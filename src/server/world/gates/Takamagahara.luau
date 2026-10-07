-- Takamagahara's gate: a great vermilion torii with black-capped columns, an upswept black
-- kasagi, a lacquered name plaque between the beams, a shimenawa rope with paper shide across the
-- opening, cyan light seams up the columns, low white tamagaki fences for wings, and mist at its
-- feet. The door is two white lacquer screens that slide out from behind the columns.

local Build = require(script.Parent.Parent.Build)
local Gate = require(script.Parent.Gate)

local Takamagahara = {}

local rgb = Color3.fromRGB
local M = Enum.Material
local VERMILION = rgb(201, 74, 58)
local BLACK = rgb(30, 30, 34)
local LACQUER = rgb(244, 242, 238)
local CEDAR = rgb(196, 170, 130)
local CYAN = rgb(143, 234, 255)
local ROPE = rgb(222, 204, 156)
local GOLD = rgb(220, 180, 60)

local W, H = Gate.WIDTH, Gate.HEIGHT
local COLUMN, COLUMN_HEIGHT = 8, 104

local function screen(parent: Instance, center: CFrame, width: number): { BasePart }
	local parts = {}
	local function add(part: BasePart)
		table.insert(parts, part)
	end
	add(Build.part(parent, Vector3.new(width, H, 1.2), center * CFrame.new(0, H / 2, 0), LACQUER))
	for x = -width / 2 + 0.6, width / 2, width / 4 do
		add(
			Build.part(
				parent,
				Vector3.new(0.8, H, 1.8),
				center * CFrame.new(math.min(x, width / 2 - 0.4), H / 2, 0),
				CEDAR,
				M.Wood
			)
		)
	end
	for y = 0.4, H, H / 6 do
		add(
			Build.part(
				parent,
				Vector3.new(width, 0.8, 1.8),
				center * CFrame.new(0, math.min(y, H - 0.4), 0),
				CEDAR,
				M.Wood
			)
		)
	end
	local seam = Build.part(
		parent,
		Vector3.new(0.4, H - 4, 2),
		center * CFrame.new(0, H / 2, 0),
		CYAN,
		M.Neon,
		{ canCollide = false }
	)
	Build.nightLight(seam)
	add(seam)
	return parts
end

function Takamagahara.build(parent: Instance, base: CFrame): Model
	local model = Gate.model("Takamagahara Gate", parent)
	local columnX = W / 2 + COLUMN / 2 + 2

	for _, side in { -1, 1 } do
		local foot = base * CFrame.new(side * columnX, 0, 0)
		Build.column(
			model,
			foot * CFrame.new(0, COLUMN_HEIGHT / 2, 0),
			COLUMN_HEIGHT,
			COLUMN,
			VERMILION,
			M.Wood
		)
		Build.column(model, foot * CFrame.new(0, 3, 0), 6, COLUMN + 2, BLACK, M.Wood)
		local seam = Build.part(
			model,
			Vector3.new(0.5, COLUMN_HEIGHT - 12, 0.5),
			foot * CFrame.new(0, COLUMN_HEIGHT / 2 + 2, -COLUMN / 2),
			CYAN,
			M.Neon,
			{ canCollide = false }
		)
		Build.nightLight(seam)
		-- Tamagaki fence wing: white posts and rails with vermilion caps.
		local wing = base * CFrame.new(side * (columnX + 22), 0, 4)
		Build.part(model, Vector3.new(36, 16, 2), wing * CFrame.new(0, 8, 0), LACQUER)
		Build.part(model, Vector3.new(37, 1.4, 3), wing * CFrame.new(0, 16.7, 0), VERMILION, M.Wood)
		for x = -16, 16, 8 do
			Build.part(
				model,
				Vector3.new(2, 18, 2.6),
				wing * CFrame.new(x, 9, 0),
				VERMILION,
				M.Wood
			)
		end
		-- Mist pooled at the columns' feet.
		local mist = Instance.new("ParticleEmitter")
		mist.Color = ColorSequence.new(rgb(240, 245, 250))
		mist.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.3, 0.75),
			NumberSequenceKeypoint.new(1, 1),
		})
		mist.Size = NumberSequence.new(14, 24)
		mist.Lifetime = NumberRange.new(6, 9)
		mist.Rate = 3
		mist.Speed = NumberRange.new(1, 3)
		mist.SpreadAngle = Vector2.new(180, 10)
		mist.LightInfluence = 1
		mist.Parent =
			Build.part(model, Vector3.new(30, 1, 10), wing * CFrame.new(0, 1, -10), LACQUER, nil, {
				transparency = 1,
				canCollide = false,
				canQuery = false,
				name = "Mist",
			})
	end

	-- Nuki (lower beam) through the columns, kasagi and shimaki on top, upswept ends.
	local nukiY = H + 8
	Build.part(
		model,
		Vector3.new(2 * columnX + 22, 4.5, 3.6),
		base * CFrame.new(0, nukiY, 0),
		VERMILION,
		M.Wood
	)
	Build.part(
		model,
		Vector3.new(2 * columnX + 30, 4, 5),
		base * CFrame.new(0, COLUMN_HEIGHT - 2, 0),
		VERMILION,
		M.Wood
	)
	Build.part(
		model,
		Vector3.new(2 * columnX + 34, 4.5, 6.4),
		base * CFrame.new(0, COLUMN_HEIGHT + 2.2, 0),
		BLACK,
		M.Wood
	)
	for _, side in { -1, 1 } do
		Build.part(
			model,
			Vector3.new(16, 4.5, 6.4),
			base
				* CFrame.new(side * (columnX + 22), COLUMN_HEIGHT + 3.6, 0)
				* CFrame.Angles(0, 0, side * 0.22),
			BLACK,
			M.Wood
		)
	end

	-- Gakuzuka strut and the name plaque.
	Build.part(
		model,
		Vector3.new(4, COLUMN_HEIGHT - nukiY - 4, 3),
		base * CFrame.new(0, (nukiY + COLUMN_HEIGHT - 4) / 2, 0),
		VERMILION,
		M.Wood
	)
	Build.part(model, Vector3.new(50, 16, 1.4), base * CFrame.new(0, nukiY + 14, -2), GOLD, M.Foil)
	Gate.plaque(
		model,
		Vector3.new(47, 13, 0.6),
		base * CFrame.new(0, nukiY + 14, -2.9),
		BLACK,
		M.SmoothPlastic,
		"TAKAMAGAHARA",
		GOLD,
		Enum.Font.Michroma
	)

	-- Shimenawa rope with zigzag paper shide, just above the opening.
	local ropeY = H + 2.5
	Build.part(
		model,
		Vector3.new(W + 6, 3.2, 3.2),
		base * CFrame.new(0, ropeY, -1),
		ROPE,
		M.Fabric,
		{ shape = Enum.PartType.Cylinder }
	)
	for x = -W / 2 + 8, W / 2 - 8, (W - 16) / 4 do
		for step = 0, 2 do
			Build.part(
				model,
				Vector3.new(1.6, 1.4, 0.1),
				base * CFrame.new(x + (step % 2) * 0.8, ropeY - 2.2 - step * 1.4, -1.8),
				LACQUER,
				M.SmoothPlastic,
				{ canCollide = false }
			)
		end
	end

	-- Two screens meet in the middle when closed, slide behind the columns when open.
	local leaves = {}
	for _, side in { -1, 1 } do
		local closed = base * CFrame.new(side * W / 4, 0, 7)
		table.insert(leaves, {
			parts = screen(model, closed, W / 2),
			closed = closed,
			open = closed * CFrame.new(side * (W / 2 + 4), 0, 0),
		})
	end
	Gate.door(model, leaves)
	return model
end

return Takamagahara
