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
--   - the armory: armorySheet in safe areas (margin, the ARMORY_MAX cap, too small); armory against
--     the approved mockups' numbers (phone 932x430 small, tablet 1180x820 large); and its rules
--     over sheets from a small phone to ARMORY_MAX under three screens: the size class follows
--     the screen's shorter side, every element inside the sheet, columns side by side, cells fit
--     the grid, the side column stacks without overlap with deploy last

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
				check(
					not PodButtons.view(state, aboard, canLand, touch, true).droneVisible
						or PodState.inFlight(state),
					label .. ": DRONE only in flight"
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
equal(golden.drone.size, UDim2.fromOffset(50, 50), "DRONE one slot")
equal(golden.drone.position, UDim2.fromOffset(700, 340), "DRONE above VIEW, right of ▲")
local desk = HudLayout.podButtons(HudLayout.mechColumnFallback(Vector2.new(1000, 800)))
equal(desk.pod.size, UDim2.fromOffset(380, 78), "fallback pod button size")
equal(desk.pod.position, UDim2.new(0.85, 134, 0.95, -268), "fallback pod button above ▲")
equal(desk.land.position, UDim2.new(0.85, 134, 0.95, 0), "fallback LAND in STAND's slot")
equal(desk.drone.position, UDim2.new(0.85, 0, 0.95, -134), "fallback DRONE above VIEW")

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
equal(smallDrawer.width, 340, "small: drawer width")
equal(HudLayout.sizes(SMALL_AREA).toggle, Vector2.new(56, 56), "small toggle")
equal(HudLayout.sizes(SMALL_AREA).status, Vector2.new(236, 40), "small status")
equal(HudLayout.railToggle(LARGE_AREA, 0), UDim2.new(1, -12, 0, 12), "large: GOD in corner")
equal(HudLayout.railToggle(LARGE_AREA, 1), UDim2.new(1, -12, 0, 76), "large: MAC under GOD")
equal(HudLayout.statusPosition(LARGE_AREA), UDim2.new(1, -240, 0, 12), "large: status left")
local largeDrawer = HudLayout.drawer(LARGE_AREA)
equal(largeDrawer.position, UDim2.new(1, -240, 0, 12), "large: drawer left of the rail")
equal(largeDrawer.height, 740, "large: drawer down to the bottom margin")
equal(largeDrawer.width, 420, "large: drawer width")
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
-- (VIEW and SCOPE in the camera slot, STAND, and PodControls' pod, LAND, ▲, ▼ and DRONE) stays
-- inside its gui, clear of the screen's centre point, in the right half and in the lower half of
-- the screen, and DRONE overlaps none of the others nor the jump button, laid out two ways:
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
local function overlaps(a, b): boolean
	return a.left < b.right and b.left < a.right and a.top < b.bottom and b.top < a.bottom
end
local function columnButtons(column, space: Space, label: string, jump: any?)
	local square = UDim2.fromOffset(column.size, column.size)
	local view = rect({ size = square, position = column.corner }, BOTTOM_RIGHT, space)
	offCentre(view, space, "VIEW " .. label)
	local stand = { size = square, position = HudLayout.standPosition(column) }
	offCentre(rect(stand, BOTTOM_RIGHT, space), space, "STAND " .. label)
	local others = { VIEW = view, STAND = rect(stand, BOTTOM_RIGHT, space), jump = jump }
	local pod = HudLayout.podButtons(column)
	for name, placed in pod do
		local box = rect(placed, BOTTOM_RIGHT, space)
		offCentre(box, space, name .. " " .. label)
		if name ~= "drone" then
			others[name] = box
		end
	end
	local drone = rect(pod.drone, BOTTOM_RIGHT, space)
	for name, box in others do
		check(not overlaps(drone, box), "drone clear of " .. name .. " " .. label)
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
			local jump = {
				left = position.X,
				top = position.Y,
				right = position.X + size.X,
				bottom = position.Y + size.Y,
			}
			columnButtons(HudLayout.mechColumn(position, size), space, where, jump)
			layouts += 1
		end
	end
end
equal(layouts, 24, "layouts checked: 7 fallback, 5 measured, two top bars each")

-- Armory ------------------------------------------------------------------------------------------

Check.section("armory sheet")
local function sameRect(got, x: number, y: number, w: number, h: number, label: string)
	equal(
		string.format("%g,%g %gx%g", got.x, got.y, got.w, got.h),
		string.format("%g,%g %gx%g", x, y, w, h),
		label
	)
end
sameRect(HudLayout.armorySheet(Vector2.new(1180, 750), 12), 12, 12, 1156, 726, "tablet area")
sameRect(HudLayout.armorySheet(Vector2.new(800, 360), 12), 12, 12, 776, 336, "phone area")
sameRect(
	HudLayout.armorySheet(Vector2.new(1920, 1022), 12),
	320,
	81,
	1280,
	860,
	"desktop: at most ARMORY_MAX, centred"
)
sameRect(HudLayout.armorySheet(Vector2.new(10, 10), 12), 5, 5, 0, 0, "area smaller than margins")

-- The approved mockups (Phone-Armory and Tablet-Armory, CSS px at the device's point size).
local COUNTS = { categories = 7, slots = 3, teams = 5 }
Check.section("armory: phone mockup (932x430, sheet 771x346)")
local phoneArmory = HudLayout.armory(Vector2.new(771, 346), Vector2.new(932, 430), COUNTS)
equal(phoneArmory.small, true, "small class")
sameRect(phoneArmory.look, 609, 12, 150, 44, "Look around")
sameRect(phoneArmory.category, 12, 66, 96, 36, "first category")
equal(phoneArmory.categoryStep, 38, "category step")
sameRect(phoneArmory.grid, 118, 66, 435, 268, "grid")
equal(phoneArmory.columns, 3, "grid columns")
equal(phoneArmory.cell, Vector2.new(136, 78), "card size")
equal(phoneArmory.card.description.h, 0, "no description")
sameRect(phoneArmory.loadoutLabel, 563, 66, 196, 12, "LOADOUT label: side column 196 wide")
equal(phoneArmory.deploy.y + phoneArmory.deploy.h, 346 - 12, "deploy at the bottom")
equal(phoneArmory.deploy.x + phoneArmory.deploy.w, 771 - 12, "deploy at the right")
equal(phoneArmory.teamStep.Y, 0, "teams as dots in a row")
equal(phoneArmory.team.w, phoneArmory.team.h, "dots are round")

Check.section("armory: tablet mockup (1180x820, sheet 1148x734)")
local tablet = HudLayout.armory(Vector2.new(1148, 734), Vector2.new(1180, 820), COUNTS)
equal(tablet.small, false, "large class")
sameRect(tablet.look, 958, 22, 170, 48, "Look around")
sameRect(tablet.category, 20, 88, 140, 48, "first category")
sameRect(tablet.grid, 176, 88, 656, 626, "grid")
equal(tablet.columns, 4, "grid columns")
equal(tablet.cell, Vector2.new(152, 124), "card size")
check(tablet.card.description.h >= 3 * 11, "description: three lines or more")
sameRect(tablet.slot, 848, 112, 280, 48, "first slot: full size")
sameRect(tablet.teamLabel, 848, 290, 280, 16, "TEAM label")
sameRect(tablet.team, 848, 314, 280, 44, "first team row: full size")
equal(tablet.teamStep, Vector2.new(0, 52), "team rows down")
equal(tablet.teamName.h, 0, "no team name line")
sameRect(tablet.deploy, 848, 642, 280, 72, "deploy: full size, bottom right")

-- Rules over sheets from a small phoneArmory to the largest sheet, both size classes.
Check.section("armory: inside the sheet, no overlaps")
local function inside(box, sheet: Vector2): boolean
	return box.x >= 0 and box.y >= 0 and box.x + box.w <= sheet.X and box.y + box.h <= sheet.Y
end
local function shifted(box, step: Vector2, index: number)
	return {
		x = box.x + step.X * (index - 1),
		y = box.y + step.Y * (index - 1),
		w = box.w,
		h = box.h,
	}
end
local SHEETS = {
	Vector2.new(560, 260),
	Vector2.new(643, 293),
	Vector2.new(771, 346),
	Vector2.new(820, 520),
	Vector2.new(1000, 600),
	Vector2.new(1148, 734),
	Vector2.new(1280, 860),
}
local SCREENS_FOR = { Vector2.new(667, 375), Vector2.new(932, 430), Vector2.new(1180, 820) }
local armories = 0
for _, sheet in SHEETS do
	for _, screen in SCREENS_FOR do
		local a = HudLayout.armory(sheet, screen, COUNTS)
		local s = a.sizes
		local where = string.format("sheet %s screen %s", tostring(sheet), tostring(screen))
		armories += 1
		equal(a.small, math.min(screen.X, screen.Y) <= 500, "size class " .. where)
		local rects = {
			title = a.title,
			counter = a.counter,
			look = a.look,
			grid = a.grid,
			loadout = a.loadoutLabel,
			teamLabel = a.teamLabel,
			teamName = a.teamName,
			deploy = a.deploy,
			lastCategory = shifted(a.category, Vector2.new(0, a.categoryStep), COUNTS.categories),
			lastSlot = shifted(a.slot, Vector2.new(0, a.slotStep), COUNTS.slots),
			lastTeam = shifted(a.team, a.teamStep, COUNTS.teams),
		}
		for name, box in rects do
			check(inside(box, sheet), name .. " inside the sheet, " .. where)
		end
		-- Columns side by side; header above the body.
		check(a.category.x + a.category.w < a.grid.x, "categories left of the grid, " .. where)
		check(a.grid.x + a.grid.w < a.loadoutLabel.x, "grid left of the side column, " .. where)
		check(a.look.y + a.look.h <= a.grid.y, "header above the body, " .. where)
		check(a.title.x + a.title.w < a.look.x, "title left of Look around, " .. where)
		-- The grid's cells fit its inner width.
		local inner = a.grid.w - s.scrollBar - s.cardStroke * 2
		check(
			a.columns * a.cell.X + (a.columns - 1) * s.cardGap <= inner,
			"cells fit the grid, " .. where
		)
		check(a.columns >= 1 and a.columns <= s.columns, "columns within the class's, " .. where)
		-- The side column stacks down without overlap; deploy last.
		local lastSlot, lastTeam = rects.lastSlot, rects.lastTeam
		check(a.loadoutLabel.y + a.loadoutLabel.h <= a.slot.y, "LOADOUT above slots, " .. where)
		check(lastSlot.y + lastSlot.h <= a.teamLabel.y, "slots above TEAM, " .. where)
		check(a.teamLabel.y + a.teamLabel.h <= a.team.y, "TEAM above the teams, " .. where)
		local teamsBottom = math.max(lastTeam.y + lastTeam.h, a.teamName.y + a.teamName.h)
		check(teamsBottom <= a.deploy.y, "teams above deploy, " .. where)
		check(a.deploy.h > 0 and a.slot.h > 0 and a.team.h > 0, "rows keep a size, " .. where)
	end
end
equal(armories, 21, "armory layouts checked: 7 sheets, 3 screens")

Check.finish()
