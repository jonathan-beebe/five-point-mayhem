-- The map: a mini admin panel below the GOD MODE button. Every player sees it. Players without
-- the map (the server's HasMap attribute) see it locked. The server re-checks HasMap on every
-- command.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)

local MapPanel = {}

local player = Players.LocalPlayer
local rgb = Color3.fromRGB

-- Right-edge column of toggles: GOD MODE on top, MAP below it, open panels below both.
MapPanel.TOGGLE_TOP = 60
MapPanel.TOGGLE_HEIGHT = 40
MapPanel.GAP = 6
MapPanel.PANEL_TOP = MapPanel.TOGGLE_TOP + 2 * (MapPanel.TOGGLE_HEIGHT + MapPanel.GAP)

local PANEL_WIDTH = 300
local PANEL_HEIGHT = 142
local CONFIRM_SECONDS = 3

-- Fires when the map panel opens, so the GOD MODE panel can close and not overlap it.
local openedEvent = Instance.new("BindableEvent")
MapPanel.opened = openedEvent.Event

local panel: Frame? = nil

local function create(
	className: string,
	properties: { [string]: any },
	children: { Instance }?
): any
	local instance = Instance.new(className)
	for key, value in properties do
		(instance :: any)[key] = value
	end
	for _, child in children or {} do
		child.Parent = instance
	end
	return instance
end

local function corner(): UICorner
	return create("UICorner", { CornerRadius = UDim.new(0, 8) })
end

local function hasMap(): boolean
	return player:GetAttribute("HasMap") == true
end

function MapPanel.close()
	if panel then
		panel.Visible = false
	end
end

local function build()
	local gui = create("ScreenGui", {
		Name = "MayhemMap",
		ResetOnSpawn = false,
		DisplayOrder = 15,
		Parent = player:WaitForChild("PlayerGui"),
	})
	local toggle = create("TextButton", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(
			1,
			-12,
			0,
			MapPanel.TOGGLE_TOP + MapPanel.TOGGLE_HEIGHT + MapPanel.GAP
		),
		Size = UDim2.fromOffset(130, MapPanel.TOGGLE_HEIGHT),
		TextSize = 16,
		Font = Enum.Font.LuckiestGuy,
		Parent = gui,
	}, { corner() })

	local frame = create("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, MapPanel.PANEL_TOP),
		Size = UDim2.fromOffset(PANEL_WIDTH, PANEL_HEIGHT),
		BackgroundColor3 = rgb(10, 18, 24),
		BackgroundTransparency = 0.1,
		Visible = false,
		Parent = gui,
	}, { corner(), create("UIStroke", { Color = rgb(80, 190, 255), Thickness = 2 }) })
	panel = frame

	create("TextLabel", {
		Position = UDim2.fromOffset(10, 8),
		Size = UDim2.fromOffset(PANEL_WIDTH - 20, 22),
		BackgroundTransparency = 1,
		Text = "🗺 MAP",
		TextColor3 = rgb(120, 210, 255),
		TextSize = 16,
		Font = Enum.Font.LuckiestGuy,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = frame,
	})

	local sniper = create("TextButton", {
		Position = UDim2.fromOffset(10, 40),
		Size = UDim2.fromOffset(PANEL_WIDTH - 20, 40),
		BackgroundColor3 = rgb(40, 110, 160),
		Text = "🎯 Give me the Sniper Rifle",
		TextColor3 = rgb(255, 255, 255),
		TextSize = 15,
		Font = Enum.Font.GothamBold,
		Parent = frame,
	}, { corner() })
	sniper.Activated:Connect(function()
		if hasMap() then
			Remotes.MapCommand:FireServer("sniper")
		end
	end)

	-- Two taps: the first arms it for CONFIRM_SECONDS, the second fires.
	local NUKE_TEXT = "☢ NUKE SERVER"
	local nuke = create("TextButton", {
		Position = UDim2.fromOffset(10, 88),
		Size = UDim2.fromOffset(PANEL_WIDTH - 20, 40),
		BackgroundColor3 = rgb(200, 20, 30),
		Text = NUKE_TEXT,
		TextColor3 = rgb(255, 255, 255),
		TextSize = 16,
		Font = Enum.Font.LuckiestGuy,
		Parent = frame,
	}, { corner() })
	local armedAt: number? = nil
	nuke.Activated:Connect(function()
		if not hasMap() then
			return
		end
		if armedAt and os.clock() - armedAt < CONFIRM_SECONDS then
			armedAt = nil
			nuke.Text = NUKE_TEXT
			Remotes.MapCommand:FireServer("nuke")
			return
		end
		local stamp = os.clock()
		armedAt = stamp
		nuke.Text = "TAP AGAIN TO NUKE EVERYONE"
		task.delay(CONFIRM_SECONDS, function()
			if armedAt == stamp then
				armedAt = nil
				nuke.Text = NUKE_TEXT
			end
		end)
	end)

	-- Covers the whole panel and swallows taps while the player has no map.
	local lock = create("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = rgb(0, 0, 0),
		BackgroundTransparency = 0.25,
		AutoButtonColor = false,
		Text = "🔒 LOCKED\nAsk an admin for the map",
		TextColor3 = rgb(230, 230, 230),
		TextSize = 16,
		Font = Enum.Font.GothamBold,
		ZIndex = 2,
		Parent = frame,
	}, { corner() })

	local function refresh()
		local unlocked = hasMap()
		lock.Visible = not unlocked
		toggle.Text = if unlocked then "🗺 MAP" else "🔒 MAP"
		toggle.BackgroundColor3 = if unlocked then rgb(80, 190, 255) else rgb(90, 90, 100)
		toggle.TextColor3 = if unlocked then rgb(0, 25, 45) else rgb(200, 200, 200)
	end
	player:GetAttributeChangedSignal("HasMap"):Connect(refresh)
	refresh()

	toggle.Activated:Connect(function()
		frame.Visible = not frame.Visible
		if frame.Visible then
			openedEvent:Fire()
		end
	end)
end

function MapPanel.start()
	build()
end

return MapPanel
