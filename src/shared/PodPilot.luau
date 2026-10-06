--!strict
-- The math server PodFlight flies a pod with: the pilot's controls, the autopilot home, a landed
-- pod's hover, the launch prompt per state and where a landing rider stands. Pure: PodFlight casts
-- the rays and reads the clock, passes the results in, and writes the returned velocities and
-- frames to the pod's LinearVelocity and AlignOrientation. Functions taking a Flight (or Homing)
-- update its yaw, speed, bank, pitch (and phase) in place: PodFlight passes the pod itself.
-- tools/tests/pod_pilot.luau compares each with the inline code it replaced in PodFlight.luau.
--
-- `height` is the pod root's height over whatever is under it (math.huge over nothing).

local MathUtil = require(script.Parent.MathUtil)
local PodState = require(script.Parent.PodState)

local PodPilot = {}

local SPEED = 100 -- top forward speed, studs/s
local REVERSE = 0.4 -- of SPEED
local ACCELERATION = 45 -- studs/s^2
local TURN_RATE = 1.6 -- rad/s at full steer
local CLIMB = 28 -- studs/s at full lift
local CLEARANCE = 4 -- the pod's root never goes lower than this over the ground
local CEILING = 400 -- nor higher than this
local LAUNCH_RISE = 16 -- studs/s straight up for LAUNCH_TIME after letting go
local LAUNCH_TIME = 1
local BANK = math.rad(18) -- roll at full steer
local PITCH = math.rad(8) -- nose down at top speed
local LIFT_PITCH = math.rad(14) -- nose up at full climb (E), down at full descent (Q)
local TILT_RATE = 3 -- 1/s: how fast the bank and pitch follow

local LAND_HEIGHT = 15 -- LAND works with the root this close over the ground
local HOVER = 1.2 -- a landed pod's root over the ground (its hull starts 0.5 above the root)

local HOME_HEIGHT = 25 -- the autopilot crosses this high over the dock
local HOME_SPEED = 60
local HOME_TURN = 2.2 -- rad/s
local DESCENT = 12 -- fastest settle, studs/s
local DOCK_DISTANCE = 0.3 -- studs from the dock that count as docked
local DOCK_ANGLE = math.rad(2)
local HOME_TIMEOUT = 60 -- seconds; past this the pod snaps onto the dock

-- What PodFlight reads besides the functions: the ray length, LAND's test, the autopilot timeout.
PodPilot.CEILING = CEILING
PodPilot.LAND_HEIGHT = LAND_HEIGHT
PodPilot.HOME_TIMEOUT = HOME_TIMEOUT

export type Phase = "climb" | "cross" | "settle"

-- The pilot's input (-1..1 each) and the pod's heading, forward speed and tilt.
export type Flight = {
	throttle: number,
	steer: number,
	lift: number,
	yaw: number,
	speed: number, -- forward, studs/s
	bank: number,
	pitch: number,
}

-- The autopilot's part of a pod.
export type Homing = {
	yaw: number,
	bank: number,
	pitch: number,
	phase: Phase,
}

-- The AlignOrientation target: heading `yaw`, then `pitch` and `bank` about the pod's own axes.
function PodPilot.attitude(yaw: number, pitch: number, bank: number): CFrame
	return CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, bank)
end

-- Whether LAND works at `height`.
function PodPilot.canLand(height: number): boolean
	return height < LAND_HEIGHT
end

-- Upward speed under the pilot: `lift`, at least LAUNCH_RISE within LAUNCH_TIME of lift-off
-- (`sinceLaunch` seconds ago), pushed up below CLEARANCE, never up above CEILING.
function PodPilot.rise(lift: number, sinceLaunch: number, height: number): number
	local rise = lift * CLIMB
	if sinceLaunch < LAUNCH_TIME then
		rise = math.max(rise, LAUNCH_RISE)
	end
	if height < CLEARANCE then
		rise = math.max(rise, (CLEARANCE - height) * 4)
	elseif height > CEILING then
		rise = math.min(rise, 0)
	end
	return rise
end

-- One step of the pilot's controls: turns, speeds up or slows, and tilts `flight`; returns the
-- pod's velocity and attitude.
function PodPilot.fly(
	flight: Flight,
	height: number,
	sinceLaunch: number,
	dt: number
): (Vector3, CFrame)
	flight.yaw = MathUtil.wrapAngle(flight.yaw - flight.steer * TURN_RATE * dt)
	local target = flight.throttle * SPEED
	if flight.throttle < 0 then
		target = flight.throttle * SPEED * REVERSE
	end
	flight.speed = MathUtil.moveToward(flight.speed, target, ACCELERATION * dt)

	local rise = PodPilot.rise(flight.lift, sinceLaunch, height)
	local heading = CFrame.Angles(0, flight.yaw, 0)
	local velocity = heading.LookVector * flight.speed + Vector3.new(0, rise, 0)
	local follow = MathUtil.rateAlpha(TILT_RATE, dt)
	flight.bank += (-flight.steer * BANK - flight.bank) * follow
	local pitch = -PITCH * flight.speed / SPEED + LIFT_PITCH * flight.lift
	flight.pitch += (pitch - flight.pitch) * follow
	return velocity, PodPilot.attitude(flight.yaw, flight.pitch, flight.bank)
end

-- Whether a settling pod at `position` with heading `yaw` is on the dock frame `target`: within
-- DOCK_DISTANCE of it and DOCK_ANGLE of its heading. PodFlight docks it then, instead of `home`.
function PodPilot.onDock(yaw: number, target: CFrame, position: Vector3): boolean
	local dockYaw = MathUtil.yawOf(target.LookVector)
	return (target.Position - position).Magnitude < DOCK_DISTANCE
		and math.abs(MathUtil.wrapAngle(yaw - dockYaw)) < DOCK_ANGLE
end

-- One step of the autopilot from `position` toward the dock frame `target`: climb to HOME_HEIGHT
-- over the dock, cross to above it, settle onto it (`onDock` says when it is there). Returns the
-- pod's velocity and attitude.
function PodPilot.home(
	homing: Homing,
	target: CFrame,
	position: Vector3,
	dt: number
): (Vector3, CFrame)
	local cruise = math.max(target.Position.Y + HOME_HEIGHT, position.Y)
	local flat = Vector3.new(target.Position.X - position.X, 0, target.Position.Z - position.Z)
	local distance = flat.Magnitude
	local dockYaw = MathUtil.yawOf(target.LookVector)
	local wantYaw = dockYaw
	local velocity = Vector3.zero

	if homing.phase == "climb" then
		velocity = Vector3.new(0, CLIMB, 0)
		if position.Y >= target.Position.Y + HOME_HEIGHT - 1 or distance < 1 then
			homing.phase = "cross"
		end
	elseif homing.phase == "cross" then
		local pace = math.min(HOME_SPEED, distance * 1.5)
		velocity = if distance > 0.01 then flat.Unit * pace else Vector3.zero
		velocity += Vector3.new(0, math.clamp((cruise - position.Y) * 2, -CLIMB, CLIMB), 0)
		if distance > 8 then
			wantYaw = MathUtil.yawOf(flat)
		end
		if distance < 0.6 and math.abs(MathUtil.wrapAngle(homing.yaw - dockYaw)) < DOCK_ANGLE then
			homing.phase = "settle"
		end
	else
		local drop = position.Y - target.Position.Y
		local correction = flat * 4
		if correction.Magnitude > 6 then
			correction = correction.Unit * 6
		end
		local down = if distance > DOCK_DISTANCE and drop < 1
			then 0
			else math.clamp(drop * 1.2 + 0.8, 0.8, DESCENT)
		velocity = correction - Vector3.new(0, down, 0)
	end

	local turn = MathUtil.wrapAngle(wantYaw - homing.yaw)
	homing.yaw = MathUtil.wrapAngle(homing.yaw + math.clamp(turn, -HOME_TURN * dt, HOME_TURN * dt))
	local follow = MathUtil.rateAlpha(TILT_RATE, dt)
	homing.bank += (0 - homing.bank) * follow
	homing.pitch += (0 - homing.pitch) * follow
	return velocity, PodPilot.attitude(homing.yaw, homing.pitch, homing.bank)
end

-- A landed pod's velocity: toward HOVER over the ground, at most 6 studs/s; still over nothing.
function PodPilot.hover(height: number): Vector3
	local rise = if height == math.huge then 0 else math.clamp((HOVER - height) * 3, -6, 6)
	return Vector3.new(0, rise, 0)
end

-- The launch prompt in `state`: its ActionText and whether it is enabled.
function PodPilot.prompt(state: PodState.State): (string, boolean)
	return if PodState.isAtRest(state) then "Launch" else "Return home",
		state ~= PodState.RETURNING and state ~= PodState.WRECKED
end

-- Where a rider put outside stands: the exit `spot` dropped onto the ground under it (`groundY`,
-- nil when the ray hit nothing: the spot's own ground), with the root `exitHeight` above that.
function PodPilot.standFrame(spot: CFrame, exitHeight: number, groundY: number?): CFrame
	local ground = if groundY then groundY else spot.Position.Y - exitHeight
	return spot.Rotation + Vector3.new(spot.Position.X, ground + exitHeight, spot.Position.Z)
end

-- The side a passenger put outside stands on, studs to the exit frame's right: odd seats left,
-- even seats right.
function PodPilot.sideways(index: number): number
	return if index % 2 == 1 then -3.5 else 3.5
end

return table.freeze(PodPilot)
