--// SERVICES
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character, humanoid, rootPart

--// CHARACTER SETUP
local function setupCharacter(char)
	character = char
	humanoid = char:WaitForChild("Humanoid")
	rootPart = char:WaitForChild("HumanoidRootPart")
end

setupCharacter(player.Character or player.CharacterAdded:Wait())
player.CharacterAdded:Connect(setupCharacter)

--// STATES
local flying = false
local speed = 60
local minSpeed, maxSpeed = 10, 200

local noclipEnabled = false
local invisible = false

local checkpointA, checkpointB = nil, nil
local teleportMode = false

local espEnabled = false
local espColor = Color3.new(0,1,0)
local espObjects = {}

local upHeld, downHeld = false, false
local bodyVel, bodyGyro

--// INPUT
UIS.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.Space then upHeld = true end
	if input.KeyCode == Enum.KeyCode.LeftControl then downHeld = true end
end)

UIS.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.Space then upHeld = false end
	if input.KeyCode == Enum.KeyCode.LeftControl then downHeld = false end
end)

--// GUI
local gui = Instance.new("ScreenGui", player.PlayerGui)
gui.Name = "SC Hub v2"
gui.ResetOnSpawn = false

local main = Instance.new("Frame", gui)
main.Size = UDim2.new(0,280,0,480)
main.Position = UDim2.new(0.5,-140,0.5,-240)
main.BorderSizePixel = 0
Instance.new("UICorner", main).CornerRadius = UDim.new(0,12)

local gradient = Instance.new("UIGradient", main)
gradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(0,120,60)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(120,0,120))
}

-- TOP BAR
local top = Instance.new("Frame", main)
top.Size = UDim2.new(1,0,0,40)
top.BackgroundTransparency = 1

-- DRAG FIXED
local dragging, dragStart, startPos

top.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = i.Position
		startPos = main.Position
	end
end)

UIS.InputChanged:Connect(function(i)
	if dragging then
		local delta = i.Position - dragStart
		main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

UIS.InputEnded:Connect(function()
	dragging = false
end)

-- MINIMIZE FIXED
local minimized = false
local minBtn = Instance.new("TextButton", top)
minBtn.Size = UDim2.new(0,30,0,30)
minBtn.Position = UDim2.new(1,-35,0,5)
minBtn.Text = "-"
minBtn.BackgroundColor3 = Color3.fromRGB(200,0,0)

local content = Instance.new("Frame", main)
content.Size = UDim2.new(1,-20,1,-60)
content.Position = UDim2.new(0,10,0,50)
content.BackgroundTransparency = 1

minBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	content.Visible = not minimized
	main.Size = minimized and UDim2.new(0,280,0,40) or UDim2.new(0,280,0,480)
end)

-- BUTTON HELPER
local function btn(text, y, parent)
	local b = Instance.new("TextButton", parent)
	b.Size = UDim2.new(1,0,0,35)
	b.Position = UDim2.new(0,0,0,y)
	b.Text = text
	b.BackgroundColor3 = Color3.fromRGB(50,50,50)
	return b
end

-- CASUAL TAB (simplified for clarity)
local flyBtn = btn("Fly",10,content)
local noclipBtn = btn("Noclip",50,content)
local invisBtn = btn("Invisibility",90,content)

--// FLY
local function startFly()
	humanoid.PlatformStand = true
	bodyVel = Instance.new("BodyVelocity", rootPart)
	bodyVel.MaxForce = Vector3.new(1e6,1e6,1e6)

	bodyGyro = Instance.new("BodyGyro", rootPart)
	bodyGyro.MaxTorque = Vector3.new(1e6,1e6,1e6)
end

local function stopFly()
	humanoid.PlatformStand = false
	if bodyVel then bodyVel:Destroy() end
	if bodyGyro then bodyGyro:Destroy() end
end

flyBtn.MouseButton1Click:Connect(function()
	flying = not flying
	flyBtn.BackgroundColor3 = flying and Color3.fromRGB(0,170,0) or Color3.fromRGB(50,50,50)
	if flying then startFly() else stopFly() end
end)

-- NOCLIP
noclipBtn.MouseButton1Click:Connect(function()
	noclipEnabled = not noclipEnabled
	noclipBtn.BackgroundColor3 = noclipEnabled and Color3.fromRGB(0,170,0) or Color3.fromRGB(50,50,50)
end)

-- INVIS
invisBtn.MouseButton1Click:Connect(function()
	invisible = not invisible
	invisBtn.BackgroundColor3 = invisible and Color3.fromRGB(0,170,0) or Color3.fromRGB(50,50,50)
end)

--// MAIN LOOP (FIXES EVERYTHING)
RunService.RenderStepped:Connect(function()
	if not character or not rootPart then return end

	-- FLY (SMOOTH + NO BLOCK BUG)
	if flying and bodyVel then
		local cam = workspace.CurrentCamera
		local move = humanoid.MoveDirection

		local vel = (cam.CFrame.LookVector * move.Z + cam.CFrame.RightVector * move.X) * speed

		if upHeld then vel += Vector3.new(0,speed,0) end
		if downHeld then vel -= Vector3.new(0,speed,0) end

		bodyVel.Velocity = vel
		bodyGyro.CFrame = cam.CFrame
	end

	-- NOCLIP
	if noclipEnabled then
		for _,v in pairs(character:GetDescendants()) do
			if v:IsA("BasePart") then v.CanCollide = false end
		end
	end

	-- INVISIBILITY
	for _,v in pairs(character:GetDescendants()) do
		if v:IsA("BasePart") or v:IsA("Decal") then
			v.Transparency = invisible and 1 or 0
		end
	end
end)

--// ESP
local function createESP(plr)
	if plr == player then return end
	local h = Instance.new("Highlight")
	h.FillTransparency = 0.5
	h.Parent = workspace
	espObjects[plr] = h
end

local function clearESP()
	for _,v in pairs(espObjects) do v:Destroy() end
	espObjects = {}
end

local espBtn = btn("ESP",140,content)

espBtn.MouseButton1Click:Connect(function()
	espEnabled = not espEnabled
	espBtn.BackgroundColor3 = espEnabled and Color3.fromRGB(0,170,0) or Color3.fromRGB(50,50,50)

	if espEnabled then
		for _,p in pairs(Players:GetPlayers()) do createESP(p) end
	else
		clearESP()
	end
end)

Players.PlayerAdded:Connect(function(p)
	if espEnabled then createESP(p) end
end)

Players.PlayerRemoving:Connect(function(p)
	if espObjects[p] then espObjects[p]:Destroy() end
end)

RunService.RenderStepped:Connect(function()
	if not espEnabled then return end
	for plr,obj in pairs(espObjects) do
		if plr.Character then
			obj.Adornee = plr.Character
			obj.FillColor = espColor
			obj.OutlineColor = espColor
		end
	end
end)
