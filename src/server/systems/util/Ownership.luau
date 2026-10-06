-- Network ownership of physics parts. Roblox errors when ownership cannot change (an anchored
-- part, one welded to an anchored part), so every call through this module is protected.

local Ownership = {}

-- Sets `part`'s assembly's network owner: `player`, or the server for nil. Returns pcall's
-- results: true, or false and the error.
function Ownership.set(part: BasePart, player: Player?): (boolean, any)
	return pcall(part.SetNetworkOwner, part, player)
end

-- Whether the server simulates `part`: unanchored and owned by the server.
function Ownership.isServerSimulated(part: BasePart): boolean
	if part.Anchored then
		return false
	end
	local ok, owner = pcall(part.GetNetworkOwner, part)
	return ok and owner == nil
end

return Ownership
