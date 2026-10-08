-- God-mode panel for admins: one-tap powers, gifting any weapon or power-up to a player or to
-- everyone, and sending them to a world's gate. Its toggle tops the system rail; the panel opens
-- in the rail's drawer (ui/RightColumn). Top to bottom: the target, the powers four to a row,
-- then the gift menus (the GATES menu among them).
-- On a small screen POWERS and GIFTS tabs show one section at a time; on a large one both show
-- and the gifts sit two to a row. The server re-checks admin rights on every command.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AdminCommands = require(ReplicatedStorage.Shared.AdminCommands)
local Config = require(ReplicatedStorage.Shared.Config)
local Names = require(ReplicatedStorage.Shared.Names)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local VehicleCatalog = require(ReplicatedStorage.Shared.VehicleCatalog)
local WeaponCatalog = require(ReplicatedStorage.Shared.WeaponCatalog)
local MacPanel = require(script.Parent.MacPanel)
local Create = require(script.Parent.ui.Create)
local RightColumn = require(script.Parent.ui.RightColumn)
local Theme = require(script.Parent.ui.Theme)

local AdminPanel = {}

local player = Players.LocalPlayer
local rgb = Color3.fromRGB
local create = Create.create

-- The gift menu and the power buttons: src/shared/AdminCommands.luau.
local GIFTS = AdminCommands.GIFTS
local POWERS = AdminCommands.POWERS

local function corner(): UICorner
	return Create.corner(Theme.Radius.panel)
end

local built = false

local GOLD = rgb(255, 200, 40)
local ROW = 44 -- every row's height: tabs, target, power and gift buttons
local GAP = 6
local PAD = 10

local function build()
	if built then
		return
	end
	built = true
	local target = "all"
	local tab = "powers" -- small screens show one section at a time: "powers" or "gifts"
	local small = true

	local gui = create("ScreenGui", {
		Name = "MayhemAdmin",
		ResetOnSpawn = false,
		ScreenInsets = RightColumn.SCREEN_INSETS,
		DisplayOrder = Theme.DisplayOrder.panels,
		Parent = player:WaitForChild("PlayerGui"),
	})
	local toggle = RightColumn.makeToggle(gui, 0, {
		BackgroundColor3 = GOLD,
		Text = "👑 GOD MODE",
		TextColor3 = rgb(40, 20, 0),
	})
	RightColumn.setLabels(toggle, "👑\nGOD", "👑 GOD MODE")

	-- The panel fills the drawer's width and is as tall as its content, up to the drawer's height;
	-- past that it scrolls as one, so on a short (phone) screen every part stays reachable.
	local width = RightColumn.PANEL_WIDTH
	local constraint = create("UISizeConstraint", { MaxSize = Vector2.new(width, 470) })
	local panel = RightColumn.makePanel("ScrollingFrame", gui, GOLD, {
		Size = UDim2.fromOffset(width, 0),
		BackgroundColor3 = rgb(20, 16, 10),
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		CanvasSize = UDim2.new(),
	}, { constraint }, true)
	Create.padding(UDim.new(0, PAD), UDim.new(0, PAD)).Parent = panel
	local list = create("UIListLayout", {
		Padding = UDim.new(0, GAP),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = panel,
	})

	-- A full-width row of the panel's list.
	local function row(order: number, height: number?): Frame
		return create("Frame", {
			LayoutOrder = order,
			Size = UDim2.new(1, -6, 0, height or ROW), -- -6: clear of the scroll bar
			AutomaticSize = if height then Enum.AutomaticSize.None else Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Parent = panel,
		})
	end

	local function textButton(parent: Instance, order: number, text: string, color: Color3)
		return create("TextButton", {
			LayoutOrder = order,
			BackgroundColor3 = color,
			Text = text,
			TextColor3 = rgb(255, 255, 255),
			TextScaled = true,
			Font = Theme.Fonts.bold,
			Parent = parent,
		}, {
			corner(),
			Create.padding(UDim.new(0, 6), UDim.new(0, 10)),
			create("UITextSizeConstraint", { MaxTextSize = 15 }),
		})
	end

	-- Tabs (small screens): POWERS | GIFTS.
	local tabs = row(1, ROW)
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, GAP),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = tabs,
	})
	local tabButtons: { [string]: TextButton } = {}
	for order, name in { "powers", "gifts" } do
		local button = textButton(tabs, order, string.upper(name), rgb(60, 50, 30))
		button.Size = UDim2.new(0.5, -GAP / 2, 1, 0)
		tabButtons[name] = button
	end

	local targetButton = textButton(row(2, ROW), 0, "", rgb(60, 50, 30))
	targetButton.Size = UDim2.fromScale(1, 1)
	targetButton.TextColor3 = rgb(255, 230, 150)
	local function refreshTarget()
		targetButton.Text = "🎯 Target: "
			.. (if target == "all" then "EVERYONE" else target)
			.. "  ▾"
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

	-- Powers: four to a row.
	local powers = row(3)
	create("UIGridLayout", {
		CellSize = UDim2.new(0.25, -GAP * 3 / 4, 0, ROW),
		CellPadding = UDim2.fromOffset(GAP, GAP),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = powers,
	})
	for index, power in POWERS do
		local button = textButton(powers, index, power.label, power.color)
		button.Font = Theme.Fonts.title
		button.Activated:Connect(function()
			local argument = if power.targeted and target ~= "all" then target else nil
			if power.command == "freeze" and target == "all" then
				argument = "all"
			end
			Remotes.AdminCommand:FireServer(power.command, argument)
		end)
	end

	local heading = create("TextLabel", {
		LayoutOrder = 4,
		Size = UDim2.new(1, -6, 0, 22),
		BackgroundTransparency = 1,
		TextColor3 = rgb(255, 210, 60),
		TextSize = 16,
		Font = Theme.Fonts.title,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = panel,
	})

	-- The menus: WEAPONS, VEHICLES, MECHS and GATES buttons above the gifts, and one menu for
	-- each of those. One shows at a time; each grows to fit its items, two to a row on a large
	-- screen. Every menu gives its item to the target but GATES, which sends the target there.
	local menus: { [string]: Frame } = {}
	local grids: { UIGridLayout } = {}
	local current = "gifts"
	local HEADINGS = {
		gifts = "🎁 GIVE TO TARGET",
		weapons = "🎁 GIVE TO TARGET › WEAPONS",
		vehicles = "🎁 GIVE TO TARGET › VEHICLES",
		mechs = "🎁 GIVE TO TARGET › MECHS",
		gates = "🚪 SEND TARGET › GATES",
	}

	local function give(id: string)
		Remotes.AdminCommand:FireServer("give", target, id)
	end

	local function menu(
		name: string,
		entries: { { id: string, label: string } },
		color: Color3,
		send: (id: string) -> ()
	)
		local frame = row(5)
		frame.Visible = false
		table.insert(
			grids,
			create("UIGridLayout", {
				CellPadding = UDim2.fromOffset(GAP, GAP),
				SortOrder = Enum.SortOrder.LayoutOrder,
				Parent = frame,
			})
		)
		menus[name] = frame
		for order, entry in entries do
			textButton(frame, order, entry.label, color).Activated:Connect(function()
				send(entry.id)
			end)
		end
		return frame
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
	local gates = {}
	for _, region in Config.REGIONS do
		table.insert(gates, { id = region.id, label = "🚪 " .. region.world })
	end
	local function sendToGate(id: string)
		Remotes.AdminCommand:FireServer("goto", id, target)
	end
	local submenus = {
		{ name = "weapons", label = "🔫 WEAPONS  ›", entries = weapons, send = give },
		{ name = "vehicles", label = "🚙 VEHICLES  ›", entries = vehicles, send = give },
		{ name = "mechs", label = "🤖 MECHS  ›", entries = mechs, send = give },
		{ name = "gates", label = "🚪 GATES  ›", entries = gates, send = sendToGate },
	}

	-- Shows what the size class and the tab call for.
	local function refresh()
		tabs.Visible = small
		local showPowers = not small or tab == "powers"
		local showGifts = not small or tab == "gifts"
		powers.Visible = showPowers
		heading.Visible = showGifts
		heading.Text = HEADINGS[current]
		for name, frame in menus do
			frame.Visible = showGifts and name == current
		end
		for name, button in tabButtons do
			button.BackgroundColor3 = if name == tab then GOLD else rgb(60, 50, 30)
			button.TextColor3 = if name == tab then rgb(40, 20, 0) else rgb(255, 230, 150)
		end
		local cell = if small then UDim2.new(1, 0, 0, ROW) else UDim2.new(0.5, -GAP / 2, 0, ROW)
		for _, grid in grids do
			grid.CellSize = cell
		end
	end

	-- Switches menu and scrolls the panel so the heading is at the top.
	local function open(name: string)
		current = name
		refresh()
		local top = heading.AbsolutePosition.Y - panel.AbsolutePosition.Y
		panel.CanvasPosition = Vector2.new(0, panel.CanvasPosition.Y + top)
	end

	local gifts = menu("gifts", GIFTS, rgb(90, 70, 20), give)
	for offset, submenu in submenus do
		textButton(gifts, offset - #submenus, submenu.label, rgb(70, 60, 110)).Activated:Connect(
			function()
				open(submenu.name)
			end
		)
		local items = menu(submenu.name, submenu.entries, rgb(45, 40, 35), submenu.send)
		textButton(items, 0, "‹  BACK", rgb(70, 60, 110)).Activated:Connect(function()
			open("gifts")
		end)
	end

	for name, button in tabButtons do
		button.Activated:Connect(function()
			tab = name
			refresh()
		end)
	end

	-- The canvas and the panel's height follow the content (AutomaticCanvasSize left the canvas at
	-- the window's size, so there was nothing to scroll).
	local function fit()
		local height = list.AbsoluteContentSize.Y + PAD * 2
		panel.CanvasSize = UDim2.fromOffset(0, height)
		constraint.MaxSize = Vector2.new(math.huge, height)
	end
	list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(fit)

	toggle.Activated:Connect(function()
		panel.Visible = not panel.Visible
		if panel.Visible then
			MacPanel.close()
		end
	end)
	RightColumn.opened:Connect(function()
		panel.Visible = false
	end)
	RightColumn.onLayout(function(isSmall)
		small = isSmall
		refresh()
	end)
	refresh()
	fit()
	RightColumn.watch(gui)
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
