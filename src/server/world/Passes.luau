-- The land between the board and the five worlds: base ground out to WorldLayout.OUTER_EXTENT, a
-- high range of peaks behind Landscape's rim, and a pass cut through both on each landmark's
-- bearing. init.server calls `raise` before the realms build and `cut` after, so no realm's bowl
-- wall blocks a pass, then `clearScenery` to take Landscape's trees and obstacles off each pass
-- and out of its gate's way. Draws from its own Random: Landscape's seeded scenery stays as it
-- was, less what is cleared.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)

local Passes = {}

local M = Enum.Material

local random = Random.new(4242)

-- Peak material by the nearest landmark, as Landscape's rim; snow caps above SNOW_LINE.
local SNOW_LINE = 300
local function rockFor(position: Vector3): Enum.Material
	local id = Config.REGIONS[Config.nearestRegion(position)].id
	if id == "palace" then
		return M.Snow
	elseif id == "pyramid" then
		return M.Sandstone
	end
	return M.Rock
end

local function baseGround(t: Terrain)
	local tile = WorldLayout.TILE
	for _, center in WorldLayout.outerTiles() do
		t:FillBlock(CFrame.new(center.X, -10, center.Z), Vector3.new(tile, 20, tile), M.Grass)
	end
end

-- Each peak is three balls stacked and shrinking, its top near `height`. Four draws per peak.
local function highRange(t: Terrain)
	for degrees = 0, 357, 3 do
		local angle = math.rad(degrees)
		local radius = random:NextNumber(WorldLayout.RANGE_INNER, WorldLayout.RANGE_OUTER)
		local footY = random:NextNumber(-60, -20)
		local base = random:NextNumber(130, 180)
		local height = random:NextNumber(220, 420)
		local foot = Config.pointAt(angle, radius, footY)
		local material = rockFor(foot)
		t:FillBall(foot, base, material)
		for step = 1, 2 do
			local size = base * (1 - 0.3 * step)
			local y = footY + (height - footY - size) * step / 2
			local cap = step == 2 and height > SNOW_LINE
			t:FillBall(Config.pointAt(angle, radius, y), size, if cap then M.Snow else material)
		end
	end
end

function Passes.raise()
	local t = workspace.Terrain
	baseGround(t)
	highRange(t)
end

-- Clears each pass's profile to Air and lays a dirt floor along it.
function Passes.cut()
	local t = workspace.Terrain
	local floorWidth = WorldLayout.PASS_PROFILE[1].width + 8
	for index = 1, #Config.REGIONS do
		for _, segment in WorldLayout.passSegments(index) do
			for _, step in WorldLayout.PASS_PROFILE do
				local height = step.top - step.bottom
				t:FillBlock(
					segment.cframe * CFrame.new(0, step.bottom + height / 2, 0),
					Vector3.new(step.width, height, segment.length),
					M.Air
				)
			end
			t:FillBlock(
				segment.cframe * CFrame.new(0, -4, 0),
				Vector3.new(floorWidth, 8, segment.length),
				M.Ground
			)
		end
	end
end

-- Destroys the trees and obstacles Landscape scattered inside a pass's clearing
-- (WorldLayout.clearingAt).
function Passes.clearScenery(world: Instance)
	local scenery = world:FindFirstChild("Scenery")
	local trees = scenery and scenery:FindFirstChild("Trees")
	local obstacles = scenery and scenery:FindFirstChild("Obstacles")
	if trees then
		for _, tree in trees:GetChildren() do
			if tree:IsA("Model") and WorldLayout.clearingAt(tree:GetPivot().Position) then
				tree:Destroy()
			end
		end
	end
	if obstacles then
		for _, part in obstacles:GetDescendants() do
			if part:IsA("BasePart") and WorldLayout.clearingAt(part.Position) then
				part:Destroy()
			end
		end
	end
end

return Passes
