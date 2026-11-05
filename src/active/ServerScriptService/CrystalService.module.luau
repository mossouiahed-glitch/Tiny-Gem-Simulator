
local Players = game:GetService("Players")

local CrystalService = {}

local RESPAWN_TIME = 8

local types = {
	Blue = {
		value = 5,
		color = Color3.fromRGB(40, 160, 255)
	},
	Purple = {
		value = 15,
		color = Color3.fromRGB(165, 65, 255)
	},
	Golden = {
		value = 50,
		color = Color3.fromRGB(255, 200, 0)
	}
}

local function validInteger(value)
	return type(value) == "number"
		and value >= 0
		and value < math.huge
		and value % 1 == 0
end

local function registerCrystal(part, crystalType, rare)

	if not part or not part:IsA("BasePart") then
		warn("Crystal spawn missing or invalid")
		return
	end

	local prompt = part:FindFirstChildOfClass("ProximityPrompt")

	if not prompt then
		warn("Missing ProximityPrompt: " .. part.Name)
		return
	end

	local available = false
	local currentType = crystalType

	local function spawn()

		if rare then
			currentType = math.random(1, 10) == 1
				and "Golden"
				or "Purple"
		end

		part.Color = types[currentType].color
		part.Transparency = 0

		prompt.ObjectText = currentType .. " Crystal"
		prompt.Enabled = true

		available = true
	end

	prompt.Enabled = false

	prompt.Triggered:Connect(function(player)

		if not available
			or player.Parent ~= Players
			or player:GetAttribute("DataReady") ~= true
			or player:GetAttribute("EconomyLocked") == true then
			return
		end

		-- Only unlocked players can use cave crystals
		if crystalType ~= "Blue"
			and player:GetAttribute("CaveUnlocked") ~= true then
			return
		end

		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")

		if not root or not humanoid or humanoid.Health <= 0 then
			return
		end

		if (root.Position - part.Position).Magnitude
			> prompt.MaxActivationDistance + 2 then
			return
		end

		local count = player:GetAttribute("CarriedCount")
		local capacity = player:GetAttribute("BackpackCapacity")
		local value = player:GetAttribute("CarriedValue")

		if not validInteger(count)
			or not validInteger(capacity)
			or not validInteger(value)
			or capacity < 1 or capacity > 45
			or count >= capacity
			or value > count * 50 then
			return
		end

		-- Claim the crystal immediately
		available = false
		prompt.Enabled = false
		part.Transparency = 1

		-- Add to backpack, not directly to coins
		player:SetAttribute("CarriedCount", count + 1)
		player:SetAttribute(
			"CarriedValue",
			value + types[currentType].value
		)

		task.delay(RESPAWN_TIME, function()
			if part.Parent then
				spawn()
			end
		end)
	end)

	spawn()
end

function CrystalService.Start()

	for i = 1, 6 do
		registerCrystal(
			workspace:FindFirstChild("BlueCrystal" .. i),
			"Blue",
			false
		)
	end

	for i = 1, 4 do
		registerCrystal(
			workspace:FindFirstChild("PurpleCrystal" .. i),
			"Purple",
			false
		)
	end

	registerCrystal(
		workspace:FindFirstChild("CaveRareSpawn1"),
		"Purple",
		true
	)
end

return CrystalService
