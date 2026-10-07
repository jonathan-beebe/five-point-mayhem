--!strict
-- The rules behind PromptPanel's prompt cards: which prompts do nothing for a seated player (the
-- panel switches those off), the key a card shows for an input type, and the cards' order. Pure:
-- Names only.
--
--   useful(where, promptName, seatName, passengerSeat)  whether a prompt does anything for a
--                                                       player seated in a vehicle
--   drawn(promptName, seatName)                         whether the prompt gets a card
--   keyText(inputType, gamepadKey, keyboardKey)         "TAP", the key's name, or ""
--   inputType(userInputType)                            the prompt input type of a last input
--                                                       type, or nil
--   before(a, b)                                        the cards' sort order
--
-- tools/tests/client_logic.luau compares each with the inline code it replaced.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Names = require(ReplicatedStorage.Shared.Names)

local PromptRules = {}

-- Where a prompt sits: on no vehicle, on the vehicle the player sits in, or on another vehicle.
export type Where = "none" | "own" | "other"

-- Whether a prompt does anything for a player seated (in a seat named `seatName`; a passenger
-- seat is a Seat, driver seats are VehicleSeats) aboard a vehicle. Prompts on no vehicle always
-- work. On another vehicle none do: getting in elsewhere means leaving the seat first, and E, F
-- and Q are vehicle controls. On the player's own vehicle the pod console's prompt works for the
-- driver and Drive for a passenger (it moves them to the free driver seat); Ride, Board and Climb
-- out do not.
function PromptRules.useful(
	where: Where,
	promptName: string,
	seatName: string,
	passengerSeat: boolean
): boolean
	if where == "none" then
		return true
	end
	if where == "other" then
		return false
	end
	if promptName == Names.Instances.PodPrompt then
		return seatName == Names.Instances.DriverSeat
	end
	if promptName == Names.Instances.DrivePrompt then
		return passengerSeat
	end
	return false
end

-- Whether a prompt gets a card for a player in a seat named `seatName` (nil: not seated). The pod
-- console's prompt gets none in a driver seat: PodControls' LAUNCH / RETURN HOME button there does
-- the same, and the prompt's key (F) still works without its card.
function PromptRules.drawn(promptName: string, seatName: string?): boolean
	return not (promptName == Names.Instances.PodPrompt and seatName == Names.Instances.DriverSeat)
end

-- The key badge's text: TAP on touch, else the gamepad or keyboard key without a "Button"
-- prefix ("" for KeyCode Unknown).
function PromptRules.keyText(
	inputType: Enum.ProximityPromptInputType,
	gamepadKey: Enum.KeyCode,
	keyboardKey: Enum.KeyCode
): string
	if inputType == Enum.ProximityPromptInputType.Touch then
		return "TAP"
	end
	local code = if inputType == Enum.ProximityPromptInputType.Gamepad
		then gamepadKey
		else keyboardKey
	if code.Value == 0 then -- no key (KeyCode Unknown)
		return ""
	end
	return (string.gsub(code.Name, "^Button", ""))
end

-- The prompt input type matching a last input type, or nil for one that says nothing (focus,
-- text input).
function PromptRules.inputType(inputType: Enum.UserInputType): Enum.ProximityPromptInputType?
	if inputType == Enum.UserInputType.Touch then
		return Enum.ProximityPromptInputType.Touch
	end
	if string.match(inputType.Name, "^Gamepad") then
		return Enum.ProximityPromptInputType.Gamepad
	end
	if inputType == Enum.UserInputType.Keyboard or string.match(inputType.Name, "^Mouse") then
		return Enum.ProximityPromptInputType.Keyboard
	end
	return nil
end

-- Keyboard key order: Drive (E) above Ride and the console (F) above Climb out (Q); equal keys by
-- full name.
function PromptRules.before(a: ProximityPrompt, b: ProximityPrompt): boolean
	local ka, kb = a.KeyboardKeyCode.Value, b.KeyboardKeyCode.Value
	return if ka ~= kb then ka < kb else a:GetFullName() < b:GetFullName()
end

return table.freeze(PromptRules)
