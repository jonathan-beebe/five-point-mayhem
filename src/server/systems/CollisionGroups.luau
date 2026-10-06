-- Every PhysicsService collision group and which pairs pass through each other. init.server.luau
-- calls `register(PhysicsService)` once at boot, before the world is built; `physics` is any
-- object with PhysicsService's three methods, so `tools/tests/collision_groups.luau` checks the
-- matrix with a stand-in.
--
-- Pairs not listed collide, as do all groups with Default (buildings, roads, terrain):
--   - LobbyGate stops LobbyPlayers (and creatures, in Default) but lets DeployedPlayers out. Once a
--     deployed non-admin has left the lobby they are LockedOutPlayers: the gates stop them again,
--     so only admins walk back in (Session moves characters between the player groups).
--   - Every vehicle's solid parts are in Vehicles; a vehicle that steps over things
--     (spec.stepsOver) is in Walkers, which passes through Vehicles and Scenery (Landscape's
--     trees, rocks, crates, barrels).
--   - A felled tree is Wreckage: it falls through vehicles and players onto the ground.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Names = require(ReplicatedStorage.Shared.Names)

local Groups = Names.CollisionGroups

local CollisionGroups = {}

-- The PhysicsService methods `register` calls.
export type Physics = {
	IsCollisionGroupRegistered: (self: any, name: string) -> boolean,
	RegisterCollisionGroup: (self: any, name: string) -> (),
	CollisionGroupSetCollidable: (self: any, a: string, b: string, collidable: boolean) -> (),
}

-- Registration order: the player groups and LobbyGate, then the vehicle groups.
local ORDER = {
	Groups.LobbyPlayers,
	Groups.DeployedPlayers,
	Groups.LockedOutPlayers,
	Groups.LobbyGate,
	Groups.Vehicles,
	Groups.Walkers,
	Groups.Scenery,
	Groups.Wreckage,
}

-- The pairs that pass through each other. Every group here is in ORDER, so all are registered
-- before the first pair is set.
local PASS_THROUGH = {
	{ Groups.LobbyGate, Groups.DeployedPlayers },
	{ Groups.Walkers, Groups.Vehicles },
	{ Groups.Walkers, Groups.Scenery },
	{ Groups.Wreckage, Groups.Vehicles },
	{ Groups.Wreckage, Groups.Walkers },
	{ Groups.Wreckage, Groups.LobbyPlayers },
	{ Groups.Wreckage, Groups.DeployedPlayers },
	{ Groups.Wreckage, Groups.LockedOutPlayers },
}

function CollisionGroups.register(physics: Physics)
	for _, group in ORDER do
		if not physics:IsCollisionGroupRegistered(group) then
			physics:RegisterCollisionGroup(group)
		end
	end
	for _, pair in PASS_THROUGH do
		physics:CollisionGroupSetCollidable(pair[1], pair[2], false)
	end
end

return CollisionGroups
