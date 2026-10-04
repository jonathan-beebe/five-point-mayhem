-- Jeep Wrangler: 2021 JL Rubicon 2-door in Sarge Green, top and doors off, sport bar, 35 in tires.

-- Scale: 4 studs = 1 m. Left-hand drive.

local rgb = Color3.fromRGB
local M = Enum.Material
local A = CFrame.Angles
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball
local CYLINDER_Z = A(0, math.rad(90), 0) -- local +X -> world -Z
local CYLINDER_Y = A(0, 0, math.rad(90))

local BODY = rgb(80, 88, 66)
local TRIM_BLACK = rgb(32, 32, 32)
local FLARE_BLACK = rgb(38, 38, 38)
local SLOT_BLACK = rgb(14, 14, 14)
local BUMPER = rgb(28, 28, 30)
local FRAME = rgb(25, 25, 27)
local TIRE = rgb(26, 26, 26)
local LUG = rgb(30, 30, 30)
local RIM = rgb(55, 57, 60)
local RIM_LIP = rgb(95, 97, 100)
local HUB = rgb(40, 40, 42)
local CAGE = rgb(24, 24, 24)
local GLASS = rgb(55, 70, 75)
local DRL = rgb(255, 244, 220)
local LENS = rgb(40, 40, 45)
local CHROME = rgb(165, 165, 170)
local TAIL_RED = rgb(220, 20, 20)
local REVERSE = rgb(240, 240, 235)
local TOW_RED = rgb(190, 30, 30)
local SEAT = rgb(30, 30, 32)
local DASH = rgb(36, 36, 38)
local FLOOR = rgb(36, 36, 36)
local SCREEN = rgb(18, 24, 32)
local PLATE = rgb(235, 235, 230)

local pieces = {}

local function add(name, size, offset, color, material, extra)
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

local function body(name, size, offset, extra)
	local spec = add(name, size, offset, BODY, M.SmoothPlastic, extra)
	spec.reflectance = 0.05
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

-- Beam from a to b: cross-section w (x) by h (y), length along local Z. Builds the rotation
-- matrix directly (same result as CFrame.lookAt, which the lune preview loader gets wrong).
local function bar(a: Vector3, b: Vector3, w: number, h: number)
	local d = b - a
	local p = (a + b) / 2
	local zAxis = -d.Unit
	local up = if math.abs(zAxis.Y) > 0.99 then Vector3.new(0, 0, -1) else Vector3.new(0, 1, 0)
	local xAxis = up:Cross(zAxis).Unit
	local yAxis = zAxis:Cross(xAxis)
	local cf = CFrame.new(
		p.X,
		p.Y,
		p.Z,
		xAxis.X,
		yAxis.X,
		zAxis.X,
		xAxis.Y,
		yAxis.Y,
		zAxis.Y,
		xAxis.Z,
		yAxis.Z,
		zAxis.Z
	)
	return Vector3.new(w, h, d.Magnitude), cf
end

local function v(x, y, z)
	return Vector3.new(x, y, z)
end

---------------------------------------------------------------------------------------------------
-- Wheels: cf is the wheel center with the axle along local X; side is the outer face direction.

local function wheel(label, cf, side)
	cyl(label .. "Tire", v(1.27, 3.56, 3.56), cf, TIRE)
	for i = 0, 11 do
		local x = i % 2 == 0 and 0.18 or -0.18
		add(
			label .. "Lug",
			v(0.85, 0.14, 0.5),
			cf * CFrame.new(x, 0, 0) * A(i * 2 * math.pi / 12, 0, 0) * CFrame.new(0, 1.73, 0),
			LUG,
			M.Fabric
		)
	end
	cyl(label .. "RimLip", v(0.04, 1.8, 1.8), cf * CFrame.new(side * 0.6, 0, 0), RIM_LIP, M.Metal)
	cyl(label .. "RimFace", v(0.04, 1.55, 1.55), cf * CFrame.new(side * 0.625, 0, 0), RIM, M.Metal)
	for k = 0, 4 do
		add(
			label .. "Spoke",
			v(0.06, 0.62, 0.22),
			cf
				* CFrame.new(side * 0.66, 0, 0)
				* A(k * 2 * math.pi / 5, 0, 0)
				* CFrame.new(0, 0.42, 0),
			RIM_LIP,
			M.Metal
		)
	end
	cyl(label .. "HubCap", v(0.08, 0.5, 0.5), cf * CFrame.new(side * 0.68, 0, 0), HUB, M.Metal)
end

wheel("FL", CFrame.new(-3.2, 1.8, -4.92), -1)
wheel("FR", CFrame.new(3.2, 1.8, -4.92), 1)
wheel("RL", CFrame.new(-3.2, 1.8, 4.92), -1)
wheel("RR", CFrame.new(3.2, 1.8, 4.92), 1)
wheel("Spare", CFrame.new(0, 4.6, 8.15) * CYLINDER_Z, -1)

---------------------------------------------------------------------------------------------------
-- Chassis and underbody

for _, s in { -1, 1 } do
	add("FrameRail", v(0.35, 0.5, 13.8), CFrame.new(s * 1.75, 2.05, 0), FRAME, M.Metal)
	add("RockRail", v(0.45, 0.45, 5.4), CFrame.new(s * 3.3, 2.28, 0), BUMPER, M.Metal)
end
cyl("FrontAxle", v(5.4, 0.45, 0.45), CFrame.new(0, 1.8, -4.92), FRAME, M.Metal)
cyl("RearAxle", v(5.4, 0.45, 0.45), CFrame.new(0, 1.8, 4.92), FRAME, M.Metal)
add("FrontDiff", v(1, 1, 1), CFrame.new(-0.5, 1.7, -4.92), FRAME, M.Metal, { shape = BALL })
add("RearDiff", v(1.05, 1.05, 1.05), CFrame.new(0, 1.7, 4.92), FRAME, M.Metal, { shape = BALL })
cyl("Driveshaft", v(8.6, 0.25, 0.25), CFrame.new(0, 1.95, 0) * CYLINDER_Z, FRAME, M.Metal)
add("FrontSkidPlate", v(2.6, 0.08, 1.6), CFrame.new(0, 1.75, -6.9), BUMPER, M.Metal)
cyl(
	"ExhaustTip",
	v(0.5, 0.3, 0.3),
	CFrame.new(-2.3, 1.95, 7.05) * CYLINDER_Z,
	CHROME,
	M.Metal,
	{ reflectance = 0.2 }
)

---------------------------------------------------------------------------------------------------
-- Front clip: grille, headlights, hood, fenders, flares, bumper

local G = CFrame.new(0, 3.75, -7.35) * A(math.rad(6), 0, 0)

body("GrillePanel", v(5.9, 1.9, 0.25), G)
for _, x in { 0, -0.55, 0.55, -1.1, 1.1, -1.65, 1.65 } do
	add("GrilleSlot", v(0.32, 1.15, 0.05), G * CFrame.new(x, 0.1, -0.15), SLOT_BLACK)
end
add("GrilleValance", v(5.9, 0.3, 0.2), G * CFrame.new(0, -0.8, -0.16), TRIM_BLACK)
for _, s in { -1, 1 } do
	local h = G * CFrame.new(s * 2.35, 0.15, 0)
	cyl("HeadlightBezel", v(0.1, 1.15, 1.15), h * CFrame.new(0, 0, -0.17) * CYLINDER_Z, TRIM_BLACK)
	cyl("HaloDRL", v(0.03, 0.98, 0.98), h * CFrame.new(0, 0, -0.235) * CYLINDER_Z, DRL, M.Neon)
	cyl(
		"Reflector",
		v(0.03, 0.8, 0.8),
		h * CFrame.new(0, 0, -0.265) * CYLINDER_Z,
		CHROME,
		M.Metal,
		{
			reflectance = 0.2,
		}
	)
	cyl("Projector", v(0.06, 0.36, 0.36), h * CFrame.new(0, 0, -0.3) * CYLINDER_Z, LENS, M.Glass, {
		transparency = 0.2,
	})
end

local H = CFrame.new(0, 4.72, -4.35) * A(math.rad(-2.2), 0, 0)

body("Hood", v(5.8, 0.18, 5.8), H)
body("HoodDome", v(2.4, 0.1, 3.6), H * CFrame.new(0, 0.14, 0.3))
wedge(
	"HoodDomeRamp",
	v(2.4, 0.1, 0.5),
	H * CFrame.new(0, 0.14, -1.75),
	BODY,
	M.SmoothPlastic,
	{ reflectance = 0.05 }
)
add("HoodVent", v(1.6, 0.05, 0.5), H * CFrame.new(0, 0.215, -1.1), TRIM_BLACK)
for k = 0, 3 do
	add("HoodVentSlat", v(1.5, 0.04, 0.06), H * CFrame.new(0, 0.25, -1.28 + k * 0.12), SLOT_BLACK)
end
add("CowlVent", v(6.3, 0.1, 0.45), CFrame.new(0, 4.97, -1.55), TRIM_BLACK)

for _, s in { -1, 1 } do
	body("HoodSideValance", v(0.12, 0.35, 5.8), CFrame.new(s * 2.92, 4.55, -4.35))
	add("HoodLatch", v(0.08, 0.45, 0.18), CFrame.new(s * 2.97, 4.48, -6.7), TRIM_BLACK)
	body("FenderTop", v(0.85, 0.15, 5.85), CFrame.new(s * 3.32, 4.4, -4.375))
	body("FenderFrontLip", v(0.85, 0.3, 0.1), CFrame.new(s * 3.32, 4.3, -7.27))
	body("FenderFrontFace", v(0.55, 0.55, 0.08), CFrame.new(s * 3.2, 3.88, -7.26))
	body("FenderRearPanel", v(0.2, 1.9, 1.45), CFrame.new(s * 3.35, 3.45, -2.17))
	add("FenderVent", v(0.04, 0.3, 0.7), CFrame.new(s * 3.47, 4.05, -2.17), SLOT_BLACK)
	add("FenderLiner", v(1.3, 0.1, 4.2), CFrame.new(s * 3.2, 3.95, -4.92), TRIM_BLACK)
	add("EngineBayWall", v(0.1, 1.5, 4.5), CFrame.new(s * 2.5, 3.4, -4.9), TRIM_BLACK)
end

-- Trapezoid fender flares centered on an axle at zc.
local function flare(label, x, zc, drl)
	local top0, top1 = v(x, 4.15, zc - 1.3), v(x, 4.15, zc + 1.3)
	local front, rear = v(x, 2.95, zc - 2.03), v(x, 2.95, zc + 2.02)
	local size, cf = bar(top0, top1, 0.45, 0.2)
	add(label .. "FlareTop", size, cf, FLARE_BLACK, M.Plastic)
	size, cf = bar(top0, front, 0.45, 0.2)
	add(label .. "FlareFront", size, cf, FLARE_BLACK, M.Plastic)
	if drl then
		add(label .. "FlareDRL", v(0.36, 0.06, 0.7), cf * CFrame.new(0, 0.12, 0), DRL, M.Neon)
	end
	size, cf = bar(top1, rear, 0.45, 0.2)
	add(label .. "FlareRear", size, cf, FLARE_BLACK, M.Plastic)
end

for _, s in { -1, 1 } do
	flare("Front", s * 3.7, -4.92, true)
	flare("Rear", s * 3.7, 4.92, false)
end

-- Front bumper
add("FrontBumper", v(6.9, 0.75, 0.6), CFrame.new(0, 2.375, -7.75), BUMPER, M.Metal)
wedge(
	"FrontBumperEndL",
	v(0.75, 0.4, 0.6),
	CFrame.new(-3.65, 2.375, -7.75) * A(0, 0, math.pi / 2),
	BUMPER,
	M.Metal
)
wedge(
	"FrontBumperEndR",
	v(0.75, 0.4, 0.6),
	CFrame.new(3.65, 2.375, -7.75) * A(0, 0, -math.pi / 2),
	BUMPER,
	M.Metal
)
add(
	"WinchFairlead",
	v(1.2, 0.35, 0.08),
	CFrame.new(0, 2.42, -8.09),
	CHROME,
	M.Metal,
	{ reflectance = 0.2 }
)
for _, s in { -1, 1 } do
	add("TowHook", v(0.18, 0.4, 0.35), CFrame.new(s * 1.6, 2.3, -8.12), TOW_RED)
	cyl("FogBezel", v(0.05, 0.58, 0.58), CFrame.new(s * 2.85, 2.4, -8.065) * CYLINDER_Z, TRIM_BLACK)
	cyl("FogLamp", v(0.06, 0.45, 0.45), CFrame.new(s * 2.85, 2.4, -8.08) * CYLINDER_Z, DRL, M.Neon)
end

---------------------------------------------------------------------------------------------------
-- Tub and rear

for _, s in { -1, 1 } do
	body("DoorSill", v(0.2, 0.5, 3.35), CFrame.new(s * 3.35, 2.75, 0.375))
	add("SillStep", v(0.45, 0.04, 3), CFrame.new(s * 3.2, 3.02, 0.375), TRIM_BLACK)
	body("CowlSide", v(0.2, 2.45, 0.35), CFrame.new(s * 3.35, 3.72, -1.3))
	add("DoorHingeLow", v(0.12, 0.35, 0.3), CFrame.new(s * 3.5, 3.55, -1.18), TRIM_BLACK)
	add("DoorHingeHigh", v(0.12, 0.35, 0.3), CFrame.new(s * 3.5, 4.45, -1.18), TRIM_BLACK)
	add(
		"DoorStriker",
		v(0.06, 0.18, 0.1),
		CFrame.new(s * 3.25, 3.9, 1.95),
		CHROME,
		M.Metal,
		{ reflectance = 0.2 }
	)
	body("RearQuarterUpper", v(0.2, 0.95, 5.3), CFrame.new(s * 3.35, 4.375, 4.55))
	body("RearQuarterFront", v(0.2, 1.4, 0.85), CFrame.new(s * 3.35, 3.2, 2.33))
	body("RearQuarterRear", v(0.2, 1.4, 0.3), CFrame.new(s * 3.35, 3.2, 7.05))
	body("BeltlineCap", v(0.36, 0.08, 5.35), CFrame.new(s * 3.3, 4.89, 4.55))
	body("RearWheelTub", v(0.85, 1, 3.6), CFrame.new(s * 3, 4.15, 4.92))
	add("RearWheelLiner", v(1.1, 0.1, 4.0), CFrame.new(s * 3.15, 3.8, 4.92), TRIM_BLACK)
	add("TaillightHousing", v(0.55, 1.1, 0.1), CFrame.new(s * 3.1, 4.15, 7.27), TRIM_BLACK)
	add("TailLamp", v(0.42, 0.8, 0.04), CFrame.new(s * 3.1, 4.27, 7.335), TAIL_RED, M.Neon)
	add("ReverseLamp", v(0.42, 0.2, 0.04), CFrame.new(s * 3.1, 3.72, 7.335), REVERSE, M.Neon)
	add("TailgateGap", v(0.04, 2.2, 0.03), CFrame.new(s * 2.52, 3.7, 7.255), SLOT_BLACK)
end

body("TubRearWall", v(6.9, 2.35, 0.15), CFrame.new(0, 3.675, 7.17))
body("Tailgate", v(5, 2.2, 0.12), CFrame.new(0, 3.7, 7.3))
add("TailgateGapTop", v(5, 0.04, 0.03), CFrame.new(0, 4.82, 7.255), SLOT_BLACK)
add("TailgateHingeLow", v(0.3, 0.3, 0.1), CFrame.new(2.45, 3, 7.4), TRIM_BLACK)
add("TailgateHingeHigh", v(0.3, 0.3, 0.1), CFrame.new(2.45, 4.4, 7.4), TRIM_BLACK)
add("TailgateHandle", v(0.5, 0.12, 0.06), CFrame.new(-2.15, 3.6, 7.39), TRIM_BLACK)
add("SpareMount", v(1, 1, 0.15), CFrame.new(0, 4.6, 7.44), TRIM_BLACK)
add("ChmslStalk", v(0.12, 1.1, 0.1), CFrame.new(0, 6.05, 7.42), TRIM_BLACK)
add("ChmslHousing", v(1, 0.2, 0.3), CFrame.new(0, 6.6, 7.55), TRIM_BLACK)
add("ChmslLamp", v(0.9, 0.12, 0.04), CFrame.new(0, 6.6, 7.715), TAIL_RED, M.Neon)
add("RearBumper", v(6.9, 0.75, 0.55), CFrame.new(0, 2.375, 7.475), BUMPER, M.Metal)
add("LicensePlate", v(1.2, 0.55, 0.04), CFrame.new(0, 2.42, 7.77), PLATE)
add("HitchReceiver", v(0.5, 0.45, 0.6), CFrame.new(0, 1.85, 7.7), FRAME, M.Metal)
body("FuelDoor", v(0.05, 0.42, 0.42), CFrame.new(-3.46, 4.3, 5.9))

---------------------------------------------------------------------------------------------------
-- Windshield

for _, s in { -1, 1 } do
	local size, cf = bar(v(s * 3, 4.95, -1.45), v(s * 3, 7.25, 0), 0.3, 0.3)
	body("APillar", size, cf)
	add("WindshieldHinge", v(0.15, 0.2, 0.25), CFrame.new(s * 3.16, 5, -1.4), TRIM_BLACK)
end
body("WindshieldHeader", v(6.3, 0.3, 0.35), CFrame.new(0, 7.25, 0))
add("HeaderCap", v(6.3, 0.06, 0.3), CFrame.new(0, 7.43, 0.02), TRIM_BLACK)
body("WindshieldBase", v(6.3, 0.25, 0.3), CFrame.new(0, 5.05, -1.38))

local W = CFrame.new(0, 6.15, -0.68) * A(math.rad(33), 0, 0)
add("Windshield", v(5.7, 2.35, 0.06), W, GLASS, M.Glass, { transparency = 0.45 })
add("WindshieldFrit", v(5.7, 0.15, 0.03), W * CFrame.new(0, -1.1, -0.05), SLOT_BLACK)
for _, s in { -1, 1 } do
	add("Wiper", v(1.9, 0.06, 0.06), W * CFrame.new(s * 1.2, -1, -0.07), TRIM_BLACK)
end

---------------------------------------------------------------------------------------------------
-- Sport bar (padded)

local function cage(label, a, b)
	local size, cf = bar(a, b, 0.3, 0.3)
	add(label, size, cf, CAGE, M.Fabric)
end

for _, s in { -1, 1 } do
	cage("CageFrontRail", v(s * 3, 7.3, 0.05), v(s * 3.05, 7.3, 2.4))
	cage("CageHoopPost", v(s * 3.05, 4.85, 2.4), v(s * 3.05, 7.3, 2.4))
	cage("CageRearRail", v(s * 3.05, 7.3, 2.4), v(s * 3.05, 7.2, 6.8))
	cage("CageRearPost", v(s * 3.05, 7.2, 6.8), v(s * 3.05, 4.85, 6.8))
	add(
		"CageJoint",
		v(0.34, 0.34, 0.34),
		CFrame.new(s * 3.05, 7.3, 2.4),
		CAGE,
		M.Fabric,
		{ shape = BALL }
	)
	add(
		"CageJoint",
		v(0.34, 0.34, 0.34),
		CFrame.new(s * 3.05, 7.2, 6.8),
		CAGE,
		M.Fabric,
		{ shape = BALL }
	)
end
cage("CageHoopBar", v(-3.05, 7.3, 2.4), v(3.05, 7.3, 2.4))
cage("CageHarnessBar", v(-3.05, 6.3, 2.4), v(3.05, 6.3, 2.4))
cage("CageRearBar", v(-3.05, 7.2, 6.8), v(3.05, 7.2, 6.8))
add("Soundbar", v(2.8, 0.3, 0.45), CFrame.new(0, 7.05, 2.4), TRIM_BLACK)

---------------------------------------------------------------------------------------------------
-- Interior

add("Floor", v(6.5, 0.1, 8.6), CFrame.new(0, 2.5, 2.85), FLOOR, M.Fabric)
add("CargoFloor", v(6.5, 0.1, 1.4), CFrame.new(0, 2.95, 6.45), FLOOR, M.Fabric)
add("Dash", v(6.5, 0.9, 0.9), CFrame.new(0, 4.85, -1.05), DASH)
wedge("DashTopPad", v(6.5, 0.2, 0.45), CFrame.new(0, 5.4, -1.2) * A(0, math.pi, 0), DASH)
add("ClusterHood", v(1.4, 0.35, 0.4), CFrame.new(-1.55, 5.47, -0.82), DASH)
for _, dx in { -0.33, 0.33 } do
	cyl(
		"Gauge",
		v(0.03, 0.4, 0.4),
		CFrame.new(-1.55 + dx, 5.25, -0.585) * CYLINDER_Z,
		SCREEN,
		M.Glass,
		{
			reflectance = 0.2,
		}
	)
end
add(
	"CenterScreen",
	v(0.85, 0.55, 0.05),
	CFrame.new(0, 5.15, -0.58),
	SCREEN,
	M.Glass,
	{ reflectance = 0.2 }
)
for _, x in { -2.7, -0.55, 0.55, 2.7 } do
	cyl("DashVent", v(0.04, 0.35, 0.35), CFrame.new(x, 5, -0.585) * CYLINDER_Z, SLOT_BLACK)
end
do
	local size, cf = bar(v(0.9, 5.55, -0.65), v(2.3, 5.55, -0.65), 0.12, 0.12)
	add("GrabHandle", size, cf, TRIM_BLACK)
end
add("CenterConsole", v(0.9, 1, 2.6), CFrame.new(0, 3, 0.4), DASH)
cyl("Shifter", v(0.5, 0.12, 0.12), CFrame.new(0, 3.75, -0.3) * CYLINDER_Y, TRIM_BLACK)
cyl("TransferShifter", v(0.5, 0.12, 0.12), CFrame.new(0, 3.75, -0.05) * CYLINDER_Y, TRIM_BLACK)

local SW = CFrame.new(-1.55, 5.15, -0.45) * A(math.rad(-25), 0, 0) * CYLINDER_Z
cyl("SteeringRim", v(0.1, 1.4, 1.4), SW, TRIM_BLACK)
cyl("SteeringHub", v(0.14, 0.5, 0.5), SW * CFrame.new(-0.03, 0, 0), DASH)
do
	local size, cf = bar(v(-1.55, 5.1, -0.55), v(-1.55, 4.75, -1.25), 0.22, 0.22)
	add("SteeringColumn", size, cf, DASH)
end

for _, s in { -1, 1 } do
	add("FrontSeatCushion", v(1.8, 0.55, 1.9), CFrame.new(s * 1.55, 2.875, 0.95), SEAT, M.Fabric)
	add("FrontSeatBase", v(1.4, 0.3, 1.4), CFrame.new(s * 1.55, 2.45, 0.95), FRAME, M.Metal)
	add(
		"FrontSeatback",
		v(1.8, 2.7, 0.35),
		CFrame.new(s * 1.55, 4.6, 1.92) * A(math.rad(10), 0, 0),
		SEAT,
		M.Fabric
	)
	add("FrontHeadrest", v(1.1, 0.7, 0.3), CFrame.new(s * 1.55, 6.4, 2.12), SEAT, M.Fabric)
	add("RearHeadrest", v(1, 0.65, 0.3), CFrame.new(s * 1.45, 6.6, 6.05), SEAT, M.Fabric)
end
add("RearBenchCushion", v(5, 0.5, 1.8), CFrame.new(0, 3.3, 4.75), SEAT, M.Fabric)
add(
	"RearBenchBack",
	v(5, 2.6, 0.35),
	CFrame.new(0, 4.95, 5.8) * A(math.rad(12), 0, 0),
	SEAT,
	M.Fabric
)

return {
	name = "Jeep Wrangler",
	speed = 90,
	turnRate = 2.4,
	footprint = Vector2.new(7.4, 15.6),
	collision = {
		{ size = Vector3.new(7, 2.6, 6.9), offset = CFrame.new(0, 3.4, -4.55) },
		{ size = Vector3.new(7, 0.9, 8.6), offset = CFrame.new(0, 2.65, 3) },
		{ size = Vector3.new(0.5, 2.6, 5.3), offset = CFrame.new(-3.25, 3.55, 4.55) },
		{ size = Vector3.new(0.5, 2.6, 5.3), offset = CFrame.new(3.25, 3.55, 4.55) },
	},
	seats = {
		CFrame.new(-1.55, 2.7, 1),
		CFrame.new(1.55, 2.7, 1),
		CFrame.new(-1.45, 3.1, 4.7),
		CFrame.new(1.45, 3.1, 4.7),
	},
	pieces = pieces,
}
