-- Titan Mech: two-legged industrial walker with a cab in the chest, a back ladder and a deck hatch.
-- Scale: 4 studs = 1 m. Rest pose = parked pose (knees bent). Hip pivots y 20, deck y 40, cab
-- cavity x -5.5..5.5, y 26.5..38.5, z -6..5.5 (only `In*` pieces inside it). The cavity is the
-- walkable cab: the torso's collision is a hollow shell around it.
--
-- Rig: every piece belongs to one bone (or the skid when `bone` is nil). Leg pieces are authored in
-- their bone's bind frame (thigh tilted 25 degrees forward, shin 25 degrees back, foot flat) so they
-- clear their neighbors through the gait's joint ranges.

local rgb = Color3.fromRGB
local M = Enum.Material
local A = CFrame.Angles
local C = CFrame.new
local V = Vector3.new
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball
local rad = math.rad
local CYLINDER_Y = A(0, 0, rad(90)) -- cylinder axis along Y
local CYLINDER_Z = A(0, rad(90), 0) -- cylinder axis along Z

-- Wedge orientations (WedgePart default: slope rises from the -Z bottom edge to the +Z top edge).
local DOWN_FRONT = A(0, 0, math.pi) -- full top and back faces, slope faces down and forward
local UP_BACK = A(0, math.pi, 0) -- slope rises toward -Z, faces up and back
local SIDE_L = A(0, math.pi / 2, 0) -- length along Z, slope falls toward -X
local SIDE_R = A(0, -math.pi / 2, 0) -- length along Z, slope falls toward +X

-- Palette: { color, material, reflectance, transparency }.
local ARMOR = { rgb(96, 102, 108), M.Metal }
local FRAME = { rgb(46, 48, 52), M.Metal }
local YELLOW = { rgb(232, 172, 32), M.Metal }
local HAZARD = { rgb(25, 25, 25), M.SmoothPlastic }
local CHROME = { rgb(188, 192, 198), M.Metal, 0.3 }
local GLASS = { rgb(150, 200, 220), M.Glass, 0.15, 0.7 }
local SCREEN = { rgb(80, 220, 255), M.Neon }
local BUTTON = { rgb(255, 130, 40), M.Neon }
local LAMP = { rgb(255, 240, 210), M.Neon }
local SEAT = { rgb(60, 40, 30), M.Fabric }
local FLOOR = { rgb(46, 48, 52), M.DiamondPlate }

local pieces = {}

local function part(bone, name, size, offset, style, shape, class)
	table.insert(pieces, {
		name = name,
		bone = bone,
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

local function cyl(bone, name, size, offset, style)
	part(bone, name, size, offset, style, CYL)
end

local function ball(bone, name, size, offset, style)
	part(bone, name, size, offset, style, BALL)
end

local function wedge(bone, name, size, offset, style)
	part(bone, name, size, offset, style, nil, "WedgePart")
end

-- Legs ----------------------------------------------------------------------------------------
-- Bind: thigh +25 degrees from vertical (knee forward), shin -25, foot flat.
local BEND = rad(25)
local HIP_Y, HIP_Z, HIP_X = 20, 0.4, 7
local THIGH, SHIN = 10, 9

for side = -1, 1, 2 do
	local s = side < 0 and "_L" or "_R"
	local x = side * HIP_X
	local thigh, shin, foot = "thigh" .. s, "shin" .. s, "foot" .. s
	local thighF = C(x, HIP_Y, HIP_Z) * A(BEND, 0, 0)
	local knee = (thighF * C(0, -THIGH, 0)).Position
	local shinF = C(knee) * A(-BEND, 0, 0)
	local ankle = (shinF * C(0, -SHIN, 0)).Position

	-- Thigh (local -Y runs down the thigh to the knee, -Z is its front face).
	cyl(thigh, "HipJoint" .. s, V(4.2, 4.4, 4.4), thighF, FRAME)
	cyl(thigh, "HipHub" .. s, V(0.5, 3, 3), thighF * C(side * 2.35, 0, 0), CHROME)
	part(thigh, "ThighCore" .. s, V(3.4, 5.6, 4), thighF * C(0, -4.6, 0.1), FRAME)
	part(thigh, "ThighPlate" .. s, V(4, 6, 0.8), thighF * C(0, -4.8, -2.3), YELLOW)
	for k = -1, 1 do
		part(
			thigh,
			"ThighStripe" .. s,
			V(0.5, 2, 0.1),
			thighF * C(k * 1.3, -6.6, -2.75) * A(0, 0, rad(40)),
			HAZARD
		)
	end
	-- Side plates run past the knee as a fork around the knee joint.
	for _, f in { -1, 1 } do
		part(thigh, "ThighFork" .. s, V(0.4, 8.2, 4), thighF * C(f * 1.85, -5.9, 0), ARMOR)
		cyl(thigh, "ThighForkDisc" .. s, V(0.4, 4, 4), C(knee) * C(f * 1.85, 0, 0), ARMOR)
	end
	part(thigh, "ThighPistonMount" .. s, V(1.6, 1, 1.4), thighF * C(0, -1.9, 2.4), FRAME)
	cyl(thigh, "ThighPiston" .. s, V(2.8, 1.3, 1.3), thighF * C(0, -3.4, 2.5) * CYLINDER_Y, FRAME)
	cyl(
		thigh,
		"ThighPistonRod" .. s,
		V(2.2, 0.6, 0.6),
		thighF * C(0, -5.8, 2.5) * CYLINDER_Y,
		CHROME
	)
	part(thigh, "ThighPistonEnd" .. s, V(1, 0.6, 1), thighF * C(0, -6.9, 2.5), FRAME)

	-- Shin (local -Y runs down to the ankle; -Z is its front, facing down-forward).
	cyl(shin, "Knee" .. s, V(3.2, 3.6, 3.6), C(knee), FRAME)
	part(shin, "KneeCap" .. s, V(3.4, 3, 1.4), C(knee) * C(0, 0.4, -2.4), YELLOW)
	for k = -1, 1, 2 do
		part(
			shin,
			"KneeStripe" .. s,
			V(0.5, 2, 0.1),
			C(knee) * C(k * 0.8, 0.4, -3.15) * A(0, 0, rad(40)),
			HAZARD
		)
	end
	part(shin, "ShinLug" .. s, V(3, 2.6, 3), shinF * C(0, -2.2, 0), FRAME)
	part(shin, "Shin" .. s, V(4.2, 3.6, 5.2), shinF * C(0, -4.6, 0), ARMOR)
	part(shin, "ShinPlate" .. s, V(3.6, 2.6, 0.5), shinF * C(0, -4.1, -2.85), ARMOR)
	part(shin, "ShinRib" .. s, V(0.8, 2.2, 0.3), shinF * C(0, -4.1, -3.2), FRAME)
	part(shin, "Calf" .. s, V(3, 3, 1), shinF * C(0, -5.1, 3.1), FRAME)
	cyl(shin, "CalfPiston" .. s, V(2.4, 1, 1), shinF * C(0, -5.6, 3.9) * CYLINDER_Y, FRAME)
	cyl(shin, "CalfRod" .. s, V(1.4, 0.5, 0.5), shinF * C(0, -7.4, 3.9) * CYLINDER_Y, CHROME)
	cyl(shin, "AnkleStem" .. s, V(2.8, 1.5, 1.5), shinF * C(0, -7.6, 0) * CYLINDER_Y, FRAME)

	-- Foot (axis-aligned; ankle ball in a cradle, flat sole on the ground).
	ball(foot, "Ankle" .. s, V(2.6, 2.6, 2.6), C(ankle), FRAME)
	for _, f in { -1, 1 } do
		part(foot, "AnkleCradle" .. s, V(0.5, 2.4, 3), C(x + f * 1.6, 2.2, ankle.Z), ARMOR)
	end
	part(foot, "Sole" .. s, V(6.4, 0.5, 13.6), C(x, 0.25, -1.4), FRAME)
	part(foot, "Foot" .. s, V(5.6, 1.1, 8.4), C(x, 1.05, -0.6), ARMOR)
	for k = -1, 1 do
		wedge(foot, "Toe" .. s, V(1.7, 0.9, 3.4), C(x + k * 1.95, 0.95, -6.5), FRAME)
		part(foot, "ToeCap" .. s, V(1.7, 0.4, 0.5), C(x + k * 1.95, 0.7, -8.0), YELLOW)
	end
	part(foot, "Heel" .. s, V(4.6, 1.4, 2.2), C(x, 1.2, 4.5), FRAME)
	wedge(foot, "HeelSpur" .. s, V(3, 1, 1.6), C(x, 1, 6.4) * UP_BACK, ARMOR)
	for _, f in { -1, 1 } do
		part(foot, "FootGuard" .. s, V(0.4, 1.2, 6), C(x + f * 3, 1.1, -1), ARMOR)
	end
end

-- Pelvis --------------------------------------------------------------------------------------
part("pelvis", "Pelvis", V(8, 3.8, 7.6), C(0, 20.3, 0.4), FRAME)
part("pelvis", "PelvisTop", V(8.6, 0.6, 8.2), C(0, 22.5, 0.4), ARMOR)
cyl("pelvis", "WaistBearing", V(0.3, 5.2, 5.2), C(0, 22.95, 0.4) * CYLINDER_Y, CHROME)
for side = -1, 1, 2 do
	cyl("pelvis", "HipHousing", V(0.7, 4.8, 4.8), C(side * 4.05, 20, 0.4), ARMOR)
end
part("pelvis", "Codpiece", V(5, 3.2, 1.2), C(0, 20, -4), YELLOW)
for k = -1, 1 do
	part("pelvis", "CodStripe", V(0.5, 2, 0.1), C(k * 1.4, 20, -4.65) * A(0, 0, rad(40)), HAZARD)
end
wedge("pelvis", "CodpieceChin", V(5, 1.2, 1.2), C(0, 17.8, -4) * DOWN_FRONT, YELLOW)
part("pelvis", "PelvisBelly", V(5, 0.8, 5), C(0, 18.1, 0.4), ARMOR)
part("pelvis", "LadderReceiver", V(2.4, 1.4, 0.6), C(0, 19, 4.5), FRAME)

-- Torso shell ---------------------------------------------------------------------------------
-- Every wall the pilot can see is the inward face of its own plate (Roblox draws no back faces).
local T = "torso"
cyl(T, "WaistRing", V(1, 7, 7), C(0, 24, 0.4) * CYLINDER_Y, CHROME)
part(T, "TorsoLower", V(16, 2.4, 11.4), C(0, 25, 0.3), ARMOR)
part(T, "Belly", V(12, 0.5, 9), C(0, 23.6, 0.6), FRAME)
wedge(T, "LowerBevel", V(16, 2.6, 1), C(0, 25.1, -5.9) * DOWN_FRONT, ARMOR)
wedge(T, "BevelL", V(11.4, 2.4, 1), C(-8.5, 25, 0.3) * DOWN_FRONT * SIDE_R, ARMOR)
wedge(T, "BevelR", V(11.4, 2.4, 1), C(8.5, 25, 0.3) * DOWN_FRONT * SIDE_L, ARMOR)
part(T, "CabFloor", V(11, 0.5, 11.5), C(0, 26.25, -0.25), FLOOR)
for side = -1, 1, 2 do
	part(T, "Wall", V(3.5, 12.3, 13), C(side * 7.25, 32.35, 0), ARMOR)
	part(T, "WallPanel", V(0.5, 7, 9), C(side * 9.25, 30.5, -0.5), ARMOR)
	for k = 0, 1 do
		part(T, "WallVent", V(0.2, 0.4, 6), C(side * 9.6, 29 + k * 1.2, -0.5), FRAME)
	end
	part(T, "WallRib", V(0.4, 7.4, 0.6), C(side * 9.3, 30.5, -5.3), FRAME)
	cyl(T, "ShoulderAxle", V(0.8, 1.6, 1.6), C(side * 9.1, 36, 0), FRAME)
end
part(T, "BackWall", V(11, 12.3, 0.5), C(0, 32.35, 5.75), ARMOR)
for side = -1, 1, 2 do
	part(T, "BackArmor", V(2.5, 12.3, 0.5), C(side * 4.25, 32.35, 6.25), ARMOR)
end
part(T, "RoofFront", V(18, 1.5, 7), C(0, 39.25, -3), ARMOR)
-- The roof's back edge steps in 0.5 over the ladder top so a backward lean clears the truss.
part(T, "RoofBack", V(18, 1.5, 1.5), C(0, 39.25, 5.25), ARMOR)
for side = -1, 1, 2 do
	part(T, "RoofBackCorner", V(7.4, 1.5, 0.5), C(side * 5.3, 39.25, 6.25), ARMOR)
end
for side = -1, 1, 2 do
	part(T, "RoofSide", V(7, 1.5, 4), C(side * 5.5, 39.25, 2.5), ARMOR)
end
wedge(T, "RoofChamfer", V(18, 1.5, 1.2), C(0, 39.25, -7.1), ARMOR)

-- Face: brow, window frame, sill, chin window, cheeks, headlights.
part(T, "Brow", V(11.2, 1, 1.4), C(0, 38, -6.7), YELLOW)
for k = -1, 1 do
	part(T, "BrowStripe", V(0.5, 1.2, 0.1), C(k * 3, 38, -7.45) * A(0, 0, rad(40)), HAZARD)
end
part(T, "Window", V(11, 6.5, 0.2), C(0, 34.25, -6.4), GLASS)
part(T, "ChinWindow", V(5, 4, 0.2), C(0, 28.5, -6.4), GLASS)
for side = -1, 1, 2 do
	part(T, "WindowFrame", V(0.8, 7.5, 1.2), C(side * 5.6, 34.25, -6.5), FRAME)
	part(T, "ChinFrame", V(0.4, 3.7, 1), C(side * 2.6, 28.35, -6.95), FRAME)
	part(T, "Chin", V(3, 3.7, 0.9), C(side * 4, 28.35, -6.95), ARMOR)
	part(T, "Cheek", V(3.4, 9.9, 0.9), C(side * 7.35, 31.45, -6.95), ARMOR)
	part(T, "CheekBand", V(3.4, 1.2, 0.1), C(side * 7.35, 27.3, -7.45), YELLOW)
	for k = -1, 1, 2 do
		part(
			T,
			"CheekStripe",
			V(0.4, 1.4, 0.1),
			C(side * 7.35 + k * 0.85, 27.3, -7.52) * A(0, 0, rad(40)),
			HAZARD
		)
	end
	part(T, "CheekRib", V(0.5, 9.9, 0.4), C(side * 8.85, 31.45, -7.5), FRAME)
	part(T, "HeadlightHousing", V(2.6, 1.8, 0.8), C(side * 7.3, 37.5, -6.9), FRAME)
	part(T, "Headlight", V(2, 1, 0.2), C(side * 7.3, 37.5, -7.35), LAMP)
end
part(T, "Sill", V(12, 0.8, 1.2), C(0, 30.6, -6.9), FRAME)

-- Deck: hatch rim, walkway, hazard edge, handrails at the ladder top, antenna.
part(T, "HatchRimFront", V(5, 0.3, 0.5), C(0, 40.1, 0.25), FRAME)
part(T, "HatchRimBack", V(5, 0.3, 0.5), C(0, 40.1, 4.75), FRAME)
for side = -1, 1, 2 do
	part(T, "HatchRimSide", V(0.5, 0.3, 4), C(side * 2.25, 40.1, 2.5), FRAME)
end
part(T, "Walkway", V(4, 0.1, 0.9), C(0, 40.05, 5.05), FLOOR)
part(T, "DeckEdge", V(6, 0.12, 0.4), C(0, 40.06, 5.75), YELLOW)
for k = -1, 1 do
	part(T, "DeckEdgeStripe", V(0.4, 0.14, 0.4), C(k * 2, 40.07, 5.75), HAZARD)
end
for side = -1, 1, 2 do
	part(T, "DeckVent", V(3, 0.2, 2.4), C(side * 5.5, 40.1, -3), FRAME)
	part(T, "RailPost", V(0.3, 2.6, 0.3), C(side * 2.4, 41.3, 6.2), YELLOW)
	part(T, "Rail", V(0.3, 0.3, 2.4), C(side * 2.4, 42.45, 5.15), YELLOW)
end
part(T, "AntennaBase", V(1, 0.6, 1), C(-8.2, 40.3, 5.6), FRAME)
cyl(T, "Antenna", V(5.4, 0.25, 0.25), C(-8.2, 43.3, 5.6) * CYLINDER_Y, FRAME)
ball(T, "AntennaTip", V(0.45, 0.45, 0.45), C(-8.2, 45.8, 5.6), BUTTON)

-- Reactor pack: two pods with the ladder channel between them (x -3..3), stacks above.
for side = -1, 1, 2 do
	local px = side * 5.75
	part(T, "Pod", V(5.5, 10.6, 2.1), C(px, 31.5, 7.55), FRAME)
	part(T, "PodCover", V(5.1, 9.6, 0.4), C(px, 31.3, 8.8), ARMOR)
	part(T, "PodBand", V(5.1, 1.2, 0.1), C(px, 34.6, 9.05), YELLOW)
	for k = -1, 1 do
		part(
			T,
			"PodStripe",
			V(0.4, 1.4, 0.1),
			C(px + k * 1.5, 34.6, 9.12) * A(0, 0, rad(40)),
			HAZARD
		)
	end
	for k = 0, 1 do
		part(T, "PodGrille", V(4, 0.3, 0.1), C(px, 28.4 + k * 0.9, 9.05), FRAME)
	end
	for k = 0, 1 do
		part(T, "PodFin", V(0.3, 0.6, 2), C(side * (3.8 + k * 0.9), 37.1, 7.55), FRAME)
	end
	ball(T, "PodLamp", V(0.6, 0.6, 0.6), C(side * 8.1, 37.1, 8.2), BUTTON)
	cyl(T, "StackCollar", V(0.6, 2.1, 2.1), C(side * 6.5, 37.1, 7.8) * CYLINDER_Y, FRAME)
	cyl(T, "Stack", V(5.4, 1.6, 1.6), C(side * 6.5, 40.1, 7.8) * CYLINDER_Y, FRAME)
	cyl(T, "StackTip", V(0.4, 1.9, 1.9), C(side * 6.5, 42.8, 7.8) * CYLINDER_Y, CHROME)
end

-- Hatch -------------------------------------------------------------------------------------
-- Hinged at its front edge (z 0.5); opens -100 degrees about X.
part("hatch", "HatchLid", V(4, 0.5, 4), C(0, 40.25, 2.5), YELLOW)
part("hatch", "HatchPlate", V(3.2, 0.1, 3.2), C(0, 40.55, 2.5), FLOOR)
part("hatch", "HatchHandle", V(1.6, 0.3, 0.3), C(0, 40.7, 4.1), FRAME)
for side = -1, 1, 2 do
	cyl("hatch", "HatchHinge", V(0.8, 0.6, 0.6), C(side * 1.2, 40.5, 0.5), FRAME)
end

-- Cab interior --------------------------------------------------------------------------------
-- Seat block (invisible) at (0, 30.5, 3); the pilot's eye is near (0, 34.3, 3.2).
local IN = "torso"
part(IN, "InSeatPost", V(1.2, 3.5, 1.2), C(0, 28.25, 3.2), FRAME)
part(IN, "InSeatPan", V(2.8, 0.4, 2.8), C(0, 30.2, 3), FRAME)
part(IN, "InSeatCushion", V(2.6, 0.6, 2.4), C(0, 30.7, 3), SEAT)
part(IN, "InSeatBack", V(2.6, 4.4, 0.6), C(0, 33.3, 4.3) * A(rad(8), 0, 0), SEAT)
part(IN, "InHeadrest", V(1.8, 1.2, 0.6), C(0, 36.2, 4.75) * A(rad(8), 0, 0), SEAT)
part(IN, "InSeatFrame", V(2.8, 5, 0.3), C(0, 33.4, 4.75) * A(rad(8), 0, 0), FRAME)
for side = -1, 1, 2 do
	part(IN, "InArmrest", V(0.4, 0.4, 2.2), C(side * 1.5, 32, 2.8), FRAME)
	part(IN, "InDash", V(3, 1.4, 2.2), C(side * 3.8, 31.2, -4.6), FRAME)
	part(IN, "InScreen", V(2.4, 1.4, 0.2), C(side * 3.8, 32.4, -5.2) * A(rad(-20), 0, 0), SCREEN)
	part(IN, "InDashButtons", V(2, 0.15, 0.5), C(side * 3.8, 31.95, -3.9), BUTTON)
	part(IN, "InConsole", V(1.8, 3.4, 4.6), C(side * 4.5, 28.2, 1.4), FRAME)
	part(IN, "InConsoleScreen", V(1.2, 0.1, 1.4), C(side * 4.5, 29.95, 0.2), SCREEN)
	part(IN, "InConsoleButton", V(0.6, 0.15, 0.35), C(side * 4.5, 29.95, 2.4), BUTTON)
	part(IN, "InStickPod", V(1.4, 0.5, 1.4), C(side * 2.9, 30, 1.5), FRAME)
	part(IN, "InStick", V(0.3, 1.6, 0.3), C(side * 2.5, 31, 1.5), FRAME)
	part(IN, "InGrip", V(0.5, 0.9, 0.5), C(side * 2.5, 32.2, 1.5), HAZARD)
	part(IN, "InWallLining", V(0.1, 11.8, 11.3), C(side * 5.45, 32.5, -0.2), FRAME)
end
part(IN, "InBackLining", V(10.8, 11.8, 0.1), C(0, 32.5, 5.45), FRAME)
part(IN, "InLampBar", V(6, 0.3, 0.6), C(0, 38.35, -1.5), LAMP)
part(IN, "InOverhead", V(4, 0.5, 2.4), C(0, 38.25, -4.4), FRAME)
for k = -1, 1 do
	part(IN, "InSwitch", V(0.3, 0.12, 0.3), C(k * 1, 37.95, -4.4), BUTTON)
end

-- Arms (decorative) ---------------------------------------------------------------------------
-- Pivots at x +-11; everything on an arm stays outside x +-9 (torso) and +-10 (legs swinging).
for side = -1, 1, 2 do
	local s = side < 0 and "_L" or "_R"
	local upper, fore = "upperArm" .. s, "foreArm" .. s
	local ax = side * 11
	local outer = side > 0 and SIDE_R or SIDE_L

	ball(upper, "Shoulder" .. s, V(4, 4, 4), C(ax, 36, 0), FRAME)
	part(upper, "Pauldron" .. s, V(4.6, 3.4, 7.4), C(side * 11.45, 38.9, 0), YELLOW)
	part(upper, "PauldronTop" .. s, V(2.6, 0.6, 7.4), C(side * 10.45, 40.9, 0), YELLOW)
	wedge(upper, "PauldronBevel" .. s, V(7.4, 1.2, 2), C(side * 12.75, 41.2, 0) * outer, YELLOW)
	part(upper, "PauldronTrim" .. s, V(4.8, 0.5, 7.6), C(side * 11.45, 37.25, 0), FRAME)
	for k = -1, 1 do
		part(
			upper,
			"PauldronStripe" .. s,
			V(0.1, 2.2, 0.6),
			C(side * 13.78, 38.9, k * 2.2) * A(rad(40), 0, 0),
			HAZARD
		)
	end
	part(upper, "UpperArm" .. s, V(3.4, 6.4, 3.6), C(side * 11.5, 31, 0), ARMOR)
	part(upper, "UpperArmPlate" .. s, V(0.4, 5, 3), C(side * 13.4, 31, 0), FRAME)
	part(upper, "BicepsMount" .. s, V(1.4, 0.8, 1.2), C(side * 11.5, 34.1, -2.2), FRAME)
	cyl(upper, "Biceps" .. s, V(3.4, 1.1, 1.1), C(side * 11.5, 32.2, -2.4) * CYLINDER_Y, FRAME)
	cyl(
		upper,
		"BicepsRod" .. s,
		V(2.6, 0.55, 0.55),
		C(side * 11.5, 29.2, -2.4) * CYLINDER_Y,
		CHROME
	)

	cyl(fore, "Elbow" .. s, V(3.6, 3.2, 3.2), C(side * 11.6, 27, 0), FRAME)
	part(fore, "Forearm" .. s, V(3.6, 7.6, 4.4), C(side * 12.2, 21.3, -0.3), ARMOR)
	part(fore, "Cuff" .. s, V(3.8, 1, 4.6), C(side * 12.2, 24.2, -0.3), YELLOW)
	part(fore, "ForearmPlate" .. s, V(0.3, 4.6, 3.4), C(side * 14.05, 20.8, -0.3), FRAME)
	part(fore, "Wrist" .. s, V(3.8, 0.8, 4.4), C(side * 12.2, 17.6, -0.3), FRAME)
end

-- Right forearm: rotary cannon, six barrels pointing forward.
do
	local F, cx, cy = "foreArm_R", 12.4, 15.6
	part(F, "CannonHousing", V(3.4, 3.2, 4.2), C(cx, cy, -0.7), FRAME)
	cyl(F, "CannonShroud", V(1.2, 3, 3), C(cx, cy, -3.4) * CYLINDER_Z, ARMOR)
	cyl(F, "CannonSpindle", V(6.6, 0.6, 0.6), C(cx, cy, -7.1) * CYLINDER_Z, CHROME)
	for k = 0, 5 do
		local a = k * math.pi / 3
		cyl(
			F,
			"CannonBarrel",
			V(6, 0.5, 0.5),
			C(cx + math.cos(a) * 0.85, cy + math.sin(a) * 0.85, -6.9) * CYLINDER_Z,
			FRAME
		)
	end
	cyl(F, "CannonClamp", V(0.5, 2.6, 2.6), C(cx, cy, -8.4) * CYLINDER_Z, ARMOR)
	cyl(F, "AmmoDrum", V(3.2, 2.6, 2.6), C(cx, 19.5, 3.4), FRAME)
	cyl(F, "AmmoBand", V(0.4, 2.7, 2.7), C(cx + 1, 19.5, 3.4), YELLOW)
	part(F, "AmmoFeed", V(1, 2.4, 0.8), C(cx, 16.8, 2.4), FRAME)
end

-- Left forearm: three-finger claw (two forward, a thumb behind).
do
	local F, cx = "foreArm_L", -12.2
	cyl(F, "ClawHub", V(1.4, 3.4, 3.4), C(cx, 16.5, -0.3) * CYLINDER_Y, FRAME)
	part(F, "ClawPalm", V(3.4, 1.6, 3.6), C(cx, 15.2, -0.3), ARMOR)
	local fingers = { { -0.7, -1.4, 1 }, { 0.7, -1.4, 1 }, { 0, 1.1, -1 } }
	for _, f in fingers do
		local fx, fz, dir = cx + f[1], f[2] - 0.3, f[3]
		local root = C(fx, 14.4, fz) * A(dir * rad(15), 0, 0)
		part(F, "ClawFinger", V(0.8, 3, 0.9), root * C(0, -1.5, 0), FRAME)
		local tip = root * C(0, -3, 0) * A(-dir * rad(45), 0, 0)
		part(F, "ClawTip", V(0.7, 2.4, 0.8), tip * C(0, -1.2, 0), CHROME)
	end
end

-- Ladder brackets (skid; they hold the TrussPart, which Vehicles builds from `ladders`) -------
-- Each clamp wraps the truss (x -1..1, z 6.5..8.5). The low one reaches forward toward the pelvis;
-- the high one stops at the truss so the back wall can lean back without touching it.
for _, y in { 18, 35 } do
	part(nil, "LadderClampBack", V(2.8, 0.6, 0.4), C(0, y, 8.7), FRAME)
	for side = -1, 1, 2 do
		part(nil, "LadderClamp", V(0.4, 0.6, 2.4), C(side * 1.2, y, 7.5), FRAME)
		if y < 20 then
			part(nil, "LadderStrut", V(0.4, 0.6, 1.4), C(side * 1.2, y, 5.6), FRAME)
		end
	end
end

return {
	name = "Titan Mech",
	speed = 18,
	turnRate = 0.7,
	footprint = Vector2.new(20, 18),
	collision = {
		-- Torso y 23.5..40, x -9..9, z -6.5..6.5, hollow around the cab cavity.
		{ size = V(18, 3, 13), offset = C(0, 25, 0) }, -- floor, top at y 26.5
		{ size = V(18, 1.5, 13), offset = C(0, 39.25, 0) }, -- roof
		{ size = V(3.5, 12, 13), offset = C(-7.25, 32.5, 0) }, -- wall L
		{ size = V(3.5, 12, 13), offset = C(7.25, 32.5, 0) }, -- wall R
		{ size = V(11, 12, 0.5), offset = C(0, 32.5, -6.25) }, -- front (window)
		{ size = V(11, 12, 1), offset = C(0, 32.5, 6) }, -- back
		{ size = V(11, 6, 8), offset = C(0, 20.5, 0.4) }, -- pelvis y 17.5..23.5
		{ size = V(5.75, 11, 2.5), offset = C(-5.625, 31.5, 7.75) }, -- pod L
		{ size = V(5.75, 11, 2.5), offset = C(5.625, 31.5, 7.75) }, -- pod R
	},
	bones = {
		{ name = "pelvis", pivot = V(0, 20, 0.4) },
		{ name = "torso", parent = "pelvis", pivot = V(0, 23.5, 0.4) },
		{ name = "hatch", parent = "torso", pivot = V(0, 40.5, 0.5) },
		{ name = "upperArm_L", parent = "torso", pivot = V(-11, 36, 0) },
		{ name = "foreArm_L", parent = "upperArm_L", pivot = V(-11, 27, 0) },
		{ name = "upperArm_R", parent = "torso", pivot = V(11, 36, 0) },
		{ name = "foreArm_R", parent = "upperArm_R", pivot = V(11, 27, 0) },
		{ name = "thigh_L", parent = "pelvis", pivot = V(-7, 20, 0.4) },
		{ name = "shin_L", parent = "thigh_L", pivot = V(-7, 10.937, -3.826) },
		{ name = "foot_L", parent = "shin_L", pivot = V(-7, 2.780, -0.023) },
		{ name = "thigh_R", parent = "pelvis", pivot = V(7, 20, 0.4) },
		{ name = "shin_R", parent = "thigh_R", pivot = V(7, 10.937, -3.826) },
		{ name = "foot_R", parent = "shin_R", pivot = V(7, 2.780, -0.023) },
	},
	seatBone = "torso",
	ladders = { { base = V(0, 2, 7.5), height = 38 } }, -- y 2..40, between the pods
	prompt = { position = V(0, 41.5, 2.5), reach = 8 }, -- over the hatch
	cab = { center = V(0, 32.5, -0.25), size = V(11, 12, 11.5) },
	exit = C(0, 43, 5.5) * A(0, math.pi, 0), -- on the deck behind the hatch, facing the ladder
	cameraFocus = V(0, 46, 0),
	cockpitCamera = true,
	gait = "mech",
	acceleration = 10,
	braking = 20,
	coasting = 14,
	turnAcceleration = 1.5,
	turnInPlace = true,
	parkingBrake = true,
	uprightTorque = 4,
	stepsOver = true,
	seats = { C(0, 30.5, 3) },
	pieces = pieces,
}
