-- Checks the server helpers in src/server/systems/util outside Roblox.
-- Usage: lune run tools/tests/server_helpers.luau
--
--   - Parts: every piece of every vehicle, creature and weapon model file, built and welded the
--     way each caller did inline before Parts existed (copied below as the reference, frozen), and
--     by the code the callers run now (Vehicles/Placement.addPieces, CreatureModel.addPieces,
--     Weapons/Pieces), gives the same part and weld, property by property
--   - Prompts: Prompts.seat, pod and board (the prompts Vehicles/Boarding and PodFlight build)
--     match the inline code they replaced
--   - Characters: parts, living, humanoidOf, rootOf and isInside return what the inline lookups
--     returned, for each missing piece and for health 100, 0, -5 and NaN
--   - Seats.unseat destroys the SeatWeld and clears Sit, with or without a weld or a seat
--
-- Not covered (Lune has no GetPivot, PivotTo, Position or network ownership):
-- Characters.moveRootTo and Ownership. Both are the callers' lines moved unchanged.

local roblox = require("@lune/roblox")

local Check = require("../lib/Check")
local Sandbox = require("../lib/Sandbox")

local check, equal = Check.check, Check.equal
local Instance, Enum, Vector3, Color3 = roblox.Instance, roblox.Enum, roblox.Vector3, roblox.Color3
local CFrame = Sandbox.CFrame
local M = Enum.Material

Check.printLimit = 10

-- The modules these load (and the ones they require) build Instances.
Sandbox.globals.Instance = Instance
local Parts = Sandbox.load("src/server/systems/util/Parts.luau")
local Prompts = Sandbox.load("src/server/systems/util/Prompts.luau")
local Characters = Sandbox.load("src/server/systems/util/Characters.luau")
local Seats = Sandbox.load("src/server/systems/util/Seats.luau")
local MathUtil = Sandbox.load("src/shared/MathUtil.luau")
local VehicleModel = Sandbox.load("src/server/systems/VehicleModel.luau")
local CreatureModel = Sandbox.load("src/server/systems/CreatureModel.luau")

-- Every property any builder sets, read with pcall: a property the class lacks reads "<none>".
local PART_PROPERTIES = {
	"ClassName",
	"Name",
	"Shape",
	"Size",
	"Color",
	"Material",
	"Transparency",
	"Reflectance",
	"CanCollide",
	"CanTouch",
	"CanQuery",
	"Massless",
	"CastShadow",
	"Anchored",
	"TopSurface",
	"BottomSurface",
	"CFrame",
}
local WELD_PROPERTIES = { "ClassName", "Name", "C0", "C1" }
local PROMPT_PROPERTIES = {
	"ClassName",
	"Name",
	"ActionText",
	"ObjectText",
	"KeyboardKeyCode",
	"GamepadKeyCode",
	"MaxActivationDistance",
	"RequiresLineOfSight",
	"Enabled",
	"HoldDuration",
	"Style",
	"Exclusivity",
	"ClickablePrompt",
	"UIOffset",
}

local function read(instance: any, property: string): any
	local ok, value = pcall(function()
		return instance[property]
	end)
	return if ok then value else "<none>"
end

-- The FAIL message is built only on a mismatch: formatting every check's message took most of the
-- run.
local function sameProperties(got: any, want: any, properties: { string }, label: string)
	for _, property in properties do
		local gotValue, wantValue = read(got, property), read(want, property)
		if gotValue == wantValue then
			check(true, "")
		else
			equal(gotValue, wantValue, label .. " " .. property)
		end
	end
end

-- Compares two built parts: properties, attributes, parent, and the weld under each (its parts
-- resolved against `base`).
local function samePart(got: any, want: any, gotBase: any, wantBase: any, label: string)
	sameProperties(got, want, PART_PROPERTIES, label)
	for name, value in want:GetAttributes() do
		equal(got:GetAttribute(name), value, label .. " attribute " .. name)
	end
	for name in got:GetAttributes() do
		check(want:GetAttribute(name) ~= nil, label .. " extra attribute " .. name)
	end
	equal(got.Parent and got.Parent.Name, want.Parent and want.Parent.Name, label .. " parent")
	local gotChildren, wantChildren = got:GetChildren(), want:GetChildren()
	equal(#gotChildren, #wantChildren, label .. " children")
	local gotWeld, wantWeld = got:FindFirstChildOfClass("Weld"), want:FindFirstChildOfClass("Weld")
	check((gotWeld == nil) == (wantWeld == nil), label .. " weld present")
	if gotWeld and wantWeld then
		sameProperties(gotWeld, wantWeld, WELD_PROPERTIES, label .. " weld")
		check(gotWeld.Part0 == gotBase and wantWeld.Part0 == wantBase, label .. " weld Part0")
		check(gotWeld.Part1 == got and wantWeld.Part1 == want, label .. " weld Part1")
	end
end

local function newBase(cframe: CFrame): any
	local base = Instance.new("Part")
	base.Name = "Base"
	base.CFrame = cframe
	return base
end

local function newModel(): any
	local model = Instance.new("Model")
	model.Name = "Holder"
	return model
end

-- Before: the inline code, word for word (Names constants inlined) ---------------------------

local Before = {}

-- Vehicles/Placement.luau `attach`, `attachTo` and the piece loop in Vehicles/Builder.luau `build`.
local SKID_TO_GROUND = CFrame.new(0, -0.5, 0)
function Before.vehicleAttach(model: any, skid: any, part: any, offset: CFrame)
	local relative = SKID_TO_GROUND * offset
	part.Anchored = false
	part.Massless = true
	part.CFrame = skid.CFrame * relative
	local weld = Instance.new("Weld")
	weld.Part0 = skid
	weld.Part1 = part
	weld.C0 = relative
	weld.Parent = part
	part.Parent = model
end
function Before.vehicleAttachTo(model: any, skid: any, bone: any, part: any, offset: CFrame)
	if not bone then
		Before.vehicleAttach(model, skid, part, offset)
		return
	end
	local relative = CFrame.new(bone.pivot):Inverse() * offset
	part.Anchored = false
	part.Massless = true
	part.CFrame = bone.part.CFrame * relative
	local weld = Instance.new("Weld")
	weld.Part0 = bone.part
	weld.Part1 = part
	weld.C0 = relative
	weld.Parent = part
	part.Parent = model
end
function Before.vehiclePiece(model: any, skid: any, bone: any, piece: any)
	local part = Instance.new(piece.class or "Part") :: any
	if piece.shape and part:IsA("Part") then
		part.Shape = piece.shape
	end
	part.Name = piece.name or "Piece"
	part.Size = piece.size
	part.Color = piece.color
	part.Material = piece.material or M.SmoothPlastic
	part.Transparency = piece.transparency or 0
	part.Reflectance = piece.reflectance or 0
	part.CanCollide = false
	part.CanTouch = false
	part.CastShadow = part.Transparency < 0.5
	if piece.hideInCockpit then
		part:SetAttribute("HideInCockpit", true) -- MechCamera
	end
	Before.vehicleAttachTo(model, skid, bone, part, piece.offset)
	return part
end

-- Creatures.luau `build`'s piece loop.
function Before.creaturePiece(model: any, root: any, fromRoot: CFrame, piece: any)
	local part = Instance.new(piece.class or "Part") :: any
	if piece.shape then
		(part :: any).Shape = piece.shape
	end
	part.Name = piece.name or "Part"
	part.Size = piece.size
	part.Color = piece.color
	part.Material = piece.material or M.SmoothPlastic
	part.Transparency = piece.transparency or 0
	part.Reflectance = piece.reflectance or 0
	part.CanCollide = false
	part.CanTouch = false
	part.Massless = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	local offset = fromRoot * piece.offset
	part.CFrame = root.CFrame * offset
	local weld = Instance.new("Weld")
	weld.Part0 = root
	weld.Part1 = part
	weld.C0 = offset
	weld.Parent = part
	part.Parent = model
	return part
end

-- Weapons.luau `createPart` and `attach`.
function Before.weaponCreatePart(spec: any, scale: number): any
	local part = Instance.new(spec.class or "Part") :: any
	if spec.shape and part:IsA("Part") then
		part.Shape = spec.shape
	end
	if spec.name then
		part.Name = spec.name
	end
	part.Size = spec.size * scale
	part.Color = spec.color
	part.Material = spec.material or M.SmoothPlastic
	part.Transparency = spec.transparency or 0
	part.Reflectance = spec.reflectance or 0
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
	return part
end
function Before.weaponAttach(handle: any, spec: any, parent: any): any
	local part = Before.weaponCreatePart(spec, 1)
	part.CFrame = handle.CFrame * spec.offset
	local weld = Instance.new("Weld")
	weld.Part0 = handle
	weld.Part1 = part
	weld.C0 = spec.offset
	weld.Parent = part
	part.Parent = parent
	return part
end

-- Vehicles/Boarding.luau `addPrompts`/`addCab` `prompt` (identical copies).
function Before.vehiclePrompt(
	anchor: any,
	objectText: string,
	reach: number,
	action: string,
	key: any,
	name: string?
): any
	local each = Instance.new("ProximityPrompt")
	each.Name = name or action .. "Prompt"
	each.ActionText = action
	each.ObjectText = objectText
	each.KeyboardKeyCode = key
	each.MaxActivationDistance = reach
	each.RequiresLineOfSight = false
	each.Parent = anchor
	return each
end

-- PodFlight.luau `new`'s two prompts.
function Before.podPrompt(anchor: any, modelName: string): any
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PodPrompt"
	prompt.ObjectText = modelName .. " pod"
	prompt.KeyboardKeyCode = Enum.KeyCode.F
	prompt.MaxActivationDistance = 6
	prompt.RequiresLineOfSight = false
	prompt.Parent = anchor
	return prompt
end
function Before.boardPrompt(root: any, modelName: string, reach: number): any
	local board = Instance.new("ProximityPrompt")
	board.Name = "BoardPrompt"
	board.ActionText = "Board"
	board.ObjectText = modelName .. " pod"
	board.KeyboardKeyCode = Enum.KeyCode.E
	board.MaxActivationDistance = reach
	board.RequiresLineOfSight = false
	board.Enabled = false
	board.Parent = root
	return board
end

-- Now: the callers' code in src -------------------------------------------------------------------

-- Vehicles/Placement (addPieces), CreatureModel (addPieces), Weapons/Pieces and util/Prompts
-- (seat, pod, board) hold the code each caller runs, and load under Lune.
local Placement = Sandbox.load("src/server/systems/Vehicles/Placement.luau", {
	-- Its terrain raycast setup, run at require time.
	RaycastParams = {
		new = function()
			return {}
		end,
	},
	workspace = { Terrain = {} },
})
local Pieces = Sandbox.load("src/server/systems/Weapons/Pieces.luau")
check(Placement.SKID_TO_GROUND == SKID_TO_GROUND, "Placement.SKID_TO_GROUND")

-- Parts -------------------------------------------------------------------------------------------

local BASE_AT = CFrame.new(12, 3.5, -40) * CFrame.Angles(0.1, 2.3, -0.2)

Check.section("parts: vehicle pieces")
local vehiclePieces = 0
for _, loaded in Sandbox.loadVehicleModels() do
	local spec = VehicleModel.define(loaded.spec)
	-- One stand-in bone part per bone, pivoted where the model says, so pieces on bones weld to a
	-- bone part as in the game.
	local function bones(skid: any)
		local each = {}
		for _, bone in spec.bones or {} do
			each[bone.name] = {
				part = newBase(skid.CFrame * SKID_TO_GROUND * CFrame.new(bone.pivot)),
				pivot = bone.pivot,
			}
		end
		return each
	end
	local wantSkid, gotSkid = newBase(BASE_AT), newBase(BASE_AT)
	local wantBones, gotBones = bones(wantSkid), bones(gotSkid)
	local wantModel, gotModel = newModel(), newModel()
	for _, piece in spec.pieces do
		Before.vehiclePiece(wantModel, wantSkid, piece.bone and wantBones[piece.bone], piece)
	end
	Placement.addPieces(gotModel, gotSkid, gotBones, spec.pieces)
	local wants, gots = wantModel:GetChildren(), gotModel:GetChildren()
	equal(#gots, #wants, loaded.id .. " pieces")
	for index, piece in spec.pieces do
		local bone = piece.bone and gotBones[piece.bone]
		local wantBone = piece.bone and wantBones[piece.bone]
		samePart(
			gots[index],
			wants[index],
			if bone then bone.part else gotSkid,
			if wantBone then wantBone.part else wantSkid,
			loaded.id .. " piece " .. index
		)
		vehiclePieces += 1
	end
end
check(vehiclePieces > 1000, "vehicle pieces built: " .. vehiclePieces)

Check.section("parts: vehicle welds without a piece (hull, ladder, ramp, cab)")
for _, offset in { CFrame.identity, CFrame.new(1, 2, 3) * CFrame.Angles(0, 1, 0) } do
	local wantSkid, gotSkid = newBase(BASE_AT), newBase(BASE_AT)
	local want, got = Instance.new("Part"), Instance.new("Part")
	Before.vehicleAttach(newModel(), wantSkid, want, offset)
	Placement.attach(newModel(), gotSkid, got, offset)
	samePart(got, want, gotSkid, wantSkid, "attach " .. tostring(offset))
	-- The ramps: a WedgePart welded to the skid at `relative`, no Anchored/Massless change.
	local wantWedge, gotWedge = Instance.new("WedgePart"), Instance.new("WedgePart")
	wantWedge.CFrame = wantSkid.CFrame * offset
	local weld = Instance.new("Weld")
	weld.Part0 = wantSkid
	weld.Part1 = wantWedge
	weld.C0 = offset
	weld.Parent = wantWedge
	wantWedge.Parent = newModel()
	Parts.weldTo(gotSkid, gotWedge, offset, newModel())
	samePart(gotWedge, wantWedge, gotSkid, wantSkid, "ramp " .. tostring(offset))
end

Check.section("parts: creature pieces")
local creaturePieces = 0
for _, loaded in Sandbox.loadCreatureModels() do
	local spec = CreatureModel.define(loaded.spec)
	local fromRoot = CreatureModel.rootCenter(spec):Inverse()
	local wantRoot, gotRoot = newBase(BASE_AT), newBase(BASE_AT)
	local wantModel, gotModel = newModel(), newModel()
	for _, piece in spec.pieces do
		Before.creaturePiece(wantModel, wantRoot, fromRoot, piece)
	end
	CreatureModel.addPieces(gotModel, gotRoot, spec)
	local wants, gots = wantModel:GetChildren(), gotModel:GetChildren()
	equal(#gots, #wants, loaded.id .. " pieces")
	for index in spec.pieces do
		samePart(gots[index], wants[index], gotRoot, wantRoot, loaded.id .. " piece " .. index)
		creaturePieces += 1
	end
end
check(creaturePieces > 100, "creature pieces built: " .. creaturePieces)

Check.section("parts: weapon pieces, held and on display")
local weaponPieces = 0
for _, loaded in Sandbox.loadWeaponModels() do
	for index, piece in loaded.spec.pieces do
		local label = loaded.id .. " piece " .. index
		local wantHandle, gotHandle = newBase(BASE_AT), newBase(BASE_AT)
		local want = Before.weaponAttach(wantHandle, piece, newModel())
		local gotModel = newModel()
		Pieces.attach(gotHandle, piece, gotModel)
		local got = gotModel:GetChildren()[1]
		samePart(got, want, gotHandle, wantHandle, label)
		-- Weapons.displayModel: scaled 1.6, no weld.
		local wantShown = Before.weaponCreatePart(piece, 1.6)
		local gotShown = Pieces.createPart(piece, 1.6)
		samePart(gotShown, wantShown, nil, nil, label .. " on display")
		weaponPieces += 1
	end
end
check(weaponPieces > 200, "weapon pieces built: " .. weaponPieces)

Check.section("parts: classes and defaults the model files may not use")
for _, class in { "Part", "WedgePart", "CornerWedgePart" } do
	for _, piece in
		{
			{
				class = class,
				size = Vector3.new(1, 2, 3),
				color = Color3.new(1, 0, 0),
				offset = CFrame.identity,
			},
			{
				class = class,
				name = "Named",
				size = Vector3.new(-0, 0.5, 1e-3),
				color = Color3.new(0, 0, 1),
				material = M.Neon,
				transparency = 0.5,
				reflectance = 0.25,
				hideInCockpit = true,
				offset = CFrame.new(0, 1, 0),
			},
		}
	do
		local label = class .. " " .. (piece.name or "unnamed")
		samePart(
			Pieces.createPart(piece),
			Before.weaponCreatePart(piece, 1),
			nil,
			nil,
			label .. " (weapon)"
		)
		local wantSkid, gotSkid = newBase(BASE_AT), newBase(BASE_AT)
		local gotModel = newModel()
		Placement.addPieces(gotModel, gotSkid, {}, { piece })
		samePart(
			gotModel:GetChildren()[1],
			Before.vehiclePiece(newModel(), wantSkid, nil, piece),
			gotSkid,
			wantSkid,
			label .. " (vehicle)"
		)
	end
end
-- A shape on a Part, for every caller (Creatures cast to Part; the others check IsA).
for _, shape in { Enum.PartType.Ball, Enum.PartType.Cylinder, Enum.PartType.Block } do
	local piece = {
		shape = shape,
		size = Vector3.new(2, 2, 2),
		color = Color3.new(0, 1, 0),
		offset = CFrame.identity,
	}
	local wantRoot, gotRoot = newBase(BASE_AT), newBase(BASE_AT)
	local gotModel = newModel()
	-- hipHeight 0 and rootSize 0: the root's center is the creature-space origin.
	CreatureModel.addPieces(
		gotModel,
		gotRoot,
		{ pieces = { piece }, hipHeight = 0, rootSize = Vector3.zero } :: any
	)
	samePart(
		gotModel:GetChildren()[1],
		Before.creaturePiece(newModel(), wantRoot, CFrame.identity, piece),
		gotRoot,
		wantRoot,
		"creature " .. shape.Name
	)
end
-- ModelChecks rejects a WedgePart with a shape, so the one difference never reaches a builder:
-- before, Creatures raised on it; now every caller ignores the shape.
local wedge = Parts.fromPiece({
	class = "WedgePart",
	shape = Enum.PartType.Ball,
	size = Vector3.one,
	color = Color3.new(),
})
equal(wedge.ClassName, "WedgePart", "a WedgePart ignores a shape")

-- Prompts -----------------------------------------------------------------------------------------

Check.section("prompts")
local function promptPair(label: string, before: (any) -> any, after: (any) -> any)
	local wantAnchor, gotAnchor = Instance.new("Attachment"), Instance.new("Attachment")
	wantAnchor.Name, gotAnchor.Name = "Anchor", "Anchor"
	local want, got = before(wantAnchor), after(gotAnchor)
	sameProperties(got, want, PROMPT_PROPERTIES, label)
	check(got.Parent == gotAnchor and want.Parent == wantAnchor, label .. " parent")
end
for _, case in
	{
		{ "Drive", Enum.KeyCode.E, "DrivePrompt" },
		{ "Ride", Enum.KeyCode.F, nil },
		{ "Climb out", Enum.KeyCode.Q, nil },
	}
do
	for _, reach in { 0.5, 14.3, 40 } do
		local action, key, name = case[1], case[2], case[3]
		promptPair(action .. " " .. reach, function(anchor)
			return Before.vehiclePrompt(anchor, "Jeep", reach, action, key, name)
		end, function(anchor)
			return Prompts.seat(anchor, "Jeep", reach, action, key, name)
		end)
	end
end
promptPair("PodPrompt", function(anchor)
	return Before.podPrompt(anchor, "OG")
end, function(anchor)
	return Prompts.pod(anchor, "OG")
end)
promptPair("BoardPrompt", function(anchor)
	return Before.boardPrompt(anchor, "OG", 12)
end, function(anchor)
	return Prompts.board(anchor, "OG", 12)
end)

-- Characters --------------------------------------------------------------------------------------

-- Stand-ins with only what the lookups touch (Lune parts have no Position).
local function fakeCharacter(humanoid: any?, root: any?): any
	return {
		FindFirstChildOfClass = function(_, class)
			assert(class == "Humanoid", class)
			return humanoid
		end,
		FindFirstChild = function(_, name)
			assert(name == "HumanoidRootPart", name)
			return root
		end,
	}
end

local NAN = 0 / 0
local cases: { { label: string, player: any } } = { { label = "no character", player = {} } }
for _, health in { 100, 0, -5, NAN } do
	for _, hasHumanoid in { true, false } do
		for _, hasRoot in { true, false } do
			local humanoid = if hasHumanoid then { Health = health } else nil
			local root = if hasRoot then { Position = Vector3.new(1, 2, 3) } else nil
			table.insert(cases, {
				label = string.format(
					"health %s humanoid %s root %s",
					tostring(health),
					tostring(hasHumanoid),
					tostring(hasRoot)
				),
				player = { Character = fakeCharacter(humanoid, root) },
			})
		end
	end
end

-- The inline lookups, word for word.
local function beforeParts(player: any)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return character, humanoid, root
end
-- Admin.luau `characterParts`.
local function beforeLiving(player: any)
	local character, humanoid, root = beforeParts(player)
	if character and humanoid and root and humanoid.Health > 0 then
		return character, humanoid, root
	end
	return nil, nil, nil
end
-- Creatures `nearestPlayer`/`playersNear` and Weapons `fireHeal`: the test before their other
-- conditions.
local function beforeAliveTest(player: any): boolean
	local _, humanoid, root = beforeParts(player)
	return not not (root and humanoid and humanoid.Health > 0)
end

Check.section("characters")
for _, case in cases do
	local player, label = case.player, case.label
	local wc, wh, wr = beforeParts(player)
	local gc, gh, gr = Characters.parts(player)
	check(gc == wc and gh == wh and gr == wr, label .. ": parts")
	wc, wh, wr = beforeLiving(player)
	gc, gh, gr = Characters.living(player)
	check(gc == wc and gh == wh and gr == wr, label .. ": living")
	equal(gc ~= nil and gh ~= nil and gr ~= nil, beforeAliveTest(player), label .. ": alive test")
	local _, inlineHumanoid, inlineRoot = beforeParts(player)
	equal(Characters.humanoidOf(player), inlineHumanoid, label .. ": humanoidOf")
	equal(Characters.rootOf(player), inlineRoot, label .. ": rootOf")
end
equal(Characters.rootOf(nil), nil, "rootOf(nil)")

Check.section("characters: isInside")
local box = { CFrame = BASE_AT, Size = Vector3.new(6, 8, 10) }
for _, offset in
	{
		Vector3.zero,
		Vector3.new(2.9, 3.9, 4.9),
		Vector3.new(3, 4, 5),
		Vector3.new(3.1, 0, 0),
		Vector3.new(0, -4.1, 0),
		Vector3.new(0, 0, 50),
	}
do
	local position = BASE_AT * offset
	for _, hasRoot in { true, false } do
		local root = if hasRoot then { Position = position } else nil
		local player = { Character = fakeCharacter(nil, root) }
		-- Vehicles `wreck`/`isOccupied`, inline.
		local character = player.Character
		local inlineRoot = character and character:FindFirstChild("HumanoidRootPart")
		local want = not not (
			inlineRoot and MathUtil.insideBox(box.CFrame, box.Size, inlineRoot.Position)
		)
		equal(
			Characters.isInside(player, box),
			want,
			tostring(offset) .. " root " .. tostring(hasRoot)
		)
	end
end
equal(Characters.isInside({}, box), false, "isInside without a character")

-- Seats -------------------------------------------------------------------------------------------

Check.section("seats")
for _, hasWeld in { true, false } do
	local seat = Instance.new("Seat")
	local weld = Instance.new("Weld")
	weld.Name = "SeatWeld"
	if hasWeld then
		weld.Parent = seat
	end
	local other = Instance.new("Weld")
	other.Name = "Other"
	other.Parent = seat
	local humanoid = Instance.new("Humanoid")
	humanoid.Sit = true
	Seats.unseat(seat, humanoid)
	equal(seat:FindFirstChild("SeatWeld"), nil, "weld " .. tostring(hasWeld) .. ": SeatWeld gone")
	equal(other.Parent, seat, "weld " .. tostring(hasWeld) .. ": other children stay")
	equal(humanoid.Sit, false, "weld " .. tostring(hasWeld) .. ": Sit")
end
local humanoid = Instance.new("Humanoid")
humanoid.Sit = true
Seats.unseat(nil, humanoid) -- Vehicles' dismount: a walker without a legs seat
equal(humanoid.Sit, false, "no seat: Sit")

Check.finish()
