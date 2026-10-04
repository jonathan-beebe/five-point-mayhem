-- Terrain ground, the mountain rim that bounds the board, and scattered scenery: trees styled
-- for the nearest landmark, rocks, rubble piles, sandbag cover, and explosive barrels.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Build = require(script.Parent.Build)
local Roads = require(script.Parent.Roads)

local Landscape = {}

local rgb = Color3.fromRGB
local M = Enum.Material

-- Ground material around each landmark, by region id.
local GROUND = {
	castle = M.Grass,
	pagoda = M.LeafyGrass,
	tower = M.Pavement,
	pyramid = M.Sand,
	palace = M.Snow,
}

-- Tree style near each landmark, by region id.
local TREES = {
	castle = { "oak", "oak", "birch" },
	pagoda = { "cherry", "cherry", "maple" },
	tower = { "street", "oak" },
	pyramid = { "palm", "palm", "jungle" },
	palace = { "pine", "pine", "birch" },
}

local random = Random.new(1337)

local function terrain()
	local t = workspace.Terrain
	t:Clear()
	-- Ground in tiles: one huge fill can exceed the terrain write limit.
	local extent = Config.WORLD_RADIUS + 280
	for x = -extent, extent - 1, 512 do
		for z = -extent, extent - 1, 512 do
			t:FillBlock(CFrame.new(x + 256, -10, z + 256), Vector3.new(512, 20, 512), M.Grass)
		end
	end
	for index, region in Config.REGIONS do
		local center = Config.regionCenter(index)
		t:FillCylinder(CFrame.new(center.X, -10, center.Z), 20, 175, GROUND[region.id])
	end
	-- A ring of mountains past the edge of the board.
	for degrees = 0, 359, 5 do
		local angle = math.rad(degrees)
		local radius = Config.WORLD_RADIUS + random:NextNumber(60, 140)
		local position = Config.pointAt(angle, radius, random:NextNumber(-40, 10))
		local region = Config.REGIONS[Config.nearestRegion(position)]
		local material = if region.id == "palace"
			then M.Snow
			elseif region.id == "pyramid" then M.Sandstone
			else M.Rock
		t:FillBall(position, random:NextNumber(90, 150), material)
		t:FillBall(
			Config.pointAt(angle, radius + 120, random:NextNumber(0, 60)),
			random:NextNumber(100, 170),
			M.Rock
		)
	end
end

-- Trees ---------------------------------------------------------------------------------------

local function trunk(
	parent: Instance,
	base: Vector3,
	height: number,
	diameter: number,
	color: Color3
)
	Build.column(
		parent,
		CFrame.new(base + Vector3.new(0, height / 2, 0)),
		height,
		diameter,
		color,
		M.Wood
	)
end

local TREE_BUILDERS: { [string]: (Instance, Vector3, number) -> () } = {
	oak = function(parent, base, s)
		trunk(parent, base, 10 * s, 2.2 * s, rgb(105, 75, 50))
		Build.ball(parent, base + Vector3.new(0, 13 * s, 0), 12 * s, rgb(70, 140, 60), M.Grass)
		Build.ball(
			parent,
			base + Vector3.new(3 * s, 11 * s, 2 * s),
			8 * s,
			rgb(80, 155, 65),
			M.Grass
		)
	end,
	birch = function(parent, base, s)
		trunk(parent, base, 14 * s, 1.4 * s, rgb(235, 235, 225))
		Build.ball(parent, base + Vector3.new(0, 15 * s, 0), 8 * s, rgb(150, 200, 80), M.Grass)
	end,
	cherry = function(parent, base, s)
		trunk(parent, base, 8 * s, 1.8 * s, rgb(80, 50, 45))
		Build.ball(parent, base + Vector3.new(0, 10 * s, 0), 11 * s, rgb(255, 180, 210), M.Grass)
		Build.ball(
			parent,
			base + Vector3.new(-3 * s, 9 * s, -2 * s),
			7 * s,
			rgb(255, 160, 200),
			M.Grass
		)
	end,
	maple = function(parent, base, s)
		trunk(parent, base, 8 * s, 1.6 * s, rgb(80, 50, 45))
		Build.ball(parent, base + Vector3.new(0, 10 * s, 0), 10 * s, rgb(210, 60, 40), M.Grass)
	end,
	street = function(parent, base, s)
		trunk(parent, base, 7 * s, 1.2 * s, rgb(90, 70, 55))
		Build.ball(parent, base + Vector3.new(0, 9 * s, 0), 7 * s, rgb(90, 160, 70), M.Grass)
		Build.part(
			parent,
			Vector3.new(6, 1, 6) * s,
			CFrame.new(base + Vector3.new(0, 0.5 * s, 0)),
			rgb(120, 120, 120),
			M.Concrete
		)
	end,
	palm = function(parent, base, s)
		local height = 18 * s
		for index = 0, 5 do
			Build.column(
				parent,
				CFrame.new(base + Vector3.new(index * 0.3 * s, (index + 0.5) * height / 6, 0)),
				height / 6 + 0.2,
				1.5 * s,
				rgb(140, 110, 70),
				M.Wood
			)
		end
		local top = base + Vector3.new(1.8 * s, height, 0)
		for leaf = 0, 5 do
			local angle = leaf / 6 * math.pi * 2
			Build.part(
				parent,
				Vector3.new(2.5 * s, 0.4, 10 * s),
				CFrame.new(top)
					* CFrame.Angles(0, angle, 0)
					* CFrame.Angles(math.rad(25), 0, 0)
					* CFrame.new(0, 0, -5 * s),
				rgb(60, 150, 50),
				M.Grass
			)
		end
	end,
	jungle = function(parent, base, s)
		trunk(parent, base, 16 * s, 2.5 * s, rgb(90, 70, 45))
		Build.ball(parent, base + Vector3.new(0, 18 * s, 0), 14 * s, rgb(40, 110, 40), M.Grass)
		Build.ball(parent, base + Vector3.new(0, 4 * s, 0), 7 * s, rgb(50, 130, 50), M.Grass)
	end,
	pine = function(parent, base, s)
		trunk(parent, base, 6 * s, 1.6 * s, rgb(90, 60, 40))
		for layer = 0, 3 do
			local diameter = (10 - layer * 2.2) * s
			Build.column(
				parent,
				CFrame.new(base + Vector3.new(0, (6 + layer * 4) * s, 0)),
				3.5 * s,
				diameter,
				rgb(40, 90, 50),
				M.Grass
			)
			Build.column(
				parent,
				CFrame.new(base + Vector3.new(0, (7.8 + layer * 4) * s, 0)),
				0.4,
				diameter * 0.8,
				rgb(245, 250, 255),
				M.Snow
			)
		end
	end,
}

-- Obstacles ----------------------------------------------------------------------------------

local function rock(parent: Instance, base: Vector3)
	local grey = random:NextNumber(110, 150)
	for _ = 1, random:NextInteger(1, 3) do
		local size = Vector3.new(
			random:NextNumber(4, 14),
			random:NextNumber(3, 10),
			random:NextNumber(4, 14)
		)
		Build.part(
			parent,
			size,
			CFrame.new(
				base + Vector3.new(random:NextNumber(-4, 4), size.Y / 3, random:NextNumber(-4, 4))
			)
				* CFrame.Angles(
					random:NextNumber(-0.4, 0.4),
					random:NextNumber(0, 6),
					random:NextNumber(-0.4, 0.4)
				),
			rgb(grey, grey, grey - 5),
			M.Slate
		)
	end
end

local function rubble(parent: Instance, base: Vector3)
	local colors = { rgb(150, 145, 140), rgb(170, 90, 70), rgb(120, 115, 110) }
	-- A broken wall chunk with a jagged top.
	local angle = random:NextNumber(0, math.pi)
	local wallBase = CFrame.new(base) * CFrame.Angles(0, angle, 0)
	for column = -3, 3 do
		local height = random:NextNumber(2, 11)
		Build.part(
			parent,
			Vector3.new(2, height, 2),
			wallBase * CFrame.new(column * 2, height / 2, 0),
			colors[2],
			M.Brick
		)
	end
	for _ = 1, random:NextInteger(5, 9) do
		local size = Vector3.new(
			random:NextNumber(1.5, 5),
			random:NextNumber(1, 3),
			random:NextNumber(1.5, 5)
		)
		Build.part(
			parent,
			size,
			CFrame.new(
				base + Vector3.new(random:NextNumber(-8, 8), size.Y / 2, random:NextNumber(-8, 8))
			)
				* CFrame.Angles(
					random:NextNumber(-0.5, 0.5),
					random:NextNumber(0, 6),
					random:NextNumber(-0.5, 0.5)
				),
			colors[random:NextInteger(1, #colors)],
			M.Concrete
		)
	end
end

local function sandbags(parent: Instance, base: Vector3)
	local frame = CFrame.new(base) * CFrame.Angles(0, random:NextNumber(0, math.pi), 0)
	for row = 0, 2 do
		for column = -3, 3 do
			Build.part(
				parent,
				Vector3.new(2.6, 1.2, 1.6),
				frame * CFrame.new(column * 2.4 + (row % 2) * 1.2, 0.6 + row * 1.15, 0),
				rgb(170, 150, 105),
				M.Fabric
			)
		end
	end
end

function Landscape.explosiveBarrel(parent: Instance, cframe: CFrame): Part
	local barrel =
		Build.column(parent, cframe, 4, 3, rgb(200, 40, 30), M.Metal, { name = "ExplosiveBarrel" })
	barrel:SetAttribute("Home", cframe)
	CollectionService:AddTag(barrel, "ExplosiveBarrel")
	return barrel
end

local function crates(parent: Instance, base: Vector3)
	local frame = CFrame.new(base) * CFrame.Angles(0, random:NextNumber(0, math.pi), 0)
	local layout = {
		Vector3.new(0, 2.5, 0),
		Vector3.new(5.2, 2.5, 0),
		Vector3.new(2.6, 7.5, 0),
		Vector3.new(0, 2.5, 5.2),
	}
	for index = 1, random:NextInteger(2, #layout) do
		Build.part(
			parent,
			Vector3.one * 5,
			frame * CFrame.new(layout[index]),
			rgb(165, 125, 75),
			M.WoodPlanks
		)
	end
end

-- Placement -----------------------------------------------------------------------------------

local function isClear(position: Vector3, roadMargin: number): boolean
	local radius = Vector2.new(position.X, position.Z).Magnitude
	if radius < 110 or radius > Config.WORLD_RADIUS - 30 then
		return false
	end
	local _, regionDistance = Config.nearestRegion(position)
	if regionDistance < 145 then
		return false
	end
	return Roads.distanceTo(position) > roadMargin
end

local function scatter(count: number, margin: number, place: (Vector3) -> ())
	local placed, attempts = 0, 0
	while placed < count and attempts < count * 20 do
		attempts += 1
		local angle = random:NextNumber(0, math.pi * 2)
		local radius = math.sqrt(random:NextNumber(0, 1)) * Config.WORLD_RADIUS
		local position = Config.pointAt(angle, radius)
		if isClear(position, margin) then
			place(position)
			placed += 1
		end
	end
end

function Landscape.build(parent: Instance)
	terrain()
	local model = Build.model("Scenery", parent)
	local trees = Build.model("Trees", model)
	local obstacles = Build.model("Obstacles", model)

	scatter(380, 8, function(position)
		local regionIndex, distance = Config.nearestRegion(position)
		local styles = if distance < 320
			then TREES[Config.REGIONS[regionIndex].id]
			else { "oak", "birch", "pine" }
		local style = styles[random:NextInteger(1, #styles)]
		TREE_BUILDERS[style](trees, position, random:NextNumber(0.8, 1.5))
	end)
	scatter(110, 6, function(position)
		rock(obstacles, position)
	end)
	scatter(45, 10, function(position)
		rubble(obstacles, position)
	end)
	scatter(40, 6, function(position)
		sandbags(obstacles, position)
	end)
	scatter(35, 6, function(position)
		crates(obstacles, position)
	end)
	scatter(45, 4, function(position)
		Landscape.explosiveBarrel(obstacles, CFrame.new(position + Vector3.new(0, 2, 0)))
	end)
	return model
end

return Landscape
