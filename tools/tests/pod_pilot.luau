-- Checks src/shared/PodPilot.luau (the pod flight math server PodFlight applies) outside Roblox.
-- Usage: lune run tools/tests/pod_pilot.luau
--
--   - every function gives the same bits (signed zeros and NaNs included; vectors and frames
--     component by component) and leaves the pod's yaw, speed, bank, pitch and phase as the
--     inline code it replaced in PodFlight.luau, copied below word for word as the reference, over
--     a sweep of inputs: zero, -0, negatives, values on each threshold and a hair either side,
--     math.huge, NaN
--   - the autopilot flown home step by step both ways from a spread of starting points
--   - a few plain values (constants, worked examples)

local luau = require("@lune/luau")
local roblox = require("@lune/roblox")

local Check = require("../lib/Check")
local Sandbox = require("../lib/Sandbox")

local check, equal = Check.check, Check.equal
local Vector3 = roblox.Vector3
local CFrame = Sandbox.CFrame

Check.printLimit = 10

local Shared = Sandbox.game:GetService("ReplicatedStorage").Shared
local MathUtil = Sandbox.require(Shared.MathUtil)
local Names = Sandbox.require(Shared.Names)
local PodState = Sandbox.require(Shared.PodState)
local PodPilot = Sandbox.require(Shared.PodPilot)

-- The inline code PodPilot replaced, from PodFlight.luau at 9ceb919, word for word inside
-- functions that take its free variables as arguments: `now` for os.clock(), `height` for
-- clearance(pod), `target` for dock(pod), `docked` for docked(pod), a hit's Y for the raycast.
-- Pods are plain tables; `mover`, `aligner` and `prompt` collect the properties written to them.
-- Compiled with luau.load, as Sandbox.require compiles PodPilot.
local Reference = luau.load(
	[[
local Reference = {}

local SPEED = 100 -- top forward speed, studs/s
local REVERSE = 0.4 -- of SPEED
local ACCELERATION = 45 -- studs/s^2
local TURN_RATE = 1.6 -- rad/s at full steer
local CLIMB = 28 -- studs/s at full lift
local CLEARANCE = 4 -- the pod's root never goes lower than this over the ground
local CEILING = 400 -- nor higher than this
local LAUNCH_RISE = 16 -- studs/s straight up for LAUNCH_TIME after letting go
local LAUNCH_TIME = 1
local BANK = math.rad(18) -- roll at full steer
local PITCH = math.rad(8) -- nose down at top speed
local LIFT_PITCH = math.rad(14) -- nose up at full climb (E), down at full descent (Q)
local TILT_RATE = 3 -- 1/s: how fast the bank and pitch follow

local LAND_HEIGHT = 15 -- LAND works with the root this close over the ground
local HOVER = 1.2 -- a landed pod's root over the ground (its hull starts 0.5 above the root)

local HOME_HEIGHT = 25 -- the autopilot crosses this high over the dock
local HOME_SPEED = 60
local HOME_TURN = 2.2 -- rad/s
local DESCENT = 12 -- fastest settle, studs/s
local DOCK_DISTANCE = 0.3 -- studs from the dock that count as docked
local DOCK_ANGLE = math.rad(2)
local HOME_TIMEOUT = 60 -- seconds; past this the pod snaps onto the dock

Reference.CEILING, Reference.LAND_HEIGHT = CEILING, LAND_HEIGHT
Reference.HOME_TIMEOUT = HOME_TIMEOUT

-- setState: the launch prompt.
function Reference.prompt(pod, state)
	pod.prompt.ActionText = if PodState.isAtRest(state) then "Launch" else "Return home"
	pod.prompt.Enabled = state ~= PodState.RETURNING and state ~= PodState.WRECKED
end

-- The pilot's controls.
function Reference.fly(pod, dt, now, height)
	pod.yaw = MathUtil.wrapAngle(pod.yaw - pod.steer * TURN_RATE * dt)
	local target = pod.throttle * SPEED
	if pod.throttle < 0 then
		target = pod.throttle * SPEED * REVERSE
	end
	pod.speed = MathUtil.moveToward(pod.speed, target, ACCELERATION * dt)

	local rise = pod.lift * CLIMB
	if now - pod.launchedAt < LAUNCH_TIME then
		rise = math.max(rise, LAUNCH_RISE)
	end
	local canLand = height < LAND_HEIGHT
	if pod.model:GetAttribute(Names.Attributes.PodCanLand) ~= canLand then
		pod.model:SetAttribute(Names.Attributes.PodCanLand, canLand)
	end
	if height < CLEARANCE then
		rise = math.max(rise, (CLEARANCE - height) * 4)
	elseif height > CEILING then
		rise = math.min(rise, 0)
	end

	local heading = CFrame.Angles(0, pod.yaw, 0)
	pod.mover.VectorVelocity = heading.LookVector * pod.speed + Vector3.new(0, rise, 0)
	local follow = MathUtil.rateAlpha(TILT_RATE, dt)
	pod.bank += (-pod.steer * BANK - pod.bank) * follow
	local pitch = -PITCH * pod.speed / SPEED + LIFT_PITCH * pod.lift
	pod.pitch += (pitch - pod.pitch) * follow
	pod.aligner.CFrame = heading * CFrame.Angles(pod.pitch, 0, pod.bank)
end

-- The autopilot: climb to HOME_HEIGHT over the dock, cross to above it, settle onto it.
function Reference.returnHome(pod, dt, now, target, docked)
	local position = pod.root.Position
	if now - pod.returningSince > HOME_TIMEOUT then
		docked(pod)
		return
	end
	local cruise = math.max(target.Position.Y + HOME_HEIGHT, position.Y)
	local flat = Vector3.new(target.Position.X - position.X, 0, target.Position.Z - position.Z)
	local distance = flat.Magnitude
	local dockYaw = MathUtil.yawOf(target.LookVector)
	local wantYaw = dockYaw
	local velocity = Vector3.zero

	if pod.phase == "climb" then
		velocity = Vector3.new(0, CLIMB, 0)
		if position.Y >= target.Position.Y + HOME_HEIGHT - 1 or distance < 1 then
			pod.phase = "cross"
		end
	elseif pod.phase == "cross" then
		local pace = math.min(HOME_SPEED, distance * 1.5)
		velocity = if distance > 0.01 then flat.Unit * pace else Vector3.zero
		velocity += Vector3.new(0, math.clamp((cruise - position.Y) * 2, -CLIMB, CLIMB), 0)
		if distance > 8 then
			wantYaw = MathUtil.yawOf(flat)
		end
		if distance < 0.6 and math.abs(MathUtil.wrapAngle(pod.yaw - dockYaw)) < DOCK_ANGLE then
			pod.phase = "settle"
		end
	else
		local drop = position.Y - target.Position.Y
		local correction = flat * 4
		if correction.Magnitude > 6 then
			correction = correction.Unit * 6
		end
		local down = if distance > DOCK_DISTANCE and drop < 1
			then 0
			else math.clamp(drop * 1.2 + 0.8, 0.8, DESCENT)
		velocity = correction - Vector3.new(0, down, 0)
		if
			(target.Position - position).Magnitude < DOCK_DISTANCE
			and math.abs(MathUtil.wrapAngle(pod.yaw - dockYaw)) < DOCK_ANGLE
		then
			docked(pod)
			return
		end
	end

	local turn = MathUtil.wrapAngle(wantYaw - pod.yaw)
	pod.yaw = MathUtil.wrapAngle(pod.yaw + math.clamp(turn, -HOME_TURN * dt, HOME_TURN * dt))
	local follow = MathUtil.rateAlpha(TILT_RATE, dt)
	pod.bank += (0 - pod.bank) * follow
	pod.pitch += (0 - pod.pitch) * follow
	pod.mover.VectorVelocity = velocity
	pod.aligner.CFrame = CFrame.Angles(0, pod.yaw, 0) * CFrame.Angles(pod.pitch, 0, pod.bank)
end

-- putOutside: where the rider stands. `hitY` nil: the ray hit nothing.
function Reference.level(pod, sideways, hitY)
	local spot = pod.root.CFrame * pod.exit * CFrame.new(sideways, 0, 0)
	local hit = if hitY then { Position = Vector3.new(0, hitY, 0) } else nil
	local groundY = if hit then hit.Position.Y else spot.Position.Y - pod.exit.Position.Y
	local level = spot.Rotation
		+ Vector3.new(spot.Position.X, groundY + pod.exit.Position.Y, spot.Position.Z)
	return level
end

-- land: each passenger's side.
function Reference.sideways(index)
	return if index % 2 == 1 then -3.5 else 3.5
end

-- A landed pod hovers HOVER over the ground, level, where it is.
function Reference.hover(pod, height)
	local rise = if height == math.huge then 0 else math.clamp((HOVER - height) * 3, -6, 6)
	pod.mover.VectorVelocity = Vector3.new(0, rise, 0)
	pod.pitch, pod.bank = 0, 0
	pod.aligner.CFrame = CFrame.Angles(0, pod.yaw, 0)
end

return Reference
]],
	{
		debugName = "PodFlight reference",
		environment = {
			CFrame = CFrame,
			Vector3 = Vector3,
			MathUtil = MathUtil,
			Names = Names,
			PodState = PodState,
		},
	}
)()

-- Same bits: -0 differs from 0, a NaN equals the same NaN; vectors, frames and tables compare
-- part by part.
local function same(a: any, b: any): boolean
	local kind = typeof(a)
	if kind ~= typeof(b) then
		return false
	elseif kind == "number" then
		return string.pack("<d", a) == string.pack("<d", b)
	elseif kind == "Vector3" then
		return same(a.X, b.X) and same(a.Y, b.Y) and same(a.Z, b.Z)
	elseif kind == "CFrame" then
		return same({ a:GetComponents() }, { b:GetComponents() })
	elseif kind == "table" then
		for key, value in a do
			if not same(value, b[key]) then
				return false
			end
		end
		for key in b do
			if a[key] == nil then
				return false
			end
		end
		return true
	end
	return a == b
end
local function show(...: any): string
	local parts = {}
	for index = 1, select("#", ...) do
		local value = select(index, ...)
		table.insert(
			parts,
			if type(value) == "number" then string.format("%.17g", value) else tostring(value)
		)
	end
	return table.concat(parts, ", ")
end

-- A walker model's attributes, as the reference reads and writes them.
local function fakeModel(canLand: any): any
	local attributes = { [Names.Attributes.PodCanLand] = canLand }
	return {
		attributes = attributes,
		GetAttribute = function(_, name)
			return attributes[name]
		end,
		SetAttribute = function(_, name, value)
			attributes[name] = value
		end,
	}
end

-- Counts a check; builds the failure message (`what`, then `label()`) only on a failure.
local function checkSame(got: any, want: any, what: string, label: () -> string)
	if same(got, want) then
		check(true, what)
	else
		check(false, what .. " " .. label())
	end
end

local nan = 0 / 0
local inf = math.huge
local DTS = { 0, 1 / 240, 1 / 60, 1 / 30, 0.5, nan }

-- Constants ---------------------------------------------------------------------------------------

Check.section("PodPilot constants")
equal(PodPilot.CEILING, Reference.CEILING, "CEILING")
equal(PodPilot.LAND_HEIGHT, Reference.LAND_HEIGHT, "LAND_HEIGHT")
equal(PodPilot.HOME_TIMEOUT, Reference.HOME_TIMEOUT, "HOME_TIMEOUT")

-- prompt ------------------------------------------------------------------------------------------

Check.section("PodPilot.prompt")
for _, state in { "docked", "flying", "returning", "landed", "wrecked" } do
	local pod = { prompt = {} }
	Reference.prompt(pod, state)
	local action, enabled = PodPilot.prompt(state :: any)
	equal(action, pod.prompt.ActionText, "ActionText " .. state)
	equal(enabled, pod.prompt.Enabled, "Enabled " .. state)
end
equal((PodPilot.prompt(PodState.DOCKED)), "Launch", "docked: Launch")
equal(select(2, PodPilot.prompt(PodState.RETURNING)), false, "returning: disabled")

-- fly ---------------------------------------------------------------------------------------------

Check.section("PodPilot.fly / canLand / rise")
local HEIGHTS = {
	-5,
	-0,
	0,
	3.9999999,
	4,
	4.0000001,
	10,
	14.999999,
	15,
	15.000001,
	399.99999,
	400,
	400.00001,
	5000,
	inf,
	nan,
}
local SINCE = { -1, 0, 0.5, 0.99999999, 1, 1.0000001, 30, nan }
local INPUTS = { -1, -0.35, -0, 0, 0.6, 1, nan }
local YAWS = { -math.pi, -0, 0, 7, nan }
local FLY_KEYS = { "yaw", "speed", "bank", "pitch", "throttle", "steer", "lift" }
local POD_SPEEDS = { -40, -0, 0, 0.3, 33.333333, 55, 71.1, 100, 140, nan }
local TILTS = { -0, 0.25, nan }

local function flyCase(state: any, height: number, since: number, dt: number, canLand: any)
	local now = 1000
	local pod = table.clone(state)
	pod.launchedAt = now - since
	pod.model = fakeModel(canLand)
	pod.mover, pod.aligner = {}, {}
	Reference.fly(pod, dt, now, height)

	local flight = table.clone(state)
	local wantCanLand = PodPilot.canLand(height)
	local velocity, attitude = PodPilot.fly(flight, height, now - pod.launchedAt, dt)
	local function label(): string
		return show(
			state.throttle,
			state.steer,
			state.lift,
			state.yaw,
			state.speed,
			state.bank,
			state.pitch,
			height,
			since,
			dt
		)
	end
	checkSame(velocity, pod.mover.VectorVelocity, "fly velocity", label)
	checkSame(attitude, pod.aligner.CFrame, "fly attitude", label)
	for _, key in FLY_KEYS do
		checkSame(flight[key], pod[key], "fly " .. key, label)
	end
	checkSame(wantCanLand, pod.model.attributes[Names.Attributes.PodCanLand], "canLand", label)
end

-- Every control and state value against a few heights; every height and launch time against a
-- few controls.
for _, throttle in INPUTS do
	for _, steer in INPUTS do
		for _, lift in INPUTS do
			for _, yaw in YAWS do
				for _, speed in POD_SPEEDS do
					for _, tilt in { 0.25 } do
						for _, height in { 2 } do
							local state = {
								throttle = throttle,
								steer = steer,
								lift = lift,
								yaw = yaw,
								speed = speed,
								bank = tilt,
								pitch = -tilt,
							}
							flyCase(state, height, 5, 1 / 60, false)
						end
					end
				end
			end
		end
	end
end
for _, lift in INPUTS do
	for _, height in HEIGHTS do
		for _, since in SINCE do
			for _, dt in DTS do
				for _, bank in TILTS do
					for _, canLand in { false, true } do
						local state = {
							throttle = 0.5,
							steer = -0.5,
							lift = lift,
							yaw = 0.3,
							speed = 20,
							bank = bank,
							pitch = 0.1,
						}
						flyCase(state, height, since, dt, canLand)
					end
				end
			end
		end
	end
end
equal(PodPilot.rise(0, 0, 50), 16, "rise: LAUNCH_RISE right after lift-off")
equal(PodPilot.rise(1, 5, 50), 28, "rise: CLIMB at full lift")
equal(PodPilot.rise(0, 5, 1), 12, "rise: pushed up below CLEARANCE")
equal(PodPilot.rise(1, 5, 401), 0, "rise: none above CEILING")
check(PodPilot.canLand(14.9) and not PodPilot.canLand(15), "canLand under 15")

-- home --------------------------------------------------------------------------------------------

Check.section("PodPilot.home")
local DOCKS = {
	CFrame.new(),
	CFrame.new(10, -4, 2.5),
	CFrame.new(3, 12, -7) * CFrame.Angles(0, math.rad(37), 0),
	CFrame.new(-2, 8, 0) * CFrame.Angles(0.3, -1.1, 2.0),
	CFrame.new(140, 0.2, -90) * CFrame.Angles(0, math.pi / 2, 0),
	CFrame.lookAt(Vector3.new(0, 1, 0), Vector3.new(5, 1, -3)),
}
-- Offsets from the dock: on it, inside and either side of each distance and height threshold.
local OFFSETS = {
	Vector3.zero,
	Vector3.new(-0, 0, -0),
	Vector3.new(0.1, 0.1, 0.1),
	Vector3.new(0.2999999, 0, 0),
	Vector3.new(0.3, 0, 0),
	Vector3.new(0, 0.3, 0),
	Vector3.new(0.005, 0.5, 0.005),
	Vector3.new(0.5, 0.99, 0),
	Vector3.new(0.59999, 3, 0),
	Vector3.new(0.6, 3, 0),
	Vector3.new(0, 0, 0.999999),
	Vector3.new(0, 0, 1),
	Vector3.new(1.4, 5, 1.4),
	Vector3.new(-6, 24, 0),
	Vector3.new(0, 23.999999, 30),
	Vector3.new(0, 24, 30),
	Vector3.new(7.9999, 26, 0),
	Vector3.new(8, 26, 0),
	Vector3.new(8.0001, 26, 0),
	Vector3.new(-30, 60, 45),
	Vector3.new(200, -10, -150),
	Vector3.new(nan, 0, 0),
}

-- One autopilot step both ways: the reference, and PodFlight's returnHome now (onDock while
-- settling, else home).
local HOME_KEYS = { "yaw", "bank", "pitch", "phase" }
local function homeCase(state: any, target: any, position: any, dt: number, label: () -> string)
	local pod = table.clone(state)
	pod.root = { Position = position }
	pod.mover, pod.aligner = {}, {}
	pod.returningSince = 0
	local refDocked = false
	Reference.returnHome(pod, dt, 1, target, function()
		refDocked = true
	end)

	local homing = table.clone(state)
	local arrived = homing.phase == "settle" and PodPilot.onDock(homing.yaw, target, position)
	local velocity, attitude
	if not arrived then
		velocity, attitude = PodPilot.home(homing, target, position, dt)
	end
	checkSame(arrived, refDocked, "home docked", label)
	checkSame(velocity, pod.mover.VectorVelocity, "home velocity", label)
	checkSame(attitude, pod.aligner.CFrame, "home attitude", label)
	for _, key in HOME_KEYS do
		checkSame(homing[key], pod[key], "home " .. key, label)
	end
	return homing, arrived, velocity
end

-- No NaN dt: math.clamp errors on a NaN bound, in both.
local HOME_DTS = { 0, 1 / 60, 0.5 }
local HOME_YAWS = { -math.pi, -0.02, -0.0349, -0, 0, 0.0349, 0.035, 1.2, math.pi, nan }
for dockIndex, target in DOCKS do
	local dockYaw = MathUtil.yawOf(target.LookVector)
	for offsetIndex, offset in OFFSETS do
		local position = target.Position + offset
		for _, phase in { "climb", "cross", "settle" } do
			for yawIndex, yaw in HOME_YAWS do
				-- The pod's yaw both as given and relative to the dock's, round DOCK_ANGLE.
				for _, relative in { false, true } do
					for _, tilt in { -0.3, nan } do
						for _, dt in HOME_DTS do
							local state = {
								yaw = if relative then MathUtil.wrapAngle(dockYaw + yaw) else yaw,
								bank = tilt,
								pitch = -tilt,
								phase = phase,
							}
							homeCase(state, target, position, dt, function()
								return show(
									dockIndex,
									offsetIndex,
									phase,
									yawIndex,
									relative,
									tilt,
									dt
								)
							end)
						end
					end
				end
			end
		end
	end
end

Check.section("PodPilot.home flown home")
-- Integrates the autopilot's velocity from each start until it docks (or 3000 steps), both ways,
-- comparing every step.
local STARTS = {
	Vector3.new(0, 2, 0),
	Vector3.new(60, 5, -80),
	Vector3.new(-300, 120, 40),
	Vector3.new(0.2, 40, 0),
}
local flown = 0
for dockIndex, target in DOCKS do
	for startIndex, start in STARTS do
		for _, startYaw in { 0, 2.5, -1 } do
			local state: any = { yaw = startYaw, bank = 0.2, pitch = -0.1, phase = "climb" }
			local position = target.Position + start
			local dt = 1 / 60
			for step = 1, 3000 do
				local homing, arrived, velocity = homeCase(state, target, position, dt, function()
					return show(dockIndex, startIndex, startYaw, step)
				end)
				if arrived then
					flown += 1
					break
				end
				state = homing
				position += velocity * dt
			end
		end
	end
end
equal(flown, #DOCKS * #STARTS * 3, "every flight docks")

-- hover -------------------------------------------------------------------------------------------

Check.section("PodPilot.hover")
for _, height in { -100, -2, -0, 0, 1.2, -0.8, 3.2, 3.20001, 10, 1e9, inf, -inf, nan } do
	for _, yaw in { -0, 0, 1.1, nan } do
		local pod = { yaw = yaw, pitch = 0.3, bank = -0.2, mover = {}, aligner = {} }
		Reference.hover(pod, height)
		check(same(PodPilot.hover(height), pod.mover.VectorVelocity), "hover " .. show(height))
		check(
			same(CFrame.Angles(0, yaw, 0), pod.aligner.CFrame),
			"hover attitude " .. show(height, yaw)
		)
	end
end
equal(PodPilot.hover(inf).Y, 0, "hover: still over nothing")
equal(PodPilot.hover(-100).Y, 6, "hover: at most 6 up")

-- standFrame / sideways ---------------------------------------------------------------------------

Check.section("PodPilot.standFrame / sideways")
local EXITS = {
	CFrame.new(0, 3, 6),
	CFrame.new(-2, 2.6, 8) * CFrame.Angles(0, math.pi, 0),
	CFrame.new(1, 0, 0),
	CFrame.new(0, -0, 4) * CFrame.Angles(0.2, 0.4, 0),
}
for rootIndex, rootFrame in DOCKS do
	for exitIndex, exit in EXITS do
		for _, sideways in { -3.5, 0, 3.5 } do
			for _, hitY in { false, -20, -0, 0, 4.5, 1e6, nan } do
				local pod = { root = { CFrame = rootFrame }, exit = exit }
				local want = Reference.level(pod, sideways, hitY or nil)
				local spot = rootFrame * exit * CFrame.new(sideways, 0, 0)
				local got = PodPilot.standFrame(spot, exit.Position.Y, hitY or nil)
				check(same(got, want), "standFrame " .. show(rootIndex, exitIndex, sideways, hitY))
			end
		end
	end
end
for index = 1, 40 do
	equal(PodPilot.sideways(index), Reference.sideways(index), "sideways " .. index)
end

Check.finish()
