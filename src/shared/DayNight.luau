-- Day and night clock math: pure, no services, so Lune can load it for tests.
--
-- A cycle's phase runs 0..1: 0 is dawn (ClockTime 6), `dayFraction` is dusk (ClockTime 18), and 1
-- wraps back to dawn. Day (6..18) takes `dayFraction` of the cycle; night (18..6) takes the rest.

local DayNight = {}

local DAWN = 6
local DUSK = 18

-- ClockTime (0..24) at a cycle phase. Any phase works; it wraps.
function DayNight.clockAt(phase: number, dayFraction: number): number
	local p = phase % 1
	if p < dayFraction then
		return DAWN + 12 * p / dayFraction
	end
	return (DUSK + 12 * (p - dayFraction) / (1 - dayFraction)) % 24
end

-- Cycle phase (0..1) at a ClockTime. Inverse of clockAt.
function DayNight.phaseAt(clock: number, dayFraction: number): number
	local c = clock % 24
	if c >= DAWN and c < DUSK then
		return (c - DAWN) / 12 * dayFraction
	end
	return dayFraction + ((c - DUSK) % 24) / 12 * (1 - dayFraction)
end

function DayNight.isNight(clock: number): boolean
	local c = clock % 24
	return c < DAWN or c >= DUSK
end

-- Hours to move the clock from `from` to `to`. Crossing between day and night always runs forward
-- (the sun sets or rises on the way). Within the same phase it takes the shorter way, so the
-- clock never passes through the other phase.
function DayNight.jumpHours(from: number, to: number): number
	local forward = (to - from) % 24
	if DayNight.isNight(from) ~= DayNight.isNight(to) then
		return forward
	end
	return if forward <= 12 then forward else forward - 24
end

-- ClockTime `alpha` (0..1, clamped, eased) of the way through a jump of `hours` from `from`.
function DayNight.blend(from: number, hours: number, alpha: number): number
	local t = math.clamp(alpha, 0, 1)
	local eased = t * t * (3 - 2 * t)
	return (from + hours * eased) % 24
end

-- ClockTime `now` seconds into a running cycle that was at `anchorPhase` at `anchorTime`.
function DayNight.cycleClock(
	anchorPhase: number,
	anchorTime: number,
	now: number,
	cycleSeconds: number,
	dayFraction: number
): number
	return DayNight.clockAt(anchorPhase + (now - anchorTime) / cycleSeconds, dayFraction)
end

return DayNight
