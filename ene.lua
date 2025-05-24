local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")
local humanoid = char:WaitForChild("Humanoid")

local targetNames = {
    "Bond", "GoldBar", "SilverBar", "Crucifix",
    "GoldStatue", "SilverPlate", "SilverStatue",
    "BrainJar", "SilverNugget", "GoldNugget"
}
local pathPoints = {
    Vector3.new(13.66, 120, 29620.67), Vector3.new(-15.98, 120, 28227.97), Vector3.new(-63.54, 120, 26911.59),
    Vector3.new(-75.71, 120, 25558.11), Vector3.new(-49.51, 120, 24038.67), Vector3.new(-34.48, 120, 22780.89),
    Vector3.new(-63.71, 120, 21477.32), Vector3.new(-84.23, 120, 19970.94), Vector3.new(-84.76, 120, 18676.13),
    Vector3.new(-87.32, 120, 17246.92), Vector3.new(-95.48, 120, 15988.29), Vector3.new(-93.76, 120, 14597.43),
    Vector3.new(-86.29, 120, 13223.68), Vector3.new(-97.56, 120, 11824.61), Vector3.new(-92.71, 120, 10398.51),
    Vector3.new(-98.43, 120, 9092.45), Vector3.new(-90.89, 120, 7741.15), Vector3.new(-86.46, 120, 6482.59),
    Vector3.new(-77.49, 120, 5081.21), Vector3.new(-73.84, 120, 3660.66), Vector3.new(-73.84, 120, 2297.51),
    Vector3.new(-76.56, 120, 933.68), Vector3.new(-81.48, 120, -429.93), Vector3.new(-83.47, 120, -1683.45),
    Vector3.new(-94.18, 120, -3035.25), Vector3.new(-109.96, 120, -4317.15), Vector3.new(-119.63, 120, -5667.43),
    Vector3.new(-118.63, 120, -6942.88), Vector3.new(-118.09, 120, -8288.66), Vector3.new(-132.12, 120, -9690.39),
    Vector3.new(-122.83, 120, -11051.38), Vector3.new(-117.53, 120, -12412.74), Vector3.new(-119.81, 120, -13762.14),
    Vector3.new(-126.27, 120, -15106.33), Vector3.new(-134.45, 120, -16563.82), Vector3.new(-129.85, 120, -17884.73),
    Vector3.new(-127.23, 120, -19234.89), Vector3.new(-133.49, 120, -20584.07), Vector3.new(-137.89, 120, -21933.47),
    Vector3.new(-139.93, 120, -23272.51), Vector3.new(-144.12, 120, -24612.54), Vector3.new(-142.93, 120, -25962.13),
    Vector3.new(-149.21, 120, -27301.58), Vector3.new(-156.19, 120, -28640.93), Vector3.new(-164.87, 120, -29990.78),
    Vector3.new(-177.65, 120, -31340.21), Vector3.new(-184.67, 120, -32689.24), Vector3.new(-208.92, 120, -34027.44),
    Vector3.new(-227.96, 120, -35376.88), Vector3.new(-239.45, 120, -36726.59), Vector3.new(-250.48, 120, -38075.91),
    Vector3.new(-260.28, 120, -39425.56), Vector3.new(-274.86, 120, -40764.67), Vector3.new(-297.45, 120, -42103.61),
    Vector3.new(-321.64, 120, -43442.59), Vector3.new(-356.78, 120, -44771.52), Vector3.new(-387.68, 120, -46100.94),
    Vector3.new(-415.83, 120, -47429.85), Vector3.new(-452.39, 120, -49407.44)
}

local speed = 1000
local tpInterval = 0.8
local dropRepeat = 10
local dropInterval = 0.1
local returnPos = Vector3.new(59.67, 11.97, 29890.71)

local foundItems = {}

local function TPTo(position)
    pcall(function()
        hrp.CFrame = CFrame.new(position)
    end)
end

local function DestroyCase()
    local castle = workspace:FindFirstChild("VampireCastle")
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
    local runtime = workspace:FindFirstChild("RuntimeItems")
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
            if weld and weld.Part1 and weld.Part1:IsDescendantOf(player.Character) then
                if not jumped then
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    task.wait(0.15)
                    hrp.CFrame = seat.CFrame
                    jumped = true
                else
                    break
                end
            else
                -- If not welded, jump out and try again
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                task.wait(0.2)
                jumped = false
            end
        end
        task.wait(0.05)
    end
end

local function scanForItems()
    local runtime = Workspace:FindFirstChild("RuntimeItems")
    if not runtime then return end
    for _, m in ipairs(runtime:GetChildren()) do
        if m:IsA("Model") and table.find(targetNames, m.Name) and m.PrimaryPart then
            local p = m.PrimaryPart.Position
            local exists = false
            for _, v in ipairs(foundItems) do
                if (v - p).Magnitude < 1 then
                    exists = true
                    break
                end
            end
            if not exists then
                table.insert(foundItems, p)
            end
        end
    end
end

local function isFull()
    local sack = char:FindFirstChild("Sack") or player.Backpack:FindFirstChild("Sack")
    if sack then
        local label = sack:FindFirstChild("BillboardGui") and sack.BillboardGui:FindFirstChild("TextLabel")
        if label and (label.Text == "10/10" or label.Text == "15/15") then
            return tonumber(label.Text:match("^(%d+)/"))
        end
    end
    return nil
end

local storeRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("StoreItem")
local dropRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("DropItem")

local function FireStore(model)
    storeRemote:FireServer(model)
end

local function FireDrop(count)
    for _ = 1, count do
        dropRemote:FireServer()
        task.wait(dropInterval)
    end
end

local function collectAllFoundItems()
    for _, pos in ipairs(foundItems) do
        hrp.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0))
        local runtime = Workspace:FindFirstChild("RuntimeItems")
        if runtime then
            for _, m in ipairs(runtime:GetChildren()) do
                if m:IsA("Model") and table.find(targetNames, m.Name) and m.PrimaryPart and (m.PrimaryPart.Position - pos).Magnitude < 1 then
                    FireStore(m)
                    task.wait(0.4)
                    if isFull() then
                        hrp.CFrame = CFrame.new(returnPos)
                        task.wait(0.5)
                        FireDrop(tonumber(isFull()))
                        task.wait(0.5)
                        hrp.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0))
                    end
                end
            end
        end
        task.wait(tpInterval)
    end
end

-- MAIN
spawn(function()
    -- 1. Sit on MaximGun
    local seat = nil
    repeat
        seat = getSeat()
        task.wait(1)
    until seat

    SitSeat(seat)
    wait(5)

    -- 2. Tween across map scanning for valuables
    local scanConn = RunService.Heartbeat:Connect(scanForItems)
    for _, pt in ipairs(pathPoints) do
        local dist = (hrp.Position - pt).Magnitude
        local tween = TweenService:Create(hrp, TweenInfo.new(dist/speed, Enum.EasingStyle.Linear), {CFrame = CFrame.new(pt)})
        tween:Play()
        tween.Completed:Wait()
    end
    scanConn:Disconnect()
    wait(1)

    -- 3. TP and collect all found valuables, handling sack full logic
    collectAllFoundItems()

    print("All valuables have been collected.")
end)
