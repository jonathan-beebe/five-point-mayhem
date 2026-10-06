-- The heal kind: restores `damage` health to the wielder and every living ally within `range`.

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

local Combat = require(script.Parent.Parent.Parent.Combat)
local Characters = require(script.Parent.Parent.Parent.util.Characters)
local Aim = require(script.Parent.Parent.Aim)
local Effects = require(script.Parent.Parent.Effects)

type Shot = Aim.Shot

local flash = Effects.flash

local function fireHeal(shot: Shot)
	local weapon = shot.weapon
	for _, other in Players:GetPlayers() do
		local _, humanoid, root = Characters.living(other)
		if humanoid and root and Combat.areAllies(shot.player, other) then
			if (root.Position - shot.root.Position).Magnitude <= weapon.range then
				humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + weapon.damage)
				local sparkle = Instance.new("Sparkles")
				sparkle.SparkleColor = weapon.color
				sparkle.Parent = root
				Debris:AddItem(sparkle, 1.5)
			end
		end
	end
	flash(shot.root.Position, weapon.color, weapon.range)
end

return { fire = fireHeal }
