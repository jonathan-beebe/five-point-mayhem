--!strict
-- Every drivable vehicle (data only). The server builds each one from its model file in
-- `src/server/vehicleModels/<id>.luau`; the admin panel lists them as gifts.

export type Vehicle = {
	id: string,
	name: string,
	icon: string,
	mech: boolean?, -- a walker (its model has a gait); the admin panel lists these under MECHS
	bulk: number?, -- crash toughness (VehicleDamage); default from the model's size
}

local VEHICLES: { Vehicle } = {
	-- Off-road and utility
	{ id = "jeep", name = "Jeep Wrangler", icon = "🚙" },
	{ id = "raptor", name = "Ford F-150 Raptor", icon = "🛻" },
	{ id = "gwagon", name = "Mercedes-AMG G 63", icon = "🚙" },
	{ id = "cybertruck", name = "Tesla Cybertruck", icon = "🛻" },
	{ id = "monster", name = "Monster Truck", icon = "🛻" },
	{ id = "buggy", name = "Dune Buggy", icon = "🏜" },
	{ id = "snowcat", name = "Snowcat", icon = "❄" },
	{ id = "lunar_rover", name = "Lunar Rover", icon = "🌙" },
	-- Speed
	{ id = "f1", name = "Formula 1 Car", icon = "🏎" },
	{ id = "nascar", name = "NASCAR Stock Car", icon = "🏁" },
	{ id = "rally", name = "Rally Car", icon = "🏁" },
	{ id = "lamborghini", name = "Lamborghini Aventador SVJ", icon = "🏎" },
	{ id = "bugatti", name = "Bugatti Chiron", icon = "🏎" },
	{ id = "kart", name = "Go-Kart", icon = "🏎" },
	{ id = "motorcycle", name = "Ducati Panigale V4", icon = "🏍" },
	-- Classics and luxury
	{ id = "phantom", name = "Rolls-Royce Phantom", icon = "👑" },
	{ id = "muscle", name = "1969 Dodge Charger", icon = "🚗" },
	{ id = "delorean", name = "DeLorean DMC-12", icon = "⚡" },
	{ id = "vwbus", name = "VW Microbus", icon = "🚐" },
	-- City and service
	{ id = "taxi", name = "NYC Taxi", icon = "🚕" },
	{ id = "police", name = "Police Interceptor", icon = "🚓" },
	{ id = "ambulance", name = "Ambulance", icon = "🚑" },
	{ id = "fire_truck", name = "Fire Engine", icon = "🚒" },
	{ id = "school_bus", name = "School Bus", icon = "🚌" },
	{ id = "ice_cream", name = "Ice Cream Truck", icon = "🍦" },
	{ id = "semi", name = "Peterbilt 389 Semi", icon = "🚛" },
	{ id = "tractor", name = "Farm Tractor", icon = "🚜" },
	{ id = "bulldozer", name = "Bulldozer", icon = "🚧" },
	-- Military
	{ id = "humvee", name = "Humvee", icon = "🪖" },
	{ id = "stryker", name = "Stryker APC", icon = "🛡" },
	{ id = "abrams", name = "M1 Abrams Tank", icon = "💥" },
	{ id = "tiger", name = "Tiger I Tank", icon = "💥" },
	-- Walkers (they stand guard around the lobby)
	{ id = "mech", name = "OG", icon = "🤖", mech = true },
	{ id = "cherry_bomb", name = "Cherry Bomb", icon = "🍒", mech = true },
	{ id = "heron", name = "Heron", icon = "🦩", mech = true },
	{ id = "rustbucket", name = "Rustbucket", icon = "⚙", mech = true },
	{ id = "aurora", name = "Aurora", icon = "✨", mech = true },
}

local byId: { [string]: Vehicle } = {}
for _, vehicle in VEHICLES do
	assert(byId[vehicle.id] == nil, "Duplicate vehicle id " .. vehicle.id)
	byId[vehicle.id] = vehicle
end

local VehicleCatalog = {
	ALL = VEHICLES,
}

function VehicleCatalog.get(id: string): Vehicle?
	return byId[id]
end

return VehicleCatalog
