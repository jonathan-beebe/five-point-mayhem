--!strict
-- The arithmetic of client CarInput: how keys, the driver seat's floats and the default controls'
-- move vector combine into throttle and steer, the pod lift, and when a frame's input goes to the
-- server (Remotes.DriveInput). Pure: no requires.
--
--   keysOrSeat(keyThrottle, keySteer, seatThrottle, seatSteer)  keys win; none held: the seat's
--   fromMoveVector(move)                                        throttle, steer from a move vector
--   clamp(throttle, steer)                                      each into -1..1
--   lift(keys, touch)                                           E/Q plus the touch buttons, -1..1
--   newSent() / send(sent, throttle, steer, lift, now)          the resend rule: on the first frame
--                                                               seated, on a change, or when stale
--
-- tools/tests/client_logic.luau compares each with the inline code it replaced.

local DriveAxes = {}

DriveAxes.CHANGE = 0.05 -- throttle or steer moved further than this: send now
DriveAxes.RESEND_INTERVAL = 0.25 -- seconds: send at least this often while seated

function DriveAxes.keysOrSeat(
	keyThrottle: number,
	keySteer: number,
	seatThrottle: number,
	seatSteer: number
): (number, number)
	if keyThrottle == 0 and keySteer == 0 then
		return seatThrottle, seatSteer
	end
	return keyThrottle, keySteer
end

function DriveAxes.fromMoveVector(move: Vector3): (number, number)
	return -move.Z, move.X
end

function DriveAxes.clamp(throttle: number, steer: number): (number, number)
	return math.clamp(throttle, -1, 1), math.clamp(steer, -1, 1)
end

function DriveAxes.lift(keys: number, touch: number): number
	return math.clamp(keys + touch, -1, 1)
end

-- The last input sent; `driving` is false until the first send after sitting down.
export type Sent = { driving: boolean, throttle: number, steer: number, lift: number, at: number }

function DriveAxes.newSent(): Sent
	return { driving = false, throttle = 0, steer = 0, lift = 0, at = 0 }
end

-- Whether to send this input at `now` (seconds); records it in `sent` when so.
function DriveAxes.send(
	sent: Sent,
	throttle: number,
	steer: number,
	lift: number,
	now: number
): boolean
	local changed = math.abs(throttle - sent.throttle) > DriveAxes.CHANGE
		or math.abs(steer - sent.steer) > DriveAxes.CHANGE
		or lift ~= sent.lift
	if not sent.driving or changed or now - sent.at > DriveAxes.RESEND_INTERVAL then
		sent.driving = true
		sent.throttle, sent.steer, sent.lift, sent.at = throttle, steer, lift, now
		return true
	end
	return false
end

return table.freeze(DriveAxes)
