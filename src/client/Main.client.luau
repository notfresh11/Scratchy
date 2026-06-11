-- Client entry point
print("Client init - Starting Spree Simulator UI")

local Client = script.Parent

-- Initialize Controllers
require(Client.MenuController)
require(Client.InventoryController)
require(Client.ShopController)
require(Client.ScratchController)
require(Client.ZoneController)

print("Client init - Controllers Loaded Successfully")
