-- What every pass gate shares: the model (walkers climb no part of it), the opening it leaves
-- clear (WorldLayout.GATE_OPENING), the world's name on a plaque, and the door.
--
-- The door: each leaf is a set of parts built closed, with the pivot they turn or slide about when
-- closed and when open. The gate model's `Open` attribute (true at build) drives every leaf: set
-- it with Gate.setOpen, or in Studio's Properties panel on the server, and the leaves tween over
-- SECONDS. Leaves collide in both states.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Names = require(ReplicatedStorage.Shared.Names)
local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local Build = require(script.Parent.Parent.Build)

local Gate = {}

Gate.WIDTH = WorldLayout.GATE_OPENING.width
Gate.HEIGHT = WorldLayout.GATE_OPENING.height
Gate.SECONDS = 3

local OPEN = "Open"

function Gate.model(name: string, parent: Instance): Model
	local model = Build.model(name, parent)
	CollectionService:AddTag(model, Names.Tags.NoClimb)
	return model
end

-- A plate with `text` on its front face (local -Z), scaled to fit.
function Gate.plaque(
	parent: Instance,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material,
	text: string,
	textColor: Color3,
	font: Enum.Font
): Part
	local plate = Build.part(parent, size, cframe, color, material, { name = "Plaque" })
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 20
	gui.LightInfluence = 0.3
	gui.Parent = plate
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(0.92, 0.84)
	label.Position = UDim2.fromScale(0.04, 0.08)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextScaled = true
	label.Font = font
	label.TextColor3 = textColor
	label.Parent = gui
	return plate
end

export type Leaf = {
	parts: { BasePart },
	closed: CFrame, -- the pivot as built
	open: CFrame, -- the pivot when open
}

-- Wires `leaves` to the gate's `Open` attribute and opens them.
function Gate.door(model: Model, leaves: { Leaf })
	local moving = {}
	for _, leaf in leaves do
		local offsets = {}
		for _, part in leaf.parts do
			offsets[part] = leaf.closed:ToObjectSpace(part.CFrame)
		end
		local pivot = Instance.new("CFrameValue")
		pivot.Name = "DoorPivot"
		pivot.Value = leaf.open
		pivot.Parent = model
		local function place()
			for part, offset in offsets do
				part.CFrame = pivot.Value * offset
			end
		end
		pivot.Changed:Connect(place)
		place()
		table.insert(moving, { leaf = leaf, pivot = pivot })
	end
	local info = TweenInfo.new(Gate.SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
	model:SetAttribute(OPEN, true)
	model:GetAttributeChangedSignal(OPEN):Connect(function()
		local open = model:GetAttribute(OPEN) == true
		for _, entry in moving do
			local goal = if open then entry.leaf.open else entry.leaf.closed
			TweenService:Create(entry.pivot, info, { Value = goal }):Play()
		end
	end)
end

function Gate.setOpen(model: Model, open: boolean)
	model:SetAttribute(OPEN, open)
end

return Gate
