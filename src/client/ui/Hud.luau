-- The measured-layout seam of the HUD: finds the on-screen elements other UI is placed against and
-- converts between ScreenGui coordinate spaces. Pure layout math is in src/shared/HudLayout.
--
--   jumpButton()                   the default touch jump button, if the touch controls exist
--   jumpWatcher(layout)            a function that hooks `layout` to the jump button's position and
--                                  size changes (once per jump button), then calls `layout`
--   matchInset(gui, object)        gives `gui` the IgnoreGuiInset of `object`'s ScreenGui, so
--                                  offsets measured on `object` mean the same in `gui`
--   edgeY(object, bottom, space)   `object`'s top or bottom edge in the space of ScreenGui `space`
--   shownIn(object)                `object` is Visible and its ScreenGui Enabled
--   addBottomControls(gui)         lists a ScreenGui of bottom-right controls; call it at require
--                                  time, before any start(). The registry keeps the reference, so
--                                  the gui must live for the session (ResetOnSpawn false, never
--                                  destroyed)
--   bottomControls()               the shown jump button and every visible child of a listed gui
--                                  that is Enabled in PlayerGui: what PromptPanel stays above

local GuiService = game:GetService("GuiService")
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
		gui.IgnoreGuiInset = owner.IgnoreGuiInset
	end
end

function Hud.edgeY(object: GuiObject, bottom: boolean, space: ScreenGui): number
	local y = object.AbsolutePosition.Y + (if bottom then object.AbsoluteSize.Y else 0)
	local owner = object:FindFirstAncestorOfClass("ScreenGui")
	if owner and owner.IgnoreGuiInset ~= space.IgnoreGuiInset then
		local inset = GuiService:GetGuiInset().Y
		y += if owner.IgnoreGuiInset then -inset else inset
	end
	return y
end

function Hud.shownIn(object: GuiObject): boolean
	local owner = object:FindFirstAncestorOfClass("ScreenGui")
	return object.Visible and owner ~= nil and owner.Enabled
end

local bottomGuis: { ScreenGui } = {}

function Hud.addBottomControls(gui: ScreenGui)
	table.insert(bottomGuis, gui)
end

function Hud.bottomControls(): { GuiObject }
	local found = {}
	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	if not playerGui then
		return found
	end
	local jump = Hud.jumpButton()
	if jump and Hud.shownIn(jump) then
		table.insert(found, jump)
	end
	for _, each in bottomGuis do
		if each.Parent == playerGui and each.Enabled then
			for _, child in each:GetChildren() do
				if child:IsA("GuiObject") and child.Visible then
					table.insert(found, child)
				end
			end
		end
	end
	return found
end

return Hud
