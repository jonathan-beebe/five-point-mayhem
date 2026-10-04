-- The shape of a weapon's 3D model, shared by the files in `src/server/weaponModels`.
-- Everything is in handle space: the hand holds the handle at the origin, local -Z points away
-- from the wielder, +Y is up, +X is the wielder's right.

export type PieceSpec = {
	name: string?,
	class: ("Part" | "WedgePart" | "CornerWedgePart")?, -- default Part
	shape: Enum.PartType?, -- Part only: Block (default), Ball, Cylinder (axis is local X)
	size: Vector3,
	offset: CFrame,
	color: Color3,
	material: Enum.Material?, -- default SmoothPlastic
	transparency: number?,
	reflectance: number?,
}

export type HandleSpec = {
	size: Vector3?, -- default 0.4 x 0.4 x 1.2
	color: Color3?,
	material: Enum.Material?,
	transparency: number?,
}

export type Model = {
	handle: HandleSpec?,
	muzzle: CFrame?, -- where shot effects start; default (0, 0.5, -length)
	pieces: { PieceSpec },
}

local WeaponModel = {}

WeaponModel.MAX_PIECES = 80

-- Rotations that lay a cylinder's X axis along Z (barrels, shafts) or Y (vertical grips).
WeaponModel.CYLINDER_Z = CFrame.Angles(0, math.rad(90), 0)
WeaponModel.CYLINDER_Y = CFrame.Angles(0, 0, math.rad(90))

function WeaponModel.define(model: Model): Model
	assert(#model.pieces <= WeaponModel.MAX_PIECES, "weapon model has too many pieces")
	return model
end

return WeaponModel
