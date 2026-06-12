local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
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
	print("TicketService: Request to reveal " .. ticketName .. " square " .. squareIndex .. " from " .. player.Name)

	local config = GameConfig.Tickets[ticketName]
	if not config then return end

	local userId = tostring(player.UserId)
	local inventory = player:FindFirstChild("Inventory")
	local ticketValue = inventory and inventory:FindFirstChild(ticketName .. "Ticket")

	-- Create session if not exists
	if not (playerSessions[userId] and playerSessions[userId][ticketName]) then
		if not ticketValue or ticketValue.Value <= 0 then
			warn("TicketService: " .. player.Name .. " has no tickets to start session.")
			return
		end

		if not playerSessions[userId] then playerSessions[userId] = {} end
		playerSessions[userId][ticketName] = {}
		ticketValue.Value -= 1
		print("TicketService: Session started for " .. player.Name)
	end

	local session = playerSessions[userId][ticketName]

	-- Don't allow re-revealing if already exists, but resend for sync
	if session[tostring(squareIndex)] ~= nil or session[squareIndex] ~= nil then
		local result = session[tostring(squareIndex)] or session[squareIndex]
		revealSquareEvent:FireClient(player, ticketName, squareIndex, result)
		return
	end

	-- Generate result
	local isMatch = math.random() <= config.WinChancePerSquare
	session[tostring(squareIndex)] = isMatch
	print("TicketService: Generated " .. tostring(isMatch) .. " for square " .. squareIndex)

	revealSquareEvent:FireClient(player, ticketName, squareIndex, isMatch)

	-- Check for completion
	local revealedCount = 0
	local matchesCount = 0
	for i = 1, 10 do -- Large enough to catch any index
		local res = session[tostring(i)] or session[i]
		if res ~= nil then
			revealedCount += 1
			if res == true then
				matchesCount += 1
			end
		end
	end

	print("TicketService: revealedCount: " .. revealedCount)

	if revealedCount >= 3 then -- Support 3 or more if UI expands
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
				print("TicketService: Rewarded " .. player.Name .. " with $" .. reward)
			end
		end

		-- CLEAR SESSION
		playerSessions[userId][ticketName] = nil
		print("TicketService: Session cleared for " .. player.Name)
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
