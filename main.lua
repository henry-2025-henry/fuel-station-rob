--// Tankstellen AutoRob (Frontal ausgerichtet, Loot + ServerHop)
--// von zer0nix | discord.gg/rFaJA9rzyB

local plrs = game:GetService("Players")
local rs = game:GetService("RunService")
local ts = game:GetService("TweenService")
local http = game:GetService("HttpService")
local vInput = game:GetService("VirtualInputManager")
local tpService = game:GetService("TeleportService")

local player = plrs.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")
local vehicles = workspace:WaitForChild("Vehicles")
local drops = workspace:WaitForChild("Drops")

local tankstellen = {
	Gas = {
		FrontCF = CFrame.new(-1527.65, 5.72, 3763.31) * CFrame.Angles(0, math.rad(-94.11), 0),
		DriveTo = Vector3.new(-1529.50, 5.82, 3800.39)
	},
	Ares = {
		FrontCF = CFrame.new(-844.64, 5.02, 1532.18) * CFrame.Angles(0, math.rad(-92.91), 0),
		DriveTo = Vector3.new(-847.91, 5.82, 1515.61)
	},
	Osso = {
		FrontCF = CFrame.new(-80.06, 5.21, -777.54) * CFrame.Angles(0, math.rad(-3.28), 0),
		DriveTo = Vector3.new(-42.06, 5.89, -770.19)
	}
}

local safeZonePos = Vector3.new(137.58, 44.69, -1856.36)
local isFlyingVehicle = false
local letzteTankstelle = nil

local function isPoliceNearby(range)
	range = range or 100
	for _, otherPlayer in pairs(plrs:GetPlayers()) do
		if otherPlayer ~= player and otherPlayer.Team and otherPlayer.Team.Name == "Police" then
			local otherChar = otherPlayer.Character
			if otherChar and otherChar:FindFirstChild("HumanoidRootPart") then
				local distance = (hrp.Position - otherChar.HumanoidRootPart.Position).Magnitude
				if distance <= range then
					return true
				end
			end
		end
	end
	return false
end

local function enterVehicle()
	local vehicle = vehicles:FindFirstChild(player.Name)
	if vehicle and char:FindFirstChild("Humanoid") then
		local seat = vehicle:FindFirstChild("DriveSeat")
		if seat then seat:Sit(char.Humanoid) end
	end
end

local function exitVehicle()
	if char:FindFirstChild("Humanoid") then
		char.Humanoid.Jump = true
	end
end

local function flyVehicleTo(position)
	if isFlyingVehicle then return end
	isFlyingVehicle = true

	local vehicle = vehicles:FindFirstChild(player.Name)
	if not vehicle or not vehicle:FindFirstChild("DriveSeat") then
		isFlyingVehicle = false
		return
	end

	local seat = vehicle.DriveSeat
	seat:Sit(char.Humanoid)

	local root = vehicle.PrimaryPart or vehicle:FindFirstChildWhichIsA("BasePart")
	local target = position
	local step, delayTime = 2, 0.01

	local function pivot(x, y, z)
		vehicle:PivotTo(CFrame.new(x, y, z))
	end

	local pos = root.Position
	for y = pos.Y, pos.Y + 3, step do
		pivot(pos.X, y, pos.Z)
		task.wait(delayTime)
	end

	local function moveXZ(startX, endX, startZ, endZ)
		local dist = ((Vector2.new(endX, endZ) - Vector2.new(startX, startZ)).Magnitude)
		local steps = math.ceil(dist / step)
		for i = 1, steps do
			local t = i / steps
			local x = startX + (endX - startX) * t
			local z = startZ + (endZ - startZ) * t
			pivot(x, pos.Y, z)
			task.wait(delayTime)
		end
	end

	moveXZ(pos.X, target.X, pos.Z, target.Z)

	for y = pos.Y + 3, target.Y + 2, -step do
		pivot(target.X, y, target.Z)
		task.wait(delayTime)
	end

	isFlyingVehicle = false
end

local function flyTo(position, duration)
	local info = TweenInfo.new(duration or 2, Enum.EasingStyle.Linear)
	local tween = ts:Create(hrp, info, {CFrame = CFrame.new(position)})
	tween:Play()
	tween.Completed:Wait()
end

local function pressF(times)
	for i = 1, times do
		vInput:SendKeyEvent(true, Enum.KeyCode.F, false, game)
		task.wait(1.2)
		vInput:SendKeyEvent(false, Enum.KeyCode.F, false, game)
	end
end

local function collectDrops()
	local function pressE()
		vInput:SendKeyEvent(true, Enum.KeyCode.E, false, game)
		wait(2.8)
		vInput:SendKeyEvent(false, Enum.KeyCode.E, false, game)
	end

	for _, drop in ipairs(drops:GetChildren()) do
		if drop:IsA("BasePart") and drop.Name:lower():find(player.Name:lower()) then
			if (drop.Position - hrp.Position).Magnitude <= 20 then
				flyTo(drop.Position + Vector3.new(0, 3, 0), 0.8)
				pressE()
				task.wait(0.4)
			end
		end
	end
end

local function robTankstelle(data)
	enterVehicle()
	task.wait(0.5)
	flyVehicleTo(data.DriveTo)
	task.wait(0.5)
	exitVehicle()
	task.wait(1.1)

	hrp.CFrame = data.FrontCF
	task.wait(0.6)
	pressF(6)
	task.wait(2.5)
	collectDrops()
end

local function serverHop()
	local servers = http:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
	for _, s in pairs(servers.data) do
		if s.playing < s.maxPlayers and s.id ~= game.JobId then
			tpService:TeleportToPlaceInstance(game.PlaceId, s.id)
			break
		end
	end
end

-- NoClip dauerhaft
rs.Stepped:Connect(function()
	local char = player.Character
	if char then
		for _, v in pairs(char:GetDescendants()) do
			if v:IsA("BasePart") then
				v.CanCollide = false
			end
		end
	end
end)

-- MAIN
task.spawn(function()
	while true do
		for name, tank in pairs(tankstellen) do
			pcall(function()
				if isPoliceNearby() then
					if name == "Osso" then
						enterVehicle()
						task.wait(0.5)
						flyVehicleTo(safeZonePos)
						task.wait(1)
					else
						return -- überspringt diese Tankstelle
					end
				else
					robTankstelle(tank)
					letzteTankstelle = tank
					task.wait(1)
				end
			end)
		end

		if letzteTankstelle then
			enterVehicle()
			task.wait(0.5)
			flyVehicleTo(safeZonePos)
			task.wait(2)
		end

		serverHop()
	end
end)
