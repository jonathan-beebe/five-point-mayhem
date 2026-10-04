-- Frying Pan: pre-seasoned 10.25-inch cast-iron skillet (unbranded American foundry style).

local WeaponModel = require(script.Parent.Parent.systems.WeaponModel)

local rgb = Color3.fromRGB
local M = Enum.Material
local CYLINDER_Y = WeaponModel.CYLINDER_Y
local CYL = Enum.PartType.Cylinder

local castIron = rgb(40, 40, 45)
local seasoned = rgb(26, 25, 25)
local wornEdge = rgb(62, 61, 63)
local bottomIron = rgb(47, 46, 48)

-- Pan centre. The pan axis is X: the cooking surface opens toward +X, the bottom faces -X.
local P = CFrame.new(0, 0, -3.6)
local WALL_SLANT = CFrame.Angles(0, math.rad(-26.57), 0) -- 0.30 outward flare over 0.60 depth

local function rx(radians: number): CFrame
	return CFrame.Angles(radians, 0, 0)
end

local pieces: { WeaponModel.PieceSpec } = {
	-- Pan body: bottom disc, underside heat-ring step, seasoned cooking floor
	{
		name = "BottomDisc",
		shape = CYL,
		size = Vector3.new(0.1, 2.36, 2.36),
		offset = CFrame.new(-0.35, 0, -3.6),
		color = bottomIron,
		material = M.Metal,
	},
	{
		name = "HeatStep",
		shape = CYL,
		size = Vector3.new(0.03, 2.1, 2.1),
		offset = CFrame.new(-0.405, 0, -3.6),
		color = bottomIron,
		material = M.Metal,
	},
	{
		name = "CookingFloor",
		shape = CYL,
		size = Vector3.new(0.03, 2.3, 2.3),
		offset = CFrame.new(-0.295, 0, -3.6),
		color = seasoned,
		material = M.Metal,
		reflectance = 0.08,
	},

	-- Pour spouts, perpendicular to the handle (world -Y and +Y)
	{
		name = "Spout_R",
		size = Vector3.new(0.24, 0.42, 0.06),
		offset = P
			* rx(math.rad(90))
			* CFrame.new(0.23, 0, 1.53)
			* CFrame.Angles(0, math.rad(-50), 0),
		color = wornEdge,
		material = M.Metal,
		reflectance = 0.05,
	},
	{
		name = "Spout_L",
		size = Vector3.new(0.24, 0.42, 0.06),
		offset = P
			* rx(math.rad(270))
			* CFrame.new(0.23, 0, 1.53)
			* CFrame.Angles(0, math.rad(-50), 0),
		color = wornEdge,
		material = M.Metal,
		reflectance = 0.05,
	},

	-- Main handle: root against the wall, U-channel grip beam, hang hole, rounded tail
	{
		name = "HandleRoot",
		size = Vector3.new(0.22, 0.52, 0.335),
		offset = CFrame.new(0.04, 0, -2.0675),
		color = castIron,
		material = M.Metal,
	},
	{
		name = "RootFlank_R",
		class = "WedgePart",
		size = Vector3.new(0.2, 0.07, 0.4),
		offset = CFrame.new(0.04, 0.225, -1.7) * CFrame.Angles(0, math.pi, 0),
		color = castIron,
		material = M.Metal,
	},
	{
		name = "RootFlank_L",
		class = "WedgePart",
		size = Vector3.new(0.2, 0.07, 0.4),
		offset = CFrame.new(0.04, -0.225, -1.7) * rx(math.pi),
		color = castIron,
		material = M.Metal,
	},
	{
		name = "GripTop",
		size = Vector3.new(0.08, 0.38, 2.15),
		offset = CFrame.new(0.11, 0, -0.825),
		color = castIron,
		material = M.Metal,
	},
	{
		name = "GripFlange_R",
		size = Vector3.new(0.14, 0.05, 2.15),
		offset = CFrame.new(0.01, 0.155, -0.825),
		color = castIron,
		material = M.Metal,
	},
	{
		name = "GripFlange_L",
		size = Vector3.new(0.14, 0.05, 2.15),
		offset = CFrame.new(0.01, -0.155, -0.825),
		color = castIron,
		material = M.Metal,
	},
	{
		name = "EdgeBead_R",
		size = Vector3.new(0.02, 0.04, 2.05),
		offset = CFrame.new(0.16, 0.17, -0.825),
		color = castIron,
		material = M.Metal,
	},
	{
		name = "EdgeBead_L",
		size = Vector3.new(0.02, 0.04, 2.05),
		offset = CFrame.new(0.16, -0.17, -0.825),
		color = castIron,
		material = M.Metal,
	},
	{
		name = "HangRail_R",
		size = Vector3.new(0.21, 0.09, 0.49),
		offset = CFrame.new(0.045, 0.145, 0.495),
		color = castIron,
		material = M.Metal,
	},
	{
		name = "HangRail_L",
		size = Vector3.new(0.21, 0.09, 0.49),
		offset = CFrame.new(0.045, -0.145, 0.495),
		color = castIron,
		material = M.Metal,
	},
	{
		name = "HandleEndCap",
		shape = CYL,
		size = Vector3.new(0.19, 0.38, 0.38),
		offset = CFrame.new(0.045, 0, 0.74),
		color = castIron,
		material = M.Metal,
	},

	-- Helper lug opposite the handle, with an underside finger lip
	{
		name = "LugShoulder",
		size = Vector3.new(0.12, 0.6, 0.13),
		offset = CFrame.new(0.13, 0, -5.065),
		color = castIron,
		material = M.Metal,
	},
	{
		name = "LugPlate",
		size = Vector3.new(0.12, 0.36, 0.23),
		offset = CFrame.new(0.13, 0, -5.245),
		color = castIron,
		material = M.Metal,
	},
	{
		name = "LugCorner_R",
		shape = CYL,
		size = Vector3.new(0.1, 0.24, 0.24),
		offset = CFrame.new(0.13, 0.18, -5.24),
		color = castIron,
		material = M.Metal,
	},
	{
		name = "LugCorner_L",
		shape = CYL,
		size = Vector3.new(0.1, 0.24, 0.24),
		offset = CFrame.new(0.13, -0.18, -5.24),
		color = castIron,
		material = M.Metal,
	},
	{
		name = "LugLip",
		size = Vector3.new(0.1, 0.36, 0.07),
		offset = CFrame.new(0.025, 0, -5.32),
		color = castIron,
		material = M.Metal,
	},
}

-- Side walls and rounded rim lip: 20 segments around the pan axis, segment 0 toward the handle (+Z)
for i = 0, 19 do
	local t = P * rx(math.rad(18 * i))
	table.insert(pieces, {
		name = string.format("Wall_%02d", i),
		size = Vector3.new(0.68, 0.47, 0.1),
		offset = t * CFrame.new(-0.08, 0, 1.305) * WALL_SLANT,
		color = castIron,
		material = M.Metal,
	})
	table.insert(pieces, {
		name = string.format("Rim_%02d", i),
		shape = CYL,
		size = Vector3.new(0.5, 0.13, 0.13),
		offset = t * CFrame.new(0.22, 0, 1.455) * CYLINDER_Y,
		color = wornEdge,
		material = M.Metal,
		reflectance = 0.05,
	})
end

return WeaponModel.define({
	-- Held upright: the pan (-Z) stands up from the fist and the cooking surface (-Y) faces the
	-- target, so the downward swing lands flat side first.
	hold = "upright",
	-- Roll about the handle: the cooking surface (built facing +X) faces -Y.
	rotation = CFrame.Angles(0, 0, -math.pi / 2),
	handle = {
		size = Vector3.new(0.2, 0.36, 1.2),
		color = castIron,
		material = M.Metal,
		transparency = 1,
	},
	pieces = pieces,
})
