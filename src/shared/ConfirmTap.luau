--!strict
-- A two-tap confirmation (client MacPanel's NUKE): the first tap arms it for a window, a second tap
-- inside the window fires, and the window running out disarms it. Pure: no requires; the caller
-- passes its clock (os.clock) and schedules the expiry (task.delay(window, ...)).
--
--   new()                          disarmed
--   tap(confirm, window, clock)    whether it fired (and disarmed), and the clock reading it took
--                                  last: on arming, the stamp to pass to expire
--   expire(confirm, stamp)         disarms, and returns true, if `stamp` still holds the arm
--
-- tools/tests/client_logic.luau drives it and the inline code it replaced through the same taps.

local ConfirmTap = {}

export type ConfirmTap = { armedAt: number? }

function ConfirmTap.new(): ConfirmTap
	return { armedAt = nil }
end

function ConfirmTap.tap(confirm: ConfirmTap, window: number, clock: () -> number): (boolean, number)
	local armedAt = confirm.armedAt
	if armedAt then
		local now = clock()
		if now - armedAt < window then
			confirm.armedAt = nil
			return true, now
		end
	end
	local stamp = clock()
	confirm.armedAt = stamp
	return false, stamp
end

function ConfirmTap.expire(confirm: ConfirmTap, stamp: number): boolean
	if confirm.armedAt == stamp then
		confirm.armedAt = nil
		return true
	end
	return false
end

return table.freeze(ConfirmTap)
