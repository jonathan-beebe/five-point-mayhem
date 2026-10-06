--!strict
-- The numbers of client NukeStrike that follow time or distance: the bomb's fall, the blast
-- wave's ring, and the camera shake. The wave follows Config.nukeWaveRadius over
-- Config.NUKE_WAVE_SECONDS, the timing the server (Admin) kills players on. Pure: Config only.
--
--   bomb(t)                    height above the ground and spin at fall progress t (0..1)
--   wave(elapsed)              the ring at `elapsed` seconds: radius, height, segment size, colour
--                              and transparency
--   waveAngle(index)           a segment's angle round the ring
--   shakeStrength(distance)    the shake's strength (0.3..1) at a camera distance from impact
--   shakeAngle(strength, t)    the jolt's bound (radians) at shake progress t (0..1)
--
-- tools/tests/client_logic.luau compares each with the inline code it replaced.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local NukeMath = {}

local rgb = Color3.fromRGB

NukeMath.BOMB_BOTTOM = 34 -- studs from the body's center down to the tip of the nose
NukeMath.DROP_HEIGHT = 1400 -- studs above the ground at release
NukeMath.DROP_SPIN = math.rad(200) -- turn about its axis over the whole fall

NukeMath.WAVE_SEGMENTS = 72
NukeMath.WAVE_HEIGHT = table.freeze({ 45, 10 }) -- studs, at impact and at the edge of the board
NukeMath.WAVE_HOT = rgb(255, 245, 210)
NukeMath.WAVE_COOL = rgb(255, 120, 40)

NukeMath.SHAKE_SECONDS = 3.5
NukeMath.SHAKE_ANGLE = math.rad(1.2) -- at strength 1
NukeMath.SHAKE_REACH = 1500 -- studs from impact where the shake bottoms out at 0.3

-- Accelerating like a falling body: height falls with t squared.
function NukeMath.bomb(t: number): (number, number)
	return NukeMath.BOMB_BOTTOM + NukeMath.DROP_HEIGHT * (1 - t * t), t * NukeMath.DROP_SPIN
end

export type Wave = {
	radius: number,
	height: number,
	size: Vector3,
	color: Color3,
	transparency: number,
}

function NukeMath.wave(elapsed: number): Wave
	local t = elapsed / Config.NUKE_WAVE_SECONDS
	local radius = math.max(Config.nukeWaveRadius(elapsed), 4)
	local height = NukeMath.WAVE_HEIGHT[1] + (NukeMath.WAVE_HEIGHT[2] - NukeMath.WAVE_HEIGHT[1]) * t
	return {
		radius = radius,
		height = height,
		size = Vector3.new(2 * math.pi * radius / NukeMath.WAVE_SEGMENTS * 1.15, height, 6),
		color = NukeMath.WAVE_HOT:Lerp(NukeMath.WAVE_COOL, math.min(t * 2, 1)),
		transparency = 0.1 + 0.85 * t,
	}
end

function NukeMath.waveAngle(index: number): number
	return index / NukeMath.WAVE_SEGMENTS * 2 * math.pi
end

function NukeMath.shakeStrength(distance: number): number
	return math.clamp(1 - 0.7 * distance / NukeMath.SHAKE_REACH, 0.3, 1)
end

-- Dies away with (1 - t) squared.
function NukeMath.shakeAngle(strength: number, t: number): number
	return NukeMath.SHAKE_ANGLE * strength * (1 - t) ^ 2
end

return table.freeze(NukeMath)
