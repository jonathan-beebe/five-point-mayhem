-- Road network: spokes from the lobby gates to each landmark, an inner and an outer ring road,
-- and connectors between the rings in the gaps between landmarks.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Build = require(script.Parent.Build)

local Roads = {}

local ASPHALT = Color3.fromRGB(55, 55, 60)
local LINE = Color3.fromRGB(255, 210, 40)
local THICKNESS = 1

type Segment = { a: Vector2, b: Vector2, halfWidth: number }
local segments: { Segment } = {}

local function segment(parent: Instance, a: Vector3, b: Vector3, width: number, top: number)
	local length = (b - a).Magnitude
	local y = top - THICKNESS / 2
	local from = Vector3.new(a.X, y, a.Z)
	local to = Vector3.new(b.X, y, b.Z)
	local frame = CFrame.lookAt((from + to) / 2, to)
	Build.part(
		parent,
		Vector3.new(width, THICKNESS, length + width * 0.4),
		frame,
		ASPHALT,
		Enum.Material.Asphalt
	)

	local dashes = math.floor(length / 16)
	for index = 0, dashes - 1 do
		local offset = -length / 2 + 8 + index * 16
		Build.part(
			parent,
			Vector3.new(0.6, 0.06, 6),
			frame * CFrame.new(0, THICKNESS / 2 + 0.03, offset),
			LINE,
			Enum.Material.SmoothPlastic,
			{ canCollide = false, canQuery = false, castShadow = false }
		)
	end
	table.insert(
		segments,
		{ a = Vector2.new(a.X, a.Z), b = Vector2.new(b.X, b.Z), halfWidth = width / 2 }
	)
end

local function ringRoad(parent: Instance, radius: number, sides: number, width: number)
	for index = 0, sides - 1 do
		local a = Config.pointAt(index / sides * 2 * math.pi, radius)
		local b = Config.pointAt((index + 1) / sides * 2 * math.pi, radius)
		-- Alternate heights by a hair so overlapping joints never z-fight.
		segment(parent, a, b, width, 0.6 + (index % 2) * 0.01)
	end
end

function Roads.build(parent: Instance)
	local model = Build.model("Roads", parent)
	ringRoad(model, Config.INNER_ROAD_RADIUS, 48, 24)
	ringRoad(model, Config.OUTER_ROAD_RADIUS, 80, 24)
	for index = 1, #Config.REGIONS do
		local angle = Config.regionAngle(index)
		segment(
			model,
			Config.pointAt(angle, Config.LOBBY_RADIUS + 2),
			Config.pointAt(angle, Config.SPOKE_END_RADIUS),
			22,
			0.7
		)
		local between = Config.betweenRegions(index)
		segment(
			model,
			Config.pointAt(between, Config.INNER_ROAD_RADIUS),
			Config.pointAt(between, Config.OUTER_ROAD_RADIUS),
			22,
			0.65
		)
	end
	return model
end

-- Flat distance from a position to the nearest road edge (negative when on a road).
function Roads.distanceTo(position: Vector3): number
	local p = Vector2.new(position.X, position.Z)
	local best = math.huge
	for _, road in segments do
		local ab = road.b - road.a
		local t = math.clamp((p - road.a):Dot(ab) / ab:Dot(ab), 0, 1)
		local distance = (p - (road.a + ab * t)).Magnitude - road.halfWidth
		best = math.min(best, distance)
	end
	return best
end

return Roads
