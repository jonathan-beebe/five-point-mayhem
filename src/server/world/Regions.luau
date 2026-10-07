-- Per-landmark world data, by Config.REGIONS id (data only, no requires): the building module in
-- `buildings`, the ground material around it, the tree styles near it and the realm module in
-- `realms` for the world past its pass. init.server builds the landmarks and realms, Landscape
-- lays the ground and trees; tools/tests/data_integrity checks every region has an entry in each
-- table.

local M = Enum.Material

return {
	-- Module in src/server/world/buildings that builds the landmark.
	BUILDINGS = {
		castle = "Castle",
		pagoda = "Pagoda",
		tower = "Skyscraper",
		pyramid = "Pyramid",
		palace = "Palace",
	},
	-- Ground material around each landmark.
	GROUND = {
		castle = M.Grass,
		pagoda = M.LeafyGrass,
		tower = M.Pavement,
		pyramid = M.Sand,
		palace = M.Snow,
	},
	-- Tree style near each landmark (Landscape's TREE_BUILDERS); repeats weight the pick.
	TREES = {
		castle = { "oak", "oak", "birch" },
		pagoda = { "cherry", "cherry", "maple" },
		tower = { "street", "oak" },
		pyramid = { "palm", "palm", "jungle" },
		palace = { "pine", "pine", "birch" },
	},
	-- Module in src/server/world/realms that builds the world past the landmark's pass.
	REALMS = {
		castle = "AshenMoor",
		pagoda = "Takamagahara",
		tower = "ManifestExcess",
		pyramid = "Tamoanchan",
		palace = "Tridevyatoe",
	},
}
