-- SMG: H&K MP5A3 9mm submachine gun, retractable stock collapsed, slimline handguard, Navy trigger group.

local WeaponModel = require(script.Parent.Parent.systems.WeaponModel)

local rgb = Color3.fromRGB
local M = Enum.Material
local CYLINDER_Z = WeaponModel.CYLINDER_Z
local CYLINDER_Y = WeaponModel.CYLINDER_Y
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball

local GUNMETAL = rgb(70, 70, 75)
local DARK_STEEL = rgb(40, 40, 44)
local WORN_STEEL = rgb(110, 110, 115)
local POLYMER = rgb(30, 30, 32)
local STIPPLE = rgb(38, 38, 40)
local MAG_STEEL = rgb(52, 52, 56)
local BORE_BLACK = rgb(10, 10, 12)
local BUTT_RUBBER = rgb(22, 22, 22)

-- Grip frame: bottom rakes rearward.
local G = CFrame.new(0, -0.08, 0.06) * CFrame.Angles(math.rad(-15), 0, 0)
-- Lower magazine frame: bottom curves forward.
local MG = CFrame.new(0, -0.25, -0.70) * CFrame.Angles(math.rad(15), 0, 0)
-- Muzzle collar centre, for the three lugs.
local COLLAR = CFrame.new(0, 0.40, -2.35)

local PIN_SIZE = Vector3.new(0.28, 0.035, 0.035)
local LUG_SIZE = Vector3.new(0.04, 0.03, 0.08)
local GROOVE_SIZE = Vector3.new(0.02, 0.025, 0.66)
local RIDGE_SIZE = Vector3.new(0.22, 0.07, 0.07)
local RAIL_SIZE = Vector3.new(0.85, 0.06, 0.06)

return WeaponModel.define({
	handle = {
		size = Vector3.new(0.2, 0.5, 0.25),
		color = POLYMER,
		material = M.Plastic,
		transparency = 1,
	},
	muzzle = CFrame.new(0, 0.40, -2.43),
	pieces = {
		-- Receiver
		{
			name = "ReceiverBody",
			size = Vector3.new(0.30, 0.19, 1.30),
			offset = CFrame.new(0, 0.425, -0.40),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "ReceiverTop",
			shape = CYL,
			size = Vector3.new(1.30, 0.30, 0.30),
			offset = CFrame.new(0, 0.52, -0.40) * CYLINDER_Z,
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "TopWeldRib",
			size = Vector3.new(0.04, 0.02, 0.98),
			offset = CFrame.new(0, 0.675, -0.51),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "SideRibL",
			size = Vector3.new(0.03, 0.05, 1.10),
			offset = CFrame.new(-0.16, 0.40, -0.42),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "SideRibR",
			size = Vector3.new(0.03, 0.05, 1.10),
			offset = CFrame.new(0.16, 0.40, -0.42),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "EjectionPort",
			size = Vector3.new(0.02, 0.10, 0.28),
			offset = CFrame.new(0.151, 0.51, -0.69),
			color = BORE_BLACK,
			material = M.SmoothPlastic,
		},
		{
			name = "EndCapBlock",
			size = Vector3.new(0.31, 0.195, 0.06),
			offset = CFrame.new(0, 0.4225, 0.28),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "EndCapTop",
			shape = CYL,
			size = Vector3.new(0.06, 0.31, 0.31),
			offset = CFrame.new(0, 0.52, 0.28) * CYLINDER_Z,
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "EndCapPin",
			shape = CYL,
			size = Vector3.new(0.34, 0.04, 0.04),
			offset = CFrame.new(0, 0.40, 0.27),
			color = WORN_STEEL,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "CockingTube",
			shape = CYL,
			size = Vector3.new(1.05, 0.20, 0.20),
			offset = CFrame.new(0, 0.55, -1.555) * CYLINDER_Z,
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "CockingSlot",
			size = Vector3.new(0.02, 0.035, 0.70),
			offset = CFrame.new(-0.09, 0.60, -1.50),
			color = BORE_BLACK,
			material = M.SmoothPlastic,
		},
		{
			name = "CockingTubeCap",
			shape = CYL,
			size = Vector3.new(0.04, 0.21, 0.21),
			offset = CFrame.new(0, 0.55, -2.10) * CYLINDER_Z,
			color = DARK_STEEL,
			material = M.Metal,
		},
		{
			name = "CockingStem",
			shape = CYL,
			size = Vector3.new(0.14, 0.05, 0.05),
			offset = CFrame.new(-0.16, 0.60, -1.25),
			color = WORN_STEEL,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "CockingKnob",
			shape = BALL,
			size = Vector3.new(0.10, 0.10, 0.10),
			offset = CFrame.new(-0.25, 0.60, -1.25),
			color = POLYMER,
			material = M.Plastic,
		},

		-- Rear sight (rotary drum)
		{
			name = "RearSightBase",
			size = Vector3.new(0.14, 0.05, 0.16),
			offset = CFrame.new(0, 0.69, 0.12),
			color = DARK_STEEL,
			material = M.Metal,
		},
		{
			name = "RearSightDrum",
			shape = CYL,
			size = Vector3.new(0.18, 0.16, 0.16),
			offset = CFrame.new(0, 0.79, 0.12),
			color = DARK_STEEL,
			material = M.Metal,
		},
		{
			name = "RearAperture",
			shape = BALL,
			size = Vector3.new(0.045, 0.045, 0.045),
			offset = CFrame.new(0, 0.79, 0.20),
			color = BORE_BLACK,
			material = M.SmoothPlastic,
		},

		-- Front sight (hooded post)
		{
			name = "FrontSightBlock",
			size = Vector3.new(0.18, 0.32, 0.12),
			offset = CFrame.new(0, 0.50, -2.02),
			color = DARK_STEEL,
			material = M.Metal,
		},
		{
			name = "HoodEarL",
			size = Vector3.new(0.03, 0.18, 0.10),
			offset = CFrame.new(-0.08, 0.75, -2.02),
			color = DARK_STEEL,
			material = M.Metal,
		},
		{
			name = "HoodEarR",
			size = Vector3.new(0.03, 0.18, 0.10),
			offset = CFrame.new(0.08, 0.75, -2.02),
			color = DARK_STEEL,
			material = M.Metal,
		},
		{
			name = "HoodTop",
			size = Vector3.new(0.20, 0.03, 0.12),
			offset = CFrame.new(0, 0.835, -2.02),
			color = DARK_STEEL,
			material = M.Metal,
		},
		{
			name = "FrontPost",
			size = Vector3.new(0.025, 0.12, 0.03),
			offset = CFrame.new(0, 0.72, -2.02),
			color = DARK_STEEL,
			material = M.Metal,
		},

		-- Barrel and muzzle
		{
			name = "Barrel",
			shape = CYL,
			size = Vector3.new(0.62, 0.12, 0.12),
			offset = CFrame.new(0, 0.40, -1.99) * CYLINDER_Z,
			color = DARK_STEEL,
			material = M.Metal,
		},
		{
			name = "MuzzleCollar",
			shape = CYL,
			size = Vector3.new(0.10, 0.17, 0.17),
			offset = COLLAR * CYLINDER_Z,
			color = DARK_STEEL,
			material = M.Metal,
		},
		{
			name = "LugTop",
			size = LUG_SIZE,
			offset = COLLAR * CFrame.new(0, 0.095, 0),
			color = WORN_STEEL,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "LugLeft",
			size = LUG_SIZE,
			offset = COLLAR * CFrame.Angles(0, 0, math.rad(120)) * CFrame.new(0, 0.095, 0),
			color = WORN_STEEL,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "LugRight",
			size = LUG_SIZE,
			offset = COLLAR * CFrame.Angles(0, 0, math.rad(240)) * CFrame.new(0, 0.095, 0),
			color = WORN_STEEL,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "Bore",
			shape = CYL,
			size = Vector3.new(0.03, 0.07, 0.07),
			offset = CFrame.new(0, 0.40, -2.405) * CYLINDER_Z,
			color = BORE_BLACK,
			material = M.SmoothPlastic,
		},

		-- Handguard (slimline)
		{
			name = "HandguardUpper",
			size = Vector3.new(0.32, 0.22, 0.82),
			offset = CFrame.new(0, 0.44, -1.45),
			color = POLYMER,
			material = M.Plastic,
		},
		{
			name = "HandguardBelly",
			shape = CYL,
			size = Vector3.new(0.82, 0.32, 0.32),
			offset = CFrame.new(0, 0.37, -1.45) * CYLINDER_Z,
			color = POLYMER,
			material = M.Plastic,
		},
		{
			name = "GrooveUpperL",
			size = GROOVE_SIZE,
			offset = CFrame.new(-0.165, 0.47, -1.45),
			color = BORE_BLACK,
			material = M.SmoothPlastic,
		},
		{
			name = "GrooveUpperR",
			size = GROOVE_SIZE,
			offset = CFrame.new(0.165, 0.47, -1.45),
			color = BORE_BLACK,
			material = M.SmoothPlastic,
		},
		{
			name = "GrooveLowerL",
			size = GROOVE_SIZE,
			offset = CFrame.new(-0.165, 0.38, -1.45),
			color = BORE_BLACK,
			material = M.SmoothPlastic,
		},
		{
			name = "GrooveLowerR",
			size = GROOVE_SIZE,
			offset = CFrame.new(0.165, 0.38, -1.45),
			color = BORE_BLACK,
			material = M.SmoothPlastic,
		},
		{
			name = "HandStopLip",
			size = Vector3.new(0.30, 0.10, 0.04),
			offset = CFrame.new(0, 0.22, -1.83),
			color = POLYMER,
			material = M.Plastic,
		},
		{
			name = "HandguardPin",
			shape = CYL,
			size = Vector3.new(0.36, 0.05, 0.05),
			offset = CFrame.new(0, 0.30, -1.10),
			color = WORN_STEEL,
			material = M.Metal,
			reflectance = 0.1,
		},

		-- Trigger group / lower
		{
			name = "LowerHousing",
			size = Vector3.new(0.26, 0.22, 0.62),
			offset = CFrame.new(0, 0.23, -0.14),
			color = POLYMER,
			material = M.Plastic,
		},
		{
			name = "RearPushPin",
			shape = CYL,
			size = PIN_SIZE,
			offset = CFrame.new(0, 0.19, 0.13),
			color = WORN_STEEL,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "FrontPushPin",
			shape = CYL,
			size = PIN_SIZE,
			offset = CFrame.new(0, 0.29, -0.38),
			color = WORN_STEEL,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "SelectorLeverL",
			size = Vector3.new(0.03, 0.05, 0.16),
			offset = CFrame.new(-0.14, 0.27, 0.05) * CFrame.Angles(math.rad(-20), 0, 0),
			color = POLYMER,
			material = M.Plastic,
		},
		{
			name = "SelectorLeverR",
			size = Vector3.new(0.03, 0.05, 0.16),
			offset = CFrame.new(0.14, 0.27, 0.05) * CFrame.Angles(math.rad(-20), 0, 0),
			color = POLYMER,
			material = M.Plastic,
		},
		{
			name = "SelectorPivotL",
			shape = CYL,
			size = Vector3.new(0.04, 0.08, 0.08),
			offset = CFrame.new(-0.145, 0.27, 0.12),
			color = DARK_STEEL,
			material = M.Metal,
		},
		{
			name = "SelectorPivotR",
			shape = CYL,
			size = Vector3.new(0.04, 0.08, 0.08),
			offset = CFrame.new(0.145, 0.27, 0.12),
			color = DARK_STEEL,
			material = M.Metal,
		},
		{
			name = "TriggerGuardBar",
			size = Vector3.new(0.08, 0.035, 0.35),
			offset = CFrame.new(0, -0.05, -0.265),
			color = POLYMER,
			material = M.Plastic,
		},
		{
			name = "TriggerGuardPost",
			size = Vector3.new(0.08, 0.19, 0.035),
			offset = CFrame.new(0, 0.035, -0.43),
			color = POLYMER,
			material = M.Plastic,
		},
		{
			name = "TriggerUpper",
			size = Vector3.new(0.04, 0.11, 0.035),
			offset = CFrame.new(0, 0.075, -0.22),
			color = DARK_STEEL,
			material = M.Metal,
		},
		{
			name = "TriggerLower",
			size = Vector3.new(0.04, 0.07, 0.035),
			offset = CFrame.new(0, 0.005, -0.205) * CFrame.Angles(math.rad(20), 0, 0),
			color = DARK_STEEL,
			material = M.Metal,
		},

		-- Pistol grip
		{
			name = "GripCore",
			size = Vector3.new(0.24, 0.60, 0.20),
			offset = G * CFrame.new(0, 0, -0.05),
			color = POLYMER,
			material = M.Plastic,
		},
		{
			name = "GripBackstrap",
			shape = CYL,
			size = Vector3.new(0.60, 0.24, 0.24),
			offset = G * CFrame.new(0, 0, 0.04) * CYLINDER_Y,
			color = POLYMER,
			material = M.Plastic,
		},
		{
			name = "FingerRidge1",
			shape = CYL,
			size = RIDGE_SIZE,
			offset = G * CFrame.new(0, 0.02, -0.15),
			color = POLYMER,
			material = M.Plastic,
		},
		{
			name = "FingerRidge2",
			shape = CYL,
			size = RIDGE_SIZE,
			offset = G * CFrame.new(0, -0.12, -0.15),
			color = POLYMER,
			material = M.Plastic,
		},
		{
			name = "FingerRidge3",
			shape = CYL,
			size = RIDGE_SIZE,
			offset = G * CFrame.new(0, -0.26, -0.15),
			color = POLYMER,
			material = M.Plastic,
		},
		{
			name = "StipplePanelL",
			size = Vector3.new(0.02, 0.38, 0.17),
			offset = G * CFrame.new(-0.125, -0.06, -0.02),
			color = STIPPLE,
			material = M.Fabric,
		},
		{
			name = "StipplePanelR",
			size = Vector3.new(0.02, 0.38, 0.17),
			offset = G * CFrame.new(0.125, -0.06, -0.02),
			color = STIPPLE,
			material = M.Fabric,
		},
		{
			name = "GripBasePlate",
			size = Vector3.new(0.26, 0.04, 0.33),
			offset = G * CFrame.new(0, -0.30, -0.005),
			color = POLYMER,
			material = M.Plastic,
		},

		-- Magazine and well
		{
			name = "MagWell",
			size = Vector3.new(0.20, 0.16, 0.34),
			offset = CFrame.new(0, 0.26, -0.66),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "MagWellFlare",
			class = "WedgePart",
			size = Vector3.new(0.20, 0.10, 0.10),
			offset = CFrame.new(0, 0.285, -0.88) * CFrame.Angles(0, 0, math.pi),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "MagUpper",
			size = Vector3.new(0.14, 0.34, 0.26),
			offset = CFrame.new(0, 0.05, -0.66),
			color = MAG_STEEL,
			material = M.Metal,
		},
		{
			name = "MagLower",
			size = Vector3.new(0.14, 0.34, 0.26),
			offset = MG,
			color = MAG_STEEL,
			material = M.Metal,
		},
		{
			name = "MagBasePlate",
			size = Vector3.new(0.17, 0.05, 0.30),
			offset = MG * CFrame.new(0, -0.185, 0),
			color = MAG_STEEL,
			material = M.Metal,
		},
		{
			name = "MagRibL",
			size = Vector3.new(0.02, 0.28, 0.05),
			offset = MG * CFrame.new(-0.075, 0, 0),
			color = MAG_STEEL,
			material = M.Metal,
		},
		{
			name = "MagRibR",
			size = Vector3.new(0.02, 0.28, 0.05),
			offset = MG * CFrame.new(0.075, 0, 0),
			color = MAG_STEEL,
			material = M.Metal,
		},
		{
			name = "MagReleasePaddle",
			size = Vector3.new(0.10, 0.03, 0.06),
			offset = CFrame.new(0, 0.17, -0.485) * CFrame.Angles(math.rad(25), 0, 0),
			color = DARK_STEEL,
			material = M.Metal,
		},
		{
			name = "MagReleaseButton",
			shape = CYL,
			size = Vector3.new(0.03, 0.06, 0.06),
			offset = CFrame.new(0.11, 0.26, -0.55),
			color = DARK_STEEL,
			material = M.Metal,
		},

		-- Collapsed stock
		{
			name = "StockRailL",
			shape = CYL,
			size = RAIL_SIZE,
			offset = CFrame.new(-0.175, 0.50, 0.125) * CYLINDER_Z,
			color = DARK_STEEL,
			material = M.Metal,
		},
		{
			name = "StockRailR",
			shape = CYL,
			size = RAIL_SIZE,
			offset = CFrame.new(0.175, 0.50, 0.125) * CYLINDER_Z,
			color = DARK_STEEL,
			material = M.Metal,
		},
		{
			name = "RailGuideL",
			size = Vector3.new(0.07, 0.10, 0.14),
			offset = CFrame.new(-0.18, 0.50, 0.15),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "RailGuideR",
			size = Vector3.new(0.07, 0.10, 0.14),
			offset = CFrame.new(0.18, 0.50, 0.15),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "ButtPlate",
			size = Vector3.new(0.40, 0.56, 0.06),
			offset = CFrame.new(0, 0.42, 0.55),
			color = DARK_STEEL,
			material = M.Metal,
		},
		{
			name = "ButtPad",
			size = Vector3.new(0.38, 0.54, 0.05),
			offset = CFrame.new(0, 0.42, 0.60),
			color = BUTT_RUBBER,
			material = M.Rubber,
		},
	},
})
