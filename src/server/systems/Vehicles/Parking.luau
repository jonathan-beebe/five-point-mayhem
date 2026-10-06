-- Parking: every catalog vehicle gets a home spot (walkers in a guard ring round the lobby, the
-- rest at random clear spots along the spokes), and a respawn loop returns vehicles that were
-- destroyed or left idle far from home. Also spawns a vehicle on demand (spawnNear, /give).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Names = require(ReplicatedStorage.Shared.Names)
local VehicleCatalog = require(ReplicatedStorage.Shared.VehicleCatalog)
local VehicleLayout = require(ReplicatedStorage.Shared.VehicleLayout)
local PodFlight = require(script.Parent.Parent.PodFlight)
local Characters = require(script.Parent.Parent.util.Characters)
local Builder = require(script.Parent.Builder)
local Specs = require(script.Parent.Specs)

local Parking = {}

local specFor = Specs.specFor
local build = Builder.build

type Spot = { id: string, cframe: CFrame, model: Model? }
local spots: { Spot } = {}

local function park(spot: Spot)
	if spot.model then
		spot.model:Destroy()
	end
	local model = build(spot.id, spot.cframe)
	spot.model = model
	model:SetAttribute("LastUsed", os.clock())
end

-- Someone in a seat, or standing in the cab.
local function isOccupied(model: Model): boolean
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("Seat") or descendant:IsA("VehicleSeat") then
			if (descendant :: any).Occupant then
				return true
			end
		end
	end
	local cab = model:FindFirstChild(Names.Instances.Cab)
	if cab and cab:IsA("BasePart") then
		for _, player in Players:GetPlayers() do
			if Characters.isInside(player, cab) then
				return true
			end
		end
	end
	return false
end

-- Spawns a vehicle (a random one when no id is given) facing away from a position.
function Parking.spawnNear(position: Vector3, facing: Vector3?, id: string?): Model
	local kind = id and VehicleCatalog.get(id)
		or VehicleCatalog.ALL[math.random(1, #VehicleCatalog.ALL)]
	local spec = specFor(kind.id)
	return build(kind.id, VehicleLayout.spawnFrame(position, facing, spec.footprint.Y))
end

-- Spots, the clear test's sizes and the respawn rule: VehicleLayout.
local placement = Random.new()

-- Everything but the terrain counts as an obstacle, roads included: no vehicle parks on a road.
local clearParams = OverlapParams.new()
clearParams.FilterType = Enum.RaycastFilterType.Exclude
clearParams.FilterDescendantsInstances = { workspace.Terrain }

-- Whether a W x L footprint at `ground` (a ground-level CFrame) is clear of the lobby and of
-- every part in the world up to `height`, with room to spare (VehicleLayout.clearBox).
local function isClear(ground: CFrame, W: number, L: number, height: number): boolean
	if not VehicleLayout.clearsLobby(ground, W, L) then
		return false
	end
	local box, size = VehicleLayout.clearBox(ground, W, L, height)
	return #workspace:GetPartBoundsInBox(box, size, clearParams) == 0
end

local function addSpot(id: string, ground: CFrame)
	local spot: Spot = { id = id, cframe = ground + Vector3.new(0, 0.2, 0) }
	table.insert(spots, spot)
	park(spot)
end

-- Walkers (specs with a gait) stand guard in a ring around the lobby, facing out toward the
-- arena: one in the middle of each gap between the gate roads, spread evenly when their count
-- differs from the gates' (VehicleLayout.guardRadius, guardSpot). Returns the walkers whose spot
-- was blocked.
local function placeWalkers(walkers: { VehicleCatalog.Vehicle }): { VehicleCatalog.Vehicle }
	local depth = 0
	for _, entry in walkers do
		depth = math.max(depth, specFor(entry.id).footprint.Y)
	end
	local radius = VehicleLayout.guardRadius(depth)
	local blocked = {}
	for index, entry in walkers do
		local spec = specFor(entry.id)
		local ground = VehicleLayout.guardSpot(index, #walkers, radius)
		if isClear(ground, spec.footprint.X, spec.footprint.Y, VehicleLayout.clearHeight(spec)) then
			addSpot(entry.id, ground)
		else
			table.insert(blocked, entry)
		end
	end
	return blocked
end

-- Parks every catalog vehicle once. Walkers go first, around the lobby; the rest (and any walker
-- whose guard spot was blocked) are dealt round-robin across the spokes, each at a random clear
-- spot with a random heading. Each vehicle is built before the next is placed, so later picks
-- avoid it. The chosen spot is the vehicle's home for respawns.
local function layOut()
	local walkers, others = {}, {}
	for _, entry in VehicleCatalog.ALL do
		table.insert(if specFor(entry.id).gait then walkers else others, entry)
	end
	for _, entry in placeWalkers(walkers) do
		warn(
			"[Mayhem vehicle] guard spot blocked for " .. entry.id .. "; parking it in a motor pool"
		)
		table.insert(others, entry)
	end
	for order, entry in others do
		local spoke = VehicleLayout.spokeFor(order)
		local spec = specFor(entry.id)
		local W, L = spec.footprint.X, spec.footprint.Y
		local height = VehicleLayout.clearHeight(spec)
		local ground = VehicleLayout.randomSpot(placement, spoke)
		local clear = isClear(ground, W, L, height)
		for _ = 2, VehicleLayout.ATTEMPTS do
			if clear then
				break
			end
			ground = VehicleLayout.randomSpot(placement, spoke)
			clear = isClear(ground, W, L, height)
		end
		if not clear then
			warn("[Mayhem vehicle] no clear parking spot for " .. entry.id)
		end
		addSpot(entry.id, ground)
	end
end

-- Parks every catalog vehicle (PodFlight.start first) and starts the respawn loop.
function Parking.start()
	PodFlight.start()
	layOut()

	-- Return cars that were destroyed, or left idle far from home for a minute.
	task.spawn(function()
		while true do
			task.wait(VehicleLayout.RESPAWN_INTERVAL)
			for _, spot in spots do
				local model = spot.model
				local skid = model and model.PrimaryPart
				if not model or not model.Parent or not skid then
					park(spot)
				elseif isOccupied(model) then
					model:SetAttribute("LastUsed", os.clock())
				else
					local distance = (skid.Position - spot.cframe.Position).Magnitude
					local idleSeconds = os.clock()
						- ((model:GetAttribute("LastUsed") :: number?) or 0)
					if VehicleLayout.shouldRepark(distance, idleSeconds, skid.Position.Y) then
						park(spot)
					end
				end
			end
		end
	end)
end

return Parking
