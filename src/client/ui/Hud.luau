-- The measured-layout seam of the HUD: finds the on-screen elements other UI is placed against and
-- converts between ScreenGui coordinate spaces. Pure layout math is in src/shared/HudLayout.
--
--   jumpButton()                   the default touch jump button, if the touch controls exist
--   jumpWatcher(layout)            a function that hooks `layout` to the jump button's position and
--                                  size changes (once per jump button), then calls `layout`
--   matchInset(gui, object)        gives `gui` the ScreenInsets of `object`'s ScreenGui, so
--                                  offsets measured on `object` mean the same in `gui`

local Players = game:GetService("Players")

local Hud = {}

local player = Players.LocalPlayer

function Hud.jumpButton(): GuiObject?
	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	local touchGui = playerGui and playerGui:FindFirstChild("TouchGui")
	local frame = touchGui and touchGui:FindFirstChild("TouchControlFrame")
	local jump = frame and frame:FindFirstChild("JumpButton")
	return if jump and jump:IsA("GuiObject") then jump else nil
end

function Hud.jumpWatcher(layout: () -> ()): () -> ()
	local watchedJump: GuiObject? = nil
	return function()
		local jump = Hud.jumpButton()
		if jump and jump ~= watchedJump then
			watchedJump = jump
			jump:GetPropertyChangedSignal("AbsolutePosition"):Connect(layout)
			jump:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
		end
		layout()
	end
end

function Hud.matchInset(gui: ScreenGui, object: GuiObject)
	local owner = object:FindFirstAncestorOfClass("ScreenGui")
	if owner then
		gui.ScreenInsets = owner.ScreenInsets
	end
end

return Hud
