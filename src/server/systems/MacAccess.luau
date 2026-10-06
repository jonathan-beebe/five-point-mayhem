-- The MAC (mini admin console, client MacPanel). Admins always have it. An admin grants it to
-- anyone else with `/give <who> mac` (this server session) or `/give <who> mac permanent` (saved
-- in a DataStore, loaded on every join).
--
-- The HasMac attribute on the player tells the client whether to unlock the panel. The panel's
-- buttons run in Admin (macCommand), which checks HasMac.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Names = require(ReplicatedStorage.Shared.Names)
local Session = require(script.Parent.Session)

local MacAccess = {}

local STORE_NAME = "MacAccess"

-- DataStores fail in Studio without API access and on outages; the MAC then stays session-only.
local storeOk, store = pcall(DataStoreService.GetDataStore, DataStoreService, STORE_NAME)
if not storeOk then
	warn("[Mayhem] MAC DataStore unavailable: " .. tostring(store))
	store = nil
end

local function key(player: Player): string
	return "map_" .. player.UserId
end

function MacAccess.has(player: Player): boolean
	return player:GetAttribute(Names.Attributes.HasMac) == true
end

-- Grants the MAC. A permanent grant also saves it. Returns false only when the save fails.
function MacAccess.grant(player: Player, permanent: boolean): boolean
	player:SetAttribute(Names.Attributes.HasMac, true)
	if not permanent then
		return true
	end
	if not store then
		return false
	end
	local ok, problem = pcall(store.SetAsync, store, key(player), true, { player.UserId })
	if not ok then
		warn("[Mayhem] failed to save MAC for " .. player.Name .. ": " .. tostring(problem))
	end
	return ok
end

local function onPlayer(player: Player)
	if Session.isAdmin(player) then
		player:SetAttribute(Names.Attributes.HasMac, true)
		return
	end
	player:SetAttribute(Names.Attributes.HasMac, false)
	if not store then
		return
	end
	local ok, saved = pcall(store.GetAsync, store, key(player))
	if not ok then
		warn("[Mayhem] failed to load MAC for " .. player.Name .. ": " .. tostring(saved))
	elseif saved == true and player.Parent then
		player:SetAttribute(Names.Attributes.HasMac, true)
	end
end

function MacAccess.start()
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayer, player)
	end
end

return MacAccess
