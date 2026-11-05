
local crystal = script.Parent
local prompt = crystal:WaitForChild("ProximityPrompt")

local respawnTime = 8
local available = false
local crystalValue = 15
local crystalType = "Purple"

-- Choose which crystal appears
local function spawnCrystal()

	local isGolden = math.random(1, 10) == 1

	if isGolden then
		crystalType = "Golden"
		crystalValue = 50
		crystal.Color = Color3.fromRGB(255, 200, 0)
	else
		crystalType = "Purple"
		crystalValue = 15
		crystal.Color = Color3.fromRGB(165, 65, 255)
	end

	prompt.ObjectText = crystalType .. " Crystal"
	crystal.Transparency = 0
	available = true
	prompt.Enabled = true

	print("Rare spawn created: " .. crystalType)
end

-- Create the first crystal
prompt.Enabled = false
crystal.Transparency = 1
spawnCrystal()

-- Handle collection
prompt.Triggered:Connect(function(player)

	if not available then
		return
	end

	-- Only players with cave access can collect
	if player:GetAttribute("CaveUnlocked") ~= true then
		return
	end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")

	if not root then
		return
	end

	-- Check distance on the server
	local distance = (root.Position - crystal.Position).Magnitude

	if distance > prompt.MaxActivationDistance then
		return
	end

	-- Check backpack
	local count = player:GetAttribute("CarriedCount") or 0
	local capacity = player:GetAttribute("BackpackCapacity") or 10
	local value = player:GetAttribute("CarriedValue") or 0

	if type(count) ~= "number"
		or type(capacity) ~= "number"
		or type(value) ~= "number"
		or count < 0 or capacity <= 0 or value < 0
		or count % 1 ~= 0 or capacity % 1 ~= 0
		or value % 1 ~= 0
		or count >= capacity then
		return
	end

	-- Claim the spawn
	available = false
	prompt.Enabled = false
	crystal.Transparency = 1

	-- Add to backpack, not directly to coins
	player:SetAttribute("CarriedCount", count + 1)
	player:SetAttribute("CarriedValue", value + crystalValue)

	print(player.Name .. " collected " .. crystalType
		.. " crystal, worth " .. crystalValue)

	-- Respawn after 8 seconds
	task.delay(respawnTime, function()
		if crystal.Parent then
			spawnCrystal()
		end
	end)
end)
