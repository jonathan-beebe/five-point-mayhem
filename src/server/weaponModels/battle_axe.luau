-- Battle Axe: late-medieval European long-hafted bearded battle axe (Dane-axe line, c. 1100-1400).

local WeaponModel = require(script.Parent.Parent.systems.WeaponModel)

local rgb = Color3.fromRGB
local M = Enum.Material
local CYLINDER_Z = WeaponModel.CYLINDER_Z
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball

-- Wedge orientations (see WedgePart default: right angle at local (ymin, zmax)).
local FLIP_Z = CFrame.Angles(0, 0, math.pi) -- right angle at (ymax, zmax)
local FLIP_X = CFrame.Angles(math.pi, 0, 0) -- right angle at (ymax, zmin)
local SIDE_R = CFrame.Angles(0, -math.pi / 2, 0) -- triangle in XY, slope facing +X
local SIDE_L = CFrame.Angles(0, math.pi / 2, 0) -- triangle in XY, slope facing -X

local LACE_TILT = CFrame.Angles(math.rad(12), 0, 0)

local BIT_STEEL = rgb(120, 120, 130)
local HONED_EDGE = rgb(196, 198, 204)
local FORGED_IRON = rgb(62, 62, 68)
local PEENED_IRON = rgb(92, 90, 86)
local STAMP_DARK = rgb(40, 40, 44)
local ASH_WOOD = rgb(142, 106, 68)
local LEATHER = rgb(74, 48, 30)
local LEATHER_LACE = rgb(58, 37, 23)
local WHIP_CORD = rgb(52, 40, 30)

local RING_SIZE = Vector3.new(0.04, 0.35, 0.35)
local LANGET_SIZE = Vector3.new(0.03, 0.12, 1.05)
local LANGET_RIVET = Vector3.new(0.07, 0.07, 0.07)
local SOCKET_RIVET = Vector3.new(0.09, 0.09, 0.09)
local EDGE_SIZE = Vector3.new(1.85, 0.20, 0.08)
local SPIKE_SIZE = Vector3.new(0.16, 0.60, 0.15)

return WeaponModel.define({
	handle = {
		size = Vector3.new(0.3, 0.3, 1.2),
		color = LEATHER,
		material = M.Leather,
		transparency = 1,
	},
	pieces = {
		-- Haft
		{
			name = "Haft",
			shape = CYL,
			size = Vector3.new(4.50, 0.30, 0.30),
			offset = CFrame.new(0, 0, -1.65) * CYLINDER_Z,
			color = ASH_WOOD,
			material = M.Wood,
		},
		{
			name = "TopCap",
			shape = CYL,
			size = Vector3.new(0.12, 0.32, 0.32),
			offset = CFrame.new(0, 0, -3.94) * CYLINDER_Z,
			color = FORGED_IRON,
			material = M.Metal,
		},
		{
			name = "TopKnob",
			shape = BALL,
			size = Vector3.new(0.22, 0.22, 0.22),
			offset = CFrame.new(0, 0, -4.00),
			color = FORGED_IRON,
			material = M.Metal,
		},
		{
			name = "ButtFerrule",
			shape = CYL,
			size = Vector3.new(0.14, 0.34, 0.34),
			offset = CFrame.new(0, 0, 0.57) * CYLINDER_Z,
			color = FORGED_IRON,
			material = M.Metal,
		},
		{
			name = "ButtEndCap",
			shape = CYL,
			size = Vector3.new(0.04, 0.28, 0.28),
			offset = CFrame.new(0, 0, 0.66) * CYLINDER_Z,
			color = PEENED_IRON,
			material = M.Metal,
		},

		-- Grip
		{
			name = "GripWrap",
			shape = CYL,
			size = Vector3.new(1.10, 0.33, 0.33),
			offset = CFrame.new(0, 0, -0.10) * CYLINDER_Z,
			color = LEATHER,
			material = M.Leather,
		},
		{
			name = "WrapRing1",
			shape = CYL,
			size = RING_SIZE,
			offset = CFrame.new(0, 0, 0.33) * LACE_TILT * CYLINDER_Z,
			color = LEATHER_LACE,
			material = M.Leather,
		},
		{
			name = "WrapRing2",
			shape = CYL,
			size = RING_SIZE,
			offset = CFrame.new(0, 0, 0.11) * LACE_TILT * CYLINDER_Z,
			color = LEATHER_LACE,
			material = M.Leather,
		},
		{
			name = "WrapRing3",
			shape = CYL,
			size = RING_SIZE,
			offset = CFrame.new(0, 0, -0.11) * LACE_TILT * CYLINDER_Z,
			color = LEATHER_LACE,
			material = M.Leather,
		},
		{
			name = "WrapRing4",
			shape = CYL,
			size = RING_SIZE,
			offset = CFrame.new(0, 0, -0.33) * LACE_TILT * CYLINDER_Z,
			color = LEATHER_LACE,
			material = M.Leather,
		},
		{
			name = "WrapRing5",
			shape = CYL,
			size = RING_SIZE,
			offset = CFrame.new(0, 0, -0.55) * LACE_TILT * CYLINDER_Z,
			color = LEATHER_LACE,
			material = M.Leather,
		},
		{
			name = "WhipLower",
			shape = CYL,
			size = Vector3.new(0.06, 0.35, 0.35),
			offset = CFrame.new(0, 0, 0.47) * CYLINDER_Z,
			color = WHIP_CORD,
			material = M.Fabric,
		},
		{
			name = "WhipUpper",
			shape = CYL,
			size = Vector3.new(0.06, 0.35, 0.35),
			offset = CFrame.new(0, 0, -0.67) * CYLINDER_Z,
			color = WHIP_CORD,
			material = M.Fabric,
		},

		-- Langets
		{
			name = "LangetR",
			size = LANGET_SIZE,
			offset = CFrame.new(0.165, 0, -2.675),
			color = BIT_STEEL,
			material = M.Metal,
		},
		{
			name = "LangetL",
			size = LANGET_SIZE,
			offset = CFrame.new(-0.165, 0, -2.675),
			color = BIT_STEEL,
			material = M.Metal,
		},
		{
			name = "LangetRivetR1",
			shape = BALL,
			size = LANGET_RIVET,
			offset = CFrame.new(0.18, 0, -2.35),
			color = PEENED_IRON,
			material = M.Metal,
		},
		{
			name = "LangetRivetR2",
			shape = BALL,
			size = LANGET_RIVET,
			offset = CFrame.new(0.18, 0, -2.90),
			color = PEENED_IRON,
			material = M.Metal,
		},
		{
			name = "LangetRivetL1",
			shape = BALL,
			size = LANGET_RIVET,
			offset = CFrame.new(-0.18, 0, -2.35),
			color = PEENED_IRON,
			material = M.Metal,
		},
		{
			name = "LangetRivetL2",
			shape = BALL,
			size = LANGET_RIVET,
			offset = CFrame.new(-0.18, 0, -2.90),
			color = PEENED_IRON,
			material = M.Metal,
		},

		-- Head: eye socket (rims sit 0.01 inside the socket ends so their end faces do not z-fight)
		{
			name = "EyeSocket",
			shape = CYL,
			size = Vector3.new(0.70, 0.40, 0.40),
			offset = CFrame.new(0, 0, -3.50) * CYLINDER_Z,
			color = FORGED_IRON,
			material = M.Metal,
		},
		{
			name = "SocketRimLower",
			shape = CYL,
			size = Vector3.new(0.06, 0.44, 0.44),
			offset = CFrame.new(0, 0, -3.19) * CYLINDER_Z,
			color = FORGED_IRON,
			material = M.Metal,
		},
		{
			name = "SocketRimUpper",
			shape = CYL,
			size = Vector3.new(0.06, 0.44, 0.44),
			offset = CFrame.new(0, 0, -3.81) * CYLINDER_Z,
			color = FORGED_IRON,
			material = M.Metal,
		},
		{
			name = "SocketRivetR",
			shape = BALL,
			size = SOCKET_RIVET,
			offset = CFrame.new(0.20, 0, -3.50),
			color = PEENED_IRON,
			material = M.Metal,
		},
		{
			name = "SocketRivetL",
			shape = BALL,
			size = SOCKET_RIVET,
			offset = CFrame.new(-0.20, 0, -3.50),
			color = PEENED_IRON,
			material = M.Metal,
		},

		-- Head: bit (+Y)
		{
			name = "BitNeck",
			size = Vector3.new(0.22, 0.73, 0.44),
			offset = CFrame.new(0, 0.485, -3.50),
			color = BIT_STEEL,
			material = M.Metal,
		},
		{
			name = "CheekBevelR",
			class = "WedgePart",
			size = Vector3.new(0.44, 0.15, 0.03),
			offset = CFrame.new(0.095, 0.925, -3.50) * SIDE_R,
			color = BIT_STEEL,
			material = M.Metal,
		},
		{
			name = "CheekBevelL",
			class = "WedgePart",
			size = Vector3.new(0.44, 0.15, 0.03),
			offset = CFrame.new(-0.095, 0.925, -3.50) * SIDE_L,
			color = BIT_STEEL,
			material = M.Metal,
		},
		{
			name = "BitBody",
			size = Vector3.new(0.16, 0.70, 1.17),
			offset = CFrame.new(0, 1.20, -3.135),
			color = BIT_STEEL,
			material = M.Metal,
		},
		{
			name = "BitToe",
			class = "WedgePart",
			size = Vector3.new(0.16, 0.80, 0.53),
			offset = CFrame.new(0, 1.15, -3.985) * FLIP_Z,
			color = BIT_STEEL,
			material = M.Metal,
		},
		{
			name = "BitBeard",
			class = "WedgePart",
			size = Vector3.new(0.16, 0.45, 0.73),
			offset = CFrame.new(0, 0.625, -2.915) * FLIP_X,
			color = BIT_STEEL,
			material = M.Metal,
		},
		{
			name = "BeardHook",
			class = "WedgePart",
			size = Vector3.new(0.16, 0.30, 0.15),
			offset = CFrame.new(0, 1.40, -2.475) * FLIP_X,
			color = BIT_STEEL,
			material = M.Metal,
		},
		{
			name = "EdgeBevelR",
			class = "WedgePart",
			size = EDGE_SIZE,
			offset = CFrame.new(0.04, 1.65, -3.325) * SIDE_R,
			color = HONED_EDGE,
			material = M.Metal,
			reflectance = 0.2,
		},
		{
			name = "EdgeBevelL",
			class = "WedgePart",
			size = EDGE_SIZE,
			offset = CFrame.new(-0.04, 1.65, -3.325) * SIDE_L,
			color = HONED_EDGE,
			material = M.Metal,
			reflectance = 0.2,
		},
		{
			name = "MakerMarkR",
			size = Vector3.new(0.01, 0.10, 0.10),
			offset = CFrame.new(0.085, 1.20, -3.30),
			color = STAMP_DARK,
			material = M.Metal,
		},
		{
			name = "MakerMarkL",
			size = Vector3.new(0.01, 0.10, 0.10),
			offset = CFrame.new(-0.085, 1.20, -3.30),
			color = STAMP_DARK,
			material = M.Metal,
		},
		-- Forge-scale seam: 0.01 proud of the neck faces and ends so it shows below the cheek bevels.
		{
			name = "BitForgeLine",
			size = Vector3.new(0.24, 0.03, 0.46),
			offset = CFrame.new(0, 0.86, -3.50),
			color = FORGED_IRON,
			material = M.Metal,
		},

		-- Head: back spike (-Y)
		{
			name = "SpikeBase",
			size = Vector3.new(0.18, 0.20, 0.30),
			offset = CFrame.new(0, -0.25, -3.50),
			color = BIT_STEEL,
			material = M.Metal,
		},
		{
			name = "SpikeFront",
			class = "WedgePart",
			size = SPIKE_SIZE,
			offset = CFrame.new(0, -0.65, -3.575) * FLIP_Z,
			color = BIT_STEEL,
			material = M.Metal,
		},
		{
			name = "SpikeBack",
			class = "WedgePart",
			size = SPIKE_SIZE,
			offset = CFrame.new(0, -0.65, -3.425) * FLIP_X,
			color = BIT_STEEL,
			material = M.Metal,
		},
	},
})
