
local crystal = script.Parent
local prompt = crystal:WaitForChild("ProximityPrompt")


local crystalValue = 15

local respawnTime = 8
local available = true

prompt.Triggered:Connect(function(player)

	-- Prevent two players collecting the same crystal
	if not available or not prompt.Enabled then
		return
	end

	-- Check that the player is close enough
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")

	if not root then
		return
	end

	local distance = (root.Position - crystal.Position).Magnitude

	if distance > prompt.MaxActivationDistance then
		return
	end

	-- Check backpack capacity
	local count = player:GetAttribute("CarriedCount") or 0
	local capacity = player:GetAttribute("BackpackCapacity") or 10

	if count >= capacity then
		print("Backpack full! Sell your crystals!")
		return
	end

	-- Mark crystal as collected
	available = false
	prompt.Enabled = false
	crystal.Transparency = 1

	-- Add crystal to backpack, NOT directly to coins
	player:SetAttribute("CarriedCount", count + 1)

	local currentValue = player:GetAttribute("CarriedValue") or 0
	player:SetAttribute("CarriedValue", currentValue + crystalValue)

	print(player.Name .. " collected a Blue Crystal!")
	print("Backpack: " .. (count + 1) .. "/" .. capacity)

	-- Respawn crystal after 8 seconds
	task.delay(respawnTime, function()
		crystal.Transparency = 0
		available = true
		prompt.Enabled = true
	end)
end)
