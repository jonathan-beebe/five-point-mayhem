-- Runs every test in tools/tests, each in its own Lune process, and prints PASS or FAIL, the check
-- count and the time per file. A failing file's output follows its line. Exits 1 if any file fails.
-- Usage: lune run tools/test [filter]   (filter: run only the files whose name contains it)

local DateTime = require("@lune/datetime")
local fs = require("@lune/fs")
local process = require("@lune/process")

local Sandbox = require("./lib/Sandbox")

local filter = process.args[1]

local files = {}
for _, file in fs.readDir(Sandbox.ROOT .. "/tools/tests") do
	if string.match(file, "%.luau$") then
		table.insert(files, "tools/tests/" .. file)
	end
end
table.sort(files)

local function now(): number
	return DateTime.now().unixTimestampMillis / 1000
end

local passed, failed = 0, 0
for _, file in files do
	local name = string.match(file, "([^/]+)%.luau$") :: string
	if filter and not string.find(name, filter, 1, true) then
		continue
	end
	local start = now()
	local result = process.exec("lune", { "run", file }, { cwd = Sandbox.ROOT })
	local seconds = now() - start
	local checks = string.match(result.stdout, "(%d+) checks, %d+ failures%s*$")
	print(
		string.format(
			"%s %-16s %14s %6.2f s",
			if result.ok then "PASS" else "FAIL",
			name,
			if checks then checks .. " checks" else "",
			seconds
		)
	)
	if result.ok then
		passed += 1
	else
		failed += 1
		for _, output in { result.stdout, result.stderr } do
			for line in string.gmatch(output, "[^\n]+") do
				print("    " .. line)
			end
		end
	end
end

if passed + failed == 0 then
	print(string.format('no test file matches "%s"', filter or ""))
end
print(string.format("%d passed, %d failed", passed, failed))
if failed > 0 or passed == 0 then
	process.exit(1)
end
