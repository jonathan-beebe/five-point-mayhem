-- Knight Sword: mid-15th-century European hand-and-a-half longsword (Oakeshott XVIIIa blade, style 1 cross, Type K wheel pommel).

local WeaponModel = require(script.Parent.Parent.systems.WeaponModel)

local rgb = Color3.fromRGB
local M = Enum.Material
local CYLINDER_Z = WeaponModel.CYLINDER_Z
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball

-- Mirrors local Y (and X) and keeps Z: turns a top taper wedge into its bottom twin.
local FLIP = CFrame.Angles(0, 0, math.pi)

local EDGE_STEEL = rgb(200, 205, 215)
local FLAT_STEEL = rgb(176, 181, 190)
local FULLER_STEEL = rgb(135, 140, 150)
local HILT_STEEL = rgb(108, 111, 118)
local PEEN_STEEL = rgb(190, 195, 205)
local GRIP_LEATHER = rgb(78, 50, 32)
local RISER_LEATHER = rgb(58, 37, 24)
local CHAPPE_LEATHER = rgb(96, 44, 28)

-- Blade stations along Z: root -0.70 (inside the guard), fuller -0.84 to -2.90, point section -3.80 to tip -4.60.
-- Edges face +Y/-Y, flats face +X/-X. Taper wedges are full height at the root and thin toward the tip.
-- Held upright: the blade stands up from the fist and the -Y edge leads the downward swing.

return WeaponModel.define({
	hold = "upright",
	handle = {
		size = Vector3.new(0.24, 0.24, 1.0),
		color = GRIP_LEATHER,
		material = M.Leather,
		transparency = 1,
	},
	pieces = {
		-- Blade: edge layer, thickness 0.06; width 0.46 at the root to 0.30 at -3.80
		{
			name = "BladeEdgeCore",
			size = Vector3.new(0.06, 0.30, 3.10),
			offset = CFrame.new(0, 0, -2.25),
			color = EDGE_STEEL,
			material = M.Metal,
			reflectance = 0.15,
		},
		{
			name = "BladeEdgeTaperTop",
			class = "WedgePart",
			size = Vector3.new(0.06, 0.08, 3.10),
			offset = CFrame.new(0, 0.19, -2.25),
			color = EDGE_STEEL,
			material = M.Metal,
			reflectance = 0.15,
		},
		{
			name = "BladeEdgeTaperBottom",
			class = "WedgePart",
			size = Vector3.new(0.06, 0.08, 3.10),
			offset = CFrame.new(0, -0.19, -2.25) * FLIP,
			color = EDGE_STEEL,
			material = M.Metal,
			reflectance = 0.15,
		},
		{
			name = "BladeEdgeTipTop",
			class = "WedgePart",
			size = Vector3.new(0.06, 0.15, 0.80),
			offset = CFrame.new(0, 0.075, -4.20),
			color = EDGE_STEEL,
			material = M.Metal,
			reflectance = 0.15,
		},
		{
			name = "BladeEdgeTipBottom",
			class = "WedgePart",
			size = Vector3.new(0.06, 0.15, 0.80),
			offset = CFrame.new(0, -0.075, -4.20) * FLIP,
			color = EDGE_STEEL,
			material = M.Metal,
			reflectance = 0.15,
		},

		-- Blade: center flats, thickness 0.11, inset 0.07 from each edge to leave the edge bevel
		{
			name = "BladeRicasso",
			size = Vector3.new(0.11, 0.16, 0.14),
			offset = CFrame.new(0, 0, -0.77),
			color = FLAT_STEEL,
			material = M.Metal,
			reflectance = 0.10,
		},
		{
			name = "BladeFlatUpper",
			size = Vector3.new(0.11, 0.05, 2.06),
			offset = CFrame.new(0, 0.055, -1.87),
			color = FLAT_STEEL,
			material = M.Metal,
			reflectance = 0.10,
		},
		{
			name = "BladeFlatLower",
			size = Vector3.new(0.11, 0.05, 2.06),
			offset = CFrame.new(0, -0.055, -1.87),
			color = FLAT_STEEL,
			material = M.Metal,
			reflectance = 0.10,
		},
		{
			name = "BladeFlatSolid",
			size = Vector3.new(0.11, 0.16, 0.90),
			offset = CFrame.new(0, 0, -3.35),
			color = FLAT_STEEL,
			material = M.Metal,
			reflectance = 0.10,
		},
		{
			name = "BladeFlatTaperTop",
			class = "WedgePart",
			size = Vector3.new(0.11, 0.08, 3.10),
			offset = CFrame.new(0, 0.12, -2.25),
			color = FLAT_STEEL,
			material = M.Metal,
			reflectance = 0.10,
		},
		{
			name = "BladeFlatTaperBottom",
			class = "WedgePart",
			size = Vector3.new(0.11, 0.08, 3.10),
			offset = CFrame.new(0, -0.12, -2.25) * FLIP,
			color = FLAT_STEEL,
			material = M.Metal,
			reflectance = 0.10,
		},
		{
			-- Ridge leading into the point: z -3.80 to -4.35
			name = "BladeFlatTipTop",
			class = "WedgePart",
			size = Vector3.new(0.11, 0.08, 0.55),
			offset = CFrame.new(0, 0.04, -4.075),
			color = FLAT_STEEL,
			material = M.Metal,
			reflectance = 0.10,
		},
		{
			name = "BladeFlatTipBottom",
			class = "WedgePart",
			size = Vector3.new(0.11, 0.08, 0.55),
			offset = CFrame.new(0, -0.04, -4.075) * FLIP,
			color = FLAT_STEEL,
			material = M.Metal,
			reflectance = 0.10,
		},

		-- Blade: fuller floor, recessed 0.015 per side below the flats
		{
			name = "FullerFloor",
			size = Vector3.new(0.08, 0.07, 2.06),
			offset = CFrame.new(0, 0, -1.87),
			color = FULLER_STEEL,
			material = M.Metal,
			reflectance = 0.05,
		},

		-- Chappe: leather rain guard, z -0.69 to -0.98
		{
			name = "ChappeBlock",
			size = Vector3.new(0.15, 0.30, 0.15),
			offset = CFrame.new(0, 0, -0.765),
			color = CHAPPE_LEATHER,
			material = M.Leather,
		},
		{
			name = "ChappePointTop",
			class = "WedgePart",
			size = Vector3.new(0.15, 0.15, 0.14),
			offset = CFrame.new(0, 0.075, -0.91),
			color = CHAPPE_LEATHER,
			material = M.Leather,
		},
		{
			name = "ChappePointBottom",
			class = "WedgePart",
			size = Vector3.new(0.15, 0.15, 0.14),
			offset = CFrame.new(0, -0.075, -0.91) * FLIP,
			color = CHAPPE_LEATHER,
			material = M.Leather,
		},

		-- Cross-guard: runs along Y in the blade plane, z -0.565 to -0.705
		{
			name = "GuardBlock",
			size = Vector3.new(0.16, 0.50, 0.14),
			offset = CFrame.new(0, 0, -0.635),
			color = HILT_STEEL,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "QuillonRight",
			size = Vector3.new(0.12, 0.24, 0.11),
			offset = CFrame.new(0, 0.36, -0.635),
			color = HILT_STEEL,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "QuillonLeft",
			size = Vector3.new(0.12, 0.24, 0.11),
			offset = CFrame.new(0, -0.36, -0.635),
			color = HILT_STEEL,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "QuillonTerminalRight",
			size = Vector3.new(0.15, 0.06, 0.14),
			offset = CFrame.new(0, 0.49, -0.635),
			color = HILT_STEEL,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "QuillonTerminalLeft",
			size = Vector3.new(0.15, 0.06, 0.14),
			offset = CFrame.new(0, -0.49, -0.635),
			color = HILT_STEEL,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "QuillonKnobRight",
			shape = BALL,
			size = Vector3.new(0.13, 0.13, 0.13),
			offset = CFrame.new(0, 0.55, -0.635),
			color = HILT_STEEL,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "QuillonKnobLeft",
			shape = BALL,
			size = Vector3.new(0.13, 0.13, 0.13),
			offset = CFrame.new(0, -0.55, -0.635),
			color = HILT_STEEL,
			material = M.Metal,
			reflectance = 0.05,
		},

		-- Grip: leather over cord, z -0.58 to 0.53, central swell and three risers
		{
			name = "GripCore",
			shape = CYL,
			size = Vector3.new(1.11, 0.24, 0.24),
			offset = CFrame.new(0, 0, -0.025) * CYLINDER_Z,
			color = GRIP_LEATHER,
			material = M.Leather,
		},
		{
			name = "GripSwell",
			shape = CYL,
			size = Vector3.new(0.54, 0.26, 0.26),
			offset = CFrame.new(0, 0, -0.03) * CYLINDER_Z,
			color = GRIP_LEATHER,
			material = M.Leather,
		},
		{
			name = "RiserFront",
			shape = CYL,
			size = Vector3.new(0.035, 0.28, 0.28),
			offset = CFrame.new(0, 0, -0.40) * CYLINDER_Z,
			color = RISER_LEATHER,
			material = M.Leather,
		},
		{
			name = "RiserMid",
			shape = CYL,
			size = Vector3.new(0.035, 0.28, 0.28),
			offset = CFrame.new(0, 0, -0.03) * CYLINDER_Z,
			color = RISER_LEATHER,
			material = M.Leather,
		},
		{
			name = "RiserRear",
			shape = CYL,
			size = Vector3.new(0.035, 0.28, 0.28),
			offset = CFrame.new(0, 0, 0.34) * CYLINDER_Z,
			color = RISER_LEATHER,
			material = M.Leather,
		},
		{
			name = "FerruleGuard",
			shape = CYL,
			size = Vector3.new(0.06, 0.28, 0.28),
			offset = CFrame.new(0, 0, -0.535) * CYLINDER_Z,
			color = HILT_STEEL,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			-- z 0.475 to 0.535: overhangs the grip end at 0.53 so the two end faces are not coplanar
			name = "FerrulePommel",
			shape = CYL,
			size = Vector3.new(0.06, 0.28, 0.28),
			offset = CFrame.new(0, 0, 0.505) * CYLINDER_Z,
			color = HILT_STEEL,
			material = M.Metal,
			reflectance = 0.05,
		},

		-- Wheel pommel: discs face +X/-X, parallel to the blade flats; center z 0.78
		{
			name = "PommelNeck",
			shape = CYL,
			size = Vector3.new(0.12, 0.18, 0.18),
			offset = CFrame.new(0, 0, 0.58) * CYLINDER_Z,
			color = HILT_STEEL,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "PommelDisc",
			shape = CYL,
			size = Vector3.new(0.14, 0.42, 0.42),
			offset = CFrame.new(0, 0, 0.78),
			color = HILT_STEEL,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "PommelBevelStep",
			shape = CYL,
			size = Vector3.new(0.20, 0.32, 0.32),
			offset = CFrame.new(0, 0, 0.78),
			color = HILT_STEEL,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "PommelBoss",
			shape = CYL,
			size = Vector3.new(0.26, 0.16, 0.16),
			offset = CFrame.new(0, 0, 0.78),
			color = HILT_STEEL,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			-- Peened tang end: dome up to z 1.035
			name = "PeenButton",
			shape = BALL,
			size = Vector3.new(0.10, 0.10, 0.10),
			offset = CFrame.new(0, 0, 0.985),
			color = PEEN_STEEL,
			material = M.Metal,
			reflectance = 0.10,
		},
	},
})
