-- The vehicle system's shared state: the workspace folder every vehicle lives in, every live
-- car by model (`cars`, only here), the Car and Crash records, and two helpers the other modules
-- share (setLimits, legsDriverSeat).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MechClimb = require(ReplicatedStorage.Shared.MechClimb)
local Names = require(ReplicatedStorage.Shared.Names)
local PodState = require(ReplicatedStorage.Shared.PodState)
local VehicleDamage = require(ReplicatedStorage.Shared.VehicleDamage)
local PodFlight = require(script.Parent.Parent.PodFlight)

local Registry = {}

local folder = Instance.new("Folder")
folder.Name = Names.Instances.Vehicles
folder.Parent = workspace

export type Car = {
	seat: VehicleSeat,
	passengers: { Seat },
	skid: BasePart,
	mover: LinearVelocity,
	turner: AngularVelocity,
	turnRate: number,
	acceleration: number,
	braking: number,
	coasting: number,
	turnAcceleration: number?, -- rad/s^2 on the yaw rate; nil = instant
	turnInPlace: boolean, -- full turn rate at any speed
	parkingBrake: boolean, -- hold still with no driver
	driveForce: number, -- mover MaxForce while driven or braked
	driveTorque: number, -- turner MaxTorque while driven or braked
	stomps: boolean, -- walker: hurts what is under it at any pace, not by ramming speed
	reach: Vector3, -- half width, height, half length of the box it hurts, from the ground
	struck: { [Model]: number }, -- os.clock() each victim (character, vehicle, tree) was last hit
	mass: number, -- footprint mass, for shoves between vehicles
	ram: number, -- spec.ram
	weight: number, -- how hard it hits trees and creatures: 1 for the base car, times ram
	pace: number, -- recent top speed; outlasts the frame in which a crash stops the vehicle
	stunnedUntil: number, -- os.clock() until which a shove, not the drive constraints, moves it
	yaw: number, -- commanded yaw rate
	throttle: number,
	steer: number,
	pod: PodFlight.Pod?, -- a walker whose cab flies (spec.pod)
	legsSeat: VehicleSeat?, -- drives the legs while the pod is away (spec.pod.legsSeat)
	crash: Crash, -- crash damage
	model: Model,
	climber: LinearVelocity?, -- vertical lift for the climb assist; nil when it does not climb
	climbRays: MechClimb.Rays?,
	climb: MechClimb.State,
	climbing: boolean, -- mirrors the model's "Climbing" attribute
}

-- Every live car, by model.
local cars: { [Model]: Car } = {}

local function setLimits(car: Car, force: number, torque: number)
	-- Compared with slack: the properties store single precision.
	if math.abs(car.mover.MaxForce - force) > 1 then
		car.mover.MaxForce = force
	end
	if math.abs(car.turner.MaxTorque - torque) > 1 then
		car.turner.MaxTorque = torque
	end
end

-- The seat that drives the legs: the driver seat, or while a pod is away the legs seat (its pilot
-- flies the pod, PodFlight).
local function legsDriverSeat(car: Car): VehicleSeat?
	return if PodFlight.isDocked(car.pod) then car.seat else car.legsSeat
end

export type Crash = {
	bulk: number,
	armor: number, -- divides crash and ram damage (VehicleDamage.armor); 1 is none
	walker: boolean, -- lands on its legs (VehicleDamage.thresholds)
	length: number, -- footprint length: a head-on crash's sparks fly at the front
	height: number, -- solid height: smoke and fire rise from half of it
	podBulk: number, -- the flying pod's, from its own hull boxes
	podLength: number,
	podMass: number, -- the pod's footprint mass, for rams into it while it is away
	tracker: VehicleDamage.Tracker, -- the skid
	podTracker: VehicleDamage.Tracker, -- the pod's root while it is away
	podState: PodState.State, -- last seen; any change clears both trackers
	climbOut: ((Player) -> ())?, -- a walker's cab exit
	lastHit: BasePart?, -- the part (skid or pod root) that took the last damage: the wreck's center
	smoke: Smoke?,
	fire: Fire?,
}

Registry.folder = folder
Registry.cars = cars
Registry.setLimits = setLimits
Registry.legsDriverSeat = legsDriverSeat

return Registry
