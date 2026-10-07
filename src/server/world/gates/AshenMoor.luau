-- The Ashen Moor's gate: a colliery gatehouse. Two soot-blackened brick towers with ember miner's
-- lamps, an iron girder lintel with a brass name plate, a pit-head winding wheel on an iron
-- headframe above, brick wings, and the Last Miner on his plinth holding his lamp toward the moor.
-- The door is an iron portcullis that drops from the headframe.

local Build = require(script.Parent.Parent.Build)
local Gate = require(script.Parent.Gate)

local AshenMoor = {}

local rgb = Color3.fromRGB
local M = Enum.Material
local BRICK = rgb(74, 42, 34)
local SOOT = rgb(22, 22, 26)
local IRON = rgb(44, 40, 38)
local BRASS = rgb(184, 137, 58)
local EMBER = rgb(255, 106, 26)
local STONE = rgb(92, 91, 94)

local W, H = Gate.WIDTH, Gate.HEIGHT
local TOWER, TOWER_HEIGHT, DEPTH = 18, 92, 22

local function lamp(parent: Instance, base: CFrame)
	Build.part(parent, Vector3.new(7, 2, 7), base * CFrame.new(0, 1, 0), IRON, M.CorrodedMetal)
	local glow = Build.ball(parent, (base * CFrame.new(0, 5, 0)).Position, 6, EMBER, M.Neon)
	Build.nightLight(glow)
	local light = Instance.new("PointLight")
	light.Color = EMBER
	light.Range = 40
	light.Brightness = 2
	light.Parent = glow
	for _, x in { -3, 3 } do
		Build.part(parent, Vector3.new(0.6, 8, 0.6), base * CFrame.new(x, 5, 0), IRON, M.Metal)
	end
	Build.part(parent, Vector3.new(8, 1, 8), base * CFrame.new(0, 9.5, 0), IRON, M.CorrodedMetal)
	local smoke = Instance.new("Smoke")
	smoke.Color = SOOT
	smoke.Opacity = 0.35
	smoke.RiseVelocity = 6
	smoke.Size = 6
	smoke.Parent = glow
end

-- The Last Miner: a blocky cast-iron figure, lamp arm raised, on a stone plinth.
local function miner(parent: Instance, base: CFrame)
	Build.part(parent, Vector3.new(14, 8, 14), base * CFrame.new(0, 4, 0), STONE, M.Slate)
	local feet = base * CFrame.new(0, 8, 0)
	for _, x in { -2.2, 2.2 } do
		Build.part(parent, Vector3.new(3.4, 11, 3.6), feet * CFrame.new(x, 5.5, 0), IRON, M.Metal)
	end
	Build.part(parent, Vector3.new(9, 11, 5), feet * CFrame.new(0, 16.5, 0), IRON, M.Metal)
	Build.part(parent, Vector3.new(5, 5, 5), feet * CFrame.new(0, 24.5, 0), IRON, M.Metal)
	Build.part(parent, Vector3.new(6.4, 1.6, 6.4), feet * CFrame.new(0, 27.4, 0), SOOT, M.Metal)
	local headlamp = Build.part(
		parent,
		Vector3.new(1.6, 1.6, 0.6),
		feet * CFrame.new(0, 27.4, -3.3),
		EMBER,
		M.Neon
	)
	Build.nightLight(headlamp)
	-- Left arm down, right arm up holding the lamp.
	Build.part(parent, Vector3.new(2.6, 10, 2.6), feet * CFrame.new(-5.8, 17, 0), IRON, M.Metal)
	Build.part(
		parent,
		Vector3.new(2.6, 11, 2.6),
		feet * CFrame.new(5.6, 25, -1.5) * CFrame.Angles(math.rad(-20), 0, math.rad(-12)),
		IRON,
		M.Metal
	)
	local held = Build.ball(parent, (feet * CFrame.new(6.8, 32, -3.4)).Position, 3, EMBER, M.Neon)
	Build.nightLight(held)
	-- Soot down his front.
	Build.part(parent, Vector3.new(7, 9, 0.3), feet * CFrame.new(0, 15, -2.6), SOOT, M.Slate)
end

function AshenMoor.build(parent: Instance, base: CFrame): Model
	local model = Gate.model("The Ashen Moor Gate", parent)
	local towerX = W / 2 + TOWER / 2

	for _, side in { -1, 1 } do
		local tower = base * CFrame.new(side * towerX, 0, 0)
		Build.part(
			model,
			Vector3.new(TOWER, TOWER_HEIGHT, DEPTH),
			tower * CFrame.new(0, TOWER_HEIGHT / 2, 0),
			BRICK,
			M.Brick
		)
		-- Soot streaks under the tower's windows, front and back.
		for _, z in { -DEPTH / 2 - 0.2, DEPTH / 2 + 0.2 } do
			for _, x in { -4.5, 4.5 } do
				Build.part(
					model,
					Vector3.new(2.4, 4, 0.4),
					tower * CFrame.new(x, 76, z),
					SOOT,
					M.SmoothPlastic
				)
				Build.part(
					model,
					Vector3.new(1.6, 26, 0.3),
					tower * CFrame.new(x, 60, z),
					SOOT,
					M.Slate,
					{ transparency = 0.25 }
				)
			end
		end
		-- Stone courses and a corbelled top.
		for _, y in { 2, 46 } do
			Build.part(
				model,
				Vector3.new(TOWER + 1, 3, DEPTH + 1),
				tower * CFrame.new(0, y, 0),
				STONE,
				M.Slate
			)
		end
		Build.part(
			model,
			Vector3.new(TOWER + 3, 3, DEPTH + 3),
			tower * CFrame.new(0, TOWER_HEIGHT + 1.5, 0),
			STONE,
			M.Slate
		)
		lamp(model, tower * CFrame.new(0, TOWER_HEIGHT + 3, 0))
		-- Wing wall out to the rock.
		Build.part(
			model,
			Vector3.new(32, 40, 8),
			base * CFrame.new(side * (towerX + TOWER / 2 + 16), 20, 2),
			BRICK,
			M.Brick
		)
		Build.part(
			model,
			Vector3.new(33, 2, 9),
			base * CFrame.new(side * (towerX + TOWER / 2 + 16), 41, 2),
			STONE,
			M.Slate
		)
	end

	-- Iron girder lintel and the brass name plate.
	local span = W + 2 * TOWER
	Build.part(model, Vector3.new(span, 10, 12), base * CFrame.new(0, H + 5, 0), IRON, M.Metal)
	for _, y in { H + 0.5, H + 9.5 } do
		Build.part(
			model,
			Vector3.new(span + 2, 1, 14),
			base * CFrame.new(0, y, 0),
			IRON,
			M.CorrodedMetal
		)
	end
	Gate.plaque(
		model,
		Vector3.new(60, 8, 0.6),
		base * CFrame.new(0, H + 5, -6.4),
		BRASS,
		M.Metal,
		"THE ASHEN MOOR",
		SOOT,
		Enum.Font.GrenzeGotisch
	)

	-- Headframe legs and the winding wheel.
	local hub = base * CFrame.new(0, H + 34, 0)
	for _, side in { -1, 1 } do
		local foot = base * CFrame.new(side * 22, H + 10, 0)
		local top = hub.Position
		local mid = (foot.Position + top) / 2
		local length = (top - foot.Position).Magnitude
		Build.part(
			model,
			Vector3.new(2.4, length, 2.4),
			CFrame.lookAt(mid, top) * CFrame.Angles(math.rad(90), 0, 0),
			IRON,
			M.CorrodedMetal
		)
	end
	local facing = CFrame.Angles(0, math.rad(90), 0)
	Build.part(
		model,
		Vector3.new(1.6, 30, 30),
		hub * CFrame.new(0, 0, -2) * facing,
		IRON,
		M.CorrodedMetal,
		{ shape = Enum.PartType.Cylinder }
	)
	Build.part(
		model,
		Vector3.new(1.8, 26, 26),
		hub * CFrame.new(0, 0, -2) * facing,
		SOOT,
		M.Slate,
		{ shape = Enum.PartType.Cylinder }
	)
	for spoke = 0, 3 do
		Build.part(
			model,
			Vector3.new(1.2, 26, 1.2),
			hub * CFrame.new(0, 0, -3) * CFrame.Angles(0, 0, spoke * math.pi / 4),
			IRON,
			M.Metal
		)
	end
	Build.part(
		model,
		Vector3.new(2.4, 5, 5),
		hub * CFrame.new(0, 0, -3.4) * facing,
		BRASS,
		M.Metal,
		{ shape = Enum.PartType.Cylinder }
	)

	miner(model, base * CFrame.new(-(towerX + TOWER / 2 + 16), 0, -16))

	-- Portcullis: iron bars across the opening, raised into the headframe when open.
	local bars: { BasePart } = {}
	local closed = base * CFrame.new(0, 0, 3)
	for x = -W / 2 + 3, W / 2 - 3, 6 do
		table.insert(
			bars,
			Build.part(
				model,
				Vector3.new(1.6, H, 1.6),
				closed * CFrame.new(x, H / 2, 0),
				IRON,
				M.CorrodedMetal
			)
		)
	end
	for y = 6, H - 4, 10 do
		table.insert(
			bars,
			Build.part(model, Vector3.new(W, 1.4, 1.4), closed * CFrame.new(0, y, 0), IRON, M.Metal)
		)
	end
	Gate.door(model, { { parts = bars, closed = closed, open = closed * CFrame.new(0, H - 4, 0) } })
	return model
end

return AshenMoor
