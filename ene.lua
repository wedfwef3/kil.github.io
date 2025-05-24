local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local autoSeedsEnabled = false
local autoToolsEnabled = false
local autoPetsEnabled = false
local autoEventItemsEnabled = false

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "UniversalUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local gameName = MarketplaceService:GetProductInfo(game.PlaceId).Name

local buttonStyle = {
    Size = UDim2.new(0, 120, 0, 30),
    BackgroundColor3 = Color3.new(0.1, 0.1, 0.1),
    BackgroundTransparency = 0.5,
    Font = Enum.Font.SourceSansBold,
    TextSize = 16
}

local function createButton(name, position, color, callback)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = buttonStyle.Size
    button.Position = position
    button.Text = name
    button.TextColor3 = color
    button.BackgroundColor3 = buttonStyle.BackgroundColor3
    button.BackgroundTransparency = buttonStyle.BackgroundTransparency
    button.Font = buttonStyle.Font
    button.TextSize = buttonStyle.TextSize
    button.Parent = screenGui
    if callback then
        button.MouseButton1Click:Connect(callback)
    end
    return button
end

local function RemovePartsWithoutPrompts(parent)
    local removed = 0
    local children = parent:GetChildren()
    for i = #children, 1, -1 do
        local child = children[i]
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
    ["Prismatic"] = 7,
    ["Divine"] = 6,
    ["Mythical"] = 5,
    ["Legendary"] = 4,
    ["Rare"] = 3,
    ["Uncommon"] = 2,
    ["Common"] = 1
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
    table.sort(seeds, function(a, b)
        return a.level > b.level
    end)
    return seeds
end
local function purchaseSeedsSequentially(seeds, index)
    if not autoSeedsEnabled or not seeds[index] then return end
    ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("BuySeedStock"):FireServer(seeds[index].name)
    task.delay(0.1, function()
        purchaseSeedsSequentially(seeds, index + 1)
    end)
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

local GEARS_RARITY_ORDER = {
    ["Prismatic"] = 7,
    ["Divine"] = 6,
    ["Mythical"] = 5,
    ["Legendary"] = 4,
    ["Rare"] = 3,
    ["Uncommon"] = 2,
    ["Common"] = 1
}
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
    table.sort(gears, function(a, b)
        return a.level > b.level
    end)
    return gears
end
local function purchaseGearsSequentially(gears, index)
    if not autoToolsEnabled or not gears[index] then return end
    ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("BuyGearStock"):FireServer(gears[index].name)
    task.delay(0.1, function()
        purchaseGearsSequentially(gears, index + 1)
    end)
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

local EVENT_ITEMS_RARITY_ORDER = {
    ["Prismatic"] = 7,
    ["Divine"] = 6,
    ["Mythical"] = 5,
    ["Legendary"] = 4,
    ["Rare"] = 3,
    ["Uncommon"] = 2,
    ["Common"] = 1
}
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
    table.sort(items, function(a, b)
        return a.level > b.level
    end)
    return items
end
local function purchaseEventItemsSequentially(items, index)
    if not autoEventItemsEnabled or not items[index] then return end
    ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("BuyEventShopStock"):FireServer(items[index].name)
    task.delay(0.1, function()
        purchaseEventItemsSequentially(items, index + 1)
    end)
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

local hideButton = createButton("Hide UI", UDim2.new(0, 10, 0, 10), Color3.new(1, 0.5, 0))
local isHidden = false

createButton("Close UI", UDim2.new(0, 10, 0, 50), Color3.new(1, 0, 0), function()
    screenGui:Destroy()
end)

createButton("Console", UDim2.new(0, 10, 0, 90), Color3.new(1, 1, 0.5), function()
    game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.F9, false, game)
end)

createButton("Teleport to Tool Shop", UDim2.new(0, 270, 0, 10), Color3.new(0, 1, 1), function()
    local character = player.Character
    if character and character:FindFirstChild("HumanoidRootPart") and workspace:FindFirstChild("Tutorial_Points") and workspace.Tutorial_Points:FindFirstChild("Tutorial_Point_3") then
        character.HumanoidRootPart.CFrame = workspace.Tutorial_Points.Tutorial_Point_3.CFrame
    end
end)

local autoSeedsButton = createButton("Auto Seeds: Off", UDim2.new(0, 140, 0, 10), Color3.new(0.5, 1, 0.5))
autoSeedsButton.MouseButton1Click:Connect(function()
    autoSeedsEnabled = not autoSeedsEnabled
    autoSeedsButton.Text = "Auto Seeds: " .. (autoSeedsEnabled and "On" or "Off")
    autoSeedsButton.TextColor3 = autoSeedsEnabled and Color3.new(0, 1, 0) or Color3.new(0.5, 1, 0.5)
    if autoSeedsEnabled then
        spawn(autoPurchaseSeedsByRarity)
    end
end)

local autoToolsButton = createButton("Auto Tools: Off", UDim2.new(0, 140, 0, 50), Color3.new(0.5, 0.5, 1))
autoToolsButton.MouseButton1Click:Connect(function()
    autoToolsEnabled = not autoToolsEnabled
    autoToolsButton.Text = "Auto Tools: " .. (autoToolsEnabled and "On" or "Off")
    autoToolsButton.TextColor3 = autoToolsEnabled and Color3.new(0, 0, 1) or Color3.new(0.5, 0.5, 1)
    if autoToolsEnabled then
        spawn(autoPurchaseGearsByRarity)
    end
end)

local autoPetsButton = createButton("Auto Pets: Off", UDim2.new(0, 140, 0, 90), Color3.new(1, 0.5, 1))
autoPetsButton.MouseButton1Click:Connect(function()
    autoPetsEnabled = not autoPetsEnabled
    autoPetsButton.Text = "Auto Pets: " .. (autoPetsEnabled and "On" or "Off")
    autoPetsButton.TextColor3 = autoPetsEnabled and Color3.new(1, 0, 1) or Color3.new(1, 0.5, 1)
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
end)

local autoEventItemsButton = createButton("Auto Event Items: Off", UDim2.new(0, 140, 0, 130), Color3.new(1, 0.8, 0.4))
autoEventItemsButton.MouseButton1Click:Connect(function()
    autoEventItemsEnabled = not autoEventItemsEnabled
    autoEventItemsButton.Text = "Auto Event Items: " .. (autoEventItemsEnabled and "On" or "Off")
    autoEventItemsButton.TextColor3 = autoEventItemsEnabled and Color3.new(1, 0.6, 0) or Color3.new(1, 0.8, 0.4)
    if autoEventItemsEnabled then
        spawn(autoPurchaseEventItemsByRarity)
    end
end)

createButton("Remove Plant Parts", UDim2.new(0, 270, 0, 50), Color3.new(1, 0.3, 0.3), ProcessFarmWithFeedback)

createButton("Seed Shop UI", UDim2.new(0, 270, 0, 90), Color3.new(0.5, 1, 0.5), function()
    local seedShop = player.PlayerGui:FindFirstChild("Seed_Shop")
    if seedShop then
        seedShop.Enabled = not seedShop.Enabled
    end
end)
createButton("Gear Shop UI", UDim2.new(0, 270, 0, 130), Color3.new(0.5, 0.5, 1), function()
    local gearShop = player.PlayerGui:FindFirstChild("Gear_Shop")
    if gearShop then
        gearShop.Enabled = not gearShop.Enabled
    end
end)
createButton("Quests UI", UDim2.new(0, 270, 0, 170), Color3.new(1, 0.5, 0.5), function()
    local dailyQuestsUI = player.PlayerGui:FindFirstChild("DailyQuests_UI")
    if dailyQuestsUI then
        dailyQuestsUI.Enabled = not dailyQuestsUI.Enabled
    end
end)
createButton("Event Shop UI", UDim2.new(0, 400, 0, 10), Color3.new(1, 1, 0), function()
    local eventShop = player.PlayerGui:FindFirstChild("EventShop_UI")
    if eventShop then
        eventShop.Enabled = not eventShop.Enabled
    end
end)

local dragging = false 
local dragInput 
local dragStart = nil 
local startPositions = {}

for _, child in ipairs(screenGui:GetChildren()) do
    if child:IsA("TextButton") then
        startPositions[child] = child.Position
    end
end

local function updatePos(input) 
    if not dragStart then return end
    local delta = input.Position - dragStart 
    for button, startPos in pairs(startPositions) do
        button.Position = UDim2.new(
            startPos.X.Scale, 
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end 

hideButton.InputBegan:Connect(function(input) 
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
        dragging = true 
        dragStart = input.Position
        for _, child in ipairs(screenGui:GetChildren()) do
            if child:IsA("TextButton") then
                startPositions[child] = child.Position
            end
        end
        input.Changed:Connect(function() 
            if input.UserInputState == Enum.UserInputState.End then 
                dragging = false 
            end 
        end) 
    end 
end) 
hideButton.InputChanged:Connect(function(input) 
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then 
        dragInput = input 
    end 
end) 
game:GetService("UserInputService").InputChanged:Connect(function(input) 
    if dragging and input == dragInput then 
        updatePos(input) 
    end 
end)

hideButton.MouseButton1Click:Connect(function()
    isHidden = not isHidden
    for _, child in ipairs(screenGui:GetChildren()) do
        if child:IsA("TextButton") and child ~= hideButton then
            child.Visible = not isHidden
        end
    end
    hideButton.Text = isHidden and "Show UI" or "Hide UI"
end)
