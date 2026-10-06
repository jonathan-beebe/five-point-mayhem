-- Checks the creature rules Creatures uses (src/shared/CreatureBrain) and the creature numbers in
-- CreatureCatalog outside Roblox.
-- Usage: lune run tools/tests/creature_brain.luau
--
--   - every function returns the same bits (signed zeros and NaNs included; vectors component by
--     component) as the inline code it replaced in Creatures.luau, copied below word for word as
--     the reference, over a sweep of inputs: values on each threshold and a hair either side, NaN.
--     Magnitudes are single precision, so a distance's hair is 0.01 (1e-6 rounds onto the line)
--   - groundPoint and wander make the same calls, in the same order with the same arguments, on
--     the Random they are given (a recording fake) as the inline code made on its own Random
--   - CreatureCatalog's counts, lists and timings equal the literals Creatures.luau had

local luau = require("@lune/luau")
local roblox = require("@lune/roblox")

local Check = require("../lib/Check")
local Sandbox = require("../lib/Sandbox")

local check, equal = Check.check, Check.equal
local Vector3, Vector2 = roblox.Vector3, roblox.Vector2

Check.printLimit = 10

local Shared = Sandbox.game:GetService("ReplicatedStorage").Shared
local Config = Sandbox.require(Shared.Config)
local CreatureBrain = Sandbox.require(Shared.CreatureBrain)
local CreatureCatalog = Sandbox.require(Shared.CreatureCatalog)

-- The inline code CreatureBrain replaced, from Creatures.luau at 3c65531, word for word inside
-- functions that take its free variables (the Random, the creature) as arguments. Compiled with
-- luau.load, as Sandbox.require compiles CreatureBrain.
local Reference = luau.load(
	[[
local Reference = {}

-- randomGroundPoint's test, alone.
function Reference.accepts(point)
	local fromOrigin = Vector2.new(point.X, point.Z).Magnitude
	local _, regionDistance = Config.nearestRegion(point)
	if fromOrigin > 130 and fromOrigin < Config.WORLD_RADIUS - 40 and regionDistance > 100 then
		return true
	end
	return false
end
function Reference.randomGroundPoint(random, center, minRadius, maxRadius)
	for _ = 1, 20 do
		local angle = random:NextNumber(0, math.pi * 2)
		local radius = random:NextNumber(minRadius, maxRadius)
		local point = center + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
		local fromOrigin = Vector2.new(point.X, point.Z).Magnitude
		local _, regionDistance = Config.nearestRegion(point)
		if fromOrigin > 130 and fromOrigin < Config.WORLD_RADIUS - 40 and regionDistance > 100 then
			return point
		end
	end
	return Config.pointAt(random:NextNumber(0, math.pi * 2), 300)
end
-- think's wander branch. Returns wanderAt and the goal MoveTo was given (nil when none).
function Reference.wander(random, creature, now)
	local moved = nil
	creature.wanderAt = now + random:NextNumber(4, 9)
	local fromHome = (creature.root.Position - creature.home).Magnitude
	local goal = if fromHome > 150
		then creature.home
		else creature.root.Position + Vector3.new(
			random:NextNumber(-40, 40),
			0,
			random:NextNumber(-40, 40)
		)
	if Vector2.new(goal.X, goal.Z).Magnitude > Config.LOBBY_RADIUS + 20 then
		moved = goal
	end
	return creature.wanderAt, moved
end
-- watchLairs: `cooldown` is lairCooldown[region.id], `live` liveFromLair(region.id).
function Reference.lairOpens(nearby, now, cooldown, live)
	local lairCooldown = { lair = cooldown }
	if
		nearby > 0
		and now >= (lairCooldown.lair or 0)
		and live < 30
	then
		return true
	end
	return false
end
function Reference.hordeSize(nearby)
	return 14 + 6 * (nearby - 1)
end
-- releaseHorde
function Reference.lairKind(count)
	local kindId = if count % 8 == 0 then "brute" else "zombie"
	return kindId
end

return Reference
]],
	{
		debugName = "Creatures reference",
		environment = { Vector3 = Vector3, Vector2 = Vector2, Config = Config },
	}
)()

-- Same bits: -0 differs from 0, a NaN equals the same NaN; vectors and tables compare part by part.
local function same(a: any, b: any): boolean
	local kind = typeof(a)
	if kind ~= typeof(b) then
		return false
	elseif kind == "number" then
		return string.pack("<d", a) == string.pack("<d", b)
	elseif kind == "Vector3" then
		return same(a.X, b.X) and same(a.Y, b.Y) and same(a.Z, b.Z)
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

local nan = 0 / 0
local SEEDS = { 1, 77, 1337, 424242 }

Check.section("CreatureBrain.acceptsGroundPoint")
-- Flat distances from the origin around 130 and WORLD_RADIUS - 40, and from each landmark's center
-- around 100, along a few bearings.
local radii = { 0, 129.99, 130, 130.01, 131, 959, 959.99, 960, 960.01, 1500, nan }
for _, radius in radii do
	for step = 0, 15 do
		local point = Config.pointAt(step * math.pi / 8, radius)
		equal(
			CreatureBrain.acceptsGroundPoint(point),
			Reference.accepts(point),
			"acceptsGroundPoint " .. show(radius, step)
		)
	end
end
for index = 1, #Config.REGIONS do
	local center = Config.regionCenter(index)
	for _, distance in { 0, 99.99, 100, 100.01, 101, 250 } do
		for step = 0, 7 do
			local point = center + Config.pointAt(step * math.pi / 4, distance, 3)
			equal(
				CreatureBrain.acceptsGroundPoint(point),
				Reference.accepts(point),
				"acceptsGroundPoint near region " .. show(index, distance, step)
			)
		end
	end
end

Check.section("CreatureBrain.groundPoint")
-- Creatures' two calls (around a landmark, across the board), and one that always falls back.
local spawns = { { Vector3.zero, 150, Config.WORLD_RADIUS - 50 }, { Vector3.zero, 0, 10 } }
for index = 1, #Config.REGIONS do
	table.insert(spawns, { Config.regionCenter(index), 110, 220 })
end
local fellBack = false
for _, spawn in spawns do
	for _, seed in SEEDS do
		local old, oldLog = recorder(seed)
		local new, newLog = recorder(seed)
		for draw = 1, 40 do
			local want = Reference.randomGroundPoint(old, spawn[1], spawn[2], spawn[3])
			check(
				same(CreatureBrain.groundPoint(new, spawn[1], spawn[2], spawn[3]), want),
				"groundPoint " .. show(spawn[1], spawn[2], spawn[3], seed, draw)
			)
			fellBack = fellBack or Vector2.new(want.X, want.Z).Magnitude == 300
		end
		check(same(newLog, oldLog), "groundPoint calls on Random " .. show(spawn[1], seed))
	end
end
check(fellBack, "the sweep reaches the fallback")

Check.section("CreatureBrain.wander")
local homes = {
	Config.pointAt(0, 300),
	Config.pointAt(1, Config.LOBBY_RADIUS + 20),
	Config.pointAt(2, 80),
}
local leash = { 0, 149.99, 150, 150.01, 151, 400, nan }
local nows = { 0, 12.5, 1e6, nan }
for _, home in homes do
	for _, distance in leash do
		for step = 0, 7 do
			local position = home + Config.pointAt(step * math.pi / 4, distance, 2)
			for _, now in nows do
				for _, seed in SEEDS do
					local old, oldLog = recorder(seed)
					local new, newLog = recorder(seed)
					local creature = { root = { Position = position }, home = home, wanderAt = 0 }
					local wantAt, wantGoal = Reference.wander(old, creature, now)
					local gotAt, gotGoal = CreatureBrain.wander(new, now, position, home)
					check(
						same(gotAt, wantAt) and same(gotGoal, wantGoal),
						"wander " .. show(home, distance, step, now, seed)
					)
					check(same(newLog, oldLog), "wander calls on Random " .. show(distance, seed))
				end
			end
		end
	end
end
-- A wanderer past the leash heads for a home on each side of the lobby margin (LOBBY_RADIUS + 20).
for _, radius in { 75, 75.99, 76, 76.01, 76.5, 77, 78 } do
	for step = 0, 7 do
		local home = Config.pointAt(step * math.pi / 4, radius)
		local position = home + Config.pointAt(step * math.pi / 4, 200)
		local old = recorder(1)
		local new = recorder(1)
		local creature = { root = { Position = position }, home = home, wanderAt = 0 }
		local wantAt, wantGoal = Reference.wander(old, creature, 5)
		local gotAt, gotGoal = CreatureBrain.wander(new, 5, position, home)
		check(
			same(gotAt, wantAt) and same(gotGoal, wantGoal),
			"wander home by the lobby " .. show(radius, step)
		)
	end
end
-- Goals inside the lobby margin stay nil; a home past the leash is the goal unmoved.
local _, inside = CreatureBrain.wander(recorder(1), 0, Vector3.zero, Vector3.zero)
equal(inside, nil, "a goal by the lobby is nil")
local far = Config.pointAt(0, 300)
local _, homeward = CreatureBrain.wander(recorder(1), 0, far + Vector3.new(200, 0, 0), far)
check(same(homeward, far), "past the leash the goal is home")

Check.section("CreatureBrain lairs")
for _, nearby in { -1, 0, 1, 2, 7, nan } do
	for _, now in { 0, 49.999999, 50, 50.000001, 1e6, nan } do
		for _, cooldown in { false, 0, 50, nan } do
			for _, live in { 0, 29, 29.999999, 30, 31, nan } do
				local until_ = if cooldown == false then nil else cooldown
				equal(
					CreatureBrain.lairOpens(nearby, now, until_, live),
					Reference.lairOpens(nearby, now, until_, live),
					"lairOpens " .. show(nearby, now, until_, live)
				)
			end
		end
	end
end
for _, nearby in { -1, 0, 1, 2, 3, 10, 64, 0.5, -0, nan } do
	check(
		same(CreatureBrain.hordeSize(nearby), Reference.hordeSize(nearby)),
		"hordeSize " .. show(nearby)
	)
end
for count = -16, 64 do
	equal(CreatureBrain.lairKind(count), Reference.lairKind(count), "lairKind " .. count)
end
equal(CreatureBrain.lairKind(nan), Reference.lairKind(nan), "lairKind NaN")
equal(CreatureBrain.hordeSize(1), 14, "one player brings 14")
equal(CreatureBrain.lairKind(8), "brute", "every 8th is a brute")

Check.section("CreatureCatalog numbers")
-- The literals Creatures.luau had at 3c65531.
check(
	same(CreatureCatalog.ROAMING, { goblin = 12, slime = 6, zombie = 30 }),
	"ROAMING is goblin 12, slime 6, zombie 30"
)
check(
	same(CreatureCatalog.HORDE_KINDS, {
		"zombie",
		"zombie",
		"zombie",
		"goblin",
		"slime",
		"skeleton",
		"oni",
		"yeti",
		"trex",
		"robot",
		"brute",
	}),
	"HORDE_KINDS in order"
)
local NUMBERS = {
	THEMED_COUNT = 3,
	RESPAWN_SECONDS = 25,
	LAIR_TRIGGER_RADIUS = 175,
	LAIR_COOLDOWN = 50,
	LAIR_CAP = 30,
	LAIR_HORDE_BASE = 14,
	LAIR_HORDE_PER_PLAYER = 6,
	LAIR_BRUTE_EVERY = 8,
	LAIR_KIND = "zombie",
	LAIR_BRUTE = "brute",
	LAIR_DESPAWN = 45,
	THINK_INTERVAL = 0.3,
	ATTACK_INTERVAL = 1.1,
}
for name, want in NUMBERS do
	equal(CreatureCatalog[name], want, "CreatureCatalog." .. name)
end
for _, id in CreatureCatalog.HORDE_KINDS do
	check(CreatureCatalog.KINDS[id] ~= nil, "HORDE_KINDS: unknown kind " .. id)
end
for id in CreatureCatalog.ROAMING do
	check(CreatureCatalog.KINDS[id] ~= nil, "ROAMING: unknown kind " .. id)
end
for _, id in { CreatureCatalog.LAIR_KIND, CreatureCatalog.LAIR_BRUTE } do
	check(CreatureCatalog.KINDS[id] ~= nil, "lair kind: unknown kind " .. id)
end

Check.finish()
