-- Tridevyatoe's gate: two ice towers banded in Khokhloma red and gold under gold and teal onion
-- domes, stained with tide lines from the rising water, a red timber lintel with the world's name
-- under a kokoshnik arch, log palisade wings, and the Three Bogatyrs standing in meltwater. The
-- door is a pair of plank doors painted with red and gold diamonds, swinging in toward the world.

local Build = require(script.Parent.Parent.Build)
local Gate = require(script.Parent.Gate)

local Tridevyatoe = {}

local rgb = Color3.fromRGB
local M = Enum.Material
local ICE = rgb(170, 215, 230)
local RED = rgb(181, 40, 30)
local GOLD = rgb(230, 180, 60)
local BLACK = rgb(30, 26, 24)
local TEAL = rgb(31, 143, 138)
local TIMBER = rgb(106, 74, 52)
local LOG = rgb(120, 88, 62)
local TIDE = rgb(60, 80, 84)
local STONE = rgb(150, 155, 160)
local WATER = rgb(63, 160, 208)

local W, H = Gate.WIDTH, Gate.HEIGHT
local TOWER, TOWER_HEIGHT = 18, 86

local function onionDome(parent: Instance, base: CFrame, color: Color3)
	Build.column(parent, base * CFrame.new(0, 3, 0), 6, 12, RED, M.Wood)
	Build.ball(parent, (base * CFrame.new(0, 13, 0)).Position, 20, color, M.Foil)
	Build.ball(parent, (base * CFrame.new(0, 21, 0)).Position, 11, color, M.Foil)
	Build.ball(parent, (base * CFrame.new(0, 26, 0)).Position, 5, color, M.Foil)
	Build.column(parent, base * CFrame.new(0, 33, 0), 10, 1, GOLD, M.Metal)
	Build.part(parent, Vector3.new(6, 0.8, 0.8), base * CFrame.new(0, 35, 0), GOLD, M.Metal)
end

-- A bogatyr on horseback, carved in stone, a tide line across his horse's chest.
local function bogatyr(parent: Instance, base: CFrame, helmetColor: Color3)
	Build.part(parent, Vector3.new(6, 7, 15), base * CFrame.new(0, 11, 0), STONE, M.Slate)
	for _, x in { -2, 2 } do
		for _, z in { -5.5, 5.5 } do
			Build.part(parent, Vector3.new(1.6, 8, 1.6), base * CFrame.new(x, 4, z), STONE, M.Slate)
		end
	end
	Build.part(
		parent,
		Vector3.new(3.6, 8, 4),
		base * CFrame.new(0, 16, -8) * CFrame.Angles(math.rad(-30), 0, 0),
		STONE,
		M.Slate
	)
	Build.part(parent, Vector3.new(3, 3, 6), base * CFrame.new(0, 19, -11), STONE, M.Slate)
	Build.part(parent, Vector3.new(5, 7, 4), base * CFrame.new(0, 18, 1), STONE, M.Slate)
	Build.part(parent, Vector3.new(3, 3, 3), base * CFrame.new(0, 23, 1), STONE, M.Slate)
	Build.part(parent, Vector3.new(2.6, 3, 2.6), base * CFrame.new(0, 25.6, 1), helmetColor, M.Foil)
	Build.part(
		parent,
		Vector3.new(0.6, 5, 5),
		base * CFrame.new(-3, 18, 1) * CFrame.Angles(0, 0, 0),
		RED,
		M.Wood,
		{ shape = Enum.PartType.Cylinder }
	)
	Build.part(parent, Vector3.new(0.6, 22, 0.6), base * CFrame.new(3, 22, -1), TIMBER, M.Wood)
	Build.part(parent, Vector3.new(6.4, 0.6, 15.4), base * CFrame.new(0, 10, 0), TIDE, M.Slate)
end

-- One door leaf: planks with a gold frame and red diamonds, hinged at its outer edge.
local function leaf(parent: Instance, hinge: CFrame, side: number): { BasePart }
	local width = W / 2
	local parts = {}
	local function add(part: BasePart)
		table.insert(parts, part)
	end
	local center = hinge * CFrame.new(-side * width / 2, 0, 0)
	add(
		Build.part(
			parent,
			Vector3.new(width, H, 2.4),
			center * CFrame.new(0, H / 2, 0),
			TIMBER,
			M.WoodPlanks
		)
	)
	for _, y in { 2, H - 2 } do
		add(
			Build.part(
				parent,
				Vector3.new(width, 1.6, 2.8),
				center * CFrame.new(0, y, 0),
				GOLD,
				M.Wood
			)
		)
	end
	for _, y in { H * 0.3, H * 0.65 } do
		add(
			Build.part(
				parent,
				Vector3.new(9, 9, 0.4),
				center * CFrame.new(0, y, -1.4) * CFrame.Angles(0, 0, math.rad(45)),
				RED,
				M.Wood
			)
		)
		add(
			Build.part(
				parent,
				Vector3.new(4.5, 4.5, 0.5),
				center * CFrame.new(0, y, -1.5) * CFrame.Angles(0, 0, math.rad(45)),
				GOLD,
				M.Wood
			)
		)
	end
	return parts
end

function Tridevyatoe.build(parent: Instance, base: CFrame): Model
	local model = Gate.model("Tridevyatoe Gate", parent)
	local towerX = W / 2 + TOWER / 2

	for index, side in { -1, 1 } do
		local foot = base * CFrame.new(side * towerX, 0, 0)
		Build.part(
			model,
			Vector3.new(TOWER, TOWER_HEIGHT, TOWER),
			foot * CFrame.new(0, TOWER_HEIGHT / 2, 0),
			ICE,
			M.Ice
		)
		for _, y in { 30, 60, TOWER_HEIGHT - 2 } do
			Build.part(
				model,
				Vector3.new(TOWER + 1, 3, TOWER + 1),
				foot * CFrame.new(0, y, 0),
				RED,
				M.Wood
			)
			Build.part(
				model,
				Vector3.new(TOWER + 1.4, 0.8, TOWER + 1.4),
				foot * CFrame.new(0, y + 1.9, 0),
				GOLD,
				M.Foil
			)
		end
		-- Tide lines: where the water stood, highest faintest.
		for line, y in { 6, 11, 15 } do
			Build.part(
				model,
				Vector3.new(TOWER + 0.4, 1.2, TOWER + 0.4),
				foot * CFrame.new(0, y, 0),
				TIDE,
				M.Slate,
				{ transparency = 0.2 * (line - 1) }
			)
		end
		onionDome(model, foot * CFrame.new(0, TOWER_HEIGHT, 0), if index == 1 then GOLD else TEAL)
		-- Log palisade wing, sharpened tops.
		local wing = base * CFrame.new(side * (towerX + TOWER / 2 + 17), 0, 2)
		for x = -15, 15, 3 do
			local height = 30 + (x % 2) * 2
			Build.column(model, wing * CFrame.new(x, height / 2, 0), height, 3, LOG, M.Wood)
			Build.part(
				model,
				Vector3.new(2.2, 2.2, 2.2),
				wing * CFrame.new(x, height + 0.6, 0) * CFrame.Angles(0, math.pi / 4, math.pi / 4),
				LOG,
				M.Wood
			)
		end
		Build.part(model, Vector3.new(34, 1.2, 3.4), wing * CFrame.new(0, 6, 0), TIDE, M.Slate)
	end

	-- Red timber lintel, the name, and the kokoshnik arch above.
	local span = W + 2 * TOWER
	Build.part(model, Vector3.new(span, 10, 10), base * CFrame.new(0, H + 5, 0), RED, M.Wood)
	for _, y in { H + 0.6, H + 9.4 } do
		Build.part(
			model,
			Vector3.new(span + 1, 1.2, 10.6),
			base * CFrame.new(0, y, 0),
			GOLD,
			M.Foil
		)
	end
	Gate.plaque(
		model,
		Vector3.new(56, 7, 0.6),
		base * CFrame.new(0, H + 5, -5.3),
		BLACK,
		M.Wood,
		"TRIDEVYATOE",
		GOLD,
		Enum.Font.Garamond
	)
	local facing = CFrame.Angles(0, math.rad(90), 0)
	Build.part(
		model,
		Vector3.new(4, 40, 40),
		base * CFrame.new(0, H + 20, 0) * facing,
		RED,
		M.Wood,
		{ shape = Enum.PartType.Cylinder }
	)
	Build.part(
		model,
		Vector3.new(4.4, 32, 32),
		base * CFrame.new(0, H + 20, 0) * facing,
		GOLD,
		M.Foil,
		{ shape = Enum.PartType.Cylinder }
	)
	Build.part(
		model,
		Vector3.new(4.8, 22, 22),
		base * CFrame.new(0, H + 20, 0) * facing,
		TEAL,
		M.Wood,
		{ shape = Enum.PartType.Cylinder }
	)
	onionDome(model, base * CFrame.new(0, H + 40, 0), GOLD)

	-- The Three Bogatyrs in a meltwater pool before the left wing.
	local pool = base * CFrame.new(-(towerX + TOWER / 2 + 17), 0, -22)
	Build.part(
		model,
		Vector3.new(40, 0.6, 22),
		pool * CFrame.new(0, 0.3, 0),
		WATER,
		M.Glass,
		{ transparency = 0.35, canCollide = false, reflectance = 0.2 }
	)
	for index, x in { -12, 0, 12 } do
		bogatyr(
			model,
			pool * CFrame.new(x, 0, (index == 2) and -3 or 0),
			if index == 2 then GOLD else STONE
		)
	end

	-- The doors: hinged at the towers, swung open 90 degrees in toward the world.
	local leaves = {}
	for _, side in { -1, 1 } do
		local hinge = base * CFrame.new(side * W / 2, 0, 0)
		table.insert(leaves, {
			parts = leaf(model, hinge, side),
			closed = hinge,
			open = hinge * CFrame.Angles(0, side * math.rad(90), 0),
		})
	end
	Gate.door(model, leaves)
	return model
end

return Tridevyatoe
