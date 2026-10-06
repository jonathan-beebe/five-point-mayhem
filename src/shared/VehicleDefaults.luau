--!strict
-- Drive tuning for a vehicle model that leaves these fields out (VehicleModel.Model). Pure data,
-- no requires: the server, the client and the Lune tests read it.

return {
	turnRate = 2.4, -- yaw rate at full lock, radians per second
	acceleration = 55, -- studs/s^2 toward the target speed
	braking = 90, -- studs/s^2 against the motion
	coasting = 30, -- studs/s^2 to rest with no throttle
}
