
local AnalyticsService = game:GetService("AnalyticsService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local FunnelService = {}
local state = {}

local onboardingNames = {
	"Player Joined",
	"First Crystal Collected",
	"First Backpack Sold",
	"First Upgrade Purchased",
	"Second Area Unlocked"
}

local progressionNames = {
	"Starting Area Entered",
	"Crystal Cave Unlocked",
	"First Purple Crystal Collected",
	"First Purple Crystal Sold"
}

local shopNames = {
	"Shop Opened",
	"Product Viewed",
	"Purchase Requested",
	"Purchase Confirmed"
}

local productNames = {
	[2062003376] = "Bigger Backpack",
	[3724904088] = "Coin Pack",
	[3724905418] = "Double Coins",
	[3724907700] = "Sell Vouchers"
}

local function getState(player)
	if not state[player] then
		state[player] = {
			onboarding = {},
			progression = {},
			shop = nil,
			lastOpen = 0
		}
	end
	return state[player]
end

local function logEvent(player, funnelName, sessionId, step, stepName, productId)
	if RunService:IsStudio() then
		print("[FUNNEL TEST] " .. funnelName
			.. " | Step " .. step .. ": " .. stepName)
		return
	end

	local fields = nil

	if productId then
		fields = {
			[Enum.AnalyticsCustomFieldKeys.CustomField01.Name] =
				productNames[productId] or "Unknown"
		}
	end

	local success, err = pcall(function()
		if funnelName == "FirstTimeExperience" then
			AnalyticsService:LogOnboardingFunnelStepEvent(
				player, step, stepName, fields
			)
		else
			AnalyticsService:LogFunnelStepEvent(
				player, funnelName, sessionId,
				step, stepName, fields
			)
		end
	end)

	if not success then
		warn("Analytics error: " .. tostring(err))
	end
end

function FunnelService.Onboarding(player, step)
	if player:GetAttribute("DataReady") ~= true
		or not onboardingNames[step] then
		return
	end

	local s = getState(player)
	if s.onboarding[step] then return end

	s.onboarding[step] = true

	logEvent(
		player, "FirstTimeExperience",
		nil, step, onboardingNames[step]
	)
end

function FunnelService.Progression(player, step)
	if player:GetAttribute("DataReady") ~= true
		or not progressionNames[step] then
		return
	end

	local s = getState(player)
	if s.progression[step] then return end

	s.progression[step] = true

	logEvent(
		player, "CrystalProgression",
		nil, step, progressionNames[step]
	)
end

function FunnelService.ShopOpened(player)
	if player:GetAttribute("DataReady") ~= true then
		return
	end

	local s = getState(player)

	if os.clock() - s.lastOpen < 0.5 then
		return
	end

	s.lastOpen = os.clock()

	s.shop = {
		id = HttpService:GenerateGUID(false),
		viewed = nil,
		requested = nil,
		confirmed = false
	}

	logEvent(
		player, "ShopCheckout",
		s.shop.id, 1, shopNames[1]
	)
end

function FunnelService.ShopViewed(player, productId)
	if player:GetAttribute("DataReady") ~= true
		or not productNames[productId] then
		return
	end

	local shop = getState(player).shop
	if not shop then return end

	shop.viewed = productId

	if not shop.didView then
		shop.didView = true

		logEvent(
			player, "ShopCheckout",
			shop.id, 2, shopNames[2], productId
		)
	end
end

function FunnelService.ShopRequested(player, productId)
	local shop = getState(player).shop

	if not shop
		or shop.viewed ~= productId
		or not productNames[productId] then
		return false
	end

	shop.requested = productId

	if not shop.didRequest then
		shop.didRequest = true

		logEvent(
			player, "ShopCheckout",
			shop.id, 3, shopNames[3], productId
		)
	end

	return true
end

function FunnelService.CanRequest(player, productId)
	local shop = getState(player).shop

	return player:GetAttribute("DataReady") == true
		and productNames[productId] ~= nil
		and shop ~= nil
		and shop.viewed == productId
		and not shop.confirmed
end

function FunnelService.ShopConfirmed(player, productId)
	local shop = getState(player).shop

	if not shop
		or shop.requested ~= productId
		or shop.confirmed then
		return
	end

	shop.confirmed = true

	logEvent(
		player, "ShopCheckout",
		shop.id, 4, shopNames[4], productId
	)
end

function FunnelService.Cleanup(player)
	state[player] = nil
end

return FunnelService
