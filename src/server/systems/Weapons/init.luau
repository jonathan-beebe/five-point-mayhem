-- Builds weapon tools from the catalog and resolves every shot on the server.
-- Clients only report "I fired weapon X at point P"; range, cooldown, damage, and the safe
-- zone are all enforced here.
--
-- This module is the facade (createTool, displayModel, give, holds); each module in the folder
-- says in its header what it owns. Requires inside the folder (each row requires only rows above
-- it, so there are no cycles):
--   FallbackModels, Effects   none (FallbackModels: WeaponCatalog and WeaponModel only)
--   Pieces                    none (WeaponModel and util/Parts only)
--   Aim                       Effects
--   Tools                     FallbackModels, Pieces
--   Projectiles               Aim, Effects
--   kinds/<kind>              Aim, Effects; kinds/projectile Aim, Projectiles
--   kinds (init)              Aim, kinds/<kind>
--   Firing                    kinds, Tools
--   init                      Firing, Projectiles, Tools
-- Requiring this module wires the system, in this order (CLAUDE.md, Hazards): the WeaponEffects
-- folder in workspace (Effects), the Heartbeat that flies projectiles, PlayerRemoving (forget
-- cooldowns), then the FireWeapon remote.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Firing = require(script.Firing)
local Projectiles = require(script.Projectiles)
local Tools = require(script.Tools)

local Weapons = {}

RunService.Heartbeat:Connect(Projectiles.heartbeat)
Players.PlayerRemoving:Connect(Firing.forget)
Remotes.FireWeapon.OnServerEvent:Connect(Firing.onFire)

-- The public API; each function's comment is at its definition.
Weapons.createTool = Tools.createTool
Weapons.displayModel = Tools.displayModel
Weapons.give = Tools.give
Weapons.holds = Tools.holds

return Weapons
