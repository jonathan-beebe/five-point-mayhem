-- Lamborghini Aventador SVJ: V12 wedge supercar in Verde Mantis with carbon aero and a big rear wing.

local rgb = Color3.fromRGB
local M = Enum.Material
local A = CFrame.Angles
local CYL = Enum.PartType.Cylinder
local WEDGE = "WedgePart"

-- Scale: 4.6 studs = 1 m (low car; lets the R15 avatar fit under the 5.3-stud roof).

-- Rotations. Cylinder axis is local X; WedgePart default rises toward +Z.
local CYLINDER_Z = A(0, math.rad(90), 0)
local RISE_FRONT = A(0, math.pi, 0)

-- Palette: color, material, reflectance, transparency.
local GREEN = { c = rgb(92, 200, 30), m = M.SmoothPlastic, r = 0.12 }
local GREEN_DARK = { c = rgb(66, 150, 22), m = M.SmoothPlastic, r = 0.1 }
local CARBON = { c = rgb(28, 28, 31), m = M.SmoothPlastic, r = 0.06 }
local MESH = { c = rgb(16, 16, 18), m = M.DiamondPlate }
local TRIM_BLACK = { c = rgb(20, 20, 22), m = M.SmoothPlastic }
local GAP = { c = rgb(12, 12, 12), m = M.SmoothPlastic }
local UNDER = { c = rgb(30, 30, 32), m = M.SmoothPlastic }
local GLASS = { c = rgb(25, 32, 38), m = M.Glass, r = 0.1, t = 0.45 }
local MIRROR = { c = rgb(150, 165, 180), m = M.Glass, r = 0.4 }
local HEAD_NEON = { c = rgb(255, 244, 225), m = M.Neon }
local MAIN_BEAM = { c = rgb(255, 244, 225), m = M.Neon, t = 0.1 }
local LAMP_HOUSING = { c = rgb(38, 40, 44), m = M.SmoothPlastic, r = 0.2 }
local AMBER = { c = rgb(255, 150, 20), m = M.Neon }
local TAIL = { c = rgb(255, 28, 22), m = M.Neon }
local TAIL_HOUSING = { c = rgb(40, 10, 10), m = M.SmoothPlastic, r = 0.2 }
local TIRE = { c = rgb(24, 24, 26), m = M.SmoothPlastic }
local RIM = { c = rgb(22, 22, 24), m = M.SmoothPlastic, r = 0.15 }
local RIM_WELL = { c = rgb(12, 12, 13), m = M.SmoothPlastic }
local RIM_HUB = { c = rgb(45, 45, 48), m = M.Metal }
local DISC = { c = rgb(80, 80, 84), m = M.Metal }
local CALIPER = { c = rgb(240, 190, 20), m = M.SmoothPlastic, r = 0.1 }
local EXHAUST = { c = rgb(70, 70, 75), m = M.Metal, r = 0.15 }
local BORE = { c = rgb(8, 8, 8), m = M.SmoothPlastic }
local PLATE = { c = rgb(225, 225, 225), m = M.SmoothPlastic }
local GOLD = { c = rgb(200, 165, 60), m = M.Metal }
local SEAT = { c = rgb(32, 32, 34), m = M.Fabric }
local STITCH = { c = rgb(92, 200, 30), m = M.Fabric }
local INTERIOR_DARK = { c = rgb(25, 25, 27), m = M.SmoothPlastic }
local DASH_TOP = { c = rgb(25, 25, 27), m = M.Fabric }
local SCREEN = { c = rgb(40, 60, 70), m = M.SmoothPlastic }

local FRONT_AXLE_Z = -6.30
local REAR_AXLE_Z = 6.12

local P = {}

local function add(
	name: string,
	size: Vector3,
	offset: CFrame,
	st,
	class: string?,
	shape: Enum.PartType?
)
	local p = {
		name = name,
		class = class,
		shape = shape,
		size = size,
		offset = offset,
		color = st.c,
		material = st.m,
		reflectance = st.r,
		transparency = st.t,
	}
	table.insert(P, p)
	return p
end

local function part(name: string, size: Vector3, offset: CFrame, st)
	return add(name, size, offset, st)
end

local function wedge(name: string, size: Vector3, offset: CFrame, st)
	return add(name, size, offset, st, WEDGE)
end

local function cyl(name: string, size: Vector3, offset: CFrame, st)
	return add(name, size, offset, st, nil, CYL)
end

-- Plate in a YZ plane from (y1, z1) to (y2, z2); local Z runs along the line. w = X width, t = thickness.
local function slab(
	name: string,
	x: number,
	w: number,
	t: number,
	y1: number,
	z1: number,
	y2: number,
	z2: number,
	st
)
	local dy, dz = y2 - y1, z2 - z1
	return part(
		name,
		Vector3.new(w, t, math.sqrt(dy * dy + dz * dz)),
		CFrame.new(x, (y1 + y2) / 2, (z1 + z2) / 2) * A(-math.atan2(dy, dz), 0, 0),
		st
	)
end

-- Bar between two points (w = horizontal-perpendicular size, t = vertical-perpendicular size).
-- Built from yaw and pitch angles (lune's CFrame.lookAt flips the pitch in the preview).
local function strut(name: string, a: Vector3, b: Vector3, w: number, t: number, st)
	local d = b - a
	local yaw = math.atan2(d.X, d.Z)
	local pitch = -math.atan2(d.Y, math.sqrt(d.X * d.X + d.Z * d.Z))
	return part(
		name,
		Vector3.new(w, t, d.Magnitude),
		CFrame.new(a:Lerp(b, 0.5)) * A(0, yaw, 0) * A(pitch, 0, 0),
		st
	)
end

-- Structure ---------------------------------------------------------------------------------

wedge("FrontTub", Vector3.new(5.8, 2.0, 6.55), CFrame.new(0, 1.6, -7.73), UNDER)
part("CabinFloor", Vector3.new(5.8, 0.2, 6.85), CFrame.new(0, 0.65, -1.03), INTERIOR_DARK)
part("RearTub", Vector3.new(5.8, 3.0, 8.6), CFrame.new(0, 2.1, 6.7), UNDER)

-- Front body --------------------------------------------------------------------------------

wedge("Hood", Vector3.new(6.0, 1.5, 5.4), CFrame.new(0, 2.5, -8.3), GREEN)
part("BumperCenter", Vector3.new(4.2, 0.95, 0.4), CFrame.new(0, 1.28, -11.15), GREEN)
part(
	"Badge",
	Vector3.new(0.3, 0.36, 0.05),
	CFrame.new(0, 1.97, -10.9) * A(math.rad(-15.5), 0, 0),
	GOLD
)
part("Splitter", Vector3.new(8.8, 0.1, 1.0), CFrame.new(0, 0.62, -10.95), CARBON)
part("NoseFlap", Vector3.new(2.0, 0.22, 0.06), CFrame.new(0, 0.95, -11.38), MESH)
part("Cowl", Vector3.new(5.8, 0.15, 0.6), CFrame.new(0, 3.25, -5.75), TRIM_BLACK)

for _, s in { -1, 1 } do
	slab("HoodCrease", s * 1.3, 0.12, 0.06, 1.83, -10.9, 3.33, -5.7, GREEN_DARK)
	slab("HoodVent", s * 1.25, 1.1, 0.05, 2.33, -8.2, 2.53, -7.4, MESH)
	slab("FenderSkin", s * 3.85, 1.8, 0.3, 1.85, -11.0, 3.2, -6.0, GREEN)
	slab("FenderTop", s * 3.85, 1.8, 0.3, 3.2, -6.0, 3.3, -4.45, GREEN)
	part("FrontCornerLow", Vector3.new(1.85, 1.0, 2.9), CFrame.new(s * 3.82, 1.1, -9.6), GREEN)
	wedge("FrontCornerHigh", Vector3.new(1.85, 1.0, 2.9), CFrame.new(s * 3.82, 2.1, -9.6), GREEN)
	part("FenderRearBlade", Vector3.new(0.4, 2.6, 0.5), CFrame.new(s * 4.55, 2.0, -4.2), GREEN)
	part("FrontIntake", Vector3.new(2.3, 1.15, 0.3), CFrame.new(s * 3.25, 1.3, -11.0), MESH)
	part("IntakeBladeH", Vector3.new(2.2, 0.12, 0.3), CFrame.new(s * 3.25, 1.5, -11.12), GREEN)
	part(
		"IntakeBladeDiag",
		Vector3.new(1.3, 0.12, 0.3),
		CFrame.new(s * 3.6, 1.1, -11.12) * A(0, 0, s * math.rad(-25)),
		GREEN
	)
	part("SplitterFin", Vector3.new(0.08, 0.35, 0.9), CFrame.new(s * 4.35, 0.8, -10.95), CARBON)
end

-- Sides -------------------------------------------------------------------------------------

for _, s in { -1, 1 } do
	part("DoorWall", Vector3.new(1.45, 2.8, 6.25), CFrame.new(s * 3.625, 2.05, -1.33), GREEN)
	wedge(
		"DoorShoulder",
		Vector3.new(6.25, 0.3, 0.7),
		CFrame.new(s * 4.0, 3.6, -1.33) * A(0, -s * math.pi / 2, 0),
		GREEN
	)
	part("DoorGapFront", Vector3.new(0.04, 2.6, 0.05), CFrame.new(s * 4.37, 2.1, -4.15), GAP)
	part("DoorGapRear", Vector3.new(0.04, 2.4, 0.05), CFrame.new(s * 4.37, 2.2, 1.75), GAP)
	strut(
		"DoorCrease",
		Vector3.new(s * 4.38, 1.45, -4.2),
		Vector3.new(s * 4.38, 2.55, 1.7),
		0.06,
		0.12,
		GREEN_DARK
	)
	part("DoorLowerCarbon", Vector3.new(0.06, 0.6, 6.1), CFrame.new(s * 4.38, 1.15, -1.35), CARBON)
	part("DoorHandle", Vector3.new(0.05, 0.08, 0.5), CFrame.new(s * 4.37, 3.15, 1.2), GAP)
	part("SideSkirt", Vector3.new(0.3, 0.45, 8.1), CFrame.new(s * 4.45, 0.82, -0.2), CARBON)
	part("SideIntakeRecess", Vector3.new(1.0, 2.25, 2.15), CFrame.new(s * 4.1, 2.175, 2.875), MESH)
	strut(
		"SideIntakeBlade",
		Vector3.new(s * 4.6, 1.05, 1.75),
		Vector3.new(s * 4.6, 3.3, 2.45),
		0.25,
		0.25,
		GREEN
	)
	part("IntakeBand", Vector3.new(1.95, 0.55, 2.15), CFrame.new(s * 3.85, 3.575, 2.875), GREEN)
	part("HaunchBand", Vector3.new(1.95, 0.4, 4.35), CFrame.new(s * 3.85, 3.7, 6.125), GREEN)
	part("HaunchRearWall", Vector3.new(1.95, 2.95, 2.8), CFrame.new(s * 3.85, 2.125, 9.7), GREEN)
	slab("HaunchTop", s * 3.85, 1.95, 0.3, 3.95, 2.0, 3.7, 11.1, GREEN)
	wedge(
		"ShoulderScoop",
		Vector3.new(1.5, 0.55, 2.4),
		CFrame.new(s * 3.9, 4.33, 4.4) * RISE_FRONT,
		GREEN
	)
	part("ScoopMouth", Vector3.new(1.3, 0.42, 0.04), CFrame.new(s * 3.9, 4.3, 3.17), MESH)
	strut(
		"ArchLipF1",
		Vector3.new(s * 4.72, 1.0, -8.15),
		Vector3.new(s * 4.72, 3.05, -7.2),
		0.06,
		0.12,
		TRIM_BLACK
	)
	strut(
		"ArchLipF2",
		Vector3.new(s * 4.72, 3.05, -7.2),
		Vector3.new(s * 4.72, 3.15, -5.0),
		0.06,
		0.12,
		TRIM_BLACK
	)
	strut(
		"ArchLipR1",
		Vector3.new(s * 4.84, 1.0, 3.95),
		Vector3.new(s * 4.84, 3.45, 4.9),
		0.05,
		0.12,
		TRIM_BLACK
	)
	strut(
		"ArchLipR2",
		Vector3.new(s * 4.84, 3.45, 4.9),
		Vector3.new(s * 4.84, 3.5, 7.5),
		0.05,
		0.12,
		TRIM_BLACK
	)
	strut(
		"ArchLipR3",
		Vector3.new(s * 4.84, 3.5, 7.5),
		Vector3.new(s * 4.84, 1.2, 8.3),
		0.05,
		0.12,
		TRIM_BLACK
	)
	strut(
		"MirrorArm",
		Vector3.new(s * 4.0, 3.55, -3.7),
		Vector3.new(s * 4.75, 3.78, -3.85),
		0.12,
		0.08,
		CARBON
	)
	part("MirrorHousing", Vector3.new(0.85, 0.42, 0.55), CFrame.new(s * 4.95, 3.85, -3.85), GREEN)
	part("MirrorGlass", Vector3.new(0.75, 0.32, 0.03), CFrame.new(s * 4.95, 3.85, -3.56), MIRROR)
end

-- Greenhouse, roof, engine cover, wing -------------------------------------------------------

slab("RoofFront", 0, 5.3, 0.2, 5.05, -1.7, 5.2, -0.4, GREEN)
part("RoofFlat", Vector3.new(5.3, 0.2, 1.3), CFrame.new(0, 5.2, 0.25), GREEN)
slab("RoofRear", 0, 5.3, 0.2, 5.2, 0.9, 4.95, 2.4, GREEN)
slab("EngineSpine", 0, 1.4, 0.2, 4.95, 2.4, 3.8, 10.6, GREEN)
part("RearDeckLip", Vector3.new(9.4, 0.15, 0.6), CFrame.new(0, 3.82, 10.85), CARBON)
part(
	"WingMain",
	Vector3.new(8.4, 0.12, 1.5),
	CFrame.new(0, 4.95, 10.55) * A(math.rad(-8), 0, 0),
	CARBON
)
part("WingGurney", Vector3.new(8.4, 0.14, 0.05), CFrame.new(0, 5.08, 11.28), CARBON)

for _, s in { -1, 1 } do
	strut(
		"APillar",
		Vector3.new(s * 2.85, 3.3, -5.6),
		Vector3.new(s * 2.47, 5.12, -1.7),
		0.35,
		0.18,
		GREEN
	)
	part(
		"SideWindowTrim",
		Vector3.new(0.08, 0.08, 7.4),
		CFrame.new(s * 3.66, 3.52, -1.4),
		TRIM_BLACK
	)
	slab("Buttress", s * 2.65, 0.8, 0.25, 4.95, 2.4, 3.85, 10.6, GREEN)
	slab("LouverPanel", s * 1.5, 1.6, 0.1, 4.88, 2.6, 3.74, 10.5, CARBON)
	local y1, z1, y2, z2 = 4.88, 2.6, 3.74, 10.5
	local pitch = A(-math.atan2(y2 - y1, z2 - z1), 0, 0)
	for k = 0, 5 do
		local t = 0.12 + k * 0.15
		part(
			"LouverSlat",
			Vector3.new(1.5, 0.08, 0.3),
			CFrame.new(s * 1.5, y1 + (y2 - y1) * t + 0.09, z1 + (z2 - z1) * t) * pitch,
			MESH
		)
	end
	part("WingEndplate", Vector3.new(0.1, 0.8, 1.8), CFrame.new(s * 4.25, 4.85, 10.6), CARBON)
	part("WingPylon", Vector3.new(0.12, 1.0, 0.7), CFrame.new(s * 1.1, 4.4, 10.3), CARBON)
end

-- Rear face ---------------------------------------------------------------------------------

part("RearPanel", Vector3.new(5.8, 2.1, 0.2), CFrame.new(0, 2.6, 11.0), GREEN)
part("RearMesh", Vector3.new(5.2, 1.0, 0.06), CFrame.new(0, 3.15, 11.14), MESH)
for k = 0, 4 do
	part("RearSlat", Vector3.new(5.2, 0.06, 0.1), CFrame.new(0, 2.75 + 0.2 * k, 11.17), TRIM_BLACK)
end
part("ExhaustHexCore", Vector3.new(1.7, 1.0, 0.3), CFrame.new(0, 2.65, 11.25), TRIM_BLACK)
part("Plate", Vector3.new(2.0, 0.5, 0.05), CFrame.new(0, 1.88, 11.14), PLATE)
slab("Diffuser", 0, 7.4, 0.1, 0.6, 9.4, 1.55, 11.3, CARBON)
for _, x in { 0, -1.2, 1.2, -2.4, 2.4, -3.4, 3.4 } do
	part("DiffuserStrake", Vector3.new(0.08, 1.0, 1.9), CFrame.new(x, 1.05, 10.35), CARBON)
end
part("RearFog", Vector3.new(0.5, 0.14, 0.05), CFrame.new(0, 1.45, 11.25), TAIL)
part("ThirdBrake", Vector3.new(1.2, 0.06, 0.05), CFrame.new(0, 3.9, 11.13), TAIL)

for _, s in { -1, 1 } do
	part(
		"ExhaustHexEnd",
		Vector3.new(0.71, 0.71, 0.3),
		CFrame.new(s * 0.85, 2.65, 11.25) * A(0, 0, math.rad(45)),
		TRIM_BLACK
	)
	cyl(
		"ExhaustTip",
		Vector3.new(0.5, 0.62, 0.62),
		CFrame.new(s * 0.4, 2.65, 11.35) * CYLINDER_Z,
		EXHAUST
	)
	cyl(
		"ExhaustBore",
		Vector3.new(0.02, 0.48, 0.48),
		CFrame.new(s * 0.4, 2.65, 11.61) * CYLINDER_Z,
		BORE
	)
end

-- Lights ------------------------------------------------------------------------------------

for _, s in { -1, 1 } do
	slab("HeadlampHousing", s * 3.55, 1.5, 0.06, 2.18, -10.4, 2.6, -9.0, LAMP_HOUSING)
	strut(
		"DrlStem",
		Vector3.new(s * 4.05, 2.24, -10.3),
		Vector3.new(s * 4.05, 2.42, -9.75),
		0.1,
		0.05,
		HEAD_NEON
	)
	strut(
		"DrlArmOut",
		Vector3.new(s * 4.05, 2.42, -9.75),
		Vector3.new(s * 4.2, 2.6, -9.1),
		0.1,
		0.05,
		HEAD_NEON
	)
	strut(
		"DrlArmIn",
		Vector3.new(s * 4.05, 2.42, -9.75),
		Vector3.new(s * 3.35, 2.6, -9.15),
		0.1,
		0.05,
		HEAD_NEON
	)
	part(
		"MainBeam",
		Vector3.new(0.4, 0.06, 0.35),
		CFrame.new(s * 3.25, 2.37, -9.6) * A(-math.atan2(0.42, 1.4), 0, 0),
		MAIN_BEAM
	)
	strut(
		"Indicator",
		Vector3.new(s * 3.4, 2.16, -10.42),
		Vector3.new(s * 4.2, 2.16, -10.42),
		0.05,
		0.08,
		AMBER
	)

	part("TailHousing", Vector3.new(1.9, 0.75, 0.1), CFrame.new(s * 3.65, 3.3, 11.15), TAIL_HOUSING)
	strut(
		"TailStem",
		Vector3.new(s * 2.8, 3.3, 11.22),
		Vector3.new(s * 3.55, 3.3, 11.22),
		0.05,
		0.1,
		TAIL
	)
	strut(
		"TailArmUp",
		Vector3.new(s * 3.55, 3.3, 11.22),
		Vector3.new(s * 4.5, 3.58, 11.22),
		0.05,
		0.1,
		TAIL
	)
	strut(
		"TailArmDown",
		Vector3.new(s * 3.55, 3.3, 11.22),
		Vector3.new(s * 4.5, 3.02, 11.22),
		0.05,
		0.1,
		TAIL
	)
end

-- Glass -------------------------------------------------------------------------------------

slab("Windshield", 0, 5.4, 0.1, 3.25, -5.6, 5.05, -1.7, GLASS)
part(
	"Wiper",
	Vector3.new(3.0, 0.05, 0.08),
	CFrame.new(-0.6, 3.36, -5.45) * A(0, math.rad(8), 0),
	TRIM_BLACK
)
for _, s in { -1, 1 } do
	local lean = A(0, 0, s * math.rad(32.5))
	part(
		"SideGlass",
		Vector3.new(0.08, 1.956, 4.0),
		CFrame.new(s * 3.125, 4.325, 0.3) * lean,
		GLASS
	)
	wedge(
		"SideGlassFront",
		Vector3.new(0.08, 1.956, 3.6),
		CFrame.new(s * 3.125, 4.325, -3.5) * lean,
		GLASS
	)
end

-- Wheels ------------------------------------------------------------------------------------

local function wheel(s: number, front: boolean)
	local zc = if front then FRONT_AXLE_Z else REAR_AXLE_Z
	local xc = if front then 3.96 else 3.80
	local yc = if front then 1.52 else 1.635
	local d = if front then 3.04 else 3.27
	local w = if front then 1.17 else 1.55
	local dRim = if front then 2.34 else 2.45
	local dDisc = if front then 1.80 else 1.72
	local xo = xc + w / 2
	local function at(dx: number, dy: number?, dz: number?): CFrame
		return CFrame.new(s * (xo + dx), yc + (dy or 0), zc + (dz or 0))
	end

	cyl("Tire", Vector3.new(w, d, d), CFrame.new(s * xc, yc, zc), TIRE)
	cyl("RimWell", Vector3.new(0.03, dRim, dRim), at(0.02), RIM)
	cyl("RimInner", Vector3.new(0.03, dRim - 0.25, dRim - 0.25), at(0.03), RIM_WELL)
	cyl("BrakeDisc", Vector3.new(0.03, dDisc, dDisc), at(0.05), DISC)
	-- Caliper wraps the disc edge at the upper rear, laid along the tangent.
	local ca = math.rad(45)
	local cr = dDisc / 2 - 0.12
	part(
		"Caliper",
		Vector3.new(0.1, 0.26, 0.75),
		at(0.12, cr * math.cos(ca), cr * math.sin(ca)) * A(ca, 0, 0),
		CALIPER
	)
	for k = 0, 4 do
		for _, dd in { -6, 6 } do
			local a = math.rad(k * 72 + dd)
			part(
				"Spoke",
				Vector3.new(0.06, 0.16, 0.82),
				at(0.2, 0.71 * math.cos(a), 0.71 * math.sin(a)) * A(a - math.pi / 2, 0, 0),
				RIM
			)
		end
	end
	cyl("Hub", Vector3.new(0.08, 0.5, 0.5), at(0.24), RIM_HUB)
	for k = 0, 4 do
		local a = math.rad(k * 72 + 36)
		cyl(
			"LugBolt",
			Vector3.new(0.03, 0.07, 0.07),
			at(0.29, 0.16 * math.cos(a), 0.16 * math.sin(a)),
			DISC
		)
	end
end

for _, s in { -1, 1 } do
	wheel(s, true)
	wheel(s, false)
end

-- Interior ----------------------------------------------------------------------------------

part("RearBulkhead", Vector3.new(5.8, 3.6, 0.15), CFrame.new(0, 2.55, 2.5), INTERIOR_DARK)
part("Dash", Vector3.new(5.6, 0.7, 1.6), CFrame.new(0, 2.95, -3.4), DASH_TOP)
part("DashLower", Vector3.new(5.6, 1.85, 0.8), CFrame.new(0, 1.68, -4.0), INTERIOR_DARK)
part("Binnacle", Vector3.new(1.2, 0.35, 0.5), CFrame.new(-1.25, 3.45, -2.9), INTERIOR_DARK)
part(
	"GaugeScreen",
	Vector3.new(1.0, 0.25, 0.03),
	CFrame.new(-1.25, 3.42, -2.64) * A(math.rad(-15), 0, 0),
	SCREEN
)
slab("CenterStack", 0, 0.4, 0.25, 2.6, -3.0, 1.4, -0.9, INTERIOR_DARK)
part(
	"StartCover",
	Vector3.new(0.15, 0.05, 0.12),
	CFrame.new(0, 2.3, -2.45) * A(math.rad(-30), 0, 0),
	TAIL
)
part("Tunnel", Vector3.new(0.4, 0.6, 3.2), CFrame.new(0, 1.05, -0.4), INTERIOR_DARK)

for _, s in { -1, 1 } do
	part("SeatCushion", Vector3.new(1.9, 0.3, 1.9), CFrame.new(s * 1.25, 0.9, 0.35), SEAT)
	slab("SeatBack", s * 1.25, 1.9, 0.35, 1.1, 1.15, 3.9, 1.65, SEAT)
	slab("SeatStripe", s * 1.25, 0.25, 0.04, 1.6, 1.0, 3.7, 1.4, STITCH)
end

local W = CFrame.new(-1.25, 2.95, -1.3) * A(math.rad(-25), 0, 0)
cyl("SteeringHub", Vector3.new(0.12, 0.45, 0.45), W * CYLINDER_Z, INTERIOR_DARK)
part("SteeringRimTop", Vector3.new(1.0, 0.12, 0.12), W * CFrame.new(0, 0.5, 0), INTERIOR_DARK)
part("SteeringRimBottom", Vector3.new(0.8, 0.12, 0.12), W * CFrame.new(0, -0.42, 0), INTERIOR_DARK)
part("SteeringRimLeft", Vector3.new(0.12, 0.9, 0.12), W * CFrame.new(-0.52, 0.03, 0), INTERIOR_DARK)
part("SteeringRimRight", Vector3.new(0.12, 0.9, 0.12), W * CFrame.new(0.52, 0.03, 0), INTERIOR_DARK)
part("SteeringColumn", Vector3.new(0.15, 0.15, 0.9), W * CFrame.new(0, 0, -0.5), INTERIOR_DARK)

return {
	name = "Lamborghini Aventador SVJ",
	speed = 140,
	turnRate = 2.5,
	footprint = Vector2.new(9.0, 22.4),
	collision = {
		{ size = Vector3.new(9.4, 2.2, 22.2), offset = CFrame.new(0, 2.3, 0) },
		{ size = Vector3.new(5.6, 1.7, 13.0), offset = CFrame.new(0, 4.25, 2.6) },
	},
	seats = { CFrame.new(-1.25, 0.55, 0.2), CFrame.new(1.25, 0.55, 0.2) },
	pieces = P,
}
