-- The MAC's NUKE, drawn on each client when the server fires Remotes.Nuke: a giant bomb falls on
-- the lobby floor, whistling louder as it drops. On impact a white flash swells, the view shakes, a
-- blast wave rings out across the board, and a mushroom cloud rises over the lobby and fades. The
-- server kills players as the wave reaches them (Admin) on the same timing (Config.NUKE_*).

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local SoundCatalog = require(ReplicatedStorage.Shared.SoundCatalog)
local Sounds = require(ReplicatedStorage.Shared.Sounds)

local NukeStrike = {}

local rgb = Color3.fromRGB
local random = Random.new()

local GROUP = "Weapons"
local UPRIGHT = CFrame.Angles(0, 0, math.pi / 2) -- turns a cylinder's axis from X to Y

-- Bomb ----------------------------------------------------------------------------------------

local BOMB_OLIVE = rgb(85, 95, 60)
local BOMB_DARK = rgb(50, 55, 40)
local BOMB_STRIPE = rgb(255, 205, 0)
local BOMB_RADIUS = 12
local BOMB_BOTTOM = 34 -- studs from the body's center down to the tip of the nose
local DROP_HEIGHT = 1400 -- studs above the ground at release
local DROP_SPIN = math.rad(200) -- turn about its axis over the whole fall

-- Blast ---------------------------------------------------------------------------------------

local FLASH_SIZE = 700
local WAVE_SEGMENTS = 72
local WAVE_HEIGHT = { 45, 10 } -- studs, at impact and at the edge of the board
local WAVE_HOT = rgb(255, 245, 210)
local WAVE_COOL = rgb(255, 120, 40)
local SHAKE_SECONDS = 3.5
local SHAKE_ANGLE = math.rad(1.2) -- at strength 1
local SHAKE_REACH = 1500 -- studs from impact where the shake bottoms out at 0.3
local SHAKE_UNDO_STEP = "NukeShakeUndo"
local SHAKE_STEP = "NukeShake"

-- Mushroom cloud ------------------------------------------------------------------------------

local SMOKE_HOT = rgb(255, 150, 60)
local SMOKE = rgb(120, 110, 104)
local SMOKE_DARK = rgb(78, 70, 66)
local DUST = rgb(150, 130, 105)
local FIRE = rgb(255, 200, 90)
local STEM_PUFFS = 9
local STEM_HEIGHT = 430
local CAP_Y = 480
local RISE_SECONDS = 10
local COOL_SECONDS = 6 -- hot orange to grey
local LINGER_SECONDS = 8 -- after the rise, before it fades
local FADE_SECONDS = 6
-- Each puff is a see-through ball wrapped in billowing smoke particles shed from its surface.
local PUFF_TRANSPARENCY = { 0.2, 0.6 } -- hot, cooled
local SMOKE_TEXTURE = "rbxasset://textures/particles/smoke_main.dds" -- Roblox's Smoke texture
local SMOKE_RATE = 2 -- particles per second per puff

local function part(
	parent: Instance,
	shape: Enum.PartType,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material
): Part
	local piece = Instance.new("Part")
	piece.Shape = shape
	piece.Size = size
	piece.CFrame = cframe
	piece.Color = color
	piece.Material = material
	piece.Anchored = true
	piece.CanCollide = false
	piece.CanQuery = false
	piece.CanTouch = false
	piece.CastShadow = false
	piece.TopSurface = Enum.SurfaceType.Smooth
	piece.BottomSurface = Enum.SurfaceType.Smooth
	piece.Parent = parent
	return piece
end

-- Tail up, nose down, pivoting on the body's center.
local function buildBomb(parent: Instance): Model
	local model = Instance.new("Model")
	model.Name = "Nuke"
	local diameter = BOMB_RADIUS * 2
	local metal = Enum.Material.Metal
	local body = part(
		model,
		Enum.PartType.Cylinder,
		Vector3.new(44, diameter, diameter),
		UPRIGHT,
		BOMB_OLIVE,
		metal
	)
	model.PrimaryPart = body
	part(
		model,
		Enum.PartType.Ball,
		Vector3.one * diameter,
		CFrame.new(0, -22, 0),
		BOMB_OLIVE,
		metal
	)
	for _, y in { -12, 12 } do
		part(
			model,
			Enum.PartType.Cylinder,
			Vector3.new(3, diameter + 0.6, diameter + 0.6),
			CFrame.new(0, y, 0) * UPRIGHT,
			BOMB_STRIPE,
			Enum.Material.SmoothPlastic
		)
	end
	part(
		model,
		Enum.PartType.Cylinder,
		Vector3.new(10, 18, 18),
		CFrame.new(0, 27, 0) * UPRIGHT,
		BOMB_DARK,
		metal
	)
	part(
		model,
		Enum.PartType.Cylinder,
		Vector3.new(8, 12, 12),
		CFrame.new(0, 35, 0) * UPRIGHT,
		BOMB_DARK,
		metal
	)
	for index = 0, 3 do
		part(
			model,
			Enum.PartType.Block,
			Vector3.new(1.5, 20, 14),
			CFrame.Angles(0, index * math.pi / 2, 0) * CFrame.new(0, 32, 13),
			BOMB_DARK,
			metal
		)
	end
	model.Parent = parent
	return model
end

-- The whistle swells over the fall; the rush peaks on impact. Returns the whistle, to stop it.
local function playFallSounds(): Sound
	local spec = SoundCatalog.NUKE
	local whistle = Sounds.make(spec.whistle, GROUP)
	whistle.PlaybackSpeed = SoundCatalog.PALETTE[spec.whistle.key].duration
		/ Config.NUKE_FALL_SECONDS
	whistle.Volume = spec.whistle.volume * spec.swell
	whistle.Parent = SoundService
	whistle:Play()
	TweenService:Create(
		whistle,
		TweenInfo.new(Config.NUKE_FALL_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Volume = spec.whistle.volume }
	):Play()
	task.delay(
		Config.NUKE_FALL_SECONDS - spec.rushLead,
		Sounds.playOn,
		spec.rush,
		SoundService,
		GROUP
	)
	return whistle
end

-- Drops the bomb from DROP_HEIGHT, accelerating like a falling body. Yields until impact.
local function fall(bomb: Model, ground: Vector3)
	local start = os.clock()
	while true do
		local t = (os.clock() - start) / Config.NUKE_FALL_SECONDS
		if t >= 1 then
			return
		end
		local height = BOMB_BOTTOM + DROP_HEIGHT * (1 - t * t)
		bomb:PivotTo(
			CFrame.new(ground + Vector3.new(0, height, 0)) * CFrame.Angles(0, t * DROP_SPIN, 0)
		)
		RunService.RenderStepped:Wait()
	end
end

local function flash(parent: Instance, ground: Vector3)
	local ball = part(
		parent,
		Enum.PartType.Ball,
		Vector3.one * 40,
		CFrame.new(ground),
		rgb(255, 250, 225),
		Enum.Material.Neon
	)
	TweenService:Create(
		ball,
		TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = Vector3.one * FLASH_SIZE }
	):Play()
	TweenService:Create(
		ball,
		TweenInfo.new(1.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Transparency = 1 }
	):Play()
	Debris:AddItem(ball, 1.9)
end

-- A ring of glowing segments that follows Config.nukeWaveRadius, so it reaches each player as the
-- server kills them.
local function wave(parent: Instance, ground: Vector3)
	local segments = {}
	for index = 1, WAVE_SEGMENTS do
		segments[index] = part(
			parent,
			Enum.PartType.Block,
			Vector3.one,
			CFrame.new(ground),
			WAVE_HOT,
			Enum.Material.Neon
		)
	end
	local start = os.clock()
	local connection: RBXScriptConnection
	connection = RunService.RenderStepped:Connect(function()
		local elapsed = os.clock() - start
		if elapsed >= Config.NUKE_WAVE_SECONDS then
			connection:Disconnect()
			for _, segment in segments do
				segment:Destroy()
			end
			return
		end
		local t = elapsed / Config.NUKE_WAVE_SECONDS
		local radius = math.max(Config.nukeWaveRadius(elapsed), 4)
		local height = WAVE_HEIGHT[1] + (WAVE_HEIGHT[2] - WAVE_HEIGHT[1]) * t
		local size = Vector3.new(2 * math.pi * radius / WAVE_SEGMENTS * 1.15, height, 6)
		local color = WAVE_HOT:Lerp(WAVE_COOL, math.min(t * 2, 1))
		local transparency = 0.1 + 0.85 * t
		for index, segment in segments do
			local angle = index / WAVE_SEGMENTS * 2 * math.pi
			segment.Size = size
			segment.CFrame = CFrame.new(ground)
				* CFrame.Angles(0, angle, 0)
				* CFrame.new(0, height / 2, -radius)
			segment.Color = color
			segment.Transparency = transparency
		end
	end)
end

-- Random jolts that die away. The default camera builds each frame from the last, so the jolt is
-- taken back out before it runs (MechCamera does the same, one step inside this).
local function shake(ground: Vector3)
	local camera = Workspace.CurrentCamera
	local distance = (camera.CFrame.Position - ground).Magnitude
	local strength = math.clamp(1 - 0.7 * distance / SHAKE_REACH, 0.3, 1)
	local start = os.clock()
	local applied = CFrame.identity
	RunService:BindToRenderStep(SHAKE_UNDO_STEP, Enum.RenderPriority.Camera.Value - 2, function()
		camera.CFrame *= applied:Inverse()
		applied = CFrame.identity
	end)
	RunService:BindToRenderStep(SHAKE_STEP, Enum.RenderPriority.Camera.Value + 2, function()
		local t = (os.clock() - start) / SHAKE_SECONDS
		if t >= 1 then
			RunService:UnbindFromRenderStep(SHAKE_UNDO_STEP)
			RunService:UnbindFromRenderStep(SHAKE_STEP)
			return
		end
		local angle = SHAKE_ANGLE * strength * (1 - t) ^ 2
		applied =
			CFrame.Angles(random:NextNumber(-angle, angle), random:NextNumber(-angle, angle), 0)
		camera.CFrame *= applied
	end)
end

-- One ball of the cloud: grows from `from` to `to` (offsets from the ground, and diameters) and
-- cools from hot orange to `color`.
local function puff(
	parent: Instance,
	ground: Vector3,
	from: Vector3,
	fromSize: number,
	to: Vector3,
	toSize: number,
	color: Color3,
	rise: number,
	delay: number
): Part
	local ball = part(
		parent,
		Enum.PartType.Ball,
		Vector3.one * fromSize,
		CFrame.new(ground + from),
		SMOKE_HOT,
		Enum.Material.SmoothPlastic
	)
	ball.Transparency = PUFF_TRANSPARENCY[1]
	local smoke = Instance.new("ParticleEmitter")
	smoke.Texture = SMOKE_TEXTURE
	smoke.Shape = Enum.ParticleEmitterShape.Sphere
	smoke.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
	smoke.Color = ColorSequence.new(color)
	smoke.Size = NumberSequence.new(toSize * 0.35, math.min(toSize * 0.7, 100)) -- Roblox caps at 100
	smoke.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.2, 0.55),
		NumberSequenceKeypoint.new(1, 1),
	})
	smoke.Lifetime = NumberRange.new(4, 7)
	smoke.Rate = SMOKE_RATE
	smoke.Speed = NumberRange.new(2, 6)
	smoke.Rotation = NumberRange.new(0, 360)
	smoke.RotSpeed = NumberRange.new(-15, 15)
	smoke.Parent = ball
	TweenService:Create(
		ball,
		TweenInfo.new(rise, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, delay),
		{ CFrame = CFrame.new(ground + to), Size = Vector3.one * toSize }
	):Play()
	TweenService:Create(
		ball,
		TweenInfo.new(
			COOL_SECONDS,
			Enum.EasingStyle.Linear,
			Enum.EasingDirection.In,
			0,
			false,
			delay
		),
		{ Color = color, Transparency = PUFF_TRANSPARENCY[2] }
	):Play()
	return ball
end

local function ring(count: number, radius: number, y: number, index: number): Vector3
	local angle = index / count * 2 * math.pi + random:NextNumber(-0.1, 0.1)
	return Vector3.new(math.cos(angle) * radius, y, math.sin(angle) * radius)
end

local function mushroomCloud(parent: Instance, ground: Vector3)
	local balls = {}
	local function add(ball: Part)
		table.insert(balls, ball)
	end
	-- Dust surging out along the ground.
	for index = 1, 14 do
		add(
			puff(
				parent,
				ground,
				ring(14, 20, 10, index),
				30,
				ring(14, 190, 25, index),
				100,
				DUST,
				3,
				0
			)
		)
	end
	-- The stem, narrowing as it climbs.
	for index = 1, STEM_PUFFS do
		local share = index / STEM_PUFFS
		local wobble = Vector3.new(random:NextNumber(-8, 8), 0, random:NextNumber(-8, 8))
		add(
			puff(
				parent,
				ground,
				Vector3.new(0, 10, 0),
				30,
				Vector3.new(0, STEM_HEIGHT * share, 0) + wobble,
				130 - 60 * share,
				SMOKE,
				RISE_SECONDS,
				0.1 * index
			)
		)
	end
	-- The cap: a dark underside ring, a rounded middle, a crown.
	for index = 1, 12 do
		add(
			puff(
				parent,
				ground,
				ring(12, 20, 20, index),
				50,
				ring(12, 150, CAP_Y, index),
				170,
				SMOKE_DARK,
				RISE_SECONDS,
				0.2
			)
		)
	end
	for index = 1, 8 do
		add(
			puff(
				parent,
				ground,
				ring(8, 15, 20, index),
				50,
				ring(8, 85, CAP_Y + 55, index),
				180,
				SMOKE,
				RISE_SECONDS,
				0.2
			)
		)
	end
	add(
		puff(
			parent,
			ground,
			Vector3.new(0, 20, 0),
			50,
			Vector3.new(0, CAP_Y + 100, 0),
			200,
			SMOKE,
			RISE_SECONDS,
			0.2
		)
	)
	-- The fireball climbs into the cap and burns out.
	for index = 1, 3 do
		local fire = part(
			parent,
			Enum.PartType.Ball,
			Vector3.one * 50,
			CFrame.new(ground),
			FIRE,
			Enum.Material.Neon
		)
		TweenService:Create(
			fire,
			TweenInfo.new(RISE_SECONDS * 0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				CFrame = CFrame.new(ground + ring(3, 40, CAP_Y - 10, index)),
				Size = Vector3.one * 170,
			}
		):Play()
		TweenService:Create(
			fire,
			TweenInfo.new(5, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 2),
			{ Transparency = 1 }
		):Play()
	end
	task.delay(RISE_SECONDS + LINGER_SECONDS, function()
		for _, ball in balls do
			(ball:FindFirstChildOfClass("ParticleEmitter") :: ParticleEmitter).Enabled = false
			TweenService:Create(ball, TweenInfo.new(FADE_SECONDS), { Transparency = 1 }):Play()
		end
	end)
end

local function strike(ground: Vector3)
	local folder = Instance.new("Folder")
	folder.Name = "NukeStrike"
	folder.Parent = Workspace
	local bomb = buildBomb(folder)
	local whistle = playFallSounds()
	fall(bomb, ground)
	bomb:Destroy()
	whistle:Destroy()
	Sounds.playOn(SoundCatalog.NUKE.blast, SoundService, GROUP)
	flash(folder, ground)
	wave(folder, ground)
	mushroomCloud(folder, ground)
	shake(ground)
	Debris:AddItem(folder, RISE_SECONDS + LINGER_SECONDS + FADE_SECONDS + 2)
end

function NukeStrike.start()
	Remotes.Nuke.OnClientEvent:Connect(function(ground)
		if typeof(ground) == "Vector3" then
			task.spawn(strike, ground)
		end
	end)
end

return NukeStrike
