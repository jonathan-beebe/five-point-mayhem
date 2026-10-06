-- Checks src/shared/RemoteGuard (the server's rules for what a client sends over a remote)
-- outside Roblox.
-- Usage: lune run tools/tests/remote_guard.luau
--
--   - isFinite, axis, isFiniteVector and optionalString on finite, signed-zero, NaN, ±inf and
--     wrong-type values
--   - axis returns every value a real client can send (DriveAxes output, -1..1) bit for bit
--   - the token bucket: starts full, refills at its rate, caps at its burst, spends one per event
--   - DRIVE_RATE and DRIVE_BURST pass a client sending on every frame at Roblox's highest frame
--     cap (240) for a minute, with a one-second network stall delivered at once, and stop a flood

local roblox = require("@lune/roblox")

local Check = require("../lib/Check")
local Sandbox = require("../lib/Sandbox")

local check, equal = Check.check, Check.equal
local Vector3 = roblox.Vector3

local Shared = Sandbox.game:GetService("ReplicatedStorage").Shared
local RemoteGuard = Sandbox.require(Shared.RemoteGuard)
local DriveAxes = Sandbox.require(Shared.DriveAxes)

local NAN = 0 / 0
local INF = math.huge

-- Same bits: signed zeros apart, NaN equal to NaN.
local function sameBits(a: number, b: number): boolean
	if a ~= a and b ~= b then
		return true
	end
	return a == b and (a ~= 0 or 1 / a == 1 / b)
end

Check.section("isFinite")
for _, value in { 0, -0, 1, -1, 0.05, 1e300, -1e300, 5e-324 } do
	check(RemoteGuard.isFinite(value), tostring(value) .. " is finite")
end
for _, value in { NAN, -NAN, INF, -INF } do
	check(not RemoteGuard.isFinite(value), tostring(value) .. " is not finite")
end

Check.section("axis")
-- Every value a real client sends: DriveAxes clamps into -1..1. Each comes back with its bits.
local real = { 0, -0, 1, -1, 0.5, -0.5, 0.05, -0.05, 0.051, 1e-9, 0.70710678118654757 }
for step = -100, 100 do
	table.insert(real, step / 100)
end
for _, value in real do
	local throttle = DriveAxes.clamp(value, value)
	check(
		sameBits(RemoteGuard.axis(throttle), throttle),
		"axis(" .. tostring(throttle) .. ") changes a real client's value"
	)
end
local CASES = {
	{ 2, 1 },
	{ -3, -1 },
	{ 1e300, 1 },
	{ -1e300, -1 },
	{ NAN, 0 },
	{ -NAN, 0 },
	{ INF, 0 },
	{ -INF, 0 },
}
for _, case in CASES do
	local got = RemoteGuard.axis(case[1])
	check(
		sameBits(got, case[2]),
		("axis(%s): got %s, want %s"):format(tostring(case[1]), tostring(got), tostring(case[2]))
	)
end

Check.section("isFiniteVector")
check(RemoteGuard.isFiniteVector(Vector3.new(1, 2, 3)), "a finite Vector3")
check(RemoteGuard.isFiniteVector(Vector3.zero), "Vector3.zero")
check(RemoteGuard.isFiniteVector(Vector3.new(1e6, -1e6, 0)), "far but finite")
for axis = 1, 3 do
	for _, bad in { NAN, INF, -INF } do
		local parts = { 1, 2, 3 }
		parts[axis] = bad
		local vector = Vector3.new(parts[1], parts[2], parts[3])
		check(not RemoteGuard.isFiniteVector(vector), "rejects " .. tostring(vector))
	end
end
for _, value in { nil, 1, "1,2,3", { X = 1, Y = 2, Z = 3 }, roblox.Vector2.new(1, 2), true } do
	check(not RemoteGuard.isFiniteVector(value), "rejects a " .. typeof(value))
end

Check.section("optionalString")
equal(RemoteGuard.optionalString("permanent"), "permanent", "a string")
equal(RemoteGuard.optionalString(""), "", "the empty string")
for _, value in { nil, 1, true, {}, Vector3.zero } do
	equal(RemoteGuard.optionalString(value), nil, "a " .. typeof(value))
end

Check.section("limiter")
do
	local limiter = RemoteGuard.newLimiter(10, 3, 100)
	for i = 1, 3 do
		check(RemoteGuard.allow(limiter, 100), "full bucket: event " .. i .. " passes")
	end
	check(not RemoteGuard.allow(limiter, 100), "empty bucket: the 4th event at once is dropped")
	check(not RemoteGuard.allow(limiter, 100.05), "half a token later: still dropped")
	check(RemoteGuard.allow(limiter, 100.101), "one token (1 / rate) later: passes")
	check(not RemoteGuard.allow(limiter, 100.101), "and spends it")
	-- A long idle refills to the burst, no further.
	local passed = 0
	for _ = 1, 10 do
		if RemoteGuard.allow(limiter, 1000) then
			passed += 1
		end
	end
	equal(passed, 3, "after a long idle the bucket holds the burst")
	-- A clock that goes backwards (it never should) gives no tokens.
	check(not RemoteGuard.allow(limiter, 500), "a backwards clock adds nothing")
end

Check.section("drive limit numbers")
check(RemoteGuard.DRIVE_RATE >= 240 * 1.25, "DRIVE_RATE has 25% over a 240 FPS client")
check(RemoteGuard.DRIVE_BURST >= 240, "DRIVE_BURST holds a second of 240 FPS sends")
do
	-- Every frame at 240 FPS for 60 s, with the frames of second 10 held back by the network and
	-- delivered together at 11 s (the stall the burst absorbs).
	local limiter = RemoteGuard.newLimiter(RemoteGuard.DRIVE_RATE, RemoteGuard.DRIVE_BURST, 0)
	local dropped = 0
	for frame = 0, 240 * 60 - 1 do
		local sent = frame / 240
		local arrives = if sent >= 10 and sent < 11 then 11 else sent
		if not RemoteGuard.allow(limiter, arrives) then
			dropped += 1
		end
	end
	equal(dropped, 0, "events dropped from a 240 FPS client sending every frame")

	-- A flood: 10,000 events in one second passes the burst plus a second's refill at most.
	local flood = RemoteGuard.newLimiter(RemoteGuard.DRIVE_RATE, RemoteGuard.DRIVE_BURST, 0)
	local passed = 0
	for i = 1, 10000 do
		if RemoteGuard.allow(flood, i / 10000) then
			passed += 1
		end
	end
	check(
		passed <= RemoteGuard.DRIVE_BURST + RemoteGuard.DRIVE_RATE + 1,
		"a flood passes at most burst + rate per second, got " .. passed
	)
end

Check.finish()
