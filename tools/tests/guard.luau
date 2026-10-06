-- Checks src/server/systems/util/Guard outside Roblox, with a recording `warn`, a fake clock and a
-- fake `task`.
-- Usage: lune run tools/tests/guard.luau
--
--   - Guard.run returns ok and the result (or the error); a failure warns
--     "[Mayhem <tag>] <first line of the error>", then the rest of the error and the traceback;
--     the rate limit keys on the first line, so the same error from another stack is held back
--   - Guard.warn rate-limits: an identical tag and message warns once per REPEAT_SECONDS, and the
--     next warning counts the ones it held back; a different tag or message warns at once
--   - Guard keeps at most MAX_TRACKED keys past their REPEAT_SECONDS: once it tracks more, keys
--     older than REPEAT_SECONDS are dropped
--   - Guard.loop spawns a loop that waits `interval` before each pass and runs every pass through
--     Guard.run: a pass that throws warns, and the next pass still runs

local Check = require("../lib/Check")
local Sandbox = require("../lib/Sandbox")

local check, equal = Check.check, Check.equal

local warnings: { string } = {}
local clock = 0
local spawned: { () -> () } = {}
local waits: { number } = {}
local STOP = "stop the fake loop"
local waitLimit = 0

local Guard = Sandbox.load("src/server/systems/util/Guard.luau", {
	warn = function(...)
		table.insert(warnings, table.concat({ ... }, " "))
	end,
	os = setmetatable({
		clock = function()
			return clock
		end,
	}, { __index = os }),
	task = {
		spawn = function(fn)
			table.insert(spawned, fn)
		end,
		wait = function(seconds)
			table.insert(waits, seconds)
			if #waits > waitLimit then
				error(STOP, 0)
			end
		end,
	},
})

Check.section("Guard.run")
do
	local ok, result = Guard.run("test ok", function(a, b)
		return a + b
	end, 2, 3)
	check(ok == true and result == 5, "a pass returns true and its result")
	equal(#warnings, 0, "no warning for a pass")

	local function failingInner()
		error("boom\nsecond line", 0)
	end
	local function failingOuter()
		failingInner()
	end
	ok, result = Guard.run("test fail", failingOuter)
	check(ok == false and result == "boom\nsecond line", "a failure returns false and the error")
	local first = string.match(warnings[1] or "", "^[^\n]*")
	equal(first, "[Mayhem test fail] boom", "the first line names the tag and the error's first")
	check(
		string.find(warnings[1] or "", "\nsecond line\n", 1, true) ~= nil,
		"the rest of the error follows: " .. tostring(warnings[1])
	)
	check(
		string.find(warnings[1] or "", "function failingInner", 1, true) ~= nil
			and string.find(warnings[1] or "", "function failingOuter", 1, true) ~= nil,
		"the traceback follows: " .. tostring(warnings[1])
	)

	-- The same error from a different stack (another line, another caller): one warning.
	Guard.run("test fail", failingInner)
	equal(#warnings, 1, "the same first line inside REPEAT_SECONDS: held back")
end

Check.section("Guard.warn: rate limit")
do
	table.clear(warnings)
	clock = 1000
	Guard.warn("spam", "same")
	clock += 1
	Guard.warn("spam", "same")
	Guard.warn("spam", "same")
	equal(#warnings, 1, "identical warnings inside REPEAT_SECONDS: one")
	Guard.warn("spam", "other")
	Guard.warn("eggs", "same")
	equal(#warnings, 3, "a different message or tag warns at once")
	clock = 1000 + Guard.REPEAT_SECONDS
	Guard.warn("spam", "same")
	equal(#warnings, 4, "after REPEAT_SECONDS it warns again")
	equal(warnings[4], "[Mayhem spam] same (2 more since the last)", "and counts the held back")
	clock += Guard.REPEAT_SECONDS
	Guard.warn("spam", "same")
	equal(warnings[5], "[Mayhem spam] same", "nothing held back: no count")
end

Check.section("Guard.loop: a pass that throws does not stop the loop")
do
	table.clear(warnings)
	clock = 5000
	local passes = 0
	Guard.loop("loop", 0.25, function()
		passes += 1
		if passes == 1 then
			error("first pass fails", 0)
		end
	end)
	equal(#spawned, 1, "the loop is spawned")
	waitLimit = 3
	local ok, err = pcall(spawned[1])
	check(not ok and err == STOP, "the loop runs until the fake wait stops it: " .. tostring(err))
	equal(passes, 3, "every pass after the failing one runs")
	equal(waits[1], 0.25, "waits the interval before a pass")
	equal(#warnings, 1, "one warning")
	equal(
		string.match(warnings[1] or "", "^[^\n]*"),
		"[Mayhem loop] first pass fails",
		"the warning"
	)
end

Check.section("Guard.warn: tracked keys are bounded")
do
	table.clear(warnings)
	clock = 10000
	check(type(Guard.MAX_TRACKED) == "number", "Guard.MAX_TRACKED is set")
	local limit = Guard.MAX_TRACKED or 256
	for index = 1, limit * 2 do
		Guard.warn("many", "message " .. index)
	end
	check(Guard.tracked and Guard.tracked() >= limit * 2, "fresh keys are all kept")
	clock += Guard.REPEAT_SECONDS
	Guard.warn("many", "one more")
	check(
		Guard.tracked ~= nil and Guard.tracked() <= limit,
		"keys older than REPEAT_SECONDS are dropped: "
			.. tostring(Guard.tracked and Guard.tracked())
	)
	table.clear(warnings)
	Guard.warn("many", "one more")
	equal(#warnings, 0, "a key just warned is kept (still held back)")
	Guard.warn("many", "message 1")
	equal(#warnings, 1, "a dropped key warns again")
end

Check.finish()
