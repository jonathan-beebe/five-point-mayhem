-- Fonts, colours and corner radii more than one client module uses, and the DisplayOrder of every
-- ScreenGui the client builds. Colours one module uses stay in that module.
--
-- DisplayOrder: a higher layer draws over a lower one. Guis sharing a layer do not overlap.
--   5   scope       SniperScope's overlay (lens, reticle, black bars)
--   5   vehicleBar  VehicleHealth's bar (the vehicle status, top right)
--   6   touch       the action cluster round the jump button: SniperScope's SCOPE, MechCamera's
--                   VIEW and STAND, PodControls' pod, LAND, ▲ and ▼
--   10  lobby       LobbyUI's CHOOSE WEAPONS button
--   14  prompts     PromptPanel's cards (top left), under the system rail's panels
--   15  panels      the system rail (top right): GOD MODE (AdminPanel) and MAC (MacPanel), and
--                   their drawer, over the action cluster while open
--   18  modal       LobbyUI's armory sheet, over the system rail and its drawer
--   20  announcer   Announcer's banner and full-screen flash, over everything

local rgb = Color3.fromRGB

local Theme = {}

Theme.DisplayOrder = table.freeze({
	scope = 5,
	vehicleBar = 5,
	touch = 6,
	lobby = 10,
	prompts = 14,
	panels = 15,
	modal = 18,
	announcer = 20,
})

Theme.Fonts = table.freeze({
	title = Enum.Font.LuckiestGuy, -- headings, the right column's toggles, the announcer
	bold = Enum.Font.GothamBold, -- buttons and labels
	regular = Enum.Font.Gotham, -- secondary text
})

Theme.Colors = table.freeze({
	hud = rgb(20, 20, 28), -- background of touch buttons, prompt cards and the vehicle bar
	white = rgb(255, 255, 255), -- text and outlines on the HUD
	cyan = rgb(120, 245, 255), -- pod button outlines, prompt hold progress
})

Theme.HUD_TRANSPARENCY = 0.25 -- background of touch buttons, prompt cards and the vehicle bar

Theme.Radius = table.freeze({
	round = UDim.new(0.5, 0), -- pill or circle: half the shorter side
	panel = UDim.new(0, 8), -- the right column's toggles, panels and their buttons; prompt cards
})

return Theme
