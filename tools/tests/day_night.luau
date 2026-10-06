-- Checks the day and night clock math (src/shared/DayNight.luau) outside Roblox.
-- Usage: lune run tools/tests/day_night.luau
--
-- For several day fractions, checks:
--   - phase 0 is dawn (6), the day fraction is dusk (18), and phases wrap
--   - phaseAt inverts clockAt, and the clock only runs forward through a cycle
--   - night takes the rest of the cycle
--   - isNight at the edges
--   - jumpHours runs forward across a sunrise or sunset and the shorter way within a phase,
--     so a same-phase jump never passes through the other phase
--   - blend hits its endpoints and clamps
--   - sample/jump: the clock is continuous across a fade's end, a jump pressed mid-fade starts
--     from the blended clock, and the fade is dropped once it has run

local Check = require("../lib/Check")
local Sandbox = require("../lib/Sandbox")

local DayNight = Sandbox.load("src/shared/DayNight.luau")

local check, near = Check.check, Check.isNear

-- Distance on the 24-hour clock face.
local function clockNear(a: number, b: number): boolean
	local d = math.abs(a - b) % 24
	return near(math.min(d, 24 - d), 0)
end

for _, f in { 0.5, 0.6, 0.25 } do
	local label = string.format("f=%.2f", f)
	local function clockIs(phase: number, expected: number)
		local got = DayNight.clockAt(phase, f)
		check(
			clockNear(got, expected),
			string.format("%s: clockAt(%.3f) = %.4f, want %.4f", label, phase, got, expected)
		)
	end
	clockIs(0, 6)
	clockIs(f, 18)
	clockIs(1, 6)
	clockIs(-1, 6)
	clockIs(-0.25, DayNight.clockAt(0.75, f))
	clockIs(f / 2, 12)
	if f == 0.5 then
		clockIs(0.75, 0)
	end

	for c = 0, 23.5, 0.5 do
		local phase = DayNight.phaseAt(c, f)
		check(phase >= 0 and phase < 1, string.format("%s: phaseAt(%.1f) = %.4f", label, c, phase))
		local back = DayNight.clockAt(phase, f)
		check(
			clockNear(back, c),
			string.format("%s: clockAt(phaseAt(%.1f)) = %.4f", label, c, back)
		)
	end

	-- Forward through a cycle: each step moves the clock forward a little, and the share of steps
	-- at night matches 1 - f.
	local STEPS = 10000
	local previous = DayNight.clockAt(0, f)
	local nightSteps = 0
	local forward = true
	for i = 1, STEPS do
		local clock = DayNight.clockAt((i - 0.5) / STEPS, f)
		local delta = (clock - previous) % 24
		if delta <= 0 or delta > 1 then
			forward = false
		end
		if DayNight.isNight(clock) then
			nightSteps += 1
		end
		previous = clock
	end
	check(forward, label .. ": the clock should run forward through a cycle")
	check(
		math.abs(nightSteps / STEPS - (1 - f)) < 1e-3,
		string.format("%s: night share %.4f, want %.4f", label, nightSteps / STEPS, 1 - f)
	)

	for _, target in { 7, 19 } do
		local back = DayNight.clockAt(DayNight.phaseAt(target, f), f)
		check(
			clockNear(back, target),
			string.format("%s: target %d lands at %.4f", label, target, back)
		)
	end

	check(
		clockNear(DayNight.cycleClock(0, 10, 160, 300, f), DayNight.clockAt(0.5, f)),
		label .. ": cycleClock half a cycle after the anchor"
	)
end

for _, case in
	{
		{ 5.99, true },
		{ 6, false },
		{ 17.99, false },
		{ 18, true },
		{ 0, true },
		{ 24, true },
	}
do
	check(
		DayNight.isNight(case[1]) == case[2],
		string.format("isNight(%.2f) should be %s", case[1], tostring(case[2]))
	)
end

for _, case in
	{
		{ 14, 19, 5 },
		{ 0, 7, 7 },
		{ 20, 7, 11 },
		{ 18.5, 7, 12.5 },
		{ 10, 7, -3 },
		{ 17, 7, -10 },
		{ 2, 19, -7 },
		{ 23, 19, -4 },
		{ 7, 7, 0 },
	}
do
	local from, to, want = case[1], case[2], case[3]
	local hours = DayNight.jumpHours(from, to)
	check(
		near(hours, want),
		string.format("jumpHours(%.1f, %.1f) = %.4f, want %.4f", from, to, hours, want)
	)
end

-- Every jump from each half hour: a same-phase jump stays in its phase the whole way, a
-- cross-phase jump runs forward, and every jump lands on its target.
for from = 0, 23.5, 0.5 do
	for _, to in { 7, 19, 0, 12, 6, 18 } do
		local hours = DayNight.jumpHours(from, to)
		local night = DayNight.isNight(from)
		if night == DayNight.isNight(to) then
			local stays = true
			for i = 0, 100 do
				if DayNight.isNight(DayNight.blend(from, hours, i / 100)) ~= night then
					stays = false
				end
			end
			check(stays, string.format("jump %.1f -> %d should stay in its phase", from, to))
		else
			check(hours >= 0, string.format("jump %.1f -> %d should run forward", from, to))
		end
		check(
			clockNear(DayNight.blend(from, hours, 1), to),
			string.format("jump %.1f -> %d should land on the target", from, to)
		)
	end
end

check(near(DayNight.blend(14, 5, 0), 14), "blend at 0 is the start")
check(near(DayNight.blend(14, 5, 1), 19), "blend at 1 is the end")
check(near(DayNight.blend(14, 5, -1), 14), "blend clamps below 0")
check(near(DayNight.blend(14, 5, 2), 19), "blend clamps above 1")
check(near(DayNight.blend(14, 5, 0.5), 16.5), "blend at 0.5 is halfway")
check(near(DayNight.blend(23, 2, 1), 1), "blend wraps past midnight")
check(near(DayNight.blend(1, -3, 1), 22), "blend wraps backwards past midnight")

-- The fade state machine, with the shipped settings.
local SETTINGS = {
	cycleSeconds = 300,
	dayFraction = 0.5,
	fadeSeconds = 3,
	dayClock = 7,
	nightClock = 19,
}
local FADE = SETTINGS.fadeSeconds

do
	local state = DayNight.begin(14, 100, SETTINGS)
	local clock = DayNight.sample(state, 100, SETTINGS)
	check(near(clock, 14), string.format("begin shows its clock, got %.4f", clock))

	-- NIGHT at t = 160: the fade runs from the displayed clock to 19, then the cycle carries on.
	local shown
	shown, state = DayNight.sample(state, 160, SETTINGS)
	state = DayNight.jump(shown, true, 160, SETTINGS)
	check(near(DayNight.sample(state, 160, SETTINGS), shown), "a jump starts from the shown clock")
	local before = DayNight.sample(state, 160 + FADE - 1e-4, SETTINGS)
	local after, cleared = DayNight.sample(state, 160 + FADE + 1e-4, SETTINGS)
	check(
		clockNear(before, 19) and math.abs(before - after) < 1e-3,
		string.format("clock continuous across fade end: %.5f then %.5f", before, after)
	)
	check(state.fade ~= nil, "fade set during a jump")
	check(cleared.fade == nil, "fade cleared after FADE seconds")
	local _, still = DayNight.sample(state, 160 + FADE - 1e-4, SETTINGS)
	check(still.fade ~= nil, "fade kept until FADE seconds")
	local later = DayNight.sample(cleared, 160 + FADE + 30, SETTINGS)
	check(
		clockNear(later, 19 + 30 / 150 * 12),
		string.format("cycle carries on from the target, got %.4f", later)
	)

	-- DAY pressed halfway through the NIGHT fade starts from the blended clock.
	local mid = 160 + FADE / 2
	local blended = DayNight.sample(state, mid, SETTINGS)
	check(
		near(blended, DayNight.blend(shown, DayNight.jumpHours(shown, 19), 0.5)),
		"alpha 0.5 shows the blended clock"
	)
	local again = DayNight.jump(blended, false, mid, SETTINGS)
	check(near(again.fade.from, blended), "a re-press mid-fade starts from the blended clock")
	check(
		near(DayNight.sample(again, mid, SETTINGS), blended),
		"no jump in the clock at the re-press"
	)
	check(
		clockNear(DayNight.sample(again, mid + FADE, SETTINGS), 7),
		"the re-press lands on its target"
	)
end

Check.finish()
