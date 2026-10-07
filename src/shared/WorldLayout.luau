--!strict
-- Where the five worlds sit past the mountain rim, and the pass cut through the rim to each:
-- pure geometry on Config's region bearings, so Lune can load it. world/Passes and the realm
-- modules in world/realms apply it to terrain; tools/tests/world_layout checks it.
--
--   r 0..1000     the board (Config.WORLD_RADIUS); Landscape's rim reaches r 1430
--   r 1120..1320  the high range's peak centres (Passes); its balls reach r 1500
--   r 1600..2400  a world's floor, centred on its landmark's bearing at r 2000
--   r 900..1600   the pass on each bearing, from the rim's inner foot to the floor's edge
--   r 910         the gate at each pass's mouth (world/gates), front toward the lobby

local Config = require(script.Parent.Config)

local WorldLayout = {}

WorldLayout.WORLD_DISTANCE = 2000
WorldLayout.FLOOR_RADIUS = 400

-- The high range: peak centres between these radii.
WorldLayout.RANGE_INNER = 1120
WorldLayout.RANGE_OUTER = 1320

WorldLayout.PASS_START = 900
WorldLayout.PASS_END = WorldLayout.WORLD_DISTANCE - WorldLayout.FLOOR_RADIUS
WorldLayout.PASS_SEGMENT = 100
-- Overlap between neighbouring segments, so no seam of rock is left between two cuts.
WorldLayout.PASS_OVERLAP = 10

export type Step = { width: number, bottom: number, top: number }

-- The pass's cross-section, widest at the top. The floor step is 72 wide (two Rustbuckets, 22-stud
-- hulls, abreast with room) and 64 high (Heron's cab tops out at 51).
WorldLayout.PASS_PROFILE = {
	{ width = 72, bottom = 0, top = 64 },
	{ width = 150, bottom = 64, top = 160 },
	{ width = 260, bottom = 160, top = 600 },
} :: { Step }

-- Each pass's gate: its centre on the bearing, and the opening every gate leaves clear when
-- open. Heron (cab top 51) walks through; two Rustbuckets (22-stud hulls) pass side by side.
WorldLayout.GATE_RADIUS = WorldLayout.PASS_START + 10
WorldLayout.GATE_OPENING = { width = 56, height = 66 }

-- Scenery is cleared from each pass and round its gate: CLEARING_HALF_WIDTH either side of the
-- bearing, from CLEARING_START out to PASS_END.
WorldLayout.CLEARING_HALF_WIDTH = 90
WorldLayout.CLEARING_START = WorldLayout.GATE_RADIUS - 50

-- A world's bowl walls leave this half-angle open toward the hub, round the pass.
WorldLayout.BOWL_GAP = math.rad(16)

-- Base ground reaches +-OUTER_EXTENT, in 512-stud tiles on the same grid as Landscape's, which
-- covers +-INNER_EXTENT.
WorldLayout.TILE = 512
WorldLayout.INNER_EXTENT = Config.WORLD_RADIUS + 280
WorldLayout.OUTER_EXTENT = WorldLayout.INNER_EXTENT + 3 * WorldLayout.TILE

local function direction(index: number): Vector3
	local angle = Config.regionAngle(index)
	return Vector3.new(math.cos(angle), 0, math.sin(angle))
end

-- World `index`'s floor centre at ground level (y 0).
function WorldLayout.center(index: number): Vector3
	return direction(index) * WorldLayout.WORLD_DISTANCE
end

-- World `index`'s origin: its floor centre, local -Z facing the lobby (as the landmarks).
function WorldLayout.frame(index: number): CFrame
	local center = WorldLayout.center(index)
	return CFrame.lookAt(center, Vector3.zero)
end

-- Pass `index`'s gate at ground level, local -Z facing the lobby, local X across the pass.
function WorldLayout.gateFrame(index: number): CFrame
	local position = direction(index) * WorldLayout.GATE_RADIUS
	return CFrame.lookAt(position, Vector3.zero)
end

-- The index of the pass whose clearing holds `position`, or nil.
function WorldLayout.clearingAt(position: Vector3): number?
	for index = 1, #Config.REGIONS do
		local outward = direction(index)
		local along = position.X * outward.X + position.Z * outward.Z
		local across = position.Z * outward.X - position.X * outward.Z
		if
			along >= WorldLayout.CLEARING_START
			and along <= WorldLayout.PASS_END
			and math.abs(across) <= WorldLayout.CLEARING_HALF_WIDTH
		then
			return index
		end
	end
	return nil
end

export type Segment = { cframe: CFrame, length: number }

-- The pass to world `index` as straight segments at ground level, lobby side first: local -Z
-- points away from the lobby along the bearing, local X across the pass.
function WorldLayout.passSegments(index: number): { Segment }
	local outward = direction(index)
	local segments = {}
	local step = WorldLayout.PASS_SEGMENT
	local radius = WorldLayout.PASS_START + step / 2
	while radius - step / 2 < WorldLayout.PASS_END do
		local position = outward * radius
		table.insert(segments, {
			cframe = CFrame.lookAt(position, position + outward),
			length = step + 2 * WorldLayout.PASS_OVERLAP,
		})
		radius += step
	end
	return segments
end

-- Whether a world-local direction (radians round the floor, 0 toward the lobby) lies in the gap
-- the bowl walls leave for the pass.
function WorldLayout.inBowlGap(localAngle: number): boolean
	local wrapped = (localAngle + math.pi) % (2 * math.pi) - math.pi
	return math.abs(wrapped) < WorldLayout.BOWL_GAP
end

-- Centres of the base ground tiles outside Landscape's square, row by row.
function WorldLayout.outerTiles(): { Vector3 }
	local tiles = {}
	local tile, inner, outer = WorldLayout.TILE, WorldLayout.INNER_EXTENT, WorldLayout.OUTER_EXTENT
	for x = -outer, outer - 1, tile do
		for z = -outer, outer - 1, tile do
			local inside = x >= -inner and x + tile <= inner and z >= -inner and z + tile <= inner
			if not inside then
				table.insert(tiles, Vector3.new(x + tile / 2, 0, z + tile / 2))
			end
		end
	end
	return tiles
end

return WorldLayout
