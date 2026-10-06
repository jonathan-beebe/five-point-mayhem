--!strict
-- Small math helpers shared by server and client systems. Pure: no requires, no services, only
-- the Luau standard library and Vector3/CFrame, so Lune loads it for tests
-- (`tools/tests/math_util.luau`). Each function is the expression its callers used inline before;
-- the test pins them bit for bit against those expressions.

local MathUtil = {}

-- `current` moved toward `target` by at most `step` (step >= 0), never past it.
function MathUtil.moveToward(current: number, target: number, step: number): number
	if current < target then
		return math.min(current + step, target)
	end
	return math.max(current - step, target)
end

-- `angle` (radians) wrapped into [-pi, pi]; floating-point rounding can return +pi.
function MathUtil.wrapAngle(angle: number): number
	return (angle + math.pi) % (2 * math.pi) - math.pi
end

-- The yaw (radians about +Y) that turns -Z to face `direction`'s horizontal part, as
-- `CFrame.Angles(0, yaw, 0)` takes it. A zero horizontal part gives -pi (atan2(-0, -0)).
function MathUtil.yawOf(direction: Vector3): number
	return math.atan2(-direction.X, -direction.Z)
end

-- Whether `point` is inside (or on a face of) the box of `size` centered at `cframe`.
function MathUtil.insideBox(cframe: CFrame, size: Vector3, point: Vector3): boolean
	local offset = cframe:PointToObjectSpace(point)
	local half = size / 2
	return math.abs(offset.X) <= half.X
		and math.abs(offset.Y) <= half.Y
		and math.abs(offset.Z) <= half.Z
end

-- `aim`, pulled back along the line from `origin` to at most `range` away.
function MathUtil.clampToRange(origin: Vector3, aim: Vector3, range: number): Vector3
	local offset = aim - origin
	return if offset.Magnitude > range then origin + offset.Unit * range else aim
end

-- The fraction of the remaining gap an exponential follow closes in `dt` seconds:
-- `value += (target - value) * alpha`. `rateAlpha` takes a rate per second, `timeAlpha` a time
-- constant in seconds.
function MathUtil.rateAlpha(rate: number, dt: number): number
	return 1 - math.exp(-rate * dt)
end

function MathUtil.timeAlpha(seconds: number, dt: number): number
	return 1 - math.exp(-dt / seconds)
end

return MathUtil
