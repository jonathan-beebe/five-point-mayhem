-- The Ashen Moor (past Stonehold Castle): a moor blackened by two hundred years of coal. For now
-- the land only: a cleared floor in a bowl of mountains, open toward its pass. Self-contained: its
-- own seed and materials, and it requires only Basin and Build, so it can move to a place of its
-- own.

local Build = require(script.Parent.Parent.Build)
local Basin = require(script.Parent.Basin)

local AshenMoor = {}

local LAND: Basin.Land = {
	seed = 101,
	floor = Enum.Material.Ground,
	walls = Enum.Material.Slate,
	peaks = Enum.Material.Basalt,
}

-- `origin` is the floor centre, local -Z toward the lobby.
function AshenMoor.build(parent: Instance, origin: CFrame): Model
	Basin.carve(origin, LAND)
	return Build.model("The Ashen Moor", parent)
end

return AshenMoor
