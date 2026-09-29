--[[
	══════════════════════════════════════════════════════════════════
	  SC HUB  ·  FREE ACCESS  ·  fully client-side (ONE LocalScript)
	══════════════════════════════════════════════════════════════════

	SETUP
	  Create a LocalScript in StarterPlayerScripts and paste this whole file.
	  No server script and no RemoteEvents are needed.

	FEATURES
	  Players : target picker, teleport, spectate, live target info
	  Self    : speed / jump / gravity, fly, noclip, infinite jump,
	            ctrl+click teleport, sit, anti-AFK, rejoin
	  Teleport: quick save, spawn, named waypoints
	  Visual  : ESP, fullbright, time of day, FOV, unlimited zoom,
	            post-effect killer, freecam
	  Info    : FPS / ping / server info, hotkeys, reset, destroy

	WHAT CLIENT-ONLY MEANS
	  Everything here affects only YOUR OWN character and screen.
	  It cannot kill, kick, freeze or move other players, and it cannot
	  give real invulnerability (health is decided by the server).
	  Speed / jump / fly / noclip run locally, so a game's own scripts
	  can still override or reject them.

	UI
	  The real Rayfield library only loads through exploit executors
	  (LocalScripts can't use loadstring / HttpGet). This file ships a
	  Rayfield-style UI (tabs, toggles, sliders, dropdown, notifications)
	  built in, so it works inside a normal published game.

	Toggle the hub with RightShift (or the small "Sc Hub" button).
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
	Name = "Sc Hub",
	ToggleKey = Enum.KeyCode.RightShift,

	DefaultSpeed = 16,   -- a slider left at its default value means "no override"
	DefaultJump = 50,
	MaxSpeed = 250,
	MaxJump = 300,
	MaxFlySpeed = 250,
	MaxFreecamSpeed = 300,

	-- Toggle hotkeys (any key not pressed while typing or over a UI box).
	-- Remove a line to disable that hotkey. Names match the toggles.
	Hotkeys = {
		Fly = Enum.KeyCode.F,
		Noclip = Enum.KeyCode.N,
		ESP = Enum.KeyCode.B,
		Freecam = Enum.KeyCode.P,
	},
}

--------------------------------------------------------------------
-- CLIENT
--------------------------------------------------------------------

local function runClient()
	local TweenService = game:GetService("TweenService")
	local UserInputService = game:GetService("UserInputService")
	local Lighting = game:GetService("Lighting")
	local Workspace = game:GetService("Workspace")
	local Stats = game:GetService("Stats")

	local LocalPlayer = Players.LocalPlayer
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

	-- Dragging (mouse + touch)
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

	-- Tabs
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
	-- UI BACKEND: real Rayfield when it can load, built-in otherwise
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
		Target = nil,              -- selected Player (Players tab)
		CustomSpeed = nil,         -- nil = game default
		CustomJump = nil,          -- nil = game default
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

	local Toggles = {}    -- name -> toggle object (hotkeys + Reset Everything)
	local Resetters = {}  -- functions run by Reset Everything

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

	-- Roblox's own PlayerModule gives us the thumbstick / WASD move vector
	-- (works on PC, mobile and gamepad). Loaded once, never inside a frame loop.
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

	-- On-screen up / down buttons for touch devices (fly + freecam)
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
	local InfoTab = createTab("Info")

	----------------------------------------------------------------
	-- PLAYERS TAB: target selection, teleport, spectate, target info
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
			Range = { 0, 400 },
			Increment = 1,
			CurrentValue = math.clamp(defaultGravity, 0, 400),
			Callback = setGravity,
		})

		local function resetMovement()
			speedSlider:Set(CONFIG.DefaultSpeed)
			jumpSlider:Set(CONFIG.DefaultJump)
			gravitySlider:Set(math.clamp(defaultGravity, 0, 400))
			setSpeed(CONFIG.DefaultSpeed)
			setJump(CONFIG.DefaultJump)
			setGravity(defaultGravity)
		end

		SelfTab:CreateButton({ Name = "Reset Speed, Jump & Gravity", Callback = resetMovement })
		table.insert(Resetters, resetMovement)

		-- Re-apply every frame so the game's own scripts can't quietly undo it.
		connect(RunService.Heartbeat, function()
			if not State.CustomSpeed and not State.CustomJump then
				return
			end

			local _, humanoid = getCharacter()
			if not humanoid then
				return
			end

			if State.CustomSpeed and humanoid.WalkSpeed ~= State.CustomSpeed then
				humanoid.WalkSpeed = State.CustomSpeed
			end

			if State.CustomJump then
				if not humanoid.UseJumpPower then
					humanoid.UseJumpPower = true
				end
				if humanoid.JumpPower ~= State.CustomJump then
					humanoid.JumpPower = State.CustomJump
				end
			end
		end)
	end

	SelfTab:CreateSection("Flight")

	do
		local parts = nil

		local function stop()
			if not parts then
				return
			end
			for _, part in pairs(parts) do
				part:Destroy()
			end
			parts = nil

			local _, humanoid = getCharacter()
			if humanoid then
				humanoid.PlatformStand = false
				humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
			end
		end

		local function start()
			stop()
			getControls()

			local _, humanoid, root = getCharacter()
			if not humanoid or not root then
				return
			end

			local attachment = make("Attachment", { Name = "ScHubFly" }, root)

			local velocity = make("LinearVelocity", {
				Attachment0 = attachment,
				MaxForce = math.huge,
				VelocityConstraintMode = Enum.VelocityConstraintMode.Vector,
				RelativeTo = Enum.ActuatorRelativeTo.World,
				VectorVelocity = Vector3.zero,
			}, root)

			local align = make("AlignOrientation", {
				Mode = Enum.OrientationAlignmentMode.OneAttachment,
				Attachment0 = attachment,
				RigidityEnabled = true,
				CFrame = root.CFrame.Rotation,
			}, root)

			humanoid.PlatformStand = true
			parts = { Attachment = attachment, Velocity = velocity, Align = align }
		end

		Toggles.Fly = SelfTab:CreateToggle({
			Name = "Fly  (Space / E up  ·  Ctrl / Q down)",
			CurrentValue = false,
			Callback = function(enabled)
				State.Fly = enabled
				refreshFlyPad()
				if enabled then
					start()
				else
					stop()
				end
			end,
		})

		SelfTab:CreateSlider({
			Name = "Fly Speed",
			Range = { 10, CONFIG.MaxFlySpeed },
			Increment = 5,
			CurrentValue = State.FlySpeed,
			Callback = function(value)
				State.FlySpeed = value
			end,
		})

		connect(RunService.RenderStepped, function()
			if not State.Fly or not parts then
				return
			end

			local camera = Workspace.CurrentCamera
			local _, humanoid, root = getCharacter()
			if not (camera and humanoid and root and parts.Attachment.Parent) then
				return
			end

			humanoid.PlatformStand = true

			-- Freecam owns the camera; hold the character still while it is on.
			if State.Freecam then
				parts.Velocity.VectorVelocity = Vector3.zero
				return
			end

			local direction = camera.CFrame:VectorToWorldSpace(getMoveVector())
			direction += Vector3.new(0, getVerticalInput(), 0)
			if direction.Magnitude > 1 then
				direction = direction.Unit
			end
			parts.Velocity.VectorVelocity = direction * State.FlySpeed

			local look = camera.CFrame.LookVector
			local flat = Vector3.new(look.X, 0, look.Z)
			if flat.Magnitude > 0.01 then
				parts.Align.CFrame = CFrame.lookAt(Vector3.zero, flat)
			end
		end)

		connect(LocalPlayer.CharacterAdded, function(character)
			State.PadUp, State.PadDown = false, false
			if State.Fly then
				character:WaitForChild("HumanoidRootPart")
				task.wait(0.5)
				if State.Fly then
					start()
				end
			end
		end)
	end

	SelfTab:CreateSection("Abilities")

	do
		local stored = {}

		Toggles.Noclip = SelfTab:CreateToggle({
			Name = "Noclip",
			CurrentValue = false,
			Callback = function(enabled)
				State.Noclip = enabled
				if not enabled then
					for part in pairs(stored) do
						if part.Parent then
							part.CanCollide = true
						end
					end
					table.clear(stored)
				end
			end,
		})

		connect(RunService.Stepped, function()
			if not State.Noclip then
				return
			end
			local character = LocalPlayer.Character
			if not character then
				return
			end
			for _, part in ipairs(character:GetDescendants()) do
				if part:IsA("BasePart") and part.CanCollide then
					stored[part] = true
					part.CanCollide = false
				end
			end
		end)

		connect(LocalPlayer.CharacterAdded, function()
			table.clear(stored)
		end)
	end

	do
		Toggles.InfiniteJump = SelfTab:CreateToggle({
			Name = "Infinite Jump",
			CurrentValue = false,
			Callback = function(enabled)
				State.InfiniteJump = enabled
			end,
		})

		connect(UserInputService.JumpRequest, function()
			if not State.InfiniteJump then
				return
			end
			local _, humanoid = getCharacter()
			if humanoid then
				humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			end
		end)
	end

	do
		Toggles.ClickTeleport = SelfTab:CreateToggle({
			Name = "Ctrl + Click Teleport  (PC)",
			CurrentValue = false,
			Callback = function(enabled)
				State.ClickTeleport = enabled
			end,
		})

		connect(UserInputService.InputBegan, function(input, processed)
			if processed or not State.ClickTeleport then
				return
			end
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
				return
			end
			if not UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
				return
			end

			local character, _, root = getCharacter()
			local camera = Workspace.CurrentCamera
			if not (character and root and camera) then
				return
			end

			local location = UserInputService:GetMouseLocation()
			local ray = camera:ViewportPointToRay(location.X, location.Y)

			local params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			params.FilterDescendantsInstances = { character }

			local result = Workspace:Raycast(ray.Origin, ray.Direction * 3000, params)
			if result then
				root.CFrame = CFrame.new(result.Position + Vector3.new(0, 3, 0))
			end
		end)
	end

	SelfTab:CreateSection("Utility")

	do
		SelfTab:CreateButton({
			Name = "Sit",
			Callback = function()
				local _, humanoid = getCharacter()
				if humanoid then
					humanoid.Sit = true
				end
			end,
		})

		SelfTab:CreateButton({
			Name = "Reset Character",
			Callback = function()
				local _, humanoid = getCharacter()
				if humanoid then
					humanoid.Health = 0
				end
			end,
		})

		Toggles.AntiAfk = SelfTab:CreateToggle({
			Name = "Anti-AFK  (stops the 20 minute idle kick)",
			CurrentValue = false,
			Callback = function(enabled)
				State.AntiAfk = enabled
			end,
		})

		connect(LocalPlayer.Idled, function()
			if not State.AntiAfk then
				return
			end
			pcall(function()
				local virtualUser = game:GetService("VirtualUser")
				virtualUser:CaptureController()
				virtualUser:ClickButton2(Vector2.zero)
			end)
		end)

		SelfTab:CreateButton({
			Name = "Rejoin Server",
			Callback = function()
				local ok = pcall(function()
					if #Players:GetPlayers() <= 1 then
						TeleportService:Teleport(game.PlaceId, LocalPlayer)
					else
						TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
					end
				end)
				if not ok then
					notify({ Title = CONFIG.Name, Content = "Rejoin isn't available here (it doesn't work inside Studio)." })
				end
			end,
		})
	end

	----------------------------------------------------------------
	-- TELEPORT TAB: quick slot, spawn, named waypoints
	----------------------------------------------------------------

	do
		local waypoints = {}   -- name -> CFrame
		local names = {}
		local selectedName = nil
		local typedName = ""
		local quickSlot = nil
		local dropdown = nil
		local input = nil

		local function refreshDropdown()
			table.sort(names, function(a, b)
				return a:lower() < b:lower()
			end)
			dropdown:Refresh(table.clone(names))
		end

		TeleportTab:CreateSection("Quick")

		TeleportTab:CreateButton({
			Name = "Save Position",
			Callback = function()
				local _, _, root = getCharacter()
				if root then
					quickSlot = root.CFrame
					notify({ Title = CONFIG.Name, Content = "Position saved." })
				end
			end,
		})

		TeleportTab:CreateButton({
			Name = "Teleport To Saved Position",
			Callback = function()
				local _, _, root = getCharacter()
				if not quickSlot then
					notify({ Title = CONFIG.Name, Content = "Save a position first." })
				elseif root then
					root.CFrame = quickSlot
				end
			end,
		})

		TeleportTab:CreateButton({
			Name = "Teleport To Spawn",
			Callback = function()
				local _, _, root = getCharacter()
				local spawnPoint = Workspace:FindFirstChildWhichIsA("SpawnLocation", true)
				if not spawnPoint then
					notify({ Title = CONFIG.Name, Content = "This game has no SpawnLocation." })
				elseif root then
					root.CFrame = spawnPoint.CFrame + Vector3.new(0, 5, 0)
				end
			end,
		})

		TeleportTab:CreateSection("Waypoints")

		input = TeleportTab:CreateInput({
			Name = "Waypoint name",
			PlaceholderText = "e.g. Base",
			RemoveTextAfterFocusLost = false,
			Callback = function(text)
				typedName = text or ""
			end,
		})

		dropdown = TeleportTab:CreateDropdown({
			Name = "Waypoint",
			Options = {},
			CurrentOption = {},
			Callback = function(option)
				selectedName = type(option) == "table" and option[1] or option
			end,
		})

		TeleportTab:CreateButton({
			Name = "Save Waypoint Here",
			Callback = function()
				local _, _, root = getCharacter()
				if not root then
					return
				end

				local name = typedName:match("^%s*(.-)%s*$")
				if name == "" then
					local number = #names + 1
					while waypoints["Waypoint " .. number] do
						number += 1
					end
					name = "Waypoint " .. number
				end

				if not waypoints[name] then
					table.insert(names, name)
				end
				waypoints[name] = root.CFrame

				refreshDropdown()
				dropdown:Set(name)
				input:Set("")
				typedName = ""
				notify({ Title = CONFIG.Name, Content = 'Saved "' .. name .. '".' })
			end,
		})

		TeleportTab:CreateButton({
			Name = "Teleport To Waypoint",
			Callback = function()
				local _, _, root = getCharacter()
				local target = selectedName and waypoints[selectedName]
				if not target then
					notify({ Title = CONFIG.Name, Content = "Pick a waypoint first." })
				elseif root then
					root.CFrame = target
				end
			end,
		})

		TeleportTab:CreateButton({
			Name = "Delete Waypoint",
			Callback = function()
				if not selectedName or not waypoints[selectedName] then
					notify({ Title = CONFIG.Name, Content = "Pick a waypoint first." })
					return
				end

				local index = table.find(names, selectedName)
				if index then
					table.remove(names, index)
				end
				waypoints[selectedName] = nil
				selectedName = nil
				refreshDropdown()
			end,
		})
	end

	----------------------------------------------------------------
	-- VISUAL TAB
	----------------------------------------------------------------

	VisualTab:CreateSection("Players")

	do
		local objects = {}
		local token = 0

		local function remove(player)
			local set = objects[player]
			if set then
				set.Highlight:Destroy()
				set.Billboard:Destroy()
				objects[player] = nil
			end
		end

		local function add(player)
			remove(player)
			if player == LocalPlayer then
				return
			end

			local character = player.Character
			local head = character and character:FindFirstChild("Head")
			if not head then
				return
			end

			local color = player.Team and player.TeamColor.Color or THEME.Accent

			local highlight = make("Highlight", {
				Name = "ScHubHighlight",
				Adornee = character,
				DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
				FillColor = color,
				OutlineColor = Color3.new(1, 1, 1),
				FillTransparency = 0.6,
				OutlineTransparency = 0,
			}, character)

			local billboard = make("BillboardGui", {
				Name = "ScHubTag",
				Adornee = head,
				AlwaysOnTop = true,
				Size = UDim2.fromOffset(170, 36),
				StudsOffset = Vector3.new(0, 2.6, 0),
			}, head)

			local label = make("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				Text = player.DisplayName,
				TextColor3 = Color3.new(1, 1, 1),
				TextStrokeTransparency = 0.4,
				Font = Enum.Font.GothamBold,
				TextSize = 13,
			}, billboard)

			objects[player] = { Highlight = highlight, Billboard = billboard, Label = label }
		end

		local function update()
			local _, _, myRoot = getCharacter()

			for player, set in pairs(objects) do
				if not set.Highlight.Parent then
					objects[player] = nil
				else
					local character = player.Character
					local humanoid = character and character:FindFirstChildOfClass("Humanoid")
					local root = character and character:FindFirstChild("HumanoidRootPart")

					if humanoid and root and myRoot then
						local health = humanoid.MaxHealth > 100000 and "∞" or tostring(math.floor(humanoid.Health + 0.5))
						local distance = math.floor((root.Position - myRoot.Position).Magnitude + 0.5)
						set.Label.Text = string.format("%s\n%s HP  ·  %d studs", player.DisplayName, health, distance)
					end
				end
			end
		end

		local function hook(player)
			if player == LocalPlayer then
				return
			end
			player.CharacterAdded:Connect(function()
				if State.ESP then
					task.wait(0.5)
					if State.ESP then
						add(player)
					end
				end
			end)
		end

		Toggles.ESP = VisualTab:CreateToggle({
			Name = "Player ESP  (highlight, name, HP, distance)",
			CurrentValue = false,
			Callback = function(enabled)
				State.ESP = enabled
				token += 1

				if enabled then
					for _, player in ipairs(Players:GetPlayers()) do
						add(player)
					end

					local mine = token
					task.spawn(function()
						while State.ESP and token == mine do
							update()
							task.wait(0.25)
						end
					end)
				else
					for player in pairs(objects) do
						remove(player)
					end
				end
			end,
		})

		for _, player in ipairs(Players:GetPlayers()) do
			hook(player)
		end
		Players.PlayerAdded:Connect(hook)
		Players.PlayerRemoving:Connect(remove)
	end

	VisualTab:CreateSection("World")

	do
		local saved = nil

		Toggles.Fullbright = VisualTab:CreateToggle({
			Name = "Fullbright",
			CurrentValue = false,
			Callback = function(enabled)
				if enabled then
					if not saved then
						saved = {
							Brightness = Lighting.Brightness,
							FogEnd = Lighting.FogEnd,
							GlobalShadows = Lighting.GlobalShadows,
							Ambient = Lighting.Ambient,
							OutdoorAmbient = Lighting.OutdoorAmbient,
						}
					end
					Lighting.Brightness = 2
					Lighting.FogEnd = 1e6
					Lighting.GlobalShadows = false
					Lighting.Ambient = Color3.fromRGB(178, 178, 178)
					Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
				elseif saved then
					for property, value in pairs(saved) do
						Lighting[property] = value
					end
					saved = nil
				end
			end,
		})
	end

	do
		local originalClock = Lighting.ClockTime
		local startValue = math.clamp(math.floor(originalClock * 2 + 0.5) / 2, 0, 24)
		local timeSlider = nil
		local clockTouched = false

		timeSlider = VisualTab:CreateSlider({
			Name = "Time Of Day",
			Range = { 0, 24 },
			Increment = 0.5,
			Suffix = "h",
			CurrentValue = startValue,
			Callback = function(value)
				if value == startValue then
					if clockTouched then
						Lighting.ClockTime = originalClock
						clockTouched = false
					end
				else
					Lighting.ClockTime = value
					clockTouched = true
				end
			end,
		})

		table.insert(Resetters, function()
			timeSlider:Set(startValue)
			if clockTouched then
				Lighting.ClockTime = originalClock
				clockTouched = false
			end
		end)
	end

	do
		local disabled = {}

		Toggles.NoEffects = VisualTab:CreateToggle({
			Name = "Disable Blur / Bloom / Post Effects",
			CurrentValue = false,
			Callback = function(enabled)
				if enabled then
					local containers = { Lighting, Workspace.CurrentCamera }
					for _, container in ipairs(containers) do
						for _, child in ipairs(container:GetChildren()) do
							if child:IsA("PostEffect") and child.Enabled then
								disabled[child] = true
								child.Enabled = false
							end
						end
					end
				else
					for effect in pairs(disabled) do
						if effect.Parent then
							effect.Enabled = true
						end
					end
					table.clear(disabled)
				end
			end,
		})
	end

	VisualTab:CreateSection("Camera")

	do
		local originalFov = Workspace.CurrentCamera.FieldOfView
		local startFov = math.clamp(math.floor(originalFov + 0.5), 40, 120)
		local fovSlider = nil
		local fovTouched = false

		fovSlider = VisualTab:CreateSlider({
			Name = "Field Of View",
			Range = { 40, 120 },
			Increment = 1,
			CurrentValue = startFov,
			Callback = function(value)
				if value == startFov then
					if fovTouched then
						Workspace.CurrentCamera.FieldOfView = originalFov
						fovTouched = false
					end
				else
					Workspace.CurrentCamera.FieldOfView = value
					fovTouched = true
				end
			end,
		})

		table.insert(Resetters, function()
			fovSlider:Set(startFov)
			if fovTouched then
				Workspace.CurrentCamera.FieldOfView = originalFov
				fovTouched = false
			end
		end)
	end

	do
		local originalMaxZoom = LocalPlayer.CameraMaxZoomDistance

		Toggles.Zoom = VisualTab:CreateToggle({
			Name = "Unlimited Camera Zoom",
			CurrentValue = false,
			Callback = function(enabled)
				LocalPlayer.CameraMaxZoomDistance = enabled and 100000 or originalMaxZoom
			end,
		})
	end

	do
		local yaw, pitch = 0, 0
		local position = Vector3.zero
		local anchoredRoot = nil
		local active = false

		local function anchorCharacter()
			local _, _, root = getCharacter()
			if root then
				root.Anchored = true
				anchoredRoot = root
			end
		end

		local function stop()
			if not active then
				return
			end
			active = false

			local camera = Workspace.CurrentCamera
			camera.CameraType = Enum.CameraType.Custom

			local _, humanoid = getCharacter()
			if humanoid then
				camera.CameraSubject = humanoid
			end

			if anchoredRoot and anchoredRoot.Parent then
				anchoredRoot.Anchored = false
			end
			anchoredRoot = nil

			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		end

		local function start()
			getControls()

			local camera = Workspace.CurrentCamera
			local cameraCFrame = camera.CFrame
			position = cameraCFrame.Position
			pitch, yaw = cameraCFrame:ToOrientation()

			camera.CameraType = Enum.CameraType.Scriptable
			active = true
			anchorCharacter()
		end

		Toggles.Freecam = VisualTab:CreateToggle({
			Name = "Freecam  (hold right mouse to look)",
			CurrentValue = false,
			Callback = function(enabled)
				State.Freecam = enabled
				refreshFlyPad()
				if enabled then
					start()
				else
					stop()
				end
			end,
		})

		VisualTab:CreateSlider({
			Name = "Freecam Speed",
			Range = { 5, CONFIG.MaxFreecamSpeed },
			Increment = 5,
			CurrentValue = State.FreecamSpeed,
			Callback = function(value)
				State.FreecamSpeed = value
			end,
		})

		connect(RunService.RenderStepped, function(dt)
			if not State.Freecam then
				return
			end

			local camera = Workspace.CurrentCamera
			if camera.CameraType ~= Enum.CameraType.Scriptable then
				camera.CameraType = Enum.CameraType.Scriptable
			end

			local looking = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
			UserInputService.MouseBehavior = looking and Enum.MouseBehavior.LockCurrentPosition
				or Enum.MouseBehavior.Default

			if looking then
				local delta = UserInputService:GetMouseDelta()
				yaw -= math.rad(delta.X * 0.25)
				pitch = math.clamp(pitch - math.rad(delta.Y * 0.25), -1.5, 1.5)
			end

			local rotation = CFrame.fromOrientation(pitch, yaw, 0)
			local move = rotation:VectorToWorldSpace(getMoveVector())
			move += Vector3.new(0, getVerticalInput(), 0)
			if move.Magnitude > 1 then
				move = move.Unit
			end

			position += move * State.FreecamSpeed * dt
			camera.CFrame = CFrame.new(position) * rotation
		end)

		-- Touch: drag anywhere that isn't the UI or thumbstick to look around.
		connect(UserInputService.InputChanged, function(input, processed)
			if State.Freecam and not processed and input.UserInputType == Enum.UserInputType.Touch then
				yaw -= math.rad(input.Delta.X * 0.3)
				pitch = math.clamp(pitch - math.rad(input.Delta.Y * 0.3), -1.5, 1.5)
			end
		end)

		-- Keep a respawned character still while the freecam is on.
		connect(LocalPlayer.CharacterAdded, function(character)
			if State.Freecam then
				character:WaitForChild("HumanoidRootPart")
				task.wait(0.3)
				if State.Freecam then
					anchorCharacter()
				end
			end
		end)
	end

	----------------------------------------------------------------
	-- INFO TAB
	----------------------------------------------------------------

	do
		InfoTab:CreateSection("Live stats")
		local fpsLabel = InfoTab:CreateLabel("FPS: --")
		local pingLabel = InfoTab:CreateLabel("Ping: --")
		local playersLabel = InfoTab:CreateLabel("Players: --")

		InfoTab:CreateSection("Server")
		InfoTab:CreateLabel("Place ID: " .. tostring(game.PlaceId))
		InfoTab:CreateLabel("Server ID: " .. (game.JobId ~= "" and game.JobId or "(Studio)"))

		InfoTab:CreateSection("Hotkeys")
		local hotkeyText = {}
		local hotkeyMap = {}
		for name, key in pairs(CONFIG.Hotkeys) do
			hotkeyMap[key] = name
			table.insert(hotkeyText, key.Name .. " = " .. name)
		end
		table.sort(hotkeyText)
		InfoTab:CreateLabel(table.concat(hotkeyText, "   ·   "))
		InfoTab:CreateLabel("Show / hide hub: " .. CONFIG.ToggleKey.Name)

		connect(UserInputService.InputBegan, function(input, processed)
			if processed then
				return
			end
			local name = hotkeyMap[input.KeyCode]
			local toggle = name and Toggles[name]
			if toggle then
				toggle:Set(not toggle.CurrentValue)
			end
		end)

		InfoTab:CreateSection("Hub")

		local function disableEverything()
			for _, toggle in pairs(Toggles) do
				toggle:Set(false)
			end
			for _, reset in ipairs(Resetters) do
				reset()
			end
		end

		InfoTab:CreateButton({
			Name = "Reset Everything",
			Callback = disableEverything,
		})

		InfoTab:CreateButton({
			Name = "Destroy Hub",
			Callback = function()
				disableEverything()
				for _, connection in ipairs(connections) do
					connection:Disconnect()
				end
				table.clear(connections)
				UI.Destroy()
				Gui:Destroy()
			end,
		})

		local frames, elapsed = 0, 0

		connect(RunService.Heartbeat, function(dt)
			frames += 1
			elapsed += dt
		end)

		task.spawn(function()
			while Gui.Parent do
				task.wait(0.5)

				local fps = elapsed > 0 and math.floor(frames / elapsed + 0.5) or 0
				frames, elapsed = 0, 0

				local ok, ping = pcall(function()
					return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
				end)

				fpsLabel:Set("FPS: " .. fps)
				pingLabel:Set(ok and string.format("Ping: %d ms", math.floor(ping + 0.5)) or "Ping: n/a")
				playersLabel:Set(string.format("Players: %d / %d", #Players:GetPlayers(), Players.MaxPlayers))
			end
		end)
	end

	----------------------------------------------------------------
	-- START
	----------------------------------------------------------------

	if usingRayfield then
		pcall(function()
			Rayfield:LoadConfiguration()
		end)
	end

	notify({
		Title = CONFIG.Name,
		Content = "Loaded. Press " .. CONFIG.ToggleKey.Name .. " to hide / show.",
		Duration = 4,
	})

	print("[" .. CONFIG.Name .. "] client loaded - UI: " .. (usingRayfield and "Rayfield" or "built-in"))
end

runClient()
