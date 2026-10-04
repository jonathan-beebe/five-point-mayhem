-- Tomato Launcher: backyard Schedule 40 PVC pneumatic spud gun with brass ball valve, clear tomato hopper.

local WeaponModel = require(script.Parent.Parent.systems.WeaponModel)

local rgb = Color3.fromRGB
local M = Enum.Material
local CYLINDER_Z = WeaponModel.CYLINDER_Z
local CYLINDER_Y = WeaponModel.CYLINDER_Y
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball
local R = math.rad

local pvcPipe = rgb(236, 234, 226)
local pvcFitting = rgb(244, 243, 238)
local primer = rgb(122, 64, 150)
local ink = rgb(45, 55, 85)
local brass = rgb(181, 148, 72)
local steel = rgb(168, 170, 174)
local chrome = rgb(200, 202, 206)
local leverRed = rgb(196, 32, 28)
local black = rgb(32, 32, 35)
local rubber = rgb(24, 24, 26)
local gaugeFace = rgb(238, 238, 232)
local needle = rgb(200, 25, 25)
local hopperClear = rgb(205, 218, 222)
local tomato = rgb(220, 40, 30)
local calyx = rgb(74, 112, 42)

-- Bore axis height.
local BY = 0.75
-- Pistol grip frame: raked 15 degrees, bottom toward +Z.
local G = CFrame.new(0, -0.05, 0.05) * CFrame.Angles(R(-15), 0, 0)

return WeaponModel.define({
	handle = {
		size = Vector3.new(0.3, 0.8, 0.45),
		color = black,
		material = M.Plastic,
		transparency = 1,
	},
	muzzle = CFrame.new(0, BY, -2.3),
	pieces = {
		-- Air chamber
		{
			name = "ChamberEndCap",
			shape = CYL,
			size = Vector3.new(0.18, 0.93, 0.93),
			offset = CFrame.new(0, BY, 0.94) * CYLINDER_Z,
			color = pvcFitting,
		},
		{
			name = "ChamberCapFace",
			shape = CYL,
			size = Vector3.new(0.04, 0.75, 0.75),
			offset = CFrame.new(0, BY, 1.045) * CYLINDER_Z,
			color = pvcFitting,
		},
		{
			name = "ChamberPipe",
			shape = CYL,
			size = Vector3.new(1.1, 0.85, 0.85),
			offset = CFrame.new(0, BY, 0.33) * CYLINDER_Z,
			color = pvcPipe,
		},
		{
			name = "ReducerCoupling",
			shape = CYL,
			size = Vector3.new(0.26, 0.93, 0.93),
			offset = CFrame.new(0, BY, -0.25) * CYLINDER_Z,
			color = pvcFitting,
		},
		{
			name = "ReducerBushingFace",
			shape = CYL,
			size = Vector3.new(0.06, 0.6, 0.6),
			offset = CFrame.new(0, BY, -0.41) * CYLINDER_Z,
			color = pvcFitting,
		},
		{
			name = "ChamberPrint",
			size = Vector3.new(0.02, 0.04, 0.5),
			offset = CFrame.new(0.43, BY, 0.55),
			color = ink,
		},

		-- Schrader fill valve on the rear cap
		{
			name = "SchraderGrommet",
			shape = CYL,
			size = Vector3.new(0.06, 0.14, 0.14),
			offset = CFrame.new(0.18, 0.8, 1.09) * CYLINDER_Z,
			color = rubber,
			material = M.Rubber,
		},
		{
			name = "SchraderStem",
			shape = CYL,
			size = Vector3.new(0.14, 0.08, 0.08),
			offset = CFrame.new(0.18, 0.8, 1.17) * CYLINDER_Z,
			color = brass,
			material = M.Metal,
			reflectance = 0.15,
		},
		{
			name = "SchraderDustCap",
			shape = CYL,
			size = Vector3.new(0.07, 0.1, 0.1),
			offset = CFrame.new(0.18, 0.8, 1.26) * CYLINDER_Z,
			color = black,
			material = M.Plastic,
		},

		-- Purple primer smears beside each solvent-welded joint
		{
			name = "PrimerChamberRear",
			shape = CYL,
			size = Vector3.new(0.05, 0.875, 0.875),
			offset = CFrame.new(0, BY, 0.82) * CYLINDER_Z,
			color = primer,
			transparency = 0.25,
		},
		{
			name = "PrimerChamberFront",
			shape = CYL,
			size = Vector3.new(0.05, 0.875, 0.875),
			offset = CFrame.new(0, BY, -0.09) * CYLINDER_Z,
			color = primer,
			transparency = 0.25,
		},
		{
			name = "PrimerBarrelRear",
			shape = CYL,
			size = Vector3.new(0.05, 0.545, 0.545),
			offset = CFrame.new(0, BY, -0.97) * CYLINDER_Z,
			color = primer,
			transparency = 0.25,
		},
		{
			name = "PrimerBarrelTee",
			shape = CYL,
			size = Vector3.new(0.05, 0.545, 0.545),
			offset = CFrame.new(0, BY, -1.43) * CYLINDER_Z,
			color = primer,
			transparency = 0.25,
		},
		{
			name = "PrimerBarrelMuzzle",
			shape = CYL,
			size = Vector3.new(0.05, 0.545, 0.545),
			offset = CFrame.new(0, BY, -1.79) * CYLINDER_Z,
			color = primer,
			transparency = 0.25,
		},

		-- Brass ball valve (lever open, parallel to the bore)
		{
			name = "ValveAdapterRear",
			shape = CYL,
			size = Vector3.new(0.08, 0.36, 0.36),
			offset = CFrame.new(0, BY, -0.46) * CYLINDER_Z,
			color = brass,
			material = M.Metal,
			reflectance = 0.15,
		},
		{
			name = "ValveCore",
			shape = CYL,
			size = Vector3.new(0.34, 0.4, 0.4),
			offset = CFrame.new(0, BY, -0.66) * CYLINDER_Z,
			color = brass,
			material = M.Metal,
			reflectance = 0.15,
		},
		{
			name = "ValveBulge",
			shape = CYL,
			size = Vector3.new(0.2, 0.52, 0.52),
			offset = CFrame.new(0, BY, -0.66) * CYLINDER_Z,
			color = brass,
			material = M.Metal,
			reflectance = 0.15,
		},
		{
			name = "ValveHexRearA",
			size = Vector3.new(0.42, 0.42, 0.08),
			offset = CFrame.new(0, BY, -0.535),
			color = brass,
			material = M.Metal,
			reflectance = 0.15,
		},
		{
			name = "ValveHexRearB",
			size = Vector3.new(0.42, 0.42, 0.08),
			offset = CFrame.new(0, BY, -0.535) * CFrame.Angles(0, 0, R(45)),
			color = brass,
			material = M.Metal,
			reflectance = 0.15,
		},
		{
			name = "ValveHexFrontA",
			size = Vector3.new(0.42, 0.42, 0.08),
			offset = CFrame.new(0, BY, -0.785),
			color = brass,
			material = M.Metal,
			reflectance = 0.15,
		},
		{
			name = "ValveHexFrontB",
			size = Vector3.new(0.42, 0.42, 0.08),
			offset = CFrame.new(0, BY, -0.785) * CFrame.Angles(0, 0, R(45)),
			color = brass,
			material = M.Metal,
			reflectance = 0.15,
		},
		{
			name = "ValveAdapterFront",
			shape = CYL,
			size = Vector3.new(0.08, 0.36, 0.36),
			offset = CFrame.new(0, BY, -0.86) * CYLINDER_Z,
			color = brass,
			material = M.Metal,
			reflectance = 0.15,
		},
		{
			name = "ValveStem",
			shape = CYL,
			size = Vector3.new(0.3, 0.1, 0.1),
			offset = CFrame.new(0, 1.14, -0.66) * CYLINDER_Y,
			color = steel,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "ValveStemNut",
			size = Vector3.new(0.13, 0.04, 0.13),
			offset = CFrame.new(0, 1.24, -0.66),
			color = steel,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "ValveLeverSteel",
			size = Vector3.new(0.09, 0.03, 0.22),
			offset = CFrame.new(0, 1.28, -0.62),
			color = steel,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "ValveLeverGrip",
			size = Vector3.new(0.12, 0.06, 0.5),
			offset = CFrame.new(0, 1.28, -0.3),
			color = leverRed,
			material = M.Plastic,
		},

		-- Barrel
		{
			name = "BarrelPipe",
			shape = CYL,
			size = Vector3.new(1.12, 0.52, 0.52),
			offset = CFrame.new(0, BY, -1.44) * CYLINDER_Z,
			color = pvcPipe,
		},
		{
			name = "TeeRun",
			shape = CYL,
			size = Vector3.new(0.4, 0.6, 0.6),
			offset = CFrame.new(0, BY, -1.2) * CYLINDER_Z,
			color = pvcFitting,
		},
		{
			name = "TeeBranch",
			shape = CYL,
			size = Vector3.new(0.3, 0.6, 0.6),
			offset = CFrame.new(0, 1.05, -1.2) * CYLINDER_Y,
			color = pvcFitting,
		},
		{
			name = "MuzzleCoupling",
			shape = CYL,
			size = Vector3.new(0.2, 0.62, 0.62),
			offset = CFrame.new(0, BY, -1.92) * CYLINDER_Z,
			color = pvcFitting,
		},
		{
			name = "BarrelPrint",
			size = Vector3.new(0.02, 0.03, 0.3),
			offset = CFrame.new(0.265, BY, -1.6),
			color = ink,
		},

		-- Clear paintball-style hopper full of tomatoes
		{
			name = "HopperNeck",
			shape = CYL,
			size = Vector3.new(0.2, 0.4, 0.4),
			offset = CFrame.new(0, 1.25, -1.2) * CYLINDER_Y,
			color = black,
			material = M.Plastic,
		},
		{
			name = "HopperBody",
			shape = CYL,
			size = Vector3.new(0.5, 0.8, 0.8),
			offset = CFrame.new(0, 1.6, -1.25) * CYLINDER_Z,
			color = hopperClear,
			material = M.Glass,
			transparency = 0.6,
		},
		{
			name = "HopperFrontDome",
			shape = BALL,
			size = Vector3.new(0.8, 0.8, 0.8),
			offset = CFrame.new(0, 1.6, -1.5),
			color = hopperClear,
			material = M.Glass,
			transparency = 0.6,
		},
		{
			name = "HopperRearDome",
			shape = BALL,
			size = Vector3.new(0.8, 0.8, 0.8),
			offset = CFrame.new(0, 1.6, -1),
			color = hopperClear,
			material = M.Glass,
			transparency = 0.6,
		},
		{
			name = "HopperLid",
			shape = CYL,
			size = Vector3.new(0.06, 0.4, 0.4),
			offset = CFrame.new(0, 2.02, -1.25) * CYLINDER_Y,
			color = black,
			material = M.Plastic,
		},
		{
			name = "HopperTomato1",
			shape = BALL,
			size = Vector3.new(0.32, 0.32, 0.32),
			offset = CFrame.new(-0.13, 1.45, -1.1),
			color = tomato,
			reflectance = 0.08,
		},
		{
			name = "HopperTomato2",
			shape = BALL,
			size = Vector3.new(0.32, 0.32, 0.32),
			offset = CFrame.new(0.13, 1.47, -1.35),
			color = tomato,
			reflectance = 0.08,
		},
		{
			name = "HopperTomato3",
			shape = BALL,
			size = Vector3.new(0.32, 0.32, 0.32),
			offset = CFrame.new(0, 1.74, -1.25),
			color = tomato,
			reflectance = 0.08,
		},
		{
			name = "HopperTomato4",
			shape = BALL,
			size = Vector3.new(0.32, 0.32, 0.32),
			offset = CFrame.new(0.1, 1.5, -0.82),
			color = tomato,
			reflectance = 0.08,
		},

		-- Tomato loaded in the muzzle
		{
			name = "MuzzleTomato",
			shape = BALL,
			size = Vector3.new(0.46, 0.46, 0.46),
			offset = CFrame.new(0, BY, -2.02),
			color = tomato,
			reflectance = 0.08,
		},
		{
			name = "CalyxLeafA",
			size = Vector3.new(0.24, 0.035, 0.05),
			offset = CFrame.new(0, BY, -2.235),
			color = calyx,
		},
		{
			name = "CalyxLeafB",
			size = Vector3.new(0.24, 0.035, 0.05),
			offset = CFrame.new(0, BY, -2.235) * CFrame.Angles(0, 0, R(60)),
			color = calyx,
		},
		{
			name = "CalyxLeafC",
			size = Vector3.new(0.24, 0.035, 0.05),
			offset = CFrame.new(0, BY, -2.235) * CFrame.Angles(0, 0, R(120)),
			color = calyx,
		},
		{
			name = "CalyxStem",
			shape = CYL,
			size = Vector3.new(0.06, 0.04, 0.04),
			offset = CFrame.new(0, BY, -2.27) * CYLINDER_Z,
			color = calyx,
		},

		-- Pressure gauge, dial facing the wielder
		{
			name = "GaugeBushing",
			shape = CYL,
			size = Vector3.new(0.16, 0.12, 0.12),
			offset = CFrame.new(0, 1.22, 0.55) * CYLINDER_Y,
			color = brass,
			material = M.Metal,
			reflectance = 0.15,
		},
		{
			name = "GaugeBody",
			shape = CYL,
			size = Vector3.new(0.12, 0.42, 0.42),
			offset = CFrame.new(0, 1.5, 0.55) * CYLINDER_Z,
			color = chrome,
			material = M.Metal,
			reflectance = 0.25,
		},
		{
			name = "GaugeFace",
			shape = CYL,
			size = Vector3.new(0.02, 0.36, 0.36),
			offset = CFrame.new(0, 1.5, 0.615) * CYLINDER_Z,
			color = gaugeFace,
		},
		{
			name = "GaugeNeedle",
			size = Vector3.new(0.02, 0.14, 0.006),
			offset = CFrame.new(0.04, 1.53, 0.632) * CFrame.Angles(0, 0, R(-35)),
			color = needle,
		},
		{
			name = "GaugeHub",
			shape = CYL,
			size = Vector3.new(0.02, 0.04, 0.04),
			offset = CFrame.new(0, 1.5, 0.635) * CYLINDER_Z,
			color = black,
			material = M.Plastic,
		},
		{
			name = "GaugeLens",
			shape = CYL,
			size = Vector3.new(0.01, 0.38, 0.38),
			offset = CFrame.new(0, 1.5, 0.652) * CYLINDER_Z,
			color = hopperClear,
			material = M.Glass,
			transparency = 0.7,
		},

		-- Pistol grip
		{
			name = "GripBody",
			size = Vector3.new(0.32, 0.95, 0.5),
			offset = G,
			color = black,
			material = M.Plastic,
		},
		{
			name = "GripPanelL",
			size = Vector3.new(0.02, 0.7, 0.4),
			offset = G * CFrame.new(-0.165, -0.02, 0),
			color = rubber,
			material = M.Rubber,
		},
		{
			name = "GripPanelR",
			size = Vector3.new(0.02, 0.7, 0.4),
			offset = G * CFrame.new(0.165, -0.02, 0),
			color = rubber,
			material = M.Rubber,
		},
		{
			name = "GripBackstrap",
			shape = CYL,
			size = Vector3.new(0.95, 0.32, 0.32),
			offset = G * CFrame.new(0, 0, 0.25) * CYLINDER_Y,
			color = black,
			material = M.Plastic,
		},
		{
			name = "GripButtCap",
			size = Vector3.new(0.36, 0.06, 0.68),
			offset = G * CFrame.new(0, -0.5, 0.08),
			color = black,
			material = M.Plastic,
		},
		{
			name = "GripFinger1",
			shape = CYL,
			size = Vector3.new(0.33, 0.12, 0.12),
			offset = G * CFrame.new(0, 0.12, -0.25),
			color = black,
			material = M.Plastic,
		},
		{
			name = "GripFinger2",
			shape = CYL,
			size = Vector3.new(0.33, 0.12, 0.12),
			offset = G * CFrame.new(0, -0.1, -0.25),
			color = black,
			material = M.Plastic,
		},
		{
			name = "GripFinger3",
			shape = CYL,
			size = Vector3.new(0.33, 0.12, 0.12),
			offset = G * CFrame.new(0, -0.32, -0.25),
			color = black,
			material = M.Plastic,
		},
		{
			name = "GripAdapterPlate",
			size = Vector3.new(0.3, 0.08, 0.75),
			offset = CFrame.new(0, 0.33, -0.15),
			color = black,
			material = M.Plastic,
		},

		-- Trigger group
		{
			name = "TriggerHousing",
			size = Vector3.new(0.26, 0.2, 0.5),
			offset = CFrame.new(0, 0.27, -0.55),
			color = black,
			material = M.Plastic,
		},
		{
			name = "TriggerMount",
			size = Vector3.new(0.1, 0.14, 0.1),
			offset = CFrame.new(0, 0.43, -0.66),
			color = steel,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "TriggerUpper",
			size = Vector3.new(0.08, 0.16, 0.08),
			offset = CFrame.new(0, 0.11, -0.5),
			color = steel,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "TriggerLower",
			size = Vector3.new(0.08, 0.14, 0.08),
			offset = CFrame.new(0, -0.01, -0.47) * CFrame.Angles(R(-20), 0, 0),
			color = steel,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "GuardFrontPost",
			size = Vector3.new(0.1, 0.42, 0.06),
			offset = CFrame.new(0, 0.07, -0.78),
			color = black,
			material = M.Plastic,
		},
		{
			name = "GuardBottomBar",
			size = Vector3.new(0.1, 0.05, 0.64),
			offset = CFrame.new(0, -0.14, -0.49),
			color = black,
			material = M.Plastic,
		},

		-- Stainless hose clamps strapping the grip to the chamber
		{
			name = "ClampRear",
			shape = CYL,
			size = Vector3.new(0.05, 0.89, 0.89),
			offset = CFrame.new(0, BY, 0.25) * CYLINDER_Z,
			color = steel,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "ClampFront",
			shape = CYL,
			size = Vector3.new(0.05, 0.89, 0.89),
			offset = CFrame.new(0, BY, -0.05) * CYLINDER_Z,
			color = steel,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "ClampScrewRear",
			size = Vector3.new(0.08, 0.12, 0.1),
			offset = CFrame.new(0.45, BY, 0.25),
			color = steel,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "ClampScrewFront",
			size = Vector3.new(0.08, 0.12, 0.1),
			offset = CFrame.new(0.45, BY, -0.05),
			color = steel,
			material = M.Metal,
			reflectance = 0.1,
		},
	},
})
