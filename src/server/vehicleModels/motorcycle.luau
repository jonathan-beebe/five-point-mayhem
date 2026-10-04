-- Ducati Panigale V4: 2020+ V4 S superbike in Ducati red with winglets, gold Ohlins and a single-sided swingarm.

-- Scale: 4 studs = 1 m. Front axle (0, 1.20, -3.00), rear axle (0, 1.345, 2.88).

local rgb = Color3.fromRGB
local M = Enum.Material
local A = CFrame.Angles
local CYL = Enum.PartType.Cylinder
local CYLINDER_Z = A(0, math.rad(90), 0) -- local +X -> world -Z
local CYLINDER_Y = A(0, 0, math.rad(90))

-- Wedge orientations (WedgePart default: right angle at local (ymin, zmax), rises toward +Z).
local RISE_FRONT = A(0, math.pi, 0) -- rises toward -Z
local FLIP_Z = A(0, 0, math.pi) -- right angle at (ymax, zmax)
local FLIP_X = A(math.pi, 0, 0) -- right angle at (ymax, zmin)
local FLANK_L = A(0, 0, math.pi / 2) -- vertical, flares toward -X as Z increases; size (h, flare, len)
local FLANK_R = A(0, 0, -math.pi / 2) -- vertical, flares toward +X as Z increases
local SIDE_L = A(0, math.pi / 2, 0) -- length along Z, solid side facing +X
local SIDE_R = A(0, -math.pi / 2, 0) -- length along Z, solid side facing -X

-- Fork frame: origin at the front axle, local +Y up the fork axis (raked 24.5 degrees).
local F = CFrame.new(0, 1.20, -3.00) * A(math.rad(24.5), 0, 0)
local FRONT_AXLE = CFrame.new(0, 1.20, -3.00)
local REAR_AXLE = CFrame.new(0, 1.345, 2.88)

local RED = rgb(200, 16, 26)
local RED_SHADOW = rgb(150, 10, 18)
local WHITE = rgb(240, 240, 236)
local MATTE_BLACK = rgb(22, 22, 24)
local FRAME_BLACK = rgb(30, 30, 33)
local BORE_BLACK = rgb(10, 10, 10)
local TIRE = rgb(24, 24, 26)
local WHEEL = rgb(58, 58, 64)
local OHLINS_GOLD = rgb(214, 170, 52)
local GOLD_TIN = rgb(190, 150, 70)
local DISC_STEEL = rgb(170, 170, 175)
local CARRIER = rgb(120, 120, 126)
local CALIPER = rgb(80, 82, 86)
local ENGINE = rgb(58, 58, 62)
local SWINGARM = rgb(150, 152, 156)
local POCKET = rgb(90, 92, 96)
local TITANIUM = rgb(165, 160, 150)
local CHAIN = rgb(50, 50, 52)
local SPROCKET = rgb(90, 90, 95)
local SEAT = rgb(36, 36, 40)
local GLASS_SMOKE = rgb(45, 45, 52)
local HEADLIGHT = rgb(255, 244, 220)
local DRL = rgb(235, 245, 255)
local TAIL = rgb(255, 25, 25)
local INDICATOR = rgb(255, 150, 20)
local PLATE = rgb(225, 225, 220)
local RESERVOIR = rgb(60, 60, 64)
local DASH_FACE = rgb(30, 42, 60)
local REV_BAR = rgb(255, 60, 40)
local MIRROR_GLASS = rgb(150, 160, 170)
local COOLER = rgb(45, 45, 48)
local NUT_RED = rgb(200, 30, 30)

local pieces = {}

local function v(x, y, z)
	return Vector3.new(x, y, z)
end

local function add(name, size, offset, color, material, extra)
	local spec = {
		name = name,
		size = size,
		offset = offset,
		color = color,
		material = material or M.SmoothPlastic,
	}
	if extra then
		for k, value in extra do
			spec[k] = value
		end
	end
	table.insert(pieces, spec)
	return spec
end

local function cyl(name, size, offset, color, material, extra)
	local spec = add(name, size, offset, color, material, extra)
	spec.shape = CYL
	return spec
end

local function wedge(name, size, offset, color, material, extra)
	local spec = add(name, size, offset, color, material, extra)
	spec.class = "WedgePart"
	return spec
end

local function paint(name, size, offset)
	return add(name, size, offset, RED, M.SmoothPlastic, { reflectance = 0.12 })
end

local function paintWedge(name, size, offset)
	return wedge(name, size, offset, RED, M.SmoothPlastic, { reflectance = 0.12 })
end

local function neon(name, size, offset, color)
	return add(name, size, offset, color, M.Neon)
end

---------------------------------------------------------------------------------------------------
-- Wheels

-- Rim layers stepped outboard from the tire face; spokes in three Y pairs.
local function rimFace(label, axle, x0, spokeTurn)
	for _, s in { -1, 1 } do
		cyl(
			label .. "RimLip",
			v(0.02, 1.74, 1.74),
			axle * CFrame.new(s * x0, 0, 0),
			WHEEL,
			M.Metal,
			{
				reflectance = 0.1,
			}
		)
		cyl(
			label .. "RimStripe",
			v(0.02, 1.66, 1.66),
			axle * CFrame.new(s * (x0 + 0.025), 0, 0),
			RED
		)
		cyl(
			label .. "Recess",
			v(0.02, 1.58, 1.58),
			axle * CFrame.new(s * (x0 + 0.05), 0, 0),
			BORE_BLACK
		)
		for _, base in { 0, 120, 240 } do
			for _, split in { -10, 10 } do
				add(
					label .. "Spoke",
					v(0.05, 0.62, 0.12),
					axle
						* A(math.rad(base + split + spokeTurn), 0, 0)
						* CFrame.new(s * (x0 + 0.075), 0.49, 0),
					WHEEL,
					M.Metal,
					{ reflectance = 0.1 }
				)
			end
		end
	end
end

-- Front wheel
cyl("FrontTire", v(0.48, 2.40, 2.40), FRONT_AXLE, TIRE)
rimFace("Front", FRONT_AXLE, 0.26, 0)
for _, s in { -1, 1 } do
	cyl("FrontHub", v(0.06, 0.36, 0.36), FRONT_AXLE * CFrame.new(s * 0.35, 0, 0), WHEEL, M.Metal)
	cyl(
		"FrontDisc",
		v(0.04, 1.32, 1.32),
		FRONT_AXLE * CFrame.new(s * 0.40, 0, 0),
		DISC_STEEL,
		M.Metal,
		{
			reflectance = 0.2,
		}
	)
	cyl(
		"FrontDiscCarrier",
		v(0.02, 0.70, 0.70),
		FRONT_AXLE * CFrame.new(s * 0.43, 0, 0),
		CARRIER,
		M.Metal
	)
	cyl(
		"FrontAxleNut",
		v(0.06, 0.20, 0.20),
		FRONT_AXLE * CFrame.new(s * 0.66, 0, 0),
		DISC_STEEL,
		M.Metal
	)
	add(
		"FrontCaliper",
		v(0.18, 0.50, 0.26),
		FRONT_AXLE * CFrame.new(s * 0.44, 0.25, 0.45),
		CALIPER,
		M.Metal
	)
	add(
		"FrontCaliperMount",
		v(0.10, 0.30, 0.10),
		FRONT_AXLE * CFrame.new(s * 0.52, 0.35, 0.20),
		CALIPER,
		M.Metal
	)
end

-- Rear wheel
cyl("RearTire", v(0.80, 2.69, 2.69), REAR_AXLE, TIRE)
rimFace("Rear", REAR_AXLE, 0.41, 60)
cyl("RearCenterNut", v(0.08, 0.40, 0.40), REAR_AXLE * CFrame.new(0.52, 0, 0), DISC_STEEL, M.Metal, {
	reflectance = 0.2,
})
cyl("RearNutHex", v(0.04, 0.24, 0.24), REAR_AXLE * CFrame.new(0.575, 0, 0), NUT_RED, M.Metal)
cyl("RearDisc", v(0.04, 0.98, 0.98), REAR_AXLE * CFrame.new(-0.53, 0, 0), DISC_STEEL, M.Metal, {
	reflectance = 0.2,
})
cyl("RearSprocket", v(0.04, 0.86, 0.86), REAR_AXLE * CFrame.new(-0.58, 0, 0), SPROCKET, M.Metal)
cyl("RearHubCarrier", v(0.14, 0.75, 0.75), REAR_AXLE * CFrame.new(-0.70, 0, 0), SWINGARM, M.Metal)
add("RearCaliper", v(0.10, 0.25, 0.40), CFrame.new(-0.53, 0.95, 2.62), CALIPER, M.Metal)

---------------------------------------------------------------------------------------------------
-- Front suspension and controls

for _, s in { -1, 1 } do
	add("ForkFoot", v(0.22, 0.45, 0.32), F * CFrame.new(s * 0.58, 0.05, 0.05), FRAME_BLACK, M.Metal)
	cyl(
		"ForkInner",
		v(1.40, 0.18, 0.18),
		F * CFrame.new(s * 0.58, 0.80, 0) * CYLINDER_Y,
		GOLD_TIN,
		M.Metal
	)
	cyl(
		"ForkOuter",
		v(1.60, 0.24, 0.24),
		F * CFrame.new(s * 0.58, 2.20, 0) * CYLINDER_Y,
		OHLINS_GOLD,
		M.Metal,
		{
			reflectance = 0.25,
		}
	)
	cyl(
		"ForkCap",
		v(0.10, 0.20, 0.20),
		F * CFrame.new(s * 0.58, 3.05, 0) * CYLINDER_Y,
		OHLINS_GOLD,
		M.Metal
	)
end
add("BottomClamp", v(1.45, 0.14, 0.40), F * CFrame.new(0, 2.25, 0.10), FRAME_BLACK, M.Metal)
add("TopClamp", v(1.45, 0.10, 0.42), F * CFrame.new(0, 2.85, 0.05), FRAME_BLACK, M.Metal)

for _, s in { -1, 1 } do
	local yaw = A(0, -s * math.rad(15), 0)
	add(
		"ClipOn",
		v(0.85, 0.11, 0.11),
		CFrame.new(s * 1.00, 3.66, -1.70) * yaw,
		FRAME_BLACK,
		M.Metal
	)
	cyl("Grip", v(0.45, 0.16, 0.16), CFrame.new(s * 1.33, 3.66, -1.62) * yaw, MATTE_BLACK)
	cyl("BarEnd", v(0.06, 0.14, 0.14), CFrame.new(s * 1.56, 3.66, -1.55) * yaw, DISC_STEEL, M.Metal)
	add("Lever", v(0.55, 0.04, 0.07), CFrame.new(s * 1.30, 3.70, -1.88) * yaw, DISC_STEEL, M.Metal)
	cyl("Reservoir", v(0.22, 0.14, 0.14), CFrame.new(s * 0.70, 3.92, -1.75) * CYLINDER_Y, RESERVOIR)
end
cyl("SteeringDamper", v(0.80, 0.08, 0.08), CFrame.new(0, 3.70, -1.55), OHLINS_GOLD, M.Metal)

---------------------------------------------------------------------------------------------------
-- Nose

paint("NoseCore", v(1.40, 0.70, 0.80), CFrame.new(0, 2.85, -3.05))
paintWedge("NoseTop", v(1.40, 0.35, 0.80), CFrame.new(0, 3.375, -3.05))
paintWedge("NoseFlankL", v(0.70, 0.35, 0.80), CFrame.new(-0.875, 2.85, -3.05) * FLANK_L)
paintWedge("NoseFlankR", v(0.70, 0.35, 0.80), CFrame.new(0.875, 2.85, -3.05) * FLANK_R)
paintWedge("Chin", v(1.90, 0.25, 0.60), CFrame.new(0, 2.625, -2.35) * FLIP_Z)

-- Upper fairing between nose and tank
for _, s in { -1, 1 } do
	paint("UpperSide", v(0.12, 1.00, 1.90), CFrame.new(s * 1.00, 3.00, -1.75))
	paintWedge(
		"UpperBevel",
		v(1.90, 0.30, 0.25),
		CFrame.new(s * 0.88, 3.55, -1.75) * (s > 0 and SIDE_R or SIDE_L)
	)
end
paint("UpperDeck", v(1.90, 0.10, 1.10), CFrame.new(0, 3.50, -2.10))

-- Side fairing
for _, s in { -1, 1 } do
	paint("SideMid", v(0.12, 1.00, 2.00), CFrame.new(s * 1.05, 2.00, -1.00))
	paintWedge("SideFrontDiag", v(0.12, 1.00, 0.70), CFrame.new(s * 1.05, 2.00, -2.35) * FLIP_Z)
	paint("SideLower", v(0.12, 0.90, 1.20), CFrame.new(s * 0.95, 1.05, -1.00))
	paintWedge("SideLowerRear", v(0.12, 0.90, 0.40), CFrame.new(s * 0.95, 1.05, -0.20) * FLIP_X)
	paintWedge("SideLowerDiag", v(0.12, 0.90, 0.40), CFrame.new(s * 0.95, 1.05, -1.80) * FLIP_Z)
	add("SideRearEdge", v(0.12, 1.10, 0.12), CFrame.new(s * 1.00, 2.05, 0.02), RED_SHADOW)
end

-- Belly pan
paint("BellyPan", v(1.80, 0.12, 1.60), CFrame.new(0, 0.62, -0.80))
add("BellyUnder", v(1.60, 0.03, 1.40), CFrame.new(0, 0.545, -0.80), MATTE_BLACK)

-- Side vents
for _, s in { -1, 1 } do
	local vent = CFrame.new(s * 1.075, 2.85, -1.55) * A(math.rad(-20), 0, 0)
	add("VentOpening", v(0.02, 0.60, 0.90), vent, BORE_BLACK)
	for _, dy in { -0.18, 0, 0.18 } do
		add("VentFin", v(0.04, 0.04, 0.85), vent * CFrame.new(s * 0.03, dy, 0), RED_SHADOW)
	end
	add("LowerVent", v(0.02, 0.35, 0.70), CFrame.new(s * 1.125, 1.85, -1.20), BORE_BLACK)
end

-- Winglets
for _, s in { -1, 1 } do
	local roll = A(0, 0, -s * math.rad(6))
	add("WingletUpper", v(0.35, 0.05, 0.60), CFrame.new(s * 1.25, 3.05, -2.25) * roll, MATTE_BLACK)
	add("WingletLower", v(0.35, 0.05, 0.60), CFrame.new(s * 1.25, 2.85, -2.20) * roll, MATTE_BLACK)
	add("WingletEndplate", v(0.03, 0.30, 0.55), CFrame.new(s * 1.42, 2.95, -2.22), MATTE_BLACK)
end

-- Front fender
paint("FenderMain", v(0.42, 0.06, 1.00), CFrame.new(0, 2.50, -3.00))
paint("FenderFront", v(0.42, 0.06, 0.60), CFrame.new(0, 2.25, -3.68) * A(math.rad(-36), 0, 0))
paint("FenderRear", v(0.42, 0.06, 0.40), CFrame.new(0, 2.33, -2.40) * A(math.rad(30), 0, 0))

---------------------------------------------------------------------------------------------------
-- Tank, frame, seat and tail

paint("Tank", v(1.70, 0.60, 1.00), CFrame.new(0, 3.70, -1.10))
paint("TankCap", v(1.50, 0.12, 0.90), CFrame.new(0, 4.06, -1.05))
paintWedge("TankRearSlope", v(1.60, 0.55, 0.85), CFrame.new(0, 3.70, -0.175) * RISE_FRONT)
paintWedge("TankFrontSlope", v(1.60, 0.30, 0.35), CFrame.new(0, 3.90, -1.775))
cyl("FuelCap", v(0.03, 0.30, 0.30), CFrame.new(0, 4.135, -0.75) * CYLINDER_Y, MATTE_BLACK)
for _, s in { -1, 1 } do
	add("KneeRecess", v(0.10, 0.70, 1.40), CFrame.new(s * 0.85, 3.15, -0.80), RED_SHADOW)
	add("FrameSpar", v(0.08, 0.35, 1.30), CFrame.new(s * 0.84, 3.25, -0.55), FRAME_BLACK, M.Metal)
	add("FrameRear", v(0.08, 0.30, 0.50), CFrame.new(s * 0.80, 3.05, 0.35), FRAME_BLACK, M.Metal)
end

add("SeatPad", v(1.00, 0.18, 1.25), CFrame.new(0, 3.41, 0.85), SEAT, M.Fabric)
wedge("SeatBolster", v(1.00, 0.15, 0.30), CFrame.new(0, 3.575, 1.40), SEAT, M.Fabric)

local TAIL_TILT = A(math.rad(-12), 0, 0)
for _, s in { -1, 1 } do
	paint("TailSide", v(0.08, 0.60, 1.70), CFrame.new(s * 0.55, 3.10, 0.75))
	paintWedge(
		"TailTaper",
		v(0.45, 0.20, 2.20),
		CFrame.new(s * 0.35, 3.62, 2.55) * TAIL_TILT * (s > 0 and FLANK_R or FLANK_L) * RISE_FRONT
	)
	paint("TailFlank", v(0.06, 0.40, 1.70), CFrame.new(s * 0.38, 3.30, 2.25) * TAIL_TILT)
end
paint("TailBody", v(0.50, 0.45, 2.20), CFrame.new(0, 3.62, 2.55) * TAIL_TILT)
paint("TailTip", v(0.50, 0.30, 0.50), CFrame.new(0, 3.88, 3.55) * TAIL_TILT)
add("Undertail", v(0.70, 0.30, 1.60), CFrame.new(0, 3.10, 2.35) * TAIL_TILT, MATTE_BLACK)
add("RearHugger", v(0.55, 0.06, 0.90), CFrame.new(0, 2.78, 2.55), MATTE_BLACK)
add("HuggerArm", v(0.35, 0.05, 0.25), CFrame.new(-0.45, 2.78, 2.30), MATTE_BLACK)
add("HuggerBracket", v(0.06, 1.00, 0.18), CFrame.new(-0.62, 2.27, 2.30), MATTE_BLACK)

-- White accents
for _, s in { -1, 1 } do
	add(
		"AccentUpper",
		v(0.02, 0.06, 1.20),
		CFrame.new(s * 1.075, 3.42, -1.70),
		WHITE,
		M.SmoothPlastic,
		{
			reflectance = 0.08,
		}
	)
	add("AccentTail", v(0.02, 0.05, 1.40), CFrame.new(s * 0.475, 3.55, 2.45) * TAIL_TILT, WHITE)
	add("AccentVent", v(0.02, 0.05, 0.80), CFrame.new(s * 1.11, 2.50, -1.35), WHITE)
end

---------------------------------------------------------------------------------------------------
-- Screen and dash

local SCREEN = CFrame.new(0, 3.90, -2.35) * A(math.rad(-38), 0, 0)
add("Screen", v(1.10, 0.05, 1.30), SCREEN, GLASS_SMOKE, M.Glass, { transparency = 0.45 })
for _, s in { -1, 1 } do
	add("ScreenTrim", v(0.04, 0.06, 1.30), SCREEN * CFrame.new(s * 0.57, 0, 0), MATTE_BLACK)
end
local DASH = CFrame.new(0, 3.95, -2.05) * A(math.rad(-30), 0, 0)
add("Dash", v(0.60, 0.38, 0.05), DASH, MATTE_BLACK)
add("DashFace", v(0.50, 0.28, 0.01), DASH * CFrame.new(0, -0.02, 0.035), DASH_FACE)
neon("RevBar", v(0.40, 0.03, 0.01), DASH * CFrame.new(0, 0.10, 0.042), REV_BAR)

---------------------------------------------------------------------------------------------------
-- Lights

for _, s in { -1, 1 } do
	add("Intake", v(0.50, 0.32, 0.04), CFrame.new(s * 0.38, 2.82, -3.47), BORE_BLACK)
	neon("Headlight", v(0.18, 0.12, 0.03), CFrame.new(s * 0.38, 2.82, -3.495), HEADLIGHT)
	neon(
		"DRL",
		v(0.55, 0.05, 0.03),
		CFrame.new(s * 0.42, 3.12, -3.47) * A(0, 0, s * math.rad(12)),
		DRL
	)
	neon("TailStrip", v(0.04, 0.05, 0.60), CFrame.new(s * 0.27, 3.72, 3.40) * TAIL_TILT, TAIL)
	neon("RearIndicator", v(0.14, 0.08, 0.08), CFrame.new(s * 0.42, 2.55, 3.95), INDICATOR)
end
paint("NoseRidge", v(0.20, 0.40, 0.04), CFrame.new(0, 2.85, -3.47))
neon("TailBar", v(0.45, 0.05, 0.04), CFrame.new(0, 3.80, 3.82), TAIL)

---------------------------------------------------------------------------------------------------
-- Chassis and drivetrain

-- Single-sided swingarm (left)
local ARM = CFrame.new(-0.72, 1.65, 1.715) * A(math.rad(14.6), 0, 0)
add("Swingarm", v(0.18, 0.50, 2.50), ARM, SWINGARM, M.Metal)
add("SwingarmRib", v(0.20, 0.06, 2.30), ARM * CFrame.new(0, 0.27, 0), SWINGARM, M.Metal)
add("SwingarmPocket", v(0.02, 0.28, 1.40), ARM * CFrame.new(-0.10, 0, 0), POCKET, M.Metal)

cyl("PivotTube", v(1.30, 0.35, 0.35), CFrame.new(0, 1.95, 0.55), FRAME_BLACK, M.Metal)
for _, s in { -1, 1 } do
	cyl("PivotCap", v(0.04, 0.40, 0.40), CFrame.new(s * 0.67, 1.95, 0.55), DISC_STEEL, M.Metal)
end

-- Chain (left)
cyl("FrontSprocket", v(0.04, 0.36, 0.36), CFrame.new(-0.58, 1.85, 0.35), SPROCKET, M.Metal)
add(
	"ChainUpper",
	v(0.05, 0.06, 2.54),
	CFrame.new(-0.58, 1.90, 1.615) * A(math.rad(5.8), 0, 0),
	CHAIN,
	M.Metal
)
add(
	"ChainLower",
	v(0.05, 0.06, 2.64),
	CFrame.new(-0.58, 1.29, 1.615) * A(math.rad(16.6), 0, 0),
	CHAIN,
	M.Metal
)
add("SprocketCover", v(0.06, 0.45, 0.50), CFrame.new(-0.66, 1.85, 0.35), MATTE_BLACK)

-- Engine
add("Engine", v(1.30, 1.40, 1.40), CFrame.new(0, 1.75, 0.00), ENGINE, M.Metal)
add("RearHead", v(1.10, 0.50, 0.60), CFrame.new(0, 2.55, 0.20), ENGINE, M.Metal)
cyl("ClutchCover", v(0.08, 0.70, 0.70), CFrame.new(0.70, 1.55, 0.05), ENGINE, M.Metal)
add("Sump", v(1.00, 0.20, 0.80), CFrame.new(0, 0.75, -0.20), ENGINE, M.Metal)

-- Rear shock
local SHOCK = CFrame.new(0.10, 2.35, 0.95) * A(math.rad(-20), 0, 0)
cyl(
	"ShockSpring",
	v(0.80, 0.22, 0.22),
	SHOCK * CYLINDER_Y,
	OHLINS_GOLD,
	M.Metal,
	{ reflectance = 0.25 }
)
cyl(
	"ShockReservoir",
	v(0.30, 0.12, 0.12),
	SHOCK * CFrame.new(0.20, 0.15, 0) * CYLINDER_Y,
	MATTE_BLACK
)

-- Exhaust (right)
add("Collector", v(0.90, 0.40, 1.40), CFrame.new(0.10, 0.80, 0.25), MATTE_BLACK)
add("Downpipe", v(0.25, 0.60, 0.25), CFrame.new(0.50, 1.05, 0.85), MATTE_BLACK)
local E = CFrame.new(0.62, 1.40, 1.15) * A(math.rad(-35), 0, 0)
for _, dy in { -0.15, 0.15 } do
	cyl("ExhaustTip", v(0.55, 0.26, 0.26), E * CFrame.new(0, dy, 0) * CYLINDER_Z, TITANIUM, M.Metal)
	cyl("ExhaustBore", v(0.03, 0.18, 0.18), E * CFrame.new(0, dy, 0.28) * CYLINDER_Z, BORE_BLACK)
end
add("HeatShield", v(0.04, 0.40, 0.55), E * CFrame.new(0.16, 0, 0), MATTE_BLACK)

-- Rearsets
for _, s in { -1, 1 } do
	add(
		"RearsetHanger",
		v(0.06, 0.50, 0.30),
		CFrame.new(s * 0.62, 2.15, 0.85),
		FRAME_BLACK,
		M.Metal
	)
	cyl("Peg", v(0.30, 0.08, 0.08), CFrame.new(s * 0.80, 2.00, 0.80), DISC_STEEL, M.Metal)
	add("FootLever", v(0.04, 0.05, 0.45), CFrame.new(s * 0.70, 1.95, 0.45), DISC_STEEL, M.Metal)
end

-- Plate hanger
add("PlateArm", v(0.12, 0.08, 0.90), CFrame.new(0, 2.95, 3.55) * A(math.rad(30), 0, 0), MATTE_BLACK)
add("Plate", v(0.75, 0.55, 0.03), CFrame.new(0, 2.35, 4.05) * A(math.rad(-10), 0, 0), PLATE)

-- Kickstand (left, retracted)
add(
	"Kickstand",
	v(0.06, 0.06, 0.90),
	CFrame.new(-0.62, 1.20, 0.55) * A(math.rad(10), 0, 0),
	FRAME_BLACK,
	M.Metal
)

---------------------------------------------------------------------------------------------------
-- Mirrors and extras

for _, s in { -1, 1 } do
	add("MirrorStalk", v(0.06, 0.06, 0.30), CFrame.new(s * 1.15, 3.95, -2.40), MATTE_BLACK)
	add("MirrorHousing", v(0.55, 0.28, 0.16), CFrame.new(s * 1.32, 4.05, -2.35), MATTE_BLACK)
	add(
		"MirrorGlass",
		v(0.45, 0.20, 0.02),
		CFrame.new(s * 1.32, 4.05, -2.26),
		MIRROR_GLASS,
		M.Glass,
		{
			reflectance = 0.4,
		}
	)
	neon("MirrorIndicator", v(0.45, 0.04, 0.02), CFrame.new(s * 1.32, 4.00, -2.44), INDICATOR)
end
add("RamAirLip", v(0.80, 0.03, 0.30), CFrame.new(0, 3.52, -2.80), BORE_BLACK)
add("Cooler", v(0.90, 0.30, 0.04), CFrame.new(0, 2.10, -1.95), COOLER)

return {
	name = "Ducati Panigale V4",
	speed = 135,
	turnRate = 3,
	footprint = Vector2.new(3, 8.4),
	collision = {
		{ size = Vector3.new(2.2, 2.2, 7.0), offset = CFrame.new(0, 2.3, 0) },
		{ size = Vector3.new(2.2, 1.0, 1.45), offset = CFrame.new(0, 3.9, -2.675) },
		{ size = Vector3.new(1.0, 0.5, 1.8), offset = CFrame.new(0, 3.7, 2.6) },
	},
	seats = { CFrame.new(0, 3.0, 0.75) },
	pieces = pieces,
}
