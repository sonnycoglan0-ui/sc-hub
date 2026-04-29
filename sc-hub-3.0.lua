-- Services
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- Prevent duplicates
if player.PlayerGui:FindFirstChild("SC Hub") then
	player.PlayerGui["SC Hub"]:Destroy()
end

-- Character setup
local character, humanoid, rootPart

local function setupCharacter(char)
	character = char
	humanoid = char:WaitForChild("Humanoid")
	rootPart = char:WaitForChild("HumanoidRootPart")
end

setupCharacter(player.Character or player.CharacterAdded:Wait())
player.CharacterAdded:Connect(setupCharacter)

-- Mobile detect
local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled

-- States
local flying = false
local speed = 50
local noclipEnabled = false
local invisible = false
local upDown = 0

local checkpointA, checkpointB = nil, nil
local teleportMode = false

-- GUI
local screenGui = Instance.new("ScreenGui", player.PlayerGui)
screenGui.Name = "SC Hub"

local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0,220,0,340)
frame.Position = UDim2.new(0.5,-110,0,100)

local frameCorner = Instance.new("UICorner", frame)
frameCorner.CornerRadius = UDim.new(0,12)

local gradient = Instance.new("UIGradient", frame)
gradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(0,120,60)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(40,60,120)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(120,0,120))
}
gradient.Rotation = 45

-- Title
local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,0,0,30)
title.BackgroundTransparency = 1
title.Text = "SC Hub"
title.TextColor3 = Color3.new(1,1,1)
title.TextScaled = true

-- Avatar minimize button
local avatarBtn = Instance.new("ImageButton", frame)
avatarBtn.Size = UDim2.new(0,30,0,30)
avatarBtn.Position = UDim2.new(1,-35,0,5)
avatarBtn.BackgroundColor3 = Color3.fromRGB(200,0,0)

local avatarCorner = Instance.new("UICorner", avatarBtn)
avatarCorner.CornerRadius = UDim.new(1,0)

task.spawn(function()
	local ok, img = pcall(function()
		return Players:GetUserThumbnailAsync(
			player.UserId,
			Enum.ThumbnailType.HeadShot,
			Enum.ThumbnailSize.Size48x48
		)
	end)
	if ok then avatarBtn.Image = img end
end)

-- Button maker
local function makeBtn(text, y)
	local b = Instance.new("TextButton", frame)
	b.Size = UDim2.new(0,200,0,30)
	b.Position = UDim2.new(0,10,0,y)
	b.Text = text
	b.BackgroundColor3 = Color3.fromRGB(50,50,50)
	b.TextColor3 = Color3.new(1,1,1)

	local c = Instance.new("UICorner", b)
	c.CornerRadius = UDim.new(0,8)

	return b
end

local speedBox = makeBtn("Speed: 50", 35)
local flyBtn = makeBtn("Fly", 70)
local noclipBtn = makeBtn("Noclip", 105)
local invisBtn = makeBtn("Invisibility", 140)
local setABtn = makeBtn("Set A", 175)
local setBBtn = makeBtn("Set B", 210)
local tpModeBtn = makeBtn("Teleport Mode", 245)
local tpABtn = makeBtn("Teleport A", 280)
local tpBBtn = makeBtn("Teleport B", 315)

-- Minimize
local minimized = false
avatarBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	for _, v in pairs(frame:GetChildren()) do
		if v ~= title and v ~= avatarBtn and v:IsA("GuiObject") then
			v.Visible = not minimized
		end
	end
	frame.Size = minimized and UDim2.new(0,220,0,35) or UDim2.new(0,220,0,340)
end)

-- Fly system (FIXED MOBILE)
local bodyVel, bodyGyro

local function startFlying()
	flying = true

	bodyVel = Instance.new("BodyVelocity")
	bodyVel.MaxForce = Vector3.new(1e6,1e6,1e6)
	bodyVel.Parent = rootPart

	bodyGyro = Instance.new("BodyGyro")
	bodyGyro.MaxTorque = Vector3.new(1e6,1e6,1e6)
	bodyGyro.Parent = rootPart

	humanoid:ChangeState(Enum.HumanoidStateType.Physics)
end

local function stopFlying()
	flying = false

	if bodyVel then bodyVel:Destroy() end
	if bodyGyro then bodyGyro:Destroy() end

	humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
end

flyBtn.MouseButton1Click:Connect(function()
	if flying then stopFlying() else startFlying() end
end)

-- Toggles
noclipBtn.MouseButton1Click:Connect(function()
	noclipEnabled = not noclipEnabled
end)

invisBtn.MouseButton1Click:Connect(function()
	invisible = not invisible
end)

-- Checkpoints
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

-- Mobile vertical movement (safe placement)
if isMobile then
	local upBtn = Instance.new("TextButton", screenGui)
	upBtn.Size = UDim2.new(0,60,0,60)
	upBtn.Position = UDim2.new(0,20,1,-140)
	upBtn.Text = "⬆️"

	local downBtn = Instance.new("TextButton", screenGui)
	downBtn.Size = UDim2.new(0,60,0,60)
	downBtn.Position = UDim2.new(0,20,1,-70)
	downBtn.Text = "⬇️"

	local c1 = Instance.new("UICorner", upBtn)
	c1.CornerRadius = UDim.new(1,0)

	local c2 = Instance.new("UICorner", downBtn)
	c2.CornerRadius = UDim.new(1,0)

	upBtn.MouseButton1Down:Connect(function() upDown = 1 end)
	upBtn.MouseButton1Up:Connect(function() upDown = 0 end)

	downBtn.MouseButton1Down:Connect(function() upDown = -1 end)
	downBtn.MouseButton1Up:Connect(function() upDown = 0 end)
end

-- Speed input
speedBox.FocusLost:Connect(function()
	local num = tonumber(speedBox.Text:match("%d+"))
	speed = math.clamp(num or 50, 1, 300)
	speedBox.Text = "Speed: " .. speed
end)

-- MAIN LOOP (FIXED MOBILE FLIGHT)
RunService.Heartbeat:Connect(function()
	if flying and bodyVel and bodyGyro and rootPart then
		local cam = workspace.CurrentCamera

		local moveDirection = humanoid.MoveDirection

		-- 📱 MOBILE FIX
		if moveDirection.Magnitude < 0.05 then
			moveDirection = cam.CFrame.LookVector * Vector3.new(1,0,1)
		end

		local direction =
			(cam.CFrame.RightVector * moveDirection.X) +
			(cam.CFrame.LookVector * moveDirection.Z) +
			Vector3.new(0, upDown, 0)

		local targetVel = Vector3.zero
		if direction.Magnitude > 0 then
			targetVel = direction.Unit * speed
		end

		bodyVel.Velocity = bodyVel.Velocity:Lerp(targetVel, 0.2)
		bodyGyro.CFrame = cam.CFrame
	end

	-- Noclip
	if character then
		for _, part in pairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = not noclipEnabled
			end
		end
	end

	-- Invisibility
	if character then
		for _, obj in pairs(character:GetDescendants()) do
			if obj:IsA("BasePart") or obj:IsA("Decal") then
				obj.Transparency = invisible and 1 or 0
			end
		end
	end
end)
