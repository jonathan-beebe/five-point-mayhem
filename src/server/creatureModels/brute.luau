-- Zombie Brute: a laborer whose body kept growing after death. Hunched mid-stride advance, torso
-- pitched 28 degrees forward, left foot forward, ape-length arms with the fists at knee height.
-- The right arm is mutated (about 1.5x the left's girth, split forearm, bone spurs). Torn work
-- trousers, a shirt remnant, a torn left flank with exposed ribs.
-- Scale: 4 studs = 1 m, 10.2 tall at the hump. Hips y 4.1, belt y 5.0, chest center y 6.85,
-- shoulders y 8, head center y 8.1 (sunk below the hump), hump top y 10.2.

local rgb = Color3.fromRGB
local M = Enum.Material
local A = CFrame.Angles
local C = CFrame.new
local V = Vector3.new
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball
local rad = math.rad
local CYLINDER_Y = A(0, 0, rad(90)) -- cylinder axis along Y

-- Palette: { color, material, reflectance, transparency }.
-- Flesh darkens and turns mauve toward the low points (lividity); left and right differ.
local SKIN_GREY = { rgb(118, 126, 106), M.Plaster }
local SKIN_OLIVE = { rgb(100, 110, 90), M.Concrete }
local SKIN_SALLOW = { rgb(138, 134, 108), M.Leather } -- stretched skin over swollen masses
local SKIN_HIDE = { rgb(88, 96, 80), M.Slate } -- back hide, hump, scalp
local LIVOR = { rgb(104, 88, 96), M.Plaster }
local LIVOR_DARK = { rgb(80, 66, 76), M.Rubber }
local BRUISE = { rgb(92, 82, 100), M.Rubber }
local INFLAMED = { rgb(140, 106, 98), M.Rubber, 0.04 } -- mutation skin
local RAW = { rgb(104, 36, 34), M.Rubber, 0.08 }
local GORE = { rgb(54, 24, 22), M.Rubber, 0.05 }
local BONE = { rgb(212, 202, 174), M.Marble }
local BONE_OLD = { rgb(178, 162, 128), M.Pebble }
local TEETH = { rgb(190, 172, 122), M.SmoothPlastic, 0.05 }
local CAVITY = { rgb(24, 14, 14), M.SmoothPlastic }
local EYE = { rgb(255, 128, 32), M.Neon }
local DENIM = { rgb(60, 64, 70), M.Fabric }
local DENIM_GRIME = { rgb(70, 62, 52), M.Fabric }
local SHIRT = { rgb(96, 46, 40), M.Fabric }
local BELT = { rgb(50, 36, 26), M.Leather }
local BUCKLE = { rgb(112, 98, 80), M.CorrodedMetal }

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

-- A frame at `position` whose local Y runs along `direction`, local X as close to world X as
-- possible.
local function alongY(position, direction)
	local y = direction.Unit
	local z = -y:Cross(Vector3.xAxis).Unit
	return CFrame.fromMatrix(position, y:Cross(z), y, z)
end

-- Cylinder from `a` to `b` (its axis is local X), `extra` studs longer to bury its ends.
local function segment(name, a, b, diameter, style, extra)
	local x = (b - a).Unit
	local reference = if math.abs(x.Y) < 0.9 then Vector3.yAxis else Vector3.zAxis
	local z = x:Cross(reference).Unit
	local length = (b - a).Magnitude + (extra or 0)
	part(
		name,
		V(length, diameter, diameter),
		CFrame.fromMatrix((a + b) / 2, x, z:Cross(x), z),
		style,
		CYL
	)
end

-- Block whose local Y runs from `a` to `b` (a strap or a tatter).
local function strip(name, a, b, width, depth, style)
	part(name, V(width, (b - a).Magnitude, depth), alongY((a + b) / 2, b - a), style)
end

-- Skeleton ------------------------------------------------------------------------------------
-- The spine leans 28 degrees forward from the pelvis; `spine(t, out)` walks t studs up it and
-- `out` studs out of the back.
local PELVIS = V(0, 4.4, 0.3)
local TILT = rad(28)
local SPINE_UP = V(0, math.cos(TILT), -math.sin(TILT))
local SPINE_BACK = V(0, math.sin(TILT), math.cos(TILT))
local function spine(t, out)
	return PELVIS + SPINE_UP * t + SPINE_BACK * (out or 0)
end

local HEAD = V(0, 8.1, -2.6)

-- Legs ----------------------------------------------------------------------------------------
-- Left leg forward with the trousers torn off below the knee; right leg back with the trousers
-- torn off above a bare knee.
local LEGS = {
	[-1] = {
		hip = V(-1.3, 4.1, 0.3),
		knee = V(-1.45, 2.5, -0.9),
		ankle = V(-1.55, 0.8, -0.5),
		quad = DENIM,
		shin = LIVOR,
		calf = SKIN_OLIVE,
	},
	[1] = {
		hip = V(1.3, 4.1, 0.3),
		knee = V(1.5, 2.2, 0.9),
		ankle = V(1.6, 0.8, 1.9),
		quad = DENIM_GRIME,
		shin = SKIN_OLIVE,
		calf = LIVOR,
	},
}

-- The front of a limb segment: perpendicular to its axis, toward -Z.
local function frontOf(direction)
	return (V(0, 0, -1) + direction * direction.Z).Unit
end

for _, side in { -1, 1 } do
	local s = side < 0 and "L" or "R"
	local leg = LEGS[side]
	local hip, knee, ankle = leg.hip, leg.knee, leg.ankle
	local thighFront = frontOf((knee - hip).Unit)
	local shinFront = frontOf((ankle - knee).Unit)

	segment("Thigh" .. s, hip, knee, 1.85, DENIM, 0.3)
	ball("Quad" .. s, 1.7, hip:Lerp(knee, 0.5) + thighFront * 0.35, leg.quad)
	if side < 0 then
		ball("KneeL", 1.35, knee, DENIM)
		strip(
			"TatterL1",
			knee + V(0.3, -0.55, -0.45),
			knee + V(0.25, -1.25, -0.42),
			0.4,
			0.08,
			DENIM_GRIME
		)
	else
		local hem = hip:Lerp(knee, 0.76)
		segment("HemR", hip:Lerp(knee, 0.72), hip:Lerp(knee, 0.8), 1.95, DENIM_GRIME)
		ball("KneeR", 1.3, knee, LIVOR)
		strip("TatterR1", hem + V(0.5, 0, -0.55), hem + V(0.55, -0.7, -0.6), 0.4, 0.08, DENIM_GRIME)
	end
	segment("Shin" .. s, knee, ankle, 1.15, leg.shin, 0.2)
	ball("Calf" .. s, 1.5, knee:Lerp(ankle, 0.32) - shinFront * 0.42, leg.calf)
	ball("Ankle" .. s, 1, ankle, LIVOR)
	part("Foot" .. s, V(1.3, 0.56, 2), C(ankle.X, 0.28, ankle.Z - 0.5), LIVOR)
	part("Toes" .. s, V(1.4, 0.4, 0.55), C(ankle.X - side * 0.03, 0.2, ankle.Z - 1.6), LIVOR_DARK)
	ball("Heel" .. s, 0.9, V(ankle.X, 0.45, ankle.Z + 0.35), LIVOR_DARK)
end

-- Pelvis and waist ----------------------------------------------------------------------------
part("Hips", V(3.1, 2.6, 2.6), C(0, 4.45, 0.3), DENIM, CYL)
for _, side in { -1, 1 } do
	ball(
		side < 0 and "GluteL" or "GluteR",
		2,
		V(side * 0.8, 4.25, 0.95),
		side < 0 and DENIM_GRIME or DENIM
	)
end
part("Belt", V(0.35, 3.25, 3.25), C(0, 5, 0.15) * CYLINDER_Y, BELT, CYL)
part("Buckle", V(0.6, 0.45, 0.15), C(0.15, 5, -1.5), BUCKLE)
strip("ShirtTail", V(0.9, 5.3, 1.35), V(1.05, 3.9, 1.55), 1, 0.1, SHIRT)

-- Torso ---------------------------------------------------------------------------------------
part("Core", V(3.4, 2.8, 2.6), alongY(spine(2.2), SPINE_UP), SKIN_OLIVE)
ball("Belly", 3, V(0, 5.55, -0.85), SKIN_SALLOW)
ball("ObliqueL", 2.2, V(-1.35, 5.75, -0.4), SKIN_GREY)
ball("ObliqueR", 2.3, V(1.4, 5.8, -0.35), SKIN_OLIVE)
ball("Ribcage", 4, spine(2.75, 0.05), SKIN_GREY)
ball("PecL", 2.3, V(-1.05, 7.15, -2), SKIN_SALLOW)
ball("PecR", 2.5, V(1.1, 7.25, -1.95), SKIN_GREY)
ball("LatL", 2.6, V(-1.55, 6.55, 0.35), SKIN_OLIVE)
ball("LatR", 2.8, V(1.6, 6.65, 0.4), SKIN_GREY)
ball("Hump", 3.4, V(0.2, 8.5, -0.55), SKIN_HIDE)
ball("Growth", 2, V(1.35, 9, -0.05), INFLAMED)
segment("Neck", V(0, 8.35, -1.35), V(0, 8.1, -2.35), 1.7, SKIN_HIDE)

-- Torn left flank: raw muscle with three ribs lying on it.
part("FlankWound", V(0.25, 1.4, 1.5), C(-2.25, 6.35, -0.6) * A(0, 0, rad(8)), RAW)
for i, rib in { V(-2.42, 6.85, -0.75), V(-2.42, 6.45, -0.65), V(-2.42, 6.05, -0.55) } do
	segment("Rib" .. i, rib + V(0, 0.05, -0.75), rib + V(0, -0.15, 0.75), 0.2, BONE_OLD, 0.1)
end

-- Shirt remnant from the right shoulder to the left hip; sores and veins on the skin.
strip("ShirtStrap", V(1.85, 8.3, -1.95), V(-1.2, 5.5, -1.95), 0.9, 0.12, SHIRT)
part("ChestSore", V(0.7, 0.55, 0.1), C(-0.95, 7, -3.13) * A(rad(8), 0, rad(14)), GORE)
part("BellyVein", V(0.12, 1.1, 0.1), C(0.55, 5.6, -2.33) * A(rad(-20), 0, rad(-18)), BRUISE)

-- Spine spurs: local Y out of the back, the tip edge raked down the spine. Each root is buried
-- about 0.2 in the hump, ribcage or lats.
local SPINE_SPURS = {
	{ t = 1.6, out = 1.95, size = V(0.4, 0.9, 0.7), style = BONE_OLD },
	{ t = 2.4, out = 2.47, size = V(0.4, 1.3, 0.9), style = BONE },
	{ t = 3.15, out = 3.24, size = V(0.4, 1.6, 1), style = BONE_OLD },
	{ t = 3.9, out = 3.31, size = V(0.4, 1.3, 0.9), style = BONE },
}
for i, spur in SPINE_SPURS do
	wedge("SpineSpur" .. i, spur.size, C(spine(spur.t, spur.out)) * A(rad(62), 0, 0), spur.style)
end

-- Spurs erupting from the right shoulder growth, fanned out and up.
wedge("ShoulderSpur1", V(0.4, 1.3, 0.7), C(2, 9.95, -0.1) * A(rad(10), 0, rad(-35)), BONE)
wedge("ShoulderSpur2", V(0.4, 1, 0.7), C(2.35, 9.5, 0.45) * A(rad(40), 0, rad(-50)), BONE_OLD)
wedge("ShoulderSpur3", V(0.4, 0.8, 0.7), C(1.5, 10, 0.35) * A(rad(35), 0, rad(-15)), BONE)

-- Left arm (heavy, unmutated) -----------------------------------------------------------------
do
	local shoulder, elbow, wrist = V(-3, 7.9, -1.4), V(-3.45, 5.6, -1.9), V(-3.35, 3.65, -2.9)
	local fore = (wrist - elbow).Unit
	local hand = wrist + fore * 0.55

	ball("DeltoidL", 2.1, shoulder + V(-0.1, 0.15, 0), SKIN_SALLOW)
	segment("UpperArmL", shoulder, elbow, 1.35, SKIN_GREY, 0.2)
	ball("BicepL", 1.45, shoulder:Lerp(elbow, 0.5) + V(0.05, 0, -0.35), SKIN_OLIVE)
	ball("TricepL", 1.35, shoulder:Lerp(elbow, 0.4) + V(-0.1, 0, 0.4), SKIN_GREY)
	ball("ElbowL", 1.15, elbow, SKIN_OLIVE)
	segment("ForearmL", elbow, wrist, 1.2, SKIN_GREY, 0.1)
	ball("ForearmMassL", 1.35, elbow:Lerp(wrist, 0.3) + V(-0.12, 0.05, 0.1), LIVOR)
	part("HandL", V(1, 1.1, 1), alongY(hand, -fore), LIVOR)
	segment("KnucklesL", hand + V(-0.5, -0.4, -0.5), hand + V(0.5, -0.4, -0.5), 0.5, LIVOR_DARK)
	part(
		"FingersL",
		V(1.05, 0.55, 0.7),
		C(hand + V(0, -0.55, -0.3)) * A(rad(-35), 0, 0),
		LIVOR_DARK
	)
end

-- Right arm (mutated) -------------------------------------------------------------------------
do
	local shoulder, elbow, wrist = V(3.3, 8, -1.2), V(3.95, 5.5, -1.1), V(3.85, 3.3, -2.5)
	local fore = (wrist - elbow).Unit
	local hand = wrist + fore * 0.95

	ball("DeltoidR", 2.7, shoulder + V(0.15, 0.2, 0), INFLAMED)
	segment("UpperArmR", shoulder, elbow, 1.9, SKIN_SALLOW, 0.3)
	ball("BicepR", 2, shoulder:Lerp(elbow, 0.55) + V(-0.05, 0, -0.55), INFLAMED)
	ball("TricepR", 1.9, shoulder:Lerp(elbow, 0.45) + V(0.3, 0, 0.5), SKIN_GREY)
	ball("ElbowR", 1.6, elbow, SKIN_OLIVE)
	wedge(
		"ElbowSpur1",
		V(0.4, 1.1, 0.7),
		C(elbow + V(0.4, 0.2, 0.95)) * A(rad(115), 0, rad(-20)),
		BONE
	)
	wedge(
		"ElbowSpur2",
		V(0.35, 0.8, 0.6),
		C(elbow + V(0.75, 0.55, 0.6)) * A(rad(85), 0, rad(-55)),
		BONE_OLD
	)
	segment("ForearmR", elbow, wrist, 2.1, INFLAMED, 0.1)
	ball("ForearmMassR", 2.35, elbow:Lerp(wrist, 0.35) + V(0.15, 0.05, -0.1), SKIN_SALLOW)

	-- Split skin on the outer forearm: raw muscle with the ulna showing.
	segment("ForearmSplit", elbow + V(0.95, -0.4, -0.05), wrist + V(0.95, 0.4, 0), 0.6, RAW)
	segment("Ulna", elbow + V(1.12, -0.3, 0), wrist + V(1.12, 0.35, 0.05), 0.3, BONE_OLD, 0.2)

	segment("Wrist", wrist, wrist + fore * 0.4, 1.75, LIVOR)
	part("HandR", V(1.5, 1.45, 1.55), alongY(hand, -fore), LIVOR)
	segment(
		"KnucklesR",
		hand + V(-0.75, -0.6, -0.55),
		hand + V(0.75, -0.6, -0.55),
		0.75,
		LIVOR_DARK
	)
	part(
		"FingersR",
		V(1.45, 0.8, 0.85),
		C(hand + V(0, -0.95, -0.2)) * A(rad(-25), 0, 0),
		LIVOR_DARK
	)
	part(
		"ThumbR",
		V(0.55, 0.9, 0.5),
		C(hand + V(-0.8, -0.35, -0.55)) * A(rad(-20), 0, rad(-18)),
		LIVOR
	)
	for i, x in { -0.45, 0.05, 0.5 } do
		wedge(
			"ClawR" .. i,
			V(0.22, 0.35, 0.4),
			C(hand + V(x, -1.45, -0.42)) * A(math.pi, 0, 0),
			BONE_OLD
		)
	end
end

-- Head ----------------------------------------------------------------------------------------
-- Sunk between the shoulders: heavy brow over glowing eyes in dark sockets, open underslung jaw.
local function head(offset)
	return HEAD + offset
end

ball("Head", 1.9, HEAD, SKIN_HIDE)
part("Brow", V(1.75, 0.45, 0.6), C(head(V(0, 0.35, -0.72))) * A(rad(-10), 0, 0), SKIN_OLIVE)
for _, side in { -1, 1 } do
	local s = side < 0 and "L" or "R"
	ball("Socket" .. s, 0.5, head(V(side * 0.4, 0.08, -0.78)), CAVITY)
end
ball("EyeL", 0.22, head(V(-0.4, 0.08, -0.98)), EYE)
ball("EyeR", 0.22, head(V(0.42, 0.06, -0.98)), EYE)
part("Nose", V(0.3, 0.3, 0.12), C(head(V(0, -0.22, -0.92))), CAVITY)
ball("CheekL", 0.85, head(V(-0.62, -0.38, -0.5)), SKIN_GREY)
ball("CheekR", 0.9, head(V(0.62, -0.38, -0.5)), SKIN_OLIVE)
part("Mouth", V(1.05, 0.55, 0.3), C(head(V(0, -0.62, -0.82))), CAVITY)
part("UpperTeeth", V(1, 0.18, 0.2), C(head(V(0, -0.42, -0.93))), TEETH)
part("Jaw", V(1.5, 0.5, 1.2), C(head(V(0, -0.95, -0.45))) * A(rad(-14), 0, 0), SKIN_OLIVE)
part("LowerTeeth", V(1.05, 0.2, 0.2), C(head(V(0, -0.78, -1.03))) * A(rad(-14), 0, 0), TEETH)
part("SkullPatch", V(0.7, 0.12, 0.8), C(head(V(-0.35, 0.88, -0.05))) * A(0, 0, rad(22)), BONE_OLD)
wedge("SkullSpur1", V(0.25, 0.6, 0.5), C(head(V(0.35, 1, 0.15))) * A(rad(20), 0, rad(-20)), BONE)
wedge(
	"SkullSpur2",
	V(0.2, 0.4, 0.35),
	C(head(V(0.65, 0.85, 0.3))) * A(rad(25), 0, rad(-40)),
	BONE_OLD
)
part("EarL", V(0.18, 0.5, 0.35), C(head(V(-0.95, 0, 0.05))), LIVOR) -- the right ear is gone

return {
	name = "Zombie Brute",
	rootSize = V(3.6, 3.6, 1.8), -- center y 5.4: belly and obliques in front, lats and glutes behind
	hipHeight = 3.6,
	pieces = pieces,
}
