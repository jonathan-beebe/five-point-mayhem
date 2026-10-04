-- Sakura Hall (Japan): a three-story timber hall on a stone platform, sweeping tiled eaves at
-- every floor, red pillars, a five-tier pagoda on the roof, a torii gate, and stone lanterns.

local Build = require(script.Parent.Parent.Build)

local Pagoda = {}

local rgb = Color3.fromRGB
local M = Enum.Material
local TIMBER = rgb(95, 62, 45)
local FLOOR = rgb(170, 130, 85)
local RED = rgb(190, 35, 30)
local TILE = rgb(55, 60, 75)
local GOLD = rgb(220, 180, 60)
local STONE = rgb(160, 160, 155)

local WIDTH, DEPTH = 100, 70
local FLOORS, FLOOR_HEIGHT = 3, 18
local PLATFORM = 4

-- Tilted roof skirt hanging off all four sides of a w x d footprint at height y.
local function eaves(
	parent: Instance,
	base: CFrame,
	w: number,
	d: number,
	y: number,
	overhang: number
)
	local tilt = math.rad(22)
	local sides = {
		{ CFrame.new(0, y, -d / 2), w + overhang * 2 },
		{ CFrame.new(0, y, d / 2) * CFrame.Angles(0, math.pi, 0), w + overhang * 2 },
		{ CFrame.new(-w / 2, y, 0) * CFrame.Angles(0, math.rad(90), 0), d + overhang * 2 },
		{ CFrame.new(w / 2, y, 0) * CFrame.Angles(0, math.rad(-90), 0), d + overhang * 2 },
	}
	for _, side in sides do
		local edge = base * side[1]
		Build.part(
			parent,
			Vector3.new(side[2], 1, overhang + 1),
			edge * CFrame.Angles(-tilt, 0, 0) * CFrame.new(0, 0, -(overhang + 1) / 2),
			TILE,
			M.Slate
		)
	end
	-- Upturned gold tips at each corner.
	for _, corner in
		{ Vector2.new(-1, -1), Vector2.new(1, -1), Vector2.new(-1, 1), Vector2.new(1, 1) }
	do
		local tip = base
			* CFrame.new(
				corner.X * (w / 2 + overhang),
				y - overhang * math.sin(tilt) + 1,
				corner.Y * (d / 2 + overhang)
			)
		Build.part(
			parent,
			Vector3.new(1.2, 3, 1.2),
			tip * CFrame.Angles(corner.Y * 0.4, 0, -corner.X * 0.4),
			GOLD,
			M.Metal
		)
	end
end

local function lantern(parent: Instance, base: CFrame)
	Build.part(parent, Vector3.new(3, 1, 3), base * CFrame.new(0, 0.5, 0), STONE, M.Concrete)
	Build.part(parent, Vector3.new(1.2, 4, 1.2), base * CFrame.new(0, 3, 0), STONE, M.Concrete)
	local light = Build.part(
		parent,
		Vector3.new(2.4, 2.2, 2.4),
		base * CFrame.new(0, 6.1, 0),
		rgb(255, 200, 120),
		M.Neon
	)
	local glow = Instance.new("PointLight")
	glow.Color = rgb(255, 190, 110)
	glow.Range = 16
	glow.Parent = light
	Build.part(parent, Vector3.new(3.6, 0.8, 3.6), base * CFrame.new(0, 7.6, 0), STONE, M.Concrete)
	Build.part(parent, Vector3.new(1, 1, 1), base * CFrame.new(0, 8.5, 0), STONE, M.Concrete)
end

function Pagoda.build(parent: Instance, base: CFrame): Model
	local model = Build.model("SakuraHall", parent)

	-- Stone platform with steps up at the front.
	Build.part(
		model,
		Vector3.new(WIDTH + 30, PLATFORM, DEPTH + 30),
		base * CFrame.new(0, PLATFORM / 2, 0),
		STONE,
		M.Cobblestone
	)
	Build.stairs(
		model,
		base * CFrame.new(0, 0, -(DEPTH + 30) / 2 - 8) * CFrame.Angles(0, math.rad(-90), 0),
		PLATFORM,
		1,
		2,
		30,
		STONE,
		M.Cobblestone
	)

	local hallBase = base * CFrame.new(0, PLATFORM, 0)
	local hall = Build.storyBuilding(model, hallBase, {
		width = WIDTH,
		depth = DEPTH,
		floors = FLOORS,
		floorHeight = FLOOR_HEIGHT,
		wallColor = TIMBER,
		wallMaterial = M.WoodPlanks,
		floorColor = FLOOR,
		floorMaterial = M.WoodPlanks,
		trimColor = RED,
		trimMaterial = M.Wood,
		windowWidth = 8,
		windowHeight = 8,
		windowSpacing = 14,
		doorWidth = 16,
		doorHeight = 14,
		sideDoors = true,
		parapet = 3,
	})

	-- Red veranda pillars around the ground floor.
	for x = -WIDTH / 2 - 6, WIDTH / 2 + 6, 14 do
		for _, z in { -DEPTH / 2 - 6, DEPTH / 2 + 6 } do
			Build.column(
				model,
				hallBase * CFrame.new(x, FLOOR_HEIGHT / 2, z),
				FLOOR_HEIGHT,
				2.2,
				RED,
				M.Wood
			)
		end
	end
	for floor = 1, FLOORS do
		eaves(model, hallBase, WIDTH, DEPTH, floor * FLOOR_HEIGHT + 2, if floor == 1 then 9 else 6)
	end

	-- Five-tier pagoda crowning the roof.
	local towerBase = hallBase * CFrame.new(0, hall.roofTop, -8)
	local tierY = 0
	for tier = 0, 4 do
		local size = 34 - tier * 5
		local height = 10
		Build.part(
			model,
			Vector3.new(size, height, size),
			towerBase * CFrame.new(0, tierY + height / 2, 0),
			if tier % 2 == 0 then TIMBER else RED,
			M.WoodPlanks
		)
		eaves(model, towerBase, size, size, tierY + height + 1, 5)
		tierY += height + 1.5
	end
	Build.column(model, towerBase * CFrame.new(0, tierY + 10, 0), 20, 1, GOLD, M.Metal)
	for ring = 0, 5 do
		Build.column(
			model,
			towerBase * CFrame.new(0, tierY + 3 + ring * 2.4, 0),
			0.6,
			4 - ring * 0.4,
			GOLD,
			M.Metal
		)
	end

	-- Torii gate over the path.
	local torii = base * CFrame.new(0, 0, -(DEPTH + 30) / 2 - 35)
	for _, side in { -1, 1 } do
		Build.column(model, torii * CFrame.new(side * 16, 16, 0), 32, 3.2, RED, M.Wood)
	end
	Build.part(model, Vector3.new(46, 2.5, 3), torii * CFrame.new(0, 26, 0), RED, M.Wood)
	Build.part(
		model,
		Vector3.new(54, 2.5, 4),
		torii * CFrame.new(0, 32.5, 0),
		rgb(30, 30, 30),
		M.Wood
	)
	for _, side in { -1, 1 } do
		Build.part(
			model,
			Vector3.new(5, 2.5, 4),
			torii * CFrame.new(side * 28, 33.5, 0) * CFrame.Angles(0, 0, side * 0.25),
			rgb(30, 30, 30),
			M.Wood
		)
	end

	-- Lanterns lining the approach, and a koi pond to the side.
	for index = 0, 3 do
		for _, side in { -1, 1 } do
			lantern(model, base * CFrame.new(side * 20, 0, -(DEPTH + 30) / 2 - 10 - index * 14))
		end
	end
	local pond = base * CFrame.new(WIDTH / 2 + 35, 0, -20)
	Build.part(
		model,
		Vector3.new(40, 1, 26),
		pond * CFrame.new(0, 0.3, 0),
		rgb(50, 110, 160),
		M.Glass,
		{ transparency = 0.25, canCollide = false }
	)
	Build.part(model, Vector3.new(42, 0.5, 28), pond * CFrame.new(0, 0.1, 0), STONE, M.Slate)
	for index = 0, 4 do
		Build.part(
			model,
			Vector3.new(1.4, 0.4, 0.7),
			pond
				* CFrame.new(-14 + index * 7, 0.6, (index % 2) * 6 - 3)
				* CFrame.Angles(0, index, 0),
			if index % 2 == 0 then rgb(255, 130, 40) else rgb(255, 255, 255),
			M.SmoothPlastic,
			{ canCollide = false }
		)
	end
	Build.part(
		model,
		Vector3.new(6, 1, 30),
		pond * CFrame.new(0, 3, 0) * CFrame.Angles(0, math.rad(90), 0),
		RED,
		M.Wood
	)
	return model
end

return Pagoda
