-- Zombie: a man a few weeks dead, in a faded denim work shirt and jeans, one work boot lost.
-- Shambling mid-stride: left leg leads, the bare right foot pushes off its toes. The torso
-- pitches 24 degrees forward over a rounded back, the neck thrusts forward and the head lolls
-- toward its left shoulder with the jaw hanging open. Both arms reach forward, the right high and
-- straight, the left lower with the elbow bent; the wrists hang limp.
-- Wounds: scalp torn to the skull, left ear gone, a bite in the left flank showing three ribs,
-- a bite in the left forearm showing the radius.
-- Scale: 4 studs = 1 m, 5.5 tall. Hip joints y 2.93, belt y 3.25, shoulders y 4.33, eyes y 5.0;
-- the right fingertips reach z -2.6.

local rgb = Color3.fromRGB
local M = Enum.Material
local A = CFrame.Angles
local C = CFrame.new
local V = Vector3.new
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball
local rad = math.rad
local CYLINDER_Y = A(0, 0, rad(90)) -- cylinder axis along Y
local CYLINDER_Z = A(0, rad(90), 0) -- cylinder axis along -Z

-- Palette: { color, material, reflectance, transparency }.
-- Skin: grey-green pallor, yellowing on the belly, purple where blood pooled low, black at the
-- extremities.
local SKIN = { rgb(140, 141, 117), M.Plaster }
local SKIN_GREY = { rgb(118, 123, 106), M.Plaster }
local SKIN_SALLOW = { rgb(150, 141, 101), M.Plaster }
local SKIN_LIVID = { rgb(96, 86, 96), M.Slate }
local SKIN_NECROTIC = { rgb(72, 64, 52), M.Slate }
local FLESH = { rgb(112, 40, 36), M.SmoothPlastic, 0.06 }
local CAVITY = { rgb(36, 22, 20), M.SmoothPlastic }
local BONE = { rgb(206, 196, 168), M.Marble }
local TEETH = { rgb(178, 160, 116), M.Plaster }
local EYE = { rgb(172, 178, 168), M.SmoothPlastic, 0.12 } -- milky cataract
local HAIR = { rgb(44, 38, 32), M.Fabric }
local SHIRT = { rgb(86, 99, 112), M.Fabric }
local SHIRT_SHADOW = { rgb(68, 76, 84), M.Fabric }
local SHIRT_GRIME = { rgb(100, 97, 84), M.Fabric }
local BLOOD = { rgb(72, 28, 24), M.Fabric }
local JEANS = { rgb(54, 63, 80), M.Fabric }
local JEANS_WORN = { rgb(80, 88, 100), M.Fabric }
local JEANS_MUD = { rgb(76, 66, 52), M.Fabric }
local BELT = { rgb(50, 36, 26), M.Leather }
local BUCKLE = { rgb(112, 100, 80), M.CorrodedMetal, 0.05 }
local SHOE = { rgb(64, 57, 48), M.Leather }
local SOLE = { rgb(38, 36, 34), M.Rubber }

local pieces = {}

local function part(name, size, offset, style, shape)
	table.insert(pieces, {
		name = name,
		shape = shape,
		size = size,
		offset = offset,
		color = style[1],
		material = style[2],
		reflectance = style[3],
		transparency = style[4],
	})
end

local function ball(name, diameter, offset, style)
	part(name, V(diameter, diameter, diameter), offset, style, BALL)
end

local function cyl(name, length, diameter, offset, style)
	part(name, V(length, diameter, diameter), offset, style, CYL)
end

-- A frame at `position` whose -Z points along `direction`, +Y as close to up as possible.
local function facing(position, direction)
	local up = if math.abs(direction.Unit.Y) > 0.99 then Vector3.xAxis else Vector3.yAxis
	return CFrame.lookAt(position, position + direction, up)
end

-- Cylinder from `a` to `b`, `extra` studs longer to bury its ends.
local function segment(name, a, b, diameter, style, extra)
	local length = (b - a).Magnitude + (extra or 0)
	cyl(name, length, diameter, facing((a + b) / 2, b - a) * CYLINDER_Z, style)
end

-- The point `length` below `from`, swung `degrees` forward (toward -Z) from hanging straight.
local function swing(from, length, degrees)
	return from + V(0, -math.cos(rad(degrees)), -math.sin(rad(degrees))) * length
end

-- Legs ----------------------------------------------------------------------------------------
-- Left leg leads in jeans and a work boot, foot flat. Right leg trails with the jeans torn open
-- at the knee and the boot lost; the bare foot pushes off with the heel raised.
local HIP_Y, HIP_Z, HIP_X = 2.93, 0.15, 0.32
local THIGH, SHIN = 1.42, 1.38
local TOE_OUT = 8 -- degrees each foot turns out
local PUSH_OFF = 14 -- degrees the trailing foot pitches up onto its toes

local LEGS = {
	[-1] = { thigh = 22, shin = 8, knee = 0.48, kneeStyle = JEANS_WORN, cuffLift = 0.2 },
	[1] = { thigh = -12, shin = -30, knee = 0.42, kneeStyle = SKIN_LIVID, cuffLift = 0.26 },
}

for _, side in { -1, 1 } do
	local s = side < 0 and "L" or "R"
	local leg = LEGS[side]
	local hip = V(side * HIP_X, HIP_Y, HIP_Z)
	local knee = swing(hip, THIGH, leg.thigh) + V(side * 0.03, 0, 0)
	local ankle = swing(knee, SHIN, leg.shin)
	local foot = C(ankle) * A(0, rad(-side * TOE_OUT), 0)

	segment("Thigh" .. s, hip + V(0, 0.12, 0), knee, 0.56, JEANS)
	ball("Knee" .. s, leg.knee, C(knee + V(0, 0, -0.04)), leg.kneeStyle)
	segment("Shin" .. s, knee, ankle + V(0, leg.cuffLift - 0.1, 0), 0.46, JEANS)
	cyl("Cuff" .. s, 0.16, 0.52, C(ankle + V(0, leg.cuffLift, 0)) * CYLINDER_Y, JEANS_MUD)

	if side < 0 then
		part("BootL", V(0.38, 0.3, 0.8), foot * C(0, -0.03, -0.2), SHOE)
		ball("BootToeL", 0.36, foot * C(0, -0.07, -0.56), SHOE)
		part("SoleL", V(0.42, 0.1, 0.94), foot * C(0, -0.197, -0.25), SOLE)
	else
		foot *= A(rad(-PUSH_OFF), 0, 0)
		ball("AnkleR", 0.26, foot, SKIN_LIVID)
		part("FootR", V(0.3, 0.2, 0.6), foot * C(0, -0.14, -0.2), SKIN_LIVID)
		ball("HeelR", 0.26, foot * C(0, -0.11, 0.06), SKIN_LIVID)
		-- Toes bend back flat on the ground.
		part(
			"ToesR",
			V(0.3, 0.1, 0.18),
			foot * C(0, -0.19, -0.58) * A(rad(PUSH_OFF), 0, 0),
			SKIN_NECROTIC
		)
	end
end

-- Hips ----------------------------------------------------------------------------------------
local HIPS = C(0, 2.98, 0.14) * A(rad(-5), 0, 0)
local BELT_LINE = HIPS * C(0, 0.27, 0)
part("Pelvis", V(1.22, 0.62, 0.8), HIPS, JEANS)
part("Belt", V(1.26, 0.14, 0.84), BELT_LINE, BELT)
part("Buckle", V(0.18, 0.13, 0.05), BELT_LINE * C(0.06, -0.04, -0.43), BUCKLE)

-- Torso ---------------------------------------------------------------------------------------
-- TORSO: origin at the spine base, +Y up the spine, -Z out of the chest.
local TORSO = C(0, 3.15, 0.12) * A(rad(-24), 0, 0)
part("Abdomen", V(0.9, 0.64, 0.62), TORSO * C(0, 0.36, -0.03), SKIN_SALLOW)
part("ShirtLower", V(0.6, 0.68, 0.72), TORSO * C(0.17, 0.38, 0.01), SHIRT_GRIME)
part("ShirtBack", V(0.92, 0.66, 0.1), TORSO * C(0, 0.38, 0.32), SHIRT_GRIME)
-- The chest is a cylinder across the body so the shoulders and pectorals read rounded.
cyl("Chest", 1.14, 0.84, TORSO * C(0, 0.98, 0), SHIRT)
ball("UpperBack", 0.88, TORSO * C(0, 1.1, 0.2), SHIRT_SHADOW)
part("Collar", V(0.6, 0.14, 0.56), TORSO * C(0, 1.44, 0.02), SHIRT_SHADOW)
part("BloodBib", V(0.26, 0.52, 0.04), TORSO * C(-0.05, 1.02, -0.425) * A(0, 0, rad(-6)), BLOOD)
part("BloodSmear", V(0.18, 0.34, 0.04), TORSO * C(0.3, 0.62, -0.37) * A(0, 0, rad(14)), BLOOD)
part(
	"ShirtRag",
	V(0.22, 0.4, 0.04),
	TORSO * C(0.32, 0.04, -0.375) * A(rad(-6), 0, rad(10)),
	SHIRT_GRIME
)
part(
	"ShirtTail",
	V(0.78, 0.42, 0.05),
	TORSO * C(0.08, -0.04, 0.39) * A(rad(6), 0, rad(-5)),
	SHIRT_GRIME
)

-- Bite in the left flank: three ribs across a dark cavity.
part("WoundFlesh", V(0.08, 0.5, 0.42), TORSO * C(-0.435, 0.42, -0.06), FLESH)
part("WoundCavity", V(0.06, 0.38, 0.3), TORSO * C(-0.465, 0.42, -0.06), CAVITY)
for i, y in { 0.3, 0.42, 0.54 } do
	cyl("Rib" .. i, 0.36, 0.05, TORSO * C(-0.5, y, -0.06) * A(rad(-14), 0, 0) * CYLINDER_Z, BONE)
end

-- Shoulders roll forward with the chest; the left deltoid is sweat-dark, the right dirt-stained.
local SHOULDERS = {}
for _, side in { -1, 1 } do
	SHOULDERS[side] = TORSO * V(side * 0.56, 1.3, -0.02)
	ball(
		side < 0 and "DeltoidL" or "DeltoidR",
		0.46,
		C(TORSO * V(side * 0.6, 1.3, -0.04)),
		side < 0 and SHIRT_SHADOW or SHIRT_GRIME
	)
end

-- Head ----------------------------------------------------------------------------------------
-- The neck thrusts 40 degrees forward from C7. HEAD: origin at the cranium center, chin tipped
-- down 6 degrees, turned 8 degrees and cocked 12 degrees toward its left shoulder.
local C7 = TORSO * V(0, 1.48, 0.12)
local NECK_TILT = rad(40)
local SKULL_BASE = C7 + V(0, math.cos(NECK_TILT), -math.sin(NECK_TILT)) * 0.45
local HEAD = C(SKULL_BASE + V(0, 0.22, -0.12)) * A(rad(-6), rad(8), rad(12))

ball("Head", 0.66, HEAD, SKIN_GREY)
cyl("Face", 0.42, 0.44, HEAD * C(0, -0.2, -0.12) * CYLINDER_Y, SKIN)
cyl("Brow", 0.44, 0.1, HEAD * C(0, 0.02, -0.29), SKIN_NECROTIC)
for _, side in { -1, 1 } do
	local s = side < 0 and "L" or "R"
	ball("Socket" .. s, 0.17, HEAD * C(side * 0.12, -0.07, -0.26), CAVITY)
	ball("Eye" .. s, 0.08, HEAD * C(side * 0.12, -0.07, -0.31), EYE)
end
part("NoseHole", V(0.1, 0.12, 0.06), HEAD * C(0, -0.17, -0.33), CAVITY)

-- Lips rotted back from the teeth; the jaw hangs open 22 degrees and skews to its right.
local JAW = HEAD * C(0.02, -0.38, -0.04) * A(rad(-22), 0, rad(5))
part("MouthGap", V(0.32, 0.14, 0.22), HEAD * C(0, -0.4, -0.24), CAVITY)
part("TeethUpper", V(0.28, 0.06, 0.05), HEAD * C(0, -0.43, -0.33), TEETH)
part("Jaw", V(0.4, 0.13, 0.36), JAW * C(0, -0.06, -0.17), SKIN)
part("TeethLower", V(0.26, 0.05, 0.04), JAW * C(0, 0.02, -0.31), TEETH)

-- Matted hair over the crown and back; the left ear is gone and the scalp torn to the skull.
part("EarR", V(0.06, 0.2, 0.14), HEAD * C(0.33, -0.06, 0.02), SKIN_SALLOW)
ball("HairShell", 0.68, HEAD * C(0.02, 0.04, 0.06), HAIR)
ball("ScalpWound", 0.24, HEAD * C(-0.18, 0.21, -0.06), FLESH)
ball("SkullBone", 0.18, HEAD * C(-0.2, 0.24, -0.06), BONE)

-- Neck: a column from C7 into the skull, with the two sternocleidomastoid tendons standing out.
segment("Neck", C7, HEAD * V(0, -0.18, 0.12), 0.46, SKIN_GREY, 0.1)
local NOTCH = TORSO * V(0, 1.42, -0.22) -- top of the sternum
for _, side in { -1, 1 } do
	local s = side < 0 and "L" or "R"
	segment(
		"Tendon" .. s,
		HEAD * V(side * 0.17, -0.2, 0.05),
		NOTCH + V(side * 0.05, 0, 0),
		0.1,
		SKIN
	)
end

-- Arms ----------------------------------------------------------------------------------------
-- `raise` is degrees forward of hanging; `inward` swings the arm toward the midline. Hands hang
-- limp from the wrist (`hand`) with the fingers curled down (`fingers`).
local UPPER, FORE = 1.05, 0.85
local ARMS = {
	[-1] = {
		raise = 48,
		inward = 0.06,
		forearm = V(0.1, 0.12, -1).Unit,
		hand = V(0.08, -0.7, -0.7).Unit,
		fingers = V(0.05, -0.98, 0.1).Unit,
		elbow = 0.3,
	},
	[1] = {
		raise = 75,
		inward = -0.12,
		forearm = V(-0.1, -0.05, -1).Unit,
		hand = V(-0.05, -0.55, -0.83).Unit,
		fingers = V(0, -0.95, -0.3).Unit,
		elbow = 0.28,
	},
}

for _, side in { -1, 1 } do
	local s = side < 0 and "L" or "R"
	local arm = ARMS[side]
	local shoulder = SHOULDERS[side]
	local upper = (swing(V(0, 0, 0), 1, arm.raise) + V(arm.inward, 0, 0)).Unit
	local elbow = shoulder + upper * UPPER
	local wrist = elbow + arm.forearm * FORE

	if side < 0 then
		-- Sleeve intact to the elbow; the forearm bitten down to the radius.
		segment("SleeveL", shoulder, elbow, 0.38, SHIRT_SHADOW)
		local bite = facing(elbow:Lerp(wrist, 0.5), arm.forearm)
		part("ForearmWoundL", V(0.12, 0.05, 0.34), bite * C(0.03, 0.115, 0), FLESH)
		cyl("RadiusL", 0.3, 0.06, bite * C(0.02, 0.13, 0) * CYLINDER_Z, BONE)
	else
		-- Sleeve torn off above the elbow, bare upper arm below it.
		segment("SleeveR", shoulder, shoulder:Lerp(elbow, 0.55), 0.38, SHIRT_GRIME)
		segment("UpperArmR", shoulder:Lerp(elbow, 0.3), elbow, 0.3, SKIN_GREY)
	end
	ball("Elbow" .. s, arm.elbow, C(elbow), SKIN_GREY)
	segment("Forearm" .. s, elbow, wrist, 0.26, SKIN, 0.04)

	local knuckles = wrist + arm.hand * 0.3
	part("Palm" .. s, V(0.24, 0.09, 0.3), facing(wrist + arm.hand * 0.15, arm.hand), SKIN)
	part(
		"Fingers" .. s,
		V(0.2, 0.06, 0.26),
		facing(knuckles + arm.fingers * 0.12, arm.fingers),
		SKIN_NECROTIC
	)
	local thumb = (arm.hand + V(-side * 0.5, -0.3, 0)).Unit
	local thumbBase = wrist + arm.hand * 0.08 + V(-side * 0.11, -0.03, 0)
	part("Thumb" .. s, V(0.07, 0.07, 0.2), facing(thumbBase + thumb * 0.1, thumb), SKIN_NECROTIC)
end

return {
	name = "Zombie",
	rootSize = V(1.3, 2, 1),
	hipHeight = 2,
	pieces = pieces,
}
