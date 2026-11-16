-- Kopitiam Tycoon: what each player sees on screen. Cash, income, the till, pop-up messages,
-- Ah Ma's speech and the "open a new branch" button. Built in code so it works on phones and computers.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Format = require(Shared:WaitForChild("Format"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local GOLD = Color3.fromRGB(232, 188, 70)
local DARK = Color3.fromRGB(20, 21, 24)
local WHITE = Color3.fromRGB(250, 250, 250)
local GREEN = Color3.fromRGB(46, 125, 87)
local RED = Color3.fromRGB(196, 58, 49)

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
end

local function text(parent, props)
	local label = Instance.new(props.button and "TextButton" or "TextLabel")
	label.BackgroundTransparency = props.background and 0 or 1
	label.BackgroundColor3 = props.background or DARK
	label.BorderSizePixel = 0
	label.Font = props.font or Enum.Font.GothamBold
	label.TextColor3 = props.color or WHITE
	label.TextScaled = true
	label.TextWrapped = true
	label.Text = props.text or ""
	label.Size = props.size
	label.Position = props.position or UDim2.new()
	label.AnchorPoint = props.anchor or Vector2.zero
	if props.maxText then
		local limit = Instance.new("UITextSizeConstraint")
		limit.MaxTextSize = props.maxText
		limit.Parent = label
	end
	label.Parent = parent
	return label
end

local gui = Instance.new("ScreenGui")
gui.Name = "KopitiamHud"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Cash panel, top middle.
local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0)
panel.Position = UDim2.new(0.5, 0, 0, 8)
panel.Size = UDim2.new(0.6, 0, 0.14, 0)
panel.BackgroundColor3 = DARK
panel.BackgroundTransparency = 0.25
panel.BorderSizePixel = 0
local panelLimit = Instance.new("UISizeConstraint")
panelLimit.MaxSize = Vector2.new(380, 96)
panelLimit.MinSize = Vector2.new(200, 64)
panelLimit.Parent = panel
corner(panel, 16)
panel.Parent = gui

local cashLabel = text(panel, { text = "RM 0", color = GOLD, size = UDim2.new(1, -20, 0.5, 0), position = UDim2.new(0, 10, 0.04, 0), maxText = 40 })
local incomeLabel = text(panel, { text = "+RM 0 a second", size = UDim2.new(1, -20, 0.22, 0), position = UDim2.new(0, 10, 0.52, 0), font = Enum.Font.GothamMedium, maxText = 18 })
local tillLabel = text(panel, { text = "Till: RM 0", size = UDim2.new(1, -20, 0.2, 0), position = UDim2.new(0, 10, 0.76, 0), font = Enum.Font.Gotham, maxText = 16 })

-- Pop-up message, lower middle.
local toast = text(gui, {
	background = DARK, size = UDim2.new(0.8, 0, 0.08, 0), position = UDim2.new(0.5, 0, 0.74, 0), anchor = Vector2.new(0.5, 0.5), maxText = 22,
	font = Enum.Font.GothamMedium,
})
toast.Visible = false
corner(toast, 14)
local toastLimit = Instance.new("UISizeConstraint")
toastLimit.MaxSize = Vector2.new(560, 64)
toastLimit.Parent = toast
local toastPad = Instance.new("UIPadding")
toastPad.PaddingLeft = UDim.new(0, 14)
toastPad.PaddingRight = UDim.new(0, 14)
toastPad.Parent = toast

-- Ah Ma's speech, above the pop-up.
local speech = text(gui, {
	background = Color3.fromRGB(250, 244, 230), color = DARK, size = UDim2.new(0.86, 0, 0.12, 0), position = UDim2.new(0.5, 0, 0.58, 0),
	anchor = Vector2.new(0.5, 0.5), maxText = 22, font = Enum.Font.GothamMedium,
})
speech.Visible = false
corner(speech, 16)
local speechLimit = Instance.new("UISizeConstraint")
speechLimit.MaxSize = Vector2.new(620, 96)
speechLimit.Parent = speech
local speechPad = Instance.new("UIPadding")
speechPad.PaddingLeft = UDim.new(0, 16)
speechPad.PaddingRight = UDim.new(0, 16)
speechPad.PaddingTop = UDim.new(0, 8)
speechPad.PaddingBottom = UDim.new(0, 8)
speechPad.Parent = speech

-- "Open a new branch" button, right side, with a confirm box.
local branchButton = text(gui, {
	button = true, background = GOLD, color = DARK, text = "Open a new branch", size = UDim2.new(0.34, 0, 0.08, 0),
	position = UDim2.new(1, -12, 0.5, 0), anchor = Vector2.new(1, 0.5), maxText = 20,
})
branchButton.Visible = false
branchButton.AutoButtonColor = true
corner(branchButton, 14)
local branchLimit = Instance.new("UISizeConstraint")
branchLimit.MaxSize = Vector2.new(230, 60)
branchLimit.MinSize = Vector2.new(140, 48)
branchLimit.Parent = branchButton

local confirm = Instance.new("Frame")
confirm.AnchorPoint = Vector2.new(0.5, 0.5)
confirm.Position = UDim2.new(0.5, 0, 0.45, 0)
confirm.Size = UDim2.new(0.86, 0, 0.36, 0)
confirm.BackgroundColor3 = DARK
confirm.BorderSizePixel = 0
confirm.Visible = false
corner(confirm, 18)
local confirmLimit = Instance.new("UISizeConstraint")
confirmLimit.MaxSize = Vector2.new(440, 250)
confirmLimit.Parent = confirm
confirm.Parent = gui
local confirmText = text(confirm, { size = UDim2.new(1, -32, 0.56, 0), position = UDim2.new(0, 16, 0.06, 0), font = Enum.Font.GothamMedium, maxText = 22 })
local yes = text(confirm, { button = true, background = GREEN, text = "Open it", size = UDim2.new(0.44, 0, 0.24, 0), position = UDim2.new(0.04, 0, 0.7, 0), maxText = 22 })
local no = text(confirm, { button = true, background = RED, text = "Not yet", size = UDim2.new(0.44, 0, 0.24, 0), position = UDim2.new(0.52, 0, 0.7, 0), maxText = 22 })
corner(yes, 12)
corner(no, 12)

gui.Parent = playerGui

-- Show a frame for a few seconds, then hide it. A newer message replaces an older one.
local showCount = {}
local function show(label, message, seconds)
	showCount[label] = (showCount[label] or 0) + 1
	local mine = showCount[label]
	label.Text = message
	label.Visible = true
	task.delay(seconds, function()
		if showCount[label] == mine then
			label.Visible = false
		end
	end)
end

local state = nil
local shownCash = 0

remotes:WaitForChild("State").OnClientEvent:Connect(function(newState)
	state = newState
	incomeLabel.Text = "+" .. Format.money(newState.income) .. " a second"
	if newState.autoCollect then
		tillLabel.Text = "Ah Boy is collecting the till"
	elseif newState.till >= newState.tillMax then
		tillLabel.Text = "Till is FULL: " .. Format.money(newState.till) .. ". Go collect!"
	else
		tillLabel.Text = "Till: " .. Format.money(newState.till) .. " of " .. Format.money(newState.tillMax)
	end
	tillLabel.TextColor3 = (not newState.autoCollect and newState.till >= newState.tillMax) and GOLD or WHITE
	branchButton.Visible = newState.canOpenBranch and not confirm.Visible
end)

remotes:WaitForChild("Notify").OnClientEvent:Connect(function(message)
	show(toast, message, 3.5)
end)

remotes:WaitForChild("AhMa").OnClientEvent:Connect(function(message)
	show(speech, "Ah Ma: " .. message, 6)
end)

branchButton.Activated:Connect(function()
	if not state then
		return
	end
	confirmText.Text = string.format(
		"Open branch %d? You start again from one kopi stall with RM 0, and everything earns x%.1f from now on.",
		state.branches + 2,
		state.multiplier + 0.5
	)
	confirm.Visible = true
	branchButton.Visible = false
end)
yes.Activated:Connect(function()
	confirm.Visible = false
	remotes.OpenBranch:FireServer()
end)
no.Activated:Connect(function()
	confirm.Visible = false
	branchButton.Visible = state ~= nil and state.canOpenBranch
end)

-- Every frame: count the cash up smoothly and spin the ceiling fans.
RunService.RenderStepped:Connect(function(dt)
	if state then
		local gap = state.cash - shownCash
		if math.abs(gap) < 1 then
			shownCash = state.cash
		else
			shownCash += gap * math.min(1, dt * 10)
		end
		cashLabel.Text = Format.money(shownCash)
	end
	for _, blades in CollectionService:GetTagged("Spin") do
		if blades:IsA("Model") and blades.PrimaryPart then
			blades:PivotTo(blades:GetPivot() * CFrame.Angles(0, dt * 6, 0))
		end
	end
end)

-- A small bounce on the cash panel whenever a pop-up says money came in.
local bounce = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true)
remotes.Notify.OnClientEvent:Connect(function(message)
	if string.find(message, "Collected", 1, true) then
		TweenService:Create(cashLabel, bounce, { TextColor3 = WHITE }):Play()
	end
end)
