-- Shotgun: Remington 870 Wingmaster 12-gauge pump-action in pistol-grip (no buttstock) configuration.

local WeaponModel = require(script.Parent.Parent.systems.WeaponModel)

local rgb = Color3.fromRGB
local M = Enum.Material
local CYLINDER_Z = WeaponModel.CYLINDER_Z
local CYLINDER_Y = WeaponModel.CYLINDER_Y
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball

-- Grip frame: raked 18 degrees, bottom toward +Z
local G = CFrame.new(0, 0, 0.08) * CFrame.Angles(math.rad(-18), 0, 0)

local bluedSteel = rgb(36, 38, 43)
local polishedBlue = rgb(52, 55, 62)
local anodizedBlack = rgb(30, 30, 32)
local brightSteel = rgb(165, 168, 172)
local shadow = rgb(12, 12, 14)
local walnut = rgb(110, 75, 45)
local walnutRidge = rgb(92, 62, 37)
local checkering = rgb(72, 48, 30)
local capBlack = rgb(20, 20, 20)
local brassBead = rgb(196, 160, 80)
local safetyRed = rgb(170, 30, 30)

local function ribPost(index: number, z: number)
	return {
		name = "RibPost" .. index,
		size = Vector3.new(0.04, 0.04, 0.04),
		offset = CFrame.new(0, 0.68, z),
		color = polishedBlue,
		material = M.Metal,
		reflectance = 0.1,
	}
end

local function forendRidge(index: number, z: number)
	return {
		name = "Ridge" .. index,
		shape = CYL,
		size = Vector3.new(0.04, 0.3, 0.3),
		offset = CFrame.new(0, 0.36, z) * CYLINDER_Z,
		color = walnutRidge,
		material = M.Wood,
	}
end

return WeaponModel.define({
	handle = {
		size = Vector3.new(0.2, 0.2, 0.2),
		color = walnut,
		material = M.Wood,
		transparency = 1,
	},
	muzzle = CFrame.new(0, 0.58, -3.17),
	pieces = {
		-- Receiver: z +0.20 to -1.10, y 0.25 to 0.73, chamfered top edges
		{
			name = "ReceiverLower",
			size = Vector3.new(0.34, 0.38, 1.3),
			offset = CFrame.new(0, 0.44, -0.45),
			color = bluedSteel,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "ReceiverUpper",
			size = Vector3.new(0.22, 0.1, 1.3),
			offset = CFrame.new(0, 0.68, -0.45),
			color = bluedSteel,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "ChamferRight",
			class = "WedgePart",
			size = Vector3.new(1.3, 0.1, 0.06),
			offset = CFrame.new(0.14, 0.68, -0.45) * CFrame.Angles(0, math.rad(-90), 0),
			color = bluedSteel,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "ChamferLeft",
			class = "WedgePart",
			size = Vector3.new(1.3, 0.1, 0.06),
			offset = CFrame.new(-0.14, 0.68, -0.45) * CFrame.Angles(0, math.rad(90), 0),
			color = bluedSteel,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "EjectionPort",
			size = Vector3.new(0.012, 0.2, 0.45),
			offset = CFrame.new(0.176, 0.5, -0.5),
			color = shadow,
			material = M.SmoothPlastic,
		},
		{
			name = "BoltFace",
			size = Vector3.new(0.014, 0.14, 0.18),
			offset = CFrame.new(0.18, 0.5, -0.36),
			color = brightSteel,
			material = M.Metal,
			reflectance = 0.15,
		},
		{
			name = "LoadingPort",
			size = Vector3.new(0.22, 0.012, 0.36),
			offset = CFrame.new(0, 0.244, -0.88),
			color = shadow,
			material = M.SmoothPlastic,
		},
		{
			name = "PinRear",
			shape = CYL,
			size = Vector3.new(0.36, 0.04, 0.04),
			offset = CFrame.new(0, 0.3, -0.12),
			color = brightSteel,
			material = M.Metal,
			reflectance = 0.15,
		},
		{
			name = "PinFront",
			shape = CYL,
			size = Vector3.new(0.36, 0.04, 0.04),
			offset = CFrame.new(0, 0.3, -0.6),
			color = brightSteel,
			material = M.Metal,
			reflectance = 0.15,
		},

		-- Trigger group: anodized plate, trigger, guard, cross-bolt safety, action-bar release
		{
			name = "TriggerPlate",
			size = Vector3.new(0.26, 0.06, 0.8),
			offset = CFrame.new(0, 0.22, -0.3),
			color = anodizedBlack,
			material = M.Metal,
		},
		{
			name = "Trigger",
			size = Vector3.new(0.05, 0.16, 0.05),
			offset = CFrame.new(0, 0.12, -0.33) * CFrame.Angles(math.rad(12), 0, 0),
			color = bluedSteel,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "GuardBottom",
			size = Vector3.new(0.08, 0.04, 0.41),
			offset = CFrame.new(0, 0.02, -0.355),
			color = anodizedBlack,
			material = M.Metal,
		},
		{
			name = "GuardFront",
			size = Vector3.new(0.08, 0.22, 0.04),
			offset = CFrame.new(0, 0.11, -0.54),
			color = anodizedBlack,
			material = M.Metal,
		},
		{
			name = "Safety",
			shape = CYL,
			size = Vector3.new(0.32, 0.05, 0.05),
			offset = CFrame.new(0, 0.22, -0.1),
			color = bluedSteel,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "SafetyBand",
			shape = CYL,
			size = Vector3.new(0.02, 0.055, 0.055),
			offset = CFrame.new(-0.165, 0.22, -0.1),
			color = safetyRed,
			material = M.SmoothPlastic,
		},
		{
			name = "ActionRelease",
			size = Vector3.new(0.02, 0.05, 0.08),
			offset = CFrame.new(-0.14, 0.21, -0.6),
			color = anodizedBlack,
			material = M.Metal,
		},

		-- Pistol grip: rounded walnut, checkering panels, black cap, hump behind the receiver
		{
			name = "GripCore",
			size = Vector3.new(0.28, 0.85, 0.14),
			offset = G,
			color = walnut,
			material = M.Wood,
		},
		{
			name = "GripFront",
			shape = CYL,
			size = Vector3.new(0.85, 0.28, 0.28),
			offset = G * CFrame.new(0, 0, -0.07) * CYLINDER_Y,
			color = walnut,
			material = M.Wood,
		},
		{
			name = "GripRear",
			shape = CYL,
			size = Vector3.new(0.85, 0.28, 0.28),
			offset = G * CFrame.new(0, 0, 0.07) * CYLINDER_Y,
			color = walnut,
			material = M.Wood,
		},
		{
			name = "CheckerRight",
			size = Vector3.new(0.012, 0.5, 0.2),
			offset = G * CFrame.new(0.146, 0, 0),
			color = checkering,
			material = M.Fabric,
		},
		{
			name = "CheckerLeft",
			size = Vector3.new(0.012, 0.5, 0.2),
			offset = G * CFrame.new(-0.146, 0, 0),
			color = checkering,
			material = M.Fabric,
		},
		{
			name = "GripCap",
			size = Vector3.new(0.2, 0.035, 0.3),
			offset = G * CFrame.new(0, -0.4425, 0),
			color = capBlack,
			material = M.Plastic,
		},
		{
			name = "GripHump",
			class = "WedgePart",
			size = Vector3.new(0.28, 0.46, 0.12),
			offset = CFrame.new(0, 0.48, 0.26) * CFrame.Angles(0, math.rad(180), 0),
			color = walnut,
			material = M.Wood,
		},

		-- Barrel: axis y 0.58, z -1.00 to -3.15; ventilated rib on posts with front and mid beads
		{
			name = "Barrel",
			shape = CYL,
			size = Vector3.new(2.15, 0.17, 0.17),
			offset = CFrame.new(0, 0.58, -2.075) * CYLINDER_Z,
			color = bluedSteel,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "BarrelRing",
			shape = CYL,
			size = Vector3.new(0.1, 0.22, 0.22),
			offset = CFrame.new(0, 0.58, -1.13) * CYLINDER_Z,
			color = bluedSteel,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "Bore",
			shape = CYL,
			size = Vector3.new(0.012, 0.11, 0.11),
			offset = CFrame.new(0, 0.58, -3.156) * CYLINDER_Z,
			color = shadow,
			material = M.SmoothPlastic,
		},
		{
			name = "Rib",
			size = Vector3.new(0.06, 0.02, 1.9),
			offset = CFrame.new(0, 0.705, -2.15),
			color = polishedBlue,
			material = M.Metal,
			reflectance = 0.1,
		},
		ribPost(1, -1.25),
		ribPost(2, -1.7),
		ribPost(3, -2.15),
		ribPost(4, -2.6),
		ribPost(5, -3.05),
		{
			name = "FrontBead",
			shape = BALL,
			size = Vector3.new(0.05, 0.05, 0.05),
			offset = CFrame.new(0, 0.73, -3.07),
			color = brassBead,
			material = M.Metal,
			reflectance = 0.2,
		},
		{
			name = "MidBead",
			shape = BALL,
			size = Vector3.new(0.035, 0.035, 0.035),
			offset = CFrame.new(0, 0.725, -2.15),
			color = brightSteel,
			material = M.Metal,
			reflectance = 0.15,
		},

		-- Magazine tube: axis y 0.39, z -1.00 to -2.76, end cap, sling stud, barrel loop
		{
			name = "MagTube",
			shape = CYL,
			size = Vector3.new(1.76, 0.15, 0.15),
			offset = CFrame.new(0, 0.39, -1.88) * CYLINDER_Z,
			color = bluedSteel,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "MagCap",
			shape = CYL,
			size = Vector3.new(0.12, 0.17, 0.17),
			offset = CFrame.new(0, 0.39, -2.81) * CYLINDER_Z,
			color = bluedSteel,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "SlingStud",
			size = Vector3.new(0.04, 0.06, 0.04),
			offset = CFrame.new(0, 0.29, -2.81),
			color = brightSteel,
			material = M.Metal,
			reflectance = 0.15,
		},
		{
			name = "BarrelLoop",
			size = Vector3.new(0.1, 0.17, 0.1),
			offset = CFrame.new(0, 0.49, -2.68),
			color = bluedSteel,
			material = M.Metal,
			reflectance = 0.05,
		},

		-- Forend: ridged walnut pump z -1.30 to -2.30 on the mag tube, steel action bars into the receiver
		{
			name = "ForendUpper",
			size = Vector3.new(0.28, 0.12, 1),
			offset = CFrame.new(0, 0.42, -1.8),
			color = walnut,
			material = M.Wood,
		},
		{
			name = "ForendBelly",
			shape = CYL,
			size = Vector3.new(1, 0.28, 0.28),
			offset = CFrame.new(0, 0.36, -1.8) * CYLINDER_Z,
			color = walnut,
			material = M.Wood,
		},
		forendRidge(1, -1.45),
		forendRidge(2, -1.6),
		forendRidge(3, -1.75),
		forendRidge(4, -1.9),
		forendRidge(5, -2.05),
		forendRidge(6, -2.2),
		{
			name = "ForendNut",
			shape = CYL,
			size = Vector3.new(0.04, 0.17, 0.17),
			offset = CFrame.new(0, 0.39, -2.32) * CYLINDER_Z,
			color = bluedSteel,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "ActionBarRight",
			size = Vector3.new(0.02, 0.05, 0.24),
			offset = CFrame.new(0.09, 0.42, -1.2),
			color = brightSteel,
			material = M.Metal,
			reflectance = 0.15,
		},
		{
			name = "ActionBarLeft",
			size = Vector3.new(0.02, 0.05, 0.24),
			offset = CFrame.new(-0.09, 0.42, -1.2),
			color = brightSteel,
			material = M.Metal,
			reflectance = 0.15,
		},
		-- Spans z -1.275 to -1.305 so its rear face clears the forend's rear face (z -1.30) by 0.025
		{
			name = "ForendRearRing",
			shape = CYL,
			size = Vector3.new(0.03, 0.29, 0.29),
			offset = CFrame.new(0, 0.36, -1.29) * CYLINDER_Z,
			color = bluedSteel,
			material = M.Metal,
			reflectance = 0.05,
		},
	},
})
