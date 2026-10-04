-- Katana: Edo-period shinogi-zukuri uchigatana, suguha hamon, chu-kissaki, black silk tsuka-ito over samegawa.

local WeaponModel = require(script.Parent.Parent.systems.WeaponModel)

local rgb = Color3.fromRGB
local M = Enum.Material
local CYLINDER_Z = WeaponModel.CYLINDER_Z
local CYL = Enum.PartType.Cylinder

local function rx(degrees: number): CFrame
	return CFrame.Angles(math.rad(degrees), 0, 0)
end

local R45 = rx(45) -- turns a square block into a diamond seen from the side
local FLIP = CFrame.Angles(0, 0, math.pi) -- wedge: full top face (spine), back face at +Z, slope rising to the point

-- Blade segment frames: each starts where the previous ends, adding 1.5 degrees of tori-zori per joint.
local SEG1 = CFrame.new(0, 0, -0.76)
local SEG2 = CFrame.new(0, 0, -2.16) * rx(1.5)
local SEG3 = CFrame.new(0, 0.0366, -3.5595) * rx(3)
local KISS = CFrame.new(0, 0.1047, -4.8577) * rx(4.5)

local ito = rgb(34, 32, 46)
local itoCross = rgb(50, 48, 66)
local samegawa = rgb(228, 222, 204)
local shakudo = rgb(42, 38, 38)
local menukiGold = rgb(184, 148, 70)
local bamboo = rgb(186, 160, 108)
local tsubaIron = rgb(52, 47, 43)
local brass = rgb(160, 124, 62)
local copper = rgb(150, 92, 62)
local seppaGilt = rgb(196, 158, 86)
local habakiGold = rgb(190, 142, 74)
local jiDark = rgb(96, 100, 108)
local ridge = rgb(168, 172, 180)
local hira = rgb(138, 143, 151)
local hamon = rgb(212, 214, 219)
local edge = rgb(235, 235, 240)

local function diamond(index: number, z: number)
	return {
		name = "SameDiamond" .. index,
		size = Vector3.new(0.27, 0.1, 0.1),
		offset = CFrame.new(0, 0, z) * R45,
		color = samegawa,
		material = M.Fabric,
	}
end

local function itoCrossing(index: number, z: number)
	return {
		name = "ItoCross" .. index,
		size = Vector3.new(0.27, 0.32, 0.025),
		offset = CFrame.new(0, 0, z),
		color = itoCross,
		material = M.Fabric,
	}
end

-- One layer of a blade segment's stepped cross-section; length runs along the segment's local -Z.
local function bladeLayer(
	name: string,
	frame: CFrame,
	width: number,
	height: number,
	y: number,
	length: number,
	zCenter: number,
	color: Color3,
	reflectance: number
)
	return {
		name = name,
		size = Vector3.new(width, height, length),
		offset = frame * CFrame.new(0, y, zCenter),
		color = color,
		material = M.Metal,
		reflectance = reflectance,
	}
end

return WeaponModel.define({
	hold = "upright",
	-- Slide the sword 0.3 toward the kashira so the fist sits on the tsuka just below the tsuba.
	-- The edge (convex side) is built at -Y, which the upright hold turns toward the target.
	rotation = CFrame.new(0, 0, 0.3),
	handle = {
		size = Vector3.new(0.24, 0.28, 1.2),
		color = ito,
		material = M.Fabric,
		transparency = 1,
	},
	pieces = {
		-- Tsuka: z +0.81 (kashira cap) to -0.64 (fuchi), before the 0.3 slide toward +Z
		{
			name = "ItoSleeve",
			size = Vector3.new(0.25, 0.3, 1.26),
			offset = CFrame.new(0, 0, 0.07),
			color = ito,
			material = M.Fabric,
		},
		diamond(1, -0.44),
		diamond(2, -0.27),
		diamond(3, -0.1),
		diamond(4, 0.07),
		diamond(5, 0.24),
		diamond(6, 0.41),
		diamond(7, 0.58),
		itoCrossing(1, -0.355),
		itoCrossing(2, -0.185),
		itoCrossing(3, -0.015),
		itoCrossing(4, 0.155),
		itoCrossing(5, 0.325),
		itoCrossing(6, 0.495),
		{
			name = "MenukiRight",
			size = Vector3.new(0.02, 0.06, 0.13),
			offset = CFrame.new(0.145, 0, 0.07),
			color = menukiGold,
			material = M.Metal,
			reflectance = 0.15,
		},
		{
			name = "MenukiLeft",
			size = Vector3.new(0.02, 0.06, 0.13),
			offset = CFrame.new(-0.145, 0, 0.24),
			color = menukiGold,
			material = M.Metal,
			reflectance = 0.15,
		},
		{
			name = "Mekugi",
			shape = CYL,
			size = Vector3.new(0.29, 0.05, 0.05),
			offset = CFrame.new(0, 0, -0.44),
			color = bamboo,
			material = M.Wood,
		},
		{
			name = "Kashira",
			size = Vector3.new(0.27, 0.32, 0.08),
			offset = CFrame.new(0, 0, 0.74),
			color = shakudo,
			material = M.Metal,
		},
		{
			name = "KashiraCap",
			size = Vector3.new(0.23, 0.28, 0.03),
			offset = CFrame.new(0, 0, 0.795),
			color = shakudo,
			material = M.Metal,
		},
		{
			name = "Fuchi",
			size = Vector3.new(0.28, 0.33, 0.08),
			offset = CFrame.new(0, 0, -0.6),
			color = shakudo,
			material = M.Metal,
		},

		-- Guard stack: seppa, tsuba, seppa, z -0.64 to -0.76
		{
			name = "SeppaRear",
			size = Vector3.new(0.3, 0.36, 0.02),
			offset = CFrame.new(0, 0, -0.65),
			color = seppaGilt,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "Tsuba",
			shape = CYL,
			size = Vector3.new(0.08, 0.7, 0.7),
			offset = CFrame.new(0, 0, -0.7) * CYLINDER_Z,
			color = tsubaIron,
			material = M.CorrodedMetal,
		},
		{
			name = "TsubaFukurin",
			shape = CYL,
			size = Vector3.new(0.06, 0.73, 0.73),
			offset = CFrame.new(0, 0, -0.7) * CYLINDER_Z,
			color = brass,
			material = M.Metal,
		},
		{
			name = "HitsuPlugRight",
			shape = CYL,
			size = Vector3.new(0.1, 0.12, 0.12),
			offset = CFrame.new(0.22, 0, -0.7) * CYLINDER_Z,
			color = copper,
			material = M.Metal,
		},
		{
			name = "HitsuPlugLeft",
			shape = CYL,
			size = Vector3.new(0.1, 0.12, 0.12),
			offset = CFrame.new(-0.22, 0, -0.7) * CYLINDER_Z,
			color = copper,
			material = M.Metal,
		},
		{
			name = "SeppaFront",
			size = Vector3.new(0.3, 0.36, 0.02),
			offset = CFrame.new(0, 0, -0.75),
			color = seppaGilt,
			material = M.Metal,
			reflectance = 0.1,
		},

		-- Habaki: z -0.76 to -0.98, encloses the blade root
		{
			name = "HabakiCollar",
			size = Vector3.new(0.13, 0.34, 0.04),
			offset = CFrame.new(0, 0, -0.78),
			color = habakiGold,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "Habaki",
			size = Vector3.new(0.11, 0.32, 0.18),
			offset = CFrame.new(0, 0, -0.89),
			color = habakiGold,
			material = M.Metal,
			reflectance = 0.1,
		},

		-- Blade segment 1 (straight): mune, shinogi-ji, shinogi ridge, hira-ji, hamon, ha; edge down
		bladeLayer("S1Mune", SEG1, 0.045, 0.03, 0.125, 1.42, -0.7, jiDark, 0.15),
		bladeLayer("S1Shinogiji", SEG1, 0.062, 0.055, 0.0825, 1.42, -0.7, jiDark, 0.15),
		bladeLayer("S1Shinogi", SEG1, 0.078, 0.02, 0.045, 1.42, -0.7, ridge, 0.2),
		bladeLayer("S1Hiraji", SEG1, 0.066, 0.075, -0.0025, 1.42, -0.7, hira, 0.1),
		bladeLayer("S1Hamon", SEG1, 0.05, 0.065, -0.0725, 1.42, -0.7, hamon, 0.05),
		bladeLayer("S1Ha", SEG1, 0.034, 0.035, -0.1225, 1.42, -0.7, edge, 0.25),

		-- Blade segment 2 (1.5 degrees), every layer 0.01 thinner
		bladeLayer("S2Mune", SEG2, 0.035, 0.03, 0.125, 1.42, -0.7, jiDark, 0.15),
		bladeLayer("S2Shinogiji", SEG2, 0.052, 0.055, 0.0825, 1.42, -0.7, jiDark, 0.15),
		bladeLayer("S2Shinogi", SEG2, 0.068, 0.02, 0.045, 1.42, -0.7, ridge, 0.2),
		bladeLayer("S2Hiraji", SEG2, 0.056, 0.075, -0.0025, 1.42, -0.7, hira, 0.1),
		bladeLayer("S2Hamon", SEG2, 0.04, 0.065, -0.0725, 1.42, -0.7, hamon, 0.05),
		bladeLayer("S2Ha", SEG2, 0.024, 0.035, -0.1225, 1.42, -0.7, edge, 0.25),

		-- Blade segment 3 (3 degrees): local z +0.01 to -1.31, 0.01 into the kissaki to close the kink gap
		bladeLayer("S3Mune", SEG3, 0.025, 0.03, 0.125, 1.32, -0.65, jiDark, 0.15),
		bladeLayer("S3Shinogiji", SEG3, 0.042, 0.055, 0.0825, 1.32, -0.65, jiDark, 0.15),
		bladeLayer("S3Shinogi", SEG3, 0.058, 0.02, 0.045, 1.32, -0.65, ridge, 0.2),
		bladeLayer("S3Hiraji", SEG3, 0.046, 0.075, -0.0025, 1.32, -0.65, hira, 0.1),
		bladeLayer("S3Hamon", SEG3, 0.03, 0.065, -0.0725, 1.32, -0.65, hamon, 0.05),
		bladeLayer("S3Ha", SEG3, 0.014, 0.035, -0.1225, 1.32, -0.65, edge, 0.25),

		-- Kissaki (4.5 degrees): yokote at local z 0, point near the spine at z -5.356.
		-- Wedge tops step 0.01 apart (ji 0.14, boshi 0.13, ha 0.12) so no top faces are coplanar.
		{
			name = "KissakiHa",
			class = "WedgePart",
			size = Vector3.new(0.012, 0.26, 0.5),
			offset = KISS * CFrame.new(0, -0.01, -0.25) * FLIP,
			color = edge,
			material = M.Metal,
			reflectance = 0.25,
		},
		{
			name = "KissakiBoshi",
			class = "WedgePart",
			size = Vector3.new(0.024, 0.23, 0.43),
			offset = KISS * CFrame.new(0, 0.015, -0.215) * FLIP,
			color = hamon,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "KissakiJi",
			class = "WedgePart",
			size = Vector3.new(0.036, 0.15, 0.3),
			offset = KISS * CFrame.new(0, 0.065, -0.15) * FLIP,
			color = jiDark,
			material = M.Metal,
			reflectance = 0.15,
		},
	},
})
