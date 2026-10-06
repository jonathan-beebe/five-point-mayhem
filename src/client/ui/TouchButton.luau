-- The round touch button of the bottom-right HUD (SniperScope's SCOPE, MechCamera's VIEW and
-- STAND, PodControls' pod, LAND, ▲ and ▼): bold scaled white text on a pill (corner radius half the
-- shorter side) with a 2-pixel border. Size and Position are left to the caller's layout.
--
--   TouchButton.new({
--   	name = "Scope", text = "SCOPE", parent = buttonGui,
--   	anchor = Vector2.new(0.5, 1),
--   	color = Theme.Colors.hud, transparency = Theme.HUD_TRANSPARENCY,
--   	strokeColor = Theme.Colors.white,
--   	paddingX = 0.12, paddingY = 0.3, -- UIPadding scale: left and right, top and bottom
--   	autoButtonColor = true,           -- optional; nil leaves the default
--   })
--
-- The button is parented after its own properties; its UICorner, UIStroke and UIPadding after it.

local Create = require(script.Parent.Create)
local Theme = require(script.Parent.Theme)

local TouchButton = {}

export type Options = {
	name: string,
	text: string,
	parent: Instance,
	anchor: Vector2,
	color: Color3,
	transparency: number,
	strokeColor: Color3,
	paddingX: number,
	paddingY: number,
	autoButtonColor: boolean?,
}

function TouchButton.new(options: Options): TextButton
	local button = Instance.new("TextButton")
	button.Name = options.name
	button.AnchorPoint = options.anchor
	button.BackgroundColor3 = options.color
	button.BackgroundTransparency = options.transparency
	button.TextColor3 = Theme.Colors.white
	button.Font = Theme.Fonts.bold
	button.TextScaled = true
	button.Text = options.text
	if options.autoButtonColor ~= nil then
		button.AutoButtonColor = options.autoButtonColor
	end
	button.Parent = options.parent
	Create.corner(Theme.Radius.round).Parent = button
	Create.stroke(options.strokeColor, 2, Enum.ApplyStrokeMode.Border).Parent = button
	Create.padding(UDim.new(options.paddingX, 0), UDim.new(options.paddingY, 0)).Parent = button
	return button
end

return TouchButton
