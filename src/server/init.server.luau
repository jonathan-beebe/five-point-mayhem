-- Server bootstrap: builds the whole world from code, then starts the game systems.
-- Characters stay unloaded until the lobby exists so nobody spawns into the void.

local Lighting = game:GetService("Lighting")
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

Players.CharacterAutoLoads = false

local Config = require(ReplicatedStorage.Shared.Config)
local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
require(ReplicatedStorage.Shared.Remotes)

local World = script.world
local Systems = script.systems
local Build = require(World.Build)
local Lamps = require(World.Lamps)
local Landscape = require(World.Landscape)
local Lobby = require(World.Lobby)
local Passes = require(World.Passes)
local Regions = require(World.Regions)
local Roads = require(World.Roads)

local Admin = require(Systems.Admin)
local CollisionGroups = require(Systems.CollisionGroups)
local Combat = require(Systems.Combat)
local Creatures = require(Systems.Creatures)
local DayNight = require(Systems.DayNight)
local Guard = require(Systems.util.Guard)
local MacAccess = require(Systems.MacAccess)
local NightLights = require(Systems.NightLights)
local Session = require(Systems.Session)
local Vehicles = require(Systems.Vehicles)
local Weapons = require(Systems.Weapons)

-- Each landmark's building module (Regions.BUILDINGS), by region id, required in region order.
local BUILDINGS = {}
for _, region in Config.REGIONS do
	local name = assert(Regions.BUILDINGS[region.id], "Regions.BUILDINGS has no " .. region.id)
	BUILDINGS[region.id] = require(World.buildings[name] :: ModuleScript)
end

-- Each world's realm module past its pass (Regions.REALMS), by region id.
local REALMS = {}
for _, region in Config.REGIONS do
	local name = assert(Regions.REALMS[region.id], "Regions.REALMS has no " .. region.id)
	REALMS[region.id] = require(World.realms[name] :: ModuleScript)
end

local function clearTemplate()
	for _, name in { "Baseplate", "SpawnLocation" } do
		local leftover = workspace:FindFirstChild(name)
		if leftover then
			leftover:Destroy()
		end
	end
	local old = workspace:FindFirstChild("MayhemWorld")
	if old then
		old:Destroy()
	end
end

local function atmosphere()
	Lighting.Brightness = 2.5
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 1
	local air = Instance.new("Atmosphere")
	air.Density = 0.28
	air.Haze = 1.2
	air.Color = Color3.fromRGB(200, 215, 235)
	air.Decay = Color3.fromRGB(110, 120, 150)
	air.Parent = Lighting
	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.6
	bloom.Threshold = 1.6
	bloom.Parent = Lighting
	local rays = Instance.new("SunRaysEffect")
	rays.Intensity = 0.06
	rays.Parent = Lighting
end

local function buildWorld()
	local started = os.clock()
	local world = Build.model("MayhemWorld", workspace)
	Lobby.build(world, Weapons.displayModel)
	Roads.build(world)
	for index, region in Config.REGIONS do
		local center = Config.regionCenter(index)
		-- Each landmark faces the lobby: local -Z points at the origin.
		local frame = CFrame.lookAt(center, Vector3.new(0, 0, 0))
		local ok, problem = pcall(BUILDINGS[region.id].build, world, frame)
		if not ok then
			warn("[Mayhem] failed to build " .. region.name .. ": " .. tostring(problem))
		end
	end
	Landscape.build(world)
	-- The worlds past the rim: the high range, each realm's land, then the passes cut through both.
	Guard.run("raise Passes", Passes.raise)
	for index, region in Config.REGIONS do
		Guard.run(
			"build " .. region.id .. " realm",
			REALMS[region.id].build,
			world,
			WorldLayout.frame(index)
		)
	end
	Guard.run("cut Passes", Passes.cut)
	-- Lamps and fireflies last: fireflies gather under the trees. Each lamp is guarded inside.
	Guard.run("build Lamps", Lamps.build, world)
	print(string.format("[Mayhem] world built in %.1fs", os.clock() - started))
end

clearTemplate()
CollisionGroups.register(PhysicsService)
Combat.setBarrelFactory(Landscape.explosiveBarrel)
atmosphere()
Guard.run("start DayNight", DayNight.start)
workspace.Gravity = Config.NORMAL_GRAVITY
buildWorld()

-- Each start is guarded: one that throws is warned and the rest still start, in this order.
Guard.run("start NightLights", NightLights.start)
Guard.run("start Session", Session.start)
Guard.run("start Creatures", Creatures.start)
Guard.run("start Vehicles", Vehicles.start)
Guard.run("start Admin", Admin.start)
Guard.run("start MacAccess", MacAccess.start)

Players.CharacterAutoLoads = true
for _, player in Players:GetPlayers() do
	if not player.Character then
		task.spawn(player.LoadCharacter, player)
	end
end
