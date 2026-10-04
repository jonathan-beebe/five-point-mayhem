-- Ice Wand: artisan crystal-tipped wand (turned ebony grip, holly shaft, clear quartz point in a three-claw sterling setting).

local WeaponModel = require(script.Parent.Parent.systems.WeaponModel)

local rgb = Color3.fromRGB
local M = Enum.Material
local CYLINDER_Z = WeaponModel.CYLINDER_Z
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball
local R = math.rad

local ebony = rgb(38, 30, 27)
local holly = rgb(214, 206, 188)
local knotWood = rgb(120, 100, 80)
local silver = rgb(192, 194, 198)
local quartzGlass = rgb(205, 235, 250)
local frostCore = rgb(170, 230, 255)
local rimeIce = rgb(200, 232, 245)
local inclusion = rgb(240, 248, 255)

-- Quartz hex geometry: vertices at 0/60/../300 degrees about Z, flat normals at 30/90/../330.
local HEX_SIDE = 0.162 -- side length = vertex radius
local HEX_APOTHEM = HEX_SIDE * math.cos(R(30)) -- 0.14, half the across-flats width
local FACET_BASE_Z = -2.24
local TIP_Z = -2.44
local FACET_THICKNESS = 0.02

-- Turned cylinder along the wand axis. size is (length, diameter, diameter).
local function turned(
	name: string,
	length: number,
	diameter: number,
	z: number,
	color: Color3,
	material: Enum.Material
)
	return {
		name = name,
		shape = CYL,
		size = Vector3.new(length, diameter, diameter),
		offset = CFrame.new(0, 0, z) * CYLINDER_Z,
		color = color,
		material = material,
		reflectance = if material == M.Metal then 0.1 else nil,
	}
end

local function silverRing(name: string, length: number, diameter: number, z: number)
	return turned(name, length, diameter, z, silver, M.Metal)
end

local function hollyTurn(name: string, length: number, diameter: number, z: number)
	return turned(name, length, diameter, z, holly, M.Wood)
end

local function ebonyTurn(name: string, length: number, diameter: number, z: number)
	return turned(name, length, diameter, z, ebony, M.Wood)
end

-- Rime crust on Shaft3: thick end against the setting at z -1.85, thinning toward the hand.
local function rime(index: number, angle: number)
	return {
		name = "Rime" .. index,
		class = "WedgePart",
		size = Vector3.new(0.03, 0.05, 0.14),
		offset = CFrame.new(0, 0, -1.78)
			* CFrame.Angles(0, 0, R(angle))
			* CFrame.new(0, 0.095, 0)
			* CFrame.Angles(0, math.pi, 0),
		color = rimeIce,
		material = M.Ice,
		transparency = 0.15,
	}
end

-- Claw prong frame: rises from the lip rim at a hex vertex and leans 5 degrees in onto the corner.
local function prongFrame(angle: number): CFrame
	return CFrame.new(0, 0, -2.035)
		* CFrame.Angles(0, 0, R(angle))
		* CFrame.new(0.168, 0, 0)
		* CFrame.Angles(0, R(5), 0)
end

local function prong(index: number, angle: number)
	return {
		name = "Prong" .. index,
		size = Vector3.new(0.04, 0.04, 0.18),
		offset = prongFrame(angle),
		color = silver,
		material = M.Metal,
		reflectance = 0.1,
	}
end

local function prongTip(index: number, angle: number)
	return {
		name = "ProngTip" .. index,
		shape = BALL,
		size = Vector3.new(0.05, 0.05, 0.05),
		offset = prongFrame(angle) * CFrame.new(0, 0, -0.09),
		color = silver,
		material = M.Metal,
		reflectance = 0.1,
	}
end

local function crystalBody(index: number, angle: number)
	return {
		name = "CrystalBody" .. index,
		size = Vector3.new(HEX_SIDE, HEX_APOTHEM * 2, 0.30),
		offset = CFrame.new(0, 0, -2.09) * CFrame.Angles(0, 0, R(angle)),
		color = quartzGlass,
		material = M.Glass,
		transparency = 0.4,
		reflectance = 0.1,
	}
end

-- Half of one termination facet: a thin right-triangle glass plate with corners at the flat's
-- midpoint, one hex vertex (side = 1 or -1), and the tip. Two halves make the triangular face;
-- six faces make the hexagonal pyramid. The plate's outer face lies on the facet plane.
local function facetHalf(name: string, flatAngle: number, side: number)
	local phi = R(flatAngle)
	local radial = Vector3.new(math.cos(phi), math.sin(phi), 0)
	local yAxis = Vector3.new(-math.sin(phi), math.cos(phi), 0) * side
	local mid = radial * HEX_APOTHEM + Vector3.new(0, 0, FACET_BASE_Z)
	local toTip = Vector3.new(0, 0, TIP_Z) - mid
	local zAxis = -toTip.Unit
	local xAxis = yAxis:Cross(zAxis)
	local inward = -(radial * (FACET_BASE_Z - TIP_Z) - Vector3.new(0, 0, HEX_APOTHEM)).Unit
	local center = mid + yAxis * (HEX_SIDE / 4) + toTip / 2 + inward * (FACET_THICKNESS / 2)
	return {
		name = name,
		class = "WedgePart",
		size = Vector3.new(FACET_THICKNESS, HEX_SIDE / 2, toTip.Magnitude),
		offset = CFrame.fromMatrix(center, xAxis, yAxis, zAxis),
		color = quartzGlass,
		material = M.Glass,
		transparency = 0.4,
		reflectance = 0.1,
	}
end

-- Frost shard at a free hex vertex between prongs: thick end on the lip, thinning along the crystal.
local function lipFrost(index: number, angle: number)
	return {
		name = "LipFrost" .. index,
		class = "WedgePart",
		size = Vector3.new(0.04, 0.04, 0.10),
		offset = CFrame.new(0, 0, -2.015)
			* CFrame.Angles(0, 0, R(angle - 90))
			* CFrame.new(0, 0.16, 0),
		color = rimeIce,
		material = M.Ice,
		transparency = 0.15,
	}
end

local function frostGlow(name: string, shape: Enum.PartType, size: Vector3, offset: CFrame)
	return {
		name = name,
		shape = shape,
		size = size,
		offset = offset,
		color = frostCore,
		material = M.Neon,
	}
end

return WeaponModel.define({
	handle = {
		size = Vector3.new(0.26, 0.26, 0.7),
		color = ebony,
		material = M.Wood,
		transparency = 1,
	},
	muzzle = CFrame.new(0, 0, -2.46),
	pieces = {
		-- Pommel: z +0.545 to +0.26
		{
			name = "PommelFinial",
			shape = BALL,
			size = Vector3.new(0.07, 0.07, 0.07),
			offset = CFrame.new(0, 0, 0.51),
			color = silver,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "PommelBall",
			shape = BALL,
			size = Vector3.new(0.2, 0.2, 0.2),
			offset = CFrame.new(0, 0, 0.40),
			color = silver,
			material = M.Metal,
			reflectance = 0.1,
		},
		silverRing("PommelCap", 0.08, 0.26, 0.30),

		-- Grip: turned ebony, +0.28 to -0.40, swell under the fist
		ebonyTurn("GripCore", 0.68, 0.22, -0.06),
		ebonyTurn("GripSwell", 0.34, 0.25, -0.03),
		ebonyTurn("GripBeadRear", 0.05, 0.27, 0.20),
		ebonyTurn("GripBeadFront", 0.05, 0.27, -0.30),
		silverRing("GripInlayRear", 0.02, 0.265, 0.10),
		silverRing("GripInlayFront", 0.02, 0.265, -0.16),

		-- Front ferrule: -0.38 to -0.50
		silverRing("FerruleLipRear", 0.025, 0.28, -0.39),
		silverRing("Ferrule", 0.12, 0.25, -0.44),
		silverRing("FerruleLipFront", 0.02, 0.27, -0.4895),

		-- Shaft: stepped holly taper, -0.49 to -1.86, silver inlay over each step
		hollyTurn("Shaft1", 0.52, 0.20, -0.75),
		hollyTurn("Shaft2", 0.46, 0.18, -1.225),
		hollyTurn("Shaft3", 0.42, 0.16, -1.65),
		silverRing("InlayRing1", 0.025, 0.215, -1.00),
		silverRing("InlayRing2", 0.025, 0.195, -1.45),
		{
			name = "Knot1",
			shape = BALL,
			size = Vector3.new(0.07, 0.07, 0.07),
			offset = CFrame.new(0.07, 0.018, -0.82),
			color = knotWood,
			material = M.Wood,
		},
		{
			name = "Knot2",
			shape = BALL,
			size = Vector3.new(0.06, 0.06, 0.06),
			offset = CFrame.new(-0.053, -0.04, -1.30),
			color = knotWood,
			material = M.Wood,
		},

		-- Rime creeping down the shaft from the setting
		rime(1, 45),
		rime(2, 135),
		rime(3, 225),
		rime(4, 315),

		-- Setting: cup -1.84 to -1.97, three claws at hex vertices 0/120/240
		silverRing("CupRearBead", 0.02, 0.235, -1.85),
		silverRing("SettingCup", 0.08, 0.22, -1.89),
		silverRing("SettingLip", 0.04, 0.34, -1.95),
		prong(1, 0),
		prong(2, 120),
		prong(3, 240),
		prongTip(1, 0),
		prongTip(2, 120),
		prongTip(3, 240),

		-- Quartz body: hexagonal prism, -1.94 to -2.24
		crystalBody(1, 0),
		crystalBody(2, 60),
		crystalBody(3, 120),

		-- Quartz termination: six triangular faces, -2.24 to the tip at -2.44
		facetHalf("Facet1A", 30, 1),
		facetHalf("Facet1B", 30, -1),
		facetHalf("Facet2A", 90, 1),
		facetHalf("Facet2B", 90, -1),
		facetHalf("Facet3A", 150, 1),
		facetHalf("Facet3B", 150, -1),
		facetHalf("Facet4A", 210, 1),
		facetHalf("Facet4B", 210, -1),
		facetHalf("Facet5A", 270, 1),
		facetHalf("Facet5B", 270, -1),
		facetHalf("Facet6A", 330, 1),
		facetHalf("Facet6B", 330, -1),

		-- Frost light inside the quartz (only emissive parts)
		frostGlow(
			"CoreBeam",
			CYL,
			Vector3.new(0.36, 0.05, 0.05),
			CFrame.new(0, 0, -2.18) * CYLINDER_Z
		),
		frostGlow("CoreHeart", BALL, Vector3.new(0.11, 0.11, 0.11), CFrame.new(0, 0, -2.12)),
		frostGlow("CoreSpark", BALL, Vector3.new(0.05, 0.05, 0.05), CFrame.new(0, 0, -2.38)),

		-- Internal fracture planes ("feathers")
		{
			name = "Inclusion1",
			size = Vector3.new(0.12, 0.01, 0.10),
			offset = CFrame.new(0.02, 0.03, -2.05) * CFrame.Angles(R(25), R(15), 0),
			color = inclusion,
			material = M.Glass,
			transparency = 0.6,
		},
		{
			name = "Inclusion2",
			size = Vector3.new(0.09, 0.01, 0.08),
			offset = CFrame.new(-0.03, -0.02, -2.20) * CFrame.Angles(R(-30), 0, R(40)),
			color = inclusion,
			material = M.Glass,
			transparency = 0.6,
		},

		-- Frost shards on the lip at the free vertices
		lipFrost(1, 60),
		lipFrost(2, 180),
		lipFrost(3, 300),
	},
})
