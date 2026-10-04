-- Arcade vehicles scattered around the motor pools beside each spoke road. A vehicle is a frictionless skid
-- carrying welded body parts, built from its model file in `src/server/vehicleModels`. The
-- driver's client sends its stick/keys over the DriveInput remote; the server turns that into
-- targets for velocity constraints on the skid. Constraints are simulated by whichever machine
-- owns the vehicle's physics, so this works under any ownership. Wrecked or abandoned vehicles
-- return to their parking spot. A driven vehicle hurts whoever it touches: cars ram, walkers stomp.

local CollectionService = game:GetService("CollectionService")
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local VehicleCatalog = require(ReplicatedStorage.Shared.VehicleCatalog)
local Combat = require(script.Parent.Combat)
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
	acceleration: number,
	braking: number,
	coasting: number,
	turnAcceleration: number?, -- rad/s^2 on the yaw rate; nil = instant
	turnInPlace: boolean, -- full turn rate at any speed
	parkingBrake: boolean, -- hold still with no driver
	stomps: boolean, -- walker: hurts what is under it at any pace, not by ramming speed
	reach: Vector3, -- half width, height, half length of the box it hurts, from the ground
	struck: { [Model]: number }, -- os.clock() each victim was last hurt
	yaw: number, -- commanded yaw rate
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
	-- Without a driver, ordinary physics has the car, unless its parking brake holds it still.
	-- With one, the drive constraints steer it, in the air too: arcade cars keep control off jumps.
	local held = occupant ~= nil or car.parkingBrake
	car.mover.Enabled = held
	car.turner.Enabled = held
	if not occupant then
		car.yaw = 0
		if held then
			car.mover.PlaneVelocity = Vector2.zero
			car.turner.AngularVelocity = Vector3.zero
		end
		return
	end

	local topSpeed = (car.seat:GetAttribute("TopSpeed") :: number?) or 80
	local look = skid.CFrame.LookVector
	local forward = Vector3.new(look.X, 0, look.Z).Unit
	local speed = skid.AssemblyLinearVelocity:Dot(forward)
	local throttle = car.throttle
	local target = if throttle >= 0 then throttle * topSpeed else throttle * topSpeed * 0.4
	local rate = if throttle == 0
		then car.coasting
		elseif math.sign(target) ~= math.sign(speed) and math.abs(speed) > 1 then car.braking
		else car.acceleration
	local newSpeed = moveToward(speed, target, rate * dt)

	car.mover.PlaneVelocity = Vector2.new(forward.X * newSpeed, forward.Z * newSpeed)
	local grip = if car.turnInPlace then 1 else math.clamp(newSpeed / 20, -1, 1)
	local yaw = -car.steer * car.turnRate * grip
	if car.turnAcceleration then
		yaw = moveToward(car.yaw, yaw, car.turnAcceleration * dt)
	end
	car.yaw = yaw
	car.turner.AngularVelocity = Vector3.new(0, yaw, 0)
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
-- The tallest ledge a vehicle climbs, and the longest stretch of skid that slopes up to it.
-- World ledges: plazas and courtyards 0.6-0.8, roads 0.7, steps 1. Collision boxes start at
-- 1.2 or higher, above the ramps' working height for those ledges.
local RAMP_HEIGHT = 1.6
local RAMP_LENGTH = 2.5

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

type Bone = { part: BasePart, pivot: Vector3 }

-- Welds a part to a bone at an offset given in vehicle space, rest pose. The bone's Transform
-- then moves it. No bone: welded to the skid.
local function attachTo(model: Model, skid: BasePart, bone: Bone?, part: BasePart, offset: CFrame)
	if not bone then
		attach(model, skid, part, offset)
		return
	end
	local relative = CFrame.new(bone.pivot):Inverse() * offset
	part.Anchored = false
	part.Massless = true
	part.CFrame = bone.part.CFrame * relative
	local weld = Instance.new("Weld")
	weld.Part0 = bone.part
	weld.Part1 = part
	weld.C0 = relative
	weld.Parent = part
	part.Parent = model
end

-- The rig: an invisible "Bone_<name>" part per bone, joined to its parent bone (or the skid) by a
-- Motor6D "Joint_<name>" whose rest frame sits at the pivot with the vehicle's axes. Clients
-- animate the joints' Transforms; the server keeps the rest pose.
local function buildBones(
	model: Model,
	skid: BasePart,
	spec: VehicleModel.Model
): { [string]: Bone }
	local bones: { [string]: Bone } = {}
	for _, boneSpec in spec.bones or {} do
		local part = Instance.new("Part")
		part.Name = "Bone_" .. boneSpec.name
		part.Size = Vector3.new(0.2, 0.2, 0.2)
		part.Transparency = 1
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.Massless = true
		part.CFrame = skid.CFrame * SKID_TO_GROUND * CFrame.new(boneSpec.pivot)
		local parent = boneSpec.parent and bones[boneSpec.parent]
		local joint = Instance.new("Motor6D")
		joint.Name = "Joint_" .. boneSpec.name
		joint.Part0 = if parent then parent.part else skid
		joint.Part1 = part
		joint.C0 = if parent
			then CFrame.new(parent.pivot):Inverse() * CFrame.new(boneSpec.pivot)
			else SKID_TO_GROUND * CFrame.new(boneSpec.pivot)
		joint.Parent = part
		part.Parent = model
		bones[boneSpec.name] = { part = part, pivot = boneSpec.pivot }
	end
	return bones
end

-- Collision groups. Every vehicle's solid parts are in Vehicles; a vehicle that steps over things
-- (spec.stepsOver) is in Walkers, which passes through Vehicles and Scenery (trees, rocks, crates,
-- barrels). Buildings, roads, terrain and players stay solid to both.
function Vehicles.registerCollisionGroups()
	for _, group in { "Vehicles", "Walkers", "Scenery" } do
		if not PhysicsService:IsCollisionGroupRegistered(group) then
			PhysicsService:RegisterCollisionGroup(group)
		end
	end
	PhysicsService:CollisionGroupSetCollidable("Walkers", "Vehicles", false)
	PhysicsService:CollisionGroupSetCollidable("Walkers", "Scenery", false)
end

-- Climbable TrussParts welded to the skid.
local function addLadders(model: Model, skid: BasePart, spec: VehicleModel.Model)
	for index, ladder in spec.ladders or {} do
		local truss = Instance.new("TrussPart")
		truss.Name = "Ladder" .. index
		truss.Size = Vector3.new(2, ladder.height, 2)
		truss.Style = Enum.Style.AlternatingSupports
		truss.Color = rgb(46, 48, 52)
		truss.Material = M.Metal
		truss.CanCollide = true
		attach(model, skid, truss, CFrame.new(ladder.base + Vector3.new(0, ladder.height / 2, 0)))
	end
end

-- Height of the vehicle's solid parts above the ground: collision boxes and ladders.
local function solidHeight(spec: VehicleModel.Model): number
	local top = 0
	for _, box in spec.collision :: { VehicleModel.BoxSpec } do
		top = math.max(top, box.offset.Position.Y + box.size.Y / 2)
	end
	for _, ladder in spec.ladders or {} do
		top = math.max(top, ladder.base.Y + ladder.height)
	end
	return top
end

-- Contact damage -------------------------------------------------------------------------------

local HIT_INTERVAL = 0.1 -- seconds between contact checks
local HIT_COOLDOWN = 0.8 -- seconds before the same vehicle hurts the same victim again
local HIT_MARGIN = 1.5 -- studs past the footprint that count as touching
local RAM_MIN_SPEED = 12 -- studs/s; slower cars nudge
local RAM_DAMAGE = 0.6 -- per stud/s of speed: 48 at 80
local STOMP_DAMAGE = 40
local STOMP_HEIGHT = 14 -- walkers hurt only around their legs, not riders on the deck

-- The box a vehicle hurts, as half width, height and half length from the ground.
local function reachFor(spec: VehicleModel.Model): Vector3
	local height = if spec.stepsOver then STOMP_HEIGHT else math.max(solidHeight(spec), 4)
	return Vector3.new(spec.footprint.X / 2 + HIT_MARGIN, height, spec.footprint.Y / 2 + HIT_MARGIN)
end

local function touches(car: Car, ground: CFrame, position: Vector3): boolean
	local at = ground:PointToObjectSpace(position)
	return math.abs(at.X) <= car.reach.X
		and math.abs(at.Z) <= car.reach.Z
		and at.Y >= -2
		and at.Y <= car.reach.Y
end

local function hurtTouching(model: Model, car: Car)
	local occupant = car.seat.Occupant
	if not occupant then
		return
	end
	local driver = Players:GetPlayerFromCharacter(occupant.Parent)
	local skid = car.skid
	local velocity = skid.AssemblyLinearVelocity
	local flat = Vector3.new(velocity.X, 0, velocity.Z)
	local speed = flat.Magnitude
	local moving = if car.stomps
		then speed > 2 or math.abs(skid.AssemblyAngularVelocity.Y) > 0.15
		else speed >= RAM_MIN_SPEED
	if not moving then
		return
	end
	local ground = skid.CFrame * SKID_TO_GROUND
	local now = os.clock()
	for _, target in Combat.getTargets() do
		local humanoid = target.humanoid
		local seat = humanoid.SeatPart
		if
			(seat and seat:IsDescendantOf(model))
			or humanoid:GetState() == Enum.HumanoidStateType.Climbing
			or now - (car.struck[target.model] or 0) < HIT_COOLDOWN
			or not touches(car, ground, target.root.Position)
		then
			continue
		end
		local amount = if car.stomps then STOMP_DAMAGE else speed * RAM_DAMAGE
		if Combat.damage(driver, target.model, humanoid, amount) then
			car.struck[target.model] = now
			local away = target.root.Position - ground.Position
			away = Vector3.new(away.X, 0, away.Z)
			local direction = if car.stomps or speed < 1
				then (if away.Magnitude > 0.1 then away.Unit else ground.LookVector)
				else flat.Unit
			local shove = if car.stomps then 50 else speed * 0.8
			Combat.push(target.model, direction * shove + Vector3.new(0, 35, 0), 0.2)
		end
	end
	for _, barrel in CollectionService:GetTagged("ExplosiveBarrel") do
		if barrel:IsA("BasePart") and touches(car, ground, barrel.Position) then
			Combat.detonateBarrel(barrel, driver)
		end
	end
	for victim, at in car.struck do
		if now - at > HIT_COOLDOWN then
			car.struck[victim] = nil
		end
	end
end

local sinceHits = 0
RunService.Heartbeat:Connect(function(dt)
	sinceHits += dt
	if sinceHits < HIT_INTERVAL then
		return
	end
	sinceHits = 0
	for model, car in cars do
		if model.Parent then
			hurtTouching(model, car)
		end
	end
end)

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
	if spec.prompt then
		-- A fixed spot (a walker's hatch): only players right there get the prompt.
		anchor.CFrame = SKID_TO_GROUND * CFrame.new(spec.prompt.position)
		reach = spec.prompt.reach
	end

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

	-- The skid and its ramps are the only massive parts: a low, frictionless sled under the
	-- footprint. Its ends are ramps whose undersides slope up like a sled's nose, so driving into
	-- a ledge up to RAMP_HEIGHT (road edges, plazas, steps) lifts the vehicle onto it.
	local ramp = math.min(RAMP_LENGTH, L / 4)
	local skid = Instance.new("Part")
	skid.Name = "Skid"
	skid.Size = Vector3.new(W, 1, L - ramp * 2)
	skid.Transparency = 1
	skid.CustomPhysicalProperties = PhysicalProperties.new(4, 0, 0, 100, 1)
	skid.CFrame = cframe * CFrame.new(0, 0.5, 0)
	skid.Parent = model
	model.PrimaryPart = skid
	-- Upside-down wedges: flat top, underside rising from the ground to RAMP_HEIGHT at the end.
	-- Their density gives each the mass of the skid slab it replaces.
	local rampDensity = 4 * 2 / RAMP_HEIGHT
	for _, turn in { CFrame.identity, CFrame.Angles(0, math.pi, 0) } do
		local wedge = Instance.new("WedgePart")
		wedge.Name = "Ramp"
		wedge.Size = Vector3.new(W, RAMP_HEIGHT, ramp)
		wedge.Transparency = 1
		wedge.CustomPhysicalProperties = PhysicalProperties.new(rampDensity, 0, 0, 100, 1)
		local relative = SKID_TO_GROUND
			* turn
			* CFrame.new(0, RAMP_HEIGHT / 2, -L / 2 + ramp / 2)
			* CFrame.Angles(0, 0, math.pi)
		wedge.CFrame = skid.CFrame * relative
		local weld = Instance.new("Weld")
		weld.Part0 = skid
		weld.Part1 = wedge
		weld.C0 = relative
		weld.Parent = wedge
		wedge.Parent = model
	end

	for index, box in spec.collision :: { VehicleModel.BoxSpec } do
		local hull = Instance.new("Part")
		hull.Name = "Hull" .. index
		hull.Size = box.size
		hull.Transparency = 1
		hull.CustomPhysicalProperties = PhysicalProperties.new(1, 0, 0, 100, 1)
		attach(model, skid, hull, box.offset)
	end

	local bones = buildBones(model, skid, spec)
	addLadders(model, skid, spec)
	local group = if spec.stepsOver then "Walkers" else "Vehicles"
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.CollisionGroup = group
		end
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
		attachTo(model, skid, piece.bone and bones[piece.bone], part, piece.offset)
	end

	-- Outside-view camera subject.
	if spec.cameraFocus then
		local focus = Instance.new("Part")
		focus.Name = "CameraFocus"
		focus.Size = Vector3.one
		focus.Transparency = 1
		focus.CanCollide = false
		focus.CanTouch = false
		focus.CanQuery = false
		attach(model, skid, focus, CFrame.new(spec.cameraFocus))
	end
	if spec.gait then
		model:SetAttribute("Gait", spec.gait)
	end

	local driver: VehicleSeat
	local passengers: { Seat } = {}
	for index, offset in spec.seats do
		local chair: BasePart = Instance.new(if index == 1 then "VehicleSeat" else "Seat") :: any
		chair.Name = if index == 1 then "DriverSeat" else "Seat" .. index
		chair.Size = VehicleModel.SEAT_SIZE
		chair.Transparency = 1
		chair.CanCollide = false
		attachTo(model, skid, spec.seatBone and bones[spec.seatBone], chair, offset)
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
	if spec.cockpitCamera then
		driver:SetAttribute("CockpitCamera", true)
	end
	if spec.gait then
		driver:SetAttribute("TurnRate", spec.turnRate or TURN_RATE) -- the walk animator reads it
	end

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
	upright.MaxTorque = 4e5 * leverage * (spec.uprightTorque or 1)
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
		acceleration = spec.acceleration or ACCELERATION,
		braking = spec.braking or BRAKING,
		coasting = spec.coasting or COASTING,
		turnAcceleration = spec.turnAcceleration,
		turnInPlace = spec.turnInPlace == true,
		parkingBrake = spec.parkingBrake == true,
		stomps = spec.stepsOver == true,
		reach = reachFor(spec),
		struck = {},
		yaw = 0,
		throttle = 0,
		steer = 0,
	}
	-- While someone drives, the server simulates the car (and the seated driver with it). When
	-- they get out, put them at the model's exit spot if it has one, then hand their character's
	-- physics back to them.
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
			if not character or not root then
				return
			end
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if spec.exit and skid.Parent and humanoid and humanoid.Health > 0 then
				-- Pivot the character so its root lands on the exit frame.
				local rootOffset = character:GetPivot():ToObjectSpace(root.CFrame)
				character:PivotTo(skid.CFrame * SKID_TO_GROUND * spec.exit * rootOffset:Inverse())
				root.AssemblyLinearVelocity = Vector3.zero
			end
			pcall(root.SetNetworkOwner, root, previous)
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

local placement = Random.new()
local SPOKE_HALF_WIDTH = 11
local CLEARANCE = 3 -- free space kept around each parked vehicle
local CLEAR_HEIGHT = 16 -- taller than every car; walkers clear their own height
local ATTEMPTS = 400

-- Everything but the terrain counts as an obstacle, roads included: no vehicle parks on a road.
local clearParams = OverlapParams.new()
clearParams.FilterType = Enum.RaycastFilterType.Exclude
clearParams.FilterDescendantsInstances = { workspace.Terrain }

-- Whether a W x L footprint at `ground` (a ground-level CFrame) is clear of the lobby and of
-- every part in the world up to `height`, with CLEARANCE to spare.
local function isClear(ground: CFrame, W: number, L: number, height: number): boolean
	for _, x in { -1, 1 } do
		for _, z in { -1, 1 } do
			local corner = ground * Vector3.new(x * W / 2, 0, z * L / 2)
			if Vector2.new(corner.X, corner.Z).Magnitude < Config.LOBBY_RADIUS + 10 then
				return false
			end
		end
	end
	local size = Vector3.new(W + CLEARANCE * 2, height, L + CLEARANCE * 2)
	local box = ground * CFrame.new(0, 0.1 + height / 2, 0)
	return #workspace:GetPartBoundsInBox(box, size, clearParams) == 0
end

-- A random ground-level spot and heading in a spoke's motor pool, on either side of the road.
local function randomSpot(spoke: number): CFrame
	local angle = Config.regionAngle(spoke)
	local outward = Config.pointAt(angle, 1)
	local side = Vector3.new(-outward.Z, 0, outward.X)
	local along = placement:NextNumber(Config.PARKING_START_RADIUS, Config.PARKING_END_RADIUS)
	local across = placement:NextNumber(SPOKE_HALF_WIDTH, Config.PARKING_REACH)
		* (if placement:NextNumber() < 0.5 then -1 else 1)
	local position = Config.pointAt(angle, along) + side * across
	return CFrame.new(position) * CFrame.Angles(0, placement:NextNumber(0, 2 * math.pi), 0)
end

-- Parks every catalog vehicle once, dealt round-robin across the spokes, each at a random clear
-- spot with a random heading. Each vehicle is built before the next is placed, so later picks
-- avoid it. The chosen spot is the vehicle's home for respawns.
local function layOut()
	for order, entry in VehicleCatalog.ALL do
		local spoke = (order - 1) % #Config.REGIONS + 1
		local spec = specFor(entry.id)
		local W, L = spec.footprint.X, spec.footprint.Y
		local top = solidHeight(spec)
		local height = if top > CLEAR_HEIGHT then top + 2 else CLEAR_HEIGHT
		local ground = randomSpot(spoke)
		local clear = isClear(ground, W, L, height)
		for _ = 2, ATTEMPTS do
			if clear then
				break
			end
			ground = randomSpot(spoke)
			clear = isClear(ground, W, L, height)
		end
		if not clear then
			warn("[Mayhem vehicle] no clear parking spot for " .. entry.id)
		end
		local spot: Spot = { id = entry.id, cframe = ground + Vector3.new(0, 0.2, 0) }
		table.insert(spots, spot)
		park(spot)
	end
end

function Vehicles.start()
	layOut()

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
