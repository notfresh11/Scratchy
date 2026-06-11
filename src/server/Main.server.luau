-- Server entry point
local Server = script.Parent

-- Require services to initialize them
local DataService = require(Server.DataService)
local TicketService = require(Server.TicketService)
local PrestigeService = require(Server.PrestigeService)
local LeaderboardService = require(Server.LeaderboardService)

print("Server initialized successfully - Spree Simulator MVP")
