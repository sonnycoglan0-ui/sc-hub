--[[
	══════════════════════════════════════════════════════════════════
	  SC HUB  ·  FREE ACCESS  ·  single-file build (server + client)
	══════════════════════════════════════════════════════════════════

	SETUP
	  1. Copy this ENTIRE file.
	  2. Script       -> ServerScriptService   (paste it)
	  3. LocalScript  -> StarterPlayerScripts  (paste the SAME code)
	  The file detects where it is running and only runs its own half.

	UI
	  The real Rayfield library only loads through exploit executors
	  (LocalScripts can't use loadstring / HttpGet). This file ships a
	  Rayfield-style UI (tabs, toggles, sliders, dropdown, notifications)
	  built in, so it works inside a normal published game.

	Toggle the hub with RightShift (or the small "Sc Hub" button).
]]

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--------------------------------------------------------------------
-- CONFIG (shared by server and client)
--------------------------------------------------------------------

local CONFIG = {
	Name = "Sc Hub",
	ToggleKey = Enum.KeyCode.RightShift,

	DefaultSpeed = 16,
	DefaultJump = 50,
	MaxSpeed = 250,
	MaxJump = 300,
	MaxFlySpeed = 250,

	ActionCooldown = 0.08,        -- seconds between normal actions (per player)
	MassActionCooldown = 1.5,     -- seconds between "Everyone" actions
	AnnouncementCooldown = 3,
	AnnouncementMaxLength = 180,

	-- Any action listed here is blocked by the server. Remove a line to enable it.
	-- With free access, anyone could kick anyone, so Kick is off by default.
	DisabledActions = {
		Kick = true,
		-- KillAll = true,
		-- FreezeAll = true,
	},

	-- Protected players can't be Killed / Frozen / Brought / Respawned / Kicked by others.
	ProtectOwner = true,          -- the game's creator (user-owned games only)
	ProtectedUserIds = {},        -- e.g. { 1234567, 7654321 }
}

local REMOTES_NAME = "SC_Hub_Remotes"

--------------------------------------------------------------------
-- SERVER
--------------------------------------------------------------------

local function runServer()
	local TextService = game:GetService("TextService")
	local StarterPlayer = game:GetService("StarterPlayer")

	local GOD_HEALTH = 1e9

	local TARGET_ACTIONS = {
		TeleportTo = true, Bring = true, Heal = true, Kill = true,
		Freeze = true, Unfreeze = true, Respawn = true, Kick = true,
	}
	local HARMFUL_ACTIONS = {
		Bring = true, Kill = true, Freeze = true, Respawn = true, Kick = true,
	}
	local MASS_ACTIONS = {
		HealAll = true, KillAll = true, FreezeAll = true,
		UnfreezeAll = true, RespawnAll = true, BringAll = true,
	}

	----------------------------------------------------------------
	-- Remotes
	----------------------------------------------------------------

	local Remotes = ReplicatedStorage:FindFirstChild(REMOTES_NAME)
	if not Remotes then
		Remotes = Instance.new("Folder")
		Remotes.Name = REMOTES_NAME
		Remotes.Parent = ReplicatedStorage
	end

	local Action = Remotes:FindFirstChild("Action")
	if not Action then
		Action = Instance.new("RemoteEvent")
		Action.Name = "Action"
		Action.Parent = Remotes
	end

	for name, disabled in pairs(CONFIG.DisabledActions) do
		if disabled then
			Remotes:SetAttribute("Disabled_" .. name, true)
		end
	end

	----------------------------------------------------------------
	-- Helpers
	----------------------------------------------------------------

	local lastUse = {}

	local function rateLimit(player, bucket, cooldown)
		local store = lastUse[player.UserId]
		if not store then
			store = {}
			lastUse[player.UserId] = store
		end
		local now = os.clock()
		if now - (store[bucket] or -math.huge) < cooldown then
			return false
		end
		store[bucket] = now
		return true
	end

	local function notify(player, title, text)
		Action:FireClient(player, "Notify", title, text)
	end

	local function getParts(player)
		local character = player and player.Character
		if not character then
			return nil, nil, nil
		end
		return character,
			character:FindFirstChildOfClass("Humanoid"),
			character:FindFirstChild("HumanoidRootPart")
	end

	local function numberArg(value, default, min, max)
		local n = tonumber(value)
		if not n or n ~= n or n == math.huge or n == -math.huge then
			n = default
		end
		return math.clamp(n, min, max)
	end

	local protectedIds = {}
	for _, id in ipairs(CONFIG.ProtectedUserIds) do
		protectedIds[id] = true
	end

	local function isProtected(player)
		if protectedIds[player.UserId] then
			return true
		end
		return CONFIG.ProtectOwner
			and game.CreatorType == Enum.CreatorType.User
			and player.UserId == game.CreatorId
	end

	local function othersOf(caller, skipProtected)
		local list = {}
		for _, other in ipairs(Players:GetPlayers()) do
			if other ~= caller and not (skipProtected and isProtected(other)) then
				table.insert(list, other)
			end
		end
		return list
	end

	----------------------------------------------------------------
	-- State helpers (persist through respawn)
	----------------------------------------------------------------

	local godConnections = {}

	local function clearGodConnection(player)
		local connection = godConnections[player]
		if connection then
			connection:Disconnect()
			godConnections[player] = nil
		end
	end

	local function setGod(player, enabled)
		player:SetAttribute("SC_God", enabled)
		clearGodConnection(player)

		local _, humanoid = getParts(player)
		if not humanoid then
			return
		end

		if enabled then
			if humanoid:GetAttribute("SC_OldMaxHealth") == nil then
				humanoid:SetAttribute("SC_OldMaxHealth", humanoid.MaxHealth)
			end
			humanoid.MaxHealth = GOD_HEALTH
			humanoid.Health = GOD_HEALTH
			godConnections[player] = humanoid.HealthChanged:Connect(function(health)
				if health > 0 and health < humanoid.MaxHealth then
					humanoid.Health = humanoid.MaxHealth
				end
			end)
		else
			local old = humanoid:GetAttribute("SC_OldMaxHealth")
			humanoid.MaxHealth = old or 100
			humanoid.Health = humanoid.MaxHealth
			humanoid:SetAttribute("SC_OldMaxHealth", nil)
		end
	end

	local function setFrozen(player, frozen)
		player:SetAttribute("SC_Frozen", frozen)
		local _, _, root = getParts(player)
		if root then
			root.Anchored = frozen
		end
	end

	local function killPlayer(target, caller)
		if target ~= caller and target:GetAttribute("SC_God") then
			return
		end
		local _, humanoid = getParts(target)
		if humanoid then
			humanoid.Health = 0
		end
	end

	local function onCharacter(player, character)
		local humanoid = character:WaitForChild("Humanoid", 10)
		local root = character:WaitForChild("HumanoidRootPart", 10)
		if not humanoid or not root then
			return
		end

		local speed = player:GetAttribute("SC_Speed")
		if speed then
			humanoid.WalkSpeed = speed
		end

		local jump = player:GetAttribute("SC_Jump")
		if jump then
			humanoid.UseJumpPower = true
			humanoid.JumpPower = jump
		end

		if player:GetAttribute("SC_God") then
			setGod(player, true)
		end

		if player:GetAttribute("SC_Frozen") then
			root.Anchored = true
		end
	end

	local function setupPlayer(player)
		player.CharacterAdded:Connect(function(character)
			onCharacter(player, character)
		end)
		if player.Character then
			task.spawn(onCharacter, player, player.Character)
		end
	end

	----------------------------------------------------------------
	-- Action handlers: (caller, target, value)
	----------------------------------------------------------------

	local Handlers = {}

	-- Self ---------------------------------------------------------

	Handlers.Speed = function(player, _, value)
		local speed = numberArg(value, CONFIG.DefaultSpeed, 0, CONFIG.MaxSpeed)
		player:SetAttribute("SC_Speed", speed)
		local _, humanoid = getParts(player)
		if humanoid then
			humanoid.WalkSpeed = speed
		end
	end

	Handlers.Jump = function(player, _, value)
		local jump = numberArg(value, CONFIG.DefaultJump, 0, CONFIG.MaxJump)
		player:SetAttribute("SC_Jump", jump)
		local _, humanoid = getParts(player)
		if humanoid then
			humanoid.UseJumpPower = true
			humanoid.JumpPower = jump
		end
	end

	Handlers.ResetMovement = function(player)
		player:SetAttribute("SC_Speed", nil)
		player:SetAttribute("SC_Jump", nil)
		local _, humanoid = getParts(player)
		if humanoid then
			humanoid.WalkSpeed = StarterPlayer.CharacterWalkSpeed
			humanoid.UseJumpPower = StarterPlayer.CharacterUseJumpPower
			humanoid.JumpPower = StarterPlayer.CharacterJumpPower
			humanoid.JumpHeight = StarterPlayer.CharacterJumpHeight
		end
	end

	Handlers.God = function(player, _, value)
		setGod(player, value == true)
	end

	-- Single target ------------------------------------------------

	Handlers.TeleportTo = function(player, target)
		local _, _, myRoot = getParts(player)
		local _, _, theirRoot = getParts(target)
		if myRoot and theirRoot then
			myRoot.CFrame = theirRoot.CFrame * CFrame.new(0, 2, 4)
		end
	end

	Handlers.Bring = function(player, target)
		local _, _, myRoot = getParts(player)
		local _, _, theirRoot = getParts(target)
		if myRoot and theirRoot then
			theirRoot.CFrame = myRoot.CFrame * CFrame.new(0, 0, -5)
		end
	end

	Handlers.Heal = function(_, target)
		local _, humanoid = getParts(target)
		if humanoid then
			humanoid.Health = humanoid.MaxHealth
		end
	end

	Handlers.Kill = function(player, target)
		killPlayer(target, player)
	end

	Handlers.Freeze = function(_, target)
		setFrozen(target, true)
	end

	Handlers.Unfreeze = function(_, target)
		setFrozen(target, false)
	end

	Handlers.Respawn = function(_, target)
		task.spawn(function()
			target:LoadCharacter()
		end)
	end

	Handlers.Kick = function(player, target)
		if target ~= player then
			target:Kick("Removed by " .. player.DisplayName .. " using " .. CONFIG.Name .. ".")
		end
	end

	-- Everyone (the caller is skipped, except for Heal) -------------

	Handlers.HealAll = function()
		for _, other in ipairs(Players:GetPlayers()) do
			local _, humanoid = getParts(other)
			if humanoid then
				humanoid.Health = humanoid.MaxHealth
			end
		end
	end

	Handlers.KillAll = function(player)
		for _, other in ipairs(othersOf(player, true)) do
			killPlayer(other, player)
		end
	end

	Handlers.FreezeAll = function(player)
		for _, other in ipairs(othersOf(player, true)) do
			setFrozen(other, true)
		end
	end

	Handlers.UnfreezeAll = function(player)
		for _, other in ipairs(othersOf(player, false)) do
			setFrozen(other, false)
		end
	end

	Handlers.RespawnAll = function(player)
		for _, other in ipairs(othersOf(player, true)) do
			task.spawn(function()
				other:LoadCharacter()
			end)
		end
	end

	Handlers.BringAll = function(player)
		local _, _, myRoot = getParts(player)
		if not myRoot then
			return
		end

		local targets = othersOf(player, true)
		local count = #targets

		for index, other in ipairs(targets) do
			local _, _, root = getParts(other)
			if root then
				local angle = (index / count) * math.pi * 2
				local offset = Vector3.new(math.cos(angle), 0, math.sin(angle)) * (6 + count * 0.5)
				local position = myRoot.Position + offset + Vector3.new(0, 3, 0)
				root.CFrame = CFrame.lookAt(
					position,
					Vector3.new(myRoot.Position.X, position.Y, myRoot.Position.Z)
				)
			end
		end
	end

	-- Announcement -------------------------------------------------

	Handlers.Announcement = function(player, _, value)
		if typeof(value) ~= "string" then
			return
		end

		local length = utf8.len(value)
		if not length or value:match("^%s*$") then
			return
		end
		if length > CONFIG.AnnouncementMaxLength then
			local cut = utf8.offset(value, CONFIG.AnnouncementMaxLength + 1) or (#value + 1)
			value = value:sub(1, cut - 1)
		end

		-- Roblox requires player-written text shown to others to be filtered.
		local ok, result = pcall(function()
			return TextService:FilterStringAsync(value, player.UserId, Enum.TextFilterContext.PublicChat)
		end)
		if not ok or not result then
			return
		end

		local okFilter, filtered = pcall(function()
			return result:GetNonChatStringForBroadcastAsync()
		end)
		if not okFilter or not filtered or filtered == "" then
			return
		end

		Action:FireAllClients("Announcement", filtered, player.DisplayName)
	end

	----------------------------------------------------------------
	-- Dispatcher
	----------------------------------------------------------------

	Action.OnServerEvent:Connect(function(player, action, targetId, value)
		if typeof(action) ~= "string" then
			return
		end

		local handler = Handlers[action]
		if not handler then
			return
		end

		local bucket, cooldown = "act", CONFIG.ActionCooldown
		if MASS_ACTIONS[action] then
			bucket, cooldown = "mass", CONFIG.MassActionCooldown
		elseif action == "Announcement" then
			bucket, cooldown = "announce", CONFIG.AnnouncementCooldown
		end

		if not rateLimit(player, bucket, cooldown) then
			if bucket ~= "act" then
				notify(player, CONFIG.Name, "Slow down a little.")
			end
			return
		end

		if CONFIG.DisabledActions[action] then
			notify(player, CONFIG.Name, action .. " is disabled in this game.")
			return
		end

		local target = nil
		if TARGET_ACTIONS[action] then
			if typeof(targetId) ~= "number" then
				return
			end

			target = Players:GetPlayerByUserId(targetId)
			if not target then
				notify(player, CONFIG.Name, "That player is no longer in the server.")
				return
			end

			if HARMFUL_ACTIONS[action] and target ~= player and isProtected(target) then
				notify(player, CONFIG.Name, target.DisplayName .. " is protected.")
				return
			end
		end

		local ok, err = pcall(handler, player, target, value)
		if not ok then
			warn("[" .. CONFIG.Name .. "] " .. action .. " failed: " .. tostring(err))
		end
	end)

	----------------------------------------------------------------
	-- Lifecycle
	----------------------------------------------------------------

	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayer(player)
	end
	Players.PlayerAdded:Connect(setupPlayer)

	Players.PlayerRemoving:Connect(function(player)
		lastUse[player.UserId] = nil
		clearGodConnection(player)
	end)

	print("[" .. CONFIG.Name .. "] server ready - FREE ACCESS")
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

	local LocalPlayer = Players.LocalPlayer
	local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

	local Remotes = ReplicatedStorage:WaitForChild(REMOTES_NAME)
	local Action = Remotes:WaitForChild("Action")

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

	----------------------------------------------------------------
	-- HUB LOGIC
	----------------------------------------------------------------

	local selectedPlayer = nil
	local optionToPlayer = {}

	local flyEnabled = false
	local noclipEnabled = false
	local infiniteJumpEnabled = false
	local espEnabled = false
	local flySpeed = 60
	local flyUpHeld = false
	local flyDownHeld = false
	local savedCFrame = nil

	local function getCharacter()
		local character = LocalPlayer.Character
		if not character then
			return nil, nil, nil
		end
		return character,
			character:FindFirstChildOfClass("Humanoid"),
			character:FindFirstChild("HumanoidRootPart")
	end

	local function send(action, target, value)
		if Remotes:GetAttribute("Disabled_" .. action) then
			notify({ Title = CONFIG.Name, Content = action .. " is disabled in this game." })
			return
		end
		Action:FireServer(action, target and target.UserId or LocalPlayer.UserId, value)
	end

	local function sendToTarget(action)
		if not selectedPlayer or not selectedPlayer.Parent then
			notify({ Title = CONFIG.Name, Content = "Pick a target on the Players tab first." })
			return
		end
		send(action, selectedPlayer)
	end

	local pending = {}

	local function debounced(key, delay, callback)
		local token = {}
		pending[key] = token
		task.delay(delay, function()
			if pending[key] == token then
				pending[key] = nil
				callback()
			end
		end)
	end

	-- Fly ---------------------------------------------------------

	local flyParts = nil
	local controls = nil
	local controlsFailed = false

	local function getControls()
		if controls or controlsFailed then
			return controls
		end
		local ok, result = pcall(function()
			local module = LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule", 5)
			return module and require(module):GetControls()
		end)
		if ok and result then
			controls = result
		else
			controlsFailed = true
		end
		return controls
	end

	local function stopFly()
		if not flyParts then
			return
		end
		for _, part in pairs(flyParts) do
			part:Destroy()
		end
		flyParts = nil

		local _, humanoid = getCharacter()
		if humanoid then
			humanoid.PlatformStand = false
			humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
		end
	end

	local function startFly()
		stopFly()
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
		flyParts = { Attachment = attachment, Velocity = velocity, Align = align }
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

	local function padButton(text, onHold)
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
				onHold(true)
			end
		end)

		button.InputEnded:Connect(function(input)
			if isPointer(input) then
				activeInput = nil
				onHold(false)
			end
		end)

		connect(UserInputService.InputEnded, function(input)
			if activeInput and input == activeInput then
				activeInput = nil
				onHold(false)
			end
		end)
	end

	padButton("▲", function(held)
		flyUpHeld = held
	end)
	padButton("▼", function(held)
		flyDownHeld = held
	end)

	local function setFly(enabled)
		flyEnabled = enabled
		FlyPad.Visible = enabled and UserInputService.TouchEnabled
		if not enabled then
			flyUpHeld, flyDownHeld = false, false
			stopFly()
		else
			startFly()
		end
	end

	connect(RunService.RenderStepped, function()
		if not flyEnabled or not flyParts then
			return
		end

		local camera = Workspace.CurrentCamera
		local _, humanoid, root = getCharacter()
		if not (camera and humanoid and root and flyParts.Attachment.Parent) then
			return
		end

		humanoid.PlatformStand = true

		local direction
		if controls then
			direction = camera.CFrame:VectorToWorldSpace(controls:GetMoveVector())
		else
			direction = humanoid.MoveDirection
		end

		local vertical = 0
		if not UserInputService:GetFocusedTextBox() then
			if UserInputService:IsKeyDown(Enum.KeyCode.Space) or UserInputService:IsKeyDown(Enum.KeyCode.E) then
				vertical += 1
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.Q) then
				vertical -= 1
			end
		end
		if flyUpHeld then
			vertical += 1
		end
		if flyDownHeld then
			vertical -= 1
		end

		direction += Vector3.new(0, vertical, 0)
		if direction.Magnitude > 1 then
			direction = direction.Unit
		end

		flyParts.Velocity.VectorVelocity = direction * flySpeed

		local look = camera.CFrame.LookVector
		local flat = Vector3.new(look.X, 0, look.Z)
		if flat.Magnitude > 0.01 then
			flyParts.Align.CFrame = CFrame.lookAt(Vector3.zero, flat)
		end
	end)

	-- Noclip ------------------------------------------------------

	local noclipStored = {}

	connect(RunService.Stepped, function()
		if not noclipEnabled then
			return
		end
		local character = LocalPlayer.Character
		if not character then
			return
		end
		for _, part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") and part.CanCollide then
				noclipStored[part] = true
				part.CanCollide = false
			end
		end
	end)

	local function setNoclip(enabled)
		noclipEnabled = enabled
		if not enabled then
			for part in pairs(noclipStored) do
				if part.Parent then
					part.CanCollide = true
				end
			end
			table.clear(noclipStored)
		end
	end

	-- Infinite jump -------------------------------------------------

	connect(UserInputService.JumpRequest, function()
		if not infiniteJumpEnabled then
			return
		end
		local _, humanoid = getCharacter()
		if humanoid then
			humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end)

	-- ESP -----------------------------------------------------------

	local espObjects = {}
	local espToken = 0

	local function removeESP(player)
		local objects = espObjects[player]
		if objects then
			objects.Highlight:Destroy()
			objects.Billboard:Destroy()
			espObjects[player] = nil
		end
	end

	local function addESP(player)
		removeESP(player)
		if player == LocalPlayer then
			return
		end

		local character = player.Character
		local head = character and character:FindFirstChild("Head")
		if not head then
			return
		end

		local highlight = make("Highlight", {
			Name = "ScHubHighlight",
			Adornee = character,
			DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
			FillColor = THEME.Accent,
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

		espObjects[player] = { Highlight = highlight, Billboard = billboard, Label = label }
	end

	local function updateESP()
		local _, _, myRoot = getCharacter()

		for player, objects in pairs(espObjects) do
			if not objects.Highlight.Parent then
				espObjects[player] = nil
			else
				local character = player.Character
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				local root = character and character:FindFirstChild("HumanoidRootPart")

				if humanoid and root and myRoot then
					local health = humanoid.MaxHealth > 100000
						and "∞"
						or tostring(math.floor(humanoid.Health + 0.5))
					local distance = math.floor((root.Position - myRoot.Position).Magnitude + 0.5)
					objects.Label.Text = string.format("%s\n%s HP  ·  %d studs", player.DisplayName, health, distance)
				end
			end
		end
	end

	local function setESP(enabled)
		espEnabled = enabled
		espToken += 1

		if enabled then
			for _, player in ipairs(Players:GetPlayers()) do
				addESP(player)
			end

			local token = espToken
			task.spawn(function()
				while espEnabled and espToken == token do
					updateESP()
					task.wait(0.25)
				end
			end)
		else
			for player in pairs(espObjects) do
				removeESP(player)
			end
		end
	end

	local function hookESP(player)
		if player == LocalPlayer then
			return
		end
		player.CharacterAdded:Connect(function()
			if espEnabled then
				task.wait(0.5)
				if espEnabled then
					addESP(player)
				end
			end
		end)
	end

	-- Fullbright / FOV / Spectate ----------------------------------

	local savedLighting = nil

	local function setFullbright(enabled)
		if enabled then
			if not savedLighting then
				savedLighting = {
					Brightness = Lighting.Brightness,
					ClockTime = Lighting.ClockTime,
					FogEnd = Lighting.FogEnd,
					GlobalShadows = Lighting.GlobalShadows,
					Ambient = Lighting.Ambient,
					OutdoorAmbient = Lighting.OutdoorAmbient,
				}
			end
			Lighting.Brightness = 2
			Lighting.ClockTime = 14
			Lighting.FogEnd = 1e6
			Lighting.GlobalShadows = false
			Lighting.Ambient = Color3.fromRGB(178, 178, 178)
			Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
		elseif savedLighting then
			for property, value in pairs(savedLighting) do
				Lighting[property] = value
			end
			savedLighting = nil
		end
	end

	local function spectate(player)
		local character = player and player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			Workspace.CurrentCamera.CameraSubject = humanoid
			notify({ Title = CONFIG.Name, Content = "Spectating " .. player.DisplayName .. "." })
		else
			notify({ Title = CONFIG.Name, Content = "Pick a target with a character first." })
		end
	end

	local function stopSpectating()
		local _, humanoid = getCharacter()
		if humanoid then
			Workspace.CurrentCamera.CameraSubject = humanoid
		end
	end

	-- Respawn persistence ----------------------------------------------

	connect(LocalPlayer.CharacterAdded, function(character)
		table.clear(noclipStored)
		flyUpHeld, flyDownHeld = false, false

		if flyEnabled then
			character:WaitForChild("HumanoidRootPart")
			task.wait(0.5)
			if flyEnabled then
				startFly()
			end
		end
	end)

	-- Announcements / server notices ---------------------------------

	connect(Action.OnClientEvent, function(kind, first, second)
		if kind == "Announcement" then
			notify({ Title = "📢 " .. tostring(second), Content = tostring(first), Duration = 7 })
		elseif kind == "Notify" then
			notify({ Title = tostring(first), Content = tostring(second), Duration = 4 })
		end
	end)

	----------------------------------------------------------------
	-- TAB: PLAYERS
	----------------------------------------------------------------

	local function buildOptions(excluded)
		table.clear(optionToPlayer)
		local list = {}
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer and player ~= excluded then
				local label = string.format("%s (@%s)", player.DisplayName, player.Name)
				optionToPlayer[label] = player
				table.insert(list, label)
			end
		end
		table.sort(list, function(a, b)
			return a:lower() < b:lower()
		end)
		return list
	end

	local PlayersTab = createTab("Players")

	PlayersTab:CreateSection("Target")

	local TargetDropdown = PlayersTab:CreateDropdown({
		Name = "Target",
		Options = buildOptions(),
		CurrentOption = {},
		Callback = function(option)
			selectedPlayer = optionToPlayer[option[1]]
		end,
	})

	local targetButtons = {
		{ "Teleport To Target", "TeleportTo" },
		{ "Bring Target", "Bring" },
		{ "Heal Target", "Heal" },
		{ "Kill Target", "Kill" },
		{ "Freeze Target", "Freeze" },
		{ "Unfreeze Target", "Unfreeze" },
		{ "Respawn Target", "Respawn" },
		{ "Kick Target", "Kick" },
	}

	for _, entry in ipairs(targetButtons) do
		PlayersTab:CreateButton({
			Name = entry[1],
			Callback = function()
				sendToTarget(entry[2])
			end,
		})
	end

	PlayersTab:CreateButton({
		Name = "Spectate Target",
		Callback = function()
			spectate(selectedPlayer)
		end,
	})

	PlayersTab:CreateButton({
		Name = "Stop Spectating",
		Callback = stopSpectating,
	})

	PlayersTab:CreateSection("Everyone (you are skipped)")

	local massButtons = {
		{ "Heal Everyone", "HealAll" },
		{ "Kill Everyone", "KillAll" },
		{ "Freeze Everyone", "FreezeAll" },
		{ "Unfreeze Everyone", "UnfreezeAll" },
		{ "Respawn Everyone", "RespawnAll" },
		{ "Bring Everyone", "BringAll" },
	}

	for _, entry in ipairs(massButtons) do
		PlayersTab:CreateButton({
			Name = entry[1],
			Callback = function()
				send(entry[2])
			end,
		})
	end

	local function refreshPlayers()
		TargetDropdown:Refresh(buildOptions())
	end

	Players.PlayerAdded:Connect(function(player)
		hookESP(player)
		refreshPlayers()
	end)

	Players.PlayerRemoving:Connect(function(player)
		if player == selectedPlayer then
			selectedPlayer = nil
		end
		removeESP(player)
		TargetDropdown:Refresh(buildOptions(player))
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		hookESP(player)
	end

	----------------------------------------------------------------
	-- TAB: SELF
	----------------------------------------------------------------

	local SelfTab = createTab("Self")

	SelfTab:CreateSection("Movement")

	local SpeedSlider = SelfTab:CreateSlider({
		Name = "Walk Speed",
		Range = { 0, CONFIG.MaxSpeed },
		Increment = 1,
		CurrentValue = CONFIG.DefaultSpeed,
		Callback = function(value)
			debounced("Speed", 0.15, function()
				send("Speed", nil, value)
			end)
		end,
	})

	local JumpSlider = SelfTab:CreateSlider({
		Name = "Jump Power",
		Range = { 0, CONFIG.MaxJump },
		Increment = 1,
		CurrentValue = CONFIG.DefaultJump,
		Callback = function(value)
			debounced("Jump", 0.15, function()
				send("Jump", nil, value)
			end)
		end,
	})

	SelfTab:CreateButton({
		Name = "Reset Speed & Jump",
		Callback = function()
			SpeedSlider:Set(CONFIG.DefaultSpeed, true)
			JumpSlider:Set(CONFIG.DefaultJump, true)
			send("ResetMovement")
		end,
	})

	SelfTab:CreateSection("Abilities")

	local GodToggle = SelfTab:CreateToggle({
		Name = "God Mode",
		CurrentValue = false,
		Callback = function(value)
			send("God", nil, value)
		end,
	})

	local InfiniteJumpToggle = SelfTab:CreateToggle({
		Name = "Infinite Jump",
		CurrentValue = false,
		Callback = function(value)
			infiniteJumpEnabled = value
		end,
	})

	local NoclipToggle = SelfTab:CreateToggle({
		Name = "Noclip",
		CurrentValue = false,
		Callback = setNoclip,
	})

	local FlyToggle = SelfTab:CreateToggle({
		Name = "Fly  (Space / E up  ·  Ctrl / Q down)",
		CurrentValue = false,
		Callback = setFly,
	})

	SelfTab:CreateSlider({
		Name = "Fly Speed",
		Range = { 10, CONFIG.MaxFlySpeed },
		Increment = 5,
		CurrentValue = flySpeed,
		Callback = function(value)
			flySpeed = value
		end,
	})

	SelfTab:CreateSection("Utility")

	SelfTab:CreateButton({
		Name = "Heal Me",
		Callback = function()
			send("Heal", LocalPlayer)
		end,
	})

	SelfTab:CreateButton({
		Name = "Respawn Me",
		Callback = function()
			send("Respawn", LocalPlayer)
		end,
	})

	SelfTab:CreateButton({
		Name = "Save Position",
		Callback = function()
			local _, _, root = getCharacter()
			if root then
				savedCFrame = root.CFrame
				notify({ Title = CONFIG.Name, Content = "Position saved." })
			end
		end,
	})

	SelfTab:CreateButton({
		Name = "Teleport To Saved Position",
		Callback = function()
			local _, _, root = getCharacter()
			if not savedCFrame then
				notify({ Title = CONFIG.Name, Content = "Save a position first." })
			elseif root then
				root.CFrame = savedCFrame
			end
		end,
	})

	----------------------------------------------------------------
	-- TAB: VISUAL
	----------------------------------------------------------------

	local VisualTab = createTab("Visual")

	local EspToggle = VisualTab:CreateToggle({
		Name = "Player ESP (highlight + name / HP / distance)",
		CurrentValue = false,
		Callback = setESP,
	})

	local FullbrightToggle = VisualTab:CreateToggle({
		Name = "Fullbright",
		CurrentValue = false,
		Callback = setFullbright,
	})

	local FovSlider = VisualTab:CreateSlider({
		Name = "Field Of View",
		Range = { 40, 120 },
		Increment = 1,
		CurrentValue = 70,
		Callback = function(value)
			Workspace.CurrentCamera.FieldOfView = value
		end,
	})

	----------------------------------------------------------------
	-- TAB: SERVER
	----------------------------------------------------------------

	local ServerTab = createTab("Server")

	ServerTab:CreateSection("Announcement")

	local AnnouncementInput = ServerTab:CreateInput({
		Name = "Message",
		PlaceholderText = "Type an announcement...",
		RemoveTextAfterFocusLost = false,
		Callback = function() end,
	})

	ServerTab:CreateButton({
		Name = "📢  Send Announcement",
		Callback = function()
			local text = AnnouncementInput:Get()
			if text:match("%S") then
				send("Announcement", nil, text)
				AnnouncementInput:Set("")
			else
				notify({ Title = CONFIG.Name, Content = "Type a message first." })
			end
		end,
	})

	----------------------------------------------------------------
	-- TAB: INFO
	----------------------------------------------------------------

	local InfoTab = createTab("Info")

	InfoTab:CreateSection("Live stats")
	local FpsLabel = InfoTab:CreateLabel("FPS: --")
	local PingLabel = InfoTab:CreateLabel("Ping: --")
	local PlayersLabel = InfoTab:CreateLabel("Players: --")

	InfoTab:CreateSection("Hub")
	InfoTab:CreateLabel("Show / hide: " .. CONFIG.ToggleKey.Name .. "  (or the small hub button)")

	local function disableEverything()
		for _, toggle in ipairs({
			GodToggle, InfiniteJumpToggle, NoclipToggle,
			FlyToggle, EspToggle, FullbrightToggle,
		}) do
			toggle:Set(false)
		end

		SpeedSlider:Set(CONFIG.DefaultSpeed, true)
		JumpSlider:Set(CONFIG.DefaultJump, true)
		FovSlider:Set(70)
		stopSpectating()

		task.delay(0.2, function()
			send("ResetMovement")
		end)
	end

	InfoTab:CreateButton({
		Name = "Reset Everything",
		Callback = disableEverything,
	})

	InfoTab:CreateButton({
		Name = "Destroy Hub",
		Callback = function()
			disableEverything()
			task.delay(0.5, function()
				for _, connection in ipairs(connections) do
					connection:Disconnect()
				end
				table.clear(connections)
				Gui:Destroy()
			end)
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

			FpsLabel:Set("FPS: " .. fps)
			PingLabel:Set(ok and string.format("Ping: %d ms", math.floor(ping + 0.5)) or "Ping: n/a")
			PlayersLabel:Set(string.format("Players: %d / %d", #Players:GetPlayers(), Players.MaxPlayers))
		end
	end)

	----------------------------------------------------------------
	-- START
	----------------------------------------------------------------

	notify({
		Title = CONFIG.Name,
		Content = "Loaded. Press " .. CONFIG.ToggleKey.Name .. " to hide / show.",
		Duration = 4,
	})

	print("[" .. CONFIG.Name .. "] client loaded - FREE ACCESS")
end

--------------------------------------------------------------------
-- ENTRY POINT
--------------------------------------------------------------------

if RunService:IsServer() then
	runServer()
else
	runClient()
end
