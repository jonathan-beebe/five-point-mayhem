-- Damage rules, kill credit, status effects, explosions, and explosive barrels.
-- Every hit in the game goes through Combat.damage so the lobby safe zone, teams, and shields
-- apply everywhere.

local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Names = require(ReplicatedStorage.Shared.Names)
local SoundCatalog = require(ReplicatedStorage.Shared.SoundCatalog)
local Sounds = require(ReplicatedStorage.Shared.Sounds)

local Combat = {}

export type Target = { model: Model, humanoid: Humanoid, root: BasePart }

-- Finds the character a part belongs to: the nearest ancestor Model holding a Humanoid.
function Combat.findCharacter(part: Instance): (Model?, Humanoid?)
	local model = part:FindFirstAncestorOfClass("Model")
	while model do
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		if humanoid then
			return model, humanoid
		end
		model = model:FindFirstAncestorOfClass("Model")
	end
	return nil, nil
end

function Combat.isFreeForAll(player: Player): boolean
	return player.Team == nil or player.Team.Name == Config.FFA_TEAM
end

function Combat.areAllies(a: Player, b: Player): boolean
	if a == b then
		return true
	end
	return not Combat.isFreeForAll(a) and a.Team == b.Team
end

-- True when `attacker` may hurt this character. A nil attacker is the environment (creatures,
-- meteors, god powers) and may hurt anyone outside the lobby.
function Combat.canDamage(attacker: Player?, character: Model, humanoid: Humanoid): boolean
	if humanoid.Health <= 0 then
		return false
	end
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root and Config.isInLobby(root.Position) then
		return false
	end
	local victim = Players:GetPlayerFromCharacter(character)
	if victim and Config.STUDIO_IMMUNE and RunService:IsStudio() then
		return false
	end
	if not attacker then
		return true
	end
	if character == attacker.Character then
		return false
	end
	return victim == nil or not Combat.areAllies(attacker, victim)
end

-- Every living player character and creature, for area effects.
function Combat.getTargets(): { Target }
	local targets = {}
	local function consider(model: Instance?)
		if not model or not model:IsA("Model") then
			return
		end
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		local root = model:FindFirstChild("HumanoidRootPart")
		if humanoid and root and humanoid.Health > 0 then
			table.insert(targets, { model = model, humanoid = humanoid, root = root :: BasePart })
		end
	end
	for _, player in Players:GetPlayers() do
		consider(player.Character)
	end
	local creatures = workspace:FindFirstChild(Names.Instances.Creatures)
	if creatures then
		for _, creature in creatures:GetChildren() do
			consider(creature)
		end
	end
	return targets
end

local function credit(attacker: Player, character: Model)
	local stats = attacker:FindFirstChild(Names.Instances.Leaderstats)
	if not stats then
		return
	end
	local isPlayer = Players:GetPlayerFromCharacter(character) ~= nil
	local stat = stats:FindFirstChild(if isPlayer then "KOs" else "Monsters") :: IntValue?
	if stat then
		stat.Value += 1
	end
end

-- Applies damage if the rules allow it. Returns true when the hit landed.
function Combat.damage(
	attacker: Player?,
	character: Model,
	humanoid: Humanoid,
	amount: number
): boolean
	if not Combat.canDamage(attacker, character, humanoid) then
		return false
	end
	local wasAlive = humanoid.Health > 0
	humanoid:TakeDamage(amount) -- TakeDamage respects ForceField shields.
	if attacker and wasAlive and humanoid.Health <= 0 then
		credit(attacker, character)
	end
	return true
end

-- Status effects ------------------------------------------------------------------------------

-- Pushes a character with a short-lived velocity constraint. Constraints replicate to the owning
-- client, so this works on player characters, whose physics the server does not own.
function Combat.push(character: Model, velocity: Vector3, seconds: number)
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root or root.Anchored then
		return
	end
	local attachment = root:FindFirstChild("PushAttachment") :: Attachment?
	if not attachment then
		local created = Instance.new("Attachment")
		created.Name = "PushAttachment"
		created.Parent = root
		attachment = created
	end
	local mover = Instance.new("LinearVelocity")
	mover.Attachment0 = attachment
	mover.MaxForce = math.huge
	mover.VectorVelocity = velocity
	mover.RelativeTo = Enum.ActuatorRelativeTo.World
	mover.Parent = root
	Debris:AddItem(mover, seconds)
end

function Combat.freeze(character: Model, seconds: number)
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end
	local token = os.clock()
	character:SetAttribute("FrozenToken", token)
	root.Anchored = true
	local old = character:FindFirstChild("IceBlock")
	if old then
		old:Destroy()
	end
	local extents = character:GetExtentsSize()
	local ice = Instance.new("Part")
	ice.Name = "IceBlock"
	ice.Anchored = true
	ice.CanCollide = false
	ice.CanQuery = false
	ice.Size = extents + Vector3.new(1, 1, 1)
	ice.CFrame = character:GetPivot()
	ice.Color = Color3.fromRGB(160, 220, 255)
	ice.Material = Enum.Material.Ice
	ice.Transparency = 0.35
	ice.Parent = character
	task.delay(seconds, function()
		if character:GetAttribute("FrozenToken") ~= token then
			return
		end
		ice:Destroy()
		if root.Parent then
			root.Anchored = false
		end
	end)
end

local function slow(character: Model, humanoid: Humanoid, seconds: number)
	local base = humanoid:GetAttribute(Names.Attributes.BaseWalkSpeed) or humanoid.WalkSpeed
	humanoid:SetAttribute(Names.Attributes.BaseWalkSpeed, base)
	local token = os.clock()
	humanoid:SetAttribute("SlowToken", token)
	humanoid.WalkSpeed = base * 0.45
	task.delay(seconds, function()
		if humanoid:GetAttribute("SlowToken") == token and humanoid.Parent then
			humanoid.WalkSpeed = humanoid:GetAttribute(Names.Attributes.BaseWalkSpeed) :: number
		end
	end)
	local root = character:FindFirstChild("HumanoidRootPart")
	if root then
		local frost = Instance.new("Sparkles")
		frost.SparkleColor = Color3.fromRGB(170, 230, 255)
		frost.Parent = root
		Debris:AddItem(frost, seconds)
	end
end

local function burn(attacker: Player?, character: Model, humanoid: Humanoid, perTick: number)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root or root:FindFirstChild("MayhemFire") then
		return
	end
	local fire = Instance.new("Fire")
	fire.Name = "MayhemFire"
	fire.Size = 6
	fire.Parent = root
	task.spawn(function()
		for _ = 1, 6 do
			task.wait(0.5)
			if humanoid.Health <= 0 then
				break
			end
			Combat.damage(attacker, character, humanoid, perTick)
		end
		fire:Destroy()
	end)
end

-- `from` is where the blow came from, for knockback direction.
function Combat.applyEffect(
	attacker: Player?,
	character: Model,
	humanoid: Humanoid,
	effect: string?,
	power: number?,
	from: Vector3?
)
	if not effect or humanoid.Health <= 0 then
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end
	if effect == "burn" then
		burn(attacker, character, humanoid, power or 4)
	elseif effect == "freeze" then
		Combat.freeze(character, power or 2.5)
	elseif effect == "slow" then
		slow(character, humanoid, power or 3)
	elseif effect == "knockback" then
		local away = root.Position - (from or root.Position - root.CFrame.LookVector)
		local flat = Vector3.new(away.X, 0, away.Z)
		local direction = if flat.Magnitude > 0.01 then flat.Unit else Vector3.zAxis
		Combat.push(character, direction * (power or 60) + Vector3.new(0, 35, 0), 0.2)
	elseif effect == "launch" then
		Combat.push(character, Vector3.new(0, power or 100, 0), 0.25)
	elseif effect == "float" then
		local bubble = Instance.new("Part")
		bubble.Shape = Enum.PartType.Ball
		bubble.Size = Vector3.one * 9
		bubble.CanCollide = false
		bubble.CanQuery = false
		bubble.Massless = true
		bubble.Material = Enum.Material.Glass
		bubble.Transparency = 0.6
		bubble.Color = Color3.fromRGB(170, 220, 255)
		bubble.CFrame = root.CFrame
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = root
		weld.Part1 = bubble
		weld.Parent = bubble
		bubble.Parent = character
		Debris:AddItem(bubble, power or 3)
		Combat.push(character, Vector3.new(0, 10, 0), power or 3)
	end
end

-- Damage plus effect, for a direct hit on a part. Returns the character hit, if any.
function Combat.hitPart(
	attacker: Player?,
	part: BasePart,
	damage: number,
	effect: string?,
	power: number?,
	from: Vector3?
): Model?
	if CollectionService:HasTag(part, Names.Tags.ExplosiveBarrel) then
		Combat.detonateBarrel(part, attacker)
		return nil
	end
	local character, humanoid = Combat.findCharacter(part)
	if character and humanoid and Combat.damage(attacker, character, humanoid, damage) then
		Combat.applyEffect(attacker, character, humanoid, effect, power, from)
		return character
	end
	return nil
end

-- Explosions ----------------------------------------------------------------------------------

-- The sound for an explosion without a weapon cue: louder for bigger blasts.
local function defaultBoom(radius: number): SoundCatalog.Cue
	local spec = SoundCatalog.EXPLOSION
	return {
		key = spec.key,
		volume = math.min(spec.base + spec.perRadius * radius, spec.max),
		jitter = spec.jitter,
		range = "explosion",
	}
end

-- Damages and throws everyone within `radius`, and sets off barrels in reach. No visual or sound.
function Combat.blast(
	attacker: Player?,
	position: Vector3,
	radius: number,
	damage: number,
	effect: string?,
	power: number?
)
	for _, target in Combat.getTargets() do
		local distance = (target.root.Position - position).Magnitude
		if distance <= radius + 2 then
			local scaled = damage * (1 - 0.5 * math.clamp(distance / radius, 0, 1))
			if Combat.damage(attacker, target.model, target.humanoid, scaled) then
				Combat.applyEffect(attacker, target.model, target.humanoid, effect, power, position)
				if effect ~= "knockback" and effect ~= "freeze" then
					local away = target.root.Position - position
					local direction = if away.Magnitude > 0.1 then away.Unit else Vector3.yAxis
					Combat.push(target.model, direction * 50 + Vector3.new(0, 40, 0), 0.15)
				end
			end
		end
	end

	for _, barrel in CollectionService:GetTagged(Names.Tags.ExplosiveBarrel) do
		if (barrel.Position - position).Magnitude <= radius + 2 then
			task.delay(0.15, Combat.detonateBarrel, barrel, attacker)
		end
	end
end

-- A blast with a fireball. `sound` is the weapon's impact cue; without one the blast plays a
-- generic boom.
function Combat.explode(
	attacker: Player?,
	position: Vector3,
	radius: number,
	damage: number,
	effect: string?,
	power: number?,
	sound: SoundCatalog.Cue?
)
	local blast = Instance.new("Explosion")
	blast.Position = position
	blast.BlastRadius = radius
	blast.BlastPressure = 0
	blast.DestroyJointRadiusPercent = 0
	blast.ExplosionType = Enum.ExplosionType.NoCraters
	blast.Parent = workspace
	Sounds.playAt(sound or defaultBoom(radius), position, "Weapons", SoundCatalog.EXPLOSION_GAIN)
	Combat.blast(attacker, position, radius, damage, effect, power)
end

local barrelFactory: ((Instance, CFrame) -> BasePart)? = nil

function Combat.setBarrelFactory(factory: (Instance, CFrame) -> BasePart)
	barrelFactory = factory
end

-- Barrels explode when shot, and come back a minute later.
function Combat.detonateBarrel(barrel: BasePart, attacker: Player?)
	if barrel:GetAttribute("Detonated") or not barrel.Parent then
		return
	end
	barrel:SetAttribute("Detonated", true)
	local parent = barrel.Parent
	local home = barrel:GetAttribute(Names.Attributes.Home) :: CFrame?
	local position = barrel.Position
	barrel:Destroy()
	Combat.explode(attacker, position, 18, 55)
	if home and barrelFactory then
		task.delay(60, function()
			if parent and parent.Parent then
				(barrelFactory :: (Instance, CFrame) -> BasePart)(parent, home)
			end
		end)
	end
end

return Combat
