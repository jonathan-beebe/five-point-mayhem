-- School Bus: Blue Bird Vision conventional school bus in glossy school-bus yellow with black rub rails.
-- Scale: 4 studs = 1 m. 36 ft body, front axle z -18.6, rear duals z 6.4, track 8.3.

local rgb = Color3.fromRGB
local M = Enum.Material
local A = CFrame.Angles
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball
local CYLINDER_Z = A(0, math.rad(90), 0) -- cylinder axis along Z
local CYLINDER_Y = A(0, 0, math.rad(90)) -- cylinder axis along Y
local SIDE_L = A(0, math.pi / 2, 0) -- wedge length along Z, tall face toward +X
local SIDE_R = A(0, -math.pi / 2, 0) -- wedge length along Z, tall face toward -X
local REAR = A(0, math.pi, 0) -- wedge rises toward -Z
local WS = A(math.rad(12.1), 0, 0) -- windshield rake, top tipped toward +Z

-- Palette: { color, material, reflectance, transparency }.
local YELLOW = { rgb(245, 185, 18), M.SmoothPlastic, 0.12 }
local TRIM = { rgb(20, 20, 22), M.SmoothPlastic, 0.05 }
local BUMPER = { rgb(30, 30, 32), M.Metal }
local GLASS = { rgb(140, 165, 175), M.Glass, 0, 0.4 }
local WS_GLASS = { rgb(140, 165, 175), M.Glass, 0, 0.35 }
local DARK_GLASS = { rgb(28, 36, 42), M.Glass, 0.25 }
local TIRE = { rgb(30, 30, 32), M.Fabric }
local RIM = { rgb(232, 232, 226), M.Metal }
local HUB = { rgb(90, 90, 95), M.Metal }
local CHROME = { rgb(200, 202, 206), M.Metal, 0.3 }
local HEAD_NEON = { rgb(255, 244, 214), M.Neon }
local AMBER_NEON = { rgb(255, 150, 20), M.Neon }
local RED_NEON = { rgb(220, 30, 25), M.Neon }
local WHITE_NEON = { rgb(250, 250, 250), M.Neon }
local STOP_RED = { rgb(196, 20, 30), M.SmoothPlastic }
local PLATE = { rgb(245, 245, 245), M.SmoothPlastic }
local VINYL = { rgb(50, 78, 58), M.SmoothPlastic }
local FLOOR = { rgb(58, 58, 62), M.SmoothPlastic }
local CEILING = { rgb(222, 222, 214), M.SmoothPlastic }
local DASH = { rgb(40, 40, 44), M.SmoothPlastic }
local WHEEL_BLACK = { rgb(25, 25, 25), M.SmoothPlastic }
local CHASSIS = { rgb(26, 26, 28), M.Metal }
local EXHAUST = { rgb(110, 105, 100), M.Metal }
local HATCH = { rgb(200, 200, 195), M.SmoothPlastic }
local STROBE = { rgb(245, 248, 255), M.Glass, 0, 0.2 }

local pieces = {}

local function part(name, size, offset, style, shape, class)
	table.insert(pieces, {
		name = name,
		class = class,
		shape = shape,
		size = size,
		offset = offset,
		color = style[1],
		material = style[2],
		reflectance = style[3],
		transparency = style[4],
	})
end

local function wedge(name, size, offset, style)
	part(name, size, offset, style, nil, "WedgePart")
end

local V = Vector3.new
local C = CFrame.new
local SIDES = { -1, 1 }

---------------------------------------------------------------------------
-- Body shell
---------------------------------------------------------------------------
part("SideUpperBandL", V(0.2, 2.4, 36.6), C(-4.8, 6.0, 2.3), YELLOW)
part("SideUpperBandR", V(0.2, 2.4, 33.4), C(4.8, 6.0, 3.9), YELLOW)
part("SideLowerFwdL", V(0.2, 2.6, 19.9), C(-4.8, 3.5, -6.05), YELLOW)
part("SideLowerFwdR", V(0.2, 2.6, 16.7), C(4.8, 3.5, -4.45), YELLOW)
for _, s in SIDES do
	part("SideLowerAft", V(0.2, 2.6, 11.7), C(s * 4.8, 3.5, 14.75), YELLOW)
	part("Header", V(0.2, 1.2, 36.6), C(s * 4.8, 11.0, 2.3), YELLOW)
	wedge("Eave", V(36.3, 0.6, 0.6), C(s * 4.6, 11.9, 2.45) * (s < 0 and SIDE_L or SIDE_R), YELLOW)
	part("RearCorner", V(9.4, 1.2, 1.2), C(s * 4.3, 6.9, 20.6) * CYLINDER_Y, YELLOW, CYL)
	part("WheelHump", V(2.4, 1.0, 5.2), C(s * 3.5, 4.5, 6.4), FLOOR)
end
part("FrontPostL", V(0.2, 3.2, 0.2), C(-4.8, 8.8, -15.9), YELLOW)
part("FrontPostR", V(0.2, 8.2, 0.2), C(4.8, 6.3, -15.9), YELLOW)
part("DoorFillerR", V(0.2, 3.2, 1.0), C(4.8, 8.8, -12.3), YELLOW)
part("RoofCrown", V(8.6, 0.6, 34.9), C(0, 11.9, 3.15), YELLOW)
part("FrontWall", V(9.8, 5.6, 0.2), C(0, 5.0, -16.1), YELLOW)
part("FrontHeader", V(9.76, 1.0, 1.4), C(0, 11.1, -15.0), YELLOW)
wedge("FrontCap", V(8.6, 0.6, 1.4), C(0, 11.9, -15.0), YELLOW)
part("RearWall", V(8.6, 9.4, 0.2), C(0, 6.9, 21.1), YELLOW)
wedge("RearCap", V(8.6, 0.6, 0.6), C(0, 11.9, 20.9) * REAR, YELLOW)
part("Ceiling", V(9.2, 0.05, 36.4), C(0, 11.52, 2.4), CEILING)
part("FloorMain", V(9.4, 0.2, 33.8), C(0, 3.9, 4.1), FLOOR)
part("FloorFront", V(7.1, 0.2, 3.2), C(-1.15, 3.9, -14.4), FLOOR)

---------------------------------------------------------------------------
-- Hood, fenders, grille, bumpers
---------------------------------------------------------------------------
part("HoodBody", V(7.0, 3.6, 5.0), C(0, 4.6, -18.7), YELLOW)
wedge("HoodTop", V(7.0, 1.2, 5.0), C(0, 7.0, -18.7), YELLOW)
for _, s in SIDES do
	part("HoodSeam", V(0.06, 0.06, 5.0), C(s * 3.5, 6.42, -18.7), TRIM)
	part("FenderTop", V(1.4, 1.6, 4.9), C(s * 4.2, 5.5, -18.65), YELLOW)
	wedge("FenderCrown", V(1.4, 0.6, 4.9), C(s * 4.2, 6.6, -18.65), YELLOW)
	part("FenderFrontDrop", V(1.4, 1.4, 0.5), C(s * 4.2, 4.0, -20.85), YELLOW)
	part("FenderRearDrop", V(1.4, 1.4, 0.3), C(s * 4.2, 4.0, -16.35), YELLOW)
	part("FenderLiner", V(1.2, 0.08, 4.2), C(s * 4.2, 4.66, -18.6), TRIM)
	part("FenderEdge", V(0.1, 0.2, 4.9), C(s * 4.96, 4.8, -18.65), TRIM)
end
part("GrilleSurround", V(3.8, 3.4, 0.1), C(0, 4.6, -21.25), CHROME)
part("GrilleMesh", V(3.4, 3.0, 0.04), C(0, 4.6, -21.32), TRIM)
for i = 0, 4 do
	part("GrilleSlat", V(3.4, 0.12, 0.06), C(0, 3.4 + 0.6 * i, -21.36), CHROME)
end
part("Emblem", V(0.06, 0.6, 0.6), C(0, 6.05, -21.33) * CYLINDER_Z, CHROME, CYL)
part("FrontBumper", V(9.6, 1.2, 0.8), C(0, 2.2, -21.8), BUMPER)
part("FrontPlate", V(1.2, 0.6, 0.05), C(-1.6, 2.2, -22.23), PLATE)
part("RearBumper", V(9.8, 1.2, 0.8), C(0, 2.4, 21.6), BUMPER)
part("RearPlate", V(1.2, 0.6, 0.04), C(-2.4, 3.85, 21.24), PLATE)
for _, s in SIDES do
	part("RearArchTrim", V(0.12, 2.6, 0.2), C(s * 4.96, 3.5, 3.9), TRIM)
	part("RearArchTrim", V(0.12, 2.6, 0.2), C(s * 4.96, 3.5, 8.9), TRIM)
	part("RearArchTop", V(0.12, 0.2, 5.0), C(s * 4.96, 4.8, 6.4), TRIM)
	part("RearArchLiner", V(1.6, 0.1, 5.0), C(s * 4.0, 4.75, 6.4), TRIM)
end

---------------------------------------------------------------------------
-- Glass, windows, doors
---------------------------------------------------------------------------
for _, s in SIDES do
	for k = 0, 11 do
		part("Pillar", V(0.2, 3.2, 0.4), C(s * 4.8, 8.8, -11.6 + 2.91 * k), YELLOW)
	end
	for i = 0, 10 do
		part("SideGlass", V(0.06, 2.9, 2.5), C(s * 4.8, 8.8, -10.145 + 2.91 * i), GLASS)
	end
	local len, cz = 32.4, 4.4
	if s < 0 then
		len, cz = 36.4, 2.4
	end
	part("WinFrameTop", V(0.1, 0.2, len), C(s * 4.95, 10.3, cz), TRIM)
	part("WinFrameBot", V(0.1, 0.2, len), C(s * 4.95, 7.3, cz), TRIM)
	part("SashBar", V(0.06, 0.12, 32.4), C(s * 4.86, 8.95, 4.4), TRIM)
end
part("DriverGlassL", V(0.06, 2.9, 4.0), C(-4.8, 8.8, -13.8), GLASS)
part("DriverSliderL", V(0.1, 3.0, 0.1), C(-4.85, 8.8, -13.8), TRIM)

-- Windshield
for _, s in SIDES do
	part("Windshield", V(4.4, 2.86, 0.08), C(s * 2.3, 9.2, -15.9) * WS, WS_GLASS)
	part("APillar", V(0.4, 2.9, 0.3), C(s * 4.7, 9.2, -15.9) * WS, TRIM)
end
part("WSCenterPost", V(0.2, 2.9, 0.12), C(0, 9.2, -15.92) * WS, TRIM)
part("WSGasket", V(9.0, 0.15, 0.2), C(0, 7.85, -16.22), TRIM)

-- Entrance door (right side)
part("DoorGlass", V(0.05, 8.0, 1.3), C(4.88, 6.4, -15.05), GLASS)
part("DoorGlass", V(0.05, 8.0, 1.3), C(4.88, 6.4, -13.55), GLASS)
for _, z in { -15.75, -14.3, -12.85 } do
	part("DoorFrameV", V(0.12, 8.2, 0.14), C(4.92, 6.4, z), TRIM)
end
for _, y in { 2.35, 6.6, 10.45 } do
	part("DoorFrameH", V(0.12, 0.14, 3.0), C(4.92, y, -14.3), TRIM)
end

-- Rear emergency door and windows
part("RearDoorGap", V(3.3, 6.65, 0.03), C(0, 7.325, 21.225), TRIM)
part("RearDoorSkin", V(3.1, 6.45, 0.05), C(0, 7.325, 21.27), YELLOW)
part("RearDoorGlassUp", V(2.5, 2.8, 0.04), C(0, 8.8, 21.33), DARK_GLASS)
part("RearDoorGlassLo", V(2.5, 1.5, 0.04), C(0, 6.05, 21.33), DARK_GLASS)
part("RearDoorHandle", V(0.7, 0.15, 0.15), C(0.9, 7.1, 21.38), CHROME)
part("RearHinge", V(0.15, 0.6, 0.12), C(-1.62, 5.0, 21.3), TRIM)
part("RearHinge", V(0.15, 0.6, 0.12), C(-1.62, 9.6, 21.3), TRIM)
for _, s in SIDES do
	part("RearWinGasket", V(2.3, 3.0, 0.03), C(s * 3.0, 8.8, 21.225), TRIM)
	part("RearWinGlass", V(2.1, 2.8, 0.04), C(s * 3.0, 8.8, 21.27), DARK_GLASS)
end

---------------------------------------------------------------------------
-- Rub rails
---------------------------------------------------------------------------
local function sideRail(s, y, z0, z1)
	part("RubRail", V(0.14, 0.32, z1 - z0), C(s * 4.97, y, (z0 + z1) / 2), TRIM)
end
for _, s in SIDES do
	local front = s < 0 and -16.0 or -12.8
	-- Side rails run to the rear corner; the rear rails wrap around it to x +-5.04.
	sideRail(s, 6.85, front, 21.2)
	sideRail(s, 5.6, front, 21.2)
	sideRail(s, 3.2, front, 3.9)
	sideRail(s, 3.2, 8.9, 21.2)
	for _, y in { 5.6, 6.85 } do
		part("RearRail", V(3.39, 0.32, 0.14), C(s * 3.345, y, 21.27), TRIM)
	end
end
part("RearRail", V(10.08, 0.32, 0.14), C(0, 3.2, 21.27), TRIM)

---------------------------------------------------------------------------
-- Lights
---------------------------------------------------------------------------
for _, s in SIDES do
	-- Headlamps and front turns
	part("HeadBezel", V(1.5, 1.0, 0.08), C(s * 2.7, 5.0, -21.24), TRIM)
	part("Headlamp", V(0.06, 0.6, 0.6), C(s * 2.35, 5.0, -21.3) * CYLINDER_Z, HEAD_NEON, CYL)
	part("Headlamp", V(0.06, 0.6, 0.6), C(s * 3.05, 5.0, -21.3) * CYLINDER_Z, HEAD_NEON, CYL)
	part("FrontTurn", V(1.3, 0.3, 0.06), C(s * 2.7, 4.25, -21.28), AMBER_NEON)

	-- Front 8-way warning lamps
	part("CapBacking", V(2.2, 0.95, 0.06), C(s * 3.3, 11.1, -15.73), TRIM)
	part("WarnAmber", V(0.12, 0.8, 0.8), C(s * 2.7, 11.1, -15.8) * CYLINDER_Z, AMBER_NEON, CYL)
	part("WarnRed", V(0.12, 0.8, 0.8), C(s * 3.9, 11.1, -15.8) * CYLINDER_Z, RED_NEON, CYL)
	part("Visor", V(0.9, 0.08, 0.35), C(s * 2.7, 11.55, -15.88), TRIM)
	part("Visor", V(0.9, 0.08, 0.35), C(s * 3.9, 11.55, -15.88), TRIM)

	-- Rear 8-way warning lamps
	part("RearCapBacking", V(2.3, 0.95, 0.04), C(s * 3.0, 10.9, 21.24), TRIM)
	part("RearWarnAmber", V(0.08, 0.8, 0.8), C(s * 2.4, 10.9, 21.3) * CYLINDER_Z, AMBER_NEON, CYL)
	part("RearWarnRed", V(0.08, 0.8, 0.8), C(s * 3.6, 10.9, 21.3) * CYLINDER_Z, RED_NEON, CYL)

	-- Tail stacks, standing proud of the rear rails
	part("TailHousing", V(1.0, 2.7, 0.2), C(s * 3.6, 5.05, 21.3), TRIM)
	part("TailStop", V(0.06, 0.75, 0.75), C(s * 3.6, 5.9, 21.42) * CYLINDER_Z, RED_NEON, CYL)
	part("TailTurn", V(0.06, 0.75, 0.75), C(s * 3.6, 5.05, 21.42) * CYLINDER_Z, AMBER_NEON, CYL)
	part("TailBackup", V(0.06, 0.75, 0.75), C(s * 3.6, 4.2, 21.42) * CYLINDER_Z, WHITE_NEON, CYL)

	-- Side markers
	part("MarkerFront", V(0.06, 0.25, 0.45), C(s * 4.97, 4.2, s < 0 and -15.6 or -12.4), AMBER_NEON)
	part("MarkerMid", V(0.06, 0.25, 0.45), C(s * 4.97, 4.2, 2.5), AMBER_NEON)
	part("MarkerRear", V(0.06, 0.25, 0.45), C(s * 4.97, 4.2, 20.2), RED_NEON)
end
part("SignFrame", V(2.6, 0.8, 0.04), C(0, 11.1, -15.72), TRIM)
part("SignFace", V(2.4, 0.6, 0.04), C(0, 11.1, -15.76), YELLOW)
part("RearSignFrame", V(2.9, 0.75, 0.03), C(0, 11.15, 21.225), TRIM)
part("RearSignFace", V(2.7, 0.55, 0.03), C(0, 11.15, 21.26), YELLOW)
for _, x in { -0.5, 0, 0.5 } do
	part("IdLampFront", V(0.3, 0.15, 0.25), C(x, 12.27, -14.5), AMBER_NEON)
	part("IdLampRear", V(0.3, 0.15, 0.25), C(x, 12.27, 20.4), RED_NEON)
end
part("Strobe", V(0.5, 0.5, 0.5), C(0, 12.45, 18.0), STROBE, BALL)

---------------------------------------------------------------------------
-- Wheels
---------------------------------------------------------------------------
for _, s in SIDES do
	-- Front single
	part("FrontTire", V(1.1, 4.2, 4.2), C(s * 4.15, 2.1, -18.6), TIRE, CYL)
	part("FrontRim", V(0.1, 2.5, 2.5), C(s * 4.73, 2.1, -18.6), RIM, CYL)
	part("FrontHub", V(0.3, 1.1, 1.1), C(s * 4.92, 2.1, -18.6), HUB, CYL)
	part("FrontHubCap", V(0.1, 0.6, 0.6), C(s * 5.1, 2.1, -18.6), CHROME, CYL)
	-- Rear duals
	part("RearTireOuter", V(1.1, 4.2, 4.2), C(s * 4.15, 2.1, 6.4), TIRE, CYL)
	part("RearTireInner", V(1.1, 4.2, 4.2), C(s * 2.95, 2.1, 6.4), TIRE, CYL)
	part("RearRim", V(0.1, 2.5, 2.5), C(s * 4.75, 2.1, 6.4), RIM, CYL)
	part("RearHub", V(0.4, 1.2, 1.2), C(s * 4.95, 2.1, 6.4), HUB, CYL)
	part("RearHubCap", V(0.15, 0.7, 0.7), C(s * 5.2, 2.1, 6.4), CHROME, CYL)
	-- Mudflaps
	part("RearMudflap", V(1.2, 1.6, 0.08), C(s * 4.15, 1.5, 9.2), TRIM)
	part("FrontMudflap", V(1.0, 1.2, 0.08), C(s * 4.15, 2.0, -16.3), TRIM)
end

---------------------------------------------------------------------------
-- Interior
---------------------------------------------------------------------------
for r = 0, 7 do
	local z = -9.0 + 3.8 * r
	for _, s in SIDES do
		part("BenchCushion", V(3.6, 0.5, 1.7), C(s * 2.85, 5.45, z), VINYL)
		part("BenchBack", V(3.6, 2.6, 0.4), C(s * 2.85, 7.0, z + 0.85), VINYL)
	end
end
part("DriverCushion", V(1.8, 0.5, 1.8), C(-2.6, 5.65, -13.0), VINYL)
part("DriverBack", V(1.8, 2.8, 0.4), C(-2.6, 7.3, -12.2), VINYL)
part("DriverPedestal", V(0.8, 1.4, 0.8), C(-2.6, 4.7, -13.0), TRIM)
part("Dash", V(4.6, 0.8, 0.6), C(-2.3, 7.4, -15.8), DASH)
part("Cluster", V(1.6, 0.5, 0.06), C(-2.6, 7.45, -15.48), TRIM)
part(
	"SteeringWheel",
	V(0.12, 2.0, 2.0),
	C(-2.6, 7.9, -14.6) * A(math.rad(30), 0, 0) * CYLINDER_Y,
	WHEEL_BLACK,
	CYL
)
part(
	"SteeringColumn",
	V(1.0, 0.3, 0.3),
	C(-2.6, 7.4, -15.05) * A(math.rad(30), 0, 0) * CYLINDER_Y,
	WHEEL_BLACK,
	CYL
)
part("SwitchPanel", V(0.8, 0.6, 2.0), C(-4.2, 6.6, -13.6), TRIM)
part("StudentMirror", V(3.0, 0.5, 0.1), C(-1.0, 10.2, -15.35), TRIM)
part("BarrierL", V(3.7, 3.4, 0.15), C(-2.85, 5.7, -11.8), VINYL)
part("BarrierR", V(3.7, 3.4, 0.15), C(2.85, 5.7, -11.8), VINYL)
part("Step1", V(1.4, 0.2, 2.9), C(4.1, 2.5, -14.3), FLOOR)
part("Riser1", V(0.1, 0.8, 2.9), C(3.4, 3.0, -14.3), FLOOR)
part("Step2", V(1.0, 0.2, 2.9), C(2.9, 3.3, -14.3), FLOOR)
part("Riser2", V(0.1, 0.6, 2.9), C(2.4, 3.7, -14.3), FLOOR)
part("Handrail", V(3.0, 0.1, 0.1), C(3.6, 6.0, -12.95) * CYLINDER_Y, CHROME, CYL)

---------------------------------------------------------------------------
-- Details
---------------------------------------------------------------------------
-- Crossing arm, folded along the right half of the front bumper
part("CrossArmHinge", V(0.5, 0.8, 0.4), C(4.3, 2.3, -22.4), TRIM)
part("CrossArmRod", V(3.4, 0.14, 0.14), C(2.6, 2.0, -22.45), YELLOW, CYL)
part("CrossArmRod", V(3.4, 0.14, 0.14), C(2.6, 2.6, -22.45), YELLOW, CYL)
part("CrossArmEnd", V(0.74, 0.14, 0.14), C(0.9, 2.3, -22.45) * CYLINDER_Y, YELLOW, CYL)

-- Stop arm, folded flat against the left side
-- An octagon of width w is the union of four w x w*tan(22.5) strips at 45 degree steps.
local OCT_RATIO = math.tan(math.rad(22.5)) * 2
part("StopArmBracket", V(0.15, 0.4, 0.5), C(-5.0, 6.0, -11.6), TRIM)
for k = 0, 3 do
	local spin = A(math.rad(45 * k), 0, 0)
	part("StopArmWhite", V(0.05, 2.0 * OCT_RATIO / 2, 2.0), C(-5.12, 6.0, -10.4) * spin, PLATE)
	part("StopArmRed", V(0.05, 1.8 * OCT_RATIO / 2, 1.8), C(-5.17, 6.0, -10.4) * spin, STOP_RED)
end
part("StopArmLamp", V(0.06, 0.35, 0.35), C(-5.22, 6.62, -10.4), RED_NEON, CYL)
part("StopArmLamp", V(0.06, 0.35, 0.35), C(-5.22, 5.38, -10.4), RED_NEON, CYL)

-- Mirrors, wipers
for _, s in SIDES do
	part("MirrorArmUp", V(0.9, 0.12, 0.12), C(s * 5.35, 9.7, -16.4), TRIM, CYL)
	part("MirrorArmLo", V(0.9, 0.12, 0.12), C(s * 5.35, 7.5, -16.4), TRIM, CYL)
	part("MirrorHead", V(0.2, 2.4, 0.8), C(s * 5.85, 8.6, -16.6), TRIM)
	part("ConvexBall", V(0.6, 0.6, 0.6), C(s * 5.85, 7.0, -16.6), TRIM, BALL)
	part("CrossviewStalk", V(1.8, 0.12, 0.12), C(s * 4.4, 7.3, -20.6) * CYLINDER_Y, TRIM, CYL)
	part("CrossviewBall", V(1.0, 1.0, 1.0), C(s * 4.5, 8.5, -20.7), TRIM, BALL)
	part("Wiper", V(1.8, 0.06, 0.1), C(s * 2.2, 8.0, -16.22) * WS * A(0, 0, math.rad(s * 15)), TRIM)
end

-- Roof hatches
part("RoofHatch", V(2.4, 0.2, 2.4), C(0, 12.3, -4), HATCH)
part("RoofHatch", V(2.4, 0.2, 2.4), C(0, 12.3, 10), HATCH)

-- Chassis
for _, s in SIDES do
	part("FrameRail", V(0.4, 0.9, 40), C(s * 1.7, 2.75, 0), CHASSIS)
end
part("FrontAxle", V(7.0, 0.4, 0.4), C(0, 2.1, -18.6), CHASSIS)
part("RearAxle", V(5.0, 0.7, 0.7), C(0, 2.1, 6.4), CHASSIS, CYL)
part("Diff", V(1.4, 1.4, 1.4), C(0, 2.1, 6.4), CHASSIS, BALL)
part("Driveshaft", V(17.7, 0.35, 0.35), C(0, 2.2, -3.15) * CYLINDER_Z, CHASSIS, CYL)
part("FuelTank", V(2.0, 1.2, 3.0), C(3.4, 3.0, -4.0), CHASSIS)
part("Muffler", V(3.0, 0.9, 0.9), C(-3.0, 2.6, -1.0) * CYLINDER_Z, CHASSIS, CYL)
part("Tailpipe", V(12.0, 0.35, 0.35), C(-3.4, 1.5, 15.6) * CYLINDER_Z, EXHAUST, CYL)

return {
	name = "School Bus",
	speed = 70,
	turnRate = 1.5,
	footprint = Vector2.new(9.6, 44),
	collision = {
		{ size = Vector3.new(9.8, 10.6, 38.2), offset = CFrame.new(0, 6.9, 2.9) }, -- body: y 1.6..12.2, z -16.2..22.0
		{ size = Vector3.new(9.8, 5.4, 6.0), offset = CFrame.new(0, 4.3, -19.2) }, -- hood: y 1.6..7.0, z -22.2..-16.2
	},
	seats = {
		CFrame.new(-2.6, 5.4, -13.0), -- driver (LHD), seat top 5.9
		CFrame.new(-2.8, 5.2, -9.0),
		CFrame.new(2.8, 5.2, -9.0),
		CFrame.new(-2.8, 5.2, -5.2),
		CFrame.new(2.8, 5.2, -5.2),
		CFrame.new(-2.8, 5.2, -1.4),
		CFrame.new(2.8, 5.2, -1.4),
		CFrame.new(2.8, 5.2, 2.4),
	},
	pieces = pieces,
}
