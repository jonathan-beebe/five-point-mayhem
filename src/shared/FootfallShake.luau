--!strict
-- MechCamera's heel-strike shake: a damped vertical sine per footfall, summed. Pure: no requires.
--
--   sum(shakes, now)  this frame's lift (studs) and pitch (radians), before the view's scale;
--                     drops the finished shakes from `shakes`
--
-- tools/tests/client_logic.luau compares it with the inline code it replaced.

local FootfallShake = {}

FootfallShake.LIFT = 0.12 -- studs at strength 1
FootfallShake.PITCH = math.rad(0.35)
FootfallShake.DECAY = 0.12 -- seconds
FootfallShake.FREQUENCY = 9 -- Hz
FootfallShake.LENGTH = 0.4 -- seconds

-- One heel strike: os.clock() when it landed, and MechMotion's footfall strength.
export type Shake = { start: number, strength: number }

function FootfallShake.sum(shakes: { Shake }, now: number): (number, number)
	local lift, pitch = 0, 0
	for index = #shakes, 1, -1 do
		local each = shakes[index]
		local t = now - each.start
		if t > FootfallShake.LENGTH then
			table.remove(shakes, index)
		else
			local wave = each.strength
				* math.exp(-t / FootfallShake.DECAY)
				* math.sin(2 * math.pi * FootfallShake.FREQUENCY * t)
			lift += FootfallShake.LIFT * wave
			pitch += FootfallShake.PITCH * wave
		end
	end
	return lift, pitch
end

return table.freeze(FootfallShake)
