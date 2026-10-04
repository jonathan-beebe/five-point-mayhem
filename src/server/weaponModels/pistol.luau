-- Pistol: Glock 17 Gen 5, 9mm polymer-frame striker pistol in matte black nitride.

local WeaponModel = require(script.Parent.Parent.systems.WeaponModel)

local rgb = Color3.fromRGB
local M = Enum.Material
local CYLINDER_Z = WeaponModel.CYLINDER_Z
local CYLINDER_Y = WeaponModel.CYLINDER_Y
local CYL = Enum.PartType.Cylinder
local A = CFrame.Angles

-- Wedge orientations (WedgePart default: right angle at local (ymin, zmax)).
local FLIP_Z = A(0, 0, math.pi) -- right angle at (ymax, zmax)
local FLIP_X = A(math.pi, 0, 0) -- right angle at (ymax, zmin)
local SIDE_L = A(0, math.pi / 2, 0) -- length along Z, solid side facing +X
local SIDE_R = A(0, -math.pi / 2, 0) -- length along Z, solid side facing -X

-- Grip frame: raked 20 degrees, top forward (-Z), bottom rearward (+Z).
local G = CFrame.new(0, 0.07, 0.10) * A(math.rad(-20), 0, 0)

local SLIDE_NITRIDE = rgb(50, 50, 55)
local SLIDE_DETAIL = rgb(22, 22, 24)
local FRAME_POLYMER = rgb(34, 34, 36)
local GRIP_STIPPLE = rgb(28, 28, 30)
local MAG_POLYMER = rgb(40, 40, 42)
local BARREL_STEEL = rgb(72, 72, 76)
local BORE_BLACK = rgb(8, 8, 8)
local PIN_STEEL = rgb(110, 110, 115)
local CONTROL_STEEL = rgb(42, 42, 45)
local SIGHT_STEEL = rgb(30, 30, 32)
local TRITIUM = rgb(205, 225, 195)
local TRIGGER_POLYMER = rgb(30, 30, 32)
local TRIGGER_SAFETY = rgb(20, 20, 22)

local SERRATION_SIZE = Vector3.new(0.30, 0.16, 0.02)
local SLIDE_BEVEL_SIZE = Vector3.new(1.54, 0.05, 0.05)
local DOT_SIZE = Vector3.new(0.012, 0.026, 0.026)
local PIN_SIZE = Vector3.new(0.32, 0.03, 0.03)
local GRIP_EDGE_SIZE = Vector3.new(0.74, 0.12, 0.12)
local GRIP_PANEL_SIZE = Vector3.new(0.02, 0.48, 0.26)
local GRIP_STRAP_SIZE = Vector3.new(0.16, 0.44, 0.02)

return WeaponModel.define({
	handle = {
		size = Vector3.new(0.28, 0.6, 0.36),
		color = FRAME_POLYMER,
		material = M.Plastic,
		transparency = 1,
	},
	muzzle = CFrame.new(0, 0.60, -1.21),
	pieces = {
		-- Slide
		{
			name = "SlideBody",
			size = Vector3.new(0.28, 0.22, 1.46),
			offset = CFrame.new(0, 0.57, -0.35),
			color = SLIDE_NITRIDE,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "SlideNose",
			size = Vector3.new(0.28, 0.14, 0.08),
			offset = CFrame.new(0, 0.61, -1.12),
			color = SLIDE_NITRIDE,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "SlideNoseBevel",
			class = "WedgePart",
			size = Vector3.new(0.28, 0.08, 0.08),
			offset = CFrame.new(0, 0.50, -1.12) * FLIP_Z,
			color = SLIDE_NITRIDE,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "SlideTopRear",
			size = Vector3.new(0.18, 0.05, 0.40),
			offset = CFrame.new(0, 0.705, 0.18),
			color = SLIDE_NITRIDE,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "SlideTopFront",
			size = Vector3.new(0.18, 0.05, 0.74),
			offset = CFrame.new(0, 0.705, -0.79),
			color = SLIDE_NITRIDE,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "SlideBevelL",
			class = "WedgePart",
			size = SLIDE_BEVEL_SIZE,
			offset = CFrame.new(-0.115, 0.705, -0.39) * SIDE_L,
			color = SLIDE_NITRIDE,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "SlideBevelR",
			class = "WedgePart",
			size = SLIDE_BEVEL_SIZE,
			offset = CFrame.new(0.115, 0.705, -0.39) * SIDE_R,
			color = SLIDE_NITRIDE,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "EjectionPortShadow",
			size = Vector3.new(0.18, 0.04, 0.40),
			offset = CFrame.new(0, 0.70, -0.22),
			color = SLIDE_DETAIL,
			material = M.Metal,
		},
		{
			name = "BarrelHood",
			size = Vector3.new(0.13, 0.03, 0.36),
			offset = CFrame.new(0, 0.725, -0.23),
			color = BARREL_STEEL,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "EjectionPortSide",
			size = Vector3.new(0.014, 0.10, 0.40),
			offset = CFrame.new(0.147, 0.63, -0.22),
			color = SLIDE_DETAIL,
			material = M.Metal,
		},
		{
			name = "Extractor",
			size = Vector3.new(0.016, 0.03, 0.10),
			offset = CFrame.new(0.148, 0.64, 0.03),
			color = CONTROL_STEEL,
			material = M.Metal,
		},
		{
			name = "SlideCoverPlate",
			size = Vector3.new(0.20, 0.16, 0.012),
			offset = CFrame.new(0, 0.57, 0.386),
			color = FRAME_POLYMER,
			material = M.Plastic,
		},

		-- Rear cocking serrations
		{
			name = "SerrRear1",
			size = SERRATION_SIZE,
			offset = CFrame.new(0, 0.58, 0.33),
			color = SLIDE_DETAIL,
			material = M.Metal,
		},
		{
			name = "SerrRear2",
			size = SERRATION_SIZE,
			offset = CFrame.new(0, 0.58, 0.29),
			color = SLIDE_DETAIL,
			material = M.Metal,
		},
		{
			name = "SerrRear3",
			size = SERRATION_SIZE,
			offset = CFrame.new(0, 0.58, 0.25),
			color = SLIDE_DETAIL,
			material = M.Metal,
		},
		{
			name = "SerrRear4",
			size = SERRATION_SIZE,
			offset = CFrame.new(0, 0.58, 0.21),
			color = SLIDE_DETAIL,
			material = M.Metal,
		},
		{
			name = "SerrRear5",
			size = SERRATION_SIZE,
			offset = CFrame.new(0, 0.58, 0.17),
			color = SLIDE_DETAIL,
			material = M.Metal,
		},
		{
			name = "SerrRear6",
			size = SERRATION_SIZE,
			offset = CFrame.new(0, 0.58, 0.13),
			color = SLIDE_DETAIL,
			material = M.Metal,
		},

		-- Front cocking serrations
		{
			name = "SerrFront1",
			size = SERRATION_SIZE,
			offset = CFrame.new(0, 0.58, -0.80),
			color = SLIDE_DETAIL,
			material = M.Metal,
		},
		{
			name = "SerrFront2",
			size = SERRATION_SIZE,
			offset = CFrame.new(0, 0.58, -0.84),
			color = SLIDE_DETAIL,
			material = M.Metal,
		},
		{
			name = "SerrFront3",
			size = SERRATION_SIZE,
			offset = CFrame.new(0, 0.58, -0.88),
			color = SLIDE_DETAIL,
			material = M.Metal,
		},
		{
			name = "SerrFront4",
			size = SERRATION_SIZE,
			offset = CFrame.new(0, 0.58, -0.92),
			color = SLIDE_DETAIL,
			material = M.Metal,
		},

		-- Night sights
		{
			name = "RearSightBase",
			size = Vector3.new(0.16, 0.06, 0.10),
			offset = CFrame.new(0, 0.76, 0.30),
			color = SIGHT_STEEL,
			material = M.Metal,
		},
		{
			name = "RearSightEarL",
			size = Vector3.new(0.055, 0.05, 0.10),
			offset = CFrame.new(-0.0525, 0.815, 0.30),
			color = SIGHT_STEEL,
			material = M.Metal,
		},
		{
			name = "RearSightEarR",
			size = Vector3.new(0.055, 0.05, 0.10),
			offset = CFrame.new(0.0525, 0.815, 0.30),
			color = SIGHT_STEEL,
			material = M.Metal,
		},
		{
			name = "RearDotL",
			shape = CYL,
			size = DOT_SIZE,
			offset = CFrame.new(-0.0525, 0.815, 0.356) * CYLINDER_Z,
			color = TRITIUM,
			material = M.SmoothPlastic,
		},
		{
			name = "RearDotR",
			shape = CYL,
			size = DOT_SIZE,
			offset = CFrame.new(0.0525, 0.815, 0.356) * CYLINDER_Z,
			color = TRITIUM,
			material = M.SmoothPlastic,
		},
		{
			name = "FrontSightPost",
			size = Vector3.new(0.05, 0.08, 0.06),
			offset = CFrame.new(0, 0.77, -1.10),
			color = SIGHT_STEEL,
			material = M.Metal,
		},
		{
			name = "FrontDot",
			shape = CYL,
			size = DOT_SIZE,
			offset = CFrame.new(0, 0.785, -1.064) * CYLINDER_Z,
			color = TRITIUM,
			material = M.SmoothPlastic,
		},

		-- Barrel
		{
			name = "BarrelCrown",
			shape = CYL,
			size = Vector3.new(0.05, 0.13, 0.13),
			offset = CFrame.new(0, 0.60, -1.165) * CYLINDER_Z,
			color = BARREL_STEEL,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "Bore",
			shape = CYL,
			size = Vector3.new(0.012, 0.075, 0.075),
			offset = CFrame.new(0, 0.60, -1.195) * CYLINDER_Z,
			color = BORE_BLACK,
			material = M.SmoothPlastic,
		},

		-- Frame
		{
			name = "FrameDustCover",
			size = Vector3.new(0.27, 0.12, 1.37),
			offset = CFrame.new(0, 0.40, -0.395),
			color = FRAME_POLYMER,
			material = M.Plastic,
		},
		{
			name = "AccessoryRail",
			size = Vector3.new(0.20, 0.04, 0.40),
			offset = CFrame.new(0, 0.32, -0.84),
			color = FRAME_POLYMER,
			material = M.Plastic,
		},
		{
			name = "RailSlot",
			size = Vector3.new(0.22, 0.03, 0.04),
			offset = CFrame.new(0, 0.318, -0.80),
			color = SLIDE_DETAIL,
			material = M.Plastic,
		},
		{
			name = "FrameTang",
			size = Vector3.new(0.27, 0.10, 0.15),
			offset = CFrame.new(0, 0.40, 0.365),
			color = FRAME_POLYMER,
			material = M.Plastic,
		},
		{
			name = "BeavertailFill",
			class = "WedgePart",
			size = Vector3.new(0.27, 0.08, 0.22),
			offset = CFrame.new(0, 0.31, 0.31) * FLIP_X,
			color = FRAME_POLYMER,
			material = M.Plastic,
		},
		{
			name = "TriggerGuardBottom",
			size = Vector3.new(0.14, 0.05, 0.50),
			offset = CFrame.new(0, 0.11, -0.27),
			color = FRAME_POLYMER,
			material = M.Plastic,
		},
		{
			name = "TriggerGuardFront",
			size = Vector3.new(0.14, 0.22, 0.05),
			offset = CFrame.new(0, 0.23, -0.495),
			color = FRAME_POLYMER,
			material = M.Plastic,
		},
		{
			name = "TriggerUpper",
			size = Vector3.new(0.06, 0.12, 0.05),
			offset = CFrame.new(0, 0.29, -0.30),
			color = TRIGGER_POLYMER,
			material = M.Plastic,
		},
		{
			name = "TriggerLower",
			size = Vector3.new(0.06, 0.10, 0.05),
			offset = CFrame.new(0, 0.19, -0.32) * A(math.rad(20), 0, 0),
			color = TRIGGER_POLYMER,
			material = M.Plastic,
		},
		{
			name = "TriggerSafetyBlade",
			size = Vector3.new(0.022, 0.12, 0.02),
			offset = CFrame.new(0, 0.25, -0.335) * A(math.rad(10), 0, 0),
			color = TRIGGER_SAFETY,
			material = M.Plastic,
		},
		{
			name = "TriggerHousingPin",
			shape = CYL,
			size = PIN_SIZE,
			offset = CFrame.new(0, 0.41, 0.12),
			color = PIN_STEEL,
			material = M.Metal,
		},
		{
			name = "TriggerPin",
			shape = CYL,
			size = PIN_SIZE,
			offset = CFrame.new(0, 0.38, -0.12),
			color = PIN_STEEL,
			material = M.Metal,
		},
		{
			name = "LockingBlockPin",
			shape = CYL,
			size = Vector3.new(0.29, 0.03, 0.03),
			offset = CFrame.new(0, 0.38, -0.46),
			color = PIN_STEEL,
			material = M.Metal,
		},
		{
			name = "TakedownLever",
			size = Vector3.new(0.29, 0.03, 0.06),
			offset = CFrame.new(0, 0.38, -0.36),
			color = CONTROL_STEEL,
			material = M.Metal,
		},
		{
			name = "SlideStopBar",
			size = Vector3.new(0.025, 0.035, 0.22),
			offset = CFrame.new(-0.1475, 0.43, -0.10),
			color = CONTROL_STEEL,
			material = M.Metal,
		},
		{
			name = "SlideStopTab",
			size = Vector3.new(0.035, 0.05, 0.06),
			offset = CFrame.new(-0.1525, 0.43, -0.02),
			color = CONTROL_STEEL,
			material = M.Metal,
		},
		{
			name = "MagRelease",
			size = Vector3.new(0.36, 0.06, 0.07),
			offset = CFrame.new(0, 0.20, -0.10),
			color = FRAME_POLYMER,
			material = M.Plastic,
		},

		-- Grip (rounded-rectangle section, 0.30 x 0.40, 0.06 corner radii)
		{
			name = "GripCoreA",
			size = Vector3.new(0.30, 0.74, 0.28),
			offset = G,
			color = FRAME_POLYMER,
			material = M.Plastic,
		},
		{
			name = "GripCoreB",
			size = Vector3.new(0.18, 0.74, 0.40),
			offset = G,
			color = FRAME_POLYMER,
			material = M.Plastic,
		},
		{
			name = "GripEdgeFL",
			shape = CYL,
			size = GRIP_EDGE_SIZE,
			offset = G * CFrame.new(-0.09, 0, -0.14) * CYLINDER_Y,
			color = FRAME_POLYMER,
			material = M.Plastic,
		},
		{
			name = "GripEdgeFR",
			shape = CYL,
			size = GRIP_EDGE_SIZE,
			offset = G * CFrame.new(0.09, 0, -0.14) * CYLINDER_Y,
			color = FRAME_POLYMER,
			material = M.Plastic,
		},
		{
			name = "GripEdgeBL",
			shape = CYL,
			size = GRIP_EDGE_SIZE,
			offset = G * CFrame.new(-0.09, 0, 0.14) * CYLINDER_Y,
			color = FRAME_POLYMER,
			material = M.Plastic,
		},
		{
			name = "GripEdgeBR",
			shape = CYL,
			size = GRIP_EDGE_SIZE,
			offset = G * CFrame.new(0.09, 0, 0.14) * CYLINDER_Y,
			color = FRAME_POLYMER,
			material = M.Plastic,
		},
		{
			name = "GripPanelL",
			size = GRIP_PANEL_SIZE,
			offset = G * CFrame.new(-0.155, -0.04, 0),
			color = GRIP_STIPPLE,
			material = M.Fabric,
		},
		{
			name = "GripPanelR",
			size = GRIP_PANEL_SIZE,
			offset = G * CFrame.new(0.155, -0.04, 0),
			color = GRIP_STIPPLE,
			material = M.Fabric,
		},
		{
			name = "FrontStrap",
			size = GRIP_STRAP_SIZE,
			offset = G * CFrame.new(0, -0.05, -0.205),
			color = GRIP_STIPPLE,
			material = M.Fabric,
		},
		{
			name = "BackStrap",
			size = GRIP_STRAP_SIZE,
			offset = G * CFrame.new(0, -0.05, 0.205),
			color = GRIP_STIPPLE,
			material = M.Fabric,
		},
		{
			name = "MagFloorplate",
			size = Vector3.new(0.32, 0.06, 0.44),
			offset = G * CFrame.new(0, -0.395, 0),
			color = MAG_POLYMER,
			material = M.Plastic,
		},
		{
			name = "MagFloorplateLip",
			size = Vector3.new(0.20, 0.04, 0.06),
			offset = G * CFrame.new(0, -0.40, -0.245),
			color = MAG_POLYMER,
			material = M.Plastic,
		},
	},
})
