-- A world's land: a flat floor of WorldLayout.FLOOR_RADIUS in a bowl of mountain walls, open
-- toward the lobby (WorldLayout.BOWL_GAP) where the pass comes in. Each realm module calls
-- `carve` with its own materials and seed, so a realm needs nothing from the hub but this file
-- and WorldLayout.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)

local Basin = {}

export type Land = {
	seed: number, -- the realm's own Random
	floor: Enum.Material,
	walls: Enum.Material,
	peaks: Enum.Material,
}

-- Fills the floor and the walls round `origin` (floor centre, local -Z toward the lobby). Three
-- draws per wall step, gap or not, so the walls stay put if BOWL_GAP changes.
function Basin.carve(origin: CFrame, land: Land)
	local t = workspace.Terrain
	local random = Random.new(land.seed)
	local radius = WorldLayout.FLOOR_RADIUS
	t:FillCylinder(origin * CFrame.new(0, -10, 0), 20, radius, land.floor)
	for degrees = 0, 354, 6 do
		local angle = math.rad(degrees)
		local distance = radius + random:NextNumber(90, 170)
		local size = random:NextNumber(110, 170)
		local height = random:NextNumber(120, 300)
		if not WorldLayout.inBowlGap(angle) then
			local x, z = math.sin(angle) * distance, -math.cos(angle) * distance
			t:FillBall(origin:PointToWorldSpace(Vector3.new(x, -30, z)), size, land.walls)
			t:FillBall(
				origin:PointToWorldSpace(Vector3.new(x, height - size * 0.6, z)),
				size * 0.6,
				land.peaks
			)
		end
	end
end

return Basin
