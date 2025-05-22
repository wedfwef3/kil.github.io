_G.DelayShot = 0.6
_G.ReachShot = 250

_G.ModsAntilag = {}
workspace.DescendantAdded:Connect(function(v)
    if v:IsA("Model") and v:FindFirstChild("HumanoidRootPart") and v:FindFirstChild("Humanoid") and v:FindFirstChild("Head") and not game.Players:GetPlayerFromCharacter(v) then
        if v.Humanoid.Health > 0 then
            table.insert(_G.ModsAntilag, v)
        end
    end
end)

local TELEPORT_OFFSET = Vector3.new(0, 0, -2) -- shoot from behind head

while true do
    local DistanceGunAura, ModsTargetShotHead, ModsTargetShotHumanoid = math.huge, nil, nil
    for i, v in pairs(_G.ModsAntilag) do
        if v:IsA("Model") and v:FindFirstChild("HumanoidRootPart") and v:FindFirstChild("Humanoid") and v:FindFirstChild("Head") and not game.Players:GetPlayerFromCharacter(v) then
            local DistanceGun = (game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart").Position - v.HumanoidRootPart.Position).Magnitude
            if DistanceGun < DistanceGunAura and DistanceGun < _G.ReachShot and v.Humanoid.Health > 0 then
                ModsTargetShotHead, ModsTargetShotHumanoid, DistanceGunAura = v:FindFirstChild(_G.CharacterMods or "Head"), v.Humanoid, DistanceGun
            end
        end
    end

    if ModsTargetShotHead and ModsTargetShotHumanoid then
        _G.ModsShotgun = {}
        local ShotNow = {14, 8, 2, 5, 11, 17}
        for i, v in pairs(game.Players.LocalPlayer.Character:GetChildren()) do
            if v:FindFirstChild("ClientWeaponState") and v.ClientWeaponState:FindFirstChild("CurrentAmmo") then
                if v.ClientWeaponState.CurrentAmmo.Value ~= 0 then
                    if v.Name == "Shotgun" or v.Name == "Sawed-Off Shotgun" then
                        for _, index in pairs(ShotNow) do
                            _G.ModsShotgun[index] = ModsTargetShotHumanoid
                        end
                    else
                        _G.ModsShotgun["2"] = ModsTargetShotHumanoid
                    end
                    -- SHOOT FROM BEHIND THE HEAD:
                    local behindHead = ModsTargetShotHead.Position + TELEPORT_OFFSET
                    game.ReplicatedStorage.Remotes.Weapon.Shoot:FireServer(
                        game.Workspace:GetServerTimeNow(),
                        v,
                        CFrame.new(behindHead, ModsTargetShotHead.Position),
                        _G.ModsShotgun
                    )
                    game.ReplicatedStorage.Remotes.Weapon.Reload:FireServer(game.Workspace:GetServerTimeNow(), v)
                end
            end
        end
    end

    task.wait(_G.DelayShot)
end
