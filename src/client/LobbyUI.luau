-- The armory screen shown in the lobby: browse the catalog by category, pick up to three
-- weapons, pick a team, and deploy. The last loadout is remembered across respawns.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local WeaponCatalog = require(ReplicatedStorage.Shared.WeaponCatalog)
local Announcer = require(script.Parent.Announcer)

local LobbyUI = {}

local player = Players.LocalPlayer
local rgb = Color3.fromRGB

local BACKGROUND = rgb(18, 18, 28)
local PANEL = rgb(32, 32, 48)
local ACCENT = rgb(255, 60, 100)
local GOLD = rgb(255, 210, 60)
local TEXT = rgb(240, 240, 250)
local MUTED = rgb(160, 160, 185)

local CATEGORY_COLORS = {
	Blades = rgb(120, 130, 160),
	Guns = rgb(110, 90, 70),
	Blasters = rgb(60, 140, 200),
	Explosives = rgb(200, 80, 50),
	Magic = rgb(140, 80, 200),
	Silly = rgb(230, 110, 170),
}

local KIND_LABELS = {
	melee = "Melee",
	hitscan = "Gun",
	projectile = "Launcher",
	strike = "Spell",
	heal = "Support",
	blink = "Mobility",
	push = "Blast",
}

local selected: { string } = {}
local category = "All"

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

local function corner(radius: number): UICorner
	return create("UICorner", { CornerRadius = UDim.new(0, radius) })
end

local function label(
	text: string,
	size: number,
	color: Color3,
	properties: { [string]: any }?
): TextLabel
	local result = create("TextLabel", {
		BackgroundTransparency = 1,
		Text = text,
		TextSize = size,
		TextColor3 = color,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
	})
	for key, value in properties or {} do
		(result :: any)[key] = value
	end
	return result
end

local function speedLabel(cooldown: number): string
	if cooldown <= 0.15 then
		return "rapid fire"
	elseif cooldown <= 0.5 then
		return "fast"
	elseif cooldown <= 1.2 then
		return "medium"
	end
	return "slow"
end

-- Layout --------------------------------------------------------------------------------------

local gui = create("ScreenGui", {
	Name = "MayhemLobby",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 10,
})

local panel = create("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(1060, 660),
	BackgroundColor3 = BACKGROUND,
	BackgroundTransparency = 0.08,
	Parent = gui,
}, {
	corner(18),
	create("UIStroke", { Color = ACCENT, Thickness = 3 }),
})
local scale = create("UIScale", { Parent = panel })

local function rescale()
	local viewport = Workspace.CurrentCamera.ViewportSize
	scale.Scale = math.min(viewport.X / 1100, viewport.Y / 720, 1)
end

label("CHOOSE YOUR WEAPONS", 34, TEXT, {
	Font = Enum.Font.LuckiestGuy,
	Position = UDim2.fromOffset(24, 14),
	Size = UDim2.fromOffset(600, 40),
	Parent = panel,
})
local counter = label("", 16, MUTED, {
	Position = UDim2.fromOffset(26, 52),
	Size = UDim2.fromOffset(600, 20),
	Parent = panel,
})

local lookButton = create("TextButton", {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -20, 0, 18),
	Size = UDim2.fromOffset(170, 40),
	BackgroundColor3 = PANEL,
	Text = "👀 Look around",
	TextColor3 = TEXT,
	TextSize = 16,
	Font = Enum.Font.GothamBold,
	Parent = panel,
}, { corner(10) })

local openButton = create("TextButton", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -110),
	Size = UDim2.fromOffset(240, 54),
	BackgroundColor3 = ACCENT,
	Text = "🔫 CHOOSE WEAPONS",
	TextColor3 = TEXT,
	TextSize = 20,
	Font = Enum.Font.LuckiestGuy,
	Visible = false,
	Parent = gui,
}, {
	corner(14),
	create(
		"UIStroke",
		{ Color = TEXT, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }
	),
})

-- Category tabs.
local tabs = create("Frame", {
	Position = UDim2.fromOffset(20, 84),
	Size = UDim2.fromOffset(700, 36),
	BackgroundTransparency = 1,
	Parent = panel,
}, {
	create(
		"UIListLayout",
		{ FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6) }
	),
})

local grid = create("ScrollingFrame", {
	Position = UDim2.fromOffset(20, 128),
	Size = UDim2.fromOffset(700, 512),
	BackgroundColor3 = PANEL,
	BackgroundTransparency = 0.4,
	BorderSizePixel = 0,
	ScrollBarThickness = 8,
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	CanvasSize = UDim2.new(),
	Parent = panel,
}, {
	corner(12),
	create("UIGridLayout", {
		CellSize = UDim2.fromOffset(164, 112),
		CellPadding = UDim2.fromOffset(8, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
	create("UIPadding", {
		PaddingTop = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 8),
	}),
})

-- Sidebar: loadout slots, teams, deploy.
local sidebar = create("Frame", {
	Position = UDim2.fromOffset(736, 84),
	Size = UDim2.fromOffset(304, 556),
	BackgroundTransparency = 1,
	Parent = panel,
})
label(
	"YOUR LOADOUT",
	20,
	GOLD,
	{ Font = Enum.Font.LuckiestGuy, Size = UDim2.fromOffset(300, 26), Parent = sidebar }
)
local slots: { TextButton } = {}
for index = 1, Config.LOADOUT_SIZE do
	slots[index] = create("TextButton", {
		Position = UDim2.fromOffset(0, 30 + (index - 1) * 52),
		Size = UDim2.fromOffset(304, 46),
		BackgroundColor3 = PANEL,
		TextColor3 = TEXT,
		TextSize = 16,
		Font = Enum.Font.GothamBold,
		Parent = sidebar,
	}, { corner(10) })
end

label("TEAM", 20, GOLD, {
	Font = Enum.Font.LuckiestGuy,
	Position = UDim2.fromOffset(0, 192),
	Size = UDim2.fromOffset(300, 26),
	Parent = sidebar,
})
local teamButtons: { [string]: TextButton } = {}
for index, spec in Config.TEAMS do
	local button = create("TextButton", {
		Position = UDim2.fromOffset(0, 222 + (index - 1) * 44),
		Size = UDim2.fromOffset(304, 38),
		BackgroundColor3 = spec.color.Color:Lerp(rgb(0, 0, 0), 0.35),
		Text = spec.name .. "  ·  " .. spec.blurb,
		TextColor3 = TEXT,
		TextSize = 14,
		Font = Enum.Font.GothamBold,
		Parent = sidebar,
	}, {
		corner(10),
		create("UIStroke", {
			Name = "Selected",
			Color = GOLD,
			Thickness = 3,
			Enabled = false,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}),
	})
	button.Activated:Connect(function()
		Remotes.ChooseTeam:FireServer(spec.name)
	end)
	teamButtons[spec.name] = button
end

local deployButton = create("TextButton", {
	Position = UDim2.fromOffset(0, 452),
	Size = UDim2.fromOffset(304, 96),
	BackgroundColor3 = ACCENT,
	Text = "ENTER THE MAYHEM",
	TextColor3 = TEXT,
	TextStrokeColor3 = rgb(40, 0, 10),
	TextStrokeTransparency = 0.3,
	TextSize = 30,
	Font = Enum.Font.LuckiestGuy,
	TextWrapped = true,
	Parent = sidebar,
}, {
	corner(14),
	create(
		"UIStroke",
		{ Color = TEXT, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }
	),
})

-- Behaviour -----------------------------------------------------------------------------------

local cards: { [string]: TextButton } = {}

-- Admin-only weapons are listed for admins only. The server refuses them for everyone else.
local function isAvailable(weapon: WeaponCatalog.Weapon): boolean
	return not weapon.adminOnly or player:GetAttribute("IsAdmin") == true
end

local function refresh()
	local available = 0
	for _, weapon in WeaponCatalog.ALL do
		if isAvailable(weapon) then
			available += 1
		end
	end
	for index = #selected, 1, -1 do
		local weapon = WeaponCatalog.get(selected[index])
		if not weapon or not isAvailable(weapon) then
			table.remove(selected, index)
		end
	end
	counter.Text = string.format(
		"%d weapons in the armory · carry up to %d · %d/%d chosen",
		available,
		Config.LOADOUT_SIZE,
		#selected,
		Config.LOADOUT_SIZE
	)
	for id, card in cards do
		local stroke = card:FindFirstChild("Selected") :: UIStroke
		local check = card:FindFirstChild("Check") :: TextLabel
		local isSelected = table.find(selected, id) ~= nil
		stroke.Enabled = isSelected
		check.Visible = isSelected
		local weapon = WeaponCatalog.get(id) :: WeaponCatalog.Weapon
		card.Visible = isAvailable(weapon) and (category == "All" or weapon.category == category)
	end
	for index, slot in slots do
		local weapon = selected[index] and WeaponCatalog.get(selected[index])
		slot.Text = if weapon
			then string.format("%d.  %s   ✕", index, weapon.name)
			else string.format("%d.  — empty —", index)
		slot.BackgroundColor3 = if weapon
			then CATEGORY_COLORS[weapon.category]:Lerp(rgb(0, 0, 0), 0.4)
			else PANEL
	end
	for name, button in teamButtons do
		(button:FindFirstChild("Selected") :: UIStroke).Enabled = player.Team ~= nil
			and player.Team.Name == name
	end
end

local function toggle(id: string)
	local index = table.find(selected, id)
	if index then
		table.remove(selected, index)
	elseif #selected < Config.LOADOUT_SIZE then
		table.insert(selected, id)
	else
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

for order, weapon in WeaponCatalog.ALL do
	local tint = CATEGORY_COLORS[weapon.category]
	local card = create("TextButton", {
		LayoutOrder = order,
		BackgroundColor3 = tint:Lerp(rgb(0, 0, 0), 0.55),
		Text = "",
		AutoButtonColor = true,
		Parent = grid,
	}, {
		corner(10),
		create("UIStroke", {
			Name = "Selected",
			Color = GOLD,
			Thickness = 3,
			Enabled = false,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}),
		create("Frame", {
			Size = UDim2.fromOffset(14, 14),
			Position = UDim2.fromOffset(8, 10),
			BackgroundColor3 = weapon.color,
			BorderSizePixel = 0,
		}, { corner(7) }),
		label(weapon.name, 15, TEXT, {
			Position = UDim2.fromOffset(28, 6),
			Size = UDim2.fromOffset(130, 22),
			TextTruncate = Enum.TextTruncate.AtEnd,
		}),
		label(
			string.format(
				"%s · %s",
				KIND_LABELS[weapon.kind] or weapon.kind,
				speedLabel(weapon.cooldown)
			),
			12,
			GOLD,
			{
				Position = UDim2.fromOffset(8, 30),
				Size = UDim2.fromOffset(150, 16),
			}
		),
		label(weapon.description, 12, MUTED, {
			Position = UDim2.fromOffset(8, 48),
			Size = UDim2.fromOffset(150, 44),
			Font = Enum.Font.Gotham,
			TextYAlignment = Enum.TextYAlignment.Top,
		}),
		label(
			if weapon.kind == "heal"
				then "HEAL " .. weapon.damage
				elseif weapon.damage > 0 then "DMG " .. weapon.damage .. (if weapon.pellets
					then "×" .. weapon.pellets
					else "")
				else "",
			12,
			TEXT,
			{
				Position = UDim2.fromOffset(8, 92),
				Size = UDim2.fromOffset(150, 16),
			}
		),
		label("✔", 22, GOLD, {
			Name = "Check",
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -6, 0, 2),
			Size = UDim2.fromOffset(24, 24),
			Visible = false,
			TextXAlignment = Enum.TextXAlignment.Right,
		}),
	})
	card.Activated:Connect(function()
		toggle(weapon.id)
	end)
	cards[weapon.id] = card
end

local tabButtons: { [string]: TextButton } = {}
local tabList = { { id = "All", icon = "🌐" } }
for _, entry in WeaponCatalog.CATEGORIES do
	table.insert(tabList, entry)
end
for order, entry in tabList do
	local button = create("TextButton", {
		LayoutOrder = order,
		Size = UDim2.fromOffset(94, 36),
		BackgroundColor3 = PANEL,
		Text = entry.icon .. " " .. entry.id,
		TextColor3 = TEXT,
		TextSize = 13,
		Font = Enum.Font.GothamBold,
		Parent = tabs,
	}, { corner(8) })
	button.Activated:Connect(function()
		category = entry.id
		for id, other in tabButtons do
			other.BackgroundColor3 = if id == category then ACCENT else PANEL
		end
		grid.CanvasPosition = Vector2.zero
		refresh()
	end)
	tabButtons[entry.id] = button
end
tabButtons.All.BackgroundColor3 = ACCENT

for index, slot in slots do
	slot.Activated:Connect(function()
		if selected[index] then
			table.remove(selected, index)
			refresh()
		end
	end)
end

local hiddenByChoice = false

local function updateVisibility()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local inLobby = humanoid ~= nil and humanoid.Health > 0 and not player:GetAttribute("Deployed")
	panel.Visible = inLobby and not hiddenByChoice
	openButton.Visible = inLobby and hiddenByChoice
end

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

function LobbyUI.start()
	gui.Parent = player:WaitForChild("PlayerGui")
	rescale()
	Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
	refresh()
	updateVisibility()

	player:GetAttributeChangedSignal("Deployed"):Connect(function()
		if player:GetAttribute("Deployed") then
			Announcer.show("GO! Run out through any glowing gate!", rgb(120, 255, 140), 4)
		end
		hiddenByChoice = false
		updateVisibility()
	end)
	player:GetPropertyChangedSignal("Team"):Connect(refresh)
	player:GetAttributeChangedSignal("IsAdmin"):Connect(refresh)
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
