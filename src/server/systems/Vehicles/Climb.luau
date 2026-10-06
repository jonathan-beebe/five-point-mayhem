-- Climb assist for walkers. A driven walker climbs walls up to MechClimb.MAX_RISE: it senses
-- them with rays, MechClimb decides, and a vertical velocity constraint (the "Climber") lifts it;
-- the model's "Climbing" attribute says when.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MechClimb = require(ReplicatedStorage.Shared.MechClimb)
local Names = require(ReplicatedStorage.Shared.Names)
local VehicleDrive = require(ReplicatedStorage.Shared.VehicleDrive)
local Registry = require(script.Parent.Registry)

local Climb = {}

local folder = Registry.folder

type Car = Registry.Car

local climbParams = RaycastParams.new()
climbParams.FilterType = Enum.RaycastFilterType.Exclude
climbParams.FilterDescendantsInstances = { folder }
climbParams.CollisionGroup = Names.CollisionGroups.Walkers
climbParams.RespectCanCollide = true

-- Terrain and anchored parts are climbable, unless they or a parent are tagged NoClimb.
local function climbable(hit: RaycastResult): boolean
	local instance = hit.Instance
	if not instance:IsA("Terrain") and not (instance:IsA("BasePart") and instance.Anchored) then
		return false
	end
	local node: Instance? = instance
	while node and node ~= workspace do
		if CollectionService:HasTag(node, Names.Tags.NoClimb) then
			return false
		end
		node = node.Parent
	end
	return true
end

-- Casts the climb rays (MechClimb.rays) from `ground`, a level frame on the skid's underside.
local function senseClimb(rays: MechClimb.Rays, ground: CFrame): MechClimb.Probe
	local function cast(ray: MechClimb.Ray, down: boolean): RaycastResult?
		local origin = ground * Vector3.new(ray.x, ray.y, ray.z)
		local direction = if down
			then Vector3.new(0, -ray.length, 0)
			else ground.LookVector * ray.length
		local hit = workspace:Raycast(origin, direction, climbParams)
		return if hit and climbable(hit) then hit else nil
	end
	local wall: { distance: number }? = nil
	for _, ray in rays.walls do
		local hit = cast(ray, false)
		if hit and math.abs(hit.Normal.Y) < MechClimb.WALL_MAX_NORMAL_Y then
			local distance = hit.Distance - (ray.z - rays.front) -- from the skid's front
			if not wall or distance < wall.distance then
				wall = { distance = distance }
			end
		end
	end
	local headroom = true
	for _, ray in rays.headroom do
		if cast(ray, false) then
			headroom = false
			break
		end
	end
	local bottom = ground.Position.Y
	local top = cast(rays.ledge, true)
	local foot = cast(rays.foot, true)
	return {
		wall = wall,
		ledge = if top then { height = top.Position.Y - bottom, normalY = top.Normal.Y } else nil,
		headroom = headroom,
		foot = if foot then foot.Position.Y - bottom else nil,
	}
end

local function setClimbing(car: Car, climbing: boolean)
	if car.climbing ~= climbing then
		car.climbing = climbing
		car.model:SetAttribute(Names.Attributes.Climbing, climbing)
	end
end

-- Ends any climb: the climber lets go and the walker falls or stands where it is.
local function stopClimb(car: Car)
	local climber = car.climber
	if climber and climber.Enabled then
		climber.Enabled = false
	end
	if car.climb.mode ~= "walk" then
		car.climb = MechClimb.new()
	end
	setClimbing(car, false)
end

-- Runs the climb assist for a driven walker. Returns the command, whose `press` replaces the
-- forward speed; nil for a vehicle that does not climb.
local function climbStep(car: Car, forward: Vector3, dt: number): MechClimb.Command?
	local climber, rays = car.climber, car.climbRays
	if not climber or not rays then
		return nil
	end
	local skid = car.skid
	local underside = (skid.CFrame * CFrame.new(0, -skid.Size.Y / 2, 0)).Position
	local ground = CFrame.lookAt(underside, underside + forward)
	local velocity = skid.AssemblyLinearVelocity
	local command = MechClimb.step(car.climb, {
		throttle = car.throttle,
		bottom = underside.Y,
		vy = velocity.Y,
		speed = velocity:Dot(forward),
		probe = if car.throttle > 0 then senseClimb(rays, ground) else nil,
		dt = dt,
	})
	local lift = command.lift
	if lift then
		-- Sized every frame: /gravity changes, and a seated driver adds mass.
		local force = VehicleDrive.climbForce(skid.AssemblyMass, workspace.Gravity)
		if math.abs(climber.MaxForce - force) > 1 then
			climber.MaxForce = force
		end
		if climber.LineVelocity ~= lift then
			climber.LineVelocity = lift
		end
		climber.Enabled = true
	elseif climber.Enabled then
		climber.Enabled = false
	end
	setClimbing(car, command.climbing)
	return command
end

Climb.stopClimb = stopClimb
Climb.climbStep = climbStep

return Climb
