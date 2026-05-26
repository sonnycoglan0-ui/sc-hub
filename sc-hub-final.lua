-// SC ADMIN HUB (FINAL 100% FIXED VERSION)
--// LocalScript -> StarterPlayerScripts

------------------------------------------------
-- SERVICES
------------------------------------------------
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local TS = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

------------------------------------------------
-- STATE
------------------------------------------------
local PREFIX = ";"

local flying = false
local noclipping = false
local invisible = false
local freecamEnabled = false
local clickTpEnabled = false
local espEnabled = false
local tracersEnabled = false

local flyConn
local noclipConn
local freecamConn
local clickTpConn
local tracerConn
local espPlayerAddedConn

local freecamPart
local invisCache = {}
local espHighlights = {}
local tracerLines = {}

------------------------------------------------
-- CHARACTER HELPERS
------------------------------------------------
local character
local humanoid
local hrp

local function updateCharacter()
character = player.Character or player.CharacterAdded:Wait()
humanoid = character:WaitForChild("Humanoid")
hrp = character:WaitForChild("HumanoidRootPart")

-- Restore invisibility after respawn
if invisible then
task.wait()
invisCache = {} -- clear old cache
for _, obj in ipairs(character:GetDescendants()) do
if obj:IsA("BasePart") or obj:IsA("Decal") then
invisCache[obj] = obj.Transparency
if obj.Name ~= "HumanoidRootPart" then
obj.Transparency = 1
end
end
end
end
end

updateCharacter()

player.CharacterAdded:Connect(function()
task.wait(1)

-- Reset features that break on respawn
if flying then Fly() end
if noclipping then Noclip() end
if freecamEnabled then
camera.CameraType = Enum.CameraType.Custom
freecamEnabled = false
if freecamPart then freecamPart:Destroy() end
end

updateCharacter()
end)

------------------------------------------------
-- UTIL
------------------------------------------------
local function notify(title, text)
pcall(function()
StarterGui:SetCore("SendNotification", {
Title = tostring(title),
Text = tostring(text),
Duration = 3
})
end)
print("[SC HUB]", title, text)
end

local function findPlayer(name)
if not name then return nil end
name = string.lower(name)

for _, p in ipairs(Players:GetPlayers()) do
if p ~= player and string.sub(string.lower(p.Name), 1, #name) == name then
return p
end
end
end

------------------------------------------------
-- FLY
------------------------------------------------
local flyGyro
local flyVel

local function Fly()
flying = not flying

if flying then
if not hrp or not humanoid then
notify("FLY", "No character found!")
flying = false
return
end

humanoid.PlatformStand = true

flyGyro = Instance.new("BodyGyro")
flyGyro.MaxTorque = Vector3.new(1e9,1e9,1e9)
flyGyro.P = 10000
flyGyro.CFrame = hrp.CFrame
flyGyro.Parent = hrp

flyVel = Instance.new("BodyVelocity")
flyVel.MaxForce = Vector3.new(1e9,1e9,1e9)
flyVel.Velocity = Vector3.zero
flyVel.Parent = hrp

flyConn = RS.RenderStepped:Connect(function()
if not flying or not hrp then return end

local moveDir = Vector3.zero
local camCF = camera.CFrame

if UIS:IsKeyDown(Enum.KeyCode.W) then moveDir += camCF.LookVector end
if UIS:IsKeyDown(Enum.KeyCode.S) then moveDir -= camCF.LookVector end
if UIS:IsKeyDown(Enum.KeyCode.A) then moveDir -= camCF.RightVector end
if UIS:IsKeyDown(Enum.KeyCode.D) then moveDir += camCF.RightVector end
if UIS:IsKeyDown(Enum.KeyCode.Space) then moveDir += Vector3.yAxis end
if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir -= Vector3.yAxis end

if moveDir.Magnitude > 0 then
flyVel.Velocity = moveDir.Unit * 60
else
flyVel.Velocity = Vector3.zero
end

flyGyro.CFrame = camCF
end)

notify("FLY", "Enabled")

else
if flyConn then flyConn:Disconnect() flyConn = nil end
if flyGyro then flyGyro:Destroy() flyGyro = nil end
if flyVel then flyVel:Destroy() flyVel = nil end
if humanoid then humanoid.PlatformStand = false end

notify("FLY", "Disabled")
end
end

------------------------------------------------
-- NOCLIP
------------------------------------------------
local function Noclip()
noclipping = not noclipping

if noclipping then
noclipConn = RS.Stepped:Connect(function()
if not character then return end
for _, obj in ipairs(character:GetDescendants()) do
if obj:IsA("BasePart") then
obj.CanCollide = false
end
end
end)
notify("NOCLIP", "Enabled")

else
if noclipConn then noclipConn:Disconnect() noclipConn = nil end
if character then
for _, obj in ipairs(character:GetDescendants()) do
if obj:IsA("BasePart") then
obj.CanCollide = true
end
end
end
notify("NOCLIP", "Disabled")
end
end

------------------------------------------------
-- INVISIBLE
------------------------------------------------
local function Invisible()
if not character then return end

invisible = not invisible
invisCache = {}

if invisible then
for _, obj in ipairs(character:GetDescendants()) do
if obj:IsA("BasePart") or obj:IsA("Decal") then
invisCache[obj] = obj.Transparency
if obj.Name ~= "HumanoidRootPart" then
obj.Transparency = 1
end
end
end
notify("INVIS", "Enabled")

else
for obj, transparency in pairs(invisCache) do
if obj and obj.Parent then
obj.Transparency = transparency
end
end
invisCache = {} -- ✅ FIX: clear cache when disabling
notify("INVIS", "Disabled")
end
end

------------------------------------------------
-- SPEED
------------------------------------------------
local function Speed(num)
if humanoid then
local newSpeed = tonumber(num) or 16
humanoid.WalkSpeed = newSpeed
notify("SPEED", "Set to "..tostring(newSpeed))
end
end

------------------------------------------------
-- JUMP
------------------------------------------------
local function Jump(num)
if humanoid then
local newJump = tonumber(num) or 50
humanoid.JumpPower = newJump
notify("JUMP", "Set to "..tostring(newJump))
end
end

------------------------------------------------
-- FREECAM
------------------------------------------------
local freecamSpeed = 50

local function Freecam()
freecamEnabled = not freecamEnabled

if freecamEnabled then
if freecamPart then freecamPart:Destroy() end
freecamPart = Instance.new("Part")
freecamPart.Anchored = true
freecamPart.CanCollide = false
freecamPart.Transparency = 1
freecamPart.CFrame = camera.CFrame
freecamPart.Parent = workspace

camera.CameraType = Enum.CameraType.Scriptable

freecamConn = RS.RenderStepped:Connect(function(dt)
if not freecamPart then return end

local dir = Vector3.zero
local cf = camera.CFrame

if UIS:IsKeyDown(Enum.KeyCode.W) then dir += cf.LookVector end
if UIS:IsKeyDown(Enum.KeyCode.S) then dir -= cf.LookVector end
if UIS:IsKeyDown(Enum.KeyCode.A) then dir -= cf.RightVector end
if UIS:IsKeyDown(Enum.KeyCode.D) then dir += cf.RightVector end
if UIS:IsKeyDown(Enum.KeyCode.E) then dir += Vector3.yAxis end
if UIS:IsKeyDown(Enum.KeyCode.Q) then dir -= Vector3.yAxis end

if dir.Magnitude > 0 then
freecamPart.CFrame += dir.Unit * freecamSpeed * dt
end

camera.CFrame = freecamPart.CFrame
end)

notify("FREECAM", "Enabled")

else
if freecamConn then freecamConn:Disconnect() freecamConn = nil end
if freecamPart then freecamPart:Destroy() freecamPart = nil end

camera.CameraType = Enum.CameraType.Custom
if humanoid then camera.CameraSubject = humanoid end

notify("FREECAM", "Disabled")
end
end

------------------------------------------------
-- CLICK TP
------------------------------------------------
local function ClickTP()
clickTpEnabled = not clickTpEnabled

if clickTpEnabled then
clickTpConn = UIS.InputBegan:Connect(function(input, gameProcessed)
if gameProcessed or not clickTpEnabled then return end

-- Ignore if typing in command bar
if UIS:GetFocusedTextBox() then return end

if input.UserInputType == Enum.UserInputType.MouseButton1 then
local mousePos = UIS:GetMouseLocation()
local ray = camera:ViewportPointToRay(mousePos.X, mousePos.Y)
local result = workspace:Raycast(ray.Origin, ray.Direction * 5000)

if result and hrp then
hrp.CFrame = CFrame.new(result.Position + Vector3.new(0,3,0))
end
end
end)
notify("CLICK TP", "Enabled")

else
if clickTpConn then clickTpConn:Disconnect() clickTpConn = nil end
notify("CLICK TP", "Disabled")
end
end

------------------------------------------------
-- ESP
------------------------------------------------
local function addESP(p)
if p == player then return end

local function apply(char)
if not espEnabled then return end
task.wait()

if espHighlights[p] then espHighlights[p]:Destroy() end

local hl = Instance.new("Highlight")
hl.FillTransparency = 0.5
hl.OutlineTransparency = 0
hl.OutlineColor = Color3.new(1,0,0)
hl.Adornee = char
hl.Parent = char

espHighlights[p] = hl
end

if p.Character then apply(p.Character) end
p.CharacterAdded:Connect(apply)
end

-- Cleanup when player leaves
Players.PlayerRemoving:Connect(function(p)
if espHighlights[p] then
espHighlights[p]:Destroy()
espHighlights[p] = nil
end
end)

local function clearESP()
for _, hl in pairs(espHighlights) do
if hl then hl:Destroy() end
end
espHighlights = {}
end

local function ESP()
espEnabled = not espEnabled

if espEnabled then
for _, p in ipairs(Players:GetPlayers()) do addESP(p) end
espPlayerAddedConn = Players.PlayerAdded:Connect(addESP)
notify("ESP", "Enabled")

else
if espPlayerAddedConn then espPlayerAddedConn:Disconnect() espPlayerAddedConn = nil end
clearESP()
notify("ESP", "Disabled")
end
end

------------------------------------------------
-- TRACERS
------------------------------------------------
local tracerGui

local function Tracers()
tracersEnabled = not tracersEnabled

if tracersEnabled then
if tracerGui then tracerGui:Destroy() end
tracerGui = Instance.new("ScreenGui")
tracerGui.ResetOnSpawn = false
tracerGui.Parent = playerGui

tracerConn = RS.RenderStepped:Connect(function()
for _, line in pairs(tracerLines) do line:Destroy() end
tracerLines = {}

for _, p in ipairs(Players:GetPlayers()) do
if p ~= player and p.Character then
local targetHRP = p.Character:FindFirstChild("HumanoidRootPart")
local targetHum = p.Character:FindFirstChild("Humanoid")

if targetHRP and targetHum and targetHum.Health > 0 then
local pos, visible = camera:WorldToViewportPoint(targetHRP.Position)
if visible then
local line = Instance.new("Frame")
line.BorderSizePixel = 0
line.BackgroundColor3 = Color3.new(1,0,0)

local origin = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
local target = Vector2.new(pos.X, pos.Y)
local diff = target - origin

line.AnchorPoint = Vector2.new(0,0.5)
line.Size = UDim2.new(0, diff.Magnitude, 0, 2)
line.Position = UDim2.new(0, origin.X, 0, origin.Y)
line.Rotation = math.deg(math.atan2(diff.Y, diff.X))

line.Parent = tracerGui
table.insert(tracerLines, line)
end
end
end
end
end)

notify("TRACERS", "Enabled")

else
if tracerConn then tracerConn:Disconnect() tracerConn = nil end
if tracerGui then tracerGui:Destroy() tracerGui = nil end
tracerLines = {}
notify("TRACERS", "Disabled")
end
end

------------------------------------------------
-- TELEPORT
------------------------------------------------
local function TeleportTo(name)
local target = findPlayer(name)
if not target then
notify("TP", "Player not found")
return
end
if target.Character and hrp then
local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
if targetHRP then
hrp.CFrame = targetHRP.CFrame + Vector3.new(3,0,0)
notify("TP", "Teleported to "..target.Name)
end
end
end

------------------------------------------------
-- DISCO LIGHTS
------------------------------------------------
local discoConn
local function Disco()
if discoConn then
discoConn:Disconnect()
discoConn = nil
Lighting.Ambient = Color3.fromRGB(127,127,127)
notify("DISCO", "Disabled")
else
discoConn = RS.RenderStepped:Connect(function()
Lighting.Ambient = Color3.fromHSV(tick() % 1, 1, 1)
end)
notify("DISCO", "Enabled")
end
end

------------------------------------------------
-- REJOIN
------------------------------------------------
local function Rejoin()
game:GetService("TeleportService"):Teleport(game.PlaceId, player)
end

------------------------------------------------
-- COMMANDS
------------------------------------------------
local commands = {}

commands.fly = Fly
commands.noclip = Noclip
commands.invis = Invisible
commands.speed = Speed
commands.jump = Jump
commands.freecam = Freecam
commands.clicktp = ClickTP
commands.esp = ESP
commands.tracers = Tracers
commands.tp = TeleportTo
commands.disco = Disco
commands.rejoin = Rejoin

------------------------------------------------
-- PROCESS COMMAND
------------------------------------------------
local function processCommand(text)
local success, err = pcall(function()
if string.sub(text,1,1) ~= PREFIX then return end
text = string.sub(text,2)
local split = text:split(" ")
local cmd = string.lower(split[1] or "")
table.remove(split,1)

if commands[cmd] then
commands[cmd](unpack(split))
else
notify("CMD", "Unknown command")
end
end)

if not success then
warn(err)
notify("ERROR", tostring(err))
end
end

------------------------------------------------
-- GUI / COMMAND BAR
------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "SCHubUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling -- ✅ FIX: proper UI layering
gui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0,400,0,60)
frame.Position = UDim2.new(0.5,-200,1,-80)
frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
frame.BorderSizePixel = 0
frame.Visible = true
frame.Parent = gui

local box = Instance.new("TextBox")
box.Size = UDim2.new(1,-10,1,-10)
box.Position = UDim2.new(0,5,0,5)
box.ClearTextOnFocus = false
box.Text = ""
box.PlaceholderText = ";command"
box.TextColor3 = Color3.new(1,1,1)
box.BackgroundColor3 = Color3.fromRGB(35,35,35)
box.BorderSizePixel = 0
box.Font = Enum.Font.Gotham
box.TextSize = 16
box.Parent = frame

------------------------------------------------
-- INPUT HANDLING
------------------------------------------------
box.FocusLost:Connect(function(enterPressed)
if enterPressed then
processCommand(box.Text)
box.Text = ""
end
end)

UIS.InputBegan:Connect(function(input, gameProcessed)
if gameProcessed then return end

-- Toggle GUI with RightShift
if input.KeyCode == Enum.KeyCode.RightShift then
frame.Visible = not frame.Visible
if frame.Visible then box:CaptureFocus() end
end

-- Escape clears text and unfocus
if input.KeyCode == Enum.KeyCode.Escape then
box.Text = ""
box:ReleaseFocus()
end
end)

------------------------------------------------
-- READY
------------------------------------------------
notify("SC HUB", "Loaded Successfully | Prefix: ; | RightShift to toggle")
