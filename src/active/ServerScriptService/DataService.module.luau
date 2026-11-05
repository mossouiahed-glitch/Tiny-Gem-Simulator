
local DataStoreService = game:GetService("DataStoreService")

local DataService = {}

-- Separate test data from future live game data
DataService.Store = DataStoreService:GetDataStore(
	"TinyGem_Development_v1"
)

-- Default values for a brand-new player
DataService.DefaultData = {
	Coins = 0,
	BackpackLevel = 1,
	CaveUnlocked = false,
	SellVouchers = 0,
	BoostExpiresAt = 0
}

-- Create an independent copy for each player
function DataService.GetDefaultData()
	return table.clone(DataService.DefaultData)
end


-- Unique ID for this server session
local HttpService = game:GetService("HttpService")
local sessionId = HttpService:GenerateGUID(false)

-- A crashed server's lock can expire after 180 seconds.
-- Our future autosave system will refresh active locks.
local LOCK_TIMEOUT = 180

DataService.ActiveSessions = {}

function DataService.Load(player)

	local key = "Player_" .. player.UserId

	local success, savedData = pcall(function()

		return DataService.Store:UpdateAsync(key, function(oldData)

			-- Never overwrite an invalid existing record
			if oldData ~= nil and type(oldData) ~= "table" then
				return nil
			end

			-- Check for an existing session lock
			if oldData and oldData.SessionLock then
				local lock = oldData.SessionLock

				if type(lock) ~= "table"
					or type(lock.Id) ~= "string"
					or type(lock.Time) ~= "number" then
					return nil
				end

				if lock.Id ~= sessionId
					and os.time() - lock.Time < LOCK_TIMEOUT then
					return nil
				end
			end

			-- Reject malformed saved progression
			if oldData then
				for field, default in pairs(DataService.DefaultData) do
					local value = oldData[field]

					if value ~= nil then
						if type(value) ~= type(default) then
							return nil
						end

						if type(value) == "number"
							and (value < 0 or value ~= value
								or value == math.huge
								or value % 1 ~= 0) then
							return nil
						end
					end
				end
			end

			local data = oldData
				and table.clone(oldData)
				or DataService.GetDefaultData()

			-- Lock this record to our server
			data.SessionLock = {
				Id = sessionId,
				Time = os.time()
			}

			return data
		end)
	end)

	if not success or not savedData then
		warn("Could not load data for " .. player.Name)
		return nil
	end

	DataService.ActiveSessions[player] = true

	return savedData
end


-- Prevent overlapping saves for the same player
local savingNow = {}

function DataService.Save(player, releaseLock)

	-- Never save data that wasn't loaded successfully
	if not DataService.ActiveSessions[player] then
		warn("Save blocked: no active session for " .. player.Name)
		return false
	end

	-- Wait for any previous save to finish
	local waitStart = os.clock()

	while savingNow[player] do
		if os.clock() - waitStart > 10 then
			warn("Save timed out waiting for another save")
			return false
		end
		task.wait(0.1)
	end

	savingNow[player] = true

	-- Read the player's server-owned values
	local snapshot = {}

	for field, default in pairs(DataService.DefaultData) do
		local value = player:GetAttribute(field)

		if type(value) ~= type(default) then
			warn("Invalid or missing player data: " .. field)
			savingNow[player] = nil
			return false
		end

		if type(value) == "number" then
			if value < 0 or value ~= value
				or value == math.huge or value % 1 ~= 0 then

				warn("Invalid number in " .. field)
				savingNow[player] = nil
				return false
			end
		end

		snapshot[field] = value
	end

	-- Validate the backpack level
	if snapshot.BackpackLevel < 1
		or snapshot.BackpackLevel > 3 then

		warn("Invalid backpack level")
		savingNow[player] = nil
		return false
	end

	local key = "Player_" .. player.UserId

	local success, result = pcall(function()

		return DataService.Store:UpdateAsync(key, function(oldData)

			-- Only the server holding the lock may save
			if type(oldData) ~= "table"
				or type(oldData.SessionLock) ~= "table"
				or oldData.SessionLock.Id ~= sessionId then

				return nil
			end

			-- Preserve other stored fields
			local newData = table.clone(oldData)

			-- Update permanent progression
			for field, value in pairs(snapshot) do
				newData[field] = value
			end

			if releaseLock then
				-- Release on final successful save
				newData.SessionLock = nil
			else
				-- Refresh the current session lock
				newData.SessionLock = {
					Id = sessionId,
					Time = os.time()
				}
			end

			return newData
		end)
	end)

	savingNow[player] = nil

	if not success or result == nil then
		warn("Failed to save data for " .. player.Name)
		return false
	end

	if releaseLock then
		DataService.ActiveSessions[player] = nil
	end

	print("Data saved successfully for " .. player.Name)
	return true
end
-- STEP 5.2: Paste ABOVE the existing final "return DataService" line.
-- This function shares the savingNow lock with DataService.Save(),
-- so autosave cannot overwrite a purchase with an old snapshot.

local PRODUCT_COIN_PACK = 3724904088
local PRODUCT_DOUBLE_COINS = 3724905418
local PRODUCT_SELL_VOUCHERS = 3724907700

function DataService.ApplyReceipt(player, receipt)
	if not DataService.ActiveSessions[player]
		or player:GetAttribute("DataReady") ~= true then
		return false, false
	end

	local id = receipt.PurchaseId
	local productId = receipt.ProductId
	if type(id) ~= "string" or id == "" then
		return false, false
	end
	if productId ~= PRODUCT_COIN_PACK
		and productId ~= PRODUCT_DOUBLE_COINS
		and productId ~= PRODUCT_SELL_VOUCHERS then
		return false, false
	end

	-- Wait for an existing Save or receipt transaction.
	local start = os.clock()
	while savingNow[player] do
		if os.clock() - start > 15 then
			warn("Purchase is waiting too long for data access")
			return false, false
		end
		task.wait(0.1)
	end
	if not DataService.ActiveSessions[player]
		or player:GetAttribute("DataReady") ~= true then
		return false, false
	end
	savingNow[player] = true

	-- Capture all session progression. Carried crystals are intentionally absent.
	local snapshot = {}
	for field, default in pairs(DataService.DefaultData) do
		local value = player:GetAttribute(field)
		if type(value) ~= type(default) then
			savingNow[player] = nil
			return false, false
		end
		if type(value) == "number" and
			(value < 0 or value % 1 ~= 0 or value == math.huge) then
			savingNow[player] = nil
			return false, false
		end
		snapshot[field] = value
	end

	-- Called by UpdateAsync possibly more than once: don't award inside callback.

	player:SetAttribute("EconomyLocked", true)

local newlyGranted = false
	local success, saved = pcall(function()
		return DataService.Store:UpdateAsync("Player_" .. player.UserId,
			function(old)
				newlyGranted = false
				if type(old) ~= "table"
					or type(old.SessionLock) ~= "table"
					or old.SessionLock.Id ~= sessionId then
					return nil
				end

				if old.ProcessedReceipts ~= nil
					and type(old.ProcessedReceipts) ~= "table" then
					return nil
				end

				local receipts = old.ProcessedReceipts or {}
				if receipts[id] == true then
					return old -- Already granted; acknowledge without granting again.
				end

				local updated = table.clone(old)
				for field, value in pairs(snapshot) do
					updated[field] = value
				end

				if productId == PRODUCT_COIN_PACK then
					updated.Coins += 250
				elseif productId == PRODUCT_DOUBLE_COINS then
					updated.BoostExpiresAt =
						math.max(updated.BoostExpiresAt, os.time()) + 600
				elseif productId == PRODUCT_SELL_VOUCHERS then
					updated.SellVouchers += 3
				end

				updated.ProcessedReceipts = table.clone(receipts)
				updated.ProcessedReceipts[id] = true
				updated.SessionLock = {Id = sessionId, Time = os.time()}
				newlyGranted = true
				return updated
			end)
	end)


	if not success or type(saved) ~= "table"
		or type(saved.ProcessedReceipts) ~= "table"
		or saved.ProcessedReceipts[id] ~= true then

		warn("Purchase receipt save could not be confirmed: " .. id)

		-- Prevent a later autosave from overwriting
		-- a purchase that may already have been saved.
		DataService.ActiveSessions[player] = nil
		savingNow[player] = nil

		-- Leave the economy locked.
		if player.Parent then
			player:Kick("Purchase saving could not be confirmed. Please rejoin later.")
		end

		return false, false
	end


	if newlyGranted then
		-- Only update the player's current session AFTER durable storage succeeds.
		-- Add the benefit to the CURRENT attributes to avoid losing gameplay
		-- changes made while DataStoreService was responding.
		if productId == PRODUCT_COIN_PACK then
			player:SetAttribute("Coins", (player:GetAttribute("Coins") or 0) + 250)
		elseif productId == PRODUCT_DOUBLE_COINS then
			player:SetAttribute("BoostExpiresAt", math.max(
				player:GetAttribute("BoostExpiresAt") or 0,
				saved.BoostExpiresAt
				))
		elseif productId == PRODUCT_SELL_VOUCHERS then
			player:SetAttribute("SellVouchers", (player:GetAttribute("SellVouchers") or 0) + 3)
		end
	end


	player:SetAttribute("EconomyLocked", false)
	savingNow[player] = nil
	return true, newlyGranted

end
-- Paste this at the END of DataService, just ABOVE the final: return DataService
-- Reuses the existing savingNow and sessionId locals in DataService.

local voucherRequests = {}

function DataService.RedeemVoucher(player)
	if voucherRequests[player] then
		return false, "A voucher sale is already in progress."
	end
	voucherRequests[player] = true

	local function reject(message)
		voucherRequests[player] = nil
		return false, message
	end

	if not DataService.ActiveSessions[player]
		or player:GetAttribute("DataReady") ~= true then
		return reject("Your saved data is not ready.")
	end

	-- Share the data-store write lock with autosave and ProcessReceipt.
	local started = os.clock()
	while savingNow[player] do
		if os.clock() - started > 10 then
			return reject("Data is busy. Please try again.")
		end
		task.wait(0.1)
	end
	if not DataService.ActiveSessions[player]
		or player:GetAttribute("DataReady") ~= true then
		return reject("You are no longer in an active session.")
	end
	savingNow[player] = true
	player:SetAttribute("EconomyLocked", true)

	local savedCapacity = player:GetAttribute("BackpackCapacity")
	local function finish(success, message)
		-- Restore capacity, including the Game Pass bonus if owned.
		local level = player:GetAttribute("BackpackLevel")
		local capacities = {[1] = 10, [2] = 20, [3] = 35}
		if capacities[level] then
			local bonus = player:GetAttribute("HasBiggerBackpack") == true and 10 or 0
			player:SetAttribute("BackpackCapacity", capacities[level] + bonus)
		elseif type(savedCapacity) == "number" then
			player:SetAttribute("BackpackCapacity", savedCapacity)
		end
		player:SetAttribute("EconomyLocked", false)
		savingNow[player] = nil
		voucherRequests[player] = nil
		return success, message
	end

	local function validInteger(value)
		return type(value) == "number"
			and value >= 0 and value < math.huge and value % 1 == 0
	end

	local count = player:GetAttribute("CarriedCount")
	local carriedValue = player:GetAttribute("CarriedValue")
	local capacity = savedCapacity
	local snapshot = {}

	for field, default in pairs(DataService.DefaultData) do
		local value = player:GetAttribute(field)
		if type(value) ~= type(default) then
			return finish(false, "Invalid player data. Sale cancelled.")
		end
		if type(value) == "number" and not validInteger(value) then
			return finish(false, "Invalid player data. Sale cancelled.")
		end
		snapshot[field] = value
	end

	if not validInteger(count) or not validInteger(carriedValue)
		or not validInteger(capacity) or capacity < 1
		or count > capacity or count > 45 then
		return finish(false, "Invalid backpack state.")
	end
	if snapshot.SellVouchers < 1 then
		return finish(false, "You have no sell vouchers.")
	end
	if count == 0 then
		return finish(false, "Collect some crystals first.")
	end
	if carriedValue < count * 5 or carriedValue > count * 50 then
		return finish(false, "Invalid crystal values.")
	end
	if snapshot.Coins > 1000000000000 then
		return finish(false, "Coin balance exceeds supported range.")
	end

	-- Existing crystal scripts check count >= capacity. Temporarily make
	-- the backpack 'full' so it cannot change while UpdateAsync yields.
	-- Also add the EconomyLocked guards listed in the instructions.
	player:SetAttribute("BackpackCapacity", count)

	local multiplier = os.time() < snapshot.BoostExpiresAt and 2 or 1
	local reward = carriedValue * multiplier
	local key = "Player_" .. player.UserId

	local success, saved = pcall(function()
		return DataService.Store:UpdateAsync(key, function(old)
			if type(old) ~= "table" or type(old.SessionLock) ~= "table"
				or old.SessionLock.Id ~= sessionId then
				return nil
			end
			local newData = table.clone(old)
			for field, value in pairs(snapshot) do
				newData[field] = value
			end
			newData.Coins = snapshot.Coins + reward
			newData.SellVouchers = snapshot.SellVouchers - 1
			newData.SessionLock = {Id = sessionId, Time = os.time()}
			return newData
		end)
	end)

	if not success or type(saved) ~= "table" then
		warn("Voucher save failed or result uncertain for " .. player.Name)
		-- A failed response may have written remotely. Block further currency
		-- actions in this session rather than risking a duplicate redemption.
		player:SetAttribute("EconomyLocked", true)
		savingNow[player] = nil
		voucherRequests[player] = nil
		DataService.ActiveSessions[player] = nil
		player:Kick("Voucher saving could not be confirmed. Rejoin later.")
		return false, "Voucher save was not confirmed."
	end

	-- Successful durable update: apply the same delta to current attributes.
	player:SetAttribute("Coins", snapshot.Coins + reward)
	player:SetAttribute("SellVouchers", snapshot.SellVouchers - 1)
	player:SetAttribute("CarriedCount", 0)
	player:SetAttribute("CarriedValue", 0)
	return finish(true, "Sold for +" .. reward .. " coins! 1 voucher used.")
end
return DataService

