-- Client entry point
print("Client init - Starting Spree Simulator UI")

local Client = script.Parent

local function safeRequire(moduleScript)
	print("Client init - Requiring: " .. moduleScript.Name)
	local success, result = pcall(function()
		return require(moduleScript)
	end)
	if not success then
		warn("Client init - Error requiring " .. moduleScript.Name .. ": " .. tostring(result))
	else
		print("Client init - Loaded: " .. moduleScript.Name)
	end
end

-- Initialize Controllers sequentially
safeRequire(Client:WaitForChild("MenuController"))
safeRequire(Client:WaitForChild("InventoryController"))
safeRequire(Client:WaitForChild("ShopController"))
safeRequire(Client:WaitForChild("ScratchController"))
safeRequire(Client:WaitForChild("ZoneController"))
safeRequire(Client:WaitForChild("AutoScratchController"))

print("Client init - All Controllers Initialization Attempted")
