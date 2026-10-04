-- Bubble Wand: craftsman's turned-walnut magic wand with brass fittings, a prong-set glass crystal and a brass bubble loop holding a soap film.

local WeaponModel = require(script.Parent.Parent.systems.WeaponModel)

local rgb = Color3.fromRGB
local M = Enum.Material
local CYLINDER_Z = WeaponModel.CYLINDER_Z
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball

local walnut = rgb(96, 62, 40)
local brass = rgb(184, 148, 74)
local antiqueBrass = rgb(140, 108, 52)
local polishedBrass = rgb(200, 166, 92)
local crystalGlass = rgb(210, 238, 255)
local glowCore = rgb(150, 220, 255)
local soapFilm = rgb(150, 220, 255)

-- Bubble loop: wire ring in the XY plane facing the target, bottom of the ring on the shaft axis.
local LOOP_Z = -2.05
local LOOP_RADIUS = 0.36
local LOOP_SEGMENTS = 12

local pieces = {
	-- Grip
	{
		name = "PommelFinial",
		shape = BALL,
		size = Vector3.new(0.2, 0.2, 0.2),
		offset = CFrame.new(0, 0, 0.5),
		color = brass,
		material = M.Metal,
		reflectance = 0.1,
	},
	{
		name = "PommelCap",
		shape = CYL,
		size = Vector3.new(0.06, 0.25, 0.25),
		offset = CFrame.new(0, 0, 0.42) * CYLINDER_Z,
		color = brass,
		material = M.Metal,
		reflectance = 0.1,
	},
	{
		name = "GripCore",
		shape = CYL,
		size = Vector3.new(0.82, 0.24, 0.24),
		offset = CFrame.new(0, 0, -0.01) * CYLINDER_Z,
		color = walnut,
		material = M.Wood,
	},
	{
		name = "GripSwell",
		shape = CYL,
		size = Vector3.new(0.4, 0.27, 0.27),
		offset = CFrame.new(0, 0, 0.05) * CYLINDER_Z,
		color = walnut,
		material = M.Wood,
	},
	{
		name = "InlayRingRear",
		shape = CYL,
		size = Vector3.new(0.02, 0.285, 0.285),
		offset = CFrame.new(0, 0, 0.25) * CYLINDER_Z,
		color = antiqueBrass,
		material = M.Metal,
	},
	{
		name = "InlayRingFront",
		shape = CYL,
		size = Vector3.new(0.02, 0.285, 0.285),
		offset = CFrame.new(0, 0, -0.15) * CYLINDER_Z,
		color = antiqueBrass,
		material = M.Metal,
	},
	{
		name = "GripFerrule",
		shape = CYL,
		size = Vector3.new(0.08, 0.27, 0.27),
		offset = CFrame.new(0, 0, -0.45) * CYLINDER_Z,
		color = brass,
		material = M.Metal,
		reflectance = 0.1,
	},
	{
		name = "TaperCollar",
		shape = CYL,
		size = Vector3.new(0.1, 0.2, 0.2),
		offset = CFrame.new(0, 0, -0.535) * CYLINDER_Z,
		color = brass,
		material = M.Metal,
		reflectance = 0.1,
	},

	-- Shaft
	{
		name = "ShaftLower",
		shape = CYL,
		size = Vector3.new(0.52, 0.16, 0.16),
		offset = CFrame.new(0, 0, -0.84) * CYLINDER_Z,
		color = walnut,
		material = M.Wood,
	},
	{
		name = "ShaftBand1",
		shape = CYL,
		size = Vector3.new(0.04, 0.19, 0.19),
		offset = CFrame.new(0, 0, -1.09) * CYLINDER_Z,
		color = antiqueBrass,
		material = M.Metal,
	},
	{
		name = "ShaftUpper",
		shape = CYL,
		size = Vector3.new(0.5, 0.13, 0.13),
		offset = CFrame.new(0, 0, -1.34) * CYLINDER_Z,
		color = walnut,
		material = M.Wood,
	},
	{
		name = "ShaftBand2",
		shape = CYL,
		size = Vector3.new(0.06, 0.16, 0.16),
		offset = CFrame.new(0, 0, -1.59) * CYLINDER_Z,
		color = brass,
		material = M.Metal,
		reflectance = 0.1,
	},
	{
		name = "RodRear",
		shape = CYL,
		size = Vector3.new(0.14, 0.07, 0.07),
		offset = CFrame.new(0, 0, -1.68) * CYLINDER_Z,
		color = brass,
		material = M.Metal,
		reflectance = 0.1,
	},

	-- Crystal setting
	{
		name = "CupRear",
		shape = CYL,
		size = Vector3.new(0.04, 0.2, 0.2),
		offset = CFrame.new(0, 0, -1.76) * CYLINDER_Z,
		color = brass,
		material = M.Metal,
		reflectance = 0.1,
	},
	{
		name = "CrystalOrb",
		shape = BALL,
		size = Vector3.new(0.18, 0.18, 0.18),
		offset = CFrame.new(0, 0, -1.85),
		color = crystalGlass,
		material = M.Glass,
		transparency = 0.35,
		reflectance = 0.2,
	},
	{
		name = "CrystalCore",
		shape = BALL,
		size = Vector3.new(0.1, 0.1, 0.1),
		offset = CFrame.new(0, 0, -1.85),
		color = glowCore,
		material = M.Neon,
	},
	{
		name = "ProngTop",
		size = Vector3.new(0.025, 0.025, 0.18),
		offset = CFrame.new(0, 0.085, -1.85),
		color = antiqueBrass,
		material = M.Metal,
	},
	{
		name = "ProngBottom",
		size = Vector3.new(0.025, 0.025, 0.18),
		offset = CFrame.new(0, -0.085, -1.85),
		color = antiqueBrass,
		material = M.Metal,
	},
	{
		name = "ProngRight",
		size = Vector3.new(0.025, 0.025, 0.18),
		offset = CFrame.new(0.085, 0, -1.85),
		color = antiqueBrass,
		material = M.Metal,
	},
	{
		name = "ProngLeft",
		size = Vector3.new(0.025, 0.025, 0.18),
		offset = CFrame.new(-0.085, 0, -1.85),
		color = antiqueBrass,
		material = M.Metal,
	},
	{
		name = "CupFront",
		shape = CYL,
		size = Vector3.new(0.04, 0.2, 0.2),
		offset = CFrame.new(0, 0, -1.94) * CYLINDER_Z,
		color = brass,
		material = M.Metal,
		reflectance = 0.1,
	},

	-- Loop mount
	{
		name = "RodFront",
		shape = CYL,
		size = Vector3.new(0.12, 0.07, 0.07),
		offset = CFrame.new(0, 0, -2.0) * CYLINDER_Z,
		color = brass,
		material = M.Metal,
		reflectance = 0.1,
	},
	{
		name = "LoopJoint",
		shape = BALL,
		size = Vector3.new(0.1, 0.1, 0.1),
		offset = CFrame.new(0, 0, LOOP_Z),
		color = polishedBrass,
		material = M.Metal,
		reflectance = 0.2,
	},

	-- Soap film stretched across the loop, inside the wire
	{
		name = "SoapFilm",
		shape = CYL,
		size = Vector3.new(0.01, 0.7, 0.7),
		offset = CFrame.new(0, LOOP_RADIUS, LOOP_Z) * CYLINDER_Z,
		color = soapFilm,
		material = M.ForceField,
	},

	-- Bubbles: one budding through the film, one drifting free in front of it
	{
		name = "BuddingBubble",
		shape = BALL,
		size = Vector3.new(0.3, 0.3, 0.3),
		offset = CFrame.new(0.05, 0.42, -2.13),
		color = soapFilm,
		material = M.ForceField,
	},
	{
		name = "DriftBubble",
		shape = BALL,
		size = Vector3.new(0.12, 0.12, 0.12),
		offset = CFrame.new(0.16, 0.6, -2.42),
		color = soapFilm,
		material = M.ForceField,
	},
}

-- Loop wire: 12 round segments, each cylinder's X axis turned onto the ring tangent.
-- Segment 9 (theta = 270 degrees) is the bottom of the ring, sitting on LoopJoint.
for i = 0, LOOP_SEGMENTS - 1 do
	local theta = math.rad(360 / LOOP_SEGMENTS * i)
	table.insert(pieces, {
		name = string.format("LoopWire%02d", i + 1),
		shape = CYL,
		size = Vector3.new(0.21, 0.06, 0.06),
		offset = CFrame.new(
			LOOP_RADIUS * math.cos(theta),
			LOOP_RADIUS + LOOP_RADIUS * math.sin(theta),
			LOOP_Z
		) * CFrame.Angles(0, 0, theta + math.rad(90)),
		color = polishedBrass,
		material = M.Metal,
		reflectance = 0.2,
	})
end

return WeaponModel.define({
	handle = {
		size = Vector3.new(0.26, 0.26, 0.9),
		color = walnut,
		material = M.Wood,
		transparency = 1,
	},
	muzzle = CFrame.new(0, LOOP_RADIUS, -2.1),
	pieces = pieces,
})
