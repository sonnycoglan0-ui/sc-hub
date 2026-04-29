-- Services
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- Prevent duplicates
if player.PlayerGui:FindFirstChild("SC Hub") then
	player.PlayerGui["SC Hub"]:Destroy()
end

-- Character
local character, humanoid, rootPart
local function setupCharacter(char)
	character = char
	humanoid = char:WaitForChild("Humanoid")
	rootPart = char:WaitForChild("HumanoidRootPart")
end

setupCharacter(player.Character or player.CharacterAdded:Wait())
player.CharacterAdded:Connect(setupCharacter)

-- States
local flying = false
local speed = 50
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
-- GUI
------------------------------------------------
local gui = Instance.new("ScreenGui", player.PlayerGui)
gui.Name = "SC Hub"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0,220,0,340)
frame.Position = UDim2.new(0.5,-110,0.5,-170)

-- Gradient
local grad = Instance.new("UIGradient", frame)
grad.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(0,120,60)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(40,60,120)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(120,0,120))
}
grad.Rotation = 45

Instance.new("UICorner", frame).CornerRadius = UDim.new(0,12)

------------------------------------------------
-- Avatar minimize button
------------------------------------------------
local avatarBtn = Instance.new("ImageButton", frame)
avatarBtn.Size = UDim2.new(0,30,0,30)
avatarBtn.Position = UDim2.new(1,-35,0,5)
avatarBtn.BackgroundColor3 = Color3.fromRGB(200,0,0)
Instance.new("UICorner", avatarBtn).CornerRadius = UDim.new(1,0)

task.spawn(function()
	local img = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
	avatarBtn.Image = img
end)

local minimized = false
avatarBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	for _, v in pairs(frame:GetChildren()) do
		if v:IsA("GuiObject") and v ~= avatarBtn then
			v.Visible = not minimized
		end
	end
end)

------------------------------------------------
-- Buttons
------------------------------------------------
local function btn(text, y)
	local b = Instance.new("TextButton", frame)
	b.Size = UDim2.new(0,200,0,30)
	b.Position = UDim2.new(0,10,0,y)
	b.Text = text
	b.BackgroundColor3 = Color3.fromRGB(50,50,50)
	b.TextColor3 = Color3.new(1,1,1)
	Instance.new("UICorner", b).CornerRadius = UDim.new(0,8)
	return b
end

local flyBtn = btn("Fly", 40)
local noclipBtn = btn("Noclip", 75)
local invisBtn = btn("Invisibility", 110)
local setA = btn("Set A", 145)
local setB = btn("Set B", 180)
local tpMode = btn("Teleport Mode", 215)
local tpA = btn("Teleport A", 250)
local tpB = btn("Teleport B", 285)

------------------------------------------------
-- Fly system
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
-- Teleport system
------------------------------------------------
setA.MouseButton1Click:Connect(function()
	if rootPart then checkpointA = rootPart.CFrame end
end)

setB.MouseButton1Click:Connect(function()
	if rootPart then checkpointB = rootPart.CFrame end
end)

tpMode.MouseButton1Click:Connect(function()
	teleportMode = not teleportMode
end)

tpA.MouseButton1Click:Connect(function()
	if teleportMode and checkpointA then
		rootPart.CFrame = checkpointA + Vector3.new(0,3,0)
	end
end)

tpB.MouseButton1Click:Connect(function()
	if teleportMode and checkpointB then
		rootPart.CFrame = checkpointB + Vector3.new(0,3,0)
	end
end)

------------------------------------------------
-- Toggles
------------------------------------------------
noclipBtn.MouseButton1Click:Connect(function()
	noclipEnabled = not noclipEnabled
end)

invisBtn.MouseButton1Click:Connect(function()
	invisible = not invisible
end)

------------------------------------------------
-- MAIN LOOP (FIXED MOBILE FLY)
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
