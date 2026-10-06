-- God-mode panel for admins: one-tap powers, plus gifting any weapon or power-up to a player
-- or to everyone. The server re-checks admin rights on every command.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AdminCommands = require(ReplicatedStorage.Shared.AdminCommands)
local Names = require(ReplicatedStorage.Shared.Names)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local VehicleCatalog = require(ReplicatedStorage.Shared.VehicleCatalog)
local WeaponCatalog = require(ReplicatedStorage.Shared.WeaponCatalog)
local MacPanel = require(script.Parent.MacPanel)

local AdminPanel = {}

local player = Players.LocalPlayer
local rgb = Color3.fromRGB

-- The gift menu and the power buttons: src/shared/AdminCommands.luau.
local GIFTS = AdminCommands.GIFTS
local POWERS = AdminCommands.POWERS

local function create(
	className: string,
	properties: { [string]: any },
	children: { Instance }?
): any
	local instance = Instance.new(className)
	for key, value in properties do
		(instance :: any)[key] = value
	end
	for _, child in (children or {}) :: { Instance } do
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
		Position = UDim2.new(1, -12, 0, MacPanel.TOGGLE_TOP),
		Size = UDim2.fromOffset(130, MacPanel.TOGGLE_HEIGHT),
		BackgroundColor3 = rgb(255, 200, 40),
		Text = "👑 GOD MODE",
		TextColor3 = rgb(40, 20, 0),
		TextSize = 16,
		Font = Enum.Font.LuckiestGuy,
		Parent = gui,
	}, { corner() })

	-- The whole panel scrolls as one, and is never taller than the space below the toggles, so on
	-- a short (phone) screen every part of it stays reachable.
	local panel = create("ScrollingFrame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, MacPanel.PANEL_TOP),
		Size = UDim2.new(0, 300, 1, -(MacPanel.PANEL_TOP + 12)),
		BackgroundColor3 = rgb(20, 16, 10),
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		CanvasSize = UDim2.new(),
		Visible = false,
		Parent = gui,
	}, {
		corner(),
		create("UIStroke", { Color = rgb(255, 200, 40), Thickness = 2 }),
		create("UISizeConstraint", { MaxSize = Vector2.new(300, 470) }),
	})
	table.insert(MacPanel.panels, panel)

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

	-- Powers sit two to a row under the target button. An odd last power fills its row.
	local GRID_TOP = targetButton.Position.Y.Offset + targetButton.Size.Y.Offset + 8
	local FULL_WIDTH = targetButton.Size.X.Offset
	local CELL_WIDTH, CELL_HEIGHT = 138, 40
	local COLUMN_PITCH, ROW_PITCH = 142, 46
	local rows = math.ceil(#POWERS / 2)
	for index, power in POWERS do
		local column = (index - 1) % 2
		local row = math.floor((index - 1) / 2)
		local alone = index == #POWERS and column == 0
		local button = create("TextButton", {
			Position = UDim2.fromOffset(10 + column * COLUMN_PITCH, GRID_TOP + row * ROW_PITCH),
			Size = UDim2.fromOffset(if alone then FULL_WIDTH else CELL_WIDTH, CELL_HEIGHT),
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

	local heading = create("TextLabel", {
		Position = UDim2.fromOffset(10, GRID_TOP + rows * ROW_PITCH + 4),
		Size = UDim2.fromOffset(FULL_WIDTH, 22),
		BackgroundTransparency = 1,
		TextColor3 = rgb(255, 210, 60),
		TextSize = 16,
		Font = Enum.Font.LuckiestGuy,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = panel,
	})

	-- The menus share the space under the heading: WEAPONS, VEHICLES and MECHS buttons above
	-- the gifts, and one menu for each of those. One shows at a time. Menus grow to fit
	-- their items; the panel scrolls them.
	local menus: { [string]: Frame } = {}
	local layouts: { [string]: UIListLayout } = {}
	local current = "gifts"
	local MENU_TOP = heading.Position.Y.Offset + heading.Size.Y.Offset + 4
	local MENU_BOTTOM_PADDING = 10
	local HEADINGS = {
		gifts = "🎁 GIVE TO TARGET",
		weapons = "🎁 GIVE TO TARGET › WEAPONS",
		vehicles = "🎁 GIVE TO TARGET › VEHICLES",
		mechs = "🎁 GIVE TO TARGET › MECHS",
	}

	-- The canvas is sized from the open menu's measured height. AutomaticCanvasSize left the
	-- canvas at the window's size, so there was nothing to scroll.
	local function fitCanvas()
		local height = layouts[current].AbsoluteContentSize.Y
		panel.CanvasSize = UDim2.fromOffset(0, MENU_TOP + height + MENU_BOTTOM_PADDING)
	end

	local function show(name: string)
		current = name
		for each, menu in menus do
			menu.Visible = each == name
		end
		heading.Text = HEADINGS[name]
		fitCanvas()
	end

	-- Switches menu and scrolls the panel so the heading is at the top.
	local function open(name: string)
		show(name)
		panel.CanvasPosition = Vector2.new(0, heading.Position.Y.Offset - 8)
	end

	local function button(menu: Frame, order: number, label: string, color: Color3)
		return create("TextButton", {
			LayoutOrder = order,
			Size = UDim2.new(1, -8, 0, 30),
			BackgroundColor3 = color,
			Text = label,
			TextColor3 = rgb(255, 255, 255),
			TextSize = 14,
			Font = Enum.Font.GothamBold,
			Parent = menu,
		}, { corner() })
	end

	local function menu(name: string, entries: { { id: string, label: string } }, color: Color3)
		local layout = create(
			"UIListLayout",
			{ Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }
		)
		local list = create("Frame", {
			Position = UDim2.fromOffset(10, MENU_TOP),
			Size = UDim2.fromOffset(280, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Visible = false,
			Parent = panel,
		}, { layout })
		menus[name] = list
		layouts[name] = layout
		layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			if current == name then
				fitCanvas()
			end
		end)
		for order, entry in entries do
			button(list, order, entry.label, color).Activated:Connect(function()
				Remotes.AdminCommand:FireServer("give", target, entry.id)
			end)
		end
		return list
	end

	local weapons = {}
	for _, weapon in WeaponCatalog.ALL do
		table.insert(weapons, { id = weapon.id, label = weapon.name })
	end
	local vehicles, mechs = {}, {}
	for _, vehicle in VehicleCatalog.ALL do
		table.insert(
			if vehicle.mech then mechs else vehicles,
			{ id = vehicle.id, label = vehicle.icon .. " " .. vehicle.name }
		)
	end
	local submenus = {
		{ name = "weapons", label = "🔫 WEAPONS  ›", entries = weapons },
		{ name = "vehicles", label = "🚙 VEHICLES  ›", entries = vehicles },
		{ name = "mechs", label = "🤖 MECHS  ›", entries = mechs },
	}

	local gifts = menu("gifts", GIFTS, rgb(90, 70, 20))
	for offset, submenu in submenus do
		button(gifts, offset - #submenus, submenu.label, rgb(70, 60, 110)).Activated:Connect(
			function()
				open(submenu.name)
			end
		)
		local list = menu(submenu.name, submenu.entries, rgb(45, 40, 35))
		button(list, 0, "‹  BACK", rgb(70, 60, 110)).Activated:Connect(function()
			open("gifts")
		end)
	end
	show("gifts")

	toggle.Activated:Connect(function()
		panel.Visible = not panel.Visible
		if panel.Visible then
			MacPanel.close()
		end
	end)
	MacPanel.opened:Connect(function()
		panel.Visible = false
	end)
end

function AdminPanel.start()
	if player:GetAttribute(Names.Attributes.IsAdmin) then
		build()
	end
	player:GetAttributeChangedSignal(Names.Attributes.IsAdmin):Connect(function()
		if player:GetAttribute(Names.Attributes.IsAdmin) then
			build()
		end
	end)
end

return AdminPanel
