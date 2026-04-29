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
main.BackgroundColor3 = Color3.fromRGB(25,25,25)
main.Parent = gui
Instance.new("UICorner", main)

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
side.Size = UDim2.new(0,100,1,0)
side.BackgroundColor3 = Color3.fromRGB(35,35,35)
side.Parent = main

local content = Instance.new("Frame")
content.Size = UDim2.new(1,-100,1,0)
content.Position = UDim2.new(0,100,0,0)
content.BackgroundTransparency = 1
content.Parent = main

------------------------------------------------
-- TABS
------------------------------------------------
local function tab(name, y)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1,0,0,50)
	b.Position = UDim2.new(0,0,0,y)
	b.Text = name
	b.BackgroundColor3 = Color3.fromRGB(50,50,50)
	b.TextColor3 = Color3.new(1,1,1)
	b.Parent = side
	return b
end

local casual = Instance.new("Frame", content)
casual.Size = UDim2.new(1,0,1,0)
casual.Visible = true
casual.BackgroundTransparency = 1

local tp = Instance.new("Frame", content)
tp.Size = UDim2.new(1,0,1,0)
tp.Visible = false
tp.BackgroundTransparency = 1

local esp = Instance.new("Frame", content)
esp.Size = UDim2.new(1,0,1,0)
esp.Visible = false
esp.BackgroundTransparency = 1

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

------------------------------------------------
-- BUTTON CREATOR
------------------------------------------------
local OFF_COLOR = Color3.fromRGB(60,60,60)
local ON_COLOR = Color3.fromRGB(0,170,0)

local function btn(text, y, parent, func, stateVar)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1,-20,0,35)
	b.Position = UDim2.new(0,10,0,y)
	b.Text = text
	b.TextColor3 = Color3.new(1,1,1)
	b.BackgroundColor3 = OFF_COLOR
	b.Parent = parent

	b.MouseButton1Click:Connect(function()
		func()
		if stateVar then
			b.BackgroundColor3 = stateVar and ON_COLOR or OFF_COLOR
		end
	end)
	return b
end

------------------------------------------------
-- CASUAL SLOTS
------------------------------------------------
local flyBtn = btn("Fly",10,casual,Features.Fly,function() return flying end)
local noclipBtn = btn("Noclip",50,casual,Features.Noclip,function() return noclipEnabled end)
local invisBtn = btn("Invisibility",90,casual,Features.Invis,function() return invisible end)

------------------------------------------------
-- TELEPORT
------------------------------------------------
btn("Set A",10,tp,Features.SetA)
btn("Set B",50,tp,Features.SetB)
btn("Teleport A",90,tp,Features.TeleportA)
btn("Teleport B",130,tp,Features.TeleportB)

------------------------------------------------
-- MINIMIZE HOOK
------------------------------------------------
local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0,30,0,30)
minBtn.Position = UDim2.new(1,-35,0,5)
minBtn.Text = "-"
minBtn.TextColor3 = Color3.new(1,1,1)
minBtn.BackgroundColor3 = Color3.fromRGB(200,0,0)
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

	-- FLY LOGIC
	if flying and bodyVel and bodyGyro then
		local cam = workspace.CurrentCamera
		local move = humanoid.MoveDirection

		local target = (cam.CFrame.LookVector * move.Z + cam.CFrame.RightVector * move.X) * speed
		if upHeld then target += Vector3.new(0,speed,0) end
		if downHeld then target -= Vector3.new(0,speed,0) end

		currentVel = currentVel:Lerp(target, 0.2)
		bodyVel.Velocity = currentVel
		bodyGyro.CFrame = cam.CFrame
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
end)
