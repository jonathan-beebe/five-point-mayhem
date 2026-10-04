-- Freeze Ray: handheld liquid-nitrogen cryogenic sprayer (Brymill Cry-Ac style) on a pistol frame.

local WeaponModel = require(script.Parent.Parent.systems.WeaponModel)

local rgb = Color3.fromRGB
local M = Enum.Material
local CYLINDER_Z = WeaponModel.CYLINDER_Z
local CYLINDER_Y = WeaponModel.CYLINDER_Y
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball

-- Wedge orientations (WedgePart default: right angle at local (ymin, zmax), length along local X).
local SIDE_R = CFrame.Angles(0, -math.pi / 2, 0) -- length along Z, slope facing +X and up
local SIDE_L = CFrame.Angles(0, math.pi / 2, 0) -- length along Z, slope facing -X and up

-- Grip frame: top raked forward toward -Z.
local G = CFrame.new(0, -0.15, 0.1) * CFrame.Angles(math.rad(-12), 0, 0)

local ICE_ANODIZED = rgb(96, 150, 180)
local STAINLESS = rgb(175, 180, 186)
local FIN_ALUMINUM = rgb(200, 205, 210)
local GUNMETAL = rgb(58, 62, 68)
local PANEL_LINE = rgb(28, 30, 34)
local POLYMER = rgb(34, 36, 40)
local GRIP_RUBBER = rgb(22, 22, 24)
local COPPER = rgb(170, 105, 65)
local BRASS = rgb(181, 148, 82)
local CRYO_GLOW = rgb(130, 220, 255)
local TANK_GLASS = rgb(210, 235, 245)
local LENS_GLASS = rgb(200, 235, 250)
local FROST = rgb(225, 242, 250)
local GAUGE_FACE = rgb(235, 235, 230)
local NEEDLE_RED = rgb(190, 30, 30)
local HAZARD_YELLOW = rgb(215, 175, 45)

local BUMP_SIZE = Vector3.new(0.30, 0.11, 0.11)
local SCREW_SIZE = Vector3.new(0.44, 0.05, 0.05)
local FIN_SIZE = Vector3.new(0.05, 0.50, 0.50)

return WeaponModel.define({
	handle = {
		size = Vector3.new(0.4, 0.4, 1.2),
		color = POLYMER,
		material = M.Plastic,
		transparency = 1,
	},
	muzzle = CFrame.new(0, 0.5, -3.0),
	pieces = {
		-- Grip
		{
			name = "GripCore",
			size = Vector3.new(0.32, 1.00, 0.44),
			offset = G,
			color = POLYMER,
			material = M.Plastic,
		},
		{
			name = "GripPanels",
			size = Vector3.new(0.345, 0.66, 0.34),
			offset = G * CFrame.new(0, -0.08, 0.02),
			color = GRIP_RUBBER,
			material = M.Rubber,
		},
		{
			name = "FingerBump1",
			shape = CYL,
			size = BUMP_SIZE,
			offset = G * CFrame.new(0, 0, -0.22),
			color = GRIP_RUBBER,
			material = M.Rubber,
		},
		{
			name = "FingerBump2",
			shape = CYL,
			size = BUMP_SIZE,
			offset = G * CFrame.new(0, -0.17, -0.22),
			color = GRIP_RUBBER,
			material = M.Rubber,
		},
		{
			name = "FingerBump3",
			shape = CYL,
			size = BUMP_SIZE,
			offset = G * CFrame.new(0, -0.34, -0.22),
			color = GRIP_RUBBER,
			material = M.Rubber,
		},
		{
			name = "GripBasePlate",
			size = Vector3.new(0.36, 0.08, 0.48),
			offset = G * CFrame.new(0, -0.53, 0),
			color = GUNMETAL,
			material = M.Metal,
		},

		-- Trigger group
		{
			name = "GuardBottom",
			size = Vector3.new(0.08, 0.05, 0.64),
			offset = CFrame.new(0, -0.12, -0.40),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "GuardFront",
			size = Vector3.new(0.08, 0.405, 0.06),
			offset = CFrame.new(0, 0.0575, -0.72),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "Trigger",
			size = Vector3.new(0.06, 0.32, 0.07),
			offset = CFrame.new(0, 0.13, -0.38) * CFrame.Angles(math.rad(15), 0, 0),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "TriggerPin",
			shape = CYL,
			size = SCREW_SIZE,
			offset = CFrame.new(0, 0.30, -0.38),
			color = STAINLESS,
			material = M.Metal,
		},

		-- Receiver
		{
			name = "ReceiverBody",
			size = Vector3.new(0.42, 0.42, 1.80),
			offset = CFrame.new(0, 0.46, -0.45),
			color = ICE_ANODIZED,
			material = M.Metal,
		},
		{
			name = "ReceiverDeck",
			size = Vector3.new(0.26, 0.08, 1.80),
			offset = CFrame.new(0, 0.71, -0.45),
			color = ICE_ANODIZED,
			material = M.Metal,
		},
		{
			name = "ChamferRight",
			class = "WedgePart",
			size = Vector3.new(1.80, 0.08, 0.08),
			offset = CFrame.new(0.17, 0.71, -0.45) * SIDE_R,
			color = ICE_ANODIZED,
			material = M.Metal,
		},
		{
			name = "ChamferLeft",
			class = "WedgePart",
			size = Vector3.new(1.80, 0.08, 0.08),
			offset = CFrame.new(-0.17, 0.71, -0.45) * SIDE_L,
			color = ICE_ANODIZED,
			material = M.Metal,
		},
		{
			name = "RearPlate",
			size = Vector3.new(0.44, 0.52, 0.04),
			offset = CFrame.new(0, 0.50, 0.47),
			color = STAINLESS,
			material = M.Metal,
		},
		{
			name = "RearValveStem",
			shape = CYL,
			size = Vector3.new(0.11, 0.20, 0.20),
			offset = CFrame.new(0, 0.50, 0.535) * CYLINDER_Z,
			color = STAINLESS,
			material = M.Metal,
		},
		{
			name = "RearKnob",
			shape = CYL,
			size = Vector3.new(0.06, 0.26, 0.26),
			offset = CFrame.new(0, 0.50, 0.62) * CYLINDER_Z,
			color = GRIP_RUBBER,
			material = M.Rubber,
		},
		{
			name = "PanelLineH",
			size = Vector3.new(0.43, 0.02, 1.05),
			offset = CFrame.new(0, 0.42, -0.675),
			color = PANEL_LINE,
			material = M.SmoothPlastic,
		},
		{
			name = "PanelLineV",
			size = Vector3.new(0.43, 0.38, 0.02),
			offset = CFrame.new(0, 0.46, -0.10),
			color = PANEL_LINE,
			material = M.SmoothPlastic,
		},
		{
			name = "ScrewRearLow",
			shape = CYL,
			size = SCREW_SIZE,
			offset = CFrame.new(0, 0.32, 0.35),
			color = STAINLESS,
			material = M.Metal,
		},
		{
			name = "ScrewRearHigh",
			shape = CYL,
			size = SCREW_SIZE,
			offset = CFrame.new(0, 0.60, 0.35),
			color = STAINLESS,
			material = M.Metal,
		},
		{
			name = "ScrewFrontLow",
			shape = CYL,
			size = SCREW_SIZE,
			offset = CFrame.new(0, 0.32, -1.25),
			color = STAINLESS,
			material = M.Metal,
		},
		{
			name = "ScrewFrontHigh",
			shape = CYL,
			size = SCREW_SIZE,
			offset = CFrame.new(0, 0.60, -1.25),
			color = STAINLESS,
			material = M.Metal,
		},
		{
			name = "StatusLED",
			shape = BALL,
			size = Vector3.new(0.06, 0.06, 0.06),
			offset = CFrame.new(-0.205, 0.60, 0.15),
			color = CRYO_GLOW,
			material = M.Neon,
		},
		{
			name = "HazardLabel",
			size = Vector3.new(0.02, 0.12, 0.30),
			offset = CFrame.new(-0.215, 0.55, -0.70),
			color = HAZARD_YELLOW,
			material = M.SmoothPlastic,
		},

		-- Pressure gauge, right side
		{
			name = "GaugeBezel",
			shape = CYL,
			size = Vector3.new(0.06, 0.26, 0.26),
			offset = CFrame.new(0.24, 0.55, 0.15),
			color = STAINLESS,
			material = M.Metal,
		},
		{
			name = "GaugeFace",
			shape = CYL,
			size = Vector3.new(0.02, 0.20, 0.20),
			offset = CFrame.new(0.28, 0.55, 0.15),
			color = GAUGE_FACE,
			material = M.SmoothPlastic,
		},
		{
			name = "GaugeNeedle",
			size = Vector3.new(0.01, 0.015, 0.08),
			offset = CFrame.new(0.295, 0.55, 0.15)
				* CFrame.Angles(math.rad(35), 0, 0)
				* CFrame.new(0, 0, -0.03),
			color = NEEDLE_RED,
			material = M.SmoothPlastic,
		},
		{
			name = "GaugeGlass",
			shape = CYL,
			size = Vector3.new(0.01, 0.22, 0.22),
			offset = CFrame.new(0.305, 0.55, 0.15),
			color = LENS_GLASS,
			material = M.Glass,
			transparency = 0.6,
		},

		-- Coolant tank, top
		{
			name = "TankGlass",
			shape = CYL,
			size = Vector3.new(1.10, 0.26, 0.26),
			offset = CFrame.new(0, 0.92, -0.50) * CYLINDER_Z,
			color = TANK_GLASS,
			material = M.Glass,
			transparency = 0.6,
			reflectance = 0.1,
		},
		{
			name = "TankCore",
			shape = CYL,
			size = Vector3.new(1.00, 0.16, 0.16),
			offset = CFrame.new(0, 0.92, -0.50) * CYLINDER_Z,
			color = CRYO_GLOW,
			material = M.Neon,
			transparency = 0.15,
		},
		{
			name = "TankCapRear",
			shape = CYL,
			size = Vector3.new(0.08, 0.30, 0.30),
			offset = CFrame.new(0, 0.92, 0.09) * CYLINDER_Z,
			color = STAINLESS,
			material = M.Metal,
		},
		{
			name = "TankCapFront",
			shape = CYL,
			size = Vector3.new(0.08, 0.30, 0.30),
			offset = CFrame.new(0, 0.92, -1.09) * CYLINDER_Z,
			color = STAINLESS,
			material = M.Metal,
		},
		{
			name = "TankBandRear",
			shape = CYL,
			size = Vector3.new(0.06, 0.29, 0.29),
			offset = CFrame.new(0, 0.92, -0.15) * CYLINDER_Z,
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "TankBandFront",
			shape = CYL,
			size = Vector3.new(0.06, 0.29, 0.29),
			offset = CFrame.new(0, 0.92, -0.85) * CYLINDER_Z,
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "TankBracketRear",
			size = Vector3.new(0.14, 0.08, 0.05),
			offset = CFrame.new(0, 0.79, -0.15),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "TankBracketFront",
			size = Vector3.new(0.14, 0.08, 0.05),
			offset = CFrame.new(0, 0.79, -0.85),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "FillValve",
			shape = CYL,
			size = Vector3.new(0.07, 0.10, 0.10),
			offset = CFrame.new(0, 0.92, 0.155) * CYLINDER_Z,
			color = BRASS,
			material = M.Metal,
		},

		-- Coolant feed line
		{
			name = "FeedPipeH",
			shape = CYL,
			size = Vector3.new(0.28, 0.08, 0.08),
			offset = CFrame.new(0, 0.92, -1.26) * CYLINDER_Z,
			color = COPPER,
			material = M.Metal,
		},
		{
			name = "FeedElbow",
			shape = BALL,
			size = Vector3.new(0.10, 0.10, 0.10),
			offset = CFrame.new(0, 0.92, -1.40),
			color = COPPER,
			material = M.Metal,
		},
		{
			name = "FeedPipeV",
			shape = CYL,
			size = Vector3.new(0.22, 0.08, 0.08),
			offset = CFrame.new(0, 0.81, -1.40) * CYLINDER_Y,
			color = COPPER,
			material = M.Metal,
		},

		-- Barrel and cooling fins
		{
			name = "BarrelCollar",
			shape = CYL,
			size = Vector3.new(0.11, 0.46, 0.46),
			offset = CFrame.new(0, 0.50, -1.395) * CYLINDER_Z,
			color = STAINLESS,
			material = M.Metal,
		},
		{
			name = "Barrel",
			shape = CYL,
			size = Vector3.new(1.12, 0.30, 0.30),
			offset = CFrame.new(0, 0.50, -2.00) * CYLINDER_Z,
			color = STAINLESS,
			material = M.Metal,
		},
		{
			name = "Fin1",
			shape = CYL,
			size = FIN_SIZE,
			offset = CFrame.new(0, 0.50, -1.60) * CYLINDER_Z,
			color = FIN_ALUMINUM,
			material = M.Metal,
		},
		{
			name = "Fin2",
			shape = CYL,
			size = FIN_SIZE,
			offset = CFrame.new(0, 0.50, -1.75) * CYLINDER_Z,
			color = FIN_ALUMINUM,
			material = M.Metal,
		},
		{
			name = "Fin3",
			shape = CYL,
			size = FIN_SIZE,
			offset = CFrame.new(0, 0.50, -1.90) * CYLINDER_Z,
			color = FIN_ALUMINUM,
			material = M.Metal,
		},
		{
			name = "Fin4",
			shape = CYL,
			size = FIN_SIZE,
			offset = CFrame.new(0, 0.50, -2.05) * CYLINDER_Z,
			color = FIN_ALUMINUM,
			material = M.Metal,
		},
		{
			name = "Fin5",
			shape = CYL,
			size = FIN_SIZE,
			offset = CFrame.new(0, 0.50, -2.20) * CYLINDER_Z,
			color = FIN_ALUMINUM,
			material = M.Metal,
		},
		{
			name = "Fin6",
			shape = CYL,
			size = FIN_SIZE,
			offset = CFrame.new(0, 0.50, -2.35) * CYLINDER_Z,
			color = FIN_ALUMINUM,
			material = M.Metal,
		},
		{
			name = "FrostSleeve",
			shape = CYL,
			size = Vector3.new(0.50, 0.32, 0.32),
			offset = CFrame.new(0, 0.50, -2.30) * CYLINDER_Z,
			color = FROST,
			material = M.Ice,
			transparency = 0.1,
		},
		{
			name = "ReturnPipe",
			shape = CYL,
			size = Vector3.new(1.20, 0.07, 0.07),
			offset = CFrame.new(0, 0.32, -2.00) * CYLINDER_Z,
			color = COPPER,
			material = M.Metal,
		},

		-- Emitter
		{
			name = "EmitterCollar",
			shape = CYL,
			size = Vector3.new(0.15, 0.42, 0.42),
			offset = CFrame.new(0, 0.50, -2.625) * CYLINDER_Z,
			color = STAINLESS,
			material = M.Metal,
		},
		{
			name = "EmitterBell",
			shape = CYL,
			size = Vector3.new(0.20, 0.50, 0.50),
			offset = CFrame.new(0, 0.50, -2.80) * CYLINDER_Z,
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "FrostRing",
			shape = CYL,
			size = Vector3.new(0.06, 0.54, 0.54),
			offset = CFrame.new(0, 0.50, -2.86) * CYLINDER_Z,
			color = FROST,
			material = M.Ice,
			transparency = 0.1,
		},
		{
			name = "EmitterCore",
			shape = CYL,
			size = Vector3.new(0.06, 0.30, 0.30),
			offset = CFrame.new(0, 0.50, -2.92) * CYLINDER_Z,
			color = CRYO_GLOW,
			material = M.Neon,
		},
		{
			name = "EmitterLens",
			shape = CYL,
			size = Vector3.new(0.03, 0.36, 0.36),
			offset = CFrame.new(0, 0.50, -2.965) * CYLINDER_Z,
			color = LENS_GLASS,
			material = M.Glass,
			transparency = 0.5,
			reflectance = 0.2,
		},
	},
})
