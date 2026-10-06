-- Aiming: the Shot record every kind of weapon fires, spread, and the raycast hitscan shots
-- resolve with (through teammates and non-solid scenery).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WeaponCatalog = require(ReplicatedStorage.Shared.WeaponCatalog)
local WeaponMath = require(ReplicatedStorage.Shared.WeaponMath)
local Combat = require(script.Parent.Parent.Combat)
local Effects = require(script.Parent.Effects)

local Aim = {}

local effectsFolder = Effects.folder
local random = Effects.random

type Weapon = WeaponCatalog.Weapon

export type Shot = {
	player: Player,
	weapon: Weapon,
	character: Model,
	root: BasePart,
	origin: Vector3, -- eye point the shot is resolved from
	muzzle: Vector3, -- where effects start
	aim: Vector3,
}

-- `direction` turned by up to `degrees` of spread (WeaponMath.spreadDirection) from Effects.random.
local function spreadDirection(direction: Vector3, degrees: number): Vector3
	return WeaponMath.spreadDirection(direction, degrees, random)
end

-- Raycast that passes through teammates and non-solid scenery.
local function raycast(player: Player, origin: Vector3, vector: Vector3): RaycastResult?
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character :: Model, effectsFolder }
	for _ = 1, 8 do
		local result = workspace:Raycast(origin, vector, params)
		if not result then
			return nil
		end
		local character, humanoid = Combat.findCharacter(result.Instance)
		local isAlly = character
			and humanoid
			and Players:GetPlayerFromCharacter(character) ~= nil
			and not Combat.canDamage(player, character, humanoid)
		if isAlly then
			params:AddToFilter(character :: Model)
		else
			return result
		end
	end
	return nil
end

Aim.spreadDirection = spreadDirection
Aim.raycast = raycast

return Aim
