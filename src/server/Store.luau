-- Loading and saving each player's kopitiam.
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local SaveData = require(Shared:WaitForChild("SaveData"))

local Store = {}

local store = nil
do
	-- In Studio this fails until "Enable Studio Access to API Services" is switched on. The game still runs.
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(Config.DataStoreName)
	end)
	if ok then
		store = result
	else
		warn("Saving is off: " .. tostring(result))
	end
end

local function key(userId)
	return "player_" .. tostring(userId)
end

-- Returns the player's data and whether storage answered. If it did not answer, the caller must not save
-- later, or a new empty kopitiam would overwrite the real one.
function Store.load(userId)
	if not store then
		return SaveData.default(), false
	end
	for attempt = 1, 3 do
		local ok, result = pcall(function()
			return store:GetAsync(key(userId))
		end)
		if ok then
			return SaveData.clean(result), true
		end
		warn("Load failed for " .. tostring(userId) .. " (try " .. attempt .. "): " .. tostring(result))
		task.wait(attempt)
	end
	return SaveData.default(), false
end

function Store.save(userId, data)
	if not store then
		return false
	end
	for attempt = 1, 3 do
		local ok, result = pcall(function()
			store:SetAsync(key(userId), data)
		end)
		if ok then
			return true
		end
		warn("Save failed for " .. tostring(userId) .. " (try " .. attempt .. "): " .. tostring(result))
		task.wait(attempt)
	end
	return false
end

return Store
