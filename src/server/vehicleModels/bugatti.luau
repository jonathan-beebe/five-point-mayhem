-- Bugatti Chiron: two-tone Atlantic blue and carbon W16 hypercar with horseshoe grille and C-line.

local rgb = Color3.fromRGB
local M = Enum.Material
local A = CFrame.Angles
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball
local WEDGE = "WedgePart"

-- Scale: 4.5 studs = 1 m (low car; seat top y 1.05 lets the R15 avatar fit under the roof).

-- Rotations. Cylinder axis is local X; WedgePart default has its right angle at (ymin, zmax).
local CYLINDER_Z = A(0, math.rad(90), 0)
local RISE_FRONT = A(0, math.pi, 0) -- high at the front, low at the rear
local FLIP_X = A(math.pi, 0, 0) -- right angle at (ymax, zmin); underside rises toward the rear

-- Palette: color, material, reflectance, transparency.
local BLUE = { c = rgb(22, 52, 120), m = M.SmoothPlastic, r = 0.12 }
local CARBON = { c = rgb(22, 24, 28), m = M.SmoothPlastic, r = 0.1 }
local GLOSS_BLACK = { c = rgb(14, 14, 18), m = M.SmoothPlastic, r = 0.15 }
local MATTE_BLACK = { c = rgb(16, 16, 18), m = M.Plastic }
local MESH_BLACK = { c = rgb(26, 26, 29), m = M.DiamondPlate }
local GAP_BLACK = { c = rgb(8, 8, 10), m = M.SmoothPlastic }
local ALLOY = { c = rgb(200, 204, 210), m = M.Metal, r = 0.3 }
local GLASS = { c = rgb(25, 35, 45), m = M.Glass, t = 0.4 }
local MIRROR = { c = rgb(150, 165, 180), m = M.Glass, r = 0.4 }
local HEADLIGHT = { c = rgb(255, 245, 225), m = M.Neon }
local HOUSING = { c = rgb(60, 62, 66), m = M.Metal }
local TAIL_RED = { c = rgb(255, 25, 20), m = M.Neon }
local REVERSE = { c = rgb(230, 230, 230), m = M.Neon }
local AMBER = { c = rgb(255, 150, 20), m = M.Neon }
local BADGE_RED = { c = rgb(200, 20, 30), m = M.SmoothPlastic }
local TIRE = { c = rgb(28, 28, 30), m = M.SmoothPlastic }
local RIM_SILVER = { c = rgb(182, 185, 190), m = M.Metal, r = 0.25 }
local RIM_DARK = { c = rgb(70, 72, 76), m = M.Metal }
local DISC = { c = rgb(95, 95, 100), m = M.Metal }
local CALIPER_BLUE = { c = rgb(30, 90, 190), m = M.SmoothPlastic }
local TITANIUM = { c = rgb(125, 118, 110), m = M.Metal }
local BORE_BLACK = { c = rgb(5, 5, 6), m = M.SmoothPlastic }
local LEATHER = { c = rgb(35, 45, 80), m = M.Fabric }
local LEATHER_DARK = { c = rgb(20, 20, 24), m = M.Fabric }

local FRONT_AXLE_Z = -5.7
local REAR_AXLE_Z = 6.5

local pieces = {}

local function add(p)
	table.insert(pieces, p)
end

local function part(
	name: string,
	size: Vector3,
	cf: CFrame,
	style,
	class: string?,
	shape: Enum.PartType?
)
	add({
		name = name,
		class = class,
		shape = shape,
		size = size,
		offset = cf,
		color = style.c,
		material = style.m,
		reflectance = style.r,
		transparency = style.t,
	})
end

local function v(x: number, y: number, z: number): Vector3
	return Vector3.new(x, y, z)
end

local function at(x: number, y: number, z: number): CFrame
	return CFrame.new(x, y, z)
end

-- A block from a to b. On side panels (default) `width` lies in the panel and `thick` runs along X;
-- with `flat`, `width` runs along X and `thick` is vertical.
local function beam(
	name: string,
	a: Vector3,
	b: Vector3,
	width: number,
	thick: number,
	style,
	flat: boolean?
)
	local d = b - a
	local yaw = math.atan2(-d.X, -d.Z)
	local pitch = math.asin(d.Y / d.Magnitude)
	local cf = CFrame.new((a + b) / 2) * A(0, yaw, 0) * A(pitch, 0, 0)
	if flat then
		part(name, v(width, thick, d.Magnitude), cf, style)
	else
		part(name, v(thick, width, d.Magnitude), cf, style)
	end
end

-- s = -1 is the left (driver) side, +1 the right. Rotations about Y and Z flip sign with s.
local SIDES = { -1, 1 }
local function sideName(name: string, s: number): string
	return name .. (if s < 0 then "L" else "R")
end

-- Body shell ---------------------------------------------------------------------------------

part("Underbody", v(5.8, 0.25, 19.6), at(0, 0.72, 0), MATTE_BLACK)
part("FrontCore", v(5.6, 1.6, 4.7), at(0, 1.45, -7.35), BLUE)
part("Hood", v(5.4, 1.1, 4.9), at(0, 2.8, -7.45), BLUE, WEDGE)
part("HoodSpine", v(0.12, 0.06, 5.0), at(0, 2.85, -7.45) * A(math.rad(-12.65), 0, 0), BLUE)
part("CabinFloor", v(5.6, 0.3, 5.9), at(0, 0.85, -2.05), MATTE_BLACK)
part("CabinCore", v(5.6, 3.45, 9.3), at(0, 2.375, 5.55), BLUE)
part("RearDeck", v(5.6, 0.1, 3.7), at(0, 4.15, 8.35), BLUE)
part("TailChamfer", v(9.0, 0.35, 0.5), at(0, 3.85, 9.95) * RISE_FRONT, BLUE, WEDGE)
part("RearFascia", v(7.9, 3.3, 0.1), at(0, 2.25, 10.17), CARBON)
part("Splitter", v(8.4, 0.08, 0.9), at(0, 0.49, -9.85), CARBON)

for _, s in SIDES do
	local function n(name: string): string
		return sideName(name, s)
	end
	-- Front fender and nose corner.
	part(n("FenderTop"), v(1.05, 0.52, 4.4), at(s * 3.78, 3.46, -5.7), BLUE)
	part(
		n("FenderChamfer"),
		v(4.4, 0.52, 0.22),
		at(s * 4.41, 3.46, -5.7) * A(0, -s * math.rad(90), 0),
		BLUE,
		WEDGE
	)
	part(n("FenderNoseInner"), v(0.9, 1.2, 2.4), at(s * 3.15, 2.6, -8.8), BLUE, WEDGE)
	part(n("FenderLowerInner"), v(0.9, 1.35, 2.1), at(s * 3.15, 1.3, -8.65), BLUE)
	part(n("FenderNoseOuter"), v(0.9, 1.2, 1.5), at(s * 4.05, 2.6, -8.35), BLUE, WEDGE)
	part(n("FenderLowerOuter"), v(0.9, 1.35, 1.5), at(s * 4.05, 1.3, -8.35), BLUE)
	part(
		n("NoseCorner"),
		v(1.6, 0.9, 0.9),
		at(s * 4.05, 1.8, -9.55) * A(0, 0, s * math.rad(-90)),
		BLUE,
		WEDGE
	)
	-- Arch rings: a semicircle of blocks over each wheel.
	for k = 0, 6 do
		local theta = math.rad(-90 + k * 30)
		part(
			n("FrontArch"),
			v(1.3, 0.45, 1.1),
			at(s * 3.88, 1.53, FRONT_AXLE_Z) * A(theta, 0, 0) * at(0, 1.975, 0),
			BLUE
		)
		part(
			n("RearArch"),
			v(1.5, 0.45, 1.15),
			at(s * 3.82, 1.6, REAR_AXLE_Z) * A(theta, 0, 0) * at(0, 2.045, 0),
			BLUE
		)
	end
	part(n("FrontArchLiner"), v(0.2, 2.3, 4.2), at(s * 3.0, 2.45, FRONT_AXLE_Z), MATTE_BLACK)
	part(n("RearArchLiner"), v(0.2, 2.3, 4.2), at(s * 2.85, 2.45, REAR_AXLE_Z), MATTE_BLACK)
	-- Doors, intake recess, rear quarter and haunch.
	part(n("Door"), v(1.55, 2.9, 3.9), at(s * 3.775, 2.2, -1.95), BLUE)
	part(n("IntakeRecess"), v(1.3, 2.9, 2.4), at(s * 3.65, 2.2, 1.2), MATTE_BLACK)
	part(n("RearQuarter"), v(1.58, 3.15, 1.85), at(s * 3.79, 2.33, 3.33), BLUE)
	part(n("HaunchTop"), v(1.25, 0.65, 4.6), at(s * 3.78, 3.83, REAR_AXLE_Z), BLUE)
	part(
		n("HaunchChamfer"),
		v(4.6, 0.65, 0.18),
		at(s * 4.49, 3.83, REAR_AXLE_Z) * A(0, -s * math.rad(90), 0),
		BLUE,
		WEDGE
	)
	part(n("RearCorner"), v(1.55, 3.15, 1.4), at(s * 3.78, 2.33, 9.45), BLUE)
	part(n("Sill"), v(0.22, 0.45, 8.2), at(s * 4.5, 0.85, 0.2), CARBON)
	part(n("DoorGapFront"), v(0.04, 2.6, 0.05), at(s * 4.56, 2.2, -3.9), GAP_BLACK)
	part(n("DoorGapRear"), v(0.04, 2.6, 0.05), at(s * 4.56, 2.2, 0.0), GAP_BLACK)
	part(n("DoorHandle"), v(0.04, 0.08, 0.5), at(s * 4.57, 3.2, -0.6), GAP_BLACK)
	part(n("SideMarker"), v(0.04, 0.12, 0.3), at(s * 4.52, 2.8, -8.4), AMBER)
end

-- C-line and side intakes ---------------------------------------------------------------------

local C_LINE = {
	v(-2.95, 5.1, -1.0),
	v(-3.0, 5.0, 0.8),
	v(-3.5, 4.6, 1.8),
	v(-4.2, 3.9, 2.4),
	v(-4.62, 3.0, 2.6),
	v(-4.62, 2.0, 2.4),
	v(-4.62, 1.35, 1.8),
	v(-4.62, 1.05, 0.8),
	v(-4.62, 1.0, -2.0),
	v(-4.58, 1.6, -4.1),
}
for _, s in SIDES do
	local flip = v(-s, 1, 1)
	for i = 1, #C_LINE - 1 do
		beam(sideName("CLine", s), C_LINE[i] * flip, C_LINE[i + 1] * flip, 0.32, 0.08, GLOSS_BLACK)
	end
	part(sideName("IntakeMesh", s), v(0.05, 2.4, 2.0), at(s * 4.33, 2.4, 1.25), MESH_BLACK)
	for _, y in { 1.6, 2.2, 2.8, 3.4 } do
		part(sideName("IntakeSlat", s), v(0.08, 0.06, 2.0), at(s * 4.37, y, 1.25), GAP_BLACK)
	end
end

-- Glasshouse, roof and engine cover -----------------------------------------------------------

local WINDSHIELD_ANGLE = math.rad(-31.7)
part("Windshield", v(5.3, 0.1, 3.55), at(0, 4.375, -3.5) * A(WINDSHIELD_ANGLE, 0, 0), GLASS)
part("Wiper", v(2.4, 0.05, 0.08), at(-0.6, 3.68, -4.75) * A(WINDSHIELD_ANGLE, 0, 0), GAP_BLACK)
part("Roof", v(5.4, 0.2, 2.9), at(0, 5.35, -0.55), CARBON)
part("RoofFin", v(0.14, 0.16, 2.9), at(0, 5.53, -0.55), CARBON)
part("EngineCover", v(5.6, 1.25, 5.6), at(0, 4.725, 3.7) * RISE_FRONT, CARBON, WEDGE)
beam("EngineFin", v(0, 5.53, 0.9), v(0, 4.18, 6.5), 0.14, 0.16, CARBON, true)
for i = 0, 5 do
	local z = 1.5 + i * 0.9
	local y = 5.35 - (z - 0.9) * 1.25 / 5.6 + 0.04
	part("Louver", v(4.8, 0.05, 0.22), at(0, y, z) * A(math.rad(12.6), 0, 0), GAP_BLACK)
end

for _, s in SIDES do
	local function n(name: string): string
		return sideName(name, s)
	end
	local lean = A(0, 0, s * math.rad(41))
	beam(n("APillar"), v(s * 2.75, 3.45, -5.0), v(s * 2.65, 5.3, -2.0), 0.28, 0.2, CARBON)
	part(n("SideWindow"), v(0.08, 2.05, 2.9), at(s * 3.425, 4.425, -0.55) * lean, GLASS)
	part(n("SideWindowFront"), v(0.08, 2.05, 3.0), at(s * 3.425, 4.425, -3.5) * lean, GLASS, WEDGE)
	part(
		n("QuarterPanel"),
		v(0.08, 2.05, 2.0),
		at(s * 3.425, 4.425, 1.9) * lean * RISE_FRONT,
		CARBON,
		WEDGE
	)
	beam(n("WindowFrame"), v(s * 2.75, 5.2, -2.0), v(s * 2.85, 5.15, 0.9), 0.15, 0.12, CARBON)
	-- Mirrors.
	part(n("MirrorHousing"), v(0.5, 0.42, 0.75), at(s * 4.85, 3.95, -3.3), CARBON)
	part(n("MirrorGlass"), v(0.4, 0.32, 0.04), at(s * 4.85, 3.95, -2.91), MIRROR)
	part(n("MirrorStalk"), v(0.45, 0.08, 0.3), at(s * 4.5, 3.8, -3.3), CARBON)
end

-- Front fascia and lights ---------------------------------------------------------------------

part("NoseBackPanel", v(7.6, 1.6, 0.1), at(0, 1.45, -9.75), MESH_BLACK)
part("UpperLip", v(6.2, 0.25, 0.4), at(0, 2.1, -9.95), BLUE)
part("LowerLip", v(7.6, 0.18, 0.5), at(0, 0.62, -10.0), BLUE)
part("LowerIntake", v(2.0, 0.3, 0.05), at(0, 0.82, -10.12), MESH_BLACK)

-- Horseshoe grille: chrome surround, black mesh, alloy bars, red badge.
part("HorseshoeChrome", v(1.8, 0.95, 0.1), at(0, 1.18, -10.15), ALLOY)
part("HorseshoeChromeTop", v(0.1, 1.8, 1.8), at(0, 1.75, -10.15) * CYLINDER_Z, ALLOY, nil, CYL)
part("HorseshoeMesh", v(1.56, 0.85, 0.1), at(0, 1.18, -10.19), MESH_BLACK)
part("HorseshoeMeshTop", v(0.1, 1.56, 1.56), at(0, 1.75, -10.19) * CYLINDER_Z, MESH_BLACK, nil, CYL)
for _, x in { -0.4, 0, 0.4 } do
	part("HorseshoeBar", v(0.05, 1.5, 0.05), at(x, 1.45, -10.26), ALLOY)
end
part("Badge", v(0.42, 0.26, 0.08), at(0, 2.5, -10.05), BADGE_RED, nil, BALL)

for _, s in SIDES do
	local function n(name: string): string
		return sideName(name, s)
	end
	part(n("GrilleSide"), v(0.35, 1.6, 0.4), at(s * 1.15, 1.45, -10.0), BLUE)
	part(n("Strake"), v(0.25, 1.4, 0.4), at(s * 2.3, 1.3, -9.95), BLUE)
	part(n("OuterIntake"), v(1.4, 1.1, 0.05), at(s * 3.15, 1.3, -9.84), MESH_BLACK)
	for _, y in { 1.0, 1.3, 1.6 } do
		part(n("OuterIntakeSlat"), v(1.4, 0.06, 0.06), at(s * 3.15, y, -9.88), GAP_BLACK)
	end
	-- Headlights: slim housing angled back at the outer end, four stepped LED cubes.
	local lamp = at(s * 3.3, 2.32, -9.62) * A(0, -s * math.rad(25), 0)
	part(n("HeadlightHousing"), v(1.55, 0.42, 0.6), lamp, HOUSING)
	for k = 0, 3 do
		local lx = s * (-0.54 + k * 0.36)
		part(n("LED"), v(0.28, 0.16, 0.08), lamp * at(lx, -0.1 + k * 0.065, -0.32), HEADLIGHT)
	end
	part(n("DRL"), v(1.4, 0.05, 0.06), lamp * at(0, -0.24, -0.27), HEADLIGHT)
	part(n("Indicator"), v(0.25, 0.1, 0.06), at(s * 4.1, 2.45, -9.25), AMBER)
end

-- Rear ----------------------------------------------------------------------------------------

part("LightBarHousing", v(8.2, 0.4, 0.1), at(0, 3.35, 10.24), GLOSS_BLACK)
part("LightBar", v(7.9, 0.12, 0.06), at(0, 3.35, 10.3), TAIL_RED)
part("RearMesh", v(7.6, 0.95, 0.05), at(0, 2.625, 10.24), MESH_BLACK)
for i = 0, 3 do
	part("RearSlat", v(7.6, 0.06, 0.08), at(0, 2.25 + i * 0.25, 10.28), GAP_BLACK)
end
part("Diffuser", v(8.4, 0.75, 1.2), at(0, 0.92, 9.6) * FLIP_X, CARBON, WEDGE)
for _, x in { -3.0, -1.5, 0, 1.5, 3.0 } do
	part("DiffuserFin", v(0.06, 0.8, 1.2), at(x, 0.95, 9.6), CARBON)
end
part("ExhaustSurround", v(1.6, 1.3, 0.1), at(0, 1.5, 10.2), GAP_BLACK)
for _, x in { -0.38, 0.38 } do
	for _, y in { 1.2, 1.8 } do
		part("ExhaustTip", v(0.45, 0.55, 0.55), at(x, y, 10.25) * CYLINDER_Z, TITANIUM, nil, CYL)
		part("ExhaustBore", v(0.04, 0.42, 0.42), at(x, y, 10.48) * CYLINDER_Z, BORE_BLACK, nil, CYL)
	end
end
part("WingPlate", v(7.4, 0.12, 1.6), at(0, 4.62, 9.0) * A(math.rad(-8), 0, 0), CARBON)
part("WingGurney", v(7.4, 0.12, 0.06), at(0, 4.78, 9.8), CARBON)
for _, s in SIDES do
	part(sideName("WingStrut", s), v(0.12, 0.55, 0.7), at(s * 1.6, 4.3, 9.0), CARBON)
	part(sideName("ReverseLamp", s), v(0.4, 0.1, 0.05), at(s * 3.0, 3.05, 10.27), REVERSE)
end
part("FuelFlap", v(0.04, 0.4, 0.4), at(-4.6, 3.4, 3.3), GAP_BLACK)

-- Wheels --------------------------------------------------------------------------------------

-- The tire is a solid cylinder, so the wheel face is layered on its outer side: dark dish, brake
-- disc, caliper, then the silver twin spokes and hub.
local WHEELS = {
	{ x = 3.72, y = 1.53, z = FRONT_AXLE_Z, w = 1.28, d = 3.06, rim = 2.29, disc = 1.85 },
	{ x = 3.62, y = 1.6, z = REAR_AXLE_Z, w = 1.6, d = 3.2, rim = 2.4, disc = 1.95 },
}
for _, wh in WHEELS do
	for _, s in SIDES do
		local c = v(s * wh.x, wh.y, wh.z)
		local face = wh.w / 2
		local function cyl(name: string, len: number, d: number, dx: number, style)
			part(sideName(name, s), v(len, d, d), CFrame.new(c + v(s * dx, 0, 0)), style, nil, CYL)
		end
		cyl("Tire", wh.w, wh.d, 0, TIRE)
		cyl("RimLip", 0.03, wh.rim, face + 0.015, RIM_SILVER)
		cyl("RimDish", 0.03, wh.rim - 0.16, face + 0.045, RIM_DARK)
		cyl("BrakeDisc", 0.03, wh.disc, face + 0.075, DISC)
		part(
			sideName("Caliper", s),
			v(0.04, 0.5, 0.85),
			CFrame.new(c + v(s * (face + 0.11), 0.5, 0.35)) * A(math.rad(-35), 0, 0),
			CALIPER_BLUE
		)
		for k = 0, 4 do
			for _, off in { -7, 7 } do
				part(
					sideName("Spoke", s),
					v(0.06, 0.95, 0.15),
					CFrame.new(c + v(s * (face + 0.16), 0, 0))
						* A(math.rad(k * 72 + off), 0, 0)
						* at(0, 0.6, 0),
					RIM_SILVER
				)
			end
		end
		cyl("HubCap", 0.1, 0.45, face + 0.2, RIM_SILVER)
		cyl("CenterBadge", 0.04, 0.2, face + 0.26, BADGE_RED)
	end
end

-- Interior ------------------------------------------------------------------------------------

for _, s in SIDES do
	part(sideName("SeatCushion", s), v(1.8, 0.3, 1.8), at(s * 1.4, 0.95, -1.0), LEATHER)
	part(
		sideName("Seatback", s),
		v(1.8, 2.6, 0.35),
		at(s * 1.4, 2.4, 0.08) * A(math.rad(12), 0, 0),
		LEATHER
	)
end
part("Dashboard", v(5.4, 0.9, 1.4), at(0, 3.0, -3.9), MATTE_BLACK)
part("DashTop", v(5.4, 0.08, 1.4), at(0, 3.49, -3.9), LEATHER)
part("Console", v(0.5, 1.2, 3.4), at(0, 1.6, -2.6), MATTE_BLACK)
part("ConsoleStrip", v(0.08, 0.06, 3.4), at(0, 2.23, -2.6), ALLOY)
local WHEEL_FRAME = at(-1.4, 2.95, -2.6) * A(math.rad(20), 0, 0)
part("SteeringWheel", v(0.12, 1.15, 1.15), WHEEL_FRAME * CYLINDER_Z, LEATHER_DARK, nil, CYL)
part(
	"SteeringHub",
	v(0.14, 0.35, 0.35),
	WHEEL_FRAME * at(0, 0, -0.02) * CYLINDER_Z,
	ALLOY,
	nil,
	CYL
)
part("SteeringColumn", v(0.18, 0.18, 0.9), WHEEL_FRAME * at(0, 0, -0.5), MATTE_BLACK)

return {
	name = "Bugatti Chiron",
	speed = 145,
	turnRate = 2.3,
	footprint = Vector2.new(8.8, 20.0),
	collision = {
		{ size = Vector3.new(9.0, 2.6, 20.0), offset = CFrame.new(0, 2.5, 0) },
		{ size = Vector3.new(5.6, 1.4, 8.0), offset = CFrame.new(0, 4.5, 2.0) },
	},
	seats = {
		CFrame.new(-1.4, 0.55, -1.0), -- driver (left-hand drive), seat top y 1.05
		CFrame.new(1.4, 0.55, -1.0),
	},
	pieces = pieces,
}
