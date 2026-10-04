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
-- Once a deployed non-admin has left the lobby they are LockedOut: the gates stop them again, so
-- only admins can walk back in.
function Session.registerCollisionGroups()
	for _, group in { "LobbyPlayers", "DeployedPlayers", "LockedOutPlayers", "LobbyGate" } do
		if not PhysicsService:IsCollisionGroupRegistered(group) then
			PhysicsService:RegisterCollisionGroup(group)
		end
	end
	PhysicsService:CollisionGroupSetCollidable("LobbyGate", "DeployedPlayers", false)
end

local function groupFor(player: Player): string
	if not player:GetAttribute("Deployed") then
		return "LobbyPlayers"
	end
	return if player:GetAttribute("LockedOut") then "LockedOutPlayers" else "DeployedPlayers"
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
	player:SetAttribute("LockedOut", false)
	setCollisionGroup(character, "LobbyPlayers")
	character.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("BasePart") then
			descendant.CollisionGroup = groupFor(player)
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
	local isAdmin = player:GetAttribute("IsAdmin") == true
	local seen = {}
	for _, id in ids do
		local weapon = typeof(id) == "string" and WeaponCatalog.get(id)
		if not weapon or seen[id] or (weapon.adminOnly and not isAdmin) then
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

-- Locks deployed non-admins out once they leave the lobby, and puts any who get back inside (a
-- teleport, a shove through a gate) just outside the wall again.
local LOCKOUT_CHECK_INTERVAL = 0.25

local function enforceLockout()
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if
			not character
			or not humanoid
			or not root
			or humanoid.Health <= 0
			or not player:GetAttribute("Deployed")
			or player:GetAttribute("IsAdmin")
		then
			continue
		end
		local position = root.Position
		local flat = Vector2.new(position.X, position.Z)
		if not player:GetAttribute("LockedOut") then
			if flat.Magnitude > Config.LOBBY_RADIUS + 4 then
				player:SetAttribute("LockedOut", true)
				setCollisionGroup(character, "LockedOutPlayers")
			end
		elseif Config.isInLobby(position) then
			if humanoid.SeatPart then
				humanoid.Sit = false
			end
			local outward = if flat.Magnitude > 0.1 then flat.Unit else Vector2.new(0, 1)
			local outside = outward * (Config.LOBBY_RADIUS + 8)
			local spot = Vector3.new(outside.X, position.Y, outside.Y)
			character:PivotTo(CFrame.lookAt(spot, spot + Vector3.new(outward.X, 0, outward.Y)))
		end
	end
end

function Session.start()
	createTeams()
	task.spawn(function()
		while true do
			task.wait(LOCKOUT_CHECK_INTERVAL)
			enforceLockout()
		end
	end)
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayer, player)
	end
	Remotes.Deploy.OnServerEvent:Connect(deploy)
	Remotes.ChooseTeam.OnServerEvent:Connect(chooseTeam)
end

return Session
