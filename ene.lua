

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local localPlayer = Players.LocalPlayer

-- === SEED LIST ===
local seeds = {
    "Carrot","Strawberry","Blueberry","Orange Tulip","Tomato","Corn",
    "Daffodil","Watermelon","Pumpkin","Apple","Bamboo","Coconut",
    "Cactus","Dragon Fruit","Mango","Grape","Mushroom","Pepper",
    "Cacao","Beanstalk"
}

-- === UI THEME ===
local Theme = {
    Background = Color3.fromRGB(18,18,18),
    Button = Color3.fromRGB(29,29,29),
    Text = Color3.fromRGB(255,255,255),
    Accent = Color3.fromRGB(87,180,255),
    Accent2 = Color3.fromRGB(50,120,255),
}

-- === UI ROOT ===
local playerGui = localPlayer:WaitForChild("PlayerGui")
local screenGui = Instance.new("ScreenGui", playerGui)
screenGui.Name = "GardenAutoFarmUI"

local MainFrame = Instance.new("Frame", screenGui)
MainFrame.Size = UDim2.new(0, 480, 0, 350)
MainFrame.Position = UDim2.new(0.5,0,0.5,0)
MainFrame.AnchorPoint = Vector2.new(0.5,0.5)
MainFrame.BackgroundColor3 = Theme.Background
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)

local frameOutline = Instance.new("UIStroke")
frameOutline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
frameOutline.Thickness = 4
frameOutline.Parent = MainFrame
local hue = 0
RunService.RenderStepped:Connect(function()
    hue = (hue + 0.008) % 1
    frameOutline.Color = Color3.fromHSV(hue, 0.8, 1)
end)

local Title = Instance.new("TextLabel", MainFrame)
Title.Text = "🌱 Grow-a-Garden Auto Hub"
Title.Size = UDim2.new(1, -20, 0, 32)
Title.Position = UDim2.new(0, 12, 0, 8)
Title.BackgroundTransparency = 1
Title.TextColor3 = Theme.Text
Title.Font = Enum.Font.GothamBold
Title.TextSize = 22
Title.TextXAlignment = Enum.TextXAlignment.Left

-- === TABS ===
local TabsFrame = Instance.new("Frame", MainFrame)
TabsFrame.Size = UDim2.new(0, 120, 1, -48)
TabsFrame.Position = UDim2.new(0, 10, 0, 44)
TabsFrame.BackgroundColor3 = Theme.Button
Instance.new("UICorner", TabsFrame).CornerRadius = UDim.new(0, 8)

local TabsScroll = Instance.new("ScrollingFrame", TabsFrame)
TabsScroll.Size = UDim2.new(1, 0, 1, 0)
TabsScroll.BackgroundTransparency = 1
TabsScroll.ScrollBarThickness = 6
TabsScroll.VerticalScrollBarInset = Enum.ScrollBarInset.Always
TabsScroll.ScrollingDirection = Enum.ScrollingDirection.Y
TabsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
TabsScroll.CanvasSize = UDim2.new(1,0,0,0)

local TabContentFrame = Instance.new("Frame", MainFrame)
TabContentFrame.Size = UDim2.new(1, -140, 1, -48)
TabContentFrame.Position = UDim2.new(0, 130, 0, 44)
TabContentFrame.BackgroundColor3 = Theme.Background
Instance.new("UICorner", TabContentFrame).CornerRadius = UDim.new(0, 8)

local Tabs = {}
local TabButtons = {}
local function CreateTab(tabName)
    local TabButton = Instance.new("TextButton", TabsScroll)
    TabButton.Text = tabName
    TabButton.Size = UDim2.new(1, -10, 0, 32)
    TabButton.Position = UDim2.new(0, 5, 0, (#Tabs * 36))
    TabButton.BackgroundColor3 = Theme.Button
    TabButton.TextColor3 = Theme.Text
    TabButton.Font = Enum.Font.GothamBold
    TabButton.TextSize = 17
    Instance.new("UICorner", TabButton).CornerRadius = UDim.new(0, 7)
    TabsScroll.CanvasSize = UDim2.new(0, 0, 0, (#Tabs + 1) * 36 + 10)
    local TabFrame = Instance.new("Frame", TabContentFrame)
    TabFrame.Size = UDim2.new(1, 0, 1, 0)
    TabFrame.Visible = (#Tabs == 0)
    TabFrame.BackgroundTransparency = 1
    table.insert(Tabs, TabFrame)
    TabButtons[#Tabs] = TabButton
    TabButton.MouseButton1Click:Connect(function()
        for i, frame in ipairs(Tabs) do
            frame.Visible = false
            TabButtons[i].BackgroundColor3 = Theme.Button
        end
        TabButton.BackgroundColor3 = Theme.Accent
        TabFrame.Visible = true
    end)
    if #Tabs == 1 then
        TabButton.BackgroundColor3 = Theme.Accent
        TabFrame.Visible = true
    end
    return TabFrame
end

-- === AUTOBUY TAB ===
local AutobuyTab = CreateTab("Autobuy")
local autobuy_selected = {}
for i, seed in ipairs(seeds) do
    autobuy_selected[seed] = false
end
local autobuy_running = false
local autobuy_thread

local AutobuyLabel = Instance.new("TextLabel", AutobuyTab)
-- Money Bar for Autobuy Tab (docks bottom right and moves with UI)
local leaderstats = localPlayer:FindFirstChild("leaderstats") or localPlayer:WaitForChild("leaderstats")
local shecklesStat = leaderstats:FindFirstChild("Sheckles") or leaderstats:WaitForChild("Sheckles")


-- Money Bar for Autobuy Tab (fix: brighter blue, stretches with UI)
local moneyBar = Instance.new("Frame", AutobuyTab)
moneyBar.Size = UDim2.new(1, -24, 0, 32)  -- stretches almost full width
moneyBar.AnchorPoint = Vector2.new(1, 1)
moneyBar.Position = UDim2.new(1, -12, 1, -12)
moneyBar.BackgroundColor3 = Theme.Button
moneyBar.BackgroundTransparency = 0.08
moneyBar.BorderSizePixel = 0
moneyBar.ZIndex = 2
Instance.new("UICorner", moneyBar).CornerRadius = UDim.new(0, 9)

local moneyLabel = Instance.new("TextLabel", moneyBar)
moneyLabel.Size = UDim2.new(1, -18, 1, 0)
moneyLabel.Position = UDim2.new(0, 9, 0, 0)
moneyLabel.BackgroundTransparency = 1
moneyLabel.TextColor3 = Color3.fromRGB(0, 170, 255)  -- much brighter blue
moneyLabel.TextStrokeTransparency = 0.7
moneyLabel.Font = Enum.Font.GothamBold
moneyLabel.TextSize = 18
moneyLabel.TextXAlignment = Enum.TextXAlignment.Right
moneyLabel.Text = "$0"
moneyLabel.ZIndex = 1

task.spawn(function()
    while true do
        local money = shecklesStat.Value
        moneyLabel.Text = ("$%s"):format(tostring(money):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
        task.wait(1)
    end
end)


AutobuyLabel.Text = "Select seeds to autobuy:"
AutobuyLabel.Size = UDim2.new(1, -20, 0, 28)
AutobuyLabel.Position = UDim2.new(0,10,0,6)
AutobuyLabel.BackgroundTransparency = 1
AutobuyLabel.TextColor3 = Theme.Text
AutobuyLabel.Font = Enum.Font.GothamBold
AutobuyLabel.TextSize = 16
AutobuyLabel.TextXAlignment = Enum.TextXAlignment.Left

local Scroll = Instance.new("ScrollingFrame", AutobuyTab)
Scroll.Size = UDim2.new(0.55, 0, 0, 170)
Scroll.Position = UDim2.new(0, 10, 0, 40)
Scroll.CanvasSize = UDim2.new(0,0,0,#seeds*30)
Scroll.BackgroundColor3 = Theme.Button
Scroll.ScrollBarThickness = 5
Scroll.VerticalScrollBarInset = Enum.ScrollBarInset.Always
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Instance.new("UICorner", Scroll).CornerRadius = UDim.new(0, 5)

local checkboxes = {}
for i, seed in ipairs(seeds) do
    local cb = Instance.new("TextButton", Scroll)
    cb.Size = UDim2.new(1, -8, 0, 26)
    cb.Position = UDim2.new(0, 4, 0, (i-1)*28)
    cb.BackgroundColor3 = Theme.Button
    cb.TextColor3 = Theme.Text
    cb.Font = Enum.Font.Gotham
    cb.TextSize = 15
    cb.Text = "[  ] " .. seed
    checkboxes[seed] = cb

    cb.MouseButton1Click:Connect(function()
        autobuy_selected[seed] = not autobuy_selected[seed]
        cb.Text = autobuy_selected[seed] and "[✔] "..seed or "[  ] "..seed
        cb.BackgroundColor3 = autobuy_selected[seed] and Theme.Accent or Theme.Button
    end)
end

local function get_autobuy_list()
    local t = {}
    for _, seed in ipairs(seeds) do
        if autobuy_selected[seed] then
            table.insert(t, seed)
        end
    end
    return t
end

local autobuy_toggle = Instance.new("TextButton", AutobuyTab)
autobuy_toggle.Size = UDim2.new(0.36, 0, 0, 38)
autobuy_toggle.Position = UDim2.new(0.6, 0, 0, 40)
autobuy_toggle.BackgroundColor3 = Theme.Button
autobuy_toggle.TextColor3 = Theme.Text
autobuy_toggle.Font = Enum.Font.GothamBold
autobuy_toggle.TextSize = 17
autobuy_toggle.Text = "Start Autobuy"
Instance.new("UICorner", autobuy_toggle).CornerRadius = UDim.new(0, 7)

autobuy_toggle.MouseButton1Click:Connect(function()
    if not autobuy_running then
        autobuy_running = true
        autobuy_toggle.Text = "Stop Autobuy"
        autobuy_toggle.BackgroundColor3 = Theme.Accent2
        autobuy_thread = task.spawn(function()
            while autobuy_running do
                local list = get_autobuy_list()
                for _, seed in ipairs(list) do
                    ReplicatedStorage.GameEvents.BuySeedStock:FireServer(seed)
                    task.wait(0.12)
                end
                task.wait(0.5)
            end
        end)
    else
        autobuy_running = false
        autobuy_toggle.Text = "Start Autobuy"
        autobuy_toggle.BackgroundColor3 = Theme.Button
    end
end)

-- === AUTOPLANT TAB (SMART RANDOM PLANTING, NO TELEPORT) ===
local AutoplantTab = CreateTab("Autoplant")
local autoplant_selected = {}
for i, seed in ipairs(seeds) do
    autoplant_selected[seed] = false
end
local autoplant_running = false
local autoplant_thread

local AutoplantLabel = Instance.new("TextLabel", AutoplantTab)
AutoplantLabel.Text = "Select seeds to autoplant:"
AutoplantLabel.Size = UDim2.new(1, -20, 0, 28)
AutoplantLabel.Position = UDim2.new(0,10,0,6)
AutoplantLabel.BackgroundTransparency = 1
AutoplantLabel.TextColor3 = Theme.Text
AutoplantLabel.Font = Enum.Font.GothamBold
AutoplantLabel.TextSize = 16
AutoplantLabel.TextXAlignment = Enum.TextXAlignment.Left

local ScrollPlant = Instance.new("ScrollingFrame", AutoplantTab)
ScrollPlant.Size = UDim2.new(0.55, 0, 0, 170)
ScrollPlant.Position = UDim2.new(0, 10, 0, 40)
ScrollPlant.CanvasSize = UDim2.new(0,0,0,#seeds*30)
ScrollPlant.BackgroundColor3 = Theme.Button
ScrollPlant.ScrollBarThickness = 5
ScrollPlant.VerticalScrollBarInset = Enum.ScrollBarInset.Always
ScrollPlant.AutomaticCanvasSize = Enum.AutomaticSize.Y
Instance.new("UICorner", ScrollPlant).CornerRadius = UDim.new(0, 5)

local checkboxes_plant = {}
for i, seed in ipairs(seeds) do
    local cb = Instance.new("TextButton", ScrollPlant)
    cb.Size = UDim2.new(1, -8, 0, 26)
    cb.Position = UDim2.new(0, 4, 0, (i-1)*28)
    cb.BackgroundColor3 = Theme.Button
    cb.TextColor3 = Theme.Text
    cb.Font = Enum.Font.Gotham
    cb.TextSize = 15
    cb.Text = "[  ] " .. seed
    checkboxes_plant[seed] = cb

    cb.MouseButton1Click:Connect(function()
        autoplant_selected[seed] = not autoplant_selected[seed]
        cb.Text = autoplant_selected[seed] and "[✔] "..seed or "[  ] "..seed
        cb.BackgroundColor3 = autoplant_selected[seed] and Theme.Accent or Theme.Button
    end)
end

local function get_autoplant_list()
    local t = {}
    for _, seed in ipairs(seeds) do
        if autoplant_selected[seed] then
            table.insert(t, seed)
        end
    end
    return t
end

local autoplant_toggle = Instance.new("TextButton", AutoplantTab)
autoplant_toggle.Size = UDim2.new(0.36, 0, 0, 38)
autoplant_toggle.Position = UDim2.new(0.6, 0, 0, 40)
autoplant_toggle.BackgroundColor3 = Theme.Button
autoplant_toggle.TextColor3 = Theme.Text
autoplant_toggle.Font = Enum.Font.GothamBold
autoplant_toggle.TextSize = 17
autoplant_toggle.Text = "Start Autoplant"
Instance.new("UICorner", autoplant_toggle).CornerRadius = UDim.new(0, 7)

local function getMyFarm()
    for _, farm in pairs(workspace.Farm:GetChildren()) do
        local data = farm:FindFirstChild("Important") and farm.Important:FindFirstChild("Data")
        if data and data:FindFirstChild("Owner") and data.Owner.Value == localPlayer.Name then
            return farm
        end
    end
    return nil
end

local function getCanPlantParts()
    local myFarm = getMyFarm()
    local canPlant = {}
    if myFarm then
        local plantLocations = myFarm:FindFirstChild("Important") and myFarm.Important:FindFirstChild("Plant_Locations")
        if plantLocations then
            for _, part in ipairs(plantLocations:GetDescendants()) do
                if part:IsA("BasePart") and part.Name:find("Can_Plant") then
                    table.insert(canPlant, part)
                end
            end
        end
    end
    return canPlant
end

local function getRandomPosition(part)
    local offset = Vector3.new(
        math.random(-part.Size.X/2, part.Size.X/2),
        0,
        math.random(-part.Size.Z/2, part.Size.Z/2)
    )
    return part.Position + offset + Vector3.new(0, 2, 0)
end

local function getSeedTool(seedName)
    for _, item in ipairs(localPlayer.Backpack:GetChildren()) do
        if item:GetAttribute("ITEM_TYPE") == "Seed" and item:GetAttribute("Seed") == seedName then
            return item
        end
    end
    local char = localPlayer.Character
    if char then
        for _, item in ipairs(char:GetChildren()) do
            if item:IsA("Tool") and item:GetAttribute("ITEM_TYPE") == "Seed" and item:GetAttribute("Seed") == seedName then
                return item
            end
        end
    end
    return nil
end

local function equipSeed(tool)
    if tool and localPlayer.Character then
        local humanoid = localPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid and tool.Parent ~= localPlayer.Character then
            humanoid:EquipTool(tool)
            task.wait(0.07)
        end
    end
end

local function isInventoryFull()
    return #localPlayer.Backpack:GetChildren() >= 200
end

autoplant_toggle.MouseButton1Click:Connect(function()
    autoplant_running = not autoplant_running
    if autoplant_running then
        autoplant_toggle.Text = "Stop Autoplant"
        autoplant_toggle.BackgroundColor3 = Theme.Accent2
        autoplant_thread = task.spawn(function()
            while autoplant_running do
                if isInventoryFull() then
                    autoplant_toggle.Text = "Backpack Full!"
                    repeat
                        task.wait(0.5)
                    until not isInventoryFull() or not autoplant_running
                    autoplant_toggle.Text = "Stop Autoplant"
                end
                if not autoplant_running then break end

                local list = get_autoplant_list()
                if #list == 0 then
                    task.wait(0.7)
                    continue
                end

                local plantParts = getCanPlantParts()
                if #plantParts == 0 then
                    task.wait(0.7)
                    continue
                end

                for _, seedName in ipairs(list) do
                    local tool = getSeedTool(seedName)
                    if tool then
                        equipSeed(tool)
                        -- Try to plant at random spots up to N times
                        local maxTries = #plantParts * 2
                        for i = 1, maxTries do
                            if not autoplant_running or isInventoryFull() then return end
                            local spot = plantParts[math.random(1, #plantParts)]
                            local pos = getRandomPosition(spot)
                            -- Try to plant
                            ReplicatedStorage.GameEvents.Plant_RE:FireServer(pos, seedName)
                            task.wait(0.12)
                        end
                    end
                end
                task.wait(0.5)
            end
            autoplant_toggle.Text = "Start Autoplant"
            autoplant_toggle.BackgroundColor3 = Theme.Button
        end)
    else
        autoplant_toggle.Text = "Start Autoplant"
        autoplant_toggle.BackgroundColor3 = Theme.Button
        if autoplant_thread then
            task.cancel(autoplant_thread)
            autoplant_thread = nil
        end
    end
end)


-- === AUTOFARM TAB (Autosell + Autocollect Combined, Interval-Based Autosell) ===

local AutofarmTab = CreateTab("Autofarm")
local autosell_running = false
local autosell_thread
local collecting = false
local collect_thread
local autosell_interval = 5 -- default seconds

-- Autofarm Features Label
local autofarmLabel = Instance.new("TextLabel", AutofarmTab)
autofarmLabel.Text = "Autofarm Features"
autofarmLabel.Size = UDim2.new(1, -20, 0, 24)
autofarmLabel.Position = UDim2.new(0, 16, 0, 8)
autofarmLabel.BackgroundTransparency = 1
autofarmLabel.TextColor3 = Theme.Accent2
autofarmLabel.Font = Enum.Font.GothamBold
autofarmLabel.TextSize = 17
autofarmLabel.TextXAlignment = Enum.TextXAlignment.Left

-- === AUTOCOLLECT SECTION ===
local autocollect_toggle = Instance.new("TextButton", AutofarmTab)
autocollect_toggle.Size = UDim2.new(0.6, 0, 0, 38)
autocollect_toggle.Position = UDim2.new(0, 16, 0, 38)
autocollect_toggle.BackgroundColor3 = Theme.Button
autocollect_toggle.TextColor3 = Theme.Text
autocollect_toggle.Font = Enum.Font.GothamBold
autocollect_toggle.TextSize = 18
autocollect_toggle.Text = "Start Autocollect"
Instance.new("UICorner", autocollect_toggle).CornerRadius = UDim.new(0, 7)

-- You can put your autocollect logic here (not changed by autosell change)

-- === AUTOSELL INTERVAL SLIDER ===
local sliderLabel = Instance.new("TextLabel", AutofarmTab)
sliderLabel.Text = "Autosell every " .. tostring(autosell_interval) .. " seconds"
sliderLabel.Size = UDim2.new(1, -20, 0, 24)
sliderLabel.Position = UDim2.new(0, 16, 0, 84)
sliderLabel.BackgroundTransparency = 1
sliderLabel.TextColor3 = Theme.Text
sliderLabel.Font = Enum.Font.GothamBold
sliderLabel.TextSize = 15
sliderLabel.TextXAlignment = Enum.TextXAlignment.Left

local sliderFrame = Instance.new("Frame", AutofarmTab)
sliderFrame.BackgroundColor3 = Theme.Button
sliderFrame.Size = UDim2.new(0.9, 0, 0, 14)
sliderFrame.Position = UDim2.new(0, 16, 0, 108)
Instance.new("UICorner", sliderFrame).CornerRadius = UDim.new(0, 5)

local sliderBar = Instance.new("Frame", sliderFrame)
sliderBar.BackgroundColor3 = Theme.Accent
sliderBar.Size = UDim2.new(0, 12, 1, 0)
sliderBar.Position = UDim2.new(1, -6, 0, 0)
sliderBar.AnchorPoint = Vector2.new(0, 0.5)
sliderBar.Name = "SliderBar"
Instance.new("UICorner", sliderBar).CornerRadius = UDim.new(0, 6)

local draggingSlider = false

local function setSliderFromX(x)
    local left = sliderFrame.AbsolutePosition.X
    local width = sliderFrame.AbsoluteSize.X
    local rel = math.clamp((x - left) / width, 0, 1)
    autosell_interval = math.max(1, math.floor(1 + rel * 59 + 0.5)) -- 1 to 60 seconds
    local barPos = rel * width - sliderBar.Size.X.Offset/2
    sliderBar.Position = UDim2.new(0, barPos, 0.5, 0)
    sliderLabel.Text = "Autosell every " .. tostring(autosell_interval) .. " seconds"
end

local function beginDrag(input)
    draggingSlider = true
    setSliderFromX(input.Position.X)
end
local function endDrag()
    draggingSlider = false
end

sliderFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        beginDrag(input)
    end
end)
sliderFrame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        endDrag()
    end
end)
sliderBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        beginDrag(input)
    end
end)
sliderBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        endDrag()
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        setSliderFromX(input.Position.X)
    end
end)

sliderBar.Position = UDim2.new(1, -6, 0.5, 0)

-- === AUTOSELL TOGGLE BUTTON & LOGIC ===
local autosell_toggle = Instance.new("TextButton", AutofarmTab)
autosell_toggle.Size = UDim2.new(0.6, 0, 0, 38)
autosell_toggle.Position = UDim2.new(0, 16, 0, 132)
autosell_toggle.BackgroundColor3 = Theme.Button
autosell_toggle.TextColor3 = Theme.Text
autosell_toggle.Font = Enum.Font.GothamBold
autosell_toggle.TextSize = 18
autosell_toggle.Text = "Start Autosell"
Instance.new("UICorner", autosell_toggle).CornerRadius = UDim.new(0, 7)

autosell_toggle.MouseButton1Click:Connect(function()
    if not autosell_running then
        autosell_running = true
        autosell_toggle.Text = "Stop Autosell"
        autosell_toggle.BackgroundColor3 = Theme.Accent2
        autosell_thread = task.spawn(function()
            local GE = ReplicatedStorage.GameEvents
            while autosell_running do
                local hrp = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local pos = hrp.CFrame
                    hrp.CFrame = workspace.Tutorial_Points.Tutorial_Point_2.CFrame
                    task.wait(0.2)
                    GE.Sell_Inventory:FireServer()
                    task.wait(0.2)
                    hrp.CFrame = pos
                end
                for i = 1, autosell_interval do
                    if not autosell_running then break end
                    task.wait(1)
                end
            end
        end)
    else
        autosell_running = false
        autosell_toggle.Text = "Start Autosell"
        autosell_toggle.BackgroundColor3 = Theme.Button
        if autosell_thread then
            task.cancel(autosell_thread)
            autosell_thread = nil
        end
    end
end)

-- === END OF AUTOFARM TAB ===


-- AUTOCOLLECT LOGIC
local function getMyFarm()
    for _, farm in pairs(workspace.Farm:GetChildren()) do
        local data = farm:FindFirstChild("Important") and farm.Important:FindFirstChild("Data")
        if data and data:FindFirstChild("Owner") and data.Owner.Value == localPlayer.Name then
            return farm
        end
    end
    return nil
end

local function getMyHarvestableCrops()
    local myFarm = getMyFarm()
    local crops = {}
    if myFarm then
        local plants = myFarm:FindFirstChild("Important") and myFarm.Important:FindFirstChild("Plants_Physical")
        if plants then
            for _, plant in pairs(plants:GetChildren()) do
                for _, part in pairs(plant:GetDescendants()) do
                    if part:IsA("BasePart") and part:FindFirstChildOfClass("ProximityPrompt") then
                        table.insert(crops, part)
                        break
                    end
                end
            end
        end
    end
    return crops
end

local function isInventoryFull()
    return #localPlayer.Backpack:GetChildren() >= autosell_threshold
end

local function sellInventory()
    -- Teleport to Steven or shop and sell inventory
    local steven = workspace.NPCS:FindFirstChild("Steven")
    local char = localPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if steven and hrp then
        local oldCFrame = hrp.CFrame
        hrp.CFrame = steven.HumanoidRootPart.CFrame + Vector3.new(0, 3, 3)
        task.wait(0.4)
        for i = 1, 4 do
            pcall(function()
                game:GetService("ReplicatedStorage").GameEvents.Sell_Inventory:FireServer()
            end)
            task.wait(0.15)
        end
        hrp.CFrame = oldCFrame
    end
end

local function autoCollectLoop()
    while collecting do
        if isInventoryFull() then
            if autosell_when_full then
                autocollect_toggle.Text = "Autoselling..."
                sellInventory()
                -- Wait until not full
                while collecting and isInventoryFull() do
                    task.wait(0.5)
                end
                autocollect_toggle.Text = "Stop Autocollect"
            else
                autocollect_toggle.Text = "Backpack Full!"
                -- Wait until user empties inventory
                while collecting and isInventoryFull() do
                    task.wait(0.5)
                end
                autocollect_toggle.Text = "Stop Autocollect"
            end
        end
        if not collecting then break end

        local crops = getMyHarvestableCrops()
        for _, crop in ipairs(crops) do
            if not collecting then return end
            if isInventoryFull() then break end
            local char = localPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp and crop and crop.Parent then
                hrp.CFrame = CFrame.new(crop.Position + Vector3.new(0, 3, 0))
                task.wait(0.15)
                local prompt = crop:FindFirstChildOfClass("ProximityPrompt")
                if prompt then
                    pcall(function()
                        fireproximityprompt(prompt)
                    end)
                    task.wait(0.1)
                end
            end
        end
        task.wait(0.2)
    end
    autocollect_toggle.Text = "Start Autocollect"
    autocollect_toggle.BackgroundColor3 = Theme.Button
end

autocollect_toggle.MouseButton1Click:Connect(function()
    collecting = not collecting
    if collecting then
        autocollect_toggle.Text = "Stop Autocollect"
        autocollect_toggle.BackgroundColor3 = Theme.Accent2
        collect_thread = task.spawn(autoCollectLoop)
    else
        autocollect_toggle.Text = "Start Autocollect"
        autocollect_toggle.BackgroundColor3 = Theme.Button
        if collect_thread then
            task.cancel(collect_thread)
            collect_thread = nil
        end
    end
end)



-- === AUTOBUY GEARS TAB ===
local gears = {
    "Watering Can",
    "Trowel",
    "Recall Wrench",
    "Basic Sprinkler",
    "Advanced Sprinkler",
    "Godly Sprinkler",
    "Lightning Rod",
    "Master Sprinkler",
}
local autobuy_gear_selected = {}
for i, gear in ipairs(gears) do
    autobuy_gear_selected[gear] = false
end
local autobuy_gear_running = false
local autobuy_gear_thread

local GearsTab = CreateTab("Gears")

local GearsLabel = Instance.new("TextLabel", GearsTab)
GearsLabel.Text = "Select gears to autobuy:"
GearsLabel.Size = UDim2.new(1, -20, 0, 28)
GearsLabel.Position = UDim2.new(0,10,0,6)
GearsLabel.BackgroundTransparency = 1
GearsLabel.TextColor3 = Theme.Text
GearsLabel.Font = Enum.Font.GothamBold
GearsLabel.TextSize = 16
GearsLabel.TextXAlignment = Enum.TextXAlignment.Left

local GearsScroll = Instance.new("ScrollingFrame", GearsTab)
GearsScroll.Size = UDim2.new(0.55, 0, 0, 170)
GearsScroll.Position = UDim2.new(0, 10, 0, 40)
GearsScroll.CanvasSize = UDim2.new(0,0,0,#gears*30)
GearsScroll.BackgroundColor3 = Theme.Button
GearsScroll.ScrollBarThickness = 5
GearsScroll.VerticalScrollBarInset = Enum.ScrollBarInset.Always
GearsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Instance.new("UICorner", GearsScroll).CornerRadius = UDim.new(0, 5)

local gears_checkboxes = {}
for i, gear in ipairs(gears) do
    local cb = Instance.new("TextButton", GearsScroll)
    cb.Size = UDim2.new(1, -8, 0, 26)
    cb.Position = UDim2.new(0, 4, 0, (i-1)*28)
    cb.BackgroundColor3 = Theme.Button
    cb.TextColor3 = Theme.Text
    cb.Font = Enum.Font.Gotham
    cb.TextSize = 15
    cb.Text = "[  ] " .. gear
    gears_checkboxes[gear] = cb

    cb.MouseButton1Click:Connect(function()
        autobuy_gear_selected[gear] = not autobuy_gear_selected[gear]
        cb.Text = autobuy_gear_selected[gear] and "[✔] "..gear or "[  ] "..gear
        cb.BackgroundColor3 = autobuy_gear_selected[gear] and Theme.Accent or Theme.Button
    end)
end

local function get_autobuy_gear_list()
    local t = {}
    for _, gear in ipairs(gears) do
        if autobuy_gear_selected[gear] then
            table.insert(t, gear)
        end
    end
    return t
end

local autobuy_gear_toggle = Instance.new("TextButton", GearsTab)
autobuy_gear_toggle.Size = UDim2.new(0.36, 0, 0, 38)
autobuy_gear_toggle.Position = UDim2.new(0.6, 0, 0, 40)
autobuy_gear_toggle.BackgroundColor3 = Theme.Button
autobuy_gear_toggle.TextColor3 = Theme.Text
autobuy_gear_toggle.Font = Enum.Font.GothamBold
autobuy_gear_toggle.TextSize = 17
autobuy_gear_toggle.Text = "Start Autobuy Gears"
Instance.new("UICorner", autobuy_gear_toggle).CornerRadius = UDim.new(0, 7)

autobuy_gear_toggle.MouseButton1Click:Connect(function()
    if not autobuy_gear_running then
        autobuy_gear_running = true
        autobuy_gear_toggle.Text = "Stop Autobuy Gears"
        autobuy_gear_toggle.BackgroundColor3 = Theme.Accent2
        autobuy_gear_thread = task.spawn(function()
            while autobuy_gear_running do
                local list = get_autobuy_gear_list()
                for _, gear in ipairs(list) do
                    ReplicatedStorage.GameEvents.BuyGearStock:FireServer(gear)
                    task.wait(0.15)
                end
                task.wait(2)
            end
        end)
    else
        autobuy_gear_running = false
        autobuy_gear_toggle.Text = "Start Autobuy Gears"
        autobuy_gear_toggle.BackgroundColor3 = Theme.Button
    end
end)


-- === MAIN TAB (Corrected: Vertical left stack for collect/shop, right-aligned ESP/autobuy) ===

local MainTab = CreateTab("Main")

local honeyShopItems = {
    "Flower Seed Pack",
    "Nectarine",
    "Hive Fruit",
    "Honey Sprinkler",
    "Bee Egg",
    "Bee Crate",
    "Honey Comb",
    "Bee Chair",
    "Honey Torch",
    "Honey Walkway"
}

local autobuy_honey_selected = {}
for _, item in ipairs(honeyShopItems) do
    autobuy_honey_selected[item] = false
end
local autobuy_honey_running = false
local autobuy_honey_thread

-- Label
local AutobuyHoneyLabel = Instance.new("TextLabel", MainTab)
AutobuyHoneyLabel.Text = "Autobuy Honey Shop Items:"
AutobuyHoneyLabel.Size = UDim2.new(0.45, 0, 0, 20)
AutobuyHoneyLabel.Position = UDim2.new(0.075, 0, 0, 6)
AutobuyHoneyLabel.BackgroundTransparency = 1
AutobuyHoneyLabel.TextColor3 = Theme.Text
AutobuyHoneyLabel.Font = Enum.Font.GothamBold
AutobuyHoneyLabel.TextSize = 16
AutobuyHoneyLabel.TextXAlignment = Enum.TextXAlignment.Left

-- ScrollingFrame for checkboxes (left column)
local itemScroll = Instance.new("ScrollingFrame", MainTab)
itemScroll.Size = UDim2.new(0.45, 0, 0, 92)
itemScroll.Position = UDim2.new(0.075, 0, 0, 28)
itemScroll.BackgroundColor3 = Theme.Button
itemScroll.BackgroundTransparency = 0.1
itemScroll.BorderSizePixel = 0
itemScroll.CanvasSize = UDim2.new(0, 0, 0, #honeyShopItems*22)
itemScroll.ScrollBarThickness = 5
itemScroll.VerticalScrollBarInset = Enum.ScrollBarInset.Always
itemScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Instance.new("UICorner", itemScroll).CornerRadius = UDim.new(0, 6)

local honey_checkboxes = {}
for i, item in ipairs(honeyShopItems) do
    local cb = Instance.new("TextButton", itemScroll)
    cb.Size = UDim2.new(1, -6, 0, 20)
    cb.Position = UDim2.new(0, 3, 0, (i-1)*22)
    cb.BackgroundColor3 = Theme.Button
    cb.TextColor3 = Theme.Text
    cb.Font = Enum.Font.Gotham
    cb.TextSize = 14
    cb.Text = "[  ] " .. item
    cb.AutoButtonColor = true
    honey_checkboxes[item] = cb

    cb.MouseButton1Click:Connect(function()
        autobuy_honey_selected[item] = not autobuy_honey_selected[item]
        cb.Text = autobuy_honey_selected[item] and "[✔] "..item or "[  ] "..item
        cb.BackgroundColor3 = autobuy_honey_selected[item] and Theme.Accent or Theme.Button
    end)
end

local function get_autobuy_honey_list()
    local t = {}
    for _, item in ipairs(honeyShopItems) do
        if autobuy_honey_selected[item] then
            table.insert(t, item)
        end
    end
    return t
end

-- Compact button settings
local buttonWidth = 0.36
local buttonHeight = 28
local rightButtonX = 0.62
local leftButtonX = 0.075
local scrollBottomY = 28 + 92
local leftButtonSpacing = 10
local rightButtonSpacing = 12

-- LEFT COLUMN: Start Honey Collect Only (under scroll)
local honeyCollectBtn = Instance.new("TextButton", MainTab)
honeyCollectBtn.Size = UDim2.new(0.45, 0, 0, buttonHeight)
honeyCollectBtn.Position = UDim2.new(leftButtonX, 0, 0, scrollBottomY + leftButtonSpacing)
honeyCollectBtn.BackgroundColor3 = Theme.Button
honeyCollectBtn.TextColor3 = Theme.Text
honeyCollectBtn.Font = Enum.Font.GothamBold
honeyCollectBtn.TextSize = 15
honeyCollectBtn.Text = "Start Honey Collect Only"
Instance.new("UICorner", honeyCollectBtn).CornerRadius = UDim.new(0, 8)

-- LEFT COLUMN: Open Shop UI (under collect)
local openShopBtn = Instance.new("TextButton", MainTab)
openShopBtn.Size = UDim2.new(0.45, 0, 0, buttonHeight)
openShopBtn.Position = UDim2.new(leftButtonX, 0, 0, scrollBottomY + buttonHeight + leftButtonSpacing * 2)
openShopBtn.BackgroundColor3 = Theme.Button
openShopBtn.TextColor3 = Theme.Text
openShopBtn.Font = Enum.Font.GothamBold
openShopBtn.TextSize = 15
openShopBtn.Text = "Open Shop UI"
Instance.new("UICorner", openShopBtn).CornerRadius = UDim.new(0, 8)

openShopBtn.MouseButton1Click:Connect(function()
    local Players = game:GetService("Players")
    local localPlayer = Players.LocalPlayer
    local shop = localPlayer.PlayerGui:FindFirstChild("HoneyEventShop_UI")
    if shop then
        shop.Enabled = not shop.Enabled
    else
        warn("HoneyEventShop_UI not found in PlayerGui!")
    end
end)

-- RIGHT COLUMN: Start Autobuy, Mutation ESP, Honey ESP (top aligned)
local rightButtonStartY = 28
-- Start Autobuy
local autobuy_honey_toggle = Instance.new("TextButton", MainTab)
autobuy_honey_toggle.Size = UDim2.new(buttonWidth, 0, 0, buttonHeight)
autobuy_honey_toggle.Position = UDim2.new(rightButtonX, 0, 0, rightButtonStartY + (buttonHeight + rightButtonSpacing) * 0)
autobuy_honey_toggle.BackgroundColor3 = Theme.Button
autobuy_honey_toggle.TextColor3 = Theme.Text
autobuy_honey_toggle.Font = Enum.Font.GothamBold
autobuy_honey_toggle.TextSize = 15
autobuy_honey_toggle.Text = "Start Autobuy"
Instance.new("UICorner", autobuy_honey_toggle).CornerRadius = UDim.new(0, 7)

autobuy_honey_toggle.MouseButton1Click:Connect(function()
    if not autobuy_honey_running then
        autobuy_honey_running = true
        autobuy_honey_toggle.Text = "Stop Autobuy"
        autobuy_honey_toggle.BackgroundColor3 = Theme.Accent2
        autobuy_honey_thread = task.spawn(function()
            while autobuy_honey_running do
                local list = get_autobuy_honey_list()
                for _, item in ipairs(list) do
                    game:GetService("ReplicatedStorage"):WaitForChild("GameEvents"):WaitForChild("BuyEventShopStock"):FireServer(item)
                    task.wait(0.15)
                end
                task.wait(1)
            end
        end)
    else
        autobuy_honey_running = false
        autobuy_honey_toggle.Text = "Start Autobuy"
        autobuy_honey_toggle.BackgroundColor3 = Theme.Button
    end
end)

-- Start Mutation ESP
local mutEspBtn = Instance.new("TextButton", MainTab)
mutEspBtn.Size = UDim2.new(buttonWidth, 0, 0, buttonHeight)
mutEspBtn.Position = UDim2.new(rightButtonX, 0, 0, rightButtonStartY + (buttonHeight + rightButtonSpacing) * 1)
mutEspBtn.BackgroundColor3 = Theme.Button
mutEspBtn.TextColor3 = Theme.Text
mutEspBtn.Font = Enum.Font.GothamBold
mutEspBtn.TextSize = 15
mutEspBtn.Text = "Start Mutation ESP"
Instance.new("UICorner", mutEspBtn).CornerRadius = UDim.new(0, 8)

local mutEspRunning = false
local mutEspThread

local function clr()
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BillboardGui") and v.Name == "MutationESP" then v:Destroy() end
    end
end

local c = {
    Wet=Color3.fromRGB(100,200,255),Gold=Color3.fromRGB(255,215,0),Frozen=Color3.fromRGB(135,206,235),
    Rainbow=Color3.fromRGB(255,0,255),Choc=Color3.fromRGB(120,72,0),Chilled=Color3.fromRGB(170,230,255),
    Shocked=Color3.fromRGB(255,255,100),Moonlit=Color3.fromRGB(150,100,255),Bloodlit=Color3.fromRGB(200,10,60),
    Celestial=Color3.fromRGB(200,255,255),Disco=Color3.fromRGB(255,120,255),Zombified=Color3.fromRGB(80,255,100),
    Plasma=Color3.fromRGB(60,255,255),["Honey Glazed"]=Color3.fromRGB(255, 200, 75),Pollinated=Color3.fromRGB(225, 255, 130)
}

mutEspBtn.MouseButton1Click:Connect(function()
    mutEspRunning = not mutEspRunning
    if mutEspRunning then
        mutEspBtn.Text = "Disable Mutation ESP"
        mutEspBtn.BackgroundColor3 = Theme.Accent2
        mutEspThread = coroutine.create(function()
            local mutations = {
                "Wet","Gold","Frozen","Rainbow","Choc","Chilled","Shocked","Moonlit","Bloodlit","Celestial",
                "Disco","Zombified","Plasma","Honey Glazed","Pollinated"
            }
            while mutEspRunning do
                clr()
                local g = getMyFarm()
                if g then
                    local pl = g.Important:FindFirstChild("Plants_Physical")
                    if pl then
                        for _, pt in ipairs(pl:GetChildren()) do
                            local fnd = {}
                            for _, mm in ipairs(mutations) do
                                if pt:GetAttribute(mm) then table.insert(fnd, mm) end
                            end
                            if #fnd > 0 then
                                local bp = pt:FindFirstChildWhichIsA("BasePart") or pt.PrimaryPart
                                if bp then
                                    local gui = Instance.new("BillboardGui")
                                    gui.Name = "MutationESP"
                                    gui.Adornee = bp
                                    gui.Size = UDim2.new(0, 100, 0, 20)
                                    gui.AlwaysOnTop = true
                                    gui.StudsOffset = Vector3.new(0, 6, 0)
                                    local lbl = Instance.new("TextLabel", gui)
                                    lbl.Size = UDim2.new(1, 0, 1, 0)
                                    lbl.BackgroundTransparency = 1
                                    lbl.Text = table.concat(fnd, " + ")
                                    lbl.TextColor3 = c[fnd[1]] or Color3.new(1,1,1)
                                    lbl.TextScaled = false
                                    lbl.TextSize = 12
                                    lbl.Font = Enum.Font.GothamBold
                                    gui.Parent = bp
                                end
                            end
                        end
                    end
                end
                wait(5)
            end
        end)
        coroutine.resume(mutEspThread)
    else
        mutEspBtn.Text = "Start Mutation ESP"
        mutEspBtn.BackgroundColor3 = Theme.Button
        clr()
    end
end)

-- Start Honey ESP
local honeyEspBtn = Instance.new("TextButton", MainTab)
honeyEspBtn.Size = UDim2.new(buttonWidth, 0, 0, buttonHeight)
honeyEspBtn.Position = UDim2.new(rightButtonX, 0, 0, rightButtonStartY + (buttonHeight + rightButtonSpacing) * 2)
honeyEspBtn.BackgroundColor3 = Theme.Button
honeyEspBtn.TextColor3 = Theme.Text
honeyEspBtn.Font = Enum.Font.GothamBold
honeyEspBtn.TextSize = 15
honeyEspBtn.Text = "Start Honey ESP"
Instance.new("UICorner", honeyEspBtn).CornerRadius = UDim.new(0, 8)

local honeyEspRunning = false
local honeyEspThread

honeyEspBtn.MouseButton1Click:Connect(function()
    honeyEspRunning = not honeyEspRunning
    local mutationName = "Pollinated"
    local mutationColor = Color3.fromRGB(255, 225, 80)
    local function clearESP()
        for _,v in ipairs(workspace:GetDescendants()) do
            if v:IsA("BillboardGui") and v.Name=="MutationESP" then v:Destroy() end
        end
    end
    local function getMyFarm()
        for _,farm in ipairs(workspace.Farm:GetChildren()) do
            local d = farm:FindFirstChild("Important") and farm.Important:FindFirstChild("Data")
            if d and d:FindFirstChild("Owner") and d.Owner.Value == localPlayer.Name then
                return farm
            end
        end
    end
    local function showPollinatedESP()
        clearESP()
        local myFarm = getMyFarm()
        if not myFarm then return end
        local plants = myFarm.Important and myFarm.Important:FindFirstChild("Plants_Physical")
        if not plants then return end
        for _,plant in ipairs(plants:GetChildren()) do
            if plant:GetAttribute(mutationName) then
                for _,bp in ipairs(plant:GetDescendants()) do
                    if bp:IsA("BasePart") then
                        local gui = Instance.new("BillboardGui")
                        gui.Name = "MutationESP"
                        gui.Adornee = bp
                        gui.Size = UDim2.new(0, 100, 0, 20)
                        gui.AlwaysOnTop = true
                        gui.StudsOffset = Vector3.new(0, 6, 0)
                        local lbl = Instance.new("TextLabel", gui)
                        lbl.Size = UDim2.new(1, 0, 1, 0)
                        lbl.BackgroundTransparency = 1
                        lbl.Text = mutationName
                        lbl.TextColor3 = mutationColor
                        lbl.TextSize = 13
                        lbl.Font = Enum.Font.GothamBold
                        gui.Parent = bp
                    end
                end
            end
        end
    end

    if honeyEspRunning then
        honeyEspBtn.Text = "Disable Honey ESP"
        honeyEspBtn.BackgroundColor3 = Theme.Accent2
        honeyEspThread = coroutine.create(function()
            while honeyEspRunning do
                showPollinatedESP()
                wait(5)
            end
        end)
        coroutine.resume(honeyEspThread)
    else
        honeyEspBtn.Text = "Start Honey ESP"
        honeyEspBtn.BackgroundColor3 = Theme.Button
        if honeyEspThread then
            honeyEspRunning = false
            honeyEspThread = nil
        end
        -- Clear ESP immediately when disabled
        local function clearESP()
            for _,v in ipairs(workspace:GetDescendants()) do
                if v:IsA("BillboardGui") and v.Name=="MutationESP" then v:Destroy() end
            end
        end
        clearESP()
    end
end)

-- Place this code after your Start Honey ESP button setup in the MainTab section

-- Auto Submit Fruits Button (underneath Start Honey ESP)
local autoSubmitBtn = Instance.new("TextButton", MainTab)
autoSubmitBtn.Size = UDim2.new(buttonWidth, 0, 0, buttonHeight)
autoSubmitBtn.Position = UDim2.new(rightButtonX, 0, 0, rightButtonStartY + (buttonHeight + rightButtonSpacing) * 3)
autoSubmitBtn.BackgroundColor3 = Theme.Button
autoSubmitBtn.TextColor3 = Theme.Text
autoSubmitBtn.Font = Enum.Font.GothamBold
autoSubmitBtn.TextSize = 15
autoSubmitBtn.Text = "Auto Submit Fruits"
Instance.new("UICorner", autoSubmitBtn).CornerRadius = UDim.new(0, 8)

local autoSubmitRunning = false
local autoSubmitThread

autoSubmitBtn.MouseButton1Click:Connect(function()
    autoSubmitRunning = not autoSubmitRunning
    if autoSubmitRunning then
        autoSubmitBtn.Text = "Disable Auto Submit"
        autoSubmitBtn.BackgroundColor3 = Theme.Accent2
        autoSubmitThread = task.spawn(function()
            local Players = game:GetService("Players")
            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            local localPlayer = Players.LocalPlayer

            local function getPollinatedFruitTool()
                for _, item in ipairs(localPlayer.Backpack:GetChildren()) do
                    if item:GetAttribute("Pollinated") then
                        return item
                    end
                end
                return nil
            end

            local function equipTool(tool)
                local char = localPlayer.Character
                if tool and char then
                    local humanoid = char:FindFirstChildOfClass("Humanoid")
                    if humanoid and tool.Parent ~= char then
                        humanoid:EquipTool(tool)
                        task.wait(0.15)
                    end
                end
            end

            while autoSubmitRunning do
                local tool = getPollinatedFruitTool()
                if tool then
                    equipTool(tool)
                    local args = { "MachineInteract" }
                    ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("HoneyMachineService_RE"):FireServer(unpack(args))
                    task.wait(0.2)
                else
                    task.wait(1)
                end
            end
        end)
    else
        autoSubmitBtn.Text = "Auto Submit Fruits"
        autoSubmitBtn.BackgroundColor3 = Theme.Button
        if autoSubmitThread then
            task.cancel(autoSubmitThread)
            autoSubmitThread = nil
        end
    end
end)

-- Place this code right after your Auto Submit Fruits button code in the MainTab setup

local collectJarBtn = Instance.new("TextButton", MainTab)
collectJarBtn.Size = UDim2.new(buttonWidth, 0, 0, buttonHeight)
collectJarBtn.Position = UDim2.new(rightButtonX, 0, 0, rightButtonStartY + (buttonHeight + rightButtonSpacing) * 4)
collectJarBtn.BackgroundColor3 = Theme.Button
collectJarBtn.TextColor3 = Theme.Text
collectJarBtn.Font = Enum.Font.GothamBold
collectJarBtn.TextSize = 15
collectJarBtn.Text = "Collect Jar"
Instance.new("UICorner", collectJarBtn).CornerRadius = UDim.new(0, 8)

local collectJarRunning = false
local collectJarThread

collectJarBtn.MouseButton1Click:Connect(function()
    collectJarRunning = not collectJarRunning
    if collectJarRunning then
        collectJarBtn.Text = "Stop Collect Jar"
        collectJarBtn.BackgroundColor3 = Theme.Accent2
        collectJarThread = task.spawn(function()
            while collectJarRunning do
                -- Teleport to the coordinates, fire the nearest prompt 3 times (with small delay between)
                local Players = game:GetService("Players")
                local localPlayer = Players.LocalPlayer
                local POSITION = Vector3.new(-111.56, 4, -7.60)

                local char = localPlayer.Character or localPlayer.CharacterAdded:Wait()
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.CFrame = CFrame.new(POSITION)
                    task.wait(0.3)
                    -- Find nearest enabled ProximityPrompt
                    local nearestPrompt, nearestDist = nil, math.huge
                    for _, part in ipairs(workspace:GetDescendants()) do
                        if part:IsA("ProximityPrompt") and part.Enabled then
                            local parent = part.Parent
                            if parent and parent:IsA("BasePart") then
                                local dist = (parent.Position - POSITION).Magnitude
                                if dist < nearestDist then
                                    nearestPrompt = part
                                    nearestDist = dist
                                end
                            end
                        end
                    end
                    if nearestPrompt then
                        for i = 1, 3 do
                            fireproximityprompt(nearestPrompt)
                            task.wait(0.2)
                        end
                        print("Fired prompt '" .. nearestPrompt.Name .. "' 3 times.")
                    else
                        warn("No enabled ProximityPrompt found near the teleport location.")
                    end
                end
                -- Wait 60 seconds before next attempt
                for i = 1, 60 do
                    if not collectJarRunning then break end
                    task.wait(1)
                end
            end
        end)
    else
        collectJarBtn.Text = "Collect Jar"
        collectJarBtn.BackgroundColor3 = Theme.Button
        if collectJarThread then
            task.cancel(collectJarThread)
            collectJarThread = nil
        end
    end
end)



-- Honey Collect Only logic
local honeyCollecting = false
local honeyCollectThread

local function isInventoryFull()
    return #localPlayer.Backpack:GetChildren() >= 200
end

local function getMyHoneyCrops()
    local myFarm = getMyFarm()
    local crops = {}
    if myFarm then
        local plants = myFarm:FindFirstChild("Important") and myFarm.Important:FindFirstChild("Plants_Physical")
        if plants then
            for _, plant in pairs(plants:GetChildren()) do
                for _, part in pairs(plant:GetDescendants()) do
                    if part:IsA("BasePart") and part:FindFirstChildOfClass("ProximityPrompt") then
                        local parPlant = part.Parent
                        if parPlant and (parPlant:GetAttribute("Honey Glazed") or parPlant:GetAttribute("Pollinated")) then
                            table.insert(crops, part)
                        end
                        break
                    end
                end
            end
        end
    end
    return crops
end

local function honeyCollectLoop()
    while honeyCollecting do
        clr()
        local g = getMyFarm()
        if g then
            local pl = g.Important:FindFirstChild("Plants_Physical")
            if pl then
                for _, pt in ipairs(pl:GetChildren()) do
                    local fnd = {}
                    for _, mm in ipairs({"Honey Glazed", "Pollinated"}) do
                        if pt:GetAttribute(mm) then table.insert(fnd, mm) end
                    end
                    if #fnd > 0 then
                        local bp = pt:FindFirstChildWhichIsA("BasePart") or pt.PrimaryPart
                        if bp then
                            local gui = Instance.new("BillboardGui")
                            gui.Name = "MutationESP"
                            gui.Adornee = bp
                            gui.Size = UDim2.new(0, 100, 0, 20)
                            gui.AlwaysOnTop = true
                            gui.StudsOffset = Vector3.new(0, 6, 0)
                            local lbl = Instance.new("TextLabel", gui)
                            lbl.Size = UDim2.new(1, 0, 1, 0)
                            lbl.BackgroundTransparency = 1
                            lbl.Text = table.concat(fnd, " + ")
                            lbl.TextColor3 = c[fnd[1]] or Color3.new(1,1,1)
                            lbl.TextScaled = false
                            lbl.TextSize = 12
                            lbl.Font = Enum.Font.GothamBold
                            gui.Parent = bp
                        end
                    end
                end
            end
        end

        if isInventoryFull() then
            honeyCollectBtn.Text = "Backpack Full!"
            repeat
                task.wait(0.5)
            until not isInventoryFull() or not honeyCollecting
            honeyCollectBtn.Text = "Stop Honey Collect Only"
        end
        if not honeyCollecting then break end

        local crops = getMyHoneyCrops()
        for _, crop in ipairs(crops) do
            if not honeyCollecting then return end
            if isInventoryFull() then break end
            local char = localPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp and crop and crop.Parent then
                hrp.CFrame = CFrame.new(crop.Position + Vector3.new(0, 3, 0))
                task.wait(0.15)
                local prompt = crop:FindFirstChildOfClass("ProximityPrompt")
                if prompt then
                    pcall(function()
                        fireproximityprompt(prompt)
                    end)
                    task.wait(0.1)
                end
            end
        end
        task.wait(0.2)
    end
    honeyCollectBtn.Text = "Start Honey Collect Only"
    honeyCollectBtn.BackgroundColor3 = Theme.Button
    clr()
end

honeyCollectBtn.MouseButton1Click:Connect(function()
    honeyCollecting = not honeyCollecting
    if honeyCollecting then
        honeyCollectBtn.Text = "Stop Honey Collect Only"
        honeyCollectBtn.BackgroundColor3 = Theme.Accent2
        honeyCollectThread = task.spawn(honeyCollectLoop)
    else
        honeyCollectBtn.Text = "Start Honey Collect Only"
        honeyCollectBtn.BackgroundColor3 = Theme.Button
        if honeyCollectThread then
            task.cancel(honeyCollectThread)
            honeyCollectThread = nil
        end
        clr()
    end
end)



local HttpService = game:GetService("HttpService")
local CONFIG_FILE = "MyGardenConfig.json"
local Theme = Theme

local SettingsTab = CreateTab("Settings")

local settings_leftX = 0.075
local settings_rightX = 0.62
local settings_btnWidth = 0.36
local settings_btnHeight = 36
local settings_topY = 40
local settings_spacing = 16

local notifLabel = Instance.new("TextLabel", SettingsTab)
notifLabel.Size = UDim2.new(1, -40, 0, 22)
notifLabel.Position = UDim2.new(0, 20, 0, 12)
notifLabel.BackgroundTransparency = 1
notifLabel.TextColor3 = Theme.Accent2
notifLabel.Font = Enum.Font.Gotham
notifLabel.TextSize = 16
notifLabel.Text = ""
notifLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Join Low Server (Left, Row 1)
local joinLowServerBtn = Instance.new("TextButton", SettingsTab)
joinLowServerBtn.Size = UDim2.new(settings_btnWidth, 0, 0, settings_btnHeight)
joinLowServerBtn.Position = UDim2.new(settings_leftX, 0, 0, settings_topY)
joinLowServerBtn.BackgroundColor3 = Theme.Accent
joinLowServerBtn.TextColor3 = Theme.Text
joinLowServerBtn.Font = Enum.Font.GothamBold
joinLowServerBtn.TextSize = 18
joinLowServerBtn.Text = "Join Low Server"
Instance.new("UICorner", joinLowServerBtn).CornerRadius = UDim.new(0, 12)
joinLowServerBtn.MouseButton1Click:Connect(function()
    notifLabel.Text = "Searching for low server..."
    local Http = game:GetService("HttpService")
    local servers = {}
    local cursor = ""
    local minPlayers, bestId = math.huge, nil
    local placeId = game.PlaceId
    local function fetchServers()
        local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100", placeId)
        if cursor ~= "" then
            url = url.."&cursor="..cursor
        end
        local response = game:HttpGet(url)
        local data = Http:JSONDecode(response)
        for _, server in ipairs(data.data or {}) do
            if server.playing < minPlayers and server.playing > 0 and not server.full then
                minPlayers = server.playing
                bestId = server.id
            end
        end
        cursor = data.nextPageCursor or ""
        return cursor ~= ""
    end
    -- Try to find a low server (up to 3 pages)
    for i = 1,3 do
        if not fetchServers() then break end
    end
    if bestId then
        notifLabel.Text = "Teleporting to low server..."
        game:GetService("TeleportService"):TeleportToPlaceInstance(placeId, bestId)
    else
        notifLabel.Text = "No suitable server found!"
    end
end)

-- Delete Other Farms (Right, Row 1)
local otherFarmBtn = Instance.new("TextButton", SettingsTab)
otherFarmBtn.Size = UDim2.new(settings_btnWidth, 0, 0, settings_btnHeight)
otherFarmBtn.Position = UDim2.new(settings_rightX, 0, 0, settings_topY)
otherFarmBtn.BackgroundColor3 = Theme.Button
otherFarmBtn.TextColor3 = Theme.Text
otherFarmBtn.Font = Enum.Font.GothamBold
otherFarmBtn.TextSize = 18
otherFarmBtn.Text = "Delete Other Farms"
Instance.new("UICorner", otherFarmBtn).CornerRadius = UDim.new(0, 12)
otherFarmBtn.MouseButton1Click:Connect(function()
    local myName = game.Players.LocalPlayer.Name
    for _, farm in ipairs(workspace.Farm:GetChildren()) do
        local data = farm:FindFirstChild("Important") and farm.Important:FindFirstChild("Data")
        if data and data:FindFirstChild("Owner") and data.Owner.Value ~= myName then
            farm:Destroy()
        end
    end
    notifLabel.Text = "Other farms deleted."
    otherFarmBtn.Visible = false
end)

-- === CONFIG HELPERS ===
local function getSelected(tbl)
    local out = {}
    for k, v in pairs(tbl) do
        if v then table.insert(out, k) end
    end
    return out
end

local function setSelected(tbl, checkboxes, arr)
    for k,_ in pairs(tbl) do tbl[k] = false end
    for _,v in ipairs(arr or {}) do
        tbl[v] = true
    end
    for name, btn in pairs(checkboxes or {}) do
        local checked = tbl[name]
        if btn then
            btn.Text = checked and "[✔] "..name or "[  ] "..name
            btn.BackgroundColor3 = checked and Theme.Accent or Theme.Button
        end
    end
end

local function loadConfig()
    if isfile(CONFIG_FILE) then
        local ok, data = pcall(function()
            return HttpService:JSONDecode(readfile(CONFIG_FILE))
        end)
        return ok and data or {}
    end
    return {}
end
local function saveConfig(config)
    writefile(CONFIG_FILE, HttpService:JSONEncode(config))
end
local function resetConfig()
    if isfile(CONFIG_FILE) then delfile(CONFIG_FILE) end
end

-- Save Config (Left, Row 2)
local saveBtn = Instance.new("TextButton", SettingsTab)
saveBtn.Size = UDim2.new(settings_btnWidth, 0, 0, settings_btnHeight)
saveBtn.Position = UDim2.new(settings_leftX, 0, 0, settings_topY + settings_btnHeight + settings_spacing)
saveBtn.BackgroundColor3 = Theme.Accent
saveBtn.TextColor3 = Theme.Text
saveBtn.Font = Enum.Font.GothamBold
saveBtn.TextSize = 18
saveBtn.Text = "Save Config"
Instance.new("UICorner", saveBtn).CornerRadius = UDim.new(0, 12)
saveBtn.MouseButton1Click:Connect(function()
    local config = {
        autobuy = getSelected(autobuy_selected),
        autoplant = getSelected(autoplant_selected),
        autogear = getSelected(autobuy_gear_selected),
        webhook = webhookBox and webhookBox.Text or "",
    }
    saveConfig(config)
    notifLabel.Text = "✅ Config saved!"
end)

-- Reset Config (Right, Row 2)
local resetBtn = Instance.new("TextButton", SettingsTab)
resetBtn.Size = UDim2.new(settings_btnWidth, 0, 0, settings_btnHeight)
resetBtn.Position = UDim2.new(settings_rightX, 0, 0, settings_topY + settings_btnHeight + settings_spacing)
resetBtn.BackgroundColor3 = Theme.Button
resetBtn.TextColor3 = Theme.Text
resetBtn.Font = Enum.Font.GothamBold
resetBtn.TextSize = 18
resetBtn.Text = "Reset Config"
Instance.new("UICorner", resetBtn).CornerRadius = UDim.new(0, 12)
resetBtn.MouseButton1Click:Connect(function()
    resetConfig()
    setSelected(autobuy_selected, checkboxes, {})
    setSelected(autoplant_selected, checkboxes_plant, {})
    setSelected(autobuy_gear_selected, gears_checkboxes, {})
    if webhookBox then webhookBox.Text = "" end
    notifLabel.Text = "Config reset."
end)

-- Reduce Lag (Left, Row 3)
local reduceLagBtn = Instance.new("TextButton", SettingsTab)
reduceLagBtn.Size = UDim2.new(settings_btnWidth, 0, 0, settings_btnHeight)
reduceLagBtn.Position = UDim2.new(settings_leftX, 0, 0, settings_topY + (settings_btnHeight + settings_spacing) * 2)
reduceLagBtn.BackgroundColor3 = Theme.Accent
reduceLagBtn.TextColor3 = Theme.Text
reduceLagBtn.Font = Enum.Font.GothamBold
reduceLagBtn.TextSize = 18
reduceLagBtn.Text = "Reduce Lag"
Instance.new("UICorner", reduceLagBtn).CornerRadius = UDim.new(0, 12)
reduceLagBtn.MouseButton1Click:Connect(function()
    pcall(function()
        local l=game:GetService("Lighting")
        l.GlobalShadows=false l.FogEnd=1e10 l.Brightness=0 l.EnvironmentDiffuseScale=0 l.EnvironmentSpecularScale=0 l.OutdoorAmbient=Color3.new(0,0,0)
        local t=workspace:FindFirstChildOfClass("Terrain")
        if t then t.WaterWaveSize=0 t.WaterWaveSpeed=0 t.WaterReflectance=0 t.WaterTransparency=1 end
        for _,v in pairs(game:GetDescendants()) do
            if v:IsA("Decal")or v:IsA("Texture")or v:IsA("ShirtGraphic")or v:IsA("Accessory")or v:IsA("Clothing")then v:Destroy()
            elseif v:IsA("ParticleEmitter")or v:IsA("Trail")then v.Enabled=false
            elseif v:IsA("Explosion")then v.Visible=false
            elseif v:IsA("MeshPart")or v:IsA("Part")or v:IsA("UnionOperation")then v.Material=Enum.Material.SmoothPlastic v.Reflectance=0 v.CastShadow=false end
        end
        workspace.StreamingEnabled=true workspace.StreamingMinRadius=32 workspace.StreamingTargetRadius=64
        settings().Rendering.QualityLevel=Enum.QualityLevel.Level01 settings().Rendering.EditQualityLevel=Enum.QualityLevel.Level01
        for _,o in pairs(workspace:GetDescendants())do
            if o:IsA("BasePart")then pcall(function()o.TextureID=""end) o.CastShadow=false end
            if o:IsA("ParticleEmitter")or o:IsA("Beam")or o:IsA("Trail")then o.Enabled=false end
            if o:IsA("BasePart")and(o.Name=="Wall"or o.Name=="ColorWall")then o:Destroy()end
        end
    end)
    notifLabel.Text = "Lag reduced!"
end)

-- === AUTOLOAD CONFIG ON SCRIPT START ===
task.spawn(function()
    local config = loadConfig()
    if config.autobuy then setSelected(autobuy_selected, checkboxes, config.autobuy) end
    if config.autoplant then setSelected(autoplant_selected, checkboxes_plant, config.autoplant) end
    if config.autogear then setSelected(autobuy_gear_selected, gears_checkboxes, config.autogear) end
    if config.webhook and webhookBox then webhookBox.Text = config.webhook end
end)




local HttpService = game:GetService("HttpService")
local webhookReq = (syn and syn.request) or (http and http.request) or http_request or request or httprequest
local localPlayer = game:GetService("Players").LocalPlayer
local UserInputService = game:GetService("UserInputService")

local WebhookTab = CreateTab("Webhook")

local webhookFrame = Instance.new("Frame", WebhookTab)
webhookFrame.Size = UDim2.new(1, -40, 0, 64)
webhookFrame.Position = UDim2.new(0, 20, 0, 28)
webhookFrame.BackgroundColor3 = Theme.Button
Instance.new("UICorner", webhookFrame).CornerRadius = UDim.new(0, 12)

local webhookBox = Instance.new("TextBox", webhookFrame)
webhookBox.Size = UDim2.new(1, -54, 1, 0)
webhookBox.Position = UDim2.new(0, 12, 0, 0)
webhookBox.BackgroundTransparency = 1
webhookBox.TextColor3 = Theme.Text
webhookBox.Font = Enum.Font.Gotham
webhookBox.TextSize = 18
webhookBox.Text = ""
webhookBox.PlaceholderText = "Paste your Discord webhook here..."
webhookBox.ClearTextOnFocus = false

local checkBtn = Instance.new("TextButton", webhookFrame)
checkBtn.Size = UDim2.new(0, 44, 0, 44)
checkBtn.Position = UDim2.new(1, -50, 0.5, -22)
checkBtn.BackgroundColor3 = Theme.Accent
checkBtn.TextColor3 = Theme.Text
checkBtn.Font = Enum.Font.GothamBold
checkBtn.TextSize = 28
checkBtn.Text = "✔"
Instance.new("UICorner", checkBtn).CornerRadius = UDim.new(0, 12)

local notifLabel = Instance.new("TextLabel", WebhookTab)
notifLabel.Size = UDim2.new(1, -40, 0, 22)
notifLabel.Position = UDim2.new(0, 20, 0, 100)
notifLabel.BackgroundTransparency = 1
notifLabel.TextColor3 = Theme.Accent2
notifLabel.Font = Enum.Font.Gotham
notifLabel.TextSize = 16
notifLabel.Text = ""
notifLabel.TextXAlignment = Enum.TextXAlignment.Left

-- === SLIDER (PC+MOBILE DRAGGABLE) ===
local sliderFrame = Instance.new("Frame", WebhookTab)
sliderFrame.Size = UDim2.new(1, -40, 0, 26)
sliderFrame.Position = UDim2.new(0, 20, 0, 130)
sliderFrame.BackgroundColor3 = Theme.Button
Instance.new("UICorner", sliderFrame).CornerRadius = UDim.new(0, 10)

local sliderBar = Instance.new("Frame", sliderFrame)
sliderBar.Size = UDim2.new(1, -44, 0, 8)
sliderBar.Position = UDim2.new(0, 22, 0.5, -4)
sliderBar.BackgroundColor3 = Theme.Accent
Instance.new("UICorner", sliderBar).CornerRadius = UDim.new(0, 4)

local sliderKnob = Instance.new("Frame", sliderFrame)
sliderKnob.Size = UDim2.new(0, 22, 0, 22)
sliderKnob.Position = UDim2.new(0, 22, 0.5, -11)
sliderKnob.BackgroundColor3 = Theme.Accent2
Instance.new("UICorner", sliderKnob).CornerRadius = UDim.new(1, 0)
sliderKnob.ZIndex = 2

local sliderLabel = Instance.new("TextLabel", WebhookTab)
sliderLabel.Size = UDim2.new(1, -40, 0, 24)
sliderLabel.Position = UDim2.new(0, 20, 0, 162)
sliderLabel.BackgroundTransparency = 1
sliderLabel.TextColor3 = Theme.Text
sliderLabel.Font = Enum.Font.Gotham
sliderLabel.TextSize = 17
sliderLabel.TextXAlignment = Enum.TextXAlignment.Left
sliderLabel.Text = "Send notification every 3 minutes"

local minValue, maxValue = 1, 60
local sliderDragging = false
local sliderValue = 1

local dragInputConn
local function setSliderKnobFromValue(val)
    local barWidth = sliderBar.AbsoluteSize.X
    local rel = (val - minValue) / (maxValue - minValue)
    local knobX = rel * barWidth
    sliderKnob.Position = UDim2.new(0, 22 + knobX - sliderKnob.Size.X.Offset / 2, 0.5, -11)
end
local function updateSliderFromX(x)
    local left = sliderBar.AbsolutePosition.X
    local width = sliderBar.AbsoluteSize.X
    local rel = math.clamp((x - left) / width, 0, 1)
    sliderValue = math.clamp(math.floor(minValue + rel * (maxValue - minValue) + 0.5), minValue, maxValue)
    setSliderKnobFromValue(sliderValue)
    sliderLabel.Text = ("Send notification every %d minute%s"):format(sliderValue, sliderValue == 1 and "" or "s")
end
local function startDrag(input)
    sliderDragging = true
    updateSliderFromX(input.Position.X)
    if dragInputConn then dragInputConn:Disconnect() end
    dragInputConn = UserInputService.InputChanged:Connect(function(moveInput)
        if sliderDragging and (moveInput.UserInputType == Enum.UserInputType.MouseMovement or moveInput.UserInputType == Enum.UserInputType.Touch) then
            updateSliderFromX(moveInput.Position.X)
        end
    end)
end
local function endDrag()
    sliderDragging = false
    if dragInputConn then dragInputConn:Disconnect() end
end

sliderKnob.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        startDrag(input)
    end
end)
sliderKnob.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        endDrag()
    end
end)
sliderBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        startDrag(input)
    end
end)
sliderBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        endDrag()
    end
end)
sliderFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        startDrag(input)
    end
end)
sliderFrame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        endDrag()
    end
end)

setSliderKnobFromValue(sliderValue)
sliderLabel.Text = ("Send notification every %d minute%s"):format(sliderValue, sliderValue == 1 and "" or "s")

-- === WEBHOOK LOGIC (CUMULATIVE GAINS ONLY, EXCLUDING STARTING ITEMS/SEEDS) ===
local leaderstats = localPlayer:WaitForChild("leaderstats")
local shecklesStat = leaderstats:WaitForChild("Sheckles")

local webhookActive = false
local webhookUrl = ""
local trackerThread = nil
local sessionStart = tick()
local startingInventory = {}
local cumulativeGained = {}

-- Group by base name (ignore [brackets])
local function getBaseName(name)
    local base = name:match("^(.-) %b[]")
    if base then return base end
    base = name:match("^(.-)%[")
    if base then return base:sub(1, -2) end
    return name
end

-- Track both items and seeds in backpack
local function getCurrentInventory()
    local counts = {}
    for _, item in ipairs(localPlayer.Backpack:GetChildren()) do
        local rawName = item:GetAttribute("Seed") or item.Name
        local baseName = getBaseName(rawName)
        counts[baseName] = (counts[baseName] or 0) + 1
    end
    return counts
end

local function updateCumulativeGained()
    local current = getCurrentInventory()
    for item, count in pairs(current) do
        local startCount = startingInventory[item] or 0
        local gainedNow = count - startCount
        if gainedNow > 0 then
            cumulativeGained[item] = math.max(cumulativeGained[item] or 0, gainedNow)
        end
    end
end

local function formatTotalsGained()
    local lines = {}
    for item, gained in pairs(cumulativeGained) do
        if gained > 0 then
            table.insert(lines, ("%s: %d"):format(item, gained))
        end
    end
    table.sort(lines)
    return #lines > 0 and table.concat(lines, "\n") or "No new items/seeds gained."
end

local function fmt(n)
    if n >= 1e9 then return ("%.2fB"):format(n/1e9)
    elseif n >= 1e6 then return ("%.2fM"):format(n/1e6)
    elseif n >= 1e3 then return ("%.2fK"):format(n/1e3)
    else return tostring(n)
    end
end

local function sendWebhook(username, currentMoney, uptime)
    if webhookUrl == "" then return end
    local embed = {
        title = ("%s's Garden Gained Items/Seeds"):format(username),
        color = 0x48db6a,
        fields = {
            { name = "Total Money", value = fmt(currentMoney), inline = false },
            { name = "Items/Seeds Gained", value = ("```%s```"):format(formatTotalsGained()), inline = false },
            { name = "Session Uptime", value = uptime, inline = false }
        }
    }
    local payload = { embeds = {embed} }
    local success, err = pcall(function()
        webhookReq{
            Url = webhookUrl,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(payload)
        }
    end)
    if success then
        notifLabel.Text = "✅ Webhook sent!"
    else
        notifLabel.Text = "❌ Failed to send webhook."
    end
end

local function startWebhook()
    webhookActive = true
    notifLabel.Text = "Webhook tracking started."
    sessionStart = tick()
    if trackerThread then
        task.cancel(trackerThread)
    end
    startingInventory = getCurrentInventory() -- snapshot at start
    cumulativeGained = {} -- reset
    trackerThread = task.spawn(function()
        while webhookActive do
            for i = 1, sliderValue * 60 do
                if not webhookActive then return end
                task.wait(1)
                updateCumulativeGained() -- update gains as you go
            end
            local nowMoney = shecklesStat.Value
            local uptime = os.date("!%X", math.floor(tick() - sessionStart))
            sendWebhook(localPlayer.Name, nowMoney, uptime)
        end
    end)
end

local function stopWebhook()
    webhookActive = false
    notifLabel.Text = "Webhook tracking stopped."
    if trackerThread then
        task.cancel(trackerThread)
        trackerThread = nil
    end
end

checkBtn.MouseButton1Click:Connect(function()
    local url = webhookBox.Text
    if url == "" or not url:find("discord.com/api/webhooks/") then
        notifLabel.Text = "❌ Please enter a valid Discord webhook URL!"
        return
    end
    webhookUrl = url
    notifLabel.Text = "Webhook set! ✔️"
    stopWebhook()
    startWebhook()
end)


-- === DRAGGABLE MAIN FRAME ===
local dragging = false
local dragStart, startPos, dragInput
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
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
        dragging = false
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input == dragInput then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)


-- === MINIMIZE/RESTORE BUTTONS (Grow-a-Garden UI STYLE) ===
local TweenService = game:GetService("TweenService")

-- Minimize button (top right, inside MainFrame)
local MinimizeButton = Instance.new("TextButton", MainFrame)
MinimizeButton.Text = "-"
MinimizeButton.Size = UDim2.new(0, 26, 0, 26)
MinimizeButton.Position = UDim2.new(1, -32, 0, 8)
MinimizeButton.BackgroundColor3 = Theme.Accent
MinimizeButton.TextColor3 = Theme.Text
MinimizeButton.Font = Enum.Font.GothamBold
MinimizeButton.TextSize = 20
Instance.new("UICorner", MinimizeButton).CornerRadius = UDim.new(0, 8)

-- Reopen button (centered in screenGui, hidden by default)
local ReopenButton = Instance.new("TextButton", screenGui)
ReopenButton.Text = "Open UI"
ReopenButton.Size = UDim2.new(0, 140, 0, 38)
ReopenButton.Position = UDim2.new(0.5, 0, 0, 18)
ReopenButton.AnchorPoint = Vector2.new(0.5, 0)
ReopenButton.BackgroundColor3 = Theme.Button
ReopenButton.TextColor3 = Theme.Text
ReopenButton.Font = Enum.Font.GothamBold
ReopenButton.TextSize = 18
ReopenButton.Visible = false
Instance.new("UICorner", ReopenButton).CornerRadius = UDim.new(0, 7)

local isMinimized = false
local origSize = MainFrame.Size
local origPos = MainFrame.Position

MinimizeButton.MouseButton1Click:Connect(function()
    if not isMinimized then
        isMinimized = true
        TweenService:Create(MainFrame, TweenInfo.new(0.22, Enum.EasingStyle.Quint), {
            Size = UDim2.new(0, 180, 0, 38),
            Position = UDim2.new(0.5, 0, 0, -50)
        }):Play()
        task.wait(0.22)
        MainFrame.Visible = false
        ReopenButton.Visible = true
    end
end)

ReopenButton.MouseButton1Click:Connect(function()
    if isMinimized then
        isMinimized = false
        MainFrame.Visible = true
        ReopenButton.Visible = false
        TweenService:Create(MainFrame, TweenInfo.new(0.22, Enum.EasingStyle.Quint), {
            Size = origSize,
            Position = origPos
        }):Play()
    end
end)
