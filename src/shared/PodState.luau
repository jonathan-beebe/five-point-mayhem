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

return table.freeze(PodState)
