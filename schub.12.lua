--// SERVICES
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

------------------------------------------------
-- GUI
------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "SC Hub"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 340, 0, 420)
main.Position = UDim2.new(0.5, -170, 0.5, -210)
main.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Parent = gui
Instance.new("UICorner", main)

-- GRADIENT BACKGROUND (MATCHING YOUR IMAGE)
local gradient = Instance.new("UIGradient", main)
gradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 120, 60)),   -- Bright Green
	ColorSequenceKeypoint.new(1, Color3.fromRGB(140, 0, 140))  -- Bright Purple
})
gradient.Rotation = 90
gradient.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0),
	NumberSequenceKeypoint.new(1, 0)
})

-- SC HUB BRANDING
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0,40)
title.Position = UDim2.new(0,0,0,0)
title.BackgroundTransparency = 1
title.Text = "SC Hub"
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.GothamBold
title.TextSize = 24
title.Parent = main

------------------------------------------------
-- DRAG
------------------------------------------------
local dragging, dragStart, startPos

main.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = i.Position
		startPos = main.Position
	end
end)

UIS.InputChanged:Connect(function(i)
	if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
		local delta = i.Position - dragStart
		main.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end
end)

UIS.InputEnded:Connect(function()
	dragging = false
end)

------------------------------------------------
-- MINIMIZE
------------------------------------------------
local minimized = false

local circle = Instance.new("ImageButton")
circle.Size = UDim2.new(0,60,0,60)
circle.Position = UDim2.new(0,20,0.5,-30)
circle.BackgroundColor3 = Color3.fromRGB(40,40,40)
circle.Visible = false
circle.BorderSizePixel = 0
circle.Parent = gui
Instance.new("UICorner", circle).CornerRadius = UDim.new(1,0)

circle.Image = "rbxthumb://type=AvatarHeadShot&id="..player.UserId.."&w=420&h=420"

local function setMin(state)
	minimized = state
	main.Visible = not state
	circle.Visible = state
end

------------------------------------------------
-- SIDE UI
------------------------------------------------
local side = Instance.new("Frame")
side.Size = UDim2.new(0,100,1,-40)
side.Position = UDim2.new(0,0,0,40)
side.BackgroundColor3 = Color3.fromRGB(0,0,0,0.2)
side.BorderSizePixel = 0
side.Parent = main

local content = Instance.new("Frame")
content.Size = UDim2.new(1,-100,1,-40)
content.Position = UDim2.new(0,100,0,40)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.Parent = main

------------------------------------------------
-- TABS
------------------------------------------------
local function tab(name, y)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1,0,0,50)
	b.Position = UDim2.new(0,0,0,y)
	b.Text = name
	b.TextColor3 = Color3.new(1,1,1)
	b.BackgroundColor3 = Color3.fromRGB(0,0,0,0.3)
	b.BorderSizePixel = 0
	b.Parent = side
	return b
end

local casual = Instance.new("Frame", content)
casual.Size = UDim2.new(1,0,1,0)
casual.Visible = true
casual.BackgroundTransparency = 1
casual.BorderSizePixel = 0

local tp = Instance.new("Frame", content)
tp.Size = UDim2.new(1,0,1,0)
tp.Visible = false
tp.BackgroundTransparency = 1
tp.BorderSizePixel = 0

local esp = Instance.new("Frame", content)
esp.Size = UDim2.new(1,0,1,0)
esp.Visible = false
esp.BackgroundTransparency = 1
esp.BorderSizePixel = 0

local tabs = {
	tab("Casual",0),
	tab("Teleport",50),
	tab("ESP",100)
}

local function switch(f)
	casual.Visible = false
	tp.Visible = false
	esp.Visible = false
	f.Visible = true
end

tabs[1].MouseButton1Click:Connect(function() switch(casual) end)
tabs[2].MouseButton1Click:Connect(function() switch(tp) end)
tabs[3].MouseButton1Click:Connect(function() switch(esp) end)

------------------------------------------------
-- VARIABLES
------------------------------------------------
local character, humanoid, rootPart
local flying = false
local noclipEnabled = false
local invisible = false
local speed = 60
local checkpointA, checkpointB = nil, nil
local bodyVel, bodyGyro
local upHeld, downHeld = false, false
local currentVel = Vector3.zero

-- ESP VARS
local espEnabled = false
local espColor = Color3.fromRGB(0, 255, 100)
local espObjects = {}

local function getCharacter()
	character = player.Character or player.CharacterAdded:Wait()
	humanoid = character:WaitForChild("Humanoid")
	rootPart = character:WaitForChild("HumanoidRootPart")
end
getCharacter()
player.CharacterAdded:Connect(getCharacter)

-- Input Keys
UIS.InputBegan:Connect(function(i, gp)
	if gp then return end
	if i.KeyCode == Enum.KeyCode.Space then upHeld = true end
	if i.KeyCode == Enum.KeyCode.LeftControl then downHeld = true end
end)
UIS.InputEnded:Connect(function(i)
	if i.KeyCode == Enum.KeyCode.Space then upHeld = false end
	if i.KeyCode == Enum.KeyCode.LeftControl then downHeld = false end
end)

------------------------------------------------
-- FEATURE SYSTEM
------------------------------------------------
local Features = {}

function Features.Fly()
	flying = not flying
	if flying then
		bodyVel = Instance.new("BodyVelocity")
		bodyVel.MaxForce = Vector3.new(1e6,1e6,1e6)
		bodyVel.Parent = rootPart

		bodyGyro = Instance.new("BodyGyro")
		bodyGyro.MaxTorque = Vector3.new(1e6,1e6,1e6)
		bodyGyro.Parent = rootPart
	else
		if bodyVel then bodyVel:Destroy() end
		if bodyGyro then bodyGyro:Destroy() end
	end
end

function Features.Noclip()
	noclipEnabled = not noclipEnabled
end

function Features.Invis()
	invisible = not invisible
end

function Features.SetA()
	checkpointA = rootPart.CFrame
end

function Features.SetB()
	checkpointB = rootPart.CFrame
end

function Features.TeleportA()
	if checkpointA then rootPart.CFrame = checkpointA + Vector3.new(0,3,0) end
end

function Features.TeleportB()
	if checkpointB then rootPart.CFrame = checkpointB + Vector3.new(0,3,0) end
end

function Features.ToggleESP()
	espEnabled = not espEnabled
	if espEnabled then
		for _, plr in pairs(Players:GetPlayers()) do
			if plr ~= player then
				local hl = Instance.new("Highlight", workspace)
				hl.FillTransparency = 0.5
				hl.OutlineTransparency = 0
				espObjects[plr] = hl
			end
		end
	else
		for _, obj in pairs(espObjects) do
			obj:Destroy()
		end
		espObjects = {}
	end
end

------------------------------------------------
-- BUTTON CREATOR
------------------------------------------------
local OFF_COLOR = Color3.fromRGB(0,0,0,0.4)
local ON_COLOR = Color3.fromRGB(0,170,0)

local function btn(text, y, parent, func)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1,-20,0,35)
	b.Position = UDim2.new(0,10,0,y)
	b.Text = text
	b.TextColor3 = Color3.new(1,1,1)
	b.BackgroundColor3 = OFF_COLOR
	b.BorderSizePixel = 0
	b.Parent = parent

	b.MouseButton1Click:Connect(func)
	return b
end

------------------------------------------------
-- CASUAL SLOTS
------------------------------------------------
local flyBtn = btn("Fly",10,casual,Features.Fly)
local noclipBtn = btn("Noclip",50,casual,Features.Noclip)
local invisBtn = btn("Invisibility",90,casual,Features.Invis)

------------------------------------------------
-- TELEPORT
------------------------------------------------
btn("Set A",10,tp,Features.SetA)
btn("Set B",50,tp,Features.SetB)
btn("Teleport A",90,tp,Features.TeleportA)
btn("Teleport B",130,tp,Features.TeleportB)

------------------------------------------------
-- ESP TAB
------------------------------------------------
local espBtn = btn("Toggle ESP",10,esp,Features.ToggleESP)

-- BIG SLIDER (FIXED INTERFERENCE)
local slider = Instance.new("Frame")
slider.Size = UDim2.new(1,-20,0,30)
slider.Position = UDim2.new(0,10,0,60)
slider.BackgroundColor3 = Color3.fromRGB(255,255,255)
slider.BorderSizePixel = 0
slider.Parent = esp

local knob = Instance.new("Frame")
knob.Size = UDim2.new(0,30,1,0)
knob.BackgroundColor3 = Color3.fromRGB(0,170,255)
knob.BorderSizePixel = 0
knob.Parent = slider

local draggingSlider = false

-- FIX: Only drag slider if clicking knob
knob.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
		draggingSlider = true
	end
end)

UIS.InputEnded:Connect(function()
	draggingSlider = false
end)

UIS.InputChanged:Connect(function(i)
	if draggingSlider then
		local sizeX = slider.AbsoluteSize.X
		if sizeX <= 0 then return end
		
		local x = math.clamp(i.Position.X - slider.AbsolutePosition.X, 0, sizeX)
		local p = x / sizeX
		
		knob.Position = UDim2.new(p, 0, 0, 0)
		espColor = Color3.fromHSV(p, 1, 1)
	end
end)

------------------------------------------------
-- MINIMIZE HOOK
------------------------------------------------
local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0,30,0,30)
minBtn.Position = UDim2.new(1,-35,0,5)
minBtn.Text = "-"
minBtn.TextColor3 = Color3.new(1,1,1)
minBtn.BackgroundColor3 = Color3.fromRGB(200,0,0)
minBtn.BorderSizePixel = 0
minBtn.Parent = main

minBtn.MouseButton1Click:Connect(function()
	setMin(not minimized)
end)

circle.MouseButton1Click:Connect(function()
	setMin(false)
end)

------------------------------------------------
-- MAIN LOOP
------------------------------------------------
RunService.RenderStepped:Connect(function()
	if not rootPart then return end

	-- FLY LOGIC (ADMIN STYLE FIXED)
	if flying and bodyVel and bodyGyro then
		local camCF = workspace.CurrentCamera.CFrame
		local move = humanoid.MoveDirection
		
		local dir = Vector3.new()
		dir += camCF.LookVector * move.Z
		dir += camCF.RightVector * move.X
		dir = Vector3.new(dir.X, 0, dir.Z).Unit
		
		local vel = dir * speed
		if upHeld then vel += Vector3.new(0,speed,0) end
		if downHeld then vel -= Vector3.new(0,speed,0) end
		
		currentVel = currentVel:Lerp(vel, 0.2)
		bodyVel.Velocity = currentVel
		bodyGyro.CFrame = camCF
	end

	-- NOCLIP
	for _,v in pairs(character:GetDescendants()) do
		if v:IsA("BasePart") then
			v.CanCollide = not noclipEnabled
		end
	end

	-- INVISIBILITY
	for _,v in pairs(character:GetDescendants()) do
		if v:IsA("BasePart") or v:IsA("Decal") then
			v.Transparency = invisible and 1 or 0
		end
	end

	-- BUTTON COLOR UPDATE
	flyBtn.BackgroundColor3 = flying and ON_COLOR or OFF_COLOR
	noclipBtn.BackgroundColor3 = noclipEnabled and ON_COLOR or OFF_COLOR
	invisBtn.BackgroundColor3 = invisible and ON_COLOR or OFF_COLOR
	espBtn.BackgroundColor3 = espEnabled and ON_COLOR or OFF_COLOR

	-- UPDATE ESP COLOR
	if espEnabled then
		for plr, obj in pairs(espObjects) do
			if plr.Character then
				obj.Adornee = plr.Character
				obj.FillColor = espColor
				obj.OutlineColor = espColor
			end
		end
	end
end)

-- PLAYER JOIN/LEAVE FOR ESP
Players.PlayerAdded:Connect(function(plr)
	if espEnabled and plr ~= player then
		local hl = Instance.new("Highlight", workspace)
		hl.FillTransparency = 0.5
		hl.OutlineTransparency = 0
		espObjects[plr] = hl
	end
end)

Players.PlayerRemoving:Connect(function(plr)
	if espObjects[plr] then
		espObjects[plr]:Destroy()
		espObjects[plr] = nil
	end
end)
