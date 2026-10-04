-- Teleport Wand: lathe-turned artisan wand, African blackwood shaft, walnut and leather-wrapped grip, brass-set amethyst point.

local WeaponModel = require(script.Parent.Parent.systems.WeaponModel)

local rgb = Color3.fromRGB
local M = Enum.Material
local CYLINDER_Z = WeaponModel.CYLINDER_Z
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball
local R = math.rad

local blackwood = rgb(38, 28, 24)
local beadWood = rgb(62, 44, 34)
local walnut = rgb(92, 58, 36)
local leather = rgb(70, 42, 26)
local brass = rgb(176, 140, 78)
local silver = rgb(196, 196, 200)
local amethyst = rgb(140, 70, 200)
local core = rgb(190, 90, 255)

local BRASS_REFLECT = 0.1
local SILVER_REFLECT = 0.15
local CRYSTAL_ALPHA = 0.35

-- Termination: a cube (side = R * sqrt(3/2)) with its body diagonal along -Z. Its silhouette along Z
-- is the prism's hexagon (corner radius R = 0.085), so the three front faces form the point and the
-- cube never pokes through the prism's flats. Rz(30) puts the cube's side vertices on the prism corners.
local POINT_SIDE = 0.104
local POINT = CFrame.new(0, 0, -2.414)
	* CFrame.Angles(0, 0, R(30))
	* CFrame.Angles(R(-144.7356), R(-45), 0)

return WeaponModel.define({
	handle = {
		size = Vector3.new(0.24, 0.24, 1.0),
		color = walnut,
		material = M.Wood,
		transparency = 1,
	},
	muzzle = CFrame.new(0, 0, -2.55),
	pieces = {
		-- Pommel and grip
		{
			name = "PommelBall",
			shape = BALL,
			size = Vector3.new(0.3, 0.3, 0.3),
			offset = CFrame.new(0, 0, 0.62),
			color = brass,
			material = M.Metal,
			reflectance = BRASS_REFLECT,
		},
		{
			name = "PommelCollar",
			shape = CYL,
			size = Vector3.new(0.08, 0.3, 0.3),
			offset = CFrame.new(0, 0, 0.52) * CYLINDER_Z,
			color = brass,
			material = M.Metal,
			reflectance = BRASS_REFLECT,
		},
		{
			name = "PommelKnob",
			shape = CYL,
			size = Vector3.new(0.14, 0.26, 0.26),
			offset = CFrame.new(0, 0, 0.41) * CYLINDER_Z,
			color = walnut,
			material = M.Wood,
		},
		{
			name = "GripCore",
			shape = CYL,
			size = Vector3.new(0.7, 0.22, 0.22),
			offset = CFrame.new(0, 0, -0.01) * CYLINDER_Z,
			color = walnut,
			material = M.Wood,
		},
		{
			name = "Wrap1",
			shape = CYL,
			size = Vector3.new(0.08, 0.245, 0.245),
			offset = CFrame.new(0, 0, 0.27) * CYLINDER_Z,
			color = leather,
			material = M.Leather,
		},
		{
			name = "Wrap2",
			shape = CYL,
			size = Vector3.new(0.08, 0.245, 0.245),
			offset = CFrame.new(0, 0, 0.15) * CYLINDER_Z,
			color = leather,
			material = M.Leather,
		},
		{
			name = "Wrap3",
			shape = CYL,
			size = Vector3.new(0.08, 0.245, 0.245),
			offset = CFrame.new(0, 0, 0.03) * CYLINDER_Z,
			color = leather,
			material = M.Leather,
		},
		{
			name = "Wrap4",
			shape = CYL,
			size = Vector3.new(0.08, 0.245, 0.245),
			offset = CFrame.new(0, 0, -0.09) * CYLINDER_Z,
			color = leather,
			material = M.Leather,
		},
		{
			name = "Wrap5",
			shape = CYL,
			size = Vector3.new(0.08, 0.245, 0.245),
			offset = CFrame.new(0, 0, -0.21) * CYLINDER_Z,
			color = leather,
			material = M.Leather,
		},
		{
			name = "Wrap6",
			shape = CYL,
			size = Vector3.new(0.08, 0.245, 0.245),
			offset = CFrame.new(0, 0, -0.33) * CYLINDER_Z,
			color = leather,
			material = M.Leather,
		},
		{
			name = "Wire1",
			shape = CYL,
			size = Vector3.new(0.02, 0.24, 0.24),
			offset = CFrame.new(0, 0, 0.21) * CYLINDER_Z,
			color = silver,
			material = M.Metal,
			reflectance = SILVER_REFLECT,
		},
		{
			name = "Wire2",
			shape = CYL,
			size = Vector3.new(0.02, 0.24, 0.24),
			offset = CFrame.new(0, 0, 0.09) * CYLINDER_Z,
			color = silver,
			material = M.Metal,
			reflectance = SILVER_REFLECT,
		},
		{
			name = "Wire3",
			shape = CYL,
			size = Vector3.new(0.02, 0.24, 0.24),
			offset = CFrame.new(0, 0, -0.03) * CYLINDER_Z,
			color = silver,
			material = M.Metal,
			reflectance = SILVER_REFLECT,
		},
		{
			name = "Wire4",
			shape = CYL,
			size = Vector3.new(0.02, 0.24, 0.24),
			offset = CFrame.new(0, 0, -0.15) * CYLINDER_Z,
			color = silver,
			material = M.Metal,
			reflectance = SILVER_REFLECT,
		},
		{
			name = "Wire5",
			shape = CYL,
			size = Vector3.new(0.02, 0.24, 0.24),
			offset = CFrame.new(0, 0, -0.27) * CYLINDER_Z,
			color = silver,
			material = M.Metal,
			reflectance = SILVER_REFLECT,
		},
		{
			name = "FrontFerrule",
			shape = CYL,
			size = Vector3.new(0.06, 0.26, 0.26),
			offset = CFrame.new(0, 0, -0.39) * CYLINDER_Z,
			color = brass,
			material = M.Metal,
			reflectance = BRASS_REFLECT,
		},
		{
			name = "Bolster",
			shape = CYL,
			size = Vector3.new(0.1, 0.28, 0.28),
			offset = CFrame.new(0, 0, -0.47) * CYLINDER_Z,
			color = walnut,
			material = M.Wood,
		},
		{
			name = "BolsterRing",
			shape = CYL,
			size = Vector3.new(0.03, 0.29, 0.29),
			offset = CFrame.new(0, 0, -0.535) * CYLINDER_Z,
			color = brass,
			material = M.Metal,
			reflectance = BRASS_REFLECT,
		},

		-- Shaft: stepped turned segments, each step hidden under a bead
		{
			name = "Shaft1",
			shape = CYL,
			size = Vector3.new(0.32, 0.18, 0.18),
			offset = CFrame.new(0, 0, -0.7) * CYLINDER_Z,
			color = blackwood,
			material = M.Wood,
		},
		{
			name = "Shaft2",
			shape = CYL,
			size = Vector3.new(0.32, 0.16, 0.16),
			offset = CFrame.new(0, 0, -1.0) * CYLINDER_Z,
			color = blackwood,
			material = M.Wood,
		},
		{
			name = "Shaft3",
			shape = CYL,
			size = Vector3.new(0.32, 0.14, 0.14),
			offset = CFrame.new(0, 0, -1.3) * CYLINDER_Z,
			color = blackwood,
			material = M.Wood,
		},
		{
			name = "Shaft4",
			shape = CYL,
			size = Vector3.new(0.32, 0.12, 0.12),
			offset = CFrame.new(0, 0, -1.6) * CYLINDER_Z,
			color = blackwood,
			material = M.Wood,
		},
		{
			name = "Shaft5",
			shape = CYL,
			size = Vector3.new(0.32, 0.105, 0.105),
			offset = CFrame.new(0, 0, -1.89) * CYLINDER_Z,
			color = blackwood,
			material = M.Wood,
		},
		{
			name = "Bead1",
			shape = CYL,
			size = Vector3.new(0.03, 0.2, 0.2),
			offset = CFrame.new(0, 0, -0.85) * CYLINDER_Z,
			color = beadWood,
			material = M.Wood,
		},
		{
			name = "Bead2",
			shape = CYL,
			size = Vector3.new(0.03, 0.18, 0.18),
			offset = CFrame.new(0, 0, -1.15) * CYLINDER_Z,
			color = beadWood,
			material = M.Wood,
		},
		{
			name = "Bead3",
			shape = CYL,
			size = Vector3.new(0.03, 0.16, 0.16),
			offset = CFrame.new(0, 0, -1.45) * CYLINDER_Z,
			color = beadWood,
			material = M.Wood,
		},
		{
			name = "Bead4",
			shape = CYL,
			size = Vector3.new(0.03, 0.14, 0.14),
			offset = CFrame.new(0, 0, -1.75) * CYLINDER_Z,
			color = beadWood,
			material = M.Wood,
		},
		{
			name = "Inlay1",
			shape = CYL,
			size = Vector3.new(0.015, 0.2, 0.2),
			offset = CFrame.new(0, 0, -0.63) * CYLINDER_Z,
			color = silver,
			material = M.Metal,
			reflectance = SILVER_REFLECT,
		},
		{
			name = "Inlay2",
			shape = CYL,
			size = Vector3.new(0.015, 0.2, 0.2),
			offset = CFrame.new(0, 0, -0.67) * CYLINDER_Z,
			color = silver,
			material = M.Metal,
			reflectance = SILVER_REFLECT,
		},

		-- Brass setting: collar, cup, lip, three claws on the crystal's flats (90, 210, 330 degrees)
		{
			name = "SettingCollar",
			shape = CYL,
			size = Vector3.new(0.08, 0.14, 0.14),
			offset = CFrame.new(0, 0, -2.07) * CYLINDER_Z,
			color = brass,
			material = M.Metal,
			reflectance = BRASS_REFLECT,
		},
		{
			name = "SettingCup",
			shape = CYL,
			size = Vector3.new(0.06, 0.18, 0.18),
			offset = CFrame.new(0, 0, -2.14) * CYLINDER_Z,
			color = brass,
			material = M.Metal,
			reflectance = BRASS_REFLECT,
		},
		{
			name = "CupLip",
			shape = CYL,
			size = Vector3.new(0.02, 0.21, 0.21),
			offset = CFrame.new(0, 0, -2.18) * CYLINDER_Z,
			color = brass,
			material = M.Metal,
			reflectance = BRASS_REFLECT,
		},
		{
			name = "ProngTop",
			size = Vector3.new(0.03, 0.02, 0.17),
			offset = CFrame.new(0, 0.096, -2.25),
			color = brass,
			material = M.Metal,
			reflectance = BRASS_REFLECT,
		},
		{
			name = "ProngLeft",
			size = Vector3.new(0.03, 0.02, 0.17),
			offset = CFrame.new(-0.0831, -0.048, -2.25) * CFrame.Angles(0, 0, R(120)),
			color = brass,
			material = M.Metal,
			reflectance = BRASS_REFLECT,
		},
		{
			name = "ProngRight",
			size = Vector3.new(0.03, 0.02, 0.17),
			offset = CFrame.new(0.0831, -0.048, -2.25) * CFrame.Angles(0, 0, R(240)),
			color = brass,
			material = M.Metal,
			reflectance = BRASS_REFLECT,
		},
		{
			name = "ProngBeadTop",
			shape = BALL,
			size = Vector3.new(0.035, 0.035, 0.035),
			offset = CFrame.new(0, 0.093, -2.33),
			color = brass,
			material = M.Metal,
			reflectance = BRASS_REFLECT,
		},
		{
			name = "ProngBeadLeft",
			shape = BALL,
			size = Vector3.new(0.035, 0.035, 0.035),
			offset = CFrame.new(-0.0805, -0.0465, -2.33),
			color = brass,
			material = M.Metal,
			reflectance = BRASS_REFLECT,
		},
		{
			name = "ProngBeadRight",
			shape = BALL,
			size = Vector3.new(0.035, 0.035, 0.035),
			offset = CFrame.new(0.0805, -0.0465, -2.33),
			color = brass,
			material = M.Metal,
			reflectance = BRASS_REFLECT,
		},

		-- Amethyst: hexagonal prism from three blocks at 0/60/120 degrees, ends staggered 0.01
		{
			name = "CrystalA",
			size = Vector3.new(0.085, 0.1472, 0.284),
			offset = CFrame.new(0, 0, -2.302),
			color = amethyst,
			material = M.Glass,
			transparency = CRYSTAL_ALPHA,
		},
		{
			name = "CrystalB",
			size = Vector3.new(0.085, 0.1472, 0.264),
			offset = CFrame.new(0, 0, -2.302) * CFrame.Angles(0, 0, R(60)),
			color = amethyst,
			material = M.Glass,
			transparency = CRYSTAL_ALPHA,
		},
		{
			name = "CrystalC",
			size = Vector3.new(0.085, 0.1472, 0.244),
			offset = CFrame.new(0, 0, -2.302) * CFrame.Angles(0, 0, R(120)),
			color = amethyst,
			material = M.Glass,
			transparency = CRYSTAL_ALPHA,
		},
		{
			name = "CrystalPoint",
			size = Vector3.new(POINT_SIDE, POINT_SIDE, POINT_SIDE),
			offset = POINT,
			color = amethyst,
			material = M.Glass,
			transparency = CRYSTAL_ALPHA,
		},
		{
			name = "CoreRod",
			shape = CYL,
			size = Vector3.new(0.22, 0.06, 0.06),
			offset = CFrame.new(0, 0, -2.3) * CYLINDER_Z,
			color = core,
			material = M.Neon,
		},
		{
			name = "CoreGlow",
			shape = BALL,
			size = Vector3.new(0.08, 0.08, 0.08),
			offset = CFrame.new(0, 0, -2.42),
			color = core,
			material = M.Neon,
		},
	},
})
