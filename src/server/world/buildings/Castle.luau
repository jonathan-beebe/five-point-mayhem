-- Stonehold Castle (England): curtain walls with a walkable rampart, four corner turrets, a
-- gatehouse, a four-story keep, and St George banners.

local Build = require(script.Parent.Parent.Build)

local Castle = {}

local rgb = Color3.fromRGB
local M = Enum.Material
local STONE = rgb(140, 138, 132)
local DARK_STONE = rgb(105, 103, 98)
local WOOD = rgb(110, 75, 45)
local RED = rgb(200, 20, 30)
local WHITE = rgb(245, 245, 240)

local SIZE = 160
local WALL_HEIGHT = 30
local WALL_THICKNESS = 8

local function banner(parent: Instance, frame: CFrame)
	Build.part(parent, Vector3.new(7, 14, 0.3), frame, WHITE, M.Fabric)
	Build.part(parent, Vector3.new(1.6, 14, 0.4), frame, RED, M.Fabric)
	Build.part(parent, Vector3.new(7, 1.6, 0.4), frame * CFrame.new(0, 2, 0), RED, M.Fabric)
end

local function flag(parent: Instance, base: CFrame)
	Build.column(parent, base * CFrame.new(0, 8, 0), 16, 0.5, rgb(60, 60, 60), M.Metal)
	Build.part(parent, Vector3.new(8, 5, 0.2), base * CFrame.new(4.2, 13.5, 0), WHITE, M.Fabric)
	Build.part(parent, Vector3.new(1.2, 5, 0.3), base * CFrame.new(4.2, 13.5, 0), RED, M.Fabric)
	Build.part(parent, Vector3.new(8, 1.2, 0.3), base * CFrame.new(4.2, 13.5, 0), RED, M.Fabric)
end

local function turret(parent: Instance, base: CFrame, diameter: number, height: number)
	Build.column(
		parent,
		base * CFrame.new(0, height / 2, 0),
		height,
		diameter,
		STONE,
		M.Cobblestone
	)
	Build.column(
		parent,
		base * CFrame.new(0, height + 0.25, 0),
		0.5,
		diameter + 1,
		DARK_STONE,
		M.Slate
	)
	local merlons = math.floor(diameter * math.pi / 6)
	for index = 0, merlons - 1 do
		local angle = index / merlons * 2 * math.pi
		local offset = Vector3.new(math.cos(angle), 0, math.sin(angle)) * (diameter / 2 - 1)
		local position = (base * CFrame.new(offset + Vector3.new(0, height + 2.5, 0))).Position
		local center = (base * CFrame.new(0, height + 2.5, 0)).Position
		Build.part(
			parent,
			Vector3.new(3, 4, 2),
			CFrame.lookAt(position, center),
			STONE,
			M.Cobblestone
		)
	end
	flag(parent, base * CFrame.new(0, height, 0))
end

function Castle.build(parent: Instance, base: CFrame): Model
	local model = Build.model("StoneholdCastle", parent)
	local half = SIZE / 2
	local t = WALL_THICKNESS

	-- Courtyard floor.
	Build.part(
		model,
		Vector3.new(SIZE, 0.6, SIZE),
		base * CFrame.new(0, 0.3, 0),
		rgb(150, 140, 120),
		M.Cobblestone
	)

	-- Curtain walls. The front has the main gate; the sides have small postern doors.
	local gate = { x = 0, width = 18, bottom = 0, top = 22 }
	local postern = { x = 0, width = 10, bottom = 0, top = 12 }
	local walls = {
		{ base * CFrame.new(0, 0, -half + t / 2), SIZE, { gate } },
		{ base * CFrame.new(0, 0, half - t / 2) * CFrame.Angles(0, math.pi, 0), SIZE, { postern } },
		{
			base * CFrame.new(-half + t / 2, 0, 0) * CFrame.Angles(0, math.rad(90), 0),
			SIZE - 2 * t,
			{ postern },
		},
		{
			base * CFrame.new(half - t / 2, 0, 0) * CFrame.Angles(0, math.rad(-90), 0),
			SIZE - 2 * t,
			{ postern },
		},
	}
	for _, spec in walls do
		local frame: CFrame = spec[1]
		Build.wall(model, frame, spec[2], WALL_HEIGHT, t, STONE, M.Cobblestone, spec[3])
		-- Battlements along the outer edge of the rampart walk.
		Build.crenellate(
			model,
			frame * CFrame.new(0, WALL_HEIGHT, -t / 2 + 1),
			spec[2] - 16,
			2,
			STONE,
			M.Cobblestone
		)
	end

	-- Corner turrets, level with the rampart so the walk loops all the way around.
	for _, corner in
		{
			Vector3.new(-1, 0, -1),
			Vector3.new(1, 0, -1),
			Vector3.new(-1, 0, 1),
			Vector3.new(1, 0, 1),
		}
	do
		turret(model, base * CFrame.new(corner.X * half, 0, corner.Z * half), 26, WALL_HEIGHT)
	end

	-- Gatehouse: two towers flanking the gate, joined by a bridge over the arch.
	for _, side in { -1, 1 } do
		local tower = base * CFrame.new(side * 17, 0, -half + 2)
		Build.part(
			model,
			Vector3.new(14, 42, 18),
			tower * CFrame.new(0, 21, 0),
			DARK_STONE,
			M.Cobblestone
		)
		Build.crenellate(model, tower * CFrame.new(0, 42, -8), 14, 2, DARK_STONE, M.Cobblestone)
		Build.truss(model, tower * CFrame.new(-side * 8, WALL_HEIGHT, 6), 12, WOOD)
	end
	Build.part(
		model,
		Vector3.new(20, 8, 18),
		base * CFrame.new(0, 38, -half + 2),
		DARK_STONE,
		M.Cobblestone
	)
	-- Raised portcullis.
	for bar = -4, 4 do
		Build.part(
			model,
			Vector3.new(0.6, 6, 0.6),
			base * CFrame.new(bar * 2, 19.5, -half + 4),
			rgb(50, 50, 50),
			M.Metal
		)
	end
	for _, side in { -1, 1 } do
		banner(model, base * CFrame.new(side * 34, 18, -half - 0.3))
	end

	-- Stairs up to the rampart along the inside of the back and front walls.
	Build.stairs(
		model,
		base * CFrame.new(-55, 0.6, half - t - 3),
		30,
		1,
		1.5,
		6,
		DARK_STONE,
		M.Slate
	)
	Build.stairs(
		model,
		base * CFrame.new(70, 0.6, -half + t + 3) * CFrame.Angles(0, math.pi, 0),
		30,
		1,
		1.5,
		6,
		DARK_STONE,
		M.Slate
	)
	for _, side in { -1, 1 } do
		Build.truss(model, base * CFrame.new(side * (half - t - 1), 0, 30), WALL_HEIGHT, WOOD)
	end

	-- The keep.
	local keepBase = base * CFrame.new(0, 0.6, 28)
	local keep = Build.storyBuilding(model, keepBase, {
		width = 72,
		depth = 52,
		floors = 4,
		floorHeight = 16,
		wallColor = rgb(125, 122, 115),
		wallMaterial = M.Cobblestone,
		floorColor = rgb(120, 85, 55),
		floorMaterial = M.WoodPlanks,
		stairColor = DARK_STONE,
		wallThickness = 3,
		windowWidth = 3,
		windowHeight = 6,
		windowSpacing = 10,
		doorWidth = 10,
		sideDoors = true,
		parapet = 0,
	})
	for _, spec in
		{
			{ CFrame.new(0, keep.roofTop, -25), 72 },
			{ CFrame.new(0, keep.roofTop, 25) * CFrame.Angles(0, math.pi, 0), 72 },
			{ CFrame.new(-35, keep.roofTop, 0) * CFrame.Angles(0, math.rad(90), 0), 52 },
			{ CFrame.new(35, keep.roofTop, 0) * CFrame.Angles(0, math.rad(-90), 0), 52 },
		}
	do
		Build.crenellate(model, keepBase * spec[1], spec[2] - 4, 2, STONE, M.Cobblestone)
	end
	for _, corner in
		{
			Vector3.new(-1, 0, -1),
			Vector3.new(1, 0, -1),
			Vector3.new(-1, 0, 1),
			Vector3.new(1, 0, 1),
		}
	do
		local position = keepBase * CFrame.new(corner.X * 36, 0, corner.Z * 26)
		Build.column(
			model,
			position * CFrame.new(0, (keep.roofTop + 12) / 2, 0),
			keep.roofTop + 12,
			10,
			STONE,
			M.Cobblestone
		)
		-- Pointed slate roofs, approximated with stacked cylinders.
		for layer = 0, 4 do
			Build.column(
				model,
				position * CFrame.new(0, keep.roofTop + 13 + layer * 2, 0),
				2,
				12 - layer * 2.4,
				rgb(70, 75, 95),
				M.Slate
			)
		end
	end
	flag(model, keepBase * CFrame.new(0, keep.roofTop, 0))
	banner(model, keepBase * CFrame.new(-20, 40, -26.5))
	banner(model, keepBase * CFrame.new(20, 40, -26.5))

	-- Courtyard props: a well, hay bales, archery targets.
	local well = base * CFrame.new(-35, 0.6, -30)
	Build.column(model, well * CFrame.new(0, 2, 0), 4, 10, STONE, M.Cobblestone)
	Build.column(
		model,
		well * CFrame.new(0, 3.9, 0),
		0.4,
		7,
		rgb(40, 90, 140),
		M.Glass,
		{ canCollide = false }
	)
	for _, side in { -1, 1 } do
		Build.part(
			model,
			Vector3.new(0.8, 9, 0.8),
			well * CFrame.new(side * 4, 4.5, 0),
			WOOD,
			M.Wood
		)
	end
	Build.wedge(
		model,
		Vector3.new(10, 3, 5),
		well * CFrame.new(0, 10.5, -2.5) * CFrame.Angles(0, math.pi, 0),
		rgb(150, 50, 40),
		M.Slate
	)
	Build.wedge(
		model,
		Vector3.new(10, 3, 5),
		well * CFrame.new(0, 10.5, 2.5),
		rgb(150, 50, 40),
		M.Slate
	)
	for index = 0, 5 do
		Build.part(
			model,
			Vector3.new(6, 4, 4),
			base * CFrame.new(40 + (index % 3) * 6.5, 2.6 + math.floor(index / 3) * 4, -40),
			rgb(220, 190, 90),
			M.Grass
		)
	end
	for index = 0, 2 do
		local target = base * CFrame.new(-60 + index * 14, 0.6, -10)
		Build.part(model, Vector3.new(0.6, 6, 0.6), target * CFrame.new(0, 3, 0.5), WOOD, M.Wood)
		for ring = 0, 2 do
			Build.part(
				model,
				Vector3.new(0.3 + ring * 0.1, 6 - ring * 2, 6 - ring * 2),
				target * CFrame.new(0, 7, 0) * CFrame.Angles(0, math.rad(90), 0),
				if ring % 2 == 0 then RED else WHITE,
				M.Fabric,
				{ shape = Enum.PartType.Cylinder }
			)
		end
	end
	return model
end

return Castle
