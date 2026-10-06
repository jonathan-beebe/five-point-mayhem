-- Checks src/shared/MathUtil.luau outside Roblox.
-- Usage: lune run tools/tests/math_util.luau
--
--   - every helper returns the same bits (signed zeros and NaNs included) as the inline expression
--     it replaced, copied below as the reference, over a sweep of inputs: zero and -0, negatives,
--     the wraparound at +-pi, points exactly on box faces, ranges of zero, infinities
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

-- `moveToward` as VehicleDrive.luau (from the old Vehicles.luau) and PodFlight.luau had it
-- (identical copies).
function Reference.moveToward(current: number, target: number, step: number): number
	if current < target then
		return math.min(current + step, target)
	end
	return math.max(current - step, target)
end

-- PodFlight.luau `wrap`; Lobby.luau `angleGap` without its math.abs; MechCamera.luau `turn`'s
-- delta.
function Reference.wrap(angle: number): number
	return (angle + math.pi) % (2 * math.pi) - math.pi
end
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
function Reference.followRateFirst(rate: number, dt: number): number
	return 1 - math.exp(-rate * dt)
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
local NUMBERS = { -inf, -1e9, -100, -3.5, -1, -0.1, -0, 0, 1e-9, 0.1, 0.5, 1, 2.4, 100, 1e9, inf }
local STEPS = { 0, 1e-6, 0.01, 0.5, 1, 7, 1e6, inf }

Check.section("moveToward")
for _, current in NUMBERS do
	for _, target in NUMBERS do
		for _, step in STEPS do
			local got = MathUtil.moveToward(current, target, step)
			local want = Reference.moveToward(current, target, step)
			check(same(got, want), "moveToward(" .. show(current, target, step) .. ")")
		end
	end
end
equal(MathUtil.moveToward(0, 10, 3), 3, "moveToward up")
equal(MathUtil.moveToward(0, -10, 3), -3, "moveToward down")
equal(MathUtil.moveToward(9, 10, 3), 10, "moveToward stops at target")

-- Angles: a fine sweep over several turns, every multiple of pi/2 (and its neighbours) up to
-- +-8 pi, and the extremes.
local ANGLES = { -inf, -1e9, -1e-300, -0, 0, 1e-300, 1e9, inf, 0 / 0 }
for step = -2000, 2000 do
	table.insert(ANGLES, step / 100)
end
for quarter = -16, 16 do
	local angle = quarter * math.pi / 2
	table.insert(ANGLES, angle)
	table.insert(ANGLES, angle + 1e-12)
	table.insert(ANGLES, angle - 1e-12)
end

Check.section("wrapAngle")
for _, angle in ANGLES do
	check(
		same(MathUtil.wrapAngle(angle), Reference.wrap(angle)),
		"wrapAngle(" .. show(angle) .. ")"
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
for step = -2000, 2000 do
	local wrapped = MathUtil.wrapAngle(step / 100)
	check(
		wrapped >= -math.pi and wrapped <= math.pi,
		"wrapAngle(" .. step / 100 .. ") in [-pi, pi]"
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
		check(
			same(got, Reference.followRateFirst(rate, dt)),
			"rateAlpha vs -rate * dt " .. show(rate, dt)
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
