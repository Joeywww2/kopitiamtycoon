-- Builds the map when the server starts: the ground, the plaza in the middle and a ring of empty plots.
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Build = require(script.Parent.Build)
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local C = Build.Colors
local V = Vector3.new

local World = {}

World.FLOOR = 0.4 -- how far a plot's floor sits above the ground

local function lamp(parent, position)
	Build.part(parent, { Size = V(0.6, 12, 0.6), CFrame = CFrame.new(position + V(0, 6, 0)), Color = C.Dark, Material = Enum.Material.Metal })
	local bulb = Build.ball(parent, CFrame.new(position + V(0, 12.6, 0)), 1.8, Color3.fromRGB(255, 236, 170), Enum.Material.Neon)
	local light = Instance.new("PointLight")
	light.Range = 34
	light.Brightness = 1.2
	light.Color = Color3.fromRGB(255, 225, 160)
	light.Parent = bulb
end

function World.build()
	local map = Instance.new("Folder")
	map.Name = "Map"

	Build.part(map, { Name = "Ground", Size = V(700, 4, 700), CFrame = CFrame.new(0, -2, 0), Color = C.Grass, Material = Enum.Material.Grass })
	Build.part(map, { Name = "Plaza", Size = V(96, 0.3, 96), CFrame = CFrame.new(0, 0.15, 0), Color = C.Tile, Material = Enum.Material.Pavement })

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "PlazaSpawn"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Size = V(10, 0.6, 10)
	spawn.CFrame = CFrame.new(0, 0.6, 26)
	spawn.Color = C.Green
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.Parent = map

	local plots = {}
	for i = 1, Config.PlotCount do
		local angle = (i - 1) * (2 * math.pi / Config.PlotCount)
		local position = V(math.sin(angle), 0, math.cos(angle)) * Config.PlotRadius
		-- Look away from the middle, so the plot's +z (its front) faces the plaza.
		local cframe = CFrame.lookAt(position, position * 2)
		local folder = Instance.new("Folder")
		folder.Name = "Plot" .. i

		Build.part(folder, { Name = "Floor", Size = V(Config.PlotSize, World.FLOOR, Config.PlotSize), CFrame = cframe * CFrame.new(0, World.FLOOR / 2, 0), Color = C.Tile, Material = Enum.Material.Marble })
		Build.part(folder, { Name = "Trim", Size = V(Config.PlotSize + 2, 0.2, Config.PlotSize + 2), CFrame = cframe * CFrame.new(0, 0.1, 0), Color = C.DarkGreen })
		-- A path from the plot's front to the plaza.
		local reach = Config.PlotRadius - Config.PlotSize / 2 - 48
		Build.part(folder, { Name = "Path", Size = V(12, 0.2, reach), CFrame = cframe * CFrame.new(0, 0.1, Config.PlotSize / 2 + reach / 2), Color = C.Stone, Material = Enum.Material.Cobblestone })

		folder.Parent = map
		table.insert(plots, { index = i, cframe = cframe, folder = folder })

		local between = angle + math.pi / Config.PlotCount
		lamp(map, V(math.sin(between), 0, math.cos(between)) * 70)
	end

	map.Parent = workspace

	Lighting.ClockTime = 17.2
	Lighting.Brightness = 2
	Lighting.Ambient = Color3.fromRGB(110, 100, 90)
	Lighting.OutdoorAmbient = Color3.fromRGB(140, 130, 120)

	return { map = map, plots = plots }
end

return World
