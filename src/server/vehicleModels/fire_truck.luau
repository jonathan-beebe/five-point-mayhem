-- Fire Engine: Pierce Enforcer custom-cab pumper in red over white with a gold cab stripe.
-- Scale: 4 studs = 1 m. Front axle z -14.4, rear axle z 5.2, front track 8.3, rear duals.

local rgb = Color3.fromRGB
local M = Enum.Material
local A = CFrame.Angles
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball
local CYLINDER_Z = A(0, math.rad(90), 0) -- cylinder axis along Z
local CYLINDER_Y = A(0, 0, math.rad(90)) -- cylinder axis along Y

-- Palette: { color, material, reflectance, transparency }.
local RED = { rgb(178, 18, 22), M.SmoothPlastic, 0.1 }
local WHITE = { rgb(238, 238, 234), M.SmoothPlastic, 0.08 }
local GOLD = { rgb(212, 170, 60), M.SmoothPlastic, 0.15 }
local CHROME = { rgb(214, 216, 220), M.Metal, 0.45 }
local STAINLESS = { rgb(188, 190, 194), M.Metal, 0.2 }
local DOOR = { rgb(176, 180, 186), M.Metal, 0.12 }
local DIAMOND = { rgb(170, 172, 176), M.DiamondPlate }
local ALUMINUM = { rgb(200, 203, 207), M.Metal, 0.1 }
local WHEEL = { rgb(205, 208, 212), M.Metal, 0.35 }
local TIRE = { rgb(28, 28, 30), M.SmoothPlastic }
local BLACK_RUBBER = { rgb(22, 22, 22), M.Fabric }
local FLAP = { rgb(18, 18, 18), M.Fabric }
local BLACK = { rgb(22, 22, 24), M.SmoothPlastic }
local SEAM_RED = { rgb(40, 12, 14), M.SmoothPlastic }
local SEAM_DOOR = { rgb(90, 92, 96), M.SmoothPlastic }
local MIRROR = { rgb(150, 160, 170), M.Glass, 0.5 }
local GLASS = { rgb(35, 48, 58), M.Glass, 0.1, 0.45 }
local SEAT = { rgb(48, 50, 54), M.Fabric }
local DASH = { rgb(38, 38, 42), M.SmoothPlastic }
local FLOOR = { rgb(45, 45, 48), M.Fabric }
local UNDER_DARK = { rgb(36, 36, 38), M.Metal }
local GAUGE = { rgb(240, 240, 232), M.SmoothPlastic }
local HEAD_NEON = { rgb(255, 244, 214), M.Neon }
local RED_NEON = { rgb(255, 30, 30), M.Neon }
local AMBER_NEON = { rgb(255, 150, 20), M.Neon }
local WHITE_NEON = { rgb(240, 242, 255), M.Neon }
local GREEN_NEON = { rgb(60, 255, 120), M.Neon }
local HOSE_YELLOW = { rgb(225, 190, 50), M.Fabric }
local HOSE_BLUE = { rgb(90, 140, 200), M.Fabric }
local HOSE_ORANGE = { rgb(215, 85, 35), M.Fabric }
local RED_CAP = { rgb(200, 30, 30), M.Metal }
local BLUE_CAP = { rgb(40, 80, 190), M.Metal }

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

local function mirror(fn)
	fn(-1)
	fn(1)
end

local V = Vector3.new
local C = CFrame.new

-- Cab shell ------------------------------------------------------------------------------------

local CHAMFER = 0.4

part("CabCore", V(6.6, 3.2, 11.6), C(0, 3.6, -12.8), UNDER_DARK)
part("CabFloor", V(9.4, 0.2, 11.6), C(0, 5.3, -12.8), FLOOR)
part("FasciaLower", V(9.2, 3.4, 0.4), C(0, 3.7, -18.6), WHITE)
part("FasciaUpper", V(9.2, 2.2, 0.4), C(0, 6.5, -18.6), RED)
part("FasciaStripe", V(9.24, 0.3, 0.46), C(0, 5.55, -18.6), GOLD)
part("Roof", V(10, 0.8, 12), C(0, 12, -12.8), RED)
part("CabRearWall", V(10, 9.6, 0.3), C(0, 6.8, -6.95), RED)

mirror(function(s)
	part("SideWhiteFront", V(0.3, 3.4, 1.4), C(s * 4.85, 3.7, -17.7), WHITE)
	part("SideWhiteArch", V(0.3, 0.4, 5.2), C(s * 4.85, 5.2, -14.4), WHITE)
	part("SideWhiteRear", V(0.3, 3.4, 5.0), C(s * 4.85, 3.7, -9.3), WHITE)
	part("SideRed", V(0.3, 2.2, 11.6), C(s * 4.85, 6.5, -12.6), RED)
	part("SideStripe", V(0.36, 0.3, 11.64), C(s * 4.85, 5.55, -12.6), GOLD)
	part("APillar", V(0.3, 4.0, 0.2), C(s * 4.85, 9.6, -18.3), RED)
	part("BPillar", V(0.3, 4.0, 0.4), C(s * 4.85, 9.6, -14.4), RED)
	part("CPillar", V(0.3, 4.0, 0.4), C(s * 4.85, 9.6, -10.4), RED)
	part("DPillar", V(0.3, 4.0, 0.8), C(s * 4.85, 9.6, -7.2), RED)
	part("WindshieldPost", V(0.3, 4.0, 0.4), C(s * 4.45, 9.6, -18.6), RED)
	-- Corner bevels: the Z rotation lays the wedge's right angle on the inner corner.
	local rot = A(0, 0, -s * math.pi / 2)
	local cx = s * (5 - CHAMFER / 2)
	local cz = -18.8 + CHAMFER / 2
	wedge("CornerWhite", V(3.4, CHAMFER, CHAMFER), C(cx, 3.7, cz) * rot, WHITE)
	wedge("CornerRed", V(6.2, CHAMFER, CHAMFER), C(cx, 8.5, cz) * rot, RED)
	part("WheelWellTop", V(1.4, 0.15, 5.0), C(s * 4.0, 5.12, -14.4), UNDER_DARK)
end)

-- Glass, windshield frame, wipers ----------------------------------------------------------------

local WS = C(0, 9.6, -18.55) * A(math.rad(6.4), 0, 0)
mirror(function(s)
	part("Windshield", V(4.3, 4.0, 0.1), WS * C(s * 2.3, 0, 0), GLASS)
	part("Wiper", V(3.2, 0.08, 0.06), WS * C(s * 2.3 - 0.4, -1.8, -0.1), BLACK)
	part("QuarterGlass", V(0.1, 4.0, 3.6), C(s * 4.85, 9.6, -16.4), GLASS)
	part("FrontDoorGlass", V(0.1, 4.0, 3.6), C(s * 4.85, 9.6, -12.4), GLASS)
	part("RearDoorGlass", V(0.1, 4.0, 2.6), C(s * 4.85, 9.6, -8.9), GLASS)
end)
part("WindshieldPost", V(0.3, 4.0, 0.14), WS * C(0, 0, -0.02), BLACK)
part("WindshieldHeader", V(9.0, 0.2, 0.14), WS * C(0, 1.95, -0.02), BLACK)

-- Cab exterior details ---------------------------------------------------------------------------

mirror(function(s)
	part("MirrorArmUpper", V(1.4, 0.12, 0.12), C(s * 5.7, 10.8, -18.0), CHROME)
	part("MirrorArmLower", V(1.4, 0.12, 0.12), C(s * 5.7, 8.3, -18.0), CHROME)
	part("MirrorHead", V(0.3, 2.2, 0.9), C(s * 6.3, 9.5, -18.0), BLACK)
	part("MirrorGlass", V(0.24, 2.0, 0.04), C(s * 6.3, 9.5, -17.53), MIRROR)
	part("DoorSeamFront", V(0.04, 2.6, 0.05), C(s * 5.01, 6.3, -14.4), SEAM_RED)
	part("DoorSeamMid", V(0.04, 5.6, 0.05), C(s * 5.01, 4.8, -10.4), SEAM_RED)
	part("DoorSeamRear", V(0.04, 5.6, 0.05), C(s * 5.01, 4.8, -7.0), SEAM_RED)
	part("DoorHandle", V(0.1, 0.2, 0.7), C(s * 5.05, 7.2, -11.0), CHROME)
	part("DoorHandle", V(0.1, 0.2, 0.7), C(s * 5.05, 7.2, -7.8), CHROME)
	cyl("GrabRail", V(2.4, 0.15, 0.15), C(s * 5.12, 8.6, -14.75) * CYLINDER_Y, CHROME)
	part("Step", V(0.8, 0.15, 1.4), C(s * 5.0, 2.3, -11.1), DIAMOND)
	part("Step", V(0.8, 0.15, 1.4), C(s * 5.0, 3.9, -11.1), DIAMOND)
	part("FenderTrim", V(0.35, 0.2, 2.6), C(s * 4.95, 5.05, -14.4), CHROME)
	part("FenderTrim", V(0.35, 0.2, 1.6), C(s * 4.95, 4.4, -16.3) * A(math.rad(-50), 0, 0), CHROME)
	part("FenderTrim", V(0.35, 0.2, 1.6), C(s * 4.95, 4.4, -12.5) * A(math.rad(50), 0, 0), CHROME)
	part("CabMarker", V(0.06, 0.25, 0.6), C(s * 5.02, 3.0, -17.7), AMBER_NEON)
end)

-- Front end --------------------------------------------------------------------------------------

part("BumperFace", V(10.6, 1.4, 0.3), C(0, 2.4, -19.85), CHROME)
part("BumperDeck", V(10.0, 0.15, 1.0), C(0, 3.0, -19.3), DIAMOND)
cyl("SirenDrum", V(1.1, 1.1, 1.1), C(1.6, 3.62, -19.3) * CYLINDER_Z, CHROME)
cyl("SirenGrille", V(0.06, 0.9, 0.9), C(1.6, 3.62, -19.87) * CYLINDER_Z, BLACK)
part("SirenSpeaker", V(1.4, 0.9, 0.06), C(-0.4, 2.4, -20.02), BLACK)
cyl("AirHorn", V(0.4, 0.55, 0.55), C(-2.2, 2.4, -20.1) * CYLINDER_Z, CHROME)
cyl("AirHorn", V(0.4, 0.55, 0.55), C(-3.2, 2.4, -20.1) * CYLINDER_Z, CHROME)
part("GrilleFrame", V(4.6, 3.4, 0.12), C(0, 5.6, -18.86), CHROME)
part("GrilleBacking", V(4.2, 3.0, 0.06), C(0, 5.6, -18.95), BLACK)
for i = 0, 3 do
	part("GrilleSlat", V(4.2, 0.16, 0.08), C(0, 4.35 + 0.75 * i, -19.0), CHROME)
end
mirror(function(s)
	part(
		"BumperEnd",
		V(0.3, 1.4, 0.9),
		C(s * 5.15, 2.4, -19.4) * A(0, -s * math.rad(35), 0),
		CHROME
	)
	part("TowHook", V(0.3, 0.5, 0.5), C(s * 3.6, 1.6, -19.9), RED)
	part("HeadlightBezel", V(1.8, 1.0, 0.1), C(s * 3.8, 3.9, -18.85), CHROME)
	part("Headlamp", V(0.7, 0.7, 0.06), C(s * 3.35, 3.9, -18.93), HEAD_NEON)
	part("Headlamp", V(0.7, 0.7, 0.06), C(s * 4.25, 3.9, -18.93), HEAD_NEON)
	part("TurnStrip", V(1.6, 0.25, 0.06), C(s * 3.8, 3.25, -18.84), AMBER_NEON)
	part("WarningHead", V(1.0, 0.45, 0.06), C(s * 3.8, 4.75, -18.84), RED_NEON)
end)

-- Lightbar and upper warning lights --------------------------------------------------------------

part("LightbarBase", V(9.2, 0.25, 1.4), C(0, 12.53, -17.2), BLACK)
for i, x in { -3.6, -1.8, 0, 1.8, 3.6 } do
	part(
		"LightbarLens",
		V(1.7, 0.45, 1.2),
		C(x, 12.88, -17.2),
		if i == 3 then WHITE_NEON else RED_NEON
	)
end
mirror(function(s)
	part("LightbarEnd", V(0.3, 0.5, 1.3), C(s * 4.65, 12.85, -17.2), CHROME)
	part("RoofWarning", V(0.9, 0.4, 0.06), C(s * 4.2, 12.0, -18.84), RED_NEON)
end)

-- Interior ---------------------------------------------------------------------------------------

for _, z in { -12.6, -8.6 } do
	mirror(function(s)
		part("SeatBase", V(1.5, 1.3, 1.4), C(s * 2.3, 6.05, z), DASH)
		part("SeatCushion", V(1.9, 0.5, 1.8), C(s * 2.3, 6.95, z), SEAT)
		part("SeatBack", V(1.9, 2.6, 0.4), C(s * 2.3, 8.4, z + 1.05) * A(math.rad(10), 0, 0), SEAT)
	end)
end
part("EngineDoghouse", V(2.2, 2.0, 4.4), C(0, 6.4, -14.0), DASH)
part("Dash", V(9.2, 1.4, 1.8), C(0, 7.9, -17.5), DASH)
part("InstrumentCluster", V(2.2, 0.8, 0.06), C(-2.3, 8.3, -16.58), BLACK)
local WHEEL_TILT = A(math.rad(-55), 0, 0) * CYLINDER_Z
local STEER = C(-2.3, 9.1, -14.1) * WHEEL_TILT
cyl("SteeringWheel", V(0.12, 1.5, 1.5), STEER, BLACK)
cyl("SteeringColumn", V(1.6, 0.25, 0.25), STEER * C(0.8, 0, 0), BLACK)

-- Pump module ------------------------------------------------------------------------------------

part("PumpCore", V(9.8, 8.0, 5.2), C(0, 6.0, -4.2), UNDER_DARK)
mirror(function(s)
	part("PumpPanel", V(0.1, 7.4, 5.0), C(s * 5.03, 5.7, -4.2), STAINLESS)
	part("PumpBand", V(0.12, 0.6, 5.2), C(s * 4.96, 9.7, -4.2), RED)
	part("PanelLightHood", V(0.4, 0.15, 5.0), C(s * 5.2, 9.35, -4.2), CHROME)
	part("RunningBoard", V(0.9, 0.2, 5.2), C(s * 5.3, 1.9, -4.2), DIAMOND)
	-- Steamer intake with cap and lug bar.
	cyl("SteamerBarrel", V(0.9, 1.5, 1.5), C(s * 5.5, 3.8, -4.2), CHROME)
	cyl("SteamerCap", V(0.3, 1.7, 1.7), C(s * 6.05, 3.8, -4.2), CHROME)
	part("SteamerLug", V(0.2, 0.3, 2.0), C(s * 6.25, 3.8, -4.2), CHROME)
	-- 2.5-inch discharges with caps.
	cyl("Discharge", V(0.5, 0.75, 0.75), C(s * 5.3, 3.8, -6.1), CHROME)
	cyl("DischargeCap", V(0.15, 0.85, 0.85), C(s * 5.6, 3.8, -6.1), RED_CAP)
	cyl("Discharge", V(0.5, 0.75, 0.75), C(s * 5.3, 3.8, -2.3), CHROME)
	cyl("DischargeCap", V(0.15, 0.85, 0.85), C(s * 5.6, 3.8, -2.3), BLUE_CAP)
end)
part("Crosslay", V(9.8, 1.1, 1.5), C(0, 10.55, -6.0), HOSE_ORANGE)
part("Crosslay", V(9.8, 1.1, 1.5), C(0, 10.55, -4.3), HOSE_BLUE)
part("Crosslay", V(9.8, 1.1, 1.5), C(0, 10.55, -2.6), HOSE_YELLOW)
part("CrosslayDivider", V(9.8, 1.2, 0.08), C(0, 10.6, -5.15), ALUMINUM)
part("CrosslayDivider", V(9.8, 1.2, 0.08), C(0, 10.6, -3.45), ALUMINUM)
cyl("CrosslayNozzle", V(0.6, 0.35, 0.35), C(-5.1, 10.3, -6.0) * CYLINDER_Y, BLACK)
cyl("CrosslayNozzle", V(0.6, 0.35, 0.35), C(-5.1, 10.3, -4.3) * CYLINDER_Y, BLACK)

-- Left operator panel.
for _, z in { -5.6, -4.4 } do
	cyl("GaugeBezel", V(0.1, 1.15, 1.15), C(-5.11, 8.3, z), CHROME)
	cyl("GaugeFace", V(0.1, 1.0, 1.0), C(-5.15, 8.3, z), GAUGE)
	part("GaugeNeedle", V(0.02, 0.4, 0.05), C(-5.21, 8.4, z) * A(math.rad(40), 0, 0), BLACK)
end
for _, z in { -6.1, -5.0, -3.9, -2.8 } do
	cyl("SmallGauge", V(0.1, 0.55, 0.55), C(-5.13, 7.1, z), GAUGE)
end
part("GovernorBox", V(0.1, 0.8, 1.0), C(-5.12, 8.3, -2.7), BLACK)
part("GovernorDisplay", V(0.04, 0.3, 0.6), C(-5.19, 8.4, -2.7), GREEN_NEON)
for _, z in { -6.0, -5.0, -3.6, -2.6 } do
	cyl("ValveStem", V(0.6, 0.14, 0.14), C(-5.35, 6.0, z), CHROME)
	part("THandle", V(0.12, 0.14, 0.6), C(-5.68, 6.0, z), CHROME)
end

-- Right panel gauges.
cyl("SmallGauge", V(0.1, 0.55, 0.55), C(5.13, 8.3, -5.0), GAUGE)
cyl("SmallGauge", V(0.1, 0.55, 0.55), C(5.13, 8.3, -3.4), GAUGE)

-- Rear body --------------------------------------------------------------------------------------

part("BodyCore", V(4.8, 7.4, 20.6), C(0, 5.5, 8.7), UNDER_DARK)
part("BodyUpper", V(10.0, 1.4, 20.6), C(0, 9.9, 8.7), RED)
part("RearFacePanel", V(4.8, 7.4, 0.05), C(0, 5.5, 19.02), RED)
part("HoseBedWallFront", V(9.4, 0.8, 0.3), C(0, 11.0, -1.45), RED)
mirror(function(s)
	part("SideBlockForward", V(2.6, 7.4, 3.8), C(s * 3.7, 5.5, 0.3), RED)
	part("SideBlockOverWheel", V(2.6, 4.2, 6.0), C(s * 3.7, 7.1, 5.2), RED)
	part("SideBlockAft", V(2.6, 7.4, 10.8), C(s * 3.7, 5.5, 13.6), RED)
	part("WheelWellLiner", V(2.5, 0.1, 5.9), C(s * 3.7, 4.93, 5.2), BLACK)
	part("HoseBedWall", V(0.3, 0.8, 20.6), C(s * 4.85, 11.0, 8.7), RED)
	part("RubRail", V(0.15, 0.3, 3.8), C(s * 5.06, 1.95, 0.3), CHROME)
	part("RubRail", V(0.15, 0.3, 10.8), C(s * 5.06, 1.95, 13.6), CHROME)
end)

-- Roll-up compartment doors: panel, two slat grooves, lift bar.
local function sideDoor(s, z0, z1, y0, y1)
	local dz, h = z1 - z0, y1 - y0
	local zc, yc = (z0 + z1) / 2, (y0 + y1) / 2
	part("RollUpDoor", V(0.06, h, dz), C(s * 5.04, yc, zc), DOOR)
	part("DoorSlat", V(0.03, 0.05, dz - 0.1), C(s * 5.08, y0 + h / 3, zc), SEAM_DOOR)
	part("DoorSlat", V(0.03, 0.05, dz - 0.1), C(s * 5.08, y0 + 2 * h / 3, zc), SEAM_DOOR)
	part("LiftBar", V(0.1, 0.12, dz - 0.4), C(s * 5.12, y0 + 0.4, zc), CHROME)
end
mirror(function(s)
	sideDoor(s, -1.35, 1.95, 2.1, 8.9)
	sideDoor(s, 2.45, 7.95, 5.3, 8.9)
	sideDoor(s, 8.45, 13.55, 2.1, 8.9)
	sideDoor(s, 13.85, 18.75, 2.1, 8.9)
end)
part("RearDoor", V(4.2, 5.9, 0.06), C(0, 5.95, 19.08), DOOR)
part("RearDoorSlat", V(4.1, 0.05, 0.03), C(0, 3.0 + 5.9 / 3, 19.12), SEAM_DOOR)
part("RearDoorSlat", V(4.1, 0.05, 0.03), C(0, 3.0 + 2 * 5.9 / 3, 19.12), SEAM_DOOR)
part("RearLiftBar", V(3.8, 0.12, 0.1), C(0, 3.4, 19.16), CHROME)

-- Rear end and body lights -----------------------------------------------------------------------

mirror(function(s)
	local x = s * 3.7
	part("LightColumn", V(1.6, 6.6, 0.06), C(x, 5.9, 19.03), BLACK)
	part("WarningLampTop", V(1.1, 0.8, 0.06), C(x, 8.6, 19.08), RED_NEON)
	part("WarningLamp", V(1.1, 0.8, 0.06), C(x, 7.6, 19.08), RED_NEON)
	part("TurnLamp", V(1.1, 0.8, 0.06), C(x, 5.0, 19.08), AMBER_NEON)
	part("StopLamp", V(1.1, 0.8, 0.06), C(x, 4.0, 19.08), RED_NEON)
	part("ReverseLamp", V(1.1, 0.6, 0.06), C(x, 3.1, 19.08), WHITE_NEON)
	cyl("RearGrabRail", V(5.0, 0.18, 0.18), C(s * 2.3, 5.7, 19.35) * CYLINDER_Y, CHROME)
	part("BodyWarning", V(0.06, 0.6, 1.0), C(s * 5.03, 10.0, -1.0), RED_NEON)
	part("BodyWarning", V(0.06, 0.6, 1.0), C(s * 5.03, 10.0, 18.2), RED_NEON)
end)
part("Tailboard", V(10.0, 0.3, 1.0), C(0, 2.0, 19.5), DIAMOND)
part("Plate", V(1.2, 0.6, 0.04), C(0, 2.6, 19.11), WHITE)

-- Hose bed and side equipment --------------------------------------------------------------------

for _, lane in { { -3.15, HOSE_YELLOW }, { 0, HOSE_BLUE }, { 3.15, HOSE_ORANGE } } do
	part("HoseLoad", V(3.0, 0.6, 20.2), C(lane[1], 10.9, 8.8), lane[2])
end
part("LaneDivider", V(0.08, 0.7, 20.2), C(-1.575, 10.95, 8.8), ALUMINUM)
part("LaneDivider", V(0.08, 0.7, 20.2), C(1.575, 10.95, 8.8), ALUMINUM)

-- Ladders on the right.
for _, z in { 2.0, 9.0, 16.0 } do
	part("LadderBracket", V(0.2, 2.2, 0.3), C(5.12, 10.3, z), BLACK)
end
for _, y in { 9.4, 11.2 } do
	part("ExtensionRail", V(0.12, 0.16, 16.0), C(5.25, y, 8.5), ALUMINUM)
end
for _, y in { 9.5, 11.1 } do
	part("RoofLadderRail", V(0.14, 0.18, 17.0), C(5.45, y, 9.0), ALUMINUM)
	part("RoofHook", V(0.14, 0.4, 0.3), C(5.45, y, 0.4), BLACK)
end
for i = 0, 11 do
	part("LadderRung", V(0.1, 1.5, 0.12), C(5.45, 10.3, 1.3 + 1.4 * i), ALUMINUM)
end

-- Hard suction on the left.
for _, y in { 9.75, 10.6 } do
	cyl("HardSuction", V(12.0, 0.75, 0.75), C(-5.42, y, 6.5) * CYLINDER_Z, BLACK_RUBBER)
	cyl("SuctionCoupling", V(0.5, 0.85, 0.85), C(-5.42, y, 0.5) * CYLINDER_Z, CHROME)
	cyl("SuctionCoupling", V(0.5, 0.85, 0.85), C(-5.42, y, 12.5) * CYLINDER_Z, CHROME)
end

-- Wheels -----------------------------------------------------------------------------------------

mirror(function(s)
	local front = function(x, size, style, name)
		cyl(name, size, C(s * x, 2.15, -14.4), style)
	end
	front(4.15, V(1.3, 4.3, 4.3), TIRE, "FrontTire")
	front(4.15, V(1.36, 2.3, 2.3), WHEEL, "FrontRim")
	front(4.86, V(0.06, 1.9, 1.9), BLACK, "HandHoleRing")
	front(4.89, V(0.06, 1.5, 1.5), WHEEL, "CenterDisc")
	front(5.0, V(0.3, 0.9, 0.9), CHROME, "HubCap")

	local rear = function(x, size, style, name)
		cyl(name, size, C(s * x, 2.15, 5.2), style)
	end
	rear(3.05, V(1.2, 4.3, 4.3), TIRE, "InnerTire")
	rear(4.35, V(1.2, 4.3, 4.3), TIRE, "OuterTire")
	rear(4.35, V(1.26, 2.3, 2.3), WHEEL, "OuterRim")
	rear(5.0, V(0.06, 1.9, 1.9), BLACK, "HandHoleRing")
	rear(5.03, V(0.06, 1.4, 1.4), WHEEL, "CenterDisc")
	rear(5.12, V(0.3, 0.8, 0.8), CHROME, "Hub")
end)

-- Mud flaps and underside ------------------------------------------------------------------------

mirror(function(s)
	part("RearMudFlap", V(2.6, 2.4, 0.08), C(s * 3.7, 1.8, 8.1), FLAP)
	part("FrameRail", V(0.5, 0.9, 38.0), C(s * 1.6, 2.3, 0), UNDER_DARK)
end)
part("FrontAxle", V(7.0, 0.4, 0.5), C(0, 2.0, -14.4), UNDER_DARK)
part("Differential", V(1.3, 1.3, 1.3), C(0, 2.15, 5.2), UNDER_DARK, BALL)
cyl("DriveShaft", V(10.0, 0.35, 0.35), C(0, 2.4, -0.4) * CYLINDER_Z, UNDER_DARK)
cyl("ExhaustTip", V(0.8, 0.4, 0.4), C(4.6, 1.7, 1.8), CHROME)

return {
	name = "Fire Engine",
	speed = 75,
	turnRate = 1.7,
	footprint = Vector2.new(10, 40),
	collision = {
		-- Cab lower with the bumper; top 6.1 stays below the seat blocks (6.2).
		{ size = Vector3.new(10.0, 4.5, 13.2), offset = CFrame.new(0, 3.85, -13.4) },
		-- Pump module, rear body and tailboard, y 1.6..11.4.
		{ size = Vector3.new(10.0, 9.8, 26.8), offset = CFrame.new(0, 6.5, 6.6) },
		-- Cab roof, above the head tops (11.2).
		{ size = Vector3.new(10.0, 0.8, 12.0), offset = CFrame.new(0, 12.0, -12.8) },
	},
	seats = {
		CFrame.new(-2.3, 6.7, -12.6), -- driver (LHD)
		CFrame.new(2.3, 6.7, -12.6), -- officer
		CFrame.new(-2.3, 6.7, -8.6), -- crew left
		CFrame.new(2.3, 6.7, -8.6), -- crew right
	},
	pieces = pieces,
}
