-- Humvee: M1151 up-armored HMMWV in desert tan CARC with an O-GPK roof turret and run-flat tires.

-- Scale: 4 studs = 1 m (roof raised ~0.1 m so the seated avatar clears it). Left-hand drive.

local rgb = Color3.fromRGB
local M = Enum.Material
local A = CFrame.Angles
local CYL = Enum.PartType.Cylinder
local CYLINDER_Z = A(0, math.rad(90), 0)
local CYLINDER_Y = A(0, 0, math.rad(90))

-- Wedge orientations (WedgePart default: slope rises from the bottom -Z edge to the top +Z edge).
local RISE_FRONT = A(0, math.pi, 0) -- slope rises toward -Z
local RISE_RIGHT = A(0, math.pi / 2, 0) -- length along Z, slope rises toward +X
local RISE_LEFT = A(0, -math.pi / 2, 0) -- length along Z, slope rises toward -X

local TAN = rgb(193, 170, 125)
local TAN_SHADE = rgb(150, 131, 95)
local TAN_LIGHT = rgb(212, 194, 152)
local RIM_TAN = rgb(172, 152, 112)
local BLACK = rgb(24, 24, 25)
local RUBBER = rgb(30, 30, 30)
local RUBBER_2 = rgb(40, 40, 40)
local DARK_METAL = rgb(58, 54, 48)
local GLASS = rgb(110, 132, 122)
local MIRROR = rgb(150, 160, 165)
local HEAD_NEON = rgb(255, 236, 192)
local AMBER = rgb(255, 150, 25)
local RED = rgb(200, 22, 16)
local SEAT_FABRIC = rgb(92, 84, 62)
local INTERIOR_TAN = rgb(160, 142, 105)
local INTERIOR_DARK = rgb(48, 47, 43)
local RADIO_GREEN = rgb(60, 66, 46)
local OD_GREEN = rgb(72, 78, 52)

local pieces = {}

local function v(x, y, z)
	return Vector3.new(x, y, z)
end

local function add(name, size, offset, color, material, extra)
	local spec = {
		name = name,
		size = size,
		offset = offset,
		color = color,
		material = material or M.SmoothPlastic,
	}
	if extra then
		for k, val in extra do
			spec[k] = val
		end
	end
	table.insert(pieces, spec)
	return spec
end

local function cyl(name, size, offset, color, material, extra)
	local spec = add(name, size, offset, color, material, extra)
	spec.shape = CYL
	return spec
end

local function wedge(name, size, offset, color, material, extra)
	local spec = add(name, size, offset, color, material, extra)
	spec.class = "WedgePart"
	return spec
end

local function glass(name, size, offset)
	return add(name, size, offset, GLASS, M.Glass, { transparency = 0.45, reflectance = 0.1 })
end

local function neon(name, size, offset, color)
	return add(name, size, offset, color, M.Neon)
end

---------------------------------------------------------------------------------------------------
-- Body: hood and front fenders.

add("HoodSlab", v(9.2, 0.25, 5.9), CFrame.new(0, 5.275, -5.95), TAN)
add("HoodRaisedPanel", v(4.2, 0.12, 5.2), CFrame.new(0, 5.46, -6.1), TAN)
wedge("HoodPanelChamferL", v(5.2, 0.12, 0.3), CFrame.new(-2.25, 5.46, -6.1) * RISE_RIGHT, TAN)
wedge("HoodPanelChamferR", v(5.2, 0.12, 0.3), CFrame.new(2.25, 5.46, -6.1) * RISE_LEFT, TAN)
wedge("HoodFrontChamfer", v(9.2, 0.4, 0.6), CFrame.new(0, 5.2, -9.2), TAN)
for i = 0, 5 do
	add("HoodIntakeLouver", v(3.0, 0.04, 0.1), CFrame.new(0, 5.54, -4.0 - i * 0.22), BLACK)
end

for _, s in { -1, 1 } do
	add("FenderSkirt", v(0.3, 0.75, 5.9), CFrame.new(s * 4.45, 4.775, -5.95), TAN)
	add("FenderNose", v(0.3, 2.0, 0.6), CFrame.new(s * 4.45, 4.0, -9.2), TAN)
	add("CowlSide", v(0.3, 2.0, 1.4), CFrame.new(s * 4.45, 3.4, -3.7), TAN)
	add("HoodLatch", v(0.06, 0.4, 0.15), CFrame.new(s * 4.63, 4.95, -8.2), BLACK)
	add("HoodLatch", v(0.06, 0.4, 0.15), CFrame.new(s * 4.63, 4.95, -4.0), BLACK)
	add("HoodGrabHandle", v(0.08, 0.08, 0.8), CFrame.new(s * 3.8, 5.47, -8.4), BLACK)
end

-- Hidden mass behind the grille, kept inside the wheel wells.
add("FrontBodyBox", v(5.8, 2.4, 6.3), CFrame.new(0, 3.8, -6.2), TAN_SHADE)

-- Grille: tan frame with black vertical slots, headlights in the outer sections.
add("GrilleFrame", v(8.6, 2.0, 0.3), CFrame.new(0, 4.0, -9.35), TAN)
for i = 0, 9 do
	add("GrilleSlot", v(0.16, 1.45, 0.04), CFrame.new(-2.25 + i * 0.5, 4.05, -9.52), BLACK)
end

-- Wheel wells.
for _, s in { -1, 1 } do
	for _, z in { -6.6, 6.6 } do
		add("ArchLiner", v(1.6, 0.1, 4.4), CFrame.new(s * 3.65, 4.35, z), BLACK)
		add("ArchLip", v(0.34, 0.08, 4.4), CFrame.new(s * 4.46, 4.36, z), TAN_SHADE)
	end
end

---------------------------------------------------------------------------------------------------
-- Cab: rockers, armored doors with window holes, windshield frame and roof around the turret hole.

-- One armored door: a slab split into 4 blocks around a window hole, with glass in the hole.
local function door(label, s, z0, z1, winZ)
	local x = s * 4.125
	local y0, y1 = 3.05, 7.8
	local wy0, wy1 = 5.85, 7.35
	local wz0, wz1 = winZ - 1.1, winZ + 1.1
	add(
		label .. "Lower",
		v(0.35, wy0 - y0, z1 - z0),
		CFrame.new(x, (y0 + wy0) / 2, (z0 + z1) / 2),
		TAN
	)
	add(
		label .. "Upper",
		v(0.35, y1 - wy1, z1 - z0),
		CFrame.new(x, (wy1 + y1) / 2, (z0 + z1) / 2),
		TAN
	)
	add(label .. "Front", v(0.35, wy1 - wy0, wz0 - z0), CFrame.new(x, 6.6, (z0 + wz0) / 2), TAN)
	add(label .. "Rear", v(0.35, wy1 - wy0, z1 - wz1), CFrame.new(x, 6.6, (wz1 + z1) / 2), TAN)
	glass(label .. "Window", v(0.06, 1.5, 2.2), CFrame.new(s * 4.2, 6.6, winZ))
	add(label .. "WinFrameTop", v(0.04, 0.08, 2.36), CFrame.new(s * 4.32, wy1 + 0.04, winZ), BLACK)
	add(
		label .. "WinFrameBottom",
		v(0.04, 0.08, 2.36),
		CFrame.new(s * 4.32, wy0 - 0.04, winZ),
		BLACK
	)
	-- External hinges on the front edge, lever handle near the rear edge.
	add(label .. "Hinge", v(0.12, 0.35, 0.25), CFrame.new(s * 4.36, 4.0, z0 + 0.2), TAN_SHADE)
	add(label .. "Hinge", v(0.12, 0.35, 0.25), CFrame.new(s * 4.36, 7.05, z0 + 0.2), TAN_SHADE)
	add(label .. "HandlePivot", v(0.12, 0.25, 0.2), CFrame.new(s * 4.37, 5.2, z1 - 0.8), BLACK)
	add(label .. "Handle", v(0.1, 0.14, 0.7), CFrame.new(s * 4.36, 5.2, z1 - 0.5), BLACK)
end

for _, s in { -1, 1 } do
	add("Rocker", v(0.35, 0.65, 9.15), CFrame.new(s * 4.125, 2.725, 0.175), TAN)
	door("FrontDoor", s, -3.0, 0.9, -1.4)
	door("RearDoor", s, 0.9, 4.8, 2.6)
	for _, z in { -3.0, 0.9, 4.8 } do
		add("DoorSeam", v(0.04, 4.75, 0.06), CFrame.new(s * 4.32, 5.425, z), BLACK)
	end
	add("DripRail", v(0.08, 0.12, 7.8), CFrame.new(s * 4.33, 7.86, 0.9), TAN_SHADE)
	add("APillar", v(0.3, 2.3, 0.35), CFrame.new(s * 4.12, 6.65, -2.85) * A(math.rad(6), 0, 0), TAN)
end

-- Two-pane ballistic windshield, raked 6 degrees back.
local RAKE = A(math.rad(6), 0, 0)
for _, s in { -1, 1 } do
	glass("Windshield", v(3.75, 2.2, 0.2), CFrame.new(s * 2.1, 6.65, -2.88) * RAKE)
	add(
		"Wiper",
		v(0.06, 1.4, 0.06),
		CFrame.new(s * 2.1, 6.85, -2.97) * RAKE * A(0, 0, math.rad(s * 18)),
		BLACK
	)
end
add("WindshieldCenterPillar", v(0.35, 2.3, 0.3), CFrame.new(0, 6.65, -2.88) * RAKE, TAN)
add("WindshieldTopRail", v(8.5, 0.3, 0.35), CFrame.new(0, 7.65, -2.8), TAN)
add("CowlStrip", v(8.5, 0.2, 0.5), CFrame.new(0, 5.5, -3.1), TAN_SHADE)

-- Roof slabs around the turret hole (x +-1.3, z 0.2..2.6).
add("RoofFront", v(8.6, 0.3, 3.2), CFrame.new(0, 7.95, -1.4), TAN)
add("RoofRear", v(8.6, 0.3, 2.2), CFrame.new(0, 7.95, 3.7), TAN)
add("RoofSideL", v(3.0, 0.3, 2.4), CFrame.new(-2.8, 7.95, 1.4), TAN)
add("RoofSideR", v(3.0, 0.3, 2.4), CFrame.new(2.8, 7.95, 1.4), TAN)

---------------------------------------------------------------------------------------------------
-- Rear cargo shell and tailgate.

local CARGO_SLOPE = math.atan(1.3 / 4.8)
wedge("CargoTopSlope", v(8.6, 1.3, 4.8), CFrame.new(0, 7.45, 7.2) * RISE_FRONT, TAN)
for _, z in { 6.0, 8.4 } do
	local y = 8.1 - (z - 4.8) * 1.3 / 4.8 + 0.03
	add("CargoTopSeam", v(8.5, 0.04, 0.06), CFrame.new(0, y, z) * A(CARGO_SLOPE, 0, 0), BLACK)
end
for _, s in { -1, 1 } do
	add("CargoSide", v(0.35, 2.4, 4.9), CFrame.new(s * 4.125, 5.6, 7.25), TAN)
	add("RearQuarterSkirt", v(0.3, 0.6, 4.9), CFrame.new(s * 4.45, 4.7, 7.25), TAN)
	add("RearCorner", v(0.65, 1.4, 0.9), CFrame.new(s * 4.275, 3.7, 9.25), TAN)
end
add("RearBodyBox", v(5.8, 3.6, 4.5), CFrame.new(0, 4.8, 7.1), TAN_SHADE)

add("Tailgate", v(7.9, 3.8, 0.3), CFrame.new(0, 4.9, 9.55), TAN)
add("TailgateSeam", v(7.92, 0.06, 0.04), CFrame.new(0, 6.7, 9.72), BLACK)
for _, s in { -1, 1 } do
	add("TailgateHinge", v(0.4, 0.3, 0.12), CFrame.new(s * 2.5, 6.6, 9.76), TAN_SHADE)
	add("TailgateLatch", v(0.6, 0.12, 0.1), CFrame.new(s * 1.2, 5.0, 9.75), BLACK)
end
add("RearPlate", v(1.2, 0.5, 0.04), CFrame.new(0, 3.4, 9.72), TAN_LIGHT)

---------------------------------------------------------------------------------------------------
-- Bumpers, underbody, frame.

add("FrontBumper", v(8.8, 0.8, 0.5), CFrame.new(0, 2.7, -9.75), TAN_SHADE)
for _, s in { -1, 1 } do
	add("FrontBumperEnd", v(0.3, 0.9, 0.7), CFrame.new(s * 4.5, 2.7, -9.6), TAN_SHADE)
	cyl("DRingShackle", v(0.15, 0.55, 0.55), CFrame.new(s * 2.0, 2.3, -10.05), BLACK, M.Metal)
end
add("RearBumper", v(8.8, 0.8, 0.4), CFrame.new(0, 2.7, 9.85), TAN_SHADE)
cyl("TowPintleRing", v(0.2, 0.5, 0.5), CFrame.new(0, 2.5, 10.25), BLACK, M.Metal)
add("TowPintleBody", v(0.3, 0.3, 0.4), CFrame.new(0, 2.5, 10.0), BLACK, M.Metal)

add("UnderbodyArmor", v(5.8, 0.25, 18.0), CFrame.new(0, 2.48, 0), DARK_METAL, M.Metal)
for _, s in { -1, 1 } do
	add("FrameRail", v(0.4, 0.5, 19.0), CFrame.new(s * 1.6, 2.1, 0), DARK_METAL, M.Metal)
	for _, z in { -4.2, 9.0 } do
		add("MudFlap", v(1.3, 1.4, 0.06), CFrame.new(s * 3.65, 1.75, z), BLACK, M.Fabric)
	end
end
cyl("Exhaust", v(0.9, 0.3, 0.3), CFrame.new(4.2, 2.6, 4.55), DARK_METAL, M.Metal)

---------------------------------------------------------------------------------------------------
-- Lights.

for _, s in { -1, 1 } do
	cyl("HeadlightBezel", v(0.12, 0.95, 0.95), CFrame.new(s * 3.4, 4.25, -9.56) * CYLINDER_Z, BLACK)
	cyl(
		"HeadlightLens",
		v(0.06, 0.76, 0.76),
		CFrame.new(s * 3.4, 4.25, -9.63) * CYLINDER_Z,
		HEAD_NEON,
		M.Neon
	)
	neon("TurnLamp", v(0.45, 0.25, 0.06), CFrame.new(s * 3.4, 3.45, -9.53), AMBER)
	neon("BlackoutMarker", v(0.25, 0.1, 0.04), CFrame.new(s * 3.4, 4.88, -9.52), AMBER)

	add("TailCluster", v(0.9, 1.1, 0.1), CFrame.new(s * 3.9, 4.1, 9.75), BLACK)
	neon("TailLamp", v(0.6, 0.55, 0.05), CFrame.new(s * 3.9, 4.25, 9.82), RED)
	neon("TailLampTurn", v(0.6, 0.2, 0.05), CFrame.new(s * 3.9, 3.75, 9.82), AMBER)
end
add("BlackoutDriveLight", v(0.5, 0.4, 0.4), CFrame.new(-3.6, 5.6, -8.6), BLACK)
neon("BlackoutDriveLens", v(0.35, 0.2, 0.04), CFrame.new(-3.6, 5.6, -8.82), HEAD_NEON)

---------------------------------------------------------------------------------------------------
-- Wheels: 37 in run-flats on tan steel rims with a geared-hub boss. side = outboard direction.

local WHEEL_R = 1.9

local function wheel(label, cf, side)
	cyl(label .. "Tire", v(1.3, 3.6, 3.6), cf, RUBBER, M.Fabric)
	cyl(label .. "Sidewall", v(1.36, 3.2, 3.2), cf, RUBBER_2, M.Fabric)
	cyl(label .. "Rim", v(1.42, 2.1, 2.1), cf, RIM_TAN, M.Metal)
	cyl(
		label .. "RimDish",
		v(0.04, 1.6, 1.6),
		cf * CFrame.new(side * 0.73, 0, 0),
		TAN_SHADE,
		M.Metal
	)
	cyl(
		label .. "HubBoss",
		v(0.45, 0.9, 0.9),
		cf * CFrame.new(side * 0.95, 0, 0),
		DARK_METAL,
		M.Metal
	)
	cyl(label .. "HubCap", v(0.1, 0.5, 0.5), cf * CFrame.new(side * 1.2, 0, 0), BLACK, M.Metal)
	for i = 0, 9 do
		local wide = i % 2 == 0
		local size = if wide then v(1.34, 0.12, 0.55) else v(0.9, 0.12, 0.55)
		local x = if wide then 0 else (if i % 4 == 1 then 0.22 else -0.22)
		add(
			label .. "Tread",
			size,
			cf * A(math.rad(18 + i * 36), 0, 0) * CFrame.new(x, -(WHEEL_R - 0.07), 0),
			RUBBER,
			M.Fabric
		)
	end
end

for _, s in { -1, 1 } do
	for _, z in { -6.6, 6.6 } do
		wheel(if z < 0 then "Front" else "Rear", CFrame.new(s * 3.65, WHEEL_R, z), s)
	end
end

-- Axles and suspension.
for _, z in { -6.6, 6.6 } do
	cyl("Differential", v(1.6, 1.0, 1.0), CFrame.new(0, 1.9, z), DARK_METAL, M.Metal)
	for _, s in { -1, 1 } do
		cyl("HalfShaft", v(2.6, 0.25, 0.25), CFrame.new(s * 1.7, 1.9, z), DARK_METAL, M.Metal)
		add("AArm", v(2.4, 0.15, 0.6), CFrame.new(s * 2.2, 1.5, z), DARK_METAL, M.Metal)
	end
end
cyl("Driveshaft", v(12.0, 0.3, 0.3), CFrame.new(0, 2.0, 0) * CYLINDER_Z, DARK_METAL, M.Metal)

---------------------------------------------------------------------------------------------------
-- Interior.

add("FloorPan", v(7.9, 0.15, 7.6), CFrame.new(0, 2.75, 0.9), INTERIOR_DARK)
add("Tunnel", v(1.6, 1.2, 7.0), CFrame.new(0, 3.35, 0.9), INTERIOR_TAN)
add("Dashboard", v(7.9, 0.6, 0.6), CFrame.new(0, 5.25, -2.6), INTERIOR_DARK)
add("DashPad", v(7.9, 0.08, 0.5), CFrame.new(0, 5.59, -2.6), BLACK)
add("RadioRack", v(1.2, 1.0, 1.0), CFrame.new(0, 4.45, -1.6), RADIO_GREEN)
for _, s in { -1, 1 } do
	for _, z in { -0.8, 3.0 } do
		add("SeatBase", v(1.4, 0.55, 1.4), CFrame.new(s * 2.1, 3.0, z), DARK_METAL)
		add("SeatCushion", v(1.8, 0.4, 1.8), CFrame.new(s * 2.1, 3.48, z), SEAT_FABRIC, M.Fabric)
		add(
			"SeatBack",
			v(1.8, 2.4, 0.35),
			CFrame.new(s * 2.1, 4.9, z + 0.95) * A(math.rad(8), 0, 0),
			SEAT_FABRIC,
			M.Fabric
		)
	end
end
local WHEEL_CF = CFrame.new(-2.1, 5.6, -2.3) * A(math.rad(-30), 0, 0)
cyl("SteeringWheel", v(0.12, 1.4, 1.4), WHEEL_CF * CYLINDER_Z, BLACK)
cyl(
	"SteeringHub",
	v(0.16, 0.4, 0.4),
	WHEEL_CF * CFrame.new(0, 0, -0.04) * CYLINDER_Z,
	INTERIOR_DARK
)
add("SteeringColumn", v(0.2, 0.2, 0.7), WHEEL_CF * CFrame.new(0, 0, -0.4), BLACK)
add("GunnerPost", v(0.3, 1.5, 0.3), CFrame.new(0, 4.65, 1.2), DARK_METAL, M.Metal)
add("GunnerPlatform", v(1.8, 0.1, 1.2), CFrame.new(0, 5.35, 1.2), INTERIOR_DARK)
add("CabBulkhead", v(7.9, 4.9, 0.1), CFrame.new(0, 5.3, 4.75), INTERIOR_TAN)
add("HeadlinerFront", v(7.9, 0.05, 3.2), CFrame.new(0, 7.775, -1.4), INTERIOR_TAN)
add("HeadlinerRear", v(7.9, 0.05, 2.1), CFrame.new(0, 7.775, 3.65), INTERIOR_TAN)

---------------------------------------------------------------------------------------------------
-- O-GPK turret: ring, front shield with ballistic glass, angled wings, side and rear plates.

local RING = CFrame.new(0, 0, 1.2)
for i = 0, 7 do
	local seg = RING * A(0, i * math.pi / 4, 0)
	add(
		"TurretRing",
		v(2.0, 0.45, 0.4),
		CFrame.new(0, 8.33, 0) * seg * CFrame.new(0, 0, -2.4),
		TAN_SHADE
	)
end

add("ShieldPlate", v(3.2, 1.4, 0.25), CFrame.new(0, 9.3, -1.15), TAN)
glass("ShieldGlass", v(3.2, 0.8, 0.25), CFrame.new(0, 10.4, -1.15))
add("ShieldGlassFrameLow", v(3.3, 0.1, 0.3), CFrame.new(0, 10.0, -1.15), TAN_SHADE)
add("ShieldGlassFrameTop", v(3.3, 0.1, 0.3), CFrame.new(0, 10.85, -1.15), TAN_SHADE)
for _, s in { -1, 1 } do
	add("ShieldGlassFrameSide", v(0.1, 0.8, 0.3), CFrame.new(s * 1.6, 10.4, -1.15), TAN_SHADE)
	local wing = CFrame.new(s * 2.25, 0, -0.55) * A(0, -s * math.rad(40), 0)
	add("WingPlate", v(1.8, 1.4, 0.25), CFrame.new(0, 9.3, 0) * wing, TAN)
	glass("WingGlass", v(1.6, 0.6, 0.2), CFrame.new(0, 10.3, 0) * wing)
	add("WingGlassFrame", v(1.8, 0.1, 0.3), CFrame.new(0, 10.65, 0) * wing, TAN_SHADE)
	add("SidePlate", v(0.2, 1.4, 2.4), CFrame.new(s * 2.85, 9.3, 1.2), TAN)
	add(
		"RearPlate",
		v(1.6, 1.0, 0.2),
		CFrame.new(s * 1.6, 9.1, 3.35) * A(0, s * math.rad(30), 0),
		TAN
	)
	add("ShieldStrut", v(0.15, 0.15, 1.2), CFrame.new(s * 1.2, 8.75, -0.6), DARK_METAL, M.Metal)
end
cyl("PintlePost", v(0.9, 0.25, 0.25), CFrame.new(0, 9.0, -0.3) * CYLINDER_Y, DARK_METAL, M.Metal)

---------------------------------------------------------------------------------------------------
-- Details: mirrors, antennas, jerry cans.

for _, s in { -1, 1 } do
	add("MirrorArm", v(0.8, 0.1, 0.1), CFrame.new(s * 4.7, 6.9, -2.9), BLACK)
	add("MirrorHead", v(0.7, 1.0, 0.15), CFrame.new(s * 5.15, 6.6, -2.9), BLACK)
	add(
		"MirrorGlass",
		v(0.6, 0.88, 0.04),
		CFrame.new(s * 5.15, 6.6, -2.81),
		MIRROR,
		M.Glass,
		{ reflectance = 0.4 }
	)

	cyl("AntennaBase", v(0.4, 0.35, 0.35), CFrame.new(s * 3.9, 7.0, 9.3) * CYLINDER_Y, BLACK)
	cyl(
		"AntennaWhip",
		v(7.0, 0.08, 0.08),
		CFrame.new(s * 3.9, 10.69, 9.61) * A(math.rad(5), 0, 0) * CYLINDER_Y,
		BLACK
	)

	add("JerryCan", v(0.6, 1.4, 0.45), CFrame.new(s * 2.6, 5.0, 9.95), OD_GREEN)
	add("JerryCanCap", v(0.15, 0.15, 0.15), CFrame.new(s * 2.75, 5.78, 9.95), OD_GREEN)
	add("JerryCanStrap", v(0.7, 0.08, 0.5), CFrame.new(s * 2.6, 5.4, 9.97), BLACK)
end

return {
	name = "Humvee",
	speed = 85,
	turnRate = 2.2,
	footprint = Vector2.new(9.2, 19.6),
	collision = {
		{ size = Vector3.new(9.2, 4.2, 19.6), offset = CFrame.new(0, 3.3, 0) },
		{ size = Vector3.new(8.6, 2.7, 7.8), offset = CFrame.new(0, 6.75, 0.9) },
		{ size = Vector3.new(8.6, 1.4, 4.8), offset = CFrame.new(0, 6.1, 7.2) },
	},
	seats = {
		CFrame.new(-2.1, 3.2, -0.8),
		CFrame.new(2.1, 3.2, -0.8),
		CFrame.new(-2.1, 3.2, 3.0),
		CFrame.new(2.1, 3.2, 3.0),
		CFrame.new(0, 5.9, 1.2),
	},
	pieces = pieces,
}
