-- Manifest Excess's gate: a roadside welcome arch. Two steel pylons with hazard bands, a cream
-- Googie sign board ringed in pink neon reading the world's name under a yellow WELCOME TO, a
-- neon starburst on top, and corrugated wing fences plastered with billboards. The door is a
-- roll-up corrugated shutter with a hazard-striped bottom rail.

local Build = require(script.Parent.Parent.Build)
local Gate = require(script.Parent.Gate)

local ManifestExcess = {}

local rgb = Color3.fromRGB
local M = Enum.Material
local STEEL = rgb(70, 80, 92)
local YELLOW = rgb(255, 200, 20)
local PINK = rgb(255, 79, 160)
local CREAM = rgb(240, 228, 200)
local RUST = rgb(138, 74, 42)
local BLACK = rgb(28, 28, 30)
local RED = rgb(200, 40, 40)

local W, H = Gate.WIDTH, Gate.HEIGHT
local PYLON, PYLON_HEIGHT = 12, 112

local function neon(parent: Instance, size: Vector3, cframe: CFrame, color: Color3): Part
	local part = Build.part(parent, size, cframe, color, M.Neon, { canCollide = false })
	Build.nightLight(part)
	return part
end

-- A starburst: a ball with spikes in the sign's plane.
local function starburst(parent: Instance, center: CFrame)
	Build.ball(parent, center.Position, 4, YELLOW, M.Neon)
	for spike = 0, 5 do
		neon(
			parent,
			Vector3.new(0.8, 14, 0.8),
			center * CFrame.Angles(0, 0, spike * math.pi / 6),
			YELLOW
		)
	end
end

function ManifestExcess.build(parent: Instance, base: CFrame): Model
	local model = Gate.model("Manifest Excess Gate", parent)
	local pylonX = W / 2 + PYLON / 2

	for index, side in { -1, 1 } do
		local foot = base * CFrame.new(side * pylonX, 0, 0)
		Build.part(
			model,
			Vector3.new(PYLON, PYLON_HEIGHT, PYLON),
			foot * CFrame.new(0, PYLON_HEIGHT / 2, 0),
			STEEL,
			M.DiamondPlate
		)
		-- Hazard bands up the bottom, the paint flaking.
		for band = 0, 3 do
			Build.part(
				model,
				Vector3.new(PYLON + 0.4, 3, PYLON + 0.4),
				foot * CFrame.new(0, 3 + band * 6, 0),
				if band % 2 == 0 then YELLOW else BLACK,
				M.Metal
			)
		end
		-- Rust running down from the bolts.
		Build.part(
			model,
			Vector3.new(3, 30, 0.3),
			foot * CFrame.new(side * -2, 80, -PYLON / 2 - 0.2),
			RUST,
			M.CorrodedMetal
		)
		-- Corrugated wing fence and its billboard.
		local wing = base * CFrame.new(side * (pylonX + PYLON / 2 + 17), 0, 2)
		Build.part(
			model,
			Vector3.new(34, 34, 2),
			wing * CFrame.new(0, 17, 0),
			RUST,
			M.CorrodedMetal
		)
		for x = -15, 15, 6 do
			Build.part(
				model,
				Vector3.new(1.4, 34, 2.6),
				wing * CFrame.new(x, 17, 0),
				STEEL,
				M.Metal
			)
		end
		Build.part(model, Vector3.new(1.4, 26, 1.4), wing * CFrame.new(0, 47, 0), STEEL, M.Metal)
		local adColor = if index == 1 then YELLOW else PINK
		Build.part(model, Vector3.new(32, 16, 1.4), wing * CFrame.new(0, 60, 0), adColor)
		Gate.plaque(
			model,
			Vector3.new(30, 14, 0.4),
			wing * CFrame.new(0, 60, -0.9),
			adColor,
			M.SmoothPlastic,
			if index == 1 then "BUY MORE!" else "50% OFF EVERYTHING",
			BLACK,
			Enum.Font.Bangers
		)
	end

	-- The sign board between the pylons, ringed in neon.
	local signY, signHeight, signWidth = H + 15, 26, 2 * pylonX + PYLON + 16
	Build.part(
		model,
		Vector3.new(2 * pylonX, 4, 8),
		base * CFrame.new(0, H + 2, 0),
		STEEL,
		M.DiamondPlate
	)
	Build.part(model, Vector3.new(signWidth, signHeight, 2), base * CFrame.new(0, signY, -2), CREAM)
	for _, y in { -1, 1 } do
		neon(
			model,
			Vector3.new(signWidth, 1, 1),
			base * CFrame.new(0, signY + y * (signHeight / 2 - 0.5), -3.2),
			PINK
		)
	end
	for _, x in { -1, 1 } do
		neon(
			model,
			Vector3.new(1, signHeight, 1),
			base * CFrame.new(x * (signWidth / 2 - 0.5), signY, -3.2),
			PINK
		)
	end
	Gate.plaque(
		model,
		Vector3.new(signWidth - 6, signHeight - 6, 0.4),
		base * CFrame.new(0, signY, -3.2),
		CREAM,
		M.SmoothPlastic,
		"MANIFEST EXCESS",
		RED,
		Enum.Font.Bangers
	)
	local welcomeY = signY + signHeight / 2 + 5
	Build.part(model, Vector3.new(44, 9, 2), base * CFrame.new(-10, welcomeY, -2), YELLOW)
	Gate.plaque(
		model,
		Vector3.new(42, 8, 0.4),
		base * CFrame.new(-10, welcomeY, -3.2),
		YELLOW,
		M.SmoothPlastic,
		"WELCOME TO",
		BLACK,
		Enum.Font.Bangers
	)
	starburst(model, base * CFrame.new(pylonX, PYLON_HEIGHT + 6, -1))

	-- Roll-up shutter: corrugated slats and a hazard-striped bottom rail, rolled up into the sign.
	local slats: { BasePart } = {}
	local closed = base * CFrame.new(0, 0, 3)
	for y = 2, H - 2, 4 do
		table.insert(
			slats,
			Build.part(
				model,
				Vector3.new(W, 4, 1.4),
				closed * CFrame.new(0, y, (y % 8 == 2) and 0.3 or 0),
				STEEL,
				M.CorrodedMetal
			)
		)
	end
	for stripe = 0, 6 do
		table.insert(
			slats,
			Build.part(
				model,
				Vector3.new(W / 7, 3, 1.8),
				closed * CFrame.new(-W / 2 + W / 14 + stripe * W / 7, 1.5, 0),
				if stripe % 2 == 0 then YELLOW else BLACK,
				M.Metal
			)
		)
	end
	Gate.door(
		model,
		{ { parts = slats, closed = closed, open = closed * CFrame.new(0, H - 2, 0) } }
	)
	return model
end

return ManifestExcess
