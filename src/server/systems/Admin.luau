-- God powers. Available as chat commands and from the admin panel (client AdminPanel).
--
--   /mayhem                    destroy everyone outside the lobby
--   /give <who> <item>         any weapon or vehicle id, or: speed, jump, giant, heal, shield,
--                              car (a random vehicle), arsenal
--   /give <who> mac [permanent] the MAC panel, for this session or saved for good
--   /meteors [seconds]         meteor storm across the board
--   /gravity                   toggle moon gravity
--   /freeze <who>              freeze players solid for 10 seconds
--   /horde [who]               summon a monster horde (around a player, or across the board)
--   /day                       jump to morning (cycle keeps running)
--   /night                     jump to nightfall (cycle keeps running)
--   /goto <world> [who]        send players to a world's gate, in the vehicle they are driving
--                              or riding (world: the start of its name or its landmark's id)
--
-- <who> is "all", "me", or the start of a player's name.
--
-- The command ids, chat list, panel buttons, gifts and power tuning are in
-- src/shared/AdminCommands.luau; each id's handler is in HANDLERS below.

local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local TweenService = game:GetService("TweenService")

local AdminCommands = require(ReplicatedStorage.Shared.AdminCommands)
local Config = require(ReplicatedStorage.Shared.Config)
local Names = require(ReplicatedStorage.Shared.Names)
local RemoteActions = require(ReplicatedStorage.Shared.RemoteActions)
local RemoteGuard = require(ReplicatedStorage.Shared.RemoteGuard)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local VehicleCatalog = require(ReplicatedStorage.Shared.VehicleCatalog)
local WeaponCatalog = require(ReplicatedStorage.Shared.WeaponCatalog)
local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local Combat = require(script.Parent.Combat)
local Creatures = require(script.Parent.Creatures)
local DayNight = require(script.Parent.DayNight)
local MacAccess = require(script.Parent.MacAccess)
local Session = require(script.Parent.Session)
local Vehicles = require(script.Parent.Vehicles)
local Weapons = require(script.Parent.Weapons)
local Characters = require(script.Parent.util.Characters)
local Seats = require(script.Parent.util.Seats)

local Admin = {}

local rgb = Color3.fromRGB
local random = Random.new()

local TUNING = AdminCommands.TUNING
-- A standing character's root above the ground.
local ROOT_HEIGHT = 3

local function announce(text: string, color: Color3, seconds: number, style: string?)
	Remotes.Announce:FireAllClients(text, color, seconds, style)
end

local function playerNames(player: Player): (string, string)
	return player.Name, player.DisplayName
end

local function resolveTargets(caller: Player, who: string?): { Player }
	return AdminCommands.resolveTargets(Players:GetPlayers(), caller, who, playerNames)
end

-- 1. MAYHEM (and the MAC's NUKE) -------------------------------------------------------------

-- One countdown at a time, shared by MAYHEM and NUKE.
local doomRunning = false

local function redSky(): ColorCorrectionEffect
	local sky = Instance.new("ColorCorrectionEffect")
	sky.TintColor = rgb(255, 120, 120)
	sky.Parent = Lighting
	return sky
end

local function clearSky(sky: ColorCorrectionEffect)
	TweenService:Create(sky, TweenInfo.new(3), { TintColor = rgb(255, 255, 255) }):Play()
	Debris:AddItem(sky, 3)
end

-- Kills through shields.
local function obliterate(character: Model, humanoid: Humanoid, root: BasePart)
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

-- Counts down, then kills every player outside the lobby and every monster.
local function mayhem()
	if doomRunning then
		return
	end
	doomRunning = true
	local sky = redSky()
	for count = 3, 1, -1 do
		announce(
			"☢ TOTAL MAYHEM IN " .. count .. " ☢",
			rgb(255, 50, 50),
			1,
			RemoteActions.AnnounceStyle.ALARM
		)
		task.wait(1)
	end
	announce("☢ MAYHEM ☢", rgb(255, 50, 50), 3, RemoteActions.AnnounceStyle.MAYHEM)
	for _, player in Players:GetPlayers() do
		local character, humanoid, root = Characters.living(player)
		if character and humanoid and root and not Config.isInLobby(root.Position) then
			obliterate(character, humanoid, root)
		end
	end
	Creatures.killAll()
	clearSky(sky)
	doomRunning = false
end

-- A bomb falls on the lobby (each client draws it: client NukeStrike), then the blast wave kills
-- every player but the caller as it reaches them, lobby included, and finally every monster.
local function nuke(caller: Player)
	if doomRunning then
		return
	end
	doomRunning = true
	local sky = redSky()
	local ground = Config.NUKE_GROUND
	Remotes.Nuke:FireAllClients(ground)
	announce(
		"☢ NUKE INCOMING ☢",
		rgb(255, 50, 50),
		Config.NUKE_FALL_SECONDS - 3,
		RemoteActions.AnnounceStyle.ALARM
	)
	task.wait(Config.NUKE_FALL_SECONDS - 3)
	for count = 3, 1, -1 do
		announce(
			"☢ NUKE INCOMING " .. count .. " ☢",
			rgb(255, 50, 50),
			1,
			RemoteActions.AnnounceStyle.ALARM
		)
		task.wait(1)
	end
	announce(
		"☢ NUKED BY " .. string.upper(caller.DisplayName) .. " ☢",
		rgb(255, 50, 50),
		3,
		RemoteActions.AnnounceStyle.MAYHEM
	)
	-- Each player is struck once, so nobody who respawns in the lobby dies again.
	local struck: { [Player]: boolean } = { [caller] = true }
	local function sweep(radius: number)
		for _, player in Players:GetPlayers() do
			local character, humanoid, root = Characters.living(player)
			if character and humanoid and root and not struck[player] then
				local offset = root.Position - ground
				if Vector2.new(offset.X, offset.Z).Magnitude <= radius then
					struck[player] = true
					obliterate(character, humanoid, root)
				end
			end
		end
	end
	local impact = os.clock()
	while os.clock() - impact < Config.NUKE_WAVE_SECONDS do
		sweep(Config.nukeWaveRadius(os.clock() - impact))
		task.wait()
	end
	sweep(math.huge)
	Creatures.killAll()
	clearSky(sky)
	doomRunning = false
end

-- 2. GIVE ------------------------------------------------------------------------------------

-- The power-ups `gift` gives a living character, by AdminCommands.POWER_UPS id; `arsenal` and
-- `car` are branches of their own in `gift`.
type PowerUp = (player: Player, character: Model, humanoid: Humanoid, root: BasePart) -> ()
local POWER_UP: { [string]: PowerUp } = {
	speed = function(_, _, humanoid)
		humanoid:SetAttribute(Names.Attributes.BaseWalkSpeed, TUNING.SPEED)
		humanoid.WalkSpeed = TUNING.SPEED
	end,
	jump = function(_, _, humanoid)
		humanoid.UseJumpPower = true
		humanoid.JumpPower = TUNING.JUMP_POWER
	end,
	giant = function(_, _, humanoid)
		for _, scale in { "BodyHeightScale", "BodyWidthScale", "BodyDepthScale", "HeadScale" } do
			local value = humanoid:FindFirstChild(scale) :: NumberValue?
			if value then
				value.Value = TUNING.GIANT_SCALE
			end
		end
	end,
	heal = function(_, _, humanoid)
		humanoid.Health = humanoid.MaxHealth
	end,
	shield = function(_, character)
		local shield = Instance.new("ForceField")
		shield.Parent = character
		Debris:AddItem(shield, TUNING.SHIELD_SECONDS)
	end,
}

local function gift(player: Player, item: string): boolean
	local character, humanoid, root = Characters.living(player)
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
	elseif POWER_UP[item] then
		-- Before the vehicle and weapon matches: WeaponCatalog.find matches by prefix.
		POWER_UP[item](player, character, humanoid, root)
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

local function giveMac(caller: Player, who: string?, duration: string?)
	local permanent = duration ~= nil and string.lower(duration) == "permanent"
	local names, unsaved = {}, {}
	for _, player in resolveTargets(caller, who) do
		table.insert(
			if MacAccess.grant(player, permanent) then names else unsaved,
			player.DisplayName
		)
	end
	if #names > 0 then
		local label = if permanent then "🖥 MAC (PERMANENT)" else "🖥 MAC"
		announce("🎁 " .. label .. " → " .. table.concat(names, ", "), rgb(255, 220, 80), 3)
	end
	if #unsaved > 0 then
		announce(
			"⚠ MAC NOT SAVED, THIS SESSION ONLY → " .. table.concat(unsaved, ", "),
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
	if query == "mac" then
		giveMac(caller, who, extra)
		return
	end
	local weapon = WeaponCatalog.find(query)
	local vehicle = VehicleCatalog.get(query)
	local label = AdminCommands.giftLabel(query, vehicle, weapon)
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
	announce("☄ METEOR STORM ☄", rgb(255, 140, 40), 3, RemoteActions.AnnounceStyle.ALARM)
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
					Combat.explode(nil, target, TUNING.METEOR_RADIUS, TUNING.METEOR_DAMAGE, "burn")
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
		local character, _, root = Characters.living(player)
		if
			character
			and root
			and not Config.isInLobby(root.Position)
			and (player ~= caller or who == "me")
		then
			Combat.freeze(character, TUNING.FREEZE_SECONDS)
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
			local _, _, root = Characters.living(player)
			if root then
				Creatures.horde(root.Position, TUNING.HORDE_AROUND_PLAYER)
			end
		end
	else
		for index = 1, #Config.REGIONS do
			Creatures.horde(
				Config.pointAt(Config.betweenRegions(index), 300),
				TUNING.HORDE_PER_REGION
			)
		end
	end
	announce(
		"👹 THE HORDE APPROACHES 👹",
		rgb(140, 255, 100),
		3,
		RemoteActions.AnnounceStyle.ALARM
	)
end

local function setTime(night: boolean)
	DayNight.jumpTo(night)
	announce(if night then "🌑 NIGHT FALLS" else "☀ DAYBREAK", rgb(200, 200, 255), 3)
end

local function regionNames(region: typeof(Config.REGIONS[1])): (string, string)
	return region.world, region.id
end

-- Sends each target to world `world`'s gate (WorldLayout.arrival, one spot each): a seated
-- target's vehicle goes with them (Vehicles.carry); otherwise they leave any seat and go on foot.
local function sendToGate(caller: Player, world: string?, who: string?)
	local index = AdminCommands.worldIndex(world, Config.REGIONS, regionNames)
	if not index then
		return
	end
	local names = {}
	for _, player in resolveTargets(caller, who) do
		local character, humanoid, root = Characters.living(player)
		if character and humanoid and root then
			local spot = WorldLayout.arrival(index, #names + 1)
			if not Vehicles.carry(humanoid, spot) then
				if humanoid.SeatPart then
					Seats.unseat(humanoid.SeatPart :: Seat, humanoid)
				end
				Characters.moveRootTo(character, root, spot * CFrame.new(0, ROOT_HEIGHT, 0))
			end
			table.insert(names, player.DisplayName)
		end
	end
	if #names > 0 then
		announce(
			"🚪 " .. table.concat(names, ", ") .. " → " .. Config.REGIONS[index].world,
			rgb(200, 180, 255),
			3
		)
	end
end

-- Dispatch -----------------------------------------------------------------------------------

-- One handler per AdminCommands id (tools/tests/admin_commands checks both ways). The test reads
-- this table with Sandbox.loadIsolated: keep it free of top-level work on required values.
type Handler = (caller: Player, first: string?, second: string?, third: string?) -> ()
local HANDLERS: { [string]: Handler } = {
	mayhem = function()
		task.spawn(mayhem)
	end,
	give = function(caller, first, second, third)
		give(caller, first, second, third)
	end,
	meteors = function(_, first)
		meteors(AdminCommands.meteorSeconds(first))
	end,
	gravity = function()
		gravity()
	end,
	freeze = function(caller, first)
		freeze(caller, first)
	end,
	horde = function(caller, first)
		horde(caller, first)
	end,
	day = function()
		setTime(false)
	end,
	night = function()
		setTime(true)
	end,
	["goto"] = function(caller, first, second)
		sendToGate(caller, first, second)
	end,
}
-- Exposed for tools/tests/admin_commands only; nothing in the game calls them.
Admin.HANDLERS = HANDLERS
Admin.POWER_UP = POWER_UP
Admin.gift = gift

function Admin.run(caller: Player, command: string, first: string?, second: string?, third: string?)
	if not Session.isAdmin(caller) then
		return
	end
	command = string.lower(command)
	local handler = HANDLERS[command]
	if handler then
		handler(caller, first, second, third)
	end
end

-- The AdminCommand remote: the command and up to three arguments, as chat passes them
-- (`/give <who> mac permanent`); a non-string argument is nil. Calls Admin.run through the table
-- (tools/tests/remote_handlers replaces it).
function Admin.onCommand(
	player: Player,
	command: unknown,
	first: unknown,
	second: unknown,
	third: unknown
)
	if type(command) ~= "string" then
		return
	end
	Admin.run(
		player,
		command,
		RemoteGuard.optionalString(first),
		RemoteGuard.optionalString(second),
		RemoteGuard.optionalString(third)
	)
end

-- The MacCommand remote: the MAC's buttons. Anyone with the MAC may use them. SNIPER gives a
-- sniper only to a player whose backpack and character hold none, so spamming it makes no Tools.
function Admin.macCommand(caller: Player, action: unknown)
	if not MacAccess.has(caller) then
		return
	end
	if action == RemoteActions.MacCommand.SNIPER then
		if not Weapons.holds(caller, "sniper") then
			Weapons.give(caller, "sniper")
		end
	elseif action == RemoteActions.MacCommand.NUKE then
		task.spawn(nuke, caller)
	end
end

function Admin.start()
	Remotes.MacCommand.OnServerEvent:Connect(Admin.macCommand)
	Remotes.AdminCommand.OnServerEvent:Connect(Admin.onCommand)

	local commands = Instance.new("Folder")
	commands.Name = "MayhemCommands"
	commands.Parent = TextChatService
	for _, name in AdminCommands.CHAT do
		local command = Instance.new("TextChatCommand")
		command.Name = "Mayhem_" .. name
		command.PrimaryAlias = "/" .. name
		command.Parent = commands
		command.Triggered:Connect(function(source, text)
			local player = Players:GetPlayerByUserId(source.UserId)
			if not player then
				return
			end
			Admin.run(player, name, AdminCommands.chatArguments(text))
		end)
	end
end

return Admin
