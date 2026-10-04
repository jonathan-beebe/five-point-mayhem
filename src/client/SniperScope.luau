-- Zoom scope for the sniper rifle. While the sniper is equipped: hold the right mouse button,
-- hold the gamepad left trigger, or toggle the on-screen SCOPE button (touch). Scoping narrows
-- the camera, draws a scope overlay, lowers mouse sensitivity, and hides the local character,
-- which sits in the middle of the third-person view. WeaponInput aims at the screen center
-- while scoped, so shots land on the reticle.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local SniperScope = {}

local player = Players.LocalPlayer
local rgb = Color3.fromRGB

local WEAPON_ID = "sniper"
local SCOPED_FOV = 12
local MIN_SENSITIVITY_SCALE = 0.1
local RENDER_STEP = "SniperScopeHide"
local VIEW_FRACTION = 0.9 -- scope circle diameter as a fraction of the shorter screen side

type Saved = {
	camera: Camera,
	fieldOfView: number,
	sensitivity: number,
	mouseIcon: boolean,
	transparency: { [Instance]: number },
}

local saved: Saved? = nil
local sniper: Tool? = nil
local touchToggled = false

-- Overlay -------------------------------------------------------------------------------------

local overlayGui = Instance.new("ScreenGui")
overlayGui.Name = "SniperScope"
overlayGui.ResetOnSpawn = false
overlayGui.IgnoreGuiInset = true
overlayGui.DisplayOrder = 5
overlayGui.Enabled = false

local function blackFrame(name: string): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.BackgroundColor3 = rgb(0, 0, 0)
	frame.BorderSizePixel = 0
	frame.Parent = overlayGui
	return frame
end

-- Four bars cover everything outside the circle's bounding square.
local top = blackFrame("Top")
local bottom = blackFrame("Bottom")
local left = blackFrame("Left")
local right = blackFrame("Right")

-- The clear view: a transparent circle whose thick outer stroke fills the square's corners.
local lens = Instance.new("Frame")
lens.Name = "Lens"
lens.AnchorPoint = Vector2.new(0.5, 0.5)
lens.Position = UDim2.fromScale(0.5, 0.5)
lens.BackgroundTransparency = 1
lens.Parent = overlayGui
local lensCorner = Instance.new("UICorner")
lensCorner.CornerRadius = UDim.new(0.5, 0)
lensCorner.Parent = lens
local lensStroke = Instance.new("UIStroke")
lensStroke.Color = rgb(0, 0, 0)
lensStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
lensStroke.Parent = lens

local function reticleLine(name: string, size: UDim2): Frame
	local line = Instance.new("Frame")
	line.Name = name
	line.AnchorPoint = Vector2.new(0.5, 0.5)
	line.Position = UDim2.fromScale(0.5, 0.5)
	line.Size = size
	line.BackgroundColor3 = rgb(0, 0, 0)
	line.BackgroundTransparency = 0.15
	line.BorderSizePixel = 0
	line.Parent = lens
	return line
end

reticleLine("Horizontal", UDim2.new(1, 0, 0, 2))
reticleLine("Vertical", UDim2.new(0, 2, 1, 0))
local dot = reticleLine("Dot", UDim2.fromOffset(4, 4))
dot.BackgroundColor3 = rgb(255, 40, 40)
dot.BackgroundTransparency = 0
local dotCorner = Instance.new("UICorner")
dotCorner.CornerRadius = UDim.new(0.5, 0)
dotCorner.Parent = dot

local function layoutOverlay()
	local viewport = Workspace.CurrentCamera.ViewportSize
	local diameter = math.floor(math.min(viewport.X, viewport.Y) * VIEW_FRACTION)
	local x0 = math.floor((viewport.X - diameter) / 2)
	local y0 = math.floor((viewport.Y - diameter) / 2)
	lens.Size = UDim2.fromOffset(diameter, diameter)
	-- A square's corner sits radius * (sqrt(2) - 1) outside its inscribed circle.
	lensStroke.Thickness = math.ceil(diameter / 2 * (math.sqrt(2) - 1)) + 2
	top.Position = UDim2.fromOffset(0, 0)
	top.Size = UDim2.new(1, 0, 0, y0)
	bottom.Position = UDim2.fromOffset(0, y0 + diameter)
	bottom.Size = UDim2.new(1, 0, 1, -(y0 + diameter))
	left.Position = UDim2.fromOffset(0, y0)
	left.Size = UDim2.fromOffset(x0, diameter)
	right.Position = UDim2.fromOffset(x0 + diameter, y0)
	right.Size = UDim2.new(1, -(x0 + diameter), 0, diameter)
end

-- Touch button --------------------------------------------------------------------------------

local buttonGui = Instance.new("ScreenGui")
buttonGui.Name = "SniperScopeButton"
buttonGui.ResetOnSpawn = false
buttonGui.DisplayOrder = 6
buttonGui.Enabled = false

local button = Instance.new("TextButton")
button.Name = "Scope"
button.AnchorPoint = Vector2.new(0.5, 1)
button.BackgroundColor3 = rgb(20, 20, 28)
button.BackgroundTransparency = 0.25
button.TextColor3 = rgb(255, 255, 255)
button.Font = Enum.Font.GothamBold
button.TextScaled = true
button.Text = "SCOPE"
button.Parent = buttonGui
local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0.5, 0)
buttonCorner.Parent = button
local buttonStroke = Instance.new("UIStroke")
buttonStroke.Color = rgb(255, 255, 255)
buttonStroke.Thickness = 2
buttonStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
buttonStroke.Parent = button
local buttonPadding = Instance.new("UIPadding")
buttonPadding.PaddingLeft = UDim.new(0.12, 0)
buttonPadding.PaddingRight = UDim.new(0.12, 0)
buttonPadding.PaddingTop = UDim.new(0.3, 0)
buttonPadding.PaddingBottom = UDim.new(0.3, 0)
buttonPadding.Parent = button

local function jumpButton(): GuiObject?
	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	local touchGui = playerGui and playerGui:FindFirstChild("TouchGui")
	local frame = touchGui and touchGui:FindFirstChild("TouchControlFrame")
	local jump = frame and frame:FindFirstChild("JumpButton")
	return if jump and jump:IsA("GuiObject") then jump else nil
end

-- Sits directly above the default jump button, measured at runtime, in the same coordinate
-- space (the button's ScreenGui copies TouchGui's inset setting).
local function layoutButton()
	local jump = jumpButton()
	if jump then
		local touchGui = jump:FindFirstAncestorOfClass("ScreenGui")
		if touchGui then
			buttonGui.IgnoreGuiInset = touchGui.IgnoreGuiInset
		end
		local size = math.floor(math.min(jump.AbsoluteSize.X, jump.AbsoluteSize.Y) * 0.8)
		local gap = math.floor(jump.AbsoluteSize.Y * 0.15)
		local center = jump.AbsolutePosition.X + jump.AbsoluteSize.X / 2
		button.Size = UDim2.fromOffset(size, size)
		button.Position = UDim2.fromOffset(math.floor(center), jump.AbsolutePosition.Y - gap)
	else
		local viewport = Workspace.CurrentCamera.ViewportSize
		local size = math.floor(math.min(viewport.X, viewport.Y) * 0.14)
		button.Size = UDim2.fromOffset(size, size)
		button.Position = UDim2.fromScale(0.88, 0.62)
	end
end

local watchedJump: GuiObject? = nil
local function watchJumpButton()
	local jump = jumpButton()
	if jump and jump ~= watchedJump then
		watchedJump = jump
		jump:GetPropertyChangedSignal("AbsolutePosition"):Connect(layoutButton)
		jump:GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutButton)
	end
	layoutButton()
end

-- Scoping -------------------------------------------------------------------------------------

local function hideCharacter()
	local current = saved
	local character = player.Character
	if not current or not character then
		return
	end
	for _, descendant in character:GetDescendants() do
		if descendant:IsA("BasePart") or descendant:IsA("Decal") then
			if current.transparency[descendant] == nil then
				current.transparency[descendant] = (descendant :: any).LocalTransparencyModifier
			end
			(descendant :: any).LocalTransparencyModifier = 1
		end
	end
end

local function scopeOut()
	local current = saved
	if not current then
		return
	end
	saved = nil
	RunService:UnbindFromRenderStep(RENDER_STEP)
	current.camera.FieldOfView = current.fieldOfView
	UserInputService.MouseDeltaSensitivity = current.sensitivity
	UserInputService.MouseIconEnabled = current.mouseIcon
	for part, value in current.transparency do
		if part.Parent then
			(part :: any).LocalTransparencyModifier = value
		end
	end
	overlayGui.Enabled = false
	button.BackgroundColor3 = rgb(20, 20, 28)
end

local function scopeIn()
	local camera = Workspace.CurrentCamera
	if saved or not sniper or not camera then
		return
	end
	saved = {
		camera = camera,
		fieldOfView = camera.FieldOfView,
		sensitivity = UserInputService.MouseDeltaSensitivity,
		mouseIcon = UserInputService.MouseIconEnabled,
		transparency = {},
	}
	local current = saved :: Saved
	camera.FieldOfView = SCOPED_FOV
	-- Scale turning speed with the zoom so the reticle moves at the same rate across the screen.
	UserInputService.MouseDeltaSensitivity = current.sensitivity
		* math.max(SCOPED_FOV / current.fieldOfView, MIN_SENSITIVITY_SCALE)
	UserInputService.MouseIconEnabled = false
	layoutOverlay()
	overlayGui.Enabled = true
	button.BackgroundColor3 = rgb(200, 40, 60)
	-- After the camera scripts, which also write LocalTransparencyModifier each frame.
	RunService:BindToRenderStep(RENDER_STEP, Enum.RenderPriority.Camera.Value + 1, hideCharacter)
end

function SniperScope.isScoped(): boolean
	return saved ~= nil
end

local function equippedSniper(): Tool?
	local character = player.Character
	if not character then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return nil
	end
	for _, child in character:GetChildren() do
		if child:IsA("Tool") and child:GetAttribute("WeaponId") == WEAPON_ID then
			return child
		end
	end
	return nil
end

-- Re-reads what the character holds; scopes out the moment the sniper is not in hand.
local function update()
	sniper = equippedSniper()
	if not sniper then
		touchToggled = false
		scopeOut()
	end
	buttonGui.Enabled = sniper ~= nil and UserInputService.TouchEnabled
	if buttonGui.Enabled then
		watchJumpButton()
	end
end

local function onCharacter(character: Model)
	scopeOut()
	character.ChildAdded:Connect(update)
	character.ChildRemoved:Connect(update)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	humanoid.Died:Connect(update)
	update()
end

local function isScopeInput(input: InputObject): boolean
	return input.UserInputType == Enum.UserInputType.MouseButton2
		or input.KeyCode == Enum.KeyCode.ButtonL2
end

function SniperScope.start()
	local playerGui = player:WaitForChild("PlayerGui")
	overlayGui.Parent = playerGui
	buttonGui.Parent = playerGui

	Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		layoutOverlay()
		layoutButton()
	end)
	Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(scopeOut)

	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and isScopeInput(input) and sniper then
			scopeIn()
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if isScopeInput(input) and not touchToggled then
			scopeOut()
		end
	end)
	button.Activated:Connect(function()
		touchToggled = not touchToggled
		if touchToggled then
			scopeIn()
		else
			scopeOut()
		end
	end)

	player.CharacterAdded:Connect(onCharacter)
	player.CharacterRemoving:Connect(function()
		touchToggled = false
		scopeOut()
	end)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end
end

return SniperScope
