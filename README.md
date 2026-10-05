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
| `src/server/creatureModels` | One part-built model per monster (format: `src/server/systems/CreatureModel.luau`) |
| `tools/preview` | Renders a vehicle, weapon or creature model file to a PNG of orthographic views |
| `tools/audition.luau` | Plays every weapon and vehicle sound; paste into the Studio Command Bar during Play |
| `src/server/world` | Lobby, roads, terrain/scenery, the five landmarks |
| `src/server/systems` | Combat, weapons, players/teams, creatures, vehicles, admin powers |
| `src/client` | Armory UI, weapon input, car input, mech animation and camera, admin panel, announcer |

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

### Back in the lobby

After deploying, admins walk in and out of the lobby through any gate. Inside, they keep their
weapons but cannot fire them, and nothing can hurt them. The armory stays closed and the server
ignores ENTER THE MAYHEM until they respawn. Admins walk in only: vehicles stop at the gates, and
the Teleport Wand cannot blink into the lobby.

Other players get one trip out. Once they step outside the lobby the gates block them, and a
player who gets back inside some other way is put outside the wall. They return to the lobby only
by respawning.

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
│   🔫 WEAPONS  ›                   │  opens a menu of all 52 weapons
│   🚙 VEHICLES  ›                  │  opens a menu of every vehicle except mechs
│   🤖 MECHS  ›                     │  opens a menu of the walkers
│   🧰 EVERY WEAPON                 │
│   🎯 Sniper Rifle                 │
│   ❤ Full heal                     │
│   🛡 Shield (30s)                 │  tap one to give it to the target
│   👟 Super speed                  │
│   🦘 Mega jump                    │
│   🗿 Giant                        │
│   🚙 Random vehicle               │
└──────────────────────────────────┘
```

In the WEAPONS, VEHICLES and MECHS menus, tap an item to give it to the target, or **‹ BACK** to return
to the gifts. The heading shows which menu is open.

The panel is never taller than the space below the buttons (at most 470 pixels), and its whole
contents scroll together, so every part is reachable on a phone.

### The MAC (mini admin console)

Every player sees a **🖥 MAC** button under **👑 GOD MODE** (non-admins see it in the same spot,
with the space above it empty). It opens a small panel:

```
┌──────────────────────────────────┐
│ 🖥 MINI ADMIN CONSOLE             │
│ 🎯 Give me the Sniper Rifle       │
│ ☢ NUKE SERVER                     │  tap twice within 3 seconds
└──────────────────────────────────┘
```

**☢ NUKE SERVER** drops a giant bomb on the lobby. It falls for 6 seconds, whistling louder as it
drops, with a 3, 2, 1 countdown at the end. On impact a blast wave rings out across the board and a
mushroom cloud rises over the lobby. The wave kills every player it reaches, in the lobby too,
except the one who pressed it; then every monster dies. Shields do not help. Only one MAYHEM or
NUKE countdown runs at a time. Timing lives in `Config.NUKE_*`; the client draws the strike
(`src/client/NukeStrike.luau`).

- Admins always have the MAC.
- Players without the MAC see **🔒 MAC**, and the panel opens with a lock over it.
- An admin gives the MAC with `/give <who> mac` (until the player leaves the server) or
  `/give <who> mac permanent` (saved, loaded every time they join).
- Permanent grants live in the `MapAccess` DataStore (the MAC's old name, kept so saved grants still load). In Studio this needs **Enable Studio Access
  to API Services**; without it a permanent grant unlocks the MAC for the session only, and the
  banner says **MAC NOT SAVED**.
- Opening the MAC closes the GOD MODE panel, and the other way round.

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
| `mac` | The 🖥 MAC panel | Until the player leaves the server |
| `mac permanent` | The 🖥 MAC panel | Saved for good |
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

Every vehicle parks once per server at a random clear spot with a random heading, in the motor
pools on both sides of the five spoke roads outside the lobby (75–235 studs out along a spoke, up
to 70 studs to either side; scenery stays out). Each spot is the vehicle's home: wrecked or
abandoned vehicles return to it. From any side of a vehicle, press **E** (or tap **Drive**) to take
the driver's seat, or **F** (**Ride**) for the free passenger seat nearest you. A passenger can
press **E** to move to the empty driver's seat. The ids in `src/shared/VehicleCatalog.luau` work
with `/give`, e.g. `/give me abrams`.

Vehicles climb ledges up to 1.6 studs (roads, landmark plazas and courtyards, Sakura Hall's
steps). Walls, the lobby gates, and taller ledges stop them.

### OG

OG (`mech`, 🤖) is the original two-legged walker, 46 studs tall. It parks with the other vehicles
and works with `/give <who> mech`.

- **Get in**: from any side, press **E** (or tap **Drive**), the same as every other vehicle.
- **Drive**: the same controls as every car (WASD/arrows, thumbstick, gamepad). It walks at 18
  studs/s, turns in place, and backs up slowly. It speeds up, stops, and turns slowly.
- **View**: you start in the cockpit, looking out the chest window. **V**, gamepad **Y**, or the
  **VIEW** button (touch, left of the jump button) switches to an outside view and back.
- **Stand up**: tap **STAND** (above **VIEW**, every platform) or jump. You get out of the seat
  and stand in the cab, still in first person, and can walk around inside it. The mech stays where
  it is, and it does not return to its parking spot while you are inside.
- **In the cab**: press **E** (or tap **Drive**) to sit back down, or **Q** (**Climb out**) to
  climb out onto the ground behind the mech.
- With nobody in it, the mech's brake holds it in place when bumped.

The legs and arms are decoration and do not collide; the cab walls, floor and roof, the hips and
the back pods do. The cab's furniture does not. Gates, walls and building doors stop it.

Preview a vehicle model without Studio (needs `lune` from `rokit install` and Python with Pillow):

```sh
python3 tools/preview/render.py src/server/vehicleModels/abrams.luau abrams.png
```

## Sniper Rifle

The Sniper Rifle (`sniper`) is admin-only.

- Only admins see it in the lobby armory. The server refuses it in a non-admin's loadout.
- `/give <who> sniper`, `/give <who> arsenal`, and the 🎯 Sniper Rifle button near the top of
  the 🎁 panel give it to anyone.
- One hit kills any player or monster. Shields and Studio immunity still block it.
- Fires every 0.1 seconds.

Scope (sniper in hand):

| Input | Scope |
| --- | --- |
| Mouse | Hold right button |
| Touch | Tap **SCOPE** (above the jump button) to toggle |
| Gamepad | Hold left trigger |

Scoped, the view zooms to a 12° field of view and shots go where the reticle is. Turning is slow
on every input: 0.02° per pixel of mouse movement, 0.03° per pixel of touch drag, 18° per second at
full right-stick deflection. The view eases toward where the input points (0.15 s time
constant). Tuning lives at the top of `src/client/SniperScope.luau`. Unequipping, dying, or
losing the tool ends the scope.

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
