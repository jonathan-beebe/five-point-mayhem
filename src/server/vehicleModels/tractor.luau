-- Farm Tractor: John Deere 8R 410 row-crop tractor with yellow wheels, four-post glass cab and front suitcase weights.

-- Scale: 4 studs = 1 m.

local rgb = Color3.fromRGB
local M = Enum.Material
local A = CFrame.Angles
local CYL = Enum.PartType.Cylinder
local CYLINDER_Z = A(0, math.rad(90), 0)
local CYLINDER_Y = A(0, 0, math.rad(90))

-- Wedge orientations (WedgePart default: right angle at local (ymin, zmax), rises toward +Z).
local SIDE_L = A(0, math.pi / 2, 0) -- length along Z, vertical face toward +X
local SIDE_R = A(0, -math.pi / 2, 0) -- length along Z, vertical face toward -X
local REV = A(0, math.pi, 0) -- rises toward -Z

local GREEN = rgb(54, 124, 43)
local YELLOW = rgb(255, 222, 0)
local YELLOW_DISH = rgb(236, 200, 0)
local TIRE = rgb(32, 32, 32)
local LUG = rgb(26, 26, 26)
local BLACK_FRAME = rgb(20, 20, 22)
local CHASSIS = rgb(28, 28, 30)
local WEIGHT = rgb(32, 32, 34)
local GRILLE = rgb(35, 35, 35)
local HUB_GREY = rgb(90, 90, 95)
local BOLT = rgb(160, 160, 165)
local GLASS = rgb(60, 80, 85)
local MIRROR = rgb(190, 200, 205)
local SCREEN = rgb(20, 30, 40)
local HEAD_WHITE = rgb(255, 244, 214)
local RED = rgb(220, 20, 20)
local AMBER = rgb(255, 150, 20)
local EXHAUST = rgb(40, 40, 40)
local SHIELD = rgb(55, 55, 58)
local SEAT_FABRIC = rgb(45, 45, 48)
local INTERIOR_DARK = rgb(30, 30, 32)
local WHEEL_BLACK = rgb(25, 25, 25)
local CAP_RED = rgb(200, 30, 30)
local CAP_BLUE = rgb(30, 80, 200)
local CAP_GREEN = rgb(40, 150, 60)
local CAP_YELLOW = rgb(240, 200, 0)

local PAINT = { reflectance = 0.1 }
local RIM_PAINT = { reflectance = 0.08 }

local pieces = {}

local function block(name, size, offset, color, material, extra)
	local spec = {
		name = name,
		size = size,
		offset = offset,
		color = color,
		material = material or M.SmoothPlastic,
	}
	if extra then
		for k, v in extra do
			spec[k] = v
		end
	end
	table.insert(pieces, spec)
	return spec
end

local function cyl(name, size, offset, color, material, extra)
	local spec = block(name, size, offset, color, material, extra)
	spec.shape = CYL
	return spec
end

local function wedge(name, size, offset, color, material, extra)
	local spec = block(name, size, offset, color, material, extra)
	spec.class = "WedgePart"
	return spec
end

-- Disc on an X axle: thickness along X, diameter d.
local function disc(name, x, y, z, thickness, d, color, material, extra)
	return cyl(name, Vector3.new(thickness, d, d), CFrame.new(x, y, z), color, material, extra)
end

---------------------------------------------------------------------------
-- Rear wheels
---------------------------------------------------------------------------
local REAR_Y, REAR_Z = 4.1, 5.8

for _, s in { -1, 1 } do
	local xc = 4.06 * s
	local F = 5.46
	disc("RearTire", xc, REAR_Y, REAR_Z, 2.8, 7.8, TIRE)
	for k = 0, 15 do
		local theta = k * 22.5
		local alt = (k % 2 == 0) and -1 or 1
		block(
			"RearLug",
			Vector3.new(1.4, 0.4, 0.8),
			CFrame.new(xc + alt * 0.65, REAR_Y, REAR_Z)
				* A(math.rad(theta), 0, 0)
				* CFrame.new(0, 3.9, 0)
				* A(0, math.rad(25 * alt), 0),
			LUG,
			M.Fabric
		)
	end
	disc("RearRimLip", s * (F + 0.03), REAR_Y, REAR_Z, 0.06, 4.6, YELLOW, nil, RIM_PAINT)
	disc("RearRimShadow", s * (F + 0.07), REAR_Y, REAR_Z, 0.04, 4.1, BLACK_FRAME)
	disc("RearRimDish", s * (F + 0.11), REAR_Y, REAR_Z, 0.04, 3.8, YELLOW_DISH)
	for i = 0, 3 do
		local a = math.rad(45 + 90 * i)
		disc(
			"RearHandHole",
			s * (F + 0.15),
			REAR_Y + 1.45 * math.cos(a),
			REAR_Z + 1.45 * math.sin(a),
			0.04,
			0.7,
			BLACK_FRAME
		)
	end
	disc("RearCenterDisc", s * (F + 0.2), REAR_Y, REAR_Z, 0.15, 2.2, YELLOW, nil, RIM_PAINT)
	for i = 0, 7 do
		local a = math.rad(22.5 + 45 * i)
		disc(
			"RearBolt",
			s * (F + 0.31),
			REAR_Y + 0.8 * math.cos(a),
			REAR_Z + 0.8 * math.sin(a),
			0.12,
			0.18,
			BOLT,
			M.Metal
		)
	end
	disc("RearHubCap", s * (F + 0.3), REAR_Y, REAR_Z, 0.2, 1.1, HUB_GREY, M.Metal)
	disc("RearAxleHousing", s * 1.95, REAR_Y, REAR_Z, 1.5, 1.3, CHASSIS, M.Metal)
end

---------------------------------------------------------------------------
-- Front wheels
---------------------------------------------------------------------------
local FRONT_Y, FRONT_Z = 3.2, -6.4

for _, s in { -1, 1 } do
	local xc = 4.0 * s
	local F = 5.2
	disc("FrontTire", xc, FRONT_Y, FRONT_Z, 2.4, 6.0, TIRE)
	for k = 0, 13 do
		local theta = k * 360 / 14
		local alt = (k % 2 == 0) and -1 or 1
		block(
			"FrontLug",
			Vector3.new(1.2, 0.35, 0.6),
			CFrame.new(xc + alt * 0.55, FRONT_Y, FRONT_Z)
				* A(math.rad(theta), 0, 0)
				* CFrame.new(0, 3.025, 0)
				* A(0, math.rad(25 * alt), 0),
			LUG,
			M.Fabric
		)
	end
	disc("FrontRimLip", s * (F + 0.03), FRONT_Y, FRONT_Z, 0.06, 3.4, YELLOW, nil, RIM_PAINT)
	disc("FrontRimShadow", s * (F + 0.07), FRONT_Y, FRONT_Z, 0.04, 3.0, BLACK_FRAME)
	disc("FrontRimDish", s * (F + 0.11), FRONT_Y, FRONT_Z, 0.04, 2.8, YELLOW_DISH)
	for i = 0, 5 do
		local a = math.rad(60 * i)
		disc(
			"FrontBolt",
			s * (F + 0.16),
			FRONT_Y + 1.05 * math.cos(a),
			FRONT_Z + 1.05 * math.sin(a),
			0.1,
			0.16,
			BOLT,
			M.Metal
		)
	end
	disc("FrontPlanetaryHub", s * (F + 0.33), FRONT_Y, FRONT_Z, 0.4, 1.6, HUB_GREY, M.Metal)
	disc("FrontHubCap", s * (F + 0.6), FRONT_Y, FRONT_Z, 0.15, 0.9, CHASSIS, M.Metal)
	block(
		"SteeringKnuckle",
		Vector3.new(0.6, 1.2, 0.8),
		CFrame.new(s * 2.75, FRONT_Y, FRONT_Z),
		CHASSIS,
		M.Metal
	)
end

---------------------------------------------------------------------------
-- Fenders and tail lamps
---------------------------------------------------------------------------
for _, s in { -1, 1 } do
	for _, phi in { -70, -35, 0, 35, 70 } do
		block(
			"RearFender",
			Vector3.new(3.3, 0.18, 2.9),
			CFrame.new(s * 4.06, REAR_Y, REAR_Z) * A(math.rad(phi), 0, 0) * CFrame.new(0, 4.6, 0),
			GREEN,
			nil,
			PAINT
		)
	end
	for _, phi in { -50, -32.5, -15, 2.5, 20 } do
		block(
			"FrontFender",
			Vector3.new(2.7, 0.15, 1.4),
			CFrame.new(s * 4.0, FRONT_Y, FRONT_Z) * A(math.rad(phi), 0, 0) * CFrame.new(0, 3.6, 0),
			GREEN,
			nil,
			PAINT
		)
	end
	block(
		"FrontFenderArm",
		Vector3.new(0.2, 2.6, 0.3),
		CFrame.new(s * 2.75, 5.1, -6.4),
		CHASSIS,
		M.Metal
	)
	block(
		"TailLampBracket",
		Vector3.new(0.9, 0.9, 0.2),
		CFrame.new(s * 4.9, 5.9, 10.5),
		BLACK_FRAME
	)
	block("TailLamp", Vector3.new(0.35, 0.5, 0.05), CFrame.new(s * 4.7, 5.9, 10.625), RED, M.Neon)
	block(
		"TailIndicator",
		Vector3.new(0.35, 0.5, 0.05),
		CFrame.new(s * 5.1, 5.9, 10.625),
		AMBER,
		M.Neon
	)
end

---------------------------------------------------------------------------
-- Hood and nose
---------------------------------------------------------------------------
block("HoodCore", Vector3.new(4.3, 3.4, 11.0), CFrame.new(0, 6.7, -3.7), GREEN, nil, PAINT)
block("HoodTop", Vector3.new(3.5, 0.4, 11.0), CFrame.new(0, 8.6, -3.7), GREEN, nil, PAINT)
wedge(
	"HoodShoulderL",
	Vector3.new(11.0, 0.4, 0.4),
	CFrame.new(-1.95, 8.6, -3.7) * SIDE_L,
	GREEN,
	nil,
	PAINT
)
wedge(
	"HoodShoulderR",
	Vector3.new(11.0, 0.4, 0.4),
	CFrame.new(1.95, 8.6, -3.7) * SIDE_R,
	GREEN,
	nil,
	PAINT
)
block("Nose", Vector3.new(4.3, 3.0, 1.2), CFrame.new(0, 6.5, -9.8), GREEN, nil, PAINT)
wedge("NoseTop", Vector3.new(4.3, 0.8, 1.2), CFrame.new(0, 8.4, -9.8), GREEN, nil, PAINT)
block("GrilleMesh", Vector3.new(2.6, 2.4, 0.05), CFrame.new(0, 6.4, -10.43), GRILLE, M.DiamondPlate)
for _, y in { 5.4, 5.9, 6.4, 6.9, 7.4 } do
	block("GrilleSlat", Vector3.new(2.6, 0.08, 0.06), CFrame.new(0, y, -10.47), BLACK_FRAME)
end
for _, s in { -1, 1 } do
	block(
		"HeadlampHousing",
		Vector3.new(0.7, 1.4, 0.05),
		CFrame.new(s * 1.75, 6.9, -10.43),
		BLACK_FRAME
	)
	block(
		"Headlamp",
		Vector3.new(0.5, 0.4, 0.05),
		CFrame.new(s * 1.75, 7.3, -10.47),
		HEAD_WHITE,
		M.Neon
	)
	block(
		"Headlamp",
		Vector3.new(0.5, 0.4, 0.05),
		CFrame.new(s * 1.75, 6.5, -10.47),
		HEAD_WHITE,
		M.Neon
	)
	block(
		"HoodVent",
		Vector3.new(0.05, 1.8, 3.0),
		CFrame.new(s * 2.175, 6.6, -7.4),
		GRILLE,
		M.DiamondPlate
	)
	block(
		"HoodLowerEdge",
		Vector3.new(0.05, 0.1, 11.0),
		CFrame.new(s * 2.175, 5.05, -3.7),
		BLACK_FRAME
	)
	block(
		"HoodPanelGap",
		Vector3.new(0.04, 0.05, 11.0),
		CFrame.new(s * 2.17, 8.2, -3.7),
		BLACK_FRAME
	)
end
block("Badge", Vector3.new(0.9, 0.05, 0.6), CFrame.new(0, 8.825, -8.6), YELLOW)
block("OilPan", Vector3.new(3.0, 1.4, 8.0), CFrame.new(0, 4.4, -5.0), CHASSIS, M.Metal)

---------------------------------------------------------------------------
-- Front weights and chassis
---------------------------------------------------------------------------
block("WeightBracket", Vector3.new(4.0, 0.6, 1.6), CFrame.new(0, 2.5, -11.2), CHASSIS, M.Metal)
for i = 0, 9 do
	block(
		"SuitcaseWeight",
		Vector3.new(0.34, 2.15, 1.6),
		CFrame.new(-1.665 + i * 0.37, 3.875, -11.2),
		WEIGHT,
		M.Metal
	)
end
cyl("WeightHandleBar", Vector3.new(3.8, 0.25, 0.25), CFrame.new(0, 5.1, -11.6), CHASSIS, M.Metal)
cyl("FrontAxle", Vector3.new(5.0, 0.9, 0.9), CFrame.new(0, 3.2, -6.4), CHASSIS, M.Metal)
block("FrontDiff", Vector3.new(1.2, 1.2, 1.4), CFrame.new(0, 3.2, -6.4), CHASSIS, M.Metal)
cyl(
	"Driveshaft",
	Vector3.new(6.0, 0.35, 0.35),
	CFrame.new(0, 3.0, -2.5) * CYLINDER_Z,
	CHASSIS,
	M.Metal
)
block("Transmission", Vector3.new(2.4, 3.0, 6.0), CFrame.new(0, 5.0, 3.6), CHASSIS, M.Metal)

---------------------------------------------------------------------------
-- Cab
---------------------------------------------------------------------------
local GLASS_LOOK = { transparency = 0.45 }

block("CabLower", Vector3.new(4.9, 1.4, 6.8), CFrame.new(0, 6.9, 5.2), BLACK_FRAME)
for _, s in { -1, 1 } do
	block("CabLowerWall", Vector3.new(0.1, 1.2, 6.8), CFrame.new(s * 2.4, 8.2, 5.2), BLACK_FRAME)
	block("CabPostFront", Vector3.new(0.3, 4.2, 0.3), CFrame.new(s * 3.45, 10.9, 1.9), BLACK_FRAME)
	block("CabPostRear", Vector3.new(0.3, 4.2, 0.3), CFrame.new(s * 3.45, 10.9, 8.5), BLACK_FRAME)
	block(
		"SideGlass",
		Vector3.new(0.08, 3.95, 6.3),
		CFrame.new(s * 3.45, 10.95, 5.2),
		GLASS,
		M.Glass,
		GLASS_LOOK
	)
end
block("CabLowerFront", Vector3.new(4.9, 1.2, 0.1), CFrame.new(0, 8.2, 1.9), BLACK_FRAME)
block("CabLowerRear", Vector3.new(4.9, 1.2, 0.1), CFrame.new(0, 8.2, 8.55), BLACK_FRAME)
block("CabSill", Vector3.new(7.2, 0.25, 6.9), CFrame.new(0, 8.85, 5.2), BLACK_FRAME)
block(
	"FrontGlass",
	Vector3.new(6.6, 3.95, 0.08),
	CFrame.new(0, 10.95, 1.9),
	GLASS,
	M.Glass,
	GLASS_LOOK
)
block(
	"RearGlass",
	Vector3.new(6.6, 3.95, 0.08),
	CFrame.new(0, 10.95, 8.5),
	GLASS,
	M.Glass,
	GLASS_LOOK
)
block("DoorSeam", Vector3.new(0.06, 3.95, 0.12), CFrame.new(-3.5, 10.95, 4.6), BLACK_FRAME)
block("DoorHandle", Vector3.new(0.06, 0.12, 0.5), CFrame.new(-3.51, 10.2, 3.2), BLACK_FRAME)
block("RoofShell", Vector3.new(7.6, 0.6, 7.8), CFrame.new(0, 13.5, 5.2), GREEN, nil, PAINT)
block("RoofVisor", Vector3.new(7.4, 0.25, 7.6), CFrame.new(0, 13.075, 5.2), BLACK_FRAME)
block("RoofCap", Vector3.new(6.8, 0.3, 6.6), CFrame.new(0, 13.95, 5.2), GREEN, nil, PAINT)
wedge("RoofCapFront", Vector3.new(6.8, 0.3, 0.6), CFrame.new(0, 13.95, 1.6), GREEN, nil, PAINT)
wedge("RoofCapRear", Vector3.new(6.8, 0.3, 0.6), CFrame.new(0, 13.95, 8.8) * REV, GREEN, nil, PAINT)
wedge(
	"RoofCapSideL",
	Vector3.new(6.6, 0.3, 0.4),
	CFrame.new(-3.6, 13.95, 5.2) * SIDE_L,
	GREEN,
	nil,
	PAINT
)
wedge(
	"RoofCapSideR",
	Vector3.new(6.6, 0.3, 0.4),
	CFrame.new(3.6, 13.95, 5.2) * SIDE_R,
	GREEN,
	nil,
	PAINT
)
block("StarFireBase", Vector3.new(1.3, 0.2, 1.1), CFrame.new(0, 14.2, 2.4), HUB_GREY, M.Metal)
cyl(
	"StarFireDome",
	Vector3.new(0.3, 1.15, 1.15),
	CFrame.new(0, 14.45, 2.4) * CYLINDER_Y,
	HUB_GREY,
	M.Metal
)
block(
	"WiperFront",
	Vector3.new(2.4, 0.06, 0.04),
	CFrame.new(-0.8, 9.9, 1.84) * A(0, 0, math.rad(60)),
	BLACK_FRAME
)
block(
	"WiperRear",
	Vector3.new(2.4, 0.06, 0.04),
	CFrame.new(-0.8, 9.9, 8.56) * A(0, 0, math.rad(60)),
	BLACK_FRAME
)

---------------------------------------------------------------------------
-- Lights, mirrors, exhaust, ladder
---------------------------------------------------------------------------
for _, x in { -3.1, -2.0, -0.9, 0.9, 2.0, 3.1 } do
	block(
		"FrontWorkLight",
		Vector3.new(0.5, 0.22, 0.06),
		CFrame.new(x, 13.45, 1.27),
		HEAD_WHITE,
		M.Neon
	)
end
for _, x in { -2.6, -1.0, 1.0, 2.6 } do
	block(
		"RearWorkLight",
		Vector3.new(0.5, 0.22, 0.06),
		CFrame.new(x, 13.45, 9.13),
		HEAD_WHITE,
		M.Neon
	)
end
for _, s in { -1, 1 } do
	block(
		"CornerLamp",
		Vector3.new(0.3, 0.22, 0.06),
		CFrame.new(s * 3.6, 13.45, 1.27),
		AMBER,
		M.Neon
	)
	block("MirrorArm", Vector3.new(1.5, 0.12, 0.12), CFrame.new(s * 4.3, 12.2, 1.6), BLACK_FRAME)
	block("MirrorHead", Vector3.new(0.8, 1.3, 0.2), CFrame.new(s * 5.0, 11.8, 1.6), BLACK_FRAME)
	block(
		"MirrorGlass",
		Vector3.new(0.7, 1.15, 0.03),
		CFrame.new(s * 5.0, 11.8, 1.715),
		MIRROR,
		M.Glass,
		{ reflectance = 0.5 }
	)
end

block("ExhaustBase", Vector3.new(0.8, 0.6, 0.8), CFrame.new(3.1, 7.3, 0.9), CHASSIS, M.Metal)
cyl(
	"ExhaustStack",
	Vector3.new(7.2, 0.5, 0.5),
	CFrame.new(3.1, 10.8, 0.9) * CYLINDER_Y,
	EXHAUST,
	M.Metal
)
cyl(
	"HeatShield",
	Vector3.new(3.2, 0.62, 0.62),
	CFrame.new(3.1, 11.0, 0.9) * CYLINDER_Y,
	SHIELD,
	M.DiamondPlate
)
cyl(
	"ExhaustTip",
	Vector3.new(0.08, 0.58, 0.58),
	CFrame.new(3.1, 14.42, 0.9) * CYLINDER_Y * A(0, 0, math.rad(15)),
	EXHAUST,
	M.Metal
)
block("ExhaustBracket", Vector3.new(0.2, 0.2, 0.8), CFrame.new(3.2, 12.0, 1.4), BLACK_FRAME)

block(
	"LadderRailInner",
	Vector3.new(0.12, 7.0, 0.12),
	CFrame.new(-2.75, 5.1, 0.9),
	BLACK_FRAME,
	M.DiamondPlate
)
block(
	"LadderRailOuter",
	Vector3.new(0.12, 7.0, 0.12),
	CFrame.new(-4.55, 5.1, 0.9),
	BLACK_FRAME,
	M.DiamondPlate
)
for _, y in { 2.0, 3.6, 5.2, 6.8 } do
	block(
		"LadderStep",
		Vector3.new(1.8, 0.1, 0.55),
		CFrame.new(-3.65, y, 0.9),
		BLACK_FRAME,
		M.DiamondPlate
	)
end

---------------------------------------------------------------------------
-- Interior
---------------------------------------------------------------------------
block("CabFloor", Vector3.new(4.7, 0.05, 6.5), CFrame.new(0, 7.625, 5.2), INTERIOR_DARK)
block("SeatPedestal", Vector3.new(0.9, 0.8, 0.9), CFrame.new(0, 8.0, 5.4), CHASSIS, M.Metal)
block("SeatCushion", Vector3.new(1.9, 0.4, 1.9), CFrame.new(0, 8.55, 5.3), SEAT_FABRIC, M.Fabric)
block(
	"SeatBackrest",
	Vector3.new(1.9, 2.6, 0.4),
	CFrame.new(0, 10.2, 6.25) * A(math.rad(8), 0, 0),
	SEAT_FABRIC,
	M.Fabric
)
block("CommandArm", Vector3.new(0.55, 0.45, 2.2), CFrame.new(1.35, 9.6, 5.0), INTERIOR_DARK)
block(
	"CommandArmControls",
	Vector3.new(0.4, 0.2, 0.8),
	CFrame.new(1.35, 9.925, 4.4),
	HUB_GREY,
	M.Metal
)
block("LeftArmrest", Vector3.new(0.3, 0.3, 1.4), CFrame.new(-1.15, 9.5, 5.4), INTERIOR_DARK)
block(
	"Display",
	Vector3.new(0.9, 0.65, 0.08),
	CFrame.new(1.6, 10.9, 3.6),
	SCREEN,
	M.Glass,
	{ reflectance = 0.2 }
)
block("ConsoleTower", Vector3.new(1.2, 2.6, 0.55), CFrame.new(0, 8.9, 2.275), INTERIOR_DARK)
block("ColumnCover", Vector3.new(0.5, 0.4, 0.8), CFrame.new(0, 10.1, 2.85), INTERIOR_DARK)
cyl(
	"SteeringColumn",
	Vector3.new(0.9, 0.25, 0.25),
	CFrame.new(0, 10.355, 3.41) * A(math.rad(-50), 0, 0) * CYLINDER_Z,
	INTERIOR_DARK
)
local WHEEL_CF = CFrame.new(0, 10.7, 3.7) * A(math.rad(-50), 0, 0) * CYLINDER_Z
cyl("SteeringWheel", Vector3.new(0.1, 1.3, 1.3), WHEEL_CF, WHEEL_BLACK)
cyl("SteeringHub", Vector3.new(0.14, 0.35, 0.35), WHEEL_CF, HUB_GREY, M.Metal)
block("BuddySeat", Vector3.new(1.2, 0.3, 1.0), CFrame.new(-1.95, 8.6, 3.8), SEAT_FABRIC, M.Fabric)

---------------------------------------------------------------------------
-- Rear hitch and hydraulics
---------------------------------------------------------------------------
block("RearHousing", Vector3.new(2.6, 3.4, 2.4), CFrame.new(0, 5.0, 8.6), CHASSIS, M.Metal)
for _, s in { -1, 1 } do
	block("LowerLink", Vector3.new(0.3, 0.3, 3.6), CFrame.new(s * 1.3, 2.7, 10.2), CHASSIS, M.Metal)
	cyl(
		"LowerLinkEnd",
		Vector3.new(0.4, 0.45, 0.45),
		CFrame.new(s * 1.3, 2.7, 11.75),
		CHASSIS,
		M.Metal
	)
	block("LiftArm", Vector3.new(0.25, 0.35, 2.2), CFrame.new(s * 1.1, 6.6, 9.4), CHASSIS, M.Metal)
	block("LiftRod", Vector3.new(0.2, 3.6, 0.2), CFrame.new(s * 1.25, 4.6, 10.4), CHASSIS, M.Metal)
end
cyl(
	"TopLink",
	Vector3.new(2.2, 0.35, 0.35),
	CFrame.new(0, 6.0, 10.9) * CYLINDER_Z,
	CHASSIS,
	M.Metal
)
block("Drawbar", Vector3.new(0.8, 0.25, 3.4), CFrame.new(0, 2.3, 10.2), CHASSIS, M.Metal)
cyl("DrawbarPin", Vector3.new(0.6, 0.2, 0.2), CFrame.new(0, 2.45, 11.5) * CYLINDER_Y, BOLT, M.Metal)
cyl("PtoStub", Vector3.new(0.6, 0.35, 0.35), CFrame.new(0, 3.9, 10.1) * CYLINDER_Z, BOLT, M.Metal)
block("PtoShield", Vector3.new(1.2, 0.08, 0.9), CFrame.new(0, 4.4, 10.2), GREEN, nil, PAINT)
block("CouplerPlate", Vector3.new(2.6, 0.9, 0.15), CFrame.new(0, 7.0, 9.875), CHASSIS, M.Metal)
local CAP_COLORS = { CAP_RED, CAP_BLUE, CAP_GREEN, CAP_YELLOW }
for i, x in { -0.9, -0.3, 0.3, 0.9 } do
	cyl(
		"Coupler",
		Vector3.new(0.4, 0.22, 0.22),
		CFrame.new(x, 7.0, 10.15) * CYLINDER_Z,
		BOLT,
		M.Metal
	)
	cyl(
		"CouplerCap",
		Vector3.new(0.08, 0.26, 0.26),
		CFrame.new(x, 7.0, 10.39) * CYLINDER_Z,
		CAP_COLORS[i]
	)
end

return {
	name = "Farm Tractor",
	-- Real: 50 km/h, 0-40 km/h in 10 s, brakes 0.4 g, coasts 0.2 g (VehicleDefaults maps them).
	speed = 28,
	acceleration = 3.9,
	braking = 9.1,
	coasting = 5.7,
	turnRate = 2,
	footprint = Vector2.new(11.8, 24),
	collision = {
		{ size = Vector3.new(4.4, 6.4, 14.0), offset = CFrame.new(0, 5.6, -5.0) },
		{ size = Vector3.new(11.8, 7.4, 8.8), offset = CFrame.new(0, 5.1, 5.9) },
		{ size = Vector3.new(7.6, 5.3, 7.8), offset = CFrame.new(0, 11.45, 5.2) },
		{ size = Vector3.new(11.0, 5.0, 6.6), offset = CFrame.new(0, 3.7, -6.4) },
	},
	seats = { CFrame.new(0, 8.3, 5.3) },
	pieces = pieces,
}
