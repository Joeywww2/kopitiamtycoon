-- A stand-in for the Roblox engine, so the real game scripts can run outside Roblox Studio.
-- It loads the built place file with Lune's Roblox library (which knows every real class and property,
-- so a misspelt property still fails) and adds the pieces Lune leaves out: events, a few methods,
-- a fake data store and a way to run each Script with the globals Roblox would give it.
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local task = require("@lune/task")

local Engine = {}

-- ── Events ───────────────────────────────────────────────────────────────────────────────────────
local function newSignal()
	local signal = { handlers = {} }
	function signal:Connect(fn)
		local connection = { Connected = true }
		local entry = { fn = fn, connection = connection }
		table.insert(signal.handlers, entry)
		function connection:Disconnect()
			connection.Connected = false
			local at = table.find(signal.handlers, entry)
			if at then
				table.remove(signal.handlers, at)
			end
		end
		return connection
	end
	function signal:Fire(...)
		for _, entry in table.clone(signal.handlers) do
			if entry.connection.Connected then
				entry.fn(...) -- called directly, so an error in a handler fails the test
			end
		end
	end
	return signal
end

-- Kept for the whole run on purpose: a weak table here loses every connection when memory is cleaned up.
local signals = {} -- instance -> { eventName -> signal }
local function signalOf(instance, name)
	local mine = signals[instance]
	if not mine then
		mine = {}
		signals[instance] = mine
	end
	if not mine[name] then
		mine[name] = newSignal()
	end
	return mine[name]
end
Engine.signal = signalOf

local EVENTS = {
	BasePart = { "Touched" },
	Players = { "PlayerAdded", "PlayerRemoving" },
	Player = { "CharacterAdded" },
	RunService = { "Heartbeat", "RenderStepped" },
	RemoteEvent = { "OnServerEvent", "OnClientEvent" },
	ProximityPrompt = { "Triggered" },
	GuiButton = { "Activated" },
	MarketplaceService = { "PromptGamePassPurchaseFinished" },
}
for className, names in EVENTS do
	for _, name in names do
		roblox.implementProperty(className, name, function(instance)
			return signalOf(instance, name)
		end)
	end
end

-- ── Methods Lune leaves out ──────────────────────────────────────────────────────────────────────
roblox.implementMethod("Instance", "WaitForChild", function(self, name)
	local child = self:FindFirstChild(name)
	if not child then
		error("WaitForChild(" .. tostring(name) .. ") on " .. self:GetFullName() .. " would wait forever", 2)
	end
	return child
end)

local pivots = {}
roblox.implementMethod("Model", "PivotTo", function(self, cframe)
	assert(typeof(cframe) == "CFrame", "PivotTo needs a CFrame")
	pivots[self] = cframe
end)
roblox.implementMethod("Model", "GetPivot", function(self)
	return pivots[self] or (self.PrimaryPart and self.PrimaryPart.CFrame) or roblox.CFrame.new()
end)

Engine.sent = {} -- every FireClient call: { remote = name, player = Player, args = {...} }
Engine.kicked = {} -- player -> message
Engine.closers = {} -- functions given to game:BindToClose
Engine.client = nil -- the Player whose screen script is running, if any

roblox.implementMethod("RemoteEvent", "FireClient", function(self, player, ...)
	assert(typeof(player) == "Instance" and player.ClassName == "Player", "FireClient needs a Player first")
	table.insert(Engine.sent, { remote = self.Name, player = player, args = { ... } })
	if Engine.client == player then
		signalOf(self, "OnClientEvent"):Fire(...)
	end
end)
roblox.implementMethod("RemoteEvent", "FireServer", function(self, ...)
	assert(Engine.client, "FireServer was called with no client running")
	signalOf(self, "OnServerEvent"):Fire(Engine.client, ...)
end)
roblox.implementMethod("Player", "Kick", function(self, message)
	Engine.kicked[self] = message or ""
end)
roblox.implementMethod("Players", "GetPlayers", function(self)
	local list = {}
	for _, child in self:GetChildren() do
		if child.ClassName == "Player" then
			table.insert(list, child)
		end
	end
	return list
end)
roblox.implementMethod("DataModel", "BindToClose", function(_, fn)
	table.insert(Engine.closers, fn)
end)
roblox.implementMethod("TweenService", "Create", function(_, instance, _info, goals)
	return {
		Play = function()
			for property in goals do
				local _ = instance[property] -- reading it proves the property exists
			end
		end,
	}
end)

-- The Robux shop. `Engine.passes["userId:passId"] = true` means that player owns that pass.
Engine.passes = {}
Engine.prompts = {} -- every purchase prompt a screen opened: { kind = "pass" | "product", id = number }
local receiptCallback = nil
roblox.implementProperty("MarketplaceService", "ProcessReceipt", function()
	return receiptCallback
end, function(_, fn)
	receiptCallback = fn
end)
roblox.implementMethod("MarketplaceService", "UserOwnsGamePassAsync", function(_, userId, passId)
	assert(type(userId) == "number" and type(passId) == "number", "UserOwnsGamePassAsync(userId, passId)")
	return Engine.passes[userId .. ":" .. passId] == true
end)
roblox.implementMethod("MarketplaceService", "PromptGamePassPurchase", function(_, player, id)
	assert(typeof(player) == "Instance" and player.ClassName == "Player" and type(id) == "number", "PromptGamePassPurchase(player, id)")
	table.insert(Engine.prompts, { kind = "pass", id = id })
end)
roblox.implementMethod("MarketplaceService", "PromptProductPurchase", function(_, player, id)
	assert(typeof(player) == "Instance" and player.ClassName == "Player" and type(id) == "number", "PromptProductPurchase(player, id)")
	table.insert(Engine.prompts, { kind = "product", id = id })
end)
roblox.implementMethod("Players", "GetPlayerByUserId", function(self, userId)
	for _, child in self:GetChildren() do
		if child.ClassName == "Player" and child.UserId == userId then
			return child
		end
	end
	return nil
end)
Engine.played = {} -- the name of every Sound played
roblox.implementMethod("Sound", "Play", function(self)
	assert(self.SoundId ~= "", "a Sound with no SoundId")
	table.insert(Engine.played, self.Name)
end)

-- A data store kept in memory. `failLoads[key] = true` makes that key's GetAsync throw.
Engine.store = { data = {}, failLoads = {}, failSaves = false, sets = 0 }
local fakeStore = {}
function fakeStore:GetAsync(key)
	if Engine.store.failLoads[key] then
		error("502: API Services rejected request")
	end
	return Engine.store.data[key]
end
function fakeStore:SetAsync(key, value)
	assert(type(value) == "table", "SetAsync value")
	if Engine.store.failSaves then
		error("502: API Services rejected request")
	end
	Engine.store.sets += 1
	Engine.store.data[key] = table.clone(value)
end
roblox.implementMethod("DataStoreService", "GetDataStore", function(_, name)
	assert(type(name) == "string" and #name > 0 and #name <= 50, "data store name")
	return fakeStore
end)

-- ── Loading the place and running its scripts ────────────────────────────────────────────────────
function Engine.load(placePath)
	local game = roblox.deserializePlace(fs.readFile(placePath))
	Engine.game = game
	local workspace = game:GetService("Workspace")

	roblox.implementMethod("CollectionService", "GetTagged", function(_, tag)
		local found = {}
		for _, instance in workspace:GetDescendants() do
			if instance:HasTag(tag) then
				table.insert(found, instance)
			end
		end
		return found
	end)

	local seed = 1
	local base = {
		game = game,
		workspace = workspace,
		Instance = roblox.Instance,
		Vector3 = roblox.Vector3,
		Vector2 = roblox.Vector2,
		CFrame = roblox.CFrame,
		Color3 = roblox.Color3,
		UDim = roblox.UDim,
		UDim2 = roblox.UDim2,
		Enum = roblox.Enum,
		task = task,
		warn = function(...)
			table.insert(Engine.warnings, table.concat({ ... }, " "))
		end,
		Random = {
			new = function()
				return {
					NextInteger = function(_, low, high)
						seed = (seed * 1103515245 + 12345) % 2147483648
						return low + seed % (high - low + 1)
					end,
				}
			end,
		},
		TweenInfo = {
			new = function(...)
				return { ... }
			end,
		},
	}
	Engine.warnings = {}

	local loaded = {} -- ModuleScript -> what it returned
	local function run(scriptInstance)
		local env = table.clone(base)
		env.script = scriptInstance
		env.require = function(target)
			assert(typeof(target) == "Instance" and target.ClassName == "ModuleScript", "require needs a ModuleScript, got " .. tostring(target))
			if loaded[target] == nil then
				loaded[target] = run(target)
			end
			return loaded[target]
		end
		local fn = luau.load(scriptInstance.Source, { debugName = scriptInstance:GetFullName(), environment = env })
		return fn()
	end
	Engine.run = run
	Engine.require = function(moduleScript)
		if loaded[moduleScript] == nil then
			loaded[moduleScript] = run(moduleScript)
		end
		return loaded[moduleScript]
	end
	return game
end

-- ── Fake players ─────────────────────────────────────────────────────────────────────────────────
function Engine.join(name, userId)
	local players = Engine.game:GetService("Players")
	local player = roblox.Instance.new("Player")
	player.Name = name
	player.DisplayName = name
	player.UserId = userId
	local gui = roblox.Instance.new("PlayerGui")
	gui.Parent = player
	player.Parent = players
	signalOf(players, "PlayerAdded"):Fire(player)
	return player
end

function Engine.spawnCharacter(player)
	local character = roblox.Instance.new("Model")
	character.Name = player.Name
	local root = roblox.Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Parent = character
	character.PrimaryPart = root
	character.Parent = Engine.game:GetService("Workspace")
	player.Character = character
	signalOf(player, "CharacterAdded"):Fire(character)
	return character, root
end

function Engine.leave(player)
	local players = Engine.game:GetService("Players")
	signalOf(players, "PlayerRemoving"):Fire(player)
	if player.Character then
		player.Character:Destroy()
	end
	player.Parent = nil
end

-- Makes `player` the one whose screen script runs (Players.LocalPlayer).
function Engine.setClient(player)
	Engine.client = player
	Engine.game:GetService("Players").LocalPlayer = player
end

-- Lets `seconds` of game time pass, in steps, by firing Heartbeat.
function Engine.advance(seconds, stepSize)
	local heartbeat = signalOf(Engine.game:GetService("RunService"), "Heartbeat")
	local step = stepSize or 0.25
	local left = seconds
	while left > 1e-9 do
		local dt = math.min(step, left)
		heartbeat:Fire(dt)
		left -= dt
	end
end

-- The messages one player was sent on one remote, oldest first.
function Engine.messages(player, remoteName)
	local list = {}
	for _, entry in Engine.sent do
		if entry.player == player and entry.remote == remoteName then
			table.insert(list, entry.args[1])
		end
	end
	return list
end

function Engine.last(player, remoteName)
	local list = Engine.messages(player, remoteName)
	return list[#list]
end

return Engine
