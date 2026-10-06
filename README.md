# Mayhem

Roblox arena game. The entire world is built from code at server start (`src/server/world`).

## Develop

```sh
rokit install
rojo serve      # then connect from the Rojo plugin in Studio and press Play
lune run tools/check  # format, lint, types, tests; exits 1 on any failure
```

`lune run tools/check` runs stylua, a 100-column line limit (model files exempt), selene, the
luau-lsp type check over `src` and every test, and lists `TEMPORARY` markers as warnings. `--fast`
skips the type check. The first full run downloads the Roblox type definitions to `.cache/` (needs
network); without luau-lsp the type check is skipped with a warning. `lune run tools/test [filter]`
runs only the tests. Files in `src/shared` are `--!strict`; the rest of `src` is nonstrict
(`.luaurc`).

## Layout

| Path | What |
| --- | --- |
| `src/shared/Config.luau` | World layout, teams, admin user ids |
| `src/shared/WeaponCatalog.luau` | All 52 weapons (data only) |
| `src/shared/VehicleCatalog.luau` | All vehicles (data only) |
| `src/shared/CreatureCatalog.luau` | Monster kinds, each landmark's themed monster and zombie lair, roaming counts, horde list, lair and brain timings (data only) |
| `src/shared/CreatureBrain.luau` | Monster rules the server applies (spawn spots, wandering, when a lair opens, horde size, brutes) |
| `src/shared/AdminCommands.luau` | Every admin command (chat command, GOD MODE button), the gifts, power tuning, and the target, gift label, chat and meteor rules |
| `src/shared/Names.luau` | Attribute, tag, collision group and instance names shared between modules and with the client |
| `src/shared/PodState.luau` | A flying pod's states and the rules read from them (server and client) |
| `src/shared/RemoteActions.luau` | The action strings remotes carry: pod and MAC commands, announcement styles |
| `src/shared/MathUtil.luau` | Small math helpers shared by server and client (move toward, angle wrap, yaw, inside a box, clamp to range, follow rates) |
| `src/shared/WeaponMath.luau` | Weapon math the server applies (spread, cooldown, melee reach, push cone, projectile step and size, display centering) |
| `src/shared/HudLayout.luau` | Layout math for the measured HUD: the touch button columns beside the jump button, the prompt card stack |
| `src/shared` client logic | The pure rules and math the client modules apply: `Loadout` (armory), `PodButtons` (pod controls), `PromptRules` (prompt cards), `HealthBar` (vehicle health bar), `DriveAxes` (car input), `EngineEnvelope` and `NearestSet` (vehicle sounds), `ScopeMath` (sniper scope), `FootfallShake` (walker camera shake), `NukeMath` (NUKE), `ConfirmTap` (the MAC's two-tap NUKE) |
| `src/server/vehicleModels` | One part-built model per vehicle (format: `src/server/systems/VehicleModel.luau`) |
| `src/server/weaponModels` | One part-built model per weapon (format: `src/server/systems/WeaponModel.luau`) |
| `src/server/creatureModels` | One part-built model per monster (format: `src/server/systems/CreatureModel.luau`) |
| `tools/check.luau` | Runs every check: format, line length, lint, types, tests (`lune run tools/check [--fast]`) |
| `tools/test.luau` | Runs every test (`lune run tools/test [filter]`) |
| `tools/tests` | Tests for shared game logic, models and data (`data_integrity`: catalogs, model files, sounds, regions; `names`: the shared names' values; `math_util`; `weapon_math`; `creature_brain`; `admin_commands`: every command has a handler; `collision_groups`: the collision matrix; `hud_layout`; `ui_kit`: the client UI kit's widgets against the code they replaced; `client_logic`: the client logic modules against the code they replaced), run under Lune |
| `tools/lib` | Lune harness: `Sandbox` loads game files outside Roblox, `Check` tallies assertions, `ModelChecks` validates model files |
| `tools/preview` | Renders a vehicle, weapon or creature model file to a PNG of orthographic views |
| `tools/audition.luau` | Plays every weapon and vehicle sound; paste into the Studio Command Bar during Play |
| `src/server/world` | Lobby, roads, terrain/scenery, the five landmarks (`Regions.luau`: each landmark's building module, ground and tree styles) |
| `src/server/systems` | Combat, weapons, players/teams, creatures, vehicles, admin powers, collision groups (`CollisionGroups.luau`: every group and pair) |
| `src/server/systems/Vehicles` | Vehicles, one module per job behind `init.luau`: `Registry` (live cars), `Specs` (model files), `Placement`, `Climb`, `Drive`, `Health` (crashes, wrecks), `Trees`, `Contact` (rams), `Boarding` (prompts, cab), `Builder`, `Parking` (spots, respawn) |
| `src/server/systems/Weapons` | Weapons, one module per job behind `init.luau`: `Tools` (tools, display stands), `FallbackModels` (models by catalog shape), `Effects` (beams, flashes, lightning), `Aim` (the shot record, spread, raycast), `Projectiles`, `Firing` (the FireWeapon remote, cooldowns), `kinds/` (one module per weapon kind) |
| `src/client` | Armory UI, weapon input, car input, vehicle health bar, mech animation and camera, admin panel, announcer |
| `src/client/ui` | Client UI kit: `Create` (instance builders), `Theme` (fonts, shared colours, every ScreenGui's DisplayOrder), `TouchButton`, `Hud` (jump button lookup, inset matching, bottom-right controls list), `RightColumn` (GOD MODE and MAC toggles and panels) |

## UI conventions

- Nothing in the persistent HUD goes in the center of the screen. Overlays and buttons sit at the
  edges. UI the player opens and closes (the MAC and GOD MODE panels, the lobby armory) and prompt
  cards that come and go are exempt, as are the sniper scope's lens and reticle (they are the aim
  point) and full-screen flashes (MAYHEM, alarms).
- Positions are measured from on-screen elements (the MAC button, the touch jump button), never
  guessed pixel offsets. Client UI is built with the kit in `src/client/ui`; layout math is in
  `src/shared/HudLayout.luau`.
- Every ProximityPrompt is drawn as a card at the right edge, under the MAC button (left of an
  open MAC or GOD MODE panel), above the bottom-right touch buttons: key (TAP on touch), object,
  action. Tap or click a card to use it. `src/client/PromptPanel.luau`.
- Seated in a vehicle, only prompts that work from that seat show: **Drive** from a passenger seat,
  and the pod console for Aurora's pilot. Other vehicles' prompts are hidden until you get out.

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
│   ☀ DAY        │   🌑 NIGHT      │
├────────────────┴─────────────────┤
│            👹 HORDE              │
├──────────────────────────────────┤
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
| `/day` | ☀ DAY | Jump to morning |
| `/night` | 🌑 NIGHT | Jump to nightfall |

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
| `car` | A random vehicle appears in front of the player | Until it is wrecked |
| any vehicle id | That vehicle appears in front of the player | Until it is wrecked |
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

**☀ DAY / 🌑 NIGHT** — `/day`, `/night`

- Day and night cycle on their own: a full day plus night lasts 5 minutes, 2½ minutes each. A
  server starts mid-afternoon.
- DAY fades to just after sunrise over 3 seconds; NIGHT fades to just after dusk. The cycle
  carries on from there.
- Pressing the phase it already is (DAY by day, NIGHT by night) restarts that phase. DAY pressed
  in the afternoon runs the clock back to morning.
- Tunables are `Config.DAY_NIGHT_*`.

## Vehicles

Every vehicle parks once per server at a random clear spot with a random heading, in the motor
pools on both sides of the five spoke roads outside the lobby (75–235 studs out along a spoke, up
to 70 studs to either side; scenery stays out). Each spot is the vehicle's home: wrecked or
abandoned vehicles return to it. From any side of a vehicle, press **E** (or tap **Drive**) to take
the driver's seat, or **F** (**Ride**) for the free passenger seat nearest you. A passenger can
press **E** to move to the empty driver's seat. The ids in `src/shared/VehicleCatalog.luau` work
with `/give`, e.g. `/give me abrams`.

Vehicles climb ledges up to 1.6 studs (roads, landmark plazas and courtyards, Sakura Hall's
steps). Walls, the lobby gates, and taller ledges stop them. Walkers also climb walls up to 14
studs (see OG).

### Crashes

A vehicle that stops hard takes damage: driving into a wall, landing a jump, being rammed. Its
size sets how much. Size is bulk: footprint × the height of its solid parts, over 560 cubic studs
(the Jeep is 1; `bulk` in `src/shared/VehicleCatalog.luau` overrides it).

- **Health**: 100 × bulk^0.25. Go-Kart 68, Jeep 100, School Bus 174, OG 225, Rustbucket 263.
- **Free bumps**: a crash costs nothing until the speed lost passes 40 × bulk^-0.3 studs/s (Jeep
  40, School Bus 21, OG 15). A landing is free up to 1.25 times that, at least 30 studs/s, so
  every vehicle drops 2 studs unhurt.
- **Walkers land on their legs**: a walker's landing is free up to 80 studs/s. A one-tier drop
  (12 studs, ~69 studs/s, or the deepest ledge a climbing walker steps off, 14.4 studs, ~75
  studs/s) costs nothing; a 24-stud drop (~97 studs/s) hurts.
- **Damage**: 0.3 × bulk^0.5 × (speed lost past the free amount)^1.3. A Jeep into a wall at 90
  takes 49 of 100; a Bugatti head-on at 145 is wrecked; a School Bus at 70 takes 145 of 174; an
  OG walking into a wall at 18 takes 6. Aurora's flying pod counts as bulk 6.9 but shares
  Aurora's 215 health: into a tower at full speed (100) it takes 226 and wrecks her.
- **Rams**: a rammed vehicle takes damage as a crash at the rammer's closing speed (its speed
  toward the struck vehicle, less the struck one's) × 1.1 × their mass ratio (0.15 to 3) × the
  rammer's ram, up to 140. A Jeep into a parked Taxi at 30 does nothing, at 60 takes 14 of 122,
  at 90 takes 48; head-on, both speeds add. A walker's legs come down 1.5 times as hard: OG
  walking into a Jeep at 18 takes 47 of its 100, Aurora at full stride (30) wrecks it. A walker
  creeping under 2 studs/s or turning in place does no damage.
- A crash worth less than 1 health is nothing: no sound, no sparks.
- Each crash clangs and throws sparks. At half health the vehicle smokes; at a quarter it burns.
  Nothing repairs it.
- **Wrecked** at no health: it brakes to a stop (a climbing walker lets go of the wall),
  explodes where it crashed (the flying pod or the vehicle's body; 35 damage, wider for bigger
  vehicles), throws everyone aboard out (anyone standing in a walker's cab lands at its exit),
  chars black, and disappears 10 seconds later. A parked vehicle comes back at its spot with full
  health on the next 10-second respawn check; a `/give` vehicle is gone.
- **Health bar**: whoever sits in a vehicle (any seat, Aurora's legs saddle too) sees its name and
  health in a bar at the bottom of the screen. It flashes white on each hit.
- Crashes into walls and the ground count only for vehicles the server simulates: driven ones
  (the server keeps them after the driver gets out), shoved ones, and flying pods. One a
  player's client simulates (carrying only passengers, or never driven and near a player) takes
  no crash damage of its own, but rams damage every vehicle.
- Tuning lives at the top of `src/shared/VehicleDamage.luau` (formulas, crash detection) and at the
  top of `src/server/systems/Vehicles/Health.luau` (wreck, smoke and fire);
  `lune run tools/test vehicle_damage` checks it.

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
- **Climb**: drive into a wall up to 14 studs tall with room on top, such as a Jaguar Pyramid
  tier, and the mech lifts itself up at 8 studs/s with its legs stepping, then steps onto the top.
  It climbs the back face of the pyramid tier by tier to the summit; the east and west faces stop
  one tier short, where the temple leaves too little room. Of the walkers only Heron is narrow
  enough to walk up the front staircase between its serpent heads and balustrades. Let go of the
  throttle to hang on the wall; push forward to keep climbing; reverse to let go and drop. It does
  not turn while climbing. Taller walls, the lobby, other vehicles and players are not climbed. Every
  walker climbs.

The legs and arms are decoration and do not collide; the cab walls, floor and roof, the hips and
the back pods do. The cab's furniture does not. Gates, walls taller than 14 studs and building
doors stop it.

### Aurora's flying pod

Aurora's capsule detaches from her legs and flies. Her arms stay with the legs. The pod seats
three: the pilot up front and two passengers behind (**F**, **Ride**, while it is docked).
Passengers look out in first person like the pilot.

- **Launch**: in the pilot's seat, press **F** at the glowing button in the middle of the console,
  or tap **LAUNCH** (above **STAND**). The pod lifts off and the legs park where they stand.
- **Fly**: WASD/arrows, thumbstick or gamepad fly forward and turn. **E** climbs and **Q**
  descends (touch: **▲** and **▼** beside the buttons). With neither, the pod holds its height. It
  never goes lower than 4 studs over the ground.
- **Return home**: **F** at the console button again, or tap **RETURN HOME**. The autopilot
  climbs, flies back over the legs, turns to their heading and settles onto them.
- **Land**: within 15 studs of the ground a **LAND** button (or **L**) appears beside
  **RETURN HOME**. The pod settles to hover just over the ground and everyone aboard gets out
  behind it. Walk up and press **E** (**Board**) to get back in: the first to board takes the
  pilot's seat, the next two the passenger seats. The pod waits until the pilot presses
  **LAUNCH** (or **F**).
- While the pod flies the seats are locked: **STAND** is hidden and jumping does nothing. If the
  pilot dies or leaves the game, the pod flies home on its own, passengers and all.
- **Drive the legs**: while the pod is away, walk up to the legs and press **E** (**Drive**) to
  sit on the saddle on top of the hips and walk the legs like any walker. When the pod returns
  home, the rider is put on the ground behind the legs before it docks.
- Nobody else can get into the pod while it flies. Anyone standing in the cab at launch is put
  outside.

Check the walkers' walk cycle and climb assist without Studio (needs `lune`):

```sh
lune run tools/test mech_
```

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
- The source of truth is `src/shared/AdminCommands.luau` (command ids, chat commands, panel
  buttons, gifts, power tuning), `src/server/systems/Admin.luau` (each command's handler) and
  `src/client/AdminPanel.luau` (panel layout).
