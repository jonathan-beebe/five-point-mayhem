-- Checks the pure vehicle logic Vehicles uses (src/shared VehicleDrive, VehicleSizing, VehicleRam,
-- VehicleLayout, and the additions to VehicleDamage and PodState) outside Roblox.
-- Usage: lune run tools/tests/vehicle_logic.luau
--
--   - every function returns the same bits (signed zeros and NaNs included; vectors and frames
--     component by component) as the inline code it replaced in Vehicles.luau, copied below word
--     for word as the reference, over a sweep of inputs: every vehicle model file (and the grey
--     placeholder) where an input comes from a spec, plus zero, -0, negatives, values on each
--     threshold and a hair either side, NaN
--   - touches, shoveVelocity, driveSeat, clearsLobby, climbForce, isHeavy, smokes and burns (whose
--     inline code was the module's code word for word) return the golden outputs generated once
--     from the code at a50e99c, on edge inputs: each threshold and either side of it, zero, -0,
--     NaN; touches also holds for every vehicle's reach box (points inside touch, points a stud
--     past a face do not)
--   - randomSpot makes the same calls, in the same order with the same arguments, on the Random
--     it is given (a recording fake) as the inline code made on its own Random
--   - a few plain values (constants, worked examples)

local luau = require("@lune/luau")
local roblox = require("@lune/roblox")

local Check = require("../lib/Check")
local Sandbox = require("../lib/Sandbox")

local check, equal = Check.check, Check.equal
local Vector3, Vector2, Color3, Enum = roblox.Vector3, roblox.Vector2, roblox.Color3, roblox.Enum
local CFrame = Sandbox.CFrame

Check.printLimit = 10

local Shared = Sandbox.game:GetService("ReplicatedStorage").Shared
local Config = Sandbox.require(Shared.Config)
local MathUtil = Sandbox.require(Shared.MathUtil)
local PodState = Sandbox.require(Shared.PodState)
local VehicleDamage = Sandbox.require(Shared.VehicleDamage)
local VehicleDefaults = Sandbox.require(Shared.VehicleDefaults)
local VehicleDrive = Sandbox.require(Shared.VehicleDrive)
local VehicleLayout = Sandbox.require(Shared.VehicleLayout)
local VehicleRam = Sandbox.require(Shared.VehicleRam)
local VehicleSizing = Sandbox.require(Shared.VehicleSizing)
local VehicleModel = Sandbox.load("src/server/systems/VehicleModel.luau")

-- The inline code the modules replaced, from Vehicles.luau at 7607178, word for word inside
-- functions that take its free variables as arguments. Compiled with luau.load, as Sandbox.load
-- compiles the modules (Lune's main chunk computes `%` with different low bits).
local Reference = luau.load(
	[[
local Reference = {}

local BASE_MASS = 8 * 14 * 4
local BASE_SPAN = 8 ^ 2 + 14 ^ 2
local SETTLING = 45 -- studs/s^2 an empty vehicle slows by, frictionless skid and all
local SPIN_SETTLING = 4 -- rad/s^2 an empty vehicle's yaw spin slows by
local HIT_MARGIN = 1.5 -- studs past the footprint that count as touching
local RAM_MIN_SPEED = 12 -- studs/s; slower cars nudge
local RAM_DAMAGE = 0.6 -- per stud/s of speed, times weight: 48 at 80 for the base car
local STOMP_DAMAGE = 40
local STOMP_HEIGHT = 14 -- walkers hurt only around their legs, not riders on the deck
local STOMP_PACE = 25 -- studs/s a moving walker shoves vehicles and hits trees with, however slow
local PACE_DECAY = 150 -- studs/s^2 the remembered pace falls by
local CREATURE_FLING = 1.6 -- creatures fly further than players
local CREATURE_LIFT = 0.5 -- extra upward fling on creatures per stud/s of pace
local MAX_FLING = 160 -- studs/s
local RAM_TRANSFER = 1.1 -- above 1, a struck vehicle of equal mass clears the rammer's path
local RAM_MIN_RATIO = 0.15
local RAM_MAX_RATIO = 3
local MAX_SHOVE = 140 -- studs/s
local TREE_BREAK = 25
local TREE_PUSH = 0.4 -- share of pace x weight the felled tree's crown takes on
local MAX_TREE_PUSH = 40 -- studs/s
local SPOKE_HALF_WIDTH = 11
local CLEARANCE = 3 -- free space kept around each parked vehicle
local CLEAR_HEIGHT = 16 -- taller than every car; walkers clear their own height
local LOBBY_MARGIN = 10 -- no vehicle parks within this of the lobby wall

-- drive: the driven step.
function Reference.driveSpeed(car, speed, topSpeed, dt)
	local throttle = car.throttle
	local target = if throttle >= 0 then throttle * topSpeed else throttle * topSpeed * 0.4
	local rate = if throttle == 0
		then car.coasting
		elseif math.sign(target) ~= math.sign(speed) and math.abs(speed) > 1 then car.braking
		else car.acceleration
	local newSpeed = MathUtil.moveToward(speed, target, rate * dt)
	return newSpeed, target
end
function Reference.driveYaw(car, newSpeed, climb, dt)
	local grip = if car.turnInPlace then 1 else math.clamp(newSpeed / 20, -1, 1)
	local yaw = if climb and climb.climbing then 0 else -car.steer * car.turnRate * grip
	if car.turnAcceleration then
		yaw = MathUtil.moveToward(car.yaw, yaw, car.turnAcceleration * dt)
	end
	return yaw
end
-- drive: no driver. `mass` and `size` are the skid's AssemblyMass and Size.
function Reference.settle(car, velocity, spin, mass, size, dt)
	local flat = Vector2.new(velocity.X, velocity.Z)
	local settling = not car.parkingBrake and (flat.Magnitude > 0.5 or math.abs(spin) > 0.1)
	local held = car.parkingBrake or settling
	local span = size.X ^ 2 + size.Z ^ 2
	local force, torque = mass * SETTLING, mass * span / 12 * SPIN_SETTLING
	local slowed = math.max(flat.Magnitude - SETTLING * dt, 0)
	local plane = if flat.Magnitude > 0
		then flat.Unit * slowed
		else Vector2.zero
	local angular =
		Vector3.new(0, MathUtil.moveToward(spin, 0, SPIN_SETTLING * dt), 0)
	return {
		settling = settling,
		held = held,
		force = force,
		torque = torque,
		plane = plane,
		angular = angular,
	}
end
-- build: strengths.
function Reference.strength(spec)
	local W, L = spec.footprint.X, spec.footprint.Y
	local mass = W * L * 4
	local strength = mass / BASE_MASS
	local leverage = strength * (W ^ 2 + L ^ 2) / BASE_SPAN
	local ram = spec.ram or 1
	return {
		mass = mass,
		upright = 4e5 * leverage * (spec.uprightTorque or 1),
		force = 3e5 * strength,
		torque = 1e6 * leverage,
		weight = math.sqrt(strength) * ram,
	}
end

local function solidHeight(spec)
	local top = 0
	for _, box in spec.collision do
		top = math.max(top, box.offset.Position.Y + box.size.Y / 2)
	end
	for _, ladder in (spec.ladders or {}) do
		top = math.max(top, ladder.base.Y + ladder.height)
	end
	return top
end
Reference.solidHeight = solidHeight

local function podSize(spec)
	local low, high = Vector3.one * math.huge, -Vector3.one * math.huge
	for _, box in spec.collision do
		if spec.pod and box.bone == spec.pod.bone then
			local half = box.size / 2
			local frame = box.offset
			local extent = (frame.RightVector * half.X):Abs()
				+ (frame.UpVector * half.Y):Abs()
				+ (frame.LookVector * half.Z):Abs()
			low = low:Min(frame.Position - extent)
			high = high:Max(frame.Position + extent)
		end
	end
	return if high.X >= low.X then high - low else Vector3.zero
end
Reference.podSize = podSize

-- newCrash, without the trackers and state.
function Reference.crash(spec, override)
	local pod = podSize(spec)
	local height = solidHeight(spec)
	return {
		bulk = VehicleDamage.bulk(spec.footprint.X, spec.footprint.Y, height, override),
		walker = spec.gait ~= nil,
		length = spec.footprint.Y,
		height = height,
		podBulk = VehicleDamage.bulk(pod.X, pod.Z, pod.Y),
		podLength = pod.Z,
		podMass = pod.X * pod.Z * 4,
	}
end

function Reference.reachFor(spec)
	local height = if spec.stepsOver then STOMP_HEIGHT else math.max(solidHeight(spec), 4)
	return Vector3.new(spec.footprint.X / 2 + HIT_MARGIN, height, spec.footprint.Y / 2 + HIT_MARGIN)
end

function Reference.clearHeight(spec)
	local top = solidHeight(spec)
	return if top > CLEAR_HEIGHT then top + 2 else CLEAR_HEIGHT
end

-- build: the pod's frames, relative to its bone's pivot.
function Reference.podFrames(spec, pivot)
	local exit = spec.exit or CFrame.new(0, 3, 0)
	local podExit = CFrame.new(exit.X - pivot.X, exit.Y, exit.Z - pivot.Z) * exit.Rotation
	local jets = {}
	for _, mouth in spec.pod.jets or {} do
		table.insert(jets, CFrame.new(mouth - pivot))
	end
	return {
		exit = podExit,
		button = CFrame.new(spec.pod.button - pivot),
		jets = jets,
	}
end
-- build: the legs seat's dismount.
function Reference.exitOf(spec)
	return spec.exit or CFrame.new(0, 3, 0)
end

-- addPrompts and addCab.
function Reference.promptReach(W, L)
	local reach = math.sqrt((W / 2) ^ 2 + (L / 2) ^ 2) + 6
	return reach
end
function Reference.cabReach(cab)
	local reach = math.sqrt((cab.size.X / 2) ^ 2 + (cab.size.Z / 2) ^ 2) + 0.5
	return reach
end

-- crashFeedback.
function Reference.crashPoint(position, tracker, lossH, lossV, length)
	local at = position
	local before = Vector3.new(tracker.startX, 0, tracker.startZ)
	if lossH >= lossV and before.Magnitude > 0.1 then
		at += before.Unit * length / 2
	end
	return at
end

-- Contact damage and ramming.
function Reference.ramTransfer(car, mass)
	return RAM_TRANSFER * math.clamp(car.mass / mass, RAM_MIN_RATIO, RAM_MAX_RATIO) * car.ram
end
function Reference.shoveSpeed(car, pace, closing, transfer)
	local speed = math.min(VehicleDamage.shovePace(pace, closing, car.stomps) * transfer, MAX_SHOVE)
	return speed
end
function Reference.pace(car, speed, dt)
	car.pace = math.max(speed, car.pace - PACE_DECAY * dt)
	return car.pace
end
function Reference.moving(car, speed, spinY)
	local moving = if car.stomps
		then speed > 2 or math.abs(spinY) > 0.15
		else car.pace >= RAM_MIN_SPEED
	return moving
end
function Reference.ramPace(car)
	local pace = if car.stomps then math.max(car.pace, STOMP_PACE) else car.pace
	return pace
end
function Reference.heading(flat, speed, look)
	local heading = if speed > 1 then flat.Unit else Vector3.new(look.X, 0, look.Z).Unit
	return heading
end
function Reference.away(ground, heading, position)
	local offset = position - ground.Position
	offset = Vector3.new(offset.X, 0, offset.Z)
	return if offset.Magnitude > 0.1 then offset.Unit else heading
end
function Reference.sweep(car, ground, flat, dt)
	local ahead = ground:VectorToObjectSpace(flat) * dt
	local height = car.reach.Y - 0.5
	local box = ground * CFrame.new(ahead.X / 2, 0.5 + height / 2, ahead.Z / 2)
	local size = Vector3.new(
		car.reach.X * 2 + math.abs(ahead.X),
		height,
		car.reach.Z * 2 + math.abs(ahead.Z)
	)
	return box, size
end
function Reference.shoveDirection(car, heading, outward)
	local direction = if car.stomps then outward else heading + outward * 0.5
	return if direction.Magnitude > 0.1 then direction.Unit else outward
end
function Reference.breaksTree(pace, car, toughness)
	return pace * car.weight >= TREE_BREAK * toughness
end
function Reference.fell(box, extent, pace, weight)
	local crown = box.Position + Vector3.new(0, extent.Y / 4, 0)
	local push = math.min(pace * weight * TREE_PUSH, MAX_TREE_PUSH)
	return crown, push
end
function Reference.contactDamage(car, pace)
	local amount = if car.stomps then STOMP_DAMAGE else pace * RAM_DAMAGE * car.weight
	return amount
end
function Reference.fling(car, pace, direction, creature)
	local fling = if car.stomps then 50 else pace * 0.8 * car.weight
	local lift = 35
	if creature then
		fling *= CREATURE_FLING
		lift += pace * CREATURE_LIFT
	end
	local push = direction * math.min(fling, MAX_FLING) + Vector3.new(0, lift, 0)
	return push
end

-- seatPlayer's gate: true when it goes on to seat the player.
function Reference.canSit(podState, legsAttribute)
	if legsAttribute then
		if not PodState.legsFree(podState) then
			return false
		end
	elseif podState ~= PodState.DOCKED then
		return false
	end
	return true
end

-- Parking.
function Reference.spawnFrame(position, facing, spec)
	local flat = facing and Vector3.new(facing.X, 0, facing.Z)
	local look = if flat and flat.Magnitude > 0.01 then flat.Unit else Vector3.zAxis
	local center = position + look * (spec.footprint.Y / 2) + Vector3.new(0, 1, 0)
	return CFrame.lookAt(center, center + look)
end
-- isClear: the box it checks for parts.
function Reference.clearBox(ground, W, L, height)
	local size = Vector3.new(W + CLEARANCE * 2, height, L + CLEARANCE * 2)
	local box = ground * CFrame.new(0, 0.1 + height / 2, 0)
	return box, size
end
function Reference.randomSpot(placement, spoke)
	local angle = Config.regionAngle(spoke)
	local outward = Config.pointAt(angle, 1)
	local side = Vector3.new(-outward.Z, 0, outward.X)
	local along = placement:NextNumber(Config.PARKING_START_RADIUS, Config.PARKING_END_RADIUS)
	local across = placement:NextNumber(SPOKE_HALF_WIDTH, Config.PARKING_REACH)
		* (if placement:NextNumber() < 0.5 then -1 else 1)
	local position = Config.pointAt(angle, along) + side * across
	return CFrame.new(position) * CFrame.Angles(0, placement:NextNumber(0, 2 * math.pi), 0)
end
-- placeWalkers: the ring radius, and every walker's spot.
function Reference.guardSpots(depth, count)
	local radius = Config.LOBBY_RADIUS + LOBBY_MARGIN + CLEARANCE + depth / 2
	local firstGap = Config.regionAngle(1) + math.pi / #Config.REGIONS
	local spots = {}
	for index = 1, count do
		local angle = firstGap + (index - 1) * 2 * math.pi / count
		local position = Config.pointAt(angle, radius)
		local ground = CFrame.lookAt(position, position + Config.pointAt(angle, 1))
		table.insert(spots, ground)
	end
	return radius, spots
end
function Reference.spoke(order)
	local spoke = (order - 1) % #Config.REGIONS + 1
	return spoke
end
-- Vehicles/Parking.luau `Parking.start`: `distance` from home, seconds since LastUsed, and the
-- skid's height.
function Reference.repark(distance, idleSeconds, y)
	local away = distance > 30
	local idle = idleSeconds > 60
	return (away and idle) or y < -50
end

return Reference
]],
	{
		debugName = "Vehicles reference",
		environment = {
			CFrame = CFrame,
			Vector3 = Vector3,
			Vector2 = Vector2,
			Config = Config,
			MathUtil = MathUtil,
			PodState = PodState,
			VehicleDamage = VehicleDamage,
		},
	}
)()

-- Same bits: -0 differs from 0, a NaN equals the same NaN; vectors, frames and tables compare
-- part by part.
local function same(a: any, b: any): boolean
	local kind = typeof(a)
	if kind ~= typeof(b) then
		return false
	elseif kind == "number" then
		return string.pack("<d", a) == string.pack("<d", b)
	elseif kind == "Vector3" then
		return same(a.X, b.X) and same(a.Y, b.Y) and same(a.Z, b.Z)
	elseif kind == "Vector2" then
		return same(a.X, b.X) and same(a.Y, b.Y)
	elseif kind == "CFrame" then
		return same({ a:GetComponents() }, { b:GetComponents() })
	elseif kind == "table" then
		for key, value in a do
			if not same(value, b[key]) then
				return false
			end
		end
		for key in b do
			if a[key] == nil then
				return false
			end
		end
		return true
	end
	return a == b
end
local function show(...: any): string
	local parts = {}
	for index = 1, select("#", ...) do
		local value = select(index, ...)
		table.insert(
			parts,
			if type(value) == "number" then string.format("%.17g", value) else tostring(value)
		)
	end
	return table.concat(parts, ", ")
end

-- Same bits as a golden value, vectors component by component; a NaN matches any NaN (the sign of
-- a literal's NaN is the platform's).
local function matches(got: any, want: any): boolean
	if typeof(got) == "Vector3" and typeof(want) == "Vector3" then
		return matches(got.X, want.X) and matches(got.Y, want.Y) and matches(got.Z, want.Z)
	elseif type(got) == "number" and type(want) == "number" and want ~= want then
		return got ~= got
	end
	return same(got, want)
end

local nan = 0 / 0

-- Every vehicle model, defined as Vehicles defines it, and Vehicles' grey placeholder.
type Entry = { id: string, spec: any }
local specs: { Entry } = {}
for _, model in Sandbox.loadVehicleModels() do
	table.insert(specs, { id = model.id, spec = VehicleModel.define(model.spec) })
end
table.insert(specs, {
	id = "placeholder",
	spec = VehicleModel.define({
		name = "placeholder",
		speed = 80,
		footprint = Vector2.new(8, 16),
		seats = { CFrame.new(-1.5, 1.5, 0) },
		pieces = {
			{
				size = Vector3.new(8, 2.5, 16),
				offset = CFrame.new(0, 2.25, 0),
				color = Color3.fromRGB(120, 120, 125),
				material = Enum.Material.Metal,
			},
		},
	}),
})
check(#specs >= 38, "every vehicle model loads")

-- A car's drive tuning, as build fills it from the spec.
local function tuningOf(spec: any): any
	return {
		turnRate = spec.turnRate or VehicleDefaults.turnRate,
		acceleration = spec.acceleration or VehicleDefaults.acceleration,
		braking = spec.braking or VehicleDefaults.braking,
		coasting = spec.coasting or VehicleDefaults.coasting,
		turnAcceleration = spec.turnAcceleration,
		turnInPlace = spec.turnInPlace == true,
		parkingBrake = spec.parkingBrake == true,
	}
end

local DTS = { 0, 1 / 240, 1 / 60, 1 / 30, 0.5 }
local FRAMES = {
	CFrame.new(),
	CFrame.new(10, -4, 2.5),
	CFrame.new(3, 1, -7) * CFrame.Angles(0, math.rad(37), 0),
	CFrame.new(-2, 8, 0) * CFrame.Angles(0.3, -1.1, 2.0),
	CFrame.new(140, 0.2, -90) * CFrame.Angles(0, math.pi / 2, 0),
	CFrame.lookAt(Vector3.new(0, 1, 0), Vector3.new(5, 1, -3)),
}
local FLATS = {
	Vector3.zero,
	Vector3.new(1e-9, 0, 0),
	Vector3.new(0.05, 0, 0.05),
	Vector3.new(0.5, 0, 0),
	Vector3.new(0.6, 0, -0.8), -- 1 long
	Vector3.new(0, 0, -1.2),
	Vector3.new(-30, 0, 45),
	Vector3.new(80, 0, 0),
	Vector3.new(-120, 0, -150),
}
local POINTS = {
	Vector3.zero,
	Vector3.new(0.05, 3, 0.05),
	Vector3.new(0.1, 0, 0),
	Vector3.new(0.105, 2, 0),
	Vector3.new(4, 0, 0),
	Vector3.new(-5.5, 1, 8.5),
	Vector3.new(6, -2, -9),
	Vector3.new(12, 14, 3),
	Vector3.new(-40, 0, 20),
	Vector3.new(0, -2.0000001, 0),
}

-- VehicleDrive ------------------------------------------------------------------------------------

Check.section("VehicleDrive.speed / targetSpeed")
local THROTTLES = { -1, -0.5, -1e-9, -0, 0, 1e-9, 0.25, 1, nan }
local SPEEDS = { -200, -80, -1.0000001, -1, -0.5, -0, 0, 1e-9, 0.5, 1, 1.5, 20, 79.9, 80, 300, nan }
for _, entry in specs do
	local tuning = tuningOf(entry.spec)
	for _, topSpeed in { entry.spec.speed, VehicleDrive.DEFAULT_TOP_SPEED } do
		for _, throttle in THROTTLES do
			for _, speed in SPEEDS do
				for _, dt in DTS do
					local car = table.clone(tuning)
					car.throttle = throttle
					local wantSpeed, wantTarget = Reference.driveSpeed(car, speed, topSpeed, dt)
					local label = entry.id .. " " .. show(throttle, speed, topSpeed, dt)
					check(
						same(VehicleDrive.speed(car, speed, throttle, topSpeed, dt), wantSpeed),
						"speed " .. label
					)
					check(
						same(VehicleDrive.targetSpeed(throttle, topSpeed), wantTarget),
						"targetSpeed " .. label
					)
				end
			end
		end
	end
end
equal(VehicleDrive.DEFAULT_TOP_SPEED, 80, "DEFAULT_TOP_SPEED")
equal(VehicleDrive.targetSpeed(-1, 80), -32, "reverse at 0.4 of top speed")

Check.section("VehicleDrive.yaw")
local STEERS = { -1, -0.3, -0, 0, 0.7, 1, nan }
local NEW_SPEEDS = { -90, -20, -0.5, -0, 0, 0.5, 19.99, 20, 20.01, 80, nan }
local CLIMBS = { false, { climbing = false }, { climbing = true } }
for _, entry in specs do
	local tuning = tuningOf(entry.spec)
	for _, steer in STEERS do
		for _, newSpeed in NEW_SPEEDS do
			for _, previous in { -3, -0, 0, 1.2 } do
				for _, climb in CLIMBS do
					for _, dt in { 0, 1 / 60, 0.5 } do
						local car = table.clone(tuning)
						car.steer, car.yaw = steer, previous
						local want = Reference.driveYaw(car, newSpeed, climb or nil, dt)
						local climbing = climb ~= false and climb.climbing
						local got = VehicleDrive.yaw(car, previous, steer, newSpeed, climbing, dt)
						check(
							same(got, want),
							"yaw "
								.. entry.id
								.. " "
								.. show(steer, newSpeed, previous, climbing, dt)
						)
					end
				end
			end
		end
	end
end

Check.section("VehicleDrive settling")
local VELOCITIES = {
	Vector3.zero,
	Vector3.new(-0, 4, -0),
	Vector3.new(0.3, 0, 0.3),
	Vector3.new(0.5, 0, 0),
	Vector3.new(0.5000001, -3, 0),
	Vector3.new(-40, 2, 25),
	Vector3.new(1e-9, 0, 0),
	Vector3.new(nan, 0, 0),
}
local SPINS = { -3, -0.1, -0.05, -0, 0, 0.1, 0.1000001, 5, nan }
for _, entry in specs do
	local spec = entry.spec
	local tuning = tuningOf(spec)
	local W, L = spec.footprint.X, spec.footprint.Y
	local size = Vector3.new(W, 1, L - math.min(2.5, L / 4) * 2)
	for _, parkingBrake in { false, true } do
		for _, velocity in VELOCITIES do
			for _, spin in SPINS do
				for _, mass in { 0, 448, 1873.25 } do
					for _, dt in { 0, 1 / 60, 0.5 } do
						local car = table.clone(tuning)
						car.parkingBrake = parkingBrake
						local want = Reference.settle(car, velocity, spin, mass, size, dt)
						-- The new drive's statements.
						local flat = Vector2.new(velocity.X, velocity.Z)
						local settling =
							VehicleDrive.isSettling(car.parkingBrake, flat.Magnitude, spin)
						local force, torque = VehicleDrive.settlingLimits(mass, size.X, size.Z)
						local slowed = VehicleDrive.settledSpeed(flat.Magnitude, dt)
						local got = {
							settling = settling,
							held = car.parkingBrake or settling,
							force = force,
							torque = torque,
							plane = if flat.Magnitude > 0 then flat.Unit * slowed else Vector2.zero,
							angular = Vector3.new(0, VehicleDrive.settledSpin(spin, dt), 0),
						}
						check(
							same(got, want),
							"settle "
								.. entry.id
								.. " "
								.. show(parkingBrake, velocity, spin, mass, dt)
						)
					end
				end
			end
		end
	end
end

Check.section("VehicleDrive.climbForce")
-- Golden outputs of VehicleDrive.climbForce, generated once from the code at a50e99c: they pin its
-- behaviour. A deliberate change updates this table. { mass, gravity, want }
local CLIMB_FORCE = {
	{ 0, 0, 0 },
	{ 0, 50, 0 },
	{ 0, 196.19999999999999, 0 },
	{ 0, 400, 0 },
	{ 0, -10, 0 },
	{ 1, 0, 60 },
	{ 1, 50, 110 },
	{ 1, 196.19999999999999, 256.19999999999999 },
	{ 1, 400, 460 },
	{ 1, -10, 50 },
	{ 448, 0, 26880 },
	{ 448, 50, 49280 },
	{ 448, 196.19999999999999, 114777.59999999999 },
	{ 448, 400, 206080 },
	{ 448, -10, 22400 },
	{ 1873.25, 0, 112395 },
	{ 1873.25, 50, 206057.5 },
	{ 1873.25, 196.19999999999999, 479926.64999999997 },
	{ 1873.25, 400, 861695 },
	{ 1873.25, -10, 93662.5 },
	{ 9000.5, 0, 540030 },
	{ 9000.5, 50, 990055 },
	{ 9000.5, 196.19999999999999, 2305928.1000000001 },
	{ 9000.5, 400, 4140230 },
	{ 9000.5, -10, 450025 },
	{ nan, 0, nan },
	{ nan, 50, nan },
	{ nan, 196.19999999999999, nan },
	{ nan, 400, nan },
	{ nan, -10, nan },
}
for _, row in CLIMB_FORCE do
	local mass, gravity, want = row[1], row[2], row[3]
	check(
		matches(VehicleDrive.climbForce(mass, gravity), want),
		"climbForce " .. show(mass, gravity)
	)
end

Check.section("VehicleDrive.strength / VehicleRam.weight")
for _, entry in specs do
	local spec = entry.spec
	local want = Reference.strength(spec)
	local strength = VehicleDrive.strength(spec.footprint.X, spec.footprint.Y, spec.uprightTorque)
	local got = {
		mass = strength.mass,
		upright = strength.uprightTorque,
		force = strength.moverForce,
		torque = strength.turnerTorque,
		weight = VehicleRam.weight(strength.strength, spec.ram or 1),
	}
	check(same(got, want), "strength " .. entry.id)
	check(
		same(VehicleSizing.footprintMass(spec.footprint.X, spec.footprint.Y), want.mass),
		"footprintMass " .. entry.id
	)
end
local base = VehicleDrive.strength(8, 14, nil)
check(base.strength == 1 and base.leverage == 1, "the 8 x 14 skid has strength and leverage 1")

-- VehicleSizing -----------------------------------------------------------------------------------

Check.section("VehicleSizing")
for _, entry in specs do
	local spec = entry.spec
	local id = entry.id
	check(same(VehicleSizing.solidHeight(spec), Reference.solidHeight(spec)), "solidHeight " .. id)
	check(same(VehicleSizing.podSize(spec), Reference.podSize(spec)), "podSize " .. id)
	for _, override in { false, 0.1, 1, 3.5, 80 } do
		local sized = VehicleSizing.crash(spec, override or nil)
		check(
			same(sized, Reference.crash(spec, override or nil)),
			"crash " .. id .. " " .. tostring(override)
		)
	end
	check(same(VehicleSizing.reach(spec), Reference.reachFor(spec)), "reach " .. id)
	check(same(VehicleLayout.clearHeight(spec), Reference.clearHeight(spec)), "clearHeight " .. id)
	local W, L = spec.footprint.X, spec.footprint.Y
	check(same(VehicleSizing.promptReach(W, L), Reference.promptReach(W, L)), "promptReach " .. id)
	if spec.cab then
		check(
			same(VehicleSizing.cabReach(spec.cab.size), Reference.cabReach(spec.cab)),
			"cab " .. id
		)
	end
	check(same(VehicleSizing.exitOf(spec), Reference.exitOf(spec)), "exitOf " .. id)
	if spec.pod then
		local pivots = { Vector3.zero, Vector3.new(1.5, -2, 30.25) }
		for _, bone in spec.bones do
			if bone.name == spec.pod.bone then
				table.insert(pivots, bone.pivot)
			end
		end
		for _, pivot in pivots do
			check(
				same(VehicleSizing.podFrames(spec, pivot), Reference.podFrames(spec, pivot)),
				"podFrames " .. id .. " " .. show(pivot)
			)
		end
	end
end
-- Edge specs: a ladder above every box, no ladders, a pod bone with no boxes, a stepping walker.
local edge = {
	footprint = Vector2.new(6, 10),
	collision = { { size = Vector3.new(6, 3, 10), offset = CFrame.new(0, 2.5, 0) } },
	ladders = { { base = Vector3.new(0, 1, 0), height = 20 } },
	pod = { bone = "Nowhere", button = Vector3.new(1, 2, 3) },
	stepsOver = true,
}
check(same(VehicleSizing.solidHeight(edge), Reference.solidHeight(edge)), "solidHeight ladder")
check(same(VehicleSizing.podSize(edge), Vector3.zero), "podSize without pod boxes")
check(same(VehicleSizing.crash(edge, nil), Reference.crash(edge, nil)), "crash edge")
check(same(VehicleSizing.reach(edge), Reference.reachFor(edge)), "reach stepsOver")
check(same(VehicleLayout.clearHeight(edge), Reference.clearHeight(edge)), "clearHeight tall")
check(
	same(VehicleSizing.podFrames(edge, Vector3.one), Reference.podFrames(edge, Vector3.one)),
	"podFrames default exit"
)

-- VehicleDamage additions -------------------------------------------------------------------------

Check.section("VehicleDamage crash feedback")
-- Golden outputs of VehicleDamage.isHeavy, smokes and burns, generated once from the code at
-- a50e99c: they pin their behaviour. A deliberate change updates these tables.
-- { amount, isHeavy for maxHealth 1, 100, 141, 266 as T/F }
local HEAVY_MAX_HEALTHS = { 1, 100, 141, 266 }
local IS_HEAVY = {
	{ 0, "FFFF" },
	{ 1, "TFFF" },
	{ 24.999998999999999, "TFFF" },
	{ 25, "TTFF" },
	{ 25.000001000000001, "TTFF" },
	{ 60, "TTTF" },
	{ 300, "TTTT" },
	{ nan, "FFFF" },
}
for _, row in IS_HEAVY do
	for index, maxHealth in HEAVY_MAX_HEALTHS do
		equal(
			VehicleDamage.isHeavy(row[1], maxHealth),
			string.sub(row[2], index, index) == "T",
			"isHeavy " .. show(row[1], maxHealth)
		)
	end
end
-- { share, smokes, burns }
local SMOKES_BURNS = {
	{ -0.5, true, true },
	{ 0, true, true },
	{ 0.10000000000000001, true, true },
	{ 0.25, true, true },
	{ 0.2500001, true, false },
	{ 0.4999999, true, false },
	{ 0.5, true, false },
	{ 0.50000009999999995, false, false },
	{ 1, false, false },
	{ nan, false, false },
}
for _, row in SMOKES_BURNS do
	equal(VehicleDamage.smokes(row[1]), row[2], "smokes " .. show(row[1]))
	equal(VehicleDamage.burns(row[1]), row[3], "burns " .. show(row[1]))
end
local STARTS = { { 0, 0 }, { 0.05, 0.05 }, { 0.1, 0 }, { 0.1000001, 0 }, { -30, 40 }, { 0, -90 } }
for _, start in STARTS do
	for _, losses in { { 0, 0 }, { 10, 10 }, { 30, 5 }, { 5, 30 }, { nan, 0 } } do
		for _, length in { 4, 14, 32.5 } do
			for _, position in POINTS do
				local tracker = { startX = start[1], startZ = start[2] }
				local want = Reference.crashPoint(position, tracker, losses[1], losses[2], length)
				local got = VehicleDamage.crashPoint(
					position,
					tracker.startX,
					tracker.startZ,
					losses[1],
					losses[2],
					length
				)
				check(same(got, want), "crashPoint " .. show(position, start[1], start[2], length))
			end
		end
	end
end

-- VehicleRam --------------------------------------------------------------------------------------

-- A car's ram fields, as build fills them.
local function ramCar(spec: any): any
	local strength = VehicleDrive.strength(spec.footprint.X, spec.footprint.Y, spec.uprightTorque)
	return {
		mass = strength.mass,
		ram = spec.ram or 1,
		weight = VehicleRam.weight(strength.strength, spec.ram or 1),
		stomps = spec.stepsOver == true,
		reach = VehicleSizing.reach(spec),
		pace = 0,
	}
end

Check.section("VehicleRam.transfer")
for _, entry in specs do
	local car = ramCar(entry.spec)
	for _, other in specs do
		local otherCar = ramCar(other.spec)
		local crash = VehicleSizing.crash(other.spec, nil)
		for _, mass in { otherCar.mass, crash.podMass } do
			local transfer = VehicleRam.transfer(car.mass, mass, car.ram)
			check(
				same(transfer, Reference.ramTransfer(car, mass)),
				"transfer " .. entry.id .. " into " .. other.id .. " " .. show(mass)
			)
		end
	end
end

Check.section("VehicleRam shove")
local PACES = { 0, 1.9, 2, 5, 12, 25, 60, 140, 300, nan }
local CLOSINGS = { 0, 1, 1.99, 2, 10, 80, nan }
local TRANSFERS = { 0.165, 0.5, 1, 1.1, 3.3, 9.9 }
for _, stomps in { false, true } do
	for _, pace in PACES do
		for _, closing in CLOSINGS do
			for _, transfer in TRANSFERS do
				check(
					same(
						VehicleRam.shoveSpeed(pace, closing, stomps, transfer),
						Reference.shoveSpeed({ stomps = stomps }, pace, closing, transfer)
					),
					"shoveSpeed " .. show(stomps, pace, closing, transfer)
				)
			end
		end
	end
end
local DIRECTIONS = {
	Vector3.new(1, 0, 0),
	Vector3.new(0.6, 0, -0.8),
	Vector3.new(-0.7071067811865476, 0, 0.7071067811865476),
}
local EAST, SLANTED, DIAGONAL = DIRECTIONS[1], DIRECTIONS[2], DIRECTIONS[3]
local STILL, DRIFTING, FAST = Vector3.zero, Vector3.new(10, -3, 4), Vector3.new(-100, 50, 120)
-- Golden outputs of VehicleRam.shoveVelocity (current, direction, speed -> velocity), generated
-- once from the code at a50e99c: they pin its behaviour. A deliberate change updates this table.
-- Speeds: zero, -0, either side of a 1 stud/s throw, either side of MAX_SHOVE (140) after the
-- lift, NaN.
local SHOVE_VELOCITIES = {
	{ STILL, SLANTED, 0, Vector3.new(0, 0, 0) },
	{ STILL, SLANTED, -0, Vector3.new(0, 0, 0) },
	{ STILL, SLANTED, 0.999, Vector3.new(0.59940004, 0.24975, -0.7992) },
	{ STILL, SLANTED, 1, Vector3.new(0.6, 0.25, -0.8) },
	{ STILL, SLANTED, 30, Vector3.new(18, 7.5, -24) },
	{ STILL, SLANTED, 111.9, Vector3.new(67.14001, 27.975, -89.520004) },
	{ STILL, SLANTED, 112, Vector3.new(67.200005, 28, -89.6) },
	{ STILL, SLANTED, 140, Vector3.new(81.49197, 33.954987, -108.65596) },
	{ STILL, SLANTED, nan, Vector3.new(nan, nan, nan) },
	{ DRIFTING, SLANTED, 0, Vector3.new(10, -3, 4) },
	{ DRIFTING, SLANTED, -0, Vector3.new(10, -3, 4) },
	{ DRIFTING, SLANTED, 0.999, Vector3.new(10.5994, -2.75025, 3.2008) },
	{ DRIFTING, SLANTED, 1, Vector3.new(10.6, -2.75, 3.2) },
	{ DRIFTING, SLANTED, 30, Vector3.new(28, 4.5, -20) },
	{ DRIFTING, SLANTED, 111.9, Vector3.new(77.14001, 24.975, -85.520004) },
	{ DRIFTING, SLANTED, 112, Vector3.new(77.200005, 25, -85.6) },
	{ DRIFTING, SLANTED, 140, Vector3.new(89.7004, 30.536306, -103.060036) },
	{ DRIFTING, SLANTED, nan, Vector3.new(nan, nan, nan) },
	{ FAST, SLANTED, 0, Vector3.new(-85.359505, 42.679752, 102.43141) },
	{ FAST, SLANTED, -0, Vector3.new(-85.359505, 42.679752, 102.43141) },
	{ FAST, SLANTED, 0.999, Vector3.new(-85.30199, 43.122513, 102.29379) },
	{ FAST, SLANTED, 1, Vector3.new(-85.301926, 43.122955, 102.293655) },
	{ FAST, SLANTED, 30, Vector3.new(-82, 57.5, 96) },
	{ FAST, SLANTED, 111.9, Vector3.new(-32.859993, 77.975, 30.479996) },
	{ FAST, SLANTED, 112, Vector3.new(-32.799995, 78, 30.400002) },
	{ FAST, SLANTED, 140, Vector3.new(-16, 85, 8) },
	{ FAST, SLANTED, nan, Vector3.new(nan, nan, nan) },
	{ STILL, EAST, 30, Vector3.new(30, 7.5, 0) },
	{ STILL, EAST, 112, Vector3.new(112, 28, 0) },
	{ STILL, EAST, 140, Vector3.new(135.81995, 33.954987, 0) },
	{ STILL, EAST, nan, Vector3.new(nan, nan, nan) },
	{ STILL, DIAGONAL, 30, Vector3.new(-21.213203, 7.5, 21.213203) },
	{ STILL, DIAGONAL, 112, Vector3.new(-79.19596, 28, 79.19596) },
	{ STILL, DIAGONAL, 140, Vector3.new(-96.03921, 33.954987, 96.03921) },
	{ STILL, DIAGONAL, nan, Vector3.new(nan, nan, nan) },
}
for _, row in SHOVE_VELOCITIES do
	local current, direction, speed, want = row[1], row[2], row[3], row[4]
	local got = VehicleRam.shoveVelocity(current, direction, speed)
	check(
		matches(got, want),
		"shoveVelocity " .. show(current, direction, speed, got) .. " want " .. tostring(want)
	)
end
equal(VehicleRam.MIN_SHOVE, 1, "MIN_SHOVE")
equal(VehicleRam.STUN_TIME, 0.6, "STUN_TIME")

Check.section("VehicleRam pace and moving")
for _, stomps in { false, true } do
	for _, previous in { 0, 11.9, 12, 40, 200, nan } do
		for _, speed in { 0, 1.9, 2, 2.0000001, 11.99, 12, 50, nan } do
			for _, dt in DTS do
				local car = { stomps = stomps, pace = previous }
				local want = Reference.pace(car, speed, dt)
				local got = VehicleRam.decayPace(previous, speed, dt)
				check(same(got, want), "decayPace " .. show(previous, speed, dt))
			end
			for _, spinY in { -1, -0.15, -0.1500001, 0, 0.15, 0.1500001, nan } do
				local car = { stomps = stomps, pace = previous }
				check(
					VehicleRam.isMoving(stomps, speed, spinY, previous)
						== Reference.moving(car, speed, spinY),
					"isMoving " .. show(stomps, speed, spinY, previous)
				)
			end
		end
		check(
			same(
				VehicleRam.ramPace(stomps, previous),
				Reference.ramPace({ stomps = stomps, pace = previous })
			),
			"ramPace " .. show(stomps, previous)
		)
	end
end

Check.section("VehicleRam heading, away, sweep, shoveDirection")
for _, ground in FRAMES do
	local look = ground.LookVector
	for _, flat in FLATS do
		local speed = flat.Magnitude
		local heading = Reference.heading(flat, speed, look)
		check(
			same(VehicleRam.heading(flat, speed, look), heading),
			"heading " .. show(ground, flat)
		)
		for _, position in POINTS do
			local point = ground * position
			check(
				same(
					VehicleRam.away(ground.Position, point, heading),
					Reference.away(ground, heading, point)
				),
				"away " .. show(ground, flat, position)
			)
		end
		for _, entry in specs do
			local car = ramCar(entry.spec)
			for _, dt in DTS do
				local wantBox, wantSize = Reference.sweep(car, ground, flat, dt)
				local gotBox, gotSize = VehicleRam.sweep(ground, flat, car.reach, dt)
				check(
					same(gotBox, wantBox) and same(gotSize, wantSize),
					"sweep " .. entry.id .. " " .. show(ground, flat, dt)
				)
			end
		end
	end
end
local OUTWARDS = {
	Vector3.new(1, 0, 0),
	Vector3.new(0, 0, -1),
	Vector3.new(-0.6, 0, 0.8),
	Vector3.new(0.7071067811865476, 0, 0.7071067811865476),
}
for _, stomps in { false, true } do
	for _, heading in OUTWARDS do
		for _, outward in OUTWARDS do
			for _, scale in { 1, -2, -2.0000001, 0.1 } do
				local h = heading * scale
				check(
					same(
						VehicleRam.shoveDirection(stomps, h, outward),
						Reference.shoveDirection({ stomps = stomps }, h, outward)
					),
					"shoveDirection " .. show(stomps, h, outward)
				)
			end
		end
	end
end

Check.section("VehicleRam.touches")
-- Golden outputs of VehicleRam.touches for a 5 x 6 x 8 reach (FRAMES index, point in the ground's
-- space -> touches), generated once from the code at a50e99c: they pin its behaviour. A
-- deliberate change updates this table.
-- FRAMES[1] puts points on each face and one float32 step past it; the turned frames 1e-4 inside
-- and outside.
local TOUCH_REACH = Vector3.new(5, 6, 8)
local TOUCHES = {
	{ 1, Vector3.new(0, 0, 0), true },
	{ 1, Vector3.new(5, 0, 0), true },
	{ 1, Vector3.new(5.000001, 0, 0), false },
	{ 1, Vector3.new(-5, 0, 0), true },
	{ 1, Vector3.new(-5.000001, 0, 0), false },
	{ 1, Vector3.new(0, -2, 0), true },
	{ 1, Vector3.new(0, -2.000001, 0), false },
	{ 1, Vector3.new(0, 6, 0), true },
	{ 1, Vector3.new(0, 6.000001, 0), false },
	{ 1, Vector3.new(0, 0, 8), true },
	{ 1, Vector3.new(0, 0, 8.000001), false },
	{ 1, Vector3.new(0, 0, -8), true },
	{ 1, Vector3.new(0, 0, -8.000001), false },
	{ 1, Vector3.new(5, 6, 8), true },
	{ 1, Vector3.new(-5, -2, -8), true },
	{ 1, Vector3.new(5.000001, 6, 8), false },
	{ 1, Vector3.new(nan, 0, 0), false },
	{ 3, Vector3.new(0, 0, 0), true },
	{ 3, Vector3.new(4.9999, 0, 0), true },
	{ 3, Vector3.new(5.0001, 0, 0), false },
	{ 3, Vector3.new(-4.9999, 0, 0), true },
	{ 3, Vector3.new(-5.0001, 0, 0), false },
	{ 3, Vector3.new(0, -1.9999, 0), true },
	{ 3, Vector3.new(0, -2.0001, 0), false },
	{ 3, Vector3.new(0, 5.9999, 0), true },
	{ 3, Vector3.new(0, 6.0001, 0), false },
	{ 3, Vector3.new(0, 0, 7.9999), true },
	{ 3, Vector3.new(0, 0, 8.0001), false },
	{ 3, Vector3.new(0, 0, -7.9999), true },
	{ 3, Vector3.new(0, 0, -8.0001), false },
	{ 3, Vector3.new(4.9999, 5.9999, 7.9999), true },
	{ 3, Vector3.new(5.0001, 5.9999, 7.9999), false },
	{ 3, Vector3.new(nan, 0, 0), false },
	{ 4, Vector3.new(0, 0, 0), true },
	{ 4, Vector3.new(4.9999, 0, 0), true },
	{ 4, Vector3.new(5.0001, 0, 0), false },
	{ 4, Vector3.new(-4.9999, 0, 0), true },
	{ 4, Vector3.new(-5.0001, 0, 0), false },
	{ 4, Vector3.new(0, -1.9999, 0), true },
	{ 4, Vector3.new(0, -2.0001, 0), false },
	{ 4, Vector3.new(0, 5.9999, 0), true },
	{ 4, Vector3.new(0, 6.0001, 0), false },
	{ 4, Vector3.new(0, 0, 7.9999), true },
	{ 4, Vector3.new(0, 0, 8.0001), false },
	{ 4, Vector3.new(0, 0, -7.9999), true },
	{ 4, Vector3.new(0, 0, -8.0001), false },
	{ 4, Vector3.new(4.9999, 5.9999, 7.9999), true },
	{ 4, Vector3.new(5.0001, 5.9999, 7.9999), false },
	{ 4, Vector3.new(nan, 0, 0), false },
}
for _, row in TOUCHES do
	local ground = FRAMES[row[1]]
	equal(
		VehicleRam.touches(TOUCH_REACH, ground, ground * row[2]),
		row[3],
		"touches " .. row[1] .. " " .. tostring(row[2])
	)
end
-- A zero reach: the ground point and the floor 2 below touch; a point beside them does not.
equal(VehicleRam.touches(Vector3.zero, FRAMES[1], Vector3.zero), true, "touches zero reach")
equal(
	VehicleRam.touches(Vector3.zero, FRAMES[1], Vector3.new(0, -2, 0)),
	true,
	"touches zero reach, floor"
)
equal(
	VehicleRam.touches(Vector3.zero, FRAMES[1], Vector3.new(1e-6, 0, 0)),
	false,
	"touches zero reach, beside"
)
-- Every vehicle's reach box, in every frame: points inside touch; a point a stud past any face
-- does not.
for _, entry in specs do
	local reach = ramCar(entry.spec).reach
	local inside, outside = {}, {}
	for _, x in { 0, 0.99, -0.99 } do
		for _, y in { -1.99, 0, 0.99 } do
			for _, z in { 0, 0.99, -0.99 } do
				table.insert(
					inside,
					Vector3.new(x * reach.X, if y == -1.99 then y else y * reach.Y, z * reach.Z)
				)
			end
		end
	end
	for _, sign in { 1, -1 } do
		table.insert(outside, Vector3.new(sign * (reach.X + 1), 0, 0))
		table.insert(outside, Vector3.new(0, 0, sign * (reach.Z + 1)))
	end
	table.insert(outside, Vector3.new(0, -3, 0))
	table.insert(outside, Vector3.new(0, reach.Y + 1, 0))
	for index, ground in FRAMES do
		for _, point in inside do
			check(
				VehicleRam.touches(reach, ground, ground * point),
				"touches " .. entry.id .. " frame " .. index .. " inside " .. tostring(point)
			)
		end
		for _, point in outside do
			check(
				not VehicleRam.touches(reach, ground, ground * point),
				"touches " .. entry.id .. " frame " .. index .. " outside " .. tostring(point)
			)
		end
	end
end

Check.section("VehicleRam contact damage and fling")
for _, entry in specs do
	local car = ramCar(entry.spec)
	for _, pace in PACES do
		check(
			same(
				VehicleRam.contactDamage(car.stomps, pace, car.weight),
				Reference.contactDamage(car, pace)
			),
			"contactDamage " .. entry.id .. " " .. show(pace)
		)
		for _, direction in DIRECTIONS do
			for _, creature in { false, true } do
				check(
					same(
						VehicleRam.fling(direction, car.stomps, pace, car.weight, creature),
						Reference.fling(car, pace, direction, creature)
					),
					"fling " .. entry.id .. " " .. show(pace, direction, creature)
				)
			end
		end
		for _, toughness in { 0.8, 1, 1.2, 1.5 } do
			check(
				VehicleRam.breaksTree(pace, car.weight, toughness)
					== Reference.breaksTree(pace, car, toughness),
				"breaksTree " .. entry.id .. " " .. show(pace, toughness)
			)
		end
		local wantCrown, wantPush =
			Reference.fell(FRAMES[3], Vector3.new(6, 30, 6), pace, car.weight)
		check(same(VehicleRam.treePush(pace, car.weight), wantPush), "treePush " .. entry.id)
		check(
			same(VehicleRam.treeCrown(FRAMES[3], Vector3.new(6, 30, 6)), wantCrown),
			"treeCrown " .. entry.id
		)
	end
end
-- Tree break at exactly TREE_BREAK x toughness, for the base car (weight 1).
check(VehicleRam.breaksTree(25, 1, 1), "the base car fells a toughness-1 tree at 25")
check(not VehicleRam.breaksTree(24.999, 1, 1), "and not below")

-- PodState seats ----------------------------------------------------------------------------------

Check.section("PodState.canSit / driveSeat")
local driver, legsSeat = { name = "driver" }, { name = "legs" }
for _, raw in { false, "docked", "flying", "returning", "landed", "wrecked" } do
	local state = PodState.of(raw or nil)
	for _, attribute in { false, true, "yes", 0 } do
		equal(
			PodState.canSit(state, attribute or nil),
			Reference.canSit(state, attribute or nil),
			"canSit " .. tostring(raw) .. " " .. tostring(attribute)
		)
	end
end
-- Golden outputs of PodState.driveSeat (raw state attribute -> the seat taken without a legs seat,
-- and with one), generated once from the code at a50e99c: they pin its behaviour. A deliberate
-- change updates this table.
local DRIVE_SEATS = {
	{ false, "driver", "driver" },
	{ "docked", "driver", "driver" },
	{ "flying", nil, "legs" },
	{ "returning", nil, nil },
	{ "landed", nil, "legs" },
	{ "wrecked", nil, nil },
}
local seatNamed = { driver = driver, legs = legsSeat }
for _, row in DRIVE_SEATS do
	local state = PodState.of(row[1] or nil)
	equal(
		PodState.driveSeat(state, driver, nil),
		row[2] and seatNamed[row[2]],
		"driveSeat " .. tostring(row[1]) .. " without legs"
	)
	equal(
		PodState.driveSeat(state, driver, legsSeat),
		row[3] and seatNamed[row[3]],
		"driveSeat " .. tostring(row[1]) .. " with legs"
	)
end

-- VehicleLayout -----------------------------------------------------------------------------------

Check.section("VehicleLayout.spawnFrame")
local FACINGS = {
	false,
	Vector3.zero,
	Vector3.new(0, 5, 0),
	Vector3.new(0.005, 1, 0.005),
	Vector3.new(0.01, 0, 0),
	Vector3.new(0.0100001, 0, 0),
	Vector3.new(3, -2, -4),
	Vector3.new(-1, 0, 0),
}
for _, entry in specs do
	for _, position in POINTS do
		for _, facing in FACINGS do
			check(
				same(
					VehicleLayout.spawnFrame(position, facing or nil, entry.spec.footprint.Y),
					Reference.spawnFrame(position, facing or nil, entry.spec)
				),
				"spawnFrame " .. entry.id .. " " .. show(position, facing)
			)
		end
	end
end

Check.section("VehicleLayout clear test")
local grounds = {}
for radius = 0, 140, 7 do
	for degrees = 0, 330, 30 do
		for _, heading in { 0, 0.5, math.pi / 2, 2 } do
			table.insert(
				grounds,
				CFrame.new(Config.pointAt(math.rad(degrees), radius, 0.2))
					* CFrame.Angles(0, heading, 0)
			)
		end
	end
end
for _, entry in specs do
	local W, L = entry.spec.footprint.X, entry.spec.footprint.Y
	local height = VehicleLayout.clearHeight(entry.spec)
	for _, ground in grounds do
		local wantBox, wantSize = Reference.clearBox(ground, W, L, height)
		local gotBox, gotSize = VehicleLayout.clearBox(ground, W, L, height)
		check(same(gotBox, wantBox) and same(gotSize, wantSize), "clearBox " .. entry.id)
	end
end
-- Golden outputs of VehicleLayout.clearsLobby, generated once from the code at a50e99c: they pin
-- its behaviour. A deliberate change updates this table. Each row: the ground's angle around the
-- lobby, its distance past Config.LOBBY_RADIUS, its heading, W, L -> clears. The lobby test's
-- margin is 10: at angle 0 and heading 0 a corner's distance past the radius is the distance
-- minus W / 2.
local CLEARS_LOBBY = {
	{ 0, 0, 0, 0, 0, false },
	{ 0, -50, 0, 0, 0, false },
	{ 0, 9.9999, 0, 0, 0, false },
	{ 0, 10, 0, 0, 0, true },
	{ 0, 10.0001, 0, 0, 0, true },
	{ 0, 200, 0, 0, 0, true },
	{ 0, 12, 0, 4, 0, true },
	{ 0, 12, 0, 4.001, 0, false },
	{ 0, 12, 0, 0, 4, true },
	{ 0, 12, 0, 4, 4, true },
	{ 0, 12, 1.5707963267948966, 0, 4, true },
	{ 0, 12, 1.5707963267948966, 0, 4.001, false },
	{ 0, 12, 1.5707963267948966, 4.001, 0, true },
	{ 0.7, 13, 1.1, 4, 4, true },
	{ 0.7, 13, 1.1, 2, 6, false },
	{ 0.7, 13, 2, 6, 2, false },
	{ 0.7, 30, 2, 40, 10, false },
	{ 0.7, 30, 0.5, 10, 40, false },
	{ 0, -0, 0, 0, 0, false },
	{ 0, nan, 0, 0, 0, true },
	{ 0, 10, 0, nan, 4, true },
}
for _, row in CLEARS_LOBBY do
	local angle, past, heading, W, L, want = row[1], row[2], row[3], row[4], row[5], row[6]
	local ground = CFrame.new(Config.pointAt(angle, Config.LOBBY_RADIUS + past, 0.2))
		* CFrame.Angles(0, heading, 0)
	equal(
		VehicleLayout.clearsLobby(ground, W, L),
		want,
		"clearsLobby " .. show(angle, past, heading, W, L)
	)
end
-- A 2 x 2 footprint whose corner sits at LOBBY_RADIUS + 10 in exact arithmetic: float rounding
-- puts it inside.
local onMargin = (Config.LOBBY_RADIUS + 10) / math.sqrt(2) - 1
equal(
	VehicleLayout.clearsLobby(CFrame.new(onMargin, 0, onMargin), 2, 2),
	false,
	"clearsLobby on the margin"
)

Check.section("VehicleLayout.randomSpot")
-- A Random stand-in that logs every call and answers from a seeded sequence.
local function recorder(seed: number): any
	local log = {}
	local state = seed
	local fake = {}
	function fake:NextNumber(...)
		local args = table.pack(...)
		state = state * 48271 % 2147483647
		local unit = state / 2147483647
		local low, high = args[1] or 0, args[2] or 1
		table.insert(log, { "NextNumber", args.n, args[1] or false, args[2] or false })
		return low + (high - low) * unit
	end
	function fake:NextInteger(...)
		table.insert(log, { "NextInteger", select("#", ...), ... })
		return 1
	end
	return fake, log
end
for spoke = 1, #Config.REGIONS do
	for _, seed in { 1, 77, 1337, 424242 } do
		local old, oldLog = recorder(seed)
		local new, newLog = recorder(seed)
		for draw = 1, 50 do
			check(
				same(VehicleLayout.randomSpot(new, spoke), Reference.randomSpot(old, spoke)),
				"randomSpot " .. show(spoke, seed, draw)
			)
		end
		check(#oldLog == 200, "the reference draws four numbers a spot")
		check(same(newLog, oldLog), "randomSpot calls on Random " .. show(spoke, seed))
	end
end

Check.section("VehicleLayout guard ring, spokes, repark")
local depths = { 0, 1 }
for _, entry in specs do
	if entry.spec.gait then
		table.insert(depths, entry.spec.footprint.Y)
	end
end
for _, depth in depths do
	for count = 1, 7 do
		local wantRadius, wantSpots = Reference.guardSpots(depth, count)
		local radius = VehicleLayout.guardRadius(depth)
		check(same(radius, wantRadius), "guardRadius " .. show(depth))
		for index = 1, count do
			check(
				same(VehicleLayout.guardSpot(index, count, radius), wantSpots[index]),
				"guardSpot " .. show(depth, index, count)
			)
		end
	end
end
for order = 1, 120 do
	equal(VehicleLayout.spokeFor(order), Reference.spoke(order), "spokeFor " .. order)
end
for _, distance in { 0, 29.999, 30, 30.000001, 500, nan } do
	for _, idle in { 0, 59.99, 60, 60.0001, 1e6, nan } do
		for _, y in { 0.7, -49.999, -50, -50.0001, -500, nan } do
			equal(
				VehicleLayout.shouldRepark(distance, idle, y),
				Reference.repark(distance, idle, y),
				"shouldRepark " .. show(distance, idle, y)
			)
		end
	end
end
equal(VehicleLayout.RESPAWN_INTERVAL, 10, "RESPAWN_INTERVAL")
equal(VehicleLayout.ATTEMPTS, 400, "ATTEMPTS")

Check.finish()
