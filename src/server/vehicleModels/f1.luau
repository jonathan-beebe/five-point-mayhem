-- Formula 1 Car: 2024-regulation ground-effect single-seater in racing red with halo and DRS wing.

local rgb = Color3.fromRGB
local M = Enum.Material
local A = CFrame.Angles
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball
local WEDGE = "WedgePart"

-- Scale: 4.6 studs = 1 m (low car; lets the R15 avatar fit the cockpit).

-- Rotations. Cylinder axis is local X; WedgePart default has its right angle at (ymin, zmax).
local CYLINDER_Z = A(0, math.rad(90), 0)
local RISE_REAR = CFrame.identity -- low at the front, high at the rear
local RISE_FRONT = A(0, math.pi, 0) -- high at the front, low at the rear
local FLIP_Z = A(0, 0, math.pi) -- right angle at (ymax, zmax); underside slopes down toward the rear
local FLIP_X = A(math.pi, 0, 0) -- right angle at (ymax, zmin); underside slopes up toward the rear
local SIDE_L = A(0, math.rad(90), 0) -- length along Z, slope rises toward +X
local SIDE_R = A(0, -math.rad(90), 0) -- length along Z, slope rises toward -X

-- Trailing edge up by deg degrees.
local function teUp(deg: number): CFrame
	return A(math.rad(-deg), 0, 0)
end

-- Palette: color, material, reflectance.
local RED = { c = rgb(158, 12, 22), m = M.SmoothPlastic, r = 0.12 }
local WHITE = { c = rgb(240, 240, 236), m = M.SmoothPlastic, r = 0.1 }
local CARBON = { c = rgb(24, 24, 27), m = M.SmoothPlastic, r = 0.05 }
local HALO = { c = rgb(24, 24, 27), m = M.SmoothPlastic, r = 0.1 }
local FLOOR = { c = rgb(18, 18, 20), m = M.SmoothPlastic }
local BLACK_HOLE = { c = rgb(8, 8, 10), m = M.SmoothPlastic }
local INTERIOR = { c = rgb(34, 34, 38), m = M.Fabric }
local TIRE = { c = rgb(26, 26, 28), m = M.Fabric }
local COMPOUND = { c = rgb(245, 205, 30), m = M.SmoothPlastic }
local RIM = { c = rgb(165, 168, 172), m = M.Metal }
local COVER = { c = rgb(30, 30, 33), m = M.SmoothPlastic, r = 0.1 }
local METAL = { c = rgb(120, 120, 125), m = M.Metal }
local EXHAUST = { c = rgb(110, 100, 92), m = M.Metal }
local PLANK = { c = rgb(140, 110, 70), m = M.Wood }
local MIRROR = { c = rgb(170, 185, 200), m = M.Glass, r = 0.5 }
local SCREEN = { c = rgb(15, 20, 28), m = M.SmoothPlastic }
local LED_GREEN = { c = rgb(60, 220, 90), m = M.Neon }
local TAIL_RED = { c = rgb(255, 30, 30), m = M.Neon }
local TCAM = { c = rgb(225, 245, 30), m = M.SmoothPlastic }

local FRONT_AXLE_Z = -7.6
local REAR_AXLE_Z = 9.0
local WHEEL_Y = 1.655
local TIRE_D = 3.31

local pieces = {}

local function add(p)
	table.insert(pieces, p)
end

local function part(
	name: string,
	size: Vector3,
	cf: CFrame,
	style,
	class: string?,
	shape: Enum.PartType?
)
	add({
		name = name,
		class = class,
		shape = shape,
		size = size,
		offset = cf,
		color = style.c,
		material = style.m,
		reflectance = style.r,
	})
end

local function v(x: number, y: number, z: number): Vector3
	return Vector3.new(x, y, z)
end

local function at(x: number, y: number, z: number): CFrame
	return CFrame.new(x, y, z)
end

-- A box of width w and height h running from a to b.
local function rod(name: string, a: Vector3, b: Vector3, w: number, h: number, style)
	part(name, v(w, h, (b - a).Magnitude), CFrame.lookAt((a + b) / 2, b), style)
end

-- A round tube of diameter d running from a to b.
local function tube(name: string, a: Vector3, b: Vector3, d: number, style)
	part(
		name,
		v((b - a).Magnitude, d, d),
		CFrame.lookAt((a + b) / 2, b) * CYLINDER_Z,
		style,
		nil,
		CYL
	)
end

local SIDES = { -1, 1 }

-- Front wing --------------------------------------------------------------------------------

part("WingNeutral", v(1.0, 0.12, 1.4), at(0, 0.55, -12.0), CARBON)
for _, s in SIDES do
	part("WingMain", v(3.9, 0.12, 1.3), at(s * 2.45, 0.45, -12.0) * teUp(4), CARBON)
	part("WingE2", v(3.9, 0.1, 0.9), at(s * 2.45, 0.75, -11.0) * teUp(15), CARBON)
	part("WingE3", v(3.9, 0.08, 0.8), at(s * 2.45, 1.05, -10.35) * teUp(28), RED)
	part("WingE4", v(3.9, 0.08, 0.6), at(s * 2.45, 1.35, -9.85) * teUp(40), RED)
	part("WingGurney", v(3.9, 0.08, 0.03), at(s * 2.45, 1.57, -9.62) * teUp(40), WHITE)
	part("Endplate", v(0.1, 1.2, 1.8), at(s * 4.45, 0.85, -10.9), WHITE)
	part("EndplateNose", v(0.1, 1.2, 1.0), at(s * 4.45, 0.85, -12.3), WHITE, WEDGE)
	part("Footplate", v(0.6, 0.06, 2.6), at(s * 4.2, 0.28, -11.2), CARBON)
	part("FlapAdjuster", v(0.18, 0.25, 0.5), at(s * 0.62, 1.2, -10.1), CARBON)
end

-- Nose --------------------------------------------------------------------------------------

local NOSE = {
	{ z = -12.6, w = 0.9, yb = 0.75, yt = 1.25 },
	{ z = -10.6, w = 1.15, yb = 0.95, yt = 1.75 },
	{ z = -8.6, w = 1.45, yb = 1.2, yt = 2.25 },
	{ z = -6.6, w = 1.9, yb = 1.3, yt = 2.65 },
	{ z = -4.6, w = 2.4, yb = 1.25, yt = 2.95 },
	{ z = -2.6, w = 3.0, yb = 1.15, yt = 3.15 },
}
for i = 1, #NOSE - 1 do
	local a, b = NOSE[i], NOSE[i + 1]
	local style = if i == 1 then WHITE else RED
	local w = (a.w + b.w) / 2
	local len = b.z - a.z
	local zc = (a.z + b.z) / 2
	local yb = (a.yb + b.yb) / 2
	local top = math.min(a.yt, b.yt)
	part("NoseBox", v(w, top - yb, len), at(0, (top + yb) / 2, zc), style)
	local rise = b.yt - a.yt
	part("NoseTop", v(w, rise, len), at(0, top + rise / 2, zc) * RISE_REAR, style, WEDGE)
end
-- S5 -> S6 is hollow below y 2.15 for the driver's legs.
part("NoseDeck", v(3.2, 1.05, 1.0), at(0, 2.675, -2.1), RED)
for _, s in SIDES do
	part("NoseWall", v(0.55, 1.05, 1.0), at(s * 1.325, 1.625, -2.1), RED)
	part("NoseCam", v(0.22, 0.12, 0.45), at(s * 0.55, 2.3, -8.0), CARBON)
end
part("NoseCap", v(0.9, 0.5, 0.15), at(0, 1.0, -12.675) * RISE_FRONT, WHITE, WEDGE)
part("Pitot", v(0.6, 0.05, 0.05), at(0, 1.3, -12.95) * CYLINDER_Z, METAL, nil, CYL)

-- Cockpit and tub ---------------------------------------------------------------------------

for _, s in SIDES do
	part("CockpitSide", v(0.62, 2.1, 3.5), at(s * 1.46, 2.15, 0.15), RED)
	part("CoamingPad", v(0.66, 0.08, 3.5), at(s * 1.46, 3.24, 0.15), INTERIOR)
	part("HeadPadSide", v(0.3, 0.6, 2.0), at(s * 1.3, 3.5, 0.85), INTERIOR)
end
part("FrontCoaming", v(2.3, 0.5, 0.4), at(0, 2.95, -1.4), RED)
part("SeatBack", v(2.3, 2.0, 0.15), at(0, 2.1, 1.35), INTERIOR)
part("HeadrestRear", v(2.6, 1.0, 0.7), at(0, 3.6, 1.65), INTERIOR)
part("Column", v(0.15, 0.15, 0.4), at(0, 2.85, -1.2), CARBON)

local WHEEL = CFrame.new(0, 2.9, -0.95) * A(math.rad(20), 0, 0)
part("WheelBody", v(1.25, 0.55, 0.12), WHEEL, CARBON)
part("WheelDisplay", v(0.5, 0.25, 0.02), WHEEL * at(0, 0.05, 0.07), SCREEN)
part("WheelLEDs", v(0.5, 0.04, 0.02), WHEEL * at(0, 0.22, 0.07), LED_GREEN)
for _, s in SIDES do
	part(
		"WheelGrip",
		v(0.55, 0.18, 0.18),
		WHEEL * at(s * 0.6, 0, 0) * A(0, 0, math.rad(90)),
		INTERIOR,
		nil,
		CYL
	)
end

-- Halo --------------------------------------------------------------------------------------

for _, s in SIDES do
	part("HaloMount", v(0.3, 1.0, 0.35), at(s * 1.6, 3.7, 1.5), HALO)
	tube("HaloTube", v(s * 1.6, 4.25, 1.5), v(s * 1.0, 4.25, -1.1), 0.3, HALO)
	part("HaloJointFront", v(0.3, 0.3, 0.3), at(s * 1.0, 4.25, -1.1), HALO, nil, BALL)
	part("HaloJointRear", v(0.3, 0.3, 0.3), at(s * 1.6, 4.25, 1.5), HALO, nil, BALL)
end
part("HaloFront", v(2.0, 0.3, 0.3), at(0, 4.25, -1.1), HALO, nil, CYL)
rod("HaloPillar", v(0, 4.2, -1.15), v(0, 3.3, -1.9), 0.3, 0.3, HALO)
part("PillarFoot", v(0.5, 0.15, 0.6), at(0, 3.25, -1.95), HALO)

-- Airbox, engine cover, rear body -----------------------------------------------------------

part("FuelCell", v(3.5, 2.3, 1.5), at(0, 2.25, 2.65), RED)
part("EngineLower", v(3.4, 1.9, 2.6), at(0, 2.05, 4.7), RED)
part("RearBody", v(3.2, 1.2, 3.0), at(0, 1.7, 7.5), RED)
part("Gearbox", v(1.8, 1.1, 1.6), at(0, 1.65, 9.8), CARBON)
part("CrashStructure", v(0.9, 0.7, 1.2), at(0, 1.65, 11.2), CARBON)
part("RainLight", v(0.5, 0.25, 0.05), at(0, 1.65, 11.825), TAIL_RED)
part("Airbox", v(1.8, 1.1, 1.5), at(0, 3.95, 2.65), RED)
part("AirboxInlet", v(1.1, 0.8, 0.05), at(0, 3.95, 1.875), BLACK_HOLE)
for _, s in SIDES do
	part("AirboxStripe", v(0.04, 0.22, 1.4), at(s * 0.92, 4.2, 2.65), WHITE)
end
part("TcamStalk", v(0.1, 0.15, 0.1), at(0, 4.57, 2.3), CARBON)
part("Tcam", v(1.0, 0.1, 0.25), at(0, 4.7, 2.3), TCAM)
part("Spine1", v(1.7, 0.9, 2.0), at(0, 3.45, 4.4), RED)
part("Spine1Top", v(1.7, 0.6, 2.0), at(0, 4.2, 4.4) * RISE_FRONT, RED, WEDGE)
part("Spine2", v(1.45, 0.85, 2.0), at(0, 2.725, 6.4), RED)
part("Spine2Top", v(1.45, 0.75, 2.0), at(0, 3.525, 6.4) * RISE_FRONT, RED, WEDGE)
part("Spine3", v(1.15, 0.2, 2.0), at(0, 2.4, 8.4), RED)
part("Spine3Top", v(1.15, 0.65, 2.0), at(0, 2.825, 8.4) * RISE_FRONT, RED, WEDGE)
part("Spine4", v(0.9, 0.2, 1.2), at(0, 2.4, 10.0) * RISE_FRONT, RED, WEDGE)
-- Fin: lower edge buried in the cover, top edge falls from the airbox to the rear wing.
part("SharkFin", v(0.06, 1.6, 4.0), at(0, 3.3, 7.4) * RISE_FRONT, RED, WEDGE)
part("Exhaust", v(0.8, 0.4, 0.4), at(0, 2.6, 10.8) * CYLINDER_Z, EXHAUST, nil, CYL)
part("ExhaustBore", v(0.02, 0.3, 0.3), at(0, 2.6, 11.21) * CYLINDER_Z, BLACK_HOLE, nil, CYL)
for _, s in SIDES do
	part("Wastegate", v(0.6, 0.18, 0.18), at(s * 0.38, 2.6, 10.9) * CYLINDER_Z, EXHAUST, nil, CYL)
end

-- Sidepods ----------------------------------------------------------------------------------

for _, s in SIDES do
	local side = if s > 0 then SIDE_R else SIDE_L
	part("PodFront", v(2.0, 1.4, 1.0), at(s * 2.75, 2.45, 0.2), RED)
	part("PodInlet", v(1.6, 0.85, 0.05), at(s * 2.8, 2.55, -0.325), BLACK_HOLE)
	part("InletLipTop", v(2.0, 0.1, 0.25), at(s * 2.75, 3.1, -0.4), RED)
	part("Undercut", v(1.5, 1.45, 4.8), at(s * 2.5, 1.025, 2.1) * FLIP_Z, RED, WEDGE)
	part("Pod1", v(2.0, 1.0, 2.5), at(s * 2.7, 2.25, 1.95), RED)
	part("Pod1Top", v(2.0, 0.4, 2.5), at(s * 2.7, 2.95, 1.95) * RISE_FRONT, RED, WEDGE)
	part("Pod2", v(1.6, 0.6, 2.4), at(s * 2.5, 2.05, 4.4), RED)
	part("Pod2Top", v(1.6, 0.4, 2.4), at(s * 2.5, 2.55, 4.4) * RISE_FRONT, RED, WEDGE)
	part("Pod3", v(1.0, 0.5, 2.0), at(s * 2.1, 1.75, 6.6), RED)
	part("Pod3Top", v(1.0, 0.35, 2.0), at(s * 2.1, 2.175, 6.6) * RISE_FRONT, RED, WEDGE)
	part("PodStripe", v(0.04, 0.25, 2.4), at(s * 3.72, 2.5, 1.95), WHITE)
	part("PodChamfer", v(0.3, 0.3, 2.2), at(s * 3.6, 3.0, 0.2) * side, RED, WEDGE)
	for k, z in { 3.6, 4.0, 4.4, 4.8 } do
		local y = 2.75 - (z - 3.2) / 6 + 0.055
		part(
			"Louvre" .. k,
			v(1.0, 0.05, 0.12),
			at(s * 2.5, y, z) * A(math.rad(9.5), 0, 0),
			BLACK_HOLE
		)
	end
	part("Mirror", v(0.85, 0.42, 0.25), at(s * 2.6, 3.75, 0.05), RED)
	part("MirrorGlass", v(0.75, 0.32, 0.03), at(s * 2.6, 3.75, 0.19), MIRROR)
	part("MirrorStalk", v(0.12, 0.5, 0.12), at(s * 2.45, 3.4, 0.15), CARBON)
end

-- Floor and diffuser ------------------------------------------------------------------------

part("FloorPlate", v(7.0, 0.1, 10.2), at(0, 0.3, 2.1), FLOOR)
part("Plank", v(0.6, 0.04, 10.0), at(0, 0.23, 2.2), PLANK)
part("FloorBib", v(2.4, 0.2, 1.5), at(0, 0.55, -3.75), FLOOR)
part("Diffuser", v(4.8, 1.4, 3.8), at(0, 1.0, 9.1) * FLIP_X, FLOOR, WEDGE)
for _, s in SIDES do
	part("FloorEdge", v(0.1, 0.35, 8.0), at(s * 3.45, 0.5, 2.0), FLOOR)
	part("EdgeWing", v(0.5, 0.05, 2.0), at(s * 3.3, 0.75, 5.8) * A(math.rad(-10), 0, 0), FLOOR)
	part("InletRamp", v(1.9, 0.6, 1.2), at(s * 2.55, 0.6, -3.0) * RISE_FRONT, FLOOR, WEDGE)
	part("DiffWall", v(0.08, 1.4, 3.8), at(s * 2.4, 1.0, 9.1), FLOOR)
	for _, x in { 0.9, 1.6 } do
		part("Fence", v(0.06, 0.6, 1.6), at(s * x, 0.6, -2.4), FLOOR)
	end
	for _, x in { 0.8, 1.6 } do
		part("Strake", v(0.06, 0.7, 2.6), at(s * x, 0.75, 9.5), FLOOR)
	end
end

-- Rear wing ---------------------------------------------------------------------------------

for _, s in SIDES do
	part("RearEndplate", v(0.1, 2.2, 2.4), at(s * 2.35, 2.75, 11.3), RED)
	part("RearEndplateTop", v(0.1, 0.4, 2.4), at(s * 2.35, 4.05, 11.3) * RISE_REAR, RED, WEDGE)
	part("RearEndplatePanel", v(0.03, 0.35, 2.2), at(s * 2.415, 3.6, 11.3), WHITE)
	part("RearEndplateLED", v(0.12, 0.7, 0.05), at(s * 2.35, 3.4, 12.525), TAIL_RED)
	part("SwanNeck", v(0.12, 1.5, 0.35), at(s * 0.25, 3.05, 11.0), CARBON)
end
part("MainPlane", v(4.6, 0.14, 1.6), at(0, 3.45, 11.2) * teUp(12), RED)
part("DRSFlap", v(4.6, 0.1, 1.0), at(0, 3.95, 12.05) * teUp(35), WHITE)
part("DRSGurney", v(4.6, 0.04, 0.05), at(0, 3.95, 12.05) * teUp(35) * at(0, 0.07, 0.47), RED)
part("DRSPod", v(0.3, 0.5, 0.3), at(0, 4.0, 11.6), CARBON)
part("Beam1", v(4.6, 0.1, 0.8), at(0, 1.95, 10.9) * teUp(10), CARBON)
part("Beam2", v(4.6, 0.08, 0.6), at(0, 2.2, 11.6) * teUp(25), CARBON)

-- Wheels ------------------------------------------------------------------------------------

local function wheel(s: number, track: number, width: number, z: number)
	local outer = track + width / 2
	local inner = track - width / 2
	local function disc(name, thick, d, x, style)
		part(name, v(thick, d, d), at(s * x, WHEEL_Y, z), style, nil, CYL)
	end
	disc("Tire", width, TIRE_D, track, TIRE)
	disc("CompoundStripe", 0.04, 2.85, outer + 0.02, COMPOUND)
	disc("SidewallMask", 0.04, 2.62, outer + 0.04, TIRE)
	disc("RimLip", 0.04, 2.3, outer + 0.06, RIM)
	disc("WheelCover", 0.04, 2.14, outer + 0.08, COVER)
	disc("WheelNut", 0.08, 0.5, outer + 0.12, RED)
	disc("BrakeDuct", 0.5, 1.9, inner - 0.25, CARBON)
	part("Caliper", v(0.15, 0.5, 0.35), at(s * (inner - 0.58), WHEEL_Y + 0.65, z + 0.2), RED)
end

for _, s in SIDES do
	wheel(s, 3.68, 1.4, FRONT_AXLE_Z)
	wheel(s, 3.56, 1.86, REAR_AXLE_Z)
	part("Winglet", v(1.1, 0.06, 1.6), at(s * 3.55, 3.48, -7.7) * A(math.rad(-6), 0, 0), CARBON)
	part("WingletStalk", v(0.08, 0.9, 0.08), at(s * 2.95, 3.05, -7.7), CARBON)
end

-- Suspension --------------------------------------------------------------------------------

for _, s in SIDES do
	local function p(x, y, z)
		return v(s * x, y, z)
	end
	rod("FU1", p(0.75, 2.45, -8.6), p(2.6, 2.35, -7.6), 0.24, 0.08, CARBON)
	rod("FU2", p(0.8, 2.6, -6.4), p(2.6, 2.35, -7.6), 0.24, 0.08, CARBON)
	rod("FL1", p(0.75, 1.45, -8.8), p(2.6, 1.05, -7.6), 0.24, 0.08, CARBON)
	rod("FL2", p(0.9, 1.4, -6.0), p(2.6, 1.05, -7.6), 0.24, 0.08, CARBON)
	rod("Pushrod", p(2.5, 1.15, -7.4), p(0.9, 2.6, -7.2), 0.12, 0.12, CARBON)
	rod("TrackRod", p(0.8, 1.8, -8.2), p(2.6, 1.8, -8.0), 0.12, 0.12, CARBON)
	part("FrontUpright", v(0.25, 1.6, 0.5), at(s * 2.85, WHEEL_Y, FRONT_AXLE_Z), CARBON)

	rod("RU1", p(1.5, 2.5, 8.0), p(2.45, 2.5, 9.0), 0.24, 0.08, CARBON)
	rod("RU2", p(0.9, 2.5, 10.2), p(2.45, 2.5, 9.0), 0.24, 0.08, CARBON)
	rod("RL1", p(1.5, 1.35, 7.6), p(2.45, 1.2, 9.0), 0.24, 0.08, CARBON)
	rod("RL2", p(0.9, 1.35, 10.4), p(2.45, 1.2, 9.0), 0.24, 0.08, CARBON)
	rod("Pullrod", p(2.45, 2.3, 9.1), p(1.0, 1.3, 8.8), 0.12, 0.12, CARBON)
	part("Driveshaft", v(1.0, 0.25, 0.25), at(s * 1.95, WHEEL_Y, REAR_AXLE_Z), METAL, nil, CYL)
	part("RearUpright", v(0.25, 1.6, 0.5), at(s * 2.25, WHEEL_Y, REAR_AXLE_Z), CARBON)
end

return {
	name = "Formula 1 Car",
	speed = 150,
	turnRate = 2.6,
	footprint = Vector2.new(9.2, 25.3),
	collision = {
		{ size = Vector3.new(9.2, 2.0, 20.4), offset = CFrame.new(0, 2.2, 0.6) }, -- body + wheels, y 1.2..3.2
		{ size = Vector3.new(1.4, 0.6, 3.0), offset = CFrame.new(0, 1.55, -11.1) }, -- nose, y 1.25..1.85
		{ size = Vector3.new(2.4, 1.3, 7.0), offset = CFrame.new(0, 3.85, 5.0) }, -- airbox/engine cover
		{ size = Vector3.new(4.8, 2.6, 2.8), offset = CFrame.new(0, 2.95, 11.2) }, -- rear wing, y 1.65..4.25
	},
	seats = { CFrame.new(0, 0.5, 0.6) }, -- seat top y 1.0
	pieces = pieces,
}
