-- Meteor Staff: carved walnut walking staff with blackened-iron fittings, holding a cracked stony-iron meteorite in a forged four-prong claw.

local WeaponModel = require(script.Parent.Parent.systems.WeaponModel)

local rgb = Color3.fromRGB
local M = Enum.Material
local CYLINDER_Y = WeaponModel.CYLINDER_Y
local rad = math.rad

local BALL = Enum.PartType.Ball
local CYL = Enum.PartType.Cylinder

local WALNUT = rgb(92, 62, 40)
local DARK_WALNUT = rgb(60, 40, 26)
local LEATHER_BROWN = rgb(84, 54, 34)
local LACING_DARK = rgb(50, 32, 20)
local BLACKENED_IRON = rgb(44, 42, 40)
local FORGED_IRON = rgb(70, 68, 64)
local AGED_BRASS = rgb(150, 118, 62)
local CHARCOAL_BASALT = rgb(36, 33, 31)
local SCORCHED_BASALT = rgb(58, 44, 38)
local METEORIC_IRON = rgb(86, 54, 38)
local MOLTEN_CORE = rgb(220, 70, 30)

local METEOR_CENTER = CFrame.new(0, 4.95, 0)

-- Cylinder standing on the shaft axis: length along Y, diameter in X/Z.
local function ring(
	name: string,
	length: number,
	diameter: number,
	y: number,
	color: Color3,
	material: Enum.Material,
	reflectance: number?
)
	return {
		name = name,
		shape = CYL,
		size = Vector3.new(length, diameter, diameter),
		offset = CFrame.new(0, y, 0) * CYLINDER_Y,
		color = color,
		material = material,
		reflectance = reflectance,
	}
end

local function ball(
	name: string,
	diameter: number,
	position: Vector3,
	color: Color3,
	material: Enum.Material
)
	return {
		name = name,
		shape = BALL,
		size = Vector3.new(diameter, diameter, diameter),
		offset = CFrame.new(position),
		color = color,
		material = material,
	}
end

local function lacing(index: number, y: number)
	return {
		name = "Lacing" .. index,
		shape = CYL,
		size = Vector3.new(0.04, 0.39, 0.39),
		offset = CFrame.new(0, y, 0) * CFrame.Angles(rad(10), 0, 0) * CYLINDER_Y,
		color = LACING_DARK,
		material = M.Leather,
	}
end

-- Rock plate on the meteor shell: outer face at r 0.55, inner face buried in the core.
local function rock(
	index: number,
	yaw: number,
	pitch: number,
	roll: number,
	w: number,
	h: number,
	color: Color3
)
	return {
		name = "Rock" .. index,
		size = Vector3.new(w, h, 0.16),
		offset = METEOR_CENTER
			* CFrame.Angles(0, rad(yaw), 0)
			* CFrame.Angles(rad(pitch), 0, 0)
			* CFrame.new(0, 0, -0.47)
			* CFrame.Angles(0, 0, rad(roll)),
		color = color,
		material = color == METEORIC_IRON and M.CorrodedMetal or M.Basalt,
	}
end

-- One forged claw prong in the plane at azimuth theta: lower arm, knuckle, upper arm, curled tip.
local function claw(pieces: { WeaponModel.PieceSpec }, theta: number)
	local c = CFrame.Angles(0, rad(theta), 0)
	table.insert(pieces, {
		name = "ClawLower_" .. theta,
		size = Vector3.new(0.08, 0.64, 0.10),
		offset = c * CFrame.new(0.44, 4.54, 0) * CFrame.Angles(0, 0, rad(-32.1)),
		color = BLACKENED_IRON,
		material = M.Metal,
	})
	table.insert(pieces, {
		name = "ClawKnuckle_" .. theta,
		shape = BALL,
		size = Vector3.new(0.13, 0.13, 0.13),
		offset = c * CFrame.new(0.60, 4.80, 0),
		color = FORGED_IRON,
		material = M.Metal,
	})
	table.insert(pieces, {
		name = "ClawUpper_" .. theta,
		size = Vector3.new(0.08, 0.66, 0.10),
		offset = c * CFrame.new(0.51, 5.10, 0) * CFrame.Angles(0, 0, rad(16.7)),
		color = BLACKENED_IRON,
		material = M.Metal,
	})
	table.insert(pieces, {
		name = "ClawTip_" .. theta,
		size = Vector3.new(0.06, 0.22, 0.08),
		offset = c * CFrame.new(0.35, 5.48, 0) * CFrame.Angles(0, 0, rad(40)),
		color = FORGED_IRON,
		material = M.Metal,
	})
end

local pieces: { WeaponModel.PieceSpec } = {
	-- Butt: iron cap in a brass ferrule, y -1.70 to -1.22
	ball("ButtCap", 0.28, Vector3.new(0, -1.56, 0), FORGED_IRON, M.Metal),
	ring("Ferrule", 0.30, 0.32, -1.40, AGED_BRASS, M.Metal, 0.05),
	ring("FerruleRing", 0.05, 0.36, -1.24, AGED_BRASS, M.Metal, 0.05),

	-- Shaft: walnut, y -1.30 to 3.00, swelling to 0.34 under the head (2.98 to 3.90)
	ring("ShaftCore", 4.30, 0.30, 0.85, WALNUT, M.Wood),
	ring("ShaftUpper", 0.92, 0.34, 3.44, WALNUT, M.Wood),

	-- Grip: leather wrap centred on the fist, spiral lacing, brass collars, lanyard
	ring("GripWrap", 1.30, 0.36, 0, LEATHER_BROWN, M.Leather),
	lacing(1, -0.48),
	lacing(2, -0.24),
	lacing(3, 0),
	lacing(4, 0.24),
	lacing(5, 0.48),
	ring("GripCollarLow", 0.08, 0.40, -0.69, AGED_BRASS, M.Metal, 0.05),
	ring("GripCollarHigh", 0.08, 0.40, 0.69, AGED_BRASS, M.Metal, 0.05),
	{
		name = "LanyardThong",
		size = Vector3.new(0.04, 0.50, 0.03),
		offset = CFrame.new(0.21, -0.95, 0) * CFrame.Angles(0, 0, rad(6)),
		color = LACING_DARK,
		material = M.Leather,
	},
	ball("LanyardBead", 0.09, Vector3.new(0.236, -1.22, 0), AGED_BRASS, M.Metal),

	-- Wood detail: knots and raised grain, half-embedded in the shaft
	ball("KnotA", 0.12, Vector3.new(0.115, -0.95, 0.06), DARK_WALNUT, M.Wood),
	ball("KnotB", 0.12, Vector3.new(-0.09, 2.60, -0.10), DARK_WALNUT, M.Wood),
	{
		name = "GrainRight",
		size = Vector3.new(0.03, 1.40, 0.05),
		offset = CFrame.new(0.15, 1.50, 0),
		color = DARK_WALNUT,
		material = M.Wood,
	},
	{
		name = "GrainLeft",
		size = Vector3.new(0.03, 1.60, 0.05),
		offset = CFrame.new(-0.15, 2.17, 0),
		color = DARK_WALNUT,
		material = M.Wood,
	},
	{
		name = "GrainFront",
		size = Vector3.new(0.05, 1.20, 0.03),
		offset = CFrame.new(0, 1.90, -0.15),
		color = DARK_WALNUT,
		material = M.Wood,
	},
	{
		name = "GrainBack",
		size = Vector3.new(0.05, 1.00, 0.03),
		offset = CFrame.new(0, 2.47, 0.15),
		color = DARK_WALNUT,
		material = M.Wood,
	},

	-- Upper fittings: brass joint ring, wire wrap, riveted iron langets
	ring("JointRing", 0.08, 0.38, 2.99, AGED_BRASS, M.Metal, 0.05),
	ring("WireWrap1", 0.04, 0.37, 3.20, AGED_BRASS, M.Metal, 0.05),
	ring("WireWrap2", 0.04, 0.37, 3.27, AGED_BRASS, M.Metal, 0.05),
	{
		name = "LangetRight",
		size = Vector3.new(0.03, 0.60, 0.08),
		offset = CFrame.new(0.175, 3.60, 0),
		color = BLACKENED_IRON,
		material = M.Metal,
	},
	{
		name = "LangetLeft",
		size = Vector3.new(0.03, 0.60, 0.08),
		offset = CFrame.new(-0.175, 3.60, 0),
		color = BLACKENED_IRON,
		material = M.Metal,
	},
	ball("RivetRight", 0.06, Vector3.new(0.19, 3.45, 0), FORGED_IRON, M.Metal),
	ball("RivetLeft", 0.06, Vector3.new(-0.19, 3.45, 0), FORGED_IRON, M.Metal),

	-- Head socket: y 3.85 to 4.46, stacked so each part overlaps the next
	ring("Socket", 0.30, 0.42, 4.00, BLACKENED_IRON, M.Metal),
	ring("SocketLip", 0.06, 0.46, 4.16, AGED_BRASS, M.Metal, 0.05),
	ring("ClawPlate", 0.10, 0.60, 4.235, BLACKENED_IRON, M.Metal),
	ring("SeatCup", 0.18, 0.50, 4.37, FORGED_IRON, M.Metal),

	-- Meteor: glowing core showing through cracks between rock plates
	{
		name = "MoltenCore",
		shape = BALL,
		size = Vector3.new(1.00, 1.00, 1.00),
		offset = METEOR_CENTER,
		color = MOLTEN_CORE,
		material = M.Neon,
	},
	rock(1, 0, 15, 10, 0.50, 0.46, CHARCOAL_BASALT),
	rock(2, 70, -10, -20, 0.46, 0.50, SCORCHED_BASALT),
	rock(3, 140, 25, 35, 0.52, 0.42, CHARCOAL_BASALT),
	rock(4, 210, -5, 5, 0.48, 0.48, METEORIC_IRON),
	rock(5, 285, 20, -15, 0.44, 0.50, SCORCHED_BASALT),
	rock(6, 35, 60, 25, 0.42, 0.40, CHARCOAL_BASALT),
	rock(7, 180, 65, -30, 0.44, 0.38, METEORIC_IRON),
	rock(8, 105, -45, 15, 0.46, 0.40, CHARCOAL_BASALT),
	rock(9, 250, -50, 40, 0.42, 0.40, SCORCHED_BASALT),
	rock(10, 0, 90, 0, 0.40, 0.40, CHARCOAL_BASALT),
}

-- Claws: four prongs rising from the claw plate, gripping the rock
for _, theta in { 45, 135, 225, 315 } do
	claw(pieces, theta)
end

return WeaponModel.define({
	handle = {
		size = Vector3.new(0.36, 1.2, 0.36),
		color = LEATHER_BROWN,
		material = M.Leather,
		transparency = 1,
	},
	muzzle = METEOR_CENTER,
	pieces = pieces,
})
