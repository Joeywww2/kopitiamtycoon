--!strict
-- What gets saved for each player, and a cleaner that makes any loaded value safe to use.
local Catalog = require(script.Parent.Catalog)
local Config = require(script.Parent.Config)

export type Data = {
	version: number,
	cash: number,
	branches: number,
	owned: { string },
	lastAngpow: number,
}

local SaveData = {}

function SaveData.default(): Data
	return { version = 1, cash = Config.StartCash, branches = 0, owned = { Catalog.starter }, lastAngpow = 0 }
end

local function number(value: any, fallback: number): number
	if type(value) ~= "number" or value ~= value or value < 0 or value == math.huge then
		return fallback
	end
	return value
end

-- Never trust what comes back from storage: wrong types, unknown items and duplicates are dropped.
function SaveData.clean(raw: any): Data
	local data = SaveData.default()
	if type(raw) ~= "table" then
		return data
	end
	data.cash = math.floor(number(raw.cash, data.cash))
	data.branches = math.floor(number(raw.branches, 0))
	data.lastAngpow = math.floor(number(raw.lastAngpow, 0))
	local seen: { [string]: boolean } = { [Catalog.starter] = true }
	local owned = { Catalog.starter }
	if type(raw.owned) == "table" then
		for _, id in raw.owned do
			if type(id) == "string" and Catalog.byId[id] and not seen[id] then
				seen[id] = true
				table.insert(owned, id)
			end
		end
	end
	data.owned = owned
	return data
end

return SaveData
