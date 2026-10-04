-- Sea Trident: cast-bronze Greco-Roman tunny-fishing trident, socketed head pinned to an ash shaft.

local WeaponModel = require(script.Parent.Parent.systems.WeaponModel)

local rgb = Color3.fromRGB
local M = Enum.Material
local CYLINDER_Z = WeaponModel.CYLINDER_Z
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball

local VERDIGRIS = rgb(46, 148, 136)
local HONED_BRONZE = rgb(201, 158, 96)
local POLISHED_BRONZE = rgb(176, 132, 72)
local DARK_BRONZE = rgb(110, 82, 50)
local DRIFTWOOD_ASH = rgb(118, 98, 76)
local WORN_LEATHER = rgb(66, 44, 30)
local TARRED_CORD = rgb(54, 44, 32)
local BLEACHED_HEMP = rgb(150, 132, 104)

local function deg(a: number): number
	return math.rad(a)
end

-- Half-arrowhead wedges lying flat in the XZ plane. EDGE_POS puts the straight edge on +X,
-- EDGE_NEG on -X; the sharp corner sits at the front (-Z) end of the straight edge.
local EDGE_POS = CFrame.Angles(0, 0, deg(90))
local EDGE_NEG = CFrame.Angles(0, 0, deg(-90))

return WeaponModel.define({
	-- Roll about the shaft: the tines (built spread along X) stand in the vertical YZ plane.
	rotation = CFrame.Angles(0, 0, -math.pi / 2),
	handle = {
		size = Vector3.new(0.25, 0.25, 1.2),
		color = WORN_LEATHER,
		material = M.Leather,
		transparency = 1,
	},
	pieces = {
		-- Butt hardware
		{
			name = "ButtFerrule",
			shape = CYL,
			size = Vector3.new(0.3, 0.27, 0.27),
			offset = CFrame.new(0, 0, 1.3) * CYLINDER_Z,
			color = DARK_BRONZE,
			material = M.Metal,
		},
		{
			name = "ButtCap",
			shape = BALL,
			size = Vector3.new(0.27, 0.27, 0.27),
			offset = CFrame.new(0, 0, 1.45),
			color = DARK_BRONZE,
			material = M.Metal,
		},
		{
			name = "ButtLip",
			shape = CYL,
			size = Vector3.new(0.05, 0.3, 0.3),
			offset = CFrame.new(0, 0, 1.15) * CYLINDER_Z,
			color = POLISHED_BRONZE,
			material = M.Metal,
			reflectance = 0.1,
		},

		-- Shaft
		{
			name = "Shaft",
			shape = CYL,
			size = Vector3.new(6.05, 0.22, 0.22),
			offset = CFrame.new(0, 0, -1.625) * CYLINDER_Z,
			color = DRIFTWOOD_ASH,
			material = M.Wood,
		},
		{
			name = "RepairBand",
			shape = CYL,
			size = Vector3.new(0.08, 0.245, 0.245),
			offset = CFrame.new(0, 0, -2) * CYLINDER_Z,
			color = DARK_BRONZE,
			material = M.Metal,
		},

		-- Grip: leather sleeve bound with tarred cord
		{
			name = "GripSleeve",
			shape = CYL,
			size = Vector3.new(1.3, 0.25, 0.25),
			offset = CYLINDER_Z,
			color = WORN_LEATHER,
			material = M.Leather,
		},
		{
			name = "GripTurn1",
			shape = CYL,
			size = Vector3.new(0.05, 0.27, 0.27),
			offset = CFrame.new(0, 0, -0.6) * CYLINDER_Z,
			color = TARRED_CORD,
			material = M.Fabric,
		},
		{
			name = "GripTurn2",
			shape = CYL,
			size = Vector3.new(0.05, 0.27, 0.27),
			offset = CFrame.new(0, 0, -0.45) * CYLINDER_Z,
			color = TARRED_CORD,
			material = M.Fabric,
		},
		{
			name = "GripTurn3",
			shape = CYL,
			size = Vector3.new(0.05, 0.27, 0.27),
			offset = CFrame.new(0, 0, -0.3) * CYLINDER_Z,
			color = TARRED_CORD,
			material = M.Fabric,
		},
		{
			name = "GripTurn4",
			shape = CYL,
			size = Vector3.new(0.05, 0.27, 0.27),
			offset = CFrame.new(0, 0, -0.15) * CYLINDER_Z,
			color = TARRED_CORD,
			material = M.Fabric,
		},
		{
			name = "GripTurn5",
			shape = CYL,
			size = Vector3.new(0.05, 0.27, 0.27),
			offset = CYLINDER_Z,
			color = TARRED_CORD,
			material = M.Fabric,
		},
		{
			name = "GripTurn6",
			shape = CYL,
			size = Vector3.new(0.05, 0.27, 0.27),
			offset = CFrame.new(0, 0, 0.15) * CYLINDER_Z,
			color = TARRED_CORD,
			material = M.Fabric,
		},
		{
			name = "GripTurn7",
			shape = CYL,
			size = Vector3.new(0.05, 0.27, 0.27),
			offset = CFrame.new(0, 0, 0.3) * CYLINDER_Z,
			color = TARRED_CORD,
			material = M.Fabric,
		},
		{
			name = "GripTurn8",
			shape = CYL,
			size = Vector3.new(0.05, 0.27, 0.27),
			offset = CFrame.new(0, 0, 0.45) * CYLINDER_Z,
			color = TARRED_CORD,
			material = M.Fabric,
		},
		{
			name = "GripTurn9",
			shape = CYL,
			size = Vector3.new(0.05, 0.27, 0.27),
			offset = CFrame.new(0, 0, 0.6) * CYLINDER_Z,
			color = TARRED_CORD,
			material = M.Fabric,
		},
		{
			name = "GripKnotFront",
			shape = CYL,
			size = Vector3.new(0.08, 0.285, 0.285),
			offset = CFrame.new(0, 0, -0.68) * CYLINDER_Z,
			color = TARRED_CORD,
			material = M.Fabric,
		},
		{
			name = "GripKnotRear",
			shape = CYL,
			size = Vector3.new(0.08, 0.285, 0.285),
			offset = CFrame.new(0, 0, 0.68) * CYLINDER_Z,
			color = TARRED_CORD,
			material = M.Fabric,
		},

		-- Upper whipping below the socket
		{
			name = "Whipping",
			shape = CYL,
			size = Vector3.new(0.3, 0.25, 0.25),
			offset = CFrame.new(0, 0, -4.4) * CYLINDER_Z,
			color = TARRED_CORD,
			material = M.Fabric,
		},
		{
			name = "WhipTurn1",
			shape = CYL,
			size = Vector3.new(0.04, 0.265, 0.265),
			offset = CFrame.new(0, 0, -4.28) * CYLINDER_Z,
			color = BLEACHED_HEMP,
			material = M.Fabric,
		},
		{
			name = "WhipTurn2",
			shape = CYL,
			size = Vector3.new(0.04, 0.265, 0.265),
			offset = CFrame.new(0, 0, -4.4) * CYLINDER_Z,
			color = BLEACHED_HEMP,
			material = M.Fabric,
		},
		{
			name = "WhipTurn3",
			shape = CYL,
			size = Vector3.new(0.04, 0.265, 0.265),
			offset = CFrame.new(0, 0, -4.52) * CYLINDER_Z,
			color = BLEACHED_HEMP,
			material = M.Fabric,
		},

		-- Socket and neck
		{
			name = "Socket",
			shape = CYL,
			size = Vector3.new(0.5, 0.3, 0.3),
			offset = CFrame.new(0, 0, -4.85) * CYLINDER_Z,
			color = VERDIGRIS,
			material = M.CorrodedMetal,
		},
		{
			name = "SocketLip",
			shape = CYL,
			size = Vector3.new(0.06, 0.34, 0.34),
			offset = CFrame.new(0, 0, -4.62) * CYLINDER_Z,
			color = POLISHED_BRONZE,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "SocketFrontRing",
			shape = CYL,
			size = Vector3.new(0.05, 0.33, 0.33),
			offset = CFrame.new(0, 0, -5.08) * CYLINDER_Z,
			color = POLISHED_BRONZE,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "RivetPin",
			shape = CYL,
			size = Vector3.new(0.36, 0.06, 0.06),
			offset = CFrame.new(0, 0, -4.85),
			color = POLISHED_BRONZE,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "RivetHeadR",
			shape = BALL,
			size = Vector3.new(0.08, 0.08, 0.08),
			offset = CFrame.new(0.17, 0, -4.85),
			color = POLISHED_BRONZE,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "RivetHeadL",
			shape = BALL,
			size = Vector3.new(0.08, 0.08, 0.08),
			offset = CFrame.new(-0.17, 0, -4.85),
			color = POLISHED_BRONZE,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "Neck",
			shape = CYL,
			size = Vector3.new(0.22, 0.22, 0.22),
			offset = CFrame.new(0, 0, -5.2) * CYLINDER_Z,
			color = VERDIGRIS,
			material = M.CorrodedMetal,
		},

		-- Yoke: center block, boss, and two arms sweeping forward to the elbows
		{
			name = "YokeCenter",
			size = Vector3.new(0.62, 0.16, 0.22),
			offset = CFrame.new(0, 0, -5.4),
			color = VERDIGRIS,
			material = M.CorrodedMetal,
		},
		{
			name = "YokeBoss",
			shape = BALL,
			size = Vector3.new(0.24, 0.24, 0.24),
			offset = CFrame.new(0, 0, -5.4),
			color = POLISHED_BRONZE,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "YokeArmR",
			size = Vector3.new(0.45, 0.15, 0.2),
			offset = CFrame.new(0.475, 0, -5.5125) * CFrame.Angles(0, deg(30), 0),
			color = VERDIGRIS,
			material = M.CorrodedMetal,
		},
		{
			name = "YokeArmL",
			size = Vector3.new(0.45, 0.15, 0.2),
			offset = CFrame.new(-0.475, 0, -5.5125) * CFrame.Angles(0, deg(-30), 0),
			color = VERDIGRIS,
			material = M.CorrodedMetal,
		},
		{
			name = "ElbowR",
			shape = BALL,
			size = Vector3.new(0.2, 0.2, 0.2),
			offset = CFrame.new(0.67, 0, -5.62),
			color = VERDIGRIS,
			material = M.CorrodedMetal,
		},
		{
			name = "ElbowL",
			shape = BALL,
			size = Vector3.new(0.2, 0.2, 0.2),
			offset = CFrame.new(-0.67, 0, -5.62),
			color = VERDIGRIS,
			material = M.CorrodedMetal,
		},

		-- Outer tines: leaf points of two half-wedges meeting on the tine centerline
		{
			name = "OuterTineR",
			shape = CYL,
			size = Vector3.new(0.62, 0.12, 0.12),
			offset = CFrame.new(0.67, 0, -5.93) * CYLINDER_Z,
			color = VERDIGRIS,
			material = M.CorrodedMetal,
		},
		{
			name = "OuterTineL",
			shape = CYL,
			size = Vector3.new(0.62, 0.12, 0.12),
			offset = CFrame.new(-0.67, 0, -5.93) * CYLINDER_Z,
			color = VERDIGRIS,
			material = M.CorrodedMetal,
		},
		{
			name = "OuterPointRIn",
			class = "WedgePart",
			size = Vector3.new(0.07, 0.08, 0.36),
			offset = CFrame.new(0.63, 0, -6.4) * EDGE_POS,
			color = HONED_BRONZE,
			material = M.Metal,
			reflectance = 0.15,
		},
		{
			name = "OuterPointROut",
			class = "WedgePart",
			size = Vector3.new(0.07, 0.08, 0.36),
			offset = CFrame.new(0.71, 0, -6.4) * EDGE_NEG,
			color = HONED_BRONZE,
			material = M.Metal,
			reflectance = 0.15,
		},
		{
			name = "OuterPointLOut",
			class = "WedgePart",
			size = Vector3.new(0.07, 0.08, 0.36),
			offset = CFrame.new(-0.71, 0, -6.4) * EDGE_POS,
			color = HONED_BRONZE,
			material = M.Metal,
			reflectance = 0.15,
		},
		{
			name = "OuterPointLIn",
			class = "WedgePart",
			size = Vector3.new(0.07, 0.08, 0.36),
			offset = CFrame.new(-0.63, 0, -6.4) * EDGE_NEG,
			color = HONED_BRONZE,
			material = M.Metal,
			reflectance = 0.15,
		},
		{
			name = "OuterMidribR",
			size = Vector3.new(0.025, 0.085, 0.28),
			offset = CFrame.new(0.67, 0, -6.37),
			color = HONED_BRONZE,
			material = M.Metal,
			reflectance = 0.15,
		},
		{
			name = "OuterMidribL",
			size = Vector3.new(0.025, 0.085, 0.28),
			offset = CFrame.new(-0.67, 0, -6.37),
			color = HONED_BRONZE,
			material = M.Metal,
			reflectance = 0.15,
		},
		-- Barbs: straight edge against the tine, sloped face forward, hook corner at the back-outer end
		{
			name = "OuterBarbR",
			class = "WedgePart",
			size = Vector3.new(0.05, 0.1, 0.22),
			offset = CFrame.new(0.77, 0, -6.12) * EDGE_NEG,
			color = VERDIGRIS,
			material = M.CorrodedMetal,
		},
		{
			name = "OuterBarbL",
			class = "WedgePart",
			size = Vector3.new(0.05, 0.1, 0.22),
			offset = CFrame.new(-0.77, 0, -6.12) * EDGE_POS,
			color = VERDIGRIS,
			material = M.CorrodedMetal,
		},

		-- Center tine: longer, with a broader point and barbs on both sides
		{
			name = "CenterTine",
			shape = CYL,
			size = Vector3.new(0.85, 0.14, 0.14),
			offset = CFrame.new(0, 0, -5.875) * CYLINDER_Z,
			color = VERDIGRIS,
			material = M.CorrodedMetal,
		},
		{
			name = "CenterPointL",
			class = "WedgePart",
			size = Vector3.new(0.08, 0.11, 0.45),
			offset = CFrame.new(-0.055, 0, -6.475) * EDGE_POS,
			color = HONED_BRONZE,
			material = M.Metal,
			reflectance = 0.15,
		},
		{
			name = "CenterPointR",
			class = "WedgePart",
			size = Vector3.new(0.08, 0.11, 0.45),
			offset = CFrame.new(0.055, 0, -6.475) * EDGE_NEG,
			color = HONED_BRONZE,
			material = M.Metal,
			reflectance = 0.15,
		},
		{
			name = "CenterMidrib",
			size = Vector3.new(0.03, 0.095, 0.36),
			offset = CFrame.new(0, 0, -6.45),
			color = HONED_BRONZE,
			material = M.Metal,
			reflectance = 0.15,
		},
		{
			name = "CenterBarbR",
			class = "WedgePart",
			size = Vector3.new(0.05, 0.1, 0.22),
			offset = CFrame.new(0.115, 0, -6.15) * EDGE_NEG,
			color = VERDIGRIS,
			material = M.CorrodedMetal,
		},
		{
			name = "CenterBarbL",
			class = "WedgePart",
			size = Vector3.new(0.05, 0.1, 0.22),
			offset = CFrame.new(-0.115, 0, -6.15) * EDGE_POS,
			color = VERDIGRIS,
			material = M.CorrodedMetal,
		},
	},
})
