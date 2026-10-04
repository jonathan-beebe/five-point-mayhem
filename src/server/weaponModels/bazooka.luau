-- Bazooka: US M1A1 2.36-inch rocket launcher (1943-45), olive-drab steel tube, walnut stock and grips.

local WeaponModel = require(script.Parent.Parent.systems.WeaponModel)

local rgb = Color3.fromRGB
local M = Enum.Material
local CYLINDER_Z = WeaponModel.CYLINDER_Z
local CYLINDER_Y = WeaponModel.CYLINDER_Y
local CYL = Enum.PartType.Cylinder
local CF = CFrame.new
local R = math.rad

-- Pistol grip frame: raked 15 degrees, bottom toward +Z.
local GRIP = CF(0, -0.15, 0.06) * CFrame.Angles(R(-15), 0, 0)
-- Rear end of the sling strap; the strap and buckle face along the strap line.
local SLING_REAR = Vector3.new(-0.20, 0.20, 0.75)
-- Wedge flipped about Z: flat face on top, full face at +Z, slope facing down and forward.
local FLIP_Z = CFrame.Angles(0, 0, math.pi)

local OD = rgb(100, 108, 52)
local OD_DARK = rgb(72, 78, 40)
local PARKERIZED = rgb(40, 42, 40)
local WORN_STEEL = rgb(118, 118, 112)
local WALNUT = rgb(110, 72, 42)
local DARK_WALNUT = rgb(78, 50, 30)
local BORE_BLACK = rgb(14, 14, 14)
local PAD_RUBBER = rgb(36, 34, 32)
local BRASS = rgb(168, 138, 72)
local STENCIL = rgb(190, 166, 74)
local WEBBING = rgb(118, 110, 74)
local CABLE_BLACK = rgb(22, 22, 22)

local BAND_BOLT_SIZE = Vector3.new(0.10, 0.08, 0.12)
local GRIP_PANEL_SIZE = Vector3.new(0.02, 0.62, 0.28)
local SIGHT_POST_SIZE = Vector3.new(0.02, 0.36, 0.03)
local SIGHT_BAR_SIZE = Vector3.new(0.10, 0.02, 0.02)
local HOUSING_SCREW_SIZE = Vector3.new(0.03, 0.06, 0.06)
local SWIVEL_SIZE = Vector3.new(0.06, 0.08, 0.08)

return WeaponModel.define({
	handle = {
		size = Vector3.new(0.3, 0.3, 0.3),
		color = WALNUT,
		material = M.Wood,
		transparency = 1,
	},
	muzzle = CF(0, 0.70, -5.10),
	pieces = {
		-- Tube
		{
			name = "Tube",
			shape = CYL,
			size = Vector3.new(6.00, 0.72, 0.72),
			offset = CF(0, 0.70, -2.00) * CYLINDER_Z,
			color = OD,
			material = M.Metal,
		},
		{
			name = "MuzzleRing",
			shape = CYL,
			size = Vector3.new(0.12, 0.78, 0.78),
			offset = CF(0, 0.70, -4.945) * CYLINDER_Z,
			color = WORN_STEEL,
			material = M.Metal,
		},
		{
			name = "MuzzleBore",
			shape = CYL,
			size = Vector3.new(0.03, 0.60, 0.60),
			offset = CF(0, 0.70, -5.010) * CYLINDER_Z,
			color = BORE_BLACK,
			material = M.SmoothPlastic,
		},
		{
			name = "FrontBand",
			shape = CYL,
			size = Vector3.new(0.16, 0.76, 0.76),
			offset = CF(0, 0.70, -4.30) * CYLINDER_Z,
			color = OD_DARK,
			material = M.Metal,
		},
		{
			name = "FrontBandBolt",
			size = BAND_BOLT_SIZE,
			offset = CF(0, 0.30, -4.30),
			color = PARKERIZED,
			material = M.Metal,
		},
		{
			name = "MidBand",
			shape = CYL,
			size = Vector3.new(0.22, 0.77, 0.77),
			offset = CF(0, 0.70, -1.90) * CYLINDER_Z,
			color = OD_DARK,
			material = M.Metal,
		},
		{
			name = "MidBandBolt",
			size = BAND_BOLT_SIZE,
			offset = CF(0, 0.30, -1.90),
			color = PARKERIZED,
			material = M.Metal,
		},
		{
			name = "BreechCollar",
			shape = CYL,
			size = Vector3.new(0.29, 0.80, 0.80),
			offset = CF(0, 0.70, 0.845) * CYLINDER_Z,
			color = OD_DARK,
			material = M.Metal,
		},
		{
			name = "BreechLip",
			shape = CYL,
			size = Vector3.new(0.06, 0.84, 0.84),
			offset = CF(0, 0.70, 0.975) * CYLINDER_Z,
			color = WORN_STEEL,
			material = M.Metal,
		},
		{
			name = "BreechBore",
			shape = CYL,
			size = Vector3.new(0.03, 0.60, 0.60),
			offset = CF(0, 0.70, 1.015) * CYLINDER_Z,
			color = BORE_BLACK,
			material = M.SmoothPlastic,
		},

		-- Stencil markings, right side
		{
			name = "StencilLine1",
			size = Vector3.new(0.01, 0.05, 0.90),
			offset = CF(0.362, 0.73, -2.60),
			color = STENCIL,
			material = M.SmoothPlastic,
		},
		{
			name = "StencilLine2",
			size = Vector3.new(0.01, 0.04, 0.60),
			offset = CF(0.362, 0.66, -2.75),
			color = STENCIL,
			material = M.SmoothPlastic,
		},

		-- Front handgrip
		{
			name = "FrontGripClamp",
			shape = CYL,
			size = Vector3.new(0.20, 0.76, 0.76),
			offset = CF(0, 0.70, -1.30) * CYLINDER_Z,
			color = OD_DARK,
			material = M.Metal,
		},
		{
			name = "FrontGripBracket",
			size = Vector3.new(0.20, 0.18, 0.30),
			offset = CF(0, 0.27, -1.30),
			color = OD_DARK,
			material = M.Metal,
		},
		{
			name = "FrontGrip",
			size = Vector3.new(0.26, 0.62, 0.32),
			offset = CF(0, -0.10, -1.30),
			color = WALNUT,
			material = M.Wood,
		},
		{
			name = "FrontGripNose",
			shape = CYL,
			size = Vector3.new(0.62, 0.26, 0.26),
			offset = CF(0, -0.10, -1.46) * CYLINDER_Y,
			color = WALNUT,
			material = M.Wood,
		},
		{
			name = "FrontGripBack",
			shape = CYL,
			size = Vector3.new(0.62, 0.26, 0.26),
			offset = CF(0, -0.10, -1.14) * CYLINDER_Y,
			color = WALNUT,
			material = M.Wood,
		},
		{
			name = "FrontGripCap",
			size = Vector3.new(0.28, 0.05, 0.50),
			offset = CF(0, -0.43, -1.30),
			color = PARKERIZED,
			material = M.Metal,
		},

		-- Trigger group
		{
			name = "TriggerHousing",
			size = Vector3.new(0.24, 0.24, 0.82),
			offset = CF(0, 0.24, -0.17),
			color = OD_DARK,
			material = M.Metal,
		},
		{
			name = "GripBand",
			shape = CYL,
			size = Vector3.new(0.20, 0.76, 0.76),
			offset = CF(0, 0.70, 0.05) * CYLINDER_Z,
			color = OD_DARK,
			material = M.Metal,
		},
		{
			name = "Trigger",
			size = Vector3.new(0.06, 0.24, 0.07),
			offset = CF(0, 0.01, -0.30) * CFrame.Angles(R(12), 0, 0),
			color = PARKERIZED,
			material = M.Metal,
		},
		{
			name = "GuardBottom",
			size = Vector3.new(0.08, 0.04, 0.44),
			offset = CF(0, -0.20, -0.32),
			color = PARKERIZED,
			material = M.Metal,
		},
		{
			name = "GuardFront",
			size = Vector3.new(0.08, 0.34, 0.04),
			offset = CF(0, -0.045, -0.54),
			color = PARKERIZED,
			material = M.Metal,
		},
		{
			name = "HousingScrewF",
			shape = CYL,
			size = HOUSING_SCREW_SIZE,
			offset = CF(-0.13, 0.24, -0.45),
			color = PARKERIZED,
			material = M.Metal,
		},
		{
			name = "HousingScrewR",
			shape = CYL,
			size = HOUSING_SCREW_SIZE,
			offset = CF(-0.13, 0.24, 0.10),
			color = PARKERIZED,
			material = M.Metal,
		},

		-- Pistol grip
		{
			name = "PistolGrip",
			size = Vector3.new(0.26, 0.78, 0.36),
			offset = GRIP,
			color = WALNUT,
			material = M.Wood,
		},
		{
			name = "GripPanelL",
			size = GRIP_PANEL_SIZE,
			offset = GRIP * CF(-0.135, 0, 0),
			color = DARK_WALNUT,
			material = M.Wood,
		},
		{
			name = "GripPanelR",
			size = GRIP_PANEL_SIZE,
			offset = GRIP * CF(0.135, 0, 0),
			color = DARK_WALNUT,
			material = M.Wood,
		},
		{
			name = "GripCap",
			size = Vector3.new(0.28, 0.05, 0.38),
			offset = GRIP * CF(0, -0.40, 0),
			color = PARKERIZED,
			material = M.Metal,
		},

		-- Shoulder stock
		{
			name = "StockBody",
			size = Vector3.new(0.30, 0.38, 0.72),
			offset = CF(0, 0.19, 0.58),
			color = WALNUT,
			material = M.Wood,
		},
		{
			name = "StockHeel",
			class = "WedgePart",
			size = Vector3.new(0.30, 0.16, 0.50),
			offset = CF(0, -0.08, 0.69) * FLIP_Z,
			color = WALNUT,
			material = M.Wood,
		},
		{
			name = "ButtPad",
			size = Vector3.new(0.32, 0.56, 0.04),
			offset = CF(0, 0.11, 0.955),
			color = PAD_RUBBER,
			material = M.Rubber,
		},
		{
			name = "StockBoltL",
			shape = CYL,
			size = Vector3.new(0.03, 0.08, 0.08),
			offset = CF(-0.16, 0.20, 0.50),
			color = PARKERIZED,
			material = M.Metal,
		},
		{
			name = "BatteryCover",
			size = Vector3.new(0.02, 0.22, 0.36),
			offset = CF(0.155, 0.18, 0.62),
			color = OD_DARK,
			material = M.Metal,
		},
		{
			name = "CoverScrew",
			shape = CYL,
			size = Vector3.new(0.03, 0.05, 0.05),
			offset = CF(0.17, 0.18, 0.62),
			color = PARKERIZED,
			material = M.Metal,
		},

		-- Front sight, left side
		{
			name = "FrontSightBand",
			shape = CYL,
			size = Vector3.new(0.12, 0.76, 0.76),
			offset = CF(0, 0.70, -3.60) * CYLINDER_Z,
			color = OD_DARK,
			material = M.Metal,
		},
		{
			name = "FrontSightArm",
			size = Vector3.new(0.24, 0.06, 0.08),
			offset = CF(-0.45, 0.79, -3.60),
			color = PARKERIZED,
			material = M.Metal,
		},
		{
			name = "FrontSightPostL",
			size = SIGHT_POST_SIZE,
			offset = CF(-0.60, 0.96, -3.60),
			color = PARKERIZED,
			material = M.Metal,
		},
		{
			name = "FrontSightPostR",
			size = SIGHT_POST_SIZE,
			offset = CF(-0.50, 0.96, -3.60),
			color = PARKERIZED,
			material = M.Metal,
		},
		{
			name = "FrontSightTop",
			size = SIGHT_BAR_SIZE,
			offset = CF(-0.55, 1.12, -3.60),
			color = PARKERIZED,
			material = M.Metal,
		},
		{
			name = "FrontSightBot",
			size = SIGHT_BAR_SIZE,
			offset = CF(-0.55, 0.80, -3.60),
			color = PARKERIZED,
			material = M.Metal,
		},
		{
			name = "FrontRangePost",
			size = Vector3.new(0.012, 0.30, 0.016),
			offset = CF(-0.55, 0.96, -3.60),
			color = PARKERIZED,
			material = M.Metal,
		},

		-- Rear peep sight, left side
		{
			name = "RearSightBase",
			size = Vector3.new(0.26, 0.10, 0.20),
			offset = CF(-0.45, 0.82, 0.45),
			color = PARKERIZED,
			material = M.Metal,
		},
		{
			name = "RearSightPlate",
			size = Vector3.new(0.12, 0.20, 0.03),
			offset = CF(-0.55, 0.95, 0.45),
			color = PARKERIZED,
			material = M.Metal,
		},
		{
			name = "RearPeep",
			shape = CYL,
			size = Vector3.new(0.04, 0.07, 0.07),
			offset = CF(-0.55, 0.98, 0.45) * CYLINDER_Z,
			color = BORE_BLACK,
			material = M.SmoothPlastic,
		},

		-- Rocket latch and contact, top of breech
		{
			name = "LatchBase",
			size = Vector3.new(0.16, 0.06, 0.36),
			offset = CF(0, 1.07, 0.55),
			color = OD_DARK,
			material = M.Metal,
		},
		{
			name = "LatchLever",
			size = Vector3.new(0.08, 0.05, 0.40),
			offset = CF(0, 1.12, 0.50) * CFrame.Angles(R(6), 0, 0),
			color = PARKERIZED,
			material = M.Metal,
		},
		{
			name = "LatchPivot",
			shape = CYL,
			size = Vector3.new(0.18, 0.06, 0.06),
			offset = CF(0, 1.11, 0.68),
			color = PARKERIZED,
			material = M.Metal,
		},
		{
			name = "BreechContact",
			size = Vector3.new(0.10, 0.04, 0.12),
			offset = CF(0, 1.11, 0.86),
			color = BRASS,
			material = M.Metal,
			reflectance = 0.1,
		},

		-- Firing cable, right side
		{
			name = "FiringCable",
			shape = CYL,
			size = Vector3.new(0.66, 0.04, 0.04),
			offset = CF(0.37, 0.62, 0.38) * CYLINDER_Z,
			color = CABLE_BLACK,
			material = M.Rubber,
		},

		-- Sling, left side
		{
			name = "SlingSwivelF",
			size = SWIVEL_SIZE,
			offset = CF(-0.345, 0.50, -4.30),
			color = PARKERIZED,
			material = M.Metal,
		},
		{
			name = "SlingSwivelR",
			size = SWIVEL_SIZE,
			offset = CF(-0.175, 0.20, 0.75),
			color = PARKERIZED,
			material = M.Metal,
		},
		{
			name = "SlingStrap",
			size = Vector3.new(0.03, 0.12, 5.06),
			offset = CFrame.lookAt(Vector3.new(-0.285, 0.35, -1.775), SLING_REAR),
			color = WEBBING,
			material = M.Fabric,
		},
		{
			name = "SlingBuckle",
			size = Vector3.new(0.05, 0.15, 0.10),
			offset = CFrame.lookAt(Vector3.new(-0.319, 0.41, -2.785), SLING_REAR),
			color = WORN_STEEL,
			material = M.Metal,
		},
	},
})
