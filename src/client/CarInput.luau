-- While the local player sits in a Mayhem car's driver seat, sends throttle and steer to the
-- server. Reads, in order: WASD/arrow keys, the driver seat's ThrottleFloat/SteerFloat (written
-- locally by the default control scripts from the thumbstick or gamepad), and the default
-- controls' move vector. Also sends `lift` for flying pods: E climbs, Q descends, plus the touch
-- buttons (PodControls).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local DriveAxes = require(ReplicatedStorage.Shared.DriveAxes)
local Names = require(ReplicatedStorage.Shared.Names)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local PodControls = require(script.Parent.PodControls)

local CarInput = {}

local player = Players.LocalPlayer
local K = Enum.KeyCode

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

local function readLift(): number
	if UserInputService:GetFocusedTextBox() then
		return 0
	end
	return DriveAxes.lift(keyAxis({ K.E }, { K.Q }), PodControls.lift())
end

local function readInput(seat: VehicleSeat): (number, number)
	if UserInputService:GetFocusedTextBox() then
		return 0, 0 -- typing in chat
	end
	local throttle, steer = DriveAxes.keysOrSeat(
		keyAxis({ K.W, K.Up }, { K.S, K.Down }),
		keyAxis({ K.D, K.Right }, { K.A, K.Left }),
		seat.ThrottleFloat,
		seat.SteerFloat
	)
	local current = if throttle == 0 and steer == 0 then getControls() else nil
	if current then
		local ok, move = pcall(current.GetMoveVector, current)
		if ok and typeof(move) == "Vector3" then
			throttle, steer = DriveAxes.fromMoveVector(move)
		end
	end
	return DriveAxes.clamp(throttle, steer)
end

local function driverSeat(): VehicleSeat?
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local seat = humanoid and humanoid.SeatPart
	if
		seat
		and seat:IsA("VehicleSeat")
		and seat:GetAttribute(Names.Attributes.MayhemCar) == true
	then
		return seat
	end
	return nil
end

function CarInput.start()
	local sent = DriveAxes.newSent()
	RunService.Heartbeat:Connect(function()
		local seat = driverSeat()
		if not seat then
			sent.driving = false
			return
		end
		local throttle, steer = readInput(seat)
		local lift = readLift()
		if DriveAxes.send(sent, throttle, steer, lift, os.clock()) then
			Remotes.DriveInput:FireServer(throttle, steer, lift)
		end
	end)
end

return CarInput
