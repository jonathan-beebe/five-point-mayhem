-- The melee kind: hits everything within `range` (plus 1.5 studs) in front of the wielder
-- (`arc`, the minimum dot, default 0.3), detonates barrels in range, and plays the tool's swing.

local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Names = require(ReplicatedStorage.Shared.Names)
local WeaponMath = require(ReplicatedStorage.Shared.WeaponMath)
local Combat = require(script.Parent.Parent.Parent.Combat)
local WeaponSounds = require(script.Parent.Parent.Parent.WeaponSounds)
local Aim = require(script.Parent.Parent.Aim)
local Effects = require(script.Parent.Parent.Effects)

type Shot = Aim.Shot

local flash = Effects.flash

local function fireMelee(shot: Shot)
	local weapon = shot.weapon
	local look = shot.root.CFrame.LookVector
	local flatLook = Vector3.new(look.X, 0, look.Z).Unit
	local minimumDot = weapon.arc or 0.3
	local struck = false
	for _, target in Combat.getTargets() do
		if target.model ~= shot.character then
			local inReach = WeaponMath.inMeleeReach(
				flatLook,
				minimumDot,
				shot.root.Position,
				target.root.Position,
				weapon.range
			)
			if
				inReach
				and Combat.damage(shot.player, target.model, target.humanoid, weapon.damage)
			then
				Combat.applyEffect(
					shot.player,
					target.model,
					target.humanoid,
					weapon.effect,
					weapon.power,
					shot.root.Position
				)
				flash(target.root.Position, weapon.color, 2)
				if not struck then
					struck = true -- one hit sound per swing
					WeaponSounds.at(weapon.id, "hit", target.root.Position)
				end
			end
		end
	end
	for _, barrel in CollectionService:GetTagged(Names.Tags.ExplosiveBarrel) do
		if (barrel.Position - shot.root.Position).Magnitude <= weapon.range then
			Combat.detonateBarrel(barrel, shot.player)
		end
	end
	local tool = shot.character:FindFirstChildOfClass("Tool")
	if tool then
		local animation = Instance.new("StringValue")
		animation.Name = "toolanim"
		animation.Value = if weapon.range > 11 then "Lunge" else "Slash"
		animation.Parent = tool
		Debris:AddItem(animation, 1)
	end
end

return { fire = fireMelee }
