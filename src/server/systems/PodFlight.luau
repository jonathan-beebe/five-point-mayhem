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
-- The flight math and its tuning (speeds, CLEARANCE, LAND_HEIGHT, HOVER, the autopilot) are in
-- src/shared/PodPilot.luau; this module casts the rays, reads the clock and moves the instances.
--
-- The model's PodState attribute ("docked", "flying", "returning", "landed", "wrecked") tells
-- clients what is going on, PodCanLand whether the pod is low enough to land; PodBone names the
-- bone that flies. A wrecked pod (Vehicles) is dead: no controls, no autopilot, no seat locks.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local MathUtil = require(ReplicatedStorage.Shared.MathUtil)
local Names = require(ReplicatedStorage.Shared.Names)
local PodPilot = require(ReplicatedStorage.Shared.PodPilot)
local PodState = require(ReplicatedStorage.Shared.PodState)
local RemoteActions = require(ReplicatedStorage.Shared.RemoteActions)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Characters = require(script.Parent.util.Characters)
local Ownership = require(script.Parent.util.Ownership)
local Prompts = require(script.Parent.util.Prompts)
local Seats = require(script.Parent.util.Seats)

local PodFlight = {}

local BOARD_REACH = 14

local WRECK_FRICTION = 0.8 -- a wrecked pod's hull away from its legs

export type State = PodState.State

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
	phase: PodPilot.Phase,
}

local pods: { [Model]: Pod } = {}

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
	local hit = workspace:Raycast(origin, Vector3.new(0, -PodPilot.CEILING - 50, 0), params)
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
	pod.model:SetAttribute(Names.Attributes.PodState, state)
	local action, enabled = PodPilot.prompt(state)
	pod.prompt.ActionText = action
	pod.prompt.Enabled = enabled
	pod.board.Enabled = state == PodState.LANDED and freeSeat(pod) ~= nil
	for _, jet in pod.jets do
		jet.Enabled = PodState.inFlight(state)
	end
	if state ~= PodState.FLYING then
		pod.model:SetAttribute(Names.Attributes.PodCanLand, false)
	end
end

local function launch(pod: Pod)
	if pod.state == PodState.LANDED then
		pod.launchedAt = os.clock() -- the lift-off rise, as from the legs
		setState(pod, PodState.FLYING)
		return
	end
	if pod.state ~= PodState.DOCKED then
		return
	end
	-- Nobody rides along standing in the cab.
	local cab = pod.model:FindFirstChild(Names.Instances.Cab) :: BasePart?
	if cab then
		for _, player in Players:GetPlayers() do
			local humanoid = Characters.humanoidOf(player)
			if humanoid and not humanoid.SeatPart and Characters.isInside(player, cab) then
				pod.eject(player)
			end
		end
	end

	local root = pod.root
	pod.joint.Enabled = false
	Ownership.set(root, nil)
	local mass = root.AssemblyMass
	pod.mover.MaxForce = mass * (workspace.Gravity + 400)
	pod.mover.VectorVelocity = Vector3.zero
	pod.yaw = MathUtil.yawOf(root.CFrame.LookVector)
	pod.aligner.CFrame = CFrame.Angles(0, pod.yaw, 0)
	pod.mover.Enabled = true
	pod.aligner.Enabled = true
	pod.speed, pod.bank, pod.pitch = 0, 0, 0
	pod.launchedAt = os.clock()
	setState(pod, PodState.FLYING)
end

local function goHome(pod: Pod)
	if pod.state ~= PodState.FLYING then
		return
	end
	-- The pod docks onto the legs' saddle: whoever rides the legs goes to the ground first.
	local rider = pod.legsSeat and pod.legsSeat.Occupant
	if rider then
		pod.dismount(rider)
	end
	pod.phase = "climb"
	pod.returningSince = os.clock()
	setState(pod, PodState.RETURNING)
end

local function docked(pod: Pod)
	pod.mover.Enabled = false
	pod.aligner.Enabled = false
	pod.root.CFrame = dock(pod) -- moves the whole pod
	pod.root.AssemblyLinearVelocity = Vector3.zero
	pod.root.AssemblyAngularVelocity = Vector3.zero
	pod.joint.Enabled = true
	setState(pod, PodState.DOCKED)
end

-- The pilot's controls.
local function fly(pod: Pod, dt: number)
	local sinceLaunch = os.clock() - pod.launchedAt
	local height = clearance(pod)
	local canLand = PodPilot.canLand(height)
	if pod.model:GetAttribute(Names.Attributes.PodCanLand) ~= canLand then
		pod.model:SetAttribute(Names.Attributes.PodCanLand, canLand)
	end
	local velocity, attitude = PodPilot.fly(pod, height, sinceLaunch, dt)
	pod.mover.VectorVelocity = velocity
	pod.aligner.CFrame = attitude
end

-- The autopilot (PodPilot.home): docks a settling pod on the dock, or any pod past HOME_TIMEOUT.
local function returnHome(pod: Pod, dt: number)
	local target = dock(pod)
	local position = pod.root.Position
	if os.clock() - pod.returningSince > PodPilot.HOME_TIMEOUT then
		docked(pod)
		return
	end
	if pod.phase == "settle" and PodPilot.onDock(pod.yaw, target, position) then
		docked(pod)
		return
	end
	local velocity, attitude = PodPilot.home(pod, target, position, dt)
	pod.mover.VectorVelocity = velocity
	pod.aligner.CFrame = attitude
end

-- Takes `humanoid` out of `seat` and stands it on the ground at the pod's exit spot, moved
-- `sideways` studs to the exit frame's right.
local function putOutside(pod: Pod, seat: Seat | VehicleSeat, humanoid: Humanoid, sideways: number)
	Seats.unseat(seat, humanoid)
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
	local level = PodPilot.standFrame(spot, pod.exit.Position.Y, hit and hit.Position.Y)
	Characters.moveRootTo(character, root, level)
end

-- Settles to HOVER over the ground and puts everyone aboard outside, behind the pod, side by side.
local function land(pod: Pod)
	if pod.state ~= PodState.FLYING or clearance(pod) >= PodPilot.LAND_HEIGHT then
		return
	end
	setState(pod, PodState.LANDED) -- before anyone gets out, so the seat locks let go
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
			putOutside(pod, seat, rider, PodPilot.sideways(index))
		end
	end
end

-- A landed pod hovers HOVER over the ground, level, where it is.
local function hover(pod: Pod)
	pod.mover.VectorVelocity = PodPilot.hover(clearance(pod))
	pod.pitch, pod.bank = 0, 0
	pod.aligner.CFrame = CFrame.Angles(0, pod.yaw, 0)
end

-- The pilot's seat while the pod is away: put a living pilot back, otherwise fly home. Boarding a
-- landed pod lifts it off.
-- A passenger seat while the pod flies: put a living passenger back.
local function onRider(pod: Pod, seat: Seat)
	pod.board.Enabled = pod.state == PodState.LANDED and freeSeat(pod) ~= nil
	local occupant = seat.Occupant
	if occupant then
		pod.riders[seat] = occupant
		return
	end
	local rider = pod.riders[seat]
	pod.riders[seat] = nil
	if not PodState.inFlight(pod.state) then
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
	if pod.state == PodState.WRECKED then
		return
	end
	local occupant = pod.seat.Occupant
	pod.board.Enabled = pod.state == PodState.LANDED and freeSeat(pod) ~= nil
	if occupant then
		pod.pilot = occupant
		return
	end
	if PodState.isAtRest(pod.state) then
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
	-- ActionText comes with the state (setState).
	local prompt = Prompts.pod(anchor, setup.model.Name)

	local board = Prompts.board(root, setup.model.Name, BOARD_REACH)

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
		state = PodState.DOCKED,
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
	setup.model:SetAttribute(
		Names.Attributes.PodBone,
		string.sub(root.Name, #Names.Instances.BonePrefix + 1)
	)
	setState(pod, PodState.DOCKED)
	prompt.Triggered:Connect(function(player)
		local takeOff = PodState.isAtRest(pod.state)
		PodFlight.command(
			player,
			pod,
			if takeOff then RemoteActions.PodCommand.LAUNCH else RemoteActions.PodCommand.HOME
		)
	end)
	board.Triggered:Connect(function(player)
		local humanoid = Characters.humanoidOf(player)
		local seat = freeSeat(pod)
		if pod.state == PodState.LANDED and humanoid and humanoid.Health > 0 and seat then
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
	local humanoid = Characters.humanoidOf(player)
	if not humanoid or pod.seat.Occupant ~= humanoid then
		return
	end
	if action == RemoteActions.PodCommand.LAUNCH then
		launch(pod)
	elseif action == RemoteActions.PodCommand.HOME then
		goHome(pod)
	elseif action == RemoteActions.PodCommand.LAND then
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
	if pod.state ~= PodState.DOCKED then
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
	setState(pod, PodState.WRECKED)
	pod.mover.Enabled = false
	pod.aligner.Enabled = false
end

-- Whether the walker's pod sits on its legs (a walker without a pod always does).
function PodFlight.isDocked(pod: Pod?): boolean
	return pod == nil or pod.state == PodState.DOCKED
end

function PodFlight.start()
	RunService.Heartbeat:Connect(function(dt)
		for model, pod in pods do
			if not model.Parent then
				pods[model] = nil
			elseif pod.state == PodState.FLYING then
				fly(pod, dt)
			elseif pod.state == PodState.RETURNING then
				returnHome(pod, dt)
			elseif pod.state == PodState.LANDED then
				hover(pod)
			end
		end
	end)
	Remotes.PodCommand.OnServerEvent:Connect(function(player, action)
		local humanoid = Characters.humanoidOf(player)
		for _, pod in pods do
			if humanoid and pod.seat.Occupant == humanoid then
				PodFlight.command(player, pod, action)
			end
		end
	end)
end

return PodFlight
