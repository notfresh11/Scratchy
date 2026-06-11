-- Server entry point
local Server = script.Parent

-- Require services to initialize them
local DataService = require(Server.DataService)
local ScratchService = require(Server.ScratchService)
local PrestigeService = require(Server.PrestigeService)

print("Server initialized successfully")
