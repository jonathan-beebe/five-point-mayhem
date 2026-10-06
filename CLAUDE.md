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
  pure logic  DayNight, VehicleDamage, MechGait, MechClimb, VehicleDefaults, MathUtil, and the
              vehicle math Vehicles applies: VehicleDrive, VehicleSizing, VehicleRam,
              VehicleLayout; the pod flight math PodFlight applies: PodPilot (tested in tools/tests)
  Config      world layout, REGIONS, teams, admin ids;  Remotes: every RemoteEvent, typed record
  contracts   Names (attributes, tags, collision groups, instance names), PodState, RemoteActions
src/server/   ServerScriptService.Server. init.server.luau boots in this order:
  1. CollisionGroups.register (every group and pair), barrel factory, lighting, DayNight.start,
     gravity
  2. buildWorld(): Lobby, Roads, one building per Config.REGIONS entry (in order), Landscape
  3. Session, Creatures, Vehicles (PodFlight.start, then layOut), Admin, MacAccess .start()
  (Requiring Systems.Vehicles, first from Admin, creates the workspace Vehicles folder and
  connects its Heartbeats, DriveInput and the Tree tag listener: see Hazards.)
  4. CharacterAutoLoads back on: nobody spawns before the lobby exists
  world/      Build helpers, Lobby, Roads, Landscape, Regions (per-landmark data), buildings/
  systems/    Combat, Weapons, Session, Creatures, Vehicles, PodFlight, Admin, MacAccess, DayNight,
              CollisionGroups, and the model formats VehicleModel, WeaponModel, CreatureModel
    Vehicles/ init.luau is the facade (damage, spawnNear, start) and wires the system. Modules:
              Registry (folder, `cars`, Car/Crash), Specs (model files, placeholder), Placement
              (vehicle space, welds, onTerrain), Climb, Drive, Health (crashes, wrecks), Trees,
              Contact (rams, contact damage), Boarding (prompts, cab), Builder, Parking (spots,
              respawn loop). init.luau's header lists the require graph.
    util/     Instance helpers the systems share: Characters, Seats, Prompts, Parts, Ownership
              (tested in tools/tests/server_helpers.luau)
  vehicleModels/ weaponModels/ creatureModels/   one model file per catalog id
src/client/   StarterPlayerScripts.Client. Feature modules with start(), each task.spawned by
              init.client.luau so one failure cannot stop the rest.
tools/        lib/ (Sandbox, Check, ModelChecks), tests/, test.luau, check.luau, preview/
```

- World building is seeded (`Build` crates `Random.new(77)`, `Landscape` `Random.new(1337)`) and
  consumes randomness in `Config.REGIONS` order. Reordering world-building calls reshuffles the map.
- Vehicle and creature model files are require-free: a plain table using only Roblox datatypes
  and the Luau standard library, so Lune (tests, `tools/preview/export.luau`) loads them without
  the game. Format and units are documented in `systems/VehicleModel.luau` and
  `systems/CreatureModel.luau`. Weapon model files require `WeaponModel` and return
  `WeaponModel.define({...})`.
- A broken vehicle file becomes a grey placeholder (`pcall` in `Vehicles/Specs`). A broken creature
  file stops server boot (`Creatures` requires every one at load, no `pcall`).

## Conventions

- Conventional Commits: `type(scope): imperative summary`. Scopes in use: `vehicles`, `weapons`,
  `creatures`, `admin`, `mac`, `map`, `ui`, `sounds`, `daynight`, `combat`, `debug`, `readme`
  (`docs(readme)`); `build:` and `test:` unscoped. Branches: `feat/`, `fix/`, `refactor/<slug>`.
- stylua (tabs, 100 columns), selene (`std = "roblox"`), luau-lsp; versions pinned in `rokit.toml`.
  `tools/check` fails any line over 100 columns in src, tools, CLAUDE.md and AGENTS.md, comments
  included (a tab counts 4); model files in vehicleModels, weaponModels and creatureModels are
  exempt. Rewrap; do not delete content.
  `src/shared` is `--!strict`; the rest of `src` is nonstrict (`.luaurc`) for now.
- Pure logic goes in `src/shared` with a Lune test in `tools/tests/<name>.luau` (uses
  `tools/lib/Check`: `check`, `equal`, `isNear`, `section`, `finish`).
- Tests load game files only through `tools/lib/Sandbox` (`Sandbox.load(path)`, or
  `Sandbox.require(Sandbox.game:GetService("ReplicatedStorage").Shared.X)`). It swaps in a correct
  `CFrame`: Lune 0.10.5's `CFrame.lookAt` faces +Z. It also stubs `Random` (deterministic, not
  Roblox's sequence) and resolves `script`/`require`. Modules that build Instances at require
  time (Weapons, Combat, Landscape) do not load under Lune; `data_integrity` reads them as text.
- Cross-module names come from `src/shared/Names.luau` (attributes, tags, collision groups,
  instance names set in one module and read in another), `PodState.luau` (pod states) and
  `RemoteActions.luau` (remote action strings). Module-private names stay local literals. Add a
  new shared name to its module and to the golden list in `tools/tests/names.luau`.
- Collision groups and the pairs that pass through each other are all in
  `src/server/systems/CollisionGroups.luau`; a new group or pair also goes in the golden matrix in
  `tools/tests/collision_groups.luau`.
- Vehicle math is in `src/shared` and `Vehicles` applies it to instances: `VehicleDrive` (target
  speed, yaw, settling, constraint strengths), `VehicleSizing` (solid height, pod box, crash sizes,
  reach box, prompt reach, pod frames), `VehicleRam` (pace, sweep box, shoves, flings, tree
  breaks), `VehicleDamage` (crash health, crash point, smoke/fire shares), `VehicleLayout` (lobby
  clearance, parking spots from an injected `Random`, guard ring, respawn rule), `PodState`
  (`canSit`, `driveSeat`). `tools/tests/vehicle_logic.luau` compares each with the inline code it
  replaced; a deliberate tuning change updates that reference too.
- Pod flight math is in `src/shared/PodPilot.luau` and `PodFlight` applies it: `fly` (turn, speed,
  `rise` with ground clearance, launch rise and ceiling, bank and pitch), `home` (the autopilot's
  climb, cross, settle phases from the dock frame and root position; `onDock` ends a settle),
  `hover`, `canLand`, `prompt` (launch prompt text and enabled per state), `standFrame` and
  `sideways` (where a rider put outside stands). PodFlight keeps the raycasts, the clock, the seat
  locks and every Instance write. `tools/tests/pod_pilot.luau` compares each with the inline code
  it replaced.
- Small math shared across modules (`moveToward`, `wrapAngle`, `yawOf`, `insideBox`,
  `clampToRange`, `rateAlpha`/`timeAlpha` follow fractions) comes from `src/shared/MathUtil.luau`.
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
  A change to a builder's output must keep `tools/tests/server_helpers.luau` passing: it compares
  each helper with the inline code it replaced.
- Every file opens with a header comment saying what it is; match the surrounding comment density.

## UI rules

- Never guess pixel offsets. Derive positions from measured on-screen elements
  (`AbsolutePosition`/`AbsoluteSize` of the MAC button, the touch jump button, the thumbstick),
  re-layout on resize, and fall back to fractions of the screen. Existing fixed offsets
  (`MacPanel.TOGGLE_TOP`, `VehicleHealth` `BAR_BOTTOM`, LobbyUI's `-110`) are debts, not precedent.
- Persistent HUD never sits at the screen center. Exempt: UI the player opens and closes (MAC and
  GOD MODE panels, the lobby armory), transient prompt cards, the sniper scope's lens and
  reticle, full-screen flashes (MAYHEM, alarms).
- Every ProximityPrompt renders as a card at the right edge (`src/client/PromptPanel.luau`); new
  prompts need no UI code.

## Recipes

`tools/tests/data_integrity.luau` enforces the cross-file rules (`lune run tools/test data`).

**Vehicle.** 1) Entry in `src/shared/VehicleCatalog.luau` (`id`, `name`, `icon`, optional `bulk`).
2) `src/server/vehicleModels/<id>.luau`, require-free, per `VehicleModel.Model`. 3) Engine profile
in `SoundCatalog.VEHICLES[id]`. 4) Render it with `tools/preview/render.py`. Parking, `/give <id>`
and the GOD MODE VEHICLES menu pick it up from the catalog.
*Walker:* catalog `mech = true`; model `gait = "mech"` with `bones` (plus `seatBone`, `cab`, `exit`,
`cockpitCamera` as OG in `vehicleModels/mech.luau` uses them); sounds in `SoundCatalog.MECHS[id]`
(`mechVariant`) instead of `VEHICLES`. It parks in the guard ring round the lobby, appears in the
MECHS menu and climbs unless `climbs = false`. Render mid-stride with `--phase 0..1`.
Enforced: id pattern, unique id, name, icon; id ↔ model file; `define()`/`ModelChecks`;
`mech` ↔ `gait`; sound entry in the right table.

*Vehicle behaviour:* change the module that owns it in `systems/Vehicles/`
(each header says what it owns); math goes in the `src/shared/Vehicle*` modules with a test. State
every module reads goes in `Registry`. A new public function goes through `init.luau`
(`Vehicles.x = Module.x`); callers keep `require(Systems.Vehicles)`.

**Weapon.** 1) Entry in `src/shared/WeaponCatalog.luau`: `category` from `CATEGORIES`, `kind` a key
of `FIRE` in `systems/Weapons.luau`, `shape`, optional `effect` (handled in
`Combat.applyEffect`); kind-specific fields only on their kind (header comment lists them).
2) `src/server/weaponModels/<id>.luau` per `WeaponModel.Model`. 3) `SoundCatalog.WEAPONS[id]`
(`pool` only for `auto` weapons). 4) Add the id to README's weapon ids table. A new `kind`,
`effect`, `impact` or `style` needs its server branch and a line in WeaponCatalog's header.
Enforced: field types, known enums, kind-only fields, model file ↔ id, `define()`/`ModelChecks`,
sound entry, header ↔ server value sets.

**Creature.** 1) Kind in `CreatureCatalog.KINDS`. 2) `src/server/creatureModels/<id>.luau`,
require-free, per `CreatureModel.Model` (one piece named `Head`). 3) Make it spawn: roaming count in
`mix` in `Creatures.start`, the horde list in `Creatures.horde`, or a landmark's `REGION_KIND`.
Enforced: kind ↔ model file both ways, `ModelChecks` pass, no aliased kind tables.

**Admin power.** 1) `systems/Admin.luau`: the function, a branch in `Admin.run`, the name in the
chat-command list in `Admin.start`, the header comment. 2) `src/client/AdminPanel.luau`: a
`POWERS` entry (`command`, `label`, `color`, `hint`, `targeted`). A gift is a `GIFTS` entry plus
handling in `give`. 3) Client effects: a new field in `src/shared/Remotes.luau` and a client
module with `start()` listed in `init.client.luau`. 4) README God mode: panel, chat table, power.
The `AdminCommand` remote forwards two arguments (`first`, `second`). Nothing tests this yet.

**Landmark / region.** 1) Append to `Config.REGIONS` (`id`, `name`, `country`).
`Config.regionAngle` spaces regions 72° apart (five); a sixth needs that changed.
2) `src/server/world/Regions.luau`: `BUILDINGS` (module name), `GROUND` (`Enum.Material`),
`TREES` (styles from Landscape's `TREE_BUILDERS`). 3) `world/buildings/<Name>.luau` exporting
`build(parent: Instance, base: CFrame): Model`; local -Z of `base` faces the lobby.
4) `CreatureCatalog.REGION_KIND` and `LAIRS` (landmark's local frame). It reshuffles seeded
scenery. Enforced: all five tables match REGIONS both ways; building file, materials, tree styles
and `REGION_KIND` kinds exist.

## Debugging: TEMPORARY probes

After one failed guess at a bug only Studio shows, ship a probe and ask the user for its output.

- One module, header line 1: `-- TEMPORARY diagnostic: <the question>.`, then what it logs, then
  `Delete this file and its line in init.<server|client>.luau once the cause is known.`
- Every wiring line ends in `-- TEMPORARY`; output lines start with a tag (`[WalkerProbe] ...`).
  `tools/check` lists every `TEMPORARY` line as a warning. Remove the probe before merge.
- Live now, awaiting the user (do not remove): `src/server/systems/WalkerProbe.luau` (walker skids
  under the ground) and `src/client/SoundProbe.luau` (which sound plays at game start).

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
    DriveInput `Drive.onInput`, the Tree tag listener (`Contact.addGrove`), Heartbeat
    `Contact.heartbeat` (crash, then contact). Registry creates the Vehicles folder when first
    required, before any of them. Keep new require-time work in init.luau, in that order.
  - `Parking.start` (`Vehicles.start`) calls `PodFlight.start()` before `layOut()`.
  - Requires inside the folder stay acyclic: a module requires only modules above it in the
    table in init.luau's header. Two modules that need each other share a lower module or an
    injected callback.
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
- Numbers in `VehicleDamage`, `VehicleDrive`, `VehicleSizing`, `VehicleRam`, `VehicleLayout`,
  `PodPilot`, `MechClimb`, `MechGait` and `DayNight` are tuning pinned by tests; changing one is a
  gameplay change. `VehicleLayout.randomSpot` draws four numbers per call, in a fixed order, from
  the `Random` it is given.
