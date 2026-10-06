-- Taking a sitter out of a seat on the server.

local Seats = {}

-- Takes `humanoid` out of `seat` at once: destroys the seat's SeatWeld (when there is one), then
-- sets Sit to false. `seat` nil skips the weld.
function Seats.unseat(seat: (Seat | VehicleSeat)?, humanoid: Humanoid)
	local weld = seat and seat:FindFirstChild("SeatWeld")
	if weld then
		weld:Destroy()
	end
	humanoid.Sit = false
end

return Seats
