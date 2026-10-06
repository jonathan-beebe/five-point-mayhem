-- Jaguar Pyramid (Mexico): an eight-tier stepped Mesoamerican pyramid with a grand front
-- staircase guarded by feathered serpents, a treasure chamber inside the base, and a temple on top.

local Build = require(script.Parent.Parent.Build)

local Pyramid = {}

local rgb = Color3.fromRGB
local M = Enum.Material
local LIMESTONE = rgb(205, 190, 150)
local DARK = rgb(165, 150, 115)
local JADE = rgb(50, 160, 110)
local RED = rgb(175, 55, 40)
local GOLD = rgb(240, 195, 60)

local BASE_SIZE = 170
local TIERS = 8
local TIER_HEIGHT = 12
local SHRINK = 18

-- A torch on a post. `nightOnly` lights it by night only (Build.nightLight); the chamber's burn
-- all day.
local function torch(parent: Instance, frame: CFrame, nightOnly: boolean?)
	Build.part(
		parent,
		Vector3.new(0.8, 5, 0.8),
		frame * CFrame.new(0, 2.5, 0),
		rgb(90, 60, 40),
		M.Wood
	)
	local bowl = Build.part(
		parent,
		Vector3.new(1.8, 1, 1.8),
		frame * CFrame.new(0, 5.5, 0),
		rgb(60, 60, 60),
		M.Metal
	)
	local fire = Instance.new("Fire")
	fire.Size = 4
	fire.Heat = 6
	fire.Parent = bowl
	local light = Instance.new("PointLight")
	light.Color = rgb(255, 160, 60)
	light.Range = 24
	light.Brightness = 2
	light.Parent = bowl
	if nightOnly then
		Build.nightLight(bowl)
	end
end

local function serpentHead(parent: Instance, frame: CFrame)
	Build.part(parent, Vector3.new(6, 6, 9), frame * CFrame.new(0, 3, 0), JADE, M.Slate)
	Build.part(parent, Vector3.new(6.2, 1.5, 4), frame * CFrame.new(0, 1.2, -3), RED, M.Slate)
	for _, side in { -1, 1 } do
		Build.part(
			parent,
			Vector3.new(1.2, 1.2, 0.4),
			frame * CFrame.new(side * 1.8, 4.6, -4.6),
			GOLD,
			M.Neon
		)
		Build.part(
			parent,
			Vector3.new(0.6, 1.6, 0.6),
			frame * CFrame.new(side * 1.5, 0.8, -4.2),
			rgb(250, 250, 240),
			M.SmoothPlastic
		)
	end
	Build.wedge(parent, Vector3.new(6, 2, 4), frame * CFrame.new(0, 7, 1), JADE, M.Slate)
end

function Pyramid.build(parent: Instance, base: CFrame): Model
	local model = Build.model("JaguarPyramid", parent)

	-- Tier 0 is a hollow treasure chamber with doors on every face except under the stairs.
	local wall = 6
	local half = BASE_SIZE / 2
	local sideDoor = { x = 0, width = 12, bottom = 0, top = 10 }
	local frontDoors = {
		{ x = -40, width = 10, bottom = 0, top = 10 },
		{ x = 40, width = 10, bottom = 0, top = 10 },
	}
	local walls = {
		{ CFrame.new(0, 0, -half + wall / 2), BASE_SIZE, frontDoors },
		{
			CFrame.new(0, 0, half - wall / 2) * CFrame.Angles(0, math.pi, 0),
			BASE_SIZE,
			{ sideDoor },
		},
		{
			CFrame.new(-half + wall / 2, 0, 0) * CFrame.Angles(0, math.rad(90), 0),
			BASE_SIZE - wall * 2,
			{ sideDoor },
		},
		{
			CFrame.new(half - wall / 2, 0, 0) * CFrame.Angles(0, math.rad(-90), 0),
			BASE_SIZE - wall * 2,
			{ sideDoor },
		},
	}
	for _, spec in walls do
		Build.wall(
			model,
			base * spec[1],
			spec[2],
			TIER_HEIGHT,
			wall,
			LIMESTONE,
			M.Limestone,
			spec[3]
		)
	end
	Build.part(
		model,
		Vector3.new(BASE_SIZE - 2, 0.6, BASE_SIZE - 2),
		base * CFrame.new(0, 0.3, 0),
		DARK,
		M.Sandstone
	)
	Build.ring(
		model,
		base * CFrame.new(0, TIER_HEIGHT - 1.5, 0),
		BASE_SIZE + 0.6,
		BASE_SIZE + 0.6,
		1.5,
		0.4,
		JADE,
		M.Slate
	)

	-- Chamber contents: pillars, torches, and piles of gold.
	for x = -60, 60, 30 do
		for z = -60, 60, 30 do
			if not (x == 0 and z == 0) then
				Build.part(
					model,
					Vector3.new(4, TIER_HEIGHT, 4),
					base * CFrame.new(x, TIER_HEIGHT / 2, z),
					DARK,
					M.Sandstone
				)
			end
		end
	end
	for _, corner in
		{ Vector2.new(-1, -1), Vector2.new(1, -1), Vector2.new(-1, 1), Vector2.new(1, 1) }
	do
		torch(model, base * CFrame.new(corner.X * 15, 0.6, corner.Y * 15))
	end
	local treasure = Random.new(9)
	for _ = 1, 40 do
		local size = treasure:NextNumber(0.8, 2)
		Build.part(
			model,
			Vector3.new(size, size * 0.5, size),
			base
				* CFrame.new(
					treasure:NextNumber(-8, 8),
					0.6 + size * 0.25,
					treasure:NextNumber(-8, 8)
				)
				* CFrame.Angles(0, treasure:NextNumber(0, 3), 0),
			GOLD,
			M.Foil
		)
	end
	Build.part(model, Vector3.new(4, 3, 3), base * CFrame.new(0, 2.1, 0), RED, M.Wood)
	Build.part(model, Vector3.new(4.2, 1, 3.2), base * CFrame.new(0, 4, 0), GOLD, M.Foil)

	-- Solid upper tiers, each trimmed with a band of jade.
	for tier = 1, TIERS - 1 do
		local size = BASE_SIZE - tier * SHRINK
		local y = tier * TIER_HEIGHT
		Build.part(
			model,
			Vector3.new(size, TIER_HEIGHT, size),
			base * CFrame.new(0, y + TIER_HEIGHT / 2, 0),
			if tier % 2 == 0 then LIMESTONE else DARK,
			M.Limestone
		)
		Build.ring(
			model,
			base * CFrame.new(0, y + TIER_HEIGHT - 1.5, 0),
			size + 0.6,
			size + 0.6,
			1.5,
			0.4,
			if tier % 2 == 0 then JADE else RED,
			M.Slate
		)
	end

	-- The grand staircase climbs the front face at 45 degrees.
	local top = TIERS * TIER_HEIGHT
	local topSize = BASE_SIZE - (TIERS - 1) * SHRINK
	local footZ = -topSize / 2 - top
	for step = 1, top do
		local z = footZ + step - 0.5
		-- Inside the base footprint the chamber ceiling carries the stairs, keeping the chamber
		-- open.
		local bottom = if z > -half then TIER_HEIGHT else 0
		Build.part(
			model,
			Vector3.new(16, step - bottom, 1),
			base * CFrame.new(0, (bottom + step) / 2, z),
			rgb(185, 170, 130),
			M.Limestone
		)
	end
	for _, side in { -1, 1 } do
		-- Balustrades with serpent heads at the foot.
		local length = math.sqrt(2) * top
		Build.part(
			model,
			Vector3.new(2, 3, length),
			base
				* CFrame.new(side * 9, top / 2 + 1.5, footZ + top / 2)
				* CFrame.Angles(math.rad(-45), 0, 0),
			JADE,
			M.Slate
		)
		serpentHead(model, base * CFrame.new(side * 9, 0, footZ - 3))
	end

	-- Temple on the summit.
	local summit = base * CFrame.new(0, top, 0)
	local temple = Build.storyBuilding(model, summit, {
		width = 40,
		depth = 30,
		floors = 1,
		floorHeight = 16,
		wallColor = LIMESTONE,
		wallMaterial = M.Limestone,
		floorColor = DARK,
		floorMaterial = M.Sandstone,
		trimColor = RED,
		trimMaterial = M.Slate,
		windowWidth = 3,
		windowHeight = 4,
		windowSpacing = 12,
		doorWidth = 8,
		doorHeight = 11,
		crates = false,
		parapet = 2,
	})
	-- Roof comb: a carved crest along the front of the temple roof.
	Build.part(
		model,
		Vector3.new(30, 12, 2),
		summit * CFrame.new(0, temple.roofTop + 6, -10),
		RED,
		M.Slate
	)
	for x = -12, 12, 6 do
		Build.part(
			model,
			Vector3.new(2.5, 2.5, 2.4),
			summit * CFrame.new(x, temple.roofTop + 8, -10),
			JADE,
			M.Slate
		)
	end
	Build.ball(model, (summit * CFrame.new(0, temple.roofTop + 15, -10)).Position, 5, GOLD, M.Foil)
	for _, side in { -1, 1 } do
		torch(model, summit * CFrame.new(side * 8, 1, -19), true)
	end
	return model
end

return Pyramid
