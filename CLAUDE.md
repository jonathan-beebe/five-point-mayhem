# Mayhem: agent guide

Roblox arena game, built by Rojo from `src/`; the server builds the world from code at start.
Gameplay, controls and tuning numbers: [README.md](README.md).

## Verify

```sh
lune run tools/check         # before every commit: stylua, line length, selene, luau-lsp, tests
lune run tools/check --fast  # while iterating: skips the luau-lsp type check
lune run tools/test [filter] # tests only, e.g. `lune run tools/test mech_`
python3 tools/preview/render.py src/server/vehicleModels/<id>.luau out.png  # look at a model
```

No Studio in the agent loop: tests, the type checker, lint and `tools/preview` renders verify a
change. Name what still needs a human in Studio: physics feel (drive, rams, climbing, flight), UI
placement on phone/tablet/desktop, network ownership, sounds by ear (`tools/audition.luau`).

## Architecture

```
src/shared/   ReplicatedStorage.Shared. Every file --!strict. Loads under Lune.
  *Catalog    data only: WeaponCatalog, VehicleCatalog, CreatureCatalog, SoundCatalog
  pure logic  DayNight, MathUtil, MechGait, MechClimb, VehicleDefaults, RemoteGuard, and the
              modules in the Conventions table (applied by a server or client module); tested
              in tools/tests
  registry    AdminCommands: admin command ids, chat list, panel buttons, gifts, power tuning
  Config      world layout, REGIONS, teams, admin ids;  Remotes: every RemoteEvent, typed record
  contracts   Names (attributes, tags, collision groups, instance names), PodState, RemoteActions
src/server/   ServerScriptService.Server. init.server.luau boots in this order:
  1. CollisionGroups.register (every group and pair), barrel factory, lighting, DayNight.start,
     gravity
  2. buildWorld(): Lobby, Roads, one building per Config.REGIONS entry (in order), Landscape,
     Passes.raise (base ground, high range), one realm per region (in order), Passes.cut (the
     passes), Lamps (night lamps, fireflies; no draws from the seeded generators)
  3. NightLights, Session, Creatures, Vehicles (PodFlight.start, then layOut), Admin,
     MacAccess .start()
  (Requiring Systems.Vehicles, first from Admin, creates the workspace Vehicles folder and
  connects its Heartbeats, DriveInput, PlayerRemoving and the Tree tag listener; requiring
  Systems.Weapons, first from Session, creates the WeaponEffects folder and connects its
  Heartbeat, PlayerRemoving and FireWeapon: see Hazards.)
  4. CharacterAutoLoads back on: nobody spawns before the lobby exists
  world/      Build helpers, Lobby, Roads, Landscape, Lamps, Regions (per-landmark data),
              buildings/, Passes (high range and passes past the rim)
    realms/   one module per world past a pass (Regions.REALMS), `build(parent, origin)`, origin
              from WorldLayout.frame; Basin carves the land. A realm is self-contained (its own
              Random, materials, lighting and scenery; no requires between realms; shared code in
              src/shared) so it can move to a place of its own
  systems/    Combat, Weapons, WeaponSounds, Session, Creatures, Vehicles, PodFlight, Admin,
              MacAccess, DayNight, NightLights, CollisionGroups, and the model formats
              VehicleModel, WeaponModel, CreatureModel
    Vehicles/ init.luau is the facade (damage, spawnNear, start) and wires the system. Modules:
              Registry (folder, `cars`, Car/Crash), Specs (model files, placeholder), Placement
              (vehicle space, welds, onTerrain), Climb, Drive, Health (crashes, wrecks), Trees,
              Contact (rams, contact damage), Boarding (prompts, cab), Builder, Parking (spots,
              respawn loop). init.luau's header lists the require graph.
    Weapons/  init.luau is the facade (createTool, displayModel, give, holds) and wires it.
              Modules: FallbackModels (models by catalog shape, loads under Lune), Effects
              (WeaponEffects folder, the shared Random, beam/flash/lightning), Aim (Shot, spread,
              raycast), Pieces (piece parts, loads under Lune), Tools (model files, tools, display
              models), Projectiles (flight, IMPACTS), Firing (FireWeapon remote, cooldowns), kinds/
              (one module per kind; kinds/init.luau is the FIRE table). init.luau's header lists
              the require graph.
    util/     Instance helpers the systems share: Characters, Seats, Prompts, Parts, Ownership
              (tested in tools/tests/server_helpers.luau); Guard (tools/tests/guard.luau)
  vehicleModels/ weaponModels/ creatureModels/   one model file per catalog id
src/client/   StarterPlayerScripts.Client. Feature modules with start(), each task.spawned by
              init.client.luau so one failure cannot stop the rest. init.client requires every
              module first, outside that isolation: LobbyUI and Announcer build nothing at require
              time (tools/tests/client_lifecycle); a new screen builds in start().
  ui/         the UI kit (no start()): Create, Theme, TouchButton, Hud, RightColumn
tools/        lib/ (Sandbox, Check, ModelChecks), tests/, test.luau, check.luau, preview/
```

- World building is seeded (`Build` crates `Random.new(77)`, `Landscape` `Random.new(1337)`) and
  consumes randomness in `Config.REGIONS` order. Reordering world-building calls reshuffles the map.
  `Passes` (`Random.new(4242)`) and each realm (its `LAND.seed`) draw from their own generators.
- Vehicle and creature model files are require-free: a plain table using only Roblox datatypes
  and the Luau standard library, so Lune (tests, `tools/preview/export.luau`) loads them without
  the game. Format and units are documented in `systems/VehicleModel.luau` and
  `systems/CreatureModel.luau`. Weapon model files require `WeaponModel` and return
  `WeaponModel.define({...})`.
- A broken vehicle file becomes a grey placeholder (`pcall` in `Vehicles/Specs`). A broken creature
  file is warned and its kind never spawns (`Guard.run` per file in `Creatures`; roaming, themed,
  lair and horde spawns skip it). A vehicle whose build throws leaves its spot empty (warned);
  the respawn loop retries it.
- `workspace.Creatures` (`Names.Instances.Creatures`) is created by `Creatures` when first
  required; `Combat` and `Vehicles/Trees` find it by name at call time.

## Conventions

- Conventional Commits: `type(scope): imperative summary`. Scopes in use: `vehicles`, `weapons`,
  `creatures`, `admin`, `mac`, `map`, `ui`, `sounds`, `daynight`, `combat`, `debug`, `server`,
  `client`, `readme` (`docs(readme)`). Unscoped: `build:`, `test:`, `refactor:`, `docs:`.
  Branches: `feat/`, `fix/`, `refactor/<slug>`.
- stylua (tabs, 100 columns), selene (`std = "roblox"`), luau-lsp; versions pinned in `rokit.toml`.
  `tools/check` fails any line over 100 columns in src, tools, CLAUDE.md and AGENTS.md, comments
  included (a tab counts 4); model files in vehicleModels, weaponModels and creatureModels are
  exempt. Rewrap; do not delete content.
  `src/shared` is `--!strict`; the rest of `src` is nonstrict (`.luaurc`) for now.
- Tests load game files only through `tools/lib/Sandbox` (`Sandbox.load(path)`, or
  `Sandbox.require(Sandbox.game:GetService("ReplicatedStorage").Shared.X)`). It swaps in a correct
  `CFrame`: Lune 0.10.5's `CFrame.lookAt` faces +Z. It also stubs `Random` (deterministic, not
  Roblox's sequence) and resolves `script`/`require`. Server systems and world modules do not
  load under Lune: Sandbox maps only ReplicatedStorage and ServerScriptService, and Weapons
  (`Effects`), Vehicles (`Registry`) and Creatures create workspace folders at require time.
  `Sandbox.loadIsolated` runs a module with `require`, `game`, `workspace` and `Instance` stubbed;
  `data_integrity` reads kinds FIRE, Projectiles.IMPACTS and kinds/strike STYLES through it, and
  `admin_commands` reads `Admin.HANDLERS` and `Admin.POWER_UP`. Keep those tables free of
  top-level work on required values (arithmetic, comparisons, iteration). Combat's effects and
  Landscape's tree builders are read as text.
  `Sandbox.globals` adds globals to every later load, requires included (`ui_kit` sets
  `Instance` so the kit's modules can require each other).
- Cross-module names come from `src/shared/Names.luau` (attributes, tags, collision groups,
  instance names set in one module and read in another), `PodState.luau` (pod states) and
  `RemoteActions.luau` (remote action strings). Module-private names stay local literals. Add a
  new shared name to its module and to the golden list in `tools/tests/names.luau`.
- Collision groups and the pairs that pass through each other are all in
  `src/server/systems/CollisionGroups.luau`; a new group or pair also goes in the golden matrix in
  `tools/tests/collision_groups.luau`.
- Pure logic lives in `src/shared`; the server or client module applies it to Instances; a Lune
  test in `tools/tests/<name>.luau` (`tools/lib/Check`: `check`, `equal`, `isNear`, `section`,
  `finish`) checks it in one of two ways. A reference: the inline code it replaced, frozen in the
  test, run beside the module on the same inputs. A golden table: inputs and the outputs the code
  gave at a named commit, generated once by a script and pasted in; a reference that is a copy of
  the current code becomes a golden table. A deliberate tuning change updates the reference, or
  regenerates the golden table from the new code. A test runs src code by loading its module
  (`Sandbox.load`, `Sandbox.loadIsolated`), never by running lines cut out of a source file: code
  a test needs from a module that does not load moves to one that does. Raycasts, the clock,
  render steps, camera writes and every
  Instance write stay in the applying module (PodFlight also keeps the seat locks; PromptPanel the
  `MaxActivationDistance` save/restore). Lune cannot load `src/client`, so client rules and math
  go in `src/shared` too. Small math several modules share (`moveToward`, `wrapAngle`, `yawOf`,
  `insideBox`, `clampToRange`, `rateAlpha`/`timeAlpha` follow fractions) comes from `MathUtil`.

  ```
  src/shared                               applied by     tools/tests
  VehicleDrive VehicleSizing VehicleRam    Vehicles       vehicle_logic
    VehicleLayout VehicleDamage PodState
  WeaponMath (COOLDOWN_SLACK 0.85)         Weapons        weapon_math
  RemoteGuard                              Drive Firing   remote_guard, remote_handlers
                                             Admin
  PodPilot                                 PodFlight      pod_pilot
  LegsDrone                                Drive          legs_drone
  CreatureBrain                            Creatures      creature_brain (+ CreatureCatalog)
  AdminCommands                            Admin          admin_commands
  Loadout                                  LobbyUI        client_logic, session
                                             Session
  PodButtons                               PodControls    client_logic
  PromptRules                              PromptPanel    client_logic
  HealthBar                                VehicleHealth  client_logic
  DriveAxes                                CarInput       client_logic
  EngineEnvelope NearestSet                VehicleSounds  client_logic
  ScopeMath                                SniperScope    client_logic
  FootfallShake                            MechCamera     client_logic
  NukeMath (follows Config.NUKE_*)         NukeStrike     client_logic
  ConfirmTap                               MacPanel       client_logic
  HudLayout                                client HUD     hud_layout
  NightLights                              Lamps          night_lights
                                             NightLights
  WorldLayout                              Passes         world_layout
                                             realms/
  ```
- Remote handlers trust nothing a client sends: any value, NaN and ±inf included (`math.clamp`
  passes NaN through). Check each argument with `src/shared/RemoteGuard` before use: numbers with
  `isFinite`/`axis`, positions with `isFiniteVector`, strings with `optionalString`, and a
  per-player `newLimiter`/`allow` bucket (fed `os.clock()`, dropped on PlayerRemoving) for a
  remote sent every frame. A handler that keeps per-player state ignores a player who left
  (`not player.Parent`) so an event queued behind PlayerRemoving makes none. A remote that
  creates Instances (MAC SNIPER: `Weapons.holds`) is bounded by what the player already has.
  A wrong type drops the event. A non-finite drive axis becomes 0 (neutral), as a missing lift
  already did. A new handler is a named function on its module so
  `tools/tests/remote_handlers.luau` can call it with recording fakes; a limit is set from the
  client's real send rate with margin (RemoteGuard's header has DriveInput's numbers).
- Server systems use `systems/util/` instead of writing these inline:
  - `Characters`: `parts(player)` (character, Humanoid, root; no health check), `living(player)`
    (all three and `Health > 0`, else nils), `humanoidOf`, `rootOf`, `isInside(player, box)`,
    `moveRootTo(character, root, cframe)` (pivot keeping the root offset, then stop the root).
    Callers testing `Health <= 0` keep that test inline on `parts`: it differs from `> 0` for NaN.
  - `Seats.unseat(seat?, humanoid)`: destroy the SeatWeld, then `Sit = false`.
  - `Prompts.make(spec, parent)`: every server ProximityPrompt; Parent set last.
  - `Parts.fromPiece(piece, defaultName?, scale?)` sets what the three model formats share; the
    caller adds its own (Vehicles CastShadow/HideInCockpit, Creatures Massless/smooth surfaces,
    Weapons CanQuery false/Massless). `Parts.weldTo(base, part, offset, parent)` places, welds, and
    parents last.
  - `Ownership.set(part, player?)` (pcall'd SetNetworkOwner), `Ownership.isServerSimulated(part)`.
  - `Guard.run(tag, fn, ...)`, `Guard.loop(tag, interval, pass)`,
    `Guard.warn(tag, message, detail?)`: see Robustness.
  `tools/tests/server_helpers.luau` compares each helper with the inline code it replaced.
- Robustness: one failure in server work warns and the rest carries on. A background loop is
  `Guard.loop(tag, interval, pass)` (wait, then the pass in `xpcall`); no endless loop
  (`while true`, `while task.wait`, `until false`) in `src/server` outside Guard
  (`tools/tests/robustness.luau` fails on one). Per-item boot work (a
  model file, a parking spot, each system's `start()` in `init.server.luau`) runs each item through
  `Guard.run` and skips the item on failure; CharacterAutoLoads comes back on after a failed start.
  A system starts its loops before its per-item work (Guard.loop waits first, so timing holds).
  Guard warns `[Mayhem <tag>] <error's first line>` plus the traceback, at most once per
  `REPEAT_SECONDS` (30) per tag and first line; past `MAX_TRACKED` keys it drops stale ones. A
  catalog kind with no handler (`FIRE[kind]` nil) warns once and ignores the shot.
  Heartbeat and event handlers need no guard: Roblox keeps the connection after an error.
  `tools/tests/robustness.luau` runs Creatures, Parking, Firing and the boot with a failing piece.
- Every file opens with a header comment saying what it is; match the surrounding comment density.

## UI rules

- Never guess pixel offsets. Derive positions from measured on-screen elements
  (`AbsolutePosition`/`AbsoluteSize` of the MAC button, the touch jump button, the thumbstick) or
  from the engine's safe areas (a ScreenGui's `ScreenInsets`: `CoreUISafeInsets`, the default,
  starts below the top bar and inside the device's cutouts; `GuiService.TopbarInset` is the free
  strip inside the top bar), re-layout on resize, and fall back to fractions of the screen where
  nothing is measurable (`HudLayout.*Fallback`: no jump button on desktop). A gap from a measured
  edge (`HudLayout.MARGIN`, `GAP`) is a spacing value, not a guess; so are the size classes'
  element sizes (`HudLayout.sizes`). Fixed offsets the user accepted: LobbyUI's CHOOSE WEAPONS
  `-110`. Not precedent.
- HUD zones (the approved design; README's UI conventions draw them): top right the vehicle
  status and the system rail (GOD MODE, MAC) with its drawer to the left; top left the prompt
  stack; bottom right the action cluster round the jump button (camera slot left of jump, seat
  slot above it, ▲/▼ left, the pod button above); bottom left the thumbstick. Small screens
  (short side ≤ 500, `HudLayout.isSmall`) get square rail icons under the status; large ones
  full-width toggles in the corner with the status left of them. A new element goes in its zone.
- On desktop the system rail overlaps Roblox's PlayerList (CoreGui, not measurable). The user
  accepted the overlap; do not offset the rail or disable the PlayerList for it.
- Build client UI with `src/client/ui` (each header lists its functions):
  - `Create`: `create(className, properties, children?)`, `corner(radius)`,
    `stroke(color, thickness?, mode?)`, `padding(horizontal, vertical)`, `label(...)` (LobbyUI's)
  - `Theme`: `Fonts`, the colours more than one module uses (`Colors.hud`, `white`, `cyan`,
    `HUD_TRANSPARENCY`), `Radius.round`/`panel`, and `DisplayOrder`: every ScreenGui's layer.
    A new ScreenGui takes its DisplayOrder from there (`ui_kit` fails on a literal).
  - `TouchButton.new(options)`: the round touch button of the action cluster
  - `Hud`: `jumpButton`, `jumpWatcher`, `matchInset`
  - `RightColumn`: the system rail (`SCREEN_INSETS` for its ScreenGuis, PromptPanel's and
    VehicleHealth's), `makeToggle`, `setLabels`, `makePanel`, `layoutIn`, `watch`, `panels`,
    `opened`
  Layout arithmetic goes in `src/shared/HudLayout.luau` with a case in
  `tools/tests/hud_layout.luau`. `tools/tests/ui_kit.luau` compares each widget with the inline
  code it replaced.
- Persistent HUD never sits at the screen center. Exempt: UI the player opens and closes (MAC and
  GOD MODE panels, the lobby armory), transient prompt cards, the sniper scope's lens and
  reticle, full-screen flashes (MAYHEM, alarms).
- Every ProximityPrompt renders as a card in the top-left prompt stack
  (`src/client/PromptPanel.luau`); new prompts need no UI code.

## Recipes

`tools/tests/data_integrity.luau` enforces the cross-file rules (`lune run tools/test data`).

**Vehicle.** 1) Entry in `src/shared/VehicleCatalog.luau` (`id`, `name`, `icon`, optional `bulk`,
optional `armor`: divides crash and ram damage, pinned per vehicle in `tools/tests/vehicle_damage`).
2) `src/server/vehicleModels/<id>.luau`, require-free, per `VehicleModel.Model`; `speed`,
`acceleration`, `braking`, `coasting` from the real vehicle by the mapping in
`src/shared/VehicleDefaults.luau`, with a `-- Real:` comment. 3) Engine profile
in `SoundCatalog.VEHICLES[id]`. 4) Render it with `tools/preview/render.py`. Parking, `/give <id>`
and the GOD MODE VEHICLES menu pick it up from the catalog.
*Walker:* catalog `mech = true`; model `gait = "mech"` with `bones` (plus `seatBone`, `cab`, `exit`,
`cockpitCamera` as OG in `vehicleModels/mech.luau` uses them); sounds in `SoundCatalog.MECHS[id]`
(`mechVariant`) instead of `VEHICLES`. It parks in the guard ring round the lobby, appears in the
MECHS menu and climbs unless `climbs = false`. Render mid-stride with `--phase 0..1`.
Enforced: id pattern, unique id, name, icon, `bulk` > 0, `armor` >= 1; id ↔ model file;
`define()`/`ModelChecks`; `mech` ↔ `gait`; sound entry in the right table; positive
`acceleration`, `braking`, `coasting`.

*Vehicle behaviour:* change the module that owns it in `systems/Vehicles/`
(each header says what it owns); math goes in the `src/shared/Vehicle*` modules with a test. State
every module reads goes in `Registry`. A new public function goes through `init.luau`
(`Vehicles.x = Module.x`); callers keep `require(Systems.Vehicles)`.

**Weapon.** 1) Entry in `src/shared/WeaponCatalog.luau`: `category` from `CATEGORIES`, `kind` a key
of `FIRE` in `systems/Weapons/kinds/init.luau`, `shape` a key of `FallbackModels.SHAPES`, optional
`effect` (handled in `Combat.applyEffect`); kind-specific fields only on their kind (header
comment lists them). 2) `src/server/weaponModels/<id>.luau` per `WeaponModel.Model`.
3) `SoundCatalog.WEAPONS[id]` (`pool` only for `auto` weapons). 4) Add the id to README's weapon
ids table.
*New kind:* one file `systems/Weapons/kinds/<kind>.luau` returning `{ fire = function(shot) }`
(the `Aim.Shot` record), its line in `kinds/init.luau`'s `FIRE`, and a line in WeaponCatalog's
header (plus its fields in `KIND_ONLY` in `data_integrity` if only it reads them). Math goes in
`WeaponMath` with a test. *New impact / style:* a function and its entry in `Projectiles.IMPACTS`
/ `kinds/strike.luau` `STYLES`, and the header line. A new `effect` is a branch in
`Combat.applyEffect` and the header line.
Enforced: field types, known enums, kind-only fields, every `kinds/` module in `FIRE`, model
file ↔ id, `define()`/`ModelChecks`, sound entry, header ↔ server value sets.

**Creature.** 1) Kind in `CreatureCatalog.KINDS`. 2) `src/server/creatureModels/<id>.luau`,
require-free, per `CreatureModel.Model` (one piece named `Head`). 3) Make it spawn: a roaming
count in `CreatureCatalog.ROAMING`, an entry in `CreatureCatalog.HORDE_KINDS` (the admin horde),
or a landmark's `REGION_KIND`. Spawn, wander and lair rules change in `CreatureBrain` with its test;
counts and timings in `CreatureCatalog` (update `tools/tests/creature_brain.luau`'s pinned values:
a gameplay change). Enforced: kind ↔ model file both ways, `ModelChecks` pass, no aliased kind
tables, every kind `ROAMING`, `HORDE_KINDS` and the lair names exists.

**Admin power.** Registry: `src/shared/AdminCommands.luau` (`COMMANDS`; derived `CHAT`, chat
order, and `POWERS`, panel order; `POWER_UPS`; `GIFTS`; `TUNING`; the rules `resolveTargets`,
`giftLabel`, `chatArguments`, `meteorSeconds`). `Admin.run` dispatches through `Admin.HANDLERS`.
1) One `COMMANDS` entry: `id` (lower case; its place in the list is its chat order), `chat`, and a
`panel` button (`slot`, `label`, `color`, `hint`, `targeted`) if it has one. Tuning numbers go in
`TUNING`. 2) One handler in `Admin.HANDLERS` under the same id, and a line in Admin's header
comment. The chat command and the panel button follow. A power-up gift is a `POWER_UPS` id plus
its function in `Admin.POWER_UP` (every power-up but `arsenal` and `car`); an `AdminCommands.GIFTS`
entry puts it in the panel's gift menu. `gift` checks `POWER_UP` after the living-character check
and before the vehicle and weapon matches: `WeaponCatalog.find` matches by prefix (`giant`,
`heal`). 3) Client effects: a new field in `src/shared/Remotes.luau` and a client module with
`start()` listed in `init.client.luau`. 4) README God mode: panel, chat table, power.
5) `tools/tests/admin_commands.luau`: add the new id, button, gift or tuning value to its pinned
lists. `HANDLERS`, `POWER_UP` and `gift` are exposed on `Admin` for that test only. The
`AdminCommand` remote (`Admin.onCommand`) forwards up to three string arguments, as chat does.
Enforced: every id has a handler and every handler an id, unique lower-case ids, panel slots
1..n, `POWER_UP` (plus `arsenal`, `car`) equals `POWER_UPS`, every panel gift is a power-up or a
weapon id, `gift`'s branches and effects match the code before the admin registry refactor (run
with recording fakes).

**HUD element.** 1) A client module with `start()` listed in `init.client.luau`; its ScreenGui's
`DisplayOrder` from a `Theme.DisplayOrder` layer (a new layer goes in Theme's header table and in
`ORDERS` in `tools/tests/ui_kit.luau`). 2) Build with `ui/Create` and `ui/Theme`; an action
cluster button is `TouchButton.new`. 3) Put it in its zone (UI rules) against measured elements:
`Hud.jumpButton()` plus `Hud.jumpWatcher(layout)` and `Hud.matchInset` for the action cluster, the
gui's `AbsoluteSize` with `CoreUISafeInsets` for the corners; re-layout on resize. The arithmetic
goes in `HudLayout` with a golden case in `tools/tests/hud_layout.luau`. 4) Name what needs a
human in Studio: placement on phone, tablet and desktop.

**Landmark / region.** 1) Append to `Config.REGIONS` (`id`, `name`, `country`).
`Config.regionAngle` spaces regions 360° / #REGIONS apart; `Config.betweenRegions` is half a step
on (cross roads, lobby showcase, admin hordes).
2) `src/server/world/Regions.luau`: `BUILDINGS` (module name), `GROUND` (`Enum.Material`),
`TREES` (styles from Landscape's `TREE_BUILDERS`), `REALMS` (module in `world/realms/`).
3) `world/buildings/<Name>.luau` exporting
`build(parent: Instance, base: CFrame): Model`; local -Z of `base` faces the lobby.
4) `CreatureCatalog.REGION_KIND` and `LAIRS` (landmark's local frame). It reshuffles seeded
scenery. 5) `world/realms/<Name>.luau` exporting `build(parent: Instance, origin: CFrame): Model`.
Enforced: all six tables match REGIONS both ways; building and realm files, materials, tree styles
and `REGION_KIND` kinds exist.

## Debugging: TEMPORARY probes

After one failed guess at a bug only Studio shows, ship a probe and ask the user for its output.

- One module, header line 1: `-- TEMPORARY diagnostic: <the question>.`, then what it logs, then
  `Delete this file and its line in init.<server|client>.luau once the cause is known.`
- Every wiring line ends in `-- TEMPORARY`; output lines start with a tag (`[WalkerProbe] ...`).
  `tools/check` lists every `TEMPORARY` line as a warning. Remove a probe once the user confirms
  the cause is known.
- No probes are live.

## Hazards

Move these word for word; do not "simplify" them.

- `systems/Vehicles/`
  - `Registry.setLimits` compares with slack (`> 1`): the properties store single precision.
  - `Health.wreck`: a stunned vehicle brakes after its stun (`task.delay(stun, brake)`) so a
    wrecking ram's throw flies first; cab ejection (`climbOut`) is deferred until the weld removal
    lands.
  - `Contact.shove`: `stunnedUntil` is set before `rammed`; under `VehicleRam.MIN_SHOVE` there is
    no stun.
  - `Builder.build`'s `watchDriver`: the server takes the skid's network ownership when a driver
    sits and hands the leaving driver's character back in a `task.defer`.
  - `init.luau` wires everything at require time, in this order: Heartbeat `Drive.heartbeat`,
    DriveInput `Drive.onInput`, PlayerRemoving `Drive.forget`, the Tree tag listener
    (`Contact.addGrove`), Heartbeat `Contact.heartbeat` (crash, then contact). Registry creates
    the Vehicles folder when first required, before any of them. Keep new require-time work in
    init.luau, in that order.
  - `Parking.start` (`Vehicles.start`) calls `PodFlight.start()` before `layOut()`.
  - Requires inside the folder stay acyclic: a module requires only modules above it in the
    table in init.luau's header. Two modules that need each other share a lower module or an
    injected callback.
- `systems/Weapons/init.luau` wires the system at require time, in this order: the WeaponEffects
  folder, Heartbeat `Projectiles.heartbeat`, PlayerRemoving `Firing.forget`, FireWeapon
  `Firing.onFire`. The folder is the one piece of require-time work outside init.luau: `Effects`
  creates it when first required, which init.luau's requires do before any connect. Put any other
  require-time work in init.luau, in that order. Requires inside the folder stay acyclic, as for
  `Vehicles/` (table in init.luau's header). Every weapon module draws from the one
  `Effects.random`.
- `systems/PodFlight.luau`: a pilot who leaves the seat in flight is re-seated in a `task.defer`,
  with `task.wait(0.5)` before the pod gives up and flies home.
- Render steps, offset from `RenderPriority.Camera`: MechCamera undo shake + turn −1, shake +1;
  NukeStrike undo −2, shake +2; SniperScope view +1. Shake goes on after the camera, off before.
- `src/client/PromptPanel.luau`: suppression sets `MaxActivationDistance` to 0 and restores the
  server's value (the server never changes it after creation).
- `src/client/MechMotion.luau` `resolve`, and `src/client/CarInput.luau`'s lazy
  `PlayerModule:GetControls()` (retried on a slow load).
- Instance, attribute, tag, collision group and prompt names, pod states and remote action strings
  (`src/shared/Names.luau`, `PodState.luau`, `RemoteActions.luau`) are a contract between server
  and client: never change a value. `tools/tests/names.luau` pins each one.
- Numbers in the shared modules of the Conventions table, `MechClimb`, `MechGait`, `DayNight`, and
  the creature numbers in `CreatureCatalog`, are tuning pinned by tests; changing one is a
  gameplay change. Functions given a `Random` draw a fixed count in a fixed order:
  `VehicleLayout.randomSpot` four per call; `WeaponMath.spreadDirection` two, pitch first (none at
  no spread); `CreatureBrain.groundPoint` two per attempt, one more for the fallback;
  `CreatureBrain.wander` one (next wander time), plus two for the goal unless heading home.
- Admin command ids (`AdminCommands`) are a contract between AdminPanel, chat and the server:
  never change one.
