-- SERVICES
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

------------------------------------------------
-- CHARACTER
------------------------------------------------
local character, humanoid, rootPart

local function setupCharacter(char)
	character = char
	humanoid = char:WaitForChild("Humanoid")
	rootPart = char:WaitForChild("HumanoidRootPart")
end

setupCharacter(player.Character or player.CharacterAdded:Wait())
player.CharacterAdded:Connect(setupCharacter)

------------------------------------------------
-- STATES
------------------------------------------------
local flying = false
local speed = 60

local noclipEnabled = false
local invisible = false

local checkpointA, checkpointB = nil, nil
local teleportMode = false

local upHeld = false
local downHeld = false

local bodyVel, bodyGyro

------------------------------------------------
-- INPUT (PC + controller + mobile jump support)
------------------------------------------------
UIS.InputBegan:Connect(function(input, gp)
	if gp then return end

	if input.KeyCode == Enum.KeyCode.Space then
		upHeld = true
	elseif input.KeyCode == Enum.KeyCode.LeftControl then
		downHeld = true
	end
end)

UIS.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.Space then
		upHeld = false
	elseif input.KeyCode == Enum.KeyCode.LeftControl then
		downHeld = false
	end
end)

------------------------------------------------
-- UI
------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "SC Hub"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0,240,0,360)
frame.Position = UDim2.new(0.5,-120,0.5,-180)
frame.Parent = gui
frame.ClipsDescendants = true

Instance.new("UICorner", frame).CornerRadius = UDim.new(0,12)

local gradient = Instance.new("UIGradient", frame)
gradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(0,120,60)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(40,60,120)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(120,0,120))
}
gradient.Rotation = 45

------------------------------------------------
-- TOP BAR
------------------------------------------------
local topBar = Instance.new("Frame", frame)
topBar.Size = UDim2.new(1,0,0,30)
topBar.BackgroundTransparency = 1

local title = Instance.new("TextLabel", topBar)
title.Size = UDim2.new(1,0,1,0)
title.BackgroundTransparency = 1
title.Text = "SC Hub"
title.TextColor3 = Color3.new(1,1,1)
title.TextScaled = true

------------------------------------------------
-- AVATAR MINIMIZE BUTTON
------------------------------------------------
local avatarBtn = Instance.new("ImageButton", topBar)
avatarBtn.Size = UDim2.new(0,26,0,26)
avatarBtn.Position = UDim2.new(1,-30,0,2)
avatarBtn.BackgroundColor3 = Color3.fromRGB(200,0,0)
Instance.new("UICorner", avatarBtn).CornerRadius = UDim.new(1,0)

task.spawn(function()
	local img = Players:GetUserThumbnailAsync(
		player.UserId,
		Enum.ThumbnailType.HeadShot,
		Enum.ThumbnailSize.Size48x48
	)
	avatarBtn.Image = img
end)

------------------------------------------------
-- BUTTON SYSTEM
------------------------------------------------
local buttons = {}

local function makeButton(text, y)
	local b = Instance.new("TextButton", frame)
	b.Size = UDim2.new(0,220,0,30)
	b.Position = UDim2.new(0,10,0,y)
	b.Text = text
	b.BackgroundColor3 = Color3.fromRGB(50,50,50)
	b.TextColor3 = Color3.new(1,1,1)
	Instance.new("UICorner", b).CornerRadius = UDim.new(0,8)

	table.insert(buttons, b)
	return b
end

local flyBtn = makeButton("Fly", 40)
local noclipBtn = makeButton("Noclip", 75)
local invisBtn = makeButton("Invisibility", 110)
local setABtn = makeButton("Set A", 145)
local setBBtn = makeButton("Set B", 180)
local tpModeBtn = makeButton("Teleport Mode", 215)
local tpABtn = makeButton("Teleport A", 250)
local tpBBtn = makeButton("Teleport B", 285)

------------------------------------------------
-- MINIMIZE (FIXED - no square bug)
------------------------------------------------
local minimized = false

local function setMin(state)
	minimized = state

	for _, v in pairs(buttons) do
		v.Visible = not state
	end

	frame.Size = state and UDim2.new(0,240,0,30) or UDim2.new(0,240,0,360)
end

avatarBtn.MouseButton1Click:Connect(function()
	setMin(not minimized)
end)

------------------------------------------------
-- DRAG SYSTEM (FIXED MOBILE + PC)
------------------------------------------------
local dragging = false
local dragStart
local startPos

topBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
	or input.UserInputType == Enum.UserInputType.Touch then

		dragging = true
		dragStart = input.Position
		startPos = frame.Position
	end
end)

UIS.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
	or input.UserInputType == Enum.UserInputType.Touch) then

		local delta = input.Position - dragStart
		frame.Position = UDim2.new(
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
-- FLIGHT SYSTEM (CLEAN + MOBILE FIXED)
------------------------------------------------
local function startFly()
	flying = true

	bodyVel = Instance.new("BodyVelocity")
	bodyVel.MaxForce = Vector3.new(1e6,1e6,1e6)
	bodyVel.Parent = rootPart

	bodyGyro = Instance.new("BodyGyro")
	bodyGyro.MaxTorque = Vector3.new(1e6,1e6,1e6)
	bodyGyro.Parent = rootPart

	humanoid:ChangeState(Enum.HumanoidStateType.Physics)
end

local function stopFly()
	flying = false
	if bodyVel then bodyVel:Destroy() end
	if bodyGyro then bodyGyro:Destroy() end
	humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
end

flyBtn.MouseButton1Click:Connect(function()
	if flying then stopFly() else startFly() end
end)

------------------------------------------------
-- CHECKPOINTS
------------------------------------------------
setABtn.MouseButton1Click:Connect(function()
	if rootPart then checkpointA = rootPart.CFrame end
end)

setBBtn.MouseButton1Click:Connect(function()
	if rootPart then checkpointB = rootPart.CFrame end
end)

tpModeBtn.MouseButton1Click:Connect(function()
	teleportMode = not teleportMode
end)

tpABtn.MouseButton1Click:Connect(function()
	if teleportMode and checkpointA then
		rootPart.CFrame = checkpointA + Vector3.new(0,3,0)
	end
end)

tpBBtn.MouseButton1Click:Connect(function()
	if teleportMode and checkpointB then
		rootPart.CFrame = checkpointB + Vector3.new(0,3,0)
	end
end)

------------------------------------------------
-- LOOP (MOBILE + PC FIXED FLY)
------------------------------------------------
RunService.Heartbeat:Connect(function()
	if flying and bodyVel and bodyGyro and rootPart then
		local cam = workspace.CurrentCamera
		local move = humanoid.MoveDirection

		local dir =
			(cam.CFrame.RightVector * move.X) +
			(cam.CFrame.LookVector * move.Z)

		if upHeld then dir += Vector3.new(0,1,0) end
		if downHeld then dir += Vector3.new(0,-1,0) end

		local target = Vector3.zero
		if dir.Magnitude > 0 then
			target = dir.Unit * speed
		end

		bodyVel.Velocity = bodyVel.Velocity:Lerp(target, 0.2)
		bodyGyro.CFrame = cam.CFrame
	end

	-- noclip
	if character then
		for _, p in pairs(character:GetDescendants()) do
			if p:IsA("BasePart") then
				p.CanCollide = not noclipEnabled
			end
		end
	end

	-- invis
	if character then
		for _, o in pairs(character:GetDescendants()) do
			if o:IsA("BasePart") or o:IsA("Decal") then
				o.Transparency = invisible and 1 or 0
			end
		end
	end
end)
