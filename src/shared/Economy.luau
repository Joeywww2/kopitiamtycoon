--!strict
-- The money rules. No Roblox calls in here, so it can be tested on its own.
local Catalog = require(script.Parent.Catalog)
local Config = require(script.Parent.Config)

local Economy = {}

export type Owned = { [string]: boolean }

-- Each branch you have opened makes every ringgit worth more.
function Economy.multiplier(branches: number): number
	return 1 + math.max(0, branches) * Config.BranchBonus
end

function Economy.incomePerSecond(owned: Owned, branches: number): number
	local base = 0
	for id in owned do
		local item = Catalog.byId[id]
		if item then
			base += item.income
		end
	end
	return base * Economy.multiplier(branches)
end

function Economy.tillCapacity(incomePerSecond: number): number
	return math.max(Config.TillMinimum, math.floor(incomePerSecond * Config.TillSeconds))
end

function Economy.requirementsMet(item: Catalog.Item, owned: Owned): boolean
	for _, id in item.requires do
		if not owned[id] then
			return false
		end
	end
	return true
end

-- Returns true, or false and a short reason the player can read.
function Economy.canBuy(id: string, owned: Owned, cash: number): (boolean, string?)
	local item = Catalog.byId[id]
	if not item then
		return false, "That is not for sale."
	end
	if owned[id] then
		return false, "You already have that."
	end
	if not Economy.requirementsMet(item, owned) then
		return false, "Buy the earlier upgrades first."
	end
	if cash < item.price then
		return false, "Not enough ringgit yet."
	end
	return true, nil
end

-- The buy pads to show: not owned yet, and everything they need is owned.
function Economy.availableItems(owned: Owned): { Catalog.Item }
	local list = {}
	for _, item in Catalog.items do
		if not owned[item.id] and Economy.requirementsMet(item, owned) then
			table.insert(list, item)
		end
	end
	return list
end

function Economy.autoCollects(owned: Owned): boolean
	for id in owned do
		local item = Catalog.byId[id]
		if item and item.autoCollect then
			return true
		end
	end
	return false
end

function Economy.canOpenBranch(owned: Owned): boolean
	for id in owned do
		local item = Catalog.byId[id]
		if item and item.unlocksBranch then
			return true
		end
	end
	return false
end

function Economy.angpow(incomePerSecond: number): number
	return math.max(Config.AngpowMinimum, math.floor(incomePerSecond * Config.AngpowSeconds))
end

return Economy
