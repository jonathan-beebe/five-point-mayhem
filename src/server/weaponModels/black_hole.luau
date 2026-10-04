-- Black Hole Orb: Victorian brass-mounted scrying globe on a turned-walnut scepter, holding an EHT-style black hole.

local WeaponModel = require(script.Parent.Parent.systems.WeaponModel)

local rgb = Color3.fromRGB
local M = Enum.Material
local CYLINDER_Z = WeaponModel.CYLINDER_Z
local CYLINDER_Y = WeaponModel.CYLINDER_Y
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball
local R = math.rad

-- Globe centre, accretion disk plane (local Y = disk normal), cup axis.
local S = CFrame.new(0, 0.6, -1.0)
local DISK = S * CFrame.Angles(R(14), 0, R(-10))
local CUP = CFrame.new(0, 0, -1.0)

local walnut = rgb(86, 55, 36)
local leather = rgb(48, 30, 28)
local cord = rgb(28, 20, 18)
local agedBrass = rgb(176, 141, 74)
local darkBronze = rgb(92, 70, 42)
local amethyst = rgb(70, 20, 100)
local globeGlass = rgb(205, 195, 220)
local smokeTint = rgb(34, 10, 52)
local horizon = rgb(4, 3, 6)
local diskHot = rgb(235, 190, 255)
local diskViolet = rgb(150, 40, 220)
local diskDeep = rgb(80, 0, 120)
local photonRing = rgb(245, 215, 255)
local moteGlow = rgb(190, 120, 255)
local lensing = rgb(110, 40, 180)

-- A point on the globe: yaw psi around the cup axis, latitude phi, radius d.
-- Local Y follows the meridian, local Z is radial.
local function prong(psi: number, phi: number, d: number): CFrame
	return S * CFrame.Angles(0, R(psi), 0) * CFrame.Angles(R(phi), 0, 0) * CFrame.new(0, 0, -d)
end

local function brass(name: string, size: Vector3, offset: CFrame, shape: Enum.PartType?)
	return {
		name = name,
		shape = shape,
		size = size,
		offset = offset,
		color = agedBrass,
		material = M.Metal,
		reflectance = 0.1,
	}
end

local function bronze(name: string, size: Vector3, offset: CFrame, shape: Enum.PartType?)
	return {
		name = name,
		shape = shape,
		size = size,
		offset = offset,
		color = darkBronze,
		material = M.Metal,
	}
end

local function cordRing(name: string, z: number)
	return {
		name = name,
		shape = CYL,
		size = Vector3.new(0.03, 0.355, 0.355),
		offset = CFrame.new(0, 0, z) * CYLINDER_Z,
		color = cord,
		material = M.Fabric,
	}
end

local function rivet(psi: number)
	return bronze(
		"CupRivet" .. psi,
		Vector3.new(0.06, 0.06, 0.06),
		CUP * CFrame.new(0, -0.18, 0) * CFrame.Angles(0, R(psi), 0) * CFrame.new(0, 0, -0.385),
		BALL
	)
end

local function prongRoot(psi: number)
	return brass("Prong" .. psi .. "Root", Vector3.new(0.09, 0.44, 0.06), prong(psi, -46, 0.72))
end

local function prongMid(psi: number)
	return brass("Prong" .. psi .. "Mid", Vector3.new(0.08, 0.44, 0.06), prong(psi, -14, 0.72))
end

local function prongClaw(psi: number)
	return brass("Prong" .. psi .. "Claw", Vector3.new(0.07, 0.28, 0.055), prong(psi, 12, 0.73))
end

local function prongTip(psi: number)
	return bronze(
		"Prong" .. psi .. "Tip",
		Vector3.new(0.11, 0.11, 0.11),
		prong(psi, 23, 0.735),
		BALL
	)
end

local function diskRing(
	name: string,
	thickness: number,
	diameter: number,
	color: Color3,
	transparency: number
)
	return {
		name = name,
		shape = CYL,
		size = Vector3.new(thickness, diameter, diameter),
		offset = DISK * CYLINDER_Y,
		color = color,
		material = M.Neon,
		transparency = transparency,
	}
end

local function mote(name: string, x: number, y: number, z: number)
	return {
		name = name,
		shape = BALL,
		size = Vector3.new(0.05, 0.05, 0.05),
		offset = DISK * CFrame.new(x, y, z),
		color = moteGlow,
		material = M.Neon,
	}
end

return WeaponModel.define({
	handle = {
		size = Vector3.new(0.3, 0.3, 0.9),
		color = walnut,
		material = M.Wood,
		transparency = 1,
	},
	muzzle = CFrame.new(0, 0.6, -1.75),
	pieces = {
		-- Grip: walnut core z -0.37 to +0.47, leather sleeve, cord rings, brass pommel and ferrule
		{
			name = "GripCore",
			shape = CYL,
			size = Vector3.new(0.84, 0.32, 0.32),
			offset = CFrame.new(0, 0, 0.05) * CYLINDER_Z,
			color = walnut,
			material = M.Wood,
		},
		{
			name = "GripSleeve",
			shape = CYL,
			size = Vector3.new(0.5, 0.335, 0.335),
			offset = CFrame.new(0, 0, 0.05) * CYLINDER_Z,
			color = leather,
			material = M.Leather,
		},
		cordRing("GripCordFront", -0.15),
		cordRing("GripCordMid", 0.05),
		cordRing("GripCordRear", 0.25),
		brass(
			"PommelCollar",
			Vector3.new(0.06, 0.38, 0.38),
			CFrame.new(0, 0, 0.5) * CYLINDER_Z,
			CYL
		),
		brass("Pommel", Vector3.new(0.36, 0.36, 0.36), CFrame.new(0, 0, 0.6), BALL),
		{
			name = "PommelJewel",
			shape = BALL,
			size = Vector3.new(0.12, 0.12, 0.12),
			offset = CFrame.new(0, 0, 0.77),
			color = amethyst,
			material = M.Glass,
			transparency = 0.2,
		},
		brass(
			"FrontFerrule",
			Vector3.new(0.1, 0.38, 0.38),
			CFrame.new(0, 0, -0.37) * CYLINDER_Z,
			CYL
		),
		bronze(
			"FerruleRing",
			Vector3.new(0.03, 0.4, 0.4),
			CFrame.new(0, 0, -0.305) * CYLINDER_Z,
			CYL
		),
		-- Neck: z -0.38 to -0.66, front end 0.02 inside the cup bowl
		brass("Neck", Vector3.new(0.28, 0.2, 0.2), CFrame.new(0, -0.12, -0.52) * CYLINDER_Z, CYL),
		bronze(
			"NeckCollar",
			Vector3.new(0.04, 0.24, 0.24),
			CFrame.new(0, -0.12, -0.6) * CYLINDER_Z,
			CYL
		),

		-- Cup / cradle: lip y -0.11 to -0.06 seats the globe bottom (y -0.10)
		brass(
			"CupLip",
			Vector3.new(0.05, 0.84, 0.84),
			CUP * CFrame.new(0, -0.085, 0) * CYLINDER_Y,
			CYL
		),
		brass(
			"CupBowl",
			Vector3.new(0.14, 0.72, 0.72),
			CUP * CFrame.new(0, -0.18, 0) * CYLINDER_Y,
			CYL
		),
		bronze(
			"CupBand",
			Vector3.new(0.03, 0.76, 0.76),
			CUP * CFrame.new(0, -0.18, 0) * CYLINDER_Y,
			CYL
		),
		brass(
			"CupStem",
			Vector3.new(0.12, 0.34, 0.34),
			CUP * CFrame.new(0, -0.31, 0) * CYLINDER_Y,
			CYL
		),
		brass("CupFinial", Vector3.new(0.26, 0.26, 0.26), CUP * CFrame.new(0, -0.42, 0), BALL),
		bronze("CupFinialDrop", Vector3.new(0.12, 0.12, 0.12), CUP * CFrame.new(0, -0.58, 0), BALL),
		rivet(45),
		rivet(135),
		rivet(225),
		rivet(315),

		-- Claw prongs: four segmented brass claws riding the globe, clear of the neck at psi 180
		prongRoot(45),
		prongRoot(135),
		prongRoot(225),
		prongRoot(315),
		prongMid(45),
		prongMid(135),
		prongMid(225),
		prongMid(315),
		prongClaw(45),
		prongClaw(135),
		prongClaw(225),
		prongClaw(315),
		prongTip(45),
		prongTip(135),
		prongTip(225),
		prongTip(315),

		-- Globe: clear glass shell over a smoky inner shell (0.02 wall)
		{
			name = "GlobeGlass",
			shape = BALL,
			size = Vector3.new(1.4, 1.4, 1.4),
			offset = S,
			color = globeGlass,
			material = M.Glass,
			transparency = 0.65,
			reflectance = 0.15,
		},
		{
			name = "GlobeSmoke",
			shape = BALL,
			size = Vector3.new(1.36, 1.36, 1.36),
			offset = S,
			color = smokeTint,
			material = M.Glass,
			transparency = 0.85,
		},

		-- Black hole core: tilted accretion disk, lensing shimmer, photon rings, event horizon, dust motes
		diskRing("DiskOuter", 0.01, 1.18, diskDeep, 0.55),
		diskRing("DiskMid", 0.03, 0.98, diskViolet, 0.35),
		diskRing("DiskInner", 0.05, 0.78, diskHot, 0.1),
		{
			name = "LensingShell",
			shape = BALL,
			size = Vector3.new(0.6, 0.6, 0.6),
			offset = S,
			color = lensing,
			material = M.ForceField,
			transparency = 0,
		},
		{
			name = "PhotonRingZ",
			shape = CYL,
			size = Vector3.new(0.02, 0.52, 0.52),
			offset = S * CYLINDER_Z,
			color = photonRing,
			material = M.Neon,
			transparency = 0.15,
		},
		{
			name = "PhotonRingX",
			shape = CYL,
			size = Vector3.new(0.02, 0.52, 0.52),
			offset = S,
			color = photonRing,
			material = M.Neon,
			transparency = 0.15,
		},
		{
			name = "EventHorizon",
			shape = BALL,
			size = Vector3.new(0.46, 0.46, 0.46),
			offset = S,
			color = horizon,
			material = M.SmoothPlastic,
			reflectance = 0,
		},
		mote("Mote1", 0.592, 0.02, 0.215),
		mote("Mote2", -0.315, -0.02, 0.546),
		mote("Mote3", -0.277, 0.02, -0.567),
	},
})
