-- Double Barrel: Colt Model 1878-style 12-gauge side-by-side hammer coach gun, 20" barrels, walnut half-pistol-grip stock.

local WeaponModel = require(script.Parent.Parent.systems.WeaponModel)

local rgb = Color3.fromRGB
local M = Enum.Material
local CYLINDER_Z = WeaponModel.CYLINDER_Z
local CYLINDER_Y = WeaponModel.CYLINDER_Y
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball
local CF = CFrame.new
local R = math.rad

-- Wedge flipped about Z: top flat, full face at +Z, underside rising toward -Z.
local FLIP_Z = CFrame.Angles(0, 0, math.pi)

-- Pistol grip frame: top leans toward -Z, bottom toward +Z.
local G = CF(0, 0.02, 0.03) * CFrame.Angles(R(-18), 0, 0)
local HAMMER_TILT = CFrame.Angles(R(-37), 0, 0)
local SPUR_TILT = CFrame.Angles(R(-22), 0, 0)
local TRIGGER_TILT = CFrame.Angles(R(15), 0, 0)

local WALNUT = rgb(80, 55, 35)
local WALNUT_CHECK = rgb(52, 35, 22)
local BLUED = rgb(34, 36, 42)
local CASE_HARDENED = rgb(96, 90, 88)
local CASE_MOTTLE = rgb(120, 105, 95)
local BRIGHT_STEEL = rgb(150, 150, 155)
local BRASS = rgb(190, 155, 75)
local BORE = rgb(12, 12, 12)
local RUBBER = rgb(28, 26, 24)
local IVORY = rgb(215, 205, 185)

local BARREL_SIZE = Vector3.new(2.15, 0.17, 0.17)
local CHAMBER_SIZE = Vector3.new(0.55, 0.185, 0.185)
local RING_SIZE = Vector3.new(0.05, 0.178, 0.178)
local BORE_SIZE = Vector3.new(0.03, 0.11, 0.11)
local FENCE_SIZE = Vector3.new(0.07, 0.21, 0.21)
local BAR_PANEL_SIZE = Vector3.new(0.02, 0.12, 0.30)
local LOCK_PLATE_SIZE = Vector3.new(0.03, 0.18, 0.36)
local HAMMER_SIZE = Vector3.new(0.04, 0.20, 0.06)
local SPUR_SIZE = Vector3.new(0.045, 0.035, 0.11)
local TUMBLER_SIZE = Vector3.new(0.05, 0.07, 0.07)
local TRIGGER_SIZE = Vector3.new(0.035, 0.15, 0.035)
local FOREND_CHECK_SIZE = Vector3.new(0.02, 0.09, 0.50)
local GRIP_ROUND_SIZE = Vector3.new(0.55, 0.22, 0.22)
local GRIP_CHECK_SIZE = Vector3.new(0.02, 0.30, 0.14)
local GRIP_CAP_ROUND_SIZE = Vector3.new(0.03, 0.23, 0.23)

return WeaponModel.define({
	handle = {
		size = Vector3.new(0.2, 0.5, 0.3),
		color = WALNUT,
		material = M.Wood,
		transparency = 1,
	},
	muzzle = CF(0, 0.50, -3.03),
	pieces = {
		-- Barrels
		{
			name = "BarrelL",
			shape = CYL,
			size = BARREL_SIZE,
			offset = CF(-0.085, 0.50, -1.875) * CYLINDER_Z,
			color = BLUED,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "BarrelR",
			shape = CYL,
			size = BARREL_SIZE,
			offset = CF(0.085, 0.50, -1.875) * CYLINDER_Z,
			color = BLUED,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "ChamberL",
			shape = CYL,
			size = CHAMBER_SIZE,
			offset = CF(-0.085, 0.50, -0.575) * CYLINDER_Z,
			color = BLUED,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "ChamberR",
			shape = CYL,
			size = CHAMBER_SIZE,
			offset = CF(0.085, 0.50, -0.575) * CYLINDER_Z,
			color = BLUED,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "MuzzleRingL",
			shape = CYL,
			size = RING_SIZE,
			offset = CF(-0.085, 0.50, -2.975) * CYLINDER_Z,
			color = BLUED,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "MuzzleRingR",
			shape = CYL,
			size = RING_SIZE,
			offset = CF(0.085, 0.50, -2.975) * CYLINDER_Z,
			color = BLUED,
			material = M.Metal,
			reflectance = 0.05,
		},
		-- Bores sit 0.005 proud of the muzzle face (z -3.0).
		{
			name = "BoreL",
			shape = CYL,
			size = BORE_SIZE,
			offset = CF(-0.085, 0.50, -2.99) * CYLINDER_Z,
			color = BORE,
			material = M.SmoothPlastic,
		},
		{
			name = "BoreR",
			shape = CYL,
			size = BORE_SIZE,
			offset = CF(0.085, 0.50, -2.99) * CYLINDER_Z,
			color = BORE,
			material = M.SmoothPlastic,
		},
		{
			name = "TopRib",
			size = Vector3.new(0.07, 0.06, 2.66),
			offset = CF(0, 0.565, -1.63),
			color = BLUED,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "BottomRib",
			size = Vector3.new(0.08, 0.07, 2.66),
			offset = CF(0, 0.45, -1.63),
			color = BLUED,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "BeadSight",
			shape = BALL,
			size = Vector3.new(0.04, 0.04, 0.04),
			offset = CF(0, 0.61, -2.92),
			color = BRASS,
			material = M.Metal,
			reflectance = 0.15,
		},

		-- Action
		{
			name = "StandingBreech",
			size = Vector3.new(0.32, 0.385, 0.24),
			offset = CF(0, 0.4075, -0.18),
			color = CASE_HARDENED,
			material = M.Metal,
		},
		{
			name = "ActionBar",
			size = Vector3.new(0.32, 0.20, 0.42),
			offset = CF(0, 0.315, -0.51),
			color = CASE_HARDENED,
			material = M.Metal,
		},
		{
			name = "Knuckle",
			shape = CYL,
			size = Vector3.new(0.30, 0.20, 0.20),
			offset = CF(0, 0.315, -0.72),
			color = CASE_HARDENED,
			material = M.Metal,
		},
		{
			name = "HingePin",
			shape = CYL,
			size = Vector3.new(0.34, 0.08, 0.08),
			offset = CF(0, 0.28, -0.66),
			color = BRIGHT_STEEL,
			material = M.Metal,
		},
		{
			name = "FenceL",
			shape = CYL,
			size = FENCE_SIZE,
			offset = CF(-0.085, 0.50, -0.27) * CYLINDER_Z,
			color = CASE_HARDENED,
			material = M.Metal,
		},
		{
			name = "FenceR",
			shape = CYL,
			size = FENCE_SIZE,
			offset = CF(0.085, 0.50, -0.27) * CYLINDER_Z,
			color = CASE_HARDENED,
			material = M.Metal,
		},
		{
			name = "BarPanelL",
			size = BAR_PANEL_SIZE,
			offset = CF(-0.16, 0.315, -0.50),
			color = CASE_MOTTLE,
			material = M.Metal,
		},
		{
			name = "BarPanelR",
			size = BAR_PANEL_SIZE,
			offset = CF(0.16, 0.315, -0.50),
			color = CASE_MOTTLE,
			material = M.Metal,
		},
		{
			name = "LockPlateL",
			size = LOCK_PLATE_SIZE,
			offset = CF(-0.14, 0.40, 0.11),
			color = CASE_MOTTLE,
			material = M.Metal,
		},
		{
			name = "LockPlateR",
			size = LOCK_PLATE_SIZE,
			offset = CF(0.14, 0.40, 0.11),
			color = CASE_MOTTLE,
			material = M.Metal,
		},
		{
			name = "TopTang",
			size = Vector3.new(0.09, 0.025, 0.32),
			offset = CF(0, 0.5875, 0.10),
			color = BLUED,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "TopLever",
			size = Vector3.new(0.07, 0.03, 0.20),
			offset = CF(0.02, 0.615, -0.03) * CFrame.Angles(0, R(15), 0),
			color = BLUED,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "LeverPivot",
			shape = CYL,
			size = Vector3.new(0.035, 0.07, 0.07),
			offset = CF(0, 0.6175, -0.12) * CYLINDER_Y,
			color = BRIGHT_STEEL,
			material = M.Metal,
		},
		{
			name = "Safety",
			size = Vector3.new(0.04, 0.025, 0.07),
			offset = CF(0, 0.6125, 0.17),
			color = BRIGHT_STEEL,
			material = M.Metal,
		},

		-- Hammers
		{
			name = "HammerL",
			size = HAMMER_SIZE,
			offset = CF(-0.15, 0.54, 0.04) * HAMMER_TILT,
			color = CASE_HARDENED,
			material = M.Metal,
		},
		{
			name = "HammerR",
			size = HAMMER_SIZE,
			offset = CF(0.15, 0.54, 0.04) * HAMMER_TILT,
			color = CASE_HARDENED,
			material = M.Metal,
		},
		{
			name = "SpurL",
			size = SPUR_SIZE,
			offset = CF(-0.15, 0.65, 0.02) * SPUR_TILT,
			color = CASE_HARDENED,
			material = M.Metal,
		},
		{
			name = "SpurR",
			size = SPUR_SIZE,
			offset = CF(0.15, 0.65, 0.02) * SPUR_TILT,
			color = CASE_HARDENED,
			material = M.Metal,
		},
		{
			name = "TumblerScrewL",
			shape = CYL,
			size = TUMBLER_SIZE,
			offset = CF(-0.15, 0.46, 0.10),
			color = BRIGHT_STEEL,
			material = M.Metal,
		},
		{
			name = "TumblerScrewR",
			shape = CYL,
			size = TUMBLER_SIZE,
			offset = CF(0.15, 0.46, 0.10),
			color = BRIGHT_STEEL,
			material = M.Metal,
		},

		-- Trigger group
		{
			name = "TriggerPlate",
			size = Vector3.new(0.12, 0.03, 0.62),
			offset = CF(0, 0.205, -0.30),
			color = BLUED,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "FrontTrigger",
			size = TRIGGER_SIZE,
			offset = CF(0, 0.13, -0.46) * TRIGGER_TILT,
			color = BLUED,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "RearTrigger",
			size = TRIGGER_SIZE,
			offset = CF(0, 0.13, -0.34) * TRIGGER_TILT,
			color = BLUED,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "GuardFront",
			size = Vector3.new(0.04, 0.17, 0.04),
			offset = CF(0, 0.11, -0.60),
			color = BLUED,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "GuardBow",
			size = Vector3.new(0.04, 0.04, 0.38),
			offset = CF(0, 0.025, -0.42),
			color = BLUED,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "GuardRear",
			size = Vector3.new(0.04, 0.04, 0.13),
			offset = CF(0, 0.0525, -0.205) * CFrame.Angles(R(-31), 0, 0),
			color = BLUED,
			material = M.Metal,
			reflectance = 0.05,
		},

		-- Forend: top at y 0.44 so it wraps the lower barrel line (barrel bottoms at 0.415).
		{
			name = "Forend",
			size = Vector3.new(0.28, 0.175, 1.03),
			offset = CF(0, 0.3525, -1.315),
			color = WALNUT,
			material = M.Wood,
		},
		{
			name = "ForendTip",
			class = "WedgePart",
			size = Vector3.new(0.28, 0.175, 0.14),
			offset = CF(0, 0.3525, -1.90) * FLIP_Z,
			color = WALNUT,
			material = M.Wood,
		},
		{
			name = "ForendIron",
			size = Vector3.new(0.16, 0.02, 0.36),
			offset = CF(0, 0.255, -0.98),
			color = CASE_HARDENED,
			material = M.Metal,
		},
		{
			name = "ForendLatch",
			size = Vector3.new(0.06, 0.02, 0.08),
			offset = CF(0, 0.24, -1.10),
			color = BRIGHT_STEEL,
			material = M.Metal,
		},
		{
			name = "ForendCheckL",
			size = FOREND_CHECK_SIZE,
			offset = CF(-0.14, 0.35, -1.35),
			color = WALNUT_CHECK,
			material = M.Fabric,
		},
		{
			name = "ForendCheckR",
			size = FOREND_CHECK_SIZE,
			offset = CF(0.14, 0.35, -1.35),
			color = WALNUT_CHECK,
			material = M.Fabric,
		},

		-- Stock
		{
			name = "Wrist",
			size = Vector3.new(0.26, 0.19, 0.41),
			offset = CF(0, 0.355, 0.145),
			color = WALNUT,
			material = M.Wood,
		},
		{
			name = "StockTop",
			shape = CYL,
			size = Vector3.new(0.91, 0.255, 0.255),
			offset = CF(0, 0.45, 0.395) * CYLINDER_Z,
			color = WALNUT,
			material = M.Wood,
		},
		{
			name = "GripCore",
			size = Vector3.new(0.22, 0.55, 0.12),
			offset = G,
			color = WALNUT,
			material = M.Wood,
		},
		{
			name = "GripFront",
			shape = CYL,
			size = GRIP_ROUND_SIZE,
			offset = G * CF(0, 0, -0.06) * CYLINDER_Y,
			color = WALNUT,
			material = M.Wood,
		},
		{
			name = "GripBack",
			shape = CYL,
			size = GRIP_ROUND_SIZE,
			offset = G * CF(0, 0, 0.06) * CYLINDER_Y,
			color = WALNUT,
			material = M.Wood,
		},
		{
			name = "GripCheckL",
			size = GRIP_CHECK_SIZE,
			offset = G * CF(-0.115, 0.02, 0),
			color = WALNUT_CHECK,
			material = M.Fabric,
		},
		{
			name = "GripCheckR",
			size = GRIP_CHECK_SIZE,
			offset = G * CF(0.115, 0.02, 0),
			color = WALNUT_CHECK,
			material = M.Fabric,
		},
		{
			name = "GripCapCore",
			size = Vector3.new(0.23, 0.03, 0.12),
			offset = G * CF(0, -0.285, 0),
			color = RUBBER,
			material = M.Rubber,
		},
		{
			name = "GripCapFront",
			shape = CYL,
			size = GRIP_CAP_ROUND_SIZE,
			offset = G * CF(0, -0.285, -0.06) * CYLINDER_Y,
			color = RUBBER,
			material = M.Rubber,
		},
		{
			name = "GripCapBack",
			shape = CYL,
			size = GRIP_CAP_ROUND_SIZE,
			offset = G * CF(0, -0.285, 0.06) * CYLINDER_Y,
			color = RUBBER,
			material = M.Rubber,
		},
		{
			name = "GripWeb",
			size = Vector3.new(0.24, 0.26, 0.25),
			offset = CF(0, 0.13, 0.245),
			color = WALNUT,
			material = M.Wood,
		},
		{
			name = "Buttstock",
			size = Vector3.new(0.26, 0.45, 0.50),
			offset = CF(0, 0.225, 0.60),
			color = WALNUT,
			material = M.Wood,
		},
		{
			name = "Belly",
			class = "WedgePart",
			size = Vector3.new(0.26, 0.14, 0.50),
			offset = CF(0, -0.07, 0.60) * FLIP_Z,
			color = WALNUT,
			material = M.Wood,
		},
		{
			name = "Spacer",
			size = Vector3.new(0.27, 0.72, 0.015),
			offset = CF(0, 0.22, 0.8575),
			color = IVORY,
			material = M.Plastic,
		},
		{
			name = "ButtPad",
			size = Vector3.new(0.28, 0.73, 0.06),
			offset = CF(0, 0.22, 0.895),
			color = RUBBER,
			material = M.Rubber,
		},
	},
})
