-- Cartoon Bomb: mid-1800s spherical cast-iron mortar shell with brass fuse adapter and waxed-cotton safety fuse.

local WeaponModel = require(script.Parent.Parent.systems.WeaponModel)

local rgb = Color3.fromRGB
local M = Enum.Material
local CYLINDER_Y = WeaponModel.CYLINDER_Y
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball
local rad = math.rad

local CAST_IRON = rgb(32, 32, 36)
local SEAM_IRON = rgb(22, 22, 25)
local RUST = rgb(92, 54, 34)
local BARE_IRON = rgb(104, 102, 98)
local BRASS = rgb(150, 118, 62)
local BRASS_WORN = rgb(118, 90, 48)
local PITCH = rgb(28, 22, 16)
local VOID = rgb(10, 10, 10)
local FUSE_CORD = rgb(196, 176, 132)
local FUSE_CHAR = rgb(42, 35, 28)
local EMBER = rgb(255, 120, 30)
local EMBER_GLOW = rgb(255, 170, 70)

-- Shell center and fuse axis frame (local +Y = fuse axis, tilted 30 degrees toward -Z).
local C = CFrame.new(0, 0.2, -0.4)
local F = C * CFrame.Angles(rad(-30), 0, 0)

-- Point on or inside the shell along direction Rx(ax) * Rz(az) * up, at radius r.
local function onShell(ax: number, az: number, r: number): CFrame
	return C * CFrame.Angles(rad(ax), 0, 0) * CFrame.Angles(0, 0, rad(az)) * CFrame.new(0, r, 0)
end

-- Fuse chain: each segment bends further back about local X.
local function seg(joint: CFrame, bend: number): CFrame
	return joint * CFrame.Angles(rad(bend), 0, 0)
end

local SEG_LEN = CFrame.new(0, 0.14, 0)
local SEG_MID = CFrame.new(0, 0.07, 0)
local G = F * CFrame.new(0, 0.99, 0) -- fuse root, top of the pitch seal
local S1 = seg(G, 0)
local J1 = S1 * SEG_LEN
local S2 = seg(J1, 14)
local J2 = S2 * SEG_LEN
local S3 = seg(J2, 16)
local J3 = S3 * SEG_LEN
local S4 = seg(J3, 18)
local J4 = S4 * SEG_LEN
local S5 = seg(J4, 20)
local J5 = S5 * SEG_LEN -- fuse cord end

local LUG_R = F * CFrame.Angles(0, 0, rad(-35))
local LUG_L = F * CFrame.Angles(0, 0, rad(35))

local RUST_SIZE = Vector3.new(1, 1, 1)
local WEAR_SIZE = Vector3.new(0.6, 0.6, 0.6)
local LUG_SIZE = Vector3.new(0.06, 0.16, 0.16)
local LUG_HOLE_SIZE = Vector3.new(0.08, 0.07, 0.07)
local SCREW_SIZE = Vector3.new(0.06, 0.06, 0.06)
local CORD_SIZE = Vector3.new(0.15, 0.08, 0.08)
local KNUCKLE_SIZE = Vector3.new(0.082, 0.082, 0.082)

return WeaponModel.define({
	handle = {
		size = Vector3.new(0.4, 0.4, 0.4),
		color = CAST_IRON,
		material = M.Metal,
		transparency = 1,
	},
	pieces = {
		-- Shell
		{
			name = "Shell",
			shape = BALL,
			size = Vector3.new(1.5, 1.5, 1.5),
			offset = C,
			color = CAST_IRON,
			material = M.Metal,
		},
		{
			name = "MoldSeam",
			shape = CYL,
			size = Vector3.new(0.02, 1.53, 1.53),
			offset = F,
			color = SEAM_IRON,
			material = M.CorrodedMetal,
		},
		{
			name = "Rust1",
			shape = BALL,
			size = RUST_SIZE,
			offset = onShell(-100, 15, 0.26),
			color = RUST,
			material = M.CorrodedMetal,
		},
		{
			name = "Rust2",
			shape = BALL,
			size = RUST_SIZE,
			offset = onShell(60, -70, 0.26),
			color = RUST,
			material = M.CorrodedMetal,
		},
		{
			name = "Rust3",
			shape = BALL,
			size = RUST_SIZE,
			offset = onShell(-150, 50, 0.26),
			color = RUST,
			material = M.CorrodedMetal,
		},
		{
			name = "Wear1",
			shape = BALL,
			size = WEAR_SIZE,
			offset = onShell(-55, -40, 0.458),
			color = BARE_IRON,
			material = M.Metal,
		},
		{
			name = "Wear2",
			shape = BALL,
			size = WEAR_SIZE,
			offset = onShell(-80, 60, 0.458),
			color = BARE_IRON,
			material = M.Metal,
		},
		{
			name = "Wear3",
			shape = BALL,
			size = WEAR_SIZE,
			offset = onShell(120, 30, 0.458),
			color = BARE_IRON,
			material = M.Metal,
		},

		-- Lifting lugs
		{
			name = "LugR",
			shape = CYL,
			size = LUG_SIZE,
			offset = LUG_R * CFrame.new(0, 0.77, 0),
			color = CAST_IRON,
			material = M.Metal,
		},
		{
			name = "LugRHole",
			shape = CYL,
			size = LUG_HOLE_SIZE,
			offset = LUG_R * CFrame.new(0, 0.79, 0),
			color = VOID,
			material = M.SmoothPlastic,
		},
		{
			name = "LugL",
			shape = CYL,
			size = LUG_SIZE,
			offset = LUG_L * CFrame.new(0, 0.77, 0),
			color = CAST_IRON,
			material = M.Metal,
		},
		{
			name = "LugLHole",
			shape = CYL,
			size = LUG_HOLE_SIZE,
			offset = LUG_L * CFrame.new(0, 0.79, 0),
			color = VOID,
			material = M.SmoothPlastic,
		},

		-- Brass fuse adapter
		{
			name = "CollarFlange",
			shape = CYL,
			size = Vector3.new(0.06, 0.5, 0.5),
			offset = F * CFrame.new(0, 0.73, 0) * CYLINDER_Y,
			color = BRASS,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "FlangeScrew1",
			shape = BALL,
			size = SCREW_SIZE,
			offset = F * CFrame.new(0.14, 0.76, 0.14),
			color = BRASS_WORN,
			material = M.Metal,
		},
		{
			name = "FlangeScrew2",
			shape = BALL,
			size = SCREW_SIZE,
			offset = F * CFrame.new(-0.14, 0.76, 0.14),
			color = BRASS_WORN,
			material = M.Metal,
		},
		{
			name = "FlangeScrew3",
			shape = BALL,
			size = SCREW_SIZE,
			offset = F * CFrame.new(0.14, 0.76, -0.14),
			color = BRASS_WORN,
			material = M.Metal,
		},
		{
			name = "FlangeScrew4",
			shape = BALL,
			size = SCREW_SIZE,
			offset = F * CFrame.new(-0.14, 0.76, -0.14),
			color = BRASS_WORN,
			material = M.Metal,
		},
		{
			name = "CollarNeck",
			shape = CYL,
			size = Vector3.new(0.22, 0.36, 0.36),
			offset = F * CFrame.new(0, 0.86, 0) * CYLINDER_Y,
			color = BRASS,
			material = M.Metal,
			reflectance = 0.05,
		},
		{
			name = "NeckLip",
			shape = CYL,
			size = Vector3.new(0.05, 0.42, 0.42),
			offset = F * CFrame.new(0, 0.95, 0) * CYLINDER_Y,
			color = BRASS_WORN,
			material = M.Metal,
		},
		{
			name = "PitchSeal",
			shape = CYL,
			size = Vector3.new(0.02, 0.26, 0.26),
			offset = F * CFrame.new(0, 0.98, 0) * CYLINDER_Y,
			color = PITCH,
			material = M.Plastic,
		},
		{
			name = "FuseFerrule",
			shape = CYL,
			size = Vector3.new(0.08, 0.11, 0.11),
			offset = F * CFrame.new(0, 1.01, 0) * CYLINDER_Y,
			color = BRASS_WORN,
			material = M.Metal,
		},

		-- Fuse cord
		{
			name = "Fuse1",
			shape = CYL,
			size = CORD_SIZE,
			offset = S1 * SEG_MID * CYLINDER_Y,
			color = FUSE_CORD,
			material = M.Fabric,
		},
		{
			name = "Fuse2",
			shape = CYL,
			size = CORD_SIZE,
			offset = S2 * SEG_MID * CYLINDER_Y,
			color = FUSE_CORD,
			material = M.Fabric,
		},
		{
			name = "Fuse3",
			shape = CYL,
			size = CORD_SIZE,
			offset = S3 * SEG_MID * CYLINDER_Y,
			color = FUSE_CORD,
			material = M.Fabric,
		},
		{
			name = "Fuse4",
			shape = CYL,
			size = CORD_SIZE,
			offset = S4 * SEG_MID * CYLINDER_Y,
			color = FUSE_CORD,
			material = M.Fabric,
		},
		{
			name = "Fuse5",
			shape = CYL,
			size = Vector3.new(0.15, 0.078, 0.078),
			offset = S5 * SEG_MID * CYLINDER_Y,
			color = FUSE_CORD,
			material = M.Fabric,
		},
		{
			name = "FuseKnuckle1",
			shape = BALL,
			size = KNUCKLE_SIZE,
			offset = J1,
			color = FUSE_CORD,
			material = M.Fabric,
		},
		{
			name = "FuseKnuckle2",
			shape = BALL,
			size = KNUCKLE_SIZE,
			offset = J2,
			color = FUSE_CORD,
			material = M.Fabric,
		},
		{
			name = "FuseKnuckle3",
			shape = BALL,
			size = KNUCKLE_SIZE,
			offset = J3,
			color = FUSE_CORD,
			material = M.Fabric,
		},
		{
			name = "FuseKnuckle4",
			shape = BALL,
			size = Vector3.new(0.08, 0.08, 0.08),
			offset = J4,
			color = FUSE_CORD,
			material = M.Fabric,
		},

		-- Burning tip
		{
			name = "FuseChar",
			shape = CYL,
			size = Vector3.new(0.07, 0.084, 0.084),
			offset = J5 * CFrame.new(0, -0.025, 0) * CYLINDER_Y,
			color = FUSE_CHAR,
			material = M.Fabric,
		},
		{
			name = "Ember",
			shape = BALL,
			size = Vector3.new(0.07, 0.07, 0.07),
			offset = J5 * CFrame.new(0, 0.02, 0),
			color = EMBER,
			material = M.Neon,
		},
		{
			name = "EmberGlow",
			shape = BALL,
			size = Vector3.new(0.14, 0.14, 0.14),
			offset = J5 * CFrame.new(0, 0.03, 0),
			color = EMBER_GLOW,
			material = M.Neon,
			transparency = 0.6,
		},
	},
})
