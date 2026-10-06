-- Tiger I Tank: late-production Panzer VI Ausf. E heavy tank with 88 mm KwK 36 in three-tone camouflage.
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
local CYLINDER_Z = A(0, math.rad(90), 0) -- cylinder axis along Z (size.X = length)
local CYLINDER_Y = A(0, 0, math.rad(90)) -- cylinder axis along Y (size.X = height)
local FLIP_Z = A(0, 0, math.pi) -- wedge right angle at (ymax, zmax)

-- Palette: color, material, transparency.
local ARMOR = { c = rgb(186, 158, 104), m = M.Concrete }
local GREEN = { c = rgb(78, 86, 56), m = M.Concrete }
local BROWN = { c = rgb(104, 66, 46), m = M.Concrete }
local TRACK = { c = rgb(62, 58, 54), m = M.Metal }
local TRACK_RUST = { c = rgb(96, 74, 58), m = M.Metal }
local TYRESTEEL = { c = rgb(76, 74, 70), m = M.Metal }
local GUNMETAL = { c = rgb(50, 48, 44), m = M.Metal }
local SOOT = { c = rgb(72, 66, 58), m = M.Metal }
local EXHAUST = { c = rgb(88, 62, 46), m = M.CorrodedMetal }
local BLACK = { c = rgb(14, 14, 14), m = M.SmoothPlastic }
local MESH = { c = rgb(40, 38, 34), m = M.DiamondPlate }
local PERISCOPE = { c = rgb(40, 55, 60), m = M.Glass, t = 0.3 }
local LAMP = { c = rgb(225, 210, 170), m = M.Neon, t = 0.2 }
local WOOD = { c = rgb(140, 105, 68), m = M.Wood }
local TOOLSTEEL = { c = rgb(92, 92, 96), m = M.Metal }
local CABLE = { c = rgb(70, 66, 60), m = M.Metal }

local pieces = {}

local function add(name, class, shape, size, offset, paint)
	table.insert(pieces, {
		name = name,
		class = class,
		shape = shape,
		size = size,
		offset = offset,
		color = paint.c,
		material = paint.m,
		transparency = paint.t,
	})
end

local function block(name, size, offset, paint)
	add(name, nil, nil, size, offset, paint)
end

local function wedge(name, size, offset, paint)
	add(name, WEDGE, nil, size, offset, paint)
end

local function cyl(name, size, offset, paint)
	add(name, nil, CYL, size, offset, paint)
end

local function ball(name, size, offset, paint)
	add(name, nil, BALL, size, offset, paint)
end

local SIDES = { -1, 1 }

--------------------------------------------------------------------------------
-- Hull structure
--------------------------------------------------------------------------------

block("Belly", V(8.0, 2.9, 23.75), CF(0, 3.35, 0.725), ARMOR)
block("Nose", V(8.0, 2.3, 1.45), CF(0, 4.05, -11.875), ARMOR)
wedge("LowerNose", V(8.0, 1.0, 1.45), CF(0, 2.4, -11.875) * FLIP_Z, ARMOR)
wedge("Glacis", V(8.0, 0.3, 1.45), CF(0, 5.35, -11.875), ARMOR)
block("Superstructure", V(12.6, 2.4, 23.4), CF(0, 6.0, 0.9), ARMOR)
block("FrontPlate", V(12.8, 2.5, 0.5), CF(0, 6.05, -10.9), ARMOR)
block("RearPlateUpper", V(12.8, 2.5, 0.3), CF(0, 6.05, 12.7), ARMOR)
block("RearPlateLower", V(8.2, 2.9, 0.3), CF(0, 3.35, 12.7), ARMOR)
for _, s in SIDES do
	block("SideFender", V(1.1, 0.1, 23.2), CF(s * 6.85, 4.8, 0.8), ARMOR)
	block("FrontMudguard", V(3.4, 0.1, 1.7), CF(s * 5.7, 4.8, -12.0), ARMOR)
	block("FrontFlap", V(3.4, 0.08, 0.8), CF(s * 5.7, 4.6, -13.05) * A(math.rad(35), 0, 0), ARMOR)
	block("RearMudguard", V(3.4, 0.1, 0.6), CF(s * 5.7, 4.8, 12.85), ARMOR)
end

--------------------------------------------------------------------------------
-- Hull front and roof details
--------------------------------------------------------------------------------

block("DriverVisor", V(1.9, 0.7, 0.25), CF(-3.2, 6.3, -11.25), ARMOR)
block("DriverVisorSlit", V(1.4, 0.08, 0.04), CF(-3.2, 6.35, -11.395), BLACK)

ball("HullMGBall", V(1.1, 1.1, 1.1), CF(3.2, 6.1, -11.15), ARMOR)
cyl("HullMGCollar", V(0.12, 1.4, 1.4), CF(3.2, 6.1, -11.2) * CYLINDER_Z, ARMOR)
cyl("HullMGBarrel", V(0.9, 0.22, 0.22), CF(3.2, 6.1, -12.0) * CYLINDER_Z, GUNMETAL)

block("HeadlightMount", V(0.2, 0.3, 0.2), CF(0, 7.45, -10.95), GUNMETAL)
cyl("HeadlightBody", V(0.5, 0.6, 0.6), CF(0, 7.75, -11.05) * CYLINDER_Z, ARMOR)
cyl("HeadlightLens", V(0.04, 0.45, 0.45), CF(0, 7.75, -11.32) * CYLINDER_Z, LAMP)

for _, s in SIDES do
	block("FrontClevisInner", V(0.25, 1.0, 0.8), CF(s * 3.3, 3.6, -12.9), GUNMETAL)
	block("FrontClevisOuter", V(0.25, 1.0, 0.8), CF(s * 3.9, 3.6, -12.9), GUNMETAL)
end

for k, y in { 3.4, 3.95, 4.5 } do
	block(
		"NoseSpareLink",
		V(2.6, 0.48, 0.2),
		CF(-2.3, y, -12.72),
		if k % 2 == 1 then TRACK else TRACK_RUST
	)
end

cyl("DriverHatchRing", V(0.12, 2.5, 2.5), CF(-3.2, 7.26, -7.9) * CYLINDER_Y, ARMOR)
cyl("DriverHatchOpening", V(0.04, 2.2, 2.2), CF(-3.2, 7.34, -7.9) * CYLINDER_Y, BLACK)
cyl("DriverHatchLid", V(0.12, 1.9, 1.9), CF(-5.3, 7.3, -7.9) * CYLINDER_Y, ARMOR)
cyl("RadioHatch", V(0.12, 2.2, 2.2), CF(3.2, 7.26, -7.9) * CYLINDER_Y, ARMOR)
block("RadioHatchHinge", V(0.6, 0.15, 0.3), CF(4.4, 7.3, -7.9), GUNMETAL)
for _, s in SIDES do
	block("HullPeriscope", V(0.6, 0.2, 0.3), CF(s * 3.2, 7.3, -9.6), GUNMETAL)
end

--------------------------------------------------------------------------------
-- Engine deck and rear
--------------------------------------------------------------------------------

block("EngineHatch", V(3.6, 0.12, 4.4), CF(0, 7.26, 9.6), ARMOR)
cyl("EngineHatchCapFront", V(0.1, 1.1, 1.1), CF(0, 7.37, 8.6) * CYLINDER_Y, ARMOR)
cyl("EngineHatchCapRear", V(0.1, 1.1, 1.1), CF(0, 7.37, 10.8) * CYLINDER_Y, ARMOR)

for _, s in SIDES do
	for _, z in { 7.8, 10.8 } do
		local x = s * 3.9
		block("GrilleFrame", V(3.0, 0.1, 2.4), CF(x, 7.25, z), GUNMETAL)
		block("GrilleMesh", V(2.6, 0.06, 2.0), CF(x, 7.31, z), MESH)
		block("GrilleBar", V(0.12, 0.08, 2.0), CF(x - 0.65, 7.34, z), ARMOR)
		block("GrilleBar", V(0.12, 0.08, 2.0), CF(x + 0.65, 7.34, z), ARMOR)
	end
end

for _, s in SIDES do
	cyl("ExhaustPipe", V(2.6, 0.6, 0.6), CF(s * 2.2, 7.5, 13.2) * CYLINDER_Y, EXHAUST)
	block("ExhaustGuard", V(1.1, 2.0, 0.7), CF(s * 2.2, 6.6, 13.2), ARMOR)
	cyl("ExhaustBore", V(0.04, 0.45, 0.45), CF(s * 2.2, 8.82, 13.2) * CYLINDER_Y, BLACK)
	block("RearClevis", V(0.3, 1.0, 0.4), CF(s * 3.0, 2.8, 12.95), GUNMETAL)
end
cyl("Jack", V(1.4, 0.5, 0.5), CF(0, 4.0, 13.1) * CYLINDER_Y, GUNMETAL)
block("JackBase", V(0.8, 0.12, 0.5), CF(0, 3.25, 13.1), GUNMETAL)

--------------------------------------------------------------------------------
-- Tools
--------------------------------------------------------------------------------

cyl("CleaningRodTube", V(12.0, 0.35, 0.35), CF(-6.52, 6.6, 3.0) * CYLINDER_Z, ARMOR)
block("RodBracketFront", V(0.25, 0.4, 0.3), CF(-6.42, 6.6, -1.5), GUNMETAL)
block("RodBracketRear", V(0.25, 0.4, 0.3), CF(-6.42, 6.6, 7.5), GUNMETAL)

cyl("TowCableLower", V(16.0, 0.22, 0.22), CF(6.48, 5.5, 1.0) * CYLINDER_Z, CABLE)
cyl("TowCableUpper", V(16.0, 0.22, 0.22), CF(6.48, 5.85, 1.0) * CYLINDER_Z, CABLE)
block("TowCableEyeFront", V(0.15, 0.6, 0.5), CF(6.5, 5.68, -7.1), GUNMETAL)
block("TowCableEyeRear", V(0.15, 0.6, 0.5), CF(6.5, 5.68, 9.1), GUNMETAL)

cyl("ShovelHandle", V(2.6, 0.15, 0.15), CF(-5.5, 7.3, -1.0) * CYLINDER_Z, WOOD)
block("ShovelBlade", V(0.7, 0.06, 0.9), CF(-5.5, 7.26, 0.75), TOOLSTEEL)
cyl("Crowbar", V(4.5, 0.12, 0.12), CF(-5.95, 7.28, 2.5) * CYLINDER_Z, TOOLSTEEL)
cyl("AxeHandle", V(2.4, 0.15, 0.15), CF(5.5, 7.3, -1.0) * CYLINDER_Z, WOOD)
block("AxeHead", V(0.5, 0.1, 0.35), CF(5.5, 7.3, 0.35), TOOLSTEEL)
cyl("SledgeHandle", V(2.6, 0.14, 0.14), CF(5.9, 7.3, 3.0) * CYLINDER_Z, WOOD)
block("SledgeHead", V(0.6, 0.3, 0.3), CF(5.9, 7.35, 4.45), TOOLSTEEL)

--------------------------------------------------------------------------------
-- Turret, gun, cupola, bin, spare links
--------------------------------------------------------------------------------

block("TurretBody", V(9.4, 3.7, 5.4), CF(0, 9.1, 0.3), ARMOR)
cyl("TurretRear", V(3.66, 9.4, 9.4), CF(0, 9.1, 3.0) * CYLINDER_Y, ARMOR)
block("TurretFront", V(7.0, 3.7, 1.2), CF(0, 9.1, -3.0), ARMOR)
wedge("TurretCornerR", V(3.7, 1.2, 1.2), CF(4.1, 9.1, -3.0) * A(0, 0, math.rad(-90)), ARMOR)
wedge("TurretCornerL", V(3.7, 1.2, 1.2), CF(-4.1, 9.1, -3.0) * A(0, 0, math.rad(90)), ARMOR)
block("Mantlet", V(6.0, 3.4, 0.5), CF(0, 9.1, -3.85), ARMOR)
wedge("MantletEndR", V(3.4, 0.6, 0.5), CF(3.3, 9.1, -3.85) * A(0, 0, math.rad(-90)), ARMOR)
wedge("MantletEndL", V(3.4, 0.6, 0.5), CF(-3.3, 9.1, -3.85) * A(0, 0, math.rad(90)), ARMOR)

local function gun(name, length, dia, z, paint)
	cyl(name, V(length, dia, dia), CF(0, 9.0, z) * CYLINDER_Z, paint)
end
gun("GunCollar", 1.4, 1.3, -4.8, ARMOR)
gun("Barrel1", 4.6, 0.85, -7.8, ARMOR)
gun("Barrel2", 5.0, 0.76, -12.6, ARMOR)
gun("Barrel3", 4.3, 0.68, -17.25, ARMOR)
gun("BrakeRear", 0.8, 1.3, -19.8, SOOT)
gun("BrakeWaist", 0.2, 0.95, -20.3, SOOT)
gun("BrakeFront", 0.8, 1.3, -20.8, SOOT)
gun("BrakeCap", 0.1, 1.1, -21.25, SOOT)
gun("Bore", 0.04, 0.42, -21.32, BLACK)
for _, s in SIDES do
	for _, z in { -19.8, -20.8 } do
		block("BrakeVent", V(0.06, 0.8, 0.5), CF(s * 0.64, 9.0, z), BLACK)
	end
end
cyl("SightPortL", V(0.06, 0.3, 0.3), CF(-1.0, 9.6, -4.13) * CYLINDER_Z, BLACK)
cyl("SightPortR", V(0.06, 0.3, 0.3), CF(-1.5, 9.6, -4.13) * CYLINDER_Z, BLACK)
cyl("CoaxPort", V(0.06, 0.35, 0.35), CF(1.3, 9.5, -4.13) * CYLINDER_Z, BLACK)
cyl("CoaxTip", V(0.3, 0.12, 0.12), CF(1.3, 9.5, -4.27) * CYLINDER_Z, GUNMETAL)

-- Commander cupola, left rear of the roof.
local CX, CZ = -2.7, 2.4
cyl("CupolaBase", V(0.6, 3.2, 3.2), CF(CX, 11.25, CZ) * CYLINDER_Y, ARMOR)
cyl("CupolaRing", V(0.45, 2.9, 2.9), CF(CX, 11.775, CZ) * CYLINDER_Y, ARMOR)
cyl("CupolaOpening", V(0.04, 2.2, 2.2), CF(CX, 12.02, CZ) * CYLINDER_Y, BLACK)
for k = 0, 6 do
	local th = k * 2 * math.pi / 7 + math.pi / 14
	block(
		"CupolaPeriscope",
		V(0.06, 0.22, 0.5),
		CF(CX + 1.63 * math.cos(th), 11.4, CZ + 1.63 * math.sin(th)) * A(0, -th, 0),
		PERISCOPE
	)
end
cyl("CupolaLid", V(0.15, 2.5, 2.5), CF(CX, 12.45, 4.9) * CYLINDER_Y, ARMOR)
block("CupolaLidArm", V(0.3, 0.4, 1.0), CF(CX, 12.2, 3.95), GUNMETAL)

-- Roof fittings.
cyl("LoaderHatch", V(0.12, 2.0, 2.0), CF(2.4, 11.01, 0.6) * CYLINDER_Y, ARMOR)
block("LoaderHatchHinge", V(0.5, 0.15, 0.3), CF(3.5, 11.05, 0.6), GUNMETAL)
cyl("Ventilator", V(0.2, 1.0, 1.0), CF(0, 11.05, -1.6) * CYLINDER_Y, ARMOR)
ball("VentilatorCap", V(0.7, 0.35, 0.7), CF(0, 11.18, -1.6), ARMOR)
cyl("CloseDefenseLauncher", V(0.35, 0.6, 0.6), CF(2.2, 11.12, 4.6) * CYLINDER_Y, ARMOR)
for _, p in { V(-1.0, 11.05, -2.6), V(1.0, 11.05, -2.6), V(0, 11.05, 6.3) } do
	cyl("LiftingPilz", V(0.2, 0.4, 0.4), CF(p) * CYLINDER_Y, GUNMETAL)
end

-- Escape hatch on the right rear wall.
cyl("EscapeHatch", V(0.15, 1.9, 1.9), CF(3.36, 9.1, 6.36) * A(0, math.rad(-45), 0), ARMOR)
block("EscapeHatchHinge", V(0.2, 0.4, 0.4), CF(3.95, 9.1, 5.55) * A(0, math.rad(-45), 0), GUNMETAL)

-- Stowage bin on the turret rear.
block("StowageBin", V(7.2, 2.0, 1.5), CF(0, 9.2, 8.15), ARMOR)
block("StowageBinLidSeam", V(7.24, 0.05, 1.54), CF(0, 9.9, 8.15), BLACK)
for _, s in SIDES do
	block("StowageBinLatch", V(0.25, 0.4, 0.06), CF(s * 1.8, 9.7, 8.93), GUNMETAL)
	block("StowageBinBracket", V(0.2, 0.3, 1.0), CF(s * 2.6, 9.0, 7.3), GUNMETAL)
end

-- Spare track links on the turret sides.
for _, s in SIDES do
	for k, z in { -1.6, -1.02, -0.44, 0.14, 0.72 } do
		block(
			"TurretSpareLink",
			V(0.2, 2.6, 0.5),
			CF(s * 4.81, 9.0, z),
			if k % 2 == 1 then TRACK else TRACK_RUST
		)
	end
	block("TurretLinkRail", V(0.12, 0.15, 3.2), CF(s * 4.78, 10.4, -0.44), GUNMETAL)
end

--------------------------------------------------------------------------------
-- Running gear
--------------------------------------------------------------------------------

for _, s in SIDES do
	-- Road wheels: 8 per side in two staggered rows.
	for i = 0, 7 do
		local x = s * (if i % 2 == 0 then 6.5 else 5.95)
		local z = -6.3 + 1.8 * i
		cyl("RoadWheelTyre", V(0.5, 3.2, 3.2), CF(x, 2.0, z), TYRESTEEL)
		cyl("RoadWheelDisc", V(0.56, 2.6, 2.6), CF(x, 2.0, z), ARMOR)
		cyl("RoadWheelHub", V(0.7, 0.9, 0.9), CF(x, 2.0, z), GUNMETAL)
	end

	-- Drive sprocket at the front.
	cyl("SprocketRing", V(0.3, 3.2, 3.2), CF(s * 6.5, 2.8, -10.4), TRACK)
	cyl("SprocketDisc", V(0.4, 2.9, 2.9), CF(s * 6.45, 2.8, -10.4), ARMOR)
	for k = 0, 5 do
		local a = math.rad(k * 60)
		cyl(
			"SprocketHole",
			V(0.04, 0.45, 0.45),
			CF(s * 6.67, 2.8 + 0.95 * math.cos(a), -10.4 + 0.95 * math.sin(a)),
			BLACK
		)
	end
	cyl("SprocketHub", V(0.5, 1.2, 1.2), CF(s * 6.75, 2.8, -10.4), GUNMETAL)

	-- Idler at the rear.
	cyl("IdlerRim", V(0.4, 2.4, 2.4), CF(s * 6.45, 2.6, 10.4), TYRESTEEL)
	cyl("IdlerInner", V(0.44, 1.8, 1.8), CF(s * 6.45, 2.6, 10.4), BLACK)
	for k = 0, 3 do
		block(
			"IdlerSpoke",
			V(0.46, 1.7, 0.25),
			CF(s * 6.45, 2.6, 10.4) * A(math.rad(k * 45), 0, 0),
			ARMOR
		)
	end
	cyl("IdlerHub", V(0.6, 0.6, 0.6), CF(s * 6.7, 2.6, 10.4), GUNMETAL)

	-- Track runs.
	local x = s * 5.65
	local tw = 2.9
	block("TrackGround", V(tw, 0.4, 15.2), CF(x, 0.2, 0), TRACK)
	block("TrackFrontDiag", V(tw, 0.4, 2.94), CF(x, 0.65, -9.0) * A(math.rad(17.8), 0, 0), TRACK)
	block("TrackRearDiag", V(tw, 0.4, 2.97), CF(x, 0.7, 9.0) * A(math.rad(-19.7), 0, 0), TRACK)
	block("TrackTopFront", V(tw, 0.4, 4.16), CF(x, 4.15, -8.35) * A(math.rad(9.7), 0, 0), TRACK)
	block("TrackTopMid", V(tw, 0.4, 12.6), CF(x, 3.8, 0), TRACK)
	block("TrackTopRear", V(tw, 0.4, 4.1), CF(x, 3.9, 8.35) * A(math.rad(-2.8), 0, 0), TRACK)
	for _, deg in { 18, 54, 90, 126, 162 } do
		local phi = math.rad(deg)
		block(
			"TrackSprocketWrap",
			V(tw, 0.4, 1.25),
			CF(x, 2.8 + 1.7 * math.cos(phi), -10.4 - 1.7 * math.sin(phi)) * A(-phi, 0, 0),
			TRACK
		)
		block(
			"TrackIdlerWrap",
			V(tw, 0.4, 1.05),
			CF(x, 2.6 + 1.4 * math.cos(phi), 10.4 + 1.4 * math.sin(phi)) * A(phi, 0, 0),
			TRACK
		)
	end
	for _, z in { -4.5, -1.5, 1.5, 4.5 } do
		block("TrackLinkGap", V(0.04, 0.42, 0.08), CF(s * 7.12, 3.8, z), BLACK)
	end
	for _, z in { -6.3, -3.8, -1.3, 1.3, 3.8, 6.3 } do
		block("TrackLinkGap", V(0.04, 0.42, 0.08), CF(s * 7.12, 0.2, z), BLACK)
	end
end

--------------------------------------------------------------------------------
-- Camouflage patches
--------------------------------------------------------------------------------

local hullPatches = {
	{ y = 6.1, z = -7.0, h = 1.3, w = 4.0, rot = 4 },
	{ y = 5.7, z = -1.5, h = 1.0, w = 3.2, rot = -5 },
	{ y = 6.2, z = 4.0, h = 1.2, w = 4.5, rot = 3 },
	{ y = 5.8, z = 9.5, h = 1.0, w = 2.8, rot = -6 },
}
local rightShift = { 2.0, 2.0, 2.0, 1.2 } -- the right side's last patch stops short of the rear plate
for _, s in SIDES do
	for k, p in hullPatches do
		local green = (k % 2 == 1) == (s < 0)
		local dz = if s > 0 then rightShift[k] else 0
		block(
			"HullCamo",
			V(0.04, p.h, p.w),
			CF(s * 6.34, p.y, p.z + dz) * A(math.rad(p.rot * s), 0, 0),
			if green then GREEN else BROWN
		)
	end
end

block("FrontCamoGreen", V(4.0, 1.1, 0.04), CF(-0.3, 6.4, -11.19) * A(0, 0, math.rad(4)), GREEN)
block("FrontCamoBrown", V(2.4, 0.9, 0.04), CF(5.1, 5.45, -11.19) * A(0, 0, math.rad(-5)), BROWN)
block("RearCamoGreen", V(3.0, 1.2, 0.04), CF(-4.3, 6.0, 12.89) * A(0, 0, math.rad(-4)), GREEN)
block("RearCamoBrown", V(3.0, 1.0, 0.04), CF(4.4, 5.6, 12.89) * A(0, 0, math.rad(5)), BROWN)
block("MantletCamoBrown", V(2.2, 1.2, 0.04), CF(-2.0, 10.0, -4.14) * A(0, 0, math.rad(5)), BROWN)
block("MantletCamoGreen", V(1.8, 1.0, 0.04), CF(2.2, 8.2, -4.14) * A(0, 0, math.rad(-4)), GREEN)

for k, p in { { 20, 9.5 }, { 80, 8.7 }, { 115, 9.6 }, { 145, 8.9 } } do
	local th = math.rad(p[1])
	block(
		"TurretCamo",
		V(0.04, 1.6, 2.0),
		CF(4.74 * math.cos(th), p[2], 3.0 + 4.74 * math.sin(th))
			* A(0, -th, 0)
			* A(math.rad(4), 0, 0),
		if k % 2 == 1 then GREEN else BROWN
	)
end

block("DeckCamoGreen", V(2.0, 0.04, 1.0), CF(-4.6, 7.24, 6.0) * A(0, math.rad(4), 0), GREEN)
block("DeckCamoBrown", V(1.6, 0.04, 2.0), CF(5.2, 7.24, 3.5) * A(0, math.rad(-5), 0), BROWN)

gun("BarrelCamoGreen", 1.6, 0.8, -12.6, GREEN)
gun("BarrelCamoBrown", 1.2, 0.72, -16.5, BROWN)

return {
	name = "Tiger I Tank",
	-- Real: 38 km/h, 0-30 km/h in 12 s, brakes 0.4 g, coasts 0.15 g (VehicleDefaults maps them).
	speed = 24,
	acceleration = 2.9,
	braking = 9.1,
	coasting = 4.7,
	turnRate = 1.5,
	footprint = Vector2.new(14.2, 25.0),
	collision = {
		{ size = V(14.2, 3.6, 24.6), offset = CF(0, 3.0, 0.1) },
		{ size = V(12.6, 2.4, 25.4), offset = CF(0, 6.0, 0.1) },
		{ size = V(9.4, 3.7, 12.0), offset = CF(0, 9.1, 1.9) },
	},
	seats = {
		CF(-3.2, 5.2, -7.9), -- driver, in the open hull hatch
		CF(-2.7, 9.1, 2.4), -- commander, in the cupola
		CF(-3.2, 7.75, 11.7), -- rider L, engine deck
		CF(3.2, 7.75, 11.7), -- rider R, engine deck
	},
	pieces = pieces,
}
