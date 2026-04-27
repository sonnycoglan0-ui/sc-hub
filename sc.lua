-- Services
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- Prevent duplicate GUI
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

-- Detect mobile
local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled

-- States
local flying = false
local speed = 50
local noclipEnabled = false

-- Movement
local moveDir = Vector3.zero
local upDown = 0

-- GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SC Hub"
screenGui.Parent = player.PlayerGui

local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0,200,0,130)
frame.Position = UDim2.new(0.5,-100,0,100)
frame.BackgroundColor3 = Color3.fromRGB(40,40,40)

-- Title (drag handle)
local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,0,0,25)
title.BackgroundColor3 = Color3.fromRGB(30,30,30)
title.Text = "SC Hub"
title.TextColor3 = Color3.new(1,1,1)
title.TextScaled = true

-- Minimize button
local minimizeBtn = Instance.new("TextButton", frame)
minimizeBtn.Size = UDim2.new(0,25,0,25)
minimizeBtn.Position = UDim2.new(1,-25,0,0)
minimizeBtn.Text = "-"
minimizeBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
minimizeBtn.TextColor3 = Color3.new(1,1,1)

-- Controls
local speedBox = Instance.new("TextBox", frame)
speedBox.Size = UDim2.new(0,180,0,30)
speedBox.Position = UDim2.new(0,10,0,35)
speedBox.Text = "Speed: 50"

local flyBtn = Instance.new("TextButton", frame)
flyBtn.Size = UDim2.new(0,180,0,30)
flyBtn.Position = UDim2.new(0,10,0,70)
flyBtn.Text = "Fly"

local noclipBtn = Instance.new("TextButton", frame)
noclipBtn.Size = UDim2.new(0,180,0,30)
noclipBtn.Position = UDim2.new(0,10,0,105)
noclipBtn.Text = "Noclip"

-- 📱 Mobile controls
local upBtn = Instance.new("TextButton", screenGui)
upBtn.Size = UDim2.new(0,80,0,80)
upBtn.Position = UDim2.new(1,-90,1,-180)
upBtn.Text = "⬆️"
upBtn.Visible = isMobile

local downBtn = Instance.new("TextButton", screenGui)
downBtn.Size = UDim2.new(0,80,0,80)
downBtn.Position = UDim2.new(1,-90,1,-90)
downBtn.Text = "⬇️"
downBtn.Visible = isMobile

-- Dragging (TOP BAR ONLY)
local dragging = false
local dragInput, mousePos, framePos

title.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		mousePos = input.Position
		framePos = frame.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

title.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

UIS.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		local delta = input.Position - mousePos
		frame.Position = UDim2.new(
			framePos.X.Scale,
			framePos.X.Offset + delta.X,
			framePos.Y.Scale,
			framePos.Y.Offset + delta.Y
		)
	end
end)

-- Minimize
local minimized = false
minimizeBtn.MouseButton1Click:Connect(function()
	minimized = not minimized

	for _, v in pairs(frame:GetChildren()) do
		if v ~= minimizeBtn and v ~= title and v:IsA("GuiObject") then
			v.Visible = not minimized
		end
	end

	frame.Size = minimized and UDim2.new(0,200,0,25) or UDim2.new(0,200,0,130)
end)

-- Fly objects
local bodyVel, bodyGyro

local function startFlying()
	flying = true

	bodyVel = Instance.new("BodyVelocity")
	bodyVel.MaxForce = Vector3.new(1e5,1e5,1e5)
	bodyVel.Parent = rootPart

	bodyGyro = Instance.new("BodyGyro")
	bodyGyro.MaxTorque = Vector3.new(1e5,1e5,1e5)
	bodyGyro.Parent = rootPart

	humanoid.PlatformStand = true
end

local function stopFlying()
	flying = false
	if bodyVel then bodyVel:Destroy() end
	if bodyGyro then bodyGyro:Destroy() end
	humanoid.PlatformStand = false
end

local function toggleFly()
	if flying then stopFlying() else startFlying() end
end

local function toggleNoclip()
	noclipEnabled = not noclipEnabled
end

-- 📱 Mobile buttons
upBtn.MouseButton1Down:Connect(function() upDown = 1 end)
upBtn.MouseButton1Up:Connect(function() upDown = 0 end)

downBtn.MouseButton1Down:Connect(function() upDown = -1 end)
downBtn.MouseButton1Up:Connect(function() upDown = 0 end)

-- PC input
UIS.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.W then moveDir += Vector3.new(0,0,-1) end
	if input.KeyCode == Enum.KeyCode.S then moveDir += Vector3.new(0,0,1) end
	if input.KeyCode == Enum.KeyCode.A then moveDir += Vector3.new(-1,0,0) end
	if input.KeyCode == Enum.KeyCode.D then moveDir += Vector3.new(1,0,0) end
	if input.KeyCode == Enum.KeyCode.Space then upDown = 1 end
	if input.KeyCode == Enum.KeyCode.LeftShift then upDown = -1 end
end)

UIS.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.W then moveDir -= Vector3.new(0,0,-1) end
	if input.KeyCode == Enum.KeyCode.S then moveDir -= Vector3.new(0,0,1) end
	if input.KeyCode == Enum.KeyCode.A then moveDir -= Vector3.new(-1,0,0) end
	if input.KeyCode == Enum.KeyCode.D then moveDir -= Vector3.new(1,0,0) end
	if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.LeftShift then upDown = 0 end
end)

-- Main loop
RunService.Heartbeat:Connect(function()
	if flying and bodyVel and bodyGyro and rootPart then
		local cam = workspace.CurrentCamera

		local direction =
			(cam.CFrame.LookVector * moveDir.Z) +
			(cam.CFrame.RightVector * moveDir.X) +
			Vector3.new(0, upDown, 0)

		if direction.Magnitude > 0 then
			bodyVel.Velocity = direction.Unit * speed
		else
			bodyVel.Velocity = Vector3.zero
		end

		bodyGyro.CFrame = cam.CFrame
	end

	-- Fixed noclip (always sync)
	if character then
		for _, part in pairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = not noclipEnabled
			end
		end
	end
end)

-- UI events
flyBtn.MouseButton1Click:Connect(toggleFly)
noclipBtn.MouseButton1Click:Connect(toggleNoclip)

speedBox.FocusLost:Connect(function()
	local num = tonumber(speedBox.Text:match("%d+"))
	speed = math.clamp(num or 50, 1, 300)
	speedBox.Text = "Speed: " .. speed
end)
