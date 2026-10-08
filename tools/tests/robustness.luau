-- Checks that one broken piece of server work does not stop the server, outside Roblox: each
-- module runs with recording fakes behind its requires (shared modules and Guard real), a
-- recording `warn`, and a fake `task` that keeps spawned loops for the test to step.
-- Usage: lune run tools/tests/robustness.luau
--
--   - Creatures: a creature model file that throws when required is warned (file and error) and
--     skipped; the module loads, start() spawns every other kind's roaming and themed counts, and
--     the admin horde never picks the broken kind. The think and lair loops start before the
--     spawns (a spawn error leaves them running), each waiting its interval before its first
--     pass, as before. A respawn whose build throws is warned
--   - Vehicles/Parking: a vehicle whose build throws is warned and its spot left empty; layOut
--     parks every other catalog vehicle, after PodFlight.start; the respawn loop's next pass
--     parks the empty spot once the build works. The respawn loop starts after PodFlight.start
--     and before layOut (a layOut error leaves it running), waiting RESPAWN_INTERVAL first
--   - Weapons/Firing: a weapon whose kind has no FIRE entry fires nothing, raises nothing, and
--     warns once per kind
--   - world/Lamps: a lamp whose build throws is warned; every other lamp is built and tagged, and
--     every other lit lamp gets its light
--   - init.server.luau: a system whose start() throws is warned; every later start runs, in boot
--     order, and CharacterAutoLoads is turned back on
--   - no endless loop in src/server outside util/Guard (`while true do`, `while task.wait(...)`,
--     `repeat ... until false`, comments ignored): background loops go through Guard.loop
--     (tools/tests/guard.luau checks a failing pass does not stop it)

local fs = require("@lune/fs")
local roblox = require("@lune/roblox")

local Check = require("../lib/Check")
local Sandbox = require("../lib/Sandbox")

local check, equal = Check.check, Check.equal
local Vector2, Vector3 = roblox.Vector2, roblox.Vector3
local CFrame = Sandbox.CFrame

Check.printLimit = 10

local Shared = Sandbox.game:GetService("ReplicatedStorage").Shared
local Config = Sandbox.require(Shared.Config)
local CreatureCatalog = Sandbox.require(Shared.CreatureCatalog)
local Names = Sandbox.require(Shared.Names)
local VehicleCatalog = Sandbox.require(Shared.VehicleCatalog)
local WeaponCatalog = Sandbox.require(Shared.WeaponCatalog)

-- Fakes shared by every module below -------------------------------------------------------------

local warnings: { string } = {}
local function recordWarn(...)
	table.insert(warnings, table.concat({ ... }, " "))
end
local function warned(text: string): number
	local count = 0
	for _, line in warnings do
		if string.find(line, text, 1, true) then
			count += 1
		end
	end
	return count
end

local clock = 0
local fakeOs = setmetatable({
	clock = function()
		return clock
	end,
}, { __index = os })

-- task: spawn keeps the function (loops are stepped by the test); wait stops a stepped loop after
-- `waitLimit` calls by raising STOP.
local STOP = "stop the fake loop"
local spawned: { () -> () } = {}
local waitCount, waitLimit = 0, 0
local waitArgs: { number } = {}
local delayed: { () -> () } = {}
local fakeTask = {
	spawn = function(fn, ...)
		local args = table.pack(...)
		table.insert(spawned, function()
			fn(table.unpack(args, 1, args.n))
		end)
	end,
	delay = function(_, fn, ...)
		local args = table.pack(...)
		table.insert(delayed, function()
			fn(table.unpack(args, 1, args.n))
		end)
	end,
	wait = function(seconds)
		table.insert(waitArgs, seconds)
		waitCount += 1
		if waitCount > waitLimit then
			error(STOP, 0)
		end
	end,
}
-- Runs a spawned loop for `passes` passes.
local function step(loop: () -> (), passes: number)
	waitCount, waitLimit = 0, passes
	local ok, err = pcall(loop)
	check(not ok and err == STOP, "the stepped loop stops at the fake wait: " .. tostring(err))
end

-- The interval a spawned loop waits before its first pass (it is stopped at that wait).
local function firstWait(loop: () -> ()): number?
	table.clear(waitArgs)
	step(loop, 0)
	return waitArgs[1]
end

local GLOBALS = { warn = recordWarn, os = fakeOs, task = fakeTask }

-- Guard, real, with the recording warn. Missing before the fix: nil.
local guardOk, Guard = pcall(Sandbox.load, "src/server/systems/util/Guard.luau", GLOBALS)
if not guardOk then
	print("Guard did not load: " .. tostring(Guard))
	Guard = nil
end

-- Answers any field read or call with itself: requires and Instances a test does not look at.
local stub
stub = setmetatable({}, {
	__index = function()
		return stub
	end,
	__call = function()
		return stub
	end,
})

-- An instance path stand-in: `require(node)` sees the last name in the path.
local function node(name: string): any
	return setmetatable({}, {
		__index = function(_, key)
			if key == "__name" then
				return name
			end
			return node(key)
		end,
		__call = function()
			return nil
		end,
	})
end

-- Loads a server module: `fakes` by module name behind its requires (a function fake is called
-- and its result returned, so it can raise), Guard real, shared modules real, anything else stub.
local function loadWith(path: string, fakes: { [string]: any }, extra: { [string]: any }?): any
	local environment = {
		game = {
			GetService = function(_, service)
				return node(service)
			end,
		},
		script = node("script"),
		require = function(target)
			local name = target.__name
			local fake = fakes[name]
			if type(fake) == "function" then
				return fake()
			elseif fake ~= nil then
				return fake
			elseif name == "Guard" then
				return Guard or stub
			end
			local ok, shared = pcall(Sandbox.require, Shared[name])
			return if ok then shared else stub
		end,
	}
	for key, value in GLOBALS do
		environment[key] = value
	end
	for key, value in extra or {} do
		environment[key] = value
	end
	return Sandbox.load(path, environment)
end

-- Instance.new: a fresh table per instance (writes stay on it), any other read the stub.
-- A Humanoid's Died:Connect keeps the handler in `diedHandlers`.
local instances: { any } = {}
local diedHandlers: { () -> () } = {}
local FakeInstance = {
	new = function(className)
		local instance = setmetatable({ ClassName = className }, {
			__index = function()
				return stub
			end,
		})
		if className == "Humanoid" then
			instance.Died = {
				Connect = function(_, handler)
					table.insert(diedHandlers, handler)
				end,
			}
		end
		table.insert(instances, instance)
		return instance
	end,
}

-- Creatures --------------------------------------------------------------------------------------

-- The kind whose model file throws: one the landmarks and the horde both use.
local BROKEN_KIND = "skeleton"
local brokenName = CreatureCatalog.KINDS[BROKEN_KIND].name

local piecesBreak = false
local fakeParts = {
	fromPiece = function()
		if piecesBreak then
			error("piece failed", 0)
		end
		return FakeInstance.new("Part")
	end,
	weldTo = function() end,
}
local creatureFakes: { [string]: any } = {
	-- CreatureModel.addPieces builds the pieces: its one require, util/Parts, is the fake.
	CreatureModel = Sandbox.load("src/server/systems/CreatureModel.luau", {
		require = function(target)
			assert(tostring(target) == "src/server/systems/util/Parts", tostring(target))
			return fakeParts
		end,
	}),
	Combat = stub,
	Characters = stub,
}
for kindId in CreatureCatalog.KINDS do
	creatureFakes[kindId] = function()
		if kindId == BROKEN_KIND then
			error("broken model file", 0)
		end
		return Sandbox.load("src/server/creatureModels/" .. kindId .. ".luau")
	end
end

-- Counts the creature models built since `from`, by name.
local function builtSince(from: number): { [string]: number }
	local counts = {}
	for index = from + 1, #instances do
		local instance = instances[index]
		if instance.ClassName == "Model" then
			counts[instance.Name] = (counts[instance.Name] or 0) + 1
		end
	end
	return counts
end

Check.section("Creatures: a broken creature model file")
do
	table.clear(warnings)
	local ok, Creatures = pcall(
		loadWith,
		"src/server/systems/Creatures.luau",
		creatureFakes,
		{ Instance = FakeInstance, workspace = stub }
	)
	check(ok, "Creatures loads: " .. tostring(if ok then "" else Creatures))
	if ok then
		equal(warned(BROKEN_KIND), 1, "one warning names the broken file")
		equal(warned("broken model file"), 1, "and carries its error")

		local from = #instances
		local started, err = pcall(Creatures.start)
		check(started, "Creatures.start runs: " .. tostring(err))
		local counts = builtSince(from)
		equal(counts[brokenName], nil, "no " .. brokenName .. " spawns")
		local want: { [string]: number } = table.clone(CreatureCatalog.ROAMING)
		for _, region in Config.REGIONS do
			want[CreatureCatalog.REGION_KIND[region.id]] = CreatureCatalog.THEMED_COUNT
		end
		for kindId, count in want do
			if kindId ~= BROKEN_KIND then
				local name = CreatureCatalog.KINDS[kindId].name
				equal(counts[name], count, name .. " spawns")
			end
		end

		from = #instances
		local center = Config.pointAt(0, Config.LOBBY_RADIUS + 200)
		local horded, hordeErr = pcall(Creatures.horde, center, 200)
		check(horded, "Creatures.horde runs: " .. tostring(hordeErr))
		counts = builtSince(from)
		equal(counts[brokenName], nil, "the horde never picks " .. brokenName)
		check((counts[CreatureCatalog.KINDS.zombie.name] or 0) > 0, "the horde has zombies")
	end
end

local function loadCreatures(): any
	return loadWith(
		"src/server/systems/Creatures.luau",
		creatureFakes,
		{ Instance = FakeInstance, workspace = stub }
	)
end

Check.section("Creatures: a spawn error leaves the loops running")
do
	table.clear(spawned)
	local Creatures = loadCreatures()
	piecesBreak = true
	local ok = pcall(Creatures.start)
	piecesBreak = false
	check(not ok, "(the spawn error reaches start's caller, init.server's Guard.run)")
	equal(#spawned, 2, "the lair and think loops are spawned before the spawns")
	local intervals = {}
	for _, loop in spawned do
		table.insert(intervals, firstWait(loop))
	end
	table.sort(intervals)
	local want = { 1, CreatureCatalog.THINK_INTERVAL }
	table.sort(want)
	equal(intervals[1], want[1], "first wait before a pass (unchanged)")
	equal(intervals[2], want[2], "first wait before a pass (unchanged)")
end

Check.section("Creatures: a respawn whose build throws")
do
	table.clear(warnings)
	table.clear(delayed)
	local Creatures = loadCreatures()
	local from = #diedHandlers
	Creatures.start()
	local died = diedHandlers[from + 1]
	check(died ~= nil, "a roaming creature has a Died handler")
	if died then
		died()
		equal(#delayed, 1, "its death schedules a respawn")
		piecesBreak = true
		local ok, err = pcall(delayed[1] or function() end)
		piecesBreak = false
		check(ok, "the failing respawn raises nothing: " .. tostring(err))
		equal(warned("creatures respawn"), 1, "it is warned")
		equal(warned("piece failed"), 1, "with its error")
	end
end

-- Vehicles/Parking -------------------------------------------------------------------------------

local brokenVehicle = VehicleCatalog.ALL[1].id
local buildBreaks = true
local built: { string } = {}
local order: { string } = {}

local function fakeModel(cframe: CFrame): any
	return {
		Parent = true,
		PrimaryPart = { Position = cframe.Position },
		GetDescendants = function()
			return {}
		end,
		FindFirstChild = function()
			return nil
		end,
		GetAttribute = function()
			return clock
		end,
		SetAttribute = function() end,
		Destroy = function() end,
	}
end

local SPEC = { footprint = Vector2.new(8, 16), collision = {} }

local Parking = loadWith("src/server/systems/Vehicles/Parking.luau", {
	PodFlight = {
		start = function()
			table.insert(order, "PodFlight.start")
		end,
	},
	Characters = stub,
	Specs = {
		specFor = function()
			return SPEC
		end,
	},
	Builder = {
		build = function(id, cframe)
			table.insert(order, "build")
			if id == brokenVehicle and buildBreaks then
				error("build failed", 0)
			end
			table.insert(built, id)
			return fakeModel(cframe)
		end,
	},
}, {
	OverlapParams = {
		new = function()
			return {}
		end,
	},
	workspace = {
		Terrain = {},
		GetPartBoundsInBox = function()
			return {}
		end,
	},
})

Check.section("Parking: a vehicle whose build throws")
do
	table.clear(warnings)
	table.clear(spawned)
	local ok, err = pcall(Parking.start)
	check(ok, "Parking.start runs: " .. tostring(err))
	equal(order[1], "PodFlight.start", "PodFlight.start before layOut")
	local parked = {}
	for _, id in built do
		parked[id] = (parked[id] or 0) + 1
	end
	equal(parked[brokenVehicle], nil, brokenVehicle .. " is not parked")
	for _, entry in VehicleCatalog.ALL do
		if entry.id ~= brokenVehicle then
			equal(parked[entry.id], 1, entry.id .. " parked after the failure")
		end
	end
	equal(warned(brokenVehicle), 1, "one warning names the vehicle")
	equal(warned("build failed"), 1, "and carries its error")

	equal(#spawned, 1, "the respawn loop is spawned")
	if spawned[1] then
		clock += 1
		step(spawned[1], 1)
		equal(warned("build failed"), 1, "a repeated failure inside the rate limit: no new warning")
		buildBreaks = false
		step(spawned[1], 1)
		local count = 0
		for _, id in built do
			if id == brokenVehicle then
				count += 1
			end
		end
		equal(count, 1, "the next respawn pass parks the empty spot")
	end
end

Check.section("Parking: a layOut error leaves the respawn loop running")
do
	table.clear(spawned)
	table.clear(order)
	local Parking2 = loadWith("src/server/systems/Vehicles/Parking.luau", {
		PodFlight = {
			start = function()
				table.insert(order, "PodFlight.start")
			end,
		},
		Characters = stub,
		Specs = {
			specFor = function()
				table.insert(order, "specFor")
				error("spec failed", 0)
			end,
		},
		Builder = { build = stub },
	}, {
		OverlapParams = {
			new = function()
				return {}
			end,
		},
		workspace = { Terrain = {} },
	})
	local ok = pcall(Parking2.start)
	check(not ok, "(the layOut error reaches start's caller, init.server's Guard.run)")
	equal(order[1], "PodFlight.start", "PodFlight.start first")
	equal(order[2], "specFor", "then layOut")
	equal(#spawned, 1, "the respawn loop is spawned before layOut")
	if spawned[1] then
		equal(
			firstWait(spawned[1]),
			Sandbox.require(Shared.VehicleLayout).RESPAWN_INTERVAL,
			"it waits RESPAWN_INTERVAL before its first pass (unchanged)"
		)
	end
end

-- Weapons/Firing ---------------------------------------------------------------------------------

local PLAYERS = {}
local function armedPlayer(weapon): any
	local position = Vector3.new(Config.LOBBY_RADIUS + 100, 5, 0)
	local parts = {
		Tool = {
			GetAttribute = function(_, name)
				return if name == Names.Attributes.WeaponId then weapon.id else nil
			end,
			FindFirstChild = function()
				return nil
			end,
		},
		Humanoid = { Health = 100 },
		HumanoidRootPart = { Anchored = false, Position = position, CFrame = CFrame.new(position) },
		Head = { Position = position + Vector3.new(0, 1.5, 0) },
	}
	local character = {
		FindFirstChildOfClass = function(_, className)
			return parts[className]
		end,
		FindFirstChild = function(_, name)
			return parts[name]
		end,
	}
	return { Character = character, Parent = PLAYERS }
end

Check.section("Firing: a weapon kind with no FIRE entry")
do
	table.clear(warnings)
	local firedKinds: { string } = {}
	local missingKind = WeaponCatalog.ALL[1].kind
	local Firing = loadWith("src/server/systems/Weapons/Firing.luau", {
		WeaponSounds = { fire = function() end },
		Tools = {
			modelFor = function()
				return {}
			end,
		},
		kinds = setmetatable({}, {
			__index = function(_, kind)
				if kind == missingKind then
					return nil
				end
				return function(shot)
					table.insert(firedKinds, shot.weapon.kind)
				end
			end,
		}),
	})
	local sameKind = {}
	for _, weapon in WeaponCatalog.ALL do
		if weapon.kind == missingKind then
			table.insert(sameKind, weapon)
		end
	end
	local aim = Vector3.new(Config.LOBBY_RADIUS + 100, 5, 50)
	for round = 1, 2 do
		for _, weapon in sameKind do
			clock += 100
			local ok, err = pcall(Firing.onFire, armedPlayer(weapon), weapon.id, aim)
			check(ok, ("%s (round %d) raises nothing: %s"):format(weapon.id, round, tostring(err)))
		end
	end
	equal(#firedKinds, 0, "nothing fires")
	equal(warned(missingKind), 1, "one warning for the kind, however many shots")

	local other
	for _, weapon in WeaponCatalog.ALL do
		if weapon.kind ~= missingKind then
			other = weapon
			break
		end
	end
	clock += 100
	Firing.onFire(armedPlayer(other), other.id, aim)
	equal(firedKinds[1], other.kind, "a kind with an entry still fires")
end

-- Lamps -----------------------------------------------------------------------------------------

Check.section("Lamps: a lamp whose build throws")
do
	table.clear(warnings)
	table.clear(instances)
	local NightLights = Sandbox.require(Shared.NightLights)
	local plans = NightLights.lobbyLamps()
	for _, lamp in NightLights.roadLamps() do
		table.insert(plans, lamp)
	end
	local BROKEN = 2 -- a lit lobby lamp
	local columns, tagged = 0, 0
	local fakeBuild = {
		model = FakeInstance.new,
		column = function()
			columns += 1
			if columns == BROKEN then
				error("lamp failed", 0)
			end
			return FakeInstance.new("Part")
		end,
		part = function()
			return FakeInstance.new("Part")
		end,
		nightLight = function()
			tagged += 1
		end,
	}
	local services: { [string]: any } = {
		CollectionService = {
			GetTagged = function()
				return {}
			end,
		},
	}
	local ok, err = pcall(function()
		local Lamps = loadWith("src/server/world/Lamps.luau", { Build = fakeBuild }, {
			game = {
				GetService = function(_, name)
					return services[name] or node(name)
				end,
			},
			Instance = FakeInstance,
		})
		Lamps.build(FakeInstance.new("Model"))
	end)
	check(ok, "Lamps.build runs to the end: " .. tostring(err))
	equal(warned("lamp failed"), 1, "the failing lamp is warned")
	equal(tagged, #plans - 1, "every other lamp is built and tagged")
	local lit = 0
	for index, lamp in plans do
		if lamp.lit and index ~= BROKEN then
			lit += 1
		end
	end
	local lights = 0
	for _, instance in instances do
		if instance.ClassName == "SpotLight" then
			lights += 1
		end
	end
	equal(lights, math.min(lit, NightLights.MAX_LIGHTS), "every other lit lamp has its light")
end

-- Server boot (init.server.luau) ----------------------------------------------------------------

Check.section("init.server: a system whose start() throws")
do
	table.clear(warnings)
	local started: { string } = {}
	local function system(name: string, breaks: boolean?): any
		return {
			start = function()
				table.insert(started, name)
				if breaks then
					error(name .. " start failed", 0)
				end
			end,
		}
	end
	local noop = function() end
	local services: { [string]: any } = {
		Players = {
			CharacterAutoLoads = true,
			GetPlayers = function()
				return {}
			end,
		},
	}
	local buildingNames, realmNames = {}, {}
	for _, region in Config.REGIONS do
		buildingNames[region.id] = "building_" .. region.id
		realmNames[region.id] = "realm_" .. region.id
	end
	local fakes: { [string]: any } = {
		Remotes = stub,
		Build = { model = FakeInstance.new },
		Landscape = { build = noop, explosiveBarrel = noop },
		Lamps = { build = noop },
		Lobby = { build = noop },
		Passes = { raise = noop, cut = noop, clearScenery = noop },
		Regions = { BUILDINGS = buildingNames, REALMS = realmNames },
		WorldLayout = { frame = noop, gateFrame = noop },
		Roads = { build = noop },
		CollisionGroups = { register = noop },
		Combat = { setBarrelFactory = noop },
		Weapons = { displayModel = noop },
		DayNight = system("DayNight"),
		NightLights = system("NightLights"),
		Session = system("Session"),
		Creatures = system("Creatures", true),
		Vehicles = system("Vehicles"),
		Admin = system("Admin"),
		MacAccess = system("MacAccess"),
	}
	for _, name in buildingNames do
		fakes[name] = { build = noop }
	end
	for _, name in realmNames do
		fakes[name] = { build = noop }
	end
	local ok, err = pcall(loadWith, "src/server/init.server.luau", fakes, {
		game = {
			GetService = function(_, name)
				return services[name] or node(name)
			end,
		},
		Instance = FakeInstance,
		workspace = {
			FindFirstChild = function()
				return nil
			end,
		},
		print = noop,
	})
	check(ok, "the boot runs to the end: " .. tostring(err))
	equal(
		table.concat(started, " "),
		"DayNight NightLights Session Creatures Vehicles Admin MacAccess",
		"every start runs, in boot order"
	)
	equal(warned("Creatures start failed"), 1, "the failing start is warned")
	equal(services.Players.CharacterAutoLoads, true, "CharacterAutoLoads is back on")
end

-- Background loops -------------------------------------------------------------------------------

-- The endless loops in `text` (Luau source), comments stripped first.
local LOOPS = { "while%s+true%s+do", "while%s+task%.wait", "until%s+false" }
local function endlessLoops(text: string): { string }
	text = string.gsub(text, "%-%-%[(=*)%[.-%]%1%]", "")
	text = string.gsub(text, "%-%-[^\n]*", "")
	local found = {}
	for _, pattern in LOOPS do
		if string.find(text, pattern) then
			table.insert(found, pattern)
		end
	end
	return found
end

Check.section("the endless-loop scan")
do
	for _, case in
		{
			{ "while true do x() end", 1 },
			{ "while  true\tdo x() end", 1 },
			{ "while task.wait(1) do x() end", 1 },
			{ "repeat\n\tx()\nuntil false", 1 },
			{ "-- while true do", 0 },
			{ "x() -- repeat until false", 0 },
			{ "--[[\nwhile true do\n]] x()", 0 },
			{ "--[==[ while task.wait() do ]==] x()", 0 },
			{ "while os.clock() < stop do x() end", 0 },
			{ "repeat x() until done", 0 },
		}
	do
		equal(#endlessLoops(case[1]), case[2], ("%q"):format(case[1]))
	end
end

Check.section("no endless loop in src/server outside Guard")
do
	local function walk(folder: string)
		for _, name in fs.readDir(Sandbox.ROOT .. "/" .. folder) do
			local path = folder .. "/" .. name
			if fs.isDir(Sandbox.ROOT .. "/" .. path) then
				walk(path)
			elseif
				string.match(name, "%.luau$") and path ~= "src/server/systems/util/Guard.luau"
			then
				local found = endlessLoops(fs.readFile(Sandbox.ROOT .. "/" .. path))
				check(
					#found == 0,
					path
						.. " runs an endless loop outside Guard.loop: "
						.. table.concat(found, ", ")
				)
			end
		end
	end
	walk("src/server")
end

Check.finish()
