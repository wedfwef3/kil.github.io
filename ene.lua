local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

local targetNames = {
    "Bond", "GoldBar", "SilverBar", "Crucifix",
    "GoldStatue", "SilverPlate", "SilverStatue",
    "BrainJar", "SilverNugget", "GoldNugget"
}

local function TPTo(position)
    pcall(function()
        hrp.CFrame = CFrame.new(position)
    end)
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
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                task.wait(0.2)
                jumped = false
            end
        end
        task.wait(0.05)
    end
end

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

-- Wait 1 second after sitting
task.wait(1)

local foundItems = {}

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
            if not alreadyTracked(pos) then
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

        -- Scan for valuables while tween is running
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

-- After tweening: TP to each found valuable item (NO collecting logic)
for _, pos in ipairs(foundItems) do
    TPTo(pos + Vector3.new(0, 5, 0)) -- +5 Y for safe landing
    task.wait(0.33)
end
