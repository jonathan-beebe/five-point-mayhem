-- Yeti: great ape (silverback build, orangutan-length arms) in shaggy white fur, 2.9 m tall,
-- standing bipedal in a menacing mid-stride. Torso pitched forward, head slung low in front of a
-- trapezius hump, knees bent; left foot forward, right foot back. The left arm reaches forward at
-- head height in a grabbing claw, the right arm hangs with its knuckles at knee height.
-- Scale: 4 studs = 1 m. Soles y 0, ankles y 0.85, hip joints y 5, shoulder joints y 9, chin y 9.33,
-- eyes y 10.43, head top y 11.6; left claw tips z -7.9 (the frontmost point).
-- Limbs are cylinders between joint landmarks; joint balls are at least as wide as the limbs they
-- join and limbs end at joint centers. Knees are solved from hip, ankle and limb lengths. Fur locks
-- are wedges hung against the body; fur shades from white to grey and grime toward the ground.

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
local CYLINDER_Z = A(0, rad(90), 0) -- cylinder axis along Z
local CYLINDER_Y = A(0, 0, rad(90)) -- cylinder axis along Y
local FLIP = A(0, 0, math.pi) -- wedge with full top and back faces, slope facing down and out

-- Palette: { color, material, reflectance, transparency }.
local FUR_WHITE = { rgb(236, 236, 230), M.Fabric } -- main coat
local FUR_SNOW = { rgb(246, 247, 247), M.Snow } -- light-catching tops
local FUR_CREAM = { rgb(228, 220, 200), M.Fabric } -- chest, belly, cheeks, inner arms
local FUR_OAT = { rgb(212, 207, 192), M.Fabric }
local FUR_SHAG = { rgb(230, 228, 220), M.Grass } -- coarse long locks
local FUR_GREY = { rgb(186, 186, 181), M.Fabric } -- shadowed coat
local FUR_ASH = { rgb(146, 143, 136), M.Fabric } -- undercoat: crotch, armpits, calves
local FUR_DIRTY = { rgb(168, 152, 128), M.Sand } -- knees, ankle and wrist cuffs
local FUR_MUD = { rgb(118, 100, 82), M.Ground }
local SKIN = { rgb(52, 48, 50), M.Leather }
local SKIN_GREY = { rgb(84, 80, 82), M.Leather } -- brow, nose, knuckles, toes
local SKIN_PALM = { rgb(70, 60, 58), M.Leather } -- soles, palm pads
local LIP = { rgb(36, 30, 32), M.Rubber }
local MOUTH = { rgb(74, 28, 32), M.SmoothPlastic }
local TEETH = { rgb(214, 204, 176), M.Marble }
local CLAW = { rgb(46, 42, 38), M.Slate }
local EYE = { rgb(150, 196, 218), M.Glass, 0.3 }
local SOCKET = { rgb(26, 22, 24), M.Rubber }

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

local function ball(name, diameter, pos, style)
	part(name, V(diameter, diameter, diameter), C(pos), style, BALL)
end

local function cyl(name, size, offset, style)
	part(name, size, offset, style, CYL)
end

local function wedge(name, size, offset, style)
	part(name, size, offset, style, nil, "WedgePart")
end

local function suffix(side)
	return if side < 0 then "L" else "R"
end

-- The left or right style, for fur that shifts tone between the two sides.
local function bySide(side, left, right)
	return if side < 0 then left else right
end

local function lerp(a, b, t)
	return a + (b - a) * t
end

-- Frame at pos with local X along dir.
local function along(pos, dir)
	local x = dir.Unit
	local hint = if math.abs(x.Y) > 0.9 then FORWARD else UP
	local y = (hint - x * hint:Dot(x)).Unit
	return CFrame.fromMatrix(pos, x, y)
end

-- Cylinder from joint a to joint b; extra lengthens it into the joint balls.
local function limb(name, a, b, diameter, style, extra)
	local size = V((b - a).Magnitude + (extra or 0), diameter, diameter)
	cyl(name, size, along((a + b) / 2, b - a), style)
end

-- Hanging fur lock: back face against the body at pos, slope facing out, tapering to a tip below;
-- tilt (degrees) swings the tip out from the body.
local function lock(name, pos, out, size, tilt, style)
	local z = -out.Unit
	local y = (UP - z * z.Y).Unit
	local x = y:Cross(z)
	wedge(name, size, CFrame.fromMatrix(pos, x, y, z) * FLIP * A(-rad(tilt), 0, 0), style)
end

-- Torso ----------------------------------------------------------------------------------------
-- Overlapping balls: chest and belly in front, back and pelvis behind, trapezius hump on top.
ball("Ribcage", 4.4, V(0, 8, -0.6), FUR_CREAM)
ball("UpperBack", 3.8, V(0, 8.9, 0.3), FUR_WHITE)
ball("LowerBack", 3.4, V(0, 6.9, 0.8), FUR_GREY)
ball("Belly", 3.8, V(0, 6.2, -0.6), FUR_CREAM)
ball("Pelvis", 3.4, V(0, 5.3, 0.4), FUR_GREY)
ball("Crotch", 1.6, V(0, 4.5, 0), FUR_ASH)
ball("Trapezius", 2.9, V(0, 9.7, -0.6), FUR_SNOW)

for _, side in { -1, 1 } do
	local s = suffix(side)
	ball("Pec" .. s, 2.1, V(side * 1.1, 8.6, -1.75), FUR_WHITE)
	ball("Lat" .. s, 3.2, V(side * 1.55, 7.6, -0.1), bySide(side, FUR_OAT, FUR_WHITE))
	ball("Hip" .. s, 2.4, V(side * 1.4, 5.1, 0.3), bySide(side, FUR_WHITE, FUR_GREY))
	ball("Flank" .. s, 2.8, V(side * 1.75, 6.6, 0.1), bySide(side, FUR_GREY, FUR_OAT))
	ball("Glute" .. s, 2.4, V(side * 0.9, 5, 1.1), FUR_WHITE)
	ball("Armpit" .. s, 1.5, V(side * 2.3, 8, -0.4), FUR_ASH)
	ball("ShoulderFur" .. s, 1.8, V(side * 3.25, 9, 0.35), FUR_SNOW)
end

-- Torso locks, authored on the left (x <= 0) and mirrored: name, position, out direction, size,
-- tilt, left style, right style.
local TORSO_LOCKS = {
	{ "PecFringe", V(-1.55, 7.8, -2.4), V(-0.5, 0, -1), V(0.8, 1.5, 0.5), 12, FUR_CREAM, FUR_SHAG },
	{ "FlankShagHi", V(-3.05, 7.3, -0.1), V(-1, 0, 0.15), V(0.9, 2, 0.55), 12, FUR_SHAG, FUR_SHAG },
	{ "FlankShagLo", V(-2.85, 5.9, 0.4), V(-1, 0, 0.3), V(0.8, 1.7, 0.5), 10, FUR_GREY, FUR_GREY },
	{ "BackShag", V(-0.95, 7.9, 2.15), V(-0.3, 0, 1), V(0.9, 2, 0.55), 12, FUR_WHITE, FUR_SHAG },
	{ "BellyFringe", V(-0.7, 5.3, -2), V(-0.3, -0.2, -1), V(0.9, 1.6, 0.5), 8, FUR_CREAM, FUR_OAT },
}
for _, spec in TORSO_LOCKS do
	local name, pos, out, size, tilt, left, right = table.unpack(spec)
	for _, side in { -1, 1 } do
		local mirror = V(-side, 1, 1)
		lock(
			name .. suffix(side),
			pos * mirror,
			out * mirror,
			size,
			tilt,
			bySide(side, left, right)
		)
	end
end
lock("BackShagHi", V(-0.5, 9.2, 2), V(0, 0.2, 1), V(1, 1.8, 0.55), 12, FUR_SNOW)
lock("BackShagLo", V(0.45, 6.3, 2.3), V(0, 0, 1), V(0.9, 1.7, 0.5), 10, FUR_GREY)

-- Head -----------------------------------------------------------------------------------------
-- Low and forward of the shoulders; dark face mask framed by cream cheek ruffs.
local HEAD = V(0, 10.45, -2.1)
ball("Head", 2.3, HEAD, FUR_WHITE)
cyl("Crest", V(1.7, 0.95, 0.95), C(HEAD + V(0, 0.6, 0.3)) * A(rad(-15), rad(90), 0), FUR_SNOW)
ball("Occiput", 1.8, HEAD + V(0, 0.1, 0.7), FUR_OAT)
ball("Face", 1.6, HEAD + V(0, -0.25, -0.85), SKIN)
cyl("Brow", V(1.6, 0.42, 0.42), C(HEAD + V(0, 0.22, -1.42)), SKIN_GREY)
ball("Muzzle", 1.15, HEAD + V(0, -0.62, -1.25), SKIN)
cyl("Nose", V(0.62, 0.34, 0.34), C(HEAD + V(0, -0.32, -1.72)), SKIN_GREY)
cyl("UpperLip", V(0.9, 0.22, 0.22), C(HEAD + V(0, -0.66, -1.84)), LIP)
part("Mouth", V(0.8, 0.32, 0.2), C(HEAD + V(0, -0.86, -1.8)), MOUTH)
part("LowerTeeth", V(0.5, 0.08, 0.08), C(HEAD + V(0, -0.98, -1.88)), TEETH)
cyl("Chin", V(1, 0.36, 0.36), C(HEAD + V(0, -1.12, -1.66)), SKIN)
lock("Beard", HEAD + V(0, -1.3, -1.35), V(0, -0.3, -1), V(0.9, 1, 0.45), 8, FUR_CREAM)

for _, side in { -1, 1 } do
	local s = suffix(side)
	ball("Cheek" .. s, 1.3, HEAD + V(side * 0.85, -0.35, -0.6), FUR_CREAM)
	ball("EyeSocket" .. s, 0.42, HEAD + V(side * 0.36, -0.02, -1.45), SOCKET)
	ball("Eye" .. s, 0.24, HEAD + V(side * 0.36, -0.02, -1.6), EYE)
	ball("Nostril" .. s, 0.16, HEAD + V(side * 0.14, -0.43, -1.88), LIP)
	wedge("Fang" .. s, V(0.1, 0.3, 0.1), C(HEAD + V(side * 0.3, -0.82, -1.9)) * FLIP, TEETH)
	local whisker = HEAD + V(side * 0.95, -0.6, -0.95)
	lock("Whisker" .. s, whisker, V(side, 0, -0.6), V(0.7, 1.1, 0.4), 12, FUR_SHAG)
end

-- Legs -----------------------------------------------------------------------------------------
local THIGH, SHIN = 2.7, 2.4

-- Knee position for a two-bone leg from hip to ankle, bending forward.
local function kneeOf(hip, ankle)
	local d = ankle - hip
	local length = d.Magnitude
	local a = (THIGH ^ 2 - SHIN ^ 2 + length ^ 2) / (2 * length)
	local h = math.sqrt(math.max(THIGH ^ 2 - a ^ 2, 0))
	local u = d.Unit
	local perp = (FORWARD - u * FORWARD:Dot(u)).Unit
	return hip + u * a + perp * h
end

-- Mid-stride: left foot forward, right foot back, toes turned out 10 degrees.
local LEGS = {
	{ side = -1, hip = V(-1.35, 5, 0.2), ankle = V(-1.75, 0.85, -1.4) },
	{ side = 1, hip = V(1.35, 5, 0.4), ankle = V(1.75, 0.85, 1.25) },
}
local TOE_X = { 0.55, 0.1, -0.32 } -- outer to inner, local X times side

for _, leg in LEGS do
	local side = leg.side
	local s = suffix(side)
	local hip, ankle = leg.hip, leg.ankle
	local knee = kneeOf(hip, ankle)

	limb("Thigh" .. s, hip, knee, 2.1, bySide(side, FUR_WHITE, FUR_OAT), 0.5)
	local quad = lerp(hip, knee, 0.4) + V(side * 0.35, 0, -0.25)
	ball("Quad" .. s, 2, quad, bySide(side, FUR_OAT, FUR_WHITE))
	local hamstring = lerp(hip, knee, 0.45) + V(0, 0, 1)
	lock("Hamstring" .. s, hamstring, V(side * 0.3, 0, 1), V(0.9, 2, 0.55), 12, FUR_SHAG)
	local thighShag = lerp(hip, knee, 0.5) + V(side * 1.05, 0, 0)
	lock("ThighShag" .. s, thighShag, V(side, 0, 0.2), V(0.8, 1.8, 0.5), 10, FUR_GREY)
	ball("Knee" .. s, 2, knee, FUR_DIRTY)
	limb("Shin" .. s, knee, ankle, 1.45, FUR_GREY)
	ball("Calf" .. s, 1.5, lerp(knee, ankle, 0.3) + V(0, 0, 0.35), FUR_ASH)
	local shinShag = lerp(knee, ankle, 0.4) + V(side * 0.7, 0, 0)
	lock("ShinShag" .. s, shinShag, V(side, 0, 0.3), V(0.8, 1.5, 0.45), 10, FUR_GREY)
	ball("AnkleCuff" .. s, 1.75, ankle + V(0, 0.15, 0), FUR_DIRTY)

	-- Foot frame on the ground under the ankle, local -Z toward the toes.
	local foot = C(ankle.X, 0, ankle.Z) * A(0, rad(-side * 10), 0)
	part("Sole" .. s, V(1.6, 0.4, 2.8), foot * C(0, 0.2, -0.8), SKIN_PALM)
	cyl("FootTop" .. s, V(2.1, 1, 1), foot * C(0, 0.5, -0.85) * A(rad(-8), 0, 0) * CYLINDER_Z, SKIN)
	ball("Heel" .. s, 1.1, (foot * C(0, 0.55, 0.5)).Position, SKIN)
	for i, x in TOE_X do
		ball("Toe" .. s .. i, 0.5, (foot * C(side * x, 0.25, -2.1)).Position, SKIN_GREY)
	end
	local bigToe = foot * C(-side * 0.72, 0.28, -1.75) * A(0, rad(90 - side * 25), 0)
	cyl("BigToe" .. s, V(0.8, 0.55, 0.55), bigToe, SKIN_GREY)
end

-- Arms -----------------------------------------------------------------------------------------
-- dir: fingers' direction; palm: palm normal; curl: finger bend (degrees); out: where the
-- triceps and forearm locks hang; front: where the biceps bulges.
local ARMS = {
	{ -- raised forward in a grabbing claw, palm down
		side = -1,
		shoulder = V(-2.85, 9, -0.9),
		elbow = V(-4.3, 7.7, -3.2),
		wrist = V(-3.7, 9, -5.5),
		dir = V(0.1, 0.35, -1),
		palm = V(0.1, -1, -0.2),
		curl = 30,
		out = V(-0.6, -0.6, 0.5),
		front = V(0.3, 0.6, -0.75),
	},
	{ -- hanging, knuckles at knee height, palm toward the thigh
		side = 1,
		shoulder = V(2.85, 9, -0.9),
		elbow = V(3.35, 6.1, -1.3),
		wrist = V(3.25, 3.5, -2.5),
		dir = V(0.05, -1, -0.3),
		palm = V(-1, 0, 0.2),
		curl = 40,
		out = V(0.6, 0, 0.8),
		front = V(-0.2, 0, -1),
	},
}
-- Fingers, thumb side first: local X (times the thumb side) and length.
local FINGERS = { { 0.43, 0.8 }, { 0.14, 0.95 }, { -0.14, 0.95 }, { -0.43, 0.8 } }

-- Hand frame at the wrist: local +Y along the fingers, local -Z out of the palm.
local function handFrame(pos, dir, palm)
	local y = dir.Unit
	local z = -(palm - y * palm:Dot(y)).Unit
	return CFrame.fromMatrix(pos, y:Cross(z), y, z)
end

for _, arm in ARMS do
	local side = arm.side
	local s = suffix(side)
	local shoulder, elbow, wrist = arm.shoulder, arm.elbow, arm.wrist
	local out = arm.out.Unit

	ball("Deltoid" .. s, 2.4, shoulder + V(side * 0.15, 0.2, 0), bySide(side, FUR_SNOW, FUR_WHITE))
	local deltoidShag = shoulder + V(side * 1.3, -0.3, 0.1)
	lock("DeltoidShag" .. s, deltoidShag, V(side, 0, 0.2), V(0.9, 1.8, 0.5), 12, FUR_SHAG)
	limb("UpperArm" .. s, shoulder, elbow, 1.9, bySide(side, FUR_WHITE, FUR_OAT), 0.3)
	ball("Biceps" .. s, 1.8, lerp(shoulder, elbow, 0.45) + arm.front * 0.35, FUR_CREAM)
	local triceps = lerp(shoulder, elbow, 0.5) + out * 0.8
	lock("Triceps" .. s, triceps, out, V(0.9, 1.7, 0.5), 12, FUR_SHAG)
	ball("Elbow" .. s, 1.95, elbow, FUR_GREY)
	limb("Forearm" .. s, elbow, wrist, 1.7, FUR_WHITE)
	ball("ForearmMass" .. s, 1.95, lerp(elbow, wrist, 0.3), FUR_CREAM)
	local shagA = lerp(elbow, wrist, 0.35) + out * 0.75
	lock("ForearmShagA" .. s, shagA, out, V(0.9, 1.8, 0.5), 14, FUR_WHITE)
	local shagB = lerp(elbow, wrist, 0.75) + out * 0.65
	lock("ForearmShagB" .. s, shagB, out, V(0.8, 1.5, 0.45), 14, bySide(side, FUR_DIRTY, FUR_MUD))
	ball("Wrist" .. s, 1.8, wrist, FUR_DIRTY)

	-- Hand: thumb on the medial side (local +X on the left hand, -X on the right).
	local hand = handFrame(wrist, arm.dir, arm.palm)
	local thumb = -side
	part("Palm" .. s, V(1.25, 1.2, 0.6), hand * C(0, 0.65, 0), SKIN)
	part("PalmPad" .. s, V(1.05, 0.9, 0.1), hand * C(0, 0.6, -0.32), SKIN_PALM)
	cyl("Knuckles" .. s, V(1.3, 0.5, 0.5), hand * C(0, 1.25, 0.05), SKIN_GREY)
	local curl = A(rad(-arm.curl), 0, 0)
	for i, finger in FINGERS do
		local x, length = finger[1], finger[2]
		local base = hand * C(x * thumb, 1.3, 0) * curl
		cyl(
			"Finger" .. s .. i,
			V(length, 0.36, 0.36),
			base * C(0, length / 2, 0) * CYLINDER_Y,
			SKIN
		)
		local claw = base * C(0, length + 0.05, -0.05) * curl * FLIP
		wedge("Claw" .. s .. i, V(0.2, 0.32, 0.22), claw, CLAW)
	end
	local thumbBase = hand * C(thumb * 0.62, 0.35, -0.15) * A(rad(-25), 0, rad(-thumb * 35))
	cyl("Thumb" .. s, V(0.8, 0.4, 0.4), thumbBase * C(0, 0.4, 0) * CYLINDER_Y, SKIN)
end

return {
	name = "Yeti",
	rootSize = V(4.4, 4.4, 2.2),
	hipHeight = 4.4,
	-- The left claw is ~7.9 forward of the root's center.
	reach = 6.5,
	pieces = pieces,
}
