local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Helper function to find frames robustly
local function getFrame(parent, name)
	local frame = parent:FindFirstChild(name)
	if not frame then
		-- Fallback: Find the first Frame if the specific name is missing
		frame = parent:FindFirstChildOfClass("Frame")
	end
	return frame
end

local MainGui = PlayerGui:WaitForChild("Main")
local MainFrame = getFrame(MainGui, "MainFrame")
local ShopButt = MainFrame:WaitForChild("ShopButt")
local InvButt = MainFrame:WaitForChild("InvButt")

local ShopGui = PlayerGui:WaitForChild("ShopGUI")
local ShopFrame = getFrame(ShopGui, "ShopFrame")
local ShopClose = ShopFrame:WaitForChild("CloseButt")

local InvGui = PlayerGui:WaitForChild("InvGUI")
-- User noted InvFrame is actually called ShopFrame in InvGUI in Studio
local InvFrame = getFrame(InvGui, "InvFrame") or getFrame(InvGui, "ShopFrame")
local InvClose = InvFrame:WaitForChild("CloseButt")

-- Fix for Camera Block: Ensure main frames are not "Active" so they don't capture mouse clicks
MainFrame.Active = false
ShopFrame.Active = false
InvFrame.Active = false

local originalSizes = {}

local function smartPopupOpen(frame)
	if not originalSizes[frame] then
		originalSizes[frame] = frame.Size
	end

	frame.Size = UDim2.new(0, 0, 0, 0)
	frame.Visible = true

	TweenService:Create(frame, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = originalSizes[frame]
	}):Play()
end

local function smartPopupClose(frame)
	local tween = TweenService:Create(frame, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Size = UDim2.new(0, 0, 0, 0)
	})

	tween.Completed:Connect(function()
		frame.Visible = false
		frame.Size = originalSizes[frame]
	end)

	tween:Play()
end

local function setupHover(button)
	local originalSize = button.Size
	local originalColor = button.BackgroundColor3
	local hoverColor = Color3.new(
		math.min(originalColor.R + 0.1, 1),
		math.min(originalColor.G + 0.1, 1),
		math.min(originalColor.B + 0.1, 1)
	)

	button.MouseEnter:Connect(function()
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

local function setupTabs(container, buttons, folders)
	for i, button in ipairs(buttons) do
		button.MouseButton1Click:Connect(function()
			for _, folder in ipairs(folders) do
				folder.Visible = false
			end
			if folders[i] then
				folders[i].Visible = true
			end
		end)
	end
end

-- Hide all UI on Start
ShopFrame.Visible = false
InvFrame.Visible = false
for _, guiName in ipairs({"ScratchSimpleGUI", "ScratchRareGUI", "ScratchGOLDENGUI"}) do
	local gui = PlayerGui:FindFirstChild(guiName)
	if gui then
		local frame = gui:FindFirstChildOfClass("Frame")
		if frame then
			frame.Visible = false
			frame.Active = false -- Ensure camera isn't blocked by these either
		end
	end
end

ShopButt.MouseButton1Click:Connect(function()
	if ShopFrame.Visible then
		smartPopupClose(ShopFrame)
	else
		if InvFrame.Visible then smartPopupClose(InvFrame) end
		smartPopupOpen(ShopFrame)
	end
end)

InvButt.MouseButton1Click:Connect(function()
	if InvFrame.Visible then
		smartPopupClose(InvFrame)
	else
		if ShopFrame.Visible then smartPopupClose(ShopFrame) end
		smartPopupOpen(InvFrame)
	end
end)

ShopClose.MouseButton1Click:Connect(function()
	smartPopupClose(ShopFrame)
end)

InvClose.MouseButton1Click:Connect(function()
	smartPopupClose(InvFrame)
end)

local shopButtons = {
	ShopFrame:WaitForChild("TicketsSHOP"),
	ShopFrame:WaitForChild("ItemsSHOP"),
	ShopFrame:WaitForChild("MoneySHOP"),
	ShopFrame:WaitForChild("PrestigeSHOP")
}
local shopFolders = {
	ShopFrame:WaitForChild("Tickets")
}
setupTabs(ShopFrame, shopButtons, shopFolders)

local invButtons = {
	InvFrame:WaitForChild("TicketsINV"),
	InvFrame:WaitForChild("ItemsINV")
}
-- Tickets folder is either a child of InvFrame or InvGUI
local invTicketsZone = InvFrame:FindFirstChild("Tickets") or InvGui:FindFirstChild("Tickets")
setupTabs(InvFrame, invButtons, {invTicketsZone})

setupHover(ShopButt)
setupHover(InvButt)
for _, btn in ipairs(shopButtons) do setupHover(btn) end
for _, btn in ipairs(invButtons) do setupHover(btn) end

return {
	smartPopupOpen = smartPopupOpen,
	smartPopupClose = smartPopupClose,
	setupHover = setupHover
}
