
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local station = script.Parent
local prompt = station:WaitForChild("ProximityPrompt")

prompt.ActionText = "Open Upgrades"

-- Create communication between UI and server
local remote = ReplicatedStorage:FindFirstChild("UpgradeAction")

if not remote then
	remote = Instance.new("RemoteEvent")
	remote.Name = "UpgradeAction"
	remote.Parent = ReplicatedStorage
end

local upgrades = {
	[1] = {cost = 100, capacity = 20},
	[2] = {cost = 350, capacity = 35}
}

local lastRequest = {}

remote.OnServerEvent:Connect(function(player)

	if player:GetAttribute("EconomyLocked") == true then return end

	if player:GetAttribute("DataReady") ~= true then
		return
	end

	-- Prevent rapid repeated purchases
	local now = os.clock()
	if now - (lastRequest[player] or -100) < 0.5 then
		return
	end
	lastRequest[player] = now

	-- Validate distance and character
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	if not root or not humanoid or humanoid.Health <= 0
		or (root.Position - station.Position).Magnitude > 12 then
		remote:FireClient(player, false, "Move closer to the station!")
		return
	end

	local level = player:GetAttribute("BackpackLevel")
	local coins = player:GetAttribute("Coins")

	if type(level) ~= "number" or level % 1 ~= 0
		or level < 1 or level > 3
		or type(coins) ~= "number" or coins % 1 ~= 0
		or coins < 0 or coins == math.huge then
		return
	end

	local upgrade = upgrades[level]

	if not upgrade then
		remote:FireClient(player, false, "Maximum level reached!")
		return
	end

	if coins < upgrade.cost then
		remote:FireClient(player, false, "Not enough coins!")
		return
	end

	-- Only the server grants the upgrade
	player:SetAttribute("Coins", coins - upgrade.cost)
	player:SetAttribute("BackpackLevel", level + 1)

	player:SetAttribute("BackpackCapacity", upgrade.capacity + (player:GetAttribute("HasBiggerBackpack") == true and 10 or 0))


	remote:FireClient(player, true, "Upgrade successful!")
end)

Players.PlayerRemoving:Connect(function(player)
	lastRequest[player] = nil
end)

