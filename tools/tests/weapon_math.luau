-- Checks src/shared/WeaponMath.luau outside Roblox.
-- Usage: lune run tools/tests/weapon_math.luau
--
--   - every function returns the same bits (signed zeros and NaNs included; vectors and frames
--     component by component) as the inline code it replaced in Weapons.luau, copied below word
--     for word as the reference, over a sweep of inputs: zero and -0, values on each threshold and
--     a hair either side, NaN, and every weapon model file for the display centering
--   - spreadDirection makes the same calls, in the same order with the same arguments, on the
--     Random it is given (a recording fake) as the inline code made on its own Random
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

-- spreadDirection, with the module's `random` as an argument.
function Reference.spreadDirection(direction, degrees, random)
	if degrees <= 0 then
		return direction
	end
	local frame = CFrame.lookAt(Vector3.zero, direction)
	local pitch = math.rad(random:NextNumber(-degrees, degrees))
	local yaw = math.rad(random:NextNumber(-degrees, degrees))
	return (frame * CFrame.Angles(pitch, yaw, 0)).LookVector
end

-- The FireWeapon handler's cooldown test.
function Reference.coolingDown(times, weaponId, now, cooldown)
	return times[weaponId] and now - times[weaponId] < cooldown * 0.85
end

-- fireMelee, per target: `from` is shot.root.Position, `to` target.root.Position.
function Reference.inMeleeReach(flatLook, minimumDot, from, to, range)
	local offset = to - from
	local flat = Vector3.new(offset.X, 0, offset.Z)
	local inReach = offset.Magnitude <= range + 1.5
	local inFront = flat.Magnitude < 2 or flatLook:Dot(flat.Unit) >= minimumDot
	return inReach and inFront
end

-- firePush, per target: `origin` is shot.origin, `position` target.root.Position.
function Reference.inPushCone(look, origin, position, range)
	local offset = position - origin
	return offset.Magnitude <= range and look:Dot(offset.Unit) > 0.4
end

-- The projectile Heartbeat.
function Reference.projectileStep(velocity, gravity, dt)
	local nextVelocity = velocity - Vector3.new(0, gravity * dt, 0)
	local step = (velocity + nextVelocity) / 2 * dt
	return step, nextVelocity
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
	Vector3.new(2 + hair, 0, 0),
	Vector3.new(0, 0, -2),
	Vector3.new(0, 5, 1),
	Vector3.new(0, 0, -6),
	Vector3.new(0, 0, -7.5),
	Vector3.new(0, 0, -7.5 - hair),
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
local RANGES = { 0, 6, 10, 20, 40, -1, nan }

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
for _, seed in { 1, 77, 424242 } do
	for _, direction in DIRECTIONS do
		for _, degrees in { 0, -0, -3, hair, 0.5, 4, 8, 30, 90, nan } do
			local old, oldLog = recorder(seed)
			local new, newLog = recorder(seed)
			for draw = 1, 5 do
				check(
					same(
						WeaponMath.spreadDirection(direction, degrees, new),
						Reference.spreadDirection(direction, degrees, old)
					),
					"spreadDirection " .. show(seed, direction, degrees, draw)
				)
			end
			check(same(newLog, oldLog), "spreadDirection calls " .. show(seed, direction, degrees))
		end
	end
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

Check.section("inMeleeReach")
for _, frame in FRAMES do
	local look = frame.LookVector
	local flatLook = Vector3.new(look.X, 0, look.Z).Unit
	local from = frame.Position
	for _, minimumDot in { 0.3, 0, -1, 0.7, 1, nan } do
		for _, offset in OFFSETS do
			for _, range in RANGES do
				local to = from + offset
				check(
					same(
						WeaponMath.inMeleeReach(flatLook, minimumDot, from, to, range),
						Reference.inMeleeReach(flatLook, minimumDot, from, to, range)
					),
					"inMeleeReach " .. show(frame, minimumDot, offset, range)
				)
			end
		end
	end
end

Check.section("inPushCone")
for _, frame in FRAMES do
	for _, aimOffset in DIRECTIONS do
		local origin = frame.Position
		local look = ((origin + aimOffset * 10) - origin).Unit
		for _, offset in OFFSETS do
			for _, range in RANGES do
				local position = origin + offset
				check(
					same(
						WeaponMath.inPushCone(look, origin, position, range),
						Reference.inPushCone(look, origin, position, range)
					),
					"inPushCone " .. show(frame, aimOffset, offset, range)
				)
			end
		end
	end
end

Check.section("projectileStep")
for _, velocity in
	{
		Vector3.zero,
		Vector3.new(0, 0, -100),
		Vector3.new(30, 40, -80),
		Vector3.new(-0, -0, 0),
		Vector3.new(nan, 1, 2),
	}
do
	for _, gravity in { 0, 196.2 * 0.3, 196.2, -10, nan } do
		for _, dt in { 0, 1 / 240, 1 / 60, 1 / 30, 0.5 } do
			local newStep, newVelocity = WeaponMath.projectileStep(velocity, gravity, dt)
			local oldStep, oldVelocity = Reference.projectileStep(velocity, gravity, dt)
			check(
				same(newStep, oldStep) and same(newVelocity, oldVelocity),
				"projectileStep " .. show(velocity, gravity, dt)
			)
		end
	end
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
