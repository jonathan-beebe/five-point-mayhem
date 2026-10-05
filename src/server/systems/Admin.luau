-- God powers. Available as chat commands and from the admin panel (client AdminPanel).
--
--   /mayhem                    destroy everyone outside the lobby
--   /give <who> <item>         any weapon or vehicle id, or: speed, jump, giant, heal, shield,
--                              car (a random vehicle), arsenal
--   /give <who> map [permanent] the map panel, for this session or saved for good
--   /meteors [seconds]         meteor storm across the board
--   /gravity                   toggle moon gravity
--   /freeze <who>              freeze players solid for 10 seconds
--   /horde [who]               summon a monster horde (around a player, or across the board)
--   /night                     toggle day and night
--
-- <who> is "all", "me", or the start of a player's name.

local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local VehicleCatalog = require(ReplicatedStorage.Shared.VehicleCatalog)
local WeaponCatalog = require(ReplicatedStorage.Shared.WeaponCatalog)
local Combat = require(script.Parent.Combat)
local Creatures = require(script.Parent.Creatures)
local MapAccess = require(script.Parent.MapAccess)
local Session = require(script.Parent.Session)
local Vehicles = require(script.Parent.Vehicles)
local Weapons = require(script.Parent.Weapons)

local Admin = {}

local rgb = Color3.fromRGB
local random = Random.new()

Admin.GIFTS = { "speed", "jump", "giant", "heal", "shield", "car", "arsenal" }

local function announce(text: string, color: Color3, seconds: number, style: string?)
	Remotes.Announce:FireAllClients(text, color, seconds, style)
end

local function resolveTargets(caller: Player, who: string?): { Player }
	local query = string.lower(who or "me")
	if query == "all" or query == "everyone" then
		return Players:GetPlayers()
	elseif query == "me" then
		return { caller }
	end
	for _, player in Players:GetPlayers() do
		local name = string.lower(player.Name)
		local display = string.lower(player.DisplayName)
		if string.sub(name, 1, #query) == query or string.sub(display, 1, #query) == query then
			return { player }
		end
	end
	return {}
end

local function characterParts(player: Player): (Model?, Humanoid?, BasePart?)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if character and humanoid and root and humanoid.Health > 0 then
		return character, humanoid, root
	end
	return nil, nil, nil
end

-- 1. MAYHEM ----------------------------------------------------------------------------------

local mayhemRunning = false

local function mayhem()
	if mayhemRunning then
		return
	end
	mayhemRunning = true
	local sky = Instance.new("ColorCorrectionEffect")
	sky.TintColor = rgb(255, 120, 120)
	sky.Parent = Lighting
	for count = 3, 1, -1 do
		announce("☢ TOTAL MAYHEM IN " .. count .. " ☢", rgb(255, 50, 50), 1, "alarm")
		task.wait(1)
	end
	announce("☢ MAYHEM ☢", rgb(255, 50, 50), 3, "mayhem")
	for _, player in Players:GetPlayers() do
		local character, humanoid, root = characterParts(player)
		if character and humanoid and root and not Config.isInLobby(root.Position) then
			local blast = Instance.new("Explosion")
			blast.Position = root.Position
			blast.BlastPressure = 0
			blast.BlastRadius = 12
			blast.DestroyJointRadiusPercent = 0
			blast.Parent = workspace
			local shield = character:FindFirstChildOfClass("ForceField")
			if shield then
				shield:Destroy()
			end
			humanoid.Health = 0
		end
	end
	Creatures.killAll()
	TweenService:Create(sky, TweenInfo.new(3), { TintColor = rgb(255, 255, 255) }):Play()
	Debris:AddItem(sky, 3)
	mayhemRunning = false
end

-- 2. GIVE ------------------------------------------------------------------------------------

local function gift(player: Player, item: string): boolean
	local character, humanoid, root = characterParts(player)
	local backpack = player:FindFirstChildOfClass("Backpack")
	local weapon = WeaponCatalog.find(item)
	local vehicle = VehicleCatalog.get(item)
	if item == "arsenal" then
		for _, each in WeaponCatalog.ALL do
			Weapons.give(player, each.id)
		end
		return true
	elseif not character or not humanoid or not root then
		return weapon ~= nil and backpack ~= nil and Weapons.give(player, weapon.id)
	elseif item == "speed" then
		humanoid:SetAttribute("BaseWalkSpeed", 40)
		humanoid.WalkSpeed = 40
	elseif item == "jump" then
		humanoid.UseJumpPower = true
		humanoid.JumpPower = 120
	elseif item == "giant" then
		for _, scale in { "BodyHeightScale", "BodyWidthScale", "BodyDepthScale", "HeadScale" } do
			local value = humanoid:FindFirstChild(scale) :: NumberValue?
			if value then
				value.Value = 2.5
			end
		end
	elseif item == "heal" then
		humanoid.Health = humanoid.MaxHealth
	elseif item == "shield" then
		local shield = Instance.new("ForceField")
		shield.Parent = character
		Debris:AddItem(shield, 30)
	elseif item == "car" or vehicle then
		local look = root.CFrame.LookVector
		Vehicles.spawnNear(root.Position + look * 8, look, if vehicle then vehicle.id else nil)
	elseif weapon then
		Weapons.give(player, weapon.id)
	else
		return false
	end
	return true
end

local function giveMap(caller: Player, who: string?, duration: string?)
	local permanent = duration ~= nil and string.lower(duration) == "permanent"
	local names, unsaved = {}, {}
	for _, player in resolveTargets(caller, who) do
		table.insert(
			if MapAccess.grant(player, permanent) then names else unsaved,
			player.DisplayName
		)
	end
	if #names > 0 then
		local label = if permanent then "🗺 MAP (PERMANENT)" else "🗺 MAP"
		announce("🎁 " .. label .. " → " .. table.concat(names, ", "), rgb(255, 220, 80), 3)
	end
	if #unsaved > 0 then
		announce(
			"⚠ MAP NOT SAVED, THIS SESSION ONLY → " .. table.concat(unsaved, ", "),
			rgb(255, 140, 60),
			4
		)
	end
end

local function give(caller: Player, who: string?, item: string?, extra: string?)
	if not item then
		return
	end
	local query = string.lower(item)
	if query == "map" then
		giveMap(caller, who, extra)
		return
	end
	local weapon = WeaponCatalog.find(query)
	local vehicle = VehicleCatalog.get(query)
	local label = if table.find(Admin.GIFTS, query)
		then string.upper(query)
		elseif vehicle then vehicle.name
		elseif weapon then weapon.name
		else nil
	if not label then
		return
	end
	local names = {}
	for _, player in resolveTargets(caller, who) do
		if gift(player, query) then
			table.insert(names, player.DisplayName)
		end
	end
	if #names > 0 then
		announce("🎁 " .. label .. " → " .. table.concat(names, ", "), rgb(255, 220, 80), 3)
	end
end

-- 3. METEORS ---------------------------------------------------------------------------------

local function meteors(seconds: number)
	announce("☄ METEOR STORM ☄", rgb(255, 140, 40), 3, "alarm")
	local stop = os.clock() + seconds
	task.spawn(function()
		while os.clock() < stop do
			for _ = 1, 3 do
				local target = Config.pointAt(
					random:NextNumber(0, math.pi * 2),
					random:NextNumber(Config.LOBBY_RADIUS + 20, Config.WORLD_RADIUS - 50)
				)
				local rock = Instance.new("Part")
				rock.Shape = Enum.PartType.Ball
				rock.Anchored = true
				rock.CanCollide = false
				rock.CanQuery = false
				rock.Size = Vector3.one * random:NextNumber(6, 12)
				rock.Material = Enum.Material.Basalt
				rock.Color = rgb(80, 40, 30)
				rock.CFrame = CFrame.new(
					target
						+ Vector3.new(random:NextNumber(-80, 80), 300, random:NextNumber(-80, 80))
				)
				Instance.new("Fire", rock).Size = 15
				rock.Parent = workspace
				TweenService:Create(
					rock,
					TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
					{ CFrame = CFrame.new(target) }
				):Play()
				task.delay(1.2, function()
					rock:Destroy()
					Combat.explode(nil, target, 16, 45, "burn")
				end)
			end
			task.wait(0.35)
		end
	end)
end

-- 4. GRAVITY ---------------------------------------------------------------------------------

local function gravity()
	local moon = workspace.Gravity > Config.MOON_GRAVITY + 1
	workspace.Gravity = if moon then Config.MOON_GRAVITY else Config.NORMAL_GRAVITY
	announce(if moon then "🌙 MOON GRAVITY" else "🌍 NORMAL GRAVITY", rgb(180, 200, 255), 3)
end

-- 5. FREEZE ----------------------------------------------------------------------------------

local function freeze(caller: Player, who: string?)
	local names = {}
	for _, player in resolveTargets(caller, who or "all") do
		local character, _, root = characterParts(player)
		if
			character
			and root
			and not Config.isInLobby(root.Position)
			and (player ~= caller or who == "me")
		then
			Combat.freeze(character, 10)
			table.insert(names, player.DisplayName)
		end
	end
	if #names > 0 then
		announce("❄ FROZEN: " .. table.concat(names, ", "), rgb(160, 220, 255), 3)
	end
end

-- Bonus powers -------------------------------------------------------------------------------

local function horde(caller: Player, who: string?)
	if who then
		for _, player in resolveTargets(caller, who) do
			local _, _, root = characterParts(player)
			if root then
				Creatures.horde(root.Position, 12)
			end
		end
	else
		for index = 1, #Config.REGIONS do
			Creatures.horde(Config.pointAt(Config.regionAngle(index) + math.rad(36), 300), 6)
		end
	end
	announce("👹 THE HORDE APPROACHES 👹", rgb(140, 255, 100), 3, "alarm")
end

local function night()
	local isDay = Lighting.ClockTime > 6 and Lighting.ClockTime < 18
	TweenService:Create(Lighting, TweenInfo.new(3), { ClockTime = if isDay then 0 else 14 }):Play()
	announce(if isDay then "🌑 NIGHT FALLS" else "☀ DAYBREAK", rgb(200, 200, 255), 3)
end

-- Dispatch -----------------------------------------------------------------------------------

function Admin.run(caller: Player, command: string, first: string?, second: string?, third: string?)
	if not Session.isAdmin(caller) then
		return
	end
	command = string.lower(command)
	if command == "mayhem" then
		task.spawn(mayhem)
	elseif command == "give" then
		give(caller, first, second, third)
	elseif command == "meteors" then
		meteors(math.clamp(tonumber(first) or 30, 5, 120))
	elseif command == "gravity" then
		gravity()
	elseif command == "freeze" then
		freeze(caller, first)
	elseif command == "horde" then
		horde(caller, first)
	elseif command == "night" then
		night()
	end
end

function Admin.start()
	Remotes.AdminCommand.OnServerEvent:Connect(function(player, command, first, second)
		if typeof(command) ~= "string" then
			return
		end
		Admin.run(
			player,
			command,
			if typeof(first) == "string" then first else nil,
			if typeof(second) == "string" then second else nil
		)
	end)

	local commands = Instance.new("Folder")
	commands.Name = "MayhemCommands"
	commands.Parent = TextChatService
	for _, name in { "mayhem", "give", "meteors", "gravity", "freeze", "horde", "night" } do
		local command = Instance.new("TextChatCommand")
		command.Name = "Mayhem_" .. name
		command.PrimaryAlias = "/" .. name
		command.Parent = commands
		command.Triggered:Connect(function(source, text)
			local player = Players:GetPlayerByUserId(source.UserId)
			if not player then
				return
			end
			local words = string.split(text, " ")
			Admin.run(player, name, words[2], words[3], words[4])
		end)
	end
end

return Admin
