-- Every ProximityPrompt, drawn by this client in the top-left corner of the screen, never over the
-- world. Each prompt is switched to Style Custom here as it appears; ProximityPromptService still
-- decides which prompts show and handles their keyboard and gamepad keys and holds. This module
-- draws one card per shown prompt: the key (or TAP on touch), the object text and the action text,
-- and a progress bar for hold prompts. Tapping or clicking a card holds the prompt.
--
-- Placement: the cards stack down from the top-left corner of the safe area (under the Roblox top
-- bar), clear of the thumbstick below and of the system rail and action cluster on the right,
-- shrinking if there are many. Cards are wider and taller on a large screen. The arithmetic is
-- HudLayout.promptStack. A prompt PromptRules.drawn turns down (the pod console's in the driver
-- seat, where PodControls' button does the same) keeps working by key with no card.
--
-- Prompts that do nothing for the local player while seated in a vehicle are switched off on this
-- client (MaxActivationDistance 0; the server never changes it after creation):
--   - every prompt of another vehicle: getting in elsewhere means leaving the seat first, and E, F
--     and Q are vehicle controls (the pod climbs on E and descends on Q, F launches it)
--   - on the player's own vehicle, Ride, Board and Climb out
--   - Drive, unless the player sits in a passenger seat (Drive moves them to the free driver seat)
--   - the pod console's prompt, unless the player sits in the driver seat (only the pilot launches)
-- Out of a seat (standing in a walker's cab too), every prompt works as the server set it. The
-- rule is PromptRules.useful; the key text and card order are PromptRules too.

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local HudLayout = require(ReplicatedStorage.Shared.HudLayout)
local Names = require(ReplicatedStorage.Shared.Names)
local PromptRules = require(ReplicatedStorage.Shared.PromptRules)
local Create = require(script.Parent.ui.Create)
local RightColumn = require(script.Parent.ui.RightColumn)
local Theme = require(script.Parent.ui.Theme)

local PromptPanel = {}

local player = Players.LocalPlayer
local rgb = Color3.fromRGB

local MIN_CARD_HEIGHT = 28 -- the shortest a card shrinks to when many show
local GAP = HudLayout.GAP

local gui = Instance.new("ScreenGui")
gui.Name = "Prompts"
gui.ResetOnSpawn = false
gui.DisplayOrder = Theme.DisplayOrder.prompts -- under the MAC and GOD MODE panels
gui.ScreenInsets = RightColumn.SCREEN_INSETS -- the safe area (IgnoreGuiInset false)

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
	local where: PromptRules.Where = if not vehicle
		then "none"
		elseif vehicle == own then "own"
		else "other"
	return PromptRules.useful(where, prompt.Name, sitting.Name, sitting:IsA("Seat"))
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

local removeCard: (ProximityPrompt) -> () -- Cards, below

local function track(prompt: ProximityPrompt)
	if prompts[prompt] then
		return
	end
	prompts[prompt] = true
	prompt.Style = Enum.ProximityPromptStyle.Custom
	prompt.Destroying:Connect(function()
		prompts[prompt] = nil
		serverReach[prompt] = nil
		removeCard(prompt) -- a destroyed prompt is not always hidden first
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
	tween: Tween?, -- the running hold progress fill
	holding: boolean,
	connections: { RBXScriptConnection },
}

local cards: { [ProximityPrompt]: Card } = {}

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
	return PromptRules.keyText(inputType, prompt.GamepadKeyCode, prompt.KeyboardKeyCode)
end

local function release(card: Card)
	if card.holding then
		card.holding = false
		card.prompt:InputHoldEnd()
	end
end

-- Cancels the hold progress fill and empties the bar.
local function stopFill(card: Card)
	local tween = card.tween
	if tween then
		card.tween = nil
		tween:Cancel()
	end
	card.progress.Size = UDim2.fromOffset(0, 3)
end

local function makeCard(prompt: ProximityPrompt, inputType: Enum.ProximityPromptInputType): Card
	local frame = Instance.new("TextButton")
	frame.Name = prompt.Name
	frame.AnchorPoint = Vector2.new(0, 0)
	frame.Text = ""
	frame.AutoButtonColor = false
	frame.BackgroundColor3 = Theme.Colors.hud
	frame.BackgroundTransparency = Theme.HUD_TRANSPARENCY
	frame.ClipsDescendants = true
	frame.Parent = gui
	Create.corner(Theme.Radius.panel).Parent = frame
	Create.stroke(Theme.Colors.white, 2, Enum.ApplyStrokeMode.Border).Parent = frame

	-- The key badge: a square at the left (sized by layout).
	local badge = Instance.new("Frame")
	badge.Name = "Badge"
	badge.AnchorPoint = Vector2.new(0, 0.5)
	badge.BackgroundColor3 = Theme.Colors.white
	badge.Parent = frame
	Create.corner(UDim.new(0.2, 0)).Parent = badge
	local key = text("Key", Theme.Fonts.bold, Theme.Colors.hud, badge)
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
	local object = text("Object", Theme.Fonts.regular, rgb(200, 200, 215), texts)
	object.Size = UDim2.fromScale(1, 0.4)
	local action = text("Action", Theme.Fonts.bold, Theme.Colors.white, texts)
	action.Position = UDim2.fromScale(0, 0.4)
	action.Size = UDim2.fromScale(1, 0.6)

	local progress = Instance.new("Frame")
	progress.Name = "Progress"
	progress.AnchorPoint = Vector2.new(0, 1)
	progress.Position = UDim2.fromScale(0, 1)
	progress.Size = UDim2.fromOffset(0, 3)
	progress.BorderSizePixel = 0
	progress.BackgroundColor3 = Theme.Colors.cyan
	progress.Parent = frame

	local card: Card = {
		prompt = prompt,
		frame = frame,
		key = key,
		object = object,
		action = action,
		progress = progress,
		tween = nil,
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
		stopFill(card)
		if prompt.HoldDuration > 0 then
			local tween = TweenService:Create(
				progress,
				TweenInfo.new(prompt.HoldDuration, Enum.EasingStyle.Linear),
				{ Size = UDim2.new(1, 0, 0, 3) }
			)
			card.tween = tween
			tween:Play()
		end
	end))
	connect(prompt.PromptButtonHoldEnded:Connect(function()
		stopFill(card)
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

function removeCard(prompt: ProximityPrompt)
	local card = cards[prompt]
	if not card then
		return
	end
	cards[prompt] = nil
	release(card)
	stopFill(card)
	for _, connection in card.connections do
		connection:Disconnect()
	end
	card.frame:Destroy()
end

-- Redraws every shown card's key for a new input type (TAP on touch, the gamepad or keyboard key).
local function refreshKeys(inputType: Enum.UserInputType)
	local promptType = PromptRules.inputType(inputType)
	if not promptType then
		return
	end
	for prompt, card in cards do
		card.key.Text = keyText(prompt, promptType)
	end
end

-- Layout ------------------------------------------------------------------------------------------

local function layout()
	local sitting = seat()
	local seatName = if sitting then sitting.Name else nil
	local ordered: { Card } = {}
	for prompt, card in cards do
		local shown = PromptRules.drawn(prompt.Name, seatName)
		card.frame.Visible = shown
		if shown then
			table.insert(ordered, card)
		end
	end
	if #ordered == 0 then
		return
	end
	-- Keyboard key order: Drive (E) above Ride and the console (F) above Climb out (Q).
	table.sort(ordered, function(a, b)
		return PromptRules.before(a.prompt, b.prompt)
	end)

	local column = HudLayout.promptStack(gui.AbsoluteSize, #ordered, MIN_CARD_HEIGHT)
	local width, height = column.width, column.height
	local insides = HudLayout.cardInsides(height, width)
	for index, card in ordered do
		card.frame.Size = UDim2.fromOffset(width, height)
		card.frame.Position = UDim2.fromOffset(column.left, HudLayout.cardTop(column, GAP, index))
		local badge = card.key.Parent :: Frame
		badge.Size = UDim2.fromOffset(insides.side, insides.side)
		badge.Position = UDim2.new(0, insides.margin, 0.5, 0)
		local texts = card.action.Parent :: Frame
		texts.Position = UDim2.fromOffset(insides.textLeft, insides.margin)
		texts.Size = UDim2.fromOffset(insides.textWidth, insides.textHeight)
	end
end

-- Start -------------------------------------------------------------------------------------------

local function onCharacter(character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	humanoid:GetPropertyChangedSignal("SeatPart"):Connect(applyAll)
	applyAll()
end

function PromptPanel.start()
	gui.Parent = player:WaitForChild("PlayerGui")
	vehicles = Workspace:WaitForChild(Names.Instances.Vehicles)

	ProximityPromptService.PromptShown:Connect(function(prompt, inputType)
		if prompt.Style ~= Enum.ProximityPromptStyle.Custom then
			return -- only prompts this module took over
		end
		removeCard(prompt)
		cards[prompt] = makeCard(prompt, inputType)
		layout()
	end)
	ProximityPromptService.PromptHidden:Connect(removeCard)
	UserInputService.LastInputTypeChanged:Connect(refreshKeys)

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
