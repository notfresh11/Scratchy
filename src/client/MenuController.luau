local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

print("MenuController: Initializing UI references...")

-- Utility for Pop-up Tweens (SIMPLIFIED FOR DEBUGGING)
local function smartPopupOpen(frame)
	if not frame then return end
	print("MenuController: Opening Frame " .. frame.Name)
	frame.Visible = true
	-- Removed Tweening and Size manipulation to ensure visibility
end

local function smartPopupClose(frame)
	if not frame then return end
	print("MenuController: Closing Frame " .. frame.Name)
	frame.Visible = false
end

local function setupHover(button)
	if not button then return end
	local originalSize = button.Size
	local originalColor = button.BackgroundColor3

	button.MouseEnter:Connect(function()
		local hoverColor = Color3.new(
			math.min(originalColor.R + 0.1, 1),
			math.min(originalColor.G + 0.1, 1),
			math.min(originalColor.B + 0.1, 1)
		)
		TweenService:Create(button, TweenInfo.new(0.1), {
			Size = UDim2.new(originalSize.X.Scale * 1.05, originalSize.X.Offset, originalSize.Y.Scale * 1.05, originalSize.Y.Offset),
			BackgroundColor3 = hoverColor
		}):Play()
	end)

	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.1), {
			Size = originalSize,
			BackgroundColor3 = originalColor
		}):Play()
	end)
end

-- 1. WAIT FOR HUD (MAIN)
local MainGui = PlayerGui:WaitForChild("Main", 10)
local MainFrame = MainGui and MainGui:WaitForChild("MainFrame", 10)
local InvButt = MainFrame and MainFrame:WaitForChild("InvButt", 10)
local ShopButt = MainFrame and MainFrame:WaitForChild("ShopButt", 10)

if InvButt then print("MenuController: InvButt found") end
if ShopButt then print("MenuController: ShopButt found") end

-- 2. WAIT FOR SHOP & INV GUI
local ShopGui = PlayerGui:WaitForChild("ShopGUI", 10)
local ShopFrame = ShopGui and ShopGui:WaitForChild("ShopFrame", 10)
local ShopTicketsFolder = ShopGui and ShopGui:WaitForChild("Tickets", 10)

local InvGui = PlayerGui:WaitForChild("InvGUI", 10)
local InvFrame = InvGui and InvGui:WaitForChild("ShopFrame", 10)
local InvTicketsZone = InvGui and InvGui:WaitForChild("Tickets", 10)

-- Fix for Camera Block & Ensuring interaction
if MainFrame then MainFrame.Active = false MainFrame.ZIndex = 5 end
if ShopFrame then ShopFrame.Active = false ShopFrame.ZIndex = 10 end
if InvFrame then InvFrame.Active = false InvFrame.ZIndex = 10 end
if InvButt then InvButt.ZIndex = 15 end
if ShopButt then ShopButt.ZIndex = 15 end

-- 3. HIDE EVERYTHING AT START
if ShopFrame then ShopFrame.Visible = false end
if InvFrame then InvFrame.Visible = false end
if InvTicketsZone then InvTicketsZone.Visible = false end
if ShopTicketsFolder then ShopTicketsFolder.Visible = false end

-- 4. CONNECT MAIN BUTTONS
if ShopButt and ShopFrame then
	ShopButt.MouseButton1Click:Connect(function()
		print("MenuController: ShopButt Clicked")
		if ShopFrame.Visible then
			smartPopupClose(ShopFrame)
			if ShopTicketsFolder then ShopTicketsFolder.Visible = false end
		else
			if InvFrame and InvFrame.Visible then
				smartPopupClose(InvFrame)
				if InvTicketsZone then InvTicketsZone.Visible = false end
			end
			smartPopupOpen(ShopFrame)
			if ShopTicketsFolder then ShopTicketsFolder.Visible = true end
		end
	end)
	setupHover(ShopButt)
end

if InvButt and InvFrame then
	InvButt.MouseButton1Click:Connect(function()
		print("MenuController: InvButt Clicked")
		if InvFrame.Visible then
			smartPopupClose(InvFrame)
			if InvTicketsZone then InvTicketsZone.Visible = false end
		else
			if ShopFrame and ShopFrame.Visible then
				smartPopupClose(ShopFrame)
				if ShopTicketsFolder then ShopTicketsFolder.Visible = false end
			end
			smartPopupOpen(InvFrame)
			if InvTicketsZone then InvTicketsZone.Visible = true end
		end
	end)
	setupHover(InvButt)
end

-- 5. CLOSE BUTTONS
if ShopFrame then
	local ShopClose = ShopFrame:FindFirstChild("CloseButt")
	if ShopClose then
		ShopClose.MouseButton1Click:Connect(function()
			smartPopupClose(ShopFrame)
			if ShopTicketsFolder then ShopTicketsFolder.Visible = false end
		end)
	end
end

if InvFrame then
	local InvClose = InvFrame:FindFirstChild("CloseButt")
	if InvClose then
		InvClose.MouseButton1Click:Connect(function()
			smartPopupClose(InvFrame)
			if InvTicketsZone then InvTicketsZone.Visible = false end
		end)
	end
end

-- 6. TICKET TABS
if ShopFrame then
	local ticketsShopButt = ShopFrame:FindFirstChild("TicketsSHOP")
	if ticketsShopButt then
		ticketsShopButt.MouseButton1Click:Connect(function()
			if ShopTicketsFolder then ShopTicketsFolder.Visible = true end
		end)
		setupHover(ticketsShopButt)
	end
end

if InvFrame then
	local ticketsInvButt = InvFrame:FindFirstChild("TicketsINV")
	if ticketsInvButt then
		ticketsInvButt.MouseButton1Click:Connect(function()
			if InvTicketsZone then InvTicketsZone.Visible = true end
		end)
		setupHover(ticketsInvButt)
	end
end

print("MenuController: UI initialized (DEBUG MODE - NO TWEENS).")

return {
	smartPopupOpen = smartPopupOpen,
	smartPopupClose = smartPopupClose,
	setupHover = setupHover
}
