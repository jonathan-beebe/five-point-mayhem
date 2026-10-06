-- The hitscan kind: instant rays (`pellets`, `spread` in degrees) from the eye toward the aim,
-- drawn as a beam (or lightning with `chain`) from the muzzle; `chain` lightning then jumps that
-- many times to the nearest enemy within 30 studs for 60% damage.

local Combat = require(script.Parent.Parent.Parent.Combat)
local WeaponSounds = require(script.Parent.Parent.Parent.WeaponSounds)
local Aim = require(script.Parent.Parent.Aim)
local Effects = require(script.Parent.Parent.Effects)

type Shot = Aim.Shot

local rgb = Color3.fromRGB
local beam = Effects.beam
local lightning = Effects.lightning
local spreadDirection = Aim.spreadDirection
local raycast = Aim.raycast

local function chainLightning(shot: Shot, from: Model, jumps: number)
	local hit: { [Model]: boolean } = { [from] = true }
	local current = from
	for _ = 1, jumps do
		local currentRoot = current:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not currentRoot then
			return
		end
		local best: Combat.Target? = nil
		local bestDistance = 30
		for _, target in Combat.getTargets() do
			local distance = (target.root.Position - currentRoot.Position).Magnitude
			if
				not hit[target.model]
				and distance < bestDistance
				and Combat.canDamage(shot.player, target.model, target.humanoid)
			then
				best, bestDistance = target, distance
			end
		end
		if not best then
			return
		end
		hit[best.model] = true
		lightning(currentRoot.Position, best.root.Position, shot.weapon.color)
		Combat.damage(shot.player, best.model, best.humanoid, shot.weapon.damage * 0.6)
		WeaponSounds.at(shot.weapon.id, "chain", best.root.Position)
		current = best.model
	end
end

local function fireHitscan(shot: Shot)
	local weapon = shot.weapon
	local direction = (shot.aim - shot.origin).Unit
	local width = if weapon.neon then 0.35 else 0.12
	local struck = false
	for _ = 1, weapon.pellets or 1 do
		local vector = spreadDirection(direction, weapon.spread or 0) * weapon.range
		local result = raycast(shot.player, shot.origin, vector)
		local finish = if result then result.Position else shot.origin + vector
		if weapon.chain then
			lightning(shot.muzzle, finish, weapon.color)
		else
			beam(
				shot.muzzle,
				finish,
				if weapon.neon then weapon.color else rgb(255, 230, 150),
				width,
				if weapon.neon then 0.15 else 0.06
			)
		end
		if result then
			local victim = Combat.hitPart(
				shot.player,
				result.Instance :: BasePart,
				weapon.damage,
				weapon.effect,
				weapon.power,
				shot.origin
			)
			if victim and not struck then
				struck = true -- one hit sound per trigger, however many pellets land
				WeaponSounds.at(weapon.id, "hit", result.Position)
			end
			if victim and weapon.chain then
				chainLightning(shot, victim, weapon.chain)
			end
		end
	end
end

return { fire = fireHitscan }
