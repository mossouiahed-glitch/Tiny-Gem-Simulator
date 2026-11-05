
local Players = game:GetService("Players")

Players.CharacterAutoLoads = false

-- Connect to the DataService we already created
local DataService = require(script.Parent:WaitForChild("DataService"))

local AUTOSAVE_INTERVAL = 60

-- Backpack capacities from the assignment
local capacities = {
	[1] = 10,
	[2] = 20,
	[3] = 35
}

-- Apply the player's loaded progression
local function setupPlayer(player, data)

	local level = data.BackpackLevel

	if type(level) ~= "number" or not capacities[level] then
		return false
	end

	-- Restore permanent player data
	for field, default in pairs(DataService.DefaultData) do

		local value = data[field]

		if value == nil then
			value = default
		end

		if type(value) ~= type(default) then
			return false
		end

		if type(value) == "number" then
			if value < 0 or value ~= value
				or value == math.huge
				or value % 1 ~= 0 then
				return false
			end
		end

		player:SetAttribute(field, value)
	end

	-- Crystals are NOT saved between sessions
	player:SetAttribute("CarriedCount", 0)
	player:SetAttribute("CarriedValue", 0)

	-- Calculate backpack capacity
	player:SetAttribute(
		"BackpackCapacity",
		capacities[level]
	)

	-- Player data is ready
	player:SetAttribute("DataReady", true)

	return true
end

-- Retry a failed save before giving up
local function saveWithRetry(player, releaseLock)

	for attempt = 1, 3 do

		if DataService.Save(player, releaseLock) then
			return true
		end

		if attempt < 3 then
			task.wait(2)
		end
	end

	warn("WARNING: Progress could not be saved for "
		.. player.Name)

	return false
end

-- When a player joins
local function onPlayerAdded(player)

	-- Respawn safely after the player's data is loaded
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")

		humanoid.Died:Connect(function()
			task.wait(5)

			if player.Parent == Players
				and player:GetAttribute("DataReady") == true then

				local success, err = pcall(function()
					player:LoadCharacterAsync()
				end)

				if not success then
					warn("Respawn failed: " .. tostring(err))
				end
			end
		end)
	end)

	player:SetAttribute("DataReady", false)

	local data = DataService.Load(player)

	if not data then
		player:Kick("Could not load your progress. Please rejoin.")
		return
	end

	if not setupPlayer(player, data) then
		warn("Invalid saved progression for " .. player.Name)
		player:Kick("Your progression could not be loaded safely.")
		return
	end

	print("Player data loaded: " .. player.Name)

	-- Spawn only after progression has loaded safely
	if player.Parent == Players then
		local success, err = pcall(function()
			player:LoadCharacterAsync()
		end)

		if not success then
			warn("Character spawn failed: " .. tostring(err))
			player:Kick("Unable to spawn. Please rejoin.")
		end
	end

	-- Handle leaving during a slow load
	if player.Parent ~= Players
		and DataService.ActiveSessions[player] then
		saveWithRetry(player, true)
	end
end

-- When a player leaves
Players.PlayerRemoving:Connect(function(player)

	if DataService.ActiveSessions[player]
		and player:GetAttribute("DataReady") == true then

		saveWithRetry(player, true)
	end
end)

-- Connect players joining
Players.PlayerAdded:Connect(onPlayerAdded)

for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

-- Periodically save active players
task.spawn(function()

	while task.wait(AUTOSAVE_INTERVAL) do

		for _, player in Players:GetPlayers() do

			if DataService.ActiveSessions[player]
				and player:GetAttribute("DataReady") == true then

				task.spawn(function()
					DataService.Save(player, false)
				end)
			end
		end
	end
end)

-- Attempt a final save when the server closes
game:BindToClose(function()

	local pending = 0

	for _, player in Players:GetPlayers() do

		if DataService.ActiveSessions[player]
			and player:GetAttribute("DataReady") == true then

			pending += 1

			task.spawn(function()

				saveWithRetry(player, true)

				pending -= 1
			end)
		end
	end

	local startTime = os.clock()

	while pending > 0 and os.clock() - startTime < 25 do
		task.wait(0.1)
	end
end)
