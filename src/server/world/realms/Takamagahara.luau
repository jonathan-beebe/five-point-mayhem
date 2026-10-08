-- Takamagahara (past Sakura Hall): the Shinto High Plain of Heaven, held up by cloud. For now the
-- land only: a cleared floor in a bowl of mountains, open toward its pass. Self-contained: its own
-- seed and materials, and it requires only Basin and Build, so it can move to a place of its own.

local Build = require(script.Parent.Parent.Build)
local Basin = require(script.Parent.Basin)

local Takamagahara = {}

local LAND: Basin.Land = {
	seed = 102,
	floor = Enum.Material.Grass,
	walls = Enum.Material.Rock,
	peaks = Enum.Material.Limestone,
}

-- `origin` is the floor centre, local -Z toward the lobby.
function Takamagahara.build(parent: Instance, origin: CFrame): Model
	Basin.carve(origin, LAND)
	return Build.model("Takamagahara", parent)
end

return Takamagahara
