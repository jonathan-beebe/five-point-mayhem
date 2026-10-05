-- Checks SoundCatalog against the weapon and vehicle catalogs: every weapon and vehicle has
-- sounds, no entry names an unknown id, pooled weapons are automatic, and every walker's cues are
-- complete.
-- Usage: lune run tools/check-sounds.luau

local fs = require("@lune/fs")
local process = require("@lune/process")

local SoundCatalog = require("../src/shared/SoundCatalog")

-- Walkers: their sounds come from VehicleSounds' mech handler, with their SoundCatalog.MECHS entry.
local CUSTOM_VEHICLES: { [string]: { [string]: any } } = SoundCatalog.MECHS

local problems = {}
local function problem(message: string)
	table.insert(problems, message)
end

-- Weapon entries in WeaponCatalog sit two tabs deep: `\t\tid = "pistol",`.
local weaponSource = fs.readFile("src/shared/WeaponCatalog.luau")
local weapons: { [string]: { auto: boolean } } = {}
local weaponCount = 0
for entry in string.gmatch(weaponSource, "\n\t{\n(.-)\n\t},") do
	local id = string.match(entry, '\t\tid = "([%w_]+)"')
	if id then
		weapons[id] = { auto = string.find(entry, "\t\tauto = true", 1, true) ~= nil }
		weaponCount += 1
	end
end

local vehicleSource = fs.readFile("src/shared/VehicleCatalog.luau")
local vehicles: { [string]: boolean } = {}
local vehicleCount = 0
for id in string.gmatch(vehicleSource, '{ id = "([%w_]+)", name') do
	vehicles[id] = true
	vehicleCount += 1
end

for id, info in weapons do
	local entry = SoundCatalog.WEAPONS[id]
	if not entry then
		problem("weapon " .. id .. " has no sounds")
	else
		local events = 0
		for _, event in SoundCatalog.WEAPON_EVENTS do
			if (entry :: any)[event] then
				events += 1
			end
		end
		if events == 0 then
			problem("weapon " .. id .. " has no cues")
		end
		if entry.pool and not info.auto then
			problem("weapon " .. id .. " pools its fire sound but is not automatic")
		end
	end
end
for id in SoundCatalog.WEAPONS do
	if not weapons[id] then
		problem("sounds for unknown weapon " .. id)
	end
end

local vehicleSounds = 0
for id in vehicles do
	if not CUSTOM_VEHICLES[id] then
		vehicleSounds += 1
		if not SoundCatalog.VEHICLES[id] then
			problem("vehicle " .. id .. " has no sounds")
		end
	end
end
for id in SoundCatalog.VEHICLES do
	if not vehicles[id] then
		problem("sounds for unknown vehicle " .. id)
	end
end
for id in CUSTOM_VEHICLES do
	if not vehicles[id] then
		problem("custom sounds for unknown vehicle " .. id)
	end
end

local function checkCue(cue: { [string]: any }?, where: string)
	if not cue then
		problem(where .. " is missing")
		return
	end
	if not SoundCatalog.PALETTE[cue.key] then
		problem(where .. ": unknown sound " .. tostring(cue.key))
	end
	if not SoundCatalog.RANGES[cue.range or "small"] then
		problem(where .. ": unknown range " .. tostring(cue.range))
	end
	if typeof(cue.volume) == "number" and cue.volume > 0.5 then
		problem(where .. ": volume " .. cue.volume .. " is louder than the mech should be")
	end
	for _, layer in cue.layers or {} do
		checkCue(layer, where .. " layer")
	end
end

for id, mech in SoundCatalog.MECHS do
	for _, event in { "powerUp", "step", "hatchOpen", "hatchClose" } do
		checkCue((mech :: any)[event], id .. "." .. event)
	end
	if mech.creak then
		checkCue(mech.creak, id .. ".creak")
	end
	for _, name in { "hum", "servo" } do
		local loop = (mech :: any)[name]
		if not loop or not SoundCatalog.PALETTE[loop.key] then
			problem(id .. "." .. name .. ": missing or unknown sound")
		elseif #loop.pitch ~= 2 or #loop.volume ~= 2 then
			problem(id .. "." .. name .. ": pitch and volume need { rest, top speed }")
		end
	end
	if mech.servo.volume[1] ~= 0 then
		problem(id .. ".servo must be silent at rest (volume[1] = 0)")
	end
end

local keys = 0
for _ in SoundCatalog.PALETTE do
	keys += 1
end

print(
	string.format(
		"%d weapons, %d vehicles (%d with engine profiles), %d palette sounds",
		weaponCount,
		vehicleCount,
		vehicleSounds,
		keys
	)
)
if #problems > 0 then
	for _, message in problems do
		print("  " .. message)
	end
	process.exit(1)
end
print("ok")
