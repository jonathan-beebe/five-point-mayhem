-- The shape of a weapon's 3D model, shared by the files in `src/server/weaponModels`.
-- Everything is in handle space: the hand holds the handle at the origin, local -Z points away
-- from the wielder, +Y is up, +X is the wielder's right.
--
-- Holds (`Model.hold`), in the tool-hold pose where the right arm points straight ahead:
--   nil        forward: model -Z points along the arm, like an aimed gun.
--   "upright"  model -Z points up from the fist and model -Y points forward, so the default
--              "Slash" swing brings the -Z end down onto the target, striking with its -Y side.

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

export type Hold = "upright"

export type Model = {
	hold: Hold?, -- default: forward
	handle: HandleSpec?,
	muzzle: CFrame?, -- where shot effects start; default (0, 0.5, -length)
	-- Turns the whole model (pieces and muzzle) about the fist, applied after the offsets. Used to
	-- orient a model without editing every piece, e.g. CFrame.Angles(0, 0, math.pi) to roll it
	-- upside down.
	rotation: CFrame?,
	pieces: { PieceSpec },
}

local WeaponModel = {}

WeaponModel.MAX_PIECES = 80

-- Tool.Grip for "upright" models. A tool's handle sits at RightGripAttachment * Grip:Inverse();
-- the attachment's +Y is up and -Z is forward along the outstretched arm. A -90 degree turn about
-- X maps model -Z to attachment +Y (up) and model -Y to attachment -Z (forward). If upright
-- weapons point the wrong way in Studio, this is the one value to change; tools, lobby display
-- stands, and tools/preview all read it.
WeaponModel.UPRIGHT_GRIP = CFrame.Angles(math.rad(-90), 0, 0)

-- The grip a model's tool uses.
function WeaponModel.grip(model: Model): CFrame
	return if model.hold == "upright" then WeaponModel.UPRIGHT_GRIP else CFrame.identity
end

-- Rotations that lay a cylinder's X axis along Z (barrels, shafts) or Y (vertical grips).
WeaponModel.CYLINDER_Z = CFrame.Angles(0, math.rad(90), 0)
WeaponModel.CYLINDER_Y = CFrame.Angles(0, 0, math.rad(90))

-- Validates a model and bakes its rotation into the piece offsets and muzzle.
function WeaponModel.define(model: Model): Model
	assert(#model.pieces <= WeaponModel.MAX_PIECES, "weapon model has too many pieces")
	local rotation = model.rotation
	if not rotation then
		return model
	end
	local pieces = table.create(#model.pieces)
	for index, piece in model.pieces do
		local turned = table.clone(piece)
		turned.offset = rotation * piece.offset
		pieces[index] = turned
	end
	return {
		hold = model.hold,
		handle = model.handle,
		muzzle = if model.muzzle then rotation * model.muzzle else nil,
		pieces = pieces,
	}
end

return WeaponModel
