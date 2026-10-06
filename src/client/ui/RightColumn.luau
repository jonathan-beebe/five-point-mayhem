-- The right-edge column: the GOD MODE toggle (AdminPanel) on top, the MAC toggle (MacPanel) below
-- it, and the panel each opens below both, one open at a time. PromptPanel measures the MAC button
-- and the open panels to stack its cards under and beside them.
--
--   makeToggle(gui, slot, properties)            a toggle in slot 0 (top) or 1, parented to `gui`
--   makePanel(className, gui, accent, properties, children?)
--                                                a hidden panel under the toggles, outlined in
--                                                `accent`, parented to `gui` and listed in `panels`
--   toggle      the MAC button once built (MacPanel sets it; PromptPanel anchors to it)
--   panels      every panel in the column, open or not
--   opened      fires when the MAC panel opens (notifyOpened), so GOD MODE's closes
--
-- Debt (CLAUDE.md UI rules): TOGGLE_TOP and MARGIN are fixed pixel offsets, kept as they were in
-- MacPanel. They should come from measured on-screen elements.

local Create = require(script.Parent.Create)
local Theme = require(script.Parent.Theme)

local RightColumn = {}

RightColumn.TOGGLE_TOP = 60 -- debt: a guessed offset clear of the top bar
RightColumn.MARGIN = 12 -- debt: gap between the column and the screen's right (and bottom) edge
RightColumn.TOGGLE_WIDTH = 130
RightColumn.TOGGLE_HEIGHT = 40
RightColumn.GAP = 6
RightColumn.PANEL_TOP = RightColumn.TOGGLE_TOP + 2 * (RightColumn.TOGGLE_HEIGHT + RightColumn.GAP)
RightColumn.PANEL_WIDTH = 300

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
		Position = UDim2.new(
			1,
			-RightColumn.MARGIN,
			0,
			RightColumn.TOGGLE_TOP + slot * (RightColumn.TOGGLE_HEIGHT + RightColumn.GAP)
		),
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
