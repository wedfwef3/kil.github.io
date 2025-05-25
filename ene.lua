local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local plr = Players.LocalPlayer
local character = plr.Character or plr.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

local targetNames = {
    "Bond", "GoldBar", "SilverBar", "Crucifix",
    "GoldStatue", "SilverStatue", "BrainJar"
}

local storageLocation = Vector3.new(57, 5, 30000)
local wasStored = {}
local sackCapacity = 10 -- Set to 15 if needed

local function TPTo(position)
    pcall(function()
        hrp.CFrame = CFrame.new(position)
    end)
    task.wait(0.4)
end

local function DestroyCase()
    local castle = Workspace:FindFirstChild("VampireCastle")
    if castle then
        for _, descendant in ipairs(castle:GetDescendants()) do
            if descendant:IsA("Model") and descendant.Name == "Bookcase" then
                descendant:Destroy()
            end
        end
    end
end

local function getSeat()
    DestroyCase()
    local runtime = Workspace:FindFirstChild("RuntimeItems")
    if not runtime then return nil end
    for _, gun in ipairs(runtime:GetChildren()) do
        if gun.Name == "MaximGun" then
            local seat = gun:FindFirstChildWhichIsA("VehicleSeat")
            if seat then return seat end
        end
    end
    return nil
end

local function SitSeat(seat)
    local jumped = false
    while true do
        if humanoid.SeatPart ~= seat then
            hrp.CFrame = seat.CFrame
            task.wait(0.1)
        else
            local weld = seat:FindFirstChild("SeatWeld")
            if weld and weld.Part1 and weld.Part1:IsDescendantOf(plr.Character) then
                if not jumped then
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    task.wait(0.15)
                    hrp.CFrame = seat.CFrame
                    jumped = true
                else
                    break
                end
            else
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                task.wait(0.2)
                jumped = false
            end
        end
        task.wait(0.05)
    end
end

local function UseSack()
    local sack = plr.Backpack:FindFirstChild("Sack")
    if sack then
        character:WaitForChild("Humanoid"):EquipTool(sack)
        return true
    end
    return false
end

local function getPos(model)
    if model:IsA("Model") then
        if model.PrimaryPart then
            return model.PrimaryPart.Position
        else
            local part = model:FindFirstChildWhichIsA("BasePart")
            if part then return part.Position end
        end
    end
    return nil
end

local function FindGold()
    local golds = {}
    local runtime = Workspace:FindFirstChild("RuntimeItems")
    if not runtime then return golds end
    for _, item in ipairs(runtime:GetChildren()) do
        if table.find(targetNames, item.Name) and not wasStored[item] then
            table.insert(golds, item)
        end
    end
    return golds
end

local function FireStore(item)
    ReplicatedStorage.Remotes.StoreItem:FireServer(item)
end

local function isFull()
    local sack = character:FindFirstChild("Sack") or plr.Backpack:FindFirstChild("Sack")
    if sack then
        local label = sack:FindFirstChild("BillboardGui") and sack.BillboardGui:FindFirstChild("TextLabel")
        if label and (label.Text == "10/10" or label.Text == "15/15") then
            return tonumber(label.Text:match("^(%d+)/"))
        end
    end
    return nil
end

local function FireDrop(count)
    for _ = 1, count do
        ReplicatedStorage.Remotes.DropItem:FireServer()
        task.wait(0.1)
    end
end

local function dropIfFull()
    local sackCount = isFull()
    if sackCount then
        TPTo(storageLocation)
        FireDrop(sackCount)
        task.wait(0.2)
    end
end

-- === HIDING LOGIC ===
local runtimeItems = Workspace:FindFirstChild("RuntimeItems")
local hiding = false

local function isInRuntimeItems(instance)
    if not runtimeItems then return false end
    return instance:IsDescendantOf(runtimeItems)
end

local function hideVisuals(instance)
    if isInRuntimeItems(instance) then return end
    if instance:IsA("BasePart") then
        instance.LocalTransparencyModifier = 1
        instance.CanCollide = false
    elseif instance:IsA("Decal") or instance:IsA("Texture") then
        instance.Transparency = 1
    elseif instance:IsA("Beam") or instance:IsA("Trail") then
        instance.Enabled = false
    end
end

coroutine.wrap(function()
    task.wait(10)
    hiding = true
    while hiding do
        for _, instance in ipairs(Workspace:GetDescendants()) do
            hideVisuals(instance)
        end
        task.wait(1)
    end
end)()
-- === END HIDING LOGIC ===

-- Sit on MaximGun, TPing to -9000 if not found
while true do
    local seat = getSeat()
    if not seat then
        TPTo(Vector3.new(57, -5, -9000))
        task.wait(0.5)
        continue
    end
    seat.Disabled = false
    SitSeat(seat)
    break
end

task.wait(1)
UseSack()

-- Tween sweep and track valuables
local foundItems = {} -- Only stores Vector3s

local function alreadyTracked(pos)
    for _, v in ipairs(foundItems) do
        if (v - pos).Magnitude < 1 then
            return true
        end
    end
    return false
end

local x, y = 57, 3
local startZ, endZ, stepZ = 30000, -49032.99, -2000
local duration = 0.5

local function scanForValuables()
    local runtime = Workspace:FindFirstChild("RuntimeItems")
    if not runtime then return end
    for _, item in ipairs(runtime:GetChildren()) do
        if item:IsA("Model") and table.find(targetNames, item.Name) and item.PrimaryPart then
            local pos = item.PrimaryPart.Position
            if typeof(pos) == "Vector3" and not alreadyTracked(pos) then
                table.insert(foundItems, pos)
            end
        end
    end
end

local function tweenMovementAndTrack()
    local currentZ = startZ
    while currentZ >= endZ do
        local startCFrame = CFrame.new(x, y, currentZ)
        local endCFrame = CFrame.new(x, y, currentZ + stepZ)

        local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
        local tween = TweenService:Create(hrp, tweenInfo, {CFrame = endCFrame})
        tween:Play()

        local tweenRunning = true
        local conn = nil
        conn = game:GetService("RunService").Heartbeat:Connect(function()
            if tweenRunning then scanForValuables() end
        end)

        tween.Completed:Wait()
        tweenRunning = false
        if conn then conn:Disconnect() end

        currentZ = currentZ + stepZ
    end
end

local success, errorMessage = pcall(tweenMovementAndTrack)
if not success then
    warn("Error in tweenMovement: " .. errorMessage)
end

-- Main collect/drop loop
while #foundItems > 0 do
    for i = #foundItems, 1, -1 do
        local pos = foundItems[i]
        -- Find the item at this position
        local runtime = Workspace:FindFirstChild("RuntimeItems")
        local itemToCollect = nil
        if runtime then
            for _, item in ipairs(runtime:GetChildren()) do
                if item:IsA("Model") and table.find(targetNames, item.Name) and item.PrimaryPart and (item.PrimaryPart.Position - pos).Magnitude < 1 and not wasStored[item] then
                    itemToCollect = item
                    break
                end
            end
        end
        if itemToCollect then
            -- TP 5 studs below the valuable item
            TPTo(Vector3.new(pos.X, pos.Y - 5, pos.Z))
            UseSack()
            FireStore(itemToCollect)
            wasStored[itemToCollect] = true
            table.remove(foundItems, i)
            dropIfFull()
            task.wait(0.4)
        else
            -- If not found at position, remove from list to avoid infinite loop
            table.remove(foundItems, i)
        end
    end
    -- Scan again in case new items spawned while collecting
    scanForValuables()
end

-- Final drop if any remaining
dropIfFull()
hiding = false -- Stop the hiding loop right after the last drop
