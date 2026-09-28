-- ╔══════════════════════════════════════════════════════════════╗
-- ║  SC HUB · GUNGAME EDITION · FULLY CLIENT-SIDE EXECUTOR VERSION
-- ║  Toggle: RightShift
-- ╚══════════════════════════════════════════════════════════════╝

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ═══════════════════════════════════════════════════════════════
-- CONFIG
-- ═══════════════════════════════════════════════════════════════
local CONFIG = {
	Name = "SC Hub",
	ToggleKey = Enum.KeyCode.RightShift,
	DefaultSpeed = 16,
	DefaultJump = 50,
	MaxSpeed = 250,
	MaxJump = 300,
	MaxFlySpeed = 250,
}

-- ═══════════════════════════════════════════════════════════════
-- STATE
-- ═══════════════════════════════════════════════════════════════
local Settings = {
	Fly = false,
	Noclip = false,
	Invisible = false,
	InfiniteJump = false,
	ESP = false,
	Fullbright = false,
	GodMode = false,
	WalkSpeed = CONFIG.DefaultSpeed,
	JumpPower = CONFIG.DefaultJump,
}

local Character, Humanoid, RootPart
local function refreshCharacter(c)
	Character = c
	Humanoid = c:WaitForChild("Humanoid")
	RootPart = c:WaitForChild("HumanoidRootPart")
end
refreshCharacter(LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait())
LocalPlayer.CharacterAdded:Connect(refreshCharacter)

-- ═══════════════════════════════════════════════════════════════
-- UI THEME
-- ═══════════════════════════════════════════════════════════════
local THEME = {
	Background = Color3.fromRGB(25, 25, 25),
	Topbar = Color3.fromRGB(34, 34, 34),
	Element = Color3.fromRGB(35, 35, 35),
	ElementHover = Color3.fromRGB(50, 50, 50),
	Stroke = Color3.fromRGB(55, 55, 55),
	Text = Color3.fromRGB(240, 240, 240),
	SubText = Color3.fromRGB(150, 150, 150),
	Accent = Color3.fromRGB(0, 146, 214),
	Off = Color3.fromRGB(100, 100, 100),
	Track = Color3.fromRGB(55, 55, 55),
}

local function make(className, props, parent)
	local obj = Instance.new(className)
	for k, v in pairs(props) do obj[k] = v end
	obj.Parent = parent
	return obj
end
local function corner(obj, r) make("UICorner", {CornerRadius = UDim.new(0, r)}, obj) end
local function outline(obj) make("UIStroke", {Color = THEME.Stroke, Thickness = 1}, obj) end
local function isPointer(i) return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch end
local function isPointerMove(i) return i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch end

-- ═══════════════════════════════════════════════════════════════
-- NOTIFICATIONS
-- ═══════════════════════════════════════════════════════════════
local Gui = make("ScreenGui", {Name="ScHub", ResetOnSpawn=false, IgnoreGuiInset=true, ZIndexBehavior=Enum.ZIndexBehavior.Sibling}, PlayerGui)
local NotifyHolder = make("Frame", {BackgroundTransparency=1, AnchorPoint=Vector2.new(1,1), Position=UDim2.new(1,-12,1,-12), Size=UDim2.new(0,270,1,-24)}, Gui)
make("UIListLayout", {Padding=UDim.new(0,8), SortOrder=Enum.SortOrder.LayoutOrder, VerticalAlignment=Enum.VerticalAlignment.Bottom, HorizontalAlignment=Enum.HorizontalAlignment.Right}, NotifyHolder)

local function notify(title, text, dur)
	local card = make("CanvasGroup", {BackgroundColor3=THEME.Topbar, Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y, GroupTransparency=1}, NotifyHolder)
	corner(card,8) outline(card)
	make("TextLabel", {BackgroundTransparency=1, Size=UDim2.new(1,0,0,16), Text=title, TextColor3=THEME.Text, Font=Enum.Font.GothamBold, TextSize=14, TextXAlignment=Enum.TextXAlignment.Left}, card)
	make("TextLabel", {BackgroundTransparency=1, Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y, Text=text, TextColor3=THEME.SubText, Font=Enum.Font.Gotham, TextSize=13, TextWrapped=true, TextXAlignment=Enum.TextXAlignment.Left}, card)
	TweenService:Create(card, TweenInfo.new(0.25), {GroupTransparency=0}):Play()
	task.delay(dur or 4, function()
		TweenService:Create(card, TweenInfo.new(0.3), {GroupTransparency=1}).Completed:Connect(function() card:Destroy() end)
	end)
end

-- ═══════════════════════════════════════════════════════════════
-- WINDOW
-- ═══════════════════════════════════════════════════════════════
local minimized = false
local Main = make("Frame", {AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.fromScale(0.5,0.5), Size=UDim2.new(0,500,0,400), BackgroundColor3=THEME.Background, ClipsDescendants=true}, Gui)
corner(Main,10) outline(Main)

local TopBar = make("Frame", {BackgroundColor3=THEME.Topbar, Size=UDim2.new(1,0,0,44)}, Main)
make("TextLabel", {BackgroundTransparency=1, Position=UDim2.new(16,0,0,0), Size=UDim2.new(1,-110,1,0), Text="SC Hub · EXECUTOR EDITION", TextColor3=THEME.Text, Font=Enum.Font.GothamBold, TextSize=16, TextXAlignment=Enum.TextXAlignment.Left}, TopBar)

local function topBtn(txt, x)
	local b = make("TextButton", {AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,x,0.5,0), Size=UDim2.fromOffset(30,30), BackgroundColor3=THEME.Element, Text=txt, TextColor3=THEME.Text, Font=Enum.Font.GothamBold, TextSize=14}, TopBar)
	corner(b,6) return b
end
local HideBtn = topBtn("X", -8)
local MinBtn = topBtn("—", -44)
local OpenBtn = make("TextButton", {Visible=false, Position=UDim2.new(10,0,0.4,0), Size=UDim2.fromOffset(84,34), BackgroundColor3=THEME.Topbar, Text="SC Hub", TextColor3=THEME.Text, Font=Enum.Font.GothamBold, TextSize=14}, Gui)
corner(OpenBtn,8) outline(OpenBtn)

local function setVis(v) Main.Visible = v; OpenBtn.Visible = not v end
HideBtn.Activated:Connect(function() setVis(false) end)
OpenBtn.Activated:Connect(function() setVis(true) end)
MinBtn.Activated:Connect(function() minimized = not minimized; Main.Size = UDim2.new(0,500,0,minimized and 44 or 400) end)

UIS.InputBegan:Connect(function(i, p)
	if not p and i.KeyCode == CONFIG.ToggleKey then setVis(not Main.Visible) end
end)

-- Drag
local dragStart, startPos
TopBar.InputBegan:Connect(function(i) if isPointer(i) then dragStart = i.Position; startPos = Main.Position end end)
UIS.InputChanged:Connect(function(i)
	if dragStart and isPointerMove(i) then
		local d = i.Position - dragStart
		Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X, startPos.Y.Scale, startPos.Y.Offset+d.Y)
	end
end)
UIS.InputEnded:Connect(function(i) if isPointer(i) then dragStart = nil end end)

-- ═══════════════════════════════════════════════════════════════
-- TABS SYSTEM
-- ═══════════════════════════════════════════════════════════════
local TabBar = make("ScrollingFrame", {BackgroundTransparency=1, Position=UDim2.new(8,0,48,0), Size=UDim2.new(1,-16,0,34), ScrollBarThickness=0, AutomaticCanvasSize=Enum.AutomaticSize.X}, Main)
make("UIListLayout", {FillDirection=Enum.FillDirection.Horizontal, Padding=UDim.new(0,6), SortOrder=Enum.SortOrder.LayoutOrder}, TabBar)
local Pages = make("Frame", {BackgroundTransparency=1, Position=UDim2.new(0,0,88,0), Size=UDim2.new(1,0,1,-88)}, Main)

local tabs = {}
local function selectTab(t)
	for _,tb in ipairs(tabs) do
		tb.Page.Visible = tb == t
		tb.Button.BackgroundColor3 = tb == t and THEME.Accent or THEME.Element
		tb.Button.TextColor3 = tb == t and Color3.new(1,1,1) or THEME.SubText
	end
end

local function createTab(name)
	local t = {}
	t.Button = make("TextButton", {Size=UDim2.new(0,0,0,28), AutomaticSize=Enum.AutomaticSize.X, BackgroundColor3=THEME.Element, Text=name, TextColor3=THEME.SubText, Font=Enum.Font.GothamMedium, TextSize=13}, TabBar)
	corner(t.Button,6)
	t.Page = make("ScrollingFrame", {Visible=false, BackgroundTransparency=1, Size=UDim2.fromScale(1,1), ScrollBarThickness=3, AutomaticCanvasSize=Enum.AutomaticSize.Y}, Pages)
	make("UIListLayout", {Padding=UDim.new(0,6), SortOrder=Enum.SortOrder.LayoutOrder}, t.Page)
	t.Button.Activated:Connect(function() selectTab(t) end)
	table.insert(tabs,t)
	if #tabs==1 then selectTab(t) end
	local order=0
	
	function t:CreateSection(n) order+=1; make("TextLabel", {LayoutOrder=order, BackgroundTransparency=1, Size=UDim2.new(1,0,0,26), Text=string.upper(n), TextColor3=THEME.SubText, Font=Enum.Font.GothamBold, TextSize=11, TextXAlignment=Enum.TextXAlignment.Left}, self.Page) end
	function t:CreateToggle(n, def, cb)
		order+=1
		local f = make("Frame", {LayoutOrder=order, Size=UDim2.new(1,0,0,40), BackgroundColor3=THEME.Element}, self.Page)
		corner(f,6) outline(f)
		make("TextLabel", {BackgroundTransparency=1, Position=UDim2.new(14,0,0,0), Size=UDim2.new(1,-84,1,0), Text=n, TextColor3=THEME.Text, Font=Enum.Font.GothamMedium, TextSize=14, TextXAlignment=Enum.TextXAlignment.Left}, f)
		local sw = make("Frame", {AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-12,0.5,0), Size=UDim2.fromOffset(42,22), BackgroundColor3=THEME.Off}, f)
		corner(sw,11)
		local k = make("Frame", {AnchorPoint=Vector2.new(0,0.5), Position=UDim2.new(0,3,0.5,0), Size=UDim2.fromOffset(16,16), BackgroundColor3=Color3.new(1,1,1)}, sw)
		corner(k,8)
		local val = def or false
		local function render()
			TweenService:Create(sw, TweenInfo.new(0.15), {BackgroundColor3=val and THEME.Accent or THEME.Off}):Play()
			TweenService:Create(k, TweenInfo.new(0.15), {Position=val and UDim2.new(1,-19,0.5,0) or UDim2.new(0,3,0.5,0)}):Play()
		end
		make("TextButton", {BackgroundTransparency=1, Text="", Size=UDim2.fromScale(1,1), Parent=f}).Activated:Connect(function()
			val = not val; render(); cb(val)
		end)
		render()
	end
	function t:CreateSlider(n, min, max, def, cb)
		order+=1
		local f = make("Frame", {LayoutOrder=order, Size=UDim2.new(1,0,0,58), BackgroundColor3=THEME.Element}, self.Page)
		corner(f,6) outline(f)
		make("TextLabel", {BackgroundTransparency=1, Position=UDim2.new(14,0,0,0), Size=UDim2.new(1,-100,0,34), Text=n, TextColor3=THEME.Text, Font=Enum.Font.GothamMedium, TextSize=14, TextXAlignment=Enum.TextXAlignment.Left}, f)
		local vl = make("TextLabel", {BackgroundTransparency=1, AnchorPoint=Vector2.new(1,0), Position=UDim2.new(1,-14,0,0), Size=UDim2.fromOffset(80,34), Text=tostring(def), TextColor3=THEME.SubText, Font=Enum.Font.Gotham, TextSize=13, TextXAlignment=Enum.TextXAlignment.Right}, f)
		local tr = make("Frame", {Position=UDim2.new(14,0,40,0), Size=UDim2.new(1,-28,0,8), BackgroundColor3=THEME.Track}, f)
		corner(tr,4)
		local fill = make("Frame", {Size=UDim2.new(0,1), BackgroundColor3=THEME.Accent}, tr)
		corner(fill,4)
		local val = def
		local function render()
			local p = (val-min)/(max-min)
			fill.Size = UDim2.new(p,0,1,0)
			vl.Text = tostring(math.floor(val*10)/10)
		end
		local drag = false
		tr.InputBegan:Connect(function(i) if isPointer(i) then drag=true end end)
		UIS.InputChanged:Connect(function(i)
			if drag and isPointerMove(i) then
				local p = math.clamp((i.Position.X-tr.AbsolutePosition.X)/tr.AbsoluteSize.X,0,1)
				val = min + (max-min)*p
				render(); cb(val)
			end
		end)
		UIS.InputEnded:Connect(function() drag=false end)
		render()
	end
	function t:CreateButton(n, cb)
		order+=1
		local f = make("Frame", {LayoutOrder=order, Size=UDim2.new(1,0,0,40), BackgroundColor3=THEME.Element}, self.Page)
		corner(f,6) outline(f)
		make("TextLabel", {BackgroundTransparency=1, Position=UDim2.new(14,0,0,0), Size=UDim2.new(1,-28,1,0), Text=n, TextColor3=THEME.Text, Font=Enum.Font.GothamMedium, TextSize=14, TextXAlignment=Enum.TextXAlignment.Left}, f)
		make("TextButton", {BackgroundTransparency=1, Text="", Size=UDim2.fromScale(1,1), Parent=f}).Activated:Connect(function()
			TweenService:Create(f, TweenInfo.new(0.1), {BackgroundColor3=THEME.ElementHover}):Play()
			task.delay(0.12, function() TweenService:Create(f, TweenInfo.new(0.2), {BackgroundColor3=THEME.Element}):Play() end)
			cb()
		end)
	end
end

-- ═══════════════════════════════════════════════════════════════
-- FEATURES
-- ═══════════════════════════════════════════════════════════════

-- FLY
local flyParts, flySpeed = nil, 60
local flyUp, flyDown = false, false
local function stopFly() if flyParts then flyParts.Velocity:Destroy(); flyParts.Align:Destroy(); flyParts.Attachment:Destroy(); flyParts=nil end; if Humanoid then Humanoid.PlatformStand=false end end
local function startFly() stopFly()
	if not RootPart then return end
	local att = make("Attachment", {}, RootPart)
	local vel = make("LinearVelocity", {Attachment0=att, MaxForce=math.huge, VelocityConstraintMode=Enum.VelocityConstraintMode.Vector, RelativeTo=Enum.ActuatorRelativeTo.World, VectorVelocity=Vector3.zero}, RootPart)
	local align = make("AlignOrientation", {Mode=Enum.OrientationAlignmentMode.OneAttachment, Attachment0=att, RigidityEnabled=true}, RootPart)
	Humanoid.PlatformStand = true
	flyParts = {Attachment=att, Velocity=vel, Align=align}
end

-- NOCLIP
RunService.Stepped:Connect(function()
	if Settings.Noclip and Character then
		for _,v in ipairs(Character:GetDescendants()) do
			if v:IsA("BasePart") then v.CanCollide = false end
		end
	end
end)

-- INVISIBLE
local function setInvis(b)
	if not Character then return end
	for _,v in ipairs(Character:GetDescendants()) do
		if v:IsA("BasePart") then v.LocalTransparencyModifier = b and 1 or 0 end
		if v:IsA("Decal") then v.Transparency = b and 1 or 0 end
	end
end

-- INFINITE JUMP
UIS.JumpRequest:Connect(function()
	if Settings.InfiniteJump and Humanoid then Humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
end)

-- GOD MODE (client-side visual only)
local origMaxHealth = 100
local godConn = nil
local function setGod(b)
	if not Humanoid then return end
	if b then
		origMaxHealth = Humanoid.MaxHealth
		Humanoid.MaxHealth = math.huge
		godConn = Humanoid.HealthChanged:Connect(function() Humanoid.Health = Humanoid.MaxHealth end)
	else
		if godConn then godConn:Disconnect() end
		Humanoid.MaxHealth = origMaxHealth
		Humanoid.Health = Humanoid.MaxHealth
	end
end

-- FULLBRIGHT
local savedLighting = nil
local function setFullbright(b)
	if b then
		savedLighting = {Brightness=Lighting.Brightness, ClockTime=Lighting.ClockTime, FogEnd=Lighting.FogEnd, GlobalShadows=Lighting.GlobalShadows}
		Lighting.Brightness=2; Lighting.ClockTime=14; Lighting.FogEnd=1e6; Lighting.GlobalShadows=false
	elseif savedLighting then
		Lighting.Brightness=savedLighting.Brightness; Lighting.ClockTime=savedLighting.ClockTime
		Lighting.FogEnd=savedLighting.FogEnd; Lighting.GlobalShadows=savedLighting.GlobalShadows
	end
end

-- ESP
local espObjects = {}
local function clearESP() for _,v in pairs(espObjects) do v.Highlight:Destroy() end; table.clear(espObjects) end
local function refreshESP() clearESP()
	if not Settings.ESP then return end
	for _,p in ipairs(Players:GetPlayers()) do
		if p~=LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
			local hl = make("Highlight", {Name="ScHubESP", Adornee=p.Character, DepthMode=Enum.HighlightDepthMode.AlwaysOnTop, FillColor=THEME.Accent, OutlineColor=Color3.new(1,1,1), FillTransparency=0.6, OutlineTransparency=0}, p.Character)
			espObjects[p] = {Highlight=hl}
		end
	end
end

-- FLY LOOP
RunService.RenderStepped:Connect(function()
	if Settings.Fly and flyParts and RootPart then
		local cam = Workspace.CurrentCamera
		local dir = Humanoid.MoveDirection
		local v = cam.CFrame:VectorToWorldSpace(dir)
		if UIS:IsKeyDown(Enum.KeyCode.Space) then v += Vector3.new(0,1,0) end
		if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then v -= Vector3.new(0,1,0) end
		if v.Magnitude>0 then v=v.Unit end
		flyParts.Velocity.VectorVelocity = v * flySpeed
	end
end)

-- SPEED/JUMP APPLY
RunService.Heartbeat:Connect(function()
	if Humanoid then
		Humanoid.WalkSpeed = Settings.WalkSpeed
		Humanoid.JumpPower = Settings.JumpPower
	end
end)

-- ═══════════════════════════════════════════════════════════════
-- BUILD TABS
-- ═══════════════════════════════════════════════════════════════

local SelfTab = createTab("Self")
SelfTab:CreateSection("Movement")
SelfTab:CreateToggle("Fly", false, function(b) Settings.Fly=b; if b then startFly() else stopFly() end; notify("SC Hub", b and "Fly ON" or "Fly OFF") end)
SelfTab:CreateToggle("Noclip", false, function(b) Settings.Noclip=b; notify("SC Hub", b and "Noclip ON" or "Noclip OFF") end)
SelfTab:CreateToggle("Invisible", false, function(b) Settings.Invisible=b; setInvis(b); notify("SC Hub", b and "Invisible ON" or "Invisible OFF") end)
SelfTab:CreateToggle("Infinite Jump", false, function(b) Settings.InfiniteJump=b; notify("SC Hub", b and "Infinite Jump ON" or "OFF") end)
SelfTab:CreateToggle("God Mode (Visual)", false, function(b) Settings.GodMode=b; setGod(b); notify("SC Hub", b and "God ON" or "God OFF") end)
SelfTab:CreateSlider("Walk Speed", 16, 250, 16, function(v) Settings.WalkSpeed=v end)
SelfTab:CreateSlider("Jump Power", 50, 300, 50, function(v) Settings.JumpPower=v end)
SelfTab:CreateSlider("Fly Speed", 10, 250, 60, function(v) flySpeed=v end)
SelfTab:CreateButton("Reset All", function()
	Settings.WalkSpeed=16; Settings.JumpPower=50; Settings.Fly=false; Settings.Noclip=false; Settings.Invisible=false; Settings.InfiniteJump=false; Settings.GodMode=false
	stopFly(); setInvis(false); setGod(false); notify("SC Hub", "Reset done")
end)

local VisualTab = createTab("Visual")
VisualTab:CreateSection("Effects")
VisualTab:CreateToggle("Player ESP", false, function(b) Settings.ESP=b; refreshESP() end)
VisualTab:CreateToggle("Fullbright", false, setFullbright)
VisualTab:CreateSlider("FOV", 40, 120, 70, function(v) Workspace.CurrentCamera.FieldOfView=v end)

local PlayerTab = createTab("Players")
PlayerTab:CreateSection("Quick Actions")
PlayerTab:CreateButton("Teleport to Mouse", function()
	local cam = Workspace.CurrentCamera
	local m = UIS:GetMouseLocation()
	local ray = cam:ViewportPointToRay(m.X, m.Y)
	local res = workspace:Raycast(ray.Origin, ray.Direction*500)
	if res and RootPart then RootPart.CFrame = CFrame.new(res.Position + Vector3.new(0,2,0)) end
end)
PlayerTab:CreateButton("Bring Closest Player", function()
	local closest, dist, pos = nil, math.huge, RootPart and RootPart.Position or Vector3.zero
	for _,p in ipairs(Players:GetPlayers()) do
		if p~=LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
			local d = (p.Character.HumanoidRootPart.Position - pos).Magnitude
			if d<dist then dist=d; closest=p end
		end
	end
	if closest and closest.Character and RootPart then
		closest.Character.HumanoidRootPart.CFrame = RootPart.CFrame * CFrame.new(0,0,-5)
		notify("SC Hub", "Brought "..closest.DisplayName)
	end
end)
PlayerTab:CreateButton("Kill Self", function() if Humanoid then Humanoid.Health=0 end end)

-- ═══════════════════════════════════════════════════════════════
-- START
-- ═══════════════════════════════════════════════════════════════
notify("SC Hub", "Loaded! Press RightShift to toggle", 4)
print("[SC Hub] Executor client-side loaded")
