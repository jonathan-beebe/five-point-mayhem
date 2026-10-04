-- Ray Gun: 1950s die-cast space-toy ray gun (Hubley "Atomic Disintegrator" / Buck Rogers XZ-38), built as a working prop.

local WeaponModel = require(script.Parent.Parent.systems.WeaponModel)

local rgb = Color3.fromRGB
local M = Enum.Material
local CYLINDER_Z = WeaponModel.CYLINDER_Z
local CYLINDER_Y = WeaponModel.CYLINDER_Y
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball

local aluminum = rgb(196, 200, 204)
local chrome = rgb(225, 228, 232)
local brass = rgb(181, 148, 82)
local finGreen = rgb(60, 120, 72)
local bakelite = rgb(92, 28, 24)
local gunmetal = rgb(52, 55, 60)
local seamDark = rgb(30, 32, 35)
local rayGreen = rgb(80, 255, 80)
local glassGreen = rgb(170, 255, 180)

-- Grip frame, raked 15 degrees so the butt sits rearward. Local +Y leans toward -Z.
local G = CFrame.new(0, -0.05, 0.02) * CFrame.Angles(math.rad(-15), 0, 0)

local function cyl(name: string, size: Vector3, offset: CFrame, color: Color3, reflectance: number?)
	return {
		name = name,
		shape = CYL,
		size = size,
		offset = offset,
		color = color,
		material = M.Metal,
		reflectance = reflectance,
	}
end

local function ball(
	name: string,
	diameter: number,
	offset: CFrame,
	color: Color3,
	material: Enum.Material
)
	return {
		name = name,
		shape = BALL,
		size = Vector3.new(diameter, diameter, diameter),
		offset = offset,
		color = color,
		material = material,
	}
end

-- Cooling fin: thin anodized disc around the barrel core.
local function fin(index: number, z: number, diameter: number)
	return cyl(
		"Fin" .. index,
		Vector3.new(0.035, diameter, diameter),
		CFrame.new(0, 0.5, z) * CYLINDER_Z,
		finGreen,
		0.1
	)
end

-- Indicator lamp: chrome bezel with a glowing bulb, on the left side of the body.
local function lampBezel(index: number, z: number)
	return cyl(
		"LampBezel" .. index,
		Vector3.new(0.03, 0.1, 0.1),
		CFrame.new(-0.255, 0.5, z),
		chrome,
		0.3
	)
end

local function lamp(index: number, z: number)
	return ball("Lamp" .. index, 0.06, CFrame.new(-0.275, 0.5, z), rayGreen, M.Neon)
end

-- Emitter prong: chrome rod with a brass ball tip, at radius 0.19 around the bore.
local function prong(name: string, x: number, y: number)
	return cyl(
		"Prong" .. name,
		Vector3.new(0.22, 0.035, 0.035),
		CFrame.new(x, y, -1.76) * CYLINDER_Z,
		chrome,
		0.3
	)
end

local function prongTip(name: string, x: number, y: number)
	return ball("ProngTip" .. name, 0.065, CFrame.new(x, y, -1.87), brass, M.Metal)
end

-- Finger rib across the grip's front strap.
local function fingerRib(index: number, y: number)
	return cyl(
		"FingerRib" .. index,
		Vector3.new(0.25, 0.07, 0.07),
		G * CFrame.new(0, y, -0.21),
		aluminum,
		0.15
	)
end

return WeaponModel.define({
	handle = {
		size = Vector3.new(0.24, 0.8, 0.4),
		color = gunmetal,
		material = M.Metal,
		transparency = 1,
	},
	muzzle = CFrame.new(0, 0.5, -1.9),
	pieces = {
		-- Receiver
		cyl(
			"Body",
			Vector3.new(0.9, 0.5, 0.5),
			CFrame.new(0, 0.5, -0.25) * CYLINDER_Z,
			aluminum,
			0.15
		),
		{
			name = "RearCap",
			shape = BALL,
			size = Vector3.new(0.5, 0.5, 0.5),
			offset = CFrame.new(0, 0.5, 0.2),
			color = aluminum,
			material = M.Metal,
			reflectance = 0.15,
		},
		cyl(
			"RearTrimRing",
			Vector3.new(0.04, 0.54, 0.54),
			CFrame.new(0, 0.5, 0.18) * CYLINDER_Z,
			chrome,
			0.3
		),
		cyl(
			"PowerDial",
			Vector3.new(0.06, 0.18, 0.18),
			CFrame.new(0, 0.5, 0.46) * CYLINDER_Z,
			chrome,
			0.3
		),
		ball("DialLamp", 0.05, CFrame.new(0, 0.5, 0.495), rayGreen, M.Neon),
		{
			name = "SeamRing",
			shape = CYL,
			size = Vector3.new(0.02, 0.52, 0.52),
			offset = CFrame.new(0, 0.5, -0.62) * CYLINDER_Z,
			color = seamDark,
			material = M.SmoothPlastic,
		},
		cyl(
			"FrontCollar",
			Vector3.new(0.06, 0.42, 0.42),
			CFrame.new(0, 0.5, -0.72) * CYLINDER_Z,
			chrome,
			0.3
		),
		{
			name = "FrameBridge",
			size = Vector3.new(0.24, 0.12, 0.5),
			offset = CFrame.new(0, 0.27, -0.25),
			color = aluminum,
			material = M.Metal,
			reflectance = 0.15,
		},
		cyl("ScrewR1", Vector3.new(0.03, 0.07, 0.07), CFrame.new(0.255, 0.5, 0.05), brass, 0.1),
		cyl("ScrewL1", Vector3.new(0.03, 0.07, 0.07), CFrame.new(-0.255, 0.5, 0.05), brass, 0.1),
		cyl("ScrewR2", Vector3.new(0.03, 0.07, 0.07), CFrame.new(0.255, 0.5, -0.55), brass, 0.1),
		cyl("ScrewL2", Vector3.new(0.03, 0.07, 0.07), CFrame.new(-0.255, 0.5, -0.55), brass, 0.1),
		{
			name = "NamePlate",
			size = Vector3.new(0.03, 0.12, 0.3),
			offset = CFrame.new(0.255, 0.5, -0.27),
			color = brass,
			material = M.Metal,
			reflectance = 0.1,
		},
		lampBezel(1, -0.15),
		lamp(1, -0.15),
		lampBezel(2, -0.27),
		lamp(2, -0.27),
		lampBezel(3, -0.39),
		lamp(3, -0.39),

		-- Charge tube and dorsal fin
		{
			name = "ChargeTube",
			shape = CYL,
			size = Vector3.new(0.44, 0.2, 0.2),
			offset = CFrame.new(0, 0.86, -0.33) * CYLINDER_Z,
			color = glassGreen,
			material = M.Glass,
			transparency = 0.5,
		},
		{
			name = "ChargeCore",
			shape = CYL,
			size = Vector3.new(0.4, 0.08, 0.08),
			offset = CFrame.new(0, 0.86, -0.33) * CYLINDER_Z,
			color = rayGreen,
			material = M.Neon,
		},
		cyl(
			"TubeCapRear",
			Vector3.new(0.05, 0.23, 0.23),
			CFrame.new(0, 0.86, -0.09) * CYLINDER_Z,
			brass,
			0.1
		),
		cyl(
			"TubeCapFront",
			Vector3.new(0.05, 0.23, 0.23),
			CFrame.new(0, 0.86, -0.57) * CYLINDER_Z,
			brass,
			0.1
		),
		{
			name = "SaddleRear",
			size = Vector3.new(0.12, 0.1, 0.05),
			offset = CFrame.new(0, 0.78, -0.09),
			color = brass,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			name = "SaddleFront",
			size = Vector3.new(0.12, 0.1, 0.05),
			offset = CFrame.new(0, 0.78, -0.57),
			color = brass,
			material = M.Metal,
			reflectance = 0.1,
		},
		{
			-- Default wedge: tall edge at +Z (rear, top y 1.00), slope running down to the rear tube cap.
			name = "DorsalFin",
			class = "WedgePart",
			size = Vector3.new(0.05, 0.28, 0.37),
			offset = CFrame.new(0, 0.86, 0.115),
			color = chrome,
			material = M.Metal,
			reflectance = 0.3,
		},

		-- Barrel, fins and emitter
		cyl(
			"BarrelCore",
			Vector3.new(0.75, 0.24, 0.24),
			CFrame.new(0, 0.5, -1.075) * CYLINDER_Z,
			gunmetal
		),
		fin(1, -0.82, 0.72),
		fin(2, -0.94, 0.68),
		fin(3, -1.06, 0.64),
		fin(4, -1.18, 0.6),
		fin(5, -1.3, 0.56),
		cyl(
			"Flare1",
			Vector3.new(0.06, 0.3, 0.3),
			CFrame.new(0, 0.5, -1.42) * CYLINDER_Z,
			chrome,
			0.3
		),
		cyl(
			"Flare2",
			Vector3.new(0.06, 0.38, 0.38),
			CFrame.new(0, 0.5, -1.48) * CYLINDER_Z,
			chrome,
			0.3
		),
		cyl(
			"Flare3",
			Vector3.new(0.06, 0.46, 0.46),
			CFrame.new(0, 0.5, -1.54) * CYLINDER_Z,
			chrome,
			0.3
		),
		cyl(
			"EmitterRim",
			Vector3.new(0.06, 0.52, 0.52),
			CFrame.new(0, 0.5, -1.6) * CYLINDER_Z,
			chrome,
			0.3
		),
		cyl(
			"EmitterDish",
			Vector3.new(0.02, 0.42, 0.42),
			CFrame.new(0, 0.5, -1.645) * CYLINDER_Z,
			gunmetal
		),
		ball("EmitterCore", 0.16, CFrame.new(0, 0.5, -1.72), rayGreen, M.Neon),
		{
			name = "EmitterDome",
			shape = BALL,
			size = Vector3.new(0.26, 0.26, 0.26),
			offset = CFrame.new(0, 0.5, -1.72),
			color = glassGreen,
			material = M.Glass,
			transparency = 0.5,
		},
		prong("Top", 0, 0.69),
		prong("Left", -0.165, 0.405),
		prong("Right", 0.165, 0.405),
		prongTip("Top", 0, 0.69),
		prongTip("Left", -0.165, 0.405),
		prongTip("Right", 0.165, 0.405),
		{
			name = "FrontSight",
			size = Vector3.new(0.03, 0.07, 0.04),
			offset = CFrame.new(0, 0.79, -1.6),
			color = chrome,
			material = M.Metal,
			reflectance = 0.3,
		},

		-- Trigger group
		{
			-- Rear end runs 0.03 into the grip front strap (meets it at z -0.20).
			name = "GuardBar",
			size = Vector3.new(0.06, 0.04, 0.43),
			offset = CFrame.new(0, -0.04, -0.385),
			color = chrome,
			material = M.Metal,
			reflectance = 0.3,
		},
		{
			name = "GuardPost",
			size = Vector3.new(0.06, 0.31, 0.04),
			offset = CFrame.new(0, 0.115, -0.58),
			color = chrome,
			material = M.Metal,
			reflectance = 0.3,
		},
		{
			name = "TriggerBlade",
			size = Vector3.new(0.05, 0.2, 0.06),
			offset = CFrame.new(0, 0.14, -0.36) * CFrame.Angles(math.rad(-12), 0, 0),
			color = chrome,
			material = M.Metal,
			reflectance = 0.3,
		},
		-- Sits on the blade's lower end (blade bottom swings to z -0.34).
		cyl("TriggerShoe", Vector3.new(0.05, 0.08, 0.08), CFrame.new(0, 0.06, -0.36), chrome, 0.3),

		-- Grip
		{
			name = "GripCore",
			size = Vector3.new(0.24, 0.9, 0.42),
			offset = G,
			color = aluminum,
			material = M.Metal,
			reflectance = 0.15,
		},
		{
			name = "GripScaleR",
			size = Vector3.new(0.04, 0.78, 0.36),
			offset = G * CFrame.new(0.14, 0, 0),
			color = bakelite,
			material = M.SmoothPlastic,
			reflectance = 0.05,
		},
		{
			name = "GripScaleL",
			size = Vector3.new(0.04, 0.78, 0.36),
			offset = G * CFrame.new(-0.14, 0, 0),
			color = bakelite,
			material = M.SmoothPlastic,
			reflectance = 0.05,
		},
		cyl("GripScrewR", Vector3.new(0.02, 0.06, 0.06), G * CFrame.new(0.165, 0, 0), brass, 0.1),
		cyl("GripScrewL", Vector3.new(0.02, 0.06, 0.06), G * CFrame.new(-0.165, 0, 0), brass, 0.1),
		fingerRib(1, -0.02),
		fingerRib(2, -0.2),
		fingerRib(3, -0.38),
		cyl(
			"Backstrap",
			Vector3.new(0.86, 0.22, 0.22),
			G * CFrame.new(0, 0, 0.17) * CYLINDER_Y,
			aluminum,
			0.15
		),
		{
			name = "ButtCap",
			size = Vector3.new(0.28, 0.06, 0.5),
			offset = G * CFrame.new(0, -0.47, 0.02),
			color = chrome,
			material = M.Metal,
			reflectance = 0.3,
		},
	},
})
