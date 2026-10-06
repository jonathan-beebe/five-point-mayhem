-- The MAC (mini admin console): a panel below the GOD MODE button. Every player sees it. Players
-- without the MAC (the server's HasMac attribute) see it locked. The server re-checks HasMac on every
-- command.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)

local MacPanel = {}

local player = Players.LocalPlayer
local rgb = Color3.fromRGB

-- Right-edge column of toggles: GOD MODE on top, MAC below it, open panels below both.
MacPanel.TOGGLE_TOP = 60
MacPanel.TOGGLE_HEIGHT = 40
MacPanel.GAP = 6
MacPanel.PANEL_TOP = MacPanel.TOGGLE_TOP + 2 * (MacPanel.TOGGLE_HEIGHT + MacPanel.GAP)

-- Measured by PromptPanel, which stacks prompts under the MAC button and left of open panels: the
-- MAC button once built, and every panel that opens in the column (the MAC's, GOD MODE's).
MacPanel.toggle = nil :: GuiObject?
MacPanel.panels = {} :: { GuiObject }

local PANEL_WIDTH = 300
local PANEL_HEIGHT = 142
local CONFIRM_SECONDS = 3

-- Fires when the MAC opens, so the GOD MODE panel can close and not overlap it.
local openedEvent = Instance.new("BindableEvent")
MacPanel.opened = openedEvent.Event

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
	for _, child in (children or {}) :: { Instance } do
		child.Parent = instance
	end
	return instance
end

local function corner(): UICorner
	return create("UICorner", { CornerRadius = UDim.new(0, 8) })
end

local function hasMac(): boolean
	return player:GetAttribute("HasMac") == true
end

function MacPanel.close()
	if panel then
		panel.Visible = false
	end
end

local function build()
	local gui = create("ScreenGui", {
		Name = "MayhemMac",
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
			MacPanel.TOGGLE_TOP + MacPanel.TOGGLE_HEIGHT + MacPanel.GAP
		),
		Size = UDim2.fromOffset(130, MacPanel.TOGGLE_HEIGHT),
		TextSize = 16,
		Font = Enum.Font.LuckiestGuy,
		Parent = gui,
	}, { corner() })

	local frame = create("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, MacPanel.PANEL_TOP),
		Size = UDim2.fromOffset(PANEL_WIDTH, PANEL_HEIGHT),
		BackgroundColor3 = rgb(10, 18, 24),
		BackgroundTransparency = 0.1,
		Visible = false,
		Parent = gui,
	}, { corner(), create("UIStroke", { Color = rgb(80, 190, 255), Thickness = 2 }) })
	panel = frame
	MacPanel.toggle = toggle
	table.insert(MacPanel.panels, frame)

	create("TextLabel", {
		Position = UDim2.fromOffset(10, 8),
		Size = UDim2.fromOffset(PANEL_WIDTH - 20, 22),
		BackgroundTransparency = 1,
		Text = "🖥 MINI ADMIN CONSOLE",
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
		if hasMac() then
			Remotes.MacCommand:FireServer("sniper")
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
		if not hasMac() then
			return
		end
		if armedAt and os.clock() - armedAt < CONFIRM_SECONDS then
			armedAt = nil
			nuke.Text = NUKE_TEXT
			Remotes.MacCommand:FireServer("nuke")
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

	-- Covers the whole panel and swallows taps while the player has no MAC.
	local lock = create("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = rgb(0, 0, 0),
		BackgroundTransparency = 0.25,
		AutoButtonColor = false,
		Text = "🔒 LOCKED\nAsk an admin for the MAC",
		TextColor3 = rgb(230, 230, 230),
		TextSize = 16,
		Font = Enum.Font.GothamBold,
		ZIndex = 2,
		Parent = frame,
	}, { corner() })

	local function refresh()
		local unlocked = hasMac()
		lock.Visible = not unlocked
		toggle.Text = if unlocked then "🖥 MAC" else "🔒 MAC"
		toggle.BackgroundColor3 = if unlocked then rgb(80, 190, 255) else rgb(90, 90, 100)
		toggle.TextColor3 = if unlocked then rgb(0, 25, 45) else rgb(200, 200, 200)
	end
	player:GetAttributeChangedSignal("HasMac"):Connect(refresh)
	refresh()

	toggle.Activated:Connect(function()
		frame.Visible = not frame.Visible
		if frame.Visible then
			openedEvent:Fire()
		end
	end)
end

function MacPanel.start()
	build()
end

return MacPanel
