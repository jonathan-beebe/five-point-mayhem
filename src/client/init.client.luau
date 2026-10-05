-- Client bootstrap. Each feature starts in its own thread so one failure cannot stop the rest.

local Announcer = require(script.Announcer)
local LobbyUI = require(script.LobbyUI)
local WeaponInput = require(script.WeaponInput)
local AdminPanel = require(script.AdminPanel)
local MapPanel = require(script.MapPanel)
local CarInput = require(script.CarInput)
local SniperScope = require(script.SniperScope)
local MechMotion = require(script.MechMotion)
local MechCamera = require(script.MechCamera)
local VehicleSounds = require(script.VehicleSounds)
local NukeStrike = require(script.NukeStrike)

for _, feature in
	{
		Announcer,
		LobbyUI,
		WeaponInput,
		AdminPanel,
		MapPanel,
		CarInput,
		SniperScope,
		MechMotion,
		MechCamera,
		VehicleSounds,
		NukeStrike,
	}
do
	task.spawn(feature.start)
end
