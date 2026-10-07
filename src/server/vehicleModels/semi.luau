-- Peterbilt 389 Semi: long-hood Class 8 tractor with a 63-inch flat-top sleeper, chrome stacks and tandem duals.
-- Scale: 4 studs = 1 m. Front axle z -13.8, drive axles z 8.4 and 13.6, LHD.

local rgb = Color3.fromRGB
local M = Enum.Material
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball
local A = CFrame.Angles
local CYLINDER_Z = A(0, math.rad(90), 0) -- cylinder axis along Z
local CYLINDER_Y = A(0, 0, math.rad(90)) -- cylinder axis along Y
local SIDE_L = A(0, math.pi / 2, 0) -- wedge length along Z, tall face toward +X, slope falls to -X
local SIDE_R = A(0, -math.pi / 2, 0) -- wedge length along Z, tall face toward -X, slope falls to +X
local REAR_DOWN = A(0, math.pi, 0) -- wedge tall face at -Z, slope falls toward +Z

-- Palette: { color, material, reflectance, transparency }.
local PAINT = { rgb(128, 14, 20), M.SmoothPlastic, 0.12 }
local CHROME = { rgb(214, 216, 222), M.Metal, 0.35 }
local ALUMINUM = { rgb(200, 204, 210), M.Metal, 0.25 }
local STAINLESS = { rgb(160, 163, 168), M.Metal, 0.2 }
local SHIELD = { rgb(180, 184, 190), M.DiamondPlate }
local DIAMOND = { rgb(185, 188, 194), M.DiamondPlate }
local FRAME_BLACK = { rgb(22, 22, 24), M.Metal }
local MECH_GRAY = { rgb(48, 48, 52), M.Metal }
local FIFTH_BLACK = { rgb(30, 30, 32), M.Metal }
local TIRE = { rgb(28, 28, 30), M.SmoothPlastic }
local HOLE_DARK = { rgb(16, 16, 18), M.SmoothPlastic }
local GRILLE_BLACK = { rgb(18, 18, 20), M.SmoothPlastic }
local CAP_BLACK = { rgb(20, 20, 22), M.SmoothPlastic }
local FLAP_BLACK = { rgb(18, 18, 18), M.Fabric }
local SEAM = { rgb(40, 8, 10), M.SmoothPlastic }
local GLASS = { rgb(36, 48, 56), M.Glass, 0, 0.45 }
local MIRROR = { rgb(150, 165, 178), M.Glass, 0.3 }
local HEAD_NEON = { rgb(255, 244, 214), M.Neon }
local AMBER_NEON = { rgb(255, 150, 20), M.Neon }
local TAIL_NEON = { rgb(220, 20, 20), M.Neon }
local BADGE_RED = { rgb(185, 20, 28), M.SmoothPlastic, 0.1 }
local HOOK_RED = { rgb(190, 30, 30), M.SmoothPlastic }
local HOSE_RED = HOOK_RED
local HOSE_BLUE = { rgb(40, 80, 180), M.SmoothPlastic }
local PLATE_WHITE = { rgb(230, 230, 225), M.SmoothPlastic }
local DASH = { rgb(38, 36, 36), M.SmoothPlastic }
local GAUGE = { rgb(225, 225, 215), M.SmoothPlastic }
local SEAT = { rgb(88, 72, 60), M.Fabric }
local CURTAIN = { rgb(70, 66, 62), M.Fabric }

local V = Vector3.new
local C = CFrame.new

local pieces = {}

local function part(name, size, offset, style, shape, class)
	table.insert(pieces, {
		name = name,
		class = class,
		shape = shape,
		size = size,
		offset = offset,
		color = style[1],
		material = style[2],
		reflectance = style[3],
		transparency = style[4],
	})
end

local function cyl(name, size, offset, style)
	part(name, size, offset, style, CYL)
end

local function wedge(name, size, offset, style)
	part(name, size, offset, style, nil, "WedgePart")
end

-- Wheels --------------------------------------------------------------------
local AXLE_Y = 2.1
local HAND_HOLE_ANGLES = { 0, 72, 144, 216, 288 }

-- kind: "front" | "outer" (full rim dressing) | "inner" (tire only).
local function wheel(x, z, outerSign, kind)
	cyl("Tire", V(1.2, 4.2, 4.2), C(x, AXLE_Y, z), TIRE)
	if kind == "inner" then
		return
	end
	local hubSize = kind == "front" and 1.1 or 1.2
	local capSize = kind == "front" and 0.6 or 0.7
	local face = x + outerSign * 0.63
	cyl("Rim", V(1.26, 2.5, 2.5), C(x, AXLE_Y, z), ALUMINUM)
	cyl("LugRing", V(0.12, 1.5, 1.5), C(face + outerSign * 0.03, AXLE_Y, z), CHROME)
	cyl("Hub", V(0.3, hubSize, hubSize), C(face + outerSign * 0.12, AXLE_Y, z), CHROME)
	part(
		"HubCap",
		V(capSize, capSize, capSize),
		C(face + outerSign * 0.27, AXLE_Y, z),
		CHROME,
		BALL
	)
	for _, deg in HAND_HOLE_ANGLES do
		local a = math.rad(deg)
		cyl(
			"HandHole",
			V(0.06, 0.36, 0.36),
			C(face, AXLE_Y + 0.95 * math.cos(a), z + 0.95 * math.sin(a)),
			HOLE_DARK
		)
	end
end

-- 4.1 Front bumper and grille -----------------------------------------------
part("Bumper", V(9.8, 1.6, 0.8), C(0, 2.7, -17.2), CHROME)
part("BumperValance", V(9.4, 0.3, 0.6), C(0, 1.75, -17.1), FRAME_BLACK)
part("FrontPlate", V(1.2, 0.6, 0.05), C(0, 2.7, -17.63), PLATE_WHITE)
for _, s in { -1, 1 } do
	part("TowHook", V(0.3, 0.5, 0.5), C(s * 2.6, 1.75, -17.45), HOOK_RED)
	cyl("FogLamp", V(0.06, 0.5, 0.5), C(s * 3.6, 2.7, -17.62) * CYLINDER_Z, HEAD_NEON)
	part("GrillePost", V(0.35, 4.7, 0.45), C(s * 2.125, 6.0, -16.5), CHROME)
end
part("GrilleTopBar", V(4.6, 0.45, 0.5), C(0, 8.17, -16.5), CHROME)
part("GrilleBottomBar", V(4.6, 0.35, 0.5), C(0, 3.8, -16.5), CHROME)
part("GrilleBacking", V(3.9, 4.3, 0.1), C(0, 6.0, -16.32), GRILLE_BLACK)
for i = 0, 11 do
	part("GrilleSlat", V(3.9, 0.1, 0.14), C(0, 4.25 + i * 0.33, -16.5), CHROME)
end
part("BadgeBack", V(1.5, 0.7, 0.06), C(0, 8.05, -16.77), CHROME)
part("BadgeRed", V(1.3, 0.5, 0.06), C(0, 8.05, -16.81), BADGE_RED)

-- 4.2 Hood and fenders ------------------------------------------------------
part("HoodCenter", V(3.9, 3.9, 8.3), C(0, 6.4, -12.15), PAINT)
part("HoodOrnament", V(0.15, 0.35, 0.9), C(0, 8.52, -15.6), CHROME)
for _, s in { -1, 1 } do
	part("HoodSide", V(0.35, 3.55, 8.3), C(s * 2.125, 6.225, -12.15), PAINT)
	wedge(
		"HoodChamfer",
		V(8.3, 0.35, 0.35),
		C(s * 2.125, 8.175, -12.15) * (s < 0 and SIDE_L or SIDE_R),
		PAINT
	)
	part("HoodSideEmblem", V(0.04, 0.3, 1.6), C(s * 2.32, 7.2, -10.5), CHROME)
	for i = 0, 3 do
		part("HoodLouver", V(0.04, 0.08, 1.2), C(s * 2.32, 6.4 + i * 0.25, -15.1), GRILLE_BLACK)
	end
	part("FenderTop", V(2.6, 0.4, 2.4), C(s * 3.6, 5.4, -13.7), PAINT)
	wedge("FenderFront", V(2.6, 1.5, 1.9), C(s * 3.6, 4.85, -15.85), PAINT)
	wedge("FenderRear", V(2.6, 1.4, 2.3), C(s * 3.6, 4.9, -11.35) * REAR_DOWN, PAINT)
	part("FenderMarker", V(0.06, 0.25, 0.8), C(s * 4.94, 5.4, -13.7), AMBER_NEON)
end

-- 4.3 Headlights ------------------------------------------------------------
for _, s in { -1, 1 } do
	part("LampPedestal", V(1.5, 0.5, 0.5), C(s * 3.55, 4.6, -16.05), FRAME_BLACK)
	part("LampBezel", V(1.8, 0.9, 0.55), C(s * 3.55, 5.25, -15.95), CHROME)
	part("LensInner", V(0.5, 0.6, 0.05), C(s * 3.0, 5.25, -16.26), HEAD_NEON)
	part("LensMid", V(0.5, 0.6, 0.05), C(s * 3.55, 5.25, -16.26), HEAD_NEON)
	part("LensOuter", V(0.5, 0.6, 0.05), C(s * 4.1, 5.25, -16.26), AMBER_NEON)
end

-- 4.4 Air cleaners and steps ------------------------------------------------
for _, s in { -1, 1 } do
	local x = s * 3.35
	cyl("AirCleaner", V(3.0, 1.5, 1.5), C(x, 7.3, -9.2) * CYLINDER_Y, CHROME)
	cyl("AirCleanerBandTop", V(0.2, 1.6, 1.6), C(x, 8.6, -9.2) * CYLINDER_Y, STAINLESS)
	cyl("AirCleanerBandBottom", V(0.2, 1.6, 1.6), C(x, 6.0, -9.2) * CYLINDER_Y, STAINLESS)
	cyl("RainCap", V(0.15, 1.2, 1.2), C(x, 8.87, -9.2) * CYLINDER_Y, CAP_BLACK)
	cyl("IntakeElbow", V(0.4, 0.7, 0.7), C(s * 2.45, 7.8, -9.2), CHROME)
	part("StepLower", V(0.9, 0.12, 1.3), C(s * 4.4, 2.9, -8.75), DIAMOND)
	part("StepUpper", V(0.9, 0.12, 1.3), C(s * 4.4, 4.2, -8.75), DIAMOND)
	part("StepBackPlate", V(0.08, 2.0, 1.3), C(s * 3.92, 3.5, -8.75), CHROME)
end

-- 4.5 Cab shell and glass ---------------------------------------------------
local RAKE = A(math.rad(12), 0, 0)
part("CabFloor", V(7.6, 0.4, 4.4), C(0, 5.2, -5.8), FRAME_BLACK)
part("Firewall", V(7.6, 3.6, 0.3), C(0, 6.8, -7.85), PAINT)
part("CenterPost", V(0.3, 2.45, 0.3), C(0, 9.8, -7.75) * RAKE, PAINT)
part("Header", V(7.6, 0.6, 0.4), C(0, 11.3, -7.45), PAINT)
part("CabRoof", V(8.1, 0.2, 4.05), C(0, 11.7, -5.625), PAINT)
for _, s in { -1, 1 } do
	part("CabSideLower", V(0.25, 3.6, 4.4), C(s * 3.925, 6.8, -5.8), PAINT)
	part("APillar", V(0.35, 2.45, 0.35), C(s * 3.85, 9.8, -7.75) * RAKE, PAINT)
	part("DripRail", V(0.25, 0.6, 4.05), C(s * 3.925, 11.3, -5.625), PAINT)
	part("BPillar", V(0.25, 2.4, 1.0), C(s * 3.925, 9.8, -4.1), PAINT)
	part("Windshield", V(3.6, 2.45, 0.08), C(s * 1.95, 9.8, -7.75) * RAKE, GLASS)
	part("SideWindow", V(0.08, 2.2, 3.0), C(s * 3.95, 9.85, -6.1), GLASS)
	part(
		"Wiper",
		V(2.0, 0.06, 0.05),
		C(s * 1.95, 9.8, -7.75) * RAKE * C(0.2, -0.95, -0.07) * A(0, 0, math.rad(12)),
		CAP_BLACK
	)
end

-- 4.6 Door details ----------------------------------------------------------
for _, s in { -1, 1 } do
	part("DoorLineFront", V(0.04, 3.6, 0.06), C(s * 4.07, 6.8, -7.7), SEAM)
	part("DoorLineRear", V(0.04, 3.6, 0.06), C(s * 4.07, 6.8, -4.5), SEAM)
	part("DoorLineBottom", V(0.04, 0.06, 3.2), C(s * 4.07, 5.15, -6.1), SEAM)
	part("DoorHandle", V(0.08, 0.15, 0.5), C(s * 4.09, 8.2, -4.9), CHROME)
	part("SillTrim", V(0.06, 0.08, 3.1), C(s * 4.08, 8.62, -6.1), CHROME)
	cyl("GrabHandle", V(1.8, 0.12, 0.12), C(s * 4.15, 7.6, -4.25) * CYLINDER_Y, CHROME)
end

-- 4.7 Mirrors ---------------------------------------------------------------
for _, s in { -1, 1 } do
	cyl("MirrorArmUpper", V(1.3, 0.12, 0.12), C(s * 4.6, 10.6, -7.3), CHROME)
	cyl("MirrorArmLower", V(1.3, 0.12, 0.12), C(s * 4.6, 8.8, -7.3), CHROME)
	part("MirrorHead", V(0.35, 2.0, 0.8), C(s * 5.25, 9.7, -7.3), CHROME)
	part("MirrorGlass", V(0.28, 1.85, 0.05), C(s * 5.25, 9.7, -6.87), MIRROR)
	cyl("HoodMirrorPost", V(1.0, 0.1, 0.1), C(s * 4.6, 6.1, -14.2) * CYLINDER_Y, CHROME)
	cyl("HoodMirrorHead", V(0.15, 0.6, 0.6), C(s * 4.6, 6.75, -14.2) * CYLINDER_Z, CAP_BLACK)
end

-- 4.8 Roof: visor, cab lights, air horns ------------------------------------
part("Visor", V(8.4, 0.1, 1.3), C(0, 11.3, -8.05) * A(math.rad(-15), 0, 0), CHROME)
for _, x in { -1.8, -0.9, 0, 0.9, 1.8 } do
	part("CabLight", V(0.4, 0.2, 0.3), C(x, 11.9, -7.4), AMBER_NEON)
end
for _, s in { -1, 1 } do
	cyl("HornTube", V(2.2, 0.35, 0.35), C(s * 1.2, 12.0, -5.0) * CYLINDER_Z, CHROME)
	cyl("HornBell", V(0.3, 0.6, 0.6), C(s * 1.2, 12.0, -6.15) * CYLINDER_Z, CHROME)
end

-- 4.9 Sleeper ---------------------------------------------------------------
part("SleeperBox", V(8.1, 6.8, 6.5), C(0, 8.4, -0.35), PAINT)
part("InteriorBackPanel", V(7.5, 6.0, 0.05), C(0, 8.4, -3.63), CURTAIN)
part("SeamTop", V(8.1, 0.04, 0.08), C(0, 11.82, -3.6), SEAM)
for _, x in { -1, 0, 1 } do
	part("RearMarker", V(0.4, 0.2, 0.06), C(x, 11.5, 2.94), TAIL_NEON)
end
for _, s in { -1, 1 } do
	part("SeamSide", V(0.04, 6.7, 0.08), C(s * 4.07, 8.4, -3.6), SEAM)
	part("SleeperWindow", V(0.06, 0.8, 1.6), C(s * 4.07, 10.1, 0.6), GLASS)
	part("SleeperWindowFrame", V(0.04, 1.0, 1.8), C(s * 4.065, 10.1, 0.6), CHROME)
	part("BaggageLineFront", V(0.04, 2.4, 0.06), C(s * 4.07, 6.5, -2.6), SEAM)
	part("BaggageLineRear", V(0.04, 2.4, 0.06), C(s * 4.07, 6.5, 0.0), SEAM)
	part("BaggageLineTop", V(0.04, 0.06, 2.6), C(s * 4.07, 7.7, -1.3), SEAM)
	part("BaggageHandle", V(0.06, 0.12, 0.4), C(s * 4.09, 7.0, -0.4), CHROME)
	part("BeltlineTrim", V(0.04, 0.12, 10.9), C(s * 4.075, 8.65, -2.55), CHROME)
end

-- 4.10 Interior -------------------------------------------------------------
local WHEEL_TILT = A(math.rad(30), 0, 0) * CYLINDER_Y
part("Dash", V(7.6, 0.6, 0.7), C(0, 8.75, -7.35), DASH)
part("GaugeCluster", V(2.4, 0.55, 0.15), C(-1.9, 9.3, -7.4), DASH)
for _, x in { -2.5, -1.9, -1.3 } do
	cyl("Gauge", V(0.06, 0.3, 0.3), C(x, 9.3, -7.3) * CYLINDER_Z, GAUGE)
end
cyl("SteeringWheel", V(0.12, 1.8, 1.8), C(-1.9, 9.3, -6.5) * WHEEL_TILT, DASH)
cyl("SteeringHub", V(0.2, 0.5, 0.5), C(-1.9, 9.3, -6.5) * WHEEL_TILT, CHROME)
cyl("SteeringColumn", V(0.8, 0.2, 0.2), C(-1.9, 8.95, -6.7) * WHEEL_TILT, DASH)
for _, s in { -1, 1 } do
	part("SeatPedestal", V(1.2, 1.45, 1.2), C(s * 1.9, 6.125, -5.0), FRAME_BLACK)
	part("SeatCushion", V(1.9, 0.5, 1.9), C(s * 1.9, 7.1, -5.0), SEAT)
	part("SeatBack", V(1.9, 2.6, 0.45), C(s * 1.9, 8.65, -4.15), SEAT)
end
cyl("ShiftLever", V(1.0, 0.08, 0.08), C(-0.6, 7.9, -5.9) * CYLINDER_Y, CHROME)
part("ShiftKnob", V(0.25, 0.25, 0.25), C(-0.6, 8.45, -5.9), CAP_BLACK, BALL)

-- 4.11 Chassis --------------------------------------------------------------
part("CrossmemberFront", V(2.74, 0.9, 0.3), C(0, 3.85, -16.5), FRAME_BLACK)
part("CrossmemberMid", V(2.74, 0.9, 0.3), C(0, 3.85, 6.6), FRAME_BLACK)
part("CrossmemberRear", V(3.8, 1.1, 0.35), C(0, 3.85, 17.125), FRAME_BLACK)
part("FrontAxle", V(6.4, 0.45, 0.45), C(0, 2.1, -13.8), FRAME_BLACK)
part("OilPan", V(2.0, 1.0, 3.2), C(0, 3.9, -11.0), MECH_GRAY)
part("Transmission", V(1.4, 1.0, 2.4), C(0, 3.9, -6.4), MECH_GRAY)
cyl("Driveshaft", V(13.6, 0.35, 0.35), C(0, 3.0, 1.6) * CYLINDER_Z, MECH_GRAY)
cyl("InterAxleShaft", V(5.2, 0.35, 0.35), C(0, 2.1, 11.0) * CYLINDER_Z, MECH_GRAY)
part("DeckPlate", V(3.6, 0.12, 3.2), C(0, 4.46, 4.6), DIAMOND)
part("FifthBase", V(2.8, 0.4, 1.6), C(0, 4.8, 10.4), MECH_GRAY)
part("FifthPlate", V(3.6, 0.25, 2.2), C(0, 5.125, 9.9), FIFTH_BLACK)
cyl("PogoStick", V(3.2, 0.15, 0.15), C(0, 6.0, 3.6) * CYLINDER_Y, CHROME)
cyl("AirLineService", V(0.8, 0.14, 0.14), C(-0.2, 7.5, 3.25) * CYLINDER_Z, HOSE_RED)
cyl("AirLineEmergency", V(0.8, 0.14, 0.14), C(0, 7.5, 3.25) * CYLINDER_Z, HOSE_BLUE)
cyl("ElectricLine", V(0.8, 0.14, 0.14), C(0.2, 7.5, 3.25) * CYLINDER_Z, CAP_BLACK)
for _, z in { 8.4, 13.6 } do
	cyl("AxleTube", V(7.4, 0.55, 0.55), C(0, 2.1, z), FRAME_BLACK)
	part("Diff", V(1.4, 1.4, 1.4), C(0, 2.1, z), FRAME_BLACK, BALL)
end
for _, s in { -1, 1 } do
	part("FrameRail", V(0.36, 1.1, 34.0), C(s * 1.55, 3.85, 0.2), FRAME_BLACK)
	part("TailLight", V(0.7, 0.35, 0.06), C(s * 1.3, 3.85, 17.34), TAIL_NEON)
	part("FrontLeaf", V(0.35, 0.35, 4.4), C(s * 1.55, 2.75, -13.8), MECH_GRAY)
	for _, z in { 9.5, 14.7 } do
		cyl("AirBag", V(0.9, 0.9, 0.9), C(s * 1.55, 2.85, z) * CYLINDER_Y, TIRE)
	end
	part("FifthSlider", V(0.3, 0.2, 5.6), C(s * 1.55, 4.5, 10.4), MECH_GRAY)
	part("FifthHorn", V(1.3, 0.25, 1.4), C(s * 1.15, 5.125, 11.7), FIFTH_BLACK)
end

-- 4.12 Fuel tanks and battery boxes -----------------------------------------
for _, s in { -1, 1 } do
	cyl("FuelTank", V(5.6, 2.6, 2.6), C(s * 3.3, 3.5, -5.0) * CYLINDER_Z, ALUMINUM)
	for _, z in { -7.0, -3.0 } do
		cyl("TankStrap", V(0.25, 2.7, 2.7), C(s * 3.3, 3.5, z) * CYLINDER_Z, STAINLESS)
	end
	cyl("FuelCap", V(0.15, 0.5, 0.5), C(s * 3.3, 4.85, -6.0) * CYLINDER_Y, CHROME)
	part("BatteryBox", V(2.2, 1.8, 2.6), C(s * 3.25, 3.5, -0.6), CHROME)
	part("BatteryBoxTop", V(2.24, 0.06, 2.64), C(s * 3.25, 4.43, -0.6), DIAMOND)
end

-- 4.13 Stacks ---------------------------------------------------------------
for _, s in { -1, 1 } do
	local x = s * 3.6
	cyl("StackPipe", V(11.6, 0.75, 0.75), C(x, 10.2, 3.5) * CYLINDER_Y, CHROME)
	cyl("HeatShield", V(3.6, 0.92, 0.92), C(x, 9.4, 3.5) * CYLINDER_Y, SHIELD)
	cyl("StackBore", V(0.06, 0.6, 0.6), C(x, 16.0, 3.5) * CYLINDER_Y, CAP_BLACK)
	part("StackBracketLower", V(0.2, 0.3, 0.5), C(x, 6.8, 3.05), CHROME)
	part("StackBracketUpper", V(0.2, 0.3, 0.5), C(x, 11.6, 3.05), CHROME)
	cyl("StackElbow", V(1.6, 0.75, 0.75), C(s * 2.8, 4.4, 3.5), CHROME)
end

-- 4.14 Rear quarter fenders and mud flaps -----------------------------------
for _, s in { -1, 1 } do
	local x = s * 3.68
	part("FrontQtrTop", V(2.7, 0.1, 1.2), C(x, 4.5, 7.8), CHROME)
	part("FrontQtrSlope", V(2.7, 0.1, 1.6), C(x, 4.0, 6.75) * A(math.rad(-40), 0, 0), CHROME)
	part("RearQtrTop", V(2.7, 0.1, 1.2), C(x, 4.5, 14.2), CHROME)
	part("RearQtrSlope", V(2.7, 0.1, 1.6), C(x, 4.0, 15.25) * A(math.rad(40), 0, 0), CHROME)
	part("MudFlap", V(2.6, 2.8, 0.08), C(x, 2.2, 16.3), FLAP_BLACK)
	part("FlapHanger", V(3.2, 0.18, 0.18), C(s * 3.3, 3.75, 16.3), CHROME)
	part("FlapWeight", V(2.6, 0.15, 0.12), C(x, 0.9, 16.3), CHROME)
end

-- 4.15 Wheels ---------------------------------------------------------------
for _, s in { -1, 1 } do
	wheel(s * 4.14, -13.8, s, "front")
	for _, z in { 8.4, 13.6 } do
		wheel(s * 4.36, z, s, "outer")
		wheel(s * 3.0, z, s, "inner")
	end
end

return {
	name = "Peterbilt 389 Semi",
	-- Real: 113 km/h, 0-100 km/h in 20 s, brakes 0.45 g, coasts 0.1 g (VehicleDefaults maps them).
	speed = 49,
	acceleration = 4.6,
	braking = 9.9,
	coasting = 3.6,
	turnRate = 1.7,
	footprint = Vector2.new(10, 35.2),
	collision = {
		{ size = V(9.8, 6.8, 9.6), offset = C(0, 5.0, -12.8) }, -- hood, fenders, bumper
		{ size = V(9.2, 10.2, 10.9), offset = C(0, 6.7, -2.55) }, -- cab, sleeper, tanks
		{ size = V(10.0, 3.6, 14.7), offset = C(0, 3.4, 10.25) }, -- chassis, fifth wheel
	},
	seats = {
		C(-1.9, 6.9, -5.0), -- driver (LHD)
		C(1.9, 6.9, -5.0),
	},
	pieces = pieces,
}
