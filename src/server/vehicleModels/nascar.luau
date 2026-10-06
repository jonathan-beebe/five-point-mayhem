-- NASCAR Stock Car: Next Gen Cup car with a Camaro ZL1 body in an electric-blue #47 livery.
-- Scale: 4.4 studs = 1 m (the car is low; 4.4 lets the seated avatar fit under the roof).

local rgb = Color3.fromRGB
local M = Enum.Material
local CYL = Enum.PartType.Cylinder
local A = CFrame.Angles
local CN = CFrame.new
local V = Vector3.new

local CYLINDER_Z = A(0, math.rad(90), 0)
local CYLINDER_Y = A(0, 0, math.rad(90))

-- Wedge orientations (WedgePart default: right angle at local (ymin, zmax)).
local FLIP_Z = A(0, 0, math.pi) -- right angle at (ymax, zmax)
local FLIP_X = A(math.pi, 0, 0) -- right angle at (ymax, zmin)

-- Looks: color, material, reflectance, transparency.
local function look(
	color: Color3,
	material: Enum.Material?,
	reflectance: number?,
	transparency: number?
)
	return {
		color = color,
		material = material or M.SmoothPlastic,
		reflectance = reflectance,
		transparency = transparency,
	}
end

local BLUE = look(rgb(0, 84, 214), nil, 0.12)
local YELLOW = look(rgb(255, 214, 0), nil, 0.1)
local WHITE = look(rgb(245, 245, 245))
local NUMBER_BLACK = look(rgb(15, 15, 18))
local RED = look(rgb(210, 30, 35))
local BLACK = look(rgb(20, 20, 22))
local CARBON = look(rgb(32, 33, 36))
local BANNER = look(rgb(18, 18, 20))
local GLASS = look(rgb(40, 50, 60), M.Glass, 0.15, 0.45)
local LAMP_SILVER = look(rgb(175, 180, 188), nil, 0.2)
local LAMP_WHITE = look(rgb(235, 240, 245))
local LAMP_DARK = look(rgb(30, 22, 24))
local TAIL_RED = look(rgb(190, 20, 25))
local RAIN_RED = look(rgb(255, 40, 40), M.Neon)
local TIRE = look(rgb(30, 30, 32))
local SIDEWALL = look(rgb(40, 40, 43))
local RIM = look(rgb(45, 47, 52), M.Metal)
local RIM_DARK = look(rgb(22, 23, 26), M.Metal)
local RIM_LIP = look(rgb(150, 152, 158), M.Metal)
local NUT = look(rgb(195, 198, 204), M.Metal)
local CALIPER = look(rgb(200, 30, 30))
local SILVER = look(rgb(185, 188, 195), M.Metal)
local EXHAUST = look(rgb(90, 88, 85), M.Metal)
local CAGE = look(rgb(205, 205, 210), M.Metal)
local SEAT_ALU = look(rgb(150, 152, 158), M.Metal)
local SEAT_PAD = look(rgb(25, 25, 28), M.Fabric)
local FLOOR = look(rgb(55, 56, 60), M.DiamondPlate)
local SCREEN = look(rgb(20, 45, 55), M.Glass, nil, 0.1)
local NET = look(rgb(12, 12, 14), M.Fabric)
local FLAP_GREY = look(rgb(60, 62, 68))

local pieces = {}

local function add(
	name: string,
	class: string?,
	shape: Enum.PartType?,
	size: Vector3,
	offset: CFrame,
	style
)
	table.insert(pieces, {
		name = name,
		class = class,
		shape = shape,
		size = size,
		offset = offset,
		color = style.color,
		material = style.material,
		reflectance = style.reflectance,
		transparency = style.transparency,
	})
end

local function block(name: string, size: Vector3, offset: CFrame, style)
	add(name, nil, nil, size, offset, style)
end

local function wedge(name: string, size: Vector3, offset: CFrame, style)
	add(name, "WedgePart", nil, size, offset, style)
end

local function cylinder(name: string, size: Vector3, offset: CFrame, style)
	add(name, nil, CYL, size, offset, style)
end

-- Shared frames.
local WINDSHIELD = CN(0, 4.5, -1.9) * A(math.rad(-29.2), 0, 0)
local REAR_WINDOW = CN(0, 4.62, 5.6) * A(math.rad(21.8), 0, 0)
local HOOD = CN(0, 3.0, -6.95) * A(math.rad(-6.8), 0, 0)
local P_R = CN(3.4, 4.5, 0) * A(0, 0, math.rad(27.8)) -- right side glass plane (tumblehome)
local P_L = CN(-3.4, 4.5, 0) * A(0, 0, -math.rad(27.8)) -- left side glass plane
local SIDE = { -1, 1 }
local AXLES = { -6.15, 6.15 }

------------------------------------------------------------------------------------------------
-- Body
------------------------------------------------------------------------------------------------

block("FrontCore", V(5.4, 2.0, 7.2), CN(0, 1.55, -7.0), BLUE)
block("RearCore", V(5.4, 2.9, 7.0), CN(0, 2.2, 7.1), BLUE)
block("Splitter", V(8.6, 0.08, 1.6), CN(0, 0.40, -10.2), CARBON)
block("FrontFascia", V(7.1, 1.3, 0.6), CN(0, 1.15, -10.45), BLUE)
wedge("Nose", V(7.1, 0.9, 0.45), CN(0, 2.25, -10.5), BLUE)
block("Hood", V(5.4, 0.2, 6.8), HOOD, BLUE)
block("CowlVent", V(5.6, 0.08, 0.3), CN(0, 3.57, -3.7), BLACK)
block("Roof", V(5.8, 0.18, 3.9), CN(0, 5.5, 1.7), BLUE)
block("Decklid", V(7.6, 0.15, 3.0), CN(0, 3.78, 9.1), BLUE)
block("RearFascia", V(8.4, 2.95, 0.3), CN(0, 2.35, 10.6), BLUE)
block("RearValance", V(8.0, 0.45, 0.25), CN(0, 0.75, 10.72), CARBON)
block("DiffuserPlate", V(8.0, 0.08, 2.2), CN(0, 0.72, 9.8) * A(math.rad(-12), 0, 0), CARBON)
for _, x in { -3, -1.8, -0.6, 0.6, 1.8, 3 } do
	block("DiffuserStrake", V(0.06, 0.5, 1.8), CN(x, 0.8, 9.9), CARBON)
end
block("SpoilerBlade", V(8.0, 0.65, 0.06), CN(0, 4.15, 10.5) * A(math.rad(20), 0, 0), CARBON)
for _, x in { -2.5, 0, 2.5 } do
	block("SpoilerSupport", V(0.06, 0.4, 0.3), CN(x, 4.0, 10.4), CARBON)
end

for _, s in SIDE do
	wedge(
		"CornerChamfer",
		V(2.05, 0.8, 0.8),
		CN(s * 3.95, 1.525, -10.35) * A(0, 0, -s * math.pi / 2),
		BLUE
	)
	block("FrontClipSide", V(0.3, 2.35, 1.95), CN(s * 4.2, 1.72, -8.975), BLUE)
	block("Door", V(0.3, 2.95, 8.6), CN(s * 4.15, 2.02, 0), BLUE)
	block("RearQuarter", V(0.3, 3.2, 2.7), CN(s * 4.2, 2.22, 9.35), BLUE)
	block("RearQuarterUpper", V(0.3, 0.55, 3.8), CN(s * 4.25, 3.58, 6.15), BLUE)
	wedge("BeltlineRise", V(0.3, 0.35, 4.0), CN(s * 4.15, 3.67, 5.6), BLUE)
	block("FenderCrown", V(1.65, 0.35, 4.6), CN(s * 3.55, 3.375, -5.9), BLUE)
	wedge("FenderNose", V(1.65, 1.0, 1.75), CN(s * 3.55, 3.05, -9.075), BLUE)
	block("NoseFill", V(0.9, 0.3, 0.4), CN(s * 3.15, 2.42, -10.1), BLUE)
	block("ArchFrontFill", V(0.3, 0.4, 0.3), CN(s * 4.2, 3.05, -8.1), BLUE)
	block("InnerFenderWall", V(0.1, 0.55, 6.7), CN(s * 2.72, 3.25, -6.95), BLUE)
	block("RearFenderTop", V(0.9, 0.2, 7.0), CN(s * 3.95, 3.74, 7.1), BLUE)
	block("RockerSkirt", V(0.25, 0.45, 8.4), CN(s * 4.3, 0.78, 0), BLACK)
	block("BeltlineSill", V(0.6, 0.06, 7.2), CN(s * 4.0, 3.52, 0), BLACK)

	-- C-pillar sail in the tumblehome plane, tall at the roof and tapering down the fastback.
	local sail = CN(s * 3.55, 4.65, 5.6) * A(0, 0, s * math.rad(27.8))
	wedge("SailPanel", V(0.12, 1.6, 4.0), sail * A(0, math.pi, 0), BLUE)

	-- A-pillar along the windshield edge, following the tumblehome.
	local bottom = V(s * 3.85, 3.55, -3.6)
	local top = V(s * 2.95, 5.45, -0.2)
	local run = top - bottom
	local yaw = math.atan2(-run.X, -run.Z)
	local pitch = math.atan2(run.Y, math.sqrt(run.X * run.X + run.Z * run.Z))
	local pillar = CFrame.new((bottom + top) / 2) * A(0, yaw, 0) * A(pitch, 0, 0)
	block("APillar", V(0.3, 0.22, run.Magnitude), pillar, BLUE)

	for _, axle in AXLES do
		block("ArchLip", V(0.12, 0.18, 2.4), CN(s * 4.36, 3.3, axle), BLUE)
		wedge("ArchShoulder", V(0.3, 1.0, 0.8), CN(s * 4.2, 2.8, axle - 1.45) * FLIP_X, BLUE)
		wedge("ArchShoulder", V(0.3, 1.0, 0.8), CN(s * 4.2, 2.8, axle + 1.45) * FLIP_Z, BLUE)
		block("WheelWell", V(0.1, 3.2, 3.8), CN(s * 2.75, 1.9, axle), BLACK)
	end
end

------------------------------------------------------------------------------------------------
-- Glass
------------------------------------------------------------------------------------------------

block("Windshield", V(5.8, 0.08, 3.95), WINDSHIELD, GLASS)
block("WindshieldBanner", V(5.6, 0.03, 0.55), WINDSHIELD * CN(0, 0.06, 1.6), BANNER)
block("RearWindow", V(5.8, 0.08, 4.3), REAR_WINDOW, GLASS)
for _, s in SIDE do
	-- Triangular glass that widens the windshield toward its base (x 2.9 -> 3.85).
	wedge(
		"WindshieldCorner",
		V(0.08, 0.95, 3.95),
		WINDSHIELD * CN(s * 3.375, 0, 0) * A(math.pi, 0, 0) * A(0, 0, -s * math.pi / 2),
		GLASS
	)
	-- Painted buttress that widens the fastback toward the deck (x 2.9 -> 3.9).
	wedge(
		"RearButtress",
		V(0.08, 1.0, 4.3),
		REAR_WINDOW * CN(s * 3.4, 0, 0) * A(0, 0, -s * math.pi / 2),
		BLUE
	)
end
block("RightWindow", V(0.06, 2.0, 3.8), P_R * CN(0, 0, 1.6), GLASS)
wedge("RightQuarterGlass", V(0.06, 1.9, 3.2), P_R * CN(0, 0, -2.0), GLASS)
wedge("LeftQuarterGlass", V(0.06, 1.9, 3.2), P_L * CN(0, 0, -2.0), GLASS)

------------------------------------------------------------------------------------------------
-- Lights
------------------------------------------------------------------------------------------------

for _, s in SIDE do
	local lamp = CN(s * 2.6, 2.3, -10.5) * A(math.rad(26.6), 0, 0)
	block("Headlamp", V(1.5, 0.35, 0.04), lamp, LAMP_SILVER)
	block("HeadlampLed", V(1.3, 0.08, 0.03), lamp * CN(0, 0.08, -0.035), LAMP_WHITE)
	block("TailLampSurround", V(1.9, 0.55, 0.04), CN(s * 2.7, 3.3, 10.77), LAMP_DARK)
	block("TailLamp", V(0.8, 0.3, 0.03), CN(s * 2.2, 3.3, 10.80), TAIL_RED)
	block("TailLamp", V(0.8, 0.3, 0.03), CN(s * 3.15, 3.3, 10.80), TAIL_RED)
end
block("RainLight", V(0.5, 0.2, 0.1), CN(0, 1.15, 10.8), RAIN_RED)

------------------------------------------------------------------------------------------------
-- Wheels: slick tire, dark forged 10-spoke rim, centre-lock nut. Layers stack outward.
------------------------------------------------------------------------------------------------

for _, s in SIDE do
	for _, z in AXLES do
		cylinder("Tire", V(1.40, 3.1, 3.1), CN(s * 3.5, 1.55, z), TIRE)
		cylinder("Sidewall", V(0.04, 2.9, 2.9), CN(s * 4.215, 1.55, z), SIDEWALL)
		cylinder("RimLip", V(0.03, 2.1, 2.1), CN(s * 4.245, 1.55, z), RIM_LIP)
		cylinder("RimBackdrop", V(0.03, 2.0, 2.0), CN(s * 4.26, 1.55, z), RIM_DARK)
		local inward = if z < 0 then 1 else -1
		block("Caliper", V(0.02, 0.5, 0.9), CN(s * 4.275, 2.1, z + 0.35 * inward), CALIPER)
		for k = 0, 9 do
			local spoke = CN(s * 4.29, 1.55, z) * A(math.rad(36 * k), 0, 0) * CN(0, 0.55, 0)
			block("Spoke", V(0.03, 0.85, 0.16), spoke, RIM)
		end
		cylinder("Hub", V(0.05, 0.5, 0.5), CN(s * 4.31, 1.55, z), RIM)
		cylinder("CentreLockNut", V(0.10, 0.32, 0.32), CN(s * 4.36, 1.55, z), NUT)
	end
end

------------------------------------------------------------------------------------------------
-- Interior
------------------------------------------------------------------------------------------------

block("FloorPan", V(5.4, 0.2, 7.2), CN(0, 0.65, 0), FLOOR)
block("SeatBase", V(1.9, 0.35, 1.9), CN(-1.2, 0.95, 1.05), SEAT_ALU)
block("SeatBack", V(2.0, 3.2, 0.3), CN(-1.2, 2.7, 1.85), SEAT_ALU)
block("SeatPad", V(1.6, 2.6, 0.06), CN(-1.2, 2.6, 1.68), SEAT_PAD)
block("HeadWing", V(0.2, 1.0, 0.9), CN(-2.3, 4.1, 1.4), SEAT_PAD)
block("HeadWing", V(0.2, 1.0, 0.9), CN(-0.1, 4.1, 1.4), SEAT_PAD)

local SW = CN(-1.2, 3.15, -0.45) * A(math.rad(-20), 0, 0)
block("WheelRimTop", V(1.0, 0.12, 0.1), SW * CN(0, 0.6, 0), BLACK)
block("WheelRimBottom", V(1.0, 0.12, 0.1), SW * CN(0, -0.6, 0), BLACK)
block("WheelRimLeft", V(0.12, 1.0, 0.1), SW * CN(-0.6, 0, 0), BLACK)
block("WheelRimRight", V(0.12, 1.0, 0.1), SW * CN(0.6, 0, 0), BLACK)
cylinder("QuickRelease", V(0.15, 0.35, 0.35), SW * CYLINDER_Z, RIM)
cylinder("SteeringColumn", V(1.2, 0.12, 0.12), SW * CN(0, 0, -0.65) * CYLINDER_Z, CAGE)
block("Dash", V(3.0, 0.6, 0.5), CN(-0.8, 3.2, -1.6), BLACK)
block("DashScreen", V(1.2, 0.4, 0.03), CN(-1.2, 3.25, -1.34), SCREEN)

for _, s in SIDE do
	cylinder("MainHoopUpright", V(4.3, 0.18, 0.18), CN(s * 2.6, 3.15, 2.4) * CYLINDER_Y, CAGE)
	cylinder("HaloBar", V(2.6, 0.18, 0.18), CN(s * 2.6, 5.25, 1.1) * CYLINDER_Z, CAGE)
end
cylinder("MainHoopTop", V(5.2, 0.18, 0.18), CN(0, 5.25, 2.4), CAGE)
cylinder("DashBar", V(5.4, 0.18, 0.18), CN(0, 3.45, -2.0), CAGE)
block("EarnhardtBar", V(0.15, 0.15, 3.8), CN(0, 4.35, -1.95) * A(math.rad(-29.2), 0, 0), CAGE)
for _, y in { 1.6, 2.3, 3.0 } do
	cylinder("DoorBar", V(5.0, 0.16, 0.16), CN(-2.75, y, 0.5) * CYLINDER_Z, CAGE)
end

-- Window net on the driver's side, just inboard of the left glass plane.
local N = P_L * CN(0.1, -0.05, 1.2)
block("NetRod", V(0.06, 0.08, 3.4), N * CN(0, 0.75, 0), NET)
for _, z in { -1.2, -0.4, 0.4, 1.2 } do
	block("NetStrap", V(0.04, 1.5, 0.08), N * CN(0, 0, z), NET)
end
for _, y in { -0.5, 0, 0.5 } do
	block("NetStrap", V(0.04, 0.08, 3.2), N * CN(0, y, 0), NET)
end

------------------------------------------------------------------------------------------------
-- Livery and details
------------------------------------------------------------------------------------------------

-- 7-segment digit layout in (up, right, horizontal) for height h, width w, stroke t.
local function segments(h: number, w: number, t: number)
	return {
		a = { h / 2 - t / 2, 0, true },
		b = { h / 4, w / 2, false },
		c = { -h / 4, w / 2, false },
		d = { -h / 2 + t / 2, 0, true },
		e = { -h / 4, -w / 2, false },
		f = { h / 4, -w / 2, false },
		g = { 0, 0, true },
	}
end
local FOUR = { "b", "c", "f", "g" }
local SEVEN = { "a", "b", "c" }

local DOOR_SEGMENTS = segments(1.4, 0.8, 0.2)
local function digit(names, faceX: number, centreY: number, centreZ: number, rightSign: number)
	for _, key in names do
		local seg = DOOR_SEGMENTS[key]
		local size = if seg[3] then V(0.03, 0.2, 0.6) else V(0.03, 0.62, 0.2)
		block(
			"DoorDigit",
			size,
			CN(faceX, centreY + seg[1], centreZ + seg[2] * rightSign),
			NUMBER_BLACK
		)
	end
end

-- Roof digits read from the right side: up = -X, reader's right = -Z.
local ROOF_SEGMENTS = segments(2.2, 1.05, 0.25)
local function roofDigit(names, centreZ: number)
	for _, key in names do
		local seg = ROOF_SEGMENTS[key]
		local size = if seg[3] then V(0.25, 0.03, 0.8) else V(1.0, 0.03, 0.25)
		block("RoofDigit", size, CN(-seg[1], 5.63, centreZ - seg[2]), NUMBER_BLACK)
	end
end

for _, s in SIDE do
	cylinder("DoorRoundel", V(0.06, 2.5, 2.5), CN(s * 4.33, 2.05, 0.3), WHITE)
	-- Reader's right is +Z on the left door and -Z on the right door.
	local right = -s
	digit(FOUR, s * 4.375, 2.05, 0.3 - 0.45 * right, right)
	digit(SEVEN, s * 4.375, 2.05, 0.3 + 0.45 * right, right)

	for i, style in { WHITE, YELLOW, RED, BLACK, WHITE } do
		block("ContingencyDecal", V(0.03, 0.18, 0.7), CN(s * 4.33, 1.25 + 0.25 * i, -3.4), style)
	end
	block("QuarterSponsor", V(0.03, 1.2, 2.0), CN(s * 4.37, 2.3, 9.4), YELLOW)
	block("DoorStripe", V(0.03, 0.45, 7.0), CN(s * 4.315, 1.27, 0.7), YELLOW)
	block("FenderStripe", V(0.03, 0.3, 1.8), CN(s * 4.37, 2.5, -9.0), YELLOW)
	for _, z in { 3.35, 3.8 } do
		cylinder("ExhaustTip", V(0.25, 0.35, 0.35), CN(s * 4.4, 0.85, z), EXHAUST)
	end
	block("RoofRail", V(0.06, 0.12, 3.6), CN(s * 2.6, 5.65, 1.7), BLUE)

	-- Roof flaps in a V opening forward.
	local flap = CN(s * 0.75, 5.605, 2.95) * A(0, -s * math.rad(25), 0)
	block("RoofFlap", V(1.5, 0.03, 0.5), flap, FLAP_GREY)
	block("RoofFlapSeam", V(1.5, 0.035, 0.05), flap * CN(0, 0.01, -0.22), BLACK)

	-- Hood louvers, pins and seams in the hood frame.
	block("LouverPlate", V(1.3, 0.03, 1.6), HOOD * CN(s * 1.6, 0.115, 1.4), BLACK)
	for _, dz in { -0.6, -0.2, 0.2, 0.6 } do
		block("LouverSlat", V(1.2, 0.04, 0.12), HOOD * CN(s * 1.6, 0.14, 1.4 + dz), BLUE)
	end
	for _, z in { -3.0, 3.0 } do
		cylinder("HoodPin", V(0.04, 0.15, 0.15), HOOD * CN(s * 1.9, 0.12, z) * CYLINDER_Y, SILVER)
	end
	block("HoodSeam", V(0.04, 0.03, 6.7), HOOD * CN(s * 2.66, 0.11, 0), BLACK)
	cylinder("DeckPin", V(0.04, 0.15, 0.15), CN(s * 3.0, 3.87, 10.2) * CYLINDER_Y, SILVER)
end

block("RoofNumberPanel", V(4.6, 0.03, 2.6), CN(0, 5.605, 1.25), WHITE)
roofDigit(FOUR, 1.9)
roofDigit(SEVEN, 0.6)
block("RoofCamera", V(0.4, 0.25, 0.5), CN(1.75, 5.72, 0.15), BLACK)
cylinder("Antenna", V(0.6, 0.04, 0.04), CN(0.9, 5.9, 3.5) * CYLINDER_Y, BLACK)
block("HoodSponsor", V(2.4, 0.03, 2.6), HOOD * CN(0, 0.115, -1.2), YELLOW)
block("LowerGrille", V(5.2, 0.5, 0.06), CN(0, 1.05, -10.77), BLACK)
block("GrilleSlat", V(5.0, 0.05, 0.04), CN(0, 0.95, -10.8), CARBON)
block("GrilleSlat", V(5.0, 0.05, 0.04), CN(0, 1.15, -10.8), CARBON)
block("UpperGrille", V(3.6, 0.2, 0.05), CN(0, 1.62, -10.77), BLACK)
cylinder("FuelFiller", V(0.04, 0.45, 0.45), CN(-4.37, 3.3, 9.2), SILVER)
block("DeckSponsor", V(5.0, 0.03, 1.8), CN(0, 3.87, 9.0), YELLOW)
block("RearBumperSponsor", V(3.2, 0.7, 0.03), CN(0, 2.3, 10.765), YELLOW)
block("RearBumperSeam", V(8.2, 0.04, 0.03), CN(0, 1.5, 10.765), BLACK)
block("DecklidSeam", V(7.6, 0.03, 0.04), CN(0, 3.865, 7.65), BLACK)

return {
	name = "NASCAR Stock Car",
	-- Real: 320 km/h, 0-100 km/h in 3.4 s, brakes 1.3 g, coasts 0.25 g (VehicleDefaults maps them).
	speed = 98,
	acceleration = 14.9,
	braking = 20,
	coasting = 6.7,
	turnRate = 2.2,
	footprint = Vector2.new(8.4, 21.0),
	collision = {
		{ size = V(8.6, 2.4, 21.4), offset = CN(0, 2.4, 0) },
		{ size = V(5.8, 1.8, 7.6), offset = CN(0, 4.5, 1.9) },
	},
	seats = { CN(-1.2, 0.65, 1.0) },
	pieces = pieces,
}
