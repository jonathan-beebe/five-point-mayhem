-- Revolver: Colt Single Action Army (1873), 4 3/4" "Civilian" barrel, case-hardened frame, blued steel, walnut grip.

local WeaponModel = require(script.Parent.Parent.systems.WeaponModel)

local rgb = Color3.fromRGB
local M = Enum.Material
local CYLINDER_Z = WeaponModel.CYLINDER_Z
local CYL = Enum.PartType.Cylinder

local function rx(degrees: number): CFrame
	return CFrame.Angles(math.rad(degrees), 0, 0)
end

local function rz(degrees: number): CFrame
	return CFrame.Angles(0, 0, math.rad(degrees))
end

local bluedSteel = rgb(38, 42, 50)
local bluedDark = rgb(20, 22, 26)
local caseGray = rgb(92, 88, 86)
local caseBlue = rgb(58, 68, 92)
local caseAmber = rgb(128, 100, 68)
local brightSteel = rgb(150, 150, 155)
local boreBlack = rgb(10, 10, 12)
local walnut = rgb(150, 110, 70)

-- Grip frame, raked 18 degrees so the butt sits rearward.
local G = CFrame.new(0, -0.14, 0.08) * rx(-18)
-- Cylinder axis, one chamber below the bore line.
local C = CFrame.new(0, 0.42, -0.30)

-- Dark flat between two chambers on the cylinder's outer surface.
local function flute(index: number, degrees: number)
	return {
		name = "Flute" .. index,
		size = Vector3.new(0.06, 0.01, 0.26),
		offset = C * rz(degrees) * CFrame.new(0, 0.219, 0),
		color = bluedDark,
		material = M.Metal,
	}
end

-- Cylinder stop notch near the rear of the cylinder, in line with each chamber.
local function boltNotch(index: number, degrees: number)
	return {
		name = "BoltNotch" .. index,
		size = Vector3.new(0.035, 0.01, 0.04),
		offset = C * rz(degrees) * CFrame.new(0, 0.219, 0.15),
		color = bluedDark,
		material = M.Metal,
	}
end

-- Mottled case-colour patch on a frame side.
local function mottle(
	name: string,
	x: number,
	y: number,
	z: number,
	height: number,
	depth: number,
	color: Color3
)
	return {
		name = name,
		size = Vector3.new(0.014, height, depth),
		offset = CFrame.new(x, y, z),
		color = color,
		material = M.Metal,
		reflectance = 0.05,
	}
end

-- Polished screw through the frame, showing a head on both sides.
local function crossScrew(name: string, diameter: number, offset: CFrame)
	return {
		name = name,
		shape = CYL,
		size = Vector3.new(0.345, diameter, diameter),
		offset = offset,
		color = brightSteel,
		material = M.Metal,
		reflectance = 0.1,
	}
end

return WeaponModel.define({
	handle = {
		size = Vector3.new(0.3, 0.6, 0.3),
		color = walnut,
		material = M.Wood,
		transparency = 1,
	},
	muzzle = CFrame.new(0, 0.54, -1.97),
	pieces = {
		-- Frame (case-hardened)
		{
			name = "FrameBottom",
			size = Vector3.new(0.29, 0.1, 0.62),
			offset = CFrame.new(0, 0.15, -0.33),
			color = caseGray,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "FrameRear",
			size = Vector3.new(0.3, 0.48, 0.2),
			offset = CFrame.new(0, 0.42, 0.05),
			color = caseGray,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "TopStrap",
			size = Vector3.new(0.26, 0.05, 0.57),
			offset = CFrame.new(0, 0.67, -0.265),
			color = caseGray,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "SightGroove",
			size = Vector3.new(0.035, 0.012, 0.5),
			offset = CFrame.new(0, 0.6995, -0.27),
			color = bluedDark,
			material = M.Metal,
		},
		{
			name = "FrameFront",
			size = Vector3.new(0.3, 0.36, 0.14),
			offset = CFrame.new(0, 0.36, -0.58),
			color = caseGray,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "FrameNoseRound",
			shape = CYL,
			size = Vector3.new(0.13, 0.3, 0.3),
			offset = CFrame.new(0, 0.54, -0.58) * CYLINDER_Z,
			color = caseGray,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "RecoilShield",
			shape = CYL,
			size = Vector3.new(0.1, 0.46, 0.46),
			offset = CFrame.new(0, 0.42, -0.07) * CYLINDER_Z,
			color = caseGray,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "LoadingGate",
			size = Vector3.new(0.02, 0.16, 0.08),
			offset = CFrame.new(0.235, 0.42, -0.07),
			color = caseGray,
			material = M.Metal,
			reflectance = 0.05,
		},

		-- Case-colour mottling
		mottle("MottleFrontR", 0.155, 0.34, -0.58, 0.2, 0.1, caseAmber),
		mottle("MottleFrontL", -0.155, 0.34, -0.58, 0.2, 0.1, caseBlue),
		mottle("MottleRearR", 0.155, 0.4, 0.05, 0.22, 0.14, caseBlue),
		mottle("MottleRearL", -0.155, 0.4, 0.05, 0.22, 0.14, caseAmber),

		-- Frame screws
		crossScrew("HammerScrew", 0.05, CFrame.new(0, 0.48, 0.1)),
		crossScrew("TriggerScrew", 0.04, CFrame.new(0, 0.15, -0.22)),
		crossScrew("BasePinLatch", 0.045, CFrame.new(0, 0.32, -0.6)),

		-- Cylinder
		{
			name = "Cylinder",
			shape = CYL,
			size = Vector3.new(0.36, 0.44, 0.44),
			offset = C * CYLINDER_Z,
			color = bluedSteel,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "CylinderBevel",
			shape = CYL,
			size = Vector3.new(0.025, 0.4, 0.4),
			offset = CFrame.new(0, 0.42, -0.4925) * CYLINDER_Z,
			color = bluedSteel,
			material = M.Metal,
			reflectance = 0.05,
		},
		flute(1, 30),
		flute(2, 90),
		flute(3, 150),
		flute(4, 210),
		flute(5, 270),
		flute(6, 330),
		boltNotch(1, 0),
		boltNotch(2, 60),
		boltNotch(3, 120),
		boltNotch(4, 180),
		boltNotch(5, 240),
		boltNotch(6, 300),

		-- Barrel and front sight
		{
			name = "Barrel",
			shape = CYL,
			size = Vector3.new(1.37, 0.19, 0.19),
			offset = CFrame.new(0, 0.54, -1.265) * CYLINDER_Z,
			color = bluedSteel,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "MuzzleCrown",
			shape = CYL,
			size = Vector3.new(0.015, 0.17, 0.17),
			offset = CFrame.new(0, 0.54, -1.955) * CYLINDER_Z,
			color = brightSteel,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "Bore",
			shape = CYL,
			size = Vector3.new(0.012, 0.085, 0.085),
			offset = CFrame.new(0, 0.54, -1.962) * CYLINDER_Z,
			color = boreBlack,
			material = M.SmoothPlastic,
		},
		{
			-- WedgePart default: tall face at +Z (rear), slope down toward the muzzle.
			name = "FrontSight",
			class = "WedgePart",
			size = Vector3.new(0.04, 0.07, 0.14),
			offset = CFrame.new(0, 0.665, -1.86),
			color = bluedSteel,
			material = M.Metal,
			reflectance = 0.05,
		},

		-- Ejector and base pin
		{
			name = "EjectorHousing",
			shape = CYL,
			size = Vector3.new(0.88, 0.12, 0.12),
			offset = CFrame.new(0.1, 0.43, -1.06) * CYLINDER_Z,
			color = bluedSteel,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "EjectorCap",
			shape = CYL,
			size = Vector3.new(0.03, 0.1, 0.1),
			offset = CFrame.new(0.1, 0.43, -1.515) * CYLINDER_Z,
			color = bluedSteel,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "EjectorSlot",
			size = Vector3.new(0.012, 0.025, 0.66),
			offset = CFrame.new(0.162, 0.43, -1.04),
			color = bluedDark,
			material = M.Metal,
		},
		{
			name = "EjectorRodHead",
			size = Vector3.new(0.04, 0.06, 0.08),
			offset = CFrame.new(0.175, 0.43, -1.4),
			color = bluedSteel,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "EjectorScrew",
			shape = CYL,
			size = Vector3.new(0.02, 0.035, 0.035),
			offset = CFrame.new(0.165, 0.43, -0.72),
			color = brightSteel,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "BasePinHead",
			shape = CYL,
			size = Vector3.new(0.06, 0.07, 0.07),
			offset = CFrame.new(0, 0.42, -0.68) * CYLINDER_Z,
			color = brightSteel,
			material = M.Metal,
			reflectance = 0.1,
		},

		-- Hammer
		{
			name = "HammerBody",
			size = Vector3.new(0.1, 0.35, 0.1),
			offset = CFrame.new(0, 0.575, 0.11),
			color = caseGray,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "HammerSpur",
			size = Vector3.new(0.1, 0.06, 0.16),
			offset = CFrame.new(0, 0.76, 0.2) * rx(-25),
			color = caseGray,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "SpurCheckering",
			size = Vector3.new(0.08, 0.008, 0.12),
			offset = CFrame.new(0, 0.76, 0.2) * rx(-25) * CFrame.new(0, 0.031, 0),
			color = bluedDark,
			material = M.Metal,
		},

		-- Trigger and guard
		{
			name = "TriggerUpper",
			size = Vector3.new(0.05, 0.08, 0.04),
			offset = CFrame.new(0, 0.11, -0.22),
			color = bluedSteel,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "TriggerLower",
			size = Vector3.new(0.05, 0.08, 0.04),
			offset = CFrame.new(0, 0.04, -0.23) * rx(25),
			color = bluedSteel,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "GuardBar",
			size = Vector3.new(0.08, 0.04, 0.29),
			offset = CFrame.new(0, -0.03, -0.255),
			color = bluedSteel,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "GuardFront",
			size = Vector3.new(0.08, 0.17, 0.04),
			offset = CFrame.new(0, 0.03, -0.41) * rx(-15),
			color = bluedSteel,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "GuardCorner",
			shape = CYL,
			size = Vector3.new(0.08, 0.05, 0.05),
			offset = CFrame.new(0, -0.03, -0.395),
			color = bluedSteel,
			material = M.Metal,
			reflectance = 0.05,
		},

		-- Grip: one-piece walnut inside a blued grip frame
		{
			name = "WalnutGrip",
			size = Vector3.new(0.32, 0.69, 0.3),
			offset = G * CFrame.new(0, 0.045, 0),
			color = walnut,
			material = M.Wood,
		},
		{
			name = "WalnutButt",
			shape = CYL,
			size = Vector3.new(0.31, 0.3, 0.3),
			offset = G * CFrame.new(0, -0.3, 0),
			color = walnut,
			material = M.Wood,
		},
		{
			name = "ButtRing",
			shape = CYL,
			size = Vector3.new(0.24, 0.36, 0.36),
			offset = G * CFrame.new(0, -0.3, 0),
			color = bluedSteel,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "Backstrap",
			size = Vector3.new(0.24, 0.7, 0.04),
			offset = G * CFrame.new(0, 0.05, 0.16),
			color = bluedSteel,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "FrontStrap",
			size = Vector3.new(0.24, 0.6, 0.04),
			offset = G * CFrame.new(0, 0, -0.16),
			color = bluedSteel,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "BackstrapUpper",
			size = Vector3.new(0.22, 0.35, 0.06),
			offset = CFrame.new(0, 0.395, 0.15),
			color = bluedSteel,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "BackstrapTop",
			shape = CYL,
			size = Vector3.new(0.22, 0.06, 0.06),
			offset = CFrame.new(0, 0.57, 0.15),
			color = bluedSteel,
			material = M.Metal,
			reflectance = 0.05,
		},
		crossScrew("GripScrew", 0.05, G * CFrame.new(0, 0.1, 0)),
	},
})
