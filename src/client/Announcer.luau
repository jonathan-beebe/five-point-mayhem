-- Big banner text across the top of the screen, plus a red flash for alarms and MAYHEM.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Remotes = require(ReplicatedStorage.Shared.Remotes)

local Announcer = {}

local gui = Instance.new("ScreenGui")
gui.Name = "MayhemAnnouncer"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 20
gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

local overlay = Instance.new("Frame")
overlay.Size = UDim2.fromScale(1, 1)
overlay.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
overlay.BackgroundTransparency = 1
overlay.BorderSizePixel = 0
overlay.Parent = gui

local banner = Instance.new("TextLabel")
banner.AnchorPoint = Vector2.new(0.5, 0)
banner.Position = UDim2.fromScale(0.5, 0.12)
banner.Size = UDim2.fromScale(0.8, 0.1)
banner.BackgroundTransparency = 1
banner.Font = Enum.Font.LuckiestGuy
banner.TextScaled = true
banner.TextStrokeTransparency = 0
banner.TextTransparency = 1
banner.TextStrokeColor3 = Color3.new(0, 0, 0)
banner.Parent = gui

local showId = 0

function Announcer.show(text: string, color: Color3?, seconds: number?, style: string?)
	showId += 1
	local id = showId
	banner.Text = text
	banner.TextColor3 = color or Color3.new(1, 1, 1)
	banner.TextTransparency = 0
	banner.TextStrokeTransparency = 0
	if style == "alarm" then
		overlay.BackgroundTransparency = 0.6
		TweenService:Create(overlay, TweenInfo.new(0.8), { BackgroundTransparency = 1 }):Play()
	elseif style == "mayhem" then
		overlay.BackgroundColor3 = Color3.new(1, 1, 1)
		overlay.BackgroundTransparency = 0
		TweenService:Create(
			overlay,
			TweenInfo.new(2.5),
			{ BackgroundTransparency = 1, BackgroundColor3 = Color3.fromRGB(255, 0, 0) }
		):Play()
	end
	task.delay(seconds or 3, function()
		if id == showId then
			TweenService:Create(
				banner,
				TweenInfo.new(0.5),
				{ TextTransparency = 1, TextStrokeTransparency = 1 }
			):Play()
		end
	end)
end

function Announcer.start()
	overlay.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	Remotes.Announce.OnClientEvent:Connect(function(text, color, seconds, style)
		if style ~= "mayhem" then
			overlay.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
		end
		Announcer.show(text, color, seconds, style)
	end)
end

return Announcer
