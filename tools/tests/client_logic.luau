-- Checks the pure client logic in src/shared (Loadout, PodButtons, PromptRules, HealthBar,
-- DriveAxes, EngineEnvelope, NearestSet, ScopeMath, FootfallShake, NukeMath, ConfirmTap) outside
-- Roblox.
-- Usage: lune run tools/tests/client_logic.luau
--
--   - golden tables, generated once from the code at a50e99c, pin the functions whose inline
--     code was a line-for-line copy of the module: Loadout.speedLabel, subtitle and statText,
--     PromptRules.inputType, HealthBar.colorFor, DriveAxes.lift and EngineEnvelope.lerp (the
--     last three bit for bit). Inputs sit on each threshold and one ulp either side, with -0, NaN
--     and inf. Every catalog weapon's statText shows its damage number (or nothing)
--   - every other function gives the same bits (signed zeros and NaNs included; vectors, colours
--     and UDim2s component by component) as the inline code it replaced in src/client, copied
--     below word for word as the reference from f584174 (stand-ins for the instances and services
--     it read), composed the way each client module now calls it
--   - inputs: every catalog weapon, every pod state, prompt name, key code and input type, health
--     and speed values across and outside their ranges, zero, -0, NaN and inf where a number
--     comes from outside, viewports from 0 to 4K
--   - the state machines (LobbyUI's loadout, CarInput's resend rule, VehicleSounds' envelopes and
--     nearest set, MechCamera's shake list, MacPanel's two taps) driven through the same event
--     sequences on the reference and on the module

local luau = require("@lune/luau")
local roblox = require("@lune/roblox")

local Check = require("../lib/Check")
local Sandbox = require("../lib/Sandbox")

local check, equal = Check.check, Check.equal
local Vector3, Vector2, Color3, UDim2, Enum =
	roblox.Vector3, roblox.Vector2, roblox.Color3, roblox.UDim2, roblox.Enum

Check.printLimit = 10

local Shared = Sandbox.game:GetService("ReplicatedStorage").Shared
local FootfallShake = Sandbox.require(Shared.FootfallShake)
local Config = Sandbox.require(Shared.Config)
local ConfirmTap = Sandbox.require(Shared.ConfirmTap)
local DriveAxes = Sandbox.require(Shared.DriveAxes)
local EngineEnvelope = Sandbox.require(Shared.EngineEnvelope)
local HealthBar = Sandbox.require(Shared.HealthBar)
local Loadout = Sandbox.require(Shared.Loadout)
local MathUtil = Sandbox.require(Shared.MathUtil)
local Names = Sandbox.require(Shared.Names)
local NearestSet = Sandbox.require(Shared.NearestSet)
local NukeMath = Sandbox.require(Shared.NukeMath)
local PodButtons = Sandbox.require(Shared.PodButtons)
local PodState = Sandbox.require(Shared.PodState)
local PromptRules = Sandbox.require(Shared.PromptRules)
local RemoteActions = Sandbox.require(Shared.RemoteActions)
local ScopeMath = Sandbox.require(Shared.ScopeMath)
local WeaponCatalog = Sandbox.require(Shared.WeaponCatalog)

local environment = {
	Vector3 = Vector3,
	Vector2 = Vector2,
	Color3 = Color3,
	UDim2 = UDim2,
	Enum = Enum,
	FootfallShake = FootfallShake,
	Config = Config,
	ConfirmTap = ConfirmTap,
	DriveAxes = DriveAxes,
	EngineEnvelope = EngineEnvelope,
	HealthBar = HealthBar,
	Loadout = Loadout,
	MathUtil = MathUtil,
	Names = Names,
	NearestSet = NearestSet,
	NukeMath = NukeMath,
	PodButtons = PodButtons,
	PodState = PodState,
	PromptRules = PromptRules,
	RemoteActions = RemoteActions,
	ScopeMath = ScopeMath,
	WeaponCatalog = WeaponCatalog,
}

-- The inline code the modules replaced, from src/client at f584174, word for word inside
-- functions that take its free variables (instances, services, upvalues) as arguments. Compiled
-- with luau.load, as Sandbox.load compiles the modules (Lune's main chunk computes `%` with
-- different low bits).
local Reference = luau.load(
	[[
local Reference = {}
local rgb = Color3.fromRGB

-- LobbyUI.luau ---------------------------------------------------------------------------------

-- `refresh` up to the counter, and each card's availability. `selected` changes in place.
function Reference.refresh(player, selected)
	local function isAvailable(weapon: WeaponCatalog.Weapon): boolean
		return not weapon.adminOnly or player:GetAttribute(Names.Attributes.IsAdmin) == true
	end
	local available = 0
	for _, weapon in WeaponCatalog.ALL do
		if isAvailable(weapon) then
			available += 1
		end
	end
	for index = #selected, 1, -1 do
		local weapon = WeaponCatalog.get(selected[index])
		if not weapon or not isAvailable(weapon) then
			table.remove(selected, index)
		end
	end
	local visible = {}
	for _, weapon in WeaponCatalog.ALL do
		visible[weapon.id] = isAvailable(weapon)
	end
	return available, visible
end

-- `toggle` before its refresh; `announce` stands in for the Announcer.show call.
function Reference.toggle(selected, id, announce)
	local index = table.find(selected, id)
	if index then
		table.remove(selected, index)
	elseif #selected < Config.LOADOUT_SIZE then
		table.insert(selected, id)
	else
		announce()
	end
end

-- PodControls.luau -----------------------------------------------------------------------------

-- `refresh`, with what it sets returned.
function Reference.pod(model, passenger, touchEnabled)
	local function state(): PodState.State
		return if model
			then PodState.of(model:GetAttribute(Names.Attributes.PodState))
			else PodState.DOCKED
	end
	local out = { cleared = false }
	local current = state()
	out.enabled = model ~= nil and not passenger
	out.text = if PodState.isAtRest(current)
		then "LAUNCH"
		elseif current == PodState.FLYING then "RETURN HOME"
		else "RETURNING"
	out.active = current ~= PodState.RETURNING
	out.autoButtonColor = current ~= PodState.RETURNING
	out.color = if PodState.isAtRest(current)
		then rgb(0, 120, 170)
		elseif current == PodState.FLYING then rgb(150, 90, 0)
		else rgb(60, 60, 70)
	local flying = model ~= nil and current == PodState.FLYING
	out.land = flying
		and (model :: Model):GetAttribute(Names.Attributes.PodCanLand) == true
	out.up = flying and touchEnabled
	out.down = flying and touchEnabled
	if not flying then
		out.cleared = true
	end
	out.lockJump = model ~= nil and PodState.inFlight(current)
	return out
end

-- The pod button's Activated handler: the command it fires, or nil.
function Reference.podCommand(model)
	local current = if model
		then PodState.of(model:GetAttribute(Names.Attributes.PodState))
		else PodState.DOCKED
	if PodState.isAtRest(current) then
		return RemoteActions.PodCommand.LAUNCH
	elseif current == PodState.FLYING then
		return RemoteActions.PodCommand.HOME
	end
	return nil
end

-- PromptPanel.luau -----------------------------------------------------------------------------

function Reference.useful(prompt, sitting, own, vehicleOf)
	local vehicle = vehicleOf(prompt)
	if not vehicle then
		return true
	end
	if vehicle ~= own then
		return false
	end
	if prompt.Name == Names.Instances.PodPrompt then
		return sitting.Name == Names.Instances.DriverSeat
	end
	if prompt.Name == Names.Instances.DrivePrompt then
		return sitting:IsA("Seat") -- a passenger seat; driver seats are VehicleSeats
	end
	return false
end

function Reference.keyText(prompt, inputType: Enum.ProximityPromptInputType): string
	if inputType == Enum.ProximityPromptInputType.Touch then
		return "TAP"
	end
	local code = if inputType == Enum.ProximityPromptInputType.Gamepad
		then prompt.GamepadKeyCode
		else prompt.KeyboardKeyCode
	if code.Value == 0 then -- no key (KeyCode Unknown)
		return ""
	end
	return (string.gsub(code.Name, "^Button", ""))
end

-- `layout`'s sort comparator, on cards.
function Reference.before(a, b)
	local ka, kb = a.prompt.KeyboardKeyCode.Value, b.prompt.KeyboardKeyCode.Value
	return if ka ~= kb then ka < kb else a.prompt:GetFullName() < b.prompt:GetFullName()
end

-- VehicleHealth.luau ---------------------------------------------------------------------------

-- `refresh`: the fill's scale, colour and the label; `model` a stand-in. The label is nil when
-- string.format fails (the same call fails in both). The colour comes from HealthBar.colorFor,
-- pinned by its golden table below.
function Reference.health(model)
	local health = (model:GetAttribute(Names.Attributes.Health) :: number?) or 0
	local maxHealth = math.max((model:GetAttribute(Names.Attributes.MaxHealth) :: number?) or 1, 1)
	local share = math.clamp(health / maxHealth, 0, 1)
	local ok, text = pcall(function()
		return string.format("%s  %d / %d", model.Name, math.ceil(health), maxHealth)
	end)
	return share, HealthBar.colorFor(share), if ok then text else nil, health
end

-- CarInput.luau --------------------------------------------------------------------------------

-- `readInput` after the text box check; `keyAxis` and `getControls` passed in.
function Reference.readInput(seat, keyAxis, getControls, K)
	local throttle = keyAxis({ K.W, K.Up }, { K.S, K.Down })
	local steer = keyAxis({ K.D, K.Right }, { K.A, K.Left })
	if throttle == 0 and steer == 0 then
		throttle, steer = seat.ThrottleFloat, seat.SteerFloat
	end
	local current = if throttle == 0 and steer == 0 then getControls() else nil
	if current then
		local ok, move = pcall(current.GetMoveVector, current)
		if ok and typeof(move) == "Vector3" then
			throttle, steer = -move.Z, move.X
		end
	end
	return math.clamp(throttle, -1, 1), math.clamp(steer, -1, 1)
end

-- `start`'s Heartbeat: one call per frame; `frame` gives what the frame reads. Returns the
-- arguments it fires DriveInput with, or nil.
function Reference.newSender()
	local RESEND_INTERVAL = 0.25
	local lastThrottle, lastSteer, lastLift, lastSent = 0, 0, 0, 0
	local driving = false
	return function(frame)
		local seat = frame.seat
		if not seat then
			driving = false
			return nil
		end
		local throttle, steer = frame.throttle, frame.steer
		local lift = frame.lift
		local now = frame.now
		local changed = math.abs(throttle - lastThrottle) > 0.05
			or math.abs(steer - lastSteer) > 0.05
			or lift ~= lastLift
		if not driving or changed or now - lastSent > RESEND_INTERVAL then
			driving = true
			lastThrottle, lastSteer, lastLift, lastSent = throttle, steer, lift, now
			return { throttle, steer, lift }
		end
		return nil
	end
end

-- VehicleSounds.luau ---------------------------------------------------------------------------

-- The inline `lerp` was EngineEnvelope.lerp word for word; the golden table pins it.
local lerp = EngineEnvelope.lerp

-- engineHandler's `update` after the start logic: `s` holds running, playing, level, smoothed,
-- bump; `follow` is the rateAlpha. Returns each voice's PlaybackSpeed and Volume, or "stop".
function Reference.engineFrame(s, SETTINGS, voices, dt, follow, target)
	local previous = s.smoothed
	s.smoothed += (target - s.smoothed) * follow
	s.bump += ((if s.smoothed > previous then SETTINGS.loadBump else 0) - s.bump) * follow

	if not s.playing then
		return nil
	end
	if s.running then
		s.level = math.min(1, s.level + dt / SETTINGS.fadeIn)
	else
		s.level = math.max(0, s.level - dt / SETTINGS.fadeOut)
	end
	if s.level <= 0 then
		s.playing = false
		return "stop"
	end
	local out = {}
	for _, voice in voices do
		local loop = voice.loop
		local shaped = s.smoothed ^ (loop.curve or SETTINGS.pitchCurve)
		local speed = lerp(loop.pitch, shaped) + (if voice.isEngine then s.bump else 0)
		local volume = lerp(loop.volume, s.smoothed) * s.level
		table.insert(out, { speed, volume })
	end
	return out
end

-- mechHandler's `update` after the start logic; `gait` a MechMotion.gait stand-in or nil, `cycle0`
-- MechGait.CYCLE, `humOn` the result of `os.clock() >= humAt`.
function Reference.mechFrame(s, profile, gait, cycle0, dt, follow, humOn)
	local targetSpeed, targetCadence = 0, 0
	if gait then
		targetSpeed = math.clamp(gait.ground / gait.topSpeed, 0, 1)
		local cycle = cycle0 * gait.rig.scale
		targetCadence = math.clamp(gait.rate * cycle / gait.topSpeed, 0, 1)
	end
	s.speed += (targetSpeed - s.speed) * follow
	s.cadence += (targetCadence - s.cadence) * follow

	if s.running and humOn then
		s.level = math.min(1, s.level + dt / profile.fadeIn)
	else
		s.level = math.max(0, s.level - dt / profile.fadeOut)
	end
	local out = {}
	if s.level > 0 then
		out.humSpeed = lerp(profile.hum.pitch, s.speed ^ (profile.hum.curve or 1))
		out.humVolume = lerp(profile.hum.volume, s.speed) * s.level
	end
	if s.cadence > 0.01 then
		out.servoSpeed = lerp(profile.servo.pitch, s.cadence ^ (profile.servo.curve or 1))
		out.servoVolume = lerp(profile.servo.volume, s.cadence)
	end
	return out
end

-- `choose`: `children` stand-ins (IsA, PrimaryPart), `active` the handler map.
function Reference.choose(children, active, eye, SETTINGS)
	local candidates: { { model: Model, distance: number } } = {}
	for _, child in children do
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
	return keep
end

-- SniperScope.luau -----------------------------------------------------------------------------

local MAX_PITCH = math.rad(80)
local VIEW_FRACTION = 0.9

function Reference.overlay(viewport)
	local out = {}
	local diameter = math.floor(math.min(viewport.X, viewport.Y) * VIEW_FRACTION)
	local x0 = math.floor((viewport.X - diameter) / 2)
	local y0 = math.floor((viewport.Y - diameter) / 2)
	out.lensSize = UDim2.fromOffset(diameter, diameter)
	-- A square's corner sits radius * (sqrt(2) - 1) outside its inscribed circle.
	out.stroke = math.ceil(diameter / 2 * (math.sqrt(2) - 1)) + 2
	out.topPosition = UDim2.fromOffset(0, 0)
	out.topSize = UDim2.new(1, 0, 0, y0)
	out.bottomPosition = UDim2.fromOffset(0, y0 + diameter)
	out.bottomSize = UDim2.new(1, 0, 1, -(y0 + diameter))
	out.leftPosition = UDim2.fromOffset(0, y0)
	out.leftSize = UDim2.fromOffset(x0, diameter)
	out.rightPosition = UDim2.fromOffset(x0 + diameter, y0)
	out.rightSize = UDim2.new(1, -(x0 + diameter), 0, diameter)
	return out
end

function Reference.turn(current, yawDegrees: number, pitchDegrees: number)
	current.targetYaw -= math.rad(yawDegrees)
	current.targetPitch =
		math.clamp(current.targetPitch - math.rad(pitchDegrees), -MAX_PITCH, MAX_PITCH)
end

function Reference.pitchOf(look)
	local pitch = math.clamp(math.asin(math.clamp(look.Y, -1, 1)), -MAX_PITCH, MAX_PITCH)
	return pitch
end

-- MechCamera.luau ------------------------------------------------------------------------------

local SHAKE_LIFT = 0.12 -- studs at strength 1
local SHAKE_PITCH = math.rad(0.35)
local SHAKE_DECAY = 0.12 -- seconds
local SHAKE_FREQUENCY = 9 -- Hz
local SHAKE_LENGTH = 0.4 -- seconds

-- `shake` up to the scale.
function Reference.shake(shakes, now)
	local lift, pitch = 0, 0
	for index = #shakes, 1, -1 do
		local each = shakes[index]
		local t = now - each.start
		if t > SHAKE_LENGTH then
			table.remove(shakes, index)
		else
			local wave = each.strength
				* math.exp(-t / SHAKE_DECAY)
				* math.sin(2 * math.pi * SHAKE_FREQUENCY * t)
			lift += SHAKE_LIFT * wave
			pitch += SHAKE_PITCH * wave
		end
	end
	return lift, pitch
end

-- NukeStrike.luau ------------------------------------------------------------------------------

local BOMB_BOTTOM = 34 -- studs from the body's center down to the tip of the nose
local DROP_HEIGHT = 1400 -- studs above the ground at release
local DROP_SPIN = math.rad(200) -- turn about its axis over the whole fall
local WAVE_SEGMENTS = 72
local WAVE_HEIGHT = { 45, 10 } -- studs, at impact and at the edge of the board
local WAVE_HOT = rgb(255, 245, 210)
local WAVE_COOL = rgb(255, 120, 40)
local SHAKE_SECONDS = 3.5
local SHAKE_ANGLE = math.rad(1.2) -- at strength 1
local SHAKE_REACH = 1500 -- studs from impact where the shake bottoms out at 0.3

-- `fall`'s frame at progress t: height and the spin angle.
function Reference.bomb(t)
	local height = BOMB_BOTTOM + DROP_HEIGHT * (1 - t * t)
	return height, t * DROP_SPIN
end

-- `wave`'s frame at `elapsed`, and every segment's angle.
function Reference.wave(elapsed)
	local t = elapsed / Config.NUKE_WAVE_SECONDS
	local radius = math.max(Config.nukeWaveRadius(elapsed), 4)
	local height = WAVE_HEIGHT[1] + (WAVE_HEIGHT[2] - WAVE_HEIGHT[1]) * t
	local size = Vector3.new(2 * math.pi * radius / WAVE_SEGMENTS * 1.15, height, 6)
	local color = WAVE_HOT:Lerp(WAVE_COOL, math.min(t * 2, 1))
	local transparency = 0.1 + 0.85 * t
	local angles = {}
	for index = 1, WAVE_SEGMENTS do
		local angle = index / WAVE_SEGMENTS * 2 * math.pi
		angles[index] = angle
	end
	return {
		radius = radius,
		height = height,
		size = size,
		color = color,
		transparency = transparency,
	},
		angles
end

function Reference.nukeShake(distance, t)
	local strength = math.clamp(1 - 0.7 * distance / SHAKE_REACH, 0.3, 1)
	local angle = SHAKE_ANGLE * strength * (1 - t) ^ 2
	return strength, angle, SHAKE_SECONDS, WAVE_HOT
end

-- MacPanel.luau --------------------------------------------------------------------------------

-- The NUKE button's Activated handler with its state; `os` and `task` are stand-ins, `log`
-- records the text and the fire.
function Reference.newNuke(os, task, log, CONFIRM_SECONDS)
	local NUKE_TEXT = "☢ NUKE SERVER"
	local nuke = setmetatable({}, {
		__newindex = function(_, key, value)
			table.insert(log, key .. "=" .. value)
		end,
	})
	local armedAt: number? = nil
	return function()
		if armedAt and os.clock() - armedAt < CONFIRM_SECONDS then
			armedAt = nil
			nuke.Text = NUKE_TEXT
			table.insert(log, "FIRE")
			return
		end
		local stamp = os.clock()
		armedAt = stamp
		nuke.Text = "TAP AGAIN TO NUKE EVERYONE"
		task.delay(CONFIRM_SECONDS, function()
			if armedAt == stamp then
				armedAt = nil
				nuke.Text = NUKE_TEXT
			end
		end)
	end
end

return Reference
]],
	{ debugName = "client reference", environment = environment }
)()

-- The client modules' code now, copied the same way: the same arguments and results as Reference.
local Now = luau.load(
	[[
local Now = {}

-- LobbyUI.luau
function Now.refresh(player, selected)
	local isAdmin = player:GetAttribute(Names.Attributes.IsAdmin) == true
	local available = Loadout.availableCount(isAdmin)
	Loadout.prune(selected, isAdmin)
	local visible = {}
	for _, weapon in WeaponCatalog.ALL do
		visible[weapon.id] = Loadout.isAvailable(weapon, isAdmin)
	end
	return available, visible
end
function Now.toggle(selected, id, announce)
	if Loadout.toggle(selected, id) == "full" then
		announce()
	end
end

-- PodControls.luau
function Now.pod(model, passenger, touchEnabled)
	local function state(): PodState.State
		return if model
			then PodState.of(model:GetAttribute(Names.Attributes.PodState))
			else PodState.DOCKED
	end
	local out = { cleared = false }
	local view = PodButtons.view(
		state(),
		model ~= nil,
		model ~= nil and model:GetAttribute(Names.Attributes.PodCanLand) == true,
		touchEnabled
	)
	out.enabled = model ~= nil and not passenger
	out.text = view.text
	out.active = view.active
	out.autoButtonColor = view.active
	out.color = view.color
	out.land = view.landVisible
	out.up = view.liftVisible
	out.down = view.liftVisible
	if not view.flying then
		out.cleared = true
	end
	out.lockJump = view.lockJump
	return out
end
function Now.podCommand(model)
	local current = if model
		then PodState.of(model:GetAttribute(Names.Attributes.PodState))
		else PodState.DOCKED
	return PodButtons.command(current)
end

-- PromptPanel.luau
function Now.useful(prompt, sitting, own, vehicleOf)
	local vehicle = vehicleOf(prompt)
	local where: PromptRules.Where = if not vehicle
		then "none"
		elseif vehicle == own then "own"
		else "other"
	return PromptRules.useful(where, prompt.Name, sitting.Name, sitting:IsA("Seat"))
end
function Now.keyText(prompt, inputType)
	return PromptRules.keyText(inputType, prompt.GamepadKeyCode, prompt.KeyboardKeyCode)
end
function Now.before(a, b)
	return PromptRules.before(a.prompt, b.prompt)
end

-- VehicleHealth.luau
function Now.health(model)
	local health, maxHealth, share = HealthBar.read(
		model:GetAttribute(Names.Attributes.Health) :: number?,
		model:GetAttribute(Names.Attributes.MaxHealth) :: number?
	)
	local textOk, text = pcall(HealthBar.labelText, model.Name, health, maxHealth)
	return share, HealthBar.colorFor(share), if textOk then text else nil, health
end

-- CarInput.luau
function Now.readInput(seat, keyAxis, getControls, K)
	local throttle, steer = DriveAxes.keysOrSeat(
		keyAxis({ K.W, K.Up }, { K.S, K.Down }),
		keyAxis({ K.D, K.Right }, { K.A, K.Left }),
		seat.ThrottleFloat,
		seat.SteerFloat
	)
	local current = if throttle == 0 and steer == 0 then getControls() else nil
	if current then
		local ok, move = pcall(current.GetMoveVector, current)
		if ok and typeof(move) == "Vector3" then
			throttle, steer = DriveAxes.fromMoveVector(move)
		end
	end
	return DriveAxes.clamp(throttle, steer)
end
function Now.newSender()
	local sent = DriveAxes.newSent()
	return function(frame)
		local seat = frame.seat
		if not seat then
			sent.driving = false
			return nil
		end
		local throttle, steer = frame.throttle, frame.steer
		local lift = frame.lift
		if DriveAxes.send(sent, throttle, steer, lift, frame.now) then
			return { throttle, steer, lift }
		end
		return nil
	end
end

-- VehicleSounds.luau
function Now.engineFrame(s, SETTINGS, voices, dt, follow, target)
	s.smoothed, s.bump =
		EngineEnvelope.follow(s.smoothed, s.bump, target, follow, SETTINGS.loadBump)

	if not s.playing then
		return nil
	end
	s.level = EngineEnvelope.fade(s.level, s.running, dt, SETTINGS.fadeIn, SETTINGS.fadeOut)
	if s.level <= 0 then
		s.playing = false
		return "stop"
	end
	local out = {}
	for _, voice in voices do
		local pitch, volume = EngineEnvelope.loop(voice.loop, s.smoothed, SETTINGS.pitchCurve)
		local speed = pitch + (if voice.isEngine then s.bump else 0)
		table.insert(out, { speed, volume * s.level })
	end
	return out
end
function Now.mechFrame(s, profile, gait, cycle0, dt, follow, humOn)
	local targetSpeed, targetCadence = 0, 0
	if gait then
		local cycle = cycle0 * gait.rig.scale
		targetSpeed, targetCadence =
			EngineEnvelope.mechTargets(gait.ground, gait.topSpeed, gait.rate, cycle)
	end
	s.speed += (targetSpeed - s.speed) * follow
	s.cadence += (targetCadence - s.cadence) * follow

	local on = s.running and humOn
	s.level = EngineEnvelope.fade(s.level, on, dt, profile.fadeIn, profile.fadeOut)
	local out = {}
	if s.level > 0 then
		local pitch, volume = EngineEnvelope.loop(profile.hum, s.speed, 1)
		out.humSpeed = pitch
		out.humVolume = volume * s.level
	end
	if s.cadence > 0.01 then
		local pitch, volume = EngineEnvelope.loop(profile.servo, s.cadence, 1)
		out.servoSpeed = pitch
		out.servoVolume = volume
	end
	return out
end
function Now.choose(children, active, eye, SETTINGS)
	local candidates = {}
	for _, child in children do
		local skid = child:IsA("Model") and child.PrimaryPart
		if skid then
			table.insert(candidates, { item = child, distance = (skid.Position - eye).Magnitude })
		end
	end
	return NearestSet.choose(
		candidates,
		active,
		SETTINGS.buildRange,
		SETTINGS.dropRange,
		SETTINGS.maxActive
	)
end

-- SniperScope.luau
function Now.overlay(viewport)
	return ScopeMath.overlay(viewport)
end
function Now.turn(current, yawDegrees, pitchDegrees)
	current.targetYaw, current.targetPitch =
		ScopeMath.turn(current.targetYaw, current.targetPitch, yawDegrees, pitchDegrees)
end
function Now.pitchOf(look)
	return ScopeMath.pitchOf(look)
end

-- MechCamera.luau
function Now.shake(shakes, now)
	return FootfallShake.sum(shakes, now)
end

-- NukeStrike.luau
function Now.bomb(t)
	return NukeMath.bomb(t)
end
function Now.wave(elapsed)
	local angles = {}
	for index = 1, NukeMath.WAVE_SEGMENTS do
		angles[index] = NukeMath.waveAngle(index)
	end
	return NukeMath.wave(elapsed), angles
end
function Now.nukeShake(distance, t)
	local strength = NukeMath.shakeStrength(distance)
	return strength, NukeMath.shakeAngle(strength, t), NukeMath.SHAKE_SECONDS, NukeMath.WAVE_HOT
end

-- MacPanel.luau
function Now.newNuke(os, task, log, CONFIRM_SECONDS)
	local NUKE_TEXT = "☢ NUKE SERVER"
	local nuke = setmetatable({}, {
		__newindex = function(_, key, value)
			table.insert(log, key .. "=" .. value)
		end,
	})
	local confirm = ConfirmTap.new()
	return function()
		local fired, stamp = ConfirmTap.tap(confirm, CONFIRM_SECONDS, os.clock)
		if fired then
			nuke.Text = NUKE_TEXT
			table.insert(log, "FIRE")
			return
		end
		nuke.Text = "TAP AGAIN TO NUKE EVERYONE"
		task.delay(CONFIRM_SECONDS, function()
			if ConfirmTap.expire(confirm, stamp) then
				nuke.Text = NUKE_TEXT
			end
		end)
	end
end

return Now
]],
	{ debugName = "client now", environment = environment }
)()

-- Comparison --------------------------------------------------------------------------------------

-- Same bits: -0 differs from 0, a NaN equals the same NaN; datatypes and tables part by part.
local function same(a: any, b: any): boolean
	local kind = typeof(a)
	if kind ~= typeof(b) then
		return false
	elseif kind == "number" then
		return string.pack("<d", a) == string.pack("<d", b)
	elseif kind == "Vector3" then
		return same(a.X, b.X) and same(a.Y, b.Y) and same(a.Z, b.Z)
	elseif kind == "Vector2" then
		return same(a.X, b.X) and same(a.Y, b.Y)
	elseif kind == "Color3" then
		return same(a.R, b.R) and same(a.G, b.G) and same(a.B, b.B)
	elseif kind == "UDim2" then
		return same(a.X.Scale, b.X.Scale)
			and same(a.X.Offset, b.X.Offset)
			and same(a.Y.Scale, b.Y.Scale)
			and same(a.Y.Offset, b.Y.Offset)
	elseif kind == "table" then
		for key, value in a do
			if not same(value, b[key]) then
				return false
			end
		end
		for key in b do
			if a[key] == nil then
				return false
			end
		end
		return true
	end
	return a == b
end

local function show(value: any): string
	if type(value) == "number" then
		return string.format("%.17g", value)
	elseif type(value) == "table" then
		local parts = {}
		for key, each in value do
			table.insert(parts, tostring(key) .. "=" .. show(each))
		end
		table.sort(parts)
		return "{" .. table.concat(parts, ", ") .. "}"
	end
	return tostring(value)
end

local function sameAs(got: any, want: any, label: string)
	check(same(got, want), string.format("%s: got %s, want %s", label, show(got), show(want)))
end

-- A golden value: the same bits as `want`, except that a NaN in `want` matches any NaN (a NaN
-- literal's sign bit is the compiler's choice).
local function matchesGolden(got: any, want: any): boolean
	if type(want) == "number" and want ~= want then
		return type(got) == "number" and got ~= got
	elseif typeof(want) == "Color3" or typeof(got) == "Color3" then
		return typeof(got) == "Color3"
			and matchesGolden(got.R, want.R)
			and matchesGolden(got.G, want.G)
			and matchesGolden(got.B, want.B)
	end
	return same(got, want)
end

local function sameAsGolden(got: any, want: any, label: string)
	check(
		matchesGolden(got, want),
		string.format("%s: got %s, want %s", label, show(got), show(want))
	)
end

-- Deterministic numbers for the random sweeps (Park-Miller).
local seed = 12345
local function nextNumber(): number
	seed = (seed * 16807) % 2147483647
	return seed / 2147483647
end
local function pick<T>(list: { T }): T
	return list[math.floor(nextNumber() * #list) + 1]
end
local function between(low: number, high: number): number
	return low + (high - low) * nextNumber()
end

local nan = 0 / 0
local inf = math.huge

-- A stand-in instance with attributes.
local function withAttributes(attributes: { [string]: any }, extra: { [string]: any }?)
	local object = extra or {}
	function object.GetAttribute(_, name: string): any
		return attributes[name]
	end
	return object
end

-- Loadout -----------------------------------------------------------------------------------------

Check.section("Loadout texts")
-- Golden outputs of Loadout.speedLabel (cooldown, label), generated once from the code at a50e99c:
-- they pin its behaviour. A deliberate change updates this table.
local SPEED_LABELS = {
	{ -inf, "rapid fire" },
	{ -1, "rapid fire" },
	{ -0, "rapid fire" },
	{ 0, "rapid fire" },
	{ 0.1, "rapid fire" },
	{ 0.14999999999999997, "rapid fire" },
	{ 0.15, "rapid fire" },
	{ 0.15000000000000002, "fast" },
	{ 0.1500001, "fast" },
	{ 0.49999999999999994, "fast" },
	{ 0.5, "fast" },
	{ 0.5000000000000001, "medium" },
	{ 0.50001, "medium" },
	{ 1.1999999999999997, "medium" },
	{ 1.2, "medium" },
	{ 1.2000000000000002, "slow" },
	{ 1.2000001, "slow" },
	{ 9, "slow" },
	{ inf, "slow" },
	{ nan, "slow" },
}
for _, case in SPEED_LABELS do
	sameAs(Loadout.speedLabel(case[1]), case[2], "speedLabel " .. show(case[1]))
end
-- Golden outputs of Loadout.subtitle (kind, cooldown, subtitle), generated once from the code at
-- a50e99c: they pin its behaviour. A deliberate change updates this table.
local SUBTITLES = {
	{ "melee", 0.3, "Melee · fast" },
	{ "hitscan", 0.3, "Gun · fast" },
	{ "projectile", 0.3, "Launcher · fast" },
	{ "strike", 0.3, "Spell · fast" },
	{ "heal", 0.3, "Support · fast" },
	{ "blink", 0.3, "Mobility · fast" },
	{ "push", 0.3, "Blast · fast" },
	{ "mystery", 0.3, "mystery · fast" },
	{ "heal", 0.15, "Support · rapid fire" },
	{ "heal", 1.2, "Support · medium" },
	{ "heal", 9, "Support · slow" },
	{ "heal", nan, "Support · slow" },
}
for _, case in SUBTITLES do
	local weapon = { id = "made-up", kind = case[1], cooldown = case[2] }
	sameAs(Loadout.subtitle(weapon), case[3], "subtitle " .. case[1] .. " " .. show(case[2]))
end
-- Golden outputs of Loadout.statText (kind, damage, pellets, text), generated once from the code at
-- a50e99c: they pin its behaviour. A deliberate change updates this table.
local STAT_TEXTS = {
	{ "heal", -5, nil, "HEAL -5" },
	{ "heal", -0, nil, "HEAL -0" },
	{ "heal", 0, nil, "HEAL 0" },
	{ "heal", 0.5, nil, "HEAL 0.5" },
	{ "heal", 1, nil, "HEAL 1" },
	{ "heal", 12, nil, "HEAL 12" },
	{ "heal", 33.25, nil, "HEAL 33.25" },
	{ "heal", 1000000000, nil, "HEAL 1000000000" },
	{ "heal", nan, nil, "HEAL nan" },
	{ "heal", inf, nil, "HEAL inf" },
	{ "heal", 12, 6, "HEAL 12" },
	{ "melee", -5, nil, "" },
	{ "melee", -5, 1, "" },
	{ "melee", -5, 6, "" },
	{ "melee", -5, 2.5, "" },
	{ "melee", -0, nil, "" },
	{ "melee", -0, 1, "" },
	{ "melee", -0, 6, "" },
	{ "melee", -0, 2.5, "" },
	{ "melee", 0, nil, "" },
	{ "melee", 0, 1, "" },
	{ "melee", 0, 6, "" },
	{ "melee", 0, 2.5, "" },
	{ "melee", 0.5, nil, "DMG 0.5" },
	{ "melee", 0.5, 1, "DMG 0.5×1" },
	{ "melee", 0.5, 6, "DMG 0.5×6" },
	{ "melee", 0.5, 2.5, "DMG 0.5×2.5" },
	{ "melee", 1, nil, "DMG 1" },
	{ "melee", 1, 1, "DMG 1×1" },
	{ "melee", 1, 6, "DMG 1×6" },
	{ "melee", 1, 2.5, "DMG 1×2.5" },
	{ "melee", 12, nil, "DMG 12" },
	{ "melee", 12, 1, "DMG 12×1" },
	{ "melee", 12, 6, "DMG 12×6" },
	{ "melee", 12, 2.5, "DMG 12×2.5" },
	{ "melee", 33.25, nil, "DMG 33.25" },
	{ "melee", 33.25, 1, "DMG 33.25×1" },
	{ "melee", 33.25, 6, "DMG 33.25×6" },
	{ "melee", 33.25, 2.5, "DMG 33.25×2.5" },
	{ "melee", 1000000000, nil, "DMG 1000000000" },
	{ "melee", 1000000000, 1, "DMG 1000000000×1" },
	{ "melee", 1000000000, 6, "DMG 1000000000×6" },
	{ "melee", 1000000000, 2.5, "DMG 1000000000×2.5" },
	{ "melee", nan, nil, "" },
	{ "melee", nan, 1, "" },
	{ "melee", nan, 6, "" },
	{ "melee", nan, 2.5, "" },
	{ "melee", inf, nil, "DMG inf" },
	{ "melee", inf, 1, "DMG inf×1" },
	{ "melee", inf, 6, "DMG inf×6" },
	{ "melee", inf, 2.5, "DMG inf×2.5" },
	{ "mystery", -5, nil, "" },
	{ "mystery", 0, nil, "" },
	{ "mystery", 12, nil, "DMG 12" },
}
for _, case in STAT_TEXTS do
	local weapon = { id = "made-up", kind = case[1], damage = case[2], pellets = case[3] }
	sameAs(
		Loadout.statText(weapon),
		case[4],
		string.format("statText %s dmg %s pellets %s", case[1], show(case[2]), show(case[3]))
	)
end
-- Every catalog weapon gets a card subtitle of the golden shape (values follow the catalog).
for _, weapon in WeaponCatalog.ALL do
	local subtitle = Loadout.subtitle(weapon)
	local speed = string.match(subtitle, "^.+ · (.+)$")
	check(
		speed == "rapid fire" or speed == "fast" or speed == "medium" or speed == "slow",
		"subtitle " .. weapon.id .. ": " .. subtitle
	)
	-- A weapon that heals or deals damage shows its number; one that does neither shows nothing.
	local text = Loadout.statText(weapon)
	if weapon.kind == "heal" or weapon.damage > 0 then
		check(
			text ~= "" and string.find(text, tostring(weapon.damage), 1, true) ~= nil,
			"statText " .. weapon.id .. ": " .. text
		)
	else
		equal(text, "", "statText " .. weapon.id)
	end
end

Check.section("Loadout refresh and toggle")
local adminOnly = 0
for _, weapon in WeaponCatalog.ALL do
	if weapon.adminOnly then
		adminOnly += 1
	end
end
check(adminOnly > 0, "the catalog has an admin-only weapon (the sweep needs one)")
local ids = { "nope", "" }
for _, weapon in WeaponCatalog.ALL do
	table.insert(ids, weapon.id)
end
local adminValues = { nil, true, false, 1, "true" }
for round = 1, 3000 do
	local attributes = { [Names.Attributes.IsAdmin] = adminValues[round % 5 + 1] }
	local player = withAttributes(attributes)
	-- A loadout as the client may hold it: valid, too long, repeated or unknown ids.
	local selected = {}
	for _ = 1, math.floor(nextNumber() * 6) do
		table.insert(selected, pick(ids))
	end
	local want, got = table.clone(selected), table.clone(selected)
	local wantCount, wantVisible = Reference.refresh(player, want)
	local gotCount, gotVisible = Now.refresh(player, got)
	local label = "refresh "
		.. table.concat(selected, ",")
		.. " admin "
		.. tostring(attributes[Names.Attributes.IsAdmin])
	sameAs(gotCount, wantCount, label .. " count")
	sameAs(gotVisible, wantVisible, label .. " visible")
	sameAs(got, want, label .. " selected")
	-- Taps on cards, with refreshes between, from that loadout.
	local wantAnnounced, gotAnnounced = 0, 0
	for _ = 1, 8 do
		local id = pick(ids)
		Reference.toggle(want, id, function()
			wantAnnounced += 1
		end)
		Now.toggle(got, id, function()
			gotAnnounced += 1
		end)
		sameAs(got, want, label .. " toggle " .. id)
		Reference.refresh(player, want)
		Now.refresh(player, got)
	end
	equal(gotAnnounced, wantAnnounced, label .. " announcements")
end

-- PodButtons --------------------------------------------------------------------------------------

Check.section("PodButtons")
local podStates = { nil, "docked", "flying", "returning", "landed", "wrecked" }
local canLandValues = { nil, true, false, 1, "true" }
local podCases = 0
for stateIndex = 1, 6 do
	for landIndex = 1, 5 do
		for _, hasModel in { true, false } do
			for _, passenger in { true, false } do
				for _, touch in { true, false } do
					local model = if hasModel
						then withAttributes({
							[Names.Attributes.PodState] = podStates[stateIndex],
							[Names.Attributes.PodCanLand] = canLandValues[landIndex],
						})
						else nil
					local label = string.format(
						"pod %s land %s model %s passenger %s touch %s",
						tostring(podStates[stateIndex]),
						tostring(canLandValues[landIndex]),
						tostring(hasModel),
						tostring(passenger),
						tostring(touch)
					)
					sameAs(
						Now.pod(model, passenger, touch),
						Reference.pod(model, passenger, touch),
						label
					)
					sameAs(Now.podCommand(model), Reference.podCommand(model), label .. " command")
					podCases += 1
				end
			end
		end
	end
end
equal(podCases, 240, "pod cases")

-- DRONE (added after the reference): shown to the pilot in flight only; ON only while the
-- LegsDrone attribute is true there. Golden rules over every state, aboard, canLand, touch, drone.
Check.section("PodButtons drone")
local droneCases = 0
for _, state in { "docked", "flying", "returning", "landed", "wrecked" } do
	for _, aboard in { true, false } do
		for _, canLand in { true, false } do
			for _, touch in { true, false } do
				for droneIndex = 1, 3 do
					local drone = ({ true, false, nil } :: { boolean? })[droneIndex]
					local view = PodButtons.view(state :: any, aboard, canLand, touch, drone)
					local label = string.format(
						"%s aboard %s land %s touch %s drone %s",
						state,
						tostring(aboard),
						tostring(canLand),
						tostring(touch),
						tostring(drone)
					)
					local flying = aboard and state == "flying"
					local on = flying and drone == true
					equal(view.droneVisible, flying, label .. " visible")
					equal(
						view.droneText,
						if on then "DRONE\nON" else "DRONE\nOFF",
						label .. " text"
					)
					equal(
						view.droneColor,
						if on then PodButtons.DRONE_ON_COLOR else PodButtons.DRONE_OFF_COLOR,
						label .. " colour"
					)
					droneCases += 1
				end
			end
		end
	end
end
equal(droneCases, 120, "drone cases")
equal(PodButtons.DRONE_OFF_COLOR, Color3.fromRGB(20, 20, 28), "DRONE OFF is the HUD colour")

-- PromptRules -------------------------------------------------------------------------------------

Check.section("PromptRules useful")
local promptNames = { "Other", "" }
for _, name in Names.Instances do
	table.insert(promptNames, name)
end
local seatNames = { Names.Instances.DriverSeat, "Seat", "PassengerSeat", "" }
local ownVehicle, otherVehicle = { name = "own" }, { name = "other" }
for _, promptName in promptNames do
	for _, seatName in seatNames do
		for _, isSeat in { true, false } do
			for _, vehicle in { false, ownVehicle, otherVehicle } do
				local prompt = { Name = promptName, vehicle = vehicle or nil }
				local sitting = {
					Name = seatName,
					IsA = function(_, className: string): boolean
						return className == "Seat" and isSeat
					end,
				}
				local function vehicleOf(each)
					return each.vehicle
				end
				sameAs(
					Now.useful(prompt, sitting, ownVehicle, vehicleOf),
					Reference.useful(prompt, sitting, ownVehicle, vehicleOf),
					string.format(
						"useful %s in %s (Seat %s) on %s",
						promptName,
						seatName,
						tostring(isSeat),
						if vehicle then vehicle.name else "none"
					)
				)
			end
		end
	end
end

-- Golden: only the pod console's prompt in a driver seat goes without a card.
for _, promptName in promptNames do
	for _, seatName in { Names.Instances.DriverSeat, "Seat", "" } do
		for _, seated in { true, false } do
			local want = not (seated and promptName == "PodPrompt" and seatName == "DriverSeat")
			equal(
				PromptRules.drawn(promptName, if seated then seatName else nil),
				want,
				string.format("drawn %s in %s (%s)", promptName, seatName, tostring(seated))
			)
		end
	end
end

Check.section("PromptRules keys and order")
local keyCodes = Enum.KeyCode:GetEnumItems()
local promptTypes = Enum.ProximityPromptInputType:GetEnumItems()
for index, code in keyCodes do
	local other = keyCodes[(index * 7) % #keyCodes + 1]
	for _, prompt in
		{
			{ GamepadKeyCode = code, KeyboardKeyCode = other },
			{ GamepadKeyCode = other, KeyboardKeyCode = code },
		}
	do
		for _, inputType in promptTypes do
			sameAs(
				Now.keyText(prompt, inputType),
				Reference.keyText(prompt, inputType),
				string.format(
					"keyText %s/%s %s",
					prompt.GamepadKeyCode.Name,
					prompt.KeyboardKeyCode.Name,
					inputType.Name
				)
			)
		end
	end
end
-- Golden outputs of PromptRules.inputType by UserInputType name (false for nil), generated once
-- from the code at a50e99c: they pin its behaviour. A deliberate change updates this table.
local PROMPT_INPUT_TYPES = {
	Accelerometer = false,
	Focus = false,
	Gamepad1 = "Gamepad",
	Gamepad2 = "Gamepad",
	Gamepad3 = "Gamepad",
	Gamepad4 = "Gamepad",
	Gamepad5 = "Gamepad",
	Gamepad6 = "Gamepad",
	Gamepad7 = "Gamepad",
	Gamepad8 = "Gamepad",
	Gyro = false,
	InputMethod = false,
	Keyboard = "Keyboard",
	MouseButton1 = "Keyboard",
	MouseButton2 = "Keyboard",
	MouseButton3 = "Keyboard",
	MouseMovement = "Keyboard",
	MouseWheel = "Keyboard",
	None = false,
	TextInput = false,
	Touch = "Touch",
}
for _, inputType in Enum.UserInputType:GetEnumItems() do
	local want = PROMPT_INPUT_TYPES[inputType.Name]
	check(want ~= nil, "inputType " .. inputType.Name .. " has a golden row")
	local got = PromptRules.inputType(inputType)
	equal(if got then got.Name else false, want, "inputType " .. inputType.Name)
end
local function card(key, name: string)
	return {
		prompt = {
			KeyboardKeyCode = key,
			GetFullName = function()
				return name
			end,
		},
	}
end
local cards = {}
for _, key in { Enum.KeyCode.E, Enum.KeyCode.F, Enum.KeyCode.Q, Enum.KeyCode.Unknown } do
	for _, name in { "Workspace.A.Drive", "Workspace.B.Ride", "Workspace.A.Drive", "" } do
		table.insert(cards, card(key, name))
	end
end
for _, a in cards do
	for _, b in cards do
		sameAs(Now.before(a, b), Reference.before(a, b), "before")
	end
end

-- HealthBar ---------------------------------------------------------------------------------------

Check.section("HealthBar")
-- Index 1 stands for an unset attribute.
local healthValues = { false, -10, -0, 0, 0.4, 1, 49.5, 50, 99.99, 100, 250, 1e300, nan, inf, -inf }
local maxValues = { false, -5, -0, 0, 0.5, 1, 100, 250, 1e300, nan, inf }
for healthIndex, healthValue in healthValues do
	for maxIndex, maxValue in maxValues do
		local health = if healthIndex == 1 then nil else healthValue
		local maxHealth = if maxIndex == 1 then nil else maxValue
		local model = withAttributes(
			{ [Names.Attributes.Health] = health, [Names.Attributes.MaxHealth] = maxHealth },
			{ Name = "Jeep" }
		)
		local label = "health " .. show(health) .. " / " .. show(maxHealth)
		sameAs({ Now.health(model) }, { Reference.health(model) }, label)
	end
end
-- Golden outputs of HealthBar.colorFor (share, R, G, B), generated once from the code at a50e99c:
-- they pin its behaviour. A deliberate change updates this table.
local HEALTH_COLORS = {
	{ -inf, nan, nan, nan },
	{ -0.02, 0.8996078372001648, 0.1725490242242813, 0.1568627506494522 },
	{ -0, 0.9019607901573181, 0.19607843458652496, 0.1568627506494522 },
	{ 0, 0.9019607901573181, 0.19607843458652496, 0.1568627506494522 },
	{ 0.001, 0.9020785093307495, 0.19725491106510162, 0.1568627655506134 },
	{ 0.25, 0.9313725233078003, 0.4901960790157318, 0.1568627506494522 },
	{ 0.49999999999999994, 0.9607843160629272, 0.7843137383460999, 0.1568627506494522 },
	{ 0.5, 0.9607843160629272, 0.7843137383460999, 0.1568627506494522 },
	{ 0.5000000000000001, 0.9607843160629272, 0.7843137383460999, 0.1568627506494522 },
	{ 0.75, 0.6176470518112183, 0.8039215803146362, 0.2549019753932953 },
	{ 0.999, 0.2758823335170746, 0.8234509825706482, 0.3525490462779999 },
	{ 1, 0.27450981736183167, 0.8235294222831726, 0.3529411852359772 },
	{ 1.02, 0.24705885350704193, 0.8250980377197266, 0.3607843220233917 },
	{ inf, nan, nan, nan },
	{ nan, nan, nan, nan },
}
for _, case in HEALTH_COLORS do
	sameAsGolden(
		HealthBar.colorFor(case[1]),
		Color3.new(case[2], case[3], case[4]),
		"colorFor " .. show(case[1])
	)
end

-- DriveAxes ---------------------------------------------------------------------------------------

Check.section("DriveAxes readInput")
local K = Enum.KeyCode
local driveKeys = { K.W, K.Up, K.S, K.Down, K.D, K.Right, K.A, K.Left }
local floats = { -1.5, -1, -0.3, -0, 0, 0.05, 0.7, 1, 2, nan }
local moves = {
	false,
	"error",
	"not a vector",
	Vector3.new(0, 0, -1),
	Vector3.new(0.5, 0, 0.25),
	Vector3.new(-2, 3, 2),
	Vector3.new(-0, 0, 0),
	Vector3.new(nan, 0, nan),
}
local readCases = 0
for mask = 0, 255, 3 do
	local down = {}
	for bit, key in driveKeys do
		down[key] = bit32.btest(mask, bit32.lshift(1, bit - 1))
	end
	-- CarInput's keyAxis (unchanged), with IsKeyDown read from `down`.
	local function keyAxis(positive, negative): number
		local value = 0
		for _, key in positive do
			if down[key] then
				value += 1
				break
			end
		end
		for _, key in negative do
			if down[key] then
				value -= 1
				break
			end
		end
		return value
	end
	for _, throttleFloat in floats do
		for _, steerFloat in floats do
			for _, move in moves do
				local seat = { ThrottleFloat = throttleFloat, SteerFloat = steerFloat }
				local calls = { want = 0, got = 0 }
				local function controlsFor(counter: string)
					return function()
						calls[counter] += 1
						if not move then
							return nil
						end
						return {
							GetMoveVector = function()
								if move == "error" then
									error("no move vector")
								end
								return move
							end,
						}
					end
				end
				local label = string.format(
					"readInput keys %d seat %s,%s move %s",
					mask,
					show(throttleFloat),
					show(steerFloat),
					tostring(move)
				)
				sameAs(
					{ Now.readInput(seat, keyAxis, controlsFor("got"), K) },
					{ Reference.readInput(seat, keyAxis, controlsFor("want"), K) },
					label
				)
				equal(calls.got, calls.want, label .. " getControls calls")
				readCases += 1
			end
		end
	end
end
-- Golden outputs of DriveAxes.lift (keys, touch, lift), generated once from the code at a50e99c:
-- they pin its behaviour. A deliberate change updates this table.
local LIFTS = {
	{ -1, -1, -1 },
	{ -1, 0, -1 },
	{ -1, 1, 0 },
	{ 0, -1, -1 },
	{ 0, 0, 0 },
	{ 0, 1, 1 },
	{ 1, -1, 0 },
	{ 1, 0, 1 },
	{ 1, 1, 1 },
	{ 0.5, 0.75, 1 },
	{ -0.5, -0.75, -1 },
	{ -0, 0, 0 },
	{ -0, -0, -0 },
	{ nan, 0, nan },
	{ inf, 0, 1 },
	{ 1, -inf, -1 },
}
for _, case in LIFTS do
	sameAsGolden(
		DriveAxes.lift(case[1], case[2]),
		case[3],
		"lift " .. show(case[1]) .. " " .. show(case[2])
	)
end

Check.section("DriveAxes resend")
for _ = 1, 300 do
	local want, got = Reference.newSender(), Now.newSender()
	local now = between(0, 100)
	local throttle, steer, lift = 0, 0, 0
	for frame = 1, 120 do
		now += pick({ 0, 1 / 60, 0.1, 0.25, 0.2500001, 0.3 })
		local roll = nextNumber()
		if roll < 0.3 then
			throttle += pick({ 0.05, -0.05, 0.0500001, 0.04, 0, 1, nan })
		elseif roll < 0.6 then
			steer = pick({ -1, -0.5, 0, 0.05, 0.051, 1, -0 })
		elseif roll < 0.7 then
			lift = pick({ -1, 0, 1 })
		end
		local inputs = {
			seat = nextNumber() > 0.1,
			throttle = throttle,
			steer = steer,
			lift = lift,
			now = now,
		}
		sameAs(got(inputs), want(inputs), "send frame " .. frame .. " " .. show(inputs))
	end
end

-- EngineEnvelope ----------------------------------------------------------------------------------

Check.section("EngineEnvelope engine")
Check.section("EngineEnvelope.lerp")
-- Golden outputs of EngineEnvelope.lerp, generated once from the code at a50e99c: they pin its
-- behaviour. A deliberate change updates this table. { from, to, t, want }
local LERPS = {
	{ 0, 1, -0.5, -0.5 },
	{ 0, 1, -0, 0 },
	{ 0, 1, 0, 0 },
	{ 0, 1, 0.25, 0.25 },
	{ 0, 1, 0.5, 0.5 },
	{ 0, 1, 1, 1 },
	{ 0, 1, 1.5, 1.5 },
	{ 0, 1, nan, nan },
	{ 0.80000000000000004, 1.6000000000000001, -0.5, 0.40000000000000002 },
	{ 0.80000000000000004, 1.6000000000000001, -0, 0.80000000000000004 },
	{ 0.80000000000000004, 1.6000000000000001, 0, 0.80000000000000004 },
	{ 0.80000000000000004, 1.6000000000000001, 0.25, 1 },
	{ 0.80000000000000004, 1.6000000000000001, 0.5, 1.2000000000000002 },
	{ 0.80000000000000004, 1.6000000000000001, 1, 1.6000000000000001 },
	{ 0.80000000000000004, 1.6000000000000001, 1.5, 2 },
	{ 0.80000000000000004, 1.6000000000000001, nan, nan },
	{ 1, 0, -0.5, 1.5 },
	{ 1, 0, -0, 1 },
	{ 1, 0, 0, 1 },
	{ 1, 0, 0.25, 0.75 },
	{ 1, 0, 0.5, 0.5 },
	{ 1, 0, 1, 0 },
	{ 1, 0, 1.5, -0.5 },
	{ 1, 0, nan, nan },
	{ -2, 3, -0.5, -4.5 },
	{ -2, 3, -0, -2 },
	{ -2, 3, 0, -2 },
	{ -2, 3, 0.25, -0.75 },
	{ -2, 3, 0.5, 0.5 },
	{ -2, 3, 1, 3 },
	{ -2, 3, 1.5, 5.5 },
	{ -2, 3, nan, nan },
	{ 0.34999999999999998, 0.34999999999999998, -0.5, 0.34999999999999998 },
	{ 0.34999999999999998, 0.34999999999999998, -0, 0.34999999999999998 },
	{ 0.34999999999999998, 0.34999999999999998, 0, 0.34999999999999998 },
	{ 0.34999999999999998, 0.34999999999999998, 0.25, 0.34999999999999998 },
	{ 0.34999999999999998, 0.34999999999999998, 0.5, 0.34999999999999998 },
	{ 0.34999999999999998, 0.34999999999999998, 1, 0.34999999999999998 },
	{ 0.34999999999999998, 0.34999999999999998, 1.5, 0.34999999999999998 },
	{ 0.34999999999999998, 0.34999999999999998, nan, nan },
}
for _, row in LERPS do
	sameAsGolden(
		EngineEnvelope.lerp({ row[1], row[2] }, row[3]),
		row[4],
		"lerp " .. show(row[1]) .. " " .. show(row[2]) .. " " .. show(row[3])
	)
end

local SoundCatalog = Sandbox.require(Shared.SoundCatalog)
local SETTINGS = SoundCatalog.VEHICLE
local engineSettings = {
	SETTINGS,
	{ loadBump = 0.04, fadeIn = 0.5, fadeOut = 0.5, pitchCurve = 0.8 },
	{ loadBump = 0, fadeIn = 0.01, fadeOut = 3, pitchCurve = 1 },
}
local profiles = {}
for id, profile in SoundCatalog.VEHICLES do
	local voices = {}
	for index, loop in { profile.engine, table.unpack(profile.layers or {}) } do
		table.insert(voices, { loop = loop, isEngine = index == 1 })
	end
	table.insert(profiles, { id = id, voices = voices })
end
check(#profiles > 0, "vehicle sound profiles")
for _, profile in profiles do
	for _, settings in engineSettings do
		local want = { running = false, playing = false, level = 0, smoothed = 0, bump = 0 }
		local got = table.clone(want)
		for frame = 1, 400 do
			local running = nextNumber() > 0.3
			local playing = want.playing or running
			want.running, got.running = running, running
			want.playing, got.playing = playing, playing
			local dt = pick({ 0, 1 / 240, 1 / 60, 0.1, 0.5 })
			local follow = MathUtil.rateAlpha(settings.smoothing or 5, dt)
			local target = pick({ 0, 0.2, 0.5, 1, nextNumber(), -0 })
			local label = string.format("engine %s frame %d", profile.id, frame)
			sameAs(
				Now.engineFrame(got, settings, profile.voices, dt, follow, target),
				Reference.engineFrame(want, settings, profile.voices, dt, follow, target),
				label
			)
			sameAs(got, want, label .. " state")
		end
	end
end

Check.section("EngineEnvelope mech")
local MechGait = Sandbox.require(Shared.MechGait)
for id, profile in SoundCatalog.MECHS do
	local want = { running = false, level = 0, speed = 0, cadence = 0 }
	local got = table.clone(want)
	for frame = 1, 600 do
		local running = nextNumber() > 0.3
		want.running, got.running = running, running
		local gait = if nextNumber() > 0.2
			then {
				ground = pick({ 0, 3, 20, 80, -1, nan }),
				topSpeed = pick({ 0, 16, 30.5 }),
				rate = pick({ 0, 0.5, 2, 9 }),
				rig = { scale = pick({ 0.5, 1, 2.25 }) },
			}
			else nil
		local dt = pick({ 0, 1 / 60, 0.1 })
		local follow = MathUtil.rateAlpha(profile.smoothing, dt)
		local humOn = nextNumber() > 0.4
		local label = string.format("mech %s frame %d", id, frame)
		sameAs(
			Now.mechFrame(got, profile, gait, MechGait.CYCLE, dt, follow, humOn),
			Reference.mechFrame(want, profile, gait, MechGait.CYCLE, dt, follow, humOn),
			label
		)
		sameAs(got, want, label .. " state")
	end
end

-- NearestSet --------------------------------------------------------------------------------------

Check.section("NearestSet")
local rangeSettings = {
	SETTINGS,
	{ buildRange = 50, dropRange = 50, maxActive = 1 },
	{ buildRange = 10, dropRange = 200, maxActive = 0 },
}
for round = 1, 400 do
	local settings = rangeSettings[round % #rangeSettings + 1]
	local children = {}
	for index = 1, math.floor(nextNumber() * 14) do
		local isModel = nextNumber() > 0.1
		local hasSkid = nextNumber() > 0.1
		-- Distances on the ranges, ties, and in between.
		local distance = pick({ 0, 50, 130, 130.0001, 160, 160.0001, 10, 200, between(0, 250) })
		children[index] = {
			name = "child" .. index,
			IsA = function(_, className: string): boolean
				return className == "Model" and isModel
			end,
			PrimaryPart = if hasSkid then { Position = Vector3.new(distance, 0, 0) } else nil,
		}
	end
	local active = {}
	for _, child in children do
		if nextNumber() > 0.5 then
			active[child] = true
		end
	end
	local want = Reference.choose(children, active, Vector3.zero, settings)
	local got = Now.choose(children, active, Vector3.zero, settings)
	sameAs(got, want, "choose round " .. round)
	-- The same keys in the same iteration order (VehicleSounds makes handlers in that order).
	local wantOrder, gotOrder = {}, {}
	for model in want do
		table.insert(wantOrder, model.name)
	end
	for model in got do
		table.insert(gotOrder, model.name)
	end
	sameAs(gotOrder, wantOrder, "choose order round " .. round)
end

-- ScopeMath ---------------------------------------------------------------------------------------

Check.section("ScopeMath")
local viewports = {
	Vector2.new(0, 0),
	Vector2.new(1, 1),
	Vector2.new(320, 240),
	Vector2.new(375.5, 667.25),
	Vector2.new(1366.4, 1024.6),
	Vector2.new(1920, 1080),
	Vector2.new(3840, 2160),
}
for side = 0, 1200, 3 do
	table.insert(viewports, Vector2.new(side, side * 0.75 + 0.5))
	table.insert(viewports, Vector2.new(side * 1.6, side))
end
for _, viewport in viewports do
	sameAs(Now.overlay(viewport), Reference.overlay(viewport), "overlay " .. tostring(viewport))
end
local turnInputs = { 0, -0, 0.02, -3.7, 18 / 60, 90, -200, 1e6, nan, inf }
for _, startPitch in { 0, -0, 1, -1.3962634015954636, 1.3962634015954636, 2, nan } do
	for _, yawDegrees in turnInputs do
		for _, pitchDegrees in turnInputs do
			local want = { targetYaw = 0.25, targetPitch = startPitch }
			local got = table.clone(want)
			Reference.turn(want, yawDegrees, pitchDegrees)
			Now.turn(got, yawDegrees, pitchDegrees)
			sameAs(
				got,
				want,
				string.format(
					"turn %s by %s,%s",
					show(startPitch),
					show(yawDegrees),
					show(pitchDegrees)
				)
			)
		end
	end
end
for step = -1100, 1100 do
	local look = Vector3.new(0.3, step / 1000, -0.7)
	sameAs(Now.pitchOf(look), Reference.pitchOf(look), "pitchOf " .. show(step))
end
for _, y in { nan, inf, -inf, -0 } do
	local look = Vector3.new(0, y, -1)
	sameAs(Now.pitchOf(look), Reference.pitchOf(look), "pitchOf " .. show(y))
end

-- FootfallShake ----------------------------------------------------------------------------------

Check.section("FootfallShake")
for round = 1, 500 do
	local want = {}
	local now = between(0, 1000)
	for _ = 1, math.floor(nextNumber() * 8) do
		table.insert(want, {
			start = now - pick({ 0, 0.1, 0.4, 0.4000001, 0.39, 2, -0.1, between(0, 0.5) }),
			strength = pick({ 0, 0.3, 1, 2.5 }),
		})
	end
	local got = table.clone(want)
	for frame = 1, 5 do
		local label = string.format("shake round %d frame %d", round, frame)
		sameAs({ Now.shake(got, now) }, { Reference.shake(want, now) }, label)
		sameAs(got, want, label .. " list")
		now += 1 / 60 * frame
	end
end

-- NukeMath ----------------------------------------------------------------------------------------

Check.section("NukeMath")
for step = -10, 1010 do
	local t = step / 1000
	sameAs({ Now.bomb(t) }, { Reference.bomb(t) }, "bomb " .. show(t))
end
for _, t in { nan, -0, inf } do
	sameAs({ Now.bomb(t) }, { Reference.bomb(t) }, "bomb " .. show(t))
end
for step = 0, 4000 do
	local elapsed = step / 1000 * Config.NUKE_WAVE_SECONDS / 4
	sameAs({ Now.wave(elapsed) }, { Reference.wave(elapsed) }, "wave " .. show(elapsed))
end
for _, elapsed in { -0, -1, nan, Config.NUKE_WAVE_SECONDS, Config.NUKE_WAVE_SECONDS * 2 } do
	sameAs({ Now.wave(elapsed) }, { Reference.wave(elapsed) }, "wave " .. show(elapsed))
end
local distances = { 0, -0, 10, 500, 1000, 1500, 2142.857, 3000, 1e9, nan, inf }
for _, distance in distances do
	for step = -5, 105 do
		local t = step / 100
		sameAs(
			{ Now.nukeShake(distance, t) },
			{ Reference.nukeShake(distance, t) },
			"nuke shake " .. show(distance) .. " " .. show(t)
		)
	end
end

-- ConfirmTap --------------------------------------------------------------------------------------

Check.section("ConfirmTap")
-- One run of the NUKE button: taps at the given times; each os.clock() read advances the clock by
-- `tick`; task.delay callbacks run when the clock passes their time.
local function runTaps(make, taps: { number }, tick: number): { string }
	local log = {}
	local clock = 0
	local pending: { { at: number, run: () -> () } } = {}
	local os = {
		clock = function(): number
			clock += tick
			return clock
		end,
	}
	local task = {
		delay = function(seconds: number, run: () -> ())
			table.insert(pending, { at = clock + seconds, run = run })
		end,
	}
	local tap = make(os, task, log, 3)
	local function runDue(time: number)
		while true do
			local due, dueIndex = nil, nil
			for index, each in pending do
				if each.at <= time and (not due or each.at < due.at) then
					due, dueIndex = each, index
				end
			end
			if not due then
				return
			end
			table.remove(pending, dueIndex)
			clock = math.max(clock, due.at)
			table.insert(log, "expire@" .. show(due.at))
			due.run()
		end
	end
	for _, time in taps do
		runDue(time)
		clock = math.max(clock, time)
		table.insert(log, "tap@" .. show(clock))
		tap()
	end
	runDue(math.huge)
	return log
end
for round = 1, 500 do
	local taps = {}
	local time = 0
	for _ = 1, math.floor(nextNumber() * 9) + 1 do
		time += pick({ 0, 0.5, 2.9999, 3, 3.0001, 4, 10, between(0, 6) })
		table.insert(taps, time)
	end
	for _, tick in { 0, 1e-6, 0.4 } do
		sameAs(
			runTaps(Now.newNuke, taps, tick),
			runTaps(Reference.newNuke, taps, tick),
			string.format("taps round %d tick %s: %s", round, show(tick), show(taps))
		)
	end
end

-- Plain values ------------------------------------------------------------------------------------

Check.section("plain values")
equal(Loadout.speedLabel(0.15), "rapid fire", "speedLabel 0.15")
equal(Loadout.statText({ kind = "hitscan", damage = 8, pellets = 6 } :: any), "DMG 8×6", "shotgun")
equal(Loadout.toggle({ "a", "b", "c" }, "d"), "full", "a fourth weapon")
equal(PodButtons.view("flying", true, true, false).text, "RETURN HOME", "flying text")
equal(PromptRules.keyText(Enum.ProximityPromptInputType.Gamepad, K.ButtonX, K.E), "X", "ButtonX")
equal(HealthBar.labelText("Jeep", 12.2, 100), "Jeep  13 / 100", "label")
-- The status label's speed, golden values: rounded studs/s; a non-finite speed reads 0.
for _, case in
	{
		{ 0, "0 spd" },
		{ 0.4, "0 spd" },
		{ 0.5, "1 spd" },
		{ 58.6, "59 spd" },
		{ 117, "117 spd" },
		{ 0 / 0, "0 spd" },
		{ math.huge, "0 spd" },
		{ -math.huge, "0 spd" },
	}
do
	equal(HealthBar.speedText(case[1]), case[2], "speed " .. tostring(case[1]))
end
check(ScopeMath.MAX_PITCH == math.rad(80), "MAX_PITCH")
equal(NukeMath.WAVE_SEGMENTS, 72, "segments")
equal(DriveAxes.RESEND_INTERVAL, 0.25, "resend interval")
check(Config.NUKE_WAVE_SECONDS > 0 and Config.NUKE_FALL_SECONDS > 0, "nuke timings")
equal(readCases, 86 * 10 * 10 * 8, "readInput cases")

Check.finish()
