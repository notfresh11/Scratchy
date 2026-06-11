local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Correct require paths based on Rojo mapping
local Shared = ReplicatedStorage:WaitForChild("Shared")
local LootTable = require(Shared.LootTable)

local ScratchService = {}
local DataService -- Will be required in Init to avoid circular dependencies if any, or just use script.Parent

-- Setup RemoteEvents and RemoteFunctions
local function setupCommunication()
	local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
	if not eventsFolder then
		eventsFolder = Instance.new("Folder")
		eventsFolder.Name = "Events"
		eventsFolder.Parent = ReplicatedStorage
	end

	local scratchRequest = eventsFolder:FindFirstChild("ScratchRequest")
	if not scratchRequest then
		scratchRequest = Instance.new("RemoteFunction")
		scratchRequest.Name = "ScratchRequest"
		scratchRequest.Parent = eventsFolder
	end

	return scratchRequest
end

local scratchRequest = setupCommunication()

-- Handle scratch card purchase requests
local function onScratchInvoke(player: Player, tierName: string)
	-- 1. Get player data
	local playerData = DataService.GetPlayerData(player)
	if not playerData then return {Success = false, Error = "Data not loaded"} end

	-- 2. Validate tier
	local tier = LootTable.Tiers[tierName]
	if not tier then return {Success = false, Error = "Invalid tier"} end

	-- 3. Check if player has enough Cash
	local leaderstats = player:FindFirstChild("leaderstats")
	local cashValue = leaderstats and leaderstats:FindFirstChild("Cash")

	if not cashValue or cashValue.Value < tier.Cost then
		return {Success = false, Error = "Not enough Cash"}
	end

	-- 4. Deduct cost
	cashValue.Value -= tier.Cost

	-- 5. Roll for reward
	local baseReward = LootTable.Roll(tierName)
	if baseReward == nil then return {Success = false, Error = "Roll failed"} end

	-- 6. Apply Shard multiplier
	-- Formula: FinalReward = math.round(BaseReward * (1 + (Shards * 0.1)))
	local multiplier = 1 + (playerData.Shards * 0.1)
	local finalReward = math.round(baseReward * multiplier)

	-- 7. Grant reward
	cashValue.Value += finalReward

	-- 8. Return result to client
	return {
		Success = true,
		BaseReward = baseReward,
		FinalReward = finalReward,
		Tier = tierName
	}
end

function ScratchService.Init()
	DataService = require(script.Parent.DataService)
	scratchRequest.OnServerInvoke = onScratchInvoke
end

ScratchService.Init()

return ScratchService
