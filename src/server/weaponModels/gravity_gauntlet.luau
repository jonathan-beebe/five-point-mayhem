-- Gravity Gauntlet: blackened Gothic plate gauntlet driving a brass-caged borosilicate globe emitter, vacuum-tube capacitor bank and pressure gauge.

local WeaponModel = require(script.Parent.Parent.systems.WeaponModel)

local rgb = Color3.fromRGB
local M = Enum.Material
local CYLINDER_Z = WeaponModel.CYLINDER_Z
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball
local R = math.rad

local blackenedSteel = rgb(46, 48, 54)
local shellSteel = rgb(58, 60, 66)
local steelEdge = rgb(150, 154, 160)
local brass = rgb(181, 140, 72)
local agedBrass = rgb(122, 94, 52)
local leather = rgb(92, 62, 40)
local leatherDark = rgb(44, 31, 22)
local porcelain = rgb(226, 220, 204)
local cableCloth = rgb(88, 38, 30)
local glass = rgb(205, 195, 235)
local gaugeGlass = rgb(220, 225, 230)
local coreViolet = rgb(120, 60, 200)
local haze = rgb(150, 90, 230)
local needleRed = rgb(170, 30, 25)

-- Globe axis: (0, GY, z), globe center at z GZ.
local GY = 0.1
local GZ = -1.28

local function lame(index: number, y: number, z: number)
	return {
		name = "Lame" .. index,
		size = Vector3.new(1.3, 0.1, 0.32),
		offset = CFrame.new(0, y, z),
		color = blackenedSteel,
		material = M.Metal,
	}
end

-- Polished roll along the lame's front edge, 0.01 proud of the lame on every side.
local function lameTrim(index: number, y: number, z: number)
	return {
		name = "LameTrim" .. index,
		size = Vector3.new(1.32, 0.12, 0.04),
		offset = CFrame.new(0, y, z),
		color = steelEdge,
		material = M.Metal,
		reflectance = 0.1,
	}
end

local function ball(name: string, diameter: number, position: CFrame, color: Color3)
	return {
		name = name,
		shape = BALL,
		size = Vector3.one * diameter,
		offset = position,
		color = color,
		material = M.Metal,
		reflectance = if color == brass then 0.1 else nil,
	}
end

local function tubeCap(name: string, x: number, z: number)
	return {
		name = name,
		shape = CYL,
		size = Vector3.new(0.1, 0.28, 0.28),
		offset = CFrame.new(x, 0.97, z) * CYLINDER_Z,
		color = brass,
		material = M.Metal,
		reflectance = 0.1,
	}
end

local function strut(index: number, degrees: number)
	local theta = R(degrees)
	return {
		name = "CageStrut" .. index,
		size = Vector3.new(0.07, 0.07, 1.04),
		offset = CFrame.new(0.53 * math.cos(theta), GY + 0.53 * math.sin(theta), -1.29)
			* CFrame.Angles(0, 0, theta),
		color = brass,
		material = M.Metal,
		reflectance = 0.1,
	}
end

-- Front guard spokes. Depths differ by 0.02 so the faces stacked at the crossing never share a plane.
local function spoke(name: string, depth: number, roll: number)
	return {
		name = name,
		size = Vector3.new(1.13, 0.06, depth),
		offset = CFrame.new(0, GY, -1.8) * CFrame.Angles(0, 0, R(roll)),
		color = brass,
		material = M.Metal,
		reflectance = 0.1,
	}
end

-- Cable run centered at `mid`, pointing at `toward`.
local function cable(name: string, length: number, mid: Vector3, toward: Vector3)
	return {
		name = name,
		shape = CYL,
		size = Vector3.new(length, 0.1, 0.1),
		offset = CFrame.lookAt(mid, toward) * CYLINDER_Z,
		color = cableCloth,
		material = M.Fabric,
	}
end

return WeaponModel.define({
	handle = {
		size = Vector3.new(0.4, 0.4, 1.2),
		color = blackenedSteel,
		material = M.Metal,
		transparency = 1,
	},
	muzzle = CFrame.new(0, GY, -1.9),
	pieces = {
		-- Cuff / vambrace (forearm runs along +Z)
		{
			name = "CuffShell",
			shape = CYL,
			size = Vector3.new(1.1, 1.5, 1.5),
			offset = CFrame.new(0, 0, 1.2) * CYLINDER_Z,
			color = blackenedSteel,
			material = M.Metal,
		},
		{
			name = "CuffRimFront",
			shape = CYL,
			size = Vector3.new(0.08, 1.62, 1.62),
			offset = CFrame.new(0, 0, 0.71) * CYLINDER_Z,
			color = steelEdge,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "CuffRimRear",
			shape = CYL,
			size = Vector3.new(0.08, 1.62, 1.62),
			offset = CFrame.new(0, 0, 1.71) * CYLINDER_Z,
			color = steelEdge,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "CuffLiner",
			shape = CYL,
			size = Vector3.new(0.06, 1.36, 1.36),
			offset = CFrame.new(0, 0, 1.77) * CYLINDER_Z,
			color = leatherDark,
			material = M.Leather,
		},
		{
			name = "StrapFront",
			shape = CYL,
			size = Vector3.new(0.14, 1.56, 1.56),
			offset = CFrame.new(0, 0, 0.95) * CYLINDER_Z,
			color = leather,
			material = M.Leather,
		},
		{
			name = "StrapRear",
			shape = CYL,
			size = Vector3.new(0.14, 1.56, 1.56),
			offset = CFrame.new(0, 0, 1.45) * CYLINDER_Z,
			color = leather,
			material = M.Leather,
		},
		{
			name = "BuckleFront",
			size = Vector3.new(0.12, 0.22, 0.24),
			offset = CFrame.new(-0.79, 0, 0.95),
			color = brass,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "BuckleRear",
			size = Vector3.new(0.12, 0.22, 0.24),
			offset = CFrame.new(-0.79, 0, 1.45),
			color = brass,
			material = M.Metal,
			reflectance = 0.1,
		},

		-- Pressure gauge on the outer cuff (+X). The lens reaches back into the bezel and encloses
		-- the dial and needle so nothing floats.
		{
			name = "GaugeBezel",
			shape = CYL,
			size = Vector3.new(0.1, 0.34, 0.34),
			offset = CFrame.new(0.79, 0, 1.2),
			color = brass,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "GaugeFace",
			shape = CYL,
			size = Vector3.new(0.02, 0.28, 0.28),
			offset = CFrame.new(0.849, 0, 1.2),
			color = porcelain,
			material = M.SmoothPlastic,
			reflectance = 0.05,
		},
		{
			name = "GaugeNeedle",
			size = Vector3.new(0.02, 0.12, 0.025),
			offset = CFrame.new(0.866, 0, 1.2)
				* CFrame.Angles(R(40), 0, 0)
				* CFrame.new(0, 0.05, 0),
			color = needleRed,
			material = M.SmoothPlastic,
		},
		{
			name = "GaugeGlass",
			shape = CYL,
			size = Vector3.new(0.07, 0.3, 0.3),
			offset = CFrame.new(0.87, 0, 1.2),
			color = gaugeGlass,
			material = M.Glass,
			transparency = 0.6,
			reflectance = 0.15,
		},

		-- Capacitor bank on top of the cuff
		{
			name = "CapSaddle",
			size = Vector3.new(0.76, 0.12, 1),
			offset = CFrame.new(0, 0.78, 1.2),
			color = agedBrass,
			material = M.Metal,
		},
		{
			name = "TubeL",
			shape = CYL,
			size = Vector3.new(0.8, 0.26, 0.26),
			offset = CFrame.new(-0.22, 0.97, 1.2) * CYLINDER_Z,
			color = glass,
			material = M.Glass,
			transparency = 0.5,
			reflectance = 0.2,
		},
		{
			name = "TubeR",
			shape = CYL,
			size = Vector3.new(0.8, 0.26, 0.26),
			offset = CFrame.new(0.22, 0.97, 1.2) * CYLINDER_Z,
			color = glass,
			material = M.Glass,
			transparency = 0.5,
			reflectance = 0.2,
		},
		{
			name = "FilamentL",
			shape = CYL,
			size = Vector3.new(0.6, 0.08, 0.08),
			offset = CFrame.new(-0.22, 0.97, 1.2) * CYLINDER_Z,
			color = coreViolet,
			material = M.Neon,
		},
		{
			name = "FilamentR",
			shape = CYL,
			size = Vector3.new(0.6, 0.08, 0.08),
			offset = CFrame.new(0.22, 0.97, 1.2) * CYLINDER_Z,
			color = coreViolet,
			material = M.Neon,
		},
		tubeCap("TubeCapFrontL", -0.22, 0.78),
		tubeCap("TubeCapFrontR", 0.22, 0.78),
		tubeCap("TubeCapRearL", -0.22, 1.62),
		tubeCap("TubeCapRearR", 0.22, 1.62),
		{
			name = "TubeClamp",
			size = Vector3.new(0.74, 0.06, 0.08),
			offset = CFrame.new(0, 1.12, 1.2),
			color = brass,
			material = M.Metal,
			reflectance = 0.1,
		},

		-- Hand armor: shell, overlapping metacarpal lames stepping down toward the knuckles
		{
			name = "HandShell",
			size = Vector3.new(1.36, 1.2, 1),
			offset = CFrame.new(0, 0, 0.15),
			color = shellSteel,
			material = M.Metal,
		},
		lame(1, 0.66, 0.5),
		lame(2, 0.645, 0.25),
		lame(3, 0.63, 0),
		lame(4, 0.615, -0.25),
		lameTrim(1, 0.66, 0.33),
		lameTrim(2, 0.645, 0.08),
		lameTrim(3, 0.63, -0.17),
		lameTrim(4, 0.615, -0.42),
		{
			name = "KnuckleRidge",
			shape = CYL,
			size = Vector3.new(1.36, 0.3, 0.3),
			offset = CFrame.new(0, 0.45, -0.38),
			color = blackenedSteel,
			material = M.Metal,
		},
		-- Studs sit on the ridge crown just ahead of LameTrim4 (front face z -0.44).
		ball("KnuckleStud1", 0.14, CFrame.new(-0.45, 0.6, -0.48), brass),
		ball("KnuckleStud2", 0.14, CFrame.new(-0.15, 0.6, -0.48), brass),
		ball("KnuckleStud3", 0.14, CFrame.new(0.15, 0.6, -0.48), brass),
		ball("KnuckleStud4", 0.14, CFrame.new(0.45, 0.6, -0.48), brass),
		{
			name = "PalmLeather",
			size = Vector3.new(1.2, 0.08, 0.9),
			offset = CFrame.new(0, -0.62, 0.15),
			color = leatherDark,
			material = M.Leather,
		},
		{
			name = "ThumbPlate",
			size = Vector3.new(0.1, 0.5, 0.6),
			offset = CFrame.new(-0.72, 0.1, 0),
			color = blackenedSteel,
			material = M.Metal,
		},
		ball("RivetRU", 0.1, CFrame.new(0.69, 0.35, 0.45), brass),
		ball("RivetRD", 0.1, CFrame.new(0.69, -0.35, 0.45), brass),
		ball("RivetLU", 0.1, CFrame.new(-0.69, 0.35, 0.45), brass),
		ball("RivetLD", 0.1, CFrame.new(-0.69, -0.35, 0.45), brass),

		-- Emitter mount
		{
			name = "EmitterCollar",
			shape = CYL,
			size = Vector3.new(0.25, 1, 1),
			offset = CFrame.new(0, GY, -0.5) * CYLINDER_Z,
			color = agedBrass,
			material = M.Metal,
		},
		{
			name = "InsulatorRing",
			shape = CYL,
			size = Vector3.new(0.12, 0.8, 0.8),
			offset = CFrame.new(0, GY, -0.68) * CYLINDER_Z,
			color = porcelain,
			material = M.SmoothPlastic,
			reflectance = 0.05,
		},
		{
			name = "CradleRing",
			shape = CYL,
			size = Vector3.new(0.08, 1.16, 1.16),
			offset = CFrame.new(0, GY, -0.77) * CYLINDER_Z,
			color = brass,
			material = M.Metal,
			reflectance = 0.1,
		},

		-- Containment globe
		{
			name = "GlobeGlass",
			shape = BALL,
			size = Vector3.one,
			offset = CFrame.new(0, GY, GZ),
			color = glass,
			material = M.Glass,
			transparency = 0.55,
			reflectance = 0.2,
		},
		{
			name = "GlobeHaze",
			shape = BALL,
			size = Vector3.one * 0.8,
			offset = CFrame.new(0, GY, GZ),
			color = haze,
			material = M.ForceField,
		},
		{
			name = "Core",
			shape = BALL,
			size = Vector3.one * 0.4,
			offset = CFrame.new(0, GY, GZ),
			color = coreViolet,
			material = M.Neon,
		},
		{
			name = "ElectrodeStem",
			shape = CYL,
			size = Vector3.new(0.3, 0.08, 0.08),
			offset = CFrame.new(0, GY, -0.94) * CYLINDER_Z,
			color = steelEdge,
			material = M.Metal,
			reflectance = 0.1,
		},

		-- Cage guard: eight bars from the cradle ring to the front spokes
		strut(1, 0),
		strut(2, 45),
		strut(3, 90),
		strut(4, 135),
		strut(5, 180),
		strut(6, 225),
		strut(7, 270),
		strut(8, 315),
		spoke("SpokeH", 0.06, 0),
		spoke("SpokeV", 0.08, 90),
		spoke("SpokeD1", 0.04, 45),
		spoke("SpokeD2", 0.1, -45),
		{
			name = "GuardHub",
			shape = CYL,
			size = Vector3.new(0.08, 0.22, 0.22),
			offset = CFrame.new(0, GY, -1.82) * CYLINDER_Z,
			color = agedBrass,
			material = M.Metal,
		},

		-- Power cables: front tube caps, over the lames, down into the collar
		cable("CableUpperL", 1.1, Vector3.new(-0.3, 0.89, 0.24), Vector3.new(-0.3, 0.81, -0.3)),
		cable("CableUpperR", 1.1, Vector3.new(0.3, 0.89, 0.24), Vector3.new(0.3, 0.81, -0.3)),
		ball("CableFerruleL", 0.13, CFrame.new(-0.3, 0.81, -0.3), brass),
		ball("CableFerruleR", 0.13, CFrame.new(0.3, 0.81, -0.3), brass),
		cable("CableLowerL", 0.42, Vector3.new(-0.3, 0.63, -0.4), Vector3.new(-0.3, 0.45, -0.5)),
		cable("CableLowerR", 0.42, Vector3.new(0.3, 0.63, -0.4), Vector3.new(0.3, 0.45, -0.5)),
		{
			name = "CableClip",
			size = Vector3.new(0.76, 0.2, 0.1),
			offset = CFrame.new(0, 0.79, 0.15),
			color = brass,
			material = M.Metal,
			reflectance = 0.1,
		},
	},
})
