-- The shape of a creature, shared by the files in `src/server/creatureModels`.
--
-- A creature file returns a plain table (no requires) so tools outside Roblox can load it; it may
-- use only Roblox datatypes (CFrame, Vector3, Vector2, Color3, Enum) and the Luau standard library.
--
-- Everything is in creature space: the origin is on the ground under the center of the root, +Y
-- is up, -Z is the way the creature faces, +X is its right. Scale: 4 studs = 1 meter; a player
-- avatar stands about 5.5 studs tall.
--
-- The creature walks as a Humanoid: an invisible HumanoidRootPart (`rootSize`) floats `hipHeight`
-- above the ground, so its center sits at y = hipHeight + rootSize.Y / 2. The root is the only
-- solid part. Pieces are decoration welded to the root: they do not collide, but weapons hit them.

export type PieceSpec = {
	name: string?,
	class: ("Part" | "WedgePart")?, -- default Part
	shape: Enum.PartType?, -- Part only: Block (default), Ball, Cylinder (axis is local X)
	size: Vector3,
	offset: CFrame,
	color: Color3,
	material: Enum.Material?, -- default SmoothPlastic
	transparency: number?,
	reflectance: number?,
}

export type Model = {
	name: string,
	rootSize: Vector3,
	hipHeight: number,
	-- Attack range from the root's center, studs. Default 4 + the root's half-length.
	reach: number?,
	pieces: { PieceSpec }, -- one piece named "Head"
}

local CreatureModel = {}

CreatureModel.MAX_PIECES = 200

-- Rotations that lay a cylinder's X axis along Z or Y.
CreatureModel.CYLINDER_Z = CFrame.Angles(0, math.rad(90), 0)
CreatureModel.CYLINDER_Y = CFrame.Angles(0, 0, math.rad(90))

-- Validates a creature file's table and fills defaults.
function CreatureModel.define(model: Model): Model
	assert(type(model.name) == "string", "creature model needs a name")
	assert(#model.pieces >= 1, model.name .. " has no pieces")
	assert(#model.pieces <= CreatureModel.MAX_PIECES, model.name .. " has too many pieces")
	assert(model.hipHeight >= 0, model.name .. " needs a hipHeight >= 0")
	assert(
		model.rootSize.X > 0 and model.rootSize.Y > 0 and model.rootSize.Z > 0,
		model.name .. " needs a positive rootSize"
	)
	local heads = 0
	for _, piece in model.pieces do
		if piece.name == "Head" then
			heads += 1
		end
	end
	assert(heads == 1, model.name .. " needs exactly one piece named Head")
	if not model.reach then
		model.reach = 4 + model.rootSize.Z / 2
	end
	return model
end

-- The root's center in creature space.
function CreatureModel.rootCenter(model: Model): CFrame
	return CFrame.new(0, model.hipHeight + model.rootSize.Y / 2, 0)
end

return CreatureModel
