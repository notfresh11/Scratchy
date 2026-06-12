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

-- Force centering and prepare for animation
local function prepareFrame(frame)
	if not frame then return end
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	if not originalSizes[frame] then
		originalSizes[frame] = frame.Size
	end
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

	-- Ensure GUI is visible and on top
	gui.Enabled = true
	gui.DisplayOrder = 20

	local mainFrame = gui:FindFirstChild("SimpleTicket") or gui:FindFirstChildOfClass("Frame")
	if not mainFrame then return end

	prepareFrame(mainFrame)

	-- 2. START OPENING ANIMATION IMMEDIATELY (Dopamine!)
	mainFrame.Visible = true
	mainFrame.Size = UDim2.new(0, 0, 0, 0)

	local openTween = TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = originalSizes[mainFrame]
	})
	openTween:Play()

	-- 3. SYNC DATA FROM SERVER (IN BACKGROUND)
	cleanupConnections()
	currentOpenTicket = ticketName

	local iconBg = mainFrame:FindFirstChild("ICONBG")

	-- Reset squares first
	if iconBg then
		for i = 1, 3 do
			local sc = iconBg:FindFirstChild("SC" .. i)
			if sc then
				sc.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				sc.Text = "?"
			end
		end
	end

	-- Invoke server
	task.spawn(function()
		local session = GetScratchSession:InvokeServer(ticketName)
		if iconBg and session then
			for i = 1, 3 do
				local sc = iconBg:FindFirstChild("SC" .. i)
				local result = session[i] or session[tostring(i)]
				if sc and result ~= nil then
					sc.BackgroundColor3 = result and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
					sc.Text = result and "GREEN" or "RED"
				end
			end
		end
	end)

	-- 4. CONNECT CLICK EVENTS
	if iconBg then
		for i = 1, 3 do
			local sc = iconBg:FindFirstChild("SC" .. i)
			if sc then
				local conn = sc.MouseButton1Click:Connect(function()
					if sc.Text == "?" then
						-- Snappy click feedback
						local btnSize = sc.Size
						TweenService:Create(sc, TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
							Size = UDim2.new(btnSize.X.Scale * 0.9, 0, btnSize.Y.Scale * 0.9, 0)
						}):Play()
						task.delay(0.05, function()
							TweenService:Create(sc, TweenInfo.new(0.05, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = btnSize}):Play()
						end)

						RevealSquareEvent:FireServer(ticketName, i)
					end
				end)
				table.insert(activeConnections, conn)
			end
		end
	end
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
	local sc = iconBg and iconBg:FindFirstChild("SC" .. squareIndex)

	if sc then
		if isMatch then
			sc.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
			sc.Text = "GREEN"
			-- Dopamine pulse
			local btnSize = sc.Size
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

	-- Auto-close
	local revealedCount = 0
	if iconBg then
		for i = 1, 3 do
			local sq = iconBg:FindFirstChild("SC" .. i)
			if sq and sq.Text ~= "?" then
				revealedCount += 1
			end
		end
	end

	if revealedCount == 3 then
		task.delay(0.8, function() -- Reduced delay for snappiness
			if mainFrame and mainFrame.Visible then
				local closeTween = TweenService:Create(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
					Size = UDim2.new(0,0,0,0)
				})
				closeTween.Completed:Connect(function()
					mainFrame.Visible = false
					mainFrame.Size = originalSizes[mainFrame]
					cleanupConnections()
					currentOpenTicket = nil
				end)
				closeTween:Play()
			end
		end)
	end
end)

return ScratchController
