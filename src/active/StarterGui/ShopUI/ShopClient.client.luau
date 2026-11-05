-- STEP 5.2: NEW LocalScript named ShopClient inside StarterGui > ShopUI (ScreenGui).
-- Handles only the SHOP DISPLAY and Roblox purchase prompts.
-- Never grant coins, boost time, vouchers, or capacity on the client.

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local gui = script.Parent
local shopAction = ReplicatedStorage:WaitForChild("ShopAnalyticsAction")
local selectedProductId = nil

gui.ResetOnSpawn = false

local products = {
	{name="Bigger Backpack", id=2062003376, price=79,
		detail="Permanent +10 backpack slots", pass=true},
	{name="Coin Pack", id=3724904088, price=19,
		detail="Receive 250 coins"},
	{name="Double Coins", id=3724905418, price=29,
		detail="Double sell income for 10 minutes"},
	{name="Sell Vouchers", id=3724907700, price=15,
		detail="Receive 3 instant-sell vouchers"}
}

local function make(className, parent, options)
	local object = Instance.new(className)
	for key, value in pairs(options) do object[key] = value end
	object.Parent = parent
	return object
end

local function corner(instance)
	make("UICorner", instance, {CornerRadius=UDim.new(0, 10)})
end

-- Visible top-right SHOP button (works with mouse and touch)
local openButton = make("TextButton", gui, {
	Name="OpenShop", AnchorPoint=Vector2.new(1, 0),
	Position=UDim2.new(1, -12, 0, 145), Size=UDim2.fromOffset(130, 46),
	BackgroundColor3=Color3.fromRGB(43, 119, 181),
	Text="SHOP", TextColor3=Color3.new(1, 1, 1),
	Font=Enum.Font.GothamBold, TextScaled=true
})
corner(openButton)

local frame = make("Frame", gui, {
	Name="ShopPanel", AnchorPoint=Vector2.new(0.5, 0.5),
	Position=UDim2.fromScale(0.5, 0.5), Size=UDim2.new(0.94, 0, 0.82, 0),
	BackgroundColor3=Color3.fromRGB(32, 42, 65), Visible=false
})
corner(frame)
make("UISizeConstraint", frame, {MaxSize=Vector2.new(460, 545)})

make("TextLabel", frame, {
	Position=UDim2.fromOffset(12, 7), Size=UDim2.new(1, -80, 0, 40),
	BackgroundTransparency=1, Text="GEM SHOP",
	TextColor3=Color3.new(1, 1, 1), TextScaled=true,
	Font=Enum.Font.GothamBold
})
local close = make("TextButton", frame, {
	Position=UDim2.new(1, -47, 0, 9), Size=UDim2.fromOffset(36, 36),
	BackgroundColor3=Color3.fromRGB(166, 61, 76),
	Text="X", TextColor3=Color3.new(1, 1, 1), TextSize=19
})
corner(close)

local list = make("ScrollingFrame", frame, {
	Position=UDim2.fromOffset(12, 55), Size=UDim2.new(1, -24, 1, -115),
	BackgroundTransparency=1, BorderSizePixel=0,
	ScrollBarThickness=5, AutomaticCanvasSize=Enum.AutomaticSize.Y,
	CanvasSize=UDim2.fromOffset(0, 0)
})
make("UIListLayout", list, {Padding=UDim.new(0, 9), SortOrder=Enum.SortOrder.LayoutOrder})

local status = make("TextLabel", frame, {
	Position=UDim2.new(0, 12, 1, -49), Size=UDim2.new(1, -24, 0, 38),
	BackgroundTransparency=1, Text="",
	TextWrapped=true, TextScaled=true, TextColor3=Color3.fromRGB(230, 236, 255)
})

local passButton
for i, product in ipairs(products) do
	local item = make("Frame", list, {
		Name=product.name:gsub("%s", ""), LayoutOrder=i,
		Size=UDim2.new(1, -9, 0, 90),
		BackgroundColor3=Color3.fromRGB(55, 69, 102)
	})
	corner(item)

	make("TextLabel", item, {
		Size=UDim2.new(1, -140, 0, 35), Position=UDim2.fromOffset(12, 7),
		BackgroundTransparency=1, Text=product.name,
		TextColor3=Color3.fromRGB(255, 255, 255),
		Font=Enum.Font.GothamBold, TextSize=17,
		TextWrapped=true, TextXAlignment=Enum.TextXAlignment.Left
	})
	make("TextLabel", item, {
		Size=UDim2.new(1, -140, 0, 38), Position=UDim2.fromOffset(12, 43),
		BackgroundTransparency=1, Text=product.detail,
		TextColor3=Color3.fromRGB(203, 217, 239),
		TextSize=13, TextWrapped=true,
		TextXAlignment=Enum.TextXAlignment.Left
	})

	local buy = make("TextButton", item, {
		Size=UDim2.new(0, 118, 0, 35),
		Position=UDim2.new(1, -128, 0, 49),
		BackgroundColor3=Color3.fromRGB(102, 188, 97),
		Text=tostring(product.price) .. " R$",
		TextColor3=Color3.new(1, 1, 1),
		Font=Enum.Font.GothamBold, TextSize=17
	})
	corner(buy)

	if product.pass then passButton = buy end

	-- Selecting a specific product is a separate VIEW funnel step.
	local view = make("TextButton", item, {
		Name="ViewProduct", Size=UDim2.new(0, 118, 0, 29),
		Position=UDim2.new(1, -128, 0, 8),
		BackgroundColor3=Color3.fromRGB(67, 126, 190),
		Text="VIEW", TextColor3=Color3.new(1, 1, 1),
		Font=Enum.Font.GothamBold, TextSize=15
	})
	corner(view)
	view.Activated:Connect(function()
		if player:GetAttribute("DataReady") ~= true then return end
		selectedProductId = product.id
		status.Text = "Selected: " .. product.name .. " — " .. product.detail
		shopAction:FireServer("view", product.id)
	end)

	buy.Activated:Connect(function()
		if player:GetAttribute("DataReady") ~= true then
			status.Text = "Player data is still loading."
			return
		end
		if product.pass then
			local owns = player:GetAttribute("HasBiggerBackpack")
			if owns == nil then
				status.Text = "Checking pass ownership. Try again shortly."
				return
			end
			if owns then
				status.Text = "You already own this pass!"
				return
			end
		end

		if selectedProductId ~= product.id then
			status.Text = "Click VIEW for this product before buying."
			return
		end
		status.Text = "Requesting Roblox purchase prompt..."
		shopAction:FireServer("purchase", product.id)
	end)
end

local function refreshPassButton()
	if not passButton then return end
	local owns = player:GetAttribute("HasBiggerBackpack")
	if owns == true then
		passButton.Text = "OWNED"
		passButton.BackgroundColor3 = Color3.fromRGB(85, 96, 112)
	elseif owns == nil then
		passButton.Text = "CHECKING..."
	else
		passButton.Text = "79 R$"
	end
end
player:GetAttributeChangedSignal("HasBiggerBackpack"):Connect(refreshPassButton)
refreshPassButton()

openButton.Activated:Connect(function()
	frame.Visible = true
	selectedProductId = nil
	shopAction:FireServer("open")
	status.Text = "Click VIEW for a product, then its Robux price to buy."
end)
close.Activated:Connect(function() frame.Visible = false end)

ReplicatedStorage:WaitForChild("PurchaseFeedback").OnClientEvent:Connect(function(message)
	status.Text = message
end)

-- The assignment also requires remaining boost time in the HUD.
local boostLabel = make("TextLabel", gui, {
	Name="BoostCountdown", AnchorPoint=Vector2.new(0.5, 0),
	Position=UDim2.new(0.5, 0, 0, 137), Size=UDim2.fromOffset(260, 30),
	BackgroundColor3=Color3.fromRGB(70, 48, 105),
	TextColor3=Color3.new(1, 1, 1), TextSize=15,
	Visible=false
})
corner(boostLabel)

task.spawn(function()
	while gui.Parent do
		local remaining = math.max(0, (player:GetAttribute("BoostExpiresAt") or 0) - os.time())
		boostLabel.Visible = remaining > 0
		if remaining > 0 then
			boostLabel.Text = string.format("2x COINS: %02d:%02d", math.floor(remaining / 60), remaining % 60)
		end
		task.wait(1)
	end
end)


-- Sell Vouchers UI from step 5.4 (kept intact)
-- Paste at the BOTTOM of your EXISTING ShopClient (LocalScript).
-- Reuses its existing player, gui, make, corner, and ReplicatedStorage variables.

local redeemRemote = ReplicatedStorage:WaitForChild("RedeemVoucher")

local sellNowButton = make("TextButton", gui, {
	Name = "SellNowWithVoucher",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -12, 0, 201),
	Size = UDim2.fromOffset(130, 46),
	BackgroundColor3 = Color3.fromRGB(221, 156, 48),
	TextColor3 = Color3.new(1, 1, 1),
	Font = Enum.Font.GothamBold,
	TextScaled = true
})
corner(sellNowButton)

local function refreshVouchers()
	local n = player:GetAttribute("SellVouchers") or 0
	sellNowButton.Text = "SELL NOW (" .. n .. ")"
	sellNowButton.Active = n > 0
	sellNowButton.BackgroundColor3 = n > 0
		and Color3.fromRGB(221, 156, 48)
		or Color3.fromRGB(103, 105, 111)
end

sellNowButton.Activated:Connect(function()
	if player:GetAttribute("DataReady") ~= true then return end
	if (player:GetAttribute("SellVouchers") or 0) < 1 then return end
	redeemRemote:FireServer()
end)

redeemRemote.OnClientEvent:Connect(function(success, message)
	status.Text = message
	frame.Visible = true
	status.TextColor3 = success
		and Color3.fromRGB(110, 255, 150)
		or Color3.fromRGB(255, 180, 125)
end)

player:GetAttributeChangedSignal("SellVouchers"):Connect(refreshVouchers)
refreshVouchers()