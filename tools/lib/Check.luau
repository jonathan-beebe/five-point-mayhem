-- Assertions for the tests in tools/tests. Each test runs in its own process, so the tally lives
-- in this module.
--
-- Usage:
--   local Check = require("../lib/Check")
--   Check.check(a == b, "a should equal b")       -- prints "FAIL a should equal b" when false
--   Check.equal(got, 3, "seats")                  -- prints "FAIL seats: got 2, want 3"
--   Check.check(Check.isNear(x, 1, 0.05), "x ~1") -- isNear is a predicate; it counts nothing
--   Check.section("jeep")                         -- prints a header; resets the section's FAILs
--   Check.finish()                                -- "N checks, M failures"; exits 1 on a failure
--
-- `Check.printLimit` caps the FAIL lines printed per section (every failure still counts).

local process = require("@lune/process")

local Check = {}

Check.printLimit = math.huge

local checks = 0
local failures = 0
local sectionFailures = 0

function Check.check(ok: boolean, message: string)
	checks += 1
	if not ok then
		failures += 1
		sectionFailures += 1
		if sectionFailures <= Check.printLimit then
			print("FAIL " .. message)
		end
	end
end

function Check.equal(got: any, want: any, message: string)
	Check.check(
		got == want,
		string.format("%s: got %s, want %s", message, tostring(got), tostring(want))
	)
end

-- True when `value` is within `slack` (default 1e-6) of `want`.
function Check.isNear(value: number, want: number, slack: number?): boolean
	return math.abs(value - want) <= (slack or 1e-6)
end

function Check.section(name: string)
	sectionFailures = 0
	print(name)
end

function Check.finish()
	print(string.format("%d checks, %d failures", checks, failures))
	if failures > 0 then
		process.exit(1)
	end
end

return Check
