-- Firework Launcher: consumer reloadable "artillery shell" mortar tube on a hobbyist launch rig with hose clamps, pistol grip and electric igniter.

local WeaponModel = require(script.Parent.Parent.systems.WeaponModel)

local rgb = Color3.fromRGB
local M = Enum.Material
local CYLINDER_Z = WeaponModel.CYLINDER_Z
local CYLINDER_Y = WeaponModel.CYLINDER_Y
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball
local R = math.rad

-- Pistol grip frame: raked 15 degrees, top leans toward -Z.
local GRIP = CFrame.new(0, -0.26, 0.1) * CFrame.Angles(R(-15), 0, 0)

local wrapMagenta = rgb(255, 80, 200)
local kraftBrown = rgb(176, 138, 92)
local stripeYellow = rgb(255, 214, 40)
local stripeCyan = rgb(40, 200, 230)
local labelWhite = rgb(240, 236, 226)
local warningRed = rgb(200, 30, 30)
local inkBlack = rgb(25, 25, 25)
local boreBlack = rgb(18, 16, 14)
local shellRed = rgb(170, 28, 36)
local clayGray = rgb(150, 140, 125)
local fuseGreen = rgb(60, 130, 60)
local steelClamp = rgb(168, 170, 174)
local gunmetal = rgb(58, 60, 64)
local gripBlack = rgb(30, 30, 32)
local rubberBlack = rgb(22, 22, 22)
local igniterGray = rgb(70, 72, 76)
local brass = rgb(180, 150, 80)
local wireRed = rgb(160, 25, 25)
local ledRed = rgb(255, 40, 40)

local function band(name: string, length: number, z: number, color: Color3)
	return {
		name = name,
		shape = CYL,
		size = Vector3.new(length, 0.912, 0.912),
		offset = CFrame.new(0, 0.7, z) * CYLINDER_Z,
		color = color,
		material = M.SmoothPlastic,
	}
end

-- One arm of a printed starburst on the wielder's left side of the wrapper.
local function starArm(
	name: string,
	length: number,
	width: number,
	y: number,
	z: number,
	angle: number,
	color: Color3
)
	return {
		name = name,
		size = Vector3.new(0.04, length, width),
		offset = CFrame.new(-0.445, y, z) * CFrame.Angles(R(angle), 0, 0),
		color = color,
		material = M.SmoothPlastic,
	}
end

local function clamp(suffix: string, z: number)
	return {
		{
			name = "Clamp" .. suffix,
			shape = CYL,
			size = Vector3.new(0.1, 0.94, 0.94),
			offset = CFrame.new(0, 0.7, z) * CYLINDER_Z,
			color = steelClamp,
			material = M.Metal,
			reflectance = 0.15,
		},
		{
			name = "ClampHousing" .. suffix,
			size = Vector3.new(0.1, 0.14, 0.18),
			offset = CFrame.new(0.49, 0.7, z),
			color = steelClamp,
			material = M.Metal,
			reflectance = 0.15,
		},
		{
			name = "ClampScrew" .. suffix,
			shape = CYL,
			size = Vector3.new(0.22, 0.07, 0.07),
			offset = CFrame.new(0.52, 0.7, z) * CYLINDER_Y,
			color = steelClamp,
			material = M.Metal,
		},
	}
end

local function fingerRidge(name: string, localY: number)
	return {
		name = name,
		shape = CYL,
		size = Vector3.new(0.26, 0.07, 0.07),
		offset = GRIP * CFrame.new(0, localY, -0.205),
		color = rubberBlack,
		material = M.Rubber,
	}
end

local pieces = {
	-- Tube: spiral-wound kraft mortar in a glossy wrapper, axis y 0.7, z +1.00 to -2.50
	{
		name = "TubeBody",
		shape = CYL,
		size = Vector3.new(3.46, 0.9, 0.9),
		offset = CFrame.new(0, 0.7, -0.75) * CYLINDER_Z,
		color = wrapMagenta,
		material = M.SmoothPlastic,
		reflectance = 0.05,
	},
	{
		name = "FrontLip",
		shape = CYL,
		size = Vector3.new(0.12, 0.94, 0.94),
		offset = CFrame.new(0, 0.7, -2.44) * CYLINDER_Z,
		color = kraftBrown,
		material = M.Cardboard,
	},
	{
		name = "RearLip",
		shape = CYL,
		size = Vector3.new(0.12, 0.94, 0.94),
		offset = CFrame.new(0, 0.7, 0.94) * CYLINDER_Z,
		color = kraftBrown,
		material = M.Cardboard,
	},
	{
		name = "MuzzleBore",
		shape = CYL,
		size = Vector3.new(0.02, 0.74, 0.74),
		offset = CFrame.new(0, 0.7, -2.505) * CYLINDER_Z,
		color = boreBlack,
		material = M.SmoothPlastic,
	},
	{
		name = "ShellNose",
		shape = BALL,
		size = Vector3.new(0.6, 0.6, 0.6),
		offset = CFrame.new(0, 0.7, -2.27),
		color = shellRed,
		material = M.SmoothPlastic,
	},
	{
		name = "ShellFuseStub",
		shape = CYL,
		size = Vector3.new(0.06, 0.03, 0.03),
		offset = CFrame.new(0, 0.7, -2.59) * CYLINDER_Z,
		color = fuseGreen,
		material = M.Fabric,
	},
	{
		name = "RearPlug",
		shape = CYL,
		size = Vector3.new(0.03, 0.78, 0.78),
		offset = CFrame.new(0, 0.7, 1.01) * CYLINDER_Z,
		color = clayGray,
		material = M.Concrete,
	},

	-- Wrapper graphics: bands, warning label on +X, starbursts on -X
	band("BandYellowRear", 0.14, 0.62, stripeYellow),
	band("BandCyanRear", 0.06, 0.48, stripeCyan),
	band("BandYellowFront", 0.14, -2.12, stripeYellow),
	band("BandCyanFront", 0.06, -1.98, stripeCyan),
	{
		name = "WarningLabel",
		size = Vector3.new(0.03, 0.26, 1.0),
		offset = CFrame.new(0.44, 0.7, -0.9),
		color = labelWhite,
		material = M.SmoothPlastic,
	},
	{
		name = "LabelRedBar",
		size = Vector3.new(0.01, 0.07, 0.9),
		offset = CFrame.new(0.46, 0.76, -0.9),
		color = warningRed,
		material = M.SmoothPlastic,
	},
	{
		name = "LabelText1",
		size = Vector3.new(0.01, 0.025, 0.8),
		offset = CFrame.new(0.46, 0.67, -0.9),
		color = inkBlack,
		material = M.SmoothPlastic,
	},
	{
		name = "LabelText2",
		size = Vector3.new(0.01, 0.025, 0.55),
		offset = CFrame.new(0.46, 0.62, -0.775),
		color = inkBlack,
		material = M.SmoothPlastic,
	},
	starArm("StarA1", 0.26, 0.05, 0.72, -0.4, 0, stripeYellow),
	starArm("StarA2", 0.26, 0.05, 0.72, -0.4, 60, stripeYellow),
	starArm("StarA3", 0.26, 0.05, 0.72, -0.4, 120, stripeYellow),
	starArm("StarB1", 0.2, 0.04, 0.68, -1.3, 0, stripeCyan),
	starArm("StarB2", 0.2, 0.04, 0.68, -1.3, 60, stripeCyan),
	starArm("StarB3", 0.2, 0.04, 0.68, -1.3, 120, stripeCyan),

	-- Mount saddle under the tube: y 0.16 to 0.30, z +0.20 to -2.00
	{
		name = "Saddle",
		size = Vector3.new(0.34, 0.14, 1.9),
		offset = CFrame.new(0, 0.23, -0.9),
		color = gunmetal,
		material = M.Metal,
	},
	{
		name = "SaddleChamferFront",
		class = "WedgePart",
		size = Vector3.new(0.34, 0.14, 0.15),
		offset = CFrame.new(0, 0.23, -1.925),
		color = gunmetal,
		material = M.Metal,
	},
	{
		name = "SaddleChamferRear",
		class = "WedgePart",
		size = Vector3.new(0.34, 0.14, 0.15),
		offset = CFrame.new(0, 0.23, 0.125) * CFrame.Angles(0, math.pi, 0),
		color = gunmetal,
		material = M.Metal,
	},

	-- Polymer pistol grip: housing y -0.03 to 0.17, grip raked down to the butt cap at y -0.67
	{
		name = "GripHousing",
		size = Vector3.new(0.3, 0.2, 0.9),
		offset = CFrame.new(0, 0.07, -0.15),
		color = gripBlack,
		material = M.Plastic,
	},
	{
		name = "PistolGrip",
		size = Vector3.new(0.28, 0.76, 0.42),
		offset = GRIP,
		color = gripBlack,
		material = M.Plastic,
	},
	{
		name = "ButtCap",
		size = Vector3.new(0.3, 0.06, 0.46),
		offset = GRIP * CFrame.new(0, -0.4, 0.02),
		color = gripBlack,
		material = M.Plastic,
	},
	{
		name = "GripPanelR",
		size = Vector3.new(0.02, 0.5, 0.32),
		offset = GRIP * CFrame.new(0.145, -0.05, 0),
		color = rubberBlack,
		material = M.Rubber,
	},
	{
		name = "GripPanelL",
		size = Vector3.new(0.02, 0.5, 0.32),
		offset = GRIP * CFrame.new(-0.145, -0.05, 0),
		color = rubberBlack,
		material = M.Rubber,
	},
	fingerRidge("FingerRidge1", -0.04),
	fingerRidge("FingerRidge2", -0.16),
	fingerRidge("FingerRidge3", -0.28),

	-- Trigger group
	{
		name = "Trigger",
		size = Vector3.new(0.06, 0.2, 0.06),
		offset = CFrame.new(0, -0.11, -0.33) * CFrame.Angles(R(12), 0, 0),
		color = gunmetal,
		material = M.Metal,
	},
	{
		name = "GuardBottom",
		size = Vector3.new(0.08, 0.05, 0.49),
		offset = CFrame.new(0, -0.3, -0.325),
		color = gripBlack,
		material = M.Plastic,
	},
	{
		name = "GuardFront",
		size = Vector3.new(0.08, 0.3, 0.05),
		offset = CFrame.new(0, -0.16, -0.545),
		color = gripBlack,
		material = M.Plastic,
	},

	-- Battery igniter box on the left of the housing: x -0.285 to -0.145, y -0.02 to 0.165
	{
		name = "IgniterBox",
		size = Vector3.new(0.14, 0.185, 0.36),
		offset = CFrame.new(-0.215, 0.0725, -0.15),
		color = igniterGray,
		material = M.Plastic,
	},
	{
		name = "ArmSwitch",
		size = Vector3.new(0.05, 0.1, 0.04),
		offset = CFrame.new(-0.22, 0.2, -0.05) * CFrame.Angles(R(20), 0, 0),
		color = warningRed,
		material = M.Plastic,
	},
	{
		name = "ArmedLED",
		shape = BALL,
		size = Vector3.new(0.05, 0.05, 0.05),
		offset = CFrame.new(-0.22, 0.175, -0.25),
		color = ledRed,
		material = M.Neon,
	},
	{
		name = "ArmLabel",
		size = Vector3.new(0.01, 0.05, 0.12),
		offset = CFrame.new(-0.288, 0.07, -0.15),
		color = stripeYellow,
		material = M.SmoothPlastic,
	},
	{
		name = "BoxScrew1",
		shape = CYL,
		size = Vector3.new(0.02, 0.04, 0.04),
		offset = CFrame.new(-0.29, 0.13, -0.3),
		color = gunmetal,
		material = M.Metal,
	},
	{
		name = "BoxScrew2",
		shape = CYL,
		size = Vector3.new(0.02, 0.04, 0.04),
		offset = CFrame.new(-0.29, 0.01, 0),
		color = gunmetal,
		material = M.Metal,
	},

	-- Visco fuse, alligator clip and lead wire to the igniter
	{
		name = "ViscoFuse",
		shape = CYL,
		size = Vector3.new(0.22, 0.06, 0.06),
		offset = CFrame.new(0, 0.7, 1.11) * CYLINDER_Z,
		color = fuseGreen,
		material = M.Fabric,
	},
	{
		name = "ClipJawTop",
		size = Vector3.new(0.05, 0.03, 0.14),
		offset = CFrame.new(0, 0.74, 1.16),
		color = brass,
		material = M.Metal,
		reflectance = 0.1,
	},
	{
		name = "ClipJawBottom",
		size = Vector3.new(0.05, 0.03, 0.14),
		offset = CFrame.new(0, 0.66, 1.16),
		color = brass,
		material = M.Metal,
		reflectance = 0.1,
	},
	{
		name = "ClipBoot",
		size = Vector3.new(0.07, 0.12, 0.12),
		offset = CFrame.new(0, 0.7, 1.28),
		color = warningRed,
		material = M.Rubber,
	},
	{
		name = "LeadWire1",
		shape = CYL,
		size = Vector3.new(0.6, 0.04, 0.04),
		offset = CFrame.lookAt(Vector3.new(-0.1, 0.405, 1.22), Vector3.new(-0.2, 0.15, 1.12))
			* CYLINDER_Z,
		color = wireRed,
		material = M.Plastic,
	},
	{
		name = "LeadWireBend",
		shape = BALL,
		size = Vector3.new(0.05, 0.05, 0.05),
		offset = CFrame.new(-0.2, 0.15, 1.12),
		color = wireRed,
		material = M.Plastic,
	},
	{
		name = "LeadWire2",
		shape = CYL,
		size = Vector3.new(1.12, 0.04, 0.04),
		offset = CFrame.lookAt(Vector3.new(-0.21, 0.115, 0.57), Vector3.new(-0.22, 0.08, 0.02))
			* CYLINDER_Z,
		color = wireRed,
		material = M.Plastic,
	},

	-- Sights: front post and open-notch rear, bases sunk into the tube top
	{
		name = "FrontSightBase",
		size = Vector3.new(0.12, 0.06, 0.14),
		offset = CFrame.new(0, 1.16, -2.3),
		color = gunmetal,
		material = M.Metal,
	},
	{
		name = "FrontSightPost",
		size = Vector3.new(0.03, 0.14, 0.03),
		offset = CFrame.new(0, 1.255, -2.3),
		color = gunmetal,
		material = M.Metal,
	},
	{
		name = "RearSightBase",
		size = Vector3.new(0.2, 0.06, 0.18),
		offset = CFrame.new(0, 1.16, 0.25),
		color = gunmetal,
		material = M.Metal,
	},
	{
		name = "RearSightEarL",
		size = Vector3.new(0.03, 0.16, 0.04),
		offset = CFrame.new(-0.07, 1.265, 0.25),
		color = gunmetal,
		material = M.Metal,
	},
	{
		name = "RearSightEarR",
		size = Vector3.new(0.03, 0.16, 0.04),
		offset = CFrame.new(0.07, 1.265, 0.25),
		color = gunmetal,
		material = M.Metal,
	},
}

-- Steel worm-drive hose clamps holding the tube to the saddle, screw housings on +X
for _, piece in clamp("Rear", -0.05) do
	table.insert(pieces, piece)
end
for _, piece in clamp("Front", -1.55) do
	table.insert(pieces, piece)
end

return WeaponModel.define({
	handle = {
		size = Vector3.new(0.4, 0.4, 1.2),
		color = gripBlack,
		material = M.Plastic,
		transparency = 1,
	},
	muzzle = CFrame.new(0, 0.7, -2.65),
	pieces = pieces,
})
