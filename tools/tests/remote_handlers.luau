-- Checks the server's remote handlers apply src/shared/RemoteGuard, outside Roblox: each handler
-- runs with recording fakes behind its requires (shared modules real), and the clock is a fake.
-- Usage: lune run tools/tests/remote_handlers.luau
--
--   - Drive.onInput (DriveInput): a real client's input lands bit for bit; a non-finite throttle,
--     steer or lift becomes 0 (neutral); a wrong type is dropped; a realistic client (DriveAxes'
--     resend rule at 30, 60, 144 and 240 FPS, with keys, a sweeping stick, pod lift, network
--     jitter and a one-second stall) has every event applied; a flood past the limit is dropped;
--     Drive.forget resets a player's limit
--   - Firing.onFire (FireWeapon): a finite Vector3 aim fires; NaN, ±inf in any component, and
--     non-Vector3 aims do not
--   - limits are per player (one player's flood leaves another's events applied); a player who
--     left (Parent nil) is ignored by Drive.onInput (no limiter made) and Firing.onFire
--   - Admin.macCommand (MacCommand) SNIPER gives a sniper only when the backpack and character
--     hold none (Tools.holds)
--   - Admin.onCommand (AdminCommand): forwards command and three string arguments to Admin.run;
--     a non-string argument becomes nil; a non-string command is dropped

local roblox = require("@lune/roblox")

local Check = require("../lib/Check")
local Sandbox = require("../lib/Sandbox")

local check, equal = Check.check, Check.equal
local Vector3 = roblox.Vector3
local CFrame = Sandbox.CFrame

Check.printLimit = 10

local Shared = Sandbox.game:GetService("ReplicatedStorage").Shared
local Config = Sandbox.require(Shared.Config)
local DriveAxes = Sandbox.require(Shared.DriveAxes)
local Names = Sandbox.require(Shared.Names)
local WeaponCatalog = Sandbox.require(Shared.WeaponCatalog)

local NAN = 0 / 0
local INF = math.huge

local function sameBits(a: number, b: number): boolean
	if a ~= a and b ~= b then
		return true
	end
	return a == b and (a ~= 0 or 1 / a == 1 / b)
end

-- An instance path stand-in: `require(node)` sees the last name in the path; a method call on
-- it (`:FindFirstChild`) answers nil.
local function node(name: string): any
	return setmetatable({}, {
		__index = function(_, key)
			if key == "__name" then
				return name
			end
			return node(key)
		end,
		__call = function()
			return nil
		end,
	})
end

-- Answers any field read or call with itself: the requires a test does not fake.
local stub = setmetatable({}, {
	__index = function(self)
		return self
	end,
	__call = function(self)
		return self
	end,
})

-- Loads a server module with `fakes` behind its requires (by module name); shared modules are
-- real, any other require is `stub`. `os` is a fake whose clock the test sets.
local clock = 0
local fakeOs = setmetatable({
	clock = function()
		return clock
	end,
}, { __index = os })
local function loadWith(path: string, fakes: { [string]: any }): any
	return Sandbox.load(path, {
		game = {
			GetService = function(_, service)
				return node(service)
			end,
		},
		script = node("script"),
		os = fakeOs,
		require = function(target)
			local name = target.__name
			if fakes[name] then
				return fakes[name]
			end
			local ok, shared = pcall(Sandbox.require, Shared[name])
			return if ok then shared else stub
		end,
	})
end

-- The Players service a fake player's Parent is; a player who left has Parent nil.
local PLAYERS = {}

-- Drive.onInput ---------------------------------------------------------------------------------

local podInputs: { { number } } = {}
local cars: { [any]: any } = {}
local Drive = loadWith("src/server/systems/Vehicles/Drive.luau", {
	Characters = {
		humanoidOf = function(player)
			return player.humanoid
		end,
	},
	Climb = { stopClimb = function() end, climbStep = function() end },
	PodFlight = {
		input = function(_, throttle, steer, lift)
			table.insert(podInputs, { throttle, steer, lift })
		end,
	},
	Registry = {
		cars = cars,
		setLimits = function() end,
		legsDriverSeat = function(car)
			return car.seat
		end,
	},
})

-- A player seated in a pod car's driver seat (docked: the seat drives the legs too).
local function seatedPlayer(): (any, any)
	local model = {}
	local seat = { Parent = model }
	local car = { seat = seat, pod = {}, throttle = 0, steer = 0 }
	cars[model] = car
	return { humanoid = { SeatPart = seat }, Parent = PLAYERS }, car
end

Check.section("Drive.onInput: values")
do
	local player, car = seatedPlayer()
	clock = 0
	Drive.onInput(player, 0.75, -0.25, 1)
	equal(car.throttle, 0.75, "throttle")
	equal(car.steer, -0.25, "steer")
	local last = podInputs[#podInputs]
	check(last[1] == 0.75 and last[2] == -0.25 and last[3] == 1, "the pod gets all three")

	Drive.onInput(player, 2, -2, -5)
	check(car.throttle == 1 and car.steer == -1, "out of range: clamped")
	equal(podInputs[#podInputs][3], -1, "lift clamped")

	for _, bad in { NAN, INF, -INF } do
		Drive.onInput(player, bad, 0.5, 0.5)
		check(
			sameBits(car.throttle, 0) and car.steer == 0.5,
			("throttle %s: got %s, %s; want 0, 0.5"):format(
				tostring(bad),
				tostring(car.throttle),
				tostring(car.steer)
			)
		)
		Drive.onInput(player, 0.5, bad, 0.5)
		check(
			car.throttle == 0.5 and sameBits(car.steer, 0),
			("steer %s: got %s, %s; want 0.5, 0"):format(
				tostring(bad),
				tostring(car.throttle),
				tostring(car.steer)
			)
		)
		Drive.onInput(player, 0.5, 0.5, bad)
		local lift = podInputs[#podInputs][3]
		check(sameBits(lift, 0), ("lift %s: got %s, want 0"):format(tostring(bad), tostring(lift)))
	end

	Drive.onInput(player, 0.3, 0.3, 0)
	local count = #podInputs
	Drive.onInput(player, "1", 0.5, 0)
	Drive.onInput(player, 0.5, nil, 0)
	check(car.throttle == 0.3 and car.steer == 0.3, "a wrong type is dropped")
	equal(#podInputs, count, "a wrong type never reaches the pod")
	Drive.onInput(player, 0.4, 0.4, "up")
	equal(podInputs[#podInputs][3], 0, "a non-number lift is 0 (as before)")
end

Check.section("Drive.onInput: a realistic client is never limited")
-- A client at `fps` (frame times jittered ±20%) for `seconds`: W held and released, a stick sweep
-- (fast enough to send on most frames), A/D taps, E/Q for the pod. DriveAxes.send decides each
-- frame; a sent event arrives after 30-300 ms of latency, in order (a reliable remote), and those
-- sent during second 5 arrive together at 6 s.
local function replay(fps: number, seconds: number): (number, number)
	local player, car = seatedPlayer()
	math.randomseed(fps)
	local function between(low: number, high: number): number
		return low + (high - low) * math.random()
	end
	local sent = DriveAxes.newSent()
	local now, lastArrival, sends, applied = 0, 0, 0, 0
	while now < seconds do
		now += (1 / fps) * between(0.8, 1.2)
		local phase = now % 4
		local throttle, steer
		if phase < 1 then
			throttle, steer = DriveAxes.keysOrSeat(1, 0, 0, 0) -- W
		elseif phase < 2 then
			throttle, steer = math.sin(now * 20), math.cos(now * 20) -- stick sweep
		elseif phase < 3 then
			throttle, steer = DriveAxes.keysOrSeat(0, if now % 0.5 < 0.25 then 1 else -1, 0, 0)
		else
			throttle, steer = 0, 0
		end
		throttle, steer = DriveAxes.clamp(throttle, steer)
		local lift = DriveAxes.lift(if now % 1 < 0.5 then 1 else 0, 0)
		if DriveAxes.send(sent, throttle, steer, lift, now) then
			sends += 1
			local arrives = math.max(lastArrival, now + between(0.03, 0.3))
			if now >= 5 and now < 6 then
				arrives = math.max(arrives, 6)
			end
			lastArrival = arrives
			clock = arrives
			car.throttle, car.steer = NAN, NAN
			Drive.onInput(player, throttle, steer, lift)
			if sameBits(car.throttle, throttle) and sameBits(car.steer, steer) then
				applied += 1
			end
		end
	end
	return sends, applied
end
for _, fps in { 30, 60, 144, 240 } do
	local sends, applied = replay(fps, 60)
	check(sends > 0, fps .. " FPS: the client sends")
	equal(applied, sends, fps .. " FPS: events applied of " .. sends .. " sent")
end

Check.section("Drive.onInput: a flood is limited")
do
	local player, car = seatedPlayer()
	clock = 1000
	local applied = 0
	for _ = 1, 5000 do
		car.throttle = NAN
		Drive.onInput(player, 0.5, 0.5, 0)
		if car.throttle == 0.5 then
			applied += 1
		end
		clock += 1 / 50000 -- 5000 events in 0.1 s
	end
	check(applied < 5000, "5000 events in 0.1 s: some are dropped (applied " .. applied .. ")")
	check(applied >= 240, "the burst passes first (applied " .. applied .. ")")
	check(type(Drive.forget) == "function", "Drive.forget exists (PlayerRemoving)")
	if type(Drive.forget) == "function" then
		Drive.forget(player)
		car.throttle = NAN
		Drive.onInput(player, 0.25, 0.25, 0)
		equal(car.throttle, 0.25, "after forget the player starts with a full bucket")
	end
end

Check.section("Drive.onInput: limits are per player")
do
	local flooder = seatedPlayer()
	local other, otherCar = seatedPlayer()
	clock = 2000
	for _ = 1, 2000 do
		Drive.onInput(flooder, 0.5, 0.5, 0)
	end
	otherCar.throttle = NAN
	Drive.onInput(other, 0.75, 0, 0)
	equal(otherCar.throttle, 0.75, "after A floods, B's next event is applied")
end

Check.section("Drive.onInput: a player who left")
do
	-- Drive with RemoteGuard wrapped to count the limiters it makes.
	local made = 0
	local RemoteGuard = Sandbox.require(Shared.RemoteGuard)
	local counted = setmetatable({
		newLimiter = function(...)
			made += 1
			return RemoteGuard.newLimiter(...)
		end,
	}, { __index = RemoteGuard })
	local CountedDrive = loadWith("src/server/systems/Vehicles/Drive.luau", {
		RemoteGuard = counted,
		Characters = {
			humanoidOf = function(player)
				return player.humanoid
			end,
		},
		Climb = { stopClimb = function() end, climbStep = function() end },
		PodFlight = { input = function() end },
		Registry = {
			cars = cars,
			setLimits = function() end,
			legsDriverSeat = function(car)
				return car.seat
			end,
		},
	})
	local player, car = seatedPlayer()
	clock = 3000
	CountedDrive.onInput(player, 0.5, 0.5, 0)
	equal(made, 1, "a limiter for the player")
	CountedDrive.forget(player)
	player.Parent = nil
	car.throttle = NAN
	CountedDrive.onInput(player, 0.25, 0.25, 0)
	equal(made, 1, "an event after the player left makes no limiter")
	check(car.throttle ~= car.throttle, "an event after the player left is not applied")
end

-- Firing.onFire ---------------------------------------------------------------------------------

local fired: { any } = {}
local Firing = loadWith("src/server/systems/Weapons/Firing.luau", {
	WeaponSounds = { fire = function() end },
	Tools = {
		modelFor = function()
			return {}
		end,
	},
	kinds = setmetatable({}, {
		__index = function()
			return function(shot)
				table.insert(fired, shot)
			end
		end,
	}),
})

local weapon = WeaponCatalog.ALL[1]
-- A living player holding `weapon`, standing well outside the lobby.
local function armedPlayer(): any
	local position = Vector3.new(Config.LOBBY_RADIUS + 100, 5, 0)
	local parts = {
		Tool = {
			GetAttribute = function(_, name)
				return if name == Names.Attributes.WeaponId then weapon.id else nil
			end,
			FindFirstChild = function()
				return nil
			end,
		},
		Humanoid = { Health = 100 },
		HumanoidRootPart = { Anchored = false, Position = position, CFrame = CFrame.new(position) },
		Head = { Position = position + Vector3.new(0, 1.5, 0) },
	}
	local character = {
		FindFirstChildOfClass = function(_, className)
			return parts[className]
		end,
		FindFirstChild = function(_, name)
			return parts[name]
		end,
	}
	return { Character = character, Parent = PLAYERS }
end

Check.section("Firing.onFire: aim")
do
	clock = 5000
	local before = #fired
	local aim = Vector3.new(Config.LOBBY_RADIUS + 100, 5, 50)
	Firing.onFire(armedPlayer(), weapon.id, aim)
	equal(#fired, before + 1, "a finite Vector3 aim fires")
	if #fired > before then
		equal(fired[#fired].aim, aim, "the shot keeps the aim")
	end
	for axis = 1, 3 do
		for _, bad in { NAN, INF, -INF } do
			local parts = { aim.X, aim.Y, aim.Z }
			parts[axis] = bad
			local count = #fired
			Firing.onFire(armedPlayer(), weapon.id, Vector3.new(parts[1], parts[2], parts[3]))
			equal(
				#fired,
				count,
				("aim component %d = %s does not fire"):format(axis, tostring(bad))
			)
		end
	end
	for _, bad in { nil, 1, "aim", { X = 1, Y = 2, Z = 3 }, CFrame.new() } do
		local count = #fired
		Firing.onFire(armedPlayer(), weapon.id, bad)
		equal(#fired, count, "a " .. typeof(bad) .. " aim does not fire")
	end
end

Check.section("Firing.onFire: a player who left")
do
	clock = 6000
	local player = armedPlayer()
	player.Parent = nil
	local count = #fired
	Firing.onFire(player, weapon.id, Vector3.new(Config.LOBBY_RADIUS + 100, 5, 50))
	equal(#fired, count, "a player who left does not fire")
end

-- Admin.onCommand -------------------------------------------------------------------------------

Check.section("Admin.onCommand")
do
	local Admin = loadWith("src/server/systems/Admin.luau", {})
	check(type(Admin.onCommand) == "function", "Admin.onCommand exists (the AdminCommand handler)")
	if type(Admin.onCommand) == "function" then
		local runs: { { any } } = {}
		Admin.run = function(...)
			table.insert(runs, table.pack(...))
		end
		local player = {}
		Admin.onCommand(player, "give", "bob", "mac", "permanent")
		local run = runs[1]
		check(run ~= nil, "a valid command runs")
		if run then
			check(run[1] == player and run[2] == "give", "caller and command")
			check(run[3] == "bob" and run[4] == "mac", "target and item")
			equal(run[5], "permanent", "the third argument")
		end
		Admin.onCommand(player, "give", 1, {}, true)
		local typed = runs[2]
		check(
			typed ~= nil and typed[3] == nil and typed[4] == nil and typed[5] == nil,
			"non-string arguments become nil"
		)
		Admin.onCommand(player, 5, "bob")
		equal(#runs, 2, "a non-string command is dropped")
	end
end

-- MAC SNIPER ------------------------------------------------------------------------------------

Check.section("MAC SNIPER: one sniper at a time")
do
	local Tools = loadWith("src/server/systems/Weapons/Tools.luau", {})
	local function tool(id: string): any
		return {
			IsA = function(_, className)
				return className == "Tool"
			end,
			GetAttribute = function(_, name)
				return if name == Names.Attributes.WeaponId then id else nil
			end,
		}
	end
	local function container(): any
		local children = {}
		return {
			children = children,
			GetChildren = function()
				return table.clone(children)
			end,
		}
	end
	local backpack, character = container(), container()
	local player = {
		Parent = PLAYERS,
		Character = character,
		FindFirstChildOfClass = function(_, className)
			return if className == "Backpack" then backpack else nil
		end,
	}
	local gives = 0
	local Admin = loadWith("src/server/systems/Admin.luau", {
		MacAccess = {
			has = function()
				return true
			end,
		},
		Weapons = {
			give = function(_, id)
				gives += 1
				table.insert(backpack.children, tool(id))
				return true
			end,
			holds = Tools.holds,
		},
	})
	check(type(Admin.macCommand) == "function", "Admin.macCommand exists (the MacCommand handler)")
	check(type(Tools.holds) == "function", "Tools.holds exists")
	if type(Admin.macCommand) == "function" and type(Tools.holds) == "function" then
		local RemoteActions = Sandbox.require(Shared.RemoteActions)
		local SNIPER = RemoteActions.MacCommand.SNIPER
		table.insert(backpack.children, tool("rocket"))
		Admin.macCommand(player, SNIPER)
		equal(gives, 1, "no sniper held (another weapon is): SNIPER gives one")
		Admin.macCommand(player, SNIPER)
		equal(gives, 1, "a sniper in the backpack: SNIPER gives nothing")
		local sniper = table.remove(backpack.children) :: any
		table.insert(character.children, sniper)
		Admin.macCommand(player, SNIPER)
		equal(gives, 1, "a sniper in hand: SNIPER gives nothing")
		table.clear(character.children)
		Admin.macCommand(player, SNIPER)
		equal(gives, 2, "after the sniper is lost: SNIPER gives one again")
		player.Character = nil
		table.clear(backpack.children)
		Admin.macCommand(player, SNIPER)
		equal(gives, 3, "no character: the backpack decides")
	end
end

Check.finish()
