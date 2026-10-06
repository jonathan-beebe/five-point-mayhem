--!strict
-- Contact math for driven vehicles (server Vehicles): when a vehicle counts as moving, the pace it
-- hits with, the box it sweeps each frame, how hard it shoves the vehicles it rams, what it does to
-- characters and creatures it touches, and when it fells a tree. Pure: numbers and Roblox
-- datatypes in and out; Vehicles applies them. The struck vehicle's health loss is VehicleDamage
-- (ramLoss). `tools/tests/vehicle_logic.luau` pins each function bit for bit against the inline
-- code it replaced.

local VehicleDamage = require(script.Parent.VehicleDamage)

local VehicleRam = {}

local RAM_MIN_SPEED = 12 -- studs/s; slower cars nudge
local STOMP_MOVE_SPEED = 2 -- studs/s a walker counts as moving above
local STOMP_MOVE_SPIN = 0.15 -- rad/s of yaw a walker turning in place counts as moving above
local STOMP_PACE = 25 -- studs/s a moving walker shoves vehicles and hits trees with, however slow
local PACE_DECAY = 150 -- studs/s^2 the remembered pace falls by
local HEADING_SPEED = 1 -- studs/s; slower, a vehicle's heading is where it faces
local AWAY_MIN = 0.1 -- studs; a victim closer to the center than this is pushed along the heading
local SWEEP_FLOOR = 0.5 -- studs over the ground the swept box starts
local OUTWARD_SHARE = 0.5 -- a car shoves along its heading plus this much of the outward line
local DIRECTION_MIN = 0.1 -- a shorter shove direction falls back to the outward line
-- A struck vehicle takes on the rammer's pace x RAM_TRANSFER x ram x their mass ratio (clamped),
-- up to MAX_SHOVE. Footprint masses: kart 215, base car 448, sedan ~670, school bus 1690.
local RAM_TRANSFER = 1.1 -- above 1, a struck vehicle of equal mass clears the rammer's path
local RAM_MIN_RATIO = 0.15
local RAM_MAX_RATIO = 3
local MAX_SHOVE = 140 -- studs/s
-- Studs/s; a softer touch (a walker turning in place) neither throws nor stuns.
VehicleRam.MIN_SHOVE = 1
local SHOVE_LIFT = 0.25 -- upward share of a shove
VehicleRam.STUN_TIME = 0.6 -- seconds a shoved vehicle flies free of its drive constraints
-- Characters and creatures touched: damage, and a fling along the push direction plus a lift.
local RAM_DAMAGE = 0.6 -- per stud/s of speed, times weight: 48 at 80 for the base car
local STOMP_DAMAGE = 40
local STOMP_FLING = 50 -- studs/s a walker flings at any pace
local RAM_FLING = 0.8 -- a car flings at this share of pace x weight
local FLING_LIFT = 35 -- studs/s up
local CREATURE_FLING = 1.6 -- creatures fly further than players
local CREATURE_LIFT = 0.5 -- extra upward fling on creatures per stud/s of pace
local MAX_FLING = 160 -- studs/s
-- A tree falls when pace x weight reaches TREE_BREAK x its toughness (0.8-1.5); slower vehicles
-- stop against it. The base car fells at 20-38 studs/s, a kart at 29-54, a school bus at 10-19.
local TREE_BREAK = 25
local TREE_PUSH = 0.4 -- share of pace x weight the felled tree's crown takes on
local MAX_TREE_PUSH = 40 -- studs/s

-- How hard a vehicle hits trees and creatures: 1 for the base car, times `ram` (spec.ram).
-- `strength` is VehicleDrive.strength's.
function VehicleRam.weight(strength: number, ram: number): number
	return math.sqrt(strength) * ram
end

-- The share of the rammer's speed a struck body of `mass` takes on: RAM_TRANSFER x their mass
-- ratio (clamped) x ram. `rammerMass` and masses are footprint masses (VehicleSizing).
function VehicleRam.transfer(rammerMass: number, mass: number, ram: number): number
	return RAM_TRANSFER * math.clamp(rammerMass / mass, RAM_MIN_RATIO, RAM_MAX_RATIO) * ram
end

-- The remembered pace: this frame's horizontal `speed`, or the last pace decayed over `dt`. It
-- outlasts the frame in which a crash stops the vehicle.
function VehicleRam.decayPace(pace: number, speed: number, dt: number): number
	return math.max(speed, pace - PACE_DECAY * dt)
end

-- Whether a driven vehicle hits anything: a walker moving or turning (`spinY`, yaw rad/s), a car
-- whose pace reaches RAM_MIN_SPEED.
function VehicleRam.isMoving(stomps: boolean, speed: number, spinY: number, pace: number): boolean
	return if stomps
		then speed > STOMP_MOVE_SPEED or math.abs(spinY) > STOMP_MOVE_SPIN
		else pace >= RAM_MIN_SPEED
end

-- The pace a vehicle hits with: a walker's legs come down at STOMP_PACE however slow it goes.
function VehicleRam.ramPace(stomps: boolean, pace: number): number
	return if stomps then math.max(pace, STOMP_PACE) else pace
end

-- The way a vehicle is going: along `flat` (horizontal velocity, `speed` long), or when nearly
-- still the way it faces (`look`).
function VehicleRam.heading(flat: Vector3, speed: number, look: Vector3): Vector3
	return if speed > HEADING_SPEED then flat.Unit else Vector3.new(look.X, 0, look.Z).Unit
end

-- The horizontal line from `origin` out to `position`; `fallback` when they nearly coincide.
function VehicleRam.away(origin: Vector3, position: Vector3, fallback: Vector3): Vector3
	local offset = position - origin
	offset = Vector3.new(offset.X, 0, offset.Z)
	return if offset.Magnitude > AWAY_MIN then offset.Unit else fallback
end

-- The box (center, size) a vehicle checks for vehicles and trees this frame: its reach, from
-- SWEEP_FLOOR up, stretched one frame (`flat` x `dt`) ahead. `ground` is the skid's ground frame.
function VehicleRam.sweep(
	ground: CFrame,
	flat: Vector3,
	reach: Vector3,
	dt: number
): (CFrame, Vector3)
	local ahead = ground:VectorToObjectSpace(flat) * dt
	local height = reach.Y - SWEEP_FLOOR
	local box = ground * CFrame.new(ahead.X / 2, SWEEP_FLOOR + height / 2, ahead.Z / 2)
	local size =
		Vector3.new(reach.X * 2 + math.abs(ahead.X), height, reach.Z * 2 + math.abs(ahead.Z))
	return box, size
end

-- Whether `position` is inside the box a vehicle hurts (`reach`, VehicleSizing.reach) at `ground`.
function VehicleRam.touches(reach: Vector3, ground: CFrame, position: Vector3): boolean
	local at = ground:PointToObjectSpace(position)
	return math.abs(at.X) <= reach.X
		and math.abs(at.Z) <= reach.Z
		and at.Y >= -2
		and at.Y <= reach.Y
end

-- The direction a rammed vehicle is thrown: a walker pushes it straight out; a car along its
-- heading, bent outward.
function VehicleRam.shoveDirection(stomps: boolean, heading: Vector3, outward: Vector3): Vector3
	local direction = if stomps then outward else heading + outward * OUTWARD_SHARE
	return if direction.Magnitude > DIRECTION_MIN then direction.Unit else outward
end

-- The speed a rammed vehicle is thrown at (VehicleDamage.shovePace x `transfer`), up to MAX_SHOVE.
-- Under MIN_SHOVE there is no throw.
function VehicleRam.shoveSpeed(
	pace: number,
	closing: number,
	stomps: boolean,
	transfer: number
): number
	return math.min(VehicleDamage.shovePace(pace, closing, stomps) * transfer, MAX_SHOVE)
end

-- A thrown vehicle's new velocity: its `current` one plus the throw and its lift, up to MAX_SHOVE.
function VehicleRam.shoveVelocity(current: Vector3, direction: Vector3, speed: number): Vector3
	local velocity = current + direction * speed + Vector3.new(0, speed * SHOVE_LIFT, 0)
	if velocity.Magnitude > MAX_SHOVE then
		velocity = velocity.Unit * MAX_SHOVE
	end
	return velocity
end

-- Damage to a character or creature a vehicle touches.
function VehicleRam.contactDamage(stomps: boolean, pace: number, weight: number): number
	return if stomps then STOMP_DAMAGE else pace * RAM_DAMAGE * weight
end

-- The push on a touched character or creature, along `direction`.
function VehicleRam.fling(
	direction: Vector3,
	stomps: boolean,
	pace: number,
	weight: number,
	creature: boolean
): Vector3
	local fling = if stomps then STOMP_FLING else pace * RAM_FLING * weight
	local lift = FLING_LIFT
	if creature then
		fling *= CREATURE_FLING
		lift += pace * CREATURE_LIFT
	end
	return direction * math.min(fling, MAX_FLING) + Vector3.new(0, lift, 0)
end

-- Whether a vehicle hitting a tree of `toughness` at `pace` fells it.
function VehicleRam.breaksTree(pace: number, weight: number, toughness: number): boolean
	return pace * weight >= TREE_BREAK * toughness
end

-- The speed a felled tree's crown is pushed at.
function VehicleRam.treePush(pace: number, weight: number): number
	return math.min(pace * weight * TREE_PUSH, MAX_TREE_PUSH)
end

-- Where a felled tree is pushed: high on its bounding box (`box`, `extent`), so it pivots on its
-- base.
function VehicleRam.treeCrown(box: CFrame, extent: Vector3): Vector3
	return box.Position + Vector3.new(0, extent.Y / 4, 0)
end

return VehicleRam
