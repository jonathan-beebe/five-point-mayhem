-- 1969 Dodge Charger: R/T in gloss black with a red bumblebee stripe, hidden-lamp grille and Rallye wheels.
-- Scale: 4.3 studs = 1 m (the roof is 1.35 m tall; 4.3 lets the seated avatar clear it).

local rgb = Color3.fromRGB
local M = Enum.Material
local A = CFrame.Angles
local CN = CFrame.new
local V = Vector3.new

local CYLINDER_Z = A(0, math.rad(90), 0)
local CYLINDER_Y = A(0, 0, math.rad(90))
local CYL = Enum.PartType.Cylinder

-- Wedge orientations (WedgePart default: right angle at local (ymin, zmax)).
local FLIP_Z = A(0, 0, math.pi) -- right angle at (ymax, zmax)
local FLIP_X = A(math.pi, 0, 0) -- right angle at (ymax, zmin)
local REV = A(0, math.pi, 0) -- rises toward -Z
local SIDE_L = A(0, math.pi / 2, 0) -- length along Z, solid side facing +X
local SIDE_R = A(0, -math.pi / 2, 0) -- length along Z, solid side facing -X

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

local BODY = look(rgb(14, 14, 16), nil, 0.12)
local VINYL = look(rgb(20, 20, 22), M.Fabric)
local BLACK_MATTE = look(rgb(6, 6, 7))
local SCOOP = look(rgb(30, 30, 34), nil, 0.08)
local GRILLE_BLACK = look(rgb(10, 10, 11))
local SLAT_GREY = look(rgb(55, 56, 60), M.Metal)
local CHROME = look(rgb(205, 207, 212), M.Metal, 0.3)
local ARGENT = look(rgb(168, 170, 175), M.Metal, 0.1)
local SLOT_DARK = look(rgb(24, 24, 27))
local TIRE = look(rgb(26, 26, 28))
local DRUM = look(rgb(70, 68, 66), M.Metal)
local GLASS = look(rgb(30, 38, 45), M.Glass, nil, 0.45)
local STRIPE_RED = look(rgb(190, 25, 30), nil, 0.1)
local TAIL_RED = look(rgb(210, 20, 25), M.Neon)
local AMBER = look(rgb(255, 150, 30), M.Neon)
local REVERSE_WHITE = look(rgb(245, 240, 225), M.Neon)
local PLATE = look(rgb(225, 225, 215))
local VINYL_INT = look(rgb(22, 22, 24), M.Fabric)
local CARPET = look(rgb(18, 18, 20), M.Fabric)
local WOOD = look(rgb(92, 58, 34), M.Wood)
local GAUGE = look(rgb(15, 15, 17), M.Glass, nil, 0.1)

local SIDES = { -1, 1 } -- -1 is the left (driver) side

local pieces = {}

local function add(
	name: string,
	size: Vector3,
	cf: CFrame,
	style,
	class: string?,
	shape: Enum.PartType?
)
	table.insert(pieces, {
		name = name,
		class = class,
		shape = shape,
		size = size,
		offset = cf,
		color = style.color,
		material = style.material,
		reflectance = style.reflectance,
		transparency = style.transparency,
	})
end

local function wedge(name: string, size: Vector3, cf: CFrame, style)
	add(name, size, cf, style, "WedgePart")
end

local function cyl(name: string, size: Vector3, cf: CFrame, style)
	add(name, size, cf, style, nil, CYL)
end

-- Side wedge that slopes down toward the outboard edge (solid side inboard).
local function inboard(s: number): CFrame
	return if s > 0 then SIDE_R else SIDE_L
end

-- Body shell ---------------------------------------------------------------------------------

add("FrontCore", V(5.8, 2.9, 8.9), CN(0, 2.25, -6.65), BODY)
add("CabinFloor", V(5.8, 0.22, 8.8), CN(0, 0.89, 2.2), CARPET)
add("RearCore", V(5.8, 3.25, 4.5), CN(0, 2.425, 8.85), BODY)

for _, s in SIDES do
	local x = s * 3.625
	-- Side panels, arch to arch. The lower 0.25 tucks under with a chamfer.
	add("FenderRearSide", V(1.05, 2.77, 3.4), CN(x, 2.415, -4.1), BODY)
	add("DoorSide", V(1.05, 2.87, 6.1), CN(x, 2.465, 0.65), BODY)
	add("RockerInner", V(0.7, 0.25, 9.5), CN(s * 3.45, 0.905, -1.05), BODY)
	wedge("RockerTuck", V(9.5, 0.25, 0.35), CN(s * 3.975, 0.905, -1.05) * inboard(s) * FLIP_Z, BODY)

	add("FenderFront", V(1.05, 3.02, 2.0), CN(x, 2.29, -10.1), BODY)
	add("FenderOverArch", V(1.05, 0.7, 3.3), CN(x, 3.45, -7.45), BODY)
	add("QuarterOverArch", V(1.05, 1.0, 3.3), CN(x, 3.6, 5.35), BODY)
	add("QuarterRear", V(1.05, 3.32, 4.1), CN(x, 2.44, 9.05), BODY)

	-- Rounded arch corners.
	wedge("ArchFrontFwd", V(1.05, 0.9, 0.7), CN(x, 2.65, -8.75) * FLIP_X, BODY)
	wedge("ArchFrontAft", V(1.05, 0.9, 0.7), CN(x, 2.65, -6.15) * FLIP_Z, BODY)
	wedge("ArchRearFwd", V(1.05, 0.9, 0.7), CN(x, 2.65, 4.05) * FLIP_X, BODY)
	wedge("ArchRearAft", V(1.05, 0.9, 0.7), CN(x, 2.65, 6.65) * FLIP_Z, BODY)

	-- Wheel-well liners keep the cabin from showing through the arches.
	add("WellRear", V(0.08, 2.3, 3.3), CN(s * 2.93, 1.95, 5.35), BLACK_MATTE)

	-- Rounded beltline: front fender, door, rear quarter.
	wedge("ShoulderFender", V(8.7, 0.15, 1.05), CN(x, 3.875, -6.75) * inboard(s), BODY)
	wedge("ShoulderDoor", V(6.1, 0.15, 1.05), CN(x, 3.975, 0.65) * inboard(s), BODY)
	wedge("ShoulderQuarter", V(7.4, 0.15, 1.05), CN(x, 4.175, 7.4) * inboard(s), BODY)

	-- Flying-buttress sail panels.
	wedge("Buttress", V(0.35, 1.45, 4.1), CN(s * 2.85, 4.975, 7.35) * REV, BODY)
end
add("Hood", V(6.2, 0.25, 8.9), CN(0, 3.825, -6.65), BODY)
add("Header", V(8.3, 0.45, 0.35), CN(0, 3.555, -11.15), BODY)
wedge("HeaderChamfer", V(8.3, 0.17, 0.4), CN(0, 3.865, -11.1), BODY)
add("Cowl", V(6.4, 0.12, 0.45), CN(0, 4.04, -2.35), BLACK_MATTE)
add("TrunkLid", V(6.2, 0.2, 4.5), CN(0, 4.15, 8.85), BODY)
add("DeckLip", V(8.3, 0.1, 0.12), CN(0, 4.2, 11.18), BODY)

add("Roof", V(5.7, 0.18, 4.8), CN(0, 5.71, 2.9), VINYL)
for _, s in SIDES do
	wedge("RoofSide", V(4.8, 0.18, 0.3), CN(s * 3.0, 5.71, 2.9) * inboard(s), VINYL)
end
wedge("RoofFront", V(6.3, 0.18, 0.3), CN(0, 5.71, 0.35), VINYL)
wedge("RoofRear", V(6.3, 0.18, 0.3), CN(0, 5.71, 5.45) * REV, VINYL)

add("FrontValance", V(7.8, 0.42, 0.25), CN(0, 0.99, -11.15), BODY)
add("RearValance", V(7.9, 1.2, 0.12), CN(0, 1.4, 11.16), BODY)
add("TailPanel", V(7.9, 1.15, 0.08), CN(0, 3.195, 11.17), BLACK_MATTE)

-- Glass --------------------------------------------------------------------------------------

local WINDSHIELD = CN(0, 4.9, -0.85) * A(math.rad(-29.9), 0, 0)
add("Windshield", V(6.3, 0.08, 3.11), WINDSHIELD, GLASS)
add("RearWindow", V(5.2, 0.08, 1.95), CN(0, 4.97, 5.95) * A(math.rad(44), 0, 0), GLASS)
for _, s in SIDES do
	local tilt = A(0, 0, s * math.rad(12))
	wedge("GlassFront", V(0.08, 1.5, 2.6), CN(s * 3.38, 4.85, -0.8) * tilt, GLASS)
	add("GlassDoor", V(0.08, 1.5, 3.5), CN(s * 3.38, 4.85, 2.25) * tilt, GLASS)
	add("GlassRear", V(0.08, 1.5, 0.9), CN(s * 3.38, 4.85, 4.45) * tilt, GLASS)
	-- C-pillar between the quarter glass and the sail panel.
	add("CPillar", V(0.12, 1.55, 0.5), CN(s * 3.36, 4.85, 5.15) * tilt, BODY)
end

-- Bright trim --------------------------------------------------------------------------------

for _, s in SIDES do
	add("APillar", V(0.16, 0.12, 3.15), CN(s * 3.2, 0, 0) * WINDSHIELD, BODY)
	add("DripRail", V(0.07, 0.07, 4.8), CN(s * 3.17, 5.6, 2.9), CHROME)
	add("BeltMoulding", V(0.06, 0.06, 7.4), CN(s * 3.56, 4.08, 1.6), CHROME)
	add(
		"QuarterDivider",
		V(0.05, 1.5, 0.06),
		CN(s * 3.42, 4.85, 2.4) * A(0, 0, s * math.rad(12)),
		BLACK_MATTE
	)
end
add("WindshieldTrim", V(6.3, 0.06, 0.06), CN(0, 4.12, -2.18), CHROME)

-- Front end ----------------------------------------------------------------------------------

add("GrilleBacking", V(8.1, 1.68, 0.08), CN(0, 2.47, -11.14), GRILLE_BLACK)
add("GrilleTop", V(8.24, 0.08, 0.08), CN(0, 3.3, -11.2), CHROME)
add("GrilleBottom", V(8.24, 0.08, 0.08), CN(0, 1.64, -11.2), CHROME)
for _, s in SIDES do
	add("GrilleSide", V(0.08, 1.74, 0.08), CN(s * 4.12, 2.47, -11.2), CHROME)
end
add("GrilleDivider", V(0.22, 1.7, 0.14), CN(0, 2.47, -11.24), CHROME)
for i = 0, 7 do
	add("GrilleSlat", V(8.0, 0.05, 0.06), CN(0, 1.78 + i * 0.2, -11.2), SLAT_GREY)
end
for _, x in { 0.6, 1.3, 2.0, 2.7, 3.4 } do
	for _, s in SIDES do
		add("GrilleBar", V(0.04, 1.6, 0.05), CN(s * x, 2.47, -11.19), SLAT_GREY)
	end
end

add("FrontBumper", V(8.3, 0.4, 0.34), CN(0, 1.4, -11.3), CHROME)
add("FrontPlate", V(1.3, 0.38, 0.04), CN(0, 0.99, -11.3), PLATE)
for _, s in SIDES do
	add(
		"FrontBumperEnd",
		V(0.3, 0.4, 0.9),
		CN(s * 4.05, 1.4, -10.95) * A(0, -s * math.rad(25), 0),
		CHROME
	)
	add("ParkingLamp", V(0.9, 0.18, 0.04), CN(s * 2.7, 0.99, -11.3), AMBER)
	add("FrontMarker", V(0.04, 0.2, 0.55), CN(s * 4.17, 2.9, -10.3), AMBER)
end

-- Rear end -----------------------------------------------------------------------------------

for _, x in { 0.95, 2.75 } do
	for _, s in SIDES do
		add("Taillamp", V(1.6, 0.42, 0.05), CN(s * x, 3.18, 11.21), TAIL_RED)
	end
end
add("TailSurroundTop", V(7.9, 0.08, 0.06), CN(0, 3.75, 11.22), CHROME)
add("TailSurroundBottom", V(7.9, 0.08, 0.06), CN(0, 2.64, 11.22), CHROME)
add("TailBezel", V(0.12, 0.5, 0.06), CN(0, 3.18, 11.23), CHROME)
add("RearBumper", V(8.2, 0.55, 0.36), CN(0, 2.255, 11.35), CHROME)
add("RearPlate", V(1.3, 0.6, 0.04), CN(0, 1.45, 11.24), PLATE)
for _, s in SIDES do
	add("TailSurroundEnd", V(0.08, 1.15, 0.06), CN(s * 3.95, 3.195, 11.22), CHROME)
	add(
		"RearBumperEnd",
		V(0.3, 0.55, 0.8),
		CN(s * 4.0, 2.255, 10.95) * A(0, s * math.rad(25), 0),
		CHROME
	)
	add("BackupLamp", V(0.45, 0.16, 0.04), CN(s * 1.6, 2.255, 11.54), REVERSE_WHITE)
	add("RearMarker", V(0.04, 0.2, 0.55), CN(s * 4.17, 3.0, 10.5), TAIL_RED)
	cyl("ExhaustTip", V(0.6, 0.32, 0.32), CN(s * 2.4, 0.62, 11.1) * CYLINDER_Z, CHROME)
	cyl("ExhaustBore", V(0.04, 0.22, 0.22), CN(s * 2.4, 0.62, 11.41) * CYLINDER_Z, BLACK_MATTE)
end

-- Bumblebee stripe ---------------------------------------------------------------------------

for _, z in { 9.82, 10.32 } do
	add("StripeDeck", V(6.2, 0.04, 0.35), CN(0, 4.27, z), STRIPE_RED)
	for _, s in SIDES do
		wedge(
			"StripeQuarterTop",
			V(0.35, 0.15, 1.05),
			CN(s * 3.625, 4.205, z) * inboard(s),
			STRIPE_RED
		)
		add("StripeQuarterSide", V(0.04, 1.6, 0.35), CN(s * 4.17, 3.3, z), STRIPE_RED)
	end
end

-- Door and body details ----------------------------------------------------------------------

for _, s in SIDES do
	add("DoorGapFront", V(0.03, 3.0, 0.04), CN(s * 4.165, 2.4, -2.4), BLACK_MATTE)
	add("DoorGapRear", V(0.03, 3.0, 0.04), CN(s * 4.165, 2.4, 2.8), BLACK_MATTE)
	add("TrunkGapSide", V(0.04, 0.03, 4.4), CN(s * 3.1, 4.26, 8.85), BLACK_MATTE)

	-- Reverse scallop scoops: deepest at the rear.
	local scoop = A(0, 0, -s * math.pi / 2)
	wedge("ScoopUpper", V(0.35, 0.1, 2.6), CN(s * 4.2, 3.35, 0.4) * scoop, SCOOP)
	wedge("ScoopLower", V(0.28, 0.08, 2.0), CN(s * 4.19, 2.55, 0.9) * scoop, SCOOP)

	add("DoorHandle", V(0.05, 0.1, 0.45), CN(s * 4.18, 3.65, 2.2), CHROME)
	add("HoodVent", V(0.9, 0.04, 0.55), CN(s * 1.3, 3.97, -6.6), BLACK_MATTE)
	for _, z in { -6.8, -6.6, -6.4 } do
		add("HoodLouver", V(0.85, 0.05, 0.05), CN(s * 1.3, 3.99, z), SLAT_GREY)
	end
	add(
		"WiperArm",
		V(1.8, 0.04, 0.06),
		CN(s * 1.2 - 0.3, 4.1, -2.05) * A(0, math.rad(10), 0),
		BLACK_MATTE
	)
end
add("HoodGap", V(6.2, 0.03, 0.04), CN(0, 3.96, -2.45), BLACK_MATTE)
add("TrunkGapFront", V(6.2, 0.03, 0.04), CN(0, 4.26, 6.7), BLACK_MATTE)
add("TrunkGapRear", V(6.2, 0.03, 0.04), CN(0, 4.26, 11.05), BLACK_MATTE)

add("MirrorBase", V(0.12, 0.22, 0.12), CN(-4.15, 4.2, -1.6), CHROME)
add("MirrorStalk", V(0.3, 0.06, 0.06), CN(-4.3, 4.3, -1.6), CHROME)
cyl("MirrorBullet", V(0.42, 0.32, 0.32), CN(-4.48, 4.33, -1.6) * CYLINDER_Z, CHROME)
add("Antenna", V(0.03, 1.4, 0.03), CN(3.8, 4.65, -4.0), CHROME)
cyl("FuelCap", V(0.06, 0.45, 0.45), CN(-3.45, 4.22, 6.4) * CYLINDER_Y, CHROME)

-- Wheels: Rallye with argent face, chrome trim ring and cap --------------------------------------

for _, z in { -7.45, 5.35 } do
	for _, s in SIDES do
		local function at(d: number): CFrame
			return CN(s * (3.4 + d), 1.45, z)
		end
		cyl("BrakeDrum", V(0.5, 1.2, 1.2), at(-0.05), DRUM)
		cyl("Tire", V(0.82, 2.9, 2.9), at(0), TIRE)
		cyl("TrimRing", V(0.04, 1.78, 1.78), at(0.43), CHROME)
		cyl("RimFace", V(0.04, 1.55, 1.55), at(0.46), ARGENT)
		for k = 0, 4 do
			local a = math.rad(k * 72)
			add(
				"RimSlot",
				V(0.03, 0.28, 0.14),
				at(0.485) * CN(0, 0.5 * math.cos(a), 0.5 * math.sin(a)) * A(a, 0, 0),
				SLOT_DARK
			)
		end
		cyl("CenterCap", V(0.06, 0.55, 0.55), at(0.5), CHROME)
	end
end

-- Interior -----------------------------------------------------------------------------------

for _, s in SIDES do
	add("BucketCushion", V(1.8, 0.3, 1.9), CN(s * 1.6, 1.15, 1.4), VINYL_INT)
	add("BucketBack", V(1.8, 2.4, 0.35), CN(s * 1.6, 2.55, 2.3) * A(math.rad(12), 0, 0), VINYL_INT)
	add("Headrest", V(0.9, 0.55, 0.3), CN(s * 1.6, 4.0, 2.55), VINYL_INT)
	add("DoorTrim", V(0.06, 1.3, 4.8), CN(s * 3.07, 3.3, 0.4), VINYL_INT)
	add("RearTrim", V(0.06, 1.3, 2.0), CN(s * 3.07, 3.3, 4.6), VINYL_INT)
end
add("RearBench", V(5.4, 0.3, 1.8), CN(0, 1.15, 4.8), VINYL_INT)
add("RearBenchBack", V(5.6, 2.5, 0.35), CN(0, 2.6, 5.75) * A(math.rad(15), 0, 0), VINYL_INT)
add("PackageShelf", V(5.4, 0.08, 1.0), CN(0, 4.0, 6.3), VINYL_INT)
add("Console", V(0.8, 0.5, 2.4), CN(0, 1.25, 0.8), VINYL_INT)
add("ShifterStalk", V(0.08, 0.5, 0.08), CN(0, 1.7, 0.2), CHROME)
add("ShifterGrip", V(0.14, 0.3, 0.2), CN(0, 2.0, 0.18), WOOD)
add("Dash", V(6.2, 1.0, 1.2), CN(0, 3.55, -1.6), VINYL_INT)
add("GaugePanel", V(2.0, 0.6, 0.05), CN(-1.6, 3.6, -0.98), BLACK_MATTE)
for _, x in { -2.25, -1.85, -1.35, -0.95 } do
	cyl("Gauge", V(0.04, 0.38, 0.38), CN(x, 3.6, -0.95) * CYLINDER_Z, GAUGE)
end
-- Wheel top leans forward; the column runs down and forward into the dash.
local WHEEL = CN(-1.6, 3.25, -0.2) * A(math.rad(-25), 0, 0)
cyl("SteeringColumn", V(1.1, 0.14, 0.14), WHEEL * CN(0, 0, -0.6) * CYLINDER_Z, BLACK_MATTE)
cyl("SteeringWheel", V(0.08, 1.5, 1.5), WHEEL * CYLINDER_Z, WOOD)
cyl("SteeringHub", V(0.1, 0.4, 0.4), WHEEL * CN(0, 0, 0.05) * CYLINDER_Z, BLACK_MATTE)
add("RearViewMirror", V(0.6, 0.18, 0.06), CN(0, 5.35, 0.7), BLACK_MATTE)

return {
	name = "1969 Dodge Charger",
	speed = 120,
	turnRate = 2.2,
	footprint = Vector2.new(7.8, 22.4),
	collision = {
		{ size = V(8.2, 2.8, 22.6), offset = CN(0, 2.6, 0) },
		{ size = V(6.8, 1.8, 5.6), offset = CN(0, 4.9, 2.6) },
	},
	seats = {
		CN(-1.6, 0.8, 1.4), -- driver (LHD)
		CN(1.6, 0.8, 1.4),
		CN(-1.45, 0.8, 4.8),
		CN(1.45, 0.8, 4.8),
	},
	pieces = pieces,
}
