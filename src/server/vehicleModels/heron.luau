-- Heron: a tall, skinny teal-and-blue stilt walker. Long blade legs on bird feet, a slim cockpit
-- tower with a crest fin and whip antennae, and long thin arms with three-finger hands.
-- Scale: 4 studs = 1 m. Rest pose = parked pose (knees bent). Hip pivots y 29.6, cockpit tower
-- y 38.5..51, cab cavity x -2.5..2.5, y 40..48, z -2.6..2.8 (only `In*` pieces inside it).
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

-- Wedge orientations (WedgePart default: slope rises from the -Z bottom edge to the +Z top edge).
local UP_BACK = A(0, math.pi, 0) -- slope rises toward -Z, faces up and back

-- Palette: { color, material, reflectance, transparency }.
local TEAL = { rgb(0, 138, 150), M.SmoothPlastic, 0.1 }
local GREEN = { rgb(40, 172, 118), M.SmoothPlastic, 0.1 }
local BLUE = { rgb(28, 84, 168), M.SmoothPlastic, 0.1 }
local DARK = { rgb(26, 34, 42), M.Metal }
local PALE = { rgb(220, 234, 232), M.SmoothPlastic }
local NEON = { rgb(80, 255, 170), M.Neon }
local GLASS = { rgb(150, 220, 215), M.Glass, 0.15, 0.65 }
local SEAT = { rgb(30, 60, 70), M.Fabric }
local SCREEN = { rgb(80, 220, 255), M.Neon }

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
local BEND = rad(25)
local HIP_Y, HIP_Z, HIP_X = 29.6, 0, 3.4
local THIGH, SHIN = 15, 15
local legBones = {}

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

	-- Thigh: a slim teal blade with a green stripe and a rod behind it.
	cyl(thigh, "Hip" .. s, V(1.6, 2.8, 2.8), thighF, DARK)
	part(thigh, "Thigh" .. s, V(1.4, 13, 2.2), thighF * C(0, -7, 0), TEAL)
	part(thigh, "ThighStripe" .. s, V(0.2, 9, 0.6), thighF * C(side * 0.75, -7, -0.4), GREEN)
	cyl(thigh, "ThighRod" .. s, V(11, 0.5, 0.5), thighF * C(0, -7, 1.5) * CYLINDER_Y, PALE)

	-- Shin: a knee disc, a blue blade with a forward shin guard, a neon ankle ring.
	cyl(shin, "Knee" .. s, V(1.8, 2.6, 2.6), C(knee), PALE)
	part(shin, "Shin" .. s, V(1.2, 13.2, 1.8), shinF * C(0, -7, 0), BLUE)
	part(shin, "ShinGuard" .. s, V(1.5, 6, 0.4), shinF * C(0, -4, -1.05), TEAL)
	part(shin, "ShinLight" .. s, V(0.3, 4, 0.1), shinF * C(0, -4, -1.3), NEON)
	cyl(shin, "AnkleRing" .. s, V(0.5, 1.9, 1.9), shinF * C(0, -13.4, 0) * CYLINDER_Y, NEON)

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

-- Cockpit pod: slim walls, floor and roof around the cab; the seat shows through the window.
part(T, "PodFloor", V(7, 1.5, 6.8), C(0, 39.25, 0.2), BLUE)
part(T, "PodRoof", V(7, 3, 6.8), C(0, 49.5, 0.2), BLUE)
for side = -1, 1, 2 do
	part(T, "PodWall", V(1, 8.4, 6.8), C(side * 3, 44.2, 0.2), TEAL)
	part(T, "PodEdge", V(0.3, 11.5, 0.3), C(side * 3.55, 44.5, -3.25), GREEN)
	part(T, "PodEdgeBack", V(0.3, 11.5, 0.3), C(side * 3.55, 44.5, 3.65), GREEN)
	part(T, "WindowPost", V(0.5, 8.4, 0.6), C(side * 2.3, 44.2, -3), TEAL)
end
part(T, "PodBack", V(5, 8.4, 0.6), C(0, 44.2, 3.3), TEAL)
part(T, "Window", V(4.2, 7.6, 0.2), C(0, 44.6, -3.1), GLASS)
part(T, "Visor", V(5.2, 0.4, 0.2), C(0, 40.6, -3.45), NEON)
wedge(T, "Brow", V(7, 1, 1.4), C(0, 48.4, -3.9) * A(0, 0, math.pi), BLUE)

-- Crest fin and whip antennae.
wedge(T, "Crest", V(0.8, 4.5, 6.4), C(0, 53.25, 0.4), GREEN)
part(T, "CrestStripe", V(0.9, 0.3, 4), C(0, 51.4, 1.4), NEON)
for side = -1, 1, 2 do
	local base = C(side * 2.4, 51, 2.4)
	cyl(T, "AntennaBase", V(0.6, 1, 1), base * CYLINDER_Y, DARK)
	local whip = base * A(rad(-8), 0, rad(-side * 9))
	cyl(T, "Antenna", V(10, 0.25, 0.25), whip * C(0, 5, 0) * CYLINDER_Y, DARK)
	ball(T, "AntennaTip", 0.6, (whip * C(0, 10, 0)).Position, NEON)
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
part(IN, "InSeatPan", V(2.4, 0.4, 2.4), C(0, 40.9, 0.9), DARK)
part(IN, "InSeatBack", V(2.4, 4, 0.5), C(0, 43.3, 2.2) * A(rad(8), 0, 0), SEAT)
part(IN, "InHeadrest", V(1.6, 1, 0.5), C(0, 46, 2.45) * A(rad(8), 0, 0), SEAT)
part(IN, "InDash", V(4, 1, 1), C(0, 42.6, -2.2), DARK)
part(IN, "InScreen", V(3, 0.8, 0.1), C(0, 43.4, -2.4) * A(rad(-20), 0, 0), SCREEN)

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
