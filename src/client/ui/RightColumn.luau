-- The right-edge column: the GOD MODE toggle (AdminPanel) on top, the MAC toggle (MacPanel) below
-- it, and the panel each opens below both, one open at a time. PromptPanel measures the MAC button
-- and the open panels to stack its cards under and beside them.
--
--   fullHeight(width)                            the Size of a panel that fills the column
--   makeToggle(gui, slot, properties)            a toggle in slot 0 (top) or 1, parented to `gui`
--   makePanel(className, gui, accent, properties, children?)
--                                                a hidden panel under the toggles, outlined in
--                                                `accent`, parented to `gui` and listed in `panels`
--   toggle      the MAC button once built (MacPanel sets it; PromptPanel anchors to it)
--   panels      every panel in the column, open or not
--   opened      fires when the MAC panel opens (notifyOpened), so GOD MODE's closes
--
-- Placement: the column hangs from the top-right corner of its ScreenGui's area, which must be
-- ScreenInsets CoreUISafeInsets (SCREEN_INSETS): the engine measures the top bar and the device's
-- cutouts and keeps that area below and inside them. MARGIN is the gap to that area's edges. The
-- arithmetic is HudLayout.columnToggle / columnPanelTop / columnPanelSize.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HudLayout = require(ReplicatedStorage.Shared.HudLayout)
local Create = require(script.Parent.Create)
local Theme = require(script.Parent.Theme)

local RightColumn = {}

RightColumn.SCREEN_INSETS = Enum.ScreenInsets.CoreUISafeInsets -- the column's ScreenGuis
RightColumn.MARGIN = 12 -- gap between the column and its area's top, right and bottom edges
RightColumn.TOGGLE_WIDTH = 130
RightColumn.TOGGLE_HEIGHT = 40
RightColumn.GAP = 6
RightColumn.PANEL_WIDTH = 300

local SPEC: HudLayout.ColumnSpec = {
	margin = RightColumn.MARGIN,
	toggleHeight = RightColumn.TOGGLE_HEIGHT,
	gap = RightColumn.GAP,
	toggles = 2, -- GOD MODE, MAC
}
RightColumn.PANEL_TOP = HudLayout.columnPanelTop(SPEC)

RightColumn.toggle = nil :: GuiObject?
RightColumn.panels = {} :: { GuiObject }

local openedEvent = Instance.new("BindableEvent")
RightColumn.opened = openedEvent.Event

function RightColumn.notifyOpened()
	openedEvent:Fire()
end

-- Every property is set before Parent; the UICorner is parented to the toggle first.
function RightColumn.makeToggle(
	gui: Instance,
	slot: number,
	properties: { [string]: any }
): TextButton
	local all: { [string]: any } = {
		AnchorPoint = Vector2.new(1, 0),
		Position = HudLayout.columnToggle(SPEC, slot),
		Size = UDim2.fromOffset(RightColumn.TOGGLE_WIDTH, RightColumn.TOGGLE_HEIGHT),
		TextSize = 16,
		Font = Theme.Fonts.title,
	}
	for key, value in properties do
		all[key] = value
	end
	local toggle = Create.create("TextButton", all, { Create.corner(Theme.Radius.panel) })
	toggle.Parent = gui
	return toggle
end

-- A panel that fills the column from PANEL_TOP down to MARGIN above the bottom, `width` wide.
function RightColumn.fullHeight(width: number): UDim2
	return HudLayout.columnPanelSize(SPEC, width)
end

-- `properties` adds to (or overrides) the shell: right-anchored at PANEL_TOP, 0.1 transparent,
-- hidden. `children` follow the UICorner and the 2-pixel UIStroke. Parent is set last.
function RightColumn.makePanel(
	className: string,
	gui: Instance,
	accent: Color3,
	properties: { [string]: any },
	children: { Instance }?
): any
	local all: { [string]: any } = {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -RightColumn.MARGIN, 0, RightColumn.PANEL_TOP),
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
	return panel
end

return RightColumn
