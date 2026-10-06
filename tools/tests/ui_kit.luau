-- Checks the client UI kit in src/client/ui outside Roblox.
-- Usage: lune run tools/tests/ui_kit.luau
--
--   - every widget the kit now builds matches the inline code it replaced (copied below from the
--     modules before the kit, Names constants inlined), property by property and child by child:
--     the touch buttons (SCOPE, VIEW, STAND, pod, LAND, ▲, ▼), the right column's toggles and
--     panels, the scope lens and dot, the vehicle health bar, a prompt card, and LobbyUI's panel,
--     buttons, grid and a weapon card
--   - Theme: every DisplayOrder, colour, font and radius equals the literal it replaced, and every
--     client ScreenGui takes its DisplayOrder from Theme
--   - RightColumn's constants equal MacPanel's old ones (PANEL_TOP follows the column's new top);
--     notifyOpened fires `opened`
--   - Hud: jumpButton and shownIn give the golden results generated once from the code at
--     a50e99c, over trees with each piece missing, of the wrong class, hidden or disabled; edgeY
--     and bottomControls give what the inline lookups gave (the bottom-right guis found by name
--     before, listed with addBottomControls now); jumpWatcher hooks a jump button once and lays
--     out on every call
--
-- Not covered: events and layout (Lune instances have no signals or AbsolutePosition). Hud's
-- signal hookup is checked against stand-ins.

local fs = require("@lune/fs")
local roblox = require("@lune/roblox")

local Check = require("../lib/Check")
local Sandbox = require("../lib/Sandbox")

local check, equal = Check.check, Check.equal
local RealInstance = roblox.Instance
local Color3, UDim, UDim2, Vector2, Enum =
	roblox.Color3, roblox.UDim, roblox.UDim2, roblox.Vector2, roblox.Enum
local rgb = Color3.fromRGB

Check.printLimit = 10

-- Lune instances have no events: a BindableEvent stand-in that counts Fire calls.
local fired = 0
local Instance = {
	new = function(className: string): any
		if className == "BindableEvent" then
			return {
				Event = { name = "opened" },
				Fire = function()
					fired += 1
				end,
			}
		end
		return RealInstance.new(className)
	end,
}
Sandbox.globals.Instance = Instance

local Create = Sandbox.require("src/client/ui/Create")
local Theme = Sandbox.require("src/client/ui/Theme")
local TouchButton = Sandbox.require("src/client/ui/TouchButton")
local RightColumn = Sandbox.require("src/client/ui/RightColumn")

-- Every property a client widget sets, read with pcall: a property the class lacks (or Lune holds
-- no default for and nobody set) reads "<none>".
local PROPERTIES = {
	"ClassName",
	"Name",
	"AnchorPoint",
	"Position",
	"Size",
	"BackgroundColor3",
	"BackgroundTransparency",
	"BorderSizePixel",
	"ClipsDescendants",
	"Visible",
	"ZIndex",
	"LayoutOrder",
	"Active",
	"AutoButtonColor",
	"AutomaticSize",
	"Text",
	"TextColor3",
	"TextSize",
	"TextScaled",
	"TextWrapped",
	"TextXAlignment",
	"TextYAlignment",
	"TextTruncate",
	"TextStrokeColor3",
	"TextStrokeTransparency",
	"Font",
	"ScrollBarThickness",
	"CanvasSize",
	"AutomaticCanvasSize",
	"CornerRadius",
	"Color",
	"Thickness",
	"ApplyStrokeMode",
	"Enabled",
	"PaddingLeft",
	"PaddingRight",
	"PaddingTop",
	"PaddingBottom",
	"Padding",
	"MaxSize",
	"CellSize",
	"CellPadding",
	"SortOrder",
	"FillDirection",
	"DisplayOrder",
	"ResetOnSpawn",
	"IgnoreGuiInset",
	"ZIndexBehavior",
}

local function read(instance: any, property: string): any
	local ok, value = pcall(function()
		return instance[property]
	end)
	return if ok then value else "<none>"
end

-- Compares two instance trees: every property (but the root's in `except`), then the children in
-- order.
local function sameTree(got: any, want: any, label: string, except: { [string]: boolean }?)
	for _, property in PROPERTIES do
		if not (except and except[property]) then
			equal(read(got, property), read(want, property), label .. " " .. property)
		end
	end
	local gotChildren, wantChildren = got:GetChildren(), want:GetChildren()
	equal(#gotChildren, #wantChildren, label .. " children")
	for index, child in wantChildren do
		local other = gotChildren[index]
		if other then
			sameTree(other, child, label .. " > " .. child.ClassName .. " " .. index)
		end
	end
end

-- Compares two roots and their parents' names.
local function sameWidget(got: any, want: any, label: string, except: { [string]: boolean }?)
	sameTree(got, want, label, except)
	equal(got.Parent and got.Parent.Name, want.Parent and want.Parent.Name, label .. " parent")
end

local function holder(name: string): any
	local gui = RealInstance.new("ScreenGui")
	gui.Name = name
	return gui
end

-- Before: the inline code (constructor calls word for word; later property sets elided) -----------

local Before = {}

-- AdminPanel, MacPanel and LobbyUI `create` (identical copies).
function Before.create(className: string, properties: { [string]: any }, children: { any }?): any
	local instance = RealInstance.new(className)
	for key, value in properties do
		(instance :: any)[key] = value
	end
	for _, child in (children or {}) :: { any } do
		child.Parent = instance
	end
	return instance
end
local create = Before.create

-- AdminPanel and MacPanel `corner`.
function Before.panelCorner(): any
	return create("UICorner", { CornerRadius = UDim.new(0, 8) })
end

-- LobbyUI `corner` and `label`.
function Before.lobbyCorner(radius: number): any
	return create("UICorner", { CornerRadius = UDim.new(0, radius) })
end
function Before.label(text: string, size: number, color: any, properties: { [string]: any }?): any
	local result = create("TextLabel", {
		BackgroundTransparency = 1,
		Text = text,
		TextSize = size,
		TextColor3 = color,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
	})
	for key, value in (properties or {}) :: { [string]: any } do
		(result :: any)[key] = value
	end
	return result
end

-- SniperScope's SCOPE button.
function Before.scopeButton(buttonGui: any): any
	local button = RealInstance.new("TextButton")
	button.Name = "Scope"
	button.AnchorPoint = Vector2.new(0.5, 1)
	button.BackgroundColor3 = rgb(20, 20, 28)
	button.BackgroundTransparency = 0.25
	button.TextColor3 = rgb(255, 255, 255)
	button.Font = Enum.Font.GothamBold
	button.TextScaled = true
	button.Text = "SCOPE"
	button.Parent = buttonGui
	local buttonCorner = RealInstance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0.5, 0)
	buttonCorner.Parent = button
	local buttonStroke = RealInstance.new("UIStroke")
	buttonStroke.Color = rgb(255, 255, 255)
	buttonStroke.Thickness = 2
	buttonStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	buttonStroke.Parent = button
	local buttonPadding = RealInstance.new("UIPadding")
	buttonPadding.PaddingLeft = UDim.new(0.12, 0)
	buttonPadding.PaddingRight = UDim.new(0.12, 0)
	buttonPadding.PaddingTop = UDim.new(0.3, 0)
	buttonPadding.PaddingBottom = UDim.new(0.3, 0)
	buttonPadding.Parent = button
	return button
end

-- MechCamera `makeButton`.
function Before.mechButton(buttonGui: any, name: string, text: string): any
	local button = RealInstance.new("TextButton")
	button.Name = name
	button.AnchorPoint = Vector2.new(1, 1)
	button.BackgroundColor3 = rgb(20, 20, 28)
	button.BackgroundTransparency = 0.25
	button.TextColor3 = rgb(255, 255, 255)
	button.Font = Enum.Font.GothamBold
	button.TextScaled = true
	button.Text = text
	button.Parent = buttonGui
	local corner = RealInstance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = button
	local stroke = RealInstance.new("UIStroke")
	stroke.Color = rgb(255, 255, 255)
	stroke.Thickness = 2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = button
	local padding = RealInstance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0.12, 0)
	padding.PaddingRight = UDim.new(0.12, 0)
	padding.PaddingTop = UDim.new(0.3, 0)
	padding.PaddingBottom = UDim.new(0.3, 0)
	padding.Parent = button
	return button
end

-- PodControls `makeButton`.
function Before.podButton(gui: any, name: string, text: string, color: any): any
	local button = RealInstance.new("TextButton")
	button.Name = name
	button.AnchorPoint = Vector2.new(1, 1)
	button.BackgroundColor3 = color
	button.BackgroundTransparency = 0.15
	button.TextColor3 = rgb(255, 255, 255)
	button.Font = Enum.Font.GothamBold
	button.TextScaled = true
	button.Text = text
	button.AutoButtonColor = true
	button.Parent = gui
	local corner = RealInstance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = button
	local stroke = RealInstance.new("UIStroke")
	stroke.Color = rgb(120, 245, 255)
	stroke.Thickness = 2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = button
	local padding = RealInstance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0.08, 0)
	padding.PaddingRight = UDim.new(0.08, 0)
	padding.PaddingTop = UDim.new(0.28, 0)
	padding.PaddingBottom = UDim.new(0.28, 0)
	padding.Parent = button
	return button
end

-- SniperScope's lens (its corner and stroke) and reticle dot corner.
function Before.lens(overlayGui: any): any
	local lens = RealInstance.new("Frame")
	lens.Name = "Lens"
	lens.AnchorPoint = Vector2.new(0.5, 0.5)
	lens.Position = UDim2.fromScale(0.5, 0.5)
	lens.BackgroundTransparency = 1
	lens.Parent = overlayGui
	local lensCorner = RealInstance.new("UICorner")
	lensCorner.CornerRadius = UDim.new(0.5, 0)
	lensCorner.Parent = lens
	local lensStroke = RealInstance.new("UIStroke")
	lensStroke.Color = rgb(0, 0, 0)
	lensStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	lensStroke.Parent = lens
	local dot = RealInstance.new("Frame")
	dot.Name = "Dot"
	dot.Parent = lens
	local dotCorner = RealInstance.new("UICorner")
	dotCorner.CornerRadius = UDim.new(0.5, 0)
	dotCorner.Parent = dot
	return lens
end

-- VehicleHealth's bar, fill and label.
function Before.healthBar(gui: any): any
	local frame = RealInstance.new("Frame")
	frame.Name = "Bar"
	frame.AnchorPoint = Vector2.new(0.5, 1)
	frame.Position = UDim2.new(0.5, 0, 1, -100)
	frame.Size = UDim2.fromOffset(260, 22)
	frame.BackgroundColor3 = rgb(20, 20, 28)
	frame.BackgroundTransparency = 0.25
	frame.ClipsDescendants = true
	frame.Parent = gui
	local frameCorner = RealInstance.new("UICorner")
	frameCorner.CornerRadius = UDim.new(0.5, 0)
	frameCorner.Parent = frame
	local stroke = RealInstance.new("UIStroke")
	stroke.Color = rgb(255, 255, 255)
	stroke.Thickness = 2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = frame
	local fill = RealInstance.new("Frame")
	fill.Name = "Fill"
	fill.BorderSizePixel = 0
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = rgb(70, 210, 90)
	fill.Parent = frame
	local fillCorner = RealInstance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0.5, 0)
	fillCorner.Parent = fill
	local label = RealInstance.new("TextLabel")
	label.Name = "Label"
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 14
	label.TextColor3 = rgb(255, 255, 255)
	label.TextStrokeTransparency = 0.4
	label.Parent = frame
	return frame
end

-- PromptPanel's `text` (still inline there, used by both sides) and `makeCard`'s instances.
local function text(name: string, font: any, color: any, parent: any): any
	local label = RealInstance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Font = font
	label.TextColor3 = color
	label.TextScaled = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Parent = parent
	return label
end
function Before.card(gui: any): any
	local function corner(radius: any, parent: any)
		local each = RealInstance.new("UICorner")
		each.CornerRadius = radius
		each.Parent = parent
	end
	local frame = RealInstance.new("TextButton")
	frame.Name = "DrivePrompt"
	frame.AnchorPoint = Vector2.new(1, 0)
	frame.Text = ""
	frame.AutoButtonColor = false
	frame.BackgroundColor3 = rgb(20, 20, 28)
	frame.BackgroundTransparency = 0.25
	frame.ClipsDescendants = true
	frame.Parent = gui
	corner(UDim.new(0, 8), frame)
	local stroke = RealInstance.new("UIStroke")
	stroke.Color = rgb(255, 255, 255)
	stroke.Thickness = 2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = frame
	local badge = RealInstance.new("Frame")
	badge.Name = "Badge"
	badge.AnchorPoint = Vector2.new(0, 0.5)
	badge.BackgroundColor3 = rgb(255, 255, 255)
	badge.Parent = frame
	corner(UDim.new(0.2, 0), badge)
	text("Key", Enum.Font.GothamBold, rgb(20, 20, 28), badge)
	local texts = RealInstance.new("Frame")
	texts.Name = "Texts"
	texts.BackgroundTransparency = 1
	texts.Parent = frame
	text("Object", Enum.Font.Gotham, rgb(200, 200, 215), texts)
	text("Action", Enum.Font.GothamBold, rgb(255, 255, 255), texts)
	local progress = RealInstance.new("Frame")
	progress.Name = "Progress"
	progress.BorderSizePixel = 0
	progress.BackgroundColor3 = rgb(120, 245, 255)
	progress.Parent = frame
	return frame
end

-- MacPanel's toggle and panel; AdminPanel's toggle and panel (MacPanel.* constants inlined).
function Before.macToggle(gui: any): any
	return create("TextButton", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 60 + 40 + 6),
		Size = UDim2.fromOffset(130, 40),
		TextSize = 16,
		Font = Enum.Font.LuckiestGuy,
		Parent = gui,
	}, { Before.panelCorner() })
end
function Before.macPanel(gui: any): any
	return create("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 152),
		Size = UDim2.fromOffset(300, 142),
		BackgroundColor3 = rgb(10, 18, 24),
		BackgroundTransparency = 0.1,
		Visible = false,
		Parent = gui,
	}, {
		Before.panelCorner(),
		create("UIStroke", { Color = rgb(80, 190, 255), Thickness = 2 }),
	})
end
function Before.adminToggle(gui: any): any
	return create("TextButton", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 60),
		Size = UDim2.fromOffset(130, 40),
		BackgroundColor3 = rgb(255, 200, 40),
		Text = "👑 GOD MODE",
		TextColor3 = rgb(40, 20, 0),
		TextSize = 16,
		Font = Enum.Font.LuckiestGuy,
		Parent = gui,
	}, { Before.panelCorner() })
end
function Before.adminPanel(gui: any): any
	return create("ScrollingFrame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 152),
		Size = UDim2.new(0, 300, 1, -(152 + 12)),
		BackgroundColor3 = rgb(20, 16, 10),
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		CanvasSize = UDim2.new(),
		Visible = false,
		Parent = gui,
	}, {
		Before.panelCorner(),
		create("UIStroke", { Color = rgb(255, 200, 40), Thickness = 2 }),
		create("UISizeConstraint", { MaxSize = Vector2.new(300, 470) }),
	})
end

-- LobbyUI's colours.
local ACCENT, GOLD, TEXT, MUTED, PANEL =
	rgb(255, 60, 100), rgb(255, 210, 60), rgb(240, 240, 250), rgb(160, 160, 185), rgb(32, 32, 48)
local WEAPON = {
	name = "Laser Pistol",
	color = rgb(255, 40, 40),
	description = "Pew pew.",
	kindLabel = "Gun",
	speed = "fast",
}

-- LobbyUI: the panel, title, open button, grid, deploy button and a weapon card.
function Before.lobby(gui: any): any
	local corner, label = Before.lobbyCorner, Before.label
	local panel = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(1060, 660),
		BackgroundColor3 = rgb(18, 18, 28),
		BackgroundTransparency = 0.08,
		Parent = gui,
	}, {
		corner(18),
		create("UIStroke", { Color = ACCENT, Thickness = 3 }),
	})
	label("CHOOSE YOUR WEAPONS", 34, TEXT, {
		Font = Enum.Font.LuckiestGuy,
		Position = UDim2.fromOffset(24, 14),
		Size = UDim2.fromOffset(600, 40),
		Parent = panel,
	})
	create("TextButton", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -110),
		Size = UDim2.fromOffset(240, 54),
		BackgroundColor3 = ACCENT,
		Text = "🔫 CHOOSE WEAPONS",
		TextColor3 = TEXT,
		TextSize = 20,
		Font = Enum.Font.LuckiestGuy,
		Visible = false,
		Parent = panel,
	}, {
		corner(14),
		create(
			"UIStroke",
			{ Color = TEXT, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }
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
	create("TextButton", {
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
		Parent = panel,
	}, {
		corner(14),
		create(
			"UIStroke",
			{ Color = TEXT, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }
		),
	})
	create("TextButton", {
		LayoutOrder = 3,
		BackgroundColor3 = rgb(110, 90, 70):Lerp(rgb(0, 0, 0), 0.55),
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
			BackgroundColor3 = WEAPON.color,
			BorderSizePixel = 0,
		}, { corner(7) }),
		label(WEAPON.name, 15, TEXT, {
			Position = UDim2.fromOffset(28, 6),
			Size = UDim2.fromOffset(130, 22),
			TextTruncate = Enum.TextTruncate.AtEnd,
		}),
		label(WEAPON.kindLabel .. " · " .. WEAPON.speed, 12, GOLD, {
			Position = UDim2.fromOffset(8, 30),
			Size = UDim2.fromOffset(150, 16),
		}),
		label(WEAPON.description, 12, MUTED, {
			Position = UDim2.fromOffset(8, 48),
			Size = UDim2.fromOffset(150, 44),
			Font = Enum.Font.Gotham,
			TextYAlignment = Enum.TextYAlignment.Top,
		}),
		label("✔", 22, GOLD, {
			Name = "Check",
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -6, 0, 2),
			Size = UDim2.fromOffset(24, 24),
			Visible = false,
			TextXAlignment = Enum.TextXAlignment.Right,
		}),
	})
	return panel
end

-- Now: the callers' code with the kit, copied from each module ------------------------------

local Now = {}

function Now.scopeButton(buttonGui: any): any
	return TouchButton.new({
		name = "Scope",
		text = "SCOPE",
		parent = buttonGui,
		anchor = Vector2.new(0.5, 1),
		color = Theme.Colors.hud,
		transparency = Theme.HUD_TRANSPARENCY,
		strokeColor = Theme.Colors.white,
		paddingX = 0.12,
		paddingY = 0.3,
	})
end

function Now.mechButton(buttonGui: any, name: string, label: string): any
	return TouchButton.new({
		name = name,
		text = label,
		parent = buttonGui,
		anchor = Vector2.new(1, 1),
		color = Theme.Colors.hud,
		transparency = Theme.HUD_TRANSPARENCY,
		strokeColor = Theme.Colors.white,
		paddingX = 0.12,
		paddingY = 0.3,
	})
end

function Now.podButton(gui: any, name: string, label: string, color: any): any
	return TouchButton.new({
		name = name,
		text = label,
		parent = gui,
		anchor = Vector2.new(1, 1),
		color = color,
		transparency = 0.15,
		strokeColor = Theme.Colors.cyan,
		paddingX = 0.08,
		paddingY = 0.28,
		autoButtonColor = true,
	})
end

function Now.lens(overlayGui: any): any
	local lens = RealInstance.new("Frame")
	lens.Name = "Lens"
	lens.AnchorPoint = Vector2.new(0.5, 0.5)
	lens.Position = UDim2.fromScale(0.5, 0.5)
	lens.BackgroundTransparency = 1
	lens.Parent = overlayGui
	Create.corner(Theme.Radius.round).Parent = lens
	local lensStroke = Create.stroke(rgb(0, 0, 0), nil, Enum.ApplyStrokeMode.Border)
	lensStroke.Parent = lens
	local dot = RealInstance.new("Frame")
	dot.Name = "Dot"
	dot.Parent = lens
	Create.corner(Theme.Radius.round).Parent = dot
	return lens
end

function Now.healthBar(gui: any): any
	local frame = RealInstance.new("Frame")
	frame.Name = "Bar"
	frame.AnchorPoint = Vector2.new(0.5, 1)
	frame.Position = UDim2.new(0.5, 0, 1, -100)
	frame.Size = UDim2.fromOffset(260, 22)
	frame.BackgroundColor3 = Theme.Colors.hud
	frame.BackgroundTransparency = Theme.HUD_TRANSPARENCY
	frame.ClipsDescendants = true
	frame.Parent = gui
	Create.corner(Theme.Radius.round).Parent = frame
	Create.stroke(Theme.Colors.white, 2, Enum.ApplyStrokeMode.Border).Parent = frame
	local fill = RealInstance.new("Frame")
	fill.Name = "Fill"
	fill.BorderSizePixel = 0
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = rgb(70, 210, 90)
	fill.Parent = frame
	Create.corner(Theme.Radius.round).Parent = fill
	local label = RealInstance.new("TextLabel")
	label.Name = "Label"
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Theme.Fonts.bold
	label.TextSize = 14
	label.TextColor3 = rgb(255, 255, 255)
	label.TextStrokeTransparency = 0.4
	label.Parent = frame
	return frame
end

function Now.card(gui: any): any
	local frame = RealInstance.new("TextButton")
	frame.Name = "DrivePrompt"
	frame.AnchorPoint = Vector2.new(1, 0)
	frame.Text = ""
	frame.AutoButtonColor = false
	frame.BackgroundColor3 = Theme.Colors.hud
	frame.BackgroundTransparency = Theme.HUD_TRANSPARENCY
	frame.ClipsDescendants = true
	frame.Parent = gui
	Create.corner(Theme.Radius.panel).Parent = frame
	Create.stroke(Theme.Colors.white, 2, Enum.ApplyStrokeMode.Border).Parent = frame
	local badge = RealInstance.new("Frame")
	badge.Name = "Badge"
	badge.AnchorPoint = Vector2.new(0, 0.5)
	badge.BackgroundColor3 = Theme.Colors.white
	badge.Parent = frame
	Create.corner(UDim.new(0.2, 0)).Parent = badge
	text("Key", Theme.Fonts.bold, Theme.Colors.hud, badge)
	local texts = RealInstance.new("Frame")
	texts.Name = "Texts"
	texts.BackgroundTransparency = 1
	texts.Parent = frame
	text("Object", Theme.Fonts.regular, rgb(200, 200, 215), texts)
	text("Action", Theme.Fonts.bold, Theme.Colors.white, texts)
	local progress = RealInstance.new("Frame")
	progress.Name = "Progress"
	progress.BorderSizePixel = 0
	progress.BackgroundColor3 = Theme.Colors.cyan
	progress.Parent = frame
	return frame
end

function Now.macToggle(gui: any): any
	return RightColumn.makeToggle(gui, 1, {})
end
function Now.macPanel(gui: any): any
	return RightColumn.makePanel("Frame", gui, rgb(80, 190, 255), {
		Size = UDim2.fromOffset(RightColumn.PANEL_WIDTH, 142),
		BackgroundColor3 = rgb(10, 18, 24),
	})
end
function Now.adminToggle(gui: any): any
	return RightColumn.makeToggle(gui, 0, {
		BackgroundColor3 = rgb(255, 200, 40),
		Text = "👑 GOD MODE",
		TextColor3 = rgb(40, 20, 0),
	})
end
function Now.adminPanel(gui: any): any
	local width = RightColumn.PANEL_WIDTH
	return RightColumn.makePanel("ScrollingFrame", gui, rgb(255, 200, 40), {
		Size = RightColumn.fullHeight(width),
		BackgroundColor3 = rgb(20, 16, 10),
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		CanvasSize = UDim2.new(),
	}, {
		Create.create("UISizeConstraint", { MaxSize = Vector2.new(width, 470) }),
	})
end

function Now.lobby(gui: any): any
	local make, label = Create.create, Create.label
	local function corner(radius: number): any
		return Create.corner(UDim.new(0, radius))
	end
	local panel = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(1060, 660),
		BackgroundColor3 = rgb(18, 18, 28),
		BackgroundTransparency = 0.08,
		Parent = gui,
	}, {
		corner(18),
		Create.stroke(ACCENT, 3),
	})
	label("CHOOSE YOUR WEAPONS", 34, TEXT, {
		Font = Theme.Fonts.title,
		Position = UDim2.fromOffset(24, 14),
		Size = UDim2.fromOffset(600, 40),
		Parent = panel,
	})
	make("TextButton", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -110),
		Size = UDim2.fromOffset(240, 54),
		BackgroundColor3 = ACCENT,
		Text = "🔫 CHOOSE WEAPONS",
		TextColor3 = TEXT,
		TextSize = 20,
		Font = Theme.Fonts.title,
		Visible = false,
		Parent = panel,
	}, {
		corner(14),
		Create.stroke(TEXT, 2, Enum.ApplyStrokeMode.Border),
	})
	local grid = make("ScrollingFrame", {
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
		make("UIGridLayout", {
			CellSize = UDim2.fromOffset(164, 112),
			CellPadding = UDim2.fromOffset(8, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		Create.padding(UDim.new(0, 8), UDim.new(0, 8)),
	})
	make("TextButton", {
		Position = UDim2.fromOffset(0, 452),
		Size = UDim2.fromOffset(304, 96),
		BackgroundColor3 = ACCENT,
		Text = "ENTER THE MAYHEM",
		TextColor3 = TEXT,
		TextStrokeColor3 = rgb(40, 0, 10),
		TextStrokeTransparency = 0.3,
		TextSize = 30,
		Font = Theme.Fonts.title,
		TextWrapped = true,
		Parent = panel,
	}, {
		corner(14),
		Create.stroke(TEXT, 2, Enum.ApplyStrokeMode.Border),
	})
	make("TextButton", {
		LayoutOrder = 3,
		BackgroundColor3 = rgb(110, 90, 70):Lerp(rgb(0, 0, 0), 0.55),
		Text = "",
		AutoButtonColor = true,
		Parent = grid,
	}, {
		corner(10),
		make("UIStroke", {
			Name = "Selected",
			Color = GOLD,
			Thickness = 3,
			Enabled = false,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}),
		make("Frame", {
			Size = UDim2.fromOffset(14, 14),
			Position = UDim2.fromOffset(8, 10),
			BackgroundColor3 = WEAPON.color,
			BorderSizePixel = 0,
		}, { corner(7) }),
		label(WEAPON.name, 15, TEXT, {
			Position = UDim2.fromOffset(28, 6),
			Size = UDim2.fromOffset(130, 22),
			TextTruncate = Enum.TextTruncate.AtEnd,
		}),
		label(WEAPON.kindLabel .. " · " .. WEAPON.speed, 12, GOLD, {
			Position = UDim2.fromOffset(8, 30),
			Size = UDim2.fromOffset(150, 16),
		}),
		label(WEAPON.description, 12, MUTED, {
			Position = UDim2.fromOffset(8, 48),
			Size = UDim2.fromOffset(150, 44),
			Font = Theme.Fonts.regular,
			TextYAlignment = Enum.TextYAlignment.Top,
		}),
		label("✔", 22, GOLD, {
			Name = "Check",
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -6, 0, 2),
			Size = UDim2.fromOffset(24, 24),
			Visible = false,
			TextXAlignment = Enum.TextXAlignment.Right,
		}),
	})
	return panel
end

-- Widgets -------------------------------------------------------------------------------------

Check.section("touch buttons")
sameWidget(Now.scopeButton(holder("A")), Before.scopeButton(holder("A")), "SCOPE")
for _, each in { { "View", "VIEW" }, { "Stand", "STAND" } } do
	sameWidget(
		Now.mechButton(holder("A"), each[1], each[2]),
		Before.mechButton(holder("A"), each[1], each[2]),
		each[2]
	)
end
for _, each in
	{
		{ "Pod", "LAUNCH", rgb(0, 120, 170), rgb(0, 120, 170) },
		{ "Up", "▲", Theme.Colors.hud, rgb(20, 20, 28) },
		{ "Down", "▼", Theme.Colors.hud, rgb(20, 20, 28) },
		{ "Land", "LAND", rgb(20, 130, 70), rgb(20, 130, 70) },
	}
do
	sameWidget(
		Now.podButton(holder("A"), each[1], each[2], each[3]),
		Before.podButton(holder("A"), each[1], each[2], each[4]),
		each[1]
	)
end

Check.section("scope lens, health bar, prompt card")
sameWidget(Now.lens(holder("A")), Before.lens(holder("A")), "lens")
sameWidget(Now.healthBar(holder("A")), Before.healthBar(holder("A")), "health bar")
sameWidget(Now.card(holder("A")), Before.card(holder("A")), "prompt card")

Check.section("right column")
-- The column's top moved from a guessed 60 below the top bar to MARGIN (12) below it, where the
-- ScreenGui's CoreUISafeInsets area starts (HudLayout.columnToggle): everything else matches the
-- code before; the positions and the GOD MODE panel's height are golden values.
local panelsBefore = #RightColumn.panels
local PLACED = { Position = true, Size = true }
local macToggle = Now.macToggle(holder("Mac"))
sameWidget(macToggle, Before.macToggle(holder("Mac")), "MAC toggle", PLACED)
local macPanel = Now.macPanel(holder("Mac"))
sameWidget(macPanel, Before.macPanel(holder("Mac")), "MAC panel", PLACED)
local adminToggle = Now.adminToggle(holder("Admin"))
sameWidget(adminToggle, Before.adminToggle(holder("Admin")), "GOD toggle", PLACED)
local adminPanel = Now.adminPanel(holder("Admin"))
sameWidget(adminPanel, Before.adminPanel(holder("Admin")), "GOD MODE panel", PLACED)
equal(adminToggle.Position, UDim2.new(1, -12, 0, 12), "GOD toggle position")
equal(macToggle.Position, UDim2.new(1, -12, 0, 58), "MAC toggle position")
equal(macPanel.Position, UDim2.new(1, -12, 0, 104), "MAC panel position")
equal(adminPanel.Position, UDim2.new(1, -12, 0, 104), "GOD MODE panel position")
for _, each in { { macToggle, "MAC toggle" }, { adminToggle, "GOD toggle" } } do
	equal(each[1].Size, UDim2.fromOffset(130, 40), each[2] .. " size")
end
equal(macPanel.Size, UDim2.fromOffset(300, 142), "MAC panel size")
equal(adminPanel.Size, UDim2.new(0, 300, 1, -116), "GOD MODE panel fills the column")
equal(#RightColumn.panels, panelsBefore + 2, "makePanel lists each panel")
check(RightColumn.panels[panelsBefore + 1] == macPanel, "MAC panel listed first")
check(RightColumn.panels[panelsBefore + 2] == adminPanel, "GOD MODE panel listed second")
sameTree(Create.corner(Theme.Radius.panel), Before.panelCorner(), "panel corner")
equal(RightColumn.TOGGLE_HEIGHT, 40, "TOGGLE_HEIGHT")
equal(RightColumn.TOGGLE_WIDTH, 130, "TOGGLE_WIDTH")
equal(RightColumn.GAP, 6, "GAP")
equal(RightColumn.PANEL_TOP, 104, "PANEL_TOP")
equal(RightColumn.PANEL_WIDTH, 300, "PANEL_WIDTH")
equal(RightColumn.MARGIN, 12, "MARGIN")
equal(RightColumn.opened.name, "opened", "opened is the BindableEvent's Event")
RightColumn.notifyOpened()
equal(fired, 1, "notifyOpened fires opened")

Check.section("lobby")
sameWidget(Now.lobby(holder("MayhemLobby")), Before.lobby(holder("MayhemLobby")), "lobby")
for _, properties in
	{
		{},
		{ Font = Enum.Font.LuckiestGuy, Name = "Title", Visible = false },
		{ TextWrapped = false, TextXAlignment = Enum.TextXAlignment.Right },
	}
do
	sameTree(
		Create.label("x", 12, GOLD, properties),
		Before.label("x", 12, GOLD, properties),
		"label"
	)
end

-- Theme ---------------------------------------------------------------------------------------

Check.section("theme")
local ORDERS = {
	scope = 5,
	vehicleBar = 5,
	touch = 6,
	lobby = 10,
	prompts = 14,
	panels = 15,
	announcer = 20,
}
for key, value in ORDERS do
	equal(Theme.DisplayOrder[key], value, "DisplayOrder." .. key)
end
for key in Theme.DisplayOrder do
	check(ORDERS[key] ~= nil, "DisplayOrder." .. key .. " is pinned here")
end
-- Each client ScreenGui and the layer it takes (the literal it had before is ORDERS[layer]).
local GUIS = {
	{ file = "SniperScope", layer = "scope" },
	{ file = "VehicleHealth", layer = "vehicleBar" },
	{ file = "SniperScope", layer = "touch" },
	{ file = "MechCamera", layer = "touch" },
	{ file = "PodControls", layer = "touch" },
	{ file = "LobbyUI", layer = "lobby" },
	{ file = "PromptPanel", layer = "prompts" },
	{ file = "AdminPanel", layer = "panels" },
	{ file = "MacPanel", layer = "panels" },
	{ file = "Announcer", layer = "announcer" },
}
for _, gui in GUIS do
	local source = fs.readFile(Sandbox.ROOT .. "/src/client/" .. gui.file .. ".luau")
	check(
		string.find(source, "DisplayOrder = Theme.DisplayOrder." .. gui.layer, 1, true) ~= nil,
		gui.file .. " uses Theme.DisplayOrder." .. gui.layer
	)
end
for _, file in fs.readDir(Sandbox.ROOT .. "/src/client") do
	if string.match(file, "%.luau$") then
		local source = fs.readFile(Sandbox.ROOT .. "/src/client/" .. file)
		check(
			string.find(source, "DisplayOrder%s*=%s*%d") == nil,
			file .. " sets no DisplayOrder literal"
		)
	end
end
equal(Theme.Colors.hud, rgb(20, 20, 28), "hud colour")
equal(Theme.Colors.white, rgb(255, 255, 255), "white")
equal(Theme.Colors.cyan, rgb(120, 245, 255), "cyan")
equal(Theme.HUD_TRANSPARENCY, 0.25, "hud transparency")
equal(Theme.Fonts.title, Enum.Font.LuckiestGuy, "title font")
equal(Theme.Fonts.bold, Enum.Font.GothamBold, "bold font")
equal(Theme.Fonts.regular, Enum.Font.Gotham, "regular font")
equal(Theme.Radius.round, UDim.new(0.5, 0), "round radius")
equal(Theme.Radius.panel, UDim.new(0, 8), "panel radius")

-- Hud -----------------------------------------------------------------------------------------

Check.section("hud lookups")
local player = RealInstance.new("Player")
local fakeGame = {
	GetService = function(_, name: string): any
		if name == "Players" then
			return { LocalPlayer = player }
		elseif name == "GuiService" then
			return {
				GetGuiInset = function()
					return Vector2.new(0, 36), Vector2.zero
				end,
			}
		end
		error("no service " .. name)
	end,
}
local Hud = Sandbox.load("src/client/ui/Hud.luau", { game = fakeGame })

-- PromptPanel's bottom-control lookup before the registry, word for word (Names constants
-- inlined). Its shownIn was Hud.shownIn word for word; SHOWN_OBJECTS below pins that.
local function oldBottomControls(): { any }
	local found = {}
	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	if not playerGui then
		return found
	end
	local touchGui = playerGui:FindFirstChild("TouchGui")
	local touchFrame = touchGui and touchGui:FindFirstChild("TouchControlFrame")
	local jump = touchFrame and touchFrame:FindFirstChild("JumpButton")
	if jump and jump:IsA("GuiObject") and Hud.shownIn(jump) then
		table.insert(found, jump)
	end
	for _, name in { "MechButtons", "PodButtons", "SniperScopeButton" } do
		local each = playerGui:FindFirstChild(name)
		if each and each:IsA("ScreenGui") and each.Enabled then
			for _, child in each:GetChildren() do
				if child:IsA("GuiObject") and child.Visible then
					table.insert(found, child)
				end
			end
		end
	end
	return found
end

local function sameSet(got: { any }, want: { any }, label: string)
	equal(#got, #want, label .. " count")
	for _, each in want do
		check(table.find(got, each) ~= nil, label .. " has " .. each.Name)
	end
end

-- The bottom-right guis, listed with Hud as MechCamera, PodControls and SniperScope list them,
-- with a visible and a hidden button each.
local bottomGuis = {}
for _, name in { "MechButtons", "PodButtons", "SniperScopeButton" } do
	local gui = RealInstance.new("ScreenGui")
	gui.Name = name
	for _, visible in { true, false } do
		local button = RealInstance.new("TextButton")
		button.Name = name .. (if visible then "Shown" else "Hidden")
		button.Visible = visible
		button.Parent = gui
	end
	Hud.addBottomControls(gui)
	table.insert(bottomGuis, gui)
end

-- Golden results of Hud.jumpButton and Hud.shownIn, generated once from the code at a50e99c:
-- they pin their behaviour. A deliberate change updates the third entry of each case.
local function new(className: string, name: string, parent: any?): any
	local each = RealInstance.new(className)
	each.Name = name
	each.Parent = parent
	return each
end
-- { label, PlayerGui tree (nil: none), the path below PlayerGui jumpButton returns (false: nil) }
local JUMP_TREES = {
	{
		"no PlayerGui",
		function()
			return nil
		end,
		false,
	},
	{
		"no TouchGui",
		function()
			local gui = new("PlayerGui", "PlayerGui")
			new("ScreenGui", "OtherGui", gui)
			return gui
		end,
		false,
	},
	{
		"no TouchControlFrame",
		function()
			local gui = new("PlayerGui", "PlayerGui")
			new("Frame", "OtherFrame", new("ScreenGui", "TouchGui", gui))
			return gui
		end,
		false,
	},
	{
		"no JumpButton",
		function()
			local gui = new("PlayerGui", "PlayerGui")
			local frame = new("Frame", "TouchControlFrame", new("ScreenGui", "TouchGui", gui))
			new("ImageButton", "ThumbstickFrame", frame)
			return gui
		end,
		false,
	},
	{
		"JumpButton a Folder",
		function()
			local gui = new("PlayerGui", "PlayerGui")
			local frame = new("Frame", "TouchControlFrame", new("ScreenGui", "TouchGui", gui))
			new("Folder", "JumpButton", frame)
			return gui
		end,
		false,
	},
	{
		"JumpButton a Frame",
		function()
			local gui = new("PlayerGui", "PlayerGui")
			local frame = new("Frame", "TouchControlFrame", new("ScreenGui", "TouchGui", gui))
			new("Frame", "JumpButton", frame)
			return gui
		end,
		"TouchGui.TouchControlFrame.JumpButton",
	},
	{
		"JumpButton an ImageButton",
		function()
			local gui = new("PlayerGui", "PlayerGui")
			local frame = new("Frame", "TouchControlFrame", new("ScreenGui", "TouchGui", gui))
			new("ImageButton", "JumpButton", frame)
			return gui
		end,
		"TouchGui.TouchControlFrame.JumpButton",
	},
	{
		"JumpButton hidden in a disabled TouchGui",
		function()
			local gui = new("PlayerGui", "PlayerGui")
			local touch = new("ScreenGui", "TouchGui", gui)
			touch.Enabled = false
			local jump = new("ImageButton", "JumpButton", new("Frame", "TouchControlFrame", touch))
			jump.Visible = false
			return gui
		end,
		"TouchGui.TouchControlFrame.JumpButton",
	},
	{
		"TouchGui a Folder",
		function()
			local gui = new("PlayerGui", "PlayerGui")
			local frame = new("Frame", "TouchControlFrame", new("Folder", "TouchGui", gui))
			new("ImageButton", "JumpButton", frame)
			return gui
		end,
		"TouchGui.TouchControlFrame.JumpButton",
	},
	{
		"JumpButton one level deeper",
		function()
			local gui = new("PlayerGui", "PlayerGui")
			local frame = new("Frame", "TouchControlFrame", new("ScreenGui", "TouchGui", gui))
			new("ImageButton", "JumpButton", new("Frame", "Inner", frame))
			return gui
		end,
		false,
	},
}
for _, case in JUMP_TREES do
	local label, tree, want = case[1], case[2](), case[3]
	if tree then
		tree.Parent = player
	end
	local got = Hud.jumpButton()
	equal(
		if got then string.gsub(got:GetFullName(), "^Player%.PlayerGui%.", "") else false,
		want,
		"jumpButton, " .. label
	)
	if tree then
		tree.Parent = nil
	end
end

-- { label, the object asked about, shownIn }
local SHOWN_OBJECTS = {}
for _, visible in { true, false } do
	local function object(parent: any): any
		local button = new("TextButton", "Button", parent)
		button.Visible = visible
		return button
	end
	local function disabled(gui: any): any
		gui.Enabled = false
		return gui
	end
	local shown = if visible then "visible" else "hidden"
	for _, case in
		{
			{ "no ScreenGui", new("Frame", "Holder"), false },
			{ "enabled ScreenGui", new("ScreenGui", "Gui"), visible },
			{ "disabled ScreenGui", disabled(new("ScreenGui", "Gui")), false },
			{
				"enabled ScreenGui two levels up",
				new("Frame", "Inner", new("Frame", "Outer", new("ScreenGui", "Gui"))),
				visible,
			},
			{
				"disabled ScreenGui inside an enabled one",
				disabled(new("ScreenGui", "Inner", new("ScreenGui", "Outer"))),
				false,
			},
			{
				"enabled ScreenGui inside a disabled one",
				new("ScreenGui", "Inner", disabled(new("ScreenGui", "Outer"))),
				visible,
			},
		}
	do
		table.insert(SHOWN_OBJECTS, { shown .. ", " .. case[1], object(case[2]), case[3] })
	end
end
for _, case in SHOWN_OBJECTS do
	equal(Hud.shownIn(case[2]), case[3], "shownIn, " .. case[1])
end

equal(Hud.jumpButton(), nil, "no PlayerGui: no jump button")
sameSet(Hud.bottomControls(), oldBottomControls(), "no PlayerGui")

local playerGui = RealInstance.new("PlayerGui")
playerGui.Parent = player
local touchGui = RealInstance.new("ScreenGui")
touchGui.Name = "TouchGui"
local touchFrame = RealInstance.new("Frame")
touchFrame.Name = "TouchControlFrame"
touchFrame.Parent = touchGui
local jump = RealInstance.new("ImageButton")
jump.Name = "JumpButton"
jump.Parent = touchFrame

-- Golden results per touch state, generated once from the code at a50e99c: whether jumpButton
-- returns `jump` (else nil) and shownIn(jump).
local JUMP_BY_TOUCH = { none = false, hidden = true, disabled = true, shown = true }
local SHOWN_BY_TOUCH = { none = true, hidden = false, disabled = false, shown = true }
local scenarios = 0
for _, touch in { "none", "hidden", "disabled", "shown" } do
	touchGui.Parent = if touch == "none" then nil else playerGui
	touchGui.Enabled = touch ~= "disabled"
	jump.Visible = touch ~= "hidden"
	for mask = 0, 63 do
		-- Two bits per gui: parented to PlayerGui, Enabled.
		for index, gui in bottomGuis do
			local bits = bit32.extract(mask, (index - 1) * 2, 2)
			gui.Parent = if bit32.btest(bits, 1) then playerGui else nil
			gui.Enabled = bit32.btest(bits, 2)
		end
		local label = string.format("touch %s guis %d", touch, mask)
		equal(Hud.jumpButton(), if JUMP_BY_TOUCH[touch] then jump else nil, label .. " jumpButton")
		sameSet(Hud.bottomControls(), oldBottomControls(), label)
		equal(Hud.shownIn(jump), SHOWN_BY_TOUCH[touch], label .. " shownIn")
		scenarios += 1
	end
end
equal(scenarios, 256, "hud scenarios")

-- A gui of the same name that nobody listed is not a bottom control (the name no longer counts).
for _, gui in bottomGuis do
	gui.Parent = nil
end
local stray = RealInstance.new("ScreenGui")
stray.Name = "MechButtons"
local strayButton = RealInstance.new("TextButton")
strayButton.Parent = stray
stray.Parent = playerGui
check(table.find(Hud.bottomControls(), strayButton) == nil, "an unlisted gui is ignored")
stray.Parent = nil

-- Stand-in GuiObjects (Lune has no AbsolutePosition) for the measured functions.
Check.section("hud measuring")
local function standIn(ignoreInset: boolean?, x: number, y: number, width: number, height: number)
	local owner = if ignoreInset == nil
		then nil
		else { IgnoreGuiInset = ignoreInset, Enabled = true }
	return {
		AbsolutePosition = Vector2.new(x, y),
		AbsoluteSize = Vector2.new(width, height),
		Visible = true,
		FindFirstAncestorOfClass = function(_, className: string)
			return if className == "ScreenGui" then owner else nil
		end,
	}
end
-- PromptPanel `edgeY` before Hud, word for word (`gui` passed in; GuiService's inset is 36).
local function oldEdgeY(object: any, bottom: boolean, gui: any): number
	local y = object.AbsolutePosition.Y + (if bottom then object.AbsoluteSize.Y else 0)
	local owner = object:FindFirstAncestorOfClass("ScreenGui")
	if owner and owner.IgnoreGuiInset ~= gui.IgnoreGuiInset then
		local inset = 36
		y += if owner.IgnoreGuiInset then -inset else inset
	end
	return y
end
for _, ownerInset in { true, false, nil } do
	for _, spaceInset in { true, false } do
		for _, bottom in { true, false } do
			local object = standIn(ownerInset, 17.5, 403.25, 90, 72.5)
			local space = { IgnoreGuiInset = spaceInset }
			equal(
				Hud.edgeY(object, bottom, space),
				oldEdgeY(object, bottom, space),
				string.format(
					"edgeY %s %s %s",
					tostring(ownerInset),
					tostring(spaceInset),
					tostring(bottom)
				)
			)
		end
	end
end
-- matchInset copies ScreenInsets, which carries every inset mode (the IgnoreGuiInset boolean
-- covers only two of the four) and sets IgnoreGuiInset to match in Roblox.
for _, insets in { "none", unpack(Enum.ScreenInsets:GetEnumItems()) } do
	local object = standIn(false, 0, 0, 1, 1)
	local owner = object:FindFirstAncestorOfClass("ScreenGui")
	if insets == "none" then
		object = standIn(nil, 0, 0, 1, 1)
	else
		owner.ScreenInsets = insets
	end
	local gui = { ScreenInsets = "unset", IgnoreGuiInset = "unset" }
	Hud.matchInset(gui, object)
	equal(
		gui.ScreenInsets,
		if insets == "none" then "unset" else insets,
		"matchInset " .. tostring(insets)
	)
	equal(gui.IgnoreGuiInset, "unset", "matchInset leaves IgnoreGuiInset to the engine")
end

-- jumpWatcher: a Hud whose player finds a stand-in jump button with countable signals.
local connects = 0
local currentJump: any = nil
local function signalJump(): any
	return {
		IsA = function(_, className: string)
			return className == "GuiObject"
		end,
		GetPropertyChangedSignal = function(_, property: string)
			return {
				Connect = function()
					connects += 1
					check(
						property == "AbsolutePosition" or property == "AbsoluteSize",
						"watched " .. property
					)
				end,
			}
		end,
	}
end
local fakePlayer = {}
fakePlayer.FindFirstChildOfClass = function()
	return {
		FindFirstChild = function()
			return {
				FindFirstChild = function()
					return {
						FindFirstChild = function()
							return currentJump
						end,
					}
				end,
			}
		end,
	}
end
local watchGame = {
	GetService = function(_, name: string): any
		if name == "Players" then
			return { LocalPlayer = fakePlayer }
		end
		return {}
	end,
}
local WatchHud = Sandbox.load("src/client/ui/Hud.luau", { game = watchGame })
local layouts = 0
local watch = WatchHud.jumpWatcher(function()
	layouts += 1
end)
watch()
equal(connects, 0, "no jump button: nothing hooked")
equal(layouts, 1, "no jump button: laid out")
currentJump = signalJump()
watch()
watch()
equal(connects, 2, "one jump button: hooked once (position and size)")
equal(layouts, 3, "laid out on every call")
currentJump = signalJump()
watch()
equal(connects, 4, "a new jump button: hooked again")

Check.finish()
