-- Bounce Ray: film-prop repulsor pistol on a cordless power-tool housing (Hilti/DeWalt polymer,
-- rubber grip, battery base) with a copper-wound magnetic coil emitter.

local WeaponModel = require(script.Parent.Parent.systems.WeaponModel)

local rgb = Color3.fromRGB
local M = Enum.Material
local CYLINDER_Z = WeaponModel.CYLINDER_Z
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball

-- Wedge orientations (WedgePart default slope faces +Y/-Z, tall face at +Z).
local FACE_REAR = CFrame.Angles(0, math.pi, 0) -- slope faces up and +Z
local FLIP_Z = CFrame.Angles(0, 0, math.pi) -- bottom chamfer, slope faces down and -Z

-- Grip frame: raked 15 degrees, top toward -Z, base toward +Z.
local GRIP = CFrame.new(0, -0.15, 0.06) * CFrame.Angles(math.rad(-15), 0, 0)
local TRIGGER = CFrame.new(0, 0.04, -0.36) * CFrame.Angles(math.rad(12), 0, 0)

local BORE_Y = 0.48

local SAFETY_ORANGE = rgb(224, 112, 20)
local ORANGE_DARK = rgb(168, 78, 14)
local GRAPHITE = rgb(44, 46, 50)
local RUBBER_BLACK = rgb(26, 26, 28)
local GRIP_STIPPLE = rgb(38, 38, 40)
local GUNMETAL = rgb(72, 75, 80)
local STEEL = rgb(152, 156, 162)
local COPPER = rgb(184, 115, 51)
local VENT_BLACK = rgb(18, 18, 20)
local WARNING_YELLOW = rgb(236, 196, 38)
local GLOW = rgb(255, 160, 40)
local LENS_GLASS = rgb(255, 196, 120)

local GRIP_PANEL = Vector3.new(0.03, 0.5, 0.36)
local VENT_SLOT = Vector3.new(0.02, 0.16, 0.05)
local SCREW_HEAD = Vector3.new(0.03, 0.06, 0.06)
local RAIL_RIB = Vector3.new(0.22, 0.03, 0.05)
local REAR_SIGHT = Vector3.new(0.06, 0.17, 0.08)
local COIL_RING = Vector3.new(0.06, 0.36, 0.36)
local GUARD_BAR = Vector3.new(0.04, 0.08, 0.6)
local PRONG = Vector3.new(0.04, 0.04, 0.14)

local function housing(
	name: string,
	size: Vector3,
	offset: CFrame,
	class: string?
): WeaponModel.PieceSpec
	return {
		name = name,
		class = class :: any,
		size = size,
		offset = offset,
		color = SAFETY_ORANGE,
		material = M.SmoothPlastic,
		reflectance = 0.05,
	}
end

local function steel(
	name: string,
	size: Vector3,
	offset: CFrame,
	shape: Enum.PartType?
): WeaponModel.PieceSpec
	return {
		name = name,
		shape = shape,
		size = size,
		offset = offset,
		color = STEEL,
		material = M.Metal,
		reflectance = 0.1,
	}
end

local function coil(name: string, z: number): WeaponModel.PieceSpec
	return {
		name = name,
		shape = CYL,
		size = COIL_RING,
		offset = CFrame.new(0, BORE_Y, z) * CYLINDER_Z,
		color = COPPER,
		material = M.Metal,
		reflectance = 0.15,
	}
end

return WeaponModel.define({
	handle = {
		size = Vector3.new(0.3, 0.7, 0.45),
		color = RUBBER_BLACK,
		material = M.Rubber,
		transparency = 1,
	},
	muzzle = CFrame.new(0, BORE_Y, -2.56),
	pieces = {
		-- Grip
		{
			name = "GripCore",
			size = Vector3.new(0.34, 0.75, 0.5),
			offset = GRIP,
			color = RUBBER_BLACK,
			material = M.Rubber,
		},
		{
			name = "GripPanelL",
			size = GRIP_PANEL,
			offset = GRIP * CFrame.new(-0.18, -0.03, 0.02),
			color = GRIP_STIPPLE,
			material = M.Slate,
		},
		{
			name = "GripPanelR",
			size = GRIP_PANEL,
			offset = GRIP * CFrame.new(0.18, -0.03, 0.02),
			color = GRIP_STIPPLE,
			material = M.Slate,
		},
		housing("GripFrontStrap", Vector3.new(0.3, 0.6, 0.05), GRIP * CFrame.new(0, -0.03, -0.27)),
		{
			name = "BatteryBase",
			size = Vector3.new(0.38, 0.08, 0.56),
			offset = GRIP * CFrame.new(0, -0.41, 0),
			color = GRAPHITE,
			material = M.Plastic,
		},
		steel("BatteryLatch", Vector3.new(0.2, 0.04, 0.06), GRIP * CFrame.new(0, -0.41, 0.29)),

		-- Receiver / upper housing
		housing("ReceiverBody", Vector3.new(0.42, 0.42, 1.75), CFrame.new(0, BORE_Y, -0.55)),
		housing("RearCap", Vector3.new(0.42, 0.28, 0.12), CFrame.new(0, 0.41, 0.385)),
		housing(
			"RearChamfer",
			Vector3.new(0.42, 0.14, 0.12),
			CFrame.new(0, 0.62, 0.385) * FACE_REAR,
			"WedgePart"
		),
		housing("NoseBlock", Vector3.new(0.42, 0.30, 0.16), CFrame.new(0, 0.42, -1.505)),
		housing(
			"NoseChamfer",
			Vector3.new(0.42, 0.12, 0.16),
			CFrame.new(0, 0.63, -1.505),
			"WedgePart"
		),
		{
			name = "SidePanelL",
			size = Vector3.new(0.02, 0.24, 0.9),
			offset = CFrame.new(-0.215, 0.5, -0.55),
			color = ORANGE_DARK,
			material = M.Plastic,
		},
		{
			name = "SidePanelR",
			size = Vector3.new(0.02, 0.24, 0.9),
			offset = CFrame.new(0.215, 0.5, -0.55),
			color = ORANGE_DARK,
			material = M.Plastic,
		},
		{
			name = "VentL1",
			size = VENT_SLOT,
			offset = CFrame.new(-0.23, 0.5, -0.7),
			color = VENT_BLACK,
			material = M.SmoothPlastic,
		},
		{
			name = "VentL2",
			size = VENT_SLOT,
			offset = CFrame.new(-0.23, 0.5, -0.85),
			color = VENT_BLACK,
			material = M.SmoothPlastic,
		},
		{
			name = "VentR1",
			size = VENT_SLOT,
			offset = CFrame.new(0.23, 0.5, -0.7),
			color = VENT_BLACK,
			material = M.SmoothPlastic,
		},
		{
			name = "VentR2",
			size = VENT_SLOT,
			offset = CFrame.new(0.23, 0.5, -0.85),
			color = VENT_BLACK,
			material = M.SmoothPlastic,
		},
		steel("ScrewLRear", SCREW_HEAD, CFrame.new(-0.22, 0.62, 0.15), CYL),
		steel("ScrewRRear", SCREW_HEAD, CFrame.new(0.22, 0.62, 0.15), CYL),
		steel("ScrewLFront", SCREW_HEAD, CFrame.new(-0.22, 0.62, -1.3), CYL),
		steel("ScrewRFront", SCREW_HEAD, CFrame.new(0.22, 0.62, -1.3), CYL),
		{
			name = "RearKnob",
			shape = CYL,
			size = Vector3.new(0.06, 0.16, 0.16),
			offset = CFrame.new(0, 0.46, 0.47) * CYLINDER_Z,
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "WarningLabel",
			size = Vector3.new(0.02, 0.1, 0.25),
			offset = CFrame.new(0.216, 0.36, 0.1),
			color = WARNING_YELLOW,
			material = M.SmoothPlastic,
		},
		{
			name = "ChargeGaugeLight",
			size = Vector3.new(0.015, 0.05, 0.26),
			offset = CFrame.new(-0.212, 0.33, -0.2),
			color = GLOW,
			material = M.Neon,
		},
		{
			name = "ChargeGaugeWindow",
			size = Vector3.new(0.02, 0.07, 0.3),
			offset = CFrame.new(-0.222, 0.33, -0.2),
			color = LENS_GLASS,
			material = M.Glass,
			transparency = 0.35,
		},
		steel("SelectorDial", Vector3.new(0.04, 0.1, 0.1), CFrame.new(-0.225, 0.6, 0.02), CYL),
		steel("SelectorLever", Vector3.new(0.02, 0.04, 0.12), CFrame.new(-0.25, 0.6, 0.06)),

		-- Top rail and sights
		{
			name = "TopRail",
			size = Vector3.new(0.2, 0.05, 1.1),
			offset = CFrame.new(0, 0.71, -0.6),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "RailRib1",
			size = RAIL_RIB,
			offset = CFrame.new(0, 0.745, -0.2),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "RailRib2",
			size = RAIL_RIB,
			offset = CFrame.new(0, 0.745, -0.45),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "RailRib3",
			size = RAIL_RIB,
			offset = CFrame.new(0, 0.745, -0.7),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "RailRib4",
			size = RAIL_RIB,
			offset = CFrame.new(0, 0.745, -0.95),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "RearSightL",
			size = REAR_SIGHT,
			offset = CFrame.new(-0.06, 0.77, 0.05),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "RearSightR",
			size = REAR_SIGHT,
			offset = CFrame.new(0.06, 0.77, 0.05),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "FrontSightPost",
			size = Vector3.new(0.05, 0.14, 0.06),
			offset = CFrame.new(0, 0.80, -1.12),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "FrontSightDot",
			shape = BALL,
			size = Vector3.new(0.05, 0.05, 0.05),
			offset = CFrame.new(0, 0.84, -1.09),
			color = GLOW,
			material = M.Neon,
		},

		-- Lower frame
		{
			name = "FrameBody",
			size = Vector3.new(0.38, 0.15, 1.575),
			offset = CFrame.new(0, 0.205, -0.4875),
			color = GRAPHITE,
			material = M.Plastic,
		},
		{
			name = "FrameChamfer",
			class = "WedgePart",
			size = Vector3.new(0.38, 0.15, 0.15),
			offset = CFrame.new(0, 0.205, -1.35) * FLIP_Z,
			color = GRAPHITE,
			material = M.Plastic,
		},
		{
			name = "UnderRail",
			size = Vector3.new(0.16, 0.04, 0.5),
			offset = CFrame.new(0, 0.115, -1.0),
			color = GUNMETAL,
			material = M.Metal,
		},

		-- Trigger group
		{
			name = "GuardFront",
			size = Vector3.new(0.1, 0.27, 0.06),
			offset = CFrame.new(0, 0, -0.65),
			color = GRAPHITE,
			material = M.Plastic,
		},
		{
			name = "GuardBottom",
			size = Vector3.new(0.1, 0.05, 0.46),
			offset = CFrame.new(0, -0.12, -0.45),
			color = GRAPHITE,
			material = M.Plastic,
		},
		{
			name = "Trigger",
			size = Vector3.new(0.06, 0.2, 0.05),
			offset = TRIGGER,
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "TriggerSafety",
			size = Vector3.new(0.02, 0.08, 0.02),
			offset = TRIGGER * CFrame.new(0, -0.03, -0.03),
			color = ORANGE_DARK,
			material = M.Plastic,
		},

		-- Emitter assembly
		{
			name = "CoreTube",
			shape = CYL,
			size = Vector3.new(0.85, 0.26, 0.26),
			offset = CFrame.new(0, BORE_Y, -2.0) * CYLINDER_Z,
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "CoilGlow",
			shape = CYL,
			size = Vector3.new(0.47, 0.30, 0.30),
			offset = CFrame.new(0, BORE_Y, -1.885) * CYLINDER_Z,
			color = GLOW,
			material = M.Neon,
		},
		coil("Coil1", -1.70),
		coil("Coil2", -1.82),
		coil("Coil3", -1.94),
		coil("Coil4", -2.06),
		{
			name = "GuardBarL",
			size = GUARD_BAR,
			offset = CFrame.new(-0.19, BORE_Y, -1.88),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "GuardBarR",
			size = GUARD_BAR,
			offset = CFrame.new(0.19, BORE_Y, -1.88),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "FrontCollar",
			shape = CYL,
			size = Vector3.new(0.1, 0.42, 0.42),
			offset = CFrame.new(0, BORE_Y, -2.16) * CYLINDER_Z,
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "MuzzleBell",
			shape = CYL,
			size = Vector3.new(0.2, 0.36, 0.36),
			offset = CFrame.new(0, BORE_Y, -2.31) * CYLINDER_Z,
			color = GUNMETAL,
			material = M.Metal,
		},
		steel(
			"Crown",
			Vector3.new(0.04, 0.38, 0.38),
			CFrame.new(0, BORE_Y, -2.43) * CYLINDER_Z,
			CYL
		),
		{
			name = "Lens",
			shape = CYL,
			size = Vector3.new(0.02, 0.26, 0.26),
			offset = CFrame.new(0, BORE_Y, -2.445) * CYLINDER_Z,
			color = GLOW,
			material = M.Neon,
		},
		{
			name = "LensCover",
			shape = CYL,
			size = Vector3.new(0.03, 0.30, 0.30),
			offset = CFrame.new(0, BORE_Y, -2.465) * CYLINDER_Z,
			color = LENS_GLASS,
			material = M.Glass,
			transparency = 0.35,
		},
		steel("ProngTop", PRONG, CFrame.new(0, 0.66, -2.49)),
		steel(
			"ProngLeft",
			PRONG,
			CFrame.new(-0.156, 0.39, -2.49) * CFrame.Angles(0, 0, math.rad(120))
		),
		steel(
			"ProngRight",
			PRONG,
			CFrame.new(0.156, 0.39, -2.49) * CFrame.Angles(0, 0, math.rad(-120))
		),
		{
			name = "PowerCable",
			shape = CYL,
			size = Vector3.new(0.55, 0.06, 0.06),
			offset = CFrame.new(0.15, 0.32, -1.85) * CYLINDER_Z,
			color = RUBBER_BLACK,
			material = M.Rubber,
		},
	},
})
