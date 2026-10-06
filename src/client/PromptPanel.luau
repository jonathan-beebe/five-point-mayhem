-- Every ProximityPrompt, drawn by this client at the right edge of the screen, never over the
-- world. Each prompt is switched to Style Custom here as it appears; ProximityPromptService still
-- decides which prompts show and handles their keyboard and gamepad keys and holds. This module
-- draws one card per shown prompt: the key (or TAP on touch), the object text and the action text,
-- and a progress bar for hold prompts. Tapping or clicking a card holds the prompt.
--
-- Placement is measured from the right-hand column of toggles (MacPanel): the cards stack down
-- from just below the MAC button, right edges aligned with it. While a panel is open in that column
-- (the MAC's, GOD MODE's) they sit left of it. They stop above the bottom-right touch controls
-- (the jump button, MechCamera's and PodControls' columns, SCOPE), shrinking if they have to.
--
-- Prompts that do nothing for the local player while seated in a vehicle are switched off on this
-- client (MaxActivationDistance 0; the server never changes it after creation):
--   - every prompt of another vehicle: getting in elsewhere means leaving the seat first, and E, F
--     and Q are vehicle controls (the pod climbs on E and descends on Q, F launches it)
--   - on the player's own vehicle, Ride, Board and Climb out
--   - Drive, unless the player sits in a passenger seat (Drive moves them to the free driver seat)
--   - the pod console's prompt, unless the player sits in the driver seat (only the pilot launches)
-- Out of a seat (standing in a walker's cab too), every prompt works as the server set it.

local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local MacPanel = require(script.Parent.MacPanel)

local PromptPanel = {}

local player = Players.LocalPlayer
local rgb = Color3.fromRGB

local CARD_WIDTH = 220
local CARD_HEIGHT = 48
local MIN_CARD_HEIGHT = 28 -- the shortest a card shrinks to above the touch controls
local GAP = MacPanel.GAP

-- ScreenGuis of the bottom-right controls the cards stay above (besides the touch jump button).
local BOTTOM_CONTROLS = { "MechButtons", "PodButtons", "SniperScopeButton" }

local gui = Instance.new("ScreenGui")
gui.Name = "Prompts"
gui.ResetOnSpawn = false
gui.DisplayOrder = 14 -- under the MAC and GOD MODE panels (15)
gui.IgnoreGuiInset = false -- the same space as MacPanel's column

-- Suppression -------------------------------------------------------------------------------------

local vehicles: Instance? = nil -- workspace.Vehicles
local prompts: { [ProximityPrompt]: true } = {}
local serverReach: { [ProximityPrompt]: number } = {} -- prompts switched off here, and their reach

-- The vehicle model (a child of workspace.Vehicles) holding `instance`, if any.
local function vehicleOf(instance: Instance): Model?
	local model = instance.Parent
	while model and model.Parent ~= vehicles do
		model = model.Parent
	end
	return if model and model:IsA("Model") then model else nil
end

local function seat(): BasePart?
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return humanoid and humanoid.SeatPart
end

-- Whether `prompt` does anything for a player sitting in `sitting` aboard `own`.
local function useful(prompt: ProximityPrompt, sitting: BasePart, own: Model): boolean
	local vehicle = vehicleOf(prompt)
	if not vehicle then
		return true
	end
	if vehicle ~= own then
		return false
	end
	if prompt.Name == "PodPrompt" then
		return sitting.Name == "DriverSeat"
	end
	if prompt.Name == "DrivePrompt" then
		return sitting:IsA("Seat") -- a passenger seat; driver seats are VehicleSeats
	end
	return false
end

local function apply(prompt: ProximityPrompt)
	local sitting = seat()
	local own = if sitting then vehicleOf(sitting) else nil
	local off = sitting ~= nil and own ~= nil and not useful(prompt, sitting, own)
	local reach = serverReach[prompt]
	if off and not reach then
		serverReach[prompt] = prompt.MaxActivationDistance
		prompt.MaxActivationDistance = 0
	elseif not off and reach then
		prompt.MaxActivationDistance = reach
		serverReach[prompt] = nil
	end
end

local function applyAll()
	for prompt in prompts do
		apply(prompt)
	end
end

local function track(prompt: ProximityPrompt)
	if prompts[prompt] then
		return
	end
	prompts[prompt] = true
	prompt.Style = Enum.ProximityPromptStyle.Custom
	prompt.Destroying:Connect(function()
		prompts[prompt] = nil
		serverReach[prompt] = nil
	end)
	apply(prompt)
end

-- Cards -------------------------------------------------------------------------------------------

type Card = {
	prompt: ProximityPrompt,
	frame: TextButton,
	key: TextLabel,
	object: TextLabel,
	action: TextLabel,
	progress: Frame,
	holding: boolean,
	connections: { RBXScriptConnection },
}

local cards: { [ProximityPrompt]: Card } = {}

local function corner(radius: UDim, parent: Instance)
	local each = Instance.new("UICorner")
	each.CornerRadius = radius
	each.Parent = parent
end

local function text(name: string, font: Enum.Font, color: Color3, parent: Instance): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Font = font
	label.TextColor3 = color
	label.TextScaled = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Parent = parent
	return label
end

local function keyText(prompt: ProximityPrompt, inputType: Enum.ProximityPromptInputType): string
	if inputType == Enum.ProximityPromptInputType.Touch then
		return "TAP"
	end
	local code = if inputType == Enum.ProximityPromptInputType.Gamepad
		then prompt.GamepadKeyCode
		else prompt.KeyboardKeyCode
	if code.Value == 0 then -- no key (KeyCode Unknown)
		return ""
	end
	return (string.gsub(code.Name, "^Button", ""))
end

local function release(card: Card)
	if card.holding then
		card.holding = false
		card.prompt:InputHoldEnd()
	end
end

local function makeCard(prompt: ProximityPrompt, inputType: Enum.ProximityPromptInputType): Card
	local frame = Instance.new("TextButton")
	frame.Name = prompt.Name
	frame.AnchorPoint = Vector2.new(1, 0)
	frame.Text = ""
	frame.AutoButtonColor = false
	frame.BackgroundColor3 = rgb(20, 20, 28)
	frame.BackgroundTransparency = 0.25
	frame.ClipsDescendants = true
	frame.Parent = gui
	corner(UDim.new(0, 8), frame)
	local stroke = Instance.new("UIStroke")
	stroke.Color = rgb(255, 255, 255)
	stroke.Thickness = 2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = frame

	-- The key badge: a square at the left (sized by layout).
	local badge = Instance.new("Frame")
	badge.Name = "Badge"
	badge.AnchorPoint = Vector2.new(0, 0.5)
	badge.BackgroundColor3 = rgb(255, 255, 255)
	badge.Parent = frame
	corner(UDim.new(0.2, 0), badge)
	local key = text("Key", Enum.Font.GothamBold, rgb(20, 20, 28), badge)
	key.TextXAlignment = Enum.TextXAlignment.Center
	key.Size = UDim2.fromScale(0.8, 0.8)
	key.AnchorPoint = Vector2.new(0.5, 0.5)
	key.Position = UDim2.fromScale(0.5, 0.5)
	key.Text = keyText(prompt, inputType)

	-- The texts fill the rest: object text small on top, action text below.
	local texts = Instance.new("Frame")
	texts.Name = "Texts"
	texts.BackgroundTransparency = 1
	texts.Parent = frame
	local object = text("Object", Enum.Font.Gotham, rgb(200, 200, 215), texts)
	object.Size = UDim2.fromScale(1, 0.4)
	local action = text("Action", Enum.Font.GothamBold, rgb(255, 255, 255), texts)
	action.Position = UDim2.fromScale(0, 0.4)
	action.Size = UDim2.fromScale(1, 0.6)

	local progress = Instance.new("Frame")
	progress.Name = "Progress"
	progress.AnchorPoint = Vector2.new(0, 1)
	progress.Position = UDim2.fromScale(0, 1)
	progress.Size = UDim2.fromOffset(0, 3)
	progress.BorderSizePixel = 0
	progress.BackgroundColor3 = rgb(120, 245, 255)
	progress.Parent = frame

	local card: Card = {
		prompt = prompt,
		frame = frame,
		key = key,
		object = object,
		action = action,
		progress = progress,
		holding = false,
		connections = {},
	}

	local function refreshText()
		object.Text = prompt.ObjectText
		object.Visible = prompt.ObjectText ~= ""
		action.Text = prompt.ActionText
	end
	refreshText()

	local function connect(connection: RBXScriptConnection)
		table.insert(card.connections, connection)
	end
	connect(prompt:GetPropertyChangedSignal("ActionText"):Connect(refreshText))
	connect(prompt:GetPropertyChangedSignal("ObjectText"):Connect(refreshText))
	connect(prompt.PromptButtonHoldBegan:Connect(function()
		if prompt.HoldDuration > 0 then
			progress.Size = UDim2.fromOffset(0, 3)
			TweenService:Create(
				progress,
				TweenInfo.new(prompt.HoldDuration, Enum.EasingStyle.Linear),
				{ Size = UDim2.new(1, 0, 0, 3) }
			):Play()
		end
	end))
	connect(prompt.PromptButtonHoldEnded:Connect(function()
		progress.Size = UDim2.fromOffset(0, 3)
	end))
	-- Touch, and mouse clicks: the card is the button.
	connect(frame.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.Touch
			or input.UserInputType == Enum.UserInputType.MouseButton1
		then
			card.holding = true
			prompt:InputHoldBegin()
		end
	end))
	connect(frame.InputEnded:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.Touch
			or input.UserInputType == Enum.UserInputType.MouseButton1
		then
			release(card)
		end
	end))
	return card
end

local function removeCard(prompt: ProximityPrompt)
	local card = cards[prompt]
	if not card then
		return
	end
	cards[prompt] = nil
	release(card)
	for _, connection in card.connections do
		connection:Disconnect()
	end
	card.frame:Destroy()
end

-- Layout ------------------------------------------------------------------------------------------

-- `object`'s top or bottom edge in this gui's space (other guis may ignore the top-bar inset).
local function edgeY(object: GuiObject, bottom: boolean): number
	local y = object.AbsolutePosition.Y + (if bottom then object.AbsoluteSize.Y else 0)
	local owner = object:FindFirstAncestorOfClass("ScreenGui")
	if owner and owner.IgnoreGuiInset ~= gui.IgnoreGuiInset then
		local inset = GuiService:GetGuiInset().Y
		y += if owner.IgnoreGuiInset then -inset else inset
	end
	return y
end

local function shownIn(object: GuiObject): boolean
	local owner = object:FindFirstAncestorOfClass("ScreenGui")
	return object.Visible and owner ~= nil and owner.Enabled
end

-- The visible bottom-right controls the cards must stay above.
local function bottomControls(): { GuiObject }
	local found = {}
	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	if not playerGui then
		return found
	end
	local touchGui = playerGui:FindFirstChild("TouchGui")
	local touchFrame = touchGui and touchGui:FindFirstChild("TouchControlFrame")
	local jump = touchFrame and touchFrame:FindFirstChild("JumpButton")
	if jump and jump:IsA("GuiObject") and shownIn(jump) then
		table.insert(found, jump)
	end
	for _, name in BOTTOM_CONTROLS do
		local each = playerGui:FindFirstChild(name)
		if each and each:IsA("ScreenGui") and each.Enabled then
			for _, child in each:GetChildren() do
				if child:IsA("GuiObject") and child.Visible then
					table.insert(found, child)
				end
			end
		end
	end
	return found
end

local function layout()
	local ordered: { Card } = {}
	for _, card in cards do
		table.insert(ordered, card)
	end
	if #ordered == 0 then
		return
	end
	-- Keyboard key order: Drive (E) above Ride and the console (F) above Climb out (Q).
	table.sort(ordered, function(a, b)
		local ka, kb = a.prompt.KeyboardKeyCode.Value, b.prompt.KeyboardKeyCode.Value
		return if ka ~= kb then ka < kb else a.prompt:GetFullName() < b.prompt:GetFullName()
	end)

	local screen = gui.AbsoluteSize
	local right, top = screen.X, 0
	local toggle = MacPanel.toggle
	if toggle then
		right = toggle.AbsolutePosition.X + toggle.AbsoluteSize.X
		top = edgeY(toggle, true) + GAP
	end
	for _, panel in MacPanel.panels do
		if shownIn(panel) then
			right = math.min(right, panel.AbsolutePosition.X - GAP)
		end
	end
	local left = right - CARD_WIDTH
	local bottom = screen.Y
	for _, control in bottomControls() do
		local x0 = control.AbsolutePosition.X
		if x0 < right and x0 + control.AbsoluteSize.X > left then
			bottom = math.min(bottom, edgeY(control, false) - GAP)
		end
	end

	local count = #ordered
	local fit = math.floor((bottom - top - (count - 1) * GAP) / count)
	local height = math.clamp(fit, MIN_CARD_HEIGHT, CARD_HEIGHT)
	for index, card in ordered do
		card.frame.Size = UDim2.fromOffset(CARD_WIDTH, height)
		card.frame.Position = UDim2.fromOffset(right, top + (index - 1) * (height + GAP))
		-- The badge: a square as tall as the card less a margin top and bottom, at the left margin.
		-- The texts run from a margin right of it to the card's right margin.
		local margin = math.floor(height * 0.15)
		local side = height - margin * 2
		local badge = card.key.Parent :: Frame
		badge.Size = UDim2.fromOffset(side, side)
		badge.Position = UDim2.new(0, margin, 0.5, 0)
		local texts = card.action.Parent :: Frame
		local textLeft = margin * 2 + side
		texts.Position = UDim2.fromOffset(textLeft, margin)
		texts.Size = UDim2.fromOffset(CARD_WIDTH - textLeft - margin, height - margin * 2)
	end
end

-- Start ---------------------------------------------------------------------------------------------

local function onCharacter(character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	humanoid:GetPropertyChangedSignal("SeatPart"):Connect(applyAll)
	applyAll()
end

function PromptPanel.start()
	gui.Parent = player:WaitForChild("PlayerGui")
	vehicles = Workspace:WaitForChild("Vehicles")

	ProximityPromptService.PromptShown:Connect(function(prompt, inputType)
		if prompt.Style ~= Enum.ProximityPromptStyle.Custom then
			return -- only prompts this module took over
		end
		removeCard(prompt)
		cards[prompt] = makeCard(prompt, inputType)
		layout()
	end)
	ProximityPromptService.PromptHidden:Connect(removeCard)

	Workspace.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("ProximityPrompt") then
			track(descendant)
		end
	end)
	for _, descendant in Workspace:GetDescendants() do
		if descendant:IsA("ProximityPrompt") then
			track(descendant)
		end
	end

	RunService.RenderStepped:Connect(layout)
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end
end

return PromptPanel
