-- Arcade vehicles scattered around the motor pools beside each spoke road. A vehicle is a
-- frictionless skid carrying welded body parts, built from its model file in
-- `src/server/vehicleModels`. The driver's client sends its stick/keys over the DriveInput
-- remote; the server turns that into targets for velocity constraints on the skid. Constraints
-- are simulated by whichever machine owns the vehicle's physics, so this works under any
-- ownership. Wrecked or abandoned vehicles return to their parking spot. A driven vehicle hurts
-- whoever it touches (cars ram, walkers stomp), shoves the vehicles it hits, and fells trees. A
-- walker with a pod (spec.pod) can send its cab flying (PodFlight); while the pod is away its legs
-- park. A hard crash damages a vehicle by its size (VehicleDamage); at no health it is wrecked: it
-- explodes, throws out whoever is aboard, and burns out. A driven walker climbs walls up to
-- MechClimb.MAX_RISE: it senses them with rays, MechClimb decides, and a vertical velocity
-- constraint (the "Climber") lifts it; the model's "Climbing" attribute says when.
--
-- This module is the facade; each module in the folder says in its header what it owns. Requires
-- inside the folder (each row requires only rows above it, so there are no cycles):
--   Registry, Specs, Placement   none
--   Climb, Trees                 Registry
--   Drive, Health                Climb, Registry
--   Contact                      Health, Placement, Registry, Trees
--   Boarding                     Placement
--   Builder                      Boarding, Climb, Health, Placement, Registry, Specs
--   Parking                      Builder, Specs
--   init                         Contact, Drive, Health, Parking
-- Requiring this module wires the system, in this order (CLAUDE.md, Hazards): the Vehicles folder
-- in workspace (Registry), the Heartbeat that drives, DriveInput, PlayerRemoving (forget the
-- DriveInput limit), the tree tag listener, then the Heartbeat that samples crashes and contact.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Names = require(ReplicatedStorage.Shared.Names)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Contact = require(script.Contact)
local Drive = require(script.Drive)
local Health = require(script.Health)
local Parking = require(script.Parking)

local Vehicles = {}

RunService.Heartbeat:Connect(Drive.heartbeat)
Remotes.DriveInput.OnServerEvent:Connect(Drive.onInput)
Players.PlayerRemoving:Connect(Drive.forget)
CollectionService:GetInstanceAddedSignal(Names.Tags.Tree):Connect(Contact.addGrove)
for _, tree in CollectionService:GetTagged(Names.Tags.Tree) do
	Contact.addGrove(tree)
end
RunService.Heartbeat:Connect(Contact.heartbeat)

-- The public API; each function's comment is at its definition.
Vehicles.damage = Health.damage
Vehicles.spawnNear = Parking.spawnNear
Vehicles.start = Parking.start

return Vehicles
