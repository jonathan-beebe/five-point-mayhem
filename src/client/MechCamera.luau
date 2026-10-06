-- Camera for walkers: while the local player drives a vehicle whose driver seat has attribute
-- CockpitCamera (or one of its passenger seats), the view starts first person from the pilot's
-- head, looking out the chest window. V, gamepad Y, or the on-screen VIEW button (touch) switches
-- to an outside view orbiting the model's CameraFocus part and back. The STAND button (or jumping)
-- gets out of the seat; the driver then stands in the cab (a part tagged MechCab) and the view
-- stays first person until they leave it (the cab's Climb out prompt). Heel strikes shake the view
-- a little (MechMotion footfalls). The view turns with the vehicle. Leaving the vehicle or dying
-- restores the camera. In the first-person views, pieces marked HideInCockpit (a tinted canopy) are
-- hidden, so the pilot sees straight through them. While a flying pod (server PodFlight) is away,
-- STAND is hidden and the view turns with the pod.
--
-- The default camera builds each frame's CFrame from the previous frame's look direction, so
-- anything written to the camera after it runs carries into the next frame. Before it runs, this
-- module takes the last shake back out and turns the look direction by the vehicle's yaw since the
-- last frame; after it runs, it adds this frame's shake.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local HudLayout = require(ReplicatedStorage.Shared.HudLayout)
local MathUtil = require(ReplicatedStorage.Shared.MathUtil)
local Names = require(ReplicatedStorage.Shared.Names)
local PodState = require(ReplicatedStorage.Shared.PodState)
local MechMotion = require(script.Parent.MechMotion)
local Hud = require(script.Parent.ui.Hud)
local Theme = require(script.Parent.ui.Theme)
local TouchButton = require(script.Parent.ui.TouchButton)

local MechCamera = {}

local player = Players.LocalPlayer

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
	model: Model,
	seat: BasePart?, -- the driver or a passenger seat; nil while standing in the cab
	humanoid: Humanoid,
	minZoom: number,
	maxZoom: number,
	outside: boolean,
	yaw: number?, -- vehicle heading last frame
	connections: { RBXScriptConnection },
}

local session: Session? = nil

-- The button column, for other modules that stack buttons beside it (PodControls): button size
-- and gap in pixels, and the bottom-right corner of VIEW. Set whenever the buttons are laid out.
export type Layout = { size: number, gap: number, corner: UDim2, ignoreInset: boolean }
MechCamera.layout = nil :: Layout?
local layoutEvent = Instance.new("BindableEvent")
MechCamera.layoutChanged = layoutEvent.Event
local shakes: { { start: number, strength: number } } = {}
local applied = CFrame.identity -- the shake added to the camera last frame

-- Buttons ---------------------------------------------------------------------------------------

local buttonGui = Instance.new("ScreenGui")
buttonGui.Name = Names.Instances.MechButtons
buttonGui.ResetOnSpawn = false
buttonGui.DisplayOrder = Theme.DisplayOrder.touch
buttonGui.Enabled = false
Hud.addBottomControls(buttonGui)

local function makeButton(name: string, text: string): TextButton
	return TouchButton.new({
		name = name,
		text = text,
		parent = buttonGui,
		anchor = Vector2.new(1, 1),
		color = Theme.Colors.hud,
		transparency = Theme.HUD_TRANSPARENCY,
		strokeColor = Theme.Colors.white,
		paddingX = 0.12,
		paddingY = 0.3,
	})
end

local viewButton = makeButton("View", "VIEW") -- touch only; V and gamepad Y everywhere
local standButton = makeButton("Stand", "STAND") -- every platform; jumping does the same

-- VIEW sits directly left of the default jump button, bottoms aligned; STAND sits directly above
-- VIEW. Measured at runtime in the jump button's coordinate space (the ScreenGui copies TouchGui's
-- inset setting).
local function layoutButton()
	local jump = Hud.jumpButton()
	local column
	if jump then
		Hud.matchInset(buttonGui, jump)
		column = HudLayout.mechColumn(jump.AbsolutePosition, jump.AbsoluteSize)
	else
		column = HudLayout.mechColumnFallback(Workspace.CurrentCamera.ViewportSize)
	end
	local size, gap, corner = column.size, column.gap, column.corner
	viewButton.Size = UDim2.fromOffset(size, size)
	viewButton.Position = corner
	standButton.Size = UDim2.fromOffset(size, size)
	standButton.Position = HudLayout.standPosition(column)
	MechCamera.layout =
		{ size = size, gap = gap, corner = corner, ignoreInset = buttonGui.IgnoreGuiInset }
	layoutEvent:Fire()
end

local watchJumpButton = Hud.jumpWatcher(layoutButton)

-- Views ----------------------------------------------------------------------------------------

-- Whether the model's flying pod is away from its legs.
local function airborne(model: Model): boolean
	return PodState.of(model:GetAttribute(Names.Attributes.PodState)) ~= PodState.DOCKED
end

-- Whether the model's flying pod locks its seats (in the air; a landed pod lets riders out).
local function seatsLocked(model: Model): boolean
	return PodState.inFlight(PodState.of(model:GetAttribute(Names.Attributes.PodState)))
end

-- Pieces the pilot looks through from inside (Vehicles sets HideInCockpit); local to this client.
local function hideCockpitPieces(model: Model, hidden: boolean)
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and part:GetAttribute(Names.Attributes.HideInCockpit) then
			part.LocalTransparencyModifier = if hidden then 1 else 0
		end
	end
end

local function focusPart(current: Session): BasePart?
	local focus = current.model:FindFirstChild(Names.Instances.CameraFocus)
	return if focus and focus:IsA("BasePart") then focus else nil
end

-- The subject the current view wants.
local function subjectFor(current: Session): Instance
	return if current.outside and current.seat
		then focusPart(current) or current.humanoid
		else current.humanoid
end

local function applyView(current: Session)
	local camera = Workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Custom
	camera.CameraSubject = subjectFor(current)
	hideCockpitPieces(current.model, not current.outside)
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
	if current and current.seat then
		current.outside = not current.outside
		applyView(current)
	end
end

local function heading(current: Session): number?
	local root = current.model.PrimaryPart
	if airborne(current.model) then
		local pod = current.model:FindFirstChild(
			Names.Instances.BonePrefix
				.. tostring(current.model:GetAttribute(Names.Attributes.PodBone))
		)
		root = if pod and pod:IsA("BasePart") then pod else root
	end
	if not root then
		return nil
	end
	return MathUtil.yawOf(root.CFrame.LookVector)
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
		local delta = MathUtil.wrapAngle(yaw - current.yaw)
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
	hideCockpitPieces(current.model, false)
	player.CameraMaxZoomDistance = current.maxZoom
	player.CameraMinZoomDistance = current.minZoom
	local camera = Workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Custom
	if current.humanoid.Parent then
		camera.CameraSubject = current.humanoid
	end
end

-- Buttons for the current state: VIEW (touch) and STAND while seated, none while standing. (The
-- cab's Climb out prompt works standing only; PromptPanel switches it off while seated.)
local function showButtons(current: Session)
	viewButton.Visible = current.seat ~= nil and UserInputService.TouchEnabled
	standButton.Visible = current.seat ~= nil and not seatsLocked(current.model)
	buttonGui.Enabled = current.seat ~= nil
	if buttonGui.Enabled then
		watchJumpButton()
	end
end

local function enter(humanoid: Humanoid, model: Model, seat: BasePart?)
	leave()
	local current: Session = {
		model = model,
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
	table.insert(
		current.connections,
		model:GetAttributeChangedSignal(Names.Attributes.PodState):Connect(function()
			if session == current then
				current.yaw = nil -- the heading source changes
				showButtons(current)
			end
		end)
	)
	applyView(current)
	RunService:BindToRenderStep(TURN_STEP, Enum.RenderPriority.Camera.Value - 1, turn)
	RunService:BindToRenderStep(RENDER_STEP, Enum.RenderPriority.Camera.Value + 1, shake)
	showButtons(current)
end

-- The walker whose cab holds this point, if any.
local function cabAt(position: Vector3): Model?
	for _, cab in CollectionService:GetTagged(Names.Tags.MechCab) do
		if cab:IsA("BasePart") and cab.Parent and cab.Parent:IsA("Model") then
			if MathUtil.insideBox(cab.CFrame, cab.Size, position) then
				return cab.Parent
			end
		end
	end
	return nil
end

-- Whether `seat` gets the cockpit view: the driver seat of a CockpitCamera vehicle, or a passenger
-- seat in one (not a pod walker's legs seat, which rides outside).
local function inCockpit(seat: BasePart): boolean
	local model = seat.Parent
	local driver = model and model:FindFirstChild(Names.Instances.DriverSeat)
	return driver ~= nil
		and driver:GetAttribute(Names.Attributes.CockpitCamera) == true
		and (seat:IsA("Seat") or seat == driver)
		and not seat:GetAttribute(Names.Attributes.LegsSeat)
end

-- Called on every seat change and every frame: seated in a cockpit, or standing in a cab, keeps
-- (or starts) a session on that vehicle; anything else ends it.
local function update(humanoid: Humanoid)
	local seat = humanoid.SeatPart
	local model: Model? = nil
	local cockpit: BasePart? = nil
	if humanoid.Health > 0 then
		if seat and seat.Parent and seat.Parent:IsA("Model") and inCockpit(seat) then
			model, cockpit = seat.Parent, seat
		elseif not seat then
			local root = humanoid.RootPart
			model = root and cabAt(root.Position)
		end
	end
	local current = session
	if not model then
		leave()
	elseif not current or current.model ~= model then
		enter(humanoid, model, cockpit)
	elseif current.seat ~= cockpit then
		-- Sat down or stood up in the same vehicle: keep the saved zoom, back to the cockpit view.
		current.seat = cockpit
		current.outside = false
		applyView(current)
		showButtons(current)
	end
end

local function stand()
	local current = session
	if current and current.seat and not seatsLocked(current.model) then
		current.humanoid.Sit = false
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

-- Notices walking into or out of a cab.
local function watchCab()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and (session or #CollectionService:GetTagged(Names.Tags.MechCab) > 0) then
		update(humanoid)
	end
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
	viewButton.Activated:Connect(toggle)
	standButton.Activated:Connect(stand)
	RunService.Heartbeat:Connect(watchCab)

	MechMotion.footfall:Connect(function(model: Model, _foot: string, strength: number)
		local current = session
		if current and current.model == model then
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
