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

			local InvGui = PlayerGui:WaitForChild("InvGUI")
			local InvFrame = InvGui:FindFirstChild("InvFrame")
			local InvTicketsZone = InvFrame and InvFrame:FindFirstChild("Tickets")
			if InvFrame and InvFrame.Visible then
				MenuController.smartPopupClose(InvFrame)
				if InvTicketsZone then InvTicketsZone.Visible = false end
			end
		end
	end
end)

return {}
