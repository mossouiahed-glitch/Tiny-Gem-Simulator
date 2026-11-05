
local Players = game:GetService("Players")

local station = script.Parent
local prompt = station:WaitForChild("ProximityPrompt")

local lastSell = {}

local function validNumber(value)
	return type(value) == "number"
		and value >= 0
		and value < math.huge
		and value % 1 == 0
end

prompt.Triggered:Connect(function(player)

	if player:GetAttribute("EconomyLocked") == true then return end

	-- Wait until saved progression is loaded
	if player:GetAttribute("DataReady") ~= true then
		return
	end

	-- Prevent rapid repeated selling
	local now = os.clock()
	if now - (lastSell[player] or -100) < 0.5 then
		return
	end
	lastSell[player] = now

	-- Verify player is near the station
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	if not root or not humanoid or humanoid.Health <= 0 then
		return
	end

	if (root.Position - station.Position).Magnitude > 12 then
		return
	end

	-- Read backpack and currency
	local count = player:GetAttribute("CarriedCount")
	local value = player:GetAttribute("CarriedValue")
	local capacity = player:GetAttribute("BackpackCapacity")
	local coins = player:GetAttribute("Coins")

	if not validNumber(count)
		or not validNumber(value)
		or not validNumber(capacity)
		or not validNumber(coins) then
		return
	end

	if count == 0 then
		print("Your backpack is empty!")
		return
	end

	-- Check that the backpack values are reasonable
	if count > capacity
		or value < count * 5
		or value > count * 50 then
		warn("Invalid backpack contents")
		return
	end

	-- Check whether Double Coins is active
	local expiresAt = player:GetAttribute("BoostExpiresAt") or 0
	local multiplier = 1

	if validNumber(expiresAt) and os.time() < expiresAt then
		multiplier = 2
	end

	-- Calculate reward on the server
	local reward = value * multiplier

	-- Empty backpack and award coins
	player:SetAttribute("CarriedCount", 0)
	player:SetAttribute("CarriedValue", 0)
	player:SetAttribute("Coins", coins + reward)

	player:SetAttribute("SaleAnnouncement", tostring(os.clock()) .. ":" .. tostring(reward))

	print("Sold " .. count .. " crystals!")
	print("Multiplier: x" .. multiplier)
	print("Earned +" .. reward .. " coins!")
end)

Players.PlayerRemoving:Connect(function(player)
	lastSell[player] = nil
end)




