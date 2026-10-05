-- The day and night cycle. The server owns Lighting.ClockTime and writes it every frame; nothing
-- else may set it. One full day plus night lasts Config.DAY_NIGHT_CYCLE_SECONDS. Admin powers jump
-- the clock to morning or nightfall with a short fade, and the cycle carries on from there.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Clock = require(ReplicatedStorage.Shared.DayNight)
local Config = require(ReplicatedStorage.Shared.Config)

local DayNight = {}

-- The cycle was at anchorPhase at anchorTime (os.clock()). A jump moves the anchor to the target,
-- FADE seconds ahead, and fades the clock there in the meantime.
local anchorPhase = 0
local anchorTime = 0
local fade: { from: number, hours: number, start: number }? = nil

local function cycleClock(now: number): number
	return Clock.cycleClock(
		anchorPhase,
		anchorTime,
		now,
		Config.DAY_NIGHT_CYCLE_SECONDS,
		Config.DAY_NIGHT_DAY_FRACTION
	)
end

local function update()
	local now = os.clock()
	if fade then
		local alpha = (now - fade.start) / Config.DAY_NIGHT_FADE_SECONDS
		if alpha < 1 then
			Lighting.ClockTime = Clock.blend(fade.from, fade.hours, alpha)
			return
		end
		fade = nil
	end
	Lighting.ClockTime = cycleClock(now)
end

function DayNight.clock(): number
	return Lighting.ClockTime
end

function DayNight.isNight(): boolean
	return Clock.isNight(Lighting.ClockTime)
end

-- Fades to just after sunrise (night = false) or just after dusk (night = true). Pressed again
-- mid-fade, the new fade starts from wherever the clock is.
function DayNight.jumpTo(night: boolean)
	local target = if night then Config.DAY_NIGHT_NIGHT_CLOCK else Config.DAY_NIGHT_DAY_CLOCK
	local from = Lighting.ClockTime
	local now = os.clock()
	anchorPhase = Clock.phaseAt(target, Config.DAY_NIGHT_DAY_FRACTION)
	anchorTime = now + Config.DAY_NIGHT_FADE_SECONDS
	fade = { from = from, hours = Clock.jumpHours(from, target), start = now }
end

function DayNight.start()
	assert(Config.DAY_NIGHT_CYCLE_SECONDS > 0, "DAY_NIGHT_CYCLE_SECONDS must be positive")
	assert(
		Config.DAY_NIGHT_DAY_FRACTION > 0 and Config.DAY_NIGHT_DAY_FRACTION < 1,
		"DAY_NIGHT_DAY_FRACTION must be between 0 and 1"
	)
	assert(Config.DAY_NIGHT_FADE_SECONDS > 0, "DAY_NIGHT_FADE_SECONDS must be positive")
	anchorPhase = Clock.phaseAt(Config.DAY_NIGHT_START_CLOCK, Config.DAY_NIGHT_DAY_FRACTION)
	anchorTime = os.clock()
	Lighting.ClockTime = Config.DAY_NIGHT_START_CLOCK
	RunService.Heartbeat:Connect(update)
end

return DayNight
