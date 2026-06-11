local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage:WaitForChild("Events")
local BuyTicketEvent = Events:WaitForChild("BuyTicketEvent")
local RevealSquareEvent = Events:WaitForChild("RevealSquareEvent")

local AutoScratch = {}
local isEnabled = false
local currentTier = "Simple" -- Default

function AutoScratch.Toggle(tier)
	isEnabled = not isEnabled
	if tier then currentTier = tier end

	if isEnabled then
		print("Auto-Scratch Enabled for " .. currentTier)
		task.spawn(function()
			while isEnabled do
				-- 1. Buy Ticket
				local buyResult = BuyTicketEvent:InvokeServer(currentTier)
				if buyResult and buyResult.Success then
					-- 2. Reveal Squares (Server-side reveal happens with 3 events)
					for i = 1, 3 do
						RevealSquareEvent:FireServer(currentTier, i)
						task.wait(0.1) -- Small delay between squares
					end
				else
					warn("Auto-Scratch: Could not buy ticket. Stopping.")
					isEnabled = false
					break
				end

				task.wait(1.5) -- Core delay
			end
			print("Auto-Scratch Disabled")
		end)
	end

	return isEnabled
end

return AutoScratch
