--!strict
-- Night lighting rules: pure, no services, so Lune can load it for tests. The server's
-- world/Lamps builds the lamps and fireflies from these plans; systems/NightLights switches
-- every part tagged Names.Tags.NightLight by `step` of Lighting.ClockTime.
--
-- Level: 0 by day, 1 by night, a straight ramp across a band of BAND_HOURS centred on dusk (18)
-- and dawn (6). The applying module writes only when the level's step (0..STEPS) changes.
--
-- Placement: lamps stand ROADSIDE studs from a road's centre line, SPACING apart along it,
-- alternating sides. A lamp is dropped inside the lobby's apron, a motor pool, a landmark's
-- clearing (the same LANDMARK_CLEARANCE scenery keeps) or ROAD_CLEAR of any road's centre line
-- (where roads cross). The road shapes follow world/Roads: rings as circles, spokes from the
-- lobby wall to SPOKE_END_RADIUS, cross roads between the rings. Every LIGHT_EVERY-th kept lamp
-- on a route carries a dynamic light; the rest glow with Neon only. MAX_LIGHTS caps the dynamic
-- lights world/Lamps adds (landmark lamps built by the buildings are extra).

local Config = require(script.Parent.Config)

local NightLights = {}

local DAWN = 6
local DUSK = 18

NightLights.BAND_HOURS = 1
NightLights.STEPS = 8
NightLights.FIREFLY_LEVEL = 0.5 -- fireflies fly from this level up

NightLights.SPACING = 72
NightLights.ROADSIDE = 16 -- past the widest road's edge (24 wide)
NightLights.ROAD_CLEAR = 14 -- half the widest road, plus 2
NightLights.LIGHT_EVERY = 4
NightLights.MAX_LIGHTS = 48
NightLights.LANDMARK_CLEARANCE = 145
NightLights.LOBBY_APRON = 20 -- studs past the lobby wall kept for the lobby lamps
NightLights.LOBBY_LAMP_ALONG = 6 -- lobby lamps: studs past the wall along each spoke
NightLights.LOBBY_LAMP_ACROSS = 17 -- and from the spoke's centre line

-- Light level (0..1) at a ClockTime. NaN or an infinite clock gives 0 (lights off).
function NightLights.level(clock: number): number
	local c = clock % 24
	if c ~= c then
		return 0
	end
	local half = NightLights.BAND_HOURS / 2
	if c >= DUSK - half and c < DUSK + half then
		return (c - (DUSK - half)) / NightLights.BAND_HOURS
	end
	if c >= DAWN - half and c < DAWN + half then
		return (DAWN + half - c) / NightLights.BAND_HOURS
	end
	return if c >= DAWN + half and c < DUSK - half then 0 else 1
end

-- The level rounded to a step, 0..STEPS.
function NightLights.step(clock: number): number
	return math.round(NightLights.level(clock) * NightLights.STEPS)
end

function NightLights.levelAt(step: number): number
	return step / NightLights.STEPS
end

-- A glowing part's colour at `level`: black (unlit Neon) up to its built colour.
function NightLights.glowColor(color: Color3, level: number): Color3
	return Color3.new(0, 0, 0):Lerp(color, math.clamp(level, 0, 1))
end

export type Lamp = {
	position: Vector3, -- foot of the pole, at ground height 0
	toward: Vector3, -- flat unit vector from the pole to the road it lights
	lit: boolean, -- carries a dynamic light
}

-- Flat distance from `p` to the straight road along `angle` from radius `from` to `to`.
local function straightDistance(p: Vector3, angle: number, from: number, to: number): number
	local along = Config.pointAt(angle, 1)
	local t = math.clamp(p:Dot(along), from, to)
	return (Vector3.new(p.X, 0, p.Z) - along * t).Magnitude
end

-- Flat distance from `p` to the nearest road centre line.
function NightLights.roadDistance(p: Vector3): number
	local radius = Vector2.new(p.X, p.Z).Magnitude
	local best = math.min(
		math.abs(radius - Config.INNER_ROAD_RADIUS),
		math.abs(radius - Config.OUTER_ROAD_RADIUS)
	)
	for index = 1, #Config.REGIONS do
		best = math.min(
			best,
			straightDistance(
				p,
				Config.regionAngle(index),
				Config.LOBBY_RADIUS + 2,
				Config.SPOKE_END_RADIUS
			),
			straightDistance(
				p,
				Config.betweenRegions(index),
				Config.INNER_ROAD_RADIUS,
				Config.OUTER_ROAD_RADIUS
			)
		)
	end
	return best
end

local function keep(position: Vector3): boolean
	local radius = Vector2.new(position.X, position.Z).Magnitude
	if radius < Config.LOBBY_RADIUS + NightLights.LOBBY_APRON then
		return false
	end
	local _, landmark = Config.nearestRegion(position)
	return landmark >= NightLights.LANDMARK_CLEARANCE
		and not Config.isInParking(position)
		and NightLights.roadDistance(position) >= NightLights.ROAD_CLEAR
end

-- Adds a route's kept lamps to `lamps`; the count of kept lamps sets `lit`.
local function addRoute(lamps: { Lamp }, candidates: { { position: Vector3, toward: Vector3 } })
	local kept = 0
	for _, candidate in candidates do
		if keep(candidate.position) then
			table.insert(lamps, {
				position = candidate.position,
				toward = candidate.toward,
				lit = kept % NightLights.LIGHT_EVERY == 0,
			})
			kept += 1
		end
	end
end

local function ring(radius: number): { { position: Vector3, toward: Vector3 } }
	local count = math.floor(2 * math.pi * radius / NightLights.SPACING)
	local list = {}
	for index = 0, count - 1 do
		local angle = (index + 0.5) / count * 2 * math.pi
		local side = if index % 2 == 0 then 1 else -1 -- outside, then inside
		local outward = Config.pointAt(angle, 1)
		table.insert(list, {
			position = Config.pointAt(angle, radius + side * NightLights.ROADSIDE),
			toward = -outward * side,
		})
	end
	return list
end

local function straight(
	angle: number,
	from: number,
	to: number
): { { position: Vector3, toward: Vector3 } }
	local count = math.floor((to - from) / NightLights.SPACING)
	local along = Config.pointAt(angle, 1)
	local across = Vector3.new(-along.Z, 0, along.X)
	local list = {}
	for index = 0, count - 1 do
		local distance = from + (index + 0.5) * (to - from) / count
		local side = if index % 2 == 0 then 1 else -1
		table.insert(list, {
			position = along * distance + across * side * NightLights.ROADSIDE,
			toward = -across * side,
		})
	end
	return list
end

-- Lamps along the roads world/Roads lays: both ring roads, the spokes and the cross roads, in
-- that order.
function NightLights.roadLamps(): { Lamp }
	local lamps: { Lamp } = {}
	addRoute(lamps, ring(Config.INNER_ROAD_RADIUS))
	addRoute(lamps, ring(Config.OUTER_ROAD_RADIUS))
	for index = 1, #Config.REGIONS do
		addRoute(
			lamps,
			straight(Config.regionAngle(index), Config.LOBBY_RADIUS + 2, Config.SPOKE_END_RADIUS)
		)
	end
	for index = 1, #Config.REGIONS do
		addRoute(
			lamps,
			straight(
				Config.betweenRegions(index),
				Config.INNER_ROAD_RADIUS,
				Config.OUTER_ROAD_RADIUS
			)
		)
	end
	return lamps
end

-- Two lamps outside each lobby gate, either side of the spoke, all lit.
function NightLights.lobbyLamps(): { Lamp }
	local lamps: { Lamp } = {}
	for index = 1, #Config.REGIONS do
		local along = Config.pointAt(Config.regionAngle(index), 1)
		local across = Vector3.new(-along.Z, 0, along.X)
		for _, side in { -1, 1 } do
			table.insert(lamps, {
				position = along * (Config.LOBBY_RADIUS + NightLights.LOBBY_LAMP_ALONG)
					+ across * side * NightLights.LOBBY_LAMP_ACROSS,
				toward = -across * side,
				lit = true,
			})
		end
	end
	return lamps
end

-- `count` distinct indices in 1..total, in draw order, from `random`. Draws one NextInteger per
-- attempt, at most count * 4 attempts; fewer come back when total < count.
function NightLights.pick(random: Random, total: number, count: number): { number }
	local picked: { number } = {}
	local seen: { [number]: boolean } = {}
	local attempts = 0
	while #picked < math.min(count, total) and attempts < count * 4 do
		attempts += 1
		local index = random:NextInteger(1, total)
		if not seen[index] then
			seen[index] = true
			table.insert(picked, index)
		end
	end
	return picked
end

return NightLights
