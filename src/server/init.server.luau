-- Server bootstrap: builds the whole world from code, then starts the game systems.
-- Characters stay unloaded until the lobby exists so nobody spawns into the void.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

Players.CharacterAutoLoads = false

local Config = require(ReplicatedStorage.Shared.Config)
require(ReplicatedStorage.Shared.Remotes)

local World = script.world
local Systems = script.systems
local Build = require(World.Build)
local Landscape = require(World.Landscape)
local Lobby = require(World.Lobby)
local Roads = require(World.Roads)

local Admin = require(Systems.Admin)
local Combat = require(Systems.Combat)
local Creatures = require(Systems.Creatures)
local Session = require(Systems.Session)
local Vehicles = require(Systems.Vehicles)
local Weapons = require(Systems.Weapons)
local WalkerProbe = require(Systems.WalkerProbe) -- TEMPORARY

local BUILDINGS = {
	castle = require(World.buildings.Castle),
	pagoda = require(World.buildings.Pagoda),
	tower = require(World.buildings.Skyscraper),
	pyramid = require(World.buildings.Pyramid),
	palace = require(World.buildings.Palace),
}

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
	Lighting.ClockTime = 14
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
	print(string.format("[Mayhem] world built in %.1fs", os.clock() - started))
end

clearTemplate()
Session.registerCollisionGroups()
Vehicles.registerCollisionGroups()
Combat.setBarrelFactory(Landscape.explosiveBarrel)
atmosphere()
workspace.Gravity = Config.NORMAL_GRAVITY
buildWorld()

Session.start()
Creatures.start()
task.spawn(WalkerProbe.start) -- TEMPORARY
Vehicles.start()
Admin.start()

Players.CharacterAutoLoads = true
for _, player in Players:GetPlayers() do
	if not player.Character then
		task.spawn(player.LoadCharacter, player)
	end
end
