-- STEP 5.2: NEW regular Script named PurchaseService in ServerScriptService
-- Only this server script handles developer-product receipts.

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataService = require(script.Parent:WaitForChild("DataService"))
local FunnelService = require(script.Parent:WaitForChild("FunnelService"))
local PASS_ID = 2062003376
local COIN_PACK_ID = 3724904088
local DOUBLE_COINS_ID = 3724905418
local SELL_VOUCHERS_ID = 3724907700

local validProducts = {
	[COIN_PACK_ID] = true,
	[DOUBLE_COINS_ID] = true,
	[SELL_VOUCHERS_ID] = true
}

local baseCapacities = {[1] = 10, [2] = 20, [3] = 35}

local feedback = Instance.new("RemoteEvent")
feedback.Name = "PurchaseFeedback"
feedback.Parent = ReplicatedStorage

local function updatePassOwnership(player)
	if player.Parent ~= Players or player:GetAttribute("DataReady") ~= true then
		return
	end

	local success, owns
	for attempt = 1, 3 do
		success, owns = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, PASS_ID)
		end)
		if success then break end
		if attempt < 3 then task.wait(1) end
	end

	if not success then
		warn("Could not verify Bigger Backpack ownership for " .. player.Name)
		return -- Leave HasBiggerBackpack unset. Don't claim they don't own it.
	end

	local level = player:GetAttribute("BackpackLevel")
	if not baseCapacities[level] then return end

	player:SetAttribute("HasBiggerBackpack", owns)
	player:SetAttribute("BackpackCapacity", baseCapacities[level] + (owns and 10 or 0))
end

local function afterDataReady(player)
	while player.Parent == Players and player:GetAttribute("DataReady") ~= true do
		task.wait(0.2)
	end
	if player.Parent == Players then
		updatePassOwnership(player)
	end
end

Players.PlayerAdded:Connect(function(player)
	task.spawn(afterDataReady, player)
end)
for _, player in Players:GetPlayers() do
	task.spawn(afterDataReady, player)
end

-- Reverify ownership on the SERVER after a successful game pass prompt.
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, id, purchased)
	if id == PASS_ID and purchased then
		updatePassOwnership(player)
		if player:GetAttribute("HasBiggerBackpack") == true then
			FunnelService.ShopConfirmed(player, id)
		end
	end
end)


-- One ProcessReceipt callback for all THREE developer products.
MarketplaceService.ProcessReceipt = function(receipt)
	if not validProducts[receipt.ProductId] then
		warn("Unrecognized product ID: " .. tostring(receipt.ProductId))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- A receipt may arrive before this player's saved data finishes loading.
	local start = os.clock()
	while player.Parent == Players
		and player:GetAttribute("DataReady") ~= true
		and os.clock() - start < 25 do
		task.wait(0.2)
	end

	if player.Parent ~= Players or player:GetAttribute("DataReady") ~= true then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- This writes BOTH the reward and receipt ID to ONE saved player record.
	local ok, newlyGranted = DataService.ApplyReceipt(player, receipt)
	if not ok then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	if newlyGranted and player.Parent == Players then
		FunnelService.ShopConfirmed(player, receipt.ProductId)
		feedback:FireClient(player, "Purchase confirmed! Reward saved.")
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end
-- Paste at the BOTTOM of your EXISTING PurchaseService (regular Script).
-- Do not make a second ProcessReceipt callback or a second PurchaseService.
-- PurchaseService already defines ReplicatedStorage, Players, and DataService.

local redeemRemote = Instance.new("RemoteEvent")
redeemRemote.Name = "RedeemVoucher"
redeemRemote.Parent = ReplicatedStorage

redeemRemote.OnServerEvent:Connect(function(player)
	local ok, message = DataService.RedeemVoucher(player)
	if player.Parent == Players then
		redeemRemote:FireClient(player, ok, message)
	end
end)
