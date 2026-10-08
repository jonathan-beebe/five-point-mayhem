-- Moving a vehicle with everyone aboard: the admin `goto` command carries a seated player's
-- vehicle to a gate (Vehicles.carry). The whole model pivots so its lowest point sits LIFT above
-- the ground frame, turned to the frame's facing, and every part's velocity stops. Riders move
-- with their seats. While a walker's pod is away, a rider in the pod carries the pod alone, to
-- POD_HEIGHT above the frame, still flying; a rider on the legs is not carried.

local PodFlight = require(script.Parent.Parent.PodFlight)
local Registry = require(script.Parent.Registry)

local Relocate = {}

local LIFT = 1
local POD_HEIGHT = 20

-- The car whose driver, legs or passenger seat holds `humanoid`, or nil.
local function carOf(humanoid: Humanoid): Registry.Car?
	local seat = humanoid.SeatPart
	if not seat then
		return nil
	end
	for _, car in Registry.cars do
		if car.seat == seat or car.legsSeat == seat or table.find(car.passengers, seat :: Seat) then
			return car
		end
	end
	return nil
end

-- Carries the vehicle `humanoid` sits in to `ground` (a ground-level CFrame whose -Z is the
-- facing). Returns whether it did: false when not seated in a vehicle, or on the legs of a
-- walker whose pod is away.
function Relocate.carry(humanoid: Humanoid, ground: CFrame): boolean
	local car = carOf(humanoid)
	if not car then
		return false
	end
	local pod = car.pod
	if pod and not PodFlight.isDocked(pod) then
		local seat = humanoid.SeatPart :: Seat
		if seat ~= pod.seat and not table.find(pod.passengers, seat) then
			return false
		end
		local look = ground.LookVector
		local position = ground.Position + Vector3.new(0, POD_HEIGHT, 0)
		pod.root.CFrame = CFrame.lookAt(position, position + Vector3.new(look.X, 0, look.Z))
		pod.root.AssemblyLinearVelocity = Vector3.zero
		pod.root.AssemblyAngularVelocity = Vector3.zero
		return true
	end
	local model = car.model
	local skid = car.skid
	local box, size = model:GetBoundingBox()
	local above = skid.Position.Y - (box.Position.Y - size.Y / 2)
	local look = ground.LookVector
	local flat = Vector3.new(look.X, 0, look.Z).Unit
	local position = ground.Position + Vector3.new(0, above + LIFT, 0)
	local target = CFrame.lookAt(position, position + flat)
	-- The skid's yaw only: drop any tilt it had.
	local skidLook = Vector3.new(skid.CFrame.LookVector.X, 0, skid.CFrame.LookVector.Z).Unit
	local level = CFrame.lookAt(skid.Position, skid.Position + skidLook)
	model:PivotTo(target * level:ToObjectSpace(model:GetPivot()))
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and not part.Anchored then
			part.AssemblyLinearVelocity = Vector3.zero
			part.AssemblyAngularVelocity = Vector3.zero
		end
	end
	car.throttle = 0
	car.steer = 0
	car.pace = 0
	return true
end

return Relocate
