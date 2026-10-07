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
--   drawer(area)                         the open rail panel: position (AnchorPoint 1, 0), the
--                                        width of a panel that fills it, height
--   promptStack(area, count, minHeight)  the prompt cards' column: left, top, width, card height
--   cardTop(column, gap, index)          the top of the index-th card
--   cardInsides(height, width)           a card's key badge and text box
--   mechColumn(jumpPosition, jumpSize)   the action cluster's slots, from the jump button
--   mechColumnFallback(viewport)         the same without a jump button: fractions of the screen
--   standPosition(column)                the seat slot (STAND, LAND)
--   podButtons(column)                   PodControls' pod, LAND, ▲ and ▼ round that cluster
--   armorySheet(area, margin)            the lobby armory's sheet in its gui's safe area
--   armory(sheet, screen, counts)        everything inside that sheet, per size class
--
-- An area is a ScreenGui's AbsoluteSize with ScreenInsets CoreUISafeInsets: the engine keeps it
-- below the top bar and inside the device's cutouts, so its corners are the screen's usable
-- corners. The fallbacks apply where there is no jump button to measure (desktop, or a touch
-- screen before its TouchGui exists). They are the "fall back to fractions of the screen" case of
-- CLAUDE.md's UI rules and keep to the lower right, clear of the screen centre (tested).
--
-- tools/tests/hud_layout.luau pins each against golden values and its rule; the armory against
-- the approved mockups' numbers and its rules (inside the sheet, no overlaps).

local HudLayout = {}

HudLayout.MARGIN = 12 -- gap between the zones and the gui area's edges
HudLayout.GAP = 8 -- gap between neighbours in a zone
-- A gui area whose short side is SMALL_SIDE or less is small (phones). Roblox's touch controls
-- draw their small jump button by the same test.
HudLayout.SMALL_SIDE = 500
HudLayout.STACK_SHARE = 0.45 -- prompt cards end above this share of the area's height
HudLayout.PILL_SHARE = 0.7 -- the pod's state button is this share of a slot's height

-- `drawer`: the width of a panel that fills the drawer (GOD MODE).
export type Sizes = { toggle: Vector2, status: Vector2, card: Vector2, drawer: number }

-- Small: square icon toggles. Large: full-width labelled toggles.
local SMALL: Sizes = {
	toggle = Vector2.new(56, 56),
	status = Vector2.new(236, 40),
	card = Vector2.new(236, 52),
	drawer = 340,
}
local LARGE: Sizes = {
	toggle = Vector2.new(220, 56),
	status = Vector2.new(300, 48),
	card = Vector2.new(300, 64),
	drawer = 420,
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
function HudLayout.drawer(area: Vector2): { position: UDim2, width: number, height: number }
	local top = HudLayout.railTop(area)
	return {
		position = UDim2.new(1, -leftOfRail(area), 0, top),
		width = HudLayout.sizes(area).drawer,
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

-- The lobby armory (client LobbyUI) ----------------------------------------------------------

-- A rectangle in pixels: left, top, width, height.
export type Rect = { x: number, y: number, w: number, h: number }

-- One size class's sizes. Pixels; `*Size` is a TextSize.
export type ArmorySizes = {
	padding: number, -- inside the sheet's edge
	gap: number, -- between the header and the body, and between the body's three columns
	header: number,
	titleSize: number,
	counterSize: number,
	lookWidth: number,
	lookHeight: number,
	lookSize: number,
	categoryWidth: number,
	categoryHeight: number,
	categoryGap: number,
	categorySize: number,
	columns: number, -- weapon grid columns, fewer where a card would be narrower than minCard
	minCard: number,
	cardHeight: number,
	cardGap: number,
	cardPadX: number,
	cardPadY: number,
	nameSize: number,
	metaSize: number,
	statSize: number,
	descriptionSize: number, -- 0: the card has no description
	scrollBar: number,
	cardStroke: number, -- a chosen card's outline, and the grid's inset that keeps it in view
	sideWidth: number,
	sideGap: number,
	labelHeight: number,
	labelSize: number,
	teamLabelGap: number, -- extra space above the TEAM label
	slotHeight: number,
	slotSize: number,
	dots: boolean, -- teams as colour dots with the chosen team's name below, or named rows
	teamHeight: number, -- a dot's side, or a row's height
	teamSize: number,
	deployHeight: number,
	deploySize: number,
}

-- Small: isSmall of the screen. Numbers from the approved mockups: phone 932x430 (small), tablet
-- 1180x820 (large).
HudLayout.ARMORY_SMALL = table.freeze({
	padding = 12,
	gap = 10,
	header = 44,
	titleSize = 20,
	counterSize = 11,
	lookWidth = 150,
	lookHeight = 44,
	lookSize = 13,
	categoryWidth = 96,
	categoryHeight = 36,
	categoryGap = 2,
	categorySize = 12,
	columns = 3,
	minCard = 120,
	cardHeight = 78,
	cardGap = 8,
	cardPadX = 10,
	cardPadY = 8,
	nameSize = 12,
	metaSize = 10,
	statSize = 10,
	descriptionSize = 0,
	scrollBar = 6,
	cardStroke = 2,
	sideWidth = 196,
	sideGap = 6,
	labelHeight = 12,
	labelSize = 11,
	teamLabelGap = 4,
	slotHeight = 34,
	slotSize = 12,
	dots = true,
	teamHeight = 34,
	teamSize = 11,
	deployHeight = 56,
	deploySize = 18,
} :: ArmorySizes)
HudLayout.ARMORY_LARGE = table.freeze({
	padding = 20,
	gap = 16,
	header = 52,
	titleSize = 26,
	counterSize = 13,
	lookWidth = 170,
	lookHeight = 48,
	lookSize = 15,
	categoryWidth = 140,
	categoryHeight = 48,
	categoryGap = 6,
	categorySize = 15,
	columns = 4,
	minCard = 140,
	cardHeight = 124,
	cardGap = 12,
	cardPadX = 12,
	cardPadY = 10,
	nameSize = 14,
	metaSize = 11,
	statSize = 11,
	descriptionSize = 11,
	scrollBar = 6,
	cardStroke = 2,
	sideWidth = 280,
	sideGap = 8,
	labelHeight = 16,
	labelSize = 13,
	teamLabelGap = 10,
	slotHeight = 48,
	slotSize = 14,
	dots = false,
	teamHeight = 44,
	teamSize = 13,
	deployHeight = 72,
	deploySize = 26,
} :: ArmorySizes)

-- The largest sheet: on a desktop monitor the sheet stops growing and sits centred in its area.
HudLayout.ARMORY_MAX = Vector2.new(1280, 860)

-- The sheet in its gui's area (ScreenInsets CoreUISafeInsets: below the top bar, inside the
-- device's cutouts): the area less `margin` on every side, at most ARMORY_MAX, centred.
function HudLayout.armorySheet(area: Vector2, margin: number): Rect
	local w = math.max(0, math.min(area.X - margin * 2, HudLayout.ARMORY_MAX.X))
	local h = math.max(0, math.min(area.Y - margin * 2, HudLayout.ARMORY_MAX.Y))
	return { x = math.floor((area.X - w) / 2), y = math.floor((area.Y - h) / 2), w = w, h = h }
end

export type Armory = {
	small: boolean,
	sizes: ArmorySizes,
	title: Rect,
	counter: Rect,
	look: Rect,
	category: Rect, -- the first category; the rest follow down by categoryStep
	categoryStep: number,
	grid: Rect,
	columns: number,
	cell: Vector2,
	card: { name: Rect, meta: Rect, description: Rect, stat: Rect }, -- inside a cell
	loadoutLabel: Rect,
	slot: Rect, -- the first slot; the rest follow down by slotStep
	slotStep: number,
	teamLabel: Rect,
	team: Rect, -- the first team; the rest follow by teamStep (right for dots, down for rows)
	teamStep: Vector2,
	teamName: Rect, -- the chosen team's name under the dots; zero height with rows
	deploy: Rect,
}

-- Everything in the sheet, in the sheet's space. `sheet` is its measured size, `screen` the
-- viewport (it picks the size class). Header row: title and counter left, Look around right.
-- Body: categories left, the weapon grid between, the side column right (LOADOUT slots, TEAM,
-- ENTER THE MAYHEM at the bottom). The grid takes the width the fixed columns leave and drops
-- grid columns before a card gets narrower than minCard. A body too short for the categories or
-- the side column shrinks their rows (categories; slots, teams, deploy by one factor); labels and
-- gaps keep their size.
function HudLayout.armory(
	sheet: Vector2,
	screen: Vector2,
	counts: { categories: number, slots: number, teams: number }
): Armory
	local small = HudLayout.isSmall(screen)
	local s = if small then HudLayout.ARMORY_SMALL else HudLayout.ARMORY_LARGE
	local pad, gap = s.padding, s.gap

	-- Header: title over counter, centred in the row's height; Look around at the right.
	local lookX = sheet.X - pad - s.lookWidth
	local textWidth = math.max(0, lookX - gap - pad)
	local textTop = pad + math.floor((s.header - (s.titleSize + 4 + s.counterSize)) / 2)
	local look = {
		x = lookX,
		y = pad + math.floor((s.header - s.lookHeight) / 2),
		w = s.lookWidth,
		h = s.lookHeight,
	}

	-- Body columns.
	local top = pad + s.header + gap
	local height = math.max(0, sheet.Y - top - pad)
	local gridX = pad + s.categoryWidth + gap
	local sideX = sheet.X - pad - s.sideWidth
	local gridWidth = math.max(0, sideX - gap - gridX)

	local categories = math.max(counts.categories, 1)
	local categoryFit = math.floor((height - (categories - 1) * s.categoryGap) / categories)
	local categoryHeight = math.clamp(categoryFit, 0, s.categoryHeight)

	-- Grid: the scroll bar keeps its own strip (VerticalScrollBarInset Always); an inset of
	-- cardStroke on every side keeps a chosen card's outline inside the grid's clipping.
	local inner = gridWidth - s.scrollBar - s.cardStroke * 2
	local fits = math.floor((inner + s.cardGap) / (s.minCard + s.cardGap))
	local columns = math.clamp(fits, 1, s.columns)
	local cellWidth = math.max(0, math.floor((inner - (columns - 1) * s.cardGap) / columns))
	local cellHeight = s.cardHeight

	-- Card insides: name and meta from the top, the stat line at the bottom, the description
	-- between them.
	local textW = math.max(0, cellWidth - s.cardPadX * 2)
	local name = { x = s.cardPadX, y = s.cardPadY, w = textW, h = s.nameSize + 2 }
	local meta = { x = s.cardPadX, y = name.y + name.h + 2, w = textW, h = s.metaSize + 2 }
	local stat = {
		x = s.cardPadX,
		y = cellHeight - s.cardPadY - s.statSize,
		w = textW,
		h = s.statSize,
	}
	local descriptionY = meta.y + meta.h + 4
	local description = {
		x = s.cardPadX,
		y = descriptionY,
		w = textW,
		h = if s.descriptionSize > 0 then math.max(0, stat.y - 4 - descriptionY) else 0,
	}

	-- Side column: labels and gaps keep their size; slots, teams and deploy share the rest.
	local slots, teams = counts.slots, counts.teams
	local labels = s.labelHeight * (if s.dots then 3 else 2)
	local teamGaps = if s.dots then 1 else math.max(teams - 1, 0)
	local gaps = s.sideGap * (math.max(slots - 1, 0) + teamGaps + 4) + s.teamLabelGap
	local teamRows = if s.dots then s.teamHeight else teams * s.teamHeight
	local flexible = slots * s.slotHeight + teamRows + s.deployHeight
	local factor = math.clamp((height - labels - gaps) / math.max(flexible, 1), 0, 1)
	local slotHeight = math.floor(s.slotHeight * factor)
	local teamHeight = math.floor(s.teamHeight * factor)
	local deployHeight = math.floor(s.deployHeight * factor)

	local y = top
	local loadoutLabel = { x = sideX, y = y, w = s.sideWidth, h = s.labelHeight }
	y += s.labelHeight + s.sideGap
	local slot = { x = sideX, y = y, w = s.sideWidth, h = slotHeight }
	local slotStep = slotHeight + s.sideGap
	y += slots * slotStep + s.teamLabelGap
	local teamLabel = { x = sideX, y = y, w = s.sideWidth, h = s.labelHeight }
	y += s.labelHeight + s.sideGap
	local team, teamStep, teamName
	if s.dots then
		local across = if teams > 1 then math.floor((s.sideWidth - teamHeight) / (teams - 1)) else 0
		team = { x = sideX, y = y, w = teamHeight, h = teamHeight }
		teamStep = Vector2.new(across, 0)
		teamName = { x = sideX, y = y + teamHeight + s.sideGap, w = s.sideWidth, h = s.labelHeight }
	else
		team = { x = sideX, y = y, w = s.sideWidth, h = teamHeight }
		teamStep = Vector2.new(0, teamHeight + s.sideGap)
		teamName = { x = sideX, y = y, w = s.sideWidth, h = 0 }
	end

	return {
		small = small,
		sizes = s,
		title = { x = pad, y = textTop, w = textWidth, h = s.titleSize },
		counter = { x = pad, y = textTop + s.titleSize + 4, w = textWidth, h = s.counterSize },
		look = look,
		category = { x = pad, y = top, w = s.categoryWidth, h = categoryHeight },
		categoryStep = categoryHeight + s.categoryGap,
		grid = { x = gridX, y = top, w = gridWidth, h = height },
		columns = columns,
		cell = Vector2.new(cellWidth, cellHeight),
		card = { name = name, meta = meta, description = description, stat = stat },
		loadoutLabel = loadoutLabel,
		slot = slot,
		slotStep = slotStep,
		teamLabel = teamLabel,
		team = team,
		teamStep = teamStep,
		teamName = teamName,
		deploy = { x = sideX, y = top + height - deployHeight, w = s.sideWidth, h = deployHeight },
	}
end

return HudLayout
