-- Tamoanchan (past Jaguar Pyramid): the Mesoamerican garden paradise, at peace with its ruins. For
-- now the land only: a cleared floor in a bowl of mountains, open toward its pass. Self-contained:
-- its own seed and materials, and it requires only Basin and Build, so it can move to a place of
-- its own.

local Build = require(script.Parent.Parent.Build)
local Basin = require(script.Parent.Basin)

local Tamoanchan = {}

local LAND: Basin.Land = {
	seed = 104,
	floor = Enum.Material.LeafyGrass,
	walls = Enum.Material.Limestone,
	peaks = Enum.Material.LeafyGrass,
}

-- `origin` is the floor centre, local -Z toward the lobby.
function Tamoanchan.build(parent: Instance, origin: CFrame): Model
	Basin.carve(origin, LAND)
	return Build.model("Tamoanchan", parent)
end

return Tamoanchan
