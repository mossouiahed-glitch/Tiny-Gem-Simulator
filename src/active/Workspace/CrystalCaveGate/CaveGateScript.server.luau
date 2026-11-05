
local Players = game:GetService("Players")

local gate = script.Parent
local prompt = gate:WaitForChild("ProximityPrompt")
local caveFloor = workspace:WaitForChild("CrystalCaveFloor")

local unlockCost = 250
local requiredLevel = 2

local lastUse = {}

prompt.Triggered:Connect(function(player)

	if player:GetAttribute("EconomyLocked") == true then return end

	-- Check the player is alive and near the gate
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	if not root or not humanoid or humanoid.Health <= 0 then
		return
	end

	local distance = (root.Position - gate.Position).Magnitude

	if distance > prompt.MaxActivationDistance + 2 then
		return
	end

	-- Prevent very rapid repeated interactions
	local now = os.clock()

	if lastUse[player] and now - lastUse[player] < 1 then
		return
	end

	lastUse[player] = now

	-- Check if this player already unlocked the cave
	local unlocked = player:GetAttribute("CaveUnlocked") == true

	if not unlocked then

		local level = player:GetAttribute("BackpackLevel") or 1
		local coins = player:GetAttribute("Coins") or 0

		-- Reject invalid progression values
		if type(level) ~= "number"
			or type(coins) ~= "number"
			or level % 1 ~= 0
			or coins % 1 ~= 0
			or coins < 0
			or coins == math.huge
			or coins ~= coins then
			return
		end

		-- Check backpack level
		if level < requiredLevel then
			print("You need Backpack Level 2!")
			return
		end

		-- Check coin balance
		if coins < unlockCost then
			print("Not enough coins! You need 250.")
			return
		end

		-- Pay and unlock the cave
		player:SetAttribute("Coins", coins - unlockCost)
		player:SetAttribute("CaveUnlocked", true)

		print("Crystal Cave unlocked!")

	end

	-- Teleport the player above the cave floor
	local destination = caveFloor.Position
		+ Vector3.new(0, caveFloor.Size.Y / 2 + 4, 0)

	character:PivotTo(CFrame.new(destination))

	print(player.Name .. " entered Crystal Cave!")

end)

Players.PlayerRemoving:Connect(function(player)
	lastUse[player] = nil
end)
