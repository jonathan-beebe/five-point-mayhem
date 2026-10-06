--!strict
-- Drive math for vehicles (server Vehicles): the speed and yaw rate a driven vehicle's constraints
-- aim for each frame, how an empty vehicle settles, and how strong the constraints are for its
-- size. Pure: plain numbers in and out; Vehicles applies them to the skid's constraints.
-- `tools/tests/vehicle_logic.luau` pins each function bit for bit against the inline code it
-- replaced.

local MathUtil = require(script.Parent.MathUtil)
local VehicleSizing = require(script.Parent.VehicleSizing)

local VehicleDrive = {}

-- A car's drive tuning (Vehicles fills it from the model, defaults from VehicleDefaults).
export type Tuning = {
	turnRate: number, -- yaw rate at full lock, rad/s
	acceleration: number, -- studs/s^2 toward the target speed
	braking: number, -- studs/s^2 against the motion
	coasting: number, -- studs/s^2 to rest with no throttle
	turnAcceleration: number?, -- rad/s^2 on the yaw rate; nil = instant
	turnInPlace: boolean, -- full turn rate at any speed
}

VehicleDrive.DEFAULT_TOP_SPEED = 80 -- studs/s, for a driver seat without a TopSpeed attribute
local REVERSE_SHARE = 0.4 -- reverse top speed, as a share of forward
local BRAKE_MIN_SPEED = 1 -- studs/s; slower than this, a target the other way accelerates
local GRIP_SPEED = 20 -- studs/s from which steering has full grip (turnInPlace: always)
local SETTLING = 45 -- studs/s^2 an empty vehicle slows by, frictionless skid and all
local SPIN_SETTLING = 4 -- rad/s^2 an empty vehicle's yaw spin slows by
local SETTLE_SPEED = 0.5 -- studs/s; an empty vehicle sliding faster than this settles
local SETTLE_SPIN = 0.1 -- rad/s; or spinning faster than this
local CLIMB_LIFT = 60 -- studs/s^2 the climber can accelerate a walker by, beyond gravity
-- Constraint strengths, tuned on an 8 x 14 skid and scaled with mass and size.
local BASE_MASS = 8 * 14 * 4
local BASE_SPAN = 8 ^ 2 + 14 ^ 2
local MOVER_FORCE = 3e5 -- the mover's MaxForce at strength 1
local TURNER_TORQUE = 1e6 -- the turner's MaxTorque at leverage 1
local UPRIGHT_TORQUE = 4e5 -- the upright AlignOrientation's MaxTorque at leverage 1

-- The forward speed full `throttle` (-1..1) aims for: reverse is slower.
function VehicleDrive.targetSpeed(throttle: number, topSpeed: number): number
	return if throttle >= 0 then throttle * topSpeed else throttle * topSpeed * REVERSE_SHARE
end

-- The forward speed after `dt`: from `speed` toward the throttle's target, by coasting with no
-- throttle, braking when the target is the other way, else accelerating.
function VehicleDrive.speed(
	tuning: Tuning,
	speed: number,
	throttle: number,
	topSpeed: number,
	dt: number
): number
	local target = VehicleDrive.targetSpeed(throttle, topSpeed)
	local rate = if throttle == 0
		then tuning.coasting
		elseif
			math.sign(target) ~= math.sign(speed) and math.abs(speed) > BRAKE_MIN_SPEED
		then tuning.braking
		else tuning.acceleration
	return MathUtil.moveToward(speed, target, rate * dt)
end

-- The commanded yaw rate: `steer` (-1..1) at the turn rate, with grip growing with `newSpeed`
-- (none while `climbing`), moved from `previous` by turnAcceleration when the model sets it.
function VehicleDrive.yaw(
	tuning: Tuning,
	previous: number,
	steer: number,
	newSpeed: number,
	climbing: boolean,
	dt: number
): number
	local grip = if tuning.turnInPlace then 1 else math.clamp(newSpeed / GRIP_SPEED, -1, 1)
	local yaw = if climbing then 0 else -steer * tuning.turnRate * grip
	if tuning.turnAcceleration then
		yaw = MathUtil.moveToward(previous, yaw, tuning.turnAcceleration * dt)
	end
	return yaw
end

-- Whether an empty vehicle without a parking brake is still sliding (`flatSpeed`, horizontal) or
-- spinning (`spin`, yaw rad/s), so its constraints bleed that off.
function VehicleDrive.isSettling(parkingBrake: boolean, flatSpeed: number, spin: number): boolean
	return not parkingBrake and (flatSpeed > SETTLE_SPEED or math.abs(spin) > SETTLE_SPIN)
end

-- MaxForce and MaxTorque while settling, from the skid's assembly mass and size: a sliding
-- friction other vehicles push through.
function VehicleDrive.settlingLimits(mass: number, sizeX: number, sizeZ: number): (number, number)
	local span = sizeX ^ 2 + sizeZ ^ 2
	return mass * SETTLING, mass * span / 12 * SPIN_SETTLING
end

-- The horizontal speed and the yaw spin a settling vehicle is held to after `dt`.
function VehicleDrive.settledSpeed(flatSpeed: number, dt: number): number
	return math.max(flatSpeed - SETTLING * dt, 0)
end

function VehicleDrive.settledSpin(spin: number, dt: number): number
	return MathUtil.moveToward(spin, 0, SPIN_SETTLING * dt)
end

-- The climber's MaxForce: lifts the assembly's `mass` against `gravity` with CLIMB_LIFT to spare.
function VehicleDrive.climbForce(mass: number, gravity: number): number
	return mass * (gravity + CLIMB_LIFT)
end

export type Strength = {
	mass: number, -- footprint mass (VehicleSizing.footprintMass)
	strength: number, -- mass over the 8 x 14 skid's
	leverage: number, -- strength x span (W^2 + L^2) over the 8 x 14 skid's
	moverForce: number, -- the mover's MaxForce
	turnerTorque: number, -- the turner's MaxTorque
	uprightTorque: number, -- the upright AlignOrientation's MaxTorque
}

-- Constraint strengths for a W x L footprint; `upright` is the model's uprightTorque multiplier.
function VehicleDrive.strength(W: number, L: number, upright: number?): Strength
	local mass = VehicleSizing.footprintMass(W, L)
	local strength = mass / BASE_MASS
	local leverage = strength * (W ^ 2 + L ^ 2) / BASE_SPAN
	return {
		mass = mass,
		strength = strength,
		leverage = leverage,
		moverForce = MOVER_FORCE * strength,
		turnerTorque = TURNER_TORQUE * leverage,
		uprightTorque = UPRIGHT_TORQUE * leverage * (upright or 1),
	}
end

return VehicleDrive
