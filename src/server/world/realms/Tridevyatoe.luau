-- Tridevyatoe (past Frost Palace): the Thrice-Nine Kingdom, its ravine city drowned by meltwater.
-- For now the land only: a cleared floor in a bowl of mountains, open toward its pass.
-- Self-contained: its own seed and materials, and it requires only Basin and Build, so it can move
-- to a place of its own.

local Build = require(script.Parent.Parent.Build)
local Basin = require(script.Parent.Basin)

local Tridevyatoe = {}

local LAND: Basin.Land = {
	seed = 105,
	floor = Enum.Material.Snow,
	walls = Enum.Material.Rock,
	peaks = Enum.Material.Glacier,
}

-- `origin` is the floor centre, local -Z toward the lobby.
function Tridevyatoe.build(parent: Instance, origin: CFrame): Model
	Basin.carve(origin, LAND)
	return Build.model("Tridevyatoe", parent)
end

return Tridevyatoe
