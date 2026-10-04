-- The spawn lobby: a marble floor ringed by glass under a glass dome, with one force-field
-- gate toward each landmark. Gates block players until they pick a loadout.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local WeaponCatalog = require(ReplicatedStorage.Shared.WeaponCatalog)
local Build = require(script.Parent.Build)

local Lobby = {}

local rgb = Color3.fromRGB
local MARBLE = rgb(235, 235, 240)
local GLASS = rgb(170, 220, 255)
local FRAME = rgb(60, 65, 80)
local GATE = rgb(255, 60, 90)

local GATE_WIDTH = 16
local PANELS = 72

local function angleGap(a: number, b: number): number
	return math.abs((a - b + math.pi) % (2 * math.pi) - math.pi)
end

function Lobby.build(parent: Instance, displayModel: (weaponId: string) -> Model?)
	local model = Build.model("Lobby", parent)
	local R = Config.LOBBY_RADIUS
	local H = Config.LOBBY_WALL_HEIGHT
	local floorTop = 1

	Build.column(
		model,
		CFrame.new(0, floorTop / 2, 0),
		floorTop,
		R * 2 + 4,
		MARBLE,
		Enum.Material.Marble
	)
	Build.column(
		model,
		CFrame.new(0, floorTop + 0.05, 0),
		0.1,
		34,
		rgb(255, 60, 90),
		Enum.Material.Neon,
		{ canCollide = false }
	)
	Build.column(
		model,
		CFrame.new(0, floorTop + 0.06, 0),
		0.1,
		31,
		MARBLE,
		Enum.Material.Marble,
		{ canCollide = false }
	)

	-- Glass wall with gaps at each gate.
	local gateAngles = {}
	for index = 1, #Config.REGIONS do
		table.insert(gateAngles, Config.regionAngle(index))
	end
	local gateHalfAngle = (GATE_WIDTH / 2) / R
	local panelWidth = 2 * math.pi * R / PANELS
	for index = 0, PANELS - 1 do
		local angle = index / PANELS * 2 * math.pi
		local blocked = false
		for _, gateAngle in gateAngles do
			if angleGap(angle, gateAngle) < gateHalfAngle + 0.02 then
				blocked = true
			end
		end
		if not blocked then
			local position = Config.pointAt(angle, R, floorTop + H / 2)
			Build.part(
				model,
				Vector3.new(panelWidth + 0.3, H, 0.6),
				CFrame.lookAt(position, Vector3.new(0, position.Y, 0)),
				GLASS,
				Enum.Material.Glass,
				{ transparency = 0.6, reflectance = 0.15 }
			)
			if index % 6 == 0 then
				Build.part(
					model,
					Vector3.new(1, H, 1.2),
					CFrame.lookAt(position, Vector3.new(0, position.Y, 0)),
					FRAME,
					Enum.Material.Metal
				)
			end
		end
	end

	-- Gates: physical barriers in their own collision group, plus a destination sign.
	for index, region in Config.REGIONS do
		local angle = Config.regionAngle(index)
		local position = Config.pointAt(angle, R, floorTop + H / 2)
		local facing = CFrame.lookAt(position, Vector3.new(0, position.Y, 0))
		local gate = Build.part(
			model,
			Vector3.new(GATE_WIDTH + 2, H, 0.5),
			facing,
			GATE,
			Enum.Material.ForceField,
			{
				transparency = 0.35,
				name = "Gate",
			}
		)
		gate.CollisionGroup = "LobbyGate"
		for _, side in { -1, 1 } do
			Build.part(
				model,
				Vector3.new(2, H + 2, 2),
				facing * CFrame.new(side * (GATE_WIDTH / 2 + 1.5), 1, 0),
				FRAME,
				Enum.Material.Metal
			)
		end
		Build.part(
			model,
			Vector3.new(GATE_WIDTH + 5, 2, 2),
			facing * CFrame.new(0, H / 2 + 1, 0),
			FRAME,
			Enum.Material.Metal
		)
		Build.billboard(
			model,
			Config.pointAt(angle, R - 6, floorTop + H - 4),
			"➜ " .. region.name,
			rgb(255, 255, 255),
			30
		)
	end

	-- Dome: latitude bands of panels facing the dome center.
	local domeCenter = Vector3.new(0, floorTop + H, 0)
	local bandStep = math.rad(15)
	for band = 0, 4 do
		local phi = (band + 0.5) * bandStep
		local ringRadius = R * math.cos(phi)
		local segments = math.max(10, math.floor(PANELS * math.cos(phi)))
		for segment = 0, segments - 1 do
			local theta = segment / segments * 2 * math.pi
			local position = domeCenter
				+ Vector3.new(
					math.cos(theta) * ringRadius,
					R * math.sin(phi),
					math.sin(theta) * ringRadius
				)
			Build.part(
				model,
				Vector3.new(2 * math.pi * ringRadius / segments + 0.4, R * bandStep + 0.4, 0.5),
				CFrame.lookAt(position, domeCenter),
				GLASS,
				Enum.Material.Glass,
				{ transparency = 0.7, reflectance = 0.1, castShadow = false }
			)
		end
	end
	Build.column(
		model,
		CFrame.new(domeCenter + Vector3.new(0, R * math.sin(math.rad(76)), 0)),
		0.6,
		2 * R * math.cos(math.rad(75)) + 2,
		GLASS,
		Enum.Material.Glass,
		{ transparency = 0.7, castShadow = false }
	)

	-- Spawn pads.
	for index = 0, 5 do
		local angle = index / 6 * 2 * math.pi + math.rad(30)
		local spawn = Instance.new("SpawnLocation")
		spawn.Name = "LobbySpawn"
		spawn.Anchored = true
		spawn.Neutral = true
		spawn.Duration = 0
		spawn.Size = Vector3.new(6, 1, 6)
		spawn.CFrame = CFrame.lookAt(
			Config.pointAt(angle, 22, floorTop + 0.5),
			Vector3.new(0, floorTop + 0.5, 0)
		)
		spawn.Color = rgb(255, 60, 90)
		spawn.Material = Enum.Material.Neon
		spawn.TopSurface = Enum.SurfaceType.Smooth
		spawn.Parent = model
	end

	-- Title over the room.
	Build.billboard(model, Vector3.new(0, floorTop + 20, 0), "MAYHEM", rgb(255, 70, 100), 46)

	-- Weapon showcase: pedestals with spinning sample weapons between the gates.
	local displays = {}
	local pick = Random.new(4)
	for index = 1, #Config.REGIONS do
		local angle = Config.regionAngle(index) + math.rad(36)
		local position = Config.pointAt(angle, R - 12, floorTop)
		Build.column(
			model,
			CFrame.new(position + Vector3.new(0, 2, 0)),
			4,
			5,
			FRAME,
			Enum.Material.Metal
		)
		Build.column(
			model,
			CFrame.new(position + Vector3.new(0, 4.1, 0)),
			0.2,
			4,
			GATE,
			Enum.Material.Neon
		)
		local weapon = WeaponCatalog.ALL[pick:NextInteger(1, #WeaponCatalog.ALL)]
		local showcase = displayModel(weapon.id)
		if showcase then
			showcase.Parent = model
			Build.billboard(
				model,
				position + Vector3.new(0, 11, 0),
				weapon.name,
				rgb(255, 230, 120),
				12
			)
			table.insert(displays, { model = showcase, center = position + Vector3.new(0, 7, 0) })
		end
	end
	RunService.Heartbeat:Connect(function()
		local spin = CFrame.Angles(0, os.clock() * 1.2, 0) * CFrame.Angles(0, 0, math.rad(20))
		for _, display in displays do
			display.model:PivotTo(
				CFrame.new(display.center + Vector3.new(0, math.sin(os.clock() * 2) * 0.5, 0))
					* spin
			)
		end
	end)

	return model
end

return Lobby
