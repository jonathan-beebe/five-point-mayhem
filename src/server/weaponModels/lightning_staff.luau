-- Lightning Staff: walnut walking staff crowned with an early-1900s plasma globe on a Tesla-coil and porcelain-insulator head.

local WeaponModel = require(script.Parent.Parent.systems.WeaponModel)

local rgb = Color3.fromRGB
local M = Enum.Material
local CY = WeaponModel.CYLINDER_Y
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball
local R = math.rad

-- Rotation about the vertical staff axis; 0 degrees points to +X.
local function spin(degrees: number): CFrame
	return CFrame.Angles(0, R(degrees), 0)
end

local GLOBE = CFrame.new(0, 4.86, 0)

local WALNUT = rgb(92, 60, 38)
local WALNUT_DARK = rgb(66, 42, 26)
local LEATHER = rgb(74, 50, 34)
local LEATHER_DARK = rgb(56, 37, 25)
local STITCH = rgb(140, 118, 84)
local BRASS = rgb(181, 146, 72)
local BRASS_AGED = rgb(128, 100, 52)
local IRON = rgb(46, 46, 48)
local COPPER = rgb(184, 98, 52)
local PHENOLIC = rgb(58, 40, 30)
local PORCELAIN = rgb(226, 220, 204)
local GLASS = rgb(215, 230, 235)
local PLASMA = rgb(255, 255, 120)
local PLASMA_CORE = rgb(255, 255, 200)

local WRAP_RIDGE_SIZE = Vector3.new(0.04, 0.39, 0.39)
local WINDING_SIZE = Vector3.new(0.035, 0.27, 0.27)
local SCREW_SIZE = Vector3.new(0.03, 0.07, 0.07)
local CLAW_SIZE = Vector3.new(0.05, 0.36, 0.08)
local FILAMENT_SIZE = Vector3.new(0.035, 0.035, 0.44)

local pieces: { WeaponModel.PieceSpec } = {
	-- Butt
	{
		name = "ButtCap",
		shape = CYL,
		size = Vector3.new(0.13, 0.30, 0.30),
		offset = CFrame.new(0, -1.435, 0) * CY,
		color = IRON,
		material = M.Metal,
	},
	{
		name = "Ferrule",
		shape = CYL,
		size = Vector3.new(0.32, 0.38, 0.38),
		offset = CFrame.new(0, -1.22, 0) * CY,
		color = BRASS,
		material = M.Metal,
		reflectance = 0.1,
	},

	-- Shaft
	{
		name = "ShaftLower",
		shape = CYL,
		size = Vector3.new(2.98, 0.32, 0.32),
		offset = CFrame.new(0, 0.11, 0) * CY,
		color = WALNUT,
		material = M.Wood,
	},
	{
		name = "ShaftUpper",
		shape = CYL,
		size = Vector3.new(2.15, 0.29, 0.29),
		offset = CFrame.new(0, 2.675, 0) * CY,
		color = WALNUT,
		material = M.Wood,
	},
	{
		name = "TaperBand",
		shape = CYL,
		size = Vector3.new(0.08, 0.36, 0.36),
		offset = CFrame.new(0, 1.60, 0) * CY,
		color = BRASS_AGED,
		material = M.Metal,
	},

	-- Grip
	{
		name = "GripWrap",
		shape = CYL,
		size = Vector3.new(1.32, 0.37, 0.37),
		offset = CY,
		color = LEATHER,
		material = M.Leather,
	},
	{
		name = "GripCollarLow",
		shape = CYL,
		size = Vector3.new(0.08, 0.42, 0.42),
		offset = CFrame.new(0, -0.69, 0) * CY,
		color = BRASS,
		material = M.Metal,
		reflectance = 0.1,
	},
	{
		name = "GripCollarHigh",
		shape = CYL,
		size = Vector3.new(0.08, 0.42, 0.42),
		offset = CFrame.new(0, 0.69, 0) * CY,
		color = BRASS,
		material = M.Metal,
		reflectance = 0.1,
	},
	{
		name = "StitchSeam",
		size = Vector3.new(0.03, 1.30, 0.03),
		offset = CFrame.new(0, 0, 0.18),
		color = STITCH,
		material = M.Fabric,
	},
	{
		name = "LanyardThong",
		size = Vector3.new(0.04, 0.58, 0.04),
		-- Top tucks under GripCollarLow at x 0.20; bottom swings out to the bead at x 0.24.
		offset = CFrame.new(0.22, -0.98, 0) * CFrame.Angles(0, 0, R(4)),
		color = LEATHER_DARK,
		material = M.Leather,
	},
	{
		name = "LanyardBead",
		shape = BALL,
		size = Vector3.new(0.10, 0.10, 0.10),
		offset = CFrame.new(0.24, -1.29, 0),
		color = BRASS_AGED,
		material = M.Metal,
	},

	-- Wood detail
	{
		name = "Knot1",
		shape = BALL,
		size = Vector3.new(0.10, 0.10, 0.10),
		offset = CFrame.new(0.125, 2.30, 0.03),
		color = WALNUT_DARK,
		material = M.Wood,
	},
	{
		name = "Knot2",
		shape = BALL,
		size = Vector3.new(0.09, 0.09, 0.09),
		offset = CFrame.new(-0.11, 3.20, -0.08),
		color = WALNUT_DARK,
		material = M.Wood,
	},

	-- Head collar
	{
		name = "HeadCollar",
		shape = CYL,
		size = Vector3.new(0.22, 0.36, 0.36),
		offset = CFrame.new(0, 3.71, 0) * CY,
		color = BRASS,
		material = M.Metal,
		reflectance = 0.1,
	},
	{
		name = "CollarScrewR",
		shape = CYL,
		size = SCREW_SIZE,
		offset = spin(0) * CFrame.new(0.185, 3.71, 0),
		color = IRON,
		material = M.Metal,
	},
	{
		name = "CollarScrewL",
		shape = CYL,
		size = SCREW_SIZE,
		offset = spin(180) * CFrame.new(0.185, 3.71, 0),
		color = IRON,
		material = M.Metal,
	},

	-- Tesla coil
	{
		name = "CoilFormer",
		shape = CYL,
		size = Vector3.new(0.33, 0.24, 0.24),
		offset = CFrame.new(0, 3.975, 0) * CY,
		color = PHENOLIC,
		material = M.Plastic,
	},

	-- Insulator and cup
	{
		name = "Insulator",
		shape = CYL,
		size = Vector3.new(0.07, 0.48, 0.48),
		offset = CFrame.new(0, 4.165, 0) * CY,
		color = PORCELAIN,
		material = M.SmoothPlastic,
		reflectance = 0.08,
	},
	{
		name = "GlobeCup",
		shape = CYL,
		size = Vector3.new(0.11, 0.56, 0.56),
		offset = CFrame.new(0, 4.245, 0) * CY,
		color = BRASS,
		material = M.Metal,
		reflectance = 0.1,
	},
	{
		name = "CupRim",
		shape = CYL,
		-- Radius 0.33 so the claw bases (inner edge r ~0.31 at Y 4.28) seat on the rim.
		size = Vector3.new(0.04, 0.66, 0.66),
		offset = CFrame.new(0, 4.31, 0) * CY,
		color = BRASS_AGED,
		material = M.Metal,
	},

	-- Plasma globe
	{
		name = "GlobeGlass",
		shape = BALL,
		size = Vector3.new(1.20, 1.20, 1.20),
		offset = GLOBE,
		color = GLASS,
		material = M.Glass,
		transparency = 0.55,
		reflectance = 0.2,
	},
	{
		name = "GlobeHaze",
		shape = BALL,
		size = Vector3.new(1.04, 1.04, 1.04),
		offset = GLOBE,
		color = PLASMA,
		material = M.Neon,
		transparency = 0.88,
	},
	{
		name = "GlassPip",
		shape = CYL,
		size = Vector3.new(0.06, 0.08, 0.08),
		offset = CFrame.new(0, 5.48, 0) * CY,
		color = GLASS,
		material = M.Glass,
		transparency = 0.3,
		reflectance = 0.2,
	},
	{
		name = "ElectrodeStem",
		shape = CYL,
		-- Spans 4.28 (inside the cup) to 4.77 (inside the core).
		size = Vector3.new(0.49, 0.06, 0.06),
		offset = CFrame.new(0, 4.525, 0) * CY,
		color = IRON,
		material = M.Metal,
	},
	{
		name = "PlasmaCore",
		shape = BALL,
		size = Vector3.new(0.22, 0.22, 0.22),
		offset = GLOBE,
		color = PLASMA_CORE,
		material = M.Neon,
	},
}

-- Spiral leather wrap ridges, tilted 8 degrees.
for index, y in { -0.45, -0.15, 0.15, 0.45 } do
	table.insert(pieces, {
		name = `WrapRidge{index}`,
		shape = CYL,
		size = WRAP_RIDGE_SIZE,
		offset = CFrame.new(0, y, 0) * CFrame.Angles(R(8), 0, 0) * CY,
		color = LEATHER_DARK,
		material = M.Leather,
	})
end

-- Copper secondary winding turns, 0.02 gaps show the former.
for index, y in { 3.87, 3.925, 3.98, 4.035, 4.09 } do
	table.insert(pieces, {
		name = `Winding{index}`,
		shape = CYL,
		size = WINDING_SIZE,
		offset = CFrame.new(0, y, 0) * CFrame.Angles(R(4), 0, 0) * CY,
		color = COPPER,
		material = M.Metal,
		reflectance = 0.15,
	})
end

-- Four forged claws: chords of a 0.66-radius arc around the globe center, inner faces 0.6125 from it.
local CLAW_SEGMENTS = {
	{ suffix = "A", r = 0.4508, y = 4.4092, t = -45 },
	{ suffix = "B", r = 0.6158, y = 4.6950, t = -15 },
	{ suffix = "C", r = 0.6158, y = 5.0250, t = 15 },
}
for _, a in { 45, 135, 225, 315 } do
	for _, segment in CLAW_SEGMENTS do
		table.insert(pieces, {
			name = `Claw{segment.suffix}_{a}`,
			size = CLAW_SIZE,
			offset = spin(a)
				* CFrame.new(segment.r, segment.y, 0)
				* CFrame.Angles(0, 0, R(segment.t)),
			color = BRASS,
			material = M.Metal,
			reflectance = 0.1,
		})
	end
	table.insert(pieces, {
		name = `ClawTip_{a}`,
		shape = BALL,
		size = Vector3.new(0.09, 0.09, 0.09),
		offset = spin(a) * CFrame.new(0.555, 5.20, 0),
		color = BRASS,
		material = M.Metal,
		reflectance = 0.1,
	})
end

-- Plasma filaments from the core to the glass, each ending in a bright contact spot.
local FILAMENTS = {
	{ yaw = 25, pitch = 40 },
	{ yaw = 100, pitch = -5 },
	{ yaw = 170, pitch = 55 },
	{ yaw = 235, pitch = 10 },
	{ yaw = 305, pitch = -25 },
}
for index, filament in FILAMENTS do
	local ray = GLOBE * spin(filament.yaw) * CFrame.Angles(R(filament.pitch), 0, 0)
	table.insert(pieces, {
		name = `Filament{index}`,
		size = FILAMENT_SIZE,
		offset = ray * CFrame.new(0, 0, -0.33),
		color = PLASMA,
		material = M.Neon,
	})
	table.insert(pieces, {
		name = `Spot{index}`,
		shape = BALL,
		size = Vector3.new(0.07, 0.07, 0.07),
		offset = ray * CFrame.new(0, 0, -0.545),
		color = PLASMA_CORE,
		material = M.Neon,
	})
end

return WeaponModel.define({
	handle = {
		size = Vector3.new(0.4, 1.2, 0.4),
		color = LEATHER,
		material = M.Leather,
		transparency = 1,
	},
	-- Top of the glass globe; lightning effects start here.
	muzzle = CFrame.new(0, 5.46, 0),
	pieces = pieces,
})
