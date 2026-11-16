-- One player's kopitiam: what they own, their cash, the till, the buy pads and the models on their plot.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared:WaitForChild("Catalog"))
local Config = require(Shared:WaitForChild("Config"))
local Economy = require(Shared:WaitForChild("Economy"))
local Format = require(Shared:WaitForChild("Format"))

local Build = require(script.Parent.Build)
local Models = require(script.Parent.Models)
local World = require(script.Parent.World)

local C = Build.Colors
local V = Vector3.new
local PAD_CAN_BUY = Color3.fromRGB(80, 200, 110)
local PAD_TOO_DEAR = Color3.fromRGB(200, 80, 70)

local Tycoon = {}
Tycoon.__index = Tycoon

function Tycoon.new(player, plot, data, remotes)
	local self = setmetatable({}, Tycoon)
	self.player = player
	self.plot = plot
	self.remotes = remotes
	self.floor = plot.cframe * CFrame.new(0, World.FLOOR, 0)
	self.cash = data.cash
	self.branches = data.branches
	self.lastAngpow = data.lastAngpow
	self.till = 0
	self.owned = {}
	for _, id in data.owned do
		self.owned[id] = true
	end
	self.canSave = true
	self.pads = {} -- item id -> the pad part
	self.models = {} -- item id -> the built model
	self.connections = {}
	self.lastTouch = {} -- item id -> when its pad was last stepped on
	self.lastComplaint = 0
	self.sinceState = 0
	self.alive = true
	return self
end

function Tycoon:notify(text)
	self.remotes.Notify:FireClient(self.player, text)
end

function Tycoon:income()
	return Economy.incomePerSecond(self.owned, self.branches)
end

-- True when `hit` is part of this kopitiam owner's own character.
function Tycoon:isOwner(hit)
	local character = self.player.Character
	return character ~= nil and hit:IsDescendantOf(character)
end

function Tycoon:start()
	local folder = Instance.new("Folder")
	folder.Name = "Tycoon_" .. self.player.Name
	self.folder = folder

	-- The owner's name on a signpost beside the entrance, clear of the path.
	local front = Config.PlotSize / 2 + 2
	for _, x in { -25, -13 } do
		Build.part(folder, { Size = V(0.6, 5, 0.6), CFrame = self.floor * CFrame.new(x, 2.5, front), Color = C.DarkWood, Material = Enum.Material.Wood })
	end
	local nameBoard = Build.part(folder, { Name = "NameBoard", Size = V(14, 3, 0.5), CFrame = self.floor * CFrame.new(-19, 6, front), Color = C.DarkGreen })
	Build.sign(nameBoard, self.player.DisplayName .. "'s Kopitiam", Enum.NormalId.Back, C.Gold)

	-- The till: a counter with a cash register, and a glowing pad in front that collects the money.
	local tillSpot = self.floor * CFrame.new(0, 0, 22)
	Build.part(folder, { Size = V(6, 3.4, 3), CFrame = tillSpot * CFrame.new(0, 1.7, 0), Color = C.Wood, Material = Enum.Material.Wood })
	local register = Build.part(folder, { Name = "Register", Size = V(2.4, 1.6, 2), CFrame = tillSpot * CFrame.new(0, 4.2, 0), Color = C.Dark })
	self.tillLabel = Build.floatingText(register, "Till: RM 0", { lift = 2.6, width = 10, height = 2, color = C.Gold, distance = 120 })
	local collect = Build.part(folder, { Name = "CollectPad", Size = V(7, 0.3, 4), CFrame = tillSpot * CFrame.new(0, 0.15, 4.5), Color = C.Volt, Material = Enum.Material.Neon })
	Build.floatingText(collect, "COLLECT", { lift = 1.6, width = 6, height = 1.2, color = C.White })
	table.insert(self.connections, collect.Touched:Connect(function(hit)
		if self:isOwner(hit) then
			self:collect(false)
		end
	end))

	local items = Instance.new("Folder")
	items.Name = "Items"
	items.Parent = folder
	self.itemsFolder = items
	local pads = Instance.new("Folder")
	pads.Name = "Pads"
	pads.Parent = folder
	self.padsFolder = pads

	for id in self.owned do
		self:buildItem(id)
	end
	self:refreshPads()

	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local ringgit = Instance.new("IntValue")
	ringgit.Name = "Ringgit"
	ringgit.Parent = stats
	local branches = Instance.new("IntValue")
	branches.Name = "Branches"
	branches.Parent = stats
	stats.Parent = self.player
	self.stats = { ringgit = ringgit, branches = branches }

	folder.Parent = self.plot.folder
	self:pushState()
end

function Tycoon:buildItem(id)
	local item = Catalog.byId[id]
	if item and not self.models[id] then
		self.models[id] = Models.build(item, self.itemsFolder, self.floor, self.player.DisplayName)
	end
end

-- Shows a buy pad for everything the player can work toward next, and removes pads for things they own.
function Tycoon:refreshPads()
	local wanted = {}
	for _, item in Economy.availableItems(self.owned) do
		wanted[item.id] = item
	end
	for id, pad in self.pads do
		if not wanted[id] then
			pad:Destroy()
			self.pads[id] = nil
		end
	end
	for id, item in wanted do
		if not self.pads[id] then
			local x = item.padX or item.x
			local z = item.padZ or (item.z + 7)
			local pad = Build.part(self.padsFolder, {
				Name = "Buy_" .. id,
				Size = V(4.5, 0.4, 4.5),
				CFrame = self.floor * CFrame.new(x, 0.2, z),
				Color = PAD_TOO_DEAR,
				Material = Enum.Material.Neon,
			})
			local price = item.price > 0 and Format.money(item.price) or "FREE"
			Build.floatingText(pad, item.name .. "\n" .. price, { lift = 3, width = 11, height = 3 })
			pad.Touched:Connect(function(hit)
				if self.alive and self:isOwner(hit) then
					self:onPadTouched(id)
				end
			end)
			self.pads[id] = pad
		end
	end
	self:paintPads()
end

function Tycoon:paintPads()
	for id, pad in self.pads do
		local item = Catalog.byId[id]
		pad.Color = (item and self.cash >= item.price) and PAD_CAN_BUY or PAD_TOO_DEAR
	end
end

function Tycoon:onPadTouched(id)
	local now = os.clock()
	if now - (self.lastTouch[id] or 0) < 0.4 then
		return
	end
	self.lastTouch[id] = now
	self:buy(id)
end

-- Tries to buy one item. Returns true when it was bought.
function Tycoon:buy(id)
	local ok, reason = Economy.canBuy(id, self.owned, self.cash)
	if not ok then
		local now = os.clock()
		if reason and now - self.lastComplaint > 2 then -- do not spam while they stand on the pad
			self.lastComplaint = now
			local item = Catalog.byId[id]
			if item and self.cash < item.price then
				reason = "You need " .. Format.money(item.price - self.cash) .. " more for the " .. item.name .. "."
			end
			self:notify(reason)
		end
		return false
	end
	local item = Catalog.byId[id]
	self.cash -= item.price
	self.owned[id] = true
	self:buildItem(id)
	self:refreshPads()
	if item.autoCollect then
		self:notify("Ah Boy starts today. He empties the till for you.")
	elseif item.unlocksBranch then
		self:notify("Franchise Licence! You can open a new branch now.")
	else
		self:notify(item.name .. " bought. +" .. Format.money(item.income * Economy.multiplier(self.branches)) .. " a second.")
	end
	self:pushState()
	return true
end

-- Moves the till's money into cash.
function Tycoon:collect(quiet)
	local amount = math.floor(self.till)
	if amount < 1 then
		return 0
	end
	self.till -= amount
	self.cash += amount
	if not quiet then
		self:notify("Collected " .. Format.money(amount) .. ".")
	end
	self:paintPads()
	self:pushState()
	return amount
end

-- Called a few times a second by the server.
function Tycoon:step(dt)
	local income = self:income()
	local capacity = Economy.tillCapacity(income)
	self.till = math.min(capacity, self.till + income * dt)
	if Economy.autoCollects(self.owned) and self.till >= 1 then
		local amount = math.floor(self.till)
		self.till -= amount
		self.cash += amount
	end
	self.sinceState += dt
	if self.sinceState >= 0.5 then
		self.sinceState = 0
		self:paintPads()
		self:pushState()
	end
end

-- Franchise time: start again from one stall, with every ringgit worth more.
function Tycoon:openBranch()
	if not Economy.canOpenBranch(self.owned) then
		self:notify("Buy the Franchise Licence first.")
		return false
	end
	self.branches += 1
	self.cash = 0
	self.till = 0
	self.owned = { [Catalog.starter] = true }
	for id, model in self.models do
		model:Destroy()
		self.models[id] = nil
	end
	for id, pad in self.pads do
		pad:Destroy()
		self.pads[id] = nil
	end
	self:buildItem(Catalog.starter)
	self:refreshPads()
	self:notify("Branch " .. (self.branches + 1) .. " is open! Everything now earns x" .. string.format("%.1f", Economy.multiplier(self.branches)) .. ".")
	self:pushState()
	return true
end

-- Ah Ma's angpow. Returns the amount given, or nil and the seconds left to wait.
function Tycoon:claimAngpow(now)
	local wait = Config.AngpowHours * 3600 - (now - self.lastAngpow)
	if wait > 0 then
		return nil, wait
	end
	local amount = Economy.angpow(self:income())
	self.lastAngpow = now
	self.cash += amount
	self:paintPads()
	self:pushState()
	return amount, 0
end

function Tycoon:pushState()
	local income = self:income()
	if self.tillLabel then
		self.tillLabel.Text = "Till: " .. Format.money(self.till)
	end
	if self.stats then
		self.stats.ringgit.Value = math.floor(self.cash)
		self.stats.branches.Value = self.branches + 1
	end
	self.remotes.State:FireClient(self.player, {
		cash = math.floor(self.cash),
		income = income,
		till = math.floor(self.till),
		tillMax = Economy.tillCapacity(income),
		branches = self.branches,
		multiplier = Economy.multiplier(self.branches),
		canOpenBranch = Economy.canOpenBranch(self.owned),
		autoCollect = Economy.autoCollects(self.owned),
	})
end

-- What gets saved. Money still in the till is kept too.
function Tycoon:snapshot()
	local owned = {}
	for _, item in Catalog.items do -- catalog order, so saves are stable
		if self.owned[item.id] then
			table.insert(owned, item.id)
		end
	end
	return {
		version = 1,
		cash = math.floor(self.cash + self.till),
		branches = self.branches,
		owned = owned,
		lastAngpow = self.lastAngpow,
	}
end

function Tycoon:destroy()
	self.alive = false
	for _, connection in self.connections do
		connection:Disconnect()
	end
	if self.folder then
		self.folder:Destroy()
	end
end

-- Where the owner stands when they arrive: just inside the entrance, facing in.
function Tycoon:spawnCFrame()
	return self.floor * CFrame.new(10, 4, 27)
end

return Tycoon
