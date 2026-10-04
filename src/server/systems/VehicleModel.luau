-- The shape of a vehicle, shared by the files in `src/server/vehicleModels`.
--
-- A vehicle file returns a plain table (no requires) so tools outside Roblox can load it; it may
-- use only Roblox datatypes (CFrame, Vector3, Vector2, Color3, Enum) and the Luau standard library.
--
-- Everything is in vehicle space: the origin is on the ground under the center of the footprint,
-- +Y is up, -Z is the front, +X is the driver's right. Scale: 4 studs = 1 meter.
--
-- The car rides on an invisible frictionless skid (footprint x 1 stud, resting on the ground);
-- wheels and body are decoration welded to it. The collision box keeps players and the world
-- out of the body. Seats are invisible; the seated avatar sits on top of each seat block.

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
}

export type BoxSpec = { size: Vector3, offset: CFrame }

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
}

local VehicleModel = {}

VehicleModel.MAX_PIECES = 320
VehicleModel.MAX_SEATS = 8
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
	return model
end

return VehicleModel
