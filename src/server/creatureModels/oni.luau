-- Oni: red-skinned Japanese ogre (aka-oni), 2.6 m tall, in a menacing ready stance. Left foot
-- forward, right foot back, knees bent; the right fist rests an iron kanabo on the right shoulder
-- (club up and back), the left arm reaches forward and down with clawed fingers.
-- Scale: 4 studs = 1 m. Feet on y 0, hip joints y 4.85, belt y 5.5, shoulder joints y 8.05,
-- chin y 8.6, hair crown y 10.43, horn tips y 11.15, kanabo tip (2, 11, 3.2).
-- Limbs are cylinders between joint landmarks; the knees are solved from hip, ankle and limb lengths.

local rgb = Color3.fromRGB
local M = Enum.Material
local A = CFrame.Angles
local C = CFrame.new
local V = Vector3.new
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball
local rad = math.rad
local UP = V(0, 1, 0)
local FORWARD = V(0, 0, -1)
local CYLINDER_Y = A(0, 0, rad(90)) -- cylinder axis along Y

-- Palette: { color, material, reflectance, transparency }.
local SKIN = { rgb(146, 42, 34), M.Leather } -- main muscle masses
local SKIN_LIGHT = { rgb(166, 58, 44), M.Leather } -- top-lit masses
local SKIN_SHADE = { rgb(116, 30, 26), M.Leather } -- undersides and back
local SKIN_FACE = { rgb(154, 48, 38), M.Plaster }
local SKIN_JAW = { rgb(134, 38, 32), M.Plaster }
local SKIN_FLUSH = { rgb(124, 30, 30), M.Plaster } -- nose, cheeks
local SKIN_ROUGH = { rgb(128, 56, 44), M.Slate } -- calluses: knees, elbows, heels, knuckles
local NAIL = { rgb(44, 36, 32), M.Slate }
local EYE = { rgb(255, 205, 60), M.Neon }
local MOUTH = { rgb(38, 12, 12), M.Slate }
local TUSK = { rgb(220, 208, 180), M.Marble }
local FANG = { rgb(200, 186, 156), M.Marble }
local HORN_ROOT = { rgb(70, 58, 46), M.Slate }
local HORN_MID = { rgb(138, 118, 88), M.Marble }
local HORN_TIP = { rgb(206, 190, 158), M.Marble }
local HAIR = { rgb(26, 23, 21), M.Grass }
local HAIR_GREY = { rgb(46, 41, 37), M.Grass }
local TIGER = { rgb(186, 116, 42), M.Grass }
local TIGER_WORN = { rgb(162, 98, 38), M.Grass }
local TIGER_PALE = { rgb(210, 182, 136), M.Grass }
local STRIPE = { rgb(30, 24, 20), M.Fabric }
local ROPE = { rgb(142, 118, 80), M.Fabric }
local ROPE_DARK = { rgb(108, 86, 58), M.Fabric }
local IRON = { rgb(50, 50, 52), M.CorrodedMetal }
local IRON_WORN = { rgb(84, 82, 78), M.Metal, 0.05 } -- polished where handled
local STUD = { rgb(104, 100, 92), M.Metal, 0.08 }
local RUST = { rgb(96, 54, 34), M.CorrodedMetal }
local GRIP = { rgb(56, 38, 28), M.Leather }

local pieces = {}

local function part(name, size, offset, style, shape, class)
	table.insert(pieces, {
		name = name,
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

local function ball(name, diameter, at, style)
	part(name, V(diameter, diameter, diameter), C(at), style, BALL)
end

local function cyl(name, size, offset, style)
	part(name, size, offset, style, CYL)
end

local function wedge(name, size, offset, style)
	part(name, size, offset, style, nil, "WedgePart")
end

-- The part of `v` perpendicular to the unit vector `axis`, normalized.
local function across(v, axis)
	return (v - axis * v:Dot(axis)).Unit
end

-- Frame at `at` with local X along `dir` and local Y as close to world up as possible.
local function alongX(at, dir)
	local x = dir.Unit
	local y = across(UP, x)
	return CFrame.fromMatrix(at, x, y, x:Cross(y))
end

-- Frame at `at` with local Y along `dir` and local Z as close to `back` as possible.
local function alongY(at, dir, back)
	local y = dir.Unit
	local z = across(back, y)
	return CFrame.fromMatrix(at, y:Cross(z), y, z)
end

-- Cylinder of diameter `d` over the fraction t0..t1 of the segment a -> b, shifted by `shift`.
local function segment(name, a, b, d, style, t0, t1, shift)
	local p0, p1 = a:Lerp(b, t0 or 0), a:Lerp(b, t1 or 1)
	local at = p0:Lerp(p1, 0.5) + (shift or Vector3.zero)
	cyl(name, V((p1 - p0).Magnitude, d, d), alongX(at, b - a), style)
end

local function suffix(side)
	return side < 0 and "L" or "R"
end

-- Head ----------------------------------------------------------------------------------------
-- Cranium ball with a block face plane and jaw; mouth open on two tusks and two fangs.
ball("Head", 1.25, V(0, 9.5, -0.3), SKIN_FACE)
part("Face", V(1, 0.72, 0.5), C(0, 9.2, -0.78), SKIN_FACE)
part("Jaw", V(1.1, 0.42, 0.95), C(0, 8.86, -0.62), SKIN_JAW)
ball("Chin", 0.44, V(0, 8.78, -0.95), SKIN_JAW)
ball("Nose", 0.42, V(0, 9.17, -1.12), SKIN_FLUSH)
part("Mouth", V(0.62, 0.16, 0.14), C(0, 8.95, -1.14), MOUTH)
part("UpperLip", V(0.66, 0.12, 0.18), C(0, 9.04, -1.11), SKIN_JAW)
for _, side in { -1, 1 } do
	local s = suffix(side)
	-- Brows angle down toward the center.
	cyl(
		"Brow" .. s,
		V(0.62, 0.3, 0.3),
		C(side * 0.3, 9.52, -1) * A(0, 0, rad(side * 14)),
		SKIN_FACE
	)
	ball("Eye" .. s, 0.2, V(side * 0.26, 9.33, -0.98), EYE)
	ball("Cheek" .. s, 0.42, V(side * 0.42, 9.1, -0.86), SKIN_FLUSH)
	wedge(
		"Tusk" .. s,
		V(0.1, 0.4, 0.12),
		C(side * 0.24, 9.06, -1.16) * A(0, rad(side * -8), 0),
		TUSK
	)
	wedge("Fang" .. s, V(0.08, 0.2, 0.1), C(side * 0.1, 8.96, -1.17) * A(0, 0, math.pi), FANG)
	wedge(
		"Ear" .. s,
		V(0.1, 0.5, 0.36),
		C(side * 0.66, 9.45, -0.25) * A(0, rad(side * -12), 0),
		SKIN_JAW
	)
end

-- Horns: three segments from the hairline, sweeping out, then up, then back to a point.
for _, side in { -1, 1 } do
	local s = suffix(side)
	local base = V(side * 0.33, 9.95, -0.66)
	local bend = base + V(side * 0.45, 1, -0.2).Unit * 0.5
	local top = bend + V(side * 0.18, 1, 0.08).Unit * 0.42
	local tipDir = V(side * 0.02, 1, 0.3).Unit
	segment("HornRoot" .. s, base, bend, 0.36, HORN_ROOT, -0.1)
	segment("HornMid" .. s, bend, top, 0.26, HORN_MID, -0.12)
	wedge(
		"HornTip" .. s,
		V(0.18, 0.36, 0.2),
		alongY(top + tipDir * 0.16, tipDir, FORWARD),
		HORN_TIP
	)
end

-- Mane: black crown and back, grizzled side tufts.
ball("HairCrown", 1.15, V(0, 9.85, 0), HAIR)
ball("HairBack", 1.2, V(0, 9.35, 0.28), HAIR)
for _, side in { -1, 1 } do
	ball("HairSide" .. suffix(side), 0.75, V(side * 0.48, 9.42, 0.22), HAIR_GREY)
end
part("HairNape", V(1, 0.6, 0.5), C(0, 8.95, 0.42) * A(rad(20), 0, 0), HAIR)

-- Torso ---------------------------------------------------------------------------------------
cyl("Neck", V(0.9, 1.05, 1.05), C(0, 8.55, -0.1) * CYLINDER_Y, SKIN)
part("Ribcage", V(2.7, 1.7, 1.9), C(0, 7.35, 0.05) * A(rad(-6), 0, 0), SKIN)
part("Abdomen", V(2.5, 1.3, 1.6), C(0, 6.05, 0.05), SKIN)
ball("LowerBelly", 1, V(0, 5.75, -0.45), SKIN)
for _, side in { -1, 1 } do
	local s = suffix(side)
	part(
		"Pec" .. s,
		V(1.45, 0.85, 0.5),
		C(side * 0.72, 7.6, -0.98) * A(rad(-6), rad(side * -12), 0),
		SKIN_LIGHT
	)
	ball("Lat" .. s, 1.3, V(side * 1.25, 7, 0.3), SKIN_SHADE)
	-- Trapezius: length along Z, slope falling from the neck to the shoulder.
	wedge(
		"Trap" .. s,
		V(1.5, 0.55, 1.3),
		C(side * 0.8, 8.45, 0.25) * A(0, rad(side * -90), 0),
		SKIN
	)
	cyl("Erector" .. s, V(1.8, 0.55, 0.55), C(side * 0.33, 6.4, 0.75) * CYLINDER_Y, SKIN_SHADE)
	part("Abs1" .. s, V(0.62, 0.5, 0.3), C(side * 0.34, 6.55, -0.78), SKIN_LIGHT)
	part("Abs2" .. s, V(0.62, 0.5, 0.3), C(side * 0.34, 6, -0.78), SKIN)
	ball("Oblique" .. s, 1.05, V(side * 1.05, 5.9, -0.05), SKIN_SHADE)
end

-- Loincloth -----------------------------------------------------------------------------------
-- Tiger pelt wrapped at the hips under a rope belt; knot at the left front, tail at the back left.
part("HipWrap", V(2.7, 0.95, 1.75), C(0, 5, 0.1), TIGER)
part("Belt", V(2.85, 0.26, 2.1), C(0, 5.5, 0.08), ROPE)
ball("BeltKnot", 0.4, V(-0.55, 5.48, -1.02), ROPE_DARK)
part("FrontFlap", V(1.15, 1.25, 0.14), C(0, 4.1, -0.84) * A(rad(5), 0, 0), TIGER)
part("BackFlap", V(1.4, 1.4, 0.14), C(0, 4.05, 1.12) * A(rad(-6), 0, 0), TIGER_PALE)
for _, side in { -1, 1 } do
	local s = suffix(side)
	ball("Glute" .. s, 1.2, V(side * 0.52, 4.95, 0.55), TIGER_WORN)
	part(
		"SideFlap" .. s,
		V(0.14, 0.85, 1.2),
		C(side * 1.62, 4.4, 0.1) * A(0, 0, rad(side * 8)),
		TIGER_WORN
	)
end
part("StripeWrapL", V(0.14, 0.7, 0.05), C(-0.8, 5, -0.79) * A(0, 0, rad(-25)), STRIPE)
part("StripeWrapR", V(0.14, 0.6, 0.05), C(0.75, 4.95, -0.79) * A(0, 0, rad(30)), STRIPE)
part("StripeFront", V(0.7, 0.12, 0.05), C(0.1, 3.95, -0.93) * A(rad(5), 0, rad(-18)), STRIPE)
part("StripeBack", V(0.8, 0.13, 0.05), C(-0.1, 4, 1.21) * A(rad(-6), 0, rad(15)), STRIPE)
part("StripeSideR", V(0.05, 0.12, 0.7), C(1.7, 4.45, 0) * A(rad(20), 0, rad(8)), STRIPE)
local TAIL_ROOT, TAIL_BEND, TAIL_END = V(-1, 5.25, 1), V(-1.1, 4.25, 1.18), V(-1.18, 3.35, 1.1)
segment("Tail", TAIL_ROOT, TAIL_BEND, 0.24, TIGER)
segment("TailTip", TAIL_BEND, TAIL_END, 0.2, STRIPE, -0.05)

-- Legs ----------------------------------------------------------------------------------------
local THIGH, SHIN = 2.3, 2.2
local LEGS = {
	{ side = -1, hip = V(-0.95, 4.85, 0.1), ankle = V(-1.3, 0.55, -1.05), yaw = 14 }, -- forward
	{ side = 1, hip = V(0.95, 4.85, 0.1), ankle = V(1.35, 0.55, 1), yaw = -16 }, -- back
}

-- Knee in the plane of hip, ankle and the forward direction, bending toward -Z.
local function solveKnee(hip, ankle)
	local reach = ankle - hip
	local dist, axis = reach.Magnitude, reach.Unit
	local along = (THIGH * THIGH - SHIN * SHIN + dist * dist) / (2 * dist)
	local out = math.sqrt(math.max(0, THIGH * THIGH - along * along))
	return hip + axis * along + across(FORWARD, axis) * out
end

for _, leg in LEGS do
	local side, hip, ankle = leg.side, leg.hip, leg.ankle
	local s = suffix(side)
	local knee = solveKnee(hip, ankle)
	local thighFront = across(FORWARD, (knee - hip).Unit)
	local shinFront = across(FORWARD, (ankle - knee).Unit)
	local outward = V(side, 0, 0)

	segment("Thigh" .. s, hip, knee, 1.4, SKIN, -0.05)
	ball(
		"QuadOuter" .. s,
		0.95,
		hip:Lerp(knee, 0.5) + outward * 0.3 + thighFront * 0.12,
		SKIN_LIGHT
	)
	ball(
		"QuadTeardrop" .. s,
		0.66,
		hip:Lerp(knee, 0.82) - outward * 0.26 + thighFront * 0.2,
		SKIN_LIGHT
	)
	segment("Hamstring" .. s, hip, knee, 1, SKIN_SHADE, 0.15, 0.85, thighFront * -0.3)
	ball("Knee" .. s, 0.62, knee + thighFront * 0.2, SKIN_ROUGH)
	segment("Shin" .. s, knee, ankle, 0.82, SKIN)
	ball("Calf" .. s, 1, knee:Lerp(ankle, 0.3) - shinFront * 0.25, SKIN)
	segment("Achilles" .. s, knee, ankle, 0.45, SKIN_SHADE, 0.5, 0.95, shinFront * -0.15)
	ball("Ankle" .. s, 0.55, ankle, SKIN)

	-- Foot frame: on the ground under the ankle, turned out by `yaw`.
	local foot = C(ankle.X, 0, ankle.Z) * A(0, rad(leg.yaw), 0)
	part("Foot" .. s, V(0.75, 0.42, 1.25), foot * C(0, 0.21, -0.4), SKIN)
	ball("Heel" .. s, 0.55, (foot * C(0, 0.275, 0.25)).Position, SKIN_ROUGH)
	part("Toes" .. s, V(0.78, 0.3, 0.4), foot * C(0, 0.15, -1.15), SKIN)
	ball("BigToe" .. s, 0.32, (foot * C(-side * 0.22, 0.16, -1.3)).Position, SKIN)
	part("ToeClaws" .. s, V(0.74, 0.1, 0.12), foot * C(0, 0.1, -1.4), NAIL)
end

-- Arms ----------------------------------------------------------------------------------------
local ARMS = {
	-- Left: reaching forward and down, open clawed hand.
	{
		side = -1,
		shoulder = V(-2, 8.05, 0.05),
		elbow = V(-2.55, 6.4, -0.4),
		wrist = V(-2.4, 5.85, -1.95),
	},
	-- Right: fist in front of the shoulder, holding the kanabo.
	{
		side = 1,
		shoulder = V(2, 8.05, 0.05),
		elbow = V(2.4, 6.4, -0.55),
		wrist = V(2.3, 7.55, -1.75),
	},
}

for _, arm in ARMS do
	local side, shoulder, elbow, wrist = arm.side, arm.shoulder, arm.elbow, arm.wrist
	local s = suffix(side)
	-- Biceps side of the upper arm: toward the forearm.
	local inner = across((wrist - elbow).Unit, (elbow - shoulder).Unit)

	ball("Deltoid" .. s, 1.25, V(side * 2.1, 8.2, 0), SKIN_LIGHT)
	segment("UpperArm" .. s, shoulder, elbow, 0.95, SKIN)
	ball("Biceps" .. s, 0.75, shoulder:Lerp(elbow, 0.55) + inner * 0.25, SKIN_LIGHT)
	segment("Triceps" .. s, shoulder, elbow, 0.7, SKIN_SHADE, 0.15, 0.85, inner * -0.22)
	ball("Elbow" .. s, 0.55, elbow - inner * 0.12, SKIN_ROUGH)
	segment("ForearmUpper" .. s, elbow, wrist, 0.88, SKIN, -0.05, 0.6)
	segment("ForearmLower" .. s, elbow, wrist, 0.58, SKIN_SHADE, 0.5, 1)
	segment("Cuff" .. s, elbow, wrist, 0.72, IRON, 0.72, 0.98)
end

-- Left hand: palm down, fingers curled into claws.
do
	local wrist = ARMS[1].wrist
	local z = -V(0.05, -0.45, -1).Unit
	local y = across(UP, z)
	local hand = CFrame.fromMatrix(wrist, y:Cross(z), y, z)
	part("PalmL", V(0.64, 0.24, 0.62), hand * C(0, 0, -0.33), SKIN)
	local fingers = hand * C(0, 0, -0.64) * A(rad(-35), 0, 0)
	part("FingersL", V(0.66, 0.18, 0.55), fingers * C(0, 0, -0.26), SKIN_ROUGH)
	local tips = (fingers * C(0, 0, -0.5)).Position
	local claws = hand.Rotation * A(rad(-75), 0, 0) + tips
	part("ClawsL", V(0.62, 0.1, 0.22), claws * C(0, -0.02, -0.08), NAIL)
	segment(
		"ThumbL",
		(hand * C(0.3, 0, -0.1)).Position,
		(hand * C(0.45, -0.08, -0.55)).Position,
		0.22,
		SKIN
	)
end

-- Kanabo ----------------------------------------------------------------------------------------
-- Iron club: grip in the right fist, axis up and back over the right shoulder. Positions are
-- distances along the axis from the grip center.
local GRIP_AT = ARMS[2].wrist + V(0, 0.3, -1).Unit * 0.4
local CLUB_AXIS = (V(2.15, 9.15, 0.25) - GRIP_AT).Unit
local SHAFT_FROM, SHAFT_TO = 1.7, 6.1
local STUD_RING = 0.4

-- Right fist wrapped around the grip (local Y along the club, +Z toward the wrist).
do
	local fist = alongY(GRIP_AT, CLUB_AXIS, ARMS[2].wrist - GRIP_AT)
	part("FistR", V(0.56, 0.62, 0.5), fist * C(0, 0, 0.12), SKIN)
	part("FingersR", V(0.5, 0.6, 0.26), fist * C(0, 0, -0.28), SKIN_ROUGH)
	ball("ThumbR", 0.28, (fist * C(-0.3, 0.22, -0.05)).Position, SKIN)
	part("ClawsR", V(0.46, 0.56, 0.08), fist * C(0, 0, -0.44), NAIL)
end

local club = alongY(GRIP_AT, CLUB_AXIS, V(1, 0, 0))
local function onClub(t, x, z)
	return club * C(x or 0, t, z or 0)
end
local function clubRing(name, t, length, d, style)
	cyl(name, V(length, d, d), alongX(onClub(t).Position, CLUB_AXIS), style)
end

ball("KanaboPommel", 0.46, onClub(-0.82).Position, IRON_WORN)
clubRing("KanaboGrip", -0.05, 1.3, 0.36, GRIP)
clubRing("KanaboCollar", 0.7, 0.2, 0.56, IRON_WORN)
clubRing("KanaboNeck", 1.3, 1.1, 0.58, IRON)
-- Two square blocks, one turned 45 degrees about the axis, form an octagonal shaft.
local shaftSize = V(0.8, SHAFT_TO - SHAFT_FROM, 0.8)
local shaftAt = onClub((SHAFT_FROM + SHAFT_TO) / 2)
part("KanaboShaftA", shaftSize, shaftAt, IRON)
part("KanaboShaftB", shaftSize, shaftAt * A(0, rad(45), 0), IRON)
clubRing("KanaboBandLow", 2, 0.18, 0.94, IRON_WORN)
clubRing("KanaboBandHigh", 5.7, 0.18, 0.94, IRON_WORN)
clubRing("KanaboCap", 6.2, 0.22, 0.84, RUST)
-- Studs: two staggered rings of four on the octagon faces.
for ring, t in { 3, 4.5 } do
	for k = 1, 4 do
		local angle = rad((k - 1) * 90 + (ring - 1) * 45)
		local at = onClub(t, math.cos(angle) * STUD_RING, math.sin(angle) * STUD_RING).Position
		ball("KanaboStud" .. ring .. k, 0.24, at, STUD)
	end
end

return {
	name = "Oni",
	rootSize = V(3.4, 3.6, 2),
	hipHeight = 4.4,
	reach = 7,
	pieces = pieces,
}
