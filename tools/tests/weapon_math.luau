-- Checks src/shared/WeaponMath.luau outside Roblox.
-- Usage: lune run tools/tests/weapon_math.luau
--
--   - spreadDirection, inMeleeReach, inPushCone and projectileStep return the same bits (signed
--     zeros included, vectors component by component; a NaN matches any NaN) as golden tables
--     generated once from the code at a50e99c: zero and -0, values on each threshold and a hair
--     either side, NaN
--   - spreadDirection makes the calls in its golden call log, in order with the same arguments, on
--     the Random it is given (a recording fake)
--   - coolingDown, projectileSize and centerUpright return the same bits as the inline code each
--     replaced in Weapons.luau, copied below word for word as the reference, over a sweep of
--     inputs: values on each threshold and a hair either side, NaN, and every weapon model file
--     for the display centering
--   - a few plain values (the cooldown slack, worked examples)

local luau = require("@lune/luau")
local roblox = require("@lune/roblox")

local Check = require("../lib/Check")
local Sandbox = require("../lib/Sandbox")

local check, equal = Check.check, Check.equal
local Vector3 = roblox.Vector3
local CFrame = Sandbox.CFrame

Check.printLimit = 10

local WeaponMath = Sandbox.require(Sandbox.game:GetService("ReplicatedStorage").Shared.WeaponMath)
local WeaponModel = Sandbox.load("src/server/systems/WeaponModel.luau")

-- The inline code the module replaced, from Weapons.luau at b7641e9, word for word inside
-- functions that take its free variables as arguments. Compiled with luau.load, as Sandbox
-- compiles the module.
local Reference = luau.load(
	[[
local Reference = {}

-- The FireWeapon handler's cooldown test.
function Reference.coolingDown(times, weaponId, now, cooldown)
	return times[weaponId] and now - times[weaponId] < cooldown * 0.85
end

-- projectileVisual.
function Reference.projectileSize(weapon)
	local size = if weapon.impact == "blackhole" then 2.5 elseif weapon.blast then 1.6 else 0.8
	return size
end

-- displayModel, for an upright spec.
function Reference.centerUpright(hold, spec, SCALE)
	local low, high = math.huge, -math.huge
	for _, piece in spec.pieces do
		local y = (hold * (piece.offset.Position * SCALE)).Y
		low = math.min(low, y)
		high = math.max(high, y)
	end
	if low <= high then
		hold = CFrame.new(0, -(low + high) / 2, 0) * hold
	end
	return hold
end

return Reference
]],
	{
		debugName = "Weapons reference",
		environment = { CFrame = CFrame, Vector3 = Vector3 },
	}
)()

-- Same bits: -0 differs from 0, a NaN equals the same NaN; vectors and frames compare part by
-- part, tables key by key.
local function same(a: any, b: any): boolean
	local kind = typeof(a)
	if kind ~= typeof(b) then
		return false
	elseif kind == "number" then
		return string.pack("<d", a) == string.pack("<d", b)
	elseif kind == "Vector3" then
		return same(a.X, b.X) and same(a.Y, b.Y) and same(a.Z, b.Z)
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
-- A golden value: numbers by bits (a NaN matches any NaN), a vector as { x, y, z }, tables key
-- by key.
local function matches(got: any, want: any): boolean
	if typeof(got) == "Vector3" then
		got = { got.X, got.Y, got.Z }
	end
	if type(want) == "number" then
		return type(got) == "number"
			and (
				if want ~= want
					then got ~= got
					else string.pack("<d", got) == string.pack("<d", want)
			)
	elseif type(want) == "table" then
		if type(got) ~= "table" or #got ~= #want then
			return false
		end
		for key, value in want do
			if not matches(got[key], value) then
				return false
			end
		end
		return true
	end
	return got == want
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

local nan = 0 / 0
local hair = 1e-9

local FRAMES = {
	CFrame.new(),
	CFrame.new(10, -4, 2.5),
	CFrame.new(3, 1, -7) * CFrame.Angles(0, math.rad(37), 0),
	CFrame.new(-2, 8, 0) * CFrame.Angles(0.3, -1.1, 2.0),
	CFrame.new(140, 0.2, -90) * CFrame.Angles(0, math.pi / 2, 0),
	CFrame.lookAt(Vector3.new(0, 1, 0), Vector3.new(5, 1, -3)),
	CFrame.Angles(math.rad(-90), 0, 0), -- looking straight down: a zero flat look
}
local DIRECTIONS = {
	Vector3.new(0, 0, -1),
	Vector3.new(1, 0, 0),
	Vector3.new(0.6, 0, -0.8),
	Vector3.new(0, 1, 0),
	Vector3.new(0, -1, 0),
	Vector3.new(0.3, -0.4, 0.866).Unit,
	Vector3.new(-5, 2, 7).Unit,
	Vector3.zero,
	Vector3.new(nan, 0, 0),
}
local OFFSETS = {
	Vector3.zero,
	Vector3.new(-0, 0, -0),
	Vector3.new(1.9, 0, 0),
	Vector3.new(2, 0, 0),
	Vector3.new(2.0001, 0, 0), -- a hair Vector3 keeps (single precision)
	Vector3.new(0, 0, -2),
	Vector3.new(0, 5, 1),
	Vector3.new(0, 0, -6),
	Vector3.new(0, 0, -7.5),
	Vector3.new(0, 0, -7.5001),
	Vector3.new(4, 0, -4),
	Vector3.new(math.sqrt(21), 0, -2), -- dot 0.4 with -Z, as close as single precision gets
	Vector3.new(math.sqrt(21), 0, -2.001),
	Vector3.new(math.sqrt(21), 0, -1.999),
	Vector3.new(-4, 0, -4),
	Vector3.new(6, 0, 6),
	Vector3.new(-3, 1.5, 2),
	Vector3.new(0, 0, 30),
	Vector3.new(12, 6, -20),
	Vector3.new(nan, 0, 0),
	Vector3.new(0, nan, 0),
}

Check.section("spreadDirection")
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
-- Golden outputs and call logs of WeaponMath.spreadDirection (fake seeded 77, one draw),
-- generated once from the code at a50e99c: they pin its behaviour. A deliberate change updates
-- this table. { DIRECTIONS index, degrees, want, calls }
local SPREAD = {
	{ 1, 0, { 0, 0, -1 }, {} },
	{ 1, -0, { 0, 0, -1 }, {} },
	{ 1, -3, { 0, 0, -1 }, {} },
	{
		1,
		1e-9,
		{ -1.6580133533478092e-12, -1.739287533442102e-11, -1 },
		{ { "NextNumber", 2, -1e-9, 1e-9 }, { "NextNumber", 2, -1e-9, 1e-9 } },
	},
	{
		1,
		4,
		{ -0.006632004864513874, -0.06951386481523514, -0.9975589513778687 },
		{ { "NextNumber", 2, -4, 4 }, { "NextNumber", 2, -4, 4 } },
	},
	{
		1,
		90,
		{ -0.14866803586483002, -0.9888725280761719, -0.005376997869461775 },
		{ { "NextNumber", 2, -90, 90 }, { "NextNumber", 2, -90, 90 } },
	},
	{ 1, nan, { nan, nan, nan }, { { "NextNumber", 2, nan, nan }, { "NextNumber", 2, nan, nan } } },
	{ 4, 0, { 0, 1, 0 }, {} },
	{ 4, -0, { 0, 1, 0 }, {} },
	{ 4, -3, { 0, 1, 0 }, {} },
	{
		4,
		1e-9,
		{ -1.6580133533478092e-12, 1, -1.739287533442102e-11 },
		{ { "NextNumber", 2, -1e-9, 1e-9 }, { "NextNumber", 2, -1e-9, 1e-9 } },
	},
	{
		4,
		4,
		{ -0.006632004864513874, 0.9975589513778687, -0.06951386481523514 },
		{ { "NextNumber", 2, -4, 4 }, { "NextNumber", 2, -4, 4 } },
	},
	{
		4,
		90,
		{ -0.14866803586483002, 0.005376997869461775, -0.9888725280761719 },
		{ { "NextNumber", 2, -90, 90 }, { "NextNumber", 2, -90, 90 } },
	},
	{ 4, nan, { nan, nan, nan }, { { "NextNumber", 2, nan, nan }, { "NextNumber", 2, nan, nan } } },
	{ 6, 0, { 0.300006628036499, -0.40000882744789124, 0.866019070148468 }, {} },
	{ 6, -0, { 0.300006628036499, -0.40000882744789124, 0.866019070148468 }, {} },
	{ 6, -3, { 0.300006628036499, -0.40000882744789124, 0.866019070148468 }, {} },
	{
		6,
		1e-9,
		{ 0.300006628036499, -0.40000882744789124, 0.866019070148468 },
		{ { "NextNumber", 2, -1e-9, 1e-9 }, { "NextNumber", 2, -1e-9, 1e-9 } },
	},
	{
		6,
		4,
		{ 0.296438992023468, -0.4627426266670227, 0.8354598879814148 },
		{ { "NextNumber", 2, -4, 4 }, { "NextNumber", 2, -4, 4 } },
	},
	{
		6,
		90,
		{ 0.01261071301996708, -0.908463716506958, -0.41777345538139343 },
		{ { "NextNumber", 2, -90, 90 }, { "NextNumber", 2, -90, 90 } },
	},
	{ 6, nan, { nan, nan, nan }, { { "NextNumber", 2, nan, nan }, { "NextNumber", 2, nan, nan } } },
	{ 8, 0, { 0, 0, 0 }, {} },
	{ 8, -0, { 0, 0, 0 }, {} },
	{ 8, -3, { 0, 0, 0 }, {} },
	{
		8,
		1e-9,
		{ nan, nan, nan },
		{ { "NextNumber", 2, -1e-9, 1e-9 }, { "NextNumber", 2, -1e-9, 1e-9 } },
	},
	{ 8, 4, { nan, nan, nan }, { { "NextNumber", 2, -4, 4 }, { "NextNumber", 2, -4, 4 } } },
	{ 8, 90, { nan, nan, nan }, { { "NextNumber", 2, -90, 90 }, { "NextNumber", 2, -90, 90 } } },
	{ 8, nan, { nan, nan, nan }, { { "NextNumber", 2, nan, nan }, { "NextNumber", 2, nan, nan } } },
	{ 9, 0, { nan, 0, 0 }, {} },
	{ 9, -0, { nan, 0, 0 }, {} },
	{ 9, -3, { nan, 0, 0 }, {} },
	{
		9,
		1e-9,
		{ nan, nan, nan },
		{ { "NextNumber", 2, -1e-9, 1e-9 }, { "NextNumber", 2, -1e-9, 1e-9 } },
	},
	{ 9, 4, { nan, nan, nan }, { { "NextNumber", 2, -4, 4 }, { "NextNumber", 2, -4, 4 } } },
	{ 9, 90, { nan, nan, nan }, { { "NextNumber", 2, -90, 90 }, { "NextNumber", 2, -90, 90 } } },
	{ 9, nan, { nan, nan, nan }, { { "NextNumber", 2, nan, nan }, { "NextNumber", 2, nan, nan } } },
}
for _, row in SPREAD do
	local direction, degrees, want, calls = DIRECTIONS[row[1]], row[2], row[3], row[4]
	local fake, log = recorder(77)
	local got = WeaponMath.spreadDirection(direction, degrees, fake)
	check(
		matches(got, want),
		"spreadDirection " .. show(direction, degrees) .. " = " .. tostring(got)
	)
	check(matches(log, calls), "spreadDirection calls " .. show(direction, degrees))
end
do
	local still, stillLog = recorder(5)
	WeaponMath.spreadDirection(Vector3.new(0, 0, -1), 0, still)
	equal(#stillLog, 0, "no spread, no draws")
	local spread, spreadLog = recorder(5)
	WeaponMath.spreadDirection(Vector3.new(0, 0, -1), 5, spread)
	equal(#spreadLog, 2, "two draws per spread shot")
end

Check.section("coolingDown")
equal(WeaponMath.COOLDOWN_SLACK, 0.85, "COOLDOWN_SLACK")
for _, cooldown in { 0, 0.1, 0.25, 1, 2.5, 8, nan } do
	for _, last in { 0, 10, 1234.5678, nan } do
		local edges = { 0, -1, cooldown * 0.85, cooldown * 0.85 - hair, cooldown * 0.85 + hair }
		for _, since in { 0.01, 0.2, 0.5, 1, 3, 100, nan, table.unpack(edges) } do
			local now = last + since
			local want = Reference.coolingDown({ gun = last }, "gun", now, cooldown)
			check(
				WeaponMath.coolingDown(last, now, cooldown) == (want and true or false),
				"coolingDown " .. show(last, now, cooldown)
			)
		end
	end
	local never = Reference.coolingDown({}, "gun", 5, cooldown)
	check(
		WeaponMath.coolingDown(nil, 5, cooldown) == (never and true or false),
		"coolingDown never fired " .. show(cooldown)
	)
end
check(WeaponMath.coolingDown(10, 10.5, 1), "0.5 s into a 1 s cooldown")
check(not WeaponMath.coolingDown(10, 10.9, 1), "0.9 s into a 1 s cooldown (slack 0.85)")

-- Golden outputs of WeaponMath.inMeleeReach, generated once from the code at a50e99c: they pin
-- its behaviour. A deliberate change updates this table. The string holds one T or F per OFFSETS
-- entry, in order. { FRAMES index, minimumDot, range, want }
local MELEE = {
	{ 1, 0.3, 6, "TTTFFTTTTFTTTTTFFFFFF" },
	{ 1, 0.3, 0, "TTFFFFFFFFFFFFFFFFFFF" },
	{ 1, 0.3, nan, "FFFFFFFFFFFFFFFFFFFFF" },
	{ 1, 0.7, 6, "TTTFFTTTTFTFFFTFFFFFF" },
	{ 1, 0.7, 0, "TTFFFFFFFFFFFFFFFFFFF" },
	{ 1, 0.7, nan, "FFFFFFFFFFFFFFFFFFFFF" },
	{ 1, nan, 6, "TTTFFFTFFFFFFFFFFFFFF" },
	{ 1, nan, 0, "TTFFFFFFFFFFFFFFFFFFF" },
	{ 1, nan, nan, "FFFFFFFFFFFFFFFFFFFFF" },
	{ 3, 0.3, 6, "TTTFFTTTTFFFFFTFFFFFF" },
	{ 3, 0.3, 0, "TTFFFFFFFFFFFFFFFFFFF" },
	{ 3, 0.3, nan, "FFFFFFFFFFFFFFFFFFFFF" },
	{ 3, 0.7, 6, "TTTFFTTTTFFFFFTFFFFFF" },
	{ 3, 0.7, 0, "TTFFFFFFFFFFFFFFFFFFF" },
	{ 3, 0.7, nan, "FFFFFFFFFFFFFFFFFFFFF" },
	{ 3, nan, 6, "TTTFFFTFFFFFFFFFFFFFF" },
	{ 3, nan, 0, "TTFFFFFFFFFFFFFFFFFFF" },
	{ 3, nan, nan, "FFFFFFFFFFFFFFFFFFFFF" },
	{ 7, 0.3, 6, "TTTFFFTFFFFFFFFFTFFFF" },
	{ 7, 0.3, 0, "TTFFFFFFFFFFFFFFFFFFF" },
	{ 7, 0.3, nan, "FFFFFFFFFFFFFFFFFFFFF" },
	{ 7, 0.7, 6, "TTTFFFTFFFFFFFFFFFFFF" },
	{ 7, 0.7, 0, "TTFFFFFFFFFFFFFFFFFFF" },
	{ 7, 0.7, nan, "FFFFFFFFFFFFFFFFFFFFF" },
	{ 7, nan, 6, "TTTFFFTFFFFFFFFFFFFFF" },
	{ 7, nan, 0, "TTFFFFFFFFFFFFFFFFFFF" },
	{ 7, nan, nan, "FFFFFFFFFFFFFFFFFFFFF" },
}

-- Golden outputs of WeaponMath.inPushCone, generated once from the code at a50e99c: they pin its
-- behaviour. A deliberate change updates this table. One T or F per OFFSETS entry, the look along
-- the DIRECTIONS entry. { FRAMES index, DIRECTIONS index, range, want }
local PUSH = {
	{ 1, 1, 6, "FFFFFTFTFFTTTFTFFFFFF" },
	{ 1, 1, 10, "FFFFFTFTTTTTTFTFFFFFF" },
	{ 1, 1, nan, "FFFFFFFFFFFFFFFFFFFFF" },
	{ 1, 3, 6, "FFTTTTFTFFTTTTFFFFFFF" },
	{ 1, 3, 10, "FFTTTTFTTTTTTTFFFFFFF" },
	{ 1, 3, nan, "FFFFFFFFFFFFFFFFFFFFF" },
	{ 1, 8, 6, "FFFFFFFFFFFFFFFFFFFFF" },
	{ 1, 8, 10, "FFFFFFFFFFFFFFFFFFFFF" },
	{ 1, 8, nan, "FFFFFFFFFFFFFFFFFFFFF" },
	{ 1, 9, 6, "FFFFFFFFFFFFFFFFFFFFF" },
	{ 1, 9, 10, "FFFFFFFFFFFFFFFFFFFFF" },
	{ 1, 9, nan, "FFFFFFFFFFFFFFFFFFFFF" },
	{ 6, 1, 6, "FFFFFTFTFFTTTFTFFFFFF" },
	{ 6, 1, 10, "FFFFFTFTTTTTTFTFFFFFF" },
	{ 6, 1, nan, "FFFFFFFFFFFFFFFFFFFFF" },
	{ 6, 3, 6, "FFTTTTFTFFTTTTFFFFFFF" },
	{ 6, 3, 10, "FFTTTTFTTTTTTTFFFFFFF" },
	{ 6, 3, nan, "FFFFFFFFFFFFFFFFFFFFF" },
	{ 6, 8, 6, "FFFFFFFFFFFFFFFFFFFFF" },
	{ 6, 8, 10, "FFFFFFFFFFFFFFFFFFFFF" },
	{ 6, 8, nan, "FFFFFFFFFFFFFFFFFFFFF" },
	{ 6, 9, 6, "FFFFFFFFFFFFFFFFFFFFF" },
	{ 6, 9, 10, "FFFFFFFFFFFFFFFFFFFFF" },
	{ 6, 9, nan, "FFFFFFFFFFFFFFFFFFFFF" },
}

-- Golden outputs of WeaponMath.projectileStep, generated once from the code at a50e99c: they pin
-- its behaviour. A deliberate change updates this table. { velocity, gravity, dt, step, velocity }
local PROJECTILE = {
	{ { 0, 0, 0 }, 0, 0, { 0, 0, 0 }, { 0, 0, 0 } },
	{ { 0, 0, 0 }, 0, 0.016666666666666666, { 0, 0, 0 }, { 0, 0, 0 } },
	{ { 0, 0, 0 }, 0, 0.5, { 0, 0, 0 }, { 0, 0, 0 } },
	{ { 0, 0, 0 }, 196.2, 0, { 0, 0, 0 }, { 0, 0, 0 } },
	{
		{ 0, 0, 0 },
		196.2,
		0.016666666666666666,
		{ 0, -0.027250001206994057, 0 },
		{ 0, -3.2699999809265137, 0 },
	},
	{ { 0, 0, 0 }, 196.2, 0.5, { 0, -24.524999618530273, 0 }, { 0, -98.0999984741211, 0 } },
	{ { 0, 0, 0 }, -10, 0, { 0, 0, 0 }, { 0, 0, 0 } },
	{
		{ 0, 0, 0 },
		-10,
		0.016666666666666666,
		{ 0, 0.0013888890389353037, 0 },
		{ 0, 0.1666666716337204, 0 },
	},
	{ { 0, 0, 0 }, -10, 0.5, { 0, 1.25, 0 }, { 0, 5, 0 } },
	{ { 0, 0, 0 }, nan, 0, { 0, nan, 0 }, { 0, nan, 0 } },
	{ { 0, 0, 0 }, nan, 0.016666666666666666, { 0, nan, 0 }, { 0, nan, 0 } },
	{ { 0, 0, 0 }, nan, 0.5, { 0, nan, 0 }, { 0, nan, 0 } },
	{ { 30, 40, -80 }, 0, 0, { 0, 0, -0 }, { 30, 40, -80 } },
	{
		{ 30, 40, -80 },
		0,
		0.016666666666666666,
		{ 0.5, 0.6666666865348816, -1.3333333730697632 },
		{ 30, 40, -80 },
	},
	{ { 30, 40, -80 }, 0, 0.5, { 15, 20, -40 }, { 30, 40, -80 } },
	{ { 30, 40, -80 }, 196.2, 0, { 0, 0, -0 }, { 30, 40, -80 } },
	{
		{ 30, 40, -80 },
		196.2,
		0.016666666666666666,
		{ 0.5, 0.6394166350364685, -1.3333333730697632 },
		{ 30, 36.72999954223633, -80 },
	},
	{
		{ 30, 40, -80 },
		196.2,
		0.5,
		{ 15, -4.524999618530273, -40 },
		{ 30, -58.099998474121094, -80 },
	},
	{ { 30, 40, -80 }, -10, 0, { 0, 0, -0 }, { 30, 40, -80 } },
	{
		{ 30, 40, -80 },
		-10,
		0.016666666666666666,
		{ 0.5, 0.6680556535720825, -1.3333333730697632 },
		{ 30, 40.16666793823242, -80 },
	},
	{ { 30, 40, -80 }, -10, 0.5, { 15, 21.25, -40 }, { 30, 45, -80 } },
	{ { 30, 40, -80 }, nan, 0, { 0, nan, -0 }, { 30, nan, -80 } },
	{
		{ 30, 40, -80 },
		nan,
		0.016666666666666666,
		{ 0.5, nan, -1.3333333730697632 },
		{ 30, nan, -80 },
	},
	{ { 30, 40, -80 }, nan, 0.5, { 15, nan, -40 }, { 30, nan, -80 } },
	{ { -0, -0, 0 }, 0, 0, { -0, -0, 0 }, { -0, -0, 0 } },
	{ { -0, -0, 0 }, 0, 0.016666666666666666, { -0, -0, 0 }, { -0, -0, 0 } },
	{ { -0, -0, 0 }, 0, 0.5, { -0, -0, 0 }, { -0, -0, 0 } },
	{ { -0, -0, 0 }, 196.2, 0, { -0, -0, 0 }, { -0, -0, 0 } },
	{
		{ -0, -0, 0 },
		196.2,
		0.016666666666666666,
		{ -0, -0.027250001206994057, 0 },
		{ -0, -3.2699999809265137, 0 },
	},
	{ { -0, -0, 0 }, 196.2, 0.5, { -0, -24.524999618530273, 0 }, { -0, -98.0999984741211, 0 } },
	{ { -0, -0, 0 }, -10, 0, { -0, 0, 0 }, { -0, 0, 0 } },
	{
		{ -0, -0, 0 },
		-10,
		0.016666666666666666,
		{ -0, 0.0013888890389353037, 0 },
		{ -0, 0.1666666716337204, 0 },
	},
	{ { -0, -0, 0 }, -10, 0.5, { -0, 1.25, 0 }, { -0, 5, 0 } },
	{ { -0, -0, 0 }, nan, 0, { -0, nan, 0 }, { -0, nan, 0 } },
	{ { -0, -0, 0 }, nan, 0.016666666666666666, { -0, nan, 0 }, { -0, nan, 0 } },
	{ { -0, -0, 0 }, nan, 0.5, { -0, nan, 0 }, { -0, nan, 0 } },
	{ { nan, 1, 2 }, 0, 0, { nan, 0, 0 }, { nan, 1, 2 } },
	{
		{ nan, 1, 2 },
		0,
		0.016666666666666666,
		{ nan, 0.01666666753590107, 0.03333333507180214 },
		{ nan, 1, 2 },
	},
	{ { nan, 1, 2 }, 0, 0.5, { nan, 0.5, 1 }, { nan, 1, 2 } },
	{ { nan, 1, 2 }, 196.2, 0, { nan, 0, 0 }, { nan, 1, 2 } },
	{
		{ nan, 1, 2 },
		196.2,
		0.016666666666666666,
		{ nan, -0.010583333671092987, 0.03333333507180214 },
		{ nan, -2.2699999809265137, 2 },
	},
	{ { nan, 1, 2 }, 196.2, 0.5, { nan, -24.024999618530273, 1 }, { nan, -97.0999984741211, 2 } },
	{ { nan, 1, 2 }, -10, 0, { nan, 0, 0 }, { nan, 1, 2 } },
	{
		{ nan, 1, 2 },
		-10,
		0.016666666666666666,
		{ nan, 0.01805555447936058, 0.03333333507180214 },
		{ nan, 1.1666666269302368, 2 },
	},
	{ { nan, 1, 2 }, -10, 0.5, { nan, 1.75, 1 }, { nan, 6, 2 } },
	{ { nan, 1, 2 }, nan, 0, { nan, nan, 0 }, { nan, nan, 2 } },
	{
		{ nan, 1, 2 },
		nan,
		0.016666666666666666,
		{ nan, nan, 0.03333333507180214 },
		{ nan, nan, 2 },
	},
	{ { nan, 1, 2 }, nan, 0.5, { nan, nan, 1 }, { nan, nan, 2 } },
}

local function flags(each: (Vector3) -> boolean): string
	local out = {}
	for _, offset in OFFSETS do
		table.insert(out, if each(offset) then "T" else "F")
	end
	return table.concat(out)
end

Check.section("inMeleeReach")
for _, row in MELEE do
	local frame, minimumDot, range, want = FRAMES[row[1]], row[2], row[3], row[4]
	local look = frame.LookVector
	local flatLook = Vector3.new(look.X, 0, look.Z).Unit
	local from = frame.Position
	local got = flags(function(offset)
		return WeaponMath.inMeleeReach(flatLook, minimumDot, from, from + offset, range)
	end)
	equal(got, want, "inMeleeReach " .. show(row[1], minimumDot, range))
end

Check.section("inPushCone")
for _, row in PUSH do
	local origin, range, want = FRAMES[row[1]].Position, row[3], row[4]
	local look = ((origin + DIRECTIONS[row[2]] * 10) - origin).Unit
	local got = flags(function(offset)
		return WeaponMath.inPushCone(look, origin, origin + offset, range)
	end)
	equal(got, want, "inPushCone " .. show(row[1], row[2], range))
end

Check.section("projectileStep")
for _, row in PROJECTILE do
	local velocity = Vector3.new(table.unpack(row[1]))
	local gravity, dt = row[2], row[3]
	local step, nextVelocity = WeaponMath.projectileStep(velocity, gravity, dt)
	check(
		matches(step, row[4]) and matches(nextVelocity, row[5]),
		"projectileStep " .. show(velocity, gravity, dt)
	)
end

Check.section("projectileSize")
for _, impact in { "blackhole", "trap", "", false } do
	for _, blast in { 0, 6, 12, false } do
		local weapon = { impact = impact or nil, blast = blast or nil }
		check(
			same(
				WeaponMath.projectileSize(weapon.impact, weapon.blast),
				Reference.projectileSize(weapon)
			),
			"projectileSize " .. show(impact, blast)
		)
	end
end

Check.section("centerUpright")
local specs = {}
for _, model in Sandbox.loadWeaponModels() do
	table.insert(specs, { id = model.id, spec = model.spec })
end
check(#specs >= 52, "every weapon model loads")
table.insert(specs, { id = "no pieces", spec = { hold = "upright", pieces = {} } })
for _, entry in specs do
	for _, scale in { 1.6, 1, 0 } do
		for _, hold in
			{ WeaponModel.grip(entry.spec):Inverse(), WeaponModel.UPRIGHT_GRIP:Inverse() }
		do
			check(
				same(
					WeaponMath.centerUpright(hold, entry.spec.pieces, scale),
					Reference.centerUpright(hold, entry.spec, scale)
				),
				"centerUpright " .. show(entry.id, scale)
			)
		end
	end
end

Check.finish()
