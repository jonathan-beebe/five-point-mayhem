--!strict
-- Every admin command: its id, whether chat runs it (`/<id>`), and its GOD MODE panel button. The
-- server's Admin system dispatches each id to its handler (Admin.HANDLERS) and makes the chat
-- commands from CHAT; the client's AdminPanel draws POWERS and GIFTS. Also the power tuning and
-- the pure rules Admin applies (targets, gift labels, chat words, meteor duration).
-- tools/tests/admin_commands.luau checks every id has a handler and pins the lists and numbers.
--
-- Ids are a contract between AdminPanel, chat and the server: never change one.

local AdminCommands = {}

local rgb = Color3.fromRGB

-- A panel button. `slot` orders the buttons (four to a row); `targeted` buttons send the panel's
-- target as the command's first argument.
export type Panel = {
	slot: number,
	label: string,
	color: Color3,
	hint: string,
	targeted: boolean?,
}

export type Command = {
	id: string,
	chat: boolean, -- a `/<id>` chat command, made in this order
	panel: Panel?, -- a GOD MODE power button
}

-- `/give` has no button: the panel's gift menus send it.
AdminCommands.COMMANDS = {
	{
		id = "mayhem",
		chat = true,
		panel = {
			slot = 1,
			label = "☢ MAYHEM",
			color = rgb(200, 20, 30),
			hint = "Destroy everyone outside the lobby",
		},
	},
	{ id = "give", chat = true },
	{
		id = "meteors",
		chat = true,
		panel = {
			slot = 2,
			label = "☄ METEORS",
			color = rgb(220, 110, 30),
			hint = "30 second meteor storm",
		},
	},
	{
		id = "gravity",
		chat = true,
		panel = {
			slot = 3,
			label = "🌙 GRAVITY",
			color = rgb(70, 90, 180),
			hint = "Toggle moon gravity",
		},
	},
	{
		id = "freeze",
		chat = true,
		panel = {
			slot = 4,
			label = "❄ FREEZE",
			color = rgb(60, 160, 210),
			hint = "Freeze the target",
			targeted = true,
		},
	},
	{
		id = "horde",
		chat = true,
		panel = {
			slot = 7,
			label = "👹 HORDE",
			color = rgb(60, 140, 50),
			hint = "Summon monsters",
			targeted = true,
		},
	},
	{
		id = "day",
		chat = true,
		panel = {
			slot = 5,
			label = "☀ DAY",
			color = rgb(220, 170, 40),
			hint = "Jump to morning",
		},
	},
	{
		id = "night",
		chat = true,
		panel = {
			slot = 6,
			label = "🌑 NIGHT",
			color = rgb(50, 40, 90),
			hint = "Jump to nightfall",
		},
	},
} :: { Command }

-- The chat commands' ids, in COMMANDS order.
AdminCommands.CHAT = {} :: { string }
-- The panel's power buttons, by slot, in the shape AdminPanel reads.
export type Power = {
	command: string,
	label: string,
	color: Color3,
	hint: string,
	targeted: boolean?,
}
AdminCommands.POWERS = {} :: { Power }
local slots: { [Power]: number } = {}
for _, command in AdminCommands.COMMANDS do
	if command.chat then
		table.insert(AdminCommands.CHAT, command.id)
	end
	local panel = command.panel
	if panel then
		local power = {
			command = command.id,
			label = panel.label,
			color = panel.color,
			hint = panel.hint,
			targeted = panel.targeted,
		}
		slots[power] = panel.slot
		table.insert(AdminCommands.POWERS, power)
	end
end
table.sort(AdminCommands.POWERS, function(a, b)
	return slots[a] < slots[b]
end)

-- `/give` items that are power-ups (not a weapon or vehicle id); their banner label is the id in
-- capitals. Admin's `gift` handles each (`POWER_UP`, plus its `arsenal` and `car` branches).
AdminCommands.POWER_UPS = { "speed", "jump", "giant", "heal", "shield", "car", "arsenal" }

-- The panel's gift menu: power-ups and one weapon, in menu order.
AdminCommands.GIFTS = {
	{ id = "arsenal", label = "🧰 EVERY WEAPON" },
	{ id = "sniper", label = "🎯 Sniper Rifle" },
	{ id = "heal", label = "❤ Full heal" },
	{ id = "shield", label = "🛡 Shield (30s)" },
	{ id = "speed", label = "👟 Super speed" },
	{ id = "jump", label = "🦘 Mega jump" },
	{ id = "giant", label = "🗿 Giant" },
	{ id = "car", label = "🚙 Random vehicle" },
}

-- Power tuning. README's God mode section quotes these.
AdminCommands.TUNING = {
	SPEED = 40, -- `speed`: walk speed (BaseWalkSpeed too)
	JUMP_POWER = 120, -- `jump`
	GIANT_SCALE = 2.5, -- `giant`: every body scale and the head
	SHIELD_SECONDS = 30, -- `shield`: the ForceField's life
	FREEZE_SECONDS = 10,
	HORDE_AROUND_PLAYER = 12, -- `/horde <who>`: monsters around each target
	HORDE_PER_REGION = 6, -- `/horde`: monsters between each pair of landmarks
	METEOR_RADIUS = 16, -- each meteor's blast
	METEOR_DAMAGE = 45,
	METEOR_SECONDS = 30, -- `/meteors` with no (or no number for) seconds
	METEOR_MIN_SECONDS = 5,
	METEOR_MAX_SECONDS = 120,
}

-- The players `who` names, from `players`: all of them for "all" or "everyone", the caller for
-- "me" (and for nil), else the first whose name or display name (`names` returns both: Roblox's
-- Player class does not convert to a table type, so a structural Name/DisplayName type cannot
-- take one) starts with `who`, case-insensitive; empty when none does.
function AdminCommands.resolveTargets<T>(
	players: { T },
	caller: T,
	who: string?,
	names: (T) -> (string, string)
): { T }
	local query = string.lower(who or "me")
	if query == "all" or query == "everyone" then
		return players
	elseif query == "me" then
		return { caller }
	end
	for _, player in players do
		local playerName, displayName = names(player)
		local name = string.lower(playerName)
		local display = string.lower(displayName)
		if string.sub(name, 1, #query) == query or string.sub(display, 1, #query) == query then
			return { player }
		end
	end
	return {}
end

-- The banner label for giving `query` (lower case): a power-up in capitals, else the vehicle's or
-- the weapon's name (the catalog entries `query` found, if any); nil for an unknown item.
function AdminCommands.giftLabel(
	query: string,
	vehicle: { name: string }?,
	weapon: { name: string }?
): string?
	return if table.find(AdminCommands.POWER_UPS, query)
		then string.upper(query)
		elseif vehicle then vehicle.name
		elseif weapon then weapon.name
		else nil
end

-- A chat command's arguments: the second, third and fourth space-separated words of `text`.
function AdminCommands.chatArguments(text: string): (string?, string?, string?)
	local words = string.split(text, " ")
	return words[2], words[3], words[4]
end

-- `/meteors [seconds]`: the storm's length from its first argument.
function AdminCommands.meteorSeconds(first: string?): number
	local tuning = AdminCommands.TUNING
	return math.clamp(
		tonumber(first) or tuning.METEOR_SECONDS,
		tuning.METEOR_MIN_SECONDS,
		tuning.METEOR_MAX_SECONDS
	)
end

return AdminCommands
