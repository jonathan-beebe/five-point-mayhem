-- Sniper Rifle: USMC M40A5 / US Army M24 SWS bolt-action (Remington 700 action, McMillan A4 stock, Leupold Mark 4 scope).

local WeaponModel = require(script.Parent.Parent.systems.WeaponModel)

local rgb = Color3.fromRGB
local M = Enum.Material
local CYLINDER_Z = WeaponModel.CYLINDER_Z
local CYLINDER_Y = WeaponModel.CYLINDER_Y
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball

local rad = math.rad

-- WedgePart default has its right angle at local (ymin, zmax). Flipped about Z: flat top,
-- vertical face at +Z, slope from top-front (-Z) down to bottom-back (+Z).
local FLIP_Z = CFrame.Angles(0, 0, math.pi)

-- Pistol grip frame, raked 15 degrees so the top leans forward.
local GRIP = CFrame.new(0, -0.12, 0.1) * CFrame.Angles(rad(-15), 0, 0)

local STOCK_OD = rgb(45, 60, 45)
local STIPPLE = rgb(36, 48, 36)
local CERAKOTE = rgb(34, 35, 37)
local ANODIZED = rgb(22, 22, 24)
local BOLT_STEEL = rgb(160, 162, 165)
local BOTTOM_METAL = rgb(28, 28, 30)
local RUBBER = rgb(18, 18, 18)
local BORE_BLACK = rgb(6, 6, 6)
local LENS_OBJECTIVE = rgb(40, 70, 90)
local LENS_EYE = rgb(25, 35, 45)
local INDEX_WHITE = rgb(225, 225, 215)
local BIPOD_STEEL = rgb(40, 41, 43)

local RAIL_SLOT = Vector3.new(0.12, 0.012, 0.03)
local FLUTE_SIDE = Vector3.new(0.012, 0.03, 1.60)
local BRAKE_PORT = Vector3.new(0.03, 0.07, 0.16)
local RING_BASE = Vector3.new(0.20, 0.10, 0.12)
local RING = Vector3.new(0.10, 0.27, 0.27)
local CROSS_BOLT = Vector3.new(0.24, 0.05, 0.05)
local LEG_OUTER = Vector3.new(0.70, 0.06, 0.06)
local LEG_INNER = Vector3.new(0.45, 0.045, 0.045)
local FOOT = Vector3.new(0.08, 0.08, 0.08)

return WeaponModel.define({
	handle = {
		size = Vector3.new(0.3, 0.3, 0.3),
		color = RUBBER,
		material = M.SmoothPlastic,
		transparency = 1,
	},
	muzzle = CFrame.new(0, 0.5, -5.07),
	pieces = {
		-- Stock
		{
			name = "StockAction",
			size = Vector3.new(0.34, 0.43, 1.75),
			offset = CFrame.new(0, 0.265, -0.625),
			color = STOCK_OD,
			material = M.Plastic,
		},
		{
			name = "Wrist",
			size = Vector3.new(0.32, 0.35, 0.30),
			offset = CFrame.new(0, 0.295, 0.30),
			color = STOCK_OD,
			material = M.Plastic,
		},
		{
			name = "GripWeb",
			size = Vector3.new(0.28, 0.17, 0.20),
			offset = CFrame.new(0, 0.045, 0.32),
			color = STOCK_OD,
			material = M.Plastic,
		},
		{
			name = "Grip",
			size = Vector3.new(0.30, 0.60, 0.36),
			offset = GRIP,
			color = STOCK_OD,
			material = M.Plastic,
		},
		{
			name = "GripCap",
			size = Vector3.new(0.32, 0.04, 0.38),
			offset = GRIP * CFrame.new(0, -0.31, 0),
			color = RUBBER,
			material = M.Rubber,
		},
		{
			name = "GripStippleL",
			size = Vector3.new(0.02, 0.34, 0.24),
			offset = GRIP * CFrame.new(-0.155, -0.02, 0),
			color = STIPPLE,
			material = M.Sand,
		},
		{
			name = "GripStippleR",
			size = Vector3.new(0.02, 0.34, 0.24),
			offset = GRIP * CFrame.new(0.155, -0.02, 0),
			color = STIPPLE,
			material = M.Sand,
		},
		{
			name = "ButtMain",
			size = Vector3.new(0.34, 0.53, 0.70),
			offset = CFrame.new(0, 0.215, 0.75),
			color = STOCK_OD,
			material = M.Plastic,
		},
		{
			name = "ButtBelly",
			class = "WedgePart",
			size = Vector3.new(0.34, 0.25, 0.70),
			offset = CFrame.new(0, -0.175, 0.75) * FLIP_Z,
			color = STOCK_OD,
			material = M.Plastic,
		},
		{
			name = "CheekRiser",
			size = Vector3.new(0.28, 0.10, 0.55),
			offset = CFrame.new(0, 0.525, 0.775),
			color = STOCK_OD,
			material = M.Plastic,
		},
		{
			name = "ButtPad",
			size = Vector3.new(0.35, 0.80, 0.10),
			offset = CFrame.new(0, 0.09, 1.15),
			color = RUBBER,
			material = M.Rubber,
		},
		{
			name = "RearSlingStud",
			shape = CYL,
			size = Vector3.new(0.06, 0.05, 0.05),
			offset = CFrame.new(0, -0.26, 0.95) * CYLINDER_Y,
			color = BOTTOM_METAL,
			material = M.Metal,
		},
		{
			name = "ForeEnd",
			size = Vector3.new(0.34, 0.26, 1.20),
			offset = CFrame.new(0, 0.33, -2.10),
			color = STOCK_OD,
			material = M.Plastic,
		},
		{
			name = "ForeEndTransition",
			class = "WedgePart",
			size = Vector3.new(0.34, 0.15, 0.40),
			offset = CFrame.new(0, 0.125, -1.70) * FLIP_Z,
			color = STOCK_OD,
			material = M.Plastic,
		},
		{
			name = "ForeEndTip",
			class = "WedgePart",
			size = Vector3.new(0.34, 0.26, 0.30),
			offset = CFrame.new(0, 0.33, -2.85) * FLIP_Z,
			color = STOCK_OD,
			material = M.Plastic,
		},

		-- Action
		{
			name = "Receiver",
			shape = CYL,
			size = Vector3.new(1.50, 0.28, 0.28),
			offset = CFrame.new(0, 0.5, -0.70) * CYLINDER_Z,
			color = CERAKOTE,
			material = M.Metal,
		},
		{
			name = "EjectionPort",
			size = Vector3.new(0.024, 0.10, 0.50),
			offset = CFrame.new(0.132, 0.54, -0.60),
			color = BOLT_STEEL,
			material = M.Metal,
			reflectance = 0.15,
		},
		{
			name = "BoltShroud",
			shape = CYL,
			size = Vector3.new(0.20, 0.24, 0.24),
			offset = CFrame.new(0, 0.5, 0.15) * CYLINDER_Z,
			color = CERAKOTE,
			material = M.Metal,
		},
		{
			name = "CockingPiece",
			size = Vector3.new(0.08, 0.10, 0.06),
			offset = CFrame.new(0, 0.47, 0.27),
			color = CERAKOTE,
			material = M.Metal,
		},
		{
			name = "BoltHandle",
			size = Vector3.new(0.32, 0.05, 0.05),
			offset = CFrame.new(0.25, 0.42, 0) * CFrame.Angles(0, 0, rad(-30)),
			color = BOLT_STEEL,
			material = M.Metal,
			reflectance = 0.15,
		},
		{
			name = "BoltKnob",
			shape = BALL,
			size = Vector3.new(0.13, 0.13, 0.13),
			offset = CFrame.new(0.39, 0.34, 0),
			color = CERAKOTE,
			material = M.Metal,
		},
		{
			name = "Safety",
			size = Vector3.new(0.04, 0.05, 0.08),
			offset = CFrame.new(0.12, 0.50, 0.18),
			color = CERAKOTE,
			material = M.Metal,
		},

		-- Barrel
		{
			name = "BarrelNut",
			shape = CYL,
			size = Vector3.new(0.06, 0.25, 0.25),
			offset = CFrame.new(0, 0.5, -1.48) * CYLINDER_Z,
			color = CERAKOTE,
			material = M.Metal,
		},
		{
			name = "BarrelShank",
			shape = CYL,
			size = Vector3.new(0.85, 0.22, 0.22),
			offset = CFrame.new(0, 0.5, -1.935) * CYLINDER_Z,
			color = CERAKOTE,
			material = M.Metal,
		},
		{
			name = "BarrelMain",
			shape = CYL,
			size = Vector3.new(1.90, 0.19, 0.19),
			offset = CFrame.new(0, 0.5, -3.31) * CYLINDER_Z,
			color = CERAKOTE,
			material = M.Metal,
		},
		{
			name = "BarrelMuzzle",
			shape = CYL,
			size = Vector3.new(0.50, 0.17, 0.17),
			offset = CFrame.new(0, 0.5, -4.51) * CYLINDER_Z,
			color = CERAKOTE,
			material = M.Metal,
		},
		{
			name = "FluteL",
			size = FLUTE_SIDE,
			offset = CFrame.new(-0.096, 0.5, -3.31),
			color = BORE_BLACK,
			material = M.SmoothPlastic,
		},
		{
			name = "FluteR",
			size = FLUTE_SIDE,
			offset = CFrame.new(0.096, 0.5, -3.31),
			color = BORE_BLACK,
			material = M.SmoothPlastic,
		},
		{
			name = "FluteTop",
			size = Vector3.new(0.03, 0.012, 1.60),
			offset = CFrame.new(0, 0.596, -3.31),
			color = BORE_BLACK,
			material = M.SmoothPlastic,
		},
		{
			name = "MuzzleBrake",
			shape = CYL,
			size = Vector3.new(0.30, 0.23, 0.23),
			offset = CFrame.new(0, 0.5, -4.90) * CYLINDER_Z,
			color = CERAKOTE,
			material = M.Metal,
		},
		{
			name = "BrakePortL",
			size = BRAKE_PORT,
			offset = CFrame.new(-0.11, 0.5, -4.92),
			color = BORE_BLACK,
			material = M.SmoothPlastic,
		},
		{
			name = "BrakePortR",
			size = BRAKE_PORT,
			offset = CFrame.new(0.11, 0.5, -4.92),
			color = BORE_BLACK,
			material = M.SmoothPlastic,
		},
		{
			name = "Bore",
			shape = CYL,
			size = Vector3.new(0.02, 0.08, 0.08),
			offset = CFrame.new(0, 0.5, -5.055) * CYLINDER_Z,
			color = BORE_BLACK,
			material = M.SmoothPlastic,
		},

		-- Rail and rings
		{
			name = "ScopeRail",
			size = Vector3.new(0.14, 0.05, 1.40),
			offset = CFrame.new(0, 0.655, -0.70),
			color = ANODIZED,
			material = M.Metal,
		},
		{
			name = "RailSlot1",
			size = RAIL_SLOT,
			offset = CFrame.new(0, 0.684, -0.45),
			color = BORE_BLACK,
			material = M.SmoothPlastic,
		},
		{
			name = "RailSlot2",
			size = RAIL_SLOT,
			offset = CFrame.new(0, 0.684, -0.60),
			color = BORE_BLACK,
			material = M.SmoothPlastic,
		},
		{
			name = "RailSlot3",
			size = RAIL_SLOT,
			offset = CFrame.new(0, 0.684, -0.75),
			color = BORE_BLACK,
			material = M.SmoothPlastic,
		},
		{
			name = "RailSlot4",
			size = RAIL_SLOT,
			offset = CFrame.new(0, 0.684, -0.90),
			color = BORE_BLACK,
			material = M.SmoothPlastic,
		},
		{
			name = "RingBaseRear",
			size = RING_BASE,
			offset = CFrame.new(0, 0.73, -0.25),
			color = ANODIZED,
			material = M.Metal,
		},
		{
			name = "RingBaseFront",
			size = RING_BASE,
			offset = CFrame.new(0, 0.73, -1.15),
			color = ANODIZED,
			material = M.Metal,
		},
		{
			name = "RingRear",
			shape = CYL,
			size = RING,
			offset = CFrame.new(0, 0.9, -0.25) * CYLINDER_Z,
			color = ANODIZED,
			material = M.Metal,
		},
		{
			name = "RingFront",
			shape = CYL,
			size = RING,
			offset = CFrame.new(0, 0.9, -1.15) * CYLINDER_Z,
			color = ANODIZED,
			material = M.Metal,
		},
		{
			name = "CrossBoltRear",
			shape = CYL,
			size = CROSS_BOLT,
			offset = CFrame.new(0, 0.72, -0.25),
			color = BOLT_STEEL,
			material = M.Metal,
			reflectance = 0.15,
		},
		{
			name = "CrossBoltFront",
			shape = CYL,
			size = CROSS_BOLT,
			offset = CFrame.new(0, 0.72, -1.15),
			color = BOLT_STEEL,
			material = M.Metal,
			reflectance = 0.15,
		},

		-- Scope
		{
			name = "EyeLens",
			shape = CYL,
			size = Vector3.new(0.02, 0.20, 0.20),
			offset = CFrame.new(0, 0.9, 0.365) * CYLINDER_Z,
			color = LENS_EYE,
			material = M.Glass,
			transparency = 0.1,
			reflectance = 0.3,
		},
		{
			name = "Eyecup",
			shape = CYL,
			size = Vector3.new(0.06, 0.31, 0.31),
			offset = CFrame.new(0, 0.9, 0.33) * CYLINDER_Z,
			color = RUBBER,
			material = M.Rubber,
		},
		{
			name = "EyepieceBell",
			shape = CYL,
			size = Vector3.new(0.30, 0.29, 0.29),
			offset = CFrame.new(0, 0.9, 0.15) * CYLINDER_Z,
			color = ANODIZED,
			material = M.Metal,
		},
		{
			name = "FocusRing",
			shape = CYL,
			size = Vector3.new(0.05, 0.31, 0.31),
			offset = CFrame.new(0, 0.9, 0.06) * CYLINDER_Z,
			color = RUBBER,
			material = M.Rubber,
		},
		{
			name = "EyepieceTaper",
			shape = CYL,
			size = Vector3.new(0.10, 0.25, 0.25),
			offset = CFrame.new(0, 0.9, -0.05) * CYLINDER_Z,
			color = ANODIZED,
			material = M.Metal,
		},
		{
			name = "TubeRear",
			shape = CYL,
			size = Vector3.new(0.40, 0.22, 0.22),
			offset = CFrame.new(0, 0.9, -0.30) * CYLINDER_Z,
			color = ANODIZED,
			material = M.Metal,
		},
		{
			name = "TurretSaddle",
			shape = CYL,
			size = Vector3.new(0.30, 0.29, 0.29),
			offset = CFrame.new(0, 0.9, -0.65) * CYLINDER_Z,
			color = ANODIZED,
			material = M.Metal,
		},
		{
			name = "ElevationTurret",
			shape = CYL,
			size = Vector3.new(0.13, 0.18, 0.18),
			offset = CFrame.new(0, 1.085, -0.65) * CYLINDER_Y,
			color = ANODIZED,
			material = M.Metal,
		},
		{
			name = "ElevationCap",
			shape = CYL,
			size = Vector3.new(0.07, 0.21, 0.21),
			offset = CFrame.new(0, 1.185, -0.65) * CYLINDER_Y,
			color = ANODIZED,
			material = M.Metal,
		},
		{
			name = "ElevationIndex",
			size = Vector3.new(0.02, 0.01, 0.08),
			offset = CFrame.new(0, 1.224, -0.70),
			color = INDEX_WHITE,
			material = M.SmoothPlastic,
		},
		{
			name = "WindageTurret",
			shape = CYL,
			size = Vector3.new(0.13, 0.18, 0.18),
			offset = CFrame.new(0.195, 0.9, -0.65),
			color = ANODIZED,
			material = M.Metal,
		},
		{
			name = "WindageCap",
			shape = CYL,
			size = Vector3.new(0.07, 0.21, 0.21),
			offset = CFrame.new(0.295, 0.9, -0.65),
			color = ANODIZED,
			material = M.Metal,
		},
		{
			name = "ParallaxKnob",
			shape = CYL,
			size = Vector3.new(0.10, 0.16, 0.16),
			offset = CFrame.new(-0.18, 0.9, -0.65),
			color = ANODIZED,
			material = M.Metal,
		},
		{
			name = "TubeFront",
			shape = CYL,
			size = Vector3.new(0.45, 0.22, 0.22),
			offset = CFrame.new(0, 0.9, -1.025) * CYLINDER_Z,
			color = ANODIZED,
			material = M.Metal,
		},
		{
			name = "ObjectiveTaper",
			shape = CYL,
			size = Vector3.new(0.15, 0.30, 0.30),
			offset = CFrame.new(0, 0.9, -1.325) * CYLINDER_Z,
			color = ANODIZED,
			material = M.Metal,
		},
		{
			name = "ObjectiveBell",
			shape = CYL,
			size = Vector3.new(0.35, 0.38, 0.38),
			offset = CFrame.new(0, 0.9, -1.575) * CYLINDER_Z,
			color = ANODIZED,
			material = M.Metal,
		},
		{
			name = "ObjectiveLens",
			shape = CYL,
			size = Vector3.new(0.02, 0.32, 0.32),
			offset = CFrame.new(0, 0.9, -1.755) * CYLINDER_Z,
			color = LENS_OBJECTIVE,
			material = M.Glass,
			transparency = 0.2,
			reflectance = 0.4,
		},

		-- Bottom metal
		{
			name = "Floorplate",
			size = Vector3.new(0.24, 0.03, 1.15),
			offset = CFrame.new(0, 0.04, -0.60),
			color = BOTTOM_METAL,
			material = M.Metal,
		},
		{
			name = "TriggerGuardBar",
			size = Vector3.new(0.08, 0.04, 0.57),
			offset = CFrame.new(0, -0.20, -0.305),
			color = BOTTOM_METAL,
			material = M.Metal,
		},
		{
			name = "TriggerGuardFront",
			size = Vector3.new(0.08, 0.26, 0.05),
			offset = CFrame.new(0, -0.06, -0.565),
			color = BOTTOM_METAL,
			material = M.Metal,
		},
		{
			name = "Trigger",
			size = Vector3.new(0.04, 0.20, 0.05),
			offset = CFrame.new(0, -0.04, -0.30) * CFrame.Angles(rad(10), 0, 0),
			color = CERAKOTE,
			material = M.Metal,
		},
		{
			name = "Magazine",
			size = Vector3.new(0.20, 0.24, 0.42),
			offset = CFrame.new(0, -0.08, -0.92),
			color = BOTTOM_METAL,
			material = M.Metal,
		},
		{
			name = "MagBaseplate",
			size = Vector3.new(0.22, 0.03, 0.44),
			offset = CFrame.new(0, -0.21, -0.92),
			color = CERAKOTE,
			material = M.Metal,
		},
		{
			name = "MagRelease",
			size = Vector3.new(0.06, 0.10, 0.03),
			offset = CFrame.new(0, -0.01, -1.14),
			color = CERAKOTE,
			material = M.Metal,
		},

		-- Bipod, folded forward
		{
			name = "BipodMount",
			size = Vector3.new(0.30, 0.10, 0.16),
			offset = CFrame.new(0, 0.155, -2.55),
			color = BIPOD_STEEL,
			material = M.Metal,
		},
		{
			name = "BipodPivot",
			shape = CYL,
			size = Vector3.new(0.34, 0.08, 0.08),
			offset = CFrame.new(0, 0.12, -2.60),
			color = BIPOD_STEEL,
			material = M.Metal,
		},
		{
			name = "LegOuterL",
			shape = CYL,
			size = LEG_OUTER,
			offset = CFrame.new(-0.12, 0.12, -2.95) * CYLINDER_Z,
			color = BIPOD_STEEL,
			material = M.Metal,
		},
		{
			name = "LegOuterR",
			shape = CYL,
			size = LEG_OUTER,
			offset = CFrame.new(0.12, 0.12, -2.95) * CYLINDER_Z,
			color = BIPOD_STEEL,
			material = M.Metal,
		},
		{
			name = "LegInnerL",
			shape = CYL,
			size = LEG_INNER,
			offset = CFrame.new(-0.12, 0.12, -3.525) * CYLINDER_Z,
			color = BOLT_STEEL,
			material = M.Metal,
			reflectance = 0.15,
		},
		{
			name = "LegInnerR",
			shape = CYL,
			size = LEG_INNER,
			offset = CFrame.new(0.12, 0.12, -3.525) * CYLINDER_Z,
			color = BOLT_STEEL,
			material = M.Metal,
			reflectance = 0.15,
		},
		{
			name = "FootL",
			shape = BALL,
			size = FOOT,
			offset = CFrame.new(-0.12, 0.12, -3.77),
			color = RUBBER,
			material = M.Rubber,
		},
		{
			name = "FootR",
			shape = BALL,
			size = FOOT,
			offset = CFrame.new(0.12, 0.12, -3.77),
			color = RUBBER,
			material = M.Rubber,
		},
	},
})
