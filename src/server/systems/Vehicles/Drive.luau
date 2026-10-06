-- Driving. The driver's client sends its stick/keys over the DriveInput remote (`onInput`); each
-- Heartbeat (`heartbeat`) turns them into targets for the velocity constraints on the skid of
-- every live car. Without a driver a car settles or holds its parking brake; a shoved car flies
-- free. `onInput` applies RemoteGuard: a non-finite axis is 0, and each player's events pass a
-- token bucket (DRIVE_RATE, DRIVE_BURST); `forget` drops a leaving player's, and events from a
-- player who left (no Parent) are ignored. init.luau connects
-- all three.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Names = require(ReplicatedStorage.Shared.Names)
local RemoteGuard = require(ReplicatedStorage.Shared.RemoteGuard)
local VehicleDrive = require(ReplicatedStorage.Shared.VehicleDrive)
local PodFlight = require(script.Parent.Parent.PodFlight)
local Characters = require(script.Parent.Parent.util.Characters)
local Climb = require(script.Parent.Climb)
local Registry = require(script.Parent.Registry)

local Drive = {}

local cars = Registry.cars
local setLimits = Registry.setLimits
local legsDriverSeat = Registry.legsDriverSeat
local stopClimb = Climb.stopClimb
local climbStep = Climb.climbStep

type Car = Registry.Car

-- Each player's DriveInput token bucket.
local limiters: { [Player]: RemoteGuard.Limiter } = {}

local function drive(car: Car, dt: number)
	local legsDriver = legsDriverSeat(car)
	local occupant = legsDriver and legsDriver.Occupant
	local skid = car.skid
	-- A shoved vehicle flies free for a moment: the drive constraints would cancel the shove.
	if os.clock() < car.stunnedUntil then
		car.mover.Enabled = false
		car.turner.Enabled = false
		stopClimb(car)
		return
	end
	-- Without a driver, ordinary physics has the car while it is at rest; when it moves (shoved,
	-- abandoned rolling) the constraints bleed off its speed and spin. A parking brake holds it
	-- still. With a driver, the drive constraints steer it, in the air too: arcade cars keep
	-- control off jumps.
	if not occupant then
		car.yaw = 0
		stopClimb(car)
		local velocity = skid.AssemblyLinearVelocity
		local flat = Vector2.new(velocity.X, velocity.Z)
		local spin = skid.AssemblyAngularVelocity.Y
		local settling = VehicleDrive.isSettling(car.parkingBrake, flat.Magnitude, spin)
		local held = car.parkingBrake or settling
		car.mover.Enabled = held
		car.turner.Enabled = held
		if car.parkingBrake then
			setLimits(car, car.driveForce, car.driveTorque)
			car.mover.PlaneVelocity = Vector2.zero
			car.turner.AngularVelocity = Vector3.zero
		elseif settling then
			-- Limits sized to the settling rates: a sliding friction other vehicles push through.
			local force, torque =
				VehicleDrive.settlingLimits(skid.AssemblyMass, skid.Size.X, skid.Size.Z)
			setLimits(car, force, torque)
			local slowed = VehicleDrive.settledSpeed(flat.Magnitude, dt)
			car.mover.PlaneVelocity = if flat.Magnitude > 0
				then flat.Unit * slowed
				else Vector2.zero
			car.turner.AngularVelocity = Vector3.new(0, VehicleDrive.settledSpin(spin, dt), 0)
		end
		return
	end
	setLimits(car, car.driveForce, car.driveTorque)
	car.mover.Enabled = true
	car.turner.Enabled = true

	local topSpeed = (car.seat:GetAttribute(Names.Attributes.TopSpeed) :: number?)
		or VehicleDrive.DEFAULT_TOP_SPEED
	local look = skid.CFrame.LookVector
	local forward = Vector3.new(look.X, 0, look.Z).Unit
	local speed = skid.AssemblyLinearVelocity:Dot(forward)
	local newSpeed = VehicleDrive.speed(car, speed, car.throttle, topSpeed, dt)
	local climb = climbStep(car, forward, dt)
	if climb and climb.press then
		newSpeed = climb.press
	end

	car.mover.PlaneVelocity = Vector2.new(forward.X * newSpeed, forward.Z * newSpeed)
	local climbing = climb ~= nil and climb.climbing
	local yaw = VehicleDrive.yaw(car, car.yaw, car.steer, newSpeed, climbing, dt)
	car.yaw = yaw
	car.turner.AngularVelocity = Vector3.new(0, yaw, 0)
end

local function heartbeat(dt: number)
	for model, car in cars do
		if model.Parent then
			drive(car, dt)
		else
			cars[model] = nil
		end
	end
end

-- Drops a leaving player's DriveInput limiter.
local function forget(player: Player)
	limiters[player] = nil
end

local function onInput(player: Player, throttle, steer, lift)
	if not player.Parent then
		return -- left the game: `forget` has run, so make no limiter
	end
	local now = os.clock()
	local limiter = limiters[player]
	if not limiter then
		limiter = RemoteGuard.newLimiter(RemoteGuard.DRIVE_RATE, RemoteGuard.DRIVE_BURST, now)
		limiters[player] = limiter
	end
	if not RemoteGuard.allow(limiter, now) then
		return
	end
	if typeof(throttle) ~= "number" or typeof(steer) ~= "number" then
		return
	end
	if typeof(lift) ~= "number" then
		lift = 0
	end
	local humanoid = Characters.humanoidOf(player)
	local seat = humanoid and humanoid.SeatPart
	local model = seat and seat.Parent
	local car = model and cars[model :: Model]
	if not car or (car.seat ~= seat and car.legsSeat ~= seat) then
		return
	end
	throttle, steer = RemoteGuard.axis(throttle), RemoteGuard.axis(steer)
	if car.pod and seat == car.seat then
		PodFlight.input(car.pod, throttle, steer, RemoteGuard.axis(lift))
	end
	if seat == legsDriverSeat(car) then
		car.throttle, car.steer = throttle, steer
	end
end

Drive.forget = forget
Drive.heartbeat = heartbeat
Drive.onInput = onInput

return Drive
