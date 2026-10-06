-- Snowcat: PistenBully 600 center-seat groomer with open grouser tracks, a 12-way blade and a rear tiller.

-- Scale: 4 studs = 1 m for length and height; width compressed about 7% to fit the 16-stud footprint.

local rgb = Color3.fromRGB
local M = Enum.Material
local A = CFrame.Angles
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball
local CYLINDER_Z = A(0, math.rad(90), 0)
local CYLINDER_Y = A(0, 0, math.rad(90))

-- Wedge orientations (WedgePart default: right angle at local (ymin, zmax), rises toward +Z).
local FLIP_Z = A(0, 0, math.pi) -- right angle at (ymax, zmax): underside slopes up toward -Z
local FACE_FRONT = A(0, math.pi, 0) -- tall at the front, slopes down toward +Z

local PB_RED = rgb(196, 22, 28)
local BLACK = rgb(22, 22, 24)
local CHASSIS = rgb(52, 54, 58)
local BELT_RUBBER = rgb(30, 30, 32)
local GROUSER_ALU = rgb(186, 189, 194)
local TIRE = rgb(28, 28, 30)
local RIM = rgb(165, 167, 172)
local SPROCKET_STEEL = rgb(45, 45, 48)
local FLANGE_STEEL = rgb(70, 70, 74)
local TOOTH_STEEL = rgb(40, 40, 42)
local HUB_STEEL = rgb(60, 60, 64)
local MOLDBOARD = rgb(140, 142, 148)
local CUTTING_EDGE = rgb(205, 205, 210)
local CHROME = rgb(215, 218, 222)
local GLASS = rgb(150, 190, 210)
local MIRROR = rgb(170, 190, 200)
local DECK_PLATE = rgb(80, 82, 86)
local STEP_PLATE = rgb(90, 92, 96)
local SEAT_FABRIC = rgb(40, 40, 44)
local CONSOLE = rgb(35, 35, 38)
local SCREEN = rgb(20, 30, 40)
local LAMP_WHITE = rgb(255, 244, 220)
local TAIL_RED = rgb(255, 30, 30)
local AMBER = rgb(255, 150, 20)
local MARKER_ORANGE = rgb(255, 110, 0)
local COMB_RUBBER = rgb(35, 35, 38)
local COMB_RIB = rgb(70, 70, 74)
local VENT_SLAT = rgb(40, 40, 44)
local EXHAUST_TIP = rgb(90, 90, 94)

local PAINT = { reflectance = 0.08 }
local GLASS_LOOK = { transparency = 0.4 }

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

local function wedge(name, size, offset, color, material, extra)
	local spec = block(name, size, offset, color, material, extra)
	spec.class = "WedgePart"
	return spec
end

local function cyl(name, length, diameter, offset, color, material, extra)
	local spec =
		block(name, Vector3.new(length, diameter, diameter), offset, color, material, extra)
	spec.shape = CYL
	return spec
end

local function ball(name, diameter, offset, color, material, extra)
	local spec =
		block(name, Vector3.new(diameter, diameter, diameter), offset, color, material, extra)
	spec.shape = BALL
	return spec
end

-- A round tube or a square bar between two points (never vertically aligned).
local function rod(name, p0, p1, d, color, material, square, extra)
	local len = (p1 - p0).Magnitude
	local cf = CFrame.lookAt((p0 + p1) / 2, p1)
	if square then
		return block(name, Vector3.new(d, d, len), cf, color, material, extra)
	end
	return cyl(name, len, d, cf * CYLINDER_Z, color, material, extra)
end

local SIDES = { -1, 1 }

----------------------------------------------------------------------------------------------------
-- Tracks
----------------------------------------------------------------------------------------------------

-- The grouser loop in side view (y, z), run clockwise: forward along the bottom, up the front,
-- rearward along the top, down the rear. Local +Y of every grouser points out of the loop.
local IDLER = Vector2.new(2.30, -7.4) -- (y, z)
local SPROCKET = Vector2.new(2.50, 7.2)
local R_IDLER = 1.76
local R_SPROCKET = 1.86
local BELT_INSET = 0.20

local function line(y0, z0, y1, z1)
	local dy, dz = y1 - y0, z1 - z0
	local len = math.sqrt(dy * dy + dz * dz)
	return {
		len = len,
		at = function(t)
			return y0 + dy * t / len, z0 + dz * t / len, math.atan2(-dy, dz)
		end,
	}
end

-- Arc around center c with radius r; angle a runs a0 -> a1. Position (cy + r cos a, cz + sgn r sin a).
local function arc(c, r, a0, a1, sgn)
	local len = math.abs(a1 - a0) * r
	return {
		len = len,
		center = c,
		r = r,
		at = function(t)
			local a = a0 + (a1 - a0) * t / len
			local y = c.X + r * math.cos(a)
			local z = c.Y + sgn * r * math.sin(a)
			-- Tangent in the direction of travel.
			local dy = -r * math.sin(a) * (a1 - a0)
			local dz = sgn * r * math.cos(a) * (a1 - a0)
			return y, z, math.atan2(-dy, dz)
		end,
	}
end

local SEGMENTS = {
	{ seg = line(0.14, 4.5, 0.14, -4.5), kind = "bottom" },
	{ seg = line(0.14, -4.5, 0.54, -7.4), kind = "ramp" },
	{ seg = arc(IDLER, R_IDLER, math.pi, 0, -1), kind = "arc" },
	{ seg = line(4.06, -7.4, 4.36, 7.2), kind = "top" },
	{ seg = arc(SPROCKET, R_SPROCKET, 0, math.pi, 1), kind = "arc" },
	{ seg = line(0.64, 7.2, 0.14, 4.5), kind = "ramp" },
}

local LOOP_LENGTH = 0
for _, s in SEGMENTS do
	LOOP_LENGTH += s.seg.len
end
local GROUSER_COUNT = 23
local PITCH = LOOP_LENGTH / GROUSER_COUNT

local function loopFrame(x, y, z, theta)
	return CFrame.new(x, y, z) * A(theta, 0, 0)
end

local ARC_CHORDS = 3

for _, s in SIDES do
	local x = 5.6 * s

	-- Grousers at a regular pitch by arc length, starting mid-bottom run.
	for k = 0, GROUSER_COUNT - 1 do
		local t = k * PITCH + PITCH / 2
		for _, entry in SEGMENTS do
			if t <= entry.seg.len then
				local y, z, theta = entry.seg.at(t)
				block(
					"Grouser",
					Vector3.new(4.4, 0.28, 0.32),
					loopFrame(x, y, z, theta),
					GROUSER_ALU,
					M.Metal,
					{ reflectance = 0.1 }
				)
				break
			end
			t -= entry.seg.len
		end
	end

	-- Belt: slabs on straight runs, tangent chords around the idler and sprocket.
	for _, entry in SEGMENTS do
		local seg = entry.seg
		if entry.kind == "arc" then
			local step = seg.len / ARC_CHORDS
			local rBelt = seg.r - BELT_INSET
			local half = (step / seg.r) / 2
			local chord = 2 * rBelt * math.tan(half) + 0.04
			for i = 0, ARC_CHORDS - 1 do
				local y, z, theta = seg.at(step * (i + 0.5))
				block(
					"Belt",
					Vector3.new(4.3, 0.12, chord),
					loopFrame(x, y, z, theta) * CFrame.new(0, -BELT_INSET, 0),
					BELT_RUBBER,
					M.SmoothPlastic
				)
			end
		elseif entry.kind == "top" then
			local y, z, theta = seg.at(seg.len / 2)
			for i = 0, 5 do
				block(
					"BeltStrip",
					Vector3.new(0.55, 0.12, seg.len),
					loopFrame(x + (i - 2.5) * 0.72, y, z, theta) * CFrame.new(0, -BELT_INSET, 0),
					BELT_RUBBER,
					M.SmoothPlastic
				)
			end
		else
			local y, z, theta = seg.at(seg.len / 2)
			block(
				"Belt",
				Vector3.new(4.3, 0.12, seg.len + 0.1),
				loopFrame(x, y, z, theta) * CFrame.new(0, -BELT_INSET, 0),
				BELT_RUBBER,
				M.SmoothPlastic
			)
		end
	end

	-- Road wheels and the front idler: twin tires with a rim disc on the outer face.
	local stations = {
		Vector2.new(1.90, -4.5),
		Vector2.new(1.90, -1.5),
		Vector2.new(1.90, 1.5),
		Vector2.new(1.90, 4.5),
		IDLER,
	}
	for _, st in stations do
		cyl("TireOuter", 1.5, 3.0, CFrame.new(6.85 * s, st.X, st.Y), TIRE, M.SmoothPlastic)
		cyl("TireInner", 1.5, 3.0, CFrame.new(4.35 * s, st.X, st.Y), TIRE, M.SmoothPlastic)
		cyl("Rim", 0.08, 1.9, CFrame.new(7.64 * s, st.X, st.Y), RIM, M.Metal)
	end

	-- Rear drive sprocket.
	local sp = CFrame.new(5.6 * s, SPROCKET.X, SPROCKET.Y)
	cyl("SprocketDrum", 4.2, 3.2, sp, SPROCKET_STEEL, M.Metal)
	cyl(
		"SprocketFlange",
		0.12,
		3.5,
		CFrame.new(7.72 * s, SPROCKET.X, SPROCKET.Y),
		FLANGE_STEEL,
		M.Metal
	)
	for k = 0, 3 do
		block(
			"SprocketTooth",
			Vector3.new(0.14, 3.6, 0.35),
			CFrame.new(7.80 * s, SPROCKET.X, SPROCKET.Y) * A(k * math.pi / 4, 0, 0),
			TOOTH_STEEL,
			M.Metal
		)
	end
	cyl("SprocketHub", 0.12, 0.8, CFrame.new(7.90 * s, SPROCKET.X, SPROCKET.Y), HUB_STEEL, M.Metal)
end

----------------------------------------------------------------------------------------------------
-- Hull and chassis
----------------------------------------------------------------------------------------------------

block("Hull", Vector3.new(6.6, 3.7, 17.2), CFrame.new(0, 3.15, 0), CHASSIS, M.Metal)
block("FrontBumper", Vector3.new(6.8, 1.2, 0.6), CFrame.new(0, 3.6, -8.9), BLACK, M.SmoothPlastic)
cyl("TowEye", 0.3, 0.6, CFrame.new(0, 2.8, -9.25) * CYLINDER_Z, HUB_STEEL, M.Metal)
block("RearDeck", Vector3.new(6.0, 0.4, 2.4), CFrame.new(0, 4.8, 8.0), BLACK, M.SmoothPlastic)
block(
	"RearDeckPlate",
	Vector3.new(5.8, 0.05, 2.2),
	CFrame.new(0, 5.025, 8.0),
	DECK_PLATE,
	M.DiamondPlate
)

for _, s in SIDES do
	-- Step platform beside the cab, over the track, with a ladder down the outside.
	block(
		"StepPlatform",
		Vector3.new(3.2, 0.3, 4.0),
		CFrame.new(6.4 * s, 5.15, -5.0),
		PB_RED,
		M.SmoothPlastic,
		PAINT
	)
	block(
		"StepTread",
		Vector3.new(3.0, 0.06, 3.6),
		CFrame.new(6.4 * s, 5.33, -5.0),
		STEP_PLATE,
		M.DiamondPlate
	)
	block(
		"LadderStileFront",
		Vector3.new(0.12, 3.4, 0.12),
		CFrame.new(8.06 * s, 3.4, -6.6),
		BLACK,
		M.SmoothPlastic
	)
	block(
		"LadderStileRear",
		Vector3.new(0.12, 3.4, 0.12),
		CFrame.new(8.06 * s, 3.4, -5.4),
		BLACK,
		M.SmoothPlastic
	)
	block(
		"LadderRung",
		Vector3.new(0.3, 0.12, 1.3),
		CFrame.new(8.06 * s, 3.2, -6.0),
		BLACK,
		M.DiamondPlate
	)
end

----------------------------------------------------------------------------------------------------
-- Cab
----------------------------------------------------------------------------------------------------

local WS_TILT = A(math.rad(9.46), 0, 0)
local WINDSHIELD = CFrame.new(0, 8.7, -7.35) * WS_TILT

block("CabBase", Vector3.new(9.2, 0.3, 7.2), CFrame.new(0, 5.15, -4.2), BLACK, M.SmoothPlastic)
block(
	"FrontLowerPanel",
	Vector3.new(9.2, 1.6, 0.25),
	CFrame.new(0, 5.8, -7.68),
	PB_RED,
	M.SmoothPlastic,
	PAINT
)
block("Roof", Vector3.new(9.4, 0.4, 7.0), CFrame.new(0, 11.3, -4.0), PB_RED, M.SmoothPlastic, PAINT)
wedge(
	"RoofVisor",
	Vector3.new(9.4, 0.4, 0.8),
	CFrame.new(0, 11.3, -7.9) * FLIP_Z,
	PB_RED,
	M.SmoothPlastic,
	PAINT
)
block("RoofRim", Vector3.new(9.5, 0.08, 7.1), CFrame.new(0, 11.06, -4.0), BLACK, M.SmoothPlastic)
block(
	"WindshieldHeader",
	Vector3.new(9.2, 0.35, 0.4),
	CFrame.new(0, 10.93, -7.0),
	BLACK,
	M.SmoothPlastic
)
block("Windshield", Vector3.new(8.8, 4.26, 0.1), WINDSHIELD, GLASS, M.Glass, GLASS_LOOK)
block("RearGlass", Vector3.new(8.6, 3.6, 0.1), CFrame.new(0, 8.9, -0.6), GLASS, M.Glass, GLASS_LOOK)
block(
	"RearWall",
	Vector3.new(9.2, 2.0, 0.2),
	CFrame.new(0, 6.1, -0.6),
	PB_RED,
	M.SmoothPlastic,
	PAINT
)

for _, s in SIDES do
	block(
		"LowerSidePanel",
		Vector3.new(0.2, 1.5, 7.0),
		CFrame.new(4.5 * s, 6.05, -4.2),
		PB_RED,
		M.SmoothPlastic,
		PAINT
	)
	block(
		"APillar",
		Vector3.new(0.35, 4.26, 0.35),
		CFrame.new(4.45 * s, 8.7, -7.35) * WS_TILT,
		BLACK,
		M.SmoothPlastic
	)
	block(
		"SideGlass",
		Vector3.new(0.1, 3.9, 6.4),
		CFrame.new(4.55 * s, 8.85, -3.9),
		GLASS,
		M.Glass,
		GLASS_LOOK
	)
	-- Triangle between the raked A-pillar and the vertical front edge of the side glass.
	wedge(
		"SideGlassFront",
		Vector3.new(0.1, 3.9, 0.55),
		CFrame.new(4.55 * s, 8.85, -7.375),
		GLASS,
		M.Glass,
		GLASS_LOOK
	)
	block(
		"Beltline",
		Vector3.new(0.22, 0.15, 7.0),
		CFrame.new(4.6 * s, 6.85, -4.2),
		BLACK,
		M.SmoothPlastic
	)
	block(
		"BPillar",
		Vector3.new(0.25, 4.0, 0.3),
		CFrame.new(4.62 * s, 8.85, -3.4),
		BLACK,
		M.SmoothPlastic
	)
	block(
		"CPillar",
		Vector3.new(0.3, 4.4, 0.3),
		CFrame.new(4.55 * s, 8.9, -0.6),
		BLACK,
		M.SmoothPlastic
	)
	block(
		"DoorGapRear",
		Vector3.new(0.03, 1.5, 0.05),
		CFrame.new(4.615 * s, 6.05, -3.4),
		BLACK,
		M.SmoothPlastic
	)
	block(
		"DoorHandle",
		Vector3.new(0.08, 0.12, 0.5),
		CFrame.new(4.75 * s, 7.3, -4.6),
		BLACK,
		M.SmoothPlastic
	)
	cyl(
		"GrabRail",
		2.6,
		0.1,
		CFrame.new(4.72 * s, 8.5, -6.9) * CYLINDER_Y,
		CHROME,
		M.Metal,
		{ reflectance = 0.3 }
	)
	block(
		"Wiper",
		Vector3.new(0.06, 2.4, 0.08),
		WINDSHIELD * CFrame.new(2.2 * s, -0.75, -0.12) * A(0, 0, math.rad(-12 * s)),
		BLACK,
		M.SmoothPlastic
	)
	rod(
		"MirrorArm",
		Vector3.new(4.7 * s, 10.2, -7.0),
		Vector3.new(5.6 * s, 9.8, -7.4),
		0.12,
		BLACK,
		M.SmoothPlastic
	)
	block(
		"MirrorHead",
		Vector3.new(0.25, 1.3, 0.8),
		CFrame.new(5.75 * s, 9.4, -7.4),
		BLACK,
		M.SmoothPlastic
	)
	block(
		"MirrorFace",
		Vector3.new(0.03, 1.1, 0.6),
		CFrame.new(5.89 * s, 9.4, -7.4),
		MIRROR,
		M.Glass,
		{ reflectance = 0.4 }
	)
end

----------------------------------------------------------------------------------------------------
-- Engine housing
----------------------------------------------------------------------------------------------------

block(
	"HoodBlock",
	Vector3.new(8.8, 2.6, 7.4),
	CFrame.new(0, 6.3, 3.1),
	PB_RED,
	M.SmoothPlastic,
	PAINT
)
block(
	"HoodTop",
	Vector3.new(8.4, 0.5, 6.4),
	CFrame.new(0, 7.85, 2.6),
	PB_RED,
	M.SmoothPlastic,
	PAINT
)
wedge(
	"HoodRearChamfer",
	Vector3.new(8.4, 0.5, 1.0),
	CFrame.new(0, 7.85, 6.3) * FACE_FRONT,
	PB_RED,
	M.SmoothPlastic,
	PAINT
)
for _, s in SIDES do
	wedge(
		"HoodSideChamfer",
		Vector3.new(6.4, 0.5, 0.2),
		CFrame.new(4.3 * s, 7.85, 2.6) * A(0, -s * math.pi / 2, 0),
		PB_RED,
		M.SmoothPlastic,
		PAINT
	)
	block(
		"SideVent",
		Vector3.new(0.04, 1.4, 2.8),
		CFrame.new(4.42 * s, 6.6, 3.8),
		BLACK,
		M.SmoothPlastic
	)
	for i = 0, 2 do
		block(
			"VentSlat",
			Vector3.new(0.06, 0.14, 2.6),
			CFrame.new(4.46 * s, 6.15 + i * 0.45, 3.8),
			VENT_SLAT,
			M.Metal
		)
	end
end
block("TopIntake", Vector3.new(3.0, 0.06, 1.8), CFrame.new(0, 8.13, 2.4), BLACK, M.SmoothPlastic)
for i = 0, 4 do
	block(
		"IntakeSlat",
		Vector3.new(2.9, 0.05, 0.1),
		CFrame.new(0, 8.18, 1.7 + i * 0.35),
		VENT_SLAT,
		M.Metal
	)
end
block("HoodRearPanel", Vector3.new(8.8, 2.8, 0.2), CFrame.new(0, 6.4, 6.9), BLACK, M.SmoothPlastic)
cyl("ExhaustStack", 2.4, 0.45, CFrame.new(3.4, 9.2, 5.6) * CYLINDER_Y, BLACK, M.SmoothPlastic)
cyl("ExhaustTip", 0.3, 0.5, CFrame.new(3.4, 10.45, 5.6) * CYLINDER_Y, EXHAUST_TIP, M.Metal)
block(
	"ExhaustFlap",
	Vector3.new(0.5, 0.05, 0.5),
	CFrame.new(3.4, 10.63, 5.6) * A(math.rad(-15), 0, 0),
	BLACK,
	M.Metal
)
cyl("HoodHandle", 8.0, 0.15, CFrame.new(0, 7.6, 7.08), CHROME, M.Metal, { reflectance = 0.3 })

----------------------------------------------------------------------------------------------------
-- Blade (12-way): a center section and two wings swept forward 22 degrees
----------------------------------------------------------------------------------------------------

local BLADE_CENTER = CFrame.new(0, 0, -13.4)
local function wingFrame(s)
	return CFrame.new(5.0 * s, 0, -13.4) * A(0, math.rad(22) * s, 0) * CFrame.new(2.3 * s, 0, 0)
end

local function bladeSection(frame, w, isWing)
	local function at(x, y, z)
		return frame * CFrame.new(x, y, z)
	end
	block(
		"CuttingEdge",
		Vector3.new(w, 0.35, 0.2),
		at(0, 0.38, -0.55),
		CUTTING_EDGE,
		M.Metal,
		{ reflectance = 0.1 }
	)
	block(
		"MoldboardLow",
		Vector3.new(w, 1.7, 0.15),
		at(0, 1.4, -0.45) * A(math.rad(14), 0, 0),
		MOLDBOARD,
		M.Metal
	)
	block("MoldboardMid", Vector3.new(w, 1.8, 0.15), at(0, 3.1, -0.25), MOLDBOARD, M.Metal)
	block(
		"MoldboardCurl",
		Vector3.new(w, 1.3, 0.15),
		at(0, 4.55, -0.42) * A(math.rad(-25), 0, 0),
		MOLDBOARD,
		M.Metal
	)
	if isWing then
		-- The wing's top rail is merged into a taller back skin.
		block(
			"BladeBack",
			Vector3.new(w, 4.85, 0.5),
			at(0, 2.725, 0.05),
			PB_RED,
			M.SmoothPlastic,
			PAINT
		)
		block(
			"BladeRib",
			Vector3.new(0.25, 4.0, 0.5),
			at(0, 2.6, 0.55),
			PB_RED,
			M.SmoothPlastic,
			PAINT
		)
	else
		block(
			"BladeBack",
			Vector3.new(w, 4.6, 0.3),
			at(0, 2.6, 0.15),
			PB_RED,
			M.SmoothPlastic,
			PAINT
		)
		block(
			"BladeTopRail",
			Vector3.new(w, 0.3, 0.9),
			at(0, 5.0, -0.1),
			PB_RED,
			M.SmoothPlastic,
			PAINT
		)
		for _, rx in { -w / 4, w / 4 } do
			block(
				"BladeRib",
				Vector3.new(0.25, 4.0, 0.5),
				at(rx, 2.6, 0.55),
				PB_RED,
				M.SmoothPlastic,
				PAINT
			)
		end
	end
end

bladeSection(BLADE_CENTER, 10.0, false)
for _, s in SIDES do
	local wf = wingFrame(s)
	bladeSection(wf, 4.6, true)
	block(
		"WingEndPlate",
		Vector3.new(0.2, 4.8, 1.0),
		wf * CFrame.new(2.4 * s, 2.6, -0.1),
		BLACK,
		M.SmoothPlastic
	)
	block(
		"MarkerPole",
		Vector3.new(0.12, 3.0, 0.12),
		wf * CFrame.new(2.2 * s, 6.5, 0.1),
		MARKER_ORANGE,
		M.SmoothPlastic
	)
	ball("MarkerTip", 0.3, wf * CFrame.new(2.2 * s, 8.1, 0.1), AMBER, M.Neon)
	cyl("WingHinge", 4.6, 0.4, CFrame.new(5.0 * s, 2.6, -13.0) * CYLINDER_Y, HUB_STEEL, M.Metal)
	rod(
		"PushArm",
		Vector3.new(3.0 * s, 2.2, -8.6),
		Vector3.new(3.0 * s, 2.2, -12.95),
		0.8,
		BLACK,
		M.SmoothPlastic,
		true
	)
	rod(
		"BladeLiftBarrel",
		Vector3.new(1.6 * s, 4.7, -8.7),
		Vector3.new(1.6 * s, 3.9, -11.0),
		0.5,
		BLACK,
		M.SmoothPlastic
	)
	rod(
		"BladeLiftRod",
		Vector3.new(1.6 * s, 3.9, -11.0),
		Vector3.new(1.6 * s, 3.4, -12.95),
		0.25,
		CHROME,
		M.Metal,
		false,
		{
			reflectance = 0.3,
		}
	)
	rod(
		"WingCylinder",
		Vector3.new(3.2 * s, 3.8, -12.95),
		(wf * CFrame.new(-0.9 * s, 3.8, 0.42)).Position,
		0.22,
		CHROME,
		M.Metal,
		false,
		{
			reflectance = 0.3,
		}
	)
end
cyl("PushCrossTube", 6.0, 0.6, CFrame.new(0, 2.2, -12.0), BLACK, M.SmoothPlastic)

----------------------------------------------------------------------------------------------------
-- Tiller and finisher comb
----------------------------------------------------------------------------------------------------

block("HitchYoke", Vector3.new(7.0, 0.5, 0.6), CFrame.new(0, 3.3, 11.2), BLACK, M.SmoothPlastic)
for _, s in SIDES do
	rod(
		"HitchArm",
		Vector3.new(2.4 * s, 4.4, 9.0),
		Vector3.new(2.4 * s, 3.0, 11.2),
		0.5,
		BLACK,
		M.SmoothPlastic,
		true
	)
	block(
		"TillerEndPlate",
		Vector3.new(0.15, 2.4, 2.8),
		CFrame.new(9.05 * s, 1.6, 12.6),
		BLACK,
		M.SmoothPlastic
	)
	block(
		"TillerFlexJoint",
		Vector3.new(0.3, 0.6, 0.6),
		CFrame.new(3.58 * s, 2.9, 12.0),
		BLACK,
		M.SmoothPlastic
	)
end
rod(
	"TillerLiftBarrel",
	Vector3.new(0, 5.2, 8.6),
	Vector3.new(0, 4.2, 10.0),
	0.5,
	BLACK,
	M.SmoothPlastic
)
rod(
	"TillerLiftRod",
	Vector3.new(0, 4.2, 10.0),
	Vector3.new(0, 3.4, 11.1),
	0.25,
	CHROME,
	M.Metal,
	false,
	{
		reflectance = 0.3,
	}
)

for _, sec in { { xc = 0, w = 7.0 }, { xc = -6.35, w = 5.4 }, { xc = 6.35, w = 5.4 } } do
	local xc, w = sec.xc, sec.w
	block(
		"TillerHood",
		Vector3.new(w, 0.25, 2.6),
		CFrame.new(xc, 2.95, 12.6),
		PB_RED,
		M.SmoothPlastic,
		PAINT
	)
	wedge(
		"TillerFrontSlope",
		Vector3.new(w, 1.0, 0.7),
		CFrame.new(xc, 2.45, 11.1),
		PB_RED,
		M.SmoothPlastic,
		PAINT
	)
	block(
		"TillerFrontSkirt",
		Vector3.new(w, 1.2, 0.12),
		CFrame.new(xc, 1.35, 10.85),
		BLACK,
		M.SmoothPlastic
	)
	block(
		"TillerRearSkirt",
		Vector3.new(w, 1.6, 0.15),
		CFrame.new(xc, 2.0, 13.9),
		BLACK,
		M.SmoothPlastic
	)
	cyl("TillerDrum", w - 0.3, 1.8, CFrame.new(xc, 1.1, 12.6), FLANGE_STEEL, M.Metal)
	block(
		"CombFlap",
		Vector3.new(w, 0.12, 3.2),
		CFrame.new(xc, 0.68, 15.43) * A(math.rad(22.8), 0, 0),
		COMB_RUBBER,
		M.SmoothPlastic
	)
	block(
		"FlatComb",
		Vector3.new(w, 0.08, 1.0),
		CFrame.new(xc, 0.04, 17.4),
		COMB_RUBBER,
		M.SmoothPlastic
	)
	for i = -1, 1 do
		block(
			"CombRib",
			Vector3.new(0.12, 0.05, 1.0),
			CFrame.new(xc + i * w / 3, 0.105, 17.4),
			COMB_RIB,
			M.SmoothPlastic
		)
	end
end

----------------------------------------------------------------------------------------------------
-- Lights
----------------------------------------------------------------------------------------------------

block("LightBar", Vector3.new(8.4, 0.35, 0.6), CFrame.new(0, 11.7, -6.9), BLACK, M.SmoothPlastic)
for _, x in { -3.5, -2.1, -0.7, 0.7, 2.1, 3.5 } do
	block("RoofLed", Vector3.new(0.9, 0.3, 0.06), CFrame.new(x, 11.7, -7.235), LAMP_WHITE, M.Neon)
end
for _, s in SIDES do
	block(
		"RearWorkLightHousing",
		Vector3.new(1.0, 0.4, 0.3),
		CFrame.new(2.5 * s, 11.7, -0.62),
		BLACK,
		M.SmoothPlastic
	)
	block(
		"RearWorkLight",
		Vector3.new(0.9, 0.3, 0.06),
		CFrame.new(2.5 * s, 11.7, -0.445),
		LAMP_WHITE,
		M.Neon
	)
	cyl(
		"BeaconBase",
		0.15,
		0.7,
		CFrame.new(3.9 * s, 11.58, -1.2) * CYLINDER_Y,
		BLACK,
		M.SmoothPlastic
	)
	ball("BeaconDome", 0.6, CFrame.new(3.9 * s, 11.95, -1.2), AMBER, M.Neon, { transparency = 0.1 })

	block(
		"HeadlightBezel",
		Vector3.new(1.5, 0.75, 0.04),
		CFrame.new(3.0 * s, 6.0, -7.82),
		BLACK,
		M.SmoothPlastic
	)
	block(
		"Headlight",
		Vector3.new(1.3, 0.55, 0.06),
		CFrame.new(3.0 * s, 6.0, -7.85),
		LAMP_WHITE,
		M.Neon
	)
	block(
		"Indicator",
		Vector3.new(0.45, 0.45, 0.06),
		CFrame.new(4.2 * s, 6.0, -7.83),
		AMBER,
		M.Neon
	)
	block(
		"BladeLight",
		Vector3.new(0.7, 0.4, 0.06),
		CFrame.new(1.2 * s, 6.1, -7.83),
		LAMP_WHITE,
		M.Neon
	)

	block("TailLamp", Vector3.new(0.9, 0.5, 0.06), CFrame.new(3.5 * s, 6.3, 7.04), TAIL_RED, M.Neon)
	block(
		"ReverseLamp",
		Vector3.new(0.5, 0.4, 0.06),
		CFrame.new(2.5 * s, 6.3, 7.04),
		LAMP_WHITE,
		M.Neon
	)
	block(
		"RearIndicator",
		Vector3.new(0.4, 0.4, 0.06),
		CFrame.new(3.5 * s, 5.7, 7.04),
		AMBER,
		M.Neon
	)
end

----------------------------------------------------------------------------------------------------
-- Interior: center driver seat with a passenger seat on each side
----------------------------------------------------------------------------------------------------

block(
	"DriverCushion",
	Vector3.new(1.8, 0.45, 1.9),
	CFrame.new(0, 6.58, -3.5),
	SEAT_FABRIC,
	M.Fabric
)
block(
	"DriverBackrest",
	Vector3.new(1.8, 2.4, 0.4),
	CFrame.new(0, 8.1, -2.45) * A(math.rad(10), 0, 0),
	SEAT_FABRIC,
	M.Fabric
)
block(
	"DriverHeadrest",
	Vector3.new(1.2, 0.7, 0.35),
	CFrame.new(0, 9.6, -2.15),
	SEAT_FABRIC,
	M.Fabric
)
block("SeatPedestal", Vector3.new(0.8, 1.0, 0.8), CFrame.new(0, 5.8, -3.5), BLACK, M.SmoothPlastic)
for _, s in SIDES do
	block(
		"PassengerCushion",
		Vector3.new(1.7, 0.45, 1.8),
		CFrame.new(2.5 * s, 6.58, -2.5),
		SEAT_FABRIC,
		M.Fabric
	)
	block(
		"PassengerBackrest",
		Vector3.new(1.7, 2.2, 0.4),
		CFrame.new(2.5 * s, 7.95, -1.45) * A(math.rad(10), 0, 0),
		SEAT_FABRIC,
		M.Fabric
	)
end
block("Dash", Vector3.new(8.4, 1.0, 0.9), CFrame.new(0, 7.0, -6.9), CONSOLE, M.SmoothPlastic)
for _, x in { -1.1, 0, 1.1 } do
	block(
		"Screen",
		Vector3.new(0.9, 0.6, 0.04),
		CFrame.new(x, 7.15, -6.43),
		SCREEN,
		M.Glass,
		{ transparency = 0.2 }
	)
end
rod(
	"SteeringColumn",
	Vector3.new(0, 7.5, -6.4),
	Vector3.new(0, 8.4, -5.3),
	0.2,
	BLACK,
	M.SmoothPlastic
)
cyl(
	"SteeringWheel",
	0.12,
	1.4,
	CFrame.new(0, 8.6, -5.1) * A(math.rad(-35), 0, 0) * CYLINDER_Z,
	BLACK,
	M.SmoothPlastic
)
block(
	"ArmrestConsole",
	Vector3.new(0.3, 0.9, 1.4),
	CFrame.new(1.25, 7.0, -3.4),
	CONSOLE,
	M.SmoothPlastic
)
cyl("Joystick", 0.6, 0.2, CFrame.new(1.25, 7.75, -3.8) * CYLINDER_Y, CONSOLE, M.SmoothPlastic)
ball("JoystickKnob", 0.35, CFrame.new(1.25, 8.1, -3.8), BLACK, M.SmoothPlastic)

return {
	name = "Snowcat",
	-- Real: 23 km/h, 0-23 km/h in 6 s, brakes 0.4 g, coasts 0.3 g (VehicleDefaults maps them).
	speed = 20,
	acceleration = 4.5,
	braking = 10.8,
	coasting = 8.9,
	turnRate = 1.8,
	footprint = Vector2.new(15.6, 18.4),
	collision = {
		{ size = Vector3.new(15.6, 4.0, 18.4), offset = CFrame.new(0, 3.3, 0) },
		{ size = Vector3.new(8.8, 3.2, 7.2), offset = CFrame.new(0, 6.9, 3.2) },
		{ size = Vector3.new(18.0, 3.8, 1.6), offset = CFrame.new(0, 3.1, -13.6) },
		{ size = Vector3.new(18.0, 1.8, 3.2), offset = CFrame.new(0, 2.1, 12.4) },
	},
	seats = {
		CFrame.new(0, 6.3, -3.6),
		CFrame.new(-2.5, 6.3, -2.6),
		CFrame.new(2.5, 6.3, -2.6),
	},
	pieces = pieces,
}
