local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

print("MenuController: Initializing UI references...")

local originalSizes = {}

-- Utility for Pop-up Tweens
local function smartPopupOpen(frame)
	if not frame then return end
	print("MenuController: Opening Frame " .. frame.Name)

	if not originalSizes[frame] then
		originalSizes[frame] = frame.Size
	end

	frame.Visible = true
	frame.Size = UDim2.new(0, 0, 0, 0)

	local tween = TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = originalSizes[frame]
	})
	tween:Play()
end

local function smartPopupClose(frame)
	if not frame then return end
	print("MenuController: Closing Frame " .. frame.Name)

	local tween = TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
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
			math.min(originalColor.R + 0.1, 1),
			math.min(originalColor.G + 0.1, 1),
			math.min(originalColor.B + 0.1, 1)
		)
		TweenService:Create(button, TweenInfo.new(0.1), {
			Size = UDim2.new(originalBtnSize.X.Scale * 1.05, originalBtnSize.X.Offset, originalBtnSize.Y.Scale * 1.05, originalBtnSize.Y.Offset),
			BackgroundColor3 = hoverColor
		}):Play()
	end)

	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.1), {
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

-- Ensure GUIs are Enabled and have correct DisplayOrder
MainGui.Enabled = true
MainGui.DisplayOrder = 5

ShopGui.Enabled = true
ShopGui.DisplayOrder = 10

InvGui.Enabled = true
InvGui.DisplayOrder = 10

-- Capture original sizes before hiding
originalSizes[ShopFrame] = ShopFrame.Size
originalSizes[InvFrame] = InvFrame.Size

-- Fix for Camera Block & Ensuring interaction
MainFrame.Active = false
ShopFrame.Active = true -- Frames themselves should be active to catch clicks
InvFrame.Active = true

-- 3. HIDE EVERYTHING AT START
ShopFrame.Visible = false
InvFrame.Visible = false
InvTicketsZone.Visible = false
ShopTicketsFolder.Visible = false

-- 4. CONNECT MAIN BUTTONS
ShopButt.MouseButton1Click:Connect(function()
	print("MenuController: ShopButt Clicked. Current Visibility: " .. tostring(ShopFrame.Visible))
	if ShopFrame.Visible then
		smartPopupClose(ShopFrame)
		ShopTicketsFolder.Visible = false
	else
		if InvFrame.Visible then
			smartPopupClose(InvFrame)
			InvTicketsZone.Visible = false
		end
		smartPopupOpen(ShopFrame)
		ShopTicketsFolder.Visible = true
	end
end)
setupHover(ShopButt)

InvButt.MouseButton1Click:Connect(function()
	print("MenuController: InvButt Clicked. Current Visibility: " .. tostring(InvFrame.Visible))
	if InvFrame.Visible then
		smartPopupClose(InvFrame)
		InvTicketsZone.Visible = false
	else
		if ShopFrame.Visible then
			smartPopupClose(ShopFrame)
			ShopTicketsFolder.Visible = false
		end
		smartPopupOpen(InvFrame)
		InvTicketsZone.Visible = true
	end
end)
setupHover(InvButt)

-- 5. CLOSE BUTTONS
local ShopClose = ShopFrame:FindFirstChild("CloseButt")
if ShopClose then
	ShopClose.MouseButton1Click:Connect(function()
		smartPopupClose(ShopFrame)
		ShopTicketsFolder.Visible = false
	end)
end

local InvClose = InvFrame:FindFirstChild("CloseButt")
if InvClose then
	InvClose.MouseButton1Click:Connect(function()
		smartPopupClose(InvFrame)
		InvTicketsZone.Visible = false
	end)
end

-- 6. TICKET TABS
local ticketsShopButt = ShopFrame:FindFirstChild("TicketsSHOP")
if ticketsShopButt then
	ticketsShopButt.MouseButton1Click:Connect(function()
		ShopTicketsFolder.Visible = true
	end)
	setupHover(ticketsShopButt)
end

local ticketsInvButt = InvFrame:FindFirstChild("TicketsINV")
if ticketsInvButt then
	ticketsInvButt.MouseButton1Click:Connect(function()
		InvTicketsZone.Visible = true
	end)
	setupHover(ticketsInvButt)
end

print("MenuController: UI initialized with Animations and DisplayOrder fix.")

return {
	smartPopupOpen = smartPopupOpen,
	smartPopupClose = smartPopupClose,
	setupHover = setupHover
}
