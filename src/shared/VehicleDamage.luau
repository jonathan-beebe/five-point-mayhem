-- Crash damage for vehicles (pure: no requires, so `tools/tests/vehicle_damage.luau` loads it
-- under lune). Vehicles samples each driven vehicle's velocity every frame into a tracker; a sharp
-- loss of speed (`step`) is a crash, and `damage` turns its size into health lost.
--
-- Size is `bulk`: the vehicle's solid volume over BASE_VOLUME (a jeep is about 1). Bigger vehicles
-- have more health, and a lower threshold: they cannot shed a crash as a light car does, and a
-- crash past the threshold costs them more, in health and as a share of it.
--
-- A crash is an episode: it starts on a frame that loses at least START_LOSS studs/s (or
-- START_DECELERATION x dt, so a long frame needs more) and runs while the frames that follow keep
-- losing CONTINUE_LOSS (or CONTINUE_DECELERATION x dt), for up to IMPACT_TIME. Its result is the
-- sum of the horizontal and the vertical speed lost. Horizontal loss is speed lost along the
-- direction of travel; vertical loss is only a fall stopping (never a lift, never a climb slowing).

local VehicleDamage = {}

-- Size.
local BASE_VOLUME = 560 -- W x L x H, cubic studs, of bulk 1
local MIN_BULK = 0.2
local MAX_BULK = 50
-- Health: BASE_HEALTH x bulk ^ HEALTH_EXPONENT.
local BASE_HEALTH = 100
local HEALTH_EXPONENT = 0.25
-- Speed lost without harm: horizontal THRESHOLD x bulk ^ -THRESHOLD_EXPONENT; a landing
-- LANDING_SCALE times that, and at least LANDING_MIN (a walker's legs: WALKER_LANDING_MIN, so a
-- one-tier 12-stud drop, ~69 studs/s, is free and a 24-stud drop, ~97, hurts).
local THRESHOLD = 40
local THRESHOLD_EXPONENT = 0.3
local LANDING_SCALE = 1.25
local LANDING_MIN = 30
local WALKER_LANDING_MIN = 75
-- Damage: DAMAGE x bulk ^ BULK_EXPONENT x (speed lost past the thresholds) ^ SPEED_EXPONENT.
local DAMAGE = 0.3
local BULK_EXPONENT = 0.5
local SPEED_EXPONENT = 1.3
-- Crash detection, studs/s lost per frame (or per second, times the frame's dt).
local START_LOSS = 12
local START_DECELERATION = 700
local CONTINUE_LOSS = 3
local CONTINUE_DECELERATION = 175
local IMPACT_TIME = 0.2 -- seconds; longest episode
-- A wreck's blast radius: WRECK_RADIUS_BASE + WRECK_RADIUS_PER_ROOT_BULK x sqrt(bulk), clamped.
local WRECK_RADIUS_BASE = 6
local WRECK_RADIUS_PER_ROOT_BULK = 4
local WRECK_RADIUS_MIN = 10
local WRECK_RADIUS_MAX = 34

-- Bulk of a W x L x H vehicle; `override` (VehicleCatalog `bulk`) wins.
function VehicleDamage.bulk(w: number, l: number, h: number, override: number?): number
	return math.clamp(override or w * l * h / BASE_VOLUME, MIN_BULK, MAX_BULK)
end

function VehicleDamage.maxHealth(bulk: number): number
	return math.round(BASE_HEALTH * bulk ^ HEALTH_EXPONENT)
end

-- Horizontal and vertical speed a crash loses without harm. Walkers land on their legs.
function VehicleDamage.thresholds(bulk: number, walker: boolean?): (number, number)
	local horizontal = THRESHOLD * bulk ^ -THRESHOLD_EXPONENT
	local vertical = math.max(LANDING_SCALE * horizontal, LANDING_MIN)
	if walker then
		vertical = math.max(vertical, WALKER_LANDING_MIN)
	end
	return horizontal, vertical
end

-- Health a crash that lost `lossH` horizontal and `lossV` vertical studs/s takes.
function VehicleDamage.damage(bulk: number, lossH: number, lossV: number, walker: boolean?): number
	local horizontal, vertical = VehicleDamage.thresholds(bulk, walker)
	local excessH = math.max(0, lossH - horizontal)
	local excessV = math.max(0, lossV - vertical)
	if excessH == 0 and excessV == 0 then
		return 0
	end
	local excess = math.sqrt(excessH ^ 2 + excessV ^ 2)
	return DAMAGE * bulk ^ BULK_EXPONENT * excess ^ SPEED_EXPONENT
end

function VehicleDamage.wreckRadius(bulk: number): number
	return math.clamp(
		WRECK_RADIUS_BASE + WRECK_RADIUS_PER_ROOT_BULK * math.sqrt(bulk),
		WRECK_RADIUS_MIN,
		WRECK_RADIUS_MAX
	)
end

-- Crash detection ------------------------------------------------------------------------------

export type Tracker = {
	primed: boolean, -- has a previous sample
	x: number, -- previous velocity
	y: number,
	z: number,
	active: boolean, -- in an episode
	elapsed: number,
	sumH: number,
	sumV: number,
	startX: number, -- velocity before the episode
	startY: number,
	startZ: number,
}

function VehicleDamage.newTracker(): Tracker
	return {
		primed = false,
		x = 0,
		y = 0,
		z = 0,
		active = false,
		elapsed = 0,
		sumH = 0,
		sumV = 0,
		startX = 0,
		startY = 0,
		startZ = 0,
	}
end

-- Forgets the previous sample and any episode: call it whenever something other than a crash
-- sets the velocity (a shove, a teleport, a pod docking). The next sample only primes.
function VehicleDamage.clear(tracker: Tracker)
	tracker.primed = false
	tracker.active = false
end

-- Feeds one frame's velocity. Returns the speed an episode lost (horizontal, vertical) on the
-- frame it ends; nothing otherwise.
function VehicleDamage.step(
	tracker: Tracker,
	vx: number,
	vy: number,
	vz: number,
	dt: number
): (number?, number?)
	if not tracker.primed then
		tracker.primed = true
		tracker.x, tracker.y, tracker.z = vx, vy, vz
		return nil, nil
	end
	local px, py, pz = tracker.x, tracker.y, tracker.z
	tracker.x, tracker.y, tracker.z = vx, vy, vz

	-- Horizontal: speed lost along the previous direction of travel.
	local lossH = 0
	local flat = math.sqrt(px * px + pz * pz)
	if flat > 1e-6 then
		lossH = math.max(0, ((px - vx) * px + (pz - vz) * pz) / flat)
	end
	-- Vertical: a fall stopping, up to the falling speed there was.
	local lossV = math.clamp(vy - py, 0, math.max(0, -py))
	local loss = lossH + lossV

	if tracker.active then
		if loss < math.max(CONTINUE_LOSS, CONTINUE_DECELERATION * dt) then
			tracker.active = false
			return tracker.sumH, tracker.sumV
		end
		tracker.sumH += lossH
		tracker.sumV += lossV
		tracker.elapsed += dt
	elseif loss >= math.max(START_LOSS, START_DECELERATION * dt) then
		tracker.active = true
		tracker.elapsed = dt
		tracker.sumH, tracker.sumV = lossH, lossV
		tracker.startX, tracker.startY, tracker.startZ = px, py, pz
	else
		return nil, nil
	end
	if tracker.elapsed >= IMPACT_TIME then
		tracker.active = false
		return tracker.sumH, tracker.sumV
	end
	return nil, nil
end

return VehicleDamage
