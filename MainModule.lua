local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local rad = math.rad
local sin = math.sin
local random = math.random
local huge = math.huge
local Remotes = game.ReplicatedStorage:WaitForChild("Remotes")

local CameraShaker = require(ReplicatedStorage.ClientModules.CameraShaker)
local camShake = CameraShaker.new(Enum.RenderPriority.Camera.Value, function(shakeCf)
    workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame * shakeCf
end)
camShake:Start()

local module = {}

local player = Players.LocalPlayer

function module.Create(instance,name,parent)
	local instance = Instance.new(instance)
	instance.Name = name
	instance.Parent = parent
	
	return instance
end

function module.checkIfHit()
	local character = player.Character or player.CharacterAdded:Wait()
	if character:FindFirstChild("Hit") or character:FindFirstChild("Debounce") then
		return true
	else
		return false
	end
end
function module.positionDistanceLimit(position, d)
	local character = player.Character
	local rootPart = character.HumanoidRootPart
	if (position - rootPart.Position).magnitude > d then
		return (CFrame.new(rootPart.Position, position) * CFrame.new(0,0,-d)).p
	else
		return position
	end
end
function module.GetParticles(m)
	local particleTable = {}
	for i,v in pairs(m:GetDescendants()) do
		if v:IsA("ParticleEmitter") then
			particleTable[v] = {
				Particle = v,
				Transparency = {},
				Size = {}
			}
			for i2 = 1, #particleTable[v]["Particle"].Transparency.Keypoints do
				particleTable[v]["Transparency"][i2] = {
					["Value"] = particleTable[v]["Particle"].Transparency.Keypoints[i2].Value,
					["Time"] = particleTable[v]["Particle"].Transparency.Keypoints[i2].Time
				}
			end
			for i2 = 1, #particleTable[v]["Particle"].Size.Keypoints do
				particleTable[v]["Size"][i2] = {
					["Value"] = particleTable[v]["Particle"].Size.Keypoints[i2].Value,
					["Time"] = particleTable[v]["Particle"].Size.Keypoints[i2].Time
				}
			end
			v.Size = NumberSequence.new(0)
			v.Transparency = NumberSequence.new(1)
		end
	end
	return particleTable
end
function module.GetParts(m)
	local partTable = {}
	for i,v in pairs(m:GetDescendants()) do
		if v:IsA("BasePart") then
			partTable[v] = {
				Part = v,
				Transparency = v.Transparency,
				Size = v.Size
			}
			v.Size = Vector3.new(0,0,0)
			v.Transparency = 1
		end
	end
	return partTable
end
function module.getMousePos(mouse)
	local character = player.Character
	local rootPart = character.HumanoidRootPart
	
	local lockOn = character.Main.LockOnScript.LockOn
	if lockOn.Value then
		return lockOn.Value.HumanoidRootPart.CFrame.p
	else
		return mouse.Hit.p
	end
end
function module.getGroundFromPosition(position)
	local ignoreList = {}		
	for i,v in pairs(workspace:GetChildren()) do
		if v:FindFirstChild("Humanoid") then
			table.insert(ignoreList,v)
		end
	end
	
	local ray = Ray.new(position + Vector3.new(0,1,0),(Vector3.new(0,-10000000,0)))
	local hit,position = workspace:FindPartOnRayWithIgnoreList(ray,ignoreList)
	return position
end
function module.checkRay(position, direction, unit)
	local ignoreList = {}		
	for i,v in pairs(workspace:GetChildren()) do
		if v:FindFirstChild("Humanoid") then
			table.insert(ignoreList,v)
		end
	end
	
	local ray = Ray.new(position - direction.unit,(direction).unit * (unit + 1))
	local hit,position = workspace:FindPartOnRayWithIgnoreList(ray,ignoreList)
	return hit
end
function module.changeSizeAndTransparency(particleTable, particle, loop, reverse)
	spawn(function()
		local a = 1
		local b = 1
		local typ = "Size"
		local count = loop
		if reverse then
			a = loop
			loop = 1
			b = -1
		end
		for i = a, loop, b do
			for eee = 1, 2 do
				if typ == "Size" then
					typ = "Transparency"
				else
					typ = "Size"
				end
				local keyPoints = {}
				for i2 = 1, #particleTable[particle][typ] do
					if typ == "Transparency" then
						local T = particleTable[particle][typ][i2]["Time"]
						local V = particleTable[particle][typ][i2]["Value"]
						table.insert(keyPoints, NumberSequenceKeypoint.new(T, 1-((1-V)/count)*i))
					else
						table.insert(keyPoints, NumberSequenceKeypoint.new(particleTable[particle][typ][i2]["Time"], (particleTable[particle][typ][i2]["Value"] * (i/count))))
					end
				end
				particle[typ] = NumberSequence.new(keyPoints)
			end
		wait() end
	end)
end
function module.getSpot(hit,orgiginalCFrame,Distance)
	local relCF = orgiginalCFrame
	local cf = orgiginalCFrame
	for i = 1,360 do
		orgiginalCFrame = cf * CFrame.Angles(0,math.rad(i),0)
		local ray = Ray.new(orgiginalCFrame.p-orgiginalCFrame.rightVector, (orgiginalCFrame.lookVector).unit * Distance)
		local part, position = workspace:FindPartOnRay(ray, hit, false, true)
		local ray2 = Ray.new(orgiginalCFrame.p+orgiginalCFrame.rightVector, (orgiginalCFrame.lookVector).unit * Distance)
		local part2, position2 = workspace:FindPartOnRay(ray2, hit, false, true)
		
		if not part and not part2 then 
			return orgiginalCFrame
		end
	end
	return relCF
end
function module.getLockedOnPlayer(character)
	if character:FindFirstChild("LockOnScript") and character:FindFirstChild("LockOnScript").LockOn.Value then
		return character:FindFirstChild("LockOnScript").LockOn.Value
	else
		return false
	end
end

function module.qwait()
	game:GetService("RunService").RenderStepped:wait()
end

function module.Lerp(a, b, t)
	return a + (b - a) * t
end
function module.Damage(character, tab)
		local victim
		local rootPart = character.HumanoidRootPart
		for i,v in pairs(workspace:GetChildren()) do
			if v:FindFirstChild("HumanoidRootPart") and v ~= character then
				local victim1 = v
				local p1 = rootPart.Position + rootPart.CFrame.lookVector * 5
				local p2 = victim1.HumanoidRootPart.Position
				
				if (p1 - p2).magnitude <= 6 then
					spawn(function()
						game.Lighting.Blur.Size = 16
						for i = 1,5 do
							game.Lighting.Blur.Size = game.Lighting.Blur.Size - 2
						wait() end
					end)
					
					if game.ReplicatedStorage.Remotes.Damage:InvokeServer(_G.Pass, v, tab) then
						victim = v
					end
				end
			end
		end
		return victim
	end
function module.CombatAnimation(combatAnim, character, bp, slashDir)
	local humanoid = character.Humanoid
	local rootPart = character.HumanoidRootPart
	function moveForward(bp)
		local ray = Ray.new(rootPart.Position,(rootPart.CFrame.lookVector).unit * 6)
		local hit,position = workspace:FindPartOnRay(ray,character)
		
		if hit then
			bp.Position = position - rootPart.CFrame.lookVector * 1.5
		end
	end
	
	combatAnim.KeyframeReached:Connect(function(keyframe)
		if keyframe == "Slash" then
			if slashDir[combatAnim.Name] then
				game.ReplicatedStorage.Remotes.SwordHandler:FireServer({_G.Pass,"SlashEffect", rootPart.CFrame + rootPart.CFrame.lookVector * 2, slashDir[combatAnim.Name]["Angle"], slashDir[combatAnim.Name]["Direction"], slashDir[combatAnim.Name]["Speed"], slashDir[combatAnim.Name]["Times"], slashDir[combatAnim.Name]["Size"], slashDir[combatAnim.Name]["Color"]})
			end
		end
		if keyframe == "1" then
			character.Head:FindFirstChild("Swing2"):Play()
			moveForward(bp)
			local victim = module.Damage(character, {
				["HitEffect"] = "LightHitEffect",
				["Sound"] = ReplicatedStorage.Sounds.Punch,
				["Position"] = rootPart.CFrame.Position + rootPart.CFrame.lookVector * 5,
				["Type"] = "Normal",
				["HitTime"] = 1,
				["HurtAnimation"] = ReplicatedStorage.Animations.HurtAnimations["Hurt"..math.random(1,3)],
				["VictimCFrame"] = rootPart.CFrame * CFrame.Angles(0, math.rad(180), 0) + rootPart.CFrame.lookVector * 6,
				["Damage"] = 1
			})
			if victim then
				camShake:Shake(CameraShaker.Presets["Bump"])
			end
		elseif keyframe == "2" then
			character.Head:FindFirstChild("Swing2"):Play()
			moveForward(bp)
			local victim = module.Damage(character, {
				["HitEffect"] = "LightHitEffect2",
				["Sound"] = ReplicatedStorage.Sounds.Kick,
				["Position"] = rootPart.CFrame.Position + rootPart.CFrame.lookVector * 5,
				["Type"] = "Normal",
				["HitTime"] = 1,
				["HurtAnimation"] = ReplicatedStorage.Animations.HurtAnimations["Hurt"..math.random(1,3)],
				["VictimCFrame"] = rootPart.CFrame * CFrame.Angles(0, math.rad(180), 0) + rootPart.CFrame.lookVector * 6,
				["Damage"] = 1
			})
			if victim then
				camShake:Shake(CameraShaker.Presets["Bump"])
			end
		elseif keyframe == "3" then
			character.Head:FindFirstChild("Swing2"):Play()
			moveForward(bp)
			local victim = module.Damage(character, {
				["HitEffect"] = "HeavyHitEffect",
				["Sound"] = ReplicatedStorage.Sounds.Kick,
				["Position"] = rootPart.CFrame.Position + rootPart.CFrame.lookVector * 5,
				["Type"] = "Normal",
				["HitTime"] = 1.5,
				["HurtAnimation"] = ReplicatedStorage.Animations.HurtAnimations["Hurt"..math.random(1,3)],
				["VictimCFrame"] = rootPart.CFrame * CFrame.Angles(0, math.rad(180), 0) + rootPart.CFrame.lookVector * 6,
				["Damage"] = 2
			})
			if victim then
				camShake:Shake(CameraShaker.Presets["Explosion"])
			end
		elseif keyframe == "4" then
			character.Head:FindFirstChild("Swing2"):Play()
			moveForward(bp)
			local victim = module.Damage(character, {
				["HitEffect"] = "HeavyHitEffect",
				["Sound"] = ReplicatedStorage.Sounds.Knockback,
				["Velocity"] = rootPart.CFrame.lookVector * 60,
				["Type"] = "Knockback",
				["HitTime"] = 0.5,
				["HurtAnimation"] = ReplicatedStorage.Animations.HurtAnimations.Knockback2,
				["VictimCFrame"] = rootPart.CFrame * CFrame.Angles(0, math.rad(180), 0) + rootPart.CFrame.lookVector * 6,
				["Damage"] = 3
			})
			if victim then
				camShake:Shake(CameraShaker.Presets["BigExplosion"])
			end
		elseif keyframe == "5" then
			character.Head:FindFirstChild("Swing2"):Play()
			moveForward(bp)
			local victim = module.Damage(character, {
				["HitEffect"] = "HeavyHitEffect",
				["Sound"] = ReplicatedStorage.Sounds.Knockback,
				["Velocity"] = rootPart.CFrame.lookVector * 60 + Vector3.new(0,50,0),
				["Type"] = "Knockback",
				["HitTime"] = 0.5,
				["HurtAnimation"] = ReplicatedStorage.Animations.HurtAnimations.Knockback2,
				["VictimCFrame"] = rootPart.CFrame * CFrame.Angles(0, math.rad(180), 0) + rootPart.CFrame.lookVector * 6,
				["Damage"] = 3
			})
			if victim then
				camShake:Shake(CameraShaker.Presets["BigExplosion"])
			end
		elseif keyframe == "6" then
			character.Head:FindFirstChild("Swing2"):Play()
			moveForward(bp)
			local victim = module.Damage(character, {
				["HitEffect"] = "HeavyHitEffect",
				["Sound"] = ReplicatedStorage.Sounds.Knockback,
				["Velocity"] = rootPart.CFrame.lookVector * 60 - Vector3.new(0,50,0),
				["Type"] = "Knockback",
				["HitTime"] = 0.5,
				["HurtAnimation"] = ReplicatedStorage.Animations.HurtAnimations.Knockback2,
				["VictimCFrame"] = rootPart.CFrame * CFrame.Angles(0, math.rad(180), 0) + rootPart.CFrame.lookVector * 6,
				["Damage"] = 3
			})
			if victim then
				camShake:Shake(CameraShaker.Presets["BigExplosion"])
			end
		elseif keyframe == "7" then
			character.Head:FindFirstChild("Swing2"):Play()
			moveForward(bp)
			spawn(function()
				game.ReplicatedStorage.Remotes.Functions:InvokeServer({_G.Pass,"PlaySound",game.ReplicatedStorage.Sounds.Knife_Slash,character.Head})
			end)
			local victim = module.Damage(character, {
				["HitEffect"] = "KnifeHitEffect",
				["Sound"] = ReplicatedStorage.Sounds.KnifeHit,
				["Position"] = rootPart.CFrame.Position + rootPart.CFrame.lookVector * 5,
				["Type"] = "Normal",
				["HitTime"] = 0.5,
				["HurtAnimation"] = ReplicatedStorage.Animations.HurtAnimations["Hurt"..math.random(1,3)],
				["VictimCFrame"] = rootPart.CFrame * CFrame.Angles(0, math.rad(180), 0) + rootPart.CFrame.lookVector * 6,
				["Damage"] = 5,
				["CameraShake"] = "Bump"
			})
			
			if victim then
				camShake:Shake(CameraShaker.Presets["Bump"])
			end
		elseif keyframe == "8" then
			character.Head:FindFirstChild("Swing2"):Play()
			moveForward(bp)
			spawn(function()
				game.ReplicatedStorage.Remotes.Functions:InvokeServer({_G.Pass,"PlaySound",game.ReplicatedStorage.Sounds.Knife_Slash,character.Head})
			end)
			local victim = module.Damage(character, {
				["HitEffect"] = "KnifeHitEffect",
				["Sound"] = ReplicatedStorage.Sounds.KnifeHit,
				["Velocity"] = rootPart.CFrame.lookVector * 70,
				["Type"] = "Knockback",
				["HitTime"] = 0.5,
				["HurtAnimation"] = ReplicatedStorage.Animations.HurtAnimations["Hurt"..math.random(1,3)],
				["VictimCFrame"] = rootPart.CFrame * CFrame.Angles(0, math.rad(180), 0) + rootPart.CFrame.lookVector * 10,
				["Damage"] = 8,
				["CameraShake"] = "BigExplosion"
			})
			if victim then
				camShake:Shake(CameraShaker.Presets["BigExplosion"])
			end
		elseif keyframe == "9" then
			character.Head:FindFirstChild("Swing2"):Play()
			moveForward(bp)
			spawn(function()
				game.ReplicatedStorage.Remotes.Functions:InvokeServer({_G.Pass,"PlaySound",game.ReplicatedStorage.Sounds.Knife_Slash,character.Head})
			end)
			local victim = module.Damage(character, {
				["HitEffect"] = "KnifeHitEffect",
				["Sound"] = ReplicatedStorage.Sounds.KnifeHit,
				["Velocity"] = rootPart.CFrame.lookVector * 40 + Vector3.new(0,20,0),
				["Type"] = "Knockback",
				["HitTime"] = 0.5,
				["HurtAnimation"] = ReplicatedStorage.Animations.HurtAnimations.Knockback2,
				["VictimCFrame"] = rootPart.CFrame * CFrame.Angles(0, math.rad(180), 0) + rootPart.CFrame.lookVector * 10,
				["Damage"] = 8,
				["CameraShake"] = "BigExplosion"
			})
			if victim then
				camShake:Shake(CameraShaker.Presets["BigExplosion"])
			end
		elseif keyframe == "10" then
			character.Head:FindFirstChild("Swing2"):Play()
			combatAnim:AdjustSpeed(0)
			moveForward(bp)
			local victim = module.Damage(character, {
				["HitEffect"] = "HeavyHitEffect",
				["Sound"] = ReplicatedStorage.Sounds.Kick,
				["Position"] = rootPart.CFrame.Position + rootPart.CFrame.lookVector * 5 + Vector3.new(0,25,0),
				["Type"] = "Normal",
				["HitTime"] = 1.5,
				["HurtAnimation"] = ReplicatedStorage.Animations.HurtAnimations["Hurt"..math.random(1,3)],
				["VictimCFrame"] = rootPart.CFrame * CFrame.Angles(0, math.rad(180), 0) + rootPart.CFrame.lookVector * 6,
				["Damage"] = 3
			})
			if victim then
				bp.Position = bp.Position + Vector3.new(0,25,0)
				camShake:Shake(CameraShaker.Presets["Explosion"])
			end
			combatAnim:AdjustSpeed(1)
		elseif keyframe == "11" then
			character.Head:FindFirstChild("Swing2"):Play()
			moveForward(bp)
			local victim = module.Damage(character, {
				["HitEffect"] = "BoneHitEffect",
				["Sound"] = ReplicatedStorage.Sounds.Kick,
				["Position"] = rootPart.CFrame.Position + rootPart.CFrame.lookVector * 5,
				["Type"] = "Normal",
				["HitTime"] = 1,
				["HurtAnimation"] = ReplicatedStorage.Animations.HurtAnimations["Hurt"..math.random(1,3)],
				["VictimCFrame"] = rootPart.CFrame * CFrame.Angles(0, math.rad(180), 0) + rootPart.CFrame.lookVector * 6,
				["Damage"] = 1,
				["Karma"] = 1
			})
			if victim then
				camShake:Shake(CameraShaker.Presets["Bump"])
			end
		elseif keyframe == "12" then
			character.Head:FindFirstChild("Swing2"):Play()
			moveForward(bp)
			local victim = module.Damage(character, {
				["HitEffect"] = "BoneHitEffect",
				["Sound"] = ReplicatedStorage.Sounds.Knockback,
				["Velocity"] = rootPart.CFrame.lookVector * 60,
				["Type"] = "Knockback",
				["HitTime"] = 0.5,
				["HurtAnimation"] = ReplicatedStorage.Animations.HurtAnimations["Hurt"..math.random(1,3)],
				["VictimCFrame"] = rootPart.CFrame * CFrame.Angles(0, math.rad(180), 0) + rootPart.CFrame.lookVector * 6,
				["Damage"] = 1,
				["Karma"] = 4
			})
			if victim then
				camShake:Shake(CameraShaker.Presets["BigExplosion"])
			end
		elseif keyframe == "13" then
			character.Head:FindFirstChild("Spear"):Play()
			moveForward(bp)
			local victim = module.Damage(character, {
				["HitEffect"] = "BoneHitEffect",
				["Sound"] = ReplicatedStorage.Sounds.Kick,
				["Position"] = rootPart.CFrame.Position + rootPart.CFrame.lookVector * 5,
				["Type"] = "Normal",
				["HitTime"] = 1,
				["HurtAnimation"] = ReplicatedStorage.Animations.HurtAnimations["Hurt"..math.random(1,3)],
				["VictimCFrame"] = rootPart.CFrame * CFrame.Angles(0, math.rad(180), 0) + rootPart.CFrame.lookVector * 6,
				["Damage"] = 3,
			})
			if victim then
				camShake:Shake(CameraShaker.Presets["Bump"])
			end
		elseif keyframe == "14" then
			character.Head:FindFirstChild("ChaosSaberSlice"):Play()
			moveForward(bp)
			local victim = module.Damage(character, {
				["HitEffect"] = "BladeHitEffect",
				["Sound"] = ReplicatedStorage.Sounds.KnifeHit,
				["Position"] = rootPart.CFrame.Position + rootPart.CFrame.lookVector * 5,
				["Type"] = "Normal",
				["HitTime"] = 1,
				["HurtAnimation"] = ReplicatedStorage.Animations.HurtAnimations["Hurt"..math.random(1,3)],
				["VictimCFrame"] = rootPart.CFrame * CFrame.Angles(0, math.rad(180), 0) + rootPart.CFrame.lookVector * 6,
				["Damage"] = 5,
			})
			if victim then
				camShake:Shake(CameraShaker.Presets["Bump"])
			end
		elseif keyframe == "15" then
			character.Head:FindFirstChild("ChaosSaberSlice"):Play()
			moveForward(bp)
			local victim = module.Damage(character, {
				["HitEffect"] = "BladeHitEffect",
				["Sound"] = ReplicatedStorage.Sounds.KnifeHit,
				["Velocity"] = rootPart.CFrame.lookVector * 60,
				["Type"] = "Knockback",
				["HitTime"] = 0.5,
				["HurtAnimation"] = ReplicatedStorage.Animations.HurtAnimations.Knockback2,
				["VictimCFrame"] = rootPart.CFrame * CFrame.Angles(0, math.rad(180), 0) + rootPart.CFrame.lookVector * 6,
				["Damage"] = 6
			})
			if victim then
				camShake:Shake(CameraShaker.Presets["BigExplosion"])
			end
		end
	end)
end
function module.BurstScreen(player,Gui,Color,howlong,w)
	spawn(function()
		local gui = player.Character.Resources.Guis.BurstScreen:Clone()
		gui[Gui].BackgroundTransparency = 0
		if Color then
			gui[Gui].BackgroundColor3 = Color
		end
		gui.Parent = player.PlayerGui
		if w then
			wait(w)
		end
		if not howlong then howlong = 10 end
		for i = 1,howlong do
			gui[Gui].BackgroundTransparency = gui[Gui].BackgroundTransparency + 1/howlong
		wait()end
		gui:Destroy()
	end)
end

function module.AddKeyframes(animation, parent)
	local character = parent.Parent
	local rootPart, humanoid = character:WaitForChild("HumanoidRootPart"), character:WaitForChild("Humanoid")
	animation.KeyframeReached:Connect(function(keyframe)
		if keyframe == "Pause" then
			animation:AdjustSpeed(0)
		elseif keyframe == "Step" then
			if humanoid.FloorMaterial == Enum.Material.Grass then
				character.Head["walking_step_grass"]:Play()
			elseif humanoid.FloorMaterial == Enum.Material.Sand then
				character.Head["walking_step_sand"]:Play()
			elseif humanoid.FloorMaterial == Enum.Material.Wood or humanoid.FloorMaterial == Enum.Material.WoodPlanks then
				character.Head["walking_step_wood"]:Play()
			elseif humanoid.FloorMaterial == Enum.Material.Concrete or humanoid.FloorMaterial == Enum.Material.SmoothPlastic or humanoid.FloorMaterial == Enum.Material.Plastic then
				character.Head["walking_step_stone"]:Play()
			end
		elseif keyframe == "RepeatEnd" then
			local timePosition = animation:GetTimeOfKeyframe("RepeatStart")
			animation.TimePosition = timePosition
		end
	end)
end

function module.BlurEffect(blur,t)
	spawn(function()
		local blurObject = game.Lighting:FindFirstChild("Blur") or Instance.new("BlurEffect", game.Lighting)
		blurObject.Size = blur
		for i = 1,t do
			blurObject.Size = blurObject.Size - blur/t
		wait() end
	end)
end

function module.CreateTween(part, info, goal, play) --[Info]: length, style, direction, repeatTimes, willRepeat, waitTime
    local Goal = goal
    local TwInfo = TweenInfo.new(unpack(info))
    local Tween = game:GetService("TweenService"):Create(part, TwInfo, Goal)
    if play then Tween:Play() end
    return Tween
end

function module.GetPlayerParts(character)
	local tab = {}
	for i, v in pairs(character:GetDescendants()) do
		if v:IsA("BasePart") then
			table.insert(tab,v)
		end
	end
	return tab
end

function module.DisableEffects(part,effect)
	for i,v in pairs(part:GetChildren()) do
		if v.Name == effect then
			v.Enabled = false
		end
	end
end

function module.CheckTable(tab,object)
	for i,v in pairs(tab) do
		if v == object then
			return true
		end
	end
	return false
end

function module.getNearByHumanoids(size)
	local character = player.Character or player.CharacterAdded:Wait()
	local rootPart = character.HumanoidRootPart
	local victim
	
	for i,v in pairs(workspace:GetChildren()) do
		local victimHRP = v:FindFirstChild("HumanoidRootPart") or v:FindFirstChild("Torso")
		if victimHRP and v ~= character then
			local foundPlayer = v
			
			local p1 = rootPart.Position + rootPart.CFrame.lookVector * size
			local p2 = victimHRP.Position
			
			if (p1 - p2).magnitude <= size then
				victim = v
			end
		end
	end
	return victim
end

function module.combatDamage(...)
	local character = player.Character or player.CharacterAdded:Wait()
	local rootPart = character.HumanoidRootPart
	local victim
	
	for i,v in pairs(workspace:GetChildren()) do
		if v:FindFirstChild("HumanoidRootPart") and v ~= character then
			local foundPlayer = v
			
			local p1 = rootPart.Position + rootPart.CFrame.lookVector * 5
			local p2 = foundPlayer.HumanoidRootPart.Position
			
			if (p1 - p2).magnitude <= 6 then
				victim = foundPlayer
				
				if not Remotes.Damage:InvokeServer(victim, ...) then
					return nil
				end
			end
		end
	end
	return victim
end

function module.CreateBodyMover(...)
	local mover, parent, force, value, debris = unpack(...)
	for i, v in pairs(parent:GetChildren()) do
		if v:IsA(mover) then
			v:Destroy()
		end
	end
	local bm = Instance.new(mover)
	bm.Name = "Client"
	if mover == "BodyPosition" then
		bm.MaxForce = force
		bm.Position = value
		bm.Parent = parent
	elseif mover == "BodyGyro" then
		bm.MaxTorque = force
		bm.CFrame = value
		bm.Parent = parent
	elseif mover == "BodyVelocity" then
		bm.MaxForce = force
		bm.Velocity = value
		bm.Parent = parent
	end
	if debris then
		game.Debris:AddItem(bm, debris)
	end
	return bm
end


return module
