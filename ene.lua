local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local WS = game:GetService("Workspace")
local LP = Players.LocalPlayer
local Char = LP.Character or LP.CharacterAdded:Wait()
local HRP = Char:WaitForChild("HumanoidRootPart")

local function getGun()
	for _, t in ipairs(Char:GetChildren()) do
		if t:IsA("Tool") and t:FindFirstChild("ClientWeaponState") then
			return t
		end
	end
	return nil
end

local function getAmmo(tool)
	local guiAmmo = LP:FindFirstChild("PlayerGui") and LP.PlayerGui:FindFirstChild("GunGui") and LP.PlayerGui.GunGui:FindFirstChild("Ammo")
	local state = tool:FindFirstChild("ClientWeaponState")
	if not state or not guiAmmo then return false, false end

	local curAmmo = state:FindFirstChild("CurrentAmmo")
	local text = guiAmmo.Text
	local slash = string.find(text, "/")
	local right = slash and tonumber(string.sub(text, slash + 1)) or nil

	return (curAmmo and tonumber(curAmmo.Value) or 0) > 0, right == 0
end

local function getNPC()
	local nearest, minDist = nil, 60
	for _, model in ipairs(WS:GetDescendants()) do
		if model:IsA("Model") and model:FindFirstChild("Humanoid") and not Players:GetPlayerFromCharacter(model) then
			local head = model:FindFirstChild("Head")
			if head then
				local dist = (HRP.Position - head.Position).Magnitude
				if dist < minDist then
					minDist = dist
					nearest = model
				end
			end
		end
	end
	return nearest
end

local function Reload(tool)
	local args = {
		[1] = WS:GetServerTimeNow(),
		[2] = tool
	}
	RS.Remotes.Weapon.Reload:FireServer(unpack(args))
end

local function Shoot(tool, npc)
	local head = npc:FindFirstChild("Head")
	if not head or not head:IsA("BasePart") then return end

	local origin = tool:FindFirstChild("Handle") and tool.Handle.Position or HRP.Position
	local look = CFrame.lookAt(origin, head.Position)

	local args = {
		[1] = WS:GetServerTimeNow(),
		[2] = tool,
		[3] = look,
		[4] = {
			["2"] = npc:FindFirstChild("Humanoid")
		}
	}
	RS.Remotes.Weapon.Shoot:FireServer(unpack(args))
end

task.spawn(function()
	while true do
		local tool
		repeat
			tool = getGun()
			task.wait(1)
		until tool

		while tool and tool.Parent == Char and tool:FindFirstChild("ClientWeaponState") do
			local ammoOK, guiZero = getAmmo(tool)

			if ammoOK then
				local npc = getNPC()
				if npc then
					while npc and npc:FindFirstChild("Humanoid") and npc.Humanoid.Health > 0 and (HRP.Position - npc.Head.Position).Magnitude <= 60 do
						local ammoNow, _ = getAmmo(tool)
						if not ammoNow then break end
						Shoot(tool, npc)
						task.wait(0.2)
					end
				end
			elseif guiZero then
				repeat task.wait(0.5)
					_, guiZero = getAmmo(tool)
				until not guiZero
			else
				Reload(tool)
				task.wait(1)
			end

			task.wait(0.2)
		end
	end
end)
