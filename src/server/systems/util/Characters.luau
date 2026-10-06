-- Finding a player's character, Humanoid and HumanoidRootPart, and moving a character. Each
-- lookup is the expression server systems repeated inline: the Humanoid by class, the root by
-- name, nothing waited for.
--
-- Health checks stay with callers that test `Health <= 0` (Session, Weapons/Firing):
-- `living` tests `Health > 0`, and the two differ for a NaN health.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MathUtil = require(ReplicatedStorage.Shared.MathUtil)

local Characters = {}

-- The player's character, its Humanoid and its HumanoidRootPart, each nil when missing. No health
-- check.
function Characters.parts(player: Player): (Model?, Humanoid?, BasePart?)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	return character, humanoid, root
end

-- The player's character, Humanoid and root when all three exist and Health > 0; else nils.
function Characters.living(player: Player): (Model?, Humanoid?, BasePart?)
	local character, humanoid, root = Characters.parts(player)
	if character and humanoid and root and humanoid.Health > 0 then
		return character, humanoid, root
	end
	return nil, nil, nil
end

-- The player's character's Humanoid, alive or dead.
function Characters.humanoidOf(player: Player): Humanoid?
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

-- The player's character's HumanoidRootPart.
function Characters.rootOf(player: Player?): BasePart?
	local character = player and player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

-- Whether the player's root is inside `box` (a part: its CFrame and Size), seated or not.
function Characters.isInside(player: Player, box: BasePart): boolean
	local root = Characters.rootOf(player)
	return root ~= nil and MathUtil.insideBox(box.CFrame, box.Size, root.Position)
end

-- Pivots `character` so its `root` lands on `cframe`, and stops the root.
function Characters.moveRootTo(character: Model, root: BasePart, cframe: CFrame)
	local rootOffset = character:GetPivot():ToObjectSpace(root.CFrame)
	character:PivotTo(cframe * rootOffset:Inverse())
	root.AssemblyLinearVelocity = Vector3.zero
end

return Characters
