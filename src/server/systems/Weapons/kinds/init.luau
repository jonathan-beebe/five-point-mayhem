-- FIRE: how each WeaponCatalog `kind` fires, one module per kind in this folder (each returns
-- `{ fire = function(shot) }`). A new kind is a new module here and its line below;
-- tools/tests/data_integrity checks the catalog's kinds against this table and every module in
-- the folder against it, through Sandbox.loadIsolated (requires stubbed): keep the table free of
-- top-level work on required values beyond `require(...).fire`.

local Aim = require(script.Parent.Aim)

type Shot = Aim.Shot

local FIRE: { [string]: (Shot) -> () } = {
	melee = require(script.melee).fire,
	hitscan = require(script.hitscan).fire,
	projectile = require(script.projectile).fire,
	strike = require(script.strike).fire,
	heal = require(script.heal).fire,
	blink = require(script.blink).fire,
	push = require(script.push).fire,
}

return FIRE
