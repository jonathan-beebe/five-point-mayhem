-- Checks src/server/systems/CollisionGroups.luau outside Roblox, against a stand-in PhysicsService.
-- Usage: lune run tools/tests/collision_groups.luau
--
--   - the collision matrix it leaves (every ordered pair of Default, each group and an
--     unregistered name) equals the golden matrix below, and equals what the calls it replaced
--     left (Session.registerCollisionGroups, then Vehicles.registerCollisionGroups, copied below
--     as the reference), on a fresh place and on one with some groups already registered
--   - it registers the groups in the old order and never sets a pair on an unregistered group
--     (PhysicsService errors on that; the stand-in does too)
--   - registering twice changes nothing

local Check = require("../lib/Check")
local Sandbox = require("../lib/Sandbox")

local check, equal = Check.check, Check.equal

local Names = Sandbox.load("src/shared/Names.luau")
local CollisionGroups = Sandbox.load("src/server/systems/CollisionGroups.luau")

local Groups = Names.CollisionGroups

-- PhysicsService's collision group API, recording what it is told. Groups collide unless set
-- otherwise; "Default" is always registered.
local function fakePhysics(preRegistered: { string }?)
	local physics = {
		order = {} :: { string },
		registered = { Default = true } :: { [string]: boolean },
		apart = {} :: { [string]: boolean },
	}
	local function key(a: string, b: string): string
		return if a < b then a .. "|" .. b else b .. "|" .. a
	end
	function physics:IsCollisionGroupRegistered(name: string): boolean
		return self.registered[name] == true
	end
	function physics:RegisterCollisionGroup(name: string)
		assert(not self.registered[name], "RegisterCollisionGroup: " .. name .. " already exists")
		self.registered[name] = true
		table.insert(self.order, name)
	end
	function physics:CollisionGroupSetCollidable(a: string, b: string, collidable: boolean)
		assert(self.registered[a], "CollisionGroupSetCollidable: " .. a .. " is not registered")
		assert(self.registered[b], "CollisionGroupSetCollidable: " .. b .. " is not registered")
		self.apart[key(a, b)] = not collidable
	end
	function physics:CollisionGroupsAreCollidable(a: string, b: string): boolean
		return not self.apart[key(a, b)]
	end
	for _, name in preRegistered or {} do
		physics:RegisterCollisionGroup(name)
	end
	physics.order = {}
	return physics
end

-- The calls CollisionGroups.register replaced, word for word but for `PhysicsService`, in
-- init.server.luau's order: Session's, then Vehicles' (whose Wreckage rules skip a player group
-- that Session had not registered yet).
local function reference(PhysicsService)
	do -- Session.registerCollisionGroups
		for _, group in
			{
				Groups.LobbyPlayers,
				Groups.DeployedPlayers,
				Groups.LockedOutPlayers,
				Groups.LobbyGate,
			}
		do
			if not PhysicsService:IsCollisionGroupRegistered(group) then
				PhysicsService:RegisterCollisionGroup(group)
			end
		end
		PhysicsService:CollisionGroupSetCollidable(Groups.LobbyGate, Groups.DeployedPlayers, false)
	end
	do -- Vehicles.registerCollisionGroups
		for _, group in { Groups.Vehicles, Groups.Walkers, Groups.Scenery, Groups.Wreckage } do
			if not PhysicsService:IsCollisionGroupRegistered(group) then
				PhysicsService:RegisterCollisionGroup(group)
			end
		end
		PhysicsService:CollisionGroupSetCollidable(Groups.Walkers, Groups.Vehicles, false)
		PhysicsService:CollisionGroupSetCollidable(Groups.Walkers, Groups.Scenery, false)
		for _, group in
			{
				Groups.Vehicles,
				Groups.Walkers,
				Groups.LobbyPlayers,
				Groups.DeployedPlayers,
				Groups.LockedOutPlayers,
			}
		do
			if PhysicsService:IsCollisionGroupRegistered(group) then
				PhysicsService:CollisionGroupSetCollidable(Groups.Wreckage, group, false)
			end
		end
	end
end

-- The pairs that pass through each other; every other pair collides.
local GOLDEN_APART = {
	"DeployedPlayers|LobbyGate",
	"DeployedPlayers|Wreckage",
	"LobbyPlayers|Wreckage",
	"LockedOutPlayers|Wreckage",
	"Scenery|Walkers",
	"Vehicles|Walkers",
	"Vehicles|Wreckage",
	"Walkers|Wreckage",
}

-- Every name the matrix covers: Default, each group, and one never registered.
local NAMES = { "Default", "Unregistered" }
for _, group in Groups do
	table.insert(NAMES, group)
end
table.sort(NAMES)

local function sameMatrix(got, want, label: string)
	for _, a in NAMES do
		check(
			got:IsCollisionGroupRegistered(a) == want:IsCollisionGroupRegistered(a),
			label .. ": " .. a .. " registered"
		)
		for _, b in NAMES do
			check(
				got:CollisionGroupsAreCollidable(a, b) == want:CollisionGroupsAreCollidable(a, b),
				string.format("%s: %s/%s collidable", label, a, b)
			)
		end
	end
end

for _, case in
	{
		{ name = "fresh place", pre = {} },
		{ name = "some groups already registered", pre = { Groups.Scenery, Groups.LobbyGate } },
	}
do
	Check.section(case.name)
	local old = fakePhysics(case.pre)
	reference(old)
	local new = fakePhysics(case.pre)
	CollisionGroups.register(new)
	sameMatrix(new, old, "new vs old")
	equal(table.concat(new.order, ","), table.concat(old.order, ","), "registration order")

	local apart = {}
	for pair, isApart in new.apart do
		if isApart then
			table.insert(apart, pair)
		end
	end
	table.sort(apart)
	equal(table.concat(apart, ","), table.concat(GOLDEN_APART, ","), "pass-through pairs")
	for _, group in Groups do
		check(new:IsCollisionGroupRegistered(group), group .. " registered")
		check(new:CollisionGroupsAreCollidable("Default", group), group .. " collides with Default")
		check(new:CollisionGroupsAreCollidable(group, group), group .. " collides with itself")
	end

	local again = fakePhysics(case.pre)
	CollisionGroups.register(again)
	CollisionGroups.register(again)
	sameMatrix(again, new, "registered twice")
end

Check.finish()
