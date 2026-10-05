-- Heron: a tall, skinny teal-and-blue stilt walker. Long blade legs on bird feet, worked by
-- excavator-style hydraulics outside each leg (hip, knee and ankle rams that slide as it walks), a
-- tractor cab of blue-tinted glass on all four sides with a crest fin and whip antennae that wobble as it walks, and long
-- thin arms with three-finger hands. Inside, a tractor's controls: a steering wheel with a spinner
-- knob that turns as the Heron turns, a gauge pod, pedals, a suspension seat with a joystick armrest console, shift levers, a
-- corner display and an overhead radio console.
-- Scale: 4 studs = 1 m. Rest pose = parked pose (knees bent). Hip pivots y 29.6, cab y 38.5..51,
-- glass y 40..48 at x +-3.3, z -3.2 and 3.55, cab cavity x -2.5..2.5, y 40..48, z -2.6..2.8 (only
-- `In*` pieces inside it).
--
-- Rig: every piece belongs to one bone. Leg pieces are authored in their bone's bind frame (thigh
-- tilted 25 degrees forward, shin 25 degrees back, foot flat), like OG's.

local rgb = Color3.fromRGB
local M = Enum.Material
local A = CFrame.Angles
local C = CFrame.new
local V = Vector3.new
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball
local rad = math.rad
local CYLINDER_Y = A(0, 0, rad(90)) -- cylinder axis along Y
local CYLINDER_Z = A(0, rad(90), 0) -- cylinder axis along Z

-- Wedge orientations (WedgePart default: slope rises from the -Z bottom edge to the +Z top edge).
local UP_BACK = A(0, math.pi, 0) -- slope rises toward -Z, faces up and back

-- Palette: { color, material, reflectance, transparency }.
local TEAL = { rgb(0, 138, 150), M.SmoothPlastic, 0.1 }
local GREEN = { rgb(40, 172, 118), M.SmoothPlastic, 0.1 }
local BLUE = { rgb(28, 84, 168), M.SmoothPlastic, 0.1 }
local DARK = { rgb(26, 34, 42), M.Metal }
local PALE = { rgb(220, 234, 232), M.SmoothPlastic }
local NEON = { rgb(80, 255, 170), M.Neon }
local SEAT = { rgb(30, 60, 70), M.Fabric }
local SCREEN = { rgb(80, 220, 255), M.Neon }
local CAB_GLASS = { rgb(70, 140, 220), M.Glass, 0.2, 0.55 }
local BARREL = { rgb(60, 70, 80), M.Metal, 0.2 }
local CHROME = { rgb(225, 230, 235), M.Metal, 0.5 }
local RUBBER = { rgb(20, 22, 24), M.Rubber }
local GAUGE = { rgb(15, 18, 22), M.SmoothPlastic }
local NEEDLE = { rgb(255, 120, 30), M.Neon }
local AMBER = { rgb(255, 170, 40), M.Neon }
local RED_LAMP = { rgb(255, 50, 40), M.Neon }
local GREEN_LAMP = { rgb(60, 255, 90), M.Neon }
local WORK_LIGHT = { rgb(255, 250, 225), M.Neon }
local KNOB_RED = { rgb(200, 30, 30), M.SmoothPlastic, 0.2 }
local KNOB_YELLOW = { rgb(240, 190, 20), M.SmoothPlastic, 0.2 }

local pieces = {}

local function part(bone, name, size, offset, style, shape, class)
	table.insert(pieces, {
		name = name,
		bone = bone,
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

local function cyl(bone, name, size, offset, style)
	part(bone, name, size, offset, style, CYL)
end

local function ball(bone, name, diameter, position, style)
	part(bone, name, V(diameter, diameter, diameter), C(position), style, BALL)
end

local function wedge(bone, name, size, offset, style)
	part(bone, name, size, offset, style, nil, "WedgePart")
end

-- Collision: a hollow box from `lo` to `hi` around the cab from `inLo` to `inHi`, as six boxes.
local function shell(lo, hi, inLo, inHi)
	local function box(a, b)
		return { size = b - a, offset = C((a + b) / 2) }
	end
	return {
		box(lo, V(hi.X, inLo.Y, hi.Z)), -- floor
		box(V(lo.X, inHi.Y, lo.Z), hi), -- roof
		box(V(lo.X, inLo.Y, lo.Z), V(inLo.X, inHi.Y, hi.Z)), -- left wall
		box(V(inHi.X, inLo.Y, lo.Z), V(hi.X, inHi.Y, hi.Z)), -- right wall
		box(V(inLo.X, inLo.Y, lo.Z), V(inHi.X, inHi.Y, inLo.Z)), -- front
		box(V(inLo.X, inLo.Y, inHi.Z), V(inHi.X, inHi.Y, hi.Z)), -- back
	}
end

-- Legs ----------------------------------------------------------------------------------------
local legBones = {}

-- A hydraulic ram from `a` (on bone `from`) to `b` (on bone `to`), rest pose. The barrel and the
-- rod are bones that aim at each other (MechGait.aim), so the rod slides in the barrel as the
-- joint between `from` and `to` moves. The barrel runs 55 % of the way from `a`, the rod 60 % back
-- from `b`; a hose runs along the barrel and a clevis lug sits at each end.
local function ram(name, s, from, a, to, b, bore)
	local barrel, rod = name .. "Barrel" .. s, name .. "Rod" .. s
	table.insert(legBones, { name = barrel, parent = from, pivot = a, aim = rod })
	table.insert(legBones, { name = rod, parent = to, pivot = b, aim = barrel })
	local length = (b - a).Magnitude
	local out, back = CFrame.lookAt(a, b), CFrame.lookAt(b, a) -- -Z toward the other end
	local lb, lr = length * 0.55, length * 0.6
	ball(barrel, name .. "Lug" .. s, bore * 1.1, a, DARK)
	cyl(
		barrel,
		name .. "Barrel" .. s,
		V(lb, bore, bore),
		out * C(0, 0, -lb / 2) * CYLINDER_Z,
		BARREL
	)
	cyl(
		barrel,
		name .. "Gland" .. s,
		V(0.5, bore * 1.15, bore * 1.15),
		out * C(0, 0, -lb + 0.25) * CYLINDER_Z,
		GREEN
	)
	cyl(
		barrel,
		name .. "Hose" .. s,
		V(lb * 0.85, 0.2, 0.2),
		out * C(bore * 0.6, 0, -lb / 2) * CYLINDER_Z,
		RUBBER
	)
	ball(rod, name .. "RodEnd" .. s, bore * 0.9, b, DARK)
	cyl(
		rod,
		name .. "Rod" .. s,
		V(lr, bore * 0.45, bore * 0.45),
		back * C(0, 0, -lr / 2) * CYLINDER_Z,
		CHROME
	)
end
local BEND = rad(25)
local HIP_Y, HIP_Z, HIP_X = 29.6, 0, 3.4
local THIGH, SHIN = 15, 15

for side = -1, 1, 2 do
	local s = side < 0 and "_L" or "_R"
	local x = side * HIP_X
	local thigh, shin, foot = "thigh" .. s, "shin" .. s, "foot" .. s
	local thighF = C(x, HIP_Y, HIP_Z) * A(BEND, 0, 0)
	local knee = (thighF * C(0, -THIGH, 0)).Position
	local shinF = C(knee) * A(-BEND, 0, 0)
	local ankle = (shinF * C(0, -SHIN, 0)).Position
	table.insert(legBones, { name = thigh, parent = "pelvis", pivot = V(x, HIP_Y, HIP_Z) })
	table.insert(legBones, { name = shin, parent = thigh, pivot = knee })
	table.insert(legBones, { name = foot, parent = shin, pivot = ankle })

	-- Thigh: a slim teal blade with a green stripe, a lug in front for the hip ram and one behind
	-- for the knee ram.
	cyl(thigh, "Hip" .. s, V(1.6, 2.8, 2.8), thighF, DARK)
	part(thigh, "Thigh" .. s, V(1.4, 13, 2.2), thighF * C(0, -7, 0), TEAL)
	part(thigh, "ThighStripe" .. s, V(0.2, 9, 0.6), thighF * C(side * 0.75, -7, -0.4), GREEN)
	part(thigh, "ThighLug" .. s, V(0.8, 1.2, 0.8), thighF * C(0, -7, -1.2), DARK)
	part(thigh, "ThighLug" .. s, V(0.8, 1.2, 0.9), thighF * C(0, -4, 1.3), DARK)

	-- Shin: a knee disc, a blue blade with a forward shin guard, a neon ankle ring.
	cyl(shin, "Knee" .. s, V(1.8, 2.6, 2.6), C(knee), PALE)
	part(shin, "Shin" .. s, V(1.2, 13.2, 1.8), shinF * C(0, -7, 0), BLUE)
	part(shin, "ShinGuard" .. s, V(1.5, 6, 0.4), shinF * C(0, -4, -1.05), TEAL)
	part(shin, "ShinLight" .. s, V(0.3, 4, 0.1), shinF * C(0, -4, -1.3), NEON)
	cyl(shin, "AnkleRing" .. s, V(0.5, 1.9, 1.9), shinF * C(0, -13.4, 0) * CYLINDER_Y, NEON)
	part(shin, "ShinLug" .. s, V(0.8, 1.2, 0.8), shinF * C(0, -4, 1.15), DARK)
	part(shin, "ShinLug" .. s, V(0.8, 1.2, 0.6), shinF * C(0, -6, -1.3), DARK)

	-- Foot: three long splayed toes with claw tips, one back toe with a spur.
	ball(foot, "Ankle" .. s, 1.8, ankle, DARK)
	part(foot, "FootHub" .. s, V(2, 1.2, 2.4), C(x, 1.1, 0), DARK)
	for _, splay in { -22, 0, 22 } do
		local toe = C(x, 0.45, -0.6) * A(0, rad(-side * splay), 0)
		part(foot, "Toe" .. s, V(0.9, 0.9, 5.6), toe * C(0, 0, -2.8), TEAL)
		wedge(foot, "Claw" .. s, V(0.9, 0.9, 1.4), toe * C(0, 0, -6.3), PALE)
	end
	part(foot, "BackToe" .. s, V(0.9, 0.9, 2.8), C(x, 0.45, 2.2), TEAL)
	wedge(foot, "Spur" .. s, V(0.9, 0.9, 1.2), C(x, 0.45, 4.2) * UP_BACK, PALE)
	part(foot, "FootLug" .. s, V(0.8, 1.6, 0.8), C(x, 1.6, -2), DARK)

	-- Hydraulics, like an excavator's boom, arm and bucket rams: hip (pelvis ear to thigh front),
	-- knee (thigh back to shin back, inside the bend) and ankle (shin front to the foot).
	part("pelvis", "RamEar" .. s, V(1.2, 3.6, 1.4), C(x, 32.9, -1.6), DARK)
	part("pelvis", "RamEarBrace" .. s, V(1.8, 1.2, 1.4), C(side * 2.5, 31.6, -1.2), DARK)
	ram("Hip", s, "pelvis", V(x, 33.2, -1.6), thigh, (thighF * C(0, -7, -1.4)).Position, 1)
	ram(
		"Knee",
		s,
		thigh,
		(thighF * C(0, -4, 1.6)).Position,
		shin,
		(shinF * C(0, -4, 1.4)).Position,
		1
	)
	ram("Ankle", s, shin, (shinF * C(0, -6, -1.5)).Position, foot, V(x, 2.4, -2), 0.8)
end

-- Pelvis --------------------------------------------------------------------------------------
cyl("pelvis", "HipAxle", V(5.2, 2.2, 2.2), C(0, HIP_Y, HIP_Z), DARK)
part("pelvis", "PelvisPlate", V(3.6, 2.4, 2.6), C(0, HIP_Y + 0.4, HIP_Z), BLUE)

-- Tower ---------------------------------------------------------------------------------------
local T = "torso"
cyl(T, "Spine", V(3.6, 1.8, 1.8), C(0, 33, 0) * CYLINDER_Y, PALE)
for k = 0, 2 do
	cyl(T, "SpineRing", V(0.35, 2.3, 2.3), C(0, 31.9 + k * 1.1, 0) * CYLINDER_Y, DARK)
end
part(T, "Abdomen", V(4.6, 4, 4.2), C(0, 36.6, 0.2), TEAL)
wedge(T, "AbdomenChin", V(4.6, 1.6, 1.4), C(0, 37.6, -2.6) * UP_BACK, TEAL)

-- Cab: a tractor cab of blue-tinted glass on all four sides between the floor and the roof, with
-- green corner posts, dark rails at the top and bottom of the glass, a wiper, a door handle, side
-- mirrors, a roof beacon and work lights.
part(T, "PodFloor", V(7, 1.5, 6.8), C(0, 39.25, 0.2), BLUE)
part(T, "PodRoof", V(7, 3, 6.8), C(0, 49.5, 0.2), BLUE)
part(T, "GlassFront", V(7, 8, 0.2), C(0, 44, -3.2), CAB_GLASS)
part(T, "GlassBack", V(7, 8, 0.2), C(0, 44, 3.55), CAB_GLASS)
for side = -1, 1, 2 do
	part(T, "GlassSide", V(0.2, 8, 6.9), C(side * 3.3, 44, 0.2), CAB_GLASS)
	part(T, "PodEdge", V(0.3, 11.5, 0.3), C(side * 3.55, 44.5, -3.25), GREEN)
	part(T, "PodEdgeBack", V(0.3, 11.5, 0.3), C(side * 3.55, 44.5, 3.65), GREEN)
	for _, y in { 40.15, 47.85 } do
		part(T, "Rail", V(0.3, 0.3, 6.9), C(side * 3.45, y, 0.2), DARK)
	end

	-- Side mirror on an arm from the front post.
	part(
		T,
		"MirrorArm",
		V(1.3, 0.15, 0.15),
		C(side * 4.1, 46.4, -3.4) * A(0, rad(side * 15), 0),
		DARK
	)
	part(T, "Mirror", V(0.2, 1.2, 0.8), C(side * 4.75, 46.2, -3.55), DARK)
	part(
		T,
		"MirrorGlass",
		V(0.05, 1, 0.6),
		C(side * 4.75, 46.2, -3.97) * A(0, rad(90), 0),
		CAB_GLASS
	)

	-- Work lights on the roof's front edge.
	part(T, "WorkLight", V(1, 0.7, 0.5), C(side * 2.6, 50.6, -3.75), DARK)
	part(T, "WorkLens", V(0.8, 0.5, 0.1), C(side * 2.6, 50.6, -4.03), WORK_LIGHT)
end
for _, y in { 40.15, 47.85 } do
	part(T, "Rail", V(7, 0.3, 0.3), C(0, y, -3.3), DARK)
	part(T, "Rail", V(7, 0.3, 0.3), C(0, y, 3.65), DARK)
end
part(T, "Visor", V(5.2, 0.4, 0.2), C(0, 40.6, -3.45), NEON)
wedge(T, "Brow", V(7, 1, 1.4), C(0, 48.4, -3.9) * A(0, 0, math.pi), BLUE)
part(T, "Wiper", V(0.1, 4, 0.1), C(0.5, 42.3, -3.35) * A(0, 0, rad(-25)), DARK)
cyl(T, "WiperPivot", V(0.2, 0.35, 0.35), C(-0.35, 40.5, -3.35) * CYLINDER_Z, DARK)
part(T, "DoorHandle", V(0.15, 0.2, 0.9), C(-3.45, 44, 2), DARK)
part(T, "GrabRail", V(0.15, 4, 0.15), C(-3.75, 44, 3.2), PALE)
cyl(T, "BeaconBase", V(0.3, 1, 1), C(-2, 51.15, -1.8) * CYLINDER_Y, DARK)
ball(T, "Beacon", 0.9, V(-2, 51.5, -1.8), AMBER)

-- Crest fin and whip antennae.
wedge(T, "Crest", V(0.8, 4.5, 6.4), C(0, 53.25, 0.4), GREEN)
part(T, "CrestStripe", V(0.9, 0.3, 4), C(0, 51.4, 1.4), NEON)
-- Each whip is its own bone and wobbles as the Heron walks.
for side = -1, 1, 2 do
	local base = C(side * 2.4, 51, 2.4)
	local bone = if side < 0 then "antenna_L" else "antenna_R"
	cyl(T, "AntennaBase", V(0.6, 1, 1), base * CYLINDER_Y, DARK)
	local whip = base * A(rad(-8), 0, rad(-side * 9))
	cyl(bone, "Antenna", V(10, 0.25, 0.25), whip * C(0, 5, 0) * CYLINDER_Y, DARK)
	ball(bone, "AntennaTip", 0.6, (whip * C(0, 10, 0)).Position, NEON)
end

-- Back: twin coolant tanks.
for side = -1, 1, 2 do
	cyl(T, "Tank", V(9, 1.6, 1.6), C(side * 1.4, 44, 4.5) * CYLINDER_Y, TEAL)
	cyl(T, "TankCap", V(0.4, 1.8, 1.8), C(side * 1.4, 48.6, 4.5) * CYLINDER_Y, PALE)
	cyl(T, "TankBand", V(0.4, 1.8, 1.8), C(side * 1.4, 42, 4.5) * CYLINDER_Y, NEON)
end

-- Cab interior --------------------------------------------------------------------------------
-- Seat block (invisible) at (0, 41.6, 0.9); the pilot's eye is near (0, 45.4, 1.1).
local IN = "torso"
part(IN, "InFloorMat", V(4.8, 0.06, 5.2), C(0, 40.03, 0.1), RUBBER)

-- Suspension seat: a rubber bellows under the pan, a cushion, a back and a headrest.
cyl(IN, "InSeatBellows", V(0.7, 1.4, 1.4), C(0, 40.35, 0.9) * CYLINDER_Y, RUBBER)
part(IN, "InSeatPan", V(2.4, 0.4, 2.4), C(0, 40.9, 0.9), DARK)
part(IN, "InSeatCushion", V(2.4, 0.5, 2.3), C(0, 41.35, 0.9), SEAT)
part(IN, "InSeatBack", V(2.4, 4, 0.5), C(0, 43.3, 2.2) * A(rad(8), 0, 0), SEAT)
part(IN, "InHeadrest", V(1.6, 1, 0.5), C(0, 45.8, 2.55) * A(rad(8), 0, 0), SEAT)

-- Steering: a column rising toward the pilot, a ten-segment wheel with three spokes, a hub and a
-- spinner knob. The wheel is its own bone and turns about the column as the Heron turns.
local WHEEL = C(0, 43.7, -1.2) * A(rad(19.5), 0, 0) -- local Y up the column
local W = "wheel"
local COLUMN_BASE = (WHEEL * C(0, -3.4, 0)).Position
cyl(IN, "InColumn", V(3.4, 0.3, 0.3), WHEEL * C(0, -1.7, 0) * CYLINDER_Y, DARK)
cyl(
	IN,
	"InColumnBoot",
	V(0.6, 0.6, 0.6),
	C(COLUMN_BASE) * A(rad(19.5), 0, 0) * C(0, 0.3, 0) * CYLINDER_Y,
	RUBBER
)
local RIM, SEGMENTS = 0.8, 10
for k = 0, SEGMENTS - 1 do
	local a = k * 2 * math.pi / SEGMENTS
	local length = 2 * RIM * math.sin(math.pi / SEGMENTS) + 0.06
	part(
		W,
		"InWheelRim",
		V(length, 0.16, 0.16),
		WHEEL * A(0, -a, 0) * C(RIM, 0, 0) * A(0, -math.pi / 2, 0),
		RUBBER
	)
end
for _, a in { 90, 210, 330 } do
	part(W, "InWheelSpoke", V(RIM, 0.08, 0.14), WHEEL * A(0, rad(-a), 0) * C(RIM / 2, 0, 0), DARK)
end
cyl(W, "InWheelHub", V(0.2, 0.45, 0.45), WHEEL * CYLINDER_Y, KNOB_YELLOW)
local spinner = WHEEL * A(0, rad(-30), 0) * C(RIM, 0, 0)
cyl(W, "InSpinner", V(0.35, 0.12, 0.12), spinner * C(0, 0.17, 0) * CYLINDER_Y, CHROME)
ball(W, "InSpinnerKnob", 0.24, (spinner * C(0, 0.38, 0)).Position, KNOB_RED)

-- Gauge pod behind the wheel, facing the pilot: a tachometer and a speedometer with needles, and a
-- column of warning lamps between them.
local POD = C(0, 43.6, -2.15) * A(rad(-15), 0, 0)
part(IN, "InGaugePod", V(2, 0.9, 0.5), POD, DARK)
for side = -1, 1, 2 do
	local face = POD * C(side * 0.55, 0.02, 0.26)
	cyl(IN, "InGaugeRim", V(0.06, 0.72, 0.72), face * CYLINDER_Z, CHROME)
	cyl(IN, "InGauge", V(0.07, 0.62, 0.62), face * C(0, 0, 0.01) * CYLINDER_Z, GAUGE)
	part(
		IN,
		"InNeedle",
		V(0.04, 0.24, 0.03),
		face * C(0, 0, 0.06) * A(0, 0, rad(side * 40 - 20)) * C(0, 0.11, 0),
		NEEDLE
	)
end
for index, style in { GREEN_LAMP, AMBER, RED_LAMP } do
	ball(IN, "InWarnLamp", 0.14, (POD * C(0, 0.3 - index * 0.17, 0.26)).Position, style)
end

-- Pedals: a clutch on the left, two brakes on the right.
for _, x in { -0.8, 0.45, 0.95 } do
	part(IN, "InPedalArm", V(0.12, 0.8, 0.12), C(x, 40.6, -2.25) * A(rad(-30), 0, 0), DARK)
	part(IN, "InPedal", V(0.42, 0.08, 0.55), C(x, 40.8, -1.95) * A(rad(30), 0, 0), RUBBER)
end

-- Right armrest console: a joystick, a hand throttle and a grid of colored buttons.
part(IN, "InArmConsole", V(0.9, 1.4, 2.6), C(1.95, 41.9, 0.6), DARK)
part(IN, "InArmPad", V(0.9, 0.2, 1.4), C(1.95, 42.7, 1.2), SEAT)
cyl(IN, "InJoystick", V(0.6, 0.15, 0.15), C(1.95, 42.9, -0.35) * CYLINDER_Y, DARK)
ball(IN, "InJoystickKnob", 0.38, V(1.95, 43.25, -0.35), RUBBER)
part(IN, "InThrottle", V(0.1, 0.6, 0.1), C(1.95, 42.85, 0.25) * A(rad(-20), 0, 0), CHROME)
ball(IN, "InThrottleKnob", 0.24, V(1.95, 43.15, 0.15), AMBER)
for row, styles in { { GREEN_LAMP, KNOB_YELLOW }, { RED_LAMP, SCREEN }, { AMBER, PALE } } do
	for column, style in styles do
		cyl(
			IN,
			"InButton",
			V(0.06, 0.18, 0.18),
			C(1.75 + (column - 1) * 0.4, 42.63, 0.15 - row * 0.32 + 1.5) * CYLINDER_Y,
			style
		)
	end
end

-- Left side: a range lever and a shuttle lever on a floor box, and a parking brake.
part(IN, "InShiftBox", V(0.8, 0.8, 1.6), C(-2, 40.4, 0.2), DARK)
for index, z in { -0.2, 0.5 } do
	local lever = C(-2, 40.8, z) * A(rad(-15), 0, 0)
	part(IN, "InLever", V(0.1, 1.8, 0.1), lever * C(0, 0.9, 0), CHROME)
	ball(
		IN,
		"InLeverKnob",
		0.3,
		(lever * C(0, 1.85, 0)).Position,
		if index == 1 then KNOB_RED else KNOB_YELLOW
	)
end
part(IN, "InParkBrake", V(0.15, 0.15, 1.2), C(-1.7, 41.1, 1.4) * A(rad(20), 0, 0), DARK)

-- Corner display on a stalk by the right front post, turned toward the pilot.
local DISPLAY = C(2, 44.6, -1.9) * A(0, rad(35), 0) * A(rad(-10), 0, 0)
part(IN, "InDisplayStalk", V(0.15, 4.2, 0.15), C(2.2, 42.1, -2.1), DARK)
part(IN, "InDisplayBezel", V(1.3, 0.95, 0.12), DISPLAY, DARK)
part(IN, "InDisplay", V(1.15, 0.8, 0.02), DISPLAY * C(0, 0, 0.065), SCREEN)

-- Overhead console: a radio, four rocker switches and a dome light.
part(IN, "InOverhead", V(3, 0.4, 1.2), C(0, 47.8, -1.9), DARK)
part(IN, "InRadio", V(1, 0.08, 0.35), C(-0.6, 47.58, -1.9), GREEN_LAMP)
for k = 0, 3 do
	part(
		IN,
		"InRocker",
		V(0.18, 0.08, 0.3),
		C(0.3 + k * 0.3, 47.58, -1.9),
		if k == 0 then AMBER else PALE
	)
end
part(IN, "InDomeLight", V(0.8, 0.08, 0.5), C(0, 47.96, 0.8), WORK_LIGHT)

-- Arms (decorative) ---------------------------------------------------------------------------
-- Long thin arms hanging past the hips; pivots at x +-5.6 so they clear the legs.
for side = -1, 1, 2 do
	local s = side < 0 and "_L" or "_R"
	local upper, fore = "upperArm" .. s, "foreArm" .. s
	local ax = side * 5.6
	part(upper, "ShoulderMount" .. s, V(1.4, 2, 2.2), C(side * 4.2, 48.5, 0.3), DARK)
	ball(upper, "Shoulder" .. s, 2.6, V(ax, 48.5, 0.3), PALE)
	part(upper, "UpperArm" .. s, V(1, 10.4, 1.2), C(ax, 42.6, 0.3), TEAL)
	part(upper, "UpperArmStripe" .. s, V(0.1, 6, 0.4), C(ax + side * 0.55, 42.6, 0.3), GREEN)

	ball(fore, "Elbow" .. s, 1.6, V(ax, 37, 0.3), PALE)
	part(fore, "Forearm" .. s, V(0.9, 10.4, 1.1), C(ax, 31.2, 0.3), BLUE)
	cyl(fore, "Cuff" .. s, V(0.6, 1.6, 1.6), C(ax, 26, 0.3) * CYLINDER_Y, NEON)
	for k = -1, 1 do
		local root = C(ax, 25.4, 0.3 + k * 0.45) * A(rad(k * 12), 0, 0)
		part(fore, "Finger" .. s, V(0.3, 3.6, 0.3), root * C(0, -1.8, 0), PALE)
	end
end

local bones = {
	{ name = "pelvis", pivot = V(0, HIP_Y, HIP_Z) },
	{ name = "torso", parent = "pelvis", pivot = V(0, 31.5, 0) },
	{ name = "upperArm_L", parent = "torso", pivot = V(-5.6, 48.5, 0.3) },
	{ name = "foreArm_L", parent = "upperArm_L", pivot = V(-5.6, 37, 0.3) },
	{ name = "upperArm_R", parent = "torso", pivot = V(5.6, 48.5, 0.3) },
	{ name = "foreArm_R", parent = "upperArm_R", pivot = V(5.6, 37, 0.3) },
	{ name = "wheel", parent = "torso", pivot = V(0, 43.7, -1.2), steer = V(0, 0.943, 0.334) },
	{ name = "antenna_L", parent = "torso", pivot = V(-2.4, 51, 2.4), wobble = true },
	{ name = "antenna_R", parent = "torso", pivot = V(2.4, 51, 2.4), wobble = true },
}
for _, bone in legBones do
	table.insert(bones, bone)
end

local CAB_LO, CAB_HI = V(-2.5, 40, -2.6), V(2.5, 48, 2.8)
local collision = shell(V(-3.5, 34.5, -3.4), V(3.5, 51, 3.6), CAB_LO, CAB_HI)
table.insert(collision, { size = V(6, 6, 3), offset = C(0, 31.5, 0) }) -- hips and spine y 28.5..34.5

return {
	name = "Heron",
	speed = 26,
	turnRate = 0.9,
	footprint = Vector2.new(12, 20),
	collision = collision,
	bones = bones,
	seatBone = "torso",
	cab = { center = (CAB_LO + CAB_HI) / 2, size = CAB_HI - CAB_LO },
	exit = C(0, 3, 10) * A(0, math.pi, 0), -- on the ground behind, facing away
	cameraFocus = V(0, 54, 0),
	cockpitCamera = true,
	gait = "mech",
	acceleration = 12,
	braking = 16,
	coasting = 12,
	turnAcceleration = 1.8,
	turnInPlace = true,
	parkingBrake = true,
	uprightTorque = 6,
	stepsOver = true,
	seats = { C(0, 41.6, 0.9) },
	pieces = pieces,
}
