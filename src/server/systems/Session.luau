-- Player lifecycle: teams, leaderstats, admin flag, collision groups, and deploying from the
-- lobby with a three-weapon loadout. Every respawn returns the player to the lobby.

local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Teams = game:GetService("Teams")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local WeaponCatalog = require(ReplicatedStorage.Shared.WeaponCatalog)
local Weapons = require(script.Parent.Weapons)

local Session = {}

-- Collision groups: lobby gates stop undeployed players (and creatures) but let deployed ones out.
function Session.registerCollisionGroups()
	for _, group in { "LobbyPlayers", "DeployedPlayers", "LobbyGate" } do
		if not PhysicsService:IsCollisionGroupRegistered(group) then
			PhysicsService:RegisterCollisionGroup(group)
		end
	end
	PhysicsService:CollisionGroupSetCollidable("LobbyGate", "DeployedPlayers", false)
end

local function setCollisionGroup(character: Model, group: string)
	for _, descendant in character:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.CollisionGroup = group
		end
	end
end

function Session.isAdmin(player: Player): boolean
	if RunService:IsStudio() then
		return true
	end
	if table.find(Config.ADMIN_USER_IDS, player.UserId) then
		return true
	end
	if game.CreatorType == Enum.CreatorType.User then
		return player.UserId == game.CreatorId
	end
	local ok, rank = pcall(player.GetRankInGroup, player, game.CreatorId)
	return ok and rank == 255
end

local function createTeams()
	for _, spec in Config.TEAMS do
		if not Teams:FindFirstChild(spec.name) then
			local team = Instance.new("Team")
			team.Name = spec.name
			team.TeamColor = spec.color
			team.AutoAssignable = false
			team.Parent = Teams
		end
	end
end

local function leaderstats(player: Player)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	for _, name in { "KOs", "Monsters" } do
		local value = Instance.new("IntValue")
		value.Name = name
		value.Parent = stats
	end
	stats.Parent = player
end

local function onCharacter(player: Player, character: Model)
	player:SetAttribute("Deployed", false)
	setCollisionGroup(character, "LobbyPlayers")
	character.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("BasePart") then
			descendant.CollisionGroup = if player:GetAttribute("Deployed")
				then "DeployedPlayers"
				else "LobbyPlayers"
		end
	end)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	humanoid:SetAttribute("BaseWalkSpeed", humanoid.WalkSpeed)
	humanoid.Died:Connect(function()
		player:SetAttribute("Deployed", false)
	end)
end

local function onPlayer(player: Player)
	player.Neutral = false
	player.Team = Teams:FindFirstChild(Config.FFA_TEAM) :: Team
	player:SetAttribute("IsAdmin", Session.isAdmin(player))
	leaderstats(player)
	player.CharacterAdded:Connect(function(character)
		onCharacter(player, character)
	end)
	if player.Character then
		onCharacter(player, player.Character)
	end
end

local function deploy(player: Player, ids: any)
	if typeof(ids) ~= "table" or #ids ~= Config.LOADOUT_SIZE or player:GetAttribute("Deployed") then
		return
	end
	local seen = {}
	for _, id in ids do
		if typeof(id) ~= "string" or not WeaponCatalog.get(id) or seen[id] then
			return
		end
		seen[id] = true
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if
		not character
		or not humanoid
		or humanoid.Health <= 0
		or not root
		or not Config.isInLobby(root.Position)
	then
		return
	end

	local backpack = player:FindFirstChildOfClass("Backpack")
	if backpack then
		backpack:ClearAllChildren()
	end
	for _, id in ids do
		Weapons.give(player, id)
	end
	player:SetAttribute("Deployed", true)
	player:SetAttribute("Loadout", table.concat(ids, ","))
	setCollisionGroup(character, "DeployedPlayers")
end

local function chooseTeam(player: Player, teamName: any)
	if typeof(teamName) ~= "string" or player:GetAttribute("Deployed") then
		return
	end
	for _, spec in Config.TEAMS do
		if spec.name == teamName then
			player.Team = Teams:FindFirstChild(teamName) :: Team
			return
		end
	end
end

function Session.start()
	createTeams()
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayer, player)
	end
	Remotes.Deploy.OnServerEvent:Connect(deploy)
	Remotes.ChooseTeam.OnServerEvent:Connect(chooseTeam)
end

return Session
