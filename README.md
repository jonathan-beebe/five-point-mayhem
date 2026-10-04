# Mayhem

Roblox arena game. The entire world is built from code at server start (`src/server/world`).

## Develop

```sh
rokit install
rojo serve      # then connect from the Rojo plugin in Studio and press Play
```

## Layout

| Path | What |
| --- | --- |
| `src/shared/Config.luau` | World layout, teams, admin user ids |
| `src/shared/WeaponCatalog.luau` | All 52 weapons (data only) |
| `src/shared/VehicleCatalog.luau` | All vehicles (data only) |
| `src/server/vehicleModels` | One part-built model per vehicle (format: `src/server/systems/VehicleModel.luau`) |
| `tools/preview` | Renders a vehicle model file to a PNG of orthographic views |
| `src/server/world` | Lobby, roads, terrain/scenery, the five landmarks |
| `src/server/systems` | Combat, weapons, players/teams, creatures, vehicles, admin powers |
| `src/client` | Armory UI, weapon input, car input, admin panel, announcer |

## God mode

### Who is an admin

| Where | Admins |
| --- | --- |
| Studio test sessions | Everyone |
| Published, user-owned place | The owner |
| Published, group-owned place | Group rank 255 (the group owner) |
| Anywhere | Every UserId in `Config.ADMIN_USER_IDS` (`src/shared/Config.luau`) |

A UserId is the number in a profile URL: `roblox.com/users/<UserId>/profile`.
The server checks admin rights on every command, from both the panel and chat. A non-admin's
command does nothing.

Every power announces itself to all players with a banner across the top of the screen.

### The panel

Admins see a **👑 GOD MODE** button in the top-right corner. It opens the panel:

```
┌──────────────────────────────────┐
│ 🎯 Target: EVERYONE (tap to change) │  cycles EVERYONE → each player
├────────────────┬─────────────────┤
│   ☢ MAYHEM     │   ☄ METEORS     │
│   🌙 GRAVITY   │   ❄ FREEZE      │  FREEZE and HORDE use the target
│   👹 HORDE     │   🌓 NIGHT      │
├────────────────┴─────────────────┤
│ 🎁 GIVE TO TARGET                 │
│   🧰 EVERY WEAPON                 │
│   ❤ Full heal                     │
│   🛡 Shield (30s)                 │  gifts, then all 52 weapons;
│   👟 Super speed                  │  tap one to give it to the target
│   🦘 Mega jump                    │
│   🗿 Giant                        │
│   🚙 Random vehicle               │
│   Knight Sword …                  │
└──────────────────────────────────┘
```

### Chat commands

Type these in chat. `<who>` is `all` (or `everyone`), `me`, or the start of a player's username
or display name, case-insensitive. The first matching player wins.

| Command | Panel button | Effect |
| --- | --- | --- |
| `/mayhem` | ☢ MAYHEM | Destroy everyone outside the lobby |
| `/give <who> <item>` | 🎁 list | Give a weapon or power-up |
| `/meteors [seconds]` | ☄ METEORS | Meteor storm across the board |
| `/gravity` | 🌙 GRAVITY | Toggle moon gravity |
| `/freeze [who]` | ❄ FREEZE | Freeze players in ice |
| `/horde [who]` | 👹 HORDE | Summon a monster horde |
| `/night` | 🌓 NIGHT | Toggle day and night |

### The powers

**☢ MAYHEM** — `/mayhem`

- The screen tints red and counts down 3, 2, 1, then flashes white.
- Every player outside the lobby explodes and dies, shields included. Players in the lobby survive.
- Every monster dies too. Roaming monsters come back after 25 seconds; horde monsters do not.
- Everyone respawns in the lobby and picks a new loadout.
- Pressing it again during the countdown does nothing.

**🎁 GIVE** — `/give <who> <item>`

Both `<who>` and `<item>` are required. Examples: `/give all rocket`, `/give me arsenal`,
`/give sam shield`.

| Item | Effect | Lasts |
| --- | --- | --- |
| `arsenal` | All 52 weapons into the backpack | Until death |
| `heal` | Full health | — |
| `shield` | Force field: immune to all damage except MAYHEM | 30 seconds |
| `speed` | Walk speed 40 (normal is 16) | Until death |
| `jump` | Jump power 120 (normal is 50) | Until death |
| `giant` | 2.5× size | Until death |
| `car` | A random vehicle appears in front of the player | Until it is wrecked or abandoned |
| any vehicle id | That vehicle appears in front of the player | Until it is wrecked or abandoned |
| any weapon | That weapon into the backpack | Until death |

- A weapon matches by its id or by the start of its name: `rocket` gives the Rocket Launcher.
- Power-up names win over weapon names. Use these to get the weapon instead: `giant_lollipop`
  (not `giant`), `healing` (not `heal`), `bomb` (not `car`, which would match Cartoon Bomb).
- Players in the lobby lose gifted weapons when they press ENTER THE MAYHEM, because their
  backpack is replaced with their chosen loadout. Gift weapons after they deploy.

**☄ METEORS** — `/meteors [seconds]`

- Default 30 seconds, minimum 5, maximum 120. The panel button always runs 30.
- Three flaming meteors fall every 0.35 seconds at random spots on the board.
- Each impact explodes: 45 damage within 16 studs, and sets targets on fire.
- Hits players and monsters alike. The lobby is safe.

**🌙 GRAVITY** — `/gravity`

- Toggles between moon gravity (38) and normal gravity (196.2) for everyone.
- Moon gravity makes jumps huge and grenades and cars float.

**❄ FREEZE** — `/freeze [who]`

- Encases each target in ice for 10 seconds: they cannot move or fire.
- No target, `all`, or EVERYONE in the panel freezes everyone except you. Use `me` to freeze yourself.
- Players in the lobby are skipped.

**👹 HORDE** — `/horde [who]`

- With a target: 12 monsters appear 25–60 studs around each targeted player.
- Without one (EVERYONE in the panel): 6 monsters appear at each of the 5 points between the
  landmarks, 30 in all.
- Mostly zombies, with goblins, slimes, brutes, and every landmark monster mixed in.
- Summoned monsters do not respawn. The game caps monsters at 170 alive.

**🌓 NIGHT** — `/night`

- Fades to midnight over 3 seconds, or back to mid-afternoon.

## Vehicles

Every vehicle parks in the motor pools along the five spoke roads outside the lobby. From any side
of a vehicle, press **E** (or tap **Drive**) to take the driver's seat, or **F** (**Ride**) for the
free passenger seat nearest you. A passenger can press **E** to move to the empty driver's seat.
Wrecked or abandoned vehicles return to their spot. The ids in `src/shared/VehicleCatalog.luau`
work with `/give`, e.g. `/give me abrams`.

Preview a vehicle model without Studio (needs `lune` from `rokit install` and Python with Pillow):

```sh
python3 tools/preview/render.py src/server/vehicleModels/abrams.luau abrams.png
```

## Weapon ids

For `/give`. The start of a weapon's name also works.

| Category | Weapons |
| --- | --- |
| Blades | `knight_sword` (Knight Sword), `katana` (Katana), `battle_axe` (Battle Axe), `war_hammer` (War Hammer), `spear` (Spartan Spear), `scythe` (Reaper Scythe), `plasma_blade` (Plasma Blade), `ice_dagger` (Frost Dagger), `trident` (Sea Trident), `frying_pan` (Frying Pan) |
| Guns | `pistol` (Pistol), `revolver` (Revolver), `golden_pistol` (Golden Pistol), `shotgun` (Shotgun), `double_barrel` (Double Barrel), `smg` (SMG), `assault_rifle` (Assault Rifle), `sniper` (Sniper Rifle), `minigun` (Minigun), `crossbow` (Crossbow) |
| Blasters | `laser_pistol` (Laser Pistol), `laser_rifle` (Laser Rifle), `ray_gun` (Ray Gun), `freeze_ray` (Freeze Ray), `tesla_gun` (Tesla Gun), `bounce_ray` (Bounce Ray), `plasma_cannon` (Plasma Cannon) |
| Explosives | `rocket_launcher` (Rocket Launcher), `bazooka` (Bazooka), `grenade_launcher` (Grenade Launcher), `missile_swarm` (Missile Swarm), `firework_launcher` (Firework Launcher), `bomb` (Cartoon Bomb), `mini_nuke` (Mini Nuke) |
| Magic | `fire_staff` (Fire Staff), `ice_wand` (Ice Wand), `lightning_staff` (Lightning Staff), `meteor_staff` (Meteor Staff), `healing_staff` (Healing Staff), `teleport_wand` (Teleport Wand), `gravity_gauntlet` (Gravity Gauntlet), `black_hole` (Black Hole Orb), `bubble_wand` (Bubble Wand) |
| Silly | `rubber_chicken` (Rubber Chicken), `pool_noodle` (Pool Noodle), `giant_lollipop` (Giant Lollipop), `slingshot` (Slingshot), `snowball` (Snowball), `water_balloon` (Water Balloon), `tomato_launcher` (Tomato Launcher), `banana_launcher` (Banana Launcher), `confetti_cannon` (Confetti Cannon) |

## Notes

- Chat commands need the default TextChatService chat, which new places use. If they do nothing,
  the panel performs the same commands.
- The source of truth is `src/server/systems/Admin.luau` (commands) and
  `src/client/AdminPanel.luau` (panel).
