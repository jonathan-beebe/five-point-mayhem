-- Plasma Cannon: Carl Gustaf M4 recoilless rifle body fitted with a bolted glass plasma
-- containment chamber, finned heatsink barrel and copper-pronged emitter, built like a film prop.

local WeaponModel = require(script.Parent.Parent.systems.WeaponModel)

local rgb = Color3.fromRGB
local M = Enum.Material
local CYLINDER_Z = WeaponModel.CYLINDER_Z
local CYLINDER_Y = WeaponModel.CYLINDER_Y
local CYL = Enum.PartType.Cylinder

local BORE_Y = 0.70

-- Grip frame: raked 15 degrees, bottom toward +Z.
local GRIP_CF = CFrame.new(0, -0.05, 0.05) * CFrame.Angles(math.rad(-15), 0, 0)

local function bore(z: number): CFrame
	return CFrame.new(0, BORE_Y, z) * CYLINDER_Z
end

local GUNMETAL = rgb(52, 56, 60)
local POLYMER = rgb(34, 36, 38)
local RUBBER = rgb(22, 22, 24)
local ALUMINUM = rgb(150, 154, 158)
local STEEL = rgb(112, 116, 120)
local COPPER = rgb(176, 108, 58)
local HAZARD_YELLOW = rgb(210, 165, 40)
local CHAMBER_GLASS = rgb(190, 235, 228)
local OPTIC_GLASS = rgb(120, 200, 190)
local PLASMA = rgb(0, 255, 200)

local FIN_SIZE = Vector3.new(0.05, 0.98, 0.98)
local COIL_SIZE = Vector3.new(0.05, 0.90, 0.90)
local TIE_ROD_SIZE = Vector3.new(0.06, 0.06, 0.90)
local NUT_SIZE = Vector3.new(0.04, 0.08, 0.08)
local PRONG_SIZE = Vector3.new(0.08, 0.08, 0.22)
local TOOTH_SIZE = Vector3.new(0.26, 0.04, 0.06)
local VENT_SIZE = Vector3.new(0.04, 0.05, 0.30)

-- Tie rods and prongs sit at radius ~0.49-0.50 on the diagonals.
local ROD = 0.346
local PRONG = 0.354

return WeaponModel.define({
	handle = {
		size = Vector3.new(0.3, 0.8, 0.4),
		color = POLYMER,
		material = M.Plastic,
		transparency = 1,
	},
	muzzle = CFrame.new(0, BORE_Y, -3.10),
	pieces = {
		-- Rear tube
		{
			name = "ButtPad",
			shape = CYL,
			size = Vector3.new(0.11, 0.96, 0.96),
			offset = bore(1.025),
			color = RUBBER,
			material = M.Rubber,
		},
		{
			name = "RearTube",
			shape = CYL,
			size = Vector3.new(1.38, 0.90, 0.90),
			offset = bore(0.29),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "RearTrimRing",
			shape = CYL,
			size = Vector3.new(0.06, 0.94, 0.94),
			offset = bore(0.90),
			color = ALUMINUM,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "HazardBand",
			shape = CYL,
			size = Vector3.new(0.08, 0.92, 0.92),
			offset = bore(-0.25),
			color = HAZARD_YELLOW,
			material = M.SmoothPlastic,
		},
		{
			name = "VentSlot1",
			size = VENT_SIZE,
			offset = CFrame.new(-0.44, 0.62, 0.45),
			color = RUBBER,
			material = M.Rubber,
		},
		{
			name = "VentSlot2",
			size = VENT_SIZE,
			offset = CFrame.new(-0.44, 0.70, 0.45),
			color = RUBBER,
			material = M.Rubber,
		},
		{
			name = "VentSlot3",
			size = VENT_SIZE,
			offset = CFrame.new(-0.44, 0.78, 0.45),
			color = RUBBER,
			material = M.Rubber,
		},

		-- Containment chamber
		{
			name = "FlangeRear",
			shape = CYL,
			size = Vector3.new(0.10, 1.04, 1.04),
			offset = bore(-0.45),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "FlangeFront",
			shape = CYL,
			size = Vector3.new(0.10, 1.04, 1.04),
			offset = bore(-1.35),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "ChamberGlass",
			shape = CYL,
			size = Vector3.new(0.82, 0.86, 0.86),
			offset = bore(-0.90),
			color = CHAMBER_GLASS,
			material = M.Glass,
			transparency = 0.55,
			reflectance = 0.2,
		},
		{
			name = "PlasmaCore",
			shape = CYL,
			size = Vector3.new(0.78, 0.34, 0.34),
			offset = bore(-0.90),
			color = PLASMA,
			material = M.Neon,
		},
		{
			name = "PlasmaHalo",
			shape = CYL,
			size = Vector3.new(0.76, 0.60, 0.60),
			offset = bore(-0.90),
			color = PLASMA,
			material = M.Neon,
			transparency = 0.6,
		},
		{
			name = "Coil1",
			shape = CYL,
			size = COIL_SIZE,
			offset = bore(-0.65),
			color = COPPER,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "Coil2",
			shape = CYL,
			size = COIL_SIZE,
			offset = bore(-0.90),
			color = COPPER,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "Coil3",
			shape = CYL,
			size = COIL_SIZE,
			offset = bore(-1.15),
			color = COPPER,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "TieRodUR",
			size = TIE_ROD_SIZE,
			offset = CFrame.new(ROD, BORE_Y + ROD, -0.90),
			color = STEEL,
			material = M.Metal,
		},
		{
			name = "TieRodUL",
			size = TIE_ROD_SIZE,
			offset = CFrame.new(-ROD, BORE_Y + ROD, -0.90),
			color = STEEL,
			material = M.Metal,
		},
		{
			name = "TieRodLR",
			size = TIE_ROD_SIZE,
			offset = CFrame.new(ROD, BORE_Y - ROD, -0.90),
			color = STEEL,
			material = M.Metal,
		},
		{
			name = "TieRodLL",
			size = TIE_ROD_SIZE,
			offset = CFrame.new(-ROD, BORE_Y - ROD, -0.90),
			color = STEEL,
			material = M.Metal,
		},
		-- Tie-rod nuts: rear set on FlangeRear's rear face, front set on FlangeFront's front face.
		{
			name = "NutRearUR",
			shape = CYL,
			size = NUT_SIZE,
			offset = CFrame.new(ROD, BORE_Y + ROD, -0.385) * CYLINDER_Z,
			color = STEEL,
			material = M.Metal,
		},
		{
			name = "NutRearUL",
			shape = CYL,
			size = NUT_SIZE,
			offset = CFrame.new(-ROD, BORE_Y + ROD, -0.385) * CYLINDER_Z,
			color = STEEL,
			material = M.Metal,
		},
		{
			name = "NutRearLR",
			shape = CYL,
			size = NUT_SIZE,
			offset = CFrame.new(ROD, BORE_Y - ROD, -0.385) * CYLINDER_Z,
			color = STEEL,
			material = M.Metal,
		},
		{
			name = "NutRearLL",
			shape = CYL,
			size = NUT_SIZE,
			offset = CFrame.new(-ROD, BORE_Y - ROD, -0.385) * CYLINDER_Z,
			color = STEEL,
			material = M.Metal,
		},
		{
			name = "NutFrontUR",
			shape = CYL,
			size = NUT_SIZE,
			offset = CFrame.new(ROD, BORE_Y + ROD, -1.415) * CYLINDER_Z,
			color = STEEL,
			material = M.Metal,
		},
		{
			name = "NutFrontUL",
			shape = CYL,
			size = NUT_SIZE,
			offset = CFrame.new(-ROD, BORE_Y + ROD, -1.415) * CYLINDER_Z,
			color = STEEL,
			material = M.Metal,
		},
		{
			name = "NutFrontLR",
			shape = CYL,
			size = NUT_SIZE,
			offset = CFrame.new(ROD, BORE_Y - ROD, -1.415) * CYLINDER_Z,
			color = STEEL,
			material = M.Metal,
		},
		{
			name = "NutFrontLL",
			shape = CYL,
			size = NUT_SIZE,
			offset = CFrame.new(-ROD, BORE_Y - ROD, -1.415) * CYLINDER_Z,
			color = STEEL,
			material = M.Metal,
		},

		-- Heatsink barrel (z -1.40 to -2.70, seated against FlangeFront)
		{
			name = "Barrel",
			shape = CYL,
			size = Vector3.new(1.30, 0.72, 0.72),
			offset = bore(-2.05),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "Fin1",
			shape = CYL,
			size = FIN_SIZE,
			offset = bore(-1.50),
			color = ALUMINUM,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "Fin2",
			shape = CYL,
			size = FIN_SIZE,
			offset = bore(-1.62),
			color = ALUMINUM,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "Fin3",
			shape = CYL,
			size = FIN_SIZE,
			offset = bore(-1.74),
			color = ALUMINUM,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "Fin4",
			shape = CYL,
			size = FIN_SIZE,
			offset = bore(-1.86),
			color = ALUMINUM,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "Fin5",
			shape = CYL,
			size = FIN_SIZE,
			offset = bore(-1.98),
			color = ALUMINUM,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "Fin6",
			shape = CYL,
			size = FIN_SIZE,
			offset = bore(-2.10),
			color = ALUMINUM,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "Sleeve",
			shape = CYL,
			size = Vector3.new(0.40, 0.80, 0.80),
			offset = bore(-2.35),
			color = POLYMER,
			material = M.Plastic,
		},

		-- Emitter
		{
			name = "Shroud",
			shape = CYL,
			size = Vector3.new(0.40, 1.00, 1.00),
			offset = bore(-2.75),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "ShroudLip",
			shape = CYL,
			size = Vector3.new(0.06, 1.06, 1.06),
			offset = bore(-2.95),
			color = ALUMINUM,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "EmitterDisc",
			shape = CYL,
			size = Vector3.new(0.04, 0.72, 0.72),
			offset = bore(-3.00),
			color = PLASMA,
			material = M.Neon,
		},
		{
			name = "EmitterLens",
			shape = CYL,
			size = Vector3.new(0.03, 0.78, 0.78),
			offset = bore(-3.035),
			color = CHAMBER_GLASS,
			material = M.Glass,
			transparency = 0.5,
			reflectance = 0.2,
		},
		{
			name = "ProngUR",
			size = PRONG_SIZE,
			offset = CFrame.new(PRONG, BORE_Y + PRONG, -3.01),
			color = COPPER,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "ProngUL",
			size = PRONG_SIZE,
			offset = CFrame.new(-PRONG, BORE_Y + PRONG, -3.01),
			color = COPPER,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "ProngLR",
			size = PRONG_SIZE,
			offset = CFrame.new(PRONG, BORE_Y - PRONG, -3.01),
			color = COPPER,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "ProngLL",
			size = PRONG_SIZE,
			offset = CFrame.new(-PRONG, BORE_Y - PRONG, -3.01),
			color = COPPER,
			material = M.Metal,
			reflectance = 0.1,
		},

		-- Grip and trigger group (mount y 0.10 to 0.30, top buried in the tube)
		{
			name = "GripMount",
			size = Vector3.new(0.34, 0.20, 0.95),
			offset = CFrame.new(0, 0.20, 0),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "MountChamferFront",
			class = "WedgePart",
			size = Vector3.new(0.34, 0.20, 0.15),
			offset = CFrame.new(0, 0.20, -0.55),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "MountChamferRear",
			class = "WedgePart",
			size = Vector3.new(0.34, 0.20, 0.15),
			offset = CFrame.new(0, 0.20, 0.55) * CFrame.Angles(0, math.pi, 0),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "Grip",
			size = Vector3.new(0.32, 0.85, 0.42),
			offset = GRIP_CF,
			color = POLYMER,
			material = M.Plastic,
		},
		{
			name = "GripPanelR",
			size = Vector3.new(0.02, 0.60, 0.34),
			offset = GRIP_CF * CFrame.new(0.165, -0.03, 0.01),
			color = RUBBER,
			material = M.Rubber,
		},
		{
			name = "GripPanelL",
			size = Vector3.new(0.02, 0.60, 0.34),
			offset = GRIP_CF * CFrame.new(-0.165, -0.03, 0.01),
			color = RUBBER,
			material = M.Rubber,
		},
		{
			name = "GripBase",
			size = Vector3.new(0.36, 0.06, 0.46),
			offset = GRIP_CF * CFrame.new(0, -0.445, 0.01),
			color = POLYMER,
			material = M.Plastic,
		},
		{
			name = "Trigger",
			size = Vector3.new(0.06, 0.20, 0.06),
			offset = CFrame.new(0, 0.08, -0.30) * CFrame.Angles(math.rad(-10), 0, 0),
			color = STEEL,
			material = M.Metal,
		},
		{
			name = "GuardBar",
			size = Vector3.new(0.06, 0.05, 0.36),
			offset = CFrame.new(0, -0.08, -0.30),
			color = POLYMER,
			material = M.Plastic,
		},
		{
			name = "GuardPost",
			size = Vector3.new(0.06, 0.30, 0.05),
			offset = CFrame.new(0, 0.055, -0.455),
			color = POLYMER,
			material = M.Plastic,
		},

		-- Foregrip (rail buried in the sleeve underside)
		{
			name = "ForeRail",
			size = Vector3.new(0.22, 0.08, 0.36),
			offset = CFrame.new(0, 0.28, -2.35),
			color = POLYMER,
			material = M.Plastic,
		},
		{
			name = "Foregrip",
			shape = CYL,
			size = Vector3.new(0.60, 0.26, 0.26),
			offset = CFrame.new(0, -0.03, -2.35) * CYLINDER_Y,
			color = RUBBER,
			material = M.Rubber,
		},
		{
			name = "ForegripCap",
			shape = CYL,
			size = Vector3.new(0.05, 0.30, 0.30),
			offset = CFrame.new(0, -0.35, -2.35) * CYLINDER_Y,
			color = STEEL,
			material = M.Metal,
		},

		-- Sights (rail y 1.13 to 1.20, teeth 1.19 to 1.23, optic 1.225 to 1.445)
		{
			name = "OpticRail",
			size = Vector3.new(0.24, 0.07, 0.70),
			offset = CFrame.new(0, 1.165, 0.50),
			color = STEEL,
			material = M.Metal,
		},
		{
			name = "RailTooth1",
			size = TOOTH_SIZE,
			offset = CFrame.new(0, 1.21, 0.25),
			color = STEEL,
			material = M.Metal,
		},
		{
			name = "RailTooth2",
			size = TOOTH_SIZE,
			offset = CFrame.new(0, 1.21, 0.40),
			color = STEEL,
			material = M.Metal,
		},
		{
			name = "RailTooth3",
			size = TOOTH_SIZE,
			offset = CFrame.new(0, 1.21, 0.55),
			color = STEEL,
			material = M.Metal,
		},
		{
			name = "RailTooth4",
			size = TOOTH_SIZE,
			offset = CFrame.new(0, 1.21, 0.70),
			color = STEEL,
			material = M.Metal,
		},
		{
			name = "OpticBody",
			size = Vector3.new(0.20, 0.22, 0.36),
			offset = CFrame.new(0, 1.335, 0.50),
			color = POLYMER,
			material = M.Plastic,
		},
		{
			name = "OpticLensFront",
			size = Vector3.new(0.16, 0.14, 0.02),
			offset = CFrame.new(0, 1.345, 0.315),
			color = OPTIC_GLASS,
			material = M.Glass,
			transparency = 0.4,
			reflectance = 0.3,
		},
		{
			name = "OpticLensRear",
			size = Vector3.new(0.16, 0.14, 0.02),
			offset = CFrame.new(0, 1.345, 0.685),
			color = OPTIC_GLASS,
			material = M.Glass,
			transparency = 0.4,
			reflectance = 0.3,
		},
		{
			name = "FrontSightBase",
			size = Vector3.new(0.18, 0.06, 0.20),
			offset = CFrame.new(0, 1.21, -2.75),
			color = STEEL,
			material = M.Metal,
		},
		{
			name = "FrontSightPost",
			size = Vector3.new(0.06, 0.16, 0.06),
			offset = CFrame.new(0, 1.28, -2.75),
			color = STEEL,
			material = M.Metal,
		},

		-- Power cell and cables (right side)
		{
			name = "PowerCell",
			size = Vector3.new(0.22, 0.40, 0.70),
			offset = CFrame.new(0.52, 0.65, 0.45),
			color = POLYMER,
			material = M.Plastic,
		},
		{
			name = "ChargeIndicator",
			size = Vector3.new(0.02, 0.06, 0.40),
			offset = CFrame.new(0.635, 0.75, 0.45),
			color = PLASMA,
			material = M.Neon,
		},
		{
			name = "CellLatch",
			size = Vector3.new(0.04, 0.12, 0.10),
			offset = CFrame.new(0.645, 0.55, 0.45),
			color = STEEL,
			material = M.Metal,
		},
		{
			name = "CableLow",
			shape = CYL,
			size = Vector3.new(0.60, 0.08, 0.08),
			offset = CFrame.new(0.455, 0.55, -0.15) * CYLINDER_Z,
			color = RUBBER,
			material = M.Rubber,
		},
		{
			name = "CableHigh",
			shape = CYL,
			size = Vector3.new(0.60, 0.08, 0.08),
			offset = CFrame.new(0.46, 0.80, -0.15) * CYLINDER_Z,
			color = RUBBER,
			material = M.Rubber,
		},
		{
			name = "ConnectorLow",
			shape = CYL,
			size = Vector3.new(0.08, 0.12, 0.12),
			offset = CFrame.new(0.455, 0.55, -0.365) * CYLINDER_Z,
			color = ALUMINUM,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "ConnectorHigh",
			shape = CYL,
			size = Vector3.new(0.08, 0.12, 0.12),
			offset = CFrame.new(0.46, 0.80, -0.365) * CYLINDER_Z,
			color = ALUMINUM,
			material = M.Metal,
			reflectance = 0.05,
		},
	},
})
