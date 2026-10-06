--!strict
-- What PodControls shows the driver of a pod walker, from the pod's state (PodState), whether the
-- local player is aboard (a model is set), whether the server lets the pod land here (attribute
-- PodCanLand) and whether the device has touch. Pure: PodState and RemoteActions only.
--
--   view(state, aboard, canLand, touch)  the pod button's text, colour and activity; which of
--                                        LAND, ▲ and ▼ show; whether the seat locks the jump
--   command(state)                       the PodCommand the pod button sends, or nil
--
-- tools/tests/client_logic.luau compares each with the inline code it replaced.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PodState = require(ReplicatedStorage.Shared.PodState)
local RemoteActions = require(ReplicatedStorage.Shared.RemoteActions)

local PodButtons = {}

local rgb = Color3.fromRGB

PodButtons.REST_COLOR = rgb(0, 120, 170) -- LAUNCH
PodButtons.FLYING_COLOR = rgb(150, 90, 0) -- RETURN HOME
PodButtons.RETURNING_COLOR = rgb(60, 60, 70) -- RETURNING, inactive

export type View = {
	text: string,
	color: Color3,
	active: boolean, -- Active and AutoButtonColor
	flying: boolean, -- false: the touch lift is let go
	landVisible: boolean,
	liftVisible: boolean, -- ▲ and ▼
	lockJump: boolean,
}

function PodButtons.view(
	state: PodState.State,
	aboard: boolean,
	canLand: boolean,
	touch: boolean
): View
	local flying = aboard and state == PodState.FLYING
	return {
		text = if PodState.isAtRest(state)
			then "LAUNCH"
			elseif state == PodState.FLYING then "RETURN HOME"
			else "RETURNING",
		color = if PodState.isAtRest(state)
			then PodButtons.REST_COLOR
			elseif state == PodState.FLYING then PodButtons.FLYING_COLOR
			else PodButtons.RETURNING_COLOR,
		active = state ~= PodState.RETURNING,
		flying = flying,
		landVisible = flying and canLand,
		liftVisible = flying and touch,
		lockJump = aboard and PodState.inFlight(state),
	}
end

function PodButtons.command(state: PodState.State): string?
	if PodState.isAtRest(state) then
		return RemoteActions.PodCommand.LAUNCH
	elseif state == PodState.FLYING then
		return RemoteActions.PodCommand.HOME
	end
	return nil
end

return table.freeze(PodButtons)
