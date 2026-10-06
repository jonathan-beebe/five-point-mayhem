--!strict
-- Monster kinds, where they live, how many and how often (data only, no requires). The server's
-- Creatures system spawns them and CreatureBrain holds the rules that read these numbers;
-- tools/tests/data_integrity checks every kind has a model file and every region a themed kind and
-- a lair; tools/tests/creature_brain pins the numbers and checks every kind they name exists.

-- `scale` sets knockback strength; the look and size come from the kind's file in
-- src/server/creatureModels (format: src/server/systems/CreatureModel.luau).
export type Kind = {
	name: string,
	health: number,
	speed: number,
	damage: number,
	scale: number,
	aggro: number,
	hops: boolean?, -- jumps while chasing
}

local KINDS: { [string]: Kind } = {
	goblin = {
		name = "Goblin",
		health = 45,
		speed = 18,
		damage = 8,
		scale = 0.8,
		aggro = 80,
	},
	slime = {
		name = "Slime",
		health = 35,
		speed = 14,
		damage = 6,
		scale = 1,
		aggro = 60,
		hops = true,
	},
	skeleton = {
		name = "Skeleton Knight",
		health = 90,
		speed = 15,
		damage = 14,
		scale = 1,
		aggro = 90,
	},
	oni = {
		name = "Oni",
		health = 220,
		speed = 12,
		damage = 26,
		scale = 2,
		aggro = 100,
	},
	robot = {
		name = "Robo-Guard",
		health = 140,
		speed = 16,
		damage = 18,
		scale = 1.4,
		aggro = 120,
	},
	trex = {
		name = "T-Rex",
		health = 400,
		speed = 17,
		damage = 40,
		scale = 2.6,
		aggro = 130,
	},
	zombie = {
		name = "Zombie",
		health = 60,
		speed = 13,
		damage = 10,
		scale = 1,
		aggro = 160,
	},
	brute = {
		name = "Zombie Brute",
		health = 260,
		speed = 11,
		damage = 25,
		scale = 1.8,
		aggro = 160,
	},
	yeti = {
		name = "Yeti",
		health = 260,
		speed = 13,
		damage = 28,
		scale = 2.2,
		aggro = 100,
	},
}

-- Themed monster near each landmark, by region id.
local REGION_KIND =
	{ castle = "skeleton", pagoda = "oni", tower = "robot", pyramid = "trex", palace = "yeti" }

-- Where each landmark's horde appears and walks out to, in the landmark's local frame (local -Z
-- faces the lobby). `y` is the floor height inside; `xs` are the doors used.
local LAIRS = {
	-- Out of the keep, through the gate.
	castle = { inside = 10, outside = -105, y = 1.6, xs = { 0 } },
	pagoda = { inside = -27, outside = -80, y = 5, xs = { 0 } },
	tower = { inside = -24, outside = -55, y = 1.8, xs = { 0 } },
	pyramid = { inside = -72, outside = -105, y = 0.6, xs = { -40, 40 } },
	palace = { inside = -27, outside = -60, y = 1.6, xs = { 0 } },
}

-- Roaming creatures spawned at start, by kind; each landmark's themed kind adds THEMED_COUNT.
-- Roaming creatures respawn RESPAWN_SECONDS after dying, at a fresh spot.
local ROAMING: { [string]: number } = { goblin = 12, slime = 6, zombie = 30 }
local THEMED_COUNT = 3
local RESPAWN_SECONDS = 25

-- The admin horde (Creatures.horde) picks each monster from this list; repeats weigh the draw.
-- Horde monsters do not respawn.
local HORDE_KINDS = {
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
}

-- Lairs: deployed players within LAIR_TRIGGER_RADIUS (flat) of a landmark's center release a horde
-- of LAIR_HORDE_BASE + LAIR_HORDE_PER_PLAYER per extra player, every LAIR_BRUTE_EVERY-th of them
-- a LAIR_BRUTE, the rest LAIR_KIND; at most once per LAIR_COOLDOWN seconds, and not while
-- LAIR_CAP or more from that lair are alive. A lair creature with no target for LAIR_DESPAWN
-- seconds vanishes.
local LAIR_TRIGGER_RADIUS = 175
local LAIR_COOLDOWN = 50
local LAIR_CAP = 30
local LAIR_HORDE_BASE = 14
local LAIR_HORDE_PER_PLAYER = 6
local LAIR_BRUTE_EVERY = 8
local LAIR_KIND = "zombie"
local LAIR_BRUTE = "brute"
local LAIR_DESPAWN = 45

-- Brains: every creature thinks each THINK_INTERVAL seconds and attacks at most once per
-- ATTACK_INTERVAL.
local THINK_INTERVAL = 0.3
local ATTACK_INTERVAL = 1.1

return {
	KINDS = KINDS,
	REGION_KIND = REGION_KIND,
	LAIRS = LAIRS,
	ROAMING = ROAMING,
	THEMED_COUNT = THEMED_COUNT,
	RESPAWN_SECONDS = RESPAWN_SECONDS,
	HORDE_KINDS = HORDE_KINDS,
	LAIR_TRIGGER_RADIUS = LAIR_TRIGGER_RADIUS,
	LAIR_COOLDOWN = LAIR_COOLDOWN,
	LAIR_CAP = LAIR_CAP,
	LAIR_HORDE_BASE = LAIR_HORDE_BASE,
	LAIR_HORDE_PER_PLAYER = LAIR_HORDE_PER_PLAYER,
	LAIR_BRUTE_EVERY = LAIR_BRUTE_EVERY,
	LAIR_KIND = LAIR_KIND,
	LAIR_BRUTE = LAIR_BRUTE,
	LAIR_DESPAWN = LAIR_DESPAWN,
	THINK_INTERVAL = THINK_INTERVAL,
	ATTACK_INTERVAL = ATTACK_INTERVAL,
}
