-- Engine sounds for vehicles near the camera, made and driven on this client only (client sounds
-- do not replicate, so per-frame pitch and volume cost no network). While a vehicle's driver
-- seat is occupied its engine runs: a start one-shot, then loops whose pitch and volume follow
-- speed / TopSpeed. Profiles live in SoundCatalog.VEHICLES; a vehicle id can instead get its own
-- handler in HANDLERS (the Titan Mech: SoundCatalog.MECH).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local MechGait = require(ReplicatedStorage.Shared.MechGait)
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

local function lerp(range: { number }, t: number): number
	return range[1] + (range[2] - range[1]) * t
end

-- Starts a loop at a random point in its file, so matching vehicles do not phase.
local function startLoop(sound: Sound, loop: SoundCatalog.Loop)
	local length = SoundCatalog.PALETTE[loop.key].duration
	sound.TimePosition = random:NextNumber(0, length * SETTINGS.loopStartSpread)
	sound:Play()
end

local function engineHandler(model: Model, profile: SoundCatalog.VehicleSounds): Handler?
	local skid = model.PrimaryPart
	local seat = model:FindFirstChild("DriverSeat")
	if
		not skid
		or not seat
		or not seat:IsA("VehicleSeat")
		or not seat:GetAttribute("MayhemCar")
	then
		return nil
	end
	local driverSeat = seat :: VehicleSeat
	local topSpeed = (driverSeat:GetAttribute("TopSpeed") :: number?) or driverSeat.MaxSpeed

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

		local follow = 1 - math.exp(-dt * SETTINGS.smoothing)
		local velocity = skid.AssemblyLinearVelocity
		local speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
		local target = math.clamp(speed / topSpeed, 0, 1)
		local previous = smoothed
		smoothed += (target - smoothed) * follow
		bump += ((if smoothed > previous then SETTINGS.loadBump else 0) - bump) * follow

		if not playing then
			return
		end
		if running then
			level = math.min(1, level + dt / SETTINGS.fadeIn)
		else
			level = math.max(0, level - dt / SETTINGS.fadeOut)
		end
		if level <= 0 then
			playing = false
			for _, voice in voices do
				voice.sound:Stop()
			end
			return
		end
		for _, voice in voices do
			local loop = voice.loop
			local shaped = smoothed ^ (loop.curve or SETTINGS.pitchCurve)
			voice.sound.PlaybackSpeed = lerp(loop.pitch, shaped)
				+ (if voice.isEngine then bump else 0)
			voice.sound.Volume = lerp(loop.volume, smoothed) * level
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

-- The Titan Mech. MechMotion animates the legs on this client; the servo follows its cadence and
-- each heel strike it fires plays a step in that foot. The hatch opens and closes with the
-- driver seat's occupant (MechGait animates it from the same signal).
local function mechHandler(model: Model): Handler?
	local skid = model.PrimaryPart
	local seat = model:FindFirstChild("DriverSeat")
	if not skid or not seat or not seat:IsA("VehicleSeat") then
		return nil
	end
	local driverSeat = seat :: VehicleSeat
	local profile = SoundCatalog.MECH

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
			Sounds.playOn(profile.step, part("Bone_foot_" .. foot), GROUP, strength)
		end
	end)

	local function update(dt: number)
		local seated = driverSeat.Occupant ~= nil
		if seated and not running then
			running = true
			humAt = os.clock() + profile.humDelay
			Sounds.playOn(profile.powerUp, skid, GROUP)
			Sounds.playOn(profile.hatchClose, part("Bone_hatch"), GROUP)
		elseif not seated and running then
			running = false
			Sounds.playOn(profile.hatchOpen, part("Bone_hatch"), GROUP)
		end

		local gait = MechMotion.gait(model)
		local targetSpeed, targetCadence = 0, 0
		if gait then
			targetSpeed = math.clamp(gait.ground / gait.topSpeed, 0, 1)
			targetCadence = math.clamp(gait.rate * MechGait.CYCLE / gait.topSpeed, 0, 1)
		end
		local follow = 1 - math.exp(-dt * profile.smoothing)
		speed += (targetSpeed - speed) * follow
		cadence += (targetCadence - cadence) * follow

		if running and os.clock() >= humAt then
			level = math.min(1, level + dt / profile.fadeIn)
		else
			level = math.max(0, level - dt / profile.fadeOut)
		end
		if level > 0 then
			if not hum.IsPlaying then
				startLoop(hum, profile.hum)
			end
			hum.PlaybackSpeed = lerp(profile.hum.pitch, speed ^ (profile.hum.curve or 1))
			hum.Volume = lerp(profile.hum.volume, speed) * level
		elseif hum.IsPlaying then
			hum:Stop()
		end

		if cadence > 0.01 then
			if not servo.IsPlaying then
				startLoop(servo, profile.servo)
			end
			servo.PlaybackSpeed = lerp(profile.servo.pitch, cadence ^ (profile.servo.curve or 1))
			servo.Volume = lerp(profile.servo.volume, cadence)
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

-- Vehicle ids with their own sounds instead of an engine profile.
local HANDLERS: { [string]: (Model) -> Handler? } = {
	mech = mechHandler,
}

local function makeHandler(model: Model): Handler?
	local id = model:GetAttribute("VehicleId")
	if typeof(id) ~= "string" then
		return nil
	end
	local custom = HANDLERS[id]
	if custom then
		return custom(model)
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
	local candidates: { { model: Model, distance: number } } = {}
	for _, child in folder:GetChildren() do
		local skid = child:IsA("Model") and child.PrimaryPart
		if skid then
			local distance = (skid.Position - eye).Magnitude
			local limit = if active[child :: Model] then SETTINGS.dropRange else SETTINGS.buildRange
			if distance <= limit then
				table.insert(candidates, { model = child :: Model, distance = distance })
			end
		end
	end
	table.sort(candidates, function(a, b)
		return a.distance < b.distance
	end)
	local keep: { [Model]: boolean } = {}
	for index = 1, math.min(#candidates, SETTINGS.maxActive) do
		keep[candidates[index].model] = true
	end
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
	local folder = workspace:WaitForChild("Vehicles")
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
