-- Mayhem Tower (USA): a fourteen-story glass-and-steel skyscraper with an art-deco crown,
-- helipad, express elevator pads, and a city plaza with taxis, hydrants, and a green statue.

local Players = game:GetService("Players")

local Build = require(script.Parent.Parent.Build)

local Skyscraper = {}

local rgb = Color3.fromRGB
local M = Enum.Material
local STEEL = rgb(70, 78, 92)
local CONCRETE = rgb(175, 175, 170)
local GLASS = rgb(120, 180, 230)
local GOLD = rgb(230, 190, 80)
local TAXI = rgb(255, 200, 20)

local SIZE = 64
local FLOORS, FLOOR_HEIGHT = 14, 14

-- A glowing pad that teleports whoever steps on it to `destination`.
local function elevatorPad(
	parent: Instance,
	frame: CFrame,
	destination: CFrame,
	label: string,
	color: Color3
)
	local pad = Build.part(
		parent,
		Vector3.new(8, 0.4, 8),
		frame * CFrame.new(0, 0.2, 0),
		color,
		M.Neon,
		{ name = "ElevatorPad" }
	)
	Build.billboard(parent, (frame * CFrame.new(0, 7, 0)).Position, label, color, 14)
	local cooldown: { [Player]: number } = {}
	pad.Touched:Connect(function(hit)
		local character = hit.Parent
		local player = character and Players:GetPlayerFromCharacter(character)
		if not player or (cooldown[player] and os.clock() - cooldown[player] < 3) then
			return
		end
		cooldown[player] = os.clock();
		(character :: Model):PivotTo(destination)
	end)
end

local function taxi(parent: Instance, frame: CFrame)
	Build.part(
		parent,
		Vector3.new(7, 2.5, 14),
		frame * CFrame.new(0, 2.2, 0),
		TAXI,
		M.SmoothPlastic
	)
	Build.part(
		parent,
		Vector3.new(6.4, 2.4, 7),
		frame * CFrame.new(0, 4.6, 0.5),
		TAXI,
		M.SmoothPlastic
	)
	Build.part(
		parent,
		Vector3.new(6.5, 1.8, 6),
		frame * CFrame.new(0, 4.6, 0.5),
		rgb(40, 50, 70),
		M.Glass
	)
	Build.part(
		parent,
		Vector3.new(2.5, 1, 1),
		frame * CFrame.new(0, 6.3, 0.5),
		rgb(255, 255, 255),
		M.Neon
	)
	for _, corner in
		{ Vector2.new(-1, -1), Vector2.new(1, -1), Vector2.new(-1, 1), Vector2.new(1, 1) }
	do
		Build.part(
			parent,
			Vector3.new(1.2, 2.6, 2.6),
			frame * CFrame.new(corner.X * 3.4, 1.3, corner.Y * 4.5),
			rgb(25, 25, 25),
			M.SmoothPlastic,
			{ shape = Enum.PartType.Cylinder }
		)
	end
end

local function streetLamp(parent: Instance, frame: CFrame)
	Build.column(parent, frame * CFrame.new(0, 8, 0), 16, 0.8, rgb(40, 45, 40), M.Metal)
	Build.part(
		parent,
		Vector3.new(0.6, 0.6, 4),
		frame * CFrame.new(0, 16, -2),
		rgb(40, 45, 40),
		M.Metal
	)
	local bulb = Build.part(
		parent,
		Vector3.new(1.4, 0.8, 1.6),
		frame * CFrame.new(0, 15.5, -3.5),
		rgb(255, 240, 200),
		M.Neon
	)
	local light = Instance.new("PointLight")
	light.Range = 22
	light.Brightness = 1.5
	light.Parent = bulb
end

local function statue(parent: Instance, frame: CFrame)
	local copper = rgb(110, 175, 150)
	Build.part(parent, Vector3.new(14, 10, 14), frame * CFrame.new(0, 5, 0), CONCRETE, M.Concrete)
	Build.part(parent, Vector3.new(5, 14, 4), frame * CFrame.new(0, 17, 0), copper, M.Metal)
	Build.part(parent, Vector3.new(6, 4, 5), frame * CFrame.new(0, 12, 0), copper, M.Metal)
	Build.ball(parent, (frame * CFrame.new(0, 26, 0)).Position, 3.6, copper, M.Metal)
	for spike = -2, 2 do
		Build.part(
			parent,
			Vector3.new(0.5, 2.4, 0.5),
			frame * CFrame.new(spike * 0.8, 28.4, 0) * CFrame.Angles(0, 0, -spike * 0.25),
			copper,
			M.Metal
		)
	end
	Build.part(
		parent,
		Vector3.new(1.4, 9, 1.4),
		frame * CFrame.new(3.2, 26, 0) * CFrame.Angles(0, 0, -0.15),
		copper,
		M.Metal
	)
	local flame = Build.part(
		parent,
		Vector3.new(1.6, 2.4, 1.6),
		frame * CFrame.new(3.9, 31.5, 0),
		rgb(255, 180, 40),
		M.Neon
	)
	Instance.new("Fire", flame).Size = 4
	Build.part(
		parent,
		Vector3.new(1.2, 3, 3.5),
		frame * CFrame.new(-2.5, 17, -2.6),
		copper,
		M.Metal
	)
end

function Skyscraper.build(parent: Instance, base: CFrame): Model
	local model = Build.model("MayhemTower", parent)

	-- Plaza.
	Build.part(
		model,
		Vector3.new(160, 0.8, 160),
		base * CFrame.new(0, 0.4, 0),
		CONCRETE,
		M.Pavement
	)

	local towerBase = base * CFrame.new(0, 0.8, 0)
	local tower = Build.storyBuilding(model, towerBase, {
		width = SIZE,
		depth = SIZE,
		floors = FLOORS,
		floorHeight = FLOOR_HEIGHT,
		wallColor = STEEL,
		wallMaterial = M.Metal,
		floorColor = rgb(130, 130, 135),
		floorMaterial = M.Concrete,
		stairColor = rgb(100, 100, 105),
		trimColor = rgb(200, 205, 215),
		trimMaterial = M.Metal,
		glassColor = GLASS,
		windowWidth = 9,
		windowHeight = 9,
		windowSill = 2,
		windowSpacing = 12,
		doorWidth = 14,
		sideDoors = true,
		parapet = 4,
	})

	-- Art-deco crown, set forward so the roof stair hole at the back stays clear.
	local roof = towerBase * CFrame.new(0, tower.roofTop, -8)
	Build.part(model, Vector3.new(40, 16, 40), roof * CFrame.new(0, 8, 0), STEEL, M.Metal)
	Build.ring(model, roof * CFrame.new(0, 15, 0), 41, 41, 1, 0.6, GOLD, M.Neon)
	Build.part(model, Vector3.new(28, 12, 28), roof * CFrame.new(0, 22, 0), STEEL, M.Metal)
	Build.ring(model, roof * CFrame.new(0, 27, 0), 29, 29, 1, 0.6, GOLD, M.Neon)
	-- Helipad on the top of the crown.
	Build.column(model, roof * CFrame.new(0, 28.1, 0), 0.2, 24, rgb(40, 40, 45), M.Concrete)
	Build.part(
		model,
		Vector3.new(1.4, 0.3, 8),
		roof * CFrame.new(-2.5, 28.3, 0),
		rgb(255, 220, 40),
		M.Neon,
		{ canCollide = false }
	)
	Build.part(
		model,
		Vector3.new(1.4, 0.3, 8),
		roof * CFrame.new(2.5, 28.3, 0),
		rgb(255, 220, 40),
		M.Neon,
		{ canCollide = false }
	)
	Build.part(
		model,
		Vector3.new(5, 0.3, 1.4),
		roof * CFrame.new(0, 28.3, 0),
		rgb(255, 220, 40),
		M.Neon,
		{ canCollide = false }
	)
	Build.truss(model, roof * CFrame.new(0, 0, 21), 28, STEEL)
	-- Antenna with a blinking-red beacon.
	Build.column(model, roof * CFrame.new(12, 28 + 20, 12), 40, 1.2, rgb(200, 200, 205), M.Metal)
	Build.ball(model, (roof * CFrame.new(12, 69, 12)).Position, 2.4, rgb(255, 30, 30), M.Neon)

	-- Sign on the crown.
	local sign = Build.part(
		model,
		Vector3.new(36, 6, 0.6),
		roof * CFrame.new(0, 8, -20.4),
		rgb(20, 20, 30),
		M.SmoothPlastic
	)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.LightInfluence = 0
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30
	gui.Parent = sign
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "MAYHEM TOWER"
	label.TextScaled = true
	label.Font = Enum.Font.Bangers
	label.TextColor3 = rgb(255, 80, 80)
	label.Parent = gui

	-- Express elevator: lobby pad to the roof, roof pad back to the plaza.
	elevatorPad(
		model,
		towerBase * CFrame.new(18, 1, -18),
		roof * CFrame.new(0, 3, 26),
		"⬆ ROOF",
		rgb(60, 255, 120)
	)
	elevatorPad(
		model,
		roof * CFrame.new(18, 0, 28),
		base * CFrame.new(0, 5, -60),
		"⬇ STREET",
		rgb(255, 140, 40)
	)

	-- Plaza props.
	statue(model, base * CFrame.new(-55, 0.8, -55))
	for _, x in { -60, -40, 40, 60 } do
		streetLamp(model, base * CFrame.new(x, 0.8, -75))
	end
	taxi(model, base * CFrame.new(45, 0.8, -50) * CFrame.Angles(0, math.rad(15), 0))
	taxi(model, base * CFrame.new(58, 0.8, -40) * CFrame.Angles(0, math.rad(-10), 0))
	taxi(model, base * CFrame.new(-50, 0.8, 50) * CFrame.Angles(0, math.rad(80), 0))
	for _, position in { Vector3.new(30, 0, -70), Vector3.new(-30, 0, -70), Vector3.new(70, 0, 20) } do
		local hydrant = base * CFrame.new(position + Vector3.new(0, 0.8, 0))
		Build.column(model, hydrant * CFrame.new(0, 1.5, 0), 3, 1.6, rgb(220, 30, 30), M.Metal)
		Build.ball(
			model,
			(hydrant * CFrame.new(0, 3.1, 0)).Position,
			1.6,
			rgb(220, 30, 30),
			M.Metal
		)
	end
	-- Hot dog cart.
	local cart = base * CFrame.new(40, 0.8, 55)
	Build.part(model, Vector3.new(8, 4, 4), cart * CFrame.new(0, 3, 0), rgb(220, 220, 225), M.Metal)
	Build.part(
		model,
		Vector3.new(9, 0.4, 5),
		cart * CFrame.new(0, 9, 0),
		rgb(230, 60, 40),
		M.Fabric
	)
	Build.part(
		model,
		Vector3.new(0.4, 4, 0.4),
		cart * CFrame.new(0, 7, 0),
		rgb(150, 150, 150),
		M.Metal
	)
	Build.part(
		model,
		Vector3.new(2.5, 0.6, 0.6),
		cart * CFrame.new(0, 5.3, 0),
		rgb(200, 110, 60),
		M.SmoothPlastic
	)
	return model
end

return Skyscraper
