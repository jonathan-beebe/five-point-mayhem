-- Dune Buggy: Meyers Manx-style fiberglass buggy on a shortened VW Beetle pan with an exposed flat-four.
-- Scale: 4 studs = 1 meter.

local rgb = Color3.fromRGB
local M = Enum.Material
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball
local A = CFrame.Angles
local V3 = Vector3.new
local CF = CFrame.new

-- Cylinder axis is local X: these lay it along Z or stand it on Y.
local CYLINDER_Z = A(0, math.rad(90), 0)
local CYLINDER_Y = A(0, 0, math.rad(90))

-- Wedge orientations (WedgePart default: full bottom and back faces, slope rises toward +Z).
local REV = A(0, math.pi, 0) -- slope rises toward -Z
local SIDE_L = A(0, math.pi / 2, 0) -- size (lenZ, h, widthX); high side toward +X
local SIDE_R = A(0, -math.pi / 2, 0) -- size (lenZ, h, widthX); high side toward -X

local ORANGE = rgb(255, 110, 20)
local ORANGE_DARK = rgb(215, 85, 12)
local VINYL = rgb(25, 25, 27)
local MAT = rgb(40, 40, 40)
local TIRE = rgb(28, 28, 30)
local TREAD = rgb(32, 32, 34)
local GROOVE = rgb(18, 18, 18)
local RIM = rgb(190, 192, 196)
local RIM_DARK = rgb(45, 45, 48)
local CHROME = rgb(210, 212, 216)
local ROLLBAR = rgb(30, 30, 32)
local CRANKCASE = rgb(165, 163, 155)
local CYL_FIN = rgb(55, 55, 58)
local HEAD = rgb(120, 118, 112)
local PUSHROD = rgb(140, 140, 140)
local CHASSIS = rgb(50, 50, 52)
local DRUM = rgb(70, 70, 72)
local SHOCK = rgb(200, 30, 30)
local EXHAUST = rgb(110, 100, 95)
local BORE = rgb(10, 10, 10)
local CARB = rgb(150, 140, 110)
local ALTERNATOR = rgb(160, 160, 165)
local BELT = rgb(20, 20, 20)
local GLASS = rgb(190, 215, 225)
local HEADLIGHT = rgb(255, 240, 205)
local TAIL = rgb(210, 20, 20)
local AMBER = rgb(255, 150, 20)
local PLATE = rgb(235, 235, 225)
local GAUGE = rgb(20, 20, 22)
local NEEDLE = rgb(240, 240, 240)
local SPOKE_METAL = rgb(150, 150, 150)
local MIRROR_FACE = rgb(40, 40, 40)

local pieces = {}

local function add(piece)
	table.insert(pieces, piece)
	return piece
end

local function box(name, size, offset, color, material, reflectance)
	return add({
		name = name,
		size = size,
		offset = offset,
		color = color,
		material = material or M.SmoothPlastic,
		reflectance = reflectance,
	})
end

local function wedge(name, size, offset, color, material, reflectance)
	return add({
		name = name,
		class = "WedgePart",
		size = size,
		offset = offset,
		color = color,
		material = material or M.SmoothPlastic,
		reflectance = reflectance,
	})
end

-- Cylinder whose axis is the local X of `offset`.
local function cyl(name, length, diameter, offset, color, material, reflectance)
	return add({
		name = name,
		shape = CYL,
		size = V3(length, diameter, diameter),
		offset = offset,
		color = color,
		material = material or M.Metal,
		reflectance = reflectance,
	})
end

local function ball(name, diameter, position, color, material, reflectance)
	return add({
		name = name,
		shape = BALL,
		size = V3(diameter, diameter, diameter),
		offset = CF(position),
		color = color,
		material = material or M.Metal,
		reflectance = reflectance,
	})
end

-- Cylinder (or square bar when `square`) running from a to b.
local function tube(name, a, b, diameter, color, material, reflectance, square)
	-- Built with fromMatrix: the X axis runs along the tube.
	local axis = (b - a).Unit
	local ref = if math.abs(axis.Y) > 0.95 then V3(1, 0, 0) else V3(0, 1, 0)
	local back = axis:Cross(ref).Unit
	local frame = CFrame.fromMatrix((a + b) / 2, axis, back:Cross(axis), back)
	local piece = {
		name = name,
		size = V3((b - a).Magnitude, diameter, diameter),
		offset = frame,
		color = color,
		material = material or M.Metal,
		reflectance = reflectance,
	}
	if not square then
		piece.shape = CYL
	end
	return add(piece)
end

local function paint(name, size, offset)
	return box(name, size, offset, ORANGE, M.SmoothPlastic, 0.12)
end

local function paintWedge(name, size, offset)
	return wedge(name, size, offset, ORANGE, M.SmoothPlastic, 0.12)
end

-- Wedge whose height (local Y) points along `up` and whose full back face points along `back`.
local function wedgeFrame(position, up, back)
	return CFrame.fromMatrix(position, up:Cross(back), up, back)
end

-- Frame of a fender plate at angle phi (degrees; 0 = front horizontal, 90 = top, 180 = rear).
local function archFrame(x, cy, cz, radius, phi)
	local p = math.rad(phi)
	return CF(x, cy + radius * math.sin(p), cz - radius * math.cos(p)) * A(p - math.pi / 2, 0, 0)
end

-- Fender: a polygon of thin plates around a wheel, each with a rolled outer lip that curls down
-- toward the wheel so the fender reads as a solid hump from the side.
local function arch(
	prefix,
	side,
	x,
	width,
	cy,
	cz,
	radius,
	phis,
	length,
	thickness,
	lipWidth,
	lipAngle
)
	local beta = math.rad(lipAngle)
	for i, phi in phis do
		local frame = archFrame(x, cy, cz, radius, phi)
		paint(prefix .. i, V3(width, thickness, length), frame)
		local lip = CF(
			side * (width / 2 + lipWidth / 2 * math.cos(beta) - 0.02),
			-lipWidth / 2 * math.sin(beta),
			0
		) * A(0, 0, -side * beta)
		paint(prefix .. "Lip" .. i, V3(lipWidth, thickness, length - 0.02), frame * lip)
	end
end

---------------------------------------------------------------------------------------------------
-- Body tub, nose and hood
---------------------------------------------------------------------------------------------------

local HOOD_FRONT_Y, HOOD_REAR_Y = 2.7, 3.2
local HOOD_FRONT_Z, HOOD_REAR_Z = -6.2, -1.3
local HOOD_SLOPE = (HOOD_REAR_Y - HOOD_FRONT_Y) / (HOOD_REAR_Z - HOOD_FRONT_Z)
local HOOD_TILT = A(-math.atan(HOOD_SLOPE), 0, 0)
local function hoodY(z)
	return HOOD_FRONT_Y + (z - HOOD_FRONT_Z) * HOOD_SLOPE
end

paint("TubUpper", V3(4.6, 1.0, 4.6), CF(0, 2.2, -3.6))
paint("TubLower", V3(4.6, 0.45, 3.0), CF(0, 1.475, -2.8))
paint("NoseMid", V3(4.0, 1.0, 0.3), CF(0, 2.2, -6.05))
paint("NoseFace", V3(4.0, 0.75, 0.3), CF(0, 2.075, -6.3))
paintWedge("NoseTopChamfer", V3(4.0, 0.25, 0.25), CF(0, 2.575, -6.325))
paintWedge("Hood", V3(4.1, 0.5, 4.9), CF(0, 2.95, -3.75))
box(
	"HoodRecess",
	V3(3.0, 0.06, 3.6),
	CF(0, hoodY(-3.4) + 0.01, -3.4) * HOOD_TILT,
	ORANGE_DARK,
	M.SmoothPlastic,
	0.08
)
for _, side in { -1, 1 } do
	local s = if side < 0 then "L" else "R"
	local sideWedge = if side < 0 then SIDE_L else SIDE_R
	paintWedge(
		"HoodChamfer" .. s,
		V3(4.6, 0.55, 0.3),
		CF(side * 2.2, hoodY(-3.6) - 0.275, -3.6) * HOOD_TILT * sideWedge
	)
	-- Rounded nose corners (plan view taper from the nose face back to the tub sides).
	paintWedge(
		"NoseCorner" .. s,
		V3(0.9, 0.3, 0.55),
		wedgeFrame(Vector3.new(side * 2.15, 2.15, -6.175), V3(side, 0, 0), V3(0, 0, 1))
	)
end

---------------------------------------------------------------------------------------------------
-- Front fenders
---------------------------------------------------------------------------------------------------

local FRONT_AXLE_Z, FRONT_AXLE_Y = -4.1, 1.25
local FRONT_ARCH_R = 1.7
local REAR_AXLE_Z, REAR_AXLE_Y = 4.0, 1.6
local REAR_ARCH_R = 1.95

for _, side in { -1, 1 } do
	local s = if side < 0 then "L" else "R"
	arch(
		"FrontFender" .. s,
		side,
		side * 2.6,
		1.1,
		FRONT_AXLE_Y,
		FRONT_AXLE_Z,
		FRONT_ARCH_R,
		{ 20, 50, 80, 110, 140, 165 },
		0.99,
		0.14,
		0.42,
		62
	)
	-- Fairing from the nose sides out to the fender front.
	paintWedge(
		"FenderNoseFairing" .. s,
		V3(0.6, 0.95, 0.55),
		wedgeFrame(V3(side * 2.775, 2.0, -5.725), V3(side, 0, 0), V3(0, 0, 1))
	)
	-- Fairing from the fender rear in to the cockpit side.
	paintWedge(
		"FenderRearFairing" .. s,
		V3(0.9, 0.5, 1.0),
		wedgeFrame(V3(side * 3.0, 2.05, -2.1), V3(side, 0, 0), V3(0, 0, -1))
	)
end

---------------------------------------------------------------------------------------------------
-- Cockpit sides, cowl, dash, bulkhead, deck, pan
---------------------------------------------------------------------------------------------------

paint("Cowl", V3(4.8, 0.2, 0.5), CF(0, 3.15, -1.05))
paint("Dash", V3(4.6, 0.3, 0.25), CF(0, 3.1, -0.95))
for _, side in { -1, 1 } do
	local s = if side < 0 then "L" else "R"
	paint("SideWall" .. s, V3(0.15, 1.0, 4.8), CF(side * 2.7, 1.9, -0.2))
	paint("SideLip" .. s, V3(0.35, 0.1, 4.8), CF(side * 2.62, 2.38, -0.2))
	paint("SideLipFront" .. s, V3(0.55, 0.2, 1.5), CF(side * 2.52, 2.53, -1.85))
	paintWedge("ScoopFront" .. s, V3(0.34, 0.21, 1.6), CF(side * 2.62, 2.525, -0.3) * REV)
	paintWedge("ScoopRear" .. s, V3(0.34, 0.21, 1.6), CF(side * 2.62, 2.525, 1.3))
	box(
		"Sill" .. s,
		V3(0.3, 0.3, 5.0),
		CF(side * 2.75, 1.45, -0.2),
		ORANGE_DARK,
		M.SmoothPlastic,
		0.08
	)
end
paint("Bulkhead", V3(4.2, 1.9, 0.14), CF(0, 2.15, 2.43))
paint("RearDeck", V3(4.1, 0.15, 1.8), CF(0, 3.05, 3.4))
paintWedge("RearDeckLip", V3(4.1, 0.3, 0.35), CF(0, 2.85, 4.4) * REV)
box("FloorPan", V3(4.6, 0.15, 9.6), CF(0, 1.15, -0.8), CHASSIS, M.Metal)
box("Tunnel", V3(0.6, 0.35, 3.6), CF(0, 1.4, 0.4), CHASSIS, M.Metal)

---------------------------------------------------------------------------------------------------
-- Rear fenders and tail lamps
---------------------------------------------------------------------------------------------------

for _, side in { -1, 1 } do
	local s = if side < 0 then "L" else "R"
	local x = side * 2.82
	arch(
		"RearFender" .. s,
		side,
		x,
		1.55,
		REAR_AXLE_Y,
		REAR_AXLE_Z,
		REAR_ARCH_R,
		{ 15, 45, 75, 105, 135, 165 },
		1.13,
		0.15,
		0.45,
		72
	)
	paint("RearFenderInner" .. s, V3(0.12, 1.05, 2.8), CF(side * 2.08, 2.425, 4.0))
	paint("RearFenderInnerTop" .. s, V3(0.1, 0.5, 1.6), CF(side * 2.08, 3.15, 4.0))
	paintWedge("RearFenderFlare" .. s, V3(0.95, 1.2, 1.0), CF(side * 3.22, 2.05, 1.8))

	-- Tail lamp on the upper part of the rearmost fender plate, facing rearward.
	local plate = archFrame(x, REAR_AXLE_Y, REAR_AXLE_Z, REAR_ARCH_R, 165)
	cyl(
		"TailLampRing" .. s,
		0.06,
		0.55,
		plate * CF(0, 0.1, -0.25) * CYLINDER_Y,
		CHROME,
		M.Metal,
		0.4
	)
	cyl("TailLamp" .. s, 0.08, 0.45, plate * CF(0, 0.13, -0.25) * CYLINDER_Y, TAIL, M.Neon)
end

---------------------------------------------------------------------------------------------------
-- Windshield, wipers, mirror
---------------------------------------------------------------------------------------------------

local WS = CF(0, 3.88, -0.69) * A(math.rad(25), 0, 0)
add({
	name = "Windshield",
	size = V3(4.3, 1.45, 0.06),
	offset = WS,
	color = GLASS,
	material = M.Glass,
	transparency = 0.45,
})
for _, side in { -1, 1 } do
	local s = if side < 0 then "L" else "R"
	box(
		"WindshieldPost" .. s,
		V3(0.12, 1.55, 0.12),
		WS * CF(side * 2.2, 0, 0),
		CHROME,
		M.Metal,
		0.4
	)
	box("Wiper" .. s, V3(1.4, 0.04, 0.06), WS * CF(side * 0.9, -0.55, -0.07), BORE, M.Metal)
end
box("WindshieldTop", V3(4.52, 0.12, 0.12), WS * CF(0, 0.74, 0), CHROME, M.Metal, 0.4)
box("WindshieldBase", V3(4.52, 0.12, 0.14), CF(0, 3.28, -1.0), CHROME, M.Metal, 0.4)
box("MirrorStalk", V3(0.35, 0.06, 0.06), CF(-2.43, 4.0, -0.63), CHROME, M.Metal, 0.4)
box("MirrorHead", V3(0.5, 0.32, 0.1), CF(-2.78, 4.03, -0.63), CHROME, M.Metal, 0.4)
box("MirrorGlass", V3(0.44, 0.26, 0.02), CF(-2.78, 4.03, -0.57), MIRROR_FACE, M.Glass, 0.3)

---------------------------------------------------------------------------------------------------
-- Headlights and indicators
---------------------------------------------------------------------------------------------------

for _, side in { -1, 1 } do
	local s = if side < 0 then "L" else "R"
	local x = side * 2.35
	box("HeadlightBracket" .. s, V3(0.3, 0.06, 0.3), CF(x, 3.0, -4.6), CHROME, M.Metal, 0.4)
	cyl("HeadlightStalk" .. s, 0.5, 0.14, CF(x, 3.25, -4.6) * CYLINDER_Y, CHROME, M.Metal, 0.4)
	cyl("HeadlightBucket" .. s, 0.6, 0.8, CF(x, 3.75, -4.65) * CYLINDER_Z, CHROME, M.Metal, 0.35)
	cyl("HeadlightBezel" .. s, 0.06, 0.86, CF(x, 3.75, -4.97) * CYLINDER_Z, CHROME, M.Metal, 0.4)
	cyl("HeadlightLens" .. s, 0.05, 0.66, CF(x, 3.75, -5.0) * CYLINDER_Z, HEADLIGHT, M.Neon)
	ball("TurnLamp" .. s, 0.3, V3(side * 1.6, 2.25, -6.45), AMBER, M.Neon)
end

---------------------------------------------------------------------------------------------------
-- Wheels
---------------------------------------------------------------------------------------------------

local function spokeFrame(x, cy, cz, radius, angle)
	return CF(x, cy + radius * math.sin(angle), cz + radius * math.cos(angle)) * A(-angle, 0, 0)
end

for _, side in { -1, 1 } do
	local s = if side < 0 then "L" else "R"

	-- Front: narrow 165R15 rib tire on a polished 5-spoke wheel with a dog-dish cap.
	local fx, fy, fz = side * 2.65, FRONT_AXLE_Y, FRONT_AXLE_Z
	cyl("FrontTire" .. s, 0.85, 2.5, CF(fx, fy, fz), TIRE, M.Fabric)
	for i, dx in { -0.22, 0, 0.22 } do
		cyl("FrontGroove" .. s .. i, 0.05, 2.52, CF(fx + dx, fy, fz), GROOVE, M.Fabric)
	end
	cyl("FrontRim" .. s, 0.87, 1.55, CF(fx, fy, fz), RIM, M.Metal, 0.3)
	cyl("FrontRimWell" .. s, 0.06, 1.3, CF(fx + side * 0.415, fy, fz), RIM_DARK, M.Metal)
	for k = 0, 4 do
		local a = math.rad(90 + k * 72)
		box(
			"FrontSpoke" .. s .. k,
			V3(0.06, 0.14, 0.5),
			spokeFrame(fx + side * 0.46, fy, fz, 0.42, a),
			RIM,
			M.Metal,
			0.3
		)
	end
	cyl("FrontHubCap" .. s, 0.1, 0.55, CF(fx + side * 0.47, fy, fz), CHROME, M.Metal, 0.4)
	cyl("FrontDrum" .. s, 0.3, 1.2, CF(side * 2.1, fy, fz), DRUM, M.Metal)

	-- Rear: fat 31x10.5 lug tire on a wide polished 5-spoke wheel.
	local rx, ry, rz = side * 2.85, REAR_AXLE_Y, REAR_AXLE_Z
	cyl("RearTire" .. s, 1.3, 3.2, CF(rx, ry, rz), TIRE, M.Fabric)
	for k = 0, 11 do
		local theta = k * 2 * math.pi / 12
		local dx = if k % 2 == 0 then 0.32 else -0.32
		box(
			"RearLug" .. s .. k,
			V3(0.55, 0.14, 0.42),
			CF(rx + dx, ry + 1.62 * math.sin(theta), rz + 1.62 * math.cos(theta))
				* A(math.pi / 2 - theta, 0, 0),
			TREAD,
			M.Fabric
		)
	end
	cyl("RearRim" .. s, 1.32, 1.9, CF(rx, ry, rz), RIM, M.Metal, 0.3)
	cyl("RearRimWell" .. s, 0.06, 1.62, CF(rx + side * 0.64, ry, rz), RIM_DARK, M.Metal)
	for k = 0, 4 do
		local a = math.rad(90 + k * 72)
		box(
			"RearSpoke" .. s .. k,
			V3(0.08, 0.18, 0.62),
			spokeFrame(rx + side * 0.7, ry, rz, 0.5, a),
			RIM,
			M.Metal,
			0.3
		)
		local b = a + math.rad(36)
		cyl(
			"RearLugNut" .. s .. k,
			0.08,
			0.1,
			CF(rx + side * 0.7, ry + 0.32 * math.sin(b), rz + 0.32 * math.cos(b)),
			CHROME,
			M.Metal,
			0.4
		)
	end
	cyl("RearCenterCap" .. s, 0.12, 0.45, CF(rx + side * 0.72, ry, rz), CHROME, M.Metal, 0.4)
end

---------------------------------------------------------------------------------------------------
-- Chassis, suspension, bumpers, plate
---------------------------------------------------------------------------------------------------

cyl("TorsionTubeLower", 4.3, 0.3, CF(0, 1.3, -4.75), CHASSIS)
cyl("TorsionTubeUpper", 4.3, 0.3, CF(0, 1.65, -4.75), CHASSIS)
for _, side in { -1, 1 } do
	local s = if side < 0 then "L" else "R"
	box("FrontTrailingArm" .. s, V3(0.15, 0.15, 0.8), CF(side * 2.12, 1.3, -4.4), CHASSIS, M.Metal)
	cyl(
		"FrontShock" .. s,
		0.75,
		0.18,
		CF(side * 1.85, 1.5, -4.45) * A(math.rad(-12), 0, 0) * CYLINDER_Y,
		SHOCK
	)
	cyl("RearAxleTube" .. s, 1.4, 0.3, CF(side * 1.5, REAR_AXLE_Y, REAR_AXLE_Z), CHASSIS)
	box("RearTrailingArm" .. s, V3(0.15, 0.2, 2.0), CF(side * 1.95, 1.4, 3.0), CHASSIS, M.Metal)
	cyl(
		"RearShock" .. s,
		1.3,
		0.2,
		CF(side * 1.85, 2.3, 4.6) * A(math.rad(-15), 0, 0) * CYLINDER_Y,
		SHOCK
	)
	box(
		"FrontBumperBracket" .. s,
		V3(0.12, 0.12, 0.5),
		CF(side * 1.6, 1.65, -6.4),
		CHASSIS,
		M.Metal
	)
	box(
		"RearNerfUpright" .. s,
		V3(0.14, 0.9, 0.14),
		CF(side * 2.0, 1.95, 6.55),
		CHROME,
		M.Metal,
		0.4
	)
	box("RearNerfRail" .. s, V3(0.12, 0.12, 1.1), CF(side * 2.0, 1.56, 6.0), CHASSIS, M.Metal)
end
box("Transaxle", V3(1.6, 0.8, 1.2), CF(0, 1.75, 3.9), CRANKCASE, M.Metal)
cyl("FrontBumper", 4.4, 0.22, CF(0, 1.65, -6.6), CHROME, M.Metal, 0.4)
cyl("RearNerfBar", 4.2, 0.24, CF(0, 2.3, 6.65), CHROME, M.Metal, 0.4)
box("LicensePlate", V3(1.2, 0.6, 0.05), CF(0, 2.8, 6.5), PLATE)
box("PlateBracket", V3(0.1, 0.4, 0.1), CF(0, 2.45, 6.52), CHASSIS, M.Metal)

---------------------------------------------------------------------------------------------------
-- Engine: air-cooled VW type 1 flat-four, fully exposed
---------------------------------------------------------------------------------------------------

box("Crankcase", V3(1.6, 1.0, 1.5), CF(0, 1.9, 5.35), CRANKCASE, M.Metal)
for _, side in { -1, 1 } do
	local s = if side < 0 then "L" else "R"
	for i, z in { 5.0, 5.7 } do
		cyl("Cylinder" .. s .. i, 0.55, 0.65, CF(side * 1.05, 2.0, z), CYL_FIN)
		cyl("Pushrod" .. s .. i, 0.5, 0.08, CF(side * 1.05, 1.62, z - 0.05), PUSHROD)
		tube(
			"Header" .. s .. i,
			V3(side * 1.4, 1.6, z - 0.1),
			V3(side * (i == 1 and 1.05 or 1.2), 1.5, 6.4),
			0.16,
			EXHAUST
		)
	end
	box("Head" .. s, V3(0.3, 0.75, 1.4), CF(side * 1.42, 2.0, 5.35), HEAD, M.Metal)
	box("ValveCover" .. s, V3(0.25, 0.6, 1.2), CF(side * 1.62, 1.95, 5.35), CHROME, M.Metal, 0.4)
	box("CylinderTin" .. s, V3(0.6, 0.06, 1.5), CF(side * 1.05, 2.42, 5.35), ROLLBAR, M.Metal)
	wedge(
		"ShroudChamfer" .. s,
		V3(1.3, 0.3, 0.3),
		CF(side * 1.05, 3.075, 5.45) * (if side < 0 then SIDE_L else SIDE_R),
		ROLLBAR,
		M.Metal
	)
	box("IntakeArm" .. s, V3(1.25, 0.1, 0.1), CF(side * 0.675, 3.28, 5.1), CRANKCASE, M.Metal)
	box("IntakeDownpipe" .. s, V3(0.1, 1.0, 0.1), CF(side * 1.3, 2.8, 5.1), CRANKCASE, M.Metal)
	tube(
		"BeltStrand" .. s,
		V3(side * 0.33, 1.95, 6.29),
		V3(side * 0.18, 3.65, 6.29),
		0.06,
		BELT,
		M.Fabric,
		nil,
		true
	)
	local tip = CF(side * 0.55, 1.7, 6.68) * A(math.rad(-30), 0, 0) * CYLINDER_Z
	cyl("ExhaustTip" .. s, 0.5, 0.2, tip, CHROME, M.Metal, 0.4)
	cyl("ExhaustBore" .. s, 0.05, 0.14, tip * CF(-0.24, 0, 0), BORE, M.SmoothPlastic)
end
box("FanShroud", V3(2.4, 0.5, 1.3), CF(0, 2.675, 5.45), ROLLBAR, M.Metal)
box("FanShroudTop", V3(1.8, 0.3, 1.3), CF(0, 3.075, 5.45), ROLLBAR, M.Metal)
cyl("FanHousing", 0.15, 1.3, CF(0, 2.85, 6.15) * CYLINDER_Z, ROLLBAR)
box("AlternatorStand", V3(0.45, 0.35, 0.45), CF(0, 3.35, 5.8), CRANKCASE, M.Metal)
cyl("Alternator", 0.6, 0.55, CF(0, 3.65, 5.9) * CYLINDER_Z, ALTERNATOR)
cyl("AlternatorPulley", 0.12, 0.4, CF(0, 3.65, 6.26) * CYLINDER_Z, CHROME, M.Metal, 0.4)
cyl("CrankPulley", 0.2, 0.7, CF(0, 1.95, 6.2) * CYLINDER_Z, CHROME, M.Metal, 0.4)
box("Carburetor", V3(0.35, 0.35, 0.35), CF(0, 3.4, 5.1), CARB, M.Metal)
cyl("AirCleaner", 0.45, 1.0, CF(0, 3.8, 5.1) * CYLINDER_Y, CHROME, M.Metal, 0.4)
ball("AirCleanerNut", 0.18, V3(0, 4.06, 5.1), CHROME, M.Metal, 0.4)
cyl("Distributor", 0.4, 0.22, CF(0.45, 3.4, 5.5) * CYLINDER_Y, ROLLBAR)
cyl("Coil", 0.4, 0.2, CF(-0.7, 3.32, 5.8) * CYLINDER_Z, ROLLBAR)
cyl("OilFiller", 0.3, 0.22, CF(-0.45, 3.35, 5.45) * CYLINDER_Y, CHROME, M.Metal, 0.4)
cyl("Muffler", 2.6, 0.45, CF(0, 1.5, 6.5), EXHAUST)

---------------------------------------------------------------------------------------------------
-- Roll bar
---------------------------------------------------------------------------------------------------

for _, side in { -1, 1 } do
	local s = if side < 0 then "L" else "R"
	cyl("RollBarUpright" .. s, 3.8, 0.28, CF(side * 2.2, 4.35, 2.65) * CYLINDER_Y, ROLLBAR)
	ball("RollBarBend" .. s, 0.28, V3(side * 2.2, 6.25, 2.65), ROLLBAR)
	tube("RollBarBrace" .. s, V3(side * 2.2, 6.1, 2.75), V3(side * 1.9, 3.16, 4.25), 0.24, ROLLBAR)
	box("RollBarBraceMount" .. s, V3(0.35, 0.06, 0.35), CF(side * 1.9, 3.155, 4.15), RIM, M.Metal)
end
cyl("RollBarTop", 4.4, 0.28, CF(0, 6.25, 2.65), ROLLBAR)
cyl("RollBarPad", 3.0, 0.42, CF(0, 6.25, 2.65), VINYL, M.Fabric)

---------------------------------------------------------------------------------------------------
-- Interior
---------------------------------------------------------------------------------------------------

for _, side in { -1, 1 } do
	local s = if side < 0 then "L" else "R"
	local x = side * 1.05
	box("SeatCushion" .. s, V3(1.8, 0.3, 1.9), CF(x, 1.73, 1.25), VINYL, M.Fabric)
	box(
		"SeatBack" .. s,
		V3(1.8, 2.0, 0.25),
		CF(x, 2.95, 2.28) * A(math.rad(8), 0, 0),
		VINYL,
		M.Fabric
	)
	box("BolsterIn" .. s, V3(0.2, 0.18, 1.6), CF(x - side * 0.8, 1.9, 1.2), VINYL, M.Fabric)
	box("BolsterOut" .. s, V3(0.2, 0.18, 1.6), CF(x + side * 0.8, 1.9, 1.2), VINYL, M.Fabric)
	box("FloorMat" .. s, V3(1.8, 0.04, 2.4), CF(side * 1.1, 1.25, -0.4), MAT, M.Fabric)
end
for i, x in { -1.4, -1.05, -0.7 } do
	box(
		"Pedal" .. i,
		V3(0.25, 0.4, 0.08),
		CF(x, 1.6, -1.0) * A(math.rad(-15), 0, 0),
		CHASSIS,
		M.Metal
	)
end
local shifter = CF(0, 2.2, 0) * A(math.rad(10), 0, 0)
cyl("Shifter", 1.2, 0.08, shifter * CYLINDER_Y, CHROME, M.Metal, 0.4)
ball("ShifterKnob", 0.25, (shifter * CF(0, 0.62, 0)).Position, VINYL, M.SmoothPlastic)
box("Handbrake", V3(0.1, 0.1, 0.7), CF(0.3, 1.65, 0.6) * A(math.rad(20), 0, 0), CHASSIS, M.Metal)

-- Steering wheel, built in its own frame.
local W = CF(-1.05, 3.75, -0.1) * A(math.rad(30), 0, 0)
for k = 0, 7 do
	box(
		"WheelRim" .. k,
		V3(0.5, 0.12, 0.12),
		W * A(0, 0, math.rad(k * 45)) * CF(0, 0.6, 0),
		VINYL,
		M.SmoothPlastic
	)
end
for i, a in { 90, 210, 330 } do
	box(
		"WheelSpoke" .. i,
		V3(0.06, 0.5, 0.08),
		W * A(0, 0, math.rad(a - 90)) * CF(0, 0.3, 0),
		SPOKE_METAL,
		M.Metal
	)
end
cyl("WheelHub", 0.1, 0.3, W * CYLINDER_Z, VINYL, M.SmoothPlastic)
tube("SteeringColumn", W.Position, V3(-1.05, 3.05, -1.0), 0.12, VINYL, M.SmoothPlastic)

-- Gauges.
cyl("SpeedoRing", 0.06, 0.62, CF(-1.05, 3.25, -0.82) * CYLINDER_Z, CHROME, M.Metal, 0.4)
cyl("SpeedoFace", 0.04, 0.55, CF(-1.05, 3.25, -0.8) * CYLINDER_Z, GAUGE)
box(
	"SpeedoNeedle",
	V3(0.03, 0.22, 0.02),
	CF(-1.05, 3.25, -0.775) * A(0, 0, math.rad(-40)) * CF(0, 0.08, 0),
	NEEDLE,
	M.Neon
)
cyl("TachRing", 0.06, 0.4, CF(-0.35, 3.25, -0.82) * CYLINDER_Z, CHROME, M.Metal, 0.4)
cyl("TachFace", 0.04, 0.35, CF(-0.35, 3.25, -0.8) * CYLINDER_Z, GAUGE)
cyl("GrabBar", 1.2, 0.1, CF(1.05, 3.31, -0.9), CHROME, M.Metal, 0.4)

return {
	name = "Dune Buggy",
	speed = 100,
	turnRate = 2.6,
	footprint = Vector2.new(7.0, 13.2),
	collision = {
		{ size = V3(5.6, 1.6, 4.8), offset = CF(0, 2.0, -3.8) }, -- nose: y 1.2..2.8
		{ size = V3(5.4, 0.6, 3.8), offset = CF(0, 1.5, 0.5) }, -- cockpit floor: y 1.2..1.8
		{ size = V3(4.2, 1.8, 4.0), offset = CF(0, 2.1, 4.4) }, -- deck + engine: y 1.2..3.0
	},
	seats = {
		CF(-1.05, 1.4, 1.5), -- driver (LHD), seat top y 1.9
		CF(1.05, 1.4, 1.5),
	},
	pieces = pieces,
}
