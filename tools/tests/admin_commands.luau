-- Checks the admin command registry (src/shared/AdminCommands) against the server's handlers and
-- the lists the game had, outside Roblox.
-- Usage: lune run tools/tests/admin_commands.luau
--
--   - every command id has a handler in Admin.HANDLERS and every handler an id; ids are lower case
--     and unique; Admin.POWER_UP's keys plus `arsenal` and `car` are the power-ups; every panel
--     gift is a power-up or a weapon
--   - Admin's `gift` takes the same branch, with the same effects in the same order, as its code at
--     3c65531 for every power-up, weapon and vehicle id, the prefixes they share and unknown items,
--     with a living character and without one (recording fakes for the character, Weapons,
--     Vehicles, Debris and Instance)
--   - the panel's power buttons, the chat command list, the gifts, the power-ups and the tuning
--     equal the literals Admin.luau and AdminPanel.luau had at 3c65531
--   - resolveTargets, giftLabel, chatArguments and meteorSeconds return what the inline code they
--     replaced in Admin.luau returned, copied below word for word as the reference
--   - `/horde` with no target sends one horde per region, half a region step past each: the same
--     points as at f35d32f for five regions, and 30 degrees past each with a sixth
--
-- Admin's requires build Instances, so HANDLERS and POWER_UP come from Admin run alone
-- (Sandbox.loadIsolated), and `gift` and `horde` from Admin run with fakes for its requires and
-- services.

local luau = require("@lune/luau")
local roblox = require("@lune/roblox")

local Check = require("../lib/Check")
local Sandbox = require("../lib/Sandbox")

local check, equal = Check.check, Check.equal
local Color3, Vector3 = roblox.Color3, roblox.Vector3
local CFrame = Sandbox.CFrame
local rgb = Color3.fromRGB

local Shared = Sandbox.game:GetService("ReplicatedStorage").Shared
local AdminCommands = Sandbox.require(Shared.AdminCommands)
local VehicleCatalog = Sandbox.require(Shared.VehicleCatalog)
local WeaponCatalog = Sandbox.require(Shared.WeaponCatalog)
local ADMIN = "src/server/systems/Admin"
local Admin = Sandbox.loadIsolated(ADMIN)

-- Same values: tables compare key by key, NaN equals NaN.
local function same(a: any, b: any): boolean
	if type(a) == "table" and type(b) == "table" then
		for key, value in a do
			if not same(value, b[key]) then
				return false
			end
		end
		for key in b do
			if a[key] == nil then
				return false
			end
		end
		return true
	elseif a ~= a and b ~= b then
		return true
	end
	return a == b
end

local function show(value: any): string
	if type(value) == "string" then
		return string.format("%q", value)
	end
	return tostring(value)
end

Check.section("handlers")
local ids: { [string]: boolean } = {}
for _, command in AdminCommands.COMMANDS do
	check(ids[command.id] == nil, "AdminCommands: duplicate id " .. command.id)
	ids[command.id] = true
	check(command.id == string.lower(command.id), command.id .. ": Admin.run lowers the command")
	check(type(command.chat) == "boolean", command.id .. ": chat must be a boolean")
	check(
		type(Admin.HANDLERS[command.id]) == "function",
		"Admin.HANDLERS has no handler for " .. command.id
	)
end
for id in Admin.HANDLERS do
	check(ids[id] == true, "Admin.HANDLERS." .. tostring(id) .. " is not an AdminCommands id")
end
local slots: { [number]: string } = {}
for _, command in AdminCommands.COMMANDS do
	local panel = command.panel
	if panel then
		check(
			slots[panel.slot] == nil,
			command.id .. ": slot shared with " .. tostring(slots[panel.slot])
		)
		slots[panel.slot] = command.id
	end
end
for slot = 1, #AdminCommands.POWERS do
	check(slots[slot] ~= nil, "panel slots run 1.." .. #AdminCommands.POWERS .. ": no " .. slot)
end
-- Admin's `gift` handles `arsenal` and `car` in branches of their own, the rest in POWER_UP.
local handled: { [string]: boolean } = { arsenal = true, car = true }
for id in Admin.POWER_UP do
	check(type(Admin.POWER_UP[id]) == "function", "Admin.POWER_UP." .. id .. " is a function")
	handled[id] = true
end
local powerUps: { [string]: boolean } = {}
for _, id in AdminCommands.POWER_UPS do
	powerUps[id] = true
	check(handled[id] == true, "Admin's gift does not handle power-up " .. id)
end
for id in handled do
	check(powerUps[id] == true, "Admin's gift handles " .. id .. ", not in AdminCommands.POWER_UPS")
end
for _, entry in AdminCommands.GIFTS do
	check(
		table.find(AdminCommands.POWER_UPS, entry.id) ~= nil
			or (WeaponCatalog.find(entry.id) and WeaponCatalog.find(entry.id).id == entry.id),
		"GIFTS." .. entry.id .. " is neither a power-up nor a weapon id"
	)
end

Check.section("lists")
-- The literals at 3c65531: AdminPanel POWERS, Admin.start's chat list, AdminPanel GIFTS and
-- Admin.GIFTS.
local POWERS = {
	{
		command = "mayhem",
		label = "☢ MAYHEM",
		color = rgb(200, 20, 30),
		hint = "Destroy everyone outside the lobby",
	},
	{
		command = "meteors",
		label = "☄ METEORS",
		color = rgb(220, 110, 30),
		hint = "30 second meteor storm",
	},
	{
		command = "gravity",
		label = "🌙 GRAVITY",
		color = rgb(70, 90, 180),
		hint = "Toggle moon gravity",
	},
	{
		command = "freeze",
		label = "❄ FREEZE",
		color = rgb(60, 160, 210),
		hint = "Freeze the target",
		targeted = true,
	},
	{
		command = "day",
		label = "☀ DAY",
		color = rgb(220, 170, 40),
		hint = "Jump to morning",
	},
	{
		command = "night",
		label = "🌑 NIGHT",
		color = rgb(50, 40, 90),
		hint = "Jump to nightfall",
	},
	{
		command = "horde",
		label = "👹 HORDE",
		color = rgb(60, 140, 50),
		hint = "Summon monsters",
		targeted = true,
	},
}
local CHAT = { "mayhem", "give", "meteors", "gravity", "freeze", "horde", "day", "night" }
local GIFTS = {
	{ id = "arsenal", label = "🧰 EVERY WEAPON" },
	{ id = "sniper", label = "🎯 Sniper Rifle" },
	{ id = "heal", label = "❤ Full heal" },
	{ id = "shield", label = "🛡 Shield (30s)" },
	{ id = "speed", label = "👟 Super speed" },
	{ id = "jump", label = "🦘 Mega jump" },
	{ id = "giant", label = "🗿 Giant" },
	{ id = "car", label = "🚙 Random vehicle" },
}
local POWER_UPS = { "speed", "jump", "giant", "heal", "shield", "car", "arsenal" }
equal(#AdminCommands.POWERS, #POWERS, "panel power count")
for index, want in POWERS do
	local got = AdminCommands.POWERS[index] or {}
	for _, field in { "command", "label", "color", "hint", "targeted" } do
		equal(got[field], want[field], ("POWERS[%d].%s"):format(index, field))
	end
	for field in got do
		check(want[field] ~= nil, ("POWERS[%d] has an extra field %s"):format(index, field))
	end
end
check(same(AdminCommands.CHAT, CHAT), "CHAT: " .. table.concat(AdminCommands.CHAT, ", "))
check(same(AdminCommands.GIFTS, GIFTS), "GIFTS in menu order")
check(same(AdminCommands.POWER_UPS, POWER_UPS), "POWER_UPS in order")

Check.section("tuning")
local TUNING = {
	SPEED = 40,
	JUMP_POWER = 120,
	GIANT_SCALE = 2.5,
	SHIELD_SECONDS = 30,
	FREEZE_SECONDS = 10,
	HORDE_AROUND_PLAYER = 12,
	HORDE_PER_REGION = 6,
	METEOR_RADIUS = 16,
	METEOR_DAMAGE = 45,
	METEOR_SECONDS = 30,
	METEOR_MIN_SECONDS = 5,
	METEOR_MAX_SECONDS = 120,
}
check(same(AdminCommands.TUNING, TUNING), "TUNING")
for name, want in TUNING do
	equal(AdminCommands.TUNING[name], want, "TUNING." .. name)
end

-- The inline code the helpers replaced, from Admin.luau at 3c65531, word for word inside
-- functions that take its free variables as arguments.
local Reference = luau.load(
	[[
local Reference = {}

-- `players` stands in for Players:GetPlayers().
function Reference.resolveTargets(players, caller, who)
	local Players = {
		GetPlayers = function()
			return table.clone(players)
		end,
	}
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
-- give: `query` is string.lower(item).
function Reference.giftLabel(query)
	local Admin = { GIFTS = { "speed", "jump", "giant", "heal", "shield", "car", "arsenal" } }
	local weapon = WeaponCatalog.find(query)
	local vehicle = VehicleCatalog.get(query)
	local label = if table.find(Admin.GIFTS, query)
		then string.upper(query)
		elseif vehicle then vehicle.name
		elseif weapon then weapon.name
		else nil
	return label
end
-- Admin.start's TextChatCommand handler: the arguments it passed to Admin.run.
function Reference.chatArguments(text)
	local words = string.split(text, " ")
	return words[2], words[3], words[4]
end
-- Admin.run's meteors branch.
function Reference.meteorSeconds(first)
	return math.clamp(tonumber(first) or 30, 5, 120)
end

return Reference
]],
	{
		debugName = "Admin reference",
		environment = { WeaponCatalog = WeaponCatalog, VehicleCatalog = VehicleCatalog },
	}
)()

Check.section("AdminCommands.resolveTargets")
local alice = { Name = "Alice99", DisplayName = "Ace" }
local bob = { Name = "bob_builder", DisplayName = "Bobby" }
local acorn = { Name = "Acorn", DisplayName = "Squirrel" }
local rosters = { {}, { alice }, { alice, bob, acorn }, { acorn, bob, alice } }
local queries = {
	"all",
	"ALL",
	"everyone",
	"Everyone",
	"me",
	"ME",
	"a",
	"A",
	"ac",
	"ace",
	"acorn",
	"alice99",
	"alice999",
	"bob",
	"BOBBY",
	"squ",
	"zed",
	"",
	" ",
	"%a",
	"a.",
	"[",
}
for rosterIndex, roster in rosters do
	for _, caller in { alice, bob } do
		local whos: { any } = table.clone(queries)
		table.insert(whos, false) -- nil
		for _, who in whos do
			local query = if who == false then nil else who
			local got = AdminCommands.resolveTargets(roster, caller, query, function(player)
				return player.Name, player.DisplayName
			end)
			local want = Reference.resolveTargets(roster, caller, query)
			local ok = #got == #want
			for index in want do
				ok = ok and rawequal(got[index], want[index])
			end
			check(ok, ("resolveTargets roster %d, %s"):format(rosterIndex, show(query)))
		end
	end
end

Check.section("AdminCommands.giftLabel")
local items = { "mac", "", "unknown", "speed", "giant", "car", "arsenal", "rock", "lolli", "s" }
for _, id in AdminCommands.POWER_UPS do
	table.insert(items, id)
end
for _, weapon in WeaponCatalog.ALL do
	table.insert(items, weapon.id)
	table.insert(items, string.lower(weapon.name))
	table.insert(items, string.sub(weapon.id, 1, 3))
end
for _, vehicle in VehicleCatalog.ALL do
	table.insert(items, vehicle.id)
end
for _, query in items do
	equal(
		AdminCommands.giftLabel(query, VehicleCatalog.get(query), WeaponCatalog.find(query)),
		Reference.giftLabel(query),
		"giftLabel " .. show(query)
	)
end

Check.section("AdminCommands.chatArguments")
local texts = {
	"/give me rocket",
	"/give all mac permanent",
	"/give all mac permanent extra words",
	"/give",
	"/give ",
	"",
	" ",
	"/give  me  rocket",
	" /give me",
	"/meteors 60",
	"/horde\tsam",
}
for _, text in texts do
	check(
		same({ AdminCommands.chatArguments(text) }, { Reference.chatArguments(text) }),
		"chatArguments " .. show(text)
	)
	equal(select("#", AdminCommands.chatArguments(text)), 3, "chatArguments returns 3 values")
end

Check.section("AdminCommands.meteorSeconds")
local firsts = {
	"4",
	"4.99",
	"5",
	"30",
	"60",
	"120",
	"120.5",
	"121",
	"-1",
	"0",
	"",
	"abc",
	"nan",
	"inf",
	"-inf",
	"0x10",
	"1e3",
	" 7 ",
	"7s",
}
for _, first in firsts do
	local okNew, got = pcall(AdminCommands.meteorSeconds, first)
	local okOld, want = pcall(Reference.meteorSeconds, first)
	check(okNew == okOld and same(got, want), "meteorSeconds " .. show(first))
end
equal(AdminCommands.meteorSeconds(nil), Reference.meteorSeconds(nil), "meteorSeconds nil")
equal(AdminCommands.meteorSeconds(nil), 30, "meteorSeconds default")

Check.section("Admin gift")
-- Every effect `gift` has, recorded in order.
local log: { { any } } = {}
local function record(...)
	table.insert(log, table.pack(...))
end
-- An Instance stand-in: property writes are recorded, reads see `fields`.
local function fake(name: string, fields: { [string]: any }): any
	return setmetatable({}, {
		__index = fields,
		__newindex = function(_, key, value)
			record("set", name, key, value)
			fields[key] = value
		end,
	})
end
local Characters = {
	living = function(player)
		return player.character, player.humanoid, player.root
	end,
}
local Weapons = {
	give = function(_, id)
		record("Weapons.give", id)
		return true
	end,
}
local Vehicles = {
	spawnNear = function(position, look, id)
		record("Vehicles.spawnNear", position, look, id)
	end,
}
local Debris = {
	AddItem = function(_, instance, seconds)
		record("Debris:AddItem", instance.ClassName, seconds)
	end,
}
local FakeInstance = {
	new = function(className)
		record("Instance.new", className)
		return fake(className, { ClassName = className })
	end,
}
local Names = Sandbox.require(Shared.Names)

-- Admin with these fakes behind its requires and services; the shared data modules are real.
local REAL = {
	AdminCommands = true,
	Config = true,
	Names = true,
	RemoteActions = true,
	VehicleCatalog = true,
	WeaponCatalog = true,
}
local Creatures = {
	horde = function(position, count)
		record("Creatures.horde", position, count)
	end,
}
local FAKES =
	{ Characters = Characters, Weapons = Weapons, Vehicles = Vehicles, Creatures = Creatures }
local stub = setmetatable({}, {
	__index = function(self)
		return self
	end,
	__call = function(self)
		return self
	end,
})
local function node(name: string): any
	return setmetatable({}, {
		__index = function(_, key)
			if key == "__name" then
				return name
			end
			return node(key)
		end,
	})
end
local loaded = Sandbox.load(ADMIN .. ".luau", {
	game = {
		GetService = function(_, service)
			return if service == "Debris" then Debris else node(service)
		end,
	},
	script = node("script"),
	Instance = FakeInstance,
	require = function(target)
		local name = target.__name
		if REAL[name] then
			return Sandbox.require(Shared[name])
		end
		return FAKES[name] or stub
	end,
})

-- `gift` at 3c65531, word for word.
local reference = luau.load(
	[[
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
	elseif item == "speed" then
		humanoid:SetAttribute(Names.Attributes.BaseWalkSpeed, 40)
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
return gift
]],
	{
		debugName = "Admin gift reference",
		environment = {
			Characters = Characters,
			WeaponCatalog = WeaponCatalog,
			VehicleCatalog = VehicleCatalog,
			Weapons = Weapons,
			Vehicles = Vehicles,
			Names = Names,
			Debris = Debris,
			Instance = FakeInstance,
		},
	}
)()

-- A player with a fresh character (living) or none, and a backpack or none. The humanoid has
-- three of the four body scales.
local function player(living: boolean, backpack: boolean): any
	local character = if living then fake("character", {}) else nil
	local scales = {}
	for _, scale in { "BodyHeightScale", "BodyWidthScale", "HeadScale" } do
		scales[scale] = fake(scale, {})
	end
	local humanoid = fake("humanoid", {
		MaxHealth = 130,
		SetAttribute = function(_, key, value)
			record("humanoid:SetAttribute", key, value)
		end,
		FindFirstChild = function(_, name)
			return scales[name]
		end,
	})
	local root = {
		Position = Vector3.new(10, 3, -20),
		CFrame = CFrame.lookAt(Vector3.new(10, 3, -20), Vector3.new(14, 3, -17)),
	}
	return {
		character = character,
		humanoid = if living then humanoid else nil,
		root = if living then root else nil,
		FindFirstChildOfClass = function(_, className)
			return if backpack and className == "Backpack" then {} else nil
		end,
	}
end

local giftItems = { "", "unknown", "mac", "giant_lollipop", "s", "sp", "gi", "he", "sh", "ca", "j" }
for _, id in AdminCommands.POWER_UPS do
	table.insert(giftItems, id)
end
for _, weapon in WeaponCatalog.ALL do
	table.insert(giftItems, weapon.id)
	table.insert(giftItems, string.sub(weapon.id, 1, 2))
end
for _, vehicle in VehicleCatalog.ALL do
	table.insert(giftItems, vehicle.id)
	table.insert(giftItems, string.sub(vehicle.id, 1, 2))
end
-- The order matters: some power-up is also the start of a weapon's id or name.
local shadowed = {}
for _, id in AdminCommands.POWER_UPS do
	if WeaponCatalog.find(id) or VehicleCatalog.get(id) then
		table.insert(shadowed, id)
	end
end
check(#shadowed > 0, "some power-up also matches a weapon or vehicle")
print("power-ups that also match a weapon or vehicle: " .. table.concat(shadowed, ", "))
for _, item in giftItems do
	for _, living in { true, false } do
		for _, backpack in { true, false } do
			log = {}
			local want = reference(player(living, backpack), item)
			local wantLog = log
			log = {}
			local got = loaded.gift(player(living, backpack), item)
			check(
				got == want and same(log, wantLog),
				("gift %s, living %s, backpack %s"):format(
					show(item),
					tostring(living),
					tostring(backpack)
				)
			)
		end
	end
end

Check.section("Admin horde: one horde between each pair of regions")
-- At main (f35d32f): `Config.pointAt(Config.regionAngle(index) + math.rad(36), 300)`, the angle
-- written out (regionAngle was `math.rad(-90 + (index - 1) * 72)`). Compiled with luau.load, as
-- Sandbox.load compiles Admin.
local hordeAt = luau.load(
	[[
local pointAt, step = ...
return function(index: number): Vector3
	return pointAt(math.rad(-90 + (index - 1) * step) + math.rad(step / 2), 300)
end
]],
	{ debugName = "horde reference" }
)
local Config = Sandbox.require(Shared.Config)
for _, regions in { 5, 6 } do
	local added = regions - #Config.REGIONS
	for index = 1, added do
		table.insert(Config.REGIONS, { id = "extra" .. index, name = "Extra", country = "None" })
	end
	log = {}
	loaded.HANDLERS.horde({ Name = "caller" }, nil)
	local hordes = {}
	for _, entry in log do
		if entry[1] == "Creatures.horde" then
			table.insert(hordes, entry)
		end
	end
	equal(#hordes, regions, regions .. " regions: hordes")
	local hordeReference = hordeAt(Config.pointAt, 360 / regions)
	for index, entry in hordes do
		local want = hordeReference(index)
		check(
			if regions == 5 then entry[2] == want else (entry[2] - want).Magnitude < 1e-9,
			("%d regions, horde %d: got %s, want %s"):format(
				regions,
				index,
				tostring(entry[2]),
				tostring(want)
			)
		)
		equal(entry[3], AdminCommands.TUNING.HORDE_PER_REGION, "horde size")
	end
	for _ = 1, added do
		table.remove(Config.REGIONS)
	end
end

Check.finish()
