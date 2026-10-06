-- Screen controls for flying pods (server PodFlight). While the local player sits in the driver
-- seat of a walker with a pod (model attribute PodBone), a wide button above MechCamera's STAND
-- reads LAUNCH (pod docked), RETURN HOME (flying) or RETURNING (the autopilot has it). On touch,
-- while flying, ▲ and ▼ beside the column climb and descend; keyboards use E and Q (CarInput reads
-- both). Passengers get only the jump lock. Near the ground (server attribute PodCanLand) a LAND
-- button (or L) appears left of it: the pod settles to hover and the pilot gets out. While the pod
-- flies the seat is locked here too: jumping is disabled. The console button's prompt (PodFlight)
-- is drawn at the side of the screen with every other prompt (PromptPanel).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local HudLayout = require(ReplicatedStorage.Shared.HudLayout)
local Names = require(ReplicatedStorage.Shared.Names)
local PodButtons = require(ReplicatedStorage.Shared.PodButtons)
local PodState = require(ReplicatedStorage.Shared.PodState)
local RemoteActions = require(ReplicatedStorage.Shared.RemoteActions)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local MechCamera = require(script.Parent.MechCamera)
local Hud = require(script.Parent.ui.Hud)
local Theme = require(script.Parent.ui.Theme)
local TouchButton = require(script.Parent.ui.TouchButton)

local PodControls = {}

local player = Players.LocalPlayer
local rgb = Color3.fromRGB

local gui = Instance.new("ScreenGui")
gui.Name = Names.Instances.PodButtons
gui.ResetOnSpawn = false
gui.DisplayOrder = Theme.DisplayOrder.touch
gui.Enabled = false
Hud.addBottomControls(gui)

local function makeButton(name: string, text: string, color: Color3): TextButton
	return TouchButton.new({
		name = name,
		text = text,
		parent = gui,
		anchor = Vector2.new(1, 1),
		color = color,
		transparency = 0.15,
		strokeColor = Theme.Colors.cyan,
		paddingX = 0.08,
		paddingY = 0.28,
		autoButtonColor = true,
	})
end

local podButton = makeButton("Pod", "LAUNCH", PodButtons.REST_COLOR)
local upButton = makeButton("Up", "▲", Theme.Colors.hud)
local downButton = makeButton("Down", "▼", Theme.Colors.hud)
local landButton = makeButton("Land", "LAND", rgb(20, 130, 70))

local model: Model? = nil -- the pod walker the local player drives
local humanoid: Humanoid? = nil
local touchLift = { up = false, down = false }
local jumpLocked = false
local passenger = false -- seated in a passenger seat (no buttons, only the jump lock)

local function state(): PodState.State
	return if model
		then PodState.of(model:GetAttribute(Names.Attributes.PodState))
		else PodState.DOCKED
end

-- The column MechCamera measured: the pod button spans two slots above STAND (its right edge on
-- the column's), LAND as wide just left of it, ▲ left of STAND and ▼ left of VIEW.
local function layout()
	local measured = MechCamera.layout
	if not measured then
		return
	end
	gui.IgnoreGuiInset = measured.ignoreInset
	local placed = HudLayout.podButtons(measured)
	podButton.Size = placed.pod.size
	podButton.Position = placed.pod.position
	landButton.Size = placed.land.size
	landButton.Position = placed.land.position
	upButton.Size = placed.up.size
	upButton.Position = placed.up.position
	downButton.Size = placed.down.size
	downButton.Position = placed.down.position
end

local function lockJump(locked: boolean)
	if jumpLocked == locked then
		return
	end
	jumpLocked = locked
	if humanoid then
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, not locked)
	end
end

local function refresh()
	local view = PodButtons.view(
		state(),
		model ~= nil,
		model ~= nil and model:GetAttribute(Names.Attributes.PodCanLand) == true,
		UserInputService.TouchEnabled
	)
	gui.Enabled = model ~= nil and not passenger
	podButton.Text = view.text
	podButton.Active = view.active
	podButton.AutoButtonColor = view.active
	podButton.BackgroundColor3 = view.color
	landButton.Visible = view.landVisible
	upButton.Visible = view.liftVisible
	downButton.Visible = view.liftVisible
	if not view.flying then
		touchLift.up, touchLift.down = false, false
	end
	lockJump(view.lockJump)
	layout()
end

local watching: RBXScriptConnection? = nil
local function setModel(new: Model?)
	if new == model then
		return
	end
	if watching then
		watching:Disconnect()
		watching = nil
	end
	model = new
	if new then
		watching = new.AttributeChanged:Connect(function(name)
			if name == Names.Attributes.PodState or name == Names.Attributes.PodCanLand then
				refresh()
			end
		end)
	end
	refresh()
end

-- Seated aboard a pod (its driver seat or a passenger seat, not the legs seat): the jump lock
-- applies; the buttons show for the driver only.
local function onSeat()
	local seat = humanoid and humanoid.SeatPart
	local parent = seat and seat.Parent
	local aboard = seat ~= nil
		and parent ~= nil
		and parent:IsA("Model")
		and parent:GetAttribute(Names.Attributes.PodBone) ~= nil
		and (seat.Name == Names.Instances.DriverSeat or seat:IsA("Seat"))
	passenger = aboard and (seat :: BasePart).Name ~= Names.Instances.DriverSeat
	setModel(if aboard then parent :: Model else nil)
end

local function onCharacter(character: Model)
	lockJump(false)
	local new = character:WaitForChild("Humanoid") :: Humanoid
	humanoid = new
	new:GetPropertyChangedSignal("SeatPart"):Connect(onSeat)
	onSeat()
end

-- Climb (+1) or descend (-1) from the touch buttons.
function PodControls.lift(): number
	return (if touchLift.up then 1 else 0) - (if touchLift.down then 1 else 0)
end

local function hold(button: TextButton, key: "up" | "down")
	button.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.Touch
			or input.UserInputType == Enum.UserInputType.MouseButton1
		then
			touchLift[key] = true
		end
	end)
	button.InputEnded:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.Touch
			or input.UserInputType == Enum.UserInputType.MouseButton1
		then
			touchLift[key] = false
		end
	end)
end

function PodControls.start()
	gui.Parent = player:WaitForChild("PlayerGui")
	podButton.Activated:Connect(function()
		local command = PodButtons.command(state())
		if command then
			Remotes.PodCommand:FireServer(command)
		end
	end)
	landButton.Activated:Connect(function()
		Remotes.PodCommand:FireServer(RemoteActions.PodCommand.LAND)
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if
			not processed
			and input.KeyCode == Enum.KeyCode.L
			and landButton.Visible
			and gui.Enabled
		then
			Remotes.PodCommand:FireServer(RemoteActions.PodCommand.LAND)
		end
	end)
	hold(upButton, "up")
	hold(downButton, "down")
	MechCamera.layoutChanged:Connect(layout)
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end
end

return PodControls
