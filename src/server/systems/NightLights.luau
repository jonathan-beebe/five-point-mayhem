-- Switches the night lights with the clock. Every part tagged Names.Tags.NightLight (world/Lamps,
-- landmark lanterns and torches via Build.nightLight) is read once at start: its built colour,
-- and the built brightness of each light under it. Each Heartbeat turns Lighting.ClockTime (the
-- server's DayNight writes it) into a step of Shared.NightLights.level; on a new step:
--   - a Neon part glows its built colour scaled by the level, and is plain SmoothPlastic in its
--     built colour at level 0 (day)
--   - each Light is on at its built brightness scaled by the level, off at level 0
--   - each Fire burns above level 0
--   - each ParticleEmitter (fireflies) emits from NightLights.FIREFLY_LEVEL up
-- Writes happen only on a step change (at most NightLights.STEPS per dusk or dawn), so the
-- replicated property changes stay few.

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Names = require(ReplicatedStorage.Shared.Names)
local Rules = require(ReplicatedStorage.Shared.NightLights)
local Guard = require(script.Parent.util.Guard)

local NightLights = {}

type Glow = {
	part: BasePart,
	color: Color3,
	neon: boolean,
	lights: { { light: Light, brightness: number } },
	fires: { Fire },
	emitters: { ParticleEmitter },
}

local glows: { Glow } = {}
local current = -1

local function capture(part: Instance)
	if not part:IsA("BasePart") then
		return
	end
	local glow: Glow = {
		part = part,
		color = part.Color,
		neon = part.Material == Enum.Material.Neon,
		lights = {},
		fires = {},
		emitters = {},
	}
	for _, child in part:GetChildren() do
		if child:IsA("Light") then
			table.insert(glow.lights, { light = child, brightness = child.Brightness })
		elseif child:IsA("Fire") then
			table.insert(glow.fires, child)
		elseif child:IsA("ParticleEmitter") then
			table.insert(glow.emitters, child)
		end
	end
	table.insert(glows, glow)
end

local function apply(glow: Glow, level: number)
	local on = level > 0
	if glow.neon then
		glow.part.Material = if on then Enum.Material.Neon else Enum.Material.SmoothPlastic
		glow.part.Color = if on then Rules.glowColor(glow.color, level) else glow.color
	end
	for _, entry in glow.lights do
		entry.light.Enabled = on
		entry.light.Brightness = entry.brightness * level
	end
	for _, fire in glow.fires do
		fire.Enabled = on
	end
	for _, emitter in glow.emitters do
		emitter.Enabled = level >= Rules.FIREFLY_LEVEL
	end
end

local function update()
	local step = Rules.step(Lighting.ClockTime)
	if step == current then
		return
	end
	current = step
	local level = Rules.levelAt(step)
	for _, glow in glows do
		apply(glow, level)
	end
end

-- After the world is built: reads every tagged part, sets them for the clock now, then follows it.
function NightLights.start()
	for _, part in CollectionService:GetTagged(Names.Tags.NightLight) do
		Guard.run("night light", capture, part)
	end
	update()
	RunService.Heartbeat:Connect(update)
end

return NightLights
