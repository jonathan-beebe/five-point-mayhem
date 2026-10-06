--!strict
-- Drive tuning for a vehicle model that leaves these fields out (VehicleModel.Model). Pure data,
-- no requires: the server, the client and the Lune tests read it.
--
-- Every car model sets speed, acceleration, braking and coasting from its real vehicle, with a
-- comment giving the real numbers. Walkers keep their own tuning. The mapping:
--
--   speed (studs/s)  = max(20, 45 x (km/h / 100) ^ (2/3))
--   time (s)         = 2.4 x (real seconds / 2.4) ^ (2/3)
--   rate (studs/s^2) = speed(v) / time(t), for a real sprint or stop of t seconds to or from v
--
-- Models are 4 studs = 1 m, so real scale would be 1.11 studs/s per km/h (a Bugatti at 467). The
-- 2/3 power keeps the order and compresses the spread: 100 km/h is 45 studs/s, a 68 km/h Abrams
-- 35, a 420 km/h Bugatti 117 (3.4x the Abrams; real 6.2x). The floor of 20 keeps every vehicle
-- faster than a player on foot (WalkSpeed 16); it lifts the Bulldozer, Lunar Rover and Snowcat.
-- Times compress by the same power about the quickest sprint (Bugatti 0-100 km/h, 2.4 s): a VW
-- Microbus's 40 s becomes 15.7 s. Acceleration is from the real 0-100 km/h time (0 to a lower
-- speed for slower vehicles); braking and coasting are from the real deceleration in g, over a
-- stop from 100 km/h or the real top speed if lower. At 100 km/h, 1 g is about 16 studs/s^2.
--
-- The defaults are a typical car: 0-100 km/h in 8 s, brakes 0.85 g, coasts 0.2 g.

return {
	turnRate = 2.4, -- yaw rate at full lock, radians per second
	acceleration = 8.4, -- studs/s^2 toward the target speed
	braking = 15.1, -- studs/s^2 against the motion
	coasting = 5.7, -- studs/s^2 to rest with no throttle
}
