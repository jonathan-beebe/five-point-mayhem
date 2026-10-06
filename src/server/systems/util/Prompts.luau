-- ProximityPrompts the server builds. Every prompt works through walls (RequiresLineOfSight
-- false); clients draw each one as a card at the right edge (src/client/PromptPanel.luau), which
-- restores `reach` after suppressing a prompt, so the server never changes MaxActivationDistance
-- after this.

local Prompts = {}

export type Spec = {
	name: string,
	action: string?, -- ActionText; nil keeps Roblox's default ("Interact")
	object: string, -- ObjectText
	key: Enum.KeyCode,
	reach: number, -- MaxActivationDistance
	enabled: boolean?, -- nil keeps Roblox's default (true)
}

-- A prompt from `spec`, parented to `parent` after every property is set.
function Prompts.make(spec: Spec, parent: Instance): ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = spec.name
	if spec.action then
		prompt.ActionText = spec.action
	end
	prompt.ObjectText = spec.object
	prompt.KeyboardKeyCode = spec.key
	prompt.MaxActivationDistance = spec.reach
	prompt.RequiresLineOfSight = false
	if spec.enabled ~= nil then
		prompt.Enabled = spec.enabled
	end
	prompt.Parent = parent
	return prompt
end

return Prompts
