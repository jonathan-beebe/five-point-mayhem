-- Builds weapon tools from the catalog and resolves every shot on the server.
-- Clients only report "I fired weapon X at point P"; range, cooldown, damage, and the safe
-- zone are all enforced here.

local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local MathUtil = require(ReplicatedStorage.Shared.MathUtil)
local Names = require(ReplicatedStorage.Shared.Names)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local WeaponCatalog = require(ReplicatedStorage.Shared.WeaponCatalog)
local Combat = require(script.Parent.Combat)
local WeaponModel = require(script.Parent.WeaponModel)
local WeaponSounds = require(script.Parent.WeaponSounds)
local Characters = require(script.Parent.util.Characters)
local Parts = require(script.Parent.util.Parts)

local modelFiles = script.Parent.Parent:FindFirstChild("weaponModels")

type Weapon = WeaponCatalog.Weapon

local Weapons = {}

local rgb = Color3.fromRGB
local M = Enum.Material
local GRIP = rgb(45, 40, 38)
local random = Random.new()

local effectsFolder = Instance.new("Folder")
effectsFolder.Name = Names.Instances.WeaponEffects
effectsFolder.Parent = workspace

-- Tool models ---------------------------------------------------------------------------------

type PieceSpec = WeaponModel.PieceSpec

local CYLINDER_Z = WeaponModel.CYLINDER_Z
local CYLINDER_Y = WeaponModel.CYLINDER_Y

-- Fallback pieces for weapons without a file in `weaponModels`, in handle space. The hand holds the handle; local -Z points away from the wielder.
local function pieces(weapon: Weapon): { PieceSpec }
	local c = weapon.color
	local glow = if weapon.neon then M.Neon else M.Metal
	local L = weapon.length or 3
	local shape = weapon.shape
	if shape == "blade" then
		return {
			{
				size = Vector3.new(1.6, 0.3, 0.35),
				offset = CFrame.new(0, 0, -0.7),
				color = rgb(120, 100, 60),
				material = M.Metal,
			},
			{
				size = Vector3.new(0.18, 0.7, L),
				offset = CFrame.new(0, 0, -0.85 - L / 2),
				color = c,
				material = glow,
			},
			{
				size = Vector3.one * 0.5,
				offset = CFrame.new(0, 0, 0.75),
				color = rgb(120, 100, 60),
				material = M.Metal,
				shape = Enum.PartType.Ball,
			},
		}
	elseif shape == "axe" then
		return {
			{
				size = Vector3.new(0.3, 0.3, L),
				offset = CFrame.new(0, 0, -L / 2 + 0.6),
				color = rgb(100, 70, 45),
				material = M.Wood,
			},
			{
				size = Vector3.new(0.25, 2, 1.6),
				offset = CFrame.new(0, 0.7, -L + 1),
				color = c,
				material = glow,
			},
		}
	elseif shape == "hammer" then
		return {
			{
				size = Vector3.new(0.35, 0.35, L),
				offset = CFrame.new(0, 0, -L / 2 + 0.6),
				color = rgb(100, 70, 45),
				material = M.Wood,
			},
			{
				size = Vector3.new(1.6, 1.6, 2.6),
				offset = CFrame.new(0, 0, -L + 0.4) * CFrame.Angles(0, math.rad(90), 0),
				color = c,
				material = glow,
			},
		}
	elseif shape == "spear" then
		return {
			{
				size = Vector3.new(0.25, 0.25, L),
				offset = CFrame.new(0, 0, -L / 2 + 1.5),
				color = rgb(110, 80, 50),
				material = M.Wood,
			},
			{
				size = Vector3.new(0.2, 0.7, 1.6),
				offset = CFrame.new(0, 0, -L + 0.7),
				color = c,
				material = glow,
			},
			{
				size = Vector3.new(1.4, 0.2, 0.2),
				offset = CFrame.new(0, 0, -L + 1.4),
				color = c,
				material = glow,
			},
		}
	elseif shape == "scythe" then
		return {
			{
				size = Vector3.new(0.3, 0.3, L),
				offset = CFrame.new(0, 0, -L / 2 + 1),
				color = rgb(60, 45, 35),
				material = M.Wood,
			},
			{
				size = Vector3.new(3.4, 0.8, 0.15),
				offset = CFrame.new(1.5, 0, -L + 1.2) * CFrame.Angles(0, 0, math.rad(-10)),
				color = rgb(200, 200, 210),
				material = M.Metal,
			},
		}
	elseif shape == "pan" then
		return {
			{
				size = Vector3.new(0.3, 0.3, L),
				offset = CFrame.new(0, 0, -L / 2 + 0.6),
				color = GRIP,
				material = M.Metal,
			},
			{
				size = Vector3.new(0.3, 3, 3),
				offset = CFrame.new(0, 0, -L - 0.6),
				color = c,
				material = M.Metal,
				shape = Enum.PartType.Cylinder,
			},
		}
	elseif shape == "gun" then
		return {
			{
				size = Vector3.new(0.45, 0.55, L),
				offset = CFrame.new(0, 0.45, -L / 2 + 0.4),
				color = c,
				material = if weapon.neon then M.SmoothPlastic else M.Metal,
			},
			{
				size = Vector3.new(L * 0.4, 0.3, 0.3),
				offset = CFrame.new(0, 0.5, -L - 0.2 + L * 0.2) * CYLINDER_Z,
				color = rgb(40, 40, 45),
				material = M.Metal,
				shape = Enum.PartType.Cylinder,
			},
			{
				size = Vector3.new(0.5, 0.2, 0.5),
				offset = CFrame.new(0, 0.8, -L + 0.5),
				color = c,
				material = glow,
			},
		}
	elseif shape == "tube" then
		return {
			{
				size = Vector3.new(L, 0.9, 0.9),
				offset = CFrame.new(0, 0.7, -L / 2 + 1) * CYLINDER_Z,
				color = c,
				material = if weapon.neon then M.SmoothPlastic else M.Metal,
				shape = Enum.PartType.Cylinder,
			},
			{
				size = Vector3.new(0.4, 1.1, 1.1),
				offset = CFrame.new(0, 0.7, -L + 1) * CYLINDER_Z,
				color = c,
				material = glow,
				shape = Enum.PartType.Cylinder,
			},
		}
	elseif shape == "staff" then
		return {
			{
				size = Vector3.new(L, 0.35, 0.35),
				offset = CFrame.new(0, L / 2 - 1.5, 0) * CYLINDER_Y,
				color = rgb(90, 60, 40),
				material = M.Wood,
				shape = Enum.PartType.Cylinder,
			},
			{
				size = Vector3.one * 1.3,
				offset = CFrame.new(0, L - 1, 0),
				color = c,
				material = glow,
				shape = Enum.PartType.Ball,
			},
		}
	elseif shape == "wand" then
		return {
			{
				size = Vector3.new(0.2, 0.2, L),
				offset = CFrame.new(0, 0, -L / 2 + 0.5),
				color = rgb(60, 40, 30),
				material = M.Wood,
			},
			{
				size = Vector3.one * 0.6,
				offset = CFrame.new(0, 0, -L + 0.4),
				color = c,
				material = glow,
				shape = Enum.PartType.Ball,
			},
		}
	elseif shape == "orb" then
		return {
			{
				size = Vector3.one * 1.6,
				offset = CFrame.new(0, 0.4, -0.6),
				color = c,
				material = glow,
				shape = Enum.PartType.Ball,
			},
		}
	elseif shape == "ball" then
		return {
			{
				size = Vector3.one * L,
				offset = CFrame.new(0, 0.2, -0.4),
				color = c,
				material = M.SmoothPlastic,
				shape = Enum.PartType.Ball,
			},
		}
	elseif shape == "chicken" then
		return {
			{
				size = Vector3.new(0.9, 0.9, 2.4),
				offset = CFrame.new(0, 0, -1.6),
				color = c,
				material = M.SmoothPlastic,
			},
			{
				size = Vector3.one * 0.9,
				offset = CFrame.new(0, 0.5, -3),
				color = c,
				material = M.SmoothPlastic,
				shape = Enum.PartType.Ball,
			},
			{
				size = Vector3.new(0.2, 0.5, 0.6),
				offset = CFrame.new(0, 1.05, -3),
				color = rgb(220, 30, 30),
				material = M.SmoothPlastic,
			},
			{
				size = Vector3.new(0.3, 0.2, 0.5),
				offset = CFrame.new(0, 0.5, -3.6),
				color = rgb(255, 150, 30),
				material = M.SmoothPlastic,
			},
		}
	elseif shape == "noodle" then
		return {
			{
				size = Vector3.new(L, 0.8, 0.8),
				offset = CFrame.new(0, 0, -L / 2 + 0.6) * CYLINDER_Z,
				color = c,
				material = M.SmoothPlastic,
				shape = Enum.PartType.Cylinder,
			},
		}
	elseif shape == "lollipop" then
		return {
			{
				size = Vector3.new(0.25, 0.25, L),
				offset = CFrame.new(0, 0, -L / 2 + 0.6),
				color = rgb(250, 250, 250),
				material = M.SmoothPlastic,
			},
			{
				size = Vector3.new(0.5, 3.2, 3.2),
				offset = CFrame.new(0, 0, -L - 1),
				color = c,
				material = M.SmoothPlastic,
				shape = Enum.PartType.Cylinder,
			},
			{
				size = Vector3.new(0.55, 1.6, 1.6),
				offset = CFrame.new(0, 0, -L - 1),
				color = rgb(255, 255, 255),
				material = M.SmoothPlastic,
				shape = Enum.PartType.Cylinder,
			},
		}
	end
	return {}
end

-- A weapon's file in `weaponModels`, or a model built from its catalog shape.
local models: { [string]: WeaponModel.Model } = {}
local function modelFor(weapon: Weapon): WeaponModel.Model
	local model = models[weapon.id]
	if model then
		return model
	end
	local file = modelFiles and modelFiles:FindFirstChild(weapon.id)
	model = if file
		then require(file :: ModuleScript) :: WeaponModel.Model
		else { pieces = pieces(weapon) }
	models[weapon.id] = model
	return model
end

-- A piece's part, invisible to queries and massless. Without a piece name it keeps the class's
-- default Name.
local function createPart(spec: PieceSpec, scale: number?): BasePart
	local part = Parts.fromPiece(spec, nil, scale)
	part.CanQuery = false
	part.Massless = true
	return part
end

local function attach(handle: BasePart, spec: PieceSpec, parent: Instance)
	Parts.weldTo(handle, createPart(spec), spec.offset, parent)
end

local function makeHandle(weapon: Weapon): Part
	local spec = modelFor(weapon).handle or {}
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = spec.size or Vector3.new(0.4, 0.4, 1.2)
	handle.Color = spec.color or GRIP
	handle.Material = spec.material or M.SmoothPlastic
	handle.Transparency = spec.transparency or 0
	handle.CanCollide = false
	handle.CanQuery = false
	handle.Massless = true
	return handle
end

function Weapons.createTool(weapon: Weapon): Tool
	local tool = Instance.new("Tool")
	tool.Name = weapon.name
	tool.ToolTip = weapon.description
	tool.CanBeDropped = false
	tool:SetAttribute(Names.Attributes.WeaponId, weapon.id)
	-- Shot muzzles are handle.CFrame * muzzle, so they follow the grip.
	tool.Grip = WeaponModel.grip(modelFor(weapon))
	local handle = makeHandle(weapon)
	WeaponSounds.equip(handle, weapon.id)
	handle.Parent = tool
	for _, spec in modelFor(weapon).pieces do
		attach(handle, spec, tool)
	end
	return tool
end

-- An anchored copy of a weapon for display stands, pivoting about the fist. Upright weapons stand
-- upright (as held), centered vertically on the pivot.
function Weapons.displayModel(weaponId: string): Model?
	local weapon = WeaponCatalog.get(weaponId)
	if not weapon then
		return nil
	end
	local SCALE = 1.6
	local spec = modelFor(weapon)
	local hold = WeaponModel.grip(spec):Inverse()
	if spec.hold == "upright" then
		local low, high = math.huge, -math.huge
		for _, piece in spec.pieces do
			local y = (hold * (piece.offset.Position * SCALE)).Y
			low = math.min(low, y)
			high = math.max(high, y)
		end
		if low <= high then
			hold = CFrame.new(0, -(low + high) / 2, 0) * hold
		end
	end
	local model = Instance.new("Model")
	model.Name = weapon.name
	local handle = makeHandle(weapon)
	handle.Anchored = true
	handle.CFrame = hold
	handle.PivotOffset = hold:Inverse()
	handle.Parent = model
	for _, piece in spec.pieces do
		local part = createPart(piece, SCALE)
		part.Anchored = true
		part.CFrame = hold * CFrame.new(piece.offset.Position * SCALE) * piece.offset.Rotation
		part.Parent = model
	end
	handle.Size *= SCALE
	model.PrimaryPart = handle
	return model
end

function Weapons.give(player: Player, weaponId: string): boolean
	local weapon = WeaponCatalog.get(weaponId)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not weapon or not backpack then
		return false
	end
	Weapons.createTool(weapon).Parent = backpack
	return true
end

-- Visual helpers ------------------------------------------------------------------------------

local function beam(from: Vector3, to: Vector3, color: Color3, width: number, life: number)
	local length = (to - from).Magnitude
	if length < 0.1 then
		return
	end
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Material = M.Neon
	part.Color = color
	part.Size = Vector3.new(width, width, length)
	part.CFrame = CFrame.lookAt((from + to) / 2, to)
	part.Parent = effectsFolder
	TweenService:Create(part, TweenInfo.new(life), { Transparency = 1 }):Play()
	Debris:AddItem(part, life)
end

local function flash(position: Vector3, color: Color3, size: number)
	local part = Instance.new("Part")
	part.Shape = Enum.PartType.Ball
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Material = M.Neon
	part.Color = color
	part.Size = Vector3.one * size
	part.CFrame = CFrame.new(position)
	part.Parent = effectsFolder
	TweenService
		:Create(part, TweenInfo.new(0.3), { Transparency = 1, Size = Vector3.one * size * 2 })
		:Play()
	Debris:AddItem(part, 0.3)
end

-- Jagged bolt from the sky (or between two points).
local function lightning(from: Vector3, to: Vector3, color: Color3)
	local segments = 8
	local previous = from
	for index = 1, segments do
		local point = from:Lerp(to, index / segments)
		if index < segments then
			point += Vector3.new(
				random:NextNumber(-3, 3),
				random:NextNumber(-1, 1),
				random:NextNumber(-3, 3)
			)
		end
		beam(previous, point, color, 0.6, 0.25)
		previous = point
	end
end

-- Aiming -------------------------------------------------------------------------------------

local function spreadDirection(direction: Vector3, degrees: number): Vector3
	if degrees <= 0 then
		return direction
	end
	local frame = CFrame.lookAt(Vector3.zero, direction)
	local pitch = math.rad(random:NextNumber(-degrees, degrees))
	local yaw = math.rad(random:NextNumber(-degrees, degrees))
	return (frame * CFrame.Angles(pitch, yaw, 0)).LookVector
end

-- Raycast that passes through teammates and non-solid scenery.
local function raycast(player: Player, origin: Vector3, vector: Vector3): RaycastResult?
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character :: Model, effectsFolder }
	for _ = 1, 8 do
		local result = workspace:Raycast(origin, vector, params)
		if not result then
			return nil
		end
		local character, humanoid = Combat.findCharacter(result.Instance)
		local isAlly = character
			and humanoid
			and Players:GetPlayerFromCharacter(character) ~= nil
			and not Combat.canDamage(player, character, humanoid)
		if isAlly then
			params:AddToFilter(character :: Model)
		else
			return result
		end
	end
	return nil
end

-- Kinds of weapon ----------------------------------------------------------------------------

type Shot = {
	player: Player,
	weapon: Weapon,
	character: Model,
	root: BasePart,
	origin: Vector3, -- eye point the shot is resolved from
	muzzle: Vector3, -- where effects start
	aim: Vector3,
}

local function fireMelee(shot: Shot)
	local weapon = shot.weapon
	local look = shot.root.CFrame.LookVector
	local flatLook = Vector3.new(look.X, 0, look.Z).Unit
	local minimumDot = weapon.arc or 0.3
	local struck = false
	for _, target in Combat.getTargets() do
		if target.model ~= shot.character then
			local offset = target.root.Position - shot.root.Position
			local flat = Vector3.new(offset.X, 0, offset.Z)
			local inReach = offset.Magnitude <= weapon.range + 1.5
			local inFront = flat.Magnitude < 2 or flatLook:Dot(flat.Unit) >= minimumDot
			if
				inReach
				and inFront
				and Combat.damage(shot.player, target.model, target.humanoid, weapon.damage)
			then
				Combat.applyEffect(
					shot.player,
					target.model,
					target.humanoid,
					weapon.effect,
					weapon.power,
					shot.root.Position
				)
				flash(target.root.Position, weapon.color, 2)
				if not struck then
					struck = true -- one hit sound per swing
					WeaponSounds.at(weapon.id, "hit", target.root.Position)
				end
			end
		end
	end
	for _, barrel in CollectionService:GetTagged(Names.Tags.ExplosiveBarrel) do
		if (barrel.Position - shot.root.Position).Magnitude <= weapon.range then
			Combat.detonateBarrel(barrel, shot.player)
		end
	end
	local tool = shot.character:FindFirstChildOfClass("Tool")
	if tool then
		local animation = Instance.new("StringValue")
		animation.Name = "toolanim"
		animation.Value = if weapon.range > 11 then "Lunge" else "Slash"
		animation.Parent = tool
		Debris:AddItem(animation, 1)
	end
end

local function chainLightning(shot: Shot, from: Model, jumps: number)
	local hit: { [Model]: boolean } = { [from] = true }
	local current = from
	for _ = 1, jumps do
		local currentRoot = current:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not currentRoot then
			return
		end
		local best: Combat.Target? = nil
		local bestDistance = 30
		for _, target in Combat.getTargets() do
			local distance = (target.root.Position - currentRoot.Position).Magnitude
			if
				not hit[target.model]
				and distance < bestDistance
				and Combat.canDamage(shot.player, target.model, target.humanoid)
			then
				best, bestDistance = target, distance
			end
		end
		if not best then
			return
		end
		hit[best.model] = true
		lightning(currentRoot.Position, best.root.Position, shot.weapon.color)
		Combat.damage(shot.player, best.model, best.humanoid, shot.weapon.damage * 0.6)
		WeaponSounds.at(shot.weapon.id, "chain", best.root.Position)
		current = best.model
	end
end

local function fireHitscan(shot: Shot)
	local weapon = shot.weapon
	local direction = (shot.aim - shot.origin).Unit
	local width = if weapon.neon then 0.35 else 0.12
	local struck = false
	for _ = 1, weapon.pellets or 1 do
		local vector = spreadDirection(direction, weapon.spread or 0) * weapon.range
		local result = raycast(shot.player, shot.origin, vector)
		local finish = if result then result.Position else shot.origin + vector
		if weapon.chain then
			lightning(shot.muzzle, finish, weapon.color)
		else
			beam(
				shot.muzzle,
				finish,
				if weapon.neon then weapon.color else rgb(255, 230, 150),
				width,
				if weapon.neon then 0.15 else 0.06
			)
		end
		if result then
			local victim = Combat.hitPart(
				shot.player,
				result.Instance :: BasePart,
				weapon.damage,
				weapon.effect,
				weapon.power,
				shot.origin
			)
			if victim and not struck then
				struck = true -- one hit sound per trigger, however many pellets land
				WeaponSounds.at(weapon.id, "hit", result.Position)
			end
			if victim and weapon.chain then
				chainLightning(shot, victim, weapon.chain)
			end
		end
	end
end

-- Projectiles ---------------------------------------------------------------------------------

type Projectile = {
	shot: Shot,
	part: BasePart,
	position: Vector3,
	velocity: Vector3,
	gravity: number,
	born: number,
	params: RaycastParams,
}

local projectiles: { Projectile } = {}

local function projectileVisual(weapon: Weapon): BasePart
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Color = weapon.color
	if weapon.category == "Explosives" and weapon.shape == "tube" then
		part.Size = Vector3.new(0.7, 0.7, 2.6)
		part.Material = M.Metal
		local fire = Instance.new("Fire")
		fire.Size = 2
		fire.Heat = 0
		fire.Parent = part
	else
		part.Shape = Enum.PartType.Ball
		local size = if weapon.impact == "blackhole" then 2.5 elseif weapon.blast then 1.6 else 0.8
		part.Size = Vector3.one * size
		part.Material = if weapon.neon then M.Neon else M.SmoothPlastic
		if weapon.effect == "burn" then
			Instance.new("Fire", part).Size = 3
		end
	end
	part.Parent = effectsFolder
	return part
end

local function blackHole(shot: Shot, position: Vector3)
	local weapon = shot.weapon
	local core = Instance.new("Part")
	core.Shape = Enum.PartType.Ball
	core.Anchored = true
	core.CanCollide = false
	core.CanQuery = false
	core.Material = M.Neon
	core.Color = rgb(20, 0, 40)
	core.Size = Vector3.one * 6
	core.CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
	core.Parent = effectsFolder
	WeaponSounds.on(weapon.id, "loop", core)
	TweenService:Create(core, TweenInfo.new(3), { Size = Vector3.one * 14 }):Play()
	local radius = weapon.radius or 40
	task.spawn(function()
		for _ = 1, 15 do
			for _, target in Combat.getTargets() do
				local offset = core.Position - target.root.Position
				if
					offset.Magnitude < radius
					and offset.Magnitude > 2
					and Combat.canDamage(shot.player, target.model, target.humanoid)
				then
					Combat.push(target.model, offset.Unit * 45, 0.2)
				end
			end
			task.wait(0.2)
		end
		core:Destroy()
		Combat.explode(
			shot.player,
			core.Position,
			14,
			weapon.damage,
			nil,
			nil,
			WeaponSounds.cue(weapon.id, "finish")
		)
	end)
end

local function bananaTrap(shot: Shot, position: Vector3)
	local peel = Instance.new("Part")
	peel.Name = "BananaPeel"
	peel.Anchored = true
	peel.CanCollide = false
	peel.Size = Vector3.new(2.4, 0.4, 1.6)
	peel.Color = rgb(255, 230, 50)
	peel.Material = M.SmoothPlastic
	peel.CFrame = CFrame.new(position + Vector3.new(0, 0.2, 0))
		* CFrame.Angles(0, random:NextNumber(0, 6), 0)
	peel.Parent = effectsFolder
	Debris:AddItem(peel, 40)
	local connection
	connection = peel.Touched:Connect(function(hit)
		local character, humanoid = Combat.findCharacter(hit)
		if
			character
			and humanoid
			and Combat.damage(shot.player, character, humanoid, shot.weapon.damage)
		then
			connection:Disconnect()
			WeaponSounds.at(shot.weapon.id, "trap", peel.Position)
			humanoid.Sit = true
			Combat.push(
				character,
				Vector3.new(random:NextNumber(-30, 30), 90, random:NextNumber(-30, 30)),
				0.25
			)
			peel:Destroy()
		end
	end)
end

local function impact(projectile: Projectile, position: Vector3, part: BasePart?)
	local shot = projectile.shot
	local weapon = shot.weapon
	if weapon.impact == "blackhole" then
		blackHole(shot, position)
	elseif weapon.impact == "trap" then
		bananaTrap(shot, position)
	elseif weapon.blast and weapon.splash then
		flash(position, weapon.color, weapon.blast * 0.75)
		WeaponSounds.at(weapon.id, "impact", position)
		Combat.blast(
			shot.player,
			position,
			weapon.blast,
			weapon.damage,
			weapon.effect,
			weapon.power
		)
	elseif weapon.blast then
		Combat.explode(
			shot.player,
			position,
			weapon.blast,
			weapon.damage,
			weapon.effect,
			weapon.power,
			WeaponSounds.cue(weapon.id, "impact")
		)
	else
		flash(position, weapon.color, 1.5)
		WeaponSounds.at(weapon.id, "impact", position)
		if part then
			Combat.hitPart(
				shot.player,
				part,
				weapon.damage,
				weapon.effect,
				weapon.power,
				projectile.position
			)
		end
	end
end

local function launch(shot: Shot, direction: Vector3)
	local weapon = shot.weapon
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { shot.character, effectsFolder }
	local part = projectileVisual(weapon)
	part.CFrame = CFrame.lookAt(shot.muzzle, shot.muzzle + direction)
	table.insert(projectiles, {
		shot = shot,
		part = part,
		position = shot.muzzle,
		velocity = direction * (weapon.speed or 100),
		gravity = (weapon.gravity or 0) * workspace.Gravity,
		born = os.clock(),
		params = params,
	})
end

RunService.Heartbeat:Connect(function(dt)
	for index = #projectiles, 1, -1 do
		local projectile = projectiles[index]
		local nextVelocity = projectile.velocity - Vector3.new(0, projectile.gravity * dt, 0)
		local step = (projectile.velocity + nextVelocity) / 2 * dt
		local result = workspace:Raycast(projectile.position, step, projectile.params)
		local expired = os.clock() - projectile.born > 6
		if result or expired then
			table.remove(projectiles, index)
			projectile.part:Destroy()
			if result then
				impact(projectile, result.Position, result.Instance :: BasePart)
			end
		else
			projectile.position += step
			projectile.velocity = nextVelocity
			if step.Magnitude > 0.001 then
				projectile.part.CFrame =
					CFrame.lookAt(projectile.position, projectile.position + step)
			end
		end
	end
end)

local function fireProjectile(shot: Shot)
	local weapon = shot.weapon
	local direction = (shot.aim - shot.muzzle).Unit
	for _ = 1, weapon.count or 1 do
		launch(shot, spreadDirection(direction, if weapon.count then weapon.spread or 0 else 0))
	end
end

local function fireStrike(shot: Shot)
	local weapon = shot.weapon
	local target = MathUtil.clampToRange(shot.root.Position, shot.aim, weapon.range)
	local radius = weapon.radius or 10
	if weapon.style == "meteor" then
		local rock = Instance.new("Part")
		rock.Shape = Enum.PartType.Ball
		rock.Anchored = true
		rock.CanCollide = false
		rock.CanQuery = false
		rock.Size = Vector3.one * 8
		rock.Material = M.Basalt
		rock.Color = rgb(70, 40, 30)
		rock.CFrame = CFrame.new(target + Vector3.new(40, 160, 0))
		Instance.new("Fire", rock).Size = 12
		rock.Parent = effectsFolder
		WeaponSounds.on(weapon.id, "fall", rock)
		TweenService:Create(
			rock,
			TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ CFrame = CFrame.new(target) }
		):Play()
		task.delay(0.7, function()
			rock:Destroy()
			Combat.explode(
				shot.player,
				target,
				radius,
				weapon.damage,
				weapon.effect,
				weapon.power,
				WeaponSounds.cue(weapon.id, "strike")
			)
		end)
	else
		lightning(
			target + Vector3.new(random:NextNumber(-10, 10), 140, random:NextNumber(-10, 10)),
			target,
			weapon.color
		)
		flash(target, weapon.color, radius)
		WeaponSounds.at(weapon.id, "strike", target)
		for _, victim in Combat.getTargets() do
			if (victim.root.Position - target).Magnitude <= radius + 2 then
				Combat.damage(shot.player, victim.model, victim.humanoid, weapon.damage)
			end
		end
	end
end

local function fireHeal(shot: Shot)
	local weapon = shot.weapon
	for _, other in Players:GetPlayers() do
		local _, humanoid, root = Characters.living(other)
		if humanoid and root and Combat.areAllies(shot.player, other) then
			if (root.Position - shot.root.Position).Magnitude <= weapon.range then
				humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + weapon.damage)
				local sparkle = Instance.new("Sparkles")
				sparkle.SparkleColor = weapon.color
				sparkle.Parent = root
				Debris:AddItem(sparkle, 1.5)
			end
		end
	end
	flash(shot.root.Position, weapon.color, weapon.range)
end

local function fireBlink(shot: Shot)
	local weapon = shot.weapon
	local target = MathUtil.clampToRange(shot.root.Position, shot.aim, weapon.range)
	if Config.isInLobby(target) then
		return
	end
	flash(shot.root.Position, weapon.color, 6)
	WeaponSounds.at(weapon.id, "blinkFrom", shot.root.Position)
	local _, yaw = shot.root.CFrame:ToOrientation()
	shot.character:PivotTo(CFrame.new(target + Vector3.new(0, 4, 0)) * CFrame.Angles(0, yaw, 0))
	flash(target + Vector3.new(0, 3, 0), weapon.color, 6)
	WeaponSounds.at(weapon.id, "blinkTo", target)
end

local function firePush(shot: Shot)
	local weapon = shot.weapon
	local look = (shot.aim - shot.origin).Unit
	for _, target in Combat.getTargets() do
		if target.model ~= shot.character then
			local offset = target.root.Position - shot.origin
			if offset.Magnitude <= weapon.range and look:Dot(offset.Unit) > 0.4 then
				if Combat.damage(shot.player, target.model, target.humanoid, weapon.damage) then
					Combat.push(
						target.model,
						look * (weapon.power or 120) + Vector3.new(0, 50, 0),
						0.25
					)
				end
			end
		end
	end
	for distance = 4, weapon.range, 6 do
		flash(shot.muzzle + look * distance, weapon.color, distance / 3)
	end
end

local FIRE: { [string]: (Shot) -> () } = {
	melee = fireMelee,
	hitscan = fireHitscan,
	projectile = fireProjectile,
	strike = fireStrike,
	heal = fireHeal,
	blink = fireBlink,
	push = firePush,
}

-- Remote handling ------------------------------------------------------------------------------

local lastFired: { [Player]: { [string]: number } } = {}

Players.PlayerRemoving:Connect(function(player)
	lastFired[player] = nil
end)

Remotes.FireWeapon.OnServerEvent:Connect(function(player, weaponId, aim)
	if typeof(weaponId) ~= "string" or typeof(aim) ~= "Vector3" then
		return
	end
	local weapon = WeaponCatalog.get(weaponId)
	local character = player.Character
	if not weapon or not character then
		return
	end
	local tool = character:FindFirstChildOfClass("Tool")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local head = character:FindFirstChild("Head") :: BasePart?
	if
		not tool
		or tool:GetAttribute(Names.Attributes.WeaponId) ~= weaponId
		or not humanoid
		or humanoid.Health <= 0
		or not root
		or not head
	then
		return
	end
	if root.Anchored or Config.isInLobby(root.Position) then
		return -- frozen, or in the safe zone
	end

	local times = lastFired[player] or {}
	lastFired[player] = times
	local now = os.clock()
	if times[weaponId] and now - times[weaponId] < weapon.cooldown * 0.85 then
		return
	end
	times[weaponId] = now

	local handle = tool:FindFirstChild("Handle") :: BasePart?
	local origin = head.Position
	local aimPoint = if (aim - origin).Magnitude < 0.5
		then origin + root.CFrame.LookVector * 10
		else aim
	WeaponSounds.fire(handle, weaponId)
	FIRE[weapon.kind]({
		player = player,
		weapon = weapon,
		character = character,
		root = root,
		origin = origin,
		muzzle = if handle
			then (handle.CFrame * (modelFor(weapon).muzzle or CFrame.new(
				0,
				0.5,
				-(weapon.length or 2)
			))).Position
			else origin,
		aim = aimPoint,
	})
end)

return Weapons
