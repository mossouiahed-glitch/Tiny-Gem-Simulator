
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local label = script.Parent

-- Update the coin counter
local function updateCoins()
	local coins = player:GetAttribute("Coins") or 0

	label.Text = "COINS: " .. coins
end

-- Update whenever the coin balance changes
player:GetAttributeChangedSignal("Coins"):Connect(updateCoins)

-- Show the starting balance
updateCoins()

