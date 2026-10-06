-- VW Microbus: 1965 Volkswagen Type 2 Samba 21-window deluxe bus in Sea Blue and Cumulus White.
-- Scale: 4 studs = 1 m. Front axle z -5.16, rear axle z 4.44, track 5.5, 7.00-14 whitewall tires.

local rgb = Color3.fromRGB
local M = Enum.Material
local A = CFrame.Angles
local V3 = Vector3.new
local CF = CFrame.new
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball
local WEDGE = "WedgePart"
local CYLINDER_Z = A(0, math.rad(90), 0) -- cylinder axis along Z
local CYLINDER_Y = A(0, 0, math.rad(90)) -- cylinder axis along Y

-- WedgePart default: full bottom and full back (+Z) faces, right angle at local (ymin, zmax).
local FLIP_Z = A(0, 0, math.pi) -- right angle at (ymax, zmax)
local FLIP_X = A(math.pi, 0, 0) -- right angle at (ymax, zmin)
local SIDE_L = A(0, math.pi / 2, 0) -- length along Z, solid side inboard (+X), slope falls to -X
local SIDE_R = A(0, -math.pi / 2, 0) -- length along Z, solid side inboard (-X), slope falls to +X
local REV = A(0, math.pi, 0) -- slope rises toward -Z

-- Vertical corner chamfers: local X is height, local Y is world-X width, local Z is world-Z depth.
local function cornerFR(pos)
	return CFrame.fromMatrix(pos, V3(0, -1, 0), V3(1, 0, 0))
end
local function cornerFL(pos)
	return CFrame.fromMatrix(pos, V3(0, 1, 0), V3(-1, 0, 0))
end
local function cornerRR(pos)
	return CFrame.fromMatrix(pos, V3(0, 1, 0), V3(1, 0, 0))
end
local function cornerRL(pos)
	return CFrame.fromMatrix(pos, V3(0, -1, 0), V3(-1, 0, 0))
end
-- Flat triangles on the nose (XY plane): right angle at the top inner corner.
local function vRight(pos)
	return CFrame.fromMatrix(pos, V3(0, 0, -1), V3(0, -1, 0))
end
local function vLeft(pos)
	return CFrame.fromMatrix(pos, V3(0, 0, 1), V3(0, -1, 0))
end
-- A block whose Z axis runs from a to b.
local function along(a, b)
	local back = (b - a).Unit
	local right = V3(0, 1, 0):Cross(back).Unit
	return CFrame.fromMatrix((a + b) / 2, right, back:Cross(right))
end

local SEA_BLUE = { color = rgb(82, 140, 162), reflectance = 0.08 }
local CREAM = { color = rgb(234, 228, 208), reflectance = 0.08 }
local BUMPER = { color = rgb(234, 228, 208), reflectance = 0.1 }
local CHROME = { color = rgb(210, 212, 216), material = M.Metal, reflectance = 0.35 }
local GLASS = { color = rgb(160, 190, 200), material = M.Glass, transparency = 0.45 }
local SKYLIGHT = { color = rgb(60, 80, 90), material = M.Glass, transparency = 0.15 }
local HEADLIGHT = { color = rgb(255, 240, 205), material = M.Neon }
local AMBER = { color = rgb(255, 150, 30), material = M.Neon }
local RED = { color = rgb(200, 20, 20), material = M.Neon }
local RUBBER = { color = rgb(26, 26, 26) }
local WHITEWALL = { color = rgb(238, 236, 228) }
local WHEEL_PAINT = { color = rgb(228, 226, 214), reflectance = 0.1 }
local WHEELHOUSE = { color = rgb(22, 22, 22) }
local UNDERBODY = { color = rgb(45, 45, 47), material = M.Metal }
local EXHAUST = { color = rgb(70, 70, 72), material = M.Metal }
local DARK_GAP = { color = rgb(28, 30, 32) }
local VINYL = { color = rgb(168, 160, 142) }
local FLOOR_MAT = { color = rgb(40, 40, 40), material = M.Fabric }
local STEERING = { color = rgb(226, 220, 198), reflectance = 0.05 }
local CANVAS = { color = rgb(118, 116, 110), material = M.Fabric }
local CANVAS_RIB = { color = rgb(95, 93, 88), material = M.Fabric }
local PLATE = { color = rgb(226, 224, 212) }

local FRONT_AXLE = -5.16
local REAR_AXLE = 4.44
local AXLES = { FRONT_AXLE, REAR_AXLE }
local WHEEL_X = 2.75
local WHEEL_Y = 1.36
local SKIN_X = 3.4 -- center of the 0.2-thick side skins (outer face 3.5)

local pieces = {}
local function add(piece)
	table.insert(pieces, piece)
end

local function make(name, class, shape, size, offset, style)
	add({
		name = name,
		class = class,
		shape = shape,
		size = size,
		offset = offset,
		color = style.color,
		material = style.material or M.SmoothPlastic,
		reflectance = style.reflectance,
		transparency = style.transparency,
	})
end
local function block(name, size, offset, style)
	make(name, "Part", nil, size, offset, style)
end
local function wedge(name, size, offset, style)
	make(name, WEDGE, nil, size, offset, style)
end
local function cyl(name, size, offset, style)
	make(name, "Part", CYL, size, offset, style)
end
local function ball(name, d, offset, style)
	make(name, "Part", BALL, V3(d, d, d), offset, style)
end

-- Calls fn(s) for the left (s = -1) and right (s = 1) side.
local function mirror(fn)
	fn(-1)
	fn(1)
end

-- Lower body ---------------------------------------------------------------

block("FrontLowerPanel", V3(5.4, 3.55, 0.2), CF(0, 3.075, -8.1), SEA_BLUE)
wedge("FrontCornerLowerR", V3(3.55, 0.8, 0.6), cornerFR(V3(3.1, 3.075, -7.9)), SEA_BLUE)
wedge("FrontCornerLowerL", V3(3.55, 0.8, 0.6), cornerFL(V3(-3.1, 3.075, -7.9)), SEA_BLUE)
wedge("NoseVR", V3(0.04, 1.3, 2.7), vRight(V3(1.35, 4.2, -8.23)), CREAM)
wedge("NoseVL", V3(0.04, 1.3, 2.7), vLeft(V3(-1.35, 4.2, -8.23)), CREAM)
block("RearLowerPanel", V3(5.4, 3.55, 0.2), CF(0, 3.075, 8.1), SEA_BLUE)
wedge("RearCornerLowerR", V3(3.55, 0.8, 0.6), cornerRR(V3(3.1, 3.075, 7.9)), SEA_BLUE)
wedge("RearCornerLowerL", V3(3.55, 0.8, 0.6), cornerRL(V3(-3.1, 3.075, 7.9)), SEA_BLUE)

mirror(function(s)
	block(
		"VTrim",
		V3(3.0, 0.08, 0.04),
		CF(s * 1.35, 4.2, -8.27) * A(0, 0, s * math.rad(25.7)),
		CHROME
	)

	local x = s * SKIN_X
	block("SideSkinUpper", V3(0.2, 1.85, 15.2), CF(x, 3.925, 0), SEA_BLUE)
	block("SideSkinFront", V3(0.2, 1.7, 0.9), CF(x, 2.15, -7.15), SEA_BLUE)
	block("SideSkinMid", V3(0.2, 1.7, 6.52), CF(x, 2.15, -0.36), SEA_BLUE)
	block("SideSkinRear", V3(0.2, 1.7, 1.62), CF(x, 2.15, 6.79), SEA_BLUE)
	wedge("ArchFillet", V3(0.2, 0.6, 0.6), CF(x, 2.7, -6.4) * FLIP_X, SEA_BLUE)
	wedge("ArchFillet", V3(0.2, 0.6, 0.6), CF(x, 2.7, -3.92) * FLIP_Z, SEA_BLUE)
	wedge("ArchFillet", V3(0.2, 0.6, 0.6), CF(x, 2.7, 3.2) * FLIP_X, SEA_BLUE)
	wedge("ArchFillet", V3(0.2, 0.6, 0.6), CF(x, 2.7, 5.68) * FLIP_Z, SEA_BLUE)
	for _, z in AXLES do
		block("WheelhouseRoof", V3(1.0, 0.1, 3.1), CF(s * 2.8, 3.05, z), WHEELHOUSE)
		block("WheelhouseWall", V3(0.1, 1.75, 3.1), CF(s * 2.25, 2.17, z), WHEELHOUSE)
	end
	block("BeltTrim", V3(0.04, 0.08, 15.2), CF(s * 3.52, 4.85, 0), CHROME)
	block("RockerTrim", V3(0.04, 0.06, 6.4), CF(s * 3.52, 1.8, -0.36), CHROME)

	-- Floor pan side strips, kept out of the wheel arches.
	block("FloorPanSide", V3(1.1, 0.12, 6.52), CF(s * 2.75, 1.24, -0.36), UNDERBODY)
	block("FloorPanSide", V3(1.1, 0.12, 0.9), CF(s * 2.75, 1.24, -7.15), UNDERBODY)
	block("FloorPanSide", V3(1.1, 0.12, 1.62), CF(s * 2.75, 1.24, 6.79), UNDERBODY)
end)
block("FloorPan", V3(4.4, 0.12, 15.8), CF(0, 1.24, 0), UNDERBODY)

-- Upper body ---------------------------------------------------------------

block("Cowl", V3(5.4, 0.15, 0.2), CF(0, 4.925, -8.1), CREAM)
block("WindshieldPost", V3(0.2, 1.75, 0.2), CF(0, 5.875, -8.1), CREAM)
block("Header", V3(5.4, 0.2, 0.2), CF(0, 6.85, -8.1), CREAM)
wedge("FrontCornerUpperR", V3(2.1, 0.8, 0.6), cornerFR(V3(3.1, 5.9, -7.9)), CREAM)
wedge("FrontCornerUpperL", V3(2.1, 0.8, 0.6), cornerFL(V3(-3.1, 5.9, -7.9)), CREAM)
block("RearWindowBottomRail", V3(4.0, 0.45, 0.2), CF(0, 5.075, 8.1), CREAM)
block("RearWindowTopRail", V3(4.0, 0.35, 0.2), CF(0, 6.775, 8.1), CREAM)
wedge("RearCornerUpperR", V3(2.1, 0.8, 0.6), cornerRR(V3(3.1, 5.9, 7.9)), CREAM)
wedge("RearCornerUpperL", V3(2.1, 0.8, 0.6), cornerRL(V3(-3.1, 5.9, 7.9)), CREAM)

local PILLARS = {
	{ -7.4, 0.4 },
	{ -4.15, 0.5 },
	{ -1.125, 0.25 },
	{ 1.775, 0.25 },
	{ 4.775, 0.45 },
	{ 6.3, 2.6 },
}

mirror(function(s)
	local x = s * SKIN_X
	block("APost", V3(0.2, 1.75, 0.2), CF(s * 2.6, 5.875, -8.1), CREAM)
	block("BeltRail", V3(0.2, 0.35, 15.2), CF(x, 5.025, 0), CREAM)
	block("RoofRail", V3(0.2, 0.3, 15.2), CF(x, 6.8, 0), CREAM)
	for _, p in PILLARS do
		block("Pillar", V3(0.2, 1.45, p[2]), CF(x, 5.925, p[1]), CREAM)
	end
	block("RearWindowPost", V3(0.7, 2.1, 0.2), CF(s * 2.35, 5.9, 8.1), CREAM)
	block("RainGutter", V3(0.1, 0.08, 15.6), CF(s * 3.55, 6.97, -0.2), CHROME)
end)

-- Roof
block("RoofSlab", V3(5.6, 0.25, 14.4), CF(0, 7.625, 0), CREAM)
wedge("RoofEdgeR", V3(15.6, 0.8, 0.7), CF(3.15, 7.35, -0.2) * SIDE_R, CREAM)
wedge("RoofEdgeL", V3(15.6, 0.8, 0.7), CF(-3.15, 7.35, -0.2) * SIDE_L, CREAM)
wedge("RoofFront", V3(5.6, 0.6, 1.15), CF(0, 7.45, -7.775), CREAM)
block("Peak", V3(5.8, 0.25, 1.15), CF(0, 7.025, -7.775), CREAM)
block("PeakIntake", V3(5.0, 0.08, 0.04), CF(0, 7.02, -8.37), DARK_GAP)
wedge("RoofRear", V3(5.6, 0.8, 1.0), CF(0, 7.35, 7.7) * REV, CREAM)

-- Sunroof
block("SunroofCanvas", V3(4.4, 0.06, 7.2), CF(0, 7.785, -1.6), CANVAS)
for _, z in { -3.8, -2.2, -0.6, 1.0 } do
	block("SunroofRib", V3(4.4, 0.05, 0.1), CF(0, 7.83, z), CANVAS_RIB)
end
block("SunroofBar", V3(4.6, 0.08, 0.15), CF(0, 7.8, -5.25), CHROME)

-- Glass --------------------------------------------------------------------

mirror(function(s)
	local x = s * SKIN_X
	block(
		"Windshield",
		V3(2.4, 1.75, 0.06),
		CF(s * 1.3, 5.875, -8.08) * A(0, -s * math.rad(3), 0),
		GLASS
	)
	block("VentWing", V3(0.06, 1.45, 0.75), CF(x, 5.925, -6.825), GLASS)
	block("VentDivider", V3(0.08, 1.45, 0.08), CF(s * 3.45, 5.925, -6.41), CHROME)
	block("DoorGlass", V3(0.06, 1.45, 1.97), CF(x, 5.925, -5.385), GLASS)
	for _, z in { -2.575, 0.325, 3.225 } do
		block("SideWindow", V3(0.06, 1.45, 2.65), CF(x, 5.925, z), GLASS)
	end
	for _, z in { -2.6, -0.45, 1.7, 3.85 } do
		block(
			"Skylight",
			V3(0.06, 0.75, 1.75),
			CF(s * 3.18, 7.38, z) * A(0, 0, s * math.rad(41.2)),
			SKYLIGHT
		)
	end
end)
block("RearWindow", V3(4.0, 1.3, 0.06), CF(0, 5.95, 8.1), GLASS)

-- Lights -------------------------------------------------------------------

mirror(function(s)
	local x = s * 2.15
	cyl("HeadlightPod", V3(0.08, 1.15, 1.15), CF(x, 3.3, -8.25) * CYLINDER_Z, SEA_BLUE)
	cyl("HeadlightBezel", V3(0.08, 0.98, 0.98), CF(x, 3.3, -8.3) * CYLINDER_Z, CHROME)
	cyl("Headlight", V3(0.04, 0.78, 0.78), CF(x, 3.3, -8.35) * CYLINDER_Z, HEADLIGHT)
	cyl("TurnSignalBase", V3(0.15, 0.3, 0.3), CF(x, 4.2, -8.28) * CYLINDER_Z, CHROME)
	ball("TurnSignal", 0.26, CF(x, 4.2, -8.36), AMBER)

	local tx = s * 2.35
	block("TaillightHousing", V3(0.5, 1.0, 0.1), CF(tx, 3.8, 8.25), CHROME)
	block("TaillightRed", V3(0.38, 0.5, 0.06), CF(tx, 3.6, 8.31), RED)
	block("TaillightAmber", V3(0.38, 0.35, 0.06), CF(tx, 4.1, 8.31), AMBER)
end)
block("PlateLight", V3(0.5, 0.15, 0.15), CF(0, 3.3, 8.28), CHROME)

-- Wheels -------------------------------------------------------------------

for _, z in AXLES do
	mirror(function(s)
		cyl("Tire", V3(0.75, 2.72, 2.72), CF(s * WHEEL_X, WHEEL_Y, z), RUBBER)
		cyl("Whitewall", V3(0.04, 2.1, 2.1), CF(s * 3.145, WHEEL_Y, z), WHITEWALL)
		cyl("Rim", V3(0.06, 1.62, 1.62), CF(s * 3.18, WHEEL_Y, z), WHEEL_PAINT)
		cyl("Hubcap", V3(0.08, 1.05, 1.05), CF(s * 3.25, WHEEL_Y, z), CHROME)
		ball("HubcapDome", 0.5, CF(s * 3.22, WHEEL_Y, z), CHROME)
		cyl("BrakeDrum", V3(0.2, 1.3, 1.3), CF(s * 2.5, WHEEL_Y, z), UNDERBODY)
		for k = 0, 3 do
			local a = math.pi / 4 + k * math.pi / 2
			block(
				"RimSlot",
				V3(0.03, 0.12, 0.25),
				CF(s * 3.225, WHEEL_Y, z) * A(a, 0, 0) * CF(0, 0.68, 0),
				DARK_GAP
			)
		end
	end)
end

-- Bumpers ------------------------------------------------------------------

block("FrontBumper", V3(6.4, 0.42, 0.18), CF(0, 1.8, -8.55), BUMPER)
block("RearBumper", V3(6.4, 0.42, 0.18), CF(0, 1.85, 8.55), BUMPER)
mirror(function(s)
	block(
		"FrontBumperEnd",
		V3(0.7, 0.42, 0.18),
		CF(s * 3.49, 1.8, -8.35) * A(0, -s * math.rad(35), 0),
		BUMPER
	)
	block("FrontBumperBracket", V3(0.25, 0.25, 0.26), CF(s * 1.9, 1.7, -8.33), UNDERBODY)
	block(
		"RearBumperEnd",
		V3(0.7, 0.42, 0.18),
		CF(s * 3.49, 1.85, 8.35) * A(0, s * math.rad(35), 0),
		BUMPER
	)
	block("RearBumperBracket", V3(0.25, 0.25, 0.26), CF(s * 1.9, 1.75, 8.33), UNDERBODY)
end)

-- Interior -----------------------------------------------------------------

block("CabFloor", V3(4.4, 0.15, 4.4), CF(0, 2.625, -5.8), FLOOR_MAT)
block("PassengerFloor", V3(6.6, 0.15, 6.5), CF(0, 2.025, -0.35), FLOOR_MAT)
block("RearTubFloor", V3(4.4, 0.15, 1.0), CF(0, 2.025, 3.4), FLOOR_MAT)
block("LuggageDeck", V3(6.6, 0.15, 4.1), CF(0, 4.55, 5.95), FLOOR_MAT)
block("DriverCushion", V3(1.65, 0.4, 1.5), CF(-1.375, 2.9, -4.45), VINYL)
block("PassengerCushion", V3(1.65, 0.4, 1.5), CF(1.375, 2.9, -4.45), VINYL)
mirror(function(s)
	block("CabBackrest", V3(1.65, 2.3, 0.3), CF(s * 1.375, 4.25, -3.55), VINYL)
	block("CabStep", V3(1.1, 0.15, 0.9), CF(s * 2.75, 2.625, -7.15), FLOOR_MAT)
end)
for _, z in { -0.9, 2.65 } do
	block("BenchCushion", V3(5.8, 0.4, 1.5), CF(0, 2.9, z), VINYL)
	block("BenchBase", V3(5.4, 0.65, 1.3), CF(0, 2.375, z), DARK_GAP)
end
block("MidBackrest", V3(5.8, 2.3, 0.3), CF(0, 4.25, 0.0), VINYL)
block("RearBackrest", V3(5.8, 2.3, 0.3), CF(0, 4.25, 3.55), VINYL)
block("Dashboard", V3(5.4, 0.55, 0.5), CF(0, 4.9, -7.8), CREAM)
cyl("SpeedoRim", V3(0.04, 0.7, 0.7), CF(-1.55, 5.0, -7.54) * CYLINDER_Z, CHROME)
cyl("Speedometer", V3(0.06, 0.6, 0.6), CF(-1.55, 5.0, -7.53) * CYLINDER_Z, DARK_GAP)
for _, x in { -1.9, -1.2 } do
	block("Pedal", V3(0.25, 0.35, 0.06), CF(x, 3.05, -7.3), DARK_GAP)
end
cyl(
	"GearLever",
	V3(1.2, 0.08, 0.08),
	CF(0, 3.3, -5.7) * A(math.rad(15), 0, 0) * CYLINDER_Y,
	DARK_GAP
)
ball("GearKnob", 0.22, CF(0, 3.9, -5.55), DARK_GAP)

-- Steering wheel: bus-style column raked 39 degrees back from vertical.
local W = CF(-1.55, 5.0, -5.8) * A(math.rad(39), 0, 0)
for k = 0, 7 do
	block(
		"SteeringRim",
		V3(0.1, 0.1, 0.68),
		W * A(0, k * math.pi / 4, 0) * CF(0.785, 0, 0),
		STEERING
	)
end
cyl("SteeringHub", V3(0.12, 0.35, 0.35), W * CYLINDER_Y, STEERING)
mirror(function(s)
	block("SteeringSpoke", V3(0.7, 0.06, 0.1), W * CF(s * 0.4, 0, 0), STEERING)
end)
cyl(
	"SteeringColumn",
	V3(2.4, 0.15, 0.15),
	CF(-1.55, 4.06, -6.55) * A(math.rad(39), 0, 0) * CYLINDER_Y,
	DARK_GAP
)

-- Details ------------------------------------------------------------------

cyl("BadgeRing", V3(0.06, 1.05, 1.05), CF(0, 3.55, -8.29) * CYLINDER_Z, CHROME)
cyl("Badge", V3(0.03, 0.8, 0.8), CF(0, 3.55, -8.335) * CYLINDER_Z, SEA_BLUE)

mirror(function(s)
	block(
		"Wiper",
		V3(0.05, 1.3, 0.04),
		CF(s * 1.3, 6.05, -8.15) * A(0, 0, s * math.rad(15)),
		DARK_GAP
	)
	block(
		"MirrorArm",
		V3(0.07, 0.07, 0.9),
		along(V3(s * 3.5, 5.1, -7.1), V3(s * 4.15, 5.7, -7.25)),
		CHROME
	)
	cyl("MirrorHead", V3(0.08, 0.5, 0.5), CF(s * 4.2, 5.75, -7.25) * CYLINDER_Z, CHROME)
	block("CabDoorHandle", V3(0.08, 0.12, 0.5), CF(s * 3.54, 4.55, -4.75), CHROME)
	block("CabDoorRearGap", V3(0.03, 3.85, 0.05), CF(s * 3.515, 5.025, -4.25), DARK_GAP)
	block("CabDoorBottomGap", V3(0.03, 0.05, 3.35), CF(s * 3.515, 3.1, -5.925), DARK_GAP)

	block("LouverRecess", V3(0.03, 1.2, 1.8), CF(s * 3.515, 5.9, 6.3), DARK_GAP)
	for i = 0, 6 do
		block("LouverSlat", V3(0.06, 0.07, 1.7), CF(s * 3.55, 5.4 + i * 0.17, 6.3), CREAM)
	end
end)

-- Cargo doors (right side only).
block("CargoDoorGap", V3(0.03, 3.95, 0.05), CF(3.515, 4.975, -3.9), DARK_GAP)
block("CargoDoorGap", V3(0.03, 5.45, 0.05), CF(3.515, 4.225, -1.125), DARK_GAP)
block("CargoDoorGap", V3(0.03, 5.45, 0.05), CF(3.515, 4.225, 1.775), DARK_GAP)
block("CargoDoorBottomGap", V3(0.03, 0.05, 5.33), CF(3.515, 1.5, -0.89), DARK_GAP)
for _, z in { -3.75, 1.62 } do
	for _, y in { 3.6, 6.2 } do
		block("CargoDoorHinge", V3(0.08, 0.3, 0.15), CF(3.54, y, z), CHROME)
	end
end
block("CargoDoorHandle", V3(0.08, 0.12, 0.5), CF(3.54, 4.5, -1.45), CHROME)

-- Rear: engine lid, plate, hatch, exhaust.
for _, y in { 4.3, 1.95 } do
	block("EngineLidGap", V3(3.8, 0.05, 0.04), CF(0, y, 8.22), DARK_GAP)
end
mirror(function(s)
	block("EngineLidGap", V3(0.05, 2.35, 0.04), CF(s * 1.9, 3.125, 8.22), DARK_GAP)
	block("HatchGap", V3(0.05, 1.8, 0.04), CF(s * 2.2, 5.82, 8.22), DARK_GAP)
end)
block("EngineLidHandle", V3(0.5, 0.1, 0.1), CF(0, 3.9, 8.25), CHROME)
block("LicensePlate", V3(1.6, 0.6, 0.04), CF(0, 2.9, 8.24), PLATE)
block("HatchGapTop", V3(4.4, 0.05, 0.04), CF(0, 6.72, 8.22), DARK_GAP)
block("HatchHandle", V3(0.4, 0.1, 0.1), CF(0, 5.1, 8.25), CHROME)
block("Muffler", V3(4.4, 0.36, 0.6), CF(0, 1.1, 7.75), EXHAUST)
cyl("Tailpipe", V3(0.8, 0.2, 0.2), CF(1.4, 1.1, 8.3) * CYLINDER_Z, EXHAUST)
cyl("FrontAxleBeam", V3(4.4, 0.35, 0.35), CF(0, 1.6, FRONT_AXLE), UNDERBODY)

return {
	name = "VW Microbus",
	-- Real: 105 km/h, 0-100 km/h in 40 s, brakes 0.6 g, coasts 0.15 g (VehicleDefaults maps them).
	speed = 46,
	acceleration = 2.9,
	braking = 11.9,
	coasting = 4.7,
	turnRate = 2,
	footprint = Vector2.new(7.0, 16.4),
	collision = {
		{ size = V3(7.0, 6.55, 16.4), offset = CF(0, 4.475, 0) }, -- y 1.2 .. 7.75
	},
	seats = {
		CF(-1.55, 2.6, -4.3), -- driver (LHD)
		CF(1.55, 2.6, -4.3), -- front passenger
		CF(-1.55, 2.6, -0.8), -- middle bench left
		CF(1.55, 2.6, -0.8), -- middle bench right
		CF(-1.55, 2.6, 2.8), -- rear bench left
		CF(1.55, 2.6, 2.8), -- rear bench right
	},
	pieces = pieces,
}
