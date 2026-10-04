-- Water Balloon: royal-blue latex party water balloon, 3-4 inch bulk-bag size, filled taut and hand-tied.

local WeaponModel = require(script.Parent.Parent.systems.WeaponModel)

local rgb = Color3.fromRGB
local M = Enum.Material
local CYLINDER_Z = WeaponModel.CYLINDER_Z
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball
local rad = math.rad

-- Finishes: color, transparency, reflectance. All SmoothPlastic (Glass hides transparent parts behind it).
type Finish = { color: Color3, transparency: number, reflectance: number }

local LATEX_STRETCHED: Finish =
	{ color = rgb(60, 140, 255), transparency = 0.3, reflectance = 0.25 }
local LATEX_GATHERED: Finish = { color = rgb(38, 98, 214), transparency = 0.12, reflectance = 0.12 }
local LATEX_KNOT: Finish = { color = rgb(30, 82, 190), transparency = 0, reflectance = 0.08 }
local LIP_OPENING: Finish = { color = rgb(14, 32, 70), transparency = 0, reflectance = 0 }
local WATER_CORE: Finish = { color = rgb(40, 110, 220), transparency = 0.45, reflectance = 0 }
local AIR_POCKET: Finish = { color = rgb(225, 240, 255), transparency = 0.55, reflectance = 0 }
local DROPLET: Finish = { color = rgb(200, 228, 255), transparency = 0.35, reflectance = 0.4 }

local function ball(
	name: string,
	diameter: number,
	offset: CFrame,
	finish: Finish
): WeaponModel.PieceSpec
	return {
		name = name,
		shape = BALL,
		size = Vector3.one * diameter,
		offset = offset,
		color = finish.color,
		material = M.SmoothPlastic,
		transparency = finish.transparency,
		reflectance = finish.reflectance,
	}
end

-- Cylinder with its axis along Z (length = X of size).
local function tube(
	name: string,
	length: number,
	diameter: number,
	offset: CFrame,
	finish: Finish
): WeaponModel.PieceSpec
	return {
		name = name,
		shape = CYL,
		size = Vector3.new(length, diameter, diameter),
		offset = offset * CYLINDER_Z,
		color = finish.color,
		material = M.SmoothPlastic,
		transparency = finish.transparency,
		reflectance = finish.reflectance,
	}
end

local pieces: { WeaponModel.PieceSpec } = {
	-- Skin shell: stretched translucent latex, teardrop tapering toward the wielder
	ball("Body", 1.4, CFrame.new(0, 0.2, -0.45), LATEX_STRETCHED),
	ball("Belly", 1.3, CFrame.new(0, 0.1, -0.42), LATEX_STRETCHED),
	ball("Shoulder", 0.95, CFrame.new(0, 0.2, -0.05), LATEX_STRETCHED),
	ball("Taper", 0.55, CFrame.new(0, 0.2, 0.25), LATEX_STRETCHED),

	-- Contents seen through the skin
	ball("WaterCore", 1.25, CFrame.new(0, 0.15, -0.45), WATER_CORE),
	ball("WaterCoreFront", 0.8, CFrame.new(0, 0.18, -0.05), WATER_CORE),
	ball("AirPocket", 0.32, CFrame.new(0.1, 0.68, -0.5), AIR_POCKET),

	-- Neck
	tube("Neck", 0.18, 0.14, CFrame.new(0, 0.2, 0.55), LATEX_GATHERED),

	-- Knot, wrap loop, tail and rolled lip
	ball("Knot", 0.22, CFrame.new(0, 0.2, 0.68), LATEX_KNOT),
	ball("KnotLobeA", 0.16, CFrame.new(0.07, 0.24, 0.66), LATEX_KNOT),
	ball("KnotLobeB", 0.14, CFrame.new(-0.06, 0.15, 0.71), LATEX_KNOT),
	{
		name = "KnotWrap",
		shape = CYL,
		size = Vector3.new(0.07, 0.24, 0.24),
		offset = CFrame.new(0, 0.2, 0.68) * CYLINDER_Z * CFrame.Angles(0, 0, rad(25)),
		color = LATEX_KNOT.color,
		material = M.SmoothPlastic,
		reflectance = LATEX_KNOT.reflectance,
	},
	tube("Tail", 0.1, 0.11, CFrame.new(0.02, 0.22, 0.81), LATEX_KNOT),
	tube("Lip", 0.05, 0.2, CFrame.new(0.02, 0.22, 0.88), LATEX_KNOT),
	tube("LipOpening", 0.07, 0.09, CFrame.new(0.02, 0.22, 0.88), LIP_OPENING),

	-- Water droplets beading on the wet skin (centres 0.69 from Body centre)
	ball("DropletA", 0.08, CFrame.new(0.346, 0.615, -0.879), DROPLET),
	ball("DropletB", 0.07, CFrame.new(-0.414, 0.407, -0.961), DROPLET),
	ball("DropletC", 0.09, CFrame.new(0.554, 0.062, -0.838), DROPLET),
	ball("DropletD", 0.07, CFrame.new(-0.224, 0.835, -0.6), DROPLET),
	ball("Drip", 0.1, CFrame.new(0.066, -0.553, -0.486), DROPLET),
	ball("DripTail", 0.06, CFrame.new(0.066, -0.61, -0.486), DROPLET),
}

-- Gather folds: eight pleats forming the cone of bunched skin between Taper and Neck.
for i = 0, 7 do
	table.insert(pieces, {
		name = "Pleat" .. (i + 1),
		size = Vector3.new(0.05, 0.035, 0.16),
		offset = CFrame.new(0, 0.2, 0.515)
			* CFrame.Angles(0, 0, rad(i * 45))
			* CFrame.new(0, 0.125, 0)
			* CFrame.Angles(rad(42), 0, 0),
		color = LATEX_GATHERED.color,
		material = M.SmoothPlastic,
		transparency = LATEX_GATHERED.transparency,
		reflectance = LATEX_GATHERED.reflectance,
	})
end

return WeaponModel.define({
	handle = {
		size = Vector3.new(0.4, 0.4, 1.2),
		color = LATEX_GATHERED.color,
		material = M.SmoothPlastic,
		transparency = 1,
	},
	muzzle = CFrame.new(0, 0.2, -1.2),
	pieces = pieces,
})
