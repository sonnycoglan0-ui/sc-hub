══════════════════════════════════════════════════════════════════
	  SC HUB  ·  MERGED WITH GEM FARMER v6.5
	  Gem farmer functionality 100% preserved — only a new tab added.
	══════════════════════════════════════════════════════════════════
]]

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

if RunService:IsServer() then
	warn("[Sc Hub] Must be a LocalScript.")
	return
end

--------------------------------------------------------------------
-- CONFIG
--------------------------------------------------------------------

local CONFIG = {
	Name = "SC Hub",
	ToggleKey = Enum.KeyCode.RightShift,
	DefaultSpeed = 16,
	DefaultJump = 50,
	MaxSpeed = 250,
	MaxJump = 300,
	MaxFlySpeed = 250,
	MaxFreecamSpeed = 300,
	MaxRecordSeconds = 300,
	RecordRate = 30,
	Hotkeys = {
		Fly = Enum.KeyCode.F,
		Noclip = Enum.KeyCode.N,
		ESP = Enum.KeyCode.B,
		Freecam = Enum.KeyCode.P,
		AimLock = Enum.KeyCode.V,
		Record = Enum.KeyCode.Y,
		Play = Enum.KeyCode.U,
	},
}

local function runClient()
	local TweenService = game:GetService("TweenService")
	local UserInputService = game:GetService("UserInputService")
	local Lighting = game:GetService("Lighting")
	local Workspace = game:GetService("Workspace")
	local Stats = game:GetService("Stats")

	local LocalPlayer = Players.LocalPlayer
	local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

	while not Workspace.CurrentCamera do task.wait() end

	local existing = PlayerGui:FindFirstChild("ScHub")
	if existing then existing:Destroy() end

	local THEME = {
		Background = Color3.fromRGB(25,25,25),
		Topbar = Color3.fromRGB(34,34,34),
		Element = Color3.fromRGB(35,35,35),
		ElementHover = Color3.fromRGB(50,50,50),
		Stroke = Color3.fromRGB(55,55,55),
		Text = Color3.fromRGB(240,240,240),
		SubText = Color3.fromRGB(150,150,150),
		Accent = Color3.fromRGB(0,146,214),
		Off = Color3.fromRGB(100,100,100),
		Track = Color3.fromRGB(55,55,55),
	}

	local connections = {}
	local function connect(signal, callback)
		local c = signal:Connect(callback)
		table.insert(connections, c)
		return c
	end
	local function safeCall(callback, ...)
		if callback then
			local ok, err = pcall(callback, ...)
			if not ok then warn("["..CONFIG.Name.."] "..tostring(err)) end
		end
	end
	local function make(className, props, parent)
		local o = Instance.new(className)
		for k,v in pairs(props) do o[k]=v end
		o.Parent = parent
		return o
	end
	local function corner(o, r) return make("UICorner",{CornerRadius=UDim.new(0,r)},o) end
	local function outline(o) return make("UIStroke",{Color=THEME.Stroke,Thickness=1,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},o) end
	local function padding(o,l,t,r,b) return make("UIPadding",{PaddingLeft=UDim.new(0,l),PaddingTop=UDim.new(0,t),PaddingRight=UDim.new(0,r),PaddingBottom=UDim.new(0,b)},o) end
	local function isPointer(i) return i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch end
	local function isPointerMove(i) return i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch end

	local Gui = make("ScreenGui",{Name="ScHub",ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=100,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},PlayerGui)

	local function buildBuiltInUI()
		local NotifyHolder = make("Frame",{BackgroundTransparency=1,AnchorPoint=Vector2.new(1,1),Position=UDim2.new(1,-12,1,-12),Size=UDim2.new(0,270,1,-24),ZIndex=50},Gui)
		make("UIListLayout",{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder,VerticalAlignment=Enum.VerticalAlignment.Bottom,HorizontalAlignment=Enum.HorizontalAlignment.Right},NotifyHolder)
		local function notify(data)
			if not Gui.Parent then return end
			local card = make("CanvasGroup",{BackgroundColor3=THEME.Topbar,BorderSizePixel=0,Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,GroupTransparency=1},NotifyHolder)
			corner(card,8); outline(card); padding(card,12,10,12,10)
			make("UIListLayout",{Padding=UDim.new(0,3),SortOrder=Enum.SortOrder.LayoutOrder},card)
			make("TextLabel",{LayoutOrder=1,BackgroundTransparency=1,Size=UDim2.new(1,0,0,16),Text=data.Title or CONFIG.Name,TextColor3=THEME.Text,Font=Enum.Font.GothamBold,TextSize=14,TextXAlignment=Enum.TextXAlignment.Left},card)
			make("TextLabel",{LayoutOrder=2,BackgroundTransparency=1,Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,Text=data.Content or "",TextColor3=THEME.SubText,Font=Enum.Font.Gotham,TextSize=13,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left},card)
			TweenService:Create(card,TweenInfo.new(0.25),{GroupTransparency=0}):Play()
			task.delay(data.Duration or 4,function()
				if card.Parent then
					local t = TweenService:Create(card,TweenInfo.new(0.3),{GroupTransparency=1})
					t.Completed:Connect(function() card:Destroy() end)
					t:Play()
				end
			end)
		end

		local function windowSize()
			local vp = Workspace.CurrentCamera.ViewportSize
			return math.min(500,vp.X*0.94), math.min(470,vp.Y*0.8)
		end
		local width,height = windowSize()
		local minimized = false

		local Main = make("Frame",{Name="Main",AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(width,height),BackgroundColor3=THEME.Background,BorderSizePixel=0,ClipsDescendants=true},Gui)
		corner(Main,10); outline(Main)
		local TopBar = make("Frame",{BackgroundColor3=THEME.Topbar,BorderSizePixel=0,Size=UDim2.new(1,0,0,44)},Main)
		make("TextLabel",{BackgroundTransparency=1,Position=UDim2.fromOffset(16,0),Size=UDim2.new(1,-110,1,0),Text=CONFIG.Name.."   ·   FREE ACCESS",TextColor3=THEME.Text,Font=Enum.Font.GothamBold,TextSize=16,TextXAlignment=Enum.TextXAlignment.Left},TopBar)

		local function topButton(text,ro)
			local b = make("TextButton",{AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,ro,0.5,0),Size=UDim2.fromOffset(30,30),BackgroundColor3=THEME.Element,BorderSizePixel=0,Text=text,TextColor3=THEME.Text,Font=Enum.Font.GothamBold,TextSize=14},TopBar)
			corner(b,6); return b
		end
		local HideButton = topButton("X",-8)
		local MinimizeButton = topButton("—",-44)
		local OpenButton = make("TextButton",{Visible=false,AnchorPoint=Vector2.new(0,0.5),Position=UDim2.new(0,10,0.4,0),Size=UDim2.fromOffset(84,34),BackgroundColor3=THEME.Topbar,BorderSizePixel=0,Text=CONFIG.Name,TextColor3=THEME.Text,Font=Enum.Font.GothamBold,TextSize=14},Gui)
		corner(OpenButton,8); outline(OpenButton)

		local function setVisible(v) Main.Visible=v; OpenButton.Visible=not v end
		HideButton.Activated:Connect(function() setVisible(false) end)
		OpenButton.Activated:Connect(function() setVisible(true) end)
		MinimizeButton.Activated:Connect(function() minimized=not minimized; Main.Size=UDim2.fromOffset(width,minimized and 44 or height) end)
		connect(UserInputService.InputBegan,function(input,processed)
			if not processed and input.KeyCode==CONFIG.ToggleKey then setVisible(not Main.Visible) end
		end)
		connect(Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"),function()
			width,height=windowSize(); Main.Size=UDim2.fromOffset(width,minimized and 44 or height)
		end)

		local dragStart, startPosition
		TopBar.InputBegan:Connect(function(input) if isPointer(input) then dragStart=input.Position; startPosition=Main.Position end end)
		connect(UserInputService.InputChanged,function(input)
			if dragStart and isPointerMove(input) then
				local delta = input.Position - dragStart
				Main.Position = UDim2.new(startPosition.X.Scale,startPosition.X.Offset+delta.X,startPosition.Y.Scale,startPosition.Y.Offset+delta.Y)
			end
		end)
		connect(UserInputService.InputEnded,function(input) if dragStart and isPointer(input) then dragStart=nil end end)

		local TabBar = make("ScrollingFrame",{BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.fromOffset(8,48),Size=UDim2.new(1,-16,0,34),ScrollBarThickness=0,ScrollingDirection=Enum.ScrollingDirection.X,AutomaticCanvasSize=Enum.AutomaticSize.X,CanvasSize=UDim2.new()},Main)
		make("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder,VerticalAlignment=Enum.VerticalAlignment.Center},TabBar)
		local Pages = make("Frame",{BackgroundTransparency=1,Position=UDim2.fromOffset(0,88),Size=UDim2.new(1,0,1,-88)},Main)
		local tabs = {}

		local function selectTab(selected)
			for _,tab in ipairs(tabs) do
				local active = tab==selected
				tab.Page.Visible = active
				tab.Button.BackgroundColor3 = active and THEME.Accent or THEME.Element
				tab.Button.TextColor3 = active and Color3.new(1,1,1) or THEME.SubText
			end
		end

		local function createTab(name)
			local Tab = {}
			local button = make("TextButton",{LayoutOrder=#tabs+1,Size=UDim2.new(0,0,0,28),AutomaticSize=Enum.AutomaticSize.X,BackgroundColor3=THEME.Element,BorderSizePixel=0,AutoButtonColor=false,Text=name,TextColor3=THEME.SubText,Font=Enum.Font.GothamMedium,TextSize=13},TabBar)
			corner(button,6); padding(button,14,0,14,0)
			local page = make("ScrollingFrame",{Visible=false,BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.fromScale(1,1),ScrollBarThickness=3,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new()},Pages)
			padding(page,10,4,12,12)
			make("UIListLayout",{Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder},page)
			Tab.Button=button; Tab.Page=page; table.insert(tabs,Tab)
			button.Activated:Connect(function() selectTab(Tab) end)
			if #tabs==1 then selectTab(Tab) end
			local order = 0
			local function newElement(h)
				order+=1
				local f = make("Frame",{LayoutOrder=order,Size=UDim2.new(1,0,0,h),BackgroundColor3=THEME.Element,BorderSizePixel=0},page)
				corner(f,6); outline(f); return f
			end
			local function elementTitle(parent,text,rr)
				return make("TextLabel",{BackgroundTransparency=1,Position=UDim2.fromOffset(14,0),Size=UDim2.new(1,-(14+(rr or 14)),0,40),Text=text,TextColor3=THEME.Text,Font=Enum.Font.GothamMedium,TextSize=14,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd},parent)
			end
			function Tab:CreateSection(sn)
				order+=1
				make("TextLabel",{LayoutOrder=order,BackgroundTransparency=1,Size=UDim2.new(1,0,0,26),Text=string.upper(sn),TextColor3=THEME.SubText,Font=Enum.Font.GothamBold,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left},page)
			end
			function Tab:CreateLabel(text)
				local f = newElement(34)
				local label = make("TextLabel",{BackgroundTransparency=1,Position=UDim2.fromOffset(14,0),Size=UDim2.new(1,-28,1,0),Text=text,TextColor3=THEME.SubText,Font=Enum.Font.Gotham,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd},f)
				local o = {}
				function o:Set(nt) label.Text=nt end
				return o
			end
			function Tab:CreateButton(opts)
				local f = newElement(40)
				elementTitle(f, opts.Name)
				local click = make("TextButton",{BackgroundTransparency=1,Text="",Size=UDim2.fromScale(1,1)},f)
				click.Activated:Connect(function()
					TweenService:Create(f,TweenInfo.new(0.1),{BackgroundColor3=THEME.ElementHover}):Play()
					task.delay(0.12,function() if f.Parent then TweenService:Create(f,TweenInfo.new(0.2),{BackgroundColor3=THEME.Element}):Play() end end)
					safeCall(opts.Callback)
				end)
				return {}
			end
			function Tab:CreateToggle(opts)
				local f = newElement(40)
				elementTitle(f, opts.Name, 70)
				local sw = make("Frame",{AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-12,0.5,0),Size=UDim2.fromOffset(42,22),BackgroundColor3=THEME.Off,BorderSizePixel=0},f)
				corner(sw,11)
				local knob = make("Frame",{AnchorPoint=Vector2.new(0,0.5),Position=UDim2.new(0,3,0.5,0),Size=UDim2.fromOffset(16,16),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0},sw)
				corner(knob,8)
				local click = make("TextButton",{BackgroundTransparency=1,Text="",Size=UDim2.fromScale(1,1)},f)
				local toggle = {CurrentValue=opts.CurrentValue==true}
				local function render(instant)
					local info = TweenInfo.new(instant and 0 or 0.15)
					TweenService:Create(sw,info,{BackgroundColor3=toggle.CurrentValue and THEME.Accent or THEME.Off}):Play()
					TweenService:Create(knob,info,{Position=toggle.CurrentValue and UDim2.new(1,-19,0.5,0) or UDim2.new(0,3,0.5,0)}):Play()
				end
				function toggle:Set(value,silent)
					self.CurrentValue = value and true or false
					render()
					if not silent then safeCall(opts.Callback,self.CurrentValue) end
				end
				click.Activated:Connect(function() toggle:Set(not toggle.CurrentValue) end)
				render(true)
				return toggle
			end
			function Tab:CreateSlider(opts)
				local mn,mx = opts.Range[1],opts.Range[2]
				local inc = opts.Increment or 1
				local f = newElement(58)
				elementTitle(f,opts.Name,110).Size=UDim2.new(1,-124,0,34)
				local valueLabel = make("TextLabel",{BackgroundTransparency=1,AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-14,0,0),Size=UDim2.fromOffset(100,34),TextColor3=THEME.SubText,Font=Enum.Font.Gotham,TextSize=13,TextXAlignment=Enum.TextXAlignment.Right},f)
				local track = make("Frame",{Position=UDim2.new(0,14,0,40),Size=UDim2.new(1,-28,0,8),BackgroundColor3=THEME.Track,BorderSizePixel=0},f)
				corner(track,4)
				local fill = make("Frame",{Size=UDim2.fromScale(0,1),BackgroundColor3=THEME.Accent,BorderSizePixel=0},track)
				corner(fill,4)
				local hit = make("TextButton",{BackgroundTransparency=1,Text="",Position=UDim2.new(0,8,0,30),Size=UDim2.new(1,-16,0,28)},f)
				local slider = {CurrentValue=opts.CurrentValue or mn}
				local function snap(value)
					value=math.clamp(value,mn,mx)
					value=mn+math.floor((value-mn)/inc+0.5)*inc
					value=math.floor(value*1000+0.5)/1000
					return math.clamp(value,mn,mx)
				end
				local function render()
					local alpha = mx>mn and (slider.CurrentValue-mn)/(mx-mn) or 0
					fill.Size=UDim2.fromScale(alpha,1)
					valueLabel.Text=tostring(slider.CurrentValue)..(opts.Suffix and (" "..opts.Suffix) or "")
				end
				function slider:Set(value,silent)
					self.CurrentValue=snap(value); render()
					if not silent then safeCall(opts.Callback,self.CurrentValue) end
				end
				local dragging=false
				local function updateFromInput(input)
					local alpha=math.clamp((input.Position.X-track.AbsolutePosition.X)/math.max(track.AbsoluteSize.X,1),0,1)
					local value=snap(mn+(mx-mn)*alpha)
					if value~=slider.CurrentValue then slider:Set(value) end
				end
				hit.InputBegan:Connect(function(input) if isPointer(input) then dragging=true; page.ScrollingEnabled=false; updateFromInput(input) end end)
				connect(UserInputService.InputChanged,function(input) if dragging and isPointerMove(input) then updateFromInput(input) end end)
				connect(UserInputService.InputEnded,function(input) if dragging and isPointer(input) then dragging=false; page.ScrollingEnabled=true end end)
				slider.CurrentValue=snap(slider.CurrentValue); render()
				return slider
			end
			function Tab:CreateInput(opts)
				local f = newElement(40)
				elementTitle(f,opts.Name,0).Size=UDim2.new(0.4,0,0,40)
				local box = make("TextBox",{AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-8,0.5,0),Size=UDim2.new(0.6,-16,0,28),BackgroundColor3=Color3.fromRGB(28,28,28),BorderSizePixel=0,PlaceholderText=opts.PlaceholderText or "",PlaceholderColor3=THEME.SubText,Text="",TextColor3=THEME.Text,Font=Enum.Font.Gotham,TextSize=13,ClearTextOnFocus=false,ClipsDescendants=true},f)
				corner(box,5); padding(box,8,0,8,0)
				box.FocusLost:Connect(function() safeCall(opts.Callback,box.Text); if opts.RemoveTextAfterFocusLost then box.Text="" end end)
				local input = {}
				function input:Get() return box.Text end
				function input:Set(t) box.Text=t end
				return input
			end
			function Tab:CreateDropdown(opts)
				local ROW,GAP,MAX_ROWS=30,3,5
				local f = newElement(40); f.ClipsDescendants=true
				local dropdown = {Options=opts.Options or {},CurrentOption=opts.CurrentOption or {}}
				local title = elementTitle(f,opts.Name,40)
				make("TextLabel",{BackgroundTransparency=1,AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-14,0,0),Size=UDim2.fromOffset(20,40),Text="▼",TextColor3=THEME.SubText,Font=Enum.Font.GothamBold,TextSize=11},f)
				local header = make("TextButton",{BackgroundTransparency=1,Text="",Size=UDim2.new(1,0,0,40)},f)
				local list = make("ScrollingFrame",{BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.fromOffset(6,44),Size=UDim2.new(1,-12,0,0),ScrollBarThickness=3,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new()},f)
				make("UIListLayout",{Padding=UDim.new(0,GAP),SortOrder=Enum.SortOrder.LayoutOrder},list)
				local open=false
				local function updateTitle() title.Text=opts.Name..":  "..(dropdown.CurrentOption[1] or "None") end
				local function resize()
					if open then
						local rows=math.min(#dropdown.Options,MAX_ROWS)
						local lh=rows*ROW+math.max(rows-1,0)*GAP
						list.Size=UDim2.new(1,-12,0,lh); f.Size=UDim2.new(1,0,0,44+lh+6)
					else
						list.Size=UDim2.new(1,-12,0,0); f.Size=UDim2.new(1,0,0,40)
					end
				end
				local function rebuild()
					for _,child in ipairs(list:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
					for index,option in ipairs(dropdown.Options) do
						local row = make("TextButton",{LayoutOrder=index,Size=UDim2.new(1,-6,0,ROW),BackgroundColor3=THEME.Topbar,BorderSizePixel=0,AutoButtonColor=false,Text=tostring(option),TextColor3=THEME.Text,Font=Enum.Font.Gotham,TextSize=13,TextTruncate=Enum.TextTruncate.AtEnd},list)
						corner(row,5)
						row.Activated:Connect(function() dropdown:Set(option); open=false; resize() end)
					end
					resize()
				end
				function dropdown:Set(option,silent)
					self.CurrentOption=option and {option} or {}; updateTitle()
					if not silent then safeCall(opts.Callback,self.CurrentOption) end
				end
				function dropdown:Refresh(newOptions)
					self.Options=newOptions
					local cur=self.CurrentOption[1]
					if cur and not table.find(newOptions,cur) then self:Set(nil) end
					rebuild()
				end
				header.Activated:Connect(function() open=not open; resize() end)
				updateTitle(); rebuild()
				return dropdown
			end
			return Tab
		end
		return {CreateTab=createTab,Notify=notify,Destroy=function() end}
	end

	local function loadRayfield()
		local ok, library = pcall(function() return loadstring(game:HttpGet("https://sirius.menu/rayfield"))() end)
		if ok and type(library)=="table" and library.CreateWindow then return library end
		return nil
	end
	local Rayfield = loadRayfield()
	local UI = nil
	local usingRayfield = false
	if Rayfield then
		local ok, window = pcall(function()
			return Rayfield:CreateWindow({
				Name=CONFIG.Name,LoadingTitle=CONFIG.Name,LoadingSubtitle="Free access",Theme="Default",
				ToggleUIKeybind=CONFIG.ToggleKey.Name,DisableRayfieldPrompts=true,DisableBuildWarnings=true,
				ConfigurationSaving={Enabled=false},KeySystem=false,
			})
		end)
		if ok and window then
			usingRayfield=true
			UI = {
				CreateTab=function(name) return window:CreateTab(name) end,
				Notify=function(data) pcall(function() Rayfield:Notify({Title=data.Title or CONFIG.Name,Content=data.Content or "",Duration=data.Duration or 4}) end) end,
				Destroy=function() pcall(function() Rayfield:Destroy() end) end,
			}
		end
	end
	if not UI then UI = buildBuiltInUI() end
	local function notify(data) UI.Notify(data) end
	local function createTab(name) return UI.CreateTab(name) end

	local StarterPlayer = game:GetService("StarterPlayer")
	local TeleportService = game:GetService("TeleportService")

	local State = {Target=nil,CustomSpeed=nil,CustomJump=nil,Fly=false,FlySpeed=60,Noclip=false,InfiniteJump=false,ClickTeleport=false,AntiAfk=false,ESP=false,Freecam=false,FreecamSpeed=60,PadUp=false,PadDown=false}
	local Toggles = {}
	local Resetters = {}

	local function getCharacter()
		local c = LocalPlayer.Character
		if not c then return nil,nil,nil end
		return c, c:FindFirstChildOfClass("Humanoid"), c:FindFirstChild("HumanoidRootPart")
	end
	local function starterValue(name,fb)
		local ok,v = pcall(function() return StarterPlayer[name] end)
		if ok and v~=nil then return v end
		return fb
	end

	local getControls, getMoveVector
	do
		local controls=nil; local failed=false
		getControls=function()
			if controls or failed then return controls end
			local ok,res = pcall(function()
				local m = LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule",5)
				return m and require(m):GetControls()
			end)
			if ok and res then controls=res else failed=true end
			return controls
		end
		getMoveVector=function()
			if controls then return controls:GetMoveVector() end
			if UserInputService:GetFocusedTextBox() then return Vector3.zero end
			local x = (UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0)-(UserInputService:IsKeyDown(Enum.KeyCode.A) and 1 or 0)
			local z = (UserInputService:IsKeyDown(Enum.KeyCode.S) and 1 or 0)-(UserInputService:IsKeyDown(Enum.KeyCode.W) and 1 or 0)
			return Vector3.new(x,0,z)
		end
	end

	local function getVerticalInput()
		local v=0
		if not UserInputService:GetFocusedTextBox() then
			if UserInputService:IsKeyDown(Enum.KeyCode.Space) or UserInputService:IsKeyDown(Enum.KeyCode.E) then v+=1 end
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.Q) then v-=1 end
		end
		if State.PadUp then v+=1 end
		if State.PadDown then v-=1 end
		return v
	end

	local FlyPad = make("Frame",{Visible=false,BackgroundTransparency=1,AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-16,0.5,0),Size=UDim2.fromOffset(64,136)},Gui)
	make("UIListLayout",{Padding=UDim.new(0,8),HorizontalAlignment=Enum.HorizontalAlignment.Center},FlyPad)
	local function padButton(text,sk)
		local activeInput=nil
		local b = make("TextButton",{Size=UDim2.fromOffset(64,64),BackgroundColor3=THEME.Accent,BackgroundTransparency=0.25,BorderSizePixel=0,Text=text,TextColor3=Color3.new(1,1,1),Font=Enum.Font.GothamBold,TextSize=22},FlyPad)
		corner(b,12)
		b.InputBegan:Connect(function(input) if isPointer(input) then activeInput=input; State[sk]=true end end)
		b.InputEnded:Connect(function(input) if isPointer(input) then activeInput=nil; State[sk]=false end end)
		connect(UserInputService.InputEnded,function(input) if activeInput and input==activeInput then activeInput=nil; State[sk]=false end end)
	end
	padButton("▲","PadUp"); padButton("▼","PadDown")
	local function refreshFlyPad()
		local show = (State.Fly or State.Freecam) and UserInputService.TouchEnabled
		FlyPad.Visible = show and true or false
		if not show then State.PadUp,State.PadDown=false,false end
	end

	----------------------------------------------------------------
	-- TABS (Gem Farmer tab added — everything else unchanged)
	----------------------------------------------------------------
	local PlayersTab = createTab("Players")
	local SelfTab = createTab("Self")
	local TeleportTab = createTab("Teleport")
	local VisualTab = createTab("Visual")
	local AimTab = createTab("Aim")
	local CrosshairTab = createTab("Crosshair")
	local MacroTab = createTab("Macro")
	local GemFarmerTab = createTab("Gem Farmer")  -- 🆕 NEW TAB
	local InfoTab = createTab("Info")

	----------------------------------------------------------------
	-- 🆕 GEM FARMER TAB — controls the original gem farmer via _G.GFState
	--    Does NOT change any gem farmer logic — just exposes the toggle.
	----------------------------------------------------------------
	do
		GemFarmerTab:CreateSection("Auto Farm")
		local gfStatus = GemFarmerTab:CreateLabel("Status: waiting for gem farmer...")
		local gfTotal = GemFarmerTab:CreateLabel("Gems farmed: 0")

		Toggles.GemFarmer = GemFarmerTab:CreateToggle({
			Name = "⚡ Auto Farm Gems",
			CurrentValue = false,
			Callback = function(enabled)
				-- Uses the gem farmer's OWN state table — zero logic change.
				-- _G.GFState is the gem farmer's v104 table (same reference).
				if _G.GFState then
					_G.GFState.AutoFarmGems = enabled
					notify({Title="Gem Farmer",Content=enabled and "Auto farm started." or "Auto farm stopped.",Duration=3})
				else
					notify({Title="Gem Farmer",Content="Gem farmer not loaded yet — wait a moment.",Duration=3})
				end
			end,
		})

		GemFarmerTab:CreateButton({
			Name = "Show Gem Farmer Window",
			Callback = function()
				-- The gem farmer has its own 👌 button window — this just notifies.
				notify({Title="Gem Farmer",Content="Use the 👌 button on screen, or RightShift, to open the original window.",Duration=5})
			end,
		})

		task.spawn(function()
			while Gui.Parent do
				if _G.GFState then
					gfStatus:Set("Status: " .. (_G.GFState.AutoFarmGems and "🔄 FARMING" or "⏸️ Idle"))
					gfTotal:Set("Gems farmed: " .. tostring(_G.GFState.TotalFarmedGems or 0))
				end
				task.wait(0.5)
			end
		end)

		table.insert(Resetters, function()
			if _G.GFState then _G.GFState.AutoFarmGems = false end
		end)
	end

	----------------------------------------------------------------
	-- PLAYERS TAB (unchanged)
	----------------------------------------------------------------
	do
		local labels={}; local labelToPlayer={}; local selectedLabel=nil; local dropdown=nil
		local function build(excluded)
			labelToPlayer={}; labels={}
			for _,p in ipairs(Players:GetPlayers()) do
				if p~=LocalPlayer and p~=excluded then
					local label=string.format("%s (@%s)",p.DisplayName,p.Name)
					labelToPlayer[label]=p; table.insert(labels,label)
				end
			end
			table.sort(labels,function(a,b) return a:lower()<b:lower() end)
			return labels
		end
		local function refresh(excluded)
			build(excluded); dropdown:Refresh(table.clone(labels))
			if selectedLabel and not labelToPlayer[selectedLabel] then selectedLabel=nil; State.Target=nil end
		end
		local function cycle(step)
			if #labels==0 then notify({Title=CONFIG.Name,Content="No other players."}); return end
			local index=table.find(labels,selectedLabel) or (step>0 and 0 or 1)
			index=((index-1+step)%#labels)+1
			dropdown:Set(labels[index])
		end
		local spectating=false
		local function spectate()
			local target=State.Target; local char=target and target.Character; local hum=char and char:FindFirstChildOfClass("Humanoid")
			if not hum then notify({Title=CONFIG.Name,Content="Pick a target with a character first."}); return end
			Workspace.CurrentCamera.CameraSubject=hum; spectating=true
			notify({Title=CONFIG.Name,Content="Spectating "..target.DisplayName.."."})
		end
		local function stopSpectating()
			if not spectating then return end
			spectating=false; local _,hum=getCharacter()
			if hum then Workspace.CurrentCamera.CameraSubject=hum end
		end
		local function teleportToTarget()
			local target=State.Target; local tc=target and target.Character; local tr=tc and tc:FindFirstChild("HumanoidRootPart"); local _,_,mr=getCharacter()
			if not tr then notify({Title=CONFIG.Name,Content="Pick a target with a character first."}); return end
			if mr then mr.CFrame=tr.CFrame*CFrame.new(0,2,4) end
		end
		PlayersTab:CreateSection("Target")
		dropdown=PlayersTab:CreateDropdown({Name="Target",Options=build(),CurrentOption={},Callback=function(option)
			local label=type(option)=="table" and option[1] or option
			selectedLabel=label; State.Target=label and labelToPlayer[label] or nil
		end})
		PlayersTab:CreateButton({Name="Previous Target",Callback=function() cycle(-1) end})
		PlayersTab:CreateButton({Name="Next Target",Callback=function() cycle(1) end})
		PlayersTab:CreateButton({Name="Teleport To Target",Callback=teleportToTarget})
		PlayersTab:CreateButton({Name="Spectate Target",Callback=spectate})
		PlayersTab:CreateButton({Name="Stop Spectating",Callback=stopSpectating})
		PlayersTab:CreateSection("Target info")
		local identityLabel=PlayersTab:CreateLabel("No target selected")
		local statsLabel=PlayersTab:CreateLabel("--")
		local ageLabel=PlayersTab:CreateLabel("--")
		Players.PlayerAdded:Connect(function() refresh() end)
		Players.PlayerRemoving:Connect(function(p) if p==State.Target then State.Target=nil; selectedLabel=nil end; refresh(p) end)
		task.spawn(function()
			while Gui.Parent do
				local target=State.Target
				if target and target.Parent then
					local char=target.Character; local hum=char and char:FindFirstChildOfClass("Humanoid"); local root=char and char:FindFirstChild("HumanoidRootPart"); local _,_,mr=getCharacter()
					local health="--"
					if hum then health=hum.MaxHealth>100000 and "∞" or tostring(math.floor(hum.Health+0.5)) end
					local distance="--"
					if root and mr then distance=tostring(math.floor((root.Position-mr.Position).Magnitude+0.5)) end
					identityLabel:Set(string.format("%s (@%s)  ·  ID %d",target.DisplayName,target.Name,target.UserId))
					statsLabel:Set(string.format("HP %s  ·  %s studs  ·  Team: %s",health,distance,target.Team and target.Team.Name or "None"))
					ageLabel:Set(string.format("Account age: %d days",target.AccountAge))
				else
					identityLabel:Set("No target selected"); statsLabel:Set("--"); ageLabel:Set("--")
				end
				task.wait(0.5)
			end
		end)
		table.insert(Resetters,stopSpectating)
	end

	----------------------------------------------------------------
	-- SELF TAB (unchanged)
	----------------------------------------------------------------
	SelfTab:CreateSection("Movement")
	do
		local originalGravity=Workspace.Gravity; local defaultGravity=math.floor(originalGravity+0.5)
		local speedSlider,jumpSlider,gravitySlider
		local function setSpeed(value)
			if value==CONFIG.DefaultSpeed then
				local had=State.CustomSpeed~=nil; State.CustomSpeed=nil; local _,h=getCharacter()
				if had and h then h.WalkSpeed=starterValue("CharacterWalkSpeed",CONFIG.DefaultSpeed) end
			else State.CustomSpeed=value end
		end
		local function setJump(value)
			if value==CONFIG.DefaultJump then
				local had=State.CustomJump~=nil; State.CustomJump=nil; local _,h=getCharacter()
				if had and h then h.UseJumpPower=starterValue("CharacterUseJumpPower",true); h.JumpPower=starterValue("CharacterJumpPower",CONFIG.DefaultJump); h.JumpHeight=starterValue("CharacterJumpHeight",7.2) end
			else State.CustomJump=value end
		end
		local gravityTouched=false
		local function setGravity(value)
			if value==defaultGravity then
				if gravityTouched then Workspace.Gravity=originalGravity; gravityTouched=false end
			else Workspace.Gravity=value; gravityTouched=true end
		end
		speedSlider=SelfTab:CreateSlider({Name="Walk Speed",Range={0,CONFIG.MaxSpeed},Increment=1,CurrentValue=CONFIG.DefaultSpeed,Callback=setSpeed})
		jumpSlider=SelfTab:CreateSlider({Name="Jump Power",Range={0,CONFIG.MaxJump},Increment=1,CurrentValue=CONFIG.DefaultJump,Callback=setJump})
		gravitySlider=SelfTab:CreateSlider({Name="Gravity",Range={0,400},Increment=1,CurrentValue=math.clamp(defaultGravity,0,400),Callback=setGravity})
		local function resetMovement()
			speedSlider:Set(CONFIG.DefaultSpeed); jumpSlider:Set(CONFIG.DefaultJump); gravitySlider:Set(math.clamp(defaultGravity,0,400))
			setSpeed(CONFIG.DefaultSpeed); setJump(CONFIG.DefaultJump); setGravity(defaultGravity)
		end
		SelfTab:CreateButton({Name="Reset Speed, Jump & Gravity",Callback=resetMovement})
		table.insert(Resetters,resetMovement)
		connect(RunService.Heartbeat,function()
			if not State.CustomSpeed and not State.CustomJump then return end
			local _,h=getCharacter(); if not h then return end
			if State.CustomSpeed and h.WalkSpeed~=State.CustomSpeed then h.WalkSpeed=State.CustomSpeed end
			if State.CustomJump then
				if not h.UseJumpPower then h.UseJumpPower=true end
				if h.JumpPower~=State.CustomJump then h.JumpPower=State.CustomJump end
			end
		end)
	end

	SelfTab:CreateSection("Flight")
	do
		local parts=nil
		local function stop()
			if not parts then return end
			for _,p in pairs(parts) do p:Destroy() end
			parts=nil
			local _,h=getCharacter()
			if h then h.PlatformStand=false; h:ChangeState(Enum.HumanoidStateType.Freefall) end
		end
		local function start()
			stop(); getControls()
			local _,h,root=getCharacter()
			if not h or not root then return end
			local att=make("Attachment",{Name="ScHubFly"},root)
			local vel=make("LinearVelocity",{Attachment0=att,MaxForce=math.huge,VelocityConstraintMode=Enum.VelocityConstraintMode.Vector,RelativeTo=Enum.ActuatorRelativeTo.World,VectorVelocity=Vector3.zero},root)
			local align=make("AlignOrientation",{Mode=Enum.OrientationAlignmentMode.OneAttachment,Attachment0=att,RigidityEnabled=true,CFrame=root.CFrame.Rotation},root)
			h.PlatformStand=true; parts={Attachment=att,Velocity=vel,Align=align}
		end
		Toggles.Fly=SelfTab:CreateToggle({Name="Fly  (Space/E up · Ctrl/Q down)",CurrentValue=false,Callback=function(enabled)
			State.Fly=enabled; refreshFlyPad()
			if enabled then start() else stop() end
		end})
		SelfTab:CreateSlider({Name="Fly Speed",Range={10,CONFIG.MaxFlySpeed},Increment=5,CurrentValue=State.FlySpeed,Callback=function(v) State.FlySpeed=v end})
		connect(RunService.RenderStepped,function()
			if not State.Fly or not parts then return end
			local cam=Workspace.CurrentCamera; local _,h,root=getCharacter()
			if not (cam and h and root and parts.Attachment.Parent) then return end
			h.PlatformStand=true
			if State.Freecam then parts.Velocity.VectorVelocity=Vector3.zero; return end
			local direction=cam.CFrame:VectorToWorldSpace(getMoveVector())
			direction += Vector3.new(0,getVerticalInput(),0)
			if direction.Magnitude>1 then direction=direction.Unit end
			parts.Velocity.VectorVelocity=direction*State.FlySpeed
			local look=cam.CFrame.LookVector; local flat=Vector3.new(look.X,0,look.Z)
			if flat.Magnitude>0.01 then parts.Align.CFrame=CFrame.lookAt(Vector3.zero,flat) end
		end)
		connect(LocalPlayer.CharacterAdded,function(char)
			State.PadUp,State.PadDown=false,false
			if State.Fly then char:WaitForChild("HumanoidRootPart"); task.wait(0.5); if State.Fly then start() end end
		end)
	end

	SelfTab:CreateSection("Abilities")
	do
		local stored={}
		Toggles.Noclip=SelfTab:CreateToggle({Name="Noclip",CurrentValue=false,Callback=function(enabled)
			State.Noclip=enabled
			if not enabled then
				for part in pairs(stored) do if part.Parent then part.CanCollide=true end end
				table.clear(stored)
			end
		end})
		connect(RunService.Stepped,function()
			if not State.Noclip then return end
			local c=LocalPlayer.Character; if not c then return end
			for _,part in ipairs(c:GetDescendants()) do
				if part:IsA("BasePart") and part.CanCollide then stored[part]=true; part.CanCollide=false end
			end
		end)
		connect(LocalPlayer.CharacterAdded,function() table.clear(stored) end)
	end
	do
		Toggles.InfiniteJump=SelfTab:CreateToggle({Name="Infinite Jump",CurrentValue=false,Callback=function(e) State.InfiniteJump=e end})
		connect(UserInputService.JumpRequest,function()
			if not State.InfiniteJump then return end
			local _,h=getCharacter(); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
		end)
	end
	do
		Toggles.ClickTeleport=SelfTab:CreateToggle({Name="Ctrl + Click Teleport (PC)",CurrentValue=false,Callback=function(e) State.ClickTeleport=e end})
		connect(UserInputService.InputBegan,function(input,processed)
			if processed or not State.ClickTeleport then return end
			if input.UserInputType~=Enum.UserInputType.MouseButton1 then return end
			if not UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then return end
			local char,_,root=getCharacter(); local cam=Workspace.CurrentCamera
			if not (char and root and cam) then return end
			local loc=UserInputService:GetMouseLocation()
			local ray=cam:ViewportPointToRay(loc.X,loc.Y)
			local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances={char}
			local result=Workspace:Raycast(ray.Origin,ray.Direction*3000,params)
			if result then root.CFrame=CFrame.new(result.Position+Vector3.new(0,3,0)) end
		end)
	end
	SelfTab:CreateSection("Utility")
	do
		SelfTab:CreateButton({Name="Sit",Callback=function() local _,h=getCharacter(); if h then h.Sit=true end end})
		SelfTab:CreateButton({Name="Reset Character",Callback=function() local _,h=getCharacter(); if h then h.Health=0 end end})
		Toggles.AntiAfk=SelfTab:CreateToggle({Name="Anti-AFK",CurrentValue=false,Callback=function(e) State.AntiAfk=e end})
		connect(LocalPlayer.Idled,function()
			if not State.AntiAfk then return end
			pcall(function() local vu=game:GetService("VirtualUser"); vu:CaptureController(); vu:ClickButton2(Vector2.zero) end)
		end)
		SelfTab:CreateButton({Name="Rejoin Server",Callback=function()
			local ok=pcall(function()
				if #Players:GetPlayers()<=1 then TeleportService:Teleport(game.PlaceId,LocalPlayer)
				else TeleportService:TeleportToPlaceInstance(game.PlaceId,game.JobId,LocalPlayer) end
			end)
			if not ok then notify({Title=CONFIG.Name,Content="Rejoin unavailable here."}) end
		end})
	end

	----------------------------------------------------------------
	-- TELEPORT TAB (unchanged)
	----------------------------------------------------------------
	do
		local waypoints={}; local names={}; local selectedName=nil; local typedName=""; local quickSlot=nil; local dropdown=nil; local input=nil
		local function refreshDropdown()
			table.sort(names,function(a,b) return a:lower()<b:lower() end)
			dropdown:Refresh(table.clone(names))
		end
		TeleportTab:CreateSection("Quick")
		TeleportTab:CreateButton({Name="Save Position",Callback=function() local _,_,r=getCharacter(); if r then quickSlot=r.CFrame; notify({Title=CONFIG.Name,Content="Position saved."}) end end})
		TeleportTab:CreateButton({Name="Teleport To Saved Position",Callback=function()
			local _,_,r=getCharacter()
			if not quickSlot then notify({Title=CONFIG.Name,Content="Save a position first."}) elseif r then r.CFrame=quickSlot end
		end})
		TeleportTab:CreateButton({Name="Teleport To Spawn",Callback=function()
			local _,_,r=getCharacter(); local sp=Workspace:FindFirstChildWhichIsA("SpawnLocation",true)
			if not sp then notify({Title=CONFIG.Name,Content="No SpawnLocation."}) elseif r then r.CFrame=sp.CFrame+Vector3.new(0,5,0) end
		end})
		TeleportTab:CreateSection("Waypoints")
		input=TeleportTab:CreateInput({Name="Waypoint name",PlaceholderText="e.g. Base",RemoveTextAfterFocusLost=false,Callback=function(t) typedName=t or "" end})
		dropdown=TeleportTab:CreateDropdown({Name="Waypoint",Options={},CurrentOption={},Callback=function(option) selectedName=type(option)=="table" and option[1] or option end})
		TeleportTab:CreateButton({Name="Save Waypoint Here",Callback=function()
			local _,_,r=getCharacter(); if not r then return end
			local name=typedName:match("^%s*(.-)%s*$")
			if name=="" then local n=#names+1; while waypoints["Waypoint "..n] do n+=1 end; name="Waypoint "..n end
			if not waypoints[name] then table.insert(names,name) end
			waypoints[name]=r.CFrame; refreshDropdown(); dropdown:Set(name); input:Set(""); typedName=""
			notify({Title=CONFIG.Name,Content='Saved "'..name..'".'})
		end})
		TeleportTab:CreateButton({Name="Teleport To Waypoint",Callback=function()
			local _,_,r=getCharacter(); local target=selectedName and waypoints[selectedName]
			if not target then notify({Title=CONFIG.Name,Content="Pick a waypoint first."}) elseif r then r.CFrame=target end
		end})
		TeleportTab:CreateButton({Name="Delete Waypoint",Callback=function()
			if not selectedName or not waypoints[selectedName] then notify({Title=CONFIG.Name,Content="Pick a waypoint first."}); return end
			local idx=table.find(names,selectedName); if idx then table.remove(names,idx) end
			waypoints[selectedName]=nil; selectedName=nil; refreshDropdown()
		end})
	end

	----------------------------------------------------------------
	-- VISUAL TAB (unchanged — condensed)
	----------------------------------------------------------------
	VisualTab:CreateSection("Players")
	do
		local objects={}; local token=0
		local function remove(p) local s=objects[p]; if s then s.Highlight:Destroy(); s.Billboard:Destroy(); objects[p]=nil end end
		local function add(p)
			remove(p); if p==LocalPlayer then return end
			local char=p.Character; local head=char and char:FindFirstChild("Head"); if not head then return end
			local color=p.Team and p.TeamColor.Color or THEME.Accent
			local hl=make("Highlight",{Name="ScHubHighlight",Adornee=char,DepthMode=Enum.HighlightDepthMode.AlwaysOnTop,FillColor=color,OutlineColor=Color3.new(1,1,1),FillTransparency=0.6,OutlineTransparency=0},char)
			local bb=make("BillboardGui",{Name="ScHubTag",Adornee=head,AlwaysOnTop=true,Size=UDim2.fromOffset(170,36),StudsOffset=Vector3.new(0,2.6,0)},head)
			local lbl=make("TextLabel",{BackgroundTransparency=1,Size=UDim2.fromScale(1,1),Text=p.DisplayName,TextColor3=Color3.new(1,1,1),TextStrokeTransparency=0.4,Font=Enum.Font.GothamBold,TextSize=13},bb)
			objects[p]={Highlight=hl,Billboard=bb,Label=lbl}
		end
		local function update()
			local _,_,mr=getCharacter()
			for p,s in pairs(objects) do
				if not s.Highlight.Parent then objects[p]=nil
				else
					local char=p.Character; local hum=char and char:FindFirstChildOfClass("Humanoid"); local root=char and char:FindFirstChild("HumanoidRootPart")
					if hum and root and mr then
						local health=hum.MaxHealth>100000 and "∞" or tostring(math.floor(hum.Health+0.5))
						local dist=math.floor((root.Position-mr.Position).Magnitude+0.5)
						s.Label.Text=string.format("%s\n%s HP  ·  %d studs",p.DisplayName,health,dist)
					end
				end
			end
		end
		local function hook(p)
			if p==LocalPlayer then return end
			p.CharacterAdded:Connect(function() if State.ESP then task.wait(0.5); if State.ESP then add(p) end end end)
		end
		Toggles.ESP=VisualTab:CreateToggle({Name="Player ESP (highlight, name, HP, distance)",CurrentValue=false,Callback=function(enabled)
			State.ESP=enabled; token+=1
			if enabled then
				for _,p in ipairs(Players:GetPlayers()) do add(p) end
				local mine=token
				task.spawn(function() while State.ESP and token==mine do update(); task.wait(0.25) end end)
			else
				for p in pairs(objects) do remove(p) end
			end
		end})
		for _,p in ipairs(Players:GetPlayers()) do hook(p) end
		Players.PlayerAdded:Connect(hook); Players.PlayerRemoving:Connect(remove)
	end
	VisualTab:CreateSection("World")
	do
		local saved=nil
		Toggles.Fullbright=VisualTab:CreateToggle({Name="Fullbright",CurrentValue=false,Callback=function(enabled)
			if enabled then
				if not saved then saved={Brightness=Lighting.Brightness,FogEnd=Lighting.FogEnd,GlobalShadows=Lighting.GlobalShadows,Ambient=Lighting.Ambient,OutdoorAmbient=Lighting.OutdoorAmbient} end
				Lighting.Brightness=2; Lighting.FogEnd=1e6; Lighting.GlobalShadows=false
				Lighting.Ambient=Color3.fromRGB(178,178,178); Lighting.OutdoorAmbient=Color3.fromRGB(178,178,178)
			elseif saved then
				for prop,val in pairs(saved) do Lighting[prop]=val end; saved=nil
			end
		end})
	end
	do
		local originalClock=Lighting.ClockTime; local startValue=math.clamp(math.floor(originalClock*2+0.5)/2,0,24); local timeSlider=nil; local clockTouched=false
		timeSlider=VisualTab:CreateSlider({Name="Time Of Day",Range={0,24},Increment=0.5,Suffix="h",CurrentValue=startValue,Callback=function(value)
			if value==startValue then if clockTouched then Lighting.ClockTime=originalClock; clockTouched=false end end
			else Lighting.ClockTime=value; clockTouched=true end
		end})
		table.insert(Resetters,function() timeSlider:Set(startValue); if clockTouched then Lighting.ClockTime=originalClock; clockTouched=false end end)
	end
	do
		local disabled={}
		Toggles.NoEffects=VisualTab:CreateToggle({Name="Disable Blur / Bloom / Post Effects",CurrentValue=false,Callback=function(enabled)
			if enabled then
				local containers={Lighting,Workspace.CurrentCamera}
				for _,c in ipairs(containers) do for _,child in ipairs(c:GetChildren()) do if child:IsA("PostEffect") and child.Enabled then disabled[child]=true; child.Enabled=false end end end
			else
				for eff in pairs(disabled) do if eff.Parent then eff.Enabled=true end end; table.clear(disabled)
			end
		end})
	end
	VisualTab:CreateSection("Camera")
	do
		local originalFov=Workspace.CurrentCamera.FieldOfView; local startFov=math.clamp(math.floor(originalFov+0.5),40,120); local fovSlider=nil; local fovTouched=false
		fovSlider=VisualTab:CreateSlider({Name="Field Of View",Range={40,120},Increment=1,CurrentValue=startFov,Callback=function(value)
			if value==startFov then if fovTouched then Workspace.CurrentCamera.FieldOfView=originalFov; fovTouched=false end end
			else Workspace.CurrentCamera.FieldOfView=value; fovTouched=true end
		end})
		table.insert(Resetters,function() fovSlider:Set(startFov); if fovTouched then Workspace.CurrentCamera.FieldOfView=originalFov; fovTouched=false end end)
	end
	do
		local originalMaxZoom=LocalPlayer.CameraMaxZoomDistance
		Toggles.Zoom=VisualTab:CreateToggle({Name="Unlimited Camera Zoom",CurrentValue=false,Callback=function(e) LocalPlayer.CameraMaxZoomDistance=e and 100000 or originalMaxZoom end})
	end
	do
		local yaw,pitch=0,0; local position=Vector3.zero; local anchoredRoot=nil; local active=false
		local function anchorCharacter() local _,_,r=getCharacter(); if r then r.Anchored=true; anchoredRoot=r end end
		local function stop()
			if not active then return end; active=false
			local cam=Workspace.CurrentCamera; cam.CameraType=Enum.CameraType.Custom
			local _,h=getCharacter(); if h then cam.CameraSubject=h end
			if anchoredRoot and anchoredRoot.Parent then anchoredRoot.Anchored=false end; anchoredRoot=nil
			UserInputService.MouseBehavior=Enum.MouseBehavior.Default
		end
		local function start()
			getControls(); local cam=Workspace.CurrentCamera; local ccf=cam.CFrame
			position=ccf.Position; pitch,yaw=ccf:ToOrientation()
			cam.CameraType=Enum.CameraType.Scriptable; active=true; anchorCharacter()
		end
		Toggles.Freecam=VisualTab:CreateToggle({Name="Freecam (hold right mouse to look)",CurrentValue=false,Callback=function(enabled)
			State.Freecam=enabled; refreshFlyPad(); if enabled then start() else stop() end
		end})
		VisualTab:CreateSlider({Name="Freecam Speed",Range={5,CONFIG.MaxFreecamSpeed},Increment=5,CurrentValue=State.FreecamSpeed,Callback=function(v) State.FreecamSpeed=v end})
		connect(RunService.RenderStepped,function(dt)
			if not State.Freecam then return end
			local cam=Workspace.CurrentCamera
			if cam.CameraType~=Enum.CameraType.Scriptable then cam.CameraType=Enum.CameraType.Scriptable end
			local looking=UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
			UserInputService.MouseBehavior=looking and Enum.MouseBehavior.LockCurrentPosition or Enum.MouseBehavior.Default
			if looking then
				local delta=UserInputService:GetMouseDelta()
				yaw-=math.rad(delta.X*0.25); pitch=math.clamp(pitch-math.rad(delta.Y*0.25),-1.5,1.5)
			end
			local rotation=CFrame.fromOrientation(pitch,yaw,0)
			local move=rotation:VectorToWorldSpace(getMoveVector())
			move+=Vector3.new(0,getVerticalInput(),0)
			if move.Magnitude>1 then move=move.Unit end
			position+=move*State.FreecamSpeed*dt; cam.CFrame=CFrame.new(position)*rotation
		end)
		connect(UserInputService.InputChanged,function(input,processed)
			if State.Freecam and not processed and input.UserInputType==Enum.UserInputType.Touch then
				yaw-=math.rad(input.Delta.X*0.3); pitch=math.clamp(pitch-math.rad(input.Delta.Y*0.3),-1.5,1.5)
			end
		end)
		connect(LocalPlayer.CharacterAdded,function(char) if State.Freecam then char:WaitForChild("HumanoidRootPart"); task.wait(0.3); if State.Freecam then anchorCharacter() end end end)
	end

	----------------------------------------------------------------
	-- AIM TAB (condensed — unchanged logic)
	----------------------------------------------------------------
	do
		local settings={HoldToAim=true,PartName="Head",Strength=25,Radius=200,MaxDistance=1500,IgnoreTeammates=true,LineOfSight=true,Lead=false,BulletSpeed=800,ShowCircle=true}
		local held=false; local target=nil; local bound=false
		local circle=make("Frame",{Visible=false,AnchorPoint=Vector2.new(0.5,0.5),BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.fromOffset(settings.Radius*2,settings.Radius*2),ZIndex=5},Gui)
		corner(circle,1000); make("UIStroke",{Color=THEME.Accent,Thickness=1.5,Transparency=0.3,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},circle)
		local function aimOrigin(cam) if UserInputService.MouseBehavior==Enum.MouseBehavior.LockCenter then return cam.ViewportSize/2 end return UserInputService:GetMouseLocation() end
		local function getPart(char)
			if settings.PartName=="Head" then return char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
			elseif settings.PartName=="Torso" then return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart") end
			return char:FindFirstChild("HumanoidRootPart")
		end
		local function isEnemy(p) if not settings.IgnoreTeammates then return true end; local mine=LocalPlayer.Team; return not (mine and p.Team==mine) end
		local function hasLOS(cam,part,char)
			if not settings.LineOfSight then return true end
			local ignore={char}; if LocalPlayer.Character then table.insert(ignore,LocalPlayer.Character) end
			local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances=ignore
			local origin=cam.CFrame.Position; return Workspace:Raycast(origin,part.Position-origin,params)==nil
		end
		local function evaluate(p,cam,origin,acquiring)
			if p==LocalPlayer or not isEnemy(p) then return nil end
			local char=p.Character; local hum=char and char:FindFirstChildOfClass("Humanoid"); local part=char and getPart(char)
			if not hum or not part or hum.Health<=0 then return nil end
			if (part.Position-cam.CFrame.Position).Magnitude>settings.MaxDistance then return nil end
			local point=cam:WorldToViewportPoint(part.Position); if point.Z<=0 then return nil end
			local pixels=(Vector2.new(point.X,point.Y)-origin).Magnitude
			if acquiring and pixels>settings.Radius then return nil end
			if not hasLOS(cam,part,char) then return nil end
			return pixels
		end
		local function acquire(cam,origin)
			local best,bestPx=nil,nil
			for _,p in ipairs(Players:GetPlayers()) do
				local px=evaluate(p,cam,origin,true)
				if px and (not bestPx or px<bestPx) then best,bestPx=p,px end
			end
			return best
		end
		local function update(dt)
			local cam=Workspace.CurrentCamera; local origin=aimOrigin(cam)
			circle.Visible=settings.ShowCircle; circle.Position=UDim2.fromOffset(origin.X,origin.Y)
			if State.Freecam then target=nil; return end
			local touchOnly=UserInputService.TouchEnabled and not UserInputService.MouseEnabled
			local active=held or not settings.HoldToAim or touchOnly
			if not active then target=nil; return end
			if target and not evaluate(target,cam,origin,false) then target=nil end
			if not target then target=acquire(cam,origin) end
			if not target then return end
			local part=getPart(target.Character); if not part then target=nil; return end
			local aimPoint=part.Position
			if settings.Lead then
				local studs=(aimPoint-cam.CFrame.Position).Magnitude; aimPoint+=part.AssemblyLinearVelocity*(studs/settings.BulletSpeed)
			end
			local goal=CFrame.lookAt(cam.CFrame.Position,aimPoint)
			local alpha=1-(1-settings.Strength/100)^(dt*60)
			cam.CFrame=cam.CFrame:Lerp(goal,alpha)
		end
		local function bind() if bound then return end; bound=true; RunService:BindToRenderStep("ScHubAim",Enum.RenderPriority.Camera.Value+1,update) end
		local function unbind() if not bound then return end; bound=false; RunService:UnbindFromRenderStep("ScHubAim"); target=nil; circle.Visible=false end
		connect(UserInputService.InputBegan,function(input,processed) if input.UserInputType==Enum.UserInputType.MouseButton2 and not processed then held=true; target=nil end end)
		connect(UserInputService.InputEnded,function(input) if input.UserInputType==Enum.UserInputType.MouseButton2 then held=false; target=nil end end)
		AimTab:CreateSection("Aim lock")
		local statusLabel=AimTab:CreateLabel("Aim lock is off")
		Toggles.AimLock=AimTab:CreateToggle({Name="Aim Lock (camera only)",CurrentValue=false,Callback=function(e) if e then bind() else unbind() end end})
		AimTab:CreateToggle({Name="Only While Holding Right Mouse",CurrentValue=true,Callback=function(e) settings.HoldToAim=e end})
		AimTab:CreateDropdown({Name="Aim At",Options={"Head","Torso","Root"},CurrentOption={"Head"},Callback=function(o) settings.PartName=type(o)=="table" and o[1] or o or "Head" end})
		AimTab:CreateSlider({Name="Lock Strength (100=hard)",Range={5,100},Increment=5,Suffix="%",CurrentValue=settings.Strength,Callback=function(v) settings.Strength=v end})
		AimTab:CreateSection("Targeting")
		AimTab:CreateSlider({Name="FOV Radius",Range={30,600},Increment=10,Suffix="px",CurrentValue=settings.Radius,Callback=function(v) settings.Radius=v; circle.Size=UDim2.fromOffset(v*2,v*2) end})
		AimTab:CreateSlider({Name="Max Distance",Range={100,3000},Increment=50,Suffix="studs",CurrentValue=settings.MaxDistance,Callback=function(v) settings.MaxDistance=v end})
		AimTab:CreateToggle({Name="Ignore Teammates",CurrentValue=true,Callback=function(e) settings.IgnoreTeammates=e end})
		AimTab:CreateToggle({Name="Require Line Of Sight",CurrentValue=true,Callback=function(e) settings.LineOfSight=e end})
		AimTab:CreateToggle({Name="Show FOV Circle",CurrentValue=true,Callback=function(e) settings.ShowCircle=e; if not e then circle.Visible=false end end})
		AimTab:CreateSection("Sniper")
		AimTab:CreateToggle({Name="Lead Moving Targets",CurrentValue=false,Callback=function(e) settings.Lead=e end})
		AimTab:CreateSlider({Name="Bullet Speed (for leading)",Range={100,3000},Increment=50,Suffix="studs/s",CurrentValue=settings.BulletSpeed,Callback=function(v) settings.BulletSpeed=v end})
		task.spawn(function()
			while Gui.Parent do
				if not bound then statusLabel:Set("Aim lock is off")
				elseif target and target.Parent then
					local _,_,mr=getCharacter(); local char=target.Character; local root=char and char:FindFirstChild("HumanoidRootPart")
					local studs=(mr and root) and math.floor((root.Position-mr.Position).Magnitude+0.5) or 0
					statusLabel:Set(string.format("Locked on %s  ·  %d studs",target.DisplayName,studs))
				elseif settings.HoldToAim and not held then statusLabel:Set("Ready · hold right mouse to lock")
				else statusLabel:Set("Searching for a target...") end
				task.wait(0.15)
			end
		end)
	end

	----------------------------------------------------------------
	-- CROSSHAIR TAB (condensed — unchanged logic)
	----------------------------------------------------------------
	do
		local DEFAULTS={Style="Cross",Size=10,Thickness=2,Gap=4,Opacity=100,R=255,G=255,B=255}
		local settings={Enabled=false,Style=DEFAULTS.Style,Size=DEFAULTS.Size,Thickness=DEFAULTS.Thickness,Gap=DEFAULTS.Gap,Opacity=DEFAULTS.Opacity,R=DEFAULTS.R,G=DEFAULTS.G,B=DEFAULTS.B,Outline=true,Dynamic=false,FollowMouse=false}
		local PRESETS={White={255,255,255},Red={255,60,60},Green={60,255,90},Cyan={0,220,255},Yellow={255,230,60},Magenta={255,70,220},Orange={255,150,40},Black={0,0,0}}
		local PRESET_NAMES={"White","Red","Green","Cyan","Yellow","Magenta","Orange","Black"}
		local holder=make("Frame",{Name="Crosshair",Visible=false,BackgroundTransparency=1,AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(0,0),ZIndex=0},Gui)
		local parts={}
		for _,name in ipairs({"Top","Bottom","Left","Right","Dot"}) do
			local f=make("Frame",{Name=name,Visible=false,AnchorPoint=Vector2.new(0.5,0.5),BorderSizePixel=0,BackgroundColor3=Color3.new(1,1,1)},holder)
			local s=make("UIStroke",{Color=Color3.new(0,0,0),Thickness=1,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},f)
			parts[name]={Frame=f,Stroke=s}
		end
		local ring=make("Frame",{Name="Ring",Visible=false,AnchorPoint=Vector2.new(0.5,0.5),BackgroundTransparency=1,BorderSizePixel=0},holder)
		corner(ring,1000); local ringStroke=make("UIStroke",{Thickness=2,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},ring)
		local extraGap=0
		local function place(name,visible,w,h,x,y,color,trans)
			local part=parts[name]; part.Frame.Visible=visible
			if visible then
				part.Frame.Size=UDim2.fromOffset(w,h); part.Frame.Position=UDim2.fromOffset(x,y)
				part.Frame.BackgroundColor3=color; part.Frame.BackgroundTransparency=trans
				part.Stroke.Enabled=settings.Outline; part.Stroke.Transparency=trans
			end
		end
		local function apply()
			local color=Color3.fromRGB(settings.R,settings.G,settings.B)
			local trans=1-settings.Opacity/100; local th=settings.Thickness; local len=settings.Size
			local offset=math.floor(settings.Gap+extraGap+len/2+0.5); local style=settings.Style
			local showLines=style=="Cross" or style=="T-Shape" or style=="Cross + Dot"
			local showDot=style=="Dot" or style=="Cross + Dot" or style=="Circle + Dot"
			local showRing=style=="Circle" or style=="Circle + Dot"
			place("Top",showLines and style~="T-Shape",th,len,0,-offset,color,trans)
			place("Bottom",showLines,th,len,0,offset,color,trans)
			place("Left",showLines,len,th,-offset,0,color,trans)
			place("Right",showLines,len,th,offset,0,color,trans)
			local dotSize=math.max(th,2); place("Dot",showDot,dotSize,dotSize,0,0,color,trans)
			ring.Visible=showRing
			if showRing then ring.Size=UDim2.fromOffset(len*2,len*2); ringStroke.Color=color; ringStroke.Thickness=th; ringStroke.Transparency=trans end
		end
		connect(RunService.RenderStepped,function()
			if not settings.Enabled then return end
			local cam=Workspace.CurrentCamera; local origin=cam.ViewportSize/2
			if settings.FollowMouse and UserInputService.MouseBehavior~=Enum.MouseBehavior.LockCenter then origin=UserInputService:GetMouseLocation() end
			holder.Position=UDim2.fromOffset(math.floor(origin.X+0.5),math.floor(origin.Y+0.5))
			local targetExtra=0
			if settings.Dynamic then
				local _,_,root=getCharacter()
				if root then
					local vel=root.AssemblyLinearVelocity; local spd=Vector3.new(vel.X,0,vel.Z).Magnitude
					targetExtra=math.clamp(spd/16*6,0,14)
				end
			end
			local before=math.floor(extraGap+0.5); extraGap+=(targetExtra-extraGap)*0.2
			if math.floor(extraGap+0.5)~=before then apply() end
		end)
		local styleDropdown,sizeSlider,thicknessSlider,gapSlider,opacitySlider,redSlider,greenSlider,blueSlider,outlineToggle,dynamicToggle,followToggle
		CrosshairTab:CreateSection("Crosshair")
		Toggles.Crosshair=CrosshairTab:CreateToggle({Name="Enable Custom Crosshair",CurrentValue=false,Callback=function(e) settings.Enabled=e; holder.Visible=e; if e then apply() end end})
		local originalMouseIcon=UserInputService.MouseIconEnabled
		Toggles.HideMouse=CrosshairTab:CreateToggle({Name="Hide Mouse Cursor",CurrentValue=false,Callback=function(e) UserInputService.MouseIconEnabled=e and false or originalMouseIcon end})
		styleDropdown=CrosshairTab:CreateDropdown({Name="Style",Options={"Cross","T-Shape","Dot","Circle","Cross + Dot","Circle + Dot"},CurrentOption={settings.Style},Callback=function(o) settings.Style=type(o)=="table" and o[1] or o or DEFAULTS.Style; apply() end})
		CrosshairTab:CreateSection("Shape")
		sizeSlider=CrosshairTab:CreateSlider({Name="Size (line length / circle radius)",Range={2,60},Increment=1,Suffix="px",CurrentValue=settings.Size,Callback=function(v) settings.Size=v; apply() end})
		thicknessSlider=CrosshairTab:CreateSlider({Name="Thickness",Range={1,8},Increment=1,Suffix="px",CurrentValue=settings.Thickness,Callback=function(v) settings.Thickness=v; apply() end})
		gapSlider=CrosshairTab:CreateSlider({Name="Center Gap",Range={0,30},Increment=1,Suffix="px",CurrentValue=settings.Gap,Callback=function(v) settings.Gap=v; apply() end})
		opacitySlider=CrosshairTab:CreateSlider({Name="Opacity",Range={10,100},Increment=5,Suffix="%",CurrentValue=settings.Opacity,Callback=function(v) settings.Opacity=v; apply() end})
		outlineToggle=CrosshairTab:CreateToggle({Name="Black Outline",CurrentValue=settings.Outline,Callback=function(e) settings.Outline=e; apply() end})
		dynamicToggle=CrosshairTab:CreateToggle({Name="Dynamic Gap (widens while you move)",CurrentValue=settings.Dynamic,Callback=function(e) settings.Dynamic=e; if not e then extraGap=0; apply() end end})
		followToggle=CrosshairTab:CreateToggle({Name="Follow Mouse (when cursor is free)",CurrentValue=settings.FollowMouse,Callback=function(e) settings.FollowMouse=e end})
		CrosshairTab:CreateSection("Color")
		CrosshairTab:CreateDropdown({Name="Color Preset",Options=PRESET_NAMES,CurrentOption={"White"},Callback=function(o)
			local name=type(o)=="table" and o[1] or o; local preset=name and PRESETS[name]
			if preset then redSlider:Set(preset[1]); greenSlider:Set(preset[2]); blueSlider:Set(preset[3]) end
		end})
		redSlider=CrosshairTab:CreateSlider({Name="Red",Range={0,255},Increment=5,CurrentValue=settings.R,Callback=function(v) settings.R=v; apply() end})
		greenSlider=CrosshairTab:CreateSlider({Name="Green",Range={0,255},Increment=5,CurrentValue=settings.G,Callback=function(v) settings.G=v; apply() end})
		blueSlider=CrosshairTab:CreateSlider({Name="Blue",Range={0,255},Increment=5,CurrentValue=settings.B,Callback=function(v) settings.B=v; apply() end})
		CrosshairTab:CreateButton({Name="Reset Crosshair Style",Callback=function()
			styleDropdown:Set(DEFAULTS.Style); sizeSlider:Set(DEFAULTS.Size); thicknessSlider:Set(DEFAULTS.Thickness)
			gapSlider:Set(DEFAULTS.Gap); opacitySlider:Set(DEFAULTS.Opacity); redSlider:Set(DEFAULTS.R)
			greenSlider:Set(DEFAULTS.G); blueSlider:Set(DEFAULTS.B); outlineToggle:Set(true)
			dynamicToggle:Set(false); followToggle:Set(false)
		end})
		apply()
	end

	----------------------------------------------------------------
	-- MACRO TAB (condensed — unchanged logic)
	----------------------------------------------------------------
	do
		local SAMPLE_INTERVAL=1/CONFIG.RecordRate
		local recordings={}; local names={}; local selectedName=nil; local typedName=""; local dropdown=nil; local nameInput=nil; local statusLabel=nil
		local recorder=nil; local playback=nil; local settings={Loop=false,Speed=1,Relative=false,Camera=false}
		local function formatTime(s) s=math.max(0,math.floor(s)); return string.format("%02d:%02d",s//60,s%60) end
		local function refreshDropdown() table.sort(names,function(a,b) return a:lower()<b:lower() end); dropdown:Refresh(table.clone(names)) end
		local function uniqueName()
			local name=typedName:match("^%s*(.-)%s*$")
			if name=="" then local n=#names+1; while recordings["Recording "..n] do n+=1 end; name="Recording "..n end
			return name
		end
		local function startRecording()
			local _,h,root=getCharacter(); if not h or not root then notify({Title=CONFIG.Name,Content="No character to record."}); return false end
			recorder={Frames={},Elapsed=0,Accumulator=SAMPLE_INTERVAL}
			notify({Title=CONFIG.Name,Content="Recording started."}); return true
		end
		local function stopRecording()
			if not recorder then return end
			local frames=recorder.Frames; recorder=nil
			if #frames<2 then notify({Title=CONFIG.Name,Content="Recording too short."}); return end
			local startTime=frames[1].t
			for _,f in ipairs(frames) do f.t-=startTime end
			local name=uniqueName()
			if not recordings[name] then table.insert(names,name) end
			recordings[name]={Frames=frames,Duration=frames[#frames].t}
			refreshDropdown(); dropdown:Set(name); nameInput:Set(""); typedName=""
			notify({Title=CONFIG.Name,Content=string.format('Saved "%s" (%s).',name,formatTime(recordings[name].Duration))})
		end
		connect(RunService.Heartbeat,function(dt)
			if not recorder then return end
			recorder.Elapsed+=dt; recorder.Accumulator+=dt
			if recorder.Accumulator<SAMPLE_INTERVAL then return end
			recorder.Accumulator=recorder.Accumulator%SAMPLE_INTERVAL
			local _,h,root=getCharacter(); local cam=Workspace.CurrentCamera
			if not (h and root and cam) then return end
			table.insert(recorder.Frames,{t=recorder.Elapsed,cf=root.CFrame,vel=root.AssemblyLinearVelocity,cam=root.CFrame:ToObjectSpace(cam.CFrame),jumping=h:GetState()==Enum.HumanoidStateType.Jumping})
			if recorder.Elapsed>=CONFIG.MaxRecordSeconds then notify({Title=CONFIG.Name,Content="Max recording length reached."}); Toggles.Record:Set(false) end
		end)
		local function stopPlayback()
			if not playback then return end
			local session=playback; playback=nil
			local _,h,root=getCharacter()
			if h then h.AutoRotate=session.OldAutoRotate end
			if root then root.AssemblyLinearVelocity=Vector3.zero end
			if session.ControlsDisabled then local c=getControls(); if c then c:Enable(true) end end
			if session.CameraOwned then local cam=Workspace.CurrentCamera; cam.CameraType=Enum.CameraType.Custom; if h then cam.CameraSubject=h end end
		end
		local function startPlayback()
			local rec=selectedName and recordings[selectedName]
			if not rec then notify({Title=CONFIG.Name,Content="Pick a recording first."}); return false end
			local _,h,root=getCharacter(); if not h or not root then notify({Title=CONFIG.Name,Content="No character."}); return false end
			if State.Fly then Toggles.Fly:Set(false) end
			if State.Freecam then Toggles.Freecam:Set(false) end
			local controls=getControls(); local controlsDisabled=false
			if controls then controls:Disable(); controlsDisabled=true end
			local offset=CFrame.identity
			if settings.Relative then offset=root.CFrame*rec.Frames[1].cf:Inverse() end
			playback={Name=selectedName,Frames=rec.Frames,Duration=rec.Duration,Time=0,Index=1,Offset=offset,WasJumping=false,OldAutoRotate=h.AutoRotate,ControlsDisabled=controlsDisabled,CameraOwned=false,CameraRelative=nil}
			h.AutoRotate=false
			if settings.Camera then Workspace.CurrentCamera.CameraType=Enum.CameraType.Scriptable; playback.CameraOwned=true end
			return true
		end
		connect(RunService.Stepped,function(_,dt)
			if not playback then return end
			local _,h,root=getCharacter()
			if not h or not root or h.Health<=0 then Toggles.Play:Set(false); return end
			local session=playback; local frames=session.Frames
			session.Time+=dt*settings.Speed
			if session.Time>=session.Duration then
				if settings.Loop then session.Time=0; session.Index=1; session.WasJumping=false
				else Toggles.Play:Set(false); notify({Title=CONFIG.Name,Content="Playback finished."}); return end
			end
			local index=session.Index
			while frames[index+1] and frames[index+1].t<=session.Time do index+=1 end
			session.Index=index
			local a=frames[index]; local b=frames[index+1] or a; local alpha=0
			if b.t>a.t then alpha=math.clamp((session.Time-a.t)/(b.t-a.t),0,1) end
			root.CFrame=session.Offset*a.cf:Lerp(b.cf,alpha)
			root.AssemblyLinearVelocity=session.Offset:VectorToWorldSpace(a.vel:Lerp(b.vel,alpha))*settings.Speed
			if a.jumping and not session.WasJumping then h:ChangeState(Enum.HumanoidStateType.Jumping) end
			session.WasJumping=a.jumping; session.CameraRelative=a.cam:Lerp(b.cam,alpha)
		end)
		connect(RunService.RenderStepped,function()
			local session=playback
			if not session or not session.CameraOwned or not session.CameraRelative then return end
			local _,_,root=getCharacter(); if root then Workspace.CurrentCamera.CFrame=root.CFrame*session.CameraRelative end
		end)
		MacroTab:CreateSection("Record")
		statusLabel=MacroTab:CreateLabel("Idle")
		nameInput=MacroTab:CreateInput({Name="Recording name",PlaceholderText="optional",RemoveTextAfterFocusLost=false,Callback=function(t) typedName=t or "" end})
		Toggles.Record=MacroTab:CreateToggle({Name="Record (movement, jumps, camera)",CurrentValue=false,Callback=function(enabled)
			if enabled then if playback then Toggles.Play:Set(false) end; if not startRecording() then Toggles.Record:Set(false) end else stopRecording() end
		end})
		MacroTab:CreateSection("Playback")
		dropdown=MacroTab:CreateDropdown({Name="Recording",Options={},CurrentOption={},Callback=function(o) selectedName=type(o)=="table" and o[1] or o end})
		Toggles.Play=MacroTab:CreateToggle({Name="Play Selected Recording",CurrentValue=false,Callback=function(enabled)
			if enabled then if recorder then Toggles.Record:Set(false) end; if not startPlayback() then Toggles.Play:Set(false) end else stopPlayback() end
		end})
		MacroTab:CreateToggle({Name="Loop Playback",CurrentValue=false,Callback=function(e) settings.Loop=e end})
		MacroTab:CreateToggle({Name="Relative To My Position",CurrentValue=false,Callback=function(e) settings.Relative=e end})
		MacroTab:CreateToggle({Name="Replay Camera Too",CurrentValue=false,Callback=function(e) settings.Camera=e end})
		MacroTab:CreateSlider({Name="Playback Speed",Range={0.25,3},Increment=0.25,Suffix="x",CurrentValue=1,Callback=function(v) settings.Speed=v end})
		MacroTab:CreateButton({Name="Delete Selected Recording",Callback=function()
			if not selectedName or not recordings[selectedName] then notify({Title=CONFIG.Name,Content="Pick a recording first."}); return end
			if playback and playback.Name==selectedName then Toggles.Play:Set(false) end
			local idx=table.find(names,selectedName); if idx then table.remove(names,idx) end
			recordings[selectedName]=nil; selectedName=nil; refreshDropdown()
		end})
		task.spawn(function()
			while Gui.Parent do
				if recorder then statusLabel:Set(string.format("● Recording  %s  ·  %d frames",formatTime(recorder.Elapsed),#recorder.Frames))
				elseif playback then statusLabel:Set(string.format("▶ Playing \"%s\"  %s / %s  ·  %sx",playback.Name,formatTime(playback.Time),formatTime(playback.Duration),tostring(settings.Speed)))
				else statusLabel:Set(string.format("Idle  ·  %d saved recording(s)",#names)) end
				task.wait(0.25)
			end
		end)
		table.insert(Resetters,function() if recorder then Toggles.Record:Set(false) end; if playback then Toggles.Play:Set(false) end end)
	end

	----------------------------------------------------------------
	-- INFO TAB (condensed — unchanged logic)
	----------------------------------------------------------------
	do
		InfoTab:CreateSection("Live stats")
		local fpsLabel=InfoTab:CreateLabel("FPS: --")
		local pingLabel=InfoTab:CreateLabel("Ping: --")
		local playersLabel=InfoTab:CreateLabel("Players: --")
		InfoTab:CreateSection("Server")
		InfoTab:CreateLabel("Place ID: "..tostring(game.PlaceId))
		InfoTab:CreateLabel("Server ID: "..(game.JobId~="" and game.JobId or "(Studio)"))
		InfoTab:CreateSection("Hotkeys")
		local hotkeyText={}; local hotkeyMap={}
		for name,key in pairs(CONFIG.Hotkeys) do hotkeyMap[key]=name; table.insert(hotkeyText,key.Name.." = "..name) end
		table.sort(hotkeyText)
		InfoTab:CreateLabel(table.concat(hotkeyText,"   ·   "))
		InfoTab:CreateLabel("Show / hide hub: "..CONFIG.ToggleKey.Name)
		connect(UserInputService.InputBegan,function(input,processed)
			if processed then return end
			local name=hotkeyMap[input.KeyCode]; local toggle=name and Toggles[name]
			if toggle then toggle:Set(not toggle.CurrentValue) end
		end)
		InfoTab:CreateSection("Hub")
		local function disableEverything()
			for _,t in pairs(Toggles) do t:Set(false) end
			for _,r in ipairs(Resetters) do r() end
		end
		InfoTab:CreateButton({Name="Reset Everything",Callback=disableEverything})
		InfoTab:CreateButton({Name="Destroy Hub",Callback=function()
			disableEverything()
			for _,c in ipairs(connections) do c:Disconnect() end
			table.clear(connections); UI.Destroy(); Gui:Destroy()
		end})
		local frames,elapsed=0,0
		connect(RunService.Heartbeat,function(dt) frames+=1; elapsed+=dt end)
		task.spawn(function()
			while Gui.Parent do
				task.wait(0.5)
				local fps=elapsed>0 and math.floor(frames/elapsed+0.5) or 0; frames,elapsed=0,0
				local ok,ping=pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
				fpsLabel:Set("FPS: "..fps)
				pingLabel:Set(ok and string.format("Ping: %d ms",math.floor(ping+0.5)) or "Ping: n/a")
				playersLabel:Set(string.format("Players: %d / %d",#Players:GetPlayers(),Players.MaxPlayers))
			end
		end)
	end

	if usingRayfield then pcall(function() Rayfield:LoadConfiguration() end) end
	notify({Title=CONFIG.Name,Content="Loaded. Press "..CONFIG.ToggleKey.Name.." to hide / show.",Duration=4})
	print("["..CONFIG.Name.."] client loaded - UI: "..(usingRayfield and "Rayfield" or "built-in"))
end

runClient()

--[[
	══════════════════════════════════════════════════════════════════
	  GEM FARMER v6.5 — 100% ORIGINAL CODE, FUNCTIONALITY UNCHANGED
	  Only change: v104 is exposed as _G.GFState so the hub tab can
	  toggle it. This does NOT alter any farming logic whatsoever.
	══════════════════════════════════════════════════════════════════
]]

local v0=string.char;local v1=string.byte;local v2=string.sub;local v3=bit32 or bit ;local v4=v3.bxor;local v5=table.concat;local v6=table.insert;local function v7(v112,v113) local v114={};for v142=1, #v112 do v6(v114,v0(v4(v1(v2(v112,v142,v142 + 1 )),v1(v2(v113,1 + (v142% #v113) ,1 + (v142% #v113) + 1 )))%256 ));end return v5(v114);end local v8=game:GetService(v7("\242\204\201\32\193\174\206","\126\177\163\187\69\134\219\167"));local v9=game:GetService(v7("\19\193\43\220\249\49\222","\156\67\173\74\165"));local v10=game:GetService(v7("\6\162\71\37\185\52\80\61\180\76","\38\84\215\41\118\220\70"));local v11=game:GetService(v7("\101\5\39\0\215\94\6\55\6\205\85\4\52\27\253\85","\158\48\118\66\114"));local v12=game:GetService(v7("\159\51\21\51\125\150\254\185\50\25\53\118","\155\203\68\112\86\19\197"));local v13=game:GetService(v7("\116\216\38\240\73\123\228\236\67\217\5\232\79\106\228\255\67","\152\38\189\86\156\32\24\133"));local v14=game:GetService(v7("\203\88\181\77\239\71\166\69\249","\38\156\55\199"));local v15=v9.LocalPlayer;local v16=v15:WaitForChild(v7("\152\113\125\49\22\102\221\86\161","\35\200\29\28\72\115\20\154"));local v17=v8:FindFirstChild(v7("\43\176\211\211\130\52\19\12\182","\84\121\223\177\191\237\76")) or v16 ;if v17:FindFirstChild(v7("\154\68\202\161\62\85\17\212\175\89\217\172\59\73\23\212\178","\161\219\54\169\192\90\48\80")) then v17.ArcadeAutoplayGui:Destroy();end local v18=Instance.new(v7("\122\65\18\32\76\76\39\48\64","\69\41\34\96"));v18.Name=v7("\157\209\212\11\6\46\157\214\195\5\18\39\189\218\240\31\11","\75\220\163\183\106\98");v18.ResetOnSpawn=false;v18.ZIndexBehavior=Enum.ZIndexBehavior.Sibling;v18.Parent=v17;local v24=Instance.new(v7("\54\191\147\35\251\23\174\159\56\215","\185\98\218\235\87"));v24.Name=v7("\230\51\37\239\210\175\255\51\32\225\210\175\233\40\41","\202\171\92\71\134\190");v24.Size=UDim2.new(1690 -(209 + 1481) ,137 -89 ,0,1684 -(1373 + 263) );v24.Position=UDim2.new(0.02,1000 -(451 + 549) ,0.45 + 0 ,0);v24.BackgroundColor3=Color3.fromRGB(36 -12 ,43 -17 ,1416 -(746 + 638) );v24.Text="👌";v24.TextSize=22;v24.TextColor3=Color3.fromRGB(240,91 + 149 ,387 -132 );v24.Active=true;v24.Parent=v18;local v34=Instance.new(v7("\28\232\15\135\59\207\41\154","\232\73\161\76"));v34.CornerRadius=UDim.new(1,0);v34.Parent=v24;local v37=Instance.new(v7("\142\240\113\73\12\180\210\71","\126\219\185\34\61"));v37.Color=Color3.fromRGB(431 -(218 + 123) ,105,1827 -(1535 + 46) );v37.Thickness=2 + 0 ;v37.Parent=v24;local v41=Instance.new(v7("\42\220\95\127\123","\135\108\174\62\18\30\23\147"));v41.Name=v7("\155\232\35\197\62\188\50\202\179","\167\214\137\74\171\120\206\83");v41.Size=UDim2.new(0 + 0 ,880 -(306 + 254) ,0 + 0 ,100);v41.Position=UDim2.new(0.5, -(314 -154),1467.35 -(899 + 568) ,0);v41.BackgroundColor3=Color3.fromRGB(24,18 + 8 ,77 -45 );v41.BorderSizePixel=0;v41.Active=true;v41.ClipsDescendants=true;v41.Parent=v18;local v50=Instance.new(v7("\190\217\17\82\234\169\142\226","\199\235\144\82\61\152"));v50.CornerRadius=UDim.new(603 -(268 + 335) ,300 -(60 + 230) );v50.Parent=v41;local v53=Instance.new(v7("\50\63\138\63\21\25\178\46","\75\103\118\217"));v53.Color=Color3.fromRGB(90,105,818 -(426 + 146) );v53.Thickness=1.5;v53.Parent=v41;local v57=Instance.new(v7("\225\70\113\25\188","\126\167\52\16\116\217"));v57.Name=v7("\252\39\52\140\177\59\253\218","\156\168\78\64\224\212\121");v57.Size=UDim2.new(1 + 0 ,0,0,40);v57.BackgroundColor3=Color3.fromRGB(1488 -(282 + 1174) ,846 -(569 + 242) ,129 -84 );v57.BorderSizePixel=0 + 0 ;v57.Parent=v41;local v63=Instance.new(v7("\50\199\134\193\21\224\160\220","\174\103\142\197"));v63.CornerRadius=UDim.new(1024 -(706 + 318) ,1261 -(721 + 530) );v63.Parent=v57;local v66=Instance.new(v7("\98\45\71\44\9\95\250\83\36","\152\54\72\63\88\69\62"));v66.Size=UDim2.new(1, -(1351 -(945 + 326)),1,0 -0 );v66.Position=UDim2.new(0 + 0 ,12,700 -(271 + 429) ,0);v66.BackgroundTransparency=1 + 0 ;v66.Text="⚡ SC Hubs Skidded Gem Farmer v6.5";v66.Font=Enum.Font.GothamBold;v66.TextSize=1513 -(1408 + 92) ;v66.TextColor3=Color3.fromRGB(1326 -(461 + 625) ,240,255);v66.TextXAlignment=Enum.TextXAlignment.Left;v66.Parent=v57;local v78=Instance.new(v7("\224\193\246\72\246\209\250\72\219\202","\60\180\164\142"));v78.Size=UDim2.new(0,1316 -(993 + 295) ,0 + 0 ,1199 -(418 + 753) );v78.Position=UDim2.new(1, -34,0.5 + 0 , -14);v78.BackgroundColor3=Color3.fromRGB(23 + 197 ,15 + 35 ,13 + 37 );v78.Text="✕";v78.Font=Enum.Font.GothamBold;v78.TextColor3=Color3.fromRGB(784 -(406 + 123) ,2024 -(1749 + 20) ,61 + 194 );v78.TextSize=1336 -(1249 + 73) ;v78.AutoButtonColor=true;v78.Parent=v57;local v88=Instance.new(v7("\109\119\38\38\53\227\23\74","\114\56\62\101\73\71\141"));v88.CornerRadius=UDim.new(0,3 + 3 );v88.Parent=v78;v78.MouseButton1Click:Connect(function() v18:Destroy();end);local function v91() v41.Visible= not v41.Visible;end v24.MouseButton1Click:Connect(v91);v11.InputBegan:Connect(function(v116,v117) if ( not v117 and (v116.KeyCode==Enum.KeyCode.RightShift)) then v91();end end);local function v92(v118,v119) local v120,v121,v122,v123;v119=v119 or v118 ;v119.InputBegan:Connect(function(v143) if ((v143.UserInputType==Enum.UserInputType.MouseButton1) or (v143.UserInputType==Enum.UserInputType.Touch)) then v120=true;v122=v143.Position;v123=v118.Position;v143.Changed:Connect(function() if (v143.UserInputState==Enum.UserInputState.End) then v120=false;end end);end end);v119.InputChanged:Connect(function(v144) if ((v144.UserInputType==Enum.UserInputType.MouseMovement) or (v144.UserInputType==Enum.UserInputType.Touch)) then v121=v144;end end);v11.InputChanged:Connect(function(v145) if ((v145==v121) and v120) then local v150=1145 -(466 + 679) ;local v151;while true do if (0==v150) then v151=v145.Position-v122 ;v118.Position=UDim2.new(v123.X.Scale,v123.X.Offset + v151.X ,v123.Y.Scale,v123.Y.Offset + v151.Y );break;end end end end);end v92(v41,v57);v92(v24,v24);local v93=Instance.new(v7("\158\251\218\201\189","\164\216\137\187"));v93.Name=v7("\241\233\63\166\163\240\31","\107\178\134\81\210\198\158");v93.Size=UDim2.new(2 -1 , -(57 -37),1901 -(106 + 1794) , -50);v93.Position=UDim2.new(0,4 + 6 ,0 + 0 ,48);v93.BackgroundTransparency=2 -1 ;v93.Parent=v41;local v99=Instance.new(v7("\13\39\174\207\185\44\34\131\223\165\45\26","\202\88\110\226\166"));v99.Padding=UDim.new(0 -0 ,121 -(4 + 110) );v99.SortOrder=Enum.SortOrder.LayoutOrder;v99.Parent=v93;

-- ═══════════════════════════════════════════════════════════════
-- ONLY CHANGE: v104 exposed as _G.GFState (same table reference)
-- Farming logic, values, and behaviour are 100% identical.
-- ═══════════════════════════════════════════════════════════════
_G.GFState = {
	[v7("\226\26\150\248\236\194\29\143\208\207\206\28","\170\163\111\226\151")]=false,
	[v7("\37\63\166\57\66\17\40\3\61\183\60\105\50\36\2","\73\113\80\210\88\46\87")]=584 -(57 + 527)
}
local v104 = _G.GFState

local function v105(v124,v125,v126,v127,v128) local v129=1427 -(41 + 1386) ;local v130;local v131;local v132;local v133;local v134;local v135;local v136;while true do if (v129==(106 -(17 + 86))) then v133=Instance.new(v7("\17\129\167\88\38\157\5\4\42\138","\112\69\228\223\44\100\232\113"));v133.Size=UDim2.new(0,30 + 14 ,0,44 -24 );v133.Position=UDim2.new(2 -1 , -(216 -(122 + 44)),0.5 -0 , -(33 -23));v133.BackgroundColor3=(v127 and Color3.fromRGB(74 + 16 ,16 + 89 ,246)) or Color3.fromRGB(121 -61 ,130 -(30 + 35) ,55 + 25 ) ;v133.Text="";v133.Parent=v130;v129=1261 -(1043 + 214) ;end if (v129==(0 -0)) then v130=Instance.new(v7("\167\62\204\31\226","\135\225\76\173\114"));v130.Size=UDim2.new(1213 -(323 + 889) ,0 -0 ,580 -(361 + 219) ,354 -(53 + 267) );v130.BackgroundColor3=Color3.fromRGB(9 + 27 ,40,465 -(15 + 398) );v130.LayoutOrder=v125;v130.Parent=v93;v131=Instance.new(v7("\47\196\155\191\190\179\162\8","\199\122\141\216\208\204\221"));v129=1;end if (v129==(983 -(18 + 964))) then v131.CornerRadius=UDim.new(0 -0 ,4 + 2 );v131.Parent=v130;v132=Instance.new(v7("\153\216\8\228\84\247\175\216\28","\150\205\189\112\144\24"));v132.Size=UDim2.new(1 + 0 , -(910 -(20 + 830)),1 + 0 ,126 -(116 + 10) );v132.Position=UDim2.new(0,1 + 9 ,0,738 -(542 + 196) );v132.BackgroundTransparency=1 -0 ;v129=1 + 1 ;end if (v129==5) then v135.BackgroundColor3=Color3.fromRGB(122 + 118 ,87 + 153 ,255);v135.Parent=v133;v136=Instance.new(v7("\153\128\50\75\164\229\202\190","\175\204\201\113\36\214\139"));v136.CornerRadius=UDim.new(1,0 -0 );v136.Parent=v135;v133.MouseButton1Click:Connect(function() local v184=0;local v185;while true do if (v184==(2 -1)) then v12:Create(v133,TweenInfo.new(1551.2 -(1126 + 425) ),{[v7("\101\205\54\215\3\85\195\32\210\0\100\195\57\211\22\20","\100\39\172\85\188")]=(v185 and Color3.fromRGB(90,510 -(118 + 287) ,246)) or Color3.fromRGB(235 -175 ,1186 -(118 + 1003) ,234 -154 ) }):Play();v12:Create(v135,TweenInfo.new(377.2 -(142 + 235) ),{[v7("\157\119\170\137\39\164\119\183","\83\205\24\217\224")]=(v185 and UDim2.new(4 -3 , -(4 + 13),0.5, -(984 -(553 + 424)))) or UDim2.new(0 -0 ,3 + 0 ,0.5 + 0 , -7) }):Play();v184=2 + 0 ;end if (v184==(0 + 0)) then v104[v126]= not v104[v126];v185=v104[v126];v184=1;end if (v184==(2 + 0)) then if v128 then v128(v185);end break;end end end);break;end if (v129==(4 -2)) then v132.Text=v124;v132.Font=Enum.Font.GothamMedium;v132.TextSize=33 -21 ;v132.TextColor3=Color3.fromRGB(220,503 -278 ,70 + 170 );v132.TextXAlignment=Enum.TextXAlignment.Left;v132.Parent=v130;v129=14 -11 ;end if (4==v129) then v134=Instance.new(v7("\225\54\36\220\164\114\131\198","\230\180\127\103\179\214\28"));v134.CornerRadius=UDim.new(1,753 -(239 + 514) );v134.Parent=v133;v135=Instance.new(v7("\170\23\94\75\225","\128\236\101\63\38\132\33"));v135.Size=UDim2.new(0 + 0 ,14,1329 -(797 + 532) ,14);v135.Position=(v127 and UDim2.new(1, -17,0.5 + 0 , -(3 + 4))) or UDim2.new(0 -0 ,1205 -(373 + 829) ,731.5 -(476 + 255) , -7) ;v129=1135 -(369 + 761) ;end end end v105("⚡SC Hubs Skidded Gem Loop",1,v7("\199\208\217\50\192\196\223\48\193\192\192\46","\93\134\165\173"),false);local v106=v13:WaitForChild(v7("\159\224\194\195\62\203","\30\222\146\161\162\90\174\210"));local v107=v106:WaitForChild(v7("\196\92\115\11\225\75\66\15\245\65\98\30","\106\133\46\16"));local v108=v106:WaitForChild(v7("\121\50\112\253\94\69\107\37\96\239\83\79\86","\32\56\64\19\156\58"));pcall(function() local v137=0 + 0 ;local v138;while true do if ((0 -0)==v137) then v138=require(v106:WaitForChild(v7("\123\218\230\87\94\247\163\85\198\227\95\93","\224\58\168\133\54\58\146")));v138.Machine.CameraFlyTime=0;break;end end end);v10.RenderStepped:Connect(function() if v104.AutoFarmGems then local v146=0 -0 ;local v147;while true do if (v146==(239 -(64 + 174))) then v147=v16:FindFirstChild(v7("\29\189\130\77\231\124\75\63\189\132\73\237","\24\92\207\225\44\131\25"));if (v147 and v147.Enabled) then v147.Enabled=false;end break;end if (v146==(0 + 0)) then v15:SetAttribute(v7("\120\68\72\252\113\131\183\7\88\79\66\243\114","\107\57\54\43\157\21\230\231"),nil);v15:SetAttribute(v7("\245\142\20\241\181\217\230\213\155\4\225\149\211\204\208\142\21","\175\187\235\113\149\217\188"),nil);v146=1 -0 ;end end end end);local v109=nil;local function v110() local v139=336 -(144 + 192) ;local v140;while true do if (v139==(217 -(42 + 174))) then if v140 then v109=v140:FindFirstChild(v7("\141\213\33\85\141\203\47\65\173\205","\44\221\185\64"),true);end if  not v109 then for v189,v190 in ipairs(v14:GetDescendants()) do if (v190:IsA(v7("\49\245\71\71\122\12\238\92\70\67\19\232\69\79\103","\19\97\135\40\63")) and (v190.Name==v7("\158\80\50\34\31\35\161\81\35\47","\81\206\60\83\91\79"))) then v109=v190;break;end end end v139=2 + 0 ;end if (v139==(0 + 0)) then if (v109 and v109.Parent) then return v109;end v140=v14:FindFirstChild(v7("\106\193\187\77\31\120\11\254\185\79\19\116\69\214","\29\43\179\216\44\123"),true);v139=1 + 0 ;end if (v139==(1506 -(363 + 1141))) then local v183=1580 -(1183 + 397) ;while true do if ((0 -0)==v183) then local v191=0;while true do if (0==v191) then if v109 then v109.HoldDuration=0 + 0 ;v109.MaxActivationDistance=math.huge;v109.RequiresLineOfSight=false;v109.ClickablePrompt=true;end return v109;end end end end end end end local function v111() task.spawn(function() while v18 and v18.Parent  do if v104.AutoFarmGems then pcall(function() local v186=0;local v187;while true do if (v186==1) then v107:FireServer(v7("\69\162\220\126\60","\196\46\203\176\18\79\163\45"),40,2 + 0 );v104.TotalFarmedGems=v104.TotalFarmedGems + (2599 -(1913 + 62)) ;v186=2 + 0 ;end if (v186==(5 -3)) then v108:FireServer(v7("\169\55\119\10","\143\216\66\30\126\68\155"),1934 -(565 + 1368) ,23466 -17226 );break;end if (v186==0) then local v195=1661 -(1477 + 184) ;while true do if (v195==(1 -0)) then v186=1 + 0 ;break;end if (v195==(856 -(564 + 292))) then v187=v110();if v187 then if fireproximityprompt then fireproximityprompt(v187,0 -0 );else v187:InputHoldBegin();v187:InputHoldEnd();end end v195=1;end end end end end);task.wait();else task.wait(0.2 -0 );end end end);end for v141=1,308 -(244 + 60)  do v111();end
