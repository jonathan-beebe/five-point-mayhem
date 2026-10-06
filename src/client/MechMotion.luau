-- Animates every walker (a vehicle model with attribute Gait = "mech") near this client. Motor6D
-- Transforms do not replicate, so each client poses each mech itself from the skid's replicated
-- velocity (src/shared/MechGait.luau); clients need not agree on the phase. While the walker
-- climbs (the model's "Climbing" attribute, Vehicles), the legs step at its rising speed. Heel
-- strikes kick up dust and fire `MechMotion.footfall` (model, foot "L" | "R", strength 0..1), which
-- MechCamera turns into a shake for the driver and VehicleSounds into a footstep. Smokestacks
-- (Attachments named "Smoke", from the model's `smoke` spec) trail smoke while the walker moves and
-- puff on every step. Hydraulic bones (Bone_ parts with an "Aim" attribute) track their partner
-- every frame (MechGait.aim); steering wheels (a "Steer" axis attribute) turn with the walker
-- (MechGait.steer); springy parts (a "Wobble" attribute) wobble as it walks (MechGait.wobble).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local MechGait = require(ReplicatedStorage.Shared.MechGait)
local Names = require(ReplicatedStorage.Shared.Names)
local VehicleDefaults = require(ReplicatedStorage.Shared.VehicleDefaults)

local MechMotion = {}

local GAIT = "mech"
local BONE_PREFIX = Names.Instances.BonePrefix
local JOINT_PREFIX = Names.Instances.JointPrefix
local ANIMATE_RANGE = 500 -- studs from the camera
local DUST_RANGE = 200
local DUST_SPEED = 3 -- ground speed (studs/s) below which steps raise no dust
local SKID_TO_GROUND = CFrame.new(0, -0.5, 0)
local SMOKE_RANGE = 400
local SMOKE_SPEED = 0.5 -- ground speed (studs/s) below which the stacks stop smoking
local SMOKE_RATE = 14 -- particles per second per stack at top speed
local SMOKE_PUFF = 5 -- particles per stack on each step

local footfallEvent = Instance.new("BindableEvent")
-- Fires (model: Model, foot: "L" | "R", strength: number) on every heel strike this client animates.
MechMotion.footfall = footfallEvent.Event

type Mech = {
	model: Model,
	skid: BasePart?,
	seat: VehicleSeat?,
	joints: { [string]: Motor6D }?,
	bones: { MechGait.AimBone }?, -- parents first
	wheels: { [string]: Vector3 }?, -- steering wheel bone -> axis
	wobbles: { [string]: MechGait.Wobble }?, -- springy bone -> its spring
	state: MechGait.State?,
	dust: ParticleEmitter?,
	smoke: { ParticleEmitter },
	posed: boolean, -- Transforms differ from the rest pose
}

local mechs: { [Model]: Mech } = {}

-- Finds the skid, driver seat and joints; with streaming they can arrive after the model.
local function resolve(mech: Mech): boolean
	if mech.joints and mech.skid and mech.skid.Parent and mech.seat and mech.seat.Parent then
		return true
	end
	local model = mech.model
	local skid = model.PrimaryPart or model:FindFirstChild(Names.Instances.Skid) :: BasePart?
	local seat = model:FindFirstChild(Names.Instances.DriverSeat)
	if not skid or not seat or not seat:IsA("VehicleSeat") then
		return false
	end
	local joints: { [string]: Motor6D } = {}
	local pivots: { [string]: Vector3 } = {}
	local bones: { MechGait.AimBone } = {}
	local wheels: { [string]: Vector3 } = {}
	local wobbles: { [string]: MechGait.Wobble } = {}
	-- Rest pivots in vehicle space: each joint's C0 sits at its pivot in the parent bone's frame
	-- (bones have the vehicle's axes); the root joints' C0 is in the skid's frame.
	local pending = {}
	for _, child in model:GetChildren() do
		local joint = child:FindFirstChildOfClass("Motor6D")
		if joint and string.sub(joint.Name, 1, #JOINT_PREFIX) == JOINT_PREFIX then
			table.insert(pending, joint)
		end
	end
	if #pending == 0 then
		return false
	end
	local progress = true
	while #pending > 0 and progress do
		progress = false
		for index = #pending, 1, -1 do
			local joint = pending[index]
			local name = string.sub(joint.Name, #JOINT_PREFIX + 1)
			local parent = joint.Part0
			local pivot: Vector3? = nil
			local parentName: string? = nil
			if parent == skid then
				pivot = (SKID_TO_GROUND:Inverse() * joint.C0).Position
			elseif parent and string.sub(parent.Name, 1, #BONE_PREFIX) == BONE_PREFIX then
				parentName = string.sub(parent.Name, #BONE_PREFIX + 1)
				local base = pivots[parentName :: string]
				pivot = base and base + joint.C0.Position
			end
			if pivot then
				pivots[name] = pivot
				joints[name] = joint
				local steer = joint.Parent and joint.Parent:GetAttribute(Names.Attributes.Steer)
				if typeof(steer) == "Vector3" then
					wheels[name] = steer
				end
				if joint.Parent and joint.Parent:GetAttribute(Names.Attributes.Wobble) then
					wobbles[name] = MechGait.newWobble()
				end
				local aim = joint.Parent and joint.Parent:GetAttribute(Names.Attributes.Aim)
				table.insert(bones, {
					name = name,
					parent = parentName,
					pivot = pivot,
					aim = if typeof(aim) == "string" then aim else nil,
				})
				table.remove(pending, index)
				progress = true
			end
		end
	end
	local ok, rig = pcall(MechGait.rig, pivots)
	if not ok then
		return false
	end
	mech.skid = skid
	mech.seat = seat :: VehicleSeat
	mech.joints = joints
	mech.bones = bones
	mech.wheels = wheels
	mech.wobbles = wobbles
	mech.state = MechGait.new(rig)

	local attachment = Instance.new("Attachment")
	attachment.Name = "MechDust"
	attachment.Parent = skid
	local dust = Instance.new("ParticleEmitter")
	dust.Enabled = false
	dust.Color = ColorSequence.new(Color3.fromRGB(170, 155, 130))
	dust.Size = NumberSequence.new(1.5, 5)
	dust.Transparency = NumberSequence.new(0.5, 1)
	dust.Lifetime = NumberRange.new(0.9, 1.4)
	dust.Speed = NumberRange.new(3, 6)
	dust.SpreadAngle = Vector2.new(70, 70)
	dust.Drag = 3
	dust.EmissionDirection = Enum.NormalId.Top
	dust.Parent = attachment
	mech.dust = dust

	for _, descendant in model:GetDescendants() do
		if descendant:IsA("Attachment") and descendant.Name == Names.Instances.Smoke then
			local smoke = Instance.new("ParticleEmitter")
			smoke.Rate = 0
			smoke.Color =
				ColorSequence.new(Color3.fromRGB(70, 64, 58), Color3.fromRGB(150, 145, 140))
			smoke.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1.2),
				NumberSequenceKeypoint.new(0.3, 3.5),
				NumberSequenceKeypoint.new(1, 8),
			})
			smoke.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.15),
				NumberSequenceKeypoint.new(0.6, 0.6),
				NumberSequenceKeypoint.new(1, 1),
			})
			smoke.Lifetime = NumberRange.new(2.2, 3.4)
			smoke.Speed = NumberRange.new(7, 11)
			smoke.SpreadAngle = Vector2.new(10, 10)
			smoke.Drag = 1.2
			smoke.Acceleration = Vector3.new(0, 2, 0)
			smoke.Rotation = NumberRange.new(0, 360)
			smoke.RotSpeed = NumberRange.new(-40, 40)
			smoke.LightInfluence = 1
			smoke.EmissionDirection = Enum.NormalId.Top
			smoke.Parent = descendant
			table.insert(mech.smoke, smoke)
		end
	end
	return true
end

local function track(model: Instance)
	if
		model:IsA("Model")
		and model:GetAttribute(Names.Attributes.Gait) == GAIT
		and not mechs[model]
	then
		mechs[model] = { model = model, smoke = {}, posed = false }
	end
end

local function rest(mech: Mech)
	if mech.posed and mech.joints then
		for _, joint in mech.joints do
			joint.Transform = CFrame.identity
		end
	end
	mech.posed = false
end

-- A pod walker's legs seat (Vehicles) is taken: someone drives the legs while the pod is away.
local function legsRidden(model: Model): boolean
	local saddle = model:FindFirstChild(Names.Instances.LegsSeat)
	return saddle ~= nil and saddle:IsA("VehicleSeat") and saddle.Occupant ~= nil
end

local function animate(mech: Mech, dt: number, viewer: Vector3)
	if not resolve(mech) then
		return
	end
	local skid = mech.skid :: BasePart
	local seat = mech.seat :: VehicleSeat
	local state = mech.state :: MechGait.State
	local distance = (skid.Position - viewer).Magnitude
	if distance > ANIMATE_RANGE then
		rest(mech)
		for _, smoke in mech.smoke do
			smoke.Rate = 0
		end
		return
	end

	local look = skid.CFrame.LookVector
	local flat = Vector3.new(look.X, 0, look.Z)
	local forward = if flat.Magnitude > 0.01 then flat.Unit else Vector3.zAxis
	local velocity = skid.AssemblyLinearVelocity
	local footfalls = MechGait.step(state, {
		forward = velocity:Dot(forward),
		climb = if mech.model:GetAttribute(Names.Attributes.Climbing)
			then math.max(velocity.Y, 0)
			else 0,
		yawRate = skid.AssemblyAngularVelocity.Y,
		occupied = seat.Occupant ~= nil or legsRidden(mech.model),
		topSpeed = (seat:GetAttribute(Names.Attributes.TopSpeed) :: number?) or 18,
		turnRate = (seat:GetAttribute(Names.Attributes.TurnRate) :: number?)
			or VehicleDefaults.turnRate,
		time = os.clock(),
	}, dt)
	local poses = MechGait.pose(state)
	MechGait.aim(mech.bones :: { MechGait.AimBone }, poses)
	for name, axis in mech.wheels :: { [string]: Vector3 } do
		poses[name] = MechGait.steer(state, axis)
	end
	for name, wobble in mech.wobbles :: { [string]: MechGait.Wobble } do
		poses[name] = MechGait.wobble(wobble, state, footfalls, dt)
	end
	for name, joint in mech.joints :: { [string]: Motor6D } do
		local pose = poses[name]
		if pose then
			joint.Transform = pose
		end
	end
	mech.posed = true

	local smoking = distance < SMOKE_RANGE and state.ground > SMOKE_SPEED
	local pace = math.clamp(state.ground / math.max(state.topSpeed, 1), 0, 1)
	for _, smoke in mech.smoke do
		smoke.Rate = if smoking then SMOKE_RATE * (0.3 + 0.7 * pace) else 0
	end

	for _, footfall in footfalls do
		if smoking then
			for _, smoke in mech.smoke do
				smoke:Emit(SMOKE_PUFF)
			end
		end
		if distance < DUST_RANGE and state.ground > DUST_SPEED and mech.dust then
			local point = MechGait.footPoint(state, footfall.foot)
			local attachment = mech.dust.Parent :: Attachment
			attachment.CFrame = SKID_TO_GROUND * CFrame.new(point)
			mech.dust:Emit(8)
		end
		footfallEvent:Fire(mech.model, footfall.foot, footfall.strength)
	end
end

-- The walk state this client animates for `model` (read only), or nil before it has resolved.
function MechMotion.gait(model: Model): MechGait.State?
	local mech = mechs[model]
	return mech and mech.state
end

function MechMotion.start()
	local folder = Workspace:WaitForChild(Names.Instances.Vehicles)
	folder.ChildAdded:Connect(track)
	folder.ChildRemoved:Connect(function(child)
		mechs[child :: Model] = nil
	end)
	for _, child in folder:GetChildren() do
		track(child)
	end

	-- Before physics, so the posed parts render this frame.
	RunService.PreSimulation:Connect(function(dt)
		local camera = Workspace.CurrentCamera
		local viewer = if camera then camera.CFrame.Position else Vector3.zero
		for model, mech in mechs do
			if not model.Parent then
				mechs[model] = nil
				continue
			end
			local ok, problem = pcall(animate, mech, dt, viewer)
			if not ok then
				warn("[MechMotion] " .. tostring(problem))
				mechs[model] = nil
			end
		end
	end)
end

return MechMotion
