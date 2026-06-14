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

	-- TaskBar Slide Logic
	local taskBar = mainFrame:WaitForChild("TaskBar")
	local hideShowButt = mainFrame:WaitForChild("HideShowBar")

	local originalPos = taskBar.Position
	-- Calculate hidden position based on TaskBar size
	local hiddenPos = UDim2.new(-taskBar.Size.X.Scale, -taskBar.Size.X.Offset - 10, originalPos.Y.Scale, originalPos.Y.Offset)
	local isBarVisible = true

	local function toggleTaskBar()
		isBarVisible = not isBarVisible
		local targetPos = isBarVisible and originalPos or hiddenPos

		local TweenService = game:GetService("TweenService")
		TweenService:Create(taskBar, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			Position = targetPos
		}):Play()

		-- Optional: Rotate or change icon of hideShowButt?
		-- User didn't ask, but good for UX.
	end

	hideShowButt.MouseButton1Click:Connect(toggleTaskBar)

	local MenuController = require(Player:WaitForChild("PlayerScripts"):WaitForChild("Client"):WaitForChild("MenuController"))
	MenuController.setupHover(hideShowButt)

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
