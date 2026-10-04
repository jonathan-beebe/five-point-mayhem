-- Fire Staff: hand-cut ash walking staff with a forged-iron claw head gripping a hand-blown amber glass orb.

local WeaponModel = require(script.Parent.Parent.systems.WeaponModel)

local rgb = Color3.fromRGB
local M = Enum.Material
local CYL_Y = WeaponModel.CYLINDER_Y
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball
local rad = math.rad

local weatheredAsh = rgb(112, 82, 58)
local knotWood = rgb(78, 55, 38)
local endGrain = rgb(158, 126, 92)
local charredWood = rgb(38, 29, 24)
local oxbloodLeather = rgb(92, 50, 36)
local darkLeather = rgb(64, 38, 28)
local rawhide = rgb(168, 140, 100)
local bone = rgb(214, 200, 170)
local blackenedIron = rgb(48, 46, 44)
local forgedIron = rgb(62, 58, 54)
local agedBrass = rgb(152, 118, 60)
local fireGlass = rgb(255, 120, 30)
local ember = rgb(255, 110, 20)
local whiteHot = rgb(255, 205, 120)

-- Shaft segment frames: each segment leans a few degrees so the staff reads as cut wood.
local MID1 = CFrame.new(0, 1.30, 0) * CFrame.Angles(rad(2), 0, 0)
local MID2 = CFrame.new(0, 2.625, 0) * CFrame.Angles(0, 0, rad(-2.5))

-- Branch stub: points out to -X and slightly up; the sawn face sits 0.003 proud of its end.
local STUB = MID1 * CFrame.new(-0.17, 0.25, 0) * CFrame.Angles(0, 0, rad(-35))

local function blackIron(name: string, shape: Enum.PartType, size: Vector3, offset: CFrame)
	return {
		name = name,
		shape = shape,
		size = size,
		offset = offset,
		color = blackenedIron,
		material = M.Metal,
		reflectance = 0.05,
	}
end

local function brass(name: string, shape: Enum.PartType, size: Vector3, offset: CFrame)
	return {
		name = name,
		shape = shape,
		size = size,
		offset = offset,
		color = agedBrass,
		material = M.Metal,
		reflectance = 0.1,
	}
end

local function wrapRidge(index: number, y: number)
	return {
		name = "wrap_ridge_" .. index,
		shape = CYL,
		size = Vector3.new(0.05, 0.365, 0.365),
		offset = CFrame.new(0, y, 0) * CFrame.Angles(0, 0, rad(8)) * CYL_Y,
		color = darkLeather,
		material = M.Leather,
	}
end

local pieces = {
	-- Ferrule
	blackIron("ferrule_tip", BALL, Vector3.new(0.30, 0.30, 0.30), CFrame.new(0, -1.53, 0)),
	blackIron("ferrule", CYL, Vector3.new(0.22, 0.34, 0.34), CFrame.new(0, -1.42, 0) * CYL_Y),
	brass("ferrule_band", CYL, Vector3.new(0.05, 0.37, 0.37), CFrame.new(0, -1.30, 0) * CYL_Y),
	brass("ferrule_rivet_R", BALL, Vector3.new(0.05, 0.05, 0.05), CFrame.new(0.17, -1.42, 0)),
	brass("ferrule_rivet_L", BALL, Vector3.new(0.05, 0.05, 0.05), CFrame.new(-0.17, -1.42, 0)),

	-- Shaft core
	{
		name = "shaft_lower",
		shape = CYL,
		size = Vector3.new(2.06, 0.30, 0.30),
		offset = CFrame.new(0, -0.33, 0) * CYL_Y,
		color = weatheredAsh,
		material = M.Wood,
	},
	{
		name = "joint_low",
		shape = BALL,
		size = Vector3.new(0.36, 0.36, 0.36),
		offset = CFrame.new(0, 0.74, 0),
		color = weatheredAsh,
		material = M.Wood,
	},
	{
		name = "shaft_mid1",
		shape = CYL,
		size = Vector3.new(1.20, 0.30, 0.30),
		offset = MID1 * CYL_Y,
		color = weatheredAsh,
		material = M.Wood,
	},
	{
		name = "joint_mid",
		shape = BALL,
		size = Vector3.new(0.36, 0.36, 0.36),
		offset = CFrame.new(0, 1.90, 0),
		color = knotWood,
		material = M.Wood,
	},
	{
		name = "shaft_mid2",
		shape = CYL,
		size = Vector3.new(1.45, 0.29, 0.29),
		offset = MID2 * CYL_Y,
		color = weatheredAsh,
		material = M.Wood,
	},

	-- Shaft details
	{
		name = "knot_1",
		shape = BALL,
		size = Vector3.new(0.14, 0.14, 0.14),
		offset = MID1 * CFrame.new(0.115, 0.05, 0.05),
		color = knotWood,
		material = M.Wood,
	},
	{
		name = "knot_2",
		shape = BALL,
		size = Vector3.new(0.14, 0.14, 0.14),
		offset = MID2 * CFrame.new(-0.115, -0.15, 0.05),
		color = knotWood,
		material = M.Wood,
	},
	{
		name = "knot_3",
		shape = BALL,
		size = Vector3.new(0.13, 0.13, 0.13),
		offset = MID2 * CFrame.new(0.03, 0.30, -0.12),
		color = knotWood,
		material = M.Wood,
	},
	{
		name = "branch_stub",
		shape = CYL,
		size = Vector3.new(0.18, 0.10, 0.10),
		offset = STUB,
		color = weatheredAsh,
		material = M.Wood,
	},
	{
		name = "branch_stub_end",
		shape = CYL,
		size = Vector3.new(0.012, 0.09, 0.09),
		offset = STUB * CFrame.new(-0.093, 0, 0),
		color = endGrain,
		material = M.Wood,
	},
	blackIron(
		"iron_band_mid",
		CYL,
		Vector3.new(0.06, 0.33, 0.33),
		MID1 * CFrame.new(0, -0.30, 0) * CYL_Y
	),
	brass(
		"brass_wire_1",
		CYL,
		Vector3.new(0.025, 0.315, 0.315),
		MID2 * CFrame.new(0, -0.40, 0) * CYL_Y
	),
	brass(
		"brass_wire_2",
		CYL,
		Vector3.new(0.025, 0.315, 0.315),
		MID2 * CFrame.new(0, -0.34, 0) * CYL_Y
	),
	{
		name = "char_band",
		shape = CYL,
		size = Vector3.new(0.20, 0.31, 0.31),
		offset = MID2 * CFrame.new(0, 0.50, 0) * CYL_Y,
		color = charredWood,
		material = M.Wood,
	},

	-- Grip: spiral-wrapped oxblood leather between brass rings, rawhide thong with a bone bead
	{
		name = "grip_wrap",
		shape = CYL,
		size = Vector3.new(1.20, 0.34, 0.34),
		offset = CYL_Y,
		color = oxbloodLeather,
		material = M.Leather,
	},
	wrapRidge(1, -0.45),
	wrapRidge(2, -0.225),
	wrapRidge(3, 0),
	wrapRidge(4, 0.225),
	wrapRidge(5, 0.45),
	brass("grip_ring_top", CYL, Vector3.new(0.06, 0.38, 0.38), CFrame.new(0, 0.62, 0) * CYL_Y),
	brass("grip_ring_bottom", CYL, Vector3.new(0.06, 0.38, 0.38), CFrame.new(0, -0.62, 0) * CYL_Y),
	{
		name = "lanyard_thong",
		size = Vector3.new(0.035, 0.55, 0.035),
		offset = CFrame.new(0.19, 0.38, 0) * CFrame.Angles(0, 0, rad(6)),
		color = rawhide,
		material = M.Leather,
	},
	{
		name = "lanyard_bead",
		shape = BALL,
		size = Vector3.new(0.09, 0.09, 0.09),
		offset = CFrame.new(0.222, 0.08, 0),
		color = bone,
		material = M.SmoothPlastic,
	},

	-- Neck collar and claw socket
	blackIron("collar", CYL, Vector3.new(0.30, 0.38, 0.38), CFrame.new(0, 3.40, 0) * CYL_Y),
	brass("collar_rim_low", CYL, Vector3.new(0.04, 0.42, 0.42), CFrame.new(0, 3.28, 0) * CYL_Y),
	brass("collar_rim_high", CYL, Vector3.new(0.04, 0.42, 0.42), CFrame.new(0, 3.51, 0) * CYL_Y),
	brass("collar_rivet_px", BALL, Vector3.new(0.06, 0.06, 0.06), CFrame.new(0.19, 3.40, 0)),
	brass("collar_rivet_nx", BALL, Vector3.new(0.06, 0.06, 0.06), CFrame.new(-0.19, 3.40, 0)),
	brass("collar_rivet_pz", BALL, Vector3.new(0.06, 0.06, 0.06), CFrame.new(0, 3.40, 0.19)),
	brass("collar_rivet_nz", BALL, Vector3.new(0.06, 0.06, 0.06), CFrame.new(0, 3.40, -0.19)),
	blackIron("claw_socket", CYL, Vector3.new(0.13, 0.50, 0.50), CFrame.new(0, 3.605, 0) * CYL_Y),
	brass("orb_seat", CYL, Vector3.new(0.11, 0.36, 0.36), CFrame.new(0, 3.715, 0) * CYL_Y),
}

-- Claws: four forged-iron prongs with a knuckle bend, gripping the orb at its equator.
-- The lower segment is 0.44 long so its foot sinks 0.04 into the socket (top end unchanged).
for _, p in { 45, 135, 225, 315 } do
	local az = CFrame.Angles(0, rad(p), 0)
	local prefix = "claw_" .. p .. "_"
	local function iron(name: string, shape: Enum.PartType, size: Vector3, offset: CFrame)
		table.insert(pieces, {
			name = prefix .. name,
			shape = shape,
			size = size,
			offset = az * offset,
			color = forgedIron,
			material = M.CorrodedMetal,
		})
	end
	iron(
		"lower",
		Enum.PartType.Block,
		Vector3.new(0.07, 0.44, 0.07),
		CFrame.new(0.296, 3.827, 0) * CFrame.Angles(0, 0, rad(-25.9))
	)
	iron("knuckle", BALL, Vector3.new(0.085, 0.085, 0.085), CFrame.new(0.39, 4.02, 0))
	iron(
		"upper",
		Enum.PartType.Block,
		Vector3.new(0.06, 0.32, 0.06),
		CFrame.new(0.36, 4.17, 0) * CFrame.Angles(0, 0, rad(11.3))
	)
	iron("tip", BALL, Vector3.new(0.065, 0.065, 0.065), CFrame.new(0.33, 4.32, 0))
end

-- Fire orb: translucent amber glass with a glowing ember and white-hot heart sealed inside
table.insert(pieces, {
	name = "orb_glass",
	shape = BALL,
	size = Vector3.new(0.70, 0.70, 0.70),
	offset = CFrame.new(0, 4.08, 0),
	color = fireGlass,
	material = M.Glass,
	transparency = 0.5,
	reflectance = 0.15,
})
table.insert(pieces, {
	name = "orb_ember",
	shape = BALL,
	size = Vector3.new(0.40, 0.40, 0.40),
	offset = CFrame.new(0, 4.08, 0),
	color = ember,
	material = M.Neon,
	transparency = 0.25,
})
table.insert(pieces, {
	name = "orb_heart",
	shape = BALL,
	size = Vector3.new(0.20, 0.20, 0.20),
	offset = CFrame.new(0, 4.08, 0),
	color = whiteHot,
	material = M.Neon,
})

return WeaponModel.define({
	-- Modeled standing along +Y; tip the staff forward so the head points along -Z.
	rotation = CFrame.Angles(math.rad(-90), 0, 0),
	handle = {
		size = Vector3.new(0.34, 1.2, 0.34),
		color = oxbloodLeather,
		material = M.Leather,
		transparency = 1,
	},
	muzzle = CFrame.new(0, 4.08, 0),
	pieces = pieces,
})
