-- Checks vehicle crash damage (src/shared/VehicleDamage.luau) outside Roblox.
-- Usage: lune run tools/tests/vehicle_damage.luau
--
--   - sizes: the jeep is bulk ~1 with 100 health; Aurora's pod is bulk ~6.94
--   - worked crashes: a jeep into a wall at 90, the pod into a tower at 100
--   - every vehicle shrugs off a 2-stud drop and a 12 studs/s bump
--   - walkers land a 12-stud drop and a 14.4-stud MechClimb step-off free and feel a 24-stud one
--   - crashes worth less than 1 health cost nothing
--   - rams: damage from the rammer's real closing speed; walkers stomp at walking pace, not
--     creeping or turning in place
--   - damage, damage as a share of health, and health grow with bulk; bulk clamps
--   - the tracker: crashes, landings and shoves count once; driving, braking, ramps, pods turning
--     round and cleared jumps do not

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local VehicleDamage =
	luau.load(fs.readFile("src/shared/VehicleDamage.luau"), { debugName = "VehicleDamage" })()
local Vector3 = roblox.Vector3

local DT = 1 / 60
local GRAVITY = 196.2
local failures = 0
local checks = 0

local function check(ok: boolean, message: string)
	checks += 1
	if not ok then
		failures += 1
		print("FAIL " .. message)
	end
end

local function near(value: number, want: number, slack: number): boolean
	return math.abs(value - want) <= slack
end

-- Landing speed after a fall of `height` studs.
local function dropSpeed(height: number): number
	return math.sqrt(2 * GRAVITY * height)
end

-- Every vehicle's model file, loaded the way export.luau loads it, with its bulk as Vehicles
-- computes it: footprint x height of its solid parts (collision boxes, default 4, and ladders).
local vehicles = {}
for _, file in fs.readDir("src/server/vehicleModels") do
	local path = "src/server/vehicleModels/" .. file
	local environment = {
		CFrame = roblox.CFrame,
		Vector3 = roblox.Vector3,
		Vector2 = roblox.Vector2,
		Color3 = roblox.Color3,
		Enum = roblox.Enum,
	}
	local spec = luau.load(fs.readFile(path), { debugName = path, environment = environment })()
	local top = if spec.collision then 0 else 4
	for _, box in spec.collision or {} do
		top = math.max(top, box.offset.Position.Y + box.size.Y / 2)
	end
	for _, ladder in spec.ladders or {} do
		top = math.max(top, ladder.base.Y + ladder.height)
	end
	local mass = spec.footprint.X * spec.footprint.Y * 4 -- Vehicles' footprint mass
	-- The pod: the box around its hull boxes.
	local pod = nil
	if spec.pod then
		local low = Vector3.new(math.huge, math.huge, math.huge)
		local high = -low
		for _, box in spec.collision do
			if box.bone == spec.pod.bone then
				local half = box.size / 2
				local frame = box.offset
				local extent = Vector3.new(
					math.abs(frame.RightVector.X * half.X)
						+ math.abs(frame.UpVector.X * half.Y)
						+ math.abs(frame.LookVector.X * half.Z),
					math.abs(frame.RightVector.Y * half.X)
						+ math.abs(frame.UpVector.Y * half.Y)
						+ math.abs(frame.LookVector.Y * half.Z),
					math.abs(frame.RightVector.Z * half.X)
						+ math.abs(frame.UpVector.Z * half.Y)
						+ math.abs(frame.LookVector.Z * half.Z)
				)
				low = low:Min(frame.Position - extent)
				high = high:Max(frame.Position + extent)
			end
		end
		local size = high - low
		pod = VehicleDamage.bulk(size.X, size.Z, size.Y)
	end
	vehicles[file:gsub("%.luau$", "")] = {
		name = spec.name,
		bulk = VehicleDamage.bulk(spec.footprint.X, spec.footprint.Y, top),
		walker = spec.gait ~= nil,
		stomps = spec.stepsOver == true,
		mass = mass,
		ram = spec.ram or 1,
		speed = spec.speed,
		pod = pod,
	}
end

-- Sizes and worked crashes ---------------------------------------------------------------------

local jeep = vehicles.jeep
check(near(jeep.bulk, 1, 0.05), "jeep bulk " .. jeep.bulk .. " should be ~1")
check(VehicleDamage.maxHealth(jeep.bulk) == 100, "jeep should have 100 health")
local wall = VehicleDamage.damage(jeep.bulk, 90, 0)
check(near(wall, 48.5, 1), "jeep into a wall at 90 takes " .. wall .. ", want ~48.5")

local aurora = vehicles.aurora
check(aurora.pod ~= nil and near(aurora.pod, 6.94, 0.05), "Aurora pod bulk should be ~6.94")
local tower = VehicleDamage.damage(aurora.pod or 0, 100, 0)
check(near(tower, 226, 3), "Aurora pod into a tower at 100 takes " .. tower .. ", want ~226")
check(
	tower >= VehicleDamage.maxHealth(aurora.bulk),
	"Aurora pod at top speed into a tower should wreck her"
)

local og = vehicles.mech
check(VehicleDamage.damage(og.bulk, 0, dropSpeed(12), true) == 0, "OG: a 12-stud drop is free")
check(VehicleDamage.damage(og.bulk, 0, dropSpeed(24), true) > 0, "OG: a 24-stud drop hurts")
check(
	VehicleDamage.damage(og.bulk, 0, dropSpeed(12), false) > 0,
	"OG without the walker allowance should feel a 12-stud drop"
)
-- MechClimb lets a walker step off up to MAX_RISE + CLEARANCE = 14.4 studs (~75.2 studs/s).
check(near(dropSpeed(14.4), 75.2, 0.1), "a 14.4-stud drop lands at ~75.2 studs/s")
for id, vehicle in vehicles do
	if vehicle.walker then
		check(
			VehicleDamage.damage(vehicle.bulk, 0, dropSpeed(14.4), true) == 0,
			id .. ": a 14.4-stud drop is free"
		)
	end
end

-- Below 1 health a crash is nothing: just past the threshold it would be a fraction.
do
	local horizontal = VehicleDamage.thresholds(jeep.bulk)
	check(VehicleDamage.damage(jeep.bulk, horizontal + 0.5, 0) == 0, "a 0.5 excess costs nothing")
	check(VehicleDamage.damage(jeep.bulk, horizontal + 5, 0) >= 1, "a 5 excess costs health")
end

for id, vehicle in vehicles do
	-- The pod lands on its hull, not on legs.
	for _, each in { { vehicle.bulk, vehicle.walker }, { vehicle.pod, false } } do
		local bulk, walker = each[1], each[2]
		if bulk then
			check(
				VehicleDamage.damage(bulk, 0, dropSpeed(2), walker) == 0,
				id .. ": a 2-stud drop should be free"
			)
			check(
				VehicleDamage.damage(bulk, 12, 0, walker) == 0,
				id .. ": a 12 studs/s bump should be free"
			)
		end
	end
end

-- Scaling --------------------------------------------------------------------------------------

for _, impact in { 40, 60, 100 } do
	local lastDamage, lastShare = -1, -1
	for step = 0, 100 do
		local bulk = 0.2 + (50 - 0.2) * step / 100
		local damage = VehicleDamage.damage(bulk, impact, 0)
		local share = damage / VehicleDamage.maxHealth(bulk)
		check(damage >= lastDamage, "damage at " .. impact .. " should grow with bulk " .. bulk)
		check(share >= lastShare, "share at " .. impact .. " should grow with bulk " .. bulk)
		lastDamage, lastShare = damage, share
	end
end
local lastHealth = 0
for step = 0, 100 do
	local health = VehicleDamage.maxHealth(0.2 + (50 - 0.2) * step / 100)
	check(health >= lastHealth, "health should not fall with bulk")
	lastHealth = health
end
check(VehicleDamage.bulk(1, 1, 1) == 0.2, "bulk clamps at 0.2")
check(VehicleDamage.bulk(100, 100, 100) == 50, "bulk clamps at 50")
check(VehicleDamage.bulk(8, 14, 5, 3) == 3, "a catalog bulk wins")
check(VehicleDamage.wreckRadius(0.2) == 10, "wreck radius clamps at 10")
check(VehicleDamage.wreckRadius(50) == 34, "wreck radius clamps at 34")

-- Rams ---------------------------------------------------------------------------------------

-- Mirrors Vehicles.shove: RAM_TRANSFER x mass ratio (clamped 0.15..3) x ram.
local function transfer(rammer, struck): number
	return 1.1 * math.clamp(rammer.mass / struck.mass, 0.15, 3) * rammer.ram
end

local function ramDamage(rammer, struck, closing: number): number
	local loss = VehicleDamage.ramLoss(closing, transfer(rammer, struck), rammer.stomps)
	return VehicleDamage.damage(struck.bulk, loss, 0)
end

check(VehicleDamage.closingSpeed(50, 0, 0, 0, 1, 0) == 50, "closing: straight at a parked car")
check(VehicleDamage.closingSpeed(50, 0, 0, 0, 0, 1) == 0, "closing: passing alongside is 0")
check(VehicleDamage.closingSpeed(50, 0, 30, 0, 2, 0) == 20, "closing: catching one up")
check(VehicleDamage.closingSpeed(50, 0, -50, 0, 1, 0) == 100, "closing: head-on adds")
check(VehicleDamage.closingSpeed(0, 0, 40, 0, 1, 0) == 0, "closing: never negative")
check(VehicleDamage.closingSpeed(50, 0, 0, 0, 0, 0) == 0, "closing: no direction is 0")

do
	local taxi = vehicles.taxi
	local slow, fast = ramDamage(jeep, taxi, 30), ramDamage(jeep, taxi, 90)
	check(fast > slow, "car rams scale with closing speed")
	check(ramDamage(jeep, taxi, 5) == 0, "a car nudging at 5 does nothing")
	check(VehicleDamage.ramLoss(1000, 3) == 140, "ram loss clamps at 140")
end

for id, walker in vehicles do
	if walker.stomps then
		check(ramDamage(walker, jeep, 1.9) == 0, id .. ": creeping at 1.9 does not hurt a jeep")
		check(ramDamage(walker, jeep, 0) == 0, id .. ": turning in place does not hurt a jeep")
		local stomp = ramDamage(walker, jeep, walker.speed)
		check(stomp >= 25, id .. " walking into a jeep takes " .. stomp .. ", want >= 25")
	end
end
check(
	ramDamage(og, jeep, 3) < VehicleDamage.maxHealth(jeep.bulk),
	"OG at 3 studs/s does not wreck a jeep"
)

-- Tracker --------------------------------------------------------------------------------------

-- Feeds velocities (each { x, y, z }) at `dt`; returns every result as { frame, lossH, lossV }.
local function feed(samples: { { number } }, dt: number?, tracker: any?): { { number } }
	tracker = tracker or VehicleDamage.newTracker()
	local results = {}
	for frame, v in samples do
		local lossH, lossV = VehicleDamage.step(tracker, v[1], v[2], v[3], dt or DT)
		if lossH then
			table.insert(results, { frame, lossH, lossV })
		end
	end
	return results
end

local function repeated(v: { number }, count: number, into: { { number } }?): { { number } }
	local list = into or {}
	for _ = 1, count do
		table.insert(list, v)
	end
	return list
end

do
	local results = feed(repeated({ 60, 0, 20 }, 60))
	check(#results == 0, "constant velocity: no crash")
end
do
	local samples = {}
	for frame = 0, 30 do
		table.insert(samples, { 0, -GRAVITY * frame * DT, 0 })
	end
	repeated({ 0, 0, 0 }, 10, samples)
	local results = feed(samples)
	check(#results == 1, "free fall then stop: one crash, got " .. #results)
	check(results[1] and near(results[1][3], 98, 0.5), "free fall 0.5 s: lossV ~98")
	check(results[1] and results[1][2] == 0, "free fall: no horizontal loss")
end
do
	local results = feed(repeated({ 0, 0, 0 }, 5, { { 100, 0, 0 }, { 60, 0, 0 } }))
	check(#results == 1, "100 -> 60 -> 0: one crash")
	check(results[1] and near(results[1][2], 100, 1e-6), "100 -> 60 -> 0: lossH 100")
end
do
	local results = feed(repeated({ 30, 45, 0 }, 10, { { 30, 0, 0 } }))
	check(#results == 0, "a ramp lifting 0 -> 45: no crash")
end
do
	local samples = {}
	for frame = 0, 60 do
		table.insert(samples, { math.max(90 - 90 * frame * DT, 0), 0, 0 })
	end
	check(#feed(samples) == 0, "braking at 90 studs/s^2: no crash")
end
-- The drive constraint's hardest stop, ~670 studs/s^2, at any frame rate.
for _, dt in { 1 / 60, 1 / 45, 1 / 30, 1 / 20 } do
	local samples = {}
	for frame = 0, math.ceil(150 / 670 / dt) + 2 do
		table.insert(samples, { math.max(150 - 670 * frame * dt, 0), 0, 0 })
	end
	check(#feed(samples, dt) == 0, "a 670 studs/s^2 stop at dt " .. dt .. ": no crash")
end
do
	local samples = {}
	for frame = 0, 10 do
		table.insert(samples, { 50, math.min(-28 + 600 * frame * DT, 28), 0 })
	end
	check(#feed(samples) == 0, "pod reversing -28 -> 28 at 600 studs/s^2: no crash")
end
do
	local tracker = VehicleDamage.newTracker()
	feed(repeated({ 140, 0, 0 }, 5), DT, tracker)
	VehicleDamage.clear(tracker)
	local results = feed(repeated({ 0, 0, 0 }, 5), DT, tracker)
	check(#results == 0, "cleared, then a jump from 140 to 0: no crash")
end
do
	local results = feed(repeated({ 0, 0, 0 }, 3, { { 90, 0, 0 } }), 1 / 30)
	check(#results == 1 and near(results[1][2], 90, 1e-6), "dt 1/30: a crash from 90 counts")
end
do
	local samples = {}
	for frame = 0, 40 do
		table.insert(samples, { 1000 - 20 * frame, 0, 0 })
	end
	local results = feed(samples)
	local limit = math.ceil(0.2 / DT) + 2 -- the priming frame, then 0.2 s, then one frame
	check(#results >= 1, "sustained 20/frame: a crash")
	check(results[1] and results[1][1] <= limit, "sustained 20/frame: ends by 0.2 s + 1 frame")
end

print(string.format("%d checks, %d failures", checks, failures))
if failures > 0 then
	process.exit(1)
end
