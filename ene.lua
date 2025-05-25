local Players = game:GetService("Players")
local player = Players.LocalPlayer
local runtimeItems = workspace:FindFirstChild("RuntimeItems")
local radius = 2000
local updateInterval = 1

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

while true do
    for _, instance in ipairs(workspace:GetDescendants()) do
        hideVisuals(instance)
    end
    task.wait(updateInterval)
end
