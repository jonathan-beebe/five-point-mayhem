-- Tesla Cybertruck: triangular brushed-stainless electric pickup with full-width light bars and a tonneau-covered bed.

-- Scale: 4.2 studs = 1 m (the smallest scale that seats the avatar under the triangular roof).

local rgb, M, A = Color3.fromRGB, Enum.Material, CFrame.Angles
local CYL = Enum.PartType.Cylinder
local WEDGE = "WedgePart"

-- Rotations. Cylinder axis is local X; WedgePart default has its right angle at (ymin, zmax).
local CYLINDER_Z = A(0, math.rad(90), 0)
local FLIP_Z = A(0, 0, math.pi) -- wedge right angle at (ymax, zmax)
local FLIP_X = A(math.pi, 0, 0) -- wedge right angle at (ymax, zmin)
local RISE_FWD = A(0, math.pi, 0) -- wedge slope rises toward -Z

-- Profile lines: nose to apex (hood and windshield are coplanar), apex to tailgate.
local function yFront(z)
	return 4.50 + (z + 11.93) * 0.26892
end
local function yRear(z)
	return 7.52 - (z + 0.70) * 0.16772
end

-- Panel lying on the profile line (z0,y0)->(z1,y1); its top face sits at the line + lift.
local function slab(z0, y0, z1, y1, x, width, thick, lift)
	local dz, dy = z1 - z0, y1 - y0
	local cf = CFrame.new(x, (y0 + y1) / 2, (z0 + z1) / 2)
		* A(-math.atan2(dy, dz), 0, 0)
		* CFrame.new(0, (lift or 0) - thick / 2, 0)
	return Vector3.new(width, thick, math.sqrt(dz * dz + dy * dy)), cf
end

-- Greenhouse side frame, pivoting on the beltline at x = s*4.1 and tilted 12 deg inward.
-- h = slant height above the beltline. Outward along the panel normal is local +X*s.
local TILT = math.rad(12)
local function gh(s, h, z)
	return CFrame.new(s * 4.1, 5.4, 0) * A(0, 0, s * TILT) * CFrame.new(0, h, z)
end

-- Palette
local STAINLESS = rgb(168, 170, 173)
local SEAM = rgb(55, 57, 60)
local CLADDING = rgb(40, 41, 44)
local TRIM_DARK = rgb(32, 32, 35)
local GLOSS_BLACK = rgb(14, 14, 16)
local TONNEAU = rgb(46, 47, 50)
local RIB = rgb(30, 30, 32)
local GLASS = rgb(20, 24, 28)
local HEAD = rgb(240, 244, 255)
local TAIL = rgb(215, 20, 25)
local AMBER = rgb(255, 150, 20)
local REVERSE = rgb(215, 215, 220)
local TIRE = rgb(26, 26, 28)
local COVER = rgb(72, 74, 78)
local COVER_RIDGE = rgb(100, 102, 106)
local UNDER = rgb(20, 20, 22)
local PLATE = rgb(200, 200, 200)
local MIRROR = rgb(180, 190, 200)
local SEAT_FABRIC = rgb(30, 30, 32)
local DASH = rgb(42, 42, 46)
local FLOOR = rgb(25, 25, 27)
local SCREEN = rgb(15, 25, 40)
local WHEEL_BLACK = rgb(22, 22, 24)

local STEEL_REFLECT = 0.12

local FRONT_WC = -8.24
local REAR_WC = 7.03
local WHEEL_X = 3.72
local WHEEL_Y = 1.845

local pieces = {}

local function add(spec)
	table.insert(pieces, spec)
end

local function steel(name, size, offset, class)
	add({
		name = name,
		class = class,
		size = size,
		offset = offset,
		color = STAINLESS,
		material = M.Metal,
		reflectance = STEEL_REFLECT,
	})
end

local function dark(name, size, offset, color, class)
	add({ name = name, class = class, size = size, offset = offset, color = color })
end

local function glass(name, size, offset, class)
	add({
		name = name,
		class = class,
		size = size,
		offset = offset,
		color = GLASS,
		material = M.Glass,
		transparency = 0.45,
		reflectance = 0.15,
	})
end

local function neon(name, size, offset, color)
	add({ name = name, size = size, offset = offset, color = color, material = M.Neon })
end

-- Body: top surfaces along the profile lines --------------------------------------------------

do
	local size, cf = slab(-11.93, yFront(-11.93), -6.60, yFront(-6.60), 0, 8.46, 0.12, 0.02)
	steel("Hood", size, cf)
	for _, s in { -1, 1 } do
		size, cf = slab(-11.93, yFront(-11.93), -6.60, yFront(-6.60), s * 3.90, 0.05, 0.02, 0.035)
		dark("HoodSeam", size, cf, SEAM)
		size, cf = slab(-6.60, yFront(-6.60), -1.30, yFront(-1.30), s * 3.80, 0.40, 0.12, 0.03)
		steel("APillar", size, cf)
		size, cf = slab(-0.20, yRear(-0.20), 3.20, yRear(3.20), s * 3.80, 0.40, 0.12, 0.03)
		steel("RoofSideBand", size, cf)
		size, cf = slab(3.20, yRear(3.20), 11.94, yRear(11.94), s * 3.90, 0.70, 0.14, 0.03)
		steel("SailTopBand", size, cf)
	end
	size, cf = slab(-1.30, yFront(-1.30), -0.70, 7.52, 0, 8.0, 0.12, 0.03)
	steel("ApexHeaderFront", size, cf)
	size, cf = slab(-0.70, 7.52, -0.20, yRear(-0.20), 0, 8.0, 0.12, 0.03)
	steel("ApexHeaderRear", size, cf)
	size, cf = slab(3.20, yRear(3.20), 3.50, yRear(3.50), 0, 7.2, 0.12, 0.03)
	steel("CabinRearCrossbar", size, cf)

	size, cf = slab(3.50, yRear(3.50), 11.75, yRear(11.75), 0, 7.10, 0.10, 0)
	add({ name = "Tonneau", size = size, offset = cf, color = TONNEAU, material = M.Metal })
	-- Ribs every 0.68 studs along the slope.
	local slope = math.atan2(yRear(11.75) - yRear(3.50), 8.25)
	for i = 1, 12 do
		local d = 0.45 + (i - 1) * 0.68
		local z = 3.50 + d * math.cos(slope)
		local ribCf = CFrame.new(0, yRear(z), z) * A(-slope, 0, 0) * CFrame.new(0, 0.03 - 0.015, 0)
		dark("TonneauRib", Vector3.new(7.0, 0.03, 0.06), ribCf, RIB)
	end
end

-- Body: front and rear ------------------------------------------------------------------------

do
	-- Slabs run bottom-to-top so the outer face (local +Y) points forward.
	local size, cf = slab(-11.72, 3.20, -11.93, 4.38, 0, 8.40, 0.15)
	steel("FrontFascia", size, cf)
	size, cf = slab(-11.10, 1.60, -11.72, 3.20, 0, 8.30, 0.30)
	add({ name = "FrontBumper", size = size, offset = cf, color = CLADDING, material = M.Plastic })
	local bumperTilt = A(math.atan2(-0.62, 1.60), 0, 0)
	for _, s in { -1, 1 } do
		local z = -11.10 - 0.62 * (2.5 - 1.60) / 1.60
		dark(
			"TowHookCover",
			Vector3.new(0.35, 0.25, 0.04),
			CFrame.new(s * 2.6, 2.5, z) * bumperTilt * CFrame.new(0, 0, -0.03),
			TRIM_DARK
		)
	end
	dark("FrontSkidPlate", Vector3.new(6.0, 0.15, 1.6), CFrame.new(0, 1.55, -10.4), UNDER)

	steel("Tailgate", Vector3.new(8.46, 2.45, 0.20), CFrame.new(0, 4.175, 11.84))
	steel("TailgateCap", Vector3.new(8.46, 0.10, 0.30), CFrame.new(0, 5.35, 11.80))
	add({
		name = "RearBumper",
		size = Vector3.new(8.40, 1.25, 0.50),
		offset = CFrame.new(0, 2.325, 11.65),
		color = CLADDING,
		material = M.Plastic,
	})
	for _, s in { -1, 1 } do
		add({
			name = "RearBumperWrap",
			size = Vector3.new(0.25, 1.25, 2.40),
			offset = CFrame.new(s * 4.13, 2.325, 10.6),
			color = CLADDING,
			material = M.Plastic,
		})
	end
	dark("LicensePlate", Vector3.new(1.25, 0.60, 0.04), CFrame.new(0, 2.40, 11.92), PLATE)
	dark("HitchReceiver", Vector3.new(0.35, 0.35, 0.50), CFrame.new(0, 1.80, 11.85), UNDER)
	dark("BedTub", Vector3.new(7.0, 3.0, 8.2), CFrame.new(0, 3.8, 7.6), UNDER)
	dark("UnderbodyTub", Vector3.new(6.0, 0.40, 20.0), CFrame.new(0, 1.55, 0), UNDER)
end

-- Body: side panels ---------------------------------------------------------------------------

for _, s in { -1, 1 } do
	local x = s * 4.10
	steel("FenderTop", Vector3.new(0.30, 0.90, 3.35), CFrame.new(x, 4.87, -10.255), WEDGE)
	steel("SideP1", Vector3.new(0.30, 2.50, 1.24), CFrame.new(x, 3.25, -11.31))
	steel("SideP2", Vector3.new(0.30, 0.35, 4.90), CFrame.new(x, 4.325, -8.24))
	steel("SideP2b", Vector3.new(0.30, 0.90, 2.79), CFrame.new(x, 4.95, -7.185))
	steel("SideDoors", Vector3.new(0.30, 3.15, 10.37), CFrame.new(x, 3.825, -0.605))
	steel("SideP4", Vector3.new(0.30, 1.25, 4.90), CFrame.new(x, 4.775, 7.03))
	steel("SideP5", Vector3.new(0.30, 2.45, 2.46), CFrame.new(x, 4.175, 10.71))
	for _, wc in { FRONT_WC, REAR_WC } do
		steel(
			"ArchCornerFront",
			Vector3.new(0.30, 1.40, 1.15),
			CFrame.new(x, 3.45, wc - 1.875) * FLIP_X,
			WEDGE
		)
		steel(
			"ArchCornerRear",
			Vector3.new(0.30, 1.40, 1.15),
			CFrame.new(x, 3.45, wc + 1.875) * FLIP_Z,
			WEDGE
		)
	end
	add({
		name = "RockerCladding",
		size = Vector3.new(0.22, 0.90, 10.37),
		offset = CFrame.new(s * 4.20, 1.80, -0.605),
		color = CLADDING,
		material = M.Plastic,
	})
	for _, z in { -5.70, -0.75, 3.60 } do
		dark("DoorSeam", Vector3.new(0.03, 3.1, 0.06), CFrame.new(s * 4.265, 3.85, z), SEAM)
	end
	dark("DoorBeltSeam", Vector3.new(0.03, 0.04, 9.30), CFrame.new(s * 4.265, 5.36, -1.05), SEAM)
	if s < 0 then
		dark("ChargePortSeam", Vector3.new(0.03, 0.5, 0.7), CFrame.new(-4.265, 4.80, 10.6), SEAM)
	end
	dark(
		"FenderCamera",
		Vector3.new(0.03, 0.12, 0.20),
		CFrame.new(s * 4.265, 4.0, -9.7),
		GLOSS_BLACK
	)

	-- Greenhouse side frame.
	steel("APillarFoot", Vector3.new(0.20, 0.545, 1.983), gh(s, 0.2725, -7.5915), WEDGE)
	steel("Sail", Vector3.new(0.20, 1.499, 8.74), gh(s, 0.7495, 7.57) * RISE_FWD, WEDGE)

	-- Arch flares and wheel-well liners.
	for _, wc in { FRONT_WC, REAR_WC } do
		local fx = s * 4.31
		local chamfer = math.atan2(1.4, 1.15)
		dark("FlareTop", Vector3.new(0.12, 0.40, 2.60), CFrame.new(fx, 4.35, wc), CLADDING)
		dark(
			"FlareFront",
			Vector3.new(0.12, 0.40, 1.81),
			CFrame.new(fx, 3.45, wc - 1.875) * A(-chamfer, 0, 0),
			CLADDING
		)
		dark(
			"FlareRear",
			Vector3.new(0.12, 0.40, 1.81),
			CFrame.new(fx, 3.45, wc + 1.875) * A(chamfer, 0, 0),
			CLADDING
		)
		for _, dz in { -2.45, 2.45 } do
			dark(
				"FlareVertical",
				Vector3.new(0.12, 1.30, 0.40),
				CFrame.new(fx, 2.10, wc + dz),
				CLADDING
			)
		end
		dark("WellInner", Vector3.new(0.10, 2.9, 4.9), CFrame.new(s * 3.00, 2.90, wc), UNDER)
		dark("WellCeiling", Vector3.new(1.40, 0.10, 2.6), CFrame.new(s * 3.70, 4.10, wc), UNDER)
	end
end

-- Glass ---------------------------------------------------------------------------------------

do
	local size, cf = slab(-6.60, yFront(-6.60), -1.30, yFront(-1.30), 0, 7.20, 0.08, -0.01)
	glass("Windshield", size, cf)
	size, cf = slab(-0.20, yRear(-0.20), 3.20, yRear(3.20), 0, 7.20, 0.08, -0.01)
	glass("RoofGlass", size, cf)
	glass("CabinBackGlass", Vector3.new(7.2, 2.2, 0.06), CFrame.new(0, 5.7, 3.35))
	for _, s in { -1, 1 } do
		glass("FrontSideGlassLower", Vector3.new(0.08, 0.545, 5.90), gh(s, 0.2725, -3.65))
		glass("FrontSideGlassUpper", Vector3.new(0.08, 1.622, 5.90), gh(s, 1.356, -3.65), WEDGE)
		glass("RearSideGlass", Vector3.new(0.08, 1.499, 3.90), gh(s, 0.7495, 1.25))
		glass(
			"RearSideGlassTop",
			Vector3.new(0.08, 0.668, 3.90),
			gh(s, 1.833, 1.25) * RISE_FWD,
			WEDGE
		)
		add({
			name = "BPillar",
			size = Vector3.new(0.06, 2.16, 0.30),
			offset = gh(s, 1.08, -0.70) * CFrame.new(s * 0.05, 0, 0),
			color = GLOSS_BLACK,
			reflectance = 0.2,
		})
	end
end

-- Lights --------------------------------------------------------------------------------------

do
	add({
		name = "FrontLightHousing",
		size = Vector3.new(8.30, 0.22, 0.10),
		offset = CFrame.new(0, 4.36, -11.91),
		color = GLOSS_BLACK,
		reflectance = 0.2,
	})
	neon("FrontLightBar", Vector3.new(8.00, 0.08, 0.06), CFrame.new(0, 4.36, -11.97), HEAD)
	add({
		name = "RearLightHousing",
		size = Vector3.new(8.30, 0.20, 0.06),
		offset = CFrame.new(0, 5.20, 11.96),
		color = GLOSS_BLACK,
		reflectance = 0.2,
	})
	neon("RearLightBar", Vector3.new(8.10, 0.09, 0.05), CFrame.new(0, 5.20, 11.99), TAIL)
	for _, s in { -1, 1 } do
		neon("Headlamp", Vector3.new(0.80, 0.13, 0.05), CFrame.new(s * 3.55, 4.36, -11.985), HEAD)
		neon(
			"FrontAmberWrap",
			Vector3.new(0.04, 0.09, 0.40),
			CFrame.new(s * 4.27, 4.30, -11.70),
			AMBER
		)
		neon("RearSideWrap", Vector3.new(0.04, 0.09, 0.40), CFrame.new(s * 4.27, 5.20, 11.72), TAIL)
		add({
			name = "ReverseLens",
			size = Vector3.new(0.50, 0.09, 0.04),
			offset = CFrame.new(s * 1.0, 5.06, 11.99),
			color = REVERSE,
			material = M.Glass,
			transparency = 0.2,
		})
	end
	neon("HighMountBrake", Vector3.new(1.0, 0.05, 0.08), CFrame.new(0, 6.88, 3.35), TAIL)
end

-- Wheels --------------------------------------------------------------------------------------

for _, w in { { -1, FRONT_WC }, { 1, FRONT_WC }, { -1, REAR_WC }, { 1, REAR_WC } } do
	local s, wc = w[1], w[2]
	local cx = s * WHEEL_X
	local hub = CFrame.new(cx, WHEEL_Y, wc)
	dark("Tire", Vector3.new(1.20, 3.60, 3.60), hub, TIRE)
	pieces[#pieces].shape = CYL
	for i = 0, 15 do
		local a = i * 2 * math.pi / 16
		local shift = (i % 2 == 0) and 0.10 or -0.10
		dark(
			"Tread",
			Vector3.new(0.95, 0.12, 0.42),
			hub * A(a, 0, 0) * CFrame.new(shift, 1.785, 0),
			TIRE
		)
	end
	dark("AeroCover", Vector3.new(0.10, 2.90, 2.90), CFrame.new(s * 4.26, WHEEL_Y, wc), COVER)
	pieces[#pieces].shape = CYL
	for k = 0, 5 do
		dark(
			"CoverRidge",
			Vector3.new(0.04, 0.12, 1.25),
			CFrame.new(s * 4.32, WHEEL_Y, wc) * A(k * math.pi / 3, 0, 0) * CFrame.new(0, 0, 0.75),
			COVER_RIDGE
		)
	end
	add({
		name = "CenterCap",
		shape = CYL,
		size = Vector3.new(0.06, 0.70, 0.70),
		offset = CFrame.new(s * 4.34, WHEEL_Y, wc),
		color = GLOSS_BLACK,
		reflectance = 0.2,
	})
end

-- Interior ------------------------------------------------------------------------------------

do
	add({
		name = "Floor",
		size = Vector3.new(7.6, 0.10, 9.5),
		offset = CFrame.new(0, 1.90, -1.25),
		color = FLOOR,
		material = M.Fabric,
	})
	local function seat(name, size, cf)
		add({ name = name, size = size, offset = cf, color = SEAT_FABRIC, material = M.Fabric })
	end
	for _, s in { -1, 1 } do
		dark("SeatPedestal", Vector3.new(1.3, 0.53, 1.3), CFrame.new(s * 2.1, 2.215, -1.35), DASH)
		seat("FrontCushion", Vector3.new(1.9, 0.45, 1.9), CFrame.new(s * 2.1, 2.70, -1.35))
		seat("FrontSeatback", Vector3.new(1.9, 2.9, 0.26), CFrame.new(s * 2.1, 4.40, -0.56))
		dark("DoorTrimFront", Vector3.new(0.10, 1.2, 4.4), CFrame.new(s * 3.88, 4.6, -3.2), DASH)
		dark("DoorTrimRear", Vector3.new(0.10, 1.2, 4.4), CFrame.new(s * 3.88, 4.6, 1.3), DASH)
	end
	seat("RearBenchCushion", Vector3.new(7.0, 0.68, 1.9), CFrame.new(0, 2.29, 2.20))
	seat("RearBenchBack", Vector3.new(7.0, 3.0, 0.30), CFrame.new(0, 4.15, 3.00))
	dark("CenterConsole", Vector3.new(1.0, 1.0, 3.6), CFrame.new(0, 2.45, -2.0), DASH)
	dark("DashTop", Vector3.new(7.4, 0.55, 1.9), CFrame.new(0, 4.455, -4.85), DASH)
	dark("DashLower", Vector3.new(7.4, 1.6, 0.20), CFrame.new(0, 3.40, -5.0), DASH)
	add({
		name = "Touchscreen",
		size = Vector3.new(1.75, 1.0, 0.06),
		offset = CFrame.new(0, 5.20, -3.95) * A(math.rad(20), 0, 0),
		color = SCREEN,
		material = M.Glass,
		reflectance = 0.2,
	})

	local W = CFrame.new(-2.1, 4.80, -2.95) * A(math.rad(22), 0, 0)
	for _, dy in { -0.50, 0.50 } do
		dark("WheelRim", Vector3.new(1.30, 0.14, 0.14), W * CFrame.new(0, dy, 0), WHEEL_BLACK)
	end
	for _, dx in { -0.60, 0.60 } do
		dark("WheelRimSide", Vector3.new(0.14, 1.0, 0.14), W * CFrame.new(dx, 0, 0), WHEEL_BLACK)
	end
	dark("WheelHub", Vector3.new(0.50, 0.40, 0.10), W * CFrame.new(0, 0, 0.03), WHEEL_BLACK)
	dark(
		"SteeringColumn",
		Vector3.new(1.1, 0.2, 0.2),
		W * CFrame.new(0, 0, -0.6) * CYLINDER_Z,
		WHEEL_BLACK
	)
	pieces[#pieces].shape = CYL
end

-- Details -------------------------------------------------------------------------------------

do
	for _, s in { -1, 1 } do
		dark(
			"MirrorArm",
			Vector3.new(0.45, 0.10, 0.18),
			CFrame.new(s * 4.30, 5.55, -5.9),
			TRIM_DARK
		)
		dark(
			"MirrorHousing",
			Vector3.new(0.70, 0.45, 0.32),
			CFrame.new(s * 4.60, 5.70, -5.9),
			TRIM_DARK
		)
		add({
			name = "MirrorGlass",
			size = Vector3.new(0.60, 0.36, 0.02),
			offset = CFrame.new(s * 4.62, 5.70, -5.73),
			color = MIRROR,
			material = M.Glass,
			reflectance = 0.5,
		})
		neon(
			"MirrorRepeater",
			Vector3.new(0.40, 0.06, 0.04),
			CFrame.new(s * 4.65, 5.70, -6.08),
			AMBER
		)
	end
	local size, cf = slab(-6.45, yFront(-6.45), -6.25, yFront(-6.25), -0.4, 5.6, 0.06, 0.10)
	add({ name = "WiperBlade", size = size, offset = cf, color = GLOSS_BLACK, reflectance = 0.2 })
	size, cf = slab(-6.70, yFront(-6.70), -6.10, yFront(-6.10), 2.3, 0.12, 0.06, 0.10)
	add({ name = "WiperArm", size = size, offset = cf, color = GLOSS_BLACK, reflectance = 0.2 })
	dark("FrontCamera", Vector3.new(0.30, 0.10, 0.03), CFrame.new(0, 4.15, -11.82), GLOSS_BLACK)
end

return {
	name = "Tesla Cybertruck",
	-- Real: 209 km/h, 0-100 km/h in 2.7 s, brakes 0.85 g, coasts 0.2 g (VehicleDefaults maps them).
	speed = 74,
	acceleration = 17.3,
	braking = 15.1,
	coasting = 5.7,
	turnRate = 2.3,
	footprint = Vector2.new(8.0, 22.6),
	collision = {
		{ size = Vector3.new(8.5, 3.6, 23.2), offset = CFrame.new(0, 3.2, 0) }, -- y 1.4..5.0
		{ size = Vector3.new(7.2, 1.5, 7.5), offset = CFrame.new(0, 5.75, -0.75) }, -- cabin y 5.0..6.5
		{ size = Vector3.new(8.5, 0.5, 8.0), offset = CFrame.new(0, 5.25, 7.0) }, -- bed and sails
	},
	seats = {
		CFrame.new(-2.1, 2.45, -1.30), -- driver (LHD), top 2.95
		CFrame.new(2.1, 2.45, -1.30),
		CFrame.new(-2.1, 2.15, 2.25), -- rear, top 2.65
		CFrame.new(2.1, 2.15, 2.25),
	},
	pieces = pieces,
}
