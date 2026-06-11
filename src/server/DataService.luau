local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local PlayerDataStore = DataStoreService:GetDataStore("PlayerData_v1")

local DataService = {}

-- Active player data stored in memory
DataService.SessionData = {}

-- Default data for new players
local DEFAULT_DATA = {
	Cash = 0,
	Shards = 0
}

-- Load data from DataStore
local function loadData(player: Player)
	local userId = tostring(player.UserId)
	local success, result = pcall(function()
		return PlayerDataStore:GetAsync(userId)
	end)

	if success then
		DataService.SessionData[userId] = result or table.clone(DEFAULT_DATA)
	else
		warn("Failed to load data for player " .. player.Name .. ": " .. tostring(result))
		-- Optional: Kick player if data fails to load to prevent data loss or overwriting
		player:Kick("Data failed to load. Please rejoin.")
	end
end

-- Save data to DataStore
local function saveData(player: Player)
	local userId = tostring(player.UserId)
	local data = DataService.SessionData[userId]

	if data then
		local success, result = pcall(function()
			PlayerDataStore:SetAsync(userId, data)
		end)

		if not success then
			warn("Failed to save data for player " .. player.Name .. ": " .. tostring(result))
		end

		DataService.SessionData[userId] = nil
	end
end

-- Setup leaderstats and values
local function setupLeaderstats(player: Player)
	local userId = tostring(player.UserId)
	local data = DataService.SessionData[userId]

	if not data then return end

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local cash = Instance.new("NumberValue")
	cash.Name = "Cash"
	cash.Value = data.Cash
	cash.Parent = leaderstats

	local shards = Instance.new("NumberValue")
	shards.Name = "Shards"
	shards.Value = data.Shards
	shards.Parent = leaderstats

	-- Sync internal data when leaderstats change
	cash.Changed:Connect(function(newValue)
		if DataService.SessionData[userId] then
			DataService.SessionData[userId].Cash = newValue
		end
	end)

	shards.Changed:Connect(function(newValue)
		if DataService.SessionData[userId] then
			DataService.SessionData[userId].Shards = newValue
		end
	end)
end

-- Public method to get a player's current data
function DataService.GetPlayerData(player: Player)
	return DataService.SessionData[tostring(player.UserId)]
end

-- Initialization
function DataService.Init()
	Players.PlayerAdded:Connect(function(player)
		loadData(player)
		setupLeaderstats(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		saveData(player)
	end)

	-- Handle existing players (for Studio testing / reloads)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			loadData(player)
			setupLeaderstats(player)
		end)
	end

	-- Bind To Close to ensure data saves on server shutdown
	game:BindToClose(function()
		for _, player in ipairs(Players:GetPlayers()) do
			task.spawn(saveData, player)
		end
		-- Wait for all tasks to complete or timeout
		task.wait(2)
	end)
end

DataService.Init()

return DataService
