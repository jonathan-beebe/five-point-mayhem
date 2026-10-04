-- Arcade vehicles parked in motor pools along each spoke road. A vehicle is a frictionless skid
-- carrying welded body parts, built from its model file in `src/server/vehicleModels`. The
-- driver's client sends its stick/keys over the DriveInput remote; the server turns that into
-- targets for velocity constraints on the skid. Constraints are simulated by whichever machine
-- owns the vehicle's physics, so this works under any ownership. Wrecked or abandoned vehicles
-- return to their parking spot.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local VehicleCatalog = require(ReplicatedStorage.Shared.VehicleCatalog)
local VehicleModel = require(script.Parent.VehicleModel)

local Vehicles = {}

local rgb = Color3.fromRGB
local M = Enum.Material

local modelFiles = script.Parent.Parent:FindFirstChild("vehicleModels")

local folder = Instance.new("Folder")
folder.Name = "Vehicles"
folder.Parent = workspace

-- Stands in for a vehicle whose model file is missing or broken.
local function placeholder(name: string): VehicleModel.Model
	return VehicleModel.define({
		name = name,
		speed = 80,
		footprint = Vector2.new(8, 16),
		seats = { CFrame.new(-1.5, 1.5, 0) },
		pieces = {
			{
				size = Vector3.new(8, 2.5, 16),
				offset = CFrame.new(0, 2.25, 0),
				color = rgb(120, 120, 125),
				material = M.Metal,
			},
		},
	})
end

local specs: { [string]: VehicleModel.Model } = {}

local function specFor(id: string): VehicleModel.Model
	local cached = specs[id]
	if cached then
		return cached
	end
	local entry = VehicleCatalog.get(id)
	local name = if entry then entry.name else id
	local file = modelFiles and modelFiles:FindFirstChild(id)
	local spec
	if file then
		local ok, result = pcall(function()
			return VehicleModel.define(require(file :: ModuleScript) :: any)
		end)
		if ok then
			spec = result
		else
			warn("[Mayhem vehicle] " .. id .. ": " .. tostring(result))
		end
	end
	spec = spec or placeholder(name)
	specs[id] = spec
	return spec
end

-- Constraint strengths, tuned on an 8 x 14 skid and scaled with mass and size.
local BASE_MASS = 8 * 14 * 4
local BASE_SPAN = 8 ^ 2 + 14 ^ 2
local ACCELERATION = 55
local BRAKING = 90
local COASTING = 30
local TURN_RATE = 2.4 -- default

type Car = {
	seat: VehicleSeat,
	skid: BasePart,
	mover: LinearVelocity,
	turner: AngularVelocity,
	turnRate: number,
	throttle: number,
	steer: number,
}

-- Every live car, by model.
local cars: { [Model]: Car } = {}

local function moveToward(current: number, target: number, step: number): number
	if current < target then
		return math.min(current + step, target)
	end
	return math.max(current - step, target)
end

local function drive(car: Car, dt: number)
	local occupant = car.seat.Occupant
	local skid = car.skid
	-- Without a driver, ordinary physics has the car. With one, the drive constraints steer it,
	-- in the air too: arcade cars keep control off jumps.
	car.mover.Enabled = occupant ~= nil
	car.turner.Enabled = occupant ~= nil
	if not occupant then
		return
	end

	local topSpeed = (car.seat:GetAttribute("TopSpeed") :: number?) or 80
	local look = skid.CFrame.LookVector
	local forward = Vector3.new(look.X, 0, look.Z).Unit
	local speed = skid.AssemblyLinearVelocity:Dot(forward)
	local throttle = car.throttle
	local target = if throttle >= 0 then throttle * topSpeed else throttle * topSpeed * 0.4
	local rate = if throttle == 0
		then COASTING
		elseif math.sign(target) ~= math.sign(speed) and math.abs(speed) > 1 then BRAKING
		else ACCELERATION
	local newSpeed = moveToward(speed, target, rate * dt)

	car.mover.PlaneVelocity = Vector2.new(forward.X * newSpeed, forward.Z * newSpeed)
	local grip = math.clamp(newSpeed / 20, -1, 1)
	car.turner.AngularVelocity = Vector3.new(0, -car.steer * car.turnRate * grip, 0)
end

RunService.Heartbeat:Connect(function(dt)
	for model, car in cars do
		if model.Parent then
			drive(car, dt)
		else
			cars[model] = nil
		end
	end
end)

Remotes.DriveInput.OnServerEvent:Connect(function(player, throttle, steer)
	if typeof(throttle) ~= "number" or typeof(steer) ~= "number" then
		return
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local seat = humanoid and humanoid.SeatPart
	local model = seat and seat.Parent
	local car = model and cars[model :: Model]
	if not car or car.seat ~= seat then
		return
	end
	car.throttle = math.clamp(throttle, -1, 1)
	car.steer = math.clamp(steer, -1, 1)
end)

local SKID_TO_GROUND = CFrame.new(0, -0.5, 0)

-- Welds a part to the skid at an offset given in vehicle space (origin on the ground).
local function attach(model: Model, skid: BasePart, part: BasePart, offset: CFrame)
	local relative = SKID_TO_GROUND * offset
	part.Anchored = false
	part.Massless = true
	part.CFrame = skid.CFrame * relative
	local weld = Instance.new("Weld")
	weld.Part0 = skid
	weld.Part1 = part
	weld.C0 = relative
	weld.Parent = part
	part.Parent = model
end

-- Collision boxes can enclose seats, so players get in by prompt: Drive (E) takes the driver
-- seat, Ride (F) the free passenger seat nearest the player. Both prompts sit above the middle of
-- the vehicle and reach past its far end, so they work from any side.
local function addPrompts(
	skid: BasePart,
	spec: VehicleModel.Model,
	driver: VehicleSeat,
	passengers: { Seat }
)
	local W, L = spec.footprint.X, spec.footprint.Y
	local anchor = Instance.new("Attachment")
	anchor.Name = "PromptAnchor"
	anchor.Position = Vector3.new(0, 3.5, 0)
	anchor.Parent = skid
	local reach = math.sqrt((W / 2) ^ 2 + (L / 2) ^ 2) + 6

	local function prompt(action: string, key: Enum.KeyCode, order: number): ProximityPrompt
		local each = Instance.new("ProximityPrompt")
		each.Name = action .. "Prompt"
		each.ActionText = action
		each.ObjectText = spec.name
		each.KeyboardKeyCode = key
		each.UIOffset = Vector2.new(0, order * 72)
		each.MaxActivationDistance = reach
		each.RequiresLineOfSight = false
		each.Parent = anchor
		return each
	end

	local function seatPlayer(player: Player, seat: Seat | VehicleSeat)
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 and not seat.Occupant then
			seat:Sit(humanoid)
		end
	end

	local drivePrompt = prompt("Drive", Enum.KeyCode.E, 0)
	drivePrompt.Triggered:Connect(function(player)
		seatPlayer(player, driver)
	end)
	driver:GetPropertyChangedSignal("Occupant"):Connect(function()
		drivePrompt.Enabled = driver.Occupant == nil
	end)

	if #passengers == 0 then
		return
	end
	local ridePrompt = prompt("Ride", Enum.KeyCode.F, 1)
	ridePrompt.Triggered:Connect(function(player)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
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

local function build(id: string, cframe: CFrame): Model
	local spec = specFor(id)
	local model = Instance.new("Model")
	model.Name = spec.name
	model:SetAttribute("VehicleId", id)
	local W, L = spec.footprint.X, spec.footprint.Y

	-- The skid is the only massive part: a low, frictionless sled under the footprint.
	local skid = Instance.new("Part")
	skid.Name = "Skid"
	skid.Size = Vector3.new(W, 1, L)
	skid.Transparency = 1
	skid.CustomPhysicalProperties = PhysicalProperties.new(4, 0, 0, 100, 1)
	skid.CFrame = cframe * CFrame.new(0, 0.5, 0)
	skid.Parent = model
	model.PrimaryPart = skid

	for index, box in spec.collision :: { VehicleModel.BoxSpec } do
		local hull = Instance.new("Part")
		hull.Name = "Hull" .. index
		hull.Size = box.size
		hull.Transparency = 1
		hull.CustomPhysicalProperties = PhysicalProperties.new(1, 0, 0, 100, 1)
		attach(model, skid, hull, box.offset)
	end

	for _, piece in spec.pieces do
		local part: BasePart = Instance.new(piece.class or "Part") :: any
		if piece.shape and part:IsA("Part") then
			part.Shape = piece.shape
		end
		part.Name = piece.name or "Piece"
		part.Size = piece.size
		part.Color = piece.color
		part.Material = piece.material or M.SmoothPlastic
		part.Transparency = piece.transparency or 0
		part.Reflectance = piece.reflectance or 0
		part.CanCollide = false
		part.CanTouch = false
		part.CastShadow = part.Transparency < 0.5
		attach(model, skid, part, piece.offset)
	end

	local driver: VehicleSeat
	local passengers: { Seat } = {}
	for index, offset in spec.seats do
		local chair: BasePart = Instance.new(if index == 1 then "VehicleSeat" else "Seat") :: any
		chair.Name = if index == 1 then "DriverSeat" else "Seat" .. index
		chair.Size = VehicleModel.SEAT_SIZE
		chair.Transparency = 1
		chair.CanCollide = false
		attach(model, skid, chair, offset)
		if index == 1 then
			driver = chair :: VehicleSeat
		else
			table.insert(passengers, chair :: Seat)
		end
	end
	addPrompts(skid, spec, driver, passengers)
	driver.MaxSpeed = spec.speed
	driver:SetAttribute("MayhemCar", true)
	driver:SetAttribute("TopSpeed", spec.speed)

	local mass = W * L * 4
	local strength = mass / BASE_MASS
	local leverage = strength * (W ^ 2 + L ^ 2) / BASE_SPAN

	-- Keeps the vehicle upright without fixing its heading.
	local attachment = Instance.new("Attachment")
	attachment.CFrame = CFrame.Angles(0, 0, math.rad(90))
	attachment.Parent = skid
	local upright = Instance.new("AlignOrientation")
	upright.Mode = Enum.OrientationAlignmentMode.OneAttachment
	upright.AlignType = Enum.AlignType.PrimaryAxisParallel
	upright.PrimaryAxis = Vector3.yAxis
	upright.Attachment0 = attachment
	upright.MaxTorque = 4e5 * leverage
	upright.Responsiveness = 12
	upright.Parent = skid

	-- Drive constraints: horizontal velocity in the world XZ plane (gravity stays free) and yaw rate.
	local driveAttachment = Instance.new("Attachment")
	driveAttachment.Name = "DriveAttachment"
	driveAttachment.Parent = skid
	local mover = Instance.new("LinearVelocity")
	mover.Attachment0 = driveAttachment
	mover.RelativeTo = Enum.ActuatorRelativeTo.World
	mover.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
	mover.PrimaryTangentAxis = Vector3.xAxis
	mover.SecondaryTangentAxis = Vector3.zAxis
	mover.MaxForce = 3e5 * strength
	mover.Enabled = false
	mover.Parent = skid
	local turner = Instance.new("AngularVelocity")
	turner.Attachment0 = driveAttachment
	turner.RelativeTo = Enum.ActuatorRelativeTo.World
	turner.MaxTorque = 1e6 * leverage
	turner.Enabled = false
	turner.Parent = skid

	local car: Car = {
		seat = driver,
		skid = skid,
		mover = mover,
		turner = turner,
		turnRate = spec.turnRate or TURN_RATE,
		throttle = 0,
		steer = 0,
	}
	-- While someone drives, the server simulates the car (and the seated driver with it). When
	-- they get out, hand their character's physics back to them.
	local lastDriver: Player? = nil
	driver:GetPropertyChangedSignal("Occupant"):Connect(function()
		model:SetAttribute("LastUsed", os.clock())
		car.throttle = 0
		car.steer = 0
		local occupant = driver.Occupant
		if occupant then
			lastDriver = Players:GetPlayerFromCharacter(occupant.Parent)
			local ok, problem = pcall(skid.SetNetworkOwner, skid, nil)
			if not ok then
				warn("[Mayhem car] could not take ownership: " .. tostring(problem))
			end
			return
		end
		local previous = lastDriver
		lastDriver = nil
		task.defer(function()
			local character = previous and previous.Character
			local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if root then
				pcall(root.SetNetworkOwner, root, previous)
			end
		end)
	end)

	model.Parent = folder
	cars[model] = car
	return model
end

type Spot = { id: string, cframe: CFrame, model: Model? }
local spots: { Spot } = {}

local function park(spot: Spot)
	if spot.model then
		spot.model:Destroy()
	end
	spot.model = build(spot.id, spot.cframe)
	spot.model:SetAttribute("LastUsed", os.clock())
end

local function isOccupied(model: Model): boolean
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("Seat") or descendant:IsA("VehicleSeat") then
			if (descendant :: any).Occupant then
				return true
			end
		end
	end
	return false
end

-- Spawns a vehicle (a random one when no id is given) facing away from a position.
function Vehicles.spawnNear(position: Vector3, facing: Vector3?, id: string?): Model
	local kind = id and VehicleCatalog.get(id)
		or VehicleCatalog.ALL[math.random(1, #VehicleCatalog.ALL)]
	local spec = specFor(kind.id)
	local flat = facing and Vector3.new(facing.X, 0, facing.Z)
	local look = if flat and flat.Magnitude > 0.01 then flat.Unit else Vector3.zAxis
	-- Clear the spawn point by half the vehicle's length.
	local center = position + look * (spec.footprint.Y / 2) + Vector3.new(0, 1, 0)
	return build(kind.id, CFrame.lookAt(center, center + look))
end

-- Lays every catalog vehicle out in rows on both sides of the spoke roads, in catalog order,
-- dealing them round-robin across the spokes. Each vehicle faces out toward its landmark.
local function layOut()
	local cursors: { { number } } = {}
	for index = 1, #Config.REGIONS do
		cursors[index] = { Config.PARKING_START_RADIUS, Config.PARKING_START_RADIUS }
	end
	for order, entry in VehicleCatalog.ALL do
		local spoke = (order - 1) % #Config.REGIONS + 1
		local sideIndex = (math.floor((order - 1) / #Config.REGIONS) % 2) + 1
		local spec = specFor(entry.id)
		local W, L = spec.footprint.X, spec.footprint.Y
		local angle = Config.regionAngle(spoke)
		local outward = Config.pointAt(angle, 1)
		local side = Vector3.new(-outward.Z, 0, outward.X) * (if sideIndex == 1 then -1 else 1)
		local along = cursors[spoke][sideIndex] + L / 2
		cursors[spoke][sideIndex] += L + 8
		if along + L / 2 > Config.PARKING_END_RADIUS then
			warn("[Mayhem vehicle] motor pool overflow at " .. entry.id)
		end
		local across = 11 + 5 + W / 2
		local position = Config.pointAt(angle, along) + side * across + Vector3.new(0, 0.2, 0)
		table.insert(spots, { id = entry.id, cframe = CFrame.lookAt(position, position + outward) })
	end
end

function Vehicles.start()
	layOut()
	for _, spot in spots do
		park(spot)
	end

	-- Return cars that were destroyed, or left idle far from home for a minute.
	task.spawn(function()
		while true do
			task.wait(10)
			for _, spot in spots do
				local model = spot.model
				local skid = model and model.PrimaryPart
				if not model or not model.Parent or not skid then
					park(spot)
				elseif isOccupied(model) then
					model:SetAttribute("LastUsed", os.clock())
				else
					local away = (skid.Position - spot.cframe.Position).Magnitude > 30
					local idle = os.clock() - ((model:GetAttribute("LastUsed") :: number?) or 0)
						> 60
					if (away and idle) or skid.Position.Y < -50 then
						park(spot)
					end
				end
			end
		end
	end)
end

return Vehicles
