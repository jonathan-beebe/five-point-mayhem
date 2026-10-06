-- Stryker APC: M1126 8x8 infantry carrier in CARC green with bolted applique armor and an M151 RWS.
-- Scale: 4 studs = 1 m. Axles at z -9.2, -4.4, 3.6, 8.4; track 9.4; tire diameter 4.6.

local rgb = Color3.fromRGB
local M = Enum.Material
local A = CFrame.Angles
local V = Vector3.new
local C = CFrame.new
local CYL = Enum.PartType.Cylinder
local WEDGE = "WedgePart"

-- Cylinder axis is local X: these lay it along Z or stand it on Y.
local CYLINDER_Z = A(0, math.rad(90), 0)
local CYLINDER_Y = A(0, 0, math.rad(90))
-- WedgePart default: full bottom and back (+Z) faces, slope rising toward +Z.
local FLIP_Z = A(0, 0, math.pi) -- right angle at (ymax, zmax)
local SIDE_L = A(0, math.pi / 2, 0) -- size.X runs along world Z, slope rises toward +X
local SIDE_R = A(0, -math.pi / 2, 0) -- size.X runs along world Z, slope rises toward -X

-- Glacis: (y 6.6, z -13.9) up to (y 9.0, z -8.5).
local GLACIS = math.atan(2.4 / 5.4)
local function onGlacis(x: number, t: number, h: number): CFrame
	local y = 6.6 + 2.4 * t
	local z = -13.9 + 5.4 * t
	local d = h / 2 + 0.02
	return C(x, y + d * math.cos(GLACIS), z - d * math.sin(GLACIS)) * A(-GLACIS, 0, 0)
end

-- Upper side slope: surface (+-5.45, 6.6) up to (+-4.2, 9.0).
local SLOPE_L = A(0, 0, math.rad(-27.5))
local SLOPE_R = A(0, 0, math.rad(27.5))
local function onSlope(side: number, s: number, d: number, z: number): CFrame
	local x = side * (4.825 - 0.462 * s + 0.887 * d)
	local y = 7.8 + 0.887 * s + 0.462 * d
	return C(x, y, z) * (side < 0 and SLOPE_L or SLOPE_R)
end

-- Palette: { color, material, reflectance, transparency }
local HULL_GREEN = { rgb(74, 83, 54), M.SmoothPlastic }
local HULL_SHADE = { rgb(63, 71, 46), M.SmoothPlastic }
local APPLIQUE = { rgb(80, 89, 59), M.SmoothPlastic }
local PANEL_GAP = { rgb(36, 40, 28), M.SmoothPlastic }
local TIRE = { rgb(28, 28, 30), M.Fabric }
local SIDEWALL = { rgb(40, 40, 42), M.SmoothPlastic }
local RIM = { rgb(68, 76, 50), M.Metal }
local HUB = { rgb(55, 62, 42), M.Metal }
local LUG = { rgb(95, 95, 90), M.Metal }
local GUNMETAL = { rgb(45, 47, 50), M.Metal }
local INTAKE_MESH = { rgb(30, 33, 25), M.Metal }
local SIGHT_GLASS = { rgb(20, 30, 40), M.Glass, 0.25, 0.2 }
local PERISCOPE_GLASS = { rgb(25, 40, 45), M.Glass, 0.2, 0.3 }
local HATCH_HOLE = { rgb(10, 10, 10), M.SmoothPlastic }
local HEADLIGHT = { rgb(255, 241, 214), M.Neon }
local TAIL = { rgb(220, 30, 25), M.Neon }
local AMBER = { rgb(255, 150, 30), M.Neon }
local LAMP_HOUSING = { rgb(35, 37, 30), M.Metal }
local TOOL_WOOD = { rgb(110, 85, 55), M.Wood }
local TOOL_STEEL = { rgb(60, 60, 60), M.Metal }
local JERRY = { rgb(70, 78, 50), M.Metal }
local ANTENNA = { rgb(25, 25, 25), M.SmoothPlastic }
local DECK_PLATE = { rgb(58, 66, 42), M.DiamondPlate }
local TREAD = { rgb(24, 24, 26), M.Fabric }

local pieces = {}

local function add(
	name: string,
	size: Vector3,
	offset: CFrame,
	token,
	class: string?,
	shape: Enum.PartType?
)
	table.insert(pieces, {
		name = name,
		class = class,
		shape = shape,
		size = size,
		offset = offset,
		color = token[1],
		material = token[2],
		reflectance = token[3],
		transparency = token[4],
	})
end

local function wedge(name: string, size: Vector3, offset: CFrame, token)
	add(name, size, offset, token, WEDGE)
end

local function cyl(name: string, size: Vector3, offset: CFrame, token)
	add(name, size, offset, token, nil, CYL)
end

-- Hull core.
add("LowerHull", V(7.8, 2.7, 24.6), C(0, 3.45, 1.3), HULL_SHADE)
wedge("LowerNose", V(7.8, 2.7, 2.9), C(0, 3.45, -12.45) * FLIP_Z, HULL_GREEN)
add("Shelf", V(10.9, 1.8, 27.5), C(0, 5.7, -0.15), HULL_GREEN)
wedge("Glacis", V(8.4, 2.4, 5.4), C(0, 7.8, -11.2), HULL_GREEN)
wedge("CheekL", V(5.4, 1.2, 1.25), C(-4.825, 7.2, -11.2) * SIDE_L, HULL_GREEN)
wedge("CheekR", V(5.4, 1.2, 1.25), C(4.825, 7.2, -11.2) * SIDE_R, HULL_GREEN)
add("UpperHull", V(8.4, 2.4, 22.1), C(0, 7.8, 2.55), HULL_GREEN)
wedge("UpperSideL", V(22.1, 2.4, 1.25), C(-4.825, 7.8, 2.55) * SIDE_L, HULL_GREEN)
wedge("UpperSideR", V(22.1, 2.4, 1.25), C(4.825, 7.8, 2.55) * SIDE_R, HULL_GREEN)
for _, s in { -1, 1 } do
	add("WellLinerF", V(1.4, 0.06, 10.6), C(s * 4.7, 4.77, -6.8), PANEL_GAP)
	add("WellLinerR", V(1.4, 0.06, 10.6), C(s * 4.7, 4.77, 6.0), PANEL_GAP)
	add("ShelfSeam", V(0.06, 0.1, 27.3), C(s * 5.48, 6.55, -0.15), PANEL_GAP)
end
add("NoseTrim", V(10.9, 0.12, 0.06), C(0, 6.5, -13.95), PANEL_GAP)

-- Applique armor tiles: side band and upper slopes.
for _, s in { -1, 1 } do
	for i = 0, 9 do
		add("BandTile", V(0.06, 1.55, 2.56), C(s * 5.48, 5.7, -12.06 + 2.68 * i), APPLIQUE)
	end
	for i = 0, 7 do
		if not (s > 0 and i == 0) then
			add("SlopeTile", V(0.06, 2.3, 2.6), onSlope(s, 0, 0.05, -6.945 + 2.71 * i), APPLIQUE)
		end
	end
end

-- Wheels: four axles in a 2-gap-2 grouping.
local AXLES = { -9.2, -4.4, 3.6, 8.4 }
for _, s in { -1, 1 } do
	for _, zc in AXLES do
		cyl("Tire", V(1.3, 4.6, 4.6), C(s * 4.7, 2.3, zc), TIRE)
		cyl("Sidewall", V(0.04, 4.1, 4.1), C(s * 5.37, 2.3, zc), SIDEWALL)
		cyl("Rim", V(0.06, 2.9, 2.9), C(s * 5.39, 2.3, zc), RIM)
		cyl("RimRing", V(0.04, 2.3, 2.3), C(s * 5.44, 2.3, zc), HUB)
		cyl("Hub", V(0.3, 1.0, 1.0), C(s * 5.57, 2.3, zc), HUB)
		cyl("HubCap", V(0.08, 0.5, 0.5), C(s * 5.76, 2.3, zc), GUNMETAL)
		-- Tread bars, offset half a step so none sits at the contact patch.
		for k = 0, 7 do
			local a = math.rad(22.5 + 45 * k)
			add(
				"TreadBar",
				V(1.34, 0.12, 0.55),
				C(s * 4.7, 2.3, zc) * A(a, 0, 0) * C(0, 2.28, 0),
				TREAD
			)
		end
		for k = 0, 5 do
			local a = math.rad(60 * k)
			cyl(
				"Lug",
				V(0.1, 0.2, 0.2),
				C(s * 5.47, 2.3 + 0.75 * math.cos(a), zc + 0.75 * math.sin(a)),
				LUG
			)
		end
	end
end

-- Glacis: engine intake and pioneer tools.
add("IntakeFrame", V(3.4, 0.06, 2.4), onGlacis(2.1, 0.55, 0.06), INTAKE_MESH)
for _, dz in { -0.9, -0.54, -0.18, 0.18, 0.54, 0.9 } do
	add("IntakeSlat", V(3.2, 0.08, 0.14), onGlacis(2.1, 0.55, 0.16) * C(0, 0, dz), GUNMETAL)
end
cyl("ShovelHandle", V(2.4, 0.12, 0.12), onGlacis(-2.2, 0.3, 0.12), TOOL_WOOD)
add("ShovelBlade", V(0.6, 0.05, 0.7), onGlacis(-3.7, 0.3, 0.05), TOOL_STEEL)
cyl("PickHandle", V(2.6, 0.14, 0.14), onGlacis(-2.3, 0.14, 0.14), TOOL_WOOD)
add("PickHead", V(0.15, 0.15, 1.2), onGlacis(-3.7, 0.14, 0.15), TOOL_STEEL)

-- Driver hatch, front-left.
add("HatchHole", V(2.4, 0.04, 1.9), C(-2.6, 9.03, -6.6), HATCH_HOLE)
add("CoamingF", V(2.9, 0.25, 0.25), C(-2.6, 9.125, -7.675), HULL_GREEN)
add("CoamingB", V(2.9, 0.25, 0.25), C(-2.6, 9.125, -5.525), HULL_GREEN)
add("CoamingL", V(0.25, 0.25, 1.9), C(-3.925, 9.125, -6.6), HULL_GREEN)
add("CoamingR", V(0.25, 0.25, 1.9), C(-1.275, 9.125, -6.6), HULL_GREEN)
add("HatchCover", V(2.2, 1.6, 0.15), C(-2.6, 9.95, -5.3), HULL_GREEN)
for _, x in { -3.4, -2.6, -1.8 } do
	add("Periscope", V(0.5, 0.3, 0.35), C(x, 9.15, -8.0), GUNMETAL)
	add("PeriscopeGlass", V(0.4, 0.18, 0.03), C(x, 9.15, -8.2), PERISCOPE_GLASS)
end

-- Commander hatch.
cyl("CmdRing", V(0.3, 2.8, 2.8), C(-2.2, 9.15, -2.0) * CYLINDER_Y, HULL_GREEN)
cyl("CmdHole", V(0.04, 2.4, 2.4), C(-2.2, 9.32, -2.0) * CYLINDER_Y, HATCH_HOLE)
cyl("CmdCover", V(0.15, 2.3, 2.3), C(-2.2, 10.35, -0.45) * CYLINDER_Z, HULL_GREEN)
for _, deg in { -90, -135, 180, 135 } do
	local a = math.rad(deg)
	local x = -2.2 + 1.6 * math.sin(a)
	local z = -2.0 + 1.6 * math.cos(a)
	add("VisionBlock", V(0.4, 0.3, 0.3), C(x, 9.15, z) * A(0, a, 0), GUNMETAL)
end

-- M151 remote weapon station with M2 .50 cal.
cyl("RwsBase", V(0.4, 1.8, 1.8), C(1.6, 9.2, -2.6) * CYLINDER_Y, HULL_GREEN)
add("RwsBody", V(1.3, 0.9, 1.3), C(1.6, 9.85, -2.5), HULL_GREEN)
add("Cradle", V(1.0, 0.5, 1.8), C(1.6, 10.55, -2.6), HULL_GREEN)
add("Receiver", V(0.45, 0.5, 1.6), C(1.6, 11.0, -2.6), GUNMETAL)
add("FeedCover", V(0.4, 0.08, 0.9), C(1.6, 11.29, -2.4), GUNMETAL)
add("Grips", V(0.4, 0.35, 0.2), C(1.6, 10.95, -1.7), GUNMETAL)
cyl("BarrelJacket", V(1.0, 0.34, 0.34), C(1.6, 11.0, -3.9) * CYLINDER_Z, GUNMETAL)
cyl("Barrel", V(3.6, 0.17, 0.17), C(1.6, 11.0, -6.2) * CYLINDER_Z, GUNMETAL)
cyl("FlashHider", V(0.35, 0.24, 0.24), C(1.6, 11.0, -8.15) * CYLINDER_Z, GUNMETAL)
add("SightBox", V(0.55, 0.7, 0.9), C(0.75, 10.8, -2.8), HULL_GREEN)
add("SightHood", V(0.6, 0.06, 1.0), C(0.75, 11.18, -2.85), HULL_SHADE)
add("SightGlass", V(0.4, 0.4, 0.03), C(0.75, 10.8, -3.27), SIGHT_GLASS)
add("AmmoCan", V(0.55, 0.65, 0.9), C(2.45, 10.6, -2.4), HULL_SHADE)

-- Roof troop hatches.
for _, s in { -1, 1 } do
	add("TroopHatch", V(3.4, 0.12, 5.5), C(s * 2.0, 9.06, 6.5), DECK_PLATE)
	cyl("TroopHinge", V(5.3, 0.14, 0.14), C(s * 0.35, 9.12, 6.5) * CYLINDER_Z, GUNMETAL)
end

-- Smoke grenade launchers at the front roof corners.
for _, s in { -1, 1 } do
	add("SmokeBase", V(0.8, 0.5, 0.8), C(s * 4.55, 8.6, -7.6), HULL_SHADE)
	local yaw = math.rad(-25 * s)
	for _, x in { 4.35, 4.75 } do
		for _, y in { 8.95, 9.3 } do
			cyl(
				"SmokeTube",
				V(0.8, 0.3, 0.3),
				C(s * x, y, -8.0) * A(0, yaw, 0) * A(math.rad(20), 0, 0) * CYLINDER_Z,
				GUNMETAL
			)
		end
	end
end

-- Engine exhaust grille, right upper slope.
add("ExhaustFrame", V(0.06, 2.0, 2.4), onSlope(1, 0, 0.05, -6.945), INTAKE_MESH)
for _, sl in { -0.6, -0.2, 0.2, 0.6 } do
	add("ExhaustLouver", V(0.1, 0.12, 2.2), onSlope(1, sl, 0.12, -6.945), GUNMETAL)
end

-- Lights.
for _, s in { -1, 1 } do
	add("HeadHousing", V(1.0, 0.8, 0.25), C(s * 4.3, 5.7, -14.0), LAMP_HOUSING)
	cyl("Headlamp", V(0.06, 0.55, 0.55), C(s * 4.45, 5.75, -14.16) * CYLINDER_Z, HEADLIGHT)
	add("Indicator", V(0.25, 0.2, 0.05), C(s * 3.95, 5.45, -14.15), AMBER)
	add("GuardIn", V(0.08, 1.0, 0.08), C(s * 4.1, 5.7, -14.35), GUNMETAL)
	add("GuardOut", V(0.08, 1.0, 0.08), C(s * 4.8, 5.7, -14.35), GUNMETAL)
	add("GuardTop", V(1.0, 0.08, 0.08), C(s * 4.45, 6.2, -14.35), GUNMETAL)
	add("TailHousing", V(0.8, 0.8, 0.2), C(s * 4.4, 6.2, 13.72), LAMP_HOUSING)
	add("TailRed", V(0.3, 0.3, 0.05), C(s * 4.25, 6.3, 13.85), TAIL)
	add("TailAmber", V(0.25, 0.25, 0.05), C(s * 4.62, 6.3, 13.85), AMBER)
end

-- Rear ramp and misc.
add("Ramp", V(6.4, 6.0, 0.2), C(0, 5.75, 13.73), HULL_GREEN)
add("RampDoor", V(2.0, 4.2, 0.06), C(-1.2, 5.6, 13.86), HULL_SHADE)
add("DoorHandle", V(0.5, 0.12, 0.12), C(-0.4, 5.6, 13.95), GUNMETAL)
cyl("RampHinge", V(6.0, 0.35, 0.35), C(0, 2.9, 13.72), GUNMETAL)
add("RearStep", V(6.6, 0.25, 0.6), C(0, 2.5, 13.75), HULL_SHADE)
for _, s in { -1, 1 } do
	add("RearTowHook", V(0.3, 0.6, 0.4), C(s * 3.4, 3.6, 13.8), GUNMETAL)
	add("JerryCan", V(1.3, 1.8, 0.62), C(s * 4.4, 7.6, 13.93), JERRY)
	add("FrontTowHook", V(0.4, 0.5, 0.35), C(s * 2.4, 4.75, -14.05), GUNMETAL)
	cyl("AntennaBase", V(0.5, 0.5, 0.5), C(s * 3.7, 9.25, 12.6) * CYLINDER_Y, GUNMETAL)
	cyl("AntennaWhip", V(8.0, 0.08, 0.08), C(s * 3.7, 13.5, 12.6) * CYLINDER_Y, ANTENNA)
end

return {
	name = "Stryker APC",
	-- Real: 100 km/h, 0-48 km/h in 12 s, brakes 0.5 g, coasts 0.12 g (VehicleDefaults maps them).
	speed = 45,
	acceleration = 3.9,
	braking = 10.6,
	coasting = 4.1,
	turnRate = 1.8,
	footprint = Vector2.new(10.4, 27.0),
	collision = {
		{ size = V(10.9, 4.5, 27.6), offset = C(0, 4.35, 0) }, -- hull to shelf top: y 2.1..6.6
		{ size = V(9.6, 2.4, 14.2), offset = C(0, 7.8, 6.5) }, -- crew compartment: y 6.6..9.0
		{ size = V(8.4, 1.0, 4.4), offset = C(0, 7.1, -11.3) }, -- glacis base: y 6.6..7.6
	},
	seats = {
		C(-2.6, 7.1, -6.6), -- driver, front-left hatch
		C(-2.2, 7.1, -2.0), -- commander hatch
		C(-2.4, 9.65, 4.2), -- roof deck riders
		C(2.4, 9.65, 4.2),
		C(-2.4, 9.65, 9.4),
		C(2.4, 9.65, 9.4),
	},
	pieces = pieces,
}
