-- Fallback models for weapons without a file in `weaponModels`, built from the catalog entry's
-- `shape` (SHAPES: one builder per shape the server can draw; tools/tests/data_integrity checks
-- WeaponCatalog's shapes against it). Loads under Lune: it requires only WeaponCatalog and
-- WeaponModel, which are require-free data.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WeaponCatalog = require(ReplicatedStorage.Shared.WeaponCatalog)
local WeaponModel = require(script.Parent.Parent.WeaponModel)

type Weapon = WeaponCatalog.Weapon

local FallbackModels = {}

local rgb = Color3.fromRGB
local M = Enum.Material
local GRIP = rgb(45, 40, 38)

type PieceSpec = WeaponModel.PieceSpec

local CYLINDER_Z = WeaponModel.CYLINDER_Z
local CYLINDER_Y = WeaponModel.CYLINDER_Y

-- Fallback pieces for weapons without a file in `weaponModels`, by shape, in handle space. The
-- hand holds the handle; local -Z points away from the wielder. Each builder takes the weapon,
-- its color, its glow material (Neon if `neon`, else Metal) and its length (default 3).
local SHAPES: { [string]: (Weapon, Color3, Enum.Material, number) -> { PieceSpec } } = {
	blade = function(_, c, glow, L)
		return {
			{
				size = Vector3.new(1.6, 0.3, 0.35),
				offset = CFrame.new(0, 0, -0.7),
				color = rgb(120, 100, 60),
				material = M.Metal,
			},
			{
				size = Vector3.new(0.18, 0.7, L),
				offset = CFrame.new(0, 0, -0.85 - L / 2),
				color = c,
				material = glow,
			},
			{
				size = Vector3.one * 0.5,
				offset = CFrame.new(0, 0, 0.75),
				color = rgb(120, 100, 60),
				material = M.Metal,
				shape = Enum.PartType.Ball,
			},
		}
	end,
	axe = function(_, c, glow, L)
		return {
			{
				size = Vector3.new(0.3, 0.3, L),
				offset = CFrame.new(0, 0, -L / 2 + 0.6),
				color = rgb(100, 70, 45),
				material = M.Wood,
			},
			{
				size = Vector3.new(0.25, 2, 1.6),
				offset = CFrame.new(0, 0.7, -L + 1),
				color = c,
				material = glow,
			},
		}
	end,
	hammer = function(_, c, glow, L)
		return {
			{
				size = Vector3.new(0.35, 0.35, L),
				offset = CFrame.new(0, 0, -L / 2 + 0.6),
				color = rgb(100, 70, 45),
				material = M.Wood,
			},
			{
				size = Vector3.new(1.6, 1.6, 2.6),
				offset = CFrame.new(0, 0, -L + 0.4) * CFrame.Angles(0, math.rad(90), 0),
				color = c,
				material = glow,
			},
		}
	end,
	spear = function(_, c, glow, L)
		return {
			{
				size = Vector3.new(0.25, 0.25, L),
				offset = CFrame.new(0, 0, -L / 2 + 1.5),
				color = rgb(110, 80, 50),
				material = M.Wood,
			},
			{
				size = Vector3.new(0.2, 0.7, 1.6),
				offset = CFrame.new(0, 0, -L + 0.7),
				color = c,
				material = glow,
			},
			{
				size = Vector3.new(1.4, 0.2, 0.2),
				offset = CFrame.new(0, 0, -L + 1.4),
				color = c,
				material = glow,
			},
		}
	end,
	scythe = function(_, _, _, L)
		return {
			{
				size = Vector3.new(0.3, 0.3, L),
				offset = CFrame.new(0, 0, -L / 2 + 1),
				color = rgb(60, 45, 35),
				material = M.Wood,
			},
			{
				size = Vector3.new(3.4, 0.8, 0.15),
				offset = CFrame.new(1.5, 0, -L + 1.2) * CFrame.Angles(0, 0, math.rad(-10)),
				color = rgb(200, 200, 210),
				material = M.Metal,
			},
		}
	end,
	pan = function(_, c, _, L)
		return {
			{
				size = Vector3.new(0.3, 0.3, L),
				offset = CFrame.new(0, 0, -L / 2 + 0.6),
				color = GRIP,
				material = M.Metal,
			},
			{
				size = Vector3.new(0.3, 3, 3),
				offset = CFrame.new(0, 0, -L - 0.6),
				color = c,
				material = M.Metal,
				shape = Enum.PartType.Cylinder,
			},
		}
	end,
	gun = function(weapon, c, glow, L)
		return {
			{
				size = Vector3.new(0.45, 0.55, L),
				offset = CFrame.new(0, 0.45, -L / 2 + 0.4),
				color = c,
				material = if weapon.neon then M.SmoothPlastic else M.Metal,
			},
			{
				size = Vector3.new(L * 0.4, 0.3, 0.3),
				offset = CFrame.new(0, 0.5, -L - 0.2 + L * 0.2) * CYLINDER_Z,
				color = rgb(40, 40, 45),
				material = M.Metal,
				shape = Enum.PartType.Cylinder,
			},
			{
				size = Vector3.new(0.5, 0.2, 0.5),
				offset = CFrame.new(0, 0.8, -L + 0.5),
				color = c,
				material = glow,
			},
		}
	end,
	tube = function(weapon, c, glow, L)
		return {
			{
				size = Vector3.new(L, 0.9, 0.9),
				offset = CFrame.new(0, 0.7, -L / 2 + 1) * CYLINDER_Z,
				color = c,
				material = if weapon.neon then M.SmoothPlastic else M.Metal,
				shape = Enum.PartType.Cylinder,
			},
			{
				size = Vector3.new(0.4, 1.1, 1.1),
				offset = CFrame.new(0, 0.7, -L + 1) * CYLINDER_Z,
				color = c,
				material = glow,
				shape = Enum.PartType.Cylinder,
			},
		}
	end,
	staff = function(_, c, glow, L)
		return {
			{
				size = Vector3.new(L, 0.35, 0.35),
				offset = CFrame.new(0, L / 2 - 1.5, 0) * CYLINDER_Y,
				color = rgb(90, 60, 40),
				material = M.Wood,
				shape = Enum.PartType.Cylinder,
			},
			{
				size = Vector3.one * 1.3,
				offset = CFrame.new(0, L - 1, 0),
				color = c,
				material = glow,
				shape = Enum.PartType.Ball,
			},
		}
	end,
	wand = function(_, c, glow, L)
		return {
			{
				size = Vector3.new(0.2, 0.2, L),
				offset = CFrame.new(0, 0, -L / 2 + 0.5),
				color = rgb(60, 40, 30),
				material = M.Wood,
			},
			{
				size = Vector3.one * 0.6,
				offset = CFrame.new(0, 0, -L + 0.4),
				color = c,
				material = glow,
				shape = Enum.PartType.Ball,
			},
		}
	end,
	orb = function(_, c, glow, _)
		return {
			{
				size = Vector3.one * 1.6,
				offset = CFrame.new(0, 0.4, -0.6),
				color = c,
				material = glow,
				shape = Enum.PartType.Ball,
			},
		}
	end,
	ball = function(_, c, _, L)
		return {
			{
				size = Vector3.one * L,
				offset = CFrame.new(0, 0.2, -0.4),
				color = c,
				material = M.SmoothPlastic,
				shape = Enum.PartType.Ball,
			},
		}
	end,
	chicken = function(_, c, _, _)
		return {
			{
				size = Vector3.new(0.9, 0.9, 2.4),
				offset = CFrame.new(0, 0, -1.6),
				color = c,
				material = M.SmoothPlastic,
			},
			{
				size = Vector3.one * 0.9,
				offset = CFrame.new(0, 0.5, -3),
				color = c,
				material = M.SmoothPlastic,
				shape = Enum.PartType.Ball,
			},
			{
				size = Vector3.new(0.2, 0.5, 0.6),
				offset = CFrame.new(0, 1.05, -3),
				color = rgb(220, 30, 30),
				material = M.SmoothPlastic,
			},
			{
				size = Vector3.new(0.3, 0.2, 0.5),
				offset = CFrame.new(0, 0.5, -3.6),
				color = rgb(255, 150, 30),
				material = M.SmoothPlastic,
			},
		}
	end,
	noodle = function(_, c, _, L)
		return {
			{
				size = Vector3.new(L, 0.8, 0.8),
				offset = CFrame.new(0, 0, -L / 2 + 0.6) * CYLINDER_Z,
				color = c,
				material = M.SmoothPlastic,
				shape = Enum.PartType.Cylinder,
			},
		}
	end,
	lollipop = function(_, c, _, L)
		return {
			{
				size = Vector3.new(0.25, 0.25, L),
				offset = CFrame.new(0, 0, -L / 2 + 0.6),
				color = rgb(250, 250, 250),
				material = M.SmoothPlastic,
			},
			{
				size = Vector3.new(0.5, 3.2, 3.2),
				offset = CFrame.new(0, 0, -L - 1),
				color = c,
				material = M.SmoothPlastic,
				shape = Enum.PartType.Cylinder,
			},
			{
				size = Vector3.new(0.55, 1.6, 1.6),
				offset = CFrame.new(0, 0, -L - 1),
				color = rgb(255, 255, 255),
				material = M.SmoothPlastic,
				shape = Enum.PartType.Cylinder,
			},
		}
	end,
}

-- The fallback pieces for `weapon`; none for a shape without a builder.
local function pieces(weapon: Weapon): { PieceSpec }
	local c = weapon.color
	local glow = if weapon.neon then M.Neon else M.Metal
	local L = weapon.length or 3
	local build = SHAPES[weapon.shape]
	if build then
		return build(weapon, c, glow, L)
	end
	return {}
end

FallbackModels.GRIP = GRIP
FallbackModels.SHAPES = SHAPES
FallbackModels.pieces = pieces

return FallbackModels
