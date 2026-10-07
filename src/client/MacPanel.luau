-- The MAC (mini admin console): a toggle on the system rail below GOD MODE and a panel in the
-- rail's drawer (ui/RightColumn). Every player sees it. Players without the MAC (the server's
-- HasMac attribute) see it locked: a lock on the toggle, a notice line in the panel and its
-- buttons dimmed. The server re-checks HasMac on every command.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ConfirmTap = require(ReplicatedStorage.Shared.ConfirmTap)
local Names = require(ReplicatedStorage.Shared.Names)
local RemoteActions = require(ReplicatedStorage.Shared.RemoteActions)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Create = require(script.Parent.ui.Create)
local RightColumn = require(script.Parent.ui.RightColumn)
local Theme = require(script.Parent.ui.Theme)

local MacPanel = {}

local player = Players.LocalPlayer
local rgb = Color3.fromRGB
local create = Create.create

local PANEL_WIDTH = RightColumn.PANEL_WIDTH
local BUTTONS_TOP = 40 -- the first button's top; the locked notice pushes it down
local NOTICE_HEIGHT = 28
local BUTTON_HEIGHT = 40
local CONFIRM_SECONDS = 3

local panel: Frame? = nil

local function corner(): UICorner
	return Create.corner(Theme.Radius.panel)
end

local function hasMac(): boolean
	return player:GetAttribute(Names.Attributes.HasMac) == true
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
		ScreenInsets = RightColumn.SCREEN_INSETS,
		DisplayOrder = Theme.DisplayOrder.panels,
		Parent = player:WaitForChild("PlayerGui"),
	})
	local toggle = RightColumn.makeToggle(gui, 1, {})

	local frame = RightColumn.makePanel("Frame", gui, rgb(80, 190, 255), {
		BackgroundColor3 = rgb(10, 18, 24),
	})
	panel = frame

	create("TextLabel", {
		Position = UDim2.fromOffset(10, 8),
		Size = UDim2.fromOffset(PANEL_WIDTH - 20, 22),
		BackgroundTransparency = 1,
		Text = "🖥 MINI ADMIN CONSOLE",
		TextColor3 = rgb(120, 210, 255),
		TextSize = 16,
		Font = Theme.Fonts.title,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = frame,
	})

	local notice = create("TextLabel", {
		Position = UDim2.fromOffset(10, BUTTONS_TOP),
		Size = UDim2.fromOffset(PANEL_WIDTH - 20, NOTICE_HEIGHT),
		BackgroundColor3 = rgb(58, 42, 14),
		Text = "🔒 Locked. Ask an admin for the MAC.",
		TextColor3 = rgb(255, 226, 181),
		TextSize = 14,
		Font = Theme.Fonts.bold,
		Parent = frame,
	}, { corner(), Create.stroke(rgb(242, 162, 58), 1) })

	local sniper = create("TextButton", {
		Size = UDim2.fromOffset(PANEL_WIDTH - 20, BUTTON_HEIGHT),
		BackgroundColor3 = rgb(40, 110, 160),
		Text = "🎯 Give me the Sniper Rifle",
		TextColor3 = rgb(255, 255, 255),
		TextSize = 15,
		Font = Theme.Fonts.bold,
		Parent = frame,
	}, { corner() })
	sniper.Activated:Connect(function()
		if hasMac() then
			Remotes.MacCommand:FireServer(RemoteActions.MacCommand.SNIPER)
		end
	end)

	-- Two taps: the first arms it for CONFIRM_SECONDS, the second fires.
	local NUKE_TEXT = "☢ NUKE SERVER"
	local nuke = create("TextButton", {
		Size = UDim2.fromOffset(PANEL_WIDTH - 20, BUTTON_HEIGHT),
		BackgroundColor3 = rgb(200, 20, 30),
		Text = NUKE_TEXT,
		TextColor3 = rgb(255, 255, 255),
		TextSize = 16,
		Font = Theme.Fonts.title,
		Parent = frame,
	}, { corner() })
	local confirm = ConfirmTap.new()
	nuke.Activated:Connect(function()
		if not hasMac() then
			return
		end
		local fired, stamp = ConfirmTap.tap(confirm, CONFIRM_SECONDS, os.clock)
		if fired then
			nuke.Text = NUKE_TEXT
			Remotes.MacCommand:FireServer(RemoteActions.MacCommand.NUKE)
			return
		end
		nuke.Text = "TAP AGAIN TO NUKE EVERYONE"
		task.delay(CONFIRM_SECONDS, function()
			if ConfirmTap.expire(confirm, stamp) then
				nuke.Text = NUKE_TEXT
			end
		end)
	end)

	-- Locked: the notice line above the buttons, which dim and ignore taps (the handlers check
	-- hasMac).
	local function refresh()
		local unlocked = hasMac()
		notice.Visible = not unlocked
		local top = if unlocked then BUTTONS_TOP else BUTTONS_TOP + NOTICE_HEIGHT + 8
		sniper.Position = UDim2.fromOffset(10, top)
		nuke.Position = UDim2.fromOffset(10, top + BUTTON_HEIGHT + 8)
		frame.Size = UDim2.fromOffset(PANEL_WIDTH, top + BUTTON_HEIGHT * 2 + 8 + 14)
		for _, button in { sniper, nuke } do
			button.AutoButtonColor = unlocked
			button.BackgroundTransparency = if unlocked then 0 else 0.55
			button.TextTransparency = if unlocked then 0 else 0.45
		end
		if unlocked then
			RightColumn.setLabels(toggle, "🖥\nMAC", "🖥 MAC")
		else
			RightColumn.setLabels(toggle, "🔒\nMAC", "🔒 MAC")
		end
		toggle.BackgroundColor3 = if unlocked then rgb(80, 190, 255) else rgb(90, 90, 100)
		toggle.TextColor3 = if unlocked then rgb(0, 25, 45) else rgb(200, 200, 200)
	end
	player:GetAttributeChangedSignal(Names.Attributes.HasMac):Connect(refresh)
	refresh()

	toggle.Activated:Connect(function()
		frame.Visible = not frame.Visible
		if frame.Visible then
			RightColumn.notifyOpened()
		end
	end)
	RightColumn.watch(gui)
end

function MacPanel.start()
	build()
end

return MacPanel
