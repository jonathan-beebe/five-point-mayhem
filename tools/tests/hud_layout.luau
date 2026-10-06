-- Checks src/shared/HudLayout.luau outside Roblox.
-- Usage: lune run tools/tests/hud_layout.luau
--
--   - every function gives the same bits as the inline code it replaced (copied below as the
--     reference, compiled with luau.load as Sandbox compiles HudLayout), composed the way each
--     caller composes it now: MechCamera's VIEW/STAND column from a jump button, SniperScope's
--     SCOPE button (from a jump button and without one), PromptPanel's card stack (column, every
--     card's frame, badge and text box)
--   - golden values where the layout changed on purpose: the right column, PodControls' buttons
--     and MechCamera's fallback column (moved to keep persistent HUD off the screen centre)
--   - inputs: jump button sizes and positions (zero, fractional, phone to tablet), viewports
--     (zero, odd, 4K), and card stacks with and without the MAC toggle, open panels and controls
--     under, beside and clear of the column, 1 to 7 cards, screens too short to fit them
--   - a few plain values

local luau = require("@lune/luau")
local roblox = require("@lune/roblox")

local Check = require("../lib/Check")
local Sandbox = require("../lib/Sandbox")

local check, equal = Check.check, Check.equal
local Vector2, UDim, UDim2 = roblox.Vector2, roblox.UDim, roblox.UDim2

local HudLayout = Sandbox.load("src/shared/HudLayout.luau")

Check.printLimit = 10

-- The inline code HudLayout replaced, word for word (jump and viewport passed in; the buttons'
-- Size and Position returned instead of set).
local Reference = luau.load(
	[[
local Reference = {}

-- MechCamera.luau `layoutButton`.
function Reference.mech(jump, viewport)
	local size, gap, corner
	if jump then
		size = math.floor(math.min(jump.AbsoluteSize.X, jump.AbsoluteSize.Y) * 0.8)
		gap = math.floor(jump.AbsoluteSize.X * 0.15)
		corner = UDim2.fromOffset(
			jump.AbsolutePosition.X - gap,
			jump.AbsolutePosition.Y + jump.AbsoluteSize.Y
		)
	end -- the fallback (no jump button) moved since: golden values in "pod buttons"
	return {
		viewSize = UDim2.fromOffset(size, size),
		viewPosition = corner,
		standSize = UDim2.fromOffset(size, size),
		standPosition = corner - UDim2.fromOffset(0, size + gap),
		layout = { size = size, gap = gap, corner = corner },
	}
end

-- SniperScope.luau `layoutButton`.
function Reference.scope(jump, viewport)
	if jump then
		local size = math.floor(math.min(jump.AbsoluteSize.X, jump.AbsoluteSize.Y) * 0.8)
		local gap = math.floor(jump.AbsoluteSize.Y * 0.15)
		local center = jump.AbsolutePosition.X + jump.AbsoluteSize.X / 2
		return {
			size = UDim2.fromOffset(size, size),
			position = UDim2.fromOffset(math.floor(center), jump.AbsolutePosition.Y - gap),
		}
	end
	local size = math.floor(math.min(viewport.X, viewport.Y) * 0.14)
	return { size = UDim2.fromOffset(size, size), position = UDim2.fromScale(0.88, 0.62) }
end

-- PromptPanel.luau `layout` after the sort. `edgeY` is the module's edgeY (now Hud.edgeY), here
-- a lookup of precomputed edges; `panels` the shown panels; `controls` bottomControls().
function Reference.cards(screen, toggle, panels, controls, count, edgeY)
	local CARD_WIDTH, CARD_HEIGHT, MIN_CARD_HEIGHT, GAP = 220, 48, 28, 6
	local right, top = screen.X, 0
	if toggle then
		right = toggle.AbsolutePosition.X + toggle.AbsoluteSize.X
		top = edgeY(toggle, true) + GAP
	end
	for _, panel in panels do
		right = math.min(right, panel.AbsolutePosition.X - GAP)
	end
	local left = right - CARD_WIDTH
	local bottom = screen.Y
	for _, control in controls do
		local x0 = control.AbsolutePosition.X
		if x0 < right and x0 + control.AbsoluteSize.X > left then
			bottom = math.min(bottom, edgeY(control, false) - GAP)
		end
	end

	local height = math.clamp(
		math.floor((bottom - top - (count - 1) * GAP) / count),
		MIN_CARD_HEIGHT,
		CARD_HEIGHT
	)
	local cards = {}
	for index = 1, count do
		local card = {}
		card.frameSize = UDim2.fromOffset(CARD_WIDTH, height)
		card.framePosition = UDim2.fromOffset(right, top + (index - 1) * (height + GAP))
		local margin = math.floor(height * 0.15)
		local side = height - margin * 2
		card.badgeSize = UDim2.fromOffset(side, side)
		card.badgePosition = UDim2.new(0, margin, 0.5, 0)
		local textLeft = margin * 2 + side
		card.textsPosition = UDim2.fromOffset(textLeft, margin)
		card.textsSize = UDim2.fromOffset(CARD_WIDTH - textLeft - margin, height - margin * 2)
		cards[index] = card
	end
	return cards
end

return Reference
]],
	{ debugName = "HudLayout reference", environment = { UDim2 = UDim2, math = math } }
)()

-- The callers' code now, copied (MechCamera and SniperScope `layoutButton`, PromptPanel
-- `layout`), with the same inputs and outputs as Reference.
local Now = {}

function Now.mech(jump)
	local column = HudLayout.mechColumn(jump.AbsolutePosition, jump.AbsoluteSize)
	local size, gap, corner = column.size, column.gap, column.corner
	return {
		viewSize = UDim2.fromOffset(size, size),
		viewPosition = corner,
		standSize = UDim2.fromOffset(size, size),
		standPosition = HudLayout.standPosition(column),
		layout = { size = size, gap = gap, corner = corner },
	}
end

function Now.scope(jump, viewport)
	if jump then
		return HudLayout.scopeButton(jump.AbsolutePosition, jump.AbsoluteSize)
	end
	return HudLayout.scopeButtonFallback(viewport)
end

function Now.cards(screen, toggle, panels, controls, count, edgeY)
	local CARD_WIDTH, CARD_HEIGHT, MIN_CARD_HEIGHT, GAP = 220, 48, 28, 6
	local panelLefts = {}
	for _, panel in panels do
		table.insert(panelLefts, panel.AbsolutePosition.X)
	end
	local measured = {}
	for _, control in controls do
		local x0 = control.AbsolutePosition.X
		table.insert(measured, {
			left = x0,
			right = x0 + control.AbsoluteSize.X,
			top = edgeY(control, false),
		})
	end
	local column = HudLayout.cardStack({
		screen = screen,
		toggle = if toggle
			then {
				right = toggle.AbsolutePosition.X + toggle.AbsoluteSize.X,
				bottom = edgeY(toggle, true),
			}
			else nil,
		panelLefts = panelLefts,
		controls = measured,
		count = count,
		width = CARD_WIDTH,
		height = CARD_HEIGHT,
		minHeight = MIN_CARD_HEIGHT,
		gap = GAP,
	})
	local height = column.height
	local insides = HudLayout.cardInsides(height, CARD_WIDTH)
	local cards = {}
	for index = 1, count do
		cards[index] = {
			frameSize = UDim2.fromOffset(CARD_WIDTH, height),
			framePosition = UDim2.fromOffset(column.right, HudLayout.cardTop(column, GAP, index)),
			badgeSize = UDim2.fromOffset(insides.side, insides.side),
			badgePosition = UDim2.new(0, insides.margin, 0.5, 0),
			textsPosition = UDim2.fromOffset(insides.textLeft, insides.margin),
			textsSize = UDim2.fromOffset(insides.textWidth, insides.textHeight),
		}
	end
	return cards
end

-- Same 64 bits: -0 differs from 0, a NaN equals the same NaN.
local function same(a: number, b: number): boolean
	return string.pack("<d", a) == string.pack("<d", b)
end

local function sameUDim2(a, b): boolean
	return same(a.X.Scale, b.X.Scale)
		and same(a.X.Offset, b.X.Offset)
		and same(a.Y.Scale, b.Y.Scale)
		and same(a.Y.Offset, b.Y.Offset)
end

-- Compares two results field by field: UDim2s by bits, numbers by bits, tables recursively.
local function sameResult(got, want, label: string)
	for key, value in want do
		local other = got[key]
		local name = label .. "." .. tostring(key)
		if typeof(value) == "UDim2" then
			check(
				typeof(other) == "UDim2" and sameUDim2(other, value),
				string.format("%s: got %s, want %s", name, tostring(other), tostring(value))
			)
		elseif type(value) == "number" then
			check(
				type(other) == "number" and same(other, value),
				string.format("%s: got %s, want %s", name, tostring(other), tostring(value))
			)
		elseif type(value) == "table" then
			check(type(other) == "table", name .. " is a table")
			if type(other) == "table" then
				sameResult(other, value, name)
			end
		else
			equal(other, value, name)
		end
	end
	for key in got do
		check(want[key] ~= nil, label .. " extra field " .. tostring(key))
	end
end

local JUMP_SIDES = { 0, 1, 37.5, 60, 70, 90, 120.25, 200 }
local JUMP_POSITIONS = { -3, 0, 13.7, 500, 1234.5 }
local VIEWPORTS = {
	Vector2.new(1, 1),
	Vector2.new(57, 900),
	Vector2.new(0, 0),
	Vector2.new(320, 240),
	Vector2.new(375.5, 667.25),
	Vector2.new(800, 600),
	Vector2.new(1366.4, 1024.6),
	Vector2.new(1920, 1080),
	Vector2.new(3840, 2160),
}

for side = 0, 1000, 7 do
	table.insert(VIEWPORTS, Vector2.new(side, side + 333))
	table.insert(VIEWPORTS, Vector2.new(side + 0.5, side * 0.6))
end

-- Every jump button the sweep tries: a stand-in with the two properties the layouts read.
local jumps = {}
for _, width in JUMP_SIDES do
	for _, height in JUMP_SIDES do
		for _, x in JUMP_POSITIONS do
			for _, y in JUMP_POSITIONS do
				table.insert(jumps, {
					AbsoluteSize = Vector2.new(width, height),
					AbsolutePosition = Vector2.new(x, y),
				})
			end
		end
	end
end

-- Every whole-pixel side up to 240, square and not, where floor() rounding steps.
for side = 0, 240 do
	for _, other in { side, 70 } do
		table.insert(jumps, {
			AbsoluteSize = Vector2.new(side, other),
			AbsolutePosition = Vector2.new(900, 500),
		})
		table.insert(jumps, {
			AbsoluteSize = Vector2.new(other, side),
			AbsolutePosition = Vector2.new(900, 500),
		})
	end
end

local function describe(jump): string
	return string.format(
		"jump %s at %s",
		tostring(jump.AbsoluteSize),
		tostring(jump.AbsolutePosition)
	)
end

Check.section("mech column")
for _, jump in jumps do
	sameResult(Now.mech(jump), Reference.mech(jump, nil), "mech " .. describe(jump))
end

Check.section("scope button")
for _, jump in jumps do
	sameResult(Now.scope(jump, nil), Reference.scope(jump, nil), "scope " .. describe(jump))
end
for _, viewport in VIEWPORTS do
	sameResult(
		Now.scope(nil, viewport),
		Reference.scope(nil, viewport),
		"scope viewport " .. tostring(viewport)
	)
end

Check.section("card stack")
-- A stand-in GuiObject: position, size, and the edges edgeY would report for it (the inset
-- shift folded in).
local function object(x: number, y: number, width: number, height: number, shift: number)
	return {
		AbsolutePosition = Vector2.new(x, y),
		AbsoluteSize = Vector2.new(width, height),
		shift = shift,
	}
end
local function edgeY(each, bottom: boolean): number
	local y = each.AbsolutePosition.Y + (if bottom then each.AbsoluteSize.Y else 0)
	return y + each.shift
end

local SCREENS = {
	Vector2.new(375.5, 667.25),
	Vector2.new(800, 600),
	Vector2.new(1920, 1080),
	Vector2.new(640, 200), -- too short for the cards
}
local cases = 0
for _, screen in SCREENS do
	local toggles = {
		false,
		object(screen.X - 142, 106, 130, 40, 0),
		object(screen.X - 142, 106, 130, 40, 36),
		object(screen.X - 142.5, 60.25, 130, 40, -36),
	}
	local panelSets = {
		{},
		{ object(screen.X - 312, 152, 300, 142, 0) },
		{ object(screen.X - 312, 152, 300, 142, 0), object(screen.X - 312.5, 152, 300, 400, 0) },
	}
	local controlSets = {
		{},
		-- the jump button under the column
		{ object(screen.X - 100, screen.Y - 110, 90, 90, 0) },
		-- MechCamera's column left of the jump button, one control clear of the cards
		{
			object(screen.X - 100, screen.Y - 110, 90, 90, -36),
			object(screen.X - 184, screen.Y - 92, 72, 72, 0),
			object(screen.X - 184, screen.Y - 177.5, 72, 72, 0),
			object(10, screen.Y - 300, 72, 72, 0),
		},
		-- controls touching the column's left or right edge exactly (with the toggle): not under it
		{ object(screen.X - 12 - 220 - 72, screen.Y - 200, 72, 72, 0) },
		{ object(screen.X - 12, screen.Y - 200, 72, 72, 0) },
	}
	for _, toggle in toggles do
		for _, panels in panelSets do
			for _, controls in controlSets do
				for count = 1, 7 do
					local given = if toggle then toggle else nil
					local label = string.format(
						"screen %s toggle %s panels %d controls %d count %d",
						tostring(screen),
						if given then tostring(given.AbsolutePosition) else "none",
						#panels,
						#controls,
						count
					)
					sameResult(
						Now.cards(screen, given, panels, controls, count, edgeY),
						Reference.cards(screen, given, panels, controls, count, edgeY),
						label
					)
					cases += 1
				end
			end
		end
	end
end
check(cases == 4 * 4 * 3 * 5 * 7, "card stack cases")

Check.section("values")
local tall = HudLayout.cardStack({
	screen = Vector2.new(1920, 1080),
	toggle = { right = 1908, bottom = 146 },
	panelLefts = {},
	controls = {},
	count = 2,
	width = 220,
	height = 48,
	minHeight = 28,
	gap = 6,
})
equal(tall.right, 1908, "cards align with the toggle's right edge")
equal(tall.top, 152, "cards start a gap under the toggle")
equal(tall.height, 48, "cards are full height with room")
local short = HudLayout.cardStack({
	screen = Vector2.new(640, 200),
	toggle = nil,
	panelLefts = { 300 },
	controls = {},
	count = 7,
	width = 220,
	height = 48,
	minHeight = 28,
	gap = 6,
})
equal(short.right, 294, "cards sit a gap left of an open panel")
equal(short.height, 28, "cards shrink no further than minHeight")
equal(HudLayout.cardTop({ top = 10, height = 40 }, 6, 3), 102, "third card's top")
local insides = HudLayout.cardInsides(48, 220)
equal(insides.margin, 7, "card margin")
equal(insides.side, 34, "badge side")
equal(insides.textWidth, 220 - 48 - 7, "text width")

-- The right column hangs from the top-right corner of its ScreenGui, whose CoreUISafeInsets area
-- the engine keeps below the top bar and inside the device's safe area: nothing to guess about the
-- top bar. Golden values for RightColumn's spec, then the rule on other specs.
Check.section("right column")
local COLUMN = { margin = 12, toggleHeight = 40, gap = 6, toggles = 2 }
equal(HudLayout.columnToggle(COLUMN, 0), UDim2.new(1, -12, 0, 12), "GOD MODE toggle")
equal(HudLayout.columnToggle(COLUMN, 1), UDim2.new(1, -12, 0, 58), "MAC toggle")
equal(HudLayout.columnPanelTop(COLUMN), 104, "panels start a gap under the MAC toggle")
equal(
	HudLayout.columnPanelSize(COLUMN, 300),
	UDim2.new(0, 300, 1, -116),
	"a full-height panel stops a margin above the bottom"
)
for _, spec in
	{
		{ margin = 0, toggleHeight = 40, gap = 6, toggles = 2 },
		{ margin = 8, toggleHeight = 33, gap = 0, toggles = 1 },
		{ margin = 20, toggleHeight = 50, gap = 10, toggles = 3 },
	}
do
	local label = string.format("margin %s gap %s toggles %d", spec.margin, spec.gap, spec.toggles)
	local first = HudLayout.columnToggle(spec, 0)
	equal(first.Y.Offset, spec.margin, label .. ": first toggle a margin below the safe top")
	equal(first.X, UDim.new(1, -spec.margin), label .. ": a margin in from the safe right edge")
	equal(first.Y.Scale, 0, label .. ": hangs from the top, whatever the screen height")
	local last = HudLayout.columnToggle(spec, spec.toggles - 1)
	equal(
		HudLayout.columnPanelTop(spec),
		last.Y.Offset + spec.toggleHeight + spec.gap,
		label .. ": panels a gap under the last toggle"
	)
end

-- LAND shares STAND's slot: whenever PodButtons shows LAND (or ▲ and ▼), the pod is in flight,
-- and MechCamera hides STAND in flight (its seatsLocked is PodState.inFlight).
Check.section("pod buttons")
local Shared = Sandbox.game:GetService("ReplicatedStorage").Shared
local PodButtons = Sandbox.require(Shared.PodButtons)
local PodState = Sandbox.require(Shared.PodState)
for _, state in { "docked", "flying", "returning", "landed", "wrecked" } do
	for _, aboard in { true, false } do
		for _, canLand in { true, false } do
			for _, touch in { true, false } do
				local view = PodButtons.view(state, aboard, canLand, touch)
				local label = string.format(
					"%s aboard %s canLand %s touch %s",
					state,
					tostring(aboard),
					tostring(canLand),
					tostring(touch)
				)
				check(
					not (view.landVisible or view.liftVisible) or PodState.inFlight(state),
					label .. ": LAND and lift only in flight"
				)
			end
		end
	end
end
local golden = HudLayout.podButtons({ size = 50, gap = 10, corner = UDim2.fromOffset(700, 400) })
equal(golden.pod.size, UDim2.fromOffset(110, 50), "pod button two slots wide")
equal(golden.pod.position, UDim2.fromOffset(640, 340), "pod button left of STAND")
equal(golden.land.size, UDim2.fromOffset(50, 50), "LAND one slot")
equal(golden.land.position, UDim2.fromOffset(700, 340), "LAND in STAND's slot")
equal(golden.up.position, UDim2.fromOffset(580, 400), "▲ left of ▼")
equal(golden.down.position, UDim2.fromOffset(640, 400), "▼ left of VIEW")
-- Without a jump button: sides 14% of the short side, gaps 20% of a side, VIEW's corner at 85%
-- across (80% before the two-row pod buttons) and 95% down.
for _, case in
	{
		{ viewport = Vector2.new(1000, 800), size = 112, gap = 22 },
		{ viewport = Vector2.new(844, 390), size = 54, gap = 10 },
		{ viewport = Vector2.new(0, 0), size = 0, gap = 0 },
	}
do
	local column = HudLayout.mechColumnFallback(case.viewport)
	local label = "fallback column " .. tostring(case.viewport)
	equal(column.size, case.size, label .. " size")
	equal(column.gap, case.gap, label .. " gap")
	equal(column.corner, UDim2.fromScale(0.85, 0.95), label .. " VIEW corner")
	equal(
		HudLayout.standPosition(column),
		UDim2.new(0.85, 0, 0.95, -(case.size + case.gap)),
		label .. " STAND above VIEW"
	)
end

-- Persistent HUD never sits at the screen centre (CLAUDE.md UI rules). Every touch button
-- (SCOPE, VIEW, STAND, and PodControls' pod, LAND, ▲ and ▼) stays inside its gui, clear of the
-- screen's centre point, in the right half and in the lower half of the screen, laid out two ways:
--   - measured from the jump button where Roblox's PlayerModule puts it (ControlModule/TouchJump
--     `ResizeJumpButton`, in ControlModule's TouchControlFrame, which fills TouchGui: a ScreenGui
--     with the default ScreenInsets, CoreUISafeInsets)
--   - the fallback without a jump button (desktop; a touch screen before its TouchGui exists):
--     fractions of the button gui, sized from the camera's ViewportSize (the whole screen)
-- Every gui here keeps the default insets (the buttons copy TouchGui's), so its area is the screen
-- less the top bar: 36 pixels (the old top bar) or 58 (the current one, GuiService:GetGuiInset()).
-- The device's side cutouts are not modelled. Screens are landscape: StarterGui.ScreenOrientation
-- is left at Roblox's default (LandscapeSensor), so phones never run this game in portrait.
Check.section("touch buttons stay off the centre")
local TOP_BARS = { 36, 58 }

-- A gui's area and the screen's centre point in the gui's coordinates.
type Space = { area: any, centre: any }

local function rect(placed: { size: any, position: any }, anchor: any, space: Space)
	local width, height = placed.size.X.Offset, placed.size.Y.Offset
	local area = space.area
	local x = placed.position.X.Scale * area.X + placed.position.X.Offset - anchor.X * width
	local y = placed.position.Y.Scale * area.Y + placed.position.Y.Offset - anchor.Y * height
	return { left = x, top = y, right = x + width, bottom = y + height }
end
local function offCentre(box, space: Space, label: string)
	local area, centre = space.area, space.centre
	check(
		box.left >= 0 and box.top >= 0 and box.right <= area.X and box.bottom <= area.Y,
		label .. " inside its gui"
	)
	check((box.top + box.bottom) / 2 > centre.Y, label .. " in the lower half")
	check(
		not (box.left <= centre.X and centre.X <= box.right)
			or not (box.top <= centre.Y and centre.Y <= box.bottom),
		label .. " clear of the centre point"
	)
	check((box.left + box.right) / 2 > centre.X, label .. " in the right half")
end

-- TouchJump's jump button (`ResizeJumpButton`, the branch without avatar abilities): size, then
-- top-left corner, in a TouchControlFrame of `frame` pixels. The other branch applies only when
-- AvatarAbilitiesInterface.isEnabled(): an AbilityManagerActor exists and the Humanoid's
-- EvaluateStateMachine is off. This game uses neither.
local function jumpButton(frame): (any, any)
	local small = math.min(frame.X, frame.Y) <= 500
	local side = if small then 70 else 120
	local offset = if small
		then Vector2.new(-(side * 1.5 - 10), -side - 20)
		else Vector2.new(-(side * 1.5 - 10), -side * 1.75)
	return Vector2.new(side, side), frame + offset
end

-- `touch`: a size a touch screen has, so the measured layout applies too.
local SCREEN_SIZES = {
	{ size = Vector2.new(844, 390), touch = true }, -- phone
	{ size = Vector2.new(667, 375), touch = true }, -- small phone
	{ size = Vector2.new(1024, 768), touch = true }, -- tablet
	{ size = Vector2.new(1366, 1024), touch = true }, -- large tablet
	{ size = Vector2.new(1920, 1080), touch = true }, -- desktop, touch monitor
	{ size = Vector2.new(3840, 2160), touch = false }, -- 4K
	{ size = Vector2.new(320, 240), touch = false }, -- tiny desktop window
}
local BOTTOM_RIGHT = Vector2.new(1, 1)
local function columnButtons(column, space: Space, label: string)
	local square = UDim2.fromOffset(column.size, column.size)
	offCentre(
		rect({ size = square, position = column.corner }, BOTTOM_RIGHT, space),
		space,
		"VIEW " .. label
	)
	local stand = { size = square, position = HudLayout.standPosition(column) }
	offCentre(rect(stand, BOTTOM_RIGHT, space), space, "STAND " .. label)
	for name, placed in HudLayout.podButtons(column) do
		offCentre(rect(placed, BOTTOM_RIGHT, space), space, name .. " " .. label)
	end
end
local layouts = 0
for _, each in SCREEN_SIZES do
	for _, topBar in TOP_BARS do
		local screen = each.size
		local space = {
			area = screen - Vector2.new(0, topBar),
			centre = screen / 2 - Vector2.new(0, topBar),
		}
		local label = string.format("%s top bar %d", tostring(screen), topBar)
		local scope = HudLayout.scopeButtonFallback(screen)
		offCentre(rect(scope, Vector2.new(0.5, 1), space), space, "SCOPE fallback " .. label)
		columnButtons(HudLayout.mechColumnFallback(screen), space, "fallback " .. label)
		layouts += 1
		if each.touch then
			local size, position = jumpButton(space.area)
			local where = "jump button " .. label
			local placed = HudLayout.scopeButton(position, size)
			offCentre(rect(placed, Vector2.new(0.5, 1), space), space, "SCOPE " .. where)
			columnButtons(HudLayout.mechColumn(position, size), space, where)
			layouts += 1
		end
	end
end
equal(layouts, 24, "layouts checked: 7 fallback, 5 measured, two top bars each")

Check.finish()
