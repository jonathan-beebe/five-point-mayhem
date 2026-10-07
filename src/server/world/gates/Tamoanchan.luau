-- Tamoanchan's gate: a Maya corbel arch of limestone, its stepped vault closing to a capstone,
-- under a roof comb with a gold glyph band and the world's name. Moss on every ledge, vines down
-- the piers, feathered serpent heads at their feet, low stone wing walls, and the Sleeping Head:
-- a colossal Olmec-style head, eyes closed, with a sapling growing from its crown. The door is a
-- stone slab with a jade seal that rises from the ground.

local Build = require(script.Parent.Parent.Build)
local Gate = require(script.Parent.Gate)

local Tamoanchan = {}

local rgb = Color3.fromRGB
local M = Enum.Material
local LIMESTONE = rgb(214, 200, 160)
local SHADE = rgb(176, 162, 124)
local MOSS = rgb(92, 140, 74)
local JADE = rgb(50, 160, 110)
local GOLD = rgb(240, 195, 60)
local FEATHER = rgb(40, 130, 90)
local RED = rgb(175, 55, 40)
local BARK = rgb(96, 72, 50)

local W, H = Gate.WIDTH, Gate.HEIGHT
local PIER, DEPTH = 20, 20
local COURSES, COURSE = 5, 6

local function moss(parent: Instance, size: Vector3, cframe: CFrame)
	Build.part(parent, size, cframe, MOSS, M.Grass, { canCollide = false })
end

local function serpent(parent: Instance, base: CFrame)
	Build.part(
		parent,
		Vector3.new(10, 9, 14),
		base * CFrame.new(0, 4.5, -7),
		LIMESTONE,
		M.Limestone
	)
	Build.wedge(
		parent,
		Vector3.new(10, 4, 8),
		base * CFrame.new(0, 11, -10) * CFrame.Angles(0, math.pi, 0),
		SHADE,
		M.Limestone
	)
	Build.part(parent, Vector3.new(8, 1, 6), base * CFrame.new(0, 3, -15), RED, M.Slate)
	for _, x in { -3, 3 } do
		Build.part(
			parent,
			Vector3.new(1.6, 1.6, 0.6),
			base * CFrame.new(x, 7, -14.2),
			JADE,
			M.Glass
		)
	end
	for index, angle in { -0.6, -0.2, 0.2, 0.6 } do
		Build.part(
			parent,
			Vector3.new(2, 9, 1),
			base * CFrame.new(math.sin(angle) * 6, 9, 0.4) * CFrame.Angles(0, 0, -angle),
			if index % 2 == 0 then FEATHER else GOLD,
			M.SmoothPlastic
		)
	end
end

-- The Sleeping Head: about 22 studs tall, helmeted, eyes closed, on the ground facing the lobby.
local function sleepingHead(parent: Instance, base: CFrame)
	local stone = rgb(150, 140, 118)
	Build.part(parent, Vector3.new(18, 20, 16), base * CFrame.new(0, 10, 0), stone, M.Basalt)
	Build.part(parent, Vector3.new(20, 6, 18), base * CFrame.new(0, 21, 0.5), stone, M.Basalt)
	for _, x in { -1, 1 } do
		Build.part(parent, Vector3.new(2, 6, 5), base * CFrame.new(x * 10, 11, 1), stone, M.Basalt)
		Build.part(parent, Vector3.new(5, 0.8, 0.5), base * CFrame.new(x * 4, 14, -8.2), SHADE)
	end
	Build.part(parent, Vector3.new(5, 5, 3), base * CFrame.new(0, 10, -9), stone, M.Basalt)
	Build.part(parent, Vector3.new(9, 2.4, 2), base * CFrame.new(0, 5, -8.6), stone, M.Basalt)
	moss(parent, Vector3.new(21, 1, 19), base * CFrame.new(0, 24.4, 0.5))
	moss(parent, Vector3.new(6, 8, 0.4), base * CFrame.new(-6, 6, -8.2))
	Build.column(parent, base * CFrame.new(2, 29, 2), 8, 1.4, BARK, M.Wood)
	Build.ball(parent, (base * CFrame.new(2, 34, 2)).Position, 9, MOSS, M.LeafyGrass)
end

function Tamoanchan.build(parent: Instance, base: CFrame): Model
	local model = Gate.model("Tamoanchan Gate", parent)
	local inner = W / 2

	-- Piers, then courses stepping in over the opening until a capstone closes the vault.
	for _, side in { -1, 1 } do
		Build.part(
			model,
			Vector3.new(PIER, H, DEPTH),
			base * CFrame.new(side * (inner + PIER / 2), H / 2, 0),
			LIMESTONE,
			M.Limestone
		)
		for course = 1, COURSES do
			local innerEdge = inner - course * (inner / (COURSES + 1))
			local outerEdge = inner + PIER - course * 2
			local y = H + (course - 0.5) * COURSE
			Build.part(
				model,
				Vector3.new(outerEdge - innerEdge, COURSE, DEPTH),
				base * CFrame.new(side * (innerEdge + outerEdge) / 2, y, 0),
				if course % 2 == 0 then SHADE else LIMESTONE,
				M.Limestone
			)
			moss(
				model,
				Vector3.new(3, 0.6, DEPTH),
				base * CFrame.new(side * (outerEdge - 1.5), H + course * COURSE + 0.3, 0)
			)
		end
		-- Vines down the pier's face.
		for _, x in { 4, 11, 16 } do
			moss(
				model,
				Vector3.new(1, 18 + x, 0.4),
				base * CFrame.new(side * (inner + x), H - (18 + x) / 2, -DEPTH / 2 - 0.2)
			)
		end
		serpent(model, base * CFrame.new(side * (inner + PIER / 2), 0, -DEPTH / 2))
		-- Low wing wall to the rock.
		local wing = base * CFrame.new(side * (inner + PIER + 18), 0, 2)
		Build.part(
			model,
			Vector3.new(36, 26, 10),
			wing * CFrame.new(0, 13, 0),
			LIMESTONE,
			M.Limestone
		)
		moss(model, Vector3.new(36, 1, 11), wing * CFrame.new(0, 26.4, 0))
	end
	local vaultTop = H + COURSES * COURSE
	Build.part(
		model,
		Vector3.new(2 * (inner + PIER - COURSES * 2), 4, DEPTH),
		base * CFrame.new(0, vaultTop + 2, 0),
		LIMESTONE,
		M.Limestone
	)

	-- Roof comb: frieze with the name, a gold glyph band, and a stepped crest.
	local frieze = vaultTop + 4
	Build.part(
		model,
		Vector3.new(64, 16, 8),
		base * CFrame.new(0, frieze + 8, 0),
		LIMESTONE,
		M.Limestone
	)
	Gate.plaque(
		model,
		Vector3.new(56, 10, 0.6),
		base * CFrame.new(0, frieze + 9, -4.2),
		SHADE,
		M.Limestone,
		"TAMOANCHAN",
		JADE,
		Enum.Font.Fondamento
	)
	local band = Build.part(
		model,
		Vector3.new(64, 1.6, 8.4),
		base * CFrame.new(0, frieze + 2, 0),
		GOLD,
		M.Foil
	)
	Build.nightLight(band)
	for step = 1, 3 do
		Build.part(
			model,
			Vector3.new(48 - step * 12, 5, 6),
			base * CFrame.new(0, frieze + 16 + (step - 0.5) * 5, 0),
			if step % 2 == 0 then SHADE else LIMESTONE,
			M.Limestone
		)
	end
	moss(model, Vector3.new(12, 0.8, 6.4), base * CFrame.new(0, frieze + 31.4, 0))

	sleepingHead(model, base * CFrame.new(inner + PIER + 18, 0, -20))

	-- The slab: closed it fills the opening, open it lies sunk below the ground.
	local closed = base * CFrame.new(0, 0, 4)
	local parts = {
		Build.part(
			model,
			Vector3.new(W, H, 4),
			closed * CFrame.new(0, H / 2, 0),
			SHADE,
			M.Limestone
		),
		Build.part(
			model,
			Vector3.new(0.6, 18, 18),
			closed * CFrame.new(0, H / 2, -2.2) * CFrame.Angles(0, math.rad(90), 0),
			JADE,
			M.Glass,
			{ shape = Enum.PartType.Cylinder }
		),
		Build.part(
			model,
			Vector3.new(0.8, 12, 12),
			closed * CFrame.new(0, H / 2, -2.4) * CFrame.Angles(0, math.rad(90), 0),
			GOLD,
			M.Foil,
			{ shape = Enum.PartType.Cylinder }
		),
	}
	Gate.door(
		model,
		{ { parts = parts, closed = closed, open = closed * CFrame.new(0, -H - 1, 0) } }
	)
	return model
end

return Tamoanchan
