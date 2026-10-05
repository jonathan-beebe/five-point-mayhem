-- Rustbucket: an old, rust-eaten brute of a walker. A squat riveted hull with a vision slit
-- between two barred corner windows and a porthole in each flank, a boiler and two crooked
-- smokestacks on its back (they smoke while it walks), patched plates in faded paint, stumpy
-- elephant legs, and huge gorilla arms whose fists hang near the ground. Inside, a steam-age
-- console: brass gauges, valve wheels, toggles, copper pipes and a speaking tube. Slow, and it
-- creaks (SoundCatalog.MECHS.rustbucket), but it shoves like nothing else (`ram`).
-- Scale: 4 studs = 1 m. Rest pose = parked pose (knees bent). Hip pivots y 17.7, hull
-- x -11..11, y 19.5..32.5, z -7..6.5, cab cavity x -9.5..9.5, y 21..29, z -5..3.5 (only `In*`
-- pieces inside it). Windows: y 25.5..28.
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
local RUST = { rgb(140, 72, 38), M.CorrodedMetal }
local RUST_DARK = { rgb(92, 48, 30), M.CorrodedMetal }
local RUST_ORANGE = { rgb(176, 96, 44), M.CorrodedMetal }
local OLD_YELLOW = { rgb(158, 128, 62), M.CorrodedMetal } -- what is left of the paint
local OLD_GREEN = { rgb(92, 104, 80), M.CorrodedMetal }
local IRON = { rgb(58, 52, 48), M.CorrodedMetal }
local SOOT = { rgb(24, 22, 20), M.Slate }
local RIVET = { rgb(70, 50, 40), M.Metal }
local GRIME = { rgb(150, 140, 90), M.Glass, 0.05, 0.55 }
local LAMP = { rgb(255, 196, 110), M.Neon }
local DEAD_LAMP = { rgb(60, 56, 46), M.Glass, 0.1 }
local SEAT = { rgb(86, 60, 40), M.Leather }
local GAUGE = { rgb(220, 210, 170), M.SmoothPlastic }
local BRASS = { rgb(196, 154, 72), M.Metal, 0.25 }
local COPPER = { rgb(172, 98, 60), M.Metal, 0.15 }
local NEEDLE = { rgb(120, 20, 16), M.SmoothPlastic }
local AMBER = { rgb(255, 168, 60), M.Neon }
local RED_LAMP = { rgb(255, 60, 40), M.Neon }

local pieces = {}

local function part(bone, name, size, offset, style, shape)
	table.insert(pieces, {
		name = name,
		bone = bone,
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

-- A plate with a rivet in each corner of its -Z face.
local function plate(bone, name, size, offset, style)
	part(bone, name, size, offset, style)
	for _, x in { -1, 1 } do
		for _, y in { -1, 1 } do
			local at = offset * C(x * (size.X / 2 - 0.45), y * (size.Y / 2 - 0.45), -size.Z / 2)
			ball(bone, "Rivet", 0.5, at.Position, RIVET)
		end
	end
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
local HIP_Y, HIP_Z, HIP_X = 17.7, 0, 6
local THIGH, SHIN = 8, 8
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

	-- Thigh: a fat drum hip, a thick block with a crooked patch, a leaking piston behind.
	cyl(thigh, "HipDrum" .. s, V(4.8, 5.4, 5.4), thighF, IRON)
	part(thigh, "Thigh" .. s, V(5.2, 6.6, 5.2), thighF * C(0, -4, 0), RUST)
	plate(
		thigh,
		"ThighPatch" .. s,
		V(4.4, 3.2, 0.4),
		thighF * C(0, -3.6, -2.7) * A(0, 0, rad(side * 7)),
		OLD_GREEN
	)
	cyl(thigh, "ThighPiston" .. s, V(4.6, 1.4, 1.4), thighF * C(0, -3.8, 3) * CYLINDER_Y, IRON)
	cyl(thigh, "ThighRod" .. s, V(3, 0.6, 0.6), thighF * C(0, -6.6, 3) * CYLINDER_Y, RUST_ORANGE)

	-- Shin: a knee drum under a bent plate, a heavy block with a dent patch, a dangling hose.
	cyl(shin, "Knee" .. s, V(5.6, 4.6, 4.6), C(knee), IRON)
	plate(
		shin,
		"KneePlate" .. s,
		V(5, 3.2, 1.2),
		C(knee) * C(0, 0.6, -2.6) * A(rad(-10), 0, rad(-side * 6)),
		RUST_ORANGE
	)
	part(shin, "Shin" .. s, V(5.8, 5.6, 6), shinF * C(0, -4.4, 0), RUST)
	plate(
		shin,
		"ShinPatch" .. s,
		V(3, 2.6, 0.3),
		shinF * C(side * 0.8, -5, -3.1) * A(0, 0, rad(-12)),
		OLD_YELLOW
	)
	cyl(
		shin,
		"Hose" .. s,
		V(4, 0.7, 0.7),
		shinF * C(side * 3.1, -4.6, 1.4) * A(0, 0, rad(side * 8)) * CYLINDER_Y,
		SOOT
	)

	-- Foot: an elephant slab with blunt riveted toes and a heel block.
	ball(foot, "Ankle" .. s, 3.6, ankle, IRON)
	part(foot, "Sole" .. s, V(9, 1, 12.4), C(x, 0.5, -1), IRON)
	part(foot, "Foot" .. s, V(8, 2.2, 9), C(x, 2.1, -0.6), RUST_DARK)
	for k = -1, 1 do
		plate(foot, "Toe" .. s, V(2.4, 1.8, 2.4), C(x + k * 2.8, 1.5, -6.6), RUST)
	end
	part(foot, "Heel" .. s, V(6, 2, 2.2), C(x, 1.6, 4.6), RUST_DARK)
end

-- Pelvis --------------------------------------------------------------------------------------
part("pelvis", "Pelvis", V(12, 4.4, 8), C(0, 18, 0.2), RUST_DARK)
plate("pelvis", "PelvisPlate", V(7, 3, 0.5), C(0, 17.8, -4) * A(0, 0, rad(3)), RUST)
part("pelvis", "Grease", V(3, 0.2, 2), C(0, 15.75, 1), SOOT)

-- Hull ----------------------------------------------------------------------------------------
-- Walls around the cab: 1.5 thick at the flanks, 2 at the front and back. The front has a vision
-- slit (x -4.5..4.5) between pillars, and a barred window at each corner (x 5.5..9.5); each
-- flank has a porthole just forward of the shoulder (z -5..-3.4). All windows span y 25.5..28.
local T = "torso"
part(T, "HullFloor", V(22, 1.5, 13.5), C(0, 20.25, -0.25), RUST_DARK)
part(T, "HullRoof", V(22, 3.5, 13.5), C(0, 30.75, -0.25), RUST)
part(T, "HullBack", V(19, 8, 3), C(0, 25, 5), RUST_DARK)
part(T, "HullFront", V(19, 4.5, 2), C(0, 23.25, -6), RUST)
part(T, "SlitTop", V(19, 1, 2), C(0, 28.5, -6), RUST)
part(T, "Slit", V(9, 2.6, 0.2), C(0, 26.75, -5.6), GRIME)
part(T, "SlitHood", V(11, 1.2, 2.6), C(0, 29.4, -7) * A(rad(-14), 0, 0), RUST_ORANGE)
for side = -1, 1, 2 do
	part(T, "Pillar", V(1, 2.5, 2), C(side * 5, 26.75, -6), RUST)
	part(T, "CornerWindow", V(4, 2.6, 0.2), C(side * 7.5, 26.75, -5.6), GRIME)
	part(T, "WindowBar", V(0.25, 2.5, 0.25), C(side * 7.5, 26.75, -6.6), IRON)
	part(T, "WindowSill", V(4.4, 0.4, 0.8), C(side * 7.5, 25.4, -7.2), IRON)

	-- Flank wall, built around the porthole.
	local x = side * 10.25
	part(T, "HullSide", V(1.5, 4.5, 13.5), C(x, 23.25, -0.25), RUST)
	part(T, "HullSide", V(1.5, 1, 13.5), C(x, 28.5, -0.25), RUST)
	part(T, "HullSide", V(1.5, 2.5, 2), C(x, 26.75, -6), RUST)
	part(T, "HullSide", V(1.5, 2.5, 9.9), C(x, 26.75, 1.55), RUST)
	part(T, "Porthole", V(0.2, 2.5, 1.6), C(side * 10.6, 26.75, -4.2), GRIME)
	for _, y in { 25.35, 28.15 } do
		part(T, "PortholeFrame", V(0.3, 0.3, 2.2), C(side * 11.1, y, -4.2), BRASS)
	end
	for _, z in { -5.15, -3.25 } do
		part(T, "PortholeFrame", V(0.3, 3.1, 0.3), C(side * 11.1, 26.75, z), BRASS)
	end
end

-- Patched armor on the front and flanks, each a little crooked. The glacis plates stop under the
-- corner windows.
plate(T, "Glacis", V(6.6, 4.6, 0.8), C(-7.75, 23.2, -7.3) * A(0, 0, rad(2)), RUST_ORANGE)
plate(T, "Glacis", V(6.6, 4.2, 0.8), C(7.75, 23, -7.3) * A(0, 0, rad(-4)), OLD_YELLOW)
plate(T, "ChinPlate", V(8, 2.6, 0.8), C(0, 22.4, -7.3) * A(0, 0, rad(-3)), OLD_GREEN)
for side = -1, 1, 2 do
	plate(
		T,
		"FlankPatch",
		V(0.6, 5, 6),
		C(side * 11.2, 25.5, 0.4) * A(rad(side * 5), 0, 0),
		RUST_ORANGE
	)
	plate(
		T,
		"FlankPatchSmall",
		V(0.5, 2.6, 3),
		C(side * 11.5, 23.4, 3.8) * A(rad(-8), 0, 0),
		OLD_YELLOW
	)
end
-- One working headlamp, one dead.
cyl(T, "LampHousing", V(1.2, 2.4, 2.4), C(-6.4, 30.2, -7.4) * CYLINDER_Z, IRON)
cyl(T, "Headlamp", V(0.3, 1.8, 1.8), C(-6.4, 30.2, -8.1) * CYLINDER_Z, LAMP)
cyl(T, "LampHousing", V(1.2, 2.4, 2.4), C(6.4, 30, -7.4) * A(0, 0, rad(-20)) * CYLINDER_Z, IRON)
cyl(T, "DeadLamp", V(0.3, 1.8, 1.8), C(6.4, 30, -8.1) * CYLINDER_Z, DEAD_LAMP)
-- A chain hanging off the roof's front corner.
for k = 0, 5 do
	ball(T, "Chain", 0.7, V(9.6 + (k % 2) * 0.15, 31.6 - k * 0.65, -7.4), IRON)
end

-- Boiler on the back of the roof: a drum with domed ends, bands and rivet rows.
cyl(T, "Boiler", V(16, 9, 9), C(0, 36, 2), RUST)
for side = -1, 1, 2 do
	ball(T, "BoilerEnd", 9, V(side * 8, 36, 2), RUST_DARK)
end
for k = -1, 1 do
	cyl(T, "BoilerBand", V(0.8, 9.5, 9.5), C(k * 5.5, 36, 2), IRON)
	for j = 0, 5 do
		local a = rad(-30 + j * 30)
		ball(
			T,
			"Rivet",
			0.5,
			V(k * 5.5 + 0.6, 36 + math.sin(a) * 4.75, 2 - math.cos(a) * 4.75),
			RIVET
		)
	end
end
plate(T, "BoilerPatch", V(3.6, 2.6, 0.4), C(-3, 38.5, -2.1) * A(rad(-30), 0, rad(8)), OLD_GREEN)

-- Two crooked smokestacks with sooty lips, and a bent antenna. Smoke rises from each lip.
local stacks = { { -4, 4.4, 10, 2.4, rad(-4), rad(5) }, { 4.6, 4.8, 7, 2, rad(-7), rad(-8) } }
local smoke = {}
for _, stack in stacks do
	local base = C(stack[1], 39, stack[2]) * A(stack[5], 0, stack[6])
	local h, d = stack[3], stack[4]
	cyl(T, "Stack", V(h, d, d), base * C(0, h / 2, 0) * CYLINDER_Y, RUST_DARK)
	cyl(T, "StackBand", V(0.6, d + 0.3, d + 0.3), base * C(0, h * 0.4, 0) * CYLINDER_Y, IRON)
	cyl(T, "StackLip", V(0.8, d + 0.6, d + 0.6), base * C(0, h, 0) * CYLINDER_Y, SOOT)
	table.insert(smoke, { position = (base * C(0, h + 0.5, 0)).Position, bone = T })
end
cyl(T, "AntennaStub", V(2, 0.4, 0.4), C(-9, 33.5, -4) * CYLINDER_Y, IRON)
cyl(T, "Antenna", V(4, 0.25, 0.25), C(-8.3, 35.6, -4) * A(0, 0, rad(-30)) * CYLINDER_Y, IRON)
ball(T, "AntennaBulb", 0.7, V(-7.3, 37.3, -4), LAMP)

-- Cab interior --------------------------------------------------------------------------------
-- Seat block (invisible) at (0, 23, 0.8); the pilot's eye is near (0, 26.8, 1).
local IN = "torso"
part(IN, "InSeatPost", V(1.2, 1.6, 1.2), C(0, 21.8, 0.9), IRON)
part(IN, "InSeat", V(2.8, 0.6, 2.6), C(0, 22.7, 0.8), SEAT)
part(IN, "InSeatBack", V(2.8, 3.6, 0.6), C(0, 24.8, 2.2) * A(rad(6), 0, 0), SEAT)
-- Steam-age console: a dash of brass-rimmed gauges (needles at different pressures), warning
-- lamps and toggles; a side console under each corner window with a valve wheel and a dial;
-- copper pipes up the flanks into one across the back; a speaking tube from the roof.
part(IN, "InDash", V(8, 2.4, 1.4), C(0, 23.4, -4.2), IRON)
for k = -1, 1 do
	local face = C(k * 2.4, 24.4, -3.55) * A(rad(-15), 0, 0)
	cyl(IN, "InGaugeRim", V(0.12, 1.6, 1.6), face * C(0, 0, 0.03) * CYLINDER_Z, BRASS)
	cyl(IN, "InGauge", V(0.2, 1.3, 1.3), face * CYLINDER_Z, GAUGE)
	local needle = face * C(0, 0, 0.12) * A(0, 0, rad(50 - k * 55))
	part(IN, "InNeedle", V(0.08, 0.5, 0.04), needle * C(0, 0.22, 0), NEEDLE)
	ball(IN, "InNeedleCap", 0.18, (face * C(0, 0, 0.13)).Position, BRASS)
end
for index, x in { -3.6, -1.2, 1.2 } do
	ball(IN, "InLamp", 0.35, V(x, 24.7, -4.4), if index == 1 then RED_LAMP else AMBER)
end
for k = -1, 1 do
	part(
		IN,
		"InToggle",
		V(0.14, 0.5, 0.14),
		C(k * 0.7, 22.9, -3.4) * A(rad(k * 25 + 20), 0, 0),
		BRASS
	)
end
for side = -1, 1, 2 do
	part(IN, "InLever", V(0.3, 2.6, 0.3), C(side * 1.9, 23.8, -1) * A(rad(-15), 0, 0), IRON)
	ball(IN, "InKnob", 0.7, V(side * 1.9, 25.1, -1.35), BRASS)

	part(IN, "InSideConsole", V(4, 2.2, 1.4), C(side * 7.3, 23.3, -4.2), IRON)
	-- Valve wheel: a hub, two spokes and a rim of brass beads.
	local hub = V(side * 6.4, 23.4, -3.3)
	ball(IN, "InValveHub", 0.35, hub, BRASS)
	part(IN, "InValveSpoke", V(1.4, 0.14, 0.14), C(hub) * A(0, 0, rad(side * 20)), BRASS)
	part(IN, "InValveSpoke", V(0.14, 1.4, 0.14), C(hub) * A(0, 0, rad(side * 20)), BRASS)
	for j = 0, 5 do
		local a = rad(j * 60)
		ball(IN, "InValveRim", 0.3, hub + V(math.cos(a) * 0.7, math.sin(a) * 0.7, 0), BRASS)
	end
	local dial = C(side * 8.4, 23.6, -3.45) * CYLINDER_Z
	cyl(IN, "InDialRim", V(0.12, 1.1, 1.1), dial, BRASS)
	cyl(IN, "InDial", V(0.15, 0.85, 0.85), dial * C(-0.03, 0, 0), GAUGE)

	-- A copper pipe up the flank, bending back along the wall to the pipe across the back.
	cyl(IN, "InPipe", V(7.4, 0.5, 0.5), C(side * 9.1, 24.7, -2.6) * CYLINDER_Y, COPPER)
	ball(IN, "InPipeElbow", 0.7, V(side * 9.1, 28.4, -2.6), COPPER)
	cyl(IN, "InPipe", V(5.6, 0.5, 0.5), C(side * 9.1, 28.4, 0.2) * CYLINDER_Z, COPPER)
end
cyl(IN, "InPipe", V(18.6, 0.6, 0.6), C(0, 28.4, 3), COPPER)
cyl(IN, "InSpeakingTube", V(0.9, 0.3, 0.3), C(-3, 28.55, -1.5) * CYLINDER_Y, BRASS)
ball(IN, "InSpeakingHorn", 0.6, V(-3, 28.1, -1.5), BRASS)

-- Arms (decorative) ---------------------------------------------------------------------------
-- Huge arms with fists near the ground; pivots at x +-16 so the fists clear the wide feet.
for side = -1, 1, 2 do
	local s = side < 0 and "_L" or "_R"
	local upper, fore = "upperArm" .. s, "foreArm" .. s
	local ax = side * 16
	part(upper, "ShoulderMount" .. s, V(3, 5, 6), C(side * 12.5, 28.5, 0), IRON)
	ball(upper, "Shoulder" .. s, 7, V(ax, 28.5, 0), RUST)
	plate(
		upper,
		"Pauldron" .. s,
		V(7.6, 3, 9.2),
		C(side * 16.4, 32.2, 0) * A(0, 0, rad(-side * 12)),
		OLD_YELLOW
	)
	part(upper, "UpperArm" .. s, V(5, 8, 5.2), C(side * 16.6, 23, 0), RUST)
	cyl(upper, "BicepPiston" .. s, V(5, 1.2, 1.2), C(side * 16.6, 23.5, -3.2) * CYLINDER_Y, IRON)

	cyl(fore, "Elbow" .. s, V(5.8, 4.8, 4.8), C(side * 16.8, 19, 0), IRON)
	part(fore, "Forearm" .. s, V(6.4, 8, 6.8), C(side * 17.2, 14, -0.4), RUST)
	part(fore, "Cuff" .. s, V(7, 1.4, 7.4), C(side * 17.2, 17.4, -0.4), RUST_DARK)
	plate(
		fore,
		"ForearmPatch" .. s,
		V(4, 3, 0.4),
		C(side * 17.2, 13.6, -4) * A(0, 0, rad(side * 10)),
		RUST_ORANGE
	)
	part(fore, "Fist" .. s, V(7.4, 5.4, 7.4), C(side * 17.4, 7.4, -0.6), RUST_DARK)
	plate(fore, "Knuckles" .. s, V(7.6, 2.2, 1.6), C(side * 17.4, 6.4, -4.6), IRON)
	part(
		fore,
		"Thumb" .. s,
		V(2, 3.4, 2.4),
		C(side * 14.6, 8.2, -2.4) * A(0, 0, rad(side * 15)),
		RUST
	)
end

local bones = {
	{ name = "pelvis", pivot = V(0, HIP_Y, HIP_Z) },
	{ name = "torso", parent = "pelvis", pivot = V(0, 20, 0) },
	{ name = "upperArm_L", parent = "torso", pivot = V(-16, 28.5, 0) },
	{ name = "foreArm_L", parent = "upperArm_L", pivot = V(-16.8, 19, 0) },
	{ name = "upperArm_R", parent = "torso", pivot = V(16, 28.5, 0) },
	{ name = "foreArm_R", parent = "upperArm_R", pivot = V(16.8, 19, 0) },
}
for _, bone in legBones do
	table.insert(bones, bone)
end

local CAB_LO, CAB_HI = V(-9.5, 21, -5), V(9.5, 29, 3.5)
local collision = shell(V(-11, 19.5, -7), V(11, 32.5, 6.5), CAB_LO, CAB_HI)
table.insert(collision, { size = V(18, 9, 9), offset = C(0, 36, 2) }) -- boiler y 31.5..40.5
table.insert(collision, { size = V(12, 4, 8), offset = C(0, 17.5, 0.2) }) -- pelvis y 15.5..19.5

return {
	name = "Rustbucket",
	speed = 8,
	turnRate = 0.45,
	footprint = Vector2.new(30, 22),
	collision = collision,
	bones = bones,
	seatBone = "torso",
	cab = { center = (CAB_LO + CAB_HI) / 2, size = CAB_HI - CAB_LO },
	exit = C(0, 3, 15) * A(0, math.pi, 0), -- on the ground behind, facing away
	cameraFocus = V(0, 38, 0),
	cockpitCamera = true,
	gait = "mech",
	acceleration = 4,
	braking = 8,
	coasting = 6,
	turnAcceleration = 0.6,
	turnInPlace = true,
	parkingBrake = true,
	uprightTorque = 8,
	stepsOver = true,
	ram = 5,
	smoke = smoke,
	seats = { C(0, 23, 0.8) },
	pieces = pieces,
}
