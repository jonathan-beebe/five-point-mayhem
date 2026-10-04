-- Pool Noodle: jumbo fluted 8-lobe hollow-core EPE foam pool noodle, hot pink, sagging under its own weight.

local WeaponModel = require(script.Parent.Parent.systems.WeaponModel)

local rgb = Color3.fromRGB
local M = Enum.Material
local CYLINDER_Z = WeaponModel.CYLINDER_Z
local CYL = Enum.PartType.Cylinder
local R = math.rad

local foamPink = rgb(255, 90, 180)
local coreWall = rgb(215, 70, 150)
local coreShadow = rgb(120, 30, 80)
local labelPaper = rgb(240, 238, 228)
local barcodeInk = rgb(30, 30, 30)
local brandBlue = rgb(40, 90, 200)

-- Segment frames: three straight runs with small kinks so the noodle droops (-4, then -10 degrees total).
local FA = CFrame.new(0, 0, 0)
local J1 = CFrame.new(0, 0, -1.9) * CFrame.Angles(R(-4), 0, 0)
local J2 = J1 * CFrame.new(0, 0, -2.3) * CFrame.Angles(R(-6), 0, 0)
local TIP = J2 * CFrame.new(0, 0, -2.2)

-- Label sits in the groove between ridge 0 (top) and ridge 7, toward the wielder's right.
local LABEL_ROT = CFrame.Angles(0, 0, R(-22.5))

local pieces = {
	-- Segment A (straight, holds the hand)
	{
		name = "NoodleA_Body",
		shape = CYL,
		size = Vector3.new(2.56, 0.8, 0.8),
		offset = FA * CFrame.new(0, 0, -0.68) * CYLINDER_Z,
		color = foamPink,
		material = M.Plaster,
	},
	-- Segment B (-4 degrees)
	{
		name = "NoodleB_Body",
		shape = CYL,
		size = Vector3.new(2.42, 0.8, 0.8),
		offset = J1 * CFrame.new(0, 0, -1.15) * CYLINDER_Z,
		color = foamPink,
		material = M.Plaster,
	},
	-- Segment C (-10 degrees total)
	{
		name = "NoodleC_Body",
		shape = CYL,
		size = Vector3.new(2.26, 0.8, 0.8),
		offset = J2 * CFrame.new(0, 0, -1.07) * CYLINDER_Z,
		color = foamPink,
		material = M.Plaster,
	},

	-- Butt cut end: hollow core
	{
		name = "ButtCoreWall",
		shape = CYL,
		size = Vector3.new(0.02, 0.36, 0.36),
		offset = CFrame.new(0, 0, 0.6) * CYLINDER_Z,
		color = coreWall,
		material = M.Plaster,
	},
	{
		name = "ButtCoreHole",
		shape = CYL,
		size = Vector3.new(0.04, 0.26, 0.26),
		offset = CFrame.new(0, 0, 0.6) * CYLINDER_Z,
		color = coreShadow,
		material = M.SmoothPlastic,
	},

	-- Tip cut end: hollow core
	{
		name = "TipCoreWall",
		shape = CYL,
		size = Vector3.new(0.02, 0.36, 0.36),
		offset = TIP * CYLINDER_Z,
		color = coreWall,
		material = M.Plaster,
	},
	{
		name = "TipCoreHole",
		shape = CYL,
		size = Vector3.new(0.04, 0.26, 0.26),
		offset = TIP * CYLINDER_Z,
		color = coreShadow,
		material = M.SmoothPlastic,
	},

	-- Retail price/UPC sticker on segment A, just ahead of the fist
	{
		name = "Label",
		size = Vector3.new(0.12, 0.01, 0.3),
		offset = FA * CFrame.new(0, 0, -1.25) * LABEL_ROT * CFrame.new(0, 0.405, 0),
		color = labelPaper,
		material = M.SmoothPlastic,
	},
	{
		name = "LabelBarcode",
		size = Vector3.new(0.07, 0.01, 0.12),
		offset = FA * CFrame.new(0, 0, -1.32) * LABEL_ROT * CFrame.new(0, 0.415, 0),
		color = barcodeInk,
		material = M.SmoothPlastic,
	},
	{
		name = "LabelBrandStripe",
		size = Vector3.new(0.1, 0.01, 0.05),
		offset = FA * CFrame.new(0, 0, -1.13) * LABEL_ROT * CFrame.new(0, 0.415, 0),
		color = brandBlue,
		material = M.SmoothPlastic,
	},
}

-- Fluting: 8 half-buried ridges per segment (k = 0 on top, stepping 45 degrees; inner edge r 0.30, outer r 0.46).
-- Ridge ends stop 0.02 short of each free cut face so the end shows the star outline without z-fighting.
local function addRidges(segment: string, frame: CFrame, zCenter: number, length: number)
	for k = 0, 7 do
		table.insert(pieces, {
			name = `{segment}_Ridge{k}`,
			shape = CYL,
			size = Vector3.new(length, 0.16, 0.16),
			offset = frame
				* CFrame.new(0, 0, zCenter)
				* CFrame.Angles(0, 0, R(k * 45))
				* CFrame.new(0, 0.38, 0)
				* CYLINDER_Z,
			color = foamPink,
			material = M.Plaster,
		})
	end
end

addRidges("NoodleA", FA, -0.69, 2.54) -- z +0.58 to -1.96
addRidges("NoodleB", J1, -1.15, 2.42) -- local +0.06 to -2.36
addRidges("NoodleC", J2, -1.06, 2.24) -- local +0.06 to -2.18

-- Held upright: the noodle rises from the fist (-Z) and its droop (-Y) leans toward the target.
return WeaponModel.define({
	hold = "upright",
	handle = {
		size = Vector3.new(0.4, 0.4, 1.2),
		color = foamPink,
		material = M.Plaster,
		transparency = 1,
	},
	pieces = pieces,
})
