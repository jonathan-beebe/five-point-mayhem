-- Checks the shared contracts (src/shared/Names.luau, PodState.luau, RemoteActions.luau) outside
-- Roblox.
-- Usage: lune run tools/tests/names.luau
--
--   - every constant equals the literal the game used before the constants existed (the golden
--     lists below), and every group has exactly the golden keys: renaming a value breaks the
--     server/client contract with running places
--   - values are unique within a group
--   - PodState.of and the predicates match the inline expressions they replaced, for every state
--     and for an unset attribute

local Check = require("../lib/Check")
local Sandbox = require("../lib/Sandbox")

local check, equal = Check.check, Check.equal

local Names = Sandbox.load("src/shared/Names.luau")
local PodState = Sandbox.load("src/shared/PodState.luau")
local RemoteActions = Sandbox.load("src/shared/RemoteActions.luau")

-- The literals each key replaced.
local GOLDEN = {
	["Names.Attributes"] = {
		Aim = "Aim",
		BaseWalkSpeed = "BaseWalkSpeed",
		Climbing = "Climbing",
		CockpitCamera = "CockpitCamera",
		Deployed = "Deployed",
		Gait = "Gait",
		HasMac = "HasMac",
		Health = "Health",
		HideInCockpit = "HideInCockpit",
		Home = "Home",
		IsAdmin = "IsAdmin",
		LegsDrone = "LegsDrone",
		LegsSeat = "LegsSeat",
		MaxHealth = "MaxHealth",
		MayhemCar = "MayhemCar",
		PodBone = "PodBone",
		PodCanLand = "PodCanLand",
		PodState = "PodState",
		Steer = "Steer",
		TopSpeed = "TopSpeed",
		Toughness = "Toughness",
		TurnRate = "TurnRate",
		VehicleId = "VehicleId",
		WeaponId = "WeaponId",
		Wobble = "Wobble",
		Wrecked = "Wrecked",
	},
	["Names.Tags"] = {
		ExplosiveBarrel = "ExplosiveBarrel",
		MechCab = "MechCab",
		NightLight = "NightLight",
		NoClimb = "NoClimb",
		Tree = "Tree",
	},
	["Names.CollisionGroups"] = {
		DeployedPlayers = "DeployedPlayers",
		LobbyGate = "LobbyGate",
		LobbyPlayers = "LobbyPlayers",
		LockedOutPlayers = "LockedOutPlayers",
		Scenery = "Scenery",
		Vehicles = "Vehicles",
		Walkers = "Walkers",
		Wreckage = "Wreckage",
	},
	["Names.Instances"] = {
		BonePrefix = "Bone_",
		Cab = "Cab",
		CameraFocus = "CameraFocus",
		Creatures = "Creatures",
		DrivePrompt = "DrivePrompt",
		DriverSeat = "DriverSeat",
		JointPrefix = "Joint_",
		Leaderstats = "leaderstats",
		LegsSeat = "LegsSeat",
		MechButtons = "MechButtons",
		PodButtons = "PodButtons",
		PodPrompt = "PodPrompt",
		Skid = "Skid",
		Smoke = "Smoke",
		SniperScopeButton = "SniperScopeButton",
		Vehicles = "Vehicles",
		WeaponEffects = "WeaponEffects",
	},
	["RemoteActions.AnnounceStyle"] = { ALARM = "alarm", MAYHEM = "mayhem" },
	["RemoteActions.MacCommand"] = { NUKE = "nuke", SNIPER = "sniper" },
	["RemoteActions.PodCommand"] = {
		DRONE = "drone",
		HOME = "home",
		LAND = "land",
		LAUNCH = "launch",
	},
}

local GROUPS = {
	["Names.Attributes"] = Names.Attributes,
	["Names.Tags"] = Names.Tags,
	["Names.CollisionGroups"] = Names.CollisionGroups,
	["Names.Instances"] = Names.Instances,
	["RemoteActions.AnnounceStyle"] = RemoteActions.AnnounceStyle,
	["RemoteActions.MacCommand"] = RemoteActions.MacCommand,
	["RemoteActions.PodCommand"] = RemoteActions.PodCommand,
}

local function sortedKeys(set: { [string]: any }): { string }
	local list = {}
	for key in set do
		table.insert(list, key)
	end
	table.sort(list)
	return list
end

for _, label in sortedKeys(GOLDEN) do
	Check.section(label)
	local golden, group = GOLDEN[label], GROUPS[label]
	check(group ~= nil, label .. " is missing")
	group = group or {}
	check(table.isfrozen(group), label .. " should be frozen")
	for _, key in sortedKeys(golden) do
		equal(group[key], golden[key], label .. "." .. key)
	end
	local seen: { [string]: string } = {}
	for _, key in sortedKeys(group) do
		check(golden[key] ~= nil, label .. "." .. key .. " has no golden value: add it here")
		local value = group[key]
		check(type(value) == "string", label .. "." .. key .. " should be a string")
		check(
			seen[value] == nil,
			string.format(
				"%s.%s repeats %s.%s's value %q",
				label,
				key,
				label,
				tostring(seen[value]),
				tostring(value)
			)
		)
		seen[value] = key
	end
end

Check.section("Names")
for _, key in sortedKeys(Names) do
	check(GROUPS["Names." .. key] ~= nil, "Names." .. key .. " is a group this test does not know")
end
check(table.isfrozen(Names), "Names should be frozen")
for _, key in sortedKeys(RemoteActions) do
	check(
		GROUPS["RemoteActions." .. key] ~= nil,
		"RemoteActions." .. key .. " is a group this test does not know"
	)
end

Check.section("PodState")
local STATES = {
	DOCKED = "docked",
	FLYING = "flying",
	RETURNING = "returning",
	LANDED = "landed",
	WRECKED = "wrecked",
}
for key, value in STATES do
	equal(PodState[key], value, "PodState." .. key)
end
local constants = 0
for key, value in PodState do
	if type(value) == "string" then
		constants += 1
		check(STATES[key] == value, "PodState." .. key .. " is not a known state")
	end
end
equal(constants, 5, "PodState constants")

-- The expressions the predicates replaced, as they stood at the call sites.
local OLD = {
	-- PodFlight setState, launch prompt, onOccupant; PodControls button and launch
	isAtRest = function(state)
		return state == "docked" or state == "landed"
	end,
	-- PodFlight jets and onRider; PodControls lockJump; MechCamera seatsLocked
	inFlight = function(state)
		return state == "flying" or state == "returning"
	end,
	-- Vehicles seatPlayer and driveSeat (the legs seat)
	legsFree = function(state)
		return state == "flying" or state == "landed"
	end,
}
-- `raw` is a PodState attribute value: unset (nil), or a state. The call sites read it as
-- `GetAttribute("PodState") or "docked"`.
local function compare(raw: string?)
	local old = raw or "docked"
	local label = tostring(raw)
	equal(PodState.of(raw), old, "PodState.of(" .. label .. ")")
	for _, name in sortedKeys(OLD) do
		equal(
			PodState[name](PodState.of(raw)),
			OLD[name](old),
			"PodState." .. name .. "(" .. label .. ")"
		)
	end
end
compare(nil)
for _, state in { "docked", "flying", "returning", "landed", "wrecked" } do
	compare(state)
end
-- MechCamera's seatsLocked read the raw attribute: unset was not locked.
equal(PodState.inFlight(PodState.of(nil)), false, "PodState.inFlight(of(nil))")

Check.finish()
