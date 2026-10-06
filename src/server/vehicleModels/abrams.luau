-- M1 Abrams Tank: M1A2 SEP v3 main battle tank in desert tan CARC with a 120 mm gun, CROWS-LP and bustle rack.

-- Scale: 4 studs = 1 m. Hull z -15.8..15.8, gun muzzle at z -23.2.

local rgb = Color3.fromRGB
local M = Enum.Material
local A = CFrame.Angles
local CYL = Enum.PartType.Cylinder
local CYLINDER_Z = A(0, math.rad(90), 0)
local CYLINDER_Y = A(0, 0, math.rad(90))

-- Wedge orientations (WedgePart default: right angle at local (ymin, zmax), slope rises toward +Z).
local FLIP_Z = A(0, 0, math.pi) -- right angle at (ymax, zmax)
local FLIP_X = A(math.pi, 0, 0) -- right angle at (ymax, zmin)
local SIDE_R = A(0, -math.pi / 2, 0) -- length along Z, solid side facing -X
local SIDE_L = A(0, math.pi / 2, 0) -- length along Z, solid side facing +X

local CARC_TAN = rgb(194, 170, 124)
local TAN_LIGHT = rgb(206, 184, 140)
local TAN_SHADE = rgb(168, 146, 104)
local SLEEVE = rgb(186, 162, 116)
local TRACK_RUBBER = rgb(40, 38, 35)
local TRACK_STEEL = rgb(72, 68, 62)
local WHEEL_RUBBER = rgb(30, 30, 30)
local GUN_BLACK = rgb(38, 38, 40)
local BORE = rgb(8, 8, 8)
local HATCH_DARK = rgb(18, 18, 18)
local GRILLE_DARK = rgb(28, 26, 24)
local OPTIC_GLASS = rgb(22, 34, 40)
local PERISCOPE = rgb(40, 58, 62)
local OD_GREEN = rgb(88, 90, 58)
local TARP = rgb(112, 100, 72)
local HEADLIGHT = rgb(255, 238, 200)
local TAILLIGHT = rgb(190, 28, 22)
local AMBER = rgb(230, 140, 30)
local ANTENNA = rgb(30, 30, 30)
local WOOD = rgb(120, 90, 60)

local pieces = {}

local function v(x, y, z)
	return Vector3.new(x, y, z)
end

local function add(spec)
	spec.material = spec.material or M.SmoothPlastic
	table.insert(pieces, spec)
	return spec
end

local function box(name, size, offset, color, material, extra)
	local spec =
		add({ name = name, size = size, offset = offset, color = color, material = material })
	if extra then
		for k, val in extra do
			spec[k] = val
		end
	end
	return spec
end

local function wedge(name, size, offset, color, material)
	return add({
		name = name,
		class = "WedgePart",
		size = size,
		offset = offset,
		color = color,
		material = material,
	})
end

local function cyl(name, size, offset, color, material, extra)
	local spec = box(name, size, offset, color, material, extra)
	spec.shape = CYL
	return spec
end

local function glass(name, size, offset, color, reflectance)
	return box(
		name,
		size,
		offset,
		color,
		M.Glass,
		{ reflectance = reflectance, transparency = 0.1 }
	)
end

-- Running gear ------------------------------------------------------------------------------

for side = -1, 1, 2 do
	local x = side * 5.73
	local s = side > 0 and "R" or "L"

	box("TrackBottom" .. s, v(2.54, 0.32, 19.2), CFrame.new(x, 0.16, 0), TRACK_RUBBER, M.Fabric)
	box(
		"TrackFront" .. s,
		v(2.54, 0.32, 4.4),
		CFrame.new(x, 0.6, -11.7) * A(math.rad(12), 0, 0),
		TRACK_RUBBER,
		M.Fabric
	)
	box(
		"TrackRear" .. s,
		v(2.54, 0.32, 4.4),
		CFrame.new(x, 0.75, 11.7) * A(math.rad(-16), 0, 0),
		TRACK_RUBBER,
		M.Fabric
	)
	box("TrackTop" .. s, v(2.54, 0.3, 26.8), CFrame.new(x, 4.2, 0.2), TRACK_RUBBER, M.Fabric)
	cyl(
		"IdlerWrap" .. s,
		v(2.0, 3.1, 3.1),
		CFrame.new(side * 5.46, 2.4, -13.2),
		TRACK_RUBBER,
		M.Fabric
	)
	cyl(
		"SprocketWrap" .. s,
		v(2.0, 3.2, 3.2),
		CFrame.new(side * 5.46, 2.9, 13.6),
		TRACK_RUBBER,
		M.Fabric
	)

	for i = 0, 11 do
		box(
			"EndConnector" .. s,
			v(0.12, 0.38, 0.5),
			CFrame.new(side * 7.04, 0.19, -8.8 + i * 1.6),
			TRACK_STEEL,
			M.Metal
		)
	end

	for i = 0, 6 do
		local z = -8.55 + i * 2.85
		cyl("RoadWheel" .. s, v(0.7, 2.54, 2.54), CFrame.new(side * 6.45, 1.57, z), WHEEL_RUBBER)
		cyl("RoadWheelDisc" .. s, v(0.08, 2.0, 2.0), CFrame.new(side * 6.84, 1.57, z), CARC_TAN)
		cyl(
			"RoadWheelHub" .. s,
			v(0.18, 0.8, 0.8),
			CFrame.new(side * 6.97, 1.57, z),
			TAN_SHADE,
			M.Metal
		)
	end

	cyl("Idler" .. s, v(0.7, 2.4, 2.4), CFrame.new(side * 6.45, 2.4, -13.2), WHEEL_RUBBER)
	cyl("IdlerDisc" .. s, v(0.08, 1.9, 1.9), CFrame.new(side * 6.84, 2.4, -13.2), CARC_TAN)
	cyl("IdlerHub" .. s, v(0.18, 0.7, 0.7), CFrame.new(side * 6.97, 2.4, -13.2), TAN_SHADE, M.Metal)

	cyl(
		"SprocketRing" .. s,
		v(0.4, 2.6, 2.6),
		CFrame.new(side * 6.66, 2.9, 13.6),
		CARC_TAN,
		M.Metal
	)
	for k = 0, 9 do
		if k ~= 4 and k ~= 5 then
			local a = math.rad(18 + k * 36)
			box(
				"SprocketTooth" .. s,
				v(0.4, 0.35, 0.42),
				CFrame.new(side * 6.66, 2.9, 13.6) * A(a, 0, 0) * CFrame.new(0, 1.42, 0),
				TRACK_STEEL,
				M.Metal
			)
		end
	end
	cyl(
		"SprocketHub" .. s,
		v(0.3, 1.2, 1.2),
		CFrame.new(side * 6.98, 2.9, 13.6),
		TAN_SHADE,
		M.Metal
	)
	cyl("FinalDrive" .. s, v(0.9, 1.8, 1.8), CFrame.new(side * 4.1, 2.9, 13.6), TAN_SHADE)
end

-- Skirts and fenders ------------------------------------------------------------------------

for side = -1, 1, 2 do
	local s = side > 0 and "R" or "L"
	wedge(
		"SkirtNose" .. s,
		v(0.32, 4.3, 1.8),
		CFrame.new(side * 7.29, 3.75, -14.3) * FLIP_Z,
		CARC_TAN
	)
	box("SkirtHeavyA" .. s, v(0.32, 4.3, 4.74), CFrame.new(side * 7.29, 3.75, -11.0), CARC_TAN)
	box("SkirtHeavyB" .. s, v(0.32, 4.3, 4.14), CFrame.new(side * 7.29, 3.75, -6.5), CARC_TAN)
	for i = 0, 4 do
		box(
			"SkirtPanel" .. s,
			v(0.22, 4.0, 3.22),
			CFrame.new(side * 7.24, 3.9, -2.76 + i * 3.28),
			CARC_TAN
		)
	end
	box("FenderLip" .. s, v(0.5, 0.2, 27.2), CFrame.new(side * 7.15, 6.0, -1.6), TAN_SHADE)
	box("RearFender" .. s, v(2.54, 1.6, 1.8), CFrame.new(side * 5.73, 5.6, 14.9), CARC_TAN)
	box("FrontFender" .. s, v(2.54, 0.4, 3.8), CFrame.new(side * 5.73, 4.8, -13.9), CARC_TAN)
end

-- Hull --------------------------------------------------------------------------------------

local GLACIS_TILT = A(math.rad(10.2), 0, 0)

box("LowerHull", v(8.6, 4.0, 28.6), CFrame.new(0, 3.9, 1.3), TAN_SHADE)
box("Deck", v(14.0, 0.5, 23.6), CFrame.new(0, 6.15, 3.8), CARC_TAN)
wedge("UpperGlacis", v(14.0, 1.4, 7.8), CFrame.new(0, 5.7, -11.9), CARC_TAN)
box("GlacisUnderfill", v(8.6, 0.4, 7.8), CFrame.new(0, 4.8, -11.9), TAN_SHADE)
wedge("LowerGlacis", v(8.6, 2.4, 2.2), CFrame.new(0, 3.8, -14.7) * FLIP_Z, CARC_TAN)
box("LowerGlacisFill", v(8.6, 2.4, 0.6), CFrame.new(0, 3.8, -13.3), CARC_TAN)

box("DriverHatchPlate", v(3.4, 0.2, 3.4), CFrame.new(0, 6.05, -10.4) * GLACIS_TILT, TAN_LIGHT)
box("DriverHatchOpening", v(2.2, 0.05, 2.2), CFrame.new(0, 6.17, -10.4) * GLACIS_TILT, HATCH_DARK)
cyl("DriverHatchLid", v(0.2, 2.2, 2.2), CFrame.new(2.1, 6.3, -10.4) * CYLINDER_Y, CARC_TAN)
for i = -1, 1 do
	glass(
		"DriverPeriscope",
		v(0.7, 0.3, 0.25),
		CFrame.new(i * 0.8, 6.12, -11.75) * A(0, math.rad(-12 * i), 0),
		PERISCOPE,
		0.3
	)
end

for side = -1, 1, 2 do
	box("HeadlightHousing", v(1.4, 0.7, 0.6), CFrame.new(side * 5.8, 5.42, -15.4), CARC_TAN)
	cyl(
		"HeadlightLens",
		v(0.06, 0.45, 0.45),
		CFrame.new(side * 6.1, 5.45, -15.72) * CYLINDER_Z,
		HEADLIGHT,
		M.Neon
	)
	box("BlackoutLamp", v(0.3, 0.2, 0.05), CFrame.new(side * 5.4, 5.45, -15.72), TAILLIGHT, M.Neon)
	for _, tx in { 2.4, 3.2 } do
		box("FrontTowLug", v(0.3, 0.5, 0.5), CFrame.new(side * tx, 3.4, -14.45), TAN_SHADE)
	end
end

box("RearPlate", v(8.6, 4.0, 0.3), CFrame.new(0, 4.4, 15.65), CARC_TAN)
box("ExhaustGrille", v(6.4, 2.6, 0.05), CFrame.new(0, 4.4, 15.83), GRILLE_DARK)
for i = 0, 5 do
	box(
		"ExhaustSlat",
		v(6.2, 0.12, 0.3),
		CFrame.new(0, 3.4 + i * 0.4, 15.9) * A(math.rad(-30), 0, 0),
		TAN_SHADE
	)
end
wedge("RearBellyChamfer", v(8.6, 0.5, 0.8), CFrame.new(0, 2.15, 15.4) * FLIP_X, TAN_SHADE)
for side = -1, 1, 2 do
	box("TailHousing", v(0.7, 0.5, 0.06), CFrame.new(side * 6.3, 5.7, 15.82), CARC_TAN)
	box(
		"TailLamp",
		v(0.22, 0.22, 0.04),
		CFrame.new(side * 6.3 - 0.15, 5.7, 15.86),
		TAILLIGHT,
		M.Neon
	)
	box(
		"IndicatorLamp",
		v(0.22, 0.22, 0.04),
		CFrame.new(side * 6.3 + 0.15, 5.7, 15.86),
		AMBER,
		M.Neon
	)
	box("RearTowHook", v(0.4, 0.6, 0.5), CFrame.new(side * 3.4, 2.8, 15.95), TAN_SHADE)
	box("DeckGrille", v(4.6, 0.05, 6.0), CFrame.new(side * 3.2, 6.43, 12.0), GRILLE_DARK)
	for _, z in { 10.4, 12.0, 13.6, 14.8 } do
		box("DeckGrilleSlat", v(4.4, 0.08, 0.2), CFrame.new(side * 3.2, 6.47, z), TAN_SHADE)
	end
	cyl("FuelCap", v(0.12, 0.7, 0.7), CFrame.new(side * 6.0, 6.46, 6.8) * CYLINDER_Y, TAN_SHADE)
end
box("TowPintle", v(0.6, 0.6, 0.6), CFrame.new(0, 2.8, 15.95), GUN_BLACK, M.Metal)
cyl("TurretRingShadow", v(0.3, 9.4, 9.4), CFrame.new(0, 6.5, -0.6) * CYLINDER_Y, HATCH_DARK)
box("InfantryPhone", v(0.6, 0.8, 0.3), CFrame.new(5.6, 5.4, 15.9), OD_GREEN, M.Fabric)
box("ShovelHandle", v(0.15, 0.08, 3.4), CFrame.new(-6.4, 6.44, 4.0), WOOD, M.Wood)
box("PickBar", v(0.15, 0.08, 3.4), CFrame.new(6.4, 6.44, 4.0), GUN_BLACK, M.Metal)

-- Turret shell ------------------------------------------------------------------------------

box("TurretCore", v(11.8, 2.8, 10.4), CFrame.new(0, 8.0, 0.4), CARC_TAN)
box("TurretFront", v(8.8, 2.2, 3.0), CFrame.new(0, 8.3, -6.3), CARC_TAN)
wedge("TurretUndercut", v(8.8, 0.6, 1.2), CFrame.new(0, 6.9, -7.2) * FLIP_Z, TAN_SHADE)
box("TurretLowerFill", v(8.8, 0.6, 1.8), CFrame.new(0, 6.9, -5.7), TAN_SHADE)
box("TurretRoof", v(11.2, 0.35, 15.4), CFrame.new(0, 9.575, 2.9), TAN_LIGHT)
box("TurretRoofFront", v(8.8, 0.35, 2.8), CFrame.new(0, 9.575, -6.2), TAN_LIGHT)
box("Bustle", v(10.4, 2.5, 5.0), CFrame.new(0, 8.15, 8.1), CARC_TAN)
wedge("BustleChamfer", v(10.4, 0.6, 1.2), CFrame.new(0, 7.2, 10.0) * FLIP_X, TAN_SHADE)

for side = -1, 1, 2 do
	wedge(
		"TurretCheek",
		v(2.8, 1.5, 3.0),
		CFrame.new(side * 5.15, 8.0, -6.3) * A(0, 0, math.rad(-90 * side)),
		CARC_TAN
	)
	wedge(
		"RoofCheek",
		v(0.35, 1.2, 2.8),
		CFrame.new(side * 5.0, 9.575, -6.2) * A(0, 0, math.rad(-90 * side)),
		TAN_LIGHT
	)
	wedge(
		"RoofChamfer",
		v(10.4, 0.5, 0.6),
		CFrame.new(side * 5.6, 9.15, 0.4) * (side > 0 and SIDE_R or SIDE_L),
		CARC_TAN
	)
	box("SideApplique", v(0.2, 2.2, 8.0), CFrame.new(side * 6.0, 8.0, 0.0), CARC_TAN)
	box("AppliqueSeam", v(0.04, 2.0, 0.08), CFrame.new(side * 6.12, 8.0, -2.0), TAN_SHADE)
	box("BustleBox", v(0.9, 1.6, 4.0), CFrame.new(side * 5.65, 8.1, 8.0), CARC_TAN)
	box("BustleBoxLatch", v(0.06, 0.25, 0.4), CFrame.new(side * 6.12, 8.6, 8.0), TAN_SHADE)
	box("BlowOffPanel", v(4.2, 0.05, 3.6), CFrame.new(side * 2.4, 9.77, 8.0), TAN_SHADE)
end

-- Mantlet and 120 mm gun --------------------------------------------------------------------

local GUN_Y = 8.2
local function barrel(name, length, diameter, z, color, material)
	cyl(name, v(length, diameter, diameter), CFrame.new(0, GUN_Y, z) * CYLINDER_Z, color, material)
end

box("GunShield", v(4.0, 2.4, 0.6), CFrame.new(0, GUN_Y, -7.95), TAN_SHADE)
barrel("MantletSleeve", 1.2, 2.0, -8.6, CARC_TAN)
barrel("RootCollar", 1.0, 1.6, -9.6, CARC_TAN, M.Metal)
barrel("SleeveSection1", 4.0, 1.28, -12.1, SLEEVE, M.Fabric)
for _, z in { -11.0, -14.0, -19.0, -21.1 } do
	barrel("ClampBand", 0.2, 1.38, z, TAN_SHADE, M.Metal)
end
barrel("EvacuatorTaper", 0.3, 1.45, -14.25, SLEEVE, M.Fabric)
barrel("EvacuatorTaper", 0.3, 1.45, -16.75, SLEEVE, M.Fabric)
barrel("BoreEvacuator", 2.2, 1.6, -15.5, SLEEVE, M.Fabric)
barrel("SleeveSection2", 4.2, 1.2, -19.0, SLEEVE, M.Fabric)
barrel("Muzzle", 2.1, 1.12, -22.15, CARC_TAN, M.Metal)
barrel("Bore", 0.1, 0.48, -23.22, BORE)
box("MuzzleReferenceSensor", v(0.5, 0.4, 0.7), CFrame.new(0, 8.95, -22.6), CARC_TAN)
cyl("CoaxPort", v(0.4, 0.25, 0.25), CFrame.new(1.6, 8.0, -8.3) * CYLINDER_Z, GUN_BLACK, M.Metal)

-- Gunner's primary sight --------------------------------------------------------------------

box("GpsBase", v(2.2, 1.0, 2.4), CFrame.new(3.6, 10.25, -6.0), CARC_TAN)
wedge("GpsLowerChamfer", v(2.2, 0.45, 0.6), CFrame.new(3.6, 9.975, -7.5), CARC_TAN)
box("GpsSunHood", v(2.2, 0.1, 0.7), CFrame.new(3.6, 10.7, -7.55), CARC_TAN)
glass("GpsWindow", v(1.6, 0.5, 0.05), CFrame.new(3.6, 10.3, -7.22), OPTIC_GLASS, 0.25)
box("GpsTop", v(2.3, 0.08, 2.5), CFrame.new(3.6, 10.79, -6.0), TAN_LIGHT)

-- Commander's independent thermal viewer ----------------------------------------------------

cyl("CitvPedestal", v(0.8, 1.0, 1.0), CFrame.new(-3.6, 10.15, -5.6) * CYLINDER_Y, CARC_TAN)
box("CitvHead", v(1.4, 1.1, 1.4), CFrame.new(-3.6, 11.1, -5.6), CARC_TAN)
glass("CitvWindow", v(0.9, 0.5, 0.05), CFrame.new(-3.6, 11.1, -6.32), OPTIC_GLASS, 0.25)
box("CitvCap", v(1.5, 0.1, 1.5), CFrame.new(-3.6, 11.7, -5.6), TAN_LIGHT)

-- Commander's and loader's hatches ----------------------------------------------------------

for side = -1, 1, 2 do
	local hx = side * 3.2
	cyl("HatchRing", v(0.35, 3.4, 3.4), CFrame.new(hx, 9.92, 0.8) * CYLINDER_Y, TAN_SHADE)
	cyl("HatchOpening", v(0.05, 2.8, 2.8), CFrame.new(hx, 10.1, 0.8) * CYLINDER_Y, HATCH_DARK)
	cyl("HatchLid", v(0.2, 2.8, 2.8), CFrame.new(hx, 11.5, 2.65) * CYLINDER_Z, CARC_TAN)
end

for i = 0, 4 do
	local a = math.rad(-150 + i * 30)
	local px, pz = 3.2 + math.cos(a) * 1.75, 0.8 + math.sin(a) * 1.75
	glass(
		"CupolaVisionBlock",
		v(0.5, 0.3, 0.2),
		CFrame.new(px, 10.0, pz) * A(0, -a - math.pi / 2, 0),
		PERISCOPE,
		0.3
	)
end

-- CROWS-LP remote weapon station ------------------------------------------------------------

cyl("CrowsTurntable", v(0.3, 1.6, 1.6), CFrame.new(3.4, 9.9, -2.6) * CYLINDER_Y, TAN_SHADE)
box("CrowsPedestal", v(0.8, 0.9, 0.8), CFrame.new(3.4, 10.5, -2.6), CARC_TAN)
box("CrowsCradle", v(1.0, 0.7, 2.2), CFrame.new(3.4, 11.2, -2.6), CARC_TAN)
box("M2Receiver", v(0.55, 0.6, 1.6), CFrame.new(3.0, 11.2, -3.2), GUN_BLACK, M.Metal)
cyl("M2Barrel", v(4.4, 0.28, 0.28), CFrame.new(3.0, 11.2, -6.2) * CYLINDER_Z, GUN_BLACK, M.Metal)
cyl("M2Shroud", v(1.0, 0.42, 0.42), CFrame.new(3.0, 11.2, -4.5) * CYLINDER_Z, GUN_BLACK, M.Metal)
cyl(
	"M2FlashHider",
	v(0.3, 0.36, 0.36),
	CFrame.new(3.0, 11.2, -8.5) * CYLINDER_Z,
	GUN_BLACK,
	M.Metal
)
box("CrowsSensor", v(0.8, 0.8, 1.0), CFrame.new(4.2, 11.4, -2.9), CARC_TAN)
glass("CrowsLens", v(0.3, 0.3, 0.04), CFrame.new(4.05, 11.45, -3.42), OPTIC_GLASS, 0.25)
glass("CrowsLens", v(0.3, 0.3, 0.04), CFrame.new(4.4, 11.45, -3.42), OPTIC_GLASS, 0.25)
box("CrowsAmmoCan", v(0.55, 0.8, 1.0), CFrame.new(2.4, 11.0, -2.4), OD_GREEN, M.Fabric)

-- Loader's armored gun shield and M240 ------------------------------------------------------

box("LagsFront", v(2.8, 1.6, 0.15), CFrame.new(-3.2, 11.0, -0.9), CARC_TAN)
box("LagsSide", v(0.15, 1.4, 1.2), CFrame.new(-4.6, 10.9, -0.4) * A(0, math.rad(20), 0), CARC_TAN)
box("LagsSide", v(0.15, 1.4, 1.2), CFrame.new(-1.8, 10.9, -0.4) * A(0, math.rad(-20), 0), CARC_TAN)
box("M240Receiver", v(0.3, 0.4, 1.4), CFrame.new(-3.2, 11.1, -1.6), GUN_BLACK, M.Metal)
cyl("M240Barrel", v(2.2, 0.18, 0.18), CFrame.new(-3.2, 11.1, -3.4) * CYLINDER_Z, GUN_BLACK, M.Metal)

-- Smoke grenade launchers -------------------------------------------------------------------

for side = -1, 1, 2 do
	local base = CFrame.new(side * 6.35, 8.9, -4.2)
	box("SmokeBase", v(0.6, 0.6, 1.5), base, TAN_SHADE)
	for row = 0, 1 do
		for col = -1, 1 do
			cyl(
				"SmokeTube",
				v(0.7, 0.32, 0.32),
				base
					* CFrame.new(side * 0.1, 0.3 + row * 0.38, col * 0.45)
					* A(0, 0, math.rad(side * 35)),
				GUN_BLACK,
				M.Metal
			)
		end
	end
end

-- Bustle rack and stowage -------------------------------------------------------------------

local RAIL = TAN_SHADE
box("RackFloor", v(11.2, 0.12, 2.8), CFrame.new(0, 7.26, 12.0), GRILLE_DARK)
box("RackRearTop", v(11.2, 0.15, 0.15), CFrame.new(0, 9.35, 13.35), RAIL, M.Metal)
box("RackRearMid", v(11.2, 0.15, 0.15), CFrame.new(0, 8.3, 13.35), RAIL, M.Metal)
for _, rx in { -5.5, -2.75, 0, 2.75, 5.5 } do
	box("RackUpright", v(0.15, 2.1, 0.15), CFrame.new(rx, 8.3, 13.35), RAIL, M.Metal)
end
for side = -1, 1, 2 do
	box("RackSideTop", v(0.15, 0.15, 7.6), CFrame.new(side * 5.6, 9.35, 9.6), RAIL, M.Metal)
	box("RackSideMid", v(0.15, 0.15, 7.6), CFrame.new(side * 5.6, 8.3, 9.6), RAIL, M.Metal)
end
box(
	"DuffelBag",
	v(2.6, 1.3, 1.8),
	CFrame.new(-3.6, 7.95, 12.1) * A(0, math.rad(6), 0),
	OD_GREEN,
	M.Fabric
)
box(
	"DuffelBag",
	v(2.6, 1.3, 1.8),
	CFrame.new(-0.6, 7.95, 12.0) * A(0, math.rad(-4), 0),
	OD_GREEN,
	M.Fabric
)
cyl("TarpRoll", v(5.0, 1.0, 1.0), CFrame.new(3.0, 7.85, 12.3), TARP, M.Fabric)
box("RackAmmoCan", v(1.0, 0.8, 0.6), CFrame.new(4.0, 8.85, 12.5), OD_GREEN, M.Fabric)

-- Antennas and sensors ----------------------------------------------------------------------

for side = -1, 1, 2 do
	cyl("AntennaBase", v(0.3, 0.5, 0.5), CFrame.new(side * 4.6, 9.9, 5.4) * CYLINDER_Y, TAN_SHADE)
	cyl("AntennaWhip", v(6.0, 0.1, 0.1), CFrame.new(side * 4.6, 13.0, 5.4) * CYLINDER_Y, ANTENNA)
end
cyl("WindSensorMast", v(1.6, 0.14, 0.14), CFrame.new(0, 10.55, 4.6) * CYLINDER_Y, TAN_SHADE)
box("WindSensorBar", v(0.8, 0.1, 0.1), CFrame.new(0, 11.35, 4.6), TAN_SHADE)
cyl("CrewDukeDome", v(0.5, 1.2, 1.2), CFrame.new(-2.2, 10.0, 6.5) * CYLINDER_Y, TAN_LIGHT)

return {
	name = "M1 Abrams Tank",
	-- Real: 68 km/h, 0-32 km/h in 7.2 s, brakes 0.55 g, coasts 0.12 g (VehicleDefaults maps them).
	speed = 35,
	acceleration = 4.2,
	braking = 11.3,
	coasting = 4.1,
	turnRate = 1.6,
	footprint = Vector2.new(14.6, 31.6),
	collision = {
		{ size = v(14.4, 4.4, 31.0), offset = CFrame.new(0, 4.1, 0) }, -- hull y 1.9..6.3
		{ size = v(11.6, 3.0, 14.4), offset = CFrame.new(0, 8.2, -1.0) }, -- turret y 6.7..9.7
		{ size = v(10.8, 2.6, 7.2), offset = CFrame.new(0, 8.3, 9.8) }, -- bustle and rack
	},
	seats = {
		CFrame.new(0, 2.8, -10.4), -- driver, head out of the hull hatch
		CFrame.new(3.2, 7.5, 0.8), -- commander, right hatch
		CFrame.new(-3.2, 7.5, 0.8), -- loader, left hatch
		CFrame.new(-4.2, 6.9, 14.6) * A(0, math.pi, 0), -- riders on the rear deck, facing aft
		CFrame.new(0, 6.9, 14.6) * A(0, math.pi, 0),
		CFrame.new(4.2, 6.9, 14.6) * A(0, math.pi, 0),
	},
	pieces = pieces,
}
