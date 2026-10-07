-- Checks the night lighting rules (src/shared/NightLights.luau) outside Roblox.
-- Usage: lune run tools/tests/night_lights.luau
--
--   - level: 0 by day, 1 by night, a ramp across the dusk and dawn bands (golden values), never
--     falling through dusk or rising through dawn, wrapping past 24, 0 for NaN and infinities
--   - step rounds the level to 0..STEPS; levelAt inverts it
--   - glowColor runs from black to the built colour and clamps
--   - roadLamps and lobbyLamps: the counts at this commit (a spacing change updates them), every
--     lamp off the lobby apron, out of motor pools and landmark clearings, ROADSIDE from its
--     road's centre line and facing it; lit lamps (lobby plus road) fit under MAX_LIGHTS
--   - pick: distinct indices in range, `count` of them, fewer when there are fewer, no draws for
--     an empty list

local roblox = require("@lune/roblox")

local Check = require("../lib/Check")
local Sandbox = require("../lib/Sandbox")

local Color3, Vector2, Vector3 = roblox.Color3, roblox.Vector2, roblox.Vector3

local check, equal, near = Check.check, Check.equal, Check.isNear

local Config = Sandbox.load("src/shared/Config.luau")
local NightLights = Sandbox.load("src/shared/NightLights.luau")

Check.section("level")
local GOLDEN_LEVEL = {
	{ 0, 1 },
	{ 3, 1 },
	{ 5.5, 1 },
	{ 5.75, 0.75 },
	{ 6, 0.5 },
	{ 6.25, 0.25 },
	{ 6.5, 0 },
	{ 12, 0 },
	{ 17.5, 0 },
	{ 17.75, 0.25 },
	{ 18, 0.5 },
	{ 18.25, 0.75 },
	{ 18.5, 1 },
	{ 23.99, 1 },
	{ 24, 1 },
	{ 30, 0.5 },
	{ -6, 0.5 },
	{ 42, 0.5 },
}
for _, case in GOLDEN_LEVEL do
	local got = NightLights.level(case[1])
	check(near(got, case[2]), ("level(%g) = %g, want %g"):format(case[1], got, case[2]))
end
for _, bad in { 0 / 0, math.huge, -math.huge } do
	equal(NightLights.level(bad), 0, "level(" .. tostring(bad) .. ")")
	equal(NightLights.step(bad), 0, "step(" .. tostring(bad) .. ")")
end
-- Rises through dusk, falls through dawn, stays in 0..1.
local previous = NightLights.level(12)
for minute = 12 * 60 + 1, 24 * 60 do
	local level = NightLights.level(minute / 60)
	check(level >= previous - 1e-12, ("level falls at %d min"):format(minute))
	check(level >= 0 and level <= 1, ("level in 0..1 at %d min"):format(minute))
	previous = level
end
for minute = 1, 12 * 60 do
	local level = NightLights.level(minute / 60)
	check(level <= previous + 1e-12, ("level rises at %d min"):format(minute))
	previous = level
end

Check.section("step")
equal(NightLights.step(12), 0, "noon")
equal(NightLights.step(0), NightLights.STEPS, "midnight")
equal(NightLights.step(18), NightLights.STEPS / 2, "dusk")
local steps: { [number]: boolean } = {}
for minute = 0, 24 * 60 - 1 do
	local step = NightLights.step(minute / 60)
	check(step == math.floor(step) and step >= 0 and step <= NightLights.STEPS, "step range")
	steps[step] = true
end
for step = 0, NightLights.STEPS do
	check(steps[step] == true, "step " .. step .. " occurs in a day")
	equal(NightLights.levelAt(step) * NightLights.STEPS, step, "levelAt " .. step)
end

Check.section("glowColor")
local warm = Color3.fromRGB(255, 196, 128)
check(NightLights.glowColor(warm, 1) == warm, "level 1 is the built colour")
check(NightLights.glowColor(warm, 2) == warm, "level clamps above 1")
check(NightLights.glowColor(warm, 0) == Color3.new(0, 0, 0), "level 0 is black")
check(NightLights.glowColor(warm, -1) == Color3.new(0, 0, 0), "level clamps below 0")
check(near(NightLights.glowColor(warm, 0.5).R, warm.R / 2), "half way")

Check.section("lamp plans")
local road = NightLights.roadLamps()
local lobby = NightLights.lobbyLamps()
local roadLit = 0
for _, lamp in road do
	roadLit += if lamp.lit then 1 else 0
end
-- Counts at this commit.
equal(#road, 111, "road lamps")
equal(roadLit, 35, "lit road lamps")
equal(#lobby, 2 * #Config.REGIONS, "lobby lamps")
check(
	#lobby + roadLit <= NightLights.MAX_LIGHTS,
	("%d lit lamps fit under MAX_LIGHTS %d"):format(#lobby + roadLit, NightLights.MAX_LIGHTS)
)

-- The roads world/Roads lays at this commit (rings as its 48- and 80-sided polygons), as
-- centre-line segments with half widths; `edge` is Roads.distanceTo's formula.
type Segment = { a: Vector2, b: Vector2, halfWidth: number }
local ROADS: { Segment } = {}
local function addSegment(a: Vector3, b: Vector3, width: number)
	table.insert(
		ROADS,
		{ a = Vector2.new(a.X, a.Z), b = Vector2.new(b.X, b.Z), halfWidth = width / 2 }
	)
end
for _, ring in { { Config.INNER_ROAD_RADIUS, 48 }, { Config.OUTER_ROAD_RADIUS, 80 } } do
	for index = 0, ring[2] - 1 do
		addSegment(
			Config.pointAt(index / ring[2] * 2 * math.pi, ring[1]),
			Config.pointAt((index + 1) / ring[2] * 2 * math.pi, ring[1]),
			24
		)
	end
end
for index = 1, #Config.REGIONS do
	local angle = Config.regionAngle(index)
	addSegment(
		Config.pointAt(angle, Config.LOBBY_RADIUS + 2),
		Config.pointAt(angle, Config.SPOKE_END_RADIUS),
		22
	)
	local between = Config.betweenRegions(index)
	addSegment(
		Config.pointAt(between, Config.INNER_ROAD_RADIUS),
		Config.pointAt(between, Config.OUTER_ROAD_RADIUS),
		22
	)
end
-- Flat distances from `p` to the nearest centre line and the nearest road edge.
local function roadDistances(p: Vector3): (number, number)
	local flat = Vector2.new(p.X, p.Z)
	local line, edge = math.huge, math.huge
	for _, segment in ROADS do
		local ab = segment.b - segment.a
		local t = math.clamp((flat - segment.a):Dot(ab) / ab:Dot(ab), 0, 1)
		local d = (flat - (segment.a + ab * t)).Magnitude
		line = math.min(line, d)
		edge = math.min(edge, d - segment.halfWidth)
	end
	return line, edge
end

for label, lamps in { road = road, lobby = lobby } do
	local offset = if label == "road" then NightLights.ROADSIDE else NightLights.LOBBY_LAMP_ACROSS
	for index, lamp in lamps do
		local p = lamp.position
		local name = ("%s lamp %d at %s"):format(label, index, tostring(p))
		check(p.Y == 0, name .. " stands on the ground")
		check(near(lamp.toward.Magnitude, 1) and lamp.toward.Y == 0, name .. " faces flat")
		local line, edge = roadDistances(p)
		-- A ring polygon's edge sits up to 0.6 inside its circle.
		check(
			line >= NightLights.ROAD_CLEAR - 0.6,
			("%s clears every road: %.2f"):format(name, line)
		)
		check(edge > 1, name .. " is off the asphalt (Lamps keeps it)")
		local lit = roadDistances(p + lamp.toward * offset)
		check(lit < 0.6, ("%s faces a road %.2f studs away"):format(name, offset))
		if label == "road" then
			local radius = Vector2.new(p.X, p.Z).Magnitude
			check(radius >= Config.LOBBY_RADIUS + NightLights.LOBBY_APRON, name .. " off the apron")
			check(not Config.isInParking(p), name .. " out of the motor pools")
			local _, landmark = Config.nearestRegion(p)
			check(landmark >= NightLights.LANDMARK_CLEARANCE, name .. " out of the clearings")
		end
	end
end

Check.section("pick")
-- A Random stand-in answering from a list, counting draws.
local function scripted(answers: { number })
	local fake = { draws = 0 }
	function fake:NextInteger(low: number, high: number): number
		self.draws += 1
		local answer = answers[self.draws] or low
		assert(answer >= low and answer <= high, "scripted answer out of range")
		return answer
	end
	return fake
end
local random = scripted({ 3, 3, 1, 5, 1, 2 })
local picked = NightLights.pick(random, 5, 3)
equal(table.concat(picked, " "), "3 1 5", "distinct, in draw order")
equal(random.draws, 4, "a repeat costs a draw")
random = scripted({ 1, 2, 1, 2 })
picked = NightLights.pick(random, 2, 5)
equal(#picked, 2, "fewer than count when the list is short")
random = scripted({})
equal(#NightLights.pick(random, 0, 24), 0, "an empty list picks nothing")
equal(random.draws, 0, "and draws nothing")
random = scripted({ 1, 1, 1, 1, 1, 1, 1, 1 })
picked = NightLights.pick(random, 9, 2)
equal(#picked, 1, "gives up after count * 4 draws")
equal(random.draws, 8, "count * 4 draws")

Check.finish()
