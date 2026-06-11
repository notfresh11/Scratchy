local Players = game:GetService("Players")

local LeaderboardService = {}

function LeaderboardService.Init()
	task.spawn(function()
		while true do
			local leaderboardPart = workspace:FindFirstChild("Leaderboard3D")
			if leaderboardPart then
				local surfaceGui = leaderboardPart:FindFirstChildOfClass("SurfaceGui")
				local scrollingFrame = surfaceGui and surfaceGui:FindFirstChildOfClass("ScrollingFrame")

				if scrollingFrame then
					-- Clear
					for _, child in ipairs(scrollingFrame:GetChildren()) do
						if child:IsA("TextLabel") then child:Destroy() end
					end

					-- Get Top Shards
					local players = Players:GetPlayers()
					table.sort(players, function(a, b)
						local shardsA = a:FindFirstChild("leaderstats") and a.leaderstats:FindFirstChild("Shards")
						local shardsB = b:FindFirstChild("leaderstats") and b.leaderstats:FindFirstChild("Shards")
						return (shardsA and shardsA.Value or 0) > (shardsB and shardsB.Value or 0)
					end)

					-- Display Top 10
					for i = 1, math.min(10, #players) do
						local p = players[i]
						local shards = p.leaderstats.Shards.Value

						local label = Instance.new("TextLabel")
						label.Size = UDim2.new(1, 0, 0, 50)
						label.Text = i .. ". " .. p.Name .. " - " .. shards .. " Shards"
						label.Parent = scrollingFrame
					end
				end
			end
			task.wait(30) -- Update every 30 seconds
		end
	end)
end

LeaderboardService.Init()

return LeaderboardService
