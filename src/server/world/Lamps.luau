-- Night lighting the world builds after the landscape: street lamps along the roads, lamps outside
-- each lobby gate, and firefly swarms under a few trees. Placement comes from Shared.NightLights;
-- every glowing part is tagged by Build.nightLight, so systems/NightLights switches it with the
-- clock (Neon by night, plain by day).
--
-- Lamp posts pass through everything (CanCollide, CanQuery and CanTouch off): vehicles, walkers,
-- shots and climb rays ignore them, so they need no collision group. The plans keep lamps off
-- the asphalt (tools/tests/night_lights). Dynamic lights: one SpotLight on every lit lamp, at
-- most NightLights.MAX_LIGHTS; firefly hosts are invisible parts with one ParticleEmitter each.
-- Fireflies pick their trees from their own Random (FIREFLY_SEED), never the world's seeded ones.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Names = require(ReplicatedStorage.Shared.Names)
local NightLights = require(ReplicatedStorage.Shared.NightLights)
local Build = require(script.Parent.Build)
local Guard = require(script.Parent.Parent.systems.util.Guard)

local Lamps = {}

local rgb = Color3.fromRGB
local M = Enum.Material

local POLE = rgb(45, 48, 55)
local BULB = rgb(255, 196, 128)
local LIGHT = rgb(255, 176, 104)
local FIREFLY = rgb(215, 255, 120)

local POLE_HEIGHT = 12
local ARM = 3.2 -- studs the lamp head reaches out toward the road

local FIREFLY_SEED = 2024
local FIREFLY_GROVES = 24
local FIREFLY_AREA = Vector3.new(28, 6, 28)

local GHOST = { canCollide = false, canQuery = false }

local function ghost(part: BasePart): BasePart
	part.CanTouch = false
	return part
end

-- One lamp post, its head reaching toward the road; `withLight` adds its SpotLight.
local function lamp(parent: Instance, spec: NightLights.Lamp, withLight: boolean)
	local foot = spec.position
	local frame = CFrame.lookAt(foot, foot + spec.toward)
	local model = Build.model("Lamp", parent)
	ghost(
		Build.column(
			model,
			frame * CFrame.new(0, POLE_HEIGHT / 2, 0),
			POLE_HEIGHT,
			0.5,
			POLE,
			M.Metal,
			GHOST
		)
	)
	ghost(
		Build.part(
			model,
			Vector3.new(0.3, 0.3, ARM),
			frame * CFrame.new(0, POLE_HEIGHT - 0.2, -ARM / 2),
			POLE,
			M.Metal,
			GHOST
		)
	)
	ghost(
		Build.part(
			model,
			Vector3.new(1.8, 0.5, 1.4),
			frame * CFrame.new(0, POLE_HEIGHT - 0.2, -ARM),
			POLE,
			M.Metal,
			GHOST
		)
	)
	local bulb = ghost(
		Build.part(
			model,
			Vector3.new(1.4, 0.2, 1),
			frame * CFrame.new(0, POLE_HEIGHT - 0.55, -ARM),
			BULB,
			M.Neon,
			{ canCollide = false, canQuery = false, castShadow = false }
		)
	)
	if withLight then
		local light = Instance.new("SpotLight")
		light.Face = Enum.NormalId.Bottom
		light.Angle = 110
		light.Range = 20
		light.Brightness = 1.4
		light.Color = LIGHT
		light.Shadows = false
		light.Parent = bulb
	end
	Build.nightLight(bulb)
end

local function fireflies(parent: Instance, base: Vector3)
	local host = ghost(
		Build.part(
			parent,
			FIREFLY_AREA,
			CFrame.new(base + Vector3.new(0, FIREFLY_AREA.Y / 2 + 1, 0)),
			FIREFLY,
			M.SmoothPlastic,
			{ transparency = 1, canCollide = false, canQuery = false, castShadow = false }
		)
	)
	host.Name = "Fireflies"
	local emitter = Instance.new("ParticleEmitter")
	emitter.Shape = Enum.ParticleEmitterShape.Box
	emitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	emitter.Color = ColorSequence.new(FIREFLY)
	emitter.LightEmission = 1
	emitter.LightInfluence = 0
	emitter.Brightness = 2
	emitter.Size = NumberSequence.new(0.3)
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.2, 0.1),
		NumberSequenceKeypoint.new(0.45, 0.8),
		NumberSequenceKeypoint.new(0.7, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Lifetime = NumberRange.new(4, 8)
	emitter.Rate = 1.5
	emitter.Speed = NumberRange.new(0.3, 1.2)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Drag = 0.4
	emitter.Acceleration = Vector3.new(0, 0.15, 0)
	emitter.Enabled = false
	emitter.Parent = host
	Build.nightLight(host)
end

-- Trees under `world`, in a fixed order (by position) so the same trees get fireflies each boot.
local function treeBases(world: Instance): { Vector3 }
	local bases = {}
	for _, tree in CollectionService:GetTagged(Names.Tags.Tree) do
		if tree:IsA("Model") and tree.PrimaryPart and tree:IsDescendantOf(world) then
			local position = tree.PrimaryPart.Position
			table.insert(bases, Vector3.new(position.X, 0, position.Z))
		end
	end
	table.sort(bases, function(a, b)
		return if a.X ~= b.X then a.X < b.X else a.Z < b.Z
	end)
	return bases
end

-- Builds after Landscape: fireflies gather under its trees.
function Lamps.build(world: Instance): Model
	local model = Build.model("NightLights", world)
	local lights = 0
	local function place(spec: NightLights.Lamp)
		local withLight = spec.lit and lights < NightLights.MAX_LIGHTS
		local ok = Guard.run("lamp", lamp, model, spec, withLight)
		if ok and withLight then
			lights += 1
		end
	end
	for _, spec in NightLights.lobbyLamps() do
		place(spec)
	end
	for _, spec in NightLights.roadLamps() do
		place(spec)
	end
	local bases = treeBases(world)
	for _, index in NightLights.pick(Random.new(FIREFLY_SEED), #bases, FIREFLY_GROVES) do
		Guard.run("fireflies", fireflies, model, bases[index])
	end
	return model
end

return Lamps
