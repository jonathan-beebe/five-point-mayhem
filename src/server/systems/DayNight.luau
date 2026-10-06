-- The day and night cycle. The server owns Lighting.ClockTime and writes it every frame; nothing
-- else may set it. One full day plus night lasts Config.DAY_NIGHT_CYCLE_SECONDS. Admin powers jump
-- the clock to morning or nightfall with a short fade, and the cycle carries on from there. The
-- clock math and fade state live in Shared.DayNight; times are time() (game seconds).

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Clock = require(ReplicatedStorage.Shared.DayNight)
local Config = require(ReplicatedStorage.Shared.Config)

local DayNight = {}

local SETTINGS: Clock.Settings = {
	cycleSeconds = Config.DAY_NIGHT_CYCLE_SECONDS,
	dayFraction = Config.DAY_NIGHT_DAY_FRACTION,
	fadeSeconds = Config.DAY_NIGHT_FADE_SECONDS,
	dayClock = Config.DAY_NIGHT_DAY_CLOCK,
	nightClock = Config.DAY_NIGHT_NIGHT_CLOCK,
}

local state: Clock.State = Clock.begin(Config.DAY_NIGHT_START_CLOCK, 0, SETTINGS)

local function update()
	local clock
	clock, state = Clock.sample(state, time(), SETTINGS)
	Lighting.ClockTime = clock
end

-- Fades to just after sunrise (night = false) or just after dusk (night = true). Pressed again
-- mid-fade, the new fade starts from wherever the clock is.
function DayNight.jumpTo(night: boolean)
	local now = time()
	local clock
	clock, state = Clock.sample(state, now, SETTINGS)
	state = Clock.jump(clock, night, now, SETTINGS)
end

function DayNight.start()
	assert(Config.DAY_NIGHT_CYCLE_SECONDS > 0, "DAY_NIGHT_CYCLE_SECONDS must be positive")
	assert(
		Config.DAY_NIGHT_DAY_FRACTION > 0 and Config.DAY_NIGHT_DAY_FRACTION < 1,
		"DAY_NIGHT_DAY_FRACTION must be between 0 and 1"
	)
	assert(Config.DAY_NIGHT_FADE_SECONDS > 0, "DAY_NIGHT_FADE_SECONDS must be positive")
	state = Clock.begin(Config.DAY_NIGHT_START_CLOCK, time(), SETTINGS)
	Lighting.ClockTime = Config.DAY_NIGHT_START_CLOCK
	RunService.Heartbeat:Connect(update)
end

return DayNight
