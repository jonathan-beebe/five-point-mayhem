--!strict
-- Weapon math the server's weapon modules (systems/Weapons) apply. Pure: no requires, no services,
-- only the Luau standard library and Vector3/CFrame, so Lune loads it for tests
-- (`tools/tests/weapon_math.luau`). Each function is the inline code it replaced in Weapons.luau;
-- the test pins them bit for bit against that code.

local WeaponMath = {}

-- A shot counts as cooled down this share of the weapon's cooldown early, so a client firing on
-- its own cooldown clock is not refused for network jitter.
WeaponMath.COOLDOWN_SLACK = 0.85

-- `direction` turned by up to `degrees` in pitch and in yaw, each drawn from `random` (pitch first,
-- two NextNumber calls); `direction` itself when `degrees` <= 0 (no draws).
function WeaponMath.spreadDirection(direction: Vector3, degrees: number, random: Random): Vector3
	if degrees <= 0 then
		return direction
	end
	local frame = CFrame.lookAt(Vector3.zero, direction)
	local pitch = math.rad(random:NextNumber(-degrees, degrees))
	local yaw = math.rad(random:NextNumber(-degrees, degrees))
	return (frame * CFrame.Angles(pitch, yaw, 0)).LookVector
end

-- Whether a weapon last fired at `last` (os.clock, nil if never) is still cooling down at `now`.
function WeaponMath.coolingDown(last: number?, now: number, cooldown: number): boolean
	return last ~= nil and now - last < cooldown * WeaponMath.COOLDOWN_SLACK
end

-- Whether a melee swing from `from` reaches a target at `to`: within `range` + 1.5 studs, and in
-- front (the flat offset's direction dotted with `flatLook`, the wielder's horizontal facing, at
-- least `minimumDot`) unless the target is within 2 studs horizontally.
function WeaponMath.inMeleeReach(
	flatLook: Vector3,
	minimumDot: number,
	from: Vector3,
	to: Vector3,
	range: number
): boolean
	local offset = to - from
	local flat = Vector3.new(offset.X, 0, offset.Z)
	local inReach = offset.Magnitude <= range + 1.5
	local inFront = flat.Magnitude < 2 or flatLook:Dot(flat.Unit) >= minimumDot
	return inReach and inFront
end

-- Whether a push from `origin` along `look` (a unit vector) reaches `position`: within `range`
-- and inside the cone where the dot with `look` exceeds 0.4.
function WeaponMath.inPushCone(
	look: Vector3,
	origin: Vector3,
	position: Vector3,
	range: number
): boolean
	local offset = position - origin
	return offset.Magnitude <= range and look:Dot(offset.Unit) > 0.4
end

-- One step of a projectile under `gravity` (studs/s^2, downward) over `dt`: the move (the mean of
-- the old and new velocity, times dt) and the new velocity.
function WeaponMath.projectileStep(
	velocity: Vector3,
	gravity: number,
	dt: number
): (Vector3, Vector3)
	local nextVelocity = velocity - Vector3.new(0, gravity * dt, 0)
	local step = (velocity + nextVelocity) / 2 * dt
	return step, nextVelocity
end

-- A ball projectile's diameter: a black hole's core, a blast shot's shell, or a bullet.
function WeaponMath.projectileSize(impact: string?, blast: number?): number
	return if impact == "blackhole" then 2.5 elseif blast then 1.6 else 0.8
end

-- An upright weapon's display hold, moved so its pieces (offsets scaled by `scale`) center
-- vertically on the pivot; `hold` unchanged without pieces.
function WeaponMath.centerUpright(
	hold: CFrame,
	pieces: { { offset: CFrame } },
	scale: number
): CFrame
	local low, high = math.huge, -math.huge
	for _, piece in pieces do
		local y = (hold * (piece.offset.Position * scale)).Y
		low = math.min(low, y)
		high = math.max(high, y)
	end
	if low <= high then
		hold = CFrame.new(0, -(low + high) / 2, 0) * hold
	end
	return hold
end

return WeaponMath
