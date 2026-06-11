-- Client entry point
local Client = script.Parent

-- Initialize Controllers
require(Client.MenuController)
require(Client.InventoryController)
require(Client.ShopController)
require(Client.ScratchController)
require(Client.ZoneController)

print("Client initialized successfully - Spree Simulator MVP")
