--!strict
-- Drone mode for a pod walker's legs (server Vehicles/Drive): while the pilot flies the pod with
-- drone on and nobody rides the legs, the legs walk after the pod as if driven. `follow` gives
-- the throttle and steer a seated driver would send; Drive feeds them into the same drive math.
-- Pure: Drive reads the skid's frame and the pod's position and passes them in.
--
--   follow(legs, target, topSpeed, deceleration)  throttle, steer (-1..1 each) that walk the
--                                                 legs' frame toward the ground point under
--                                                 `target` and stop them within ARRIVE of it
--
-- Horizontal distance only: height (the pod's altitude, a hill) does not count. The legs turn
-- toward the target in proportion to the heading error, full steer at FULL_STEER and beyond;
-- past TURN_FIRST they stand and turn in place before walking. Throttle eases down with distance
-- so the legs can stop by ARRIVE: the speed from which `deceleration` (the walker's
-- acceleration, the rate VehicleDrive.speed slows a driven vehicle toward a lower throttle)
-- stops it over the distance left, times STOP_SHARE for margin.
--
-- tools/tests/legs_drone.luau pins `follow` against a golden table and checks its rules.

local MathUtil = require(script.Parent.MathUtil)

local LegsDrone = {}

LegsDrone.ARRIVE = 4 -- studs, horizontal: inside this the legs stand still under the pod
LegsDrone.FULL_STEER = math.rad(30) -- heading error that gets full steer
LegsDrone.TURN_FIRST = math.rad(60) -- past this heading error the legs turn in place first
LegsDrone.STOP_SHARE = 0.8 -- of the deceleration the throttle profile plans to stop with

-- Throttle and steer that walk `legs` toward the ground point under `target`. `topSpeed` is the
-- legs' top speed, `deceleration` the rate (studs/s^2) they slow at under a lower throttle.
function LegsDrone.follow(
	legs: CFrame,
	target: Vector3,
	topSpeed: number,
	deceleration: number
): (number, number)
	local offset = target - legs.Position
	local flat = Vector3.new(offset.X, 0, offset.Z)
	local distance = flat.Magnitude
	if distance <= LegsDrone.ARRIVE then
		return 0, 0
	end
	local turn = MathUtil.wrapAngle(MathUtil.yawOf(flat) - MathUtil.yawOf(legs.LookVector))
	-- A positive steer turns right (VehicleDrive.yaw): a target to the left (turn > 0) steers < 0.
	local steer = math.clamp(-turn / LegsDrone.FULL_STEER, -1, 1)
	if math.abs(turn) > LegsDrone.TURN_FIRST then
		return 0, steer
	end
	local left = distance - LegsDrone.ARRIVE
	local speed = math.sqrt(2 * deceleration * LegsDrone.STOP_SHARE * left)
	local throttle = math.clamp(speed / math.max(topSpeed, 1), 0, 1)
	return throttle, steer
end

return table.freeze(LegsDrone)
