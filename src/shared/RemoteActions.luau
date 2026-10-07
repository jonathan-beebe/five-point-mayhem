--!strict
-- The string arguments that pick an action on a remote (src/shared/Remotes.luau). Both ends compare
-- against these. Pure data, no requires: the Lune tests read it. Constants are UPPER_CASE
-- (`PodCommand.LAUNCH = "launch"`); tools/tests/names.luau pins their values.

return table.freeze({
	-- Remotes.Announce's `style` (nil: a plain banner). Announcer draws the flash.
	AnnounceStyle = table.freeze({
		ALARM = "alarm", -- a red flash
		MAYHEM = "mayhem", -- a white flash fading to red
	}),
	-- Remotes.MacCommand's action: the MAC panel's buttons (Admin runs them).
	MacCommand = table.freeze({
		NUKE = "nuke",
		SNIPER = "sniper",
	}),
	-- Remotes.PodCommand's action, for the pod the player drives (PodFlight runs them).
	PodCommand = table.freeze({
		DRONE = "drone", -- toggles the legs' drone mode (they follow the flying pod)
		HOME = "home",
		LAND = "land",
		LAUNCH = "launch",
	}),
})
