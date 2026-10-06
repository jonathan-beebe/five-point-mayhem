--!strict
-- Picks the nearest few of a set of things, with hysteresis: a thing joins within `buildRange` and
-- leaves beyond `dropRange` (wider), at most `maxActive` at once. Client VehicleSounds keeps engine
-- sounds on the vehicles it picks. Pure: no requires.
--
--   choose(candidates, active, buildRange, dropRange, maxActive)  the set to keep
--
-- tools/tests/client_logic.luau compares it with the inline code it replaced.

local NearestSet = {}

export type Candidate<T> = { item: T, distance: number }

-- `candidates` in any order, each with its distance; `active` the things picked last time (any
-- value counts). Returns the kept things as keys of a set.
function NearestSet.choose<T>(
	candidates: { Candidate<T> },
	active: { [T]: any },
	buildRange: number,
	dropRange: number,
	maxActive: number
): { [T]: boolean }
	local inRange: { Candidate<T> } = {}
	for _, candidate in candidates do
		local limit = if active[candidate.item] then dropRange else buildRange
		if candidate.distance <= limit then
			table.insert(inRange, candidate)
		end
	end
	table.sort(inRange, function(a, b)
		return a.distance < b.distance
	end)
	local keep: { [T]: boolean } = {}
	for index = 1, math.min(#inRange, maxActive) do
		keep[inRange[index].item] = true
	end
	return keep
end

return table.freeze(NearestSet)
