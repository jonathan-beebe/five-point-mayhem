--!strict
-- The vehicle health bar's numbers (client VehicleHealth): the fill share, its colour and the
-- label, from the model's Health and MaxHealth attributes. Pure: no requires.
--
--   read(health, maxHealth)       attribute values (nil when unset) to health, max (at least 1)
--                                 and the share 0..1
--   colorFor(share)               green at full health, yellow at half, red at none
--   labelText(name, health, max)  "<name>  <health rounded up> / <max>"
--   speedText(speed)              "<speed rounded> spd" (studs/s); a non-finite speed reads 0
--
-- tools/tests/client_logic.luau compares each with the inline code it replaced.

local HealthBar = {}

local rgb = Color3.fromRGB

HealthBar.HEALTHY = rgb(70, 210, 90)
HealthBar.HURT = rgb(245, 200, 40)
HealthBar.CRITICAL = rgb(230, 50, 40)

function HealthBar.read(health: number?, maxHealth: number?): (number, number, number)
	local current = health or 0
	local most = math.max(maxHealth or 1, 1)
	return current, most, math.clamp(current / most, 0, 1)
end

function HealthBar.colorFor(share: number): Color3
	if share >= 0.5 then
		return HealthBar.HURT:Lerp(HealthBar.HEALTHY, (share - 0.5) * 2)
	end
	return HealthBar.CRITICAL:Lerp(HealthBar.HURT, share * 2)
end

function HealthBar.labelText(name: string, health: number, maxHealth: number): string
	return string.format("%s  %d / %d", name, math.ceil(health), maxHealth)
end

function HealthBar.speedText(speed: number): string
	local finite = speed == speed and math.abs(speed) ~= math.huge
	return string.format("%d spd", if finite then math.round(speed) else 0)
end

return table.freeze(HealthBar)
