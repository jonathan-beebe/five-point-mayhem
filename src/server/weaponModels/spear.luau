-- Spartan Spear: 5th-century BC Greek hoplite dory (ash shaft, cast-bronze leaf head, bronze sauroter).
-- Held upright with the fist about a third up the shaft; the leaf edges face ±Y, so one leads the
-- downward swing.

local WeaponModel = require(script.Parent.Parent.systems.WeaponModel)

local rgb = Color3.fromRGB
local M = Enum.Material
local CYLINDER_Z = WeaponModel.CYLINDER_Z
local rad = math.rad
local pi = math.pi

local OILED_ASH = rgb(156, 118, 78)
local OXBLOOD_LEATHER = rgb(92, 52, 36)
local LEATHER_RIDGE = rgb(70, 40, 28)
local SINEW = rgb(140, 110, 75)
local POLISHED_BRONZE = rgb(190, 160, 80)
local HONED_EDGE = rgb(215, 188, 118)
local MIDRIB_BRONZE = rgb(170, 138, 64)
local AGED_BRONZE = rgb(128, 98, 52)
local DARK_BRONZE_RING = rgb(105, 80, 42)
local RIVET_BRONZE = rgb(88, 66, 36)

local BALL = Enum.PartType.Ball
local CYL = Enum.PartType.Cylinder

local function ridge(name: string, z: number)
	return {
		name = name,
		shape = CYL,
		size = Vector3.new(0.04, 0.265, 0.265),
		offset = CFrame.new(0, 0, z) * CFrame.Angles(rad(12), 0, 0) * CYLINDER_Z,
		color = LEATHER_RIDGE,
		material = M.Leather,
	}
end

return WeaponModel.define({
	hold = "upright",
	handle = {
		size = Vector3.new(0.24, 0.24, 1.2),
		color = OXBLOOD_LEATHER,
		material = M.Leather,
		transparency = 1,
	},
	pieces = {
		-- Shaft: z +2.42 to -4.15, ends buried in both sockets
		{
			name = "Shaft",
			shape = CYL,
			size = Vector3.new(6.57, 0.22, 0.22),
			offset = CFrame.new(0, 0, -0.865) * CYLINDER_Z,
			color = OILED_ASH,
			material = M.Wood,
		},

		-- Grip wrap: leather centred on the hand, sinew ties, tilted ridges
		{
			name = "GripLeather",
			shape = CYL,
			size = Vector3.new(1.3, 0.25, 0.25),
			offset = CYLINDER_Z,
			color = OXBLOOD_LEATHER,
			material = M.Leather,
		},
		{
			name = "GripCordFront",
			shape = CYL,
			size = Vector3.new(0.07, 0.27, 0.27),
			offset = CFrame.new(0, 0, -0.665) * CYLINDER_Z,
			color = SINEW,
			material = M.Fabric,
		},
		{
			name = "GripCordRear",
			shape = CYL,
			size = Vector3.new(0.07, 0.27, 0.27),
			offset = CFrame.new(0, 0, 0.665) * CYLINDER_Z,
			color = SINEW,
			material = M.Fabric,
		},
		ridge("GripRidge1", -0.5),
		ridge("GripRidge2", -0.3),
		ridge("GripRidge3", -0.1),
		ridge("GripRidge4", 0.1),
		ridge("GripRidge5", 0.3),
		ridge("GripRidge6", 0.5),

		-- Sauroter (butt spike): z +2.10 to +2.91
		{
			name = "SauroterMouthRing",
			shape = CYL,
			size = Vector3.new(0.05, 0.3, 0.3),
			offset = CFrame.new(0, 0, 2.135) * CYLINDER_Z,
			color = DARK_BRONZE_RING,
			material = M.Metal,
		},
		{
			name = "SauroterSocket",
			shape = CYL,
			size = Vector3.new(0.35, 0.27, 0.27),
			offset = CFrame.new(0, 0, 2.275) * CYLINDER_Z,
			color = AGED_BRONZE,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "SauroterCollar",
			shape = CYL,
			size = Vector3.new(0.05, 0.3, 0.3),
			offset = CFrame.new(0, 0, 2.47) * CYLINDER_Z,
			color = DARK_BRONZE_RING,
			material = M.Metal,
		},
		{
			name = "SauroterBody",
			size = Vector3.new(0.17, 0.17, 0.18),
			offset = CFrame.new(0, 0, 2.58),
			color = AGED_BRONZE,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "SauroterChiselTop",
			class = "WedgePart",
			size = Vector3.new(0.17, 0.085, 0.24),
			offset = CFrame.new(0, 0.0425, 2.79) * CFrame.Angles(0, pi, 0),
			color = AGED_BRONZE,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "SauroterChiselBottom",
			class = "WedgePart",
			size = Vector3.new(0.17, 0.085, 0.24),
			offset = CFrame.new(0, -0.0425, 2.79) * CFrame.Angles(pi, 0, 0),
			color = AGED_BRONZE,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "SauroterRivetR",
			shape = BALL,
			size = Vector3.new(0.055, 0.055, 0.055),
			offset = CFrame.new(0.135, 0, 2.28),
			color = RIVET_BRONZE,
			material = M.Metal,
		},
		{
			name = "SauroterRivetL",
			shape = BALL,
			size = Vector3.new(0.055, 0.055, 0.055),
			offset = CFrame.new(-0.135, 0, 2.28),
			color = RIVET_BRONZE,
			material = M.Metal,
		},

		-- Head socket: z -3.75 to -4.50
		{
			name = "HeadMouthRing",
			shape = CYL,
			size = Vector3.new(0.05, 0.31, 0.31),
			offset = CFrame.new(0, 0, -3.785) * CYLINDER_Z,
			color = DARK_BRONZE_RING,
			material = M.Metal,
		},
		{
			name = "HeadSocket",
			shape = CYL,
			size = Vector3.new(0.5, 0.28, 0.28),
			offset = CFrame.new(0, 0, -4) * CYLINDER_Z,
			color = AGED_BRONZE,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			-- -4.20 to -4.24; front face 0.01 behind the socket end (-4.25)
			name = "HeadTopRing",
			shape = CYL,
			size = Vector3.new(0.04, 0.3, 0.3),
			offset = CFrame.new(0, 0, -4.22) * CYLINDER_Z,
			color = DARK_BRONZE_RING,
			material = M.Metal,
		},
		{
			-- -4.24 to -4.39
			name = "HeadTaper",
			shape = CYL,
			size = Vector3.new(0.15, 0.24, 0.24),
			offset = CFrame.new(0, 0, -4.315) * CYLINDER_Z,
			color = AGED_BRONZE,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			-- -4.38 to -4.50
			name = "HeadNeck",
			shape = CYL,
			size = Vector3.new(0.12, 0.19, 0.19),
			offset = CFrame.new(0, 0, -4.44) * CYLINDER_Z,
			color = POLISHED_BRONZE,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "HeadRivetR",
			shape = BALL,
			size = Vector3.new(0.065, 0.065, 0.065),
			offset = CFrame.new(0.14, 0, -3.9),
			color = RIVET_BRONZE,
			material = M.Metal,
		},
		{
			name = "HeadRivetL",
			shape = BALL,
			size = Vector3.new(0.065, 0.065, 0.065),
			offset = CFrame.new(-0.14, 0, -3.9),
			color = RIVET_BRONZE,
			material = M.Metal,
		},

		-- Leaf blade: core 0.06 thick, honed edges 0.04 thick; z -4.48 to -5.80
		-- Segment 1: flare, half-width 0.09 -> 0.23
		{
			name = "BladeCore1",
			size = Vector3.new(0.06, 0.18, 0.2),
			offset = CFrame.new(0, 0, -4.58),
			color = POLISHED_BRONZE,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "BladeEdge1Top",
			class = "WedgePart",
			size = Vector3.new(0.04, 0.14, 0.2),
			offset = CFrame.new(0, 0.16, -4.58) * CFrame.Angles(0, pi, 0),
			color = HONED_EDGE,
			material = M.Metal,
			reflectance = 0.2,
		},
		{
			name = "BladeEdge1Bottom",
			class = "WedgePart",
			size = Vector3.new(0.04, 0.14, 0.2),
			offset = CFrame.new(0, -0.16, -4.58) * CFrame.Angles(pi, 0, 0),
			color = HONED_EDGE,
			material = M.Metal,
			reflectance = 0.2,
		},
		-- Segment 2: flare, half-width 0.23 -> 0.31
		{
			name = "BladeCore2",
			size = Vector3.new(0.06, 0.46, 0.22),
			offset = CFrame.new(0, 0, -4.79),
			color = POLISHED_BRONZE,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "BladeEdge2Top",
			class = "WedgePart",
			size = Vector3.new(0.04, 0.08, 0.22),
			offset = CFrame.new(0, 0.27, -4.79) * CFrame.Angles(0, pi, 0),
			color = HONED_EDGE,
			material = M.Metal,
			reflectance = 0.2,
		},
		{
			name = "BladeEdge2Bottom",
			class = "WedgePart",
			size = Vector3.new(0.04, 0.08, 0.22),
			offset = CFrame.new(0, -0.27, -4.79) * CFrame.Angles(pi, 0, 0),
			color = HONED_EDGE,
			material = M.Metal,
			reflectance = 0.2,
		},
		-- Segment 3: widest, parallel edges at half-width 0.31
		{
			name = "BladeCore3",
			size = Vector3.new(0.06, 0.46, 0.2),
			offset = CFrame.new(0, 0, -5),
			color = POLISHED_BRONZE,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "BladeEdge3Top",
			size = Vector3.new(0.04, 0.08, 0.2),
			offset = CFrame.new(0, 0.27, -5),
			color = HONED_EDGE,
			material = M.Metal,
			reflectance = 0.2,
		},
		{
			name = "BladeEdge3Bottom",
			size = Vector3.new(0.04, 0.08, 0.2),
			offset = CFrame.new(0, -0.27, -5),
			color = HONED_EDGE,
			material = M.Metal,
			reflectance = 0.2,
		},
		-- Segment 4: narrowing, half-width 0.31 -> 0.21
		{
			name = "BladeCore4",
			size = Vector3.new(0.06, 0.42, 0.26),
			offset = CFrame.new(0, 0, -5.23),
			color = POLISHED_BRONZE,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "BladeEdge4Top",
			class = "WedgePart",
			size = Vector3.new(0.04, 0.1, 0.26),
			offset = CFrame.new(0, 0.26, -5.23),
			color = HONED_EDGE,
			material = M.Metal,
			reflectance = 0.2,
		},
		{
			name = "BladeEdge4Bottom",
			class = "WedgePart",
			size = Vector3.new(0.04, 0.1, 0.26),
			offset = CFrame.new(0, -0.26, -5.23) * CFrame.Angles(0, 0, pi),
			color = HONED_EDGE,
			material = M.Metal,
			reflectance = 0.2,
		},
		-- Segment 5: narrowing, half-width 0.21 -> 0.09
		{
			name = "BladeCore5",
			size = Vector3.new(0.06, 0.18, 0.24),
			offset = CFrame.new(0, 0, -5.48),
			color = POLISHED_BRONZE,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "BladeEdge5Top",
			class = "WedgePart",
			size = Vector3.new(0.04, 0.12, 0.24),
			offset = CFrame.new(0, 0.15, -5.48),
			color = HONED_EDGE,
			material = M.Metal,
			reflectance = 0.2,
		},
		{
			name = "BladeEdge5Bottom",
			class = "WedgePart",
			size = Vector3.new(0.04, 0.12, 0.24),
			offset = CFrame.new(0, -0.15, -5.48) * CFrame.Angles(0, 0, pi),
			color = HONED_EDGE,
			material = M.Metal,
			reflectance = 0.2,
		},
		-- Segment 6: tip, half-width 0.09 -> 0 at z -5.80
		{
			name = "BladeTipTop",
			class = "WedgePart",
			size = Vector3.new(0.06, 0.09, 0.2),
			offset = CFrame.new(0, 0.045, -5.7),
			color = POLISHED_BRONZE,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "BladeTipBottom",
			class = "WedgePart",
			size = Vector3.new(0.06, 0.09, 0.2),
			offset = CFrame.new(0, -0.045, -5.7) * CFrame.Angles(0, 0, pi),
			color = POLISHED_BRONZE,
			material = M.Metal,
			reflectance = 0.1,
		},

		-- Midrib: diamond section, square blocks turned 45 degrees about Z
		{
			name = "MidribRear",
			size = Vector3.new(0.08, 0.08, 0.66),
			offset = CFrame.new(0, 0, -4.81) * CFrame.Angles(0, 0, rad(45)),
			color = MIDRIB_BRONZE,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "MidribFront",
			size = Vector3.new(0.06, 0.06, 0.5),
			offset = CFrame.new(0, 0, -5.39) * CFrame.Angles(0, 0, rad(45)),
			color = MIDRIB_BRONZE,
			material = M.Metal,
			reflectance = 0.1,
		},
	},
})
