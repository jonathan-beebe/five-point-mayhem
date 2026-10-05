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
}

export type BoxSpec = { size: Vector3, offset: CFrame }

export type BoneSpec = {
	name: string,
	parent: string?, -- an earlier bone; nil = the skid
	pivot: Vector3, -- joint center in the rest pose; joint axes are the vehicle axes
}

-- A climbable TrussPart (2 x height x 2) welded to the skid.
export type LadderSpec = {
	base: Vector3, -- bottom center; y >= 1
	height: number, -- even (TrussPart sizes snap to 2 studs)
}

-- The Drive/Ride prompt's anchor and MaxActivationDistance.
export type PromptSpec = { position: Vector3, reach: number }

-- A walkable room around the driver seat (the mech's cab). Leaving the seat leaves the driver
-- standing in it; prompts inside offer Drive and Climb out (to `exit`). The collision boxes must
-- leave it hollow. The prompts sit 3 above its floor (avatar root height) and reach its corners.
export type CabSpec = { center: Vector3, size: Vector3 }

export type Model = {
	name: string,
	speed: number, -- top speed, studs per second
	turnRate: number?, -- yaw rate at full lock, radians per second; default 2.4
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
	prompt: PromptSpec?, -- default: 3.5 above the center, reach from the footprint
	cab: CabSpec?,
	exit: CFrame?, -- with a cab: where Climb out puts the player's root
	cameraFocus: Vector3?, -- outside-view camera subject
	cockpitCamera: boolean?, -- the driver gets the first-person cockpit camera
	gait: string?, -- client animator for the bones; "mech" is the only one
	acceleration: number?, -- studs/s^2 toward the target speed; default 55
	braking: number?, -- studs/s^2 against the motion; default 90
	coasting: number?, -- studs/s^2 to rest with no throttle; default 30
	turnAcceleration: number?, -- rad/s^2 on the yaw rate; nil = instant
	turnInPlace: boolean?, -- full turn rate at zero speed
	parkingBrake: boolean?, -- with no driver, the drive constraints hold it still
	uprightTorque: number?, -- multiplier on the upright MaxTorque; default 1
	stepsOver: boolean?, -- passes through scenery and other vehicles; buildings and ground stop it
	ram: number?, -- how hard it shoves vehicles, fells trees, flings creatures; default 1
}

local VehicleModel = {}

VehicleModel.MAX_PIECES = 320
VehicleModel.MAX_SEATS = 8
VehicleModel.MAX_BONES = 32
VehicleModel.SEAT_SIZE = Vector3.new(2, 1, 2)

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
	return model
end

return VehicleModel
