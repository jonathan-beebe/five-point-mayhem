-- Slime: a sagging mound of murky olive gel, 6.4 wide and 4.5 tall, leaning into its direction of
-- travel. Seven overlapping translucent Glass lobes sit on a darker gel foot that spreads into a wet
-- ground film and a trail behind (+Z). Three pseudopods push out at the leading edge (-Z) and four
-- drips run down to the foot. Inside: sediment on the floor, an opaque core, a skull in the upper
-- front (its sockets are the face), a femur, ribs, vertebrae, coins, a boot, and a rusted sword
-- swallowed point-first with its hilt out of the upper rear-left.
-- Scale: 4 studs = 1 m. Root y 0.2..3.2, x/z -1.5..1.5, inside the gel. Foot top y 0.6.
--
-- Roblox does not render transparent parts behind transparent Glass, so only the outer gel is
-- transparent; every interior piece has transparency 0.

local rgb = Color3.fromRGB
local M = Enum.Material
local V = Vector3.new
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball
local rad = math.rad

-- Palette: { color, material, reflectance, transparency }.
local GEL_A = { rgb(146, 172, 88), M.Glass, 0.15, 0.45 }
local GEL_B = { rgb(138, 166, 82), M.Glass, 0.15, 0.42 }
local GEL_C = { rgb(154, 178, 96), M.Glass, 0.15, 0.45 }
local GEL_D = { rgb(132, 160, 84), M.Glass, 0.15, 0.42 }
local GEL_E = { rgb(150, 174, 78), M.Glass, 0.15, 0.45 }
local GEL_F = { rgb(162, 184, 104), M.Glass, 0.18, 0.5 }
local GEL_G = { rgb(158, 180, 98), M.Glass, 0.18, 0.48 }
local GEL_FOOT = { rgb(112, 138, 60), M.Glass, 0.12, 0.35 }
local FILM = { rgb(170, 182, 122), M.Glass, 0.3, 0.6 }
local DRIP_A = { rgb(126, 154, 70), M.Glass, 0.2, 0.35 }
local DRIP_B = { rgb(134, 160, 74), M.Glass, 0.2, 0.35 }
local BEAD = { rgb(118, 146, 62), M.Glass, 0.28, 0.3 }
local BLISTER = { rgb(190, 202, 142), M.Glass, 0.35, 0.5 }
local CORE = { rgb(72, 88, 38), M.SmoothPlastic, 0.05 }
local SEDIMENT = { rgb(60, 56, 34), M.Ground }
local BONE_A = { rgb(198, 186, 150), M.Plaster }
local BONE_B = { rgb(184, 170, 132), M.Plaster }
local BONE_C = { rgb(168, 154, 116), M.Plaster }
local SOCKET = { rgb(36, 32, 22), M.SmoothPlastic }
local RUST = { rgb(112, 72, 44), M.CorrodedMetal }
local IRON = { rgb(74, 66, 58), M.CorrodedMetal }
local GRIP = { rgb(50, 38, 28), M.Fabric }
local GOLD_A = { rgb(176, 140, 60), M.Metal, 0.2 }
local GOLD_B = { rgb(158, 124, 52), M.Metal, 0.15 }
local GOLD_C = { rgb(188, 152, 72), M.Metal, 0.2 }
local LEATHER_A = { rgb(66, 44, 30), M.Leather }
local LEATHER_B = { rgb(54, 37, 26), M.Leather }

local pieces = {}

-- Position plus rotation in degrees.
local function at(x, y, z, rx, ry, rz)
	return CFrame.new(x, y, z) * CFrame.Angles(rad(rx or 0), rad(ry or 0), rad(rz or 0))
end

-- A cylinder standing on its axis (a disc when short).
local function upright(x, y, z)
	return at(x, y, z, 0, 0, 90)
end

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

local function cyl(name, size, offset, style)
	part(name, size, offset, style, CYL)
end

local function ball(name, d, offset, style)
	part(name, V(d, d, d), offset, style, BALL)
end

-- Gel body ------------------------------------------------------------------------------------
ball("Head", 4.6, at(0, 2.2, 0.1), GEL_A)
ball("GelFront", 3.6, at(0, 1.75, -1.3), GEL_B)
ball("GelBack", 3.4, at(0, 1.6, 1.5), GEL_C)
ball("GelLeft", 3.4, at(-1.5, 1.6, 0.1), GEL_D)
ball("GelRight", 3.2, at(1.6, 1.5, 0.3), GEL_E)
ball("GelCrown", 2.6, at(-0.8, 3.2, -0.6), GEL_F)
ball("GelShoulder", 2.4, at(1, 2.9, -0.9), GEL_G)

-- Base: foot, ground film, trail behind.
cyl("GelFoot", V(0.6, 6.2, 6.2), upright(0, 0.3, 0.1), GEL_FOOT)
cyl("GelFilm", V(0.12, 7.4, 7.4), upright(0, 0.06, 0.5), FILM)
cyl("TrailNear", V(0.3, 3, 3), upright(0.35, 0.15, 3.7), GEL_FOOT)
cyl("TrailFar", V(0.16, 1.8, 1.8), upright(0.7, 0.08, 5.1), FILM)

-- Leading edge pseudopods.
ball("PseudopodL", 1.4, at(-1.35, 0.62, -2.75), GEL_B)
ball("PseudopodM", 1, at(0.15, 0.45, -3.25), GEL_D)
ball("PseudopodR", 1.2, at(1.3, 0.55, -2.8), GEL_C)

-- Drips: a runner from the lobe's equator down to the foot, a bead pooled on the foot rim.
cyl("DripLRunner", V(1, 0.36, 0.36), upright(-2.98, 1.1, 0.23), DRIP_A)
ball("DripLBead", 0.56, at(-3.06, 0.72, 0.24), BEAD)
cyl("DripRRunner", V(0.9, 0.36, 0.36), upright(3, 1.05, 0.05), DRIP_B)
ball("DripRBead", 0.56, at(3.08, 0.72, 0.04), BEAD)
cyl("DripBLRunner", V(1, 0.36, 0.36), upright(-0.75, 1.1, 2.79), DRIP_A)
ball("DripBLBead", 0.56, at(-0.79, 0.72, 2.86), BEAD)
cyl("DripFRRunner", V(1.15, 0.36, 0.36), upright(0.99, 1.17, -2.48), DRIP_B)
ball("DripFRBead", 0.56, at(1.04, 0.72, -2.54), BEAD)

-- Surface blisters, sunk just inside the Head and GelLeft surfaces.
ball("BlisterA", 0.7, at(-1.31, 3.29, -1.21), BLISTER)
ball("BlisterB", 0.5, at(0.66, 3.74, 1.53), BLISTER)
ball("BlisterC", 0.4, at(-2.82, 2.16, -0.65), BLISTER)

-- Interior mass.
ball("Core", 2, at(0.2, 1.7, 0.5), CORE)
cyl("Sediment", V(0.4, 4.4, 4.4), upright(0, 0.32, 0.2), SEDIMENT)

-- Skull: face turned 20 degrees to the creature's left, jaw hanging open.
ball("SkullCranium", 1.15, at(0.37, 2.89, -0.96, -12, 20, 10), BONE_A)
part("SkullFace", V(0.74, 0.5, 0.4), at(0.26, 2.46, -1.37, -12, 20, 10), BONE_B)
ball("SkullEyeL", 0.3, at(0.01, 2.59, -1.43, -12, 20, 10), SOCKET)
ball("SkullEyeR", 0.3, at(0.36, 2.63, -1.57, -12, 20, 10), SOCKET)
part("SkullJaw", V(0.64, 0.16, 0.5), at(0.34, 2.08, -1.25, 11.5, 22.2, 1.4), BONE_C)

-- Bones: femur with knobs at both ends, two ribs, two vertebrae on the sediment.
cyl("FemurShaft", V(2.2, 0.3, 0.3), at(1.15, 1.55, 0.85, 0, 49.7, 16.3), BONE_B)
ball("FemurHead", 0.46, at(1.83, 1.86, 0.05), BONE_C)
ball("FemurKnee", 0.5, at(0.47, 1.24, 1.65), BONE_A)
part("RibA", V(0.12, 0.22, 1.5), at(-1.55, 1.25, 0.9, -36.3, 20.6, 14.5), BONE_A)
part("RibB", V(0.12, 0.22, 1.5), at(-1.75, 1.05, 0.35, -33.7, 23.9, 15.1), BONE_C)
cyl("VertebraA", V(0.28, 0.42, 0.42), at(-0.9, 0.65, -1.2, 0, 35, 8), BONE_B)
cyl("VertebraB", V(0.28, 0.42, 0.42), at(-0.62, 0.67, -1.45, 0, 35, -6), BONE_A)

-- Sword: swallowed point-first, hilt out of the upper rear-left.
part("SwordBlade", V(0.08, 0.34, 3.5), at(-1.06, 2.41, 0.88, -49.3, -18.6, -90), RUST)
part("SwordGuard", V(0.14, 1, 0.14), at(-1.64, 3.71, 2.01, -49.3, -18.6, -90), IRON)
cyl("SwordGrip", V(0.8, 0.16, 0.16), at(-1.79, 4.05, 2.3, -180, -62.7, -134.1), GRIP)
ball("SwordPommel", 0.26, at(-1.95, 4.41, 2.61), IRON)

-- Coins on the sediment.
cyl("CoinA", V(0.06, 0.36, 0.36), at(0.9, 0.55, -0.9, 8, 0, 94), GOLD_A)
cyl("CoinB", V(0.06, 0.36, 0.36), at(1.25, 0.55, -0.5, -6, 0, 100), GOLD_B)
cyl("CoinC", V(0.06, 0.36, 0.36), at(-0.3, 0.55, 1.6, 12, 0, 85), GOLD_C)

-- Half-dissolved boot.
part("BootShaft", V(0.5, 1, 0.55), at(1.6, 1.4, 1, 0, -30, -70), LEATHER_A)
part("BootFoot", V(0.5, 0.4, 0.95), at(1.54, 1.28, 0.45, 0, -30, -70), LEATHER_B)

return {
	name = "Slime",
	rootSize = V(3, 3, 3),
	hipHeight = 0.2,
	reach = 5.5,
	pieces = pieces,
}
