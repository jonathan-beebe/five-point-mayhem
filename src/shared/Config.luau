-- World layout, teams, and tuning shared by server and client.

local Config = {}

-- Add Roblox UserIds here to grant god powers in published games.
-- The place owner is always an admin, and everyone is an admin in Studio test sessions.
Config.ADMIN_USER_IDS = {} :: { number }

Config.LOADOUT_SIZE = 3

-- Lobby: a glass-domed safe room at the world origin.
Config.LOBBY_RADIUS = 56
Config.LOBBY_WALL_HEIGHT = 26
Config.LOBBY_CEILING = 90

-- Board layout, in studs from the origin.
Config.RING_RADIUS = 480 -- building centers
Config.INNER_ROAD_RADIUS = 260
Config.OUTER_ROAD_RADIUS = 720
Config.WORLD_RADIUS = 1000
Config.SPOKE_END_RADIUS = 420

Config.NORMAL_GRAVITY = 196.2
Config.MOON_GRAVITY = 38

Config.FFA_TEAM = "Lone Wolves"
Config.TEAMS = {
	{
		name = "Lone Wolves",
		color = BrickColor.new("Medium stone grey"),
		blurb = "Everyone is a target",
	},
	{ name = "Red Dragons", color = BrickColor.new("Really red"), blurb = "Team up in red" },
	{ name = "Blue Sharks", color = BrickColor.new("Really blue"), blurb = "Team up in blue" },
	{ name = "Green Vipers", color = BrickColor.new("Lime green"), blurb = "Team up in green" },
	{ name = "Gold Lions", color = BrickColor.new("New Yeller"), blurb = "Team up in gold" },
}

-- The five landmarks, clockwise from north. Index order drives placement around the ring.
Config.REGIONS = {
	{ id = "castle", name = "Stonehold Castle", country = "England" },
	{ id = "pagoda", name = "Sakura Hall", country = "Japan" },
	{ id = "tower", name = "Mayhem Tower", country = "USA" },
	{ id = "pyramid", name = "Jaguar Pyramid", country = "Mexico" },
	{ id = "palace", name = "Frost Palace", country = "Russia" },
}

function Config.regionAngle(index: number): number
	return math.rad(-90 + (index - 1) * 72)
end

function Config.pointAt(angle: number, radius: number, y: number?): Vector3
	return Vector3.new(math.cos(angle) * radius, y or 0, math.sin(angle) * radius)
end

function Config.regionCenter(index: number): Vector3
	return Config.pointAt(Config.regionAngle(index), Config.RING_RADIUS)
end

-- Index and flat distance of the landmark closest to a position.
function Config.nearestRegion(position: Vector3): (number, number)
	local best, bestDistance = 1, math.huge
	for index = 1, #Config.REGIONS do
		local center = Config.regionCenter(index)
		local distance = Vector2.new(position.X - center.X, position.Z - center.Z).Magnitude
		if distance < bestDistance then
			best, bestDistance = index, distance
		end
	end
	return best, bestDistance
end

-- The lobby is a safe zone: nobody inside it can deal or take damage.
function Config.isInLobby(position: Vector3): boolean
	return position.Y < Config.LOBBY_CEILING
		and Vector2.new(position.X, position.Z).Magnitude < Config.LOBBY_RADIUS + 1
end

return Config
