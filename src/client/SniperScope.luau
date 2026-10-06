-- Zoom scope for the sniper rifle. While the sniper is equipped: hold the right mouse button,
-- hold the gamepad left trigger, or toggle the on-screen SCOPE button (touch). Scoping narrows
-- the camera, draws a scope overlay, and hides the local character, which sits in the middle of
-- the third-person view. WeaponInput aims at the screen center while scoped, so shots land on the
-- reticle.
--
-- Scoped, this module turns the camera itself (Scriptable) instead of the default camera, whose
-- touch and gamepad turning ignore the zoom. Mouse, touch drags and the right thumbstick move a
-- target heading at low per-input rates; the view eases toward it, so it responds slowly.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local MathUtil = require(ReplicatedStorage.Shared.MathUtil)
local Names = require(ReplicatedStorage.Shared.Names)

local SniperScope = {}

local player = Players.LocalPlayer
local rgb = Color3.fromRGB

local WEAPON_ID = "sniper"
local SCOPED_FOV = 12
local RENDER_STEP = "SniperScopeView"

-- Turning while scoped, degrees per input unit.
local MOUSE_RATE = 0.02 -- per pixel of mouse movement
local TOUCH_RATE = 0.03 -- per pixel of drag
local GAMEPAD_RATE = 18 -- per second at full right-stick deflection
local GAMEPAD_DEADZONE = 0.15
local EASE_SECONDS = 0.15 -- time constant of the view easing toward the target heading
local MAX_PITCH = math.rad(80)
local VIEW_FRACTION = 0.9 -- scope circle diameter as a fraction of the shorter screen side

type Saved = {
	camera: Camera,
	cameraType: Enum.CameraType,
	fieldOfView: number,
	mouseIcon: boolean,
	mouseBehavior: Enum.MouseBehavior,
	transparency: { [Instance]: number },
	offset: Vector3, -- camera position relative to the character's root
	yaw: number, -- current view, radians
	pitch: number,
	targetYaw: number, -- where input points the view
	targetPitch: number,
}

local saved: Saved? = nil
local sniper: Tool? = nil
local touchToggled = false
local stick = Vector2.zero -- right thumbstick
local dragTouches: { [InputObject]: true } = {} -- touches that began on the world, not on a button

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
buttonGui.Name = Names.Instances.SniperScopeButton
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

local function turn(current: Saved, yawDegrees: number, pitchDegrees: number)
	current.targetYaw -= math.rad(yawDegrees)
	current.targetPitch =
		math.clamp(current.targetPitch - math.rad(pitchDegrees), -MAX_PITCH, MAX_PITCH)
end

local function rootPart(): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function viewStep(dt: number)
	local current = saved
	if not current then
		return
	end
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
	local mouse = UserInputService:GetMouseDelta()
	turn(current, mouse.X * MOUSE_RATE, mouse.Y * MOUSE_RATE)
	if stick.Magnitude > GAMEPAD_DEADZONE then
		turn(current, stick.X * GAMEPAD_RATE * dt, -stick.Y * GAMEPAD_RATE * dt)
	end
	local ease = MathUtil.timeAlpha(EASE_SECONDS, dt)
	current.yaw += (current.targetYaw - current.yaw) * ease
	current.pitch += (current.targetPitch - current.pitch) * ease
	local root = rootPart()
	local position = if root then root.Position + current.offset else current.camera.CFrame.Position
	current.camera.CFrame = CFrame.new(position)
		* CFrame.Angles(0, current.yaw, 0)
		* CFrame.Angles(current.pitch, 0, 0)
	hideCharacter()
end

local function scopeOut()
	local current = saved
	if not current then
		return
	end
	saved = nil
	RunService:UnbindFromRenderStep(RENDER_STEP)
	-- The default camera picks up the look direction from the camera's CFrame.
	current.camera.CameraType = current.cameraType
	current.camera.FieldOfView = current.fieldOfView
	UserInputService.MouseBehavior = current.mouseBehavior
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
	local look = camera.CFrame.LookVector
	local yaw = MathUtil.yawOf(look)
	local pitch = math.clamp(math.asin(math.clamp(look.Y, -1, 1)), -MAX_PITCH, MAX_PITCH)
	local root = rootPart()
	saved = {
		camera = camera,
		cameraType = camera.CameraType,
		fieldOfView = camera.FieldOfView,
		mouseIcon = UserInputService.MouseIconEnabled,
		mouseBehavior = UserInputService.MouseBehavior,
		transparency = {},
		offset = if root then camera.CFrame.Position - root.Position else Vector3.zero,
		yaw = yaw,
		pitch = pitch,
		targetYaw = yaw,
		targetPitch = pitch,
	}
	camera.CameraType = Enum.CameraType.Scriptable
	camera.FieldOfView = SCOPED_FOV
	UserInputService.MouseIconEnabled = false
	layoutOverlay()
	overlayGui.Enabled = true
	button.BackgroundColor3 = rgb(200, 40, 60)
	-- After the camera scripts, which also write LocalTransparencyModifier each frame.
	RunService:BindToRenderStep(RENDER_STEP, Enum.RenderPriority.Camera.Value + 1, viewStep)
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
		if child:IsA("Tool") and child:GetAttribute(Names.Attributes.WeaponId) == WEAPON_ID then
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
		if processed then
			return
		end
		if isScopeInput(input) and sniper then
			scopeIn()
		elseif input.UserInputType == Enum.UserInputType.Touch then
			dragTouches[input] = true
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.Thumbstick2 then
			stick = Vector2.new(input.Position.X, input.Position.Y)
		elseif dragTouches[input] and saved then
			turn(saved, input.Delta.X * TOUCH_RATE, input.Delta.Y * TOUCH_RATE)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		dragTouches[input] = nil
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
