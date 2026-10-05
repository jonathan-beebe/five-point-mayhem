-- Network events. The server creates them; clients wait for them.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local NAMES = {
	"Deploy", -- client -> server: { weaponId, weaponId, weaponId }
	"ChooseTeam", -- client -> server: teamName
	"FireWeapon", -- client -> server: weaponId, aimPosition
	"DriveInput", -- client -> server: throttle, steer (each -1..1)
	"AdminCommand", -- client -> server: command, target, item
	"MapCommand", -- client -> server: action ("sniper")
	"Announce", -- server -> client: text, color, seconds, style
}

local folder: Instance
if RunService:IsServer() then
	folder = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder")
	folder.Name = "Remotes"
	for _, name in NAMES do
		if not folder:FindFirstChild(name) then
			local remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = folder
		end
	end
	folder.Parent = ReplicatedStorage
else
	folder = ReplicatedStorage:WaitForChild("Remotes")
end

local Remotes: { [string]: RemoteEvent } = {}
for _, name in NAMES do
	Remotes[name] = folder:WaitForChild(name) :: RemoteEvent
end

return Remotes
