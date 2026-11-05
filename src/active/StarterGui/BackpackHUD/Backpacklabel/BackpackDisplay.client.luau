
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local label = script.Parent

local function updateBackpack()
	local count = player:GetAttribute("CarriedCount") or 0
	local capacity = player:GetAttribute("BackpackCapacity") or 10

	if count >= capacity then
		label.Text = "BACKPACK FULL! SELL YOUR CRYSTALS!"
	else
		label.Text = "BACKPACK: " .. count .. "/" .. capacity
	end
end

player:GetAttributeChangedSignal("CarriedCount"):Connect(updateBackpack)
player:GetAttributeChangedSignal("BackpackCapacity"):Connect(updateBackpack)

updateBackpack()
