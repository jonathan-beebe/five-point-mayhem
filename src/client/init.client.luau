-- Client bootstrap. Each feature starts in its own thread so one failure cannot stop the rest.

local Announcer = require(script.Announcer)
local LobbyUI = require(script.LobbyUI)
local WeaponInput = require(script.WeaponInput)
local AdminPanel = require(script.AdminPanel)
local CarInput = require(script.CarInput)
local SniperScope = require(script.SniperScope)

for _, feature in { Announcer, LobbyUI, WeaponInput, AdminPanel, CarInput, SniperScope } do
	task.spawn(feature.start)
end
