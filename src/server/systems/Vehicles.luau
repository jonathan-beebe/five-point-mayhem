-- Arcade cars parked beside the lobby exits and near each landmark. A car is a frictionless skid
-- carrying welded body parts. The driver's client sends its stick/keys over the DriveInput remote;
-- the server turns that into targets for velocity constraints on the skid. Constraints are
-- simulated by whichever machine owns the car's physics, so this works under any ownership.
-- Wrecked or abandoned cars return to their parking spot.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local Vehicles = {}

local rgb = Color3.fromRGB
local M = Enum.Material

type Kind = {
	name: string,
	width: number,
	length: number,
	wheel: number,
	speed: number,
	color: Color3,
	seats: number,
}

local KINDS: { [string]: Kind } = {
	jeep = {
		name = "Jeep",
		width = 8,
		length = 14,
		wheel = 3.4,
		speed = 85,
		color = rgb(85, 110, 60),
		seats = 3,
	},
	monster = {
		name = "Monster Truck",
		width = 11,
		length = 16,
		wheel = 7,
		speed = 75,
		color = rgb(200, 40, 40),
		seats = 3,
	},
	kart = {
		name = "Go-Kart",
		width = 5,
		length = 8,
		wheel = 2,
		speed = 105,
		color = rgb(40, 120, 255),
		seats = 0,
	},
	taxi = {
		name = "Taxi",
		width = 8,
		length = 15,
		wheel = 3,
		speed = 90,
		color = rgb(255, 200, 20),
		seats = 3,
	},
	buggy = {
		name = "Dune Buggy",
		width = 8,
		length = 12,
		wheel = 3.6,
		speed = 95,
		color = rgb(255, 130, 30),
		seats = 1,
	},
	snowcat = {
		name = "Snow Cat",
		width = 10,
		length = 14,
		wheel = 4,
		speed = 70,
		color = rgb(250, 250, 255),
		seats = 3,
	},
}

-- Themed car parked near each landmark, by region id.
local REGION_KIND =
	{ castle = "jeep", pagoda = "kart", tower = "taxi", pyramid = "buggy", palace = "snowcat" }

local folder = Instance.new("Folder")
folder.Name = "Vehicles"
folder.Parent = workspace

local ACCELERATION = 55
local BRAKING = 90
local COASTING = 30
local TURN_RATE = 2.4

type Car = {
	seat: VehicleSeat,
	skid: BasePart,
	mover: LinearVelocity,
	turner: AngularVelocity,
	throttle: number,
	steer: number,
}

-- Every live car, by model.
local cars: { [Model]: Car } = {}

local function moveToward(current: number, target: number, step: number): number
	if current < target then
		return math.min(current + step, target)
	end
	return math.max(current - step, target)
end

local function drive(car: Car, dt: number)
	local occupant = car.seat.Occupant
	local skid = car.skid
	-- Without a driver, ordinary physics has the car. With one, the drive constraints steer it,
	-- in the air too: arcade cars keep control off jumps.
	car.mover.Enabled = occupant ~= nil
	car.turner.Enabled = occupant ~= nil
	if not occupant then
		return
	end

	local topSpeed = (car.seat:GetAttribute("TopSpeed") :: number?) or 80
	local look = skid.CFrame.LookVector
	local forward = Vector3.new(look.X, 0, look.Z).Unit
	local speed = skid.AssemblyLinearVelocity:Dot(forward)
	local throttle = car.throttle
	local target = if throttle >= 0 then throttle * topSpeed else throttle * topSpeed * 0.4
	local rate = if throttle == 0
		then COASTING
		elseif math.sign(target) ~= math.sign(speed) and math.abs(speed) > 1 then BRAKING
		else ACCELERATION
	local newSpeed = moveToward(speed, target, rate * dt)

	car.mover.PlaneVelocity = Vector2.new(forward.X * newSpeed, forward.Z * newSpeed)
	local grip = math.clamp(newSpeed / 20, -1, 1)
	car.turner.AngularVelocity = Vector3.new(0, -car.steer * TURN_RATE * grip, 0)
end

RunService.Heartbeat:Connect(function(dt)
	for model, car in cars do
		if model.Parent then
			drive(car, dt)
		else
			cars[model] = nil
		end
	end
end)

Remotes.DriveInput.OnServerEvent:Connect(function(player, throttle, steer)
	if typeof(throttle) ~= "number" or typeof(steer) ~= "number" then
		return
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local seat = humanoid and humanoid.SeatPart
	local model = seat and seat.Parent
	local car = model and cars[model :: Model]
	if not car or car.seat ~= seat then
		return
	end
	car.throttle = math.clamp(throttle, -1, 1)
	car.steer = math.clamp(steer, -1, 1)
end)

local function weldPart(
	model: Model,
	skid: BasePart,
	size: Vector3,
	offset: CFrame,
	color: Color3,
	material: Enum.Material?,
	shape: Enum.PartType?,
	collide: boolean?
): Part
	local part = Instance.new("Part")
	if shape then
		part.Shape = shape
	end
	part.Size = size
	part.Color = color
	part.Material = material or M.SmoothPlastic
	part.CanCollide = collide == true
	part.Massless = true
	part.CFrame = skid.CFrame * offset
	local weld = Instance.new("Weld")
	weld.Part0 = skid
	weld.Part1 = part
	weld.C0 = offset
	weld.Parent = part
	part.Parent = model
	return part
end

local function seat(
	model: Model,
	skid: BasePart,
	className: string,
	offset: CFrame
): Seat | VehicleSeat
	local chair = Instance.new(className) :: any
	chair.Size = Vector3.new(2.4, 1, 2.4)
	chair.Color = rgb(30, 30, 30)
	chair.Massless = true
	chair.CFrame = skid.CFrame * offset
	local weld = Instance.new("Weld")
	weld.Part0 = skid
	weld.Part1 = chair
	weld.C0 = offset
	weld.Parent = chair
	chair.Parent = model
	return chair
end

local function build(kind: Kind, cframe: CFrame): Model
	local model = Instance.new("Model")
	model.Name = kind.name
	local W, L, d = kind.width, kind.length, kind.wheel

	-- The skid is the only colliding, massive part: a low, wide, frictionless sled.
	local skid = Instance.new("Part")
	skid.Name = "Skid"
	skid.Size = Vector3.new(W, 1, L)
	skid.Transparency = 1
	skid.CustomPhysicalProperties = PhysicalProperties.new(4, 0, 0, 100, 1)
	skid.CFrame = cframe * CFrame.new(0, 0.5, 0)
	skid.Parent = model
	model.PrimaryPart = skid

	local deck = d * 0.55
	weldPart(
		model,
		skid,
		Vector3.new(W, 1.6, L),
		CFrame.new(0, deck, 0),
		kind.color,
		M.Metal,
		nil,
		true
	)
	weldPart(
		model,
		skid,
		Vector3.new(W - 1, 1.4, 3),
		CFrame.new(0, deck + 1.4, -L / 2 + 1.5),
		kind.color,
		M.Metal
	)
	weldPart(
		model,
		skid,
		Vector3.new(W - 1.4, 2.2, 0.3),
		CFrame.new(0, deck + 2.6, -L / 2 + 3.2) * CFrame.Angles(math.rad(-20), 0, 0),
		rgb(150, 200, 230),
		M.Glass
	)
	for _, side in { -1, 1 } do
		weldPart(
			model,
			skid,
			Vector3.new(0.8, 0.8, 0.3),
			CFrame.new(side * (W / 2 - 1), deck + 0.6, -L / 2 - 0.1),
			rgb(255, 255, 210),
			M.Neon
		)
		weldPart(
			model,
			skid,
			Vector3.new(0.8, 0.6, 0.3),
			CFrame.new(side * (W / 2 - 1), deck + 0.6, L / 2 + 0.1),
			rgb(255, 30, 30),
			M.Neon
		)
	end
	-- Roll bar.
	if kind.seats > 0 then
		for _, side in { -1, 1 } do
			weldPart(
				model,
				skid,
				Vector3.new(0.4, 4, 0.4),
				CFrame.new(side * (W / 2 - 0.5), deck + 2.8, 1),
				rgb(40, 40, 40),
				M.Metal
			)
		end
		weldPart(
			model,
			skid,
			Vector3.new(W - 0.6, 0.4, 0.4),
			CFrame.new(0, deck + 4.8, 1),
			rgb(40, 40, 40),
			M.Metal
		)
	end
	-- Wheels (decorative; the skid carries the car).
	for _, corner in
		{ Vector2.new(-1, -1), Vector2.new(1, -1), Vector2.new(-1, 1), Vector2.new(1, 1) }
	do
		weldPart(
			model,
			skid,
			Vector3.new(d * 0.45, d, d),
			CFrame.new(corner.X * (W / 2 + d * 0.15), d / 2 - 0.5, corner.Y * (L / 2 - d * 0.5)),
			rgb(25, 25, 25),
			M.SmoothPlastic,
			Enum.PartType.Cylinder
		)
	end

	local driver =
		seat(model, skid, "VehicleSeat", CFrame.new(-W / 4, deck + 1.3, -1)) :: VehicleSeat
	driver.Name = "DriverSeat"
	driver.MaxSpeed = kind.speed
	driver:SetAttribute("MayhemCar", true)
	driver:SetAttribute("TopSpeed", kind.speed)
	local seatOffsets = {
		CFrame.new(W / 4, deck + 1.3, -1),
		CFrame.new(-W / 4, deck + 1.3, 3.5),
		CFrame.new(W / 4, deck + 1.3, 3.5),
	}
	for index = 1, kind.seats do
		seat(model, skid, "Seat", seatOffsets[index])
	end

	-- Keeps the car upright without fixing its heading.
	local attachment = Instance.new("Attachment")
	attachment.CFrame = CFrame.Angles(0, 0, math.rad(90))
	attachment.Parent = skid
	local upright = Instance.new("AlignOrientation")
	upright.Mode = Enum.OrientationAlignmentMode.OneAttachment
	upright.AlignType = Enum.AlignType.PrimaryAxisParallel
	upright.PrimaryAxis = Vector3.yAxis
	upright.Attachment0 = attachment
	upright.MaxTorque = 4e5
	upright.Responsiveness = 12
	upright.Parent = skid

	-- Drive constraints: horizontal velocity in the world XZ plane (gravity stays free) and yaw rate.
	local driveAttachment = Instance.new("Attachment")
	driveAttachment.Name = "DriveAttachment"
	driveAttachment.Parent = skid
	local mover = Instance.new("LinearVelocity")
	mover.Attachment0 = driveAttachment
	mover.RelativeTo = Enum.ActuatorRelativeTo.World
	mover.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
	mover.PrimaryTangentAxis = Vector3.xAxis
	mover.SecondaryTangentAxis = Vector3.zAxis
	mover.MaxForce = 3e5
	mover.Enabled = false
	mover.Parent = skid
	local turner = Instance.new("AngularVelocity")
	turner.Attachment0 = driveAttachment
	turner.RelativeTo = Enum.ActuatorRelativeTo.World
	turner.MaxTorque = 1e6
	turner.Enabled = false
	turner.Parent = skid

	local car: Car =
		{ seat = driver, skid = skid, mover = mover, turner = turner, throttle = 0, steer = 0 }
	-- While someone drives, the server simulates the car (and the seated driver with it). When
	-- they get out, hand their character's physics back to them.
	local lastDriver: Player? = nil
	driver:GetPropertyChangedSignal("Occupant"):Connect(function()
		model:SetAttribute("LastUsed", os.clock())
		car.throttle = 0
		car.steer = 0
		local occupant = driver.Occupant
		if occupant then
			lastDriver = Players:GetPlayerFromCharacter(occupant.Parent)
			local ok, problem = pcall(skid.SetNetworkOwner, skid, nil)
			if not ok then
				warn("[Mayhem car] could not take ownership: " .. tostring(problem))
			end
			return
		end
		local previous = lastDriver
		lastDriver = nil
		task.defer(function()
			local character = previous and previous.Character
			local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if root then
				pcall(root.SetNetworkOwner, root, previous)
			end
		end)
	end)

	model.Parent = folder
	cars[model] = car
	return model
end

type Spot = { kind: Kind, cframe: CFrame, model: Model? }
local spots: { Spot } = {}

local function park(spot: Spot)
	if spot.model then
		spot.model:Destroy()
	end
	spot.model = build(spot.kind, spot.cframe)
	spot.model:SetAttribute("LastUsed", os.clock())
end

local function isOccupied(model: Model): boolean
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("Seat") or descendant:IsA("VehicleSeat") then
			if (descendant :: any).Occupant then
				return true
			end
		end
	end
	return false
end

function Vehicles.spawnNear(position: Vector3, kindId: string?): Model
	local kind = KINDS[kindId or "jeep"] or KINDS.jeep
	return build(kind, CFrame.new(position + Vector3.new(0, 2, 0)))
end

function Vehicles.start()
	for index, region in Config.REGIONS do
		local angle = Config.regionAngle(index)
		local outward = Config.pointAt(angle, 1)
		local side = Vector3.new(-outward.Z, 0, outward.X)
		-- Two near the lobby exit, on either side of the road.
		for _, offset in { -1, 1 } do
			local position = Config.pointAt(angle, 100)
				+ side * offset * 22
				+ Vector3.new(0, 0.2, 0)
			local kindId = if offset < 0
				then "jeep"
				else (if index % 2 == 0 then "monster" else "kart")
			table.insert(
				spots,
				{ kind = KINDS[kindId], cframe = CFrame.lookAt(position, position + outward) }
			)
		end
		-- One themed car on the road toward the landmark.
		local position = Config.pointAt(angle, 330) + side * 22 + Vector3.new(0, 0.2, 0)
		table.insert(spots, {
			kind = KINDS[REGION_KIND[region.id]],
			cframe = CFrame.lookAt(position, position - outward),
		})
	end
	for _, spot in spots do
		park(spot)
	end

	-- Return cars that were destroyed, or left idle far from home for a minute.
	task.spawn(function()
		while true do
			task.wait(10)
			for _, spot in spots do
				local model = spot.model
				local skid = model and model.PrimaryPart
				if not model or not model.Parent or not skid then
					park(spot)
				elseif isOccupied(model) then
					model:SetAttribute("LastUsed", os.clock())
				else
					local away = (skid.Position - spot.cframe.Position).Magnitude > 30
					local idle = os.clock() - ((model:GetAttribute("LastUsed") :: number?) or 0)
						> 60
					if (away and idle) or skid.Position.Y < -50 then
						park(spot)
					end
				end
			end
		end
	end)
end

return Vehicles
