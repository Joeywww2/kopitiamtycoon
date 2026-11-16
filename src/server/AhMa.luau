-- Ah Ma sits in the plaza. Talk to her for a tip, and once a day for an angpow.
local Build = require(script.Parent.Build)

local C = Build.Colors
local V = Vector3.new

local TIPS = {
	"Aiyo, your till is full again. Go and collect lah.",
	"Money in your pocket earns nothing. Buy the next upgrade.",
	"When Ah Boy starts work, you never walk to the till again.",
	"Green pad means you can afford it. Red pad means work harder.",
	"A Franchise Licence lets you open a new branch. Every branch makes every ringgit worth more.",
	"Ah Ma started with one kopi stall also. Slowly, slowly.",
	"Ah Ma is 80 and Ah Ma has helpers. What about you?",
	"Come back tomorrow. Ah Ma got angpow for you.",
}

local AhMa = {}

-- Builds her at the middle of the plaza. `onTalk(player)` must return what she says.
function AhMa.build(parent, onTalk)
	local folder = Instance.new("Folder")
	folder.Name = "AhMa"
	local spot = CFrame.new(0, 0.3, 0)

	-- Her kopitiam table and umbrella.
	Build.cylinder(folder, spot * CFrame.new(4, 3, 0), 0.35, 5, C.Marble, Enum.Material.Marble)
	Build.cylinder(folder, spot * CFrame.new(4, 1.45, 0), 2.9, 0.7, C.DarkWood, Enum.Material.Wood)
	Build.cylinder(folder, spot * CFrame.new(4, 7, 0), 9, 0.4, C.Dark)
	Build.cylinder(folder, spot * CFrame.new(4, 11.4, 0), 0.5, 13, C.Red)
	Build.cylinder(folder, spot * CFrame.new(4.8, 3.5, 0.4), 0.6, 0.6, C.White) -- her kopi
	Build.cylinder(folder, spot * CFrame.new(7.4, 1, 0), 2, 1.6, C.Wood, Enum.Material.Wood) -- a stool for visitors

	local _, torso = Build.person(folder, spot * CFrame.new(0, 0.6, 0.2), {
		name = "Ah Ma",
		shirt = Color3.fromRGB(226, 120, 150), -- floral pink blouse
		pants = Color3.fromRGB(70, 70, 90),
		hair = Color3.fromRGB(200, 200, 205),
		bun = true,
	})
	Build.part(folder, { Size = V(1.05, 0.25, 1.05), CFrame = spot * CFrame.new(1.45, 2.4, 0.2), Color = Color3.fromRGB(60, 170, 110) }) -- jade bangle
	Build.floatingText(torso, "Ah Ma", { lift = 3.6, width = 6, height = 1.5, color = C.Gold, distance = 140 })

	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = "Ah Ma"
	prompt.ActionText = "Talk"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = torso
	prompt.Triggered:Connect(onTalk)

	folder.Parent = parent
	return folder
end

function AhMa.tip(random)
	return TIPS[random:NextInteger(1, #TIPS)]
end

AhMa.tips = TIPS

return AhMa
