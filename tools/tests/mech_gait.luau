-- Checks the walk cycle (src/shared/MechGait.luau) of every walker (a vehicle model with
-- gait "mech") outside Roblox.
-- Usage: lune run tools/tests/mech_gait.luau
--
-- Drives each walker's gait, at its own top speed and turn rate, through walking, reversing, turning in place, starting and stopping, and checks:
--   - a planted foot does not skate: its ground point moves < 0.05 studs per frame
--   - a planted ankle sits on the ground (the IK reaches it)
--   - every channel stays inside the bone limits before clamping
--   - the feet settle under the hips and the phase parks after a stop
--   - heel strikes fire while walking
--   - a wobble (antenna spring) moves while walking and settles after a stop

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local function load(file: string): any
	local environment = { CFrame = roblox.CFrame, Vector3 = roblox.Vector3 }
	return luau.load(fs.readFile(file), { debugName = file, environment = environment })()
end

local MechGait = load("src/shared/MechGait.luau")
local CFrame, Vector3 = roblox.CFrame, roblox.Vector3

-- Rest pivots, top speed and turn rate of the walker under test (set by the loop at the bottom).
local PIVOTS: { [string]: any } = {}
local TOP, TURN, RISE, FALL = 18, 0.7, 1.8, 1.3

-- Every walker's model file, loaded the way export.luau loads it.
local walkers = {}
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
	if spec.gait == "mech" then
		local pivots = {}
		for _, bone in spec.bones do
			pivots[bone.name] = bone.pivot
		end
		table.insert(walkers, {
			name = spec.name,
			pivots = pivots,
			speed = spec.speed,
			turnRate = spec.turnRate or 0.7,
			rise = spec.speed / (spec.acceleration or 55), -- seconds from rest to top speed
			fall = spec.speed / (spec.coasting or 30), -- seconds to coast from top speed to rest
		})
	end
end
table.sort(walkers, function(a, b)
	return a.name < b.name
end)

local DT = 1 / 60
local SKATE = 0.05
local failures = 0
local walkerFailures = 0 -- failures printed for the walker under test
local checks = 0

local function check(ok: boolean, message: string)
	checks += 1
	if not ok then
		failures += 1
		walkerFailures += 1
		if walkerFailures <= 10 then
			print("FAIL " .. message)
		end
	end
end

-- Ankle position in vehicle space from the posed Transforms (forward kinematics, as Motor6Ds do).
local function ankle(rig, poses, side: string): any
	local pelvis = CFrame.new(rig.pelvis) * poses.pelvis
	local hip, knee, foot =
		PIVOTS["thigh_" .. side], PIVOTS["shin_" .. side], PIVOTS["foot_" .. side]
	local thigh = pelvis * CFrame.new(hip - rig.pelvis) * poses["thigh_" .. side]
	local shin = thigh * CFrame.new(knee - hip) * poses["shin_" .. side]
	return (shin * CFrame.new(foot - knee)).Position
end

-- Limits allow 0.5 degrees of slack: the knee touches its -40 degree stop at mid-swing.
local SLACK = math.rad(0.5)

local function checkLimits(state, label: string)
	for bone, channels in state.raw do
		for name, value in channels do
			local limit = MechGait.LIMITS[bone] and MechGait.LIMITS[bone][name]
			if limit then
				local slack = if name == "tx" or name == "ty" then 1e-6 else SLACK
				check(
					value >= limit[1] - slack and value <= limit[2] + slack,
					string.format(
						"%s: %s.%s = %.2f outside %.2f..%.2f",
						label,
						bone,
						name,
						if name == "tx" or name == "ty" then value else math.deg(value),
						if name == "tx" or name == "ty" then limit[1] else math.deg(limit[1]),
						if name == "tx" or name == "ty" then limit[2] else math.deg(limit[2])
					)
				)
			end
		end
	end
end

-- Runs a scenario: `drive(t)` returns forward speed and yaw rate at time t. Tracks each foot's
-- ground point along its hip's path (exact for straight motion; for turns, the motion along the
-- arc). Checks start after `warmup` seconds.
local function run(
	label: string,
	seconds: number,
	drive: (number) -> (number, number),
	warmup: number?
)
	local rig = MechGait.rig(PIVOTS)
	local state = MechGait.new(rig)
	local travelled = { L = 0, R = 0 } -- distance each hip has moved forward over the ground
	local last = {}
	local footfalls = 0
	local maxSkate = 0
	local wobble = MechGait.newWobble()
	local maxWobble = 0
	local t = 0
	while t < seconds do
		local v, omega = drive(t)
		local events = MechGait.step(state, {
			forward = v,
			yawRate = omega,
			occupied = true,
			topSpeed = TOP,
			turnRate = TURN,
			time = t,
		}, DT)
		footfalls += #events
		local poses = MechGait.pose(state)
		MechGait.wobble(wobble, state, events, DT)
		local checking = t >= (warmup or 0)
		if not checking then
			t += DT
			continue
		end
		checkLimits(state, string.format("%s t=%.2f", label, t))
		maxWobble = math.max(maxWobble, math.abs(wobble.x), math.abs(wobble.z))
		for _, side in { "L", "R" } do
			local hipX = PIVOTS["thigh_" .. side].X
			travelled[side] += (v - omega * hipX) * DT
			local foot = state.feet[side]
			local a = ankle(rig, poses, side)
			-- Ground position of the ankle along the hip's path (forward +).
			local ground = travelled[side] - a.Z
			local planted = not foot.swinging and foot.lift == 0
			if planted and last[side] and last[side].planted then
				local skate = math.abs(ground - last[side].ground)
				maxSkate = math.max(maxSkate, skate)
				check(
					skate < SKATE,
					string.format("%s t=%.2f: %s foot skated %.3f", label, t, side, skate)
				)
				check(
					math.abs(a.Y - PIVOTS["foot_" .. side].Y) < 0.05,
					string.format(
						"%s t=%.2f: %s ankle %.3f off the ground",
						label,
						t,
						side,
						a.Y - PIVOTS["foot_" .. side].Y
					)
				)
			end
			local target = Vector3.new(
				PIVOTS["foot_" .. side].X,
				PIVOTS["foot_" .. side].Y + foot.lift,
				PIVOTS["foot_" .. side].Z - foot.z
			)
			check(
				(a - target).Magnitude < 0.05,
				string.format(
					"%s t=%.2f: %s IK missed by %.3f",
					label,
					t,
					side,
					(a - target).Magnitude
				)
			)
			last[side] = { planted = planted, ground = ground }
		end
		t += DT
	end
	print(
		string.format(
			"%-28s footfalls %3d  max skate %.4f  max wobble %4.1f deg",
			label,
			footfalls,
			maxSkate,
			math.deg(maxWobble)
		)
	)
	return state, footfalls, wobble, maxWobble
end

local function ramp(t: number, start: number, rise: number): number
	return math.clamp((t - start) / rise, 0, 1)
end

for _, walker in walkers do
	PIVOTS, TOP, TURN = walker.pivots, walker.speed, walker.turnRate
	RISE, FALL = walker.rise, walker.fall
	walkerFailures = 0
	print(walker.name)
	-- Steady walk at top speed (a jump to full speed, so checks start once the stride settles).
	local _, walkSteps, _, walkWobble = run("walk at top speed", 12, function()
		return TOP, 0
	end, 3)
	check(walkSteps >= 12, "walking at top speed should give heel strikes, got " .. walkSteps)
	check(walkWobble > math.rad(2), "a wobble should move while walking")

	-- Start from rest at the walker's acceleration, walk, coast to a stop, settle.
	local stopped, _, stoppedWobble = run("start, walk, stop", 16, function(t)
		if t < 8 then
			return TOP * ramp(t, 0, RISE), 0
		end
		return TOP * (1 - ramp(t, 8, FALL)), 0
	end)
	check(stopped.rate == 0, "phase should park after stopping")
	check(
		math.abs(stoppedWobble.x) < math.rad(0.5) and math.abs(stoppedWobble.z) < math.rad(0.5),
		"a wobble should settle after stopping"
	)
	for _, side in { "L", "R" } do
		check(
			math.abs(stopped.feet[side].z) <= MechGait.SETTLED * stopped.rig.scale,
			side .. " foot should settle under the hip"
		)
	end

	run("reverse at 40 %", 10, function(t)
		return -TOP * 0.4 * ramp(t, 0, 0.7), 0
	end)
	run("turn in place left", 10, function(t)
		return 0, TURN * ramp(t, 0, 0.5)
	end)
	run("turn in place right", 10, function(t)
		return 0, -TURN * ramp(t, 0, 0.5)
	end)
	run("walk and turn", 10, function(t)
		return TOP * ramp(t, 0, RISE), TURN * ramp(t, 2, 0.5)
	end)
	run("idle occupied", 30, function()
		return 0, 0
	end)

	-- Empty and still: the rest pose, hatch open.
	do
		local rig = MechGait.rig(PIVOTS)
		local state = MechGait.new(rig)
		MechGait.step(
			state,
			{
				forward = 0,
				yawRate = 0,
				occupied = false,
				topSpeed = TOP,
				turnRate = TURN,
				time = 0,
			},
			DT
		)
		local poses = MechGait.pose(state)
		for bone, pose in poses do
			if bone ~= "hatch" then
				local still = pose.Position.Magnitude < 1e-4
					and pose.LookVector:Dot(Vector3.new(0, 0, -1)) > 1 - 1e-6
				check(still, "empty mech: " .. bone .. " should be at rest")
			end
		end
		check(
			math.abs(math.deg(state.raw.hatch.x) + 100) < 1e-3,
			"empty mech: hatch should be open"
		)
	end
end

print(string.format("%d checks, %d failures", checks, failures))
if failures > 0 then
	process.exit(1)
end
