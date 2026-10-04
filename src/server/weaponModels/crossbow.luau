-- Crossbow: Barnett-style recurve hunting crossbow with walnut stock and scope, cocked with a broadhead bolt.

local WeaponModel = require(script.Parent.Parent.systems.WeaponModel)

local rgb = Color3.fromRGB
local M = Enum.Material
local CYLINDER_Z = WeaponModel.CYLINDER_Z
local CYLINDER_Y = WeaponModel.CYLINDER_Y
local CYL = Enum.PartType.Cylinder
local rad = math.rad

-- Wedge orientations (WedgePart default: flat bottom, vertical face at +Z, slope rising toward +Z).
local FLIP_Z = CFrame.Angles(0, 0, math.pi) -- flat top, vertical face at +Z
local LAY_L = CFrame.Angles(0, 0, rad(90)) -- flat face toward +X, height along -X
local LAY_R = CFrame.Angles(0, 0, rad(-90)) -- flat face toward -X, height along +X

-- Pistol grip frame: raked 15 degrees, bottom toward +Z.
local GRIP = CFrame.new(0, -0.08, 0.06) * CFrame.Angles(rad(-15), 0, 0)

local WALNUT = rgb(120, 85, 50)
local CHECKERING = rgb(72, 50, 32)
local GUNMETAL = rgb(52, 54, 58)
local BLUED_STEEL = rgb(38, 40, 46)
local BRUSHED_STEEL = rgb(165, 168, 172)
local RAIL_ALU = rgb(120, 122, 126)
local LIMB_BLACK = rgb(30, 30, 32)
local RUBBER = rgb(25, 25, 27)
local POLYMER = rgb(35, 35, 37)
local STRING = rgb(210, 200, 175)
local CARBON = rgb(22, 22, 24)
local VANE_ORANGE = rgb(230, 95, 30)
local NOCK_LIME = rgb(120, 200, 60)
local BLADE_STEEL = rgb(200, 202, 206)
local SCOPE_BLACK = rgb(30, 30, 32)
local LENS = rgb(90, 120, 140)

local BOLT_Y = 0.632

return WeaponModel.define({
	handle = {
		size = Vector3.new(0.24, 0.6, 0.38),
		color = WALNUT,
		material = M.Wood,
		transparency = 1,
	},
	muzzle = CFrame.new(0, BOLT_Y, -2.4),
	pieces = {
		-- Stock
		{
			name = "Tiller",
			size = Vector3.new(0.34, 0.26, 2.44),
			offset = CFrame.new(0, 0.42, -0.97),
			color = WALNUT,
			material = M.Wood,
		},
		{
			name = "Butt",
			size = Vector3.new(0.3, 0.55, 0.5),
			offset = CFrame.new(0, 0.33, 0.5),
			color = WALNUT,
			material = M.Wood,
		},
		{
			name = "ButtPad",
			size = Vector3.new(0.32, 0.57, 0.06),
			offset = CFrame.new(0, 0.33, 0.775),
			color = RUBBER,
			material = M.Rubber,
		},
		{
			name = "CombRamp",
			class = "WedgePart",
			size = Vector3.new(0.29, 0.055, 0.25),
			offset = CFrame.new(0, 0.5775, 0.125),
			color = WALNUT,
			material = M.Wood,
		},
		{
			name = "BellyWedge",
			class = "WedgePart",
			size = Vector3.new(0.3, 0.235, 0.25),
			offset = CFrame.new(0, 0.1725, 0.125) * FLIP_Z,
			color = WALNUT,
			material = M.Wood,
		},
		{
			name = "Grip",
			size = Vector3.new(0.26, 0.88, 0.4),
			offset = GRIP * CFrame.new(0, 0.04, 0),
			color = WALNUT,
			material = M.Wood,
		},
		{
			name = "GripCap",
			size = Vector3.new(0.28, 0.06, 0.44),
			offset = GRIP * CFrame.new(0, -0.42, 0),
			color = BLUED_STEEL,
			material = M.Metal,
		},
		{
			name = "GripPanelR",
			size = Vector3.new(0.02, 0.45, 0.28),
			offset = GRIP * CFrame.new(0.135, -0.03, 0),
			color = CHECKERING,
			material = M.Fabric,
		},
		{
			name = "GripPanelL",
			size = Vector3.new(0.02, 0.45, 0.28),
			offset = GRIP * CFrame.new(-0.135, -0.03, 0),
			color = CHECKERING,
			material = M.Fabric,
		},
		{
			name = "ForendPanelR",
			size = Vector3.new(0.02, 0.16, 0.6),
			offset = CFrame.new(0.175, 0.42, -1.4),
			color = CHECKERING,
			material = M.Fabric,
		},
		{
			name = "ForendPanelL",
			size = Vector3.new(0.02, 0.16, 0.6),
			offset = CFrame.new(-0.175, 0.42, -1.4),
			color = CHECKERING,
			material = M.Fabric,
		},

		-- Trigger group
		{
			name = "TriggerBox",
			size = Vector3.new(0.37, 0.22, 0.8),
			offset = CFrame.new(0, 0.42, -0.25),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "PinRear",
			shape = CYL,
			size = Vector3.new(0.39, 0.05, 0.05),
			offset = CFrame.new(0, 0.38, -0.05),
			color = BRUSHED_STEEL,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "PinFront",
			shape = CYL,
			size = Vector3.new(0.39, 0.05, 0.05),
			offset = CFrame.new(0, 0.38, -0.45),
			color = BRUSHED_STEEL,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "GuardBottom",
			size = Vector3.new(0.06, 0.04, 0.55),
			offset = CFrame.new(0, -0.12, -0.42),
			color = BLUED_STEEL,
			material = M.Metal,
		},
		{
			name = "GuardFront",
			size = Vector3.new(0.06, 0.44, 0.05),
			offset = CFrame.new(0, 0.08, -0.67),
			color = BLUED_STEEL,
			material = M.Metal,
		},
		{
			name = "Trigger",
			size = Vector3.new(0.05, 0.34, 0.06),
			offset = CFrame.new(0, 0.14, -0.36) * CFrame.Angles(rad(-15), 0, 0),
			color = BLUED_STEEL,
			material = M.Metal,
		},
		{
			name = "Safety",
			size = Vector3.new(0.08, 0.05, 0.12),
			offset = CFrame.new(0, 0.57, -0.15),
			color = POLYMER,
			material = M.Plastic,
		},

		-- Rail and latch
		{
			name = "FlightRail",
			size = Vector3.new(0.14, 0.05, 1.15),
			offset = CFrame.new(0, 0.575, -1.325),
			color = RAIL_ALU,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "LatchBlock",
			size = Vector3.new(0.24, 0.14, 0.5),
			offset = CFrame.new(0, 0.62, -0.5),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "RetentionSpring",
			size = Vector3.new(0.03, 0.01, 0.25),
			offset = CFrame.new(0, 0.67, -0.85),
			color = BRUSHED_STEEL,
			material = M.Metal,
			reflectance = 0.1,
		},

		-- Prod
		{
			name = "ProdBracket",
			size = Vector3.new(0.5, 0.27, 0.3),
			offset = CFrame.new(0, 0.465, -2.05),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "LimbInnerR",
			size = Vector3.new(0.44, 0.18, 0.07),
			offset = CFrame.new(0.4432, 0.58, -1.9982) * CFrame.Angles(0, rad(-15), 0),
			color = LIMB_BLACK,
			material = M.SmoothPlastic,
			reflectance = 0.05,
		},
		{
			name = "LimbInnerL",
			size = Vector3.new(0.44, 0.18, 0.07),
			offset = CFrame.new(-0.4432, 0.58, -1.9982) * CFrame.Angles(0, rad(15), 0),
			color = LIMB_BLACK,
			material = M.SmoothPlastic,
			reflectance = 0.05,
		},
		{
			name = "LimbMidR",
			size = Vector3.new(0.39, 0.15, 0.06),
			offset = CFrame.new(0.788, 0.58, -1.8589) * CFrame.Angles(0, rad(-30), 0),
			color = LIMB_BLACK,
			material = M.SmoothPlastic,
			reflectance = 0.05,
		},
		{
			name = "LimbMidL",
			size = Vector3.new(0.39, 0.15, 0.06),
			offset = CFrame.new(-0.788, 0.58, -1.8589) * CFrame.Angles(0, rad(30), 0),
			color = LIMB_BLACK,
			material = M.SmoothPlastic,
			reflectance = 0.05,
		},
		{
			name = "LimbTipR",
			size = Vector3.new(0.2, 0.12, 0.05),
			offset = CFrame.new(1.0241, 0.58, -1.8022) * CFrame.Angles(0, rad(20), 0),
			color = LIMB_BLACK,
			material = M.SmoothPlastic,
			reflectance = 0.05,
		},
		{
			name = "LimbTipL",
			size = Vector3.new(0.2, 0.12, 0.05),
			offset = CFrame.new(-1.0241, 0.58, -1.8022) * CFrame.Angles(0, rad(-20), 0),
			color = LIMB_BLACK,
			material = M.SmoothPlastic,
			reflectance = 0.05,
		},
		{
			name = "LimbPocketR",
			size = Vector3.new(0.16, 0.22, 0.14),
			offset = CFrame.new(0.308, 0.58, -2.0345) * CFrame.Angles(0, rad(-15), 0),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "LimbPocketL",
			size = Vector3.new(0.16, 0.22, 0.14),
			offset = CFrame.new(-0.308, 0.58, -2.0345) * CFrame.Angles(0, rad(15), 0),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "TipCapR",
			shape = CYL,
			size = Vector3.new(0.16, 0.09, 0.09),
			offset = CFrame.new(1.1087, 0.58, -1.833) * CYLINDER_Y,
			color = RUBBER,
			material = M.Rubber,
		},
		{
			name = "TipCapL",
			shape = CYL,
			size = Vector3.new(0.16, 0.09, 0.09),
			offset = CFrame.new(-1.1087, 0.58, -1.833) * CYLINDER_Y,
			color = RUBBER,
			material = M.Rubber,
		},
		{
			name = "StringR",
			shape = CYL,
			size = Vector3.new(1.52, 0.03, 0.03),
			offset = CFrame.new(0.5744, 0.615, -1.2915) * CFrame.Angles(0, rad(45.35), 0),
			color = STRING,
			material = M.Fabric,
		},
		{
			name = "StringL",
			shape = CYL,
			size = Vector3.new(1.52, 0.03, 0.03),
			offset = CFrame.new(-0.5744, 0.615, -1.2915) * CFrame.Angles(0, rad(-45.35), 0),
			color = STRING,
			material = M.Fabric,
		},

		-- Stirrup
		{
			name = "StirrupArmR",
			size = Vector3.new(0.05, 0.05, 0.3),
			offset = CFrame.new(0.2, 0.42, -2.335),
			color = BLUED_STEEL,
			material = M.Metal,
		},
		{
			name = "StirrupArmL",
			size = Vector3.new(0.05, 0.05, 0.3),
			offset = CFrame.new(-0.2, 0.42, -2.335),
			color = BLUED_STEEL,
			material = M.Metal,
		},
		{
			name = "StirrupBar",
			shape = CYL,
			size = Vector3.new(0.45, 0.06, 0.06),
			offset = CFrame.new(0, 0.42, -2.47),
			color = BLUED_STEEL,
			material = M.Metal,
		},

		-- Bolt
		{
			name = "BoltShaft",
			shape = CYL,
			size = Vector3.new(1.45, 0.06, 0.06),
			offset = CFrame.new(0, BOLT_Y, -1.475) * CYLINDER_Z,
			color = CARBON,
			material = M.SmoothPlastic,
			reflectance = 0.1,
		},
		{
			name = "Nock",
			shape = CYL,
			size = Vector3.new(0.06, 0.066, 0.066),
			offset = CFrame.new(0, BOLT_Y, -0.77) * CYLINDER_Z,
			color = NOCK_LIME,
			material = M.Plastic,
		},
		{
			name = "VaneL",
			class = "WedgePart",
			size = Vector3.new(0.012, 0.06, 0.3),
			offset = CFrame.new(0, BOLT_Y, -1)
				* CFrame.Angles(0, 0, rad(60))
				* CFrame.new(0, 0.055, 0),
			color = VANE_ORANGE,
			material = M.Plastic,
		},
		{
			name = "VaneR",
			class = "WedgePart",
			size = Vector3.new(0.012, 0.06, 0.3),
			offset = CFrame.new(0, BOLT_Y, -1)
				* CFrame.Angles(0, 0, rad(-60))
				* CFrame.new(0, 0.055, 0),
			color = VANE_ORANGE,
			material = M.Plastic,
		},
		{
			name = "Ferrule",
			shape = CYL,
			size = Vector3.new(0.08, 0.055, 0.055),
			offset = CFrame.new(0, BOLT_Y, -2.22) * CYLINDER_Z,
			color = CARBON,
			material = M.SmoothPlastic,
			reflectance = 0.1,
		},
		{
			name = "BladeTop",
			class = "WedgePart",
			size = Vector3.new(0.012, 0.06, 0.16),
			offset = CFrame.new(0, BOLT_Y + 0.03, -2.28),
			color = BLADE_STEEL,
			material = M.Metal,
			reflectance = 0.15,
		},
		{
			name = "BladeBottom",
			class = "WedgePart",
			size = Vector3.new(0.012, 0.06, 0.16),
			offset = CFrame.new(0, BOLT_Y - 0.03, -2.28) * FLIP_Z,
			color = BLADE_STEEL,
			material = M.Metal,
			reflectance = 0.15,
		},
		{
			name = "BladeLeft",
			class = "WedgePart",
			size = Vector3.new(0.012, 0.06, 0.16),
			offset = CFrame.new(-0.03, BOLT_Y, -2.28) * LAY_L,
			color = BLADE_STEEL,
			material = M.Metal,
			reflectance = 0.15,
		},
		{
			name = "BladeRight",
			class = "WedgePart",
			size = Vector3.new(0.012, 0.06, 0.16),
			offset = CFrame.new(0.03, BOLT_Y, -2.28) * LAY_R,
			color = BLADE_STEEL,
			material = M.Metal,
			reflectance = 0.15,
		},

		-- Scope
		{
			name = "ScopeBase",
			size = Vector3.new(0.14, 0.04, 0.5),
			offset = CFrame.new(0, 0.71, -0.5),
			color = SCOPE_BLACK,
			material = M.Metal,
		},
		{
			name = "RingFootRear",
			size = Vector3.new(0.1, 0.1, 0.06),
			offset = CFrame.new(0, 0.775, -0.35),
			color = SCOPE_BLACK,
			material = M.Metal,
		},
		{
			name = "RingFootFront",
			size = Vector3.new(0.1, 0.1, 0.06),
			offset = CFrame.new(0, 0.775, -0.65),
			color = SCOPE_BLACK,
			material = M.Metal,
		},
		{
			name = "RingRear",
			shape = CYL,
			size = Vector3.new(0.06, 0.22, 0.22),
			offset = CFrame.new(0, 0.88, -0.35) * CYLINDER_Z,
			color = SCOPE_BLACK,
			material = M.Metal,
		},
		{
			name = "RingFront",
			shape = CYL,
			size = Vector3.new(0.06, 0.22, 0.22),
			offset = CFrame.new(0, 0.88, -0.65) * CYLINDER_Z,
			color = SCOPE_BLACK,
			material = M.Metal,
		},
		{
			name = "ScopeTube",
			shape = CYL,
			size = Vector3.new(0.8, 0.16, 0.16),
			offset = CFrame.new(0, 0.88, -0.5) * CYLINDER_Z,
			color = SCOPE_BLACK,
			material = M.Metal,
		},
		{
			name = "ObjectiveBell",
			shape = CYL,
			size = Vector3.new(0.2, 0.24, 0.24),
			offset = CFrame.new(0, 0.88, -0.95) * CYLINDER_Z,
			color = SCOPE_BLACK,
			material = M.Metal,
		},
		{
			name = "ObjectiveLens",
			shape = CYL,
			size = Vector3.new(0.02, 0.2, 0.2),
			offset = CFrame.new(0, 0.88, -1.059) * CYLINDER_Z,
			color = LENS,
			material = M.Glass,
			transparency = 0.35,
			reflectance = 0.4,
		},
		{
			name = "OcularBell",
			shape = CYL,
			size = Vector3.new(0.16, 0.21, 0.21),
			offset = CFrame.new(0, 0.88, -0.05) * CYLINDER_Z,
			color = SCOPE_BLACK,
			material = M.Metal,
		},
		{
			name = "Eyecup",
			shape = CYL,
			size = Vector3.new(0.06, 0.22, 0.22),
			offset = CFrame.new(0, 0.88, 0.05) * CYLINDER_Z,
			color = RUBBER,
			material = M.Rubber,
		},
		{
			name = "TurretElev",
			shape = CYL,
			size = Vector3.new(0.1, 0.1, 0.1),
			offset = CFrame.new(0, 0.99, -0.5) * CYLINDER_Y,
			color = SCOPE_BLACK,
			material = M.Metal,
		},
		{
			name = "TurretWind",
			shape = CYL,
			size = Vector3.new(0.1, 0.1, 0.1),
			offset = CFrame.new(0.11, 0.88, -0.5),
			color = SCOPE_BLACK,
			material = M.Metal,
		},
	},
})
