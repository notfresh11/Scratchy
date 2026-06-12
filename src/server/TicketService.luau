local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local DataService

local TicketService = {}

-- Session tracking for squares: [userId][ticketName] = { [index] = isMatch }
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

	local sellTicket = eventsFolder:FindFirstChild("SellTicketEvent")
	if not sellTicket then
		sellTicket = Instance.new("RemoteFunction")
		sellTicket.Name = "SellTicketEvent"
		sellTicket.Parent = eventsFolder
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

	return buyTicket, sellTicket, revealSquare, getSession
end

local buyTicketFunc, sellTicketFunc, revealSquareEvent, getSessionFunc = setupCommunication()

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

-- SELL TICKET
local function onSellTicket(player: Player, ticketName: string)
	local cleanName = ticketName:gsub("Ticket", "")
	local config = GameConfig.Tickets[cleanName]
	if not config then return {Success = false, Error = "Invalid Ticket"} end

	local inventory = player:FindFirstChild("Inventory")
	local ticketValue = inventory and inventory:FindFirstChild(cleanName .. "Ticket")

	if not ticketValue or ticketValue.Value <= 0 then
		return {Success = false, Error = "You don't have this ticket"}
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	local cashValue = leaderstats and leaderstats:FindFirstChild("Cash")

	if not cashValue then return {Success = false, Error = "Data Error"} end

	-- Sell for 50%
	local sellPrice = math.floor(config.Cost * 0.5)
	ticketValue.Value -= 1
	cashValue.Value += sellPrice

	return {Success = true, Price = sellPrice}
end

-- Internal helper to check session completion
local function isSessionComplete(session)
	local revealedCount = 0
	for i = 1, 10 do
		if session[tostring(i)] ~= nil or session[i] ~= nil then
			revealedCount += 1
		end
	end
	return revealedCount >= 3
end

-- GET / START SESSION
local function onGetSession(player: Player, ticketName: string)
	local userId = tostring(player.UserId)

	-- 1. If session exists, return it (Resume)
	if playerSessions[userId] and playerSessions[userId][ticketName] then
		local session = playerSessions[userId][ticketName]

		-- Defensive check: if it was already finished, clear it and force a new one
		if isSessionComplete(session) then
			print("TicketService: Found completed session for " .. player.Name .. " - " .. ticketName .. ". Clearing.")
			playerSessions[userId][ticketName] = nil
		else
			print("TicketService: Resuming session for " .. player.Name .. " - " .. ticketName)
			return session
		end
	end

	-- 2. No session, try to start a new one
	local config = GameConfig.Tickets[ticketName]
	if not config then return nil end

	local inventory = player:FindFirstChild("Inventory")
	local ticketValue = inventory and inventory:FindFirstChild(ticketName .. "Ticket")

	if ticketValue and ticketValue.Value > 0 then
		-- Consume ticket immediately
		ticketValue.Value -= 1

		if not playerSessions[userId] then playerSessions[userId] = {} end
		playerSessions[userId][ticketName] = {}

		print("TicketService: Started NEW session for " .. player.Name .. " - " .. ticketName .. " (Ticket consumed)")
		return playerSessions[userId][ticketName]
	else
		warn("TicketService: " .. player.Name .. " has no tickets to start session.")
		return nil
	end
end

-- REVEAL SQUARE
local function onRevealSquare(player: Player, ticketName: string, squareIndex: number)
	local userId = tostring(player.UserId)
	local session = playerSessions[userId] and playerSessions[userId][ticketName]

	if not session then
		warn("TicketService: Reveal attempt without active session for " .. player.Name)
		return
	end

	local config = GameConfig.Tickets[ticketName]
	if not config then return end

	-- Don't allow re-revealing if already exists, but resend for sync
	if session[tostring(squareIndex)] == nil and session[squareIndex] == nil then
		-- Generate result
		local isMatch = math.random() <= config.WinChancePerSquare
		session[tostring(squareIndex)] = isMatch
		print("TicketService: Reveal result for " .. player.Name .. " -> " .. tostring(isMatch))
	end

	local finalResult = session[tostring(squareIndex)] or session[squareIndex]
	revealSquareEvent:FireClient(player, ticketName, squareIndex, finalResult)

	-- Check for completion
	local revealedCount = 0
	local matchesCount = 0
	for i = 1, 10 do -- Search for all possible square indices
		local res = session[tostring(i)] or session[i]
		if res ~= nil then
			revealedCount += 1
			if res == true then
				matchesCount += 1
			end
		end
	end

	if revealedCount >= 3 then
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
				print("TicketService: Reward paid to " .. player.Name .. ": $" .. reward)
			end
		end

		-- CLEAR SESSION
		playerSessions[userId][ticketName] = nil
		print("TicketService: Session COMPLETED for " .. player.Name)
	end
end

function TicketService.Init()
	DataService = require(script.Parent.DataService)

	buyTicketFunc.OnServerInvoke = onBuyTicket
	sellTicketFunc.OnServerInvoke = onSellTicket
	getSessionFunc.OnServerInvoke = onGetSession
	revealSquareEvent.OnServerEvent:Connect(onRevealSquare)

	Players.PlayerRemoving:Connect(function(player)
		playerSessions[tostring(player.UserId)] = nil
	end)
end

TicketService.Init()

return TicketService
