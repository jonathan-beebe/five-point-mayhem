-- Checks the region ring angles in src/shared/Config.luau outside Roblox.
-- Usage: lune run tools/tests/regions.luau
--
--   - Config.regionAngle and Config.betweenRegions return the same bits for every region index as
--     the expressions they replaced (`math.rad(-90 + (index - 1) * 72)`, and that `+ math.rad(36)`
--     in Admin's horde, Lobby's showcase and Roads' cross roads), copied below as the reference
--   - the spacing follows #Config.REGIONS: with a sixth region the step is 60 degrees and the
--     between angle sits half a step on

local luau = require("@lune/luau")

local Check = require("../lib/Check")
local Sandbox = require("../lib/Sandbox")

local check, equal = Check.check, Check.equal

-- Same bits: signed zeros and NaNs included.
local function sameBits(a: number, b: number): boolean
	if a ~= a and b ~= b then
		return true
	end
	return a == b and (a ~= 0 or 1 / a == 1 / b)
end

-- The expressions at main (f35d32f), word for word. Compiled with luau.load, as Sandbox.load
-- compiles Config (Lune's main chunk can compute different low bits).
local Reference = luau.load(
	[[
local Reference = {}
function Reference.regionAngle(index: number): number
	return math.rad(-90 + (index - 1) * 72)
end
function Reference.between(index: number): number
	return Reference.regionAngle(index) + math.rad(36)
end
return Reference
]],
	{ debugName = "regions reference" }
)()

local Config = Sandbox.load("src/shared/Config.luau")

Check.section("five regions: same bits as the literals")
equal(#Config.REGIONS, 5, "five regions")
for index = 1, #Config.REGIONS do
	local got = Config.regionAngle(index)
	check(sameBits(got, Reference.regionAngle(index)), "regionAngle " .. index)
	local between = Config.betweenRegions
	check(type(between) == "function", "Config.betweenRegions exists")
	if type(between) == "function" then
		check(sameBits(between(index), Reference.between(index)), "betweenRegions " .. index)
	end
end

Check.section("six regions: the step follows #REGIONS")
local Six = Sandbox.load("src/shared/Config.luau")
table.insert(Six.REGIONS, { id = "sixth", name = "Sixth", country = "Nowhere" })
for index = 1, 6 do
	local want = math.rad(-90 + (index - 1) * 60)
	check(
		Check.isNear(Six.regionAngle(index), want, 1e-12),
		("regionAngle %d: got %.6f, want %.6f"):format(index, Six.regionAngle(index), want)
	)
	if type(Six.betweenRegions) == "function" then
		check(
			Check.isNear(Six.betweenRegions(index), want + math.rad(30), 1e-12),
			"betweenRegions " .. index
		)
	end
end

Check.finish()
