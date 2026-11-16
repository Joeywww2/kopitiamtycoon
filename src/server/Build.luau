-- Small helpers for building things out of plain parts, so the map needs no imported models.
local Build = {}

Build.Colors = {
	Wood = Color3.fromRGB(133, 94, 66),
	DarkWood = Color3.fromRGB(92, 64, 45),
	Marble = Color3.fromRGB(236, 233, 226),
	Cream = Color3.fromRGB(240, 230, 206),
	Tile = Color3.fromRGB(226, 216, 190),
	Green = Color3.fromRGB(46, 125, 87),
	DarkGreen = Color3.fromRGB(30, 84, 60),
	Red = Color3.fromRGB(196, 58, 49),
	Steel = Color3.fromRGB(176, 182, 188),
	Dark = Color3.fromRGB(45, 45, 48),
	Gold = Color3.fromRGB(232, 188, 70),
	Skin = Color3.fromRGB(245, 205, 48), -- the classic blocky yellow, for every character
	Grass = Color3.fromRGB(96, 150, 84),
	Stone = Color3.fromRGB(150, 150, 146),
	White = Color3.fromRGB(250, 250, 250),
	Orange = Color3.fromRGB(240, 140, 40),
	Pandan = Color3.fromRGB(120, 180, 90),
	Volt = Color3.fromRGB(210, 255, 0),
}

-- One anchored part. `props` needs Size and CFrame; everything else is optional.
function Build.part(parent, props)
	local part = Instance.new("Part")
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Material = props.Material or Enum.Material.SmoothPlastic
	part.Color = props.Color or Build.Colors.Cream
	part.Size = props.Size
	part.CFrame = props.CFrame
	if props.Shape then
		part.Shape = props.Shape
	end
	if props.Transparency then
		part.Transparency = props.Transparency
	end
	if props.CanCollide ~= nil then
		part.CanCollide = props.CanCollide
	end
	part.Name = props.Name or "Part"
	part.Parent = parent
	return part
end

-- An upright cylinder: `height` tall and `diameter` wide, centred on `cframe`.
function Build.cylinder(parent, cframe, height, diameter, color, material)
	return Build.part(parent, {
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(height, diameter, diameter),
		CFrame = cframe * CFrame.Angles(0, 0, math.rad(90)),
		Color = color,
		Material = material,
	})
end

function Build.ball(parent, cframe, diameter, color, material)
	return Build.part(parent, {
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(diameter, diameter, diameter),
		CFrame = cframe,
		Color = color,
		Material = material,
	})
end

-- Text that floats above a part and always faces the camera.
function Build.floatingText(part, text, options)
	options = options or {}
	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Size = UDim2.fromScale(options.width or 9, options.height or 2.4)
	gui.StudsOffset = Vector3.new(0, options.lift or 3, 0)
	gui.AlwaysOnTop = options.onTop or false
	gui.MaxDistance = options.distance or 90
	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = options.color or Build.Colors.White
	label.TextStrokeTransparency = 0.4
	label.Text = text
	label.Parent = gui
	gui.Parent = part
	return label
end

-- Text painted on one face of a part, like a signboard.
function Build.sign(part, text, face, textColor)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Sign"
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = textColor or Build.Colors.White
	label.Text = text
	label.Parent = gui
	gui.Parent = part
	return label
end

-- A blocky person standing at `cframe` (feet on the floor), facing its +Z.
function Build.person(parent, cframe, options)
	options = options or {}
	local C = Build.Colors
	local model = Instance.new("Model")
	model.Name = options.name or "Person"
	local shirt = options.shirt or C.Green
	local pants = options.pants or C.Dark
	Build.part(model, { Size = Vector3.new(0.9, 2, 1), CFrame = cframe * CFrame.new(-0.5, 1, 0), Color = pants })
	Build.part(model, { Size = Vector3.new(0.9, 2, 1), CFrame = cframe * CFrame.new(0.5, 1, 0), Color = pants })
	local torso = Build.part(model, { Name = "Torso", Size = Vector3.new(2, 2, 1), CFrame = cframe * CFrame.new(0, 3, 0), Color = shirt })
	Build.part(model, { Size = Vector3.new(0.9, 2, 0.9), CFrame = cframe * CFrame.new(-1.45, 3, 0), Color = shirt })
	Build.part(model, { Size = Vector3.new(0.9, 2, 0.9), CFrame = cframe * CFrame.new(1.45, 3, 0), Color = shirt })
	Build.part(model, { Name = "Head", Size = Vector3.new(1.3, 1.3, 1.3), CFrame = cframe * CFrame.new(0, 4.65, 0), Color = C.Skin })
	if options.hair then
		Build.part(model, { Size = Vector3.new(1.4, 0.5, 1.4), CFrame = cframe * CFrame.new(0, 5.4, 0), Color = options.hair })
	end
	if options.bun then
		Build.ball(model, cframe * CFrame.new(0, 5.6, -0.6), 0.8, options.hair or C.Steel)
	end
	model.PrimaryPart = torso
	model.Parent = parent
	return model, torso
end

return Build
