--[[
  Improved "Grow-a-Garden" UI with "Farm" Tab, modern visuals, and essential farm automation buttons:
    - Autobuy Seeds
    - Autoplant
    - Autocollect

  Combines your modern UI style with extra game mechanic code.
  All logic is modular for extensibility.
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

-- === SETTINGS & STATE ===
local settings = {
    auto_buy_seeds = false,
    use_distance_check = true,
    collection_distance = 17,
    collect_nearest_fruit = true,
    debug_mode = false,
}
local selected_seed = "Carrot"
local plant_position = nil
local is_auto_planting = false
local is_auto_collecting = false

local seedsList = {'Carrot', 'Strawberry', "Blueberry", 'Orange Tulip', 'Tomato', 'Corn', 'Watermelon', 'Daffodil', "Pumpkin", 'Apple', 'Bamboo', 'Coconut', 'Cactus', 'Dragon Fruit', 'Mango', 'Grape', 'Mushroom', 'Pepper', 'Cacao', 'Beanstalk'}

local GameEvents = ReplicatedStorage:WaitForChild("GameEvents")
local buySeedEvent = GameEvents:WaitForChild("BuySeedStock")
local plantSeedEvent = GameEvents:WaitForChild("Plant_RE")

-- === GAME LOGIC ===
local function get_player_farm()
    for _, farm in ipairs(workspace.Farm:GetChildren()) do
        local important_folder = farm:FindFirstChild("Important")
        if important_folder then
            local owner_value = important_folder:FindFirstChild("Data") and important_folder.Data:FindFirstChild("Owner")
            if owner_value and owner_value.Value == localPlayer.Name then
                return farm
            end
        end
    end
    return nil
end

local function buy_seed(seed_name)
    if playerGui.Seed_Shop and playerGui.Seed_Shop.Frame.ScrollingFrame[seed_name] then
        local t = playerGui.Seed_Shop.Frame.ScrollingFrame[seed_name].Main_Frame.Cost_Text
        if t.TextColor3 ~= Color3.fromRGB(255, 0, 0) then
            buySeedEvent:FireServer(seed_name)
        end
    end
end

local function equip_seed(seed_name)
    local character = localPlayer.Character
    if not character then return false end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end

    for _, item in ipairs(localPlayer.Backpack:GetChildren()) do
        if item:GetAttribute("ITEM_TYPE") == "Seed" and item:GetAttribute("Seed") == seed_name then
            humanoid:EquipTool(item)
            task.wait()
            local equipped_tool = character:FindFirstChildOfClass("Tool")
            if equipped_tool and equipped_tool:GetAttribute("ITEM_TYPE") == "Seed" and equipped_tool:GetAttribute("Seed") == seed_name then
                return equipped_tool
            end
        end
    end

    local equipped_tool = character:FindFirstChildOfClass("Tool")
    if equipped_tool and equipped_tool:GetAttribute("ITEM_TYPE") == "Seed" and equipped_tool:GetAttribute("Seed") == seed_name then
        return equipped_tool
    end

    return false
end

local function auto_collect_fruits()
    while is_auto_collecting do
        local character = localPlayer.Character
        local player_root_part = character and character:FindFirstChild("HumanoidRootPart")
        local current_farm = get_player_farm()

        if not (player_root_part and current_farm and current_farm.Important and current_farm.Important.Plants_Physical) then
            task.wait(0.5)
            continue
        end

        local plants_physical = current_farm.Important.Plants_Physical

        if settings.collect_nearest_fruit then
            local nearest_prompt = nil
            local min_distance = math.huge

            for _, plant in ipairs(plants_physical:GetChildren()) do
                for _, descendant in ipairs(plant:GetDescendants()) do
                    if descendant:IsA("ProximityPrompt") and descendant.Enabled and descendant.Parent then
                        local distance_to_fruit = (player_root_part.Position - descendant.Parent.Position).Magnitude
                        local can_collect = not settings.use_distance_check or (distance_to_fruit <= settings.collection_distance)
                        if can_collect and distance_to_fruit < min_distance then
                            min_distance = distance_to_fruit
                            nearest_prompt = descendant
                        end
                    end
                end
            end

            if nearest_prompt then
                fireproximityprompt(nearest_prompt)
                task.wait(0.05)
            end
        else
            for _, plant in ipairs(plants_physical:GetChildren()) do
                for _, fruit_prompt in ipairs(plant:GetDescendants()) do
                    if fruit_prompt:IsA("ProximityPrompt") and fruit_prompt.Enabled and fruit_prompt.Parent then
                        local collect_this = not settings.use_distance_check or ((player_root_part.Position - fruit_prompt.Parent.Position).Magnitude <= settings.collection_distance)
                        if collect_this then
                            fireproximityprompt(fruit_prompt)
                            task.wait(0.05)
                        end
                    end
                end
            end
        end
        task.wait()
    end
end

local function auto_plant_seeds(seed_name)
    while is_auto_planting do
        local seed_in_hand = equip_seed(seed_name)
        if not seed_in_hand and settings.auto_buy_seeds then
            buy_seed(seed_name)
            task.wait(0.1)
            seed_in_hand = equip_seed(seed_name)
        end

        if seed_in_hand and plant_position then
            local quantity = seed_in_hand:GetAttribute("Quantity")
            if quantity and quantity > 0 then
                plantSeedEvent:FireServer(plant_position, seed_name)
                task.wait(0.1)
            end
        end
        task.wait(0.2)
    end
end

-- === UI CONSTRUCTION (Modernized) ===

local Theme = {
    Background = Color3.fromRGB(13, 16, 20),
    Button = Color3.fromRGB(36, 41, 49),
    Accent = Color3.fromRGB(56, 132, 255),
    Text = Color3.fromRGB(255, 255, 255)
}
local screenGui = Instance.new("ScreenGui", playerGui)
screenGui.Name = "BetterGardenTabbedUI"

local MainFrame = Instance.new("Frame", screenGui)
MainFrame.Size = UDim2.new(0, 560, 0, 340)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
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
Title.Text = "🌱 Grow-a-Garden Hub"
Title.Size = UDim2.new(1, -30, 0, 32)
Title.Position = UDim2.new(0, 18, 0, 10)
Title.BackgroundTransparency = 1
Title.TextColor3 = Theme.Text
Title.Font = Enum.Font.GothamBold
Title.TextSize = 21
Title.TextXAlignment = Enum.TextXAlignment.Left

local TabsFrame = Instance.new("Frame", MainFrame)
TabsFrame.Size = UDim2.new(0, 140, 1, -50)
TabsFrame.Position = UDim2.new(0, 14, 0, 46)
TabsFrame.BackgroundColor3 = Theme.Button
TabsFrame.ClipsDescendants = true
Instance.new("UICorner", TabsFrame).CornerRadius = UDim.new(0, 7)

local TabsScroll = Instance.new("ScrollingFrame", TabsFrame)
TabsScroll.Size = UDim2.new(1, 0, 1, 0)
TabsScroll.Position = UDim2.new(0, 0, 0, 0)
TabsScroll.BackgroundTransparency = 1
TabsScroll.ScrollBarThickness = 6
TabsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
TabsScroll.VerticalScrollBarInset = Enum.ScrollBarInset.Always
TabsScroll.ScrollingDirection = Enum.ScrollingDirection.Y
TabsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

local TabContentFrame = Instance.new("Frame", MainFrame)
TabContentFrame.Size = UDim2.new(1, -170, 1, -50)
TabContentFrame.Position = UDim2.new(0, 160, 0, 46)
TabContentFrame.BackgroundColor3 = Theme.Background
TabContentFrame.ClipsDescendants = true
Instance.new("UICorner", TabContentFrame).CornerRadius = UDim.new(0, 7)

local Tabs = {}
local function CreateTab(tabName)
    local TabButton = Instance.new("TextButton", TabsScroll)
    TabButton.Text = tabName
    TabButton.Size = UDim2.new(1, -12, 0, 35)
    TabButton.Position = UDim2.new(0, 6, 0, (#Tabs * 40))
    TabButton.BackgroundColor3 = Theme.Button
    TabButton.TextColor3 = Theme.Text
    TabButton.Font = Enum.Font.GothamBold
    TabButton.TextSize = 17
    TabButton.AutoButtonColor = true
    Instance.new("UICorner", TabButton).CornerRadius = UDim.new(0, 7)
    -- Highlight on select
    TabButton.MouseButton1Down:Connect(function()
        for i, frame in ipairs(Tabs) do
            frame.Visible = false
            TabsScroll:GetChildren()[i].BackgroundColor3 = Theme.Button
        end
        TabButton.BackgroundColor3 = Theme.Accent
        Tabs[#Tabs].Visible = true
    end)
    TabsScroll.CanvasSize = UDim2.new(0, 0, 0, (#Tabs + 1) * 40 + 8)
    local TabFrame = Instance.new("Frame", TabContentFrame)
    TabFrame.Size = UDim2.new(1, 0, 1, 0)
    TabFrame.Visible = (#Tabs == 0)
    TabFrame.BackgroundTransparency = 1
    table.insert(Tabs, TabFrame)
    return TabFrame
end

local function CreateButton(parent, text, callback, ypos)
    local Button = Instance.new("TextButton", parent)
    Button.Text = text
    Button.Size = UDim2.new(0.88, 0, 0, 36)
    Button.Position = UDim2.new(0.06, 0, 0, ypos)
    Button.BackgroundColor3 = Theme.Button
    Button.TextColor3 = Theme.Text
    Button.Font = Enum.Font.Gotham
    Button.TextSize = 16
    Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 7)
    Button.MouseEnter:Connect(function()
        Button.BackgroundColor3 = Theme.Accent
    end)
    Button.MouseLeave:Connect(function()
        Button.BackgroundColor3 = Theme.Button
    end)
    Button.MouseButton1Click:Connect(callback)
    return Button
end

local function CreateToggle(parent, text, getValue, setValue, ypos)
    local Toggle = Instance.new("TextButton", parent)
    Toggle.Text = text .. ": " .. (getValue() and "ON" or "OFF")
    Toggle.Size = UDim2.new(0.88, 0, 0, 36)
    Toggle.Position = UDim2.new(0.06, 0, 0, ypos)
    Toggle.BackgroundColor3 = getValue() and Theme.Accent or Theme.Button
    Toggle.TextColor3 = Theme.Text
    Toggle.Font = Enum.Font.Gotham
    Toggle.TextSize = 16
    Instance.new("UICorner", Toggle).CornerRadius = UDim.new(0, 7)
    Toggle.MouseButton1Click:Connect(function()
        local newValue = not getValue()
        setValue(newValue)
        Toggle.Text = text .. ": " .. (newValue and "ON" or "OFF")
        Toggle.BackgroundColor3 = newValue and Theme.Accent or Theme.Button
    end)
    return Toggle
end

local function CreateDropdown(parent, label, getValue, setValue, items, ypos)
    local Label = Instance.new("TextLabel", parent)
    Label.Text = label .. ":"
    Label.Size = UDim2.new(0.4, 0, 0, 28)
    Label.Position = UDim2.new(0.06, 0, 0, ypos)
    Label.BackgroundTransparency = 1
    Label.TextColor3 = Theme.Text
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 15

    local Drop = Instance.new("TextButton", parent)
    Drop.Text = getValue()
    Drop.Size = UDim2.new(0.46, 0, 0, 28)
    Drop.Position = UDim2.new(0.5, 0, 0, ypos)
    Drop.BackgroundColor3 = Theme.Button
    Drop.TextColor3 = Theme.Text
    Drop.Font = Enum.Font.Gotham
    Drop.TextSize = 15
    Instance.new("UICorner", Drop).CornerRadius = UDim.new(0, 7)

    Drop.MouseButton1Click:Connect(function()
        local menu = Instance.new("Frame", parent)
        menu.Size = UDim2.new(0.46, 0, 0, #items * 26)
        menu.Position = UDim2.new(0.5, 0, 0, ypos + 28)
        menu.BackgroundColor3 = Theme.Background
        menu.ZIndex = 2
        for i, v in ipairs(items) do
            local opt = Instance.new("TextButton", menu)
            opt.Text = v
            opt.Size = UDim2.new(1, 0, 0, 26)
            opt.Position = UDim2.new(0, 0, 0, (i-1)*26)
            opt.BackgroundColor3 = Theme.Button
            opt.TextColor3 = Theme.Text
            opt.Font = Enum.Font.Gotham
            opt.TextSize = 15
            opt.ZIndex = 3
            Instance.new("UICorner", opt).CornerRadius = UDim.new(0, 5)
            opt.MouseButton1Click:Connect(function()
                setValue(v)
                Drop.Text = v
                menu:Destroy()
            end)
        end
        menu.MouseLeave:Connect(function() menu:Destroy() end)
    end)
end

-- === FARM TAB ===
local FarmTab = CreateTab("Farm")

local ypos = 12
CreateDropdown(FarmTab, "Seed", function() return selected_seed end, function(v) selected_seed = v end, seedsList, ypos)
ypos = ypos + 38

CreateButton(FarmTab, "Set Plant Position (use where you stand)", function()
    local character = localPlayer.Character
    local root_part = character and character:FindFirstChild("HumanoidRootPart")
    if root_part then
        plant_position = root_part.Position
        Title.Text = "🌱 Position set: " .. tostring(plant_position)
        task.delay(1.5, function() Title.Text = "🌱 Grow-a-Garden Hub" end)
    end
end, ypos)
ypos = ypos + 44

CreateToggle(FarmTab, "Autobuy Seed", function() return settings.auto_buy_seeds end, function(v) settings.auto_buy_seeds = v end, ypos)
ypos = ypos + 38

CreateToggle(FarmTab, "Autoplant", function() return is_auto_planting end, function(v)
    is_auto_planting = v
    if v then
        task.spawn(auto_plant_seeds, selected_seed)
    end
end, ypos)
ypos = ypos + 38

CreateToggle(FarmTab, "Autocollect", function() return is_auto_collecting end, function(v)
    is_auto_collecting = v
    if v then
        task.spawn(auto_collect_fruits)
    end
end, ypos)
ypos = ypos + 38

CreateToggle(FarmTab, "Collect Nearest Fruit", function() return settings.collect_nearest_fruit end, function(v) settings.collect_nearest_fruit = v end, ypos)
ypos = ypos + 38

CreateToggle(FarmTab, "Use Distance Check", function() return settings.use_distance_check end, function(v) settings.use_distance_check = v end, ypos)
ypos = ypos + 38

-- Collection Distance Slider (simple ugly implementation)
local sliderLabel = Instance.new("TextLabel", FarmTab)
sliderLabel.Text = "Collection Distance: " .. tostring(settings.collection_distance)
sliderLabel.Size = UDim2.new(0.7, 0, 0, 28)
sliderLabel.Position = UDim2.new(0.06, 0, 0, ypos)
sliderLabel.BackgroundTransparency = 1
sliderLabel.TextColor3 = Theme.Text
sliderLabel.Font = Enum.Font.Gotham
sliderLabel.TextSize = 15

local slider = Instance.new("TextButton", FarmTab)
slider.Text = "+"
slider.Size = UDim2.new(0.09, 0, 0, 28)
slider.Position = UDim2.new(0.76, 0, 0, ypos)
slider.BackgroundColor3 = Theme.Button
slider.TextColor3 = Theme.Accent
slider.Font = Enum.Font.Gotham
slider.TextSize = 17
Instance.new("UICorner", slider).CornerRadius = UDim.new(0, 7)
slider.MouseButton1Click:Connect(function()
    settings.collection_distance = math.min(settings.collection_distance + 1, 30)
    sliderLabel.Text = "Collection Distance: " .. tostring(settings.collection_distance)
end)

local slider2 = Instance.new("TextButton", FarmTab)
slider2.Text = "-"
slider2.Size = UDim2.new(0.09, 0, 0, 28)
slider2.Position = UDim2.new(0.66, 0, 0, ypos)
slider2.BackgroundColor3 = Theme.Button
slider2.TextColor3 = Theme.Accent
slider2.Font = Enum.Font.Gotham
slider2.TextSize = 17
Instance.new("UICorner", slider2).CornerRadius = UDim.new(0, 7)
slider2.MouseButton1Click:Connect(function()
    settings.collection_distance = math.max(settings.collection_distance - 1, 1)
    sliderLabel.Text = "Collection Distance: " .. tostring(settings.collection_distance)
end)

-- === DRAGGABLE UI ===
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

-- === SET PLANT POSITION DEFAULT ===
local farm = get_player_farm()
if farm and farm.Important and farm.Important.Plant_Locations then
    local default_plant_location = farm.Important.Plant_Locations:FindFirstChildOfClass("Part")
    if default_plant_location then
        plant_position = default_plant_location.Position
    else
        plant_position = Vector3.new(0,0,0)
    end
else
    plant_position = Vector3.new(0,0,0)
end
