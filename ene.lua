

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

local moneyBar = Instance.new("Frame", AutobuyTab)
moneyBar.Size = UDim2.new(0, 140, 0, 32)
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
moneyLabel.TextColor3 = Theme.Accent
moneyLabel.TextStrokeTransparency = 0.8
moneyLabel.Font = Enum.Font.GothamBold
moneyLabel.TextSize = 18
moneyLabel.TextXAlignment = Enum.TextXAlignment.Right
moneyLabel.Text = "$0"
moneyLabel.ZIndex = 3

-- Update loop
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

-- === AUTOSELL TAB ===
local AutosellTab = CreateTab("Autosell")
local autosell_running = false
local autosell_thread

local autosell_toggle = Instance.new("TextButton", AutosellTab)
autosell_toggle.Size = UDim2.new(0.6, 0, 0, 38)
autosell_toggle.Position = UDim2.new(0, 16, 0, 64)
autosell_toggle.BackgroundColor3 = Theme.Button
autosell_toggle.TextColor3 = Theme.Text
autosell_toggle.Font = Enum.Font.GothamBold
autosell_toggle.TextSize = 18
autosell_toggle.Text = "Start Autosell"
Instance.new("UICorner", autosell_toggle).CornerRadius = UDim.new(0, 7)

local autosell_threshold = 200
local sliderLabel = Instance.new("TextLabel", AutosellTab)
sliderLabel.Text = "Sell when backpack has at least: "..tostring(autosell_threshold)
sliderLabel.Size = UDim2.new(1, -20, 0, 24)
sliderLabel.Position = UDim2.new(0, 16, 0, 24)
sliderLabel.BackgroundTransparency = 1
sliderLabel.TextColor3 = Theme.Text
sliderLabel.Font = Enum.Font.GothamBold
sliderLabel.TextSize = 15
sliderLabel.TextXAlignment = Enum.TextXAlignment.Left

local sliderFrame = Instance.new("Frame", AutosellTab)
sliderFrame.BackgroundColor3 = Theme.Button
sliderFrame.Size = UDim2.new(0.9, 0, 0, 14)
sliderFrame.Position = UDim2.new(0, 16, 0, 48)
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
    autosell_threshold = math.floor(1 + rel * 199 + 0.5)
    local barPos = rel * width - sliderBar.Size.X.Offset/2
    sliderBar.Position = UDim2.new(0, barPos, 0.5, 0)
    sliderLabel.Text = "Sell when backpack has at least: "..tostring(autosell_threshold)
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

local function getHRP()
    local char = localPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

autosell_toggle.MouseButton1Click:Connect(function()
    if not autosell_running then
        autosell_running = true
        autosell_toggle.Text = "Stop Autosell"
        autosell_toggle.BackgroundColor3 = Theme.Accent2
        autosell_thread = task.spawn(function()
            local GE = ReplicatedStorage.GameEvents
            while autosell_running do
                local Backpack = localPlayer:FindFirstChild("Backpack")
                local hrp = getHRP()
                if Backpack and #Backpack:GetChildren() >= autosell_threshold and hrp then
                    local pos = hrp.CFrame
                    repeat
                        hrp.CFrame = workspace.Tutorial_Points.Tutorial_Point_2.CFrame
                        task.wait(0.2)
                        GE.Sell_Inventory:FireServer()
                        task.wait(0.2)
                    until not autosell_running or #Backpack:GetChildren()<autosell_threshold
                    hrp.CFrame = pos
                end
                task.wait(1)
            end
        end)
    else
        autosell_running = false
        autosell_toggle.Text = "Start Autosell"
        autosell_toggle.BackgroundColor3 = Theme.Button
    end
end)

-- === AUTOCOLLECT TAB (TP + AUTOCOLLECT + OPTIONAL AUTOSELL) ===
local AutocollectTab = CreateTab("Autocollect")

local autocollect_toggle = Instance.new("TextButton", AutocollectTab)
autocollect_toggle.Size = UDim2.new(0.6, 0, 0, 38)
autocollect_toggle.Position = UDim2.new(0, 16, 0, 30)
autocollect_toggle.BackgroundColor3 = Theme.Button
autocollect_toggle.TextColor3 = Theme.Text
autocollect_toggle.Font = Enum.Font.GothamBold
autocollect_toggle.TextSize = 18
autocollect_toggle.Text = "Start Autocollect"
Instance.new("UICorner", autocollect_toggle).CornerRadius = UDim.new(0, 7)

-- Autosell toggle just below
local autosell_collect_toggle = Instance.new("TextButton", AutocollectTab)
autosell_collect_toggle.Size = UDim2.new(0.6, 0, 0, 32)
autosell_collect_toggle.Position = UDim2.new(0, 16, 0, 76)
autosell_collect_toggle.BackgroundColor3 = Theme.Button
autosell_collect_toggle.TextColor3 = Theme.Text
autosell_collect_toggle.Font = Enum.Font.Gotham
autosell_collect_toggle.TextSize = 16
autosell_collect_toggle.Text = "Autosell When Full: OFF"
Instance.new("UICorner", autosell_collect_toggle).CornerRadius = UDim.new(0, 7)
local autosell_when_full = false

autosell_collect_toggle.MouseButton1Click:Connect(function()
    autosell_when_full = not autosell_when_full
    if autosell_when_full then
        autosell_collect_toggle.Text = "Autosell When Full: ON"
        autosell_collect_toggle.BackgroundColor3 = Theme.Accent
    else
        autosell_collect_toggle.Text = "Autosell When Full: OFF"
        autosell_collect_toggle.BackgroundColor3 = Theme.Button
    end
end)

local collecting = false
local collect_thread

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
    return #localPlayer.Backpack:GetChildren() >= 200
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

-- Mutation ESP Tab (with toggle button and compact ESP)
local EspTab = CreateTab("Mutation ESP")

local espToggle = Instance.new("TextButton", EspTab)
espToggle.Size = UDim2.new(0.7, 0, 0, 46)
espToggle.Position = UDim2.new(0.15, 0, 0, 32)
espToggle.BackgroundColor3 = Theme.Button
espToggle.TextColor3 = Theme.Text
espToggle.Font = Enum.Font.GothamBold
espToggle.TextSize = 22
espToggle.Text = "Start Mutation ESP"
Instance.new("UICorner", espToggle).CornerRadius = UDim.new(0, 8)

local espRunning = false
local espThread

local m={"Wet","Gold","Frozen","Rainbow","Choc","Chilled","Shocked","Moonlit","Bloodlit","Celestial","Disco","Zombified","Plasma"}
local c={Wet=Color3.fromRGB(100,200,255),Gold=Color3.fromRGB(255,215,0),Frozen=Color3.fromRGB(135,206,235),Rainbow=Color3.fromRGB(255,0,255),Choc=Color3.fromRGB(120,72,0),Chilled=Color3.fromRGB(170,230,255),Shocked=Color3.fromRGB(255,255,100),Moonlit=Color3.fromRGB(150,100,255),Bloodlit=Color3.fromRGB(200,10,60),Celestial=Color3.fromRGB(200,255,255),Disco=Color3.fromRGB(255,120,255),Zombified=Color3.fromRGB(80,255,100),Plasma=Color3.fromRGB(60,255,255)}
local p=game.Players.LocalPlayer

local function clr()
    for _,v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BillboardGui") and v.Name=="MutationESP" then v:Destroy() end
    end
end
local function grd()
    for _,f in ipairs(workspace.Farm:GetChildren()) do
        local d=f:FindFirstChild("Important") and f.Important:FindFirstChild("Data")
        if d and d:FindFirstChild("Owner") and d.Owner.Value==p.Name then return f end
    end
end

espToggle.MouseButton1Click:Connect(function()
    espRunning = not espRunning
    if espRunning then
        espToggle.Text = "Disable Mutation ESP"
        espToggle.BackgroundColor3 = Theme.Accent2
        espThread = coroutine.create(function()
            while espRunning do
                clr()
                local g=grd()
                if g then
                    local pl=g.Important:FindFirstChild("Plants_Physical")
                    if pl then
                        for _,pt in ipairs(pl:GetChildren()) do
                            local fnd={}
                            for _,mm in ipairs(m) do
                                if pt:GetAttribute(mm) then table.insert(fnd,mm) end
                            end
                            if #fnd>0 then
                                local bp=pt:FindFirstChildWhichIsA("BasePart") or pt.PrimaryPart
                                if bp then
                                    local gui=Instance.new("BillboardGui")
                                    gui.Name="MutationESP"
                                    gui.Adornee=bp
                                    gui.Size=UDim2.new(0,100,0,20)
                                    gui.AlwaysOnTop=true
                                    gui.StudsOffset=Vector3.new(0,6,0)
                                    local lbl=Instance.new("TextLabel",gui)
                                    lbl.Size=UDim2.new(1,0,1,0)
                                    lbl.BackgroundTransparency=1
                                    lbl.Text=table.concat(fnd," + ")
                                    lbl.TextColor3=c[fnd[1]] or Color3.new(1,1,1)
                                    lbl.TextScaled=false
                                    lbl.TextSize=12
                                    lbl.Font=Enum.Font.GothamBold
                                    gui.Parent=bp
                                end
                            end
                        end
                    end
                end
                wait(2)
            end
        end)
        coroutine.resume(espThread)
    else
        espToggle.Text = "Start Mutation ESP"
        espToggle.BackgroundColor3 = Theme.Button
        clr()
    end
end)

-- === SERVER TAB ===
local ServerTab = CreateTab("Server")

-- "Join Low Server" button
local joinLowBtn = Instance.new("TextButton", ServerTab)
joinLowBtn.Size = UDim2.new(0, 180, 0, 38)
joinLowBtn.Position = UDim2.new(0, 20, 0, 20)
joinLowBtn.BackgroundColor3 = Theme.Button
joinLowBtn.TextColor3 = Theme.Text
joinLowBtn.Font = Enum.Font.GothamBold
joinLowBtn.TextSize = 18
joinLowBtn.Text = "Join Low Server"
Instance.new("UICorner", joinLowBtn).CornerRadius = UDim.new(0, 7)

-- "Auto Hop" toggle
local autoHopToggle = Instance.new("TextButton", ServerTab)
autoHopToggle.Size = UDim2.new(0, 180, 0, 38)
autoHopToggle.Position = UDim2.new(0, 20, 0, 68)
autoHopToggle.BackgroundColor3 = Theme.Button
autoHopToggle.TextColor3 = Theme.Text
autoHopToggle.Font = Enum.Font.GothamBold
autoHopToggle.TextSize = 18
autoHopToggle.Text = "Auto Hop: OFF"
Instance.new("UICorner", autoHopToggle).CornerRadius = UDim.new(0, 7)

local autoHopEnabled = false

-- Player threshold slider
local thresholdLabel = Instance.new("TextLabel", ServerTab)
thresholdLabel.Text = "Hop if players > 28"
thresholdLabel.Size = UDim2.new(0, 170, 0, 22)
thresholdLabel.Position = UDim2.new(0, 25, 0, 118)
thresholdLabel.BackgroundTransparency = 1
thresholdLabel.TextColor3 = Theme.Text
thresholdLabel.Font = Enum.Font.Gotham
thresholdLabel.TextSize = 14
thresholdLabel.TextXAlignment = Enum.TextXAlignment.Left

local playerThreshold = 28
local sliderFrame = Instance.new("Frame", ServerTab)
sliderFrame.BackgroundColor3 = Theme.Button
sliderFrame.Size = UDim2.new(0, 130, 0, 10)
sliderFrame.Position = UDim2.new(0, 25, 0, 145)
Instance.new("UICorner", sliderFrame).CornerRadius = UDim.new(0, 5)

local sliderBar = Instance.new("Frame", sliderFrame)
sliderBar.BackgroundColor3 = Theme.Accent
sliderBar.Size = UDim2.new(0, 16, 1, 0)
sliderBar.Position = UDim2.new((playerThreshold-10)/30, 0, 0, 0)
Instance.new("UICorner", sliderBar).CornerRadius = UDim.new(0, 5)

-- Slider logic
local draggingSlider = false
local function setSliderFromX(x)
    local left = sliderFrame.AbsolutePosition.X
    local width = sliderFrame.AbsoluteSize.X
    local rel = math.clamp((x - left) / width, 0, 1)
    playerThreshold = math.floor(10 + rel * 30 + 0.5)
    sliderBar.Position = UDim2.new(rel, -8, 0, 0)
    thresholdLabel.Text = "Hop if players > "..tostring(playerThreshold)
end
sliderFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingSlider = true
        setSliderFromX(input.Position.X)
    end
end)
sliderFrame.InputEnded:Connect(function()
    draggingSlider = false
end)
sliderBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingSlider = true
        setSliderFromX(input.Position.X)
    end
end)
sliderBar.InputEnded:Connect(function()
    draggingSlider = false
end)
UserInputService.InputChanged:Connect(function(input)
    if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
        setSliderFromX(input.Position.X)
    end
end)
sliderBar.Position = UDim2.new((playerThreshold-10)/30, -8, 0, 0)

-- Server hop logic
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local PlaceId = game.PlaceId
local function getLowestServer()
    local servers = {}
    local cursor = nil
    repeat
        local url = "https://games.roblox.com/v1/games/"..PlaceId.."/servers/Public?sortOrder=Asc&limit=100"
        if cursor then url = url.."&cursor="..cursor end
        local data = HttpService:JSONDecode(game:HttpGet(url))
        for _, server in ipairs(data.data) do
            if server.playing < server.maxPlayers and server.id ~= game.JobId then
                table.insert(servers, { id = server.id, playing = server.playing })
            end
        end
        cursor = data.nextPageCursor
    until not cursor or #servers > 0
    table.sort(servers, function(a, b) return a.playing < b.playing end)
    return servers[1]
end
local function serverHop(target)
    if target then
        TeleportService:TeleportToPlaceInstance(PlaceId, target.id, Players.LocalPlayer)
    end
end

joinLowBtn.MouseButton1Click:Connect(function()
    local target = getLowestServer()
    if target then
        joinLowBtn.Text = "Teleporting..."
        serverHop(target)
    else
        joinLowBtn.Text = "No Server :("
        wait(2)
        joinLowBtn.Text = "Join Low Server"
    end
end)

local autoHopThread
autoHopToggle.MouseButton1Click:Connect(function()
    autoHopEnabled = not autoHopEnabled
    autoHopToggle.Text = autoHopEnabled and "Auto Hop: ON" or "Auto Hop: OFF"
    autoHopToggle.BackgroundColor3 = autoHopEnabled and Theme.Accent2 or Theme.Button
    if autoHopThread then
        task.cancel(autoHopThread)
        autoHopThread = nil
    end
    if autoHopEnabled then
        autoHopThread = task.spawn(function()
            while autoHopEnabled do
                if #Players:GetPlayers() > playerThreshold then
                    local target = getLowestServer()
                    if target then serverHop(target) end
                    break
                end
                task.wait(6)
            end
        end)
    end
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
