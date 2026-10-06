-- Arcade vehicles scattered around the motor pools beside each spoke road. A vehicle is a frictionless skid
-- carrying welded body parts, built from its model file in `src/server/vehicleModels`. The
-- driver's client sends its stick/keys over the DriveInput remote; the server turns that into
-- targets for velocity constraints on the skid. Constraints are simulated by whichever machine
-- owns the vehicle's physics, so this works under any ownership. Wrecked or abandoned vehicles
-- return to their parking spot. A driven vehicle hurts whoever it touches (cars ram, walkers
-- stomp), shoves the vehicles it hits, and fells trees. A walker with a pod (spec.pod) can send
-- its cab flying (PodFlight); while the pod is away its legs park. A hard crash damages a vehicle
-- by its size (VehicleDamage); at no health it is wrecked: it explodes, throws out whoever is
-- aboard, and burns out. A driven walker climbs walls up to MechClimb.MAX_RISE: it senses them
-- with rays, MechClimb decides, and a vertical velocity constraint (the "Climber") lifts it; the
-- model's "Climbing" attribute says when.

local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local MechClimb = require(ReplicatedStorage.Shared.MechClimb)
local Names = require(ReplicatedStorage.Shared.Names)
local PodState = require(ReplicatedStorage.Shared.PodState)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local SoundCatalog = require(ReplicatedStorage.Shared.SoundCatalog)
local Sounds = require(ReplicatedStorage.Shared.Sounds)
local VehicleCatalog = require(ReplicatedStorage.Shared.VehicleCatalog)
local VehicleDamage = require(ReplicatedStorage.Shared.VehicleDamage)
local VehicleDrive = require(ReplicatedStorage.Shared.VehicleDrive)
local VehicleLayout = require(ReplicatedStorage.Shared.VehicleLayout)
local VehicleRam = require(ReplicatedStorage.Shared.VehicleRam)
local VehicleSizing = require(ReplicatedStorage.Shared.VehicleSizing)
local Combat = require(script.Parent.Combat)
local PodFlight = require(script.Parent.PodFlight)
local VehicleModel = require(script.Parent.VehicleModel)
local Characters = require(script.Parent.util.Characters)
local Ownership = require(script.Parent.util.Ownership)
local Parts = require(script.Parent.util.Parts)
local Prompts = require(script.Parent.util.Prompts)
local Seats = require(script.Parent.util.Seats)

local Vehicles = {}

local rgb = Color3.fromRGB
local M = Enum.Material

local modelFiles = script.Parent.Parent:FindFirstChild("vehicleModels")

local folder = Instance.new("Folder")
folder.Name = Names.Instances.Vehicles
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

-- Drive tuning for a model that leaves it out. Drive and settling math: VehicleDrive.
local ACCELERATION = VehicleModel.DEFAULTS.acceleration
local BRAKING = VehicleModel.DEFAULTS.braking
local COASTING = VehicleModel.DEFAULTS.coasting
local TURN_RATE = VehicleModel.DEFAULTS.turnRate

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
	crash: Crash, -- crash damage
	model: Model,
	climber: LinearVelocity?, -- vertical lift for the climb assist; nil when it does not climb
	climbRays: MechClimb.Rays?,
	climb: MechClimb.State,
	climbing: boolean, -- mirrors the model's "Climbing" attribute
}

-- Every live car, by model.
local cars: { [Model]: Car } = {}

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
climbParams.CollisionGroup = Names.CollisionGroups.Walkers
climbParams.RespectCanCollide = true

-- Terrain and anchored parts are climbable, unless they or a parent are tagged NoClimb.
local function climbable(hit: RaycastResult): boolean
	local instance = hit.Instance
	if not instance:IsA("Terrain") and not (instance:IsA("BasePart") and instance.Anchored) then
		return false
	end
	local node: Instance? = instance
	while node and node ~= workspace do
		if CollectionService:HasTag(node, Names.Tags.NoClimb) then
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
	local headroom = true
	for _, ray in rays.headroom do
		if cast(ray, false) then
			headroom = false
			break
		end
	end
	local bottom = ground.Position.Y
	local top = cast(rays.ledge, true)
	local foot = cast(rays.foot, true)
	return {
		wall = wall,
		ledge = if top then { height = top.Position.Y - bottom, normalY = top.Normal.Y } else nil,
		headroom = headroom,
		foot = if foot then foot.Position.Y - bottom else nil,
	}
end

local function setClimbing(car: Car, climbing: boolean)
	if car.climbing ~= climbing then
		car.climbing = climbing
		car.model:SetAttribute(Names.Attributes.Climbing, climbing)
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
		local force = VehicleDrive.climbForce(skid.AssemblyMass, workspace.Gravity)
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
		local settling = VehicleDrive.isSettling(car.parkingBrake, flat.Magnitude, spin)
		local held = car.parkingBrake or settling
		car.mover.Enabled = held
		car.turner.Enabled = held
		if car.parkingBrake then
			setLimits(car, car.driveForce, car.driveTorque)
			car.mover.PlaneVelocity = Vector2.zero
			car.turner.AngularVelocity = Vector3.zero
		elseif settling then
			-- Limits sized to the settling rates: a sliding friction other vehicles push through.
			local force, torque =
				VehicleDrive.settlingLimits(skid.AssemblyMass, skid.Size.X, skid.Size.Z)
			setLimits(car, force, torque)
			local slowed = VehicleDrive.settledSpeed(flat.Magnitude, dt)
			car.mover.PlaneVelocity = if flat.Magnitude > 0
				then flat.Unit * slowed
				else Vector2.zero
			car.turner.AngularVelocity = Vector3.new(0, VehicleDrive.settledSpin(spin, dt), 0)
		end
		return
	end
	setLimits(car, car.driveForce, car.driveTorque)
	car.mover.Enabled = true
	car.turner.Enabled = true

	local topSpeed = (car.seat:GetAttribute(Names.Attributes.TopSpeed) :: number?)
		or VehicleDrive.DEFAULT_TOP_SPEED
	local look = skid.CFrame.LookVector
	local forward = Vector3.new(look.X, 0, look.Z).Unit
	local speed = skid.AssemblyLinearVelocity:Dot(forward)
	local newSpeed = VehicleDrive.speed(car, speed, car.throttle, topSpeed, dt)
	local climb = climbStep(car, forward, dt)
	if climb and climb.press then
		newSpeed = climb.press
	end

	car.mover.PlaneVelocity = Vector2.new(forward.X * newSpeed, forward.Z * newSpeed)
	local climbing = climb ~= nil and climb.climbing
	local yaw = VehicleDrive.yaw(car, car.yaw, car.steer, newSpeed, climbing, dt)
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
	local humanoid = Characters.humanoidOf(player)
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
	part.Anchored = false
	part.Massless = true
	Parts.weldTo(skid, part, SKID_TO_GROUND * offset, model)
end

type Bone = { part: BasePart, pivot: Vector3 }

-- Welds a part to a bone at an offset given in vehicle space, rest pose. The bone's Transform
-- then moves it. No bone: welded to the skid.
local function attachTo(model: Model, skid: BasePart, bone: Bone?, part: BasePart, offset: CFrame)
	if not bone then
		attach(model, skid, part, offset)
		return
	end
	part.Anchored = false
	part.Massless = true
	Parts.weldTo(bone.part, part, CFrame.new(bone.pivot):Inverse() * offset, model)
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
	for _, boneSpec in (spec.bones or {}) :: { VehicleModel.BoneSpec } do
		local part = Instance.new("Part")
		part.Name = Names.Instances.BonePrefix .. boneSpec.name
		part.Size = Vector3.new(0.2, 0.2, 0.2)
		part.Transparency = 1
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.Massless = true
		part.CFrame = skid.CFrame * SKID_TO_GROUND * CFrame.new(boneSpec.pivot)
		local parent = boneSpec.parent and bones[boneSpec.parent]
		local joint = Instance.new("Motor6D")
		joint.Name = Names.Instances.JointPrefix .. boneSpec.name
		joint.Part0 = if parent then parent.part else skid
		joint.Part1 = part
		joint.C0 = if parent
			then CFrame.new(parent.pivot):Inverse() * CFrame.new(boneSpec.pivot)
			else SKID_TO_GROUND * CFrame.new(boneSpec.pivot)
		joint.Parent = part
		if boneSpec.aim then
			part:SetAttribute(Names.Attributes.Aim, boneSpec.aim)
		end
		if boneSpec.steer then
			part:SetAttribute(Names.Attributes.Steer, boneSpec.steer)
		end
		if boneSpec.wobble then
			part:SetAttribute(Names.Attributes.Wobble, true)
		end
		part.Parent = model
		bones[boneSpec.name] = { part = part, pivot = boneSpec.pivot }
	end
	return bones
end

-- An Attachment "Smoke" at each smokestack mouth, on its bone. Clients (MechMotion) emit from it.
local function addSmoke(skid: BasePart, bones: { [string]: Bone }, spec: VehicleModel.Model)
	for _, stack in (spec.smoke or {}) :: { VehicleModel.SmokeSpec } do
		local bone = stack.bone and bones[stack.bone]
		local attachment = Instance.new("Attachment")
		attachment.Name = Names.Instances.Smoke
		attachment.CFrame = if bone
			then CFrame.new(bone.pivot):Inverse() * CFrame.new(stack.position)
			else SKID_TO_GROUND * CFrame.new(stack.position)
		attachment.Parent = if bone then bone.part else skid
	end
end

-- Climbable TrussParts welded to the skid.
local function addLadders(model: Model, skid: BasePart, spec: VehicleModel.Model)
	for index, ladder in (spec.ladders or {}) :: { VehicleModel.LadderSpec } do
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

-- Crash damage ---------------------------------------------------------------------------------

-- Each Heartbeat samples the velocity of the skid (and of a pod away from its legs) into a
-- VehicleDamage tracker; a crash it reports costs the vehicle health (model attributes Health and
-- MaxHealth, from its bulk). Only assemblies the server simulates are tracked: a client's samples
-- arrive late and jumpy. Anything else that sets a tracked velocity (a shove, a pod docking)
-- clears the tracker. At half health the vehicle smokes, at a quarter it burns; at none it is
-- wrecked.

local WRECK_DAMAGE = 35 -- the wreck's blast at its center
local WRECK_THROW = 60 -- studs/s up that throws out whoever is aboard
local WRECK_SCATTER = 20 -- studs/s, at most, sideways
local WRECK_HOP = 25 -- studs/s up the hulk jumps
local WRECK_TIME = 10 -- seconds the burnt-out hulk stays
local CHAR_COLOR = rgb(20, 20, 20)
local CHAR_SHARE = 0.75 -- how far each part's color goes to CHAR_COLOR

type Crash = {
	bulk: number,
	walker: boolean, -- lands on its legs (VehicleDamage.thresholds)
	length: number, -- footprint length: a head-on crash's sparks fly at the front
	height: number, -- solid height: smoke and fire rise from half of it
	podBulk: number, -- the flying pod's, from its own hull boxes
	podLength: number,
	podMass: number, -- the pod's footprint mass, for rams into it while it is away
	tracker: VehicleDamage.Tracker, -- the skid
	podTracker: VehicleDamage.Tracker, -- the pod's root while it is away
	podState: PodState.State, -- last seen; any change clears both trackers
	climbOut: ((Player) -> ())?, -- a walker's cab exit
	lastHit: BasePart?, -- the part (skid or pod root) that took the last damage: the wreck's center
	smoke: Smoke?,
	fire: Fire?,
}

local scatter = Random.new()

local function newCrash(id: string, spec: VehicleModel.Model): Crash
	local entry = VehicleCatalog.get(id)
	local override = entry and entry.bulk
	local size = VehicleSizing.crash(spec, override)
	return {
		bulk = size.bulk,
		walker = size.walker,
		length = size.length,
		height = size.height,
		podBulk = size.podBulk,
		podLength = size.podLength,
		podMass = size.podMass,
		tracker = VehicleDamage.newTracker(),
		podTracker = VehicleDamage.newTracker(),
		podState = PodState.DOCKED,
		climbOut = nil,
		lastHit = nil,
		smoke = nil,
		fire = nil,
	}
end

-- A crash's sound and a burst of sparks at `at`.
local function crashFeedback(model: Model, at: Vector3, amount: number)
	local maxHealth = (model:GetAttribute(Names.Attributes.MaxHealth) :: number?) or 100
	local cue = if VehicleDamage.isHeavy(amount, maxHealth)
		then SoundCatalog.CRASH.heavy
		else SoundCatalog.CRASH.light
	Sounds.playAt(cue, at, "Weapons")
	local spot = Instance.new("Attachment")
	spot.Name = "CrashSparks"
	spot.Position = at -- Terrain sits at the origin
	spot.Parent = workspace.Terrain
	local sparks = Instance.new("ParticleEmitter")
	sparks.Enabled = false
	sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparks.LightEmission = 1
	sparks.Color = ColorSequence.new(rgb(255, 240, 170), rgb(255, 120, 30))
	sparks.Size = NumberSequence.new(0.5, 0)
	sparks.Lifetime = NumberRange.new(0.3, 0.7)
	sparks.Speed = NumberRange.new(20, 45)
	sparks.SpreadAngle = Vector2.new(180, 180)
	sparks.Acceleration = Vector3.new(0, -workspace.Gravity / 4, 0)
	sparks.Parent = spot
	sparks:Emit(math.clamp(math.round(amount), 8, 60))
	Debris:AddItem(spot, 1.5)
end

-- Feeds `part`'s velocity to `tracker`, and damages the vehicle by a crash it reports.
local function sampleCrash(
	model: Model,
	crash: Crash,
	part: BasePart,
	tracker: VehicleDamage.Tracker,
	bulk: number,
	walker: boolean,
	length: number,
	dt: number
)
	if not Ownership.isServerSimulated(part) then
		VehicleDamage.clear(tracker)
		return
	end
	local velocity = part.AssemblyLinearVelocity
	local lossH, lossV = VehicleDamage.step(tracker, velocity.X, velocity.Y, velocity.Z, dt)
	if not lossH or not lossV then
		return
	end
	local amount = VehicleDamage.damage(bulk, lossH, lossV, walker)
	if amount <= 0 then
		return
	end
	-- Head-on: at the front, the way it was going. A landing: under it.
	local at = VehicleDamage.crashPoint(
		part.Position,
		tracker.startX,
		tracker.startZ,
		lossH,
		lossV,
		length
	)
	crashFeedback(model, at, amount)
	crash.lastHit = part
	Vehicles.damage(model, amount)
end

local function trackCrash(model: Model, car: Car, dt: number)
	local crash = car.crash
	local podState = if car.pod then car.pod.state else PodState.DOCKED
	if podState ~= crash.podState then
		-- A pod letting go of its legs or snapping back onto them jumps both velocities.
		crash.podState = podState
		VehicleDamage.clear(crash.tracker)
		VehicleDamage.clear(crash.podTracker)
	end
	sampleCrash(model, crash, car.skid, crash.tracker, crash.bulk, crash.walker, crash.length, dt)
	if car.pod and podState ~= PodState.DOCKED then
		sampleCrash(
			model,
			crash,
			car.pod.root,
			crash.podTracker,
			crash.podBulk,
			false,
			crash.podLength,
			dt
		)
	end
end

-- A ram hits the struck vehicle like a crash that lost `loss` studs/s (VehicleDamage.ramLoss):
-- its legs (the skid), or with `pod` its pod away from them. A shove sets the velocity, so the
-- tracker starts over.
local function rammed(other: Car, loss: number, pod: boolean?)
	local crash = other.crash
	local part = if pod and other.pod then other.pod.root else other.skid
	VehicleDamage.clear(if pod then crash.podTracker else crash.tracker)
	local amount = VehicleDamage.damage(if pod then crash.podBulk else crash.bulk, loss, 0)
	local model = other.skid.Parent
	if amount > 0 and model and model:IsA("Model") then
		crashFeedback(model, part.Position, amount)
		crash.lastHit = part
		Vehicles.damage(model, amount)
	end
end

-- Throws whoever sits in `seat` out and up.
local function throwOut(seat: (Seat | VehicleSeat)?)
	local humanoid = seat and seat.Occupant
	if not seat or not humanoid then
		return
	end
	Seats.unseat(seat, humanoid)
	local character = humanoid.Parent
	if character and character:IsA("Model") then
		local sideways = Vector3.new(
			scatter:NextNumber(-WRECK_SCATTER, WRECK_SCATTER),
			0,
			scatter:NextNumber(-WRECK_SCATTER, WRECK_SCATTER)
		)
		Combat.push(character, sideways + Vector3.new(0, WRECK_THROW, 0), 0.2)
	end
end

-- Destroys a vehicle at no health: it brakes to a stop, throws out everyone aboard (a walker's cab
-- puts whoever stands in it at the exit), explodes, chars, hops, and is cleared after WRECK_TIME.
-- A parked vehicle's spot then builds a fresh one (Vehicles.start); a /give vehicle is gone.
local function wreck(model: Model, car: Car)
	if model:GetAttribute(Names.Attributes.Wrecked) then
		return
	end
	model:SetAttribute(Names.Attributes.Wrecked, true)
	model:SetAttribute(Names.Attributes.Health, 0)
	cars[model] = nil
	-- The skid is frictionless: the drive constraints, held at zero, are the hulk's brake. A
	-- rammed wreck flies its throw out first (the rest of VehicleRam.STUN_TIME), then brakes.
	local function brake()
		setLimits(car, car.driveForce, car.driveTorque)
		car.mover.PlaneVelocity = Vector2.zero
		car.turner.AngularVelocity = Vector3.zero
		car.mover.Enabled = true
		car.turner.Enabled = true
	end
	local stun = car.stunnedUntil - os.clock()
	if stun > 0 then
		car.mover.Enabled = false
		car.turner.Enabled = false
		task.delay(stun, brake)
	else
		brake()
	end
	-- A walker wrecked mid-climb lets go and falls.
	stopClimb(car)
	if car.pod then
		PodFlight.wreck(car.pod)
	end
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("ProximityPrompt") then
			descendant:Destroy()
		end
	end
	throwOut(car.seat)
	throwOut(car.legsSeat)
	for _, seat in car.passengers do
		throwOut(seat)
	end
	local climbOut = car.crash.climbOut
	local cab = model:FindFirstChild(Names.Instances.Cab) :: BasePart?
	if climbOut and cab then
		-- Deferred: a thrown-out driver sits until the weld's removal lands, and climbOut skips
		-- anyone seated.
		task.defer(function()
			for _, player in Players:GetPlayers() do
				if Characters.isInside(player, cab) then
					climbOut(player)
				end
			end
		end)
	end

	-- At the part that crashed (a flying pod, or the legs), else the skid.
	local hit = car.crash.lastHit
	local center = if hit and hit:IsDescendantOf(model) then hit.Position else car.skid.Position
	Combat.explode(nil, center, VehicleDamage.wreckRadius(car.crash.bulk), WRECK_DAMAGE)
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and part.Transparency < 1 then
			part.Color = part.Color:Lerp(CHAR_COLOR, CHAR_SHARE)
			part.Material = M.CorrodedMetal
		end
	end
	if Ownership.isServerSimulated(car.skid) then
		car.skid.AssemblyLinearVelocity += Vector3.new(0, WRECK_HOP, 0)
	end
	task.delay(WRECK_TIME, function()
		model:Destroy()
	end)
end

-- Smoke at half health and fire at a quarter, from the skid at half the solid height; a wreck at
-- none.
local function onHealth(model: Model, car: Car)
	if model:GetAttribute(Names.Attributes.Wrecked) then
		return
	end
	local health = (model:GetAttribute(Names.Attributes.Health) :: number?) or 0
	local maxHealth = (model:GetAttribute(Names.Attributes.MaxHealth) :: number?) or 1
	local crash = car.crash
	local share = health / maxHealth
	if VehicleDamage.smokes(share) and not crash.smoke then
		local spot = Instance.new("Attachment")
		spot.Name = "DamageFx"
		spot.Position = Vector3.new(0, math.max(crash.height / 2, 1), 0)
		spot.Parent = car.skid
		local size = 4 + 2 * math.sqrt(crash.bulk)
		local smoke = Instance.new("Smoke")
		smoke.Color = rgb(45, 45, 48)
		smoke.Opacity = 0.4
		smoke.Size = size
		smoke.RiseVelocity = 8
		smoke.Parent = spot
		local fire = Instance.new("Fire")
		fire.Size = math.min(size, 30)
		fire.Heat = 12
		fire.Enabled = false
		fire.Parent = spot
		crash.smoke, crash.fire = smoke, fire
	end
	if crash.smoke and crash.fire then
		crash.smoke.Enabled = VehicleDamage.smokes(share)
		crash.fire.Enabled = VehicleDamage.burns(share)
	end
	if health <= 0 then
		wreck(model, car)
	end
end

-- Health from the vehicle's bulk, set before the model is parented so clients see it at once.
local function addHealth(model: Model, car: Car)
	local maxHealth = VehicleDamage.maxHealth(car.crash.bulk)
	model:SetAttribute(Names.Attributes.MaxHealth, maxHealth)
	model:SetAttribute(Names.Attributes.Health, maxHealth)
	model:GetAttributeChangedSignal(Names.Attributes.Health):Connect(function()
		onHealth(model, car)
	end)
end

-- Takes `amount` health from a vehicle (crashes, rams; weapons could). A wreck takes no more.
function Vehicles.damage(model: Model, amount: number)
	local health = model:GetAttribute(Names.Attributes.Health)
	if
		model:GetAttribute(Names.Attributes.Wrecked)
		or typeof(health) ~= "number"
		or amount <= 0
	then
		return
	end
	model:SetAttribute(Names.Attributes.Health, math.max(0, health - amount))
end

-- Contact damage and ramming -------------------------------------------------------------------

-- The numbers (pace, shoves, flings, tree breaks) are VehicleRam's; the reach box is
-- VehicleSizing.reach.
local HIT_INTERVAL = 0.1 -- seconds between contact checks on characters and barrels
local HIT_COOLDOWN = 0.8 -- seconds before the same vehicle hits the same victim again
local TREE_LIE = 15 -- seconds a felled tree lies before it is cleared
local TREE_REGROW = 120 -- seconds until it grows back where it stood

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
CollectionService:GetInstanceAddedSignal(Names.Tags.Tree):Connect(addGrove)
for _, tree in CollectionService:GetTagged(Names.Tags.Tree) do
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
	local creatures = workspace:FindFirstChild(Names.Instances.Creatures)
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
			part.CollisionGroup = Names.CollisionGroups.Wreckage
			part.CanTouch = false
			part.Anchored = false
			mass += part:GetMass()
		end
	end
	Ownership.set(trunk, nil)
	-- Pushed high, the tree pivots on its base and falls the way the vehicle was going.
	local crown = VehicleRam.treeCrown(box, extent)
	local push = VehicleRam.treePush(pace, weight)
	trunk:ApplyImpulseAtPosition(direction * push * mass, crown)
	task.delay(TREE_LIE, function()
		tree:Destroy()
	end)
	task.delay(TREE_REGROW, regrow, sapling, grove, box, extent)
end

-- Throws a struck vehicle along `direction`, scaled by the rammer's pace, ram and the two masses,
-- and frees it from its drive constraints for VehicleRam.STUN_TIME so the throw carries. Its
-- damage comes from `closing`, the rammer's real speed toward it.
local function shove(
	car: Car,
	other: Car,
	direction: Vector3,
	pace: number,
	closing: number,
	now: number
)
	local skid = other.skid
	local transfer = VehicleRam.transfer(car.mass, other.mass, car.ram)
	local speed = VehicleRam.shoveSpeed(pace, closing, car.stomps, transfer)
	if speed < VehicleRam.MIN_SHOVE then
		-- No throw, so no stun: a car pinned by a creeping walker keeps its drive and can back out.
		rammed(other, VehicleDamage.ramLoss(closing, transfer, car.stomps))
		return
	end
	-- Stunned first: a ram that wrecks it lets the throw fly before the wreck brakes (wreck).
	other.stunnedUntil = now + VehicleRam.STUN_TIME
	rammed(other, VehicleDamage.ramLoss(closing, transfer, car.stomps))
	-- The server must own the struck vehicle for the throw to take. A driven one it already owns;
	-- an empty one it takes here. One carrying only passengers stays with their client, which
	-- leaves it to the collision alone.
	local aboard = other.seat.Occupant ~= nil
	for _, seat in other.passengers do
		aboard = aboard or seat.Occupant ~= nil
	end
	if not aboard then
		Ownership.set(skid, nil)
	end
	skid.AssemblyLinearVelocity =
		VehicleRam.shoveVelocity(skid.AssemblyLinearVelocity, direction, speed)
end

-- Vehicles and trees are checked every frame with a box that reaches one frame ahead, so the hit
-- lands before the crash stops the rammer. Characters and barrels are checked every
-- HIT_INTERVAL (`checkTargets`).
local function hurtTouching(model: Model, car: Car, dt: number, checkTargets: boolean)
	local skid = car.skid
	local velocity = skid.AssemblyLinearVelocity
	local flat = Vector3.new(velocity.X, 0, velocity.Z)
	local speed = flat.Magnitude
	car.pace = VehicleRam.decayPace(car.pace, speed, dt)
	local legsDriver = legsDriverSeat(car)
	local occupant = legsDriver and legsDriver.Occupant
	local now = os.clock()
	-- A shoved vehicle hits nothing until it is back under control: no chains of shoves.
	if not occupant or now < car.stunnedUntil then
		return
	end
	local driver = Players:GetPlayerFromCharacter(occupant.Parent)
	if not VehicleRam.isMoving(car.stomps, speed, skid.AssemblyAngularVelocity.Y, car.pace) then
		return
	end
	local pace = VehicleRam.ramPace(car.stomps, car.pace)
	local ground = skid.CFrame * SKID_TO_GROUND
	local heading = VehicleRam.heading(flat, speed, ground.LookVector)
	local function away(position: Vector3): Vector3
		return VehicleRam.away(ground.Position, position, heading)
	end

	local box, size = VehicleRam.sweep(ground, flat, car.reach, dt)
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
		local pod = other and other.pod
		if
			other
			and pod
			and not PodFlight.isDocked(pod)
			and part.AssemblyRootPart == pod.root.AssemblyRootPart
		then
			-- Its pod, away from the legs: damage only. The pod's own mover holds its course; the
			-- legs are not touched.
			car.struck[victim :: Model] = now
			local struck = pod.root.AssemblyLinearVelocity
			local outward = away(pod.root.Position)
			local closing = VehicleDamage.closingSpeed(
				velocity.X,
				velocity.Z,
				struck.X,
				struck.Z,
				outward.X,
				outward.Z
			)
			local transfer = VehicleRam.transfer(car.mass, other.crash.podMass, car.ram)
			rammed(other, VehicleDamage.ramLoss(closing, transfer, car.stomps), true)
		elseif other then
			car.struck[victim :: Model] = now
			local outward = away(other.skid.Position)
			local direction = VehicleRam.shoveDirection(car.stomps, heading, outward)
			local struck = other.skid.AssemblyLinearVelocity
			local closing = VehicleDamage.closingSpeed(
				velocity.X,
				velocity.Z,
				struck.X,
				struck.Z,
				outward.X,
				outward.Z
			)
			shove(car, other, direction, pace, closing, now)
		elseif CollectionService:HasTag(victim, Names.Tags.Tree) then
			local toughness = (victim:GetAttribute(Names.Attributes.Toughness) :: number?) or 1
			if VehicleRam.breaksTree(pace, car.weight, toughness) then
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
			or not VehicleRam.touches(car.reach, ground, target.root.Position)
		then
			continue
		end
		local amount = VehicleRam.contactDamage(car.stomps, pace, car.weight)
		if Combat.damage(driver, target.model, humanoid, amount) then
			car.struck[target.model] = now
			local direction = if car.stomps or speed < 1
				then away(target.root.Position)
				else heading
			local creature = Players:GetPlayerFromCharacter(target.model) == nil
			local push = VehicleRam.fling(direction, car.stomps, pace, car.weight, creature)
			if creature and humanoid.Health <= 0 then
				-- A kill: throw the whole body before its joints break, so the pieces scatter.
				target.root.AssemblyLinearVelocity = push
			end
			Combat.push(target.model, push, 0.2)
		end
	end
	for _, barrel in CollectionService:GetTagged(Names.Tags.ExplosiveBarrel) do
		if barrel:IsA("BasePart") and VehicleRam.touches(car.reach, ground, barrel.Position) then
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
			trackCrash(model, car, dt)
			hurtTouching(model, car, dt, checkTargets)
		end
	end
end)

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

local function build(id: string, cframe: CFrame): Model
	local spec = specFor(id)
	local model = Instance.new("Model")
	model.Name = spec.name
	model:SetAttribute(Names.Attributes.VehicleId, id)
	local W, L = spec.footprint.X, spec.footprint.Y
	local grounded
	cframe, grounded = onTerrain(cframe, W, L)

	-- The skid and its ramps are the only massive parts: a low, frictionless sled under the
	-- footprint. Its ends are ramps whose undersides slope up like a sled's nose, so driving into
	-- a ledge up to RAMP_HEIGHT (road edges, plazas, steps) lifts the vehicle onto it.
	local ramp = math.min(RAMP_LENGTH, L / 4)
	local skid = Instance.new("Part")
	skid.Name = Names.Instances.Skid
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
		Parts.weldTo(skid, wedge, relative, model)
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
	local group = if spec.stepsOver
		then Names.CollisionGroups.Walkers
		else Names.CollisionGroups.Vehicles
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.CollisionGroup = group
		end
	end

	for _, piece in spec.pieces do
		local part = Parts.fromPiece(piece, "Piece")
		part.CastShadow = part.Transparency < 0.5
		if piece.hideInCockpit then
			part:SetAttribute(Names.Attributes.HideInCockpit, true) -- MechCamera
		end
		attachTo(model, skid, piece.bone and bones[piece.bone], part, piece.offset)
	end

	-- Outside-view camera subject.
	if spec.cameraFocus then
		local focus = Instance.new("Part")
		focus.Name = Names.Instances.CameraFocus
		focus.Size = Vector3.one
		focus.Transparency = 1
		focus.CanCollide = false
		focus.CanTouch = false
		focus.CanQuery = false
		attachTo(model, skid, podBone, focus, CFrame.new(spec.cameraFocus))
	end
	if spec.gait then
		model:SetAttribute(Names.Attributes.Gait, spec.gait)
	end

	local driver: VehicleSeat
	local passengers: { Seat } = {}
	for index, offset in spec.seats do
		local chair: BasePart = Instance.new(if index == 1 then "VehicleSeat" else "Seat") :: any
		chair.Name = if index == 1 then Names.Instances.DriverSeat else "Seat" .. index
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
		saddle.Name = Names.Instances.LegsSeat
		saddle.Size = VehicleModel.SEAT_SIZE
		saddle.Transparency = 1
		saddle.CanCollide = false
		saddle.CanTouch = false
		saddle.MaxSpeed = spec.speed
		saddle:SetAttribute(Names.Attributes.MayhemCar, true) -- CarInput sends its driver's input
		saddle:SetAttribute(Names.Attributes.TopSpeed, spec.speed)
		saddle:SetAttribute(Names.Attributes.LegsSeat, true)
		attachTo(model, skid, legsBone, saddle, spec.pod.legsSeat)
		legsSeat = saddle
	end
	addPrompts(skid, spec, driver, passengers, legsSeat)
	driver.MaxSpeed = spec.speed
	driver:SetAttribute(Names.Attributes.MayhemCar, true)
	driver:SetAttribute(Names.Attributes.TopSpeed, spec.speed)
	if spec.cockpitCamera then
		driver:SetAttribute(Names.Attributes.CockpitCamera, true)
	end
	local eject: ((Player) -> ())? = nil
	if spec.cab then
		eject = addCab(model, skid, spec, driver, podBone)
	end
	if spec.gait then
		driver:SetAttribute(Names.Attributes.TurnRate, spec.turnRate or TURN_RATE) -- the walk animator reads it
	end

	local strength = VehicleDrive.strength(W, L, spec.uprightTorque)

	-- Keeps the vehicle upright without fixing its heading.
	local attachment = Instance.new("Attachment")
	attachment.CFrame = CFrame.Angles(0, 0, math.rad(90))
	attachment.Parent = skid
	local upright = Instance.new("AlignOrientation")
	upright.Mode = Enum.OrientationAlignmentMode.OneAttachment
	upright.AlignType = Enum.AlignType.PrimaryAxisParallel
	upright.PrimaryAxis = Vector3.yAxis
	upright.Attachment0 = attachment
	upright.MaxTorque = strength.uprightTorque
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
	mover.MaxForce = strength.moverForce
	mover.Enabled = false
	mover.Parent = skid
	local turner = Instance.new("AngularVelocity")
	turner.Attachment0 = driveAttachment
	turner.RelativeTo = Enum.ActuatorRelativeTo.World
	turner.MaxTorque = strength.turnerTorque
	turner.Enabled = false
	turner.Parent = skid
	-- Climb assist: a vertical velocity on the same attachment, off until a climb (climbStep).
	local climbs = spec.gait ~= nil and spec.climbs ~= false
	local climber: LinearVelocity? = nil
	if climbs then
		local made = Instance.new("LinearVelocity")
		made.Name = "Climber"
		made.Attachment0 = driveAttachment
		made.RelativeTo = Enum.ActuatorRelativeTo.World
		made.VelocityConstraintMode = Enum.VelocityConstraintMode.Line
		made.LineDirection = Vector3.yAxis
		made.Enabled = false
		made.Parent = skid
		climber = made
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
		reach = VehicleSizing.reach(spec),
		struck = {},
		mass = strength.mass,
		ram = ram,
		weight = VehicleRam.weight(strength.strength, ram),
		pace = 0,
		stunnedUntil = 0,
		yaw = 0,
		throttle = 0,
		steer = 0,
		crash = newCrash(id, spec),
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
				local ok, problem = Ownership.set(skid, nil)
				if not ok then
					warn("[Mayhem car] could not take ownership: " .. tostring(problem))
				end
				return
			end
			local previous = lastDriver
			lastDriver = nil
			task.defer(function()
				local root = Characters.rootOf(previous)
				if not root then
					return
				end
				Ownership.set(root, previous)
			end)
		end)
	end
	watchDriver(driver)
	car.legsSeat = legsSeat
	if legsSeat then
		watchDriver(legsSeat)
	end

	if spec.pod and podBone then
		-- The button, jets and the walker's exit, moved from the legs' frame to the pod's (the exit
		-- keeps its height over the ground).
		local frames = VehicleSizing.podFrames(spec, podBone.pivot)
		car.pod = PodFlight.new({
			model = model,
			skid = skid,
			seat = driver,
			root = podBone.part,
			joint = podBone.part:FindFirstChild(Names.Instances.JointPrefix .. spec.pod.bone) :: Motor6D,
			button = frames.button,
			jets = frames.jets,
			exit = frames.exit,
			legsSeat = legsSeat,
			passengers = passengers,
			-- Off the legs and onto the ground at the walker's exit.
			dismount = function(humanoid: Humanoid)
				Seats.unseat(legsSeat, humanoid)
				local character = humanoid.Parent
				if character and character:IsA("Model") then
					placeAtExit(skid, VehicleSizing.exitOf(spec), character)
				end
			end,
			eject = eject or function() end,
		})
	end

	car.crash.climbOut = eject
	addHealth(model, car)
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
function Vehicles.spawnNear(position: Vector3, facing: Vector3?, id: string?): Model
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

function Vehicles.start()
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

return Vehicles
