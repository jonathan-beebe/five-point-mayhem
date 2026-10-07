-- Frost Palace (Russia): a three-story red-brick palace with white trim, onion-domed towers in
-- bright colors, a grand arched entrance, giant nesting dolls, and snowmen in the snow.

local Build = require(script.Parent.Parent.Build)

local Palace = {}

local rgb = Color3.fromRGB
local M = Enum.Material
local BRICK = rgb(170, 55, 45)
local WHITE = rgb(240, 240, 235)
local GOLD = rgb(235, 190, 60)
local DOMES = { rgb(40, 110, 200), rgb(40, 160, 90), GOLD, rgb(220, 60, 60), rgb(250, 250, 250) }

local WIDTH, DEPTH = 110, 70
local FLOORS, FLOOR_HEIGHT = 3, 16

-- Cylinder tower with an onion dome, standing on `base`.
local function domeTower(
	parent: Instance,
	base: CFrame,
	diameter: number,
	height: number,
	domeColor: Color3
)
	Build.column(parent, base * CFrame.new(0, height / 2, 0), height, diameter, BRICK, M.Brick)
	for band = 1, 3 do
		Build.column(
			parent,
			base * CFrame.new(0, height * band / 4, 0),
			1,
			diameter + 0.6,
			WHITE,
			M.Concrete
		)
	end
	Build.column(parent, base * CFrame.new(0, height + 1, 0), 2, diameter + 1.5, WHITE, M.Concrete)
	-- The onion: a fat ball, a narrower ball above, and a gold spire.
	local domeDiameter = diameter * 1.35
	Build.ball(
		parent,
		(base * CFrame.new(0, height + domeDiameter * 0.45, 0)).Position,
		domeDiameter,
		domeColor,
		M.SmoothPlastic
	)
	Build.ball(
		parent,
		(base * CFrame.new(0, height + domeDiameter * 0.85, 0)).Position,
		domeDiameter * 0.55,
		domeColor,
		M.SmoothPlastic
	)
	Build.ball(
		parent,
		(base * CFrame.new(0, height + domeDiameter * 1.08, 0)).Position,
		domeDiameter * 0.25,
		domeColor,
		M.SmoothPlastic
	)
	Build.column(
		parent,
		base * CFrame.new(0, height + domeDiameter * 1.2 + 3, 0),
		7,
		0.6,
		GOLD,
		M.Foil
	)
	Build.ball(
		parent,
		(base * CFrame.new(0, height + domeDiameter * 1.2 + 6.8, 0)).Position,
		1.4,
		GOLD,
		M.Foil
	)
	Build.part(
		parent,
		Vector3.new(3.4, 0.4, 0.4),
		base * CFrame.new(0, height + domeDiameter * 1.2 + 4.5, 0),
		GOLD,
		M.Foil
	)
end

local function nestingDoll(parent: Instance, base: CFrame, scale: number, color: Color3)
	Build.ball(
		parent,
		(base * CFrame.new(0, 5 * scale, 0)).Position,
		10 * scale,
		color,
		M.SmoothPlastic
	)
	Build.ball(
		parent,
		(base * CFrame.new(0, 11.5 * scale, 0)).Position,
		7 * scale,
		color,
		M.SmoothPlastic
	)
	Build.column(
		parent,
		base * CFrame.new(0, 11.5 * scale, -3.2 * scale) * CFrame.Angles(math.rad(90), 0, 0),
		0.4,
		4.6 * scale,
		rgb(255, 225, 200),
		M.SmoothPlastic
	)
	for _, side in { -1, 1 } do
		Build.ball(
			parent,
			(base * CFrame.new(side * 0.8 * scale, 12 * scale, -3.5 * scale)).Position,
			0.6 * scale,
			rgb(30, 30, 40),
			M.SmoothPlastic
		)
		Build.ball(
			parent,
			(base * CFrame.new(side * 1.3 * scale, 10.9 * scale, -3.4 * scale)).Position,
			0.8 * scale,
			rgb(255, 120, 130),
			M.SmoothPlastic
		)
	end
	Build.column(
		parent,
		base * CFrame.new(0, 5 * scale, -4.4 * scale) * CFrame.Angles(math.rad(90), 0, 0),
		0.4,
		4 * scale,
		GOLD,
		M.SmoothPlastic
	)
end

-- A lantern hung on a pillar whose face is at `frame`, -Z out of it; lit by night only
-- (Build.nightLight).
local function porchLantern(parent: Instance, frame: CFrame)
	Build.part(parent, Vector3.new(0.4, 0.4, 1.4), frame * CFrame.new(0, 1.4, -0.7), GOLD, M.Metal)
	local lamp = Build.part(
		parent,
		Vector3.new(1.4, 2, 1.4),
		frame * CFrame.new(0, 0, -1.6),
		rgb(255, 210, 150),
		M.Neon,
		{ castShadow = false }
	)
	Build.part(parent, Vector3.new(1.8, 0.4, 1.8), frame * CFrame.new(0, 1.2, -1.6), GOLD, M.Metal)
	local light = Instance.new("PointLight")
	light.Color = rgb(255, 200, 140)
	light.Range = 16
	light.Brightness = 1.2
	light.Parent = lamp
	Build.nightLight(lamp)
end

local function snowman(parent: Instance, base: CFrame)
	Build.ball(parent, (base * CFrame.new(0, 3, 0)).Position, 6, WHITE, M.Snow)
	Build.ball(parent, (base * CFrame.new(0, 7.5, 0)).Position, 4.4, WHITE, M.Snow)
	Build.ball(parent, (base * CFrame.new(0, 10.8, 0)).Position, 3.2, WHITE, M.Snow)
	Build.part(
		parent,
		Vector3.new(0.5, 0.5, 2),
		base * CFrame.new(0, 10.8, -2.2),
		rgb(255, 140, 30),
		M.SmoothPlastic
	)
	Build.column(parent, base * CFrame.new(0, 12.8, 0), 2, 2.4, rgb(30, 30, 30), M.Fabric)
	Build.column(parent, base * CFrame.new(0, 12.3, 0), 0.3, 3.6, rgb(30, 30, 30), M.Fabric)
end

function Palace.build(parent: Instance, base: CFrame): Model
	local model = Build.model("FrostPalace", parent)

	-- Snowy forecourt.
	Build.part(
		model,
		Vector3.new(170, 0.6, 140),
		base * CFrame.new(0, 0.3, -15),
		rgb(235, 240, 245),
		M.Snow
	)

	local hallBase = base * CFrame.new(0, 0.6, 0)
	local hall = Build.storyBuilding(model, hallBase, {
		width = WIDTH,
		depth = DEPTH,
		floors = FLOORS,
		floorHeight = FLOOR_HEIGHT,
		wallColor = BRICK,
		wallMaterial = M.Brick,
		floorColor = rgb(150, 110, 75),
		floorMaterial = M.WoodPlanks,
		stairColor = rgb(200, 200, 200),
		trimColor = WHITE,
		trimMaterial = M.Concrete,
		windowWidth = 5,
		windowHeight = 8,
		windowSpacing = 11,
		doorWidth = 14,
		doorHeight = 13,
		sideDoors = true,
		parapet = 3,
	})

	-- Grand arched entrance porch.
	for _, side in { -1, 1 } do
		Build.part(
			model,
			Vector3.new(4, 18, 4),
			hallBase * CFrame.new(side * 10, 9, -DEPTH / 2 - 8),
			WHITE,
			M.Concrete
		)
		porchLantern(model, hallBase * CFrame.new(side * 10, 12, -DEPTH / 2 - 10))
	end
	Build.part(
		model,
		Vector3.new(26, 3, 12),
		hallBase * CFrame.new(0, 19.5, -DEPTH / 2 - 6),
		WHITE,
		M.Concrete
	)
	Build.wedge(
		model,
		Vector3.new(26, 6, 6),
		hallBase * CFrame.new(0, 24, -DEPTH / 2 - 9),
		BRICK,
		M.Brick
	)
	Build.wedge(
		model,
		Vector3.new(26, 6, 6),
		hallBase * CFrame.new(0, 24, -DEPTH / 2 - 3) * CFrame.Angles(0, math.pi, 0),
		BRICK,
		M.Brick
	)

	-- Onion-domed towers on the roof, kept forward of the stair hole along the back wall.
	local roof = hallBase * CFrame.new(0, hall.roofTop, 0)
	domeTower(model, roof * CFrame.new(0, 0, -8), 22, 30, DOMES[3])
	domeTower(model, roof * CFrame.new(-38, 0, -18), 14, 18, DOMES[1])
	domeTower(model, roof * CFrame.new(38, 0, -18), 14, 18, DOMES[2])
	domeTower(model, roof * CFrame.new(-38, 0, 12), 12, 14, DOMES[4])
	domeTower(model, roof * CFrame.new(38, 0, 12), 12, 14, DOMES[5])
	-- Ground-level corner towers.
	for _, corner in
		{ Vector2.new(-1, -1), Vector2.new(1, -1), Vector2.new(-1, 1), Vector2.new(1, 1) }
	do
		domeTower(
			model,
			hallBase * CFrame.new(corner.X * (WIDTH / 2 + 4), 0, corner.Y * (DEPTH / 2 + 4)),
			12,
			hall.roofTop + 8,
			DOMES[(corner.X + corner.Y + 4) % 5 + 1]
		)
	end

	-- Forecourt decorations.
	nestingDoll(model, base * CFrame.new(-40, 0.6, -70), 1.6, rgb(220, 40, 40))
	nestingDoll(model, base * CFrame.new(-28, 0.6, -72), 1.2, rgb(40, 110, 200))
	nestingDoll(model, base * CFrame.new(-19, 0.6, -73), 0.8, rgb(250, 200, 40))
	snowman(model, base * CFrame.new(35, 0.6, -70))
	snowman(model, base * CFrame.new(50, 0.6, -60) * CFrame.Angles(0, 0.5, 0))
	return model
end

return Palace
