local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- Mechanic State
local chr = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local hum = chr:FindFirstChildWhichIsA("Humanoid")
local hrp = chr:WaitForChild("HumanoidRootPart")
local vi = game:GetService("VirtualInputManager")
local GE = ReplicatedStorage.GameEvents

local tog = {
	sell=false, moonlit=false, harvest=false, tpw=false, infj=false, wander=false, hideplants=false,
	eggs=false, feed=false, esp=false, daily=false
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
	harvest=true, seeds=true, gears=true, evshop=true, sell=true, moonlit=true, wander=true, hideplants=true,
	eggs=true, esp=true, daily=true
}
local vals = {
	tpws=5,
	harvestmode="Aura",
	esp={
		gold=false, rgb=false, shock=false, wet=false, moonlit=false,
		bloodlit=false, celestial=false, frozen=false, chilled=false
	}
}
local binds = {}

if not workspace:FindFirstChild("platform") then
	local p = Instance.new("Part", workspace)
	p.Name = "platform"
	p.Transparency = 1
	p.Size = Vector3.new(3, .1, 3)
	p.Anchored = true
	p.CFrame = CFrame.new(0,0,0)
end
local platform = workspace:FindFirstChild("platform")
local UserFarm = nil
for _, v in pairs(workspace.Farm:GetChildren()) do
	if v.Important.Data.Owner.Value == LocalPlayer.Name then
		UserFarm = v
	end
end

function checkFruitAge(p)
	p = p.Parent
	return p.Grow.Age.Value >= p:GetAttribute("MaxAge")
end

function esp(v)
	local par, name = v.Parent, v.Name
	task.spawn(function()
		if v:IsA("BasePart") and "MeshPart" ~= v.ClassName and not v:FindFirstChild("sdaisdada1") then
			local a,b=nil,nil
			if "UnionOperation"==v.ClassName or v.Shape==Enum.PartType.Ball then
				a=Instance.new("SphereHandleAdornment",v)
				b=Instance.new("SphereHandleAdornment",a)
				a.Radius=v.Size.X/2
				b.Radius=v.Size.X/2+.1
			else
				a=Instance.new("BoxHandleAdornment",v)
				b=Instance.new("BoxHandleAdornment",a)
				a.Size=v.Size
				b.Size=v.Size+Vector3.new(.1,.1,.1)
				a.CFrame=CFrame.Angles(v.CFrame:ToOrientation())
				b.CFrame=CFrame.Angles(v.CFrame:ToOrientation())
			end
			a.Name="sdaisdada1"
			b.Name="sdaisdada2"
			a.Adornee=v
			b.Adornee=v
			a.AlwaysOnTop=true
			b.AlwaysOnTop=true
			a.ZIndex=1
			b.ZIndex=0
			a.Transparency=.4
			b.Transparency=0
			b.Color=BrickColor.new(1)
			a.Visible=false
			task.wait(.1)
			a.Visible=true
			while par:FindFirstChild(name) and par[name]:FindFirstChild("sdaisdada1") do
				a.Color = v.BrickColor
				task.wait(.05)
			end
		end
	end)
end

function rerender()
	if not UserFarm then return end
	for _, v in pairs(UserFarm.Important.Plants_Physical:GetDescendants()) do
		if v.Name == "sdaisdada1" or v.Name == "sdaisdada2" then
			v:Destroy()
		end
	end
end

if binds.main then pcall(function() binds.main:Disconnect() end) end
binds.main = RunService.RenderStepped:Connect(function()
	pcall(function()
		chr = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
		hum = chr:FindFirstChildWhichIsA("Humanoid")
		hrp = chr:FindFirstChild("HumanoidRootPart")
	end)
	if tog.tpw and chr and hum then
		if hum.MoveDirection.Magnitude > 0 then
			chr:TranslateBy(hum.MoveDirection * vals.tpws / 5)
		end
	end
	if tog.moonlit and cd.moonlit then
		cd.moonlit = false
		GE.NightQuestRemoteEvent:FireServer("SubmitAllPlants")
		task.wait(.2)
		cd.moonlit = true
	end
	if tog.sell and cd.sell then
		if #LocalPlayer.Backpack:GetChildren() > 199 then
			cd.sell = false
			local pos = hrp.CFrame
			repeat
				hrp.CFrame = workspace.Tutorial_Points.Tutorial_Point_2.CFrame
				task.wait()
				GE.Sell_Inventory:FireServer()
			until not tog.sell or #LocalPlayer.Backpack:GetChildren() < 200
			hrp.CFrame = pos
			cd.sell = true
		end
	end
	if tog.harvest and cd.harvest then
		cd.harvest = false
		pcall(function()
			local mode = vals.harvestmode
			if mode == "Aura" then
				for _,v in pairs(UserFarm.Important.Plants_Physical:GetDescendants()) do
					if v:IsA("ProximityPrompt") and checkFruitAge(v.Parent) and (v.Parent.Position-hrp.Position).Magnitude < 17 then
						fireproximityprompt(v)
					end
				end
				task.wait(.1)
			elseif mode == "Random" then
				local ps = UserFarm.Important.Plants_Physical:GetChildren()
				local fs = ps[math.random(1,#ps)].Fruits:GetChildren()
				local f = fs[math.random(1,#fs)]
				for _,v in pairs(f:GetChildren()) do
					local p = v:FindFirstChildWhichIsA("ProximityPrompt")
					if p and checkFruitAge(v) then
						fireproximityprompt(p)
						break
					end
				end
			elseif mode == "Scuffed" then
				local ps=UserFarm.Important.Plants_Physical:GetChildren()
				local fs=ps[math.random(1,#ps)].Fruits:GetChildren()
				local f=fs[math.random(1,#fs)]
				for _,v in pairs(f:GetChildren()) do
					local p = v:FindFirstChildWhichIsA("ProximityPrompt")
					if p and checkFruitAge(v) then
						vi:SendKeyEvent(true, Enum.KeyCode.E, false, game)
						vi:SendKeyEvent(false, Enum.KeyCode.E, false, game)
						hrp.CFrame = v.CFrame
						vi:SendKeyEvent(true, Enum.KeyCode.E, false, game)
						vi:SendKeyEvent(false, Enum.KeyCode.E, false, game)
						break
					end
				end
			else
				vi:SendKeyEvent(true, Enum.KeyCode.E, false, game)
				vi:SendKeyEvent(false, Enum.KeyCode.E, false, game)
			end
		end)
		cd.harvest = true
	end
	if cd.seeds then
		cd.seeds = false
		for k,v in pairs(seeds) do
			if v[2] then
				for i=0,5 do
					GE.BuySeedStock:FireServer(v[1])
				end
			end
		end
		task.wait(.5)
		cd.seeds = true
	end
	if cd.gears then
		cd.gears = false
		for k,v in pairs(gears) do
			if v[2] then
				GE.BuyGearStock:FireServer(v[1])
			end
		end
		task.wait(1)
		cd.gears = true
	end
	if cd.evshop then
		cd.evshop = false
		for k,v in pairs(event) do
			if v[2] then
				GE.BuyEventShopStock:FireServer(v[1])
			end
		end
		task.wait(1)
		cd.evshop = true
	end
	if tog.wander and cd.wander and #LocalPlayer.Backpack:GetChildren() < 200 then
		cd.wander = false
		local timeout = false
		local p,s = UserFarm.PetArea.Position,UserFarm.PetArea.Size
		local goal = nil
		local ps = UserFarm.Important.Plants_Physical:GetChildren()
		pcall(function()
			local fs = ps[math.random(1,#ps)].Fruits:GetChildren()
			for _,v in pairs(fs[math.random(1,#fs)]:GetChildren()) do
				local p = v:FindFirstChildWhichIsA("ProximityPrompt")
				if p and checkFruitAge(v) then
					goal = p.Parent.Position + Vector3.new(0,4,0)
					break
				end
			end
			TweenService:Create(hrp, TweenInfo.new(.5, Enum.EasingStyle.Linear), {CFrame = CFrame.new(goal.X,goal.Y,goal.Z)}):Play()
			task.spawn(function()
				task.wait(5)
				timeout = true
			end)
			repeat
				task.wait()
				platform.CFrame = hrp.CFrame - Vector3.new(0,2.3,0)
			until (goal-hrp.Position).Magnitude < 2 or timeout
		end)
		cd.wander = true
	end
	if tog.hideplants and cd.hideplants then
		cd.hideplants = false
		for _,v in pairs(UserFarm.Important.Plants_Physical:GetChildren()) do
			for _,i in pairs(v:GetChildren()) do
				if tonumber(i.Name) and (i:IsA("BasePart") or i:IsA("MeshPart")) then
					i.CanCollide = false
					i.Transparency = 1
				end
				if i.Name == "Branches" then
					for _,k in pairs(i:GetDescendants()) do
						if k:IsA("BasePart") or k:IsA("MeshPart") then
							k.CanCollide = false
							k.Transparency = 1
						end
					end
				end
			end
		end
		task.wait(.25)
		cd.hideplants = true
	end
	if tog.eggs and cd.eggs then
		cd.eggs = false
		for i=1,3 do
			GE.BuyPetEgg:FireServer(i)
		end
		task.wait(1)
		cd.eggs = true
	end
	if tog.feed then
		local p = {}
		for _,v in pairs(workspace.PetsPhysical:GetChildren()) do
			if v:GetAttribute("OWNER") == LocalPlayer.Name then
				table.insert(p, v:GetAttribute("UUID"))
			end
		end
		if #p > 0 then
			GE.ActivePetService:FireServer("Feed", p[math.random(1,#p)])
		end
	end
	if tog.esp and cd.esp then
		cd.esp = false
		for _,v in pairs(UserFarm.Important.Plants_Physical:GetChildren()) do
			pcall(function()
				for _,f in pairs(v.Fruits:GetChildren()) do
					local var = f.Variant.Value
					if ("Gold" == var and vals.esp.gold) or
					("Rainbow" == var and vals.esp.rgb) or
					(f:GetAttribute("Wet") and vals.esp.wet) or
					(f:GetAttribute("Shocked") and vals.esp.shock) or
					(f:GetAttribute("Moonlit") and vals.esp.moonlit) or
					(f:GetAttribute("Bloodlit") and vals.esp.bloodlit) or
					(f:GetAttribute("Celestial") and vals.esp.celestial) or
					(f:GetAttribute("Frozen") and vals.esp.frozen) or
					(f:GetAttribute("Chilled") and vals.esp.chilled) then
						for _,p in pairs(f:GetChildren()) do
							if tonumber(p.Name) and p:IsA("BasePart") then
								esp(p)
							end
						end
					end
				end
			end)
		end
		task.wait(1)
		cd.esp = true
	end
	if tog.daily then
		cd.daily = false
		ReplicatedStorage.ByteNetReliable:FireServer(buffer.fromstring("\002"))
		task.wait(1)
		cd.daily = true
	end
end)

if binds.jump then pcall(function() binds.jump:Disconnect() end) end
binds.jump = UIS.JumpRequest:Connect(function()
	if tog.infj and hum then
		hum:ChangeState("Jumping")
	end
end)

-- === UI CODE (Modern Tabbed UI) ===
local Theme = {
    Background = Color3.fromRGB(15, 15, 15),
    Button = Color3.fromRGB(30, 30, 30),
    Text = Color3.fromRGB(255, 255, 255)
}
local screenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
screenGui.Name = "GardenModernTabbedUI"

local MainFrame = Instance.new("Frame", screenGui)
MainFrame.Size = UDim2.new(0, 440, 0, 320)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.BackgroundColor3 = Theme.Background
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

local frameOutline = Instance.new("UIStroke")
frameOutline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
frameOutline.Thickness = 3
frameOutline.Parent = MainFrame
local hue = 0
RunService.RenderStepped:Connect(function()
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

local function CreateToggle(parent, text, getValue, setValue, position)
    local Toggle = Instance.new("TextButton", parent)
    Toggle.Text = text .. ": Off"
    Toggle.Size = UDim2.new(0.9, 0, 0, 36)
    Toggle.Position = position
    Toggle.BackgroundColor3 = Theme.Button
    Toggle.TextColor3 = Theme.Text
    Toggle.Font = Enum.Font.Gotham
    Toggle.TextSize = 15
    Instance.new("UICorner", Toggle).CornerRadius = UDim.new(0, 6)
    Toggle.MouseButton1Click:Connect(function()
        local newValue = not getValue()
        setValue(newValue)
        Toggle.Text = text .. ": " .. (newValue and "On" or "Off")
        Toggle.BackgroundColor3 = newValue and Color3.fromRGB(34, 177, 76) or Theme.Button
    end)
    return Toggle
end

-- MAIN TAB
local MainTab = CreateTab("Main")
CreateToggle(MainTab, "Auto Harvest", function() return tog.harvest end, function(v) tog.harvest = v end, UDim2.new(0.05, 0, 0, 10))
CreateToggle(MainTab, "Auto Sell", function() return tog.sell end, function(v) tog.sell = v end, UDim2.new(0.05, 0, 0, 56))
CreateToggle(MainTab, "Wander", function() return tog.wander end, function(v) tog.wander = v end, UDim2.new(0.05, 0, 0, 102))
CreateButton(MainTab, "Manual Sell", function()
    local pos = hrp.CFrame
    hrp.CFrame = workspace.Tutorial_Points.Tutorial_Point_2.CFrame
    task.wait(.1)
    repeat
        GE.Sell_Inventory:FireServer()
        task.wait(.1)
    until not tog.sell or #LocalPlayer.Backpack:GetChildren() < 200
    hrp.CFrame = pos
end, UDim2.new(0.05, 0, 0, 148))
CreateToggle(MainTab, "Give Moonlit Fruits", function() return tog.moonlit end, function(v) tog.moonlit = v end, UDim2.new(0.05, 0, 0, 194))
CreateToggle(MainTab, "Claim Daily Quest", function() return tog.daily end, function(v) tog.daily = v end, UDim2.new(0.05, 0, 0, 240))

-- SEEDS TAB
local SeedsTab = CreateTab("Seeds")
for i, v in ipairs(seeds) do
    CreateToggle(SeedsTab, v[1], function() return v[2] end, function(n) seeds[i][2]=n end, UDim2.new(0.05, 0, 0, 10 + (i-1)*40))
end

-- GEARS TAB
local GearsTab = CreateTab("Gears")
for i, v in ipairs(gears) do
    CreateToggle(GearsTab, v[1], function() return v[2] end, function(n) gears[i][2]=n end, UDim2.new(0.05, 0, 0, 10 + (i-1)*40))
end

-- EVENT SHOP TAB
local EventTab = CreateTab("Event Shop")
for i, v in ipairs(event) do
    CreateToggle(EventTab, v[1], function() return v[2] end, function(n) event[i][2]=n end, UDim2.new(0.05, 0, 0, 10 + (i-1)*40))
end

-- PETS TAB
local PetsTab = CreateTab("Pets")
CreateToggle(PetsTab, "Buy Eggs", function() return tog.eggs end, function(v) tog.eggs = v end, UDim2.new(0.05, 0, 0, 10))
CreateToggle(PetsTab, "Feed", function() return tog.feed end, function(v) tog.feed = v end, UDim2.new(0.05, 0, 0, 56))

-- LOCAL TAB
local LocalTab = CreateTab("Local Player")
CreateToggle(LocalTab, "Inf Jump", function() return tog.infj end, function(v) tog.infj = v end, UDim2.new(0.05, 0, 0, 10))
CreateToggle(LocalTab, "TP Walk", function() return tog.tpw end, function(v) tog.tpw = v end, UDim2.new(0.05, 0, 0, 56))
-- Add slider etc. as needed

-- ESP TAB (Simplified)
local EspTab = CreateTab("ESP")
CreateToggle(EspTab, "Enable ESP", function() return tog.esp end, function(v) tog.esp = v rerender() end, UDim2.new(0.05, 0, 0, 10))

-- Drag main frame (Must be after MainFrame creation)
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
UIS.InputChanged:Connect(function(input)
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
