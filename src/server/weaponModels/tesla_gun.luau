-- Tesla Gun: hobbyist handheld solid-state Tesla coil powered by a cordless-tool battery pack.

local WeaponModel = require(script.Parent.Parent.systems.WeaponModel)

local rgb = Color3.fromRGB
local M = Enum.Material
local CZ = WeaponModel.CYLINDER_Z
local CY = WeaponModel.CYLINDER_Y
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball

-- Grip frame: centered under the enclosure, raked 12 degrees (top forward).
local G = CFrame.new(0, -0.05, 0.08) * CFrame.Angles(math.rad(-12), 0, 0)

local ENAMEL = rgb(52, 55, 60)
local DARK_GUNMETAL = rgb(38, 40, 44)
local PANEL_STEEL = rgb(64, 68, 74)
local ALUMINUM = rgb(178, 182, 186)
local BRIGHT_ALUMINUM = rgb(200, 204, 208)
local STEEL = rgb(120, 124, 128)
local CHROME = rgb(210, 212, 215)
local TUNGSTEN = rgb(140, 140, 146)
local BRASS = rgb(181, 148, 74)
local COPPER = rgb(184, 108, 52)
local BRIGHT_COPPER = rgb(201, 125, 70)
local DARK_COPPER = rgb(140, 78, 38)
local BLUE_STEEL = rgb(45, 48, 55)
local BAKELITE = rgb(58, 36, 26)
local PVC_CREAM = rgb(226, 220, 200)
local PORCELAIN = rgb(236, 234, 228)
local WALNUT = rgb(92, 58, 36)
local LEATHER = rgb(70, 48, 34)
local BATTERY_PLASTIC = rgb(34, 35, 38)
local RUBBER_BLACK = rgb(25, 25, 27)
local HV_RED = rgb(170, 30, 28)
local WARN_YELLOW = rgb(230, 186, 30)
local DIAL_CREAM = rgb(238, 232, 212)
local NEEDLE_RED = rgb(190, 30, 30)
local METER_GLASS = rgb(205, 220, 228)
local SHROUD_GLASS = rgb(200, 215, 225)
local LED_GREEN = rgb(80, 255, 120)
local ARC_VIOLET = rgb(150, 120, 255)

local FIN_SIZE = Vector3.new(0.04, 0.3, 0.05)
local SCREW_SIZE = Vector3.new(0.02, 0.05, 0.05)
local STANDOFF_SIZE = Vector3.new(0.86, 0.06, 0.06)
local BAND_SIZE = Vector3.new(0.02, 0.372, 0.372)
local WRAP_SIZE = Vector3.new(0.36, 0.08, 0.52)
local CAP_SIZE = Vector3.new(0.38, 0.06, 0.54)

return WeaponModel.define({
	handle = {
		size = Vector3.new(0.3, 0.7, 0.4),
		color = WALNUT,
		material = M.Wood,
		transparency = 1,
	},
	muzzle = CFrame.new(0, 0.62, -2.1),
	pieces = {
		-- Enclosure
		{
			name = "Body",
			size = Vector3.new(0.6, 0.52, 1.4),
			offset = CFrame.new(0, 0.57, 0.15),
			color = ENAMEL,
			material = M.Metal,
		},
		{
			name = "Deck",
			size = Vector3.new(0.36, 0.1, 1.4),
			offset = CFrame.new(0, 0.88, 0.15),
			color = DARK_GUNMETAL,
			material = M.Metal,
		},
		{
			name = "ChamferL",
			class = "WedgePart",
			size = Vector3.new(1.4, 0.1, 0.12),
			offset = CFrame.new(-0.24, 0.88, 0.15) * CFrame.Angles(0, math.rad(90), 0),
			color = DARK_GUNMETAL,
			material = M.Metal,
		},
		{
			name = "ChamferR",
			class = "WedgePart",
			size = Vector3.new(1.4, 0.1, 0.12),
			offset = CFrame.new(0.24, 0.88, 0.15) * CFrame.Angles(0, math.rad(-90), 0),
			color = DARK_GUNMETAL,
			material = M.Metal,
		},
		{
			name = "FinL1",
			size = FIN_SIZE,
			offset = CFrame.new(-0.32, 0.57, 0.65),
			color = ALUMINUM,
			material = M.Metal,
		},
		{
			name = "FinL2",
			size = FIN_SIZE,
			offset = CFrame.new(-0.32, 0.57, 0.53),
			color = ALUMINUM,
			material = M.Metal,
		},
		{
			name = "FinL3",
			size = FIN_SIZE,
			offset = CFrame.new(-0.32, 0.57, 0.41),
			color = ALUMINUM,
			material = M.Metal,
		},
		{
			name = "FinR1",
			size = FIN_SIZE,
			offset = CFrame.new(0.32, 0.57, 0.65),
			color = ALUMINUM,
			material = M.Metal,
		},
		{
			name = "FinR2",
			size = FIN_SIZE,
			offset = CFrame.new(0.32, 0.57, 0.53),
			color = ALUMINUM,
			material = M.Metal,
		},
		{
			name = "FinR3",
			size = FIN_SIZE,
			offset = CFrame.new(0.32, 0.57, 0.41),
			color = ALUMINUM,
			material = M.Metal,
		},
		{
			name = "PanelL",
			size = Vector3.new(0.02, 0.36, 0.7),
			offset = CFrame.new(-0.31, 0.57, -0.1),
			color = PANEL_STEEL,
			material = M.Metal,
		},
		{
			name = "PanelR",
			size = Vector3.new(0.02, 0.36, 0.7),
			offset = CFrame.new(0.31, 0.57, -0.1),
			color = PANEL_STEEL,
			material = M.Metal,
		},
		{
			name = "ScrewL_A",
			shape = CYL,
			size = SCREW_SIZE,
			offset = CFrame.new(-0.33, 0.57, 0.2),
			color = STEEL,
			material = M.Metal,
		},
		{
			name = "ScrewL_B",
			shape = CYL,
			size = SCREW_SIZE,
			offset = CFrame.new(-0.33, 0.57, -0.4),
			color = STEEL,
			material = M.Metal,
		},
		{
			name = "ScrewR_A",
			shape = CYL,
			size = SCREW_SIZE,
			offset = CFrame.new(0.33, 0.57, 0.2),
			color = STEEL,
			material = M.Metal,
		},
		{
			name = "ScrewR_B",
			shape = CYL,
			size = SCREW_SIZE,
			offset = CFrame.new(0.33, 0.57, -0.4),
			color = STEEL,
			material = M.Metal,
		},
		{
			name = "WarnLabel",
			size = Vector3.new(0.012, 0.14, 0.24),
			offset = CFrame.new(0.326, 0.57, -0.1),
			color = WARN_YELLOW,
			material = M.SmoothPlastic,
		},

		-- Battery pack
		{
			name = "BatteryPack",
			size = Vector3.new(0.5, 0.44, 0.2),
			offset = CFrame.new(0, 0.6, 0.95),
			color = BATTERY_PLASTIC,
			material = M.Plastic,
		},
		{
			name = "StatusLED",
			size = Vector3.new(0.05, 0.05, 0.02),
			offset = CFrame.new(0.14, 0.7, 1.055),
			color = LED_GREEN,
			material = M.Neon,
		},

		-- Voltmeter (bezel y 0.93-0.99; dial and glass seat into it)
		{
			name = "MeterBezel",
			shape = CYL,
			size = Vector3.new(0.06, 0.3, 0.3),
			offset = CFrame.new(0, 0.96, 0.45) * CY,
			color = CHROME,
			material = M.Metal,
			reflectance = 0.2,
		},
		{
			name = "MeterDial",
			shape = CYL,
			size = Vector3.new(0.01, 0.24, 0.24),
			offset = CFrame.new(0, 1.0, 0.45) * CY,
			color = DIAL_CREAM,
			material = M.SmoothPlastic,
		},
		{
			name = "MeterNeedle",
			size = Vector3.new(0.015, 0.008, 0.1),
			offset = CFrame.new(0, 1.009, 0.45)
				* CFrame.Angles(0, math.rad(35), 0)
				* CFrame.new(0, 0, -0.05),
			color = NEEDLE_RED,
			material = M.SmoothPlastic,
		},
		{
			name = "MeterGlass",
			shape = CYL,
			size = Vector3.new(0.05, 0.29, 0.29),
			offset = CFrame.new(0, 1.01, 0.45) * CY,
			color = METER_GLASS,
			material = M.Glass,
			transparency = 0.7,
		},

		-- Toggle switch
		{
			name = "ToggleBase",
			size = Vector3.new(0.12, 0.04, 0.12),
			offset = CFrame.new(-0.1, 0.95, -0.15),
			color = STEEL,
			material = M.Metal,
		},
		{
			name = "ToggleLever",
			shape = CYL,
			size = Vector3.new(0.16, 0.04, 0.04),
			offset = CFrame.new(-0.1, 1.02, -0.18) * CFrame.Angles(math.rad(-25), 0, 0) * CY,
			color = CHROME,
			material = M.Metal,
			reflectance = 0.2,
		},

		-- HV lead
		{
			name = "CableGland",
			shape = CYL,
			size = Vector3.new(0.08, 0.11, 0.11),
			offset = CFrame.new(0.12, 0.97, -0.25) * CY,
			color = RUBBER_BLACK,
			material = M.Rubber,
		},
		{
			name = "HVCable",
			shape = CYL,
			size = Vector3.new(0.23, 0.07, 0.07),
			offset = CFrame.new(0.12, 0.965, -0.365) * CZ,
			color = HV_RED,
			material = M.Rubber,
		},
		{
			name = "Feedthrough",
			shape = CYL,
			size = Vector3.new(0.08, 0.12, 0.12),
			offset = CFrame.new(0.12, 0.965, -0.52) * CZ,
			color = PORCELAIN,
			material = M.SmoothPlastic,
			reflectance = 0.05,
		},

		-- Pistol grip
		{
			name = "GripCore",
			size = Vector3.new(0.34, 0.85, 0.5),
			offset = G,
			color = WALNUT,
			material = M.Wood,
		},
		{
			name = "GripWrapUpper",
			size = WRAP_SIZE,
			offset = G * CFrame.new(0, 0.12, 0),
			color = LEATHER,
			material = M.Leather,
		},
		{
			name = "GripWrapLower",
			size = WRAP_SIZE,
			offset = G * CFrame.new(0, -0.16, 0),
			color = LEATHER,
			material = M.Leather,
		},
		{
			name = "GripCollar",
			size = CAP_SIZE,
			offset = G * CFrame.new(0, 0.33, 0),
			color = BRASS,
			material = M.Metal,
		},
		{
			name = "ButtCap",
			size = CAP_SIZE,
			offset = G * CFrame.new(0, -0.455, 0),
			color = BRASS,
			material = M.Metal,
		},

		-- Trigger group
		{
			name = "GuardBar",
			size = Vector3.new(0.08, 0.05, 0.42),
			offset = CFrame.new(0, 0.02, -0.35),
			color = BRASS,
			material = M.Metal,
		},
		{
			name = "GuardPost",
			size = Vector3.new(0.08, 0.29, 0.05),
			offset = CFrame.new(0, 0.165, -0.53),
			color = BRASS,
			material = M.Metal,
		},
		{
			name = "Trigger",
			size = Vector3.new(0.07, 0.24, 0.07),
			offset = CFrame.new(0, 0.2, -0.3) * CFrame.Angles(math.rad(15), 0, 0),
			color = BLUE_STEEL,
			material = M.Metal,
		},

		-- Coil section (between bulkhead faces z -0.65 and -1.51)
		{
			name = "RearBulkhead",
			shape = CYL,
			size = Vector3.new(0.1, 0.9, 0.9),
			offset = CFrame.new(0, 0.62, -0.6) * CZ,
			color = BAKELITE,
			material = M.SmoothPlastic,
		},
		{
			name = "FrontBulkhead",
			shape = CYL,
			size = Vector3.new(0.08, 0.9, 0.9),
			offset = CFrame.new(0, 0.62, -1.55) * CZ,
			color = BAKELITE,
			material = M.SmoothPlastic,
		},
		{
			name = "Standoff1",
			shape = CYL,
			size = STANDOFF_SIZE,
			offset = CFrame.new(0.233, 0.853, -1.08) * CZ,
			color = BRASS,
			material = M.Metal,
		},
		{
			name = "Standoff2",
			shape = CYL,
			size = STANDOFF_SIZE,
			offset = CFrame.new(-0.233, 0.853, -1.08) * CZ,
			color = BRASS,
			material = M.Metal,
		},
		{
			name = "Standoff3",
			shape = CYL,
			size = STANDOFF_SIZE,
			offset = CFrame.new(0.233, 0.387, -1.08) * CZ,
			color = BRASS,
			material = M.Metal,
		},
		{
			name = "Standoff4",
			shape = CYL,
			size = STANDOFF_SIZE,
			offset = CFrame.new(-0.233, 0.387, -1.08) * CZ,
			color = BRASS,
			material = M.Metal,
		},
		{
			name = "Primary",
			shape = CYL,
			size = Vector3.new(0.22, 0.46, 0.46),
			offset = CFrame.new(0, 0.62, -0.76) * CZ,
			color = BRIGHT_COPPER,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "Secondary",
			shape = CYL,
			size = Vector3.new(0.86, 0.36, 0.36),
			offset = CFrame.new(0, 0.62, -1.08) * CZ,
			color = COPPER,
			material = M.Metal,
		},
		{
			name = "WindingBand1",
			shape = CYL,
			size = BAND_SIZE,
			offset = CFrame.new(0, 0.62, -0.98) * CZ,
			color = DARK_COPPER,
			material = M.Metal,
		},
		{
			name = "WindingBand2",
			shape = CYL,
			size = BAND_SIZE,
			offset = CFrame.new(0, 0.62, -1.12) * CZ,
			color = DARK_COPPER,
			material = M.Metal,
		},
		{
			name = "WindingBand3",
			shape = CYL,
			size = BAND_SIZE,
			offset = CFrame.new(0, 0.62, -1.26) * CZ,
			color = DARK_COPPER,
			material = M.Metal,
		},
		{
			name = "WindingBand4",
			shape = CYL,
			size = BAND_SIZE,
			offset = CFrame.new(0, 0.62, -1.40) * CZ,
			color = DARK_COPPER,
			material = M.Metal,
		},
		{
			name = "FormerCap",
			shape = CYL,
			size = Vector3.new(0.04, 0.4, 0.4),
			offset = CFrame.new(0, 0.62, -1.49) * CZ,
			color = PVC_CREAM,
			material = M.SmoothPlastic,
		},
		{
			name = "Shroud",
			shape = CYL,
			size = Vector3.new(0.87, 0.86, 0.86),
			offset = CFrame.new(0, 0.62, -1.08) * CZ,
			color = SHROUD_GLASS,
			material = M.Glass,
			transparency = 0.75,
		},

		-- Under-rail and foregrip
		{
			name = "UnderRail",
			size = Vector3.new(0.14, 0.08, 1.04),
			offset = CFrame.new(0, 0.14, -1.07),
			color = ALUMINUM,
			material = M.Metal,
		},
		{
			name = "Foregrip",
			size = Vector3.new(0.24, 0.5, 0.28),
			offset = CFrame.new(0, -0.15, -1.1),
			color = WALNUT,
			material = M.Wood,
		},

		-- Top-load and breakout
		{
			name = "ToroidStem",
			shape = CYL,
			size = Vector3.new(0.08, 0.14, 0.14),
			offset = CFrame.new(0, 0.62, -1.63) * CZ,
			color = BRASS,
			material = M.Metal,
		},
		{
			name = "ToroidFlank",
			shape = CYL,
			size = Vector3.new(0.26, 0.85, 0.85),
			offset = CFrame.new(0, 0.62, -1.78) * CZ,
			color = ALUMINUM,
			material = M.Metal,
		},
		{
			name = "ToroidCore",
			shape = CYL,
			size = Vector3.new(0.14, 0.95, 0.95),
			offset = CFrame.new(0, 0.62, -1.78) * CZ,
			color = BRIGHT_ALUMINUM,
			material = M.Metal,
		},
		{
			name = "Electrode",
			shape = CYL,
			size = Vector3.new(0.14, 0.05, 0.05),
			offset = CFrame.new(0, 0.62, -1.97) * CZ,
			color = TUNGSTEN,
			material = M.Metal,
		},
		{
			name = "SparkTip",
			shape = BALL,
			size = Vector3.new(0.09, 0.09, 0.09),
			offset = CFrame.new(0, 0.62, -2.05),
			color = ARC_VIOLET,
			material = M.Neon,
		},
		{
			name = "Corona",
			shape = BALL,
			size = Vector3.new(0.24, 0.24, 0.24),
			offset = CFrame.new(0, 0.62, -2.05),
			color = ARC_VIOLET,
			material = M.ForceField,
			transparency = 0.4,
		},
	},
})
