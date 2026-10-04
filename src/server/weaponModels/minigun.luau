-- Minigun: M134D / GAU-17/A 7.62 mm six-barrel rotary gun, handheld configuration.

local WeaponModel = require(script.Parent.Parent.systems.WeaponModel)

local rgb = Color3.fromRGB
local M = Enum.Material
local CYLINDER_Z = WeaponModel.CYLINDER_Z
local CYL = Enum.PartType.Cylinder
local A = CFrame.Angles
local rad = math.rad

local GUNMETAL = rgb(60, 60, 60)
local GUNMETAL_DARK = rgb(42, 42, 44)
local BARREL_STEEL = rgb(45, 45, 48)
local ROTOR_STEEL = rgb(110, 110, 115)
local CLAMP_BLACK = rgb(35, 35, 38)
local MOTOR_BLACK = rgb(30, 30, 32)
local BOLT_STEEL = rgb(90, 90, 95)
local BORE = rgb(10, 10, 10)
local GRIP_RUBBER = rgb(25, 25, 25)
local GRIP_PANEL = rgb(38, 38, 38)
local CHUTE_OD = rgb(72, 78, 48)
local CHUTE_OD_DARK = rgb(55, 60, 38)
local BRASS = rgb(176, 141, 87)
local PLATE_BRASS = rgb(150, 125, 70)

local AXIS_Y = 0.7

local REAR_BOLT = Vector3.new(0.03, 0.07, 0.07)
local SEAM_RING = Vector3.new(0.03, 0.83, 0.83)
local MOTOR_RIB = Vector3.new(0.04, 0.38, 0.38)
local CHUTE_SEG = Vector3.new(0.24, 0.32, 0.3)
local CHUTE_RIB = Vector3.new(0.28, 0.05, 0.34)
local BARREL = Vector3.new(3.3, 0.13, 0.13)
local BORE_HOLE = Vector3.new(0.02, 0.07, 0.07)
local CLAMP = Vector3.new(0.14, 0.6, 0.6)
local CLAMP_BOLT = Vector3.new(0.08, 0.08, 0.1)
local CASING = Vector3.new(0.2, 0.06, 0.06)

-- Grip frame: raked 12 degrees, top forward.
local G = CFrame.new(0, -0.05, 0.05) * A(rad(-12), 0, 0)
-- Last chute segment; its bottom face (local y -0.16) is the chute mouth.
local SEG3 = CFrame.new(-0.56, -0.56, 0.15) * A(rad(-28), 0, 0)

-- Barrel ring: radius 0.2 around the gun axis.
local BARREL_Z = -2.35
local BORE_Z = -4.005

return WeaponModel.define({
	handle = {
		size = Vector3.new(0.26, 0.7, 0.4),
		color = GRIP_RUBBER,
		material = M.Rubber,
		transparency = 1,
	},
	muzzle = CFrame.new(0, AXIS_Y, -4.05),
	pieces = {
		-- Housing
		{
			name = "HousingMain",
			shape = CYL,
			size = Vector3.new(1.2, 0.8, 0.8),
			offset = CFrame.new(0, AXIS_Y, 0) * CYLINDER_Z,
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "RearCap",
			shape = CYL,
			size = Vector3.new(0.1, 0.74, 0.74),
			offset = CFrame.new(0, AXIS_Y, 0.645) * CYLINDER_Z,
			color = GUNMETAL_DARK,
			material = M.Metal,
		},
		{
			name = "RearBoltR",
			shape = CYL,
			size = REAR_BOLT,
			offset = CFrame.new(0.22, AXIS_Y, 0.705) * CYLINDER_Z,
			color = BOLT_STEEL,
			material = M.Metal,
		},
		{
			name = "RearBoltL",
			shape = CYL,
			size = REAR_BOLT,
			offset = CFrame.new(-0.22, AXIS_Y, 0.705) * CYLINDER_Z,
			color = BOLT_STEEL,
			material = M.Metal,
		},
		{
			name = "RearBoltT",
			shape = CYL,
			size = REAR_BOLT,
			offset = CFrame.new(0, 0.92, 0.705) * CYLINDER_Z,
			color = BOLT_STEEL,
			material = M.Metal,
		},
		{
			name = "RearBoltB",
			shape = CYL,
			size = REAR_BOLT,
			offset = CFrame.new(0, 0.48, 0.705) * CYLINDER_Z,
			color = BOLT_STEEL,
			material = M.Metal,
		},
		{
			name = "SeamRingRear",
			shape = CYL,
			size = SEAM_RING,
			offset = CFrame.new(0, AXIS_Y, 0.25) * CYLINDER_Z,
			color = GUNMETAL_DARK,
			material = M.Metal,
		},
		{
			name = "SeamRingFront",
			shape = CYL,
			size = SEAM_RING,
			offset = CFrame.new(0, AXIS_Y, -0.25) * CYLINDER_Z,
			color = GUNMETAL_DARK,
			material = M.Metal,
		},
		{
			name = "FrontBearingRing",
			shape = CYL,
			size = Vector3.new(0.08, 0.86, 0.86),
			offset = CFrame.new(0, AXIS_Y, -0.62) * CYLINDER_Z,
			color = GUNMETAL_DARK,
			material = M.Metal,
		},
		{
			-- Between the front seam ring (z -0.235..-0.265) and the bearing ring (z -0.58..-0.66).
			name = "DataPlate",
			size = Vector3.new(0.02, 0.14, 0.28),
			offset = CFrame.new(0.4, 0.62, -0.42),
			color = PLATE_BRASS,
			material = M.Metal,
		},

		-- Drive motor (right side)
		{
			name = "MotorBody",
			shape = CYL,
			size = Vector3.new(0.75, 0.34, 0.34),
			offset = CFrame.new(0.45, 0.92, 0.15) * CYLINDER_Z,
			color = MOTOR_BLACK,
			material = M.Metal,
		},
		{
			name = "MotorEndCap",
			shape = CYL,
			size = Vector3.new(0.06, 0.3, 0.3),
			offset = CFrame.new(0.45, 0.92, 0.55) * CYLINDER_Z,
			color = GUNMETAL_DARK,
			material = M.Metal,
		},
		{
			name = "MotorRibRear",
			shape = CYL,
			size = MOTOR_RIB,
			offset = CFrame.new(0.45, 0.92, 0.3) * CYLINDER_Z,
			color = MOTOR_BLACK,
			material = M.Metal,
		},
		{
			name = "MotorRibFront",
			shape = CYL,
			size = MOTOR_RIB,
			offset = CFrame.new(0.45, 0.92, 0) * CYLINDER_Z,
			color = MOTOR_BLACK,
			material = M.Metal,
		},
		{
			name = "MotorConnector",
			size = Vector3.new(0.1, 0.1, 0.1),
			offset = CFrame.new(0.45, 0.92, 0.62),
			color = BOLT_STEEL,
			material = M.Metal,
		},

		-- Feed system (left side)
		{
			name = "Delinker",
			size = Vector3.new(0.28, 0.42, 0.55),
			offset = CFrame.new(-0.47, 0.62, -0.05),
			color = GUNMETAL_DARK,
			material = M.Metal,
		},
		{
			name = "ChuteEntry",
			size = Vector3.new(0.26, 0.28, 0.34),
			offset = CFrame.new(-0.55, 0.3, -0.05),
			color = CHUTE_OD_DARK,
			material = M.Metal,
		},
		{
			name = "ChuteSeg1",
			size = CHUTE_SEG,
			offset = CFrame.new(-0.56, 0.02, -0.02) * A(rad(-8), 0, 0),
			color = CHUTE_OD,
			material = M.Metal,
		},
		{
			name = "ChuteRib1",
			size = CHUTE_RIB,
			offset = CFrame.new(-0.56, -0.13, 0.01) * A(rad(-13), 0, 0),
			color = CHUTE_OD_DARK,
			material = M.Metal,
		},
		{
			name = "ChuteSeg2",
			size = CHUTE_SEG,
			offset = CFrame.new(-0.56, -0.27, 0.05) * A(rad(-18), 0, 0),
			color = CHUTE_OD,
			material = M.Metal,
		},
		{
			name = "ChuteRib2",
			size = CHUTE_RIB,
			offset = CFrame.new(-0.56, -0.42, 0.09) * A(rad(-23), 0, 0),
			color = CHUTE_OD_DARK,
			material = M.Metal,
		},
		{
			name = "ChuteSeg3",
			size = CHUTE_SEG,
			offset = SEG3,
			color = CHUTE_OD,
			material = M.Metal,
		},
		{
			-- Link strip set just inside the mouth, between the two rounds.
			name = "BeltLink",
			size = Vector3.new(0.22, 0.03, 0.18),
			offset = SEG3 * CFrame.new(0, -0.165, 0),
			color = GUNMETAL_DARK,
			material = M.Metal,
		},
		{
			-- Rounds poke 0.04 out of the mouth face; cylinder axis runs across the chute (X).
			name = "CasingA",
			shape = CYL,
			size = CASING,
			offset = SEG3 * CFrame.new(0, -0.17, -0.07),
			color = BRASS,
			material = M.Metal,
			reflectance = 0.15,
		},
		{
			name = "CasingB",
			shape = CYL,
			size = CASING,
			offset = SEG3 * CFrame.new(0, -0.17, 0.07),
			color = BRASS,
			material = M.Metal,
			reflectance = 0.15,
		},

		-- Grip and trigger group
		{
			name = "GripMount",
			size = Vector3.new(0.3, 0.14, 0.5),
			offset = CFrame.new(0, 0.33, 0),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "Grip",
			size = Vector3.new(0.26, 0.8, 0.42),
			offset = G,
			color = GRIP_RUBBER,
			material = M.Rubber,
		},
		{
			name = "GripPanelR",
			size = Vector3.new(0.02, 0.6, 0.34),
			offset = G * CFrame.new(0.135, -0.02, 0),
			color = GRIP_PANEL,
			material = M.Rubber,
		},
		{
			name = "GripPanelL",
			size = Vector3.new(0.02, 0.6, 0.34),
			offset = G * CFrame.new(-0.135, -0.02, 0),
			color = GRIP_PANEL,
			material = M.Rubber,
		},
		{
			name = "GripBaseCap",
			size = Vector3.new(0.3, 0.06, 0.46),
			offset = G * CFrame.new(0, -0.42, 0),
			color = GUNMETAL_DARK,
			material = M.Metal,
		},
		{
			name = "Trigger",
			size = Vector3.new(0.06, 0.3, 0.06),
			offset = CFrame.new(0, 0.15, -0.26) * A(rad(-15), 0, 0),
			color = BOLT_STEEL,
			material = M.Metal,
		},
		{
			name = "GuardBottom",
			size = Vector3.new(0.08, 0.04, 0.42),
			offset = CFrame.new(0, -0.04, -0.37),
			color = GUNMETAL_DARK,
			material = M.Metal,
		},
		{
			name = "GuardFrontPost",
			size = Vector3.new(0.08, 0.36, 0.05),
			offset = CFrame.new(0, 0.14, -0.56),
			color = GUNMETAL_DARK,
			material = M.Metal,
		},

		-- Carry handle
		{
			name = "HandlePostRear",
			size = Vector3.new(0.1, 0.3, 0.1),
			offset = CFrame.new(0, 1.2, 0.3),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "HandlePostFront",
			size = Vector3.new(0.1, 0.3, 0.1),
			offset = CFrame.new(0, 1.2, -0.4),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "HandleBar",
			shape = CYL,
			size = Vector3.new(0.82, 0.1, 0.1),
			offset = CFrame.new(0, 1.38, -0.05) * CYLINDER_Z,
			color = GUNMETAL_DARK,
			material = M.Metal,
		},
		{
			name = "HandleSleeve",
			shape = CYL,
			size = Vector3.new(0.5, 0.14, 0.14),
			offset = CFrame.new(0, 1.38, -0.05) * CYLINDER_Z,
			color = GRIP_RUBBER,
			material = M.Rubber,
		},

		-- Rotor and spindle
		{
			name = "GunRotor",
			shape = CYL,
			size = Vector3.new(0.3, 0.66, 0.66),
			offset = CFrame.new(0, AXIS_Y, -0.8) * CYLINDER_Z,
			color = ROTOR_STEEL,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "Spindle",
			shape = CYL,
			size = Vector3.new(3.05, 0.16, 0.16),
			offset = CFrame.new(0, AXIS_Y, -2.4) * CYLINDER_Z,
			color = ROTOR_STEEL,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "SpindleNut",
			shape = CYL,
			size = Vector3.new(0.06, 0.2, 0.2),
			offset = CFrame.new(0, AXIS_Y, -3.93) * CYLINDER_Z,
			color = ROTOR_STEEL,
			material = M.Metal,
			reflectance = 0.1,
		},

		-- Barrels (z -0.7 to -4.0, rear ends seated in the rotor)
		{
			name = "Barrel1",
			shape = CYL,
			size = BARREL,
			offset = CFrame.new(0, 0.9, BARREL_Z) * CYLINDER_Z,
			color = BARREL_STEEL,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "Barrel2",
			shape = CYL,
			size = BARREL,
			offset = CFrame.new(0.1732, 0.8, BARREL_Z) * CYLINDER_Z,
			color = BARREL_STEEL,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "Barrel3",
			shape = CYL,
			size = BARREL,
			offset = CFrame.new(0.1732, 0.6, BARREL_Z) * CYLINDER_Z,
			color = BARREL_STEEL,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "Barrel4",
			shape = CYL,
			size = BARREL,
			offset = CFrame.new(0, 0.5, BARREL_Z) * CYLINDER_Z,
			color = BARREL_STEEL,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "Barrel5",
			shape = CYL,
			size = BARREL,
			offset = CFrame.new(-0.1732, 0.6, BARREL_Z) * CYLINDER_Z,
			color = BARREL_STEEL,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "Barrel6",
			shape = CYL,
			size = BARREL,
			offset = CFrame.new(-0.1732, 0.8, BARREL_Z) * CYLINDER_Z,
			color = BARREL_STEEL,
			material = M.Metal,
			reflectance = 0.05,
		},

		-- Bores (0.015 proud of each barrel face)
		{
			name = "Bore1",
			shape = CYL,
			size = BORE_HOLE,
			offset = CFrame.new(0, 0.9, BORE_Z) * CYLINDER_Z,
			color = BORE,
			material = M.SmoothPlastic,
		},
		{
			name = "Bore2",
			shape = CYL,
			size = BORE_HOLE,
			offset = CFrame.new(0.1732, 0.8, BORE_Z) * CYLINDER_Z,
			color = BORE,
			material = M.SmoothPlastic,
		},
		{
			name = "Bore3",
			shape = CYL,
			size = BORE_HOLE,
			offset = CFrame.new(0.1732, 0.6, BORE_Z) * CYLINDER_Z,
			color = BORE,
			material = M.SmoothPlastic,
		},
		{
			name = "Bore4",
			shape = CYL,
			size = BORE_HOLE,
			offset = CFrame.new(0, 0.5, BORE_Z) * CYLINDER_Z,
			color = BORE,
			material = M.SmoothPlastic,
		},
		{
			name = "Bore5",
			shape = CYL,
			size = BORE_HOLE,
			offset = CFrame.new(-0.1732, 0.6, BORE_Z) * CYLINDER_Z,
			color = BORE,
			material = M.SmoothPlastic,
		},
		{
			name = "Bore6",
			shape = CYL,
			size = BORE_HOLE,
			offset = CFrame.new(-0.1732, 0.8, BORE_Z) * CYLINDER_Z,
			color = BORE,
			material = M.SmoothPlastic,
		},

		-- Barrel clamps
		{
			name = "MidClamp",
			shape = CYL,
			size = CLAMP,
			offset = CFrame.new(0, AXIS_Y, -2.3) * CYLINDER_Z,
			color = CLAMP_BLACK,
			material = M.Metal,
		},
		{
			name = "FrontClamp",
			shape = CYL,
			size = CLAMP,
			offset = CFrame.new(0, AXIS_Y, -3.7) * CYLINDER_Z,
			color = CLAMP_BLACK,
			material = M.Metal,
		},
		{
			name = "MidClampBoltR",
			size = CLAMP_BOLT,
			offset = CFrame.new(0.32, AXIS_Y, -2.3),
			color = BOLT_STEEL,
			material = M.Metal,
		},
		{
			name = "MidClampBoltL",
			size = CLAMP_BOLT,
			offset = CFrame.new(-0.32, AXIS_Y, -2.3),
			color = BOLT_STEEL,
			material = M.Metal,
		},
		{
			name = "FrontClampBoltR",
			size = CLAMP_BOLT,
			offset = CFrame.new(0.32, AXIS_Y, -3.7),
			color = BOLT_STEEL,
			material = M.Metal,
		},
		{
			name = "FrontClampBoltL",
			size = CLAMP_BOLT,
			offset = CFrame.new(-0.32, AXIS_Y, -3.7),
			color = BOLT_STEEL,
			material = M.Metal,
		},
	},
})
