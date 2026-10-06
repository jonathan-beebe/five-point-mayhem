-- The FireWeapon remote: a client reports "I fired weapon X at point P"; this checks the held
-- tool, a living character outside the lobby and the cooldown, builds the Shot (eye origin, muzzle
-- from the tool's model) and fires it through FIRE[weapon.kind]. init.luau connects `onFire` and
-- `forget` (PlayerRemoving).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Names = require(ReplicatedStorage.Shared.Names)
local RemoteGuard = require(ReplicatedStorage.Shared.RemoteGuard)
local WeaponCatalog = require(ReplicatedStorage.Shared.WeaponCatalog)
local WeaponMath = require(ReplicatedStorage.Shared.WeaponMath)
local WeaponSounds = require(script.Parent.Parent.WeaponSounds)
local Tools = require(script.Parent.Tools)
local FIRE = require(script.Parent.kinds)

local Firing = {}

local modelFor = Tools.modelFor

local lastFired: { [Player]: { [string]: number } } = {}

-- Drops a leaving player's cooldown clocks.
local function forget(player: Player)
	lastFired[player] = nil
end

-- The FireWeapon handler: the remote's arguments, unchecked until the first test. An aim that is
-- not a Vector3 with finite components (RemoteGuard) is dropped, as is a shot from a player who
-- left (no Parent): `forget` has run, so make no cooldown clocks.
local function onFire(player: Player, weaponId, aim)
	if not player.Parent then
		return
	end
	if typeof(weaponId) ~= "string" or not RemoteGuard.isFiniteVector(aim) then
		return
	end
	local weapon = WeaponCatalog.get(weaponId)
	local character = player.Character
	if not weapon or not character then
		return
	end
	local tool = character:FindFirstChildOfClass("Tool")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local head = character:FindFirstChild("Head") :: BasePart?
	if
		not tool
		or tool:GetAttribute(Names.Attributes.WeaponId) ~= weaponId
		or not humanoid
		or humanoid.Health <= 0
		or not root
		or not head
	then
		return
	end
	if root.Anchored or Config.isInLobby(root.Position) then
		return -- frozen, or in the safe zone
	end

	local times = lastFired[player] or {}
	lastFired[player] = times
	local now = os.clock()
	if WeaponMath.coolingDown(times[weaponId], now, weapon.cooldown) then
		return
	end
	times[weaponId] = now

	local handle = tool:FindFirstChild("Handle") :: BasePart?
	local origin = head.Position
	local aimPoint = if (aim - origin).Magnitude < 0.5
		then origin + root.CFrame.LookVector * 10
		else aim
	WeaponSounds.fire(handle, weaponId)
	FIRE[weapon.kind]({
		player = player,
		weapon = weapon,
		character = character,
		root = root,
		origin = origin,
		muzzle = if handle
			then (handle.CFrame * (modelFor(weapon).muzzle or CFrame.new(
				0,
				0.5,
				-(weapon.length or 2)
			))).Position
			else origin,
		aim = aimPoint,
	})
end

Firing.forget = forget
Firing.onFire = onFire

return Firing
