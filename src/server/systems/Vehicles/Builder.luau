-- Builds a vehicle from its spec (Specs): the skid and its ramps, bones, collision hulls,
-- pieces, seats, prompts and cab (Boarding), the upright, drive and climb constraints, the Car
-- record in Registry.cars, the flying pod (PodFlight) and health (Health). Ownership follows the
-- driver (watchDriver). A vehicle built where the terrain has no collision yet is held until it
-- has.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MechClimb = require(ReplicatedStorage.Shared.MechClimb)
local Names = require(ReplicatedStorage.Shared.Names)
local VehicleDrive = require(ReplicatedStorage.Shared.VehicleDrive)
local VehicleRam = require(ReplicatedStorage.Shared.VehicleRam)
local VehicleSizing = require(ReplicatedStorage.Shared.VehicleSizing)
local PodFlight = require(script.Parent.Parent.PodFlight)
local VehicleModel = require(script.Parent.Parent.VehicleModel)
local Characters = require(script.Parent.Parent.util.Characters)
local Ownership = require(script.Parent.Parent.util.Ownership)
local Parts = require(script.Parent.Parent.util.Parts)
local Seats = require(script.Parent.Parent.util.Seats)
local Boarding = require(script.Parent.Boarding)
local Climb = require(script.Parent.Climb)
local Health = require(script.Parent.Health)
local Placement = require(script.Parent.Placement)
local Registry = require(script.Parent.Registry)
local Specs = require(script.Parent.Specs)

local Builder = {}

local rgb = Color3.fromRGB
local M = Enum.Material

local folder = Registry.folder
local cars = Registry.cars
local legsDriverSeat = Registry.legsDriverSeat
local specFor = Specs.specFor
local SKID_TO_GROUND = Placement.SKID_TO_GROUND
local attach = Placement.attach
local attachTo = Placement.attachTo
local onTerrain = Placement.onTerrain
local stopClimb = Climb.stopClimb
local newCrash = Health.newCrash
local addHealth = Health.addHealth
local addPrompts = Boarding.addPrompts
local placeAtExit = Boarding.placeAtExit
local addCab = Boarding.addCab

type Car = Registry.Car
type Bone = Placement.Bone

-- Drive tuning for a model that leaves it out. Drive and settling math: VehicleDrive.
local ACCELERATION = VehicleModel.DEFAULTS.acceleration
local BRAKING = VehicleModel.DEFAULTS.braking
local COASTING = VehicleModel.DEFAULTS.coasting
local TURN_RATE = VehicleModel.DEFAULTS.turnRate

-- The tallest ledge a vehicle climbs, and the longest stretch of skid that slopes up to it.
-- World ledges: plazas and courtyards 0.6-0.8, roads 0.7, steps 1. Collision boxes start at
-- 1.2 or higher, above the ramps' working height for those ledges.
local RAMP_HEIGHT = 1.6
local RAMP_LENGTH = 2.5

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

local GROUND_WAIT = 10 -- seconds a new vehicle waits for terrain collision under it

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
		-- The walk animator reads it.
		driver:SetAttribute(Names.Attributes.TurnRate, spec.turnRate or TURN_RATE)
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

	-- Drive constraints: horizontal velocity in the world XZ plane (gravity stays free) and yaw
	-- rate.
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
		local joint = podBone.part:FindFirstChild(Names.Instances.JointPrefix .. spec.pod.bone)
		car.pod = PodFlight.new({
			model = model,
			skid = skid,
			seat = driver,
			root = podBone.part,
			joint = joint :: Motor6D,
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

Builder.build = build

return Builder
