-- G 63: 2019+ Mercedes-AMG G 63 (W463A) in obsidian black metallic.
-- Scale: 4 studs = 1 m. Front axle z -6.3, rear axle z 5.26, track 6.56, 22" wheels.

local rgb = Color3.fromRGB
local M = Enum.Material
local A = CFrame.Angles
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball
local CYLINDER_Z = A(0, math.rad(90), 0) -- cylinder axis along Z
local CYLINDER_Y = A(0, 0, math.rad(90)) -- cylinder axis along Y
-- WedgePart default: full bottom and full back (+Z) faces, slope rising toward +Z.
local W_LEFT = A(0, math.pi / 2, 0) -- size = (lengthZ, h, widthX); tall face +X, slope falls to -X
local W_RIGHT = A(0, -math.pi / 2, 0) -- tall face -X, slope falls to +X

local OBS = rgb(24, 24, 30)
local CHROME = rgb(200, 203, 208)
local ALU = rgb(160, 163, 168)
local TRIM_BLK = rgb(26, 26, 28)
local GRILLE_BLK = rgb(10, 10, 12)
local GAP = rgb(6, 6, 8)
local UNDER = rgb(30, 30, 32)
local GLASS = rgb(25, 32, 40)
local LENS = rgb(220, 228, 238)
local LED_W = rgb(235, 242, 255)
local AMBER = rgb(255, 150, 30)
local RED = rgb(210, 20, 20)
local TAIL_RED = rgb(120, 10, 14)
local REVERSE_WHITE = rgb(235, 235, 235)
local TIRE = rgb(28, 28, 30)
local RIM_SILVER = rgb(165, 168, 172)
local RIM_DARK = rgb(45, 46, 50)
local DISC = rgb(115, 115, 118)
local CALIPER_RED = rgb(175, 22, 28)
local BORE = rgb(8, 8, 8)
local LEATHER_RED = rgb(125, 28, 30)
local LEATHER_BLK = rgb(32, 30, 30)
local DASH = rgb(38, 38, 40)
local SCREEN = rgb(15, 20, 30)
local SCREEN_GLOW = rgb(40, 70, 110)
local HEADLINER = rgb(58, 56, 54)
local MIRROR_GLASS = rgb(150, 160, 170)
local PLATE = rgb(225, 225, 220)

local PAINT_REFLECT = 0.12
local GLASS_ALPHA = 0.45

local FRONT_AXLE = -6.3
local REAR_AXLE = 5.26
local WHEEL_X = 3.28
local WHEEL_Y = 1.59
local SIDES = { -1, 1 }

local pieces = {}
local function add(p)
	table.insert(pieces, p)
end

local function paint(name, size, offset)
	add({
		name = name,
		size = size,
		offset = offset,
		color = OBS,
		material = M.SmoothPlastic,
		reflectance = PAINT_REFLECT,
	})
end

local function block(name, size, offset, color, material, extra)
	local p = {
		name = name,
		size = size,
		offset = offset,
		color = color,
		material = material or M.SmoothPlastic,
	}
	if extra then
		for k, v in extra do
			p[k] = v
		end
	end
	add(p)
end

local function cyl(name, size, offset, color, material, extra)
	local p = {
		name = name,
		shape = CYL,
		size = size,
		offset = offset,
		color = color,
		material = material or M.SmoothPlastic,
	}
	if extra then
		for k, v in extra do
			p[k] = v
		end
	end
	add(p)
end

local function wedge(name, size, offset, color, material, extra)
	local p = {
		name = name,
		class = "WedgePart",
		size = size,
		offset = offset,
		color = color,
		material = material or M.SmoothPlastic,
	}
	if extra then
		for k, v in extra do
			p[k] = v
		end
	end
	add(p)
end

local CHROME_X = { reflectance = 0.25 }
local GLOSS = { reflectance = PAINT_REFLECT }

-- Body shell ---------------------------------------------------------------------------------

block("EngineCore", Vector3.new(5.2, 3.0, 5.1), CFrame.new(0, 3.2, -6.15), UNDER)
block("CabinFloor", Vector3.new(6.9, 0.7, 12.1), CFrame.new(0, 2.05, 2.35), TRIM_BLK)
block("Firewall", Vector3.new(6.9, 2.6, 0.1), CFrame.new(0, 3.7, -3.65), TRIM_BLK)
paint("Hood", Vector3.new(5.9, 0.18, 5.1), CFrame.new(0, 4.79, -6.15))
wedge("HoodChamfer", Vector3.new(5.9, 0.18, 0.3), CFrame.new(0, 4.79, -8.85), OBS, nil, GLOSS)
paint("Cowl", Vector3.new(6.9, 0.12, 0.3), CFrame.new(0, 4.94, -3.75))
block("CowlVent", Vector3.new(6.2, 0.03, 0.18), CFrame.new(0, 5.01, -3.75), GRILLE_BLK)
block("NoseFace", Vector3.new(6.9, 1.8, 0.3), CFrame.new(0, 3.8, -8.85), OBS, nil, GLOSS)

for _, s in SIDES do
	local side = s < 0 and "L" or "R"
	paint("FenderTop" .. side, Vector3.new(0.5, 0.3, 5.4), CFrame.new(s * 3.2, 4.85, -6.3))
	paint("PanelFrontCorner" .. side, Vector3.new(0.3, 3.1, 0.8), CFrame.new(s * 3.6, 3.45, -8.6))
	paint(
		"PanelFrontArch" .. side,
		Vector3.new(0.3, 1.25, 3.8),
		CFrame.new(s * 3.6, 4.375, FRONT_AXLE)
	)
	paint("PanelDoors" .. side, Vector3.new(0.3, 3.3, 7.76), CFrame.new(s * 3.6, 3.35, -0.52))
	paint(
		"PanelRearArch" .. side,
		Vector3.new(0.3, 1.25, 3.8),
		CFrame.new(s * 3.6, 4.375, REAR_AXLE)
	)
	paint("PanelRearCorner" .. side, Vector3.new(0.3, 3.1, 1.54), CFrame.new(s * 3.6, 3.45, 7.93))

	for _, az in { FRONT_AXLE, REAR_AXLE } do
		block(
			"WheelWell" .. side,
			Vector3.new(0.85, 1.5, 4.0),
			CFrame.new(s * 3.025, 3.05, az),
			TRIM_BLK
		)
		paint("FlareTop" .. side, Vector3.new(0.22, 0.3, 4.3), CFrame.new(s * 3.86, 3.9, az))
		-- Legs lean their tops in toward the wheel, so the arch opens wider at the bottom.
		paint(
			"FlareLegFront" .. side,
			Vector3.new(0.22, 0.95, 0.35),
			CFrame.new(s * 3.86, 3.4, az - 2.08) * A(math.rad(22), 0, 0)
		)
		paint(
			"FlareLegRear" .. side,
			Vector3.new(0.22, 0.95, 0.35),
			CFrame.new(s * 3.86, 3.4, az + 2.08) * A(math.rad(-22), 0, 0)
		)
	end

	-- Glasshouse.
	paint(
		"APillar" .. side,
		Vector3.new(0.28, 2.6, 0.24),
		CFrame.new(s * 3.56, 6.3, -3.35) * A(math.rad(11.3), 0, 0)
	)
	paint("BPillar" .. side, Vector3.new(0.24, 2.62, 0.3), CFrame.new(s * 3.62, 6.31, 0.6))
	paint("CPillar" .. side, Vector3.new(0.24, 2.62, 0.4), CFrame.new(s * 3.62, 6.31, 4.15))
	paint("DPillar" .. side, Vector3.new(0.24, 2.62, 0.4), CFrame.new(s * 3.62, 6.31, 8.5))
	paint("WindowSill" .. side, Vector3.new(0.24, 0.1, 11.7), CFrame.new(s * 3.62, 5.05, 2.55))
	paint("WindowHeader" .. side, Vector3.new(0.24, 0.32, 11.8), CFrame.new(s * 3.62, 7.46, 2.75))
	paint("DripRail" .. side, Vector3.new(0.08, 0.1, 11.8), CFrame.new(s * 3.76, 7.6, 2.75))
end

paint("RearPanel", Vector3.new(6.9, 3.6, 0.3), CFrame.new(0, 3.7, 8.55))
for _, s in SIDES do
	paint("RearPost", Vector3.new(0.825, 2.1, 0.3), CFrame.new(s * 3.0875, 6.55, 8.55))
end
paint("RearHeader", Vector3.new(7.0, 0.22, 0.3), CFrame.new(0, 7.51, 8.55))

paint("Roof", Vector3.new(6.88, 0.24, 11.8), CFrame.new(0, 7.74, 2.75))
wedge(
	"RoofChamferL",
	Vector3.new(11.8, 0.24, 0.18),
	CFrame.new(-3.53, 7.74, 2.75) * W_LEFT,
	OBS,
	nil,
	GLOSS
)
wedge(
	"RoofChamferR",
	Vector3.new(11.8, 0.24, 0.18),
	CFrame.new(3.53, 7.74, 2.75) * W_RIGHT,
	OBS,
	nil,
	GLOSS
)
wedge("RoofChamferFront", Vector3.new(6.88, 0.24, 0.2), CFrame.new(0, 7.74, -3.25), OBS, nil, GLOSS)
paint("WindshieldHeader", Vector3.new(7.0, 0.2, 0.3), CFrame.new(0, 7.53, -3.12))
block("Headliner", Vector3.new(6.8, 0.04, 11.6), CFrame.new(0, 7.59, 2.75), HEADLINER, M.Fabric)

-- Bumpers and chassis.
paint("FrontBumper", Vector3.new(7.7, 1.35, 0.6), CFrame.new(0, 2.075, -9.3))
wedge(
	"FrontBumperChamfer",
	Vector3.new(7.7, 0.15, 0.6),
	CFrame.new(0, 2.825, -9.3),
	OBS,
	nil,
	GLOSS
)
block(
	"FrontSkidPlate",
	Vector3.new(4.0, 0.12, 1.2),
	CFrame.new(0, 1.36, -9.0),
	ALU,
	M.Metal,
	{ reflectance = 0.1 }
)
paint("RearBumper", Vector3.new(7.7, 0.95, 0.45), CFrame.new(0, 1.98, 8.85))
block("RearStepPlate", Vector3.new(3.0, 0.05, 0.3), CFrame.new(0, 2.47, 8.85), TRIM_BLK)
block("Chassis", Vector3.new(4.8, 0.6, 15.0), CFrame.new(0, 1.3, 0), UNDER, M.Metal)
cyl("FrontAxle", Vector3.new(5.4, 0.4, 0.4), CFrame.new(0, WHEEL_Y, FRONT_AXLE), UNDER, M.Metal)
cyl("RearAxle", Vector3.new(5.4, 0.4, 0.4), CFrame.new(0, WHEEL_Y, REAR_AXLE), UNDER, M.Metal)
add({
	name = "RearDiff",
	shape = BALL,
	size = Vector3.new(1, 1, 1),
	offset = CFrame.new(0, 1.5, REAR_AXLE),
	color = UNDER,
	material = M.Metal,
})
add({
	name = "FrontDiff",
	shape = BALL,
	size = Vector3.new(0.9, 0.9, 0.9),
	offset = CFrame.new(0, 1.5, FRONT_AXLE),
	color = UNDER,
	material = M.Metal,
})

-- Glass --------------------------------------------------------------------------------------

local GLASS_X = { transparency = GLASS_ALPHA }
block(
	"Windshield",
	Vector3.new(6.9, 2.55, 0.08),
	CFrame.new(0, 6.25, -3.35) * A(math.rad(11.3), 0, 0),
	GLASS,
	M.Glass,
	GLASS_X
)
for _, s in SIDES do
	local side = s < 0 and "L" or "R"
	block(
		"FrontDoorGlass" .. side,
		Vector3.new(0.06, 2.25, 3.55),
		CFrame.new(s * 3.55, 6.225, -1.325),
		GLASS,
		M.Glass,
		GLASS_X
	)
	-- Triangle between the vertical door glass and the raked A-pillar.
	wedge(
		"FrontDoorGlassTip" .. side,
		Vector3.new(0.06, 2.25, 0.46),
		CFrame.new(s * 3.55, 6.225, -3.33),
		GLASS,
		M.Glass,
		GLASS_X
	)
	block(
		"RearDoorGlass" .. side,
		Vector3.new(0.06, 2.25, 3.2),
		CFrame.new(s * 3.55, 6.225, 2.35),
		GLASS,
		M.Glass,
		GLASS_X
	)
	block(
		"QuarterGlass" .. side,
		Vector3.new(0.06, 2.25, 3.95),
		CFrame.new(s * 3.55, 6.225, 6.325),
		GLASS,
		M.Glass,
		GLASS_X
	)
end
block("RearWindow", Vector3.new(5.4, 1.9, 0.06), CFrame.new(0, 6.45, 8.73), GLASS, M.Glass, GLASS_X)
block(
	"RearWiper",
	Vector3.new(0.06, 1.3, 0.04),
	CFrame.new(0.2, 6.05, 8.78) * A(0, 0, math.rad(-55)),
	TRIM_BLK
)

-- Lights -------------------------------------------------------------------------------------

for _, s in SIDES do
	local side = s < 0 and "L" or "R"
	local hx, hy = s * 2.6, 3.85
	cyl(
		"HeadlightBezel" .. side,
		Vector3.new(0.12, 1.35, 1.35),
		CFrame.new(hx, hy, -9.06) * CYLINDER_Z,
		CHROME,
		M.Metal,
		CHROME_X
	)
	cyl(
		"HeadlightRing" .. side,
		Vector3.new(0.06, 1.15, 1.15),
		CFrame.new(hx, hy, -9.13) * CYLINDER_Z,
		LED_W,
		M.Neon
	)
	cyl(
		"HeadlightLens" .. side,
		Vector3.new(0.06, 0.95, 0.95),
		CFrame.new(hx, hy, -9.15) * CYLINDER_Z,
		LENS,
		M.Glass,
		{ transparency = 0.15 }
	)
	cyl(
		"HeadlightProjector" .. side,
		Vector3.new(0.04, 0.45, 0.45),
		CFrame.new(hx, hy + 0.08, -9.18) * CYLINDER_Z,
		CHROME,
		M.Metal,
		{ reflectance = 0.3 }
	)
	block(
		"HeadlightDrl" .. side,
		Vector3.new(0.6, 0.08, 0.04),
		CFrame.new(hx, 3.5, -9.19),
		LED_W,
		M.Neon
	)

	block(
		"IndicatorPod" .. side,
		Vector3.new(0.5, 0.22, 0.75),
		CFrame.new(s * 3.3, 5.11, -8.5),
		CHROME,
		M.Metal,
		CHROME_X
	)
	block(
		"IndicatorLens" .. side,
		Vector3.new(0.36, 0.12, 0.55),
		CFrame.new(s * 3.3, 5.27, -8.5),
		AMBER,
		M.Neon,
		{ transparency = 0.1 }
	)
	block(
		"BumperDrl" .. side,
		Vector3.new(0.9, 0.12, 0.05),
		CFrame.new(s * 2.5, 2.6, -9.63),
		LED_W,
		M.Neon
	)

	block(
		"TailHousing" .. side,
		Vector3.new(0.6, 1.8, 0.08),
		CFrame.new(s * 3.43, 3.8, 8.74),
		TAIL_RED,
		M.Glass,
		{ transparency = 0.2 }
	)
	block(
		"TailBrake" .. side,
		Vector3.new(0.45, 0.6, 0.05),
		CFrame.new(s * 3.43, 4.25, 8.79),
		RED,
		M.Neon
	)
	block(
		"TailIndicator" .. side,
		Vector3.new(0.45, 0.35, 0.05),
		CFrame.new(s * 3.43, 3.6, 8.79),
		AMBER,
		M.Neon
	)
	block(
		"TailReverse" .. side,
		Vector3.new(0.45, 0.3, 0.05),
		CFrame.new(s * 3.43, 3.15, 8.79),
		REVERSE_WHITE,
		M.Glass,
		{ transparency = 0.2 }
	)
	block(
		"BumperReflector" .. side,
		Vector3.new(0.6, 0.15, 0.04),
		CFrame.new(s * 3.0, 1.95, 9.09),
		TAIL_RED,
		M.SmoothPlastic
	)
end
block("ThirdBrakeLight", Vector3.new(1.6, 0.08, 0.06), CFrame.new(0, 7.51, 8.73), RED, M.Neon)

-- Grille and front apron ---------------------------------------------------------------------

block("GrilleField", Vector3.new(3.4, 1.5, 0.05), CFrame.new(0, 3.75, -9.03), GRILLE_BLK)
for _, y in { 4.55, 2.95 } do
	block(
		"GrilleSurroundH",
		Vector3.new(3.6, 0.1, 0.08),
		CFrame.new(0, y, -9.06),
		CHROME,
		M.Metal,
		CHROME_X
	)
end
for _, s in SIDES do
	block(
		"GrilleSurroundV",
		Vector3.new(0.1, 1.7, 0.08),
		CFrame.new(s * 1.75, 3.75, -9.06),
		CHROME,
		M.Metal,
		CHROME_X
	)
end
for i = 0, 14 do
	block(
		"GrilleSlat",
		Vector3.new(0.07, 1.45, 0.1),
		CFrame.new(-1.54 + i * 0.22, 3.75, -9.08),
		CHROME,
		M.Metal,
		CHROME_X
	)
end
cyl(
	"GrilleBadge",
	Vector3.new(0.06, 0.6, 0.6),
	CFrame.new(0, 3.8, -9.15) * CYLINDER_Z,
	CHROME,
	M.Metal,
	CHROME_X
)
cyl(
	"GrilleBadgeInner",
	Vector3.new(0.04, 0.45, 0.45),
	CFrame.new(0, 3.8, -9.18) * CYLINDER_Z,
	GRILLE_BLK
)
block("BumperCenterIntake", Vector3.new(2.2, 0.55, 0.05), CFrame.new(0, 1.75, -9.62), GRILLE_BLK)
for _, s in SIDES do
	block(
		"BumperSideIntake",
		Vector3.new(1.6, 0.9, 0.05),
		CFrame.new(s * 2.5, 2.05, -9.62),
		GRILLE_BLK
	)
	for _, y in { 1.85, 2.25 } do
		block(
			"IntakeFin",
			Vector3.new(1.5, 0.06, 0.06),
			CFrame.new(s * 2.5, y, -9.66),
			ALU,
			M.Metal,
			{ reflectance = 0.1 }
		)
	end
end
block(
	"BumperLip",
	Vector3.new(6.6, 0.1, 0.12),
	CFrame.new(0, 1.45, -9.63),
	ALU,
	M.Metal,
	{ reflectance = 0.1 }
)
block("FrontPlate", Vector3.new(2.1, 0.45, 0.04), CFrame.new(0, 2.4, -9.63), PLATE)

-- Wheels -------------------------------------------------------------------------------------

for _, s in SIDES do
	for _, az in { FRONT_AXLE, REAR_AXLE } do
		local function at(x)
			return CFrame.new(s * x, WHEEL_Y, az)
		end
		cyl("Tire", Vector3.new(1.18, 3.18, 3.18), at(WHEEL_X), TIRE)
		cyl("TireSidewall", Vector3.new(0.02, 2.95, 2.95), at(3.875), rgb(36, 36, 38))
		cyl(
			"RimLip",
			Vector3.new(0.04, 2.3, 2.3),
			at(3.89),
			RIM_SILVER,
			M.Metal,
			{ reflectance = 0.15 }
		)
		cyl("RimWell", Vector3.new(0.04, 2.05, 2.05), at(3.91), RIM_DARK, M.Metal)
		cyl("BrakeDisc", Vector3.new(0.03, 1.7, 1.7), at(3.925), DISC, M.Metal)
		block(
			"Caliper",
			Vector3.new(0.03, 0.3, 0.6),
			CFrame.new(s * 3.93, WHEEL_Y + 0.6, az + 0.4) * A(math.rad(34), 0, 0),
			CALIPER_RED
		)
		for i = 0, 4 do
			block(
				"Spoke",
				Vector3.new(0.05, 0.16, 2.0),
				at(3.96) * A(math.rad(i * 36 + 18), 0, 0),
				RIM_SILVER,
				M.Metal,
				{ reflectance = 0.15 }
			)
		end
		cyl(
			"Hub",
			Vector3.new(0.06, 0.55, 0.55),
			at(3.98),
			RIM_SILVER,
			M.Metal,
			{ reflectance = 0.15 }
		)
		cyl("CenterCap", Vector3.new(0.03, 0.3, 0.3), at(4.0), CHROME, M.Metal, CHROME_X)
	end
end

-- Spare wheel on the rear door ---------------------------------------------------------------

cyl("SpareTire", Vector3.new(1.0, 3.2, 3.2), CFrame.new(0, 4.15, 9.2) * CYLINDER_Z, TIRE)
cyl(
	"SpareRing",
	Vector3.new(0.04, 3.1, 3.1),
	CFrame.new(0, 4.15, 9.70) * CYLINDER_Z,
	CHROME,
	M.Metal,
	CHROME_X
)
cyl(
	"SpareCover",
	Vector3.new(0.06, 2.95, 2.95),
	CFrame.new(0, 4.15, 9.72) * CYLINDER_Z,
	OBS,
	M.SmoothPlastic,
	GLOSS
)
cyl(
	"SpareBadge",
	Vector3.new(0.04, 0.7, 0.7),
	CFrame.new(0, 4.15, 9.76) * CYLINDER_Z,
	CHROME,
	M.Metal,
	CHROME_X
)
block("SpareBracket", Vector3.new(0.5, 0.5, 0.5), CFrame.new(0, 4.15, 8.85), TRIM_BLK)

-- Interior -----------------------------------------------------------------------------------

block("Dashboard", Vector3.new(7.0, 0.55, 0.9), CFrame.new(0, 4.78, -3.15), DASH)
block("DashPad", Vector3.new(6.9, 0.08, 0.5), CFrame.new(0, 5.0, -3.25), LEATHER_BLK, M.Fabric)
local screenCf = CFrame.new(-1.05, 5.3, -2.85) * A(math.rad(-10), 0, 0)
block("Widescreen", Vector3.new(3.2, 0.5, 0.06), screenCf, SCREEN, M.Glass, { transparency = 0.1 })
block(
	"ScreenGlow",
	Vector3.new(3.0, 0.4, 0.02),
	screenCf * CFrame.new(0, 0, 0.04),
	SCREEN_GLOW,
	M.Neon,
	{ transparency = 0.3 }
)
for _, s in SIDES do
	cyl(
		"DashVent",
		Vector3.new(0.08, 0.32, 0.32),
		CFrame.new(s * 0.25 + 0.9, 4.85, -2.68) * CYLINDER_Z,
		CHROME,
		M.Metal,
		CHROME_X
	)
end
block("GrabHandle", Vector3.new(1.2, 0.12, 0.12), CFrame.new(1.6, 5.08, -2.75), TRIM_BLK)
local wheelCf = CFrame.new(-1.65, 5.3, -2.4) * A(math.rad(-25), 0, 0) * CYLINDER_Z
cyl("SteeringRim", Vector3.new(0.1, 1.3, 1.3), wheelCf, LEATHER_BLK, M.Fabric)
cyl("SteeringHub", Vector3.new(0.12, 0.45, 0.45), wheelCf * CFrame.new(0.05, 0, 0), TRIM_BLK)
cyl("SteeringColumn", Vector3.new(0.9, 0.2, 0.2), wheelCf * CFrame.new(-0.45, 0, 0), TRIM_BLK)
block("CenterConsole", Vector3.new(1.0, 1.4, 2.8), CFrame.new(0, 3.1, -1.6), LEATHER_BLK, M.Fabric)
block(
	"GearSelector",
	Vector3.new(0.3, 0.06, 0.5),
	CFrame.new(0, 3.83, -1.9),
	CHROME,
	M.Metal,
	CHROME_X
)

for _, seat in { { -1.65, -0.9 }, { 1.65, -0.9 }, { -1.6, 2.9 }, { 1.6, 2.9 } } do
	local x, zc = seat[1], seat[2]
	block("SeatBase", Vector3.new(1.6, 0.55, 1.4), CFrame.new(x, 2.67, zc), TRIM_BLK)
	block(
		"SeatCushion",
		Vector3.new(1.9, 0.45, 1.8),
		CFrame.new(x, 3.17, zc),
		LEATHER_RED,
		M.Fabric
	)
	block(
		"SeatBack",
		Vector3.new(1.9, 2.5, 0.4),
		CFrame.new(x, 4.65, zc + 0.82) * A(math.rad(6), 0, 0),
		LEATHER_RED,
		M.Fabric
	)
	block(
		"Headrest",
		Vector3.new(1.1, 0.6, 0.35),
		CFrame.new(x, 6.3, zc + 0.98),
		LEATHER_BLK,
		M.Fabric
	)
end
for _, s in SIDES do
	block(
		"DoorCard",
		Vector3.new(0.05, 2.6, 11.6),
		CFrame.new(s * 3.42, 3.7, 2.4),
		LEATHER_BLK,
		M.Fabric
	)
end
block("CargoMat", Vector3.new(5.2, 0.05, 3.8), CFrame.new(0, 2.43, 6.3), TRIM_BLK, M.Fabric)

-- Details ------------------------------------------------------------------------------------

for _, s in SIDES do
	local side = s < 0 and "L" or "R"
	for _, hz in { -3.4, 0.65 } do
		for _, hy in { 3.0, 4.5 } do
			block(
				"DoorHinge" .. side,
				Vector3.new(0.14, 0.4, 0.32),
				CFrame.new(s * 3.82, hy, hz),
				CHROME,
				M.Metal,
				CHROME_X
			)
			cyl(
				"HingePin" .. side,
				Vector3.new(0.5, 0.08, 0.08),
				CFrame.new(s * 3.9, hy, hz - 0.12) * CYLINDER_Y,
				CHROME,
				M.Metal,
				CHROME_X
			)
		end
	end
	for _, hz in { 0.1, 3.6 } do
		block(
			"DoorHandle" .. side,
			Vector3.new(0.08, 0.14, 0.6),
			CFrame.new(s * 3.8, 4.55, hz),
			CHROME,
			M.Metal,
			CHROME_X
		)
	end
	for _, gz in { -3.45, 0.55, 3.95 } do
		block("DoorGapV" .. side, Vector3.new(0.04, 3.3, 0.04), CFrame.new(s * 3.77, 3.35, gz), GAP)
	end
	block(
		"DoorGapBottom" .. side,
		Vector3.new(0.04, 0.04, 7.4),
		CFrame.new(s * 3.77, 1.82, 0.25),
		GAP
	)
	block(
		"RubStrip" .. side,
		Vector3.new(0.05, 0.18, 7.6),
		CFrame.new(s * 3.78, 3.3, -0.45),
		TRIM_BLK
	)
	block(
		"RubStripChrome" .. side,
		Vector3.new(0.06, 0.03, 7.6),
		CFrame.new(s * 3.785, 3.4, -0.45),
		CHROME,
		M.Metal,
		CHROME_X
	)

	block(
		"MirrorArm" .. side,
		Vector3.new(0.4, 0.12, 0.25),
		CFrame.new(s * 3.85, 5.3, -3.15),
		OBS,
		M.SmoothPlastic,
		GLOSS
	)
	block(
		"MirrorHead" .. side,
		Vector3.new(0.5, 0.6, 0.3),
		CFrame.new(s * 4.2, 5.45, -3.15),
		OBS,
		M.SmoothPlastic,
		GLOSS
	)
	block(
		"MirrorGlass" .. side,
		Vector3.new(0.42, 0.5, 0.03),
		CFrame.new(s * 4.2, 5.45, -2.99),
		MIRROR_GLASS,
		M.Glass,
		{ reflectance = 0.4 }
	)
	block(
		"MirrorRepeater" .. side,
		Vector3.new(0.3, 0.05, 0.04),
		CFrame.new(s * 4.25, 5.18, -3.3),
		AMBER,
		M.Neon
	)

	block(
		"RunningBoard" .. side,
		Vector3.new(0.42, 0.14, 6.9),
		CFrame.new(s * 3.96, 1.55, -0.85),
		TRIM_BLK
	)
	for _, rx in { 3.86, 4.06 } do
		block(
			"RunningBoardStrip" .. side,
			Vector3.new(0.06, 0.03, 6.7),
			CFrame.new(s * rx, 1.635, -0.85),
			ALU,
			M.Metal,
			{ reflectance = 0.1 }
		)
	end
	block(
		"ExhaustHousing" .. side,
		Vector3.new(0.25, 0.4, 1.0),
		CFrame.new(s * 3.85, 1.35, 3.18),
		TRIM_BLK
	)
	for _, ez in { 2.95, 3.4 } do
		cyl(
			"ExhaustTip" .. side,
			Vector3.new(0.35, 0.32, 0.32),
			CFrame.new(s * 3.9, 1.35, ez),
			CHROME,
			M.Metal,
			CHROME_X
		)
		cyl(
			"ExhaustBore" .. side,
			Vector3.new(0.02, 0.22, 0.22),
			CFrame.new(s * 4.08, 1.35, ez),
			BORE
		)
	end
	block(
		"HoodShutLine" .. side,
		Vector3.new(0.04, 0.03, 5.1),
		CFrame.new(s * 2.93, 4.895, -6.15),
		GAP
	)
	block(
		"RearDoorSeam" .. side,
		Vector3.new(0.04, 3.6, 0.04),
		CFrame.new(s * 3.08, 3.7, 8.72),
		GAP
	)
end

for _, hy in { 3.4, 6.6 } do
	block(
		"RearHinge",
		Vector3.new(0.32, 0.4, 0.14),
		CFrame.new(2.95, hy, 8.78),
		CHROME,
		M.Metal,
		CHROME_X
	)
	cyl(
		"RearHingePin",
		Vector3.new(0.5, 0.08, 0.08),
		CFrame.new(3.08, hy, 8.86) * CYLINDER_Y,
		CHROME,
		M.Metal,
		CHROME_X
	)
end
block(
	"RearDoorHandle",
	Vector3.new(0.6, 0.14, 0.08),
	CFrame.new(-2.2, 4.4, 8.77),
	CHROME,
	M.Metal,
	CHROME_X
)
for _, wx in { -1.6, 1.3 } do
	block(
		"Wiper",
		Vector3.new(2.6, 0.06, 0.06),
		CFrame.new(wx, 5.07, -3.72) * A(0, 0, math.rad(4)),
		TRIM_BLK
	)
end
block("FuelDoorFrame", Vector3.new(0.03, 0.6, 0.6), CFrame.new(3.765, 4.4, 7.95), GAP)
paint("FuelDoor", Vector3.new(0.04, 0.52, 0.52), CFrame.new(3.78, 4.4, 7.95))
block("RearPlate", Vector3.new(2.1, 0.45, 0.04), CFrame.new(0, 2.05, 9.1), PLATE)
block("TowHitchCover", Vector3.new(0.5, 0.3, 0.3), CFrame.new(0, 1.45, 9.05), TRIM_BLK)

return {
	name = "Mercedes-AMG G 63",
	speed = 100,
	turnRate = 2.3,
	footprint = Vector2.new(7.6, 18.6),
	collision = {
		{ size = Vector3.new(7.8, 3.8, 19.2), offset = CFrame.new(0, 3.1, 0.1) },
		{ size = Vector3.new(7.3, 2.8, 11.8), offset = CFrame.new(0, 6.4, 2.75) },
	},
	seats = {
		CFrame.new(-1.65, 2.9, -0.9), -- driver (LHD)
		CFrame.new(1.65, 2.9, -0.9),
		CFrame.new(-1.6, 2.9, 2.9),
		CFrame.new(1.6, 2.9, 2.9),
	},
	pieces = pieces,
}
