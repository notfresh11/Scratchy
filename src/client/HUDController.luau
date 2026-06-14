local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local HUDController = {}

function HUDController.Init()
	-- 1. Hide default leaderboard
	task.spawn(function()
		local success = false
		while not success do
			success = pcall(function()
				StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
			end)
			task.wait(0.5)
		end
	end)

	-- 2. Find HUD Elements
	local mainGui = PlayerGui:WaitForChild("Main")
	local mainFrame = mainGui:WaitForChild("MainFrame")

	local moneyLabel = mainFrame:WaitForChild("MONEY")
	local shardsLabel = mainFrame:WaitForChild("SHARDS")
	local luckLabel = mainFrame:WaitForChild("LUCK")

	local leaderstats = Player:WaitForChild("leaderstats")
	local cash = leaderstats:WaitForChild("Cash")
	local shards = leaderstats:WaitForChild("Shards")
	local luck = leaderstats:WaitForChild("Luck")

	local function updateHUD()
		moneyLabel.Text = "CASH: " .. (cash.Value or 0)
		shardsLabel.Text = "SHARDS: " .. (shards.Value or 0)
		luckLabel.Text = "LUCK: " .. (luck.Value or 0)
	end

	cash.Changed:Connect(updateHUD)
	shards.Changed:Connect(updateHUD)
	luck.Changed:Connect(updateHUD)

	updateHUD()
	print("HUDController: Initialized and connected to stats.")
end

HUDController.Init()

return HUDController
