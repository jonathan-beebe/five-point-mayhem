-- Monsters. Each landmark has a themed monster near it; goblins, slimes, and zombies wander
-- everywhere. They chase deployed players who come close and respawn after dying.
--
-- Every landmark is also a zombie lair: when a deployed player comes near, a horde pours out of
-- its main door. Horde zombies vanish if nobody is around for a while, and do not respawn.

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Combat = require(script.Parent.Combat)

local Creatures = {}

local rgb = Color3.fromRGB
local M = Enum.Material
local random = Random.new()

type Palette = { skin: Color3, body: Color3, eyes: Color3, legs: Color3 }

type Kind = {
	name: string,
	health: number,
	speed: number,
	damage: number,
	scale: number,
	aggro: number,
	palette: Palette,
	style: string,
}

local KINDS: { [string]: Kind } = {
	goblin = {
		name = "Goblin",
		health = 45,
		speed = 18,
		damage = 8,
		scale = 0.8,
		aggro = 80,
		style = "biped",
		palette = {
			skin = rgb(90, 160, 60),
			body = rgb(110, 80, 50),
			eyes = rgb(255, 230, 40),
			legs = rgb(80, 60, 40),
		},
	},
	slime = {
		name = "Slime",
		health = 35,
		speed = 14,
		damage = 6,
		scale = 1,
		aggro = 60,
		style = "slime",
		palette = {
			skin = rgb(80, 230, 90),
			body = rgb(80, 230, 90),
			eyes = rgb(20, 20, 20),
			legs = rgb(80, 230, 90),
		},
	},
	skeleton = {
		name = "Skeleton Knight",
		health = 90,
		speed = 15,
		damage = 14,
		scale = 1,
		aggro = 90,
		style = "biped",
		palette = {
			skin = rgb(235, 235, 220),
			body = rgb(120, 120, 130),
			eyes = rgb(255, 40, 40),
			legs = rgb(235, 235, 220),
		},
	},
	oni = {
		name = "Oni",
		health = 220,
		speed = 12,
		damage = 26,
		scale = 2,
		aggro = 100,
		style = "horned",
		palette = {
			skin = rgb(210, 50, 40),
			body = rgb(60, 50, 90),
			eyes = rgb(255, 230, 60),
			legs = rgb(210, 50, 40),
		},
	},
	robot = {
		name = "Robo-Guard",
		health = 140,
		speed = 16,
		damage = 18,
		scale = 1.4,
		aggro = 120,
		style = "biped",
		palette = {
			skin = rgb(160, 165, 175),
			body = rgb(60, 70, 90),
			eyes = rgb(60, 220, 255),
			legs = rgb(120, 125, 135),
		},
	},
	trex = {
		name = "T-Rex",
		health = 400,
		speed = 17,
		damage = 40,
		scale = 2.6,
		aggro = 130,
		style = "dino",
		palette = {
			skin = rgb(80, 120, 60),
			body = rgb(70, 105, 55),
			eyes = rgb(255, 200, 0),
			legs = rgb(70, 105, 55),
		},
	},
	zombie = {
		name = "Zombie",
		health = 60,
		speed = 13,
		damage = 10,
		scale = 1,
		aggro = 160,
		style = "zombie",
		palette = {
			skin = rgb(120, 165, 100),
			body = rgb(70, 90, 130),
			eyes = rgb(255, 40, 40),
			legs = rgb(80, 60, 45),
		},
	},
	brute = {
		name = "Zombie Brute",
		health = 260,
		speed = 11,
		damage = 25,
		scale = 1.8,
		aggro = 160,
		style = "zombie",
		palette = {
			skin = rgb(100, 140, 90),
			body = rgb(110, 40, 40),
			eyes = rgb(255, 120, 0),
			legs = rgb(60, 50, 40),
		},
	},
	yeti = {
		name = "Yeti",
		health = 260,
		speed = 13,
		damage = 28,
		scale = 2.2,
		aggro = 100,
		style = "biped",
		palette = {
			skin = rgb(240, 245, 255),
			body = rgb(230, 235, 245),
			eyes = rgb(60, 140, 255),
			legs = rgb(230, 235, 245),
		},
	},
}

-- Themed monster near each landmark, by region id.
local REGION_KIND =
	{ castle = "skeleton", pagoda = "oni", tower = "robot", pyramid = "trex", palace = "yeti" }

local folder = Instance.new("Folder")
folder.Name = "Creatures"
folder.Parent = workspace

type Creature = {
	model: Model,
	humanoid: Humanoid,
	root: BasePart,
	kind: Kind,
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

local function piece(
	model: Model,
	root: BasePart,
	size: Vector3,
	offset: CFrame,
	color: Color3,
	material: Enum.Material?,
	shape: Enum.PartType?,
	name: string?
): Part
	local part = Instance.new("Part")
	if shape then
		part.Shape = shape
	end
	part.Size = size
	part.Color = color
	part.Material = material or M.SmoothPlastic
	part.CanCollide = false
	part.Massless = true
	part.CFrame = root.CFrame * offset
	part.Name = name or "Part"
	local weld = Instance.new("Weld")
	weld.Part0 = root
	weld.Part1 = part
	weld.C0 = offset
	weld.Parent = part
	part.Parent = model
	return part
end

-- Humanoid bipeds stand on legs of length 2*s below a 2*s tall root; HipHeight matches.
local function biped(model: Model, root: BasePart, s: number, p: Palette, armAngle: number)
	piece(model, root, Vector3.new(2, 2, 1.1) * s, CFrame.new(), p.body)
	piece(
		model,
		root,
		Vector3.new(1.5, 1.4, 1.4) * s,
		CFrame.new(0, 1.75 * s, 0),
		p.skin,
		nil,
		nil,
		"Head"
	)
	for _, side in { -1, 1 } do
		piece(
			model,
			root,
			Vector3.new(0.3, 0.3, 0.1) * s,
			CFrame.new(side * 0.35 * s, 1.9 * s, -0.72 * s),
			p.eyes,
			M.Neon
		)
		piece(
			model,
			root,
			Vector3.new(0.8, 2, 0.8) * s,
			CFrame.new(side * 1.45 * s, 0, -0.2 * s) * CFrame.Angles(math.rad(armAngle), 0, 0),
			p.skin
		)
		piece(
			model,
			root,
			Vector3.new(0.9, 2, 0.9) * s,
			CFrame.new(side * 0.5 * s, -2 * s, 0),
			p.legs
		)
	end
end

local function build(kind: Kind, position: Vector3): Creature
	local s = kind.scale
	local model = Instance.new("Model")
	model.Name = kind.name
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Transparency = 1
	root.Size = if kind.style == "slime" then Vector3.new(3, 3, 3) * s else Vector3.new(2, 2, 1) * s
	root.CFrame = CFrame.new(position)
	root.Parent = model
	model.PrimaryPart = root

	local hipHeight = 2 * s
	local p = kind.palette
	if kind.style == "slime" then
		hipHeight = 0.2
		piece(
			model,
			root,
			Vector3.one * 4.2 * s,
			CFrame.new(0, 0.4 * s, 0),
			p.skin,
			M.Glass,
			Enum.PartType.Ball,
			"Head"
		).Transparency =
			0.25
		for _, side in { -1, 1 } do
			piece(
				model,
				root,
				Vector3.one * 0.7 * s,
				CFrame.new(side * 0.7 * s, 1 * s, -1.8 * s),
				p.eyes,
				M.SmoothPlastic,
				Enum.PartType.Ball
			)
		end
	else
		biped(model, root, s, p, if kind.style == "zombie" then 85 else 25)
		if kind.style == "horned" then
			for _, side in { -1, 1 } do
				piece(
					model,
					root,
					Vector3.new(0.3, 1, 0.3) * s,
					CFrame.new(side * 0.5 * s, 2.8 * s, 0) * CFrame.Angles(0, 0, -side * 0.3),
					rgb(240, 230, 200)
				)
			end
			piece(
				model,
				root,
				Vector3.new(0.5, 3.5, 0.5) * s,
				CFrame.new(1.6 * s, 0, -1.4 * s) * CFrame.Angles(math.rad(70), 0, 0),
				rgb(40, 40, 40),
				M.Metal
			)
		elseif kind.style == "dino" then
			piece(
				model,
				root,
				Vector3.new(1.4, 1.2, 2.4) * s,
				CFrame.new(0, 1.9 * s, -1.4 * s),
				p.skin,
				nil,
				nil,
				"Snout"
			)
			piece(
				model,
				root,
				Vector3.new(1.3, 0.3, 2) * s,
				CFrame.new(0, 1.15 * s, -1.4 * s),
				rgb(250, 245, 230)
			)
			piece(
				model,
				root,
				Vector3.new(1.2, 1.2, 4) * s,
				CFrame.new(0, -0.3 * s, 2.3 * s) * CFrame.Angles(math.rad(-15), 0, 0),
				p.body
			)
		end
	end
	if kind.name == "Skeleton Knight" then
		piece(
			model,
			root,
			Vector3.new(0.2, 0.5, 4),
			CFrame.new(1.45 * s, -0.6 * s, -2.4),
			rgb(200, 200, 210),
			M.Metal
		)
	end

	local humanoid = Instance.new("Humanoid")
	humanoid.RequiresNeck = false
	humanoid.HipHeight = hipHeight
	humanoid.MaxHealth = kind.health
	humanoid.Health = kind.health
	humanoid.WalkSpeed = kind.speed
	humanoid:SetAttribute("BaseWalkSpeed", kind.speed)
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOn
	humanoid.Parent = model

	model:PivotTo(
		CFrame.new(position + Vector3.new(0, hipHeight + root.Size.Y / 2 + 0.5, 0))
			* CFrame.Angles(0, random:NextNumber(0, 6), 0)
	)
	model.Parent = folder
	root:SetNetworkOwner(nil)
	return {
		model = model,
		humanoid = humanoid,
		root = root,
		kind = kind,
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
	local kind = KINDS[kindId]
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
	track(build(kind, position), kindId, near == nil)
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

local function nearestPlayer(creature: Creature): (Model?, BasePart?, number)
	local best, bestRoot, bestDistance = nil, nil, creature.kind.aggro
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if
			root
			and humanoid
			and humanoid.Health > 0
			and player:GetAttribute("Deployed")
			and not Config.isInLobby(root.Position)
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
	local reach = 4 + 2 * creature.kind.scale
	if target and targetRoot then
		creature.lastSeen = now
		creature.humanoid:MoveTo(targetRoot.Position)
		if creature.kind.style == "slime" then
			creature.humanoid.Jump = true
		end
		if distance <= reach and now - creature.lastAttack > 1.1 then
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

-- Where each landmark's horde appears and walks out to, in the landmark's local frame (local -Z
-- faces the lobby). `y` is the floor height inside; `xs` are the doors used.
local LAIRS = {
	castle = { inside = 10, outside = -105, y = 1.6, xs = { 0 } }, -- out of the keep, through the gate
	pagoda = { inside = -27, outside = -80, y = 5, xs = { 0 } },
	tower = { inside = -24, outside = -55, y = 1.8, xs = { 0 } },
	pyramid = { inside = -72, outside = -105, y = 0.6, xs = { -40, 40 } },
	palace = { inside = -27, outside = -60, y = 1.6, xs = { 0 } },
}
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
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if root and humanoid and humanoid.Health > 0 and player:GetAttribute("Deployed") then
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
		"alarm"
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
		local creature = build(KINDS[kindId], inside)
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
