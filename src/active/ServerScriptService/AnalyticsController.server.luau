
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local FunnelService = require(
	script.Parent:WaitForChild("FunnelService")
)

-- Reuse the existing RemoteEvent if it exists
local shopAction = ReplicatedStorage:FindFirstChild(
	"ShopAnalyticsAction"
)

if not shopAction then
	shopAction = Instance.new("RemoteEvent")
	shopAction.Name = "ShopAnalyticsAction"
	shopAction.Parent = ReplicatedStorage
end

local products = {
	[2062003376] = "Pass",
	[3724904088] = "Product",
	[3724905418] = "Product",
	[3724907700] = "Product"
}

local lastPrompt = {}

-- Process shop analytics requests
shopAction.OnServerEvent:Connect(function(player, action, productId)
	if type(action) ~= "string"
		or player:GetAttribute("DataReady") ~= true then
		return
	end

	if action == "open" then
		FunnelService.ShopOpened(player)
		return
	end

	if type(productId) ~= "number"
		or not products[productId] then
		return
	end

	if action == "view" then
		FunnelService.ShopViewed(player, productId)
		return
	end

	if action ~= "purchase"
		or not FunnelService.CanRequest(player, productId) then
		return
	end

	if productId == 2062003376
		and player:GetAttribute("HasBiggerBackpack") ~= false then
		return
	end

	if os.clock() - (lastPrompt[player] or -100) < 1.5 then
		return
	end

	lastPrompt[player] = os.clock()

	local success, err = pcall(function()
		if products[productId] == "Pass" then
			MarketplaceService:PromptGamePassPurchase(
				player, productId
			)
		else
			MarketplaceService:PromptProductPurchase(
				player, productId
			)
		end
	end)

	if success then
		FunnelService.ShopRequested(player, productId)
	else
		warn("Purchase prompt error: " .. tostring(err))
	end
end)

-- Track validated gameplay progression
local function trackPlayer(player)
	while player.Parent == Players
		and player:GetAttribute("DataReady") ~= true do
		task.wait(0.1)
	end

	if player.Parent ~= Players then return end

	FunnelService.Onboarding(player, 1)

	player.CharacterAdded:Connect(function()
		FunnelService.Progression(player, 1)
	end)

	if player.Character then
		FunnelService.Progression(player, 1)
	end

	local function snapshot()
		return {
			count = player:GetAttribute("CarriedCount") or 0,
			value = player:GetAttribute("CarriedValue") or 0,
			coins = player:GetAttribute("Coins") or 0,
			level = player:GetAttribute("BackpackLevel") or 1,
			cave = player:GetAttribute("CaveUnlocked") == true
		}
	end

	local previous = snapshot()
	local purpleHeld = 0
	local scheduled = false

	local function check()
		if scheduled then return end
		scheduled = true

		task.defer(function()
			scheduled = false

			if player.Parent ~= Players
				or player:GetAttribute("DataReady") ~= true then
				return
			end

			local current = snapshot()

			local countAdded = current.count - previous.count
			local valueAdded = current.value - previous.value

			-- Crystal collected
			if countAdded > 0 and valueAdded > 0 then
				FunnelService.Onboarding(player, 2)

				if valueAdded == 15
					and countAdded == 1
					and current.cave then

					purpleHeld += 1
					FunnelService.Progression(player, 3)
				end
			end

			-- Backpack sold
			if previous.count > 0
				and current.count == 0
				and current.value == 0
				and current.coins > previous.coins then

				FunnelService.Onboarding(player, 3)

				if purpleHeld > 0 and current.cave then
					FunnelService.Progression(player, 4)
				end

				purpleHeld = 0
			end

			-- Backpack upgrade
			if current.level > previous.level
				and current.coins < previous.coins then

				FunnelService.Onboarding(player, 4)
			end

			-- Crystal Cave unlock
			if current.cave
				and not previous.cave
				and current.coins < previous.coins then

				FunnelService.Onboarding(player, 5)
				FunnelService.Progression(player, 2)
			end

			previous = current
		end)
	end

	for _, name in {
		"CarriedCount",
		"CarriedValue",
		"Coins",
		"BackpackLevel",
		"CaveUnlocked"
		} do
		player:GetAttributeChangedSignal(name):Connect(check)
	end
end

Players.PlayerAdded:Connect(function(player)
	task.spawn(trackPlayer, player)
end)

for _, player in Players:GetPlayers() do
	task.spawn(trackPlayer, player)
end

Players.PlayerRemoving:Connect(function(player)
	lastPrompt[player] = nil
	FunnelService.Cleanup(player)
end)
