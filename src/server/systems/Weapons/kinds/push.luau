-- The push kind: a cone blast along the aim that damages and throws enemies within `range`
-- (`power`, default 120, plus 50 up).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WeaponMath = require(ReplicatedStorage.Shared.WeaponMath)
local Combat = require(script.Parent.Parent.Parent.Combat)
local Aim = require(script.Parent.Parent.Aim)
local Effects = require(script.Parent.Parent.Effects)

type Shot = Aim.Shot

local flash = Effects.flash

local function firePush(shot: Shot)
	local weapon = shot.weapon
	local look = (shot.aim - shot.origin).Unit
	for _, target in Combat.getTargets() do
		if target.model ~= shot.character then
			if WeaponMath.inPushCone(look, shot.origin, target.root.Position, weapon.range) then
				if Combat.damage(shot.player, target.model, target.humanoid, weapon.damage) then
					Combat.push(
						target.model,
						look * (weapon.power or 120) + Vector3.new(0, 50, 0),
						0.25
					)
				end
			end
		end
	end
	for distance = 4, weapon.range, 6 do
		flash(shot.muzzle + look * distance, weapon.color, distance / 3)
	end
end

return { fire = firePush }
