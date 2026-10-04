-- Camera for walkers: while the local player drives a vehicle whose driver seat has attribute
-- CockpitCamera, the view starts first person from the pilot's head, looking out the chest
-- window. V, gamepad Y, or the on-screen VIEW button (touch) switches to an outside view orbiting
-- the model's CameraFocus part and back. Heel strikes shake the view a little (MechMotion
-- footfalls). The view turns with the vehicle. Getting out or dying restores the camera.
--
-- The default camera builds each frame's CFrame from the previous frame's look direction, so
-- anything written to the camera after it runs carries into the next frame. Before it runs, this
-- module takes the last shake back out and turns the look direction by the vehicle's yaw since the
-- last frame; after it runs, it adds this frame's shake.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local MechMotion = require(script.Parent.MechMotion)

local MechCamera = {}

local player = Players.LocalPlayer
local rgb = Color3.fromRGB

local COCKPIT_ZOOM = 0.5 -- under the default camera's first-person threshold
local OUTSIDE_MIN_ZOOM = 45
local OUTSIDE_MAX_ZOOM = 110
local OUTSIDE_START_ZOOM = 70
local RENDER_STEP = "MechCameraShake"
local TURN_STEP = "MechCameraTurn"

-- Heel-strike shake: a damped vertical sine.
local SHAKE_LIFT = 0.12 -- studs at strength 1
local SHAKE_PITCH = math.rad(0.35)
local SHAKE_DECAY = 0.12 -- seconds
local SHAKE_FREQUENCY = 9 -- Hz
local SHAKE_LENGTH = 0.4 -- seconds
local OUTSIDE_SHAKE = 0.5 -- amplitude scale in the outside view

type Session = {
	seat: VehicleSeat,
	humanoid: Humanoid,
	minZoom: number,
	maxZoom: number,
	outside: boolean,
	yaw: number?, -- vehicle heading last frame
	connections: { RBXScriptConnection },
}

local session: Session? = nil
local shakes: { { start: number, strength: number } } = {}
local applied = CFrame.identity -- the shake added to the camera last frame

-- Touch button ---------------------------------------------------------------------------------

local buttonGui = Instance.new("ScreenGui")
buttonGui.Name = "MechViewButton"
buttonGui.ResetOnSpawn = false
buttonGui.DisplayOrder = 6
buttonGui.Enabled = false

local button = Instance.new("TextButton")
button.Name = "View"
button.AnchorPoint = Vector2.new(1, 1)
button.BackgroundColor3 = rgb(20, 20, 28)
button.BackgroundTransparency = 0.25
button.TextColor3 = rgb(255, 255, 255)
button.Font = Enum.Font.GothamBold
button.TextScaled = true
button.Text = "VIEW"
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

-- Sits directly left of the default jump button, bottoms aligned, measured at runtime in the same
-- coordinate space (the button's ScreenGui copies TouchGui's inset setting).
local function layoutButton()
	local jump = jumpButton()
	if jump then
		local touchGui = jump:FindFirstAncestorOfClass("ScreenGui")
		if touchGui then
			buttonGui.IgnoreGuiInset = touchGui.IgnoreGuiInset
		end
		local size = math.floor(math.min(jump.AbsoluteSize.X, jump.AbsoluteSize.Y) * 0.8)
		local gap = math.floor(jump.AbsoluteSize.X * 0.15)
		button.Size = UDim2.fromOffset(size, size)
		button.Position = UDim2.fromOffset(
			jump.AbsolutePosition.X - gap,
			jump.AbsolutePosition.Y + jump.AbsoluteSize.Y
		)
	else
		local viewport = Workspace.CurrentCamera.ViewportSize
		local size = math.floor(math.min(viewport.X, viewport.Y) * 0.14)
		button.Size = UDim2.fromOffset(size, size)
		button.Position = UDim2.fromScale(0.8, 0.95)
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

-- Views ----------------------------------------------------------------------------------------

local function focusPart(current: Session): BasePart?
	local model = current.seat.Parent
	local focus = model and model:FindFirstChild("CameraFocus")
	return if focus and focus:IsA("BasePart") then focus else nil
end

-- The subject the current view wants.
local function subjectFor(current: Session): Instance
	return if current.outside then focusPart(current) or current.humanoid else current.humanoid
end

local function applyView(current: Session)
	local camera = Workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Custom
	camera.CameraSubject = subjectFor(current)
	if not current.outside then
		player.CameraMinZoomDistance = COCKPIT_ZOOM
		player.CameraMaxZoomDistance = COCKPIT_ZOOM
		return
	end
	-- Pin the zoom to the start distance for a frame, then open the range.
	player.CameraMaxZoomDistance = OUTSIDE_START_ZOOM
	player.CameraMinZoomDistance = OUTSIDE_START_ZOOM
	task.delay(0.1, function()
		if session == current and current.outside then
			player.CameraMinZoomDistance = OUTSIDE_MIN_ZOOM
			player.CameraMaxZoomDistance = OUTSIDE_MAX_ZOOM
		end
	end)
end

local function toggle()
	local current = session
	if current then
		current.outside = not current.outside
		applyView(current)
	end
end

local function heading(current: Session): number?
	local model = current.seat.Parent
	local root = model and model:IsA("Model") and model.PrimaryPart
	if not root then
		return nil
	end
	local look = root.CFrame.LookVector
	return math.atan2(-look.X, -look.Z)
end

-- Before the default camera: undo last frame's shake, then turn the view with the vehicle.
local function turn()
	local current = session
	if not current then
		return
	end
	local camera = Workspace.CurrentCamera
	camera.CFrame *= applied:Inverse()
	applied = CFrame.identity
	local yaw = heading(current)
	if yaw and current.yaw then
		local delta = (yaw - current.yaw + math.pi) % (2 * math.pi) - math.pi
		camera.CFrame = CFrame.new(camera.CFrame.Position)
			* CFrame.Angles(0, delta, 0)
			* camera.CFrame.Rotation
	end
	current.yaw = yaw
end

local function shake()
	local current = session
	if not current or #shakes == 0 then
		return
	end
	local now = os.clock()
	local lift, pitch = 0, 0
	for index = #shakes, 1, -1 do
		local each = shakes[index]
		local t = now - each.start
		if t > SHAKE_LENGTH then
			table.remove(shakes, index)
		else
			local wave = each.strength
				* math.exp(-t / SHAKE_DECAY)
				* math.sin(2 * math.pi * SHAKE_FREQUENCY * t)
			lift += SHAKE_LIFT * wave
			pitch += SHAKE_PITCH * wave
		end
	end
	local scale = if current.outside then OUTSIDE_SHAKE else 1
	applied = CFrame.new(0, -lift * scale, 0) * CFrame.Angles(-pitch * scale, 0, 0)
	Workspace.CurrentCamera.CFrame *= applied
end

local function leave()
	local current = session
	if not current then
		return
	end
	session = nil
	for _, connection in current.connections do
		connection:Disconnect()
	end
	table.clear(shakes)
	applied = CFrame.identity
	RunService:UnbindFromRenderStep(RENDER_STEP)
	RunService:UnbindFromRenderStep(TURN_STEP)
	buttonGui.Enabled = false
	player.CameraMaxZoomDistance = current.maxZoom
	player.CameraMinZoomDistance = current.minZoom
	local camera = Workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Custom
	if current.humanoid.Parent then
		camera.CameraSubject = current.humanoid
	end
end

local function enter(humanoid: Humanoid, seat: VehicleSeat)
	leave()
	local current: Session = {
		seat = seat,
		humanoid = humanoid,
		minZoom = player.CameraMinZoomDistance,
		maxZoom = player.CameraMaxZoomDistance,
		outside = false,
		connections = {},
	}
	session = current
	-- Roblox points the camera at a VehicleSeat when its occupant sits; point it back at the view's
	-- subject whenever something changes it.
	local camera = Workspace.CurrentCamera
	table.insert(
		current.connections,
		camera:GetPropertyChangedSignal("CameraSubject"):Connect(function()
			if session == current and camera.CameraSubject ~= subjectFor(current) then
				task.defer(function()
					if session == current then
						camera.CameraSubject = subjectFor(current)
					end
				end)
			end
		end)
	)
	applyView(current)
	RunService:BindToRenderStep(TURN_STEP, Enum.RenderPriority.Camera.Value - 1, turn)
	RunService:BindToRenderStep(RENDER_STEP, Enum.RenderPriority.Camera.Value + 1, shake)
	buttonGui.Enabled = UserInputService.TouchEnabled
	if buttonGui.Enabled then
		watchJumpButton()
	end
end

local function update(humanoid: Humanoid)
	local seat = humanoid.SeatPart
	local cockpit = humanoid.Health > 0
		and seat ~= nil
		and seat:IsA("VehicleSeat")
		and seat:GetAttribute("CockpitCamera") == true
	if cockpit then
		if not session or session.seat ~= seat then
			enter(humanoid, seat :: VehicleSeat)
		end
	else
		leave()
	end
end

local function onCharacter(character: Model)
	leave()
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	humanoid:GetPropertyChangedSignal("SeatPart"):Connect(function()
		update(humanoid)
	end)
	humanoid.Died:Connect(leave)
	update(humanoid)
end

function MechCamera.start()
	buttonGui.Parent = player:WaitForChild("PlayerGui")
	Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		if buttonGui.Enabled then
			layoutButton()
		end
	end)
	-- A new camera object: start over on it.
	Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		leave()
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			update(humanoid)
		end
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or not session then
			return
		end
		if input.KeyCode == Enum.KeyCode.V or input.KeyCode == Enum.KeyCode.ButtonY then
			toggle()
		end
	end)
	button.Activated:Connect(toggle)

	MechMotion.footfall:Connect(function(model: Model, _foot: string, strength: number)
		local current = session
		if current and current.seat.Parent == model then
			table.insert(shakes, { start = os.clock(), strength = strength })
		end
	end)

	player.CharacterAdded:Connect(onCharacter)
	player.CharacterRemoving:Connect(leave)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end
end

return MechCamera
