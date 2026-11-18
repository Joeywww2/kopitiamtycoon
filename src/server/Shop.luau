-- The Robux shop: game passes (bought once) and cash packs (bought again and again).
-- IDs live in Config. Anything at 0 is switched off, so nothing here runs until Joey makes them in the Creator Hub.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local Shop = {}

-- Game pass ID -> its name in Config.GamePasses
local function passNames()
	local byId = {}
	for name, id in Config.GamePasses do
		if id ~= 0 then
			byId[id] = name
		end
	end
	return byId
end

-- Product ID -> its pack in Config.Products
local function packs()
	local byId = {}
	for _, pack in Config.Products do
		if pack.id ~= 0 then
			byId[pack.id] = pack
		end
	end
	return byId
end

-- `tycoonOf(player)` returns that player's Tycoon or nil. `save(player)` saves and returns true when it worked.
function Shop.start(tycoonOf, save)
	local passes = passNames()
	local products = packs()

	-- Check which passes a player already owns, once their kopitiam is ready.
	function Shop.checkPasses(player)
		for id, name in passes do
			task.spawn(function()
				local ok, owns = pcall(function()
					return MarketplaceService:UserOwnsGamePassAsync(player.UserId, id)
				end)
				local tycoon = tycoonOf(player)
				if ok and owns and tycoon then
					tycoon:grantPass(name)
				end
			end)
		end
	end

	-- A pass bought during play works straight away.
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, id, bought)
		local name = passes[id]
		local tycoon = tycoonOf(player)
		if bought and name and tycoon then
			tycoon:grantPass(name)
		end
	end)

	-- Roblox calls this for every cash pack, and again later if we do not say it was granted.
	MarketplaceService.ProcessReceipt = function(receipt)
		local pack = products[receipt.ProductId]
		local player = Players:GetPlayerByUserId(receipt.PlayerId)
		local tycoon = player and tycoonOf(player)
		if not pack or not tycoon or not tycoon.canSave then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		local receiptId = tostring(receipt.PurchaseId)
		if tycoon:hasReceipt(receiptId) then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
		local amount = tycoon:grantCashPack(receiptId, pack)
		if save(player) then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
		tycoon:undoCashPack(receiptId, amount)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
end

return Shop
