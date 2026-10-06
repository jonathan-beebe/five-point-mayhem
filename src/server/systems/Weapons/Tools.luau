-- Weapon tools and display models: each weapon's model (its file in `weaponModels`, else
-- FallbackModels from its catalog shape, cached), the Tool a player holds (createTool, give,
-- holds), and the anchored copy on the lobby's display stands (displayModel).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Names = require(ReplicatedStorage.Shared.Names)
local WeaponCatalog = require(ReplicatedStorage.Shared.WeaponCatalog)
local WeaponMath = require(ReplicatedStorage.Shared.WeaponMath)
local WeaponModel = require(script.Parent.Parent.WeaponModel)
local WeaponSounds = require(script.Parent.Parent.WeaponSounds)
local Parts = require(script.Parent.Parent.util.Parts)
local FallbackModels = require(script.Parent.FallbackModels)

local modelFiles = script.Parent.Parent.Parent:FindFirstChild("weaponModels")

type Weapon = WeaponCatalog.Weapon

local Tools = {}

local M = Enum.Material
local GRIP = FallbackModels.GRIP
local pieces = FallbackModels.pieces

type PieceSpec = WeaponModel.PieceSpec

-- A weapon's file in `weaponModels`, or a model built from its catalog shape.
local models: { [string]: WeaponModel.Model } = {}
local function modelFor(weapon: Weapon): WeaponModel.Model
	local model = models[weapon.id]
	if model then
		return model
	end
	local file = modelFiles and modelFiles:FindFirstChild(weapon.id)
	model = if file
		then require(file :: ModuleScript) :: WeaponModel.Model
		else { pieces = pieces(weapon) }
	models[weapon.id] = model
	return model
end

-- A piece's part, invisible to queries and massless. Without a piece name it keeps the class's
-- default Name.
local function createPart(spec: PieceSpec, scale: number?): BasePart
	local part = Parts.fromPiece(spec, nil, scale)
	part.CanQuery = false
	part.Massless = true
	return part
end

local function attach(handle: BasePart, spec: PieceSpec, parent: Instance)
	Parts.weldTo(handle, createPart(spec), spec.offset, parent)
end

local function makeHandle(weapon: Weapon): Part
	local spec = modelFor(weapon).handle or {}
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = spec.size or Vector3.new(0.4, 0.4, 1.2)
	handle.Color = spec.color or GRIP
	handle.Material = spec.material or M.SmoothPlastic
	handle.Transparency = spec.transparency or 0
	handle.CanCollide = false
	handle.CanQuery = false
	handle.Massless = true
	return handle
end

function Tools.createTool(weapon: Weapon): Tool
	local tool = Instance.new("Tool")
	tool.Name = weapon.name
	tool.ToolTip = weapon.description
	tool.CanBeDropped = false
	tool:SetAttribute(Names.Attributes.WeaponId, weapon.id)
	-- Shot muzzles are handle.CFrame * muzzle, so they follow the grip.
	tool.Grip = WeaponModel.grip(modelFor(weapon))
	local handle = makeHandle(weapon)
	WeaponSounds.equip(handle, weapon.id)
	handle.Parent = tool
	for _, spec in modelFor(weapon).pieces do
		attach(handle, spec, tool)
	end
	return tool
end

-- An anchored copy of a weapon for display stands, pivoting about the fist. Upright weapons stand
-- upright (as held), centered vertically on the pivot.
function Tools.displayModel(weaponId: string): Model?
	local weapon = WeaponCatalog.get(weaponId)
	if not weapon then
		return nil
	end
	local SCALE = 1.6
	local spec = modelFor(weapon)
	local hold = WeaponModel.grip(spec):Inverse()
	if spec.hold == "upright" then
		hold = WeaponMath.centerUpright(hold, spec.pieces, SCALE)
	end
	local model = Instance.new("Model")
	model.Name = weapon.name
	local handle = makeHandle(weapon)
	handle.Anchored = true
	handle.CFrame = hold
	handle.PivotOffset = hold:Inverse()
	handle.Parent = model
	for _, piece in spec.pieces do
		local part = createPart(piece, SCALE)
		part.Anchored = true
		part.CFrame = hold * CFrame.new(piece.offset.Position * SCALE) * piece.offset.Rotation
		part.Parent = model
	end
	handle.Size *= SCALE
	model.PrimaryPart = handle
	return model
end

function Tools.give(player: Player, weaponId: string): boolean
	local weapon = WeaponCatalog.get(weaponId)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not weapon or not backpack then
		return false
	end
	Tools.createTool(weapon).Parent = backpack
	return true
end

-- Whether the player's Backpack or character holds a Tool of this weapon id.
function Tools.holds(player: Player, weaponId: string): boolean
	for _, container in { player:FindFirstChildOfClass("Backpack"), player.Character } do
		for _, child in container:GetChildren() do
			if child:IsA("Tool") and child:GetAttribute(Names.Attributes.WeaponId) == weaponId then
				return true
			end
		end
	end
	return false
end

Tools.modelFor = modelFor

return Tools
