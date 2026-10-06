-- Loads a vehicle, weapon or creature model file outside Roblox and prints its parts as JSON for
-- render.py.
-- Usage: lune run tools/preview/export.luau <path/to/model.luau> [--weapon]
-- Files under a `weaponModels` folder are weapons without the flag; files under a
-- `creatureModels` folder are creatures.
-- A vehicle with `bones` exports in its rest pose: each piece and seat on a bone follows that bone.
-- A walker exports mid-stride with `--phase <0..1> [--speed <studs/s>]` (see below).

local process = require("@lune/process")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")

local ModelChecks = require("../lib/ModelChecks")
local Sandbox = require("../lib/Sandbox")

local path = process.args[1]
assert(path, "usage: lune run tools/preview/export.luau <model.luau> [--weapon]")
-- Flags after the path: `--name` alone is true, `--name value` takes the value.
local options: { [string]: string | boolean } = {}
do
	local index = 2
	while process.args[index] do
		local name = assert(string.match(process.args[index], "^%-%-(.+)$"), "unexpected argument")
		local value = process.args[index + 1]
		if value and not string.match(value, "^%-%-") then
			options[name] = value
			index += 2
		else
			options[name] = true
			index += 1
		end
	end
end
local isWeapon = options.weapon == true or string.find(path, "weaponModels", 1, true) ~= nil
local isCreature = string.find(path, "creatureModels", 1, true) ~= nil
local kind: ModelChecks.Kind = if isWeapon
	then "weapon"
	elseif isCreature then "creature"
	else "vehicle"

local RobloxCFrame = roblox.CFrame
local SYSTEMS = "src/server/systems/"

-- Relative to the working directory; Sandbox resolves relative paths against the repository root.
if string.sub(path, 1, 1) ~= "/" then
	path = process.cwd .. path
end
-- Weapon files require(script.Parent.Parent.systems.WeaponModel); Sandbox resolves it.
local spec = Sandbox.load(path)

local function frame(cf): { number }
	return { cf:GetComponents() }
end

local function vector(v): { number }
	return { v.X, v.Y, v.Z }
end

-- Problems the render shows; for a vehicle or creature, `defined` is define() run on a copy.
local problems, defined = ModelChecks.check(spec, kind)

-- Bone frames in vehicle space. A bone's world frame is its parent's (the skid's is identity)
-- times the joint C0 times the joint Transform, as Roblox builds a Motor6D chain. `transforms`
-- holds each bone's Transform; empty is the rest pose, where every bone frame is CFrame.new(pivot).
local transforms: { [string]: CFrame } = {}

-- --phase <0..1> [--speed <studs/s>]: a walker (gait "mech") posed mid-stride by
-- src/shared/MechGait.luau. Walks at the speed (default top speed) until the stride settles, then
-- on to the phase. Phase 0 is the left heel strike, 0.5 the right.
if options.phase and spec.gait == "mech" then
	local MechGait = Sandbox.load("src/shared/MechGait.luau")
	local pivots = {}
	for _, bone in spec.bones or {} do
		pivots[bone.name] = bone.pivot
	end
	local state = MechGait.new(MechGait.rig(pivots))
	local target = assert(tonumber(options.phase), "--phase takes a number from 0 to 1") % 1
	local DT = 1 / 240
	local input = {
		forward = tonumber(options.speed) or spec.speed,
		yawRate = 0,
		occupied = true,
		topSpeed = spec.speed,
		turnRate = spec.turnRate or Sandbox.load("src/shared/VehicleDefaults.luau").turnRate,
		time = 0,
	}
	local function advance()
		input.time += DT
		MechGait.step(state, input, DT)
	end
	for _ = 1, 8 / DT do
		advance()
	end
	-- Stop on the frame that reaches the phase (none if the legs have stopped).
	for _ = 1, 4 / DT do
		if state.rate == 0 then
			break
		end
		local before = state.phase
		advance()
		local after = state.phase
		local reached = if after >= before
			then before < target and target <= after
			else target > before or target <= after
		if reached then
			break
		end
	end
	local poses = MechGait.pose(state)
	MechGait.aim(spec.bones, poses)
	for name, pose in poses do
		transforms[name] = pose
	end
end
local bones: { [string]: { pivot: Vector3, world: CFrame } } = {}
local boneList = {}
for _, bone in spec.bones or {} do
	local parent = if bone.parent then bones[bone.parent] else nil
	local parentWorld = if parent then parent.world else RobloxCFrame.new()
	local parentPivot = if parent then parent.pivot else roblox.Vector3.zero
	local c0 = RobloxCFrame.new(parentPivot):Inverse() * RobloxCFrame.new(bone.pivot)
	local world = parentWorld * c0 * (transforms[bone.name] or RobloxCFrame.new())
	bones[bone.name] = { pivot = bone.pivot, world = world }
end

-- Where a rest-pose frame owned by `bone` sits in the current pose (unchanged for the skid).
local function posed(bone: string?, offset)
	local owner = if bone then bones[bone] else nil
	if not owner then
		return offset
	end
	return owner.world * RobloxCFrame.new(owner.pivot):Inverse() * offset
end

local parts = {}
-- Weapons render in the wielder's frame (RightGripAttachment, -Z forward along the arm, +Y up):
-- the handle sits at Grip:Inverse(), as Roblox places a tool's handle.
local hold = RobloxCFrame.new()
if isWeapon then
	local WeaponModel = Sandbox.require(SYSTEMS .. "WeaponModel")
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
	if not ModelChecks.renderable(piece) then
		continue
	end
	table.insert(parts, {
		name = piece.name or ("piece " .. index),
		class = piece.class or "Part",
		shape = if piece.shape then piece.shape.Name else "Block",
		size = vector(piece.size),
		cframe = frame(hold * posed(piece.bone, piece.offset)),
		color = { piece.color.R, piece.color.G, piece.color.B },
		material = if piece.material then piece.material.Name else "SmoothPlastic",
		transparency = piece.transparency or 0,
		bone = piece.bone,
	})
end

if isWeapon then
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

if isCreature then
	local rootSize = if typeof(spec.rootSize) == "Vector3" then spec.rootSize else nil
	local hipHeight = if type(spec.hipHeight) == "number" then spec.hipHeight else nil
	print(serde.encode("json", {
		kind = "creature",
		name = spec.name,
		parts = parts,
		collision = if rootSize and hipHeight
			then {
				{
					size = vector(rootSize),
					cframe = frame(RobloxCFrame.new(0, hipHeight + rootSize.Y / 2, 0)),
				},
			}
			else {},
		reach = if defined then defined.reach else nil,
		rootCenterY = if rootSize and hipHeight then hipHeight + rootSize.Y / 2 else nil,
		problems = problems,
	}))
	return
end

local seats = {}
for _, seat in spec.seats or {} do
	table.insert(seats, frame(posed(spec.seatBone, seat)))
end

for _, bone in spec.bones or {} do
	local posedBone = bones[bone.name]
	table.insert(boneList, {
		name = bone.name,
		parent = bone.parent,
		pivot = vector(bone.pivot),
		cframe = frame(if posedBone then posedBone.world else RobloxCFrame.new(bone.pivot)),
	})
end

local ladders = {}
for _, ladder in spec.ladders or {} do
	table.insert(ladders, { base = vector(ladder.base), height = ladder.height })
end

local collision = {}
for _, box in spec.collision or {} do
	table.insert(collision, { size = vector(box.size), cframe = frame(box.offset) })
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
	bones = boneList,
	ladders = ladders,
	prompt = if spec.prompt
		then { position = vector(spec.prompt.position), reach = spec.prompt.reach }
		else nil,
	exit = if spec.exit then frame(spec.exit) else nil,
	cameraFocus = if spec.cameraFocus then vector(spec.cameraFocus) else nil,
	problems = problems,
}))
