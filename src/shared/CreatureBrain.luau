--!strict
-- The rules the server's Creatures system runs its monsters by: where a roaming creature may
-- spawn, where an idle one wanders, when a landmark's lair releases a horde, how big it is and
-- which of its monsters are brutes. Pure: Creatures reads the players, the clock and the active
-- list, passes them in, and builds, moves and tracks the Instances. Functions taking a Random
-- draw from it in a fixed order (each says how many). The numbers they share with the rest of the
-- game are in CreatureCatalog. tools/tests/creature_brain.luau compares each with the inline code
-- it replaced in Creatures.luau, and each Random's calls with the calls that code made.

local Config = require(script.Parent.Config)
local CreatureCatalog = require(script.Parent.CreatureCatalog)

local CreatureBrain = {}

local SPAWN_ATTEMPTS = 20 -- random spots tried before a spawn falls back to FALLBACK_RADIUS
local SPAWN_MIN_RADIUS = 130 -- studs from the origin
local SPAWN_EDGE_MARGIN = 40 -- studs inside the world's edge
local SPAWN_REGION_CLEARANCE = 100 -- studs from every landmark's center
local FALLBACK_RADIUS = 300
local WANDER_MIN, WANDER_MAX = 4, 9 -- seconds between wander goals
local WANDER_STEP = 40 -- studs a goal lies at most from the creature, on each flat axis
local HOME_LEASH = 150 -- studs from home past which a wanderer heads home
local LOBBY_MARGIN = 20 -- wander goals stay this far outside the lobby wall

-- Whether a roaming creature may spawn at `point`: away from the lobby, the world's edge and
-- every landmark.
function CreatureBrain.acceptsGroundPoint(point: Vector3): boolean
	local fromOrigin = Vector2.new(point.X, point.Z).Magnitude
	local _, regionDistance = Config.nearestRegion(point)
	return fromOrigin > SPAWN_MIN_RADIUS
		and fromOrigin < Config.WORLD_RADIUS - SPAWN_EDGE_MARGIN
		and regionDistance > SPAWN_REGION_CLEARANCE
end

-- A spawn point minRadius..maxRadius (flat) from `center` that acceptsGroundPoint, or after
-- SPAWN_ATTEMPTS misses a point FALLBACK_RADIUS from the origin. Two draws per attempt (angle,
-- radius), plus one (angle) for the fallback.
function CreatureBrain.groundPoint(
	rng: Random,
	center: Vector3,
	minRadius: number,
	maxRadius: number
): Vector3
	for _ = 1, SPAWN_ATTEMPTS do
		local angle = rng:NextNumber(0, math.pi * 2)
		local radius = rng:NextNumber(minRadius, maxRadius)
		local point = center + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
		if CreatureBrain.acceptsGroundPoint(point) then
			return point
		end
	end
	return Config.pointAt(rng:NextNumber(0, math.pi * 2), FALLBACK_RADIUS)
end

-- An idle creature at `position` picks its next wander: when it next wanders (one draw), and the
-- goal to walk to (two more draws, x then z, unless it is past HOME_LEASH from `home` and heads
-- home). The goal is nil when it lies within LOBBY_MARGIN of the lobby wall: the creature stays.
function CreatureBrain.wander(
	rng: Random,
	now: number,
	position: Vector3,
	home: Vector3
): (number, Vector3?)
	local wanderAt = now + rng:NextNumber(WANDER_MIN, WANDER_MAX)
	local fromHome = (position - home).Magnitude
	local goal = if fromHome > HOME_LEASH
		then home
		else position + Vector3.new(
			rng:NextNumber(-WANDER_STEP, WANDER_STEP),
			0,
			rng:NextNumber(-WANDER_STEP, WANDER_STEP)
		)
	if Vector2.new(goal.X, goal.Z).Magnitude > Config.LOBBY_RADIUS + LOBBY_MARGIN then
		return wanderAt, goal
	end
	return wanderAt, nil
end

-- Whether a lair releases a horde: `nearby` deployed players are in range, its cooldown (the time
-- it may next open, nil if never opened) has passed, and fewer than LAIR_CAP of its creatures live.
function CreatureBrain.lairOpens(
	nearby: number,
	now: number,
	cooldownUntil: number?,
	live: number
): boolean
	return nearby > 0 and now >= (cooldownUntil or 0) and live < CreatureCatalog.LAIR_CAP
end

-- How many monsters a lair releases for `nearby` players.
function CreatureBrain.hordeSize(nearby: number): number
	return CreatureCatalog.LAIR_HORDE_BASE + CreatureCatalog.LAIR_HORDE_PER_PLAYER * (nearby - 1)
end

-- The kind of a lair horde's `count`th monster (from 1).
function CreatureBrain.lairKind(count: number): string
	return if count % CreatureCatalog.LAIR_BRUTE_EVERY == 0
		then CreatureCatalog.LAIR_BRUTE
		else CreatureCatalog.LAIR_KIND
end

return CreatureBrain
