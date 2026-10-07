-- The system rail in the top-right corner: the GOD MODE toggle (AdminPanel) above the MAC toggle
-- (MacPanel), and the drawer each opens to their left, one open at a time. On a small screen the
-- toggles are square icons under the vehicle status; on a large one they are full-width labelled
-- buttons in the corner, with the status left of them (HudLayout's zones).
--
--   makeToggle(gui, slot, properties)   a toggle in slot 0 (GOD MODE) or 1 (MAC), parented to
--                                       `gui`; toggles stack in slot order with no gap for a
--                                       missing one
--   setLabels(toggle, small, large)     the toggle's text for each size class
--   makePanel(className, gui, accent, properties, children?, fill?)
--                                       a hidden drawer panel, outlined in `accent`, parented to
--                                       `gui` and listed in `panels`; `fill` sizes it to the
--                                       drawer's height
--   layoutIn(area)                      places every toggle and panel for a gui area
--   watch(gui)                          lays the rail out now and whenever `gui` resizes
--   panels      every panel in the rail, open or not
--   opened      fires when the MAC panel opens (notifyOpened), so GOD MODE's closes
--
-- Placement: the rail's ScreenGuis use ScreenInsets CoreUISafeInsets (SCREEN_INSETS): the engine
-- measures the top bar and the device's cutouts and keeps the area below and inside them. The
-- arithmetic is HudLayout.railToggle / drawer.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HudLayout = require(ReplicatedStorage.Shared.HudLayout)
local Create = require(script.Parent.Create)
local Theme = require(script.Parent.Theme)

local RightColumn = {}

RightColumn.SCREEN_INSETS = Enum.ScreenInsets.CoreUISafeInsets -- the rail's ScreenGuis
RightColumn.MARGIN = HudLayout.MARGIN
RightColumn.GAP = HudLayout.GAP
RightColumn.PANEL_WIDTH = 300
RightColumn.SMALL_TEXT = 13 -- a square toggle's two-line label
RightColumn.LARGE_TEXT = 20 -- a full-width toggle's label

type Toggle = { button: TextButton, slot: number, small: string, large: string }

local toggles: { Toggle } = {}
local filled: { [GuiObject]: true } = {} -- panels sized to the drawer's height
RightColumn.panels = {} :: { GuiObject }

local openedEvent = Instance.new("BindableEvent")
RightColumn.opened = openedEvent.Event

function RightColumn.notifyOpened()
	openedEvent:Fire()
end

function RightColumn.layoutIn(area: Vector2)
	local small = HudLayout.isSmall(area)
	local size = HudLayout.sizes(area).toggle
	for index, toggle in toggles do
		local button = toggle.button
		button.Position = HudLayout.railToggle(area, index - 1)
		button.Size = UDim2.fromOffset(size.X, size.Y)
		button.Text = if small then toggle.small else toggle.large
		button.TextSize = if small then RightColumn.SMALL_TEXT else RightColumn.LARGE_TEXT
	end
	local drawer = HudLayout.drawer(area)
	for _, panel in RightColumn.panels do
		panel.Position = drawer.position
		if filled[panel] then
			panel.Size = UDim2.fromOffset(RightColumn.PANEL_WIDTH, drawer.height)
		end
	end
end

local watched: { ScreenGui } = {}

local function relayout()
	for _, gui in watched do
		if gui.Parent then
			RightColumn.layoutIn(gui.AbsoluteSize)
			return
		end
	end
end

function RightColumn.watch(gui: ScreenGui)
	table.insert(watched, gui)
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(relayout)
	relayout()
end

-- Every property is set before Parent; the UICorner is parented to the toggle first.
function RightColumn.makeToggle(
	gui: Instance,
	slot: number,
	properties: { [string]: any }
): TextButton
	local all: { [string]: any } = {
		AnchorPoint = Vector2.new(1, 0),
		TextSize = RightColumn.SMALL_TEXT,
		TextWrapped = true,
		Font = Theme.Fonts.title,
	}
	for key, value in properties do
		all[key] = value
	end
	local button = Create.create("TextButton", all, { Create.corner(Theme.Radius.panel) })
	button.Parent = gui
	table.insert(
		toggles,
		{ button = button, slot = slot, small = button.Text, large = button.Text }
	)
	table.sort(toggles, function(a, b)
		return a.slot < b.slot
	end)
	return button
end

function RightColumn.setLabels(button: TextButton, small: string, large: string)
	for _, toggle in toggles do
		if toggle.button == button then
			toggle.small, toggle.large = small, large
		end
	end
	relayout()
end

-- `properties` adds to (or overrides) the shell: right-anchored, 0.1 transparent, hidden.
-- `children` follow the UICorner and the 2-pixel UIStroke. Parent is set last.
function RightColumn.makePanel(
	className: string,
	gui: Instance,
	accent: Color3,
	properties: { [string]: any },
	children: { Instance }?,
	fill: boolean?
): any
	local all: { [string]: any } = {
		AnchorPoint = Vector2.new(1, 0),
		BackgroundTransparency = 0.1,
		Visible = false,
	}
	for key, value in properties do
		all[key] = value
	end
	local list = { Create.corner(Theme.Radius.panel), Create.stroke(accent, 2) }
	for _, child in (children or {}) :: { Instance } do
		table.insert(list, child)
	end
	local panel = Create.create(className, all, list)
	panel.Parent = gui
	table.insert(RightColumn.panels, panel)
	if fill then
		filled[panel] = true
	end
	return panel
end

return RightColumn
