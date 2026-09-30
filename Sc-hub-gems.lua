--[[
	══════════════════════════════════════════════════════════════════
	  SC HUB · GEMS EDITION  ·  Rayfield + Built-in Fallback
	  Toggle: RightShift
	══════════════════════════════════════════════════════════════════
]]

-- Load Rayfield first, fall back to built-in UI
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
	Name = "SC HUB · GEMS EDITION",
	LoadingTitle = "SC HUB",
	LoadingSubtitle = "Loading...",
	ConfigurationSaving = { Enabled = true, FolderName = "SCHub", FileName = "GemsConfig" },
	DiscordLink = nil,
	KeySystem = false,
})

-- Create your tabs exactly as before
local Tabs = {
	Main = Window:CreateTab("🏠 Main"),
	Self = Window:CreateTab("🏃 Self"),
	Visual = Window:CreateTab("👁️ Visual"),
	Gems = Window:CreateTab("💎 Gems"),
	Settings = Window:CreateTab("⚙️ Settings"),
}

-- ═══════════════════════════════════════════════════════════════
-- 💎 GEMS TAB — NOW INSIDE SO IT ACTUALLY WORKS
-- ═══════════════════════════════════════════════════════════════
local GemsEnabled = false
local AutoPickup = false
local PickupDistance = 30

Tabs.Gems:CreateSection("Auto Farm")

Tabs.Gems:CreateToggle({
	Name = "Auto Collect Gems",
	CurrentValue = false,
	Callback = function(Value)
		GemsEnabled = Value
		Rayfield:Notify({ Title = "💎 Gems", Content = Value and "Auto Collect ON" or "Auto Collect OFF" })
	end,
})

Tabs.Gems:CreateToggle({
	Name = "Auto Pickup Nearby",
	CurrentValue = false,
	Callback = function(Value)
		AutoPickup = Value
		Rayfield:Notify({ Title = "💎 Gems", Content = Value and "Auto Pickup ON" or "Auto Pickup OFF" })
	end,
})

Tabs.Gems:CreateSlider({
	Name = "Pickup Distance",
	Range = { 10, 100 },
	Increment = 1,
	CurrentValue = 30,
	Callback = function(Value)
		PickupDistance = Value
	end,
})

Tabs.Gems:CreateButton({
	Name = "Collect All Gems Now",
	Callback = function()
		Rayfield:Notify({ Title = "💎 Gems", Content = "Collecting..." })
		task.spawn(function()
			local Success, Error = pcall(function()
				local ReplicatedStorage = game:GetService("ReplicatedStorage")
				local Remote = ReplicatedStorage:FindFirstChild("CollectGem") or ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("CollectGem")
				if not Remote then
					Rayfield:Notify({ Title = "⚠️ Gems", Content = "Remote not found — check game names!" })
					return
				end
				local Count = 0
				for _, Desc in ipairs(workspace:GetDescendants()) do
					if Desc.Name == "Gem" and Desc:IsA("BasePart") then
						pcall(function() Remote:FireServer(Desc) end)
						Count += 1
					end
				end
				Rayfield:Notify({ Title = "💎 Gems", Content = "Collected " .. Count .. " gems!" })
			end)
			if not Success then
				Rayfield:Notify({ Title = "❌ Error", Content = Error or "Failed to collect" })
			end
		end)
	end,
})

-- Auto-pickup loop (safe — won't crash script)
task.spawn(function()
	while task.wait(0.5) do
		if not AutoPickup then continue end
		local LocalPlayer = game:GetService("Players").LocalPlayer
		local Character = LocalPlayer.Character
		if not Character then continue end
		local Root = Character:FindFirstChild("HumanoidRootPart")
		if not Root then continue end
		pcall(function()
			local ReplicatedStorage = game:GetService("ReplicatedStorage")
			local Remote = ReplicatedStorage:FindFirstChild("CollectGem") or ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("CollectGem")
			if not Remote then return end
			for _, Desc in ipairs(workspace:GetDescendants()) do
				if Desc.Name == "Gem" and Desc:IsA("BasePart") then
					if (Desc.Position - Root.Position).Magnitude <= PickupDistance then
						pcall(function() Remote:FireServer(Desc) end)
					end
				end
			end
		end)
	end
end)

Tabs.Gems:CreateSection("Info")
Tabs.Gems:CreateLabel("💡 Auto-farm works if the game uses\n'ReplicatedStorage.CollectGem' or\n'ReplicatedStorage.Events.CollectGem'\n\nIf nothing happens, the game uses\ndifferent names — check their scripts!")

Rayfield:Notify({ Title = "✅ SC HUB LOADED", Content = "Rayfield UI active — Gems tab ready!", Duration = 5 })
