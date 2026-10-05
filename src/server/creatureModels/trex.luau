-- T-Rex: adult Tyrannosaurus rex after Scott Hartman's skeletal (Sue/Stan proportions) and
-- post-2017 paleoart. Horizontal spine with the hips as the pivot and trunk high point, deep narrow
-- skull, thick S-curved neck, long counterbalancing tail, tiny two-fingered arms. Fine pebbly
-- scales and no feathers (Bell et al. 2017); lips cover the teeth when closed (Cullen et al. 2023),
-- so the open jaws show only the tooth tips. Olive-umber back, brown flanks, buff countershaded
-- belly, dorsal bands on the rear tail, a healed bite scar on the left cheek.
-- Pose: mid-stride, left leg forward and planted, right leg trailing; jaws open 14 degrees; the
-- tail swings to +X toward the tip. Narrow gauge (per trackways): knees out at x +-2.75, feet in
-- at x +-1.6.
-- Scale: 12.3 m nose to tail = 41 studs (3.25 studs/m). Hip joints (+-2.5, 11.2, 1.4), sacral
-- ridge top y 14.65, shoulders z -8, jaw joint (0, 13.55, -12.6), eyes y 15.55, snout tip z -17.65,
-- brow top y 16.53, tail tip (2, 9.55, 23.2).

local rgb = Color3.fromRGB
local M = Enum.Material
local A = CFrame.Angles
local C = CFrame.new
local V = Vector3.new
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball
local rad = math.rad

-- Wedge pointing down: full top and back faces, slope faces down and forward (teeth, hand claws).
local DOWN = A(0, 0, math.pi)

-- Palette: { color, material, reflectance, transparency }.
-- Dorsal over flank over belly; adjacent pieces alternate between the two tones of a pair.
local DORSAL = { rgb(72, 64, 49), M.Slate }
local DORSAL_2 = { rgb(82, 72, 54), M.Slate }
local FLANK = { rgb(103, 91, 69), M.Pebble }
local FLANK_2 = { rgb(113, 100, 76), M.Pebble }
local MOTTLE = { rgb(80, 70, 54), M.Slate } -- blotches and tail bands
local BELLY = { rgb(166, 148, 116), M.Leather }
local BELLY_2 = { rgb(150, 134, 104), M.Leather } -- throat, chest, pubic boot
local FACE = { rgb(90, 77, 59), M.Slate }
local FACE_DARK = { rgb(66, 56, 45), M.Slate } -- keratinous bosses, rugosities, eyelids
local FACE_2 = { rgb(102, 88, 68), M.Slate } -- jugal flares
local LIP = { rgb(124, 110, 89), M.Leather } -- labial scales
local JAW = { rgb(98, 85, 66), M.Slate }
local JAW_UNDER = { rgb(148, 130, 102), M.Leather }
local MOUTH = { rgb(92, 44, 40), M.Leather }
local TONGUE = { rgb(126, 66, 60), M.Leather }
local TOOTH = { rgb(212, 199, 170), M.Marble }
local NOSTRIL = { rgb(34, 28, 24), M.SmoothPlastic }
local EYE = { rgb(190, 132, 40), M.Glass, 0.2 }
local PUPIL = { rgb(14, 11, 9), M.SmoothPlastic, 0.3 }
local SCAR = { rgb(130, 100, 86), M.Leather }
local LEG = { rgb(86, 76, 61), M.Pebble } -- thighs, knees
local LEG_2 = { rgb(96, 85, 67), M.Pebble } -- shins, calves, ankles
local SCUTE = { rgb(66, 59, 50), M.Slate } -- metatarsi, toes, hands
local TENDON = { rgb(110, 98, 80), M.Leather }
local GRIME = { rgb(88, 76, 60), M.Ground } -- mud on the foot pads
local CLAW = { rgb(44, 38, 33), M.Marble, 0.05 }

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

local function ball(name, diameter, position, style)
	part(name, V(diameter, diameter, diameter), C(position), style, BALL)
end

local function wedge(name, size, offset, style)
	part(name, size, offset, style, nil, "WedgePart")
end

-- A frame at `position` whose local X (a cylinder's axis) runs along `direction`.
local function alongX(position, direction)
	local x = direction.Unit
	local reference = if math.abs(x.Y) < 0.9 then Vector3.yAxis else Vector3.zAxis
	local z = x:Cross(reference).Unit
	return CFrame.fromMatrix(position, x, z:Cross(x), z)
end

-- Cylinder from `a` to `b`.
local function segment(name, a, b, diameter, style)
	part(name, V((b - a).Magnitude, diameter, diameter), alongX((a + b) / 2, b - a), style, CYL)
end

-- Cylinder of `length` centered on `position`, its axis along `direction`.
local function rod(name, length, diameter, position, direction, style)
	part(name, V(length, diameter, diameter), alongX(position, direction), style, CYL)
end

-- Capsule from `a` to `b`: a cylinder with a ball on each end.
local function capsule(name, a, b, diameter, style)
	segment(name, a, b, diameter, style)
	ball(name .. "Front", diameter, a, style)
	ball(name .. "Rear", diameter, b, style)
end

-- Thin disc lying on the hide, facing `normal` (mottling).
local function disc(name, diameter, position, normal, style)
	rod(name, 0.14, diameter, position, normal, style)
end

local SIDES = { -1, 1 }
local function suffix(side)
	return side < 0 and "_L" or "_R"
end

-- Torso ---------------------------------------------------------------------------------------
-- Ribcage, belly and back run from the shoulders (z -8) to the hips (z 0.4), rising to the rear.
segment("Ribcage", V(0, 10.6, -8), V(0, 11.2, 0.4), 5.6, FLANK)
segment("Belly", V(0, 9.4, -7.6), V(0, 8.7, 0.4), 4.6, BELLY)
ball("Chest", 5.2, V(0, 10.2, -8.6), BELLY_2)
ball("Shoulders", 5.4, V(0, 11.35, -7.6), FLANK)
segment("Back", V(0, 12.2, -8.2), V(0, 13, 0.4), 3, DORSAL)
segment("BellyRear", V(0, 9, -0.6), V(0, 9.8, 3.4), 4.4, BELLY_2)
for _, side in SIDES do
	local s = suffix(side)
	capsule("Oblique" .. s, V(side * 1.2, 10.4, -5), V(side * 1.3, 10.6, -1.2), 4.6, FLANK_2)
	-- Skin fold behind the arm.
	segment("AxillaFold" .. s, V(side * 2.55, 11, -6.6), V(side * 2.3, 8.6, -6), 0.5, FLANK_2)
end

-- Hips ----------------------------------------------------------------------------------------
local BACKWARD = V(0, 0, 1)
rod("HipMass", 7, 5.8, V(0, 11.3, 1.4), BACKWARD, FLANK_2)
rod("SacralRidge", 6.4, 1.6, V(0, 13.85, 1.2), V(0, -0.04, 1), DORSAL)
for _, side in SIDES do
	rod("Ilium" .. suffix(side), 5.2, 1.4, V(side * 1.35, 13.45, 1.4), V(0, -0.05, 1), DORSAL_2)
end
ball("PubicBoot", 3.2, V(0, 7.9, -0.2), BELLY_2)

-- Tail ----------------------------------------------------------------------------------------
-- Spine points from the hips to the tip, with the tail's diameter at each; it droops and swings
-- 2 studs to +X.
local TAIL = {
	{ V(0, 11.7, 4.6), 5 },
	{ V(0, 11.55, 7.6), 4.5 },
	{ V(0.1, 11.25, 10.6), 3.8 },
	{ V(0.3, 10.85, 13.5), 3.1 },
	{ V(0.6, 10.45, 16.3), 2.45 },
	{ V(1, 10.05, 19), 1.8 },
	{ V(1.5, 9.75, 21.4), 1.2 },
	{ V(2, 9.55, 23.2), 0.55 },
}
local UP = Vector3.yAxis

for i = 1, #TAIL - 1 do
	local a, b = TAIL[i][1], TAIL[i + 1][1]
	local d = (TAIL[i][2] + TAIL[i + 1][2]) / 2
	segment("Tail" .. i, a, b, d, FLANK)
	-- Buff underside (chevrons, caudofemoralis) on the front three segments.
	if i <= 3 then
		local drop = UP * d * 0.24
		segment("TailUnder" .. i, a - drop, b - drop, d * 0.72, BELLY)
	end
	-- Dark dorsal stripe on the front four segments.
	if i <= 4 then
		local lift = UP * d * 0.27
		segment("TailTop" .. i, a + lift, b + lift, d * 0.5, DORSAL)
	end
end
for i = 2, #TAIL - 1 do
	ball("TailJoint" .. i - 1, TAIL[i][2] * 0.96, TAIL[i][1], if i % 2 == 0 then FLANK_2 else FLANK)
end
ball("TailTip", TAIL[#TAIL][2], TAIL[#TAIL][1], DORSAL)

-- Dorsal bands on the rear half: rings the tail's size shifted up so only a crescent shows on top.
-- Each is placed at a fractional spine index.
for i, at in { 4.55, 5.4, 6.25, 7.1 } do
	local k = math.floor(at)
	local u = at - k
	local a, b = TAIL[k], TAIL[k + 1]
	local d = a[2] + (b[2] - a[2]) * u
	local position = a[1]:Lerp(b[1], u) + UP * (0.06 * d + 0.05)
	rod("TailBand" .. i, 0.7, d * 0.99, position, b[1] - a[1], MOTTLE)
end

-- Neck ----------------------------------------------------------------------------------------
segment("NeckBase", V(0, 11.6, -8.6), V(0, 13.6, -11.6), 4.4, FLANK)
segment("NeckUpper", V(0, 13.4, -11), V(0, 14.5, -12.8), 3, FLANK)
segment("NeckTop", V(0, 12.9, -8), V(0, 14.9, -12.2), 1.7, DORSAL)
segment("Throat", V(0, 10.2, -9.4), V(0, 12.6, -12.8), 2.8, BELLY_2)
for _, side in SIDES do
	local s = suffix(side)
	segment("NeckFold" .. s, V(side * 1.9, 13.6, -10.3), V(side * 1.65, 11.6, -11.2), 0.42, FLANK_2)
end

-- Skull ---------------------------------------------------------------------------------------
-- Three blocks step down from the jaw muscles to the snout; the upper lip line is y 13.6.
local LIP_LINE = 13.6
part("Head", V(3.2, 2.8, 2.4), C(0, 14.8, -13.6), FACE)
part("SnoutMid", V(2.2, 2.2, 1.8), C(0, 14.55, -15.6), FACE)
part("SnoutTip", V(1.6, 1.5, 1.2), C(0, 14.3, -17), FACE)
wedge("NasalSlope", V(2.2, 0.55, 1.8), C(0, 15.925, -15.6), FACE)
wedge("SnoutSlope", V(1.6, 0.6, 1.2), C(0, 15.35, -17), FACE)
part("Palate", V(2, 0.2, 3.8), C(0, 13.45, -15), MOUTH)
for i, at in { V(0, 15.68, -14.6), V(0, 15.46, -15.6), V(0, 15.18, -16.6) } do
	ball("NasalBump" .. i, 0.36, at, FACE_DARK) -- nasal rugosities
end
ball("OcciputCrest", 1.2, V(0, 15.75, -12.75), DORSAL)

-- Upper teeth along each side, front to back: { x, z, height }.
local UPPER_TEETH = {
	{ 1.28, -13.6, 0.45 },
	{ 1.12, -14.4, 0.55 },
	{ 0.9, -15.2, 0.55 },
	{ 0.86, -16, 0.45 },
	{ 0.6, -16.8, 0.45 },
	{ 0.4, -17.4, 0.45 },
}

for _, side in SIDES do
	local s = suffix(side)
	part(
		"Jugal" .. s,
		V(0.4, 1, 2.4),
		C(side * 1.58, 14.15, -13.6) * A(rad(6), rad(-side * 8), 0),
		FACE_2
	)
	ball("JawMuscle" .. s, 1.9, V(side * 1.25, 14.7, -12.65), FACE)
	-- Keratinous brow (postorbital) and lacrimal bosses.
	part(
		"Brow" .. s,
		V(0.8, 0.5, 1),
		C(side * 1.15, 16.2, -14.2) * A(0, 0, rad(side * 12)),
		FACE_DARK
	)
	part(
		"Lacrimal" .. s,
		V(0.6, 0.45, 0.7),
		C(side * 0.95, 16.12, -15) * A(0, 0, rad(side * 10)),
		FACE_DARK
	)
	ball("Eyelid" .. s, 0.8, V(side * 1.28, 15.55, -14.6), FACE_DARK)
	ball("Eye" .. s, 0.52, V(side * 1.46, 15.55, -14.72), EYE)
	ball("Pupil" .. s, 0.2, V(side * 1.66, 15.55, -14.86), PUPIL)
	ball("Nostril" .. s, 0.3, V(side * 0.62, 14.9, -17.45), NOSTRIL)
	part(
		"LipRear" .. s,
		V(0.3, 0.55, 2.4),
		C(side * 1.55, 13.6, -13.8) * A(0, rad(-side * 8), 0),
		LIP
	)
	part("LipMid" .. s, V(0.3, 0.5, 1.9), C(side * 1.05, 13.65, -15.6), LIP)
	part("LipFront" .. s, V(0.3, 0.5, 1.3), C(side * 0.75, 13.75, -17), LIP)
	for i, tooth in UPPER_TEETH do
		local x, z, h = tooth[1], tooth[2], tooth[3]
		wedge(
			"ToothUpper" .. i .. s,
			V(0.18, h, 0.3),
			C(side * x, LIP_LINE - h / 2, z) * DOWN,
			TOOTH
		)
	end
end
part("Scar_L", V(0.08, 0.16, 1.3), C(-1.82, 14.35, -13.4) * A(rad(25), rad(-8), 0), SCAR)

-- Lower jaw -----------------------------------------------------------------------------------
-- Authored in the jaw frame: pivot at the jaw joint, opened 14 degrees (front down).
local JAW_FRAME = C(0, 13.55, -12.6) * A(rad(-14), 0, 0)
local function jaw(x, y, z)
	return JAW_FRAME * C(x, y, z)
end

part("JawRear", V(3.1, 1.8, 2.2), jaw(0, -0.8, -0.9), JAW)
part("JawMid", V(2, 1.1, 1.8), jaw(0, -0.5, -2.8), JAW)
part("JawFront", V(1.4, 0.9, 1.3), jaw(0, -0.45, -4.3), JAW)
part("Gular", V(1.8, 0.35, 2.8), jaw(0, -1.12, -1.8) * A(rad(-4), 0, 0), JAW_UNDER)
part("Tongue", V(1.3, 0.3, 3), jaw(0, 0.12, -2.4), TONGUE)

-- Lower teeth along each side, back to front: { x, z }.
local LOWER_TEETH = { { 1.08, -1.6 }, { 0.72, -2.5 }, { 0.68, -3.4 }, { 0.45, -4.3 } }

for _, side in SIDES do
	local s = suffix(side)
	part("LowerLipRear" .. s, V(0.28, 0.45, 2.2), jaw(side * 1.48, 0.05, -0.9), LIP)
	part("LowerLipMid" .. s, V(0.28, 0.4, 1.8), jaw(side * 0.95, 0.05, -2.8), LIP)
	part("LowerLipFront" .. s, V(0.28, 0.4, 1.3), jaw(side * 0.66, 0, -4.3), LIP)
	for i, tooth in LOWER_TEETH do
		wedge(
			"ToothLower" .. i .. s,
			V(0.16, 0.42, 0.26),
			jaw(side * tooth[1], 0.32, tooth[2]),
			TOOTH
		)
	end
end

-- Arms ----------------------------------------------------------------------------------------
-- Tucked under the chest; two clawed fingers each.
for _, side in SIDES do
	local s = suffix(side)
	local shoulder = V(side * 2.25, 10, -7.6)
	local elbow = V(side * 2.45, 8.85, -8)
	local wrist = V(side * 2.35, 8.55, -8.95)
	ball("Shoulder" .. s, 1.5, shoulder, FLANK)
	segment("UpperArm" .. s, shoulder, elbow, 0.75, FLANK)
	ball("Elbow" .. s, 0.66, elbow, FLANK_2)
	segment("Forearm" .. s, elbow, wrist, 0.55, FLANK_2)
	part("Hand" .. s, V(0.34, 0.5, 0.45), C(wrist + V(0, -0.12, -0.1)) * A(rad(-20), 0, 0), SCUTE)
	for i, dx in { -0.09, 0.09 } do
		local knuckle = wrist + V(dx, -0.3, -0.25)
		local tip = wrist + V(dx * 1.6, -0.62, -0.62)
		segment("Finger" .. i .. s, knuckle, tip, 0.17, SCUTE)
		wedge("HandClaw" .. i .. s, V(0.12, 0.26, 0.2), C(tip + V(0, -0.12, -0.04)) * DOWN, CLAW)
	end
end

-- Legs ----------------------------------------------------------------------------------------
-- Femur 4.8, tibia 4.2, metatarsus 2.5 (Sue 1.38 : 1.14 : 0.67 m). `femur` and `tibia` are pitch
-- angles from vertical (positive swings the lower end forward); the metatarsus runs from the ankle
-- down to a foot pad at y 0.7.
local HIP = V(2.5, 11.2, 1.4)
local FEMUR, TIBIA, METATARSUS = 4.8, 4.2, 2.5
local KNEE_X, ANKLE_X, FOOT_X, PAD_Y = 2.75, 2.05, 1.6, 0.7
local STRIDE = {
	[-1] = { femur = 34, tibia = -14 }, -- forward leg, planted
	[1] = { femur = 4, tibia = -38 }, -- trailing leg, pushing off
}

-- Toes: digit II inner, III middle (longest), IV outer. `splay` yaws the toe toward the midline.
local TOES = {
	{ digit = "II", splay = 18, length = 1.7, inset = 0.25 },
	{ digit = "III", splay = 0, length = 2.1, inset = 0 },
	{ digit = "IV", splay = -18, length = 1.6, inset = -0.25 },
}

local LEG_JOINTS = {}

for _, side in SIDES do
	local s = suffix(side)
	local stride = STRIDE[side]
	local f, t = rad(stride.femur), rad(stride.tibia)
	local hip = V(side * HIP.X, HIP.Y, HIP.Z)
	local knee = V(side * KNEE_X, hip.Y - FEMUR * math.cos(f), hip.Z - FEMUR * math.sin(f))
	local ankle = V(side * ANKLE_X, knee.Y - TIBIA * math.cos(t), knee.Z - TIBIA * math.sin(t))
	local m = math.acos((ankle.Y - PAD_Y) / METATARSUS)
	local pad = V(side * FOOT_X, PAD_Y, ankle.Z - METATARSUS * math.sin(m))
	LEG_JOINTS[side] = { hip = hip, knee = knee }

	-- Thigh: drumstick of the ilio-femoral muscles, with the caudofemoralis running into the tail.
	ball("ThighTop" .. s, 4.6, hip + V(-side * 0.1, 0.1, 0.2), LEG)
	local femur = (knee - hip).Unit
	segment("Thigh" .. s, hip + femur * 0.6, hip + femur * 3, 3.7, LEG)
	segment("ThighLower" .. s, hip + femur * 2.6, hip + femur * 4.2, 2.6, LEG)
	segment(
		"Caudofemoralis" .. s,
		hip + V(-side * 0.3, 0.2, 1.4),
		V(side * 1.2, 11, 8.4),
		2.8,
		FLANK_2
	)
	ball("Knee" .. s, 2.2, knee, LEG)

	-- Shin, with the calf and Achilles tendon behind it.
	local tibia = (ankle - knee).Unit
	local back = V(0, tibia.Z, -tibia.Y).Unit
	segment("Shin" .. s, knee + tibia * 0.4, ankle, 1.6, LEG_2)
	segment(
		"Calf" .. s,
		knee + tibia * 0.6 + back * 0.55,
		knee + tibia * 2.8 + back * 0.35,
		1.9,
		LEG_2
	)
	segment("Achilles" .. s, knee + tibia * 2.6 + back * 0.55, ankle + back * 0.45, 0.42, TENDON)
	ball("Ankle" .. s, 1.45, ankle, LEG_2)

	-- Foot.
	segment("Metatarsus" .. s, ankle, pad, 1.15, SCUTE)
	ball("FootPad" .. s, 1.4, pad, GRIME)
	for _, toe in TOES do
		local yaw = rad(side * toe.splay)
		local forward = V(-math.sin(yaw), 0, -math.cos(yaw))
		local base = V(pad.X - side * toe.inset, 0.35, pad.Z - 0.1)
		local tip = base + forward * toe.length
		rod("Toe" .. toe.digit .. s, toe.length, 0.68, (base + tip) / 2, forward, SCUTE)
		local claw = tip + forward * 0.25
		wedge(
			"Claw" .. toe.digit .. s,
			V(0.34, 0.5, 0.8),
			C(claw.X, 0.25, claw.Z) * A(0, yaw, 0),
			CLAW
		)
	end
	-- Hallux (digit I): small, high on the inner back of the metatarsus.
	local halluxEnd = pad + V(-side * 0.7, 0.05, 0.05)
	segment("Hallux" .. s, pad + V(-side * 0.45, 0.3, 0.55), halluxEnd, 0.34, SCUTE)
	wedge("HalluxClaw" .. s, V(0.16, 0.3, 0.32), C(halluxEnd + V(0, -0.1, -0.15)) * DOWN, CLAW)
end

-- Mottling ------------------------------------------------------------------------------------
-- Irregular dark blotches: pairs of overlapping discs laid on the ribcage (radius 2.8 around an
-- axis rising from y 10.6 at z -8 to y 11.2 at z 0.4). Different on each side.
local FLANK_BLOTCHES = {
	{ "FlankBlotch1a_L", -1, 12.5, -5.6, 1.4 },
	{ "FlankBlotch1b_L", -1, 12, -4.8, 0.9 },
	{ "FlankBlotch2a_L", -1, 12.9, -2.2, 1.2 },
	{ "FlankBlotch2b_L", -1, 12.4, -1.4, 0.8 },
	{ "FlankBlotch1a_R", 1, 12.3, -5, 1.3 },
	{ "FlankBlotch1b_R", 1, 12.8, -4.2, 0.9 },
	{ "FlankBlotch2a_R", 1, 12.6, -1.8, 1.1 },
	{ "FlankBlotch2b_R", 1, 12, -1.2, 0.8 },
}
local RIB_RADIUS = 2.82

for _, blotch in FLANK_BLOTCHES do
	local name, side, y, z, d = table.unpack(blotch)
	local axisY = 10.6 + 0.6 * (z + 8) / 8.4
	local pitch = math.asin(math.clamp((y - axisY) / 2.8, -1, 1))
	local normal = V(side * math.cos(pitch), math.sin(pitch), 0)
	disc(name, d, V(0, axisY, z) + normal * RIB_RADIUS, normal, MOTTLE)
end
-- Back blotches sit on the dorsal cylinder (top y 13.7 at z -8.2, rising 0.8 to z 0.4): { x, z, d }.
for i, blotch in { { -0.5, -6.6, 1.3 }, { 0.6, -4.2, 1.5 }, { -0.3, -1.6, 1.2 } } do
	local x, z, d = table.unpack(blotch)
	local backTop = 13.72 + 0.8 * (z + 8.2) / 8.6
	disc("BackBlotch" .. i, d, V(x, backTop, z), UP, MOTTLE)
end
for _, side in SIDES do
	local joints = LEG_JOINTS[side]
	local p = joints.hip + (joints.knee - joints.hip).Unit * 1.8
	disc("ThighBlotch" .. suffix(side), 1.5, p + V(side * 1.87, 0.2, 0), V(side, 0, 0), MOTTLE)
end

return {
	name = "T-Rex",
	rootSize = V(3.6, 4, 6.4), -- center y 10.6, z 0: inside the belly, ribcage and hip mass
	hipHeight = 8.6,
	reach = 20, -- 3D from the root center (y 10.6) to a player's root (y ~3) at the snout
	pieces = pieces,
}
