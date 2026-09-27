-- NeedleHighlighter.lua
-- Place this as a LocalScript inside StarterPlayerScripts
-- Every player gets this UI and can use it to highlight the needle for themselves.

local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

-- ============ CONFIG ============
-- If your needle object has a CollectionService tag, set it here.
local NEEDLE_TAG = "Needle"

-- Fallback: if no tagged instance is found, search by name inside this folder.
-- Set to Workspace if your haystack items are directly in Workspace.
local HAYSTACK_CONTAINER = Workspace
local NEEDLE_NAME = "Needle"
-- =================================

-- Load Rayfield
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
	Name = "Needle Finder",
	LoadingTitle = "Needle Finder",
	LoadingSubtitle = "Find the needle in the haystack",
	ConfigurationSaving = {
		Enabled = false,
	},
})

local Tab = Window:CreateTab("Needle Finder", 4483362458)

local currentHighlight = nil

local function findNeedle()
	local tagged = CollectionService:GetTagged(NEEDLE_TAG)
	if #tagged > 0 then
		return tagged[1]
	end

	return HAYSTACK_CONTAINER:FindFirstChild(NEEDLE_NAME, true)
end

local function clearHighlight()
	if currentHighlight then
		currentHighlight:Destroy()
		currentHighlight = nil
	end
end

Tab:CreateButton({
	Name = "Highlight Needle",
	Callback = function()
		clearHighlight()

		local needle = findNeedle()
		if not needle then
			Rayfield:Notify({
				Title = "Not Found",
				Content = "Couldn't find the needle. Check the tag/name config.",
				Duration = 3,
			})
			return
		end

		local highlight = Instance.new("Highlight")
		highlight.FillColor = Color3.fromRGB(255, 0, 0)
		highlight.OutlineColor = Color3.fromRGB(255, 255, 0)
		highlight.FillTransparency = 0.5
		highlight.OutlineTransparency = 0
		highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		highlight.Adornee = needle
		highlight.Parent = needle

		currentHighlight = highlight

		Rayfield:Notify({
			Title = "Needle Found",
			Content = "Highlighted: " .. needle:GetFullName(),
			Duration = 3,
		})
	end,
})

Tab:CreateButton({
	Name = "Clear Highlight",
	Callback = function()
		clearHighlight()
	end,
})

-- ============================================================
-- FARM TAB: Auto Grab Hay + Auto Feed Cow
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

-- ============ FARM CONFIG ============
local HAY_TAG = "Hay"              -- CollectionService tag on hay pickups (if you use one)
local HAY_CONTAINER = Workspace    -- fallback search root if no tag is used
local HAY_NAME = "Hay"             -- fallback: name of the part/model holding the ProximityPrompt
local GRAB_RADIUS = 12             -- studs; only trigger prompts within this range

local COW_TAG = "Cow"              -- CollectionService tag on cow(s) (if you use one)
local COW_CONTAINER = Workspace    -- fallback search root if no tag is used
local COW_NAME = "Cow"             -- fallback: name of the cow model
local FEED_RADIUS = 10             -- studs; only feed when this close to a cow
local FEED_COOLDOWN = 1            -- seconds between feed button presses

-- EDIT THIS: return the actual feed button Instance in your PlayerGui.
-- Example: return player.PlayerGui:WaitForChild("FeedGui"):WaitForChild("FeedButton")
local function getFeedButton()
	local gui = player:WaitForChild("PlayerGui")
	local ok, button = pcall(function()
		return gui:WaitForChild("FeedGui", 5):WaitForChild("FeedButton", 5)
	end)
	if ok then
		return button
	end
	return nil
end
-- ======================================

local autoGrabEnabled = false
local autoFeedEnabled = false
local lastFeedTime = 0

local function getPosition(inst)
	if inst:IsA("BasePart") then
		return inst.Position
	elseif inst:IsA("Model") then
		return inst:GetPivot().Position
	end
	return nil
end

local function getHayPrompts()
	local prompts = {}

	for _, tagged in ipairs(CollectionService:GetTagged(HAY_TAG)) do
		local prompt = tagged:IsA("ProximityPrompt") and tagged or tagged:FindFirstChildOfClass("ProximityPrompt")
		if prompt then
			table.insert(prompts, prompt)
		end
	end

	if #prompts == 0 then
		for _, inst in ipairs(HAY_CONTAINER:GetDescendants()) do
			if inst:IsA("ProximityPrompt") and inst.Parent and inst.Parent.Name == HAY_NAME then
				table.insert(prompts, inst)
			end
		end
	end

	return prompts
end

local function getCows()
	local cows = {}

	for _, tagged in ipairs(CollectionService:GetTagged(COW_TAG)) do
		table.insert(cows, tagged)
	end

	if #cows == 0 then
		for _, inst in ipairs(COW_CONTAINER:GetChildren()) do
			if inst.Name == COW_NAME then
				table.insert(cows, inst)
			end
		end
	end

	return cows
end

local function firePrompt(prompt)
	local ok = pcall(function()
		prompt:InputHoldBegin()
		task.wait((prompt.HoldDuration or 0) + 0.05)
		prompt:InputHoldEnd()
	end)
	return ok
end

local function getRootPosition()
	local character = player.Character
	if not character then
		return nil
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	return root and root.Position or nil
end

RunService.Heartbeat:Connect(function()
	local rootPos = getRootPosition()
	if not rootPos then
		return
	end

	if autoGrabEnabled then
		for _, prompt in ipairs(getHayPrompts()) do
			local pos = getPosition(prompt.Parent)
			if pos and (pos - rootPos).Magnitude <= GRAB_RADIUS then
				task.spawn(firePrompt, prompt)
			end
		end
	end

	if autoFeedEnabled and (os.clock() - lastFeedTime) >= FEED_COOLDOWN then
		for _, cow in ipairs(getCows()) do
			local pos = getPosition(cow)
			if pos and (pos - rootPos).Magnitude <= FEED_RADIUS then
				local button = getFeedButton()
				if button then
					local ok = pcall(function()
						button:Activate()
					end)
					if ok then
						lastFeedTime = os.clock()
					end
				end
				break
			end
		end
	end
end)

local FarmTab = Window:CreateTab("Farm", 4483362458)

FarmTab:CreateToggle({
	Name = "Auto Grab Hay",
	CurrentValue = false,
	Callback = function(value)
		autoGrabEnabled = value
	end,
})

FarmTab:CreateToggle({
	Name = "Auto Feed Cow",
	CurrentValue = false,
	Callback = function(value)
		autoFeedEnabled = value
	end,
})
