-- Checks the client lifecycle of LobbyUI and Announcer outside Roblox: requiring them builds no UI
-- (init.client.luau requires every module before it isolates each start(), so an error at require
-- time would stop the whole client), start() builds it, and Announcer.show works before
-- Announcer.start (LobbyUI calls it).
-- Usage: lune run tools/tests/client_lifecycle.luau
--
--   - requiring both creates no Instance and parents nothing to PlayerGui
--   - Announcer.show before start builds the banner once and shows the text; start does not build
--     a second gui and wires the Announce remote
--   - LobbyUI.start builds two guis: MayhemLobby (CHOOSE WEAPONS) and MayhemArmory (the sheet, in
--     the safe area); the tree each module builds equals a pinned fingerprint: Announcer's from the
--     code at commit 9205477, where it built its UI at require time; LobbyUI's from the armory
--     sheet (feat/armory-sheet), a deliberate re-pin: the design replaced the fixed panel
--   - the sheet re-lays out on a viewport change: large class at 1280x720 (descriptions, team
--     rows), small at 932x430 (compact cards, team dots and the chosen team's name)
--
-- Lune instances have no events: every Instance.new returns a proxy over a real Lune instance whose
-- missing members (Activated, GetPropertyChangedSignal, ...) are stand-in signals. Services,
-- the local player, the camera and the remotes are stand-ins. Lune has no layout: AbsoluteSize
-- reads zero, so LobbyUI lays out from the viewport.

local roblox = require("@lune/roblox")

local Check = require("../lib/Check")
local Sandbox = require("../lib/Sandbox")

local check, equal = Check.check, Check.equal
local RealInstance = roblox.Instance
local Vector2 = roblox.Vector2

Check.printLimit = 10

-- Stand-ins ---------------------------------------------------------------------------------------

-- A signal that records handlers; calling it (as GetPropertyChangedSignal(name)) gives another.
local function signal(): any
	local handlers = {}
	local self = {}
	function self.Connect(_, handler)
		table.insert(handlers, handler)
		return { Disconnect = function() end }
	end
	function self.Fire(_, ...)
		for _, handler in handlers do
			handler(...)
		end
	end
	return setmetatable(self, {
		__call = function()
			return signal()
		end,
	})
end

-- Lune instances behind proxies: properties and methods go to the real instance (proxies passed in
-- are unwrapped), a member Lune does not have is a stand-in signal.
local realOf: { [any]: any } = setmetatable({}, { __mode = "k" }) :: any
local created = 0

local function unwrap(value: any): any
	return realOf[value] or value
end

local function wrap(real: any): any
	local signals = {}
	local proxy = setmetatable({}, {
		__index = function(_, key)
			local ok, value = pcall(function()
				return real[key]
			end)
			if not ok and key == "AbsoluteSize" then
				return Vector2.zero -- Lune has no layout: Roblox's value before the first render
			elseif not ok then
				signals[key] = signals[key] or signal()
				return signals[key]
			end
			if type(value) == "function" then
				return function(_, ...)
					local args = table.pack(...)
					for index = 1, args.n do
						args[index] = unwrap(args[index])
					end
					return value(real, table.unpack(args, 1, args.n))
				end
			end
			return value
		end,
		__newindex = function(_, key, value)
			real[key] = unwrap(value)
		end,
	})
	realOf[proxy] = real
	return proxy
end

local playerGui = RealInstance.new("PlayerGui")
local attributes: { [string]: any } = {}
local attributeSignals: { [string]: any } = {}
local player = {
	Team = nil,
	Character = nil,
	CharacterAdded = signal(),
	GetAttribute = function(_, name: string)
		return attributes[name]
	end,
	GetAttributeChangedSignal = function(_, name: string)
		attributeSignals[name] = attributeSignals[name] or signal()
		return attributeSignals[name]
	end,
	GetPropertyChangedSignal = function()
		return signal()
	end,
	WaitForChild = function(_, name: string)
		assert(name == "PlayerGui", "player:WaitForChild " .. name)
		return playerGui
	end,
}

local remotes: { [string]: any } = {}
local remoteFolder = {
	WaitForChild = function(_, name: string)
		remotes[name] = remotes[name]
			or {
				Name = name,
				OnClientEvent = signal(),
				FireServer = function() end,
			}
		return remotes[name]
	end,
}

local tweens = 0
local viewportChanged = signal()
local camera = {
	ViewportSize = Vector2.new(1280, 720),
	GetPropertyChangedSignal = function(_, name: string)
		assert(name == "ViewportSize", "camera:GetPropertyChangedSignal " .. name)
		return viewportChanged
	end,
}
local SERVICES: { [string]: any } = {
	Players = { LocalPlayer = player },
	Teams = { ChildAdded = signal() },
	Workspace = { CurrentCamera = camera },
	TweenService = {
		Create = function()
			tweens += 1
			return { Play = function() end, Cancel = function() end, Completed = signal() }
		end,
	},
	RunService = {
		IsServer = function()
			return false
		end,
	},
	ReplicatedStorage = {
		Shared = Sandbox.game:GetService("ReplicatedStorage").Shared,
		WaitForChild = function(_, name: string)
			assert(name == "Remotes", "ReplicatedStorage:WaitForChild " .. name)
			return remoteFolder
		end,
	},
}

local delays: { { seconds: number, callback: () -> () } } = {}
Sandbox.globals.game = {
	GetService = function(_, name: string)
		return assert(SERVICES[name], "no stand-in for service " .. name)
	end,
}
Sandbox.globals.Instance = {
	new = function(className: string)
		created += 1
		return wrap(RealInstance.new(className))
	end,
}
Sandbox.globals.task = {
	delay = function(seconds: number, callback: () -> ())
		table.insert(delays, { seconds = seconds, callback = callback })
	end,
}

-- Tree fingerprints -------------------------------------------------------------------------------

local PROPERTIES = {
	"ClassName",
	"Name",
	"AnchorPoint",
	"Position",
	"Size",
	"BackgroundColor3",
	"BackgroundTransparency",
	"BorderSizePixel",
	"Visible",
	"ZIndex",
	"LayoutOrder",
	"AutoButtonColor",
	"Text",
	"TextColor3",
	"TextSize",
	"TextScaled",
	"TextWrapped",
	"TextXAlignment",
	"TextYAlignment",
	"TextTruncate",
	"TextTransparency",
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
	"CellSize",
	"CellPadding",
	"SortOrder",
	"FillDirection",
	"Scale",
	"DisplayOrder",
	"ResetOnSpawn",
	"IgnoreGuiInset",
	"ZIndexBehavior",
}

-- What a weapon card shows from the catalog: its texts and its colours (category tint, weapon
-- colour). Normalised in the card the fingerprint keeps, so the catalog's contents do not count.
local FROM_CATALOG = { Text = true, BackgroundColor3 = true }

local function read(instance: any, property: string, card: boolean?): string
	local ok, value = pcall(function()
		return instance[property]
	end)
	if not ok then
		return "<none>"
	end
	if card and FROM_CATALOG[property] then
		return "<catalog>"
	end
	local text = tostring(value)
	-- The armory counter names the catalog's size: a new weapon is not a layout change.
	return (string.gsub(text, "^%d+ weapons ·", "N weapons ·"))
end

-- One line per instance, depth first. The weapon cards (TextButtons in the grid) are counted; the
-- first is listed with FROM_CATALOG normalised, the rest are not: a card's layout is this test's
-- subject, the catalog's contents are not.
local function dump(
	instance: any,
	depth: number,
	lines: { string },
	cards: { number },
	card: boolean?
)
	local values = {}
	for _, property in PROPERTIES do
		table.insert(values, property .. "=" .. read(instance, property, card))
	end
	table.insert(lines, string.rep(" ", depth) .. table.concat(values, ";"))
	for _, child in instance:GetChildren() do
		if instance.ClassName == "ScrollingFrame" and child.ClassName == "TextButton" then
			cards[1] += 1
			if cards[1] == 1 then
				dump(child, depth + 1, lines, cards, true)
			end
		else
			dump(child, depth + 1, lines, cards, card)
		end
	end
end

-- FNV-1a over the dump, 32 bits.
local function fnv(text: string): number
	local hash = 2166136261
	for index = 1, #text do
		hash = bit32.bxor(hash, string.byte(text, index))
		hash = (hash * 16777619) % 4294967296
	end
	return hash
end

local function fingerprint(gui: any): (number, number, number)
	local lines, cards = {}, { 0 }
	dump(gui, 0, lines, cards)
	return #lines, fnv(table.concat(lines, "\n")), cards[1]
end

local function guisNamed(name: string): { any }
	local found = {}
	for _, child in playerGui:GetChildren() do
		if child.Name == name then
			table.insert(found, child)
		end
	end
	return found
end

-- Require -----------------------------------------------------------------------------------------

Check.section("require builds nothing")
local Remotes = Sandbox.require(Sandbox.game:GetService("ReplicatedStorage").Shared.Remotes)
local WeaponCatalog =
	Sandbox.require(Sandbox.game:GetService("ReplicatedStorage").Shared.WeaponCatalog)
local Announcer = Sandbox.require("src/client/Announcer")
local LobbyUI = Sandbox.require("src/client/LobbyUI")
check(Remotes.Announce ~= nil, "stand-in remotes load")
equal(created, 0, "instances created by requiring Announcer and LobbyUI")
equal(#playerGui:GetChildren(), 0, "guis in PlayerGui after require")

-- Announcer ---------------------------------------------------------------------------------------

Check.section("Announcer.show before start")
local ok, problem = pcall(Announcer.show, "TOO MANY", nil, 2)
check(ok, "show before start runs: " .. tostring(problem))
local announcers = guisNamed("MayhemAnnouncer")
equal(#announcers, 1, "show builds one announcer gui")
local banner = announcers[1] and announcers[1]:FindFirstChildOfClass("TextLabel")
equal(banner and banner.Text, "TOO MANY", "banner text")
equal(banner and banner.Visible, true, "banner shown")
equal(#delays, 1, "one fade scheduled")
Announcer.show("AGAIN")
equal(#guisNamed("MayhemAnnouncer"), 1, "a second show reuses the gui")

Check.section("Announcer.start")
Announcer.start()
equal(#guisNamed("MayhemAnnouncer"), 1, "start after show reuses the gui")
remotes.Announce.OnClientEvent:Fire("FROM SERVER", nil, 1, nil)
equal(banner and banner.Text, "FROM SERVER", "start wires the Announce remote")

-- LobbyUI -----------------------------------------------------------------------------------------

Check.section("LobbyUI.start")
LobbyUI.start()
equal(#guisNamed("MayhemLobby"), 1, "start builds one lobby gui (CHOOSE WEAPONS)")
local armories = guisNamed("MayhemArmory")
equal(#armories, 1, "start builds one armory gui (the sheet)")
local armory = armories[1]
equal(
	armory and armory.ScreenInsets,
	roblox.Enum.ScreenInsets.CoreUISafeInsets,
	"the sheet's gui keeps to the safe area"
)
attributes.Deployed = true
attributeSignals.Deployed:Fire()
equal(banner and banner.Text, "GO! Run out through any glowing gate!", "deploy announces")

Check.section("same trees as pinned")
-- Fingerprints of each gui after the calls above (lines, FNV-1a): Announcer's from the code at
-- 9205477; LobbyUI's from the armory sheet (feat/armory-sheet), laid out at 1280x720 (large).
local PINNED = {
	MayhemAnnouncer = { lines = 3, hash = 1879087032 },
	MayhemLobby = { lines = 4, hash = 440393528 },
	MayhemArmory = { lines = 80, hash = 1108460872 },
}
for name, want in PINNED do
	local gui = guisNamed(name)[1]
	if gui then
		local lines, hash, cards = fingerprint(gui)
		print(string.format("  %s: %d lines, hash %d", name, lines, hash))
		equal(lines, want.lines, name .. " instance count")
		equal(hash, want.hash, name .. " tree fingerprint")
		if name == "MayhemArmory" then
			equal(cards, #WeaponCatalog.ALL, "a card per weapon")
		end
	end
end

-- The sheet's elements by what they show.
local function find(root: any, predicate: (any) -> boolean): any
	for _, each in root:GetDescendants() do
		if predicate(each) then
			return each
		end
	end
	return nil
end
local function textIs(text: string): (any) -> boolean
	return function(each)
		return each:IsA("TextLabel") and (each :: any).Text == text
	end
end

Check.section("size classes")
local sheet = armory and armory:FindFirstChildOfClass("Frame")
local gridFrame = sheet and sheet:FindFirstChildOfClass("ScrollingFrame")
local gridLayout = gridFrame and gridFrame:FindFirstChildOfClass("UIGridLayout")
local description = gridFrame
	and find(gridFrame, function(each)
		return each.Name == "Description"
	end)
local teamLine = sheet and find(sheet, textIs("Tap a colour to pick"))
check(sheet ~= nil and gridLayout ~= nil and description ~= nil, "sheet, grid and a card found")
if sheet and gridLayout and description and teamLine then
	-- Large (1280x720): the sheet fills the viewport less 12; 4 columns; descriptions; team rows.
	equal(sheet.Size, roblox.UDim2.fromOffset(1256, 696), "large: sheet size")
	equal(sheet.Position, roblox.UDim2.fromOffset(12, 12), "large: sheet position")
	equal(description.Visible, true, "large: card descriptions shown")
	equal(teamLine.Visible, false, "large: no team name line (named rows)")
	local largeCell = gridLayout.CellSize

	-- Small (932x430, the phone mockup): re-laid out on the viewport change.
	camera.ViewportSize = Vector2.new(932, 430)
	viewportChanged:Fire()
	equal(sheet.Size, roblox.UDim2.fromOffset(908, 406), "small: sheet size")
	equal(description.Visible, false, "small: compact cards")
	equal(teamLine.Visible, true, "small: the chosen team's name under the dots")
	equal(gridLayout.CellSize.Y.Offset, 78, "small: card height")
	check(gridLayout.CellSize ~= largeCell, "small: cell size changed")
end

Check.finish()
