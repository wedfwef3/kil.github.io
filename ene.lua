-- GROW-A-GARDEN FULL MODERN UI SCRIPT
-- Includes: Farm (autobuy/autoplant, your farm only), Seeds, Gears, Event Shop, Pets, Local, ESP

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

-- === SHARED STATE ===
local tog = {
	sell=false,moonlit=false,harvest=false,tpw=false,infj=false,wander=false,hideplants=false,
	eggs=false,feed=false,esp=false,daily=false
}
local seeds = {
	{"Carrot",false},{"Strawberry",false},{"Blueberry",false},{"Orange Tulip",false},{"Tomato",false},{"Corn",false},
	{"Daffodil",false},{"Watermelon",false},{"Pumpkin",false},{"Apple",false},{"Bamboo",false},{"Coconut",false},
	{"Cactus",false},{"Dragon Fruit",false},{"Mango",false},{"Grape",false},{"Mushroom",false},{"Pepper",false},
	{"Cacao",false},{"Beanstalk",false},
}
local gears = {
	{"Watering Can",false},{"Trowel",false},{"Recall Wrench",false},{"Basic Sprinkler",false},{"Advanced Sprinkler",false},
	{"Godly Sprinkler",false},{"Lightning Rod",false},{"Master Sprinkler",false},
}
local event = {
	{"Mysterious Crate",false},{"Night Egg",false},{"Night Seed Pack",false},{"Blood Banana",false},{"Moon Melon",false},
	{"Star Caller",false},{"Blood Hedgehog",false},{"Blood Kiwi",false},{"Blood Owl",false},
}
local cd = {
	harvest=true,seeds=true,gears=true,evshop=true,sell=true,moonlit=true,wander=true,hideplants=true,
	eggs=true,esp=true,daily=true
}
local vals = {
	tpws=5,
	harvestmode="Aura",
	esp={
		gold=false,rgb=false,shock=false,wet=false,moonlit=false,
		bloodlit=false,celestial=false,frozen=false,chilled=false
	}
}
local binds = {}

-- === FARM DETECTION ===
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

-- === UI THEME ===
local Theme = {
    Background = Color3.fromRGB(15, 15, 15),
    Button = Color3.fromRGB(30, 30, 30),
    Text = Color3.fromRGB(255, 255, 255),
    Accent = Color3.fromRGB(56, 132, 255),
}

-- === UI ROOT ===
local screenGui = Instance.new("ScreenGui", playerGui)
screenGui.Name = "GardenModernTabbedUI"

local MainFrame = Instance.new("Frame", screenGui)
MainFrame.Size = UDim2.new(0, 540, 0, 340)
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
local TabButtons = {}
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
    TabsScroll.CanvasSize = UDim2.new(0, 0, 0, (#Tabs + 1) * 40 + 8)
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

local function CreateButton(parent, text, callback, position)
    local Button = Instance.new("TextButton", parent)
    Button.Text = text
    Button.Size = UDim2.new(0.92, 0, 0, 32)
    Button.Position = position
    Button.BackgroundColor3 = Theme.Button
    Button.TextColor3 = Theme.Text
    Button.Font = Enum.Font.Gotham
    Button.TextSize = 15
    Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 6)
    Button.MouseEnter:Connect(function()
        Button.BackgroundColor3 = Theme.Accent
    end)
    Button.MouseLeave:Connect(function()
        Button.BackgroundColor3 = Theme.Button
    end)
    Button.MouseButton1Click:Connect(callback)
    return Button
end

local function CreateToggle(parent, text, getValue, setValue, position)
    local Toggle = Instance.new("TextButton", parent)
    Toggle.Text = text .. ": " .. (getValue() and "ON" or "OFF")
    Toggle.Size = UDim2.new(0.92, 0, 0, 32)
    Toggle.Position = position
    Toggle.BackgroundColor3 = getValue() and Theme.Accent or Theme.Button
    Toggle.TextColor3 = Theme.Text
    Toggle.Font = Enum.Font.Gotham
    Toggle.TextSize = 15
    Instance.new("UICorner", Toggle).CornerRadius = UDim.new(0, 6)
    Toggle.MouseButton1Click:Connect(function()
        local newValue = not getValue()
        setValue(newValue)
        Toggle.Text = text .. ": " .. (newValue and "ON" or "OFF")
        Toggle.BackgroundColor3 = newValue and Theme.Accent or Theme.Button
    end)
    return Toggle
end

-- === FARM TAB (FIRST TAB!) ===
local FarmTab = CreateTab("Farm")
local farm_y = 8
for i, v in ipairs(seeds) do
    CreateToggle(FarmTab, v[1], function() return v[2] end, function(state) seeds[i][2] = state end, UDim2.new(0.05, 0, 0, farm_y))
    farm_y = farm_y + 34
end

CreateButton(FarmTab, "Buy All Enabled Seeds", function()
    for _, v in ipairs(seeds) do
        if v[2] then
            ReplicatedStorage.GameEvents.BuySeedStock:FireServer(v[1])
        end
    end
end, UDim2.new(0.05, 0, 0, farm_y))
farm_y = farm_y + 38

CreateButton(FarmTab, "Plant All Enabled Seeds (My Farm)", function()
    local myFarm = get_my_farm()
    if not myFarm then
        warn("Your farm not found!")
        return
    end
    local plantLocations = myFarm:FindFirstChild("Important") and myFarm.Important:FindFirstChild("Plant_Locations")
    if not plantLocations then
        warn("No plant locations in your farm!")
        return
    end
    for _, v in ipairs(seeds) do
        if v[2] then
            for _, spot in ipairs(plantLocations:GetChildren()) do
                if spot:IsA("BasePart") then
                    ReplicatedStorage.GameEvents.Plant_RE:FireServer(spot.Position, v[1])
                    task.wait(0.05)
                end
            end
        end
    end
end, UDim2.new(0.05, 0, 0, farm_y))
farm_y = farm_y + 38

CreateButton(FarmTab, "Plant All Enabled Seeds (at your Position)", function()
    local pos = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") and localPlayer.Character.HumanoidRootPart.Position
    if not pos then return end
    for _, v in ipairs(seeds) do
        if v[2] then
            ReplicatedStorage.GameEvents.Plant_RE:FireServer(pos, v[1])
            task.wait(0.05)
        end
    end
end, UDim2.new(0.05, 0, 0, farm_y))

-- === SEEDS TAB ===
local SeedsTab = CreateTab("Seeds")
local seeds_y = 5
for i, v in ipairs(seeds) do
    CreateToggle(SeedsTab, v[1], function() return v[2] end, function(n) seeds[i][2]=n end, UDim2.new(0.05, 0, 0, seeds_y))
    seeds_y = seeds_y + 31
end

-- === GEARS TAB ===
local GearsTab = CreateTab("Gears")
local gears_y = 5
for i, v in ipairs(gears) do
    CreateToggle(GearsTab, v[1], function() return v[2] end, function(n) gears[i][2]=n end, UDim2.new(0.05, 0, 0, gears_y))
    gears_y = gears_y + 31
end

-- === EVENT SHOP TAB ===
local EventTab = CreateTab("Event Shop")
local event_y = 5
for i, v in ipairs(event) do
    CreateToggle(EventTab, v[1], function() return v[2] end, function(n) event[i][2]=n end, UDim2.new(0.05, 0, 0, event_y))
    event_y = event_y + 31
end

-- === PETS TAB ===
local PetsTab = CreateTab("Pets")
CreateToggle(PetsTab, "Buy Eggs", function() return tog.eggs end, function(v) tog.eggs = v end, UDim2.new(0.05, 0, 0, 5))
CreateToggle(PetsTab, "Feed", function() return tog.feed end, function(v) tog.feed = v end, UDim2.new(0.05, 0, 0, 38))

-- === LOCAL PLAYER TAB ===
local LocalTab = CreateTab("Local Player")
CreateToggle(LocalTab, "Inf Jump", function() return tog.infj end, function(v) tog.infj = v end, UDim2.new(0.05, 0, 0, 5))
CreateToggle(LocalTab, "TP Walk", function() return tog.tpw end, function(v) tog.tpw = v end, UDim2.new(0.05, 0, 0, 38))

-- === ESP TAB ===
local EspTab = CreateTab("ESP")
CreateToggle(EspTab, "Enable ESP", function() return tog.esp end, function(v) tog.esp = v end, UDim2.new(0.05, 0, 0, 5))
-- Add more ESP filters here if you want

-- === DRAG MAIN FRAME ===
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
