-- Bulldozer: Caterpillar D9 high-drive crawler dozer with semi-U blade, ROPS cab and single-shank ripper.
-- Scale: 4 studs = 1 m.

local rgb = Color3.fromRGB
local M = Enum.Material
local A = CFrame.Angles
local V = Vector3.new
local CF = CFrame.new
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball
local WEDGE = "WedgePart"

-- Rotations. Cylinder axis is local X; WedgePart default has its right angle at (ymin, zmax).
local CYLINDER_Y = A(0, 0, math.rad(90))
local RISE_FWD = A(0, math.pi, 0) -- wedge slope rises toward -Z
local SIDE_L = A(0, math.pi / 2, 0) -- size (lenZ, h, widthX); high side toward +X
local SIDE_R = A(0, -math.pi / 2, 0) -- size (lenZ, h, widthX); high side toward -X

-- Palette: color, material, reflectance, transparency.
local YELLOW = { c = rgb(255, 199, 18), m = M.SmoothPlastic, r = 0.06 }
local BLACK = { c = rgb(32, 32, 34), m = M.Metal }
local TRACK = { c = rgb(52, 50, 47), m = M.Metal }
local GROUSER = { c = rgb(78, 74, 68), m = M.Metal }
local IDLER = { c = rgb(44, 43, 41), m = M.Metal }
local EDGE = { c = rgb(70, 68, 64), m = M.Metal }
local EDGE_BRIGHT = { c = rgb(150, 147, 140), m = M.Metal, r = 0.1 }
local DARK = { c = rgb(38, 37, 36), m = M.Metal }
local CHROME = { c = rgb(210, 212, 215), m = M.Metal, r = 0.3 }
local GRILLE = { c = rgb(18, 18, 18), m = M.Metal }
local WALKWAY = { c = rgb(72, 72, 74), m = M.DiamondPlate }
local EXHAUST = { c = rgb(30, 29, 28), m = M.Metal }
local RUST = { c = rgb(90, 62, 40), m = M.CorrodedMetal }
local CAB_FRAME = { c = rgb(26, 26, 28), m = M.SmoothPlastic }
local GLASS = { c = rgb(70, 90, 100), m = M.Glass, t = 0.45 }
local SEAT = { c = rgb(42, 42, 44), m = M.Fabric }
local INTERIOR = { c = rgb(20, 30, 40), m = M.SmoothPlastic }
local HEAD = { c = rgb(255, 244, 214), m = M.Neon }
local TAIL = { c = rgb(210, 25, 18), m = M.Neon }
local AMBER = { c = rgb(255, 150, 0), m = M.Neon }

local pieces = {}

local function add(name, class, shape, size, offset, p)
	table.insert(pieces, {
		name = name,
		class = class,
		shape = shape,
		size = size,
		offset = offset,
		color = p.c,
		material = p.m,
		reflectance = p.r,
		transparency = p.t,
	})
end

local function block(name, size, offset, p)
	add(name, "Part", nil, size, offset, p)
end

local function wedge(name, size, offset, p)
	add(name, WEDGE, nil, size, offset, p)
end

local function cyl(name, size, offset, p)
	add(name, "Part", CYL, size, offset, p)
end

local function ball(name, d, offset, p)
	add(name, "Part", BALL, V(d, d, d), offset, p)
end

-- Block with local -Z running a -> b and local +Y world-up-ish. Built from yaw and pitch; the
-- preview runtime's CFrame.lookAt mirrors the pitch of rear-pointing targets.
local function beamCF(a: Vector3, b: Vector3)
	local d = (b - a).Unit
	local yaw = math.atan2(-d.X, -d.Z)
	local pitch = math.asin(d.Y)
	return CF((a + b) / 2) * A(0, yaw, 0) * A(pitch, 0, 0)
end

-- Cylinder with local X running a -> b.
local function rodCF(a: Vector3, b: Vector3)
	return beamCF(a, b) * A(0, math.rad(90), 0)
end

local function rod(name, a, b, d, p)
	cyl(name, V((b - a).Magnitude, d, d), rodCF(a, b), p)
end

local function beam(name, w, h, a, b, p)
	block(name, V(w, h, (b - a).Magnitude), beamCF(a, b), p)
end

---------------------------------------------------------------------------------------------------
-- Undercarriage: high-drive triangular track, one per side.
---------------------------------------------------------------------------------------------------

local SHOE_W = 2.44
local GROUSER_SIZE = V(SHOE_W, 0.25, 0.3)

for _, sx in { -1, 1 } do
	local x = 4.5 * sx

	-- Bottom run.
	block("TrackBottomRun", V(SHOE_W, 0.35, 13.9), CF(x, 0.425, -0.15), TRACK)
	for i = 0, 12 do
		block("TrackGrouserBottom", GROUSER_SIZE, CF(x, 0.125, -6.6 + i * 1.05), GROUSER)
	end

	-- Top run: front idler to sprocket.
	local topRun = beamCF(V(x, 4.12, -7.74), V(x, 7.88, 3.72))
	block("TrackTopRun", V(SHOE_W, 0.35, 12.06), topRun, TRACK)
	for i = 0, 10 do
		block("TrackGrouserTop", GROUSER_SIZE, topRun * CF(0, 0.3, -5.25 + i * 1.05), GROUSER)
	end

	-- Rear run: sprocket down to rear idler.
	local rearRun = beamCF(V(x, 7.32, 6.46), V(x, 3.72, 8.13))
	block("TrackRearRun", V(SHOE_W, 0.35, 3.97), rearRun, TRACK)
	for i = 0, 3 do
		block("TrackGrouserRear", GROUSER_SIZE, rearRun * CF(0, 0.3, -1.5 + i * 1.0), GROUSER)
	end

	-- Wraps around the idlers and the sprocket.
	cyl("FrontIdlerWrap", V(SHOE_W, 4.4, 4.4), CF(x, 2.2, -7.1), TRACK)
	cyl("RearIdlerWrap", V(SHOE_W, 4.4, 4.4), CF(x, 2.2, 6.8), TRACK)
	cyl("SprocketWrap", V(SHOE_W, 6.0, 6.0), CF(x, 5.2, 4.6), TRACK)

	-- Idlers.
	for _, z in { -7.1, 6.8 } do
		cyl("IdlerDisc", V(2.54, 3.4, 3.4), CF(x, 2.2, z), IDLER)
		cyl("IdlerHub", V(2.66, 1.4, 1.4), CF(x, 2.2, z), BLACK)
	end

	-- Sprocket and final drive.
	local sprocket = CF(x, 5.2, 4.6)
	cyl("SprocketDisc", V(2.54, 5.0, 5.0), sprocket, IDLER)
	cyl("FinalDriveHub", V(2.7, 2.4, 2.4), sprocket, BLACK)
	for i = 0, 5 do
		block(
			"SprocketTooth",
			V(2.6, 0.6, 0.7),
			sprocket * A(i * math.pi / 3, 0, 0) * CF(0, 2.55, 0),
			BLACK
		)
	end

	-- Roller frame and bottom rollers.
	for i = 0, 6 do
		cyl("BottomRoller", V(2.0, 1.1, 1.1), CF(x, 1.15, -5.4 + i * 1.8), TRACK)
	end
	block("TrackRollerFrame", V(2.0, 1.6, 11.6), CF(x, 2.3, -0.15), BLACK)
	block("RockGuard", V(0.12, 1.0, 10.0), CF(x + 1.06 * sx, 1.4, -0.15), BLACK)
end

---------------------------------------------------------------------------------------------------
-- Tractor body: frame, hood, radiator guard, fenders, fuel tank.
---------------------------------------------------------------------------------------------------

block("BellyGuard", V(6.0, 0.4, 16.0), CF(0, 2.05, -0.5), BLACK)
block("MainCase", V(6.4, 2.0, 17.6), CF(0, 3.25, 0), BLACK)

-- Hood: body to y 9.0, top slab and edge chamfers to 9.6.
block("HoodBody", V(5.8, 5.0, 8.2), CF(0, 6.5, -4.9), YELLOW)
block("HoodTop", V(4.6, 0.6, 7.6), CF(0, 9.3, -4.6), YELLOW)
wedge("HoodChamferL", V(7.6, 0.6, 0.6), CF(-2.6, 9.3, -4.6) * SIDE_L, YELLOW)
wedge("HoodChamferR", V(7.6, 0.6, 0.6), CF(2.6, 9.3, -4.6) * SIDE_R, YELLOW)
wedge("HoodChamferFront", V(5.8, 0.6, 0.6), CF(0, 9.3, -8.7), YELLOW)

-- Louvered engine side doors.
for _, sx in { -1, 1 } do
	block("LouverInset", V(0.06, 3.0, 5.8), CF(2.93 * sx, 6.5, -4.7), GRILLE)
	for i = 0, 4 do
		block("LouverSlat", V(0.12, 0.14, 5.6), CF(2.96 * sx, 5.25 + i * 0.6, -4.7), YELLOW)
	end
	block("DoorSeam", V(0.04, 4.6, 0.08), CF(2.92 * sx, 6.6, -1.5), GRILLE)
end

-- Radiator guard.
for _, sx in { -1, 1 } do
	block("GuardPost", V(0.5, 7.6, 0.6), CF(2.85 * sx, 6.1, -9.0), YELLOW)
end
block("GuardTopBar", V(6.2, 0.5, 0.6), CF(0, 9.65, -9.0), YELLOW)
block("GuardBottomBar", V(6.2, 0.6, 0.6), CF(0, 2.6, -9.0), YELLOW)
block("GrilleInset", V(5.2, 6.6, 0.06), CF(0, 6.1, -9.04), GRILLE)
for i = 0, 5 do
	block("GrilleBar", V(5.2, 0.18, 0.2), CF(0, 3.6 + i * 1.0, -9.17), YELLOW)
end
block("GrilleCenterBar", V(0.3, 6.4, 0.2), CF(0, 6.1, -9.2), YELLOW)

-- Front headlights on the guard.
for _, sx in { -1, 1 } do
	block("HeadlightHousing", V(0.9, 0.7, 0.6), CF(2.3 * sx, 10.25, -8.9), BLACK)
	block("Headlight", V(0.7, 0.5, 0.06), CF(2.3 * sx, 10.25, -9.22), HEAD)
end

-- Exhaust stack and precleaner.
cyl("ExhaustStack", V(4.0, 0.8, 0.8), CF(1.4, 11.6, -4.6) * CYLINDER_Y, EXHAUST)
cyl("StackFlange", V(0.3, 1.2, 1.2), CF(1.4, 9.75, -4.6) * CYLINDER_Y, BLACK)
cyl("StackTip", V(0.5, 0.86, 0.86), CF(1.4, 13.4, -4.6) * CYLINDER_Y, RUST)
cyl("PrecleanerBody", V(1.4, 1.1, 1.1), CF(-1.4, 10.3, -5.2) * CYLINDER_Y, BLACK)
cyl("PrecleanerCap", V(0.3, 1.3, 1.3), CF(-1.4, 11.15, -5.2) * CYLINDER_Y, BLACK)

-- Fenders over the sprockets.
for _, sx in { -1, 1 } do
	block("FenderDeck", V(2.9, 0.3, 11.0), CF(4.45 * sx, 8.65, 3.9), YELLOW)
	block("FenderWalkway", V(2.6, 0.05, 10.6), CF(4.45 * sx, 8.83, 3.9), WALKWAY)
	wedge("FenderFrontLip", V(2.9, 1.3, 1.0), CF(4.45 * sx, 8.15, -2.1), YELLOW)
	block("FenderSkirt", V(0.15, 0.7, 11.0), CF(5.88 * sx, 8.3, 3.9), YELLOW)
end

block("CabBulkhead", V(6.2, 4.8, 6.6), CF(0, 6.4, 2.4), YELLOW)

-- Rear fuel tank.
block("FuelTank", V(7.0, 3.7, 3.4), CF(0, 6.25, 7.7), YELLOW)
block("FuelTankTop", V(7.0, 0.5, 2.4), CF(0, 8.35, 7.7), YELLOW)
wedge("FuelTankChamferRear", V(7.0, 0.5, 0.5), CF(0, 8.35, 9.15) * RISE_FWD, YELLOW)
wedge("FuelTankChamferFront", V(7.0, 0.5, 0.5), CF(0, 8.35, 6.25), YELLOW)
cyl("FuelCap", V(0.3, 0.6, 0.6), CF(2.4, 8.75, 7.0) * CYLINDER_Y, BLACK)
block("TankSeam", V(7.04, 0.08, 0.08), CF(0, 5.2, 9.4), GRILLE)

for _, sx in { -1, 1 } do
	block("RearLampHousing", V(0.8, 0.6, 0.3), CF(3.0 * sx, 8.0, 9.55), BLACK)
	block("RearLamp", V(0.6, 0.4, 0.06), CF(3.0 * sx, 8.0, 9.72), TAIL)
end

-- Handrails and steps.
for _, sx in { -1, 1 } do
	rod("HandrailSide", V(5.7 * sx, 10.4, 0.0), V(5.7 * sx, 10.4, 8.8), 0.15, YELLOW)
	rod("HandrailRear", V(3.1 * sx, 10.4, 6.0), V(5.6 * sx, 10.4, 6.0), 0.15, YELLOW)
	for _, z in { 0.4, 8.6 } do
		cyl("HandrailPost", V(1.6, 0.15, 0.15), CF(5.7 * sx, 9.6, z) * CYLINDER_Y, YELLOW)
	end
	cyl("HandrailPost", V(1.6, 0.15, 0.15), CF(3.15 * sx, 9.6, 6.0) * CYLINDER_Y, YELLOW)
	block("Step", V(1.0, 0.12, 1.2), CF(6.2 * sx, 3.36, -0.6), WALKWAY)
end

---------------------------------------------------------------------------------------------------
-- Blade: semi-U moldboard, center section plus two forward-swept wings.
---------------------------------------------------------------------------------------------------

local BANDS = {
	-- theta (deg), length, yc, zc, palette
	{ 26.6, 1.44, 1.92, -13.54, EDGE },
	{ 15.5, 1.97, 3.45, -12.98, YELLOW },
	{ 0, 2.10, 5.40, -12.725, YELLOW },
	{ -14.0, 1.75, 7.24, -12.93, YELLOW },
	{ -30.3, 1.49, 8.69, -13.5, YELLOW },
}

local function bandCF(b)
	return CF(0, b[3], b[4]) * A(math.rad(b[1]), 0, 0)
end

for _, b in BANDS do
	block("Moldboard", V(12.4, b[2], 0.35), bandCF(b), b[5])
end
block(
	"BladeWearStrip",
	V(12.4, 0.12, 0.38),
	CF(0, 1.48, -13.9) * A(math.rad(26.6), 0, 0),
	EDGE_BRIGHT
)

for _, sx in { -1, 1 } do
	local hinge = CF(6.2 * sx, 0, -12.9) * A(0, math.rad(25) * sx, 0)
	for _, b in BANDS do
		block("WingBand", V(2.8, b[2], 0.35), hinge * CF(1.3 * sx, 0, 12.9) * bandCF(b), b[5])
	end
	block(
		"WingWearStrip",
		V(2.8, 0.12, 0.38),
		hinge * CF(1.3 * sx, 1.48, -13.9 + 12.9) * A(math.rad(26.6), 0, 0),
		EDGE_BRIGHT
	)
	block("WingEndPlate", V(0.25, 7.6, 1.6), hinge * CF(2.65 * sx, 5.3, -0.35), YELLOW)
	block("WingBackPlate", V(2.6, 6.4, 0.25), hinge * CF(1.3 * sx, 5.1, 0.25), YELLOW)
	block("EndBit", V(0.5, 0.9, 1.0), hinge * CF(2.4 * sx, 1.75, -0.9), EDGE)
end

block("BladeBackPlate", V(12.4, 6.6, 0.3), CF(0, 5.0, -11.75), YELLOW)
for _, x in { -4.5, -1.5, 1.5, 4.5 } do
	block("BladeRib", V(0.4, 6.6, 1.0), CF(x, 5.0, -12.2), YELLOW)
end
block("BladeTopBeam", V(12.4, 0.6, 1.4), CF(0, 8.3, -12.4), YELLOW)
block("BladeBottomBeam", V(12.4, 0.6, 1.4), CF(0, 2.4, -12.4), YELLOW)

---------------------------------------------------------------------------------------------------
-- Push arms and blade hydraulics.
---------------------------------------------------------------------------------------------------

for _, sx in { -1, 1 } do
	beam("PushArm", 0.7, 1.1, V(6.2 * sx, 2.6, -11.6), V(6.2 * sx, 2.6, -0.6), YELLOW)
	cyl("PushArmTrunnion", V(0.6, 1.4, 1.4), CF(6.15 * sx, 2.6, -0.6), BLACK)
	cyl("BladePivotPin", V(0.9, 0.7, 0.7), CF(6.2 * sx, 2.6, -11.8), BLACK)

	rod("LiftCylinder", V(3.4 * sx, 8.0, -8.9), V(3.4 * sx, 7.36, -10.4), 0.9, YELLOW)
	rod("LiftCylinderRod", V(3.4 * sx, 7.4, -10.3), V(3.4 * sx, 6.8, -11.7), 0.45, CHROME)
	block("LiftCylinderClevis", V(0.5, 0.6, 0.6), CF(3.4 * sx, 8.0, -8.9), BLACK)
	block("LiftCylinderBracket", V(0.6, 0.8, 0.5), CF(3.4 * sx, 8.2, -8.55), BLACK)

	rod("TiltCylinder", V(6.2 * sx, 3.4, -7.0), V(6.0 * sx, 5.6, -9.6), 0.75, YELLOW)
	rod("TiltCylinderRod", V(6.0 * sx, 5.5, -9.4), V(5.6 * sx, 7.6, -11.8), 0.38, CHROME)
	block("TiltCylinderClevis", V(0.5, 0.6, 0.6), CF(5.6 * sx, 7.6, -11.8), BLACK)
end

---------------------------------------------------------------------------------------------------
-- Cab (ROPS) and interior.
---------------------------------------------------------------------------------------------------

block("CabFloor", V(7.2, 0.3, 6.4), CF(0, 8.95, 2.4), BLACK)
for _, sx in { -1, 1 } do
	for _, z in { -0.65, 5.45 } do
		block("CabPost", V(0.35, 6.3, 0.35), CF(3.45 * sx, 12.25, z), CAB_FRAME)
	end
	block("CabSideGlass", V(0.1, 5.9, 5.8), CF(3.48 * sx, 12.25, 2.4), GLASS)
	block("DoorFrame", V(0.12, 5.9, 0.12), CF(3.55 * sx, 12.25, 2.9), CAB_FRAME)
	block("CabSillRail", V(0.12, 0.25, 6.2), CF(3.55 * sx, 9.35, 2.4), CAB_FRAME)
	block("CabHeaderRail", V(0.12, 0.2, 6.2), CF(3.55 * sx, 15.25, 2.4), CAB_FRAME)
	block("DoorHandle", V(0.08, 0.1, 0.4), CF(3.62 * sx, 11.8, 3.3), BLACK)
end
block("CabLowerFront", V(6.6, 0.5, 0.2), CF(0, 9.35, -0.7), CAB_FRAME)
block("CabFrontGlass", V(6.55, 5.6, 0.1), CF(0, 12.4, -0.72), GLASS)
block("CabRearGlass", V(6.55, 5.6, 0.1), CF(0, 12.4, 5.52), GLASS)
block("CabFrontHeader", V(6.6, 0.25, 0.2), CF(0, 15.27, -0.7), CAB_FRAME)
block("CabRearHeader", V(6.6, 0.25, 0.2), CF(0, 15.27, 5.5), CAB_FRAME)
block("CabRearSill", V(6.6, 0.5, 0.2), CF(0, 9.35, 5.5), CAB_FRAME)

-- Roof.
block("CabRoof", V(7.6, 0.5, 6.8), CF(0, 15.65, 2.4), YELLOW)
block("CabRoofCap", V(7.6, 0.3, 6.0), CF(0, 16.05, 2.4), YELLOW)
wedge("CabRoofChamferFront", V(7.6, 0.3, 0.4), CF(0, 16.05, -0.8), YELLOW)
wedge("CabRoofChamferRear", V(7.6, 0.3, 0.4), CF(0, 16.05, 5.6) * RISE_FWD, YELLOW)
block("Pressurizer", V(3.0, 0.7, 2.0), CF(0, 16.55, 4.2), YELLOW)
block("PressurizerVent", V(2.4, 0.4, 0.05), CF(0, 16.55, 3.18), GRILLE)

-- Work lights under the roof edges.
for _, sx in { -1, 1 } do
	block("WorkLightHousingFront", V(0.7, 0.5, 0.4), CF(2.6 * sx, 15.65, -1.2), BLACK)
	block("WorkLightFront", V(0.5, 0.35, 0.06), CF(2.6 * sx, 15.65, -1.43), HEAD)
	block("WorkLightHousingRear", V(0.7, 0.5, 0.4), CF(2.6 * sx, 15.65, 6.0), BLACK)
	block("WorkLightRear", V(0.5, 0.35, 0.06), CF(2.6 * sx, 15.65, 6.23), HEAD)
end

-- Beacon.
cyl("BeaconBase", V(0.2, 0.7, 0.7), CF(-2.6, 16.3, 4.6) * CYLINDER_Y, BLACK)
ball("BeaconDome", 0.6, CF(-2.6, 16.65, 4.6), AMBER)

-- Mirrors and wiper.
for _, sx in { -1, 1 } do
	block("MirrorArm", V(0.8, 0.1, 0.1), CF(3.9 * sx, 14.6, -0.6), BLACK)
	block("Mirror", V(0.1, 0.9, 0.6), CF(4.3 * sx, 14.4, -0.6), BLACK)
end
block("Wiper", V(0.08, 3.0, 0.06), CF(1.2, 12.0, -0.81) * A(0, 0, math.rad(20)), BLACK)

-- Interior.
block("SeatPedestal", V(1.2, 1.15, 1.2), CF(0, 9.675, 2.4), BLACK)
block("SeatCushion", V(1.9, 0.6, 1.8), CF(0, 10.55, 2.3), SEAT)
block("SeatBack", V(1.9, 2.6, 0.4), CF(0, 12.0, 3.3), SEAT)
block("Headrest", V(1.3, 0.7, 0.35), CF(0, 13.75, 3.35), SEAT)
for _, sx in { -1, 1 } do
	block("Armrest", V(0.4, 0.3, 1.6), CF(1.25 * sx, 11.3, 2.2), SEAT)
	block("ArmrestPod", V(0.4, 0.4, 0.6), CF(1.25 * sx, 11.25, 1.6), BLACK)
	block("JoystickStalk", V(0.12, 0.35, 0.12), CF(1.25 * sx, 11.6, 1.6), BLACK)
	ball("JoystickKnob", 0.3, CF(1.25 * sx, 11.8, 1.6), BLACK)
end
block("Dash", V(5.0, 0.8, 0.6), CF(0, 9.8, -0.2), BLACK)
block("Monitor", V(0.9, 0.6, 0.1), CF(1.6, 10.9, 0.0) * A(math.rad(-15), 0, 0), INTERIOR)
block("MonitorStalk", V(0.1, 0.7, 0.1), CF(1.6, 10.4, 0.05), BLACK)

---------------------------------------------------------------------------------------------------
-- Ripper: parallelogram linkage, beam and single shank.
---------------------------------------------------------------------------------------------------

block("RipperMount", V(6.4, 4.8, 1.0), CF(0, 4.8, 9.9), YELLOW)
for _, sx in { -1, 1 } do
	local x = 2.2 * sx
	beam("RipperUpperLink", 0.6, 0.8, V(x, 6.6, 10.2), V(x, 6.0, 14.2), YELLOW)
	beam("RipperLowerLink", 0.6, 0.8, V(x, 3.0, 10.2), V(x, 3.4, 14.2), YELLOW)
	for _, p in { V(x, 6.6, 10.2), V(x, 6.0, 14.2), V(x, 3.0, 10.2), V(x, 3.4, 14.2) } do
		cyl("RipperLinkPin", V(0.9, 0.5, 0.5), CF(p), BLACK)
	end
	rod("RipperCylinder", V(1.2 * sx, 7.0, 10.3), V(1.2 * sx, 5.8, 12.2), 0.75, YELLOW)
	rod("RipperCylinderRod", V(1.2 * sx, 5.9, 12.0), V(1.2 * sx, 4.6, 14.1), 0.38, CHROME)
end
block("RipperBeam", V(5.6, 3.6, 1.4), CF(0, 4.8, 14.8), YELLOW)
block("RipperShank", V(0.7, 5.6, 1.3), CF(0, 5.8, 14.85), DARK)
beam("RipperShankCurve", 0.7, 1.0, V(0, 3.1, 14.9), V(0, 1.95, 13.7), DARK)
beam("RipperTip", 0.72, 0.7, V(0, 2.1, 13.85), V(0, 1.5, 13.05), EDGE)
wedge(
	"RipperTipPoint",
	V(0.72, 0.35, 0.5),
	beamCF(V(0, 2.1, 13.85), V(0, 1.5, 13.05)) * CF(0, 0.18, -0.75) * A(0, 0, math.pi),
	EDGE
)
cyl("RipperShankPin", V(1.0, 0.4, 0.4), CF(0, 6.2, 14.85), BLACK)

return {
	name = "Bulldozer",
	-- Real: 11.7 km/h, 0-11.7 km/h in 4 s, brakes 0.4 g, coasts 0.3 g (VehicleDefaults maps them).
	speed = 20,
	acceleration = 5.9,
	braking = 16.9,
	coasting = 14,
	turnRate = 1.6,
	footprint = Vector2.new(11.4, 18.4),
	collision = {
		{ size = V(11.4, 7.4, 18.4), offset = CF(0, 5.1, 0) },
		{ size = V(7.2, 7.1, 6.6), offset = CF(0, 12.35, 2.4) },
		{ size = V(17.2, 7.8, 2.6), offset = CF(0, 5.3, -13.0) },
		{ size = V(6.0, 6.0, 6.4), offset = CF(0, 4.8, 12.8) },
	},
	seats = { CF(0, 10.4, 2.4) },
	pieces = pieces,
}
