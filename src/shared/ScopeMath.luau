--!strict
-- The math of client SniperScope: the overlay's lens and the four black bars around it, the
-- target heading's turn and pitch limit, and the pitch of a look direction. Pure: no requires.
-- The scoped view's yaw comes from MathUtil.yawOf.
--
--   overlay(viewport)                     lens size, its stroke thickness, and each bar's frame
--   turn(yaw, pitch, yawDeg, pitchDeg)    the target heading turned by input, pitch clamped
--   pitchOf(look)                         the clamped pitch of a look direction
--
-- tools/tests/client_logic.luau compares each with the inline code it replaced.

local ScopeMath = {}

ScopeMath.MAX_PITCH = math.rad(80)
ScopeMath.VIEW_FRACTION = 0.9 -- scope circle diameter as a fraction of the shorter screen side

export type Overlay = {
	lensSize: UDim2,
	stroke: number,
	topPosition: UDim2,
	topSize: UDim2,
	bottomPosition: UDim2,
	bottomSize: UDim2,
	leftPosition: UDim2,
	leftSize: UDim2,
	rightPosition: UDim2,
	rightSize: UDim2,
}

-- A lens centred on the screen; four bars cover everything outside its bounding square.
function ScopeMath.overlay(viewport: Vector2): Overlay
	local diameter = math.floor(math.min(viewport.X, viewport.Y) * ScopeMath.VIEW_FRACTION)
	local x0 = math.floor((viewport.X - diameter) / 2)
	local y0 = math.floor((viewport.Y - diameter) / 2)
	return {
		lensSize = UDim2.fromOffset(diameter, diameter),
		-- A square's corner sits radius * (sqrt(2) - 1) outside its inscribed circle.
		stroke = math.ceil(diameter / 2 * (math.sqrt(2) - 1)) + 2,
		topPosition = UDim2.fromOffset(0, 0),
		topSize = UDim2.new(1, 0, 0, y0),
		bottomPosition = UDim2.fromOffset(0, y0 + diameter),
		bottomSize = UDim2.new(1, 0, 1, -(y0 + diameter)),
		leftPosition = UDim2.fromOffset(0, y0),
		leftSize = UDim2.fromOffset(x0, diameter),
		rightPosition = UDim2.fromOffset(x0 + diameter, y0),
		rightSize = UDim2.new(1, -(x0 + diameter), 0, diameter),
	}
end

-- Turns the target heading (radians) by input in degrees: positive yaw turns right, positive
-- pitch looks down.
function ScopeMath.turn(
	targetYaw: number,
	targetPitch: number,
	yawDegrees: number,
	pitchDegrees: number
): (number, number)
	targetYaw -= math.rad(yawDegrees)
	targetPitch =
		math.clamp(targetPitch - math.rad(pitchDegrees), -ScopeMath.MAX_PITCH, ScopeMath.MAX_PITCH)
	return targetYaw, targetPitch
end

function ScopeMath.pitchOf(look: Vector3): number
	return math.clamp(
		math.asin(math.clamp(look.Y, -1, 1)),
		-ScopeMath.MAX_PITCH,
		ScopeMath.MAX_PITCH
	)
end

return table.freeze(ScopeMath)
