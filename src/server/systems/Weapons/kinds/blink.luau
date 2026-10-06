-- The blink kind: teleports the wielder to the aim point, clamped to `range`, unless it is in
-- the lobby.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local MathUtil = require(ReplicatedStorage.Shared.MathUtil)
local WeaponSounds = require(script.Parent.Parent.Parent.WeaponSounds)
local Aim = require(script.Parent.Parent.Aim)
local Effects = require(script.Parent.Parent.Effects)

type Shot = Aim.Shot

local flash = Effects.flash

local function fireBlink(shot: Shot)
	local weapon = shot.weapon
	local target = MathUtil.clampToRange(shot.root.Position, shot.aim, weapon.range)
	if Config.isInLobby(target) then
		return
	end
	flash(shot.root.Position, weapon.color, 6)
	WeaponSounds.at(weapon.id, "blinkFrom", shot.root.Position)
	local _, yaw = shot.root.CFrame:ToOrientation()
	shot.character:PivotTo(CFrame.new(target + Vector3.new(0, 4, 0)) * CFrame.Angles(0, yaw, 0))
	flash(target + Vector3.new(0, 3, 0), weapon.color, 6)
	WeaponSounds.at(weapon.id, "blinkTo", target)
end

return { fire = fireBlink }
