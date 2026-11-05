
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Create our feedback interface
local gui = Instance.new("ScreenGui")
gui.Name = "GameFeedbackUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 20
gui.Parent = playerGui

-- Create sounds
local function makeSound(soundId)
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = 0.4
	sound.Parent = SoundService
	return sound
end

local pickupSound = makeSound(
	"rbxasset://sounds/electronicpingshort.wav"
)

local sellSound = makeSound(
	"rbxasset://sounds/button.wav"
)

local unlockSound = makeSound(
	"rbxasset://sounds/victory.wav"
)

-- Floating notification animation
local function showPopup(message, color)

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.8, 0, 0, 50)
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.fromScale(0.5, 0.38)
	label.BackgroundColor3 = Color3.fromRGB(30, 40, 65)
	label.BackgroundTransparency = 0.2
	label.Text = message
	label.TextColor3 = color
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = gui

	local constraint = Instance.new("UISizeConstraint")
	constraint.MaxSize = Vector2.new(420, 50)
	constraint.Parent = label

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = label

	local tween = TweenService:Create(
		label,
		TweenInfo.new(0.9, Enum.EasingStyle.Quad),
		{
			Position = UDim2.fromScale(0.5, 0.28),
			TextTransparency = 1,
			BackgroundTransparency = 1
		}
	)

	tween:Play()

	tween.Completed:Connect(function()
		label:Destroy()
	end)
end

-- Create a glowing pickup animation
local function pickupEffect()

	local character = player.Character
	local root = character and character:FindFirstChild(
		"HumanoidRootPart"
	)

	if not root then return end

	local sparkle = Instance.new("Part")
	sparkle.Shape = Enum.PartType.Ball
	sparkle.Material = Enum.Material.Neon
	sparkle.Color = Color3.fromRGB(75, 180, 255)
	sparkle.Size = Vector3.new(0.8, 0.8, 0.8)
	sparkle.Anchored = true
	sparkle.CanCollide = false
	sparkle.CanTouch = false
	sparkle.CanQuery = false
	sparkle.Position = root.Position + Vector3.new(0, 3, 0)
	sparkle.Parent = workspace

	local tween = TweenService:Create(
		sparkle,
		TweenInfo.new(0.6),
		{
			Position = sparkle.Position + Vector3.new(0, 2, 0),
			Size = Vector3.new(0.1, 0.1, 0.1),
			Transparency = 1
		}
	)

	tween:Play()

	tween.Completed:Connect(function()
		sparkle:Destroy()
	end)
end

-- Detect validated crystal collection
local previousCount = player:GetAttribute("CarriedCount") or 0

player:GetAttributeChangedSignal("CarriedCount"):Connect(function()
	local count = player:GetAttribute("CarriedCount") or 0

	if player:GetAttribute("DataReady") == true
		and count > previousCount then

		SoundService:PlayLocalSound(pickupSound)
		pickupEffect()
		showPopup("+1 CRYSTAL!", Color3.fromRGB(90, 210, 255))
	end

	previousCount = count
end)

-- Detect selling reward messages
player:GetAttributeChangedSignal("SaleAnnouncement"):Connect(function()

	local message = player:GetAttribute("SaleAnnouncement")

	if type(message) ~= "string" then return end

	local reward = tonumber(message:match(":(%d+)$"))

	if reward and reward > 0 then
		SoundService:PlayLocalSound(sellSound)
		showPopup(
			"+" .. reward .. " COINS!",
			Color3.fromRGB(255, 215, 70)
		)
	end
end)

-- Detect Crystal Cave unlocking
local caveWasUnlocked = player:GetAttribute("CaveUnlocked") == true

player:GetAttributeChangedSignal("CaveUnlocked"):Connect(function()
	local unlocked = player:GetAttribute("CaveUnlocked") == true

	if unlocked and not caveWasUnlocked
		and player:GetAttribute("DataReady") == true then

		SoundService:PlayLocalSound(unlockSound)
		showPopup(
			"CRYSTAL CAVE UNLOCKED!",
			Color3.fromRGB(195, 120, 255)
		)
	end

	caveWasUnlocked = unlocked
end)

-- Detect backpack upgrades
local previousLevel = player:GetAttribute("BackpackLevel") or 1

player:GetAttributeChangedSignal("BackpackLevel"):Connect(function()
	local level = player:GetAttribute("BackpackLevel") or 1

	if player:GetAttribute("DataReady") == true
		and level > previousLevel then

		showPopup(
			"BACKPACK LEVEL " .. level .. "!",
			Color3.fromRGB(120, 255, 160)
		)
	end

	previousLevel = level
end)

-- Double Coins countdown
local boostLabel = Instance.new("TextLabel")
boostLabel.Size = UDim2.new(0.8, 0, 0, 35)
boostLabel.AnchorPoint = Vector2.new(0.5, 0)
boostLabel.Position = UDim2.new(0.5, 0, 0, 135)
boostLabel.BackgroundColor3 = Color3.fromRGB(75, 45, 130)
boostLabel.TextColor3 = Color3.new(1, 1, 1)
boostLabel.TextScaled = true
boostLabel.Font = Enum.Font.GothamBold
boostLabel.Visible = false
boostLabel.Parent = gui

local boostConstraint = Instance.new("UISizeConstraint")
boostConstraint.MaxSize = Vector2.new(300, 35)
boostConstraint.Parent = boostLabel

local boostCorner = Instance.new("UICorner")
boostCorner.CornerRadius = UDim.new(0, 10)
boostCorner.Parent = boostLabel

task.spawn(function()
	while gui.Parent do
		local expiresAt = player:GetAttribute("BoostExpiresAt") or 0
		local remaining = math.max(0, expiresAt - os.time())

		boostLabel.Visible = remaining > 0

		if remaining > 0 then
			local minutes = math.floor(remaining / 60)
			local seconds = remaining % 60

			boostLabel.Text = string.format(
				"2X COINS  %02d:%02d",
				minutes,
				seconds
			)
		end

		task.wait(1)
	end
end)
