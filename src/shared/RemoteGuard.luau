--!strict
-- The server's rules for what a client sends over a remote: a client can send any value, NaN and
-- ±inf included (math.clamp passes NaN through). Pure: no requires; the caller passes the clock.
--
--   isFinite(x)                  neither NaN nor ±inf
--   axis(x)                      a drive axis: finite into -1..1, non-finite 0 (neutral)
--   isFiniteVector(value)        a Vector3 with three finite components
--   optionalString(value)        the value if a string, else nil
--   newLimiter(rate, burst, now) a token bucket: `burst` events at once, `rate` per second after
--   allow(limiter, now)          spends a token; false (drop the event) when there is none
--
-- DRIVE_RATE and DRIVE_BURST limit DriveInput per player. The client (DriveAxes.send) sends at
-- most once per Heartbeat: 60 a second at Roblox's default frame cap, 240 at its highest; idle it
-- resends every RESEND_INTERVAL (4 a second). 300 a second sustained is 25% over the most a real
-- client can send; a burst of 300 absorbs a second of 240 FPS sends arriving at once after a
-- network stall.
--
-- tools/tests/remote_guard.luau checks each; tools/tests/remote_handlers.luau the handlers.

local RemoteGuard = {}

RemoteGuard.DRIVE_RATE = 300 -- DriveInput events per second, per player
RemoteGuard.DRIVE_BURST = 300 -- DriveInput events at once, per player

function RemoteGuard.isFinite(x: number): boolean
	return x == x and x ~= math.huge and x ~= -math.huge
end

function RemoteGuard.axis(x: number): number
	if not RemoteGuard.isFinite(x) then
		return 0
	end
	return math.clamp(x, -1, 1)
end

function RemoteGuard.isFiniteVector(value: unknown): boolean
	if typeof(value) ~= "Vector3" then
		return false
	end
	local vector = value :: Vector3
	return RemoteGuard.isFinite(vector.X)
		and RemoteGuard.isFinite(vector.Y)
		and RemoteGuard.isFinite(vector.Z)
end

function RemoteGuard.optionalString(value: unknown): string?
	return if type(value) == "string" then value else nil
end

export type Limiter = { rate: number, burst: number, tokens: number, at: number }

-- A full bucket at `now` (seconds).
function RemoteGuard.newLimiter(rate: number, burst: number, now: number): Limiter
	return { rate = rate, burst = burst, tokens = burst, at = now }
end

-- Whether an event at `now` passes; spends a token when it does.
function RemoteGuard.allow(limiter: Limiter, now: number): boolean
	local elapsed = math.max(now - limiter.at, 0)
	limiter.tokens = math.min(limiter.burst, limiter.tokens + elapsed * limiter.rate)
	limiter.at = math.max(now, limiter.at)
	if limiter.tokens < 1 then
		return false
	end
	limiter.tokens -= 1
	return true
end

return table.freeze(RemoteGuard)
