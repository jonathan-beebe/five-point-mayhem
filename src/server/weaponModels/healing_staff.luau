-- Healing Staff: Renaissance-fair workshop wizard staff, turned ash shaft, brass claw setting holding a glowing glass orb.

local WeaponModel = require(script.Parent.Parent.systems.WeaponModel)

local rgb = Color3.fromRGB
local M = Enum.Material
local CY = WeaponModel.CYLINDER_Y
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball

local WOOD = rgb(112, 78, 50)
local WOOD_NODE = rgb(74, 50, 32)
local WOOD_KNOT = rgb(58, 40, 26)
local LEATHER = rgb(72, 46, 30)
local LEATHER_BAND = rgb(94, 62, 40)
local TWINE = rgb(168, 146, 108)
local BRASS = rgb(176, 140, 72)
local DARK_BRASS = rgb(128, 98, 48)
local VERDIGRIS = rgb(88, 140, 112)
local GLASS_MINT = rgb(180, 255, 200)
local HEAL_GREEN = rgb(120, 255, 140)

local ORB_Y = 4.3

local function r(degrees: number): number
	return math.rad(degrees)
end

-- Turned cylinder standing on the staff axis.
local function ring(
	name: string,
	length: number,
	diameter: number,
	y: number,
	color: Color3,
	material: Enum.Material,
	reflectance: number?
): WeaponModel.PieceSpec
	return {
		name = name,
		shape = CYL,
		size = Vector3.new(length, diameter, diameter),
		offset = CFrame.new(0, y, 0) * CY,
		color = color,
		material = material,
		reflectance = reflectance,
	}
end

local function ball(
	name: string,
	diameter: number,
	offset: CFrame,
	color: Color3,
	material: Enum.Material
): WeaponModel.PieceSpec
	return {
		name = name,
		shape = BALL,
		size = Vector3.one * diameter,
		offset = offset,
		color = color,
		material = material,
	}
end

local pieces: { WeaponModel.PieceSpec } = {
	-- Butt ferrule
	ball("FerruleCap", 0.32, CFrame.new(0, -1.35, 0), BRASS, M.Metal),
	ring("FerruleSleeve", 0.30, 0.32, -1.20, BRASS, M.Metal, 0.1),
	ring("FerruleLip", 0.04, 0.36, -1.05, DARK_BRASS, M.Metal, 0.05),

	-- Lower shaft (runs 0.05 into the grip wrap)
	ring("ShaftLower", 0.75, 0.30, -0.975, WOOD, M.Wood),

	-- Grip: leather wrap whipped with twine at each end
	ring("GripWrap", 1.30, 0.34, 0, LEATHER, M.Leather),
	ring("WhippingLower", 0.08, 0.37, -0.66, TWINE, M.Fabric),
	ring("WhippingUpper", 0.08, 0.37, 0.66, TWINE, M.Fabric),

	-- Upper shaft, thickening toward the head
	ring("ShaftMid", 1.40, 0.31, 1.30, WOOD, M.Wood),
	ring("GrowthNode", 0.10, 0.35, 2.00, WOOD_NODE, M.Wood),
	ring("ShaftUpper", 1.42, 0.33, 2.71, WOOD, M.Wood),
	ball("Knot1", 0.11, CFrame.new(0.15, 1.15, 0.03), WOOD_KNOT, M.Wood),
	ball("Knot2", 0.12, CFrame.new(-0.14, 2.45, -0.07), WOOD_KNOT, M.Wood),
	ball("Knot3", 0.10, CFrame.new(0.05, 3.05, 0.16), WOOD_KNOT, M.Wood),

	-- Brass collar and cup (the step overlaps the cup by 0.005 so their faces never share a plane)
	ring("CollarRing", 0.08, 0.40, 3.42, DARK_BRASS, M.Metal, 0.05),
	ring("CollarSleeve", 0.22, 0.36, 3.55, BRASS, M.Metal, 0.1),
	ring("CollarStep", 0.06, 0.46, 3.685, BRASS, M.Metal, 0.1),
	ring("CupBase", 0.10, 0.58, 3.76, DARK_BRASS, M.Metal, 0.05),

	-- Orb: glass shell, faint inner glow, bright core (shell bottom rests 0.01 into the cup)
	{
		name = "OrbShell",
		shape = BALL,
		size = Vector3.one * 1.0,
		offset = CFrame.new(0, ORB_Y, 0),
		color = GLASS_MINT,
		material = M.Glass,
		transparency = 0.45,
		reflectance = 0.2,
	},
	{
		name = "OrbHalo",
		shape = BALL,
		size = Vector3.one * 0.8,
		offset = CFrame.new(0, ORB_Y, 0),
		color = HEAL_GREEN,
		material = M.Neon,
		transparency = 0.7,
	},
	{
		name = "OrbCore",
		shape = BALL,
		size = Vector3.one * 0.55,
		offset = CFrame.new(0, ORB_Y, 0),
		color = HEAL_GREEN,
		material = M.Neon,
		transparency = 0.1,
	},
}

-- Spiral leather wrap: raised bands tilted 10 degrees, 0.01 proud of the wrap.
for i, y in { -0.50, -0.30, -0.10, 0.10, 0.30, 0.50 } do
	local band = ring(`WrapBand{i}`, 0.05, 0.36, y, LEATHER_BAND, M.Leather)
	band.offset = CFrame.new(0, y, 0) * CFrame.Angles(r(10), 0, 0) * CY
	table.insert(pieces, band)
end

-- Collar studs between the leaves.
for i, a in { 45, 135, 225, 315 } do
	table.insert(
		pieces,
		ball(
			`Stud{i}`,
			0.07,
			CFrame.Angles(0, r(a), 0) * CFrame.new(0, 3.55, -0.18),
			BRASS,
			M.Metal
		)
	)
end

-- Verdigris copper leaves rising from the collar, tops leaning outward.
for i, a in { 0, 90, 180, 270 } do
	table.insert(pieces, {
		name = `Leaf{i}`,
		size = Vector3.new(0.12, 0.26, 0.03),
		offset = CFrame.Angles(0, r(a), 0)
			* CFrame.new(0, 3.52, -0.20)
			* CFrame.Angles(r(-25), 0, 0),
		color = VERDIGRIS,
		material = M.Metal,
	})
end

-- Claw prongs: each is three flat straps on a polygon around the orb. Joints sit on a circle of
-- radius PRONG_R about the orb center, at 30, 70, 110 and 150 degrees up from the orb's bottom.
-- Strap midpoints sit at PRONG_R * cos(20) = 0.540, so the inner face (0.03 in) clears the
-- 0.5 glass radius by 0.01. The first joint lands on the cup rim; the last carries a ball tip.
local PRONG_R = 0.575
local STEP = 40
local MID_R = PRONG_R * math.cos(r(STEP / 2))
local STRAP_LENGTH = 2 * PRONG_R * math.sin(r(STEP / 2)) + 0.04
local SEGMENTS = { "ProngBase", "ProngMid", "ProngTop" }

for i, a in { 45, 135, 225, 315 } do
	local spin = CFrame.Angles(0, r(a), 0)
	for s, segName in SEGMENTS do
		-- Angle up from the orb's bottom to this strap's midpoint; the strap is tangent there.
		local phi = 30 + STEP * (s - 1) + STEP / 2
		local radial = MID_R * math.sin(r(phi))
		local y = ORB_Y - MID_R * math.cos(r(phi))
		table.insert(pieces, {
			name = `{segName}{i}`,
			size = Vector3.new(0.07, STRAP_LENGTH, 0.06),
			offset = spin * CFrame.new(0, y, -radial) * CFrame.Angles(r(phi - 90), 0, 0),
			color = BRASS,
			material = M.Metal,
			reflectance = 0.1,
		})
	end
	local tipPhi = 30 + STEP * #SEGMENTS
	local tip = ball(
		`ProngTip{i}`,
		0.08,
		spin * CFrame.new(0, ORB_Y - PRONG_R * math.cos(r(tipPhi)), -PRONG_R * math.sin(r(tipPhi))),
		BRASS,
		M.Metal
	)
	tip.reflectance = 0.1
	table.insert(pieces, tip)
end

return WeaponModel.define({
	handle = { transparency = 1 },
	muzzle = CFrame.new(0, ORB_Y, 0),
	pieces = pieces,
})
