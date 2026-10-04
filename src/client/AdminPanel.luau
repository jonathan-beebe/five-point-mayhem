-- God-mode panel for admins: one-tap powers, plus gifting any weapon or power-up to a player
-- or to everyone. The server re-checks admin rights on every command.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local VehicleCatalog = require(ReplicatedStorage.Shared.VehicleCatalog)
local WeaponCatalog = require(ReplicatedStorage.Shared.WeaponCatalog)

local AdminPanel = {}

local player = Players.LocalPlayer
local rgb = Color3.fromRGB

local GIFTS = {
	{ id = "arsenal", label = "🧰 EVERY WEAPON" },
	{ id = "heal", label = "❤ Full heal" },
	{ id = "shield", label = "🛡 Shield (30s)" },
	{ id = "speed", label = "👟 Super speed" },
	{ id = "jump", label = "🦘 Mega jump" },
	{ id = "giant", label = "🗿 Giant" },
	{ id = "car", label = "🚙 Random vehicle" },
}

local POWERS = {
	{
		command = "mayhem",
		label = "☢ MAYHEM",
		color = rgb(200, 20, 30),
		hint = "Destroy everyone outside the lobby",
	},
	{
		command = "meteors",
		label = "☄ METEORS",
		color = rgb(220, 110, 30),
		hint = "30 second meteor storm",
	},
	{
		command = "gravity",
		label = "🌙 GRAVITY",
		color = rgb(70, 90, 180),
		hint = "Toggle moon gravity",
	},
	{
		command = "freeze",
		label = "❄ FREEZE",
		color = rgb(60, 160, 210),
		hint = "Freeze the target",
		targeted = true,
	},
	{
		command = "horde",
		label = "👹 HORDE",
		color = rgb(60, 140, 50),
		hint = "Summon monsters",
		targeted = true,
	},
	{
		command = "night",
		label = "🌓 NIGHT",
		color = rgb(50, 40, 90),
		hint = "Toggle day and night",
	},
}

local function create(
	className: string,
	properties: { [string]: any },
	children: { Instance }?
): any
	local instance = Instance.new(className)
	for key, value in properties do
		(instance :: any)[key] = value
	end
	for _, child in children or {} do
		child.Parent = instance
	end
	return instance
end

local function corner(): UICorner
	return create("UICorner", { CornerRadius = UDim.new(0, 8) })
end

local built = false

local function build()
	if built then
		return
	end
	built = true
	local target = "all"

	local gui = create("ScreenGui", {
		Name = "MayhemAdmin",
		ResetOnSpawn = false,
		DisplayOrder = 15,
		Parent = player:WaitForChild("PlayerGui"),
	})
	local toggle = create("TextButton", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 60),
		Size = UDim2.fromOffset(130, 40),
		BackgroundColor3 = rgb(255, 200, 40),
		Text = "👑 GOD MODE",
		TextColor3 = rgb(40, 20, 0),
		TextSize = 16,
		Font = Enum.Font.LuckiestGuy,
		Parent = gui,
	}, { corner() })

	local panel = create("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 106),
		Size = UDim2.fromOffset(300, 470),
		BackgroundColor3 = rgb(20, 16, 10),
		BackgroundTransparency = 0.1,
		Visible = false,
		Parent = gui,
	}, { corner(), create("UIStroke", { Color = rgb(255, 200, 40), Thickness = 2 }) })

	local targetButton = create("TextButton", {
		Position = UDim2.fromOffset(10, 10),
		Size = UDim2.fromOffset(280, 34),
		BackgroundColor3 = rgb(60, 50, 30),
		TextColor3 = rgb(255, 230, 150),
		TextSize = 15,
		Font = Enum.Font.GothamBold,
		Parent = panel,
	}, { corner() })

	local function refreshTarget()
		targetButton.Text = "🎯 Target: "
			.. (if target == "all" then "EVERYONE" else target)
			.. "  (tap to change)"
	end
	targetButton.Activated:Connect(function()
		local names = { "all" }
		for _, other in Players:GetPlayers() do
			table.insert(names, other.Name)
		end
		local index = table.find(names, target) or 0
		target = names[index % #names + 1]
		refreshTarget()
	end)
	refreshTarget()

	for index, power in POWERS do
		local column = (index - 1) % 2
		local row = math.floor((index - 1) / 2)
		local button = create("TextButton", {
			Position = UDim2.fromOffset(10 + column * 142, 52 + row * 46),
			Size = UDim2.fromOffset(138, 40),
			BackgroundColor3 = power.color,
			Text = power.label,
			TextColor3 = rgb(255, 255, 255),
			TextSize = 16,
			Font = Enum.Font.LuckiestGuy,
			Parent = panel,
		}, { corner() })
		button.Activated:Connect(function()
			local argument = if power.targeted and target ~= "all" then target else nil
			if power.command == "freeze" and target == "all" then
				argument = "all"
			end
			Remotes.AdminCommand:FireServer(power.command, argument)
		end)
	end

	create("TextLabel", {
		Position = UDim2.fromOffset(10, 194),
		Size = UDim2.fromOffset(280, 22),
		BackgroundTransparency = 1,
		Text = "🎁 GIVE TO TARGET",
		TextColor3 = rgb(255, 210, 60),
		TextSize = 16,
		Font = Enum.Font.LuckiestGuy,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = panel,
	})

	local list = create("ScrollingFrame", {
		Position = UDim2.fromOffset(10, 220),
		Size = UDim2.fromOffset(280, 240),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = panel,
	}, {
		create(
			"UIListLayout",
			{ Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }
		),
	})

	local entries = table.clone(GIFTS)
	for _, vehicle in VehicleCatalog.ALL do
		table.insert(entries, { id = vehicle.id, label = vehicle.icon .. " " .. vehicle.name })
	end
	for _, weapon in WeaponCatalog.ALL do
		table.insert(entries, { id = weapon.id, label = weapon.name })
	end
	for order, entry in entries do
		local button = create("TextButton", {
			LayoutOrder = order,
			Size = UDim2.new(1, -8, 0, 30),
			BackgroundColor3 = if order <= #GIFTS then rgb(90, 70, 20) else rgb(45, 40, 35),
			Text = entry.label,
			TextColor3 = rgb(255, 255, 255),
			TextSize = 14,
			Font = Enum.Font.GothamBold,
			Parent = list,
		}, { corner() })
		button.Activated:Connect(function()
			Remotes.AdminCommand:FireServer("give", target, entry.id)
		end)
	end

	toggle.Activated:Connect(function()
		panel.Visible = not panel.Visible
	end)
end

function AdminPanel.start()
	if player:GetAttribute("IsAdmin") then
		build()
	end
	player:GetAttributeChangedSignal("IsAdmin"):Connect(function()
		if player:GetAttribute("IsAdmin") then
			build()
		end
	end)
end

return AdminPanel
