-- Contact damage and ramming. Each Heartbeat (`heartbeat`) samples every live car for crash
-- damage (Health.trackCrash), and a driven one hurts whoever it touches (cars ram, walkers stomp),
-- shoves the vehicles it hits (Health.rammed) and fells trees (Trees). Drone legs (Drive) count
-- as driven by the pod's pilot. `addGrove` adds a tagged tree's grove to what vehicles can ram.
-- init.luau connects both.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Names = require(ReplicatedStorage.Shared.Names)
local VehicleDamage = require(ReplicatedStorage.Shared.VehicleDamage)
local VehicleRam = require(ReplicatedStorage.Shared.VehicleRam)
local Combat = require(script.Parent.Parent.Combat)
local PodFlight = require(script.Parent.Parent.PodFlight)
local Ownership = require(script.Parent.Parent.util.Ownership)
local Health = require(script.Parent.Health)
local Placement = require(script.Parent.Placement)
local Registry = require(script.Parent.Registry)
local Trees = require(script.Parent.Trees)

local Contact = {}

local folder = Registry.folder
local cars = Registry.cars
local legsDriverSeat = Registry.legsDriverSeat
local SKID_TO_GROUND = Placement.SKID_TO_GROUND
local rammed = Health.rammed
local trackCrash = Health.trackCrash
local fell = Trees.fell

type Car = Registry.Car

-- The numbers (pace, shoves, flings, tree breaks) are VehicleRam's; the reach box is
-- VehicleSizing.reach.
local HIT_INTERVAL = 0.1 -- seconds between contact checks on characters and barrels
local HIT_COOLDOWN = 0.8 -- seconds before the same vehicle hits the same victim again

-- What a vehicle can ram: the solid parts of vehicles and of the tree groves (the parents of
-- trees tagged Tree by Landscape).
local rammable = OverlapParams.new()
rammable.FilterType = Enum.RaycastFilterType.Include
rammable.RespectCanCollide = true
local rammableRoots: { Instance } = { folder }
rammable.FilterDescendantsInstances = rammableRoots

local function addGrove(tree: Instance)
	local grove = tree.Parent
	if grove and not table.find(rammableRoots, grove) then
		table.insert(rammableRoots, grove)
		rammable.FilterDescendantsInstances = rammableRoots
	end
end

-- Throws a struck vehicle along `direction`, scaled by the rammer's pace, ram and the two masses,
-- and frees it from its drive constraints for VehicleRam.STUN_TIME so the throw carries. Its
-- damage comes from `closing`, the rammer's real speed toward it.
local function shove(
	car: Car,
	other: Car,
	direction: Vector3,
	pace: number,
	closing: number,
	now: number
)
	local skid = other.skid
	local transfer = VehicleRam.transfer(car.mass, other.mass, car.ram)
	local speed = VehicleRam.shoveSpeed(pace, closing, car.stomps, transfer)
	if speed < VehicleRam.MIN_SHOVE then
		-- No throw, so no stun: a car pinned by a creeping walker keeps its drive and can back out.
		rammed(other, VehicleDamage.ramLoss(closing, transfer, car.stomps))
		return
	end
	-- Stunned first: a ram that wrecks it lets the throw fly before the wreck brakes (wreck).
	other.stunnedUntil = now + VehicleRam.STUN_TIME
	rammed(other, VehicleDamage.ramLoss(closing, transfer, car.stomps))
	-- The server must own the struck vehicle for the throw to take. A driven one it already owns;
	-- an empty one it takes here. One carrying only passengers stays with their client, which
	-- leaves it to the collision alone.
	local aboard = other.seat.Occupant ~= nil
	for _, seat in other.passengers do
		aboard = aboard or seat.Occupant ~= nil
	end
	if not aboard then
		Ownership.set(skid, nil)
	end
	skid.AssemblyLinearVelocity =
		VehicleRam.shoveVelocity(skid.AssemblyLinearVelocity, direction, speed)
end

-- Vehicles and trees are checked every frame with a box that reaches one frame ahead, so the hit
-- lands before the crash stops the rammer. Characters and barrels are checked every
-- HIT_INTERVAL (`checkTargets`).
local function hurtTouching(model: Model, car: Car, dt: number, checkTargets: boolean)
	local skid = car.skid
	local velocity = skid.AssemblyLinearVelocity
	local flat = Vector3.new(velocity.X, 0, velocity.Z)
	local speed = flat.Magnitude
	car.pace = VehicleRam.decayPace(car.pace, speed, dt)
	local legsDriver = legsDriverSeat(car)
	local occupant = legsDriver and legsDriver.Occupant
	if not occupant and PodFlight.droneGoal(car.pod) then
		occupant = (car.pod :: PodFlight.Pod).seat.Occupant -- drone legs: the pilot drives them
	end
	local now = os.clock()
	-- A shoved vehicle hits nothing until it is back under control: no chains of shoves.
	if not occupant or now < car.stunnedUntil then
		return
	end
	local driver = Players:GetPlayerFromCharacter(occupant.Parent)
	if not VehicleRam.isMoving(car.stomps, speed, skid.AssemblyAngularVelocity.Y, car.pace) then
		return
	end
	local pace = VehicleRam.ramPace(car.stomps, car.pace)
	local ground = skid.CFrame * SKID_TO_GROUND
	local heading = VehicleRam.heading(flat, speed, ground.LookVector)
	local function away(position: Vector3): Vector3
		return VehicleRam.away(ground.Position, position, heading)
	end

	local box, size = VehicleRam.sweep(ground, flat, car.reach, dt)
	for _, part in workspace:GetPartBoundsInBox(box, size, rammable) do
		local victim = part.Parent
		if
			not victim
			or victim == model
			or not victim:IsA("Model")
			or now - (car.struck[victim :: Model] or 0) < HIT_COOLDOWN
		then
			continue
		end
		local other = cars[victim :: Model]
		local pod = other and other.pod
		if
			other
			and pod
			and not PodFlight.isDocked(pod)
			and part.AssemblyRootPart == pod.root.AssemblyRootPart
		then
			-- Its pod, away from the legs: damage only. The pod's own mover holds its course; the
			-- legs are not touched.
			car.struck[victim :: Model] = now
			local struck = pod.root.AssemblyLinearVelocity
			local outward = away(pod.root.Position)
			local closing = VehicleDamage.closingSpeed(
				velocity.X,
				velocity.Z,
				struck.X,
				struck.Z,
				outward.X,
				outward.Z
			)
			local transfer = VehicleRam.transfer(car.mass, other.crash.podMass, car.ram)
			rammed(other, VehicleDamage.ramLoss(closing, transfer, car.stomps), true)
		elseif other then
			car.struck[victim :: Model] = now
			local outward = away(other.skid.Position)
			local direction = VehicleRam.shoveDirection(car.stomps, heading, outward)
			local struck = other.skid.AssemblyLinearVelocity
			local closing = VehicleDamage.closingSpeed(
				velocity.X,
				velocity.Z,
				struck.X,
				struck.Z,
				outward.X,
				outward.Z
			)
			shove(car, other, direction, pace, closing, now)
		elseif CollectionService:HasTag(victim, Names.Tags.Tree) then
			local toughness = (victim:GetAttribute(Names.Attributes.Toughness) :: number?) or 1
			if VehicleRam.breaksTree(pace, car.weight, toughness) then
				car.struck[victim :: Model] = now
				fell(
					victim :: Model,
					if car.stomps then away(part.Position) else heading,
					pace,
					car.weight
				)
			end
		end
	end

	if not checkTargets then
		return
	end
	for _, target in Combat.getTargets() do
		local humanoid = target.humanoid
		local seat = humanoid.SeatPart
		if
			(seat and seat:IsDescendantOf(model))
			or humanoid:GetState() == Enum.HumanoidStateType.Climbing
			or now - (car.struck[target.model] or 0) < HIT_COOLDOWN
			or not VehicleRam.touches(car.reach, ground, target.root.Position)
		then
			continue
		end
		local amount = VehicleRam.contactDamage(car.stomps, pace, car.weight)
		if Combat.damage(driver, target.model, humanoid, amount) then
			car.struck[target.model] = now
			local direction = if car.stomps or speed < 1
				then away(target.root.Position)
				else heading
			local creature = Players:GetPlayerFromCharacter(target.model) == nil
			local push = VehicleRam.fling(direction, car.stomps, pace, car.weight, creature)
			if creature and humanoid.Health <= 0 then
				-- A kill: throw the whole body before its joints break, so the pieces scatter.
				target.root.AssemblyLinearVelocity = push
			end
			Combat.push(target.model, push, 0.2)
		end
	end
	for _, barrel in CollectionService:GetTagged(Names.Tags.ExplosiveBarrel) do
		if barrel:IsA("BasePart") and VehicleRam.touches(car.reach, ground, barrel.Position) then
			Combat.detonateBarrel(barrel, driver)
		end
	end
	for victim, at in car.struck do
		if now - at > HIT_COOLDOWN then
			car.struck[victim] = nil
		end
	end
end

local sinceHits = 0
local function heartbeat(dt: number)
	sinceHits += dt
	local checkTargets = sinceHits >= HIT_INTERVAL
	if checkTargets then
		sinceHits = 0
	end
	for model, car in cars do
		if model.Parent then
			trackCrash(model, car, dt)
			hurtTouching(model, car, dt, checkTargets)
		end
	end
end

Contact.addGrove = addGrove
Contact.heartbeat = heartbeat

return Contact
