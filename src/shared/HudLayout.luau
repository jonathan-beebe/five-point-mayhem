--!strict
-- Layout math for the measured HUD: where the client places touch buttons and prompt cards, given
-- sizes and positions it measured on screen (src/client/ui/Hud reads them). Pixels throughout.
--
--   mechColumn(jumpPosition, jumpSize)   MechCamera's VIEW/STAND column, from the jump button
--   mechColumnFallback(viewport)         the same without a jump button: fractions of the screen
--   standPosition(column)                STAND, directly above VIEW
--   podButtons(column)                   PodControls' pod, LAND, ▲ and ▼ around that column
--   scopeButton(jumpPosition, jumpSize)  SniperScope's SCOPE button, above the jump button
--   scopeButtonFallback(viewport)        the same without a jump button: fractions of the screen
--   cardStack(stack)                     PromptPanel's card column: right edge, top, card height
--   cardTop(column, gap, index)          the top of the index-th card
--   cardInsides(height, width)           a card's key badge and text box
--   columnToggle(spec, slot)             a right-column toggle's position (AnchorPoint 1, 0)
--   columnPanelTop(spec)                 where the right column's panels start
--   columnPanelSize(spec, width)         a panel that fills the column down to its bottom margin
--
-- The fallbacks apply where there is no jump button to measure (desktop, or a touch screen before
-- its TouchGui exists). They are the "fall back to fractions of the screen" case of CLAUDE.md's UI
-- rules and keep to the lower right, clear of the screen centre (tested).
--
-- tools/tests/hud_layout.luau compares each with the inline code it replaced; the right column
-- against golden values and its rule.

local HudLayout = {}

-- A button column: square button side, gap between buttons, and the bottom-right corner of its
-- lowest button (VIEW).
export type Column = { size: number, gap: number, corner: UDim2 }

-- VIEW sits directly left of the jump button, bottoms aligned.
function HudLayout.mechColumn(jumpPosition: Vector2, jumpSize: Vector2): Column
	local size = math.floor(math.min(jumpSize.X, jumpSize.Y) * 0.8)
	local gap = math.floor(jumpSize.X * 0.15)
	local corner = UDim2.fromOffset(jumpPosition.X - gap, jumpPosition.Y + jumpSize.Y)
	return { size = size, gap = gap, corner = corner }
end

function HudLayout.mechColumnFallback(viewport: Vector2): Column
	local size = math.floor(math.min(viewport.X, viewport.Y) * 0.14)
	local gap = math.floor(size * 0.2)
	-- 0.85: ▲, two slots left of VIEW, stays in the right half of a 4:3 screen.
	local corner = UDim2.fromScale(0.85, 0.95)
	return { size = size, gap = gap, corner = corner }
end

function HudLayout.standPosition(column: Column): UDim2
	return column.corner - UDim2.fromOffset(0, column.size + column.gap)
end

export type Placed = { size: UDim2, position: UDim2 }

-- Two rows, VIEW's and STAND's, so every button stays in the lower right, clear of the screen
-- centre (a third row reaches the upper half above a high jump button). The pod button spans two
-- slots left of STAND; LAND takes STAND's slot (LAND shows only in flight, when MechCamera hides
-- STAND); ▼ sits left of VIEW and ▲ left of ▼.
function HudLayout.podButtons(
	column: Column
): { pod: Placed, land: Placed, up: Placed, down: Placed }
	local step = column.size + column.gap
	local function slot(left: number, up: number): UDim2
		return column.corner - UDim2.fromOffset(left * step, up * step)
	end
	local wide = UDim2.fromOffset(column.size * 2 + column.gap, column.size)
	local square = UDim2.fromOffset(column.size, column.size)
	return {
		pod = { size = wide, position = slot(1, 1) },
		land = { size = square, position = slot(0, 1) },
		up = { size = square, position = slot(2, 0) },
		down = { size = square, position = slot(1, 0) },
	}
end

-- SCOPE sits directly above the jump button, centred on it (AnchorPoint 0.5, 1).
function HudLayout.scopeButton(jumpPosition: Vector2, jumpSize: Vector2): Placed
	local size = math.floor(math.min(jumpSize.X, jumpSize.Y) * 0.8)
	local gap = math.floor(jumpSize.Y * 0.15)
	local center = jumpPosition.X + jumpSize.X / 2
	return {
		size = UDim2.fromOffset(size, size),
		position = UDim2.fromOffset(math.floor(center), jumpPosition.Y - gap),
	}
end

function HudLayout.scopeButtonFallback(viewport: Vector2): Placed
	local size = math.floor(math.min(viewport.X, viewport.Y) * 0.14)
	return { size = UDim2.fromOffset(size, size), position = UDim2.fromScale(0.88, 0.62) }
end

-- What PromptPanel measured, in its gui's space. `toggle` is the MAC button's right and bottom
-- edges; `panelLefts` the left edges of the open panels in the right column; `controls` the
-- horizontal span and top edge of each bottom-right control.
export type Stack = {
	screen: Vector2,
	toggle: { right: number, bottom: number }?,
	panelLefts: { number },
	controls: { { left: number, right: number, top: number } },
	count: number,
	width: number,
	height: number, -- a card's full height
	minHeight: number, -- the shortest a card shrinks to above the controls
	gap: number,
}

-- Cards stack down from just below the toggle, right edges aligned with it, or left of the open
-- panels. They stop above every control under their column, shrinking (to minHeight) to fit.
function HudLayout.cardStack(stack: Stack): { right: number, top: number, height: number }
	local right, top = stack.screen.X, 0
	local toggle = stack.toggle
	if toggle then
		right = toggle.right
		top = toggle.bottom + stack.gap
	end
	for _, panelLeft in stack.panelLefts do
		right = math.min(right, panelLeft - stack.gap)
	end
	local left = right - stack.width
	local bottom = stack.screen.Y
	for _, control in stack.controls do
		if control.left < right and control.right > left then
			bottom = math.min(bottom, control.top - stack.gap)
		end
	end

	local count = stack.count
	local fit = math.floor((bottom - top - (count - 1) * stack.gap) / count)
	local height = math.clamp(fit, stack.minHeight, stack.height)
	return { right = right, top = top, height = height }
end

function HudLayout.cardTop(
	column: { top: number, height: number },
	gap: number,
	index: number
): number
	return column.top + (index - 1) * (column.height + gap)
end

-- The badge: a square as tall as the card less a margin top and bottom, at the left margin. The
-- texts run from a margin right of it to the card's right margin.
function HudLayout.cardInsides(
	height: number,
	width: number
): {
	margin: number,
	side: number,
	textLeft: number,
	textWidth: number,
	textHeight: number,
}
	local margin = math.floor(height * 0.15)
	local side = height - margin * 2
	local textLeft = margin * 2 + side
	return {
		margin = margin,
		side = side,
		textLeft = textLeft,
		textWidth = width - textLeft - margin,
		textHeight = height - margin * 2,
	}
end

-- The right column (ui/RightColumn) in a ScreenGui with ScreenInsets CoreUISafeInsets: the engine
-- measures the top bar and the device's cutouts and starts the gui's area below and inside them, so
-- the column hangs from that area's top-right corner. `margin` is the gap to the area's top, right
-- and bottom edges; `toggles` the number of toggles stacked above the panels.
export type ColumnSpec = { margin: number, toggleHeight: number, gap: number, toggles: number }

function HudLayout.columnToggle(spec: ColumnSpec, slot: number): UDim2
	return UDim2.new(1, -spec.margin, 0, spec.margin + slot * (spec.toggleHeight + spec.gap))
end

function HudLayout.columnPanelTop(spec: ColumnSpec): number
	return spec.margin + spec.toggles * (spec.toggleHeight + spec.gap)
end

function HudLayout.columnPanelSize(spec: ColumnSpec, width: number): UDim2
	return UDim2.new(0, width, 1, -(HudLayout.columnPanelTop(spec) + spec.margin))
end

return HudLayout
