-- Lunar Rover: Apollo 15 LRV, open aluminum tube chassis on wire-mesh wheels with a gold umbrella antenna.

-- Scale: 4 studs = 1 m.

local rgb = Color3.fromRGB
local M = Enum.Material
local A = CFrame.Angles
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball
local CYLINDER_Z = A(0, math.rad(90), 0)
local CYLINDER_Y = A(0, 0, math.rad(90))

local CHASSIS_ALU = rgb(196, 198, 200)
local FLOOR = rgb(172, 175, 178)
local FLOOR_DARK = rgb(120, 122, 125)
local MESH = rgb(150, 152, 150)
local MESH_DARK = rgb(115, 117, 115)
local TITANIUM = rgb(205, 205, 198)
local INNER_FRAME = rgb(100, 100, 98)
local HUB = rgb(218, 218, 218)
local MOTOR_GRAY = rgb(115, 117, 122)
local FENDER_SILVER = rgb(205, 205, 202)
local FENDER_EXT = rgb(178, 178, 175)
local GOLD_FOIL = rgb(212, 168, 66)
local GOLD_FOIL_DARK = rgb(180, 135, 45)
local GOLD_MESH = rgb(222, 190, 110)
local WHITE_BLANKET = rgb(236, 236, 228)
local MIRROR = rgb(228, 232, 238)
local RIB_WHITE = rgb(235, 235, 230)
local CAMERA_WHITE = rgb(205, 205, 200)
local CONSOLE_GRAY = rgb(70, 72, 75)
local CONSOLE_BLACK = rgb(32, 32, 34)
local GAUGE_FACE = rgb(18, 18, 20)
local NEEDLE_WHITE = rgb(240, 240, 240)
local LENS_GLASS = rgb(25, 30, 40)
local WEBBING = rgb(212, 208, 192)
local BELT = rgb(120, 130, 145)
local BAG_WHITE = rgb(240, 240, 235)
local TOOL_STEEL = rgb(170, 172, 175)

local WHEELS = {
	Vector3.new(-3.66, 1.65, -4.58),
	Vector3.new(3.66, 1.65, -4.58),
	Vector3.new(-3.66, 1.65, 4.58),
	Vector3.new(3.66, 1.65, 4.58),
}

local pieces = {}

local function add(spec)
	table.insert(pieces, spec)
	return spec
end

local function block(name, size, offset, color, material, extra)
	local spec = { name = name, size = size, offset = offset, color = color, material = material }
	if extra then
		for k, v in extra do
			spec[k] = v
		end
	end
	return add(spec)
end

local function cyl(name, length, diameter, offset, color, material, extra)
	local spec =
		block(name, Vector3.new(length, diameter, diameter), offset, color, material, extra)
	spec.shape = CYL
	return spec
end

local function ball(name, diameter, offset, color, material)
	local spec = block(name, Vector3.new(diameter, diameter, diameter), offset, color, material)
	spec.shape = BALL
	return spec
end

-- A tube between two points.
local function tube(name, p0, p1, diameter, color, material)
	local length = (p1 - p0).Magnitude
	local cf = CFrame.lookAt((p0 + p1) / 2, p1) * CYLINDER_Z
	return cyl(name, length, diameter, cf, color, material)
end

local ALU = M.Metal

----------------------------------------------------------------------------------------------------
-- Wheels and suspension
----------------------------------------------------------------------------------------------------

for _, w in WHEELS do
	local s = math.sign(w.X)
	local f = math.sign(w.Z)
	local c = CFrame.new(w)

	cyl("Tire", 0.92, 3.14, c, MESH, M.DiamondPlate, { transparency = 0.45 })
	cyl("BumpStop", 0.6, 2.5, c, INNER_FRAME, M.Metal)
	cyl("TireBandOuter", 0.06, 3.16, c * CFrame.new(s * 0.44, 0, 0), MESH_DARK, M.Metal, {
		transparency = 0.6,
	})
	cyl("TireBandInner", 0.06, 3.16, c * CFrame.new(-s * 0.44, 0, 0), MESH_DARK, M.Metal, {
		transparency = 0.6,
	})
	cyl("HubDish", 0.1, 1.5, c * CFrame.new(s * 0.5, 0, 0), HUB, M.Metal, { reflectance = 0.15 })
	cyl("HubCone", 0.1, 0.95, c * CFrame.new(s * 0.58, 0, 0), HUB, M.Metal, { reflectance = 0.15 })
	cyl("HubCap", 0.08, 0.4, c * CFrame.new(s * 0.65, 0, 0), MOTOR_GRAY, M.Metal)
	cyl("HubMotor", 0.4, 0.9, c * CFrame.new(-s * 0.62, 0, 0), MOTOR_GRAY, M.Metal)

	for k = 0, 7 do
		local theta = k * math.pi / 4
		for _, side in { -1, 1 } do
			block(
				"Chevron",
				Vector3.new(0.46, 0.06, 0.12),
				c
					* A(theta, 0, 0)
					* CFrame.new(side * 0.22, 1.615, 0)
					* A(0, side * math.rad(28), 0),
				TITANIUM,
				M.Metal
			)
		end
	end

	block(
		"UpperWishbone",
		Vector3.new(0.62, 0.1, 0.5),
		CFrame.new(s * 2.7, 2.15, w.Z),
		CHASSIS_ALU,
		ALU
	)
	block(
		"LowerWishbone",
		Vector3.new(0.62, 0.1, 0.6),
		CFrame.new(s * 2.7, 1.25, w.Z),
		CHASSIS_ALU,
		ALU
	)
	tube(
		"Damper",
		Vector3.new(s * 2.45, 2.2, w.Z + f * 0.35),
		Vector3.new(s * 2.95, 1.3, w.Z + f * 0.35),
		0.14,
		MOTOR_GRAY,
		M.Metal
	)
	cyl("TieRod", 1.1, 0.07, CFrame.new(s * 2.55, 1.45, w.Z - f * 0.55), CHASSIS_ALU, ALU)
end

----------------------------------------------------------------------------------------------------
-- Chassis
----------------------------------------------------------------------------------------------------

for _, s in { -1, 1 } do
	cyl("MainRail", 11.6, 0.2, CFrame.new(s * 2.4, 1.64, 0) * CYLINDER_Z, CHASSIS_ALU, ALU)
	cyl("UpperRail", 5.0, 0.12, CFrame.new(s * 2.4, 2.25, 0) * CYLINDER_Z, CHASSIS_ALU, ALU)
	for _, z in { -2.5, 2.5 } do
		cyl("Upright", 0.6, 0.1, CFrame.new(s * 2.4, 1.95, z) * CYLINDER_Y, CHASSIS_ALU, ALU)
	end
	for _, z in { -2.6, 2.6 } do
		cyl("HingeKnuckle", 0.3, 0.26, CFrame.new(s * 2.4, 1.64, z), FLOOR_DARK, M.Metal)
	end
	for _, z in { -4.4, 4.4 } do
		cyl("TorsionBar", 3.0, 0.08, CFrame.new(s * 2.25, 1.5, z) * CYLINDER_Z, MOTOR_GRAY, M.Metal)
	end
end

for _, z in { -5.9, -3.8, -2.6, 2.6, 3.8, 5.9 } do
	cyl("CrossTube", 4.8, 0.14, CFrame.new(0, 1.6, z), CHASSIS_ALU, ALU)
end

block("Floor", Vector3.new(4.6, 0.06, 5.0), CFrame.new(0, 1.58, 0), FLOOR, M.DiamondPlate)
for _, x in { -1.8, -0.9, 0, 0.9, 1.8 } do
	block("FloorBead", Vector3.new(0.05, 0.03, 4.8), CFrame.new(x, 1.625, 0), FLOOR_DARK, M.Metal)
end
block("ForwardDeck", Vector3.new(4.6, 0.06, 3.3), CFrame.new(0, 1.78, -4.3), CHASSIS_ALU, ALU)
block("AftDeck", Vector3.new(4.6, 0.06, 3.3), CFrame.new(0, 1.78, 4.3), CHASSIS_ALU, ALU)

----------------------------------------------------------------------------------------------------
-- Fenders
----------------------------------------------------------------------------------------------------

for _, w in WHEELS do
	local s = math.sign(w.X)
	local f = math.sign(w.Z)
	local x = s * 3.66
	local plate = Vector3.new(1.12, 0.06, 1.1)
	local slope = math.rad(35)

	block(
		"FenderTop",
		Vector3.new(1.12, 0.06, 1.6),
		CFrame.new(x, 3.45, w.Z),
		FENDER_SILVER,
		M.Metal,
		{
			reflectance = 0.1,
		}
	)
	-- Plates hinge at the top plate's ends and slope down away from it.
	local outerHinge = CFrame.new(x, 3.45, w.Z + f * 0.78)
	local outer = outerHinge * A(f * slope, 0, 0) * CFrame.new(0, 0, f * 0.55)
	block("FenderOuter", plate, outer, FENDER_SILVER, M.Metal, { reflectance = 0.1 })
	local innerHinge = CFrame.new(x, 3.45, w.Z - f * 0.78)
	block(
		"FenderInner",
		plate,
		innerHinge * A(-f * slope, 0, 0) * CFrame.new(0, 0, -f * 0.55),
		FENDER_SILVER,
		M.Metal,
		{ reflectance = 0.1 }
	)
	if f < 0 then
		local tip = outerHinge * A(f * slope, 0, 0) * CFrame.new(0, -0.01, f * 1.08)
		block(
			"FenderExtension",
			Vector3.new(1.1, 0.05, 0.6),
			tip * A(f * math.rad(20), 0, 0) * CFrame.new(0, 0, f * 0.3),
			FENDER_EXT,
			M.SmoothPlastic
		)
	end
	tube(
		"FenderStrut",
		Vector3.new(s * 2.4, 2.25, w.Z),
		Vector3.new(s * 3.3, 3.42, w.Z),
		0.08,
		CHASSIS_ALU,
		ALU
	)
end

----------------------------------------------------------------------------------------------------
-- Forward chassis: batteries, electronics, relay unit
----------------------------------------------------------------------------------------------------

for _, s in { -1, 1 } do
	block(
		"BatteryCover",
		Vector3.new(1.7, 0.7, 1.6),
		CFrame.new(s * 1.2, 2.17, -3.6),
		WHITE_BLANKET,
		M.Fabric
	)
	block(
		"BatteryRadiator",
		Vector3.new(1.4, 0.04, 1.3),
		CFrame.new(s * 1.2, 2.53, -3.6),
		MIRROR,
		M.Metal,
		{
			reflectance = 0.4,
		}
	)
	cyl("DustCoverHinge", 1.7, 0.08, CFrame.new(s * 1.2, 2.55, -2.78), CHASSIS_ALU, ALU)
	block("RelayLeg", Vector3.new(0.1, 0.42, 0.1), CFrame.new(s * 0.9, 2.0, -5.6), CHASSIS_ALU, ALU)
end

block(
	"SignalProcessor",
	Vector3.new(1.6, 0.6, 1.1),
	CFrame.new(0, 2.12, -4.75),
	GOLD_FOIL,
	M.Foil,
	{
		reflectance = 0.2,
	}
)
block("DriveControl", Vector3.new(3.6, 0.45, 0.6), CFrame.new(0, 2.04, -2.75), GOLD_FOIL, M.Foil, {
	reflectance = 0.2,
})
local crinkles = {
	{ -0.35, 2.43, -4.95, 10, Vector3.new(0.6, 0.03, 0.5) },
	{ 0.4, 2.43, -4.55, -8, Vector3.new(0.5, 0.03, 0.4) },
	{ -1.2, 2.275, -2.72, -6, Vector3.new(0.6, 0.03, 0.4) },
	{ 1.15, 2.275, -2.78, 9, Vector3.new(0.6, 0.03, 0.4) },
}
for _, c in crinkles do
	block(
		"FoilCrinkle",
		c[5],
		CFrame.new(c[1], c[2], c[3]) * A(0, math.rad(c[4]), 0),
		GOLD_FOIL_DARK,
		M.Foil
	)
end

block("RelayUnit", Vector3.new(2.2, 1.4, 1.0), CFrame.new(0, 2.9, -5.6), WHITE_BLANKET, M.Fabric)
block("RelayMirror", Vector3.new(2.0, 0.04, 0.85), CFrame.new(0, 3.62, -5.6), MIRROR, M.Metal, {
	reflectance = 0.4,
})
block(
	"RelayPanel",
	Vector3.new(1.2, 0.5, 0.04),
	CFrame.new(0, 2.8, -6.12),
	CONSOLE_BLACK,
	M.SmoothPlastic
)
for _, x in { -0.35, 0, 0.35 } do
	cyl("RelayConnector", 0.08, 0.14, CFrame.new(x, 2.8, -6.16) * CYLINDER_Z, CHASSIS_ALU, ALU)
end

----------------------------------------------------------------------------------------------------
-- High-gain umbrella antenna (front left)
----------------------------------------------------------------------------------------------------

cyl("HGAMastLower", 3.8, 0.14, CFrame.new(-1.5, 3.7, -5.5) * CYLINDER_Y, CHASSIS_ALU, ALU)
cyl("HGAMastCollar", 0.2, 0.22, CFrame.new(-1.5, 5.6, -5.5) * CYLINDER_Y, MOTOR_GRAY, M.Metal)
cyl("HGAMastUpper", 2.0, 0.1, CFrame.new(-1.5, 6.6, -5.5) * CYLINDER_Y, CHASSIS_ALU, ALU)

local D = CFrame.new(-1.5, 7.55, -5.5) * A(math.rad(-30), 0, math.rad(12))
ball("HGAHub", 0.3, D, RIB_WHITE, M.Metal)
for k = 0, 7 do
	block(
		"HGARib",
		Vector3.new(0.05, 0.05, 1.9),
		D * A(0, k * math.pi / 4, 0) * CFrame.new(0, 0.18, -0.92) * A(math.rad(11), 0, 0),
		RIB_WHITE,
		M.Metal
	)
end
cyl(
	"HGADishRim",
	0.04,
	3.6,
	D * CFrame.new(0, 0.36, 0) * CYLINDER_Y,
	GOLD_MESH,
	M.Foil,
	{ transparency = 0.3 }
)
cyl(
	"HGADishMid",
	0.04,
	2.4,
	D * CFrame.new(0, 0.2, 0) * CYLINDER_Y,
	GOLD_MESH,
	M.Foil,
	{ transparency = 0.3 }
)
cyl("HGADishInner", 0.04, 1.2, D * CFrame.new(0, 0.08, 0) * CYLINDER_Y, GOLD_MESH, M.Foil, {
	transparency = 0.2,
})
cyl("HGAFeed", 0.9, 0.06, D * CFrame.new(0, 0.6, 0) * CYLINDER_Y, RIB_WHITE, M.Metal)
ball("HGAFeedTip", 0.14, D * CFrame.new(0, 1.05, 0), RIB_WHITE, M.Metal)
block(
	"HGAHandle",
	Vector3.new(0.4, 0.06, 0.06),
	D * CFrame.new(0, -0.15, 0.3),
	CONSOLE_BLACK,
	M.SmoothPlastic
)

----------------------------------------------------------------------------------------------------
-- Low-gain helical antenna (front right)
----------------------------------------------------------------------------------------------------

cyl("LGAMast", 3.6, 0.1, CFrame.new(1.5, 3.6, -5.4) * CYLINDER_Y, CHASSIS_ALU, ALU)
cyl("LGAElement", 2.0, 0.07, CFrame.new(1.5, 6.4, -5.4) * CYLINDER_Y, RIB_WHITE, M.Metal)
for i = 0, 7 do
	cyl(
		"LGAHelix",
		0.035,
		0.32,
		CFrame.new(1.5, 5.6 + i * 0.22, -5.4) * A(math.rad(12), 0, 0) * CYLINDER_Y,
		GOLD_FOIL,
		M.Foil,
		{ reflectance = 0.2 }
	)
end
ball("LGATip", 0.12, CFrame.new(1.5, 7.42, -5.4), RIB_WHITE, M.Metal)

----------------------------------------------------------------------------------------------------
-- TV camera (front center)
----------------------------------------------------------------------------------------------------

cyl("TVMast", 1.26, 0.14, CFrame.new(0, 4.27, -5.9) * CYLINDER_Y, CHASSIS_ALU, ALU)
block("TVYoke", Vector3.new(0.7, 0.3, 0.3), CFrame.new(0, 4.95, -5.9), MOTOR_GRAY, M.Metal)
block(
	"TVBody",
	Vector3.new(0.62, 0.6, 1.0),
	CFrame.new(0, 5.4, -5.9),
	CAMERA_WHITE,
	M.SmoothPlastic
)
block("TVThermalTop", Vector3.new(0.58, 0.03, 0.9), CFrame.new(0, 5.715, -5.9), MIRROR, M.Metal, {
	reflectance = 0.4,
})
cyl(
	"TVLensBarrel",
	0.4,
	0.3,
	CFrame.new(0, 5.4, -6.55) * CYLINDER_Z,
	CONSOLE_BLACK,
	M.SmoothPlastic
)
cyl("TVLensHood", 0.2, 0.4, CFrame.new(0, 5.4, -6.8) * CYLINDER_Z, CONSOLE_BLACK, M.SmoothPlastic)
cyl("TVLensGlass", 0.03, 0.26, CFrame.new(0, 5.4, -6.91) * CYLINDER_Z, LENS_GLASS, M.Glass, {
	transparency = 0.2,
})

----------------------------------------------------------------------------------------------------
-- Crew station: seats
----------------------------------------------------------------------------------------------------

local RECLINE = A(math.rad(10), 0, 0)

for _, s in { -1, 1 } do
	local x = s * 1.2
	block("SeatPan", Vector3.new(1.7, 0.05, 1.5), CFrame.new(x, 2.56, 0.9), WEBBING, M.Fabric)
	for _, dx in { -0.88, 0.88 } do
		cyl("SeatPanTube", 1.6, 0.09, CFrame.new(x + dx, 2.55, 0.9) * CYLINDER_Z, CHASSIS_ALU, ALU)
		cyl(
			"SeatBackTube",
			1.9,
			0.09,
			CFrame.new(x + dx, 3.5, 1.78) * RECLINE * CYLINDER_Y,
			CHASSIS_ALU,
			ALU
		)
	end
	cyl("SeatFrontTube", 1.8, 0.09, CFrame.new(x, 2.55, 0.12), CHASSIS_ALU, ALU)
	block(
		"SeatBack",
		Vector3.new(1.7, 1.7, 0.05),
		CFrame.new(x, 3.5, 1.78) * RECLINE,
		WEBBING,
		M.Fabric
	)
	cyl("SeatTopTube", 1.8, 0.09, CFrame.new(x, 4.43, 1.95), CHASSIS_ALU, ALU)
	for _, dx in { -0.8, 0.8 } do
		block(
			"SeatLeg",
			Vector3.new(0.08, 0.95, 0.08),
			CFrame.new(x + dx, 2.08, 0.9),
			CHASSIS_ALU,
			ALU
		)
	end
	block(
		"SeatBelt",
		Vector3.new(0.12, 1.6, 0.03),
		CFrame.new(x, 3.5, 1.78) * RECLINE * CFrame.new(0, 0, -0.05) * A(0, 0, s * math.rad(25)),
		BELT,
		M.Fabric
	)
	block(
		"Footrest",
		Vector3.new(1.5, 0.05, 0.5),
		CFrame.new(x, 1.8, -2.05) * A(math.rad(35), 0, 0),
		FLOOR,
		M.DiamondPlate
	)
end

----------------------------------------------------------------------------------------------------
-- Crew station: hand controller and armrest
----------------------------------------------------------------------------------------------------

block(
	"Armrest",
	Vector3.new(0.28, 0.12, 1.2),
	CFrame.new(0, 3.15, 0.75),
	CONSOLE_BLACK,
	M.SmoothPlastic
)
block("ArmrestPost", Vector3.new(0.1, 1.5, 0.1), CFrame.new(0, 2.35, 1.2), CHASSIS_ALU, ALU)
cyl("ControllerPost", 1.6, 0.1, CFrame.new(0, 2.43, -0.3) * CYLINDER_Y, CHASSIS_ALU, ALU)
cyl(
	"ControllerBoot",
	0.25,
	0.26,
	CFrame.new(0, 3.35, -0.3) * CYLINDER_Y,
	CONSOLE_BLACK,
	M.SmoothPlastic
)
cyl("TStem", 0.45, 0.09, CFrame.new(0, 3.7, -0.3) * CYLINDER_Y, CONSOLE_BLACK, M.SmoothPlastic)
cyl("TCrossbar", 0.34, 0.1, CFrame.new(0, 3.95, -0.3), CONSOLE_BLACK, M.SmoothPlastic)

----------------------------------------------------------------------------------------------------
-- Crew station: control and display console
----------------------------------------------------------------------------------------------------

cyl("ConsolePost", 2.3, 0.14, CFrame.new(0, 2.75, -2.4) * CYLINDER_Y, CHASSIS_ALU, ALU)
local CONSOLE = CFrame.new(0, 4.4, -2.4) * A(math.rad(-15), 0, 0)
block("ConsoleBox", Vector3.new(2.0, 1.3, 0.3), CONSOLE, CONSOLE_GRAY, M.SmoothPlastic)
block(
	"ConsoleFace",
	Vector3.new(1.9, 1.2, 0.03),
	CONSOLE * CFrame.new(0, 0, 0.165),
	CONSOLE_BLACK,
	M.SmoothPlastic
)
for row = 0, 1 do
	for col = -1, 1 do
		local dial = CONSOLE * CFrame.new(col * 0.6, 0.35 - row * 0.45, 0.2)
		cyl("GaugeDial", 0.03, 0.32, dial * CYLINDER_Z, GAUGE_FACE, M.Glass, { transparency = 0.1 })
		block(
			"GaugeNeedle",
			Vector3.new(0.02, 0.12, 0.02),
			dial
				* CFrame.new(0, 0, 0.025)
				* A(0, 0, math.rad(35 - (row * 3 + col) * 20))
				* CFrame.new(0, 0.05, 0),
			NEEDLE_WHITE,
			M.Neon
		)
	end
end
for i = 0, 7 do
	block(
		"ToggleSwitch",
		Vector3.new(0.05, 0.05, 0.1),
		CONSOLE * CFrame.new(-0.77 + i * 0.22, -0.45, 0.23),
		CHASSIS_ALU,
		ALU
	)
end
block(
	"SunShadowBase",
	Vector3.new(0.4, 0.04, 0.3),
	CONSOLE * CFrame.new(0, 0.67, 0),
	CONSOLE_BLACK,
	M.SmoothPlastic
)
block(
	"SunShadowPin",
	Vector3.new(0.04, 0.3, 0.04),
	CONSOLE * CFrame.new(0, 0.84, 0),
	NEEDLE_WHITE,
	M.Neon
)

-- Movie camera on a post at the right seat side.
block("MovieCamPost", Vector3.new(0.06, 1.05, 0.06), CFrame.new(2.4, 2.775, -1.2), CHASSIS_ALU, ALU)
block(
	"MovieCam",
	Vector3.new(0.3, 0.35, 0.5),
	CFrame.new(2.4, 3.47, -1.2),
	CONSOLE_GRAY,
	M.SmoothPlastic
)
cyl(
	"MovieCamLens",
	0.15,
	0.14,
	CFrame.new(2.4, 3.5, -1.52) * CYLINDER_Z,
	CONSOLE_BLACK,
	M.SmoothPlastic
)

----------------------------------------------------------------------------------------------------
-- Aft pallet and tools
----------------------------------------------------------------------------------------------------

block("PalletDeck", Vector3.new(4.0, 0.08, 3.0), CFrame.new(0, 1.85, 4.5), CHASSIS_ALU, ALU)
for _, s in { -1, 1 } do
	for _, z in { 3.6, 5.4 } do
		cyl(
			"CarrierUpright",
			2.01,
			0.08,
			CFrame.new(s * 1.8, 2.895, z) * CYLINDER_Y,
			CHASSIS_ALU,
			ALU
		)
	end
	cyl("CarrierRailZ", 1.8, 0.08, CFrame.new(s * 1.8, 3.9, 4.5) * CYLINDER_Z, CHASSIS_ALU, ALU)
end
for _, z in { 3.6, 5.4 } do
	cyl("CarrierRailX", 3.6, 0.08, CFrame.new(0, 3.9, z), CHASSIS_ALU, ALU)
end
block(
	"CarrierBackPanel",
	Vector3.new(3.5, 1.6, 0.04),
	CFrame.new(0, 2.7, 5.44),
	WHITE_BLANKET,
	M.Fabric
)
for _, x in { -1.0, 0, 1.0 } do
	block("SampleBags", Vector3.new(0.7, 0.8, 0.5), CFrame.new(x, 2.29, 4.0), BAG_WHITE, M.Fabric)
end

local TOOL_LEAN = A(math.rad(15), 0, 0)
local function toolTop(x)
	return CFrame.new(x, 3.75, 4.8) * TOOL_LEAN * CFrame.new(0, 1.8, 0)
end
for _, x in { -1.4, -0.9, 1.3 } do
	cyl(
		"ToolHandle",
		3.6,
		0.06,
		CFrame.new(x, 3.75, 4.8) * TOOL_LEAN * CYLINDER_Y,
		TOOL_STEEL,
		M.Metal
	)
	cyl(
		"ToolGrip",
		0.3,
		0.09,
		toolTop(x) * CFrame.new(0, -0.2, 0) * CYLINDER_Y,
		CONSOLE_BLACK,
		M.SmoothPlastic
	)
end
-- Tongs, scoop and rake heads ride on the low (working) ends, the grips on the high ends.
block(
	"ScoopHead",
	Vector3.new(0.25, 0.15, 0.3),
	toolTop(-0.9) * CFrame.new(0, 0.05, -0.1),
	TOOL_STEEL,
	M.Metal
)
block(
	"RakeHead",
	Vector3.new(0.6, 0.1, 0.12),
	toolTop(1.3) * CFrame.new(0, 0.05, 0),
	TOOL_STEEL,
	M.Metal
)
cyl("Gnomon", 0.8, 0.04, CFrame.new(1.6, 4.3, 3.7) * CYLINDER_Y, TOOL_STEEL, M.Metal)
ball("GnomonBall", 0.1, CFrame.new(1.6, 4.73, 3.7), TOOL_STEEL, M.Metal)
cyl("HammerHandle", 0.9, 0.06, CFrame.new(0.9, 2.8, 5.49) * CYLINDER_Y, TOOL_STEEL, M.Metal)
block("HammerHead", Vector3.new(0.3, 0.12, 0.12), CFrame.new(0.9, 3.28, 5.49), MOTOR_GRAY, M.Metal)

return {
	name = "Lunar Rover",
	-- Real: 13 km/h, 0-13 km/h in 4 s, brakes 0.15 g, coasts 0.1 g (VehicleDefaults maps them).
	speed = 20,
	acceleration = 5.9,
	braking = 8.2,
	coasting = 6.3,
	turnRate = 2,
	footprint = Vector2.new(8.4, 12.4),
	collision = {
		{ size = Vector3.new(8.2, 1.0, 12.2), offset = CFrame.new(0, 1.8, 0) },
		{ size = Vector3.new(4.4, 1.4, 3.4), offset = CFrame.new(0, 2.95, -4.6) },
		{ size = Vector3.new(4.0, 1.9, 3.0), offset = CFrame.new(0, 3.0, 4.5) },
	},
	seats = {
		CFrame.new(-1.2, 2.1, 0.9),
		CFrame.new(1.2, 2.1, 0.9),
	},
	pieces = pieces,
}
