-- The projectile kind: launches `count` (default 1) projectiles from the muzzle toward the aim,
-- spread by `spread` degrees when `count` is set. Projectiles.luau flies them.

local Aim = require(script.Parent.Parent.Aim)
local Projectiles = require(script.Parent.Parent.Projectiles)

type Shot = Aim.Shot

local spreadDirection = Aim.spreadDirection
local launch = Projectiles.launch

local function fireProjectile(shot: Shot)
	local weapon = shot.weapon
	local direction = (shot.aim - shot.muzzle).Unit
	for _ = 1, weapon.count or 1 do
		launch(shot, spreadDirection(direction, if weapon.count then weapon.spread or 0 else 0))
	end
end

return { fire = fireProjectile }
