-- Skeleton Knight: a 14th-century knight reduced to bone, still in what is left of his harness.
-- Advancing in plough guard: longsword two-handed, hilt before the right hip, point raised at
-- face height. Left foot forward and flat, right foot back on its toes, knees bent, torso pitched
-- 8 degrees forward, skull rolled 5 degrees with the jaw hanging open.
-- Salvaged armour: right arm and left leg in plate, left arm and right leg bare bone. The torso
-- between gorget and belt is open: ribcage over a hollow abdomen with only the lumbar spine.
-- Scale: 4 studs = 1 m, 5.67 tall at the helmet apex. Eyes y 5.0, shoulders (+-0.58, 4.39),
-- belt y 2.95, hip joints (+-0.42, 2.8); the sword point reaches (-0.36, 4.16, -3.43).

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
-- Bone darkens from the sun-bleached skull down to soil-stained joints and spine.
local BONE_SKULL = { rgb(218, 207, 180), M.Plaster }
local BONE_PALE = { rgb(206, 197, 172), M.Plaster }
local BONE_AGED = { rgb(190, 175, 140), M.Concrete }
local BONE_DARK = { rgb(150, 133, 100), M.Concrete }
local TEETH = { rgb(178, 156, 104), M.Marble }
local CAVITY = { rgb(30, 25, 22), M.Slate }
local EYE = { rgb(255, 38, 24), M.Neon }
local STEEL = { rgb(122, 124, 126), M.Metal, 0.08 }
local STEEL_DARK = { rgb(80, 82, 85), M.Metal, 0.04 }
local STEEL_BLUE = { rgb(96, 100, 108), M.Metal, 0.05 }
local RUST = { rgb(116, 68, 40), M.CorrodedMetal }
local RUST_DARK = { rgb(82, 52, 34), M.CorrodedMetal }
local MAIL = { rgb(74, 72, 68), M.CorrodedMetal }
local BLADE = { rgb(166, 170, 174), M.Metal, 0.18 }
local BLADE_WORN = { rgb(140, 142, 142), M.Metal, 0.1 }
local BRASS = { rgb(138, 108, 56), M.Metal, 0.05 }
local LEATHER = { rgb(60, 40, 27), M.Leather }
local LEATHER_WORN = { rgb(88, 64, 44), M.Leather }
local CLOTH = { rgb(90, 40, 36), M.Fabric } -- faded oxblood
local CLOTH_DIRTY = { rgb(66, 52, 41), M.Fabric }

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

local function ball(name, diameter, offset, style)
	part(name, V(diameter, diameter, diameter), offset, style, BALL)
end

local function cyl(name, length, diameter, offset, style)
	part(name, V(length, diameter, diameter), offset, style, CYL)
end

local function wedge(name, size, offset, style)
	part(name, size, offset, style, nil, "WedgePart")
end

-- A frame at `position` whose -Z points along `direction`, +Y as close to up as possible.
local function facing(position, direction)
	local up = if math.abs(direction.Unit.Y) > 0.99 then Vector3.xAxis else Vector3.yAxis
	return CFrame.lookAt(position, position + direction, up)
end

-- Cylinder from `a` to `b`.
local function segment(name, a, b, diameter, style)
	cyl(name, (b - a).Magnitude, diameter, facing((a + b) / 2, b - a) * CYLINDER_Z, style)
end

-- Short cylinder centered at `center` with its axis along `axis`.
local function disc(name, center, axis, diameter, thickness, style)
	cyl(name, thickness, diameter, facing(center, axis) * CYLINDER_Z, style)
end

-- Two-bone IK: the middle joint for a chain from `from` to `to`, bending toward `pole`.
local function joint(from, to, upper, lower, pole)
	local reach = to - from
	local d = reach.Magnitude
	local u = reach.Unit
	local along = (upper * upper + d * d - lower * lower) / (2 * d)
	local out = math.sqrt(math.max(0, upper * upper - along * along))
	local bend = (pole - u * pole:Dot(u)).Unit
	return from + u * along + bend * out
end

-- Frames --------------------------------------------------------------------------------------
-- TORSO: pivot at L3, leaning forward. HEAD: cranium center, chin up 6 degrees, rolled 5. JAW:
-- the jaw hinge, open 14 degrees. SWORD: grip center, -Z toward the point, +Y along the edges.
-- Pelvis, skirt, scabbard and legs are built in creature space.
local TORSO = C(0, 3.2, 0) * A(rad(-8), 0, 0)
local HEAD = TORSO * C(0, 1.96, -0.06) * A(rad(6), 0, rad(5))
local JAW = HEAD * C(0, -0.22, 0.04) * A(rad(-14), 0, 0)
local SWORD = facing(V(0.24, 3.08, -0.72), V(-0.22, 0.4, -1))

-- Head ----------------------------------------------------------------------------------------
-- Bascinet with its visor lost (only the rusted pivots remain), mail aventail below.
ball("Head", 0.62, HEAD * C(0, 0, 0.03), BONE_SKULL)
ball("HelmetBowl", 0.72, HEAD * C(0, 0.13, 0.06), STEEL)
wedge("HelmetPeak", V(0.2, 0.16, 0.26), HEAD * C(0, 0.44, 0.13), STEEL)
cyl("HelmetBrow", 0.06, 0.74, HEAD * C(0, -0.03, 0.06) * CYLINDER_Y, STEEL_DARK)
for _, side in { -1, 1 } do
	local s = side < 0 and "L" or "R"
	part("Orbit" .. s, V(0.15, 0.12, 0.04), HEAD * C(side * 0.115, -0.11, -0.265), CAVITY)
	ball("Eye" .. s, 0.075, HEAD * C(side * 0.115, -0.11, -0.285), EYE)
	part(
		"Cheekbone" .. s,
		V(0.09, 0.07, 0.2),
		HEAD * C(side * 0.205, -0.2, -0.17) * A(0, rad(side * 15), 0),
		BONE_AGED
	)
	cyl("VisorPivot" .. s, 0.04, 0.09, HEAD * C(side * 0.355, 0, 0), RUST)
end
part("NasalCavity", V(0.08, 0.11, 0.03), HEAD * C(0, -0.2, -0.27), CAVITY)
part("Maxilla", V(0.27, 0.1, 0.18), HEAD * C(0, -0.29, -0.16), BONE_AGED)
part("UpperTeeth", V(0.23, 0.06, 0.05), HEAD * C(0, -0.355, -0.235), TEETH)
part("Mandible", V(0.27, 0.08, 0.26), JAW * C(0, -0.2, -0.17), BONE_AGED)
part("LowerTeeth", V(0.21, 0.05, 0.05), JAW * C(0, -0.135, -0.27), TEETH)
cyl("Aventail", 0.32, 0.66, HEAD * C(0, -0.38, 0.13) * CYLINDER_Y, MAIL)

-- Chest ---------------------------------------------------------------------------------------
cyl("GorgetUpper", 0.1, 0.56, TORSO * C(0, 1.55, 0.04) * CYLINDER_Y, STEEL_DARK)
cyl("GorgetLower", 0.1, 0.7, TORSO * C(0, 1.46, 0.04) * CYLINDER_Y, STEEL)
cyl("ThoracicSpine", 0.82, 0.12, TORSO * C(0, 0.98, 0.2) * CYLINDER_Y, BONE_DARK)
part("Manubrium", V(0.17, 0.15, 0.05), TORSO * C(0, 1.27, -0.27) * A(rad(8), 0, 0), BONE_PALE)
part("Sternum", V(0.11, 0.42, 0.05), TORSO * C(0, 0.98, -0.31) * A(rad(8), 0, 0), BONE_PALE)

for _, side in { -1, 1 } do
	segment(
		side < 0 and "ClavicleL" or "ClavicleR",
		TORSO * V(side * 0.07, 1.36, -0.25),
		TORSO * V(side * 0.56, 1.42, -0.02),
		0.065,
		BONE_AGED
	)
end

-- Backplate: rusted on the left, bright on the right.
part("BackplateCentre", V(0.46, 0.8, 0.07), TORSO * C(0, 0.95, 0.33), STEEL_BLUE)
for _, side in { -1, 1 } do
	part(
		side < 0 and "BackplateL" or "BackplateR",
		V(0.28, 0.74, 0.07),
		TORSO * C(side * 0.33, 0.95, 0.24) * A(0, rad(side * 42), 0),
		side < 0 and RUST or STEEL
	)
end

-- Ribs run from the spine out along the side, then slope down toward the sternum and stop short
-- of it where the cartilage has rotted. `y` is the rib's height at the spine, `width` its
-- half-width at the side.
local RIBS = {
	{ y = 1.24, width = 0.34 },
	{ y = 1.08, width = 0.4 },
	{ y = 0.92, width = 0.44 },
	{ y = 0.76, width = 0.46 },
	{ y = 0.6, width = 0.46 },
}
local OVERLAP = 0.025 -- each segment runs past the rib's bend so the corner closes

for i, rib in RIBS do
	local odd = i % 2 == 1
	for _, side in { -1, 1 } do
		local name = "Rib" .. i .. (side < 0 and "L" or "R")
		local back = TORSO * V(side * (rib.width - 0.1), rib.y, 0.25)
		local bend = TORSO * V(side * rib.width, rib.y - 0.05, -0.03)
		local tip = TORSO * V(side * 0.12, rib.y - 0.17, -0.29)
		segment(
			name .. "Side",
			back,
			bend + (bend - back).Unit * OVERLAP,
			0.055,
			odd and BONE_PALE or BONE_AGED
		)
		segment(
			name .. "Front",
			bend - (tip - bend).Unit * OVERLAP,
			tip,
			0.05,
			odd and BONE_AGED or BONE_DARK
		)
	end
end

for _, side in { -1, 1 } do
	segment(
		side < 0 and "FloatingRibL" or "FloatingRibR",
		TORSO * V(side * 0.34, 0.46, 0.25),
		TORSO * V(side * 0.43, 0.38, 0.02),
		0.045,
		BONE_DARK
	)
end

-- Abdomen and pelvis --------------------------------------------------------------------------
-- Hollow but for the lumbar column; the iliac wings and sacrum show above the belt.
cyl("LumbarCore", 0.6, 0.08, TORSO * C(0, 0.28, 0.16) * CYLINDER_Y, BONE_DARK)
for i, y in { 0.12, 0.3, 0.48 } do
	cyl(
		"Lumbar" .. i,
		0.1,
		0.17,
		TORSO * C(0, y, 0.14) * CYLINDER_Y,
		i == 2 and BONE_DARK or BONE_AGED
	)
end
for _, side in { -1, 1 } do
	part(
		side < 0 and "IliumL" or "IliumR",
		V(0.07, 0.3, 0.34),
		C(side * 0.29, 3.12, 0.02) * A(0, 0, rad(-side * 22)),
		BONE_DARK
	)
end
part("Sacrum", V(0.2, 0.28, 0.07), C(0, 3.08, 0.2) * A(rad(-30), 0, 0), BONE_AGED)

-- Belt, haubergeon skirt with a rusted hem, and the tattered surcoat.
cyl("Belt", 0.12, 1.02, C(0, 2.95, 0) * CYLINDER_Y, LEATHER)
part("Buckle", V(0.14, 0.13, 0.04), C(0, 2.95, -0.52), BRASS)
cyl("MailSkirtUpper", 0.34, 0.94, C(0, 2.76, 0.02) * CYLINDER_Y, MAIL)
cyl("MailSkirtLower", 0.4, 1, C(0, 2.4, 0.02) * CYLINDER_Y, MAIL)
cyl("MailHem", 0.08, 1.06, C(0, 2.2, 0.02) * CYLINDER_Y, RUST_DARK)
part("SurcoatFront", V(0.34, 0.62, 0.03), C(-0.05, 2.62, -0.53) * A(rad(10), 0, 0), CLOTH)
part("SurcoatStrip", V(0.15, 0.42, 0.03), C(0.2, 2.72, -0.52) * A(rad(8), 0, rad(5)), CLOTH_DIRTY)
part("SurcoatBack", V(0.42, 0.78, 0.03), C(-0.03, 2.54, 0.53) * A(rad(-8), 0, 0), CLOTH_DIRTY)

-- Scabbard slung off the left hip, back and down 35 degrees; +Z runs from the locket to the chape.
local SCABBARD = C(-0.6, 2.9, -0.12) * A(rad(35), 0, 0)
local SCABBARD_LENGTH = 2.55
part("Scabbard", V(0.07, 0.15, SCABBARD_LENGTH), SCABBARD * C(0, 0, SCABBARD_LENGTH / 2), LEATHER)
part("ScabbardLocket", V(0.09, 0.19, 0.18), SCABBARD * C(0, 0, 0.1), BRASS)
part("ScabbardChape", V(0.09, 0.17, 0.22), SCABBARD * C(0, 0, SCABBARD_LENGTH - 0.1), RUST)

-- Sword ---------------------------------------------------------------------------------------
-- Longsword: wheel pommel, two-hand grip, straight crossguard, a tapering blade with a dark
-- fuller, and a diamond point closed by two wedges.
cyl("Grip", 0.56, 0.075, SWORD * CYLINDER_Z, LEATHER_WORN)
cyl("Pommel", 0.07, 0.17, SWORD * C(0, 0, 0.33), STEEL_DARK)
part("Crossguard", V(0.06, 0.62, 0.06), SWORD * C(0, 0, -0.31), STEEL_DARK)
part("BladeForte", V(0.04, 0.17, 1.6), SWORD * C(0, 0, -1.14), BLADE)
part("Fuller", V(0.046, 0.04, 1.2), SWORD * C(0, 0, -0.98), STEEL_DARK)
part("BladeFoible", V(0.035, 0.13, 0.76), SWORD * C(0, 0, -2.32), BLADE_WORN)
wedge("PointUpper", V(0.035, 0.065, 0.28), SWORD * C(0, 0.0325, -2.84), BLADE_WORN)
wedge(
	"PointLower",
	V(0.035, 0.065, 0.28),
	SWORD * C(0, -0.0325, -2.84) * A(0, 0, math.pi),
	BLADE_WORN
)

-- Arms ----------------------------------------------------------------------------------------
-- Both hands on the grip: the right gauntlet below the crossguard, the bare left hand behind it
-- at the pommel. `pole` is the direction the elbow bends toward.
local UPPER, FORE = 1, 0.91 -- shoulder to elbow, elbow to hand center
local ARMS = {
	[-1] = {
		hand = SWORD * V(0, 0, 0.16),
		pole = V(-1, -0.5, 0.1),
		pauldron = STEEL_DARK,
		lames = { RUST, STEEL },
	},
	[1] = {
		hand = SWORD * V(0, 0, -0.12),
		pole = V(1, -0.3, 0.7),
		pauldron = STEEL,
		lames = { STEEL_DARK, RUST },
	},
}

for _, side in { -1, 1 } do
	local s = side < 0 and "L" or "R"
	local arm = ARMS[side]
	local shoulder = TORSO * V(side * 0.58, 1.2, 0.02)
	local hand = arm.hand
	local elbow = joint(shoulder, hand, UPPER, FORE, arm.pole)
	local upper = (elbow - shoulder).Unit
	local fore = (hand - elbow).Unit
	local wrist = hand - fore * 0.13
	local outward = upper:Cross(fore).Unit -- elbow's outer side
	if outward.X * side < 0 then
		outward = -outward
	end
	local grip = SWORD.Rotation + hand

	ball("Pauldron" .. s, 0.52, C(shoulder + V(side * 0.05, 0.03, 0.02)), arm.pauldron)
	disc("PauldronLame1" .. s, shoulder + upper * 0.24, upper, 0.44, 0.1, arm.lames[1])
	disc("PauldronLame2" .. s, shoulder + upper * 0.33, upper, 0.38, 0.1, arm.lames[2])

	if side > 0 then
		segment("Rerebrace" .. s, shoulder + upper * 0.3, elbow - upper * 0.1, 0.24, STEEL)
		ball("Couter" .. s, 0.25, C(elbow), STEEL_DARK)
		disc("CouterWing" .. s, elbow + outward * 0.13, outward, 0.26, 0.035, STEEL)
		segment("Vambrace" .. s, elbow + fore * 0.1, wrist, 0.21, STEEL_BLUE)
		disc("GauntletCuff" .. s, wrist, fore, 0.25, 0.16, STEEL_DARK)
		part("Gauntlet" .. s, V(0.18, 0.2, 0.15), grip, STEEL_DARK)
	else
		segment("Humerus" .. s, shoulder + upper * 0.22, elbow - upper * 0.06, 0.1, BONE_AGED)
		disc("ElbowCondyles" .. s, elbow - upper * 0.02, outward, 0.15, 0.2, BONE_DARK)
		-- Ulna on the outer side of the forearm, radius on the inner.
		segment(
			"Ulna" .. s,
			elbow - fore * 0.05 + outward * 0.035,
			wrist + outward * 0.02,
			0.07,
			BONE_AGED
		)
		segment(
			"Radius" .. s,
			elbow + fore * 0.05 - outward * 0.04,
			wrist - outward * 0.03,
			0.065,
			BONE_PALE
		)
		ball("Carpals" .. s, 0.11, C(wrist), BONE_DARK)
		part("Palm" .. s, V(0.05, 0.17, 0.13), grip * C(-0.075, 0, 0), BONE_AGED)
		part("Fingers" .. s, V(0.15, 0.05, 0.13), grip * C(0, -0.07, 0), BONE_AGED)
		part("Thumb" .. s, V(0.1, 0.04, 0.045), grip * C(-0.02, 0.06, 0), BONE_PALE)
	end
end

-- Legs ----------------------------------------------------------------------------------------
-- Left leg leads in plate, foot flat. Right leg trails as bare bone, the foot pitched onto its
-- toes with the heel raised.
local FEMUR, TIBIA = 1.44, 1.29
local KNEE_POLE = V(0, 0, -1)
local PUSH_OFF = 24 -- degrees the trailing foot pitches toes-down
local LEGS = {
	[-1] = { hip = V(-0.42, 2.8, 0), ankle = V(-0.45, 0.3, -0.72) },
	[1] = { hip = V(0.42, 2.8, 0), ankle = V(0.46, 0.36, 1.08) },
}

for _, side in { -1, 1 } do
	local s = side < 0 and "L" or "R"
	local hip, ankle = LEGS[side].hip, LEGS[side].ankle
	local knee = joint(hip, ankle, FEMUR, TIBIA, KNEE_POLE)
	local thigh = (knee - hip).Unit
	local shin = (ankle - knee).Unit

	if side < 0 then
		segment("Cuisse" .. s, hip + thigh * 0.35, knee - thigh * 0.12, 0.3, STEEL)
		disc("CuisseLame" .. s, knee - thigh * 0.17, thigh, 0.32, 0.08, RUST)
		ball("Poleyn" .. s, 0.28, C(knee + V(0, 0, -0.04)), STEEL)
		disc(
			"PoleynWing" .. s,
			knee + V(side * 0.15, 0, 0.01),
			Vector3.xAxis,
			0.26,
			0.035,
			STEEL_DARK
		)
		segment("Greave" .. s, knee + shin * 0.12, ankle - shin * 0.04, 0.24, STEEL_BLUE)
		ball("AnkleCop" .. s, 0.24, C(ankle + V(0, -0.04, 0.02)), STEEL_DARK)
		-- Sabaton: plated instep and pointed toe on a leather sole.
		part("SabatonInstep" .. s, V(0.24, 0.14, 0.36), C(ankle.X, 0.11, ankle.Z - 0.2), STEEL)
		wedge("SabatonToe" .. s, V(0.22, 0.12, 0.28), C(ankle.X, 0.1, ankle.Z - 0.51), STEEL_DARK)
		part(
			"SabatonSole" .. s,
			V(0.24, 0.04, 0.84),
			C(ankle.X, 0.02, ankle.Z - 0.24),
			LEATHER_WORN
		)
	else
		local front = V(1, 0, 0):Cross(shin).Unit -- perpendicular to the tibia
		if front.Z > 0 then
			front = -front
		end
		segment("Femur" .. s, hip + thigh * 0.3, knee - thigh * 0.08, 0.11, BONE_AGED)
		cyl("FemoralCondyles" .. s, 0.22, 0.17, C(knee - thigh * 0.04), BONE_DARK)
		ball("Patella" .. s, 0.11, C(knee + (front - thigh * 0.3).Unit * 0.09), BONE_PALE)
		cyl("TibialPlateau" .. s, 0.2, 0.13, C(knee + shin * 0.08), BONE_AGED)
		segment("Tibia" .. s, knee + shin * 0.1, ankle - shin * 0.04, 0.085, BONE_PALE)
		segment(
			"Fibula" .. s,
			knee + shin * 0.14 + V(0.065, 0, 0.03),
			ankle + V(0.055, 0, 0.02),
			0.04,
			BONE_DARK
		)

		local foot = C(ankle) * A(rad(-PUSH_OFF), 0, 0)
		ball("Talus" .. s, 0.13, C(ankle), BONE_DARK)
		part("Calcaneus" .. s, V(0.12, 0.12, 0.2), foot * C(0, -0.07, 0.1), BONE_AGED)
		part("Tarsals" .. s, V(0.16, 0.09, 0.2), foot * C(0, -0.07, -0.13), BONE_DARK)
		part("Metatarsals" .. s, V(0.21, 0.05, 0.3), foot * C(0.01, -0.11, -0.36), BONE_AGED)
		-- Toes bend back flat on the ground ahead of the ball of the foot.
		local ballOfFoot = foot * V(0.01, -0.11, -0.51)
		part(
			"Toes" .. s,
			V(0.23, 0.04, 0.15),
			C(ankle.X + 0.01, 0.02, ballOfFoot.Z - 0.06),
			BONE_PALE
		)
	end
end

return {
	name = "Skeleton Knight",
	-- Narrower than the 2-wide guide: the skirt is 1 wide and the ribcage 0.94.
	rootSize = V(1.4, 2, 1),
	hipHeight = 2,
	reach = 4.5,
	pieces = pieces,
}
