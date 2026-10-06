-- Vehicle space and placement: SKID_TO_GROUND (the skid's frame to the ground under it), welding
-- a part to the skid or to a bone at an offset in vehicle space, building the model file's pieces
-- (addPieces), and lifting a frame onto the terrain surface (onTerrain).
-- tools/tests/server_helpers.luau loads this module and builds every vehicle model's pieces.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Names = require(ReplicatedStorage.Shared.Names)
local VehicleModel = require(script.Parent.Parent.VehicleModel)
local Parts = require(script.Parent.Parent.util.Parts)

local Placement = {}

local SKID_TO_GROUND = CFrame.new(0, -0.5, 0)

-- Welds a part to the skid at an offset given in vehicle space (origin on the ground).
local function attach(model: Model, skid: BasePart, part: BasePart, offset: CFrame)
	part.Anchored = false
	part.Massless = true
	Parts.weldTo(skid, part, SKID_TO_GROUND * offset, model)
end

export type Bone = { part: BasePart, pivot: Vector3 }

-- Welds a part to a bone at an offset given in vehicle space, rest pose. The bone's Transform
-- then moves it. No bone: welded to the skid.
local function attachTo(model: Model, skid: BasePart, bone: Bone?, part: BasePart, offset: CFrame)
	if not bone then
		attach(model, skid, part, offset)
		return
	end
	part.Anchored = false
	part.Massless = true
	Parts.weldTo(bone.part, part, CFrame.new(bone.pivot):Inverse() * offset, model)
end

-- The model file's pieces, each welded to its bone (from `bones`, by name), else to the skid.
local function addPieces(
	model: Model,
	skid: BasePart,
	bones: { [string]: Bone },
	pieces: { VehicleModel.PieceSpec }
)
	for _, piece in pieces do
		local part = Parts.fromPiece(piece, "Piece")
		part.CastShadow = part.Transparency < 0.5
		if piece.hideInCockpit then
			part:SetAttribute(Names.Attributes.HideInCockpit, true) -- MechCamera
		end
		attachTo(model, skid, piece.bone and bones[piece.bone], part, piece.offset)
	end
end

-- Terrain collides only at its surface: a part below it falls through the inside. Lifts `cframe`
-- to the highest terrain surface under the footprint's center and corners (never lower). The
-- second result is false when no ray hit terrain: right after the world is built, terrain has no
-- collision yet (raycasts miss it and parts fall through it).
local terrainOnly = RaycastParams.new()
terrainOnly.FilterType = Enum.RaycastFilterType.Include
terrainOnly.FilterDescendantsInstances = { workspace.Terrain }

local function onTerrain(cframe: CFrame, W: number, L: number): (CFrame, boolean)
	local top = cframe.Position.Y
	local found = false
	for _, corner in
		{
			Vector3.zero,
			Vector3.new(-W, 0, -L),
			Vector3.new(W, 0, -L),
			Vector3.new(-W, 0, L),
			Vector3.new(W, 0, L),
		}
	do
		local point = cframe * (corner / 2)
		local hit =
			workspace:Raycast(point + Vector3.new(0, 50, 0), Vector3.new(0, -100, 0), terrainOnly)
		if hit then
			top = math.max(top, hit.Position.Y)
			found = true
		end
	end
	return cframe + Vector3.new(0, top - cframe.Position.Y, 0), found
end

Placement.SKID_TO_GROUND = SKID_TO_GROUND
Placement.attach = attach
Placement.attachTo = attachTo
Placement.addPieces = addPieces
Placement.onTerrain = onTerrain

return Placement
