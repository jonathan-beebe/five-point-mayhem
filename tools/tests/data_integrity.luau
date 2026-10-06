-- Checks the game's data tables against each other and against the model files, outside Roblox.
-- Usage: lune run tools/tests/data_integrity.luau
--
--   - catalogs: unique ids of letters, digits and underscores, names; weapon categories, kinds,
--     shapes, effects, impacts and styles the server handles (and WeaponCatalog's header
--     documents), fields only other kinds read, a positive cooldown
--   - every weapon, vehicle and creature kind has a model file, and every model file has an entry
--   - every model file passes its define() (on a copy) and tools/lib/ModelChecks
--   - walkers: the catalog's mech flag matches the model's gait "mech"
--   - every vehicle model sets acceleration, braking and coasting (VehicleDefaults' mapping)
--   - sounds: every weapon and vehicle has its SoundCatalog entry (walkers in MECHS), no entry
--     names an unknown id, pooled weapons are automatic, every walker's cues are complete
--   - regions: every Config.REGIONS id has a building, ground, trees, a themed monster and a lair
--
-- The catalogs, Config, CreatureCatalog, the world's Regions data, Weapons/FallbackModels and the
-- model files load through Sandbox, the data modules by the instance paths the game requires them
-- by. The weapon kinds (kinds/init FIRE), impacts (Projectiles.IMPACTS) and strike styles
-- (kinds/strike STYLES) come from those modules run alone (Sandbox.loadIsolated): their requires
-- build Instances. Combat's effects and Landscape's tree builders
-- are read from their source with narrow matches (`tableKeys`, `compared`) that fail when the code
-- no longer has the shape they expect: Combat.applyEffect is an if chain, and Landscape builds the
-- world when required.

local fs = require("@lune/fs")

local Check = require("../lib/Check")
local ModelChecks = require("../lib/ModelChecks")
local Sandbox = require("../lib/Sandbox")

local check = Check.check

local function sorted(set: { [any]: any }): { any }
	local list = {}
	for key in set do
		table.insert(list, key)
	end
	table.sort(list)
	return list
end

local function describe(set: { [any]: any }): string
	return table.concat(sorted(set), ", ")
end

local function read(path: string): string
	return fs.readFile(Sandbox.ROOT .. "/" .. path)
end

-- Requires a module (a Sandbox instance path); a failure ends the test with its error.
-- `isolated` loads it with Sandbox.loadIsolated instead: for a server module whose requires build
-- Instances (Combat, Effects), to read the tables it defines.
local function requireOrStop(target: any, isolated: boolean?): any
	local ok, result = pcall(if isolated then Sandbox.loadIsolated else Sandbox.require, target)
	if not ok then
		check(false, tostring(target) .. " fails to load: " .. tostring(result))
		Check.finish()
	end
	return result
end

-- Reading server source ---------------------------------------------------------------------

-- The keys of `local NAME ... = { ... }` in a file that cannot load under Lune: the lines one tab
-- deep reading `<key> = <value>` (stylua's layout). Fails if the table is missing, or changes
-- outside its constructor (`NAME.x = ...`, which this read would miss).
local function tableKeys(path: string, name: string, value: string): { [string]: boolean }
	local source = read(path)
	local block = string.match(source, "\nlocal " .. name .. "[^\n]*= {\n(.-)\n}\n")
	check(block ~= nil, path .. ": no `local " .. name .. " = {` table (update this test)")
	local outside = string.match(source, "\n%s*(" .. name .. "[%.%[][^\n]-[^=~<>]=[^=][^\n]*)")
	check(
		outside == nil,
		path .. ": " .. name .. " changes outside its constructor: " .. tostring(outside)
	)
	local keys = {}
	for key in string.gmatch("\n" .. (block or "") .. "\n", "\n\t([%w_]+) = " .. value) do
		keys[key] = true
	end
	return keys
end

-- Every capture of `pattern` inside the first match of `scope` (a pattern for one function) in
-- a file: the values a server comparison chain handles.
local function compared(path: string, scope: string, pattern: string): { [string]: boolean }
	local body = string.match(read(path), scope)
	check(body ~= nil, path .. ": no match for " .. scope .. " (update this test)")
	local values = {}
	for value in string.gmatch(body or "", pattern) do
		values[value] = true
	end
	return values
end

-- Data modules ------------------------------------------------------------------------------

local Shared = Sandbox.game:GetService("ReplicatedStorage").Shared
local Server = Sandbox.game:GetService("ServerScriptService").Server
local WeaponCatalog = requireOrStop(Shared.WeaponCatalog)
local VehicleCatalog = requireOrStop(Shared.VehicleCatalog)
local SoundCatalog = requireOrStop(Shared.SoundCatalog)
local Config = requireOrStop(Shared.Config)
-- Creatures requires ReplicatedStorage.Shared.CreatureCatalog; init.server script.world.Regions
-- and Landscape script.Parent.Regions.
local CreatureCatalog = requireOrStop(Shared.CreatureCatalog)
local Regions = requireOrStop(Server.world.Regions)

-- Value sets the server handles, from the tables the code dispatches through.
local WEAPONS = "src/server/systems/Weapons/"
local FUNCTION_END = "%(.-\nend\n"
local function keys(table_: { [string]: any }): { [string]: boolean }
	local set = {}
	for key in table_ do
		set[key] = true
	end
	return set
end
-- kinds/init.luau: FIRE, one module per kind.
local FIRE = requireOrStop(Server.systems.Weapons.kinds, true)
local KINDS = keys(FIRE)
-- FallbackModels.SHAPES: the fallback model per shape (loads without stubs).
local SHAPES = keys(requireOrStop(Server.systems.Weapons.FallbackModels).SHAPES)
-- Combat.applyEffect's chain (`if effect == "burn" then`).
local EFFECTS = compared(
	"src/server/systems/Combat.luau",
	"\nfunction Combat%.applyEffect" .. FUNCTION_END,
	'[^%.%w_]effect == "([%w_]+)"'
)
-- Projectiles.IMPACTS: what a projectile does where it lands.
local IMPACTS = keys(requireOrStop(Server.systems.Weapons.Projectiles, true).IMPACTS)
-- kinds/strike.luau STYLES: what a strike calls down.
local STYLES = keys(requireOrStop(Server.systems.Weapons.kinds.strike, true).STYLES)

-- Every module in kinds/ is a kind in FIRE.
do
	Check.section("weapon kinds")
	for _, file in fs.readDir(Sandbox.ROOT .. "/" .. WEAPONS .. "kinds") do
		local kind = string.match(file, "^(.+)%.luau$")
		if kind and kind ~= "init" then
			check(KINDS[kind] ~= nil, WEAPONS .. "kinds/" .. file .. " is not in FIRE (kinds/init)")
		end
	end
end

-- Fields only some kinds read, with the function in systems/Weapons/ that reads each; on any other
-- kind they do nothing.
local KIND_ONLY: { [string]: { [string]: string } } = {
	arc = { melee = "kinds/melee" },
	pellets = { hitscan = "kinds/hitscan" },
	chain = { hitscan = "kinds/hitscan" },
	speed = { projectile = "Projectiles.launch" },
	gravity = { projectile = "Projectiles.launch" },
	blast = { projectile = "Projectiles.impact" },
	count = { projectile = "kinds/projectile" },
	impact = { projectile = "Projectiles.impact" },
	splash = { projectile = "Projectiles.impact" },
	style = { strike = "kinds/strike" },
	radius = { strike = "kinds/strike", projectile = "Projectiles.blackHole" },
}
-- Every weapon's fields without a default (WeaponCatalog's Weapon type), by type.
local WEAPON_FIELDS = {
	id = "string",
	name = "string",
	category = "string",
	kind = "string",
	description = "string",
	damage = "number",
	cooldown = "number",
	range = "number",
	color = "Color3",
	shape = "string",
}

local ID_PATTERN = "^[%w_]+$"

-- The sets WeaponCatalog's header comment documents.
do
	Check.section("WeaponCatalog header")
	local header = string.match(read("src/shared/WeaponCatalog.luau"), "^(.-)\n[^%-]") or ""
	local documented = { kind = {}, effect = {}, impact = {}, style = {} }
	for line in string.gmatch(header, "[^\n]+") do
		local kind = string.match(line, "^%-%-   (%l+) ")
		if kind then
			documented.kind[kind] = true
		end
		local effects = string.match(line, "^%-%- effect: (.+)$")
		for value in string.gmatch(effects or "", "%l+") do
			documented.effect[value] = true
		end
		-- `impact` = "blackhole" | "trap", ...: the quoted values up to a comma or the line's end.
		for _, field in { "impact", "style" } do
			local values = string.match(line, "`" .. field .. "` = ([^,]*)")
			for value in string.gmatch(values or "", '"(%w+)"') do
				documented[field][value] = true
			end
		end
	end
	for field, handled in { kind = KINDS, effect = EFFECTS, impact = IMPACTS, style = STYLES } do
		Check.equal(
			describe(documented[field]),
			describe(handled),
			"WeaponCatalog header documents " .. field .. " values the server handles"
		)
	end
end

-- Checks a catalog list's ids and (unless `nameless`) names; returns the entries by id.
local function checkEntries(label: string, entries: { any }, nameless: boolean?): { [string]: any }
	local byId = {}
	for index, entry in entries do
		local where = label .. " #" .. index
		check(type(entry.id) == "string", where .. ": id must be a string")
		if type(entry.id) ~= "string" then
			continue
		end
		where = label .. " " .. entry.id
		check(string.match(entry.id, ID_PATTERN) ~= nil, where .. ": id must match " .. ID_PATTERN)
		check(byId[entry.id] == nil, where .. ": duplicate id")
		check(
			nameless or (type(entry.name) == "string" and string.match(entry.name, "%S") ~= nil),
			where .. ": needs a name"
		)
		byId[entry.id] = entry
	end
	return byId
end

Check.section("WeaponCatalog")
local CATEGORIES = checkEntries("category", WeaponCatalog.CATEGORIES, true)
local weapons = checkEntries("weapon", WeaponCatalog.ALL)
local used: { [string]: boolean } = {}
for id, weapon in weapons do
	local where = "weapon " .. id
	for field, kind in WEAPON_FIELDS do
		check(typeof(weapon[field]) == kind, where .. ": " .. field .. " must be a " .. kind)
	end
	check(
		CATEGORIES[weapon.category] ~= nil,
		where .. ": unknown category " .. tostring(weapon.category)
	)
	used[weapon.category] = true
	check(KINDS[weapon.kind] ~= nil, where .. ": unknown kind " .. tostring(weapon.kind))
	check(SHAPES[weapon.shape] ~= nil, where .. ": unknown shape " .. tostring(weapon.shape))
	for field, set in { effect = EFFECTS, impact = IMPACTS, style = STYLES } do
		if weapon[field] ~= nil then
			check(
				set[weapon[field]] ~= nil,
				where .. ": unknown " .. field .. " " .. tostring(weapon[field])
			)
		end
	end
	check(
		typeof(weapon.cooldown) == "number" and weapon.cooldown > 0,
		where .. ": cooldown must be positive"
	)
	for field, readers in KIND_ONLY do
		if weapon[field] ~= nil then
			local names = {}
			for kind, reader in readers do
				table.insert(names, kind .. " (" .. reader .. ")")
			end
			table.sort(names)
			check(
				readers[weapon.kind] ~= nil,
				string.format(
					"%s: %s does nothing on a %s weapon; the server reads it only for %s "
						.. "(KIND_ONLY in tools/tests/data_integrity.luau)",
					where,
					field,
					tostring(weapon.kind),
					table.concat(names, ", ")
				)
			)
		end
	end
	if weapon.splash then
		check(weapon.blast ~= nil, where .. ": splash needs a blast radius")
	end
end
for id in CATEGORIES do
	check(used[id] == true, "category " .. id .. " has no weapons")
end

Check.section("VehicleCatalog")
local vehicles = checkEntries("vehicle", VehicleCatalog.ALL)
for id, vehicle in vehicles do
	check(
		type(vehicle.icon) == "string" and vehicle.icon ~= "",
		"vehicle " .. id .. ": needs an icon"
	)
end

-- Model files -------------------------------------------------------------------------------

-- Loads every model file in `folder` by id; a file that fails to load is a failure.
local function loadModels(folder: string): { [string]: any }
	local models = {}
	for _, file in fs.readDir(Sandbox.ROOT .. "/" .. folder) do
		local id = string.match(file, "^(.+)%.luau$")
		if id then
			local ok, spec = pcall(Sandbox.load, folder .. "/" .. file)
			check(ok, folder .. "/" .. file .. " fails to load: " .. tostring(spec))
			models[id] = if ok then spec else false
		end
	end
	return models
end

-- Every catalog id has a model file and every model file a catalog id.
local function checkPairs(label: string, folder: string, ids: { [string]: any }, models)
	for id in ids do
		check(models[id] ~= nil, label .. " " .. id .. " has no " .. folder .. "/" .. id .. ".luau")
	end
	for id in models do
		check(ids[id] ~= nil, folder .. "/" .. id .. ".luau has no " .. label .. " entry")
	end
end

local function checkModels(folder: string, models: { [string]: any }, kind: ModelChecks.Kind)
	for _, id in sorted(models) do
		local spec = models[id]
		if spec then
			local ok, problems = pcall(ModelChecks.check, spec, kind)
			if not ok then
				check(false, folder .. "/" .. id .. ": ModelChecks fails: " .. tostring(problems))
			else
				check(#problems == 0, folder .. "/" .. id .. ": " .. table.concat(problems, "; "))
			end
		end
	end
end

Check.section("weapon models")
local WEAPON_MODELS = "src/server/weaponModels"
local weaponModels = loadModels(WEAPON_MODELS)
checkPairs("weapon", WEAPON_MODELS, weapons, weaponModels)
-- Weapon files run define() themselves; it must also accept its own output (Weapons requires
-- the file and uses the table as is).
local WeaponModel = Sandbox.require("src/server/systems/WeaponModel")
for id, spec in weaponModels do
	if spec then
		local ok, err = pcall(WeaponModel.define, table.clone(spec))
		check(ok, WEAPON_MODELS .. "/" .. id .. ": define fails: " .. tostring(err))
	end
end
checkModels(WEAPON_MODELS, weaponModels, "weapon")

Check.section("vehicle models")
local VEHICLE_MODELS = "src/server/vehicleModels"
local vehicleModels = loadModels(VEHICLE_MODELS)
checkPairs("vehicle", VEHICLE_MODELS, vehicles, vehicleModels)
checkModels(VEHICLE_MODELS, vehicleModels, "vehicle")
for id, vehicle in vehicles do
	local spec = vehicleModels[id]
	if spec then
		check(
			(spec.gait == "mech") == (vehicle.mech == true),
			string.format(
				'vehicle %s: catalog mech = %s but the model\'s gait = %s (mech needs gait "mech")',
				id,
				tostring(vehicle.mech),
				tostring(spec.gait)
			)
		)
		-- Drive tuning comes from the real vehicle (VehicleDefaults' mapping), not the defaults.
		for _, field in { "acceleration", "braking", "coasting" } do
			local value = spec[field]
			check(
				type(value) == "number" and value > 0,
				string.format("vehicle %s: model needs a positive %s", id, field)
			)
		end
	end
end

Check.section("creature models")
local CREATURE_MODELS = "src/server/creatureModels"
local creatureKinds = CreatureCatalog.KINDS
local creatureModels = loadModels(CREATURE_MODELS)
checkPairs("CreatureCatalog kind", CREATURE_MODELS, creatureKinds, creatureModels)
checkModels(CREATURE_MODELS, creatureModels, "creature")
-- One entry per kind: an alias (KINDS.ghoul = KINDS.zombie) would spawn a second kind with the
-- first one's stats and name.
local seen: { [any]: string } = {}
for _, id in sorted(creatureKinds) do
	local kind = creatureKinds[id]
	check(
		seen[kind] == nil,
		"CreatureCatalog.KINDS." .. id .. " is the same table as KINDS." .. tostring(seen[kind])
	)
	seen[kind] = id
end

-- Sounds ------------------------------------------------------------------------------------

Check.section("SoundCatalog")
for id, weapon in weapons do
	local entry = SoundCatalog.WEAPONS[id]
	check(entry ~= nil, "weapon " .. id .. " has no SoundCatalog.WEAPONS entry")
	if entry then
		local events = 0
		for _, event in SoundCatalog.WEAPON_EVENTS do
			if entry[event] then
				events += 1
			end
		end
		check(events > 0, "weapon " .. id .. " has no cues")
		check(
			not entry.pool or weapon.auto == true,
			"weapon " .. id .. " pools its fire sound but is not automatic"
		)
	end
end
for id in SoundCatalog.WEAPONS do
	check(weapons[id] ~= nil, "SoundCatalog.WEAPONS has sounds for unknown weapon " .. id)
end
-- Walkers' sounds come from VehicleSounds' mech handler with their MECHS entry; other vehicles
-- have engine profiles in VEHICLES.
for id, vehicle in vehicles do
	if vehicle.mech then
		check(SoundCatalog.MECHS[id] ~= nil, "walker " .. id .. " has no SoundCatalog.MECHS entry")
	else
		check(
			SoundCatalog.VEHICLES[id] ~= nil,
			"vehicle " .. id .. " has no SoundCatalog.VEHICLES entry"
		)
	end
end
for id in SoundCatalog.VEHICLES do
	check(vehicles[id] ~= nil, "SoundCatalog.VEHICLES has sounds for unknown vehicle " .. id)
	check(
		not SoundCatalog.MECHS[id],
		"vehicle " .. id .. " has both an engine profile and walker sounds"
	)
end
for id in SoundCatalog.MECHS do
	local vehicle = vehicles[id]
	check(
		vehicle ~= nil and vehicle.mech == true,
		"SoundCatalog.MECHS entry " .. id .. " is not a walker"
	)
end

local function checkCue(cue: { [string]: any }?, where: string)
	check(cue ~= nil, where .. " is missing")
	if not cue then
		return
	end
	check(SoundCatalog.PALETTE[cue.key] ~= nil, where .. ": unknown sound " .. tostring(cue.key))
	check(
		SoundCatalog.RANGES[cue.range or "small"] ~= nil,
		where .. ": unknown range " .. tostring(cue.range)
	)
	check(
		typeof(cue.volume) ~= "number" or cue.volume <= 0.5,
		where .. ": volume " .. tostring(cue.volume) .. " is louder than the mech should be"
	)
	for _, layer in cue.layers or {} do
		checkCue(layer, where .. " layer")
	end
end

for id, mech in SoundCatalog.MECHS do
	for _, event in { "powerUp", "step", "hatchOpen", "hatchClose" } do
		checkCue(mech[event], id .. "." .. event)
	end
	if mech.creak then
		checkCue(mech.creak, id .. ".creak")
	end
	for _, name in { "hum", "servo" } do
		local loop = mech[name]
		local known = loop ~= nil and SoundCatalog.PALETTE[loop.key] ~= nil
		check(known, id .. "." .. name .. ": missing or unknown sound")
		if known then
			check(
				#loop.pitch == 2 and #loop.volume == 2,
				id .. "." .. name .. ": pitch and volume need { rest, top speed }"
			)
		end
	end
	check(
		mech.servo ~= nil and mech.servo.volume[1] == 0,
		id .. ".servo must be silent at rest (volume[1] = 0)"
	)
end

-- Regions -----------------------------------------------------------------------------------

Check.section("regions")
local regions: { [string]: boolean } = {}
for _, region in Config.REGIONS do
	regions[region.id] = true
end
local perRegion = {
	["Regions.BUILDINGS"] = Regions.BUILDINGS,
	["Regions.GROUND"] = Regions.GROUND,
	["Regions.TREES"] = Regions.TREES,
	["CreatureCatalog.REGION_KIND"] = CreatureCatalog.REGION_KIND,
	["CreatureCatalog.LAIRS"] = CreatureCatalog.LAIRS,
}
for label, entries in perRegion do
	for id in regions do
		check(entries[id] ~= nil, label .. " has no entry for region " .. id)
	end
	for id in entries do
		check(regions[id] ~= nil, label .. " has an entry for unknown region " .. tostring(id))
	end
end
-- What the region entries name exists.
for id, name in Regions.BUILDINGS do
	-- init.server requires script.world.buildings[name].
	check(
		fs.isFile(Sandbox.ROOT .. "/src/server/world/buildings/" .. tostring(name) .. ".luau"),
		"Regions.BUILDINGS."
			.. id
			.. ": no src/server/world/buildings/"
			.. tostring(name)
			.. ".luau"
	)
end
for id, material in Regions.GROUND do
	check(
		typeof(material) == "EnumItem" and tostring(material.EnumType) == "Enum.Material",
		"Regions.GROUND." .. id .. " must be an Enum.Material"
	)
end
-- Landscape's tree builders: `oak = function(parent, base, s)` lines.
local treeBuilders = tableKeys("src/server/world/Landscape.luau", "TREE_BUILDERS", "function%(")
local styles: { [string]: { string } } = {}
for id, list in Regions.TREES do
	for _, style in list do
		styles[style] = styles[style] or {}
		table.insert(styles[style], id)
	end
end
for _, style in sorted(styles) do
	table.sort(styles[style])
	check(
		treeBuilders[style] ~= nil,
		"Regions.TREES ("
			.. table.concat(styles[style], ", ")
			.. "): Landscape has no TREE_BUILDERS."
			.. style
	)
end
for id, kind in CreatureCatalog.REGION_KIND do
	check(
		creatureKinds[kind] ~= nil,
		"CreatureCatalog.REGION_KIND." .. id .. ": unknown creature kind " .. tostring(kind)
	)
end

print(
	string.format(
		"%d weapons, %d vehicles, %d creature kinds, %d regions",
		#WeaponCatalog.ALL,
		#VehicleCatalog.ALL,
		#sorted(creatureKinds),
		#Config.REGIONS
	)
)
Check.finish()
