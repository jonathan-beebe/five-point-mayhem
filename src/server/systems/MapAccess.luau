-- The map: a mini admin panel (client MapPanel). Admins always have it. An admin grants it to
-- anyone else with `/give <who> map` (this server session) or `/give <who> map permanent` (saved
-- in a DataStore, loaded on every join).
--
-- The HasMap attribute on the player tells the client whether to unlock the panel. The panel's
-- buttons run in Admin (mapCommand), which checks HasMap.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local Session = require(script.Parent.Session)

local MapAccess = {}

local STORE_NAME = "MapAccess"

-- DataStores fail in Studio without API access and on outages; the map then stays session-only.
local storeOk, store = pcall(DataStoreService.GetDataStore, DataStoreService, STORE_NAME)
if not storeOk then
	warn("[Mayhem] map DataStore unavailable: " .. tostring(store))
	store = nil
end

local function key(player: Player): string
	return "map_" .. player.UserId
end

function MapAccess.has(player: Player): boolean
	return player:GetAttribute("HasMap") == true
end

-- Grants the map. A permanent grant also saves it. Returns false only when the save fails.
function MapAccess.grant(player: Player, permanent: boolean): boolean
	player:SetAttribute("HasMap", true)
	if not permanent then
		return true
	end
	if not store then
		return false
	end
	local ok, problem = pcall(store.SetAsync, store, key(player), true, { player.UserId })
	if not ok then
		warn("[Mayhem] failed to save map for " .. player.Name .. ": " .. tostring(problem))
	end
	return ok
end

local function onPlayer(player: Player)
	if Session.isAdmin(player) then
		player:SetAttribute("HasMap", true)
		return
	end
	player:SetAttribute("HasMap", false)
	if not store then
		return
	end
	local ok, saved = pcall(store.GetAsync, store, key(player))
	if not ok then
		warn("[Mayhem] failed to load map for " .. player.Name .. ": " .. tostring(saved))
	elseif saved == true and player.Parent then
		player:SetAttribute("HasMap", true)
	end
end

function MapAccess.start()
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayer, player)
	end
end

return MapAccess
