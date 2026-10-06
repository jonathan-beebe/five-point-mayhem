-- Runs every check the project has, in order, and prints PASS or FAIL per step. Exits 1 if any
-- step fails.
-- Usage: lune run tools/check [--fast]   (--fast skips the type check)
--
-- Steps: stylua --check src tools; selene src tools; rojo sourcemap + luau-lsp analyze over src;
-- lune run tools/test. TEMPORARY markers in src and tools print as warnings and do not fail the run.
-- luau-lsp checks src only: the Lune scripts under tools are not type-analyzed. Its Roblox type
-- definitions download once into .cache/ (gitignored), for the luau-lsp version in rokit.toml.
-- Without luau-lsp (rokit install) the type check is skipped with a warning.

local fs = require("@lune/fs")
local net = require("@lune/net")
local process = require("@lune/process")

local Sandbox = require("./lib/Sandbox")

local USAGE = "usage: lune run tools/check [--fast]"

local fast = false
for _, arg in process.args do
	if arg == "--fast" then
		fast = true
	else
		print(string.format('unknown argument "%s"\n%s', arg, USAGE))
		process.exit(1)
	end
end

local results: { { name: string, status: string } } = {}
local failed = false

local function record(name: string, status: string)
	table.insert(results, { name = name, status = status })
	if status == "FAIL" then
		failed = true
	end
end

-- An error message without the stack traceback Lune appends.
local function message(err: unknown): string
	return string.match(tostring(err), "^[^\n]*") or ""
end

-- Runs a command with its output on this terminal. True when it exits 0.
local function run(program: string, args: { string }): boolean
	local ok, result = pcall(process.exec, program, args, { cwd = Sandbox.ROOT, stdio = "inherit" })
	if not ok then
		print(string.format("%s: %s", program, message(result)))
		return false
	end
	return result.ok
end

local function step(name: string, program: string, args: { string })
	print(string.format("\n== %s", name))
	record(name, if run(program, args) then "PASS" else "FAIL")
end

local function hasLuauLsp(): boolean
	local ok, result = pcall(process.exec, "luau-lsp", { "--version" }, { cwd = Sandbox.ROOT })
	return ok and result.ok
end

-- The luau-lsp version pinned in rokit.toml, or nil.
local function luauLspVersion(): string?
	local manifest = fs.readFile(Sandbox.ROOT .. "/rokit.toml")
	return string.match(manifest, 'luau%-lsp%s*=%s*"[%w_%-]+/luau%-lsp@([%w%.%-]+)"')
end

-- Downloads the Roblox type definitions for `version` when missing. Returns the path relative to
-- the root, or nil and an error message.
local function ensureDefinitions(version: string): (string?, string?)
	local relative = ".cache/globalTypes-" .. version .. ".d.luau"
	local path = Sandbox.ROOT .. "/" .. relative
	if fs.isFile(path) then
		return relative, nil
	end
	local url = "https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/"
		.. version
		.. "/scripts/globalTypes.d.luau"
	print("downloading " .. url)
	local ok, response = pcall(net.request, url)
	if not ok then
		return nil, tostring(response)
	end
	if not response.ok then
		return nil, string.format("HTTP %d", response.statusCode)
	end
	if #response.body == 0 then
		return nil, "empty response"
	end
	if not fs.isDir(Sandbox.ROOT .. "/.cache") then
		fs.writeDir(Sandbox.ROOT .. "/.cache")
	end
	fs.writeFile(path, response.body)
	return relative, nil
end

local function typeCheck()
	local name = "luau-lsp analyze"
	if fast then
		record(name, "SKIP")
		return
	end
	print(string.format("\n== %s", name))
	if not hasLuauLsp() then
		print("WARNING: luau-lsp not found (rokit install); type check skipped")
		record(name, "SKIP")
		return
	end
	local version = luauLspVersion()
	if not version then
		print('rokit.toml has no luau-lsp entry ("johnnymorganz/luau-lsp@<version>")')
		record(name, "FAIL")
		return
	end
	local definitions, problem = ensureDefinitions(version)
	if not definitions then
		print("could not download type definitions: " .. tostring(problem))
		record(name, "FAIL")
		return
	end
	if not run("rojo", { "sourcemap", "default.project.json", "--output", "sourcemap.json" }) then
		record(name, "FAIL")
		return
	end
	-- Output is captured so a broken definitions file can be recognised. luau-lsp reads .luaurc
	-- from the root itself.
	local args = {
		"analyze",
		"--platform=roblox",
		"--sourcemap=sourcemap.json",
		"--defs=" .. definitions,
		"src",
	}
	local ok, result = pcall(process.exec, "luau-lsp", args, { cwd = Sandbox.ROOT })
	if not ok then
		print(string.format("luau-lsp: %s", message(result)))
		record(name, "FAIL")
		return
	end
	for _, output in { result.stdout, result.stderr } do
		for line in string.gmatch(output, "[^\n]+") do
			if not string.match(line, "^%[INFO%]") and not string.match(line, "^%[WARN%]") then
				print(line)
			end
		end
	end
	if not result.ok then
		local output = result.stdout .. result.stderr
		if
			string.find(output, "parse_error", 1, true)
			or string.find(output, "Unknown type 'Vector3'", 1, true)
		then
			print(string.format("%s looks broken: delete .cache/ and run again", definitions))
		end
	end
	record(name, if result.ok then "PASS" else "FAIL")
end

-- Every line in src and tools marked TEMPORARY, as "path:line: text". Skips this file.
local function temporaryMarkers(): { string }
	local found = {}
	local function walk(dir: string)
		local entries = fs.readDir(Sandbox.ROOT .. "/" .. dir)
		table.sort(entries)
		for _, entry in entries do
			local path = dir .. "/" .. entry
			if fs.isDir(Sandbox.ROOT .. "/" .. path) then
				walk(path)
			elseif string.match(entry, "%.luau$") and path ~= "tools/check.luau" then
				local number = 0
				for line in
					string.gmatch(fs.readFile(Sandbox.ROOT .. "/" .. path) .. "\n", "([^\n]*)\n")
				do
					number += 1
					if string.find(line, "TEMPORARY", 1, true) then
						table.insert(
							found,
							string.format(
								"%s:%d: %s",
								path,
								number,
								(string.gsub(line, "^%s+", ""))
							)
						)
					end
				end
			end
		end
	end
	walk("src")
	walk("tools")
	return found
end

step("stylua", "stylua", { "--check", "src", "tools" })
step("selene", "selene", { "src", "tools" })
typeCheck()
step("tests", "lune", { "run", "tools/test" })

local markers = temporaryMarkers()
if #markers > 0 then
	print(string.format("\nWARNING: %d TEMPORARY markers", #markers))
	for _, marker in markers do
		print("  " .. marker)
	end
end

print("\n== summary")
for _, result in results do
	print(string.format("%-4s %s", result.status, result.name))
end
if failed then
	process.exit(1)
end
