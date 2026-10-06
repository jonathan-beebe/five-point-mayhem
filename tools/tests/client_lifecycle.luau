-- Checks the client lifecycle of LobbyUI and Announcer outside Roblox: requiring them builds no UI
-- (init.client.luau requires every module before it isolates each start(), so an error at require
-- time would stop the whole client), start() builds it, and Announcer.show works before
-- Announcer.start (LobbyUI calls it).
-- Usage: lune run tools/tests/client_lifecycle.luau
--
--   - requiring both creates no Instance and parents nothing to PlayerGui
--   - Announcer.show before start builds the banner once and shows the text; start does not build
--     a second gui and wires the Announce remote
--   - LobbyUI.start builds the armory; the tree each module builds equals the tree the code before
--     this change built through the same calls (fingerprints pinned below, taken from that code at
--     commit 9205477, where both modules built their UI at require time)
--
-- Lune instances have no events: every Instance.new returns a proxy over a real Lune instance whose
-- missing members (Activated, GetPropertyChangedSignal, ...) are stand-in signals. Services,
-- the local player and the remotes are stand-ins.

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
			if not ok then
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
local SERVICES: { [string]: any } = {
	Players = { LocalPlayer = player },
	Teams = { ChildAdded = signal() },
	Workspace = {
		CurrentCamera = {
			ViewportSize = Vector2.new(1280, 720),
			GetPropertyChangedSignal = function()
				return signal()
			end,
		},
	},
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
	return (string.gsub(text, "^%d+ weapons in the armory", "N weapons in the armory"))
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
local lobbies = guisNamed("MayhemLobby")
equal(#lobbies, 1, "start builds one lobby gui")
attributes.Deployed = true
attributeSignals.Deployed:Fire()
equal(banner and banner.Text, "GO! Run out through any glowing gate!", "deploy announces")

Check.section("same trees as the code before")
-- Fingerprints of each gui after the calls above (lines, FNV-1a), from the code at 9205477.
local PINNED = {
	MayhemAnnouncer = { lines = 3, hash = 1879087032 },
	MayhemLobby = { lines = 69, hash = 122058355 },
}
for name, want in PINNED do
	local gui = guisNamed(name)[1]
	if gui then
		local lines, hash, cards = fingerprint(gui)
		print(string.format("  %s: %d lines, hash %d", name, lines, hash))
		equal(lines, want.lines, name .. " instance count")
		equal(hash, want.hash, name .. " tree fingerprint")
		if name == "MayhemLobby" then
			equal(cards, #WeaponCatalog.ALL, "a card per weapon")
		end
	end
end

Check.finish()
