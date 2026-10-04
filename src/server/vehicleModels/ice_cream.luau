-- Ice Cream Truck: Grumman Kurbmaster step van on a Chevrolet P30 chassis with pastel bands, serving window and roof cone.
-- Scale: 4 studs = 1 m. Front axle z -8.4, rear duals z 4.5, 8R19.5 tires. Left-hand drive.

local rgb = Color3.fromRGB
local M = Enum.Material
local A = CFrame.Angles
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball
local CYL_Z = A(0, math.rad(90), 0) -- cylinder axis along Z
local CYL_Y = A(0, 0, math.rad(90)) -- cylinder axis along Y (size.X = height)
-- WedgePart default: full bottom and full back (+Z) faces, slope rising toward +Z.
local REV = A(0, math.pi, 0) -- slope rises toward -Z
local FLIP_X = A(math.pi, 0, 0) -- right angle at (ymax, zmin)
local FLIP_Z = A(0, 0, math.pi) -- right angle at (ymax, zmax)
local SIDE_R = A(0, -math.pi / 2, 0) -- size (lenZ, h, wX); tall face at -X, slope descends to +X
local SIDE_L = A(0, math.pi / 2, 0) -- size (lenZ, h, wX); tall face at +X, slope descends to -X
-- Vertical corner chamfers, size (h, wX, dZ); the slope faces the named corner.
local CORNER_FL = A(0, 0, math.pi / 2)
local CORNER_FR = A(0, 0, -math.pi / 2)
local CORNER_RL = A(0, math.pi, 0) * A(0, 0, -math.pi / 2)
local CORNER_RR = A(0, math.pi, 0) * A(0, 0, math.pi / 2)

local BODY = rgb(245, 245, 242)
local PINK = rgb(247, 168, 196)
local BLUE = rgb(150, 205, 235)
local AWNING_WHITE = rgb(250, 250, 248)
local CHROME = rgb(210, 210, 215)
local STAINLESS = rgb(190, 190, 195)
local RIM_WHITE = rgb(235, 235, 230)
local TIRE = rgb(28, 28, 30)
local SHOULDER = rgb(40, 40, 42)
local RUBBER = rgb(30, 30, 32)
local GAP = rgb(35, 35, 38)
local CHASSIS = rgb(40, 40, 42)
local LINER = rgb(18, 18, 18)
local GLASS = rgb(150, 190, 210)
local HEADLAMP = rgb(255, 240, 200)
local AMBER = rgb(255, 160, 40)
local TAIL_RED = rgb(230, 30, 30)
local REVERSE = rgb(245, 245, 245)
local STOP_RED = rgb(200, 25, 25)
local CAUTION = rgb(255, 210, 40)
local WAFFLE = rgb(214, 160, 90)
local WAFFLE_DARK = rgb(190, 135, 70)
local CONE_RIM = rgb(200, 145, 78)
local SCOOP = rgb(247, 150, 185)
local CREAM = rgb(252, 248, 235)
local CHERRY = rgb(200, 20, 30)
local MENU_YELLOW = rgb(255, 236, 150)
local MENU_MINT = rgb(190, 235, 215)
local MENU_PINK = rgb(252, 215, 228)
local FLOOR = rgb(55, 55, 58)
local DASH = rgb(50, 50, 54)
local BLACK = rgb(25, 25, 27)
local VINYL = rgb(90, 60, 45)
local PLATE_STEEL = rgb(150, 150, 155)
local PLATE = rgb(240, 240, 235)
local GRILLE_BLACK = rgb(20, 20, 22)
local GREY = rgb(150, 150, 155)
local LIGHT_GREY = rgb(205, 205, 208)

local TILE_COLORS = {
	rgb(255, 182, 193),
	rgb(173, 216, 230),
	rgb(255, 250, 205),
	rgb(152, 251, 152),
	rgb(255, 200, 150),
	rgb(221, 160, 221),
	rgb(139, 90, 60),
	rgb(255, 255, 255),
}

local PAINT_REFLECT = 0.08
local PASTEL_REFLECT = 0.06
local CHROME_REFLECT = 0.25
local GLASS_ALPHA = 0.45
local RAKE = A(math.rad(8.1), 0, 0) -- windshield, top leans toward +Z

local FRONT_AXLE = -8.4
local REAR_AXLE = 4.5
local WHEEL_Y = 1.65

local pieces = {}

local function part(name, size, offset, color, material, extra)
	local spec = {
		name = name,
		size = size,
		offset = offset,
		color = color,
		material = material or M.SmoothPlastic,
	}
	if extra then
		for k, v in extra do
			spec[k] = v
		end
	end
	table.insert(pieces, spec)
end

local function wedge(name, size, offset, color, material, extra)
	local e = { class = "WedgePart" }
	if extra then
		for k, v in extra do
			e[k] = v
		end
	end
	part(name, size, offset, color, material, e)
end

local function cyl(name, size, offset, color, material, extra)
	local e = { shape = CYL }
	if extra then
		for k, v in extra do
			e[k] = v
		end
	end
	part(name, size, offset, color, material, e)
end

local function ball(name, d, pos, color, material, extra)
	local e = { shape = BALL }
	if extra then
		for k, v in extra do
			e[k] = v
		end
	end
	part(name, Vector3.new(d, d, d), CFrame.new(pos), color, material, e)
end

local function paint(name, size, offset, color)
	part(name, size, offset, color or BODY, M.SmoothPlastic, { reflectance = PAINT_REFLECT })
end

local function pastel(name, size, offset, color)
	part(name, size, offset, color, M.SmoothPlastic, { reflectance = PASTEL_REFLECT })
end

local function lamp(name, size, offset, color, extra)
	part(name, size, offset, color, M.Neon, extra)
end

local function glass(name, size, offset)
	part(name, size, offset, GLASS, M.Glass, { transparency = GLASS_ALPHA, reflectance = 0.1 })
end

local SIDES = { -1, 1 }

---------------------------------------------------------------------------------------------------
-- Body shell
---------------------------------------------------------------------------------------------------
paint("NoseFace", Vector3.new(8.4, 3.6, 0.2), CFrame.new(0, 4.0, -11.8))
paint("Hood", Vector3.new(9.2, 0.3, 1.55), CFrame.new(0, 5.85, -10.725))
wedge(
	"HoodChamfer",
	Vector3.new(8.4, 0.3, 0.4),
	CFrame.new(0, 5.85, -11.7),
	BODY,
	M.SmoothPlastic,
	{
		reflectance = PAINT_REFLECT,
	}
)
part("Cowl", Vector3.new(8.8, 0.2, 0.3), CFrame.new(0, 6.05, -10.1), CHASSIS)
paint("Header", Vector3.new(9.2, 0.8, 0.6), CFrame.new(0, 10.6, -9.5))
wedge(
	"RoofFrontChamfer",
	Vector3.new(9.2, 0.4, 0.5),
	CFrame.new(0, 11.2, -9.55),
	BODY,
	M.SmoothPlastic,
	{
		reflectance = PAINT_REFLECT,
	}
)
paint("Roof", Vector3.new(8.4, 0.4, 20.9), CFrame.new(0, 11.2, 1.15))
wedge(
	"RoofRearChamfer",
	Vector3.new(9.2, 0.4, 0.4),
	CFrame.new(0, 11.2, 11.8) * REV,
	BODY,
	M.SmoothPlastic,
	{
		reflectance = PAINT_REFLECT,
	}
)
paint("RearFace", Vector3.new(8.4, 8.6, 0.2), CFrame.new(0, 6.7, 11.9))

for _, s in SIDES do
	wedge(
		"NoseCorner",
		Vector3.new(3.8, 0.4, 0.4),
		CFrame.new(s * 4.4, 4.1, -11.7) * (s < 0 and CORNER_FL or CORNER_FR),
		BODY,
		M.SmoothPlastic,
		{ reflectance = PAINT_REFLECT }
	)
	paint("NoseSide", Vector3.new(0.2, 3.6, 1.1), CFrame.new(s * 4.5, 4.0, -10.95))
	wedge(
		"RoofSideChamfer",
		Vector3.new(20.9, 0.4, 0.4),
		CFrame.new(s * 4.4, 11.2, 1.15) * (s > 0 and SIDE_R or SIDE_L),
		BODY,
		M.SmoothPlastic,
		{ reflectance = PAINT_REFLECT }
	)
	wedge(
		"RearCorner",
		Vector3.new(8.6, 0.4, 0.4),
		CFrame.new(s * 4.4, 6.7, 11.8) * (s < 0 and CORNER_RL or CORNER_RR),
		BODY,
		M.SmoothPlastic,
		{ reflectance = PAINT_REFLECT }
	)
	paint("LowerSide", Vector3.new(0.2, 2.0, 22.0), CFrame.new(s * 4.5, 5.0, 0.6))

	-- Skirts around the wheel arches (y 2.4..4.0).
	for _, seg in { { -11.5, -10.4 }, { -6.4, 2.4 }, { 6.6, 11.6 } } do
		local len = seg[2] - seg[1]
		local zc = (seg[1] + seg[2]) / 2
		paint("Skirt", Vector3.new(0.2, 1.6, len), CFrame.new(s * 4.5, 3.2, zc))
		pastel("BlueUnderBand", Vector3.new(0.04, 0.4, len), CFrame.new(s * 4.63, 4.1, zc), BLUE)
	end

	-- Wheel arches: rounded top corners, black liners, rubber lips.
	for _, arch in { { -10.4, -6.4, FRONT_AXLE, 4.0 }, { 2.4, 6.6, REAR_AXLE, 4.2 } } do
		wedge(
			"ArchCorner",
			Vector3.new(0.2, 0.5, 0.5),
			CFrame.new(s * 4.5, 3.75, arch[1] + 0.25) * FLIP_X,
			BODY,
			M.SmoothPlastic,
			{ reflectance = PAINT_REFLECT }
		)
		wedge(
			"ArchCorner",
			Vector3.new(0.2, 0.5, 0.5),
			CFrame.new(s * 4.5, 3.75, arch[2] - 0.25) * FLIP_Z,
			BODY,
			M.SmoothPlastic,
			{ reflectance = PAINT_REFLECT }
		)
		part("ArchLiner", Vector3.new(0.8, 0.8, arch[4]), CFrame.new(s * 4.0, 3.65, arch[3]), LINER)
	end

	-- Cab openings (window y 7.0..9.8) and B-pillar.
	paint("CabLower", Vector3.new(0.2, 1.0, 4.0), CFrame.new(s * 4.5, 6.5, -7.8))
	paint("CabUpper", Vector3.new(0.2, 1.2, 4.0), CFrame.new(s * 4.5, 10.4, -7.8))
	paint("BPillar", Vector3.new(0.2, 5.0, 0.5), CFrame.new(s * 4.5, 8.5, -5.55))
	glass("CabGlass", Vector3.new(0.08, 2.78, 3.9), CFrame.new(s * 4.52, 8.4, -7.8))

	-- Door seams.
	for _, z in { -9.72, -5.82 } do
		part("DoorSeam", Vector3.new(0.04, 6.1, 0.05), CFrame.new(s * 4.66, 7.15, z), GAP)
	end
end

-- Right side (+X): serving-window opening y 6.0..9.6, z -2.8..+3.2.
paint("PanelFwdWindow", Vector3.new(0.2, 5.0, 2.5), CFrame.new(4.5, 8.5, -4.05))
paint("WindowHeader", Vector3.new(0.2, 1.4, 6.0), CFrame.new(4.5, 10.3, 0.2))
paint("PanelAftWindow", Vector3.new(0.2, 5.0, 8.4), CFrame.new(4.5, 8.5, 7.4))
-- Left side (-X).
paint("PanelLeft", Vector3.new(0.2, 5.0, 16.9), CFrame.new(-4.5, 8.5, 3.15))

---------------------------------------------------------------------------------------------------
-- Pastel bands
---------------------------------------------------------------------------------------------------
for _, s in SIDES do
	pastel("PinkBelt", Vector3.new(0.04, 0.6, 23.0), CFrame.new(s * 4.63, 4.7, 0.05), PINK)
	pastel("BlueRoofBand", Vector3.new(0.04, 0.4, 21.3), CFrame.new(s * 4.63, 10.4, 0.9), BLUE)
end
pastel("PinkBeltFront", Vector3.new(7.6, 0.5, 0.04), CFrame.new(0, 5.4, -11.93), PINK)
pastel("PinkBeltRear", Vector3.new(8.4, 0.6, 0.04), CFrame.new(0, 4.7, 12.03), PINK)
pastel("BlueUnderRear", Vector3.new(8.4, 0.4, 0.04), CFrame.new(0, 4.1, 12.03), BLUE)
pastel("BlueRoofRear", Vector3.new(8.4, 0.4, 0.04), CFrame.new(0, 10.4, 12.03), BLUE)

---------------------------------------------------------------------------------------------------
-- Windshield, serving window, rear windows
---------------------------------------------------------------------------------------------------
for _, s in SIDES do
	glass("Windshield", Vector3.new(4.15, 4.25, 0.08), CFrame.new(s * 2.15, 8.1, -9.7) * RAKE)
	paint("APillar", Vector3.new(0.3, 4.3, 0.3), CFrame.new(s * 4.45, 8.1, -9.7) * RAKE)
end
part("CenterPost", Vector3.new(0.15, 4.3, 0.12), CFrame.new(0, 8.1, -9.72) * RAKE, RUBBER)

glass("SlidingPane", Vector3.new(0.06, 3.4, 3.0), CFrame.new(4.45, 7.8, 1.7))
part("SlideTrack", Vector3.new(0.12, 0.1, 6.0), CFrame.new(4.45, 9.55, 0.2), STAINLESS, M.Metal)
for _, y in { 9.6, 6.0 } do
	part(
		"WindowFrame",
		Vector3.new(0.1, 0.12, 6.2),
		CFrame.new(4.62, y, 0.2),
		CHROME,
		M.Metal,
		{ reflectance = CHROME_REFLECT }
	)
end
for _, z in { -2.8, 3.2 } do
	part(
		"WindowFrame",
		Vector3.new(0.1, 3.7, 0.12),
		CFrame.new(4.62, 7.8, z),
		CHROME,
		M.Metal,
		{ reflectance = CHROME_REFLECT }
	)
end
for _, s in SIDES do
	glass("RearDoorWindow", Vector3.new(1.8, 1.8, 0.06), CFrame.new(s * 1.5, 8.4, 12.04))
end

---------------------------------------------------------------------------------------------------
-- Lights
---------------------------------------------------------------------------------------------------
for _, s in SIDES do
	cyl(
		"HeadlightBezel",
		Vector3.new(0.15, 1.1, 1.1),
		CFrame.new(s * 3.2, 4.5, -11.95) * CYL_Z,
		CHROME,
		M.Metal,
		{ reflectance = CHROME_REFLECT }
	)
	lamp(
		"Headlight",
		Vector3.new(0.1, 0.85, 0.85),
		CFrame.new(s * 3.2, 4.5, -12.02) * CYL_Z,
		HEADLAMP,
		{
			shape = CYL,
		}
	)
	lamp("FrontTurn", Vector3.new(0.65, 0.35, 0.06), CFrame.new(s * 3.2, 3.55, -11.94), AMBER)
	lamp("SideMarkerFront", Vector3.new(0.04, 0.25, 0.4), CFrame.new(s * 4.64, 5.6, -11.0), AMBER)
	lamp("SideMarkerRear", Vector3.new(0.04, 0.25, 0.4), CFrame.new(s * 4.64, 5.6, 11.2), TAIL_RED)
	lamp("TailLight", Vector3.new(0.5, 1.6, 0.06), CFrame.new(s * 3.95, 4.2, 12.05), TAIL_RED)
	lamp("BackupLight", Vector3.new(0.5, 0.35, 0.06), CFrame.new(s * 3.95, 3.15, 12.05), REVERSE)
	lamp(
		"UpperStop",
		Vector3.new(0.06, 0.5, 0.5),
		CFrame.new(s * 3.9, 10.4, 12.07) * CYL_Z,
		TAIL_RED,
		{
			shape = CYL,
		}
	)
end
for i = -2, 2 do
	lamp("HeaderClearance", Vector3.new(0.35, 0.2, 0.06), CFrame.new(i, 10.75, -9.84), AMBER)
end
for _, x in { -0.6, 0, 0.6 } do
	lamp("RearClearance", Vector3.new(0.3, 0.18, 0.06), CFrame.new(x, 10.8, 12.05), TAIL_RED)
end

---------------------------------------------------------------------------------------------------
-- Front details
---------------------------------------------------------------------------------------------------
part("GrilleSurround", Vector3.new(4.4, 1.5, 0.06), CFrame.new(0, 4.4, -11.93), CHROME, M.Metal, {
	reflectance = CHROME_REFLECT,
})
part("GrilleBacking", Vector3.new(4.1, 1.2, 0.06), CFrame.new(0, 4.4, -11.99), GRILLE_BLACK)
for i = 0, 3 do
	part(
		"GrilleSlat",
		Vector3.new(4.0, 0.08, 0.06),
		CFrame.new(0, 3.95 + i * 0.3, -12.05),
		CHROME,
		M.Metal,
		{ reflectance = CHROME_REFLECT }
	)
end
part(
	"FrontBumper",
	Vector3.new(9.4, 0.7, 0.5),
	CFrame.new(0, 2.3, -12.2),
	CHROME,
	M.Metal,
	{ reflectance = 0.2 }
)
part("PlateFront", Vector3.new(1.2, 0.6, 0.05), CFrame.new(0, 2.35, -12.48), PLATE)
for _, s in SIDES do
	wedge(
		"BumperEnd",
		Vector3.new(0.7, 0.3, 0.5),
		CFrame.new(s * 4.85, 2.3, -12.2) * (s < 0 and CORNER_FL or CORNER_FR),
		CHROME,
		M.Metal,
		{ reflectance = 0.2 }
	)
	part(
		"Wiper",
		Vector3.new(2.6, 0.06, 0.06),
		CFrame.new(s * 2.0, 6.35, -10.06) * A(math.rad(8.1), 0, math.rad(-s * 10)),
		BLACK
	)
	part("MirrorArm", Vector3.new(1.2, 0.08, 0.08), CFrame.new(s * 5.1, 9.4, -9.6), BLACK, M.Metal)
	part("MirrorArm", Vector3.new(1.2, 0.08, 0.08), CFrame.new(s * 5.1, 8.2, -9.6), BLACK, M.Metal)
	part("MirrorHead", Vector3.new(0.3, 1.6, 0.7), CFrame.new(s * 5.65, 8.8, -9.6), BLACK)
	part(
		"MirrorGlass",
		Vector3.new(0.25, 1.4, 0.04),
		CFrame.new(s * 5.65, 8.8, -9.23),
		GLASS,
		M.Glass,
		{ reflectance = 0.4 }
	)
end

---------------------------------------------------------------------------------------------------
-- Wheels and axles
---------------------------------------------------------------------------------------------------
local function lugs(xc, len, z, radius, count)
	for k = 0, count - 1 do
		local a = k * 2 * math.pi / count
		cyl(
			"LugNut",
			Vector3.new(len, 0.14, 0.14),
			CFrame.new(xc, WHEEL_Y + radius * math.cos(a), z + radius * math.sin(a)),
			CHROME,
			M.Metal,
			{ reflectance = CHROME_REFLECT }
		)
	end
end

for _, s in SIDES do
	-- Front: single wheel, center x 3.85, outer rim face x 4.34.
	local fx = s * 3.85
	cyl("Tire", Vector3.new(0.9, 3.3, 3.3), CFrame.new(fx, WHEEL_Y, FRONT_AXLE), TIRE)
	cyl("TireShoulder", Vector3.new(0.94, 2.6, 2.6), CFrame.new(fx, WHEEL_Y, FRONT_AXLE), SHOULDER)
	cyl(
		"Rim",
		Vector3.new(0.98, 1.9, 1.9),
		CFrame.new(fx, WHEEL_Y, FRONT_AXLE),
		RIM_WHITE,
		M.Metal,
		{
			reflectance = 0.05,
		}
	)
	cyl(
		"HubCap",
		Vector3.new(0.2, 0.8, 0.8),
		CFrame.new(s * 4.4, WHEEL_Y, FRONT_AXLE),
		CHROME,
		M.Metal,
		{ reflectance = CHROME_REFLECT }
	)
	lugs(s * 4.37, 0.12, FRONT_AXLE, 0.6, 6)

	-- Rear duals: inner x 3.00, outer x 3.95 (outer rim face 4.44).
	cyl("TireInner", Vector3.new(0.9, 3.3, 3.3), CFrame.new(s * 3.0, WHEEL_Y, REAR_AXLE), TIRE)
	cyl(
		"RimInner",
		Vector3.new(0.94, 1.9, 1.9),
		CFrame.new(s * 3.0, WHEEL_Y, REAR_AXLE),
		RIM_WHITE,
		M.Metal
	)
	cyl("TireOuter", Vector3.new(0.9, 3.3, 3.3), CFrame.new(s * 3.95, WHEEL_Y, REAR_AXLE), TIRE)
	cyl(
		"TireShoulder",
		Vector3.new(0.94, 2.6, 2.6),
		CFrame.new(s * 3.95, WHEEL_Y, REAR_AXLE),
		SHOULDER
	)
	cyl(
		"RimOuter",
		Vector3.new(0.98, 1.9, 1.9),
		CFrame.new(s * 3.95, WHEEL_Y, REAR_AXLE),
		RIM_WHITE,
		M.Metal,
		{
			reflectance = 0.05,
		}
	)
	cyl(
		"RearHub",
		Vector3.new(0.16, 1.0, 1.0),
		CFrame.new(s * 4.52, WHEEL_Y, REAR_AXLE),
		CHROME,
		M.Metal,
		{ reflectance = CHROME_REFLECT }
	)
	lugs(s * 4.47, 0.12, REAR_AXLE, 0.68, 4)
	part("MudFlap", Vector3.new(1.6, 1.2, 0.06), CFrame.new(s * 3.5, 1.4, 6.7), RUBBER)
end
part(
	"FrontAxle",
	Vector3.new(6.8, 0.35, 0.35),
	CFrame.new(0, WHEEL_Y, FRONT_AXLE),
	CHASSIS,
	M.Metal
)
cyl("RearAxle", Vector3.new(6.4, 0.5, 0.5), CFrame.new(0, WHEEL_Y, REAR_AXLE), CHASSIS, M.Metal)
ball("Differential", 1.1, Vector3.new(0, WHEEL_Y, REAR_AXLE), CHASSIS, M.Metal)

---------------------------------------------------------------------------------------------------
-- Serving window counter and awning (+X)
---------------------------------------------------------------------------------------------------
part(
	"Counter",
	Vector3.new(0.9, 0.12, 6.4),
	CFrame.new(4.95, 5.95, 0.2),
	STAINLESS,
	M.Metal,
	{ reflectance = 0.1 }
)
for _, z in { -2.2, 2.6 } do
	wedge(
		"CounterBracket",
		Vector3.new(0.12, 0.6, 0.8),
		CFrame.new(5.0, 5.59, z) * SIDE_R * A(0, 0, math.pi),
		STAINLESS,
		M.Metal
	)
end
part("NapkinBox", Vector3.new(0.4, 0.5, 0.3), CFrame.new(5.1, 6.26, -1.8), CHROME, M.Metal, {
	reflectance = CHROME_REFLECT,
})
for i = 0, 7 do
	local z = -2.6 + i * 0.8
	local color = i % 2 == 0 and PINK or AWNING_WHITE
	part(
		"AwningStripe",
		Vector3.new(1.8, 0.08, 0.8),
		CFrame.new(5.4, 9.6, z) * A(0, 0, math.rad(-26.6)),
		color
	)
	ball(
		"Scallop",
		0.4,
		Vector3.new(6.22, 8.82, z),
		i % 2 == 0 and AWNING_WHITE or PINK,
		M.SmoothPlastic
	)
end
part("AwningCap", Vector3.new(0.25, 0.25, 6.4), CFrame.new(4.72, 10.0, 0.2), PINK)
part("Valance", Vector3.new(0.06, 0.35, 6.4), CFrame.new(6.22, 9.02, 0.2), PINK)
for _, z in { -3.03, 3.43 } do
	wedge("AwningEnd", Vector3.new(0.06, 0.8, 1.6), CFrame.new(5.4, 9.6, z) * SIDE_R, AWNING_WHITE)
end
for _, z in { -2.6, 3.0 } do
	part(
		"AwningArm",
		Vector3.new(1.7, 0.08, 0.08),
		CFrame.new(5.4, 8.8, z) * A(0, 0, math.rad(26)),
		CHROME,
		M.Metal,
		{ reflectance = CHROME_REFLECT }
	)
end

---------------------------------------------------------------------------------------------------
-- Menu boards
---------------------------------------------------------------------------------------------------
local tileIndex = 0
local function menu(s, zc, len, cols, boardColor)
	local x = s * 4.63
	pastel("MenuBorder", Vector3.new(0.05, 3.3, len), CFrame.new(x, 7.9, zc), BLUE)
	pastel(
		"MenuBoard",
		Vector3.new(0.04, 3.0, len - 0.3),
		CFrame.new(s * 4.66, 7.9, zc),
		boardColor
	)
	local spacing = (len - 0.3) / cols
	for c = 0, cols - 1 do
		for r = -1, 1 do
			tileIndex += 1
			part(
				"MenuTile",
				Vector3.new(0.04, 0.75, spacing - 0.25),
				CFrame.new(s * 4.69, 7.9 + r * 0.95, zc + (c - (cols - 1) / 2) * spacing),
				TILE_COLORS[(tileIndex - 1) % #TILE_COLORS + 1]
			)
		end
	end
end
menu(1, -4.05, 2.3, 2, MENU_YELLOW)
menu(1, 7.5, 7.4, 4, MENU_MINT)
menu(-1, 3.0, 9.0, 5, MENU_PINK)

---------------------------------------------------------------------------------------------------
-- Roof: cone, chime horn, condenser
---------------------------------------------------------------------------------------------------
local CONE_Z = -5.5
cyl("ConePedestal", Vector3.new(0.4, 1.2, 1.2), CFrame.new(0, 11.6, CONE_Z) * CYL_Y, BODY)
for i = 0, 6 do
	local d = 0.5 + i * 0.3
	cyl(
		"ConeSection",
		Vector3.new(0.62, d, d),
		CFrame.new(0, 12.11 + i * 0.6, CONE_Z) * CYL_Y,
		i % 2 == 0 and WAFFLE or WAFFLE_DARK,
		M.Sand
	)
end
cyl("ConeRim", Vector3.new(0.3, 2.6, 2.6), CFrame.new(0, 16.15, CONE_Z) * CYL_Y, CONE_RIM, M.Sand)
ball("Scoop", 2.9, Vector3.new(0, 17.2, CONE_Z), SCOOP)
ball("SwirlLow", 2.3, Vector3.new(0, 18.2, CONE_Z), CREAM)
ball("SwirlMid", 1.5, Vector3.new(0, 18.95, CONE_Z), CREAM)
ball("SwirlTip", 0.8, Vector3.new(0, 19.5, CONE_Z), CREAM)
ball(
	"Cherry",
	0.6,
	Vector3.new(0.3, 19.85, CONE_Z + 0.1),
	CHERRY,
	M.SmoothPlastic,
	{ reflectance = 0.15 }
)

part("HornMount", Vector3.new(0.6, 0.5, 0.6), CFrame.new(2.6, 11.65, -8.0), GREY, M.Metal)
cyl("HornBell", Vector3.new(1.2, 0.9, 0.9), CFrame.new(2.6, 12.1, -8.4) * CYL_Z, CHROME, M.Metal, {
	reflectance = CHROME_REFLECT,
})
cyl("HornThroat", Vector3.new(0.06, 0.6, 0.6), CFrame.new(2.6, 12.1, -9.02) * CYL_Z, BLACK)
part("Condenser", Vector3.new(3.0, 1.0, 2.6), CFrame.new(0, 11.9, 8.0), LIGHT_GREY, M.Metal)

---------------------------------------------------------------------------------------------------
-- Interior
---------------------------------------------------------------------------------------------------
part("Floor", Vector3.new(8.8, 0.2, 21.2), CFrame.new(0, 3.5, 0.9), FLOOR, M.Rubber)
for _, s in SIDES do
	part(
		"WheelHump",
		Vector3.new(1.1, 0.6, 2.4),
		CFrame.new(s * 3.85, 3.9, FRONT_AXLE),
		FLOOR,
		M.Rubber
	)
end
part("Dashboard", Vector3.new(8.6, 1.2, 0.75), CFrame.new(0, 6.0, -9.475), DASH)
part("DashPad", Vector3.new(8.6, 0.1, 0.8), CFrame.new(0, 6.65, -9.45), BLACK)
part("Gauges", Vector3.new(1.4, 0.6, 0.06), CFrame.new(-2.4, 6.3, -9.07), BLACK)
-- Steering column from the dash (-2.4, 6.2, -9.0) to the wheel hub (-2.4, 6.9, -7.7).
cyl(
	"SteeringColumn",
	Vector3.new(1.48, 0.18, 0.18),
	CFrame.new(-2.4, 6.55, -8.35) * CYL_Z * A(0, 0, math.rad(-28)),
	DASH
)
local W = CFrame.new(-2.4, 6.9, -7.7) * A(math.rad(35), 0, 0)
for k = 0, 7 do
	local a = math.rad(k * 45)
	part(
		"WheelRim",
		Vector3.new(0.12, 0.12, 0.6),
		W * CFrame.new(0.75 * math.cos(a), 0, 0.75 * math.sin(a)) * A(0, -a, 0),
		BLACK
	)
end
for _, deg in { 0, 90, 180 } do
	local a = math.rad(deg)
	part(
		"WheelSpoke",
		Vector3.new(0.7, 0.08, 0.12),
		W * CFrame.new(0.35 * math.cos(a), 0, 0.35 * math.sin(a)) * A(0, -a, 0),
		BLACK
	)
end
cyl("WheelHub", Vector3.new(0.15, 0.4, 0.4), W * CYL_Y, DASH)
for _, s in SIDES do
	part(
		"SeatCushion",
		Vector3.new(1.8, 0.4, 1.8),
		CFrame.new(s * 2.4, 4.8, -6.2),
		VINYL,
		M.Leather
	)
	part("SeatBack", Vector3.new(1.8, 2.4, 0.35), CFrame.new(s * 2.4, 6.2, -5.2), VINYL, M.Leather)
	part("SeatPedestal", Vector3.new(0.8, 1.0, 0.8), CFrame.new(s * 2.4, 4.1, -6.2), DASH)
	part("Bulkhead", Vector3.new(3.2, 7.4, 0.15), CFrame.new(s * 2.9, 7.3, -4.6), BODY)
end
part(
	"Freezer",
	Vector3.new(2.4, 2.4, 5.0),
	CFrame.new(2.9, 4.8, 0.2),
	STAINLESS,
	M.Metal,
	{ reflectance = 0.1 }
)
for _, z in { -1.0, 1.4 } do
	part(
		"FreezerLid",
		Vector3.new(2.2, 0.06, 2.3),
		CFrame.new(2.9, 6.03, z),
		GLASS,
		M.Glass,
		{ transparency = 0.4, reflectance = 0.1 }
	)
end
part("Shelf", Vector3.new(0.8, 0.12, 6.0), CFrame.new(-4.0, 8.0, 0.2), STAINLESS, M.Metal)

---------------------------------------------------------------------------------------------------
-- Details: stop arm, handles, chassis, rear
---------------------------------------------------------------------------------------------------
cyl("StopArmBorder", Vector3.new(0.06, 1.75, 1.75), CFrame.new(-4.7, 7.6, -3.4), AWNING_WHITE)
cyl("StopArm", Vector3.new(0.08, 1.6, 1.6), CFrame.new(-4.75, 7.6, -3.4), STOP_RED)
part("StopArmHinge", Vector3.new(0.15, 0.3, 0.3), CFrame.new(-4.68, 7.6, -4.4), BLACK)
for _, s in SIDES do
	cyl(
		"GrabHandle",
		Vector3.new(2.0, 0.12, 0.12),
		CFrame.new(s * 4.7, 6.8, -5.45) * CYL_Y,
		CHROME,
		M.Metal,
		{ reflectance = CHROME_REFLECT }
	)
	part(
		"DoorHandle",
		Vector3.new(0.06, 0.15, 0.5),
		CFrame.new(s * 4.65, 6.6, -6.4),
		CHROME,
		M.Metal,
		{
			reflectance = CHROME_REFLECT,
		}
	)
	part(
		"EntryStep",
		Vector3.new(0.8, 0.15, 0.8),
		CFrame.new(s * 4.6, 2.3, -5.9),
		PLATE_STEEL,
		M.DiamondPlate
	)
	part("FrameRail", Vector3.new(0.4, 0.6, 21.0), CFrame.new(s * 1.8, 2.1, 0.5), CHASSIS, M.Metal)
end
cyl("FuelCap", Vector3.new(0.06, 0.4, 0.4), CFrame.new(-4.64, 3.4, -1.5), CHASSIS, M.Metal)
cyl("FuelTank", Vector3.new(3.0, 1.2, 1.2), CFrame.new(-3.0, 1.75, -1.8) * CYL_Z, CHASSIS, M.Metal)
cyl("ExhaustTip", Vector3.new(1.0, 0.3, 0.3), CFrame.new(2.6, 1.6, 12.2) * CYL_Z, CHROME, M.Metal, {
	reflectance = CHROME_REFLECT,
})
part("RearBumper", Vector3.new(9.4, 0.6, 0.8), CFrame.new(0, 2.3, 12.3), RUBBER)
part(
	"RearStep",
	Vector3.new(3.0, 0.06, 0.8),
	CFrame.new(0, 2.63, 12.3),
	PLATE_STEEL,
	M.DiamondPlate
)
part("PlateRear", Vector3.new(1.2, 0.6, 0.05), CFrame.new(0, 3.4, 12.1), PLATE)
part("CautionSign", Vector3.new(5.0, 1.0, 0.05), CFrame.new(0, 10.1, 12.08), CAUTION)
part("RearDoorHandle", Vector3.new(0.5, 0.15, 0.06), CFrame.new(0.6, 6.5, 12.1), CHROME, M.Metal, {
	reflectance = CHROME_REFLECT,
})
for _, x in { -3.0, 0, 3.0 } do
	part("RearDoorSeam", Vector3.new(0.06, 6.95, 0.04), CFrame.new(x, 6.125, 12.07), GAP)
end

return {
	name = "Ice Cream Truck",
	speed = 65,
	turnRate = 2,
	footprint = Vector2.new(9.2, 24.4),
	collision = {
		-- Box body and cab: y 1.4..11.4, z -9.8..11.8.
		{ size = Vector3.new(9.2, 10.0, 21.6), offset = CFrame.new(0, 6.4, 1.0) },
		-- Nose: y 1.4..6.0, z -12.4..-9.8.
		{ size = Vector3.new(9.2, 4.6, 2.6), offset = CFrame.new(0, 3.7, -11.1) },
	},
	seats = {
		CFrame.new(-2.4, 4.5, -6.2), -- driver (LHD)
		CFrame.new(2.4, 4.5, -6.2), -- passenger / server
	},
	pieces = pieces,
}
