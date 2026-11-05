
local portal = script.Parent
local prompt = portal:WaitForChild("ProximityPrompt")

local spawnPoint = workspace:WaitForChild("SpawnLocation")

prompt.Triggered:Connect(function(player)

	-- Find the player's character
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	if not root or not humanoid or humanoid.Health <= 0 then
		return
	end

	-- Verify the player is near the portal
	local distance = (root.Position - portal.Position).Magnitude

	if distance > prompt.MaxActivationDistance + 2 then
		return
	end

	-- Calculate a safe position above the spawn point
	local destination = spawnPoint.Position
		+ Vector3.new(0, spawnPoint.Size.Y / 2 + 4, 0)

	-- Return the player to the Starting Area
	character:PivotTo(CFrame.new(destination))

	print(player.Name .. " returned to Starting Area!")

end)
