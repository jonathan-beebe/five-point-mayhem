-- Instance builders for client UI.
--   create(className, properties, children?)  sets each property (in the table's iteration order,
--                                             Parent included), then parents each child to it
--   corner(radius)                            a UICorner (Theme.Radius has the shared radii)
--   stroke(color, thickness?, mode?)          a UIStroke; nil leaves Thickness (1) or
--                                             ApplyStrokeMode (Contextual) at the default
--   padding(horizontal, vertical)             a UIPadding: left and right, top and bottom
--   label(text, size, color, properties?)     LobbyUI's text: transparent, GothamBold, left
--                                             aligned, wrapped; `properties` override any of it
-- None of them parents what it returns, except create when `properties` holds Parent.

local Theme = require(script.Parent.Theme)

local Create = {}

function Create.create(
	className: string,
	properties: { [string]: any },
	children: { Instance }?
): any
	local instance = Instance.new(className)
	for key, value in properties do
		(instance :: any)[key] = value
	end
	for _, child in (children or {}) :: { Instance } do
		child.Parent = instance
	end
	return instance
end

function Create.corner(radius: UDim): UICorner
	return Create.create("UICorner", { CornerRadius = radius })
end

function Create.stroke(color: Color3, thickness: number?, mode: Enum.ApplyStrokeMode?): UIStroke
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	if thickness then
		stroke.Thickness = thickness
	end
	if mode then
		stroke.ApplyStrokeMode = mode
	end
	return stroke
end

function Create.padding(horizontal: UDim, vertical: UDim): UIPadding
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = horizontal
	padding.PaddingRight = horizontal
	padding.PaddingTop = vertical
	padding.PaddingBottom = vertical
	return padding
end

function Create.label(
	text: string,
	size: number,
	color: Color3,
	properties: { [string]: any }?
): TextLabel
	local result = Create.create("TextLabel", {
		BackgroundTransparency = 1,
		Text = text,
		TextSize = size,
		TextColor3 = color,
		Font = Theme.Fonts.bold,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
	})
	for key, value in (properties or {}) :: { [string]: any } do
		(result :: any)[key] = value
	end
	return result
end

return Create
