-- Aurora: a sleek high-tech walker. A glossy white capsule body with a smoked bubble canopy, cyan
-- light seams, a floating halo ring behind it, swept fins and twin thrusters; slender legs on
-- pointed feet, and floating shoulder pods over a blaster arm and a light-shield arm.
-- Scale: 4 studs = 1 m. Rest pose = parked pose (knees bent). Hip pivots y 22.5, capsule axis
-- y 31 (radius 6, z -10..12), cab cavity x -3.5..3.5, y 27..35, z -4..3.5 (only `In*` pieces
-- inside it). The pilot sees out through the capsule (Roblox draws no back faces).
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
local WHITE = { rgb(236, 239, 243), M.SmoothPlastic, 0.25 }
local GRAPHITE = { rgb(34, 37, 44), M.SmoothPlastic, 0.15 }
local LIGHT = { rgb(0, 222, 255), M.Neon }
local SHIELD = { rgb(80, 220, 255), M.Neon, 0, 0.55 }
local CANOPY = { rgb(40, 70, 100), M.Glass, 0.3, 0.55 }
local SEAT = { rgb(236, 239, 243), M.SmoothPlastic }
local HOLO = { rgb(0, 222, 255), M.Neon, 0, 0.4 }

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
local HIP_Y, HIP_Z, HIP_X = 22.5, 0, 6.2
local THIGH, SHIN = 11, 11
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

	-- Thigh: a ball hip, a white tube in a graphite sleeve, a light ring above the knee.
	ball(thigh, "Hip" .. s, 3.8, thighF.Position, WHITE)
	cyl(thigh, "Thigh" .. s, V(8, 3.2, 3.2), thighF * C(0, -5.4, 0) * CYLINDER_Y, WHITE)
	cyl(thigh, "ThighSleeve" .. s, V(2.6, 3.5, 3.5), thighF * C(0, -2.6, 0) * CYLINDER_Y, GRAPHITE)
	cyl(thigh, "ThighLight" .. s, V(0.25, 3.4, 3.4), thighF * C(0, -8.8, 0) * CYLINDER_Y, LIGHT)

	-- Shin: a graphite knee ball, a white tube with a front blade carrying a light strip.
	ball(shin, "Knee" .. s, 3, knee, GRAPHITE)
	cyl(shin, "Shin" .. s, V(8.4, 2.8, 2.8), shinF * C(0, -5.4, 0) * CYLINDER_Y, WHITE)
	part(shin, "ShinBlade" .. s, V(1.8, 8, 0.6), shinF * C(0, -5, -1.5), GRAPHITE)
	part(shin, "ShinLight" .. s, V(0.3, 6, 0.1), shinF * C(0, -5, -1.85), LIGHT)
	cyl(shin, "AnkleSleeve" .. s, V(1.4, 2.6, 2.6), shinF * C(0, -9.8, 0) * CYLINDER_Y, GRAPHITE)

	-- Foot: a pointed white shoe with a light line along its nose, on a graphite sole.
	ball(foot, "Ankle" .. s, 2.4, ankle, GRAPHITE)
	part(foot, "Sole" .. s, V(4.4, 0.4, 10), C(x, 0.2, -1.6), GRAPHITE)
	part(foot, "Shoe" .. s, V(4, 1.6, 5.6), C(x, 1.2, -0.6), WHITE)
	wedge(foot, "Nose" .. s, V(4, 1.6, 3.2), C(x, 1.2, -5), WHITE)
	part(foot, "NoseLight" .. s, V(4.05, 0.2, 2.6), C(x, 0.5, -5) * A(rad(-26), 0, 0), LIGHT)
	ball(foot, "Heel" .. s, 2.2, V(x, 1.1, 2.4), GRAPHITE)
end

-- Pelvis --------------------------------------------------------------------------------------
cyl("pelvis", "HipAxle", V(10, 2.6, 2.6), C(0, HIP_Y, HIP_Z), GRAPHITE)
ball("pelvis", "PelvisBall", 6, V(0, 23.2, 0.2), WHITE)
cyl("pelvis", "PelvisLight", V(0.3, 6.1, 6.1), C(0, 23.2, 0.2) * CYLINDER_Y, LIGHT)

-- Capsule -------------------------------------------------------------------------------------
local T = "torso"
local AXIS_Y, RADIUS = 31, 6
cyl(T, "Capsule", V(10, RADIUS * 2, RADIUS * 2), C(0, AXIS_Y, 1) * CYLINDER_Z, WHITE)
ball(T, "Nose", RADIUS * 2, V(0, AXIS_Y, -4), WHITE)
ball(T, "Tail", RADIUS * 2, V(0, AXIS_Y, 6), WHITE)
ball(T, "Canopy", 9.6, V(0, 32.4, -6.6), CANOPY)
ball(T, "ChinSensor", 2, V(0, 26.2, -7.4), GRAPHITE)
-- Light seams: a ring around the waist of the capsule and lines along its top and flanks.
for k = 0, 23 do
	local around = C(0, AXIS_Y, 3.5) * A(0, 0, k * math.pi / 12)
	part(T, "Seam", V(1.6, 0.15, 0.3), around * C(0, RADIUS + 0.02, 0), LIGHT)
end
part(T, "SeamTop", V(0.4, 0.12, 10), C(0, AXIS_Y + RADIUS + 0.02, 1), LIGHT)
for side = -1, 1, 2 do
	part(T, "SeamFlank", V(0.12, 0.4, 10), C(side * (RADIUS + 0.02), AXIS_Y, 1), LIGHT)
	part(
		T,
		"CanopyTrim",
		V(0.3, 3, 0.3),
		C(side * 4.2, 32.4, -8.6) * A(0, 0, rad(side * 20)),
		LIGHT
	)
end

-- Swept fins and twin thrusters.
for side = -1, 1, 2 do
	wedge(T, "Fin", V(0.5, 3.6, 6.4), C(side * 2.6, 37.9, 5.6) * A(0, 0, rad(-side * 12)), GRAPHITE)
	part(
		T,
		"FinLight",
		V(0.55, 0.2, 4),
		C(side * 2.75, 37.1, 6.2) * A(0, 0, rad(-side * 12)),
		LIGHT
	)
	cyl(T, "Thruster", V(3, 2.6, 2.6), C(side * 3.4, 27, 10.3) * CYLINDER_Z, GRAPHITE)
	cyl(T, "ThrusterLip", V(0.4, 2.9, 2.9), C(side * 3.4, 27, 11.7) * CYLINDER_Z, WHITE)
	ball(T, "ThrusterGlow", 2, V(side * 3.4, 27, 11.6), LIGHT)
end

-- Halo: a ring of light floating behind the capsule, with four emitters.
local HALO = C(0, 33, 9.5)
for k = 0, 19 do
	local around = HALO * A(0, 0, k * math.pi / 10)
	part(T, "Halo", V(2.45, 0.5, 0.5), around * C(0, 7.6, 0), LIGHT)
end
for k = 0, 3 do
	local around = HALO * A(0, 0, math.pi / 4 + k * math.pi / 2)
	ball(T, "HaloEmitter", 1.2, (around * C(0, 7.6, 0)).Position, GRAPHITE)
end

-- Cab interior --------------------------------------------------------------------------------
-- Seat block (invisible) at (0, 28.6, 1.3); the pilot's eye is near (0, 32.5, 1.5).
local IN = "torso"
part(IN, "InFloor", V(6.6, 0.3, 7), C(0, 27.15, -0.25), GRAPHITE)
part(IN, "InSeatPan", V(2.6, 0.5, 2.6), C(0, 27.85, 1.3), GRAPHITE)
part(IN, "InSeat", V(2.6, 0.5, 2.4), C(0, 28.35, 1.3), SEAT)
part(IN, "InSeatBack", V(2.6, 4, 0.5), C(0, 30.6, 2.6) * A(rad(12), 0, 0), SEAT)
part(IN, "InHolo", V(4, 1.6, 0.1), C(0, 31.3, -3.2) * A(rad(-15), 0, 0), HOLO)
for side = -1, 1, 2 do
	part(IN, "InArmrest", V(0.5, 0.4, 2.4), C(side * 1.6, 29.4, 1.1), GRAPHITE)
	ball(IN, "InTouchpad", 0.8, V(side * 1.6, 29.7, 0.1), LIGHT)
end

-- Arms (decorative) ---------------------------------------------------------------------------
-- Shoulder pods float clear of the capsule; the forearms hang below them, clear of the legs.
for side = -1, 1, 2 do
	local s = side < 0 and "_L" or "_R"
	local upper, fore = "upperArm" .. s, "foreArm" .. s
	ball(upper, "ShoulderPod" .. s, 4, V(side * 9.6, 33, 0.5), WHITE)
	cyl(upper, "ShoulderLight" .. s, V(0.3, 4.1, 4.1), C(side * 9.6, 33, 0.5), LIGHT)
	cyl(upper, "UpperArm" .. s, V(5.5, 1.8, 1.8), C(side * 9.8, 29, 0.5) * CYLINDER_Y, GRAPHITE)

	ball(fore, "Elbow" .. s, 2.2, V(side * 10, 25.5, 0.5), GRAPHITE)
	cyl(fore, "Gauntlet" .. s, V(7, 3.2, 3.2), C(side * 10.2, 21.8, 0.2) * CYLINDER_Y, WHITE)
	cyl(fore, "GauntletLight" .. s, V(0.3, 3.3, 3.3), C(side * 10.2, 18.6, 0.2) * CYLINDER_Y, LIGHT)
end
-- Right forearm: a blaster under the gauntlet. Left: a disc of light as a shield.
cyl("foreArm_R", "Blaster", V(5.4, 1.6, 1.6), C(10.2, 18, -1.8) * CYLINDER_Z, GRAPHITE)
cyl("foreArm_R", "BlasterMuzzle", V(0.3, 1.2, 1.2), C(10.2, 18, -4.55) * CYLINDER_Z, LIGHT)
cyl("foreArm_L", "ShieldHub", V(0.6, 2, 2), C(-11.9, 21.6, 0.2), GRAPHITE)
cyl("foreArm_L", "Shield", V(0.2, 7.4, 7.4), C(-12.3, 21.6, 0.2), SHIELD)

local bones = {
	{ name = "pelvis", pivot = V(0, HIP_Y, HIP_Z) },
	{ name = "torso", parent = "pelvis", pivot = V(0, 24.5, 0.5) },
	{ name = "upperArm_L", parent = "torso", pivot = V(-9.5, 33, 0.5) },
	{ name = "foreArm_L", parent = "upperArm_L", pivot = V(-10, 25.5, 0.5) },
	{ name = "upperArm_R", parent = "torso", pivot = V(9.5, 33, 0.5) },
	{ name = "foreArm_R", parent = "upperArm_R", pivot = V(10, 25.5, 0.5) },
}
for _, bone in legBones do
	table.insert(bones, bone)
end

local CAB_LO, CAB_HI = V(-3.5, 27, -4), V(3.5, 35, 3.5)
local collision = shell(V(-6, 25, -10), V(6, 37, 12), CAB_LO, CAB_HI)
table.insert(collision, { size = V(10, 3, 5), offset = C(0, 23, 0) }) -- pelvis y 21.5..24.5

return {
	name = "Aurora",
	speed = 30,
	turnRate = 1.1,
	footprint = Vector2.new(18, 18),
	collision = collision,
	bones = bones,
	seatBone = "torso",
	cab = { center = (CAB_LO + CAB_HI) / 2, size = CAB_HI - CAB_LO },
	exit = C(0, 3, 15) * A(0, math.pi, 0), -- on the ground behind, facing away
	cameraFocus = V(0, 38, 0),
	cockpitCamera = true,
	gait = "mech",
	acceleration = 10,
	braking = 28,
	coasting = 18,
	turnAcceleration = 3,
	turnInPlace = true,
	parkingBrake = true,
	uprightTorque = 4,
	stepsOver = true,
	seats = { C(0, 28.6, 1.3) },
	pieces = pieces,
}
