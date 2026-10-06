--!strict
-- Builds and plays Sounds from SoundCatalog cues. The server plays weapon sounds (they
-- replicate); each client plays vehicle engines for itself.

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local SoundCatalog = require(ReplicatedStorage.Shared.SoundCatalog)

type Cue = SoundCatalog.Cue

local Sounds = {}

local random = Random.new()
local DEFAULT_JITTER = { 0.04, 0.10 }
local DEFAULT_FADE = 0.3

local function addEffects(parent: Instance, effects: { SoundCatalog.Effect }?)
	for _, spec in (effects or {}) :: { SoundCatalog.Effect } do
		local effect = Instance.new(spec.class) :: any
		for property, value in spec do
			if property ~= "class" then
				effect[property] = value
			end
		end
		effect.Parent = parent
	end
end

-- The SoundService group `name`, created the first time it is asked for. Groups made on the
-- server replicate; the client makes its own (Vehicles) locally.
function Sounds.group(name: string): SoundGroup
	local existing = SoundService:FindFirstChild(name)
	if existing then
		return existing :: SoundGroup
	end
	local spec = SoundCatalog.GROUPS[name]
	local group = Instance.new("SoundGroup")
	group.Name = name
	group.Volume = spec.volume
	addEffects(group, spec.effects)
	group.Parent = SoundService
	return group
end

-- A Sound set up from a cue (or a vehicle loop): asset, base volume and pitch, roll-off, group,
-- effects. Not parented and not playing.
function Sounds.make(cue: { [string]: any }, group: string): Sound
	local range = SoundCatalog.RANGES[cue.range or "small"]
	local sound = Instance.new("Sound")
	sound.Name = cue.key
	sound.SoundId = "rbxassetid://" .. SoundCatalog.PALETTE[cue.key].id
	sound.Volume = if typeof(cue.volume) == "number" then cue.volume else 0
	sound.PlaybackSpeed = if typeof(cue.pitch) == "number" then cue.pitch else 1
	sound.RollOffMode = Enum.RollOffMode.InverseTapered
	sound.RollOffMinDistance = range[1]
	sound.RollOffMaxDistance = range[2]
	sound.SoundGroup = Sounds.group(group)
	addEffects(sound, cue.effects)
	return sound
end

-- Each play bumps a sound's token, so a fade from an earlier play leaves it alone.
local tokens: { [Sound]: number } = setmetatable({}, { __mode = "k" }) :: any
local tweens: { [Sound]: Tween } = setmetatable({}, { __mode = "k" }) :: any

local function bump(sound: Sound): number
	local tween = tweens[sound]
	if tween then
		tween:Cancel()
		tweens[sound] = nil
	end
	local token = (tokens[sound] or 0) + 1
	tokens[sound] = token
	return token
end

local function fade(sound: Sound, seconds: number, token: number)
	if tokens[sound] ~= token or not sound.Parent then
		return
	end
	local tween = TweenService:Create(sound, TweenInfo.new(seconds), { Volume = 0 })
	tweens[sound] = tween
	tween.Completed:Connect(function(state)
		if state == Enum.PlaybackState.Completed and tokens[sound] == token then
			sound:Stop()
		end
	end)
	tween:Play()
end

-- Fades a playing sound to silence, then stops it. A later play cancels the fade.
function Sounds.fadeOut(sound: Sound, seconds: number)
	fade(sound, seconds, bump(sound))
end

local playOn: (Cue, Instance, string, number?) -> number

-- Plays a sound built from `cue` with fresh jitter, from `cue.start`, stopping at
-- `cue.stopAfter`. Layers play beside it as one-shots. `gain` scales every volume.
function Sounds.play(sound: Sound, cue: Cue, group: string, gain: number?)
	local token = bump(sound)
	local jitter = cue.jitter or DEFAULT_JITTER
	sound.PlaybackSpeed = (cue.pitch or 1) * random:NextNumber(1 - jitter[1], 1 + jitter[1])
	sound.Volume = cue.volume * random:NextNumber(1 - jitter[2], 1) * (gain or 1)
	sound.TimePosition = cue.start or 0
	sound:Play()
	if cue.stopAfter then
		local speed = sound.PlaybackSpeed
		local seconds = math.min(cue.fade or DEFAULT_FADE, cue.stopAfter - (cue.start or 0))
		local hold = (cue.stopAfter - (cue.start or 0) - seconds) / speed
		task.delay(hold, fade, sound, seconds / speed, token)
	end
	local parent = sound.Parent
	if parent then
		for _, layer in (cue.layers or {}) :: { Cue } do
			playOn(layer, parent, group, gain)
		end
	end
end

-- A throwaway sound on `parent` (a part or attachment): plays once and is destroyed after it
-- ends, or with its parent. Returns its lifetime in seconds.
function playOn(cue: Cue, parent: Instance, group: string, gain: number?): number
	local sound = Sounds.make(cue, group)
	sound.Parent = parent
	Sounds.play(sound, cue, group, gain)
	local length = (cue.stopAfter or SoundCatalog.PALETTE[cue.key].duration) - (cue.start or 0)
	local lifetime = length / sound.PlaybackSpeed + 0.3
	Debris:AddItem(sound, lifetime)
	return lifetime
end
Sounds.playOn = playOn

-- A one-shot at a world position.
function Sounds.playAt(cue: Cue, position: Vector3, group: string, gain: number?)
	local attachment = Instance.new("Attachment")
	attachment.Name = "SoundAt"
	attachment.Position = position -- Terrain sits at the origin
	attachment.Parent = workspace.Terrain
	local lifetime = playOn(cue, attachment, group, gain)
	for _, layer in (cue.layers or {}) :: { Cue } do
		local length = (layer.stopAfter or SoundCatalog.PALETTE[layer.key].duration)
			- (layer.start or 0)
		lifetime = math.max(lifetime, length / ((layer.pitch or 1) * 0.85) + 0.3)
	end
	Debris:AddItem(attachment, lifetime)
end

return Sounds
