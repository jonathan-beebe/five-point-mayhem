-- Weapon sounds from SoundCatalog.WEAPONS. Fire sounds live on the tool's handle; every other
-- event is a one-shot in the world. Events a weapon has no cue for are silent.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SoundCatalog = require(ReplicatedStorage.Shared.SoundCatalog)
local Sounds = require(ReplicatedStorage.Shared.Sounds)

local WeaponSounds = {}

local GROUP = "Weapons"

local function cueFor(weaponId: string, event: string): SoundCatalog.Cue?
	local entry = SoundCatalog.WEAPONS[weaponId]
	return entry and (entry :: any)[event]
end

-- Gives a tool's handle its fire sound: FireSound, or FireSound1..n for a pooled auto weapon.
function WeaponSounds.equip(handle: BasePart, weaponId: string)
	local entry = SoundCatalog.WEAPONS[weaponId]
	if not entry or not entry.fire then
		return
	end
	local count = entry.pool or 1
	for index = 1, count do
		local sound = Sounds.make(entry.fire, GROUP)
		sound.Name = if count > 1 then "FireSound" .. index else "FireSound"
		sound.Parent = handle
	end
end

-- Minigun-style sounds held while shots keep coming. `from` and `at` track the file position.
type Held = { sound: Sound, spec: SoundCatalog.Sustain, last: number, from: number, at: number }
local held: { [Sound]: Held } = {}

local nextInPool: { [BasePart]: number } = setmetatable({}, { __mode = "k" }) :: any

function WeaponSounds.fire(handle: BasePart?, weaponId: string)
	local entry = SoundCatalog.WEAPONS[weaponId]
	local cue = entry and entry.fire
	if not handle or not entry or not cue then
		return
	end
	local name = "FireSound"
	if entry.pool then
		local index = (nextInPool[handle] or 0) % entry.pool + 1
		nextInPool[handle] = index
		name ..= index
	end
	local sound = handle:FindFirstChild(name) :: Sound?
	if not sound then
		return
	end
	local now = os.clock()
	local sustain = entry.sustain
	if sustain then
		local state = held[sound]
		if state then
			state.last = now
			return
		end
		held[sound] = { sound = sound, spec = sustain, last = now, from = cue.start or 0, at = now }
	end
	Sounds.play(sound, cue, GROUP)
end

RunService.Heartbeat:Connect(function()
	local now = os.clock()
	for sound, state in held do
		if not sound.Parent then
			held[sound] = nil
		elseif now - state.last > state.spec.release then
			held[sound] = nil
			Sounds.fadeOut(sound, state.spec.fade)
		elseif state.from + (now - state.at) * sound.PlaybackSpeed > state.spec.loopAt then
			sound.TimePosition = state.spec.loopTo
			state.from, state.at = state.spec.loopTo, now
		end
	end
end)

-- The cue for an event, for callers that hand it on (Combat.explode).
WeaponSounds.cue = cueFor

-- A one-shot at a world position.
function WeaponSounds.at(weaponId: string, event: string, position: Vector3)
	local cue = cueFor(weaponId, event)
	if cue then
		Sounds.playAt(cue, position, GROUP)
	end
end

-- A one-shot riding a part; it stops when the part is destroyed.
function WeaponSounds.on(weaponId: string, event: string, part: BasePart)
	local cue = cueFor(weaponId, event)
	if cue then
		Sounds.playOn(cue, part, GROUP)
	end
end

return WeaponSounds
