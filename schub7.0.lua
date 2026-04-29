--// SERVICES
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer

--// GUI
local gui = Instance.new("ScreenGui")
gui.Name = "CleanHubUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

--// MAIN FRAME
local main = Instance.new("Frame")
main.Size = UDim2.new(0, 340, 0, 420)
main.Position = UDim2.new(0.5, -170, 0.5, -210)
main.BackgroundColor3 = Color3.fromRGB(25,25,25)
main.Parent = gui
Instance.new("UICorner", main)

--// DRAG SYSTEM
local dragging, dragStart, startPos

main.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = main.Position
	end
end)

UIS.InputChanged:Connect(function(input)
	if dragging then
		local delta = input.Position - dragStart
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

--// MINIMIZE AVATAR CIRCLE
local circle = Instance.new("ImageButton")
circle.Size = UDim2.new(0, 60, 0, 60)
circle.Position = UDim2.new(0, 20, 0.5, -30)
circle.BackgroundColor3 = Color3.fromRGB(40,40,40)
circle.Visible = false
circle.Parent = gui
Instance.new("UICorner", circle).CornerRadius = UDim.new(1,0)

circle.Image = "rbxthumb://type=AvatarHeadShot&id="..player.UserId.."&w=420&h=420"

-- circle drag
local cDrag, cStart, cPos

circle.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
		cDrag = true
		cStart = i.Position
		cPos = circle.Position
	end
end)

UIS.InputChanged:Connect(function(i)
	if cDrag then
		local delta = i.Position - cStart
		circle.Position = UDim2.new(
			cPos.X.Scale,
			cPos.X.Offset + delta.X,
			cPos.Y.Scale,
			cPos.Y.Offset + delta.Y
		)
	end
end)

UIS.InputEnded:Connect(function()
	cDrag = false
end)

--// MINIMIZE BUTTON
local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0,30,0,30)
minBtn.Position = UDim2.new(1,-35,0,5)
minBtn.Text = "-"
minBtn.BackgroundColor3 = Color3.fromRGB(200,0,0)
minBtn.Parent = main

local minimized = false

minBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	main.Visible = not minimized
	circle.Visible = minimized
end)

circle.MouseButton1Click:Connect(function()
	minimized = false
	main.Visible = true
	circle.Visible = false
end)

--// SIDE TABS
local side = Instance.new("Frame")
side.Size = UDim2.new(0,100,1,0)
side.BackgroundColor3 = Color3.fromRGB(35,35,35)
side.Parent = main

local content = Instance.new("Frame")
content.Size = UDim2.new(1,-100,1,0)
content.Position = UDim2.new(0,100,0,0)
content.BackgroundTransparency = 1
content.Parent = main

local function createTab(name, y)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1,0,0,50)
	b.Position = UDim2.new(0,0,0,y)
	b.Text = name
	b.BackgroundColor3 = Color3.fromRGB(50,50,50)
	b.Parent = side
	return b
end

local tabs = {
	createTab("Casual", 0),
	createTab("Teleport", 50),
	createTab("ESP", 100)
}

local frames = {}

local function newFrame()
	local f = Instance.new("Frame")
	f.Size = UDim2.new(1,0,1,0)
	f.Visible = false
	f.BackgroundTransparency = 1
	f.Parent = content
	table.insert(frames, f)
	return f
end

local casual = newFrame()
local tp = newFrame()
local esp = newFrame()

local function switch(frame)
	for _,v in pairs(frames) do
		v.Visible = false
	end
	frame.Visible = true
end

tabs[1].MouseButton1Click:Connect(function() switch(casual) end)
tabs[2].MouseButton1Click:Connect(function() switch(tp) end)
tabs[3].MouseButton1Click:Connect(function() switch(esp) end)

switch(casual)

--// UI HELPERS
local function button(text, y, parent)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1,-20,0,35)
	b.Position = UDim2.new(0,10,0,y)
	b.Text = text
	b.BackgroundColor3 = Color3.fromRGB(60,60,60)
	b.Parent = parent
	return b
end

local function label(text, y, parent)
	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(1,-20,0,25)
	l.Position = UDim2.new(0,10,0,y)
	l.Text = text
	l.BackgroundTransparency = 1
	l.TextColor3 = Color3.new(1,1,1)
	l.Parent = parent
	return l
end

--// CASUAL TAB (PLACEHOLDERS ONLY)
button("Feature Slot 1",10,casual)
button("Feature Slot 2",50,casual)

--// TELEPORT TAB (PLACEHOLDERS)
button("Teleport Slot 1",10,tp)
button("Teleport Slot 2",50,tp)

--// ESP TAB (SLIDER UI ONLY FIXED)
label("Color Slider",10,esp)

local slider = Instance.new("Frame")
slider.Size = UDim2.new(1,-20,0,10)
slider.Position = UDim2.new(0,10,0,40)
slider.BackgroundColor3 = Color3.fromRGB(255,255,255)
slider.Parent = esp

local knob = Instance.new("Frame")
knob.Size = UDim2.new(0,10,1,0)
knob.BackgroundColor3 = Color3.fromRGB(0,170,255)
knob.Parent = slider

local draggingSlider = false

knob.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseBu...
