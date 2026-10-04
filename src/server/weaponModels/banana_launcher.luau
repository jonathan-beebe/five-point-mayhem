-- Banana Launcher: backyard pneumatic spud gun in yellow-painted Schedule-40 PVC with a brass ball-valve trigger, loaded with a real Cavendish banana.

local WeaponModel = require(script.Parent.Parent.systems.WeaponModel)

local rgb = Color3.fromRGB
local M = Enum.Material
local CYLINDER_Z = WeaponModel.CYLINDER_Z
local CYLINDER_Y = WeaponModel.CYLINDER_Y
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball
local R = math.rad

local pvcYellow = rgb(255, 230, 50)
local fittingYellow = rgb(232, 200, 40)
local primer = rgb(110, 50, 140)
local ink = rgb(50, 50, 80)
local bore = rgb(20, 20, 20)
local brass = rgb(180, 140, 65)
local steel = rgb(175, 175, 180)
local chrome = rgb(200, 200, 205)
local leverRed = rgb(175, 25, 25)
local rubberBlack = rgb(25, 25, 25)
local frictionTape = rgb(30, 30, 30)
local ductTape = rgb(165, 165, 165)
local dialWhite = rgb(240, 240, 235)
local needleBlack = rgb(15, 15, 15)
local dialRed = rgb(200, 30, 30)
local glass = rgb(220, 235, 240)
local bananaPeel = rgb(240, 205, 75)
local bananaNeck = rgb(205, 200, 80)
local bananaStem = rgb(120, 110, 50)
local bananaTip = rgb(60, 45, 30)
local bananaSpot = rgb(90, 60, 30)

-- Bore axis height.
local BY = 0.7

-- Lever frame: tilted 4 degrees nose-down over the barrel.
local LEVER = CFrame.new(0, 1.08, -1.14) * CFrame.Angles(R(-4), 0, 0)

-- Cylinder piece. `len` runs along the cylinder axis, `dia` is its diameter.
local function cyl(
	name: string,
	len: number,
	dia: number,
	offset: CFrame,
	color: Color3,
	material: Enum.Material,
	reflectance: number?
)
	return {
		name = name,
		shape = CYL,
		size = Vector3.new(len, dia, dia),
		offset = offset,
		color = color,
		material = material,
		reflectance = reflectance,
	}
end

-- Pipe-axis cylinder centered on the bore at z.
local function bz(
	name: string,
	len: number,
	dia: number,
	z: number,
	color: Color3,
	material: Enum.Material,
	refl: number?
)
	return cyl(name, len, dia, CFrame.new(0, BY, z) * CYLINDER_Z, color, material, refl)
end

-- One of three crossed blocks forming a hex nut shoulder around the bore.
local function hex(name: string, z: number, len: number, angle: number)
	return {
		name = name,
		size = Vector3.new(0.3, 0.52, len),
		offset = CFrame.new(0, BY, z) * CFrame.Angles(0, 0, R(angle)),
		color = brass,
		material = M.Metal,
		reflectance = 0.1,
	}
end

return WeaponModel.define({
	handle = { size = Vector3.new(0.3, 0.6, 0.3), transparency = 1 },
	muzzle = CFrame.new(0, BY, -2.1),
	pieces = {
		-- Rear cap and Schrader valve
		bz("SchraderCap", 0.07, 0.11, 0.815, rubberBlack, M.Rubber),
		bz("SchraderStem", 0.14, 0.09, 0.72, brass, M.Metal, 0.1),
		bz("SchraderNut", 0.04, 0.17, 0.67, brass, M.Metal, 0.1),
		bz("RearCapFace", 0.05, 0.72, 0.635, fittingYellow, M.Plastic),
		bz("RearCap", 0.16, 0.88, 0.54, fittingYellow, M.Plastic),

		-- Pressure chamber, 3"
		bz("Chamber", 0.65, 0.8, 0.155, pvcYellow, M.Plastic),
		bz("ChamberPrimerRear", 0.07, 0.82, 0.415, primer, M.SmoothPlastic),
		bz("ChamberPrimerFront", 0.07, 0.82, -0.105, primer, M.SmoothPlastic),
		bz("ChamberTape", 0.26, 0.83, 0.1, ductTape, M.Fabric),
		{
			name = "ChamberPrint",
			size = Vector3.new(0.01, 0.035, 0.13),
			offset = CFrame.new(0.403, BY, 0.305),
			color = ink,
			material = M.SmoothPlastic,
		},

		-- Reducer bushing, 3" to 1"
		bz("Reducer", 0.18, 0.88, -0.24, fittingYellow, M.Plastic),
		bz("ReducerStep1", 0.1, 0.66, -0.38, fittingYellow, M.Plastic),
		bz("ReducerStep2", 0.06, 0.5, -0.46, fittingYellow, M.Plastic),

		-- Brass ball valve (trigger)
		bz("ValveNippleRear", 0.1, 0.34, -0.53, brass, M.Metal, 0.1),
		hex("ValveHexRearA", -0.61, 0.08, 0),
		hex("ValveHexRearB", -0.61, 0.1, 60),
		hex("ValveHexRearC", -0.61, 0.12, 120),
		bz("ValveBody", 0.28, 0.5, -0.78, brass, M.Metal, 0.1),
		hex("ValveHexFrontA", -0.95, 0.08, 0),
		hex("ValveHexFrontB", -0.95, 0.1, 60),
		hex("ValveHexFrontC", -0.95, 0.12, 120),
		bz("ValveNippleFront", 0.1, 0.34, -1.03, brass, M.Metal, 0.1),
		cyl(
			"ValvePackingNut",
			0.04,
			0.18,
			CFrame.new(0, 0.955, -0.78) * CYLINDER_Y,
			brass,
			M.Metal,
			0.1
		),
		cyl("ValveStem", 0.12, 0.12, CFrame.new(0, 1, -0.78) * CYLINDER_Y, steel, M.Metal, 0.15),
		{
			name = "LeverRoot",
			size = Vector3.new(0.14, 0.04, 0.24),
			offset = CFrame.new(0, 1.08, -0.78),
			color = steel,
			material = M.Metal,
			reflectance = 0.15,
		},
		{
			name = "LeverGrip",
			size = Vector3.new(0.16, 0.07, 0.52),
			offset = LEVER,
			color = leverRed,
			material = M.SmoothPlastic,
		},
		-- Axis left along X so the round side caps the lever tip.
		cyl("LeverEnd", 0.16, 0.07, LEVER * CFrame.new(0, 0, -0.26), leverRed, M.SmoothPlastic),
		cyl("LeverNut", 0.03, 0.12, CFrame.new(0, 1.115, -0.78) * CYLINDER_Y, steel, M.Metal, 0.15),

		-- Barrel, 2"
		bz("BarrelAdapter", 0.16, 0.62, -1.15, fittingYellow, M.Plastic),
		bz("BarrelPrimerRear", 0.07, 0.58, -1.275, primer, M.SmoothPlastic),
		bz("Barrel", 0.76, 0.56, -1.6, pvcYellow, M.Plastic),
		bz("BarrelTape", 0.12, 0.58, -1.5, ductTape, M.Fabric),
		{
			name = "BarrelPrint",
			size = Vector3.new(0.01, 0.025, 0.5),
			offset = CFrame.new(0.283, BY, -1.56),
			color = ink,
			material = M.SmoothPlastic,
		},
		bz("BarrelPrimerFront", 0.07, 0.58, -1.815, primer, M.SmoothPlastic),
		bz("MuzzleCoupler", 0.14, 0.64, -1.93, fittingYellow, M.Plastic),
		bz("MuzzleBore", 0.02, 0.5, -2.005, bore, M.SmoothPlastic),

		-- Pistol grip, 1" PVC wrapped in friction tape
		cyl(
			"GripSocket",
			0.24,
			0.46,
			CFrame.new(0, 0.27, 0) * CYLINDER_Y,
			fittingYellow,
			M.Plastic
		),
		cyl("GripTape", 0.72, 0.4, CFrame.new(0, -0.2, 0) * CYLINDER_Y, frictionTape, M.Fabric),
		cyl(
			"GripWrap1",
			0.03,
			0.42,
			CFrame.new(0, -0.45, 0) * CFrame.Angles(R(10), 0, 0) * CYLINDER_Y,
			frictionTape,
			M.Fabric
		),
		cyl(
			"GripWrap2",
			0.03,
			0.42,
			CFrame.new(0, -0.21, 0) * CFrame.Angles(R(10), 0, 0) * CYLINDER_Y,
			frictionTape,
			M.Fabric
		),
		cyl(
			"GripWrap3",
			0.03,
			0.42,
			CFrame.new(0, 0.03, 0) * CFrame.Angles(R(10), 0, 0) * CYLINDER_Y,
			frictionTape,
			M.Fabric
		),
		cyl(
			"GripEndcap",
			0.12,
			0.46,
			CFrame.new(0, -0.6, 0) * CYLINDER_Y,
			fittingYellow,
			M.Plastic
		),
		cyl(
			"GripEndcapFace",
			0.03,
			0.38,
			CFrame.new(0, -0.67, 0) * CYLINDER_Y,
			fittingYellow,
			M.Plastic
		),

		-- Pressure gauge on top of the chamber, dial facing the wielder (+Z).
		-- Face stack steps 0.01 per layer: dial 0.255, red zone 0.265, needle 0.275, lens 0.30.
		cyl("GaugeBushing", 0.1, 0.14, CFrame.new(0, 1.12, 0.2) * CYLINDER_Y, brass, M.Metal, 0.1),
		cyl("GaugeCase", 0.1, 0.4, CFrame.new(0, 1.36, 0.2) * CYLINDER_Z, chrome, M.Metal, 0.3),
		cyl(
			"GaugeDial",
			0.01,
			0.34,
			CFrame.new(0, 1.36, 0.25) * CYLINDER_Z,
			dialWhite,
			M.SmoothPlastic
		),
		{
			name = "GaugeRedZone",
			size = Vector3.new(0.07, 0.02, 0.01),
			offset = CFrame.new(0.1, 1.43, 0.26) * CFrame.Angles(0, 0, R(-55)),
			color = dialRed,
			material = M.SmoothPlastic,
		},
		{
			name = "GaugeNeedle",
			size = Vector3.new(0.015, 0.13, 0.01),
			offset = CFrame.new(0.037, 1.413, 0.27) * CFrame.Angles(0, 0, R(-35)),
			color = needleBlack,
			material = M.SmoothPlastic,
		},
		cyl(
			"GaugePivot",
			0.02,
			0.035,
			CFrame.new(0, 1.36, 0.275) * CYLINDER_Z,
			needleBlack,
			M.SmoothPlastic
		),
		{
			name = "GaugeLens",
			shape = CYL,
			size = Vector3.new(0.055, 0.38, 0.38),
			offset = CFrame.new(0, 1.36, 0.2725) * CYLINDER_Z,
			color = glass,
			material = M.Glass,
			transparency = 0.7,
			reflectance = 0.2,
		},

		-- Banana, loaded stem-first, curving upward out of the bore
		bz("BananaBody", 0.16, 0.34, -2.02, bananaPeel, M.SmoothPlastic, 0.02),
		cyl(
			"BananaShoulder",
			0.08,
			0.28,
			CFrame.new(0, 0.71, -2.13) * CFrame.Angles(R(15), 0, 0) * CYLINDER_Z,
			bananaPeel,
			M.SmoothPlastic,
			0.02
		),
		cyl(
			"BananaNeck",
			0.08,
			0.2,
			CFrame.new(0, 0.73, -2.2) * CFrame.Angles(R(25), 0, 0) * CYLINDER_Z,
			bananaNeck,
			M.SmoothPlastic
		),
		cyl(
			"BananaStem",
			0.08,
			0.1,
			CFrame.new(0, 0.755, -2.26) * CFrame.Angles(R(32), 0, 0) * CYLINDER_Z,
			bananaStem,
			M.Wood
		),
		cyl(
			"BananaStemTip",
			0.02,
			0.11,
			CFrame.new(0, 0.7815, -2.302) * CFrame.Angles(R(32), 0, 0) * CYLINDER_Z,
			bananaTip,
			M.Wood
		),
		{
			name = "BananaSpot1",
			shape = BALL,
			size = Vector3.new(0.05, 0.05, 0.05),
			offset = CFrame.new(0.12, 0.815, -2.05),
			color = bananaSpot,
			material = M.SmoothPlastic,
		},
		{
			name = "BananaSpot2",
			shape = BALL,
			size = Vector3.new(0.05, 0.05, 0.05),
			offset = CFrame.new(-0.13, 0.6, -2.07),
			color = bananaSpot,
			material = M.SmoothPlastic,
		},
	},
})
