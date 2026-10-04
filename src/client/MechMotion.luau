-- Animates every walker (a vehicle model with attribute Gait = "mech") near this client. Motor6D
-- Transforms do not replicate, so each client poses each mech itself from the skid's replicated
-- velocity (src/shared/MechGait.luau); clients need not agree on the phase. Heel strikes kick up
-- dust and fire `MechMotion.footfall` (model, foot "L" | "R", strength 0..1), which MechCamera
-- turns into a shake for the driver and VehicleSounds into a footstep.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local MechGait = require(ReplicatedStorage.Shared.MechGait)

local MechMotion = {}

local GAIT = "mech"
local ANIMATE_RANGE = 500 -- studs from the camera
local DUST_RANGE = 200
local DUST_SPEED = 3 -- ground speed (studs/s) below which steps raise no dust
local SKID_TO_GROUND = CFrame.new(0, -0.5, 0)

local footfallEvent = Instance.new("BindableEvent")
-- Fires (model: Model, foot: "L" | "R", strength: number) on every heel strike this client animates.
MechMotion.footfall = footfallEvent.Event

type Mech = {
	model: Model,
	skid: BasePart?,
	seat: VehicleSeat?,
	joints: { [string]: Motor6D }?,
	state: MechGait.State?,
	dust: ParticleEmitter?,
	posed: boolean, -- Transforms differ from the rest pose
}

local mechs: { [Model]: Mech } = {}

-- Finds the skid, driver seat and joints; with streaming they can arrive after the model.
local function resolve(mech: Mech): boolean
	if mech.joints and mech.skid and mech.skid.Parent and mech.seat and mech.seat.Parent then
		return true
	end
	local model = mech.model
	local skid = model.PrimaryPart or model:FindFirstChild("Skid") :: BasePart?
	local seat = model:FindFirstChild("DriverSeat")
	if not skid or not seat or not seat:IsA("VehicleSeat") then
		return false
	end
	local joints: { [string]: Motor6D } = {}
	local pivots: { [string]: Vector3 } = {}
	-- Rest pivots in vehicle space: each joint's C0 sits at its pivot in the parent bone's frame
	-- (bones have the vehicle's axes); the root joints' C0 is in the skid's frame.
	local pending = {}
	for _, child in model:GetChildren() do
		local joint = child:FindFirstChildOfClass("Motor6D")
		if joint and string.sub(joint.Name, 1, 6) == "Joint_" then
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
			local name = string.sub(joint.Name, 7)
			local parent = joint.Part0
			local pivot: Vector3? = nil
			if parent == skid then
				pivot = (SKID_TO_GROUND:Inverse() * joint.C0).Position
			elseif parent and string.sub(parent.Name, 1, 5) == "Bone_" then
				local base = pivots[string.sub(parent.Name, 6)]
				pivot = base and base + joint.C0.Position
			end
			if pivot then
				pivots[name] = pivot
				joints[name] = joint
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
	return true
end

local function track(model: Instance)
	if model:IsA("Model") and model:GetAttribute("Gait") == GAIT and not mechs[model] then
		mechs[model] = { model = model, posed = false }
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
		return
	end

	local look = skid.CFrame.LookVector
	local flat = Vector3.new(look.X, 0, look.Z)
	local forward = if flat.Magnitude > 0.01 then flat.Unit else Vector3.zAxis
	local footfalls = MechGait.step(state, {
		forward = skid.AssemblyLinearVelocity:Dot(forward),
		yawRate = skid.AssemblyAngularVelocity.Y,
		occupied = seat.Occupant ~= nil,
		topSpeed = (seat:GetAttribute("TopSpeed") :: number?) or 18,
		turnRate = (seat:GetAttribute("TurnRate") :: number?) or 0.7,
		time = os.clock(),
	}, dt)
	local poses = MechGait.pose(state)
	for name, joint in mech.joints :: { [string]: Motor6D } do
		local pose = poses[name]
		if pose then
			joint.Transform = pose
		end
	end
	mech.posed = true

	for _, footfall in footfalls do
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
	local folder = Workspace:WaitForChild("Vehicles")
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
