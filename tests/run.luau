-- Plays Kopitiam Tycoon from start to finish with fake players, against the real built place file.
-- Run with:  rojo build -o build/KopitiamTycoon.rbxlx && lune run tests/run
local fs = require("@lune/fs")
local process = require("@lune/process")
local Enum = require("@lune/roblox").Enum
local serde = require("@lune/serde")
local task = require("@lune/task")

local Engine = require("./engine")

local passed, failed = 0, 0
local function check(name, condition, detail)
	if condition then
		passed += 1
	else
		failed += 1
		print("  FAIL " .. name .. (detail and (": " .. tostring(detail)) or ""))
	end
end
local function section(title)
	print("\n" .. title)
end

local function main()
local game = Engine.load("build/KopitiamTycoon.rbxlx")
local workspace = game:GetService("Workspace")
local shared = game:GetService("ReplicatedStorage").Shared
local Catalog = Engine.require(shared.Catalog)
local Config = Engine.require(shared.Config)
local Economy = Engine.require(shared.Economy)
local Format = Engine.require(shared.Format)
local SaveData = Engine.require(shared.SaveData)

-- ── 1. The rules on their own ────────────────────────────────────────────────────────────────────
section("Rules")
check("money small", Format.money(950) == "RM 950", Format.money(950))
check("money commas", Format.money(1250) == "RM 1,250", Format.money(1250))
check("money K", Format.money(12500) == "RM 12.5K", Format.money(12500))
check("money M", Format.money(3200000) == "RM 3.20M", Format.money(3200000))
check("money never negative", Format.money(-5) == "RM 0")

local seen, order = {}, {}
local starters = 0
for index, item in Catalog.items do
	check("unique id " .. item.id, not seen[item.id])
	seen[item.id] = true
	order[item.id] = index
	if item.price == 0 then
		starters += 1
	end
	check("price is a whole number " .. item.id, item.price == math.floor(item.price) and item.price >= 0)
	check("on the plot " .. item.id, math.abs(item.x) <= Config.PlotSize / 2 and math.abs(item.z) <= Config.PlotSize / 2 + 6)
	for _, need in item.requires do
		check(item.id .. " requires something earlier", order[need] ~= nil, need)
	end
	if index > 1 then
		check("prices rise " .. item.id, item.price > Catalog.items[index - 1].price)
	end
end
check("one free starter", starters == 1 and Catalog.byId[Catalog.starter].price == 0)

check("branch multiplier", Economy.multiplier(0) == 1 and Economy.multiplier(2) == 2)
check("income of starter", Economy.incomePerSecond({ kopi_stall = true }, 0) == 1)
check("income with a branch", Economy.incomePerSecond({ kopi_stall = true }, 1) == 1.5)
check("till minimum", Economy.tillCapacity(0.1) == Config.TillMinimum)
check("cannot buy unknown", select(1, Economy.canBuy("nope", {}, 1e9)) == false)
check("cannot buy twice", select(1, Economy.canBuy("kopi_stall", { kopi_stall = true }, 1e9)) == false)
check("cannot skip ahead", select(1, Economy.canBuy("franchise", { kopi_stall = true }, 1e9)) == false)
check("cannot buy when poor", select(1, Economy.canBuy("table_1", { kopi_stall = true }, 24)) == false)
check("can buy when ready", select(1, Economy.canBuy("table_1", { kopi_stall = true }, 25)) == true)

local junk = SaveData.clean({ cash = -50, branches = "many", owned = { "table_1", "table_1", "hacked_item", 7 }, lastAngpow = 0 / 0 })
check("clean: bad cash", junk.cash == Config.StartCash)
check("clean: bad branches", junk.branches == 0)
check("clean: owned", #junk.owned == 2 and junk.owned[1] == "kopi_stall" and junk.owned[2] == "table_1", table.concat(junk.owned, ","))
check("clean: nan time", junk.lastAngpow == 0)
check("clean: not a table", #SaveData.clean("oops").owned == 1)
local olderSave = SaveData.clean({ version = 1, cash = 10, branches = 0, owned = { "kopi_stall" }, lastAngpow = 0 })
check("clean: a version 1 save gets the new fields", olderSave.lastSeen == 0 and #olderSave.receipts == 0)
local receiptSave = SaveData.clean({ receipts = { "a", 5, "b", string.rep("x", 200) }, lastSeen = -4 })
check("clean: receipts keep only short strings", table.concat(receiptSave.receipts, ",") == "a,b", table.concat(receiptSave.receipts, ","))
check("clean: bad lastSeen", receiptSave.lastSeen == 0)

check("offline: short breaks earn nothing", Economy.offlineEarnings(10, Config.OfflineMinimumSeconds - 1) == 0)
check("offline: half pay while away", Economy.offlineEarnings(10, 3600) == math.floor(3600 * 10 * Config.OfflineShare))
check("offline: capped at a few hours", Economy.offlineEarnings(10, 30 * 24 * 3600) == math.floor(Config.OfflineHours * 3600 * 10 * Config.OfflineShare))
check("cash pack: seconds of income", Economy.cashPack(10, 900, 500) == 9000)
check("cash pack: never below the minimum", Economy.cashPack(0.1, 900, 500) == 500)
check("double cash doubles income", Economy.incomePerSecond({ kopi_stall = true }, 1, 2) == 3)

-- Turn the shop and a sound on, as Joey will once he has made them in the Creator Hub.
Config.GamePasses.DoubleCash = 111
Config.GamePasses.AutoCollect = 222
Config.Products.CashSmall.id = 333
Config.Products.CashBig.id = 444
Config.Sounds.Buy = "rbxassetid://1"
Config.Sounds.Collect = "rbxassetid://2"

-- ── 2. Start the server ──────────────────────────────────────────────────────────────────────────
section("Server start")
Engine.run(game:GetService("ServerScriptService").Server)
local map = workspace:FindFirstChild("Map")
check("map built", map ~= nil)
check("six plots", map and #(function()
	local plots = {}
	for _, child in map:GetChildren() do
		if child.Name:match("^Plot%d$") then
			table.insert(plots, child)
		end
	end
	return plots
end)() == Config.PlotCount)
check("Ah Ma is in the plaza", map:FindFirstChild("AhMa") ~= nil)
check("remotes exist", game:GetService("ReplicatedStorage"):FindFirstChild("Remotes") ~= nil)
check("a spawn exists", map:FindFirstChild("PlazaSpawn") ~= nil)
local models = Engine.require(game:GetService("ServerScriptService").Server.Models)
for _, item in Catalog.items do
	check("model exists for " .. item.kind, models.kinds[item.kind] ~= nil)
end

-- ── 3. A new player ──────────────────────────────────────────────────────────────────────────────
section("New player")
local remotes = game:GetService("ReplicatedStorage").Remotes
local joey = Engine.join("Joey", 1001)
local joeyCharacter, joeyRoot = Engine.spawnCharacter(joey)
task.wait(0.2)

local function tycoonFolder(player)
	for _, plot in map:GetChildren() do
		local folder = plot:FindFirstChild("Tycoon_" .. player.Name)
		if folder then
			return folder, plot
		end
	end
	return nil
end
local function padNames(player)
	local folder = tycoonFolder(player)
	local names = {}
	for _, pad in folder.Pads:GetChildren() do
		table.insert(names, pad.Name)
	end
	table.sort(names)
	return names
end
local function touch(player, part, withPart)
	Engine.signal(part, "Touched"):Fire(withPart)
end
local function state(player)
	return Engine.last(player, "State")
end

local folder, plot = tycoonFolder(joey)
check("got a plot", folder ~= nil and plot.Name == "Plot1", plot and plot.Name)
check("starter stall is built", folder.Items:FindFirstChild("kopi_stall") ~= nil)
check("only the next pad shows", table.concat(padNames(joey), ",") == "Buy_table_1", table.concat(padNames(joey), ","))
check("starts with RM 0 and RM 1 a second", state(joey).cash == 0 and state(joey).income == 1)
check("leaderboard shows", joey:FindFirstChild("leaderstats") and joey.leaderstats.Ringgit.Value == 0 and joey.leaderstats.Branches.Value == 1)
check("welcome message", (Engine.last(joey, "Notify") or ""):find("Welcome") ~= nil, Engine.last(joey, "Notify"))
check("moved to own plot", (joeyCharacter:GetPivot().Position - plot.Floor.CFrame.Position).Magnitude < 40)

section("Earning and the till")
Engine.advance(10)
check("till fills", state(joey).till == 10 and state(joey).cash == 0, state(joey).till)
touch(joey, folder.CollectPad, joeyRoot)
check("collecting moves it to cash", state(joey).cash == 10 and state(joey).till == 0, state(joey).cash)
check("collect message", Engine.last(joey, "Notify") == "Collected RM 10.", Engine.last(joey, "Notify"))
Engine.advance(1000)
check("till stops when full", state(joey).till == state(joey).tillMax and state(joey).tillMax == 300, state(joey).till)
touch(joey, folder.CollectPad, joeyRoot)

section("Buying")
local stranger = Engine.join("Stranger", 2002)
local _, strangerRoot = Engine.spawnCharacter(stranger)
task.wait(0.2)
local before = state(joey).cash
touch(joey, folder.Pads.Buy_table_1, strangerRoot)
check("someone else cannot buy with my money", state(joey).cash == before and folder.Items:FindFirstChild("table_1") == nil)
touch(joey, folder.Pads.Buy_table_1, joeyRoot)
check("buying takes the price", state(joey).cash == before - 25, state(joey).cash)
check("the table appears", folder.Items:FindFirstChild("table_1") ~= nil)
check("income goes up", state(joey).income == 2)
check("next pad appears, old one goes", table.concat(padNames(joey), ",") == "Buy_roti_bakar", table.concat(padNames(joey), ","))
check("stranger has their own plot", select(2, tycoonFolder(stranger)).Name == "Plot2")

-- RM 310 buys the table (25), toaster (60) and eggs (120), leaving RM 105: not enough for the RM 200 table.
touch(joey, folder.Pads.Buy_roti_bakar, joeyRoot)
touch(joey, folder.Pads.Buy_half_boiled, joeyRoot)
local cashNow = state(joey).cash
check("three buys leave RM 105", cashNow == 105, cashNow)
touch(joey, folder.Pads.Buy_table_2, joeyRoot)
check("cannot overspend", state(joey).cash == cashNow and folder.Items:FindFirstChild("table_2") == nil)
check("told how much is missing", Engine.last(joey, "Notify") == "You need RM 95 more for the Second Table.", Engine.last(joey, "Notify"))
check("pad is red when too dear", folder.Pads.Buy_table_2.Color.G < 0.5)
Engine.advance(100, 1)
touch(joey, folder.CollectPad, joeyRoot)
check("pad turns green when affordable", folder.Pads.Buy_table_2.Color.G > 0.7)

-- ── 4. Play all the way to the Franchise Licence ─────────────────────────────────────────────────
section("Whole game")
local function playToFranchise(player, root)
	local mine = tycoonFolder(player)
	local seconds = 0
	local guard = 0
	while not state(player).canOpenBranch do
		guard += 1
		assert(guard < 200000, "the game never finishes")
		local bought = false
		for _, pad in mine.Pads:GetChildren() do
			local item = Catalog.byId[pad.Name:sub(5)]
			if state(player).cash >= item.price then
				touch(player, pad, root)
				bought = true
				break
			end
		end
		if not bought then
			Engine.advance(5, 1)
			seconds += 5
			if not state(player).autoCollect then
				touch(player, mine.CollectPad, root)
			end
		end
	end
	return seconds
end
local firstRun = playToFranchise(joey, joeyRoot)
print(string.format("  first branch takes about %d minutes of play", math.floor(firstRun / 60 + 0.5)))
check("first branch takes 20 to 90 minutes", firstRun > 20 * 60 and firstRun < 90 * 60, firstRun)
local built = 0
for _, item in Catalog.items do
	if folder.Items:FindFirstChild(item.id) then
		built += 1
	end
end
check("every item is built", built == #Catalog.items, built)
check("no pads left", #folder.Pads:GetChildren() == 0)
check("Ah Boy collects by himself", state(joey).autoCollect == true)
check("fans are tagged to spin", #game:GetService("CollectionService"):GetTagged("Spin") == 3)
check("the neon sign carries the owner's name", (function()
	for _, d in folder.Items.neon_sign:GetDescendants() do
		if d.ClassName == "TextLabel" and d.Text == "Joey's Kopitiam" then
			return true
		end
	end
	return false
end)())

-- A picture of the finished shop, for checking how it looks.
local parts = {}
for _, d in workspace:GetDescendants() do
	if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
		-- Moved models (customers) only record their pivot here, so place each part as Roblox would.
		local cframe = d.CFrame
		local model = d:FindFirstAncestorWhichIsA("Model")
		if model and model.PrimaryPart and model.PrimaryPart ~= d then
			cframe = model:GetPivot() * model.PrimaryPart.CFrame:Inverse() * d.CFrame
		elseif model and model.PrimaryPart == d then
			cframe = model:GetPivot()
		end
		table.insert(parts, { s = { d.Size.X, d.Size.Y, d.Size.Z }, c = { cframe:GetComponents() }, k = { d.Color.R, d.Color.G, d.Color.B }, sh = d.ClassName == "Part" and d.Shape.Name or "Block", t = d.Transparency, n = d.Material.Name == "Neon" })
	end
end
fs.writeFile("build/scene.json", serde.encode("json", { parts = parts, focus = { plot.Floor.CFrame.Position.X, plot.Floor.CFrame.Position.Y, plot.Floor.CFrame.Position.Z } }))
print("  wrote build/scene.json with " .. #parts .. " parts")

-- ── 5. Opening a new branch ──────────────────────────────────────────────────────────────────────
section("New branch")
Engine.signal(remotes.OpenBranch, "OnServerEvent"):Fire(stranger)
check("no licence, no branch", Engine.last(stranger, "Notify") == "Buy the Franchise Licence first.", Engine.last(stranger, "Notify"))
Engine.signal(remotes.OpenBranch, "OnServerEvent"):Fire(joey)
check("branch opens", state(joey).branches == 1 and state(joey).multiplier == 1.5)
check("starts again from one stall", #folder.Items:GetChildren() == 1 and folder.Items:FindFirstChild("kopi_stall") ~= nil)
check("cash and till reset", state(joey).cash == 0 and state(joey).till == 0)
check("income uses the multiplier", state(joey).income == 1.5)
check("first pad is back", table.concat(padNames(joey), ",") == "Buy_table_1")
check("leaderboard counts branches", joey.leaderstats.Branches.Value == 2)
Engine.signal(remotes.OpenBranch, "OnServerEvent"):Fire(joey)
check("cannot open another straight away", state(joey).branches == 1)
check("opening a branch saves", Engine.store.data.player_1001 ~= nil and Engine.store.data.player_1001.branches == 1)

-- ── 6. Ah Ma ─────────────────────────────────────────────────────────────────────────────────────
section("Ah Ma")
local prompt
for _, d in map.AhMa:GetDescendants() do
	if d.ClassName == "ProximityPrompt" then
		prompt = d
	end
end
check("Ah Ma can be talked to", prompt ~= nil)
local cashBefore = state(joey).cash
Engine.signal(prompt, "Triggered"):Fire(joey)
check("first talk gives an angpow", (Engine.last(joey, "AhMa") or ""):find("Angpow") ~= nil, Engine.last(joey, "AhMa"))
check("angpow is at least the minimum", state(joey).cash - cashBefore == math.max(Config.AngpowMinimum, 1.5 * Config.AngpowSeconds), state(joey).cash - cashBefore)
local afterAngpow = state(joey).cash
Engine.signal(prompt, "Triggered"):Fire(joey)
check("second talk is a tip, no more money", state(joey).cash == afterAngpow and (Engine.last(joey, "AhMa") or ""):find("Angpow for you") == nil, Engine.last(joey, "AhMa"))

-- ── 7. Saving and coming back ────────────────────────────────────────────────────────────────────
section("Saving")
touch(joey, folder.Pads.Buy_table_1, joeyRoot)
Engine.advance(7)
local expectCash = state(joey).cash + state(joey).till
Engine.leave(joey)
local saved = Engine.store.data.player_1001
check("leaving saves", saved ~= nil)
check("save keeps cash and till", saved and saved.cash == expectCash, saved and saved.cash)
check("save keeps items", saved and table.concat(saved.owned, ",") == "kopi_stall,table_1", saved and table.concat(saved.owned, ","))
check("save keeps branches and angpow time", saved and saved.branches == 1 and saved.lastAngpow > 0)
check("plot is cleared", plot:FindFirstChild("Tycoon_Joey") == nil)

joey = Engine.join("Joey", 1001)
joeyCharacter, joeyRoot = Engine.spawnCharacter(joey)
task.wait(0.2)
folder, plot = tycoonFolder(joey)
check("comes back to a plot", folder ~= nil and plot.Name == "Plot1", plot and plot.Name)
check("cash is back", state(joey).cash == expectCash, state(joey).cash)
check("items are back", folder.Items:FindFirstChild("table_1") ~= nil and state(joey).income == 3)
check("branch is back", state(joey).branches == 1)
Engine.signal(prompt, "Triggered"):Fire(joey)
check("no second angpow after rejoining", (Engine.last(joey, "AhMa") or ""):find("Angpow for you") == nil)

section("Customers")
local customerFolder = folder:FindFirstChild("Customers")
check("customers have a place", customerFolder ~= nil)
local mostAtOnce, everSpoke = 0, false
for _ = 1, 160 do
	Engine.advance(0.25)
	local inside = #customerFolder:GetChildren()
	mostAtOnce = math.max(mostAtOnce, inside)
	for _, d in customerFolder:GetDescendants() do
		if d.ClassName == "TextLabel" then
			everSpoke = true
		end
	end
end
check("customers walk in", mostAtOnce >= 1, mostAtOnce)
local standing = true
for _, model in customerFolder:GetChildren() do
	local height = model:GetPivot().Position.Y - plot.Floor.CFrame.Position.Y
	if height < 2.5 then
		standing = false
	end
end
check("customers stand on the floor, not in it", standing)
check("no more than the shop can hold", mostAtOnce <= Config.CustomerMax, mostAtOnce)
check("customers order something", everSpoke)
local touchy = false
for _, d in customerFolder:GetDescendants() do
	if d:IsA("BasePart") and (d.CanTouch or d.CanCollide) then
		touchy = true
	end
end
check("customers never press buy pads or block the way", not touchy)

section("Offline earnings")
Engine.store.data.player_7007 = { version = 2, cash = 0, branches = 0, owned = { "kopi_stall", "table_1" }, lastAngpow = 0, lastSeen = os.time() - 3600, receipts = {} }
local returning = Engine.join("Returning", 7007)
Engine.spawnCharacter(returning)
task.wait(0.2)
local expectAway = math.floor(3600 * 2 * Config.OfflineShare)
check("earns while away", state(returning).cash == expectAway, state(returning).cash)
check("is told what was earned", (Engine.last(returning, "Notify") or ""):find("While you were away, your kopitiam earned " .. Format.money(expectAway), 1, true) ~= nil, Engine.last(returning, "Notify"))
Engine.leave(returning)
check("save remembers when they left", math.abs(Engine.store.data.player_7007.lastSeen - os.time()) <= 2)
returning = Engine.join("Returning", 7007)
task.wait(0.2)
check("rejoining straight away pays nothing extra", state(returning).cash == expectAway, state(returning).cash)
Engine.leave(returning)

section("Robux shop")
Engine.passes["8008:111"] = true
local vip = Engine.join("Vip", 8008)
task.wait(0.2)
check("an owned Double Cash pass doubles income", state(vip).income == 2 and state(vip).passes.DoubleCash == true, state(vip).income)
Engine.leave(vip)
local MarketplaceService = game:GetService("MarketplaceService")
Engine.signal(MarketplaceService, "PromptGamePassPurchaseFinished"):Fire(stranger, 222, true)
check("Auto Till works the moment it is bought", state(stranger).autoCollect == true)
Engine.advance(3)
check("the till empties itself", state(stranger).till == 0)
local strangerCash = state(stranger).cash
local decision = MarketplaceService.ProcessReceipt({ ProductId = 333, PlayerId = 2002, PurchaseId = "r1" })
local packAmount = Economy.cashPack(state(stranger).income, Config.Products.CashSmall.seconds, Config.Products.CashSmall.minimum)
check("a cash pack is granted", decision == Enum.ProductPurchaseDecision.PurchaseGranted, decision)
check("a cash pack pays", state(stranger).cash == strangerCash + packAmount, state(stranger).cash - strangerCash)
check("a cash pack saves straight away", Engine.store.data.player_2002 and table.find(Engine.store.data.player_2002.receipts, "r1") ~= nil)
decision = MarketplaceService.ProcessReceipt({ ProductId = 333, PlayerId = 2002, PurchaseId = "r1" })
check("the same receipt never pays twice", decision == Enum.ProductPurchaseDecision.PurchaseGranted and state(stranger).cash == strangerCash + packAmount)
check("an unknown product waits", MarketplaceService.ProcessReceipt({ ProductId = 999, PlayerId = 2002, PurchaseId = "r2" }) == Enum.ProductPurchaseDecision.NotProcessedYet)
check("a player who left waits", MarketplaceService.ProcessReceipt({ ProductId = 333, PlayerId = 424242, PurchaseId = "r3" }) == Enum.ProductPurchaseDecision.NotProcessedYet)
Engine.store.failSaves = true -- three tries with waits, about 6 seconds
local cashBeforeFail = state(stranger).cash
decision = MarketplaceService.ProcessReceipt({ ProductId = 444, PlayerId = 2002, PurchaseId = "r4" })
Engine.store.failSaves = false
check("when saving fails, the pack is taken back for a retry", decision == Enum.ProductPurchaseDecision.NotProcessedYet and state(stranger).cash == cashBeforeFail, state(stranger).cash - cashBeforeFail)
decision = MarketplaceService.ProcessReceipt({ ProductId = 444, PlayerId = 2002, PurchaseId = "r4" })
check("the retry pays once saving works", decision == Enum.ProductPurchaseDecision.PurchaseGranted and state(stranger).cash > cashBeforeFail)

section("When loading a save fails")
Engine.store.failLoads.player_3003 = true
Engine.store.data.player_3003 = { version = 1, cash = 999999, branches = 4, owned = { "kopi_stall", "table_1" }, lastAngpow = 5 }
local unlucky = Engine.join("Unlucky", 3003) -- three tries with waits, about 6 seconds
Engine.spawnCharacter(unlucky)
task.wait(0.2)
check("still gets a kopitiam", tycoonFolder(unlucky) ~= nil)
check("is told it will not save", (Engine.last(unlucky, "Notify") or ""):find("will not be saved") ~= nil, Engine.last(unlucky, "Notify"))
Engine.leave(unlucky)
check("their real save is not overwritten", Engine.store.data.player_3003.cash == 999999 and Engine.store.data.player_3003.branches == 4)

section("Full server")
local extras = {}
for i = 1, Config.PlotCount do
	extras[i] = Engine.join("Guest" .. i, 5000 + i)
end
local kicked = 0
for _, guest in extras do
	if Engine.kicked[guest] then
		kicked += 1
	end
end
-- Joey and Stranger hold two plots, so of six more guests, two cannot fit.
check("guests beyond six plots are turned away", kicked == 2, kicked)

section("Server shutdown")
local setsBefore = Engine.store.sets
for _, closer in Engine.closers do
	closer()
end
check("shutdown saves everyone", Engine.store.sets - setsBefore >= 5, Engine.store.sets - setsBefore)

-- ── 8. The player's screen ───────────────────────────────────────────────────────────────────────
section("Screen")
Engine.setClient(joey)
Engine.run(game:GetService("StarterPlayer").StarterPlayerScripts.Client)
local hud = joey.PlayerGui:FindFirstChild("KopitiamHud")
check("screen is built", hud ~= nil)
local function labelWith(textPart)
	for _, d in hud:GetDescendants() do
		if (d.ClassName == "TextLabel" or d.ClassName == "TextButton") and d.Text:find(textPart, 1, true) then
			return d
		end
	end
	return nil
end
Engine.advance(1)
Engine.signal(game:GetService("RunService"), "RenderStepped"):Fire(5)
check("shows cash", labelWith(Format.money(state(joey).cash)) ~= nil, Format.money(state(joey).cash))
check("shows income", labelWith("a second") ~= nil)
check("shows the till", labelWith("Till: ") ~= nil)
Engine.signal(prompt, "Triggered"):Fire(joey)
check("shows what Ah Ma says", labelWith("Ah Ma: ") ~= nil and labelWith("Ah Ma: ").Visible)
local branchButton = labelWith("Open a new branch")
check("branch button hidden until earned", branchButton ~= nil and branchButton.Visible == false)
local shopButton = labelWith("Shop")
check("shop button shows when the shop has items", shopButton ~= nil and shopButton.Visible)
Engine.signal(shopButton, "Activated"):Fire()
check("shop opens", hud.Shop.Visible)
local buyButtons = {}
for _, d in hud.Shop:GetDescendants() do
	if d.ClassName == "TextButton" and (d.Text == "Buy" or d.Text == "Owned") then
		table.insert(buyButtons, d)
	end
end
check("four things for sale", #buyButtons == 4, #buyButtons)
Engine.signal(buyButtons[1], "Activated"):Fire()
check("Buy opens the Roblox purchase", #Engine.prompts == 1 and Engine.prompts[1].kind == "pass" and Engine.prompts[1].id == 111)
Engine.signal(labelWith("X"), "Activated"):Fire()
check("shop closes", not hud.Shop.Visible)
local playedBefore = #Engine.played
touch(joey, folder.CollectPad, joeyRoot)
check("collecting plays a sound", Engine.played[#Engine.played] == "Collect" and #Engine.played == playedBefore + 1)
playToFranchise(joey, joeyRoot)
check("branch button shows when earned", branchButton.Visible == true)
Engine.signal(branchButton, "Activated"):Fire()
check("asks before opening", labelWith("Open branch 3?") ~= nil, (labelWith("Open branch") or {}).Text)
task.wait(1.1) -- the server ignores branch requests less than a second apart
Engine.signal(labelWith("Open it"), "Activated"):Fire()
check("pressing yes opens the branch", state(joey).branches == 2 and state(joey).multiplier == 2, state(joey).branches)

section("Warnings from the game")
for _, warning in Engine.warnings do
	print("  warn: " .. warning)
end
check("only the expected warnings", #Engine.warnings == 6, #Engine.warnings) -- three failed load tries, three failed save tries

end

local ok, problem = xpcall(main, function(message)
	return tostring(message) .. "\n" .. debug.traceback()
end)
if not ok then
	failed += 1
	print("\nCRASH: " .. tostring(problem))
end
print(string.format("\n%d passed, %d failed", passed, failed))
process.exit(failed == 0 and 0 or 1)
