-- Checks the worlds' layout past the rim (src/shared/WorldLayout.luau) outside Roblox.
-- Usage: lune run tools/tests/world_layout.luau
--
--   - each world's centre on its landmark's bearing at WORLD_DISTANCE, its frame facing the lobby
--   - floors clear of each other, of Landscape's rim and of the high range; bowl walls inside the
--     base ground
--   - each pass: segments along the bearing, overlapping, covering PASS_START..PASS_END, past the
--     outer road; the profile clears two Rustbuckets abreast and Heron's cab, widening upward
--   - gates: on the bearing inside the pass's mouth, facing the lobby; the opening clears Heron's
--     cab and two Rustbuckets and fits the pass floor
--   - clearingAt: the pass and its gate's surroundings, nothing short of CLEARING_START (past the
--     outer road), nothing to the side, nil at the lobby and the landmarks
--   - inBowlGap: open toward the lobby, closed elsewhere, wrapping
--   - outerTiles: the ring of tiles round Landscape's square, none inside it, no two the same

local roblox = require("@lune/roblox")

local Check = require("../lib/Check")
local Sandbox = require("../lib/Sandbox")

local Vector3 = roblox.Vector3

local check, equal, near = Check.check, Check.equal, Check.isNear

local Config = Sandbox.load("src/shared/Config.luau")
local WorldLayout = Sandbox.load("src/shared/WorldLayout.luau")

-- Reaches of the terrain the layout must clear, from the code that fills it.
-- Landscape: rim centres up to WORLD_RADIUS + 140, back row 120 further, balls up to 170.
local LANDSCAPE_RIM_REACH = Config.WORLD_RADIUS + 140 + 120 + 170
-- Passes.highRange: foot balls up to 180.
local RANGE_REACH = WorldLayout.RANGE_OUTER + 180
-- Basin.carve: walls up to FLOOR_RADIUS + 170 out, balls up to 170.
local BOWL_REACH = WorldLayout.FLOOR_RADIUS + 170 + 170
-- Clearances: two Rustbucket hulls (22) abreast with room; Heron's cab top (51).
local TWO_WALKERS = 60
local TWO_HULLS = 44
local HERON_TOP = 51

local function flat(v): number
	return math.sqrt(v.X * v.X + v.Z * v.Z)
end

Check.section("centres")
for index = 1, #Config.REGIONS do
	local center = WorldLayout.center(index)
	local angle = Config.regionAngle(index)
	-- Vector3 stores single precision.
	check(near(flat(center), WorldLayout.WORLD_DISTANCE, 1e-3), "world " .. index .. " distance")
	local bearing = Vector3.new(math.cos(angle), 0, math.sin(angle))
	check(near(center.Unit:Dot(bearing), 1, 1e-6), "world " .. index .. " on its bearing")
	equal(center.Y, 0, "world " .. index .. " at ground level")
	local frame = WorldLayout.frame(index)
	local toLobby = (Vector3.zero - center).Unit
	check(near(frame.LookVector:Dot(toLobby), 1, 1e-6), "world " .. index .. " -Z faces the lobby")
	check(
		near((frame.Position - center).Magnitude, 0, 1e-6),
		"world " .. index .. " frame at centre"
	)
end

Check.section("clearances")
local floorInner = WorldLayout.WORLD_DISTANCE - WorldLayout.FLOOR_RADIUS
check(floorInner > LANDSCAPE_RIM_REACH, "floors clear Landscape's rim")
check(floorInner > RANGE_REACH, "floors clear the high range")
check(WorldLayout.RANGE_INNER > Config.WORLD_RADIUS, "high range past the board")
for a = 1, #Config.REGIONS do
	local center = WorldLayout.center(a)
	check(
		math.max(math.abs(center.X), math.abs(center.Z)) + BOWL_REACH <= WorldLayout.OUTER_EXTENT,
		"world " .. a .. " bowl inside the base ground"
	)
	for b = a + 1, #Config.REGIONS do
		local gap = (center - WorldLayout.center(b)).Magnitude
		check(gap > 2 * BOWL_REACH, "worlds " .. a .. " and " .. b .. " bowls apart")
	end
end

Check.section("passes")
check(WorldLayout.PASS_START > Config.OUTER_ROAD_RADIUS, "pass starts past the outer road")
equal(WorldLayout.PASS_END, floorInner, "pass ends at the floor's edge")
for index = 1, #Config.REGIONS do
	local segments = WorldLayout.passSegments(index)
	local outward = WorldLayout.center(index).Unit
	local reach = WorldLayout.PASS_START
	for number, segment in segments do
		local position = segment.cframe.Position
		local radius = flat(position)
		local half = segment.length / 2
		local label = "pass " .. index .. " segment " .. number
		check(near(segment.cframe.LookVector:Dot(outward), 1, 1e-6), label .. " faces outward")
		check(near(position.Unit:Dot(outward), 1, 1e-6), label .. " on the bearing")
		equal(position.Y, 0, label .. " at ground level")
		check(radius - half <= reach, label .. " leaves no gap")
		reach = radius + half
	end
	check(reach >= WorldLayout.PASS_END, "pass " .. index .. " reaches the floor")
	equal(#segments, 7, "pass " .. index .. " segment count")
end
local profile = WorldLayout.PASS_PROFILE
check(profile[1].width >= TWO_WALKERS, "floor fits two walkers abreast")
equal(profile[1].bottom, 0, "profile starts at the ground")
check(profile[1].top > HERON_TOP, "floor step clears Heron's cab")
for number = 2, #profile do
	check(profile[number].width > profile[number - 1].width, "step " .. number .. " widens")
	equal(profile[number].bottom, profile[number - 1].top, "step " .. number .. " stacks")
end

Check.section("gates")
local opening = WorldLayout.GATE_OPENING
check(opening.width > TWO_HULLS, "gate opening fits two Rustbuckets")
check(opening.height > HERON_TOP, "gate opening clears Heron's cab")
check(opening.width < profile[1].width, "gate opening inside the pass floor")
check(
	WorldLayout.GATE_RADIUS > WorldLayout.PASS_START
		and WorldLayout.GATE_RADIUS < WorldLayout.PASS_END,
	"gate inside the pass"
)
for index = 1, #Config.REGIONS do
	local frame = WorldLayout.gateFrame(index)
	local outward = WorldLayout.center(index).Unit
	check(near(flat(frame.Position), WorldLayout.GATE_RADIUS, 1e-3), "gate " .. index .. " radius")
	check(near(frame.Position.Unit:Dot(outward), 1, 1e-6), "gate " .. index .. " on the bearing")
	equal(frame.Position.Y, 0, "gate " .. index .. " at ground level")
	check(near(frame.LookVector:Dot(-outward), 1, 1e-6), "gate " .. index .. " faces the lobby")
end

Check.section("clearingAt")
check(WorldLayout.CLEARING_START > Config.OUTER_ROAD_RADIUS + 30, "clearing past the outer road")
check(WorldLayout.clearingAt(Vector3.zero) == nil, "no clearing at the lobby")
for index = 1, #Config.REGIONS do
	local label = "pass " .. index
	check(WorldLayout.clearingAt(Config.regionCenter(index)) == nil, label .. ": landmark kept")
	local gate = WorldLayout.gateFrame(index)
	equal(WorldLayout.clearingAt(gate.Position), index, label .. ": gate")
	local edge = WorldLayout.CLEARING_HALF_WIDTH
	equal(
		WorldLayout.clearingAt(gate:PointToWorldSpace(Vector3.new(edge - 1, 0, -30))),
		index,
		label .. ": wing"
	)
	check(
		WorldLayout.clearingAt(gate:PointToWorldSpace(Vector3.new(edge + 1, 0, 0))) == nil,
		label .. ": side"
	)
	local outward = WorldLayout.center(index).Unit
	equal(WorldLayout.clearingAt(outward * 1500), index, label .. ": deep in the pass")
	check(
		WorldLayout.clearingAt(outward * (WorldLayout.CLEARING_START - 1)) == nil,
		label .. ": short of the clearing"
	)
end

Check.section("inBowlGap")
local gap = WorldLayout.BOWL_GAP
check(WorldLayout.inBowlGap(0), "open toward the lobby")
check(WorldLayout.inBowlGap(gap * 0.99), "open just inside the gap")
check(WorldLayout.inBowlGap(-gap * 0.99), "open just inside the gap, other side")
check(WorldLayout.inBowlGap(2 * math.pi - gap * 0.5), "wraps past a full turn")
check(not WorldLayout.inBowlGap(gap * 1.01), "closed just past the gap")
check(not WorldLayout.inBowlGap(math.pi), "closed away from the lobby")

Check.section("outerTiles")
local tiles = WorldLayout.outerTiles()
local perSide = 2 * WorldLayout.OUTER_EXTENT / WorldLayout.TILE
local innerSide = 2 * WorldLayout.INNER_EXTENT / WorldLayout.TILE
equal(#tiles, perSide * perSide - innerSide * innerSide, "tile count")
local seen = {}
local half = WorldLayout.TILE / 2
for _, tile in tiles do
	local key = tile.X .. "," .. tile.Z
	check(not seen[key], "tile " .. key .. " once")
	seen[key] = true
	local inside = math.abs(tile.X) + half <= WorldLayout.INNER_EXTENT
		and math.abs(tile.Z) + half <= WorldLayout.INNER_EXTENT
	check(not inside, "tile " .. key .. " outside Landscape's square")
	check(
		math.abs(tile.X) + half <= WorldLayout.OUTER_EXTENT
			and math.abs(tile.Z) + half <= WorldLayout.OUTER_EXTENT,
		"tile " .. key .. " inside the outer extent"
	)
end

Check.finish()
