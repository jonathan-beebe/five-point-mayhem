--!strict
-- Walk cycle for every walker's bones: pure math, no services, so Lune can load it for tests and
-- the preview renderer. The legs are decoration driven by the skid's measured velocity; nothing
-- here touches physics. Stride lengths and heights are OG's (legs 19 studs long),
-- scaled by each rig's leg length.
--
-- Everything is in vehicle space (origin on the ground, +Y up, -Z front, +X right). A foot's `z` is
-- its forward offset (+ = forward) from its rest ankle. Phase `phase` runs 0..1 per stride: the
-- left foot is in stance for [0, DUTY) and swings for the rest; the right foot runs half a cycle
-- later. Stance feet integrate the ground speed under their hip, so they stay planted; swing feet
-- travel from where they lifted off to where the next stance will center them.
--
-- Angle signs (Motor6D Transform about the vehicle axes):
--   +X  a hanging segment swings forward; a forward toe tips up; the torso top tips back
--   +Y  the front turns left
--   +Z  a hanging segment swings toward +X; the +X side rises

local MechGait = {}

local rad = math.rad
local TAU = 2 * math.pi

-- Distances below are for a leg of REFERENCE_LEG; a rig's `scale` multiplies them.
MechGait.REFERENCE_LEG = 19 -- thigh + shin, studs
MechGait.STEP = 14 -- one foot's stance travel at full stride, studs
MechGait.DUTY = 0.6 -- stance fraction of the cycle; 20 % double support
MechGait.CYCLE = MechGait.STEP / MechGait.DUTY -- studs per stride
MechGait.LIFT = 3.5 -- peak swing height
MechGait.MIN_RATE = 0.6 -- cycles per second while turning in place or settling
MechGait.MOVING = 0.3 -- ground speed (studs/s) below which the legs settle and stop
MechGait.SETTLED = 0.75 -- feet within this of their rest spot count as under the hips
local SLIP = MechGait.STEP / 2 + 1 -- a planted foot slides only past this

local BOB = 0.9
local DIP = 0.3
local SWAY = 0.6
local ROLL = rad(2.5)
local PELVIS_YAW = rad(5)
local TORSO_YAW = rad(8)
local ARM_SWING = rad(10)
local ELBOW = rad(8)
local LEAN_SPEED = rad(3)
local LEAN_ACCEL = rad(5)
local TURN_LEAD = rad(4)
local W_TAU = 0.3 -- smoothing of the gait weight, seconds
local ACCEL_TAU = 0.25 -- smoothing of the measured acceleration, seconds
local FULL_GAIT = 6 -- ground speed at which the body overlays reach full weight

-- Idle (occupied, standing): a slow breath and an occasional weight shift.
local BREATH_PERIOD = 3.5
local IDLE_RAMP = 1.0 -- seconds for the idle amplitude to go 0 -> 1 and back
local HATCH_TIME = 0.8 -- seconds to open or close
local HATCH_OPEN = rad(-100)
local SHIFT = 0.4
local SHIFT_EASE = 1.2
local SHIFT_HOLD = 2

-- Toe pitch keys over a swing (progress 0..1), radians.
local TOE_KEYS = { { 0, 0 }, { 0.15, rad(-12) }, { 0.6, 0 }, { 0.9, rad(8) }, { 1, 0 } }

-- Limits relative to the rest pose, radians (studs for translations). Poses are clamped to these.
MechGait.LIMITS = {
	pelvis = {
		tx = { -1, 1 },
		ty = { -1.4, 0 },
		x = { rad(-3), rad(3) },
		y = { rad(-10), rad(10) },
		z = { rad(-4), rad(4) },
	},
	torso = { x = { rad(-8), rad(3) }, y = { rad(-10), rad(10) }, z = { rad(-3), rad(3) } },
	hatch = { x = { rad(-100), 0 } },
	upperArm_L = { x = { rad(-20), rad(20) }, z = { rad(-8), 0 } },
	upperArm_R = { x = { rad(-20), rad(20) }, z = { 0, rad(8) } },
	foreArm_L = { x = { 0, rad(40) } },
	foreArm_R = { x = { 0, rad(40) } },
	thigh_L = { x = { rad(-30), rad(32) }, z = { rad(-6), rad(6) } },
	thigh_R = { x = { rad(-30), rad(32) }, z = { rad(-6), rad(6) } },
	shin_L = { x = { rad(-40), rad(15) } },
	shin_R = { x = { rad(-40), rad(15) } },
	foot_L = { x = { rad(-45), rad(45) }, z = { rad(-6), rad(6) } },
	foot_R = { x = { rad(-45), rad(45) }, z = { rad(-6), rad(6) } },
}

export type Side = "L" | "R"

export type Leg = {
	side: Side,
	hip: Vector3, -- rest pivots, vehicle space
	knee: Vector3,
	ankle: Vector3,
	thigh: number, -- segment lengths
	shin: number,
	thighRest: number, -- segment angles from vertical in the rest pose (+ = forward)
	shinRest: number,
	offset: number, -- phase offset: 0 left, 0.5 right
}

export type Rig = {
	pelvis: Vector3,
	legs: { Leg },
	scale: number, -- leg length / REFERENCE_LEG
}

export type Foot = {
	z: number, -- forward offset from the rest ankle
	lift: number,
	swinging: boolean,
	liftoff: number, -- z at the start of the current swing
	toe: number, -- toe pitch, radians
	speed: number, -- ground speed under the hip, forward +
}

export type Input = {
	forward: number, -- skid velocity along its flat forward, studs/s
	climb: number?, -- studs/s the walker is being lifted (climb assist); legs step at this pace
	yawRate: number, -- rad/s, + = turning left
	occupied: boolean,
	topSpeed: number,
	turnRate: number,
	time: number, -- seconds, any monotonic clock
}

export type Footfall = { foot: Side, strength: number }

export type State = {
	rig: Rig,
	phase: number,
	rate: number, -- cycles per second
	feet: { [Side]: Foot },
	weight: number, -- 0..1 gait weight for the body overlays
	ground: number, -- larger of the two hips' ground speeds
	forward: number,
	yawRate: number,
	accel: number, -- smoothed forward acceleration
	idle: number, -- 0..1 idle amplitude
	hatch: number, -- 0 closed .. 1 open
	time: number,
	topSpeed: number,
	turnRate: number,
	shiftStart: number?, -- time the current weight shift began
	shiftSide: number,
	nextShift: number?,
	-- Unclamped channel values from the last pose, for tests: [bone][channel].
	raw: { [string]: { [string]: number } },
}

local function smoothstep(u: number): number
	u = math.clamp(u, 0, 1)
	return u * u * (3 - 2 * u)
end

local function lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

local function toePitch(u: number): number
	for index = 2, #TOE_KEYS do
		local a, b = TOE_KEYS[index - 1], TOE_KEYS[index]
		if u <= b[1] then
			return lerp(a[2], b[2], smoothstep((u - a[1]) / (b[1] - a[1])))
		end
	end
	return 0
end

-- Angle from vertical of the segment from `top` down to `bottom`; + when it leans forward (-Z).
local function segmentAngle(top: Vector3, bottom: Vector3): number
	return math.atan2(-(bottom.Z - top.Z), top.Y - bottom.Y)
end

-- Builds the rig from rest pivots in vehicle space, keyed by bone name.
function MechGait.rig(pivots: { [string]: Vector3 }): Rig
	local legs: { Leg } = {}
	for _, side: Side in { "L", "R" } :: { Side } do
		local hip = assert(pivots["thigh_" .. side], "rig needs thigh_" .. side)
		local knee = assert(pivots["shin_" .. side], "rig needs shin_" .. side)
		local ankle = assert(pivots["foot_" .. side], "rig needs foot_" .. side)
		table.insert(legs, {
			side = side,
			hip = hip,
			knee = knee,
			ankle = ankle,
			thigh = (knee - hip).Magnitude,
			shin = (ankle - knee).Magnitude,
			thighRest = segmentAngle(hip, knee),
			shinRest = segmentAngle(knee, ankle),
			offset = if side == "L" then 0 else 0.5,
		})
	end
	return {
		pelvis = assert(pivots.pelvis, "rig needs pelvis"),
		legs = legs,
		scale = (legs[1].thigh + legs[1].shin) / MechGait.REFERENCE_LEG,
	}
end

local function newFoot(): Foot
	return { z = 0, lift = 0, swinging = false, liftoff = 0, toe = 0, speed = 0 }
end

-- A parked, empty mech: rest pose, hatch open, phase in a double-support window.
function MechGait.new(rig: Rig): State
	return {
		rig = rig,
		phase = 0.05,
		rate = 0,
		feet = { L = newFoot(), R = newFoot() },
		weight = 0,
		ground = 0,
		forward = 0,
		yawRate = 0,
		accel = 0,
		idle = 0,
		hatch = 1,
		time = 0,
		topSpeed = 18,
		turnRate = 0.7,
		shiftStart = nil,
		shiftSide = 1,
		nextShift = nil,
		raw = {},
	}
end

local function inDoubleSupport(phase: number): boolean
	return phase % 0.5 < 0.1
end

-- Advances the walk by dt seconds. Returns the heel strikes that happened in this step.
function MechGait.step(state: State, input: Input, dt: number): { Footfall }
	dt = math.clamp(dt, 0, 0.1)
	local footfalls: { Footfall } = {}
	if dt <= 0 then
		return footfalls
	end
	local scale = state.rig.scale
	local DUTY, STEP, CYCLE = MechGait.DUTY, MechGait.STEP * scale, MechGait.CYCLE * scale
	local slip = SLIP * scale

	local v = input.forward
	local climb = input.climb or 0
	if climb > math.abs(v) then
		v = climb
	end
	local omega = input.yawRate
	state.time = input.time
	state.topSpeed = math.max(input.topSpeed, 1)
	state.turnRate = math.max(input.turnRate, 0.01)
	state.accel += ((v - state.forward) / dt - state.accel) * (1 - math.exp(-dt / ACCEL_TAU))
	state.forward = v
	state.yawRate = omega

	-- Ground speed under each hip.
	local legs = state.rig.legs
	local g = 0
	for _, leg in legs do
		local foot = state.feet[leg.side]
		foot.speed = v - omega * leg.hip.X
		g = math.max(g, math.abs(foot.speed))
	end
	state.ground = g

	-- Moving: step at the speed's cadence. Stopped: keep stepping until both feet are back under
	-- the hips, then park at the next double-support window.
	local rate = 0
	if g > MechGait.MOVING then
		rate = math.max(g / CYCLE, MechGait.MIN_RATE)
	else
		local settled = inDoubleSupport(state.phase)
		for _, foot in state.feet do
			settled = settled and not foot.swinging and math.abs(foot.z) <= MechGait.SETTLED * scale
		end
		rate = if settled then 0 else MechGait.MIN_RATE
	end
	state.rate = rate

	local before = state.phase
	local after = before + rate * dt
	if after >= 1 then
		after -= 1
	end
	state.phase = after
	local wrapped = after < before
	local strikes = {
		L = wrapped,
		R = (before < 0.5 and after >= 0.5) or (wrapped and after >= 0.5),
	}

	for _, leg in legs do
		local foot = state.feet[leg.side]
		local p = (after - leg.offset) % 1
		if p < DUTY then
			if foot.swinging then
				foot.swinging = false -- landed where the swing aimed
			end
			foot.z = math.clamp(foot.z - foot.speed * dt, -slip, slip)
			foot.lift = 0
			foot.toe = 0
		else
			if not foot.swinging then
				foot.swinging = true
				foot.liftoff = foot.z
			end
			local u = (p - DUTY) / (1 - DUTY)
			-- Land half the coming stance's travel ahead, so the stance centers under the hip.
			local land = 0
			if rate > 0 then
				local stance = DUTY / rate
				local travel = foot.speed * stance + 0.5 * state.accel * stance * stance
				land = math.clamp(travel, -STEP, STEP) / 2
			end
			foot.z = lerp(foot.liftoff, land, smoothstep(u))
			local height = math.clamp(math.abs(land - foot.liftoff) / (6 * scale), 0.35, 1)
			foot.lift = MechGait.LIFT * scale * height * math.sin(math.pi * u)
			foot.toe = toePitch(u)
		end
	end

	state.weight += (math.clamp(g / FULL_GAIT, 0, 1) - state.weight) * (1 - math.exp(-dt / W_TAU))

	local idleTarget = if input.occupied then 1 else 0
	state.idle = math.clamp(state.idle + math.sign(idleTarget - state.idle) * dt / IDLE_RAMP, 0, 1)
	local hatchTarget = if input.occupied then 0 else 1
	state.hatch =
		math.clamp(state.hatch + math.sign(hatchTarget - state.hatch) * dt / HATCH_TIME, 0, 1)

	-- Weight shifts every 6-10 s while standing occupied.
	if input.occupied then
		local now = input.time
		if not state.nextShift then
			state.nextShift = now + 6 + math.random() * 4
		end
		if not state.shiftStart and now >= (state.nextShift :: number) then
			state.shiftStart = now
			state.shiftSide = if math.random() < 0.5 then -1 else 1
		end
		if state.shiftStart and now - state.shiftStart > SHIFT_EASE * 2 + SHIFT_HOLD then
			state.shiftStart = nil
			state.nextShift = now + 6 + math.random() * 4
		end
	else
		state.shiftStart = nil
		state.nextShift = nil
	end

	if state.weight > 0.3 then
		local strength = state.weight * (0.5 + 0.5 * math.min(g / state.topSpeed, 1))
		for _, side: Side in { "L", "R" } :: { Side } do
			if strikes[side] then
				table.insert(footfalls, { foot = side, strength = strength })
			end
		end
	end
	return footfalls
end

-- The ground point under a foot, vehicle space (for dust and sounds).
function MechGait.footPoint(state: State, side: Side): Vector3
	for _, leg in state.rig.legs do
		if leg.side == side then
			return Vector3.new(leg.ankle.X, 0, leg.ankle.Z - state.feet[side].z)
		end
	end
	error("no foot " .. side)
end

local function shiftOffset(state: State): number
	local start = state.shiftStart
	if not start then
		return 0
	end
	local e = state.time - start
	local ease = if e < SHIFT_EASE
		then smoothstep(e / SHIFT_EASE)
		elseif e < SHIFT_EASE + SHIFT_HOLD then 1
		else 1 - smoothstep((e - SHIFT_EASE - SHIFT_HOLD) / SHIFT_EASE)
	return SHIFT * state.shiftSide * ease
end

-- Two-bone IK in the leg's plane. `down` and `forward` locate the target from the hip; returns the
-- thigh and shin angles from vertical (+ = forward), knee bent forward.
local function solveLeg(leg: Leg, down: number, forward: number): (number, number)
	local reach =
		math.min(math.sqrt(down * down + forward * forward), 0.98 * (leg.thigh + leg.shin))
	local a, b = leg.thigh, leg.shin
	local toTarget = math.atan2(forward, down)
	local atHip = math.acos(math.clamp((a * a + reach * reach - b * b) / (2 * a * reach), -1, 1))
	local atKnee = math.acos(math.clamp((a * a + b * b - reach * reach) / (2 * a * b), -1, 1))
	local thigh = toTarget + atHip
	return thigh, thigh - (math.pi - atKnee)
end

-- Motor6D Transforms for the current state, by bone name. Values are clamped to LIMITS; the
-- unclamped ones are kept in state.raw.
function MechGait.pose(state: State): { [string]: CFrame }
	local raw: { [string]: { [string]: number } } = {}
	state.raw = raw
	local function channel(bone: string, name: string, value: number): number
		raw[bone] = raw[bone] or {}
		raw[bone][name] = value
		local limit = MechGait.LIMITS[bone] and MechGait.LIMITS[bone][name]
		return if limit then math.clamp(value, limit[1], limit[2]) else value
	end

	local w = state.weight
	local phase = state.phase
	local still = state.idle * (1 - w)
	local breath = TAU * state.time / BREATH_PERIOD
	local swing = TAU * (phase - 0.05)
	local stride = math.cos(TAU * phase)

	local bob = -BOB / 2 + BOB / 2 * math.cos(2 * TAU * (phase - 0.3))
	bob -= DIP * math.max(0, 1 - (phase % 0.5) / 0.08) ^ 2
	-- Translations are in reference-leg studs (as are their limits), scaled to this rig after.
	local scale = state.rig.scale
	local pelvisY = scale
		* channel("pelvis", "ty", w * bob + still * (-0.15 - 0.15 * math.sin(breath)))
	local pelvisX = scale
		* channel("pelvis", "tx", -w * SWAY * math.sin(swing) + still * shiftOffset(state))
	local pelvisRoll = channel("pelvis", "z", -w * ROLL * math.sin(swing))
	local lead = TURN_LEAD * math.clamp(state.yawRate / state.turnRate, -1, 1)
	local pelvisYaw = channel("pelvis", "y", -w * PELVIS_YAW * stride + lead)
	local pelvisRotation = CFrame.Angles(0, pelvisYaw, 0) * CFrame.Angles(0, 0, pelvisRoll)
	local pelvisT = CFrame.new(pelvisX, pelvisY, 0) * pelvisRotation

	local lean = math.clamp(
		-LEAN_SPEED * state.forward / state.topSpeed
			- LEAN_ACCEL * math.clamp(state.accel / 10, -1, 1),
		rad(-7),
		rad(1.5) -- set when OG had a back ladder: further back pushed the deck edge into it
	)
	local torsoPitch = channel("torso", "x", w * lean + still * rad(0.5) * math.sin(breath + 0.6))
	local torsoYaw = channel("torso", "y", w * TORSO_YAW * stride)

	local poses: { [string]: CFrame } = {
		pelvis = pelvisT,
		torso = CFrame.Angles(torsoPitch, torsoYaw, 0),
		hatch = CFrame.Angles(channel("hatch", "x", HATCH_OPEN * smoothstep(state.hatch)), 0, 0),
	}

	local breathArm = still * rad(2) * (0.5 + 0.5 * math.sin(breath))
	for _, side in { "L", "R" } do
		local sign = if side == "L" then -1 else 1
		local shoulder = channel("upperArm_" .. side, "x", sign * w * ARM_SWING * stride)
		local elbow = w * (ELBOW + 0.4 * math.max(0, shoulder)) + breathArm
		poses["upperArm_" .. side] = CFrame.Angles(shoulder, 0, 0)
		poses["foreArm_" .. side] = CFrame.Angles(channel("foreArm_" .. side, "x", elbow), 0, 0)
	end

	-- Legs: place each ankle on its foot target, in the hip's frame after the pelvis moved.
	local pelvisFrame = CFrame.new(state.rig.pelvis) * pelvisT
	for _, leg in state.rig.legs do
		local foot = state.feet[leg.side]
		local target = Vector3.new(leg.ankle.X, leg.ankle.Y + foot.lift, leg.ankle.Z - foot.z)
		local hipFrame = pelvisFrame * CFrame.new(leg.hip - state.rig.pelvis)
		local d = hipFrame:PointToObjectSpace(target)
		local spread = math.atan2(d.X, -d.Y)
		local thighAbs, shinAbs = solveLeg(leg, math.sqrt(d.X * d.X + d.Y * d.Y), -d.Z)
		local hipX = channel("thigh_" .. leg.side, "x", thighAbs - leg.thighRest)
		local hipZ = channel("thigh_" .. leg.side, "z", spread)
		local kneeX =
			channel("shin_" .. leg.side, "x", (shinAbs - thighAbs) - (leg.shinRest - leg.thighRest))
		local thighT = CFrame.Angles(0, 0, hipZ) * CFrame.Angles(hipX, 0, 0)
		local shinT = CFrame.Angles(kneeX, 0, 0)
		-- The foot stays level with the ground (plus its toe pitch) whatever the leg above does.
		local above = pelvisRotation * thighT * shinT
		local footT = above:Inverse() * CFrame.Angles(foot.toe, 0, 0)
		local fx, _, fz = footT:ToEulerAnglesXYZ()
		channel("foot_" .. leg.side, "x", fx)
		channel("foot_" .. leg.side, "z", fz)
		poses["thigh_" .. leg.side] = thighT
		poses["shin_" .. leg.side] = shinT
		poses["foot_" .. leg.side] = footT
	end
	return poses
end

-- Hydraulics: a bone with `aim` (a barrel or a rod) turns about its pivot so the line from its
-- pivot to the aimed bone's pivot keeps the direction it has in the rest pose. Pair a barrel and a
-- rod that aim at each other, on bones either side of a joint, and the rod slides in the barrel as
-- the joint moves. `bones` lists every bone, parents first; `poses` holds the gait's Transforms
-- and gains one for each aiming bone.
export type AimBone = { name: string, parent: string?, pivot: Vector3, aim: string? }

-- The rotation that turns unit vector `from` onto unit vector `to`.
local function turn(from: Vector3, to: Vector3): CFrame
	local axis = from:Cross(to)
	local sin = axis.Magnitude
	if sin < 1e-6 then
		return CFrame.new()
	end
	return CFrame.fromAxisAngle(axis / sin, math.atan2(sin, from:Dot(to)))
end

function MechGait.aim(bones: { AimBone }, poses: { [string]: CFrame })
	local pivots: { [string]: Vector3 } = {}
	local frames: { [string]: CFrame } = {} -- vehicle space, posed
	local function unturned(bone: AimBone): CFrame
		local parentFrame = if bone.parent then frames[bone.parent] else CFrame.new()
		local parentPivot = if bone.parent then pivots[bone.parent] else Vector3.new()
		return parentFrame * CFrame.new(bone.pivot - parentPivot)
	end
	for _, bone in bones do
		pivots[bone.name] = bone.pivot
		frames[bone.name] = unturned(bone) * (poses[bone.name] or CFrame.new())
	end
	for _, bone in bones do
		local target = bone.aim and frames[bone.aim]
		if target then
			local frame = unturned(bone)
			local rest = (pivots[bone.aim :: string] - bone.pivot).Unit
			local now = frame:VectorToObjectSpace((target.Position - frame.Position).Unit)
			poses[bone.name] = turn(rest, now)
		end
	end
end

-- A steering wheel's Transform: a turn about `axis` (rest pose, vehicle space) that follows the
-- walker's yaw rate, to WHEEL_LOCK at the full turn rate. Turning left turns the wheel
-- counterclockwise as seen from the tip of `axis`.
MechGait.WHEEL_LOCK = rad(120)

function MechGait.steer(state: State, axis: Vector3): CFrame
	local lock = math.clamp(state.yawRate / state.turnRate, -1, 1)
	return CFrame.fromAxisAngle(axis.Unit, MechGait.WHEEL_LOCK * lock)
end

-- Wobble: a springy part (an antenna) tips about its pivot on a damped spring. Each heel strike
-- kicks it, speeding up tips it back and braking forward, and a turn sways it outward. Angles are
-- Transform angles about X (+ tips an upright part's top back) and Z (+ tips it toward -X).
MechGait.WOBBLE_STIFFNESS = 70 -- 1/s^2: about 1.3 swings a second
MechGait.WOBBLE_DAMPING = 3 -- 1/s: rings for about 2 seconds
MechGait.WOBBLE_KICK = rad(60) -- rad/s added per heel strike at full strength
MechGait.WOBBLE_ACCEL = rad(6) -- lean at 10 studs/s^2 of acceleration
MechGait.WOBBLE_TURN = rad(5) -- lean at the full turn rate
MechGait.WOBBLE_LIMIT = rad(15)

export type Wobble = { x: number, z: number, vx: number, vz: number }

function MechGait.newWobble(): Wobble
	return { x = 0, z = 0, vx = 0, vz = 0 }
end

-- Advances `wobble` by `dt` after a MechGait.step that returned `footfalls`; returns its
-- Transform.
function MechGait.wobble(wobble: Wobble, state: State, footfalls: { Footfall }, dt: number): CFrame
	for _, footfall in footfalls do
		local side = if footfall.foot == "L" then 1 else -1
		wobble.vx -= MechGait.WOBBLE_KICK * footfall.strength
		wobble.vz += side * 0.5 * MechGait.WOBBLE_KICK * footfall.strength
	end
	local leanX = MechGait.WOBBLE_ACCEL * math.clamp(state.accel / 10, -1, 1)
	local leanZ = -MechGait.WOBBLE_TURN * math.clamp(state.yawRate / state.turnRate, -1, 1)
	local k, c, limit = MechGait.WOBBLE_STIFFNESS, MechGait.WOBBLE_DAMPING, MechGait.WOBBLE_LIMIT
	-- Semi-implicit Euler in steps of at most 1/60 s, so a slow frame stays stable.
	local steps = math.max(1, math.ceil(dt * 60))
	local h = dt / steps
	for _ = 1, steps do
		wobble.vx += (k * (leanX - wobble.x) - c * wobble.vx) * h
		wobble.vz += (k * (leanZ - wobble.z) - c * wobble.vz) * h
		wobble.x += wobble.vx * h
		wobble.z += wobble.vz * h
		if math.abs(wobble.x) > limit then
			wobble.x, wobble.vx = math.sign(wobble.x) * limit, 0
		end
		if math.abs(wobble.z) > limit then
			wobble.z, wobble.vz = math.sign(wobble.z) * limit, 0
		end
	end
	return CFrame.Angles(wobble.x, 0, wobble.z)
end

return MechGait
