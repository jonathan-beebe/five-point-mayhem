-- Missile Swarm: M202A1 FLASH 66 mm multi-shot rocket launcher, five-tube quincunx clip.

local WeaponModel = require(script.Parent.Parent.systems.WeaponModel)

local rgb = Color3.fromRGB
local M = Enum.Material
local CYLINDER_Z = WeaponModel.CYLINDER_Z
local CYLINDER_Y = WeaponModel.CYLINDER_Y
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball

local ordnanceRed = rgb(176, 62, 44)
local frameOD = rgb(68, 72, 52)
local gunmetal = rgb(52, 54, 56)
local boltSteel = rgb(88, 90, 92)
local boreBlack = rgb(22, 22, 24)
local venturiBlack = rgb(30, 29, 28)
local warheadOlive = rgb(96, 98, 64)
local polymerBlack = rgb(35, 36, 38)
local rubberBlack = rgb(30, 30, 32)
local stippleBlack = rgb(40, 40, 42)
local lensTint = rgb(110, 150, 145)

-- Grip frame: raked 15 degrees, top toward -Z.
local G = CFrame.new(0, -0.22, 0.12) * CFrame.Angles(math.rad(-15), 0, 0)

local BOLT = Vector3.new(0.03, 0.08, 0.08)
local DISC = Vector3.new(0.02, 0.28, 0.28)
local LENS = Vector3.new(0.18, 0.16, 0.02)

-- Painted fiberglass launch tube, Z +1.0 to -2.9.
local function tube(suffix: string, x: number, y: number)
	return {
		name = "Tube_" .. suffix,
		shape = CYL,
		size = Vector3.new(3.9, 0.34, 0.34),
		offset = CFrame.new(x, y, -0.95) * CYLINDER_Z,
		color = ordnanceRed,
		material = M.Plastic,
	}
end

-- Steel reinforcing ring around the tube mouth.
local function muzzleRing(suffix: string, x: number, y: number)
	return {
		name = "MuzzleRing_" .. suffix,
		shape = CYL,
		size = Vector3.new(0.08, 0.37, 0.37),
		offset = CFrame.new(x, y, -2.9) * CYLINDER_Z,
		color = gunmetal,
		material = M.Metal,
	}
end

-- Black bore disc, 0.015 proud of the ring face.
local function bore(suffix: string, x: number, y: number)
	return {
		name = "Bore_" .. suffix,
		shape = CYL,
		size = DISC,
		offset = CFrame.new(x, y, -2.945) * CYLINDER_Z,
		color = boreBlack,
		material = M.SmoothPlastic,
	}
end

-- Warhead nose showing in the bore.
local function warhead(suffix: string, x: number, y: number)
	return {
		name = "Warhead_" .. suffix,
		shape = BALL,
		size = Vector3.new(0.14, 0.14, 0.14),
		offset = CFrame.new(x, y, -2.95),
		color = warheadOlive,
		material = M.Metal,
	}
end

-- Rear venturi disc, sunk 0.005 into the tube's rear face so it stays attached.
local function venturi(suffix: string, x: number, y: number)
	return {
		name = "Venturi_" .. suffix,
		shape = CYL,
		size = DISC,
		offset = CFrame.new(x, y, 1.005) * CYLINDER_Z,
		color = venturiBlack,
		material = M.Metal,
	}
end

-- Bulkhead bolt head; z is the bolt center, 0.005 into the bulkhead face.
local function bolt(name: string, x: number, y: number, z: number)
	return {
		name = name,
		shape = CYL,
		size = BOLT,
		offset = CFrame.new(x, y, z) * CYLINDER_Z,
		color = boltSteel,
		material = M.Metal,
	}
end

return WeaponModel.define({
	handle = { transparency = 1 },
	muzzle = CFrame.new(0, 0.78, -3.0),
	pieces = {
		-- Tube pack (center + four corners)
		tube("C", 0, 0.78),
		tube("UL", -0.27, 1.05),
		tube("UR", 0.27, 1.05),
		tube("LL", -0.27, 0.51),
		tube("LR", 0.27, 0.51),
		muzzleRing("C", 0, 0.78),
		muzzleRing("UL", -0.27, 1.05),
		muzzleRing("UR", 0.27, 1.05),
		muzzleRing("LL", -0.27, 0.51),
		muzzleRing("LR", 0.27, 0.51),
		bore("C", 0, 0.78),
		bore("UL", -0.27, 1.05),
		bore("UR", 0.27, 1.05),
		bore("LL", -0.27, 0.51),
		bore("LR", 0.27, 0.51),
		warhead("C", 0, 0.78),
		warhead("UL", -0.27, 1.05),
		warhead("UR", 0.27, 1.05),
		warhead("LL", -0.27, 0.51),
		warhead("LR", 0.27, 0.51),
		venturi("C", 0, 0.78),
		venturi("UL", -0.27, 1.05),
		venturi("UR", 0.27, 1.05),
		venturi("LL", -0.27, 0.51),
		venturi("LR", 0.27, 0.51),

		-- Frame
		{
			name = "FrontBulkhead",
			size = Vector3.new(0.96, 0.96, 0.14),
			offset = CFrame.new(0, 0.78, -2.55),
			color = frameOD,
			material = M.Metal,
		},
		{
			name = "MidBand",
			size = Vector3.new(0.96, 0.96, 0.1),
			offset = CFrame.new(0, 0.78, -1.2),
			color = frameOD,
			material = M.Metal,
		},
		{
			name = "RearBulkhead",
			size = Vector3.new(0.96, 0.96, 0.14),
			offset = CFrame.new(0, 0.78, 0.6),
			color = frameOD,
			material = M.Metal,
		},
		{
			name = "RailL",
			size = Vector3.new(0.05, 0.14, 3.3),
			offset = CFrame.new(-0.505, 0.78, -0.975),
			color = gunmetal,
			material = M.Metal,
		},
		{
			name = "RailR",
			size = Vector3.new(0.05, 0.14, 3.3),
			offset = CFrame.new(0.505, 0.78, -0.975),
			color = gunmetal,
			material = M.Metal,
		},
		{
			name = "TopRail",
			size = Vector3.new(0.2, 0.06, 3.3),
			offset = CFrame.new(0, 1.29, -0.975),
			color = gunmetal,
			material = M.Metal,
		},
		{
			name = "BottomSpine",
			size = Vector3.new(0.3, 0.06, 3.3),
			offset = CFrame.new(0, 0.27, -0.975),
			color = gunmetal,
			material = M.Metal,
		},

		-- Bulkhead bolts
		bolt("BoltF_L", -0.42, 0.78, -2.63),
		bolt("BoltF_R", 0.42, 0.78, -2.63),
		bolt("BoltF_T", 0, 1.21, -2.63),
		bolt("BoltF_B", 0, 0.35, -2.63),
		bolt("BoltR_L", -0.42, 0.78, 0.68),
		bolt("BoltR_R", 0.42, 0.78, 0.68),
		bolt("BoltR_T", 0, 1.21, 0.68),
		bolt("BoltR_B", 0, 0.35, 0.68),

		-- Pistol grip
		{
			name = "GripCore",
			size = Vector3.new(0.28, 0.85, 0.42),
			offset = G,
			color = rubberBlack,
			material = M.Rubber,
		},
		{
			name = "GripPanelL",
			size = Vector3.new(0.02, 0.6, 0.34),
			offset = G * CFrame.new(-0.145, -0.07, 0),
			color = stippleBlack,
			material = M.Fabric,
		},
		{
			name = "GripPanelR",
			size = Vector3.new(0.02, 0.6, 0.34),
			offset = G * CFrame.new(0.145, -0.07, 0),
			color = stippleBlack,
			material = M.Fabric,
		},
		{
			name = "GripCap",
			size = Vector3.new(0.3, 0.06, 0.44),
			offset = G * CFrame.new(0, -0.44, 0),
			color = gunmetal,
			material = M.Metal,
		},

		-- Trigger group
		{
			name = "TriggerHousing",
			size = Vector3.new(0.26, 0.22, 0.85),
			offset = CFrame.new(0, 0.13, -0.15),
			color = polymerBlack,
			material = M.Plastic,
		},
		{
			name = "GuardBottom",
			size = Vector3.new(0.08, 0.04, 0.5),
			offset = CFrame.new(0, -0.27, -0.31),
			color = polymerBlack,
			material = M.Plastic,
		},
		{
			name = "GuardFront",
			size = Vector3.new(0.08, 0.31, 0.04),
			offset = CFrame.new(0, -0.125, -0.54),
			color = polymerBlack,
			material = M.Plastic,
		},
		{
			name = "Trigger",
			size = Vector3.new(0.06, 0.22, 0.07),
			offset = CFrame.new(0, -0.08, -0.25) * CFrame.Angles(math.rad(-12), 0, 0),
			color = gunmetal,
			material = M.Metal,
		},
		{
			name = "ArmingLever",
			size = Vector3.new(0.04, 0.06, 0.4),
			offset = CFrame.new(0.145, 0.13, -0.3),
			color = gunmetal,
			material = M.Metal,
		},
		{
			name = "ArmingKnob",
			shape = BALL,
			size = Vector3.new(0.1, 0.1, 0.1),
			offset = CFrame.new(0.17, 0.13, -0.52),
			color = rubberBlack,
			material = M.Rubber,
		},
		{
			name = "Selector",
			shape = CYL,
			size = Vector3.new(0.04, 0.12, 0.12),
			offset = CFrame.new(-0.145, 0.13, -0.05),
			color = polymerBlack,
			material = M.Plastic,
		},

		-- Folding foregrip
		{
			name = "ForegripHinge",
			size = Vector3.new(0.2, 0.08, 0.2),
			offset = CFrame.new(0, 0.2, -1.85),
			color = gunmetal,
			material = M.Metal,
		},
		{
			name = "ForegripPost",
			shape = CYL,
			size = Vector3.new(0.55, 0.2, 0.2),
			offset = CFrame.new(0, -0.11, -1.85) * CYLINDER_Y,
			color = rubberBlack,
			material = M.Rubber,
		},
		{
			name = "ForegripCap",
			shape = CYL,
			size = Vector3.new(0.05, 0.22, 0.22),
			offset = CFrame.new(0, -0.405, -1.85) * CYLINDER_Y,
			color = polymerBlack,
			material = M.Plastic,
		},

		-- Reflex sight
		{
			name = "SightMount",
			size = Vector3.new(0.16, 0.1, 0.3),
			offset = CFrame.new(0, 1.37, 0.1),
			color = gunmetal,
			material = M.Metal,
		},
		{
			name = "SightHousing",
			size = Vector3.new(0.24, 0.24, 0.5),
			offset = CFrame.new(0, 1.54, 0.1),
			color = frameOD,
			material = M.Metal,
		},
		{
			name = "SightLensFront",
			size = LENS,
			offset = CFrame.new(0, 1.55, -0.157),
			color = lensTint,
			material = M.Glass,
			transparency = 0.35,
			reflectance = 0.25,
		},
		{
			name = "SightLensRear",
			size = LENS,
			offset = CFrame.new(0, 1.55, 0.357),
			color = lensTint,
			material = M.Glass,
			transparency = 0.35,
			reflectance = 0.25,
		},
		{
			name = "SightHood",
			size = Vector3.new(0.26, 0.03, 0.12),
			offset = CFrame.new(0, 1.67, -0.2),
			color = frameOD,
			material = M.Metal,
		},
		{
			name = "SightKnob",
			shape = CYL,
			size = Vector3.new(0.04, 0.1, 0.1),
			offset = CFrame.new(0.135, 1.54, 0.1),
			color = gunmetal,
			material = M.Metal,
		},
	},
})
