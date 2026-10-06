-- ProximityPrompts the server builds. Every prompt works through walls (RequiresLineOfSight
-- false); clients draw each one as a card at the right edge (src/client/PromptPanel.luau), which
-- restores `reach` after suppressing a prompt, so the server never changes MaxActivationDistance
-- after this. `seat`, `pod` and `board` are the prompts Vehicles/Boarding and PodFlight build
-- (tools/tests/server_helpers.luau checks each against the inline code it replaced).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Names = require(ReplicatedStorage.Shared.Names)

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

-- A vehicle's seat prompt on `anchor` (Vehicles/Boarding). `name` defaults to `<action>Prompt`;
-- PromptPanel finds the Drive prompt by its name.
function Prompts.seat(
	anchor: Instance,
	object: string,
	reach: number,
	action: string,
	key: Enum.KeyCode,
	name: string?
): ProximityPrompt
	return Prompts.make({
		name = name or action .. "Prompt",
		action = action,
		object = object,
		key = key,
		reach = reach,
	}, anchor)
end

-- A pod's button prompt (PodFlight). ActionText comes with the pod's state.
function Prompts.pod(anchor: Instance, modelName: string): ProximityPrompt
	return Prompts.make({
		name = Names.Instances.PodPrompt,
		object = modelName .. " pod",
		key = Enum.KeyCode.F,
		reach = 6,
	}, anchor)
end

-- A landed pod's Board prompt (PodFlight), disabled until the pod lands.
function Prompts.board(root: Instance, modelName: string, reach: number): ProximityPrompt
	return Prompts.make({
		name = "BoardPrompt",
		action = "Board",
		object = modelName .. " pod",
		key = Enum.KeyCode.E,
		reach = reach,
		enabled = false,
	}, root)
end

return Prompts
