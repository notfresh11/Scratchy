local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local Events = ReplicatedStorage:WaitForChild("Events")
local BuyTicketEvent = Events:WaitForChild("BuyTicketEvent")

local ShopGui = PlayerGui:WaitForChild("ShopGUI")
-- Tickets is a sibling of ShopFrame in ShopGUI
local TicketsFolder = ShopGui:WaitForChild("Tickets")

local MenuController = require(script.Parent.MenuController)

local function setupShop()
	-- Buy Buttons
	for _, ticketFrame in ipairs(TicketsFolder:GetChildren()) do
		if ticketFrame:IsA("Frame") then
			local buyButt = ticketFrame:FindFirstChild("BUYButt")
			local infoButt = ticketFrame:FindFirstChild("INFOButt")

			local ticketName = ticketFrame.Name:gsub("T", "")

			if buyButt then
				MenuController.setupHover(buyButt)
				buyButt.MouseButton1Click:Connect(function()
					local result = BuyTicketEvent:InvokeServer(ticketName)
					if result and result.Success then
						print("Purchased " .. ticketName)
					else
						warn("Purchase failed: " .. (result and result.Error or "Unknown"))
					end
				end)
			end

			if infoButt then
				MenuController.setupHover(infoButt)
			end
		end
	end
end

setupShop()

return {}
