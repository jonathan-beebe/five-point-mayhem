-- Guard: server work that must survive its own errors. Background loops and per-item boot work
-- (one creature model file, one parking spot) run through here so one failure warns and the rest
-- carries on.
--   run(tag, fn, ...)       xpcall(fn, ...); on failure warn(tag, the error's first line, the
--                           rest of it and the traceback). Returns ok, result (or the error).
--   loop(tag, interval, fn) spawns `while true: task.wait(interval); run(tag, fn)`.
--   warn(tag, message, detail?)
--                           "[Mayhem <tag>] <message>" (then `detail` on the next lines), at most
--                           once per REPEAT_SECONDS for the same tag and message; the next one
--                           counts those held back. Past MAX_TRACKED keys, keys older than
--                           REPEAT_SECONDS are dropped.
-- Tested in tools/tests/guard.luau (and the callers in tools/tests/robustness.luau).

local Guard = {}

Guard.REPEAT_SECONDS = 30
Guard.MAX_TRACKED = 256

local lastWarned: { [string]: number } = {}
local heldBack: { [string]: number } = {}
local tracked = 0

-- Drops the keys whose last warning is REPEAT_SECONDS old or more.
local function prune(now: number)
	for key, last in lastWarned do
		if now - last >= Guard.REPEAT_SECONDS then
			lastWarned[key] = nil
			heldBack[key] = nil
			tracked -= 1
		end
	end
end

-- How many keys Guard tracks (for tools/tests/guard.luau).
function Guard.tracked(): number
	return tracked
end

function Guard.warn(tag: string, message: string, detail: string?)
	local key = tag .. "\0" .. message
	local now = os.clock()
	local last = lastWarned[key]
	if last and now - last < Guard.REPEAT_SECONDS then
		heldBack[key] = (heldBack[key] or 0) + 1
		return
	end
	if not last then
		if tracked >= Guard.MAX_TRACKED then
			prune(now)
		end
		tracked += 1
	end
	lastWarned[key] = now
	local count = heldBack[key]
	heldBack[key] = nil
	local suffix = if count then (" (%d more since the last)"):format(count) else ""
	local rest = if detail and detail ~= "" then "\n" .. detail else ""
	warn(("[Mayhem %s] %s%s%s"):format(tag, message, suffix, rest))
end

-- The error and its traceback, from inside xpcall.
local function withTraceback(err: any): { error: any, trace: string }
	return { error = err, trace = debug.traceback(tostring(err), 2) }
end

function Guard.run(tag: string, fn: (...any) -> ...any, ...: any): (boolean, any)
	local ok, result = xpcall(fn, withTraceback, ...)
	if ok then
		return true, result
	end
	-- The first line keys the rate limit; the rest of the error and the stack follow it.
	local trace = result.trace
	local firstLine = string.match(trace, "^[^\n]*") :: string
	Guard.warn(tag, firstLine, string.sub(trace, #firstLine + 2))
	return false, result.error
end

function Guard.loop(tag: string, interval: number, fn: () -> ())
	task.spawn(function()
		while true do
			task.wait(interval)
			Guard.run(tag, fn)
		end
	end)
end

return Guard
