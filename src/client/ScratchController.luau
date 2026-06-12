local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local Events = ReplicatedStorage:WaitForChild("Events")
local RevealSquareEvent = Events:WaitForChild("RevealSquareEvent")
local GetScratchSession = Events:WaitForChild("GetScratchSession")
local ScratchMenusTemplates = ReplicatedStorage:WaitForChild("ScratchMenu")

local MenuController = require(script.Parent.MenuController)

local ScratchController = {}

local currentGui = nil
local activeConnections = {}

local function cleanupConnections()
	for _, conn in ipairs(activeConnections) do
		conn:Disconnect()
	end
	activeConnections = {}
end

local function closeAndDestroy()
	if not currentGui then return end

	local gui = currentGui
	currentGui = nil -- Prevent double calls

	print("ScratchController: Closing and destroying GUI.")

	local mainFrame = gui:FindFirstChild("SimpleTicket") or gui:FindFirstChildOfClass("Frame")
	if mainFrame then
		local closeTween = TweenService:Create(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
			Size = UDim2.new(0.1, 0, 0.1, 0)
		})
		closeTween.Completed:Connect(function()
			cleanupConnections()
			gui:Destroy()
		end)
		closeTween:Play()
	else
		cleanupConnections()
		gui:Destroy()
	end
end

function ScratchController.OpenScratch(ticketName: string)
	-- 1. PREVENT DOUBLE OPEN
	if currentGui then
		currentGui:Destroy()
		cleanupConnections()
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
				local result = session[i] or session[tostring(i)]
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
				table.insert(activeConnections, conn)
			end
		end
	end

	-- Safety manual close
	local closeButt = mainFrame:FindFirstChild("CloseButt")
	if closeButt then
		local conn = closeButt.MouseButton1Click:Connect(function()
			closeAndDestroy()
		end)
		table.insert(activeConnections, conn)
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
		task.delay(3, function()
			closeAndDestroy()
		end)
	end
end)

return ScratchController
