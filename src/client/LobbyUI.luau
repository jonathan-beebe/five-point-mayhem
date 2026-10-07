-- The armory sheet shown in the lobby: browse the catalog by category, pick up to three weapons,
-- pick a team, and deploy. The last loadout is remembered across respawns. start() builds the
-- screen: requiring this module builds nothing, so an error here cannot stop the client bootstrap
-- (init.client.luau) from requiring the other modules.
--
-- Two ScreenGuis. MayhemArmory (DisplayOrder modal, over the right column and its panels) holds
-- the sheet: it fills the gui's safe area (ScreenInsets CoreUISafeInsets: below the top bar,
-- inside the device's cutouts) less MARGIN. Header: ARMORY, the counter, Look around (hides the
-- sheet). Body: categories, the weapon grid, then LOADOUT, TEAM and ENTER THE MAYHEM. MayhemLobby
-- (DisplayOrder lobby) holds CHOOSE WEAPONS, which brings the sheet back.
--
-- layout() measures the gui and the viewport and applies HudLayout.armorySheet and
-- HudLayout.armory (size class, columns, card size, every rect) on every size change. Small
-- screens get compact cards (no description) and teams as colour dots; large ones cards with the
-- description and teams as named rows. Both team forms are the same buttons, restyled.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local HudLayout = require(ReplicatedStorage.Shared.HudLayout)
local Loadout = require(ReplicatedStorage.Shared.Loadout)
local Names = require(ReplicatedStorage.Shared.Names)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local WeaponCatalog = require(ReplicatedStorage.Shared.WeaponCatalog)
local Announcer = require(script.Parent.Announcer)
local Create = require(script.Parent.ui.Create)
local Theme = require(script.Parent.ui.Theme)

local LobbyUI = {}

local player = Players.LocalPlayer
local rgb = Color3.fromRGB
local create, label = Create.create, Create.label

local MARGIN = 12 -- gap between the sheet and its gui's safe area, as the right column's

local SHEET = rgb(12, 16, 24)
local CARD = rgb(26, 34, 48)
local PICKED = rgb(16, 48, 58) -- a chosen card's and a filled slot's background
local ACCENT = rgb(255, 60, 100)
local GOLD = rgb(255, 210, 60)
local TEXT = rgb(240, 240, 250)
local MUTED = rgb(199, 209, 220)
local DIM = rgb(142, 153, 166) -- an empty slot
local CYAN = Theme.Colors.cyan
local ON_CYAN = rgb(4, 33, 43) -- text on the selected category

local selected: { string } = {}
local category = "All"
local small = false -- the size class layout() last applied

local function corner(radius: number): UICorner
	return Create.corner(UDim.new(0, radius))
end

local function place(object: GuiObject, rect: HudLayout.Rect, dx: number?, dy: number?)
	object.Position = UDim2.fromOffset(rect.x + (dx or 0), rect.y + (dy or 0))
	object.Size = UDim2.fromOffset(rect.w, rect.h)
end

type Card = {
	button: TextButton,
	name: TextLabel,
	meta: TextLabel,
	description: TextLabel,
	stat: TextLabel,
}
type Slot = { button: TextButton, number: TextLabel, name: TextLabel, remove: TextLabel }
type Team = { button: TextButton, corner: UICorner, spec: { [string]: any } }

-- Built by build() when start() runs; requiring this module builds nothing.
local gui: ScreenGui
local armoryGui: ScreenGui
local sheet: Frame
local title: TextLabel
local counter: TextLabel
local lookButton: TextButton
local openButton: TextButton
local grid: ScrollingFrame
local gridLayout: UIGridLayout
local gridPadding: UIPadding
local loadoutLabel: TextLabel
local teamLabel: TextLabel
local teamName: TextLabel
local deployButton: TextButton
local slots: { Slot } = {}
local teams: { Team } = {}
local cards: { [string]: Card } = {}
local tabButtons: { TextButton } = {}
local tabIds: { [TextButton]: string } = {}
local hiddenByChoice = false

-- Behaviour -----------------------------------------------------------------------------------

local function refresh()
	local isAdmin = player:GetAttribute(Names.Attributes.IsAdmin) == true
	local available = Loadout.availableCount(isAdmin)
	Loadout.prune(selected, isAdmin)
	counter.Text = string.format(
		"%d weapons · carry up to %d · %d/%d chosen",
		available,
		Config.LOADOUT_SIZE,
		#selected,
		Config.LOADOUT_SIZE
	)
	for id, card in cards do
		local index = table.find(selected, id)
		local weapon = WeaponCatalog.get(id) :: WeaponCatalog.Weapon
		local stat = Loadout.statText(weapon)
		if index then
			stat = if stat == "" then "slot " .. index else stat .. " · slot " .. index
		end
		card.stat.Text = stat
		card.button.BackgroundColor3 = if index then PICKED else CARD;
		(card.button:FindFirstChild("Selected") :: UIStroke).Enabled = index ~= nil
		card.button.Visible = Loadout.isAvailable(weapon, isAdmin)
			and (category == "All" or weapon.category == category)
	end
	for index, slot in slots do
		local weapon = selected[index] and WeaponCatalog.get(selected[index])
		slot.name.Text = if weapon then weapon.name else "empty"
		slot.name.TextColor3 = if weapon then TEXT else DIM
		slot.remove.Visible = weapon ~= nil
		slot.button.BackgroundColor3 = if weapon then PICKED else CARD
	end
	local chosen = nil
	for _, team in teams do
		local isChosen = player.Team ~= nil and player.Team.Name == team.spec.name
		if isChosen then
			chosen = team.spec
		end
		(team.button:FindFirstChild("Selected") :: UIStroke).Enabled = isChosen
		team.button.Text = if small
			then ""
			elseif isChosen then team.spec.name .. "  ·  " .. team.spec.blurb
			else team.spec.name
	end
	teamName.Text = if chosen then chosen.name .. " · " .. chosen.blurb else "Tap a colour to pick"
	for _, button in tabButtons do
		local isCurrent = tabIds[button] == category
		button.BackgroundTransparency = if isCurrent then 0 else 1
		button.TextColor3 = if isCurrent then ON_CYAN else MUTED
	end
end

local function toggle(id: string)
	if Loadout.toggle(selected, id) == "full" then
		Announcer.show(
			string.format(
				"You can carry %d weapons. Tap one in your loadout to swap it.",
				Config.LOADOUT_SIZE
			),
			GOLD,
			2
		)
	end
	refresh()
end

local function updateVisibility()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local inLobby = humanoid ~= nil
		and humanoid.Health > 0
		and not player:GetAttribute(Names.Attributes.Deployed)
	sheet.Visible = inLobby and not hiddenByChoice
	openButton.Visible = inLobby and hiddenByChoice
end

-- Layout --------------------------------------------------------------------------------------

-- Applies HudLayout to every element: the gui's area (the viewport until the gui has a size),
-- the sheet in it, then the sheet's insides from the sheet's size.
local function layout()
	local viewport = Workspace.CurrentCamera.ViewportSize
	local area = armoryGui.AbsoluteSize
	if area.X <= 0 or area.Y <= 0 then
		area = viewport
	end
	local box = HudLayout.armorySheet(area, MARGIN)
	place(sheet, box)
	local l = HudLayout.armory(Vector2.new(box.w, box.h), viewport, {
		categories = #tabButtons,
		slots = #slots,
		teams = #teams,
	})
	local s = l.sizes
	small = l.small

	place(title, l.title)
	title.TextSize = s.titleSize
	place(counter, l.counter)
	counter.TextSize = s.counterSize
	place(lookButton, l.look)
	lookButton.TextSize = s.lookSize

	for index, button in tabButtons do
		place(button, l.category, 0, (index - 1) * l.categoryStep)
		button.TextSize = s.categorySize
	end

	place(grid, l.grid)
	grid.ScrollBarThickness = s.scrollBar
	local inset = UDim.new(0, s.cardStroke)
	gridPadding.PaddingLeft, gridPadding.PaddingRight = inset, inset
	gridPadding.PaddingTop, gridPadding.PaddingBottom = inset, inset
	gridLayout.CellSize = UDim2.fromOffset(l.cell.X, l.cell.Y)
	gridLayout.CellPadding = UDim2.fromOffset(s.cardGap, s.cardGap)
	for _, card in cards do
		place(card.name, l.card.name)
		card.name.TextSize = s.nameSize
		place(card.meta, l.card.meta)
		card.meta.TextSize = s.metaSize
		place(card.description, l.card.description)
		card.description.TextSize = s.descriptionSize
		card.description.Visible = s.descriptionSize > 0
		place(card.stat, l.card.stat)
		card.stat.TextSize = s.statSize
	end

	place(loadoutLabel, l.loadoutLabel)
	loadoutLabel.TextSize = s.labelSize
	for index, slot in slots do
		place(slot.button, l.slot, 0, (index - 1) * l.slotStep)
		slot.number.TextSize = s.slotSize
		slot.name.TextSize = s.slotSize
		slot.remove.TextSize = s.slotSize
	end

	place(teamLabel, l.teamLabel)
	teamLabel.TextSize = s.labelSize
	for index, team in teams do
		local step = l.teamStep * (index - 1)
		place(team.button, l.team, step.X, step.Y)
		team.button.TextSize = s.teamSize
		team.button.BackgroundColor3 = if s.dots
			then team.spec.color.Color
			else team.spec.color.Color:Lerp(rgb(0, 0, 0), 0.35)
		team.corner.CornerRadius = if s.dots then Theme.Radius.round else UDim.new(0, 12)
	end
	place(teamName, l.teamName)
	teamName.TextSize = s.teamSize
	teamName.Visible = s.dots

	place(deployButton, l.deploy)
	deployButton.TextSize = s.deploySize

	refresh()
end

local function selectedStroke(): UIStroke
	return create("UIStroke", {
		Name = "Selected",
		Color = CYAN,
		Thickness = 2,
		Enabled = false,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

local function build()
	gui = create("ScreenGui", {
		Name = "MayhemLobby",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = Theme.DisplayOrder.lobby,
	})
	armoryGui = create("ScreenGui", {
		Name = "MayhemArmory",
		ResetOnSpawn = false,
		ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = Theme.DisplayOrder.modal,
	})

	local edge = Create.stroke(TEXT, 1.5)
	edge.Transparency = 0.8
	sheet = create("Frame", {
		BackgroundColor3 = SHEET,
		BackgroundTransparency = 0.04,
		Parent = armoryGui,
	}, { corner(20), edge })

	title = label("ARMORY", 20, TEXT, {
		Font = Theme.Fonts.title,
		TextWrapped = false,
		Parent = sheet,
	})
	counter = label("", 11, MUTED, {
		TextWrapped = false,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = sheet,
	})

	local lookEdge = Create.stroke(TEXT, 1.5, Enum.ApplyStrokeMode.Border)
	lookEdge.Transparency = 0.72
	lookButton = create("TextButton", {
		BackgroundTransparency = 1,
		Text = "👀 Look around",
		TextColor3 = TEXT,
		Font = Theme.Fonts.bold,
		Parent = sheet,
	}, { Create.corner(Theme.Radius.round), lookEdge })

	openButton = create("TextButton", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -110),
		Size = UDim2.fromOffset(240, 54),
		BackgroundColor3 = ACCENT,
		Text = "🔫 CHOOSE WEAPONS",
		TextColor3 = TEXT,
		TextSize = 20,
		Font = Theme.Fonts.title,
		Visible = false,
		Parent = gui,
	}, {
		corner(14),
		Create.stroke(TEXT, 2, Enum.ApplyStrokeMode.Border),
	})

	-- Categories: a vertical list, the current one filled cyan.
	local tabList = { "All" }
	for _, entry in WeaponCatalog.CATEGORIES do
		table.insert(tabList, entry.id)
	end
	for _, id in tabList do
		local button = create("TextButton", {
			BackgroundColor3 = CYAN,
			BackgroundTransparency = 1,
			Text = id,
			TextColor3 = MUTED,
			Font = Theme.Fonts.bold,
			TextXAlignment = Enum.TextXAlignment.Left,
			AutoButtonColor = false,
			Parent = sheet,
		}, { corner(10), Create.padding(UDim.new(0, 12), UDim.new(0, 0)) })
		button.Activated:Connect(function()
			category = id
			grid.CanvasPosition = Vector2.zero
			refresh()
		end)
		table.insert(tabButtons, button)
		tabIds[button] = id
	end

	gridLayout = create("UIGridLayout", { SortOrder = Enum.SortOrder.LayoutOrder })
	gridPadding = Create.padding(UDim.new(0, 0), UDim.new(0, 0))
	grid = create("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		VerticalScrollBarInset = Enum.ScrollBarInset.Always,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = sheet,
	}, { gridLayout, gridPadding })

	for order, weapon in WeaponCatalog.ALL do
		local card: Card = {
			name = label(weapon.name, 12, TEXT, {
				Name = "WeaponName",
				TextWrapped = false,
				TextTruncate = Enum.TextTruncate.AtEnd,
			}),
			meta = label(Loadout.subtitle(weapon), 10, GOLD, {
				Name = "Meta",
				TextWrapped = false,
				TextTruncate = Enum.TextTruncate.AtEnd,
			}),
			description = label(weapon.description, 11, MUTED, {
				Name = "Description",
				Font = Theme.Fonts.regular,
				TextYAlignment = Enum.TextYAlignment.Top,
				TextTruncate = Enum.TextTruncate.AtEnd,
			}),
			stat = label("", 10, TEXT, { Name = "Stat", TextWrapped = false }),
			button = nil :: any,
		}
		card.button = create("TextButton", {
			LayoutOrder = order,
			BackgroundColor3 = CARD,
			Text = "",
			AutoButtonColor = true,
			Parent = grid,
		}, {
			corner(12),
			selectedStroke(),
			card.name,
			card.meta,
			card.description,
			card.stat,
		})
		card.button.Activated:Connect(function()
			toggle(weapon.id)
		end)
		cards[weapon.id] = card
	end

	-- Side column: loadout slots (tap a filled one to empty it), teams, deploy.
	loadoutLabel = label("LOADOUT", 11, GOLD, { Font = Theme.Fonts.title, Parent = sheet })
	for index = 1, Config.LOADOUT_SIZE do
		local slot: Slot = {
			number = label(tostring(index), 12, MUTED, {
				Position = UDim2.fromOffset(12, 0),
				Size = UDim2.new(0, 16, 1, 0),
			}),
			name = label("", 12, DIM, {
				Position = UDim2.fromOffset(32, 0),
				Size = UDim2.new(1, -60, 1, 0),
				TextWrapped = false,
				TextTruncate = Enum.TextTruncate.AtEnd,
			}),
			remove = label("✕", 12, MUTED, {
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -12, 0, 0),
				Size = UDim2.new(0, 16, 1, 0),
				TextXAlignment = Enum.TextXAlignment.Right,
			}),
			button = nil :: any,
		}
		slot.button = create("TextButton", {
			BackgroundColor3 = CARD,
			Text = "",
			Parent = sheet,
		}, { corner(10), slot.number, slot.name, slot.remove })
		slot.button.Activated:Connect(function()
			if selected[index] then
				table.remove(selected, index)
				refresh()
			end
		end)
		slots[index] = slot
	end

	teamLabel = label("TEAM", 11, GOLD, { Font = Theme.Fonts.title, Parent = sheet })
	for _, spec in Config.TEAMS do
		local team: Team = { corner = corner(12), spec = spec, button = nil :: any }
		team.button = create("TextButton", {
			Text = "",
			TextColor3 = TEXT,
			Font = Theme.Fonts.bold,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = sheet,
		}, {
			team.corner,
			Create.padding(UDim.new(0, 14), UDim.new(0, 0)),
			create("UIStroke", {
				Name = "Selected",
				Color = TEXT,
				Thickness = 2,
				Enabled = false,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}),
		})
		team.button.Activated:Connect(function()
			Remotes.ChooseTeam:FireServer(spec.name)
		end)
		table.insert(teams, team)
	end
	teamName = label("", 11, MUTED, {
		TextWrapped = false,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = sheet,
	})

	deployButton = create("TextButton", {
		BackgroundColor3 = ACCENT,
		Text = "ENTER THE MAYHEM",
		TextColor3 = TEXT,
		TextStrokeColor3 = rgb(40, 0, 10),
		TextStrokeTransparency = 0.3,
		Font = Theme.Fonts.title,
		TextWrapped = true,
		Parent = sheet,
	}, { corner(16) })

	deployButton.Activated:Connect(function()
		Remotes.Deploy:FireServer(table.clone(selected))
	end)

	lookButton.Activated:Connect(function()
		hiddenByChoice = true
		updateVisibility()
	end)

	openButton.Activated:Connect(function()
		hiddenByChoice = false
		updateVisibility()
	end)
end

function LobbyUI.start()
	build()
	local playerGui = player:WaitForChild("PlayerGui")
	gui.Parent = playerGui
	armoryGui.Parent = playerGui
	layout()
	Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(layout)
	armoryGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
	updateVisibility()

	player:GetAttributeChangedSignal(Names.Attributes.Deployed):Connect(function()
		if player:GetAttribute(Names.Attributes.Deployed) then
			Announcer.show("GO! Run out through any glowing gate!", rgb(120, 255, 140), 4)
		end
		hiddenByChoice = false
		updateVisibility()
	end)
	player:GetPropertyChangedSignal("Team"):Connect(refresh)
	player:GetAttributeChangedSignal(Names.Attributes.IsAdmin):Connect(refresh)
	Teams.ChildAdded:Connect(refresh)
	player.CharacterAdded:Connect(function(character)
		hiddenByChoice = false
		updateVisibility()
		local humanoid = character:WaitForChild("Humanoid") :: Humanoid
		humanoid.Died:Connect(updateVisibility)
		updateVisibility()
	end)
	if player.Character then
		local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Died:Connect(updateVisibility)
		end
	end
end

return LobbyUI
