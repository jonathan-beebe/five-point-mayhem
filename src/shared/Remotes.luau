--!strict
-- Network events. The server creates them; clients wait for them.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local isServer = RunService:IsServer()

local folder: Instance
if isServer then
	folder = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder")
	folder.Name = "Remotes"
else
	folder = ReplicatedStorage:WaitForChild("Remotes")
end

-- The server finds or creates the remote in the folder; clients wait for it.
local function remote(name: string): RemoteEvent
	if isServer then
		local existing = folder:FindFirstChild(name)
		if existing then
			return existing :: RemoteEvent
		end
		local created = Instance.new("RemoteEvent")
		created.Name = name
		created.Parent = folder
		return created
	end
	return folder:WaitForChild(name) :: RemoteEvent
end

-- Fields are made in this order. The type is inferred, so a misspelt remote is a type error.
local Remotes = {
	Deploy = remote("Deploy"), -- client -> server: { weaponId, weaponId, weaponId }
	ChooseTeam = remote("ChooseTeam"), -- client -> server: teamName
	FireWeapon = remote("FireWeapon"), -- client -> server: weaponId, aimPosition
	DriveInput = remote("DriveInput"), -- client -> server: throttle, steer, lift (each -1..1; lift for flying pods)
	PodCommand = remote("PodCommand"), -- client -> server: action ("launch", "home" or "land"), for the pod the player drives
	AdminCommand = remote("AdminCommand"), -- client -> server: command, target, item
	MacCommand = remote("MacCommand"), -- client -> server: action ("sniper" or "nuke")
	Announce = remote("Announce"), -- server -> client: text, color, seconds, style
	Nuke = remote("Nuke"), -- server -> client: the MAC's NUKE is falling (Config.NUKE_GROUND)
}

if isServer then
	folder.Parent = ReplicatedStorage
end

-- Every field is a RemoteEvent; the checker types a record's iteration values as unknown.
for key, event in Remotes :: { [string]: RemoteEvent } do
	assert(key == event.Name, "Remotes." .. key .. " is named " .. event.Name)
end

return Remotes
