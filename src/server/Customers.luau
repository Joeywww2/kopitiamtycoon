-- Customers who walk into one player's kopitiam, stop at something the player owns, say a word, pay at the
-- till and leave. They are only for looks: income does not depend on them. Each moves every server frame.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared:WaitForChild("Catalog"))
local Config = require(Shared:WaitForChild("Config"))

local Build = require(script.Parent.Build)

local C = Build.Colors
local SHIRTS = {
	C.Red, C.Green, C.White, Color3.fromRGB(70, 110, 190), Color3.fromRGB(240, 200, 60), Color3.fromRGB(150, 90, 160),
	Color3.fromRGB(230, 120, 150), C.Orange,
}
local HAIR = { C.Dark, Color3.fromRGB(60, 40, 30), C.Steel }
local LINES = {
	"Kopi O kosong satu!", "Teh tarik kurang manis, boss.", "Sedap!", "Boss, tapau ah.", "Roti bakar extra kaya!",
	"Wah, so cold the aircon!", "Same as usual.", "Can add egg ah?", "Milo ais, thanks.", "Fuyoh!", "Aiyo, so long the queue.",
	"Two half-boiled, one kopi.",
}
local SPOT_KINDS = { -- where a customer can stop: in front of these, never on walls, fans or the ceiling
	stall = true, table = true, toaster = true, eggs = true, tehtarik = true, wok = true, shelf = true, grill = true,
	cart = true, griddle = true, durian = true, tent = true,
}

local Customers = {}
Customers.__index = Customers
Customers.LINES = LINES

-- `floor` is the plot's CFrame at floor height; `ownedFn` returns the owner's { [id] = true }.
function Customers.new(parent, floor, ownedFn, random)
	local self = setmetatable({}, Customers)
	local folder = Instance.new("Folder")
	folder.Name = "Customers"
	folder.Parent = parent
	self.folder = folder
	self.floor = floor
	self.ownedFn = ownedFn
	self.random = random
	self.list = {}
	self.sinceSpawn = Config.CustomerEverySeconds -- the first one walks in straight away
	self.count = 0 -- customers ever served, also used to name them
	return self
end

-- How many can be inside at once: more as the shop grows.
function Customers:limit()
	local owned = 0
	for _ in self.ownedFn() do
		owned += 1
	end
	return math.min(Config.CustomerMax, 1 + math.floor(owned / 3))
end

-- Somewhere to stand: just in front of a random thing the player owns that serves food or seats people.
function Customers:pickSpot()
	local spots = {}
	for id in self.ownedFn() do
		local item = Catalog.byId[id]
		if item and SPOT_KINDS[item.kind] then
			table.insert(spots, item)
		end
	end
	if #spots == 0 then
		return nil
	end
	local item = spots[self.random:NextInteger(1, #spots)]
	local side = item.kind == "table" and (self.random:NextInteger(0, 1) == 0 and -3.6 or 3.6) or 0
	local depth = item.kind == "table" and 0 or 4.5
	return Vector3.new(item.x + side, 0, item.z + depth)
end

function Customers:spawn()
	local spot = self:pickSpot()
	if not spot then
		return
	end
	self.count += 1
	local half = Config.PlotSize / 2
	local door = Vector3.new(self.random:NextInteger(-2, 2), 0, half + 4)
	local till = Vector3.new(self.random:NextInteger(-2, 2), 0, 26.5)
	local model = Build.person(self.folder, self.floor * CFrame.new(door), {
		name = "Customer" .. self.count,
		shirt = SHIRTS[self.random:NextInteger(1, #SHIRTS)],
		hair = HAIR[self.random:NextInteger(1, #HAIR)],
	})
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.CanTouch = false -- never set off a buy pad
		end
	end
	table.insert(self.list, {
		model = model,
		at = door,
		-- walk in, stop and order, pay at the till, walk out
		route = { { to = spot, wait = self.random:NextInteger(4, 8), say = true }, { to = till, wait = 1 }, { to = door } },
		leg = 1,
		waited = 0,
		bob = 0,
	})
end

function Customers:say(model, line)
	local head = model:FindFirstChild("Head")
	if head then
		local label = Build.floatingText(head, line, { lift = 2.2, width = 8, height = 1.4, distance = 60 })
		task.delay(2.5, function()
			if label.Parent then
				label.Parent:Destroy()
			end
		end)
	end
end

-- Moves everyone along. Called every server frame.
function Customers:step(dt)
	self.sinceSpawn += dt
	if self.sinceSpawn >= Config.CustomerEverySeconds and #self.list < self:limit() then
		self.sinceSpawn = 0
		self:spawn()
	end
	for i = #self.list, 1, -1 do
		local c = self.list[i]
		local leg = c.route[c.leg]
		local gap = leg.to - c.at
		local distance = gap.Magnitude
		if distance > 0.05 then
			local move = math.min(distance, Config.CustomerWalkSpeed * dt)
			c.at += gap.Unit * move
			c.bob += dt * 12
			local facing = CFrame.new(c.at, c.at + gap.Unit)
			-- A model's pivot is its torso (the PrimaryPart), which sits 3 studs above the feet.
			c.model:PivotTo(self.floor * facing * CFrame.new(0, 3 + math.abs(math.sin(c.bob)) * 0.25, 0))
		else
			if c.waited == 0 and leg.say then
				self:say(c.model, LINES[self.random:NextInteger(1, #LINES)])
			end
			c.waited += dt
			if c.waited >= (leg.wait or 0) then
				c.waited = 0
				c.leg += 1
				if c.leg > #c.route then
					c.model:Destroy()
					table.remove(self.list, i)
				end
			end
		end
	end
end

function Customers:clear()
	for _, c in self.list do
		c.model:Destroy()
	end
	table.clear(self.list)
end

function Customers:destroy()
	self:clear()
	self.folder:Destroy()
end

return Customers
