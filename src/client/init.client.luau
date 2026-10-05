-- Client bootstrap. Each feature starts in its own thread so one failure cannot stop the rest.

local Announcer = require(script.Announcer)
local LobbyUI = require(script.LobbyUI)
local WeaponInput = require(script.WeaponInput)
local AdminPanel = require(script.AdminPanel)
local MacPanel = require(script.MacPanel)
local CarInput = require(script.CarInput)
local SniperScope = require(script.SniperScope)
local MechMotion = require(script.MechMotion)
local MechCamera = require(script.MechCamera)
local PodControls = require(script.PodControls)
local VehicleSounds = require(script.VehicleSounds)
local NukeStrike = require(script.NukeStrike)
local SoundProbe = require(script.SoundProbe) -- TEMPORARY

for _, feature in
	{
		SoundProbe, -- TEMPORARY
		Announcer,
		LobbyUI,
		WeaponInput,
		AdminPanel,
		MacPanel,
		CarInput,
		SniperScope,
		MechMotion,
		MechCamera,
		PodControls,
		VehicleSounds,
		NukeStrike,
	}
do
	task.spawn(feature.start)
end
