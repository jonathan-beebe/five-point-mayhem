--!strict
-- Where vehicles park (server Vehicles): walkers in a guard ring round the lobby, the rest at
-- random clear spots in the motor pools beside the spoke roads, dealt round-robin; when a parked
-- vehicle goes back home; and where a spawned one appears. Pure: Config, VehicleSizing and Roblox
-- datatypes; randomness comes from the Random passed in. `tools/tests/vehicle_logic.luau` pins
-- each function bit for bit (and randomSpot's calls on its Random) against the inline code it
-- replaced.

local Config = require(script.Parent.Config)
local VehicleSizing = require(script.Parent.VehicleSizing)

local VehicleLayout = {}

local SPOKE_HALF_WIDTH = 11 -- studs from a spoke road's center line to the motor pool's edge
local CLEARANCE = 3 -- free space kept around each parked vehicle
local CLEAR_HEIGHT = 16 -- taller than every car; walkers clear their own height
local WALKER_HEADROOM = 2 -- studs a walker taller than CLEAR_HEIGHT clears over its solid height
local LOBBY_MARGIN = 10 -- no vehicle parks within this of the lobby wall
local CLEAR_FLOOR = 0.1 -- studs over the ground the clear box starts
VehicleLayout.ATTEMPTS = 400 -- random spots tried per vehicle before it parks on a blocked one
-- Returning vehicles home: every RESPAWN_INTERVAL seconds, a parked vehicle that is gone is
-- rebuilt, and an unoccupied one is too when it fell under FALL_Y or has sat more than HOME_RADIUS
-- from home and unused for IDLE_TIME seconds.
VehicleLayout.RESPAWN_INTERVAL = 10
local HOME_RADIUS = 30
local IDLE_TIME = 60
local FALL_Y = -50
local SPAWN_FACING_MIN = 0.01 -- a shorter horizontal facing spawns facing +Z
local SPAWN_LIFT = 1 -- studs a spawned vehicle starts above the given position

-- Whether every corner of a W x L footprint at `ground` (a ground-level CFrame) lies outside the
-- lobby plus LOBBY_MARGIN.
function VehicleLayout.clearsLobby(ground: CFrame, W: number, L: number): boolean
	for _, x in { -1, 1 } do
		for _, z in { -1, 1 } do
			local corner = ground * Vector3.new(x * W / 2, 0, z * L / 2)
			if Vector2.new(corner.X, corner.Z).Magnitude < Config.LOBBY_RADIUS + LOBBY_MARGIN then
				return false
			end
		end
	end
	return true
end

-- The box (center, size) that must hold no parts for a W x L footprint at `ground`: up to
-- `height`, with CLEARANCE to spare on each side.
function VehicleLayout.clearBox(
	ground: CFrame,
	W: number,
	L: number,
	height: number
): (CFrame, Vector3)
	local size = Vector3.new(W + CLEARANCE * 2, height, L + CLEARANCE * 2)
	local box = ground * CFrame.new(0, CLEAR_FLOOR + height / 2, 0)
	return box, size
end

-- The height clearBox checks above a vehicle's footprint.
function VehicleLayout.clearHeight(spec: VehicleSizing.Spec): number
	local top = VehicleSizing.solidHeight(spec)
	return if top > CLEAR_HEIGHT then top + WALKER_HEADROOM else CLEAR_HEIGHT
end

-- A random ground-level spot and heading in a spoke's motor pool, on either side of the road.
-- Draws four numbers from `rng`.
function VehicleLayout.randomSpot(rng: Random, spoke: number): CFrame
	local angle = Config.regionAngle(spoke)
	local outward = Config.pointAt(angle, 1)
	local side = Vector3.new(-outward.Z, 0, outward.X)
	local along = rng:NextNumber(Config.PARKING_START_RADIUS, Config.PARKING_END_RADIUS)
	local across = rng:NextNumber(SPOKE_HALF_WIDTH, Config.PARKING_REACH)
		* (if rng:NextNumber() < 0.5 then -1 else 1)
	local position = Config.pointAt(angle, along) + side * across
	return CFrame.new(position) * CFrame.Angles(0, rng:NextNumber(0, 2 * math.pi), 0)
end

-- The spoke (1..#Config.REGIONS) the `order`th motor-pool vehicle parks by: round-robin.
function VehicleLayout.spokeFor(order: number): number
	return (order - 1) % #Config.REGIONS + 1
end

-- The guard ring's radius: as tight as clearsLobby allows the deepest walker (`depth`, its
-- footprint length), whose back edge sits CLEARANCE past the lobby margin.
function VehicleLayout.guardRadius(depth: number): number
	return Config.LOBBY_RADIUS + LOBBY_MARGIN + CLEARANCE + depth / 2
end

-- The `index`th of `count` walkers' ground frame on the ring, facing out: the first in the middle
-- of the gap after the first gate road, the rest spread evenly.
function VehicleLayout.guardSpot(index: number, count: number, radius: number): CFrame
	local firstGap = Config.regionAngle(1) + math.pi / #Config.REGIONS
	local angle = firstGap + (index - 1) * 2 * math.pi / count
	local position = Config.pointAt(angle, radius)
	return CFrame.lookAt(position, position + Config.pointAt(angle, 1))
end

-- Whether an unoccupied parked vehicle goes back home: `distance` studs from home and unused for
-- `idleSeconds`, or fallen to height `y`.
function VehicleLayout.shouldRepark(distance: number, idleSeconds: number, y: number): boolean
	local away = distance > HOME_RADIUS
	local idle = idleSeconds > IDLE_TIME
	return (away and idle) or y < FALL_Y
end

-- The frame a spawned vehicle `length` long appears at: facing along `facing`'s horizontal part
-- (else +Z), half its length past `position`, so it clears the spawn point.
function VehicleLayout.spawnFrame(position: Vector3, facing: Vector3?, length: number): CFrame
	local flat = facing and Vector3.new(facing.X, 0, facing.Z)
	local look = if flat and flat.Magnitude > SPAWN_FACING_MIN then flat.Unit else Vector3.zAxis
	local center = position + look * (length / 2) + Vector3.new(0, SPAWN_LIFT, 0)
	return CFrame.lookAt(center, center + look)
end

return VehicleLayout
