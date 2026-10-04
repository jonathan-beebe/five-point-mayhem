-- Reaper Scythe: Austrian-pattern European mowing scythe, ash snath with hand-forged steel blade.

local WeaponModel = require(script.Parent.Parent.systems.WeaponModel)

local rgb = Color3.fromRGB
local M = Enum.Material
local CYLINDER_Z = WeaponModel.CYLINDER_Z
local CYLINDER_Y = WeaponModel.CYLINDER_Y
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball
local rad = math.rad

local forgedSteel = rgb(60, 60, 70)
local blackSteel = rgb(42, 42, 48)
local honedEdge = rgb(150, 150, 158)
local brightSteel = rgb(112, 112, 120)
local rust = rgb(104, 62, 40)
local darkAsh = rgb(78, 58, 42)
local nibWood = rgb(96, 72, 50)
local wornLeather = rgb(58, 40, 28)
local leatherSeam = rgb(40, 28, 20)
local waxedTwine = rgb(150, 130, 95)

-- Nib axis: raked 15 degrees forward from +Y, rooted inside the clamp on the snath.
local NIB_TILT = CFrame.Angles(rad(-15), 0, 0)
local NIB_BASE = Vector3.new(0, 0.12, -2.2)
local NIB_AXIS = Vector3.new(0, math.cos(rad(15)), -math.sin(rad(15)))

local function nib(along: number): CFrame
	return CFrame.new(NIB_BASE + NIB_AXIS * along)
end

-- Blade frame: a horizontal segment that starts at spine point (sx, sz) and turns by theta
-- degrees about Y. `u` runs along the segment, `n` runs from the spine toward the edge (+Z side).
local function bladeAt(
	sx: number,
	sz: number,
	theta: number,
	y: number,
	u: number,
	n: number
): CFrame
	local c, s = math.cos(rad(theta)), math.sin(rad(theta))
	return CFrame.new(sx + u * c + n * s, y, sz - u * s + n * c) * CFrame.Angles(0, rad(theta), 0)
end

-- Maps a wedge's local X to -Y, local Y to the edge side (+n) and local Z to -u, so the tall face
-- joins the previous segment, the slope is the cutting edge and the point runs out along the spine.
local WEDGE_FLAT = CFrame.fromMatrix(Vector3.zero, Vector3.new(0, -1, 0), Vector3.new(0, 0, 1))

local function grip(
	name: string,
	length: number,
	diameter: number,
	z: number,
	color: Color3,
	material: Enum.Material
)
	return {
		name = name,
		shape = CYL,
		size = Vector3.new(length, diameter, diameter),
		offset = CFrame.new(0, 0, z) * CYLINDER_Z,
		color = color,
		material = material,
	}
end

local function seam(index: number, z: number)
	return {
		name = "GripSeam" .. index,
		shape = CYL,
		size = Vector3.new(0.03, 0.36, 0.36),
		offset = CFrame.new(0, 0, z) * CFrame.Angles(rad(8), 0, 0) * CYLINDER_Z,
		color = leatherSeam,
		material = M.Leather,
	}
end

local pieces: { WeaponModel.PieceSpec } = {
	-- Snath: ash shaft in three tapering steps, z +1.20 to -5.00, 0.04 overlap at each joint
	grip("SnathRear", 2.3, 0.3, 0.05, darkAsh, M.Wood),
	grip("SnathMid", 2.44, 0.28, -2.28, darkAsh, M.Wood),
	grip("SnathFront", 1.54, 0.26, -4.23, darkAsh, M.Wood),

	-- Butt
	grip("ButtFerrule", 0.14, 0.34, 1.14, blackSteel, M.Metal),
	{
		name = "ButtKnob",
		shape = BALL,
		size = Vector3.new(0.29, 0.29, 0.29),
		offset = CFrame.new(0, 0, 1.22),
		color = darkAsh,
		material = M.Wood,
	},

	-- Grip: leather wrap at the hand, twine whipping at each end, overlap ridges
	grip("GripWrap", 1.1, 0.34, 0, wornLeather, M.Leather),
	grip("GripTwineRear", 0.06, 0.38, 0.58, waxedTwine, M.Fabric),
	grip("GripTwineFront", 0.06, 0.38, -0.58, waxedTwine, M.Fabric),
	seam(1, 0.3),
	seam(2, 0),
	seam(3, -0.3),

	-- Nib: steel clamp band with bolt and nut, wooden hand peg
	grip("NibClamp", 0.28, 0.36, -2.2, blackSteel, M.Metal),
	{
		name = "NibBolt",
		shape = CYL,
		size = Vector3.new(0.06, 0.09, 0.09),
		offset = CFrame.new(0.195, 0, -2.2),
		color = brightSteel,
		material = M.Metal,
	},
	{
		name = "NibNut",
		size = Vector3.new(0.06, 0.09, 0.09),
		offset = CFrame.new(-0.195, 0, -2.2),
		color = brightSteel,
		material = M.Metal,
	},
	{
		name = "NibCollar",
		shape = CYL,
		size = Vector3.new(0.12, 0.24, 0.24),
		offset = nib(0.08) * NIB_TILT * CYLINDER_Y,
		color = blackSteel,
		material = M.Metal,
	},
	{
		name = "NibPeg",
		shape = CYL,
		size = Vector3.new(0.75, 0.18, 0.18),
		offset = nib(0.375) * NIB_TILT * CYLINDER_Y,
		color = nibWood,
		material = M.Wood,
	},
	{
		name = "NibKnob",
		shape = BALL,
		size = Vector3.new(0.24, 0.24, 0.24),
		offset = nib(0.78),
		color = nibWood,
		material = M.Wood,
	},

	-- Ring collar: clamps the blade tang under the snath end with a square-head bolt
	{
		name = "Ring",
		shape = CYL,
		size = Vector3.new(0.32, 0.42, 0.42),
		offset = CFrame.new(0, -0.03, -4.5) * CYLINDER_Z,
		color = blackSteel,
		material = M.Metal,
	},
	{
		name = "RingLip",
		shape = CYL,
		size = Vector3.new(0.05, 0.46, 0.46),
		offset = CFrame.new(0, -0.03, -4.645) * CYLINDER_Z,
		color = blackSteel,
		material = M.Metal,
	},
	{
		name = "RingBoss",
		size = Vector3.new(0.14, 0.08, 0.16),
		offset = CFrame.new(0, 0.2, -4.5),
		color = blackSteel,
		material = M.Metal,
	},
	{
		name = "RingWasher",
		shape = CYL,
		size = Vector3.new(0.02, 0.14, 0.14),
		offset = CFrame.new(0, 0.25, -4.5) * CYLINDER_Y,
		color = brightSteel,
		material = M.Metal,
	},
	{
		name = "RingBoltHead",
		size = Vector3.new(0.09, 0.08, 0.09),
		offset = CFrame.new(0, 0.295, -4.5) * CFrame.Angles(0, rad(45), 0),
		color = brightSteel,
		material = M.Metal,
	},
	grip("SnathEndCap", 0.06, 0.3, -5, blackSteel, M.Metal),

	-- Tang and heel: tang top face is tangent to the snath underside, hook pin rises into it
	{
		name = "Tang",
		size = Vector3.new(0.14, 0.08, 0.8),
		offset = CFrame.new(0, -0.17, -4.7),
		color = forgedSteel,
		material = M.Metal,
	},
	{
		name = "TangHook",
		size = Vector3.new(0.1, 0.1, 0.06),
		offset = CFrame.new(0, -0.12, -4.33),
		color = forgedSteel,
		material = M.Metal,
	},
	{
		name = "HeelBoss",
		size = Vector3.new(0.3, 0.07, 0.5),
		offset = CFrame.new(0.1, -0.17, -5.02),
		color = forgedSteel,
		material = M.Metal,
	},
}

-- Blade: four segments chained on the spine (convex, -Z) side so the spine has no gaps and the
-- edge side overlaps. Alternate segments sit 0.01 apart in Y to keep overlapping faces apart.
-- Thickness steps act as bevels: rib 0.09, heel boss 0.07, body 0.05, edge 0.03.
local SEGMENTS = {
	{ theta = 0, y = -0.17, length = 0.75, width = 0.62 },
	{ theta = -6, y = -0.16, length = 0.75, width = 0.56 },
	{ theta = -14, y = -0.17, length = 0.7, width = 0.48 },
	{ theta = -24, y = -0.16, length = 0.65, width = 0.38 },
}

local sx, sz = -0.05, -5.33
for index, seg in SEGMENTS do
	local body = seg.width - 0.05
	local half = seg.length / 2
	table.insert(pieces, {
		name = "Blade" .. index .. "Body",
		size = Vector3.new(seg.length + 0.02, 0.05, body),
		offset = bladeAt(sx, sz, seg.theta, seg.y, half, body / 2),
		color = forgedSteel,
		material = M.Metal,
	})
	table.insert(pieces, {
		name = "Blade" .. index .. "Rib",
		size = Vector3.new(seg.length + 0.04, 0.09, 0.07),
		offset = bladeAt(sx, sz, seg.theta, seg.y, half, 0.035),
		color = blackSteel,
		material = M.Metal,
	})
	table.insert(pieces, {
		name = "Blade" .. index .. "Edge",
		size = Vector3.new(seg.length + 0.04, 0.03, 0.1),
		offset = bladeAt(sx, sz, seg.theta, seg.y, half, body),
		color = honedEdge,
		material = M.Metal,
		reflectance = 0.2,
	})
	local c, s = math.cos(rad(seg.theta)), math.sin(rad(seg.theta))
	sx, sz = sx + seg.length * c, sz - seg.length * s
end

-- Tip: hooked point, starts at the end of segment 4 and turns 38 degrees back toward the wielder
local TIP_THETA, TIP_Y, TIP_LENGTH, TIP_WIDTH = -38, -0.17, 0.8, 0.36
local tipC, tipS = math.cos(rad(TIP_THETA)), math.sin(rad(TIP_THETA))
local tipPoint = Vector3.new(sx + TIP_LENGTH * tipC, TIP_Y, sz - TIP_LENGTH * tipS)
local edgeBase = Vector3.new(sx + TIP_WIDTH * tipS, TIP_Y, sz + TIP_WIDTH * tipC)
local tipEdgeLength = (tipPoint - edgeBase).Magnitude

table.insert(pieces, {
	name = "TipBody",
	class = "WedgePart",
	size = Vector3.new(0.05, TIP_WIDTH, TIP_LENGTH),
	offset = bladeAt(sx, sz, TIP_THETA, TIP_Y, TIP_LENGTH / 2, TIP_WIDTH / 2) * WEDGE_FLAT,
	color = forgedSteel,
	material = M.Metal,
})
table.insert(pieces, {
	name = "TipRib",
	size = Vector3.new(0.6, 0.09, 0.07),
	offset = bladeAt(sx, sz, TIP_THETA, TIP_Y, 0.3, 0.035),
	color = blackSteel,
	material = M.Metal,
})
-- Edge strip runs along the wedge's slope from the edge-side base corner to the point
table.insert(pieces, {
	name = "TipEdge",
	size = Vector3.new(tipEdgeLength - 0.02, 0.03, 0.1),
	offset = CFrame.lookAt((edgeBase + tipPoint) / 2, tipPoint) * CFrame.Angles(0, rad(90), 0),
	color = honedEdge,
	material = M.Metal,
	reflectance = 0.2,
})

-- Weathering: rust patches near the heel, 0.01 proud of the blade top
table.insert(pieces, {
	name = "RustPatch1",
	size = Vector3.new(0.28, 0.02, 0.16),
	offset = CFrame.new(0.45, -0.145, -5.12),
	color = rust,
	material = M.CorrodedMetal,
})
table.insert(pieces, {
	name = "RustPatch2",
	size = Vector3.new(0.22, 0.02, 0.12),
	offset = CFrame.new(1.15, -0.135, -5.15) * CFrame.Angles(0, rad(-6), 0),
	color = rust,
	material = M.CorrodedMetal,
})

return WeaponModel.define({
	-- Held upright: the snath rises from the fist (-Z), the blade at its top reaches forward (-Y)
	-- and its edge faces down the snath toward the wielder (+Z), so the swing hooks it into the target.
	hold = "upright",
	-- Roll about the snath: the blade (built along +X) points along -Y, the nib peg along +X.
	rotation = CFrame.Angles(0, 0, -math.pi / 2),
	handle = {
		size = Vector3.new(0.3, 0.3, 1.2),
		color = wornLeather,
		material = M.Leather,
		transparency = 1,
	},
	pieces = pieces,
})
