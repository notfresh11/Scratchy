local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local DataService

local TicketService = {}

-- Session tracking for squares
local playerSessions = {}

-- Setup RemoteEvents and RemoteFunctions
local function setupCommunication()
	local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
	if not eventsFolder then
		eventsFolder = Instance.new("Folder")
		eventsFolder.Name = "Events"
		eventsFolder.Parent = ReplicatedStorage
	end

	local buyTicket = eventsFolder:FindFirstChild("BuyTicketEvent")
	if not buyTicket then
		buyTicket = Instance.new("RemoteFunction")
		buyTicket.Name = "BuyTicketEvent"
		buyTicket.Parent = eventsFolder
	end

	local revealSquare = eventsFolder:FindFirstChild("RevealSquareEvent")
	if not revealSquare then
		revealSquare = Instance.new("RemoteEvent")
		revealSquare.Name = "RevealSquareEvent"
		revealSquare.Parent = eventsFolder
	end

	local getSession = eventsFolder:FindFirstChild("GetScratchSession")
	if not getSession then
		getSession = Instance.new("RemoteFunction")
		getSession.Name = "GetScratchSession"
		getSession.Parent = eventsFolder
	end

	return buyTicket, revealSquare, getSession
end

local buyTicketFunc, revealSquareEvent, getSessionFunc = setupCommunication()

-- BUY TICKET
local function onBuyTicket(player: Player, ticketName: string)
	local config = GameConfig.Tickets[ticketName]
	if not config then return {Success = false, Error = "Invalid Ticket"} end

	local leaderstats = player:FindFirstChild("leaderstats")
	local cashValue = leaderstats and leaderstats:FindFirstChild("Cash")

	if not cashValue or cashValue.Value < config.Cost then
		return {Success = false, Error = "Not enough Cash"}
	end

	local inventory = player:FindFirstChild("Inventory")
	local ticketValue = inventory and inventory:FindFirstChild(ticketName .. "Ticket")

	if not ticketValue then return {Success = false, Error = "Inventory Error"} end

	-- Deduct and Add
	cashValue.Value -= config.Cost
	ticketValue.Value += 1

	return {Success = true}
end

-- GET SESSION
local function onGetSession(player: Player, ticketName: string)
	local userId = tostring(player.UserId)
	if playerSessions[userId] and playerSessions[userId][ticketName] then
		return playerSessions[userId][ticketName]
	end
	return nil
end

-- REVEAL SQUARE
local function onRevealSquare(player: Player, ticketName: string, squareIndex: number)
	local config = GameConfig.Tickets[ticketName]
	if not config then return end

	local userId = tostring(player.UserId)
	local inventory = player:FindFirstChild("Inventory")
	local ticketValue = inventory and inventory:FindFirstChild(ticketName .. "Ticket")

	-- Check if session already exists
	if not (playerSessions[userId] and playerSessions[userId][ticketName]) then
		-- No active session, check if player has a ticket to start one
		if not ticketValue or ticketValue.Value <= 0 then return end

		-- START SESSION & CONSUME TICKET
		if not playerSessions[userId] then playerSessions[userId] = {} end
		playerSessions[userId][ticketName] = {}
		ticketValue.Value -= 1
		print("Ticket consumed for " .. player.Name .. " (Started Scratching " .. ticketName .. ")")
	end

	local session = playerSessions[userId][ticketName]

	-- If square already revealed, resend result (idempotency)
	if session[squareIndex] ~= nil then
		revealSquareEvent:FireClient(player, ticketName, squareIndex, session[squareIndex])
		return
	end

	-- RNG Logic
	local isMatch = math.random() <= config.WinChancePerSquare
	session[squareIndex] = isMatch
	revealSquareEvent:FireClient(player, ticketName, squareIndex, isMatch)

	-- Check for reward
	local revealedCount = 0
	local matchesCount = 0
	for i = 1, 3 do
		if session[i] ~= nil then
			revealedCount += 1
			if session[i] == true then
				matchesCount += 1
			end
		end
	end

	if revealedCount == 3 then
		local reward = 0
		if matchesCount == 3 then
			reward = config.Rewards.Jackpot
		elseif matchesCount == 2 then
			reward = config.Rewards.Medium
		end

		if reward > 0 then
			local leaderstats = player:FindFirstChild("leaderstats")
			local cashValue = leaderstats and leaderstats:FindFirstChild("Cash")
			if cashValue then
				cashValue.Value += reward
			end
		end

		-- Clear Session
		playerSessions[userId][ticketName] = nil
	end
end

function TicketService.Init()
	DataService = require(script.Parent.DataService)

	buyTicketFunc.OnServerInvoke = onBuyTicket
	getSessionFunc.OnServerInvoke = onGetSession
	revealSquareEvent.OnServerEvent:Connect(onRevealSquare)

	-- CLEANUP MEMORY LEAK
	Players.PlayerRemoving:Connect(function(player)
		playerSessions[tostring(player.UserId)] = nil
	end)
end

TicketService.Init()

return TicketService
