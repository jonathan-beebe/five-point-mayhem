-- While the local player sits in a Mayhem car's driver seat, sends throttle and steer to the
-- server. Reads WASD/arrow keys directly, plus the movement stick (gamepad, mobile thumbstick)
-- from the default control scripts.

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

local function readInput(): (number, number)
	if UserInputService:GetFocusedTextBox() then
		return 0, 0 -- typing in chat
	end
	local throttle = keyAxis({ K.W, K.Up }, { K.S, K.Down })
	local steer = keyAxis({ K.D, K.Right }, { K.A, K.Left })
	if throttle == 0 and steer == 0 and controls then
		local ok, move = pcall(controls.GetMoveVector, controls)
		if ok and typeof(move) == "Vector3" then
			throttle, steer = -move.Z, move.X
		end
	end
	return math.clamp(throttle, -1, 1), math.clamp(steer, -1, 1)
end

local function inDriverSeat(): boolean
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local seat = humanoid and humanoid.SeatPart
	return seat ~= nil and seat:IsA("VehicleSeat") and seat:GetAttribute("MayhemCar") == true
end

function CarInput.start()
	task.spawn(function()
		local ok, module = pcall(function()
			return require(
				player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule", 10) :: ModuleScript
			)
		end)
		if ok and module then
			controls = module:GetControls()
		end
	end)

	local lastThrottle, lastSteer, lastSent = 0, 0, 0
	local driving = false
	RunService.Heartbeat:Connect(function()
		if not inDriverSeat() then
			driving = false
			return
		end
		local throttle, steer = readInput()
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
