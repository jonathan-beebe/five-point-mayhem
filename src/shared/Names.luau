--!strict
-- Names that cross a module boundary: attributes, tags, collision groups and instance names one
-- module sets and another reads (often server sets, client reads). Pure data, no requires: the
-- server, the clients and the Lune tests read it. A name one module both sets and reads stays a
-- local literal in that module.
--
-- The values are a contract between server and client: changing one changes what the other
-- looks for. tools/tests/names.luau pins every value.
--
-- Casing: keys mirror their string values (`Attributes.PodState = "PodState"`), except the two
-- prefixes and `Leaderstats` ("leaderstats"). PodState and RemoteActions use UPPER_CASE constants.

local Names = {}

-- Instance attributes, by the module that sets them.
Names.Attributes = table.freeze({
	Aim = "Aim", -- bone part, Vehicles: the bone turns toward the camera's aim (MechMotion)
	-- Humanoid, Session/Creatures/Admin: the unslowed speed (Combat).
	BaseWalkSpeed = "BaseWalkSpeed",
	Climbing = "Climbing", -- walker model, Vehicles: lifting itself up a wall (MechMotion)
	CockpitCamera = "CockpitCamera", -- driver seat, Vehicles: the cockpit view (MechCamera)
	Deployed = "Deployed", -- player, Session: out of the lobby (Creatures, LobbyUI)
	Gait = "Gait", -- vehicle model, Vehicles: animated walker gait (MechMotion, WalkerProbe)
	HasMac = "HasMac", -- player, MacAccess: the MAC is unlocked (MacPanel)
	Health = "Health", -- vehicle model, Vehicles (VehicleHealth)
	HideInCockpit = "HideInCockpit", -- part, Vehicles: hidden in the cockpit view (MechCamera)
	Home = "Home", -- explosive barrel, Landscape: where it respawns (Combat)
	IsAdmin = "IsAdmin", -- player, Session (AdminPanel, LobbyUI)
	LegsSeat = "LegsSeat", -- pod walker's legs seat, Vehicles (MechCamera)
	MaxHealth = "MaxHealth", -- vehicle model, Vehicles (VehicleHealth)
	MayhemCar = "MayhemCar", -- driver or legs seat, Vehicles (CarInput, VehicleSounds)
	-- Pod walker model, PodFlight: the bone that flies (PodControls, MechCamera).
	PodBone = "PodBone",
	PodCanLand = "PodCanLand", -- pod walker model, PodFlight: low enough to land (PodControls)
	PodState = "PodState", -- pod walker model, PodFlight: a PodState value (Vehicles, clients)
	Steer = "Steer", -- bone part, Vehicles: the bone turns with steering (MechMotion)
	TopSpeed = "TopSpeed", -- driver or legs seat, Vehicles (MechMotion, VehicleSounds)
	Toughness = "Toughness", -- tree, Landscape: its scale; rams need more to fell it (Vehicles)
	TurnRate = "TurnRate", -- driver seat, Vehicles (MechMotion)
	VehicleId = "VehicleId", -- vehicle model, Vehicles: its VehicleCatalog id (VehicleSounds)
	WeaponId = "WeaponId", -- tool, Weapons: its WeaponCatalog id (WeaponInput, SniperScope)
	Wobble = "Wobble", -- bone part, Vehicles: the bone sways (MechMotion)
	Wrecked = "Wrecked", -- vehicle model, Vehicles (VehicleHealth)
})

-- CollectionService tags.
Names.Tags = table.freeze({
	ExplosiveBarrel = "ExplosiveBarrel", -- Landscape (Combat, Weapons, Vehicles)
	MechCab = "MechCab", -- a walker's cab volume, Vehicles (MechCamera)
	NoClimb = "NoClimb", -- Lobby: walkers climb no part of it (Vehicles)
	Tree = "Tree", -- Landscape: rams fell it (Vehicles)
})

-- PhysicsService collision groups: one namespace for the whole place. The server's
-- systems/CollisionGroups registers them all and sets which pairs pass through each other.
Names.CollisionGroups = table.freeze({
	DeployedPlayers = "DeployedPlayers",
	LobbyGate = "LobbyGate",
	LobbyPlayers = "LobbyPlayers",
	LockedOutPlayers = "LockedOutPlayers",
	Scenery = "Scenery", -- Landscape's trees, rocks, crates and barrels
	Vehicles = "Vehicles",
	Walkers = "Walkers", -- vehicles with spec.stepsOver
	Wreckage = "Wreckage", -- felled trees
})

-- Instance names another module looks up.
Names.Instances = table.freeze({
	BonePrefix = "Bone_", -- Vehicles' rig part per bone: "Bone_<bone>"
	Cab = "Cab", -- a walker's cab volume, Vehicles (PodFlight)
	CameraFocus = "CameraFocus", -- Vehicles (MechCamera)
	Creatures = "Creatures", -- workspace folder, Creatures (Combat, Vehicles)
	DrivePrompt = "DrivePrompt", -- Vehicles builds it as "Drive" .. "Prompt" (PromptPanel)
	DriverSeat = "DriverSeat", -- Vehicles (clients)
	JointPrefix = "Joint_", -- Vehicles' Motor6D per bone: "Joint_<bone>"
	Leaderstats = "leaderstats", -- player folder, Session (Combat)
	LegsSeat = "LegsSeat", -- pod walker's legs seat, Vehicles (MechMotion)
	MechButtons = "MechButtons", -- ScreenGui, MechCamera (ui/Hud lists the gui)
	PodButtons = "PodButtons", -- ScreenGui, PodControls (ui/Hud lists the gui)
	PodPrompt = "PodPrompt", -- PodFlight (PromptPanel)
	Skid = "Skid", -- a vehicle's root part, Vehicles (MechMotion, WalkerProbe)
	Smoke = "Smoke", -- smokestack Attachment, Vehicles (MechMotion)
	SniperScopeButton = "SniperScopeButton", -- ScreenGui, SniperScope (ui/Hud lists the gui)
	Vehicles = "Vehicles", -- workspace folder, Vehicles (Creatures, clients)
	WeaponEffects = "WeaponEffects", -- workspace folder, Weapons (WeaponInput)
})

return table.freeze(Names)
