-- A weapon model's pieces as parts: createPart (invisible to queries, massless) and attach (welded
-- to the handle). Requires only WeaponModel and util/Parts, so it loads under Lune:
-- tools/tests/server_helpers.luau builds every weapon model's pieces through it.

local WeaponModel = require(script.Parent.Parent.WeaponModel)
local Parts = require(script.Parent.Parent.util.Parts)

type PieceSpec = WeaponModel.PieceSpec

local Pieces = {}

-- A piece's part, invisible to queries and massless. Without a piece name it keeps the class's
-- default Name.
function Pieces.createPart(spec: PieceSpec, scale: number?): BasePart
	local part = Parts.fromPiece(spec, nil, scale)
	part.CanQuery = false
	part.Massless = true
	return part
end

function Pieces.attach(handle: BasePart, spec: PieceSpec, parent: Instance)
	Parts.weldTo(handle, Pieces.createPart(spec), spec.offset, parent)
end

return Pieces
