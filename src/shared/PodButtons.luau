--!strict
-- What PodControls shows the driver of a pod walker, from the pod's state (PodState), whether the
-- local player is aboard (a model is set), whether the server lets the pod land here (attribute
-- PodCanLand), whether the device has touch and whether the legs follow the pod (attribute
-- LegsDrone). Pure: PodState and RemoteActions only.
--
--   view(state, aboard, canLand, touch, drone?)  the pod button's text, colour and activity;
--                                                which of LAND, ▲, ▼ and DRONE show; DRONE's
--                                                text and colour; whether the seat locks the jump
--   command(state)                               the PodCommand the pod button sends, or nil
--
-- tools/tests/client_logic.luau compares each with the inline code it replaced; DRONE's fields
-- (added after) against golden cases.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PodState = require(ReplicatedStorage.Shared.PodState)
local RemoteActions = require(ReplicatedStorage.Shared.RemoteActions)

local PodButtons = {}

local rgb = Color3.fromRGB

PodButtons.REST_COLOR = rgb(0, 120, 170) -- LAUNCH
PodButtons.FLYING_COLOR = rgb(150, 90, 0) -- RETURN HOME
PodButtons.RETURNING_COLOR = rgb(60, 60, 70) -- RETURNING, inactive
PodButtons.DRONE_OFF_COLOR = rgb(20, 20, 28) -- DRONE OFF: the value of Theme.Colors.hud
PodButtons.DRONE_ON_COLOR = rgb(20, 130, 150) -- DRONE ON

export type View = {
	text: string,
	color: Color3,
	active: boolean, -- Active and AutoButtonColor
	flying: boolean, -- false: the touch lift is let go
	landVisible: boolean,
	liftVisible: boolean, -- ▲ and ▼
	lockJump: boolean,
	droneVisible: boolean, -- DRONE: the pilot, in flight
	droneText: string,
	droneColor: Color3,
}

function PodButtons.view(
	state: PodState.State,
	aboard: boolean,
	canLand: boolean,
	touch: boolean,
	drone: boolean?
): View
	local flying = aboard and state == PodState.FLYING
	local droneOn = flying and drone == true
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
		droneVisible = flying,
		droneText = if droneOn then "DRONE\nON" else "DRONE\nOFF",
		droneColor = if droneOn then PodButtons.DRONE_ON_COLOR else PodButtons.DRONE_OFF_COLOR,
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
