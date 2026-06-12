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

-- Snappy Centering
local function prepareFrame(frame)
	if not frame then return end
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	if not originalSizes[frame] then
		originalSizes[frame] = frame.Size
		print("ScratchController: Prepared size for " .. frame.Name .. " -> " .. tostring(frame.Size))
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

	gui.Enabled = true
	gui.DisplayOrder = 20

	local mainFrame = gui:FindFirstChild("SimpleTicket") or gui:FindFirstChildOfClass("Frame")
	if not mainFrame then return end

	prepareFrame(mainFrame)

	-- 2. START OPENING ANIMATION IMMEDIATELY (Centered Pop-In)
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
		print("ScratchController: Connecting squares...")
		for _, child in ipairs(iconBg:GetChildren()) do
			local indexStr = child.Name:match("%d+")
			if indexStr then
				local i = tonumber(indexStr)
				print("ScratchController: Found square: " .. child.Name .. " as Index: " .. i)

				child.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				child.Text = "?"
				child.Active = true
				child.ZIndex = 30 -- Ensure it's on top of background

				local conn = child.MouseButton1Click:Connect(function()
					print("ScratchController: Clicked SC" .. i)
					if child.Text == "?" then
						-- Snappy click feedback
						local btnSize = child.Size
						TweenService:Create(child, TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
							Size = UDim2.new(btnSize.X.Scale * 0.9, 0, btnSize.Y.Scale * 0.9, 0)
						}):Play()
						task.delay(0.05, function()
							TweenService:Create(child, TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = btnSize}):Play()
						end)

						print("ScratchController: Firing RevealSquareEvent for " .. i)
						RevealSquareEvent:FireServer(ticketName, i)
					end
				end)
				table.insert(activeConnections, conn)
			end
		end
	else
		warn("ScratchController: ICONBG NOT FOUND!")
	end

	-- Invoke server to catch up
	task.spawn(function()
		local session = GetScratchSession:InvokeServer(ticketName)
		if iconBg and session then
			print("ScratchController: Restoring session state...")
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
	print("ScratchController: Revealed result for square " .. squareIndex .. ": " .. tostring(isMatch))

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
			local indexStr = child.Name:match(tostring(squareIndex))
			if indexStr then
				sc = child
				break
			end
		end
	end

	if sc then
		if isMatch then
			sc.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
			sc.Text = "GREEN"
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
		for _, child in ipairs(iconBg:GetChildren()) do
			if child.Name:match("%d+") and child.Text ~= "?" then
				revealedCount += 1
			end
		end
	end

	if revealedCount >= 3 then
		task.delay(0.6, function()
			if mainFrame and mainFrame.Visible then
				print("ScratchController: Auto-closing " .. mainFrame.Name)
				local closeTween = TweenService:Create(mainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
					Size = UDim2.new(0.1,0,0.1,0)
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
