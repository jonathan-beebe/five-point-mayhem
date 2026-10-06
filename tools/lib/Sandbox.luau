-- Loads game source files under Lune, outside Roblox, for tests and tools.
--
-- Usage (from a file in tools/):
--   local Sandbox = require("./lib/Sandbox") -- "../lib/Sandbox" from tools/tests
--   local MechGait = Sandbox.load("src/shared/MechGait.luau")
--   for _, model in Sandbox.loadVehicleModels() do print(model.id, model.spec.name) end
--
-- A loaded file sees:
--   - Lune's Roblox datatypes (Vector3, Color3, Enum, ...) with CFrame swapped for `CFrame` below
--   - `Random`: a stand-in (Lune has none); deterministic when seeded, but not Roblox's sequence
--   - `script`: a proxy for the file's place in the tree. `script.Parent.X` is the folder's X;
--     `require(proxy)` loads <path>.luau or <path>/init.luau, sandboxed the same way, once
--   - `game:GetService(name)`: the services default.project.json maps (ReplicatedStorage.Shared
--     is src/shared, ServerScriptService.Server is src/server)
--
-- `load(path, extra)`: `extra` adds or overrides globals for that file only; modules it requires
-- get the plain sandbox.
--
-- `Sandbox.game` and `Sandbox.require` are the same `game` and `require` outside a loaded file, so
-- a tool can require a module by the instance path the game uses:
--   Sandbox.require(Sandbox.game:GetService("ReplicatedStorage").Shared.CreatureCatalog)
--
-- Relative paths resolve against the repository root, so tools run from any directory in it.

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")

local Sandbox = {}

-- The repository root: this file is <root>/tools/lib/Sandbox.luau.
local source = debug.info(1, "s")
Sandbox.ROOT = (string.gsub(source, "/tools/lib/Sandbox$", ""))
assert(
	Sandbox.ROOT ~= source,
	"Sandbox: expected to run from <root>/tools/lib/Sandbox.luau, not " .. source
)

-- The absolute path of `path` with `.` and `..` collapsed, so equal files give equal keys.
local function resolve(path: string): string
	if string.sub(path, 1, 1) ~= "/" then
		path = Sandbox.ROOT .. "/" .. path
	end
	local parts = {}
	for part in string.gmatch(path, "[^/]+") do
		if part == ".." then
			table.remove(parts)
		elseif part ~= "." then
			table.insert(parts, part)
		end
	end
	return "/" .. table.concat(parts, "/")
end

-- Lune's CFrame.lookAt (and CFrame.new(position, target)) disagree with Roblox; rebuild them from
-- fromMatrix the way Roblox defines them: -Z toward the target, +Y as close to `up` as possible.
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
Sandbox.CFrame = setmetatable({
	lookAt = lookAt,
	new = function(...)
		local a, b = ...
		if select("#", ...) == 2 and typeof(a) == "Vector3" and typeof(b) == "Vector3" then
			return lookAt(a, b)
		end
		return RobloxCFrame.new(...)
	end,
}, { __index = RobloxCFrame })

-- Park-Miller generator behind Random.new(seed): NextNumber and NextInteger.
local MODULUS = 2147483647
local Random = {}
Random.__index = Random
function Random.new(seed: number?)
	local state = math.floor(math.abs(seed or os.clock() * 1e6)) % (MODULUS - 1) + 1
	return setmetatable({ state = state }, Random)
end
function Random:NextNumber(min: number?, max: number?): number
	self.state = self.state * 48271 % MODULUS
	local unit = (self.state - 1) / (MODULUS - 1)
	local low, high = min or 0, max or 1
	return low + (high - low) * unit
end
function Random:NextInteger(min: number, max: number): number
	return math.min(math.floor(self:NextNumber(min, max + 1)), max)
end

local DATATYPES = {
	"Axes",
	"BrickColor",
	"Color3",
	"ColorSequence",
	"ColorSequenceKeypoint",
	"Enum",
	"Faces",
	"Font",
	"NumberRange",
	"NumberSequence",
	"NumberSequenceKeypoint",
	"PhysicalProperties",
	"Ray",
	"Rect",
	"Region3",
	"UDim",
	"UDim2",
	"Vector2",
	"Vector3",
	"Vector3int16",
}

-- Instance paths (folders, without .luau) for the services default.project.json maps.
local SERVICES = {
	ReplicatedStorage = { Shared = "src/shared" },
	ServerScriptService = { Server = "src/server" },
}

local cache: { [string]: any } = {}
local load: (string, { [string]: any }?) -> any

-- A stand-in for the Instance at `path`: indexing names a child, Parent the folder above.
local function proxy(path: string): any
	return setmetatable({}, {
		__index = function(_, key)
			if key == "Parent" then
				local parent = string.match(path, "^(.*)/[^/]+$")
				assert(
					parent and parent ~= "",
					"script.Parent: " .. path .. " has no parent folder"
				)
				return proxy(parent)
			elseif key == "Name" then
				return string.match(path, "([^/]+)$")
			end
			return proxy(path .. "/" .. key)
		end,
		__tostring = function()
			return path
		end,
		path = path,
	})
end

-- Loads the module a proxy (or an instance path such as "src/server/systems/WeaponModel") names.
function Sandbox.require(target: any): any
	local meta = type(target) == "table" and getmetatable(target)
	local path = if type(target) == "string" then target elseif meta then meta.path else nil
	assert(
		type(path) == "string",
		"Sandbox.require: expected a script proxy or an instance path, got " .. typeof(target)
	)
	local file = path .. ".luau"
	if not fs.isFile(resolve(file)) then
		file = path .. "/init.luau"
		if not fs.isFile(resolve(file)) then
			error(("Sandbox.require: no %s.luau or %s/init.luau"):format(path, path), 2)
		end
	end
	local key = resolve(file)
	if cache[key] == nil then
		cache[key] = load(file)
	end
	return cache[key]
end

local game = {
	GetService = function(_, name: string)
		local children = assert(SERVICES[name], "game:GetService: no mapping for " .. name)
		return setmetatable({}, {
			__index = function(_, key)
				return proxy(assert(children[key], name .. "." .. key .. " is not mapped"))
			end,
		})
	end,
}
Sandbox.game = game

-- Runs the file at `path` in the sandbox and returns what it returns. `extra` adds or overrides
-- globals.
function load(path: string, extra: { [string]: any }?): any
	local environment: { [string]: any } = {
		CFrame = Sandbox.CFrame,
		Random = Random,
		game = game,
		require = Sandbox.require,
		script = proxy((string.gsub(string.gsub(path, "%.luau$", ""), "/init$", ""))),
	}
	for _, name in DATATYPES do
		environment[name] = (roblox :: any)[name]
	end
	for key, value in extra or {} do
		environment[key] = value
	end
	local file = resolve(path)
	assert(fs.isFile(file), "Sandbox.load: no file at " .. file)
	return luau.load(fs.readFile(file), { debugName = path, environment = environment })()
end
Sandbox.load = load

export type Loaded = { id: string, path: string, spec: any }

-- Loads every model file in `folder`, sorted by id (the file name).
local function loadFolder(folder: string): { Loaded }
	local list = {}
	for _, file in fs.readDir(resolve(folder)) do
		local id = string.match(file, "^(.+)%.luau$")
		if id then
			local path = folder .. "/" .. file
			table.insert(list, { id = id, path = path, spec = load(path) })
		end
	end
	table.sort(list, function(a, b)
		return a.id < b.id
	end)
	return list
end

function Sandbox.loadVehicleModels(): { Loaded }
	return loadFolder("src/server/vehicleModels")
end

function Sandbox.loadWeaponModels(): { Loaded }
	return loadFolder("src/server/weaponModels")
end

function Sandbox.loadCreatureModels(): { Loaded }
	return loadFolder("src/server/creatureModels")
end

return Sandbox
