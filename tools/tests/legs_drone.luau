-- Checks src/shared/LegsDrone.luau (drone mode's follow math, applied by server Vehicles/Drive)
-- outside Roblox.
-- Usage: lune run tools/tests/legs_drone.luau
--
--   - follow returns the golden outputs generated once from the code at its first commit on
--     feat/pod-drone-legs: on and around ARRIVE, ahead, to either side, past TURN_FIRST, behind,
--     far away, other headings, a zero top speed
--   - rules over a sweep of headings and offsets: nothing inside ARRIVE, axes in -1..1, steer
--     toward the target's side, no throttle past TURN_FIRST, throttle never falls with distance,
--     height ignored
--   - Aurora's legs walked step by step with VehicleDrive's speed and yaw (its model's tuning)
--     from a spread of starts: each ends standing within ARRIVE of the target, having turned to
--     it first when it started facing away
--   - the tuning constants (a change is a gameplay change)

local roblox = require("@lune/roblox")

local Check = require("../lib/Check")
local Sandbox = require("../lib/Sandbox")

local check, equal = Check.check, Check.equal
local Vector3 = roblox.Vector3
local CFrame = Sandbox.CFrame
local V = Vector3.new

Check.printLimit = 10

local Shared = Sandbox.game:GetService("ReplicatedStorage").Shared
local LegsDrone = Sandbox.require(Shared.LegsDrone)
local MathUtil = Sandbox.require(Shared.MathUtil)
local VehicleDrive = Sandbox.require(Shared.VehicleDrive)

local function legsAt(yawDegrees: number, position: Vector3): CFrame
	return CFrame.new(position) * CFrame.Angles(0, math.rad(yawDegrees), 0)
end

Check.section("constants")
equal(LegsDrone.ARRIVE, 4, "ARRIVE")
equal(LegsDrone.FULL_STEER, math.rad(30), "FULL_STEER")
equal(LegsDrone.TURN_FIRST, math.rad(60), "TURN_FIRST")
equal(LegsDrone.STOP_SHARE, 0.8, "STOP_SHARE")

-- yaw (degrees), legs position, target, topSpeed, deceleration -> throttle, steer
Check.section("golden")
local GOLDEN = {
	{ 0, V(0, 0, 0), V(0, 40, 0), 30, 10, 0, 0 },
	{ 0, V(0, 0, 0), V(3, 60, -2), 30, 10, 0, 0 },
	{ 0, V(0, 0, 0), V(0, 30, -4), 30, 10, 0, 0 },
	{ 0, V(0, 0, 0), V(0, 30, -4.5), 30, 10, 0.09428090415820635, -0 },
	{ 0, V(0, 0, 0), V(0, 30, -10), 30, 10, 0.32659863237109038, -0 },
	{ 0, V(0, 0, 0), V(0, 30, -60), 30, 10, 0.99777530313971774, -0 },
	{ 0, V(0, 0, 0), V(0, 30, -500), 30, 10, 1, -0 },
	{ 0, V(0, 0, 0), V(-10, 30, -40), 30, 10, 0.81356342333797349, -0.46787478226421614 },
	{ 0, V(0, 0, 0), V(10, 30, -40), 30, 10, 0.81356342333797349, 0.46787478226421614 },
	{ 0, V(0, 0, 0), V(-40, 30, -40), 30, 10, 0.96672222810869746, -1 },
	{ 0, V(0, 0, 0), V(40, 30, -40), 30, 10, 0.96672222810869746, 1 },
	{ 0, V(0, 0, 0), V(-40, 30, 0), 30, 10, 0, -1 },
	{ 0, V(0, 0, 0), V(0, 30, 40), 30, 10, 0, 1 },
	{ 90, V(100, 5, 100), V(50, 80, 100), 30, 10, 0.90431066441670238, 8.3482602182922197e-08 },
	{ 90, V(100, 5, 100), V(150, 80, 100), 30, 10, 0, -1 },
	{ -135, V(-20, 2, 30), V(10, 50, 60), 30, 10, 0.8265204909509537, -0 },
	{ 180, V(0, 0, 0), V(5, 30, 80), 18, 6, 1, -0.11921097886804012 },
	{ 0, V(0, 0, 0), V(0, 30, -20), 0, 10, 1, -0 },
}
for index, case in GOLDEN do
	local throttle, steer = LegsDrone.follow(legsAt(case[1], case[2]), case[3], case[4], case[5])
	equal(throttle, case[6], "case " .. index .. " throttle")
	equal(steer, case[7], "case " .. index .. " steer")
end

Check.section("rules")
local rules = 0
for yaw = -180, 180, 15 do
	for _, offset in { V(0, 0, 0), V(37, -3, -12), V(-250, 9, 400) } do
		local legs = legsAt(yaw, offset)
		local lastThrottle = {}
		for distance = 0, 120, 2.5 do
			for bearing = -180, 165, 15 do
				local direction = V(-math.sin(math.rad(bearing)), 0, -math.cos(math.rad(bearing)))
				local target = offset + direction * distance + V(0, 30, 0)
				local throttle, steer = LegsDrone.follow(legs, target, 30, 10)
				local label = string.format("yaw %d bearing %d distance %g", yaw, bearing, distance)
				check(throttle >= 0 and throttle <= 1, label .. ": throttle in 0..1")
				check(steer >= -1 and steer <= 1, label .. ": steer in -1..1")
				if distance <= LegsDrone.ARRIVE then
					check(throttle == 0 and steer == 0, label .. ": stands inside ARRIVE")
				else
					local turn = MathUtil.wrapAngle(math.rad(bearing - yaw))
					if math.abs(turn) > 1e-3 and math.abs(math.abs(turn) - math.pi) > 1e-3 then
						check(math.sign(steer) == -math.sign(turn), label .. ": steers toward it")
					end
					if math.abs(turn) > LegsDrone.TURN_FIRST + 1e-3 then
						check(throttle == 0, label .. ": turns in place first")
					elseif math.abs(turn) < LegsDrone.TURN_FIRST - 1e-3 then
						check(throttle > 0, label .. ": walks")
						local last = lastThrottle[bearing]
						if last then
							check(throttle >= last, label .. ": throttle grows with distance")
						end
						lastThrottle[bearing] = throttle
					end
					local high, highSteer = LegsDrone.follow(legs, target + V(0, 300, 0), 30, 10)
					check(high == throttle and highSteer == steer, label .. ": height ignored")
				end
				rules += 1
			end
		end
	end
end
equal(rules, 25 * 3 * 49 * 24, "rule cases")

-- Aurora's tuning (src/server/vehicleModels/aurora.luau) through VehicleDrive, as Drive applies
-- it: the legs' forward speed and yaw rate, integrated at 60 Hz on flat ground.
Check.section("walk to the pod")
local AURORA = {
	turnRate = 1.1,
	acceleration = 10,
	braking = 28,
	coasting = 18,
	turnAcceleration = 3,
	turnInPlace = true,
}
local TOP_SPEED = 30
local DT = 1 / 60
local function walk(yawDegrees: number, target: Vector3): (number, number, boolean)
	local position = V(0, 0, 0)
	local yaw = math.rad(yawDegrees)
	local speed, yawRate = 0, 0
	local backwards = false
	for _ = 1, 60 * 60 do
		local legs = CFrame.new(position) * CFrame.Angles(0, yaw, 0)
		local throttle, steer = LegsDrone.follow(legs, target, TOP_SPEED, AURORA.acceleration)
		speed = VehicleDrive.speed(AURORA, speed, throttle, TOP_SPEED, DT)
		yawRate = VehicleDrive.yaw(AURORA, yawRate, steer, speed, false, DT)
		if speed < -0.01 then
			backwards = true
		end
		yaw += yawRate * DT
		position += legs.LookVector * Vector3.new(1, 0, 1) * speed * DT
	end
	local flat = Vector3.new(target.X - position.X, 0, target.Z - position.Z)
	return flat.Magnitude, math.abs(speed) + math.abs(yawRate), backwards
end
local walks = 0
for _, yawDegrees in { 0, 45, 90, 180, -120 } do
	local targets = { V(0, 40, -30), V(80, 60, -10), V(-200, 30, 150), V(5, 30, 6), V(0, 9, 300) }
	for _, target in targets do
		local label = string.format("yaw %d to %s", yawDegrees, tostring(target))
		local distance, motion, backwards = walk(yawDegrees, target)
		check(distance <= LegsDrone.ARRIVE + 0.5, label .. ": stands by the target, " .. distance)
		check(motion < 1e-3, label .. ": at rest")
		check(not backwards, label .. ": never walks backwards")
		walks += 1
	end
end
equal(walks, 25, "walks")

Check.finish()
