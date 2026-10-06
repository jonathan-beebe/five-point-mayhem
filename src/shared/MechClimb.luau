--!strict
-- Decision logic for the walker climb assist; Vehicles senses, this decides. Pure math, no
-- services, so Lune can load it for tests (tools/tests/mech_climb.luau).
--
-- A driven walker pushing into a wall up to MAX_RISE tall, with headroom and a flat top, lifts
-- itself straight up (Vehicles' "Climber" constraint) and steps onto the top. While it lifts it
-- keeps a GAP from the wall, so trim along the wall cannot catch the skid; once the skid's ramps
-- clear the top it presses forward, and it walks again when the flat of its skid is over the top.
-- Letting go of the throttle clings to the wall; reversing lets go.
--
-- Everything is in vehicle space (origin on the ground under the center of the footprint, +Y up,
-- -Z front). Heights in a Probe and Input are relative to the skid's bottom.

local MechClimb = {}

MechClimb.MAX_RISE = 14 -- pyramid tier 12 + margin; lobby wall/gates 26, castle 30 stay out
MechClimb.MIN_RISE = 1.6 -- lower ledges are the skid ramps' job (= Vehicles RAMP_HEIGHT)
MechClimb.RAMP_LENGTH = 2.5 -- = Vehicles RAMP_LENGTH: the skid's flat underside starts this far in
MechClimb.WALL_RAY_HEIGHT = 2.0
MechClimb.REACH = 2.5
MechClimb.LEDGE_INSET = 2 -- probe lands 4.5 past the front: inside a 9-stud ledge
MechClimb.WALL_MAX_NORMAL_Y = 0.6
MechClimb.TOP_MIN_NORMAL_Y = 0.6 -- balustrade 0.707 passes
MechClimb.SPEED = 8 -- studs/s up
MechClimb.PRESS = 3 -- studs/s forward once the ramps clear the top
MechClimb.GAP = 0.6 -- studs kept from the wall while lifting: clears trim up to this deep
MechClimb.BACKOFF = 2 -- studs/s back while closer than GAP
MechClimb.CLEAR = 1.4 -- press forward from this far under the top: the ramp tips (1.6) clear it
MechClimb.CLEARANCE = 0.4 -- lift to this far over the top
MechClimb.STALL_SPEED = 1
MechClimb.STALL_TIME = 0.6
MechClimb.STALL_GRACE = 0.2 -- seconds at the start of a climb before a stall counts
MechClimb.COOLDOWN = 1.0

export type Probe = {
	wall: { distance: number }?, -- nearest wall face ahead, from the skid's front
	ledge: { height: number, normalY: number }?, -- the top LEDGE_INSET past REACH
	headroom: boolean, -- nothing taller than MAX_RISE within reach of the top, across the width
	foot: number?, -- ground under the front of the skid's flat underside; nil = none near
}
export type Mode = "walk" | "climb" | "cling"
export type State = {
	mode: Mode,
	target: number, -- height of the top being climbed (bottom-relative at the start, then absolute)
	stalled: number, -- seconds without progress
	time: number, -- seconds into this climb
	cooldown: number, -- seconds before a new climb may start
}
export type Input = {
	throttle: number,
	bottom: number, -- skid bottom, world Y
	vy: number, -- vertical velocity
	speed: number, -- horizontal velocity along the walker's forward
	probe: Probe?, -- nil when not sensed
	dt: number,
}
export type Command = {
	lift: number?, -- vertical speed for the climber; nil = climber off (0 holds)
	press: number?, -- forward speed while climbing (- = back); nil = ordinary driving
	climbing: boolean,
}

-- A ray in vehicle space from (x, y, z): walls and headroom cast forward (-Z), ledge and foot down.
export type Ray = { x: number, y: number, z: number, length: number }
-- `front` is the z of the skid's front edge, which Probe distances count from. Walls and headroom
-- cast at the same x offsets: both edges and the center.
export type Rays = { front: number, walls: { Ray }, headroom: { Ray }, ledge: Ray, foot: Ray }

-- Side rays run this far inside the skid's edges, so a wall meeting a front corner at an angle
-- reads as near as it is (the GAP holds the corner off trim).
MechClimb.EDGE_INSET = 0.05

function MechClimb.new(): State
	return { mode = "walk", target = 0, stalled = 0, time = 0, cooldown = 0 }
end

-- How far above the skid's bottom the top of the wall ahead is, if the walker can climb it.
function MechClimb.rise(probe: Probe): number?
	local wall, ledge = probe.wall, probe.ledge
	if not wall or wall.distance > MechClimb.REACH or not probe.headroom or not ledge then
		return nil
	end
	if ledge.normalY < MechClimb.TOP_MIN_NORMAL_Y then
		return nil
	end
	if ledge.height <= MechClimb.MIN_RISE or ledge.height > MechClimb.MAX_RISE then
		return nil
	end
	return ledge.height
end

local function walk(state: State): Command
	state.mode = "walk"
	return { climbing = false }
end

function MechClimb.step(state: State, input: Input): Command
	state.cooldown = math.max(state.cooldown - input.dt, 0)
	local throttle = input.throttle
	if throttle < 0 then
		return walk(state)
	end
	if throttle == 0 then
		if state.mode == "walk" then
			return { climbing = false }
		end
		state.mode = "cling"
		return { lift = 0, climbing = true }
	end

	local bottom = input.bottom
	local probe = input.probe
	if state.mode == "walk" then
		local r = if state.cooldown == 0 and probe then MechClimb.rise(probe) else nil
		if not r then
			return { climbing = false }
		end
		state.target = bottom + r
		state.stalled = 0
		state.time = 0
	end
	if state.mode == "cling" then
		state.stalled = 0
		state.time = 0
	end
	state.mode = "climb"
	state.time += input.dt

	local r = probe and MechClimb.rise(probe)
	if r then
		state.target = math.max(state.target, bottom + r)
	end

	local over = bottom >= state.target + MechClimb.CLEARANCE
	if over and probe and probe.foot then
		return walk(state)
	end

	-- Progress: rising while under the top, moving forward once over it.
	local moving = if over then input.speed else input.vy
	if moving >= MechClimb.STALL_SPEED or state.time < MechClimb.STALL_GRACE then
		state.stalled = 0
	else
		state.stalled += input.dt
		if state.stalled >= MechClimb.STALL_TIME then
			state.cooldown = MechClimb.COOLDOWN
			return walk(state)
		end
	end

	local press = 0
	if bottom >= state.target - MechClimb.CLEAR then
		press = MechClimb.PRESS
	elseif probe and probe.wall and probe.wall.distance < MechClimb.GAP then
		press = -MechClimb.BACKOFF
	end
	return { lift = if over then 0 else MechClimb.SPEED, press = press, climbing = true }
end

-- The sensing rays for a W x L footprint, vehicle space.
function MechClimb.rays(W: number, L: number): Rays
	local front = -L / 2
	local start = front + 1 -- one stud inside the skid, so a wall touching the front still hits
	local high = MechClimb.MAX_RISE + 1
	local side = W / 2 - MechClimb.EDGE_INSET
	local walls, headroom = {}, {}
	for _, x in { -side, 0, side } do
		table.insert(walls, {
			x = x,
			y = MechClimb.WALL_RAY_HEIGHT,
			z = start,
			length = MechClimb.REACH + 1,
		})
		table.insert(headroom, {
			x = x,
			y = high,
			z = start,
			length = MechClimb.REACH + MechClimb.LEDGE_INSET + 1,
		})
	end
	return {
		front = front,
		walls = walls,
		headroom = headroom,
		ledge = {
			x = 0,
			y = high,
			z = front - MechClimb.REACH - MechClimb.LEDGE_INSET,
			length = high + 0.5,
		},
		foot = {
			x = 0,
			y = 0.5,
			z = front + MechClimb.RAMP_LENGTH,
			length = MechClimb.CLEARANCE + 1,
		},
	}
end

return MechClimb
