-- Goblin: small, wiry, hunched cave goblin in film creature style. Leathery olive skin flushed at
-- the nose, ears, elbows and knees; scrap leather and cloth gear; a notched iron cleaver.
-- Scale: 4 studs = 1 m, 4.3 studs to the ear tips. Pose: ready crouch, spine pitched 28 degrees
-- forward, left foot forward, left claw reaching, cleaver held low in the right fist, point up.
-- Landmarks: soles y 0, hip joints y 1.84, belt y 2.09, shoulders y 3.11, eyes y 3.72 z -1.35,
-- head top y 4.28. Root spans x -0.8..0.8, y 1.6..3.2, z -0.4..0.4 inside pelvis, ribs and hump.

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

-- WedgePart default: slope rises from the -Z bottom edge to the +Z top edge.
local UP_BACK = A(0, math.pi, 0) -- slope rises toward -Z, faces up and back

-- Palette: { color, material, reflectance, transparency }.
local SKIN = { rgb(106, 108, 80), M.Leather }
local SKIN_DARK = { rgb(82, 86, 62), M.Leather }
local SKIN_BELLY = { rgb(138, 132, 102), M.Leather }
local SKIN_FLUSH = { rgb(130, 102, 84), M.Leather }
local SKIN_SCALP = { rgb(94, 96, 76), M.Slate }
local SKIN_GRIME = { rgb(78, 70, 54), M.Leather }
local SOCKET = { rgb(48, 40, 34), M.Leather }
local EYE = { rgb(206, 170, 58), M.Glass, 0.3 }
local MOUTH = { rgb(42, 26, 24), M.SmoothPlastic }
local TOOTH = { rgb(176, 162, 118), M.Marble }
local NAIL = { rgb(58, 50, 40), M.Slate }
local LEATHER = { rgb(72, 50, 34), M.Leather }
local LEATHER_WORN = { rgb(98, 72, 48), M.Leather }
local CLOTH = { rgb(86, 76, 56), M.Fabric }
local CLOTH_DIRTY = { rgb(66, 58, 44), M.Fabric }
local RUST = { rgb(104, 82, 64), M.CorrodedMetal }
local IRON = { rgb(80, 78, 74), M.Metal, 0.1 }
local EDGE = { rgb(146, 142, 134), M.Metal, 0.25 }
local WRAP = { rgb(118, 98, 70), M.Fabric }

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

local function cyl(name, size, offset, style)
	part(name, size, offset, style, CYL)
end

local function ball(name, diameter, offset, style)
	part(name, V(diameter, diameter, diameter), offset, style, BALL)
end

local function wedge(name, size, offset, style)
	part(name, size, offset, style, nil, "WedgePart")
end

-- Frame at the midpoint of a..b with local X along a->b (a cylinder's axis).
local function alongX(a, b)
	local dir = (b - a).Unit
	local ref = math.abs(dir.Y) > 0.95 and Vector3.zAxis or Vector3.yAxis
	local up = (ref - dir * ref:Dot(dir)).Unit
	return CFrame.fromMatrix((a + b) / 2, dir, up)
end

-- Frame at the midpoint of a..b with local Y along a->b and local X near world X.
local function alongY(a, b)
	local dir = (b - a).Unit
	local right = (Vector3.xAxis - dir * dir.X).Unit
	return CFrame.fromMatrix((a + b) / 2, right, dir)
end

-- Cylinder from joint a to joint b, lengthened by `overlap` so it buries into both joints.
local function limb(name, a, b, diameter, style, overlap)
	local length = (b - a).Magnitude + (overlap or 0)
	cyl(name, V(length, diameter, diameter), alongX(a, b), style)
end

local function sideName(side)
	return side < 0 and "L" or "R"
end

-- Joints. Index by side: -1 is the creature's left (-X), 1 its right.
local ELBOW = { [-1] = V(-0.92, 2.36, -0.66), [1] = V(1.0, 2.3, -0.2) }
local WRIST = { [-1] = V(-0.76, 2.12, -1.56), [1] = V(0.86, 1.92, -0.96) }
local HIP = { [-1] = V(-0.36, 1.84, 0.12), [1] = V(0.36, 1.84, 0.12) }
local KNEE = { [-1] = V(-0.5, 1.2, -0.5), [1] = V(0.54, 1.05, -0.25) }
local ANKLE = { [-1] = V(-0.46, 0.3, -0.36), [1] = V(0.48, 0.3, 0.36) }

-- Torso ---------------------------------------------------------------------------------------
-- Spine frame: local +Y runs up the spine, -Z is the belly side.
local TF = C(0, 1.95, 0.15) * A(rad(-28), 0, 0)

cyl("Pelvis", V(1.0, 0.7, 0.7), C(0, 1.93, 0.18), SKIN_DARK)
cyl("Abdomen", V(0.7, 0.82, 0.82), TF * C(0, 0.5, -0.02) * CYLINDER_Y, SKIN)
ball("Belly", 0.62, TF * C(0, 0.55, -0.16), SKIN_BELLY)
ball("Ribcage", 1.08, TF * C(0, 1.02, 0), SKIN)
ball("BackHump", 0.98, TF * C(0, 1.12, 0.3), SKIN_DARK)
ball("Trapezius", 0.62, TF * C(0, 1.5, 0.12), SKIN_DARK)
cyl("Collarbone", V(0.96, 0.07, 0.07), TF * C(0, 1.38, -0.33), SKIN)
for _, side in { -1, 1 } do
	cyl(
		"Rib" .. sideName(side),
		V(0.34, 0.07, 0.07),
		TF * C(side * 0.3, 0.84, -0.38) * A(0, side * rad(-48), side * rad(-18)),
		SKIN_BELLY
	)
end

-- Neck and head -------------------------------------------------------------------------------
-- Head frame: pushed forward of the chest and tipped 8 degrees down.
local HF = C(0, 3.74, -0.98) * A(rad(-8), 0, 0)
limb("Neck", (TF * C(0, 1.5, -0.08)).Position, (HF * C(0, -0.3, 0.12)).Position, 0.34, SKIN, 0.1)

ball("Head", 0.82, HF * C(0, 0.12, 0.1), SKIN_SCALP)
ball("Occiput", 0.68, HF * C(0, 0.06, 0.38), SKIN_DARK)
part("Brow", V(0.58, 0.12, 0.2), HF * C(0, 0.12, -0.25) * A(rad(-12), 0, 0), SKIN)
part("Midface", V(0.46, 0.34, 0.3), HF * C(0, -0.1, -0.2), SKIN)
part("NoseBridge", V(0.12, 0.3, 0.13), HF * C(0, -0.07, -0.42) * A(rad(-26), 0, 0), SKIN)
ball("NoseTip", 0.18, HF * C(0, -0.21, -0.52), SKIN_FLUSH)
part("Jaw", V(0.5, 0.2, 0.42), HF * C(0, -0.34, -0.18) * A(rad(8), 0, 0), SKIN)
ball("Chin", 0.22, HF * C(0, -0.4, -0.38), SKIN_DARK)
part("Mouth", V(0.34, 0.04, 0.06), HF * C(0, -0.27, -0.41), MOUTH)

for _, side in { -1, 1 } do
	local s = sideName(side)
	ball("Cheek" .. s, 0.24, HF * C(side * 0.21, -0.07, -0.26), SKIN)
	ball("Socket" .. s, 0.17, HF * C(side * 0.13, 0.03, -0.31), SOCKET)
	ball("Eye" .. s, 0.1, HF * C(side * 0.13, 0.03, -0.37), EYE)
	-- Lower tusk: slope faces forward, point up.
	wedge("Tusk" .. s, V(0.05, 0.13, 0.06), HF * C(side * 0.12, -0.22, -0.42) * UP_BACK, TOOTH)

	-- Ear: long triangle with its root edge in the skull, swept 45 degrees out and 24 up.
	local ear = HF
		* C(side * 0.4, 0.06, 0.06)
		* A(0, side * rad(45), 0)
		* A(rad(-24), 0, 0)
		* UP_BACK
	wedge("Ear" .. s, V(0.06, 0.34, 0.78), ear * C(0, 0, -0.34), SKIN_DARK)
	wedge("EarInner" .. s, V(0.04, 0.22, 0.5), ear * C(-side * 0.035, -0.04, -0.22), SKIN_FLUSH)
end

-- Arms ----------------------------------------------------------------------------------------
local SHOULDER = {
	[-1] = (TF * C(-0.66, 1.3, 0.02)).Position,
	[1] = (TF * C(0.66, 1.3, 0.02)).Position,
}

for _, side in { -1, 1 } do
	local s = sideName(side)
	local shoulder = SHOULDER[side]
	local elbow, wrist = ELBOW[side], WRIST[side]
	ball("Deltoid" .. s, 0.44, C(shoulder), SKIN_DARK)
	limb("UpperArm" .. s, shoulder, elbow, 0.28, SKIN)
	ball("Elbow" .. s, 0.26, C(elbow), SKIN_FLUSH)
	limb("Forearm" .. s, elbow, wrist, 0.24, SKIN_DARK)
	ball("ForearmMuscle" .. s, 0.32, C(elbow:Lerp(wrist, 0.28)), SKIN)
end

-- Left hand: open claw reaching forward, three fingers curling down.
do
	local reach = (WRIST[-1] - ELBOW[-1]).Unit
	local knuckles = WRIST[-1] + reach * 0.32
	part("HandL", V(0.26, 0.32, 0.09), alongY(WRIST[-1], knuckles), SKIN)
	for k = -1, 1 do
		local base = knuckles + V(k * 0.085, 0, 0)
		local tip = base + reach * 0.18 + V(k * 0.04, -0.22, 0)
		limb("FingerL" .. (k + 2), base, tip, 0.065, SKIN, 0.04)
		limb("ClawL" .. (k + 2), tip, tip + V(0, -0.08, 0.04), 0.045, NAIL, 0.02)
	end
	local thumb = WRIST[-1] + reach * 0.12 + V(0.12, 0, 0)
	limb("ThumbL", thumb, thumb + V(0.14, -0.12, -0.12), 0.07, SKIN)
end

-- Right hand: fist and leather bracer.
local FIST = WRIST[1] + (WRIST[1] - ELBOW[1]).Unit * 0.14
ball("FistR", 0.3, C(FIST), SKIN)
cyl(
	"BracerR",
	V(0.36, 0.3, 0.3),
	alongX(ELBOW[1]:Lerp(WRIST[1], 0.55), ELBOW[1]:Lerp(WRIST[1], 0.95)),
	LEATHER
)

-- Cleaver: grip through the fist, blade pitched 35 degrees up from forward -------------------
-- Blade frame: local +Y runs from the fist to the point, -Z is the cutting edge.
local BF = alongY(FIST, FIST + V(0, math.sin(rad(35)), -math.cos(rad(35))))
cyl("Grip", V(0.5, 0.1, 0.1), BF * C(0, 0.04, 0) * CYLINDER_Y, WRAP)
part("Guard", V(0.12, 0.08, 0.34), BF * C(0, 0.3, 0), IRON)
part("Blade", V(0.05, 1.3, 0.3), BF * C(0, 1.0, 0.03), IRON)
part("BladeEdge", V(0.035, 1.3, 0.06), BF * C(0, 1.0, -0.15), EDGE)
wedge("BladeTip", V(0.05, 0.36, 0.36), BF * C(0, 1.83, 0), IRON)

-- Legs ----------------------------------------------------------------------------------------
for _, side in { -1, 1 } do
	local s = sideName(side)
	local knee, ankle = KNEE[side], ANKLE[side]
	limb("Thigh" .. s, HIP[side], knee, 0.46, SKIN, 0.1)
	ball("Knee" .. s, 0.34, C(knee), SKIN_FLUSH)
	limb("Shin" .. s, knee, ankle, 0.26, SKIN)
	ball("Calf" .. s, 0.36, C(knee:Lerp(ankle, 0.3) + V(0, 0, 0.12)), SKIN_DARK)

	-- Foot frame: on the ground under the ankle, toes turned out 12 degrees.
	local foot = C(ankle.X, 0, ankle.Z) * A(0, side * rad(-12), 0)
	ball("Heel" .. s, 0.3, foot * C(0, 0.15, 0.08), SKIN_GRIME)
	part("Foot" .. s, V(0.4, 0.12, 0.72), foot * C(0, 0.06, -0.26), SKIN)
	-- Instep: default wedge, high at the ankle, sloping down to the toes.
	wedge("Instep" .. s, V(0.36, 0.16, 0.5), foot * C(0, 0.2, -0.2), SKIN)
	for _, k in { -1, 1 } do
		cyl(
			"Toe" .. s .. (k == side and "Out" or "In"),
			V(0.34, 0.13, 0.13),
			foot * C(k * 0.1, 0.065, -0.72) * A(0, k * rad(-8), 0) * CYLINDER_Z,
			SKIN_GRIME
		)
	end
end

-- Gear ----------------------------------------------------------------------------------------
cyl("Belt", V(0.14, 0.92, 0.92), TF * C(0, 0.16, -0.02) * CYLINDER_Y, LEATHER)
part("LoinFront", V(0.5, 0.62, 0.05), C(0, 1.62, -0.29) * A(rad(10), 0, 0), CLOTH)
part("LoinBack", V(0.62, 0.66, 0.05), C(0, 1.62, 0.57) * A(rad(-12), 0, 0), CLOTH_DIRTY)
part("Pouch", V(0.16, 0.26, 0.24), C(0.6, 1.86, 0.2) * A(0, 0, rad(-8)), LEATHER_WORN)
part("Pauldron", V(0.42, 0.08, 0.46), C(SHOULDER[-1] + V(-0.04, 0.2, 0)) * A(0, 0, rad(30)), RUST)
-- Shoulder strap across the chest, right hip to left shoulder.
part(
	"Strap",
	V(0.12, 1.25, 0.05),
	alongY((TF * C(0.38, 0.3, -0.42)).Position, (TF * C(-0.5, 1.4, -0.3)).Position) * C(0, 0, -0.04),
	LEATHER_WORN
)

return {
	name = "Goblin",
	rootSize = V(1.6, 1.6, 0.8),
	hipHeight = 1.6,
	reach = 3.6, -- blade tip 3 studs ahead of the root center
	pieces = pieces,
}
