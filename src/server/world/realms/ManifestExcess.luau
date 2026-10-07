-- Manifest Excess (past Mayhem Tower): a frontier boomtown buried in its own consumption. For now
-- the land only: a cleared floor in a bowl of mountains, open toward its pass. Self-contained: its
-- own seed and materials, and it requires only Basin and Build, so it can move to a place of its
-- own.

local Build = require(script.Parent.Parent.Build)
local Basin = require(script.Parent.Basin)

local ManifestExcess = {}

local LAND: Basin.Land = {
	seed = 103,
	floor = Enum.Material.Sand,
	walls = Enum.Material.Sandstone,
	peaks = Enum.Material.Sandstone,
}

-- `origin` is the floor centre, local -Z toward the lobby.
function ManifestExcess.build(parent: Instance, origin: CFrame): Model
	Basin.carve(origin, LAND)
	return Build.model("Manifest Excess", parent)
end

return ManifestExcess
