--[[
    private hub | by HxL
    Full Fusion: FatalityZ + Ragalic + Posral + Mercury + Apple + Rezonans
    All features included, all kicks working.
]]

-- Load Obsidian
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Camera = Workspace.CurrentCamera
local LP = Players.LocalPlayer
local Mouse = LP:GetMouse()

-- Remote retrieval
local function getRemote(parent, name)
    return parent:FindFirstChild(name) or parent:WaitForChild(name, 10)
end

local GrabEvents = getRemote(ReplicatedStorage, "GrabEvents")
local SNO = getRemote(GrabEvents, "SetNetworkOwner")
local CreateLine = getRemote(GrabEvents, "CreateGrabLine")
local DestroyLine = getRemote(GrabEvents, "DestroyGrabLine")
local ExtendLine = getRemote(GrabEvents, "ExtendGrabLine")
local EndGrab = getRemote(GrabEvents, "EndGrabEarly")

local CharEvents = getRemote(ReplicatedStorage, "CharacterEvents")
local Struggle = getRemote(CharEvents, "Struggle")
local RagdollRemote = getRemote(CharEvents, "RagdollRemote")
local GrabEvent = getRemote(CharEvents, "Grab")

local StickyEvent = getRemote(ReplicatedStorage.PlayerEvents, "StickyPartEvent")
local SpawnToy = getRemote(ReplicatedStorage.MenuToys, "SpawnToyRemoteFunction")
local DestroyToyRemote = getRemote(ReplicatedStorage.MenuToys, "DestroyToy")
local GameCorrection = getRemote(ReplicatedStorage.GameCorrectionEvents, "GameCorrectionsNotify")

-- Helpers
local function getChar(plr) return plr.Character end
local function getRoot(char) return char and char:FindFirstChild("HumanoidRootPart") end
local function getHum(char) return char and char:FindFirstChildOfClass("Humanoid") end
local function sno(part) SNO:FireServer(part, part.CFrame) end
local function unsno(part) DestroyLine:FireServer(part) end

local function spawntoy(toyName, cf)
    if not LP.CanSpawnToy.Value then LP.CanSpawnToy.Changed:Wait() end
    local folder = Workspace[LP.Name .. "SpawnedInToys"]
    local toy = nil
    local conn = folder.ChildAdded:Connect(function(c)
        if c.Name == toyName then toy = c conn:Disconnect() end
    end)
    SpawnToy:InvokeServer(toyName, cf or (getRoot(LP.Character).CFrame * CFrame.new(0,10,0)), Vector3.zero)
    repeat task.wait() until toy or not conn.Connected
    if conn.Connected then conn:Disconnect() end
    return toy
end

local function getBlob()
    if LP.Character and getHum(LP.Character).SeatPart and getHum(LP.Character).SeatPart.Parent.Name == "CreatureBlobman" then
        return getHum(LP.Character).SeatPart.Parent
    end
    return nil
end

-- Global state
local state = {
    walkspeed = 16, jumppower = 50, flightspeed = 50, spinspeed = 10,
    strength = 300, extendspeed = 1, linelagspeed = 50, packetsize = 3000,
    grabEnabled = false, grabMode = "Kill",
    auraEnabled = false, auraMode = "Kill",
    lineExtend = false, lineLag = false, packetLag = false,
    superStrength = false, killGrab = false, masslessGrab = false,
    spinGrab = false, ragdollGrab = false, kickGrab = false,
    antiGrab = false, antiOwnership = false, antiBlob = false,
    antiBurn = false, antiVoid = false, antiExplo = false,
    antiPaint = false, antiSticky = false, antiInputLag = false,
    antiBanana = false, killDodge = false, flyingReset = false,
    antiRagBlob = false, shurikenAntiKick = false,
    gucciManual = false, autoGucci = false, loopTP = false,
    targetPlayer = nil,
    kickOwnership = false, kickPallet = false, kickSnowball = false,
    loopKill = false, loopKickBlob = false, bringAll = false,
    blobTarget = nil, blobMethod = "Lock Target1", blobLock = false,
    thirdperson = false, fov = 90, esp = false, antikickESP = false,
    waterwalk = false, platformTP = false, platformKey = "X",
    jerkKey = "Q", gucciKey = "J",
    connections = {}, tasks = {}, shurikenObj = nil,
}

local function refreshDropdown(dropdown)
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then table.insert(list, p.Name) end
    end
    dropdown:SetValues(list)
    if #list > 0 then dropdown:SetValue(list[1]) end
end

-- Build Window
local Window = Library:CreateWindow({
    Title = "private hub",
    Footer = "by HxL",
    NotifySide = "Right",
    ShowCustomCursor = true,
    EnableCompacting = true,
    SidebarCompacted = true,
})

local HomeTab = Window:AddTab("Home", "home")
local PlayerTab = Window:AddTab("Player", "user")
local CombatTab = Window:AddTab("Combat", "sword")
local DefenseTab = Window:AddTab("Defense", "shield")
local TargetTab = Window:AddTab("Target", "crosshair")
local BlobmanTab = Window:AddTab("Blobman", "blob")
local VisualsTab = Window:AddTab("Visuals", "eye")
local MiscTab = Window:AddTab("Misc", "zap")
local ServerTab = Window:AddTab("Server", "server")
local KeybindsTab = Window:AddTab("Keybinds", "keyboard")
local SettingsTab = Window:AddTab("Settings", "settings")

-- ==================== HOME ====================
HomeTab:AddLeftGroupbox("Welcome"):AddLabel("private hub by HxL")
HomeTab:AddRightGroupbox("Quick Actions"):AddButton({Text = "Kick All Players", Func = function()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local tr = getRoot(p.Character)
            if tr then
                sno(tr)
                for _ = 1, 40 do CreateLine:FireServer(tr, tr.CFrame) task.wait() end
                DestroyLine:FireServer(tr)
            end
        end
    end
end})

-- ==================== PLAYER ====================
local moveGroup = PlayerTab:AddLeftGroupbox("Movement")
moveGroup:AddSlider('WalkSpeed', {Text='Walk Speed', Default=16, Min=0, Max=200, Callback=function(v) state.walkspeed=v; local hum=getHum(LP.Character) if hum then hum.WalkSpeed=v end end})
moveGroup:AddSlider('JumpPower', {Text='Jump Power', Default=50, Min=0, Max=300, Callback=function(v) state.jumppower=v; local hum=getHum(LP.Character) if hum then hum.JumpPower=v end end})
moveGroup:AddSlider('FlightSpeed', {Text='Flight Speed', Default=50, Min=10, Max=200, Callback=function(v) state.flightspeed=v end})
moveGroup:AddSlider('SpinSpeed', {Text='Spin Speed', Default=10, Min=1, Max=50, Callback=function(v) state.spinspeed=v end})

moveGroup:AddToggle('Fly', {Text='Fly', Default=false, Callback=function(v)
    state.flying = v
    if v then
        task.spawn(function() while state.flying do
            local root = getRoot(LP.Character)
            if root then
                local bv = root:FindFirstChild("FlyBV") or Instance.new("BodyVelocity")
                bv.Name="FlyBV"; bv.MaxForce=Vector3.new(1e5,1e5,1e5); bv.Parent=root
                local bg = root:FindFirstChild("FlyBG") or Instance.new("BodyGyro")
                bg.Name="FlyBG"; bg.MaxTorque=Vector3.new(1e5,1e5,1e5); bg.Parent=root
                local move = Vector3.zero
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += Camera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= Camera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= Camera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += Camera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0,1,0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move -= Vector3.new(0,1,0) end
                bv.Velocity = move * state.flightspeed
                bg.CFrame = Camera.CFrame
            end
            task.wait()
        end end)
    else
        if LP.Character then
            local root = getRoot(LP.Character)
            if root then
                if root:FindFirstChild("FlyBV") then root.FlyBV:Destroy() end
                if root:FindFirstChild("FlyBG") then root.FlyBG:Destroy() end
            end
        end
    end
end})
moveGroup:AddToggle('Spin', {Text='Spin', Default=false, Callback=function(v)
    state.spinning = v
    if v then task.spawn(function() while state.spinning do local root=getRoot(LP.Character) if root then root.CFrame=root.CFrame*CFrame.Angles(0,math.rad(state.spinspeed),0) end task.wait() end end) end
end})
moveGroup:AddToggle('InfJump', {Text='Infinite Jump', Default=false, Callback=function(v)
    if v then UserInputService.JumpRequest:Connect(function() local hum=getHum(LP.Character) if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end end) end
end})

local tpGroup = PlayerTab:AddRightGroupbox("Teleports")
local houses = {"Barn","BlueHouse","Factory","GlassHouse","JapaneseHouse","PinkRoofHouse","SpookyHouse","Train","TudorHouse"}
tpGroup:AddDropdown('HouseSelect', {Values=houses, Default=1, Text='House'})
tpGroup:AddButton({Text='TP to House', Func=function()
    local h = Workspace.Waypoints:FindFirstChild(Options.HouseSelect.Value)
    if h and h:IsA("Model") then
        local pp = h.PrimaryPart or h:FindFirstChildWhichIsA("BasePart")
        if pp then getRoot(LP.Character).CFrame = pp.CFrame + Vector3.new(0,5,0) end
    end
end})
tpGroup:AddButton({Text='TP to Spawn', Func=function()
    local s = Workspace:FindFirstChild("SpawningPlatform")
    if s then getRoot(LP.Character).CFrame = s:FindFirstChildWhichIsA("BasePart").CFrame + Vector3.new(0,5,0) end
end})
tpGroup:AddToggle('LoopTP', {Text='Loop TP', Default=false, Callback=function(v)
    state.loopTP = v
    if v then task.spawn(function() while state.loopTP do local root=getRoot(LP.Character) if root then root.CFrame=CFrame.new(math.random(-500,500),math.random(30,400),math.random(-500,500)) end task.wait(0.05) end end) end
end})
tpGroup:AddToggle('PlatformTP', {Text='Platform TP', Default=false, Callback=function(v)
    state.platformTP = v
    if v then
        local plat = Instance.new("Part", Workspace)
        plat.Name="Platform"; plat.Anchored=true; plat.Size=Vector3.new(50,1,50); plat.CFrame=CFrame.new(0,100000,0)
        UserInputService.InputBegan:Connect(function(i,gpe) if not gpe and i.KeyCode==Enum.KeyCode[state.platformKey] and state.platformTP then local root=getRoot(LP.Character) if root then root.CFrame=plat.CFrame+Vector3.new(0,5,0) end end end)
    end
end})
tpGroup:AddLabel("Platform TP Key"):AddKeyPicker('PlatformKey', {Default='X', Callback=function(k) state.platformKey=k end})

local charGroup = PlayerTab:AddLeftGroupbox("Character")
charGroup:AddButton({Text='Apply WalkSpeed', Func=function() local hum=getHum(LP.Character) if hum then hum.WalkSpeed=state.walkspeed end end})
charGroup:AddButton({Text='Apply JumpPower', Func=function() local hum=getHum(LP.Character) if hum then hum.JumpPower=state.jumppower end end})

-- ==================== COMBAT ====================
local grabsGroup = CombatTab:AddLeftGroupbox("Grabs")
grabsGroup:AddDropdown('GrabMode', {Values={"Kill","Kick","Void","Spin","Fling","TP to Spawn"}, Default=1, Text='Grab Mode', Callback=function(v) state.grabMode=v end})
grabsGroup:AddToggle('GrabEnabled', {Text='Enable Grab Mode', Default=false, Callback=function(v) state.grabEnabled=v end})

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe or not state.grabEnabled then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local ray = Camera:ScreenPointToRay(Mouse.X, Mouse.Y)
        local params = RaycastParams.new(); params.FilterType = Enum.RaycastFilterType.Blacklist; params.FilterDescendantsInstances = {LP.Character}
        local hit = Workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
        if hit and hit.Instance then
            local char = hit.Instance:FindFirstAncestorOfClass("Model")
            if char then
                local plr = Players:GetPlayerFromCharacter(char)
                if plr and plr ~= LP then
                    local tr = getRoot(char)
                    if not tr then return end
                    if state.grabMode == "Kill" then
                        sno(tr); local myRoot=getRoot(LP.Character); local old=myRoot.CFrame; myRoot.CFrame=tr.CFrame+Vector3.new(0,3,-3)
                        for _=1,30 do CreateLine:FireServer(tr, tr.CFrame); ExtendLine:FireServer(tr,30) task.wait(0.01) end
                        EndGrab:FireServer(); myRoot.CFrame=old
                    elseif state.grabMode == "Kick" then
                        sno(tr); local myRoot=getRoot(LP.Character); local old=myRoot.CFrame; myRoot.CFrame=tr.CFrame+Vector3.new(0,3,-3)
                        for _=1,20 do DestroyLine:FireServer(tr) RunService.RenderStepped:Wait() SNO:FireServer(tr,tr.CFrame) DestroyLine:FireServer(tr) RunService.RenderStepped:Wait() SNO:FireServer(tr,tr.CFrame) end
                        myRoot.CFrame=old
                    elseif state.grabMode == "Void" then tr.CFrame = CFrame.new(0,-100,0)
                    elseif state.grabMode == "Spin" then task.spawn(function() while state.grabEnabled and char.Parent do tr.CFrame=tr.CFrame*CFrame.Angles(0,math.rad(30),0) task.wait(0.05) end end)
                    elseif state.grabMode == "Fling" then
                        local bv = Instance.new("BodyVelocity"); bv.MaxForce=Vector3.new(1e8,1e8,1e8); bv.Velocity=Vector3.new(0,5000,0); bv.Parent=tr; Debris:AddItem(bv,1)
                    elseif state.grabMode == "TP to Spawn" then
                        local s = Workspace:FindFirstChild("SpawningPlatform")
                        if s then tr.CFrame = s:FindFirstChildWhichIsA("BasePart").CFrame + Vector3.new(0,5,0) end
                    end
                end
            end
        end
    end
end)

grabsGroup:AddToggle('SuperStrength', {Text='Super Strength', Default=false, Callback=function(v) state.superStrength=v; if v then local c1=Workspace.ChildAdded:Connect(function(c) if c.Name=="GrabParts" and state.superStrength then local part=c:FindFirstChild("GrabPart") or c:WaitForChild("GrabPart",1) if part then local weld=part:FindFirstChild("WeldConstraint") or part:WaitForChild("WeldConstraint",1) if weld and weld.Part1 then local grabbed=weld.Part1 local conn=UserInputService.InputBegan:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton2 then local bv=Instance.new("BodyVelocity",grabbed) bv.MaxForce=Vector3.new(1e8,1e8,1e8) bv.Velocity=Camera.CFrame.LookVector*state.strength Debris:AddItem(bv,2) end end) c.Destroying:Connect(function() conn:Disconnect() end) end end end end) table.insert(state.connections,c1) end end})
grabsGroup:AddToggle('KillGrab', {Text='Kill Grab', Default=false, Callback=function(v) state.killGrab=v; if v then local c=Workspace.ChildAdded:Connect(function(c) if c.Name=="GrabParts" and state.killGrab then local part=c:FindFirstChild("GrabPart") if part and part:FindFirstChild("WeldConstraint") then local p=part.WeldConstraint.Part1 if p and p.Parent and p.Parent:FindFirstChildOfClass("Humanoid") then p.Parent.Humanoid.Health=0 end end end end) table.insert(state.connections,c) end end})
grabsGroup:AddToggle('MasslessGrab', {Text='Massless Grab', Default=false, Callback=function(v) state.masslessGrab=v; if v then local c=RunService.Heartbeat:Connect(function() local gp=Workspace:FindFirstChild("GrabParts") if gp then local dp=gp:FindFirstChild("DragPart") if dp then local ap=dp:FindFirstChild("AlignPosition") if ap then ap.Responsiveness=200; ap.MaxForce=1e8; ap.MaxVelocity=1e8 end local ao=dp:FindFirstChild("AlignOrientation") if ao then ao.Responsiveness=200; ao.MaxTorque=1e8 end end end end) table.insert(state.connections,c) end end})
grabsGroup:AddToggle('SpinGrab', {Text='Spin Grab', Default=false, Callback=function(v) state.spinGrab=v; if v then local c=Workspace.ChildAdded:Connect(function(c) if c.Name=="GrabParts" and state.spinGrab then local gp=c:FindFirstChild("GrabPart") if gp and gp:FindFirstChild("WeldConstraint") then local p=gp.WeldConstraint.Part1 while c.Parent and Workspace:FindFirstChild("GrabParts") do if p then p.AssemblyAngularVelocity=Vector3.new(0,100,0) end task.wait() end end end end) table.insert(state.connections,c) end end})
grabsGroup:AddToggle('RagdollGrab', {Text='Ragdoll Grab', Default=false, Callback=function(v) state.ragdollGrab=v; if v then local c=Workspace.ChildAdded:Connect(function(c) if c.Name=="GrabParts" and state.ragdollGrab then local gp=c:FindFirstChild("GrabPart") if gp and gp:FindFirstChild("WeldConstraint") then local p=gp.WeldConstraint.Part1 if p and p.Parent then local hum=p.Parent:FindFirstChildOfClass("Humanoid") if hum then hum.PlatformStand=true task.wait(0.015) hum.PlatformStand=false end end end end end) table.insert(state.connections,c) end end})
grabsGroup:AddToggle('KickGrab', {Text='Kick Grab', Default=false, Callback=function(v) state.kickGrab=v; if v then local c=Workspace.ChildAdded:Connect(function(c) if c.Name=="GrabParts" and state.kickGrab then local gp=c:FindFirstChild("GrabPart") if gp and gp:FindFirstChild("WeldConstraint") then local p=gp.WeldConstraint.Part1 while c.Parent and Workspace:FindFirstChild("GrabParts") do DestroyLine:FireServer(p) RunService.RenderStepped:Wait() SNO:FireServer(p,p.CFrame) DestroyLine:FireServer(p) RunService.RenderStepped:Wait() SNO:FireServer(p,p.CFrame) end end end end) table.insert(state.connections,c) end end})

-- Auras
local auraGroup = CombatTab:AddLeftGroupbox("Auras")
auraGroup:AddDropdown('AuraMode', {Values={"Kill","Kick","Void","Fling","Sky","TP to Spawn"}, Default=1, Text='Aura Mode', Callback=function(v) state.auraMode=v end})
auraGroup:AddToggle('AuraToggle', {Text='Enable Aura', Default=false, Callback=function(v) state.auraEnabled=v; if v then task.spawn(function() while state.auraEnabled do local myRoot=getRoot(LP.Character) if myRoot then for _,plr in ipairs(Players:GetPlayers()) do if plr~=LP then local tr=getRoot(getChar(plr)) if tr and (tr.Position-myRoot.Position).Magnitude<=50 then if state.auraMode=="Kill" then sno(tr); for _=1,10 do CreateLine:FireServer(tr,tr.CFrame); ExtendLine:FireServer(tr,30) task.wait(0.01) end; EndGrab:FireServer() elseif state.auraMode=="Kick" then sno(tr); for _=1,30 do CreateLine:FireServer(tr,tr.CFrame); ExtendLine:FireServer(tr,30) task.wait(0.005) end elseif state.auraMode=="Void" then tr.CFrame=CFrame.new(0,-100,0) elseif state.auraMode=="Fling" then local bv=Instance.new("BodyVelocity"); bv.MaxForce=Vector3.new(1e8,1e8,1e8); bv.Velocity=Vector3.new(0,5000,0); bv.Parent=tr; Debris:AddItem(bv,1) elseif state.auraMode=="Sky" then tr.CFrame=tr.CFrame+Vector3.new(0,500,0) elseif state.auraMode=="TP to Spawn" then local s=Workspace:FindFirstChild("SpawningPlatform") if s then tr.CFrame=s:FindFirstChildWhichIsA("BasePart").CFrame+Vector3.new(0,5,0) end end end end end task.wait(0.3) end end) end end})

-- Line extend & lag
local lineGroup = CombatTab:AddRightGroupbox("Line")
lineGroup:AddToggle('LineExtend', {Text='Extend Line', Default=false, Callback=function(v) state.lineExtend=v; if v then task.spawn(function() while state.lineExtend do if state.targetPlayer then local tr=getRoot(getChar(state.targetPlayer)) if tr then ExtendLine:FireServer(tr,30) end end task.wait(1/state.extendspeed) end end) end end})
lineGroup:AddSlider('ExtendSpeed', {Text='Extend Speed', Default=1, Min=1, Max=30, Callback=function(v) state.extendspeed=v end})

local lagGroup = CombatTab:AddRightGroupbox("Line Lag")
lagGroup:AddToggle('LineLag', {Text='Enable Line Lag', Default=false, Callback=function(v) state.lineLag=v; if v then task.spawn(function() while state.lineLag do for _,plr in ipairs(Players:GetPlayers()) do if plr~=LP then local tr=getRoot(getChar(plr)) if tr then CreateLine:FireServer(tr,tr.CFrame) end end end task.wait(1/state.linelagspeed) end end) end end})
lagGroup:AddSlider('LagSpeed', {Text='Lag Speed', Default=50, Min=50, Max=1000, Callback=function(v) state.linelagspeed=v end})
lagGroup:AddButton({Text='MAX Lag', Func=function() Toggles.LineLag:SetValue(true); Options.LagSpeed:SetValue(1000) end})

local packetGroup = CombatTab:AddRightGroupbox("Packet Lag")
packetGroup:AddSlider('PacketSize', {Text='Packet Size', Default=3000, Min=100, Max=60000, Callback=function(v) state.packetsize=v end})
packetGroup:AddToggle('PacketLag', {Text='Enable Packets', Default=false, Callback=function(v) state.packetLag=v; if v then task.spawn(function() while state.packetLag do ExtendLine:FireServer(string.rep("a", state.packetsize)) task.wait(0.5) end end) end end})

-- ==================== DEFENSE ====================
local defLeft = DefenseTab:AddLeftGroupbox("Anti")
defLeft:AddToggle('AntiGrab', {Text='Anti Grab', Default=false, Callback=function(v) state.antiGrab=v; if v then local conn=LP.IsHeld:GetPropertyChangedSignal("Value"):Connect(function() if state.antiGrab and LP.IsHeld.Value then local char=LP.Character if char then local hrp=getRoot(char) Struggle:FireServer() hrp.Anchored=true repeat Struggle:FireServer() task.wait() until not LP.IsHeld.Value hrp.Anchored=false end end end) table.insert(state.connections,conn) end end})
defLeft:AddToggle('AntiOwnership', {Text='Anti Ownership', Default=false, Callback=function(v) state.antiOwnership=v; if v then local conn=LP.IsHeld:GetPropertyChangedSignal("Value"):Connect(function() if state.antiOwnership and LP.IsHeld.Value then local char=LP.Character if char then local hrp=getRoot(char) Struggle:FireServer() hrp.Anchored=true repeat Struggle:FireServer() task.wait() until not LP.IsHeld.Value hrp.Anchored=false end end end) table.insert(state.connections,conn) end end})
defLeft:AddToggle('AntiBlobman', {Text='Anti Blobman', Default=false, Callback=function(v) state.antiBlob=v; if v then local c=Workspace.DescendantAdded:Connect(function(d) if d.Name=="CreatureBlobman" and not d:IsDescendantOf(Workspace[LP.Name.."SpawnedInToys"]) then local rd=d:FindFirstChild("RightDetector") if rd then rd.RightWeld.Enabled=false; rd.RightAlignOrientation.Enabled=false end local ld=d:FindFirstChild("LeftDetector") if ld then ld.LeftWeld.Enabled=false; ld.LeftAlignOrientation.Enabled=false end end end) table.insert(state.connections,c) end end})
defLeft:AddToggle('AntiBurn', {Text='Anti Burn', Default=false, Callback=function(v) state.antiBurn=v; if v then local hum=getHum(LP.Character) if hum then local conn=hum.FireDebounce.Changed:Connect(function(val) if state.antiBurn and val then local hrp=getRoot(LP.Character) local bar=Workspace.Plots.Plot1.Barrier.PlotBarrier local saved=bar.CFrame task.spawn(function() while hum and hum.FireDebounce.Value do bar.CFrame=hrp.CFrame task.wait() end end) task.wait(1) hum.FireDebounce.Value=false task.wait() bar.CFrame=saved end end) table.insert(state.connections,conn) end end end})
defLeft:AddToggle('AntiVoid', {Text='Anti Void', Default=false, Callback=function(v) state.antiVoid=v; Workspace.FallenPartsDestroyHeight=v and 0/0 or -100 end})
defLeft:AddToggle('AntiExplode', {Text='Anti Explosion', Default=false, Callback=function(v) state.antiExplo=v; if v then local c=Workspace.ChildAdded:Connect(function(obj) if obj.Name=="Part" and state.antiExplo then local hrp=getRoot(LP.Character) if hrp and (obj.Position-hrp.Position).Magnitude<20 then hrp.Anchored=true; task.wait(0.01); hrp.Anchored=false end end end) table.insert(state.connections,c) end end})
defLeft:AddToggle('AntiPaint', {Text='Anti Paint', Default=false, Callback=function(v) state.antiPaint=v; if v then local c=Workspace.DescendantAdded:Connect(function(d) if d.Name=="PaintPlayerPart" then d:Destroy() end end) table.insert(state.connections,c) end end})
defLeft:AddToggle('AntiSticky', {Text='Anti Sticky', Default=false, Callback=function(v) LP.PlayerScripts.StickyPartsTouchDetection.Enabled=not v end})
defLeft:AddToggle('AntiInputLag', {Text='Anti Input Lag', Default=false, Callback=function(v) state.antiInputLag=v; if v then local burger=spawntoy("FoodCoconut") burger.Name="antiInput" task.spawn(function() while state.antiInputLag do burger.HoldPart.HoldItemRemoteFunction:InvokeServer(burger,LP.Character) task.wait(0.1) burger.HoldPart.DropItemRemoteFunction:InvokeServer(burger,CFrame.new(0,1e9,0),Vector3.zero) task.wait() end end) end end})
defLeft:AddToggle('AntiBananaSit', {Text='Anti Banana Sit', Default=false, Callback=function(v) state.antiBanana=v; if v then task.spawn(function() while state.antiBanana do local hum=getHum(LP.Character) if hum then hum.Sit=true; hum:ChangeState(Enum.HumanoidStateType.Running) end task.wait() end end) end end})
defLeft:AddToggle('KillDodge', {Text='Kill Dodge', Default=false, Callback=function(v) state.killDodge=v; if v then task.spawn(function() local tpos=Vector3.new(252,-7,464) LP.CharacterAdded:Connect(function(c) local hrp=getRoot(c); local hum=getHum(c) task.spawn(function() while state.killDodge do if not LP.InPlot.Value and hum.Health>0 then hrp.CFrame=CFrame.new(tpos) end task.wait() end end) end) end) end end})
defLeft:AddToggle('FlyingReset', {Text='Flying Reset', Default=false, Callback=function(v) state.flyingReset=v; if v then local c=GameCorrection.OnClientEvent:Connect(function(t) if t=="Flying" and state.flyingReset then Struggle:FireServer() local hum=getHum(LP.Character) if hum then hum.Health=0 end end end) table.insert(state.connections,c) end end})
defLeft:AddToggle('AntiRagBlob', {Text='Anti Ragdoll on Blob', Default=false, Callback=function(v) state.antiRagBlob=v; if v then local c=LP.CharacterAdded:Connect(function(char) task.wait(0.5) local hum=getHum(char) if hum then local sc=hum:GetPropertyChangedSignal("SeatPart"):Connect(function() if hum.SeatPart and hum.SeatPart.Parent.Name=="CreatureBlobman" and state.antiRagBlob then local seat=hum.SeatPart while not hum.Sit do task.wait() end RagdollRemote:FireServer(getRoot(char),3) while not hum.Ragdolled.Value do task.wait() end task.wait(0.4) hum.Sit=false seat:Sit(hum) task.delay(0.25,function() while hum.SeatPart do RagdollRemote:FireServer(getRoot(char),1) task.wait(0.05) end end) end end) table.insert(state.connections,sc) end end) table.insert(state.connections,c) end end})
defLeft:AddToggle('ShurikenAntiKick', {Text='Shuriken Anti Kick', Default=false, Callback=function(v) state.shurikenAntiKick=v; if v then task.spawn(function() local function clear() if state.shurikenObj and state.shurikenObj.Parent then DestroyToyRemote:FireServer(state.shurikenObj) state.shurikenObj=nil end end local function weldIt() if not LP.Character then return end local hrp=getRoot(LP.Character) if not hrp then return end clear() repeat task.wait() until LP.CanSpawnToy.Value SpawnToy:InvokeServer("NinjaShuriken",hrp.CFrame*CFrame.new(0,12,20),Vector3.zero) local shu=Workspace[LP.Name.."SpawnedInToys"]:WaitForChild("NinjaShuriken",5) if shu then shu.Name="AntiKick" local part=shu:WaitForChild("StickyPart") sno(part) StickyEvent:FireServer(part,hrp:WaitForChild("FirePlayerPart"),CFrame.Angles(0,math.rad(90),math.rad(90))) state.shurikenObj=shu end end weldIt() local conn=Workspace[LP.Name.."SpawnedInToys"].ChildRemoved:Connect(function(child) if child==state.shurikenObj and state.shurikenAntiKick then weldIt() end end) local charConn=LP.CharacterAdded:Connect(function() if state.shurikenAntiKick then weldIt() end end) table.insert(state.connections,conn) table.insert(state.connections,charConn) end) else local inv=Workspace[LP.Name.."SpawnedInToys"] if inv then for _,obj in ipairs(inv:GetChildren()) do if obj.Name=="AntiKick" then DestroyToyRemote:FireServer(obj) end end end end end})

-- Gucci (Apple method)
local defRight = DefenseTab:AddRightGroupbox("Gucci")
defRight:AddToggle('GucciManual', {Text='Gucci (press J)', Default=false, Callback=function(v) state.gucciManual=v end})
defRight:AddToggle('AutoGucci', {Text='Auto Gucci', Default=false, Callback=function(v) state.autoGucci=v; if v then task.spawn(function() while state.autoGucci do if not getHum(LP.Character).SeatPart or getHum(LP.Character).SeatPart.Parent.Name~="CreatureBlobman" then local blob=spawntoy("CreatureBlobman",getRoot(LP.Character).CFrame*CFrame.new(5,5,20)) blob.VehicleSeat:Sit(getHum(LP.Character)) task.wait(3) blob.VehicleSeat.CFrame=CFrame.new(0,0/0,0) end task.wait(5) end end) end end})

-- ==================== TARGET ====================
local tgtGroup = TargetTab:AddLeftGroupbox("Selection")
local targetDropdown = tgtGroup:AddDropdown('TargetPlayer', {Values={}, Default=1, Text='Target', Callback=function(v) state.targetPlayer=Players:FindFirstChild(v) end})
tgtGroup:AddButton({Text='Refresh', Func=function() refreshDropdown(targetDropdown) end})

local kickGroup = TargetTab:AddRightGroupbox("Kick Methods")
kickGroup:AddToggle('OwnershipKick', {Text='Ownership Kick', Default=false, Callback=function(v)
    state.kickOwnership = v
    if v and state.targetPlayer then
        local targetName = state.targetPlayer.Name
        task.spawn(function()
            local GE = GrabEvents
            local currentFPS = 60
            local fpsConnection = RunService.RenderStepped:Connect(function(dt) currentFPS = 1/dt end)
            local bodyPos, bodyGyro
            local function cleanup() if bodyPos then bodyPos:Destroy() end if bodyGyro then bodyGyro:Destroy() end end
            local savedPos = getRoot(LP.Character).CFrame
            local dragging, grabStart = false, 0
            while state.kickOwnership do
                local target = Players:FindFirstChild(targetName)
                if not target or not target.Character then break end
                local myRoot = getRoot(LP.Character)
                local tChar = target.Character
                local tRoot = getRoot(tChar)
                local tHum = getHum(tChar)
                if tRoot and tHum and myRoot then
                    if not dragging then
                        myRoot.CFrame = tRoot.CFrame * CFrame.new(0,0,3)
                        cleanup()
                        pcall(function()
                            tHum.PlatformStand = true; tHum.Sit = true
                            SNO:FireServer(tRoot, tRoot.CFrame)
                            DestroyLine:FireServer(tRoot)
                        end)
                        if grabStart == 0 then grabStart = tick() end
                        if tick() - grabStart > 0.35 then
                            dragging = true; grabStart = 0
                            local lockPos = savedPos * CFrame.new(0,17,0)
                            bodyPos = Instance.new("BodyPosition", tRoot)
                            bodyPos.MaxForce = Vector3.new(9e9,9e9,9e9); bodyPos.D = 100; bodyPos.Position = lockPos.Position
                            bodyGyro = Instance.new("BodyGyro", tRoot)
                            bodyGyro.MaxTorque = Vector3.new(9e9,9e9,9e9); bodyGyro.D = 100; bodyGyro.CFrame = lockPos
                        end
                    else
                        myRoot.CFrame = savedPos
                        local lockPos = savedPos * CFrame.new(0,17,0)
                        pcall(function()
                            local f = currentFPS > 200 and 2 or (currentFPS >= 155 and 3 or 4)
                            for _=1,f do
                                SNO:FireServer(tRoot, lockPos)
                                DestroyLine:FireServer(tRoot)
                            end
                        end)
                        if bodyPos and bodyPos.Parent then
                            bodyPos.Position = lockPos.Position; bodyGyro.CFrame = lockPos
                        end
                        if (tRoot.Position - lockPos.Position).Magnitude > 10 then
                            dragging = false; grabStart = 0; cleanup()
                            myRoot.CFrame = tRoot.CFrame * CFrame.new(0,0,3)
                        end
                    end
                else
                    dragging = false; grabStart = 0; cleanup()
                end
                RunService.Heartbeat:Wait()
            end
            fpsConnection:Disconnect()
            cleanup()
            if LP.Character and getRoot(LP.Character) then getRoot(LP.Character).CFrame = savedPos end
        end)
    end
end})
kickGroup:AddToggle('PalletRagdoll', {Text='Pallet Ragdoll', Default=false, Callback=function(v) state.kickPallet=v; if v and state.targetPlayer then task.spawn(function() while state.kickPallet do local t=state.targetPlayer if not t or not t.Character then break end local sky=CFrame.new(0,800000,0) SpawnToy:InvokeServer("PalletLightBrown",sky,Vector3.zero) local p=Workspace[LP.Name.."SpawnedInToys"]:WaitForChild("PalletLightBrown",3) if p then local sp=p:WaitForChild("SoundPart") sp.Anchored=false sp.CanCollide=false sno(sp) for i=1,20 do RunService.Heartbeat:Wait() end local head=t.Character:FindFirstChild("Head") if head then sp.CFrame=CFrame.new(head.Position+Vector3.new(0,0.2,0)) end sp.CanCollide=true task.wait(0.1) sp.CanCollide=false sp.CFrame=sky DestroyToyRemote:FireServer(p) end task.wait(1) end end) end end})
kickGroup:AddToggle('SnowballRagdoll', {Text='Snowball Ragdoll', Default=false, Callback=function(v) state.kickSnowball=v; if v and state.targetPlayer then task.spawn(function() while state.kickSnowball do local t=state.targetPlayer if not t or not t.Character then break end local torso=t.Character:FindFirstChild("Torso") or t.Character:FindFirstChild("UpperTorso") if not torso then continue end for i=1,3 do SpawnToy:InvokeServer("BallSnowball",torso.CFrame*CFrame.new(math.random()-0.5,math.random()-0.5,math.random()-0.5),Vector3.zero) end task.wait(0.5) local inv=Workspace[LP.Name.."SpawnedInToys"] for _,sb in ipairs(inv:GetChildren()) do if sb.Name=="BallSnowball" and sb.PrimaryPart then sb.PrimaryPart.CFrame=torso.CFrame*CFrame.new(math.random()-0.5,math.random()-0.5,math.random()-0.5) sb.PrimaryPart.Velocity=Vector3.zero end end task.wait() end end) end end})
kickGroup:AddToggle('LoopKill', {Text='Loop Kill', Default=false, Callback=function(v) state.loopKill=v; if v and state.targetPlayer then task.spawn(function() while state.loopKill do local t=state.targetPlayer if not t or not t.Character then break end local tr=getRoot(t.Character) if tr then local mr=getRoot(LP.Character) local saved=mr.CFrame mr.CFrame=tr.CFrame+Vector3.new(0,3,-3) sno(tr) for _=1,10 do CreateLine:FireServer(tr,tr.CFrame) ExtendLine:FireServer(tr,30) task.wait(0.01) end EndGrab:FireServer() mr.CFrame=saved end task.wait(1.2) end end) end end})
kickGroup:AddToggle('LoopKickBlob', {Text='Loop Kick Blob', Default=false, Callback=function(v) state.loopKickBlob=v; if v and state.targetPlayer then task.spawn(function() while state.loopKickBlob do local t=state.targetPlayer if not t then break end local blob=getBlob() if not blob then break end local tr=getRoot(t.Character) if not tr then continue end local CG=blob.BlobmanSeatAndOwnerScript.CreatureGrab local CD=blob.BlobmanSeatAndOwnerScript.CreatureDrop local RD=blob.RightDetector local RW=RD.RightWeld CG:FireServer(RD,tr,RW) task.wait(0.01) CD:FireServer(RW) task.wait(0.01) end end) end end})

-- Bring All (Grab) from FatalityZ
kickGroup:AddToggle('BringAllGrab', {Text='Bring All (Grab)', Default=false, Callback=function(v)
    state.bringAll = v
    if v then
        task.spawn(function()
            for loop=1,2 do
                if not state.bringAll then break end
                for _,target in ipairs(Players:GetPlayers()) do
                    if target~=LP and target.Character and target.Character:FindFirstChild("HumanoidRootPart") and getHum(target.Character) and getHum(target.Character).Health>0 then
                        local tr = getRoot(target.Character)
                        local mr = getRoot(LP.Character)
                        local saved = mr.CFrame
                        mr.CFrame = tr.CFrame; mr.Velocity=Vector3.zero; task.wait(0.20)
                        pcall(function()
                            getHum(target.Character).PlatformStand=true; getHum(target.Character).Sit=true
                            SNO:FireServer(tr, mr.CFrame)
                            CreateLine:FireServer(tr, Vector3.zero, tr.Position, false)
                        end)
                        task.wait(0.20)
                        mr.CFrame = saved; mr.Velocity=Vector3.zero
                        tr.CFrame = saved*CFrame.new(0,0,-5)
                        tr.AssemblyLinearVelocity=Vector3.zero; tr.AssemblyAngularVelocity=Vector3.zero; tr.Velocity=Vector3.zero; tr.RotVelocity=Vector3.zero
                        pcall(function()
                            DestroyLine:FireServer(tr)
                            getHum(target.Character).PlatformStand=false; getHum(target.Character).Sit=false
                            SNO:FireServer(tr, tr.CFrame)
                        end)
                        task.wait(0.15)
                    end
                end
            end
            state.bringAll = false; Toggles.BringAllGrab:SetValue(false)
        end)
    end
end})

-- ==================== BLOBMAN ====================
local blobGroup = BlobmanTab:AddLeftGroupbox("Blobman")
local blobDropdown = blobGroup:AddDropdown('BlobTarget', {Values={}, Default=1, Text='Target', Callback=function(v) state.blobTarget=Players:FindFirstChild(v) end})
blobGroup:AddButton({Text='Refresh', Func=function() refreshDropdown(blobDropdown) end})
blobGroup:AddDropdown('BlobMethod', {Values={"Lock Target1","Lock Target2","Super Lock","Kill"}, Default=1, Text='Method', Callback=function(v) state.blobMethod=v end})
blobGroup:AddButton({Text='Apply Method', Func=function()
    if not state.blobTarget then return end
    local blob=getBlob() if not blob then return end
    local t=state.blobTarget if not t.Character then return end
    local tr=getRoot(t.Character) if not tr then return end
    local script=blob.BlobmanSeatAndOwnerScript
    local CG=script.CreatureGrab local CD=script.CreatureDrop local CR=script.CreatureRelease
    local RD=blob.RightDetector local RW=RD.RightWeld
    local mr=getRoot(LP.Character)
    if state.blobMethod=="Lock Target1" then
        if (tr.Position-mr.Position).Magnitude>30 then mr.CFrame=tr.CFrame sno(tr) mr.CFrame=mr.CFrame end
        CG:FireServer(RD,tr,RW) CD:FireServer(RW) CG:FireServer(RD,tr,RW)
    elseif state.blobMethod=="Lock Target2" then
        if (tr.Position-mr.Position).Magnitude>30 then mr.CFrame=tr.CFrame sno(tr) mr.CFrame=mr.CFrame end
        CG:FireServer(RD,tr,RW) CD:FireServer(RW)
    elseif state.blobMethod=="Super Lock" then
        if (tr.Position-mr.Position).Magnitude>30 then mr.CFrame=tr.CFrame sno(tr) mr.CFrame=mr.CFrame end
        CG:FireServer(RD,tr,RW) CR:FireServer(RW)
        if tr:GetNetworkOwner()==LP then tr.CFrame=RD.CFrame end
    elseif state.blobMethod=="Kill" then
        blob.HumanoidRootPart.CFrame=tr.CFrame
        repeat CG:FireServer(nil,tr,RW) CD:FireServer(RW) task.wait() until tr:GetNetworkOwner()==LP
        t.Character.Humanoid.Health=0
    end
end})
blobGroup:AddToggle('LoopBlobMethod', {Text='Loop Apply', Default=false, Callback=function(v) state.blobLock=v; if v then task.spawn(function() while state.blobLock do if state.blobTarget and state.blobTarget.Character then local blob=getBlob() if blob then local tr=getRoot(state.blobTarget.Character) if tr then local script=blob.BlobmanSeatAndOwnerScript local CG=script.CreatureGrab local CD=script.CreatureDrop local CR=script.CreatureRelease local RD=blob.RightDetector local RW=RD.RightWeld local mr=getRoot(LP.Character) if state.blobMethod=="Lock Target1" then if (tr.Position-mr.Position).Magnitude>30 then mr.CFrame=tr.CFrame sno(tr) mr.CFrame=mr.CFrame end CG:FireServer(RD,tr,RW) CD:FireServer(RW) CG:FireServer(RD,tr,RW) elseif state.blobMethod=="Lock Target2" then if (tr.Position-mr.Position).Magnitude>30 then mr.CFrame=tr.CFrame sno(tr) mr.CFrame=mr.CFrame end CG:FireServer(RD,tr,RW) CD:FireServer(RW) elseif state.blobMethod=="Super Lock" then if (tr.Position-mr.Position).Magnitude>30 then mr.CFrame=tr.CFrame sno(tr) mr.CFrame=mr.CFrame end CG:FireServer(RD,tr,RW) CR:FireServer(RW) if tr:GetNetworkOwner()==LP then tr.CFrame=RD.CFrame end elseif state.blobMethod=="Kill" then blob.HumanoidRootPart.CFrame=tr.CFrame repeat CG:FireServer(nil,tr,RW) CD:FireServer(RW) task.wait() until tr:GetNetworkOwner()==LP state.blobTarget.Character.Humanoid.Health=0 end end end end task.wait(0.5) end end) end end})

-- ==================== VISUALS ====================
local visGroup = VisualsTab:AddLeftGroupbox("ESP")
visGroup:AddToggle('PCLDESP', {Text='PCLD ESP', Default=false, Callback=function(v) state.esp=v; if v then local function addESP(part) if part:IsA("BasePart") and part.Name=="playercharacterlocationdetector" then local hl=Instance.new("Highlight",part) hl.FillColor=Color3.new(1,0,0) end end for _,obj in ipairs(Workspace:GetDescendants()) do addESP(obj) end local c=Workspace.DescendantAdded:Connect(function(obj) if state.esp then addESP(obj) end end) table.insert(state.connections,c) end end})
visGroup:AddToggle('AntiKickESP', {Text='Anti-Kick ESP', Default=false, Callback=function(v) state.antikickESP=v; if v then local function addH(obj) if (obj.Name=="NinjaShuriken" or obj.Name=="NinjaKunai") and obj:IsA("Model") then local hl=Instance.new("Highlight",obj) hl.FillColor=obj:FindFirstChild("StickyPart") and obj.StickyPart:FindFirstChild("StickyWeld") and obj.StickyPart.StickyWeld.Part1 and Color3.new(1,1,0) or Color3.new(0,1,0) end end for _,obj in ipairs(Workspace:GetDescendants()) do addH(obj) end local c=Workspace.DescendantAdded:Connect(function(obj) if state.antikickESP then addH(obj) end end) table.insert(state.connections,c) end end})

local camGroup = VisualsTab:AddRightGroupbox("Camera")
camGroup:AddToggle('ThirdPerson', {Text='Third Person', Default=false, Callback=function(v) state.thirdperson=v; LP.CameraMode=v and Enum.CameraMode.Classic or Enum.CameraMode.LockFirstPerson; if v then LP.CameraMaxZoomDistance=100000 LP.CameraMinZoomDistance=0.5 end end})
camGroup:AddSlider('FOV', {Text='FOV', Default=90, Min=30, Max=120, Callback=function(v) state.fov=v; Camera.FieldOfView=v end})

-- ==================== MISC ====================
local miscGroup = MiscTab:AddLeftGroupbox("Miscellaneous")
miscGroup:AddToggle('WaterWalk', {Text='Water Walk', Default=false, Callback=function(v) state.waterwalk=v; local ocean=Workspace.Map.AlwaysHereTweenedObjects.Ocean.Object.ObjectModel; if ocean then for _,part in ipairs(ocean:GetChildren()) do if part.Name=="Ocean" then part.CanCollide=v end end end end})
miscGroup:AddButton({Text='Break Barrier', Func=function() local b=spawntoy("FoodHamburger") b.HoldPart.HoldItemRemoteFunction:InvokeServer(b,LP.Character) task.wait(0.1) getRoot(LP.Character).CFrame=Workspace.Waypoints.TudorHouse.CFrame task.wait(0.1) DestroyToyRemote:FireServer(b) end})
miscGroup:AddButton({Text='Bring Train', Func=function() local b=spawntoy("FoodHamburger") Workspace.Map.AlwaysHereTweenedObjects.Train.Object.ObjectModel.Seat:Sit(getHum(LP.Character)) task.wait(0.1) b.HoldPart.HoldItemRemoteFunction:InvokeServer(b,LP.Character) task.wait(0.1) DestroyToyRemote:FireServer(b) getRoot(LP.Character).CFrame=getRoot(LP.Character).CFrame+Vector3.new(0,5,0) end})
miscGroup:AddButton({Text='Delete Legs', Func=function() local char=LP.Character if not char then return end local void=Workspace.FallenPartsDestroyHeight Workspace.FallenPartsDestroyHeight=-100 RagdollRemote:FireServer(getRoot(char),2) task.wait(0.5) for _,limb in ipairs({"Left Leg","Right Leg"}) do if char:FindFirstChild(limb) then char[limb].CFrame=CFrame.new(0,-10000,0) end end task.wait(0.5) getRoot(char).CFrame=CFrame.new(0,-9970,0) task.wait(0.5) Workspace.FallenPartsDestroyHeight=void end})
miscGroup:AddToggle('JerkOff', {Text='Jerk Off (Q)', Default=false, Callback=function(v) if v then local anim=Instance.new("Animation") anim.AnimationId="rbxassetid://168268306" local animator=getHum(LP.Character):FindFirstChildOfClass("Animator") or Instance.new("Animator",getHum(LP.Character)) local track=animator:LoadAnimation(anim) track:Play() state.tasks.jerk=track task.spawn(function() while track.IsPlaying do track.TimePosition=0.3 task.wait(0.1) end end) UserInputService.InputBegan:Connect(function(input,gpe) if not gpe and input.KeyCode==Enum.KeyCode[state.jerkKey] then if track.IsPlaying then track:Stop() else track:Play() end end end) else if state.tasks.jerk then state.tasks.jerk:Stop() end end end})
miscGroup:AddLabel("Jerk Key"):AddKeyPicker('JerkKey', {Default='Q', Callback=function(k) state.jerkKey=k end})

-- ==================== SERVER ====================
ServerTab:AddLeftGroupbox("Lag"):AddButton({Text='Line Lag All', Func=function() for _,p in ipairs(Players:GetPlayers()) do if p~=LP and p.Character then local tr=getRoot(p.Character) if tr then for _=1,100 do CreateLine:FireServer(tr,tr.CFrame) task.wait() end end end end end})
ServerTab:AddRightGroupbox("Destroy"):AddButton({Text='Destroy Server (Blob)', Func=function() local blob=spawntoy("CreatureBlobman") blob.VehicleSeat:Sit(getHum(LP.Character)) for _,p in ipairs(Players:GetPlayers()) do if p~=LP and p.Character then local tr=getRoot(p.Character) if tr then blob.HumanoidRootPart.CFrame=tr.CFrame repeat blob.BlobmanSeatAndOwnerScript.CreatureGrab:FireServer(nil,tr,blob.RightDetector.RightWeld) task.wait() until tr:GetNetworkOwner()==LP blob.BlobmanSeatAndOwnerScript.CreatureRelease:FireServer(blob.RightDetector.RightWeld) end end end DestroyToyRemote:FireServer(blob) end})

-- ==================== KEYBINDS ====================
KeybindsTab:AddLeftGroupbox("Keybinds"):AddLabel("J - Gucci")
KeybindsTab:AddLeftGroupbox("Keybinds"):AddLabel("Q - Jerk Off")

-- ==================== SETTINGS ====================
SettingsTab:AddLeftGroupbox("Settings"):AddButton({Text='Unload', Func=function() for _,v in ipairs(state.connections) do if v then v:Disconnect() end end state.connections={} if Workspace:FindFirstChild("Platform") then Workspace.Platform:Destroy() end if Workspace:FindFirstChild("FlyBV") then Workspace.FlyBV:Destroy() end if Workspace:FindFirstChild("FlyBG") then Workspace.FlyBG:Destroy() end Window:Destroy() end})

-- Initialize dropdowns
task.spawn(function() task.wait(1) refreshDropdown(targetDropdown) refreshDropdown(blobDropdown) end)

-- Gucci key handler
UserInputService.InputBegan:Connect(function(input,gpe) if not gpe and input.KeyCode==Enum.KeyCode[state.gucciKey] and state.gucciManual then local blob=spawntoy("CreatureBlobman",getRoot(LP.Character).CFrame*CFrame.new(5,5,20)) blob.VehicleSeat:Sit(getHum(LP.Character)) task.wait(3) blob.VehicleSeat.CFrame=CFrame.new(0,0/0,0) end end)

-- Save/Load
ThemeManager:SetLibrary(Library) SaveManager:SetLibrary(Library) SaveManager:IgnoreThemeSettings() SaveManager:SetIgnoreIndexes({"MenuKeybind"}) ThemeManager:SetFolder("PrivateHub") SaveManager:SetFolder("PrivateHub/Configs") SaveManager:BuildConfigSection(SettingsTab) ThemeManager:ApplyToTab(SettingsTab)

-- Keep alive
while task.wait(10) do end
