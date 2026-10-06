-- Big banner text across the top of the screen, plus a red flash for alarms and MAYHEM.
-- The overlay and banner are hidden between announcements, and a new announcement cancels the
-- previous one's fade. The gui is built by start() or the first show(), whichever comes first.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local RemoteActions = require(ReplicatedStorage.Shared.RemoteActions)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Theme = require(script.Parent.ui.Theme)

local Announcer = {}

local overlay: Frame, banner: TextLabel

-- Builds the gui on first use: from start(), or from show() when a module announces before start
-- (LobbyUI does). Requiring this module builds nothing.
local function build()
	if banner then
		return
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = "MayhemAnnouncer"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = Theme.DisplayOrder.announcer

	local flash = Instance.new("Frame")
	flash.Size = UDim2.fromScale(1, 1)
	flash.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	flash.BackgroundTransparency = 1
	flash.BorderSizePixel = 0
	flash.Visible = false
	flash.Parent = gui

	local text = Instance.new("TextLabel")
	text.AnchorPoint = Vector2.new(0.5, 0)
	text.Position = UDim2.fromScale(0.5, 0.12)
	text.Size = UDim2.fromScale(0.8, 0.1)
	text.BackgroundTransparency = 1
	text.Font = Theme.Fonts.title
	text.TextScaled = true
	text.TextStrokeTransparency = 0
	text.TextTransparency = 1
	text.TextStrokeColor3 = Color3.new(0, 0, 0)
	text.Visible = false
	text.Parent = gui

	overlay, banner = flash, text

	-- Last: WaitForChild can yield, and a show() arriving meanwhile finds the banner built.
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end

local showId = 0

local fades: { [GuiObject]: Tween } = {}

-- Stops an object's running fade so a new announcement shows at full strength and stays visible.
local function stopFade(object: GuiObject)
	local fade = fades[object]
	if fade then
		fade:Cancel()
		fades[object] = nil
	end
end

-- Plays a fade, then hides the object unless the fade was stopped first.
local function fadeOut(object: GuiObject, info: TweenInfo, goal: { [string]: any })
	stopFade(object)
	local tween = TweenService:Create(object, info, goal)
	fades[object] = tween
	tween.Completed:Connect(function(state)
		if state == Enum.PlaybackState.Completed then
			object.Visible = false
			fades[object] = nil
		end
	end)
	tween:Play()
end

function Announcer.show(text: string, color: Color3?, seconds: number?, style: string?)
	build()
	showId += 1
	local id = showId
	stopFade(banner)
	banner.Text = text
	banner.TextColor3 = color or Color3.new(1, 1, 1)
	banner.TextTransparency = 0
	banner.TextStrokeTransparency = 0
	banner.Visible = true
	if style == RemoteActions.AnnounceStyle.ALARM then
		overlay.BackgroundTransparency = 0.6
		overlay.Visible = true
		fadeOut(overlay, TweenInfo.new(0.8), { BackgroundTransparency = 1 })
	elseif style == RemoteActions.AnnounceStyle.MAYHEM then
		overlay.BackgroundColor3 = Color3.new(1, 1, 1)
		overlay.BackgroundTransparency = 0
		overlay.Visible = true
		fadeOut(
			overlay,
			TweenInfo.new(2.5),
			{ BackgroundTransparency = 1, BackgroundColor3 = Color3.fromRGB(255, 0, 0) }
		)
	end
	task.delay(seconds or 3, function()
		if id == showId then
			fadeOut(
				banner,
				TweenInfo.new(0.5),
				{ TextTransparency = 1, TextStrokeTransparency = 1 }
			)
		end
	end)
end

function Announcer.start()
	build()
	overlay.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	Remotes.Announce.OnClientEvent:Connect(function(text, color, seconds, style)
		if style ~= RemoteActions.AnnounceStyle.MAYHEM then
			overlay.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
		end
		Announcer.show(text, color, seconds, style)
	end)
end

return Announcer
