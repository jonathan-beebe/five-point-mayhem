-- Grenade Launcher: US M79 "Thumper" 40mm single-shot break-action launcher, olive drab barrel, walnut furniture.

local WeaponModel = require(script.Parent.Parent.systems.WeaponModel)

local rgb = Color3.fromRGB
local M = Enum.Material
local CYLINDER_Z = WeaponModel.CYLINDER_Z
local CYLINDER_Y = WeaponModel.CYLINDER_Y
local CYL = Enum.PartType.Cylinder
local A = CFrame.Angles
local r = math.rad

-- Wedge orientations (WedgePart default: right angle at local (ymin, zmax)).
local SIDE_L = A(0, r(90), 0) -- slope faces up and -X
local SIDE_R = A(0, r(-90), 0) -- slope faces up and +X
local UNDER_L = A(0, r(90), r(180)) -- slope faces down and -X
local UNDER_R = A(0, r(-90), r(180)) -- slope faces down and +X
local FACE_FRONT = A(0, r(180), 0) -- vertical face at -Z, slope falls toward +Z
local FLIP_Z = A(0, 0, r(180)) -- right angle at (ymax, zmax): flat top, slope underneath

local OLIVE_DRAB = rgb(60, 70, 50)
local PARKERIZED = rgb(58, 60, 58)
local BLUED_STEEL = rgb(32, 34, 38)
local SCREW_STEEL = rgb(95, 95, 92)
local WALNUT = rgb(105, 66, 38)
local WALNUT_DARK = rgb(62, 38, 22)
local RUBBER = rgb(28, 26, 24)
local BORE_BLACK = rgb(10, 10, 10)

local SIDE_SCREW = Vector3.new(0.02, 0.05, 0.05)
local HINGE_PIN = Vector3.new(0.02, 0.10, 0.10)
local LEAF_RAIL = Vector3.new(0.03, 0.44, 0.04)
local FRONT_EAR = Vector3.new(0.03, 0.10, 0.10)
local RECEIVER_CHAMFER = Vector3.new(0.62, 0.08, 0.08)
local FOREND_CHAMFER = Vector3.new(0.85, 0.06, 0.06)
local FOREND_GROOVE = Vector3.new(0.01, 0.025, 0.65)
local BUTT_SCREW = Vector3.new(0.015, 0.05, 0.05)

return WeaponModel.define({
	handle = {
		size = Vector3.new(0.28, 0.42, 0.5),
		color = WALNUT,
		material = M.Wood,
		transparency = 1,
	},
	muzzle = CFrame.new(0, 0.5, -2.4),
	pieces = {
		-- Barrel
		{
			name = "Barrel",
			shape = CYL,
			size = Vector3.new(1.63, 0.52, 0.52),
			offset = CFrame.new(0, 0.5, -1.525) * CYLINDER_Z,
			color = OLIVE_DRAB,
			material = M.Metal,
		},
		{
			name = "BreechRing",
			shape = CYL,
			size = Vector3.new(0.15, 0.58, 0.58),
			offset = CFrame.new(0, 0.5, -0.79) * CYLINDER_Z,
			color = PARKERIZED,
			material = M.Metal,
		},
		{
			name = "MuzzleCrown",
			shape = CYL,
			size = Vector3.new(0.08, 0.56, 0.56),
			offset = CFrame.new(0, 0.5, -2.31) * CYLINDER_Z,
			color = PARKERIZED,
			material = M.Metal,
		},
		{
			name = "Bore",
			shape = CYL,
			size = Vector3.new(0.02, 0.42, 0.42),
			offset = CFrame.new(0, 0.5, -2.35) * CYLINDER_Z,
			color = BORE_BLACK,
			material = M.SmoothPlastic,
		},
		{
			name = "BarrelBand",
			shape = CYL,
			size = Vector3.new(0.06, 0.56, 0.56),
			offset = CFrame.new(0, 0.5, -1.85) * CYLINDER_Z,
			color = BLUED_STEEL,
			material = M.Metal,
		},
		{
			name = "FrontSlingLoop",
			size = Vector3.new(0.05, 0.10, 0.12),
			offset = CFrame.new(0, 0.18, -1.85),
			color = BLUED_STEEL,
			material = M.Metal,
		},

		-- Front sight
		{
			name = "FrontSightBase",
			size = Vector3.new(0.18, 0.06, 0.14),
			offset = CFrame.new(0, 0.78, -2.2),
			color = BLUED_STEEL,
			material = M.Metal,
		},
		{
			name = "FrontSightBlade",
			size = Vector3.new(0.03, 0.12, 0.06),
			offset = CFrame.new(0, 0.87, -2.2),
			color = BLUED_STEEL,
			material = M.Metal,
		},
		{
			name = "FrontSightEarL",
			size = FRONT_EAR,
			offset = CFrame.new(-0.075, 0.86, -2.2),
			color = BLUED_STEEL,
			material = M.Metal,
		},
		{
			name = "FrontSightEarR",
			size = FRONT_EAR,
			offset = CFrame.new(0.075, 0.86, -2.2),
			color = BLUED_STEEL,
			material = M.Metal,
		},

		-- Leaf sight, raised
		{
			name = "LeafBase",
			size = Vector3.new(0.22, 0.08, 0.30),
			offset = CFrame.new(0, 0.78, -1.0),
			color = BLUED_STEEL,
			material = M.Metal,
		},
		{
			name = "LeafHinge",
			shape = CYL,
			size = Vector3.new(0.24, 0.07, 0.07),
			offset = CFrame.new(0, 0.82, -1.0),
			color = BLUED_STEEL,
			material = M.Metal,
		},
		{
			name = "LeafRailL",
			size = LEAF_RAIL,
			offset = CFrame.new(-0.08, 1.06, -1.0),
			color = BLUED_STEEL,
			material = M.Metal,
		},
		{
			name = "LeafRailR",
			size = LEAF_RAIL,
			offset = CFrame.new(0.08, 1.06, -1.0),
			color = BLUED_STEEL,
			material = M.Metal,
		},
		{
			name = "LeafTopBar",
			size = Vector3.new(0.19, 0.04, 0.04),
			offset = CFrame.new(0, 1.26, -1.0),
			color = BLUED_STEEL,
			material = M.Metal,
		},
		{
			name = "LeafSlider",
			size = Vector3.new(0.13, 0.07, 0.06),
			offset = CFrame.new(0, 1.09, -1.0),
			color = SCREW_STEEL,
			material = M.Metal,
		},
		{
			name = "LeafAperture",
			shape = CYL,
			size = Vector3.new(0.07, 0.035, 0.035),
			offset = CFrame.new(0, 1.09, -1.0) * CYLINDER_Z,
			color = BORE_BLACK,
			material = M.SmoothPlastic,
		},

		-- Receiver
		{
			name = "ReceiverBody",
			size = Vector3.new(0.46, 0.50, 0.62),
			offset = CFrame.new(0, 0.45, -0.41),
			color = PARKERIZED,
			material = M.Metal,
		},
		{
			name = "ReceiverTopCap",
			size = Vector3.new(0.30, 0.08, 0.62),
			offset = CFrame.new(0, 0.74, -0.41),
			color = PARKERIZED,
			material = M.Metal,
		},
		{
			name = "ReceiverChamferL",
			class = "WedgePart",
			size = RECEIVER_CHAMFER,
			offset = CFrame.new(-0.19, 0.74, -0.41) * SIDE_L,
			color = PARKERIZED,
			material = M.Metal,
		},
		{
			name = "ReceiverChamferR",
			class = "WedgePart",
			size = RECEIVER_CHAMFER,
			offset = CFrame.new(0.19, 0.74, -0.41) * SIDE_R,
			color = PARKERIZED,
			material = M.Metal,
		},
		{
			name = "SidePlateL",
			size = Vector3.new(0.01, 0.30, 0.44),
			offset = CFrame.new(-0.235, 0.42, -0.40),
			color = BLUED_STEEL,
			material = M.Metal,
		},
		{
			name = "SidePlateR",
			size = Vector3.new(0.01, 0.30, 0.44),
			offset = CFrame.new(0.235, 0.42, -0.40),
			color = BLUED_STEEL,
			material = M.Metal,
		},
		{
			name = "ScrewL1",
			shape = CYL,
			size = SIDE_SCREW,
			offset = CFrame.new(-0.245, 0.42, -0.24),
			color = SCREW_STEEL,
			material = M.Metal,
		},
		{
			name = "ScrewL2",
			shape = CYL,
			size = SIDE_SCREW,
			offset = CFrame.new(-0.245, 0.42, -0.56),
			color = SCREW_STEEL,
			material = M.Metal,
		},
		{
			name = "ScrewR1",
			shape = CYL,
			size = SIDE_SCREW,
			offset = CFrame.new(0.245, 0.42, -0.24),
			color = SCREW_STEEL,
			material = M.Metal,
		},
		{
			name = "ScrewR2",
			shape = CYL,
			size = SIDE_SCREW,
			offset = CFrame.new(0.245, 0.42, -0.56),
			color = SCREW_STEEL,
			material = M.Metal,
		},
		{
			name = "HingeKnuckle",
			shape = CYL,
			size = Vector3.new(0.48, 0.16, 0.16),
			offset = CFrame.new(0, 0.26, -0.75),
			color = PARKERIZED,
			material = M.Metal,
		},
		{
			name = "HingePinL",
			shape = CYL,
			size = HINGE_PIN,
			offset = CFrame.new(-0.25, 0.26, -0.75),
			color = SCREW_STEEL,
			material = M.Metal,
		},
		{
			name = "HingePinR",
			shape = CYL,
			size = HINGE_PIN,
			offset = CFrame.new(0.25, 0.26, -0.75),
			color = SCREW_STEEL,
			material = M.Metal,
		},
		{
			name = "TopLever",
			size = Vector3.new(0.08, 0.05, 0.26),
			offset = CFrame.new(0.04, 0.805, -0.34) * A(0, r(-10), 0),
			color = BLUED_STEEL,
			material = M.Metal,
		},
		{
			name = "TopLeverPivot",
			shape = CYL,
			size = Vector3.new(0.02, 0.07, 0.07),
			offset = CFrame.new(0.06, 0.835, -0.44) * CYLINDER_Y,
			color = SCREW_STEEL,
			material = M.Metal,
		},
		{
			name = "SafetySlide",
			size = Vector3.new(0.08, 0.04, 0.08),
			offset = CFrame.new(0, 0.80, -0.15),
			color = BLUED_STEEL,
			material = M.Metal,
		},

		-- Trigger group
		{
			name = "Trigger",
			size = Vector3.new(0.05, 0.20, 0.06),
			offset = CFrame.new(0, 0.12, -0.25) * A(r(12), 0, 0),
			color = BLUED_STEEL,
			material = M.Metal,
		},
		{
			name = "GuardBottom",
			size = Vector3.new(0.07, 0.04, 0.46),
			offset = CFrame.new(0, -0.04, -0.31),
			color = BLUED_STEEL,
			material = M.Metal,
		},
		{
			name = "GuardFront",
			size = Vector3.new(0.07, 0.26, 0.05),
			offset = CFrame.new(0, 0.09, -0.515),
			color = BLUED_STEEL,
			material = M.Metal,
		},

		-- Forend: wider than the barrel so it cradles the lower half
		{
			name = "ForendMain",
			size = Vector3.new(0.56, 0.28, 0.85),
			offset = CFrame.new(0, 0.38, -1.225),
			color = WALNUT,
			material = M.Wood,
		},
		{
			name = "ForendBottom",
			size = Vector3.new(0.44, 0.06, 0.85),
			offset = CFrame.new(0, 0.21, -1.225),
			color = WALNUT,
			material = M.Wood,
		},
		{
			name = "ForendChamferL",
			class = "WedgePart",
			size = FOREND_CHAMFER,
			offset = CFrame.new(-0.25, 0.21, -1.225) * UNDER_L,
			color = WALNUT,
			material = M.Wood,
		},
		{
			name = "ForendChamferR",
			class = "WedgePart",
			size = FOREND_CHAMFER,
			offset = CFrame.new(0.25, 0.21, -1.225) * UNDER_R,
			color = WALNUT,
			material = M.Wood,
		},
		{
			name = "ForendGrooveL",
			size = FOREND_GROOVE,
			offset = CFrame.new(-0.285, 0.40, -1.225),
			color = WALNUT_DARK,
			material = M.Wood,
		},
		{
			name = "ForendGrooveR",
			size = FOREND_GROOVE,
			offset = CFrame.new(0.285, 0.40, -1.225),
			color = WALNUT_DARK,
			material = M.Wood,
		},
		{
			name = "ForendScrew",
			shape = CYL,
			size = Vector3.new(0.02, 0.06, 0.06),
			offset = CFrame.new(0, 0.175, -1.45) * CYLINDER_Y,
			color = SCREW_STEEL,
			material = M.Metal,
		},

		-- Stock
		{
			name = "Wrist",
			size = Vector3.new(0.30, 0.47, 0.61),
			offset = CFrame.new(0, 0.125, 0.195),
			color = WALNUT,
			material = M.Wood,
		},
		{
			name = "CombWedge",
			class = "WedgePart",
			size = Vector3.new(0.30, 0.40, 0.575),
			offset = CFrame.new(0, 0.56, 0.1825) * FACE_FRONT,
			color = WALNUT,
			material = M.Wood,
		},
		{
			name = "StockNoseWedge",
			class = "WedgePart",
			size = Vector3.new(0.30, 0.15, 0.17),
			offset = CFrame.new(0, 0.435, 0.385),
			color = WALNUT,
			material = M.Wood,
		},
		{
			name = "StockBody",
			size = Vector3.new(0.34, 0.62, 0.66),
			offset = CFrame.new(0, 0.20, 0.80),
			color = WALNUT,
			material = M.Wood,
		},
		{
			name = "StockToe",
			class = "WedgePart",
			size = Vector3.new(0.34, 0.14, 0.66),
			offset = CFrame.new(0, -0.18, 0.80) * FLIP_Z,
			color = WALNUT,
			material = M.Wood,
		},
		{
			name = "Buttpad",
			size = Vector3.new(0.36, 0.78, 0.055),
			offset = CFrame.new(0, 0.13, 1.1525),
			color = RUBBER,
			material = M.Rubber,
		},
		{
			name = "ButtScrewTop",
			shape = CYL,
			size = BUTT_SCREW,
			offset = CFrame.new(0, 0.38, 1.182) * CYLINDER_Z,
			color = SCREW_STEEL,
			material = M.Metal,
		},
		{
			name = "ButtScrewBottom",
			shape = CYL,
			size = BUTT_SCREW,
			offset = CFrame.new(0, -0.12, 1.182) * CYLINDER_Z,
			color = SCREW_STEEL,
			material = M.Metal,
		},
		{
			name = "RearSwivelBase",
			size = Vector3.new(0.06, 0.04, 0.12),
			offset = CFrame.new(0, -0.23, 0.98),
			color = BLUED_STEEL,
			material = M.Metal,
		},
		{
			name = "RearSlingLoop",
			size = Vector3.new(0.025, 0.09, 0.16),
			offset = CFrame.new(0, -0.29, 0.98),
			color = BLUED_STEEL,
			material = M.Metal,
		},
	},
})
