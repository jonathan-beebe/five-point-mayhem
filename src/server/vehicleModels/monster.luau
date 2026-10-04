-- Monster Truck: red fiberglass pickup body on 66-inch Terra tires, gold shocks, 4-link solid axles and a chrome blower.

-- Scale: 4 studs = 1 m.

local rgb = Color3.fromRGB
local M = Enum.Material
local A = CFrame.Angles
local V = Vector3.new
local CF = CFrame.new
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball
local CYLINDER_Z = A(0, math.rad(90), 0)
local CYLINDER_Y = A(0, 0, math.rad(90))

local BODY_RED = rgb(200, 18, 24)
local TRIM_BLACK = rgb(24, 24, 26)
local STRIPE_WHITE = rgb(240, 240, 240)
local CHROME = rgb(205, 208, 214)
local WHEEL_SILVER = rgb(190, 192, 198)
local WHEEL_DISH = rgb(150, 152, 158)
local TIRE = rgb(30, 30, 32)
local CHASSIS = rgb(58, 60, 66)
local AXLE_BLACK = rgb(45, 45, 48)
local LINK = rgb(170, 172, 178)
local SHOCK_GOLD = rgb(196, 160, 52)
local ENGINE = rgb(70, 72, 78)
local INLET_BLACK = rgb(10, 10, 10)
local GLASS = rgb(90, 110, 125)
local HEAD_NEON = rgb(255, 244, 214)
local TAIL_NEON = rgb(220, 20, 20)
local AMBER_NEON = rgb(255, 150, 30)
local INTERIOR = rgb(38, 38, 42)
local SEAT = rgb(20, 20, 22)
local DASH = rgb(32, 32, 35)
local BEDLINER = rgb(42, 42, 45)

local PAINT_REFL = 0.12
local CHROME_REFL = 0.25

local pieces = {}

local function add(p)
	table.insert(pieces, p)
end

-- Plain block helper.
local function block(name, size, offset, color, mat, refl)
	add({
		name = name,
		size = size,
		offset = offset,
		color = color,
		material = mat,
		reflectance = refl,
	})
end

-- Cylinder (axis = local X of offset).
local function cyl(name, d, len, offset, color, mat, refl)
	add({
		name = name,
		shape = CYL,
		size = V(len, d, d),
		offset = offset,
		color = color,
		material = mat,
		reflectance = refl,
	})
end

-- Tube between two points.
local function rod(name, a, b, d, color, mat, refl)
	local len = (b - a).Magnitude
	add({
		name = name,
		shape = CYL,
		size = V(len, d, d),
		offset = CFrame.lookAt((a + b) / 2, b) * A(0, math.rad(90), 0),
		color = color,
		material = mat,
		reflectance = refl,
	})
end

local function red(name, size, offset)
	block(name, size, offset, BODY_RED, M.SmoothPlastic, PAINT_REFL)
end

local function black(name, size, offset)
	block(name, size, offset, TRIM_BLACK, M.SmoothPlastic)
end

local function chrome(name, size, offset)
	block(name, size, offset, CHROME, M.Metal, CHROME_REFL)
end

local SIDES = { -1, 1 }
local AXLES = { -7.2, 7.2 }

-- Wheels: Terra tires with chevron bar lugs, beadlock rims and planetary hubs.
for _, A_ in AXLES do
	for _, s in SIDES do
		local W = V(s * 5.4, 3.35, A_)
		cyl("Tire", 6.3, 4.4, CF(W), TIRE, M.Fabric)
		for i = 0, 9 do
			local th = math.rad(i * 36)
			add({
				name = "Lug",
				size = V(2.0, 0.42, 0.85),
				offset = CF(W) * A(th, 0, 0) * CF(s * 1.1, -3.14, 0) * A(0, math.rad(22), 0),
				color = TIRE,
				material = M.Fabric,
			})
			add({
				name = "Lug",
				size = V(2.0, 0.42, 0.85),
				offset = CF(W)
					* A(th + math.rad(18), 0, 0)
					* CF(-s * 1.1, -3.14, 0)
					* A(0, math.rad(-22), 0),
				color = TIRE,
				material = M.Fabric,
			})
		end
		cyl("BeadlockRing", 3.6, 0.08, CF(s * 7.63, 3.35, A_), WHEEL_SILVER, M.Metal, 0.15)
		cyl("RimDish", 2.9, 0.08, CF(s * 7.68, 3.35, A_), WHEEL_DISH, M.Metal)
		for b = 0, 5 do
			local a = math.rad(b * 60 + 30)
			add({
				name = "BeadlockBolt",
				shape = BALL,
				size = V(0.18, 0.18, 0.18),
				offset = CF(s * 7.70, 3.35 + 1.6 * math.sin(a), A_ + 1.6 * math.cos(a)),
				color = CHROME,
				material = M.Metal,
				reflectance = CHROME_REFL,
			})
		end
		cyl("PlanetaryHub", 1.3, 0.3, CF(s * 7.84, 3.35, A_), AXLE_BLACK, M.Metal)
		cyl("HubCap", 0.7, 0.08, CF(s * 8.03, 3.35, A_), CHROME, M.Metal, CHROME_REFL)
	end
end

-- Axles, steering and 4-links.
for _, A_ in AXLES do
	local S = math.sign(A_)
	cyl("AxleTube", 0.8, 6.0, CF(0, 3.35, A_), AXLE_BLACK, M.Metal)
	add({
		name = "DiffBall",
		shape = BALL,
		size = V(2.0, 2.0, 2.0),
		offset = CF(0.6, 3.35, A_),
		color = AXLE_BLACK,
		material = M.Metal,
	})
	cyl(
		"DiffCover",
		1.6,
		0.2,
		CF(0.6, 3.35, A_ + S * 1.0) * CYLINDER_Z,
		CHROME,
		M.Metal,
		CHROME_REFL
	)
	cyl("PinionSnout", 0.7, 0.8, CF(0.6, 3.35, S * 5.9) * CYLINDER_Z, AXLE_BLACK, M.Metal)
	for _, s in SIDES do
		cyl("PlanetaryHousing", 1.5, 0.5, CF(s * 2.95, 3.35, A_), AXLE_BLACK, M.Metal)
	end
	cyl("TieRod", 0.3, 6.0, CF(0, 2.9, S * 8.5), LINK, M.Metal, 0.1)
	cyl("SteeringRam", 0.45, 2.4, CF(-1.6, 3.5, S * 8.5), CHROME, M.Metal, CHROME_REFL)
	block("ShockTower", V(5.0, 0.35, 2.4), CF(0, 8.32, A_), CHASSIS, M.Metal)

	for _, s in SIDES do
		rod("LowerLink", V(s * 1.8, 2.8, A_), V(s * 1.6, 6.2, S * 2.4), 0.35, LINK, M.Metal, 0.1)
	end
	rod("UpperLink", V(0.2, 4.3, A_ - S * 0.4), V(-1.4, 6.3, S * 3.4), 0.35, LINK, M.Metal, 0.1)
	rod("UpperLink", V(1.0, 4.3, A_ - S * 0.4), V(1.4, 6.3, S * 3.4), 0.35, LINK, M.Metal, 0.1)

	-- Shocks: two per wheel, inboard of the tire.
	for _, s in SIDES do
		for _, k in SIDES do
			local B = V(s * 2.5, 3.9, A_ + k * 0.6)
			local T = V(s * 2.15, 8.2, A_ + k * 0.95)
			local function P(t)
				return B:Lerp(T, t)
			end
			local R = V(0, 0, k * 0.45)
			rod("ShockShaft", P(0), P(0.40), 0.22, CHROME, M.Metal, CHROME_REFL)
			rod("ShockBody", P(0.35), P(0.98), 0.55, SHOCK_GOLD, M.Metal, 0.1)
			rod("ShockReservoir", P(0.5) + R, P(0.85) + R, 0.36, AXLE_BLACK, M.Metal)
		end
	end
end

-- Chassis.
for _, s in SIDES do
	block("FrameRail", V(0.5, 0.6, 19.0), CF(s * 1.6, 6.6, 0), CHASSIS, M.Metal)
end
for _, z in { -9.2, -2.2, 2.2, 9.2 } do
	cyl("Crossmember", 0.4, 3.7, CF(0, 6.6, z), CHASSIS, M.Metal)
end
for _, s in SIDES do
	for _, z in { -9.0, 9.0 } do
		block("BodyMount", V(0.3, 1.6, 0.3), CF(s * 1.6, 7.7, z), CHASSIS, M.Metal)
	end
end
cyl("PushBar", 0.45, 7.6, CF(0, 8.0, -10.4), CHROME, M.Metal, CHROME_REFL)
for _, s in SIDES do
	rod("PushBarStrut", V(s * 1.6, 6.6, -9.5), V(s * 2.6, 8.0, -10.4), 0.3, CHASSIS, M.Metal)
end

-- Engine and blower.
block("EngineBlock", V(2.4, 1.8, 3.4), CF(0, 7.6, -5.0), ENGINE, M.Metal)
block("BlowerCase", V(1.5, 3.8, 2.0), CF(0, 10.4, -5.0), WHEEL_SILVER, M.Metal, 0.15)
chrome("BugCatcher", V(1.3, 0.8, 1.2), CF(0, 12.75, -5.1))
block("ScoopInlet", V(1.0, 0.5, 0.04), CF(0, 12.8, -5.72), INLET_BLACK, M.SmoothPlastic)
for _, s in SIDES do
	rod("Zoomie", V(s * 1.2, 7.4, -4.0), V(s * 2.9, 7.7, -2.9), 0.4, CHROME, M.Metal, CHROME_REFL)
	cyl("ZoomieTip", 0.5, 0.4, CF(s * 3.1, 7.7, -2.9), CHROME, M.Metal, CHROME_REFL)
end

-- Driveline.
cyl("Transmission", 1.1, 2.4, CF(0, 7.3, -2.1) * CYLINDER_Z, ENGINE, M.Metal)
block("TransferCase", V(1.4, 1.4, 1.0), CF(0.6, 6.0, -0.4), AXLE_BLACK, M.Metal)
rod("FrontDriveshaft", V(0.6, 5.6, -0.9), V(0.6, 3.35, -5.5), 0.35, LINK, M.Metal, 0.1)
rod("RearDriveshaft", V(0.6, 5.6, 0.1), V(0.6, 3.35, 5.5), 0.35, LINK, M.Metal, 0.1)

-- Body: front clip.
red("FrontClip", V(8.4, 2.95, 7.0), CF(0, 9.975, -6.5))
red("Hood", V(7.8, 0.5, 6.6), CF(0, 11.35, -6.1))
add({
	name = "HoodChamfer",
	class = "WedgePart",
	size = V(7.8, 0.5, 0.6),
	offset = CF(0, 11.35, -9.7),
	color = BODY_RED,
	material = M.SmoothPlastic,
	reflectance = PAINT_REFL,
})
chrome("GrilleSurround", V(4.6, 1.5, 0.12), CF(0, 10.15, -10.04))
block("GrilleInsert", V(4.2, 1.2, 0.04), CF(0, 10.15, -10.11), INLET_BLACK, M.SmoothPlastic)
for _, y in { 9.7, 10.0, 10.3, 10.6 } do
	chrome("GrilleSlat", V(4.2, 0.08, 0.04), CF(0, y, -10.15))
end
black("FrontValance", V(8.6, 0.35, 0.35), CF(0, 8.65, -10.05))

-- Body: cab (hollow shell).
for _, s in SIDES do
	red("CabSide", V(0.3, 3.1, 5.7), CF(s * 4.05, 10.05, -0.15))
end
block("CabFloor", V(7.8, 0.3, 5.7), CF(0, 8.65, -0.15), INTERIOR, M.Fabric)
red("CabRearWall", V(7.8, 2.8, 0.3), CF(0, 10.2, 2.55))
block("Dash", V(7.8, 0.8, 1.0), CF(0, 11.05, -2.5), DASH, M.SmoothPlastic)
for _, s in SIDES do
	red("APillar", V(0.35, 3.05, 0.35), CF(s * 3.55, 12.85, -2.15) * A(math.rad(34.2), 0, 0))
end
red("Roof", V(7.4, 0.3, 3.95), CF(0, 14.2, 0.675))
for _, s in SIDES do
	red("CPost", V(0.5, 2.5, 0.5), CF(s * 3.55, 12.85, 2.4))
	black("BStrip", V(0.12, 2.4, 0.15), CF(s * 3.66, 12.85, 1.3))
	black("WindowSill", V(0.6, 0.1, 5.7), CF(s * 3.85, 11.65, -0.15))
	for _, z in { -2.85, 1.3, 2.75 } do
		black("DoorGap", V(0.07, 2.8, 0.06), CF(s * 4.235, 10.05, z))
	end
	chrome("DoorHandle", V(0.08, 0.15, 0.5), CF(s * 4.25, 11.25, 0.9))
	black("MirrorArm", V(0.5, 0.12, 0.12), CF(s * 4.45, 12.0, -2.6))
	black("MirrorHead", V(0.25, 0.75, 0.9), CF(s * 4.8, 12.2, -2.6))
end

-- Body: bed.
for _, s in SIDES do
	red("BedSide", V(0.3, 3.1, 7.3), CF(s * 4.05, 10.05, 6.35))
	black("BedRailCap", V(0.5, 0.12, 7.3), CF(s * 4.0, 11.66, 6.35))
end
block("BedFloor", V(7.8, 0.3, 7.3), CF(0, 9.05, 6.35), BEDLINER, M.Fabric)
red("Tailgate", V(7.8, 2.9, 0.3), CF(0, 10.05, 9.85))
black("TailgateHandle", V(1.0, 0.25, 0.06), CF(0, 11.0, 10.03))
chrome("RearBumper", V(8.4, 0.5, 0.5), CF(0, 8.55, 10.25))
black("FuelCell", V(2.4, 1.4, 1.8), CF(0, 9.9, 4.5))
cyl("FillerCap", 0.5, 0.15, CF(0, 10.68, 4.5) * CYLINDER_Y, CHROME, M.Metal, CHROME_REFL)

-- Trim.
for _, s in SIDES do
	for _, z in { -7.0, 7.0 } do
		black("FenderFlare", V(0.6, 0.35, 6.0), CF(s * 4.3, 8.62, z))
	end
	block("BeltStripe", V(0.05, 0.3, 19.8), CF(s * 4.225, 10.9, 0), STRIPE_WHITE, M.SmoothPlastic)
end

-- Glass.
local function glass(name, size, offset, class)
	add({
		name = name,
		class = class,
		size = size,
		offset = offset,
		color = GLASS,
		material = M.Glass,
		transparency = 0.45,
	})
end
glass("Windshield", V(6.8, 3.02, 0.1), CF(0, 12.85, -2.15) * A(math.rad(34.2), 0, 0))
for _, x in { -1.6, 1.6 } do
	black("Wiper", V(2.6, 0.08, 0.08), CF(x - 0.3, 11.78, -3.0) * A(0, 0, math.rad(6)))
end
glass("RearGlass", V(6.6, 2.3, 0.1), CF(0, 12.85, 2.45))
for _, s in SIDES do
	glass("SideGlass", V(0.1, 2.45, 3.3), CF(s * 3.6, 12.85, 0.5))
	glass("SideGlassFront", V(0.1, 2.5, 1.7), CF(s * 3.6, 12.85, -2.15), "WedgePart")
end

-- Lights.
for _, s in SIDES do
	chrome("HeadlightBezel", V(1.2, 1.1, 0.08), CF(s * 3.0, 10.15, -10.04))
	block("Headlight", V(1.0, 0.9, 0.06), CF(s * 3.0, 10.15, -10.09), HEAD_NEON, M.Neon)
	block("Indicator", V(0.9, 0.3, 0.06), CF(s * 3.0, 9.35, -10.05), AMBER_NEON, M.Neon)
	block("Taillight", V(0.5, 1.6, 0.08), CF(s * 3.95, 10.4, 10.04), TAIL_NEON, M.Neon)
end
black("LightBar", V(5.4, 0.2, 0.4), CF(0, 14.45, -0.8))
for _, x in { -2.1, -0.7, 0.7, 2.1 } do
	black("LightPod", V(0.75, 0.6, 0.35), CF(x, 14.85, -0.85))
	block("PodLens", V(0.6, 0.45, 0.05), CF(x, 14.85, -1.04), HEAD_NEON, M.Neon)
end

-- Interior.
for _, s in SIDES do
	block("SeatPedestal", V(1.2, 0.85, 1.2), CF(s * 1.4, 9.22, 0.75), CHASSIS, M.Metal)
	block("SeatBase", V(1.8, 0.35, 1.7), CF(s * 1.4, 9.82, 0.75), SEAT, M.Fabric)
	block("SeatBack", V(1.9, 3.0, 0.35), CF(s * 1.4, 11.3, 1.65), SEAT, M.Fabric)
end
local WHEEL_CF = CF(-1.4, 11.9, -0.65) * A(math.rad(25), 0, 0) * CYLINDER_Z
cyl("SteeringWheel", 1.3, 0.15, WHEEL_CF, SEAT, M.Fabric)
cyl("SteeringHub", 0.35, 0.2, WHEEL_CF, TRIM_BLACK, M.SmoothPlastic)
rod("SteeringColumn", V(-1.4, 11.75, -0.95), V(-1.4, 11.2, -2.0), 0.18, TRIM_BLACK, M.SmoothPlastic)
black("GaugePod", V(1.8, 0.5, 0.4), CF(-1.4, 11.7, -2.2))
chrome("RearSteerLever", V(0.12, 0.6, 0.12), CF(-0.2, 9.3, -0.3))

-- Roll cage.
for _, s in SIDES do
	cyl("HoopLeg", 0.25, 5.05, CF(s * 3.2, 11.3, 2.1) * CYLINDER_Y, CHASSIS, M.Metal)
end
cyl("HoopTop", 0.25, 6.4, CF(0, 13.8, 2.1), CHASSIS, M.Metal)
for _, s in SIDES do
	rod("RoofBar", V(s * 3.2, 13.8, -1.3), V(s * 3.2, 13.8, 2.1), 0.25, CHASSIS, M.Metal)
	rod("Downbar", V(s * 3.2, 11.6, -2.9), V(s * 3.2, 13.8, -1.4), 0.25, CHASSIS, M.Metal)
end

return {
	name = "Monster Truck",
	speed = 85,
	turnRate = 2.4,
	footprint = Vector2.new(15.2, 21.2),
	collision = {
		{ size = V(15.2, 7.2, 21.2), offset = CF(0, 4.8, 0) },
		{ size = V(8.6, 3.2, 20.6), offset = CF(0, 10.0, 0) },
		{ size = V(7.6, 2.6, 4.0), offset = CF(0, 12.9, 0.5) },
	},
	seats = { CF(-1.4, 9.5, 0.8), CF(1.4, 9.5, 0.8) },
	pieces = pieces,
}
