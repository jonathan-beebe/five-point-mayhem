-- Rolls-Royce Phantom: Phantom VIII limousine saloon in arctic white over diamond black two-tone.
-- Scale: 4 studs = 1 m. Front axle z -7.58, rear axle z 6.63, track 6.74, 22" wheels.

local rgb = Color3.fromRGB
local M = Enum.Material
local A = CFrame.Angles
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball
local CYLINDER_Z = A(0, math.rad(90), 0) -- cylinder axis along Z
local CYLINDER_Y = A(0, 0, math.rad(90)) -- cylinder axis along Y
-- WedgePart default: right angle at local (ymin, zmax), slope rising toward +Z.
local FLIP_Z = A(0, 0, math.pi) -- right angle at (ymax, zmax)
local FLIP_X = A(math.pi, 0, 0) -- right angle at (ymax, zmin)
local RISE_FWD = A(0, math.pi, 0) -- right angle at (ymin, zmin), slope rising toward -Z
local SIDE_L = A(0, math.pi / 2, 0) -- size.X is length along Z; tall face +X
local SIDE_R = A(0, -math.pi / 2, 0) -- size.X is length along Z; tall face -X

local WHITE = rgb(236, 236, 232)
local BLACK = rgb(18, 18, 22)
local COACHLINE = rgb(25, 45, 120)
local CHROME = rgb(210, 212, 218)
local GRILLE_DARK = rgb(15, 15, 17)
local TRIM_BLACK = rgb(25, 25, 27)
local GAP = rgb(12, 12, 14)
local LINER = rgb(22, 22, 24)
local GLASS = rgb(40, 50, 60)
local LAMP_BLACK = rgb(30, 32, 36)
local HEADLIGHT = rgb(255, 244, 220)
local DRL = rgb(235, 245, 255)
local AMBER = rgb(255, 150, 30)
local TAIL = rgb(200, 20, 25)
local TAIL_DARK = rgb(110, 10, 15)
local REVERSE = rgb(245, 245, 245)
local PLATE = rgb(225, 225, 220)
local TIRE = rgb(28, 28, 30)
local RIM_DARK = rgb(55, 57, 62)
local CAP_DARK = rgb(25, 25, 30)
local MIRROR = rgb(190, 200, 210)
local LEATHER = rgb(215, 200, 175)
local LEATHER_ACCENT = rgb(120, 70, 50)
local INT_DARK = rgb(35, 30, 28)
local CARPET = rgb(200, 190, 170)
local WOOD = rgb(95, 58, 35)
local GALLERY = rgb(200, 210, 220)
local CLOCK = rgb(240, 238, 230)
local HEADLINER = rgb(20, 20, 26)
local STAR = rgb(240, 245, 255)

local WHITE_REFLECT = 0.12
local BLACK_REFLECT = 0.15
local CHROME_REFLECT = 0.3
local GLASS_ALPHA = 0.4

local FRONT_AXLE = -7.58
local REAR_AXLE = 6.63
local AXLES = { FRONT_AXLE, REAR_AXLE }
local WHEEL_X = 3.37
local WHEEL_Y = 1.52
local SIDES = { -1, 1 }

-- Greenhouse tumblehome: side glass and pillars lean inward 10 degrees.
local TUMBLE = math.rad(10)

local pieces = {}

local function part(name, size, offset, color, material, extra)
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
	table.insert(pieces, p)
	return p
end

local function wedge(name, size, offset, color, material, extra)
	local p = part(name, size, offset, color, material, extra)
	p.class = "WedgePart"
	return p
end

local function white(name, size, offset)
	return part(name, size, offset, WHITE, M.SmoothPlastic, { reflectance = WHITE_REFLECT })
end

local function black(name, size, offset)
	return part(name, size, offset, BLACK, M.SmoothPlastic, { reflectance = BLACK_REFLECT })
end

local function chrome(name, size, offset)
	return part(name, size, offset, CHROME, M.Metal, { reflectance = CHROME_REFLECT })
end

local function neon(name, size, offset, color)
	return part(name, size, offset, color, M.Neon)
end

local function glass(name, size, offset)
	return part(name, size, offset, GLASS, M.Glass, { transparency = GLASS_ALPHA })
end

local function cyl(name, size, offset, color, material, extra)
	local p = part(name, size, offset, color, material, extra)
	p.shape = CYL
	return p
end

local function ball(name, d, offset, color, material, extra)
	local p = part(name, Vector3.new(d, d, d), offset, color, material, extra)
	p.shape = BALL
	return p
end

------------------------------------------------------------------------------------------------
-- Body: liner core, white lower body split around the arches, black hood, belt and trunk.
------------------------------------------------------------------------------------------------

part("CoreFront", Vector3.new(5.7, 3.1, 7.4), CFrame.new(0, 2.35, -7.5), LINER)
part("CoreCabinFloor", Vector3.new(5.7, 0.8, 8.4), CFrame.new(0, 1.2, 0.4), LINER)
part("CoreRear", Vector3.new(5.7, 3.1, 6.6), CFrame.new(0, 2.35, 7.9), LINER)

for _, s in SIDES do
	local x = s * 3.425
	white("SideFrontOverhang", Vector3.new(1.15, 3.15, 1.67), CFrame.new(x, 2.325, -10.165))
	white("SideAboveFrontArch", Vector3.new(1.15, 0.63, 3.5), CFrame.new(x, 3.585, FRONT_AXLE))
	white("SideDoors", Vector3.new(1.15, 3.15, 10.71), CFrame.new(x, 2.325, -0.475))
	white("SideAboveRearArch", Vector3.new(1.15, 0.63, 3.5), CFrame.new(x, 3.585, REAR_AXLE))
	white("SideRearOverhang", Vector3.new(1.15, 3.15, 2.82), CFrame.new(x, 2.325, 9.79))
	for _, axle in AXLES do
		wedge(
			"ArchCornerFront",
			Vector3.new(1.15, 0.55, 0.55),
			CFrame.new(x, 2.995, axle - 1.475) * FLIP_X,
			WHITE,
			M.SmoothPlastic,
			{ reflectance = WHITE_REFLECT }
		)
		wedge(
			"ArchCornerRear",
			Vector3.new(1.15, 0.55, 0.55),
			CFrame.new(x, 2.995, axle + 1.475) * FLIP_Z,
			WHITE,
			M.SmoothPlastic,
			{ reflectance = WHITE_REFLECT }
		)
	end
	-- Black arch liner lip, set just inside the opening.
	for _, axle in AXLES do
		part("ArchLiner", Vector3.new(0.9, 0.06, 3.5), CFrame.new(s * 3.45, 3.24, axle), LINER)
	end
end

white("FrontBumper", Vector3.new(8.0, 1.25, 0.5), CFrame.new(0, 1.675, -11.25))
wedge(
	"FrontBumperChamfer",
	Vector3.new(8.0, 0.3, 0.5),
	CFrame.new(0, 0.9, -11.25) * FLIP_Z,
	WHITE,
	M.SmoothPlastic,
	{ reflectance = WHITE_REFLECT }
)
for _, s in SIDES do
	white("FasciaSide", Vector3.new(2.55, 1.6, 0.4), CFrame.new(s * 2.725, 3.1, -11.2))
end

black("Hood", Vector3.new(8.0, 0.45, 7.55), CFrame.new(0, 4.125, -7.575))
part("CowlStrip", Vector3.new(7.4, 0.1, 0.3), CFrame.new(0, 4.4, -3.85), TRIM_BLACK)
for _, s in SIDES do
	black("BeltRail", Vector3.new(1.0, 0.35, 12.2), CFrame.new(s * 3.5, 4.075, 2.3))
end
black("TrunkDeck", Vector3.new(8.0, 0.6, 2.0), CFrame.new(0, 4.2, 9.4))
wedge(
	"TrunkTail",
	Vector3.new(8.0, 0.6, 1.0),
	CFrame.new(0, 4.2, 10.9) * RISE_FWD,
	BLACK,
	M.SmoothPlastic,
	{ reflectance = BLACK_REFLECT }
)
white("RearPanel", Vector3.new(8.0, 2.85, 0.3), CFrame.new(0, 2.475, 11.35))
wedge(
	"RearBumperChamfer",
	Vector3.new(7.8, 0.3, 0.5),
	CFrame.new(0, 0.9, 11.25) * FLIP_X,
	WHITE,
	M.SmoothPlastic,
	{ reflectance = WHITE_REFLECT }
)
part("ParcelShelf", Vector3.new(6.0, 0.1, 3.4), CFrame.new(0, 4.3, 6.6), INT_DARK, M.Fabric)

-- Roof and pillars.
black("Roof", Vector3.new(6.2, 0.15, 6.9), CFrame.new(0, 6.505, 2.15))
wedge(
	"RoofChamferL",
	Vector3.new(6.9, 0.15, 0.3),
	CFrame.new(-3.25, 6.505, 2.15) * SIDE_L,
	BLACK,
	M.SmoothPlastic,
	{ reflectance = BLACK_REFLECT }
)
wedge(
	"RoofChamferR",
	Vector3.new(6.9, 0.15, 0.3),
	CFrame.new(3.25, 6.505, 2.15) * SIDE_R,
	BLACK,
	M.SmoothPlastic,
	{ reflectance = BLACK_REFLECT }
)

local WINDSHIELD_PITCH = A(math.rad(-39.4), 0, 0)
for _, s in SIDES do
	local lean = A(0, 0, s * TUMBLE)
	black(
		"APillar",
		Vector3.new(0.4, 0.22, 3.23),
		CFrame.new(s * 3.45, 5.425, -2.55) * WINDSHIELD_PITCH
	)
	black("BPillar", Vector3.new(0.22, 2.23, 0.35), CFrame.new(s * 3.555, 5.35, -0.025) * lean)
	black("CPillar", Vector3.new(0.22, 2.23, 1.6), CFrame.new(s * 3.555, 5.35, 4.8) * lean)
	wedge(
		"CPillarSail",
		Vector3.new(0.22, 2.2, 2.8),
		CFrame.new(s * 3.555, 5.35, 7.0) * lean * RISE_FWD,
		BLACK,
		M.SmoothPlastic,
		{ reflectance = BLACK_REFLECT }
	)
end

------------------------------------------------------------------------------------------------
-- Glass.
------------------------------------------------------------------------------------------------

glass("Windshield", Vector3.new(6.9, 0.08, 3.23), CFrame.new(0, 5.425, -2.55) * WINDSHIELD_PITCH)
glass(
	"RearGlass",
	Vector3.new(6.0, 0.08, 3.47),
	CFrame.new(0, 5.425, 7.0) * A(math.rad(36.2), 0, 0)
)
for _, s in SIDES do
	local lean = A(0, 0, s * TUMBLE)
	local tri = wedge(
		"FrontQuarterGlass",
		Vector3.new(0.08, 2.05, 2.5),
		CFrame.new(s * 3.6, 5.425, -2.55) * lean,
		GLASS,
		M.Glass
	)
	tri.transparency = GLASS_ALPHA
	glass("FrontDoorGlass", Vector3.new(0.08, 2.23, 1.1), CFrame.new(s * 3.555, 5.35, -0.75) * lean)
	glass("RearDoorGlass", Vector3.new(0.08, 2.23, 3.85), CFrame.new(s * 3.555, 5.35, 2.075) * lean)
	chrome("BeltChrome", Vector3.new(0.1, 0.05, 7.8), CFrame.new(s * 3.78, 4.28, 0.1))
end

------------------------------------------------------------------------------------------------
-- Pantheon grille and Spirit of Ecstasy.
------------------------------------------------------------------------------------------------

chrome("GrilleTop", Vector3.new(2.9, 0.22, 0.45), CFrame.new(0, 4.34, -11.375))
-- Grille crown: the polished surround blends back into the bonnet.
wedge(
	"GrilleCrown",
	Vector3.new(2.9, 0.1, 0.8),
	CFrame.new(0, 4.4, -10.75) * RISE_FWD,
	CHROME,
	M.Metal,
	{ reflectance = CHROME_REFLECT }
)
chrome("GrilleBottom", Vector3.new(2.9, 0.18, 0.45), CFrame.new(0, 2.34, -11.375))
for _, s in SIDES do
	chrome("GrilleSide", Vector3.new(0.2, 2.2, 0.45), CFrame.new(s * 1.35, 3.35, -11.375))
end
part("GrilleBacking", Vector3.new(2.5, 1.9, 0.1), CFrame.new(0, 3.35, -11.3), GRILLE_DARK, M.Metal)
for i = 0, 12 do
	chrome("GrilleSlat", Vector3.new(0.06, 1.8, 0.25), CFrame.new(-1.08 + i * 0.18, 3.35, -11.45))
end

chrome("SoE_Base", Vector3.new(0.3, 0.05, 0.3), CFrame.new(0, 4.46, -11.05))
cyl(
	"SoE_Plinth",
	Vector3.new(0.1, 0.22, 0.22),
	CFrame.new(0, 4.55, -11.05) * CYLINDER_Y,
	CHROME,
	M.Metal,
	{
		reflectance = CHROME_REFLECT,
	}
)
chrome(
	"SoE_Body",
	Vector3.new(0.08, 0.38, 0.1),
	CFrame.new(0, 4.76, -11.1) * A(math.rad(-25), 0, 0)
)
ball(
	"SoE_Head",
	0.09,
	CFrame.new(0, 4.95, -11.2),
	CHROME,
	M.Metal,
	{ reflectance = CHROME_REFLECT }
)
for _, s in SIDES do
	chrome(
		"SoE_Wing",
		Vector3.new(0.03, 0.12, 0.35),
		CFrame.new(s * 0.07, 4.85, -11.0) * A(math.rad(-20), s * math.rad(12), 0)
	)
end

------------------------------------------------------------------------------------------------
-- Headlamps and lower front.
------------------------------------------------------------------------------------------------

for _, s in SIDES do
	part(
		"HeadlampHousing",
		Vector3.new(1.9, 0.5, 0.06),
		CFrame.new(s * 2.7, 3.55, -11.43),
		LAMP_BLACK,
		M.Glass,
		{ transparency = 0.15 }
	)
	ball("HeadlampProjector", 0.3, CFrame.new(s * 2.25, 3.5, -11.44), HEADLIGHT, M.Neon)
	ball("HeadlampProjector", 0.3, CFrame.new(s * 3.05, 3.5, -11.44), HEADLIGHT, M.Neon)
	neon("DRL", Vector3.new(1.9, 0.07, 0.04), CFrame.new(s * 2.7, 3.78, -11.45), DRL)
	chrome("HeadlampChromeTop", Vector3.new(1.95, 0.04, 0.05), CFrame.new(s * 2.7, 3.82, -11.44))
	chrome("HeadlampChromeBottom", Vector3.new(1.95, 0.04, 0.05), CFrame.new(s * 2.7, 3.28, -11.44))
end

part("LowerIntake", Vector3.new(4.6, 0.45, 0.06), CFrame.new(0, 1.45, -11.53), GRILLE_DARK, M.Metal)
chrome("IntakeChromeBar", Vector3.new(4.8, 0.08, 0.06), CFrame.new(0, 1.7, -11.55))
for _, s in SIDES do
	part(
		"CornerIntake",
		Vector3.new(0.7, 0.6, 0.06),
		CFrame.new(s * 3.1, 1.45, -11.53),
		GRILLE_DARK,
		M.Metal
	)
	neon("Indicator", Vector3.new(0.6, 0.1, 0.04), CFrame.new(s * 3.1, 2.05, -11.53), AMBER)
end

------------------------------------------------------------------------------------------------
-- Rear.
------------------------------------------------------------------------------------------------

for _, s in SIDES do
	part(
		"TailLensFrame",
		Vector3.new(0.85, 1.4, 0.04),
		CFrame.new(s * 3.45, 3.1, 11.52),
		TAIL_DARK,
		M.Glass,
		{ transparency = 0.2 }
	)
	neon("TailNeon", Vector3.new(0.65, 1.2, 0.04), CFrame.new(s * 3.45, 3.1, 11.55), TAIL)
	neon("Reverse", Vector3.new(0.3, 0.2, 0.04), CFrame.new(s * 3.45, 2.6, 11.57), REVERSE)
	part("Reflector", Vector3.new(0.5, 0.08, 0.04), CFrame.new(s * 3.2, 1.4, 11.62), TAIL_DARK)
	part("ExhaustSlit", Vector3.new(1.2, 0.08, 0.03), CFrame.new(s * 2.0, 1.12, 11.61), GAP)
end
white("RearBumper", Vector3.new(8.0, 0.95, 0.1), CFrame.new(0, 1.525, 11.55))
part("RearBumperLine", Vector3.new(7.6, 0.03, 0.03), CFrame.new(0, 2.0, 11.51), GAP)
chrome("TrunkChrome", Vector3.new(5.2, 0.1, 0.05), CFrame.new(0, 3.75, 11.53))
part("Plate", Vector3.new(2.0, 0.6, 0.04), CFrame.new(0, 2.4, 11.53), PLATE)

------------------------------------------------------------------------------------------------
-- Wheels: 22" polished six-spoke rims.
------------------------------------------------------------------------------------------------

for _, s in SIDES do
	for _, z in AXLES do
		local cx = s * WHEEL_X
		local center = CFrame.new(cx, WHEEL_Y, z)
		local face = CFrame.new(cx + s * 0.58, WHEEL_Y, z)
		cyl("Tire", Vector3.new(1.1, 3.04, 3.04), center, TIRE)
		cyl("RimBarrel", Vector3.new(1.12, 2.24, 2.24), center, RIM_DARK, M.Metal)
		for k = 0, 2 do
			chrome("SpokeBar", Vector3.new(0.06, 2.1, 0.2), face * A(k * math.rad(60), 0, 0))
		end
		for i = 0, 7 do
			chrome(
				"RimLip",
				Vector3.new(0.06, 0.14, 0.86),
				face * A(i * math.rad(45), 0, 0) * CFrame.new(0, 1.07, 0)
			)
		end
		cyl(
			"CenterCap",
			Vector3.new(0.06, 0.6, 0.6),
			CFrame.new(s * (WHEEL_X + 0.6), WHEEL_Y, z),
			CAP_DARK,
			M.Metal
		)
		ball("CapEmblem", 0.2, CFrame.new(s * (WHEEL_X + 0.63), WHEEL_Y, z), CHROME, M.Metal, {
			reflectance = CHROME_REFLECT,
		})
	end
end

------------------------------------------------------------------------------------------------
-- Interior.
------------------------------------------------------------------------------------------------

part("Carpet", Vector3.new(5.7, 0.1, 8.4), CFrame.new(0, 1.65, 0.4), CARPET, M.Fabric)
part("Dash", Vector3.new(6.6, 0.8, 1.4), CFrame.new(0, 4.0, -3.1), INT_DARK, M.Fabric)
part(
	"DashWood",
	Vector3.new(6.4, 0.45, 0.05),
	CFrame.new(0, 3.95, -2.37),
	WOOD,
	M.Wood,
	{ reflectance = 0.15 }
)
part("GalleryGlass", Vector3.new(3.0, 0.3, 0.04), CFrame.new(1.2, 4.2, -2.34), GALLERY, M.Glass, {
	transparency = 0.3,
})
part("Binnacle", Vector3.new(1.4, 0.4, 0.1), CFrame.new(-1.6, 4.3, -2.37), LAMP_BLACK, M.Glass)
cyl(
	"ClockBezel",
	Vector3.new(0.03, 0.32, 0.32),
	CFrame.new(0, 3.95, -2.34) * CYLINDER_Z,
	CHROME,
	M.Metal,
	{
		reflectance = CHROME_REFLECT,
	}
)
cyl("ClockFace", Vector3.new(0.04, 0.26, 0.26), CFrame.new(0, 3.95, -2.33) * CYLINDER_Z, CLOCK)
part("Console", Vector3.new(0.9, 0.9, 2.6), CFrame.new(0, 2.1, -1.9), INT_DARK, M.Fabric)

local WHEEL_TILT = A(math.rad(-25), 0, 0)
cyl(
	"Column",
	Vector3.new(0.6, 0.15, 0.15),
	CFrame.new(-1.6, 4.0, -2.3) * WHEEL_TILT * CYLINDER_Z,
	INT_DARK,
	M.Fabric
)
local wheelFrame = CFrame.new(-1.6, 4.15, -2.05) * WHEEL_TILT
cyl("SteeringWheel", Vector3.new(0.08, 1.35, 1.35), wheelFrame * CYLINDER_Z, INT_DARK, M.Fabric)
cyl(
	"WheelHub",
	Vector3.new(0.06, 0.4, 0.4),
	wheelFrame * CFrame.new(0, 0, 0.04) * CYLINDER_Z,
	CHROME,
	M.Metal
)

for _, s in SIDES do
	part(
		"FrontCushion",
		Vector3.new(2.0, 0.45, 2.0),
		CFrame.new(s * 1.6, 2.08, -0.6),
		LEATHER,
		M.Fabric
	)
	part(
		"FrontBackrest",
		Vector3.new(2.0, 2.5, 0.4),
		CFrame.new(s * 1.6, 3.55, 0.42) * A(math.rad(10), 0, 0),
		LEATHER,
		M.Fabric
	)
	part(
		"FrontHeadrest",
		Vector3.new(1.1, 0.6, 0.3),
		CFrame.new(s * 1.6, 5.1, 0.65),
		LEATHER,
		M.Fabric
	)
	part(
		"RearHeadrest",
		Vector3.new(1.1, 0.6, 0.3),
		CFrame.new(s * 1.7, 5.0, 5.1),
		LEATHER,
		M.Fabric
	)
	part(
		"DoorTrim",
		Vector3.new(0.05, 0.9, 8.3),
		CFrame.new(s * 2.82, 3.75, 0.4),
		LEATHER,
		M.Fabric
	)
end
part("RearCushion", Vector3.new(5.4, 0.45, 2.1), CFrame.new(0, 2.08, 3.6), LEATHER, M.Fabric)
part(
	"RearBackrest",
	Vector3.new(5.4, 2.4, 0.45),
	CFrame.new(0, 3.5, 4.85) * A(math.rad(8), 0, 0),
	LEATHER,
	M.Fabric
)
part("RearArmrest", Vector3.new(0.6, 0.35, 1.6), CFrame.new(0, 2.9, 3.9), LEATHER_ACCENT, M.Fabric)
part("Headliner", Vector3.new(6.0, 0.04, 6.7), CFrame.new(0, 6.41, 2.15), HEADLINER, M.Fabric)

-- Starlight headliner: a jittered grid of fibre-optic stars.
local STAR_X = { -2.2, -0.8, 0.8, 2.2 }
local STAR_Z = { -0.4, 2.0, 4.4 }
local JITTER = { 0.2, -0.25, 0.1, -0.05, 0.3, -0.15, 0.25, -0.3, 0.05, 0.15, -0.2, 0.28 }
local j = 0
for _, sx in STAR_X do
	for _, sz in STAR_Z do
		j += 1
		local jx = JITTER[j]
		local jz = JITTER[(j % #JITTER) + 1]
		ball("Star", 0.07, CFrame.new(sx + jx, 6.37, sz + jz), STAR, M.Neon)
	end
end

------------------------------------------------------------------------------------------------
-- Details: mirrors, wipers, shut lines, coach-door handles, coachline, sills.
------------------------------------------------------------------------------------------------

for _, s in SIDES do
	black("MirrorArm", Vector3.new(0.45, 0.15, 0.25), CFrame.new(s * 4.0, 4.325, -3.3))
	black("MirrorHousing", Vector3.new(0.7, 0.42, 0.32), CFrame.new(s * 4.45, 4.5, -3.35))
	part(
		"MirrorGlass",
		Vector3.new(0.58, 0.32, 0.03),
		CFrame.new(s * 4.45, 4.5, -3.17),
		MIRROR,
		M.Glass,
		{
			reflectance = 0.4,
		}
	)
	part(
		"Wiper",
		Vector3.new(2.4, 0.06, 0.08),
		CFrame.new(s * 1.3, 4.47, -3.6) * A(0, s * math.rad(8), 0),
		TRIM_BLACK
	)

	local gx = s * 4.01
	part("GapFrontDoor", Vector3.new(0.03, 3.1, 0.05), CFrame.new(gx, 2.35, -5.5), GAP)
	part("GapBPillar", Vector3.new(0.03, 3.45, 0.05), CFrame.new(gx, 2.525, -0.02), GAP)
	part("GapRearDoor", Vector3.new(0.03, 3.45, 0.05), CFrame.new(gx, 2.525, 4.6), GAP)
	part("HoodShutLine", Vector3.new(0.04, 0.02, 7.3), CFrame.new(s * 3.0, 4.36, -7.5), GAP)

	chrome("HandleFront", Vector3.new(0.08, 0.12, 0.55), CFrame.new(s * 4.05, 3.6, -0.55))
	chrome("HandleRear", Vector3.new(0.08, 0.12, 0.55), CFrame.new(s * 4.05, 3.6, 0.5))
	part("Coachline", Vector3.new(0.02, 0.05, 18.0), CFrame.new(s * 4.04, 3.78, -0.5), COACHLINE)
	chrome("SillChrome", Vector3.new(0.03, 0.08, 10.0), CFrame.new(s * 4.02, 1.0, -0.5))
end

return {
	name = "Rolls-Royce Phantom",
	speed = 110,
	turnRate = 2,
	footprint = Vector2.new(7.6, 22.6),
	collision = {
		{ size = Vector3.new(7.9, 3.0, 22.8), offset = CFrame.new(0, 2.7, 0) },
		{ size = Vector3.new(6.8, 2.2, 9.4), offset = CFrame.new(0, 5.3, 1.4) },
	},
	seats = {
		CFrame.new(-1.6, 1.8, -0.6), -- driver (LHD)
		CFrame.new(1.6, 1.8, -0.6),
		CFrame.new(-1.7, 1.8, 3.6),
		CFrame.new(1.7, 1.8, 3.6),
	},
	pieces = pieces,
}
