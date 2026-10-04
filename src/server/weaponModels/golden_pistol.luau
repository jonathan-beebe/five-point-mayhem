-- Golden Pistol: IMI/Magnum Research Desert Eagle Mark XIX .50 AE in Titanium Gold finish.

local WeaponModel = require(script.Parent.Parent.systems.WeaponModel)

local rgb = Color3.fromRGB
local M = Enum.Material
local CYLINDER_Z = WeaponModel.CYLINDER_Z
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball
local rad = math.rad

-- Wedge orientations for chamfers running along Z (size.X = length, size.Z = width).
local CHAMFER_R = CFrame.Angles(0, rad(-90), 0) -- slope faces up and +X
local CHAMFER_L = CFrame.Angles(0, rad(90), 0) -- slope faces up and -X

-- Grip frame: raked 15 degrees, top forward, bottom rearward.
local GRIP = CFrame.new(0, -0.12, 0.13) * CFrame.Angles(rad(-15), 0, 0)

local POLISHED_GOLD = rgb(226, 180, 60)
local BRUSHED_GOLD = rgb(196, 154, 52)
local DARK_GOLD = rgb(120, 88, 28)
local BLACK_STEEL = rgb(32, 32, 36)
local BORE_BLACK = rgb(12, 12, 14)
local GRIP_RUBBER = rgb(22, 22, 24)
local TRITIUM = rgb(120, 255, 150)

local POLISHED = 0.2

return WeaponModel.define({
	handle = {
		size = Vector3.new(0.30, 0.60, 0.40),
		color = POLISHED_GOLD,
		material = M.Metal,
		transparency = 1,
	},
	muzzle = CFrame.new(0, 0.55, -1.98),
	pieces = {
		-- Slide
		{
			name = "SlideBody",
			size = Vector3.new(0.32, 0.26, 1.00),
			offset = CFrame.new(0, 0.53, -0.05),
			color = POLISHED_GOLD,
			material = M.Metal,
			reflectance = POLISHED,
		},
		{
			name = "SlideTop",
			size = Vector3.new(0.20, 0.06, 1.00),
			offset = CFrame.new(0, 0.69, -0.05),
			color = POLISHED_GOLD,
			material = M.Metal,
			reflectance = POLISHED,
		},
		{
			name = "SlideChamferR",
			class = "WedgePart",
			size = Vector3.new(1.00, 0.06, 0.06),
			offset = CFrame.new(0.13, 0.69, -0.05) * CHAMFER_R,
			color = POLISHED_GOLD,
			material = M.Metal,
			reflectance = POLISHED,
		},
		{
			name = "SlideChamferL",
			class = "WedgePart",
			size = Vector3.new(1.00, 0.06, 0.06),
			offset = CFrame.new(-0.13, 0.69, -0.05) * CHAMFER_L,
			color = POLISHED_GOLD,
			material = M.Metal,
			reflectance = POLISHED,
		},
		{
			name = "Serration1",
			size = Vector3.new(0.34, 0.14, 0.022),
			offset = CFrame.new(0, 0.49, 0.38),
			color = DARK_GOLD,
			material = M.Metal,
		},
		{
			name = "Serration2",
			size = Vector3.new(0.34, 0.14, 0.022),
			offset = CFrame.new(0, 0.49, 0.33),
			color = DARK_GOLD,
			material = M.Metal,
		},
		{
			name = "Serration3",
			size = Vector3.new(0.34, 0.14, 0.022),
			offset = CFrame.new(0, 0.49, 0.28),
			color = DARK_GOLD,
			material = M.Metal,
		},
		{
			name = "Serration4",
			size = Vector3.new(0.34, 0.14, 0.022),
			offset = CFrame.new(0, 0.49, 0.23),
			color = DARK_GOLD,
			material = M.Metal,
		},
		{
			name = "Serration5",
			size = Vector3.new(0.34, 0.14, 0.022),
			offset = CFrame.new(0, 0.49, 0.18),
			color = DARK_GOLD,
			material = M.Metal,
		},
		{
			name = "EjectionPort",
			size = Vector3.new(0.02, 0.12, 0.26),
			offset = CFrame.new(0.165, 0.595, -0.30),
			color = BLACK_STEEL,
			material = M.Metal,
		},
		{
			name = "SlideBarrelSeam",
			size = Vector3.new(0.34, 0.24, 0.02),
			offset = CFrame.new(0, 0.52, -0.55),
			color = DARK_GOLD,
			material = M.Metal,
		},

		-- Slide controls and hammer
		{
			name = "SafetyPivotR",
			shape = CYL,
			size = Vector3.new(0.04, 0.10, 0.10),
			offset = CFrame.new(0.17, 0.61, 0.36),
			color = DARK_GOLD,
			material = M.Metal,
		},
		{
			name = "SafetyPivotL",
			shape = CYL,
			size = Vector3.new(0.04, 0.10, 0.10),
			offset = CFrame.new(-0.17, 0.61, 0.36),
			color = DARK_GOLD,
			material = M.Metal,
		},
		{
			name = "SafetyLeverR",
			size = Vector3.new(0.03, 0.05, 0.16),
			offset = CFrame.new(0.17, 0.61, 0.28),
			color = POLISHED_GOLD,
			material = M.Metal,
			reflectance = POLISHED,
		},
		{
			name = "SafetyLeverL",
			size = Vector3.new(0.03, 0.05, 0.16),
			offset = CFrame.new(-0.17, 0.61, 0.28),
			color = POLISHED_GOLD,
			material = M.Metal,
			reflectance = POLISHED,
		},
		{
			name = "Hammer",
			size = Vector3.new(0.10, 0.16, 0.07),
			offset = CFrame.new(0, 0.52, 0.47) * CFrame.Angles(rad(20), 0, 0),
			color = POLISHED_GOLD,
			material = M.Metal,
			reflectance = POLISHED,
		},
		{
			name = "HammerSpur",
			shape = CYL,
			size = Vector3.new(0.10, 0.09, 0.09),
			offset = CFrame.new(0, 0.60, 0.50),
			color = POLISHED_GOLD,
			material = M.Metal,
			reflectance = POLISHED,
		},

		-- Rear sight
		{
			name = "RearSightR",
			size = Vector3.new(0.07, 0.07, 0.08),
			offset = CFrame.new(0.065, 0.755, 0.36),
			color = BLACK_STEEL,
			material = M.Metal,
		},
		{
			name = "RearSightL",
			size = Vector3.new(0.07, 0.07, 0.08),
			offset = CFrame.new(-0.065, 0.755, 0.36),
			color = BLACK_STEEL,
			material = M.Metal,
		},
		{
			name = "RearDotR",
			shape = BALL,
			size = Vector3.new(0.03, 0.03, 0.03),
			offset = CFrame.new(0.065, 0.765, 0.405),
			color = TRITIUM,
			material = M.Neon,
		},
		{
			name = "RearDotL",
			shape = BALL,
			size = Vector3.new(0.03, 0.03, 0.03),
			offset = CFrame.new(-0.065, 0.765, 0.405),
			color = TRITIUM,
			material = M.Neon,
		},

		-- Barrel
		{
			name = "BarrelBody",
			size = Vector3.new(0.30, 0.26, 1.40),
			offset = CFrame.new(0, 0.53, -1.25),
			color = POLISHED_GOLD,
			material = M.Metal,
			reflectance = POLISHED,
		},
		{
			name = "BarrelRib",
			size = Vector3.new(0.14, 0.08, 1.40),
			offset = CFrame.new(0, 0.70, -1.25),
			color = POLISHED_GOLD,
			material = M.Metal,
			reflectance = POLISHED,
		},
		{
			name = "BarrelChamferR",
			class = "WedgePart",
			size = Vector3.new(1.40, 0.06, 0.08),
			offset = CFrame.new(0.11, 0.69, -1.25) * CHAMFER_R,
			color = POLISHED_GOLD,
			material = M.Metal,
			reflectance = POLISHED,
		},
		{
			name = "BarrelChamferL",
			class = "WedgePart",
			size = Vector3.new(1.40, 0.06, 0.08),
			offset = CFrame.new(-0.11, 0.69, -1.25) * CHAMFER_L,
			color = POLISHED_GOLD,
			material = M.Metal,
			reflectance = POLISHED,
		},
		{
			name = "BarrelFlat",
			size = Vector3.new(0.32, 0.14, 1.10),
			offset = CFrame.new(0, 0.53, -1.22),
			color = BRUSHED_GOLD,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "RailSlot1",
			size = Vector3.new(0.16, 0.02, 0.025),
			offset = CFrame.new(0, 0.74, -0.75),
			color = DARK_GOLD,
			material = M.Metal,
		},
		{
			name = "RailSlot2",
			size = Vector3.new(0.16, 0.02, 0.025),
			offset = CFrame.new(0, 0.74, -0.95),
			color = DARK_GOLD,
			material = M.Metal,
		},
		{
			name = "RailSlot3",
			size = Vector3.new(0.16, 0.02, 0.025),
			offset = CFrame.new(0, 0.74, -1.15),
			color = DARK_GOLD,
			material = M.Metal,
		},
		{
			name = "RailSlot4",
			size = Vector3.new(0.16, 0.02, 0.025),
			offset = CFrame.new(0, 0.74, -1.35),
			color = DARK_GOLD,
			material = M.Metal,
		},
		{
			name = "RailSlot5",
			size = Vector3.new(0.16, 0.02, 0.025),
			offset = CFrame.new(0, 0.74, -1.55),
			color = DARK_GOLD,
			material = M.Metal,
		},
		{
			name = "MuzzleCrown",
			shape = CYL,
			size = Vector3.new(0.02, 0.17, 0.17),
			offset = CFrame.new(0, 0.55, -1.95) * CYLINDER_Z,
			color = POLISHED_GOLD,
			material = M.Metal,
			reflectance = 0.3,
		},
		{
			name = "Bore",
			shape = CYL,
			size = Vector3.new(0.03, 0.10, 0.10),
			offset = CFrame.new(0, 0.55, -1.955) * CYLINDER_Z,
			color = BORE_BLACK,
			material = M.SmoothPlastic,
		},

		-- Front sight
		{
			name = "FrontSight",
			size = Vector3.new(0.05, 0.08, 0.10),
			offset = CFrame.new(0, 0.78, -1.84),
			color = BLACK_STEEL,
			material = M.Metal,
		},
		{
			name = "FrontDot",
			shape = BALL,
			size = Vector3.new(0.03, 0.03, 0.03),
			offset = CFrame.new(0, 0.795, -1.785),
			color = TRITIUM,
			material = M.Neon,
		},

		-- Frame
		{
			name = "FrameBody",
			size = Vector3.new(0.30, 0.20, 2.02),
			offset = CFrame.new(0, 0.30, -0.59),
			color = POLISHED_GOLD,
			material = M.Metal,
			reflectance = POLISHED,
		},
		{
			name = "SeamSlideFrame",
			size = Vector3.new(0.34, 0.016, 1.00),
			offset = CFrame.new(0, 0.40, -0.05),
			color = DARK_GOLD,
			material = M.Metal,
		},
		{
			name = "SeamBarrelFrame",
			size = Vector3.new(0.32, 0.016, 1.05),
			offset = CFrame.new(0, 0.40, -1.075),
			color = DARK_GOLD,
			material = M.Metal,
		},
		{
			name = "TriggerPin",
			shape = CYL,
			size = Vector3.new(0.32, 0.04, 0.04),
			offset = CFrame.new(0, 0.27, -0.24),
			color = DARK_GOLD,
			material = M.Metal,
		},
		{
			name = "HammerPin",
			shape = CYL,
			size = Vector3.new(0.32, 0.04, 0.04),
			offset = CFrame.new(0, 0.30, 0.32),
			color = DARK_GOLD,
			material = M.Metal,
		},
		{
			name = "SlideStop",
			size = Vector3.new(0.02, 0.05, 0.24),
			offset = CFrame.new(-0.155, 0.35, -0.24),
			color = DARK_GOLD,
			material = M.Metal,
		},
		{
			name = "BarrelRelease",
			size = Vector3.new(0.02, 0.06, 0.06),
			offset = CFrame.new(-0.155, 0.30, -0.68),
			color = DARK_GOLD,
			material = M.Metal,
		},

		-- Trigger group
		{
			name = "GuardBar",
			size = Vector3.new(0.10, 0.05, 0.53),
			offset = CFrame.new(0, -0.02, -0.365),
			color = POLISHED_GOLD,
			material = M.Metal,
			reflectance = POLISHED,
		},
		{
			name = "GuardPost",
			size = Vector3.new(0.10, 0.27, 0.06),
			offset = CFrame.new(0, 0.09, -0.60),
			color = POLISHED_GOLD,
			material = M.Metal,
			reflectance = POLISHED,
		},
		{
			name = "GuardHook",
			class = "WedgePart",
			size = Vector3.new(0.10, 0.08, 0.08),
			offset = CFrame.new(0, -0.005, -0.67),
			color = POLISHED_GOLD,
			material = M.Metal,
			reflectance = POLISHED,
		},
		{
			name = "Trigger",
			size = Vector3.new(0.06, 0.18, 0.05),
			offset = CFrame.new(0, 0.13, -0.30) * CFrame.Angles(rad(15), 0, 0),
			color = POLISHED_GOLD,
			material = M.Metal,
			reflectance = POLISHED,
		},
		{
			name = "TriggerToe",
			shape = CYL,
			size = Vector3.new(0.06, 0.06, 0.06),
			offset = CFrame.new(0, 0.05, -0.33),
			color = POLISHED_GOLD,
			material = M.Metal,
			reflectance = POLISHED,
		},

		-- Grip
		{
			name = "GripCore",
			size = Vector3.new(0.29, 0.80, 0.42),
			offset = GRIP,
			color = POLISHED_GOLD,
			material = M.Metal,
			reflectance = POLISHED,
		},
		{
			name = "GripPanelR",
			size = Vector3.new(0.02, 0.66, 0.34),
			offset = GRIP * CFrame.new(0.155, -0.02, 0),
			color = GRIP_RUBBER,
			material = M.Rubber,
		},
		{
			name = "GripPanelL",
			size = Vector3.new(0.02, 0.66, 0.34),
			offset = GRIP * CFrame.new(-0.155, -0.02, 0),
			color = GRIP_RUBBER,
			material = M.Rubber,
		},
		{
			name = "GripScrewR",
			shape = CYL,
			size = Vector3.new(0.02, 0.05, 0.05),
			offset = GRIP * CFrame.new(0.17, 0.02, 0),
			color = POLISHED_GOLD,
			material = M.Metal,
			reflectance = POLISHED,
		},
		{
			name = "GripScrewL",
			shape = CYL,
			size = Vector3.new(0.02, 0.05, 0.05),
			offset = GRIP * CFrame.new(-0.17, 0.02, 0),
			color = POLISHED_GOLD,
			material = M.Metal,
			reflectance = POLISHED,
		},
		{
			name = "MagBaseplate",
			size = Vector3.new(0.32, 0.06, 0.46),
			offset = GRIP * CFrame.new(0, -0.43, 0),
			color = POLISHED_GOLD,
			material = M.Metal,
			reflectance = POLISHED,
		},
		{
			name = "MagRelease",
			size = Vector3.new(0.03, 0.06, 0.06),
			offset = CFrame.new(-0.16, 0.15, -0.10),
			color = BLACK_STEEL,
			material = M.Metal,
		},
	},
})
