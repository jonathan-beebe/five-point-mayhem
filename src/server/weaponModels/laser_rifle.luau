-- Laser Rifle: AR-15-pattern carbine (Picatinny upper, Aimpoint-style tube optic, adjustable stock) with a finned directed-energy emitter in place of the barrel.

local WeaponModel = require(script.Parent.Parent.systems.WeaponModel)

local rgb = Color3.fromRGB
local M = Enum.Material
local rad = math.rad
local CYLINDER_Z = WeaponModel.CYLINDER_Z
local CYLINDER_Y = WeaponModel.CYLINDER_Y
local CYL = Enum.PartType.Cylinder

-- Wedge orientations (WedgePart default: full-height face at local +Z, flat face at local -Y).
local RY_L = CFrame.Angles(0, rad(90), 0) -- full-height side toward +X: chamfers on left edges
local RY_R = CFrame.Angles(0, rad(-90), 0) -- full-height side toward -X: chamfers on right edges
local RZ_180 = CFrame.Angles(0, 0, rad(180)) -- flat face on top: bottom edges

-- Sub-assembly frames.
local GRIP = CFrame.new(0, -0.15, 0.06) * CFrame.Angles(rad(-15), 0, 0)
local BATTERY = CFrame.new(0, -0.24, -0.87) * CFrame.Angles(rad(8), 0, 0)

local GUNMETAL = rgb(58, 60, 64)
local POLYMER = rgb(32, 33, 35)
local GRIP_RUBBER = rgb(22, 22, 24)
local DARK_STEEL = rgb(44, 45, 48)
local BARE_STEEL = rgb(140, 142, 146)
local MAGENTA_ANODIZED = rgb(170, 35, 135)
local COPPER = rgb(160, 95, 55)
local EMITTER_NEON = rgb(255, 60, 200)
local EMITTER_LENS = rgb(255, 150, 230)
local OPTIC_GLASS = rgb(60, 40, 70)

local RAIL_TOOTH = Vector3.new(0.24, 0.04, 0.07)
local OPTIC_RING = Vector3.new(0.06, 0.30, 0.30)
local OPTIC_LENS = Vector3.new(0.02, 0.22, 0.22)
local HG_WEDGE = Vector3.new(1.20, 0.06, 0.08)
local VENT = Vector3.new(0.02, 0.10, 0.34)
local FIN = Vector3.new(0.04, 0.38, 0.38)

return WeaponModel.define({
	handle = {
		size = Vector3.new(0.3, 0.8, 0.42),
		color = GRIP_RUBBER,
		material = M.Rubber,
		transparency = 1,
	},
	muzzle = CFrame.new(0, 0.47, -3.19),
	pieces = {
		-- Grip
		{
			name = "GripCore",
			size = Vector3.new(0.30, 0.80, 0.42),
			offset = GRIP,
			color = POLYMER,
			material = M.SmoothPlastic,
		},
		{
			name = "GripPanelL",
			size = Vector3.new(0.03, 0.58, 0.32),
			offset = GRIP * CFrame.new(-0.155, -0.05, 0.02),
			color = GRIP_RUBBER,
			material = M.Rubber,
		},
		{
			name = "GripPanelR",
			size = Vector3.new(0.03, 0.58, 0.32),
			offset = GRIP * CFrame.new(0.155, -0.05, 0.02),
			color = GRIP_RUBBER,
			material = M.Rubber,
		},
		{
			name = "GripCap",
			size = Vector3.new(0.32, 0.05, 0.46),
			offset = GRIP * CFrame.new(0, -0.42, 0.01),
			color = POLYMER,
			material = M.SmoothPlastic,
		},

		-- Trigger group
		{
			name = "GuardBottom",
			size = Vector3.new(0.08, 0.04, 0.51),
			offset = CFrame.new(0, -0.12, -0.355),
			color = POLYMER,
			material = M.SmoothPlastic,
		},
		{
			name = "GuardFront",
			size = Vector3.new(0.08, 0.30, 0.04),
			offset = CFrame.new(0, 0.01, -0.59),
			color = POLYMER,
			material = M.SmoothPlastic,
		},
		{
			name = "Trigger",
			size = Vector3.new(0.05, 0.24, 0.06),
			offset = CFrame.new(0, 0.04, -0.34) * CFrame.Angles(rad(12), 0, 0),
			color = MAGENTA_ANODIZED,
			material = M.Metal,
		},
		{
			name = "Selector",
			shape = CYL,
			size = Vector3.new(0.03, 0.08, 0.08),
			offset = CFrame.new(0.21, 0.25, -0.12),
			color = MAGENTA_ANODIZED,
			material = M.Metal,
		},

		-- Lower receiver and battery
		{
			name = "LowerReceiver",
			size = Vector3.new(0.40, 0.24, 1.40),
			offset = CFrame.new(0, 0.26, -0.40),
			color = POLYMER,
			material = M.SmoothPlastic,
		},
		{
			name = "MagWell",
			size = Vector3.new(0.30, 0.18, 0.42),
			offset = CFrame.new(0, 0.06, -0.85),
			color = POLYMER,
			material = M.SmoothPlastic,
		},
		{
			name = "Battery",
			size = Vector3.new(0.26, 0.55, 0.38),
			offset = BATTERY,
			color = POLYMER,
			material = M.SmoothPlastic,
		},
		{
			name = "BatteryBase",
			size = Vector3.new(0.30, 0.06, 0.42),
			offset = BATTERY * CFrame.new(0, -0.29, 0),
			color = DARK_STEEL,
			material = M.Metal,
		},
		{
			name = "ChargeGauge",
			size = Vector3.new(0.28, 0.30, 0.04),
			offset = BATTERY * CFrame.new(0, -0.05, 0.10),
			color = EMITTER_NEON,
			material = M.Neon,
		},
		{
			name = "MagRelease",
			size = Vector3.new(0.03, 0.06, 0.06),
			offset = CFrame.new(0.21, 0.22, -0.62),
			color = BARE_STEEL,
			material = M.Metal,
		},

		-- Upper receiver
		{
			name = "UpperReceiver",
			size = Vector3.new(0.42, 0.30, 1.80),
			offset = CFrame.new(0, 0.52, -0.60),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "TopDeck",
			size = Vector3.new(0.26, 0.06, 1.80),
			offset = CFrame.new(0, 0.70, -0.60),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "ChamferL",
			class = "WedgePart",
			size = Vector3.new(1.80, 0.06, 0.08),
			offset = CFrame.new(-0.17, 0.70, -0.60) * RY_L,
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "ChamferR",
			class = "WedgePart",
			size = Vector3.new(1.80, 0.06, 0.08),
			offset = CFrame.new(0.17, 0.70, -0.60) * RY_R,
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "RailBase",
			size = Vector3.new(0.20, 0.06, 1.30),
			offset = CFrame.new(0, 0.76, -0.55),
			color = DARK_STEEL,
			material = M.Metal,
		},
		{
			name = "RailTooth1",
			size = RAIL_TOOTH,
			offset = CFrame.new(0, 0.81, 0.00),
			color = DARK_STEEL,
			material = M.Metal,
		},
		{
			name = "RailTooth2",
			size = RAIL_TOOTH,
			offset = CFrame.new(0, 0.81, -0.28),
			color = DARK_STEEL,
			material = M.Metal,
		},
		{
			name = "RailTooth3",
			size = RAIL_TOOTH,
			offset = CFrame.new(0, 0.81, -0.56),
			color = DARK_STEEL,
			material = M.Metal,
		},
		{
			name = "RailTooth4",
			size = RAIL_TOOTH,
			offset = CFrame.new(0, 0.81, -0.84),
			color = DARK_STEEL,
			material = M.Metal,
		},
		{
			name = "RailTooth5",
			size = RAIL_TOOTH,
			offset = CFrame.new(0, 0.81, -1.12),
			color = DARK_STEEL,
			material = M.Metal,
		},
		{
			name = "ChargingHandle",
			size = Vector3.new(0.30, 0.07, 0.10),
			offset = CFrame.new(0, 0.64, 0.34),
			color = MAGENTA_ANODIZED,
			material = M.Metal,
		},
		{
			name = "PowerDoorR",
			size = Vector3.new(0.02, 0.14, 0.40),
			offset = CFrame.new(0.215, 0.52, -0.45),
			color = POLYMER,
			material = M.SmoothPlastic,
		},
		{
			name = "IndicatorBezelL",
			size = Vector3.new(0.02, 0.10, 0.48),
			offset = CFrame.new(-0.215, 0.52, -0.45),
			color = POLYMER,
			material = M.SmoothPlastic,
		},
		{
			name = "IndicatorStripL",
			size = Vector3.new(0.02, 0.04, 0.40),
			offset = CFrame.new(-0.23, 0.52, -0.45),
			color = EMITTER_NEON,
			material = M.Neon,
		},

		-- Optic
		{
			name = "OpticMount",
			size = Vector3.new(0.16, 0.165, 0.30),
			offset = CFrame.new(0, 0.8625, -0.36),
			color = DARK_STEEL,
			material = M.Metal,
		},
		{
			name = "OpticTube",
			shape = CYL,
			size = Vector3.new(0.50, 0.26, 0.26),
			offset = CFrame.new(0, 1.06, -0.36) * CYLINDER_Z,
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "OpticRingRear",
			shape = CYL,
			size = OPTIC_RING,
			offset = CFrame.new(0, 1.06, -0.15) * CYLINDER_Z,
			color = DARK_STEEL,
			material = M.Metal,
		},
		{
			name = "OpticRingFront",
			shape = CYL,
			size = OPTIC_RING,
			offset = CFrame.new(0, 1.06, -0.57) * CYLINDER_Z,
			color = DARK_STEEL,
			material = M.Metal,
		},
		{
			name = "OpticLensRear",
			shape = CYL,
			size = OPTIC_LENS,
			offset = CFrame.new(0, 1.06, -0.10) * CYLINDER_Z,
			color = OPTIC_GLASS,
			material = M.Glass,
			transparency = 0.25,
			reflectance = 0.4,
		},
		{
			name = "OpticLensFront",
			shape = CYL,
			size = OPTIC_LENS,
			offset = CFrame.new(0, 1.06, -0.62) * CYLINDER_Z,
			color = OPTIC_GLASS,
			material = M.Glass,
			transparency = 0.25,
			reflectance = 0.4,
		},
		{
			name = "TurretTop",
			shape = CYL,
			size = Vector3.new(0.08, 0.10, 0.10),
			offset = CFrame.new(0, 1.21, -0.36) * CYLINDER_Y,
			color = DARK_STEEL,
			material = M.Metal,
		},
		{
			name = "TurretSide",
			shape = CYL,
			size = Vector3.new(0.08, 0.10, 0.10),
			offset = CFrame.new(0.155, 1.06, -0.36),
			color = DARK_STEEL,
			material = M.Metal,
		},

		-- Stock
		{
			name = "BufferTube",
			shape = CYL,
			size = Vector3.new(0.60, 0.18, 0.18),
			offset = CFrame.new(0, 0.50, 0.55) * CYLINDER_Z,
			color = DARK_STEEL,
			material = M.Metal,
		},
		{
			name = "StockBody",
			size = Vector3.new(0.30, 0.42, 0.40),
			offset = CFrame.new(0, 0.42, 0.80),
			color = POLYMER,
			material = M.SmoothPlastic,
		},
		{
			name = "StockToe",
			class = "WedgePart",
			size = Vector3.new(0.30, 0.20, 0.34),
			offset = CFrame.new(0, 0.115, 0.83) * RZ_180,
			color = POLYMER,
			material = M.SmoothPlastic,
		},
		{
			name = "ButtPad",
			size = Vector3.new(0.32, 0.64, 0.05),
			offset = CFrame.new(0, 0.32, 1.025),
			color = GRIP_RUBBER,
			material = M.Rubber,
		},
		{
			name = "CheekRest",
			size = Vector3.new(0.24, 0.06, 0.36),
			offset = CFrame.new(0, 0.66, 0.80),
			color = POLYMER,
			material = M.SmoothPlastic,
		},

		-- Handguard (octagonal section)
		{
			name = "HGCore",
			size = Vector3.new(0.44, 0.28, 1.20),
			offset = CFrame.new(0, 0.47, -2.05),
			color = POLYMER,
			material = M.SmoothPlastic,
		},
		{
			name = "HGTop",
			size = Vector3.new(0.28, 0.06, 1.20),
			offset = CFrame.new(0, 0.64, -2.05),
			color = POLYMER,
			material = M.SmoothPlastic,
		},
		{
			name = "HGBottom",
			size = Vector3.new(0.28, 0.06, 1.20),
			offset = CFrame.new(0, 0.30, -2.05),
			color = POLYMER,
			material = M.SmoothPlastic,
		},
		{
			name = "HGWedgeTL",
			class = "WedgePart",
			size = HG_WEDGE,
			offset = CFrame.new(-0.18, 0.64, -2.05) * RY_L,
			color = POLYMER,
			material = M.SmoothPlastic,
		},
		{
			name = "HGWedgeTR",
			class = "WedgePart",
			size = HG_WEDGE,
			offset = CFrame.new(0.18, 0.64, -2.05) * RY_R,
			color = POLYMER,
			material = M.SmoothPlastic,
		},
		{
			name = "HGWedgeBL",
			class = "WedgePart",
			size = HG_WEDGE,
			offset = CFrame.new(-0.18, 0.30, -2.05) * RY_L * RZ_180,
			color = POLYMER,
			material = M.SmoothPlastic,
		},
		{
			name = "HGWedgeBR",
			class = "WedgePart",
			size = HG_WEDGE,
			offset = CFrame.new(0.18, 0.30, -2.05) * RY_R * RZ_180,
			color = POLYMER,
			material = M.SmoothPlastic,
		},
		{
			name = "VentL1",
			size = VENT,
			offset = CFrame.new(-0.225, 0.47, -1.80),
			color = COPPER,
			material = M.Metal,
		},
		{
			name = "VentL2",
			size = VENT,
			offset = CFrame.new(-0.225, 0.47, -2.30),
			color = COPPER,
			material = M.Metal,
		},
		{
			name = "VentR1",
			size = VENT,
			offset = CFrame.new(0.225, 0.47, -1.80),
			color = COPPER,
			material = M.Metal,
		},
		{
			name = "VentR2",
			size = VENT,
			offset = CFrame.new(0.225, 0.47, -2.30),
			color = COPPER,
			material = M.Metal,
		},

		-- Emitter
		{
			name = "EmitterShroud",
			shape = CYL,
			size = Vector3.new(0.43, 0.30, 0.30),
			offset = CFrame.new(0, 0.47, -2.835) * CYLINDER_Z,
			color = DARK_STEEL,
			material = M.Metal,
		},
		{
			name = "CoolingFin1",
			shape = CYL,
			size = FIN,
			offset = CFrame.new(0, 0.47, -2.72) * CYLINDER_Z,
			color = DARK_STEEL,
			material = M.Metal,
		},
		{
			name = "CoolingFin2",
			shape = CYL,
			size = FIN,
			offset = CFrame.new(0, 0.47, -2.80) * CYLINDER_Z,
			color = DARK_STEEL,
			material = M.Metal,
		},
		{
			name = "CoolingFin3",
			shape = CYL,
			size = FIN,
			offset = CFrame.new(0, 0.47, -2.88) * CYLINDER_Z,
			color = DARK_STEEL,
			material = M.Metal,
		},
		{
			name = "CoolingFin4",
			shape = CYL,
			size = FIN,
			offset = CFrame.new(0, 0.47, -2.96) * CYLINDER_Z,
			color = DARK_STEEL,
			material = M.Metal,
		},
		{
			name = "EmitterBell",
			shape = CYL,
			size = Vector3.new(0.10, 0.36, 0.36),
			offset = CFrame.new(0, 0.47, -3.09) * CYLINDER_Z,
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "EmitterCore",
			shape = CYL,
			size = Vector3.new(0.02, 0.18, 0.18),
			offset = CFrame.new(0, 0.47, -3.145) * CYLINDER_Z,
			color = EMITTER_NEON,
			material = M.Neon,
		},
		{
			name = "EmitterLens",
			shape = CYL,
			size = Vector3.new(0.03, 0.26, 0.26),
			offset = CFrame.new(0, 0.47, -3.16) * CYLINDER_Z,
			color = EMITTER_LENS,
			material = M.Glass,
			transparency = 0.35,
			reflectance = 0.3,
		},
	},
})
