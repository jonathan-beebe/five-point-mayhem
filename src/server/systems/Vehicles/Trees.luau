-- Trees a vehicle fells (Contact): a felled tree topples, lies TREE_LIE seconds, and grows back
-- after TREE_REGROW once nothing stands in its place.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Names = require(ReplicatedStorage.Shared.Names)
local VehicleRam = require(ReplicatedStorage.Shared.VehicleRam)
local Ownership = require(script.Parent.Parent.util.Ownership)
local Registry = require(script.Parent.Registry)

local Trees = {}

local folder = Registry.folder

local TREE_LIE = 15 -- seconds a felled tree lies before it is cleared
local TREE_REGROW = 120 -- seconds until it grows back where it stood

-- A felled tree grows back once no vehicle, creature or player stands in its place.
local regrowParams = OverlapParams.new()
regrowParams.FilterType = Enum.RaycastFilterType.Include

local function regrow(sapling: Model, grove: Instance, box: CFrame, extent: Vector3)
	if not grove.Parent then
		return
	end
	local blockers: { Instance } = { folder }
	local creatures = workspace:FindFirstChild(Names.Instances.Creatures)
	if creatures then
		table.insert(blockers, creatures)
	end
	for _, player in Players:GetPlayers() do
		if player.Character then
			table.insert(blockers, player.Character)
		end
	end
	regrowParams.FilterDescendantsInstances = blockers
	if #workspace:GetPartBoundsInBox(box, extent, regrowParams) > 0 then
		task.delay(TREE_LIE, regrow, sapling, grove, box, extent)
		return
	end
	sapling.Parent = grove
end

-- Topples a tree away from a vehicle: its parts weld to the trunk, come loose, and turn to
-- Wreckage, which falls through vehicles and players. It lies for TREE_LIE seconds, then goes.
local function fell(tree: Model, direction: Vector3, pace: number, weight: number)
	local trunk = tree.PrimaryPart
	local grove = tree.Parent
	if not trunk or not grove or tree:GetAttribute("Felled") then
		return
	end
	local sapling = tree:Clone()
	local box, extent = tree:GetBoundingBox()
	tree:SetAttribute("Felled", true)
	local mass = 0
	for _, part in tree:GetDescendants() do
		if part:IsA("BasePart") then
			if part ~= trunk then
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = trunk
				weld.Part1 = part
				weld.Parent = part
			end
			part.CollisionGroup = Names.CollisionGroups.Wreckage
			part.CanTouch = false
			part.Anchored = false
			mass += part:GetMass()
		end
	end
	Ownership.set(trunk, nil)
	-- Pushed high, the tree pivots on its base and falls the way the vehicle was going.
	local crown = VehicleRam.treeCrown(box, extent)
	local push = VehicleRam.treePush(pace, weight)
	trunk:ApplyImpulseAtPosition(direction * push * mass, crown)
	task.delay(TREE_LIE, function()
		tree:Destroy()
	end)
	task.delay(TREE_REGROW, regrow, sapling, grove, box, extent)
end

Trees.fell = fell

return Trees
