-- Rocket Launcher: Saab Carl Gustaf M3/M4 84 mm recoilless rifle, matte olive-drab finish.

local WeaponModel = require(script.Parent.Parent.systems.WeaponModel)

local rgb = Color3.fromRGB
local M = Enum.Material
local CYLINDER_Z = WeaponModel.CYLINDER_Z
local CYLINDER_Y = WeaponModel.CYLINDER_Y
local CYL = Enum.PartType.Cylinder
local A = CFrame.Angles
local rad = math.rad

local OLIVE_DRAB = rgb(70, 90, 60)
local OLIVE_DARK = rgb(54, 68, 46)
local GUNMETAL = rgb(58, 60, 62)
local SIGHT_BLACK = rgb(32, 34, 33)
local BLACK_POLYMER = rgb(36, 37, 38)
local BLACK_RUBBER = rgb(26, 26, 26)
local BORE_DARK = rgb(12, 12, 12)
local LENS_GLASS = rgb(50, 75, 90)
local AMMO_YELLOW = rgb(196, 160, 48)
local STENCIL_TAN = rgb(188, 178, 148)
local SLING_WEBBING = rgb(96, 92, 70)

local AXIS_Y = 0.7

local BAND = Vector3.new(0.12, 0.86, 0.86)
local GRIP_STRAP = Vector3.new(0.76, 0.29, 0.29)
local GRIP_PANEL = Vector3.new(0.02, 0.56, 0.36)
local FOREGRIP_RIDGE = Vector3.new(0.03, 0.32, 0.32)
local SIGHT_LEAF = Vector3.new(0.03, 0.14, 0.04)

-- Pistol grip frame: raked 15 degrees, top forward.
local GRIP = CFrame.new(0, -0.09, 0.03) * A(rad(-15), 0, 0)

local function tube(z: number): CFrame
	return CFrame.new(0, AXIS_Y, z) * CYLINDER_Z
end

return WeaponModel.define({
	handle = {
		size = Vector3.new(0.25, 0.25, 0.25),
		color = BLACK_POLYMER,
		material = M.Plastic,
		transparency = 1,
	},
	muzzle = CFrame.new(0, AXIS_Y, -4.05),
	pieces = {
		-- Tube
		{
			name = "TubeBody",
			shape = CYL,
			size = Vector3.new(3.75, 0.82, 0.82),
			offset = tube(-1.675),
			color = OLIVE_DRAB,
			material = M.Plastic,
		},
		{
			name = "BandRear",
			shape = CYL,
			size = BAND,
			offset = tube(-0.95),
			color = OLIVE_DARK,
			material = M.Plastic,
		},
		{
			name = "BandMid",
			shape = CYL,
			size = BAND,
			offset = tube(-2.3),
			color = OLIVE_DARK,
			material = M.Plastic,
		},
		{
			name = "BandFront",
			shape = CYL,
			size = BAND,
			offset = tube(-2.95),
			color = OLIVE_DARK,
			material = M.Plastic,
		},
		{
			name = "AmmoBand",
			shape = CYL,
			size = Vector3.new(0.08, 0.84, 0.84),
			offset = tube(-3.35),
			color = AMMO_YELLOW,
			material = M.SmoothPlastic,
		},
		{
			name = "MuzzleBumper",
			shape = CYL,
			size = Vector3.new(0.4, 0.96, 0.96),
			offset = tube(-3.75),
			color = BLACK_RUBBER,
			material = M.Rubber,
		},
		{
			name = "MuzzleLip",
			shape = CYL,
			size = Vector3.new(0.05, 0.92, 0.92),
			offset = tube(-3.975),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "MuzzleBore",
			shape = CYL,
			size = Vector3.new(0.06, 0.7, 0.7),
			offset = tube(-3.98),
			color = BORE_DARK,
			material = M.SmoothPlastic,
		},
		{
			name = "BreechRing",
			shape = CYL,
			size = Vector3.new(0.2, 0.9, 0.9),
			offset = tube(0.3),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "VenturiNeck",
			shape = CYL,
			size = Vector3.new(0.15, 0.8, 0.8),
			offset = tube(0.475),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "VenturiCone1",
			shape = CYL,
			size = Vector3.new(0.15, 0.9, 0.9),
			offset = tube(0.625),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "VenturiCone2",
			shape = CYL,
			size = Vector3.new(0.15, 1, 1),
			offset = tube(0.775),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "VenturiRearBumper",
			shape = CYL,
			size = Vector3.new(0.15, 1.08, 1.08),
			offset = tube(0.925),
			color = BLACK_RUBBER,
			material = M.Rubber,
		},
		{
			name = "VenturiThroat",
			shape = CYL,
			size = Vector3.new(0.02, 0.82, 0.82),
			offset = tube(1.005),
			color = BORE_DARK,
			material = M.SmoothPlastic,
		},
		-- Centered on the tube's +X side, between the clamp and the middle band.
		{
			name = "StencilPlate",
			size = Vector3.new(0.02, 0.12, 0.5),
			offset = CFrame.new(0.41, AXIS_Y, -1.95),
			color = STENCIL_TAN,
			material = M.SmoothPlastic,
		},

		-- Shoulder rest
		{
			name = "ShoulderBracket",
			size = Vector3.new(0.14, 0.1, 0.26),
			offset = CFrame.new(0, 0.3, 0.45),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "ShoulderPad",
			size = Vector3.new(0.3, 0.16, 0.34),
			offset = CFrame.new(0, 0.18, 0.45),
			color = BLACK_RUBBER,
			material = M.Rubber,
		},

		-- Grip and trigger group
		-- Mount runs Z -0.80 to +0.22 so the trigger-guard front bolts into it.
		{
			name = "GripMount",
			size = Vector3.new(0.26, 0.14, 1.02),
			offset = CFrame.new(0, 0.27, -0.29),
			color = BLACK_POLYMER,
			material = M.Plastic,
		},
		{
			name = "GripBody",
			size = Vector3.new(0.28, 0.78, 0.42),
			offset = GRIP,
			color = BLACK_POLYMER,
			material = M.Plastic,
		},
		{
			name = "GripFrontStrap",
			shape = CYL,
			size = GRIP_STRAP,
			offset = GRIP * CFrame.new(0, 0, -0.17) * CYLINDER_Y,
			color = BLACK_POLYMER,
			material = M.Plastic,
		},
		{
			name = "GripRearStrap",
			shape = CYL,
			size = GRIP_STRAP,
			offset = GRIP * CFrame.new(0, 0, 0.17) * CYLINDER_Y,
			color = BLACK_POLYMER,
			material = M.Plastic,
		},
		{
			name = "GripPanelL",
			size = GRIP_PANEL,
			offset = GRIP * CFrame.new(-0.15, -0.02, 0),
			color = BLACK_RUBBER,
			material = M.Rubber,
		},
		{
			name = "GripPanelR",
			size = GRIP_PANEL,
			offset = GRIP * CFrame.new(0.15, -0.02, 0),
			color = BLACK_RUBBER,
			material = M.Rubber,
		},
		{
			name = "GripBaseplate",
			size = Vector3.new(0.3, 0.06, 0.64),
			offset = GRIP * CFrame.new(0, -0.41, 0),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "TriggerGuardBottom",
			size = Vector3.new(0.06, 0.04, 0.48),
			offset = CFrame.new(0, -0.1, -0.51),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "TriggerGuardFront",
			size = Vector3.new(0.06, 0.34, 0.04),
			offset = CFrame.new(0, 0.05, -0.75),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "Trigger",
			size = Vector3.new(0.05, 0.26, 0.06),
			offset = CFrame.new(0, 0.09, -0.47) * A(rad(10), 0, 0),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "SafetyLever",
			size = Vector3.new(0.03, 0.06, 0.12),
			offset = CFrame.new(0.14, 0.25, -0.25),
			color = GUNMETAL,
			material = M.Metal,
		},

		-- Foregrip
		{
			name = "ForeGripClamp",
			shape = CYL,
			size = Vector3.new(0.24, 0.88, 0.88),
			offset = tube(-1.5),
			color = BLACK_POLYMER,
			material = M.Plastic,
		},
		{
			name = "ForeGripStem",
			size = Vector3.new(0.24, 0.12, 0.3),
			offset = CFrame.new(0, 0.27, -1.5),
			color = BLACK_POLYMER,
			material = M.Plastic,
		},
		{
			name = "ForeGripBody",
			shape = CYL,
			size = Vector3.new(0.62, 0.3, 0.3),
			offset = CFrame.new(0, -0.09, -1.5) * CYLINDER_Y,
			color = BLACK_RUBBER,
			material = M.Rubber,
		},
		{
			name = "ForeGripCap",
			shape = CYL,
			size = Vector3.new(0.06, 0.34, 0.34),
			offset = CFrame.new(0, -0.42, -1.5) * CYLINDER_Y,
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "ForeGripRidge1",
			shape = CYL,
			size = FOREGRIP_RIDGE,
			offset = CFrame.new(0, -0.25, -1.5) * CYLINDER_Y,
			color = BLACK_POLYMER,
			material = M.Plastic,
		},
		{
			name = "ForeGripRidge2",
			shape = CYL,
			size = FOREGRIP_RIDGE,
			offset = CFrame.new(0, -0.1, -1.5) * CYLINDER_Y,
			color = BLACK_POLYMER,
			material = M.Plastic,
		},
		{
			name = "ForeGripRidge3",
			shape = CYL,
			size = FOREGRIP_RIDGE,
			offset = CFrame.new(0, 0.05, -1.5) * CYLINDER_Y,
			color = BLACK_POLYMER,
			material = M.Plastic,
		},

		-- Optical sight, left side
		{
			name = "SightMountBase",
			size = Vector3.new(0.22, 0.12, 0.6),
			offset = CFrame.new(-0.4, 0.82, -0.9),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "SightArm",
			size = Vector3.new(0.12, 0.2, 0.3),
			offset = CFrame.new(-0.55, 0.92, -0.9),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "ScopeBody",
			shape = CYL,
			size = Vector3.new(1, 0.22, 0.22),
			offset = CFrame.new(-0.6, 1.05, -0.9) * CYLINDER_Z,
			color = SIGHT_BLACK,
			material = M.Metal,
		},
		{
			name = "ScopeObjectiveBell",
			shape = CYL,
			size = Vector3.new(0.2, 0.28, 0.28),
			offset = CFrame.new(-0.6, 1.05, -1.45) * CYLINDER_Z,
			color = SIGHT_BLACK,
			material = M.Metal,
		},
		{
			name = "ScopeObjectiveLens",
			shape = CYL,
			size = Vector3.new(0.02, 0.24, 0.24),
			offset = CFrame.new(-0.6, 1.05, -1.555) * CYLINDER_Z,
			color = LENS_GLASS,
			material = M.Glass,
			transparency = 0.35,
			reflectance = 0.25,
		},
		{
			name = "ScopeEyeRubber",
			shape = CYL,
			size = Vector3.new(0.22, 0.26, 0.26),
			offset = CFrame.new(-0.6, 1.05, -0.35) * CYLINDER_Z,
			color = BLACK_RUBBER,
			material = M.Rubber,
		},
		{
			name = "ScopeEyeLens",
			shape = CYL,
			size = Vector3.new(0.02, 0.2, 0.2),
			offset = CFrame.new(-0.6, 1.05, -0.235) * CYLINDER_Z,
			color = LENS_GLASS,
			material = M.Glass,
			transparency = 0.35,
			reflectance = 0.25,
		},
		{
			name = "ScopeTurretTop",
			shape = CYL,
			size = Vector3.new(0.1, 0.12, 0.12),
			offset = CFrame.new(-0.6, 1.19, -0.95) * CYLINDER_Y,
			color = SIGHT_BLACK,
			material = M.Metal,
		},
		-- Axis along X (no rotation).
		{
			name = "ScopeTurretSide",
			shape = CYL,
			size = Vector3.new(0.1, 0.12, 0.12),
			offset = CFrame.new(-0.74, 1.05, -0.95),
			color = SIGHT_BLACK,
			material = M.Metal,
		},

		-- Iron sights
		{
			name = "FrontSightBase",
			size = Vector3.new(0.12, 0.12, 0.12),
			offset = CFrame.new(0, 1.15, -3.2),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "FrontSightBlade",
			size = Vector3.new(0.03, 0.14, 0.03),
			offset = CFrame.new(0, 1.27, -3.2),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "RearSightBase",
			size = Vector3.new(0.16, 0.08, 0.14),
			offset = CFrame.new(0, 1.14, -0.3),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "RearSightLeafL",
			size = SIGHT_LEAF,
			offset = CFrame.new(-0.05, 1.24, -0.3),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "RearSightLeafR",
			size = SIGHT_LEAF,
			offset = CFrame.new(0.05, 1.24, -0.3),
			color = GUNMETAL,
			material = M.Metal,
		},

		-- Venturi hardware
		{
			name = "VenturiLatch",
			size = Vector3.new(0.08, 0.14, 0.3),
			offset = CFrame.new(0.46, 0.75, 0.35),
			color = GUNMETAL,
			material = M.Metal,
		},
		-- Axis along X (no rotation).
		{
			name = "VenturiLatchKnob",
			shape = CYL,
			size = Vector3.new(0.14, 0.1, 0.1),
			offset = CFrame.new(0.53, 0.75, 0.45),
			color = BLACK_POLYMER,
			material = M.Plastic,
		},
		{
			name = "VenturiHinge",
			shape = CYL,
			size = Vector3.new(0.24, 0.12, 0.12),
			offset = CFrame.new(-0.44, AXIS_Y, 0.4) * CYLINDER_Z,
			color = GUNMETAL,
			material = M.Metal,
		},

		-- Sling, left side: two straps meeting at the sag point (-0.5, 0.2, -1.0).
		{
			name = "SlingSwivelRear",
			size = Vector3.new(0.1, 0.1, 0.1),
			offset = CFrame.new(-0.5, 0.55, 0.75),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "SlingSwivelFront",
			size = Vector3.new(0.12, 0.1, 0.1),
			offset = CFrame.new(-0.43, 0.55, -2.7),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "SlingStrapRear",
			size = Vector3.new(0.03, 0.14, 1.79),
			offset = CFrame.new(-0.5, 0.375, -0.125) * A(rad(-11.3), 0, 0),
			color = SLING_WEBBING,
			material = M.Fabric,
		},
		{
			name = "SlingStrapFront",
			size = Vector3.new(0.03, 0.14, 1.74),
			offset = CFrame.new(-0.5, 0.375, -1.85) * A(rad(11.6), 0, 0),
			color = SLING_WEBBING,
			material = M.Fabric,
		},
	},
})
