-- Server entry point
print("Server init - Starting Spree Simulator Backend")

local Server = script.Parent

-- Require services to initialize them
local DataService = require(Server.DataService)
local TicketService = require(Server.TicketService)
local PrestigeService = require(Server.PrestigeService)
local AdminService = require(Server.AdminService)

-- Explicitly call Init where necessary
AdminService.Init()

print("Server init - Services Loaded Successfully")
