-- While the local player sits in a Mayhem car's driver seat, sends throttle and steer to the
-- server. Reads, in order: WASD/arrow keys, the driver seat's ThrottleFloat/SteerFloat (written
-- locally by the default control scripts from the thumbstick or gamepad), and the default
-- controls' move vector.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Remotes = require(ReplicatedStorage.Shared.Remotes)

local CarInput = {}

local player = Players.LocalPlayer
local K = Enum.KeyCode

local RESEND_INTERVAL = 0.25

local controls: any = nil
local controlsWarned = false

local function keyAxis(positive: { Enum.KeyCode }, negative: { Enum.KeyCode }): number
	local value = 0
	for _, key in positive do
		if UserInputService:IsKeyDown(key) then
			value += 1
			break
		end
	end
	for _, key in negative do
		if UserInputService:IsKeyDown(key) then
			value -= 1
			break
		end
	end
	return value
end

-- The default control scripts, required on first use so a slow PlayerModule load is retried.
local function getControls(): any
	if controls then
		return controls
	end
	local scripts = player:FindFirstChild("PlayerScripts")
	local module = scripts and scripts:FindFirstChild("PlayerModule")
	if not module then
		return nil
	end
	local ok, result = pcall(function()
		return (require(module :: ModuleScript) :: any):GetControls()
	end)
	if ok and result then
		controls = result
	elseif not controlsWarned then
		controlsWarned = true
		warn("[CarInput] default controls unavailable:", result)
	end
	return controls
end

local function readInput(seat: VehicleSeat): (number, number)
	if UserInputService:GetFocusedTextBox() then
		return 0, 0 -- typing in chat
	end
	local throttle = keyAxis({ K.W, K.Up }, { K.S, K.Down })
	local steer = keyAxis({ K.D, K.Right }, { K.A, K.Left })
	if throttle == 0 and steer == 0 then
		throttle, steer = seat.ThrottleFloat, seat.SteerFloat
	end
	local current = if throttle == 0 and steer == 0 then getControls() else nil
	if current then
		local ok, move = pcall(current.GetMoveVector, current)
		if ok and typeof(move) == "Vector3" then
			throttle, steer = -move.Z, move.X
		end
	end
	return math.clamp(throttle, -1, 1), math.clamp(steer, -1, 1)
end

local function driverSeat(): VehicleSeat?
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local seat = humanoid and humanoid.SeatPart
	if seat and seat:IsA("VehicleSeat") and seat:GetAttribute("MayhemCar") == true then
		return seat
	end
	return nil
end

function CarInput.start()
	local lastThrottle, lastSteer, lastSent = 0, 0, 0
	local driving = false
	RunService.Heartbeat:Connect(function()
		local seat = driverSeat()
		if not seat then
			driving = false
			return
		end
		local throttle, steer = readInput(seat)
		local now = os.clock()
		local changed = math.abs(throttle - lastThrottle) > 0.05
			or math.abs(steer - lastSteer) > 0.05
		if not driving or changed or now - lastSent > RESEND_INTERVAL then
			driving = true
			lastThrottle, lastSteer, lastSent = throttle, steer, now
			Remotes.DriveInput:FireServer(throttle, steer)
		end
	end)
end

return CarInput
