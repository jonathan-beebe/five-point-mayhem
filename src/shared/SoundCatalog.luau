-- Every weapon and vehicle sound (data only). Tune by ear here; `src/shared/Sounds.luau` plays
-- these on the server (weapons) and `src/client/VehicleSounds.luau` on each client (engines and
-- the Titan Mech).
--
-- A cue is one sound on one event:
--   key        PALETTE entry
--   volume     base Sound.Volume, before the SoundGroup master
--   pitch      base PlaybackSpeed (default 1)
--   jitter     { pitch, volume }: speed × U(1 - p, 1 + p), volume × U(1 - v, 1) on every play
--   range      RANGES entry (roll-off distances)
--   start      file seconds to start from (default 0)
--   stopAfter  file seconds to stop at; fades out over `fade` seconds before it
--   effects    SoundEffect instances to add: { class = "...", <property> = value, ... }
--   layers     cues played with this one at the same place; missing range/jitter come from it
--
-- Weapon events: fire (on the handle), hit (first melee or hitscan victim), chain (each tesla
-- jump), impact (projectile landing; blast weapons hand it to Combat.explode), strike, fall
-- (meteor in flight), loop / finish (black hole), trap (banana slip), blinkFrom / blinkTo.
-- `pool = n` gives an auto weapon n handle sounds played in turn so tails overlap; `sustain`
-- holds one sound while the trigger is held.

export type Effect = { [string]: any }

export type Cue = {
	key: string,
	volume: number,
	pitch: number?,
	jitter: { number }?,
	range: string?,
	start: number?,
	stopAfter: number?,
	fade: number?,
	effects: { Effect }?,
	layers: { Cue }?,
}

export type Sustain = {
	release: number, -- seconds without a shot before the sound fades
	fade: number,
	loopAt: number, -- file seconds; jumps back to loopTo when playback passes it
	loopTo: number,
}

export type WeaponSounds = {
	pool: number?,
	sustain: Sustain?,
	fire: Cue?,
	hit: Cue?,
	chain: Cue?,
	impact: Cue?,
	strike: Cue?,
	fall: Cue?,
	loop: Cue?,
	finish: Cue?,
	trap: Cue?,
	blinkFrom: Cue?,
	blinkTo: Cue?,
}

-- A looping vehicle sound. Pitch and volume run from [1] at rest to [2] at top speed.
export type Loop = {
	key: string,
	pitch: { number },
	volume: { number },
	curve: number?, -- pitch follows speed^curve (default VEHICLE.pitchCurve)
	range: string?,
	effects: { Effect }?,
}

export type VehicleSounds = {
	engine: Loop,
	layers: { Loop }?,
	start: Cue?,
}

-- The Titan Mech (VehicleSounds' `mech` handler). `hum` runs while a pilot is aboard and follows
-- ground speed; `servo` follows the legs' cadence (walking or turning in place) and is silent at
-- rest. `step` plays at each heel strike at volume x strength (0..1).
export type MechSounds = {
	hum: Loop,
	servo: Loop,
	powerUp: Cue, -- pilot sits; the hum starts `humDelay` seconds later
	step: Cue,
	hatchOpen: Cue, -- pilot leaves
	hatchClose: Cue, -- pilot sits
	humDelay: number,
	fadeIn: number, -- seconds for the hum to reach full level
	fadeOut: number,
	smoothing: number, -- speed and cadence follow rate, per second
}

-- Asset ids are Roblox store ids. Two are by Roblox; the rest are the Pro Sound Effects library
-- (creator ProSoundEffects, 7462895450). `duration` is the file length in seconds.
local PALETTE: { [string]: { id: number, duration: number } } = {
	-- Weapons
	SWISH_SWORD = { id = 9120742716, duration = 0.8 },
	SWISH_HEAVY = { id = 9113305107, duration = 0.9 },
	SWISH_THIN = { id = 9113610400, duration = 0.5 },
	SWISH_POLE = { id = 9126014253, duration = 0.9 },
	SWISH_WIDE = { id = 9126229927, duration = 1.4 },
	SWISH_PLASMA = { id = 9117406326, duration = 2.0 },
	HIT_BLADE = { id = 9119746592, duration = 1.4 },
	HIT_BLUNT = { id = 9117969892, duration = 1.8 },
	HIT_CLANG = { id = 9125595554, duration = 1.4 },
	HIT_SOFT = { id = 9113520887, duration = 0.9 },
	SQUEAK = { id = 9120222115, duration = 1.7 },
	BOING = { id = 9113854388, duration = 1.0 },
	ICE_CRACKLE = { id = 9125611419, duration = 2.5 },
	PISTOL = { id = 9114720234, duration = 2.8 },
	SMG = { id = 9114714603, duration = 2.8 },
	REVOLVER = { id = 9118163044, duration = 3.1 },
	MAGNUM = { id = 9117402631, duration = 2.5 },
	SHOTGUN = { id = 9114706864, duration = 4.4 },
	RIFLE = { id = 9113185628, duration = 3.8 },
	SNIPER = { id = 9118173988, duration = 3.5 },
	MINIGUN = { id = 9116923526, duration = 3.5 },
	CROSSBOW = { id = 9114003328, duration = 1.4 },
	ARROW_HIT = { id = 9113161827, duration = 1.0 },
	LASER = { id = 9119767682, duration = 1.9 },
	LASER_B = { id = 9119769683, duration = 2.4 },
	RAYGUN = { id = 9118792338, duration = 2.1 },
	SCIFI_B = { id = 9118792537, duration = 1.7 },
	TESLA = { id = 9119992532, duration = 1.4 },
	ZAP = { id = 9116275998, duration = 1.3 },
	PLASMA_FIRE = { id = 9114315137, duration = 2.4 },
	ROCKET_LAUNCH = { id = 12222132, duration = 1.0 },
	ROCKET_SMALL = { id = 12222065, duration = 2.0 },
	GRENADE_THUMP = { id = 9114659666, duration = 1.6 },
	MORTAR_LAUNCH = { id = 9125698534, duration = 3.5 },
	EXPL_SMALL = { id = 9114086657, duration = 3.5 },
	EXPL_MED = { id = 9116973611, duration = 1.4 },
	EXPL_LARGE = { id = 9114363548, duration = 4.6 },
	ROCK_SLAM = { id = 9119037874, duration = 0.8 },
	FIRE_WHOOSH = { id = 9114463410, duration = 1.9 },
	FIRE_POOF = { id = 9125616715, duration = 1.5 },
	FIREBALL_BY = { id = 9114428740, duration = 4.0 },
	THUNDER = { id = 9120021818, duration = 6.4 },
	CHIME = { id = 9116395089, duration = 2.9 },
	FAIRY = { id = 9114369623, duration = 4.5 },
	TELEPORT = { id = 9116227010, duration = 0.8 },
	AIR_BLAST = { id = 9125577419, duration = 2.1 },
	VORTEX_CAST = { id = 9120749129, duration = 1.0 },
	VORTEX_LOOP = { id = 9120183454, duration = 4.6 },
	BUBBLE = { id = 9112753050, duration = 1.2 },
	POP = { id = 9117848931, duration = 0.9 },
	CORK_POP = { id = 9119669295, duration = 0.6 },
	SLINGSHOT = { id = 9119215650, duration = 3.5 },
	SNOW_HIT = { id = 9119313205, duration = 1.1 },
	BALLOON_SPLASH = { id = 9120496285, duration = 1.6 },
	AIR_POP = { id = 9113051587, duration = 1.9 },
	SPLAT = { id = 9113663393, duration = 1.3 },
	SLIDE_WHISTLE = { id = 9119198140, duration = 1.4 },
	-- Vehicles
	ENG_V8 = { id = 9112734732, duration = 90.5 },
	ENG_HOTROD = { id = 9114833668, duration = 77.6 },
	ENG_LUX = { id = 9112919269, duration = 91.7 },
	ENG_F1 = { id = 9112782019, duration = 36.0 },
	ENG_KART = { id = 9112787430, duration = 27.0 },
	ENG_KART_EXH = { id = 9112787844, duration = 50.1 },
	ENG_UTILITY = { id = 9112786418, duration = 36.0 },
	ENG_SEMI = { id = 9112736109, duration = 46.0 },
	ENG_BUS = { id = 9112886237, duration = 27.0 },
	ENG_DIESEL = { id = 9112735376, duration = 111.8 },
	ENG_TRAIN = { id = 9112769417, duration = 36.4 },
	MOTOR_WHINE = { id = 9112908932, duration = 31.7 },
	TRACKS = { id = 9113763481, duration = 5.7 },
	START_GAS = { id = 9112983172, duration = 2.1 },
	START_DIESEL = { id = 9125347271, duration = 3.7 },
	START_EV = { id = 9125981170, duration = 1.8 },
	-- Titan Mech
	MECH_HUM = { id = 9112889082, duration = 36.0 }, -- Transformer Hum 1: steady buzz, loop
	MECH_SERVO = { id = 9112838167, duration = 36.0 }, -- Oil Pump Rhythmic Whine Whir 1: loop
	MECH_POWER_UP = { id = 9114583503, duration = 4.9 }, -- Giant Servo Motor Powering Up 2
	MECH_STEP = { id = 9116478399, duration = 1.4 }, -- Massive Footstep Impact 22
	MECH_CLANK = { id = 9118240078, duration = 1.5 }, -- Robot Footsteps Large Metal Clunks Heavy 1
	MECH_HATCH = { id = 9113059983, duration = 1.7 }, -- Air Chuff Hydraulic Pneumatic Air Burst 5
}

-- Roll-off distances in studs (RollOffMode InverseTapered).
local RANGES: { [string]: { number } } = {
	melee = { 5, 60 }, -- swings, hits, silly hits, heal, bubble
	small = { 8, 150 }, -- small arms, blasters, magic casts, crossbow, slingshot
	heavy = { 10, 250 }, -- shotguns, sniper, minigun, launchers
	explosion = { 15, 350 }, -- small and medium explosions, thunder, black hole
	large = { 25, 500 }, -- mini nuke, meteor
	engine = { 10, 120 },
	tracks = { 8, 90 },
	footfall = { 12, 160 }, -- mech steps; VehicleSounds drops a vehicle's sounds at 160
}

-- Effects. Every gain is set because EqualizerSoundEffect defaults to Low −20, Mid −10.
local function eq(low: number, mid: number, high: number): Effect
	return { class = "EqualizerSoundEffect", LowGain = low, MidGain = mid, HighGain = high }
end

local function chorus(mix: number, depth: number, rate: number): Effect
	return { class = "ChorusSoundEffect", Mix = mix, Depth = depth, Rate = rate }
end

local function reverb(decay: number, wet: number): Effect
	return { class = "ReverbSoundEffect", DecayTime = decay, WetLevel = wet, DryLevel = 0 }
end

local function distortion(level: number): Effect
	return { class = "DistortionSoundEffect", Level = level }
end

local GROUPS: { [string]: { volume: number, effects: { Effect } } } = {
	Weapons = {
		volume = 0.6,
		effects = {
			{
				class = "CompressorSoundEffect",
				Threshold = -18,
				Ratio = 3,
				Attack = 0.005,
				Release = 0.15,
				GainMakeup = 0,
			},
		},
	},
	Vehicles = { volume = 0.5, effects = { eq(0, 0, -3) } },
}

-- Jitter defaults: { pitch, volume }.
local J = {
	semi = { 0.04, 0.10 },
	auto = { 0.06, 0.20 },
	melee = { 0.07, 0.15 },
	boom = { 0.05, 0.10 },
	silly = { 0.10, 0.15 },
}

-- Fills a cue's range and jitter unless it sets its own.
local function class(range: string, jitter: { number }): (Cue) -> Cue
	return function(cue: Cue): Cue
		cue.range = cue.range or range
		cue.jitter = cue.jitter or jitter
		return cue
	end
end

local MELEE = class("melee", J.melee)
local SEMI = class("small", J.semi)
local AUTO = class("small", J.auto)
local HEAVY = class("heavy", J.semi)
local BOOM = class("explosion", J.boom)
local LARGE = class("large", J.boom)
local SILLY = class("melee", J.silly)

local WEAPONS: { [string]: WeaponSounds } = {
	-- Blades
	knight_sword = {
		fire = MELEE({ key = "SWISH_SWORD", volume = 0.25 }),
		hit = MELEE({ key = "HIT_BLADE", volume = 0.28 }),
	},
	katana = {
		fire = MELEE({ key = "SWISH_THIN", volume = 0.24, pitch = 0.95, effects = { eq(0, 0, 2) } }),
		hit = MELEE({ key = "HIT_BLADE", volume = 0.25, pitch = 1.15 }),
	},
	battle_axe = {
		fire = MELEE({ key = "SWISH_HEAVY", volume = 0.28, pitch = 0.8 }),
		hit = MELEE({
			key = "HIT_BLUNT",
			volume = 0.32,
			pitch = 0.85,
			layers = { { key = "HIT_BLADE", volume = 0.15, pitch = 0.75 } },
		}),
	},
	war_hammer = {
		fire = MELEE({ key = "SWISH_HEAVY", volume = 0.28, pitch = 0.7 }),
		hit = MELEE({ key = "HIT_BLUNT", volume = 0.35, pitch = 0.75, effects = { eq(4, 0, 0) } }),
	},
	spear = {
		fire = MELEE({ key = "SWISH_POLE", volume = 0.48, pitch = 1.1 }),
		hit = MELEE({ key = "HIT_BLUNT", volume = 0.25, pitch = 1.2 }),
	},
	scythe = {
		fire = MELEE({
			key = "SWISH_WIDE",
			volume = 0.25,
			pitch = 0.85,
			stopAfter = 1.0,
			fade = 0.2,
		}),
		hit = MELEE({ key = "HIT_BLADE", volume = 0.26, pitch = 0.9 }),
	},
	plasma_blade = {
		fire = MELEE({
			key = "SWISH_PLASMA",
			volume = 0.24,
			stopAfter = 0.8,
			fade = 0.2,
			effects = { chorus(0.4, 0.15, 1.5) },
		}),
		hit = MELEE({
			key = "HIT_BLADE",
			volume = 0.22,
			pitch = 0.8,
			layers = { { key = "ZAP", volume = 0.12, pitch = 1.3 } },
		}),
	},
	ice_dagger = {
		fire = MELEE({ key = "SWISH_THIN", volume = 0.2, pitch = 1.2, jitter = { 0.08, 0.2 } }),
		hit = MELEE({
			key = "ICE_CRACKLE",
			volume = 0.18,
			pitch = 1.4,
			stopAfter = 0.5,
			fade = 0.15,
		}),
	},
	trident = {
		fire = MELEE({ key = "SWISH_POLE", volume = 0.5, pitch = 0.95 }),
		hit = MELEE({ key = "HIT_BLUNT", volume = 0.26, pitch = 1.05 }),
	},
	frying_pan = {
		fire = MELEE({ key = "SWISH_HEAVY", volume = 0.22, pitch = 1.15 }),
		hit = MELEE({ key = "HIT_CLANG", volume = 0.32, pitch = 0.85, effects = { eq(0, 2, 0) } }),
	},

	-- Guns
	pistol = {
		fire = SEMI({ key = "PISTOL", volume = 0.32, stopAfter = 0.9, fade = 0.3 }),
	},
	revolver = {
		fire = SEMI({ key = "REVOLVER", volume = 0.38, pitch = 0.95, stopAfter = 1.2, fade = 0.4 }),
	},
	golden_pistol = {
		fire = SEMI({
			key = "MAGNUM",
			volume = 0.4,
			pitch = 0.95,
			stopAfter = 1.2,
			fade = 0.4,
			effects = { eq(0, 0, 1) },
		}),
	},
	shotgun = {
		-- The full file: the shot, then the pump.
		fire = HEAVY({ key = "SHOTGUN", volume = 0.45 }),
	},
	double_barrel = {
		-- Cut before the pump.
		fire = HEAVY({
			key = "SHOTGUN",
			volume = 0.5,
			pitch = 0.88,
			stopAfter = 0.9,
			fade = 0.3,
			effects = { eq(3, 0, 0) },
		}),
	},
	smg = {
		pool = 3,
		fire = AUTO({ key = "SMG", volume = 0.2, pitch = 1.12, stopAfter = 0.35, fade = 0.1 }),
	},
	assault_rifle = {
		pool = 3,
		fire = AUTO({
			key = "RIFLE",
			volume = 0.22,
			jitter = { 0.05, 0.2 },
			stopAfter = 0.5,
			fade = 0.15,
		}),
	},
	sniper = {
		fire = HEAVY({
			key = "SNIPER",
			volume = 0.55,
			jitter = { 0.02, 0.05 },
			stopAfter = 2.0,
			fade = 0.6,
			effects = { reverb(1.8, -14) },
		}),
	},
	minigun = {
		-- The file is a 3 s continuous blast; hold it while the trigger is down.
		sustain = { release = 0.12, fade = 0.08, loopAt = 3.2, loopTo = 0.6 },
		fire = HEAVY({ key = "MINIGUN", volume = 0.22, jitter = { 0.03, 0 }, start = 0.15 }),
	},
	crossbow = {
		fire = SEMI({ key = "CROSSBOW", volume = 0.3 }),
		impact = SEMI({ key = "ARROW_HIT", volume = 0.25, stopAfter = 0.7, fade = 0.2 }),
	},

	-- Blasters
	laser_pistol = {
		fire = SEMI({ key = "LASER", volume = 0.28, pitch = 1.15, stopAfter = 0.6, fade = 0.2 }),
	},
	laser_rifle = {
		pool = 3,
		fire = AUTO({ key = "LASER_B", volume = 0.18, pitch = 1.3, stopAfter = 0.35, fade = 0.1 }),
	},
	ray_gun = {
		fire = SEMI({
			key = "RAYGUN",
			volume = 0.3,
			pitch = 1.05,
			stopAfter = 0.9,
			fade = 0.3,
			effects = { chorus(0.3, 0.15, 0.5) },
		}),
	},
	freeze_ray = {
		fire = SEMI({ key = "SCIFI_B", volume = 0.28, pitch = 1.25, effects = { eq(-4, 0, 3) } }),
		hit = SEMI({ key = "ICE_CRACKLE", volume = 0.25, stopAfter = 1.4, fade = 0.4 }),
	},
	tesla_gun = {
		fire = SEMI({ key = "TESLA", volume = 0.3 }),
		chain = SEMI({ key = "ZAP", volume = 0.18, pitch = 1.1, jitter = { 0.08, 0.2 } }),
	},
	bounce_ray = {
		fire = SEMI({ key = "SCIFI_B", volume = 0.25, pitch = 0.9 }),
		hit = SEMI({ key = "BOING", volume = 0.25 }),
	},
	plasma_cannon = {
		fire = HEAVY({ key = "PLASMA_FIRE", volume = 0.35, pitch = 0.9 }),
		impact = BOOM({
			key = "EXPL_SMALL",
			volume = 0.4,
			pitch = 1.2,
			stopAfter = 1.5,
			fade = 0.5,
			layers = { { key = "ZAP", volume = 0.18, pitch = 0.8 } },
		}),
	},

	-- Explosives
	rocket_launcher = {
		fire = HEAVY({ key = "ROCKET_LAUNCH", volume = 0.42 }),
		impact = BOOM({ key = "EXPL_MED", volume = 0.5 }),
	},
	bazooka = {
		fire = HEAVY({
			key = "ROCKET_LAUNCH",
			volume = 0.48,
			pitch = 0.82,
			effects = { eq(3, 0, 0) },
		}),
		impact = BOOM({
			key = "EXPL_MED",
			volume = 0.58,
			pitch = 0.85,
			layers = { { key = "EXPL_SMALL", volume = 0.25, pitch = 0.8, stopAfter = 1.5 } },
		}),
	},
	grenade_launcher = {
		-- The file holds two shots; keep the first.
		fire = HEAVY({ key = "GRENADE_THUMP", volume = 0.4, stopAfter = 0.55, fade = 0.1 }),
		impact = BOOM({
			key = "EXPL_SMALL",
			volume = 0.45,
			pitch = 0.95,
			stopAfter = 1.8,
			fade = 0.6,
		}),
	},
	missile_swarm = {
		-- One launch per trigger; each of the five rockets plays its own impact.
		fire = HEAVY({ key = "ROCKET_LAUNCH", volume = 0.4, pitch = 1.25 }),
		impact = BOOM({
			key = "EXPL_SMALL",
			volume = 0.3,
			pitch = 1.2,
			jitter = { 0.08, 0.2 },
			stopAfter = 1.2,
			fade = 0.4,
		}),
	},
	firework_launcher = {
		fire = HEAVY({ key = "ROCKET_SMALL", volume = 0.3, pitch = 1.35 }),
		impact = BOOM({
			key = "EXPL_SMALL",
			volume = 0.32,
			pitch = 1.45,
			stopAfter = 0.8,
			fade = 0.3,
			layers = { { key = "FIRE_POOF", volume = 0.2, pitch = 1.3 } },
		}),
	},
	bomb = {
		fire = MELEE({ key = "SWISH_WIDE", volume = 0.22, pitch = 0.8 }),
		impact = BOOM({ key = "EXPL_MED", volume = 0.55, pitch = 0.92 }),
	},
	mini_nuke = {
		fire = HEAVY({ key = "MORTAR_LAUNCH", volume = 0.45, pitch = 0.9 }),
		impact = LARGE({
			key = "EXPL_LARGE",
			volume = 0.8,
			pitch = 0.7,
			jitter = { 0.03, 0.05 },
			effects = { reverb(3.5, -10) },
			layers = { { key = "EXPL_MED", volume = 0.4, pitch = 0.6 } },
		}),
	},

	-- Magic
	fire_staff = {
		fire = SEMI({ key = "FIRE_WHOOSH", volume = 0.26 }),
		impact = BOOM({ key = "FIRE_POOF", volume = 0.32 }),
	},
	ice_wand = {
		fire = SEMI({ key = "CHIME", volume = 0.22, pitch = 1.25, stopAfter = 1.0, fade = 0.4 }),
		impact = SEMI({
			key = "ICE_CRACKLE",
			volume = 0.28,
			pitch = 0.9,
			stopAfter = 1.6,
			fade = 0.5,
		}),
	},
	lightning_staff = {
		fire = SEMI({ key = "ZAP", volume = 0.16, pitch = 1.2 }),
		-- Cut before the rain tail.
		strike = BOOM({
			key = "THUNDER",
			volume = 0.55,
			pitch = 1.05,
			jitter = { 0.06, 0.1 },
			stopAfter = 2.8,
			fade = 0.8,
		}),
	},
	meteor_staff = {
		fire = SEMI({ key = "FIRE_WHOOSH", volume = 0.22, pitch = 0.8 }),
		-- Rides the falling rock; `start` puts the pass-by peak near the 0.7 s arrival.
		fall = BOOM({ key = "FIREBALL_BY", volume = 0.35, pitch = 1.2, start = 0.6 }),
		strike = LARGE({
			key = "EXPL_MED",
			volume = 0.6,
			pitch = 0.75,
			layers = { { key = "ROCK_SLAM", volume = 0.35, pitch = 0.8 } },
		}),
	},
	healing_staff = {
		fire = MELEE({
			key = "FAIRY",
			volume = 0.22,
			pitch = 1.1,
			jitter = { 0, 0.1 },
			stopAfter = 1.6,
			fade = 0.6,
		}),
	},
	teleport_wand = {
		blinkFrom = SEMI({ key = "TELEPORT", volume = 0.25 }),
		blinkTo = SEMI({ key = "TELEPORT", volume = 0.25, pitch = 1.25 }),
	},
	gravity_gauntlet = {
		fire = HEAVY({
			key = "AIR_BLAST",
			volume = 0.32,
			pitch = 0.85,
			stopAfter = 1.2,
			fade = 0.4,
		}),
	},
	black_hole = {
		fire = SEMI({ key = "VORTEX_CAST", volume = 0.28, pitch = 0.75 }),
		-- Rides the core; at pitch 0.7 the file outlasts the core's 3 s life.
		loop = BOOM({ key = "VORTEX_LOOP", volume = 0.4, pitch = 0.7 }),
		finish = BOOM({ key = "EXPL_MED", volume = 0.5, pitch = 0.6 }),
	},
	bubble_wand = {
		fire = SEMI({ key = "BUBBLE", volume = 0.22 }),
		impact = MELEE({ key = "POP", volume = 0.22, pitch = 0.8 }),
	},

	-- Silly
	rubber_chicken = {
		fire = SILLY({ key = "SWISH_POLE", volume = 0.4, pitch = 1.2 }),
		hit = SILLY({
			key = "SQUEAK",
			volume = 0.28,
			jitter = { 0.12, 0.15 },
			stopAfter = 0.9,
			fade = 0.3,
			layers = { { key = "HIT_SOFT", volume = 0.18 } },
		}),
	},
	pool_noodle = {
		fire = SILLY({ key = "SWISH_POLE", volume = 0.4, pitch = 0.8 }),
		hit = SILLY({
			key = "HIT_SOFT",
			volume = 0.2,
			pitch = 0.8,
			layers = { { key = "BOING", volume = 0.18, pitch = 0.9 } },
		}),
	},
	giant_lollipop = {
		fire = SILLY({ key = "SWISH_HEAVY", volume = 0.22, pitch = 1.1 }),
		hit = SILLY({ key = "HIT_BLUNT", volume = 0.25, pitch = 1.3, effects = { eq(0, 0, 2) } }),
	},
	slingshot = {
		-- start and stopAfter bracket the release inside a stretch-then-release file.
		fire = SILLY({
			key = "SLINGSHOT",
			volume = 0.25,
			pitch = 1.1,
			range = "small",
			start = 0,
			stopAfter = 1.2,
			fade = 0.3,
		}),
	},
	snowball = {
		fire = SILLY({ key = "SWISH_THIN", volume = 0.18, pitch = 0.85 }),
		impact = SILLY({ key = "SNOW_HIT", volume = 0.25 }),
	},
	water_balloon = {
		fire = SILLY({ key = "SWISH_THIN", volume = 0.18, pitch = 0.7 }),
		impact = SILLY({ key = "BALLOON_SPLASH", volume = 0.32, range = "small" }),
	},
	tomato_launcher = {
		pool = 3,
		fire = AUTO({
			key = "AIR_POP",
			volume = 0.2,
			pitch = 1.2,
			jitter = { 0.08, 0.2 },
			stopAfter = 0.4,
			fade = 0.1,
		}),
		impact = SILLY({
			key = "SPLAT",
			volume = 0.22,
			pitch = 1.1,
			jitter = { 0.12, 0.2 },
			range = "small",
		}),
	},
	banana_launcher = {
		fire = SILLY({
			key = "AIR_POP",
			volume = 0.24,
			pitch = 0.85,
			range = "small",
			stopAfter = 0.6,
			fade = 0.2,
		}),
		trap = SILLY({
			key = "SLIDE_WHISTLE",
			volume = 0.2,
			layers = { { key = "HIT_SOFT", volume = 0.15 } },
		}),
	},
	confetti_cannon = {
		fire = SILLY({
			key = "CORK_POP",
			volume = 0.32,
			pitch = 0.7,
			range = "heavy",
			layers = { { key = "AIR_BLAST", volume = 0.18, pitch = 1.3, stopAfter = 0.8 } },
		}),
	},
}

-- Vehicles ------------------------------------------------------------------------------------

local function engine(
	key: string,
	pitch: { number },
	volume: { number },
	effects: { Effect }?
): Loop
	return { key = key, pitch = pitch, volume = volume, effects = effects }
end

-- Track clatter: silent at rest, pitch 0.7 → 1.2 times `scale`.
local function tracks(max: number, scale: number): Loop
	return {
		key = "TRACKS",
		pitch = { 0.7 * scale, 1.2 * scale },
		volume = { 0, max },
		curve = 1,
		range = "tracks",
	}
end

local function start(key: string, pitch: number?, volume: number?): Cue
	return { key = key, pitch = pitch, volume = volume or 0.25 }
end

-- Keyed by VehicleCatalog id. `mech` uses MECH below.
local VEHICLES: { [string]: VehicleSounds } = {
	-- Off-road and utility
	jeep = {
		engine = engine("ENG_V8", { 0.80, 1.30 }, { 0.14, 0.32 }, { eq(2, 0, 0) }),
		start = start("START_GAS"),
	},
	raptor = {
		engine = engine(
			"ENG_V8",
			{ 0.72, 1.32 },
			{ 0.16, 0.38 },
			{ eq(3, 0, 0), distortion(0.05) }
		),
		start = start("START_GAS"),
	},
	gwagon = {
		engine = engine("ENG_V8", { 0.78, 1.35 }, { 0.15, 0.36 }, { eq(2, 0, 1) }),
		start = start("START_GAS"),
	},
	cybertruck = {
		engine = engine("MOTOR_WHINE", { 0.60, 1.60 }, { 0.06, 0.26 }, { eq(-4, 0, 0) }),
		start = start("START_EV", nil, 0.15),
	},
	monster = {
		engine = engine(
			"ENG_HOTROD",
			{ 0.62, 1.05 },
			{ 0.18, 0.42 },
			{ eq(5, 0, 0), distortion(0.08) }
		),
		start = start("START_GAS", 0.8),
	},
	buggy = {
		engine = engine("ENG_KART", { 0.70, 1.30 }, { 0.14, 0.34 }, { eq(2, 0, 0) }),
	},
	snowcat = {
		engine = engine("ENG_DIESEL", { 0.80, 1.15 }, { 0.16, 0.32 }),
		layers = { tracks(0.14, 0.85) },
		start = start("START_DIESEL"),
	},
	lunar_rover = {
		engine = engine("MOTOR_WHINE", { 1.10, 1.80 }, { 0.04, 0.16 }, {
			{ class = "TremoloSoundEffect", Depth = 0.15, Frequency = 6, Duty = 0.5 },
		}),
		start = start("START_EV", 1.2, 0.12),
	},
	-- Speed
	f1 = {
		engine = engine("ENG_F1", { 0.80, 1.50 }, { 0.14, 0.40 }, { eq(-1, 0, 0) }),
	},
	nascar = {
		engine = engine("ENG_HOTROD", { 0.85, 1.45 }, { 0.16, 0.40 }, { distortion(0.06) }),
		start = start("START_GAS"),
	},
	rally = {
		engine = engine("ENG_KART_EXH", { 0.55, 1.10 }, { 0.14, 0.36 }, { eq(3, 0, 0) }),
		start = start("START_GAS", 1.1),
	},
	lamborghini = {
		engine = engine("ENG_F1", { 0.70, 1.30 }, { 0.15, 0.40 }, { eq(2, 0, 0) }),
		start = start("START_GAS", 1.15),
	},
	bugatti = {
		engine = engine("ENG_V8", { 0.85, 1.60 }, { 0.12, 0.36 }, { eq(3, 0, -2) }),
		start = start("START_GAS", 0.9),
	},
	kart = {
		engine = engine("ENG_KART", { 0.90, 1.60 }, { 0.10, 0.28 }),
	},
	motorcycle = {
		engine = engine("ENG_KART_EXH", { 1.00, 2.00 }, { 0.12, 0.32 }, { eq(0, 0, 2) }),
		start = start("START_GAS", 1.4, 0.2),
	},
	-- Classics and luxury
	phantom = {
		engine = engine("ENG_LUX", { 0.80, 1.25 }, { 0.08, 0.20 }, { eq(0, 0, -4) }),
	},
	muscle = {
		engine = engine("ENG_HOTROD", { 0.75, 1.35 }, { 0.18, 0.42 }, { eq(3, 0, 0) }),
		start = start("START_GAS"),
	},
	delorean = {
		engine = engine("ENG_V8", { 0.90, 1.40 }, { 0.12, 0.30 }, { eq(-2, 0, 0) }),
		start = start("START_GAS", 1.1),
	},
	vwbus = {
		engine = engine("ENG_UTILITY", { 0.75, 1.25 }, { 0.12, 0.30 }),
		start = start("START_GAS", 1.2),
	},
	-- City and service
	taxi = {
		engine = engine("ENG_V8", { 0.80, 1.25 }, { 0.12, 0.30 }),
		start = start("START_GAS"),
	},
	police = {
		engine = engine("ENG_V8", { 0.80, 1.40 }, { 0.14, 0.36 }, { eq(1, 0, 0) }),
		start = start("START_GAS"),
	},
	ambulance = {
		engine = engine("ENG_SEMI", { 1.00, 1.50 }, { 0.12, 0.30 }, { eq(-2, 0, 0) }),
		start = start("START_DIESEL", 1.1),
	},
	fire_truck = {
		engine = engine("ENG_SEMI", { 0.85, 1.30 }, { 0.16, 0.38 }, { eq(2, 0, 0) }),
		start = start("START_DIESEL"),
	},
	school_bus = {
		engine = engine("ENG_BUS", { 0.80, 1.25 }, { 0.14, 0.34 }),
		start = start("START_DIESEL"),
	},
	ice_cream = {
		engine = engine("ENG_BUS", { 0.90, 1.35 }, { 0.12, 0.30 }),
		start = start("START_DIESEL", 1.1),
	},
	semi = {
		engine = engine("ENG_SEMI", { 0.80, 1.20 }, { 0.18, 0.42 }, { eq(3, 0, 0) }),
		start = start("START_DIESEL", 0.85),
	},
	tractor = {
		engine = engine("ENG_UTILITY", { 0.60, 0.95 }, { 0.14, 0.30 }, { eq(4, 0, 0) }),
		start = start("START_DIESEL", 0.9),
	},
	bulldozer = {
		engine = engine("ENG_DIESEL", { 0.75, 1.05 }, { 0.18, 0.34 }, { eq(3, 0, 0) }),
		layers = { tracks(0.18, 0.75) },
		start = start("START_DIESEL", 0.8),
	},
	-- Military
	humvee = {
		engine = engine("ENG_SEMI", { 1.00, 1.50 }, { 0.14, 0.34 }),
		start = start("START_DIESEL"),
	},
	stryker = {
		engine = engine("ENG_DIESEL", { 0.85, 1.25 }, { 0.18, 0.38 }, { eq(2, 0, 0) }),
		start = start("START_DIESEL", 0.9),
	},
	abrams = {
		engine = engine("ENG_TRAIN", { 0.90, 1.30 }, { 0.16, 0.36 }, { eq(3, 0, 0) }),
		layers = {
			-- Turbine whine.
			engine("MOTOR_WHINE", { 1.60, 2.40 }, { 0.05, 0.14 }),
			tracks(0.22, 1),
		},
		start = start("START_EV", 0.6, 0.2),
	},
	tiger = {
		engine = engine("ENG_TRAIN", { 0.70, 1.00 }, { 0.18, 0.36 }, { eq(4, 0, 0) }),
		layers = { tracks(0.22, 0.8) },
		start = start("START_DIESEL", 0.7),
	},
}

-- Engine behavior shared by every vehicle.
local VEHICLE = {
	buildRange = 130, -- studs from the camera to start a vehicle's sounds
	dropRange = 160, -- studs from the camera to remove them
	maxActive = 8, -- nearest vehicles with sounds
	startDelay = 0.6, -- seconds from the start one-shot to the engine loop
	fadeIn = 0.5,
	fadeOut = 0.5,
	smoothing = 5, -- speed follow rate, per second
	loadBump = 0.04, -- extra engine pitch while accelerating
	pitchCurve = 0.8,
	loopStartSpread = 0.6, -- loops start at a random point in the first 60% of the file
}

-- Texture under the visuals: hum and servo sit below every engine idle, steps below small arms.
local MECH: MechSounds = {
	-- A guitar-amp transformer buzz pitched down to a reactor drone; the EQ takes the fizz off.
	hum = {
		key = "MECH_HUM",
		pitch = { 0.55, 0.62 },
		volume = { 0.08, 0.13 },
		curve = 1,
		effects = { eq(3, 0, -8) },
	},
	-- Hydraulic pump whir while the legs move.
	servo = {
		key = "MECH_SERVO",
		pitch = { 0.6, 0.8 },
		volume = { 0, 0.12 },
		curve = 1,
		effects = { eq(0, 0, -4) },
	},
	powerUp = { key = "MECH_POWER_UP", volume = 0.22, pitch = 0.85, jitter = { 0.03, 0 } },
	-- A deep boom with a low metal clunk on top; jitter keeps long walks from repeating.
	step = {
		key = "MECH_STEP",
		volume = 0.38,
		pitch = 0.85,
		jitter = { 0.07, 0.15 },
		range = "footfall",
		effects = { eq(3, 0, -4) },
		layers = { { key = "MECH_CLANK", volume = 0.12, pitch = 0.6 } },
	},
	hatchOpen = { key = "MECH_HATCH", volume = 0.16, jitter = { 0.04, 0.1 } },
	hatchClose = { key = "MECH_HATCH", volume = 0.16, pitch = 0.85, jitter = { 0.04, 0.1 } },
	humDelay = 0.8,
	fadeIn = 1.5,
	fadeOut = 1.0,
	smoothing = 4,
}

-- Combat.explode without a weapon cue (barrels, admin meteors): EXPL_MED, louder for bigger blasts.
local EXPLOSION = { key = "EXPL_MED", base = 0.35, perRadius = 0.01, max = 0.6, jitter = J.boom }

-- Multiplies every sound Combat.explode plays. Roblox's Explosion instance plays its own boom,
-- which no property turns off, so ours sits on top of it at half volume. Set to 1 if the
-- built-in boom turns out to be silent.
local EXPLOSION_GAIN = 0.5

-- Validates keys and fills each layer's range and jitter from its cue.
local function check(cue: Cue?, where: string)
	if not cue then
		return
	end
	assert(PALETTE[cue.key], where .. ": unknown sound " .. cue.key)
	assert(RANGES[cue.range or "small"], where .. ": unknown range " .. tostring(cue.range))
	for _, layer in cue.layers or {} do
		layer.range = layer.range or cue.range
		layer.jitter = layer.jitter or cue.jitter
		check(layer, where)
	end
end

local WEAPON_EVENTS = {
	"fire",
	"hit",
	"chain",
	"impact",
	"strike",
	"fall",
	"loop",
	"finish",
	"trap",
	"blinkFrom",
	"blinkTo",
}
for id, entry in WEAPONS do
	for _, event in WEAPON_EVENTS do
		check((entry :: any)[event], id .. "." .. event)
	end
end
for id, entry in VEHICLES do
	for _, loop in { entry.engine, table.unpack(entry.layers or {}) } do
		assert(PALETTE[loop.key], id .. ": unknown sound " .. loop.key)
		loop.range = loop.range or "engine"
	end
	if entry.start then
		entry.start.range = "engine"
		entry.start.jitter = { 0.03, 0 }
		check(entry.start, id .. ".start")
	end
end
for _, loop in { MECH.hum, MECH.servo } do
	assert(PALETTE[loop.key], "mech: unknown sound " .. loop.key)
	loop.range = loop.range or "engine"
end
for _, event in { "powerUp", "step", "hatchOpen", "hatchClose" } do
	local cue = (MECH :: any)[event] :: Cue
	cue.range = cue.range or "engine"
	check(cue, "mech." .. event)
end

return {
	PALETTE = PALETTE,
	RANGES = RANGES,
	GROUPS = GROUPS,
	WEAPONS = WEAPONS,
	WEAPON_EVENTS = WEAPON_EVENTS,
	VEHICLES = VEHICLES,
	VEHICLE = VEHICLE,
	MECH = MECH,
	EXPLOSION = EXPLOSION,
	EXPLOSION_GAIN = EXPLOSION_GAIN,
}
