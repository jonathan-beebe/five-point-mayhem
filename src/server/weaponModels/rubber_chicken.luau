-- Rubber Chicken: classic 22-inch hollow yellow latex novelty chicken (Loftus / Archie McPhee style), held by the ankles.

local WeaponModel = require(script.Parent.Parent.systems.WeaponModel)

local rgb = Color3.fromRGB
local M = Enum.Material
local CYLINDER_Z = WeaponModel.CYLINDER_Z
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball
local R = math.rad

local latexYellow = rgb(255, 220, 60)
local latexCrease = rgb(222, 184, 40)
local combRed = rgb(200, 32, 32)
local wattleRed = rgb(178, 26, 30)
local beakOrange = rgb(242, 138, 28)
local mouthDark = rgb(110, 18, 22)
local legOrange = rgb(236, 148, 36)
local nailBrown = rgb(92, 58, 32)
local eyeWhite = rgb(240, 238, 228)
local eyeBlack = rgb(18, 16, 16)

local GLOSS = 0.03 -- semi-gloss latex

-- Rx(a): positive a raises the -Z end. Ry(a): positive a swings the -Z end toward -X.
local function rx(degrees: number): CFrame
	return CFrame.Angles(R(degrees), 0, 0)
end

local function ry(degrees: number): CFrame
	return CFrame.Angles(0, R(degrees), 0)
end

local function ball(name: string, d: number, offset: CFrame, color: Color3, reflectance: number?)
	return {
		name = name,
		shape = BALL,
		size = Vector3.new(d, d, d),
		offset = offset,
		color = color,
		material = M.SmoothPlastic,
		reflectance = reflectance or GLOSS,
	}
end

local pieces: { WeaponModel.PieceSpec } = {
	-- Body: capsule core, breast and belly sag, spine ridge, tail nub, skin fold
	{
		name = "BodyCore",
		shape = CYL,
		size = Vector3.new(1.1, 0.9, 0.9),
		offset = CFrame.new(0, 0.3, -1.7) * CYLINDER_Z,
		color = latexYellow,
		material = M.SmoothPlastic,
		reflectance = GLOSS,
	},
	ball("BodyRearCap", 0.9, CFrame.new(0, 0.3, -1.15), latexYellow),
	ball("BodyFrontCap", 0.9, CFrame.new(0, 0.32, -2.25), latexYellow),
	ball("Breast", 0.82, CFrame.new(0, 0.18, -2.3), latexYellow),
	ball("Belly", 0.8, CFrame.new(0, 0.12, -1.6), latexYellow),
	{
		name = "SpineRidge",
		shape = CYL,
		size = Vector3.new(1.3, 0.16, 0.16),
		offset = CFrame.new(0, 0.74, -1.7) * CYLINDER_Z,
		color = latexCrease,
		material = M.SmoothPlastic,
	},
	ball("Tail", 0.4, CFrame.new(0, 0.55, -0.75), latexYellow),
	{
		name = "SkinFoldRing",
		shape = CYL,
		size = Vector3.new(0.04, 0.94, 0.94),
		offset = CFrame.new(0, 0.3, -1.4) * CYLINDER_Z,
		color = latexCrease,
		material = M.SmoothPlastic,
	},

	-- Neck: crop, two curving segments with a joint, wrinkle rings
	ball("Crop", 0.5, CFrame.new(0, 0.5, -2.58), latexYellow),
	{
		name = "NeckLower",
		shape = CYL,
		size = Vector3.new(0.5, 0.36, 0.36),
		offset = CFrame.new(0, 0.5, -2.78) * rx(16) * CYLINDER_Z,
		color = latexYellow,
		material = M.SmoothPlastic,
		reflectance = GLOSS,
	},
	ball("NeckJoint", 0.36, CFrame.new(0, 0.57, -3.02), latexYellow),
	{
		name = "NeckUpper",
		shape = CYL,
		size = Vector3.new(0.44, 0.32, 0.32),
		offset = CFrame.new(0, 0.675, -3.2) * rx(30) * CYLINDER_Z,
		color = latexYellow,
		material = M.SmoothPlastic,
		reflectance = GLOSS,
	},
	{
		name = "NeckWrinkle1",
		shape = CYL,
		size = Vector3.new(0.035, 0.4, 0.4),
		offset = CFrame.new(0, 0.535, -2.9) * rx(16) * CYLINDER_Z,
		color = latexCrease,
		material = M.SmoothPlastic,
	},
	{
		name = "NeckWrinkle2",
		shape = CYL,
		size = Vector3.new(0.035, 0.37, 0.37),
		offset = CFrame.new(0, 0.64, -3.14) * rx(30) * CYLINDER_Z,
		color = latexCrease,
		material = M.SmoothPlastic,
	},

	-- Head: skull, jaw, serrated comb of flat discs on a thinner base blade
	ball("Skull", 0.5, CFrame.new(0, 0.82, -3.5), latexYellow),
	ball("Jaw", 0.38, CFrame.new(0, 0.72, -3.64), latexYellow),
	{
		name = "CombBase",
		size = Vector3.new(0.06, 0.14, 0.46),
		offset = CFrame.new(0, 1.04, -3.52),
		color = combRed,
		material = M.SmoothPlastic,
		reflectance = GLOSS,
	},
	{
		name = "CombLobe1",
		shape = CYL,
		size = Vector3.new(0.08, 0.18, 0.18),
		offset = CFrame.new(0, 1.1, -3.32),
		color = combRed,
		material = M.SmoothPlastic,
		reflectance = GLOSS,
	},
	{
		name = "CombLobe2",
		shape = CYL,
		size = Vector3.new(0.1, 0.24, 0.24),
		offset = CFrame.new(0, 1.16, -3.46),
		color = combRed,
		material = M.SmoothPlastic,
		reflectance = GLOSS,
	},
	{
		name = "CombLobe3",
		shape = CYL,
		size = Vector3.new(0.08, 0.22, 0.22),
		offset = CFrame.new(0, 1.15, -3.6),
		color = combRed,
		material = M.SmoothPlastic,
		reflectance = GLOSS,
	},
	{
		name = "CombLobe4",
		shape = CYL,
		size = Vector3.new(0.1, 0.16, 0.16),
		offset = CFrame.new(0, 1.08, -3.72),
		color = combRed,
		material = M.SmoothPlastic,
		reflectance = GLOSS,
	},

	-- Screaming open beak: upper wedge tipped up, lower wedge flipped and dropped, dark mouth
	{
		name = "BeakUpper",
		class = "WedgePart",
		size = Vector3.new(0.2, 0.14, 0.34),
		offset = CFrame.new(0, 0.8, -3.86) * rx(8),
		color = beakOrange,
		material = M.SmoothPlastic,
		reflectance = GLOSS,
	},
	{
		name = "BeakLower",
		class = "WedgePart",
		size = Vector3.new(0.16, 0.09, 0.26),
		offset = CFrame.new(0, 0.62, -3.8) * rx(-18) * CFrame.Angles(0, 0, math.pi),
		color = beakOrange,
		material = M.SmoothPlastic,
		reflectance = GLOSS,
	},
	{
		name = "MouthInterior",
		size = Vector3.new(0.14, 0.12, 0.1),
		offset = CFrame.new(0, 0.69, -3.8),
		color = mouthDark,
		material = M.SmoothPlastic,
	},
	ball("WattleUpper", 0.18, CFrame.new(0, 0.52, -3.7), wattleRed),
	ball("WattleLower", 0.14, CFrame.new(0, 0.41, -3.68), wattleRed),
}

local function add(piece)
	table.insert(pieces, piece)
end

for _, s in { 1, -1 } do
	local side = if s > 0 then "_R" else "_L"

	-- Painted eyes: white disc sunk into the skull, black pupil bead through it
	add({
		name = "EyeWhite" .. side,
		shape = CYL,
		size = Vector3.new(0.05, 0.13, 0.13),
		offset = CFrame.new(s * 0.215, 0.9, -3.56),
		color = eyeWhite,
		material = M.SmoothPlastic,
	})
	add(ball("EyePupil" .. side, 0.08, CFrame.new(s * 0.25, 0.9, -3.57), eyeBlack, 0.25))

	-- Wings folded tight: rear tucked in toward the body and dropped slightly
	local wing = CFrame.new(s * 0.47, 0.42, -1.85) * ry(-s * 6) * rx(8)
	add(ball("WingShoulder" .. side, 0.34, CFrame.new(s * 0.4, 0.45, -2.15), latexYellow))
	add({
		name = "WingUpper" .. side,
		size = Vector3.new(0.12, 0.34, 0.6),
		offset = wing,
		color = latexYellow,
		material = M.SmoothPlastic,
		reflectance = GLOSS,
	})
	add({
		name = "WingTip" .. side,
		class = "WedgePart",
		size = Vector3.new(0.1, 0.3, 0.5),
		offset = CFrame.new(s * 0.45, 0.36, -1.35) * ry(-s * 6) * CFrame.Angles(0, math.pi, 0),
		color = latexYellow,
		material = M.SmoothPlastic,
		reflectance = GLOSS,
	})
	add({
		name = "WingCrease" .. side,
		size = Vector3.new(0.02, 0.03, 0.5),
		offset = wing * CFrame.new(s * 0.065, -0.02, 0), -- 0.005 into the outer face, 0.015 proud
		color = latexCrease,
		material = M.SmoothPlastic,
	})

	-- Legs: drumstick bulging from the rear of the body, knee, long scaly shank to the ankle (in the fist)
	local leg = ry(-s * 5.7)
	add(ball("Drumstick" .. side, 0.42, CFrame.new(s * 0.21, 0.02, -1.02), latexYellow))
	add(ball("Knee" .. side, 0.3, CFrame.new(s * 0.19, -0.04, -0.84), latexYellow))
	add({
		name = "Shank" .. side,
		shape = CYL,
		size = Vector3.new(0.88, 0.13, 0.13),
		offset = CFrame.new(s * 0.135, -0.01, -0.4) * leg * CYLINDER_Z,
		color = legOrange,
		material = M.Rubber,
	})
	add({
		name = "ShankScaleRing" .. side,
		shape = CYL,
		size = Vector3.new(0.03, 0.155, 0.155),
		offset = CFrame.new(s * 0.153, -0.014, -0.58) * leg * CYLINDER_Z,
		color = legOrange,
		material = M.Rubber,
	})
	add({
		name = "Ankle" .. side,
		shape = BALL,
		size = Vector3.new(0.16, 0.16, 0.16),
		offset = CFrame.new(s * 0.09, 0, 0.05),
		color = legOrange,
		material = M.Rubber,
	})

	-- Feet: three toes from the ankle, drooping 20 degrees toward +Z and splayed, dark nail at each tip
	local toes = {
		{ "Middle", CFrame.new(s * 0.09, -0.058, 0.21), 0, CFrame.new(s * 0.09, -0.116, 0.37) },
		{
			"Outer",
			CFrame.new(s * 0.157, -0.058, 0.195),
			s * 25,
			CFrame.new(s * 0.225, -0.116, 0.34),
		},
		{
			"Inner",
			CFrame.new(s * 0.062, -0.058, 0.207),
			-s * 10,
			CFrame.new(s * 0.035, -0.116, 0.365),
		},
	}
	for _, toe in toes do
		add({
			name = "Toe" .. toe[1] .. side,
			shape = CYL,
			size = Vector3.new(0.34, 0.09, 0.09),
			offset = toe[2] * ry(toe[3]) * rx(20) * CYLINDER_Z, -- rx(20) lowers the +Z end
			color = legOrange,
			material = M.Rubber,
		})
		add(ball("Nail" .. toe[1] .. side, 0.08, toe[4], nailBrown, 0.05))
	end
end

return WeaponModel.define({
	hold = "upright", -- held by the ankles, body up from the fist, belly toward the target
	handle = {
		size = Vector3.new(0.4, 0.4, 1.2),
		color = legOrange,
		material = M.Rubber,
		transparency = 1, -- the visible grip is the two leg shanks
	},
	pieces = pieces,
})
