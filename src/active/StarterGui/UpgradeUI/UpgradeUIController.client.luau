
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local gui = script.Parent
local remote = ReplicatedStorage:WaitForChild("UpgradeAction")
local prompt = workspace:WaitForChild("UpgradeStation"):WaitForChild("ProximityPrompt")

gui.ResetOnSpawn = false

local function create(class, parent, properties)
	local object = Instance.new(class)

	for property, value in pairs(properties) do
		object[property] = value
	end

	object.Parent = parent
	return object
end

local function round(object)
	create("UICorner", object, {
		CornerRadius = UDim.new(0, 12)
	})
end

-- Main window
local frame = create("Frame", gui, {
	Name = "UpgradePanel",
	Size = UDim2.new(0.9, 0, 0, 245),
	Position = UDim2.fromScale(0.5, 0.5),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundColor3 = Color3.fromRGB(40, 49, 76),
	Visible = false
})
round(frame)

create("UISizeConstraint", frame, {
	MaxSize = Vector2.new(400, 245)
})

-- Window title
create("TextLabel", frame, {
	Size = UDim2.new(1, -70, 0, 40),
	Position = UDim2.fromOffset(15, 10),
	BackgroundTransparency = 1,
	Text = "BACKPACK UPGRADES",
	TextColor3 = Color3.new(1, 1, 1),
	TextScaled = true,
	Font = Enum.Font.GothamBold
})

-- Close button
local close = create("TextButton", frame, {
	Size = UDim2.fromOffset(35, 35),
	Position = UDim2.new(1, -45, 0, 12),
	BackgroundColor3 = Color3.fromRGB(175, 65, 75),
	Text = "X",
	TextColor3 = Color3.new(1, 1, 1),
	TextSize = 20
})
round(close)

-- Upgrade details
local info = create("TextLabel", frame, {
	Size = UDim2.new(1, -30, 0, 85),
	Position = UDim2.fromOffset(15, 55),
	BackgroundColor3 = Color3.fromRGB(29, 37, 59),
	TextColor3 = Color3.new(1, 1, 1),
	TextSize = 17,
	TextWrapped = true,
	Font = Enum.Font.Gotham
})
round(info)

-- Message after purchase
local status = create("TextLabel", frame, {
	Size = UDim2.new(1, -30, 0, 25),
	Position = UDim2.fromOffset(15, 145),
	BackgroundTransparency = 1,
	Text = "",
	TextColor3 = Color3.fromRGB(255, 215, 100),
	TextSize = 15
})

-- Purchase button
local button = create("TextButton", frame, {
	Size = UDim2.new(1, -30, 0, 50),
	Position = UDim2.fromOffset(15, 180),
	BackgroundColor3 = Color3.fromRGB(139, 93, 225),
	TextColor3 = Color3.new(1, 1, 1),
	TextSize = 19,
	Font = Enum.Font.GothamBold,
	Text = "UPGRADE"
})
round(button)

local upgrades = {
	[1] = {cost = 100, capacity = 20},
	[2] = {cost = 350, capacity = 35}
}

local capacities = {[1] = 10, [2] = 20, [3] = 35}

local function refresh()
	local level = player:GetAttribute("BackpackLevel") or 1
	local coins = player:GetAttribute("Coins") or 0
	local nextUpgrade = upgrades[level]

	if not nextUpgrade then
		info.Text = "Level 3 - 35 slots\nMaximum upgrade reached!"
		button.Text = "MAX LEVEL"
		return
	end

	info.Text = "Level " .. level .. " - " .. capacities[level]
		.. " slots\nNext: Level " .. (level + 1)
		.. " - " .. nextUpgrade.capacity
		.. " slots\nCost: " .. nextUpgrade.cost
		.. " Coins | You have: " .. coins

	button.Text = "UPGRADE BACKPACK"
end

-- Open window when pressing E at the station
prompt.Triggered:Connect(function()
	refresh()
	status.Text = ""
	frame.Visible = true
end)

close.Activated:Connect(function()
	frame.Visible = false
end)

-- Ask the server to purchase the upgrade
button.Activated:Connect(function()
	remote:FireServer()
end)

-- Show server response
remote.OnClientEvent:Connect(function(success, message)
	status.Text = message
	status.TextColor3 = success
		and Color3.fromRGB(100, 255, 140)
		or Color3.fromRGB(255, 190, 100)

	refresh()
end)

player:GetAttributeChangedSignal("Coins"):Connect(refresh)
player:GetAttributeChangedSignal("BackpackLevel"):Connect(refresh)
