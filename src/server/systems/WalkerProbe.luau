-- TEMPORARY diagnostic: why walkers end up with their skid under the ground. For every walker in
-- workspace.Vehicles, logs the ground under it (a raycast from above that ignores vehicles and
-- characters), then the skid's height and what the skid overlaps at 0, 0.5, 1, 2 and 5 seconds.
-- Delete this file and its line in init.server.luau once the cause is known.

local Players = game:GetService("Players")

local WalkerProbe = {}

local SAMPLES = { 0, 0.5, 1, 2, 5 }

local function groundUnder(position: Vector3, ignore: { Instance }): string
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore
	local hit = workspace:Raycast(position + Vector3.new(0, 80, 0), Vector3.new(0, -200, 0), params)
	if not hit then
		return "nothing"
	end
	return string.format(
		"%s (%s, group %s) at y=%.2f",
		hit.Instance:GetFullName(),
		hit.Material.Name,
		if hit.Instance:IsA("BasePart") then hit.Instance.CollisionGroup else "?",
		hit.Position.Y
	)
end

local function watch(model: Model)
	local skid = model:WaitForChild("Skid", 5) :: BasePart?
	if not skid then
		return
	end
	local ignore: { Instance } = { workspace:FindFirstChild("Vehicles") or model }
	for _, player in Players:GetPlayers() do
		if player.Character then
			table.insert(ignore, player.Character)
		end
	end
	local started = os.clock()
	print(
		string.format(
			"[WalkerProbe] %s spawned skid y=%.2f group=%s canCollide=%s; ground: %s",
			model.Name,
			skid.Position.Y,
			skid.CollisionGroup,
			tostring(skid.CanCollide),
			groundUnder(skid.Position, ignore)
		)
	)
	for _, at in SAMPLES do
		task.wait(math.max(at - (os.clock() - started), 0))
		if not skid.Parent then
			return
		end
		print(
			string.format(
				"[WalkerProbe] %s t=%.1f skid y=%.2f vy=%.2f anchored=%s ground: %s",
				model.Name,
				os.clock() - started,
				skid.Position.Y,
				skid.AssemblyLinearVelocity.Y,
				tostring(skid.Anchored),
				groundUnder(skid.Position, ignore)
			)
		)
	end
end

function WalkerProbe.start()
	local folder = workspace:WaitForChild("Vehicles")
	for _, model in folder:GetChildren() do
		if model:IsA("Model") and model:GetAttribute("Gait") then
			task.spawn(watch, model)
		end
	end
	folder.ChildAdded:Connect(function(model)
		task.defer(function()
			if model:IsA("Model") and model:GetAttribute("Gait") then
				watch(model)
			end
		end)
	end)
end

return WalkerProbe
