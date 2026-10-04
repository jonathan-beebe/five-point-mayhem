-- Plays every weapon and vehicle sound in SoundCatalog, one after another, for tuning by ear.
--
-- In Studio: press Play (F5), then paste this whole file into the Command Bar (View > Command
-- Bar) and press Enter. Works from the server or the client view. Sounds play around your
-- character and the Output window names each one as it plays. After editing SoundCatalog, stop
-- and press Play again: a running game keeps the catalog it loaded.
--
-- Weapon cues that the game plays through Combat.explode also spawn a harmless Explosion and use
-- EXPLOSION_GAIN, so you hear what players hear. Vehicles run their start sound, then sweep the
-- engine loops idle -> top speed -> idle with the curve VehicleSounds uses. The mech closes its
-- hatch and powers up, then walks the same sweep: hum, servo, and alternating steps at the gait's
-- cadence (0.65 s apart at top speed), then opens its hatch.

-- Settings ------------------------------------------------------------------------------------

local SECTION = "all" -- "all" | "weapons" | "vehicles"
local ONLY = {} -- weapon or vehicle ids, e.g. { "shotgun", "abrams" }; empty plays everything
local GAP = 0.6 -- seconds of silence between cues

------------------------------------------------------------------------------------------------

local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

assert(RunService:IsRunning(), "[audition] press Play first, then paste this into the Command Bar")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local SoundCatalog = require(Shared.SoundCatalog)
local MechGait = require(Shared.MechGait)
local Sounds = require(Shared.Sounds)
local VehicleCatalog = require(Shared.VehicleCatalog)
local WeaponCatalog = require(Shared.WeaponCatalog)

local player = Players.LocalPlayer or Players:GetPlayers()[1]
local character = player and player.Character
local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
assert(root, "[audition] no character to play around")

local wanted: { [string]: boolean } = {}
for _, id in ONLY do
	wanted[id] = true
end
local function include(id: string): boolean
	return next(wanted) == nil or wanted[id] == true
end

-- Everything this run makes lives under one attachment, removed at the end.
local NEAR = CFrame.new(1.5, 0.5, -3) -- in your hand
local FAR = CFrame.new(0, 0, -25) -- where a shot lands
local anchor = Instance.new("Attachment")
anchor.Name = "Audition"
anchor.Parent = workspace.Terrain

local function spot(offset: CFrame): Attachment
	local each = Instance.new("Attachment")
	each.Name = "AuditionSpot"
	each.WorldPosition = ((root :: BasePart).CFrame * offset).Position
	each.Parent = anchor
	return each
end

local function length(cue: SoundCatalog.Cue): number
	local seconds = (cue.stopAfter or SoundCatalog.PALETTE[cue.key].duration) - (cue.start or 0)
	return seconds / (cue.pitch or 1)
end

-- Load every file first so the first play of each is not late.
local preload = {}
for _, entry in SoundCatalog.PALETTE do
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://" .. entry.id
	table.insert(preload, sound)
end
print("[audition] loading " .. #preload .. " sounds…")
ContentProvider:PreloadAsync(preload)

-- The events the game sends through Combat.explode (see Weapons.luau impact/blackHole/fireStrike).
local function explodes(weapon: WeaponCatalog.Weapon, event: string): boolean
	return (event == "impact" and weapon.blast ~= nil and not weapon.splash and not weapon.impact)
		or event == "finish"
		or (event == "strike" and weapon.style == "meteor")
end

local FAR_EVENTS = {
	impact = true,
	strike = true,
	fall = true,
	loop = true,
	finish = true,
	trap = true,
	blinkTo = true,
}

local function playWeapons()
	for _, weapon in WeaponCatalog.ALL do
		local entry = SoundCatalog.WEAPONS[weapon.id]
		if not entry or not include(weapon.id) then
			continue
		end
		for _, event in SoundCatalog.WEAPON_EVENTS do
			local cue = (entry :: any)[event] :: SoundCatalog.Cue?
			if not cue then
				continue
			end
			local where = spot(if FAR_EVENTS[event] then FAR else NEAR)
			local gain = 1
			local note = ""
			if explodes(weapon, event) then
				local blast = Instance.new("Explosion")
				blast.Position = where.WorldPosition
				blast.BlastRadius = weapon.blast or 14
				blast.BlastPressure = 0
				blast.DestroyJointRadiusPercent = 0
				blast.ExplosionType = Enum.ExplosionType.NoCraters
				blast.Parent = workspace
				gain = SoundCatalog.EXPLOSION_GAIN
				note = "  (+ Explosion, gain " .. gain .. ")"
			end
			-- Auto weapons fire a short burst so repetition and pooling are audible.
			local shots = if event == "fire" and weapon.auto then 6 else 1
			print(("[audition] %s.%s  %s%s"):format(weapon.id, event, cue.key, note))
			for _ = 1, shots do
				Sounds.playOn(cue, where, "Weapons", gain)
				if shots > 1 then
					task.wait(math.max(weapon.cooldown, 0.06))
				end
			end
			task.wait(length(cue) + GAP)
		end
	end
end

local function lerp(range: { number }, t: number): number
	return range[1] + (range[2] - range[1]) * t
end

-- Speed / top speed over the sweep: idle, rise, hold at top speed, fall back to idle.
local SWEEP = { { 0, 1.5 }, { 1, 3 }, { 1, 1 }, { 0, 2.5 } }

local function playVehicles()
	local settings = SoundCatalog.VEHICLE
	for _, vehicle in VehicleCatalog.ALL do
		local profile = SoundCatalog.VEHICLES[vehicle.id]
		if not profile or not include(vehicle.id) then
			continue
		end
		local where = spot(CFrame.new(0, 0, -8))
		print(("[audition] %s  engine %s"):format(vehicle.id, profile.engine.key))
		if profile.start then
			Sounds.playOn(profile.start, where, "Vehicles")
			task.wait(settings.startDelay)
		end
		local voices = {}
		for _, loop in { profile.engine, table.unpack(profile.layers or {}) } do
			local sound = Sounds.make(loop, "Vehicles")
			sound.Looped = true
			sound.Parent = where
			sound:Play()
			table.insert(voices, { loop = loop, sound = sound })
		end
		local speed = 0
		for _, step in SWEEP do
			local target, seconds = step[1], step[2]
			local from = speed
			local began = os.clock()
			while os.clock() - began < seconds do
				local t = math.clamp((os.clock() - began) / seconds, 0, 1)
				speed = from + (target - from) * t
				for _, voice in voices do
					local shaped = speed ^ (voice.loop.curve or settings.pitchCurve)
					voice.sound.PlaybackSpeed = lerp(voice.loop.pitch, shaped)
					voice.sound.Volume = lerp(voice.loop.volume, speed)
				end
				RunService.Heartbeat:Wait()
			end
		end
		for _, voice in voices do
			Sounds.fadeOut(voice.sound, settings.fadeOut)
		end
		task.wait(settings.fadeOut + GAP)
		where:Destroy()
	end
end

local MECH_TOP_SPEED = 18 -- the mech's `speed` (src/server/vehicleModels/mech.luau)

local function playMech()
	local mech = SoundCatalog.MECH
	local where = spot(CFrame.new(0, 0, -12))
	local feet = { L = spot(CFrame.new(-7, 0, -12)), R = spot(CFrame.new(7, 0, -12)) }
	print("[audition] mech  hatchClose + powerUp")
	Sounds.playOn(mech.hatchClose, where, "Vehicles")
	Sounds.playOn(mech.powerUp, where, "Vehicles")
	task.wait(mech.humDelay)

	local hum = Sounds.make(mech.hum, "Vehicles")
	hum.Looped = true
	hum.Parent = where
	hum:Play()
	local servo = Sounds.make(mech.servo, "Vehicles")
	servo.Looped = true
	servo.Parent = where
	servo:Play()

	print("[audition] mech  hum, servo, steps: rest -> top speed -> rest")
	local level = 0
	local speed = 0
	local untilStep = 0
	local foot = "L"
	for _, step in SWEEP do
		local target, seconds = step[1], step[2]
		local from = speed
		local began = os.clock()
		local last = began
		while os.clock() - began < seconds do
			local now = os.clock()
			local dt = now - last
			last = now
			local t = math.clamp((now - began) / seconds, 0, 1)
			speed = from + (target - from) * t
			level = math.min(1, level + dt / mech.fadeIn)
			-- Cadence as MechGait steps it: speed / CYCLE, at least MIN_RATE while moving.
			local moving = speed * MECH_TOP_SPEED > MechGait.MOVING
			local rate = if moving
				then math.max(speed * MECH_TOP_SPEED / MechGait.CYCLE, MechGait.MIN_RATE)
				else 0
			local cadence = math.clamp(rate * MechGait.CYCLE / MECH_TOP_SPEED, 0, 1)
			hum.PlaybackSpeed = lerp(mech.hum.pitch, speed ^ (mech.hum.curve or 1))
			hum.Volume = lerp(mech.hum.volume, speed) * level
			servo.PlaybackSpeed = lerp(mech.servo.pitch, cadence ^ (mech.servo.curve or 1))
			servo.Volume = lerp(mech.servo.volume, cadence)
			-- Two heel strikes per cycle; strength as MechGait gives it at full gait weight.
			untilStep -= dt
			if rate > 0 and untilStep <= 0 then
				untilStep = 0.5 / rate
				Sounds.playOn(mech.step, feet[foot], "Vehicles", 0.5 + 0.5 * speed)
				foot = if foot == "L" then "R" else "L"
			end
			RunService.Heartbeat:Wait()
		end
	end

	print("[audition] mech  hatchOpen")
	Sounds.fadeOut(hum, mech.fadeOut)
	Sounds.fadeOut(servo, mech.fadeOut)
	Sounds.playOn(mech.hatchOpen, where, "Vehicles")
	task.wait(math.max(mech.fadeOut, SoundCatalog.PALETTE[mech.hatchOpen.key].duration) + GAP)
	where:Destroy()
	feet.L:Destroy()
	feet.R:Destroy()
end

task.spawn(function()
	if SECTION ~= "vehicles" then
		playWeapons()
	end
	if SECTION ~= "weapons" then
		playVehicles()
		if include("mech") then
			playMech()
		end
	end
	anchor:Destroy()
	print("[audition] done")
end)
