-- Vehicle health: crash damage, ram damage, smoke and fire, and wrecks. Health.damage is
-- Vehicles.damage.

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Names = require(ReplicatedStorage.Shared.Names)
local PodState = require(ReplicatedStorage.Shared.PodState)
local SoundCatalog = require(ReplicatedStorage.Shared.SoundCatalog)
local Sounds = require(ReplicatedStorage.Shared.Sounds)
local VehicleCatalog = require(ReplicatedStorage.Shared.VehicleCatalog)
local VehicleDamage = require(ReplicatedStorage.Shared.VehicleDamage)
local VehicleSizing = require(ReplicatedStorage.Shared.VehicleSizing)
local Combat = require(script.Parent.Parent.Combat)
local PodFlight = require(script.Parent.Parent.PodFlight)
local VehicleModel = require(script.Parent.Parent.VehicleModel)
local Characters = require(script.Parent.Parent.util.Characters)
local Ownership = require(script.Parent.Parent.util.Ownership)
local Seats = require(script.Parent.Parent.util.Seats)
local Climb = require(script.Parent.Climb)
local Registry = require(script.Parent.Registry)

local Health = {}

local rgb = Color3.fromRGB
local M = Enum.Material

local cars = Registry.cars
local setLimits = Registry.setLimits
local stopClimb = Climb.stopClimb

type Car = Registry.Car
type Crash = Registry.Crash

-- Each Heartbeat samples the velocity of the skid (and of a pod away from its legs) into a
-- VehicleDamage tracker; a crash it reports costs the vehicle health (model attributes Health and
-- MaxHealth, from its bulk). Only assemblies the server simulates are tracked: a client's samples
-- arrive late and jumpy. Anything else that sets a tracked velocity (a shove, a pod docking)
-- clears the tracker. At half health the vehicle smokes, at a quarter it burns; at none it is
-- wrecked.

local WRECK_DAMAGE = 35 -- the wreck's blast at its center
local WRECK_THROW = 60 -- studs/s up that throws out whoever is aboard
local WRECK_SCATTER = 20 -- studs/s, at most, sideways
local WRECK_HOP = 25 -- studs/s up the hulk jumps
local WRECK_TIME = 10 -- seconds the burnt-out hulk stays
local CHAR_COLOR = rgb(20, 20, 20)
local CHAR_SHARE = 0.75 -- how far each part's color goes to CHAR_COLOR

local scatter = Random.new()

local function newCrash(id: string, spec: VehicleModel.Model): Crash
	local entry = VehicleCatalog.get(id)
	local override = entry and entry.bulk
	local size = VehicleSizing.crash(spec, override)
	return {
		bulk = size.bulk,
		walker = size.walker,
		length = size.length,
		height = size.height,
		podBulk = size.podBulk,
		podLength = size.podLength,
		podMass = size.podMass,
		tracker = VehicleDamage.newTracker(),
		podTracker = VehicleDamage.newTracker(),
		podState = PodState.DOCKED,
		climbOut = nil,
		lastHit = nil,
		smoke = nil,
		fire = nil,
	}
end

-- A crash's sound and a burst of sparks at `at`.
local function crashFeedback(model: Model, at: Vector3, amount: number)
	local maxHealth = (model:GetAttribute(Names.Attributes.MaxHealth) :: number?) or 100
	local cue = if VehicleDamage.isHeavy(amount, maxHealth)
		then SoundCatalog.CRASH.heavy
		else SoundCatalog.CRASH.light
	Sounds.playAt(cue, at, "Weapons")
	local spot = Instance.new("Attachment")
	spot.Name = "CrashSparks"
	spot.Position = at -- Terrain sits at the origin
	spot.Parent = workspace.Terrain
	local sparks = Instance.new("ParticleEmitter")
	sparks.Enabled = false
	sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparks.LightEmission = 1
	sparks.Color = ColorSequence.new(rgb(255, 240, 170), rgb(255, 120, 30))
	sparks.Size = NumberSequence.new(0.5, 0)
	sparks.Lifetime = NumberRange.new(0.3, 0.7)
	sparks.Speed = NumberRange.new(20, 45)
	sparks.SpreadAngle = Vector2.new(180, 180)
	sparks.Acceleration = Vector3.new(0, -workspace.Gravity / 4, 0)
	sparks.Parent = spot
	sparks:Emit(math.clamp(math.round(amount), 8, 60))
	Debris:AddItem(spot, 1.5)
end

-- Feeds `part`'s velocity to `tracker`, and damages the vehicle by a crash it reports.
local function sampleCrash(
	model: Model,
	crash: Crash,
	part: BasePart,
	tracker: VehicleDamage.Tracker,
	bulk: number,
	walker: boolean,
	length: number,
	dt: number
)
	if not Ownership.isServerSimulated(part) then
		VehicleDamage.clear(tracker)
		return
	end
	local velocity = part.AssemblyLinearVelocity
	local lossH, lossV = VehicleDamage.step(tracker, velocity.X, velocity.Y, velocity.Z, dt)
	if not lossH or not lossV then
		return
	end
	local amount = VehicleDamage.damage(bulk, lossH, lossV, walker)
	if amount <= 0 then
		return
	end
	-- Head-on: at the front, the way it was going. A landing: under it.
	local at = VehicleDamage.crashPoint(
		part.Position,
		tracker.startX,
		tracker.startZ,
		lossH,
		lossV,
		length
	)
	crashFeedback(model, at, amount)
	crash.lastHit = part
	Health.damage(model, amount)
end

local function trackCrash(model: Model, car: Car, dt: number)
	local crash = car.crash
	local podState = if car.pod then car.pod.state else PodState.DOCKED
	if podState ~= crash.podState then
		-- A pod letting go of its legs or snapping back onto them jumps both velocities.
		crash.podState = podState
		VehicleDamage.clear(crash.tracker)
		VehicleDamage.clear(crash.podTracker)
	end
	sampleCrash(model, crash, car.skid, crash.tracker, crash.bulk, crash.walker, crash.length, dt)
	if car.pod and podState ~= PodState.DOCKED then
		sampleCrash(
			model,
			crash,
			car.pod.root,
			crash.podTracker,
			crash.podBulk,
			false,
			crash.podLength,
			dt
		)
	end
end

-- A ram hits the struck vehicle like a crash that lost `loss` studs/s (VehicleDamage.ramLoss):
-- its legs (the skid), or with `pod` its pod away from them. A shove sets the velocity, so the
-- tracker starts over.
local function rammed(other: Car, loss: number, pod: boolean?)
	local crash = other.crash
	local part = if pod and other.pod then other.pod.root else other.skid
	VehicleDamage.clear(if pod then crash.podTracker else crash.tracker)
	local amount = VehicleDamage.damage(if pod then crash.podBulk else crash.bulk, loss, 0)
	local model = other.skid.Parent
	if amount > 0 and model and model:IsA("Model") then
		crashFeedback(model, part.Position, amount)
		crash.lastHit = part
		Health.damage(model, amount)
	end
end

-- Throws whoever sits in `seat` out and up.
local function throwOut(seat: (Seat | VehicleSeat)?)
	local humanoid = seat and seat.Occupant
	if not seat or not humanoid then
		return
	end
	Seats.unseat(seat, humanoid)
	local character = humanoid.Parent
	if character and character:IsA("Model") then
		local sideways = Vector3.new(
			scatter:NextNumber(-WRECK_SCATTER, WRECK_SCATTER),
			0,
			scatter:NextNumber(-WRECK_SCATTER, WRECK_SCATTER)
		)
		Combat.push(character, sideways + Vector3.new(0, WRECK_THROW, 0), 0.2)
	end
end

-- Destroys a vehicle at no health: it brakes to a stop, throws out everyone aboard (a walker's cab
-- puts whoever stands in it at the exit), explodes, chars, hops, and is cleared after WRECK_TIME.
-- A parked vehicle's spot then builds a fresh one (Parking.start); a /give vehicle is gone.
local function wreck(model: Model, car: Car)
	if model:GetAttribute(Names.Attributes.Wrecked) then
		return
	end
	model:SetAttribute(Names.Attributes.Wrecked, true)
	model:SetAttribute(Names.Attributes.Health, 0)
	cars[model] = nil
	-- The skid is frictionless: the drive constraints, held at zero, are the hulk's brake. A
	-- rammed wreck flies its throw out first (the rest of VehicleRam.STUN_TIME), then brakes.
	local function brake()
		setLimits(car, car.driveForce, car.driveTorque)
		car.mover.PlaneVelocity = Vector2.zero
		car.turner.AngularVelocity = Vector3.zero
		car.mover.Enabled = true
		car.turner.Enabled = true
	end
	local stun = car.stunnedUntil - os.clock()
	if stun > 0 then
		car.mover.Enabled = false
		car.turner.Enabled = false
		task.delay(stun, brake)
	else
		brake()
	end
	-- A walker wrecked mid-climb lets go and falls.
	stopClimb(car)
	if car.pod then
		PodFlight.wreck(car.pod)
	end
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("ProximityPrompt") then
			descendant:Destroy()
		end
	end
	throwOut(car.seat)
	throwOut(car.legsSeat)
	for _, seat in car.passengers do
		throwOut(seat)
	end
	local climbOut = car.crash.climbOut
	local cab = model:FindFirstChild(Names.Instances.Cab) :: BasePart?
	if climbOut and cab then
		-- Deferred: a thrown-out driver sits until the weld's removal lands, and climbOut skips
		-- anyone seated.
		task.defer(function()
			for _, player in Players:GetPlayers() do
				if Characters.isInside(player, cab) then
					climbOut(player)
				end
			end
		end)
	end

	-- At the part that crashed (a flying pod, or the legs), else the skid.
	local hit = car.crash.lastHit
	local center = if hit and hit:IsDescendantOf(model) then hit.Position else car.skid.Position
	Combat.explode(nil, center, VehicleDamage.wreckRadius(car.crash.bulk), WRECK_DAMAGE)
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and part.Transparency < 1 then
			part.Color = part.Color:Lerp(CHAR_COLOR, CHAR_SHARE)
			part.Material = M.CorrodedMetal
		end
	end
	if Ownership.isServerSimulated(car.skid) then
		car.skid.AssemblyLinearVelocity += Vector3.new(0, WRECK_HOP, 0)
	end
	task.delay(WRECK_TIME, function()
		model:Destroy()
	end)
end

-- Smoke at half health and fire at a quarter, from the skid at half the solid height; a wreck at
-- none.
local function onHealth(model: Model, car: Car)
	if model:GetAttribute(Names.Attributes.Wrecked) then
		return
	end
	local health = (model:GetAttribute(Names.Attributes.Health) :: number?) or 0
	local maxHealth = (model:GetAttribute(Names.Attributes.MaxHealth) :: number?) or 1
	local crash = car.crash
	local share = health / maxHealth
	if VehicleDamage.smokes(share) and not crash.smoke then
		local spot = Instance.new("Attachment")
		spot.Name = "DamageFx"
		spot.Position = Vector3.new(0, math.max(crash.height / 2, 1), 0)
		spot.Parent = car.skid
		local size = 4 + 2 * math.sqrt(crash.bulk)
		local smoke = Instance.new("Smoke")
		smoke.Color = rgb(45, 45, 48)
		smoke.Opacity = 0.4
		smoke.Size = size
		smoke.RiseVelocity = 8
		smoke.Parent = spot
		local fire = Instance.new("Fire")
		fire.Size = math.min(size, 30)
		fire.Heat = 12
		fire.Enabled = false
		fire.Parent = spot
		crash.smoke, crash.fire = smoke, fire
	end
	if crash.smoke and crash.fire then
		crash.smoke.Enabled = VehicleDamage.smokes(share)
		crash.fire.Enabled = VehicleDamage.burns(share)
	end
	if health <= 0 then
		wreck(model, car)
	end
end

-- Health from the vehicle's bulk, set before the model is parented so clients see it at once.
local function addHealth(model: Model, car: Car)
	local maxHealth = VehicleDamage.maxHealth(car.crash.bulk)
	model:SetAttribute(Names.Attributes.MaxHealth, maxHealth)
	model:SetAttribute(Names.Attributes.Health, maxHealth)
	model:GetAttributeChangedSignal(Names.Attributes.Health):Connect(function()
		onHealth(model, car)
	end)
end

-- Takes `amount` health from a vehicle (crashes, rams; weapons could). A wreck takes no more.
function Health.damage(model: Model, amount: number)
	local health = model:GetAttribute(Names.Attributes.Health)
	if
		model:GetAttribute(Names.Attributes.Wrecked)
		or typeof(health) ~= "number"
		or amount <= 0
	then
		return
	end
	model:SetAttribute(Names.Attributes.Health, math.max(0, health - amount))
end

Health.newCrash = newCrash
Health.trackCrash = trackCrash
Health.rammed = rammed
Health.addHealth = addHealth

return Health
