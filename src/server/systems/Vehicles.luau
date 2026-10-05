-- Arcade vehicles scattered around the motor pools beside each spoke road. A vehicle is a frictionless skid
-- carrying welded body parts, built from its model file in `src/server/vehicleModels`. The
-- driver's client sends its stick/keys over the DriveInput remote; the server turns that into
-- targets for velocity constraints on the skid. Constraints are simulated by whichever machine
-- owns the vehicle's physics, so this works under any ownership. Wrecked or abandoned vehicles
-- return to their parking spot. A driven vehicle hurts whoever it touches (cars ram, walkers
-- stomp), shoves the vehicles it hits, and fells trees. A walker with a pod (spec.pod) can send
-- its cab flying (PodFlight); while the pod is away its legs park. A driven walker climbs walls up
-- to MechClimb.MAX_RISE: it senses them with rays, MechClimb decides, and a vertical velocity
-- constraint (the "Climber") lifts it; the model's "Climbing" attribute says when.

local CollectionService = game:GetService("CollectionService")
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local MechClimb = require(ReplicatedStorage.Shared.MechClimb)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local VehicleCatalog = require(ReplicatedStorage.Shared.VehicleCatalog)
local Combat = require(script.Parent.Combat)
local PodFlight = require(script.Parent.PodFlight)
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
local SETTLING = 45 -- studs/s^2 an empty vehicle slows by, frictionless skid and all
local SPIN_SETTLING = 4 -- rad/s^2 an empty vehicle's yaw spin slows by
local CLIMB_LIFT = 60 -- studs/s^2 the climber can accelerate a walker by, beyond gravity

type Car = {
	seat: VehicleSeat,
	passengers: { Seat },
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
	driveForce: number, -- mover MaxForce while driven or braked
	driveTorque: number, -- turner MaxTorque while driven or braked
	stomps: boolean, -- walker: hurts what is under it at any pace, not by ramming speed
	reach: Vector3, -- half width, height, half length of the box it hurts, from the ground
	struck: { [Model]: number }, -- os.clock() each victim (character, vehicle, tree) was last hit
	mass: number, -- footprint mass, for shoves between vehicles
	ram: number, -- spec.ram
	weight: number, -- how hard it hits trees and creatures: 1 for the base car, times ram
	pace: number, -- recent top speed; outlasts the frame in which a crash stops the vehicle
	stunnedUntil: number, -- os.clock() until which a shove, not the drive constraints, moves it
	yaw: number, -- commanded yaw rate
	throttle: number,
	steer: number,
	pod: PodFlight.Pod?, -- a walker whose cab flies (spec.pod)
	legsSeat: VehicleSeat?, -- drives the legs while the pod is away (spec.pod.legsSeat)
	model: Model,
	climber: LinearVelocity?, -- vertical lift for the climb assist; nil when it does not climb
	climbRays: MechClimb.Rays?,
	climb: MechClimb.State,
	climbing: boolean, -- mirrors the model's "Climbing" attribute
}

-- Every live car, by model.
local cars: { [Model]: Car } = {}

local function moveToward(current: number, target: number, step: number): number
	if current < target then
		return math.min(current + step, target)
	end
	return math.max(current - step, target)
end

local function setLimits(car: Car, force: number, torque: number)
	-- Compared with slack: the properties store single precision.
	if math.abs(car.mover.MaxForce - force) > 1 then
		car.mover.MaxForce = force
	end
	if math.abs(car.turner.MaxTorque - torque) > 1 then
		car.turner.MaxTorque = torque
	end
end

-- Climb assist (walkers) -------------------------------------------------------------------------

local climbParams = RaycastParams.new()
climbParams.FilterType = Enum.RaycastFilterType.Exclude
climbParams.FilterDescendantsInstances = { folder }
climbParams.CollisionGroup = "Walkers"
climbParams.RespectCanCollide = true

-- Terrain and anchored parts are climbable, unless they or a parent are tagged NoClimb.
local function climbable(hit: RaycastResult): boolean
	local instance = hit.Instance
	if not instance:IsA("Terrain") and not (instance:IsA("BasePart") and instance.Anchored) then
		return false
	end
	local node: Instance? = instance
	while node and node ~= workspace do
		if CollectionService:HasTag(node, "NoClimb") then
			return false
		end
		node = node.Parent
	end
	return true
end

-- Casts the climb rays (MechClimb.rays) from `ground`, a level frame on the skid's underside.
local function senseClimb(rays: MechClimb.Rays, ground: CFrame): MechClimb.Probe
	local function cast(ray: MechClimb.Ray, down: boolean): RaycastResult?
		local origin = ground * Vector3.new(ray.x, ray.y, ray.z)
		local direction = if down
			then Vector3.new(0, -ray.length, 0)
			else ground.LookVector * ray.length
		local hit = workspace:Raycast(origin, direction, climbParams)
		return if hit and climbable(hit) then hit else nil
	end
	local wall: { distance: number }? = nil
	for _, ray in rays.walls do
		local hit = cast(ray, false)
		if hit and math.abs(hit.Normal.Y) < MechClimb.WALL_MAX_NORMAL_Y then
			local distance = hit.Distance - (ray.z - rays.front) -- from the skid's front
			if not wall or distance < wall.distance then
				wall = { distance = distance }
			end
		end
	end
	local bottom = ground.Position.Y
	local top = cast(rays.ledge, true)
	local foot = cast(rays.foot, true)
	return {
		wall = wall,
		ledge = if top then { height = top.Position.Y - bottom, normalY = top.Normal.Y } else nil,
		headroom = cast(rays.headroom, false) == nil,
		foot = if foot then foot.Position.Y - bottom else nil,
	}
end

local function setClimbing(car: Car, climbing: boolean)
	if car.climbing ~= climbing then
		car.climbing = climbing
		car.model:SetAttribute("Climbing", climbing)
	end
end

-- Ends any climb: the climber lets go and the walker falls or stands where it is.
local function stopClimb(car: Car)
	local climber = car.climber
	if climber and climber.Enabled then
		climber.Enabled = false
	end
	if car.climb.mode ~= "walk" then
		car.climb = MechClimb.new()
	end
	setClimbing(car, false)
end

-- Runs the climb assist for a driven walker. Returns the command, whose `press` replaces the
-- forward speed; nil for a vehicle that does not climb.
local function climbStep(car: Car, forward: Vector3, dt: number): MechClimb.Command?
	local climber, rays = car.climber, car.climbRays
	if not climber or not rays then
		return nil
	end
	local skid = car.skid
	local underside = (skid.CFrame * CFrame.new(0, -skid.Size.Y / 2, 0)).Position
	local ground = CFrame.lookAt(underside, underside + forward)
	local velocity = skid.AssemblyLinearVelocity
	local command = MechClimb.step(car.climb, {
		throttle = car.throttle,
		bottom = underside.Y,
		vy = velocity.Y,
		speed = velocity:Dot(forward),
		probe = if car.throttle > 0 then senseClimb(rays, ground) else nil,
		dt = dt,
	})
	local lift = command.lift
	if lift then
		-- Sized every frame: /gravity changes, and a seated driver adds mass.
		local force = skid.AssemblyMass * (workspace.Gravity + CLIMB_LIFT)
		if math.abs(climber.MaxForce - force) > 1 then
			climber.MaxForce = force
		end
		if climber.LineVelocity ~= lift then
			climber.LineVelocity = lift
		end
		climber.Enabled = true
	elseif climber.Enabled then
		climber.Enabled = false
	end
	setClimbing(car, command.climbing)
	return command
end

-- The seat that drives the legs: the driver seat, or while a pod is away the legs seat (its pilot
-- flies the pod, PodFlight).
local function legsDriverSeat(car: Car): VehicleSeat?
	return if PodFlight.isDocked(car.pod) then car.seat else car.legsSeat
end

local function drive(car: Car, dt: number)
	local legsDriver = legsDriverSeat(car)
	local occupant = legsDriver and legsDriver.Occupant
	local skid = car.skid
	-- A shoved vehicle flies free for a moment: the drive constraints would cancel the shove.
	if os.clock() < car.stunnedUntil then
		car.mover.Enabled = false
		car.turner.Enabled = false
		stopClimb(car)
		return
	end
	-- Without a driver, ordinary physics has the car while it is at rest; when it moves (shoved,
	-- abandoned rolling) the constraints bleed off its speed and spin. A parking brake holds it
	-- still. With a driver, the drive constraints steer it, in the air too: arcade cars keep
	-- control off jumps.
	if not occupant then
		car.yaw = 0
		stopClimb(car)
		local velocity = skid.AssemblyLinearVelocity
		local flat = Vector2.new(velocity.X, velocity.Z)
		local spin = skid.AssemblyAngularVelocity.Y
		local settling = not car.parkingBrake and (flat.Magnitude > 0.5 or math.abs(spin) > 0.1)
		local held = car.parkingBrake or settling
		car.mover.Enabled = held
		car.turner.Enabled = held
		if car.parkingBrake then
			setLimits(car, car.driveForce, car.driveTorque)
			car.mover.PlaneVelocity = Vector2.zero
			car.turner.AngularVelocity = Vector3.zero
		elseif settling then
			-- Limits sized to the settling rates: a sliding friction other vehicles push through.
			local mass = skid.AssemblyMass
			local span = skid.Size.X ^ 2 + skid.Size.Z ^ 2
			setLimits(car, mass * SETTLING, mass * span / 12 * SPIN_SETTLING)
			local slowed = math.max(flat.Magnitude - SETTLING * dt, 0)
			car.mover.PlaneVelocity = if flat.Magnitude > 0
				then flat.Unit * slowed
				else Vector2.zero
			car.turner.AngularVelocity = Vector3.new(0, moveToward(spin, 0, SPIN_SETTLING * dt), 0)
		end
		return
	end
	setLimits(car, car.driveForce, car.driveTorque)
	car.mover.Enabled = true
	car.turner.Enabled = true

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
	local climb = climbStep(car, forward, dt)
	if climb and climb.press then
		newSpeed = climb.press
	end

	car.mover.PlaneVelocity = Vector2.new(forward.X * newSpeed, forward.Z * newSpeed)
	local grip = if car.turnInPlace then 1 else math.clamp(newSpeed / 20, -1, 1)
	local yaw = if climb and climb.climbing then 0 else -car.steer * car.turnRate * grip
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

Remotes.DriveInput.OnServerEvent:Connect(function(player, throttle, steer, lift)
	if typeof(throttle) ~= "number" or typeof(steer) ~= "number" then
		return
	end
	if typeof(lift) ~= "number" then
		lift = 0
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local seat = humanoid and humanoid.SeatPart
	local model = seat and seat.Parent
	local car = model and cars[model :: Model]
	if not car or (car.seat ~= seat and car.legsSeat ~= seat) then
		return
	end
	throttle, steer = math.clamp(throttle, -1, 1), math.clamp(steer, -1, 1)
	if car.pod and seat == car.seat then
		PodFlight.input(car.pod, throttle, steer, math.clamp(lift, -1, 1))
	end
	if seat == legsDriverSeat(car) then
		car.throttle, car.steer = throttle, steer
	end
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
		if boneSpec.aim then
			part:SetAttribute("Aim", boneSpec.aim)
		end
		if boneSpec.steer then
			part:SetAttribute("Steer", boneSpec.steer)
		end
		if boneSpec.wobble then
			part:SetAttribute("Wobble", true)
		end
		part.Parent = model
		bones[boneSpec.name] = { part = part, pivot = boneSpec.pivot }
	end
	return bones
end

-- Collision groups. Every vehicle's solid parts are in Vehicles; a vehicle that steps over things
-- (spec.stepsOver) is in Walkers, which passes through Vehicles and Scenery (trees, rocks, crates,
-- barrels). Buildings, roads, terrain and players stay solid to both. A felled tree is Wreckage:
-- it falls through vehicles and players onto the ground. Player groups come from Session.
function Vehicles.registerCollisionGroups()
	for _, group in { "Vehicles", "Walkers", "Scenery", "Wreckage" } do
		if not PhysicsService:IsCollisionGroupRegistered(group) then
			PhysicsService:RegisterCollisionGroup(group)
		end
	end
	PhysicsService:CollisionGroupSetCollidable("Walkers", "Vehicles", false)
	PhysicsService:CollisionGroupSetCollidable("Walkers", "Scenery", false)
	for _, group in { "Vehicles", "Walkers", "LobbyPlayers", "DeployedPlayers", "LockedOutPlayers" } do
		if PhysicsService:IsCollisionGroupRegistered(group) then
			PhysicsService:CollisionGroupSetCollidable("Wreckage", group, false)
		end
	end
end

-- An Attachment "Smoke" at each smokestack mouth, on its bone. Clients (MechMotion) emit from it.
local function addSmoke(skid: BasePart, bones: { [string]: Bone }, spec: VehicleModel.Model)
	for _, stack in spec.smoke or {} do
		local bone = stack.bone and bones[stack.bone]
		local attachment = Instance.new("Attachment")
		attachment.Name = "Smoke"
		attachment.CFrame = if bone
			then CFrame.new(bone.pivot):Inverse() * CFrame.new(stack.position)
			else SKID_TO_GROUND * CFrame.new(stack.position)
		attachment.Parent = if bone then bone.part else skid
	end
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

-- Contact damage and ramming -------------------------------------------------------------------

local HIT_INTERVAL = 0.1 -- seconds between contact checks on characters and barrels
local HIT_COOLDOWN = 0.8 -- seconds before the same vehicle hits the same victim again
local HIT_MARGIN = 1.5 -- studs past the footprint that count as touching
local RAM_MIN_SPEED = 12 -- studs/s; slower cars nudge
local RAM_DAMAGE = 0.6 -- per stud/s of speed, times weight: 48 at 80 for the base car
local STOMP_DAMAGE = 40
local STOMP_HEIGHT = 14 -- walkers hurt only around their legs, not riders on the deck
local STOMP_PACE = 25 -- studs/s a moving walker hits vehicles and trees with, however slow
local PACE_DECAY = 150 -- studs/s^2 the remembered pace falls by
local CREATURE_FLING = 1.6 -- creatures fly further than players
local CREATURE_LIFT = 0.5 -- extra upward fling on creatures per stud/s of pace
local MAX_FLING = 160 -- studs/s
-- A struck vehicle takes on the rammer's pace x RAM_TRANSFER x ram x their mass ratio (clamped),
-- up to MAX_SHOVE. Footprint masses: kart 215, base car 448, sedan ~670, school bus 1690.
local RAM_TRANSFER = 1.1 -- above 1, a struck vehicle of equal mass clears the rammer's path
local RAM_MIN_RATIO = 0.15
local RAM_MAX_RATIO = 3
local MAX_SHOVE = 140 -- studs/s
local SHOVE_LIFT = 0.25 -- upward share of a shove
local STUN_TIME = 0.6 -- seconds a shoved vehicle flies free of its drive constraints
-- A tree falls when pace x weight reaches TREE_BREAK x its toughness (0.8-1.5); slower vehicles
-- stop against it. The base car fells at 20-38 studs/s, a kart at 29-54, a school bus at 10-19.
local TREE_BREAK = 25
local TREE_PUSH = 0.4 -- share of pace x weight the felled tree's crown takes on
local MAX_TREE_PUSH = 40 -- studs/s
local TREE_LIE = 15 -- seconds a felled tree lies before it is cleared
local TREE_REGROW = 120 -- seconds until it grows back where it stood

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

-- What a vehicle can ram: the solid parts of vehicles and of the tree groves (the parents of
-- trees tagged Tree by Landscape).
local rammable = OverlapParams.new()
rammable.FilterType = Enum.RaycastFilterType.Include
rammable.RespectCanCollide = true
local rammableRoots: { Instance } = { folder }
rammable.FilterDescendantsInstances = rammableRoots

local function addGrove(tree: Instance)
	local grove = tree.Parent
	if grove and not table.find(rammableRoots, grove) then
		table.insert(rammableRoots, grove)
		rammable.FilterDescendantsInstances = rammableRoots
	end
end
CollectionService:GetInstanceAddedSignal("Tree"):Connect(addGrove)
for _, tree in CollectionService:GetTagged("Tree") do
	addGrove(tree)
end

-- A felled tree grows back once no vehicle, creature or player stands in its place.
local regrowParams = OverlapParams.new()
regrowParams.FilterType = Enum.RaycastFilterType.Include

local function regrow(sapling: Model, grove: Instance, box: CFrame, extent: Vector3)
	if not grove.Parent then
		return
	end
	local blockers: { Instance } = { folder }
	local creatures = workspace:FindFirstChild("Creatures")
	if creatures then
		table.insert(blockers, creatures)
	end
	for _, player in Players:GetPlayers() do
		if player.Character then
			table.insert(blockers, player.Character)
		end
	end
	regrowParams.FilterDescendantsInstances = blockers
	if #workspace:GetPartBoundsInBox(box, extent, regrowParams) > 0 then
		task.delay(TREE_LIE, regrow, sapling, grove, box, extent)
		return
	end
	sapling.Parent = grove
end

-- Topples a tree away from a vehicle: its parts weld to the trunk, come loose, and turn to
-- Wreckage, which falls through vehicles and players. It lies for TREE_LIE seconds, then goes.
local function fell(tree: Model, direction: Vector3, pace: number, weight: number)
	local trunk = tree.PrimaryPart
	local grove = tree.Parent
	if not trunk or not grove or tree:GetAttribute("Felled") then
		return
	end
	local sapling = tree:Clone()
	local box, extent = tree:GetBoundingBox()
	tree:SetAttribute("Felled", true)
	local mass = 0
	for _, part in tree:GetDescendants() do
		if part:IsA("BasePart") then
			if part ~= trunk then
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = trunk
				weld.Part1 = part
				weld.Parent = part
			end
			part.CollisionGroup = "Wreckage"
			part.CanTouch = false
			part.Anchored = false
			mass += part:GetMass()
		end
	end
	pcall(trunk.SetNetworkOwner, trunk, nil)
	-- Pushed high, the tree pivots on its base and falls the way the vehicle was going.
	local crown = box.Position + Vector3.new(0, extent.Y / 4, 0)
	local push = math.min(pace * weight * TREE_PUSH, MAX_TREE_PUSH)
	trunk:ApplyImpulseAtPosition(direction * push * mass, crown)
	task.delay(TREE_LIE, function()
		tree:Destroy()
	end)
	task.delay(TREE_REGROW, regrow, sapling, grove, box, extent)
end

-- Throws a struck vehicle along `direction`, scaled by the rammer's pace, ram and the two masses,
-- and frees it from its drive constraints for STUN_TIME so the throw carries.
local function shove(car: Car, other: Car, direction: Vector3, pace: number, now: number)
	local skid = other.skid
	local ratio = math.clamp(car.mass / other.mass, RAM_MIN_RATIO, RAM_MAX_RATIO)
	local speed = math.min(pace * RAM_TRANSFER * ratio * car.ram, MAX_SHOVE)
	-- The server must own the struck vehicle for the throw to take. A driven one it already owns;
	-- an empty one it takes here. One carrying only passengers stays with their client, which
	-- leaves it to the collision alone.
	local aboard = other.seat.Occupant ~= nil
	for _, seat in other.passengers do
		aboard = aboard or seat.Occupant ~= nil
	end
	if not aboard then
		pcall(skid.SetNetworkOwner, skid, nil)
	end
	local velocity = skid.AssemblyLinearVelocity
		+ direction * speed
		+ Vector3.new(0, speed * SHOVE_LIFT, 0)
	if velocity.Magnitude > MAX_SHOVE then
		velocity = velocity.Unit * MAX_SHOVE
	end
	skid.AssemblyLinearVelocity = velocity
	other.stunnedUntil = now + STUN_TIME
end

-- Vehicles and trees are checked every frame with a box that reaches one frame ahead, so the hit
-- lands before the crash stops the rammer. Characters and barrels are checked every
-- HIT_INTERVAL (`checkTargets`).
local function hurtTouching(model: Model, car: Car, dt: number, checkTargets: boolean)
	local skid = car.skid
	local velocity = skid.AssemblyLinearVelocity
	local flat = Vector3.new(velocity.X, 0, velocity.Z)
	local speed = flat.Magnitude
	car.pace = math.max(speed, car.pace - PACE_DECAY * dt)
	local legsDriver = legsDriverSeat(car)
	local occupant = legsDriver and legsDriver.Occupant
	local now = os.clock()
	-- A shoved vehicle hits nothing until it is back under control: no chains of shoves.
	if not occupant or now < car.stunnedUntil then
		return
	end
	local driver = Players:GetPlayerFromCharacter(occupant.Parent)
	local moving = if car.stomps
		then speed > 2 or math.abs(skid.AssemblyAngularVelocity.Y) > 0.15
		else car.pace >= RAM_MIN_SPEED
	if not moving then
		return
	end
	local pace = if car.stomps then math.max(car.pace, STOMP_PACE) else car.pace
	local ground = skid.CFrame * SKID_TO_GROUND
	local look = ground.LookVector
	local heading = if speed > 1 then flat.Unit else Vector3.new(look.X, 0, look.Z).Unit
	local function away(position: Vector3): Vector3
		local offset = position - ground.Position
		offset = Vector3.new(offset.X, 0, offset.Z)
		return if offset.Magnitude > 0.1 then offset.Unit else heading
	end

	local ahead = ground:VectorToObjectSpace(flat) * dt
	local height = car.reach.Y - 0.5
	local box = ground * CFrame.new(ahead.X / 2, 0.5 + height / 2, ahead.Z / 2)
	local size = Vector3.new(
		car.reach.X * 2 + math.abs(ahead.X),
		height,
		car.reach.Z * 2 + math.abs(ahead.Z)
	)
	for _, part in workspace:GetPartBoundsInBox(box, size, rammable) do
		local victim = part.Parent
		if
			not victim
			or victim == model
			or not victim:IsA("Model")
			or now - (car.struck[victim :: Model] or 0) < HIT_COOLDOWN
		then
			continue
		end
		local other = cars[victim :: Model]
		if other then
			car.struck[victim :: Model] = now
			local outward = away(other.skid.Position)
			local direction = if car.stomps then outward else heading + outward * 0.5
			shove(
				car,
				other,
				if direction.Magnitude > 0.1 then direction.Unit else outward,
				pace,
				now
			)
		elseif CollectionService:HasTag(victim, "Tree") then
			local toughness = (victim:GetAttribute("Toughness") :: number?) or 1
			if pace * car.weight >= TREE_BREAK * toughness then
				car.struck[victim :: Model] = now
				fell(
					victim :: Model,
					if car.stomps then away(part.Position) else heading,
					pace,
					car.weight
				)
			end
		end
	end

	if not checkTargets then
		return
	end
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
		local amount = if car.stomps then STOMP_DAMAGE else pace * RAM_DAMAGE * car.weight
		if Combat.damage(driver, target.model, humanoid, amount) then
			car.struck[target.model] = now
			local direction = if car.stomps or speed < 1
				then away(target.root.Position)
				else heading
			local fling = if car.stomps then 50 else pace * 0.8 * car.weight
			local lift = 35
			local creature = Players:GetPlayerFromCharacter(target.model) == nil
			if creature then
				fling *= CREATURE_FLING
				lift += pace * CREATURE_LIFT
			end
			local push = direction * math.min(fling, MAX_FLING) + Vector3.new(0, lift, 0)
			if creature and humanoid.Health <= 0 then
				-- A kill: throw the whole body before its joints break, so the pieces scatter.
				target.root.AssemblyLinearVelocity = push
			end
			Combat.push(target.model, push, 0.2)
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
	local checkTargets = sinceHits >= HIT_INTERVAL
	if checkTargets then
		sinceHits = 0
	end
	for model, car in cars do
		if model.Parent then
			hurtTouching(model, car, dt, checkTargets)
		end
	end
end)

-- Collision boxes can enclose seats, so players get in by prompt: Drive (E) takes the driver
-- seat, Ride (F) the free passenger seat nearest the player. Both prompts sit above the middle of
-- the vehicle and reach past its far end, so they work from any side.
local function seatPlayer(player: Player, seat: Seat | VehicleSeat)
	local model = seat.Parent
	local podState = model and model:GetAttribute("PodState") or "docked"
	if seat:GetAttribute("LegsSeat") then
		if podState ~= "flying" and podState ~= "landed" then
			return -- the legs ride only while the pod is away, and not while it comes home
		end
	elseif podState ~= "docked" then
		return -- the seat is away with its pod
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 and not seat.Occupant then
		seat:Sit(humanoid)
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

	-- Drive takes the driver seat, or while a pod is away (flying or landed) the legs seat.
	local model = skid.Parent :: Model
	local function driveSeat(): VehicleSeat?
		local podState = model:GetAttribute("PodState") or "docked"
		if podState == "docked" then
			return driver
		end
		return if legsSeat and (podState == "flying" or podState == "landed") then legsSeat else nil
	end
	local drivePrompt = prompt("Drive", Enum.KeyCode.E, 0)
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
		model:GetAttributeChangedSignal("PodState"):Connect(refreshDrive)
	end

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

-- Terrain collides only at its surface: a part below it falls through the inside. Lifts `cframe`
-- to the highest terrain surface under the footprint's center and corners (never lower). The
-- second result is false when no ray hit terrain: right after the world is built, terrain has no
-- collision yet (raycasts miss it and parts fall through it).
local GROUND_WAIT = 10 -- seconds a new vehicle waits for terrain collision under it
local terrainOnly = RaycastParams.new()
terrainOnly.FilterType = Enum.RaycastFilterType.Include
terrainOnly.FilterDescendantsInstances = { workspace.Terrain }

local function onTerrain(cframe: CFrame, W: number, L: number): (CFrame, boolean)
	local top = cframe.Position.Y
	local found = false
	for _, corner in
		{
			Vector3.zero,
			Vector3.new(-W, 0, -L),
			Vector3.new(W, 0, -L),
			Vector3.new(-W, 0, L),
			Vector3.new(W, 0, L),
		}
	do
		local point = cframe * (corner / 2)
		local hit =
			workspace:Raycast(point + Vector3.new(0, 50, 0), Vector3.new(0, -100, 0), terrainOnly)
		if hit then
			top = math.max(top, hit.Position.Y)
			found = true
		end
	end
	return cframe + Vector3.new(0, top - cframe.Position.Y, 0), found
end

-- Puts `character` on the ground at the walker's exit spot (`exit`, vehicle space).
local function placeAtExit(skid: BasePart, exit: CFrame, character: Model)
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end
	-- Pivot the character so its root lands on the exit frame.
	local rootOffset = character:GetPivot():ToObjectSpace(root.CFrame)
	-- Never below the terrain surface under the exit, or the player falls through the world.
	local lift = Vector3.new(0, exit.Position.Y, 0)
	local spot = (onTerrain(skid.CFrame * SKID_TO_GROUND * exit - lift, 0, 0)) + lift
	character:PivotTo(spot * rootOffset:Inverse())
	root.AssemblyLinearVelocity = Vector3.zero
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
	volume.Name = "Cab"
	volume.Size = cab.size
	volume.Transparency = 1
	volume.CanCollide = false
	volume.CanTouch = false
	volume.CanQuery = false
	-- A flying pod takes its cab along.
	attachTo(model, skid, podBone, volume, CFrame.new(cab.center))
	CollectionService:AddTag(volume, "MechCab")

	local anchor = Instance.new("Attachment")
	anchor.Name = "CabPromptAnchor"
	anchor.Position = Vector3.new(0, 3 - cab.size.Y / 2, 0)
	anchor.Parent = volume
	local reach = math.sqrt((cab.size.X / 2) ^ 2 + (cab.size.Z / 2) ^ 2) + 0.5

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

	local drivePrompt = prompt("Drive", Enum.KeyCode.E, 0)
	drivePrompt.Triggered:Connect(function(player)
		seatPlayer(player, driver)
	end)
	driver:GetPropertyChangedSignal("Occupant"):Connect(function()
		drivePrompt.Enabled = driver.Occupant == nil
	end)

	local function climbOut(player: Player)
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if character and humanoid and humanoid.Health > 0 and not humanoid.SeatPart then
			placeAtExit(skid, exit, character)
		end
	end
	prompt("Climb out", Enum.KeyCode.Q, 1).Triggered:Connect(function(player)
		if (model:GetAttribute("PodState") or "docked") == "docked" then
			climbOut(player)
		end
	end)
	return climbOut
end

local function build(id: string, cframe: CFrame): Model
	local spec = specFor(id)
	local model = Instance.new("Model")
	model.Name = spec.name
	model:SetAttribute("VehicleId", id)
	local W, L = spec.footprint.X, spec.footprint.Y
	local grounded
	cframe, grounded = onTerrain(cframe, W, L)

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

	local bones = buildBones(model, skid, spec)
	for index, box in spec.collision :: { VehicleModel.BoxSpec } do
		local hull = Instance.new("Part")
		hull.Name = "Hull" .. index
		hull.Size = box.size
		hull.Transparency = 1
		hull.CustomPhysicalProperties = PhysicalProperties.new(1, 0, 0, 100, 1)
		attachTo(model, skid, box.bone and bones[box.bone], hull, box.offset)
	end
	local podBone = spec.pod and bones[spec.pod.bone]
	addLadders(model, skid, spec)
	addSmoke(skid, bones, spec)
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
		if piece.hideInCockpit then
			part:SetAttribute("HideInCockpit", true) -- MechCamera
		end
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
		attachTo(model, skid, podBone, focus, CFrame.new(spec.cameraFocus))
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
		-- No sitting by touch: players get in by prompt (Seat:Sit), and a driver who stands up in
		-- a cab would otherwise land back on the seat and sit again.
		chair.CanTouch = false
		attachTo(model, skid, spec.seatBone and bones[spec.seatBone], chair, offset)
		if index == 1 then
			driver = chair :: VehicleSeat
		else
			table.insert(passengers, chair :: Seat)
		end
	end
	-- A pod walker's saddle on the pod bone's parent, for driving the legs while the pod is away.
	local legsSeat: VehicleSeat? = nil
	if spec.pod and spec.pod.legsSeat then
		local legsBone: Bone? = nil
		for _, boneSpec in spec.bones or {} do
			if boneSpec.name == spec.pod.bone and boneSpec.parent then
				legsBone = bones[boneSpec.parent]
			end
		end
		local saddle = Instance.new("VehicleSeat")
		saddle.Name = "LegsSeat"
		saddle.Size = VehicleModel.SEAT_SIZE
		saddle.Transparency = 1
		saddle.CanCollide = false
		saddle.CanTouch = false
		saddle.MaxSpeed = spec.speed
		saddle:SetAttribute("MayhemCar", true) -- CarInput sends its driver's input
		saddle:SetAttribute("TopSpeed", spec.speed)
		saddle:SetAttribute("LegsSeat", true)
		attachTo(model, skid, legsBone, saddle, spec.pod.legsSeat)
		legsSeat = saddle
	end
	addPrompts(skid, spec, driver, passengers, legsSeat)
	driver.MaxSpeed = spec.speed
	driver:SetAttribute("MayhemCar", true)
	driver:SetAttribute("TopSpeed", spec.speed)
	if spec.cockpitCamera then
		driver:SetAttribute("CockpitCamera", true)
	end
	local eject: ((Player) -> ())? = nil
	if spec.cab then
		eject = addCab(model, skid, spec, driver, podBone)
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
	-- Climb assist: a vertical velocity on the same attachment, off until a climb (climbStep).
	local climbs = spec.gait ~= nil and spec.climbs ~= false
	local climber: LinearVelocity? = nil
	if climbs then
		climber = Instance.new("LinearVelocity")
		climber.Name = "Climber"
		climber.Attachment0 = driveAttachment
		climber.RelativeTo = Enum.ActuatorRelativeTo.World
		climber.VelocityConstraintMode = Enum.VelocityConstraintMode.Line
		climber.LineDirection = Vector3.yAxis
		climber.Enabled = false
		climber.Parent = skid
	end

	local ram = spec.ram or 1
	local car: Car = {
		seat = driver,
		passengers = passengers,
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
		driveForce = mover.MaxForce,
		driveTorque = turner.MaxTorque,
		stomps = spec.stepsOver == true,
		reach = reachFor(spec),
		struck = {},
		mass = mass,
		ram = ram,
		weight = math.sqrt(strength) * ram,
		pace = 0,
		stunnedUntil = 0,
		yaw = 0,
		throttle = 0,
		steer = 0,
		model = model,
		climber = climber,
		climbRays = if climbs then MechClimb.rays(W, L) else nil,
		climb = MechClimb.new(),
		climbing = false,
	}
	-- While someone drives, the server simulates the car (and the seated driver with it). When
	-- they get out, hand their character's physics back to them. A driver getting out of a cab
	-- stands up in it.
	local function watchDriver(seat: VehicleSeat)
		local lastDriver: Player? = nil
		seat:GetPropertyChangedSignal("Occupant"):Connect(function()
			model:SetAttribute("LastUsed", os.clock())
			if seat == legsDriverSeat(car) then
				car.throttle = 0
				car.steer = 0
				stopClimb(car)
			end
			local occupant = seat.Occupant
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
				pcall(root.SetNetworkOwner, root, previous)
			end)
		end)
	end
	watchDriver(driver)
	car.legsSeat = legsSeat
	if legsSeat then
		watchDriver(legsSeat)
	end

	if spec.pod and podBone then
		local pivot = podBone.pivot
		-- The walker's exit, moved from the legs' frame to the pod's: the same spot around the
		-- pod's root, the same height over the ground.
		local exit = spec.exit or CFrame.new(0, 3, 0)
		local podExit = CFrame.new(exit.X - pivot.X, exit.Y, exit.Z - pivot.Z) * exit.Rotation
		local jets = {}
		for _, mouth in spec.pod.jets or {} do
			table.insert(jets, CFrame.new(mouth - pivot))
		end
		car.pod = PodFlight.new({
			model = model,
			skid = skid,
			seat = driver,
			root = podBone.part,
			joint = podBone.part:FindFirstChild("Joint_" .. spec.pod.bone) :: Motor6D,
			button = CFrame.new(spec.pod.button - pivot),
			jets = jets,
			exit = podExit,
			legsSeat = legsSeat,
			passengers = passengers,
			-- Off the legs and onto the ground at the walker's exit.
			dismount = function(humanoid: Humanoid)
				local weld = legsSeat and legsSeat:FindFirstChild("SeatWeld")
				if weld then
					weld:Destroy()
				end
				humanoid.Sit = false
				local character = humanoid.Parent
				if character and character:IsA("Model") then
					placeAtExit(skid, spec.exit or CFrame.new(0, 3, 0), character)
				end
			end,
			eject = eject or function() end,
		})
	end

	model.Parent = folder
	cars[model] = car
	-- No terrain collision under the spot yet: hold the vehicle in place until there is, then set
	-- it on the surface. Unheld, it would fall through and stay buried (a walker until its lowest
	-- collision box catches on the surface, with its prompt and exit underground).
	if not grounded then
		skid.Anchored = true
		task.spawn(function()
			local deadline = os.clock() + GROUND_WAIT
			while skid.Parent and os.clock() < deadline do
				task.wait(0.1)
				local spot, found = onTerrain(cframe, W, L)
				if found then
					model:PivotTo(spot * CFrame.new(0, 0.5, 0))
					break
				end
			end
			if os.clock() >= deadline then
				warn("[Mayhem vehicle] no terrain under " .. spec.name .. "; releasing it anyway")
			end
			skid.Anchored = false
		end)
	end
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

-- Someone in a seat, or standing in the cab.
local function isOccupied(model: Model): boolean
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("Seat") or descendant:IsA("VehicleSeat") then
			if (descendant :: any).Occupant then
				return true
			end
		end
	end
	local cab = model:FindFirstChild("Cab")
	if cab and cab:IsA("BasePart") then
		for _, player in Players:GetPlayers() do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if root then
				local offset = cab.CFrame:PointToObjectSpace(root.Position)
				local half = cab.Size / 2
				if
					math.abs(offset.X) <= half.X
					and math.abs(offset.Y) <= half.Y
					and math.abs(offset.Z) <= half.Z
				then
					return true
				end
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
local LOBBY_MARGIN = 10 -- no vehicle parks within this of the lobby wall
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
			if Vector2.new(corner.X, corner.Z).Magnitude < Config.LOBBY_RADIUS + LOBBY_MARGIN then
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

-- The height isClear checks above a vehicle's footprint.
local function clearHeight(spec: VehicleModel.Model): number
	local top = solidHeight(spec)
	return if top > CLEAR_HEIGHT then top + 2 else CLEAR_HEIGHT
end

local function addSpot(id: string, ground: CFrame)
	local spot: Spot = { id = id, cframe = ground + Vector3.new(0, 0.2, 0) }
	table.insert(spots, spot)
	park(spot)
end

-- Walkers (specs with a gait) stand guard in a ring around the lobby, facing out toward the
-- arena: one in the middle of each gap between the gate roads, spread evenly when their count
-- differs from the gates'. The ring is as tight as isClear allows the deepest walker, whose back
-- edge sits CLEARANCE past the lobby margin. Returns the walkers whose spot was blocked.
local function placeWalkers(walkers: { VehicleCatalog.Vehicle }): { VehicleCatalog.Vehicle }
	local depth = 0
	for _, entry in walkers do
		depth = math.max(depth, specFor(entry.id).footprint.Y)
	end
	local radius = Config.LOBBY_RADIUS + LOBBY_MARGIN + CLEARANCE + depth / 2
	local firstGap = Config.regionAngle(1) + math.pi / #Config.REGIONS
	local blocked = {}
	for index, entry in walkers do
		local spec = specFor(entry.id)
		local angle = firstGap + (index - 1) * 2 * math.pi / #walkers
		local position = Config.pointAt(angle, radius)
		local ground = CFrame.lookAt(position, position + Config.pointAt(angle, 1))
		if isClear(ground, spec.footprint.X, spec.footprint.Y, clearHeight(spec)) then
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
		local spoke = (order - 1) % #Config.REGIONS + 1
		local spec = specFor(entry.id)
		local W, L = spec.footprint.X, spec.footprint.Y
		local height = clearHeight(spec)
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
		addSpot(entry.id, ground)
	end
end

function Vehicles.start()
	PodFlight.start()
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
