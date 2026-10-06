-- The strike kind: calls a `style` down onto the aim point, clamped to `range`, hitting within
-- `radius` (default 10). STYLES by WeaponCatalog `style` (tools/tests/data_integrity checks the
-- catalog against it); lightning without one. data_integrity reads STYLES through
-- Sandbox.loadIsolated (requires stubbed): keep the table free of top-level work on required
-- values.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local MathUtil = require(ReplicatedStorage.Shared.MathUtil)
local WeaponCatalog = require(ReplicatedStorage.Shared.WeaponCatalog)
local Combat = require(script.Parent.Parent.Parent.Combat)
local WeaponSounds = require(script.Parent.Parent.Parent.WeaponSounds)
local Aim = require(script.Parent.Parent.Aim)
local Effects = require(script.Parent.Parent.Effects)

type Shot = Aim.Shot

type Weapon = WeaponCatalog.Weapon

local rgb = Color3.fromRGB
local M = Enum.Material
local random = Effects.random
local effectsFolder = Effects.folder
local flash = Effects.flash
local lightning = Effects.lightning

-- A burning rock falls onto `target` and explodes there.
local function meteor(shot: Shot, weapon: Weapon, target: Vector3, radius: number)
	local rock = Instance.new("Part")
	rock.Shape = Enum.PartType.Ball
	rock.Anchored = true
	rock.CanCollide = false
	rock.CanQuery = false
	rock.Size = Vector3.one * 8
	rock.Material = M.Basalt
	rock.Color = rgb(70, 40, 30)
	rock.CFrame = CFrame.new(target + Vector3.new(40, 160, 0))
	Instance.new("Fire", rock).Size = 12
	rock.Parent = effectsFolder
	WeaponSounds.on(weapon.id, "fall", rock)
	TweenService:Create(
		rock,
		TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ CFrame = CFrame.new(target) }
	):Play()
	task.delay(0.7, function()
		rock:Destroy()
		Combat.explode(
			shot.player,
			target,
			radius,
			weapon.damage,
			weapon.effect,
			weapon.power,
			WeaponSounds.cue(weapon.id, "strike")
		)
	end)
end

-- A bolt from the sky onto `target` hits everyone within `radius` (plus 2 studs).
local function lightningStrike(shot: Shot, weapon: Weapon, target: Vector3, radius: number)
	lightning(
		target + Vector3.new(random:NextNumber(-10, 10), 140, random:NextNumber(-10, 10)),
		target,
		weapon.color
	)
	flash(target, weapon.color, radius)
	WeaponSounds.at(weapon.id, "strike", target)
	for _, victim in Combat.getTargets() do
		if (victim.root.Position - target).Magnitude <= radius + 2 then
			Combat.damage(shot.player, victim.model, victim.humanoid, weapon.damage)
		end
	end
end

local STYLES: { [string]: (Shot, Weapon, Vector3, number) -> () } = {
	meteor = meteor,
	lightning = lightningStrike,
}

local function fireStrike(shot: Shot)
	local weapon = shot.weapon
	local target = MathUtil.clampToRange(shot.root.Position, shot.aim, weapon.range)
	local radius = weapon.radius or 10
	local style = weapon.style and STYLES[weapon.style] or STYLES.lightning
	style(shot, weapon, target, radius)
end

return { fire = fireStrike, STYLES = STYLES }
