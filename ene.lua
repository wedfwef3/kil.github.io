local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local rs = game:GetService("RunService")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local Theme = {
    Background = Color3.fromRGB(15, 15, 15),
    Button = Color3.fromRGB(30, 30, 30),
    Text = Color3.fromRGB(255, 255, 255)
}

local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
screenGui.Name = "GardenHubUI"

local MainFrame = Instance.new("Frame", screenGui)
MainFrame.Size = UDim2.new(0, 400, 0, 280)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.BackgroundColor3 = Theme.Background
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

local frameOutline = Instance.new("UIStroke")
frameOutline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
frameOutline.Thickness = 3
frameOutline.Parent = MainFrame
local hue = 0
rs.RenderStepped:Connect(function()
    hue = (hue + 0.005) % 1
    frameOutline.Color = Color3.fromHSV(hue, 1, 1)
end)

local Title = Instance.new("TextLabel", MainFrame)
Title.Text = "Garden Script Hub"
Title.Size = UDim2.new(1, -20, 0, 28)
Title.Position = UDim2.new(0, 10, 0, 5)
Title.BackgroundTransparency = 1
Title.TextColor3 = Theme.Text
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18

local TabsFrame = Instance.new("Frame", MainFrame)
TabsFrame.Size = UDim2.new(0, 120, 1, -40)
TabsFrame.Position = UDim2.new(0, 10, 0, 35)
TabsFrame.BackgroundColor3 = Theme.Button
Instance.new("UICorner", TabsFrame).CornerRadius = UDim.new(0, 6)

local TabContentFrame = Instance.new("Frame", MainFrame)
TabContentFrame.Size = UDim2.new(1, -140, 1, -40)
TabContentFrame.Position = UDim2.new(0, 130, 0, 35)
TabContentFrame.BackgroundColor3 = Theme.Background
TabContentFrame.ClipsDescendants = true
Instance.new("UICorner", TabContentFrame).CornerRadius = UDim.new(0, 6)

local Tabs = {}

local function CreateTab(tabName)
    local TabButton = Instance.new("TextButton", TabsFrame)
    TabButton.Text = tabName
    TabButton.Size = UDim2.new(1, -10, 0, 32)
    TabButton.Position = UDim2.new(0, 5, 0, (#Tabs * 37))
    TabButton.BackgroundColor3 = Theme.Button
    TabButton.TextColor3 = Theme.Text
    TabButton.Font = Enum.Font.GothamBold
    TabButton.TextSize = 16
    Instance.new("UICorner", TabButton).CornerRadius = UDim.new(0, 6)

    local TabFrame = Instance.new("Frame", TabContentFrame)
    TabFrame.Size = UDim2.new(1, 0, 1, 0)
    TabFrame.Visible = (#Tabs == 0)
    TabFrame.BackgroundTransparency = 1
    table.insert(Tabs, TabFrame)

    TabButton.MouseButton1Click:Connect(function()
        for _, frame in pairs(Tabs) do
            frame.Visible = false
        end
        TabFrame.Visible = true
    end)
    return TabFrame
end

local function CreateButton(parent, text, callback, position)
    local Button = Instance.new("TextButton", parent)
    Button.Text = text
    Button.Size = UDim2.new(0.9, 0, 0, 36)
    Button.Position = position
    Button.BackgroundColor3 = Theme.Button
    Button.TextColor3 = Theme.Text
    Button.Font = Enum.Font.Gotham
    Button.TextSize = 15
    Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 6)
    Button.MouseEnter:Connect(function()
        Button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    end)
    Button.MouseLeave:Connect(function()
        Button.BackgroundColor3 = Theme.Button
    end)
    Button.MouseButton1Click:Connect(callback)
    return Button
end

-- STATE & LOGIC FROM GARDEN CODE

local autoSeedsEnabled = false
local autoToolsEnabled = false
local autoPetsEnabled = false
local autoEventItemsEnabled = false

local function RemovePartsWithoutPrompts(parent)
    local removed = 0
    for _, child in ipairs(parent:GetChildren()) do
        if child:IsA("Model") then
            removed = removed + RemovePartsWithoutPrompts(child)
        elseif child:IsA("BasePart") then
            local hasPrompt = false
            for _, desc in ipairs(child:GetDescendants()) do
                if desc:IsA("ProximityPrompt") then
                    hasPrompt = true
                    break
                end
            end
            if not hasPrompt then
                child:Destroy()
                removed = removed + 1
            end
        end
    end
    return removed
end

local function ProcessFarmWithFeedback()
    for _, farmChild in ipairs(workspace:FindFirstChild("Farm") and workspace.Farm:GetChildren() or {}) do
        local important = farmChild:FindFirstChild("Important")
        if important then
            local plantsPhysical = important:FindFirstChild("Plants_Physical")
            if plantsPhysical then
                for _, plantModel in ipairs(plantsPhysical:GetChildren()) do
                    if plantModel:IsA("Model") then
                        RemovePartsWithoutPrompts(plantModel)
                    end
                end
            end
        end
    end
end

local SEED_RARITY_ORDER = {
    ["Prismatic"] = 7, ["Divine"] = 6, ["Mythical"] = 5,
    ["Legendary"] = 4, ["Rare"] = 3, ["Uncommon"] = 2, ["Common"] = 1
}
local function getSeedShopFrame()
    local gui = player.PlayerGui:FindFirstChild("Seed_Shop")
    if gui then
        local frame = gui:FindFirstChild("Frame")
        if frame then
            return frame:FindFirstChild("ScrollingFrame")
        end
    end
end
local function getSortedSeeds()
    local seeds = {}
    local scrollingFrame = getSeedShopFrame()
    if not scrollingFrame then return seeds end
    for _, seedFrame in ipairs(scrollingFrame:GetChildren()) do
        local rarityText = seedFrame:FindFirstChild("Main_Frame") and seedFrame.Main_Frame:FindFirstChild("Rarity_Text")
        if rarityText then
            table.insert(seeds, {
                name = seedFrame.Name,
                rarity = rarityText.Text,
                level = SEED_RARITY_ORDER[rarityText.Text] or 0
            })
        end
    end
    table.sort(seeds, function(a, b) return a.level > b.level end)
    return seeds
end
local function purchaseSeedsSequentially(seeds, index)
    if not autoSeedsEnabled or not seeds[index] then return end
    ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("BuySeedStock"):FireServer(seeds[index].name)
    task.delay(0.1, function() purchaseSeedsSequentially(seeds, index + 1) end)
end
local function autoPurchaseSeedsByRarity()
    while autoSeedsEnabled do
        local sortedSeeds = getSortedSeeds()
        if #sortedSeeds > 0 then
            purchaseSeedsSequentially(sortedSeeds, 1)
        end
        task.wait(0.1)
    end
end

local GEARS_RARITY_ORDER = SEED_RARITY_ORDER
local function getGearShopFrame()
    local gui = player.PlayerGui:FindFirstChild("Gear_Shop")
    if gui then
        local frame = gui:FindFirstChild("Frame")
        if frame then
            return frame:FindFirstChild("ScrollingFrame")
        end
    end
end
local function getSortedGears()
    local gears = {}
    local scrollingFrame = getGearShopFrame()
    if not scrollingFrame then return gears end
    for _, gearFrame in ipairs(scrollingFrame:GetChildren()) do
        local rarityText = gearFrame:FindFirstChild("Main_Frame") and gearFrame.Main_Frame:FindFirstChild("Rarity_Text")
        if rarityText then
            table.insert(gears, {
                name = gearFrame.Name,
                rarity = rarityText.Text,
                level = GEARS_RARITY_ORDER[rarityText.Text] or 0
            })
        end
    end
    table.sort(gears, function(a, b) return a.level > b.level end)
    return gears
end
local function purchaseGearsSequentially(gears, index)
    if not autoToolsEnabled or not gears[index] then return end
    ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("BuyGearStock"):FireServer(gears[index].name)
    task.delay(0.1, function() purchaseGearsSequentially(gears, index + 1) end)
end
local function autoPurchaseGearsByRarity()
    while autoToolsEnabled do
        local sortedGears = getSortedGears()
        if #sortedGears > 0 then
            purchaseGearsSequentially(sortedGears, 1)
        end
        task.wait(0.11)
    end
end

local EVENT_ITEMS_RARITY_ORDER = SEED_RARITY_ORDER
local function getEventShopFrame()
    local eventShopUI = player.PlayerGui:FindFirstChild("EventShop_UI")
    if eventShopUI then
        local frame = eventShopUI:FindFirstChild("Frame")
        if frame then
            return frame:FindFirstChild("ScrollingFrame")
        end
    end
end
local function getSortedEventItems()
    local items = {}
    local scrollingFrame = getEventShopFrame()
    if not scrollingFrame then return items end
    for _, itemFrame in ipairs(scrollingFrame:GetChildren()) do
        local rarityText = itemFrame:FindFirstChild("Main_Frame") and itemFrame.Main_Frame:FindFirstChild("Rarity_Text")
        if rarityText then
            table.insert(items, {
                name = itemFrame.Name,
                rarity = rarityText.Text,
                level = EVENT_ITEMS_RARITY_ORDER[rarityText.Text] or 0
            })
        end
    end
    table.sort(items, function(a, b) return a.level > b.level end)
    return items
end
local function purchaseEventItemsSequentially(items, index)
    if not autoEventItemsEnabled or not items[index] then return end
    ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("BuyEventShopStock"):FireServer(items[index].name)
    task.delay(0.1, function() purchaseEventItemsSequentially(items, index + 1) end)
end
local function autoPurchaseEventItemsByRarity()
    while autoEventItemsEnabled do
        local sortedItems = getSortedEventItems()
        if #sortedItems > 0 then
            purchaseEventItemsSequentially(sortedItems, 1)
        end
        task.wait(0.11)
    end
end

-- === TABS ===

local MainTab = CreateTab("Main")
local ShopTab = CreateTab("Shops")
local AutoTab = CreateTab("Automation")
local ToolsTab = CreateTab("Tools")

-- MainTab buttons
CreateButton(MainTab, "Teleport to Tool Shop", function()
    local character = player.Character
    if character and character:FindFirstChild("HumanoidRootPart") and workspace:FindFirstChild("Tutorial_Points") and workspace.Tutorial_Points:FindFirstChild("Tutorial_Point_3") then
        character.HumanoidRootPart.CFrame = workspace.Tutorial_Points.Tutorial_Point_3.CFrame
    end
end, UDim2.new(0.05, 0, 0, 10))

CreateButton(MainTab, "Remove Plant Parts", ProcessFarmWithFeedback, UDim2.new(0.05, 0, 0, 56))

-- ShopTab buttons
CreateButton(ShopTab, "Toggle Seed Shop UI", function()
    local seedShop = player.PlayerGui:FindFirstChild("Seed_Shop")
    if seedShop then
        seedShop.Enabled = not seedShop.Enabled
    end
end, UDim2.new(0.05, 0, 0, 10))
CreateButton(ShopTab, "Toggle Gear Shop UI", function()
    local gearShop = player.PlayerGui:FindFirstChild("Gear_Shop")
    if gearShop then
        gearShop.Enabled = not gearShop.Enabled
    end
end, UDim2.new(0.05, 0, 0, 56))
CreateButton(ShopTab, "Toggle Quests UI", function()
    local dailyQuestsUI = player.PlayerGui:FindFirstChild("DailyQuests_UI")
    if dailyQuestsUI then
        dailyQuestsUI.Enabled = not dailyQuestsUI.Enabled
    end
end, UDim2.new(0.05, 0, 0, 102))
CreateButton(ShopTab, "Toggle Event Shop UI", function()
    local eventShop = player.PlayerGui:FindFirstChild("EventShop_UI")
    if eventShop then
        eventShop.Enabled = not eventShop.Enabled
    end
end, UDim2.new(0.05, 0, 0, 148))

-- Automation Tab Buttons
local autoSeedsBtn = CreateButton(AutoTab, "Auto Seeds: Off", function()
    autoSeedsEnabled = not autoSeedsEnabled
    autoSeedsBtn.Text = "Auto Seeds: " .. (autoSeedsEnabled and "On" or "Off")
    autoSeedsBtn.BackgroundColor3 = autoSeedsEnabled and Color3.fromRGB(34, 177, 76) or Theme.Button
    if autoSeedsEnabled then
        spawn(autoPurchaseSeedsByRarity)
    end
end, UDim2.new(0.05, 0, 0, 10))

local autoToolsBtn = CreateButton(AutoTab, "Auto Tools: Off", function()
    autoToolsEnabled = not autoToolsEnabled
    autoToolsBtn.Text = "Auto Tools: " .. (autoToolsEnabled and "On" or "Off")
    autoToolsBtn.BackgroundColor3 = autoToolsEnabled and Color3.fromRGB(0, 162, 232) or Theme.Button
    if autoToolsEnabled then
        spawn(autoPurchaseGearsByRarity)
    end
end, UDim2.new(0.05, 0, 0, 56))

local autoPetsBtn = CreateButton(AutoTab, "Auto Pets: Off", function()
    autoPetsEnabled = not autoPetsEnabled
    autoPetsBtn.Text = "Auto Pets: " .. (autoPetsEnabled and "On" or "Off")
    autoPetsBtn.BackgroundColor3 = autoPetsEnabled and Color3.fromRGB(255, 0, 255) or Theme.Button
    if autoPetsEnabled then
        spawn(function()
            while autoPetsEnabled do
                local buyEvent = ReplicatedStorage:FindFirstChild("GameEvents") and ReplicatedStorage.GameEvents:FindFirstChild("BuyPetEgg")
                if buyEvent then
                    for i = 1, 3 do
                        if not autoPetsEnabled then break end
                        buyEvent:FireServer(i)
                        task.wait(0.1)
                    end
                end
                task.wait(0.1)
            end
        end)
    end
end, UDim2.new(0.05, 0, 0, 102))

local autoEventItemsBtn = CreateButton(AutoTab, "Auto Event Items: Off", function()
    autoEventItemsEnabled = not autoEventItemsEnabled
    autoEventItemsBtn.Text = "Auto Event Items: " .. (autoEventItemsEnabled and "On" or "Off")
    autoEventItemsBtn.BackgroundColor3 = autoEventItemsEnabled and Color3.fromRGB(255, 201, 14) or Theme.Button
    if autoEventItemsEnabled then
        spawn(autoPurchaseEventItemsByRarity)
    end
end, UDim2.new(0.05, 0, 0, 148))

-- Tools Tab
CreateButton(ToolsTab, "Open Console", function()
    game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.F9, false, game)
end, UDim2.new(0.05, 0, 0, 10))

CreateButton(ToolsTab, "Close UI", function()
    screenGui:Destroy()
end, UDim2.new(0.05, 0, 0, 56))

-- Minimize/Show
local minimizeButton = Instance.new("TextButton", MainFrame)
minimizeButton.Text = "-"
minimizeButton.Size = UDim2.new(0, 24, 0, 24)
minimizeButton.Position = UDim2.new(1, -30, 0, 8)
minimizeButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
minimizeButton.TextColor3 = Theme.Text
Instance.new("UICorner", minimizeButton).CornerRadius = UDim.new(0, 6)

local reopenButton = Instance.new("TextButton", screenGui)
reopenButton.Text = "Open Garden Hub"
reopenButton.Size = UDim2.new(0, 160, 0, 32)
reopenButton.Position = UDim2.new(0.5, 0, 0, -40)
reopenButton.AnchorPoint = Vector2.new(0.5, 0)
reopenButton.Visible = false
reopenButton.BackgroundColor3 = Theme.Button
reopenButton.TextColor3 = Theme.Text
Instance.new("UICorner", reopenButton).CornerRadius = UDim.new(0, 6)

local isMinimized = false
minimizeButton.MouseButton1Click:Connect(function()
    if not isMinimized then
        isMinimized = true
        TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Position = UDim2.new(0.5, 0, -0.7, 0),
            Size = UDim2.new(0, 200, 0, 50)
        }):Play()
        wait(0.3)
        MainFrame.Visible = false
        reopenButton.Visible = true
    end
end)
reopenButton.MouseButton1Click:Connect(function()
    if isMinimized then
        isMinimized = false
        reopenButton.Visible = false
        MainFrame.Visible = true
        TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(0, 400, 0, 280)
        }):Play()
    end
end)

-- Drag main frame
local dragToggle = false
local dragStart, startPos, dragInput
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragToggle = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)
MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)
MainFrame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragToggle = false
    end
end)
UIS.InputChanged:Connect(function(input)
    if dragToggle and input == dragInput then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)
