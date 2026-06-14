local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local PlayerDataStore = DataStoreService:GetDataStore("PlayerData_v4")

local DataService = {}

-- Active player data stored in memory
DataService.SessionData = {}

-- Default data for new players
local DEFAULT_DATA = {
	Cash = GameConfig.StartingCash,
	Shards = 0,
	Luck = 0,
	Inventory = {
		SimpleTicket = 0,
		RareTicket = 0,
		GoldenTicket = 0
	}
}

-- Load data from DataStore
local function loadData(player: Player)
	local userId = tostring(player.UserId)
	local success, result = pcall(function()
		return PlayerDataStore:GetAsync(userId)
	end)

	if success then
		DataService.SessionData[userId] = result or table.clone(DEFAULT_DATA)

		local session = DataService.SessionData[userId]
		if session.Shards == nil then session.Shards = 0 end
		if session.Luck == nil then session.Luck = 0 end
		if not session.Inventory then session.Inventory = table.clone(DEFAULT_DATA.Inventory) end
		for k, v in pairs(DEFAULT_DATA.Inventory) do
			if session.Inventory[k] == nil then
				session.Inventory[k] = v
			end
		end
	else
		warn("Failed to load data for player " .. player.Name .. ": " .. tostring(result))
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
local function setupPlayerObjects(player: Player)
	local userId = tostring(player.UserId)
	local data = DataService.SessionData[userId]

	if not data then return end

	-- Leaderstats
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

	local luck = Instance.new("NumberValue")
	luck.Name = "Luck"
	luck.Value = data.Luck
	luck.Parent = leaderstats

	-- Inventory Folder
	local inventory = Instance.new("Folder")
	inventory.Name = "Inventory"
	inventory.Parent = player

	for ticketName, amount in pairs(data.Inventory) do
		local val = Instance.new("IntValue")
		val.Name = ticketName
		val.Value = amount
		val.Parent = inventory

		val.Changed:Connect(function(newValue)
			if DataService.SessionData[userId] then
				DataService.SessionData[userId].Inventory[ticketName] = newValue
			end
		end)
	end

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

	luck.Changed:Connect(function(newValue)
		if DataService.SessionData[userId] then
			DataService.SessionData[userId].Luck = newValue
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
		setupPlayerObjects(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		saveData(player)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			loadData(player)
			setupPlayerObjects(player)
		end)
	end

	game:BindToClose(function()
		for _, player in ipairs(Players:GetPlayers()) do
			task.spawn(saveData, player)
		end
		task.wait(2)
	end)
end

DataService.Init()

return DataService
