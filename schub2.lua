--[[
	══════════════════════════════════════════════════════════════════
	  SC HUB  ·  FREE ACCESS  ·  + GEM FARMER
	  Merged: SC Hub + Skidded Gem Farmer v6.5
	══════════════════════════════════════════════════════════════════
]]

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

if RunService:IsServer() then
	warn("[Sc Hub] This file must be a LocalScript inside StarterPlayerScripts, not a Script.")
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

--------------------------------------------------------------------
-- GEM FARMER STATE & HELPERS
--------------------------------------------------------------------
local GemFarmer = {
	Enabled = false,
	TotalFarmed = 0,
	PromptCache = nil,
}

local function findGemPrompt()
	if GemFarmer.PromptCache and GemFarmer.PromptCache.Parent then
		return GemFarmer.PromptCache
	end
	for _, desc in ipairs(workspace:GetDescendants()) do
		if desc:IsA("ProximityPrompt") and desc.Name == "Collect" then
			GemFarmer.PromptCache = desc
			return desc
		end
	end
	return nil
end

local function firePrompt(prompt)
	if prompt then
		prompt:InputHoldBegin()
		task.wait(0.05)
		prompt:InputHoldEnd()
	end
end

--------------------------------------------------------------------
-- CLIENT
--------------------------------------------------------------------

local function runClient()
	local TweenService = game:GetService("TweenService")
	local UserInputService = game:GetService("UserInputService")
	local Lighting = game:GetService("Lighting")
	local Workspace = game:GetService("Workspace")
	local Stats = game:GetService("Stats")
	local PlayersService = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local LocalPlayer = PlayersService.LocalPlayer
	local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

	while not Workspace.CurrentCamera do
		task.wait()
	end

	local existing = PlayerGui:FindFirstChild("ScHub")
	if existing then
		existing:Destroy()
	end

	----------------------------------------------------------------
	-- UI TOOLKIT (Rayfield-style)
	----------------------------------------------------------------

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

	local connections = {}

	local function connect(signal, callback)
		local connection = signal:Connect(callback)
		table.insert(connections, connection)
		return connection
	end

	local function safeCall(callback, ...)
		if callback then
			local ok, err = pcall(callback, ...)
			if not ok then
				warn("[" .. CONFIG.Name .. "] " .. tostring(err))
			end
		end
	end

	local function make(className, props, parent)
		local object = Instance.new(className)
		for key, value in pairs(props) do
			object[key] = value
		end
		object.Parent = parent
		return object
	end

	local function corner(object, radius)
		return make("UICorner", { CornerRadius = UDim.new(0, radius) }, object)
	end

	local function outline(object)
		return make("UIStroke", {
			Color = THEME.Stroke,
			Thickness = 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}, object)
	end

	local function padding(object, left, top, right, bottom)
		return make("UIPadding", {
			PaddingLeft = UDim.new(0, left),
			PaddingTop = UDim.new(0, top),
			PaddingRight = UDim.new(0, right),
			PaddingBottom = UDim.new(0, bottom),
		}, object)
	end

	local function isPointer(input)
		return input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
	end

	local function isPointerMove(input)
		return input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch
	end

	local Gui = make("ScreenGui", {
		Name = "ScHub",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 100,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, PlayerGui)

	local function buildBuiltInUI()
	----------------------------------------------------------------
	-- Notifications
	----------------------------------------------------------------

	local NotifyHolder = make("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -12, 1, -12),
		Size = UDim2.new(0, 270, 1, -24),
		ZIndex = 50,
	}, Gui)

	make("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
	}, NotifyHolder)

	local function notify(data)
		if not Gui.Parent then
			return
		end

		local card = make("CanvasGroup", {
			BackgroundColor3 = THEME.Topbar,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			GroupTransparency = 1,
		}, NotifyHolder)
		corner(card, 8)
		outline(card)
		padding(card, 12, 10, 12, 10)
		make("UIListLayout", {
			Padding = UDim.new(0, 3),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, card)

		make("TextLabel", {
			LayoutOrder = 1,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 16),
			Text = data.Title or CONFIG.Name,
			TextColor3 = THEME.Text,
			Font = Enum.Font.GothamBold,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, card)

		make("TextLabel", {
			LayoutOrder = 2,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Text = data.Content or "",
			TextColor3 = THEME.SubText,
			Font = Enum.Font.Gotham,
			TextSize = 13,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, card)

		TweenService:Create(card, TweenInfo.new(0.25), { GroupTransparency = 0 }):Play()

		task.delay(data.Duration or 4, function()
			if card.Parent then
				local tween = TweenService:Create(card, TweenInfo.new(0.3), { GroupTransparency = 1 })
				tween.Completed:Connect(function()
					card:Destroy()
				end)
				tween:Play()
			end
		end)
	end

	----------------------------------------------------------------
	-- Window
	----------------------------------------------------------------

	local function windowSize()
		local viewport = Workspace.CurrentCamera.ViewportSize
		return math.min(500, viewport.X * 0.94), math.min(470, viewport.Y * 0.8)
	end

	local width, height = windowSize()
	local minimized = false

	local Main = make("Frame", {
		Name = "Main",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(width, height),
		BackgroundColor3 = THEME.Background,
		BorderSizePixel = 0,
		ClipsDescendants = true,
	}, Gui)
	corner(Main, 10)
	outline(Main)

	local TopBar = make("Frame", {
		BackgroundColor3 = THEME.Topbar,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 44),
	}, Main)

	make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(16, 0),
		Size = UDim2.new(1, -110, 1, 0),
		Text = CONFIG.Name .. "   ·   FREE ACCESS",
		TextColor3 = THEME.Text,
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, TopBar)

	local function topButton(text, rightOffset)
		local button = make("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, rightOffset, 0.5, 0),
			Size = UDim2.fromOffset(30, 30),
			BackgroundColor3 = THEME.Element,
			BorderSizePixel = 0,
			Text = text,
			TextColor3 = THEME.Text,
			Font = Enum.Font.GothamBold,
			TextSize = 14,
		}, TopBar)
		corner(button, 6)
		return button
	end

	local HideButton = topButton("X", -8)
	local MinimizeButton = topButton("—", -44)

	local OpenButton = make("TextButton", {
		Visible = false,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 10, 0.4, 0),
		Size = UDim2.fromOffset(84, 34),
		BackgroundColor3 = THEME.Topbar,
		BorderSizePixel = 0,
		Text = CONFIG.Name,
		TextColor3 = THEME.Text,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
	}, Gui)
	corner(OpenButton, 8)
	outline(OpenButton)

	local function setVisible(visible)
		Main.Visible = visible
		OpenButton.Visible = not visible
	end

	HideButton.Activated:Connect(function()
		setVisible(false)
	end)

	OpenButton.Activated:Connect(function()
		setVisible(true)
	end)

	MinimizeButton.Activated:Connect(function()
		minimized = not minimized
		Main.Size = UDim2.fromOffset(width, minimized and 44 or height)
	end)

	connect(UserInputService.InputBegan, function(input, processed)
		if not processed and input.KeyCode == CONFIG.ToggleKey then
			setVisible(not Main.Visible)
		end
	end)

	connect(Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"), function()
		width, height = windowSize()
		Main.Size = UDim2.fromOffset(width, minimized and 44 or height)
	end)

	local dragStart, startPosition

	TopBar.InputBegan:Connect(function(input)
		if isPointer(input) then
			dragStart = input.Position
			startPosition = Main.Position
		end
	end)

	connect(UserInputService.InputChanged, function(input)
		if dragStart and isPointerMove(input) then
			local delta = input.Position - dragStart
			Main.Position = UDim2.new(
				startPosition.X.Scale, startPosition.X.Offset + delta.X,
				startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
			)
		end
	end)

	connect(UserInputService.InputEnded, function(input)
		if dragStart and isPointer(input) then
			dragStart = nil
		end
	end)

	local TabBar = make("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(8, 48),
		Size = UDim2.new(1, -16, 0, 34),
		ScrollBarThickness = 0,
		ScrollingDirection = Enum.ScrollingDirection.X,
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		CanvasSize = UDim2.new(),
	}, Main)

	make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
	}, TabBar)

	local Pages = make("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 88),
		Size = UDim2.new(1, 0, 1, -88),
	}, Main)

	local tabs = {}

	local function selectTab(selected)
		for _, tab in ipairs(tabs) do
			local active = tab == selected
			tab.Page.Visible = active
			tab.Button.BackgroundColor3 = active and THEME.Accent or THEME.Element
			tab.Button.TextColor3 = active and Color3.new(1, 1, 1) or THEME.SubText
		end
	end

	local function createTab(name)
		local Tab = {}

		local button = make("TextButton", {
			LayoutOrder = #tabs + 1,
			Size = UDim2.new(0, 0, 0, 28),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundColor3 = THEME.Element,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = name,
			TextColor3 = THEME.SubText,
			Font = Enum.Font.GothamMedium,
			TextSize = 13,
		}, TabBar)
		corner(button, 6)
		padding(button, 14, 0, 14, 0)

		local page = make("ScrollingFrame", {
			Visible = false,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
			ScrollBarThickness = 3,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.new(),
		}, Pages)
		padding(page, 10, 4, 12, 12)
		make("UIListLayout", {
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, page)

		Tab.Button = button
		Tab.Page = page
		table.insert(tabs, Tab)

		button.Activated:Connect(function()
			selectTab(Tab)
		end)

		if #tabs == 1 then
			selectTab(Tab)
		end

		local order = 0

		local function newElement(elementHeight)
			order += 1
			local frame = make("Frame", {
				LayoutOrder = order,
				Size = UDim2.new(1, 0, 0, elementHeight),
				BackgroundColor3 = THEME.Element,
				BorderSizePixel = 0,
			}, page)
			corner(frame, 6)
			outline(frame)
			return frame
		end

		local function elementTitle(parent, text, rightReserve)
			return make("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(14, 0),
				Size = UDim2.new(1, -(14 + (rightReserve or 14)), 0, 40),
				Text = text,
				TextColor3 = THEME.Text,
				Font = Enum.Font.GothamMedium,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
			}, parent)
		end

		function Tab:CreateSection(sectionName)
			order += 1
			make("TextLabel", {
				LayoutOrder = order,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 26),
				Text = string.upper(sectionName),
				TextColor3 = THEME.SubText,
				Font = Enum.Font.GothamBold,
				TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Left,
			}, page)
		end

		function Tab:CreateLabel(text)
			local frame = newElement(34)
			local label = make("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(14, 0),
				Size = UDim2.new(1, -28, 1, 0),
				Text = text,
				TextColor3 = THEME.SubText,
				Font = Enum.Font.Gotham,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
			}, frame)

			local object = {}
			function object:Set(newText)
				label.Text = newText
			end
			return object
		end

		function Tab:CreateButton(opts)
			local frame = newElement(40)
			elementTitle(frame, opts.Name)

			local click = make("TextButton", {
				BackgroundTransparency = 1,
				Text = "",
				Size = UDim2.fromScale(1, 1),
			}, frame)

			click.Activated:Connect(function()
				TweenService:Create(frame, TweenInfo.new(0.1), { BackgroundColor3 = THEME.ElementHover }):Play()
				task.delay(0.12, function()
					if frame.Parent then
						TweenService:Create(frame, TweenInfo.new(0.2), { BackgroundColor3 = THEME.Element }):Play()
					end
				end)
				safeCall(opts.Callback)
			end)

			return {}
		end

		function Tab:CreateToggle(opts)
			local frame = newElement(40)
			elementTitle(frame, opts.Name, 70)

			local switch = make("Frame", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -12, 0.5, 0),
				Size = UDim2.fromOffset(42, 22),
				BackgroundColor3 = THEME.Off,
				BorderSizePixel = 0,
			}, frame)
			corner(switch, 11)

			local knob = make("Frame", {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 3, 0.5, 0),
				Size = UDim2.fromOffset(16, 16),
				BackgroundColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 0,
			}, switch)
			corner(knob, 8)

			local click = make("TextButton", {
				BackgroundTransparency = 1,
				Text = "",
				Size = UDim2.fromScale(1, 1),
			}, frame)

			local toggle = { CurrentValue = opts.CurrentValue == true }

			local function render(instant)
				local info = TweenInfo.new(instant and 0 or 0.15)
				TweenService:Create(switch, info, {
					BackgroundColor3 = toggle.CurrentValue and THEME.Accent or THEME.Off,
				}):Play()
				TweenService:Create(knob, info, {
					Position = toggle.CurrentValue and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
				}):Play()
			end

			function toggle:Set(value, silent)
				self.CurrentValue = value and true or false
				render()
				if not silent then
					safeCall(opts.Callback, self.CurrentValue)
				end
			end

			click.Activated:Connect(function()
				toggle:Set(not toggle.CurrentValue)
			end)

			render(true)
			return toggle
		end

		function Tab:CreateSlider(opts)
			local min, max = opts.Range[1], opts.Range[2]
			local increment = opts.Increment or 1

			local frame = newElement(58)
			elementTitle(frame, opts.Name, 110).Size = UDim2.new(1, -124, 0, 34)

			local valueLabel = make("TextLabel", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -14, 0, 0),
				Size = UDim2.fromOffset(100, 34),
				TextColor3 = THEME.SubText,
				Font = Enum.Font.Gotham,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Right,
			}, frame)

			local track = make("Frame", {
				Position = UDim2.new(0, 14, 0, 40),
				Size = UDim2.new(1, -28, 0, 8),
				BackgroundColor3 = THEME.Track,
				BorderSizePixel = 0,
			}, frame)
			corner(track, 4)

			local fill = make("Frame", {
				Size = UDim2.fromScale(0, 1),
				BackgroundColor3 = THEME.Accent,
				BorderSizePixel = 0,
			}, track)
			corner(fill, 4)

			local hit = make("TextButton", {
				BackgroundTransparency = 1,
				Text = "",
				Position = UDim2.new(0, 8, 0, 30),
				Size = UDim2.new(1, -16, 0, 28),
			}, frame)

			local slider = { CurrentValue = opts.CurrentValue or min }

			local function snap(value)
				value = math.clamp(value, min, max)
				value = min + math.floor((value - min) / increment + 0.5) * increment
				value = math.floor(value * 1000 + 0.5) / 1000
				return math.clamp(value, min, max)
			end

			local function render()
				local alpha = max > min and (slider.CurrentValue - min) / (max - min) or 0
				fill.Size = UDim2.fromScale(alpha, 1)
				valueLabel.Text = tostring(slider.CurrentValue) .. (opts.Suffix and (" " .. opts.Suffix) or "")
			end

			function slider:Set(value, silent)
				self.CurrentValue = snap(value)
				render()
				if not silent then
					safeCall(opts.Callback, self.CurrentValue)
				end
			end

			local dragging = false

			local function updateFromInput(input)
				local alpha = math.clamp(
					(input.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1),
					0, 1
				)
				local value = snap(min + (max - min) * alpha)
				if value ~= slider.CurrentValue then
					slider:Set(value)
				end
			end

			hit.InputBegan:Connect(function(input)
				if isPointer(input) then
					dragging = true
					page.ScrollingEnabled = false
					updateFromInput(input)
				end
			end)

			connect(UserInputService.InputChanged, function(input)
				if dragging and isPointerMove(input) then
					updateFromInput(input)
				end
			end)

			connect(UserInputService.InputEnded, function(input)
				if dragging and isPointer(input) then
					dragging = false
					page.ScrollingEnabled = true
				end
			end)

			slider.CurrentValue = snap(slider.CurrentValue)
			render()
			return slider
		end

		function Tab:CreateInput(opts)
			local frame = newElement(40)
			elementTitle(frame, opts.Name, 0).Size = UDim2.new(0.4, 0, 0, 40)

			local box = make("TextBox", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -8, 0.5, 0),
				Size = UDim2.new(0.6, -16, 0, 28),
				BackgroundColor3 = Color3.fromRGB(28, 28, 28),
				BorderSizePixel = 0,
				PlaceholderText = opts.PlaceholderText or "",
				PlaceholderColor3 = THEME.SubText,
				Text = "",
				TextColor3 = THEME.Text,
				Font = Enum.Font.Gotham,
				TextSize = 13,
				ClearTextOnFocus = false,
				ClipsDescendants = true,
			}, frame)
			corner(box, 5)
			padding(box, 8, 0, 8, 0)

			box.FocusLost:Connect(function()
				safeCall(opts.Callback, box.Text)
				if opts.RemoveTextAfterFocusLost then
					box.Text = ""
				end
			end)

			local input = {}
			function input:Get()
				return box.Text
			end
			function input:Set(text)
				box.Text = text
			end
			return input
		end

		function Tab:CreateDropdown(opts)
			local ROW, GAP, MAX_ROWS = 30, 3, 5

			local frame = newElement(40)
			frame.ClipsDescendants = true

			local dropdown = {
				Options = opts.Options or {},
				CurrentOption = opts.CurrentOption or {},
			}

			local title = elementTitle(frame, opts.Name, 40)

			make("TextLabel", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -14, 0, 0),
				Size = UDim2.fromOffset(20, 40),
				Text = "▼",
				TextColor3 = THEME.SubText,
				Font = Enum.Font.GothamBold,
				TextSize = 11,
			}, frame)

			local header = make("TextButton", {
				BackgroundTransparency = 1,
				Text = "",
				Size = UDim2.new(1, 0, 0, 40),
			}, frame)

			local list = make("ScrollingFrame", {
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Position = UDim2.fromOffset(6, 44),
				Size = UDim2.new(1, -12, 0, 0),
				ScrollBarThickness = 3,
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				CanvasSize = UDim2.new(),
			}, frame)
			make("UIListLayout", {
				Padding = UDim.new(0, GAP),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}, list)

			local open = false

			local function updateTitle()
				title.Text = opts.Name .. ":  " .. (dropdown.CurrentOption[1] or "None")
			end

			local function resize()
				if open then
					local rows = math.min(#dropdown.Options, MAX_ROWS)
					local listHeight = rows * ROW + math.max(rows - 1, 0) * GAP
					list.Size = UDim2.new(1, -12, 0, listHeight)
					frame.Size = UDim2.new(1, 0, 0, 44 + listHeight + 6)
				else
					list.Size = UDim2.new(1, -12, 0, 0)
					frame.Size = UDim2.new(1, 0, 0, 40)
				end
			end

			local function rebuild()
				for _, child in ipairs(list:GetChildren()) do
					if child:IsA("TextButton") then
						child:Destroy()
					end
				end

				for index, option in ipairs(dropdown.Options) do
					local row = make("TextButton", {
						LayoutOrder = index,
						Size = UDim2.new(1, -6, 0, ROW),
						BackgroundColor3 = THEME.Topbar,
						BorderSizePixel = 0,
						AutoButtonColor = false,
						Text = tostring(option),
						TextColor3 = THEME.Text,
						Font = Enum.Font.Gotham,
						TextSize = 13,
						TextTruncate = Enum.TextTruncate.AtEnd,
					}, list)
					corner(row, 5)

					row.Activated:Connect(function()
						dropdown:Set(option)
						open = false
						resize()
					end)
				end

				resize()
			end

			function dropdown:Set(option, silent)
				self.CurrentOption = option and { option } or {}
				updateTitle()
				if not silent then
					safeCall(opts.Callback, self.CurrentOption)
				end
			end

			function dropdown:Refresh(newOptions)
				self.Options = newOptions
				local current = self.CurrentOption[1]
				if current and not table.find(newOptions, current) then
					self:Set(nil)
				end
				rebuild()
			end

			header.Activated:Connect(function()
				open = not open
				resize()
			end)

			updateTitle()
			rebuild()
			return dropdown
		end

		return Tab
	end

	return { CreateTab = createTab, Notify = notify, Destroy = function() end }
	end

	----------------------------------------------------------------
	-- UI BACKEND: Rayfield when available, built-in otherwise
	----------------------------------------------------------------

	local function loadRayfield()
		local ok, library = pcall(function()
			return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
		end)
		if ok and type(library) == "table" and library.CreateWindow then
			return library
		end
		return nil
	end

	local Rayfield = loadRayfield()
	local UI = nil
	local usingRayfield = false

	if Rayfield then
		local ok, window = pcall(function()
			return Rayfield:CreateWindow({
				Name = CONFIG.Name,
				LoadingTitle = CONFIG.Name,
				LoadingSubtitle = "Free access",
				Theme = "Default",
				ToggleUIKeybind = CONFIG.ToggleKey.Name,
				DisableRayfieldPrompts = true,
				DisableBuildWarnings = true,
				ConfigurationSaving = { Enabled = false },
				KeySystem = false,
			})
		end)

		if ok and window then
			usingRayfield = true
			UI = {
				CreateTab = function(name)
					return window:CreateTab(name)
				end,
				Notify = function(data)
					pcall(function()
						Rayfield:Notify({
							Title = data.Title or CONFIG.Name,
							Content = data.Content or "",
							Duration = data.Duration or 4,
						})
					end)
				end,
				Destroy = function()
					pcall(function()
						Rayfield:Destroy()
					end)
				end,
			}
		end
	end

	if not UI then
		UI = buildBuiltInUI()
	end

	local function notify(data)
		UI.Notify(data)
	end

	local function createTab(name)
		return UI.CreateTab(name)
	end

	----------------------------------------------------------------
	-- SHARED STATE & HELPERS
	----------------------------------------------------------------

	local StarterPlayer = game:GetService("StarterPlayer")
	local TeleportService = game:GetService("TeleportService")

	local State = {
		Target = nil,
		CustomSpeed = nil,
		CustomJump = nil,
		Fly = false,
		FlySpeed = 60,
		Noclip = false,
		InfiniteJump = false,
		ClickTeleport = false,
		AntiAfk = false,
		ESP = false,
		Freecam = false,
		FreecamSpeed = 60,
		PadUp = false,
		PadDown = false,
	}

	local Toggles = {}
	local Resetters = {}

	local function getCharacter()
		local character = LocalPlayer.Character
		if not character then
			return nil, nil, nil
		end
		return character,
			character:FindFirstChildOfClass("Humanoid"),
			character:FindFirstChild("HumanoidRootPart")
	end

	local function starterValue(name, fallback)
		local ok, value = pcall(function()
			return StarterPlayer[name]
		end)
		if ok and value ~= nil then
			return value
		end
		return fallback
	end

	local getControls
	local getMoveVector
	do
		local controls = nil
		local failed = false

		getControls = function()
			if controls or failed then
				return controls
			end
			local ok, result = pcall(function()
				local module = LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule", 5)
				return module and require(module):GetControls()
			end)
			if ok and result then
				controls = result
			else
				failed = true
			end
			return controls
		end

		getMoveVector = function()
			if controls then
				return controls:GetMoveVector()
			end
			if UserInputService:GetFocusedTextBox() then
				return Vector3.zero
			end
			local x = (UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0)
				- (UserInputService:IsKeyDown(Enum.KeyCode.A) and 1 or 0)
			local z = (UserInputService:IsKeyDown(Enum.KeyCode.S) and 1 or 0)
				- (UserInputService:IsKeyDown(Enum.KeyCode.W) and 1 or 0)
			return Vector3.new(x, 0, z)
		end
	end

	local function getVerticalInput()
		local vertical = 0
		if not UserInputService:GetFocusedTextBox() then
			if UserInputService:IsKeyDown(Enum.KeyCode.Space) or UserInputService:IsKeyDown(Enum.KeyCode.E) then
				vertical += 1
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.Q) then
				vertical -= 1
			end
		end
		if State.PadUp then
			vertical += 1
		end
		if State.PadDown then
			vertical -= 1
		end
		return vertical
	end

	local FlyPad = make("Frame", {
		Visible = false,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -16, 0.5, 0),
		Size = UDim2.fromOffset(64, 136),
	}, Gui)

	make("UIListLayout", {
		Padding = UDim.new(0, 8),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
	}, FlyPad)

	local function padButton(text, stateKey)
		local activeInput = nil

		local button = make("TextButton", {
			Size = UDim2.fromOffset(64, 64),
			BackgroundColor3 = THEME.Accent,
			BackgroundTransparency = 0.25,
			BorderSizePixel = 0,
			Text = text,
			TextColor3 = Color3.new(1, 1, 1),
			Font = Enum.Font.GothamBold,
			TextSize = 22,
		}, FlyPad)
		corner(button, 12)

		button.InputBegan:Connect(function(input)
			if isPointer(input) then
				activeInput = input
				State[stateKey] = true
			end
		end)

		button.InputEnded:Connect(function(input)
			if isPointer(input) then
				activeInput = nil
				State[stateKey] = false
			end
		end)

		connect(UserInputService.InputEnded, function(input)
			if activeInput and input == activeInput then
				activeInput = nil
				State[stateKey] = false
			end
		end)
	end

	padButton("▲", "PadUp")
	padButton("▼", "PadDown")

	local function refreshFlyPad()
		local show = (State.Fly or State.Freecam) and UserInputService.TouchEnabled
		FlyPad.Visible = show and true or false
		if not show then
			State.PadUp, State.PadDown = false, false
		end
	end

	----------------------------------------------------------------
	-- TABS
	----------------------------------------------------------------

	local PlayersTab = createTab("Players")
	local SelfTab = createTab("Self")
	local TeleportTab = createTab("Teleport")
	local VisualTab = createTab("Visual")
	local AimTab = createTab("Aim")
	local CrosshairTab = createTab("Crosshair")
	local MacroTab = createTab("Macro")
	local GemFarmerTab = createTab("Gem Farmer")
	local InfoTab = createTab("Info")

	----------------------------------------------------------------
	-- GEM FARMER TAB
	----------------------------------------------------------------
	do
		local statusLabel = GemFarmerTab:CreateLabel("Idle")

		GemFarmerTab:CreateSection("Auto Farm")

		Toggles.GemFarmer = GemFarmerTab:CreateToggle({
			Name = "⚡ SC Hubs Gem Loop",
			CurrentValue = false,
			Callback = function(enabled)
				GemFarmer.Enabled = enabled
				if enabled then
					GemFarmer.TotalFarmed = 0
					notify({ Title = "Gem Farmer", Content = "Started farming gems!", Duration = 3 })
				else
					notify({ Title = "Gem Farmer", Content = "Stopped. Total: " .. GemFarmer.TotalFarmed .. " gems", Duration = 4 })
				end
			end,
		})

		GemFarmerTab:CreateLabel("Total Gems Farmed: 0")
		local totalLabel = GemFarmerTab:CreateLabel("0")

		task.spawn(function()
			while Gui.Parent do
				if GemFarmer.Enabled then
					local prompt = findGemPrompt()
					if prompt then
						firePrompt(prompt)
						GemFarmer.TotalFarmed += 1
						statusLabel:Set("🔄 Farming...  ·  Total: " .. GemFarmer.TotalFarmed)
						totalLabel:Set("💎 " .. GemFarmer.TotalFarmed)
					else
						statusLabel:Set("🔍 Searching for gems...")
					end
					task.wait(0.15)
				else
					statusLabel:Set("⏸️ Idle")
				end
				task.wait(0.1)
			end
		end)

		table.insert(Resetters, function()
			GemFarmer.Enabled = false
			GemFarmer.TotalFarmed = 0
		end)
	end

	----------------------------------------------------------------
	-- PLAYERS TAB
	----------------------------------------------------------------

	do
		local labels = {}
		local labelToPlayer = {}
		local selectedLabel = nil
		local dropdown = nil

		local function build(excluded)
			labelToPlayer = {}
			labels = {}
			for _, player in ipairs(Players:GetPlayers()) do
				if player ~= LocalPlayer and player ~= excluded then
					local label = string.format("%s (@%s)", player.DisplayName, player.Name)
					labelToPlayer[label] = player
					table.insert(labels, label)
				end
			end
			table.sort(labels, function(a, b)
				return a:lower() < b:lower()
			end)
			return labels
		end

		local function refresh(excluded)
			build(excluded)
			dropdown:Refresh(table.clone(labels))
			if selectedLabel and not labelToPlayer[selectedLabel] then
				selectedLabel = nil
				State.Target = nil
			end
		end

		local function cycle(step)
			if #labels == 0 then
				notify({ Title = CONFIG.Name, Content = "There are no other players in the server." })
				return
			end
			local index = table.find(labels, selectedLabel) or (step > 0 and 0 or 1)
			index = ((index - 1 + step) % #labels) + 1
			dropdown:Set(labels[index])
		end

		local spectating = false

		local function spectate()
			local target = State.Target
			local character = target and target.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if not humanoid then
				notify({ Title = CONFIG.Name, Content = "Pick a target with a character first." })
				return
			end
			Workspace.CurrentCamera.CameraSubject = humanoid
			spectating = true
			notify({ Title = CONFIG.Name, Content = "Spectating " .. target.DisplayName .. "." })
		end

		local function stopSpectating()
			if not spectating then
				return
			end
			spectating = false
			local _, humanoid = getCharacter()
			if humanoid then
				Workspace.CurrentCamera.CameraSubject = humanoid
			end
		end

		local function teleportToTarget()
			local target = State.Target
			local targetCharacter = target and target.Character
			local targetRoot = targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart")
			local _, _, myRoot = getCharacter()

			if not targetRoot then
				notify({ Title = CONFIG.Name, Content = "Pick a target with a character first." })
				return
			end
			if myRoot then
				myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 2, 4)
			end
		end

		PlayersTab:CreateSection("Target")

		dropdown = PlayersTab:CreateDropdown({
			Name = "Target",
			Options = build(),
			CurrentOption = {},
			Callback = function(option)
				local label = type(option) == "table" and option[1] or option
				selectedLabel = label
				State.Target = label and labelToPlayer[label] or nil
			end,
		})

		PlayersTab:CreateButton({ Name = "Previous Target", Callback = function() cycle(-1) end })
		PlayersTab:CreateButton({ Name = "Next Target", Callback = function() cycle(1) end })
		PlayersTab:CreateButton({ Name = "Teleport To Target", Callback = teleportToTarget })
		PlayersTab:CreateButton({ Name = "Spectate Target", Callback = spectate })
		PlayersTab:CreateButton({ Name = "Stop Spectating", Callback = stopSpectating })

		PlayersTab:CreateSection("Target info")

		local identityLabel = PlayersTab:CreateLabel("No target selected")
		local statsLabel = PlayersTab:CreateLabel("--")
		local ageLabel = PlayersTab:CreateLabel("--")

		Players.PlayerAdded:Connect(function()
			refresh()
		end)

		Players.PlayerRemoving:Connect(function(player)
			if player == State.Target then
				State.Target = nil
				selectedLabel = nil
			end
			refresh(player)
		end)

		task.spawn(function()
			while Gui.Parent do
				local target = State.Target

				if target and target.Parent then
					local character = target.Character
					local humanoid = character and character:FindFirstChildOfClass("Humanoid")
					local root = character and character:FindFirstChild("HumanoidRootPart")
					local _, _, myRoot = getCharacter()

					local health = "--"
					if humanoid then
						health = humanoid.MaxHealth > 100000 and "∞" or tostring(math.floor(humanoid.Health + 0.5))
					end

					local distance = "--"
					if root and myRoot then
						distance = tostring(math.floor((root.Position - myRoot.Position).Magnitude + 0.5))
					end

					identityLabel:Set(string.format("%s (@%s)  ·  ID %d", target.DisplayName, target.Name, target.UserId))
					statsLabel:Set(string.format("HP %s  ·  %s studs  ·  Team: %s", health, distance, target.Team and target.Team.Name or "None"))
					ageLabel:Set(string.format("Account age: %d days", target.AccountAge))
				else
					identityLabel:Set("No target selected")
					statsLabel:Set("--")
					ageLabel:Set("--")
				end

				task.wait(0.5)
			end
		end)

		table.insert(Resetters, stopSpectating)
	end

	----------------------------------------------------------------
	-- SELF TAB
	----------------------------------------------------------------

	SelfTab:CreateSection("Movement")

	do
		local originalGravity = Workspace.Gravity
		local defaultGravity = math.floor(originalGravity + 0.5)

		local speedSlider, jumpSlider, gravitySlider

		local function setSpeed(value)
			if value == CONFIG.DefaultSpeed then
				local hadOverride = State.CustomSpeed ~= nil
				State.CustomSpeed = nil
				local _, humanoid = getCharacter()
				if hadOverride and humanoid then
					humanoid.WalkSpeed = starterValue("CharacterWalkSpeed", CONFIG.DefaultSpeed)
				end
			else
				State.CustomSpeed = value
			end
		end

		local function setJump(value)
			if value == CONFIG.DefaultJump then
				local hadOverride = State.CustomJump ~= nil
				State.CustomJump = nil
				local _, humanoid = getCharacter()
				if hadOverride and humanoid then
					humanoid.UseJumpPower = starterValue("CharacterUseJumpPower", true)
					humanoid.JumpPower = starterValue("CharacterJumpPower", CONFIG.DefaultJump)
					humanoid.JumpHeight = starterValue("CharacterJumpHeight", 7.2)
				end
			else
				State.CustomJump = value
			end
		end

		local gravityTouched = false

		local function setGravity(value)
			if value == defaultGravity then
				if gravityTouched then
					Workspace.Gravity = originalGravity
					gravityTouched = false
				end
			else
				Workspace.Gravity = value
				gravityTouched = true
			end
		end

		speedSlider = SelfTab:CreateSlider({
			Name = "Walk Speed",
			Range = { 0, CONFIG.MaxSpeed },
			Increment = 1,
			CurrentValue = CONFIG.DefaultSpeed,
			Callback = setSpeed,
		})

		jumpSlider = SelfTab:CreateSlider({
			Name = "Jump Power",
			Range = { 0, CONFIG.MaxJump },
			Increment = 1,
			CurrentValue = CONFIG.DefaultJump,
			Callback = setJump,
		})

		gravitySlider = SelfTab:CreateSlider({
			Name = "Gravity",
			Range = { 0, 40
