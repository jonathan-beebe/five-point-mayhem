-- Monsters. Each landmark has a themed monster near it; goblins, slimes, and zombies wander
-- everywhere. They chase deployed players who come close and respawn after dying.
--
-- Every landmark is also a zombie lair: when a deployed player comes near, a horde pours out of
-- its main door. Horde zombies vanish if nobody is around for a while, and do not respawn.

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local CreatureCatalog = require(ReplicatedStorage.Shared.CreatureCatalog)
local Names = require(ReplicatedStorage.Shared.Names)
local RemoteActions = require(ReplicatedStorage.Shared.RemoteActions)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Combat = require(script.Parent.Combat)
local CreatureModel = require(script.Parent.CreatureModel)
local Characters = require(script.Parent.util.Characters)
local Parts = require(script.Parent.util.Parts)

local creatureModels = script.Parent.Parent.creatureModels

local Creatures = {}

local rgb = Color3.fromRGB
local random = Random.new()

-- Kinds, their themed regions and lairs: src/shared/CreatureCatalog.luau.
type Kind = CreatureCatalog.Kind

local KINDS = CreatureCatalog.KINDS
-- Themed monster near each landmark, by region id.
local REGION_KIND = CreatureCatalog.REGION_KIND

local folder = Instance.new("Folder")
folder.Name = Names.Instances.Creatures
folder.Parent = workspace

type Creature = {
	model: Model,
	humanoid: Humanoid,
	root: BasePart,
	kind: Kind,
	reach: number, -- attack range from the root's center
	home: Vector3,
	lastAttack: number,
	wanderAt: number,
	lastSeen: number, -- when it last had a target
	exit: Vector3?, -- horde zombies first walk out the door to here
	exitUntil: number,
	lair: string?, -- region id of the lair a horde zombie came from
}
local active: { Creature } = {}

-- Most creatures alive at once, to protect the server.
local MAX_ACTIVE = 170

-- Model building ----------------------------------------------------------------------------

local models: { [string]: CreatureModel.Model } = {}
for kindId in KINDS do
	models[kindId] = CreatureModel.define(require(creatureModels[kindId]) :: any)
end

local function build(kindId: string, position: Vector3): Creature
	local kind = KINDS[kindId]
	local spec = models[kindId]
	local model = Instance.new("Model")
	model.Name = kind.name
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Transparency = 1
	root.Size = spec.rootSize
	root.CFrame = CFrame.new(position)
	root.Parent = model
	model.PrimaryPart = root

	-- Pieces are authored in creature space (origin on the ground); weld them relative to the root.
	local fromRoot = CreatureModel.rootCenter(spec):Inverse()
	for _, piece in spec.pieces do
		local part = Parts.fromPiece(piece, "Part")
		part.Massless = true
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		Parts.weldTo(root, part, fromRoot * piece.offset, model)
	end

	local humanoid = Instance.new("Humanoid")
	humanoid.RequiresNeck = false
	humanoid.HipHeight = spec.hipHeight
	humanoid.MaxHealth = kind.health
	humanoid.Health = kind.health
	humanoid.WalkSpeed = kind.speed
	humanoid:SetAttribute(Names.Attributes.BaseWalkSpeed, kind.speed)
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOn
	humanoid.Parent = model

	model:PivotTo(
		CFrame.new(position + Vector3.new(0, spec.hipHeight + spec.rootSize.Y / 2 + 0.5, 0))
			* CFrame.Angles(0, random:NextNumber(0, 6), 0)
	)
	model.Parent = folder
	-- Unprotected on purpose (not Ownership.set): a failure here should raise.
	root:SetNetworkOwner(nil)
	return {
		model = model,
		humanoid = humanoid,
		root = root,
		kind = kind,
		reach = spec.reach :: number,
		home = position,
		lastAttack = 0,
		wanderAt = 0,
		lastSeen = os.clock(),
		exitUntil = 0,
	}
end

-- Spawning -----------------------------------------------------------------------------------

local function randomGroundPoint(center: Vector3, minRadius: number, maxRadius: number): Vector3
	for _ = 1, 20 do
		local angle = random:NextNumber(0, math.pi * 2)
		local radius = random:NextNumber(minRadius, maxRadius)
		local point = center + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
		local fromOrigin = Vector2.new(point.X, point.Z).Magnitude
		local _, regionDistance = Config.nearestRegion(point)
		if fromOrigin > 130 and fromOrigin < Config.WORLD_RADIUS - 40 and regionDistance > 100 then
			return point
		end
	end
	return Config.pointAt(random:NextNumber(0, math.pi * 2), 300)
end

local spawnOne: (kindId: string, near: Vector3?) -> ()

local function untrack(creature: Creature)
	local index = table.find(active, creature)
	if index then
		table.remove(active, index)
	end
end

local function track(creature: Creature, kindId: string, respawn: boolean)
	table.insert(active, creature)
	creature.humanoid.Died:Connect(function()
		untrack(creature)
		Debris:AddItem(creature.model, 3)
		if respawn then
			task.delay(25, spawnOne, kindId)
		end
	end)
end

spawnOne = function(kindId: string, near: Vector3?)
	local position: Vector3
	if near then
		position = near
	else
		local regionKind = nil
		for index, region in Config.REGIONS do
			if REGION_KIND[region.id] == kindId then
				regionKind = index
			end
		end
		position = if regionKind
			then randomGroundPoint(Config.regionCenter(regionKind), 110, 220)
			else randomGroundPoint(Vector3.zero, 150, Config.WORLD_RADIUS - 50)
	end
	track(build(kindId, position), kindId, near == nil)
end

-- Summons a temporary horde around a point (admin command). These do not respawn.
function Creatures.horde(center: Vector3, count: number)
	local ids = {
		"zombie",
		"zombie",
		"zombie",
		"goblin",
		"slime",
		"skeleton",
		"oni",
		"yeti",
		"trex",
		"robot",
		"brute",
	}
	for _ = 1, count do
		local kindId = ids[random:NextInteger(1, #ids)]
		local angle = random:NextNumber(0, math.pi * 2)
		local point = center
			+ Vector3.new(math.cos(angle), 0, math.sin(angle)) * random:NextNumber(25, 60)
		if
			not Config.isInLobby(point)
			and Vector2.new(point.X, point.Z).Magnitude > Config.LOBBY_RADIUS + 10
		then
			spawnOne(kindId, Vector3.new(point.X, 0, point.Z))
		end
	end
end

-- Brains -------------------------------------------------------------------------------------

-- Whether the humanoid sits in a vehicle (any seat under workspace.Vehicles): creatures ignore
-- players in vehicles.
local function inVehicle(humanoid: Humanoid): boolean
	local seat = humanoid.SeatPart
	local vehicles = workspace:FindFirstChild(Names.Instances.Vehicles)
	return seat ~= nil and vehicles ~= nil and seat:IsDescendantOf(vehicles)
end

local function nearestPlayer(creature: Creature): (Model?, BasePart?, number)
	local best, bestRoot, bestDistance = nil, nil, creature.kind.aggro
	for _, player in Players:GetPlayers() do
		local character, humanoid, root = Characters.living(player)
		if
			character
			and humanoid
			and root
			and player:GetAttribute(Names.Attributes.Deployed)
			and not Config.isInLobby(root.Position)
			and not inVehicle(humanoid)
		then
			local distance = (root.Position - creature.root.Position).Magnitude
			if distance < bestDistance then
				best, bestRoot, bestDistance = character, root, distance
			end
		end
	end
	return best, bestRoot, bestDistance
end

local function think(creature: Creature, now: number)
	if creature.root.Anchored then
		return -- frozen
	end
	local humanoid = creature.humanoid
	-- Hop over crates and kerbs when walking but not getting anywhere.
	local flat = creature.root.AssemblyLinearVelocity * Vector3.new(1, 0, 1)
	if humanoid.MoveDirection.Magnitude > 0.1 and flat.Magnitude < 2 then
		humanoid.Jump = true
	end
	if creature.exit and now < creature.exitUntil then
		humanoid:MoveTo(creature.exit)
		return
	end
	local target, targetRoot, distance = nearestPlayer(creature)
	if target and targetRoot then
		creature.lastSeen = now
		creature.humanoid:MoveTo(targetRoot.Position)
		if creature.kind.hops then
			creature.humanoid.Jump = true
		end
		if distance <= creature.reach and now - creature.lastAttack > 1.1 then
			creature.lastAttack = now
			local victim = target:FindFirstChildOfClass("Humanoid")
			if victim and Combat.damage(nil, target, victim, creature.kind.damage) then
				Combat.applyEffect(
					nil,
					target,
					victim,
					"knockback",
					40 + creature.kind.scale * 15,
					creature.root.Position
				)
			end
		end
	elseif creature.lair and now - creature.lastSeen > 45 then
		untrack(creature)
		creature.model:Destroy()
	elseif now > creature.wanderAt then
		creature.wanderAt = now + random:NextNumber(4, 9)
		local fromHome = (creature.root.Position - creature.home).Magnitude
		local goal = if fromHome > 150
			then creature.home
			else creature.root.Position + Vector3.new(
				random:NextNumber(-40, 40),
				0,
				random:NextNumber(-40, 40)
			)
		if Vector2.new(goal.X, goal.Z).Magnitude > Config.LOBBY_RADIUS + 20 then
			creature.humanoid:MoveTo(goal)
		end
	end
end

-- Lairs --------------------------------------------------------------------------------------

-- Where each landmark's horde appears (CreatureCatalog).
local LAIRS = CreatureCatalog.LAIRS
local LAIR_TRIGGER_RADIUS = 175
local LAIR_COOLDOWN = 50

local lairCooldown: { [string]: number } = {}

local function liveFromLair(regionId: string): number
	local count = 0
	for _, creature in active do
		if creature.lair == regionId then
			count += 1
		end
	end
	return count
end

local function playersNear(center: Vector3, radius: number): number
	local count = 0
	for _, player in Players:GetPlayers() do
		local character, humanoid, root = Characters.living(player)
		if character and humanoid and root and player:GetAttribute(Names.Attributes.Deployed) then
			local offset = root.Position - center
			if Vector2.new(offset.X, offset.Z).Magnitude < radius then
				count += 1
			end
		end
	end
	return count
end

local function releaseHorde(index: number, size: number)
	local region = Config.REGIONS[index]
	local lair = LAIRS[region.id]
	local center = Config.regionCenter(index)
	local frame = CFrame.lookAt(center, Vector3.zero)
	Remotes.Announce:FireAllClients(
		"🧟 THE DEAD POUR OUT OF " .. string.upper(region.name) .. "! 🧟",
		rgb(150, 255, 120),
		4,
		RemoteActions.AnnounceStyle.ALARM
	)
	for count = 1, size do
		if #active >= MAX_ACTIVE then
			return
		end
		local x = lair.xs[random:NextInteger(1, #lair.xs)]
		local inside = frame
			* Vector3.new(
				x + random:NextNumber(-3, 3),
				lair.y,
				lair.inside + random:NextNumber(-2, 2)
			)
		local outside = frame * Vector3.new(x + random:NextNumber(-12, 12), 0, lair.outside)
		local kindId = if count % 8 == 0 then "brute" else "zombie"
		local creature = build(kindId, inside)
		creature.lair = region.id
		creature.exit = outside
		creature.exitUntil = os.clock() + 5
		track(creature, kindId, false)
		task.wait(0.2)
	end
end

local function watchLairs()
	while true do
		task.wait(1)
		local now = os.clock()
		for index, region in Config.REGIONS do
			local nearby = playersNear(Config.regionCenter(index), LAIR_TRIGGER_RADIUS)
			if
				nearby > 0
				and now >= (lairCooldown[region.id] or 0)
				and liveFromLair(region.id) < 30
			then
				lairCooldown[region.id] = now + LAIR_COOLDOWN
				task.spawn(releaseHorde, index, 14 + 6 * (nearby - 1))
			end
		end
	end
end

function Creatures.start()
	task.spawn(watchLairs)
	local mix = { goblin = 12, slime = 6, zombie = 30 }
	for _, region in Config.REGIONS do
		mix[REGION_KIND[region.id]] = 3
	end
	for kindId, count in mix do
		for _ = 1, count do
			spawnOne(kindId)
		end
	end
	task.spawn(function()
		while true do
			task.wait(0.3)
			local now = os.clock()
			for _, creature in table.clone(active) do
				if creature.humanoid.Health > 0 and creature.model.Parent then
					think(creature, now)
				end
			end
		end
	end)
end

function Creatures.killAll()
	for _, creature in table.clone(active) do
		creature.humanoid.Health = 0
	end
end

return Creatures
