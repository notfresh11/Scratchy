local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local ShopGui = PlayerGui:WaitForChild("ShopGUI")
local ShopFrame = ShopGui:WaitForChild("ShopFrame")

local MenuController = require(script.Parent.MenuController)

local Zone = workspace:WaitForChild("World"):WaitForChild("Zones"):WaitForChild("TeleportZone"):WaitForChild("ZoneContainer")

Zone.Touched:Connect(function(hit)
	local char = hit.Parent
	local player = Players:GetPlayerFromCharacter(char)

	if player == Player then
		if not ShopFrame.Visible then
			MenuController.smartPopupOpen(ShopFrame)
			-- Optionally close inventory
			local InvGui = PlayerGui:WaitForChild("InvGUI")
			local InvFrame = InvGui:WaitForChild("InvFrame")
			if InvFrame.Visible then
				MenuController.smartPopupClose(InvFrame)
			end
		end
	end
end)

return {}
