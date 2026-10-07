-- Checks src/shared/HudLayout.luau outside Roblox.
-- Usage: lune run tools/tests/hud_layout.luau
--
--   - mechColumn's slot size, gap and camera slot give the same bits as the inline code it
--     replaced (copied below as the reference, compiled with luau.load as Sandbox compiles
--     HudLayout), over jump button sizes and positions (zero, fractional, phone to tablet)
--   - golden values where the layout changed on purpose (the HUD zones redesign): the seat slot,
--     the fallback cluster, PodControls' buttons, the system rail, the vehicle status, the drawer
--     and the prompt stack, per size class
--   - rules: the rail and drawer line up, the status sits clear of the rail, the prompt stack
--     stays above STACK_SHARE of the height and left of the centre, and every touch button stays
--     in the lower right, clear of the screen centre, on phone, tablet and desktop screens

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

-- MechCamera.luau `layoutButton`: VIEW's slot (STAND moved since: golden values below).
function Reference.mech(jump)
	local size = math.floor(math.min(jump.AbsoluteSize.X, jump.AbsoluteSize.Y) * 0.8)
	local gap = math.floor(jump.AbsoluteSize.X * 0.15)
	local corner = UDim2.fromOffset(
		jump.AbsolutePosition.X - gap,
		jump.AbsolutePosition.Y + jump.AbsoluteSize.Y
	)
	return { size = size, gap = gap, corner = corner }
end

return Reference
]],
	{ debugName = "HudLayout reference", environment = { UDim2 = UDim2, math = math } }
)()

-- mechColumn's slot size, gap and camera slot, with the same inputs and outputs as Reference.
local function nowMech(jump)
	local column = HudLayout.mechColumn(jump.AbsolutePosition, jump.AbsoluteSize)
	return { size = column.size, gap = column.gap, corner = column.corner }
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
	sameResult(nowMech(jump), Reference.mech(jump), "mech " .. describe(jump))
end

-- The seat slot (STAND, LAND): directly above the jump button, centred on it, a gap above it.
Check.section("seat slot")
for _, jump in jumps do
	local column = HudLayout.mechColumn(jump.AbsolutePosition, jump.AbsoluteSize)
	local seat = HudLayout.standPosition(column)
	local centre = jump.AbsolutePosition.X + jump.AbsoluteSize.X / 2
	local label = "seat " .. describe(jump)
	check(
		math.abs(seat.X.Offset - column.size / 2 - centre) < 1,
		label .. ": centred on the jump button"
	)
	local above = UDim2.fromOffset(0, jump.AbsolutePosition.Y - column.gap)
	equal(seat.Y.Offset, above.Y.Offset, label .. ": a gap above jump")
	check(seat.X.Scale == 0 and seat.Y.Scale == 0, label .. ": in pixels")
end
for _, viewport in VIEWPORTS do
	local column = HudLayout.mechColumnFallback(viewport)
	equal(
		HudLayout.standPosition(column),
		column.corner + UDim2.fromOffset(column.size + column.gap, 0),
		"fallback seat " .. tostring(viewport) .. ": a gap right of the camera slot"
	)
end
-- A phone's jump button (70 at 749, 242 in an 844 x 332 area).
local phone = HudLayout.mechColumn(Vector2.new(749, 242), Vector2.new(70, 70))
equal(phone.size, 56, "phone slot side")
equal(phone.gap, 10, "phone gap")
equal(phone.corner, UDim2.fromOffset(739, 312), "phone camera slot left of jump")
equal(phone.seat, UDim2.fromOffset(812, 232), "phone seat slot above jump")

-- Without a jump button: sides 14% of the short side, gaps 20% of a side, the camera slot's
-- corner at 85% across and 95% down, the seat slot in the jump button's place right of it.
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
		UDim2.new(0.85, case.size + case.gap, 0.95, 0),
		label .. " STAND right of VIEW"
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
local golden = HudLayout.podButtons({
	size = 50,
	gap = 10,
	corner = UDim2.fromOffset(700, 400),
	seat = UDim2.fromOffset(785, 330),
})
equal(golden.pod.size, UDim2.fromOffset(195, 35), "pod button spans ▲ to the seat slot")
equal(golden.pod.position, UDim2.fromOffset(785, 270), "pod button a gap above the seat slot")
equal(golden.land.size, UDim2.fromOffset(50, 50), "LAND one slot")
equal(golden.land.position, UDim2.fromOffset(785, 330), "LAND in STAND's slot")
equal(golden.up.position, UDim2.fromOffset(640, 340), "▲ above ▼")
equal(golden.down.position, UDim2.fromOffset(640, 400), "▼ left of VIEW")
local desk = HudLayout.podButtons(HudLayout.mechColumnFallback(Vector2.new(1000, 800)))
equal(desk.pod.size, UDim2.fromOffset(380, 78), "fallback pod button size")
equal(desk.pod.position, UDim2.new(0.85, 134, 0.95, -268), "fallback pod button above ▲")
equal(desk.land.position, UDim2.new(0.85, 134, 0.95, 0), "fallback LAND in STAND's slot")

-- The top right: the vehicle status, the system rail and the drawer, per size class.
Check.section("system rail")
local SMALL_AREA, LARGE_AREA = Vector2.new(844, 332), Vector2.new(1180, 764)
check(HudLayout.isSmall(SMALL_AREA), "a phone is small")
check(not HudLayout.isSmall(LARGE_AREA), "a tablet is large")
check(HudLayout.isSmall(Vector2.new(500, 900)), "a short side of 500 is small")
check(not HudLayout.isSmall(Vector2.new(501, 501)), "a short side of 501 is large")
equal(HudLayout.railToggle(SMALL_AREA, 0), UDim2.new(1, -12, 0, 60), "small: GOD under status")
equal(HudLayout.railToggle(SMALL_AREA, 1), UDim2.new(1, -12, 0, 124), "small: MAC under GOD")
equal(HudLayout.statusPosition(SMALL_AREA), UDim2.new(1, -12, 0, 12), "small: status in corner")
local smallDrawer = HudLayout.drawer(SMALL_AREA)
equal(smallDrawer.position, UDim2.new(1, -76, 0, 60), "small: drawer left of the rail")
equal(smallDrawer.height, 260, "small: drawer down to the bottom margin")
equal(HudLayout.sizes(SMALL_AREA).toggle, Vector2.new(56, 56), "small toggle")
equal(HudLayout.sizes(SMALL_AREA).status, Vector2.new(236, 40), "small status")
equal(HudLayout.railToggle(LARGE_AREA, 0), UDim2.new(1, -12, 0, 12), "large: GOD in corner")
equal(HudLayout.railToggle(LARGE_AREA, 1), UDim2.new(1, -12, 0, 76), "large: MAC under GOD")
equal(HudLayout.statusPosition(LARGE_AREA), UDim2.new(1, -240, 0, 12), "large: status left")
local largeDrawer = HudLayout.drawer(LARGE_AREA)
equal(largeDrawer.position, UDim2.new(1, -240, 0, 12), "large: drawer left of the rail")
equal(largeDrawer.height, 740, "large: drawer down to the bottom margin")
equal(HudLayout.sizes(LARGE_AREA).toggle, Vector2.new(220, 56), "large toggle")
equal(HudLayout.sizes(LARGE_AREA).status, Vector2.new(300, 48), "large status")
equal(HudLayout.drawer(Vector2.new(400, 20)).height, 0, "a drawer never has negative height")
for _, area in { SMALL_AREA, LARGE_AREA, Vector2.new(667, 317), Vector2.new(1920, 1022) } do
	local label = "area " .. tostring(area)
	local sizes = HudLayout.sizes(area)
	local first = HudLayout.railToggle(area, 0)
	local drawer = HudLayout.drawer(area)
	equal(drawer.position.Y.Offset, first.Y.Offset, label .. ": drawer top-aligned with the rail")
	equal(
		-drawer.position.X.Offset,
		-first.X.Offset + sizes.toggle.X + HudLayout.GAP,
		label .. ": drawer a gap left of the rail"
	)
	local status = HudLayout.statusPosition(area)
	local clear = status.Y.Offset + sizes.status.Y + HudLayout.GAP <= first.Y.Offset
		or -status.X.Offset >= -first.X.Offset + sizes.toggle.X + HudLayout.GAP
	check(clear, label .. ": status clear of the rail")
end

-- The top left: the prompt stack, per size class.
Check.section("prompt stack")
for _, case in
	{
		{ area = SMALL_AREA, count = 1, width = 236, height = 52 },
		{ area = SMALL_AREA, count = 2, width = 236, height = 52 },
		{ area = SMALL_AREA, count = 3, width = 236, height = 40 },
		{ area = SMALL_AREA, count = 7, width = 236, height = 28 },
		{ area = LARGE_AREA, count = 3, width = 300, height = 64 },
		{ area = Vector2.new(640, 40), count = 1, width = 236, height = 52 },
	}
do
	local stack = HudLayout.promptStack(case.area, case.count, 28)
	local label = string.format("stack %s count %d", tostring(case.area), case.count)
	equal(stack.left, 12, label .. " left")
	equal(stack.top, 12, label .. " top")
	equal(stack.width, case.width, label .. " width")
	equal(stack.height, case.height, label .. " height")
end
for _, area in { SMALL_AREA, LARGE_AREA, Vector2.new(667, 317), Vector2.new(1920, 1022) } do
	for count = 1, 7 do
		local stack = HudLayout.promptStack(area, count, 28)
		local label = string.format("stack %s count %d", tostring(area), count)
		local bottom = HudLayout.cardTop(stack, HudLayout.GAP, count) + stack.height
		check(
			stack.height == 28 or bottom <= area.Y * HudLayout.STACK_SHARE,
			label .. ": ends above the thumbstick"
		)
		check(stack.left + stack.width < area.X / 2, label .. ": left of the centre")
	end
end
equal(HudLayout.cardTop({ top = 10, height = 40 }, 6, 3), 102, "third card's top")
local insides = HudLayout.cardInsides(48, 220)
equal(insides.margin, 7, "card margin")
equal(insides.side, 34, "badge side")
equal(insides.textWidth, 220 - 48 - 7, "text width")

-- Persistent HUD never sits at the screen centre (CLAUDE.md UI rules). Every touch button
-- (VIEW and SCOPE in the camera slot, STAND, and PodControls' pod, LAND, ▲ and ▼) stays inside its
-- gui, clear of the
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
		columnButtons(HudLayout.mechColumnFallback(screen), space, "fallback " .. label)
		layouts += 1
		if each.touch then
			local size, position = jumpButton(space.area)
			local where = "jump button " .. label
			columnButtons(HudLayout.mechColumn(position, size), space, where)
			layouts += 1
		end
	end
end
equal(layouts, 24, "layouts checked: 7 fallback, 5 measured, two top bars each")

Check.finish()
