--!strict
-- A flying pod's state (server PodFlight). PodFlight publishes it on the walker model's PodState
-- attribute (Names.Attributes.PodState) for Vehicles and the clients. A model without the
-- attribute (no pod, or not set yet) counts as docked. Pure: no requires. Constants are
-- UPPER_CASE (`PodState.DOCKED = "docked"`); tools/tests/names.luau pins their values.
--
--   docked     on its legs
--   flying     the pilot flies it
--   returning  the autopilot flies it home
--   landed     hovering just over the ground; everyone aboard was put outside
--   wrecked    dead: no controls, no autopilot, no seat locks

export type State = "docked" | "flying" | "returning" | "landed" | "wrecked"

local PodState = {
	DOCKED = "docked" :: "docked",
	FLYING = "flying" :: "flying",
	RETURNING = "returning" :: "returning",
	LANDED = "landed" :: "landed",
	WRECKED = "wrecked" :: "wrecked",
}

-- The state a PodState attribute value stands for: unset is docked.
function PodState.of(value: unknown): State
	return (value or PodState.DOCKED) :: State
end

-- Docked or landed: the pod sits still and nobody is locked in. LAUNCH takes off from either.
function PodState.isAtRest(state: State): boolean
	return state == PodState.DOCKED or state == PodState.LANDED
end

-- Flying or returning: in the air under the pilot or the autopilot. The seats lock, the jets burn.
function PodState.inFlight(state: State): boolean
	return state == PodState.FLYING or state == PodState.RETURNING
end

-- Flying or landed: the pod is off its legs and not coming home, so the legs seat can be driven.
function PodState.legsFree(state: State): boolean
	return state == PodState.FLYING or state == PodState.LANDED
end

-- Whether a player may sit in a seat of a walker whose pod is in `state`: the legs seat
-- (`legsSeat`, the seat's LegsSeat attribute, tested for truth) only while the legs are free, any
-- other seat only while the pod is docked (it is away with the pod).
function PodState.canSit(state: State, legsSeat: unknown): boolean
	if legsSeat then
		return PodState.legsFree(state)
	end
	return state == PodState.DOCKED
end

-- The seat the walk-up Drive prompt takes: the driver seat while docked, the legs seat (if any)
-- while the legs are free, else none.
function PodState.driveSeat<T>(state: State, driver: T, legsSeat: T?): T?
	if state == PodState.DOCKED then
		return driver
	end
	return if legsSeat and PodState.legsFree(state) then legsSeat else nil
end

return table.freeze(PodState)
