--!strict
-- Monster kinds and where they live (data only, no requires). The server's Creatures system spawns
-- them; tools/tests/data_integrity checks every kind has a model file and every region a themed
-- kind and a lair.

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
	castle = { inside = 10, outside = -105, y = 1.6, xs = { 0 } }, -- out of the keep, through the gate
	pagoda = { inside = -27, outside = -80, y = 5, xs = { 0 } },
	tower = { inside = -24, outside = -55, y = 1.8, xs = { 0 } },
	pyramid = { inside = -72, outside = -105, y = 0.6, xs = { -40, 40 } },
	palace = { inside = -27, outside = -60, y = 1.6, xs = { 0 } },
}

return {
	KINDS = KINDS,
	REGION_KIND = REGION_KIND,
	LAIRS = LAIRS,
}
