-- The messages that travel between the server and each player's screen.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NAMES = {
	"State", -- server -> player: cash, income, till and branch numbers for the screen
	"Notify", -- server -> player: a short message that pops up
	"AhMa", -- server -> player: something Ah Ma says
	"OpenBranch", -- player -> server: "open a new branch" was pressed
	"Effect", -- server -> player: play a sound (Buy, Collect, Angpow, Branch)
}

local Remotes = {}

function Remotes.create()
	local folder = Instance.new("Folder")
	folder.Name = "Remotes"
	local map = {}
	for _, name in NAMES do
		local remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = folder
		map[name] = remote
	end
	folder.Parent = ReplicatedStorage
	return map
end

return Remotes
