local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local Events = ReplicatedStorage:WaitForChild("Events")
local RevealSquareEvent = Events:WaitForChild("RevealSquareEvent")
local GetScratchSession = Events:WaitForChild("GetScratchSession")
local FinishScratchSession = Events:WaitForChild("FinishScratchSession")
local ScratchMenusTemplates = ReplicatedStorage:WaitForChild("ScratchMenu")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local MenuController = require(script.Parent.MenuController)

local ScratchController = {}

local currentGui = nil
local activeConnections = {} -- [GuiInstance] = {Connection, ...}

local function cleanupConnections(gui)
	if not gui then return end
	local connections = activeConnections[gui]
	if connections then
		for _, conn in ipairs(connections) do
			conn:Disconnect()
		end
		activeConnections[gui] = nil
	end
end

local function closeAndDestroy(specificGui)
	local gui = specificGui or currentGui
	if not gui or not gui.Parent then return end

	if gui == currentGui then
		currentGui = nil
	end

	print("ScratchController: Closing and destroying GUI: " .. gui.Name)

	local mainFrame = gui:FindFirstChild("SimpleTicket") or gui:FindFirstChildOfClass("Frame")
	if mainFrame and mainFrame.Visible then
		local closeTween = TweenService:Create(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
			Size = UDim2.new(0.1, 0, 0.1, 0)
		})
		closeTween.Completed:Connect(function()
			cleanupConnections(gui)
			if gui.Parent then
				gui:Destroy()
			end
		end)
		closeTween:Play()
	else
		cleanupConnections(gui)
		if gui.Parent then
			gui:Destroy()
		end
	end
end

local function checkCompletion(gui, ticketName)
	if not gui then return end
	local mainFrame = gui:FindFirstChild("SimpleTicket") or gui:FindFirstChildOfClass("Frame")
	if not mainFrame then return end

	local iconBg = mainFrame:FindFirstChild("ICONBG")
	local collectButt = mainFrame:FindFirstChild("COLLECTBUTT")
	local trowButt = mainFrame:FindFirstChild("TROWBUTT")

	if not iconBg then return end

	local revealedCount = 0
	local matchesCount = 0
	for _, child in ipairs(iconBg:GetChildren()) do
		if child.Name:match("%d+") and child.Text ~= "?" then
			revealedCount += 1
			if child.Text == "GREEN" then
				matchesCount += 1
			end
		end
	end

	if revealedCount >= 3 then
		-- If buttons are already visible, we already connected and setup
		if (collectButt and collectButt.Visible) or (trowButt and trowButt.Visible) then return end

		local config = GameConfig.Tickets[ticketName]
		local reward = 0
		if matchesCount == 3 then
			reward = config.Rewards.Jackpot
		elseif matchesCount == 2 then
			reward = config.Rewards.Medium
		end

		if reward > 0 then
			if collectButt then
				collectButt.Visible = true
				collectButt.Text = reward .. "$"
				local conn = collectButt.MouseButton1Click:Connect(function()
					print("ScratchController: Collecting reward: " .. reward)
					local res = FinishScratchSession:InvokeServer(ticketName, "Collect")
					if res and res.Success then
						closeAndDestroy(gui)
					end
				end)
				if not activeConnections[gui] then activeConnections[gui] = {} end
				table.insert(activeConnections[gui], conn)
			end
			if trowButt then trowButt.Visible = false end
		else
			if trowButt then
				trowButt.Visible = true
				local conn = trowButt.MouseButton1Click:Connect(function()
					print("ScratchController: Throwing away ticket")
					local res = FinishScratchSession:InvokeServer(ticketName, "ThrowAway")
					if res and res.Success then
						closeAndDestroy(gui)
					end
				end)
				if not activeConnections[gui] then activeConnections[gui] = {} end
				table.insert(activeConnections[gui], conn)
			end
			if collectButt then collectButt.Visible = false end
		end
	else
		if collectButt then collectButt.Visible = false end
		if trowButt then trowButt.Visible = false end
	end
end

local function animateInfoText(gui)
	local mainFrame = gui:FindFirstChild("SimpleTicket") or gui:FindFirstChildOfClass("Frame")
	local infoText = mainFrame and mainFrame:FindFirstChild("INFO")
	if not infoText then return end

	local originalSize = infoText.Size
	local originalPos = infoText.Position
	infoText.AnchorPoint = Vector2.new(0.5, 0.5)
	infoText.Position = UDim2.new(
		originalPos.X.Scale + (originalSize.X.Scale * 0.5),
		originalPos.X.Offset + (originalSize.X.Offset * 0.5),
		originalPos.Y.Scale + (originalSize.Y.Scale * 0.5),
		originalPos.Y.Offset + (originalSize.Y.Offset * 0.5)
	)

	local tweenInfo = TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	local tween = TweenService:Create(infoText, tweenInfo, {
		Size = UDim2.new(originalSize.X.Scale * 1.15, originalSize.X.Offset * 1.15, originalSize.Y.Scale * 1.15, originalSize.Y.Offset * 1.15)
	})
	tween:Play()

	if not activeConnections[gui] then activeConnections[gui] = {} end
	table.insert(activeConnections[gui], {Disconnect = function() tween:Cancel() end})
end

function ScratchController.OpenScratch(ticketName: string)
	-- 1. PREVENT DOUBLE OPEN
	if currentGui then
		local oldGui = currentGui
		currentGui = nil
		cleanupConnections(oldGui)
		oldGui:Destroy()
	end

	-- 2. CLOSE OTHER MAIN MENUS
	MenuController.closeAllMainMenus()

	local firstLetter = ticketName:sub(1,1):upper()
	local restOfName = ticketName:sub(2):lower()
	local templateName = "Scratch" .. firstLetter .. restOfName .. "GUI"

	if ticketName:lower() == "golden" then
		templateName = "ScratchGOLDENGUI"
	end

	local template = ScratchMenusTemplates:FindFirstChild(templateName)
	if not template then
		warn("ScratchController: Template not found: " .. templateName)
		return
	end

	-- 3. SYNC SESSION FROM SERVER FIRST
	print("ScratchController: Requesting session from server...")
	local session = GetScratchSession:InvokeServer(ticketName)

	if not session then
		print("ScratchController: No active session or tickets available.")
		return
	end

	-- 4. CLONE AND SETUP
	print("ScratchController: Cloning template " .. templateName)
	local gui = template:Clone()
	gui.Enabled = true
	gui.DisplayOrder = 20
	gui.Parent = PlayerGui
	currentGui = gui

	local mainFrame = gui:FindFirstChild("SimpleTicket") or gui:FindFirstChildOfClass("Frame")
	if not mainFrame then return end

	-- Snappy Centering
	mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	mainFrame.Position = UDim2.fromScale(0.5, 0.5)
	local targetSize = mainFrame.Size

	-- Start Opening Animation
	mainFrame.Visible = true
	mainFrame.Size = UDim2.new(0.1, 0, 0.1, 0)
	TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = targetSize
	}):Play()

	-- 5. POPULATE AND CONNECT
	local iconBg = mainFrame:FindFirstChild("ICONBG")

	-- Hide buttons initially
	local collectButt = mainFrame:FindFirstChild("COLLECTBUTT")
	local trowButt = mainFrame:FindFirstChild("TROWBUTT")
	if collectButt then collectButt.Visible = false end
	if trowButt then trowButt.Visible = false end

	animateInfoText(gui)

	if iconBg then
		for _, child in ipairs(iconBg:GetChildren()) do
			local indexStr = child.Name:match("%d+")
			if indexStr then
				local i = tonumber(indexStr)
				child.ZIndex = 30

				-- Initial state
				child.Text = "?"
				child.BackgroundColor3 = Color3.fromRGB(255, 255, 255)

				-- Restore from session
				local result = session[i]
				if result == nil then result = session[tostring(i)] end

				if result ~= nil then
					child.BackgroundColor3 = result and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
					child.Text = result and "GREEN" or "RED"
				end

				local originalBtnSize = child.Size

				local conn = child.MouseButton1Click:Connect(function()
					if child.Text == "?" then
						-- Snappy feedback
						TweenService:Create(child, TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
							Size = UDim2.new(originalBtnSize.X.Scale * 0.9, 0, originalBtnSize.Y.Scale * 0.9, 0)
						}):Play()
						task.delay(0.05, function()
							if child.Parent then
								TweenService:Create(child, TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = originalBtnSize}):Play()
							end
						end)

						RevealSquareEvent:FireServer(ticketName, i)
					end
				end)
				if not activeConnections[gui] then activeConnections[gui] = {} end
				table.insert(activeConnections[gui], conn)
			end
		end
	end

	checkCompletion(gui, ticketName)

	-- Safety manual close
	local closeButt = mainFrame:FindFirstChild("CloseButt")
	if closeButt then
		local conn = closeButt.MouseButton1Click:Connect(function()
			closeAndDestroy(gui)
		end)
		if not activeConnections[gui] then activeConnections[gui] = {} end
		table.insert(activeConnections[gui], conn)
	end
end

-- Listen for server results
RevealSquareEvent.OnClientEvent:Connect(function(ticketName, squareIndex, isMatch)
	if not currentGui then return end

	local mainFrame = currentGui:FindFirstChild("SimpleTicket") or currentGui:FindFirstChildOfClass("Frame")
	local iconBg = mainFrame and mainFrame:FindFirstChild("ICONBG")

	local sc = nil
	if iconBg then
		for _, child in ipairs(iconBg:GetChildren()) do
			if child.Name:match(tostring(squareIndex)) then
				sc = child
				break
			end
		end
	end

	if sc then
		if isMatch then
			sc.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
			sc.Text = "GREEN"
			-- Pulse
			local btnSize = sc.Size
			TweenService:Create(sc, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Size = UDim2.new(btnSize.X.Scale * 1.2, 0, btnSize.Y.Scale * 1.2, 0)
			}):Play()
			task.delay(0.2, function()
				if sc.Parent then
					TweenService:Create(sc, TweenInfo.new(0.1), {Size = btnSize}):Play()
				end
			end)
		else
			sc.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
			sc.Text = "RED"
		end
	end

	checkCompletion(currentGui, ticketName)
end)

return ScratchController
