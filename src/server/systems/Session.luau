--!nolint DeprecatedApi
-- TODO: GetRankInGroup is deprecated; moving to GetRankInGroupAsync changes behaviour, so it waits.
-- Player lifecycle: teams, leaderstats, admin flag, collision groups, and deploying from the
-- lobby with a loadout of up to three weapons. Every respawn returns the player to the lobby.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Teams = game:GetService("Teams")

local Config = require(ReplicatedStorage.Shared.Config)
local Names = require(ReplicatedStorage.Shared.Names)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local WeaponCatalog = require(ReplicatedStorage.Shared.WeaponCatalog)
local Weapons = require(script.Parent.Weapons)
local Characters = require(script.Parent.util.Characters)

local Session = {}

local function groupFor(player: Player): string
	if not player:GetAttribute(Names.Attributes.Deployed) then
		return Names.CollisionGroups.LobbyPlayers
	end
	return if player:GetAttribute("LockedOut")
		then Names.CollisionGroups.LockedOutPlayers
		else Names.CollisionGroups.DeployedPlayers
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
	stats.Name = Names.Instances.Leaderstats
	for _, name in { "KOs", "Monsters" } do
		local value = Instance.new("IntValue")
		value.Name = name
		value.Parent = stats
	end
	stats.Parent = player
end

local function onCharacter(player: Player, character: Model)
	player:SetAttribute(Names.Attributes.Deployed, false)
	player:SetAttribute("LockedOut", false)
	setCollisionGroup(character, Names.CollisionGroups.LobbyPlayers)
	character.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("BasePart") then
			descendant.CollisionGroup = groupFor(player)
		end
	end)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	humanoid:SetAttribute(Names.Attributes.BaseWalkSpeed, humanoid.WalkSpeed)
	humanoid.Died:Connect(function()
		player:SetAttribute(Names.Attributes.Deployed, false)
	end)
end

local function onPlayer(player: Player)
	player.Neutral = false
	player.Team = Teams:FindFirstChild(Config.FFA_TEAM) :: Team
	player:SetAttribute(Names.Attributes.IsAdmin, Session.isAdmin(player))
	leaderstats(player)
	player.CharacterAdded:Connect(function(character)
		onCharacter(player, character)
	end)
	if player.Character then
		onCharacter(player, player.Character)
	end
end

-- The loadout is an array of 0 to LOADOUT_SIZE distinct weapon ids. Anything else is refused.
local function deploy(player: Player, ids: any)
	if typeof(ids) ~= "table" or player:GetAttribute(Names.Attributes.Deployed) then
		return
	end
	local isAdmin = player:GetAttribute(Names.Attributes.IsAdmin) == true
	local seen = {}
	local count = 0
	for key, id in ids do
		count += 1
		local weapon = typeof(id) == "string" and WeaponCatalog.get(id)
		if
			key ~= count
			or count > Config.LOADOUT_SIZE
			or not weapon
			or seen[id]
			or (weapon.adminOnly and not isAdmin)
		then
			return
		end
		seen[id] = true
	end
	local character, humanoid, root = Characters.parts(player)
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
	player:SetAttribute(Names.Attributes.Deployed, true)
	player:SetAttribute("Loadout", table.concat(ids, ","))
	setCollisionGroup(character, Names.CollisionGroups.DeployedPlayers)
end

local function chooseTeam(player: Player, teamName: any)
	if typeof(teamName) ~= "string" or player:GetAttribute(Names.Attributes.Deployed) then
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
		local character, humanoid, root = Characters.parts(player)
		if
			not character
			or not humanoid
			or not root
			or humanoid.Health <= 0
			or not player:GetAttribute(Names.Attributes.Deployed)
			or player:GetAttribute(Names.Attributes.IsAdmin)
		then
			continue
		end
		local position = root.Position
		local flat = Vector2.new(position.X, position.Z)
		if not player:GetAttribute("LockedOut") then
			if flat.Magnitude > Config.LOBBY_RADIUS + 4 then
				player:SetAttribute("LockedOut", true)
				setCollisionGroup(character, Names.CollisionGroups.LockedOutPlayers)
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
