-- DeLorean DMC-12: 1981 gull-wing coupe in unpainted brushed stainless steel with rear louvers.
-- Scale: 4.6 studs = 1 m (the car is 1.14 m tall; 4.6 lets the seated avatar fit under the roof).

local rgb = Color3.fromRGB
local M = Enum.Material
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball
local A = CFrame.Angles
local CN = CFrame.new
local V = Vector3.new

local CYLINDER_Z = A(0, math.rad(90), 0)
local CYLINDER_Y = A(0, 0, math.rad(90))

-- Wedge orientations (WedgePart default: right angle at local (ymin, zmax), rises toward +Z).
local RISE_FRONT = A(0, math.pi, 0) -- right angle at (ymin, zmin), rises toward -Z
local FLIP_Z = A(0, 0, math.pi) -- right angle at (ymax, zmax)
local FLIP_X = A(math.pi, 0, 0) -- right angle at (ymax, zmin)

-- Looks: color, material, reflectance, transparency.
local function look(
	color: Color3,
	material: Enum.Material?,
	reflectance: number?,
	transparency: number?
)
	return {
		color = color,
		material = material or M.SmoothPlastic,
		reflectance = reflectance,
		transparency = transparency,
	}
end

local SS = look(rgb(168, 170, 172), M.Metal, 0.12)
local SSD = look(rgb(148, 150, 153), M.Metal, 0.08)
local BLK = look(rgb(28, 28, 30))
local LOUVER = look(rgb(20, 20, 22), M.Metal)
local GAP = look(rgb(30, 30, 32))
local WELL = look(rgb(15, 15, 15))
local GRILLE = look(rgb(12, 12, 12))
local UNDER = look(rgb(30, 30, 32))
local GL = look(rgb(40, 48, 56), M.Glass, 0.1, 0.45)
local GL_REAR = look(rgb(40, 48, 56), M.Glass, 0.1, 0.6)
local HEAD = look(rgb(255, 244, 214), M.Neon)
local BEZEL = look(rgb(190, 190, 195), M.Metal)
local AMBER = look(rgb(255, 145, 25), M.Neon)
local RED = look(rgb(200, 20, 20), M.Neon)
local RED_GLASS = look(rgb(200, 20, 20), M.Glass)
local REV = look(rgb(240, 240, 235), M.Glass)
local TIRE = look(rgb(25, 25, 25), M.Fabric)
local SIDEWALL = look(rgb(38, 38, 40))
local RIM = look(rgb(185, 187, 190), M.Metal, 0.15)
local RIMFACE = look(rgb(160, 162, 165), M.Metal)
local SLOT = look(rgb(45, 45, 48))
local HUB = look(rgb(200, 200, 205), M.Metal)
local SEAT = look(rgb(72, 72, 75), M.Fabric)
local BOLSTER = look(rgb(55, 55, 58), M.Fabric)
local DASH = look(rgb(32, 32, 35))
local CONSOLE = look(rgb(40, 40, 43))
local TRIM = look(rgb(60, 60, 63))
local CARPET = look(rgb(35, 35, 37), M.Fabric)
local GAUGE = look(rgb(15, 15, 15))
local INTAKE_SLAT = look(rgb(55, 55, 58))
local PLATE = look(rgb(230, 230, 225))
local EXHAUST = look(rgb(120, 120, 125), M.Metal)

local pieces = {}

local function add(
	name: string,
	class: string?,
	shape: Enum.PartType?,
	size: Vector3,
	offset: CFrame,
	style
)
	table.insert(pieces, {
		name = name,
		class = class,
		shape = shape,
		size = size,
		offset = offset,
		color = style.color,
		material = style.material,
		reflectance = style.reflectance,
		transparency = style.transparency,
	})
end

local function block(name: string, size: Vector3, offset: CFrame, style)
	add(name, nil, nil, size, offset, style)
end

local function wedge(name: string, size: Vector3, offset: CFrame, style)
	add(name, "WedgePart", nil, size, offset, style)
end

local function cylinder(name: string, size: Vector3, offset: CFrame, style)
	add(name, nil, CYL, size, offset, style)
end

-- A bar of cross-section w x h running from p0 to p1.
local function bar(name: string, w: number, h: number, p0: Vector3, p1: Vector3, style)
	local d = p1 - p0
	local len = d.Magnitude
	local yaw = math.atan2(-d.X, -d.Z)
	local pitch = math.asin(d.Y / len)
	block(name, V(w, h, len), CFrame.new((p0 + p1) / 2) * A(0, yaw, 0) * A(pitch, 0, 0), style)
end

-- A thin triangle lying in a frame's local XZ plane. The right angle sits at (xIn, zEnd), where
-- zEnd is z0 when dz is -1 and z1 when dz is 1; the triangle widens toward xOut at that end.
local function planeTri(
	name: string,
	frame: CFrame,
	xIn: number,
	xOut: number,
	z0: number,
	z1: number,
	dz: number,
	y: number,
	thick: number,
	style
)
	local dx = if xOut > xIn then 1 else -1
	local rot = A(0, 0, -dx * math.pi / 2)
	if dz < 0 then
		rot = rot * RISE_FRONT
	end
	wedge(
		name,
		V(thick, math.abs(xOut - xIn), z1 - z0),
		frame * CN((xIn + xOut) / 2, y, (z0 + z1) / 2) * rot,
		style
	)
end

local SIDE = { -1, 1 }

-- Body side skins: outer face at x = +-4.27.
local SKIN_X = 4.27

-- Side skin block, thickness t, outer face on the body side.
local function skin(
	name: string,
	s: number,
	z0: number,
	z1: number,
	y0: number,
	y1: number,
	t: number,
	style
)
	block(
		name,
		V(t, y1 - y0, z1 - z0),
		CN(s * (SKIN_X - t / 2), (y0 + y1) / 2, (z0 + z1) / 2),
		style
	)
end

-- Side skin triangle in the YZ plane with the given wedge orientation.
local function skinTri(
	name: string,
	s: number,
	z0: number,
	z1: number,
	y0: number,
	y1: number,
	t: number,
	rot: CFrame,
	style
)
	wedge(
		name,
		V(t, y1 - y0, z1 - z0),
		CN(s * (SKIN_X - t / 2), (y0 + y1) / 2, (z0 + z1) / 2) * rot,
		style
	)
end

-- Hood plane: from the nose (y 2.3, z -9.5) up to the cowl (y 3.4, z -4.2).
local HOOD_ANGLE = math.atan2(1.1, 5.3)
local HOOD_LEN = math.sqrt(1.1 * 1.1 + 5.3 * 5.3)
local HOOD = CN(0, 2.85, -6.85) * A(-HOOD_ANGLE, 0, 0)
local function hoodY(z: number): number
	return 2.3 + (z + 9.5) * 1.1 / 5.3
end

-- Windshield plane: cowl (y 3.45, z -4.2) to roof front (y 5.12, z -1.0).
local WS_ANGLE = math.atan2(1.67, 3.2)
local WS_LEN = math.sqrt(1.67 * 1.67 + 3.2 * 3.2)
local WINDSHIELD = CN(0, 4.285, -2.6) * A(-WS_ANGLE, 0, 0)

-- Louver / backlight plane: roof rear (y 5.12, z 2.6) down to the deck (y 3.95, z 6.6).
local LV_ANGLE = math.atan2(1.17, 4.0)
local LV_LEN = math.sqrt(1.17 * 1.17 + 4.0 * 4.0)
local LOUVERS = CN(0, 4.535, 4.6) * A(LV_ANGLE, 0, 0)

-- Side glass plane: beltline (x 3.85, y 3.45) up to the roof edge (x 2.75, y 5.12).
local TUMBLE = math.atan2(1.1, 1.67)
local GLASS_SLANT = math.sqrt(1.1 * 1.1 + 1.67 * 1.67)
local function sidePlane(s: number): CFrame
	return CN(s * 3.30, 4.285, 0) * A(0, 0, s * TUMBLE)
end
-- Local y on the side plane for a world height.
local function sideY(y: number): number
	return (y - 4.285) / math.cos(TUMBLE)
end

------------------------------------------------------------------------------------------------
-- Body core
------------------------------------------------------------------------------------------------

block("Undertray", V(7.6, 0.25, 18.8), CN(0, 0.78, 0), UNDER)
block("FrontNoseBlock", V(4.4, 1.4, 5.25), CN(0, 1.6, -6.825), SSD)
block("EngineBayFiller", V(5.6, 2.0, 6.0), CN(0, 2.95, 6.3), SSD)
block("Firewall", V(7.0, 1.95, 0.15), CN(0, 1.98, -3.4), DASH)

-- Hood: thin slab on the hood plane, with chamfered outer edges.
block("Hood", V(8.3, 0.12, HOOD_LEN), HOOD * CN(0, -0.06, 0), SS)
block("CowlPanel", V(7.7, 0.08, 0.45), CN(0, 3.42, -4.0), GAP)
for _, s in SIDE do
	wedge(
		"HoodShoulder",
		V(HOOD_LEN, 0.12, 0.12),
		HOOD * CN(s * 4.21, -0.06, 0) * A(0, -s * math.pi / 2, 0),
		SSD
	)
	block("HoodSeam", V(0.04, 0.03, HOOD_LEN - 0.3), HOOD * CN(s * 3.55, 0.005, 0.1), GAP)
end
block("HoodFrontSeam", V(7.0, 0.03, 0.04), HOOD * CN(0, 0.005, -HOOD_LEN / 2 + 0.25), GAP)
block(
	"FuelFlap",
	V(0.6, 0.03, 0.6),
	HOOD * CN(-1.6, 0.005, (-5.0 + 6.85) / math.cos(HOOD_ANGLE)),
	SSD
)
for _, x in { -0.5, 0.5 } do
	block("WasherJet", V(0.15, 0.05, 0.1), HOOD * CN(x, 0.03, HOOD_LEN / 2 - 0.2), BLK)
end

-- Rear deck, chamfer and tail panel.
block("RearDeck", V(8.54, 0.2, 2.8), CN(0, 3.775, 7.95) * A(math.atan2(0.15, 2.7), 0, 0), SS)
wedge("RearDeckChamfer", V(8.54, 0.25, 0.3), CN(0, 3.675, 9.45) * RISE_FRONT, SSD)
block("RearFascia", V(8.54, 1.4, 0.3), CN(0, 2.85, 9.45), SS)

-- Roof.
block("Roof", V(5.5, 0.13, 3.6), CN(0, 5.19, 0.8), SS)
block("RoofHingeRail", V(0.22, 0.06, 3.6), CN(0, 5.28, 0.8), LOUVER)

------------------------------------------------------------------------------------------------
-- Sides
------------------------------------------------------------------------------------------------

for _, s in SIDE do
	-- Front fender: ahead of, over and behind the front arch (flat top y 2.64, z -6.45 .. -5.09).
	skin("FrontCorner", s, -9.5, -7.35, 0.65, 2.18, 0.5, SS)
	skinTri("FrontCornerTop", s, -9.5, -7.35, 2.18, hoodY(-7.35) - 0.12, 0.5, CFrame.identity, SS)
	skinTri("FrontArchFront", s, -7.35, -6.45, 1.74, 2.64, 0.5, FLIP_X, SS)
	skinTri("FrontArchRear", s, -5.09, -4.19, 1.74, 2.64, 0.5, FLIP_Z, SS)
	skinTri("FrontFender", s, -7.35, -4.19, 2.64, hoodY(-4.19) - 0.12, 0.5, CFrame.identity, SS)

	-- Door and sill between the arches, with a chamfered shoulder.
	skin("DoorSkin", s, -4.19, 3.40, 0.65, 3.2, 0.5, SS)
	skin("DoorShoulderInner", s, -4.19, 2.6, 3.2, 3.45, 0.25, SS)
	block("DoorShoulderInner2", V(0.25, 0.25, 6.79), CN(s * 3.895, 3.325, -0.795), SS)
	wedge(
		"DoorShoulder",
		V(6.79, 0.25, 0.25),
		CN(s * 4.145, 3.325, -0.795) * A(0, -s * math.pi / 2, 0),
		SSD
	)

	-- Rear quarter: rising top, arch (flat top y 3.2, z 4.3 .. 6.36) and rear corner.
	skin("QuarterBase", s, 2.6, 7.26, 3.2, 3.45, 0.8, SS)
	skinTri("QuarterRise", s, 2.6, 6.6, 3.45, 3.95, 0.8, CFrame.identity, SS)
	skin("QuarterUpper", s, 6.6, 9.6, 3.45, 3.82, 0.8, SS)
	skinTri("RearArchFront", s, 3.40, 4.30, 2.30, 3.2, 0.5, FLIP_X, SS)
	skinTri("RearArchRear", s, 6.36, 7.26, 2.30, 3.2, 0.5, FLIP_Z, SS)
	skin("RearCorner", s, 7.26, 9.6, 0.65, 3.45, 0.5, SS)

	-- Sail panels behind the door glass, on the tumblehome plane.
	local sp = sidePlane(s)
	local yMid = sideY(3.95)
	wedge(
		"SailUpper",
		V(0.5, 1 - yMid, 4.0),
		sp * CN(-s * 0.25, (1 + yMid) / 2, 4.6) * RISE_FRONT,
		SS
	)
	wedge("SailLower", V(0.5, yMid + 1, 4.0), sp * CN(-s * 0.25, (yMid - 1) / 2, 4.6) * FLIP_X, SS)
	planeTri("SailTop", LOUVERS, s * 2.6, s * 3.2, -LV_LEN / 2, LV_LEN / 2, 1, -0.03, 0.06, SSD)

	-- Panel seams and crease.
	local gx = s * 4.29
	block("DoorSeamFront", V(0.04, 2.55, 0.05), CN(gx, 2.175, -4.0), GAP)
	block("DoorSeamRear", V(0.04, 2.55, 0.05), CN(gx, 2.175, 2.6), GAP)
	block("DoorSeamSill", V(0.04, 0.05, 6.6), CN(gx, 0.9, -0.7), GAP)
	block("Crease", V(0.04, 0.05, 8.7), CN(gx, 2.6, -0.7), SSD)
	block("Crease", V(0.04, 0.05, 2.59), CN(gx, 2.6, 8.305), SSD)
	bar(
		"BPillarSeal",
		0.06,
		0.12,
		CN(s * 3.85, 3.45, 2.6).Position,
		CN(s * 2.75, 5.12, 2.6).Position,
		GAP
	)

	-- Wheel wells.
	block("FrontWellLiner", V(0.2, 1.7, 3.16), CN(s * 2.3, 1.75, -5.77), WELL)
	block("FrontWellCeiling", V(1.6, 0.06, 2.4), CN(s * 3.0, 2.77, -5.7), WELL)
	block("RearWellLiner", V(0.2, 2.2, 3.86), CN(s * 2.85, 2.1, 5.33), WELL)
	block("RearWellCeiling", V(1.0, 0.06, 3.0), CN(s * 3.3, 3.12, 5.33), WELL)
end

------------------------------------------------------------------------------------------------
-- Glass and pillars
------------------------------------------------------------------------------------------------

block("Windshield", V(5.5, 0.08, WS_LEN), WINDSHIELD, GL)
for _, s in SIDE do
	planeTri(
		"WindshieldEdge",
		WINDSHIELD,
		s * 2.75,
		s * 3.85,
		-WS_LEN / 2,
		WS_LEN / 2,
		-1,
		0,
		0.08,
		GL
	)
	bar("APillar", 0.18, 0.18, V(s * 3.85, 3.47, -4.2), V(s * 2.75, 5.14, -1.0), SS)

	local sp = sidePlane(s)
	block("SideGlass", V(0.08, GLASS_SLANT, 3.6), sp * CN(0, 0, 0.8), GL)
	wedge("SideGlassFront", V(0.08, GLASS_SLANT, 3.2), sp * CN(0, 0, -2.6), GL)
	local yToll = sideY(3.95)
	block("TollBoothTop", V(0.05, 0.05, 1.8), sp * CN(s * 0.06, yToll, 1.5), BLK)
	block("TollBoothFront", V(0.05, yToll + 1, 0.05), sp * CN(s * 0.06, (yToll - 1) / 2, 0.6), BLK)
end

block("Backlight", V(5.3, 0.06, LV_LEN), LOUVERS * CN(0, -0.04, 0), GL_REAR)

------------------------------------------------------------------------------------------------
-- Rear louvers
------------------------------------------------------------------------------------------------

for _, s in SIDE do
	block("LouverRail", V(0.18, 0.12, LV_LEN), LOUVERS * CN(s * 2.7, 0.08, 0), LOUVER)
end
block("LouverSpine", V(0.15, 0.12, LV_LEN), LOUVERS * CN(0, 0.08, 0), LOUVER)
for i = 1, 10 do
	block(
		"LouverSlat",
		V(5.3, 0.06, 0.32),
		LOUVERS * CN(0, 0.12, -1.85 + (i - 1) * 0.41) * A(math.rad(35), 0, 0),
		LOUVER
	)
end

------------------------------------------------------------------------------------------------
-- Bumpers and black trim
------------------------------------------------------------------------------------------------

block("FrontBumper", V(8.4, 1.0, 0.5), CN(0, 1.25, -9.57), BLK)
block("FrontBumperLip", V(7.6, 0.18, 0.55), CN(0, 0.70, -9.45), BLK)
for _, y in { 1.05, 1.2, 1.35 } do
	block("FrontIntakeSlat", V(4.0, 0.06, 0.05), CN(0, y, -9.84), GRILLE)
end
block("HeadlampBand", V(7.4, 0.56, 0.10), CN(0, 2.02, -9.55), BLK)
for _, y in { 1.86, 1.97, 2.08, 2.19 } do
	block("GrilleSlat", V(2.0, 0.05, 0.06), CN(0, y, -9.62), GRILLE)
end
block("RearBumper", V(8.4, 1.4, 0.5), CN(0, 1.50, 9.57), BLK)
for _, y in { 1.25, 1.85 } do
	block("RearBumperGroove", V(8.0, 0.05, 0.04), CN(0, y, 9.83), GRILLE)
end
block("FrontBumperGroove", V(8.0, 0.05, 0.04), CN(0, 1.62, -9.83), GRILLE)

for _, s in SIDE do
	block("FrontBumperWrap", V(0.5, 1.0, 1.9), CN(s * 4.05, 1.25, -8.6), BLK)
	block("RearBumperWrap", V(0.5, 1.4, 2.3), CN(s * 4.05, 1.5, 8.4), BLK)
	block("MirrorStalk", V(0.35, 0.08, 0.15), CN(s * 4.3, 3.6, -3.4), BLK)
	block("Mirror", V(0.25, 0.35, 0.55), CN(s * 4.55, 3.7, -3.4), BLK)
	block("DoorHandle", V(0.04, 0.10, 0.45), CN(s * 4.29, 3.0, 1.9), BLK)
	block("SideIntake", V(0.04, 0.45, 0.65), CN(s * 4.29, 3.0, 3.0), BLK)
	for _, y in { 2.88, 3.0, 3.12 } do
		block("SideIntakeSlat", V(0.05, 0.04, 0.6), CN(s * 4.31, y, 3.0), INTAKE_SLAT)
	end
end
for _, x in { -1.4, 0.9 } do
	block(
		"Wiper",
		V(2.3, 0.05, 0.08),
		WINDSHIELD * CN(x, 0.07, -WS_LEN / 2 + 0.25) * A(0, math.rad(6), 0),
		BLK
	)
end

------------------------------------------------------------------------------------------------
-- Lights
------------------------------------------------------------------------------------------------

for _, s in SIDE do
	for _, x in { 1.55, 2.55 } do
		block("HeadlampBezel", V(0.86, 0.50, 0.04), CN(s * x, 2.03, -9.60), BEZEL)
		block("Headlamp", V(0.76, 0.42, 0.06), CN(s * x, 2.03, -9.62), HEAD)
	end
	block("FrontIndicator", V(0.6, 0.22, 0.06), CN(s * 3.55, 1.45, -9.84), AMBER)
	block("SideMarker", V(0.04, 0.15, 0.45), CN(s * 4.31, 1.3, -8.6), AMBER)

	-- Taillight cluster: black housing, red / amber / red bands, reverse lamp inboard, ribs.
	block("TailHousing", V(3.1, 1.1, 0.08), CN(s * 2.45, 2.90, 9.62), BLK)
	block("TailTop", V(2.9, 0.25, 0.05), CN(s * 2.45, 3.25, 9.68), RED)
	block("TailMid", V(2.9, 0.25, 0.05), CN(s * 2.45, 2.92, 9.68), AMBER)
	block("TailLow", V(2.0, 0.25, 0.05), CN(s * 2.9, 2.60, 9.68), RED)
	block("Reverse", V(0.9, 0.25, 0.05), CN(s * 1.45, 2.60, 9.68), REV)
	for _, y in { 2.44, 2.76, 3.085, 3.41 } do
		block("TailRib", V(3.0, 0.04, 0.04), CN(s * 2.45, y, 9.72), BLK)
	end
	block("RearReflector", V(0.6, 0.12, 0.04), CN(s * 3.3, 1.6, 9.84), RED_GLASS)
end
block("PlateRecess", V(1.8, 0.85, 0.05), CN(0, 2.85, 9.6), BLK)
block("Plate", V(1.6, 0.7, 0.04), CN(0, 2.85, 9.63), PLATE)

------------------------------------------------------------------------------------------------
-- Wheels
------------------------------------------------------------------------------------------------

local function wheel(s: number, x: number, z: number, d: number, w: number)
	local y = d / 2
	local function at(dx: number): CFrame
		return CN(s * (x + dx), y, z)
	end
	local half = w / 2
	cylinder("Tire", V(w, d, d), at(0), TIRE)
	cylinder("Sidewall", V(0.04, d - 0.12, d - 0.12), at(half + 0.005), SIDEWALL)
	local rimW = w * 0.55
	cylinder("Rim", V(rimW, d * 0.66, d * 0.66), at(half + 0.05 - rimW / 2), RIM)
	cylinder("RimFace", V(0.04, d * 0.62, d * 0.62), at(half + 0.07), RIMFACE)
	for i = 1, 8 do
		block(
			"RimSlot",
			V(0.03, d * 0.07, d * 0.16),
			at(half + 0.095) * A(math.rad(45 * i), 0, 0) * CN(0, 0, d * 0.21),
			SLOT
		)
	end
	cylinder("HubCap", V(0.06, d * 0.16, d * 0.16), at(half + 0.11), HUB)
	for i = 1, 4 do
		cylinder(
			"LugNut",
			V(0.05, 0.07, 0.07),
			at(half + 0.105) * A(math.rad(90 * i + 45), 0, 0) * CN(0, 0, d * 0.11),
			HUB
		)
	end
end

for _, s in SIDE do
	wheel(s, 2.91, -5.77, 2.72, 0.90)
	wheel(s, 3.65, 5.33, 3.05, 1.08)
end

------------------------------------------------------------------------------------------------
-- Interior
------------------------------------------------------------------------------------------------

block("Floor", V(7.0, 0.08, 5.2), CN(0, 1.04, -0.6), CARPET)
block("Console", V(0.5, 0.9, 4.2), CN(0, 1.5, -0.9), CONSOLE)
block("GearLever", V(0.08, 0.5, 0.08), CN(0, 2.15, -0.6), BEZEL)
add("GearKnob", nil, BALL, V(0.18, 0.18, 0.18), CN(0, 2.42, -0.6), DASH)
block("DashTop", V(7.0, 0.45, 1.5), CN(0, 3.15, -2.6), DASH)
block("DashFace", V(7.0, 0.6, 0.15), CN(0, 2.65, -1.9), DASH)
block("Binnacle", V(1.4, 0.35, 0.5), CN(-1.3, 3.45, -2.1), DASH)
for _, x in { -1.6, -1.0 } do
	cylinder("Gauge", V(0.04, 0.32, 0.32), CN(x, 3.42, -1.84) * CYLINDER_Z, GAUGE)
end
local WHEEL_CF = CN(-1.3, 2.9, -0.85) * CYLINDER_Z * A(0, 0, math.rad(-25))
cylinder("SteeringWheel", V(0.10, 1.35, 1.35), WHEEL_CF, GAUGE)
cylinder("SteeringHub", V(0.14, 0.4, 0.4), WHEEL_CF * CN(0.03, 0, 0), DASH)
bar("SteeringColumn", 0.14, 0.14, V(-1.3, 3.25, -1.85), V(-1.3, 2.95, -0.95), DASH)

for _, s in SIDE do
	block("SeatCushion", V(1.9, 0.30, 1.9), CN(s * 1.3, 0.90, 0.6), SEAT)
	for _, b in { -1, 1 } do
		block("SeatBolster", V(0.2, 0.25, 1.8), CN(s * 1.3 + b * 0.95, 1.12, 0.6), BOLSTER)
	end
	block("SeatBack", V(1.9, 2.6, 0.35), CN(s * 1.3, 2.3, 1.75) * A(math.rad(12), 0, 0), SEAT)
	block("Headrest", V(1.0, 0.6, 0.3), CN(s * 1.3, 3.85, 2.05), SEAT)
	block("DoorPanel", V(0.1, 1.6, 6.5), CN(s * 3.62, 2.6, -0.6), TRIM)
end
block("RearBulkhead", V(6.4, 2.6, 0.15), CN(0, 2.4, 2.55), GAP)

------------------------------------------------------------------------------------------------
-- Details
------------------------------------------------------------------------------------------------

for _, x in { -1.6, -1.0 } do
	cylinder("ExhaustTip", V(0.5, 0.28, 0.28), CN(x, 0.7, 9.65) * CYLINDER_Z, EXHAUST)
	cylinder("ExhaustBore", V(0.52, 0.20, 0.20), CN(x, 0.7, 9.65) * CYLINDER_Z, GRILLE)
end
cylinder("Antenna", V(1.2, 0.04, 0.04), CN(3.6, 3.95, -4.35) * CYLINDER_Y, GAP)

return {
	name = "DeLorean DMC-12",
	speed = 105,
	turnRate = 2.4,
	footprint = Vector2.new(8.2, 19.2),
	collision = {
		{ size = V(8.4, 2.2, 19.4), offset = CN(0, 2.3, 0) },
		{ size = V(6.6, 1.75, 5.5), offset = CN(0, 4.275, 1.75) },
	},
	seats = {
		CN(-1.3, 0.5, 0.6), -- driver (left-hand drive)
		CN(1.3, 0.5, 0.6),
	},
	pieces = pieces,
}
