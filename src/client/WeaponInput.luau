-- Turns clicks/taps into FireWeapon requests for whichever weapon is equipped.
-- Automatic weapons keep firing while the button is held.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local WeaponCatalog = require(ReplicatedStorage.Shared.WeaponCatalog)

local WeaponInput = {}

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local CROSSHAIR = "rbxasset://textures/GunCursor.png"

local lastFired: { [string]: number } = {}

-- World point under the cursor (or the last touch), ignoring the local character.
local function aimPoint(): Vector3
	local camera = Workspace.CurrentCamera
	local ray = camera:ScreenPointToRay(mouse.X, mouse.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local filter: { Instance } = {}
	if player.Character then
		table.insert(filter, player.Character)
	end
	local effects = Workspace:FindFirstChild("WeaponEffects")
	if effects then
		table.insert(filter, effects)
	end
	params.FilterDescendantsInstances = filter
	local result = Workspace:Raycast(ray.Origin, ray.Direction * 2000, params)
	return if result then result.Position else ray.Origin + ray.Direction * 2000
end

local function tryFire(weapon: WeaponCatalog.Weapon): boolean
	local now = os.clock()
	if lastFired[weapon.id] and now - lastFired[weapon.id] < weapon.cooldown then
		return false
	end
	lastFired[weapon.id] = now
	Remotes.FireWeapon:FireServer(weapon.id, aimPoint())
	return true
end

local function bind(tool: Tool)
	local weapon = WeaponCatalog.get(tool:GetAttribute("WeaponId") :: string)
	if not weapon or tool:GetAttribute("InputBound") then
		return
	end
	tool:SetAttribute("InputBound", true)
	local holding = false

	tool.Activated:Connect(function()
		if not weapon.auto then
			tryFire(weapon)
			return
		end
		holding = true
		while holding and tool.Parent == player.Character do
			tryFire(weapon)
			task.wait(weapon.cooldown)
		end
	end)
	tool.Deactivated:Connect(function()
		holding = false
	end)
	tool.Equipped:Connect(function()
		mouse.Icon = CROSSHAIR
	end)
	tool.Unequipped:Connect(function()
		holding = false
		mouse.Icon = ""
	end)
end

local function watch(container: Instance)
	for _, child in container:GetChildren() do
		if child:IsA("Tool") then
			bind(child)
		end
	end
	container.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			bind(child)
		end
	end)
end

function WeaponInput.start()
	player.CharacterAdded:Connect(function(character)
		mouse.Icon = ""
		watch(character)
		watch(player:WaitForChild("Backpack"))
	end)
	if player.Character then
		watch(player.Character)
		watch(player:WaitForChild("Backpack"))
	end
end

return WeaponInput
