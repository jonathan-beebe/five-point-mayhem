-- Aurora: a sleek high-tech walker. A glossy white capsule body with a smoked bubble canopy, cyan
-- light seams, a floating halo ring behind it, swept fins, twin thrusters and hover pads; curved,
-- muscled legs on pointed feet, and floating shoulder pods over a blaster arm and a light-shield
-- arm. The capsule is a pod (PodFlight): it detaches from the legs and flies, then flies home and
-- docks. The shoulder pods and arms belong to the pelvis, so they stay with the legs, and so does a
-- saddle on top of the pelvis from which another player can drive the legs while the pod is away.
-- Inside: an arc of glass-topped desk around the seat with digital controls (the LAUNCH button
-- in the middle, slider strips, ring dials, keypads) under a wrap of holo panes.
-- The pod seats three: the pilot up front, two passengers side by side behind.
-- Scale: 4 studs = 1 m. Rest pose = parked pose (knees bent). Hip pivots y 22.5. The pod is
-- authored with its capsule axis at y 31 (radius 6, z -10..17) and cab cavity x -3.5..3.5,
-- y 27..35, z -4..8.5 (only `In*` pieces inside it); POD_FORWARD then moves all of it 2.5 studs
-- forward, so the capsule centers over the hips. The riders see out through the capsule (Roblox
-- draws no back faces) and through the canopy, which the cockpit view hides (hideInCockpit).
--
-- Rig: every piece belongs to one bone. Leg pieces are authored in their bone's bind frame (thigh
-- tilted 25 degrees forward, shin 25 degrees back, foot flat), like OG's.

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

-- Palette: { color, material, reflectance, transparency }.
local WHITE = { rgb(236, 239, 243), M.SmoothPlastic, 0.25 }
local GRAPHITE = { rgb(34, 37, 44), M.SmoothPlastic, 0.15 }
local LIGHT = { rgb(0, 222, 255), M.Neon }
local SHIELD = { rgb(80, 220, 255), M.Neon, 0, 0.55 }
local CANOPY = { rgb(40, 70, 100), M.Glass, 0.3, 0.55 }
local SEAT = { rgb(236, 239, 243), M.SmoothPlastic }
local HOLO = { rgb(0, 222, 255), M.Neon, 0, 0.4 }
local HOLO_FAINT = { rgb(0, 222, 255), M.Neon, 0, 0.7 }
local DESK_GLASS = { rgb(8, 12, 20), M.SmoothPlastic, 0.45 }
local MAGENTA = { rgb(255, 60, 200), M.Neon }
local PALE_LIGHT = { rgb(220, 250, 255), M.Neon }
local DIM_LIGHT = { rgb(0, 110, 140), M.Neon }

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

local function ball(bone, name, diameter, position, style)
	part(bone, name, V(diameter, diameter, diameter), C(position), style, BALL)
end

local function wedge(bone, name, size, offset, style)
	part(bone, name, size, offset, style, nil, "WedgePart")
end

-- An organic tube along a curve: a quadratic Bezier from `a` past control `c` to `b`, as one
-- cylinder per span with a ball at each inner point so the bends stay smooth. `widths` gives the
-- diameter at each point (spans = #widths - 1). Returns the points and a frame at each point with
-- local X along the curve.
local function tube(bone, name, a, c, b, widths, style)
	local spans = #widths - 1
	local points = {}
	for i = 0, spans do
		local t = i / spans
		points[i + 1] = a * (1 - t) ^ 2 + c * (2 * (1 - t) * t) + b * t ^ 2
	end
	local frames = {}
	for i = 1, spans do
		local p, q = points[i], points[i + 1]
		local d = (widths[i] + widths[i + 1]) / 2
		local along = CFrame.lookAt((p + q) / 2, q) * CYLINDER_Z
		cyl(bone, name, V((q - p).Magnitude, d, d), along, style)
		if i > 1 then
			ball(bone, name .. "Joint", widths[i], p, style)
		end
		frames[i] = CFrame.lookAt(p, q) * CYLINDER_Z
	end
	frames[spans + 1] = CFrame.lookAt(points[spans + 1], points[spans + 1] * 2 - points[spans])
		* CYLINDER_Z
	return points, frames
end

-- A light ring around a tube at point `index` of `tube`'s result.
local function band(bone, name, frames, widths, index, style)
	local d = widths[index] + 0.15
	cyl(bone, name, V(0.25, d, d), frames[index], style)
end

-- Collision: a hollow box from `lo` to `hi` around the cab from `inLo` to `inHi`, as six boxes.
local function shell(lo, hi, inLo, inHi)
	local function box(a, b)
		return { size = b - a, offset = C((a + b) / 2) }
	end
	return {
		box(lo, V(hi.X, inLo.Y, hi.Z)), -- floor
		box(V(lo.X, inHi.Y, lo.Z), hi), -- roof
		box(V(lo.X, inLo.Y, lo.Z), V(inLo.X, inHi.Y, hi.Z)), -- left wall
		box(V(inHi.X, inLo.Y, lo.Z), V(hi.X, inHi.Y, hi.Z)), -- right wall
		box(V(inLo.X, inLo.Y, lo.Z), V(inHi.X, inHi.Y, inLo.Z)), -- front
		box(V(inLo.X, inLo.Y, inHi.Z), V(inHi.X, inHi.Y, hi.Z)), -- back
	}
end

-- Legs ----------------------------------------------------------------------------------------
local BEND = rad(25)
local HIP_Y, HIP_Z, HIP_X = 22.5, 0, 6.2
local THIGH, SHIN = 11, 11
local legBones = {}

for side = -1, 1, 2 do
	local s = side < 0 and "_L" or "_R"
	local x = side * HIP_X
	local thigh, shin, foot = "thigh" .. s, "shin" .. s, "foot" .. s
	local thighF = C(x, HIP_Y, HIP_Z) * A(BEND, 0, 0)
	local knee = (thighF * C(0, -THIGH, 0)).Position
	local shinF = C(knee) * A(-BEND, 0, 0)
	local ankle = (shinF * C(0, -SHIN, 0)).Position
	table.insert(legBones, { name = thigh, parent = "pelvis", pivot = V(x, HIP_Y, HIP_Z) })
	table.insert(legBones, { name = shin, parent = thigh, pivot = knee })
	table.insert(legBones, { name = foot, parent = shin, pivot = ankle })

	-- Thigh: a ball hip and a muscled white thigh that swells at the front, a light ring above the
	-- knee.
	ball(thigh, "Hip" .. s, 3.8, thighF.Position, WHITE)
	local thighWidths = { 3.3, 3.8, 3.5, 3, 2.6 }
	local _, thighFrames = tube(
		thigh,
		"Thigh" .. s,
		(thighF * C(0, -1, 0)).Position,
		(thighF * C(0, -5.5, -1.1)).Position,
		(thighF * C(0, -10.4, 0)).Position,
		thighWidths,
		WHITE
	)
	band(thigh, "ThighLight" .. s, thighFrames, thighWidths, 4, LIGHT)

	-- Shin: a graphite knee ball, a white shin with a swelling calf behind, a front blade carrying
	-- a light strip.
	ball(shin, "Knee" .. s, 3, knee, GRAPHITE)
	tube(
		shin,
		"Shin" .. s,
		(shinF * C(0, -0.8, 0)).Position,
		(shinF * C(0, -4.5, 1.2)).Position,
		(shinF * C(0, -9.6, 0)).Position,
		{ 2.6, 3.1, 2.8, 2.3, 2 },
		WHITE
	)
	part(shin, "ShinBlade" .. s, V(1.8, 8, 0.6), shinF * C(0, -5, -1.5), GRAPHITE)
	part(shin, "ShinLight" .. s, V(0.3, 6, 0.1), shinF * C(0, -5, -1.85), LIGHT)
	cyl(shin, "AnkleSleeve" .. s, V(1.4, 2.6, 2.6), shinF * C(0, -9.8, 0) * CYLINDER_Y, GRAPHITE)

	-- Foot: a pointed white shoe with a light line along its nose, on a graphite sole.
	ball(foot, "Ankle" .. s, 2.4, ankle, GRAPHITE)
	part(foot, "Sole" .. s, V(4.4, 0.4, 10), C(x, 0.2, -1.6), GRAPHITE)
	part(foot, "Shoe" .. s, V(4, 1.6, 5.6), C(x, 1.2, -0.6), WHITE)
	wedge(foot, "Nose" .. s, V(4, 1.6, 3.2), C(x, 1.2, -5), WHITE)
	part(foot, "NoseLight" .. s, V(4.05, 0.2, 2.6), C(x, 0.5, -5) * A(rad(-26), 0, 0), LIGHT)
	ball(foot, "Heel" .. s, 2.2, V(x, 1.1, 2.4), GRAPHITE)
end

-- Pelvis --------------------------------------------------------------------------------------
cyl("pelvis", "HipAxle", V(10, 2.6, 2.6), C(0, HIP_Y, HIP_Z), GRAPHITE)
ball("pelvis", "PelvisBall", 6, V(0, 23.2, 0.2), WHITE)
cyl("pelvis", "PelvisLight", V(0.3, 6.1, 6.1), C(0, 23.2, 0.2) * CYLINDER_Y, LIGHT)
-- Saddle on top of the pelvis: the legs seat while the pod is away (inside the capsule when docked).
part("pelvis", "Saddle", V(2.4, 0.5, 2.4), C(0, 26.25, 0.2), GRAPHITE)
part("pelvis", "SaddlePad", V(2, 0.12, 2), C(0, 26.53, 0.2), SEAT)
for side = -1, 1, 2 do
	part("pelvis", "SaddleGrip", V(0.3, 0.6, 1.2), C(side * 1.35, 26.6, -0.2), GRAPHITE)
end

-- Capsule -------------------------------------------------------------------------------------
local T = "torso"
local AXIS_Y, RADIUS = 31, 6
cyl(T, "Capsule", V(15, RADIUS * 2, RADIUS * 2), C(0, AXIS_Y, 3.5) * CYLINDER_Z, WHITE)
ball(T, "Nose", RADIUS * 2, V(0, AXIS_Y, -4), WHITE)
ball(T, "Tail", RADIUS * 2, V(0, AXIS_Y, 11), WHITE)
ball(T, "Canopy", 9.6, V(0, 32.4, -6.6), CANOPY)
pieces[#pieces].hideInCockpit = true -- clear from inside
ball(T, "ChinSensor", 2, V(0, 26.2, -7.4), GRAPHITE)
-- Light seams: a ring around the waist of the capsule and lines along its top and flanks.
for k = 0, 23 do
	local around = C(0, AXIS_Y, 6) * A(0, 0, k * math.pi / 12)
	part(T, "Seam", V(1.6, 0.15, 0.3), around * C(0, RADIUS + 0.02, 0), LIGHT)
end
part(T, "SeamTop", V(0.4, 0.12, 15), C(0, AXIS_Y + RADIUS + 0.02, 3.5), LIGHT)
for side = -1, 1, 2 do
	part(T, "SeamFlank", V(0.12, 0.4, 15), C(side * (RADIUS + 0.02), AXIS_Y, 3.5), LIGHT)
	part(
		T,
		"CanopyTrim",
		V(0.3, 3, 0.3),
		C(side * 4.2, 32.4, -8.6) * A(0, 0, rad(side * 20)),
		LIGHT
	)
end

-- Swept fins and twin thrusters.
for side = -1, 1, 2 do
	wedge(
		T,
		"Fin",
		V(0.5, 3.6, 6.4),
		C(side * 2.6, 37.9, 10.6) * A(0, 0, rad(-side * 12)),
		GRAPHITE
	)
	part(
		T,
		"FinLight",
		V(0.55, 0.2, 4),
		C(side * 2.75, 37.1, 11.2) * A(0, 0, rad(-side * 12)),
		LIGHT
	)
	cyl(T, "Thruster", V(3, 2.6, 2.6), C(side * 3.4, 27, 15.3) * CYLINDER_Z, GRAPHITE)
	cyl(T, "ThrusterLip", V(0.4, 2.9, 2.9), C(side * 3.4, 27, 16.7) * CYLINDER_Z, WHITE)
	ball(T, "ThrusterGlow", 2, V(side * 3.4, 27, 16.6), LIGHT)
end

-- Hover pads under the capsule: graphite rims round glowing cores.
for _, at in { V(0, 25.25, -5.5), V(-2.6, 25.6, 11.5), V(2.6, 25.6, 11.5) } do
	cyl(T, "HoverRim", V(0.25, 2.2, 2.2), C(at) * CYLINDER_Y, GRAPHITE)
	cyl(T, "HoverPad", V(0.3, 1.6, 1.6), C(at - V(0, 0.04, 0)) * CYLINDER_Y, LIGHT)
end

-- Halo: a ring of light floating behind the capsule, with four emitters.
local HALO = C(0, 33, 14.5)
for k = 0, 19 do
	local around = HALO * A(0, 0, k * math.pi / 10)
	part(T, "Halo", V(2.45, 0.5, 0.5), around * C(0, 7.6, 0), LIGHT)
end
for k = 0, 3 do
	local around = HALO * A(0, 0, math.pi / 4 + k * math.pi / 2)
	ball(T, "HaloEmitter", 1.2, (around * C(0, 7.6, 0)).Position, GRAPHITE)
end

-- Cab interior --------------------------------------------------------------------------------
-- Seat block (invisible) at (0, 28.6, 1.3); the pilot's eye is near (0, 32.5, 1.5). Passenger seat
-- blocks at (+-1.6, 28.6, 6.2).
local IN = "torso"
local PASSENGERS = { V(-1.6, 28.6, 6.2), V(1.6, 28.6, 6.2) }
part(IN, "InFloor", V(6.6, 0.3, 12.5), C(0, 27.15, 2.25), GRAPHITE)
for _, at in PASSENGERS do
	part(IN, "InSeatPan", V(2.2, 0.5, 2.2), C(at.X, 27.85, at.Z), GRAPHITE)
	part(IN, "InSeat", V(2.2, 0.5, 2), C(at.X, 28.35, at.Z), SEAT)
	part(IN, "InSeatBack", V(2.2, 3.6, 0.5), C(at.X, 30.4, at.Z + 1.2) * A(rad(12), 0, 0), SEAT)
	part(IN, "InSeatLight", V(2.2, 0.12, 0.1), C(at.X, 28.62, at.Z - 1.02), LIGHT)
end
part(IN, "InSeatPan", V(2.6, 0.5, 2.6), C(0, 27.85, 1.3), GRAPHITE)
part(IN, "InSeat", V(2.6, 0.5, 2.4), C(0, 28.35, 1.3), SEAT)
part(IN, "InSeatBack", V(2.6, 4, 0.5), C(0, 30.6, 2.6) * A(rad(12), 0, 0), SEAT)
for side = -1, 1, 2 do
	part(IN, "InArmrest", V(0.5, 0.4, 2.4), C(side * 1.6, 29.4, 1.1), GRAPHITE)
	ball(IN, "InTouchpad", 0.8, V(side * 1.6, 29.7, 0.1), LIGHT)
end

-- Desk: an arc of seven glass-topped segments around the seat, each tilted toward the pilot, with
-- a light strip along its near edge. DESK[k] is segment k's top surface (k = -3..3, 0 ahead):
-- local X across, -Z toward the pilot, +Y out of the glass.
local SEAT_AT = V(0, 29.6, 1.3)
local DESK_RADIUS, DESK_STEP = 3.3, rad(23)
local DESK = {}
for k = -3, 3 do
	local a = k * DESK_STEP
	local at = SEAT_AT + V(math.sin(a) * DESK_RADIUS, 0, -math.cos(a) * DESK_RADIUS)
	local frame = CFrame.lookAt(at, V(SEAT_AT.X, at.Y, SEAT_AT.Z)) * A(rad(-15), 0, 0)
	local width = 2 * DESK_RADIUS * math.sin(DESK_STEP / 2) + 0.06
	part(IN, "InDesk", V(width, 0.5, 0.9), frame, GRAPHITE)
	part(IN, "InDeskGlass", V(width - 0.1, 0.04, 0.8), frame * C(0, 0.26, 0), DESK_GLASS)
	part(IN, "InDeskEdge", V(width, 0.06, 0.06), frame * C(0, 0.2, -0.47), LIGHT)
	DESK[k] = frame * C(0, 0.28, 0)
	if k % 2 == 0 then
		-- A stem down to the floor under every other segment.
		local stem = V(at.X, (27.3 + at.Y - 0.25) / 2, at.Z)
		cyl(IN, "InDeskStem", V(at.Y - 0.25 - 27.3, 0.5, 0.5), C(stem) * CYLINDER_Y, GRAPHITE)
	end
end

-- The middle segment: the LAUNCH button, a glowing ring round a pearl cap, with a faint holo disc
-- floating over it. PodFlight's prompt sits on it.
local BUTTON = DESK[0]
cyl(IN, "InLaunchRing", V(0.05, 0.95, 0.95), BUTTON * CYLINDER_Y, LIGHT)
cyl(IN, "InLaunchCap", V(0.1, 0.72, 0.72), BUTTON * C(0, 0.04, 0) * CYLINDER_Y, SEAT)
cyl(IN, "InLaunchCore", V(0.12, 0.3, 0.3), BUTTON * C(0, 0.06, 0) * CYLINDER_Y, MAGENTA)
cyl(IN, "InLaunchHolo", V(0.02, 1.3, 1.3), BUTTON * C(0, 0.75, 0) * CYLINDER_Y, HOLO_FAINT)
for side = -1, 1, 2 do
	for j = 1, 3 do
		local height = 0.12 + 0.08 * ((j * 7 + side * 3) % 4)
		part(IN, "InWave", V(0.06, 0.02, height), BUTTON * C(side * (0.55 + j * 0.1), 0, 0), LIGHT)
	end
end

for side = -1, 1, 2 do
	-- Slider strips: three tracks, each with a pale thumb at its own level.
	local sliders = DESK[side]
	for j = -1, 1 do
		part(IN, "InSliderTrack", V(0.05, 0.02, 0.6), sliders * C(j * 0.28, 0, 0), DIM_LIGHT)
		local level = ((j + 2) * (side + 3)) % 5 / 4 - 0.5
		part(
			IN,
			"InSliderThumb",
			V(0.2, 0.05, 0.08),
			sliders * C(j * 0.28, 0.01, level * 0.5),
			PALE_LIGHT
		)
	end

	-- Ring dial: a glowing ring with a needle and four ticks.
	local dial = DESK[side * 2]
	cyl(IN, "InDialRing", V(0.03, 0.7, 0.7), dial * CYLINDER_Y, LIGHT)
	cyl(IN, "InDialFace", V(0.04, 0.56, 0.56), dial * C(0, 0.01, 0) * CYLINDER_Y, DESK_GLASS)
	part(
		IN,
		"InDialNeedle",
		V(0.03, 0.03, 0.24),
		dial * C(0, 0.03, 0) * A(0, rad(side * 40), 0) * C(0, 0, -0.12),
		MAGENTA
	)
	for t = 0, 3 do
		local tick = dial * A(0, t * math.pi / 2, 0) * C(0, 0.02, -0.42)
		part(IN, "InDialTick", V(0.06, 0.02, 0.06), tick, PALE_LIGHT)
	end

	-- Keypad: a 3 x 2 grid of lit keys.
	local keys = DESK[side * 3]
	for row = 0, 1 do
		for column = -1, 1 do
			local lit = (row * 3 + column + side) % 3
			part(
				IN,
				"InKey",
				V(0.22, 0.03, 0.22),
				keys * C(column * 0.3, 0, (row - 0.5) * 0.3),
				if lit == 0 then MAGENTA elseif lit == 1 then LIGHT else DIM_LIGHT
			)
		end
	end
end

-- Holo panes: the main one ahead and two angled at the sides, with readout lines.
part(IN, "InHolo", V(4, 1.6, 0.1), C(0, 31.3, -3.2) * A(rad(-15), 0, 0), HOLO)
for side = -1, 1, 2 do
	local a = side * rad(42)
	local at = V(math.sin(a) * 3.6, 31.4, 1.3 - math.cos(a) * 3.6)
	local pane = CFrame.lookAt(at, V(0, 31.4, 1.3)) * A(rad(-10), 0, 0)
	part(IN, "InHoloSide", V(1.6, 1.1, 0.05), pane, HOLO_FAINT)
	for row, width in { 1.1, 0.7, 0.9 } do
		part(
			IN,
			"InReadout",
			V(width, 0.06, 0.02),
			pane * C((width - 1.1) / 2, 0.45 - row * 0.22, -0.04),
			PALE_LIGHT
		)
	end
end

-- Arms (decorative) ---------------------------------------------------------------------------
-- Shoulder pods float clear of the capsule; the forearms hang below them, clear of the legs.
for side = -1, 1, 2 do
	local s = side < 0 and "_L" or "_R"
	local upper, fore = "upperArm" .. s, "foreArm" .. s
	ball(upper, "ShoulderPod" .. s, 4, V(side * 9.6, 33, 0.5), WHITE)
	cyl(upper, "ShoulderLight" .. s, V(0.3, 4.1, 4.1), C(side * 9.6, 33, 0.5), LIGHT)
	tube(
		upper,
		"UpperArm" .. s,
		V(side * 9.7, 31.4, 0.5),
		V(side * 10.6, 28.5, 0.1),
		V(side * 10, 25.6, 0.5),
		{ 1.7, 2.2, 2, 1.7, 1.6 },
		GRAPHITE
	)

	-- Forearm: a gauntlet that flares out past the elbow and curves forward to the wrist.
	ball(fore, "Elbow" .. s, 2.2, V(side * 10, 25.5, 0.5), GRAPHITE)
	local gauntletWidths = { 2, 3, 3.4, 3.1, 2.6 }
	local _, gauntletFrames = tube(
		fore,
		"Gauntlet" .. s,
		V(side * 10, 24.6, 0.5),
		V(side * 10.6, 21.6, -0.5),
		V(side * 10.2, 18.4, 0),
		gauntletWidths,
		WHITE
	)
	band(fore, "GauntletLight" .. s, gauntletFrames, gauntletWidths, 4, LIGHT)
end
-- Right forearm: a blaster under the gauntlet. Left: a disc of light as a shield.
cyl("foreArm_R", "Blaster", V(5.4, 1.6, 1.6), C(10.2, 18, -1.8) * CYLINDER_Z, GRAPHITE)
cyl("foreArm_R", "BlasterMuzzle", V(0.3, 1.2, 1.2), C(10.2, 18, -4.55) * CYLINDER_Z, LIGHT)
cyl("foreArm_L", "ShieldHub", V(0.6, 2, 2), C(-12.2, 21.6, -0.1), GRAPHITE)
cyl("foreArm_L", "Shield", V(0.2, 7.4, 7.4), C(-12.6, 21.6, -0.1), SHIELD)

local bones = {
	{ name = "pelvis", pivot = V(0, HIP_Y, HIP_Z) },
	{ name = "torso", parent = "pelvis", pivot = V(0, 24.5, 0.5) },
	-- The arms hang from the pelvis, so they stay with the legs when the pod flies.
	{ name = "upperArm_L", parent = "pelvis", pivot = V(-9.5, 33, 0.5) },
	{ name = "foreArm_L", parent = "upperArm_L", pivot = V(-10, 25.5, 0.5) },
	{ name = "upperArm_R", parent = "pelvis", pivot = V(9.5, 33, 0.5) },
	{ name = "foreArm_R", parent = "upperArm_R", pivot = V(10, 25.5, 0.5) },
}
for _, bone in legBones do
	table.insert(bones, bone)
end

-- Everything on the pod moves POD_FORWARD from where it was authored above.
local POD_FORWARD = C(0, 0, -2.5)
for _, piece in pieces do
	if piece.bone == "torso" then
		piece.offset = POD_FORWARD * piece.offset
	end
end
local function forward(position)
	return (POD_FORWARD * C(position)).Position
end

local CAB_LO, CAB_HI = forward(V(-3.5, 27, -4)), forward(V(3.5, 35, 8.5))
local collision = shell(forward(V(-6, 25, -10)), forward(V(6, 37, 17)), CAB_LO, CAB_HI)
for _, box in collision do
	box.bone = "torso" -- the capsule's hull flies with the pod
end
local seats = { C(forward(V(0, 28.6, 1.3))) }
for _, at in PASSENGERS do
	table.insert(seats, C(forward(at)))
end
table.insert(collision, { size = V(10, 3, 5), offset = C(0, 23, 0) }) -- pelvis y 21.5..24.5

return {
	name = "Aurora",
	speed = 30,
	turnRate = 1.1,
	footprint = Vector2.new(18, 18),
	collision = collision,
	bones = bones,
	seatBone = "torso",
	cab = { center = (CAB_LO + CAB_HI) / 2, size = CAB_HI - CAB_LO },
	exit = C(0, 3, 18) * A(0, math.pi, 0), -- on the ground behind, facing away
	cameraFocus = V(0, 38, 0),
	cockpitCamera = true,
	gait = "mech",
	acceleration = 10,
	braking = 28,
	coasting = 18,
	turnAcceleration = 3,
	turnInPlace = true,
	parkingBrake = true,
	uprightTorque = 4,
	stepsOver = true,
	seats = seats,
	pod = {
		bone = "torso",
		button = forward(BUTTON.Position),
		jets = { forward(V(-3.4, 27, 17)), forward(V(3.4, 27, 17)) },
		legsSeat = C(0, 26.1, 0.2), -- seat block top 26.6, on the saddle pad
	},
	pieces = pieces,
}
