-- Laser Pistol: compact striker-fired polymer service pistol (Glock 19 / SIG P320 proportions)
-- with a directed-energy emitter in place of the barrel, built like a prototype film prop.

local WeaponModel = require(script.Parent.Parent.systems.WeaponModel)

local rgb = Color3.fromRGB
local M = Enum.Material
local CYLINDER_Z = WeaponModel.CYLINDER_Z
local CYL = Enum.PartType.Cylinder

-- Wedge orientations (WedgePart default slope faces +Y/-Z).
local SIDE_L = CFrame.Angles(0, math.rad(90), 0) -- length along Z, slope facing up and -X
local SIDE_R = CFrame.Angles(0, math.rad(-90), 0) -- length along Z, slope facing up and +X

-- Grip frame: raked 15 degrees, bottom toward +Z. Grip details are placed in this local space.
local GRIP = CFrame.new(0, -0.14, 0.10) * CFrame.Angles(math.rad(-15), 0, 0)

local BORE_Y = 0.47

local POLYMER = rgb(30, 31, 33)
local GRIP_RUBBER = rgb(22, 22, 24)
local GUNMETAL = rgb(62, 64, 68)
local DARK_STEEL = rgb(34, 35, 38)
local ALUMINUM = rgb(165, 168, 172)
local ANODIZED_RED = rgb(165, 30, 40)
local COPPER = rgb(176, 104, 62)
local SILVER = rgb(150, 152, 156)
local EMITTER_RED = rgb(255, 50, 60)
local LENS_GLASS = rgb(255, 150, 150)

local SCREW_HEAD = Vector3.new(0.02, 0.03, 0.03)
local VENT_SLOT = Vector3.new(0.02, 0.07, 0.05)
local SERRATION = Vector3.new(0.02, 0.18, 0.025)
local FIN = Vector3.new(0.03, 0.24, 0.24)

local pieces: { WeaponModel.PieceSpec } = {
	-- Upper housing
	{
		name = "UpperHousing",
		size = Vector3.new(0.30, 0.24, 1.40),
		offset = CFrame.new(0, 0.44, -0.35),
		color = GUNMETAL,
		material = M.Metal,
	},
	{
		name = "TopDeck",
		size = Vector3.new(0.20, 0.06, 1.40),
		offset = CFrame.new(0, 0.59, -0.35),
		color = GUNMETAL,
		material = M.Metal,
	},
	{
		name = "TopChamferL",
		class = "WedgePart",
		size = Vector3.new(1.40, 0.06, 0.05),
		offset = CFrame.new(-0.125, 0.59, -0.35) * SIDE_L,
		color = GUNMETAL,
		material = M.Metal,
	},
	{
		name = "TopChamferR",
		class = "WedgePart",
		size = Vector3.new(1.40, 0.06, 0.05),
		offset = CFrame.new(0.125, 0.59, -0.35) * SIDE_R,
		color = GUNMETAL,
		material = M.Metal,
	},
	{
		name = "RearPlate",
		size = Vector3.new(0.26, 0.26, 0.03),
		offset = CFrame.new(0, 0.46, 0.365),
		color = DARK_STEEL,
		material = M.Metal,
	},
	{
		name = "FrontBezel",
		size = Vector3.new(0.28, 0.28, 0.03),
		offset = CFrame.new(0, 0.465, -1.065),
		color = DARK_STEEL,
		material = M.Metal,
	},

	-- Housing side panels
	{
		name = "SidePanelL",
		size = Vector3.new(0.02, 0.12, 0.50),
		offset = CFrame.new(-0.16, 0.44, -0.55),
		color = ANODIZED_RED,
		material = M.Metal,
	},
	{
		name = "SidePanelR",
		size = Vector3.new(0.02, 0.12, 0.50),
		offset = CFrame.new(0.16, 0.44, -0.55),
		color = ANODIZED_RED,
		material = M.Metal,
	},

	-- Sights
	{
		name = "RearSightL",
		size = Vector3.new(0.08, 0.07, 0.06),
		offset = CFrame.new(-0.08, 0.645, 0.28),
		color = DARK_STEEL,
		material = M.Metal,
	},
	{
		name = "RearSightR",
		size = Vector3.new(0.08, 0.07, 0.06),
		offset = CFrame.new(0.08, 0.645, 0.28),
		color = DARK_STEEL,
		material = M.Metal,
	},
	{
		name = "FrontSight",
		size = Vector3.new(0.04, 0.07, 0.06),
		offset = CFrame.new(0, 0.645, -0.98),
		color = DARK_STEEL,
		material = M.Metal,
	},
	{
		name = "FrontSightFiber",
		size = Vector3.new(0.025, 0.025, 0.02),
		offset = CFrame.new(0, 0.66, -0.945),
		color = EMITTER_RED,
		material = M.Neon,
	},

	-- Frame
	{
		name = "Frame",
		size = Vector3.new(0.28, 0.15, 1.22),
		offset = CFrame.new(0, 0.25, -0.39),
		color = POLYMER,
		material = M.Plastic,
	},
	{
		name = "Rail",
		size = Vector3.new(0.16, 0.04, 0.40),
		offset = CFrame.new(0, 0.16, -0.78),
		color = DARK_STEEL,
		material = M.Metal,
	},
	{
		name = "RailSlot1",
		size = Vector3.new(0.17, 0.02, 0.03),
		offset = CFrame.new(0, 0.155, -0.71),
		color = POLYMER,
		material = M.Plastic,
	},
	{
		name = "RailSlot2",
		size = Vector3.new(0.17, 0.02, 0.03),
		offset = CFrame.new(0, 0.155, -0.85),
		color = POLYMER,
		material = M.Plastic,
	},
	{
		name = "TakedownLever",
		size = Vector3.new(0.30, 0.03, 0.08),
		offset = CFrame.new(0, 0.28, -0.50),
		color = DARK_STEEL,
		material = M.Metal,
	},
	{
		name = "SlideStop",
		size = Vector3.new(0.02, 0.04, 0.20),
		offset = CFrame.new(-0.145, 0.30, -0.15),
		color = DARK_STEEL,
		material = M.Metal,
	},
	{
		name = "TriggerPin",
		shape = CYL,
		size = Vector3.new(0.30, 0.03, 0.03),
		offset = CFrame.new(0, 0.24, -0.30),
		color = SILVER,
		material = M.Metal,
	},

	-- Trigger group
	{
		name = "GuardBottom",
		size = Vector3.new(0.08, 0.04, 0.48),
		offset = CFrame.new(0, -0.08, -0.38),
		color = POLYMER,
		material = M.Plastic,
	},
	{
		name = "GuardFront",
		size = Vector3.new(0.08, 0.26, 0.04),
		offset = CFrame.new(0, 0.05, -0.60),
		color = POLYMER,
		material = M.Plastic,
	},
	{
		name = "TriggerUpper",
		size = Vector3.new(0.05, 0.10, 0.04),
		offset = CFrame.new(0, 0.13, -0.34) * CFrame.Angles(math.rad(-8), 0, 0),
		color = DARK_STEEL,
		material = M.Metal,
	},
	{
		name = "TriggerLower",
		size = Vector3.new(0.05, 0.10, 0.04),
		offset = CFrame.new(0, 0.04, -0.355) * CFrame.Angles(math.rad(15), 0, 0),
		color = DARK_STEEL,
		material = M.Metal,
	},

	-- Grip and power cell
	{
		name = "GripCore",
		size = Vector3.new(0.26, 0.80, 0.42),
		offset = GRIP,
		color = POLYMER,
		material = M.Plastic,
	},
	{
		name = "GripPanelL",
		size = Vector3.new(0.02, 0.62, 0.34),
		offset = GRIP * CFrame.new(-0.145, -0.02, 0.005),
		color = GRIP_RUBBER,
		material = M.Rubber,
	},
	{
		name = "GripPanelR",
		size = Vector3.new(0.02, 0.62, 0.34),
		offset = GRIP * CFrame.new(0.145, -0.02, 0.005),
		color = GRIP_RUBBER,
		material = M.Rubber,
	},
	{
		name = "GripScrewL",
		shape = CYL,
		size = SCREW_HEAD,
		offset = GRIP * CFrame.new(-0.155, -0.02, 0.005),
		color = SILVER,
		material = M.Metal,
	},
	{
		name = "GripScrewR",
		shape = CYL,
		size = SCREW_HEAD,
		offset = GRIP * CFrame.new(0.155, -0.02, 0.005),
		color = SILVER,
		material = M.Metal,
	},
	{
		name = "FrontStrap",
		size = Vector3.new(0.24, 0.62, 0.02),
		offset = GRIP * CFrame.new(0, -0.06, -0.215),
		color = GRIP_RUBBER,
		material = M.Rubber,
	},
	{
		name = "Backstrap",
		size = Vector3.new(0.24, 0.66, 0.03),
		offset = GRIP * CFrame.new(0, 0, 0.22),
		color = POLYMER,
		material = M.Plastic,
	},
	{
		name = "Beavertail",
		size = Vector3.new(0.24, 0.06, 0.18),
		offset = CFrame.new(0, 0.21, 0.29),
		color = POLYMER,
		material = M.Plastic,
	},
	{
		name = "CellRelease",
		shape = CYL,
		size = Vector3.new(0.06, 0.06, 0.06),
		offset = CFrame.new(-0.15, 0.12, -0.17),
		color = POLYMER,
		material = M.Plastic,
	},
	{
		name = "CellBase",
		size = Vector3.new(0.30, 0.06, 0.46),
		offset = GRIP * CFrame.new(0, -0.425, 0),
		color = DARK_STEEL,
		material = M.Metal,
	},
	{
		name = "CellIndicator",
		size = Vector3.new(0.14, 0.025, 0.02),
		offset = GRIP * CFrame.new(0, -0.425, 0.225),
		color = EMITTER_RED,
		material = M.Neon,
	},

	-- Emitter
	{
		name = "EmitterBarrel",
		shape = CYL,
		size = Vector3.new(0.50, 0.16, 0.16),
		offset = CFrame.new(0, BORE_Y, -1.20) * CYLINDER_Z,
		color = DARK_STEEL,
		material = M.Metal,
	},
	{
		name = "Coil",
		shape = CYL,
		size = Vector3.new(0.20, 0.18, 0.18),
		offset = CFrame.new(0, BORE_Y, -1.19) * CYLINDER_Z,
		color = COPPER,
		material = M.Metal,
		reflectance = 0.1,
	},
	{
		name = "Shroud",
		shape = CYL,
		size = Vector3.new(0.10, 0.22, 0.22),
		offset = CFrame.new(0, BORE_Y, -1.37) * CYLINDER_Z,
		color = GUNMETAL,
		material = M.Metal,
	},
	{
		name = "CrownRing",
		shape = CYL,
		size = Vector3.new(0.04, 0.20, 0.20),
		offset = CFrame.new(0, BORE_Y, -1.44) * CYLINDER_Z,
		color = DARK_STEEL,
		material = M.Metal,
	},
	{
		name = "Lens",
		shape = CYL,
		size = Vector3.new(0.02, 0.11, 0.11),
		offset = CFrame.new(0, BORE_Y, -1.475) * CYLINDER_Z,
		color = EMITTER_RED,
		material = M.Neon,
	},
	{
		name = "LensGlass",
		shape = CYL,
		size = Vector3.new(0.04, 0.14, 0.14),
		offset = CFrame.new(0, BORE_Y, -1.475) * CYLINDER_Z,
		color = LENS_GLASS,
		material = M.Glass,
		transparency = 0.6,
		reflectance = 0.2,
	},
}

-- Machined vent slots and hex screws on both red side panels.
for _, side in { -1, 1 } do
	for index, z in { -0.45, -0.55, -0.65 } do
		table.insert(pieces, {
			name = `VentSlot{side < 0 and "L" or "R"}{index}`,
			size = VENT_SLOT,
			offset = CFrame.new(side * 0.175, 0.44, z),
			color = DARK_STEEL,
			material = M.Metal,
		})
	end
	for index, z in { -0.33, -0.77 } do
		table.insert(pieces, {
			name = `PanelScrew{side < 0 and "L" or "R"}{index}`,
			shape = CYL,
			size = SCREW_HEAD,
			offset = CFrame.new(side * 0.175, 0.44, z),
			color = SILVER,
			material = M.Metal,
		})
	end
	-- Rear cocking serrations.
	for index, z in { 0.12, 0.19, 0.26 } do
		table.insert(pieces, {
			name = `Serration{side < 0 and "L" or "R"}{index}`,
			size = SERRATION,
			offset = CFrame.new(side * 0.155, 0.44, z),
			color = DARK_STEEL,
			material = M.Metal,
		})
	end
end

-- Heat-sink fins over the coil.
for index, z in { -1.10, -1.16, -1.22, -1.28 } do
	table.insert(pieces, {
		name = `Fin{index}`,
		shape = CYL,
		size = FIN,
		offset = CFrame.new(0, BORE_Y, z) * CYLINDER_Z,
		color = ALUMINUM,
		material = M.Metal,
	})
end

return WeaponModel.define({
	handle = {
		size = Vector3.new(0.2, 0.2, 0.2),
		color = POLYMER,
		material = M.Plastic,
		transparency = 1,
	},
	muzzle = CFrame.new(0, BORE_Y, -1.50),
	pieces = pieces,
})
