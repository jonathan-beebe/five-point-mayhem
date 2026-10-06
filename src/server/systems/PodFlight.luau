-- Flying pods (VehicleModel.PodSpec). A walker whose cab can leave its legs: the pilot presses the
-- console's launch button (its prompt, or the screen button via the PodCommand remote) and the
-- pod bone's joint lets go, so the pod (that bone and every piece, hull box, seat and cab welded to
-- it) becomes its own body. The legs park where they stand.
--
-- The server simulates the pod, as it does a driven vehicle. In flight the pilot's throttle and
-- steer (DriveInput) fly and turn it and `lift` climbs or descends; with no lift it holds its
-- height, and it never sinks below CLEARANCE over the ground. RETURN HOME (or the pilot dying or
-- leaving the game) hands it to the autopilot: climb above the legs, fly over them, turn to their
-- heading, settle onto them, and the joint takes hold again. While the pod flies the seat is
-- locked: a pilot who gets out is put back. While the pod is away another player can drive the
-- legs from their saddle (Vehicles); RETURN HOME puts that rider on the ground first.
--
-- Passenger seats ride along. They are locked in flight too; a passenger who dies stays out.
--
-- Within LAND_HEIGHT of the ground the pilot can LAND: the pod settles to hover just over the
-- ground and everyone aboard is put outside, behind it, to explore. Its Board prompt (E) seats
-- whoever walks up, the pilot's seat first. It stays landed until the pilot presses LAUNCH, so
-- the others can board too.
--
-- The model's PodState attribute ("docked", "flying", "returning", "landed", "wrecked") tells
-- clients what is going on, PodCanLand whether the pod is low enough to land; PodBone names the
-- bone that flies. A wrecked pod (Vehicles) is dead: no controls, no autopilot, no seat locks.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Remotes = require(ReplicatedStorage.Shared.Remotes)

local PodFlight = {}

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
local BOARD_REACH = 14

local HOME_HEIGHT = 25 -- the autopilot crosses this high over the dock
local HOME_SPEED = 60
local HOME_TURN = 2.2 -- rad/s
local DESCENT = 12 -- fastest settle, studs/s
local DOCK_DISTANCE = 0.3 -- studs from the dock that count as docked
local DOCK_ANGLE = math.rad(2)
local HOME_TIMEOUT = 60 -- seconds; past this the pod snaps onto the dock

local WRECK_FRICTION = 0.8 -- a wrecked pod's hull away from its legs

export type State = "docked" | "flying" | "returning" | "landed" | "wrecked"

export type Pod = {
	model: Model,
	skid: BasePart,
	seat: VehicleSeat,
	root: BasePart, -- the pod bone
	joint: Motor6D, -- the pod bone's joint to its parent
	mover: LinearVelocity,
	aligner: AlignOrientation,
	jets: { ParticleEmitter },
	prompt: ProximityPrompt,
	board: ProximityPrompt, -- a landed pod's way back in
	eject: (Player) -> (), -- puts a player standing in the cab outside
	exit: CFrame, -- where a landing pilot stands, relative to `root` (height from the ground)
	legsSeat: VehicleSeat?, -- drives the legs while the pod is away (Vehicles)
	dismount: (Humanoid) -> (), -- takes a rider off the legs and puts them on the ground
	passengers: { Seat },
	riders: { [Seat]: Humanoid }, -- each passenger seat's last occupant
	state: State,
	pilot: Humanoid?,
	throttle: number,
	steer: number,
	lift: number,
	yaw: number,
	speed: number, -- forward, studs/s
	bank: number,
	pitch: number,
	launchedAt: number,
	returningSince: number,
	phase: "climb" | "cross" | "settle",
}

local pods: { [Model]: Pod } = {}

local function moveToward(current: number, target: number, step: number): number
	if current < target then
		return math.min(current + step, target)
	end
	return math.max(current - step, target)
end

local function wrap(angle: number): number
	return (angle + math.pi) % (2 * math.pi) - math.pi
end

local function yawOf(cframe: CFrame): number
	local look = cframe.LookVector
	return math.atan2(-look.X, -look.Z)
end

-- Where the pod bone sits when docked: the joint's rest frame on its parent bone.
local function dock(pod: Pod): CFrame
	local joint = pod.joint
	return (joint.Part0 :: BasePart).CFrame * joint.C0 * joint.C1:Inverse()
end

-- Height of the pod's root over whatever is under it (not the walker itself).
local function clearance(pod: Pod): number
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { pod.model }
	local origin = pod.root.Position
	local hit = workspace:Raycast(origin, Vector3.new(0, -CEILING - 50, 0), params)
	return if hit then origin.Y - hit.Position.Y else math.huge
end

-- The seat Board fills: the pilot's if it is free, otherwise a free passenger seat.
local function freeSeat(pod: Pod): (Seat | VehicleSeat)?
	if not pod.seat.Occupant then
		return pod.seat
	end
	for _, seat in pod.passengers do
		if not seat.Occupant then
			return seat
		end
	end
	return nil
end

local function setState(pod: Pod, state: State)
	pod.state = state
	pod.model:SetAttribute("PodState", state)
	pod.prompt.ActionText = if state == "docked" or state == "landed"
		then "Launch"
		else "Return home"
	pod.prompt.Enabled = state ~= "returning" and state ~= "wrecked"
	pod.board.Enabled = state == "landed" and freeSeat(pod) ~= nil
	for _, jet in pod.jets do
		jet.Enabled = state == "flying" or state == "returning"
	end
	if state ~= "flying" then
		pod.model:SetAttribute("PodCanLand", false)
	end
end

local function launch(pod: Pod)
	if pod.state == "landed" then
		pod.launchedAt = os.clock() -- the lift-off rise, as from the legs
		setState(pod, "flying")
		return
	end
	if pod.state ~= "docked" then
		return
	end
	-- Nobody rides along standing in the cab.
	local cab = pod.model:FindFirstChild("Cab") :: BasePart?
	if cab then
		for _, player in Players:GetPlayers() do
			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if humanoid and root and not humanoid.SeatPart then
				local offset = cab.CFrame:PointToObjectSpace(root.Position)
				local half = cab.Size / 2
				if
					math.abs(offset.X) <= half.X
					and math.abs(offset.Y) <= half.Y
					and math.abs(offset.Z) <= half.Z
				then
					pod.eject(player)
				end
			end
		end
	end

	local root = pod.root
	pod.joint.Enabled = false
	pcall(root.SetNetworkOwner, root, nil)
	local mass = root.AssemblyMass
	pod.mover.MaxForce = mass * (workspace.Gravity + 400)
	pod.mover.VectorVelocity = Vector3.zero
	pod.yaw = yawOf(root.CFrame)
	pod.aligner.CFrame = CFrame.Angles(0, pod.yaw, 0)
	pod.mover.Enabled = true
	pod.aligner.Enabled = true
	pod.speed, pod.bank, pod.pitch = 0, 0, 0
	pod.launchedAt = os.clock()
	setState(pod, "flying")
end

local function goHome(pod: Pod)
	if pod.state ~= "flying" then
		return
	end
	-- The pod docks onto the legs' saddle: whoever rides the legs goes to the ground first.
	local rider = pod.legsSeat and pod.legsSeat.Occupant
	if rider then
		pod.dismount(rider)
	end
	pod.phase = "climb"
	pod.returningSince = os.clock()
	setState(pod, "returning")
end

local function docked(pod: Pod)
	pod.mover.Enabled = false
	pod.aligner.Enabled = false
	pod.root.CFrame = dock(pod) -- moves the whole pod
	pod.root.AssemblyLinearVelocity = Vector3.zero
	pod.root.AssemblyAngularVelocity = Vector3.zero
	pod.joint.Enabled = true
	setState(pod, "docked")
end

-- The pilot's controls.
local function fly(pod: Pod, dt: number)
	pod.yaw = wrap(pod.yaw - pod.steer * TURN_RATE * dt)
	local target = pod.throttle * SPEED
	if pod.throttle < 0 then
		target = pod.throttle * SPEED * REVERSE
	end
	pod.speed = moveToward(pod.speed, target, ACCELERATION * dt)

	local rise = pod.lift * CLIMB
	if os.clock() - pod.launchedAt < LAUNCH_TIME then
		rise = math.max(rise, LAUNCH_RISE)
	end
	local height = clearance(pod)
	local canLand = height < LAND_HEIGHT
	if pod.model:GetAttribute("PodCanLand") ~= canLand then
		pod.model:SetAttribute("PodCanLand", canLand)
	end
	if height < CLEARANCE then
		rise = math.max(rise, (CLEARANCE - height) * 4)
	elseif height > CEILING then
		rise = math.min(rise, 0)
	end

	local heading = CFrame.Angles(0, pod.yaw, 0)
	pod.mover.VectorVelocity = heading.LookVector * pod.speed + Vector3.new(0, rise, 0)
	local follow = 1 - math.exp(-TILT_RATE * dt)
	pod.bank += (-pod.steer * BANK - pod.bank) * follow
	local pitch = -PITCH * pod.speed / SPEED + LIFT_PITCH * pod.lift
	pod.pitch += (pitch - pod.pitch) * follow
	pod.aligner.CFrame = heading * CFrame.Angles(pod.pitch, 0, pod.bank)
end

-- The autopilot: climb to HOME_HEIGHT over the dock, cross to above it, settle onto it.
local function returnHome(pod: Pod, dt: number)
	local target = dock(pod)
	local position = pod.root.Position
	if os.clock() - pod.returningSince > HOME_TIMEOUT then
		docked(pod)
		return
	end
	local cruise = math.max(target.Position.Y + HOME_HEIGHT, position.Y)
	local flat = Vector3.new(target.Position.X - position.X, 0, target.Position.Z - position.Z)
	local distance = flat.Magnitude
	local dockYaw = yawOf(target)
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
			wantYaw = math.atan2(-flat.X, -flat.Z)
		end
		if distance < 0.6 and math.abs(wrap(pod.yaw - dockYaw)) < DOCK_ANGLE then
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
			and math.abs(wrap(pod.yaw - dockYaw)) < DOCK_ANGLE
		then
			docked(pod)
			return
		end
	end

	local turn = wrap(wantYaw - pod.yaw)
	pod.yaw = wrap(pod.yaw + math.clamp(turn, -HOME_TURN * dt, HOME_TURN * dt))
	local follow = 1 - math.exp(-TILT_RATE * dt)
	pod.bank += (0 - pod.bank) * follow
	pod.pitch += (0 - pod.pitch) * follow
	pod.mover.VectorVelocity = velocity
	pod.aligner.CFrame = CFrame.Angles(0, pod.yaw, 0) * CFrame.Angles(pod.pitch, 0, pod.bank)
end

-- Takes `humanoid` out of `seat` and stands it on the ground at the pod's exit spot, moved
-- `sideways` studs to the exit frame's right.
local function putOutside(pod: Pod, seat: Seat | VehicleSeat, humanoid: Humanoid, sideways: number)
	local weld = seat:FindFirstChild("SeatWeld")
	if weld then
		weld:Destroy()
	end
	humanoid.Sit = false
	local character = humanoid.Parent
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not character or not root or not character:IsA("Model") then
		return
	end
	-- The exit spot, dropped onto whatever is under it, then the root's height above that.
	local spot = pod.root.CFrame * pod.exit * CFrame.new(sideways, 0, 0)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { pod.model, character }
	local hit =
		workspace:Raycast(spot.Position + Vector3.new(0, 20, 0), Vector3.new(0, -200, 0), params)
	local groundY = if hit then hit.Position.Y else spot.Position.Y - pod.exit.Position.Y
	local level = spot.Rotation
		+ Vector3.new(spot.Position.X, groundY + pod.exit.Position.Y, spot.Position.Z)
	local rootOffset = character:GetPivot():ToObjectSpace(root.CFrame)
	character:PivotTo(level * rootOffset:Inverse())
	root.AssemblyLinearVelocity = Vector3.zero
end

-- Settles to HOVER over the ground and puts everyone aboard outside, behind the pod, side by side.
local function land(pod: Pod)
	if pod.state ~= "flying" or clearance(pod) >= LAND_HEIGHT then
		return
	end
	setState(pod, "landed") -- before anyone gets out, so the seat locks let go
	pod.speed, pod.lift, pod.throttle, pod.steer = 0, 0, 0, 0
	local pilot = pod.seat.Occupant
	pod.pilot = nil
	if pilot then
		putOutside(pod, pod.seat, pilot, 0)
	end
	for index, seat in pod.passengers do
		local rider = seat.Occupant
		pod.riders[seat] = nil
		if rider then
			putOutside(pod, seat, rider, if index % 2 == 1 then -3.5 else 3.5)
		end
	end
end

-- A landed pod hovers HOVER over the ground, level, where it is.
local function hover(pod: Pod)
	local height = clearance(pod)
	local rise = if height == math.huge then 0 else math.clamp((HOVER - height) * 3, -6, 6)
	pod.mover.VectorVelocity = Vector3.new(0, rise, 0)
	pod.pitch, pod.bank = 0, 0
	pod.aligner.CFrame = CFrame.Angles(0, pod.yaw, 0)
end

-- The pilot's seat while the pod is away: put a living pilot back, otherwise fly home. Boarding a
-- landed pod lifts it off.
-- A passenger seat while the pod flies: put a living passenger back.
local function onRider(pod: Pod, seat: Seat)
	pod.board.Enabled = pod.state == "landed" and freeSeat(pod) ~= nil
	local occupant = seat.Occupant
	if occupant then
		pod.riders[seat] = occupant
		return
	end
	local rider = pod.riders[seat]
	pod.riders[seat] = nil
	if pod.state ~= "flying" and pod.state ~= "returning" then
		return
	end
	task.defer(function()
		local character = rider and rider.Parent
		if
			rider
			and character
			and rider.Health > 0
			and not seat.Occupant
			and Players:GetPlayerFromCharacter(character)
		then
			seat:Sit(rider)
		end
	end)
end

local function onOccupant(pod: Pod)
	if pod.state == "wrecked" then
		return
	end
	local occupant = pod.seat.Occupant
	pod.board.Enabled = pod.state == "landed" and freeSeat(pod) ~= nil
	if occupant then
		pod.pilot = occupant
		return
	end
	if pod.state == "docked" or pod.state == "landed" then
		pod.pilot = nil
		return
	end
	local pilot = pod.pilot
	task.defer(function()
		if pod.seat.Occupant then
			return
		end
		local character = pilot and pilot.Parent
		if
			pilot
			and character
			and pilot.Health > 0
			and Players:GetPlayerFromCharacter(character)
		then
			pod.seat:Sit(pilot)
			task.wait(0.5)
			if pod.seat.Occupant then
				return
			end
		end
		pod.pilot = nil
		goHome(pod)
	end)
end

export type Setup = {
	model: Model,
	skid: BasePart,
	seat: VehicleSeat,
	root: BasePart,
	joint: Motor6D,
	button: CFrame, -- the launch button, relative to `root`
	jets: { CFrame }, -- thruster mouths, relative to `root`
	exit: CFrame, -- where a landing pilot stands, relative to `root`; its Y is the root's height
	-- over the ground there
	eject: (Player) -> (),
	legsSeat: VehicleSeat?,
	dismount: (Humanoid) -> (),
	passengers: { Seat }, -- seats that fly with the pod besides the pilot's
}

function PodFlight.new(setup: Setup): Pod
	local root = setup.root
	local attachment = Instance.new("Attachment")
	attachment.Name = "PodFlight"
	attachment.Parent = root
	local mover = Instance.new("LinearVelocity")
	mover.Attachment0 = attachment
	mover.RelativeTo = Enum.ActuatorRelativeTo.World
	mover.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	mover.Enabled = false
	mover.Parent = root
	local aligner = Instance.new("AlignOrientation")
	aligner.Mode = Enum.OrientationAlignmentMode.OneAttachment
	aligner.Attachment0 = attachment
	aligner.MaxTorque = math.huge
	aligner.Responsiveness = 40
	aligner.Enabled = false
	aligner.Parent = root

	local jets = {}
	for _, mouth in setup.jets do
		local spot = Instance.new("Attachment")
		spot.Name = "PodJet"
		spot.CFrame = mouth
		spot.Parent = root
		local flame = Instance.new("ParticleEmitter")
		flame.Enabled = false
		flame.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		flame.LightEmission = 1
		flame.Color = ColorSequence.new(Color3.fromRGB(120, 245, 255), Color3.fromRGB(40, 90, 255))
		flame.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1.6),
			NumberSequenceKeypoint.new(1, 0),
		})
		flame.Transparency = NumberSequence.new(0.1, 1)
		flame.Lifetime = NumberRange.new(0.25, 0.4)
		flame.Rate = 60
		flame.Speed = NumberRange.new(18, 24)
		flame.SpreadAngle = Vector2.new(6, 6)
		flame.EmissionDirection = Enum.NormalId.Back
		flame.Parent = spot
		table.insert(jets, flame)
	end

	local anchor = Instance.new("Attachment")
	anchor.Name = "PodButton"
	anchor.CFrame = setup.button
	anchor.Parent = root
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PodPrompt"
	prompt.ObjectText = setup.model.Name .. " pod"
	prompt.KeyboardKeyCode = Enum.KeyCode.F
	prompt.MaxActivationDistance = 6
	prompt.RequiresLineOfSight = false
	prompt.Parent = anchor

	local board = Instance.new("ProximityPrompt")
	board.Name = "BoardPrompt"
	board.ActionText = "Board"
	board.ObjectText = setup.model.Name .. " pod"
	board.KeyboardKeyCode = Enum.KeyCode.E
	board.MaxActivationDistance = BOARD_REACH
	board.RequiresLineOfSight = false
	board.Enabled = false
	board.Parent = root

	local pod: Pod = {
		model = setup.model,
		skid = setup.skid,
		seat = setup.seat,
		root = root,
		joint = setup.joint,
		mover = mover,
		aligner = aligner,
		jets = jets,
		prompt = prompt,
		board = board,
		eject = setup.eject,
		exit = setup.exit,
		legsSeat = setup.legsSeat,
		dismount = setup.dismount,
		passengers = setup.passengers,
		riders = {},
		state = "docked",
		pilot = nil,
		throttle = 0,
		steer = 0,
		lift = 0,
		yaw = 0,
		speed = 0,
		bank = 0,
		pitch = 0,
		launchedAt = 0,
		returningSince = 0,
		phase = "climb",
	}
	setup.model:SetAttribute("PodBone", string.sub(root.Name, 6))
	setState(pod, "docked")
	prompt.Triggered:Connect(function(player)
		local takeOff = pod.state == "docked" or pod.state == "landed"
		PodFlight.command(player, pod, if takeOff then "launch" else "home")
	end)
	board.Triggered:Connect(function(player)
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local seat = freeSeat(pod)
		if pod.state == "landed" and humanoid and humanoid.Health > 0 and seat then
			seat:Sit(humanoid)
		end
	end)
	for _, seat in setup.passengers do
		seat:GetPropertyChangedSignal("Occupant"):Connect(function()
			onRider(pod, seat)
		end)
	end
	setup.seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		onOccupant(pod)
	end)
	pods[setup.model] = pod
	return pod
end

-- `action` from `player`, who must be the pod's pilot.
function PodFlight.command(player: Player, pod: Pod, action: any)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or pod.seat.Occupant ~= humanoid then
		return
	end
	if action == "launch" then
		launch(pod)
	elseif action == "home" then
		goHome(pod)
	elseif action == "land" then
		land(pod)
	end
end

function PodFlight.input(pod: Pod, throttle: number, steer: number, lift: number)
	pod.throttle, pod.steer, pod.lift = throttle, steer, lift
end

-- Kills the pod (its vehicle is wrecked): it lets go of its pilot and riders, so nobody is put
-- back in a seat, and stops flying wherever it is.
function PodFlight.wreck(pod: Pod)
	-- Away from the legs, the hull grinds to a stop on the ground: its boxes are frictionless.
	if pod.state ~= "docked" then
		local body = pod.root.AssemblyRootPart
		for _, part in pod.model:GetDescendants() do
			if part:IsA("BasePart") and part.CanCollide and part.AssemblyRootPart == body then
				local physical = part.CurrentPhysicalProperties
				part.CustomPhysicalProperties =
					PhysicalProperties.new(physical.Density, WRECK_FRICTION, 0, 100, 1)
			end
		end
	end
	pod.pilot = nil
	table.clear(pod.riders)
	setState(pod, "wrecked")
	pod.mover.Enabled = false
	pod.aligner.Enabled = false
end

-- Whether the walker's pod sits on its legs (a walker without a pod always does).
function PodFlight.isDocked(pod: Pod?): boolean
	return pod == nil or pod.state == "docked"
end

function PodFlight.start()
	RunService.Heartbeat:Connect(function(dt)
		for model, pod in pods do
			if not model.Parent then
				pods[model] = nil
			elseif pod.state == "flying" then
				fly(pod, dt)
			elseif pod.state == "returning" then
				returnHome(pod, dt)
			elseif pod.state == "landed" then
				hover(pod)
			end
		end
	end)
	Remotes.PodCommand.OnServerEvent:Connect(function(player, action)
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		for _, pod in pods do
			if humanoid and pod.seat.Occupant == humanoid then
				PodFlight.command(player, pod, action)
			end
		end
	end)
end

return PodFlight
