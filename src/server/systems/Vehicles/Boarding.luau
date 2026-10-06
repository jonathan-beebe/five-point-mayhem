-- Getting in and out: the Drive and Ride prompts on every vehicle, a walker's cab with its Drive
-- and Climb out prompts, and putting a player down at a walker's exit spot.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Names = require(ReplicatedStorage.Shared.Names)
local PodState = require(ReplicatedStorage.Shared.PodState)
local VehicleSizing = require(ReplicatedStorage.Shared.VehicleSizing)
local VehicleModel = require(script.Parent.Parent.VehicleModel)
local Characters = require(script.Parent.Parent.util.Characters)
local Prompts = require(script.Parent.Parent.util.Prompts)
local Placement = require(script.Parent.Placement)

local Boarding = {}

local SKID_TO_GROUND = Placement.SKID_TO_GROUND
local attachTo = Placement.attachTo
local onTerrain = Placement.onTerrain

type Bone = Placement.Bone

-- Collision boxes can enclose seats, so players get in by prompt: Drive (E) takes the driver
-- seat, Ride (F) the free passenger seat nearest the player. Both prompts sit above the middle of
-- the vehicle and reach past its far end, so they work from any side. Clients draw every prompt at
-- the side of the screen and switch off the ones that do nothing for a seated player
-- (src/client/PromptPanel.luau).
local function seatPlayer(player: Player, seat: Seat | VehicleSeat)
	local model = seat.Parent
	local podState = PodState.of(model and model:GetAttribute(Names.Attributes.PodState))
	-- The legs ride only while the pod is away, and not while it comes home; any other seat is
	-- away with its pod.
	if not PodState.canSit(podState, seat:GetAttribute(Names.Attributes.LegsSeat)) then
		return
	end
	local humanoid = Characters.humanoidOf(player)
	if humanoid and humanoid.Health > 0 and not seat.Occupant then
		-- Seat and VehicleSeat both have Sit(Humanoid); the checker cannot call a union of methods.
		(seat :: Seat):Sit(humanoid)
	end
end

local function addPrompts(
	skid: BasePart,
	spec: VehicleModel.Model,
	driver: VehicleSeat,
	passengers: { Seat },
	legsSeat: VehicleSeat?
)
	local W, L = spec.footprint.X, spec.footprint.Y
	local anchor = Instance.new("Attachment")
	anchor.Name = "PromptAnchor"
	anchor.Position = Vector3.new(0, 3.5, 0)
	anchor.Parent = skid
	local reach = VehicleSizing.promptReach(W, L)
	if spec.prompt then
		-- A fixed spot (a walker's hatch): only players right there get the prompt.
		anchor.CFrame = SKID_TO_GROUND * CFrame.new(spec.prompt.position)
		reach = spec.prompt.reach
	end

	-- `name` defaults to `<action>Prompt`; PromptPanel finds the Drive prompt by its name.
	local function prompt(action: string, key: Enum.KeyCode, name: string?): ProximityPrompt
		return Prompts.make({
			name = name or action .. "Prompt",
			action = action,
			object = spec.name,
			key = key,
			reach = reach,
		}, anchor)
	end

	-- Drive takes the driver seat, or while a pod is away (flying or landed) the legs seat.
	local model = skid.Parent :: Model
	local function driveSeat(): VehicleSeat?
		return PodState.driveSeat(
			PodState.of(model:GetAttribute(Names.Attributes.PodState)),
			driver,
			legsSeat
		)
	end
	local drivePrompt = prompt("Drive", Enum.KeyCode.E, Names.Instances.DrivePrompt)
	drivePrompt.Triggered:Connect(function(player)
		local seat = driveSeat()
		if seat then
			seatPlayer(player, seat)
		end
	end)
	local function refreshDrive()
		local seat = driveSeat()
		drivePrompt.Enabled = seat ~= nil and seat.Occupant == nil
	end
	driver:GetPropertyChangedSignal("Occupant"):Connect(refreshDrive)
	if legsSeat then
		legsSeat:GetPropertyChangedSignal("Occupant"):Connect(refreshDrive)
		model:GetAttributeChangedSignal(Names.Attributes.PodState):Connect(refreshDrive)
	end

	if #passengers == 0 then
		return
	end
	local ridePrompt = prompt("Ride", Enum.KeyCode.F)
	ridePrompt.Triggered:Connect(function(player)
		local root = Characters.rootOf(player)
		if not root then
			return
		end
		local best, bestDistance = nil, math.huge
		for _, seat in passengers do
			local distance = (seat.Position - root.Position).Magnitude
			if not seat.Occupant and distance < bestDistance then
				best, bestDistance = seat, distance
			end
		end
		if best then
			seatPlayer(player, best)
		end
	end)
	local function refresh()
		local free = false
		for _, seat in passengers do
			free = free or seat.Occupant == nil
		end
		ridePrompt.Enabled = free
	end
	for _, seat in passengers do
		seat:GetPropertyChangedSignal("Occupant"):Connect(refresh)
	end
end

-- Puts `character` on the ground at the walker's exit spot (`exit`, vehicle space).
local function placeAtExit(skid: BasePart, exit: CFrame, character: Model)
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end
	-- The root lands on the exit frame, never below the terrain surface under the exit, or the
	-- player falls through the world.
	local lift = Vector3.new(0, exit.Position.Y, 0)
	local spot = (onTerrain(skid.CFrame * SKID_TO_GROUND * exit - lift, 0, 0)) + lift
	Characters.moveRootTo(character, root, spot)
end

-- The walkable cab (spec.cab): an invisible volume tagged MechCab (the client's camera looks for
-- it) holding two prompts: Drive takes the free driver seat, Climb out moves the player to the
-- exit spot outside.
local function addCab(
	model: Model,
	skid: BasePart,
	spec: VehicleModel.Model,
	driver: VehicleSeat,
	podBone: Bone?
): (Player) -> ()
	local cab = spec.cab :: VehicleModel.CabSpec
	local exit = spec.exit :: CFrame
	local volume = Instance.new("Part")
	volume.Name = Names.Instances.Cab
	volume.Size = cab.size
	volume.Transparency = 1
	volume.CanCollide = false
	volume.CanTouch = false
	volume.CanQuery = false
	-- A flying pod takes its cab along.
	attachTo(model, skid, podBone, volume, CFrame.new(cab.center))
	CollectionService:AddTag(volume, Names.Tags.MechCab)

	local anchor = Instance.new("Attachment")
	anchor.Name = "CabPromptAnchor"
	anchor.Position = Vector3.new(0, 3 - cab.size.Y / 2, 0)
	anchor.Parent = volume
	local reach = VehicleSizing.cabReach(cab.size)

	-- `name` defaults to `<action>Prompt`; PromptPanel finds the Drive prompt by its name.
	local function prompt(action: string, key: Enum.KeyCode, name: string?): ProximityPrompt
		return Prompts.make({
			name = name or action .. "Prompt",
			action = action,
			object = spec.name,
			key = key,
			reach = reach,
		}, anchor)
	end

	local drivePrompt = prompt("Drive", Enum.KeyCode.E, Names.Instances.DrivePrompt)
	drivePrompt.Triggered:Connect(function(player)
		seatPlayer(player, driver)
	end)
	driver:GetPropertyChangedSignal("Occupant"):Connect(function()
		drivePrompt.Enabled = driver.Occupant == nil
	end)

	local function climbOut(player: Player)
		local character, humanoid = Characters.parts(player)
		if character and humanoid and humanoid.Health > 0 and not humanoid.SeatPart then
			placeAtExit(skid, exit, character)
		end
	end
	prompt("Climb out", Enum.KeyCode.Q).Triggered:Connect(function(player)
		if PodState.of(model:GetAttribute(Names.Attributes.PodState)) == PodState.DOCKED then
			climbOut(player)
		end
	end)
	return climbOut
end

Boarding.addPrompts = addPrompts
Boarding.placeAtExit = placeAtExit
Boarding.addCab = addCab

return Boarding
