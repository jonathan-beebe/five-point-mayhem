-- War Hammer: 15th-century European foot war hammer (c. 1450-1500, Wallace Collection / Royal Armouries type).

local WeaponModel = require(script.Parent.Parent.systems.WeaponModel)

local rgb = Color3.fromRGB
local M = Enum.Material
local CYLINDER_Z = WeaponModel.CYLINDER_Z
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball

local FORGED_STEEL = rgb(90, 90, 100)
local DARK_STEEL = rgb(62, 64, 70)
local POLISHED_STEEL = rgb(150, 152, 158)
local RIVET_IRON = rgb(112, 112, 120)
local ASH_WOOD = rgb(128, 98, 66)
local LEATHER_BASE = rgb(82, 52, 34)
local LEATHER_WRAP = rgb(64, 40, 26)
local BRASS_WIRE = rgb(160, 128, 70)

-- Head centre along Z; every head offset is HZ + dz.
local HZ = -3.9

-- Turns the beak about its own axis (X) through the head centre so its curve bends toward the butt (+Z).
local BEAK_CURL = CFrame.new(0, 0, HZ) * CFrame.Angles(math.rad(-90), 0, 0) * CFrame.new(0, 0, -HZ)

local WRAP_TILT = CFrame.Angles(math.rad(10), 0, 0)

return WeaponModel.define({
	-- Held upright: the head (-Z) rises from the fist and the face strikes forward (-Y) on the swing.
	hold = "upright",
	-- Roll about the haft: the face (built at +X) turns to -Y, the beak to +Y.
	rotation = CFrame.Angles(0, 0, -math.pi / 2),
	handle = {
		size = Vector3.new(0.36, 0.36, 1.2),
		color = LEATHER_BASE,
		material = M.Leather,
		transparency = 1,
	},
	pieces = {
		-- Haft: ash, z +0.55 to -3.95, top end buried in the head core
		{
			name = "Haft",
			shape = CYL,
			size = Vector3.new(4.5, 0.32, 0.32),
			offset = CFrame.new(0, 0, -1.7) * CYLINDER_Z,
			color = ASH_WOOD,
			material = M.Wood,
		},

		-- Butt
		{
			name = "ButtCap",
			shape = CYL,
			size = Vector3.new(0.14, 0.4, 0.4),
			offset = CFrame.new(0, 0, 0.6) * CYLINDER_Z,
			color = DARK_STEEL,
			material = M.Metal,
		},
		{
			name = "Pommel",
			shape = BALL,
			size = Vector3.new(0.26, 0.26, 0.26),
			offset = CFrame.new(0, 0, 0.72),
			color = DARK_STEEL,
			material = M.Metal,
		},

		-- Grip: leather sleeve, spiral wrap, brass wire bindings
		{
			name = "GripSleeve",
			shape = CYL,
			size = Vector3.new(1.5, 0.36, 0.36),
			offset = CFrame.new(0, 0, -0.2) * CYLINDER_Z,
			color = LEATHER_BASE,
			material = M.Leather,
		},
		{
			name = "GripWrap1",
			shape = CYL,
			size = Vector3.new(0.07, 0.385, 0.385),
			offset = CFrame.new(0, 0, 0.38) * WRAP_TILT * CYLINDER_Z,
			color = LEATHER_WRAP,
			material = M.Leather,
		},
		{
			name = "GripWrap2",
			shape = CYL,
			size = Vector3.new(0.07, 0.385, 0.385),
			offset = CFrame.new(0, 0, 0.13) * WRAP_TILT * CYLINDER_Z,
			color = LEATHER_WRAP,
			material = M.Leather,
		},
		{
			name = "GripWrap3",
			shape = CYL,
			size = Vector3.new(0.07, 0.385, 0.385),
			offset = CFrame.new(0, 0, -0.12) * WRAP_TILT * CYLINDER_Z,
			color = LEATHER_WRAP,
			material = M.Leather,
		},
		{
			name = "GripWrap4",
			shape = CYL,
			size = Vector3.new(0.07, 0.385, 0.385),
			offset = CFrame.new(0, 0, -0.37) * WRAP_TILT * CYLINDER_Z,
			color = LEATHER_WRAP,
			material = M.Leather,
		},
		{
			name = "GripWrap5",
			shape = CYL,
			size = Vector3.new(0.07, 0.385, 0.385),
			offset = CFrame.new(0, 0, -0.62) * WRAP_TILT * CYLINDER_Z,
			color = LEATHER_WRAP,
			material = M.Leather,
		},
		{
			name = "WireTop",
			shape = CYL,
			size = Vector3.new(0.05, 0.39, 0.39),
			offset = CFrame.new(0, 0, -0.9) * CYLINDER_Z,
			color = BRASS_WIRE,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "WireBottom",
			shape = CYL,
			size = Vector3.new(0.05, 0.39, 0.39),
			offset = CFrame.new(0, 0, 0.5) * CYLINDER_Z,
			color = BRASS_WIRE,
			material = M.Metal,
			reflectance = 0.05,
		},

		-- Rondel guard above the hand
		{
			name = "RondelDisc",
			shape = CYL,
			size = Vector3.new(0.05, 0.8, 0.8),
			offset = CFrame.new(0, 0, -1.02) * CYLINDER_Z,
			color = DARK_STEEL,
			material = M.Metal,
		},
		{
			name = "RondelBoss",
			shape = CYL,
			size = Vector3.new(0.12, 0.42, 0.42),
			offset = CFrame.new(0, 0, -1.02) * CYLINDER_Z,
			color = DARK_STEEL,
			material = M.Metal,
		},

		-- Langets: four riveted steel strips, z -2.1 to -4.0, inner faces 0.01 inside the haft
		{
			name = "LangetR",
			size = Vector3.new(0.04, 0.12, 1.9),
			offset = CFrame.new(0.17, 0, -3.05),
			color = DARK_STEEL,
			material = M.Metal,
		},
		{
			name = "LangetL",
			size = Vector3.new(0.04, 0.12, 1.9),
			offset = CFrame.new(-0.17, 0, -3.05),
			color = DARK_STEEL,
			material = M.Metal,
		},
		{
			name = "LangetT",
			size = Vector3.new(0.12, 0.04, 1.9),
			offset = CFrame.new(0, 0.17, -3.05),
			color = DARK_STEEL,
			material = M.Metal,
		},
		{
			name = "LangetB",
			size = Vector3.new(0.12, 0.04, 1.9),
			offset = CFrame.new(0, -0.17, -3.05),
			color = DARK_STEEL,
			material = M.Metal,
		},
		{
			name = "Rivet1",
			shape = BALL,
			size = Vector3.new(0.08, 0.08, 0.08),
			offset = CFrame.new(0.19, 0, -2.4),
			color = RIVET_IRON,
			material = M.Metal,
		},
		{
			name = "Rivet2",
			shape = BALL,
			size = Vector3.new(0.08, 0.08, 0.08),
			offset = CFrame.new(-0.19, 0, -2.4),
			color = RIVET_IRON,
			material = M.Metal,
		},
		{
			name = "Rivet3",
			shape = BALL,
			size = Vector3.new(0.08, 0.08, 0.08),
			offset = CFrame.new(0, 0.19, -2.4),
			color = RIVET_IRON,
			material = M.Metal,
		},
		{
			name = "Rivet4",
			shape = BALL,
			size = Vector3.new(0.08, 0.08, 0.08),
			offset = CFrame.new(0, -0.19, -2.4),
			color = RIVET_IRON,
			material = M.Metal,
		},
		{
			name = "Rivet5",
			shape = BALL,
			size = Vector3.new(0.08, 0.08, 0.08),
			offset = CFrame.new(0.19, 0, -3.1),
			color = RIVET_IRON,
			material = M.Metal,
		},
		{
			name = "Rivet6",
			shape = BALL,
			size = Vector3.new(0.08, 0.08, 0.08),
			offset = CFrame.new(-0.19, 0, -3.1),
			color = RIVET_IRON,
			material = M.Metal,
		},
		{
			name = "Rivet7",
			shape = BALL,
			size = Vector3.new(0.08, 0.08, 0.08),
			offset = CFrame.new(0, 0.19, -3.1),
			color = RIVET_IRON,
			material = M.Metal,
		},
		{
			name = "Rivet8",
			shape = BALL,
			size = Vector3.new(0.08, 0.08, 0.08),
			offset = CFrame.new(0, -0.19, -3.1),
			color = RIVET_IRON,
			material = M.Metal,
		},
		{
			name = "LangetCollar",
			shape = CYL,
			size = Vector3.new(0.08, 0.44, 0.44),
			offset = CFrame.new(0, 0, -2.1) * CYLINDER_Z,
			color = DARK_STEEL,
			material = M.Metal,
		},
		{
			name = "SocketCollar",
			shape = CYL,
			size = Vector3.new(0.16, 0.48, 0.48),
			offset = CFrame.new(0, 0, HZ + 0.38) * CYLINDER_Z,
			color = FORGED_STEEL,
			material = M.Metal,
			reflectance = 0.08,
		},

		-- Head core: octagonal YZ section from two crossed blocks plus four edge bevels
		{
			name = "CoreA",
			size = Vector3.new(0.8, 0.7, 0.46),
			offset = CFrame.new(0, 0, HZ),
			color = FORGED_STEEL,
			material = M.Metal,
			reflectance = 0.08,
		},
		{
			name = "CoreB",
			size = Vector3.new(0.78, 0.46, 0.7),
			offset = CFrame.new(0, 0, HZ),
			color = FORGED_STEEL,
			material = M.Metal,
			reflectance = 0.08,
		},
		{
			name = "BevelTopFront",
			class = "WedgePart",
			size = Vector3.new(0.8, 0.12, 0.12),
			offset = CFrame.new(0, 0.29, HZ - 0.29),
			color = FORGED_STEEL,
			material = M.Metal,
			reflectance = 0.08,
		},
		{
			name = "BevelTopBack",
			class = "WedgePart",
			size = Vector3.new(0.8, 0.12, 0.12),
			offset = CFrame.new(0, 0.29, HZ + 0.29) * CFrame.Angles(0, math.rad(180), 0),
			color = FORGED_STEEL,
			material = M.Metal,
			reflectance = 0.08,
		},
		{
			name = "BevelBotFront",
			class = "WedgePart",
			size = Vector3.new(0.8, 0.12, 0.12),
			offset = CFrame.new(0, -0.29, HZ - 0.29) * CFrame.Angles(0, 0, math.rad(180)),
			color = FORGED_STEEL,
			material = M.Metal,
			reflectance = 0.08,
		},
		{
			name = "BevelBotBack",
			class = "WedgePart",
			size = Vector3.new(0.8, 0.12, 0.12),
			offset = CFrame.new(0, -0.29, HZ + 0.29) * CFrame.Angles(math.rad(180), 0, 0),
			color = FORGED_STEEL,
			material = M.Metal,
			reflectance = 0.08,
		},

		-- Striking face (+X): round neck, flare, square face with a 2x2 waffle of teeth
		{
			name = "FaceNeck",
			shape = CYL,
			size = Vector3.new(0.36, 0.6, 0.6),
			offset = CFrame.new(0.57, 0, HZ),
			color = FORGED_STEEL,
			material = M.Metal,
			reflectance = 0.08,
		},
		{
			name = "FaceFlare",
			shape = CYL,
			size = Vector3.new(0.12, 0.72, 0.72),
			offset = CFrame.new(0.81, 0, HZ),
			color = FORGED_STEEL,
			material = M.Metal,
			reflectance = 0.08,
		},
		{
			name = "FaceBlock",
			size = Vector3.new(0.18, 0.8, 0.8),
			offset = CFrame.new(0.96, 0, HZ),
			color = FORGED_STEEL,
			material = M.Metal,
			reflectance = 0.08,
		},
		{
			name = "FaceTooth1",
			size = Vector3.new(0.1, 0.26, 0.26),
			offset = CFrame.new(1.08, 0.19, HZ + 0.19) * CFrame.Angles(math.rad(45), 0, 0),
			color = POLISHED_STEEL,
			material = M.Metal,
			reflectance = 0.15,
		},
		{
			name = "FaceTooth2",
			size = Vector3.new(0.1, 0.26, 0.26),
			offset = CFrame.new(1.08, 0.19, HZ - 0.19) * CFrame.Angles(math.rad(45), 0, 0),
			color = POLISHED_STEEL,
			material = M.Metal,
			reflectance = 0.15,
		},
		{
			name = "FaceTooth3",
			size = Vector3.new(0.1, 0.26, 0.26),
			offset = CFrame.new(1.08, -0.19, HZ + 0.19) * CFrame.Angles(math.rad(45), 0, 0),
			color = POLISHED_STEEL,
			material = M.Metal,
			reflectance = 0.15,
		},
		{
			name = "FaceTooth4",
			size = Vector3.new(0.1, 0.26, 0.26),
			offset = CFrame.new(1.08, -0.19, HZ - 0.19) * CFrame.Angles(math.rad(45), 0, 0),
			color = POLISHED_STEEL,
			material = M.Metal,
			reflectance = 0.15,
		},

		-- Raven's beak (-X), tapering segments curving toward the butt (+Z) to a polished point
		{
			name = "BeakRoot",
			size = Vector3.new(0.42, 0.5, 0.4),
			offset = BEAK_CURL * CFrame.new(-0.59, 0, HZ),
			color = FORGED_STEEL,
			material = M.Metal,
			reflectance = 0.08,
		},
		{
			name = "BeakSeg1",
			size = Vector3.new(0.5, 0.36, 0.28),
			offset = BEAK_CURL * CFrame.new(-1, -0.03, HZ) * CFrame.Angles(0, 0, math.rad(8)),
			color = FORGED_STEEL,
			material = M.Metal,
			reflectance = 0.08,
		},
		{
			name = "BeakSeg2",
			size = Vector3.new(0.4, 0.26, 0.2),
			offset = BEAK_CURL * CFrame.new(-1.38, -0.12, HZ) * CFrame.Angles(0, 0, math.rad(18)),
			color = FORGED_STEEL,
			material = M.Metal,
			reflectance = 0.08,
		},
		{
			-- Local -Z points along -X, tilted 28 degrees toward the butt; flat face continues the curve.
			name = "BeakTip",
			class = "WedgePart",
			size = Vector3.new(0.16, 0.24, 0.5),
			offset = BEAK_CURL
				* CFrame.new(-1.76, -0.3, HZ)
				* CFrame.Angles(0, 0, math.rad(28))
				* CFrame.Angles(0, math.rad(90), 0),
			color = POLISHED_STEEL,
			material = M.Metal,
			reflectance = 0.15,
		},

		-- Top spike (-Z): square base and four tapered fins meeting at the point
		{
			name = "SpikeBase",
			size = Vector3.new(0.36, 0.36, 0.25),
			offset = CFrame.new(0, 0, HZ - 0.45),
			color = FORGED_STEEL,
			material = M.Metal,
			reflectance = 0.08,
		},
		{
			name = "SpikeTop",
			class = "WedgePart",
			size = Vector3.new(0.2, 0.14, 0.45),
			offset = CFrame.new(0, 0.07, HZ - 0.79),
			color = POLISHED_STEEL,
			material = M.Metal,
			reflectance = 0.15,
		},
		{
			name = "SpikeBottom",
			class = "WedgePart",
			size = Vector3.new(0.2, 0.14, 0.45),
			offset = CFrame.new(0, -0.07, HZ - 0.79) * CFrame.Angles(0, 0, math.rad(180)),
			color = POLISHED_STEEL,
			material = M.Metal,
			reflectance = 0.15,
		},
		{
			name = "SpikeRight",
			class = "WedgePart",
			size = Vector3.new(0.2, 0.14, 0.45),
			offset = CFrame.new(0.07, 0, HZ - 0.79) * CFrame.Angles(0, 0, math.rad(-90)),
			color = POLISHED_STEEL,
			material = M.Metal,
			reflectance = 0.15,
		},
		{
			name = "SpikeLeft",
			class = "WedgePart",
			size = Vector3.new(0.2, 0.14, 0.45),
			offset = CFrame.new(-0.07, 0, HZ - 0.79) * CFrame.Angles(0, 0, math.rad(90)),
			color = POLISHED_STEEL,
			material = M.Metal,
			reflectance = 0.15,
		},
	},
})
