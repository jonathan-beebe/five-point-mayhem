-- Loads a vehicle or weapon model file outside Roblox and prints its parts as JSON for render.py.
-- Usage: lune run tools/preview/export.luau <path/to/model.luau> [--weapon]
-- Files under a `weaponModels` folder are weapons without the flag.

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")

local path = process.args[1]
assert(path, "usage: lune run tools/preview/export.luau <model.luau> [--weapon]")
local isWeapon = process.args[2] == "--weapon" or string.find(path, "weaponModels", 1, true) ~= nil

-- Lune's CFrame.lookAt (and CFrame.new(position, target)) disagree with Roblox; rebuild them
-- from fromMatrix the way Roblox defines them: -Z toward the target, +Y as close to `up` as possible.
local RobloxCFrame = roblox.CFrame
local function lookAt(at, target, up)
	up = up or roblox.Vector3.yAxis
	local look = (target - at).Unit
	local right = look:Cross(up)
	if right.Magnitude < 1e-6 then
		right = look:Cross(roblox.Vector3.zAxis)
	end
	right = right.Unit
	return RobloxCFrame.fromMatrix(at, right, right:Cross(look), -look)
end
local CFrameShim = setmetatable({
	lookAt = lookAt,
	new = function(...)
		local a, b = ...
		if select("#", ...) == 2 and typeof(a) == "Vector3" and typeof(b) == "Vector3" then
			return lookAt(a, b)
		end
		return RobloxCFrame.new(...)
	end,
}, { __index = RobloxCFrame })

local function load(file: string, extra: { [string]: any }?)
	local environment = {
		CFrame = CFrameShim,
		Vector3 = roblox.Vector3,
		Vector2 = roblox.Vector2,
		Color3 = roblox.Color3,
		Enum = roblox.Enum,
	}
	for key, value in extra or {} do
		environment[key] = value
	end
	return luau.load(fs.readFile(file), { debugName = file, environment = environment })()
end

-- Weapon files call require(script.Parent.Parent.systems.WeaponModel). `script` is a proxy whose
-- leaf names the real module; `require` loads it (sandboxed the same way) from src/server/systems.
local SYSTEMS = "src/server/systems/"
local modules = {}
local function requireShim(target)
	local name = assert(rawget(target, "name"), "require: unsupported target")
	if not modules[name] then
		modules[name] = load(SYSTEMS .. name .. ".luau")
	end
	return modules[name]
end
local function proxy(name: string?)
	return setmetatable({ name = name }, {
		__index = function(_, key)
			if key == "Parent" then
				return proxy(nil)
			end
			return proxy(key)
		end,
	})
end

local spec = if isWeapon
	then load(path, { script = proxy(nil), require = requireShim })
	else load(path)

local function frame(cf): { number }
	return { cf:GetComponents() }
end

local function vector(v): { number }
	return { v.X, v.Y, v.Z }
end

local problems = {}
local function problem(text: string)
	table.insert(problems, text)
end

local parts = {}
-- Weapons render in the wielder's frame (RightGripAttachment, -Z forward along the arm, +Y up):
-- the handle sits at Grip:Inverse(), as Roblox places a tool's handle.
local hold = RobloxCFrame.new()
if isWeapon then
	local WeaponModel = requireShim({ name = "WeaponModel" })
	hold = WeaponModel.grip(spec):Inverse()
	local handle = spec.handle or {}
	local handleSize = handle.size or roblox.Vector3.new(0.4, 0.4, 1.2)
	local handleColor = handle.color or roblox.Color3.fromRGB(45, 40, 38)
	table.insert(parts, {
		name = "Handle",
		class = "Part",
		shape = "Block",
		size = { handleSize.X, handleSize.Y, handleSize.Z },
		cframe = { hold:GetComponents() },
		color = { handleColor.R, handleColor.G, handleColor.B },
		material = if handle.material then handle.material.Name else "SmoothPlastic",
		transparency = handle.transparency or 0,
	})
end
for index, piece in spec.pieces do
	local label = piece.name or ("piece " .. index)
	if typeof(piece.size) ~= "Vector3" or typeof(piece.offset) ~= "CFrame" then
		problem(label .. ": size must be a Vector3 and offset a CFrame")
		continue
	end
	if typeof(piece.color) ~= "Color3" then
		problem(label .. ": color must be a Color3")
		continue
	end
	local class = piece.class or "Part"
	if class ~= "Part" and class ~= "WedgePart" then
		problem(label .. ": class " .. class .. " is not rendered (Part or WedgePart only)")
	end
	local size = piece.size
	if size.X <= 0 or size.Y <= 0 or size.Z <= 0 then
		problem(label .. ": every size component must be positive")
	end
	local shape = if piece.shape then piece.shape.Name else "Block"
	if class == "WedgePart" and piece.shape then
		problem(label .. ": a WedgePart takes no shape")
	end
	if shape == "Cylinder" and math.abs(size.Y - size.Z) > 0.001 then
		problem(label .. ": a cylinder's Y and Z sizes must match (Roblox uses the smaller)")
	end
	table.insert(parts, {
		name = label,
		class = class,
		shape = shape,
		size = vector(size),
		cframe = frame(hold * piece.offset),
		color = { piece.color.R, piece.color.G, piece.color.B },
		material = if piece.material then piece.material.Name else "SmoothPlastic",
		transparency = piece.transparency or 0,
	})
end

if isWeapon then
	if #spec.pieces > 80 then
		problem(#spec.pieces .. " pieces; the limit is 80")
	end
	local muzzle = if spec.muzzle then hold * spec.muzzle else nil
	print(serde.encode("json", {
		kind = "weapon",
		name = string.match(path, "([^/]+)%.luau$"),
		hold = spec.hold or "forward",
		parts = parts,
		muzzle = if muzzle then vector(muzzle.Position) else nil,
		problems = problems,
	}))
	return
end

local seats = {}
for _, seat in spec.seats or {} do
	table.insert(seats, frame(seat))
end

local collision = {}
for _, box in spec.collision or {} do
	table.insert(collision, { size = vector(box.size), cframe = frame(box.offset) })
	if box.offset.Position.Y - box.size.Y / 2 < 1 then
		problem("collision box bottom below y = 1 drags on the ground")
	end
end

if #spec.pieces > 320 then
	problem(#spec.pieces .. " pieces; the limit is 320")
end
if typeof(spec.footprint) ~= "Vector2" then
	problem("footprint must be a Vector2")
end
if #seats == 0 then
	problem("needs at least one seat (the driver)")
end

print(serde.encode("json", {
	name = spec.name,
	speed = spec.speed,
	turnRate = spec.turnRate,
	footprint = if typeof(spec.footprint) == "Vector2"
		then { spec.footprint.X, spec.footprint.Y }
		else nil,
	parts = parts,
	seats = seats,
	collision = collision,
	problems = problems,
}))
