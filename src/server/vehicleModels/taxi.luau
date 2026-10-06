-- NYC Taxi: Ford Crown Victoria LWB, taxi yellow with checker band and roof ad topper.
-- Scale: 4 studs = 1 m. Front axle z -6.9, rear axle z 5.4, track 6.5, P225/60R16 tires.

local rgb = Color3.fromRGB
local M = Enum.Material
local A = CFrame.Angles
local CYL = Enum.PartType.Cylinder
local CYLINDER_Z = A(0, math.rad(90), 0) -- cylinder axis along Z
local CYLINDER_Y = A(0, 0, math.rad(90)) -- cylinder axis along Y
-- WedgePart default: full bottom and full back (+Z) faces, slope rising toward +Z.
local FLIP_X = A(math.pi, 0, 0) -- right angle at (ymax, zmin)
local FLIP_Z = A(0, 0, math.pi) -- right angle at (ymax, zmax)
local REV = A(0, math.pi, 0) -- slope rises toward -Z

local TAXI = rgb(246, 182, 16)
local TAXI_DARK = rgb(222, 160, 10)
local CHECKER_BLACK = rgb(18, 18, 20)
local TRIM_BLACK = rgb(25, 25, 27)
local UNDER = rgb(22, 22, 22)
local CHROME = rgb(205, 208, 212)
local GLASS = rgb(38, 50, 58)
local PLEXI = rgb(200, 215, 220)
local TIRE = rgb(30, 30, 32)
local RIM_STEEL = rgb(60, 62, 66)
local HUBCAP = rgb(188, 191, 196)
local HEADLAMP = rgb(255, 244, 214)
local AMBER = rgb(255, 150, 30)
local TAIL_RED = rgb(200, 20, 20)
local REVERSE = rgb(235, 235, 235)
local INTERIOR = rgb(48, 49, 52)
local SEAT = rgb(40, 40, 43)
local GAUGE = rgb(90, 160, 220)
local METER_RED = rgb(255, 40, 30)
local TV_BLUE = rgb(60, 110, 190)
local PLATE = rgb(230, 232, 228)
local EMBLEM_BLUE = rgb(20, 40, 110)
local TOPPER_WHITE = rgb(240, 240, 236)
local AD_RED = rgb(200, 30, 40)
local AD_BLUE = rgb(30, 60, 150)
local AD_YELLOW = rgb(250, 210, 40)
local TAXI_LAMP = rgb(255, 226, 150)

local PAINT_REFLECT = 0.1
local GLASS_ALPHA = 0.45
local CHROME_REFLECT = 0.35
local TUMBLE = math.rad(16.7)

local FRONT_AXLE = -6.9
local REAR_AXLE = 5.4
local WHEEL_X = 3.25
local WHEEL_Y = 1.35

local pieces = {}
local function add(spec)
	table.insert(pieces, spec)
end

local function mirror(fn)
	fn(-1)
	fn(1)
end

-- Side tilt: tops lean inward (tumblehome).
local function tilt(s)
	return A(0, 0, s * TUMBLE)
end

local function paint(name, size, offset, class)
	add({
		name = name,
		class = class,
		size = size,
		offset = offset,
		color = TAXI,
		material = M.SmoothPlastic,
		reflectance = PAINT_REFLECT,
	})
end

local function part(name, size, offset, color, material, extra)
	local spec = { name = name, size = size, offset = offset, color = color, material = material }
	if extra then
		for k, v in extra do
			spec[k] = v
		end
	end
	add(spec)
end

local function chrome(name, size, offset)
	part(name, size, offset, CHROME, M.Metal, { reflectance = CHROME_REFLECT })
end

local function glass(name, size, offset, class)
	add({
		name = name,
		class = class,
		size = size,
		offset = offset,
		color = GLASS,
		material = M.Glass,
		transparency = GLASS_ALPHA,
		reflectance = 0.1,
	})
end

local function neon(name, size, offset, color)
	part(name, size, offset, color, M.Neon)
end

---------------------------------------------------------------------------------------------------
-- Body core and shell
---------------------------------------------------------------------------------------------------
part("CoreFront", Vector3.new(5.5, 2.58, 6.1), CFrame.new(0, 2.09, -7.35), UNDER, M.SmoothPlastic)
part("CabinFloor", Vector3.new(5.5, 0.6, 8.9), CFrame.new(0, 1.1, 0.15), INTERIOR, M.Fabric)
part("CoreRear", Vector3.new(5.5, 3.04, 6.05), CFrame.new(0, 2.32, 7.625), UNDER, M.SmoothPlastic)
part("Underbody", Vector3.new(5.4, 0.25, 20), CFrame.new(0, 0.675, 0), UNDER, M.SmoothPlastic)

paint("Hood", Vector3.new(7.3, 0.12, 6.1), CFrame.new(0, 3.44, -7.35))
paint("HoodNose", Vector3.new(7.3, 0.25, 0.25), CFrame.new(0, 3.375, -10.525), "WedgePart")
paint("FrontFascia", Vector3.new(7.8, 1.1, 0.3), CFrame.new(0, 2.7, -10.8))
paint("RearPanel", Vector3.new(7.8, 1.5, 0.3), CFrame.new(0, 2.9, 10.8))
paint("TrunkDeck", Vector3.new(7.3, 0.12, 3.2), CFrame.new(0, 3.9, 9.0))
paint("TrunkDrop", Vector3.new(7.3, 0.3, 0.35), CFrame.new(0, 3.81, 10.775) * REV, "WedgePart")
paint("Roof", Vector3.new(6.3, 0.15, 5.9), CFrame.new(0, 5.88, 1.65))
paint("FrontBumper", Vector3.new(7.1, 1.0, 0.5), CFrame.new(0, 1.65, -10.85))
paint("RearBumper", Vector3.new(7.1, 1.0, 0.5), CFrame.new(0, 1.65, 10.85))

local CORNER = Vector3.new(1.0, 0.4, 0.5)
paint("BumperCornerFL", CORNER, CFrame.new(-3.75, 1.65, -10.85) * A(0, 0, math.pi / 2), "WedgePart")
paint("BumperCornerFR", CORNER, CFrame.new(3.75, 1.65, -10.85) * A(0, 0, -math.pi / 2), "WedgePart")
paint(
	"BumperCornerRR",
	CORNER,
	CFrame.new(3.75, 1.65, 10.85) * REV * A(0, 0, math.pi / 2),
	"WedgePart"
)
paint(
	"BumperCornerRL",
	CORNER,
	CFrame.new(-3.75, 1.65, 10.85) * REV * A(0, 0, -math.pi / 2),
	"WedgePart"
)

part("Cowl", Vector3.new(6.6, 0.12, 0.5), CFrame.new(0, 3.56, -4.3), TRIM_BLACK, M.Plastic)
part("PackageShelf", Vector3.new(7.2, 0.1, 2.8), CFrame.new(0, 3.89, 6.0), INTERIOR, M.Fabric)

local ARCHES = { { -8.55, -5.25 }, { 3.75, 7.05 } }

mirror(function(s)
	paint("SideFront", Vector3.new(1.2, 2.38, 2.1), CFrame.new(s * 3.35, 2.19, -9.6))
	paint("FenderTop", Vector3.new(0.3, 0.37, 1.75), CFrame.new(s * 3.8, 3.565, -9.425))
	paint(
		"FenderTopNose",
		Vector3.new(0.3, 0.37, 0.35),
		CFrame.new(s * 3.8, 3.565, -10.475),
		"WedgePart"
	)
	paint("SideOverFrontWheel", Vector3.new(0.3, 0.8, 3.3), CFrame.new(s * 3.8, 3.35, FRONT_AXLE))
	paint("SideMid", Vector3.new(0.3, 2.95, 9.0), CFrame.new(s * 3.8, 2.275, -0.75))
	paint("SideOverRearWheel", Vector3.new(0.3, 0.9, 3.3), CFrame.new(s * 3.8, 3.4, REAR_AXLE))
	paint("SideRear", Vector3.new(1.2, 2.9, 3.6), CFrame.new(s * 3.35, 2.45, 8.85))
	for _, arch in ARCHES do
		local size = Vector3.new(0.3, 0.7, 0.7)
		paint("ArchChamfer", size, CFrame.new(s * 3.8, 2.6, arch[1] + 0.35) * FLIP_X, "WedgePart")
		paint("ArchChamfer", size, CFrame.new(s * 3.8, 2.6, arch[2] - 0.35) * FLIP_Z, "WedgePart")
	end
	part(
		"DoorPanelInner",
		Vector3.new(0.9, 2.3, 8.9),
		CFrame.new(s * 3.2, 2.55, 0.15),
		INTERIOR,
		M.Fabric
	)
	-- A-pillar follows both the windshield rake and the side tumblehome.
	local aBase = Vector3.new(s * 3.45, 3.68, -4.3)
	local aTop = Vector3.new(s * 3.0, 5.9, -1.3)
	local d = aTop - aBase
	local pitch = math.atan2(-math.sqrt(d.X * d.X + d.Y * d.Y), d.Z)
	local roll = math.atan2(-d.X, d.Y)
	paint(
		"APillar",
		Vector3.new(0.5, 0.14, d.Magnitude),
		CFrame.new((aBase + aTop) / 2) * A(0, 0, roll) * A(pitch, 0, 0)
	)
	part(
		"BPillar",
		Vector3.new(0.14, 2.0, 0.4),
		CFrame.new(s * 3.48, 4.8, 0.0) * tilt(s),
		TRIM_BLACK,
		M.Plastic
	)
	paint("CPillarRect", Vector3.new(0.2, 2.0, 0.8), CFrame.new(s * 3.47, 4.8, 4.2) * tilt(s))
	paint(
		"CPillarSlope",
		Vector3.new(0.2, 1.95, 2.8),
		CFrame.new(s * 3.47, 4.825, 6.0) * tilt(s) * REV,
		"WedgePart"
	)
	part(
		"DripRail",
		Vector3.new(0.08, 0.08, 5.9),
		CFrame.new(s * 3.17, 5.84, 1.65),
		TRIM_BLACK,
		M.Plastic
	)
end)

---------------------------------------------------------------------------------------------------
-- Checker band, panel lines, belt moldings
---------------------------------------------------------------------------------------------------
mirror(function(s)
	for i = 0, 28 do
		local z = -3.9 + i * 0.3
		local y = (i % 2 == 0) and 2.9 or 3.2
		part(
			"Checker",
			Vector3.new(0.04, 0.3, 0.3),
			CFrame.new(s * 3.975, y, z),
			CHECKER_BLACK,
			M.SmoothPlastic
		)
	end
	for _, z in { -4.1, 0.0, 4.4 } do
		part(
			"DoorGap",
			Vector3.new(0.03, 2.9, 0.04),
			CFrame.new(s * 3.965, 2.3, z),
			TRIM_BLACK,
			M.Plastic
		)
	end
	-- Black body-side molding, broken at the wheel arches.
	for _, seg in { { -10.5, -8.7 }, { -5.1, 3.6 }, { 7.2, 10.5 } } do
		part(
			"SideMolding",
			Vector3.new(0.05, 0.18, seg[2] - seg[1]),
			CFrame.new(s * 3.975, 2.2, (seg[1] + seg[2]) / 2),
			TRIM_BLACK,
			M.Plastic
		)
	end
	part(
		"BeltMolding",
		Vector3.new(0.3, 0.05, 8.7),
		CFrame.new(s * 3.8, 3.775, 0.15),
		TRIM_BLACK,
		M.Plastic
	)
end)
part(
	"TrunkShutLine",
	Vector3.new(7.0, 0.03, 0.04),
	CFrame.new(0, 3.97, 7.45),
	TRIM_BLACK,
	M.Plastic
)
part(
	"FuelDoor",
	Vector3.new(0.03, 0.5, 0.5),
	CFrame.new(-3.965, 3.3, 6.3),
	TAXI_DARK,
	M.SmoothPlastic
)

---------------------------------------------------------------------------------------------------
-- Glass
---------------------------------------------------------------------------------------------------
glass(
	"Windshield",
	Vector3.new(6.5, 0.08, 3.8),
	CFrame.new(0, 4.775, -2.8) * A(math.rad(-36.9), 0, 0)
)
glass("Backlight", Vector3.new(5.9, 0.08, 3.5), CFrame.new(0, 4.88, 6.0) * A(math.rad(36.2), 0, 0))
mirror(function(s)
	glass(
		"FrontDoorGlassSlope",
		Vector3.new(0.08, 2.0, 2.6),
		CFrame.new(s * 3.45, 4.8, -2.7) * tilt(s),
		"WedgePart"
	)
	glass("FrontDoorGlass", Vector3.new(0.08, 2.0, 1.2), CFrame.new(s * 3.45, 4.8, -0.8) * tilt(s))
	glass("RearDoorGlass", Vector3.new(0.08, 2.0, 3.6), CFrame.new(s * 3.45, 4.8, 2.0) * tilt(s))
end)

---------------------------------------------------------------------------------------------------
-- Front lights and grille
---------------------------------------------------------------------------------------------------
mirror(function(s)
	chrome("HeadlampHousing", Vector3.new(2.1, 0.6, 0.06), CFrame.new(s * 2.6, 2.95, -10.97))
	neon("HeadlampLens", Vector3.new(1.0, 0.4, 0.02), CFrame.new(s * 2.25, 2.95, -11.02), HEADLAMP)
	neon("ParkTurn", Vector3.new(0.6, 0.35, 0.03), CFrame.new(s * 3.3, 2.95, -11.02), AMBER)
	neon("SideMarkerFront", Vector3.new(0.03, 0.3, 0.6), CFrame.new(s * 3.97, 2.95, -10.35), AMBER)
	chrome("GrilleSide", Vector3.new(0.1, 0.75, 0.06), CFrame.new(s * 1.35, 2.875, -10.98))
	part(
		"FrontRubStrip",
		Vector3.new(2.6, 0.2, 0.04),
		CFrame.new(s * 2.3, 1.75, -11.12),
		TRIM_BLACK,
		M.Plastic
	)
end)
chrome("GrilleTop", Vector3.new(2.8, 0.1, 0.06), CFrame.new(0, 3.2, -10.98))
chrome("GrilleBottom", Vector3.new(2.8, 0.1, 0.06), CFrame.new(0, 2.55, -10.98))
part(
	"GrilleInsert",
	Vector3.new(2.6, 0.6, 0.03),
	CFrame.new(0, 2.875, -10.965),
	TRIM_BLACK,
	M.Plastic
)
for k = 0, 6 do
	chrome("GrilleSlat", Vector3.new(0.06, 0.55, 0.04), CFrame.new(-0.9 + k * 0.3, 2.875, -10.99))
end
chrome("EmblemRing", Vector3.new(0.56, 0.3, 0.03), CFrame.new(0, 2.875, -11.005))
part(
	"Emblem",
	Vector3.new(0.5, 0.24, 0.04),
	CFrame.new(0, 2.875, -11.02),
	EMBLEM_BLUE,
	M.SmoothPlastic
)
part("LowerIntake", Vector3.new(3.0, 0.25, 0.04), CFrame.new(0, 1.3, -11.12), TRIM_BLACK, M.Plastic)
part(
	"FrontPlateFrame",
	Vector3.new(1.3, 0.7, 0.03),
	CFrame.new(0, 1.7, -11.115),
	TRIM_BLACK,
	M.Plastic
)
part("FrontPlate", Vector3.new(1.2, 0.6, 0.03), CFrame.new(0, 1.7, -11.135), PLATE, M.SmoothPlastic)

---------------------------------------------------------------------------------------------------
-- Rear lights and trim
---------------------------------------------------------------------------------------------------
mirror(function(s)
	neon("TailLamp", Vector3.new(1.6, 0.75, 0.04), CFrame.new(s * 3.05, 3.22, 10.97), TAIL_RED)
	neon("TailWrap", Vector3.new(0.04, 0.75, 0.55), CFrame.new(s * 3.97, 3.22, 10.6), TAIL_RED)
	part(
		"Reverse",
		Vector3.new(0.4, 0.35, 0.04),
		CFrame.new(s * 2.05, 3.22, 10.97),
		REVERSE,
		M.SmoothPlastic
	)
	neon("SideMarkerRear", Vector3.new(0.03, 0.25, 0.5), CFrame.new(s * 3.97, 2.6, 10.3), TAIL_RED)
	part(
		"RearRubStrip",
		Vector3.new(2.6, 0.2, 0.04),
		CFrame.new(s * 2.3, 1.75, 11.12),
		TRIM_BLACK,
		M.Plastic
	)
end)
neon("CHMSL", Vector3.new(1.0, 0.1, 0.1), CFrame.new(0, 3.94, 6.9), TAIL_RED)
chrome("TrunkChromeStrip", Vector3.new(3.6, 0.08, 0.04), CFrame.new(0, 3.5, 10.97))
chrome("RearEmblem", Vector3.new(0.4, 0.18, 0.03), CFrame.new(0, 3.3, 10.965))
part(
	"RearPlateFrame",
	Vector3.new(1.3, 0.7, 0.03),
	CFrame.new(0, 2.85, 10.965),
	TRIM_BLACK,
	M.Plastic
)
part("RearPlate", Vector3.new(1.2, 0.6, 0.03), CFrame.new(0, 2.85, 10.985), PLATE, M.SmoothPlastic)

---------------------------------------------------------------------------------------------------
-- Wheels: black tire, steel rim edge, full silver hubcap with vent slots
---------------------------------------------------------------------------------------------------
local function wheel(x, z)
	local s = x < 0 and -1 or 1
	local function disc(name, width, dia, ox, color, material, reflectance)
		add({
			name = name,
			shape = CYL,
			size = Vector3.new(width, dia, dia),
			offset = CFrame.new(s * ox, WHEEL_Y, z),
			color = color,
			material = material,
			reflectance = reflectance,
		})
	end
	disc("Tire", 0.9, 2.7, math.abs(x), TIRE, M.SmoothPlastic)
	disc("SteelRimRing", 0.06, 1.95, 3.69, RIM_STEEL, M.Metal)
	disc("Hubcap", 0.08, 1.8, 3.74, HUBCAP, M.Metal, 0.2)
	disc("HubDome", 0.10, 0.8, 3.80, HUBCAP, M.Metal, 0.2)
	disc("CenterCap", 0.06, 0.35, 3.87, CHROME, M.Metal, CHROME_REFLECT)
	for k = 0, 5 do
		part(
			"HubcapVent",
			Vector3.new(0.03, 0.45, 0.16),
			CFrame.new(s * 3.79, WHEEL_Y, z) * A(math.rad(k * 60), 0, 0) * CFrame.new(0, 0.6, 0),
			TRIM_BLACK,
			M.Plastic
		)
	end
end

mirror(function(s)
	wheel(s * WHEEL_X, FRONT_AXLE)
	wheel(s * WHEEL_X, REAR_AXLE)
end)

---------------------------------------------------------------------------------------------------
-- Roof ad topper
---------------------------------------------------------------------------------------------------
part("TopperFoot", Vector3.new(0.9, 0.12, 0.5), CFrame.new(0, 6.015, 0.4), TRIM_BLACK, M.Plastic)
part("TopperFoot", Vector3.new(0.9, 0.12, 0.5), CFrame.new(0, 6.015, 2.8), TRIM_BLACK, M.Plastic)
part("TopperBody", Vector3.new(0.8, 1.2, 4.0), CFrame.new(0, 6.675, 1.6), TRIM_BLACK, M.Plastic)
for _, z in { -0.4, 3.6 } do
	part(
		"TopperEndCap",
		Vector3.new(1.2, 0.8, 0.8),
		CFrame.new(0, 6.675, z) * CYLINDER_Y,
		TRIM_BLACK,
		M.Plastic,
		{ shape = CYL }
	)
end
mirror(function(s)
	part(
		"AdFace",
		Vector3.new(0.04, 1.0, 3.6),
		CFrame.new(s * 0.42, 6.675, 1.6),
		TOPPER_WHITE,
		M.SmoothPlastic
	)
	part(
		"AdRedBand",
		Vector3.new(0.03, 0.35, 3.2),
		CFrame.new(s * 0.455, 6.9, 1.6),
		AD_RED,
		M.SmoothPlastic
	)
	part(
		"AdBlueBlock",
		Vector3.new(0.03, 0.3, 1.4),
		CFrame.new(s * 0.455, 6.45, 0.9),
		AD_BLUE,
		M.SmoothPlastic
	)
	part(
		"AdYellowBlock",
		Vector3.new(0.03, 0.3, 1.2),
		CFrame.new(s * 0.455, 6.45, 2.5),
		AD_YELLOW,
		M.SmoothPlastic
	)
end)
chrome("TopperRail", Vector3.new(0.85, 0.06, 4.0), CFrame.new(0, 7.3, 1.6))
neon("TaxiLampFront", Vector3.new(0.55, 0.4, 0.06), CFrame.new(0, 6.7, -0.82), TAXI_LAMP)
neon("TaxiLampRear", Vector3.new(0.55, 0.4, 0.06), CFrame.new(0, 6.7, 4.02), TAXI_LAMP)

---------------------------------------------------------------------------------------------------
-- Interior
---------------------------------------------------------------------------------------------------
local WHEEL_CF = CFrame.new(-1.55, 3.6, -2.2) * A(math.rad(25), 0, 0) * CYLINDER_Z

part("Dash", Vector3.new(7.0, 0.75, 1.4), CFrame.new(0, 3.275, -3.6), INTERIOR, M.Fabric)
part("ClusterHood", Vector3.new(1.4, 0.25, 0.5), CFrame.new(-1.55, 3.77, -3.3), INTERIOR, M.Fabric)
neon("Gauges", Vector3.new(1.1, 0.3, 0.02), CFrame.new(-1.55, 3.55, -3.0), GAUGE)
part("SteeringWheel", Vector3.new(0.12, 1.4, 1.4), WHEEL_CF, TRIM_BLACK, M.Plastic, { shape = CYL })
part("SteeringHub", Vector3.new(0.16, 0.45, 0.45), WHEEL_CF, INTERIOR, M.Fabric, { shape = CYL })
part(
	"SteeringColumn",
	Vector3.new(0.25, 0.25, 0.9),
	CFrame.new(-1.55, 3.35, -2.75) * A(math.rad(25), 0, 0),
	TRIM_BLACK,
	M.Plastic
)
part("Meter", Vector3.new(0.8, 0.3, 0.4), CFrame.new(0.3, 3.8, -3.3), TRIM_BLACK, M.Plastic)
neon("MeterDisplay", Vector3.new(0.5, 0.1, 0.02), CFrame.new(0.3, 3.82, -3.09), METER_RED)
part("Console", Vector3.new(0.8, 0.8, 1.6), CFrame.new(0, 1.8, -2.0), INTERIOR, M.Fabric)
mirror(function(s)
	part(
		"FrontCushion",
		Vector3.new(2.0, 0.35, 1.5),
		CFrame.new(s * 1.55, 1.575, -0.75),
		SEAT,
		M.Fabric
	)
	part(
		"FrontBack",
		Vector3.new(2.0, 2.3, 0.35),
		CFrame.new(s * 1.55, 2.9, 0.35) * A(math.rad(8), 0, 0),
		SEAT,
		M.Fabric
	)
	part(
		"FrontHeadrest",
		Vector3.new(1.1, 0.6, 0.3),
		CFrame.new(s * 1.55, 4.55, 0.55) * A(math.rad(8), 0, 0),
		SEAT,
		M.Fabric
	)
	part(
		"RearHeadrest",
		Vector3.new(1.1, 0.45, 0.3),
		CFrame.new(s * 1.55, 4.35, 4.85) * A(math.rad(12), 0, 0),
		SEAT,
		M.Fabric
	)
end)
part("RearCushion", Vector3.new(5.6, 0.35, 1.8), CFrame.new(0, 1.575, 3.45), SEAT, M.Fabric)
part(
	"RearBack",
	Vector3.new(5.6, 2.5, 0.35),
	CFrame.new(0, 3.0, 4.55) * A(math.rad(12), 0, 0),
	SEAT,
	M.Fabric
)
part("PartitionLower", Vector3.new(5.4, 1.6, 0.08), CFrame.new(0, 2.2, 0.8), INTERIOR, M.Fabric)
part("PartitionRail", Vector3.new(5.6, 0.1, 0.1), CFrame.new(0, 3.0, 0.8), TRIM_BLACK, M.Plastic)
part(
	"PartitionPlexi",
	Vector3.new(5.4, 2.75, 0.05),
	CFrame.new(0, 4.4, 0.8),
	PLEXI,
	M.Glass,
	{ transparency = 0.75 }
)
part("TaxiTVBezel", Vector3.new(0.9, 0.6, 0.06), CFrame.new(0, 2.6, 0.87), TRIM_BLACK, M.Plastic)
part(
	"TaxiTVScreen",
	Vector3.new(0.75, 0.45, 0.02),
	CFrame.new(0, 2.6, 0.91),
	TV_BLUE,
	M.SmoothPlastic
)

---------------------------------------------------------------------------------------------------
-- Details
---------------------------------------------------------------------------------------------------
mirror(function(s)
	part(
		"MirrorArm",
		Vector3.new(0.3, 0.12, 0.15),
		CFrame.new(s * 4.0, 4.0, -3.65),
		TRIM_BLACK,
		M.Plastic
	)
	part(
		"MirrorHousing",
		Vector3.new(0.5, 0.45, 0.25),
		CFrame.new(s * 4.3, 4.05, -3.6),
		TRIM_BLACK,
		M.Plastic
	)
	part(
		"MirrorGlass",
		Vector3.new(0.42, 0.36, 0.03),
		CFrame.new(s * 4.3, 4.05, -3.46),
		CHROME,
		M.Metal,
		{ reflectance = 0.4 }
	)
	chrome("DoorHandle", Vector3.new(0.06, 0.12, 0.5), CFrame.new(s * 3.98, 3.5, -1.0))
	chrome("DoorHandle", Vector3.new(0.06, 0.12, 0.5), CFrame.new(s * 3.98, 3.5, 3.6))
	add({
		name = "ExhaustTip",
		shape = CYL,
		size = Vector3.new(0.6, 0.25, 0.25),
		offset = CFrame.new(s * 2.6, 0.9, 10.9) * CYLINDER_Z,
		color = CHROME,
		material = M.Metal,
		reflectance = CHROME_REFLECT,
	})
end)
part("Wiper", Vector3.new(2.2, 0.05, 0.06), CFrame.new(-1.4, 3.69, -4.15), TRIM_BLACK, M.Plastic)
part(
	"Wiper",
	Vector3.new(2.2, 0.05, 0.06),
	CFrame.new(0.9, 3.69, -4.15) * A(0, 0, math.rad(4)),
	TRIM_BLACK,
	M.Plastic
)
part("Antenna", Vector3.new(0.04, 1.4, 0.04), CFrame.new(2.9, 4.6, 9.8), TRIM_BLACK, M.Plastic)

return {
	name = "NYC Taxi",
	-- Real: 177 km/h, 0-100 km/h in 9 s, brakes 0.8 g, coasts 0.2 g (VehicleDefaults maps them).
	speed = 66,
	acceleration = 7.8,
	braking = 14.5,
	coasting = 5.7,
	turnRate = 2.3,
	footprint = Vector2.new(7.6, 22.0),
	collision = {
		{ size = Vector3.new(7.9, 2.55, 22.2), offset = CFrame.new(0, 2.475, 0) },
		{ size = Vector3.new(6.3, 2.2, 9.0), offset = CFrame.new(0, 4.85, 1.5) },
		{ size = Vector3.new(0.9, 1.3, 4.8), offset = CFrame.new(0, 6.7, 1.6) },
	},
	seats = {
		CFrame.new(-1.55, 1.2, -0.6), -- driver (LHD)
		CFrame.new(1.55, 1.2, -0.6),
		CFrame.new(-1.55, 1.2, 3.5),
		CFrame.new(1.55, 1.2, 3.5),
	},
	pieces = pieces,
}
