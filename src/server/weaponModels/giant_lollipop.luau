-- Giant Lollipop: carnival "whirly pop" swirl hard candy on a rolled-paper stick, cellophane-wrapped with a satin bow.

local WeaponModel = require(script.Parent.Parent.systems.WeaponModel)

local rgb = Color3.fromRGB
local M = Enum.Material
local CYLINDER_Z = WeaponModel.CYLINDER_Z
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball

local candyPink = rgb(255, 80, 120)
local candyCream = rgb(255, 240, 230)
local stick = rgb(244, 240, 228)
local stickEnd = rgb(230, 224, 208)
local stickHollow = rgb(120, 110, 95)
local cellophane = rgb(235, 245, 255)
local ribbon = rgb(190, 20, 45)

local CANDY_GLOSS = 0.12
local WRAP_ALPHA = 0.8
local WRAP_GLOSS = 0.15

return WeaponModel.define({
	handle = {
		size = Vector3.new(0.26, 0.26, 1.2),
		color = stick,
		material = M.Plastic,
		transparency = 1,
	},
	pieces = {
		-- Rolled-paper stick
		{
			name = "Stick",
			shape = CYL,
			size = Vector3.new(5.32, 0.26, 0.26),
			offset = CFrame.new(0, 0, -2.04) * CYLINDER_Z,
			color = stick,
			material = M.Plastic,
		},
		{
			name = "StickEndCap",
			shape = CYL,
			size = Vector3.new(0.02, 0.22, 0.22),
			offset = CFrame.new(0, 0, 0.625) * CYLINDER_Z,
			color = stickEnd,
			material = M.Plastic,
		},
		{
			name = "StickHollow",
			shape = CYL,
			size = Vector3.new(0.02, 0.07, 0.07),
			offset = CFrame.new(0, 0, 0.64) * CYLINDER_Z,
			color = stickHollow,
			material = M.Plastic,
		},

		-- Candy body: nested domed rings with shifted centers (spiral read)
		{
			name = "CandyRing1",
			shape = CYL,
			size = Vector3.new(0.46, 3.2, 3.2),
			offset = CFrame.new(0, 0, -5.5),
			color = candyPink,
			material = M.SmoothPlastic,
			reflectance = CANDY_GLOSS,
		},
		{
			name = "CandyRing2",
			shape = CYL,
			size = Vector3.new(0.49, 2.84, 2.84),
			offset = CFrame.new(0, 0.04, -5.47),
			color = candyCream,
			material = M.SmoothPlastic,
			reflectance = CANDY_GLOSS,
		},
		{
			name = "CandyRing3",
			shape = CYL,
			size = Vector3.new(0.52, 2.48, 2.48),
			offset = CFrame.new(0, -0.02, -5.52),
			color = candyPink,
			material = M.SmoothPlastic,
			reflectance = CANDY_GLOSS,
		},
		{
			name = "CandyRing4",
			shape = CYL,
			size = Vector3.new(0.55, 2.12, 2.12),
			offset = CFrame.new(0, 0.05, -5.46),
			color = candyCream,
			material = M.SmoothPlastic,
			reflectance = CANDY_GLOSS,
		},
		{
			name = "CandyRing5",
			shape = CYL,
			size = Vector3.new(0.58, 1.76, 1.76),
			offset = CFrame.new(0, -0.01, -5.53),
			color = candyPink,
			material = M.SmoothPlastic,
			reflectance = CANDY_GLOSS,
		},
		{
			name = "CandyRing6",
			shape = CYL,
			size = Vector3.new(0.61, 1.4, 1.4),
			offset = CFrame.new(0, 0.04, -5.48),
			color = candyCream,
			material = M.SmoothPlastic,
			reflectance = CANDY_GLOSS,
		},
		{
			name = "CandyRing7",
			shape = CYL,
			size = Vector3.new(0.64, 1.04, 1.04),
			offset = CFrame.new(0, -0.02, -5.51),
			color = candyPink,
			material = M.SmoothPlastic,
			reflectance = CANDY_GLOSS,
		},
		{
			name = "CandyRing8",
			shape = CYL,
			size = Vector3.new(0.67, 0.68, 0.68),
			offset = CFrame.new(0, 0.03, -5.49),
			color = candyCream,
			material = M.SmoothPlastic,
			reflectance = CANDY_GLOSS,
		},
		{
			name = "CandyCenter",
			shape = CYL,
			size = Vector3.new(0.7, 0.32, 0.32),
			offset = CFrame.new(0, 0.01, -5.5),
			color = candyPink,
			material = M.SmoothPlastic,
			reflectance = CANDY_GLOSS,
		},

		-- Twisted rope rim: 16 balls on radius 1.55, starting at 11.25 degrees, 22.5 degree steps
		{
			name = "Rope01",
			shape = BALL,
			size = Vector3.new(0.48, 0.48, 0.48),
			offset = CFrame.new(0, 0.302, -3.98),
			color = candyPink,
			material = M.SmoothPlastic,
			reflectance = CANDY_GLOSS,
		},
		{
			name = "Rope02",
			shape = BALL,
			size = Vector3.new(0.48, 0.48, 0.48),
			offset = CFrame.new(0, 0.861, -4.211),
			color = candyCream,
			material = M.SmoothPlastic,
			reflectance = CANDY_GLOSS,
		},
		{
			name = "Rope03",
			shape = BALL,
			size = Vector3.new(0.48, 0.48, 0.48),
			offset = CFrame.new(0, 1.289, -4.639),
			color = candyPink,
			material = M.SmoothPlastic,
			reflectance = CANDY_GLOSS,
		},
		{
			name = "Rope04",
			shape = BALL,
			size = Vector3.new(0.48, 0.48, 0.48),
			offset = CFrame.new(0, 1.52, -5.198),
			color = candyCream,
			material = M.SmoothPlastic,
			reflectance = CANDY_GLOSS,
		},
		{
			name = "Rope05",
			shape = BALL,
			size = Vector3.new(0.48, 0.48, 0.48),
			offset = CFrame.new(0, 1.52, -5.802),
			color = candyPink,
			material = M.SmoothPlastic,
			reflectance = CANDY_GLOSS,
		},
		{
			name = "Rope06",
			shape = BALL,
			size = Vector3.new(0.48, 0.48, 0.48),
			offset = CFrame.new(0, 1.289, -6.361),
			color = candyCream,
			material = M.SmoothPlastic,
			reflectance = CANDY_GLOSS,
		},
		{
			name = "Rope07",
			shape = BALL,
			size = Vector3.new(0.48, 0.48, 0.48),
			offset = CFrame.new(0, 0.861, -6.789),
			color = candyPink,
			material = M.SmoothPlastic,
			reflectance = CANDY_GLOSS,
		},
		{
			name = "Rope08",
			shape = BALL,
			size = Vector3.new(0.48, 0.48, 0.48),
			offset = CFrame.new(0, 0.302, -7.02),
			color = candyCream,
			material = M.SmoothPlastic,
			reflectance = CANDY_GLOSS,
		},
		{
			name = "Rope09",
			shape = BALL,
			size = Vector3.new(0.48, 0.48, 0.48),
			offset = CFrame.new(0, -0.302, -7.02),
			color = candyPink,
			material = M.SmoothPlastic,
			reflectance = CANDY_GLOSS,
		},
		{
			name = "Rope10",
			shape = BALL,
			size = Vector3.new(0.48, 0.48, 0.48),
			offset = CFrame.new(0, -0.861, -6.789),
			color = candyCream,
			material = M.SmoothPlastic,
			reflectance = CANDY_GLOSS,
		},
		{
			name = "Rope11",
			shape = BALL,
			size = Vector3.new(0.48, 0.48, 0.48),
			offset = CFrame.new(0, -1.289, -6.361),
			color = candyPink,
			material = M.SmoothPlastic,
			reflectance = CANDY_GLOSS,
		},
		{
			name = "Rope12",
			shape = BALL,
			size = Vector3.new(0.48, 0.48, 0.48),
			offset = CFrame.new(0, -1.52, -5.802),
			color = candyCream,
			material = M.SmoothPlastic,
			reflectance = CANDY_GLOSS,
		},
		{
			name = "Rope13",
			shape = BALL,
			size = Vector3.new(0.48, 0.48, 0.48),
			offset = CFrame.new(0, -1.52, -5.198),
			color = candyPink,
			material = M.SmoothPlastic,
			reflectance = CANDY_GLOSS,
		},
		{
			name = "Rope14",
			shape = BALL,
			size = Vector3.new(0.48, 0.48, 0.48),
			offset = CFrame.new(0, -1.289, -4.639),
			color = candyCream,
			material = M.SmoothPlastic,
			reflectance = CANDY_GLOSS,
		},
		{
			name = "Rope15",
			shape = BALL,
			size = Vector3.new(0.48, 0.48, 0.48),
			offset = CFrame.new(0, -0.861, -4.211),
			color = candyPink,
			material = M.SmoothPlastic,
			reflectance = CANDY_GLOSS,
		},
		{
			name = "Rope16",
			shape = BALL,
			size = Vector3.new(0.48, 0.48, 0.48),
			offset = CFrame.new(0, -0.302, -3.98),
			color = candyCream,
			material = M.SmoothPlastic,
			reflectance = CANDY_GLOSS,
		},

		-- Fused candy bulge where the stick enters
		{
			name = "CandyCollar",
			shape = BALL,
			size = Vector3.new(0.4, 0.4, 0.4),
			offset = CFrame.new(0, 0, -3.9),
			color = candyPink,
			material = M.SmoothPlastic,
			reflectance = CANDY_GLOSS,
		},

		-- Cellophane wrapper (flat face of each pleat on the neck, tall end toward the candy)
		{
			name = "WrapperDisc",
			shape = CYL,
			size = Vector3.new(0.8, 3.75, 3.75),
			offset = CFrame.new(0, 0, -5.5),
			color = cellophane,
			material = M.Glass,
			transparency = WRAP_ALPHA,
			reflectance = WRAP_GLOSS,
		},
		{
			name = "WrapperNeck",
			shape = CYL,
			size = Vector3.new(0.45, 0.3, 0.3),
			offset = CFrame.new(0, 0, -3.425) * CYLINDER_Z,
			color = cellophane,
			material = M.Glass,
			transparency = WRAP_ALPHA,
			reflectance = WRAP_GLOSS,
		},
		{
			name = "WrapperFrill",
			shape = CYL,
			size = Vector3.new(0.14, 0.44, 0.44),
			offset = CFrame.new(0, 0, -3.15) * CYLINDER_Z,
			color = cellophane,
			material = M.Glass,
			transparency = WRAP_ALPHA,
			reflectance = WRAP_GLOSS,
		},
		{
			name = "PleatTop",
			class = "WedgePart",
			size = Vector3.new(0.5, 0.36, 0.3),
			offset = CFrame.new(0, 0.33, -3.55) * CFrame.Angles(0, math.pi, 0),
			color = cellophane,
			material = M.Glass,
			transparency = WRAP_ALPHA,
			reflectance = WRAP_GLOSS,
		},
		{
			name = "PleatBottom",
			class = "WedgePart",
			size = Vector3.new(0.5, 0.36, 0.3),
			offset = CFrame.new(0, -0.33, -3.55) * CFrame.Angles(math.pi, 0, 0),
			color = cellophane,
			material = M.Glass,
			transparency = WRAP_ALPHA,
			reflectance = WRAP_GLOSS,
		},
		{
			name = "PleatRight",
			class = "WedgePart",
			size = Vector3.new(0.5, 0.24, 0.3),
			offset = CFrame.new(0.27, 0, -3.55)
				* CFrame.Angles(0, 0, -math.pi / 2)
				* CFrame.Angles(0, math.pi, 0),
			color = cellophane,
			material = M.Glass,
			transparency = WRAP_ALPHA,
			reflectance = WRAP_GLOSS,
		},
		{
			name = "PleatLeft",
			class = "WedgePart",
			size = Vector3.new(0.5, 0.24, 0.3),
			offset = CFrame.new(-0.27, 0, -3.55)
				* CFrame.Angles(0, 0, math.pi / 2)
				* CFrame.Angles(0, math.pi, 0),
			color = cellophane,
			material = M.Glass,
			transparency = WRAP_ALPHA,
			reflectance = WRAP_GLOSS,
		},

		-- Satin ribbon tie (tails hang from the knot and spread outward)
		{
			name = "RibbonBand",
			shape = CYL,
			size = Vector3.new(0.12, 0.36, 0.36),
			offset = CFrame.new(0, 0, -3.3) * CYLINDER_Z,
			color = ribbon,
			material = M.Fabric,
		},
		{
			name = "BowKnot",
			shape = BALL,
			size = Vector3.new(0.14, 0.14, 0.14),
			offset = CFrame.new(0, 0.22, -3.3),
			color = ribbon,
			material = M.Fabric,
		},
		{
			name = "BowLoopLeft",
			size = Vector3.new(0.34, 0.08, 0.14),
			offset = CFrame.new(-0.19, 0.27, -3.3) * CFrame.Angles(0, 0, -0.35),
			color = ribbon,
			material = M.Fabric,
		},
		{
			name = "BowLoopRight",
			size = Vector3.new(0.34, 0.08, 0.14),
			offset = CFrame.new(0.19, 0.27, -3.3) * CFrame.Angles(0, 0, 0.35),
			color = ribbon,
			material = M.Fabric,
		},
		{
			name = "BowTailLeft",
			size = Vector3.new(0.09, 0.4, 0.03),
			offset = CFrame.new(-0.06, 0.02, -3.22) * CFrame.Angles(0, 0, -0.25),
			color = ribbon,
			material = M.Fabric,
		},
		{
			name = "BowTailRight",
			size = Vector3.new(0.09, 0.4, 0.03),
			offset = CFrame.new(0.06, 0.02, -3.22) * CFrame.Angles(0, 0, 0.25),
			color = ribbon,
			material = M.Fabric,
		},
	},
})
