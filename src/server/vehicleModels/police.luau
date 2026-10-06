-- Police Interceptor: 2020+ Ford Police Interceptor Utility in black-and-white highway patrol livery.
-- Scale: 4 studs = 1 m. Front axle z -6.35, rear axle z 5.75, track 6.7, 18" black steel wheels.

local rgb = Color3.fromRGB
local M = Enum.Material
local A = CFrame.Angles
local V = Vector3.new
local CF = CFrame.new
local CYL = Enum.PartType.Cylinder
local CYLINDER_Z = A(0, math.rad(90), 0) -- cylinder axis along Z
local CYLINDER_Y = A(0, 0, math.rad(90)) -- cylinder axis along Y
-- WedgePart default: full bottom and full back (+Z) faces, right angle at (ymin, zmax).
local W_FWD = A(0, math.pi, 0) -- right angle at (ymin, zmin): slope rises toward -Z
local W_TOP_FRONT = A(math.pi, 0, 0) -- right angle at (ymax, zmin)
local W_TOP_BACK = A(0, 0, math.pi) -- right angle at (ymax, zmax)
local W_IN = A(0, -math.pi / 2, 0) -- size = (lengthZ, h, widthX); tall face -X, slope falls to +X
-- Plan-view chamfers: size = (height, widthX, lengthZ).
local W_PLAN_FRONT = A(0, 0, -math.pi / 2) -- solid at (xmin, zmax): cuts the outer-front corner
local W_PLAN_REAR = A(0, 0, math.pi / 2) * A(math.pi, 0, 0) -- solid at (xmin, zmin): cuts outer-rear

local PAINT_BLACK = rgb(18, 18, 20)
local PAINT_WHITE = rgb(242, 243, 245)
local GLOSS_BLACK = rgb(10, 10, 12)
local TRIM_BLACK = rgb(28, 28, 30)
local SEAM = rgb(8, 8, 9)
local RUBBER = rgb(22, 22, 22)
local GLASS = rgb(28, 34, 40)
local MIRROR_GLASS = rgb(150, 160, 170)
local TIRE = rgb(26, 26, 28)
local SIDEWALL = rgb(36, 36, 38)
local STEEL_WHEEL = rgb(35, 35, 38)
local STEEL_LIP = rgb(48, 48, 52)
local HOLE = rgb(10, 10, 11)
local CHROME = rgb(190, 192, 196)
local PUSHBAR = rgb(22, 22, 24)
local GRILLE_DARK = rgb(12, 12, 13)
local GRILLE_BAR = rgb(40, 40, 44)
local HEADLIGHT_HOUSING = rgb(20, 22, 25)
local HEADLIGHT = rgb(255, 244, 225)
local DRL = rgb(235, 245, 255)
local TAIL = rgb(200, 20, 20)
local TAIL_LENS = rgb(120, 10, 12)
local REFLECTOR = rgb(120, 15, 15)
local AMBER = rgb(255, 150, 20)
local LIGHT_RED = rgb(255, 30, 30)
local LIGHT_BLUE = rgb(30, 80, 255)
local LENS_CLEAR = rgb(220, 225, 230)
local BAR_BASE = rgb(30, 30, 32)
local INTERIOR = rgb(40, 40, 43)
local REAR_SEAT = rgb(38, 38, 40)
local DASH = rgb(32, 32, 35)
local STEERING = rgb(25, 25, 27)
local LAPTOP = rgb(55, 55, 58)
local SCREEN = rgb(90, 140, 200)
local CAGE = rgb(60, 60, 64)
local GUN_BOX = rgb(70, 72, 76)
local PLATE = rgb(235, 235, 230)
local EXHAUST = rgb(140, 140, 145)
local BORE = rgb(15, 15, 15)

local PAINT_REFLECT = 0.1
local WHITE_REFLECT = 0.08
local GLASS_ALPHA = 0.45

local FRONT_AXLE = -6.35
local REAR_AXLE = 5.75
local WHEEL_X = 3.35
local WHEEL_Y = 1.525
local SIDES = { -1, 1 }

-- Hood top line: 3.95 at the leading edge (z -9.9) rising to 4.35 at the cowl (z -4.3).
local HOOD_PITCH = -math.atan(0.4 / 5.6)
local function hoodY(z: number): number
	return 4.35 + (z + 4.3) * (0.4 / 5.6)
end

-- Greenhouse tumblehome: side glass plane runs from x 3.85 at the sill (y 4.5) to 3.25 at y 6.95.
local SILL_Y = 4.5
local TUMBLE = math.atan(0.6 / 2.45)
local GLASS_SLANT = 2.45 / math.cos(TUMBLE)
local function sidePlane(y: number, z: number, out: number?): CFrame
	local x = 3.85 - (y - SILL_Y) * math.tan(TUMBLE)
	return CF(x, y, z) * A(0, 0, TUMBLE) * CF(out or 0, 0, 0)
end

-- Windshield: base (y 4.4, z -4.3) to header (y 6.95, z -1.5).
local SCREEN_PITCH = -math.atan(2.55 / 2.8)
local SCREEN_LEN = math.sqrt(2.55 ^ 2 + 2.8 ^ 2)
local SCREEN_CF = CF(0, 5.675, -2.9) * A(SCREEN_PITCH, 0, 0)

-- Hatch glass: roof end (y 6.95, z 8.7) down to (y 4.95, z 9.8).
local HATCH_PITCH = math.atan(2.0 / 1.1)
local HATCH_LEN = math.sqrt(2.0 ^ 2 + 1.1 ^ 2)
local HATCH_CF = CF(0, 5.95, 9.25) * A(HATCH_PITCH, 0, 0)

local pieces = {}
local function add(p)
	table.insert(pieces, p)
end

-- Reflects a vehicle-space frame across the X = 0 plane.
local function reflect(cf: CFrame): CFrame
	local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = cf:GetComponents()
	return CFrame.new(-x, y, z, r00, -r01, -r02, -r10, r11, r12, -r20, r21, r22)
end

-- Adds a piece authored on the right side (+X) and its mirror image on the left.
local function mirror(p)
	add(p)
	local copy = table.clone(p)
	copy.offset = reflect(p.offset)
	add(copy)
end

local function part(name, size, offset, color, material, extra)
	local p = {
		name = name,
		size = size,
		offset = offset,
		color = color,
		material = material or M.SmoothPlastic,
	}
	if extra then
		for k, v in extra do
			p[k] = v
		end
	end
	return p
end

local function wedge(name, size, offset, color, material, extra)
	local p = part(name, size, offset, color, material, extra)
	p.class = "WedgePart"
	return p
end

local function cyl(name, size, offset, color, material, extra)
	local p = part(name, size, offset, color, material, extra)
	p.shape = CYL
	return p
end

local function black(name, size, offset)
	return part(name, size, offset, PAINT_BLACK, M.SmoothPlastic, { reflectance = PAINT_REFLECT })
end

local function white(name, size, offset)
	return part(name, size, offset, PAINT_WHITE, M.SmoothPlastic, { reflectance = WHITE_REFLECT })
end

local function glass(name, size, offset)
	return part(name, size, offset, GLASS, M.Glass, { transparency = GLASS_ALPHA })
end

local function neon(name, size, offset, color)
	return part(name, size, offset, color, M.Neon)
end

-- A beam of the given cross-section running from p0 to p1.
local function beam(name, p0: Vector3, p1: Vector3, w, h, color, material, extra)
	local d = p1 - p0
	local len = d.Magnitude
	local frame = CF((p0 + p1) / 2) * A(0, math.atan2(d.X, d.Z), 0) * A(-math.asin(d.Y / len), 0, 0)
	return part(name, V(w, h, len), frame, color, material, extra)
end

-- Body shell ----------------------------------------------------------------------------------
-- Core structure stays inside the tires (x +-2.8); side segments fill x 2.8..4.0.

add(part("FloorTub", V(5.6, 0.65, 19.6), CF(0, 1.575, 0), TRIM_BLACK, M.Plastic))
add(part("EngineBay", V(5.6, 2.0, 5.5), CF(0, 2.9, -7.05), TRIM_BLACK, M.Plastic))
add(part("CargoTub", V(5.6, 0.85, 4.8), CF(0, 2.325, 7.4), TRIM_BLACK, M.Plastic))
add(part("Firewall", V(5.6, 0.6, 0.2), CF(0, 4.1, -4.4), TRIM_BLACK, M.Plastic))

-- Front end
add(black("FrontFascia", V(6.8, 1.6, 0.6), CF(0, 2.1, -9.8)))
add(black("FrontUpperNose", V(6.8, 1.05, 0.5), CF(0, 3.425, -9.8)))
mirror(
	wedge(
		"FasciaCornerChamfer",
		V(2.6, 0.6, 0.6),
		CF(3.7, 2.6, -9.8) * W_PLAN_FRONT,
		PAINT_BLACK,
		M.SmoothPlastic,
		{ reflectance = PAINT_REFLECT }
	)
)
mirror(black("FrontCorner", V(1.2, 2.6, 1.3), CF(3.4, 2.6, -8.85)))
mirror(black("FrontArchTop", V(1.2, 0.45, 3.7), CF(3.4, 3.675, FRONT_AXLE)))
mirror(
	wedge(
		"FrontArchWedgeF",
		V(1.2, 1.0, 1.0),
		CF(3.4, 2.95, FRONT_AXLE - 1.35) * W_TOP_FRONT,
		PAINT_BLACK,
		M.SmoothPlastic,
		{ reflectance = PAINT_REFLECT }
	)
)
mirror(
	wedge(
		"FrontArchWedgeR",
		V(1.2, 1.0, 1.0),
		CF(3.4, 2.95, FRONT_AXLE + 1.35) * W_TOP_BACK,
		PAINT_BLACK,
		M.SmoothPlastic,
		{ reflectance = PAINT_REFLECT }
	)
)
mirror(black("FenderBehindArch", V(1.2, 2.85, 0.2), CF(3.4, 2.775, -4.4)))
mirror(
	black(
		"FenderTop",
		V(0.42, 0.5, 5.3),
		CF(3.79, hoodY(-6.95) + 0.02 - 0.25, -6.95) * A(HOOD_PITCH, 0, 0)
	)
)
add(black("Hood", V(7.16, 0.2, 5.62), CF(0, hoodY(-7.1) - 0.1, -7.1) * A(HOOD_PITCH, 0, 0)))
add(
	black(
		"HoodPowerBulge",
		V(3.0, 0.08, 4.6),
		CF(0, hoodY(-6.9) + 0.03, -6.9) * A(HOOD_PITCH, 0, 0)
	)
)
add(part("Cowl", V(7.0, 0.15, 0.5), CF(0, 4.36, -4.3), TRIM_BLACK, M.Plastic))

-- Doors (white) and rockers
mirror(part("Rocker", V(1.2, 0.35, 8.4), CF(3.4, 1.375, -0.3), TRIM_BLACK, M.Plastic))
mirror(white("FrontDoor", V(1.2, 2.95, 5.7), CF(3.4, 3.025, -1.45)))
mirror(white("RearDoorLower", V(1.2, 2.95, 2.5), CF(3.4, 3.025, 2.65)))
mirror(white("RearDoorOverArch", V(1.2, 1.05, 1.1), CF(3.4, 3.975, 4.45)))
mirror(
	wedge(
		"RearDoorArchWedge",
		V(1.2, 1.0, 1.0),
		CF(3.4, 2.95, REAR_AXLE - 1.35) * W_TOP_FRONT,
		PAINT_WHITE,
		M.SmoothPlastic,
		{ reflectance = WHITE_REFLECT }
	)
)

-- Rear quarters (black)
mirror(black("RearArchTop", V(1.2, 1.2, 2.6), CF(3.4, 4.05, 6.3)))
mirror(
	wedge(
		"RearArchWedgeR",
		V(1.2, 1.0, 1.0),
		CF(3.4, 2.95, REAR_AXLE + 1.35) * W_TOP_BACK,
		PAINT_BLACK,
		M.SmoothPlastic,
		{ reflectance = PAINT_REFLECT }
	)
)
mirror(black("RearCorner", V(1.2, 3.35, 2.0), CF(3.4, 2.975, 8.6)))
mirror(black("RearCornerInner", V(0.2, 3.35, 0.5), CF(3.5, 2.975, 9.85)))
mirror(
	wedge(
		"RearCornerChamfer",
		V(3.35, 0.4, 0.5),
		CF(3.8, 2.975, 9.85) * W_PLAN_REAR,
		PAINT_BLACK,
		M.SmoothPlastic,
		{ reflectance = PAINT_REFLECT }
	)
)
add(black("Tailgate", V(6.8, 2.6, 0.3), CF(0, 3.7, 9.9)))
add(black("TailgateLip", V(6.8, 0.2, 0.35), CF(0, 4.9, 9.875)))
add(part("RearBumper", V(7.2, 1.2, 0.55), CF(0, 1.8, 9.875), TRIM_BLACK, M.Plastic))
mirror(
	wedge(
		"RearBumperCorner",
		V(1.2, 0.4, 0.55),
		CF(3.8, 1.8, 9.875) * W_PLAN_REAR,
		TRIM_BLACK,
		M.Plastic
	)
)
add(part("RearBumperStepPad", V(3.0, 0.06, 0.4), CF(0, 2.42, 9.95), RUBBER, M.Fabric))
add(part("FrontLowerValance", V(6.6, 0.35, 0.4), CF(0, 1.375, -9.85), TRIM_BLACK, M.Plastic))

-- Black cladding: rockers and arch moldings
mirror(part("RockerCladding", V(0.06, 0.6, 8.4), CF(4.03, 1.55, -0.3), TRIM_BLACK, M.Plastic))
for _, axle in { FRONT_AXLE, REAR_AXLE } do
	mirror(part("ArchMoldingTop", V(0.06, 0.18, 1.9), CF(4.03, 3.54, axle), TRIM_BLACK, M.Plastic))
	mirror(
		part(
			"ArchMoldingF",
			V(0.08, 0.18, 1.35),
			CF(4.03, 2.95, axle - 1.35) * A(math.rad(-45), 0, 0) * CF(0, 0.05, 0),
			TRIM_BLACK,
			M.Plastic
		)
	)
	mirror(
		part(
			"ArchMoldingR",
			V(0.08, 0.18, 1.35),
			CF(4.03, 2.95, axle + 1.35) * A(math.rad(45), 0, 0) * CF(0, 0.05, 0),
			TRIM_BLACK,
			M.Plastic
		)
	)
end

-- Greenhouse frame
local pillarBase = V(3.78, 4.42, -4.3)
local pillarTop = V(3.22, 6.98, -1.5)
mirror(
	beam(
		"APillar",
		pillarBase,
		pillarTop,
		0.3,
		0.22,
		PAINT_BLACK,
		M.SmoothPlastic,
		{ reflectance = PAINT_REFLECT }
	)
)
add(black("WindshieldHeader", V(6.5, 0.15, 0.3), CF(0, 7.025, -1.55)))
add(white("Roof", V(6.5, 0.15, 10.2), CF(0, 7.025, 3.6)))
mirror(
	wedge(
		"RoofRailChamfer",
		V(10.2, 0.15, 0.2),
		CF(3.35, 7.025, 3.6) * W_IN,
		PAINT_WHITE,
		M.SmoothPlastic,
		{
			reflectance = WHITE_REFLECT,
		}
	)
)
mirror(part("DripRail", V(0.1, 0.12, 10.0), CF(3.3, 6.89, 3.6), TRIM_BLACK, M.Plastic))
mirror(
	part(
		"BPillar",
		V(0.08, GLASS_SLANT, 0.4),
		sidePlane(5.725, 1.4, 0.05),
		GLOSS_BLACK,
		M.SmoothPlastic,
		{
			reflectance = 0.15,
		}
	)
)
mirror(
	part(
		"CPillar",
		V(0.08, GLASS_SLANT, 0.4),
		sidePlane(5.725, 4.8, 0.05),
		GLOSS_BLACK,
		M.SmoothPlastic,
		{
			reflectance = 0.15,
		}
	)
)
mirror(
	part(
		"DPillar",
		V(0.08, GLASS_SLANT, 0.45),
		sidePlane(5.725, 8.45, 0.05),
		GLOSS_BLACK,
		M.SmoothPlastic,
		{
			reflectance = 0.15,
		}
	)
)
mirror(
	wedge(
		"DPillarWrap",
		V(0.75, 2.35, 1.2),
		sidePlane(5.775, 9.2, -0.35) * W_FWD,
		GLOSS_BLACK,
		M.SmoothPlastic,
		{ reflectance = 0.15 }
	)
)
mirror(part("SillTrim", V(0.1, 0.08, 12.6), CF(3.86, 4.5, 2.0), TRIM_BLACK, M.Plastic))
add(
	wedge(
		"RoofSpoiler",
		V(6.2, 0.2, 0.7),
		CF(0, 7.0, 9.0),
		PAINT_BLACK,
		M.SmoothPlastic,
		{ reflectance = PAINT_REFLECT }
	)
)

-- Panel seams, handles, mirrors, wipers --------------------------------------------------------

mirror(part("SeamFenderDoor", V(0.05, 2.95, 0.05), CF(4.025, 3.025, -4.3), SEAM))
mirror(part("SeamFrontRearDoor", V(0.05, 2.95, 0.05), CF(4.025, 3.025, 1.4), SEAM))
mirror(part("SeamRearDoorQuarter", V(0.05, 1.05, 0.05), CF(4.025, 3.975, 5.0), SEAM))
add(part("SeamHoodFront", V(6.8, 0.05, 0.05), CF(0, 3.96, -9.93), SEAM))
mirror(part("ShoulderCrease", V(0.05, 0.05, 13.0), CF(4.025, 4.1, 0.5), SEAM))
for _, z in { 0.4, 3.9 } do
	mirror(
		part(
			"DoorHandle",
			V(0.08, 0.16, 0.7),
			CF(4.05, 4.15, z),
			GLOSS_BLACK,
			M.SmoothPlastic,
			{ reflectance = 0.15 }
		)
	)
end
mirror(black("MirrorHousing", V(0.8, 0.55, 0.4), CF(4.35, 4.85, -3.6)))
mirror(
	part(
		"MirrorGlass",
		V(0.65, 0.42, 0.03),
		CF(4.35, 4.85, -3.385),
		MIRROR_GLASS,
		M.Glass,
		{ reflectance = 0.3 }
	)
)
mirror(part("MirrorStalk", V(0.4, 0.15, 0.25), CF(4.05, 4.65, -3.6), TRIM_BLACK, M.Plastic))
add(part("WiperL", V(0.06, 0.06, 2.6), CF(-1.4, 4.5, -4.1) * A(0, math.rad(80), 0), SEAM))
add(part("WiperR", V(0.06, 0.06, 2.6), CF(1.3, 4.5, -4.1) * A(0, math.rad(80), 0), SEAM))
add(
	part(
		"RearWiper",
		V(0.05, 0.05, 1.5),
		HATCH_CF * CF(0.4, 0.06, 0.55) * A(0, math.rad(70), 0),
		SEAM
	)
)
add(part("FuelDoor", V(0.04, 0.5, 0.5), CF(-4.025, 4.0, 7.2), SEAM))

-- Glass ----------------------------------------------------------------------------------------

add(glass("Windshield", V(6.6, 0.08, SCREEN_LEN), SCREEN_CF))
mirror(glass("FrontSideGlass", V(0.08, GLASS_SLANT, 2.6), sidePlane(5.725, -0.1)))
mirror(
	wedge(
		"FrontSideGlassTri",
		V(0.08, GLASS_SLANT, 2.8),
		sidePlane(5.725, -2.8),
		GLASS,
		M.Glass,
		{ transparency = GLASS_ALPHA }
	)
)
mirror(glass("RearSideGlass", V(0.08, GLASS_SLANT, 3.0), sidePlane(5.725, 3.1)))
mirror(glass("QuarterGlass", V(0.08, GLASS_SLANT, 3.25), sidePlane(5.725, 6.625)))
add(glass("HatchGlass", V(5.8, 0.08, HATCH_LEN), HATCH_CF))
add(neon("ThirdBrakeLamp", V(1.0, 0.08, 0.08), CF(0, 6.9, 9.15), TAIL))

-- Front lights and grille ---------------------------------------------------------------------

add(part("GrilleSurround", V(4.9, 1.45, 0.15), CF(0, 3.05, -10.12), TRIM_BLACK, M.Plastic))
add(part("GrilleInset", V(4.6, 1.25, 0.1), CF(0, 3.05, -10.15), GRILLE_DARK))
for i = 0, 4 do
	add(part("GrilleBar", V(4.6, 0.08, 0.06), CF(0, 2.55 + i * 0.25, -10.22), GRILLE_BAR, M.Metal))
end
add(neon("GrilleStrobeRed", V(0.4, 0.12, 0.05), CF(-1.6, 3.425, -10.25), LIGHT_RED))
add(neon("GrilleStrobeBlue", V(0.4, 0.12, 0.05), CF(1.6, 3.425, -10.25), LIGHT_BLUE))
mirror(part("HeadlightHousing", V(1.0, 0.45, 0.2), CF(2.95, 3.65, -10.1), HEADLIGHT_HOUSING))
mirror(neon("HeadlightLED", V(0.8, 0.15, 0.05), CF(2.95, 3.74, -10.215), HEADLIGHT))
mirror(neon("DRL", V(0.95, 0.06, 0.05), CF(2.95, 3.5, -10.215), DRL))
mirror(
	part(
		"HeadlightWrap",
		V(0.82, 0.45, 0.06),
		CF(3.7, 3.65, -9.8) * A(0, math.rad(-45), 0) * CF(0, 0, -0.04),
		HEADLIGHT_HOUSING,
		M.Glass,
		{ reflectance = 0.2 }
	)
)
mirror(neon("AmberMarker", V(0.05, 0.15, 0.4), CF(4.03, 3.3, -9.0), AMBER))
add(part("LowerGrille", V(3.6, 0.6, 0.08), CF(0, 1.75, -10.13), GRILLE_DARK))
mirror(cyl("FogLamp", V(0.06, 0.35, 0.35), CF(2.7, 1.75, -10.12) * CYLINDER_Z, HEADLIGHT, M.Neon))
mirror(
	cyl("FogBezel", V(0.04, 0.5, 0.5), CF(2.7, 1.75, -10.11) * CYLINDER_Z, TRIM_BLACK, M.Plastic)
)

-- Push bumper
mirror(part("PushBarUpright", V(0.3, 2.4, 0.3), CF(1.2, 2.75, -10.75), PUSHBAR, M.Metal))
add(part("PushBarLower", V(3.9, 0.45, 0.3), CF(0, 2.15, -10.8), PUSHBAR, M.Metal))
add(part("PushBarUpper", V(3.9, 0.45, 0.3), CF(0, 3.55, -10.8), PUSHBAR, M.Metal))
add(part("PushBarPadLower", V(3.7, 0.3, 0.06), CF(0, 2.15, -10.97), RUBBER, M.Fabric))
add(part("PushBarPadUpper", V(3.7, 0.3, 0.06), CF(0, 3.55, -10.97), RUBBER, M.Fabric))
mirror(part("PushBarMount", V(0.25, 0.25, 0.7), CF(1.2, 1.7, -10.4), PUSHBAR, M.Metal))
add(neon("PushBarLedRed", V(0.2, 0.5, 0.05), CF(-1.2, 2.85, -10.92), LIGHT_RED))
add(neon("PushBarLedBlue", V(0.2, 0.5, 0.05), CF(1.2, 2.85, -10.92), LIGHT_BLUE))

-- Spotlight on the driver A-pillar
add(
	cyl(
		"SpotlightPost",
		V(0.6, 0.1, 0.1),
		CF(-3.95, 4.85, -3.85) * CYLINDER_Y,
		CHROME,
		M.Metal,
		{ reflectance = 0.3 }
	)
)
add(
	cyl(
		"SpotlightCan",
		V(0.55, 0.45, 0.45),
		CF(-3.95, 5.25, -3.95) * CYLINDER_Z,
		CHROME,
		M.Metal,
		{ reflectance = 0.3 }
	)
)
add(
	cyl(
		"SpotlightLens",
		V(0.04, 0.38, 0.38),
		CF(-3.95, 5.25, -4.24) * CYLINDER_Z,
		HEADLIGHT,
		M.Neon
	)
)
add(part("SpotlightHandle", V(0.35, 0.06, 0.06), CF(-3.7, 5.0, -3.75), TRIM_BLACK))

-- Lightbar
add(part("LightbarBase", V(5.6, 0.1, 1.1), CF(0, 7.25, 0.3), BAR_BASE))
mirror(part("LightbarFoot", V(0.4, 0.1, 1.0), CF(2.6, 7.15, 0.3), BAR_BASE))
mirror(part("LightbarEndCap", V(0.2, 0.32, 1.1), CF(2.85, 7.46, 0.3), GLOSS_BLACK))
add(
	part(
		"LightbarLens",
		V(5.5, 0.3, 1.0),
		CF(0, 7.45, 0.3),
		LENS_CLEAR,
		M.Glass,
		{ transparency = 0.55 }
	)
)
for _, x in { 0.5, 1.35, 2.2 } do
	for _, z in { 0.05, 0.55 } do
		add(neon("LightbarRed", V(0.75, 0.18, 0.35), CF(-x, 7.45, z), LIGHT_RED))
		add(neon("LightbarBlue", V(0.75, 0.18, 0.35), CF(x, 7.45, z), LIGHT_BLUE))
	end
end
add(neon("TakedownLamp", V(0.2, 0.16, 0.08), CF(0, 7.45, -0.1), HEADLIGHT))

-- Antennas
add(cyl("AntennaPuck", V(0.12, 0.4, 0.4), CF(0, 7.16, 3.0) * CYLINDER_Y, GLOSS_BLACK))
add(cyl("AntennaPuck", V(0.12, 0.4, 0.4), CF(-1.5, 7.16, 5.5) * CYLINDER_Y, GLOSS_BLACK))
add(cyl("AntennaPuck", V(0.12, 0.4, 0.4), CF(1.5, 7.16, 5.5) * CYLINDER_Y, GLOSS_BLACK))
add(cyl("AntennaWhip", V(1.6, 0.04, 0.04), CF(0, 7.9, 7.0) * CYLINDER_Y, GLOSS_BLACK))
add(cyl("AntennaWhipBase", V(0.1, 0.15, 0.15), CF(0, 7.15, 7.0) * CYLINDER_Y, GLOSS_BLACK))

-- Rear lights, plate, exhaust -----------------------------------------------------------------

mirror(
	part(
		"TailLampHousing",
		V(1.6, 0.4, 0.06),
		CF(3.0, 4.45, 10.07),
		TAIL_LENS,
		M.Glass,
		{ transparency = 0.3 }
	)
)
mirror(neon("TailLamp", V(1.4, 0.18, 0.05), CF(3.0, 4.48, 10.08), TAIL))
mirror(
	part(
		"TailLampCorner",
		V(0.5, 0.4, 0.06),
		CF(3.8, 4.45, 9.85) * A(0, math.rad(-45), 0) * CF(0, 0, 0.03),
		TAIL_LENS,
		M.Glass,
		{ transparency = 0.3 }
	)
)
mirror(neon("TailLampWrap", V(0.06, 0.18, 0.9), CF(4.02, 4.45, 9.0), TAIL))
mirror(neon("ReverseLamp", V(0.3, 0.12, 0.04), CF(2.45, 4.36, 10.09), DRL))
mirror(neon("BumperReflector", V(0.4, 0.1, 0.05), CF(3.0, 2.0, 10.17), REFLECTOR))
add(neon("RearStrobeRed", V(0.6, 0.12, 0.05), CF(-1.2, 6.7, 8.88), LIGHT_RED))
add(neon("RearStrobeBlue", V(0.6, 0.12, 0.05), CF(1.2, 6.7, 8.88), LIGHT_BLUE))
add(part("PlateRecess", V(2.1, 0.8, 0.03), CF(0, 3.35, 10.06), TRIM_BLACK, M.Plastic))
add(part("LicensePlate", V(1.9, 0.6, 0.05), CF(0, 3.35, 10.09), PLATE))
mirror(
	cyl(
		"ExhaustTip",
		V(0.5, 0.35, 0.35),
		CF(2.6, 1.35, 10.15) * CYLINDER_Z,
		EXHAUST,
		M.Metal,
		{ reflectance = 0.2 }
	)
)
mirror(cyl("ExhaustBore", V(0.05, 0.26, 0.26), CF(2.6, 1.35, 10.41) * CYLINDER_Z, BORE))

-- Wheels: 255/60R18 on black steel wheels ------------------------------------------------------

for _, s in SIDES do
	for _, az in { FRONT_AXLE, REAR_AXLE } do
		local function at(x: number): CFrame
			return CF(s * x, WHEEL_Y, az)
		end
		add(cyl("Tire", V(1.02, 3.05, 3.05), at(WHEEL_X), TIRE))
		add(cyl("Sidewall", V(0.03, 2.8, 2.8), at(3.875), SIDEWALL))
		add(cyl("RimLip", V(0.04, 1.95, 1.95), at(3.905), STEEL_LIP, M.Metal))
		add(
			cyl(
				"RimFace",
				V(0.03, 1.6, 1.6),
				at(3.93),
				STEEL_WHEEL,
				M.Metal,
				{ reflectance = 0.05 }
			)
		)
		for i = 0, 5 do
			local a = math.rad(i * 60 + 30)
			local offset = CF(s * 3.955, WHEEL_Y + 0.56 * math.sin(a), az + 0.56 * math.cos(a))
			add(cyl("CoolingHole", V(0.03, 0.28, 0.28), offset, HOLE))
		end
		add(
			cyl("CenterCap", V(0.06, 0.55, 0.55), at(3.965), CHROME, M.Metal, { reflectance = 0.3 })
		)
		for i = 0, 4 do
			local a = math.rad(i * 72)
			local offset = CF(s * 3.96, WHEEL_Y + 0.37 * math.sin(a), az + 0.37 * math.cos(a))
			add(cyl("LugNut", V(0.05, 0.1, 0.1), offset, CHROME, M.Metal))
		end
	end
end

-- Interior ------------------------------------------------------------------------------------

add(part("Dashboard", V(5.6, 0.75, 1.4), CF(0, 4.025, -3.6), DASH))
add(wedge("DashTop", V(5.6, 0.3, 0.7), CF(0, 4.55, -3.6) * W_FWD, DASH))
add(part("InstrumentHood", V(1.4, 0.25, 0.5), CF(-1.6, 4.55, -3.0), DASH))
local wheelCf = CF(-1.6, 4.45, -2.2) * A(math.rad(-25), 0, 0) * CYLINDER_Z
add(cyl("SteeringRim", V(0.12, 1.4, 1.4), wheelCf, STEERING))
add(cyl("SteeringHub", V(0.15, 0.5, 0.5), wheelCf, STEERING))
add(cyl("SteeringColumn", V(0.9, 0.22, 0.22), wheelCf * CF(-0.5, 0, 0), STEERING))
add(part("CenterConsole", V(1.2, 0.8, 3.4), CF(0, 2.3, -1.5), INTERIOR, M.Fabric))
add(part("RadioStack", V(0.8, 0.6, 0.3), CF(0, 3.6, -3.0), GLOSS_BLACK))
add(part("LaptopPole", V(0.12, 0.9, 0.12), CF(0.2, 3.15, -2.4), CAGE, M.Metal))
add(part("LaptopBase", V(1.0, 0.08, 0.75), CF(0.2, 3.64, -2.4), LAPTOP))
local screenCf = CF(0.2, 3.98, -2.0) * A(math.rad(-15), 0, 0)
add(part("LaptopLid", V(1.0, 0.7, 0.05), screenCf, LAPTOP))
add(neon("LaptopScreen", V(0.9, 0.6, 0.02), screenCf * CF(0, 0, -0.035), SCREEN))

for _, x in { -1.6, 1.6 } do
	add(part("FrontSeatCushion", V(1.8, 0.4, 1.9), CF(x, 2.35, -0.6), INTERIOR, M.Fabric))
	add(
		part(
			"FrontSeatBack",
			V(1.8, 2.3, 0.35),
			CF(x, 3.75, 0.3) * A(math.rad(-10), 0, 0),
			INTERIOR,
			M.Fabric
		)
	)
	add(part("FrontHeadrest", V(1.0, 0.6, 0.3), CF(x, 5.2, 0.5), INTERIOR, M.Fabric))
end

-- Prisoner partition behind the front seats
for _, y in { 4.6, 6.8 } do
	add(part("CageRail", V(5.8, 0.12, 0.12), CF(0, y, 0.85), CAGE, M.Metal))
end
for _, x in { -1.5, 1.5 } do
	add(part("CagePost", V(0.12, 2.1, 0.12), CF(x, 5.7, 0.85), CAGE, M.Metal))
end
add(
	part(
		"CagePane",
		V(5.6, 2.1, 0.05),
		CF(0, 5.7, 0.85),
		LENS_CLEAR,
		M.Glass,
		{ transparency = 0.6 }
	)
)
add(part("CageLowerPanel", V(5.6, 1.5, 0.08), CF(0, 3.85, 0.95), CAGE, M.Metal))

add(part("RearBenchCushion", V(5.4, 0.4, 1.9), CF(0, 2.35, 3.3), REAR_SEAT))
add(part("RearBenchBack", V(5.4, 2.3, 0.35), CF(0, 3.75, 4.35) * A(math.rad(-10), 0, 0), REAR_SEAT))
for _, x in { -1.6, 1.6 } do
	add(part("RearHeadrest", V(1.0, 0.6, 0.3), CF(x, 5.2, 4.55), REAR_SEAT))
end
add(part("CargoFloor", V(5.6, 0.1, 4.6), CF(0, 2.8, 7.4), RUBBER, M.Fabric))
add(part("GunLockBox", V(4.0, 0.8, 1.5), CF(0, 3.25, 7.6), GUN_BOX, M.Metal))

return {
	name = "Police Interceptor",
	-- Real: 240 km/h, 0-100 km/h in 5.8 s, brakes 0.95 g, coasts 0.2 g (VehicleDefaults maps them).
	speed = 81,
	acceleration = 10.4,
	braking = 16.2,
	coasting = 5.7,
	turnRate = 2.4,
	footprint = Vector2.new(7.8, 20.0),
	collision = {
		{ size = V(7.8, 3.2, 20.0), offset = CF(0, 2.8, 0) },
		{ size = V(6.6, 2.5, 13.0), offset = CF(0, 5.65, 2.2) },
	},
	seats = {
		CF(-1.6, 2.1, -0.6), -- driver (left-hand drive)
		CF(1.6, 2.1, -0.6),
		CF(-1.6, 2.1, 3.3),
		CF(1.6, 2.1, 3.3),
	},
	pieces = pieces,
}
