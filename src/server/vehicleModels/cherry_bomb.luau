-- Cherry Bomb: a red ball of a walker on short stubby legs, with a bubble window, ball fists and
-- round pad feet. It came from an ancient alien civilization: the shell is veined like stone, a
-- band of gold glyphs circles its back half above a gold seal, and the cab holds a smooth obsidian
-- console of pearl knobs, glowing rings, glyph labels and a holo pane, two orb controls on padded
-- armrests, and a rounded, padded seat. Scale: 4 studs = 1 m. Rest pose = parked pose (knees bent). Hip pivots y 13.5,
-- body sphere center y 24 (radius 10), cab cavity x -3.5..3.5, y 21..29, z -3.5..4 (only `In*`
-- pieces inside it). The pilot sits inside the sphere and sees out through it (Roblox draws no
-- back faces), so nothing opaque crosses the cab's view forward.
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

-- Palette: { color, material, reflectance, transparency }.
local RED = { rgb(205, 24, 36), M.SmoothPlastic, 0.18 }
local SHELL = { rgb(205, 24, 36), M.Marble, 0.12 } -- the body: red with faint stone veins
local DEEP_RED = { rgb(140, 14, 24), M.SmoothPlastic, 0.1 }
local WHITE = { rgb(245, 240, 232), M.SmoothPlastic, 0.1 }
local JOINT = { rgb(40, 38, 42), M.Metal }
local RUBBER = { rgb(28, 26, 28), M.Rubber }
local GLASS = { rgb(170, 215, 235), M.Glass, 0.2, 0.65 }
local LAMP = { rgb(255, 236, 170), M.Neon }
local GLOW = { rgb(255, 150, 40), M.Neon }
local SEAT = { rgb(245, 240, 232), M.Fabric }
local GOLD = { rgb(200, 165, 90), M.Metal, 0.2 } -- tarnished glyph inlay
local RUNE = { rgb(90, 255, 220), M.Neon }
local HOLO = { rgb(90, 255, 220), M.Neon, 0, 0.6 }
local ORB = { rgb(90, 255, 220), M.Neon, 0, 0.15 }
local OBSIDIAN = { rgb(22, 20, 30), M.SmoothPlastic, 0.35 }
local PEARL = { rgb(235, 232, 245), M.SmoothPlastic, 0.3 }

local pieces = {}

local function part(bone, name, size, offset, style, shape)
	table.insert(pieces, {
		name = name,
		bone = bone,
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

-- Glyphs: an alien alphabet in a unit cell (x and y in -0.5..0.5). A stroke is a bar from
-- (x1, y1) to (x2, y2) or a round dot { x, y, diameter }.
local GLYPHS = {
	{ { -0.3, -0.5, -0.3, 0.5 }, { -0.3, -0.5, 0.4, -0.5 }, { 0.25, 0.3, 0.35 } },
	{ { -0.45, 0.45, 0, -0.45 }, { 0, -0.45, 0.45, 0.45 }, { 0, 0.25, 0.3 } },
	{ { -0.45, 0.45, 0.45, 0.45 }, { 0, 0.45, 0, -0.15 }, { 0, -0.4, 0.3 } },
	{ { 0, 0, 0.7 }, { -0.5, -0.5, 0.5, 0.5 } },
	{ { -0.35, -0.5, -0.35, 0.2 }, { 0.05, -0.5, 0.05, 0.5 }, { 0.4, -0.5, 0.4, 0 } },
	{ { -0.45, 0.4, 0.45, 0.4 }, { 0.45, 0.4, 0.45, -0.45 }, { -0.2, -0.2, 0.35 } },
	{ { -0.45, -0.2, 0.45, -0.2 }, { -0.25, 0.45, 0.3 }, { 0.25, 0.45, 0.3 } },
}

-- Draws glyph `index` in `frame`'s XY plane (+Y up as read, +X right), `cell` studs across,
-- with strokes `width` wide and `depth` thick along the frame's Z.
local function glyph(bone, name, frame, index, cell, width, depth, style)
	for _, stroke in GLYPHS[(index - 1) % #GLYPHS + 1] do
		if #stroke == 3 then
			local at = frame * C(stroke[1] * cell, stroke[2] * cell, 0)
			local d = stroke[3] * cell
			cyl(bone, name, V(depth, d, d), at * CYLINDER_Z, style)
		else
			local x1, y1 = stroke[1] * cell, stroke[2] * cell
			local x2, y2 = stroke[3] * cell, stroke[4] * cell
			local length = math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2) + width
			local at = frame
				* C((x1 + x2) / 2, (y1 + y2) / 2, 0)
				* A(0, 0, math.atan2(y2 - y1, x2 - x1))
			part(bone, name, V(length, width, depth), at, style)
		end
	end
end

-- Legs ----------------------------------------------------------------------------------------
local BEND = rad(25)
local HIP_Y, HIP_Z, HIP_X = 13.5, 0, 4.8
local THIGH, SHIN = 6, 6
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

	-- Thigh: a ball hip and a stubby red drum with a white band.
	ball(thigh, "Hip" .. s, 3.8, thighF.Position, JOINT)
	cyl(thigh, "Thigh" .. s, V(4.2, 3.4, 3.4), thighF * C(0, -3, 0) * CYLINDER_Y, RED)
	cyl(thigh, "ThighBand" .. s, V(0.7, 3.7, 3.7), thighF * C(0, -3, 0) * CYLINDER_Y, WHITE)

	-- Shin: ball knee under a round red cap, a drum, a white ankle cuff.
	ball(shin, "Knee" .. s, 3.4, knee, JOINT)
	ball(shin, "KneeCap" .. s, 2.6, (C(knee) * C(0, 0.3, -1.3)).Position, RED)
	cyl(shin, "Shin" .. s, V(4.2, 3.6, 3.6), shinF * C(0, -3, 0) * CYLINDER_Y, RED)
	cyl(shin, "AnkleCuff" .. s, V(0.8, 3.9, 3.9), shinF * C(0, -5, 0) * CYLINDER_Y, WHITE)

	-- Foot: a round rubber pad under a red dome, three ball toes and a heel ball.
	ball(foot, "Ankle" .. s, 2.8, ankle, JOINT)
	cyl(foot, "Pad" .. s, V(1.2, 7.4, 7.4), C(x, 0.6, -0.4) * CYLINDER_Y, RUBBER)
	cyl(foot, "PadShell" .. s, V(1, 6.6, 6.6), C(x, 1.7, -0.4) * CYLINDER_Y, RED)
	ball(foot, "Dome" .. s, 4.4, V(x, 2.2, -0.2), RED)
	for k = -1, 1 do
		ball(foot, "Toe" .. s, 2.2, V(x + k * 1.9, 1.1, -3.7 + math.abs(k) * 0.5), WHITE)
	end
	ball(foot, "Heel" .. s, 2, V(x, 1, 3.2), WHITE)
end

-- Pelvis --------------------------------------------------------------------------------------
cyl("pelvis", "HipAxle", V(10, 3, 3), C(0, HIP_Y, HIP_Z), JOINT)
ball("pelvis", "PelvisBall", 7, V(0, 14, 0), JOINT)

-- Body ----------------------------------------------------------------------------------------
-- One big sphere with a white belt of segments (a solid disc would floor the pilot's view).
local T = "torso"
local BODY = V(0, 24, 0)
local R = 10
ball(T, "Body", R * 2, BODY, SHELL)
for k = 0, 23 do
	local around = C(BODY) * A(0, k * math.pi / 12, 0)
	part(T, "Belt", V(2.75, 1.4, 0.5), around * C(0, 0, -R + 0.1), WHITE)
	if k % 2 == 0 then
		ball(T, "BeltStud", 0.7, (around * C(0, 0, -R - 0.25)).Position, JOINT)
	end
end

-- A point on the sphere's front surface at (x, y), pushed out by `out`.
local function onFront(x, y, out)
	local dy = y - BODY.Y
	return V(x, y, -math.sqrt(R * R - x * x - dy * dy) - out)
end

-- A frame on the sphere's surface, `out` beyond it: +Z points out, +Y up, +X right as seen from
-- outside. `azimuth` turns from the front (-Z) toward the right (+X); `elevation` rises from the
-- belt. Degrees.
local function onSphere(azimuth, elevation, out)
	local az, el = rad(azimuth), rad(elevation)
	local direction = V(math.sin(az) * math.cos(el), math.sin(el), -math.cos(az) * math.cos(el))
	return CFrame.lookAt(BODY + direction * (R + out), BODY)
end

-- A band of gold glyphs around the back half, clear of the pilot's forward view and the ports.
for k = 0, 14 do
	glyph(T, "Glyph", onSphere(85 + k * 13.5, 38, 0.02), k * 3 + 1, 1.5, 0.22, 0.15, GOLD)
end

-- The seal on the back, between the exhausts: a gold ring, rays round a glowing core, and a
-- crown of dots.
local SEAL = onSphere(180, 16, 0)
cyl(T, "SealRing", V(0.15, 3.6, 3.6), SEAL * CYLINDER_Z, GOLD)
cyl(T, "SealFace", V(0.2, 3, 3), SEAL * CYLINDER_Z, SHELL)
cyl(T, "SealCore", V(0.3, 0.8, 0.8), SEAL * CYLINDER_Z, RUNE)
for k = 0, 5 do
	local turn = SEAL * A(0, 0, k * math.pi / 3)
	part(T, "SealRay", V(0.7, 0.18, 0.25), turn * C(0.95, 0, 0), GOLD)
	cyl(T, "SealDot", V(0.15, 0.35, 0.35), turn * C(0, 2.15, 0) * CYLINDER_Z, GOLD)
end

-- Bubble window, ringed with bolts.
local WINDOW_Y = 26.5
ball(T, "Window", 9, V(0, WINDOW_Y, -6.6), GLASS)
for k = 0, 11 do
	local a = k * math.pi / 6
	local bx, by = math.cos(a) * 4.9, WINDOW_Y + math.sin(a) * 4.9
	ball(T, "WindowBolt", 0.9, onFront(bx, by, 0.1), JOINT)
end
-- Cheek lamps and a grille smile.
for side = -1, 1, 2 do
	ball(T, "CheekLamp", 1.8, onFront(side * 5.5, 21.5, 0.2), LAMP)
	ball(T, "CheekRim", 2.3, onFront(side * 5.5, 21.5, -0.4), WHITE)
end
for k = -2, 2 do
	part(
		T,
		"Grille",
		V(0.6, 1.4, 0.6),
		C(onFront(k * 1.1, 19.6 + math.abs(k) * 0.25, -0.15)),
		JOINT
	)
end

-- Side ports and back exhausts.
for side = -1, 1, 2 do
	cyl(T, "PortRim", V(0.5, 4.6, 4.6), C(side * 9.55, 27, 2.5), WHITE)
	cyl(T, "Port", V(0.6, 3.6, 3.6), C(side * 9.65, 27, 2.5), JOINT)
	cyl(T, "PortCore", V(0.65, 1.4, 1.4), C(side * 9.7, 27, 2.5), GLOW)
	cyl(T, "Exhaust", V(2.4, 2.8, 2.8), C(side * 3, 21.5, 9.2) * CYLINDER_Z, JOINT)
	ball(T, "ExhaustGlow", 1.6, V(side * 3, 21.5, 10.2), GLOW)
end

-- Crown: a hatch dome, a white collar and a bent antenna with a ball tip (its own bone; it wobbles
-- as Cherry Bomb walks).
ball(T, "Hatch", 6, V(0, 33.2, 1.5), DEEP_RED)
cyl(T, "HatchCollar", V(0.6, 6.4, 6.4), C(0, 33.6, 1.5) * CYLINDER_Y, WHITE)
ball(T, "HatchKnob", 1.2, V(0, 36.3, 1.5), WHITE)
cyl(T, "AntennaBase", V(0.8, 1.6, 1.6), C(4, 32.7, 4) * CYLINDER_Y, JOINT)
cyl(
	"antenna",
	"Antenna",
	V(6, 0.3, 0.3),
	C(4.6, 36, 4.6) * A(rad(-12), 0, rad(-10)) * CYLINDER_Y,
	JOINT
)
ball("antenna", "AntennaTip", 1, V(5.1, 38.9, 5.2), GLOW)

-- Cab interior --------------------------------------------------------------------------------
-- Seat block (invisible) at (0, 23, 1.2); the pilot's eye is near (0, 26.8, 1.4).
local IN = "torso"
cyl(IN, "InFloor", V(0.4, 7, 7), C(0, 21.2, 0.2) * CYLINDER_Y, OBSIDIAN)
cyl(IN, "InFloorRing", V(0.42, 5.4, 5.4), C(0, 21.2, 0.2) * CYLINDER_Y, GOLD)
cyl(IN, "InFloorInset", V(0.44, 5, 5), C(0, 21.2, 0.2) * CYLINDER_Y, OBSIDIAN)

-- Seat: a round padded cushion with a rolled front edge, a reclined back with side bolsters and
-- a pillow headrest.
cyl(IN, "InSeatPost", V(1.6, 1.2, 1.2), C(0, 21.8, 1.2) * CYLINDER_Y, OBSIDIAN)
cyl(IN, "InSeatCushion", V(0.7, 3, 3), C(0, 22.65, 1.2) * CYLINDER_Y, SEAT)
cyl(IN, "InSeatRoll", V(2.8, 0.7, 0.7), C(0, 22.8, -0.2), SEAT)
local back = C(0, 24.7, 2.5) * A(rad(10), 0, 0)
part(IN, "InSeatBack", V(2.4, 3.4, 0.6), back, SEAT)
for side = -1, 1, 2 do
	cyl(IN, "InSeatBolster", V(3.4, 0.7, 0.7), back * C(side * 1.3, 0, -0.1) * CYLINDER_Y, SEAT)
	ball(IN, "InBolsterCap", 0.7, (back * C(side * 1.3, 1.7, -0.1)).Position, SEAT)
end
cyl(IN, "InHeadrest", V(1.8, 0.9, 0.9), back * C(0, 1.95, -0.15), SEAT)

-- Armrests: padded rolls on obsidian posts, each ending in a glowing control orb in a gold
-- cradle.
for side = -1, 1, 2 do
	local x = side * 2.25
	cyl(IN, "InArmPost", V(2.2, 0.5, 0.5), C(x, 22.3, 1.2) * CYLINDER_Y, OBSIDIAN)
	cyl(IN, "InArmrest", V(2.6, 0.7, 0.7), C(x, 23.4, 0.9) * CYLINDER_Z, SEAT)
	cyl(IN, "InOrbCradle", V(0.08, 0.8, 0.8), C(x, 23.78, -0.4) * CYLINDER_Y, GOLD)
	ball(IN, "InOrb", 0.6, V(x, 24.05, -0.4), ORB)
	glyph(IN, "InLabel", C(x, 23.76, 0.6) * A(rad(-90), 0, 0), side + 5, 0.3, 0.05, 0.04, RUNE)
end

-- Console: an obsidian pill under a sloped face that looks back at the pilot. Five pearl knobs
-- on glowing rings (the middle one a glowing emitter), a glyph label under each, and a holo pane
-- of glowing readouts above.
cyl(IN, "InConsole", V(4.8, 1.1, 1.1), C(0, 24, -2.7), OBSIDIAN)
for side = -1, 1, 2 do
	ball(IN, "InConsoleEnd", 1.1, V(side * 2.4, 24, -2.7), OBSIDIAN)
end
local face = C(0, 24.5, -2.6) * A(rad(30), 0, 0)
part(IN, "InConsoleFace", V(4.8, 0.1, 1.3), face, OBSIDIAN)
for k = -2, 2 do
	local x = k * 0.9
	cyl(IN, "InKnobRing", V(0.04, 0.6, 0.6), face * C(x, 0.06, -0.15) * CYLINDER_Y, RUNE)
	ball(IN, "InKnob", 0.4, (face * C(x, 0.12, -0.15)).Position, if k == 0 then RUNE else PEARL)
	glyph(IN, "InLabel", face * C(x, 0.06, 0.35) * A(rad(-90), 0, 0), k + 3, 0.3, 0.05, 0.04, RUNE)
end
local pane = C(0, 25.2, -2.9) * A(rad(-12), 0, 0)
part(IN, "InHolo", V(2.2, 1, 0.05), pane, HOLO)
for row, width in { 1.4, 0.9, 1.2 } do
	part(
		IN,
		"InReadout",
		V(width, 0.06, 0.02),
		pane * C((width - 1.4) / 2, 0.55 - row * 0.27, 0.04),
		RUNE
	)
end

-- Arms (decorative) ---------------------------------------------------------------------------
-- Ball shoulders on the sphere's flanks, a ball upper arm, and a ball fist with three knuckles.
for side = -1, 1, 2 do
	local s = side < 0 and "_L" or "_R"
	local upper, fore = "upperArm" .. s, "foreArm" .. s
	ball(upper, "Shoulder" .. s, 4.2, V(side * 10.9, 25, 0), JOINT)
	ball(upper, "UpperArm" .. s, 3.6, V(side * 11.6, 22.2, 0), RED)
	ball(fore, "Elbow" .. s, 2.6, V(side * 11.8, 20, 0), JOINT)
	ball(fore, "Fist" .. s, 4.8, V(side * 12.2, 16.8, -0.3), RED)
	cyl(fore, "Wristband" .. s, V(0.7, 4.4, 4.4), C(side * 12.1, 18.6, -0.2) * CYLINDER_Y, WHITE)
	for k = -1, 1 do
		ball(fore, "Knuckle" .. s, 1.4, V(side * 12.2 + k * 1.15, 16, -2.4), WHITE)
	end
end

local bones = {
	{ name = "pelvis", pivot = V(0, HIP_Y, HIP_Z) },
	{ name = "torso", parent = "pelvis", pivot = V(0, 15, 0) },
	{ name = "upperArm_L", parent = "torso", pivot = V(-10.8, 25, 0) },
	{ name = "foreArm_L", parent = "upperArm_L", pivot = V(-11.8, 20, 0) },
	{ name = "upperArm_R", parent = "torso", pivot = V(10.8, 25, 0) },
	{ name = "foreArm_R", parent = "upperArm_R", pivot = V(11.8, 20, 0) },
	{ name = "antenna", parent = "torso", pivot = V(4, 33.1, 4), wobble = true },
}
for _, bone in legBones do
	table.insert(bones, bone)
end

local CAB_LO, CAB_HI = V(-3.5, 21, -3.5), V(3.5, 29, 4)
local collision = shell(V(-9, 15, -8.5), V(9, 33, 8.5), CAB_LO, CAB_HI)
table.insert(collision, { size = V(10, 3, 6), offset = C(0, 13.5, 0) }) -- pelvis y 12..15

return {
	name = "Cherry Bomb",
	speed = 16,
	turnRate = 1,
	footprint = Vector2.new(20, 18),
	collision = collision,
	bones = bones,
	seatBone = "torso",
	cab = { center = (CAB_LO + CAB_HI) / 2, size = CAB_HI - CAB_LO },
	exit = C(0, 3, 13) * A(0, math.pi, 0), -- on the ground behind, facing away
	cameraFocus = V(0, 30, 0),
	cockpitCamera = true,
	gait = "mech",
	acceleration = 6,
	braking = 24,
	coasting = 16,
	turnAcceleration = 2.5,
	turnInPlace = true,
	parkingBrake = true,
	uprightTorque = 3,
	stepsOver = true,
	seats = { C(0, 23, 1.2) },
	pieces = pieces,
}
