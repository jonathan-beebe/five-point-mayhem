-- Go-Kart: CIK-FIA OK-class racing kart with chrome tube frame, red bodywork and a 2-stroke engine.

local rgb = Color3.fromRGB
local M = Enum.Material
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball
local A = CFrame.Angles
local CZ = A(0, math.rad(90), 0) -- cylinder axis along Z
local CY = A(0, 0, math.rad(90)) -- cylinder axis along Y
local FLIP_Z = A(0, 0, math.pi) -- wedge right angle at (ymax, zmax)
local RISE_FRONT = A(0, math.pi, 0) -- wedge high at the front

-- Scale: 4.6 studs = 1 m (low vehicle; the seated R15 avatar matches a real driver).

-- Palette: color, material, reflectance, transparency.
local BODY_RED = { c = rgb(200, 22, 30), m = M.SmoothPlastic, r = 0.08 }
local PLATE_WHITE = { c = rgb(240, 240, 236), m = M.SmoothPlastic }
local BLACK = { c = rgb(22, 22, 24), m = M.Plastic }
local NOSE_SLOT = { c = rgb(12, 12, 14), m = M.SmoothPlastic }
local FRAME_CHROME = { c = rgb(196, 200, 205), m = M.Metal, r = 0.3 }
local AXLE_STEEL = { c = rgb(150, 152, 158), m = M.Metal, r = 0.2 }
local BOLT_STEEL = { c = rgb(205, 205, 210), m = M.Metal }
local MAG_GREY = { c = rgb(118, 120, 126), m = M.Metal }
local TIRE = { c = rgb(30, 30, 32), m = M.SmoothPlastic }
local TIRE_SIDE = { c = rgb(38, 38, 40), m = M.Plastic }
local WHEEL_MAG = { c = rgb(168, 171, 177), m = M.Metal, r = 0.15 }
local DISH_DARK = { c = rgb(70, 72, 76), m = M.Metal }
local HUB_GOLD = { c = rgb(212, 172, 70), m = M.Metal, r = 0.1 }
local ENGINE_ALU = { c = rgb(178, 180, 184), m = M.Metal }
local ENGINE_DARK = { c = rgb(55, 57, 62), m = M.Metal }
local CLUTCH_STEEL = { c = rgb(120, 120, 124), m = M.Metal }
local EXH_STEEL = { c = rgb(150, 148, 145), m = M.Metal }
local SILENCER = { c = rgb(192, 192, 197), m = M.Metal, r = 0.15 }
local TIP_DARK = { c = rgb(40, 36, 34), m = M.Metal }
local RAD_CORE = { c = rgb(62, 64, 68), m = M.DiamondPlate }
local RAD_ALU = { c = rgb(185, 188, 192), m = M.Metal }
local SEAT_BLACK = { c = rgb(22, 22, 25), m = M.SmoothPlastic, r = 0.08 }
local PAD_GREY = { c = rgb(45, 45, 50), m = M.Fabric }
local GRIP_BLACK = { c = rgb(24, 24, 26), m = M.Fabric }
local SPOKE_ANOD = { c = rgb(60, 60, 66), m = M.Metal }
local DASH_GREY = { c = rgb(45, 45, 50), m = M.SmoothPlastic }
local SCREEN = { c = rgb(25, 42, 36), m = M.Glass, r = 0.2 }
local LED_RED = { c = rgb(255, 40, 30), m = M.Neon }
local LED_GREEN = { c = rgb(40, 230, 60), m = M.Neon }
local PEDAL_ALU = { c = rgb(190, 192, 196), m = M.Metal }
local TANK_PLASTIC = { c = rgb(230, 230, 222), m = M.SmoothPlastic, t = 0.35 }
local HOSE_CLEAR = { c = rgb(230, 230, 222), m = M.SmoothPlastic, t = 0.3 }
local FUEL_AMBER = { c = rgb(205, 160, 80), m = M.SmoothPlastic, t = 0.2 }
local DISC_IRON = { c = rgb(95, 95, 98), m = M.Metal }
local CALIPER_GOLD = { c = rgb(205, 165, 60), m = M.Metal }
local SPROCKET_ALU = { c = rgb(210, 210, 215), m = M.Metal }
local CHAIN_DARK = { c = rgb(60, 60, 62), m = M.Metal }

local pieces = {}

local function add(
	name: string,
	p,
	size: Vector3,
	offset: CFrame,
	class: string?,
	shape: Enum.PartType?
)
	table.insert(pieces, {
		name = name,
		class = class,
		shape = shape,
		size = size,
		offset = offset,
		color = p.c,
		material = p.m,
		reflectance = p.r,
		transparency = p.t,
	})
end

local function block(name, p, size, offset)
	add(name, p, size, offset)
end

local function wedge(name, p, size, offset)
	add(name, p, size, offset, "WedgePart")
end

-- Cylinder along local X: length, diameter.
local function cyl(name, p, len, dia, offset)
	add(name, p, Vector3.new(len, dia, dia), offset, nil, CYL)
end

local function ball(name, p, dia, pos: Vector3)
	add(name, p, Vector3.new(dia, dia, dia), CFrame.new(pos), nil, BALL)
end

-- Local X runs from a to b.
local function axis(a: Vector3, b: Vector3): CFrame
	local d = b - a
	local h = math.sqrt(d.X * d.X + d.Z * d.Z)
	return CFrame.new((a + b) / 2) * A(0, math.atan2(-d.Z, d.X), 0) * A(0, 0, math.atan2(d.Y, h))
end

local function tube(name, a: Vector3, b: Vector3, dia, p)
	cyl(name, p or FRAME_CHROME, (b - a).Magnitude, dia, axis(a, b))
end

-- Tube through a list of points with a ball at each bend.
local function hose(name, pts, dia, p)
	for i = 1, #pts - 1 do
		tube(name, pts[i], pts[i + 1], dia, p)
		if i > 1 then
			ball(name .. "Bend", p, dia, pts[i])
		end
	end
end

local V = Vector3.new

-- Frame ------------------------------------------------------------------------------------------

for _, s in { -1, 1 } do
	tube("RailFront", V(0.85 * s, 0.22, -3.05), V(0.95 * s, 0.22, -1.5), 0.15)
	tube("RailMid", V(0.95 * s, 0.22, -1.5), V(1.25 * s, 0.22, 0.3), 0.15)
	tube("RailRear", V(1.25 * s, 0.22, 0.3), V(1.55 * s, 0.22, 2.25), 0.15)
	tube("RailTail", V(1.55 * s, 0.22, 2.25), V(1.45 * s, 0.22, 3.0), 0.15)
	tube("KingpinRail", V(1.95 * s, 0.25, -2.55), V(1.45 * s, 0.22, -1.0), 0.15)
	tube("OuterRail", V(1.45 * s, 0.22, -1.0), V(1.25 * s, 0.22, 0.3), 0.15)
	tube("PodBarFront", V(1.2 * s, 0.32, -1.3), V(2.8 * s, 0.32, -1.3), 0.1)
	tube("PodBarRear", V(1.2 * s, 0.32, 0.7), V(2.8 * s, 0.32, 0.7), 0.1)
	tube("NoseMount", V(0.85 * s, 0.22, -3.05), V(0.85 * s, 0.3, -3.95), 0.1)
	tube("BumperMount", V(1.45 * s, 0.22, 3.0), V(1.45 * s, 0.32, 3.4), 0.1)
	for _, n in
		{ V(0.95, 0.22, -1.5), V(1.25, 0.22, 0.3), V(1.55, 0.22, 2.25), V(1.45, 0.22, -1.0) }
	do
		ball("FrameJoint", FRAME_CHROME, 0.16, V(n.X * s, n.Y, n.Z))
	end
end
tube("CrossNose", V(-0.85, 0.22, -3.05), V(0.85, 0.22, -3.05), 0.15)
tube("CrossKingpin", V(-1.95, 0.25, -2.55), V(1.95, 0.25, -2.55), 0.15)
tube("CrossFront", V(-0.95, 0.22, -1.5), V(0.95, 0.22, -1.5), 0.15)
tube("CrossMid", V(-1.25, 0.22, 0.3), V(1.25, 0.22, 0.3), 0.15)
tube("CrossRear", V(-1.45, 0.22, 3.0), V(1.45, 0.22, 3.0), 0.15)
tube("CrossDiagonal", V(-0.95, 0.22, -1.5), V(1.25, 0.22, 0.3), 0.15)
tube("BumperBar", V(-2.5, 0.32, 3.4), V(2.5, 0.32, 3.4), 0.1)

-- Front axle, steering, pedals, tank ------------------------------------------------------------

for _, s in { -1, 1 } do
	block("Spindle", FRAME_CHROME, V(0.14, 0.5, 0.2), CFrame.new(2.0 * s, 0.585, -2.55))
	block("CBracketLow", FRAME_CHROME, V(0.32, 0.06, 0.26), CFrame.new(1.93 * s, 0.3, -2.55))
	block("CBracketHigh", FRAME_CHROME, V(0.32, 0.06, 0.26), CFrame.new(1.93 * s, 0.87, -2.55))
	cyl("Kingpin", BOLT_STEEL, 0.7, 0.08, CFrame.new(2.0 * s, 0.585, -2.55) * CY)
	tube("StubAxle", V(2.0 * s, 0.585, -2.55), V(2.3 * s, 0.585, -2.55), 0.12, BOLT_STEEL)
	cyl("FrontHub", WHEEL_MAG, 0.18, 0.32, CFrame.new(2.12 * s, 0.585, -2.55))
	block(
		"SteeringArm",
		FRAME_CHROME,
		V(0.06, 0.06, 0.45),
		CFrame.new(1.95 * s, 0.5, -2.32) * A(0, s * math.rad(15), 0)
	)
	tube("TieRod", V(0.12 * s, 0.42, -2.45), V(1.88 * s, 0.5, -2.12), 0.07)
	ball("RodEnd", BLACK, 0.11, V(0.12 * s, 0.42, -2.45))
	ball("RodEnd", BLACK, 0.11, V(1.88 * s, 0.5, -2.12))
	tube("PanelBracket", V(0.12 * s, 2.0, -2.2), V(0.06 * s, 1.9, -1.35), 0.05)
	-- Pedals: brake on the left, throttle on the right.
	block(
		"Pedal",
		PEDAL_ALU,
		V(0.32, 0.55, 0.05),
		CFrame.new(0.45 * s, 1.15, -1.8) * A(math.rad(-20), 0, 0)
	)
	tube("PedalArm", V(0.45 * s, 0.3, -1.95), V(0.45 * s, 0.95, -1.82), 0.06)
	block("PedalPivot", MAG_GREY, V(0.14, 0.12, 0.14), CFrame.new(0.45 * s, 0.28, -1.95))
end
block("SteeringPlate", FRAME_CHROME, V(0.5, 0.06, 0.25), CFrame.new(0, 0.42, -2.5))
block("ColumnBearing", BLACK, V(0.2, 0.18, 0.18), CFrame.new(0, 0.38, -2.62))
tube("Column", V(0, 0.4, -2.6), V(0, 2.58, -0.78), 0.11)
cyl(
	"ColumnCollar",
	FRAME_CHROME,
	0.12,
	0.16,
	axis(V(0, 0.4, -2.6), V(0, 2.58, -0.78)).Rotation + V(0, 2.5, -0.85)
)
tube("BrakeRod", V(-0.45, 0.4, -1.9), V(-0.75, 0.6, 1.8), 0.04, BOLT_STEEL)

block("FuelTank", TANK_PLASTIC, V(0.75, 0.55, 1.1), CFrame.new(0, 0.55, -1.45))
block("Fuel", FUEL_AMBER, V(0.68, 0.3, 1.02), CFrame.new(0, 0.45, -1.45))
cyl("FuelCap", BLACK, 0.08, 0.2, CFrame.new(0, 0.86, -1.75) * CY)
tube("FuelLine", V(0.2, 0.6, -0.9), V(1.4, 0.95, 0.65), 0.04, HOSE_CLEAR)
block("FloorTray", BLACK, V(1.9, 0.04, 2.7), CFrame.new(0, 0.15, -1.1))

-- Steering wheel: local Z faces the driver, the top leans forward (column at 50 degrees).

local WF = CFrame.new(0, 2.65, -0.7) * A(math.rad(-40), 0, 0)
for k = 0, 11 do
	block(
		"WheelRim",
		GRIP_BLACK,
		V(0.36, 0.11, 0.11),
		WF * A(0, 0, k * math.pi / 6) * CFrame.new(0, 0.66, 0)
	)
end
for _, s in { -1, 1 } do
	block("WheelGrip", GRIP_BLACK, V(0.12, 0.42, 0.16), WF * CFrame.new(0.66 * s, 0, 0))
end
for _, a in { 180, 100, 260 } do
	block(
		"WheelSpoke",
		SPOKE_ANOD,
		V(0.12, 0.6, 0.04),
		WF * A(0, 0, math.rad(a)) * CFrame.new(0, 0.33, -0.02)
	)
end
cyl("WheelHub", SPOKE_ANOD, 0.14, 0.32, WF * CFrame.new(0, 0, -0.06) * CZ)
block("DashBox", DASH_GREY, V(0.56, 0.32, 0.12), WF * CFrame.new(0, 0.13, 0.07))
block("DashScreen", SCREEN, V(0.42, 0.2, 0.02), WF * CFrame.new(0, 0.14, 0.135))
for i, x in { -0.15, -0.05, 0.05, 0.15 } do
	block(
		"ShiftLed",
		if i <= 2 then LED_GREEN else LED_RED,
		V(0.05, 0.03, 0.02),
		WF * CFrame.new(x, 0.265, 0.135)
	)
end

-- Wheels -----------------------------------------------------------------------------------------

-- Centre (cx is the right-side value), tyre diameter and width, rim diameter, side sign.
local function wheel(cx, cy, cz, dia, width, rimDia, s)
	local k = rimDia / 0.66
	local face = cx + width / 2 -- outer tyre face, right side
	local function at(x)
		return CFrame.new(x * s, cy, cz)
	end
	cyl("Tread", TIRE, width - 0.12, dia, at(cx))
	cyl("Shoulder", TIRE_SIDE, 0.06, dia - 0.1, at(cx - width / 2 + 0.03))
	cyl("Shoulder", TIRE_SIDE, 0.06, dia - 0.1, at(face - 0.03))
	cyl("RimLip", WHEEL_MAG, 0.16, rimDia, at(face - 0.06))
	cyl("RimInner", WHEEL_MAG, 0.06, rimDia, at(cx - width / 2 + 0.01))
	cyl("RimDish", DISH_DARK, 0.02, rimDia - 0.14, at(face + 0.03))
	for i = 0, 5 do
		block(
			"RimSpoke",
			WHEEL_MAG,
			V(0.02, 0.22 * k, 0.08 * k),
			at(face + 0.05) * A(i * math.pi / 3, 0, 0) * CFrame.new(0, 0.15 * k, 0)
		)
	end
	cyl("HubCap", HUB_GOLD, 0.06, 0.18 * k, at(face + 0.07))
	for i = 0, 2 do
		local a = i * 2 * math.pi / 3
		local r = 0.12 * k
		cyl(
			"LugNut",
			BOLT_STEEL,
			0.06,
			0.06,
			CFrame.new((face + 0.08) * s, cy + r * math.cos(a), cz + r * math.sin(a))
		)
	end
	block("Valve", BOLT_STEEL, V(0.04, 0.1, 0.04), CFrame.new((face + 0.02) * s, cy + 0.26 * k, cz))
end

for _, s in { -1, 1 } do
	wheel(2.35, 0.585, -2.55, 1.17, 0.58, 0.66, s)
	wheel(2.75, 0.64, 2.25, 1.28, 0.9, 0.72, s)
end

-- Rear axle, brake and drive ---------------------------------------------------------------------

cyl("RearAxle", AXLE_STEEL, 4.6, 0.23, CFrame.new(0, 0.64, 2.25))
for _, s in { -1, 1 } do
	cyl("RearHub", WHEEL_MAG, 0.25, 0.38, CFrame.new(2.175 * s, 0.64, 2.25))
	block("HubSlit", NOSE_SLOT, V(0.26, 0.04, 0.06), CFrame.new(2.175 * s, 0.83, 2.25))
end
for _, x in { -1.5, 0, 1.5 } do
	block("BearingCarrier", MAG_GREY, V(0.18, 0.55, 0.45), CFrame.new(x, 0.5, 2.25))
	cyl("Bearing", BOLT_STEEL, 0.2, 0.32, CFrame.new(x, 0.64, 2.25))
end
cyl("BrakeDisc", DISC_IRON, 0.08, 0.92, CFrame.new(-0.75, 0.64, 2.25))
cyl("DiscCarrier", MAG_GREY, 0.2, 0.36, CFrame.new(-0.75, 0.64, 2.25))
for i = 0, 3 do
	local a = i * math.pi / 2 + math.pi / 4
	block(
		"DiscSlot",
		NOSE_SLOT,
		V(0.1, 0.04, 0.18),
		CFrame.new(-0.75, 0.64, 2.25) * A(a, 0, 0) * CFrame.new(0, 0.33, 0)
	)
end
block(
	"Caliper",
	CALIPER_GOLD,
	V(0.24, 0.3, 0.36),
	CFrame.new(-0.75, 1.0, 1.95) * A(math.rad(-40), 0, 0)
)
block("CaliperMount", MAG_GREY, V(0.06, 0.4, 0.3), CFrame.new(-0.62, 0.8, 1.9))
cyl("Sprocket", SPROCKET_ALU, 0.04, 0.85, CFrame.new(1.92, 0.64, 2.25))
cyl("SprocketCarrier", MAG_GREY, 0.12, 0.34, CFrame.new(1.88, 0.64, 2.25))
cyl("ClutchDrum", CLUTCH_STEEL, 0.15, 0.4, CFrame.new(1.97, 0.6, 1.45))
tube("ChainTop", V(1.92, 0.8, 1.45), V(1.92, 1.065, 2.25), 0.05, CHAIN_DARK)
tube("ChainBottom", V(1.92, 0.4, 1.45), V(1.92, 0.215, 2.25), 0.05, CHAIN_DARK)
block(
	"ChainGuard",
	BLACK,
	V(0.04, 0.35, 1.0),
	CFrame.new(2.03, 0.98, 1.85) * A(math.rad(-17), 0, 0)
)

-- Engine (right) ---------------------------------------------------------------------------------

block("EngineMount", MAG_GREY, V(0.85, 0.08, 1.1), CFrame.new(1.55, 0.31, 1.35))
for _, z in { 0.95, 1.75 } do
	block("MountClamp", MAG_GREY, V(0.2, 0.14, 0.2), CFrame.new(1.25, 0.24, z))
end
block("Crankcase", ENGINE_ALU, V(0.7, 0.75, 0.9), CFrame.new(1.55, 0.72, 1.35))
wedge("CrankcaseChamfer", ENGINE_ALU, V(0.7, 0.2, 0.25), CFrame.new(1.55, 0.45, 0.78) * FLIP_Z)
cyl("IgnitionCover", ENGINE_DARK, 0.06, 0.45, CFrame.new(1.18, 0.72, 1.35))
local BF = CFrame.new(1.55, 1.38, 1.3) * A(math.rad(-8), 0, 0)
block("Barrel", ENGINE_ALU, V(0.55, 0.6, 0.6), BF)
for _, y in { -0.18, -0.03, 0.12 } do
	block("BarrelRib", ENGINE_DARK, V(0.6, 0.04, 0.64), BF * CFrame.new(0, y, 0))
end
cyl("Head", ENGINE_DARK, 0.2, 0.6, CFrame.new(1.55, 1.78, 1.27) * CY)
cyl("PlugCap", BLACK, 0.16, 0.12, CFrame.new(1.55, 1.95, 1.27) * CY)
tube("HTLead", V(1.55, 2.0, 1.27), V(1.2, 1.6, 0.9), 0.04, BLACK)
cyl("WaterPump", ENGINE_ALU, 0.15, 0.28, CFrame.new(1.92, 0.78, 1.0))
block("Carburettor", ENGINE_DARK, V(0.28, 0.3, 0.35), CFrame.new(1.55, 1.15, 0.78))
cyl("CarbBell", BOLT_STEEL, 0.1, 0.24, CFrame.new(1.55, 1.15, 0.56) * CZ)
tube("IntakeDuct", V(1.55, 0.95, 0.42), V(1.55, 1.12, 0.55), 0.22, BLACK)
tube("ThrottleCable", V(1.4, 1.2, 0.7), V(0.45, 0.35, -1.9), 0.03, BLACK)
block("Airbox", BLACK, V(0.66, 0.7, 1.2), CFrame.new(1.55, 0.72, -0.2))
wedge("AirboxChamfer", BLACK, V(0.66, 0.15, 0.3), CFrame.new(1.55, 1.145, -0.65) * RISE_FRONT)
for _, x in { 1.4, 1.7 } do
	cyl("IntakeTrumpet", BLACK, 0.25, 0.18, CFrame.new(x, 1.2, -0.45) * CY)
end

-- Exhaust: header, expansion chamber, silencer across the back.

tube("Header", V(1.55, 1.4, 1.6), V(1.75, 1.35, 2.05), 0.2, EXH_STEEL)
tube("ChamberCone", V(1.75, 1.35, 2.05), V(1.45, 1.4, 2.6), 0.34, EXH_STEEL)
ball("ChamberBend", EXH_STEEL, 0.34, V(1.75, 1.35, 2.05))
tube("ChamberBelly", V(1.45, 1.4, 2.6), V(0.5, 1.45, 2.85), 0.46, EXH_STEEL)
ball("ChamberBend", EXH_STEEL, 0.46, V(1.45, 1.4, 2.6))
tube("Stinger", V(0.5, 1.45, 2.85), V(-0.15, 1.45, 2.9), 0.3, EXH_STEEL)
ball("ChamberBend", EXH_STEEL, 0.3, V(0.5, 1.45, 2.85))
tube("Silencer", V(-0.15, 1.45, 2.9), V(-1.55, 1.45, 2.9), 0.52, SILENCER)
for _, x in { -0.15, -1.55 } do
	cyl("SilencerCap", ENGINE_DARK, 0.05, 0.55, CFrame.new(x, 1.45, 2.9))
end
for _, x in { -0.5, -1.2 } do
	cyl("SilencerStrap", BLACK, 0.06, 0.56, CFrame.new(x, 1.45, 2.9))
end
tube("Tailpipe", V(-1.55, 1.45, 2.9), V(-1.8, 1.5, 3.15), 0.12, EXH_STEEL)
cyl(
	"TailpipeTip",
	TIP_DARK,
	0.04,
	0.13,
	axis(V(-1.55, 1.45, 2.9), V(-1.8, 1.5, 3.15)).Rotation + V(-1.8, 1.5, 3.15)
)

-- Radiator (left of the seat, facing forward) ----------------------------------------------------

block("RadiatorCore", RAD_CORE, V(1.1, 1.65, 0.16), CFrame.new(-1.8, 1.975, 0.75))
for _, x in { -1.2, -2.4 } do
	block("RadiatorTank", RAD_ALU, V(0.1, 1.75, 0.2), CFrame.new(x, 1.975, 0.75))
end
block("RadiatorTop", RAD_ALU, V(1.3, 0.08, 0.2), CFrame.new(-1.8, 2.84, 0.75))
block("RadiatorBottom", RAD_ALU, V(1.3, 0.08, 0.2), CFrame.new(-1.8, 1.11, 0.75))
cyl("FillerCap", BLACK, 0.08, 0.12, CFrame.new(-1.3, 2.92, 0.75) * CY)
block("Shutter", { c = BLACK.c, m = M.Fabric }, V(1.0, 0.65, 0.03), CFrame.new(-1.8, 2.45, 0.655))
cyl("ShutterRoller", BLACK, 1.1, 0.1, CFrame.new(-1.8, 2.8, 0.62))
tube("RadiatorStrut", V(-1.3, 1.15, 0.75), V(-1.3, 0.22, 0.6), 0.06)
tube("RadiatorStrut", V(-2.3, 1.15, 0.75), V(-1.6, 0.22, 0.9), 0.06)
hose(
	"TopHose",
	{ V(-1.35, 2.5, 0.85), V(-1.3, 2.2, 2.25), V(1.3, 2.0, 2.25), V(1.55, 1.85, 1.4) },
	0.1,
	BLACK
)
hose(
	"BottomHose",
	{ V(-1.35, 1.25, 0.85), V(-1.25, 0.95, 2.0), V(1.3, 0.95, 2.0), V(1.9, 0.78, 1.1) },
	0.1,
	BLACK
)

-- Seat -------------------------------------------------------------------------------------------

block("SeatPan", SEAT_BLACK, V(2.0, 0.12, 1.3), CFrame.new(0, 0.9, 0.95))
block("SeatTub", SEAT_BLACK, V(1.9, 0.6, 1.4), CFrame.new(0, 0.6, 1.0))
wedge("SeatChamfer", SEAT_BLACK, V(1.9, 0.3, 0.25), CFrame.new(0, 0.45, 0.18) * FLIP_Z)
local SB = CFrame.new(0, 1.75, 1.85) * A(math.rad(12), 0, 0)
block("SeatBack", SEAT_BLACK, V(2.3, 2.3, 0.12), SB)
cyl("SeatRoll", SEAT_BLACK, 2.3, 0.14, SB * CFrame.new(0, 1.15, 0))
for _, s in { -1, 1 } do
	block("SeatBolster", SEAT_BLACK, V(0.12, 0.9, 1.4), CFrame.new(1.1 * s, 1.15, 0.95))
	wedge(
		"BolsterTop",
		SEAT_BLACK,
		V(0.12, 0.35, 0.4),
		CFrame.new(1.1 * s, 1.425, 0.25) * RISE_FRONT
	)
	block(
		"SeatWing",
		SEAT_BLACK,
		V(0.12, 1.9, 0.35),
		CFrame.new(1.12 * s, 1.9, 1.75) * A(math.rad(12), 0, 0)
	)
	tube("SeatStay", V(0.75 * s, 2.4, 2.07), V(1.45 * s, 0.22, 2.95), 0.08)
	tube("SeatStay", V(1.12 * s, 1.2, 1.4), V(1.5 * s, 0.22, 2.0), 0.08)
end
block("RibPad", PAD_GREY, V(0.06, 0.5, 0.8), CFrame.new(1.01, 1.35, 1.0))

-- Nose (CIK front fairing) -----------------------------------------------------------------------

block("NoseFront", BODY_RED, V(4.5, 0.5, 0.9), CFrame.new(0, 0.5, -3.75))
wedge("NoseChamfer", BODY_RED, V(4.5, 0.3, 0.45), CFrame.new(0, 0.9, -3.975))
block("NoseTop", BODY_RED, V(4.5, 0.3, 0.45), CFrame.new(0, 0.9, -3.525))
for _, s in { -1, 1 } do
	wedge(
		"NoseCheek",
		BODY_RED,
		V(0.9, 0.3, 0.35),
		CFrame.new(2.425 * s, 0.4, -3.75) * A(0, -s * math.rad(90), 0)
	)
end
block("NoseRear", BODY_RED, V(3.7, 0.55, 1.05), CFrame.new(0, 0.55, -2.775))
wedge("NoseSlope", BODY_RED, V(3.7, 0.4, 1.05), CFrame.new(0, 1.025, -2.775))
wedge("NoseRidge", BODY_RED, V(1.4, 0.2, 1.0), CFrame.new(0, 1.15, -3.0))
block("NoseStripe", PLATE_WHITE, V(4.52, 0.08, 0.06), CFrame.new(0, 0.78, -4.2))
for _, x in { -1.4, -0.6, 0.6, 1.4 } do
	block("NoseSlot", NOSE_SLOT, V(0.5, 0.08, 0.05), CFrame.new(x, 0.5, -4.215))
end
block("NoseSkid", BLACK, V(4.4, 0.06, 0.9), CFrame.new(0, 0.27, -3.75))

-- Front panel (nassau) ---------------------------------------------------------------------------

local PF = CFrame.new(0, 1.55, -2.28) * A(math.rad(10), 0, 0)
block("FrontPanel", BODY_RED, V(1.4, 1.4, 0.08), PF)
for _, s in { -1, 1 } do
	block("PanelEar", BODY_RED, V(0.35, 0.8, 0.08), PF * CFrame.new(0.875 * s, 0.3, 0))
	wedge(
		"PanelTaper",
		BODY_RED,
		V(0.08, 0.6, 0.35),
		PF * CFrame.new(0.875 * s, -0.4, 0) * A(0, -s * math.rad(90), 0) * FLIP_Z
	)
end
cyl("PanelRoll", BODY_RED, 2.1, 0.1, PF * CFrame.new(0, 0.7, 0))
block("PanelPlate", PLATE_WHITE, V(1.2, 0.75, 0.04), PF * CFrame.new(0, 0.05, -0.055))

-- Side pods --------------------------------------------------------------------------------------

for _, s in { -1, 1 } do
	block("PodBase", BODY_RED, V(0.9, 0.5, 2.75), CFrame.new(2.4 * s, 0.55, -0.275))
	block("PodWall", BODY_RED, V(0.2, 1.0, 2.95), CFrame.new(2.95 * s, 0.8, -0.275))
	wedge(
		"PodTop",
		BODY_RED,
		V(2.75, 0.5, 0.9),
		CFrame.new(2.4 * s, 1.05, -0.275) * A(0, s * math.rad(90), 0)
	)
	wedge("PodRampFront", BODY_RED, V(1.1, 0.5, 0.3), CFrame.new(2.5 * s, 0.55, -1.8))
	wedge("PodRampRear", BODY_RED, V(1.1, 0.5, 0.3), CFrame.new(2.5 * s, 0.55, 1.25) * RISE_FRONT)
	cyl("PodRoll", BODY_RED, 2.95, 0.12, CFrame.new(2.95 * s, 1.3, -0.275) * CZ)
	block("PodTrim", BLACK, V(0.05, 0.05, 2.75), CFrame.new(1.96 * s, 0.81, -0.275))
	block("PodPlate", PLATE_WHITE, V(0.06, 0.6, 1.1), CFrame.new(3.06 * s, 0.85, -0.1))
	block("PodStripe", PLATE_WHITE, V(0.06, 0.08, 2.9), CFrame.new(3.06 * s, 1.18, -0.275))
	block("PodLowerStrip", BLACK, V(0.06, 0.1, 2.9), CFrame.new(3.06 * s, 0.36, -0.275))
end

-- Rear bumper ------------------------------------------------------------------------------------

block("BumperFloor", BODY_RED, V(6.0, 0.1, 1.1), CFrame.new(0, 0.3, 3.6))
block("BumperDeck", BODY_RED, V(5.0, 0.3, 0.9), CFrame.new(0, 0.45, 3.5))
wedge("BumperSlope", BODY_RED, V(5.0, 0.65, 0.9), CFrame.new(0, 0.925, 3.5))
block("BumperWall", BODY_RED, V(6.3, 1.0, 0.24), CFrame.new(0, 0.75, 4.07))
cyl("BumperRoll", BODY_RED, 5.0, 0.18, CFrame.new(0, 1.25, 4.07))
for _, s in { -1, 1 } do
	block("BumperCap", BODY_RED, V(0.67, 0.95, 1.17), CFrame.new(2.83 * s, 0.725, 3.635))
	block("BumperCapTop", BODY_RED, V(0.67, 0.25, 0.77), CFrame.new(2.83 * s, 1.325, 3.835))
	wedge("BumperCapRamp", BODY_RED, V(0.67, 0.25, 0.4), CFrame.new(2.83 * s, 1.325, 3.25))
	block("BumperStripe", PLATE_WHITE, V(1.6, 0.08, 0.04), CFrame.new(2.0 * s, 1.05, 4.2))
	block("BumperSlot", NOSE_SLOT, V(0.5, 0.12, 0.05), CFrame.new(1.3 * s, 0.5, 4.205))
end
block("BumperPlate", PLATE_WHITE, V(1.7, 0.65, 0.04), CFrame.new(0, 0.8, 4.2))

return {
	name = "Go-Kart",
	speed = 105,
	turnRate = 3,
	footprint = Vector2.new(6.4, 8.4),
	collision = {
		-- y 1.2-2.2, z 0.5-4.2: seat, engine, radiator, bumper
		{ size = Vector3.new(6.2, 1.0, 3.7), offset = CFrame.new(0, 1.7, 2.35) },
		-- y 1.2-1.9, z -4.2-0.5: nose, panel, pods
		{ size = Vector3.new(5.4, 0.7, 4.7), offset = CFrame.new(0, 1.55, -1.85) },
	},
	seats = { CFrame.new(0, 0.5, 1.0) },
	pieces = pieces,
}
