-- Rally Car: Subaru Impreza WRC 2003-05 "blobeye" sedan in WR Blue with gold wheels and gravel trim.
-- Scale: 4.3 studs = 1 m (the car is low; 4.3 lets the seated avatar fit under the roof).

local rgb = Color3.fromRGB
local M = Enum.Material
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball
local A = CFrame.Angles
local CN = CFrame.new
local V = Vector3.new

local CYLINDER_Z = A(0, math.rad(90), 0)
local CYLINDER_Y = A(0, 0, math.rad(90))

-- Wedge orientations (WedgePart default: right angle at local (ymin, zmax), slope rises to +Z).
local RISE_FRONT = A(0, math.pi, 0) -- slope rises toward -Z, right angle at bottom-front
local FLIP_X = A(math.pi, 0, 0) -- right angle at top-front
local FLIP_Z = A(0, 0, math.pi) -- right angle at top-back
local SIDE_L = A(0, math.pi / 2, 0) -- size (lengthZ, height, widthX), high edge inboard on the left
local SIDE_R = A(0, -math.pi / 2, 0)
-- Plan-view corner chamfers: WedgePart size (H, wX, wZ) maps to world X = wX, Y = H, Z = wZ.
local PLAN_FL = A(0, 0, math.rad(90))
local PLAN_FR = A(0, 0, math.rad(-90))
local PLAN_RL = A(math.pi, 0, 0) * A(0, 0, math.rad(90))
local PLAN_RR = A(math.pi, 0, 0) * A(0, 0, math.rad(-90))

-- Greenhouse angles.
local WINDSHIELD_TILT = A(math.rad(-37.9), 0, 0)
local REAR_WINDOW_TILT = A(math.rad(33.4), 0, 0)
local TUMBLEHOME = 0.296 -- 17 degrees
-- Hood slope: surface y(z) = 3.3 + 0.1 * (z + 9.1).
local HOOD_TILT = A(-0.0997, 0, 0)
local function hoodY(z: number): number
	return 3.3 + 0.1 * (z + 9.1)
end

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

local BLUE = look(rgb(24, 58, 150), nil, 0.12)
local GOLD = look(rgb(200, 160, 60), M.Metal, 0.15)
local TRIM = look(rgb(20, 20, 22))
local POD = look(rgb(16, 16, 18))
local MESH = look(rgb(22, 22, 24), M.DiamondPlate)
local SPLITTER = look(rgb(30, 30, 32))
local SKID_PLATE = look(rgb(70, 70, 75), M.DiamondPlate)
local TYRE = look(rgb(28, 28, 30), M.Fabric)
local TYRE_SHOULDER = look(rgb(36, 36, 38), M.Fabric)
local GLASS = look(rgb(30, 40, 52), M.Glass, 0.15, 0.45)
local HEADLIGHT_GLASS = look(rgb(200, 210, 220), M.Glass, 0.1, 0.35)
local CHROME = look(rgb(190, 190, 195), M.Metal, 0.3)
local NEON_WHITE = look(rgb(255, 244, 214), M.Neon)
local NEON_RED = look(rgb(200, 18, 22), M.Neon)
local NEON_AMBER = look(rgb(255, 140, 20), M.Neon)
local TAIL_GLASS = look(rgb(120, 10, 15), M.Glass, 0.1, 0.2)
local RED = look(rgb(210, 40, 40))
local DISC = look(rgb(110, 110, 115), M.Metal)
local RECESS = look(rgb(35, 30, 20))
local EXHAUST = look(rgb(90, 90, 95), M.Metal)
local BORE = look(rgb(8, 8, 8))
local WHITE = look(rgb(235, 235, 235))
local PLATE_WHITE = look(rgb(230, 230, 230))
local MIRROR_GLASS = look(rgb(170, 180, 190), M.Glass, 0.3)
local INTERIOR = look(rgb(38, 38, 42), M.Fabric)
local DASH = look(rgb(35, 35, 38))
local DOOR_CARD = look(rgb(45, 45, 48))
local FLOOR = look(rgb(28, 28, 30))
local SEAT_FABRIC = look(rgb(30, 45, 120), M.Fabric)
local HARNESS = look(rgb(200, 30, 35), M.Fabric)
local CAGE = look(rgb(165, 165, 170), M.Metal)
local LINER = look(rgb(14, 14, 16))

local AXLES = { -5.5, 5.4 }
local SIDES = { -1, 1 }
local WHEEL_Y = 1.42

local pieces = {}

local function add(
	name: string,
	size: Vector3,
	offset: CFrame,
	style,
	class: string?,
	shape: Enum.PartType?
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

local function wedge(name: string, size: Vector3, offset: CFrame, style)
	add(name, size, offset, style, "WedgePart")
end

local function cyl(name: string, size: Vector3, offset: CFrame, style)
	add(name, size, offset, style, nil, CYL)
end

local function ball(name: string, size: Vector3, offset: CFrame, style)
	add(name, size, offset, style, nil, BALL)
end

----------------------------------------------------------------------------------------------------
-- Body shell
----------------------------------------------------------------------------------------------------

add("TubFront", V(5.2, 2.35, 5.6), CN(0, 2.125, -6.4), BLUE)
add("TubRear", V(5.2, 2.95, 3.3), CN(0, 2.425, 7.55), BLUE)
add("Floor", V(5.2, 0.35, 9.5), CN(0, 1.125, 1.15), FLOOR)
wedge("Hood", V(7.0, 0.55, 5.5), CN(0, 3.575, -6.35), BLUE)
add("TrunkLid", V(7.0, 0.3, 3.1), CN(0, 4.05, 7.65), BLUE)
add("TrunkLidGap", V(5.6, 0.02, 0.05), CN(0, 4.21, 6.35), TRIM)
add("Roof", V(5.3, 0.14, 4.5), CN(0, 5.91, 1.35), BLUE)
add("Cowl", V(5.6, 0.05, 0.25), CN(0, 3.9, -3.62), TRIM)

for _, s in SIDES do
	local x = s * 3.05
	add("SideFrontQuarter", V(0.9, 2.35, 1.95), CN(x, 2.125, -8.125), BLUE)
	add("SideFrontFender", V(0.9, 0.25, 3.3), CN(x, 3.175, -5.5), BLUE)
	add("SideDoors", V(0.9, 2.95, 7.6), CN(x, 2.425, -0.05), BLUE)
	add("SideRearFender", V(0.9, 0.85, 3.3), CN(x, 3.475, 5.4), BLUE)
	add("SideRearQuarter", V(0.9, 2.95, 2.15), CN(x, 2.425, 8.125), BLUE)
	add("Sill", V(0.15, 0.45, 7.2), CN(s * 3.575, 1.2, -0.05), TRIM)

	for _, zA in AXLES do
		wedge("ArchCornerFront", V(0.9, 0.5, 0.5), CN(x, 2.8, zA - 1.4) * FLIP_X, BLUE)
		wedge("ArchCornerRear", V(0.9, 0.5, 0.5), CN(x, 2.8, zA + 1.4) * FLIP_Z, BLUE)
		-- Box flare: top rail, two legs and an inboard bevel onto the panel.
		add("FlareTop", V(0.3, 0.35, 3.9), CN(s * 3.65, 3.2, zA), BLUE)
		add("FlareLeg", V(0.3, 1.6, 0.35), CN(s * 3.65, 2.2, zA - 1.95), BLUE)
		add("FlareLeg", V(0.3, 1.6, 0.35), CN(s * 3.65, 2.2, zA + 1.95), BLUE)
		wedge(
			"FlareBevel",
			V(3.9, 0.3, 0.3),
			CN(s * 3.65, 3.525, zA) * (s < 0 and SIDE_L or SIDE_R),
			BLUE
		)
		-- Black wheel-well liner closes the arch so the cabin does not show through.
		add("ArchLiner", V(0.04, 2.1, 3.3), CN(s * 2.62, 2.0, zA), LINER)
	end

	-- Greenhouse: C-pillar, A-pillar, glass, B-pillar.
	wedge(
		"CPillar",
		V(0.1, 1.95, 2.5),
		CN(s * 3.0, 4.875, 4.85) * RISE_FRONT * A(0, 0, -s * TUMBLEHOME),
		BLUE
	)
	add("APillar", V(0.2, 0.1, 3.42), CN(s * 2.92, 4.97, -2.25) * WINDSHIELD_TILT, TRIM)
	wedge(
		"SideGlassFront",
		V(0.08, 2.1, 2.7),
		CN(s * 3.0, 4.95, -2.25) * A(0, 0, s * TUMBLEHOME),
		GLASS
	)
	add("SideGlass", V(0.08, 2.1, 4.5), CN(s * 3.0, 4.95, 1.35) * A(0, 0, s * TUMBLEHOME), GLASS)
	add("BPillar", V(0.1, 2.0, 0.3), CN(s * 3.02, 4.95, 0.85) * A(0, 0, s * TUMBLEHOME), TRIM)
	add("DripRail", V(0.06, 0.06, 4.6), CN(s * 2.66, 5.86, 1.35), TRIM)
end

-- Belly skid plate under the front.
add("SkidPlate", V(4.6, 0.1, 3.6), CN(0, 0.9, -7.2), SKID_PLATE)
wedge("SkidPlateNose", V(4.6, 0.3, 0.6), CN(0, 0.99, -9.3) * RISE_FRONT, SKID_PLATE)
add("SkidPlateRib", V(0.1, 0.06, 3.4), CN(-1.2, 0.83, -7.2), SKID_PLATE)
add("SkidPlateRib", V(0.1, 0.06, 3.4), CN(1.2, 0.83, -7.2), SKID_PLATE)

----------------------------------------------------------------------------------------------------
-- Hood scoop, vents, pins
----------------------------------------------------------------------------------------------------

add("Scoop", V(2.2, 0.4, 1.6), CN(0, 3.84, -5.4) * HOOD_TILT, BLUE)
add("ScoopOpening", V(1.9, 0.24, 0.03), CN(0, 3.82, -6.22) * HOOD_TILT, POD)
wedge("ScoopFairing", V(2.2, 0.4, 0.8), CN(0, 3.96, -4.2) * HOOD_TILT * RISE_FRONT, BLUE)
for _, s in SIDES do
	add("LouverPlate", V(1.3, 0.03, 0.9), CN(s * 1.95, 3.495, -7.3) * HOOD_TILT, POD)
	for _, z in { -7.6, -7.3, -7.0 } do
		add("LouverSlat", V(1.3, 0.06, 0.1), CN(s * 1.95, 3.52, z) * HOOD_TILT, BLUE)
	end
	cyl(
		"HoodPin",
		V(0.06, 0.16, 0.16),
		CN(s * 2.9, hoodY(-8.4) + 0.02, -8.4) * HOOD_TILT * CYLINDER_Y,
		CHROME
	)
end

----------------------------------------------------------------------------------------------------
-- Front end
----------------------------------------------------------------------------------------------------

add("Bumper", V(5.8, 1.7, 0.4), CN(0, 1.8, -9.3), BLUE)
wedge("BumperCornerFL", V(1.7, 0.6, 0.4), CN(-3.2, 1.8, -9.3) * PLAN_FL, BLUE)
wedge("BumperCornerFR", V(1.7, 0.6, 0.4), CN(3.2, 1.8, -9.3) * PLAN_FR, BLUE)
add("LowerIntake", V(4.4, 0.8, 0.04), CN(0, 1.65, -9.52), MESH)
for _, s in SIDES do
	add("SideIntake", V(1.0, 0.6, 0.04), CN(s * 2.75, 1.7, -9.52), MESH)
end
add("IntakeBar", V(4.4, 0.08, 0.04), CN(0, 1.65, -9.55), BLUE)
add("Splitter", V(6.6, 0.1, 0.5), CN(0, 0.92, -9.4), SPLITTER)
add("Grille", V(2.8, 0.6, 0.04), CN(0, 2.97, -9.27), TRIM)
for i = -2, 2 do
	add("GrilleSlat", V(0.05, 0.5, 0.03), CN(i * 0.5, 2.97, -9.3), SPLITTER)
end
for _, s in SIDES do
	add("HeadlightHousing", V(1.95, 0.6, 0.3), CN(s * 2.45, 2.97, -9.21), HEADLIGHT_GLASS)
	add("HeadlightReflector", V(1.8, 0.5, 0.1), CN(s * 2.45, 2.97, -9.12), CHROME)
	cyl("LowBeam", V(0.04, 0.4, 0.4), CN(s * 2.0, 2.97, -9.33) * CYLINDER_Z, NEON_WHITE)
	cyl("HighBeam", V(0.04, 0.4, 0.4), CN(s * 2.85, 2.97, -9.33) * CYLINDER_Z, NEON_WHITE)
	add("Indicator", V(0.35, 0.18, 0.04), CN(s * 3.25, 2.75, -9.33), NEON_AMBER)
	add("SideRepeater", V(0.04, 0.12, 0.3), CN(s * 3.52, 2.9, -7.6), NEON_AMBER)
end
add("TowStrapFront", V(0.15, 0.4, 0.06), CN(1.9, 1.15, -9.54), RED)

----------------------------------------------------------------------------------------------------
-- Light pod: four round lamps across the nose
----------------------------------------------------------------------------------------------------

add("PodPanel", V(5.0, 1.05, 0.35), CN(0, 3.55, -9.375), POD)
wedge("PodFairing", V(5.0, 0.7, 0.9), CN(0, 3.65, -8.75) * RISE_FRONT, POD)
for _, x in { -1.875, -0.625, 0.625, 1.875 } do
	cyl("LampBezel", V(0.12, 0.9, 0.9), CN(x, 3.55, -9.6) * CYLINDER_Z, CHROME)
	cyl("LampLens", V(0.04, 0.76, 0.76), CN(x, 3.55, -9.68) * CYLINDER_Z, NEON_WHITE)
end

----------------------------------------------------------------------------------------------------
-- Glass and roof
----------------------------------------------------------------------------------------------------

local windshieldCF = CN(0, 4.95, -2.25) * WINDSHIELD_TILT
add("Windshield", V(5.8, 0.08, 3.42), windshieldCF, GLASS)
add("WindshieldBanner", V(5.6, 0.04, 0.7), windshieldCF * CN(0, 0.065, 1.3), POD)
add(
	"WiperLeft",
	V(2.2, 0.05, 0.08),
	windshieldCF * CN(-1.4, 0.07, -1.45) * A(0, math.rad(8), 0),
	TRIM
)
add(
	"WiperRight",
	V(2.2, 0.05, 0.08),
	windshieldCF * CN(1.0, 0.07, -1.45) * A(0, math.rad(8), 0),
	TRIM
)
add("RearWindow", V(5.4, 0.08, 3.0), CN(0, 5.025, 4.85) * REAR_WINDOW_TILT, GLASS)
local rearWindowCF = CN(0, 5.025, 4.85) * REAR_WINDOW_TILT
for _, s in SIDES do
	-- Sloped C-pillar skin that frames the rear window edge.
	add("RearWindowFrame", V(0.45, 0.1, 3.0), rearWindowCF * CN(s * 2.55, 0.05, 0), BLUE)
end
add("RearWindowSeal", V(4.7, 0.1, 0.12), rearWindowCF * CN(0, 0.05, -1.44), TRIM)
add("ParcelShelf", V(5.2, 0.1, 1.2), CN(0, 4.05, 5.5), INTERIOR)

add("RoofVentBody", V(1.3, 0.28, 0.9), CN(0, 6.12, -0.25), BLUE)
add("RoofVentOpening", V(1.1, 0.18, 0.03), CN(0, 6.12, -0.715), POD)
wedge("RoofVentTail", V(1.3, 0.28, 0.6), CN(0, 6.12, 0.5) * RISE_FRONT, BLUE)
add("Antenna", V(0.05, 0.8, 0.05), CN(0.8, 6.38, 3.0), TRIM)
add("AntennaBase", V(0.2, 0.06, 0.3), CN(0.8, 6.01, 3.0), TRIM)

----------------------------------------------------------------------------------------------------
-- Rear
----------------------------------------------------------------------------------------------------

add("RearBumper", V(5.8, 1.7, 0.4), CN(0, 1.8, 9.3), BLUE)
wedge("RearCornerRL", V(1.7, 0.6, 0.4), CN(-3.2, 1.8, 9.3) * PLAN_RL, BLUE)
wedge("RearCornerRR", V(1.7, 0.6, 0.4), CN(3.2, 1.8, 9.3) * PLAN_RR, BLUE)
add("Diffuser", V(5.0, 0.3, 0.6), CN(0, 1.05, 9.25), TRIM)
for i = -2, 2 do
	add("DiffuserFin", V(0.06, 0.3, 0.5), CN(i * 0.8 - 0.3, 0.95, 9.35), TRIM)
end
add("BumperGap", V(5.6, 0.04, 0.02), CN(0, 2.67, 9.505), TRIM)
for _, s in SIDES do
	add("TailHousing", V(1.6, 0.7, 0.05), CN(s * 2.65, 3.45, 9.225), TAIL_GLASS)
	add("TailLamp", V(0.9, 0.3, 0.03), CN(s * 2.75, 3.45, 9.265), NEON_RED)
	add("RearIndicator", V(0.4, 0.25, 0.03), CN(s * 2.15, 3.45, 9.265), NEON_AMBER)
	add("Reverse", V(0.3, 0.2, 0.03), CN(s * 3.2, 3.45, 9.265), NEON_WHITE)
	add("RearReflector", V(0.4, 0.12, 0.03), CN(s * 2.4, 2.3, 9.515), NEON_RED)
end
add("Plate", V(2.0, 0.6, 0.03), CN(0, 3.3, 9.215), PLATE_WHITE)
add("PlateLamp", V(0.6, 0.06, 0.1), CN(0, 3.65, 9.22), CHROME)
cyl("ExhaustTip", V(0.8, 0.55, 0.55), CN(2.0, 1.15, 9.3) * CYLINDER_Z, EXHAUST)
cyl("ExhaustBore", V(0.03, 0.42, 0.42), CN(2.0, 1.15, 9.715) * CYLINDER_Z, BORE)
add("TowStrapRear", V(0.15, 0.4, 0.06), CN(-2.0, 1.2, 9.53), RED)

----------------------------------------------------------------------------------------------------
-- Rear wing
----------------------------------------------------------------------------------------------------

add("WingMainPlane", V(6.6, 0.16, 1.3), CN(0, 5.45, 8.4) * A(math.rad(-6), 0, 0), BLUE)
cyl("WingLeadingEdge", V(6.6, 0.18, 0.18), CN(0, 5.38, 7.76), BLUE)
add("WingGurney", V(6.6, 0.16, 0.06), CN(0, 5.6, 9.03), TRIM)
for _, s in SIDES do
	add("WingEndPlate", V(0.08, 1.1, 1.6), CN(s * 3.34, 5.3, 8.4), BLUE)
	add("WingPylon", V(0.15, 1.2, 0.6), CN(s * 1.6, 4.8, 8.3), BLUE)
	add("WingPylonFoot", V(0.4, 0.05, 0.8), CN(s * 1.6, 4.225, 8.3), TRIM)
end

----------------------------------------------------------------------------------------------------
-- Wheels
----------------------------------------------------------------------------------------------------

for _, s in SIDES do
	local function wx(x: number): number
		return s * x
	end
	for _, zA in AXLES do
		local hub = CN(wx(3.27), WHEEL_Y, zA)
		cyl("Tyre", V(1.0, 2.84, 2.84), hub, TYRE)
		cyl("TyreShoulder", V(0.03, 2.6, 2.6), CN(wx(3.785), WHEEL_Y, zA), TYRE_SHOULDER)
		cyl("RimLip", V(0.06, 1.95, 1.95), CN(wx(3.8), WHEEL_Y, zA), GOLD)
		cyl("Recess", V(0.06, 1.75, 1.75), CN(wx(3.82), WHEEL_Y, zA), RECESS)
		cyl("BrakeDisc", V(0.02, 1.5, 1.5), CN(wx(3.85), WHEEL_Y, zA), DISC)
		add(
			"Caliper",
			V(0.06, 0.45, 0.3),
			CN(wx(3.87), WHEEL_Y, zA) * A(math.rad(30), 0, 0) * CN(0, 0, 0.7),
			RED
		)
		for k = 0, 5 do
			add(
				"Spoke",
				V(0.06, 0.18, 0.75),
				CN(wx(3.88), WHEEL_Y, zA) * A(k * math.pi / 3, 0, 0) * CN(0, 0, 0.58),
				GOLD
			)
		end
		cyl("Hub", V(0.1, 0.55, 0.55), CN(wx(3.91), WHEEL_Y, zA), GOLD)
		cyl("CenterNut", V(0.08, 0.25, 0.25), CN(wx(3.97), WHEEL_Y, zA), CHROME)

		-- Mud flap behind the wheel: white with a black bottom edge.
		add("MudFlap", V(0.95, 1.3, 0.06), CN(s * 3.15, 0.85, zA + 1.75), WHITE)
		add("MudFlapEdge", V(0.99, 0.16, 0.1), CN(s * 3.15, 0.27, zA + 1.75), TRIM)
	end
end

----------------------------------------------------------------------------------------------------
-- Side details
----------------------------------------------------------------------------------------------------

for _, s in SIDES do
	for _, z in { -3.7, 0.85, 3.6 } do
		add("DoorGap", V(0.02, 2.6, 0.05), CN(s * 3.51, 2.4, z), TRIM)
	end
	for _, z in { 0.3, 3.0 } do
		add("Handle", V(0.04, 0.12, 0.45), CN(s * 3.52, 3.45, z), TRIM)
	end
	add("MirrorHousing", V(0.6, 0.45, 0.35), CN(s * 3.75, 4.15, -2.9), BLUE)
	add("MirrorStalk", V(0.3, 0.1, 0.15), CN(s * 3.4, 4.0, -2.95), BLUE)
	add("MirrorGlass", V(0.5, 0.35, 0.03), CN(s * 3.75, 4.15, -2.71), MIRROR_GLASS)
	add("NumberPlate", V(0.03, 0.9, 1.4), CN(s * 3.52, 2.9, -1.6), WHITE)
	add("NumberPlateBorder", V(0.02, 0.06, 1.4), CN(s * 3.54, 2.48, -1.6), TRIM)
	add("BeltStrip", V(0.25, 0.06, 7.4), CN(s * 3.35, 3.93, 0), TRIM)
end
cyl("FuelCap", V(0.04, 0.45, 0.45), CN(3.52, 3.4, 6.2), TRIM)

----------------------------------------------------------------------------------------------------
-- Interior
----------------------------------------------------------------------------------------------------

add("Firewall", V(5.2, 2.55, 0.2), CN(0, 2.575, -3.5), INTERIOR)
add("Dash", V(5.2, 0.7, 1.4), CN(0, 3.45, -2.9), DASH)
add("GaugePod", V(1.0, 0.3, 0.3), CN(-1.35, 3.9, -2.3), TRIM)
add("CenterConsole", V(0.9, 0.9, 0.2), CN(0, 3.0, -2.15), TRIM)
add("Tunnel", V(0.6, 0.5, 4.5), CN(0, 1.55, -0.9), TRIM)
add("Shifter", V(0.08, 0.7, 0.08), CN(0, 2.0, -1.0), CHROME)
ball("ShifterKnob", V(0.2, 0.2, 0.2), CN(0, 2.4, -1.0), TRIM)
add("Handbrake", V(0.1, 0.9, 0.1), CN(0, 2.1, 0.0), CHROME)
ball("HandbrakeKnob", V(0.2, 0.2, 0.2), CN(0, 2.6, 0.0), TRIM)

local steeringCF = CN(-1.35, 3.3, -0.55) * A(math.rad(-25), 0, 0)
cyl("SteeringRim", V(0.12, 1.3, 1.3), steeringCF * CYLINDER_Z, TRIM)
cyl("SteeringPad", V(0.16, 0.4, 0.4), steeringCF * CYLINDER_Z, BLUE)
add("SteeringColumn", V(0.15, 0.15, 1.2), CN(-1.35, 3.5, -1.2) * A(math.rad(-25), 0, 0), TRIM)

for _, s in SIDES do
	local sx = s * 1.35
	add("DoorPanel", V(0.05, 1.5, 7.2), CN(s * 2.57, 2.6, 0), DOOR_CARD)
	add("SeatCushion", V(1.8, 0.3, 1.9), CN(sx, 1.25, 1.0), SEAT_FABRIC)
	add("SeatBack", V(1.8, 3.2, 0.35), CN(sx, 3.0, 1.825), SEAT_FABRIC)
	add("SeatBolster", V(0.2, 2.4, 0.6), CN(sx - 1.1, 2.6, 1.55), SEAT_FABRIC)
	add("SeatBolster", V(0.2, 2.4, 0.6), CN(sx + 1.1, 2.6, 1.55), SEAT_FABRIC)
	add("HarnessLeft", V(0.18, 0.04, 1.4), CN(sx - 0.45, 4.45, 2.4), HARNESS)
	add("HarnessRight", V(0.18, 0.04, 1.4), CN(sx + 0.45, 4.45, 2.4), HARNESS)
end

-- Roll cage.
for _, s in SIDES do
	cyl("CageHoopPost", V(4.4, 0.15, 0.15), CN(s * 2.45, 3.55, 2.3) * CYLINDER_Y, CAGE)
	add("CageRoofBar", V(0.15, 0.15, 3.2), CN(s * 2.45, 5.7, 0.7), CAGE)
	add("CageAPillar", V(0.15, 0.15, 3.0), CN(s * 2.45, 4.8, -2.1) * A(math.rad(-36.9), 0, 0), CAGE)
	add("CageRearStay", V(0.15, 0.15, 3.9), CN(s * 2.3, 4.75, 4.05) * A(math.rad(25.9), 0, 0), CAGE)
end
add("CageHoopTop", V(4.9, 0.15, 0.15), CN(0, 5.7, 2.3), CAGE)
add("CageDiagonal", V(6.52, 0.15, 0.15), CN(0, 3.55, 2.3) * A(0, 0, math.rad(41.3)), CAGE)
add("CageHarnessBar", V(4.9, 0.12, 0.12), CN(0, 4.4, 2.3), CAGE)

return {
	name = "Rally Car",
	-- Real: 205 km/h, 0-100 km/h in 3.3 s, brakes 1.2 g, coasts 0.25 g (VehicleDefaults maps them).
	speed = 73,
	acceleration = 15.2,
	braking = 19,
	coasting = 6.7,
	turnRate = 2.7,
	footprint = Vector2.new(7.4, 18.6),
	collision = {
		{ size = V(7.4, 2.6, 18.6), offset = CN(0, 2.5, 0) }, -- y 1.2..3.8
		{ size = V(5.4, 2.1, 4.6), offset = CN(0, 4.85, 1.35) }, -- cabin, y 3.8..5.9
	},
	-- Left-hand drive: driver on the left. Seat tops at y 1.4.
	seats = { CN(-1.35, 0.9, 1.0), CN(1.35, 0.9, 1.0) },
	pieces = pieces,
}
