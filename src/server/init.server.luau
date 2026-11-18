-- Kopitiam Tycoon: the server. Builds the map, gives each player a plot, runs the money and saves progress.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))

local AhMa = require(script.AhMa)
local Remotes = require(script.Remotes)
local Shop = require(script.Shop)
local Store = require(script.Store)
local Tycoon = require(script.Tycoon)
local World = require(script.World)

local remotes = Remotes.create()
local world = World.build()
local random = Random.new()

local tycoons = {} -- player -> their Tycoon
local freePlots = table.clone(world.plots)
local lastBranchRequest = {} -- player -> clock time, to ignore button mashing

local function save(player)
	local tycoon = tycoons[player]
	if tycoon and tycoon.canSave then
		return Store.save(player.UserId, tycoon:snapshot())
	end
	return false
end

local function placeAtPlot(tycoon, character)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if root and tycoon.alive then
		task.wait(0.1) -- let the default spawn finish first
		character:PivotTo(tycoon:spawnCFrame())
	end
end

local joining = {} -- player -> true while their save loads, so nobody is set up twice

local function onPlayerAdded(player)
	if joining[player] or tycoons[player] then
		return
	end
	joining[player] = true
	local plot = table.remove(freePlots, 1)
	if not plot then
		joining[player] = nil
		player:Kick("Every kopitiam lot here is taken. Please join another server.")
		return
	end

	local data, loaded = Store.load(player.UserId)
	joining[player] = nil
	if player.Parent == nil then -- they left while we were loading
		table.insert(freePlots, plot)
		return
	end

	local tycoon = Tycoon.new(player, plot, data, remotes)
	tycoon.canSave = loaded
	tycoons[player] = tycoon
	tycoon:start()

	player.CharacterAdded:Connect(function(character)
		placeAtPlot(tycoon, character)
	end)
	if player.Character then
		task.spawn(placeAtPlot, tycoon, player.Character)
	end

	Shop.checkPasses(player)
	if loaded then
		local away = tycoon:welcomeBack(os.time())
		if away > 0 then
			tycoon:notify("Welcome back! While you were away, your kopitiam earned " .. Format.money(away) .. ".")
		else
			tycoon:notify("Welcome to your kopitiam! Step on a green pad to buy your next upgrade.")
		end
	else
		tycoon:notify("Your save could not be loaded, so this visit will not be saved. Try again later.")
	end
end

local function onPlayerRemoving(player)
	joining[player] = nil
	local tycoon = tycoons[player]
	if not tycoon then
		return
	end
	save(player)
	tycoons[player] = nil
	lastBranchRequest[player] = nil
	tycoon:destroy()
	table.insert(freePlots, tycoon.plot)
	table.sort(freePlots, function(a, b)
		return a.index < b.index
	end)
end

-- Ah Ma: an angpow when one is due, otherwise a tip.
AhMa.build(world.map, function(player)
	local tycoon = tycoons[player]
	if not tycoon then
		return
	end
	local amount = tycoon:claimAngpow(os.time())
	if amount then
		remotes.AhMa:FireClient(player, "Angpow for you: " .. Format.money(amount) .. ". Don't spend it all on bubble tea.")
	else
		remotes.AhMa:FireClient(player, AhMa.tip(random))
	end
end)

remotes.OpenBranch.OnServerEvent:Connect(function(player)
	local now = os.clock()
	if now - (lastBranchRequest[player] or 0) < 1 then
		return
	end
	lastBranchRequest[player] = now
	local tycoon = tycoons[player]
	if tycoon and tycoon:openBranch() then
		task.spawn(save, player)
	end
end)

Shop.start(function(player)
	return tycoons[player]
end, save)

-- Income a few times a second is plenty; customers move every frame so they walk smoothly.
local sinceStep = 0
RunService.Heartbeat:Connect(function(dt)
	for _, tycoon in tycoons do
		tycoon:stepCustomers(dt)
	end
	sinceStep += dt
	if sinceStep < 0.25 then
		return
	end
	local elapsed = sinceStep
	sinceStep = 0
	for _, tycoon in tycoons do
		tycoon:step(elapsed)
	end
end)

-- Autosave.
task.spawn(function()
	while true do
		task.wait(Config.AutosaveSeconds)
		for player in tycoons do
			task.spawn(save, player)
		end
	end
end)

-- Save everyone when the server shuts down.
game:BindToClose(function()
	local pending = 0
	for player in tycoons do
		pending += 1
		task.spawn(function()
			save(player)
			pending -= 1
		end)
	end
	local waited = 0
	while pending > 0 and waited < 20 do
		waited += task.wait(0.1)
	end
end)

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in Players:GetPlayers() do -- anyone who joined before this script started
	task.spawn(onPlayerAdded, player)
end
