

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

-- === AUTOPLANT TAB ===
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

local function get_my_farm()
    for _, farm in ipairs(workspace:WaitForChild("Farm"):GetChildren()) do
        local important = farm:FindFirstChild("Important")
        local ownerVal = important and important:FindFirstChild("Data") and important.Data:FindFirstChild("Owner")
        if ownerVal and ownerVal.Value == localPlayer.Name then
            return farm
        end
    end
    return nil
end

local function shuffle(t)
    local n = #t
    for i = n, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
end

local function get_seed_tool(seedList)
    for _, seedName in ipairs(seedList) do
        for _, item in ipairs(localPlayer.Backpack:GetChildren()) do
            if item:GetAttribute("ITEM_TYPE") == "Seed" and item:GetAttribute("Seed") == seedName then
                return item, seedName
            end
        end
        local char = localPlayer.Character
        if char then
            for _, item in ipairs(char:GetChildren()) do
                if item:IsA("Tool") and item:GetAttribute("ITEM_TYPE") == "Seed" and item:GetAttribute("Seed") == seedName then
                    return item, seedName
                end
            end
        end
    end
    return nil, nil
end

local function equip_seed(tool)
    if tool and localPlayer.Character then
        local humanoid = localPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid and tool.Parent ~= localPlayer.Character then
            humanoid:EquipTool(tool)
            task.wait(0.07)
        end
    end
end

autoplant_toggle.MouseButton1Click:Connect(function()
    if not autoplant_running then
        autoplant_running = true
        autoplant_toggle.Text = "Stop Autoplant"
        autoplant_toggle.BackgroundColor3 = Theme.Accent2
        autoplant_thread = task.spawn(function()
            while autoplant_running do
                local list = get_autoplant_list()
                if #list == 0 then
                    task.wait(0.7)
                    continue
                end
                local myFarm = get_my_farm()
                if myFarm then
                    local plantLocations = myFarm:FindFirstChild("Important") and myFarm.Important:FindFirstChild("Plant_Locations")
                    if plantLocations then
                        local allPlots = {}
                        for _, plot in ipairs(plantLocations:GetChildren()) do
                            if plot:IsA("BasePart") then
                                table.insert(allPlots, plot)
                            end
                        end
                        shuffle(allPlots)
                        while autoplant_running do
                            local tool, seedName = get_seed_tool(list)
                            if not tool then
                                task.wait(0.7)
                                break
                            end
                            equip_seed(tool)
                            shuffle(allPlots)
                            for _, spot in ipairs(allPlots) do
                                if not autoplant_running then return end
                                ReplicatedStorage.GameEvents.Plant_RE:FireServer(spot.Position, seedName)
                                task.wait(0.09)
                                break
                            end
                            task.wait(0.08)
                        end
                    end
                end
                task.wait(0.5)
            end
        end)
    else
        autoplant_running = false
        autoplant_toggle.Text = "Start Autoplant"
        autoplant_toggle.BackgroundColor3 = Theme.Button
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

-- === AUTOCOLLECT TAB ===
local AutocollectTab = CreateTab("Autocollect")
local autocollect_running = false
local autocollect_thread

local autocollect_toggle = Instance.new("TextButton", AutocollectTab)
autocollect_toggle.Size = UDim2.new(0.6, 0, 0, 38)
autocollect_toggle.Position = UDim2.new(0, 16, 0, 30)
autocollect_toggle.BackgroundColor3 = Theme.Button
autocollect_toggle.TextColor3 = Theme.Text
autocollect_toggle.Font = Enum.Font.GothamBold
autocollect_toggle.TextSize = 18
autocollect_toggle.Text = "Start Autocollect"
Instance.new("UICorner", autocollect_toggle).CornerRadius = UDim.new(0, 7)

local COLLECT_DISTANCE = 17 -- hardcoded max
local function get_plant_locations()
    local myFarm = get_my_farm()
    if myFarm and myFarm:FindFirstChild("Important") and myFarm.Important:FindFirstChild("Plant_Locations") then
        local locs = {}
        for _, part in ipairs(myFarm.Important.Plant_Locations:GetChildren()) do
            if part:IsA("BasePart") then
                table.insert(locs, part.Position)
            end
        end
        if #locs >= 2 then
            return {locs[1], locs[2]}
        elseif #locs == 1 then
            return {locs[1], locs[1]}
        end
    end
    return {Vector3.new(0,0,0), Vector3.new(0,0,0)}
end

local function fire_proximity_prompt(prompt)
    if fireproximityprompt then
        fireproximityprompt(prompt)
    else
        local vi = game:GetService("VirtualInputManager")
        vi:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        vi:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    end
end

autocollect_toggle.MouseButton1Click:Connect(function()
    if not autocollect_running then
        autocollect_running = true
        autocollect_toggle.Text = "Stop Autocollect"
        autocollect_toggle.BackgroundColor3 = Theme.Accent2
        autocollect_thread = task.spawn(function()
            while autocollect_running do
                local character = localPlayer.Character
                local hrp = character and character:FindFirstChild("HumanoidRootPart")
                local myFarm = get_my_farm()
                if hrp and myFarm and myFarm:FindFirstChild("Important") and myFarm.Important:FindFirstChild("Plants_Physical") then
                    local plants_physical = myFarm.Important.Plants_Physical
                    local tps = get_plant_locations()
                    for _, tpPos in ipairs(tps) do
                        hrp.CFrame = CFrame.new(tpPos + Vector3.new(0, 3, 0))
                        task.wait(0.1)
                        for _, plant in ipairs(plants_physical:GetChildren()) do
                            for _, descendant in ipairs(plant:GetDescendants()) do
                                if descendant:IsA("ProximityPrompt") and descendant.Enabled and descendant.Parent then
                                    local dist = (hrp.Position - descendant.Parent.Position).Magnitude
                                    if dist <= COLLECT_DISTANCE then
                                        fire_proximity_prompt(descendant)
                                        task.wait(0.03)
                                    end
                                end
                            end
                        end
                        task.wait(0.1)
                    end
                end
                task.wait(0.3)
            end
        end)
    else
        autocollect_running = false
        autocollect_toggle.Text = "Start Autocollect"
        autocollect_toggle.BackgroundColor3 = Theme.Button
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
