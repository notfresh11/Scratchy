local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local Events = ReplicatedStorage:WaitForChild("Events")
local BuyTicketEvent = Events:WaitForChild("BuyTicketEvent")
local PrestigeRequest = Events:WaitForChild("PrestigeRequest")

local ShopGui = PlayerGui:WaitForChild("ShopGUI")
local ShopFrame = ShopGui:WaitForChild("ShopFrame")
local TicketsFolder = ShopFrame:WaitForChild("Tickets")
local PrestigeSHOP = ShopFrame:WaitForChild("PrestigeSHOP")

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

	-- Prestige Button
	if PrestigeSHOP then
		-- Assuming the PrestigeSHOP tab button ITSELF is the one you click to prestige in this MVP,
		-- or it has a button inside. Usually, we'd have a button inside.
		-- Based on prompt: "PrestigeSHOP" is a tab. I'll add a listener to it if it acts as a button,
		-- or look for a button inside.
		local pButton = PrestigeSHOP:FindFirstChild("PrestigeButt") or PrestigeSHOP
		pButton.MouseButton1Click:Connect(function()
			local result = PrestigeRequest:InvokeServer()
			if result and result.Success then
				print("Prestige Successful! New Shards: " .. result.NewShards)
			else
				warn("Prestige failed: " .. (result and result.Error or "Unknown"))
			end
		end)
	end
end

setupShop()

return {}
