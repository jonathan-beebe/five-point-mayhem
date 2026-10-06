--!strict
-- The per-frame arithmetic of client VehicleSounds: how an engine's smoothed speed, load bump and
-- fade level move each frame, a walker's speed and cadence targets, and a loop's pitch and volume
-- at a share of top speed. Pure: no requires. Tuning stays in SoundCatalog (VEHICLE, MECHS).
--
--   lerp(range, t)                                 range[1] at 0 to range[2] at 1
--   follow(smoothed, bump, target, alpha, load)    smoothed speed and bump after one frame
--   fade(level, on, dt, fadeIn, fadeOut)           the level after one frame, 0..1
--   mechTargets(ground, topSpeed, rate, cycle)     a walker's speed and cadence shares, 0..1
--   loop(loop, share, defaultCurve)                a loop's pitch and volume (before the level)
--
-- tools/tests/client_logic.luau compares each with the inline code it replaced.

local EngineEnvelope = {}

-- The fields of SoundCatalog.Loop read here.
export type Loop = { pitch: { number }, volume: { number }, curve: number? }

function EngineEnvelope.lerp(range: { number }, t: number): number
	return range[1] + (range[2] - range[1]) * t
end

-- `smoothed` follows `target` by `alpha` (MathUtil.rateAlpha); `bump` follows `load` while the
-- speed rises and 0 otherwise, by the same alpha.
function EngineEnvelope.follow(
	smoothed: number,
	bump: number,
	target: number,
	alpha: number,
	load: number
): (number, number)
	local previous = smoothed
	smoothed += (target - smoothed) * alpha
	bump += ((if smoothed > previous then load else 0) - bump) * alpha
	return smoothed, bump
end

-- Rises over `fadeIn` seconds while `on`, else falls over `fadeOut`.
function EngineEnvelope.fade(
	level: number,
	on: boolean,
	dt: number,
	fadeIn: number,
	fadeOut: number
): number
	if on then
		return math.min(1, level + dt / fadeIn)
	end
	return math.max(0, level - dt / fadeOut)
end

-- Ground speed and leg cadence as shares of top speed; `cycle` is the rig's stride
-- (MechGait.CYCLE * rig scale).
function EngineEnvelope.mechTargets(
	ground: number,
	topSpeed: number,
	rate: number,
	cycle: number
): (number, number)
	return math.clamp(ground / topSpeed, 0, 1), math.clamp(rate * cycle / topSpeed, 0, 1)
end

-- Pitch along the loop's curve (`defaultCurve` without one); volume linear in `share`.
function EngineEnvelope.loop(loop: Loop, share: number, defaultCurve: number): (number, number)
	return EngineEnvelope.lerp(loop.pitch, share ^ (loop.curve or defaultCurve)),
		EngineEnvelope.lerp(loop.volume, share)
end

return table.freeze(EngineEnvelope)
