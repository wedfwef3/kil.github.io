-- Service Declarations
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

-- Declare auto-purchase control variables
local autoSeedsEnabled = false
local autoToolsEnabled = false
local autoPetsEnabled = false
local autoEventItemsEnabled = false

-- Create UI ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "UniversalUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

-- Get game name
local gameName = MarketplaceService:GetProductInfo(game.PlaceId).Name

-- Initialize UI notification
StarterGui:SetCore("SendNotification", {
    Title = gameName,
    Text = "inltree｜"..gameName.." Script Loading...｜Loading...",
    Duration = 3
})

task.wait(0.1)

-- Button style settings
local buttonStyle = {
    Size = UDim2.new(0, 120, 0, 30),
    BackgroundColor3 = Color3.new(0.1, 0.1, 0.1),
    BackgroundTransparency = 0.5,
    Font = Enum.Font.SourceSansBold,
    TextSize = 16
}

-- Button creation function
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

-- ===================== Remove Plant Parts Feature =====================
local totalRemoved = 0

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
    print("✅ Remove Plant Parts: Clicked")
    print(("-"):rep(40))
    
    totalRemoved = 0  -- Reset counter
    
    for idx, farmChild in ipairs(workspace.Farm:GetChildren()) do
        local childRemoved = 0
        local childName = farmChild.Name
        
        -- Find Important.Plants_Physical path
        local important = farmChild:FindFirstChild("Important")
        if important then
            local plantsPhysical = important:FindFirstChild("Plants_Physical")
            if plantsPhysical then
                for _, plantModel in ipairs(plantsPhysical:GetChildren()) do
                    if plantModel:IsA("Model") then
                        childRemoved = childRemoved + RemovePartsWithoutPrompts(plantModel)
                    end
                end
            end
        end
        
        print(string.format("Farm [%d] %-20s : Removed %d plant parts", 
              idx, childName, childRemoved))
        
        totalRemoved = totalRemoved + childRemoved
    end
    
    print(("-"):rep(40))
    print(string.format("✅ Total removed plant parts: %d", totalRemoved))
end

-- ===================== Auto Purchase Seeds Feature =====================
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
    return Players.LocalPlayer.PlayerGui:WaitForChild("Seed_Shop"):WaitForChild("Frame"):WaitForChild("ScrollingFrame")
end

local function getSortedSeeds()
    local seeds = {}
    local scrollingFrame = getSeedShopFrame()
    
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
        return a.level > b.level  -- Descending by rarity
    end)
    
    return seeds
end

local function purchaseSeedsSequentially(seeds, index)
    if not autoSeedsEnabled or not seeds[index] then return end
    
    -- Fire seed purchase event
    ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("BuySeedStock"):FireServer(seeds[index].name)
    
    -- Purchase next seed after 0.1 seconds
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
        task.wait(0.1) -- Wait after the full purchase loop
    end
end

-- ===================== Auto Purchase Tools Feature =====================
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
    return Players.LocalPlayer.PlayerGui:WaitForChild("Gear_Shop"):WaitForChild("Frame"):WaitForChild("ScrollingFrame")
end

local function getSortedGears()
    local gears = {}
    local scrollingFrame = getGearShopFrame()
    
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
        return a.level > b.level  -- Descending by rarity
    end)
    
    return gears
end

local function purchaseGearsSequentially(gears, index)
    if not autoToolsEnabled or not gears[index] then return end
    
    -- Fire tool purchase event
    ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("BuyGearStock"):FireServer(gears[index].name)
    
    -- Purchase next gear after 0.1 seconds
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

-- ===================== Auto Purchase Event Items Feature =====================
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
        return eventShopUI:WaitForChild("Frame"):WaitForChild("ScrollingFrame")
    end
    return nil
end

local function getSortedEventItems()
    local eventItems = {}
    local scrollingFrame = getEventShopFrame()
    
    if scrollingFrame then
        for _, itemFrame in ipairs(scrollingFrame:GetChildren()) do
            local rarityText = itemFrame:FindFirstChild("Main_Frame") and itemFrame.Main_Frame:FindFirstChild("Rarity_Text")
            if rarityText then
                table.insert(eventItems, {
                    name = itemFrame.Name,
                    rarity = rarityText.Text,
                    level = EVENT_ITEMS_RARITY_ORDER[rarityText.Text] or 0
                })
            end
        end
        
        table.sort(eventItems, function(a, b)
            return a.level > b.level  -- Descending by rarity
        end)
    end
    
    return eventItems
end

local function purchaseEventItemsSequentially(items, index)
    if not autoEventItemsEnabled or not items[index] then return end
    
    -- Fire event item purchase event
    local args = {
        items[index].name
    }
    ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("BuyEventShopStock"):FireServer(unpack(args))
    
    -- Purchase next event item after 0.1 seconds
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

-- ===================== Create Buttons =====================
local hideButton = createButton("Hide UI", UDim2.new(0, 10, 0, 10), Color3.new(1, 0.5, 0))
local isHidden = false

createButton("Close UI", UDim2.new(0, 10, 0, 50), Color3.new(1, 0, 0), function()
    screenGui:Destroy()
    print("✅ "..gameName.." - Panel: Closed")
end)

createButton("Console", UDim2.new(0, 10, 0, 90), Color3.new(1, 1, 0.5), function()
    game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.F9, false, game)
    print("✅ Console: Opened")
end)

-- Tool shop teleport button
createButton("Teleport to Tool Shop", UDim2.new(0, 270, 0, 10), Color3.new(0, 1, 1), function()
    local character = game.Players.LocalPlayer.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        character.HumanoidRootPart.CFrame = workspace.Tutorial_Points.Tutorial_Point_3.CFrame
        print("✅ Teleported to Tool Shop")
    end
end)

-- Auto seed purchase toggle
local autoSeedsButton = createButton("Auto Seeds: Off", UDim2.new(0, 140, 0, 10), Color3.new(0.5, 1, 0.5))

autoSeedsButton.MouseButton1Click:Connect(function()
    autoSeedsEnabled = not autoSeedsEnabled
    autoSeedsButton.Text = "Auto Seeds: " .. (autoSeedsEnabled and "On" or "Off")
    autoSeedsButton.TextColor3 = autoSeedsEnabled and Color3.new(0, 1, 0) or Color3.new(0.5, 1, 0.5)
    print("✅ Auto Seeds: " .. (autoSeedsEnabled and "Enabled" or "Disabled"))
    
    if autoSeedsEnabled then
        spawn(autoPurchaseSeedsByRarity)
    end
end)

-- Auto tool purchase toggle
local autoToolsButton = createButton("Auto Tools: Off", UDim2.new(0, 140, 0, 50), Color3.new(0.5, 0.5, 1))

autoToolsButton.MouseButton1Click:Connect(function()
    autoToolsEnabled = not autoToolsEnabled
    autoToolsButton.Text = "Auto Tools: " .. (autoToolsEnabled and "On" or "Off")
    autoToolsButton.TextColor3 = autoToolsEnabled and Color3.new(0, 0, 1) or Color3.new(0.5, 0.5, 1)
    print("✅ Auto Tools: " .. (autoToolsEnabled and "Enabled" or "Disabled"))
    
    if autoToolsEnabled then
        spawn(autoPurchaseGearsByRarity)
    end
end)

-- Auto pets toggle
local autoPetsButton = createButton("Auto Pets: Off", UDim2.new(0, 140, 0, 90), Color3.new(1, 0.5, 1))

autoPetsButton.MouseButton1Click:Connect(function()
    autoPetsEnabled = not autoPetsEnabled
    autoPetsButton.Text = "Auto Pets: " .. (autoPetsEnabled and "On" or "Off")
    autoPetsButton.TextColor3 = autoPetsEnabled and Color3.new(1, 0, 1) or Color3.new(1, 0.5, 1)
    print("✅ Auto Pets: " .. (autoPetsEnabled and "Enabled" or "Disabled"))
    
    if autoPetsEnabled then
        spawn(function()
            while autoPetsEnabled do
                local buyEvent = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("BuyPetEgg")

                for i = 1, 3 do
                    if not autoPetsEnabled then break end
                    buyEvent:FireServer(i)
                    task.wait(0.1)
                end
                
                task.wait(0.1)
            end
        end)
    end
end)

-- Auto event items toggle
local autoEventItemsButton = createButton("Auto Event Items: Off", UDim2.new(0, 140, 0, 130), Color3.new(1, 0.8, 0.4))

autoEventItemsButton.MouseButton1Click:Connect(function()
    autoEventItemsEnabled = not autoEventItemsEnabled
    autoEventItemsButton.Text = "Auto Event Items: " .. (autoEventItemsEnabled and "On" or "Off")
    autoEventItemsButton.TextColor3 = autoEventItemsEnabled and Color3.new(1, 0.6, 0) or Color3.new(1, 0.8, 0.4)
    print("✅ Auto Event Items: " .. (autoEventItemsEnabled and "Enabled" or "Disabled"))
    
    if autoEventItemsEnabled then
        spawn(autoPurchaseEventItemsByRarity)
    end
end)

-- Remove plant parts button
createButton("Remove Plant Parts", UDim2.new(0, 270, 0, 50), Color3.new(1, 0.3, 0.3), ProcessFarmWithFeedback)

-- Seed shop UI toggle
createButton("Seed Shop UI", UDim2.new(0, 270, 0, 90), Color3.new(0.5, 1, 0.5), function()
    local seedShop = player.PlayerGui:FindFirstChild("Seed_Shop")
    if seedShop then
        seedShop.Enabled = not seedShop.Enabled
        print("✅ Seed Shop UI: " .. (seedShop.Enabled and "Opened" or "Closed"))
    end
end)

-- Gear shop UI toggle
createButton("Gear Shop UI", UDim2.new(0, 270, 0, 130), Color3.new(0.5, 0.5, 1), function()
    local gearShop = player.PlayerGui:FindFirstChild("Gear_Shop")
    if gearShop then
        gearShop.Enabled = not gearShop.Enabled
        print("✅ Gear Shop UI: " .. (gearShop.Enabled and "Opened" or "Closed"))
    end
end)

-- Daily quests UI toggle
createButton("Quests UI", UDim2.new(0, 270, 0, 170), Color3.new(1, 0.5, 0.5), function()
    local dailyQuestsUI = player.PlayerGui:FindFirstChild("DailyQuests_UI")
    if dailyQuestsUI then
        dailyQuestsUI.Enabled = not dailyQuestsUI.Enabled
        print("✅ Quests UI: " .. (dailyQuestsUI.Enabled and "Opened" or "Closed"))
    end
end)

-- Event shop UI toggle
createButton("Event Shop UI", UDim2.new(0, 400, 0, 10), Color3.new(1, 1, 0), function()
    local eventShop = player.PlayerGui:FindFirstChild("EventShop_UI")
    if eventShop then
        eventShop.Enabled = not eventShop.Enabled
        print("✅ Event Shop UI: " .. (eventShop.Enabled and "Opened" or "Closed"))
    end
end)

-- ===================== UI Drag Functionality =====================
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

-- Hide/Show UI logic
hideButton.MouseButton1Click:Connect(function()
    isHidden = not isHidden
    for _, child in ipairs(screenGui:GetChildren()) do
        if child:IsA("TextButton") and child ~= hideButton then
            child.Visible = not isHidden
        end
    end
    hideButton.Text = isHidden and "Show UI" or "Hide UI"
    print("✅ Hide state:", isHidden and "Closed" or "Opened")
end)

-- Loading complete notification
task.wait(0.5)
StarterGui:SetCore("SendNotification", {
    Title = gameName,
    Text = gameName.."｜Garden Planting｜Loaded",
    Duration = 3
})

warn("\n"..(("="):rep(40).."\n- Script Name: "..gameName.."\n- Description: Planting Garden｜Adds auto-purchase pets (if enough money), remove plant parts, open shop UIs and optimize auto-purchase seeds/tools\n- Version: 1.0.5\n- Author: inltree｜Lin×DeepSeek\n"..("="):rep(40)))
