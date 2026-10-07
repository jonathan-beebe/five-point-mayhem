-- Ambulance: Type III ambulance, Ford E-450 cutaway cab with a white modular box body.
-- Scale: 4 studs = 1 m. Front axle z -9.8, rear axle z 6.25, front track 6.9, rear duals.

local rgb = Color3.fromRGB
local M = Enum.Material
local A = CFrame.Angles
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball
local CYLINDER_Z = A(0, math.rad(90), 0) -- cylinder axis along Z
local CYLINDER_Y = A(0, 0, math.rad(90)) -- cylinder axis along Y
-- WedgePart default: full bottom and full back (+Z) faces, slope rising toward +Z.
local FLIP_Z = A(0, 0, math.pi) -- right angle at (ymax, zmax)
local FLIP_X = A(math.pi, 0, 0) -- right angle at (ymax, zmin)
local REV = A(0, math.pi, 0) -- slope rises toward -Z
local RAKE = A(math.rad(31.8), 0, 0) -- windshield rake, top toward +Z
local WHEEL_TILT = A(math.rad(-35), 0, 0) * CYLINDER_Z -- steering axis rises toward the driver

-- Palette: { color, material, reflectance, transparency }
local WHITE = { rgb(244, 245, 242), M.SmoothPlastic, 0.08 }
local STRIPE_RED = { rgb(196, 22, 28), M.SmoothPlastic, 0.12 }
local CHROME = { rgb(205, 208, 212), M.Metal, 0.3 }
local STAINLESS = { rgb(175, 178, 182), M.Metal }
local ALUM = { rgb(190, 192, 195), M.Metal }
local DIAMOND = { rgb(170, 172, 175), M.DiamondPlate }
local BLACK_TRIM = { rgb(28, 28, 30), M.SmoothPlastic }
local GRILLE_BLACK = { rgb(18, 18, 20), M.SmoothPlastic }
local GAP = { rgb(40, 40, 42), M.SmoothPlastic }
local PLATE = { rgb(235, 235, 230), M.SmoothPlastic }
local GLASS = { rgb(40, 52, 60), M.Glass, 0.1, 0.4 }
local GLASS_DARK = { rgb(30, 35, 40), M.Glass, 0.1, 0.45 }
local MIRROR = { rgb(180, 190, 200), M.Glass, 0.4 }
local NEON_RED = { rgb(255, 30, 30), M.Neon }
local NEON_AMBER = { rgb(255, 150, 20), M.Neon }
local NEON_WARM = { rgb(255, 244, 214), M.Neon }
local NEON_COOL = { rgb(230, 240, 255), M.Neon }
local SCENE_LENS = { rgb(235, 238, 240), M.SmoothPlastic, 0.3 }
local RED_LENS = { rgb(170, 20, 20), M.SmoothPlastic, 0.2 }
local TIRE = { rgb(26, 26, 28), M.Fabric }
local STEEL_WHEEL = { rgb(200, 202, 205), M.Metal }
local CHASSIS = { rgb(35, 35, 37), M.Metal }
local INTERIOR_DARK = { rgb(45, 46, 50), M.SmoothPlastic }
local DASH = { rgb(38, 39, 42), M.SmoothPlastic }
local SEAT_FABRIC = { rgb(70, 72, 78), M.Fabric }
local FLOOR = { rgb(120, 125, 130), M.SmoothPlastic }
local COT_YELLOW = { rgb(230, 190, 30), M.SmoothPlastic }
local COT_PAD = { rgb(30, 40, 70), M.Fabric }
local BENCH_VINYL = { rgb(40, 70, 120), M.SmoothPlastic }
local CABINET = { rgb(205, 210, 215), M.SmoothPlastic }
local AC_GRAY = { rgb(215, 218, 220), M.SmoothPlastic }

local FRONT_AXLE = -9.8
local REAR_AXLE = 6.25
local WHEEL_Y = 1.5

local V = Vector3.new
local C = CFrame.new

local pieces = {}

local function add(name, size, offset, token, class, shape)
	table.insert(pieces, {
		name = name,
		class = class,
		shape = shape,
		size = size,
		offset = offset,
		color = token[1],
		material = token[2],
		reflectance = token[3],
		transparency = token[4],
	})
end

local function part(name, size, offset, token)
	add(name, size, offset, token)
end

local function wedge(name, size, offset, token)
	add(name, size, offset, token, "WedgePart")
end

local function cyl(name, size, offset, token)
	add(name, size, offset, token, nil, CYL)
end

local function mirror(fn)
	fn(-1)
	fn(1)
end

---------------------------------------------------------------------------------------------------
-- Cab body
---------------------------------------------------------------------------------------------------
part("EngineCore", V(5.9, 2.9, 3.6), C(0, 3.45, -11.3), WHITE)
part("FenderBand", V(7.6, 1.6, 3.6), C(0, 4.1, -11.3), WHITE)
wedge("Hood", V(7.2, 0.6, 3.6), C(0, 5.2, -11.3), WHITE)
part("Cowl", V(7.2, 0.15, 0.5), C(0, 5.55, -9.45), BLACK_TRIM)
part("CabLower", V(7.7, 1.9, 3.7), C(0, 3.05, -6.15), WHITE)
part("WindshieldHeader", V(7.6, 0.35, 0.3), C(0, 8.68, -7.65), WHITE)
part("CabRoof", V(7.9, 0.2, 3.45), C(0, 8.95, -5.875), WHITE)
part("CabBackWall", V(7.9, 4.9, 0.1), C(0, 6.45, -4.3), WHITE)

mirror(function(s)
	part("FrontLowerFender", V(0.85, 1.3, 1.5), C(s * 3.375, 2.65, -12.35), WHITE)
	wedge("ArchFrontChamfer", V(0.85, 0.8, 0.8), C(s * 3.375, 2.9, -11.2) * FLIP_X, WHITE)
	part("RearFender", V(0.3, 2.3, 1.5), C(s * 3.75, 4.45, -8.75), WHITE)
	wedge("ArchRearChamfer", V(0.3, 0.8, 0.8), C(s * 3.75, 2.9, -8.4) * FLIP_Z, WHITE)
	part("WheelLip", V(0.1, 0.12, 3.6), C(s * 3.85, 3.3, -9.8), BLACK_TRIM)
	part("DoorSkin", V(0.1, 4.0, 3.65), C(s * 3.9, 4.1, -6.175), WHITE)
	part("DoorGapFront", V(0.04, 4.0, 0.06), C(s * 3.97, 4.1, -7.98), GAP)
	part("DoorGapRear", V(0.04, 4.0, 0.06), C(s * 3.97, 4.1, -4.4), GAP)
	part("DoorHandle", V(0.08, 0.18, 0.6), C(s * 4.03, 5.6, -4.9), BLACK_TRIM)
	part("APillar", V(0.35, 3.45, 0.35), C(s * 3.6, 7.05, -8.5) * RAKE, WHITE)
	part("SideWindowRail", V(0.12, 0.35, 3.4), C(s * 3.9, 8.68, -5.95), WHITE)
	part("RearWindowPost", V(0.12, 2.6, 0.3), C(s * 3.9, 7.4, -4.45), WHITE)
	part("CabStep", V(0.5, 0.15, 3.2), C(s * 4.05, 2.0, -6.2), BLACK_TRIM)
	part("Wiper", V(2.8, 0.08, 0.1), C(s * 1.6, 5.9, -9.31) * RAKE, BLACK_TRIM)
	part("HeadlampBezel", V(1.3, 1.1, 0.1), C(s * 2.75, 4.15, -13.15), BLACK_TRIM)
	part("BumperEndCap", V(0.3, 1.0, 0.8), C(s * 3.95, 2.1, -13.3), CHROME)
	part("MirrorArmUpper", V(1.0, 0.1, 0.1), C(s * 4.4, 8.3, -7.4), BLACK_TRIM)
	part("MirrorArmLower", V(1.0, 0.1, 0.1), C(s * 4.4, 7.0, -7.4), BLACK_TRIM)
	part("MirrorHead", V(0.35, 1.7, 0.9), C(s * 5.05, 7.65, -7.4), BLACK_TRIM)
	part("MirrorGlass", V(0.28, 1.5, 0.04), C(s * 5.05, 7.65, -6.93), MIRROR)
end)

part("GrilleSurround", V(3.9, 1.5, 0.12), C(0, 4.05, -13.14), CHROME)
part("GrilleMesh", V(3.5, 1.15, 0.1), C(0, 4.05, -13.22), GRILLE_BLACK)
part("GrilleBar", V(3.5, 0.12, 0.06), C(0, 3.85, -13.28), CHROME)
part("GrilleBar", V(3.5, 0.12, 0.06), C(0, 4.3, -13.28), CHROME)
part("LowerValance", V(7.0, 0.6, 0.1), C(0, 2.9, -13.15), BLACK_TRIM)
part("Bumper", V(7.8, 1.0, 0.6), C(0, 2.1, -13.45), CHROME)
part("LicensePlate", V(1.2, 0.6, 0.05), C(0, 2.1, -13.775), PLATE)
part("SirenSpeaker", V(0.8, 0.7, 0.2), C(-1.6, 2.1, -13.85), BLACK_TRIM)

---------------------------------------------------------------------------------------------------
-- Glass
---------------------------------------------------------------------------------------------------
part("Windshield", V(7.0, 3.41, 0.1), C(0, 7.05, -8.5) * RAKE, GLASS)
mirror(function(s)
	wedge("QuarterGlass", V(0.1, 2.9, 1.8), C(s * 3.85, 7.05, -8.5), GLASS)
	part("CabSideGlass", V(0.08, 2.4, 3.0), C(s * 3.88, 7.3, -6.05), GLASS)
	part("RearDoorWindow", V(2.95, 2.4, 0.06), C(s * 1.955, 8.6, 12.99), GLASS_DARK)
end)
part("EntryDoorWindow", V(0.06, 2.2, 3.0), C(4.73, 8.5, -1.6), GLASS_DARK)

---------------------------------------------------------------------------------------------------
-- Box shell
---------------------------------------------------------------------------------------------------
part("LeftWall", V(0.15, 7.5, 17.15), C(-4.725, 7.15, 4.425), WHITE)
part("RightWallFront", V(0.15, 7.5, 0.55), C(4.725, 7.15, -3.875), WHITE)
part("RightWallRear", V(0.15, 7.5, 12.6), C(4.725, 7.15, 6.7), WHITE)
part("RightWallOverDoor", V(0.15, 0.7, 4.0), C(4.725, 10.55, -1.6), WHITE)
part("EntryDoorLower", V(0.15, 3.9, 4.0), C(4.725, 5.45, -1.6), WHITE)
part("EntryDoorTop", V(0.15, 0.6, 4.0), C(4.725, 9.9, -1.6), WHITE)
part("EntryDoorStile", V(0.15, 2.2, 0.5), C(4.725, 8.5, -3.35), WHITE)
part("EntryDoorStile", V(0.15, 2.2, 0.5), C(4.725, 8.5, 0.15), WHITE)
part("FrontWall", V(9.3, 7.5, 0.15), C(0, 7.15, -4.075), WHITE)
part("BoxRoof", V(9.6, 0.15, 17.15), C(0, 10.975, 4.425), WHITE)
part("BoxFloor", V(9.3, 0.15, 16.9), C(0, 3.475, 4.45), FLOOR)
part("RearHeader", V(7.8, 0.6, 0.15), C(0, 10.6, 12.925), WHITE)
part("RearSill", V(7.8, 0.1, 0.15), C(0, 3.45, 12.925), WHITE)
part("SkirtFront", V(9.6, 1.2, 8.55), C(0, 2.8, 0.125), WHITE)
part("SkirtRear", V(9.6, 1.2, 4.9), C(0, 2.8, 10.55), WHITE)
part("WheelWellLiner", V(9.5, 0.06, 3.7), C(0, 3.36, REAR_AXLE), BLACK_TRIM)
part("RoofEdgeFront", V(9.8, 0.2, 0.2), C(0, 10.98, -4.17), ALUM)
part("RoofEdgeRear", V(9.8, 0.2, 0.2), C(0, 10.98, 13.02), ALUM)

mirror(function(s)
	part("RearCornerPost", V(0.75, 7.5, 0.15), C(s * 4.275, 7.15, 12.925), WHITE)
	wedge("RearArchFrontChamfer", V(0.35, 0.9, 0.9), C(s * 4.625, 2.95, 4.85) * FLIP_X, WHITE)
	wedge("RearArchRearChamfer", V(0.35, 0.9, 0.9), C(s * 4.625, 2.95, 7.65) * FLIP_Z, WHITE)
	part("ArchFlare", V(0.2, 0.3, 3.9), C(s * 4.85, 3.4, REAR_AXLE), BLACK_TRIM)
	part("CornerExtrusionFront", V(0.25, 7.7, 0.25), C(s * 4.8, 7.15, -4.15), ALUM)
	part("CornerExtrusionRear", V(0.25, 7.7, 0.25), C(s * 4.8, 7.15, 13.0), ALUM)
	part("RoofEdgeSide", V(0.2, 0.2, 17.3), C(s * 4.82, 10.98, 4.425), ALUM)
	part("RubRailFront", V(0.1, 0.2, 8.55), C(s * 4.85, 2.3, 0.125), STAINLESS)
	part("RubRailRear", V(0.1, 0.2, 4.9), C(s * 4.85, 2.3, 10.55), STAINLESS)
end)

---------------------------------------------------------------------------------------------------
-- Compartments and doors
---------------------------------------------------------------------------------------------------
local function compartment(s, z0, z1, y0, y1, handleY)
	local w, h = z1 - z0, y1 - y0
	local zc, yc = (z0 + z1) / 2, (y0 + y1) / 2
	part("CompartmentGap", V(0.04, h + 0.12, w + 0.12), C(s * 4.82, yc, zc), GAP)
	part("CompartmentDoor", V(0.06, h, w), C(s * 4.85, yc, zc), WHITE)
	part("CompartmentHandle", V(0.08, 0.25, 0.7), C(s * 4.92, handleY, zc), CHROME)
end

compartment(-1, -3.8, -0.8, 2.4, 10.0, 6.8) -- tall O2 compartment
compartment(-1, -0.5, 4.1, 2.4, 7.6, 4.2)
compartment(-1, 8.4, 12.6, 2.4, 7.6, 4.2)
compartment(1, 0.8, 4.1, 2.4, 7.6, 4.2)
compartment(1, 8.4, 12.6, 2.4, 7.6, 4.2)

-- Curb-side entry door
part("EntryGapFront", V(0.04, 6.7, 0.06), C(4.82, 6.85, -3.62), GAP)
part("EntryGapRear", V(0.04, 6.7, 0.06), C(4.82, 6.85, 0.42), GAP)
part("EntryGapTop", V(0.04, 0.06, 4.1), C(4.82, 10.22, -1.6), GAP)
part("EntryHandle", V(0.08, 0.25, 0.7), C(4.92, 6.8, -0.3), CHROME)
cyl("GrabRail", V(2.6, 0.12, 0.12), C(4.95, 7.0, 0.7) * CYLINDER_Y, CHROME)
part("GrabRailMountTop", V(0.15, 0.1, 0.1), C(4.86, 8.2, 0.7), CHROME)
part("GrabRailMountBottom", V(0.15, 0.1, 0.1), C(4.86, 5.8, 0.7), CHROME)
part("KickPlate", V(0.06, 1.1, 3.8), C(4.83, 2.85, -1.6), DIAMOND)
part("StepTread", V(0.6, 0.12, 3.6), C(5.05, 2.25, -1.6), DIAMOND)

-- Rear double doors
mirror(function(s)
	part("RearDoorLower", V(3.85, 3.9, 0.14), C(s * 1.955, 5.45, 12.99), WHITE)
	part("RearDoorTop", V(3.85, 0.5, 0.14), C(s * 1.955, 10.05, 12.99), WHITE)
	part("RearDoorInnerStile", V(0.45, 2.4, 0.14), C(s * 0.255, 8.6, 12.99), WHITE)
	part("RearDoorOuterStile", V(0.45, 2.4, 0.14), C(s * 3.655, 8.6, 12.99), WHITE)
	part("RearDoorHandle", V(0.8, 0.15, 0.12), C(s * 0.6, 6.8, 13.12), CHROME)
	for _, y in { 4.4, 7.0, 9.6 } do
		part("RearDoorHinge", V(0.25, 0.35, 0.1), C(s * 3.83, y, 13.05), STAINLESS)
	end
end)
part("RearDoorSeam", V(0.1, 6.8, 0.1), C(0, 6.9, 12.92), GAP)

---------------------------------------------------------------------------------------------------
-- Red stripe
---------------------------------------------------------------------------------------------------
mirror(function(s)
	part("BoxBand", V(0.1, 0.8, 17.2), C(s * 4.85, 5.6, 4.425), STRIPE_RED)
	part("BoxPinstripe", V(0.1, 0.15, 17.2), C(s * 4.85, 6.275, 4.425), STRIPE_RED)
	part("CabDoorBand", V(0.06, 0.7, 3.65), C(s * 3.97, 5.55, -6.175), STRIPE_RED)
	part("BoxFrontBand", V(0.85, 0.8, 0.06), C(s * 4.375, 5.6, -4.18), STRIPE_RED)
	part("RearPostBand", V(0.75, 0.8, 0.08), C(s * 4.275, 5.6, 13.04), STRIPE_RED)
	part("RearDoorBand", V(3.85, 0.8, 0.04), C(s * 1.955, 5.6, 13.08), STRIPE_RED)
	part("RearDoorPinstripe", V(3.85, 0.15, 0.04), C(s * 1.955, 6.275, 13.08), STRIPE_RED)
end)

---------------------------------------------------------------------------------------------------
-- Lights
---------------------------------------------------------------------------------------------------
mirror(function(s)
	-- Cab front
	part("Headlamp", V(1.0, 0.7, 0.06), C(s * 2.7, 4.2, -13.21), NEON_WARM)
	part("FrontTurn", V(0.3, 0.7, 0.1), C(s * 3.55, 4.2, -13.15), NEON_AMBER)
	part("GrilleWarning", V(0.5, 0.3, 0.06), C(s * 1.0, 4.07, -13.27), NEON_RED)
	part("BumperFlasher", V(0.5, 0.25, 0.06), C(s * 2.9, 2.15, -13.77), NEON_RED)
	part("FenderMarker", V(0.06, 0.3, 0.5), C(s * 3.82, 4.3, -12.5), NEON_AMBER)

	-- Box front header
	part("FrontCornerLight", V(0.8, 0.8, 0.1), C(s * 4.3, 10.2, -4.18), NEON_RED)
	part("FrontCenterLight", V(0.8, 0.6, 0.1), C(s * 1.4, 10.2, -4.18), NEON_RED)

	-- Box sides
	part("SideFrontWrap", V(0.1, 0.8, 0.8), C(s * 4.87, 10.2, -3.6), NEON_RED)
	part("SideMidLight", V(0.1, 0.8, 0.8), C(s * 4.87, 10.2, 4.4), NEON_RED)
	part("SideRearWrap", V(0.1, 0.8, 0.8), C(s * 4.87, 10.2, 12.45), NEON_RED)
	part("SceneLight", V(0.1, 0.45, 1.2), C(s * 4.87, 10.25, 1.5), SCENE_LENS)
	part("SceneLight", V(0.1, 0.45, 1.2), C(s * 4.87, 10.25, 8.5), SCENE_LENS)
	part("SideMarkerFront", V(0.08, 0.25, 0.25), C(s * 4.85, 3.0, -3.98), NEON_AMBER)
	part("SideMarkerRear", V(0.08, 0.25, 0.3), C(s * 4.85, 3.0, 12.82), NEON_RED)

	-- Rear face
	part("RearCornerLight", V(0.7, 0.9, 0.1), C(s * 4.27, 10.2, 13.03), NEON_RED)
	part("RearCenterAmber", V(1.0, 0.4, 0.1), C(s * 1.4, 10.6, 13.03), NEON_AMBER)
	part("RearFlood", V(0.7, 0.35, 0.08), C(s * 2.8, 10.6, 13.03), SCENE_LENS)
	part("TailLamp", V(0.6, 0.7, 0.1), C(s * 4.27, 4.85, 13.03), NEON_RED)
	part("RearTurn", V(0.6, 0.6, 0.1), C(s * 4.27, 4.2, 13.03), NEON_AMBER)
	part("ReverseLamp", V(0.6, 0.35, 0.1), C(s * 4.27, 3.65, 13.03), NEON_COOL)
	part("RearReflector", V(0.5, 0.3, 0.1), C(s * 4.27, 6.8, 13.03), RED_LENS)
end)
part("FrontCenterWhite", V(1.0, 0.6, 0.1), C(0, 10.2, -4.18), NEON_COOL)
for _, x in { -0.6, 0, 0.6 } do
	part("FrontIdLamp", V(0.3, 0.15, 0.08), C(x, 10.75, -4.18), NEON_AMBER)
end
for _, x in { -0.45, 0, 0.45 } do
	part("RearIdLamp", V(0.25, 0.15, 0.08), C(x, 10.6, 13.03), NEON_RED)
end

---------------------------------------------------------------------------------------------------
-- Wheels
---------------------------------------------------------------------------------------------------
local function lugs(x, z, radius)
	for k = 0, 7 do
		local a = math.rad(k * 45)
		cyl(
			"Lug",
			V(0.1, 0.14, 0.14),
			C(x, WHEEL_Y + radius * math.sin(a), z + radius * math.cos(a)),
			CHROME
		)
	end
end

mirror(function(s)
	-- Front
	cyl("FrontTire", V(0.9, 3.0, 3.0), C(s * 3.45, WHEEL_Y, FRONT_AXLE), TIRE)
	cyl("FrontRim", V(0.06, 1.75, 1.75), C(s * 3.92, WHEEL_Y, FRONT_AXLE), STEEL_WHEEL)
	cyl("FrontHub", V(0.3, 0.8, 0.8), C(s * 4.0, WHEEL_Y, FRONT_AXLE), CHROME)
	lugs(s * 3.99, FRONT_AXLE, 0.55)

	-- Rear duals
	cyl("RearInnerTire", V(0.85, 3.0, 3.0), C(s * 3.05, WHEEL_Y, REAR_AXLE), TIRE)
	cyl("RearOuterTire", V(0.85, 3.0, 3.0), C(s * 3.95, WHEEL_Y, REAR_AXLE), TIRE)
	cyl("RearRim", V(0.06, 1.75, 1.75), C(s * 4.39, WHEEL_Y, REAR_AXLE), STEEL_WHEEL)
	cyl("RearHub", V(0.4, 0.9, 0.9), C(s * 4.5, WHEEL_Y, REAR_AXLE), CHROME)
	lugs(s * 4.44, REAR_AXLE, 0.6)
end)

---------------------------------------------------------------------------------------------------
-- Chassis, rear step, roof gear
---------------------------------------------------------------------------------------------------
mirror(function(s)
	part("FrameRail", V(0.35, 0.6, 19.0), C(s * 1.7, 1.9, 0.5), CHASSIS)
	part("Mudflap", V(1.9, 1.6, 0.06), C(s * 3.5, 1.4, 8.2), BLACK_TRIM)
	part("DockBumper", V(0.7, 0.6, 0.2), C(s * 3.6, 1.85, 13.85), BLACK_TRIM)
	part("RoofVent", V(0.9, 0.25, 0.9), C(s * 2.0, 11.17, 2.0), WHITE)
	cyl("Antenna", V(1.4, 0.06, 0.06), C(s * 1.2, 11.75, -2.5) * CYLINDER_Y, BLACK_TRIM)
end)
cyl("RearAxle", V(6.2, 0.6, 0.6), C(0, WHEEL_Y, REAR_AXLE), CHASSIS)
add("Differential", V(1.0, 1.0, 1.0), C(0.3, 1.45, REAR_AXLE), CHASSIS, nil, BALL)
part("FrontAxle", V(5.8, 0.35, 0.35), C(0, WHEEL_Y, FRONT_AXLE), CHASSIS)
cyl("Driveshaft", V(14, 0.3, 0.3), C(0, 1.6, -1.6) * CYLINDER_Z, CHASSIS)
part("FuelTank", V(2.6, 0.9, 3.0), C(0, 1.65, 10.4), BLACK_TRIM)
cyl("ExhaustPipe", V(8, 0.25, 0.25), C(-3.5, 1.8, -0.4) * CYLINDER_Z, CHASSIS)
cyl("ExhaustTip", V(1.4, 0.3, 0.3), C(-4.2, 1.8, 3.6), CHROME)
part("RearStep", V(8.6, 0.25, 0.8), C(0, 2.27, 13.4), DIAMOND)
part("RearStepFace", V(8.6, 0.6, 0.1), C(0, 1.85, 13.75), BLACK_TRIM)
part("AcCondenser", V(2.6, 0.5, 2.2), C(0, 11.3, 9.0), AC_GRAY)
cyl("AcFanGrille", V(0.06, 1.4, 1.4), C(0, 11.58, 9.0) * CYLINDER_Y, GRILLE_BLACK)

---------------------------------------------------------------------------------------------------
-- Interior
---------------------------------------------------------------------------------------------------
part("CabFloor", V(7.6, 0.2, 4.6), C(0, 3.9, -6.6), INTERIOR_DARK)
part("EngineDoghouse", V(1.8, 1.4, 2.6), C(0, 4.7, -7.4), INTERIOR_DARK)
part("Dash", V(7.2, 0.7, 1.0), C(0, 6.15, -8.6), DASH)
part("DashPad", V(7.0, 0.1, 0.8), C(0, 6.55, -8.7), INTERIOR_DARK)
part("GaugeBinnacle", V(1.6, 0.4, 0.5), C(-2.0, 6.7, -8.2), DASH)
cyl("SteeringWheel", V(0.12, 1.5, 1.5), C(-2.0, 6.5, -7.1) * WHEEL_TILT, DASH)
cyl("SteeringHub", V(0.2, 0.4, 0.4), C(-2.0, 6.5, -7.1) * WHEEL_TILT, DASH)
cyl("SteeringColumn", V(1.3, 0.25, 0.25), C(-2.0, 6.13, -7.63) * WHEEL_TILT, DASH)

mirror(function(s)
	part("CabSeatCushion", V(1.9, 0.45, 1.8), C(s * 2.0, 4.38, -5.5), SEAT_FABRIC)
	part("CabSeatBack", V(1.9, 2.6, 0.35), C(s * 2.0, 6.0, -4.75), SEAT_FABRIC)
	part("CabHeadrest", V(1.2, 0.8, 0.35), C(s * 2.0, 7.7, -4.75), SEAT_FABRIC)
	part("UpperCabinet", V(1.0, 1.5, 8.0), C(s * 4.1, 9.9, 7.5), CABINET)
end)

part("CaptainCushion", V(1.9, 0.45, 1.8), C(-2.0, 4.58, -1.0), SEAT_FABRIC)
part("CaptainBack", V(1.9, 2.4, 0.35), C(-2.0, 6.0, -0.15), SEAT_FABRIC)
part("CotBase", V(1.8, 1.2, 6.0), C(-1.2, 4.2, 5.2), CHASSIS)
part("CotFrame", V(2.3, 0.2, 7.6), C(-1.2, 4.9, 5.2), COT_YELLOW)
part("Mattress", V(2.0, 0.35, 7.2), C(-1.2, 5.18, 5.2), COT_PAD)
wedge("CotHeadSection", V(2.0, 0.8, 1.6), C(-1.2, 5.75, 2.4) * REV, COT_PAD)
part("BenchSeat", V(1.5, 1.1, 6.0), C(3.85, 4.1, 5.0), BENCH_VINYL)
part("BenchBack", V(0.3, 1.8, 6.0), C(4.45, 5.6, 5.0), BENCH_VINYL)

return {
	name = "Ambulance",
	-- Real: 130 km/h, 0-100 km/h in 18 s, brakes 0.6 g, coasts 0.12 g (VehicleDefaults maps them).
	speed = 54,
	acceleration = 4.9,
	braking = 11.9,
	coasting = 4.1,
	turnRate = 2,
	footprint = Vector2.new(9.4, 27.6),
	collision = {
		{ size = V(9.6, 8.85, 17.15), offset = C(0, 6.625, 4.425) }, -- box, y 2.2..11.05
		{ size = V(7.8, 4.2, 9.6), offset = C(0, 3.5, -9.0) }, -- hood + cab lower, y 1.4..5.6
		{ size = V(7.8, 3.4, 3.6), offset = C(0, 7.3, -6.0) }, -- cab upper, y 5.6..9.0
		{ size = V(8.6, 0.8, 0.8), offset = C(0, 2.0, 13.4) }, -- rear step, y 1.6..2.4
	},
	seats = {
		C(-2.0, 4.1, -5.6), -- driver (LHD)
		C(2.0, 4.1, -5.6), -- cab passenger
		C(-2.0, 4.3, -1.0), -- box captain chair
		C(2.9, 4.3, 5.0), -- box squad bench
	},
	pieces = pieces,
}
