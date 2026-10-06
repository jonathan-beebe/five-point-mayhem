-- Weapon visuals: the workspace folder every weapon effect and projectile lives in (created when
-- this module is first required; shots' raycasts skip it), the Random every weapon module draws
-- from, and the beam, flash and lightning effects.

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Names = require(ReplicatedStorage.Shared.Names)

local Effects = {}

local M = Enum.Material

local random = Random.new()

local effectsFolder = Instance.new("Folder")
effectsFolder.Name = Names.Instances.WeaponEffects
effectsFolder.Parent = workspace

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

Effects.folder = effectsFolder
Effects.random = random
Effects.beam = beam
Effects.flash = flash
Effects.lightning = lightning

return Effects
