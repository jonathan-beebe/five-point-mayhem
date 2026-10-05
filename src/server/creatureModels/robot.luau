-- Robo-Guard: 1.85 m military security android. Olive-grey armor shells bolted over a dark steel
-- chassis, with rotary actuators, piston rods and cable runs exposed at every joint; a backpack
-- power unit with heat-sink fins; black wrap visor with a cyan sensor bar.
-- Scale: 4 studs = 1 m, 7.4 tall (antenna tip 7.73). Pose: combat advance, left foot forward,
-- knees bent, torso pitched 7 degrees forward, left hand reaching open, right fist holding a stun
-- baton level. Landmarks: hip actuators y 3.6, waist actuator y 4.35 (torso pivot), shoulders
-- y 5.94 at x +-1.32, visor y 7.0, crown 7.39. Root spans y 2.8..5.6 (pelvis to lower chest).
--
-- Pieces are authored in joint frames (pelvis, torso, neck, shoulder, upper arm, forearm, hand,
-- thigh, shin, foot) so each limb is one loop over `{ -1, 1 }` sides.

local rgb = Color3.fromRGB
local M = Enum.Material
local A = CFrame.Angles
local C = CFrame.new
local V = Vector3.new
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball
local rad = math.rad
local CYLINDER_Y = A(0, 0, rad(90)) -- cylinder axis along Y

-- Degrees version of CFrame.Angles.
local function deg(x, y, z)
	return A(rad(x), rad(y), rad(z))
end

-- Palette: { color, material, reflectance, transparency }.
local ARMOR = { rgb(88, 94, 86), M.Metal, 0.04 }
local ARMOR_ALT = { rgb(80, 85, 79), M.Metal, 0.03 }
local ARMOR_FADED = { rgb(104, 108, 100), M.Metal, 0.04 }
local ARMOR_GRIME = { rgb(74, 74, 64), M.Metal, 0.02 }
local WORN_EDGE = { rgb(142, 144, 140), M.Metal, 0.15 }
local FRAME = { rgb(50, 52, 56), M.Metal, 0.06 }
local JOINT = { rgb(34, 35, 38), M.Metal, 0.1 }
local CHROME = { rgb(176, 180, 184), M.Metal, 0.35 }
local RUBBER = { rgb(26, 26, 28), M.Rubber }
local HEATSINK = { rgb(72, 66, 58), M.CorrodedMetal }
local DECK = { rgb(58, 60, 62), M.DiamondPlate, 0.02 }
local HAZARD = { rgb(178, 142, 44), M.Metal, 0.05 }
local VISOR = { rgb(12, 16, 20), M.Glass, 0.3, 0.1 }
local SENSOR = { rgb(60, 220, 255), M.Neon }
local STATUS = { rgb(255, 70, 40), M.Neon }
local ARC = { rgb(150, 235, 255), M.Neon, 0, 0.2 }

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

-- Cylinder along the frame's X axis.
local function cyl(name, length, diameter, offset, style)
	part(name, V(length, diameter, diameter), offset, style, CYL)
end

-- Cylinder along the frame's Y axis.
local function cylY(name, length, diameter, offset, style)
	cyl(name, length, diameter, offset * CYLINDER_Y, style)
end

local function ball(name, diameter, offset, style)
	part(name, V(diameter, diameter, diameter), offset, style, BALL)
end

-- Frame at `from` whose -Y axis points at `to`, pitched in the YZ plane.
local function segment(from: Vector3, to: Vector3): CFrame
	local d = to - from
	return C(from) * A(math.atan2(-d.Z, -d.Y), 0, 0)
end

-- Pelvis ---------------------------------------------------------------------------------------
local PELVIS = C(0, 3.85, 0.05)

part("PelvisCore", V(1.9, 0.6, 1.1), PELVIS, FRAME)
cylY("WaistActuator", 0.4, 1.25, PELVIS * C(0, 0.45, 0), JOINT)
part("BeltPlate", V(1.98, 0.22, 1.2), PELVIS * C(0, 0.22, 0), ARMOR_FADED)
part("Codpiece", V(0.72, 0.62, 0.2), PELVIS * C(0, -0.18, -0.6) * deg(10, 0, 0), ARMOR)
part("SeatPlate", V(1.5, 0.5, 0.2), PELVIS * C(0, -0.05, 0.62) * deg(-10, 0, 0), ARMOR_ALT)
for _, side in { -1, 1 } do
	local s = side < 0 and "L" or "R"
	part(
		"Tasset" .. s,
		V(0.18, 0.78, 0.9),
		PELVIS * C(side * 1.06, -0.18, 0) * deg(0, 0, side * 8),
		ARMOR_GRIME
	)
	cyl("HipActuator" .. s, 0.42, 0.66, PELVIS * C(side * 0.62, -0.25, 0), JOINT)
end

-- Legs -----------------------------------------------------------------------------------------
-- Knee position solved from hip, ankle and segment lengths; the knee bends forward (-Z).
local HIP_X, HIP_Y, HIP_Z = 0.6, 3.6, 0.05
local ANKLE_Y = 0.42
local THIGH, SHIN = 1.75, 1.68
local FOOT_X = 0.62
local STRIDE = { [-1] = -0.78, [1] = 0.82 } -- ankle z per side: left forward, right back

local function kneeFrom(hip: Vector3, ankle: Vector3): Vector3
	local dy, dz = ankle.Y - hip.Y, ankle.Z - hip.Z
	local span = math.sqrt(dy * dy + dz * dz)
	local spread = math.acos((THIGH * THIGH + span * span - SHIN * SHIN) / (2 * THIGH * span))
	local angle = math.atan2(dz, dy) + spread -- the forward (-Z) of the two solutions
	return V(hip.X, hip.Y + THIGH * math.cos(angle), hip.Z + THIGH * math.sin(angle))
end

for _, side in { -1, 1 } do
	local s = side < 0 and "L" or "R"
	local hip = V(side * HIP_X, HIP_Y, HIP_Z)
	local ankle = V(side * FOOT_X, ANKLE_Y, STRIDE[side])
	local knee = kneeFrom(hip, ankle)
	local thigh = segment(hip, knee)
	local shin = segment(knee, ankle)
	local foot = C(ankle.X, 0, ankle.Z)

	cylY("ThighCore" .. s, 1.45, 0.56, thigh * C(0, -0.85, 0), FRAME)
	part("QuadPlate" .. s, V(0.62, 1.15, 0.2), thigh * C(0, -0.78, -0.31), ARMOR)
	part("ThighSidePlate" .. s, V(0.16, 1.05, 0.62), thigh * C(side * 0.33, -0.72, 0), ARMOR_ALT)
	cylY("HamstringCylinder" .. s, 0.8, 0.22, thigh * C(-side * 0.08, -0.55, 0.3), JOINT)
	cylY("HamstringRod" .. s, 0.6, 0.11, thigh * C(-side * 0.08, -1.25, 0.3), CHROME)
	cyl("KneeActuator" .. s, 0.62, 0.5, thigh * C(0, -THIGH, 0), JOINT)
	part("Kneecap" .. s, V(0.42, 0.42, 0.16), thigh * C(0, -1.68, -0.3) * deg(-12, 0, 0), WORN_EDGE)

	cylY("ShinCore" .. s, 1.4, 0.42, shin * C(0, -0.85, 0), FRAME)
	part("ShinGuard" .. s, V(0.5, 0.95, 0.16), shin * C(0, -0.55, -0.26), ARMOR)
	part("ShinGuardLower" .. s, V(0.46, 0.5, 0.14), shin * C(0, -1.25, -0.24), ARMOR_GRIME)
	part("CalfMotor" .. s, V(0.4, 0.85, 0.36), shin * C(0, -0.55, 0.27), ARMOR_GRIME)
	cylY("CalfRod" .. s, 0.6, 0.12, shin * C(0, -1.25, 0.27), CHROME)
	cylY(
		"ShinCable" .. s,
		1.25,
		0.08,
		shin * C(side * 0.25, -0.8, 0.08) * deg(0, 0, side * 3),
		RUBBER
	)
	cyl("AnkleActuator" .. s, 0.52, 0.36, shin * C(0, -SHIN, 0), JOINT)

	part("Sole" .. s, V(0.64, 0.14, 1.32), foot * C(0, 0.07, -0.18), RUBBER)
	part("FootUpper" .. s, V(0.56, 0.26, 0.9), foot * C(0, 0.27, -0.1), ARMOR_GRIME)
	part("ToeCap" .. s, V(0.56, 0.22, 0.38), foot * C(0, 0.25, -0.73), WORN_EDGE, nil, "WedgePart")
	part("HeelBlock" .. s, V(0.5, 0.3, 0.3), foot * C(0, 0.29, 0.38), DECK)
end

-- Torso ----------------------------------------------------------------------------------------
-- Pitched forward 7 degrees about the waist actuator.
local TORSO = C(0, 4.35, 0.05) * deg(-7, 0, 0)

part("AbdomenCore", V(1.4, 1.05, 0.95), TORSO * C(0, 0.5, 0.05), FRAME)
for i, plate in { { 0.2, 1.05, ARMOR_ALT }, { 0.47, 1.15, ARMOR }, { 0.74, 1.25, ARMOR_ALT } } do
	part("AbPlate" .. i, V(plate[2], 0.24, 0.16), TORSO * C(0, plate[1], -0.5), plate[3])
end
part("ChestLower", V(2.05, 0.5, 1.3), TORSO * C(0, 1.16, 0), ARMOR_ALT)
part("ChestUpper", V(2.4, 0.66, 1.4), TORSO * C(0, 1.72, 0), ARMOR)
part("Sternum", V(0.6, 0.9, 0.12), TORSO * C(0, 1.38, -0.69), ARMOR_FADED)
part("SpineGuard", V(0.42, 0.95, 0.24), TORSO * C(0, 0.5, 0.58), ARMOR_ALT)
for _, side in { -1, 1 } do
	local s = side < 0 and "L" or "R"
	local pec = side < 0 and ARMOR_FADED or ARMOR
	part(
		"PecPlate" .. s,
		V(0.86, 0.46, 0.14),
		TORSO * C(side * 0.64, 1.8, -0.73) * deg(-8, 0, 0),
		pec
	)
	part(
		"RibFlank" .. s,
		V(0.3, 0.85, 1.15),
		TORSO * C(side * 1.04, 1.22, 0.02) * deg(0, 0, side * 14),
		ARMOR_GRIME
	)
	part(
		"Trapezius" .. s,
		V(0.66, 0.26, 0.98),
		TORSO * C(side * 0.78, 2.07, 0.05) * deg(0, 0, -side * 14),
		ARMOR_ALT
	)
	cylY(
		"NeckCable" .. s,
		0.45,
		0.07,
		TORSO * C(side * 0.21, 2.24, 0.2) * deg(0, 0, side * 8),
		RUBBER
	)
end
part("ChestIdPlate", V(0.34, 0.14, 0.04), TORSO * C(-0.64, 1.5, -0.68), HAZARD)
part("ChestStatusLight", V(0.14, 0.07, 0.04), TORSO * C(0.58, 1.5, -0.68), STATUS)
cylY("CollarRing", 0.16, 0.95, TORSO * C(0, 2.1, 0.02), JOINT)
cylY("NeckBoot", 0.32, 0.44, TORSO * C(0, 2.24, 0.02), RUBBER)

-- Power pack on the back, cabled into the waist.
part("PowerPack", V(1.6, 1.2, 0.55), TORSO * C(0, 1.45, 0.95), ARMOR_ALT)
part("PackTopPlate", V(1.66, 0.1, 0.6), TORSO * C(0, 2.1, 0.95), DECK)
for i, y in { 1.1, 1.28, 1.46, 1.64 } do
	part("PackFin" .. i, V(1.2, 0.07, 0.14), TORSO * C(0, y, 1.27), HEATSINK)
end
for _, side in { -1, 1 } do
	local s = side < 0 and "L" or "R"
	cylY("BatteryCell" .. s, 1.05, 0.34, TORSO * C(side * 0.62, 1.4, 1.32), HEATSINK)
	cylY("PackCable" .. s, 0.9, 0.09, TORSO * C(side * 0.35, 0.6, 0.62) * deg(14, 0, 0), RUBBER)
end

-- Head -----------------------------------------------------------------------------------------
-- Pitched back 5 degrees from the torso so the visor looks level.
local NECK = TORSO * C(0, 2.3, 0.02) * deg(5, 0, 0)

part("Head", V(0.64, 0.42, 0.68), NECK * C(0, 0.24, 0), ARMOR_FADED)
cyl("Crown", 0.66, 0.7, NECK * C(0, 0.4, 0.03), ARMOR)
part("CrownRidge", V(0.12, 0.06, 0.56), NECK * C(0, 0.74, 0.03), FRAME)
part("HeadRear", V(0.52, 0.38, 0.2), NECK * C(0, 0.3, 0.38), FRAME)
part("Visor", V(0.68, 0.2, 0.12), NECK * C(0, 0.38, -0.33), VISOR)
part("SensorBar", V(0.24, 0.04, 0.04), NECK * C(0, 0.39, -0.4), SENSOR)
for _, side in { -1, 1 } do
	local s = side < 0 and "L" or "R"
	part("VisorWrap" .. s, V(0.1, 0.18, 0.3), NECK * C(side * 0.33, 0.38, -0.2), VISOR)
	cyl("EarPod" .. s, 0.12, 0.3, NECK * C(side * 0.37, 0.3, 0.05), JOINT)
	ball("SensorLens" .. s, 0.09, NECK * C(side * 0.18, 0.39, -0.38), SENSOR)
end
part("Faceplate", V(0.48, 0.22, 0.12), NECK * C(0, 0.15, -0.33) * deg(-15, 0, 0), ARMOR)
for i, y in { 0.11, 0.18 } do
	part("ChinVent" .. i, V(0.3, 0.03, 0.04), NECK * C(0, y, -0.4) * deg(-15, 0, 0), FRAME)
end
cylY("Antenna", 0.36, 0.04, NECK * C(0.22, 0.86, 0.22), RUBBER)
ball("AntennaTip", 0.07, NECK * C(0.22, 1.05, 0.22), STATUS)

-- Arms -----------------------------------------------------------------------------------------
-- Angles in degrees. Left reaches forward with an open, hooked hand; right holds the baton level.
local UPPER_ARM, FOREARM = 1.3, 1.2
local ARM_POSE = {
	[-1] = { pitch = 38, abduct = 12, elbow = 52, wrist = -10, curl = 22 },
	[1] = { pitch = 18, abduct = 14, elbow = 74, wrist = 0, curl = -85 },
}

for _, side in { -1, 1 } do
	local s = side < 0 and "L" or "R"
	local pose = ARM_POSE[side]
	local shoulder = TORSO * C(side * 1.32, 1.6, 0.05)
	local upper = shoulder * deg(0, 0, side * pose.abduct) * deg(pose.pitch, 0, 0)
	local fore = upper * C(0, -UPPER_ARM, 0) * deg(pose.elbow, 0, 0)
	local hand = fore * C(0, -FOREARM, 0) * deg(pose.wrist, 0, 0)

	ball("ShoulderActuator" .. s, 0.64, shoulder, JOINT)
	part(
		"Pauldron" .. s,
		V(0.72, 0.28, 0.92),
		shoulder * C(side * 0.08, 0.3, 0) * deg(0, 0, -side * 16),
		ARMOR
	)
	local pauldronSide = shoulder * C(side * 0.42, 0.06, 0) * deg(0, 0, -side * 6)
	part("PauldronSide" .. s, V(0.14, 0.5, 0.84), pauldronSide, ARMOR_ALT)

	cylY("UpperArmCore" .. s, 1.1, 0.4, upper * C(0, -0.65, 0), FRAME)
	part("BicepPlate" .. s, V(0.5, 0.8, 0.18), upper * C(0, -0.62, -0.24), ARMOR)
	part("UpperArmSidePlate" .. s, V(0.14, 0.75, 0.46), upper * C(side * 0.25, -0.6, 0), ARMOR_ALT)
	cylY("TricepCylinder" .. s, 0.7, 0.17, upper * C(0, -0.5, 0.25), JOINT)
	cylY("TricepRod" .. s, 0.5, 0.09, upper * C(0, -1.05, 0.25), CHROME)
	cyl("ElbowActuator" .. s, 0.5, 0.42, upper * C(0, -UPPER_ARM, 0), JOINT)

	part("ElbowGuard" .. s, V(0.4, 0.28, 0.3), fore * C(0, 0.05, 0.2) * deg(20, 0, 0), WORN_EDGE)
	cylY("ForearmCore" .. s, 1, 0.36, fore * C(0, -0.6, 0), FRAME)
	part("ForearmShell" .. s, V(0.5, 0.9, 0.3), fore * C(0, -0.58, 0.1), ARMOR)
	cylY("ForearmCable" .. s, 0.9, 0.07, fore * C(-side * 0.22, -0.58, -0.12), RUBBER)
	ball("WristActuator" .. s, 0.3, fore * C(0, -FOREARM, 0), JOINT)

	part("Palm" .. s, V(0.42, 0.42, 0.2), hand * C(0, -0.25, 0), FRAME)
	part("Knuckles" .. s, V(0.44, 0.12, 0.24), hand * C(0, -0.44, 0.02), WORN_EDGE)
	for i, x in { -0.13, 0, 0.13 } do
		local finger = hand * C(x, -0.48, 0) * deg(pose.curl, 0, 0)
		part("Finger" .. i .. s, V(0.11, 0.32, 0.12), finger * C(0, -0.15, 0), FRAME)
	end
	local thumb = hand * C(-side * 0.2, -0.18, -0.02) * deg(pose.curl * 0.6, 0, -side * 35)
	part("Thumb" .. s, V(0.11, 0.26, 0.12), thumb * C(0, -0.13, 0), FRAME)

	if side == 1 then
		-- Stun baton through the right fist, emitter 2 studs past the palm.
		cylY("BatonGrip", 0.55, 0.16, hand * C(0, -0.42, 0.12), RUBBER)
		cylY("BatonShaft", 1.3, 0.12, hand * C(0, -1.32, 0.12), JOINT)
		cylY("BatonCollar", 0.08, 0.2, hand * C(0, -0.72, 0.12), WORN_EDGE)
		ball("BatonEmitter", 0.16, hand * C(0, -2, 0.12), ARC)
		part("UnitStripe", V(0.04, 0.16, 0.84), pauldronSide * C(0.08, 0, 0), HAZARD)
	end
end

return {
	name = "Robo-Guard",
	rootSize = V(2.4, 2.8, 1.4),
	hipHeight = 2.8,
	reach = 4.6,
	pieces = pieces,
}
