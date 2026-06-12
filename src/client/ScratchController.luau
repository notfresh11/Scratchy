local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local Events = ReplicatedStorage:WaitForChild("Events")
local RevealSquareEvent = Events:WaitForChild("RevealSquareEvent")
local GetScratchSession = Events:WaitForChild("GetScratchSession")

local MenuController = require(script.Parent.MenuController)

local ScratchController = {}

local currentOpenTicket = nil
local activeConnections = {}
local originalSizes = {}

local function cleanupConnections()
	for _, conn in ipairs(activeConnections) do
		conn:Disconnect()
	end
	activeConnections = {}
end

-- Reset visuals for a clean start
local function resetVisuals(mainFrame)
	if not mainFrame then return end
	local iconBg = mainFrame:FindFirstChild("ICONBG")
	if iconBg then
		for _, child in ipairs(iconBg:GetChildren()) do
			if child.Name:match("%d+") then
				child.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				child.Text = "?"
				local originalBtnSize = child:GetAttribute("OriginalSize")
				if originalBtnSize then
					child.Size = originalBtnSize
				end
			end
		end
	end
end

-- Snappy Centering
local function prepareFrame(frame)
	if not frame then return end
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	if not originalSizes[frame] then
		originalSizes[frame] = frame.Size
		local iconBg = frame:FindFirstChild("ICONBG")
		if iconBg then
			for _, child in ipairs(iconBg:GetChildren()) do
				if child.Name:match("%d+") then
					child:SetAttribute("OriginalSize", child.Size)
				end
			end
		end
	end
end

local function closeScratch(mainFrame)
	if not mainFrame or not mainFrame.Visible then return end
	print("ScratchController: closeScratch called for " .. mainFrame.Name)
	local closeTween = TweenService:Create(mainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		Size = UDim2.new(0.1,0,0.1,0)
	})
	closeTween.Completed:Connect(function()
		mainFrame.Visible = false
		mainFrame.Size = originalSizes[mainFrame]
		resetVisuals(mainFrame)
		cleanupConnections()
		currentOpenTicket = nil
	end)
	closeTween:Play()
end

function ScratchController.OpenScratch(ticketName: string)
	-- 1. IMMEDIATELY CLOSE OTHER MENUS
	MenuController.closeAllMainMenus()

	local firstLetter = ticketName:sub(1,1):upper()
	local restOfName = ticketName:sub(2):lower()
	local guiName = "Scratch" .. firstLetter .. restOfName .. "GUI"

	if ticketName:lower() == "golden" then
		guiName = "ScratchGOLDENGUI"
	end

	print("ScratchController: Opening " .. guiName)

	local gui = PlayerGui:FindFirstChild(guiName)
	if not gui then
		warn("ScratchController: Could not find GUI: " .. guiName)
		return
	end

	gui.Enabled = true
	gui.DisplayOrder = 20

	local mainFrame = gui:FindFirstChild("SimpleTicket") or gui:FindFirstChildOfClass("Frame")
	if not mainFrame then return end

	prepareFrame(mainFrame)

	-- HARD RESET BEFORE SHOWING
	resetVisuals(mainFrame)

	-- 2. START OPENING ANIMATION IMMEDIATELY
	mainFrame.Visible = true
	mainFrame.Size = UDim2.new(0.1, 0, 0.1, 0)

	local openTween = TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = originalSizes[mainFrame]
	})
	openTween:Play()

	-- 3. SYNC DATA AND CONNECT CLICKS
	cleanupConnections()
	currentOpenTicket = ticketName

	local iconBg = mainFrame:FindFirstChild("ICONBG")

	if iconBg then
		for _, child in ipairs(iconBg:GetChildren()) do
			local indexStr = child.Name:match("%d+")
			if indexStr then
				local i = tonumber(indexStr)
				child.Active = true
				child.ZIndex = 30

				local conn = child.MouseButton1Click:Connect(function()
					print("ScratchController: Square " .. i .. " clicked. Text: " .. child.Text)
					if child.Text == "?" then
						local btnSize = child:GetAttribute("OriginalSize") or child.Size
						TweenService:Create(child, TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
							Size = UDim2.new(btnSize.X.Scale * 0.9, 0, btnSize.Y.Scale * 0.9, 0)
						}):Play()
						task.delay(0.05, function()
							TweenService:Create(child, TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = btnSize}):Play()
						end)

						RevealSquareEvent:FireServer(ticketName, i)
					end
				end)
				table.insert(activeConnections, conn)
			end
		end
	end

	-- SAFETY: Connect manual close button if it exists
	local closeButt = mainFrame:FindFirstChild("CloseButt")
	if closeButt then
		local conn = closeButt.MouseButton1Click:Connect(function()
			closeScratch(mainFrame)
		end)
		table.insert(activeConnections, conn)
	end

	-- Invoke server to catch up
	task.spawn(function()
		local session = GetScratchSession:InvokeServer(ticketName)
		if iconBg and session then
			print("ScratchController: Syncing session state...")
			for _, child in ipairs(iconBg:GetChildren()) do
				local indexStr = child.Name:match("%d+")
				if indexStr then
					local i = tonumber(indexStr)
					local result = session[i] or session[tostring(i)]
					if result ~= nil then
						child.BackgroundColor3 = result and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
						child.Text = result and "GREEN" or "RED"
					end
				end
			end
		end
	end)
end

-- Listen for server results
RevealSquareEvent.OnClientEvent:Connect(function(ticketName, squareIndex, isMatch)
	local firstLetter = ticketName:sub(1,1):upper()
	local restOfName = ticketName:sub(2):lower()
	local guiName = "Scratch" .. firstLetter .. restOfName .. "GUI"
	if ticketName:lower() == "golden" then guiName = "ScratchGOLDENGUI" end

	local gui = PlayerGui:FindFirstChild(guiName)
	if not gui then return end

	local mainFrame = gui:FindFirstChild("SimpleTicket") or gui:FindFirstChildOfClass("Frame")
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
			local btnSize = sc:GetAttribute("OriginalSize") or sc.Size
			TweenService:Create(sc, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Size = UDim2.new(btnSize.X.Scale * 1.2, 0, btnSize.Y.Scale * 1.2, 0)
			}):Play()
			task.delay(0.2, function()
				TweenService:Create(sc, TweenInfo.new(0.1), {Size = btnSize}):Play()
			end)
		else
			sc.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
			sc.Text = "RED"
		end
	end

	-- Auto-close check
	local revealedCount = 0
	if iconBg then
		for _, child in ipairs(iconBg:GetChildren()) do
			if child.Name:match("%d+") and child.Text ~= "?" then
				revealedCount += 1
			end
		end
	end

	if revealedCount >= 3 then
		print("ScratchController: 3 squares revealed. Starting 3s delay...")
		task.delay(3, function()
			closeScratch(mainFrame)
		end)
	end
end)

return ScratchController
