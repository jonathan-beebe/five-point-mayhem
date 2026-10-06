-- Engine sounds for vehicles near the camera, made and driven on this client only (client sounds
-- do not replicate, so per-frame pitch and volume cost no network). While a vehicle's driver
-- seat is occupied its engine runs: a start one-shot, then loops whose pitch and volume follow
-- speed / TopSpeed. Profiles live in SoundCatalog.VEHICLES; walkers instead get the mech handler
-- with their profile from SoundCatalog.MECHS.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local EngineEnvelope = require(ReplicatedStorage.Shared.EngineEnvelope)
local MathUtil = require(ReplicatedStorage.Shared.MathUtil)
local MechGait = require(ReplicatedStorage.Shared.MechGait)
local Names = require(ReplicatedStorage.Shared.Names)
local NearestSet = require(ReplicatedStorage.Shared.NearestSet)
local SoundCatalog = require(ReplicatedStorage.Shared.SoundCatalog)
local Sounds = require(ReplicatedStorage.Shared.Sounds)

local MechMotion = require(script.Parent.MechMotion)

local VehicleSounds = {}

local GROUP = "Vehicles"
local SETTINGS = SoundCatalog.VEHICLE
local SELECT_INTERVAL = 0.25 -- seconds between choosing which vehicles get sounds

-- A vehicle's sounds. `update` runs every frame while the vehicle is near the camera; `destroy`
-- removes its sounds.
type Handler = { update: (dt: number) -> (), destroy: () -> () }

local random = Random.new()

-- Starts a loop at a random point in its file, so matching vehicles do not phase.
local function startLoop(sound: Sound, loop: SoundCatalog.Loop)
	local length = SoundCatalog.PALETTE[loop.key].duration
	sound.TimePosition = random:NextNumber(0, length * SETTINGS.loopStartSpread)
	sound:Play()
end

local function engineHandler(model: Model, profile: SoundCatalog.VehicleSounds): Handler?
	local skid = model.PrimaryPart
	local seat = model:FindFirstChild(Names.Instances.DriverSeat)
	if
		not skid
		or not seat
		or not seat:IsA("VehicleSeat")
		or not seat:GetAttribute(Names.Attributes.MayhemCar)
	then
		return nil
	end
	local driverSeat = seat :: VehicleSeat
	local topSpeed = (driverSeat:GetAttribute(Names.Attributes.TopSpeed) :: number?)
		or driverSeat.MaxSpeed

	type Voice = { loop: SoundCatalog.Loop, sound: Sound, isEngine: boolean }
	local voices: { Voice } = {}
	for index, loop in { profile.engine, table.unpack(profile.layers or {}) } do
		local sound = Sounds.make(loop, GROUP)
		sound.Looped = true
		sound.Volume = 0
		sound.Parent = skid
		table.insert(voices, { loop = loop, sound = sound, isEngine = index == 1 })
	end

	local running = false -- driver seated
	local playing = false -- loops started
	local loopsAt = 0 -- os.clock() at which the loops start
	local level = 0 -- fade in/out, 0..1
	local smoothed = 0 -- speed / top speed, smoothed
	local bump = 0 -- extra engine pitch while accelerating

	local function update(dt: number)
		local seated = driverSeat.Occupant ~= nil
		if seated and not running then
			running = true
			loopsAt = os.clock()
			if profile.start then
				Sounds.playOn(profile.start, skid, GROUP)
				loopsAt += SETTINGS.startDelay
			end
		elseif not seated and running then
			running = false
		end
		if running and not playing and os.clock() >= loopsAt then
			playing = true
			for _, voice in voices do
				startLoop(voice.sound, voice.loop)
			end
		end

		local follow = MathUtil.rateAlpha(SETTINGS.smoothing, dt)
		local velocity = skid.AssemblyLinearVelocity
		local speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
		local target = math.clamp(speed / topSpeed, 0, 1)
		smoothed, bump = EngineEnvelope.follow(smoothed, bump, target, follow, SETTINGS.loadBump)

		if not playing then
			return
		end
		level = EngineEnvelope.fade(level, running, dt, SETTINGS.fadeIn, SETTINGS.fadeOut)
		if level <= 0 then
			playing = false
			for _, voice in voices do
				voice.sound:Stop()
			end
			return
		end
		for _, voice in voices do
			local pitch, volume = EngineEnvelope.loop(voice.loop, smoothed, SETTINGS.pitchCurve)
			voice.sound.PlaybackSpeed = pitch + (if voice.isEngine then bump else 0)
			voice.sound.Volume = volume * level
		end
	end

	return {
		update = update,
		destroy = function()
			for _, voice in voices do
				voice.sound:Destroy()
			end
		end,
	}
end

-- A walker. MechMotion animates the legs on this client; the servo follows its cadence and each
-- heel strike it fires plays a step in that foot (and a creak at that knee, if the profile has
-- one). The hatch opens and closes with the driver seat's occupant (MechGait animates it from the
-- same signal).
local function mechHandler(model: Model, profile: SoundCatalog.MechSounds): Handler?
	local skid = model.PrimaryPart
	local seat = model:FindFirstChild(Names.Instances.DriverSeat)
	if not skid or not seat or not seat:IsA("VehicleSeat") then
		return nil
	end
	local driverSeat = seat :: VehicleSeat

	local hum = Sounds.make(profile.hum, GROUP)
	hum.Looped = true
	hum.Parent = skid
	local servo = Sounds.make(profile.servo, GROUP)
	servo.Looped = true
	servo.Parent = skid

	local function part(name: string): Instance
		return model:FindFirstChild(name) or skid :: BasePart
	end

	-- A mech that comes into range already piloted hums at once, without the power-up.
	local running = driverSeat.Occupant ~= nil
	local humAt = if running then 0 else math.huge -- os.clock() at which the hum starts
	local level = 0 -- hum fade in/out, 0..1
	local speed = 0 -- ground speed / top speed, smoothed
	local cadence = 0 -- leg cadence / cadence at top speed, smoothed

	local footfall = MechMotion.footfall:Connect(function(walker: Model, foot: string, strength)
		if walker == model then
			Sounds.playOn(
				profile.step,
				part(Names.Instances.BonePrefix .. "foot_" .. foot),
				GROUP,
				strength
			)
			if profile.creak then
				Sounds.playOn(
					profile.creak,
					part(Names.Instances.BonePrefix .. "shin_" .. foot),
					GROUP,
					strength
				)
			end
		end
	end)

	local function update(dt: number)
		local seated = driverSeat.Occupant ~= nil
		if seated and not running then
			running = true
			humAt = os.clock() + profile.humDelay
			Sounds.playOn(profile.powerUp, skid, GROUP)
			Sounds.playOn(profile.hatchClose, part(Names.Instances.BonePrefix .. "hatch"), GROUP)
		elseif not seated and running then
			running = false
			Sounds.playOn(profile.hatchOpen, part(Names.Instances.BonePrefix .. "hatch"), GROUP)
		end

		local gait = MechMotion.gait(model)
		local targetSpeed, targetCadence = 0, 0
		if gait then
			local cycle = MechGait.CYCLE * gait.rig.scale
			targetSpeed, targetCadence =
				EngineEnvelope.mechTargets(gait.ground, gait.topSpeed, gait.rate, cycle)
		end
		local follow = MathUtil.rateAlpha(profile.smoothing, dt)
		speed += (targetSpeed - speed) * follow
		cadence += (targetCadence - cadence) * follow

		local on = running and os.clock() >= humAt
		level = EngineEnvelope.fade(level, on, dt, profile.fadeIn, profile.fadeOut)
		if level > 0 then
			if not hum.IsPlaying then
				startLoop(hum, profile.hum)
			end
			local pitch, volume = EngineEnvelope.loop(profile.hum, speed, 1)
			hum.PlaybackSpeed = pitch
			hum.Volume = volume * level
		elseif hum.IsPlaying then
			hum:Stop()
		end

		if cadence > 0.01 then
			if not servo.IsPlaying then
				startLoop(servo, profile.servo)
			end
			local pitch, volume = EngineEnvelope.loop(profile.servo, cadence, 1)
			servo.PlaybackSpeed = pitch
			servo.Volume = volume
		elseif servo.IsPlaying then
			servo:Stop()
		end
	end

	return {
		update = update,
		destroy = function()
			footfall:Disconnect()
			hum:Destroy()
			servo:Destroy()
		end,
	}
end

local function makeHandler(model: Model): Handler?
	local id = model:GetAttribute(Names.Attributes.VehicleId)
	if typeof(id) ~= "string" then
		return nil
	end
	local walker = SoundCatalog.MECHS[id]
	if walker then
		return mechHandler(model, walker)
	end
	local profile = SoundCatalog.VEHICLES[id]
	return if profile then engineHandler(model, profile) else nil
end

local active: { [Model]: Handler } = {}

local function drop(model: Model)
	local handler = active[model]
	if handler then
		active[model] = nil
		handler.destroy()
	end
end

-- Keeps sounds on the nearest vehicles within range: start within buildRange, stop beyond
-- dropRange, at most maxActive.
local function choose(folder: Instance)
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local eye = camera.CFrame.Position
	local candidates: { NearestSet.Candidate<Model> } = {}
	for _, child in folder:GetChildren() do
		local skid = child:IsA("Model") and child.PrimaryPart
		if skid then
			table.insert(
				candidates,
				{ item = child :: Model, distance = (skid.Position - eye).Magnitude }
			)
		end
	end
	local keep = NearestSet.choose(
		candidates,
		active,
		SETTINGS.buildRange,
		SETTINGS.dropRange,
		SETTINGS.maxActive
	)
	for model in active do
		if not keep[model] then
			drop(model)
		end
	end
	for model in keep do
		if not active[model] then
			local handler = makeHandler(model)
			if handler then
				active[model] = handler
			end
		end
	end
end

function VehicleSounds.start()
	local folder = workspace:WaitForChild(Names.Instances.Vehicles)
	folder.ChildRemoved:Connect(function(child)
		drop(child :: Model)
	end)
	local sinceSelect = math.huge
	RunService.Heartbeat:Connect(function(dt)
		sinceSelect += dt
		if sinceSelect >= SELECT_INTERVAL then
			sinceSelect = 0
			choose(folder)
		end
		for model, handler in active do
			if model.Parent ~= folder or not model.PrimaryPart then
				drop(model)
			else
				handler.update(dt)
			end
		end
	end)
end

return VehicleSounds
