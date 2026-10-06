-- The shape of a vehicle, shared by the files in `src/server/vehicleModels`.
--
-- A vehicle file returns a plain table (no requires) so tools outside Roblox can load it; it may
-- use only Roblox datatypes (CFrame, Vector3, Vector2, Color3, Enum) and the Luau standard library.
--
-- Everything is in vehicle space: the origin is on the ground under the center of the footprint,
-- +Y is up, -Z is the front, +X is the driver's right. Scale: 4 studs = 1 meter.
--
-- The car rides on an invisible frictionless skid (footprint x 1 stud, resting on the ground)
-- whose ends ramp up to 1.6 studs within 2.5 studs of the front and back, so it climbs curbs and
-- steps; wheels and body are decoration welded to it. The collision box keeps players and the world
-- out of the body. Seats are invisible; the seated avatar sits on top of each seat block.
--
-- Optional rig (walkers): `bones` form a Motor6D tree rooted at the skid. A piece or seat on a bone
-- is welded to that bone and authored in the rest pose; its bone's Transform moves it. Every other
-- field below `pieces` is optional too; a model without them builds as a plain car.

export type PieceSpec = {
	name: string?,
	class: ("Part" | "WedgePart")?, -- default Part
	shape: Enum.PartType?, -- Part only: Block (default), Ball, Cylinder (axis is local X)
	size: Vector3,
	offset: CFrame,
	color: Color3,
	material: Enum.Material?, -- default SmoothPlastic
	transparency: number?,
	reflectance: number?,
	bone: string?, -- welded to this bone; nil = welded to the skid
	-- Left out of the pilot's first-person view, so the pilot sees straight through it (a tinted
	-- canopy that looks clear from inside).
	hideInCockpit: boolean?,
}

-- `bone`: welded to that bone instead of the skid (a flying pod's hull goes with the pod).
export type BoxSpec = { size: Vector3, offset: CFrame, bone: string? }

-- A flying pod (server PodFlight): the seat bone detaches from the walker and flies, with every
-- piece, hull box, seat and the cab welded to it, then flies home and docks.
export type PodSpec = {
	bone: string, -- must be the seatBone
	button: Vector3, -- the console's launch button, vehicle space, rest pose: the prompt's anchor
	jets: { Vector3 }?, -- thruster mouths (facing +Z) that flame while the pod flies
	-- A saddle seat on the pod bone's parent bone (vehicle space, rest pose): while the pod is
	-- away, the walk-up Drive prompt seats a player here to drive the legs.
	legsSeat: CFrame?,
}

export type BoneSpec = {
	name: string,
	parent: string?, -- an earlier bone; nil = the skid
	pivot: Vector3, -- joint center in the rest pose; joint axes are the vehicle axes
	-- A hydraulic end: clients turn this bone so it keeps pointing at the `aim` bone's pivot
	-- (MechGait.aim). A barrel and a rod aim at each other across a joint.
	aim: string?,
	-- A steering wheel: clients turn this bone about this axis (vehicle space, pointing at the
	-- driver) as the walker turns (MechGait.steer).
	steer: Vector3?,
	-- A springy part (an antenna): clients wobble this bone about its pivot as the walker steps,
	-- speeds up, brakes and turns (MechGait.wobble).
	wobble: boolean?,
}

-- A climbable TrussPart (2 x height x 2) welded to the skid.
export type LadderSpec = {
	base: Vector3, -- bottom center; y >= 1
	height: number, -- even (TrussPart sizes snap to 2 studs)
}

-- A smokestack mouth (walkers): clients puff smoke from it while the walker moves, and a burst on
-- every step. In vehicle space, rest pose; on `bone` (nil = the skid), so it moves with that bone.
export type SmokeSpec = { position: Vector3, bone: string? }

-- The Drive/Ride prompt's anchor and MaxActivationDistance.
export type PromptSpec = { position: Vector3, reach: number }

-- A walkable room around the driver seat (the mech's cab). Leaving the seat leaves the driver
-- standing in it; prompts inside offer Drive and Climb out (to `exit`). The collision boxes must
-- leave it hollow. The prompts sit 3 above its floor (avatar root height) and reach its corners.
export type CabSpec = { center: Vector3, size: Vector3 }

export type Model = {
	name: string,
	speed: number, -- top speed, studs per second
	turnRate: number?, -- yaw rate at full lock, radians per second; default in DEFAULTS
	footprint: Vector2, -- skid width (X) and length (Z)
	-- Solid boxes players and the world collide with. Default: the footprint up to 4 studs tall.
	collision: { BoxSpec }?,
	-- Seat centers. The first is the driver. A seat block is 2 x 1 x 2; the avatar sits on its
	-- top face, facing -Z.
	seats: { CFrame },
	pieces: { PieceSpec },

	bones: { BoneSpec }?, -- parents before children
	seatBone: string?, -- every seat welds to this bone; default the skid
	ladders: { LadderSpec }?,
	smoke: { SmokeSpec }?,
	prompt: PromptSpec?, -- default: 3.5 above the center, reach from the footprint
	cab: CabSpec?,
	pod: PodSpec?,
	exit: CFrame?, -- with a cab: where Climb out puts the player's root
	cameraFocus: Vector3?, -- outside-view camera subject
	cockpitCamera: boolean?, -- the driver gets the first-person cockpit camera
	gait: string?, -- client animator for the bones; "mech" is the only one
	acceleration: number?, -- studs/s^2 toward the target speed; default in DEFAULTS
	braking: number?, -- studs/s^2 against the motion; default in DEFAULTS
	coasting: number?, -- studs/s^2 to rest with no throttle; default in DEFAULTS
	turnAcceleration: number?, -- rad/s^2 on the yaw rate; nil = instant
	turnInPlace: boolean?, -- full turn rate at zero speed
	parkingBrake: boolean?, -- with no driver, the drive constraints hold it still
	uprightTorque: number?, -- multiplier on the upright MaxTorque; default 1
	stepsOver: boolean?, -- passes through scenery and other vehicles; buildings and ground stop it
	-- Walker climb assist (MechClimb): climbs walls up to MechClimb.MAX_RISE. Default true for
	-- walkers (gait set); false turns it off.
	climbs: boolean?,
	ram: number?, -- how hard it shoves vehicles, fells trees, flings creatures; default 1
}

local VehicleDefaults = require(game:GetService("ReplicatedStorage").Shared.VehicleDefaults)

local VehicleModel = {}

VehicleModel.MAX_PIECES = 320
VehicleModel.MAX_SEATS = 8
VehicleModel.MAX_BONES = 32
VehicleModel.SEAT_SIZE = Vector3.new(2, 1, 2)

-- Drive tuning for a model that leaves these fields out (src/shared/VehicleDefaults.luau).
VehicleModel.DEFAULTS = VehicleDefaults

-- Rotations that lay a cylinder's X axis along Z (axles across the car need none) or Y.
VehicleModel.CYLINDER_Z = CFrame.Angles(0, math.rad(90), 0)
VehicleModel.CYLINDER_Y = CFrame.Angles(0, 0, math.rad(90))

-- Validates a vehicle file's table and fills defaults.
function VehicleModel.define(model: Model): Model
	assert(type(model.name) == "string", "vehicle model needs a name")
	assert(#model.pieces <= VehicleModel.MAX_PIECES, model.name .. " has too many pieces")
	assert(
		#model.seats >= 1 and #model.seats <= VehicleModel.MAX_SEATS,
		model.name .. " needs 1 to " .. VehicleModel.MAX_SEATS .. " seats"
	)
	assert(model.speed > 0, model.name .. " needs a positive speed")
	if not model.collision then
		local W, L = model.footprint.X, model.footprint.Y
		model.collision = { { size = Vector3.new(W, 3, L), offset = CFrame.new(0, 2.5, 0) } }
	end

	local bones = {}
	if model.bones then
		assert(
			#model.bones <= VehicleModel.MAX_BONES,
			model.name .. " has more than " .. VehicleModel.MAX_BONES .. " bones"
		)
		for _, bone in model.bones do
			assert(type(bone.name) == "string", model.name .. ": a bone needs a name")
			assert(
				not bones[bone.name],
				model.name .. ": bone " .. bone.name .. " is defined twice"
			)
			assert(
				bone.parent == nil or bones[bone.parent],
				model.name .. ": bone " .. bone.name .. "'s parent must be an earlier bone"
			)
			bones[bone.name] = true
		end
		for _, bone in model.bones do
			assert(
				bone.aim == nil or (bones[bone.aim] and bone.aim ~= bone.name),
				model.name .. ": bone " .. bone.name .. " aims at an unknown bone"
			)
			assert(
				bone.steer == nil or bone.steer.Magnitude > 0,
				model.name .. ": bone " .. bone.name .. " needs a nonzero steer axis"
			)
		end
	end
	for _, stack in model.smoke or {} do
		assert(
			stack.bone == nil or bones[stack.bone],
			model.name .. ": a smoke spot names an unknown bone"
		)
	end
	for index, piece in model.pieces do
		assert(
			piece.bone == nil or bones[piece.bone],
			model.name .. ": piece " .. (piece.name or tostring(index)) .. " names an unknown bone"
		)
	end
	assert(
		model.seatBone == nil or bones[model.seatBone],
		model.name .. ": seatBone names an unknown bone"
	)
	for _, ladder in model.ladders or {} do
		assert(ladder.base.Y >= 1, model.name .. ": a ladder's base must be at y >= 1")
		assert(
			ladder.height > 0 and ladder.height % 2 == 0,
			model.name .. ": a ladder's height must be a positive even number"
		)
	end
	assert(
		(model.cab == nil) == (model.exit == nil),
		model.name .. ": a cab needs an exit, and an exit needs a cab"
	)
	assert(
		model.prompt == nil or model.prompt.reach > 0,
		model.name .. ": prompt reach must be positive"
	)
	assert(model.ram == nil or model.ram > 0, model.name .. ": ram must be positive")
	for _, box in model.collision :: { BoxSpec } do
		assert(
			box.bone == nil or bones[box.bone],
			model.name .. ": a collision box names an unknown bone"
		)
	end
	if model.pod then
		assert(
			model.pod.bone == model.seatBone and bones[model.pod.bone],
			model.name .. ": the pod's bone must be the seatBone"
		)
	end
	return model
end

return VehicleModel
