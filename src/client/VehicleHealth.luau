-- The health bar of the vehicle the local player sits in (any seat: driver, passenger, a walker's
-- legs saddle). Server Vehicles keeps the model's Health and MaxHealth attributes; the bar sits at
-- the bottom centre, above the backpack hotbar, goes green to yellow to red, and flashes white on
-- each hit. A wrecked vehicle (attribute Wrecked) hides it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Names = require(ReplicatedStorage.Shared.Names)

local VehicleHealth = {}

local player = Players.LocalPlayer
local rgb = Color3.fromRGB

local BAR_SIZE = Vector2.new(260, 22)
local BAR_BOTTOM = 100 -- pixels from the bottom of the screen: clear of the backpack hotbar
local FLASH_TIME = 0.15
local HEALTHY = rgb(70, 210, 90)
local HURT = rgb(245, 200, 40)
local CRITICAL = rgb(230, 50, 40)

local gui = Instance.new("ScreenGui")
gui.Name = "VehicleHealth"
gui.ResetOnSpawn = false
gui.DisplayOrder = 5
gui.Enabled = false

local frame = Instance.new("Frame")
frame.Name = "Bar"
frame.AnchorPoint = Vector2.new(0.5, 1)
frame.Position = UDim2.new(0.5, 0, 1, -BAR_BOTTOM)
frame.Size = UDim2.fromOffset(BAR_SIZE.X, BAR_SIZE.Y)
frame.BackgroundColor3 = rgb(20, 20, 28)
frame.BackgroundTransparency = 0.25
frame.ClipsDescendants = true
frame.Parent = gui
local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0.5, 0)
frameCorner.Parent = frame
local stroke = Instance.new("UIStroke")
stroke.Color = rgb(255, 255, 255)
stroke.Thickness = 2
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
stroke.Parent = frame

local fill = Instance.new("Frame")
fill.Name = "Fill"
fill.BorderSizePixel = 0
fill.Size = UDim2.fromScale(1, 1)
fill.BackgroundColor3 = HEALTHY
fill.Parent = frame
local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(0.5, 0)
fillCorner.Parent = fill

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
label.Font = Enum.Font.GothamBold
label.TextSize = 14
label.TextColor3 = rgb(255, 255, 255)
label.TextStrokeTransparency = 0.4
label.Parent = frame

-- Green at full health, yellow at half, red at none.
local function colorFor(share: number): Color3
	if share >= 0.5 then
		return HURT:Lerp(HEALTHY, (share - 0.5) * 2)
	end
	return CRITICAL:Lerp(HURT, share * 2)
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
	local health = (model:GetAttribute(Names.Attributes.Health) :: number?) or 0
	local maxHealth = math.max((model:GetAttribute(Names.Attributes.MaxHealth) :: number?) or 1, 1)
	local share = math.clamp(health / maxHealth, 0, 1)
	fill.Size = UDim2.fromScale(share, 1)
	fill.BackgroundColor3 = colorFor(share)
	label.Text = string.format("%s  %d / %d", model.Name, math.ceil(health), maxHealth)
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
	vehicles = workspace:WaitForChild(Names.Instances.Vehicles)
	RunService.Heartbeat:Connect(function()
		watch(seatedIn())
	end)
end

return VehicleHealth
