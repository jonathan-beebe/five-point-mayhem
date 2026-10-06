-- Checks src/shared/MathUtil.luau outside Roblox.
-- Usage: lune run tools/tests/math_util.luau
--
--   - moveToward, wrapAngle and rateAlpha return the same bits (signed zeros included; a NaN
--     matches any NaN) as golden tables generated once from the code at a50e99c: zero and -0,
--     thresholds a hair either side, the wraparound at +-pi, infinities and NaN
--   - yawOf, insideBox, clampToRange, timeAlpha (and wrapAngle and rateAlpha in their callers'
--     other forms) return the same bits as the inline expression each replaced, copied below as
--     the reference, over a sweep of inputs: zero and -0, negatives, points exactly on box faces,
--     ranges of zero, infinities
--   - properties over wide sweeps: moveToward stays between current and target, moves at most a
--     step and reaches a target within a step (2048 combinations); wrapAngle lands in [-pi, pi]
--     a whole number of turns from its input (4001 points and every pi/2 to +-8 pi)
--   - a few plain values (wrapAngle's range, yawOf's axes, insideBox's faces)

local luau = require("@lune/luau")
local roblox = require("@lune/roblox")

local Check = require("../lib/Check")
local Sandbox = require("../lib/Sandbox")

local check, equal = Check.check, Check.equal
local Vector3 = roblox.Vector3
local CFrame = Sandbox.CFrame

local MathUtil = Sandbox.load("src/shared/MathUtil.luau")

Check.printLimit = 10

-- The inline expressions the helpers replaced, word for word. Compiled with luau.load, as
-- Sandbox.load compiles MathUtil. Lune's main chunk and luau.load chunks compute `%` with
-- different low bits (e.g. at 1e9, 1e7, 12345.678), so the reference must compile the same way.
local Reference = luau.load(
	[[
local Reference = {}

-- Lobby.luau `angleGap` without its math.abs; MechCamera.luau `turn`'s delta.
function Reference.angleGap(a: number, b: number): number
	return math.abs((a - b + math.pi) % (2 * math.pi) - math.pi)
end
function Reference.cameraDelta(yaw: number, current: number): number
	return (yaw - current + math.pi) % (2 * math.pi) - math.pi
end

-- PodFlight.luau `yawOf(cframe)` and the `flat` heading; MechCamera.luau `heading`;
-- SniperScope.luau `scopeIn`.
function Reference.yawOfCFrame(cframe: CFrame): number
	local look = cframe.LookVector
	return math.atan2(-look.X, -look.Z)
end
function Reference.yawOfFlat(flat: Vector3): number
	return math.atan2(-flat.X, -flat.Z)
end

-- `inside(part, position)` from the old Vehicles.luau (now util/Characters.luau `isInside`);
-- PodFlight.luau's cab check; MechCamera.luau `cabAt`.
function Reference.inside(cframe: CFrame, size: Vector3, position: Vector3): boolean
	local offset = cframe:PointToObjectSpace(position)
	local half = size / 2
	return math.abs(offset.X) <= half.X
		and math.abs(offset.Y) <= half.Y
		and math.abs(offset.Z) <= half.Z
end

-- Weapons.luau `fireStrike` and `fireBlink` (identical).
function Reference.target(rootPosition: Vector3, aim: Vector3, range: number): Vector3
	local offset = aim - rootPosition
	return if offset.Magnitude > range then rootPosition + offset.Unit * range else aim
end

-- VehicleSounds.luau (`-dt * smoothing`, twice); PodFlight.luau (`-TILT_RATE * dt`, twice).
function Reference.followDtFirst(dt: number, rate: number): number
	return 1 - math.exp(-dt * rate)
end
-- SniperScope.luau (`-dt / EASE_SECONDS`); MechGait.luau (`-dt / ACCEL_TAU`, `-dt / W_TAU`).
function Reference.followTau(dt: number, tau: number): number
	return 1 - math.exp(-dt / tau)
end

return Reference
]],
	{ debugName = "MathUtil reference" }
)()

-- Same 64 bits: -0 differs from 0, a NaN equals the same NaN.
local function same(a: number, b: number): boolean
	return string.pack("<d", a) == string.pack("<d", b)
end
-- A golden value: the same bits, or any NaN for a NaN.
local function matches(got: number, want: number): boolean
	return if want ~= want then got ~= got else same(got, want)
end
local function sameVector(a: Vector3, b: Vector3): boolean
	return same(a.X, b.X) and same(a.Y, b.Y) and same(a.Z, b.Z)
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

local inf = math.huge
local nan = 0 / 0

-- Golden outputs of MathUtil.moveToward, generated once from the code at a50e99c: they pin its
-- behaviour. A deliberate change updates this table. { current, target, step, want }
local MOVE_TOWARD = {
	{ -0, -0, 0.5, -0 },
	{ -0, 0, 0.5, 0 },
	{ -0, 1, 0.5, 0.5 },
	{ -0, nan, 0.5, -0.5 },
	{ 0, -0, 0.5, -0 },
	{ 0, 0, 0.5, 0 },
	{ 0, 1, 0.5, 0.5 },
	{ 0, nan, 0.5, -0.5 },
	{ 1, -0, 0.5, 0.5 },
	{ 1, 0, 0.5, 0.5 },
	{ 1, 1, 0.5, 1 },
	{ 1, nan, 0.5, 0.5 },
	{ nan, -0, 0.5, nan },
	{ nan, 0, 0.5, nan },
	{ nan, 1, 0.5, nan },
	{ nan, nan, 0.5, nan },
	{ 0, 10, 3, 3 },
	{ 0, -10, 3, -3 },
	{ 9, 10, 3, 10 },
	{ 9, 10, 1, 10 },
	{ 9, 10, 0.999999999, 9.999999999 },
	{ 9, 10, 1.000000001, 10 },
	{ 10, 9, 0.999999999, 9.000000001 },
	{ 10, 9, 1.000000001, 9 },
	{ 9.999999999, 10, 0, 9.999999999 },
	{ 10.000000001, 10, 0, 10.000000001 },
	{ 1, 1, 5, 1 },
	{ 0, 10, -1, -1 },
	{ 0, -10, -1, 1 },
	{ 0, 1, inf, 1 },
	{ 0, -1, inf, -1 },
	{ inf, 0, 1, inf },
	{ -inf, 0, 1, -inf },
	{ 0, inf, 1000000, 1000000 },
	{ 0, -inf, 1000000, -1000000 },
	{ inf, inf, 1, inf },
	{ -1e9, 1e9, 1e-6, -999999999.999999 },
	{ 0.1, 0.30000000000000004, 0.2, 0.30000000000000004 },
	{ -3.5, -0.1, 2.4, -1.1 },
	{ 1, 2, nan, nan },
	{ 2, 1, nan, nan },
	{ 0, 1, -0, 0 },
	{ -0, -1, 0, -0 },
}

Check.section("moveToward")
for _, row in MOVE_TOWARD do
	local current, target, step, want = table.unpack(row)
	local got = MathUtil.moveToward(current, target, step)
	check(
		matches(got, want),
		"moveToward("
			.. show(current, target, step)
			.. ") = "
			.. show(got)
			.. ", want "
			.. show(want)
	)
end
equal(MathUtil.moveToward(0, 10, 3), 3, "moveToward up")
equal(MathUtil.moveToward(0, -10, 3), -3, "moveToward down")
equal(MathUtil.moveToward(9, 10, 3), 10, "moveToward stops at target")
-- Over every finite current and target and every step: the result lies between current and
-- target, moves by at most the step (to the rounding of current + step), and is the target when
-- the target is within a step.
local NUMBERS = { -inf, -1e9, -100, -3.5, -1, -0.1, -0, 0, 1e-9, 0.1, 0.5, 1, 2.4, 100, 1e9, inf }
local STEPS = { 0, 1e-6, 0.01, 0.5, 1, 7, 1e6, inf }
for _, current in NUMBERS do
	for _, target in NUMBERS do
		for _, step in STEPS do
			if math.abs(current) < inf and math.abs(target) < inf then
				local got = MathUtil.moveToward(current, target, step)
				local label = "moveToward(" .. show(current, target, step) .. ")"
				check(
					got >= math.min(current, target) and got <= math.max(current, target),
					label .. " stays between current and target"
				)
				-- current + step rounds to current's precision.
				local slack = 1e-15 * math.max(1, math.abs(current))
				check(math.abs(got - current) <= step + slack, label .. " moves by at most step")
				if math.abs(target - current) <= step then
					check(got == target, label .. " reaches the target")
				end
			end
		end
	end
end

-- Golden outputs of MathUtil.wrapAngle, generated once from the code at a50e99c: they pin its
-- behaviour. A deliberate change updates this table. The 1e9, 1e7 and 12345.678 rows pin the low
-- bits of `%` as luau.load compiles it (Sandbox.load); they may need regenerating after a Lune
-- upgrade. Every multiple of pi/2 up to +-4 pi and a
-- hair either side, and the extremes. { angle, want }
local WRAP_ANGLE = {
	{ -inf, nan },
	{ -1e9, -0.5773954942696129 },
	{ -1e-300, 0 },
	{ -0, 0 },
	{ 0, 0 },
	{ 1e-300, 0 },
	{ 1e9, 0.577395430696594 },
	{ inf, nan },
	{ nan, nan },
	{ -20, -1.1504440784612413 },
	{ -12.5, 0.06637061435917246 },
	{ -3.15, 3.133185307179586 },
	{ -0.01, -0.009999999999999787 },
	{ 0.01, 0.009999999999999787 },
	{ 3.15, -3.133185307179586 },
	{ 7, 0.7168146928204138 },
	{ 12345.678, -0.7811286078867319 },
	{ 1e7, 2.7075436365905112 },
	{ -12.566370614359172, 0 },
	{ -12.566370614358172, 1.000088900582341e-12 },
	{ -12.566370614360173, -1.000088900582341e-12 },
	{ -10.995574287564276, 1.5707963267948966 },
	{ -10.995574287563276, 1.5707963267958966 },
	{ -10.995574287565276, 1.5707963267938965 },
	{ -9.42477796076938, -3.141592653589793 },
	{ -9.42477796076838, -3.141592653588793 },
	{ -9.42477796077038, 3.141592653588793 },
	{ -7.853981633974483, -1.5707963267948966 },
	{ -7.853981633973483, -1.5707963267938965 },
	{ -7.853981633975483, -1.5707963267958966 },
	{ -6.283185307179586, 0 },
	{ -6.283185307178586, 1.000088900582341e-12 },
	{ -6.283185307180586, -1.000088900582341e-12 },
	{ -4.71238898038469, 1.5707963267948966 },
	{ -4.71238898038369, 1.5707963267958966 },
	{ -4.71238898038569, 1.5707963267938965 },
	{ -3.141592653589793, -3.141592653589793 },
	{ -3.141592653588793, -3.141592653588793 },
	{ -3.141592653590793, 3.141592653588793 },
	{ -1.5707963267948966, -1.5707963267948966 },
	{ -1.5707963267938965, -1.5707963267938965 },
	{ -1.5707963267958966, -1.5707963267958966 },
	{ 0, 0 },
	{ 1e-12, 1.000088900582341e-12 },
	{ -1e-12, -1.000088900582341e-12 },
	{ 1.5707963267948966, 1.5707963267948966 },
	{ 1.5707963267958966, 1.5707963267958966 },
	{ 1.5707963267938965, 1.5707963267938965 },
	{ 3.141592653589793, -3.141592653589793 },
	{ 3.141592653590793, -3.141592653588793 },
	{ 3.141592653588793, 3.141592653588793 },
	{ 4.71238898038469, -1.5707963267948966 },
	{ 4.71238898038569, -1.5707963267938965 },
	{ 4.71238898038369, -1.5707963267958966 },
	{ 6.283185307179586, 0 },
	{ 6.283185307180586, 1.000088900582341e-12 },
	{ 6.283185307178586, -1.000088900582341e-12 },
	{ 7.853981633974483, 1.5707963267948966 },
	{ 7.853981633975483, 1.5707963267958966 },
	{ 7.853981633973483, 1.5707963267938965 },
	{ 9.42477796076938, -3.141592653589793 },
	{ 9.42477796077038, -3.141592653588793 },
	{ 9.42477796076838, 3.141592653588793 },
	{ 10.995574287564276, -1.5707963267948966 },
	{ 10.995574287565276, -1.5707963267938965 },
	{ 10.995574287563276, -1.5707963267958966 },
	{ 12.566370614359172, 0 },
	{ 12.566370614360173, 1.000088900582341e-12 },
	{ 12.566370614358172, -1.000088900582341e-12 },
}

Check.section("wrapAngle")
for _, row in WRAP_ANGLE do
	local angle, want = row[1], row[2]
	local got = MathUtil.wrapAngle(angle)
	check(
		matches(got, want),
		"wrapAngle(" .. show(angle) .. ") = " .. show(got) .. ", want " .. show(want)
	)
end
for _, a in { -7, -math.pi, -1, 0, 0.5, math.pi, 3.5, 10 } do
	for _, b in { -math.pi, -2, 0, 1, math.pi, 6.5 } do
		check(
			same(math.abs(MathUtil.wrapAngle(a - b)), Reference.angleGap(a, b)),
			"|wrapAngle(a - b)| == angleGap(" .. show(a, b) .. ")"
		)
		check(
			same(MathUtil.wrapAngle(a - b), Reference.cameraDelta(a, b)),
			"wrapAngle(yaw - current) == camera delta(" .. show(a, b) .. ")"
		)
	end
end
-- Over a fine sweep of several turns and every multiple of pi/2 (and a hair either side) up to
-- +-8 pi: the result is in [-pi, pi] and differs from the angle by a whole number of turns.
local SWEEP = {}
for step = -2000, 2000 do
	table.insert(SWEEP, step / 100)
end
for quarter = -16, 16 do
	local angle = quarter * math.pi / 2
	table.insert(SWEEP, angle)
	table.insert(SWEEP, angle + 1e-12)
	table.insert(SWEEP, angle - 1e-12)
end
for _, angle in SWEEP do
	local wrapped = MathUtil.wrapAngle(angle)
	local turns = (angle - wrapped) / (2 * math.pi)
	check(
		wrapped >= -math.pi and wrapped <= math.pi,
		"wrapAngle(" .. show(angle) .. ") in [-pi, pi]"
	)
	check(
		math.abs(turns - math.round(turns)) <= 1e-9,
		"wrapAngle(" .. show(angle) .. ") differs by whole turns"
	)
end
equal(MathUtil.wrapAngle(math.pi), -math.pi, "wrapAngle(pi)")
equal(MathUtil.wrapAngle(-math.pi), -math.pi, "wrapAngle(-pi)")

Check.section("yawOf")
local COMPONENTS = { -2, -1, -1e-9, -0, 0, 1e-9, 1, 2 }
for _, x in COMPONENTS do
	for _, y in { -1, 0, 3 } do
		for _, z in COMPONENTS do
			local flat = Vector3.new(x, y, z)
			check(
				same(MathUtil.yawOf(flat), Reference.yawOfFlat(flat)),
				"yawOf(" .. show(x, y, z) .. ")"
			)
		end
	end
end
for degrees = -720, 720, 3 do
	for _, pitch in { -1.2, 0, 0.4 } do
		local frame = CFrame.new(5, -2, 9)
			* CFrame.Angles(0, math.rad(degrees), 0)
			* CFrame.Angles(pitch, 0, 0)
		check(
			same(MathUtil.yawOf(frame.LookVector), Reference.yawOfCFrame(frame)),
			"yawOf(LookVector) at " .. show(degrees, pitch)
		)
	end
end
equal(MathUtil.yawOf(Vector3.new(0, 0, -1)), 0, "yawOf(-Z)")
check(Check.isNear(MathUtil.yawOf(Vector3.new(-1, 0, 0)), math.pi / 2), "yawOf(-X) = pi/2")

Check.section("insideBox")
local FRAMES = {
	CFrame.new(),
	CFrame.new(10, -4, 2.5),
	CFrame.new(3, 1, -7) * CFrame.Angles(0, math.rad(37), 0),
	CFrame.new(-2, 8, 0) * CFrame.Angles(0.3, -1.1, 2.0),
	CFrame.new(0, 0, 0) * CFrame.Angles(0, math.pi / 2, 0),
}
local SIZES =
	{ Vector3.new(4, 2, 8), Vector3.new(1, 1, 1), Vector3.new(0, 3, 6), Vector3.new(7, 0.2, 3) }
-- Local offsets as fractions of the half size: center, exactly on each face, corners, a hair
-- inside and outside a face.
local FRACTIONS = { -1.5, -1 - 1e-6, -1, -1 + 1e-6, -0.5, -0, 0, 0.5, 1 - 1e-6, 1, 1 + 1e-6, 1.5 }
local onFaceInside = 0
for _, frame in FRAMES do
	for _, size in SIZES do
		local half = size / 2
		for _, fx in FRACTIONS do
			for _, fy in { -1, 0, 1, 1.5 } do
				for _, fz in FRACTIONS do
					local point = frame * Vector3.new(half.X * fx, half.Y * fy, half.Z * fz)
					local got = MathUtil.insideBox(frame, size, point)
					check(
						got == Reference.inside(frame, size, point),
						"insideBox(" .. show(frame, size, point) .. ")"
					)
				end
			end
		end
		-- Points given in world space exactly on a face (identity frame: no rounding).
		if frame == FRAMES[1] then
			for _, point in
				{
					Vector3.new(half.X, 0, 0),
					Vector3.new(-half.X, half.Y, half.Z),
					Vector3.new(0, -half.Y, 0),
				}
			do
				local got = MathUtil.insideBox(frame, size, point)
				check(
					got == Reference.inside(frame, size, point),
					"insideBox on face " .. show(point)
				)
				check(got, "a point on a face counts as inside: " .. show(size, point))
				if got then
					onFaceInside += 1
				end
			end
		end
	end
end
equal(onFaceInside, 3 * #SIZES, "face points inside")

Check.section("clampToRange")
local ORIGINS = { Vector3.zero, Vector3.new(12, 3, -40), Vector3.new(-0.5, 100, 7) }
local OFFSETS = {
	Vector3.zero,
	Vector3.new(1, 0, 0),
	Vector3.new(0, 0, -50),
	Vector3.new(30, 40, 0), -- 50 long
	Vector3.new(-120, 5, 300),
	Vector3.new(1e-7, 0, 0),
}
local RANGES = { -1, 0, 1, 49.999, 50, 50.001, 150, 1e6, inf }
for _, origin in ORIGINS do
	for _, offset in OFFSETS do
		local aim = origin + offset
		for _, range in RANGES do
			check(
				sameVector(
					MathUtil.clampToRange(origin, aim, range),
					Reference.target(origin, aim, range)
				),
				"clampToRange(" .. show(origin, aim, range) .. ")"
			)
		end
	end
end
check(
	MathUtil.clampToRange(Vector3.zero, Vector3.new(0, 0, 10), 100) == Vector3.new(0, 0, 10),
	"in range: aim unchanged"
)
check(
	(MathUtil.clampToRange(Vector3.zero, Vector3.new(0, 0, 10), 4) - Vector3.new(0, 0, 4)).Magnitude
		< 1e-6,
	"out of range: pulled back to the range"
)

-- Golden outputs of MathUtil.rateAlpha, generated once from the code at a50e99c: they pin its
-- behaviour. A deliberate change updates this table. { rate, dt, want }
local RATE_ALPHA = {
	{ 0, 0, 0 },
	{ 0, 1e-6, 0 },
	{ 0, 0.016666666666666666, 0 },
	{ 0, 0.0173, 0 },
	{ 0, 1, 0 },
	{ 0, inf, nan },
	{ -0, 0, 0 },
	{ -0, 1e-6, 0 },
	{ -0, 0.016666666666666666, 0 },
	{ -0, 0.0173, 0 },
	{ -0, 1, 0 },
	{ -0, inf, nan },
	{ 0.5, 0, 0 },
	{ 0.5, 1e-6, 4.999998749477541e-7 },
	{ 0.5, 0.016666666666666666, 0.008298707361124036 },
	{ 0.5, 0.0173, 0.008612696386240182 },
	{ 0.5, 1, 0.3934693402873666 },
	{ 0.5, inf, 1 },
	{ 5, 0, 0 },
	{ 5, 1e-6, 4.999987500031722e-6 },
	{ 5, 0.016666666666666666, 0.07995558537067671 },
	{ 5, 0.0173, 0.08286445121529429 },
	{ 5, 1, 0.9932620530009145 },
	{ 5, inf, 1 },
	{ 12, 0, 0 },
	{ 12, 1e-6, 1.1999928000272497e-5 },
	{ 12, 0.016666666666666666, 0.18126924692201818 },
	{ 12, 0.0173, 0.18746801548814884 },
	{ 12, 1, 0.9999938557876467 },
	{ 12, inf, 1 },
	{ 100, 0, 0 },
	{ 100, 1e-6, 9.999500016666385e-5 },
	{ 100, 0.016666666666666666, 0.8111243971624382 },
	{ 100, 0.0173, 0.8227155900301222 },
	{ 100, 1, 1 },
	{ 100, inf, 1 },
	{ inf, 0, nan },
	{ inf, 1e-6, 1 },
	{ inf, 0.016666666666666666, 1 },
	{ inf, 0.0173, 1 },
	{ inf, 1, 1 },
	{ inf, inf, 1 },
	{ -1, 0, 0 },
	{ -1, 1e-6, -1.0000004999621837e-6 },
	{ -1, 0.016666666666666666, -0.016806330386260893 },
	{ -1, 0.0173, -0.017450511698055227 },
	{ -1, 1, -1.718281828459045 },
	{ -1, inf, -inf },
	{ nan, 0, nan },
	{ nan, 1e-6, nan },
	{ nan, 0.016666666666666666, nan },
	{ nan, 0.0173, nan },
	{ nan, 1, nan },
	{ nan, inf, nan },
}

Check.section("rateAlpha golden")
for _, row in RATE_ALPHA do
	local rate, dt, want = table.unpack(row)
	local got = MathUtil.rateAlpha(rate, dt)
	check(
		matches(got, want),
		"rateAlpha(" .. show(rate, dt) .. ") = " .. show(got) .. ", want " .. show(want)
	)
end

Check.section("rateAlpha / timeAlpha")
local DTS = { 0, 1e-6, 1 / 240, 1 / 60, 1 / 30, 0.0173, 0.1, 0.5, 1, 10, inf }
for frame = 1, 400 do
	table.insert(DTS, frame * 0.00037)
end
local RATES = { 0, 0.5, 2, 4, 5, 6, 8, 12, 100, inf }
local TAUS = { 1e-3, 0.03, 0.05, 0.08, 0.12, 0.25, 1, 3, inf }
for _, dt in DTS do
	for _, rate in RATES do
		local got = MathUtil.rateAlpha(rate, dt)
		check(
			same(got, Reference.followDtFirst(dt, rate)),
			"rateAlpha vs -dt * rate " .. show(rate, dt)
		)
	end
	for _, tau in TAUS do
		check(
			same(MathUtil.timeAlpha(tau, dt), Reference.followTau(dt, tau)),
			"timeAlpha vs -dt / tau " .. show(tau, dt)
		)
	end
end
equal(MathUtil.rateAlpha(5, 0), 0, "no time, no follow")
check(Check.isNear(MathUtil.timeAlpha(1, 1), 1 - math.exp(-1)), "one time constant")

Check.finish()
