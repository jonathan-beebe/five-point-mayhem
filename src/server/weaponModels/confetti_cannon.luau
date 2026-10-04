-- Confetti Cannon: reusable pistol-grip CO2 confetti launcher with a foil-wrapped disposable cardboard confetti tube.

local WeaponModel = require(script.Parent.Parent.systems.WeaponModel)

local rgb = Color3.fromRGB
local M = Enum.Material
local CYLINDER_Z = WeaponModel.CYLINDER_Z
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball
local R = math.rad

-- Wedge orientations (WedgePart default: right angle at local (ymin, zmax), slope faces -Z/+Y).
local FLIP_Z = CFrame.Angles(0, 0, math.pi) -- flat top, tall face +Z, slope faces -Z/-Y
local FLIP_X = CFrame.Angles(math.pi, 0, 0) -- flat top, tall face -Z, slope faces +Z/-Y

-- Pistol grip frame: raked 15 degrees, bottom toward +Z.
local GRIP = CFrame.new(0, -0.1, 0.1) * CFrame.Angles(R(-15), 0, 0)

local partyPinkFoil = rgb(255, 120, 220)
local silverFoil = rgb(200, 202, 210)
local kraft = rgb(176, 140, 96)
local boreShadow = rgb(40, 30, 35)
local blackABS = rgb(30, 30, 33)
local charcoalABS = rgb(45, 45, 48)
local gripRubber = rgb(22, 22, 24)
local satinSteel = rgb(170, 172, 176)
local brass = rgb(181, 145, 80)
local chrome = rgb(210, 212, 215)
local triggerPink = rgb(225, 80, 170)
local safetyRed = rgb(190, 35, 35)
local labelPaper = rgb(242, 240, 232)
local warningYellow = rgb(245, 200, 30)
local printBlack = rgb(25, 25, 25)
local gaugeWhite = rgb(235, 235, 230)
local ledGreen = rgb(90, 255, 120)
local confettiGold = rgb(255, 200, 60)
local confettiCyan = rgb(70, 200, 255)
local confettiPurple = rgb(160, 90, 235)
local confettiLime = rgb(150, 230, 60)
local confettiOrange = rgb(255, 140, 40)

local CONFETTI = Vector3.new(0.14, 0.012, 0.1)
local STREAMER = Vector3.new(0.04, 0.01, 0.3)

local function at(x: number, y: number, z: number, rx: number, ry: number, rz: number): CFrame
	return CFrame.new(x, y, z) * CFrame.Angles(R(rx), R(ry), R(rz))
end

return WeaponModel.define({
	handle = {
		size = Vector3.new(0.4, 0.4, 1.2),
		color = blackABS,
		material = M.Plastic,
		transparency = 1,
	},
	muzzle = CFrame.new(0, 0.7, -1.6),
	pieces = {
		-- Confetti tube
		{
			name = "TubeBody",
			shape = CYL,
			size = Vector3.new(2.15, 0.9, 0.9),
			offset = CFrame.new(0, 0.7, -0.375) * CYLINDER_Z,
			color = partyPinkFoil,
			material = M.Foil,
		},
		{
			name = "RearCap",
			shape = CYL,
			size = Vector3.new(0.3, 0.96, 0.96),
			offset = CFrame.new(0, 0.7, 0.8) * CYLINDER_Z,
			color = blackABS,
			material = M.Plastic,
		},
		{
			name = "RearCapKnurl",
			shape = CYL,
			size = Vector3.new(0.12, 0.99, 0.99),
			offset = CFrame.new(0, 0.7, 0.85) * CYLINDER_Z,
			color = gripRubber,
			material = M.Rubber,
		},
		{
			name = "RearEndDisc",
			shape = CYL,
			size = Vector3.new(0.04, 0.84, 0.84),
			offset = CFrame.new(0, 0.7, 0.97) * CYLINDER_Z,
			color = charcoalABS,
			material = M.Plastic,
		},
		{
			name = "FillValve",
			shape = CYL,
			size = Vector3.new(0.05, 0.14, 0.14),
			offset = CFrame.new(0, 0.7, 1.01) * CYLINDER_Z,
			color = brass,
			material = M.Metal,
		},
		{
			name = "ClampRear",
			shape = CYL,
			size = Vector3.new(0.12, 0.98, 0.98),
			offset = CFrame.new(0, 0.7, 0.45) * CYLINDER_Z,
			color = charcoalABS,
			material = M.Plastic,
		},
		{
			name = "ClampMid",
			shape = CYL,
			size = Vector3.new(0.12, 0.98, 0.98),
			offset = CFrame.new(0, 0.7, -0.5) * CYLINDER_Z,
			color = charcoalABS,
			material = M.Plastic,
		},
		{
			name = "ClampFront",
			shape = CYL,
			size = Vector3.new(0.12, 0.98, 0.98),
			offset = CFrame.new(0, 0.7, -1.05) * CYLINDER_Z,
			color = charcoalABS,
			material = M.Plastic,
		},
		{
			name = "ClampScrewRear",
			shape = CYL,
			size = Vector3.new(0.03, 0.06, 0.06),
			offset = CFrame.new(0.495, 0.7, 0.45),
			color = satinSteel,
			material = M.Metal,
		},
		{
			name = "ClampScrewMid",
			shape = CYL,
			size = Vector3.new(0.03, 0.06, 0.06),
			offset = CFrame.new(0.495, 0.7, -0.5),
			color = satinSteel,
			material = M.Metal,
		},
		{
			name = "ClampScrewFront",
			shape = CYL,
			size = Vector3.new(0.03, 0.06, 0.06),
			offset = CFrame.new(0.495, 0.7, -1.05),
			color = satinSteel,
			material = M.Metal,
		},
		{
			name = "FoilBandRear",
			shape = CYL,
			size = Vector3.new(0.08, 0.92, 0.92),
			offset = CFrame.new(0, 0.7, 0.2) * CYLINDER_Z,
			color = silverFoil,
			material = M.Foil,
		},
		{
			name = "FoilBandMid",
			shape = CYL,
			size = Vector3.new(0.08, 0.92, 0.92),
			offset = CFrame.new(0, 0.7, -0.78) * CYLINDER_Z,
			color = silverFoil,
			material = M.Foil,
		},
		{
			name = "FoilBandFront",
			shape = CYL,
			size = Vector3.new(0.08, 0.92, 0.92),
			offset = CFrame.new(0, 0.7, -1.3) * CYLINDER_Z,
			color = silverFoil,
			material = M.Foil,
		},
		{
			name = "Label",
			size = Vector3.new(0.02, 0.2, 0.5),
			offset = CFrame.new(0.455, 0.7, -0.15),
			color = labelPaper,
		},
		{
			name = "LabelWarningStripe",
			size = Vector3.new(0.01, 0.05, 0.46),
			offset = CFrame.new(0.468, 0.7, -0.15),
			color = warningYellow,
		},
		{
			name = "LabelPrintTop",
			size = Vector3.new(0.01, 0.02, 0.36),
			offset = CFrame.new(0.468, 0.76, -0.17),
			color = printBlack,
		},
		{
			name = "LabelPrintBottom",
			size = Vector3.new(0.01, 0.02, 0.28),
			offset = CFrame.new(0.468, 0.64, -0.13),
			color = printBlack,
		},
		{
			name = "MuzzleRim",
			shape = CYL,
			size = Vector3.new(0.06, 0.94, 0.94),
			offset = CFrame.new(0, 0.7, -1.45) * CYLINDER_Z,
			color = kraft,
			material = M.Cardboard,
		},
		{
			name = "Bore",
			shape = CYL,
			size = Vector3.new(0.02, 0.82, 0.82),
			offset = CFrame.new(0, 0.7, -1.485) * CYLINDER_Z,
			color = boreShadow,
		},

		-- Confetti load at the mouth
		{
			name = "Confetti1",
			size = CONFETTI,
			offset = at(0.18, 0.86, -1.52, 40, 20, 10),
			color = confettiGold,
			material = M.Foil,
		},
		{
			name = "Confetti2",
			size = CONFETTI,
			offset = at(-0.15, 0.82, -1.54, -30, 60, 0),
			color = confettiCyan,
			material = M.Foil,
		},
		{
			name = "Confetti3",
			size = CONFETTI,
			offset = at(0.05, 0.55, -1.51, 70, 0, 30),
			color = confettiLime,
		},
		{
			name = "Confetti4",
			size = CONFETTI,
			offset = at(-0.22, 0.62, -1.53, 15, -45, 80),
			color = confettiPurple,
			material = M.Foil,
		},
		{
			name = "Confetti5",
			size = CONFETTI,
			offset = at(0.25, 0.6, -1.52, -60, 30, -20),
			color = confettiOrange,
		},
		{
			name = "Confetti6",
			size = CONFETTI,
			offset = at(0, 0.95, -1.53, -15, 10, 0),
			color = silverFoil,
			material = M.Foil,
		},
		{
			name = "Confetti7",
			size = CONFETTI,
			offset = at(-0.05, 0.7, -1.54, 30, 15, 45),
			color = confettiGold,
			material = M.Foil,
		},
		{
			name = "Confetti8",
			size = CONFETTI,
			offset = at(0.12, 0.72, -1.53, -20, -30, 60),
			color = confettiCyan,
			material = M.Foil,
		},
		{
			name = "Streamer1",
			size = STREAMER,
			offset = at(0.2, 0.42, -1.58, -50, 0, 10),
			color = confettiGold,
			material = M.Foil,
		},
		{
			name = "Streamer2",
			size = STREAMER,
			offset = at(-0.18, 0.45, -1.6, -65, 15, 0),
			color = silverFoil,
			material = M.Foil,
		},

		-- Launcher body (clamshell under the tube; sides visible below the tube from y 0.12 to 0.29)
		{
			name = "Body",
			size = Vector3.new(0.36, 0.28, 1.3),
			offset = CFrame.new(0, 0.26, 0.05),
			color = blackABS,
			material = M.Plastic,
		},
		{
			name = "BodyFrontChamfer",
			class = "WedgePart",
			size = Vector3.new(0.36, 0.28, 0.2),
			offset = CFrame.new(0, 0.26, -0.7) * FLIP_Z,
			color = blackABS,
			material = M.Plastic,
		},
		{
			name = "BodyRearChamfer",
			class = "WedgePart",
			size = Vector3.new(0.36, 0.28, 0.15),
			offset = CFrame.new(0, 0.26, 0.775) * FLIP_X,
			color = blackABS,
			material = M.Plastic,
		},
		{
			name = "LEDBezel",
			shape = CYL,
			size = Vector3.new(0.015, 0.09, 0.09),
			offset = CFrame.new(0.185, 0.22, 0.55),
			color = chrome,
			material = M.Metal,
			reflectance = 0.2,
		},
		{
			name = "LED",
			shape = CYL,
			size = Vector3.new(0.02, 0.06, 0.06),
			offset = CFrame.new(0.19, 0.22, 0.55),
			color = ledGreen,
			material = M.Neon,
		},
		{
			name = "SafetySlot",
			size = Vector3.new(0.02, 0.05, 0.22),
			offset = CFrame.new(0.185, 0.18, 0.3),
			color = boreShadow,
		},
		{
			name = "SafetySlider",
			size = Vector3.new(0.03, 0.07, 0.14),
			offset = CFrame.new(0.195, 0.18, 0.33),
			color = safetyRed,
		},
		{
			name = "BodyScrewFront",
			shape = CYL,
			size = Vector3.new(0.02, 0.05, 0.05),
			offset = CFrame.new(0.19, 0.16, -0.35),
			color = satinSteel,
			material = M.Metal,
		},
		{
			name = "BodyScrewRear",
			shape = CYL,
			size = Vector3.new(0.02, 0.05, 0.05),
			offset = CFrame.new(0.19, 0.16, 0.6),
			color = satinSteel,
			material = M.Metal,
		},

		-- Pistol grip
		{
			name = "GripCore",
			size = Vector3.new(0.32, 0.9, 0.48),
			offset = GRIP,
			color = blackABS,
			material = M.Plastic,
		},
		{
			name = "GripPanelRight",
			size = Vector3.new(0.03, 0.66, 0.38),
			offset = GRIP * CFrame.new(0.17, -0.04, 0.02),
			color = gripRubber,
			material = M.Rubber,
		},
		{
			name = "GripPanelLeft",
			size = Vector3.new(0.03, 0.66, 0.38),
			offset = GRIP * CFrame.new(-0.17, -0.04, 0.02),
			color = gripRubber,
			material = M.Rubber,
		},
		{
			name = "FingerRidge1",
			shape = CYL,
			size = Vector3.new(0.28, 0.09, 0.09),
			offset = GRIP * CFrame.new(0, 0.12, -0.245),
			color = gripRubber,
			material = M.Rubber,
		},
		{
			name = "FingerRidge2",
			shape = CYL,
			size = Vector3.new(0.28, 0.09, 0.09),
			offset = GRIP * CFrame.new(0, -0.08, -0.245),
			color = gripRubber,
			material = M.Rubber,
		},
		{
			name = "FingerRidge3",
			shape = CYL,
			size = Vector3.new(0.28, 0.09, 0.09),
			offset = GRIP * CFrame.new(0, -0.28, -0.245),
			color = gripRubber,
			material = M.Rubber,
		},
		{
			name = "GripBasePlate",
			size = Vector3.new(0.36, 0.06, 0.54),
			offset = GRIP * CFrame.new(0, -0.47, 0),
			color = charcoalABS,
			material = M.Plastic,
		},
		{
			name = "GripScrewTop",
			shape = CYL,
			size = Vector3.new(0.02, 0.05, 0.05),
			offset = GRIP * CFrame.new(0.19, 0.2, 0.05),
			color = satinSteel,
			material = M.Metal,
		},
		{
			name = "GripScrewBottom",
			shape = CYL,
			size = Vector3.new(0.02, 0.05, 0.05),
			offset = GRIP * CFrame.new(0.19, -0.28, 0.05),
			color = satinSteel,
			material = M.Metal,
		},

		-- Trigger group
		{
			name = "TriggerGuardBar",
			size = Vector3.new(0.08, 0.05, 0.46),
			offset = CFrame.new(0, -0.17, -0.34),
			color = blackABS,
			material = M.Plastic,
		},
		{
			name = "TriggerGuardPost",
			size = Vector3.new(0.08, 0.33, 0.05),
			offset = CFrame.new(0, -0.025, -0.55),
			color = blackABS,
			material = M.Plastic,
		},
		{
			name = "TriggerBlade",
			size = Vector3.new(0.07, 0.24, 0.08),
			offset = at(0, 0.04, -0.4, -15, 0, 0),
			color = triggerPink,
		},
		{
			name = "TriggerTip",
			shape = BALL,
			size = Vector3.new(0.09, 0.09, 0.09),
			offset = CFrame.new(0, -0.076, -0.369),
			color = triggerPink,
		},

		-- CO2 system
		{
			name = "CO2Cartridge",
			shape = CYL,
			size = Vector3.new(0.5, 0.22, 0.22),
			offset = CFrame.new(0, 0.15, -1.0) * CYLINDER_Z,
			color = satinSteel,
			material = M.Metal,
		},
		{
			name = "CO2Nose",
			shape = BALL,
			size = Vector3.new(0.22, 0.22, 0.22),
			offset = CFrame.new(0, 0.15, -1.25),
			color = satinSteel,
			material = M.Metal,
		},
		{
			name = "CO2Neck",
			shape = CYL,
			size = Vector3.new(0.1, 0.12, 0.12),
			offset = CFrame.new(0, 0.15, -0.7) * CYLINDER_Z,
			color = brass,
			material = M.Metal,
		},
		{
			name = "Regulator",
			size = Vector3.new(0.2, 0.18, 0.12),
			offset = CFrame.new(0, 0.17, -0.64),
			color = brass,
			material = M.Metal,
		},
		{
			name = "CartridgeBracket",
			size = Vector3.new(0.1, 0.1, 0.1),
			offset = CFrame.new(0, 0.27, -1.05),
			color = blackABS,
			material = M.Plastic,
		},
		{
			name = "GaugeBezel",
			shape = CYL,
			size = Vector3.new(0.04, 0.12, 0.12),
			offset = CFrame.new(0.115, 0.17, -0.64),
			color = chrome,
			material = M.Metal,
			reflectance = 0.2,
		},
		{
			name = "GaugeFace",
			shape = CYL,
			size = Vector3.new(0.014, 0.095, 0.095),
			offset = CFrame.new(0.139, 0.17, -0.64),
			color = gaugeWhite,
		},
		{
			name = "GaugeNeedle",
			size = Vector3.new(0.01, 0.04, 0.008),
			offset = at(0.149, 0.18, -0.645, 35, 0, 0),
			color = safetyRed,
		},
	},
})
