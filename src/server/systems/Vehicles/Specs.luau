-- Vehicle specs by catalog id: each model file in `src/server/vehicleModels` through
-- VehicleModel.define, cached. A missing or broken file becomes a grey placeholder (warned).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VehicleCatalog = require(ReplicatedStorage.Shared.VehicleCatalog)
local VehicleModel = require(script.Parent.Parent.VehicleModel)

local Specs = {}

local rgb = Color3.fromRGB
local M = Enum.Material

local modelFiles = script.Parent.Parent.Parent:FindFirstChild("vehicleModels")

-- Stands in for a vehicle whose model file is missing or broken.
local function placeholder(name: string): VehicleModel.Model
	return VehicleModel.define({
		name = name,
		speed = 80,
		footprint = Vector2.new(8, 16),
		seats = { CFrame.new(-1.5, 1.5, 0) },
		pieces = {
			{
				size = Vector3.new(8, 2.5, 16),
				offset = CFrame.new(0, 2.25, 0),
				color = rgb(120, 120, 125),
				material = M.Metal,
			},
		},
	})
end

local specs: { [string]: VehicleModel.Model } = {}

local function specFor(id: string): VehicleModel.Model
	local cached = specs[id]
	if cached then
		return cached
	end
	local entry = VehicleCatalog.get(id)
	local name = if entry then entry.name else id
	local file = modelFiles and modelFiles:FindFirstChild(id)
	local spec
	if file then
		local ok, result = pcall(function()
			return VehicleModel.define(require(file :: ModuleScript) :: any)
		end)
		if ok then
			spec = result
		else
			warn("[Mayhem vehicle] " .. id .. ": " .. tostring(result))
		end
	end
	spec = spec or placeholder(name)
	specs[id] = spec
	return spec
end

Specs.specFor = specFor

return Specs
