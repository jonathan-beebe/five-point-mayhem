-- Assault Rifle: M4A1-pattern 5.56 carbine, 14.5" barrel, Ranger Green free-float M-LOK furniture, micro red dot.

local WeaponModel = require(script.Parent.Parent.systems.WeaponModel)

local rgb = Color3.fromRGB
local M = Enum.Material
local CYLINDER_Z = WeaponModel.CYLINDER_Z
local CYLINDER_Y = WeaponModel.CYLINDER_Y
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball
local R = math.rad

-- Wedge orientations (WedgePart default: right angle at local (ymin, zmax), slope faces -Z/+Y).
local FLIP_Z = CFrame.Angles(0, 0, math.pi) -- flat face on top, slope faces -Z/-Y
local SIDE_R = CFrame.Angles(0, R(-90), 0) -- runs along Z, slope faces +X/+Y
local SIDE_L = CFrame.Angles(0, R(90), 0) -- runs along Z, slope faces -X/+Y

-- Pistol grip frame: raked 20 degrees, bottom toward +Z.
local GRIP = CFrame.new(0, -0.1, 0.04) * CFrame.Angles(R(-20), 0, 0)
-- Lower magazine segment frame: curves forward.
local MAG2 = CFrame.new(0, -0.549, -0.823) * CFrame.Angles(R(22), 0, 0)

local anodBlack = rgb(40, 41, 43)
local rangerGreen = rgb(85, 95, 70)
local gripTexture = rgb(78, 88, 64)
local polyBlack = rgb(32, 32, 34)
local phosphate = rgb(62, 63, 64)
local parkerized = rgb(52, 53, 55)
local soot = rgb(22, 22, 24)
local slotShadow = rgb(18, 18, 20)
local pinSteel = rgb(120, 121, 124)
local nickel = rgb(168, 166, 158)
local buttRubber = rgb(28, 28, 30)
local lensGlass = rgb(70, 105, 100)
local redDot = rgb(255, 45, 35)

local function pin(name: string, diameter: number, y: number, z: number)
	return {
		name = name,
		shape = CYL,
		size = Vector3.new(0.24, diameter, diameter),
		offset = CFrame.new(0, y, z),
		color = pinSteel,
		material = M.Metal,
	}
end

local function mlokSlot(index: number, z: number)
	return {
		name = "MlokSlot" .. index,
		size = Vector3.new(0.3, 0.06, 0.24),
		offset = CFrame.new(0, 0.48, z),
		color = slotShadow,
		material = M.SmoothPlastic,
	}
end

local function tine(name: string, x: number, y: number)
	return {
		name = name,
		size = Vector3.new(0.035, 0.035, 0.21),
		offset = CFrame.new(x, y, -3.785) * CFrame.Angles(0, 0, R(45)),
		color = parkerized,
		material = M.Metal,
	}
end

local function lens(name: string, z: number)
	return {
		name = name,
		shape = CYL,
		size = Vector3.new(0.02, 0.18, 0.18),
		offset = CFrame.new(0, 0.89, z) * CYLINDER_Z,
		color = lensGlass,
		material = M.Glass,
		transparency = 0.3,
		reflectance = 0.3,
	}
end

return WeaponModel.define({
	handle = {
		size = Vector3.new(0.2, 0.5, 0.25),
		color = rangerGreen,
		material = M.Plastic,
		transparency = 1,
	},
	muzzle = CFrame.new(0, 0.48, -3.96),
	pieces = {
		-- Upper receiver: y 0.34 to 0.60, z +0.33 to -1.25, Picatinny rail on top to y 0.68
		{
			name = "UpperBody",
			size = Vector3.new(0.24, 0.26, 1.58),
			offset = CFrame.new(0, 0.47, -0.46),
			color = anodBlack,
			material = M.Metal,
		},
		{
			name = "UpperRailBase",
			size = Vector3.new(0.18, 0.04, 1.58),
			offset = CFrame.new(0, 0.62, -0.46),
			color = anodBlack,
			material = M.Metal,
		},
		{
			name = "UpperRailCrown",
			size = Vector3.new(0.14, 0.04, 1.58),
			offset = CFrame.new(0, 0.66, -0.46),
			color = anodBlack,
			material = M.Metal,
		},
		{
			name = "ChargingHandle",
			size = Vector3.new(0.3, 0.04, 0.08),
			offset = CFrame.new(0, 0.6, 0.36),
			color = anodBlack,
			material = M.Metal,
		},
		{
			name = "BoltCarrier",
			size = Vector3.new(0.02, 0.1, 0.36),
			offset = CFrame.new(0.126, 0.47, -0.2),
			color = nickel,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "DustCoverOpen",
			size = Vector3.new(0.025, 0.1, 0.4),
			offset = CFrame.new(0.1225, 0.29, -0.2),
			color = anodBlack,
			material = M.Metal,
		},
		{
			name = "BrassDeflector",
			size = Vector3.new(0.05, 0.1, 0.08),
			offset = CFrame.new(0.135, 0.5, 0.04),
			color = anodBlack,
			material = M.Metal,
		},
		{
			name = "ForwardAssist",
			shape = CYL,
			size = Vector3.new(0.18, 0.09, 0.09),
			offset = CFrame.new(0.15, 0.43, 0.2) * CYLINDER_Z,
			color = anodBlack,
			material = M.Metal,
		},
		{
			name = "ForwardAssistCap",
			shape = CYL,
			size = Vector3.new(0.03, 0.08, 0.08),
			offset = CFrame.new(0.15, 0.43, 0.305) * CYLINDER_Z,
			color = phosphate,
			material = M.Metal,
		},

		-- Lower receiver and trigger group: y 0.12 to 0.34, magwell below
		{
			name = "LowerBody",
			size = Vector3.new(0.22, 0.22, 1.42),
			offset = CFrame.new(0, 0.23, -0.36),
			color = anodBlack,
			material = M.Metal,
		},
		{
			name = "Magwell",
			size = Vector3.new(0.22, 0.24, 0.46),
			offset = CFrame.new(0, 0, -0.75),
			color = anodBlack,
			material = M.Metal,
		},
		{
			name = "MagwellLip",
			size = Vector3.new(0.24, 0.04, 0.48),
			offset = CFrame.new(0, -0.12, -0.75),
			color = anodBlack,
			material = M.Metal,
		},
		{
			name = "LowerFrontBevel",
			class = "WedgePart",
			size = Vector3.new(0.22, 0.12, 0.09),
			offset = CFrame.new(0, 0.06, -1.025) * FLIP_Z,
			color = anodBlack,
			material = M.Metal,
		},
		{
			-- Runs from inside the grip front (z -0.10) to inside the magwell rear (z -0.53)
			name = "TriggerGuard",
			size = Vector3.new(0.07, 0.03, 0.43),
			offset = CFrame.new(0, -0.065, -0.315),
			color = anodBlack,
			material = M.Metal,
		},
		{
			name = "Trigger",
			size = Vector3.new(0.04, 0.18, 0.04),
			offset = CFrame.new(0, 0.04, -0.27) * CFrame.Angles(R(15), 0, 0),
			color = phosphate,
			material = M.Metal,
		},
		{
			name = "Selector",
			size = Vector3.new(0.02, 0.04, 0.14),
			offset = CFrame.new(-0.12, 0.26, 0.1),
			color = anodBlack,
			material = M.Metal,
		},
		{
			name = "MagRelease",
			shape = CYL,
			size = Vector3.new(0.03, 0.07, 0.07),
			offset = CFrame.new(0.12, 0.04, -0.58),
			color = anodBlack,
			material = M.Metal,
		},
		{
			name = "BoltCatch",
			size = Vector3.new(0.02, 0.1, 0.06),
			offset = CFrame.new(-0.12, 0.21, -0.47),
			color = anodBlack,
			material = M.Metal,
		},
		pin("RearTakedownPin", 0.04, 0.28, 0.25),
		pin("FrontPivotPin", 0.04, 0.28, -1),
		pin("TriggerPin", 0.035, 0.19, -0.27),
		pin("HammerPin", 0.035, 0.19, -0.1),

		-- Pistol grip: MOE-style, top buried in the lower receiver
		{
			name = "GripBody",
			size = Vector3.new(0.2, 0.7, 0.3),
			offset = GRIP,
			color = rangerGreen,
			material = M.Plastic,
		},
		{
			name = "GripPanels",
			size = Vector3.new(0.22, 0.34, 0.2),
			offset = GRIP * CFrame.new(0, -0.04, 0.01),
			color = gripTexture,
			material = M.Fabric,
		},
		{
			name = "GripCap",
			size = Vector3.new(0.22, 0.04, 0.32),
			offset = GRIP * CFrame.new(0, -0.36, 0),
			color = polyBlack,
			material = M.Plastic,
		},
		{
			name = "GripBeavertail",
			size = Vector3.new(0.18, 0.05, 0.16),
			offset = CFrame.new(0, 0.095, 0.17),
			color = rangerGreen,
			material = M.Plastic,
		},

		-- Handguard: free-float octagonal M-LOK, z -1.25 to -3.25, centered on the bore (y 0.48)
		{
			name = "HGCore",
			size = Vector3.new(0.28, 0.2, 2),
			offset = CFrame.new(0, 0.48, -2.25),
			color = rangerGreen,
			material = M.Plastic,
		},
		{
			name = "HGTop",
			size = Vector3.new(0.18, 0.04, 2),
			offset = CFrame.new(0, 0.6, -2.25),
			color = rangerGreen,
			material = M.Plastic,
		},
		{
			name = "HGBottom",
			size = Vector3.new(0.18, 0.04, 2),
			offset = CFrame.new(0, 0.36, -2.25),
			color = rangerGreen,
			material = M.Plastic,
		},
		{
			name = "HGBevelTR",
			class = "WedgePart",
			size = Vector3.new(2, 0.04, 0.05),
			offset = CFrame.new(0.115, 0.6, -2.25) * SIDE_R,
			color = rangerGreen,
			material = M.Plastic,
		},
		{
			name = "HGBevelTL",
			class = "WedgePart",
			size = Vector3.new(2, 0.04, 0.05),
			offset = CFrame.new(-0.115, 0.6, -2.25) * SIDE_L,
			color = rangerGreen,
			material = M.Plastic,
		},
		{
			name = "HGBevelBR",
			class = "WedgePart",
			size = Vector3.new(2, 0.04, 0.05),
			offset = CFrame.new(0.115, 0.36, -2.25) * FLIP_Z * SIDE_L,
			color = rangerGreen,
			material = M.Plastic,
		},
		{
			name = "HGBevelBL",
			class = "WedgePart",
			size = Vector3.new(2, 0.04, 0.05),
			offset = CFrame.new(-0.115, 0.36, -2.25) * FLIP_Z * SIDE_R,
			color = rangerGreen,
			material = M.Plastic,
		},
		{
			name = "HGRailBase",
			size = Vector3.new(0.16, 0.02, 2),
			offset = CFrame.new(0, 0.63, -2.25),
			color = anodBlack,
			material = M.Metal,
		},
		{
			name = "HGRailCrown",
			size = Vector3.new(0.14, 0.04, 2),
			offset = CFrame.new(0, 0.66, -2.25),
			color = anodBlack,
			material = M.Metal,
		},
		mlokSlot(1, -1.65),
		mlokSlot(2, -2.25),
		mlokSlot(3, -2.85),
		{
			-- Flat top against the handguard bottom (y 0.34), deep face at the rear
			name = "AngledForegrip",
			class = "WedgePart",
			size = Vector3.new(0.16, 0.12, 0.4),
			offset = CFrame.new(0, 0.28, -2.3) * FLIP_Z,
			color = rangerGreen,
			material = M.Plastic,
		},

		-- Barrel and A2 birdcage flash hider: z -3.20 to -3.95
		{
			name = "Barrel",
			shape = CYL,
			size = Vector3.new(0.43, 0.11, 0.11),
			offset = CFrame.new(0, 0.48, -3.415) * CYLINDER_Z,
			color = phosphate,
			material = M.Metal,
		},
		{
			name = "FlashHiderBase",
			shape = CYL,
			size = Vector3.new(0.06, 0.15, 0.15),
			offset = CFrame.new(0, 0.48, -3.65) * CYLINDER_Z,
			color = parkerized,
			material = M.Metal,
		},
		{
			name = "FlashHiderCore",
			shape = CYL,
			size = Vector3.new(0.21, 0.11, 0.11),
			offset = CFrame.new(0, 0.48, -3.785) * CYLINDER_Z,
			color = soot,
			material = M.Metal,
		},
		{
			name = "FlashHiderFront",
			shape = CYL,
			size = Vector3.new(0.06, 0.15, 0.15),
			offset = CFrame.new(0, 0.48, -3.92) * CYLINDER_Z,
			color = parkerized,
			material = M.Metal,
		},
		-- Prongs sit inside the 0.075 outer radius of the base and front rings
		tine("TineUR", 0.034, 0.514),
		tine("TineUL", -0.034, 0.514),
		tine("TineLR", 0.034, 0.446),
		tine("TineLL", -0.034, 0.446),

		-- Buffer tube and collapsed CTR stock: z +0.30 to +1.36
		{
			name = "BufferTube",
			shape = CYL,
			size = Vector3.new(0.9, 0.17, 0.17),
			offset = CFrame.new(0, 0.46, 0.75) * CYLINDER_Z,
			color = anodBlack,
			material = M.Metal,
		},
		{
			name = "CastleNut",
			shape = CYL,
			size = Vector3.new(0.05, 0.22, 0.22),
			offset = CFrame.new(0, 0.46, 0.385) * CYLINDER_Z,
			color = phosphate,
			material = M.Metal,
		},
		{
			name = "StockSleeve",
			size = Vector3.new(0.2, 0.22, 0.7),
			offset = CFrame.new(0, 0.46, 0.9),
			color = rangerGreen,
			material = M.Plastic,
		},
		{
			-- Flat top under the sleeve, vertical face at the butt, underside slopes down toward the butt
			name = "StockToe",
			class = "WedgePart",
			size = Vector3.new(0.18, 0.48, 0.7),
			offset = CFrame.new(0, 0.11, 0.9) * FLIP_Z,
			color = rangerGreen,
			material = M.Plastic,
		},
		{
			name = "StockPlate",
			size = Vector3.new(0.22, 0.72, 0.06),
			offset = CFrame.new(0, 0.22, 1.25),
			color = rangerGreen,
			material = M.Plastic,
		},
		{
			name = "ButtPad",
			size = Vector3.new(0.24, 0.74, 0.08),
			offset = CFrame.new(0, 0.22, 1.32),
			color = buttRubber,
			material = M.Rubber,
		},

		-- Red-dot optic on a riser, centered at z -0.55
		{
			-- Clamps over the rail crown down to the rail base (y 0.64)
			name = "OpticMount",
			size = Vector3.new(0.16, 0.14, 0.3),
			offset = CFrame.new(0, 0.71, -0.55),
			color = anodBlack,
			material = M.Metal,
		},
		{
			name = "MountClampKnob",
			shape = CYL,
			size = Vector3.new(0.06, 0.08, 0.08),
			offset = CFrame.new(0.1, 0.7, -0.55),
			color = pinSteel,
			material = M.Metal,
		},
		{
			name = "OpticBase",
			size = Vector3.new(0.18, 0.08, 0.36),
			offset = CFrame.new(0, 0.81, -0.55),
			color = anodBlack,
			material = M.Metal,
		},
		{
			-- Ends at z -0.36 / -0.74, inside the hoods, so its end faces do not fight the hood faces
			name = "OpticBody",
			shape = CYL,
			size = Vector3.new(0.38, 0.22, 0.22),
			offset = CFrame.new(0, 0.89, -0.55) * CYLINDER_Z,
			color = anodBlack,
			material = M.Metal,
		},
		{
			name = "OpticFrontHood",
			shape = CYL,
			size = Vector3.new(0.06, 0.24, 0.24),
			offset = CFrame.new(0, 0.89, -0.72) * CYLINDER_Z,
			color = anodBlack,
			material = M.Metal,
		},
		{
			name = "OpticRearHood",
			shape = CYL,
			size = Vector3.new(0.06, 0.24, 0.24),
			offset = CFrame.new(0, 0.89, -0.38) * CYLINDER_Z,
			color = anodBlack,
			material = M.Metal,
		},
		lens("FrontLens", -0.756),
		lens("RearLens", -0.344),
		{
			name = "RedDot",
			shape = BALL,
			size = Vector3.new(0.025, 0.025, 0.025),
			offset = CFrame.new(0, 0.89, -0.344),
			color = redDot,
			material = M.Neon,
		},
		{
			name = "WindageTurret",
			shape = CYL,
			size = Vector3.new(0.06, 0.08, 0.08),
			offset = CFrame.new(0.13, 0.89, -0.55),
			color = anodBlack,
			material = M.Metal,
		},
		{
			name = "ElevationTurret",
			shape = CYL,
			size = Vector3.new(0.06, 0.08, 0.08),
			offset = CFrame.new(0, 1.02, -0.55) * CYLINDER_Y,
			color = anodBlack,
			material = M.Metal,
		},

		-- Folded flip-up backup sights on the rail crown (y 0.68)
		{
			name = "RearSightBase",
			size = Vector3.new(0.14, 0.05, 0.16),
			offset = CFrame.new(0, 0.705, 0.2),
			color = anodBlack,
			material = M.Metal,
		},
		{
			name = "RearSightLeaf",
			class = "WedgePart",
			size = Vector3.new(0.1, 0.04, 0.12),
			offset = CFrame.new(0, 0.75, 0.2),
			color = anodBlack,
			material = M.Metal,
		},
		{
			name = "FrontSightBase",
			size = Vector3.new(0.14, 0.05, 0.16),
			offset = CFrame.new(0, 0.705, -3.1),
			color = anodBlack,
			material = M.Metal,
		},
		{
			name = "FrontSightLeaf",
			class = "WedgePart",
			size = Vector3.new(0.1, 0.04, 0.12),
			offset = CFrame.new(0, 0.75, -3.1) * CFrame.Angles(0, math.pi, 0),
			color = anodBlack,
			material = M.Metal,
		},

		-- Magazine: curved 30-round polymer, two segments; the lower one is 0.01 wider so the
		-- overlapping side faces at the bend do not fight
		{
			name = "MagUpper",
			size = Vector3.new(0.17, 0.4, 0.38),
			offset = CFrame.new(0, -0.24, -0.75) * CFrame.Angles(R(8), 0, 0),
			color = polyBlack,
			material = M.Plastic,
		},
		{
			name = "MagLower",
			size = Vector3.new(0.18, 0.36, 0.38),
			offset = MAG2,
			color = polyBlack,
			material = M.Plastic,
		},
		{
			name = "MagFloorplate",
			size = Vector3.new(0.21, 0.05, 0.44),
			offset = MAG2 * CFrame.new(0, -0.195, 0),
			color = polyBlack,
			material = M.Plastic,
		},
		{
			name = "MagRib1",
			size = Vector3.new(0.19, 0.04, 0.4),
			offset = MAG2 * CFrame.new(0, 0.06, 0),
			color = polyBlack,
			material = M.Plastic,
		},
		{
			name = "MagRib2",
			size = Vector3.new(0.19, 0.04, 0.4),
			offset = MAG2 * CFrame.new(0, -0.06, 0),
			color = polyBlack,
			material = M.Plastic,
		},
	},
})
