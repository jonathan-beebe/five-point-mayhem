-- Snowball: a hand-packed wet-snow snowball with palm-pressed ice, refrozen glaze and picked-up debris.

local WeaponModel = require(script.Parent.Parent.systems.WeaponModel)

local rgb = Color3.fromRGB
local M = Enum.Material
local BALL = Enum.PartType.Ball
local CYL = Enum.PartType.Cylinder

local snowWhite = rgb(248, 250, 255)
local snowShadow = rgb(228, 235, 245)
local packedIce = rgb(214, 230, 243)
local iceGlaze = rgb(196, 222, 240)
local glint = rgb(240, 248, 255)
local grit = rgb(92, 80, 68)
local leafBrown = rgb(122, 84, 46)
local leafStem = rgb(90, 62, 36)
local pineNeedle = rgb(96, 104, 58)

-- Debris frames: local -Z points out of the snow along the surface normal.
local leafFrame = CFrame.lookAt(
	Vector3.new(-0.322, 0.639, -0.195),
	Vector3.new(-0.875, 1.394, 0.157)
) * CFrame.Angles(0, 0, math.rad(35))
local needleFrame = CFrame.lookAt(
	Vector3.new(0.418, 0.506, -0.623),
	Vector3.new(1.159, 1.05, -1.018)
) * CFrame.Angles(0, 0, math.rad(-20))

local function snow(name, s, x, y, z, color)
	return {
		name = name,
		shape = BALL,
		size = Vector3.new(s, s, s),
		offset = CFrame.new(x, y, z),
		color = color,
		material = M.Snow,
	}
end

local function glaze(name, s, x, y, z)
	return {
		name = name,
		shape = BALL,
		size = Vector3.new(s, s, s),
		offset = CFrame.new(x, y, z),
		color = iceGlaze,
		material = M.Ice,
		transparency = 0.35,
		reflectance = 0.2,
	}
end

local function packed(name, s, x, y, z)
	return {
		name = name,
		shape = BALL,
		size = Vector3.new(s, s, s),
		offset = CFrame.new(x, y, z),
		color = packedIce,
		material = M.Glacier,
		reflectance = 0.05,
	}
end

local function crystal(name, s, x, y, z)
	return {
		name = name,
		shape = BALL,
		size = Vector3.new(s, s, s),
		offset = CFrame.new(x, y, z),
		color = glint,
		material = M.Glass,
		transparency = 0.1,
		reflectance = 0.5,
	}
end

local function speck(name, s, x, y, z)
	return {
		name = name,
		shape = BALL,
		size = Vector3.new(s, s, s),
		offset = CFrame.new(x, y, z),
		color = grit,
		material = M.Rock,
	}
end

return WeaponModel.define({
	handle = {
		size = Vector3.new(0.4, 0.4, 0.4),
		color = snowWhite,
		material = M.Snow,
		transparency = 1,
	},
	muzzle = CFrame.new(0, 0.2, -1.05),
	pieces = {
		-- Core lobes
		snow("Core", 1.12, 0, 0.2, -0.4, snowWhite),
		snow("LobeUpperLeft", 0.9, -0.14, 0.32, -0.46, snowWhite),
		snow("LobeLowerRight", 0.92, 0.13, 0.08, -0.33, snowShadow),
		snow("LobeFront", 0.86, 0.04, 0.18, -0.6, snowWhite),
		snow("LobeBack", 0.84, -0.06, 0.24, -0.22, snowShadow),

		-- Packing bumps (knuckle and palm lumps)
		snow("BumpTop", 0.46, 0.039, 0.586, -0.439, snowShadow),
		snow("BumpRight", 0.44, 0.376, 0.275, -0.513, snowWhite),
		snow("BumpLeftLow", 0.42, -0.37, 0.052, -0.437, snowShadow),
		snow("BumpUnder", 0.4, 0.075, -0.174, -0.55, snowShadow),
		snow("BumpFrontHigh", 0.4, -0.109, 0.381, -0.762, snowWhite),
		snow("BumpBackRight", 0.38, 0.225, 0.388, -0.099, snowWhite),
		snow("BumpFrontLowRight", 0.36, 0.218, -0.018, -0.749, snowShadow),
		snow("BumpBackLeftLow", 0.36, -0.246, -0.005, -0.113, snowShadow),

		-- Loose powder clumps
		snow("Powder1", 0.18, 0.149, 0.646, -0.202, snowWhite),
		snow("Powder2", 0.16, -0.397, 0.54, -0.683, snowWhite),
		snow("Powder3", 0.14, 0.431, 0.152, -0.687, snowWhite),
		snow("Powder4", 0.15, -0.198, 0.101, -0.895, snowWhite),
		snow("Powder5", 0.12, 0.355, 0.555, -0.552, snowWhite),
		snow("Powder6", 0.14, -0.452, 0.25, -0.149, snowWhite),
		snow("Powder7", 0.13, 0.049, -0.096, 0.045, snowWhite),
		snow("Powder8", 0.11, 0.11, 0.365, -0.949, snowWhite),

		-- Refrozen ice glaze
		glaze("IceCapFront", 0.34, 0.121, 0.273, -0.886),
		glaze("IceCapLeft", 0.3, -0.476, 0.319, -0.566),
		glaze("IceCapTopBack", 0.28, -0.093, 0.597, -0.166),
		glaze("IceCapRightLow", 0.26, 0.481, -0.055, -0.343),
		glaze("IceCapUnderFront", 0.24, -0.094, -0.177, -0.682),

		-- Palm-pressed packed patches
		packed("PackedPatchRight", 0.32, 0.4, 0.38, -0.3),
		packed("PackedPatchLeftTop", 0.3, -0.317, 0.623, -0.453),
		packed("PackedPatchBottom", 0.3, 0, -0.262, -0.331),

		-- Ice-crystal glints
		crystal("Glint1", 0.05, 0.218, 0.527, -0.782),
		crystal("Glint2", 0.045, -0.287, 0.43, -0.86),
		crystal("Glint3", 0.05, 0.469, 0.376, -0.166),
		crystal("Glint4", 0.045, -0.172, 0.743, -0.343),
		crystal("Glint5", 0.04, 0.355, 0.022, -0.844),
		crystal("Glint6", 0.045, -0.487, 0.085, -0.629),

		-- Grit specks
		speck("Grit1", 0.05, 0.322, 0.259, -0.897),
		speck("Grit2", 0.045, -0.268, -0.217, -0.162),
		speck("Grit3", 0.04, 0.089, -0.364, -0.519),

		-- Debris
		{
			name = "LeafFragment",
			size = Vector3.new(0.15, 0.09, 0.012),
			offset = leafFrame,
			color = leafBrown,
			material = M.Fabric,
		},
		{
			name = "LeafStem",
			shape = CYL,
			size = Vector3.new(0.07, 0.012, 0.012),
			offset = leafFrame * CFrame.new(0.105, 0, 0.006),
			color = leafStem,
			material = M.Wood,
		},
		{
			name = "PineNeedle",
			shape = CYL,
			size = Vector3.new(0.22, 0.018, 0.018),
			offset = needleFrame,
			color = pineNeedle,
			material = M.Plastic,
		},
	},
})
