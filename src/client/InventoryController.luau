local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local InvTicketsTemplates = ReplicatedStorage:WaitForChild("InvTickets")
local InventoryFolder = Player:WaitForChild("Inventory")

local InvGui = PlayerGui:WaitForChild("InvGUI")
local TicketsZone = InvGui:WaitForChild("Tickets")

local ScratchController = require(script.Parent.ScratchController)

local TicketMapping = {
	["SimpleTicket"] = "SimpleTTemplate",
	["RareTicket"] = "RareTTemplate",
	["GoldenTicket"] = "GoldenTTemplate"
}

local function updateInventory()
	-- Clear current visual tickets
	for _, child in ipairs(TicketsZone:GetChildren()) do
		if child:IsA("Frame") or child:IsA("ImageLabel") or child:IsA("ImageButton") then
			child:Destroy()
		end
	end

	-- Add tickets from server inventory
	for _, ticketVal in ipairs(InventoryFolder:GetChildren()) do
		if ticketVal.Value > 0 then
			local templateName = TicketMapping[ticketVal.Name]
			local template = InvTicketsTemplates:FindFirstChild(templateName)

			if template then
				local clone = template:Clone()
				local displayName = ticketVal.Name:gsub("Ticket", ""):upper()
				clone.Name = ticketVal.Name

				local nameLabel = clone:FindFirstChild("Name")
				if nameLabel then
					nameLabel.Text = displayName .. " TICKET (x" .. ticketVal.Value .. ")"
				end

				clone.Parent = TicketsZone

				-- Connect Scratch Button
				local scratchButt = clone:FindFirstChild("ScratchButt")
				if scratchButt then
					scratchButt.MouseButton1Click:Connect(function()
						ScratchController.OpenScratch(ticketVal.Name:gsub("Ticket", ""))
					end)
				end
			end
		end
	end
end

-- Listen for changes
for _, ticketVal in ipairs(InventoryFolder:GetChildren()) do
	ticketVal.Changed:Connect(updateInventory)
end

InventoryFolder.ChildAdded:Connect(function(child)
	if child:IsA("IntValue") then
		child.Changed:Connect(updateInventory)
		updateInventory()
	end
end)

updateInventory()

return {}
