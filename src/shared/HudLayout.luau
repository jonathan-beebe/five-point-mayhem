--!strict
-- Layout math for the measured HUD: where the client places its corners of the screen, given sizes
-- and positions it measured on screen (src/client/ui/Hud reads them). Pixels throughout.
--
-- The zones (CLAUDE.md UI rules; README's UI conventions draw them):
--   top right     the vehicle status, the system rail (GOD MODE, MAC) and the drawer each opens
--   top left      the prompt stack, under the Roblox top bar
--   bottom right  the action cluster round the jump button: camera slot (VIEW, SCOPE) left of
--                 jump, seat slot (STAND, LAND) above it, ▲ and ▼ left of the camera slot, and the
--                 pod's state button above them all
--   bottom left   the thumbstick (Roblox's), kept clear
--
--   isSmall(area)                        a phone-sized gui area: the small size class
--   sizes(area)                          the size class's toggle, status and card sizes
--   railTop(area)                        the first rail toggle's top
--   railToggle(area, index)              the index-th (0-based) rail toggle (AnchorPoint 1, 0)
--   statusPosition(area)                 the vehicle status (AnchorPoint 1, 0)
--   drawer(area)                         the open rail panel: position (AnchorPoint 1, 0), height
--   promptStack(area, count, minHeight)  the prompt cards' column: left, top, width, card height
--   cardTop(column, gap, index)          the top of the index-th card
--   cardInsides(height, width)           a card's key badge and text box
--   mechColumn(jumpPosition, jumpSize)   the action cluster's slots, from the jump button
--   mechColumnFallback(viewport)         the same without a jump button: fractions of the screen
--   standPosition(column)                the seat slot (STAND, LAND)
--   podButtons(column)                   PodControls' pod, LAND, ▲ and ▼ round that cluster
--
-- An area is a ScreenGui's AbsoluteSize with ScreenInsets CoreUISafeInsets: the engine keeps it
-- below the top bar and inside the device's cutouts, so its corners are the screen's usable
-- corners. The fallbacks apply where there is no jump button to measure (desktop, or a touch
-- screen before its TouchGui exists). They are the "fall back to fractions of the screen" case of
-- CLAUDE.md's UI rules and keep to the lower right, clear of the screen centre (tested).
--
-- tools/tests/hud_layout.luau pins each against golden values and its rule.

local HudLayout = {}

HudLayout.MARGIN = 12 -- gap between the zones and the gui area's edges
HudLayout.GAP = 8 -- gap between neighbours in a zone
-- A gui area whose short side is SMALL_SIDE or less is small (phones). Roblox's touch controls
-- draw their small jump button by the same test.
HudLayout.SMALL_SIDE = 500
HudLayout.STACK_SHARE = 0.45 -- prompt cards end above this share of the area's height
HudLayout.PILL_SHARE = 0.7 -- the pod's state button is this share of a slot's height

export type Sizes = { toggle: Vector2, status: Vector2, card: Vector2 }

-- Small: square icon toggles. Large: full-width labelled toggles.
local SMALL: Sizes = {
	toggle = Vector2.new(56, 56),
	status = Vector2.new(236, 40),
	card = Vector2.new(236, 52),
}
local LARGE: Sizes = {
	toggle = Vector2.new(220, 56),
	status = Vector2.new(300, 48),
	card = Vector2.new(300, 64),
}

function HudLayout.isSmall(area: Vector2): boolean
	return math.min(area.X, area.Y) <= HudLayout.SMALL_SIDE
end

function HudLayout.sizes(area: Vector2): Sizes
	return if HudLayout.isSmall(area) then SMALL else LARGE
end

-- Top right ---------------------------------------------------------------------------------------

-- Small: the status takes the corner and the rail starts under it, so the rail and its drawer
-- line up. Large: the rail takes the corner and the status sits left of it.
function HudLayout.railTop(area: Vector2): number
	if HudLayout.isSmall(area) then
		return HudLayout.MARGIN + SMALL.status.Y + HudLayout.GAP
	end
	return HudLayout.MARGIN
end

function HudLayout.railToggle(area: Vector2, index: number): UDim2
	local toggle = HudLayout.sizes(area).toggle
	local top = HudLayout.railTop(area) + index * (toggle.Y + HudLayout.GAP)
	return UDim2.new(1, -HudLayout.MARGIN, 0, top)
end

-- The right edge of whatever sits left of the rail (the large status, the drawer), from the
-- area's right edge.
local function leftOfRail(area: Vector2): number
	return HudLayout.MARGIN + HudLayout.sizes(area).toggle.X + HudLayout.GAP
end

function HudLayout.statusPosition(area: Vector2): UDim2
	if HudLayout.isSmall(area) then
		return UDim2.new(1, -HudLayout.MARGIN, 0, HudLayout.MARGIN)
	end
	return UDim2.new(1, -leftOfRail(area), 0, HudLayout.MARGIN)
end

-- The drawer opens left of the rail, top-aligned with it, and may run down to the bottom margin:
-- an open panel covers the action cluster until it closes (the panels draw over the touch layer).
function HudLayout.drawer(area: Vector2): { position: UDim2, height: number }
	local top = HudLayout.railTop(area)
	return {
		position = UDim2.new(1, -leftOfRail(area), 0, top),
		height = math.max(area.Y - top - HudLayout.MARGIN, 0),
	}
end

-- Top left ----------------------------------------------------------------------------------------

-- Cards stack down from the top-left corner and end above STACK_SHARE of the height, clear of the
-- thumbstick, shrinking (to minHeight) to fit. One full card always fits.
function HudLayout.promptStack(
	area: Vector2,
	count: number,
	minHeight: number
): { left: number, top: number, width: number, height: number }
	local card = HudLayout.sizes(area).card
	local top = HudLayout.MARGIN
	local bottom = math.max(area.Y * HudLayout.STACK_SHARE, top + card.Y)
	local fit = math.floor((bottom - top - (count - 1) * HudLayout.GAP) / count)
	return {
		left = HudLayout.MARGIN,
		top = top,
		width = card.X,
		height = math.clamp(fit, minHeight, card.Y),
	}
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

-- Bottom right ------------------------------------------------------------------------------------

-- The action cluster: square slot side, gap between slots, the bottom-right corner of the camera
-- slot (VIEW, SCOPE) and of the seat slot (STAND, LAND).
export type Column = { size: number, gap: number, corner: UDim2, seat: UDim2 }

-- The camera slot sits directly left of the jump button, bottoms aligned; the seat slot directly
-- above the jump button, centred on it.
function HudLayout.mechColumn(jumpPosition: Vector2, jumpSize: Vector2): Column
	local size = math.floor(math.min(jumpSize.X, jumpSize.Y) * 0.8)
	local gap = math.floor(jumpSize.X * 0.15)
	local corner = UDim2.fromOffset(jumpPosition.X - gap, jumpPosition.Y + jumpSize.Y)
	local seat =
		UDim2.fromOffset(math.floor(jumpPosition.X + (jumpSize.X + size) / 2), jumpPosition.Y - gap)
	return { size = size, gap = gap, corner = corner, seat = seat }
end

-- Without a jump button the seat slot takes the jump button's place, right of the camera slot.
function HudLayout.mechColumnFallback(viewport: Vector2): Column
	local size = math.floor(math.min(viewport.X, viewport.Y) * 0.14)
	local gap = math.floor(size * 0.2)
	-- 0.85: ▲ and ▼, a slot left of the camera slot, stay in the right half of a 4:3 screen.
	local corner = UDim2.fromScale(0.85, 0.95)
	return {
		size = size,
		gap = gap,
		corner = corner,
		seat = corner + UDim2.fromOffset(size + gap, 0),
	}
end

function HudLayout.standPosition(column: Column): UDim2
	return column.seat
end

export type Placed = { size: UDim2, position: UDim2 }

-- ▼ sits left of the camera slot and ▲ above ▼; LAND takes the seat slot (LAND shows only in
-- flight, when MechCamera hides STAND). The pod's state button spans from ▲'s left edge to the
-- seat slot's right edge, a gap above the higher of the two, PILL_SHARE of a slot tall, so it
-- stays in the lower half of the screen (tested).
function HudLayout.podButtons(
	column: Column
): { pod: Placed, land: Placed, up: Placed, down: Placed }
	local size, gap = column.size, column.gap
	local step = size + gap
	local square = UDim2.fromOffset(size, size)
	local corner, seat = column.corner, column.seat
	local upTop = corner.Y.Offset - step - size
	local seatTop = seat.Y.Offset - size
	local pillHeight = math.floor(size * HudLayout.PILL_SHARE)
	local width = seat.X.Offset - corner.X.Offset + size * 2 + gap
	return {
		pod = {
			size = UDim2.fromOffset(width, pillHeight),
			position = UDim2.new(
				seat.X.Scale,
				seat.X.Offset,
				seat.Y.Scale,
				math.min(upTop, seatTop) - gap
			),
		},
		land = { size = square, position = seat },
		up = { size = square, position = corner - UDim2.fromOffset(step, step) },
		down = { size = square, position = corner - UDim2.fromOffset(step, 0) },
	}
end

return HudLayout
