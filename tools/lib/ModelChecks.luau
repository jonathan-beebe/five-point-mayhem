-- Checks a vehicle, weapon or creature model file's table beyond what the game's own define()
-- asserts: what tools/preview can render, piece limits, and placement rules. Used by
-- tools/preview/export.luau (it reports the problems with the render) and
-- tools/tests/data_integrity.luau (it fails on any).
--
-- Usage:
--   local ModelChecks = require("./lib/ModelChecks") -- "../lib/ModelChecks" from tools/tests
--   local problems, defined = ModelChecks.check(spec, "vehicle") -- or "weapon", "creature"
--
-- `problems` lists piece problems first, then the kind's. For a vehicle or creature, `defined` is
-- define() run on a copy of `spec` (it fills defaults in place), or nil when define() fails; its
-- error is one of the problems. Weapon files call define() themselves, so `defined` is nil.

local Sandbox = require("./Sandbox")

local SYSTEMS = "src/server/systems/"

local ModelChecks = {}

export type Kind = "vehicle" | "weapon" | "creature"

-- Whether a piece has the types tools/preview needs to draw it.
function ModelChecks.renderable(piece: any): boolean
	return typeof(piece.size) == "Vector3"
		and typeof(piece.offset) == "CFrame"
		and typeof(piece.color) == "Color3"
end

local function checkPiece(piece: any, label: string, problem: (string) -> ())
	if typeof(piece.size) ~= "Vector3" or typeof(piece.offset) ~= "CFrame" then
		problem(label .. ": size must be a Vector3 and offset a CFrame")
		return
	end
	if typeof(piece.color) ~= "Color3" then
		problem(label .. ": color must be a Color3")
		return
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
end

-- Runs a model module's define() on a copy of `spec`. Returns the defined copy, or nil and the
-- error without its "file:line: " prefix.
local function define(module: string, spec: any): (any?, string?)
	local ok, result = pcall(Sandbox.require(SYSTEMS .. module).define, table.clone(spec))
	if ok then
		return result, nil
	end
	return nil, (string.gsub(tostring(result), "^.-:%d+: ", ""))
end

-- Height of the lowest point of any renderable piece, in creature space.
local function lowestPoint(pieces: { any }): number
	local lowest = math.huge
	for _, piece in pieces do
		if ModelChecks.renderable(piece) then
			-- Lowest point of the piece's box: |R1j| * size_j / 2 summed over its axes (c[7..9] is row Y).
			local c = { piece.offset:GetComponents() }
			local size = { piece.size.X, piece.size.Y, piece.size.Z }
			local half = 0
			for column = 0, 2 do
				half += math.abs(c[7 + column]) * size[column + 1] / 2
			end
			lowest = math.min(lowest, c[2] - half)
		end
	end
	return lowest
end

function ModelChecks.check(spec: any, kind: Kind): ({ string }, any?)
	local problems = {}
	local function problem(text: string)
		table.insert(problems, text)
	end

	for index, piece in spec.pieces do
		checkPiece(piece, piece.name or ("piece " .. index), problem)
	end

	if kind == "weapon" then
		if #spec.pieces > 80 then
			problem(#spec.pieces .. " pieces; the limit is 80")
		end
		return problems, nil
	end

	if kind == "creature" then
		local defined, err = define("CreatureModel", spec)
		if err then
			problem(err)
		end
		local lowest = lowestPoint(spec.pieces)
		if lowest > 0.15 then
			problem(string.format("lowest piece is %.2f studs above the ground", lowest))
		elseif lowest < -0.5 then
			problem(string.format("a piece sinks %.2f studs below the ground", -lowest))
		end
		return problems, defined
	end

	-- The game's own checks (bones, seatBone, ladders, prompt).
	local defined, err = define("VehicleModel", spec)
	if err then
		problem(err)
	end
	for _, box in spec.collision or {} do
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
	if #(spec.seats or {}) == 0 then
		problem("needs at least one seat (the driver)")
	end
	return problems, defined
end

return ModelChecks
