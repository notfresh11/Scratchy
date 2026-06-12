local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

print("MenuController: Initializing UI references...")

local originalSizes = {}

-- Center and prepare
local function prepareFrame(frame)
	if not frame then return end
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	if not originalSizes[frame] then
		originalSizes[frame] = frame.Size
	end
end

-- Snappy Pop-up Open
local function smartPopupOpen(frame)
	if not frame then return end
	print("MenuController: Opening Frame " .. frame.Name)

	prepareFrame(frame)

	frame.Visible = true
	frame.Size = UDim2.new(0, 0, 0, 0)

	-- Faster pop with more bounce
	local tween = TweenService:Create(frame, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = originalSizes[frame]
	})
	tween:Play()
end

-- Snappy Pop-up Close
local function smartPopupClose(frame)
	if not frame or not frame.Visible then return end
	print("MenuController: Closing Frame " .. frame.Name)

	local tween = TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		Size = UDim2.new(0, 0, 0, 0)
	})

	tween.Completed:Connect(function()
		frame.Visible = false
		if originalSizes[frame] then
			frame.Size = originalSizes[frame]
		end
	end)

	tween:Play()
end

local function setupHover(button)
	if not button then return end
	local originalBtnSize = button.Size
	local originalColor = button.BackgroundColor3

	button.MouseEnter:Connect(function()
		local hoverColor = Color3.new(
			math.min(originalColor.R + 0.15, 1),
			math.min(originalColor.G + 0.15, 1),
			math.min(originalColor.B + 0.15, 1)
		)
		TweenService:Create(button, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(originalBtnSize.X.Scale * 1.1, originalBtnSize.X.Offset, originalBtnSize.Y.Scale * 1.1, originalBtnSize.Y.Offset),
			BackgroundColor3 = hoverColor
		}):Play()
	end)

	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = originalBtnSize,
			BackgroundColor3 = originalColor
		}):Play()
	end)
end

-- 1. WAIT FOR HUD (MAIN)
local MainGui = PlayerGui:WaitForChild("Main")
local MainFrame = MainGui:WaitForChild("MainFrame")
local InvButt = MainFrame:WaitForChild("InvButt")
local ShopButt = MainFrame:WaitForChild("ShopButt")

-- 2. WAIT FOR SHOP & INV GUI
local ShopGui = PlayerGui:WaitForChild("ShopGUI")
local ShopFrame = ShopGui:WaitForChild("ShopFrame")
local ShopTicketsFolder = ShopFrame:WaitForChild("Tickets")

local InvGui = PlayerGui:WaitForChild("InvGUI")
local InvFrame = InvGui:WaitForChild("InvFrame")
local InvTicketsZone = InvFrame:WaitForChild("Tickets")

-- Prepare frames
prepareFrame(ShopFrame)
prepareFrame(InvFrame)

-- GUIs Setup
MainGui.Enabled = true
MainGui.DisplayOrder = 5
ShopGui.Enabled = true
ShopGui.DisplayOrder = 10
InvGui.Enabled = true
InvGui.DisplayOrder = 10

-- Interactions
MainFrame.Active = false
ShopFrame.Active = true
InvFrame.Active = true

-- 3. HIDE EVERYTHING AT START
ShopFrame.Visible = false
InvFrame.Visible = false
InvTicketsZone.Visible = true
ShopTicketsFolder.Visible = true

local function closeAllMainMenus()
	smartPopupClose(ShopFrame)
	smartPopupClose(InvFrame)
end

-- 4. CONNECT MAIN BUTTONS
ShopButt.MouseButton1Click:Connect(function()
	if ShopFrame.Visible then
		smartPopupClose(ShopFrame)
	else
		closeAllMainMenus()
		smartPopupOpen(ShopFrame)
	end
end)
setupHover(ShopButt)

InvButt.MouseButton1Click:Connect(function()
	if InvFrame.Visible then
		smartPopupClose(InvFrame)
	else
		closeAllMainMenus()
		smartPopupOpen(InvFrame)
	end
end)
setupHover(InvButt)

-- 5. CLOSE BUTTONS
local ShopClose = ShopFrame:FindFirstChild("CloseButt")
if ShopClose then
	ShopClose.MouseButton1Click:Connect(function()
		smartPopupClose(ShopFrame)
	end)
end

local InvClose = InvFrame:FindFirstChild("CloseButt")
if InvClose then
	InvClose.MouseButton1Click:Connect(function()
		smartPopupClose(InvFrame)
	end)
end

print("MenuController: UI initialized with Super Snappy Centered Animations.")

return {
	smartPopupOpen = smartPopupOpen,
	smartPopupClose = smartPopupClose,
	closeAllMainMenus = closeAllMainMenus,
	setupHover = setupHover
}
