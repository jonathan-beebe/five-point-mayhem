--!strict
-- The lobby armory's loadout rules and weapon card texts (client LobbyUI). A loadout is an array of
-- up to Config.LOADOUT_SIZE distinct weapon ids; the functions that change one change it in place.
-- Session.deploy applies isAvailable to a deployed loadout.
--
--   speedLabel(cooldown)          "rapid fire", "fast", "medium" or "slow"
--   subtitle(weapon)              the card's "<kind label> · <speed label>" line
--   statText(weapon)              "HEAL n", "DMG n", "DMG n×p" or ""
--   isAvailable(weapon, isAdmin)  admin-only weapons are listed for admins only
--   availableCount(isAdmin)       the weapons the armory lists
--   prune(selected, isAdmin)      drops unknown and unavailable ids
--   toggle(selected, id)          "removed", "added", or "full" (unchanged)
--
-- tools/tests/client_logic.luau compares each with the inline code it replaced.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local WeaponCatalog = require(ReplicatedStorage.Shared.WeaponCatalog)

local Loadout = {}

Loadout.KIND_LABELS = table.freeze({
	melee = "Melee",
	hitscan = "Gun",
	projectile = "Launcher",
	strike = "Spell",
	heal = "Support",
	blink = "Mobility",
	push = "Blast",
} :: { [string]: string })

function Loadout.speedLabel(cooldown: number): string
	if cooldown <= 0.15 then
		return "rapid fire"
	elseif cooldown <= 0.5 then
		return "fast"
	elseif cooldown <= 1.2 then
		return "medium"
	end
	return "slow"
end

function Loadout.subtitle(weapon: WeaponCatalog.Weapon): string
	return string.format(
		"%s · %s",
		Loadout.KIND_LABELS[weapon.kind] or weapon.kind,
		Loadout.speedLabel(weapon.cooldown)
	)
end

function Loadout.statText(weapon: WeaponCatalog.Weapon): string
	return if weapon.kind == "heal"
		then "HEAL " .. weapon.damage
		elseif weapon.damage > 0 then "DMG " .. weapon.damage .. (if weapon.pellets
			then "×" .. weapon.pellets
			else "")
		else ""
end

-- Session.deploy refuses admin-only weapons for everyone else.
function Loadout.isAvailable(weapon: WeaponCatalog.Weapon, isAdmin: boolean): boolean
	return not weapon.adminOnly or isAdmin
end

function Loadout.availableCount(isAdmin: boolean): number
	local available = 0
	for _, weapon in WeaponCatalog.ALL do
		if Loadout.isAvailable(weapon, isAdmin) then
			available += 1
		end
	end
	return available
end

function Loadout.prune(selected: { string }, isAdmin: boolean)
	for index = #selected, 1, -1 do
		local weapon = WeaponCatalog.get(selected[index])
		if not weapon or not Loadout.isAvailable(weapon, isAdmin) then
			table.remove(selected, index)
		end
	end
end

export type Toggled = "removed" | "added" | "full"

-- A chosen id comes off; a new one goes on the end while there is room.
function Loadout.toggle(selected: { string }, id: string): Toggled
	local index = table.find(selected, id)
	if index then
		table.remove(selected, index)
		return "removed"
	elseif #selected < Config.LOADOUT_SIZE then
		table.insert(selected, id)
		return "added"
	end
	return "full"
end

return table.freeze(Loadout)
