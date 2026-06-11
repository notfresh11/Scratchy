local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PrestigeService = {}
local DataService

-- Configuration
local PRESTIGE_THRESHOLD = 10000

-- Setup RemoteFunction
local function setupCommunication()
	local eventsFolder = ReplicatedStorage:WaitForChild("Events")

	local prestigeRequest = eventsFolder:FindFirstChild("PrestigeRequest")
	if not prestigeRequest then
		prestigeRequest = Instance.new("RemoteFunction")
		prestigeRequest.Name = "PrestigeRequest"
		prestigeRequest.Parent = eventsFolder
	end

	return prestigeRequest
end

local prestigeRequest = setupCommunication()

-- Handle prestige requests
local function onPrestigeInvoke(player: Player)
	local playerData = DataService.GetPlayerData(player)
	if not playerData then return {Success = false, Error = "Data not loaded"} end

	local leaderstats = player:FindFirstChild("leaderstats")
	local cashValue = leaderstats and leaderstats:FindFirstChild("Cash")
	local shardsValue = leaderstats and leaderstats:FindFirstChild("Shards")

	if not cashValue or not shardsValue then
		return {Success = false, Error = "Stats not found"}
	end

	-- Check threshold
	if cashValue.Value < PRESTIGE_THRESHOLD then
		return {Success = false, Error = "Not enough Cash (Need " .. PRESTIGE_THRESHOLD .. ")"}
	end

	-- Apply prestige
	cashValue.Value = 0
	shardsValue.Value += 1

	-- Manually sync session data for immediate consistency
	playerData.Cash = cashValue.Value
	playerData.Shards = shardsValue.Value

	return {
		Success = true,
		NewShards = shardsValue.Value
	}
end

function PrestigeService.Init()
	DataService = require(script.Parent.DataService)
	prestigeRequest.OnServerInvoke = onPrestigeInvoke
end

PrestigeService.Init()

return PrestigeService
