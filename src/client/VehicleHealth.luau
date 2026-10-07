-- The health bar of the vehicle the local player sits in (any seat: driver, passenger, a walker's
-- legs saddle). Server Vehicles keeps the model's Health and MaxHealth attributes; the bar is the
-- vehicle status in the top-right corner (HudLayout.statusPosition: above the system rail on a
-- small screen, left of it on a large one), goes green to yellow to red, and flashes white on
-- each hit. A wrecked vehicle (attribute Wrecked) hides it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local HealthBar = require(ReplicatedStorage.Shared.HealthBar)
local HudLayout = require(ReplicatedStorage.Shared.HudLayout)
local Names = require(ReplicatedStorage.Shared.Names)
local Create = require(script.Parent.ui.Create)
local RightColumn = require(script.Parent.ui.RightColumn)
local Theme = require(script.Parent.ui.Theme)

local VehicleHealth = {}

local player = Players.LocalPlayer
local rgb = Color3.fromRGB

local FLASH_TIME = 0.15

local gui = Instance.new("ScreenGui")
gui.Name = "VehicleHealth"
gui.ResetOnSpawn = false
gui.DisplayOrder = Theme.DisplayOrder.vehicleBar
gui.ScreenInsets = RightColumn.SCREEN_INSETS -- the system rail's space
gui.Enabled = false

local frame = Instance.new("Frame")
frame.Name = "Bar"
frame.AnchorPoint = Vector2.new(1, 0)
frame.BackgroundColor3 = Theme.Colors.hud
frame.BackgroundTransparency = Theme.HUD_TRANSPARENCY
frame.ClipsDescendants = true
frame.Parent = gui
Create.corner(Theme.Radius.round).Parent = frame
Create.stroke(Theme.Colors.white, 2, Enum.ApplyStrokeMode.Border).Parent = frame

local fill = Instance.new("Frame")
fill.Name = "Fill"
fill.BorderSizePixel = 0
fill.Size = UDim2.fromScale(1, 1)
fill.BackgroundColor3 = HealthBar.HEALTHY
fill.Parent = frame
Create.corner(Theme.Radius.round).Parent = fill

local flash = Instance.new("Frame")
flash.Name = "Flash"
flash.BorderSizePixel = 0
flash.Size = UDim2.fromScale(1, 1)
flash.BackgroundColor3 = rgb(255, 255, 255)
flash.BackgroundTransparency = 1
flash.Parent = frame

local label = Instance.new("TextLabel")
label.Name = "Label"
label.BackgroundTransparency = 1
label.Size = UDim2.fromScale(1, 1)
label.Font = Theme.Fonts.bold
label.TextSize = 14
label.TextColor3 = rgb(255, 255, 255)
label.TextStrokeTransparency = 0.4
label.Parent = frame

local function layout()
	local area = gui.AbsoluteSize
	local size = HudLayout.sizes(area).status
	frame.Position = HudLayout.statusPosition(area)
	frame.Size = UDim2.fromOffset(size.X, size.Y)
end

local vehicles: Instance? = nil -- workspace.Vehicles
local current: Model? = nil -- the vehicle shown
local connection: RBXScriptConnection? = nil
local lastHealth = 0

local function refresh()
	local model = current
	if not model then
		return
	end
	local health, maxHealth, share = HealthBar.read(
		model:GetAttribute(Names.Attributes.Health) :: number?,
		model:GetAttribute(Names.Attributes.MaxHealth) :: number?
	)
	fill.Size = UDim2.fromScale(share, 1)
	fill.BackgroundColor3 = HealthBar.colorFor(share)
	label.Text = HealthBar.labelText(model.Name, health, maxHealth)
	if health < lastHealth then
		flash.BackgroundTransparency = 0.2
		TweenService:Create(flash, TweenInfo.new(FLASH_TIME), { BackgroundTransparency = 1 }):Play()
	end
	lastHealth = health
	gui.Enabled = health > 0 and not model:GetAttribute(Names.Attributes.Wrecked)
end

-- The vehicle model holding the local player's seat, if any.
local function seatedIn(): Model?
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local seat = humanoid and humanoid.SeatPart
	local model = vehicles and seat and seat.Parent
	while model and model.Parent ~= vehicles do
		model = model.Parent
	end
	return if model and model:IsA("Model") then model else nil
end

local function watch(model: Model?)
	if model == current then
		return
	end
	if connection then
		connection:Disconnect()
		connection = nil
	end
	current = model
	if not model then
		gui.Enabled = false
		return
	end
	lastHealth = (model:GetAttribute(Names.Attributes.Health) :: number?) or 0
	connection = model.AttributeChanged:Connect(function(name)
		if
			name == Names.Attributes.Health
			or name == Names.Attributes.MaxHealth
			or name == Names.Attributes.Wrecked
		then
			refresh()
		end
	end)
	refresh()
end

function VehicleHealth.start()
	gui.Parent = player:WaitForChild("PlayerGui")
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
	layout()
	vehicles = workspace:WaitForChild(Names.Instances.Vehicles)
	RunService.Heartbeat:Connect(function()
		watch(seatedIn())
	end)
end

return VehicleHealth
