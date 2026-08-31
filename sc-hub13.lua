--// SC HUB
--// Fresh Admin Panel
--// Place in StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--==================================================
-- SETTINGS
--==================================================

local Settings = {
	Fly = false,
	Noclip = false,
	Invisible = false,
	InfiniteJump = false,
	ESP = false,
	UsernameESP = false,
	XRay = false,
	Fullbright = false,
	Freecam = false,

	WalkSpeed = 16,
	JumpPower = 50,

	TPA = nil,
	TPB = nil,
}

local Character
local Humanoid
local Root

local function refreshCharacter(char)
	Character = char
	Humanoid = char:WaitForChild("Humanoid")
	Root = char:WaitForChild("HumanoidRootPart")
end

refreshCharacter(LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait())

LocalPlayer.CharacterAdded:Connect(function(char)
	refreshCharacter(char)

	task.wait(0.5)

	if Settings.Invisible then
		for _, obj in ipairs(Character:GetDescendants()) do
			if obj:IsA("BasePart") then
				obj.LocalTransparencyModifier = 1
			elseif obj:IsA("Decal") then
				obj.Transparency = 1
			end
		end
	end
end)

--==================================================
-- GUI
--==================================================

local Gui = Instance.new("ScreenGui")
Gui.Name = "SCHub"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.Parent = PlayerGui

-- Main window
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 600, 0, 430)
Main.Position = UDim2.new(0.5, -300, 0.5, -215)
Main.BackgroundColor3 = Color3.fromRGB(15, 18, 24)
Main.BorderSizePixel = 0
Main.Parent = Gui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 16)
MainCorner.Parent = Main

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(55, 65, 75)
Stroke.Thickness = 1
Stroke.Parent = Main

-- Gradient
local Gradient = Instance.new("UIGradient")
Gradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 180, 100)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 90, 220))
})
Gradient.Rotation = 35
Gradient.Parent = Main

-- Overlay to keep center dark
local Overlay = Instance.new("Frame")
Overlay.Size = UDim2.new(1, 0, 1, 0)
Overlay.BackgroundColor3 = Color3.fromRGB(10, 13, 18)
Overlay.BackgroundTransparency = 0.08
Overlay.BorderSizePixel = 0
Overlay.Parent = Main

local OverlayCorner = Instance.new("UICorner")
OverlayCorner.CornerRadius = UDim.new(0, 16)
OverlayCorner.Parent = Overlay

--==================================================
-- TITLE
--==================================================

local Title = Instance.new("TextLabel")
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 22, 0, 12)
Title.Size = UDim2.new(0, 300, 0, 35)
Title.Font = Enum.Font.GothamBold
Title.Text = "SC Hub"
Title.TextSize = 25
Title.TextColor3 = Color3.new(1,1,1)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Overlay

local Subtitle = Instance.new("TextLabel")
Subtitle.BackgroundTransparency = 1
Subtitle.Position = UDim2.new(0, 23, 0, 42)
Subtitle.Size = UDim2.new(0, 300, 0, 20)
Subtitle.Font = Enum.Font.Gotham
Subtitle.Text = "Admin Control Panel"
Subtitle.TextSize = 12
Subtitle.TextColor3 = Color3.fromRGB(170,180,190)
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.Parent = Overlay

--==================================================
-- AVATAR CLOSE BUTTON
--==================================================

local AvatarButton = Instance.new("ImageButton")
AvatarButton.Name = "ProfileClose"
AvatarButton.Size = UDim2.new(0, 42, 0, 42)
AvatarButton.Position = UDim2.new(1, -57, 0, 12)
AvatarButton.BackgroundColor3 = Color3.fromRGB(30, 35, 42)
AvatarButton.BorderSizePixel = 0
AvatarButton.Parent = Overlay

local AvatarCorner = Instance.new("UICorner")
AvatarCorner.CornerRadius = UDim.new(1, 0)
AvatarCorner.Parent = AvatarButton

local thumb = Players:GetUserThumbnailAsync(
	LocalPlayer.UserId,
	Enum.ThumbnailType.HeadShot,
	Enum.ThumbnailSize.Size100x100
)

AvatarButton.Image = thumb

AvatarButton.MouseButton1Click:Connect(function()
	Main.Visible = false
end)

--==================================================
-- SIDEBAR
--==================================================

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 135, 1, -85)
Sidebar.Position = UDim2.new(0, 12, 0, 70)
Sidebar.BackgroundColor3 = Color3.fromRGB(18, 22, 29)
Sidebar.BorderSizePixel = 0
Sidebar.Parent = Overlay

local SideCorner = Instance.new("UICorner")
SideCorner.CornerRadius = UDim.new(0, 12)
SideCorner.Parent = Sidebar

local SideLayout = Instance.new("UIListLayout")
SideLayout.Padding = UDim.new(0, 7)
SideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
SideLayout.VerticalAlignment = Enum.VerticalAlignment.Top
SideLayout.Parent = Sidebar

local SidePadding = Instance.new("UIPadding")
SidePadding.PaddingTop = UDim.new(0, 10)
SidePadding.Parent = Sidebar

--==================================================
-- CONTENT
--==================================================

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -165, 1, -85)
Content.Position = UDim2.new(0, 153, 0, 70)
Content.BackgroundTransparency = 1
Content.Parent = Overlay

--==================================================
-- NOTIFICATIONS
--==================================================

local NotificationHolder = Instance.new("Frame")
NotificationHolder.Size = UDim2.new(0, 280, 0, 250)
NotificationHolder.Position = UDim2.new(1, -295, 1, -265)
NotificationHolder.BackgroundTransparency = 1
NotificationHolder.Parent = Gui

local NotificationLayout = Instance.new("UIListLayout")
NotificationLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
NotificationLayout.Padding = UDim.new(0, 7)
NotificationLayout.Parent = NotificationHolder

local function Notify(text)
	local N = Instance.new("TextLabel")
	N.Size = UDim2.new(1, 0, 0, 42)
	N.BackgroundColor3 = Color3.fromRGB(22, 26, 34)
	N.BackgroundTransparency = 0.05
	N.Text = text
	N.TextColor3 = Color3.new(1,1,1)
	N.Font = Enum.Font.GothamMedium
	N.TextSize = 13
	N.TextWrapped = true
	N.BorderSizePixel = 0
	N.Parent = NotificationHolder

	local C = Instance.new("UICorner")
	C.CornerRadius = UDim.new(0, 9)
	C.Parent = N

	task.delay(2.5, function()
		local t = TweenService:Create(
			N,
			TweenInfo.new(0.25),
			{BackgroundTransparency = 1, TextTransparency = 1}
		)
		t:Play()
		t.Completed:Wait()
		N:Destroy()
	end)
end

--==================================================
-- BUTTON CREATOR
--==================================================

local function MakeButton(parent, text, callback)
	local Button = Instance.new("TextButton")
	Button.Size = UDim2.new(1, 0, 0, 42)
	Button.BackgroundColor3 = Color3.fromRGB(27, 32, 40)
	Button.BorderSizePixel = 0
	Button.AutoButtonColor = false
	Button.Text = text
	Button.Font = Enum.Font.GothamMedium
	Button.TextSize = 13
	Button.TextColor3 = Color3.fromRGB(230,235,240)
	Button.Parent = parent

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 9)
	Corner.Parent = Button

	Button.MouseEnter:Connect(function()
		TweenService:Create(
			Button,
			TweenInfo.new(0.15),
			{BackgroundColor3 = Color3.fromRGB(38, 48, 60)}
		):Play()
	end)

	Button.MouseLeave:Connect(function()
		TweenService:Create(
			Button,
			TweenInfo.new(0.15),
			{BackgroundColor3 = Color3.fromRGB(27, 32, 40)}
		):Play()
	end)

	Button.MouseButton1Click:Connect(callback)

	return Button
end

local function MakeToggle(parent, text, settingName, callback)
	local Button

	local function update()
		local enabled = Settings[settingName]

		Button.Text = text .. (enabled and "   • ON" or "   • OFF")

		if enabled then
			Button.BackgroundColor3 = Color3.fromRGB(25, 125, 85)
		else
			Button.BackgroundColor3 = Color3.fromRGB(27, 32, 40)
		end
	end

	Button = MakeButton(parent, text, function()
		Settings[settingName] = not Settings[settingName]
		update()

		if callback then
			callback(Settings[settingName])
		end
	end)

	update()

	return Button
end

--==================================================
-- PAGE SYSTEM
--==================================================

local Pages = {}

local function CreatePage(name)
	local Page = Instance.new("Frame")
	Page.Name = name
	Page.Size = UDim2.new(1, 0, 1, 0)
	Page.BackgroundTransparency = 1
	Page.Visible = false
	Page.Parent = Content

	Pages[name] = Page

	return Page
end

local function CreateSideButton(name)
	local Button = Instance.new("TextButton")
	Button.Size = UDim2.new(1, -16, 0, 38)
	Button.BackgroundColor3 = Color3.fromRGB(24, 29, 36)
	Button.BorderSizePixel = 0
	Button.AutoButtonColor = false
	Button.Text = name
	Button.TextColor3 = Color3.fromRGB(200,210,220)
	Button.Font = Enum.Font.GothamMedium
	Button.TextSize = 12
	Button.Parent = Sidebar

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 8)
	Corner.Parent = Button

	Button.MouseButton1Click:Connect(function()
		for _, page in pairs(Pages) do
			page.Visible = false
		end

		Pages[name].Visible = true

		for _, child in ipairs(Sidebar:GetChildren()) do
			if child:IsA("TextButton") then
				child.BackgroundColor3 = Color3.fromRGB(24, 29, 36)
			end
		end

		Button.BackgroundColor3 = Color3.fromRGB(35, 120, 90)
	end)

	return Button
end

--==================================================
-- MOVEMENT PAGE
--==================================================

local Movement = CreatePage("Movement")

local MoveLayout = Instance.new("UIListLayout")
MoveLayout.Padding = UDim.new(0, 8)
MoveLayout.Parent = Movement

MakeToggle(Movement, "Fly", "Fly", function(state)
	Notify(state and "Fly enabled" or "Fly disabled")
end)

MakeToggle(Movement, "Noclip", "Noclip", function(state)
	Notify(state and "Noclip enabled" or "Noclip disabled")
end)

MakeToggle(Movement, "Invisibility", "Invisible", function(state)
	if not Character then return end

	for _, obj in ipairs(Character:GetDescendants()) do
		if obj:IsA("BasePart") then
			obj.LocalTransparencyModifier = state and 1 or 0
		elseif obj:IsA("Decal") then
			obj.Transparency = state and 1 or 0
		end
	end

	Notify(state and "Invisibility enabled" or "Invisibility disabled")
end)

MakeToggle(Movement, "Infinite Jump", "InfiniteJump", function(state)
	Notify(state and "Infinite Jump enabled" or "Infinite Jump disabled")
end)

-- WalkSpeed
local SpeedBox = MakeButton(Movement, "WalkSpeed: 16", function()
	Settings.WalkSpeed += 5

	if Settings.WalkSpeed > 100 then
		Settings.WalkSpeed = 16
	end

	if Humanoid then
		Humanoid.WalkSpeed = Settings.WalkSpeed
	end

	SpeedBox.Text = "WalkSpeed: " .. Settings.WalkSpeed
end)

-- JumpPower
local JumpBox = MakeButton(Movement, "JumpPower: 50", function()
	Settings.JumpPower += 10

	if Settings.JumpPower > 150 then
		Settings.JumpPower = 50
	end

	if Humanoid then
		Humanoid.JumpPower = Settings.JumpPower
	end

	JumpBox.Text = "JumpPower: " .. Settings.JumpPower
end)

--==================================================
-- TELEPORT PAGE
--==================================================

local Teleport = CreatePage("Teleport")

local TPLayout = Instance.new("UIListLayout")
TPLayout.Padding = UDim.new(0, 8)
TPLayout.Parent = Teleport

MakeButton(Teleport, "Teleport", function()
	Notify("Teleport tool ready")
end)

MakeButton(Teleport, "Set TP A", function()
	if Root then
		Settings.TPA = Root.CFrame
		Notify("TP A saved")
	end
end)

MakeButton(Teleport, "Set TP B", function()
	if Root then
		Settings.TPB = Root.CFrame
		Notify("TP B saved")
	end
end)

MakeButton(Teleport, "TP to A", function()
	if Root and Settings.TPA then
		Root.CFrame = Settings.TPA
		Notify("Teleported to A")
	else
		Notify("TP A hasn't been set")
	end
end)

MakeButton(Teleport, "TP to B", function()
	if Root and Settings.TPB then
		Root.CFrame = Settings.TPB
		Notify("Teleported to B")
	else
		Notify("TP B hasn't been set")
	end
end)

--==================================================
-- PLAYER PAGE
--==================================================

local PlayerPage = CreatePage("Player")

local PlayerLayout = Instance.new("UIListLayout")
PlayerLayout.Padding = UDim.new(0, 8)
PlayerLayout.Parent = PlayerPage

-- ESP
local ESPObjects = {}

local function ClearESP()
	for _, data in pairs(ESPObjects) do
		if data.Highlight then
			data.Highlight:Destroy()
		end

		if data.Billboard then
			data.Billboard:Destroy()
		end
	end

	table.clear(ESPObjects)
end

local function ApplyESP(player)
	if player == LocalPlayer then return end
	if not player.Character then return end

	local highlight = Instance.new("Highlight")
	highlight.Name = "SC_ESP"
	highlight.FillTransparency = 0.75
	highlight.OutlineTransparency = 0
	highlight.Adornee = player.Character
	highlight.Parent = player.Character

	local billboard

	if Settings.UsernameESP then
		billboard = Instance.new("BillboardGui")
		billboard.Name = "SC_NameESP"
		billboard.Size = UDim2.new(0, 200, 0, 35)
		billboard.StudsOffset = Vector3.new(0, 3, 0)
		billboard.AlwaysOnTop = true
		billboard.Adornee = player.Character:FindFirstChild("Head")
		billboard.Parent = player.Character

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1,0,1,0)
		label.BackgroundTransparency = 1
		label.Text = player.DisplayName .. "  @" .. player.Name
		label.TextColor3 = Color3.new(1,1,1)
		label.TextStrokeTransparency = 0
		label.Font = Enum.Font.GothamBold
		label.TextSize = 13
		label.Parent = billboard
	end

	ESPObjects[player] = {
		Highlight = highlight,
		Billboard = billboard
	}
end

local function RefreshESP()
	ClearESP()

	if not Settings.ESP then
		return
	end

	for _, player in ipairs(Players:GetPlayers()) do
		ApplyESP(player)
	end
end

MakeToggle(PlayerPage, "ESP Players", "ESP", function()
	RefreshESP()
end)

MakeToggle(PlayerPage, "Username ESP", "UsernameESP", function()
	RefreshESP()
end)

MakeToggle(PlayerPage, "X-Ray", "XRay", function(state)
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") and not obj:IsDescendantOf(Character) then
			if state then
				obj.LocalTransparencyModifier = 0.45
			else
				obj.LocalTransparencyModifier = 0
			end
		end
	end

	Notify(state and "X-Ray enabled" or "X-Ray disabled")
end)

Players.PlayerAdded:Connect(function()
	task.wait(1)
	RefreshESP()
end)

Players.PlayerRemoving:Connect(function(player)
	if ESPObjects[player] then
		if ESPObjects[player].Highlight then
			ESPObjects[player].Highlight:Destroy()
		end
		if ESPObjects[player].Billboard then
			ESPObjects[player].Billboard:Destroy()
		end

		ESPObjects[player] = nil
	end
end)

--==================================================
-- WORLD PAGE
--==================================================

local World = CreatePage("World")

local WorldLayout = Instance.new("UIListLayout")
WorldLayout.Padding = UDim.new(0, 8)
WorldLayout.Parent = World

local originalLighting = {
	Brightness = Lighting.Brightness,
	ClockTime = Lighting.ClockTime,
	FogEnd = Lighting.FogEnd,
	GlobalShadows = Lighting.GlobalShadows
}

MakeToggle(World, "Fullbright", "Fullbright", function(state)
	if state then
		Lighting.Brightness = 2
		Lighting.ClockTime = 14
		Lighting.FogEnd = 100000
		Lighting.GlobalShadows = false
	else
		Lighting.Brightness = originalLighting.Brightness
		Lighting.ClockTime = originalLighting.ClockTime
		Lighting.FogEnd = originalLighting.FogEnd
		Lighting.GlobalShadows = originalLighting.GlobalShadows
	end

	Notify(state and "Fullbright enabled" or "Fullbright disabled")
end)

MakeButton(World, "FOV: 70", function(button)
	-- FOV handled below
end)

local FOVButton = World:GetChildren()[2]
if FOVButton and FOVButton:IsA("TextButton") then
	FOVButton.Text = "FOV: 70"

	FOVButton.MouseButton1Click:Connect(function()
		local camera = workspace.CurrentCamera
		camera.FieldOfView += 10

		if camera.FieldOfView > 120 then
			camera.FieldOfView = 70
		end

		FOVButton.Text = "FOV: " .. math.floor(camera.FieldOfView)
	end)
end

--==================================================
-- SETTINGS PAGE
--==================================================

local SettingsPage = CreatePage("Settings")

local SettingsLayout = Instance.new("UIListLayout")
SettingsLayout.Padding = UDim.new(0, 8)
SettingsLayout.Parent = SettingsPage

MakeButton(SettingsPage, "Reset Movement", function()
	Settings.WalkSpeed = 16
	Settings.JumpPower = 50

	if Humanoid then
		Humanoid.WalkSpeed = 16
		Humanoid.JumpPower = 50
	end

	Notify("Movement settings reset")
end)

MakeButton(SettingsPage, "Reopen SC Hub", function()
	Main.Visible = true
end)

MakeButton(SettingsPage, "Hide Hub", function()
	Main.Visible = false
end)

--==================================================
-- SIDEBAR BUTTONS
--==================================================

CreateSideButton("Movement")
CreateSideButton("Teleport")
CreateSideButton("Player")
CreateSideButton("World")
CreateSideButton("Settings")

Pages.Movement.Visible = true

--==================================================
-- WELCOME TEXT
--==================================================

local Welcome = Instance.new("TextLabel")
Welcome.BackgroundTransparency = 1
Welcome.Position = UDim2.new(0, 17, 1, -32)
Welcome.Size = UDim2.new(0, 300, 0, 22)
Welcome.Text = "Welcome, " .. LocalPlayer.DisplayName
Welcome.Font = Enum.Font.GothamMedium
Welcome.TextSize = 12
Welcome.TextColor3 = Color3.fromRGB(175,185,195)
Welcome.TextXAlignment = Enum.TextXAlignment.Left
Welcome.Parent = Overlay

--==================================================
-- DRAGGING
--==================================================

local dragging = false
local dragStart
local startPosition

Title.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then

		dragging = true
		dragStart = input.Position
		startPosition = Main.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

UIS.InputChanged:Connect(function(input)
	if dragging and (
		input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch
	) then

		local delta = input.Position - dragStart

		Main.Position = UDim2.new(
			startPosition.X.Scale,
			startPosition.X.Offset + delta.X,
			startPosition.Y.Scale,
			startPosition.Y.Offset + delta.Y
		)
	end
end)

--==================================================
-- FLY
--==================================================

local FlyVelocity
local FlyConnection

local function StopFly()
	if FlyVelocity then
		FlyVelocity:Destroy()
		FlyVelocity = nil
	end

	if FlyConnection then
		FlyConnection:Disconnect()
		FlyConnection = nil
	end
end

local function StartFly()
	StopFly()

	if not Root then return end

	FlyVelocity = Instance.new("BodyVelocity")
	FlyVelocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
	FlyVelocity.Velocity = Vector3.zero
	FlyVelocity.Parent = Root

	FlyConnection = RunService.RenderStepped:Connect(function()
		if not Settings.Fly or not Root then
			StopFly()
			return
		end

		local camera = workspace.CurrentCamera
		local direction = Vector3.zero

		if UIS:IsKeyDown(Enum.KeyCode.W) then
			direction += camera.CFrame.LookVector
		end

		if UIS:IsKeyDown(Enum.KeyCode.S) then
			direction -= camera.CFrame.LookVector
		end

		if UIS:IsKeyDown(Enum.KeyCode.A) then
			direction -= camera.CFrame.RightVector
		end

		if UIS:IsKeyDown(Enum.KeyCode.D) then
			direction += camera.CFrame.RightVector
		end

		if UIS:IsKeyDown(Enum.KeyCode.Space) then
			direction += Vector3.new(0,1,0)
		end

		if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
			direction -= Vector3.new(0,1,0)
		end

		if direction.Magnitude > 0 then
			direction = direction.Unit
		end

		FlyVelocity.Velocity = direction * 60
	end)
end

-- Reconnect fly toggle behaviour
task.spawn(function()
	local old = Settings.Fly

	while true do
		task.wait(0.1)

		if Settings.Fly ~= old then
			old = Settings.Fly

			if Settings.Fly then
				StartFly()
			else
				StopFly()
			end
		end
	end
end)

--==================================================
-- NOCLIP
--==================================================

RunService.Stepped:Connect(function()
	if Settings.Noclip and Character then
		for _, obj in ipairs(Character:GetDescendants()) do
			if obj:IsA("BasePart") then
				obj.CanCollide = false
			end
		end
	end
end)

--==================================================
-- INFINITE JUMP
--==================================================

UIS.JumpRequest:Connect(function()
	if Settings.InfiniteJump and Humanoid then
		Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end)

--==================================================
-- CHARACTER SPEED UPDATE
--==================================================

RunService.Heartbeat:Connect(function()
	if Humanoid then
		Humanoid.WalkSpeed = Settings.WalkSpeed
		Humanoid.JumpPower = Settings.JumpPower
	end
end)

--==================================================
-- OPEN KEY
--==================================================

UIS.InputBegan:Connect(function(input, processed)
	if processed then return end

	if input.KeyCode == Enum.KeyCode.RightShift then
		Main.Visible = not Main.Visible
	end
end)

--==================================================
-- OPEN ANIMATION
--==================================================

Main.Size = UDim2.new(0, 0, 0, 0)

TweenService:Create(
	Main,
	TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	{Size = UDim2.new(0, 600, 0, 430)}
):Play()

Notify("SC Hub loaded")
