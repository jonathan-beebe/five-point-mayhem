-- TEMPORARY diagnostic: which sound plays when the game starts. For the first 30 seconds, logs
-- every Sound that starts playing on this client: its name, asset, volume and where it lives.
-- Delete this file and its line in init.client.luau once the cause is known.

local SoundProbe = {}

local WINDOW = 30

function SoundProbe.start()
	local started = os.clock()
	local function report(sound: Sound, how: string)
		print(
			string.format(
				"[SoundProbe] t=%.2f %s %s id=%s vol=%.2f in %s",
				os.clock() - started,
				how,
				sound.Name,
				sound.SoundId,
				sound.Volume,
				if sound.Parent then sound.Parent:GetFullName() else "nil"
			)
		)
	end
	local function watch(instance: Instance)
		if not instance:IsA("Sound") then
			return
		end
		local sound = instance :: Sound
		if sound.Playing then
			report(sound, "already playing")
		end
		sound.Played:Connect(function()
			report(sound, "played")
		end)
		sound:GetPropertyChangedSignal("Playing"):Connect(function()
			if sound.Playing then
				report(sound, "playing")
			end
		end)
	end
	for _, instance in game:GetDescendants() do
		pcall(watch, instance)
	end
	local added = game.DescendantAdded:Connect(function(instance)
		pcall(watch, instance)
	end)
	task.delay(WINDOW, function()
		added:Disconnect()
		print("[SoundProbe] done")
	end)
end

return SoundProbe
