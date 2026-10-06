-- Checks the walker climb assist (src/shared/MechClimb.luau) outside Roblox.
-- Usage: lune run tools/tests/mech_climb.luau
--
--   - rise/step rules: when a climb starts, ends, clings, lets go, and gives up on a stall
--   - every walker's sensing rays start inside its footprint and probe the right spots
--   - a 2D side view of every walker (its length, speed and acceleration) driving at full
--     throttle into the pyramid's faces and staircase, a sheer wall and a thin wall: it climbs
--     what it should, refuses the rest, never sinks into the world, and does not stall in a loop
--   - the walk cycle steps while the walker is lifted in place, and parks after

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local function load(file: string): any
	local environment = { CFrame = roblox.CFrame, Vector3 = roblox.Vector3 }
	return luau.load(fs.readFile(file), { debugName = file, environment = environment })()
end

local MechClimb = load("src/shared/MechClimb.luau")
local MechGait = load("src/shared/MechGait.luau")

local failures = 0
local checks = 0

local function check(ok: boolean, message: string)
	checks += 1
	if not ok then
		failures += 1
		print("FAIL " .. message)
	end
end

-- Every walker's model file, loaded the way mech_gait.luau loads it.
local walkers = {}
for _, file in fs.readDir("src/server/vehicleModels") do
	local path = "src/server/vehicleModels/" .. file
	local environment = {
		CFrame = roblox.CFrame,
		Vector3 = roblox.Vector3,
		Vector2 = roblox.Vector2,
		Color3 = roblox.Color3,
		Enum = roblox.Enum,
	}
	local spec = luau.load(fs.readFile(path), { debugName = path, environment = environment })()
	if spec.gait == "mech" then
		local pivots = {}
		for _, bone in spec.bones do
			pivots[bone.name] = bone.pivot
		end
		table.insert(walkers, {
			name = spec.name,
			W = spec.footprint.X,
			L = spec.footprint.Y,
			speed = spec.speed,
			acceleration = spec.acceleration or 55,
			coasting = spec.coasting or 30,
			turnRate = spec.turnRate or 0.7,
			pivots = pivots,
		})
	end
end
table.sort(walkers, function(a, b)
	return a.name < b.name
end)

-- rise and step ---------------------------------------------------------------------------------

local DT = 1 / 60

local function probe(rise: number, fields: { [string]: any }?): any
	local p = { wall = { distance = 0.2 }, ledge = { height = rise, normalY = 1 }, headroom = true }
	for key, value in fields or {} do
		p[key] = value
	end
	return p
end

do
	check(MechClimb.rise(probe(12)) == 12, "a 12-stud wall with a top should be climbable")
	check(MechClimb.rise(probe(0.8)) == nil, "a 0.8 ledge is the ramps' job")
	check(MechClimb.rise(probe(20)) == nil, "a 20-stud wall is too tall")
	check(MechClimb.rise(probe(12, { headroom = false })) == nil, "no headroom, no climb")
	check(
		MechClimb.rise(probe(12, { ledge = { height = 12, normalY = 0.3 } })) == nil,
		"a steep top is not a top"
	)
	check(MechClimb.rise(probe(12, { wall = false })) == nil, "no wall, no climb")

	local state = MechClimb.new()
	local idle = MechClimb.step(
		state,
		{ throttle = 0, bottom = 0, vy = 0, speed = 0, probe = probe(12), dt = DT }
	)
	check(idle.lift == nil and not idle.climbing, "no throttle, no lift")

	-- A climb from bottom 0 onto a 12-stud top: lifts, presses once clear, ends over the top.
	local command = MechClimb.step(
		state,
		{ throttle = 1, bottom = 0, vy = 0, speed = 0, probe = probe(12), dt = DT }
	)
	check(command.lift == MechClimb.SPEED and command.climbing, "a wall + rise 12 should climb")
	check(command.press == -MechClimb.BACKOFF, "against the wall: back off to the gap")
	command = MechClimb.step(state, {
		throttle = 1,
		bottom = 11,
		vy = 8,
		speed = 0,
		probe = probe(1, { wall = false }),
		dt = DT,
	})
	check(command.press == MechClimb.PRESS, "ramps clear of the top: press forward")
	command = MechClimb.step(state, {
		throttle = 1,
		bottom = 12 + MechClimb.CLEARANCE,
		vy = 8,
		speed = 3,
		probe = { headroom = true },
		dt = DT,
	})
	check(command.lift == 0 and command.press == MechClimb.PRESS, "over the top: hold and press")
	command = MechClimb.step(state, {
		throttle = 1,
		bottom = 12 + MechClimb.CLEARANCE,
		vy = 0,
		speed = 3,
		probe = { headroom = true, foot = -MechClimb.CLEARANCE },
		dt = DT,
	})
	check(not command.climbing and state.mode == "walk", "on the top: walk")

	-- Stalled under an overhang: gives up after STALL_TIME, then waits out the cooldown.
	state = MechClimb.new()
	MechClimb.step(
		state,
		{ throttle = 1, bottom = 0, vy = 0, speed = 0, probe = probe(12), dt = DT }
	)
	local t, gaveUp = 0, nil
	while t < 2 and not gaveUp do
		t += DT
		command = MechClimb.step(
			state,
			{ throttle = 1, bottom = 3, vy = 0, speed = 0, probe = probe(9), dt = DT }
		)
		if not command.climbing then
			gaveUp = t
		end
	end
	check(
		gaveUp ~= nil
			and gaveUp >= MechClimb.STALL_TIME
			and gaveUp <= MechClimb.STALL_TIME + MechClimb.STALL_GRACE + 0.05,
		"a stall should give up after STALL_TIME, got " .. tostring(gaveUp)
	)
	check(state.cooldown > 0, "a stall should start the cooldown")
	command = MechClimb.step(
		state,
		{ throttle = 1, bottom = 3, vy = 0, speed = 0, probe = probe(9), dt = DT }
	)
	check(not command.climbing, "no new climb during the cooldown")
	for _ = 1, math.ceil(MechClimb.COOLDOWN / DT) + 1 do
		command = MechClimb.step(
			state,
			{ throttle = 1, bottom = 3, vy = 0, speed = 0, probe = probe(9), dt = DT }
		)
	end
	check(command.climbing, "climbs again after the cooldown")

	-- Letting go mid-climb clings; throttle resumes toward the same top; reverse lets go.
	state = MechClimb.new()
	MechClimb.step(
		state,
		{ throttle = 1, bottom = 0, vy = 0, speed = 0, probe = probe(12), dt = DT }
	)
	MechClimb.step(
		state,
		{ throttle = 1, bottom = 5, vy = 8, speed = 0, probe = probe(7), dt = DT }
	)
	command = MechClimb.step(state, { throttle = 0, bottom = 6, vy = 8, speed = 0, dt = DT })
	check(command.lift == 0 and command.climbing and state.mode == "cling", "throttle 0 clings")
	for _ = 1, 120 do
		command = MechClimb.step(state, { throttle = 0, bottom = 6, vy = 0, speed = 0, dt = DT })
	end
	check(command.lift == 0 and state.mode == "cling", "clinging lasts")
	command = MechClimb.step(state, {
		throttle = 1,
		bottom = 6,
		vy = 0,
		speed = 0,
		probe = probe(6, { wall = { distance = 1 } }),
		dt = DT,
	})
	check(
		command.lift == MechClimb.SPEED and state.target == 12,
		"throttle resumes the climb toward the same top"
	)
	command = MechClimb.step(state, { throttle = -1, bottom = 7, vy = 8, speed = 0, dt = DT })
	check(command.lift == nil and not command.climbing, "reverse lets go")
end

-- Rays ------------------------------------------------------------------------------------------

for _, walker in walkers do
	local rays = MechClimb.rays(walker.W, walker.L)
	local front = -walker.L / 2
	for index, ray in rays.walls do
		check(
			math.abs(ray.x) < walker.W / 2 and ray.z > front and ray.z < walker.L / 2,
			string.format("%s: wall ray %d starts outside the footprint", walker.name, index)
		)
		check(
			ray.z - ray.length <= front - MechClimb.REACH + 1e-6,
			string.format("%s: wall ray %d falls short of REACH", walker.name, index)
		)
	end
	local past = front - rays.ledge.z
	check(
		past >= 3 and past <= 8.9,
		string.format("%s: ledge probe lands %.1f past the front", walker.name, past)
	)
	check(#rays.headroom == #rays.walls, walker.name .. ": a headroom ray per wall ray")
	for index, ray in rays.headroom do
		check(
			ray.x == rays.walls[index].x and ray.z - ray.length <= rays.ledge.z,
			string.format(
				"%s: headroom ray %d should share its wall ray's x and reach the ledge probe",
				walker.name,
				index
			)
		)
	end

	-- Angled approach: a wall meeting a front corner at angle a reads within GAP of the corner, so
	-- the climb backs the corner off the trim. A ray at x meets that wall (W/2 - |x|) * tan(a) past
	-- the front.
	for _, degrees in { 10, 25, 45, 60 } do
		local nearest = math.huge
		for _, ray in rays.walls do
			nearest =
				math.min(nearest, (walker.W / 2 - math.abs(ray.x)) * math.tan(math.rad(degrees)))
		end
		check(
			nearest < MechClimb.GAP / 2,
			string.format(
				"%s: a wall at %d degrees on a front corner reads %.2f away",
				walker.name,
				degrees,
				nearest
			)
		)
	end
	check(
		rays.ledge.y - rays.ledge.length < -0.4,
		walker.name .. ": ledge probe should reach below the bottom"
	)
	check(
		rays.foot.z > front and rays.foot.y - rays.foot.length <= -MechClimb.CLEARANCE - 0.5 + 1e-6,
		walker.name .. ": foot ray should start in the footprint and reach under the clearance"
	)
end

-- 2D kinematic side view -------------------------------------------------------------------------
-- `s` runs along the walker's path (forward +), `y` up. The world is boxes {s0, s1, y0, y1}. The
-- skid spans [front - L, front] with ramps RAMP_LENGTH long at each end whose undersides rise to
-- RAMP_HEIGHT at the tips (Vehicles' sled); everything above it is ignored. A box may carry an x
-- range {.., x0, x1} (vehicle space across the walker): rays at other x miss it, but it always
-- overlaps the footprint, so the skid collides with it.

local RAMP_HEIGHT, RAMP_LENGTH = 1.6, 2.5
local GRAVITY = 196.2
local EPS = 1e-6

type Box = { number }

-- The lowest point of the skid's underside over [a, c] (inside the skid), above its bottom.
local function underside(front: number, L: number, a: number, c: number): number
	local back = front - L
	if c > back + RAMP_LENGTH and a < front - RAMP_LENGTH then
		return 0
	end
	if a >= front - RAMP_LENGTH then
		return RAMP_HEIGHT * (1 - (front - a) / RAMP_LENGTH)
	end
	return RAMP_HEIGHT * (1 - (c - back) / RAMP_LENGTH)
end

local function span(front: number, L: number, box: Box): (number, number)
	return math.max(box[1], front - L), math.min(box[2], front)
end

local function overlaps(world: { Box }, front: number, L: number, bottom: number, slack: number)
	for _, box in world do
		local a, c = span(front, L, box)
		if c - a > EPS then
			local low = bottom + underside(front, L, a, c)
			if box[4] > low + slack and box[3] < bottom + RAMP_HEIGHT - slack then
				return true
			end
		end
	end
	return false
end

-- The highest bottom resting on boxes no higher than `limit` above `bottom`.
local function support(world: { Box }, front: number, L: number, limit: number): number
	local best = -math.huge
	for _, box in world do
		local a, c = span(front, L, box)
		if c - a > EPS then
			local rest = box[4] - underside(front, L, a, c)
			if rest <= limit + EPS then
				best = math.max(best, rest)
			end
		end
	end
	return best
end

local function inside(box: Box, s: number, y: number): boolean
	return s > box[1] and s < box[2] and y > box[3] and y < box[4]
end

local function lane(box: Box, x: number): boolean
	return box[5] == nil or (x > box[5] and x < box[6])
end

-- First face a forward ray at height y from s meets within length, ignoring boxes it starts in.
local function castForward(world: { Box }, x: number, s: number, y: number, length: number): number?
	local nearest = nil
	for _, box in world do
		if lane(box, x) and not inside(box, s, y) and y > box[3] and y < box[4] and box[1] >= s then
			local d = box[1] - s
			if d <= length and (not nearest or d < nearest) then
				nearest = d
			end
		end
	end
	return nearest
end

-- Highest top a downward ray from (s, y) meets within length, ignoring boxes it starts in.
local function castDown(world: { Box }, x: number, s: number, y: number, length: number): number?
	local best = nil
	for _, box in world do
		if lane(box, x) and s >= box[1] and s < box[2] and not inside(box, s, y) then
			if box[4] <= y and box[4] >= y - length and (not best or box[4] > best) then
				best = box[4]
			end
		end
	end
	return best
end

-- Senses the world the way Vehicles does.
local function sense(world: { Box }, rays, front: number, L: number, bottom: number)
	local center = front - L / 2
	local function at(z: number): number
		return center - z
	end
	local wall = nil
	for _, ray in rays.walls do
		local d = castForward(world, ray.x, at(ray.z), bottom + ray.y, ray.length)
		local distance = d and d - (ray.z - rays.front)
		if distance and (not wall or distance < wall.distance) then
			wall = { distance = distance }
		end
	end
	local headroom = true
	for _, ray in rays.headroom do
		if castForward(world, ray.x, at(ray.z), bottom + ray.y, ray.length) then
			headroom = false
		end
	end
	local ledge, foot = rays.ledge, rays.foot
	local top = castDown(world, ledge.x, at(ledge.z), bottom + ledge.y, ledge.length)
	local under = castDown(world, foot.x, at(foot.z), bottom + foot.y, foot.length)
	return {
		wall = wall,
		ledge = if top then { height = top - bottom, normalY = 1 } else nil,
		headroom = headroom,
		foot = if under then under - bottom else nil,
	}
end

type Run = {
	top: number,
	at: number, -- seconds to reach the top
	final: number,
	climbs: number,
	stalls: number,
	settled: number,
}

-- Drives a walker at full throttle from `start` (its front) for `seconds`.
local function simulate(walker, world: { Box }, start: number, seconds: number, label: string): Run
	local L = walker.L
	local rays = MechClimb.rays(walker.W, L)
	local state = MechClimb.new()
	local front, bottom = start, 0
	local speed, vy = 0, 0
	local run = { top = 0, at = 0, final = 0, climbs = 0, stalls = 0, settled = 0 }
	local wasClimbing = false
	local sank = false
	local t = 0
	while t < seconds do
		local command = MechClimb.step(state, {
			throttle = 1,
			bottom = bottom,
			vy = vy,
			speed = speed,
			probe = sense(world, rays, front, L, bottom),
			dt = DT,
		})
		if command.climbing and not wasClimbing then
			run.climbs += 1
		end
		if wasClimbing and not command.climbing and state.cooldown > 0 then
			run.stalls += 1
		end
		wasClimbing = command.climbing

		-- Vertical: the climber holds its speed until something stops it; otherwise gravity.
		if command.lift then
			vy = command.lift
			local next = bottom + vy * DT
			if overlaps(world, front, L, next, 0) then
				vy = 0
			else
				bottom = next
			end
		else
			vy -= GRAVITY * DT
			local floor = support(world, front, L, bottom)
			bottom += vy * DT
			if bottom <= floor then
				bottom, vy = floor, 0
			end
		end

		-- Horizontal: the drive constraint's target; the ramps lift the skid onto low ledges.
		local target = if command.press
			then command.press
			else math.min(speed + walker.acceleration * DT, walker.speed)
		local next = front + target * DT
		local moved = false
		if not overlaps(world, next, L, bottom, 0) then
			moved = true
		else
			local ramped = support(world, next, L, bottom + RAMP_HEIGHT)
			if ramped > bottom and not overlaps(world, next, L, ramped, 0) then
				bottom, moved = ramped, true
				vy = math.max(vy, 0)
			end
		end
		if moved then
			front, speed = next, target
		else
			speed = 0
		end

		if overlaps(world, front, L, bottom, 0.05) and not sank then
			sank = true
			check(false, string.format("%s %s t=%.2f: sank into the world", walker.name, label, t))
		end
		if bottom > run.top + 0.05 then
			run.top, run.at = bottom, t
		end
		if math.abs(bottom - run.final) < 0.05 and not command.climbing then
			run.settled += DT
		else
			run.settled = 0
		end
		run.final = bottom
		t += DT
	end
	print(
		string.format(
			"  %-22s top %5.1f at %4.1f s  final %5.1f  climbs %2d  stalls %d",
			label,
			run.top,
			run.at,
			run.final,
			run.climbs,
			run.stalls
		)
	)
	return run
end

-- The pyramid, from src/server/world/buildings/Pyramid.luau:16-19 (BASE_SIZE 170, TIERS 8,
-- TIER_HEIGHT 12, SHRINK 18): tier k spans 9k..170-9k from the face, 12k..12k+12 high, with a jade
-- band 1.5 tall and 0.3 proud at the top of each riser. `temple` is how far from the face the
-- summit temple starts (40 x 30, about 19 tall with roof and parapet).
local BASE, TIERS, TIER, SHRINK = 170, 8, 12, 18
local SUMMIT = TIERS * TIER

local GROUND: Box = { -1000, 1000, -10, 0 }

-- `templeX` limits the temple to an x range across the walker (an off-center approach).
local function pyramid(temple: number, templeX: { number }?): { Box }
	local world = { GROUND }
	for k = 0, TIERS - 1 do
		local s0 = k * SHRINK / 2
		table.insert(world, { s0, BASE - s0, k * TIER, (k + 1) * TIER })
		table.insert(world, { s0 - 0.3, s0 + 0.1, (k + 1) * TIER - 1.5, (k + 1) * TIER })
	end
	local x0, x1 = nil, nil
	if templeX then
		x0, x1 = templeX[1], templeX[2]
	end
	table.insert(world, { temple, BASE - temple, SUMMIT, SUMMIT + 19, x0, x1 })
	return world
end

-- The front staircase: 1-stud steps at 45 degrees from 33 studs out to the summit edge
-- (Pyramid.luau:190-218), over the front face.
local function staircase(): { Box }
	local world = pyramid(BASE / 2 - 15)
	local edge = (BASE - (TIERS - 1) * SHRINK) / 2 + SUMMIT - BASE / 2 -- footZ, from the face
	for step = 1, SUMMIT do
		local s = -edge + step - 1
		table.insert(world, { s, s + 1, if s + 0.5 > 0 then TIER else 0, step })
	end
	return world
end

for _, walker in walkers do
	print(walker.name)
	-- (a) Back face: 7 studs free in front of the temple.
	local back = simulate(walker, pyramid(BASE / 2 - 15), -10, 60, "back face")
	check(back.top >= SUMMIT - 0.05, walker.name .. ": back face should reach the summit")
	check(back.stalls == 0, walker.name .. ": back face should not stall")

	-- (b) Side faces: 2 studs free; the last tier is refused cleanly.
	local side = simulate(walker, pyramid(BASE / 2 - 20), -10, 60, "side face")
	check(
		math.abs(side.final - (SUMMIT - TIER)) < 0.05,
		string.format(
			"%s: side face should stop at %d, got %.1f",
			walker.name,
			SUMMIT - TIER,
			side.final
		)
	)
	check(side.stalls == 0, walker.name .. ": side face should not stall")
	check(side.climbs == TIERS - 1, walker.name .. ": side face should climb once per tier")
	check(side.settled > 5, walker.name .. ": side face should settle")

	-- (b') A side face approached off-center: the temple is beside the center line, across only
	-- one edge of the walker. The edge headroom ray refuses the last tier; no climb into the
	-- temple, no stall loop.
	local offset = simulate(
		walker,
		pyramid(BASE / 2 - 20, { walker.W / 2 - 2, walker.W / 2 + 40 }),
		-10,
		60,
		"side face, off-center"
	)
	check(
		math.abs(offset.final - (SUMMIT - TIER)) < 0.05,
		string.format(
			"%s: off-center side face should stop at %d, got %.1f",
			walker.name,
			SUMMIT - TIER,
			offset.final
		)
	)
	check(offset.stalls == 0, walker.name .. ": off-center side face should not stall")
	check(
		offset.climbs == TIERS - 1,
		walker.name .. ": off-center side face should climb once per tier"
	)

	-- (c) The front staircase.
	local stairs = simulate(walker, staircase(), -50, 60, "front staircase")
	check(stairs.top >= SUMMIT - 0.05, walker.name .. ": staircase should reach the summit")
	check(stairs.stalls == 0, walker.name .. ": staircase should not stall")

	-- (d) A 30-stud sheer wall.
	local sheer = simulate(walker, { GROUND, { 0, 50, 0, 30 } }, -10, 10, "30-stud wall")
	check(sheer.top <= RAMP_HEIGHT, walker.name .. ": a 30-stud wall should not be climbed")
	check(sheer.climbs == 0, walker.name .. ": a 30-stud wall should not start a climb")

	-- (e) A 12-stud wall 1 stud thick: no top to stand on, so it is not climbed.
	local thin = simulate(walker, { GROUND, { 0, 1, 0, 12 } }, -10, 10, "12-stud thin wall")
	check(thin.top <= RAMP_HEIGHT, walker.name .. ": a thin wall should not be climbed")
	check(thin.climbs == 0, walker.name .. ": a thin wall should not start a climb")

	-- (f) A 12-stud block with a deep top: one climb, then on top for good.
	local block = simulate(walker, { GROUND, { 0, 400, 0, 12 } }, -10, 15, "12-stud block")
	check(
		math.abs(block.final - 12) < 0.05 and block.climbs == 1 and block.settled > 5,
		walker.name .. ": a 12-stud block should be climbed once and stood on"
	)
end

-- Gait while lifted -----------------------------------------------------------------------------

for _, walker in walkers do
	local state = MechGait.new(MechGait.rig(walker.pivots))
	local function step(t: number, climb: number)
		return MechGait.step(state, {
			forward = 0,
			climb = climb,
			yawRate = 0,
			occupied = true,
			topSpeed = walker.speed,
			turnRate = walker.turnRate,
			time = t,
		}, DT)
	end
	local footfalls, t = 0, 0
	while t < 2 do
		footfalls += #step(t, MechClimb.SPEED)
		t += DT
	end
	check(state.rate > 0, walker.name .. ": legs should step while lifted")
	check(footfalls >= 2, walker.name .. ": lifting should give footfalls, got " .. footfalls)
	local parked = nil
	while t < 5 do
		step(t, 0)
		if state.rate == 0 and not parked then
			parked = t
		end
		t += DT
	end
	check(parked ~= nil and parked <= 5, walker.name .. ": legs should park within 3 s of the lift")
end

print(string.format("%d checks, %d failures", checks, failures))
if failures > 0 then
	process.exit(1)
end
