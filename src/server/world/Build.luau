-- Part-placing helpers used by every world builder.
-- Conventions: a CFrame passed to a wall/building marks its ground-level center; local -Z is the
-- front. Everything is anchored unless stated otherwise.

local Build = {}

export type PartOptions = {
	shape: Enum.PartType?,
	transparency: number?,
	canCollide: boolean?,
	canQuery: boolean?,
	castShadow: boolean?,
	reflectance: number?,
	name: string?,
}

local Smooth = Enum.SurfaceType.Smooth

function Build.model(name: string, parent: Instance): Model
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = parent
	return model
end

function Build.part(
	parent: Instance,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material?,
	options: PartOptions?
): Part
	local part = Instance.new("Part")
	part.Anchored = true
	part.TopSurface = Smooth
	part.BottomSurface = Smooth
	if options and options.shape then
		part.Shape = options.shape
	end
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	if options then
		if options.transparency then
			part.Transparency = options.transparency
		end
		if options.canCollide == false then
			part.CanCollide = false
			if options.canQuery == false then
				part.CanQuery = false
			end
		end
		if options.castShadow == false then
			part.CastShadow = false
		end
		if options.reflectance then
			part.Reflectance = options.reflectance
		end
		if options.name then
			part.Name = options.name
		end
	end
	part.Parent = parent
	return part
end

function Build.wedge(
	parent: Instance,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material?
): WedgePart
	local wedge = Instance.new("WedgePart")
	wedge.Anchored = true
	wedge.Size = size
	wedge.CFrame = cframe
	wedge.Color = color
	wedge.Material = material or Enum.Material.SmoothPlastic
	wedge.Parent = parent
	return wedge
end

-- Upright cylinder centered on `center`.
function Build.column(
	parent: Instance,
	center: CFrame,
	height: number,
	diameter: number,
	color: Color3,
	material: Enum.Material?,
	options: PartOptions?
): Part
	local merged: PartOptions = table.clone(options or {})
	merged.shape = Enum.PartType.Cylinder
	return Build.part(
		parent,
		Vector3.new(height, diameter, diameter),
		center * CFrame.Angles(0, 0, math.rad(90)),
		color,
		material,
		merged
	)
end

function Build.ball(
	parent: Instance,
	position: Vector3,
	diameter: number,
	color: Color3,
	material: Enum.Material?,
	options: PartOptions?
): Part
	local merged: PartOptions = table.clone(options or {})
	merged.shape = Enum.PartType.Ball
	return Build.part(parent, Vector3.one * diameter, CFrame.new(position), color, material, merged)
end

-- Climbable lattice running straight up from `base`.
function Build.truss(parent: Instance, base: CFrame, height: number, color: Color3): TrussPart
	local truss = Instance.new("TrussPart")
	truss.Anchored = true
	truss.Size = Vector3.new(2, math.max(2, math.floor(height / 2) * 2), 2)
	truss.CFrame = base * CFrame.new(0, truss.Size.Y / 2, 0)
	truss.Color = color
	truss.Material = Enum.Material.Metal
	truss.Parent = parent
	return truss
end

export type Opening = { x: number, width: number, bottom: number, top: number }

-- A wall along local X from `base` (ground center), cut by rectangular openings.
-- Openings must not overlap along X; stack per-floor walls for windows above windows.
function Build.wall(
	parent: Instance,
	base: CFrame,
	length: number,
	height: number,
	thickness: number,
	color: Color3,
	material: Enum.Material?,
	openings: { Opening }?
)
	local cuts = { -length / 2, length / 2 }
	for _, opening in (openings or {}) :: { Opening } do
		table.insert(cuts, math.clamp(opening.x - opening.width / 2, -length / 2, length / 2))
		table.insert(cuts, math.clamp(opening.x + opening.width / 2, -length / 2, length / 2))
	end
	table.sort(cuts)

	for index = 1, #cuts - 1 do
		local a, b = cuts[index], cuts[index + 1]
		local width = b - a
		if width > 0.05 then
			local mid = (a + b) / 2
			local covering: Opening? = nil
			for _, opening in (openings or {}) :: { Opening } do
				if math.abs(mid - opening.x) < opening.width / 2 then
					covering = opening
					break
				end
			end
			local spans = if covering
				then { { 0, covering.bottom }, { covering.top, height } }
				else { { 0, height } }
			for _, span in spans do
				local low, high = span[1], math.min(span[2], height)
				if high - low > 0.05 then
					Build.part(
						parent,
						Vector3.new(width, high - low, thickness),
						base * CFrame.new(mid, (low + high) / 2, 0),
						color,
						material
					)
				end
			end
		end
	end
end

export type Hole = { x0: number, x1: number, z0: number, z1: number }

-- Horizontal slab whose top sits at `top` above `base`, optionally with one rectangular hole.
function Build.slab(
	parent: Instance,
	base: CFrame,
	width: number,
	depth: number,
	top: number,
	thickness: number,
	color: Color3,
	material: Enum.Material?,
	hole: Hole?
)
	local y = top - thickness / 2
	local function piece(x0: number, x1: number, z0: number, z1: number)
		if x1 - x0 > 0.05 and z1 - z0 > 0.05 then
			Build.part(
				parent,
				Vector3.new(x1 - x0, thickness, z1 - z0),
				base * CFrame.new((x0 + x1) / 2, y, (z0 + z1) / 2),
				color,
				material
			)
		end
	end
	local w, d = width / 2, depth / 2
	if not hole then
		piece(-w, w, -d, d)
		return
	end
	piece(-w, hole.x0, -d, d)
	piece(hole.x1, w, -d, d)
	piece(hole.x0, hole.x1, -d, hole.z0)
	piece(hole.x0, hole.x1, hole.z1, d)
end

-- Solid staircase climbing along local +X from `base` (floor level at the foot of the stairs).
function Build.stairs(
	parent: Instance,
	base: CFrame,
	steps: number,
	rise: number,
	run: number,
	width: number,
	color: Color3,
	material: Enum.Material?
)
	for step = 1, steps do
		local height = step * rise
		Build.part(
			parent,
			Vector3.new(run, height, width),
			base * CFrame.new((step - 0.5) * run, height / 2, 0),
			color,
			material
		)
	end
end

-- Battlement blocks along local X, standing on `base` (top-of-wall line).
function Build.crenellate(
	parent: Instance,
	base: CFrame,
	length: number,
	thickness: number,
	color: Color3,
	material: Enum.Material?
)
	local merlonWidth, merlonHeight, pitch = 3, 4, 6
	local count = math.floor(length / pitch)
	local start = -(count - 1) * pitch / 2
	for index = 0, count - 1 do
		Build.part(
			parent,
			Vector3.new(merlonWidth, merlonHeight, thickness),
			base * CFrame.new(start + index * pitch, merlonHeight / 2, 0),
			color,
			material
		)
	end
end

-- Four walls of a hollow box ring (e.g. parapet), standing on `base`.
function Build.ring(
	parent: Instance,
	base: CFrame,
	width: number,
	depth: number,
	height: number,
	thickness: number,
	color: Color3,
	material: Enum.Material?
)
	local w, d = width / 2, depth / 2
	local t = thickness / 2
	Build.part(
		parent,
		Vector3.new(width, height, thickness),
		base * CFrame.new(0, height / 2, -d + t),
		color,
		material
	)
	Build.part(
		parent,
		Vector3.new(width, height, thickness),
		base * CFrame.new(0, height / 2, d - t),
		color,
		material
	)
	Build.part(
		parent,
		Vector3.new(thickness, height, depth - thickness * 2),
		base * CFrame.new(-w + t, height / 2, 0),
		color,
		material
	)
	Build.part(
		parent,
		Vector3.new(thickness, height, depth - thickness * 2),
		base * CFrame.new(w - t, height / 2, 0),
		color,
		material
	)
end

export type StoryOptions = {
	width: number,
	depth: number,
	floors: number,
	floorHeight: number,
	wallColor: Color3,
	wallMaterial: Enum.Material?,
	floorColor: Color3,
	floorMaterial: Enum.Material?,
	stairColor: Color3?,
	trimColor: Color3?,
	trimMaterial: Enum.Material?,
	glassColor: Color3?,
	wallThickness: number?,
	windowWidth: number?,
	windowHeight: number?,
	windowSill: number?,
	windowSpacing: number?,
	doorWidth: number?,
	doorHeight: number?,
	sideDoors: boolean?,
	parapet: number?,
	crates: boolean?,
}

export type StoryResult = {
	roofTop: number, -- local Y of the walkable roof
	stairHole: Hole, -- footprint of the roof access hole, in local coordinates
}

local crateRandom = Random.new(77)

-- A walkable multi-story box: floors, windows, front/back doors, switchback stairs to every floor
-- and onto the roof. Stairs run in two lanes along the back wall, alternating direction.
function Build.storyBuilding(parent: Instance, base: CFrame, options: StoryOptions): StoryResult
	local W, D = options.width, options.depth
	local floors, h = options.floors, options.floorHeight
	local wall = options.wallThickness or 2
	local slab = 1
	local windowWidth = options.windowWidth or 6
	local windowHeight = options.windowHeight or math.min(7, h - 6)
	local windowSill = options.windowSill or 3.5
	local spacing = options.windowSpacing or 14
	local doorWidth = options.doorWidth or 12
	local doorHeight = math.min(options.doorHeight or 12, h - 2)
	local stairColor = options.stairColor or options.floorColor

	local run, laneWidth = 1.5, 6
	local steps = h
	local x0 = -W / 2 + wall + 3
	local x1 = x0 + steps * run
	local laneA = D / 2 - wall - laneWidth / 2 - 0.5
	local laneB = laneA - laneWidth
	local function laneHole(flight: number): Hole
		local z = if flight % 2 == 0 then laneA else laneB
		return { x0 = x0, x1 = x1, z0 = z - laneWidth / 2, z1 = z + laneWidth / 2 }
	end

	local function windowsFor(length: number, withDoor: boolean): { Opening }
		local openings = {}
		local count = math.max(0, math.floor((length - 8) / spacing))
		local start = -(count - 1) * spacing / 2
		for index = 0, count - 1 do
			local x = start + index * spacing
			if not (withDoor and math.abs(x) < (doorWidth + windowWidth) / 2 + 1) then
				table.insert(openings, {
					x = x,
					width = windowWidth,
					bottom = windowSill,
					top = windowSill + windowHeight,
				})
			end
		end
		if withDoor then
			table.insert(openings, { x = 0, width = doorWidth, bottom = 0, top = doorHeight })
		end
		return openings
	end

	local function glaze(wallBase: CFrame, openings: { Opening })
		if not options.glassColor then
			return
		end
		for _, opening in openings do
			if opening.bottom > 0 then
				Build.part(
					parent,
					Vector3.new(opening.width, opening.top - opening.bottom, 0.3),
					wallBase * CFrame.new(opening.x, (opening.bottom + opening.top) / 2, 0),
					options.glassColor,
					Enum.Material.Glass,
					{ transparency = 0.45, canCollide = false, canQuery = false, reflectance = 0.2 }
				)
			end
		end
	end

	for floor = 0, floors do
		local level = floor * h
		-- Slab: ground floor solid, every higher floor (and the roof) has the stair hole below it.
		Build.slab(
			parent,
			base * CFrame.new(0, level, 0),
			W,
			D,
			slab,
			slab,
			options.floorColor,
			options.floorMaterial,
			if floor > 0 then laneHole(floor - 1) else nil
		)
		if floor == floors then
			break
		end

		local wallBase = level + slab
		local wallHeight = h - slab
		local ground = floor == 0
		local frontOpenings = windowsFor(W, ground)
		local sideOpenings = windowsFor(D - wall * 2, ground and options.sideDoors == true)
		local walls = {
			{ CFrame.new(0, wallBase, -D / 2 + wall / 2), W, frontOpenings },
			{
				CFrame.new(0, wallBase, D / 2 - wall / 2) * CFrame.Angles(0, math.pi, 0),
				W,
				frontOpenings,
			},
			{
				CFrame.new(-W / 2 + wall / 2, wallBase, 0) * CFrame.Angles(0, math.rad(90), 0),
				D - wall * 2,
				sideOpenings,
			},
			{
				CFrame.new(W / 2 - wall / 2, wallBase, 0) * CFrame.Angles(0, math.rad(-90), 0),
				D - wall * 2,
				sideOpenings,
			},
		}
		for _, spec in walls do
			local wallCFrame = base * spec[1]
			Build.wall(
				parent,
				wallCFrame,
				spec[2],
				wallHeight,
				wall,
				options.wallColor,
				options.wallMaterial,
				spec[3]
			)
			glaze(wallCFrame, spec[3])
		end

		if options.trimColor then
			Build.ring(
				parent,
				base * CFrame.new(0, level - 0.2, 0),
				W + 1,
				D + 1,
				1.6,
				0.6,
				options.trimColor,
				options.trimMaterial
			)
		end

		-- Stairs up from this floor.
		local foot = level + slab
		if floor % 2 == 0 then
			Build.stairs(
				parent,
				base * CFrame.new(x0, foot, laneA),
				steps,
				1,
				run,
				laneWidth,
				stairColor,
				options.floorMaterial
			)
		else
			Build.stairs(
				parent,
				base * CFrame.new(x1, foot, laneB) * CFrame.Angles(0, math.pi, 0),
				steps,
				1,
				run,
				laneWidth,
				stairColor,
				options.floorMaterial
			)
		end

		local crateX0, crateX1 = x1 + 4, W / 2 - wall - 4
		local crateZ0, crateZ1 = -D / 2 + wall + 6, laneB - laneWidth
		if options.crates ~= false and crateX1 > crateX0 and crateZ1 > crateZ0 then
			for _ = 1, 3 do
				local size = crateRandom:NextNumber(3, 5)
				local cx = crateRandom:NextNumber(crateX0, crateX1)
				local cz = crateRandom:NextNumber(crateZ0, crateZ1)
				do
					Build.part(
						parent,
						Vector3.one * size,
						base
							* CFrame.new(cx, foot + size / 2, cz)
							* CFrame.Angles(0, crateRandom:NextNumber(0, 1.5), 0),
						Color3.fromRGB(160, 120, 70),
						Enum.Material.WoodPlanks
					)
				end
			end
		end
	end

	local roofTop = floors * h + slab
	local parapet = options.parapet or 4
	if parapet > 0 then
		Build.ring(
			parent,
			base * CFrame.new(0, roofTop, 0),
			W,
			D,
			parapet,
			1,
			options.wallColor,
			options.wallMaterial
		)
	end

	return { roofTop = roofTop, stairHole = laneHole(floors - 1) }
end

-- A sign floating in the world, readable from any angle.
function Build.billboard(
	parent: Instance,
	position: Vector3,
	text: string,
	color: Color3,
	studsWide: number
): Part
	local anchor = Build.part(parent, Vector3.one, CFrame.new(position), color, nil, {
		transparency = 1,
		canCollide = false,
		canQuery = false,
		name = "Sign",
	})
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromScale(studsWide, studsWide / 5)
	gui.LightInfluence = 0
	gui.MaxDistance = 600
	gui.Parent = anchor
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextScaled = true
	label.Font = Enum.Font.LuckiestGuy
	label.TextColor3 = color
	label.TextStrokeTransparency = 0
	label.Parent = gui
	return anchor
end

return Build
