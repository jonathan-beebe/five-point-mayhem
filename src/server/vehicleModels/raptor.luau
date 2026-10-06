-- Ford F-150 Raptor: Gen 3 SuperCrew off-road pickup in Code Orange on 37 in all-terrain tires.

local rgb = Color3.fromRGB
local M = Enum.Material
local A = CFrame.Angles
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball
local WEDGE = "WedgePart"

-- Rotations. Cylinder axis is local X; WedgePart default has its right angle at (ymin, zmax).
local CYLINDER_Z = A(0, math.rad(90), 0)
local CYLINDER_Y = A(0, 0, math.rad(90))
local FLIP_Z = A(0, 0, math.pi) -- full top + full back face; underside slopes
local FLIP_X = A(math.pi, 0, 0) -- full top + full front face; right angle at (ymax, zmin)
local REVERSE = A(0, math.pi, 0) -- slope rises toward -Z
local SIDE_L = A(0, math.rad(90), 0) -- length along Z, slope rises toward +X
local SIDE_R = A(0, -math.rad(90), 0) -- length along Z, slope rises toward -X

-- Scale: 4 studs = 1 m.
local ORANGE = rgb(236, 98, 22)
local TRIM_BLACK = rgb(32, 32, 34)
local FLARE_BLACK = rgb(28, 28, 30)
local GLOSS_BLACK = rgb(16, 16, 18)
local GAP_BLACK = rgb(8, 8, 10)
local GRILLE_BLACK = rgb(20, 20, 22)
local LETTER_GRAY = rgb(72, 74, 78)
local SKID_SILVER = rgb(128, 130, 134)
local GLASS = rgb(30, 38, 45)
local HEAD_WHITE = rgb(255, 244, 220)
local DRL_WHITE = rgb(235, 245, 255)
local AMBER = rgb(255, 150, 20)
local TAIL_RED = rgb(210, 15, 15)
local TAIL_DARK = rgb(110, 10, 12)
local RUBBER = rgb(26, 26, 28)
local TREAD = rgb(34, 34, 36)
local WHEEL_DARK = rgb(36, 36, 40)
local WHEEL_GRAY = rgb(88, 90, 96)
local WHEEL_RING = rgb(60, 60, 66)
local FRAME = rgb(20, 20, 22)
local SHOCK = rgb(40, 40, 44)
local EXHAUST = rgb(85, 85, 90)
local BEDLINER = rgb(24, 24, 26)
local DASH = rgb(28, 28, 30)
local INTERIOR_DARK = rgb(30, 30, 32)
local SEAT_BLACK = rgb(36, 36, 38)
local SCREEN = rgb(60, 110, 160)
local PLATE_WHITE = rgb(232, 232, 232)

local PAINT = M.SmoothPlastic
local PAINT_GLOSS = 0.1

local HOOD_PITCH = A(math.rad(-2.35), 0, 0)
local WINDSHIELD_PITCH = A(math.rad(-50.6), 0, 0)

local FRONT_AXLE_Z = -7.85
local REAR_AXLE_Z = 6.9
local WHEEL_Y = 1.94
local TRACK_X = 3.65

local pieces = {}

local function add(p)
	table.insert(pieces, p)
end

-- Calls fn once per side: s = -1 (left, driver) and s = 1 (right).
local function sides(fn)
	fn(-1)
	fn(1)
end

-- Wedge orientation whose slope rises toward the vehicle's centerline.
local function inward(s)
	return s < 0 and SIDE_L or SIDE_R
end

local function paint(name, size, offset)
	add({
		name = name,
		size = size,
		offset = offset,
		color = ORANGE,
		material = PAINT,
		reflectance = PAINT_GLOSS,
	})
end

local function glass(name, size, offset, class)
	add({
		name = name,
		class = class,
		size = size,
		offset = offset,
		color = GLASS,
		material = M.Glass,
		transparency = 0.4,
		reflectance = 0.15,
	})
end

local function neon(name, size, offset, color)
	add({ name = name, size = size, offset = offset, color = color, material = M.Neon })
end

-- Front clip and hood ---------------------------------------------------------------------

add({
	name = "EngineBay",
	size = Vector3.new(6.0, 2.9, 6.1),
	offset = CFrame.new(0, 4.45, -8.25),
	color = ORANGE,
	material = PAINT,
})
paint("Hood", Vector3.new(7.7, 0.3, 6.1), CFrame.new(0, 5.72, -8.25) * HOOD_PITCH)
add({
	name = "HoodNose",
	class = WEDGE,
	size = Vector3.new(7.7, 0.3, 0.3),
	offset = CFrame.new(0, 5.6, -11.45),
	color = ORANGE,
	material = PAINT,
	reflectance = PAINT_GLOSS,
})
paint("PowerDome", Vector3.new(2.8, 0.14, 4.6), CFrame.new(0, 5.95, -8.0) * HOOD_PITCH)
add({
	name = "PowerDomeNose",
	class = WEDGE,
	size = Vector3.new(2.8, 0.14, 0.4),
	offset = CFrame.new(0, 5.91, -10.5) * HOOD_PITCH,
	color = ORANGE,
	material = PAINT,
	reflectance = PAINT_GLOSS,
})

sides(function(s)
	local x = s * 2.3
	add({
		name = "HoodVent",
		size = Vector3.new(1.4, 0.06, 1.1),
		offset = CFrame.new(x, 5.88, -9.9) * HOOD_PITCH,
		color = TRIM_BLACK,
	})
	for _, z in { -10.25, -9.9, -9.55 } do
		add({
			name = "HoodVentSlat",
			size = Vector3.new(1.3, 0.05, 0.08),
			offset = CFrame.new(x, 5.93, z) * HOOD_PITCH,
			color = GLOSS_BLACK,
			reflectance = 0.08,
		})
	end

	paint("FenderUpper", Vector3.new(1.0, 1.6, 6.1), CFrame.new(s * 3.5, 5.05, -8.25))
	paint("FenderNose", Vector3.new(1.0, 1.4, 1.15), CFrame.new(s * 3.5, 3.55, -10.72))
	paint("FenderTail", Vector3.new(1.0, 2.05, 0.4), CFrame.new(s * 3.5, 3.225, -5.4))

	add({
		name = "FenderVent",
		size = Vector3.new(0.05, 0.6, 0.7),
		offset = CFrame.new(s * 4.02, 4.9, -5.75),
		color = TRIM_BLACK,
	})
	for _, y in { 4.75, 5.05 } do
		add({
			name = "FenderVentSlat",
			size = Vector3.new(0.06, 0.06, 0.6),
			offset = CFrame.new(s * 4.05, y, -5.75),
			color = GLOSS_BLACK,
		})
	end
end)

add({
	name = "Cowl",
	size = Vector3.new(7.0, 0.08, 0.4),
	offset = CFrame.new(0, 6.03, -5.05),
	color = TRIM_BLACK,
})
add({
	name = "WiperL",
	size = Vector3.new(2.4, 0.05, 0.08),
	offset = CFrame.new(-1.4, 6.12, -4.95) * A(0, 0, math.rad(4)),
	color = GLOSS_BLACK,
})
add({
	name = "WiperR",
	size = Vector3.new(2.4, 0.05, 0.08),
	offset = CFrame.new(1.0, 6.12, -4.95) * A(0, 0, math.rad(-4)),
	color = GLOSS_BLACK,
})

-- Cab: hollow shell of door panels, floor, firewall and back wall -------------------------

sides(function(s)
	paint("FrontDoor", Vector3.new(0.3, 3.7, 5.95), CFrame.new(s * 3.85, 4.05, -2.225))
	paint("RearDoor", Vector3.new(0.3, 3.7, 3.45), CFrame.new(s * 3.85, 4.05, 2.475))
	for _, z in { -5.2, 0.75, 4.2 } do
		add({
			name = "DoorGap",
			size = Vector3.new(0.04, 3.5, 0.05),
			offset = CFrame.new(s * 4.01, 4.05, z),
			color = GAP_BLACK,
		})
	end
	for _, z in { 0.25, 3.7 } do
		add({
			name = "DoorHandle",
			size = Vector3.new(0.06, 0.18, 0.55),
			offset = CFrame.new(s * 4.03, 5.35, z),
			color = TRIM_BLACK,
		})
	end
	add({
		name = "RockerCladding",
		size = Vector3.new(0.08, 0.5, 9.4),
		offset = CFrame.new(s * 4.02, 2.45, -0.5),
		color = TRIM_BLACK,
	})
	add({
		name = "RunningBoard",
		size = Vector3.new(0.5, 0.18, 8.6),
		offset = CFrame.new(s * 4.3, 2.0, -0.5),
		color = TRIM_BLACK,
		material = M.Metal,
	})
	for _, z in { -3.5, 2.5 } do
		add({
			name = "BoardBracket",
			size = Vector3.new(0.5, 0.35, 0.25),
			offset = CFrame.new(s * 4.1, 2.2, z),
			color = FRAME,
		})
	end

	add({
		name = "BeltShoulder",
		class = WEDGE,
		size = Vector3.new(9.4, 0.12, 0.34),
		offset = CFrame.new(s * 3.83, 5.96, -0.5) * inward(s),
		color = ORANGE,
		material = PAINT,
		reflectance = PAINT_GLOSS,
	})
	add({
		name = "RoofChamfer",
		class = WEDGE,
		size = Vector3.new(8.05, 0.18, 0.3),
		offset = CFrame.new(s * 3.62, 7.95, 0.175) * inward(s),
		color = ORANGE,
		material = PAINT,
		reflectance = PAINT_GLOSS,
	})
	paint(
		"APillar",
		Vector3.new(0.28, 0.25, 2.55),
		CFrame.new(s * 3.6, 6.98, -4.4) * WINDSHIELD_PITCH
	)
	add({
		name = "BPillar",
		size = Vector3.new(0.24, 1.95, 0.3),
		offset = CFrame.new(s * 3.68, 6.92, 0.75),
		color = GLOSS_BLACK,
		reflectance = 0.08,
	})
	paint("CPillar", Vector3.new(0.3, 1.95, 0.45), CFrame.new(s * 3.7, 6.92, 3.98))
	paint("RearWindowSide", Vector3.new(0.4, 1.95, 0.25), CFrame.new(s * 3.4, 6.92, 4.1))
end)

add({
	name = "CabFloor",
	size = Vector3.new(7.4, 0.2, 9.4),
	offset = CFrame.new(0, 2.5, -0.5),
	color = INTERIOR_DARK,
})
add({
	name = "Firewall",
	size = Vector3.new(7.4, 3.5, 0.2),
	offset = CFrame.new(0, 4.15, -5.15),
	color = INTERIOR_DARK,
})
paint("CabBackWall", Vector3.new(7.4, 3.6, 0.2), CFrame.new(0, 4.1, 4.1))
paint("Roof", Vector3.new(7.2, 0.25, 8.05), CFrame.new(0, 8.075, 0.175))
paint("RearWindowTop", Vector3.new(7.0, 0.2, 0.25), CFrame.new(0, 7.85, 4.1))
paint("RearWindowBottom", Vector3.new(7.0, 0.2, 0.25), CFrame.new(0, 5.98, 4.1))

-- Glass -----------------------------------------------------------------------------------

glass("Windshield", Vector3.new(7.0, 0.08, 2.52), CFrame.new(0, 6.98, -4.4) * WINDSHIELD_PITCH)
sides(function(s)
	glass("QuarterGlass", Vector3.new(0.08, 1.9, 1.55), CFrame.new(s * 3.66, 6.9, -4.35), WEDGE)
	glass("FrontDoorGlass", Vector3.new(0.08, 1.9, 4.2), CFrame.new(s * 3.66, 6.9, -1.45))
	glass("RearDoorGlass", Vector3.new(0.08, 1.9, 2.85), CFrame.new(s * 3.66, 6.9, 2.33))
	add({
		name = "SliderDivider",
		size = Vector3.new(0.06, 1.65, 0.1),
		offset = CFrame.new(s * 1.1, 6.9, 4.18),
		color = GLOSS_BLACK,
	})
end)
glass("RearWindow", Vector3.new(6.4, 1.65, 0.08), CFrame.new(0, 6.9, 4.14))

-- Grille and front bumper -----------------------------------------------------------------

add({
	name = "Grille",
	size = Vector3.new(5.8, 2.3, 0.3),
	offset = CFrame.new(0, 4.35, -11.45),
	color = GRILLE_BLACK,
	material = M.Fabric,
})
for _, y in { 5.5, 3.2 } do
	add({
		name = "GrilleSurround",
		size = Vector3.new(6.2, 0.22, 0.4),
		offset = CFrame.new(0, y, -11.5),
		color = TRIM_BLACK,
	})
end
sides(function(s)
	add({
		name = "GrilleSurroundSide",
		size = Vector3.new(0.22, 2.3, 0.4),
		offset = CFrame.new(s * 3.0, 4.35, -11.5),
		color = TRIM_BLACK,
	})
end)
for _, y in { 3.6, 3.95, 4.75, 5.1 } do
	add({
		name = "GrilleSlat",
		size = Vector3.new(5.6, 0.05, 0.05),
		offset = CFrame.new(0, y, -11.62),
		color = GLOSS_BLACK,
	})
end
for _, x in { -1.95, -0.65, 0.65, 1.95 } do
	add({
		name = "Letter",
		size = Vector3.new(1.05, 0.95, 0.12),
		offset = CFrame.new(x, 4.35, -11.67),
		color = LETTER_GRAY,
		material = M.Metal,
	})
	add({
		name = "LetterCounter",
		size = Vector3.new(0.4, 0.3, 0.04),
		offset = CFrame.new(x, 4.45, -11.74),
		color = GRILLE_BLACK,
	})
end
for _, x in { -0.5, 0, 0.5 } do
	neon("GrilleMarker", Vector3.new(0.32, 0.1, 0.06), CFrame.new(x, 5.28, -11.66), AMBER)
end

add({
	name = "FrontBumper",
	size = Vector3.new(7.0, 1.1, 0.6),
	offset = CFrame.new(0, 2.45, -11.5),
	color = TRIM_BLACK,
	material = M.Metal,
})
sides(function(s)
	add({
		name = "BumperEnd",
		class = WEDGE,
		size = Vector3.new(0.9, 1.1, 0.6),
		offset = CFrame.new(s * 3.95, 2.45, -11.2) * REVERSE,
		color = TRIM_BLACK,
		material = M.Metal,
	})
	add({
		name = "TowHook",
		size = Vector3.new(0.18, 0.4, 0.35),
		offset = CFrame.new(s * 1.5, 2.2, -11.9),
		color = GLOSS_BLACK,
	})
	add({
		name = "BumperWing",
		size = Vector3.new(0.93, 1.5, 0.3),
		offset = CFrame.new(s * 3.515, 3.8, -11.42),
		color = TRIM_BLACK,
		material = M.Metal,
	})
	neon("FogLamp", Vector3.new(0.7, 0.3, 0.06), CFrame.new(s * 3.0, 2.55, -11.83), HEAD_WHITE)
end)
add({
	name = "SkidPlate",
	class = WEDGE,
	size = Vector3.new(3.6, 0.45, 1.4),
	offset = CFrame.new(0, 1.75, -10.85) * FLIP_Z,
	color = SKID_SILVER,
	material = M.Metal,
})

-- Lights ----------------------------------------------------------------------------------

sides(function(s)
	local hx = s * 3.45
	add({
		name = "HeadlightHousing",
		size = Vector3.new(1.1, 0.9, 0.3),
		offset = CFrame.new(hx, 5.0, -11.4),
		color = GLOSS_BLACK,
		reflectance = 0.08,
	})
	neon(
		"HeadlightLens",
		Vector3.new(0.55, 0.45, 0.05),
		CFrame.new(s * 3.35, 5.05, -11.58),
		HEAD_WHITE
	)
	neon("DrlTop", Vector3.new(1.0, 0.07, 0.05), CFrame.new(hx, 5.42, -11.59), DRL_WHITE)
	neon("DrlBottom", Vector3.new(1.0, 0.07, 0.05), CFrame.new(hx, 4.6, -11.59), DRL_WHITE)
	neon("DrlOuter", Vector3.new(0.07, 0.85, 0.05), CFrame.new(s * 3.95, 5.01, -11.59), DRL_WHITE)
	neon("FrontTurn", Vector3.new(0.3, 0.12, 0.05), CFrame.new(s * 3.0, 4.7, -11.6), AMBER)

	add({
		name = "TailHousing",
		size = Vector3.new(0.45, 2.1, 0.12),
		offset = CFrame.new(s * 3.78, 4.45, 11.36),
		color = TAIL_DARK,
		material = M.Glass,
		transparency = 0.2,
	})
	neon("TailVertical", Vector3.new(0.07, 2.0, 0.05), CFrame.new(s * 3.97, 4.45, 11.45), TAIL_RED)
	neon("TailTop", Vector3.new(0.42, 0.07, 0.05), CFrame.new(s * 3.78, 5.4, 11.45), TAIL_RED)
	neon("TailBottom", Vector3.new(0.42, 0.07, 0.05), CFrame.new(s * 3.78, 3.5, 11.45), TAIL_RED)
	neon("ReverseLamp", Vector3.new(0.28, 0.35, 0.05), CFrame.new(s * 3.75, 4.3, 11.45), HEAD_WHITE)
	neon("MirrorTurn", Vector3.new(0.06, 0.08, 0.5), CFrame.new(s * 4.85, 6.25, -3.75), AMBER)
end)
for _, x in { -1.6, -0.8, 0, 0.8, 1.6 } do
	neon("RoofMarker", Vector3.new(0.25, 0.08, 0.12), CFrame.new(x, 8.24, -3.75), AMBER)
end
neon("ThirdBrake", Vector3.new(1.2, 0.1, 0.06), CFrame.new(0, 7.9, 4.25), TAIL_RED)

-- Bed and rear ----------------------------------------------------------------------------

sides(function(s)
	paint("BedSideUpper", Vector3.new(0.3, 1.46, 7.0), CFrame.new(s * 3.85, 4.97, 7.85))
	paint("BedSideRear", Vector3.new(0.3, 1.34, 2.15), CFrame.new(s * 3.85, 3.57, 10.275))
	paint("BedSideFront", Vector3.new(0.3, 1.34, 0.3), CFrame.new(s * 3.85, 3.57, 4.5))
	add({
		name = "RailCap",
		size = Vector3.new(0.4, 0.08, 7.0),
		offset = CFrame.new(s * 3.8, 5.74, 7.85),
		color = TRIM_BLACK,
	})
	add({
		name = "WheelTub",
		size = Vector3.new(0.6, 0.85, 4.0),
		offset = CFrame.new(s * 3.4, 4.1, REAR_AXLE_Z),
		color = BEDLINER,
		material = M.Fabric,
	})
	add({
		name = "StepPad",
		size = Vector3.new(1.2, 0.04, 0.4),
		offset = CFrame.new(s * 2.6, 3.02, 11.55),
		color = GLOSS_BLACK,
		material = M.DiamondPlate,
	})
	add({
		name = "ExhaustTip",
		shape = CYL,
		size = Vector3.new(0.5, 0.35, 0.35),
		offset = CFrame.new(s * 2.9, 1.75, 11.45) * CYLINDER_Z,
		color = EXHAUST,
		material = M.Metal,
	})
	add({
		name = "ExhaustBore",
		shape = CYL,
		size = Vector3.new(0.04, 0.26, 0.26),
		offset = CFrame.new(s * 2.9, 1.75, 11.71) * CYLINDER_Z,
		color = GAP_BLACK,
	})
end)
paint("BedFrontWall", Vector3.new(7.4, 2.1, 0.2), CFrame.new(0, 4.65, 4.45))
add({
	name = "BedFloor",
	size = Vector3.new(7.4, 0.15, 6.7),
	offset = CFrame.new(0, 3.6, 7.85),
	color = BEDLINER,
	material = M.Fabric,
})
paint("Tailgate", Vector3.new(7.1, 2.7, 0.2), CFrame.new(0, 4.35, 11.25))
add({
	name = "TailgateBand",
	size = Vector3.new(7.1, 0.08, 0.24),
	offset = CFrame.new(0, 5.72, 11.25),
	color = TRIM_BLACK,
})
add({
	name = "TailgateHandle",
	size = Vector3.new(0.8, 0.22, 0.06),
	offset = CFrame.new(0, 5.25, 11.38),
	color = TRIM_BLACK,
})
add({
	name = "CabBedGap",
	size = Vector3.new(7.6, 2.5, 0.12),
	offset = CFrame.new(0, 4.4, 4.3),
	color = GAP_BLACK,
})
add({
	name = "RearBumper",
	size = Vector3.new(7.9, 0.9, 0.55),
	offset = CFrame.new(0, 2.55, 11.55),
	color = TRIM_BLACK,
	material = M.Metal,
})
add({
	name = "LicensePlate",
	size = Vector3.new(1.2, 0.6, 0.04),
	offset = CFrame.new(0, 2.55, 11.84),
	color = PLATE_WHITE,
})
add({
	name = "Hitch",
	size = Vector3.new(0.35, 0.35, 0.6),
	offset = CFrame.new(0, 1.95, 11.6),
	color = FRAME,
})

-- Fender flares and arch liners -----------------------------------------------------------

for _, zc in { FRONT_AXLE_Z, REAR_AXLE_Z } do
	sides(function(s)
		local x = s * 4.2
		add({
			name = "FlareTop",
			size = Vector3.new(0.45, 0.35, 2.3),
			offset = CFrame.new(x, 4.3, zc),
			color = FLARE_BLACK,
		})
		add({
			name = "FlareFront",
			size = Vector3.new(0.45, 0.35, 2.0),
			offset = CFrame.new(x, 3.55, zc - 1.75) * A(math.rad(-45), 0, 0),
			color = FLARE_BLACK,
		})
		add({
			name = "FlareRear",
			size = Vector3.new(0.45, 0.35, 2.0),
			offset = CFrame.new(x, 3.55, zc + 1.75) * A(math.rad(45), 0, 0),
			color = FLARE_BLACK,
		})
		add({
			name = "ArchLiner",
			size = Vector3.new(0.95, 0.25, 4.4),
			offset = CFrame.new(s * 3.475, 4.1, zc),
			color = GAP_BLACK,
		})
		-- Body fill in the upper corners of the square arch cut, following the flare slants.
		add({
			name = "ArchCornerFront",
			class = WEDGE,
			size = Vector3.new(0.3, 1.4, 1.4),
			offset = CFrame.new(s * 3.85, 3.55, zc - 1.6) * FLIP_X,
			color = ORANGE,
			material = PAINT,
			reflectance = PAINT_GLOSS,
		})
		add({
			name = "ArchCornerRear",
			class = WEDGE,
			size = Vector3.new(0.3, 1.4, 1.4),
			offset = CFrame.new(s * 3.85, 3.55, zc + 1.6) * FLIP_Z,
			color = ORANGE,
			material = PAINT,
			reflectance = PAINT_GLOSS,
		})
	end)
end

-- Wheels ----------------------------------------------------------------------------------

for _, wz in { FRONT_AXLE_Z, REAR_AXLE_Z } do
	sides(function(s)
		local wx = s * TRACK_X
		add({
			name = "Tire",
			shape = CYL,
			size = Vector3.new(1.28, 3.76, 3.76),
			offset = CFrame.new(wx, WHEEL_Y, wz),
			color = RUBBER,
		})
		for i = 0, 11 do
			add({
				name = "Tread",
				size = Vector3.new(1.15, 0.16, 0.6),
				offset = CFrame.new(wx, WHEEL_Y, wz)
					* A(math.rad(i * 30), 0, 0)
					* CFrame.new((i % 2 == 0) and 0.07 or -0.07, -1.86, 0),
				color = TREAD,
				material = M.Fabric,
			})
		end
		add({
			name = "BeadlockRing",
			shape = CYL,
			size = Vector3.new(0.06, 1.98, 1.98),
			offset = CFrame.new(wx + s * 0.68, WHEEL_Y, wz),
			color = WHEEL_RING,
			material = M.Metal,
		})
		add({
			name = "RimFace",
			shape = CYL,
			size = Vector3.new(0.04, 1.75, 1.75),
			offset = CFrame.new(wx + s * 0.73, WHEEL_Y, wz),
			color = WHEEL_DARK,
		})
		for k = 0, 5 do
			add({
				name = "Spoke",
				size = Vector3.new(0.06, 0.7, 0.2),
				offset = CFrame.new(wx + s * 0.77, WHEEL_Y, wz)
					* A(math.rad(k * 60), 0, 0)
					* CFrame.new(0, 0.5, 0),
				color = WHEEL_GRAY,
				material = M.Metal,
			})
		end
		add({
			name = "HubCap",
			shape = CYL,
			size = Vector3.new(0.12, 0.55, 0.55),
			offset = CFrame.new(wx + s * 0.81, WHEEL_Y, wz),
			color = WHEEL_GRAY,
			material = M.Metal,
		})
	end)
end

-- Undercarriage ---------------------------------------------------------------------------

sides(function(s)
	add({
		name = "FrameRail",
		size = Vector3.new(0.5, 0.6, 19.0),
		offset = CFrame.new(s * 1.6, 2.0, 0),
		color = FRAME,
	})
	add({
		name = "LowerArm",
		size = Vector3.new(2.2, 0.2, 0.6),
		offset = CFrame.new(s * 2.2, 1.6, FRONT_AXLE_Z),
		color = FRAME,
	})
	add({
		name = "FrontShock",
		shape = CYL,
		size = Vector3.new(1.6, 0.32, 0.32),
		offset = CFrame.new(s * 2.6, 2.9, -7.6) * CYLINDER_Y,
		color = SHOCK,
		material = M.Metal,
	})
	add({
		name = "RearShock",
		shape = CYL,
		size = Vector3.new(1.6, 0.32, 0.32),
		offset = CFrame.new(s * 2.4, 2.9, 7.3) * CYLINDER_Y,
		color = SHOCK,
		material = M.Metal,
	})
end)
add({
	name = "RearAxle",
	shape = CYL,
	size = Vector3.new(6.2, 0.45, 0.45),
	offset = CFrame.new(0, WHEEL_Y, REAR_AXLE_Z),
	color = FRAME,
})
add({
	name = "RearDiff",
	shape = BALL,
	size = Vector3.new(1.1, 1.1, 1.1),
	offset = CFrame.new(0.3, 1.85, REAR_AXLE_Z),
	color = FRAME,
})
add({
	name = "FrontDiff",
	size = Vector3.new(1.2, 0.8, 1.0),
	offset = CFrame.new(0, 1.75, FRONT_AXLE_Z),
	color = FRAME,
})
add({
	name = "FuelTank",
	size = Vector3.new(1.6, 0.8, 3.0),
	offset = CFrame.new(-2.3, 2.1, 2.5),
	color = FRAME,
})

-- Interior --------------------------------------------------------------------------------

add({
	name = "Dashboard",
	size = Vector3.new(7.2, 0.9, 1.2),
	offset = CFrame.new(0, 5.6, -4.3),
	color = DASH,
})
add({
	name = "Binnacle",
	size = Vector3.new(1.4, 0.35, 0.5),
	offset = CFrame.new(-1.55, 6.15, -3.9),
	color = DASH,
})
add({
	name = "CenterScreen",
	size = Vector3.new(1.0, 0.7, 0.08),
	offset = CFrame.new(0, 6.0, -3.72) * A(math.rad(-15), 0, 0),
	color = SCREEN,
	material = M.Neon,
	transparency = 0.3,
})
add({
	name = "SteeringWheel",
	shape = CYL,
	size = Vector3.new(0.12, 1.3, 1.3),
	offset = CFrame.new(-1.55, 5.5, -2.45) * A(math.rad(-25), 0, 0) * CYLINDER_Z,
	color = GLOSS_BLACK,
})
add({
	name = "SteeringColumn",
	shape = CYL,
	size = Vector3.new(1.0, 0.25, 0.25),
	offset = CFrame.new(-1.55, 5.25, -3.0) * A(math.rad(-25), 0, 0) * CYLINDER_Z,
	color = DASH,
})
add({
	name = "Console",
	size = Vector3.new(0.9, 1.0, 2.2),
	offset = CFrame.new(0, 3.4, -1.6),
	color = DASH,
})
sides(function(s)
	local x = s * 1.55
	add({
		name = "FrontCushion",
		size = Vector3.new(1.8, 0.4, 1.8),
		offset = CFrame.new(x, 3.38, -0.95),
		color = SEAT_BLACK,
		material = M.Fabric,
	})
	add({
		name = "FrontSeatback",
		size = Vector3.new(1.8, 2.4, 0.4),
		offset = CFrame.new(x, 4.8, -0.05),
		color = SEAT_BLACK,
		material = M.Fabric,
	})
	add({
		name = "FrontHeadrest",
		size = Vector3.new(1.0, 0.6, 0.3),
		offset = CFrame.new(x, 6.35, 0.0),
		color = SEAT_BLACK,
		material = M.Fabric,
	})
	add({
		name = "RearHeadrest",
		size = Vector3.new(1.0, 0.55, 0.3),
		offset = CFrame.new(x, 6.25, 3.7),
		color = SEAT_BLACK,
		material = M.Fabric,
	})
	add({
		name = "SeatStitch",
		size = Vector3.new(0.06, 2.2, 0.02),
		offset = CFrame.new(x, 4.8, -0.27),
		color = ORANGE,
	})
end)
add({
	name = "RearBench",
	size = Vector3.new(6.4, 0.4, 1.8),
	offset = CFrame.new(0, 3.48, 2.8),
	color = SEAT_BLACK,
	material = M.Fabric,
})
add({
	name = "RearSeatback",
	size = Vector3.new(6.4, 2.2, 0.4),
	offset = CFrame.new(0, 4.85, 3.65),
	color = SEAT_BLACK,
	material = M.Fabric,
})

-- Mirrors ---------------------------------------------------------------------------------

sides(function(s)
	add({
		name = "MirrorHousing",
		size = Vector3.new(0.6, 0.85, 0.4),
		offset = CFrame.new(s * 4.75, 6.55, -3.75),
		color = TRIM_BLACK,
	})
	add({
		name = "MirrorStalk",
		size = Vector3.new(0.9, 0.15, 0.2),
		offset = CFrame.new(s * 4.15, 6.25, -3.85),
		color = TRIM_BLACK,
	})
	add({
		name = "MirrorGlass",
		size = Vector3.new(0.45, 0.7, 0.04),
		offset = CFrame.new(s * 4.75, 6.55, -3.53),
		color = GLASS,
		material = M.Glass,
		reflectance = 0.4,
	})
end)

return {
	name = "Ford F-150 Raptor",
	-- Real: 172 km/h, 0-100 km/h in 5.9 s, brakes 0.75 g, coasts 0.2 g (VehicleDefaults maps them).
	speed = 65,
	acceleration = 10.3,
	braking = 13.9,
	coasting = 5.7,
	turnRate = 2.2,
	footprint = Vector2.new(8, 22),
	collision = {
		{ size = Vector3.new(8.4, 4.3, 23.4), offset = CFrame.new(0, 3.75, 0) }, -- body, y 1.6..5.9
		{ size = Vector3.new(7.4, 2.3, 8.0), offset = CFrame.new(0, 7.05, -0.3) }, -- cabin, y 5.9..8.2
	},
	seats = {
		CFrame.new(-1.55, 3.1, -0.9), -- driver (LHD)
		CFrame.new(1.55, 3.1, -0.9),
		CFrame.new(-1.55, 3.2, 2.8),
		CFrame.new(1.55, 3.2, 2.8),
	},
	pieces = pieces,
}
