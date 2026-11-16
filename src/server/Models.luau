-- What each thing you buy looks like, built from plain parts.
-- Every builder gets a Model to fill and `at(x, y, z)`, which gives a spot measured from the item's place
-- on the floor: +x right, +y up, +z toward the front of the shop.
local Build = require(script.Parent.Build)
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))

local C = Build.Colors
local V = Vector3.new
local FRONT = Enum.NormalId.Back -- a part's "Back" face points to +z, the front of the shop
local HALF = Config.PlotSize / 2

local function counter(model, at, width, color)
	Build.part(model, { Size = V(width, 3.4, 3), CFrame = at(0, 1.7, 0), Color = color or C.Wood, Material = Enum.Material.Wood })
	Build.part(model, { Size = V(width + 0.4, 0.3, 3.4), CFrame = at(0, 3.55, 0), Color = C.Marble, Material = Enum.Material.Marble })
end

local builders = {}

-- A hawker stall with an awning and a signboard.
function builders.stall(model, at, item)
	counter(model, at, 10)
	for _, x in { -4.7, 4.7 } do
		Build.part(model, { Size = V(0.5, 8.6, 0.5), CFrame = at(x, 4.3, -1.2), Color = C.DarkWood, Material = Enum.Material.Wood })
	end
	Build.part(model, { Size = V(11, 0.4, 5), CFrame = at(0, 8.8, 0.4), Color = C.Green })
	Build.part(model, { Size = V(11, 0.9, 0.3), CFrame = at(0, 8.2, 2.9), Color = C.Cream })
	local board = Build.part(model, { Size = V(9, 1.6, 0.3), CFrame = at(0, 10, 0), Color = C.DarkGreen })
	Build.sign(board, item.name, FRONT, C.Gold)
	Build.cylinder(model, at(-3, 4.5, 0), 1.6, 1.3, C.Steel, Enum.Material.Metal) -- kettle
	for i = 0, 2 do
		Build.cylinder(model, at(1 + i * 1.2, 4, 0.4), 0.7, 0.7, C.White) -- cups
	end
end

-- A round marble table with four stools.
function builders.table(model, at)
	Build.cylinder(model, at(0, 3, 0), 0.35, 5, C.Marble, Enum.Material.Marble)
	Build.cylinder(model, at(0, 1.45, 0), 2.9, 0.7, C.DarkWood, Enum.Material.Wood)
	Build.cylinder(model, at(0, 0.15, 0), 0.3, 2.4, C.DarkWood, Enum.Material.Wood)
	for _, p in { { 3.6, 0 }, { -3.6, 0 }, { 0, 3.6 }, { 0, -3.6 } } do
		Build.cylinder(model, at(p[1], 1, p[2]), 2, 1.5, C.Wood, Enum.Material.Wood)
	end
	Build.cylinder(model, at(0.8, 3.5, 0.3), 0.6, 0.6, C.White) -- a cup of kopi
	Build.cylinder(model, at(0.8, 3.75, 0.3), 0.1, 0.45, C.DarkWood)
end

function builders.toaster(model, at)
	counter(model, at, 7)
	Build.part(model, { Size = V(2.4, 1.6, 1.4), CFrame = at(-1.2, 4.5, 0), Color = C.Steel, Material = Enum.Material.Metal })
	for _, x in { -1.7, -0.7 } do
		Build.part(model, { Size = V(0.3, 1, 1), CFrame = at(x, 5.4, 0), Color = Color3.fromRGB(210, 160, 90) })
	end
	Build.part(model, { Size = V(2, 0.2, 1.6), CFrame = at(2, 3.8, 0), Color = C.White }) -- plate
	Build.part(model, { Size = V(1.2, 0.3, 1.2), CFrame = at(2, 4.05, 0), Color = Color3.fromRGB(210, 160, 90) })
	Build.part(model, { Size = V(1.1, 0.12, 1.1), CFrame = at(2, 4.26, 0), Color = C.Pandan }) -- kaya
end

function builders.eggs(model, at)
	counter(model, at, 7)
	Build.cylinder(model, at(-1.5, 4.4, 0), 1.4, 2, C.Steel, Enum.Material.Metal) -- pot
	Build.part(model, { Size = V(2.6, 0.2, 1.6), CFrame = at(2, 3.8, 0), Color = C.DarkWood })
	for i = 0, 3 do
		Build.ball(model, at(1.1 + i * 0.6, 4.2, 0), 0.6, C.White)
	end
end

function builders.tehtarik(model, at)
	counter(model, at, 8)
	Build.cylinder(model, at(-2, 5.2, 0), 3, 1.8, C.Steel, Enum.Material.Metal) -- urn
	Build.cylinder(model, at(-2, 6.85, 0), 0.3, 1.2, C.Dark)
	for i = 0, 2 do
		Build.cylinder(model, at(0.8 + i * 1.1, 4.2, 0.3), 1, 0.8, Color3.fromRGB(200, 140, 80), Enum.Material.Glass)
	end
end

-- Walls on three sides, a tiled stripe, and beams overhead for the fans. The front stays open.
function builders.walls(model, at)
	local h = 14
	local function wall(size, cf)
		Build.part(model, { Size = size, CFrame = cf, Color = C.Cream })
	end
	wall(V(HALF * 2, h, 1), at(0, h / 2, -HALF + 0.5))
	wall(V(1, h, HALF * 2 - 1), at(-HALF + 0.5, h / 2, 0.5))
	wall(V(1, h, HALF * 2 - 1), at(HALF - 0.5, h / 2, 0.5))
	Build.part(model, { Size = V(HALF * 2 - 2, 3, 0.2), CFrame = at(0, 1.5, -HALF + 1.1), Color = C.Green }) -- tile stripe
	for _, x in { -HALF + 1.1, HALF - 1.1 } do
		Build.part(model, { Size = V(0.2, 3, HALF * 2 - 2), CFrame = at(x, 1.5, 0.5), Color = C.Green })
	end
	for _, x in { -HALF + 1, HALF - 1 } do -- front pillars
		Build.part(model, { Size = V(2, h + 4, 2), CFrame = at(x, (h + 4) / 2, HALF - 1), Color = C.Cream })
	end
	Build.part(model, { Size = V(HALF * 2, 3, 1.5), CFrame = at(0, h + 2.5, HALF - 1), Color = C.Cream }) -- front beam
	for _, z in { -20, 0, 20 } do -- beams; the fans hang from the middle one
		Build.part(model, { Size = V(HALF * 2 - 2, 0.8, 0.8), CFrame = at(0, h + 1.6, z), Color = C.DarkWood, Material = Enum.Material.Wood, CanCollide = false })
	end
end

-- Three ceiling fans. The blades are tagged so each player's screen spins them.
function builders.fans(model, at)
	for _, x in { -16, 0, 16 } do
		Build.part(model, { Size = V(0.3, 1.6, 0.3), CFrame = at(x, 0, 0), Color = C.Dark, CanCollide = false })
		local blades = Instance.new("Model")
		blades.Name = "FanBlades"
		local hub = Build.cylinder(blades, at(x, -0.9, 0), 0.5, 1.4, C.Dark)
		hub.CanCollide = false
		for i = 0, 2 do
			Build.part(blades, {
				Size = V(5, 0.12, 1.1),
				CFrame = at(x, -0.9, 0) * CFrame.Angles(0, math.rad(i * 120), 0) * CFrame.new(3, 0, 0),
				Color = C.DarkWood,
				CanCollide = false,
			})
		end
		blades.PrimaryPart = hub
		blades:AddTag("Spin")
		blades.Parent = model
	end
end

function builders.wok(model, at, item)
	counter(model, at, 8, C.Steel)
	Build.part(model, { Size = V(3, 0.6, 2.6), CFrame = at(-1.5, 4, 0), Color = C.Dark, Material = Enum.Material.Metal }) -- stove
	Build.cylinder(model, at(-1.5, 4.6, 0), 0.6, 3, C.Dark, Enum.Material.Metal) -- wok
	Build.cylinder(model, at(-1.5, 4.95, 0), 0.15, 2.4, C.Orange, Enum.Material.Neon) -- hot food
	Build.part(model, { Size = V(2.4, 0.2, 1.6), CFrame = at(2.2, 3.8, 0), Color = C.White })
	local board = Build.part(model, { Size = V(7, 1.3, 0.3), CFrame = at(0, 7.4, -1.2), Color = C.Red })
	Build.sign(board, item.name, FRONT, C.White)
	for _, x in { -3.6, 3.6 } do
		Build.part(model, { Size = V(0.3, 4, 0.3), CFrame = at(x, 5.4, -1.2), Color = C.Dark })
	end
end

function builders.shelf(model, at)
	Build.part(model, { Size = V(8, 8, 0.4), CFrame = at(0, 4, -1), Color = C.DarkWood, Material = Enum.Material.Wood })
	for i = 0, 2 do
		local y = 1.6 + i * 2.6
		Build.part(model, { Size = V(8, 0.3, 2), CFrame = at(0, y, 0), Color = C.Wood, Material = Enum.Material.Wood })
		for j = 0, 4 do
			Build.cylinder(model, at(-3 + j * 1.5, y + 0.75, 0), 1.2, 0.9, C.Pandan, Enum.Material.Glass)
			Build.cylinder(model, at(-3 + j * 1.5, y + 1.42, 0), 0.15, 0.95, C.Gold)
		end
	end
end

-- Ah Boy, who empties the till for you.
function builders.helper(model, at)
	local _, torso = Build.person(model, at(0, 0, 0), { name = "Ah Boy", shirt = C.White, pants = C.Dark, hair = C.Dark })
	Build.part(model, { Size = V(2.1, 1.6, 0.2), CFrame = at(0, 2.6, 0.6), Color = C.Green }) -- apron
	Build.floatingText(torso, "Ah Boy", { lift = 3.4, width = 5, height = 1.2 })
end

function builders.grill(model, at)
	for _, x in { -3, 3 } do
		Build.part(model, { Size = V(0.4, 3, 0.4), CFrame = at(x, 1.5, 0), Color = C.Dark })
	end
	Build.part(model, { Size = V(8, 0.9, 2), CFrame = at(0, 3.3, 0), Color = C.Dark, Material = Enum.Material.Metal })
	Build.part(model, { Size = V(7.4, 0.2, 1.4), CFrame = at(0, 3.8, 0), Color = C.Orange, Material = Enum.Material.Neon }) -- charcoal
	for i = 0, 7 do
		Build.part(model, { Size = V(0.15, 0.15, 2.8), CFrame = at(-3.2 + i * 0.9, 4, 0), Color = C.Wood })
		Build.part(model, { Size = V(0.4, 0.35, 1.3), CFrame = at(-3.2 + i * 0.9, 4.05, -0.4), Color = Color3.fromRGB(150, 85, 45) })
	end
end

function builders.cart(model, at, item)
	Build.part(model, { Size = V(6, 3, 3), CFrame = at(0, 2.7, 0), Color = C.Pandan })
	for _, x in { -2, 2 } do
		Build.part(model, { Shape = Enum.PartType.Cylinder, Size = V(0.5, 2.4, 2.4), CFrame = at(x, 1.2, 1.7) * CFrame.Angles(0, math.rad(90), 0), Color = C.Dark })
	end
	for _, x in { -2.7, 2.7 } do
		Build.part(model, { Size = V(0.3, 4.4, 0.3), CFrame = at(x, 6.4, -1), Color = C.Dark })
	end
	Build.part(model, { Size = V(7, 0.4, 4), CFrame = at(0, 8.8, 0), Color = C.White })
	Build.part(model, { Size = V(7, 0.4, 1.3), CFrame = at(0, 8.8, 1.35), Color = C.Red })
	Build.cylinder(model, at(1.5, 4.6, 0), 0.8, 1.6, C.White) -- bowl
	Build.cylinder(model, at(1.5, 5.05, 0), 0.2, 1.3, C.Pandan)
	Build.part(model, { Size = V(2, 1.6, 2), CFrame = at(-1.5, 5, 0), Color = C.White, Material = Enum.Material.Ice, Transparency = 0.2 }) -- ice block
	local board = Build.part(model, { Size = V(5.6, 1.2, 0.2), CFrame = at(0, 3, 1.6), Color = C.White })
	Build.sign(board, item.name, FRONT, C.DarkGreen)
end

function builders.griddle(model, at, item)
	counter(model, at, 8, C.Steel)
	Build.part(model, { Size = V(5, 0.4, 2.6), CFrame = at(-1, 3.9, 0), Color = C.Dark, Material = Enum.Material.Metal })
	for i = 0, 2 do
		Build.cylinder(model, at(-2.4 + i * 1.5, 4.2, 0), 0.15, 1.3, Color3.fromRGB(230, 200, 140))
	end
	Build.cylinder(model, at(2.8, 4.3, 0), 1.2, 1, C.Steel, Enum.Material.Metal) -- curry pot
	local board = Build.part(model, { Size = V(7, 1.3, 0.3), CFrame = at(0, 7.4, -1.2), Color = C.Orange })
	Build.sign(board, item.name, FRONT, C.White)
	for _, x in { -3.6, 3.6 } do
		Build.part(model, { Size = V(0.3, 4, 0.3), CFrame = at(x, 5.4, -1.2), Color = C.Dark })
	end
end

-- A television on the back wall.
function builders.tv(model, at)
	Build.part(model, { Size = V(1, 1, 0.8), CFrame = at(0, 0, 0.1), Color = C.Dark })
	local screen = Build.part(model, { Size = V(11, 6, 0.4), CFrame = at(0, 0, 0.7), Color = Color3.fromRGB(30, 110, 60), Material = Enum.Material.Neon })
	Build.part(model, { Size = V(11.6, 6.6, 0.3), CFrame = at(0, 0, 0.45), Color = C.Dark })
	Build.sign(screen, "LIVE   2 - 1", FRONT, C.White)
end

-- The big sign over the entrance, with the owner's name.
function builders.neon(model, at, _item, ownerName)
	local board = Build.part(model, { Size = V(34, 4.5, 0.6), CFrame = at(0, 0, 0.3), Color = C.Red, Material = Enum.Material.Neon })
	Build.part(model, { Size = V(35, 5.5, 0.4), CFrame = at(0, 0, 0), Color = C.Dark })
	Build.sign(board, ownerName .. "'s Kopitiam", FRONT, C.White)
end

function builders.durian(model, at, item)
	Build.part(model, { Size = V(8, 2.6, 4), CFrame = at(0, 1.3, 0), Color = C.Wood, Material = Enum.Material.WoodPlanks })
	local spots = { { -2.6, 0 }, { -0.9, 0.5 }, { 0.9, -0.4 }, { 2.6, 0.3 }, { -1.7, -1 }, { 1.8, -1.1 } }
	for i, p in spots do
		Build.ball(model, at(p[1], 3.5, p[2]), 1.7, Color3.fromRGB(150, 160, 60), Enum.Material.Pebble)
		if i <= 2 then
			Build.ball(model, at(p[1] * 0.6, 4.8, p[2]), 1.5, Color3.fromRGB(150, 160, 60), Enum.Material.Pebble)
		end
	end
	local board = Build.part(model, { Size = V(7, 1.3, 0.2), CFrame = at(0, 1.4, 2.1), Color = Color3.fromRGB(245, 215, 90) })
	Build.sign(board, item.name, FRONT, C.DarkGreen)
end

-- Two wall units, one on each side wall.
function builders.aircon(model, at)
	for _, side in { -1, 1 } do
		local x = side * (HALF - 1.9)
		Build.part(model, { Size = V(1.8, 2.2, 7), CFrame = at(x, 0, 0), Color = C.White })
		Build.part(model, { Size = V(0.2, 0.3, 6), CFrame = at(x - side * 0.95, -0.8, 0), Color = Color3.fromRGB(120, 200, 255), Material = Enum.Material.Neon })
	end
end

-- A pasar malam tent with goods and a string of lights.
function builders.tent(model, at, item)
	for _, p in { { -4, -3 }, { 4, -3 }, { -4, 3 }, { 4, 3 } } do
		Build.part(model, { Size = V(0.3, 8, 0.3), CFrame = at(p[1], 4, p[2]), Color = C.Steel, Material = Enum.Material.Metal })
	end
	Build.part(model, { Size = V(9.4, 0.4, 7.4), CFrame = at(0, 8.2, 0), Color = C.Red })
	Build.part(model, { Size = V(6, 1.2, 4.6), CFrame = at(0, 9, 0), Color = C.White })
	Build.part(model, { Size = V(7, 2.6, 3), CFrame = at(0, 1.3, 0), Color = C.Wood, Material = Enum.Material.WoodPlanks })
	local goods = { C.Orange, C.Pandan, C.Gold, C.Red, C.White }
	for i, color in goods do
		Build.part(model, { Size = V(1, 0.9, 1.6), CFrame = at(-3.6 + i * 1.2, 3.05, 0), Color = color })
	end
	for i = 0, 6 do
		Build.ball(model, at(-4 + i * 1.33, 7.6, 3.1), 0.5, C.Gold, Enum.Material.Neon)
	end
	local board = Build.part(model, { Size = V(6.4, 1.2, 0.2), CFrame = at(0, 1.4, 1.6), Color = C.Dark })
	Build.sign(board, item.name, FRONT, C.Gold)
end

-- Two delivery scooters parked out front.
function builders.riders(model, at)
	for n, x in { -3.5, 3.5 } do
		Build.part(model, { Size = V(1.2, 1.4, 4.4), CFrame = at(x, 1.7, 0), Color = n == 1 and C.Red or C.Green })
		Build.part(model, { Size = V(1.1, 0.4, 2), CFrame = at(x, 2.6, 0.3), Color = C.Dark }) -- seat
		Build.part(model, { Size = V(0.3, 2, 0.3), CFrame = at(x, 3, -1.7), Color = C.Dark }) -- handlebar post
		Build.part(model, { Size = V(2.2, 0.3, 0.3), CFrame = at(x, 4, -1.7), Color = C.Dark })
		for _, z in { -1.9, 1.9 } do
			Build.part(model, { Shape = Enum.PartType.Cylinder, Size = V(0.6, 1.9, 1.9), CFrame = at(x, 0.95, z), Color = C.Dark })
		end
		Build.part(model, { Size = V(1.8, 1.8, 1.8), CFrame = at(x, 3.7, 1.6), Color = C.Pandan }) -- delivery box
	end
end

function builders.plaque(model, at)
	Build.part(model, { Size = V(3, 3, 3), CFrame = at(0, 1.5, 0), Color = C.Marble, Material = Enum.Material.Marble })
	local plate = Build.part(model, { Size = V(5, 3.4, 0.4), CFrame = at(0, 4.9, 0), Color = C.Gold, Material = Enum.Material.Metal })
	Build.sign(plate, "FRANCHISE LICENCE", FRONT, C.Dark)
end

local Models = {}

-- Builds one item on a plot and returns its Model. `floor` is the plot's CFrame at floor height.
function Models.build(item, parent, floor, ownerName)
	local model = Instance.new("Model")
	model.Name = item.id
	local base = floor * CFrame.new(item.x, item.y or 0, item.z)
	local function at(x, y, z)
		return base * CFrame.new(x, y, z)
	end
	local builder = builders[item.kind]
	if builder then
		builder(model, at, item, ownerName)
	else
		warn("No model for kind " .. tostring(item.kind))
	end
	model.Parent = parent
	return model
end

Models.kinds = builders

return Models
