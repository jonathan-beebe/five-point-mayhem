-- Slingshot: hand-carved natural-fork oak slingshot, amber flat latex bands, leather pouch with a river pebble.

local WeaponModel = require(script.Parent.Parent.systems.WeaponModel)

local rgb = Color3.fromRGB
local M = Enum.Material
local CYLINDER_Z = WeaponModel.CYLINDER_Z
local CYLINDER_Y = WeaponModel.CYLINDER_Y
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball
local R = math.rad
local v3 = Vector3.new

local oak = rgb(140, 100, 60)
local knot = rgb(88, 58, 32)
local holeDark = rgb(34, 24, 16)
local gripLeather = rgb(96, 62, 38)
local seamLeather = rgb(66, 42, 26)
local pouchLeather = rgb(122, 86, 54)
local thread = rgb(38, 34, 30)
local latex = rgb(204, 152, 74)
local paracord = rgb(74, 80, 58)
local brass = rgb(181, 146, 82)
local pebble = rgb(128, 123, 114)

local LATEX_TRANSPARENCY = 0.15
local LATEX_REFLECTANCE = 0.05

-- Fork geometry (right side; left is mirrored in X).
local ELBOW = v3(0.30, 0.72, 0)
local TIP = v3(0.36, 1.00, 0)
-- Lower arm starts deep inside the grip core so its end cap never shows outside the crotch.
local ARM_ROOT = v3(0.03, 0.245, 0)
-- Band path: from inside the tip wrap back to the pouch wing end.
local BAND_A = v3(0.343, 0.92, 0.08)
local BAND_B = v3(0.16, 0.60, 0.735)

local function mirror(p: Vector3, side: number): Vector3
	return v3(p.X * side, p.Y, p.Z)
end

local function sideName(name: string, side: number): string
	return name .. (if side > 0 then "R" else "L")
end

local function ball(
	name: string,
	diameter: number,
	at: Vector3,
	color: Color3,
	material: Enum.Material
)
	return {
		name = name,
		shape = BALL,
		size = v3(diameter, diameter, diameter),
		offset = CFrame.new(at),
		color = color,
		material = material,
	}
end

-- Cylinder running from a to b.
local function rod(
	name: string,
	a: Vector3,
	b: Vector3,
	diameter: number,
	color: Color3,
	material: Enum.Material
)
	return {
		name = name,
		shape = CYL,
		size = v3((b - a).Magnitude, diameter, diameter),
		offset = CFrame.lookAt((a + b) / 2, b) * CYLINDER_Z,
		color = color,
		material = material,
	}
end

-- Ring of the given length/diameter centered at `at`, axis along the upper arm toward the tip.
local function armRing(
	name: string,
	at: Vector3,
	length: number,
	diameter: number,
	side: number,
	color: Color3,
	material: Enum.Material,
	transparency: number?,
	reflectance: number?
)
	return {
		name = name,
		shape = CYL,
		size = v3(length, diameter, diameter),
		offset = CFrame.lookAt(mirror(at, side), mirror(TIP, side)) * CYLINDER_Z,
		color = color,
		material = material,
		transparency = transparency,
		reflectance = reflectance,
	}
end

-- Flat latex strip along the band path between fractions t0..t1 (band width in X, thickness in Y).
local function bandStrip(
	name: string,
	side: number,
	t0: number,
	t1: number,
	width: number,
	thickness: number
)
	local a = mirror(BAND_A, side)
	local b = mirror(BAND_B, side)
	local p0 = a:Lerp(b, t0)
	local p1 = a:Lerp(b, t1)
	return {
		name = name,
		size = v3(width, thickness, (p1 - p0).Magnitude),
		offset = CFrame.lookAt((p0 + p1) / 2, b),
		color = latex,
		material = M.SmoothPlastic,
		transparency = LATEX_TRANSPARENCY,
		reflectance = LATEX_REFLECTANCE,
	}
end

local pieces: { WeaponModel.PieceSpec } = {
	-- Frame: grip, crotch, butt
	{
		name = "GripCore",
		shape = CYL,
		size = v3(0.90, 0.28, 0.28),
		offset = CFrame.new(0, -0.10, 0) * CYLINDER_Y,
		color = oak,
		material = M.Wood,
	},
	ball("ButtFlare", 0.30, v3(0, -0.55, 0), oak, M.Wood),
	ball("Crotch", 0.32, v3(0, 0.36, 0), oak, M.Wood),

	-- Frame details: knots, maker's pin, lanyard hole
	{
		name = "KnotArm",
		shape = CYL,
		size = v3(0.02, 0.075, 0.075),
		offset = CFrame.new(-0.18, 0.50, -0.115) * CYLINDER_Z,
		color = knot,
		material = M.Wood,
	},
	{
		name = "KnotGrip",
		shape = CYL,
		size = v3(0.02, 0.06, 0.06),
		offset = CFrame.new(0.135, 0.25, 0),
		color = knot,
		material = M.Wood,
	},
	{
		name = "MakerPin",
		shape = CYL,
		size = v3(0.02, 0.05, 0.05),
		offset = CFrame.new(0, 0.36, -0.155) * CYLINDER_Z,
		color = brass,
		material = M.Metal,
		reflectance = 0.1,
	},
	{
		name = "LanyardHole",
		shape = CYL,
		size = v3(0.302, 0.07, 0.07),
		offset = CFrame.new(0, -0.53, 0) * CYLINDER_Z,
		color = holeDark,
		material = M.Wood,
	},

	-- Grip wrap: spiral leather with thread whipping at both ends
	{
		name = "Wrap",
		shape = CYL,
		size = v3(0.56, 0.32, 0.32),
		offset = CFrame.new(0, -0.14, 0) * CYLINDER_Y,
		color = gripLeather,
		material = M.Leather,
	},
	{
		name = "WhipBottom",
		shape = CYL,
		size = v3(0.04, 0.335, 0.335),
		offset = CFrame.new(0, -0.43, 0) * CYLINDER_Y,
		color = thread,
		material = M.Fabric,
	},
	{
		name = "WhipTop",
		shape = CYL,
		size = v3(0.04, 0.335, 0.335),
		offset = CFrame.new(0, 0.15, 0) * CYLINDER_Y,
		color = thread,
		material = M.Fabric,
	},

	-- Lanyard: paracord loop through the butt, hanging clear of the butt flare, tied off below
	ball("CordKnot", 0.09, v3(0, -0.79, 0), paracord, M.Fabric),

	-- Pouch: leather folded around a river pebble
	{
		name = "PouchCenter",
		size = v3(0.15, 0.17, 0.03),
		offset = CFrame.new(0, 0.60, 0.78),
		color = pouchLeather,
		material = M.Leather,
	},
	ball("Pebble", 0.13, v3(0, 0.60, 0.705), pebble, M.Slate),
}

local function add(piece: WeaponModel.PieceSpec)
	table.insert(pieces, piece)
end

for i, y in { -0.36, -0.27, -0.18, -0.09, 0.00, 0.09 } do
	add({
		name = "WrapSeam" .. i,
		shape = CYL,
		size = v3(0.025, 0.33, 0.33),
		offset = CFrame.new(0, y, 0) * CFrame.Angles(R(8), 0, 0) * CYLINDER_Y,
		color = seamLeather,
		material = M.Leather,
	})
end

for _, side in { 1, -1 } do
	-- Fork arm: lower arm, elbow, upper arm, rounded tip
	add(
		rod(
			sideName("LowerArm", side),
			mirror(ARM_ROOT, side),
			mirror(ELBOW, side),
			0.24,
			oak,
			M.Wood
		)
	)
	add(ball(sideName("Elbow", side), 0.24, mirror(ELBOW, side), oak, M.Wood))
	add(rod(sideName("UpperArm", side), mirror(ELBOW, side), mirror(TIP, side), 0.21, oak, M.Wood))
	add(ball(sideName("Tip", side), 0.21, mirror(TIP, side), oak, M.Wood))

	-- Band folded over the fork tip, thread-tied, with a loose tag end hanging in front
	add(
		armRing(
			sideName("BandWrap", side),
			v3(0.343, 0.922, 0),
			0.13,
			0.235,
			side,
			latex,
			M.SmoothPlastic,
			LATEX_TRANSPARENCY,
			LATEX_REFLECTANCE
		)
	)
	add(armRing(sideName("TipTie", side), v3(0.335, 0.883, 0), 0.04, 0.25, side, thread, M.Fabric))
	add({
		name = sideName("BandTag", side),
		size = v3(0.07, 0.08, 0.02),
		offset = CFrame.new(0.324 * side, 0.83, -0.112) * CFrame.Angles(0, 0, R(-12.1 * side)),
		color = latex,
		material = M.SmoothPlastic,
		transparency = LATEX_TRANSPARENCY,
		reflectance = LATEX_REFLECTANCE,
	})

	-- Bands: tapered flat latex, wide at the fork, narrow at the pouch. The lower strip is
	-- 0.02 thinner so its faces sit 0.01 inside the upper strip where they overlap.
	add(bandStrip(sideName("BandUpper", side), side, 0, 0.509, 0.12, 0.032))
	add(bandStrip(sideName("BandLower", side), side, 0.491, 1.009, 0.09, 0.012))

	-- Pouch wing and the thread tie binding the band to it
	add({
		name = sideName("PouchWing", side),
		size = v3(0.10, 0.15, 0.03),
		offset = CFrame.new(0.116 * side, 0.60, 0.751) * CFrame.Angles(0, R(35 * side), 0),
		color = pouchLeather,
		material = M.Leather,
	})
	add({
		name = sideName("PouchTie", side),
		size = v3(0.11, 0.05, 0.045),
		offset = CFrame.lookAt(mirror(v3(0.172, 0.621, 0.691), side), mirror(BAND_B, side)),
		color = thread,
		material = M.Fabric,
	})
end

-- Lanyard legs: front (-Z) and back (+Z). Each leaves the hole face, drops past the butt flare,
-- then angles in to the knot.
for _, face in { -1, 1 } do
	local label = if face < 0 then "Front" else "Back"
	local exit = v3(0, -0.53, 0.150 * face)
	local bend = v3(0, -0.70, 0.168 * face)
	local toKnot = v3(0, -0.79, 0.035 * face)
	add(rod("Cord" .. label .. "Upper", exit, bend, 0.045, paracord, M.Fabric))
	add(ball("Cord" .. label .. "Bend", 0.045, bend, paracord, M.Fabric))
	add(rod("Cord" .. label .. "Lower", bend, toKnot, 0.045, paracord, M.Fabric))
end

return WeaponModel.define({
	handle = {
		size = v3(0.28, 0.28, 0.28),
		color = oak,
		material = M.Wood,
		transparency = 1,
	},
	muzzle = CFrame.new(0, 0.95, -0.15),
	pieces = pieces,
})
