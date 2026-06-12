local Players = game:GetService("Players")

local AdminService = {}

-- Simple check: Is player the place owner?
local function isAdmin(player)
	-- In Studio, the player is always an admin
	if game:GetService("RunService"):IsStudio() then
		return true
	end
	return player.UserId == game.CreatorId
end

function AdminService.Init()
	print("AdminService: Initializing...")

	Players.PlayerAdded:Connect(function(player)
		player.Chatted:Connect(function(message)
			if not isAdmin(player) then return end

			local args = message:split(" ")
			if args[1] == "/give" then
				local targetName = args[2]
				local statName = args[3]
				local amount = tonumber(args[4])

				if targetName and statName and amount then
					local targetPlayer = nil
					for _, p in ipairs(Players:GetPlayers()) do
						if p.Name:lower():sub(1, #targetName) == targetName:lower() then
							targetPlayer = p
							break
						end
					end

					if targetPlayer then
						local leaderstats = targetPlayer:FindFirstChild("leaderstats")
						if leaderstats then
							local stat = leaderstats:FindFirstChild(statName:sub(1,1):upper() .. statName:sub(2):lower())
							if stat then
								stat.Value += amount
								print("AdminService: Gave " .. amount .. " " .. stat.Name .. " to " .. targetPlayer.Name)
							else
								warn("AdminService: Stat " .. statName .. " not found.")
							end
						end
					else
						warn("AdminService: Target player " .. targetName .. " not found.")
					end
				end
			end
		end)
	end)
end

return AdminService
