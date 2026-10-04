-- Plasma Blade: machined anodized-aluminum energy-sword replica hilt with a layered plasma blade.

local WeaponModel = require(script.Parent.Parent.systems.WeaponModel)

local rgb = Color3.fromRGB
local M = Enum.Material
local CYLINDER_Z = WeaponModel.CYLINDER_Z
local CYLINDER = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball

local FLIP = CFrame.Angles(0, 0, math.pi)
local TIP_RIGHT = CFrame.Angles(0, math.rad(-90), 0)
local TIP_LEFT = CFrame.Angles(0, math.rad(90), 0)

local ANODIZED_BLACK = rgb(28, 30, 34)
local GRIP_RUBBER = rgb(22, 22, 24)
local BRUSHED_ALUMINUM = rgb(163, 167, 172)
local GUNMETAL = rgb(62, 66, 72)
local VENT_BLACK = rgb(12, 12, 14)
local BOLT_STEEL = rgb(192, 195, 200)
local CELL_GLASS = rgb(170, 225, 245)
local PLASMA_WHITE = rgb(215, 248, 255)
local PLASMA_CYAN = rgb(60, 200, 255)
local PLASMA_HALO = rgb(35, 160, 255)

local GRIP_RING = Vector3.new(0.08, 0.38, 0.38)
local VENT = Vector3.new(0.04, 0.02, 0.22)
local BOLT = Vector3.new(0.03, 0.08, 0.08)
local CELL_BAR = Vector3.new(0.04, 0.04, 0.16)
local GUARD_TIP = Vector3.new(0.30, 0.15, 0.25)

return WeaponModel.define({
	-- Held upright: blade toward -Z, edge (blade width along Y) faces -Y onto the target.
	hold = "upright",
	handle = {
		size = Vector3.new(0.4, 0.4, 1.2),
		color = ANODIZED_BLACK,
		material = M.Metal,
		transparency = 1,
	},
	pieces = {
		-- Grip
		{
			name = "GripTube",
			shape = CYLINDER,
			size = Vector3.new(1.20, 0.34, 0.34),
			offset = CFrame.new(0, 0, 0) * CYLINDER_Z,
			color = ANODIZED_BLACK,
			material = M.Metal,
		},
		{
			name = "GripRing1",
			shape = CYLINDER,
			size = GRIP_RING,
			offset = CFrame.new(0, 0, -0.45) * CYLINDER_Z,
			color = GRIP_RUBBER,
			material = M.Rubber,
		},
		{
			name = "GripRing2",
			shape = CYLINDER,
			size = GRIP_RING,
			offset = CFrame.new(0, 0, -0.225) * CYLINDER_Z,
			color = GRIP_RUBBER,
			material = M.Rubber,
		},
		{
			name = "GripRing3",
			shape = CYLINDER,
			size = GRIP_RING,
			offset = CFrame.new(0, 0, 0) * CYLINDER_Z,
			color = GRIP_RUBBER,
			material = M.Rubber,
		},
		{
			name = "GripRing4",
			shape = CYLINDER,
			size = GRIP_RING,
			offset = CFrame.new(0, 0, 0.225) * CYLINDER_Z,
			color = GRIP_RUBBER,
			material = M.Rubber,
		},
		{
			name = "GripRing5",
			shape = CYLINDER,
			size = GRIP_RING,
			offset = CFrame.new(0, 0, 0.45) * CYLINDER_Z,
			color = GRIP_RUBBER,
			material = M.Rubber,
		},
		{
			name = "FrontFerrule",
			shape = CYLINDER,
			size = Vector3.new(0.08, 0.40, 0.40),
			offset = CFrame.new(0, 0, -0.565) * CYLINDER_Z,
			color = BRUSHED_ALUMINUM,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "ActivatorSwitch",
			size = Vector3.new(0.08, 0.06, 0.12),
			offset = CFrame.new(0, 0.19, -0.335),
			color = BOLT_STEEL,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "ActivatorLED",
			shape = BALL,
			size = Vector3.new(0.05, 0.05, 0.05),
			offset = CFrame.new(0, 0.23, -0.335),
			color = PLASMA_CYAN,
			material = M.Neon,
		},

		-- Pommel
		{
			name = "PommelCollar",
			shape = CYLINDER,
			size = Vector3.new(0.10, 0.40, 0.40),
			offset = CFrame.new(0, 0, 0.65) * CYLINDER_Z,
			color = BRUSHED_ALUMINUM,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "CellWindow",
			shape = CYLINDER,
			size = Vector3.new(0.16, 0.30, 0.30),
			offset = CFrame.new(0, 0, 0.78) * CYLINDER_Z,
			color = CELL_GLASS,
			material = M.Glass,
			transparency = 0.45,
		},
		{
			name = "CellCore",
			shape = CYLINDER,
			size = Vector3.new(0.14, 0.18, 0.18),
			offset = CFrame.new(0, 0, 0.78) * CYLINDER_Z,
			color = PLASMA_CYAN,
			material = M.Neon,
		},
		{
			name = "CellBarTop",
			size = CELL_BAR,
			offset = CFrame.new(0, 0.155, 0.78),
			color = BRUSHED_ALUMINUM,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "CellBarBottom",
			size = CELL_BAR,
			offset = CFrame.new(0, -0.155, 0.78),
			color = BRUSHED_ALUMINUM,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "CellBarRight",
			size = CELL_BAR,
			offset = CFrame.new(0.155, 0, 0.78),
			color = BRUSHED_ALUMINUM,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "CellBarLeft",
			size = CELL_BAR,
			offset = CFrame.new(-0.155, 0, 0.78),
			color = BRUSHED_ALUMINUM,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "PommelCap",
			shape = CYLINDER,
			size = Vector3.new(0.10, 0.42, 0.42),
			offset = CFrame.new(0, 0, 0.91) * CYLINDER_Z,
			color = BRUSHED_ALUMINUM,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "PommelEndCap",
			shape = CYLINDER,
			size = Vector3.new(0.06, 0.32, 0.32),
			offset = CFrame.new(0, 0, 0.99) * CYLINDER_Z,
			color = ANODIZED_BLACK,
			material = M.Metal,
		},

		-- Crossguard
		{
			name = "EmitterNeck",
			shape = CYLINDER,
			size = Vector3.new(0.12, 0.36, 0.36),
			offset = CFrame.new(0, 0, -0.66) * CYLINDER_Z,
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "GuardBody",
			size = Vector3.new(1.00, 0.30, 0.30),
			offset = CFrame.new(0, 0, -0.85),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "GuardTipRightUpper",
			class = "WedgePart",
			size = GUARD_TIP,
			offset = CFrame.new(0.625, 0.075, -0.85) * TIP_RIGHT,
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "GuardTipRightLower",
			class = "WedgePart",
			size = GUARD_TIP,
			offset = CFrame.new(0.625, -0.075, -0.85) * TIP_RIGHT * FLIP,
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "GuardTipLeftUpper",
			class = "WedgePart",
			size = GUARD_TIP,
			offset = CFrame.new(-0.625, 0.075, -0.85) * TIP_LEFT,
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "GuardTipLeftLower",
			class = "WedgePart",
			size = GUARD_TIP,
			offset = CFrame.new(-0.625, -0.075, -0.85) * TIP_LEFT * FLIP,
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "VentR1",
			size = VENT,
			offset = CFrame.new(0.22, 0.155, -0.85),
			color = VENT_BLACK,
			material = M.SmoothPlastic,
		},
		{
			name = "VentR2",
			size = VENT,
			offset = CFrame.new(0.32, 0.155, -0.85),
			color = VENT_BLACK,
			material = M.SmoothPlastic,
		},
		{
			name = "VentR3",
			size = VENT,
			offset = CFrame.new(0.42, 0.155, -0.85),
			color = VENT_BLACK,
			material = M.SmoothPlastic,
		},
		{
			name = "VentL1",
			size = VENT,
			offset = CFrame.new(-0.22, 0.155, -0.85),
			color = VENT_BLACK,
			material = M.SmoothPlastic,
		},
		{
			name = "VentL2",
			size = VENT,
			offset = CFrame.new(-0.32, 0.155, -0.85),
			color = VENT_BLACK,
			material = M.SmoothPlastic,
		},
		{
			name = "VentL3",
			size = VENT,
			offset = CFrame.new(-0.42, 0.155, -0.85),
			color = VENT_BLACK,
			material = M.SmoothPlastic,
		},
		{
			name = "BoltRearRight",
			shape = CYLINDER,
			size = BOLT,
			offset = CFrame.new(0.35, 0, -0.69) * CYLINDER_Z,
			color = BOLT_STEEL,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "BoltRearLeft",
			shape = CYLINDER,
			size = BOLT,
			offset = CFrame.new(-0.35, 0, -0.69) * CYLINDER_Z,
			color = BOLT_STEEL,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "BoltFrontRight",
			shape = CYLINDER,
			size = BOLT,
			offset = CFrame.new(0.38, 0, -1.01) * CYLINDER_Z,
			color = BOLT_STEEL,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "BoltFrontLeft",
			shape = CYLINDER,
			size = BOLT,
			offset = CFrame.new(-0.38, 0, -1.01) * CYLINDER_Z,
			color = BOLT_STEEL,
			material = M.Metal,
			reflectance = 0.1,
		},

		-- Emitter
		{
			name = "EmitterMouth",
			size = Vector3.new(0.28, 0.84, 0.10),
			offset = CFrame.new(0, 0, -1.05),
			color = GUNMETAL,
			material = M.Metal,
		},
		{
			name = "ClawUpper",
			size = Vector3.new(0.26, 0.08, 0.17),
			offset = CFrame.new(0, 0.445, -1.095),
			color = BRUSHED_ALUMINUM,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "ClawLower",
			size = Vector3.new(0.26, 0.08, 0.17),
			offset = CFrame.new(0, -0.445, -1.095),
			color = BRUSHED_ALUMINUM,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "ClawTipUpper",
			class = "WedgePart",
			size = Vector3.new(0.26, 0.08, 0.12),
			offset = CFrame.new(0, 0.445, -1.24),
			color = BRUSHED_ALUMINUM,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "ClawTipLower",
			class = "WedgePart",
			size = Vector3.new(0.26, 0.08, 0.12),
			offset = CFrame.new(0, -0.445, -1.24) * FLIP,
			color = BRUSHED_ALUMINUM,
			material = M.Metal,
			reflectance = 0.05,
		},

		-- Blade: white-hot core inside a cyan glow inside a faint halo
		{
			name = "BladeCore",
			size = Vector3.new(0.06, 0.50, 3.60),
			offset = CFrame.new(0, 0, -2.82),
			color = PLASMA_WHITE,
			material = M.Neon,
		},
		{
			name = "BladeCoreTipUpper",
			class = "WedgePart",
			size = Vector3.new(0.06, 0.25, 0.50),
			offset = CFrame.new(0, 0.125, -4.87),
			color = PLASMA_WHITE,
			material = M.Neon,
		},
		{
			name = "BladeCoreTipLower",
			class = "WedgePart",
			size = Vector3.new(0.06, 0.25, 0.50),
			offset = CFrame.new(0, -0.125, -4.87) * FLIP,
			color = PLASMA_WHITE,
			material = M.Neon,
		},
		{
			name = "BladeGlow",
			size = Vector3.new(0.14, 0.66, 3.66),
			offset = CFrame.new(0, 0, -2.87),
			color = PLASMA_CYAN,
			material = M.Neon,
			transparency = 0.25,
		},
		{
			name = "BladeGlowTipUpper",
			class = "WedgePart",
			size = Vector3.new(0.14, 0.33, 0.60),
			offset = CFrame.new(0, 0.165, -5.00),
			color = PLASMA_CYAN,
			material = M.Neon,
			transparency = 0.25,
		},
		{
			name = "BladeGlowTipLower",
			class = "WedgePart",
			size = Vector3.new(0.14, 0.33, 0.60),
			offset = CFrame.new(0, -0.165, -5.00) * FLIP,
			color = PLASMA_CYAN,
			material = M.Neon,
			transparency = 0.25,
		},
		{
			name = "BladeHalo",
			size = Vector3.new(0.24, 0.80, 3.70),
			offset = CFrame.new(0, 0, -2.91),
			color = PLASMA_HALO,
			material = M.Neon,
			transparency = 0.7,
		},
		{
			name = "BladeHaloTipUpper",
			class = "WedgePart",
			size = Vector3.new(0.24, 0.40, 0.66),
			offset = CFrame.new(0, 0.20, -5.09),
			color = PLASMA_HALO,
			material = M.Neon,
			transparency = 0.7,
		},
		{
			name = "BladeHaloTipLower",
			class = "WedgePart",
			size = Vector3.new(0.24, 0.40, 0.66),
			offset = CFrame.new(0, -0.20, -5.09) * FLIP,
			color = PLASMA_HALO,
			material = M.Neon,
			transparency = 0.7,
		},
	},
})
