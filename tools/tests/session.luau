-- Checks src/server/systems/Session.luau outside Roblox: Session runs with recording fakes behind
-- its requires (shared modules real) and fake services.
-- Usage: lune run tools/tests/session.luau
--
--   - Session.isAdmin keeps its rules: everyone in Studio; Config.ADMIN_USER_IDS; the owner of a
--     user-owned place; rank 255 in the owning group. A rank lookup that fails is rank 0.
--   - the group rank is the highest Rank in GroupService:GetRolesInGroupAsync's Roles for a member
--     (the Player lookups GetRankInGroup and GetRankInGroupAsync are deprecated and never called);
--     not a member or a malformed answer is rank 0
--   - a lookup that succeeds runs once per player: later calls read the cache, Session.forget (the
--     PlayerRemoving handler) drops it, and a player who left during the lookup is not cached
--   - a failed lookup is rank 0 and not cached: the next call looks up again; a later lookup that
--     makes the player admin sets an IsAdmin attribute of false to true
--   - concurrent first calls for one player share one lookup (a yielding fake): the second waits
--     for the first's answer
--   - Session.deploy (Deploy) accepts and refuses the same loadouts as its code before it used
--     Loadout.isAvailable: golden cases for admin-only weapons with and without the IsAdmin
--     attribute, duplicates, too many, unknown ids, wrong types, gaps, already deployed
--   - deploy follows Loadout.isAvailable: a fake rule that refuses a weapon refuses that loadout
--   - an accepted deploy sets Deployed and no "Loadout" attribute (nothing reads it)

local roblox = require("@lune/roblox")

local Check = require("../lib/Check")
local Sandbox = require("../lib/Sandbox")

local check, equal = Check.check, Check.equal
local Enum = roblox.Enum
local Vector3 = roblox.Vector3

Check.printLimit = 20

local Shared = Sandbox.game:GetService("ReplicatedStorage").Shared
local Config = Sandbox.require(Shared.Config)
local Names = Sandbox.require(Shared.Names)

local SESSION = "src/server/systems/Session.luau"

-- An instance path stand-in: `require(node)` sees the last name in the path.
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

-- Answers any field read or call with itself: the requires a test does not fake.
local stub = setmetatable({}, {
	__index = function(self)
		return self
	end,
	__call = function(self)
		return self
	end,
})

-- A signal whose handlers the test fires by hand.
local function signal(): any
	local handlers = {}
	return {
		handlers = handlers,
		Connect = function(_, handler)
			table.insert(handlers, handler)
		end,
		fire = function(...)
			for _, handler in handlers do
				handler(...)
			end
		end,
	}
end

local log: { string } = {}
local function record(line: string)
	table.insert(log, line)
end

-- Fake players by UserId: GroupService answers from them and counts their lookups.
local players: { [number]: any } = {}
local GroupService = {
	GetRolesInGroupAsync = function(_, userId, groupId)
		local player = players[userId]
		player.lookups += 1
		table.insert(player.groups, groupId)
		if player.onLookup then
			player.onLookup()
		end
		if player.hold then
			coroutine.yield()
		end
		local answer = player.answer
		if answer == false then
			error("HTTP 500 (Internal Server Error)")
		elseif type(answer) == "number" then
			return if answer > 0
				then { IsMember = true, Roles = { { Name = "rank", Rank = answer } } }
				else { IsMember = false, Roles = {} }
		end
		return answer
	end,
}

-- The place: Studio or live, owned by a user or a group. Session reads it at call time.
local place = { studio = false }
local fakeGame = {
	CreatorType = Enum.CreatorType.Group,
	CreatorId = 4000,
	GetService = function(_, service)
		if service == "GroupService" then
			return GroupService
		elseif service == "RunService" then
			return {
				IsStudio = function()
					return place.studio
				end,
			}
		elseif service == "Players" then
			return {
				PlayerAdded = signal(),
				PlayerRemoving = signal(),
				GetPlayers = function()
					return {}
				end,
			}
		elseif service == "Teams" then
			return {
				FindFirstChild = function(_, name)
					return { Name = name }
				end,
			}
		end
		return node(service)
	end,
}

local Characters = {
	parts = function(player)
		return player.character, player.humanoid, player.root
	end,
}
local Weapons = {
	give = function(_, id)
		record("Weapons.give " .. id)
		return true
	end,
}
local Remotes = {
	Deploy = { OnServerEvent = signal() },
	ChooseTeam = { OnServerEvent = signal() },
}
local Guard = { loop = function() end, run = function() end }

-- Session with these fakes behind its requires; `extra` replaces more of them by module name.
local function loadSession(extra: { [string]: any }?): any
	local fakes: { [string]: any } = {
		Characters = Characters,
		Weapons = Weapons,
		Remotes = Remotes,
		Guard = Guard,
	}
	for name, fake in extra or {} do
		fakes[name] = fake
	end
	return Sandbox.load(SESSION, {
		game = fakeGame,
		Enum = Enum,
		-- task.spawn resumes at once, as Roblox does.
		task = {
			spawn = function(thread, ...)
				assert(coroutine.resume(thread, ...))
			end,
		},
		script = node("script"),
		require = function(target)
			local name = target.__name
			if fakes[name] then
				return fakes[name]
			end
			local ok, shared = pcall(Sandbox.require, Shared[name])
			return if ok then shared else stub
		end,
	})
end

local Session = loadSession()

-- A player in the server. `answer` is what GroupService:GetRolesInGroupAsync answers for them:
-- a rank (a member holding that rank, or not a member at 0), `false` (it throws), or a table
-- passed through as is.
local PLAYERS = {}
local function newPlayer(userId: number, answer: any): any
	local player = { UserId = userId, Parent = PLAYERS, Name = "p" .. userId }
	player.lookups = 0
	player.groups = {}
	player.answer = answer
	player.attributes = {}
	function player.GetAttribute(self, key)
		return self.attributes[key]
	end
	function player.SetAttribute(self, key, value)
		self.attributes[key] = value
	end
	-- The deprecated Player lookups: Session must not call them.
	for _, name in { "GetRankInGroup", "GetRankInGroupAsync" } do
		player[name] = function(self)
			self.deprecated = name
			error(name .. " is deprecated")
		end
	end
	players[userId] = player
	return player
end

Check.section("Session.isAdmin: rules")
type Case = {
	name: string,
	studio: boolean,
	owner: "user" | "group",
	userId: number,
	answer: any,
	listed: boolean?,
	want: boolean,
	lookups: number,
}
local function makeCase(
	name: string,
	studio: boolean,
	owner: "user" | "group",
	userId: number,
	answer: any,
	want: boolean,
	lookups: number,
	listed: boolean?
): Case
	return {
		name = name,
		studio = studio,
		owner = owner,
		userId = userId,
		answer = answer,
		want = want,
		lookups = lookups,
		listed = listed,
	}
end
local function roles(...: number): any
	local list = {}
	for _, rank in { ... } do
		table.insert(list, { Name = "role " .. rank, Rank = rank })
	end
	return { IsMember = true, Roles = list }
end
local CASES: { Case } = {
	makeCase("studio", true, "group", 7, 0, true, 0),
	makeCase("listed admin", false, "group", 9001, 0, true, 0, true),
	makeCase("place owner", false, "user", 4000, 0, true, 0),
	makeCase("not the owner", false, "user", 7, 255, false, 0),
	makeCase("group rank 255", false, "group", 7, 255, true, 1),
	makeCase("group rank 254", false, "group", 7, 254, false, 1),
	makeCase("group member rank 1", false, "group", 7, 1, false, 1),
	makeCase("not a member", false, "group", 7, 0, false, 1),
	makeCase("lookup fails", false, "group", 7, false, false, 1),
	makeCase("255 among several roles", false, "group", 7, roles(1, 255, 50), true, 1),
	makeCase("several roles under 255", false, "group", 7, roles(1, 254), false, 1),
	makeCase(
		"255 but not a member",
		false,
		"group",
		7,
		{ IsMember = false, Roles = roles(255).Roles },
		false,
		1
	),
	makeCase("no answer", false, "group", 7, nil, false, 1),
	makeCase("no roles", false, "group", 7, { IsMember = true }, false, 1),
	makeCase(
		"rank not a number",
		false,
		"group",
		7,
		{ IsMember = true, Roles = { { Rank = "255" } } },
		false,
		1
	),
}
for _, case in CASES do
	place.studio = case.studio
	fakeGame.CreatorType = if case.owner == "user"
		then Enum.CreatorType.User
		else Enum.CreatorType.Group
	if case.listed then
		table.insert(Config.ADMIN_USER_IDS, case.userId)
	end
	local player = newPlayer(case.userId, case.answer)
	local ok, got = pcall(Session.isAdmin, player)
	equal(ok and got, case.want, case.name)
	equal(player.lookups, case.lookups, case.name .. ": GetRolesInGroupAsync calls")
	equal(player.deprecated, nil, case.name .. ": deprecated lookup")
	for _, groupId in player.groups do
		equal(groupId, 4000, case.name .. ": looks up the owning group")
	end
	if case.listed then
		table.remove(Config.ADMIN_USER_IDS, table.find(Config.ADMIN_USER_IDS, case.userId))
	end
end
place.studio = false
fakeGame.CreatorType = Enum.CreatorType.Group

Check.section("Session.isAdmin: rank cache")
do
	local admin = newPlayer(11, 255)
	for _ = 1, 3 do
		equal(Session.isAdmin(admin), true, "rank 255 stays admin")
	end
	equal(admin.lookups, 1, "three calls look the rank up once")

	local failed = newPlayer(12, false)
	equal(Session.isAdmin(failed), false, "a failed lookup is rank 0")
	equal(Session.isAdmin(failed), false, "a failed lookup again is rank 0")
	equal(failed.lookups, 2, "a failed lookup is not cached: the next call looks up again")
	failed.answer = 255
	equal(Session.isAdmin(failed), true, "a later lookup at 255 is admin")
	Session.isAdmin(failed)
	equal(failed.lookups, 3, "the later success is cached")

	-- A failure at join left IsAdmin false; the next isAdmin call that finds rank 255 fixes it.
	local healed = newPlayer(15, false)
	healed.attributes[Names.Attributes.IsAdmin] = Session.isAdmin(healed)
	equal(healed.attributes[Names.Attributes.IsAdmin], false, "joined as non-admin")
	healed.answer = 255
	Session.isAdmin(healed)
	equal(healed.attributes[Names.Attributes.IsAdmin], true, "IsAdmin set true after the success")
	local member = newPlayer(16, 1)
	member.attributes[Names.Attributes.IsAdmin] = false
	Session.isAdmin(member)
	equal(member.attributes[Names.Attributes.IsAdmin], false, "a non-admin's IsAdmin stays false")

	-- Two first calls at once (Session's and MacAccess's PlayerAdded handlers): one lookup.
	local joining = newPlayer(17, 255)
	joining.hold = true
	local first = coroutine.create(Session.isAdmin)
	local secondAnswer
	local second = coroutine.create(function(player)
		secondAnswer = Session.isAdmin(player)
	end)
	local firstOk, firstResult = coroutine.resume(first, joining)
	check(firstOk and coroutine.status(first) == "suspended", "the first call waits on the lookup")
	local secondOk, problem = coroutine.resume(second, joining)
	check(secondOk, "the second call runs: " .. tostring(problem))
	equal(joining.lookups, 1, "the second call waits for the first lookup")
	joining.hold = false
	firstOk, firstResult = coroutine.resume(first)
	equal(firstOk and firstResult, true, "the first call answers admin")
	equal(coroutine.status(second), "dead", "the second call has finished")
	equal(secondAnswer, true, "the second call answers admin from the first lookup")
	equal(joining.lookups, 1, "two concurrent calls, one lookup")

	local forget = Session.forget
	check(type(forget) == "function", "Session.forget exists")
	if type(forget) == "function" then
		forget(admin)
		Session.isAdmin(admin)
		equal(admin.lookups, 2, "after Session.forget the rank is looked up again")
	end

	-- PlayerRemoving is wired to Session.forget by start().
	local Players = fakeGame:GetService("Players")
	local services = fakeGame.GetService
	fakeGame.GetService = function(self, service)
		return if service == "Players" then Players else services(self, service)
	end
	local started = loadSession()
	fakeGame.GetService = services
	started.start()
	local wired = newPlayer(13, 255)
	started.isAdmin(wired)
	Players.PlayerRemoving.fire(wired)
	started.isAdmin(wired)
	equal(wired.lookups, 2, "PlayerRemoving drops the cached rank")

	-- A player who leaves while the lookup yields is not cached (no entry outlives them).
	local leaving = newPlayer(14, 255)
	leaving.onLookup = function()
		leaving.Parent = nil
	end
	Session.isAdmin(leaving)
	Session.isAdmin(leaving)
	equal(leaving.lookups, 2, "a player who left during the lookup is not cached")
end

-- deploy ----------------------------------------------------------------------------------------

-- A player in the lobby with a living character and a backpack. `isAdmin` is the IsAdmin
-- attribute's value.
local function lobbyPlayer(isAdmin: any, deployed: boolean?): any
	local attributes =
		{ [Names.Attributes.IsAdmin] = isAdmin, [Names.Attributes.Deployed] = deployed }
	local backpack = {
		ClearAllChildren = function()
			record("backpack:ClearAllChildren")
		end,
	}
	return {
		Parent = PLAYERS,
		attributes = attributes,
		character = {
			GetDescendants = function()
				return {}
			end,
		},
		humanoid = { Health = 100 },
		root = { Position = Vector3.new(3, 5, -4) },
		GetAttribute = function(_, key)
			return attributes[key]
		end,
		SetAttribute = function(_, key, value)
			record(("SetAttribute %s %s"):format(key, tostring(value)))
			attributes[key] = value
		end,
		FindFirstChildOfClass = function(_, className)
			return if className == "Backpack" then backpack else nil
		end,
	}
end

-- Golden: whether deploy accepted each loadout before it used Loadout.isAvailable (main at
-- f35d32f). `sniper` is the one admin-only weapon.
check(Sandbox.require(Shared.WeaponCatalog).get("sniper").adminOnly == true, "sniper is admin-only")
local DEPLOYS: { { name: string, ids: any, isAdmin: any, deployed: boolean?, want: boolean } } = {
	{ name = "empty", ids = {}, isAdmin = false, want = true },
	{ name = "one", ids = { "knight_sword" }, isAdmin = false, want = true },
	{
		name = "three",
		ids = { "knight_sword", "katana", "battle_axe" },
		isAdmin = false,
		want = true,
	},
	{
		name = "four",
		ids = { "knight_sword", "katana", "battle_axe", "spear" },
		isAdmin = true,
		want = false,
	},
	{ name = "duplicate", ids = { "katana", "katana" }, isAdmin = true, want = false },
	{ name = "unknown id", ids = { "katana", "nope" }, isAdmin = true, want = false },
	{ name = "number id", ids = { "katana", 5 }, isAdmin = true, want = false },
	{ name = "gap", ids = { [1] = "katana", [3] = "spear" }, isAdmin = true, want = false },
	{ name = "string key", ids = { first = "katana" }, isAdmin = true, want = false },
	{ name = "not a table", ids = "katana", isAdmin = true, want = false },
	{ name = "admin-only, non-admin", ids = { "sniper" }, isAdmin = false, want = false },
	{ name = "admin-only, no attribute", ids = { "sniper" }, isAdmin = nil, want = false },
	{ name = "admin-only, attribute 'true'", ids = { "sniper" }, isAdmin = "true", want = false },
	{
		name = "admin-only last, non-admin",
		ids = { "katana", "sniper" },
		isAdmin = false,
		want = false,
	},
	{ name = "admin-only, admin", ids = { "sniper" }, isAdmin = true, want = true },
	{
		name = "admin-only last, admin",
		ids = { "katana", "spear", "sniper" },
		isAdmin = true,
		want = true,
	},
	{
		name = "already deployed",
		ids = { "katana" },
		isAdmin = true,
		deployed = true,
		want = false,
	},
}

-- The effects of an accepted deploy, in order.
local function accepted(ids: { string }): { string }
	local want = { "backpack:ClearAllChildren" }
	for _, id in ids do
		table.insert(want, "Weapons.give " .. id)
	end
	table.insert(want, "SetAttribute " .. Names.Attributes.Deployed .. " true")
	return want
end

Check.section("Session.deploy: golden loadouts")
check(type(Session.deploy) == "function", "Session.deploy exists")
for _, case in DEPLOYS do
	log = {}
	local ok, problem = pcall(Session.deploy, lobbyPlayer(case.isAdmin, case.deployed), case.ids)
	check(ok, case.name .. " runs: " .. tostring(problem))
	local want = if case.want then accepted(case.ids) else {}
	equal(table.concat(log, "; "), table.concat(want, "; "), case.name)
end

Check.section("Session.deploy: follows Loadout.isAvailable")
do
	local Loadout = Sandbox.require(Shared.Loadout)
	-- A rule that lists everything but the katana, the sniper included.
	local ruled = loadSession({
		Loadout = setmetatable({
			isAvailable = function(weapon, _isAdmin)
				return weapon.id ~= "katana"
			end,
		}, { __index = Loadout }),
	})
	for _, case in
		{
			{ ids = { "katana" }, want = false },
			{ ids = { "spear", "katana" }, want = false },
			{ ids = { "sniper" }, want = true },
			{ ids = { "spear" }, want = true },
		}
	do
		log = {}
		pcall(ruled.deploy, lobbyPlayer(false), case.ids)
		local want = if case.want then accepted(case.ids) else {}
		equal(table.concat(log, "; "), table.concat(want, "; "), table.concat(case.ids, ","))
	end
end

Check.section("Session.deploy: attributes")
do
	log = {}
	local player = lobbyPlayer(false)
	pcall(Session.deploy, player, { "katana", "spear" })
	equal(player.attributes[Names.Attributes.Deployed], true, "Deployed is set")
	equal(player.attributes.Loadout, nil, "no Loadout attribute")
end

Check.finish()
