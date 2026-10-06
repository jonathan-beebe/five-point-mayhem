--!strict
-- Sizes Vehicles derives from a vehicle model (server VehicleModel.Model, after define): solid
-- height, the flying pod's box, crash sizes, the box a vehicle hurts, prompt reach, and the pod's
-- frames relative to its bone. Pure: Roblox datatypes and VehicleDamage only.
-- `tools/tests/vehicle_logic.luau` pins each function bit for bit, for every model file, against
-- the inline code it replaced.

local VehicleDamage = require(script.Parent.VehicleDamage)

local VehicleSizing = {}

type Box = { size: Vector3, offset: CFrame, bone: string? }
type Ladder = { base: Vector3, height: number }

-- The fields of VehicleModel.Model these functions read; nested tables repeat VehicleModel's
-- types in full. `collision` is set: define fills it.
export type Spec = {
	footprint: Vector2,
	collision: { Box }?,
	ladders: { Ladder }?,
	pod: { bone: string, button: Vector3, jets: { Vector3 }?, legsSeat: CFrame? }?,
	cab: { center: Vector3, size: Vector3 }?,
	exit: CFrame?,
	stepsOver: boolean?,
	gait: string?,
}

local FOOTPRINT_DENSITY = 4 -- mass per square stud of footprint
local HIT_MARGIN = 1.5 -- studs past the footprint that count as touching
local STOMP_HEIGHT = 14 -- walkers hurt only around their legs, not riders on the deck
local MIN_REACH_HEIGHT = 4 -- a car hurts at least this high
local PROMPT_MARGIN = 6 -- studs the Drive/Ride prompts reach past the footprint's corners
local CAB_PROMPT_MARGIN = 0.5 -- studs the cab prompts reach past its corners
-- Where Climb out puts the player for a model without `exit`.
VehicleSizing.DEFAULT_EXIT = CFrame.new(0, 3, 0)

-- Footprint mass, for shoves between vehicles: base car 448, kart 215, school bus 1690.
function VehicleSizing.footprintMass(w: number, l: number): number
	return w * l * FOOTPRINT_DENSITY
end

-- Height of the vehicle's solid parts above the ground: collision boxes and ladders.
function VehicleSizing.solidHeight(spec: Spec): number
	local top = 0
	for _, box in spec.collision :: { Box } do
		top = math.max(top, box.offset.Position.Y + box.size.Y / 2)
	end
	for _, ladder in (spec.ladders or {}) :: { Ladder } do
		top = math.max(top, ladder.base.Y + ladder.height)
	end
	return top
end

-- Size of the box around the pod's hull boxes (spec.pod.bone), in vehicle space. Zero without.
function VehicleSizing.podSize(spec: Spec): Vector3
	local low, high = Vector3.one * math.huge, -Vector3.one * math.huge
	for _, box in spec.collision :: { Box } do
		if spec.pod and box.bone == spec.pod.bone then
			local half = box.size / 2
			local frame = box.offset
			local extent = (frame.RightVector * half.X):Abs()
				+ (frame.UpVector * half.Y):Abs()
				+ (frame.LookVector * half.Z):Abs()
			low = low:Min(frame.Position - extent)
			high = high:Max(frame.Position + extent)
		end
	end
	return if high.X >= low.X then high - low else Vector3.zero
end

export type CrashSize = {
	bulk: number,
	walker: boolean, -- lands on its legs (VehicleDamage.thresholds)
	length: number, -- footprint length: a head-on crash's sparks fly at the front
	height: number, -- solid height: smoke and fire rise from half of it
	podBulk: number, -- the flying pod's, from its own hull boxes
	podLength: number,
	podMass: number, -- the pod's footprint mass, for rams into it while it is away
}

-- The sizes crash damage uses. `override` is the catalog entry's `bulk`.
function VehicleSizing.crash(spec: Spec, override: number?): CrashSize
	local pod = VehicleSizing.podSize(spec)
	local height = VehicleSizing.solidHeight(spec)
	return {
		bulk = VehicleDamage.bulk(spec.footprint.X, spec.footprint.Y, height, override),
		walker = spec.gait ~= nil,
		length = spec.footprint.Y,
		height = height,
		podBulk = VehicleDamage.bulk(pod.X, pod.Z, pod.Y),
		podLength = pod.Z,
		podMass = VehicleSizing.footprintMass(pod.X, pod.Z),
	}
end

-- The box a vehicle hurts, as half width, height and half length from the ground.
function VehicleSizing.reach(spec: Spec): Vector3
	local height = if spec.stepsOver
		then STOMP_HEIGHT
		else math.max(VehicleSizing.solidHeight(spec), MIN_REACH_HEIGHT)
	return Vector3.new(spec.footprint.X / 2 + HIT_MARGIN, height, spec.footprint.Y / 2 + HIT_MARGIN)
end

-- The Drive/Ride prompts' reach from the middle of a W x L vehicle: past its far corners.
function VehicleSizing.promptReach(W: number, L: number): number
	return math.sqrt((W / 2) ^ 2 + (L / 2) ^ 2) + PROMPT_MARGIN
end

-- The cab prompts' reach from the middle of a cab of `size`: its corners.
function VehicleSizing.cabReach(size: Vector3): number
	return math.sqrt((size.X / 2) ^ 2 + (size.Z / 2) ^ 2) + CAB_PROMPT_MARGIN
end

-- Where Climb out (and a pod walker's legs-seat dismount) puts the player, vehicle space.
function VehicleSizing.exitOf(spec: Spec): CFrame
	return spec.exit or VehicleSizing.DEFAULT_EXIT
end

export type PodFrames = {
	exit: CFrame, -- the walker's exit, around the pod's root, at the same height over the ground
	button: CFrame, -- the launch button
	jets: { CFrame }, -- thruster mouths
}

-- The pod's frames relative to its bone's `pivot` (spec.pod must be set).
function VehicleSizing.podFrames(spec: Spec, pivot: Vector3): PodFrames
	local pod = assert(spec.pod, "podFrames: the model has no pod")
	local exit = VehicleSizing.exitOf(spec)
	local jets = {}
	for _, mouth in (pod.jets or {}) :: { Vector3 } do
		table.insert(jets, CFrame.new(mouth - pivot))
	end
	return {
		exit = CFrame.new(exit.X - pivot.X, exit.Y, exit.Z - pivot.Z) * exit.Rotation,
		button = CFrame.new(pod.button - pivot),
		jets = jets,
	}
end

return VehicleSizing
