-- Parts built from model-file pieces (VehicleModel, CreatureModel and WeaponModel piece specs)
-- and welds holding them. `fromPiece` sets what all three model formats share; each caller sets
-- its own extras after it:
--   Vehicles   CastShadow from Transparency, HideInCockpit attribute; then Anchored false and
--              Massless true before welding
--   Creatures  Massless, smooth Top and Bottom surfaces
--   Weapons    CanQuery false, Massless
-- tools/tests/server_helpers.luau builds every piece of every model file both ways (this module,
-- and the inline code it replaced) and compares the results property by property.

local Parts = {}

-- The fields of a piece spec this module reads.
export type Piece = {
	class: string?, -- default Part
	shape: Enum.PartType?, -- Part only; ignored on other classes
	name: string?,
	size: Vector3,
	color: Color3,
	material: Enum.Material?, -- default SmoothPlastic
	transparency: number?, -- default 0
	reflectance: number?, -- default 0
}

-- An unparented part for `piece`: no collision, no touch events. Its Name is `piece.name`, else
-- `defaultName`, else the class's default. `scale` multiplies the size.
function Parts.fromPiece(piece: Piece, defaultName: string?, scale: number?): BasePart
	local part = Instance.new(piece.class or "Part") :: BasePart
	if piece.shape and part:IsA("Part") then
		part.Shape = piece.shape
	end
	local name = piece.name or defaultName
	if name then
		part.Name = name
	end
	part.Size = if scale then piece.size * scale else piece.size
	part.Color = piece.color
	part.Material = piece.material or Enum.Material.SmoothPlastic
	part.Transparency = piece.transparency or 0
	part.Reflectance = piece.reflectance or 0
	part.CanCollide = false
	part.CanTouch = false
	return part
end

-- Puts `part` at `offset` from `base`, welds it there (a Weld under `part`, C0 = `offset`), then
-- parents it to `parent`.
function Parts.weldTo(base: BasePart, part: BasePart, offset: CFrame, parent: Instance)
	part.CFrame = base.CFrame * offset
	local weld = Instance.new("Weld")
	weld.Part0 = base
	weld.Part1 = part
	weld.C0 = offset
	weld.Parent = part
	part.Parent = parent
end

return Parts
