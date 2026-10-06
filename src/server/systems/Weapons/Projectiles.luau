-- Projectiles: simulated shots launched by the projectile kind, stepped each Heartbeat
-- (`heartbeat`; init.luau connects it) with gravity, raycast along each step, and what they do
-- where they land (`impact`; IMPACTS by WeaponCatalog `impact`, tools/tests/data_integrity checks
-- the catalog against it). A projectile that hits nothing expires after 6 seconds.
-- data_integrity reads IMPACTS through Sandbox.loadIsolated (requires stubbed): keep the table
-- free of top-level work on required values.

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local WeaponCatalog = require(ReplicatedStorage.Shared.WeaponCatalog)
local WeaponMath = require(ReplicatedStorage.Shared.WeaponMath)
local Combat = require(script.Parent.Parent.Combat)
local WeaponSounds = require(script.Parent.Parent.WeaponSounds)
local Aim = require(script.Parent.Aim)
local Effects = require(script.Parent.Effects)

type Weapon = WeaponCatalog.Weapon
type Shot = Aim.Shot

local Projectiles = {}

local rgb = Color3.fromRGB
local M = Enum.Material
local random = Effects.random
local effectsFolder = Effects.folder
local flash = Effects.flash

type Projectile = {
	shot: Shot,
	part: BasePart,
	position: Vector3,
	velocity: Vector3,
	gravity: number,
	born: number,
	params: RaycastParams,
}

local projectiles: { Projectile } = {}

local function projectileVisual(weapon: Weapon): BasePart
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Color = weapon.color
	if weapon.category == "Explosives" and weapon.shape == "tube" then
		part.Size = Vector3.new(0.7, 0.7, 2.6)
		part.Material = M.Metal
		local fire = Instance.new("Fire")
		fire.Size = 2
		fire.Heat = 0
		fire.Parent = part
	else
		part.Shape = Enum.PartType.Ball
		local size = WeaponMath.projectileSize(weapon.impact, weapon.blast)
		part.Size = Vector3.one * size
		part.Material = if weapon.neon then M.Neon else M.SmoothPlastic
		if weapon.effect == "burn" then
			Instance.new("Fire", part).Size = 3
		end
	end
	part.Parent = effectsFolder
	return part
end

local function blackHole(shot: Shot, position: Vector3)
	local weapon = shot.weapon
	local core = Instance.new("Part")
	core.Shape = Enum.PartType.Ball
	core.Anchored = true
	core.CanCollide = false
	core.CanQuery = false
	core.Material = M.Neon
	core.Color = rgb(20, 0, 40)
	core.Size = Vector3.one * 6
	core.CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
	core.Parent = effectsFolder
	WeaponSounds.on(weapon.id, "loop", core)
	TweenService:Create(core, TweenInfo.new(3), { Size = Vector3.one * 14 }):Play()
	local radius = weapon.radius or 40
	task.spawn(function()
		for _ = 1, 15 do
			for _, target in Combat.getTargets() do
				local offset = core.Position - target.root.Position
				if
					offset.Magnitude < radius
					and offset.Magnitude > 2
					and Combat.canDamage(shot.player, target.model, target.humanoid)
				then
					Combat.push(target.model, offset.Unit * 45, 0.2)
				end
			end
			task.wait(0.2)
		end
		core:Destroy()
		Combat.explode(
			shot.player,
			core.Position,
			14,
			weapon.damage,
			nil,
			nil,
			WeaponSounds.cue(weapon.id, "finish")
		)
	end)
end

local function bananaTrap(shot: Shot, position: Vector3)
	local peel = Instance.new("Part")
	peel.Name = "BananaPeel"
	peel.Anchored = true
	peel.CanCollide = false
	peel.Size = Vector3.new(2.4, 0.4, 1.6)
	peel.Color = rgb(255, 230, 50)
	peel.Material = M.SmoothPlastic
	peel.CFrame = CFrame.new(position + Vector3.new(0, 0.2, 0))
		* CFrame.Angles(0, random:NextNumber(0, 6), 0)
	peel.Parent = effectsFolder
	Debris:AddItem(peel, 40)
	local connection
	connection = peel.Touched:Connect(function(hit)
		local character, humanoid = Combat.findCharacter(hit)
		if
			character
			and humanoid
			and Combat.damage(shot.player, character, humanoid, shot.weapon.damage)
		then
			connection:Disconnect()
			WeaponSounds.at(shot.weapon.id, "trap", peel.Position)
			humanoid.Sit = true
			Combat.push(
				character,
				Vector3.new(random:NextNumber(-30, 30), 90, random:NextNumber(-30, 30)),
				0.25
			)
			peel:Destroy()
		end
	end)
end

-- What a projectile with an `impact` does where it lands, by WeaponCatalog `impact`.
local IMPACTS: { [string]: (Shot, Vector3) -> () } = {
	blackhole = blackHole,
	trap = bananaTrap,
}

local function impact(projectile: Projectile, position: Vector3, part: BasePart?)
	local shot = projectile.shot
	local weapon = shot.weapon
	local special = weapon.impact and IMPACTS[weapon.impact]
	if special then
		special(shot, position)
	elseif weapon.blast and weapon.splash then
		flash(position, weapon.color, weapon.blast * 0.75)
		WeaponSounds.at(weapon.id, "impact", position)
		Combat.blast(
			shot.player,
			position,
			weapon.blast,
			weapon.damage,
			weapon.effect,
			weapon.power
		)
	elseif weapon.blast then
		Combat.explode(
			shot.player,
			position,
			weapon.blast,
			weapon.damage,
			weapon.effect,
			weapon.power,
			WeaponSounds.cue(weapon.id, "impact")
		)
	else
		flash(position, weapon.color, 1.5)
		WeaponSounds.at(weapon.id, "impact", position)
		if part then
			Combat.hitPart(
				shot.player,
				part,
				weapon.damage,
				weapon.effect,
				weapon.power,
				projectile.position
			)
		end
	end
end

local function launch(shot: Shot, direction: Vector3)
	local weapon = shot.weapon
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { shot.character, effectsFolder }
	local part = projectileVisual(weapon)
	part.CFrame = CFrame.lookAt(shot.muzzle, shot.muzzle + direction)
	table.insert(projectiles, {
		shot = shot,
		part = part,
		position = shot.muzzle,
		velocity = direction * (weapon.speed or 100),
		gravity = (weapon.gravity or 0) * workspace.Gravity,
		born = os.clock(),
		params = params,
	})
end

local function heartbeat(dt: number)
	for index = #projectiles, 1, -1 do
		local projectile = projectiles[index]
		local step, nextVelocity =
			WeaponMath.projectileStep(projectile.velocity, projectile.gravity, dt)
		local result = workspace:Raycast(projectile.position, step, projectile.params)
		local expired = os.clock() - projectile.born > 6
		if result or expired then
			table.remove(projectiles, index)
			projectile.part:Destroy()
			if result then
				impact(projectile, result.Position, result.Instance :: BasePart)
			end
		else
			projectile.position += step
			projectile.velocity = nextVelocity
			if step.Magnitude > 0.001 then
				projectile.part.CFrame =
					CFrame.lookAt(projectile.position, projectile.position + step)
			end
		end
	end
end

Projectiles.IMPACTS = IMPACTS
Projectiles.launch = launch
Projectiles.heartbeat = heartbeat

return Projectiles
