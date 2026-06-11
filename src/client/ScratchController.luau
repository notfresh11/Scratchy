local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local Events = ReplicatedStorage:WaitForChild("Events")
local RevealSquareEvent = Events:WaitForChild("RevealSquareEvent")
local GetScratchSession = Events:WaitForChild("GetScratchSession")

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

function ScratchController.OpenScratch(ticketName: string)
	local guiName = "Scratch" .. ticketName:sub(1,1):upper() .. ticketName:sub(2):lower() .. "GUI"
	if ticketName:lower() == "golden" then guiName = "ScratchGOLDENGUI" end

	local gui = PlayerGui:FindFirstChild(guiName)
	if not gui then
		warn("Could not find GUI: " .. guiName)
		return
	end

	local mainFrame = gui:FindFirstChild("SimpleTicket") or gui:FindFirstChildOfClass("Frame")
	if not mainFrame then return end

	-- Reset and Cleanup
	cleanupConnections()
	currentOpenTicket = ticketName

	if not originalSizes[mainFrame] then
		originalSizes[mainFrame] = mainFrame.Size
	end

	local iconBg = mainFrame:FindFirstChild("ICONBG")

	-- SYNC SESSION FROM SERVER
	local session = GetScratchSession:InvokeServer(ticketName)

	if iconBg then
		for i = 1, 3 do
			local sc = iconBg:FindFirstChild("SC" .. i)
			if sc then
				sc.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				sc.Text = "?"

				-- Use session[i] or session[tostring(i)] depending on remote behavior
				-- Roblox usually packs numeric keys into an array
				if session and (session[i] ~= nil or session[tostring(i)] ~= nil) then
					local isMatch = session[i]
					if isMatch == nil then isMatch = session[tostring(i)] end

					sc.BackgroundColor3 = isMatch and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
					sc.Text = isMatch and "GREEN" or "RED"
				end

				local conn = sc.MouseButton1Click:Connect(function()
					if sc.Text == "?" then
						-- Physical Feedback
						local originalSize = sc.Size
						TweenService:Create(sc, TweenInfo.new(0.05), {
							Size = UDim2.new(originalSize.X.Scale * 0.8, 0, originalSize.Y.Scale * 0.8, 0)
						}):Play()

						task.delay(0.05, function()
							TweenService:Create(sc, TweenInfo.new(0.05), {Size = originalSize}):Play()
						end)

						-- Server Request
						RevealSquareEvent:FireServer(ticketName, i)
					end
				end)
				table.insert(activeConnections, conn)
			end
		end
	end

	-- Pop-up Animation
	mainFrame.Visible = true
	mainFrame.Size = UDim2.new(0,0,0,0)
	TweenService:Create(mainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = originalSizes[mainFrame]
	}):Play()
end

-- Listen for server results
RevealSquareEvent.OnClientEvent:Connect(function(ticketName, squareIndex, isMatch)
	local guiName = "Scratch" .. ticketName:sub(1,1):upper() .. ticketName:sub(2):lower() .. "GUI"
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
		else
			sc.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
			sc.Text = "RED"
		end
	end

	-- Auto-close check
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
		task.delay(1.5, function()
			if mainFrame and mainFrame.Visible then
				local tween = TweenService:Create(mainFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
					Size = UDim2.new(0,0,0,0)
				})
				tween.Completed:Connect(function()
					mainFrame.Visible = false
					mainFrame.Size = originalSizes[mainFrame]
					cleanupConnections()
					currentOpenTicket = nil
				end)
				tween:Play()
			end
		end)
	end
end)

return ScratchController
