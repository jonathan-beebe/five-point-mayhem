-- Frost Dagger: 16th-century European quillon (parrying) dagger with a glacial-ice blade.

local WeaponModel = require(script.Parent.Parent.systems.WeaponModel)

local rgb = Color3.fromRGB
local M = Enum.Material
local CYLINDER_Z = WeaponModel.CYLINDER_Z
local CYLINDER_Y = WeaponModel.CYLINDER_Y
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball

local function rx(degrees: number): CFrame
	return CFrame.Angles(math.rad(degrees), 0, 0)
end

local FLIP = CFrame.Angles(0, 0, math.pi) -- mirrors a wedge below the blade centreline

local glacialIce = rgb(160, 220, 255)
local ridgeIce = rgb(190, 232, 255)
local frostCore = rgb(140, 215, 255)
local frostSteel = rgb(168, 178, 188)
local darkSteel = rgb(90, 98, 108)
local silverWire = rgb(200, 205, 212)
local gripLeather = rgb(34, 40, 52)
local rime = rgb(235, 244, 250)
local crystalGlass = rgb(185, 230, 255)
local pommelGlow = rgb(140, 215, 255)

local function wireBand(index: number, z: number)
	return {
		name = "WireBand" .. index,
		shape = CYL,
		size = Vector3.new(0.03, 0.32, 0.32),
		offset = CFrame.new(0, 0, z) * CYLINDER_Z,
		color = silverWire,
		material = M.Metal,
		reflectance = 0.2,
	}
end

return WeaponModel.define({
	handle = {
		size = Vector3.new(0.28, 0.28, 1.05),
		color = gripLeather,
		material = M.Leather,
		transparency = 1,
	},
	pieces = {
		-- Blade: z -0.80 to -3.05, edges up/down, flats facing ±X
		{
			name = "BladeUpper",
			class = "WedgePart",
			size = Vector3.new(0.06, 0.25, 2.25),
			offset = CFrame.new(0, 0.125, -1.925),
			color = glacialIce,
			material = M.Ice,
			transparency = 0.3,
			reflectance = 0.1,
		},
		{
			name = "BladeLower",
			class = "WedgePart",
			size = Vector3.new(0.06, 0.25, 2.25),
			offset = CFrame.new(0, -0.125, -1.925) * FLIP,
			color = glacialIce,
			material = M.Ice,
			transparency = 0.3,
			reflectance = 0.1,
		},
		-- Ridge halves overlap the centreline by 0.012 so their flat faces clear the blade's at y = 0
		{
			name = "RidgeUpper",
			class = "WedgePart",
			size = Vector3.new(0.13, 0.112, 2.15),
			offset = CFrame.new(0, 0.044, -1.875),
			color = ridgeIce,
			material = M.Ice,
			transparency = 0.2,
			reflectance = 0.1,
		},
		{
			name = "RidgeLower",
			class = "WedgePart",
			size = Vector3.new(0.13, 0.112, 2.15),
			offset = CFrame.new(0, -0.044, -1.875) * FLIP,
			color = ridgeIce,
			material = M.Ice,
			transparency = 0.2,
			reflectance = 0.1,
		},
		{
			name = "CoreUpper",
			class = "WedgePart",
			size = Vector3.new(0.02, 0.095, 1.9),
			offset = CFrame.new(0, 0.0225, -1.75),
			color = frostCore,
			material = M.Neon,
			transparency = 0.35,
		},
		{
			name = "CoreLower",
			class = "WedgePart",
			size = Vector3.new(0.02, 0.095, 1.9),
			offset = CFrame.new(0, -0.0225, -1.75) * FLIP,
			color = frostCore,
			material = M.Neon,
			transparency = 0.35,
		},

		-- Blade mount: steel collar, riveted langets on each flat
		{
			name = "BladeCollar",
			size = Vector3.new(0.2, 0.54, 0.1),
			offset = CFrame.new(0, 0, -0.79),
			color = frostSteel,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "LangetRight",
			size = Vector3.new(0.02, 0.14, 0.24),
			offset = CFrame.new(0.07, 0, -0.92),
			color = darkSteel,
			material = M.Metal,
		},
		{
			name = "LangetLeft",
			size = Vector3.new(0.02, 0.14, 0.24),
			offset = CFrame.new(-0.07, 0, -0.92),
			color = darkSteel,
			material = M.Metal,
		},
		{
			name = "RivetRight",
			shape = BALL,
			size = Vector3.new(0.05, 0.05, 0.05),
			offset = CFrame.new(0.088, 0, -0.97),
			color = frostSteel,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "RivetLeft",
			shape = BALL,
			size = Vector3.new(0.05, 0.05, 0.05),
			offset = CFrame.new(-0.088, 0, -0.97),
			color = frostSteel,
			material = M.Metal,
			reflectance = 0.1,
		},

		-- Guard: centre block, quillons curving 10 degrees toward the blade, rings, ball finials, rime
		{
			name = "GuardBlock",
			size = Vector3.new(0.24, 0.34, 0.15),
			offset = CFrame.new(0, 0, -0.695),
			color = frostSteel,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "QuillonUpper",
			shape = CYL,
			size = Vector3.new(0.4, 0.1, 0.1),
			offset = CFrame.new(0, 0.35, -0.695) * rx(-10) * CYLINDER_Y,
			color = frostSteel,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "QuillonLower",
			shape = CYL,
			size = Vector3.new(0.4, 0.1, 0.1),
			offset = CFrame.new(0, -0.35, -0.695) * rx(10) * CYLINDER_Y,
			color = frostSteel,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "QuillonRingUpper",
			shape = CYL,
			size = Vector3.new(0.03, 0.13, 0.13),
			offset = CFrame.new(0, 0.498, -0.721) * rx(-10) * CYLINDER_Y,
			color = darkSteel,
			material = M.Metal,
		},
		{
			name = "QuillonRingLower",
			shape = CYL,
			size = Vector3.new(0.03, 0.13, 0.13),
			offset = CFrame.new(0, -0.498, -0.721) * rx(10) * CYLINDER_Y,
			color = darkSteel,
			material = M.Metal,
		},
		{
			name = "FinialUpper",
			shape = BALL,
			size = Vector3.new(0.16, 0.16, 0.16),
			offset = CFrame.new(0, 0.58, -0.735),
			color = frostSteel,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "FinialLower",
			shape = BALL,
			size = Vector3.new(0.16, 0.16, 0.16),
			offset = CFrame.new(0, -0.58, -0.735),
			color = frostSteel,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "RimeRight",
			size = Vector3.new(0.02, 0.26, 0.12),
			offset = CFrame.new(0.125, 0, -0.695),
			color = rime,
			material = M.Snow,
		},
		{
			name = "RimeLeft",
			size = Vector3.new(0.02, 0.26, 0.12),
			offset = CFrame.new(-0.125, 0, -0.695),
			color = rime,
			material = M.Snow,
		},

		-- Grip: leather core, steel ferrules, raised silver wire bands
		{
			name = "GripCore",
			shape = CYL,
			size = Vector3.new(1.05, 0.3, 0.3),
			offset = CFrame.new(0, 0, -0.015) * CYLINDER_Z,
			color = gripLeather,
			material = M.Leather,
		},
		{
			name = "FerruleFront",
			shape = CYL,
			size = Vector3.new(0.08, 0.36, 0.36),
			offset = CFrame.new(0, 0, -0.585) * CYLINDER_Z,
			color = frostSteel,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "FerruleRear",
			shape = CYL,
			size = Vector3.new(0.08, 0.36, 0.36),
			offset = CFrame.new(0, 0, 0.545) * CYLINDER_Z,
			color = frostSteel,
			material = M.Metal,
			reflectance = 0.1,
		},
		wireBand(1, -0.45),
		wireBand(2, -0.32),
		wireBand(3, -0.19),
		wireBand(4, -0.06),
		wireBand(5, 0.07),
		wireBand(6, 0.2),
		wireBand(7, 0.33),
		wireBand(8, 0.46),

		-- Pommel: steel wheel (axis X) with a glowing disc under a glass crystal on each face, tang peen
		{
			name = "PommelWheel",
			shape = CYL,
			size = Vector3.new(0.16, 0.42, 0.42),
			offset = CFrame.new(0, 0, 0.78),
			color = frostSteel,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "PommelGlowRight",
			shape = CYL,
			size = Vector3.new(0.03, 0.12, 0.12),
			offset = CFrame.new(0.085, 0, 0.78),
			color = pommelGlow,
			material = M.Neon,
		},
		{
			name = "PommelGlowLeft",
			shape = CYL,
			size = Vector3.new(0.03, 0.12, 0.12),
			offset = CFrame.new(-0.085, 0, 0.78),
			color = pommelGlow,
			material = M.Neon,
		},
		{
			name = "PommelCrystalRight",
			shape = CYL,
			size = Vector3.new(0.04, 0.2, 0.2),
			offset = CFrame.new(0.09, 0, 0.78),
			color = crystalGlass,
			material = M.Glass,
			transparency = 0.35,
		},
		{
			name = "PommelCrystalLeft",
			shape = CYL,
			size = Vector3.new(0.04, 0.2, 0.2),
			offset = CFrame.new(-0.09, 0, 0.78),
			color = crystalGlass,
			material = M.Glass,
			transparency = 0.35,
		},
		{
			name = "TangPeen",
			shape = CYL,
			size = Vector3.new(0.06, 0.08, 0.08),
			offset = CFrame.new(0, 0, 1) * CYLINDER_Z,
			color = darkSteel,
			material = M.Metal,
		},
	},
})
