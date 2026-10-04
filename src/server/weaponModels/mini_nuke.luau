-- Mini Nuke: M28 "Davy Crockett" 120 mm recoilless launcher, shoulder-fired, with an M388 warhead on the spigot.

local WeaponModel = require(script.Parent.Parent.systems.WeaponModel)

local rgb = Color3.fromRGB
local M = Enum.Material
local CYLINDER_Z = WeaponModel.CYLINDER_Z
local CYLINDER_Y = WeaponModel.CYLINDER_Y
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball
local rad = math.rad

local OLIVE_DRAB = rgb(76, 84, 54)
local OLIVE_DARK = rgb(58, 64, 42)
local WARHEAD_OLIVE = rgb(88, 96, 62)
local GUNMETAL = rgb(50, 52, 55)
local STEEL = rgb(150, 152, 156)
local BORE_BLACK = rgb(18, 18, 18)
local SCORCHED = rgb(62, 56, 50)
local GRIP_BLACK = rgb(34, 34, 32)
local RUBBER = rgb(26, 26, 26)
local HAZARD_YELLOW = rgb(230, 230, 60)
local BRASS = rgb(176, 142, 78)
local DATA_WHITE = rgb(214, 208, 190)
local LENS_GLASS = rgb(90, 120, 115)
local ARM_LAMP = rgb(255, 170, 40)

local AXIS_Y = 0.7

-- Pistol-grip frame: bottom of the grip raked toward the wielder (+Z).
local G = CFrame.new(0, -0.05, 0.02) * CFrame.Angles(rad(-12), 0, 0)

local BAND_SIZE = Vector3.new(0.12, 0.96, 0.96)
local HAZARD_SIZE = Vector3.new(0.1, 0.92, 0.92)
local SCREW_SIZE = Vector3.new(0.02, 0.05, 0.05)
local FIN_SIZE = Vector3.new(0.03, 0.44, 0.3)
local WARHEAD_BAND_SIZE = Vector3.new(0.06, 1.12, 1.12)

local function onAxis(z: number): CFrame
	return CFrame.new(0, AXIS_Y, z) * CYLINDER_Z
end

local function fin(k: number): CFrame
	return CFrame.new(0, AXIS_Y, -4.02)
		* CFrame.Angles(0, 0, rad(45 + 90 * k))
		* CFrame.new(0, 0.38, 0)
end

return WeaponModel.define({
	handle = {
		size = Vector3.new(0.24, 0.5, 0.3),
		color = GRIP_BLACK,
		material = M.Plastic,
		transparency = 1,
	},
	muzzle = CFrame.new(0, AXIS_Y, -5.3),
	pieces = {
		-- Tube and breech
		{
			name = "TubeMain",
			shape = CYL,
			size = Vector3.new(4.2, 0.9, 0.9),
			offset = onAxis(-1.5),
			color = OLIVE_DRAB,
			material = M.Metal,
		},
		{
			name = "BandRear",
			shape = CYL,
			size = BAND_SIZE,
			offset = onAxis(0.45),
			color = OLIVE_DARK,
			material = M.Metal,
		},
		{
			name = "BandMid",
			shape = CYL,
			size = BAND_SIZE,
			offset = onAxis(-1.6),
			color = OLIVE_DARK,
			material = M.Metal,
		},
		{
			name = "BandFront",
			shape = CYL,
			size = BAND_SIZE,
			offset = onAxis(-3.0),
			color = OLIVE_DARK,
			material = M.Metal,
		},
		{
			name = "HazardBandA",
			shape = CYL,
			size = HAZARD_SIZE,
			offset = onAxis(-2.35),
			color = HAZARD_YELLOW,
			material = M.SmoothPlastic,
		},
		{
			name = "HazardBandB",
			shape = CYL,
			size = HAZARD_SIZE,
			offset = onAxis(-2.6),
			color = HAZARD_YELLOW,
			material = M.SmoothPlastic,
		},
		{
			name = "MuzzleCollar",
			shape = CYL,
			size = Vector3.new(0.25, 1.0, 1.0),
			offset = onAxis(-3.49),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "MuzzleBore",
			shape = CYL,
			size = Vector3.new(0.02, 0.72, 0.72),
			offset = onAxis(-3.62),
			color = BORE_BLACK,
			material = M.SmoothPlastic,
		},
		-- Lengthened from 0.2 to 0.22 so it overlaps the venturi flare instead of leaving a 0.01 gap.
		{
			name = "BreechRing",
			shape = CYL,
			size = Vector3.new(0.22, 1.0, 1.0),
			offset = onAxis(0.65),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "VenturiFlare",
			shape = CYL,
			size = Vector3.new(0.25, 1.1, 1.1),
			offset = onAxis(0.875),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "VenturiLip",
			shape = CYL,
			size = Vector3.new(0.04, 1.16, 1.16),
			offset = onAxis(0.985),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "VenturiThroat",
			shape = CYL,
			size = Vector3.new(0.03, 0.8, 0.8),
			offset = onAxis(1.01),
			color = SCORCHED,
			material = M.CorrodedMetal,
		},
		{
			name = "VenturiCore",
			shape = CYL,
			size = Vector3.new(0.03, 0.45, 0.45),
			offset = onAxis(1.03),
			color = BORE_BLACK,
			material = M.SmoothPlastic,
		},

		-- Shoulder pad
		{
			name = "ShoulderPad",
			size = Vector3.new(0.5, 0.16, 0.35),
			offset = CFrame.new(0, 0.2, 0.4),
			color = RUBBER,
			material = M.Rubber,
		},

		-- Grip and trigger group
		{
			name = "GripMount",
			size = Vector3.new(0.3, 0.12, 0.7),
			offset = CFrame.new(0, 0.21, -0.1),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "PistolGrip",
			size = Vector3.new(0.24, 0.55, 0.32),
			offset = G,
			color = GRIP_BLACK,
			material = M.Plastic,
		},
		{
			name = "GripPanelL",
			size = Vector3.new(0.02, 0.45, 0.26),
			offset = G * CFrame.new(-0.125, -0.02, 0),
			color = RUBBER,
			material = M.Rubber,
		},
		{
			name = "GripPanelR",
			size = Vector3.new(0.02, 0.45, 0.26),
			offset = G * CFrame.new(0.125, -0.02, 0),
			color = RUBBER,
			material = M.Rubber,
		},
		{
			name = "GripCap",
			size = Vector3.new(0.26, 0.05, 0.34),
			offset = G * CFrame.new(0, -0.29, 0),
			color = GRIP_BLACK,
			material = M.Plastic,
		},
		{
			name = "Trigger",
			size = Vector3.new(0.05, 0.2, 0.05),
			offset = CFrame.new(0, 0.07, -0.25) * CFrame.Angles(rad(15), 0, 0),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "GuardBottom",
			size = Vector3.new(0.06, 0.04, 0.36),
			offset = CFrame.new(0, -0.08, -0.3),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "GuardFront",
			size = Vector3.new(0.05, 0.265, 0.04),
			offset = CFrame.new(0, 0.0375, -0.455),
			color = GUNMETAL,
			material = M.Metal,
		},

		-- Foregrip
		{
			name = "ForeGripClamp",
			size = Vector3.new(0.3, 0.12, 0.3),
			offset = CFrame.new(0, 0.21, -1.6),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "ForeGrip",
			shape = CYL,
			size = Vector3.new(0.55, 0.22, 0.22),
			offset = CFrame.new(0, -0.07, -1.6) * CYLINDER_Y,
			color = RUBBER,
			material = M.Rubber,
		},
		{
			name = "ForeGripCap",
			shape = CYL,
			size = Vector3.new(0.05, 0.26, 0.26),
			offset = CFrame.new(0, -0.36, -1.6) * CYLINDER_Y,
			color = GUNMETAL,
			material = M.Metal,
		},

		-- Optical sight, upper left
		{
			name = "ScopeBase",
			size = Vector3.new(0.14, 0.2, 0.45),
			offset = CFrame.new(-0.38, 1.08, -0.6) * CFrame.Angles(0, 0, rad(45)),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "ScopeBody",
			shape = CYL,
			size = Vector3.new(0.9, 0.24, 0.24),
			offset = CFrame.new(-0.48, 1.2, -0.6) * CYLINDER_Z,
			color = OLIVE_DARK,
			material = M.Metal,
		},
		{
			name = "ScopeObjBell",
			shape = CYL,
			size = Vector3.new(0.12, 0.3, 0.3),
			offset = CFrame.new(-0.48, 1.2, -1.08) * CYLINDER_Z,
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "ScopeObjLens",
			shape = CYL,
			size = Vector3.new(0.02, 0.24, 0.24),
			offset = CFrame.new(-0.48, 1.2, -1.145) * CYLINDER_Z,
			color = LENS_GLASS,
			material = M.Glass,
			transparency = 0.35,
			reflectance = 0.25,
		},
		{
			name = "ScopeEyecup",
			shape = CYL,
			size = Vector3.new(0.15, 0.28, 0.28),
			offset = CFrame.new(-0.48, 1.2, -0.1) * CYLINDER_Z,
			color = RUBBER,
			material = M.Rubber,
		},
		{
			name = "ScopeEyeLens",
			shape = CYL,
			size = Vector3.new(0.02, 0.2, 0.2),
			offset = CFrame.new(-0.48, 1.2, -0.02) * CYLINDER_Z,
			color = LENS_GLASS,
			material = M.Glass,
			transparency = 0.35,
			reflectance = 0.25,
		},
		{
			name = "ScopeKnobTop",
			shape = CYL,
			size = Vector3.new(0.08, 0.12, 0.12),
			offset = CFrame.new(-0.48, 1.35, -0.6) * CYLINDER_Y,
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "ScopeKnobSide",
			shape = CYL,
			size = Vector3.new(0.08, 0.12, 0.12),
			offset = CFrame.new(-0.63, 1.2, -0.6),
			color = GUNMETAL,
			material = M.Metal,
		},

		-- Iron sights
		{
			name = "FrontSightBase",
			size = Vector3.new(0.16, 0.08, 0.14),
			offset = CFrame.new(0, 1.17, -3.25),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "FrontSightPost",
			size = Vector3.new(0.04, 0.16, 0.04),
			offset = CFrame.new(0, 1.28, -3.25),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "RearSightBase",
			size = Vector3.new(0.2, 0.14, 0.08),
			offset = CFrame.new(0, 1.2, 0.2),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "RearSightAperture",
			shape = CYL,
			size = Vector3.new(0.03, 0.12, 0.12),
			offset = CFrame.new(0, 1.32, 0.2) * CYLINDER_Z,
			color = GUNMETAL,
			material = M.Metal,
		},

		-- Arming box, right side (cylinders here keep their default X axis, facing outward)
		{
			name = "ArmingBox",
			size = Vector3.new(0.22, 0.3, 0.5),
			offset = CFrame.new(0.52, 0.65, -0.5),
			color = OLIVE_DARK,
			material = M.Metal,
		},
		{
			name = "LampBezel",
			shape = CYL,
			size = Vector3.new(0.03, 0.12, 0.12),
			offset = CFrame.new(0.64, 0.72, -0.38),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "ArmingLamp",
			shape = CYL,
			size = Vector3.new(0.03, 0.08, 0.08),
			offset = CFrame.new(0.665, 0.72, -0.38),
			color = ARM_LAMP,
			material = M.Neon,
		},
		{
			name = "SwitchBase",
			shape = CYL,
			size = Vector3.new(0.03, 0.1, 0.1),
			offset = CFrame.new(0.64, 0.6, -0.6),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "SwitchLever",
			size = Vector3.new(0.14, 0.03, 0.03),
			offset = CFrame.new(0.7, 0.6, -0.6) * CFrame.Angles(0, 0, rad(20)),
			color = STEEL,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "ScrewA",
			shape = CYL,
			size = SCREW_SIZE,
			offset = CFrame.new(0.635, 0.54, -0.28),
			color = STEEL,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "ScrewB",
			shape = CYL,
			size = SCREW_SIZE,
			offset = CFrame.new(0.635, 0.76, -0.28),
			color = STEEL,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "ScrewC",
			shape = CYL,
			size = SCREW_SIZE,
			offset = CFrame.new(0.635, 0.54, -0.72),
			color = STEEL,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "ScrewD",
			shape = CYL,
			size = SCREW_SIZE,
			offset = CFrame.new(0.635, 0.76, -0.72),
			color = STEEL,
			material = M.Metal,
			reflectance = 0.1,
		},

		-- M388 warhead
		{
			name = "PistonRod",
			shape = CYL,
			size = Vector3.new(0.35, 0.3, 0.3),
			offset = onAxis(-3.725),
			color = STEEL,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "TailCone1",
			shape = CYL,
			size = Vector3.new(0.12, 0.5, 0.5),
			offset = onAxis(-3.94),
			color = WARHEAD_OLIVE,
			material = M.Metal,
		},
		{
			name = "TailCone2",
			shape = CYL,
			size = Vector3.new(0.12, 0.75, 0.75),
			offset = onAxis(-4.04),
			color = WARHEAD_OLIVE,
			material = M.Metal,
		},
		{
			name = "TailCone3",
			shape = CYL,
			size = Vector3.new(0.12, 0.95, 0.95),
			offset = onAxis(-4.14),
			color = WARHEAD_OLIVE,
			material = M.Metal,
		},
		{
			name = "WarheadBody",
			shape = CYL,
			size = Vector3.new(0.4, 1.1, 1.1),
			offset = onAxis(-4.38),
			color = WARHEAD_OLIVE,
			material = M.Metal,
		},
		{
			name = "WarheadNose",
			shape = BALL,
			size = Vector3.new(1.1, 1.1, 1.1),
			offset = CFrame.new(0, AXIS_Y, -4.58),
			color = WARHEAD_OLIVE,
			material = M.Metal,
		},
		{
			name = "Fuze",
			shape = CYL,
			size = Vector3.new(0.08, 0.26, 0.26),
			offset = onAxis(-5.15),
			color = BRASS,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "FuzeTip",
			shape = BALL,
			size = Vector3.new(0.12, 0.12, 0.12),
			offset = CFrame.new(0, AXIS_Y, -5.19),
			color = BRASS,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "Fin1",
			size = FIN_SIZE,
			offset = fin(0),
			color = WARHEAD_OLIVE,
			material = M.Metal,
		},
		{
			name = "Fin2",
			size = FIN_SIZE,
			offset = fin(1),
			color = WARHEAD_OLIVE,
			material = M.Metal,
		},
		{
			name = "Fin3",
			size = FIN_SIZE,
			offset = fin(2),
			color = WARHEAD_OLIVE,
			material = M.Metal,
		},
		{
			name = "Fin4",
			size = FIN_SIZE,
			offset = fin(3),
			color = WARHEAD_OLIVE,
			material = M.Metal,
		},
		{
			name = "WarheadBandA",
			shape = CYL,
			size = WARHEAD_BAND_SIZE,
			offset = onAxis(-4.24),
			color = HAZARD_YELLOW,
			material = M.SmoothPlastic,
		},
		{
			name = "WarheadBandB",
			shape = CYL,
			size = WARHEAD_BAND_SIZE,
			offset = onAxis(-4.52),
			color = HAZARD_YELLOW,
			material = M.SmoothPlastic,
		},
		{
			name = "LiftLug",
			size = Vector3.new(0.12, 0.08, 0.16),
			offset = CFrame.new(0, 1.28, -4.38),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "DataPlate",
			size = Vector3.new(0.02, 0.2, 0.18),
			offset = CFrame.new(0.55, AXIS_Y, -4.38),
			color = DATA_WHITE,
			material = M.SmoothPlastic,
		},
	},
})
