--[[ 
Premium Hub v6 ASCII - full single file
- Splash 7s then Hub
- Speed, Fly (clean exit), Light
- ESP (highlight + selectionbox + name + distance), team/role colors, username toggle
- Hitbox (HRP), TP Player, NoClip, Infinite Jump
- HUD, keybinds, drag, panic, autosave
- ASCII only (no UTF-8)
]]

-- hard reset previous UIs
pcall(function()
    local P = game:GetService("Players").LocalPlayer
    local roots = {}
    local okCore, core = pcall(function() return game:GetService("CoreGui") end)
    local function add(x) if x then table.insert(roots, x) end end
    add(gethui and gethui())
    add(okCore and core)
    add(P and P:FindFirstChild("PlayerGui"))
    local names = {"PremiumHubV6_ASCII","PremiumHUD_ASCII","PH_SPLASH_ASCII","PremiumHubV6","PremiumHUD","PH_BOOT","PH_Splash"}
    for _,root in ipairs(roots) do
        for _,n in ipairs(names) do
            pcall(function() if root:FindFirstChild(n) then root[n]:Destroy() end end)
        end
    end
end)

-- services
local Players  = game:GetService("Players")
local UIS      = game:GetService("UserInputService")
local RS       = game:GetService("RunService")
local TS       = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Http     = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local MPS      = game:GetService("MarketplaceService")
local LP       = Players.LocalPlayer

-- helpers
local function best_parent()
    if gethui then local ok,g = pcall(gethui); if ok and g then return g end end
    local okCore, core = pcall(function() return game:GetService("CoreGui") end)
    return okCore and core or LP:WaitForChild("PlayerGui")
end
local function safe_parent(gui)
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
    gui.Parent = best_parent()
end
local function tween(o,t,props) return TS:Create(o, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props) end
local function disconnect(c) if c then pcall(function() c:Disconnect() end) end
local function disconnectAll(tab) for i=#tab,1,-1 do disconnect(tab[i]); tab[i]=nil end end
local function getChar() return LP.Character or LP.CharacterAdded:Wait() end
local function getHum()  return (getChar()):WaitForChild("Humanoid") end

-- splash 7s
local function showSplash7s(onClose)
    local blur = Instance.new("BlurEffect"); blur.Size = 0; blur.Name = "PH_BLUR_ASCII"; blur.Parent = Lighting
    tween(blur,.20,{Size=18}):Play()

    local G = Instance.new("ScreenGui"); G.Name="PH_SPLASH_ASCII"; safe_parent(G)

    local bg = Instance.new("Frame"); bg.BackgroundColor3=Color3.new(0,0,0); bg.BackgroundTransparency = .35; bg.Size=UDim2.fromScale(1,1); bg.Parent=G

    local box = Instance.new("Frame"); box.Size=UDim2.fromOffset(520,10); box.AnchorPoint=Vector2.new(.5,.5)
    box.Position=UDim2.fromScale(.5,.5); box.BackgroundColor3=Color3.fromRGB(24,26,32); box.Parent=G
    Instance.new("UICorner",box).CornerRadius=UDim.new(0,16); box.ClipsDescendants=true

    local title = Instance.new("TextLabel"); title.BackgroundTransparency=1; title.Font=Enum.Font.GothamBlack
    title.TextSize=22; title.TextColor3=Color3.fromRGB(235,238,255); title.TextXAlignment=Enum.TextXAlignment.Left
    title.Text="Bienvenue, "..(LP.DisplayName or LP.Name); title.Position=UDim2.fromOffset(24,78); title.Size=UDim2.fromOffset(470,28); title.Parent=box

    local gname="this game"; pcall(function() gname = MPS:GetProductInfo(game.PlaceId).Name end)
    local sub = Instance.new("TextLabel"); sub.BackgroundTransparency=1; sub.Font=Enum.Font.Gotham
    sub.TextSize=14; sub.TextColor3=Color3.fromRGB(170,176,196); sub.TextXAlignment=Enum.TextXAlignment.Left
    sub.Text="Loading Premium Hub... Game: "..gname
    sub.Position=UDim2.fromOffset(24,110); sub.Size=UDim2.fromOffset(470,22); sub.Parent=box

    local tip = Instance.new("TextLabel"); tip.BackgroundTransparency=1; tip.Font=Enum.Font.Gotham
    tip.TextSize=13; tip.TextColor3=Color3.fromRGB(170,176,196); tip.TextXAlignment=Enum.TextXAlignment.Left
    tip.Text='Tip: toggle UI with "$" (Shift+4) or F2 or Insert or RightCtrl'
    tip.Position=UDim2.fromOffset(24,138); tip.Size=UDim2.fromOffset(470,22); tip.Parent=box

    local spinner = Instance.new("ImageLabel"); spinner.BackgroundTransparency=1; spinner.Image="rbxassetid://1095708"
    spinner.ImageColor3=Color3.fromRGB(120,170,255); spinner.AnchorPoint=Vector2.new(1,1); spinner.Position=UDim2.new(1,-18,1,-16)
    spinner.Size=UDim2.fromOffset(28,28); spinner.Parent=box

    tween(box,.22,{Size=UDim2.fromOffset(520,240)}):Play()

    local rot=0; local rconn=RS.RenderStepped:Connect(function(dt) rot=(rot+dt*360)%360; spinner.Rotation=rot end)
    task.delay(7,function()
        tween(box,.18,{Size=UDim2.fromOffset(520,10)}):Play()
        tween(bg,.18,{BackgroundTransparency=1}):Play()
        task.delay(.20,function()
            pcall(function() rconn:Disconnect() end)
            tween(blur,.18,{Size=0}):Play()
            task.delay(.20,function() pcall(function() blur:Destroy() end) end)
            pcall(function() G:Destroy() end)
            if onClose then onClose() end
        end)
    end)
end

-- main hub
local function StartHub()
    if _G.__PH_ASCII_RUNNING then return end
    _G.__PH_ASCII_RUNNING = true

    -- storage
    local FS = { ok = (writefile and readfile and isfile and makefolder) and true or false }
    FS.dir  = "PremiumHub_ASCII"
    FS.file = ("%s/settings_%d.json"):format(FS.dir, game.PlaceId)
    local function saveTable(t)
        local ok, data = pcall(function() return Http:JSONEncode(t) end)
        if not ok then return end
        if FS.ok then
            pcall(function() if not isfolder(FS.dir) then makefolder(FS.dir) end end)
            pcall(function() writefile(FS.file, data) end)
        else
            shared.__PH_ASCII_SAVE = data
        end
    end
    local function loadTable()
        local raw
        if FS.ok and isfile(FS.file) then raw = pcall(function() return readfile(FS.file) end) and readfile(FS.file) or nil
        else raw = shared.__PH_ASCII_SAVE end
        if raw then local ok,tab=pcall(function() return Http:JSONDecode(raw) end); if ok and type(tab)=="table" then return tab end end
        return {}
    end

    local S = {
        -- UI
        uiVisible=true, scale=1.0, opacity=1.0, hudOn=true, windowPos=nil,

        -- hotkeys
        key_UI={"Shift","4"}, key_Panic={"RightAlt"}, key_ESP={"F3"}, key_Fly={"F4"}, key_Clip={"F5"},

        -- Speed
        speedOn=false, speed=22, minSpeed=16, maxSpeed=120, speedCon={hb=nil,prop=nil}, humanoid=nil, normalSpeed=nil,

        -- Fly
        flyOn=false, flyConns={}, flyAlive=false, flyData=nil,

        -- Light
        lightOn=false, lightBackup=nil,

        -- ESP
        espOn=false, espConn=nil, espHz=12, espShowUsername=true, espMaxDist=6000,

        -- Hitbox
        hitboxOn=false, hitboxSize=10, hitboxConn=nil, hitboxOrig={},

        -- TP
        tpSelectedUserId=nil, tpSelectedLabel=nil,

        -- NoClip
        noclipOn=false, noclipStep=nil, noclipDesc=nil, noclipOriginal={},

        -- Infinite Jump
        ijOn=false, ijBoost=55, ijConn=nil,
    }
    do local loaded=loadTable(); for k,v in pairs(loaded) do if S[k]~=nil then S[k]=v end end end

    -- UI roots
    local UI  = Instance.new("ScreenGui"); UI.Name="PremiumHubV6_ASCII"; safe_parent(UI); UI.Enabled=false
    local HUD = Instance.new("ScreenGui"); HUD.Name="PremiumHUD_ASCII"; safe_parent(HUD); HUD.Enabled=S.hudOn

    local ALPHA={} local function regA(n) table.insert(ALPHA, n) end
    local function applyOpacity() for _,f in ipairs(ALPHA) do pcall(function() f.BackgroundTransparency = 1 - S.opacity end) end end

    local Main = Instance.new("Frame")
    Main.Size=UDim2.fromOffset(680,760)
    Main.BackgroundColor3=Color3.fromRGB(18,18,22)
    Main.BorderSizePixel=0
    Main.Active=true
    Main.Parent=UI
    do local vs=workspace.CurrentCamera.ViewportSize
        local px=S.windowPos and S.windowPos.x or math.floor(vs.X/2 - Main.Size.X.Offset/2)
        local py=S.windowPos and S.windowPos.y or math.floor(vs.Y/2 - Main.Size.Y.Offset/2)
        Main.Position=UDim2.fromOffset(px,py)
    end
    Instance.new("UICorner",Main).CornerRadius=UDim.new(0,18); regA(Main)
    local sc=Instance.new("UIScale",Main); sc.Scale=S.scale

    local Header=Instance.new("Frame"); Header.Size=UDim2.new(1,0,0,56); Header.BackgroundColor3=Color3.fromRGB(28,30,36); Header.BorderSizePixel=0; Header.Active=true; Header.Parent=Main
    Instance.new("UICorner",Header).CornerRadius=UDim.new(0,18); regA(Header)
    local Title=Instance.new("TextLabel"); Title.BackgroundTransparency=1; Title.Position=UDim2.fromOffset(16,8); Title.Size=UDim2.fromOffset(420,40)
    Title.Font=Enum.Font.GothamBlack; Title.TextSize=22; Title.TextXAlignment=Enum.TextXAlignment.Left; Title.TextColor3=Color3.fromRGB(235,238,255)
    Title.Text="Premium Hub v6 ASCII - VIP"; Title.Parent=Header
    local Hint=Instance.new("TextLabel"); Hint.BackgroundTransparency=1; Hint.AnchorPoint=Vector2.new(1,0); Hint.Position=UDim2.new(1,-56,0,18)
    Hint.Size=UDim2.fromOffset(360,24); Hint.Font=Enum.Font.Gotham; Hint.TextSize=14; Hint.TextXAlignment=Enum.TextXAlignment.Right; Hint.TextColor3=Color3.fromRGB(170,176,196)
    Hint.Text='Hide: "$"(Shift+4) / F2 / Insert / RightCtrl'; Hint.Parent=Header
    local HideBtn=Instance.new("TextButton"); HideBtn.AnchorPoint=Vector2.new(1,0); HideBtn.Position=UDim2.new(1,-12,0,10); HideBtn.Size=UDim2.fromOffset(36,36)
    HideBtn.Text="X"; HideBtn.TextSize=16; HideBtn.Font=Enum.Font.GothamBold; HideBtn.TextColor3=Color3.fromRGB(235,238,255); HideBtn.AutoButtonColor=false
    HideBtn.BackgroundColor3=Color3.fromRGB(60,60,70); HideBtn.Parent=Header; Instance.new("UICorner",HideBtn).CornerRadius=UDim.new(1,0); regA(HideBtn)

    local Quick=Instance.new("Frame"); Quick.BackgroundColor3=Color3.fromRGB(28,30,36); Quick.BorderSizePixel=0; Quick.Size=UDim2.new(1,-32,0,42)
    Quick.Position=UDim2.fromOffset(16,62); Quick.Parent=Main; Instance.new("UICorner",Quick).CornerRadius=UDim.new(0,12); regA(Quick)
    local qList=Instance.new("UIListLayout",Quick); qList.FillDirection=Enum.FillDirection.Horizontal; qList.Padding=UDim.new(0,8); qList.VerticalAlignment=Enum.VerticalAlignment.Center
    local function quick(txt,w,cb)
        local b=Instance.new("TextButton"); b.Size=UDim2.fromOffset(w,28); b.Text=txt; b.Font=Enum.Font.GothamSemibold; b.TextSize=14; b.TextColor3=Color3.fromRGB(235,238,255)
        b.BackgroundColor3=Color3.fromRGB(60,60,70); b.AutoButtonColor=false; b.Parent=Quick; Instance.new("UICorner",b).CornerRadius=UDim.new(0,8); regA(b)
        b.MouseEnter:Connect(function() tween(b,.12,{BackgroundColor3=Color3.fromRGB(80,110,240)}):Play() end)
        b.MouseLeave:Connect(function() tween(b,.12,{BackgroundColor3=Color3.fromRGB(60,60,70)}):Play() end)
        b.MouseButton1Click:Connect(cb)
    end

    local Content=Instance.new("ScrollingFrame"); Content.Position=UDim2.fromOffset(16,110); Content.Size=UDim2.new(1,-32,1,-126)
    Content.CanvasSize=UDim2.new(0,0,0,0); Content.ScrollBarThickness=6; Content.BackgroundTransparency=1; Content.Parent=Main
    local VList=Instance.new("UIListLayout",Content); VList.Padding=UDim.new(0,12); VList.SortOrder=Enum.SortOrder.LayoutOrder
    local function refreshCanvas() Content.CanvasSize=UDim2.new(0,0,0,VList.AbsoluteContentSize.Y+8) end
    VList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(refreshCanvas)

    local HudFrame=Instance.new("Frame"); HudFrame.Size=UDim2.fromOffset(240,26); HudFrame.Position=UDim2.fromOffset(12,12)
    HudFrame.BackgroundColor3=Color3.fromRGB(28,30,36); HudFrame.Parent=HUD; Instance.new("UICorner",HudFrame).CornerRadius=UDim.new(0,8); regA(HudFrame)
    local HudText=Instance.new("TextLabel"); HudText.BackgroundTransparency=1; HudText.Font=Enum.Font.GothamSemibold; HudText.TextSize=14; HudText.TextXAlignment=Enum.TextXAlignment.Left; HudText.TextColor3=Color3.fromRGB(235,238,255)
    HudText.Text="Speed:off  Fly:off  ESP:off  Clip:off"; HudText.Size=UDim2.new(1,-10,1,0); HudText.Position=UDim2.fromOffset(8,0); HudText.Parent=HudFrame
    local function refreshHUD() HudText.Text=string.format("Speed:%s  Fly:%s  ESP:%s  Clip:%s", S.speedOn and "on" or "off", S.flyOn and "on" or "off", S.espOn and "on" or "off", S.noclipOn and "on" or "off") end
    refreshHUD()

    -- UI building helpers
    local function section(title,subtitle)
        local Card=Instance.new("Frame"); Card.Size=UDim2.new(1,0,0,0); Card.AutomaticSize=Enum.AutomaticSize.Y; Card.BackgroundColor3=Color3.fromRGB(22,24,29); Card.BorderSizePixel=0; Card.Active=true; Card.Parent=Content
        Instance.new("UICorner",Card).CornerRadius=UDim.new(0,14); regA(Card)
        local Top=Instance.new("Frame"); Top.BackgroundColor3=Color3.fromRGB(28,30,36); Top.BorderSizePixel=0; Top.Size=UDim2.new(1,0,0,46); Top.Parent=Card
        Instance.new("UICorner",Top).CornerRadius=UDim.new(0,14); regA(Top)
        local T=Instance.new("TextLabel"); T.BackgroundTransparency=1; T.Font=Enum.Font.GothamSemibold; T.TextSize=16; T.TextXAlignment=Enum.TextXAlignment.Left
        T.TextColor3=Color3.fromRGB(235,238,255); T.Text=title; T.Position=UDim2.fromOffset(12,8); T.Size=UDim2.fromOffset(440,20); T.Parent=Top
        local ST=Instance.new("TextLabel"); ST.BackgroundTransparency=1; ST.Font=Enum.Font.Gotham; ST.TextSize=13; ST.TextXAlignment=Enum.TextXAlignment.Left
        ST.TextColor3=Color3.fromRGB(170,176,196); ST.Text=subtitle or ""; ST.Position=UDim2.fromOffset(12,24); ST.Size=UDim2.fromOffset(560,18); ST.Parent=Top
        local Body=Instance.new("Frame"); Body.BackgroundTransparency=1; Body.Position=UDim2.fromOffset(0,46); Body.Size=UDim2.new(1,0,0,0); Body.AutomaticSize=Enum.AutomaticSize.Y; Body.Parent=Card
        local Pad=Instance.new("UIPadding",Body); Pad.PaddingLeft=UDim.new(0,12); Pad.PaddingRight=UDim.new(0,12); Pad.PaddingTop=UDim.new(0,10); Pad.PaddingBottom=UDim.new(0,12)
        return Card,Body
    end
    local function toggle(parent,label,default)
        local Row=Instance.new("Frame"); Row.BackgroundTransparency=1; Row.Size=UDim2.new(1,0,0,34); Row.Parent=parent
        local L=Instance.new("TextLabel"); L.BackgroundTransparency=1; L.Font=Enum.Font.Gotham; L.TextSize=14; L.TextXAlignment=Enum.TextXAlignment.Left; L.TextColor3=Color3.fromRGB(235,238,255); L.Text=label; L.Position=UDim2.fromOffset(0,8); L.Size=UDim2.fromOffset(360,18); L.Parent=Row
        local Btn=Instance.new("TextButton"); Btn.AutoButtonColor=false; Btn.AnchorPoint=Vector2.new(1,0); Btn.Position=UDim2.new(1,-2,0,4)
        Btn.Size=UDim2.fromOffset(74,26); Btn.BackgroundColor3= default and Color3.fromRGB(58,116,255) or Color3.fromRGB(60,60,70); Btn.Text=""; Btn.Parent=Row; Instance.new("UICorner",Btn).CornerRadius=UDim.new(1,0); regA(Btn)
        local Knob=Instance.new("Frame"); Knob.Size=UDim2.fromOffset(24,24); Knob.Position= default and UDim2.fromOffset(48,1) or UDim2.fromOffset(2,1); Knob.BackgroundColor3=Color3.fromRGB(28,30,36); Knob.Parent=Btn; Instance.new("UICorner",Knob).CornerRadius=UDim.new(1,0); regA(Knob)
        local function setOn(on) tween(Btn,.16,{BackgroundColor3= on and Color3.fromRGB(58,116,255) or Color3.fromRGB(60,60,70)}):Play(); tween(Knob,.16,{Position= on and UDim2.fromOffset(48,1) or UDim2.fromOffset(2,1)}):Play() end
        return setOn, Btn
    end
    local function slider(parent,label,minV,maxV,defaultV,fmt)
        local Row=Instance.new("Frame"); Row.BackgroundTransparency=1; Row.Size=UDim2.new(1,0,0,58); Row.Parent=parent
        local T=Instance.new("TextLabel"); T.BackgroundTransparency=1; T.Font=Enum.Font.Gotham; T.TextSize=14; T.TextXAlignment=Enum.TextXAlignment.Left; T.TextColor3=Color3.fromRGB(235,238,255)
        local function format(v) return fmt and fmt(v) or tostring(v) end
        T.Text=string.format("%s: %s",label,format(defaultV)); T.Position=UDim2.fromOffset(0,2); T.Size=UDim2.fromOffset(380,18); T.Parent=Row
        local Track=Instance.new("Frame"); Track.BackgroundColor3=Color3.fromRGB(46,50,65); Track.BorderSizePixel=0; Track.Position=UDim2.fromOffset(0,28); Track.Size=UDim2.new(1,-2,0,10); Track.Parent=Row; Instance.new("UICorner",Track).CornerRadius=UDim.new(0,6); regA(Track)
        local Fill=Instance.new("Frame"); Fill.BackgroundColor3=Color3.fromRGB(58,116,255); Fill.BorderSizePixel=0; Fill.Size=UDim2.fromOffset(0,10); Fill.Parent=Track; Instance.new("UICorner",Fill).CornerRadius=UDim.new(0,6)
        local Knob=Instance.new("Frame"); Knob.Size=UDim2.fromOffset(16,16); Knob.Position=UDim2.fromOffset(-8,-3); Knob.BackgroundColor3=Color3.fromRGB(28,30,36); Knob.Parent=Fill; Instance.new("UICorner",Knob).CornerRadius=UDim.new(1,0); regA(Knob)
        local dragging=false; local current=defaultV
        local function setFromX(px)
            local abs=Track.AbsoluteSize.X; local rel=math.clamp(px/abs,0,1)
            local val=math.floor(minV + (maxV-minV)*rel + .5)
            local w=math.floor(abs*rel + .5)
            Fill.Size=UDim2.fromOffset(w,10); Knob.Position=UDim2.fromOffset(w-8,-3)
            T.Text=string.format("%s: %s",label,format(val))
            current=val
        end
        RS.Heartbeat:Wait(); local rel=(defaultV-minV)/(maxV-minV); setFromX(Track.AbsoluteSize.X*rel)
        Track.InputBegan:Connect(function(io) if io.UserInputType==Enum.UserInputType.MouseButton1 or io.UserInputType==Enum.UserInputType.Touch then dragging=true; setFromX(io.Position.X-Track.AbsolutePosition.X) end end)
        UIS.InputChanged:Connect(function(io) if dragging and (io.UserInputType==Enum.UserInputType.MouseMovement or io.UserInputType==Enum.UserInputType.Touch) then setFromX(io.Position.X-Track.AbsolutePosition.X) end end)
        UIS.InputEnded:Connect(function(io) if io.UserInputType==Enum.UserInputType.MouseButton1 or io.UserInputType==Enum.UserInputType.Touch then dragging=false end end)
        return function() return current end
    end

    -- SPEED
    local function speed_enable()
        S.humanoid = getHum()
        S.normalSpeed = S.humanoid.WalkSpeed
        disconnect(S.speedCon.hb); disconnect(S.speedCon.prop)
        S.speedCon.hb = RS.Heartbeat:Connect(function()
            if S.speedOn and S.humanoid and S.humanoid.Parent and S.humanoid.WalkSpeed ~= S.speed then
                S.humanoid.WalkSpeed = S.speed
            end
        end)
        S.speedCon.prop = S.humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
            if S.speedOn and S.humanoid.WalkSpeed ~= S.speed then S.humanoid.WalkSpeed = S.speed end
        end)
    end
    local function speed_disable()
        disconnect(S.speedCon.hb); S.speedCon.hb=nil
        disconnect(S.speedCon.prop); S.speedCon.prop=nil
        local h = S.humanoid or (getChar():FindFirstChildOfClass("Humanoid"))
        if h then h.WalkSpeed = S.normalSpeed or 16 end
    end
    LP.CharacterAdded:Connect(function() if S.speedOn then task.wait(.3); speed_enable() end end)

    -- FLY
    local function fly_disable()
        S.flyAlive=false; disconnectAll(S.flyConns)
        if not S.flyData then return end
        local hrp=S.flyData.hrp; local hum=S.flyData.humanoid; local Controls=S.flyData.Controls; local collMap=S.flyData.collMap
        pcall(function() if S.flyData.lv then S.flyData.lv.Enabled=false; S.flyData.lv:Destroy() end end)
        pcall(function() if S.flyData.att then S.flyData.att:Destroy() end end)
        if collMap then for part,can in pairs(collMap) do if part and part.Parent then part.CanCollide=can end end end
        if hrp then hrp.AssemblyLinearVelocity=Vector3.zero; hrp.AssemblyAngularVelocity=Vector3.zero; hrp.CFrame=hrp.CFrame + Vector3.new(0,0.05,0) end
        if Controls then pcall(function() Controls:Enable() end) end
        if hum then
            hum.AutoRotate=true; hum.PlatformStand=false; hum.Sit=false
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
            task.delay(0.05,function() if hum and hum.Parent then pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end) end end)
        end
        S.flyData=nil
    end
    local function fly_enable()
        fly_disable()
        local char=getChar(); local hrp=char:WaitForChild("HumanoidRootPart"); local hum=char:WaitForChild("Humanoid")
        S.flyAlive=true
        local Controls=nil
        pcall(function() local ps=LP:WaitForChild("PlayerScripts"); local ok,PlayerModule=pcall(function() return require(ps:WaitForChild("PlayerModule")) end); if ok and PlayerModule then Controls=PlayerModule:GetControls(); if Controls then Controls:Disable() end end end)
        hum.AutoRotate=false; hum:ChangeState(Enum.HumanoidStateType.Physics); hum.PlatformStand=true
        local collMap={}; for _,d in ipairs(char:GetDescendants()) do if d:IsA("BasePart") then collMap[d]=d.CanCollide; d.CanCollide=false end end
        table.insert(S.flyConns, char.DescendantAdded:Connect(function(d) if d:IsA("BasePart") then collMap[d]=d.CanCollide; d.CanCollide=false end end))
        local att=Instance.new("Attachment"); att.Parent=hrp
        local lv=Instance.new("LinearVelocity"); lv.Attachment0=att; lv.MaxForce=math.huge; lv.RelativeTo=Enum.ActuatorRelativeTo.World; lv.Parent=hrp
        S.flyData={hrp=hrp,humanoid=hum,lv=lv,att=att,Controls=Controls,collMap=collMap}
        table.insert(S.flyConns, hum:GetPropertyChangedSignal("PlatformStand"):Connect(function() if S.flyAlive and hum.PlatformStand~=true then hum.PlatformStand=true end end))
        table.insert(S.flyConns, RS.Stepped:Connect(function() if S.flyAlive then hrp.AssemblyAngularVelocity=Vector3.zero end end))
        table.insert(S.flyConns, RS.RenderStepped:Connect(function()
            if not S.flyAlive then return end
            local cam=workspace.CurrentCamera; if not cam then return end
            local look=cam.CFrame.LookVector
            local yawDir=Vector3.new(look.X,0,look.Z); if yawDir.Magnitude<1e-3 then yawDir=Vector3.zAxis else yawDir=yawDir.Unit end
            hrp.CFrame=CFrame.lookAt(hrp.Position, hrp.Position+yawDir, Vector3.yAxis)
            local rightDir=Vector3.new(cam.CFrame.RightVector.X,0,cam.CFrame.RightVector.Z); rightDir=(rightDir.Magnitude>0) and rightDir.Unit or Vector3.new(-yawDir.Z,0,yawDir.X)
            local fwd,right=0,0
            if UIS:IsKeyDown(Enum.KeyCode.W) then fwd += 1 end
            if UIS:IsKeyDown(Enum.KeyCode.S) then fwd -= 1 end
            if UIS:IsKeyDown(Enum.KeyCode.D) then right += 1 end
            if UIS:IsKeyDown(Enum.KeyCode.A) then right -= 1 end
            local SPEED,VERTICAL,PITCH_DEADZONE=65,45,0.08
            local horiz=yawDir*fwd + rightDir*right; if horiz.Magnitude>0 then horiz=horiz.Unit*SPEED else horiz=Vector3.zero end
            local vertical=0; if fwd~=0 then local pitch=look.Y; if math.abs(pitch)>PITCH_DEADZONE then vertical=pitch*VERTICAL*fwd end end
            lv.VectorVelocity=Vector3.new(horiz.X,vertical,horiz.Z)
        end))
        table.insert(S.flyConns, hum.Died:Connect(fly_disable))
    end

    -- LIGHT
    local LIGHT_PRESET={GlobalShadows=false, FogEnd=100000, Brightness=2, Ambient=Color3.fromRGB(150,150,150)}
    local function light_enable() if not S.lightBackup then S.lightBackup={GlobalShadows=Lighting.GlobalShadows, FogEnd=Lighting.FogEnd, Brightness=Lighting.Brightness, Ambient=Lighting.Ambient} end
        Lighting.GlobalShadows=LIGHT_PRESET.GlobalShadows; Lighting.FogEnd=LIGHT_PRESET.FogEnd; Lighting.Brightness=LIGHT_PRESET.Brightness; Lighting.Ambient=LIGHT_PRESET.Ambient end
    local function light_disable() if S.lightBackup then Lighting.GlobalShadows=S.lightBackup.GlobalShadows; Lighting.FogEnd=S.lightBackup.FogEnd; Lighting.Brightness=S.lightBackup.Brightness; Lighting.Ambient=S.lightBackup.Ambient end end

    -- ESP
    local ROLE_COLORS={Murder=Color3.fromRGB(255,60,60),Murderer=Color3.fromRGB(255,60,60),Innocent=Color3.fromRGB(64,128,255),Sheriff=Color3.fromRGB(255,220,0),Detective=Color3.fromRGB(255,220,0)}
    local DEFAULT_COLOR=Color3.fromRGB(200,200,200)
    local function getRole(p,char) local r=p:GetAttribute("Role"); if r==nil and char then r=char:GetAttribute("Role") end; return (typeof(r)=="string") and r or nil end
    local function colorFor(p,char) local role=getRole(p,char); if role and ROLE_COLORS[role] then return ROLE_COLORS[role] end; if p.Team and p.Team.TeamColor then return p.Team.TeamColor.Color end; return DEFAULT_COLOR end
    local function headOrPart(char) return char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildWhichIsA("BasePart") end
    local function sameColor(a,b) return a and b and a.r==b.r and a.g==b.g and a.b==b.b end
    local ESP_REG={}
    local function buildESPFor(p,char)
        if not char or p==LP then return end
        local reg=ESP_REG[p]; if not reg then reg={conns={}}; ESP_REG[p]=reg else disconnectAll(reg.conns) end
        reg.char=char
        local hl=char:FindFirstChild("ESP_Highlight"); if not hl then hl=Instance.new("Highlight"); hl.Name="ESP_Highlight"; hl.FillTransparency=1; hl.OutlineTransparency=0; hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; hl.Parent=char end
        reg.hl=hl
        local box=char:FindFirstChild("ESP_Box"); if not box then box=Instance.new("SelectionBox"); box.Name="ESP_Box"; box.LineThickness=0.02; box.SurfaceTransparency=1; pcall(function() box.Adornee=char end); box.Parent=char end
        reg.box=box
        for _,d in ipairs(char:GetDescendants()) do if d:IsA("BillboardGui") and d.Name=="ESP_BBG" then d:Destroy() end end
        local bb=Instance.new("BillboardGui"); bb.Name="ESP_BBG"; bb.Size=UDim2.new(0,220,0,44); bb.StudsOffset=Vector3.new(0,3,0); bb.AlwaysOnTop=true; bb.MaxDistance=5000
        local head=headOrPart(char); bb.Parent=(head and head:IsA("BasePart")) and head or (char:FindFirstChild("HumanoidRootPart") or char)
        local nameLbl=Instance.new("TextLabel"); nameLbl.Name="Name"; nameLbl.BackgroundTransparency=1; nameLbl.Size=UDim2.new(1,0,0.5,0); nameLbl.Font=Enum.Font.GothamBold; nameLbl.TextScaled=true; nameLbl.TextStrokeTransparency=.5; nameLbl.Parent=bb
        local distLbl=Instance.new("TextLabel"); distLbl.Name="Dist"; distLbl.BackgroundTransparency=1; distLbl.Position=UDim2.new(0,0,0.5,0); distLbl.Size=UDim2.new(1,0,0.5,0); distLbl.Font=Enum.Font.Gotham; distLbl.TextScaled=true; distLbl.TextStrokeTransparency=.5; distLbl.Parent=bb
        reg.bb,reg.nameLbl,reg.distLbl=bb,nameLbl,distLbl; reg.lastName=""; reg.lastDist=-1; reg.lastColor=nil
        table.insert(reg.conns, char.DescendantAdded:Connect(function(d) if d.Name=="Head" and d:IsA("BasePart") and reg.bb and reg.bb.Parent~=d then reg.bb.Parent=d end end))
        table.insert(reg.conns, char.AncestryChanged:Connect(function(_,parent) if parent==nil then disconnectAll(reg.conns) end end))
    end
    local function ensureESPFor(p) local char=p.Character; if not char then return end; local reg=ESP_REG[p]; if not reg or reg.char~=char or not reg.bb or not reg.hl or not reg.box then buildESPFor(p,char) end end
    local function esp_tick()
        local myC=LP.Character; if not myC then return end
        local myHRP=myC:FindFirstChild("HumanoidRootPart"); if not myHRP then return end
        for _,p in ipairs(Players:GetPlayers()) do
            if p~=LP then
                ensureESPFor(p)
                local reg=ESP_REG[p]; local char=p.Character
                if reg and char and reg.bb and reg.hl and reg.box then
                    local tHRP=char:FindFirstChild("HumanoidRootPart")
                    if not tHRP then reg.bb.Enabled=false; reg.hl.Enabled=false; reg.box.Visible=false
                    else
                        local dist=(myHRP.Position - tHRP.Position).Magnitude
                        if dist > S.espMaxDist then reg.bb.Enabled=false; reg.hl.Enabled=false; reg.box.Visible=false
                        else
                            local col=colorFor(p,char)
                            if not sameColor(reg.lastColor,col) then reg.lastColor=col; reg.hl.OutlineColor=col; pcall(function() reg.box.LineColor3=col end); reg.nameLbl.TextColor3=col; reg.distLbl.TextColor3=col end
                            local display=(p.DisplayName and p.DisplayName~="") and p.DisplayName or p.Name
                            local wantName=S.espShowUsername and (display.." (@"..p.Name..")") or display
                            if reg.lastName~=wantName then reg.nameLbl.Text=wantName; reg.lastName=wantName end
                            local di=(dist>=0) and math.floor(dist+0.5) or 0
                            if reg.lastDist~=di then reg.distLbl.Text=tostring(di).." studs"; reg.lastDist=di end
                            reg.bb.Enabled=true; reg.hl.Enabled=true; reg.box.Visible=true
                            if reg.bb.Parent==reg.char or (not reg.bb.Parent) or (not reg.bb.Parent.Parent) then local h=headOrPart(char); if h then reg.bb.Parent=h end end
                        end
                    end
                end
            end
        end
    end
    local function esp_enable()
        if S.espConn then return end
        for _,pl in ipairs(Players:GetPlayers()) do if pl~=LP and pl.Character then buildESPFor(pl, pl.Character) end end
        local acc=0; S.espConn=RS.Heartbeat:Connect(function(dt) acc+=dt; if acc>=(1/math.max(1,S.espHz)) then esp_tick(); acc=0 end end)
        Players.PlayerAdded:Connect(function(p) p.CharacterAdded:Connect(function(c) task.wait(0.2); buildESPFor(p,c) end); if p.Character then buildESPFor(p,p.Character) end end)
    end
    local function esp_disable() disconnect(S.espConn); S.espConn=nil; for _,reg in pairs(ESP_REG) do if reg.bb then reg.bb.Enabled=false end; if reg.hl then reg.hl.Enabled=false end; if reg.box then reg.box.Visible=false end end end

    -- HITBOX
    local function rememberHRP(hrp) if not hrp or S.hitboxOrig[hrp] then return end S.hitboxOrig[hrp]={Size=hrp.Size,Transparency=hrp.Transparency,Material=hrp.Material,CanCollide=hrp.CanCollide,BrickColor=hrp.BrickColor} end
    local function applyHitboxTo(hrp) if not hrp then return end rememberHRP(hrp); hrp.Size=Vector3.new(S.hitboxSize,S.hitboxSize,S.hitboxSize); hrp.Transparency=.7; hrp.BrickColor=BrickColor.new("Really red"); hrp.Material=Enum.Material.Neon; hrp.CanCollide=false end
    local function restoreAllHitbox() for hrp,orig in pairs(S.hitboxOrig) do if hrp and hrp.Parent and orig then pcall(function() hrp.Size=orig.Size; hrp.Transparency=orig.Transparency; hrp.Material=orig.Material; hrp.CanCollide=orig.CanCollide; hrp.BrickColor=orig.BrickColor end) end end S.hitboxOrig={} end
    local function hitbox_loop() for _,pl in ipairs(Players:GetPlayers()) do if pl~=LP and pl.Character then local hrp=pl.Character:FindFirstChild("HumanoidRootPart"); if hrp then pcall(applyHitboxTo, hrp) end end end end
    local function hitbox_enable() if S.hitboxConn then return end; hitbox_loop(); S.hitboxConn=RS.RenderStepped:Connect(function() if S.hitboxOn then hitbox_loop() end end); Players.PlayerAdded:Connect(function(p) p.CharacterAdded:Connect(function(c) task.wait(.1); local hrp=c:FindFirstChild("HumanoidRootPart"); if hrp then rememberHRP(hrp) end end) end) end
    local function hitbox_disable() disconnect(S.hitboxConn); S.hitboxConn=nil; restoreAllHitbox() end

    -- NOCLIP
    local function noclip_cachePart(inst) if inst:IsA("BasePart") and S.noclipOriginal[inst]==nil then S.noclipOriginal[inst]=inst.CanCollide end end
    local function noclip_cacheChar(char) for _,d in ipairs(char:GetDescendants()) do noclip_cachePart(d) end; disconnect(S.noclipDesc); S.noclipDesc=char.DescendantAdded:Connect(noclip_cachePart) end
    local function noclip_apply(char) for part,_ in pairs(S.noclipOriginal) do if part.Parent and part:IsDescendantOf(char) then part.CanCollide=false end end end
    local function noclip_enable() local char=getChar(); S.noclipOriginal={}; noclip_cacheChar(char); disconnect(S.noclipStep); S.noclipStep=RS.Stepped:Connect(function() noclip_apply(char) end) end
    local function noclip_disable() disconnect(S.noclipStep); S.noclipStep=nil; disconnect(S.noclipDesc); S.noclipDesc=nil; for part,can in pairs(S.noclipOriginal) do if part and part.Parent then part.CanCollide=can end end; S.noclipOriginal={} end
    LP.CharacterAdded:Connect(function(c) if S.noclipOn then noclip_enable() end end)

    -- INFINITE JUMP
    local function ij_bind(char)
        local hum=char:WaitForChild("Humanoid"); local root=char:WaitForChild("HumanoidRootPart")
        hum.UseJumpPower=true
        if S.ijConn then S.ijConn:Disconnect() end
        S.ijConn=UIS.JumpRequest:Connect(function()
            if not S.ijOn then return end
            if hum.Health<=0 or hum:GetState()==Enum.HumanoidStateType.Dead then return end
            local v=root.AssemblyLinearVelocity
            root.AssemblyLinearVelocity=Vector3.new(v.X, math.max(S.ijBoost,0), v.Z)
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end)
    end
    if LP.Character then ij_bind(LP.Character) end
    LP.CharacterAdded:Connect(function(c) if S.ijOn then ij_bind(c) end end)

    -- TP
    local function getHRPFromChar(char) return char and char:FindFirstChild("HumanoidRootPart") end
    local function tpToPlayerId(userId) local me=LP; local target=Players:GetPlayerByUserId(userId); if not (me and me.Character and target and target.Character) then return end; local myHRP=getHRPFromChar(me.Character); local targetHRP=getHRPFromChar(target.Character); if not (myHRP and targetHRP) then return end; me.Character:PivotTo(targetHRP.CFrame * CFrame.new(0,0,3)) end
    local function listOthers() local arr={}; for _,p in ipairs(Players:GetPlayers()) do if p~=LP then table.insert(arr,p) end end; table.sort(arr,function(a,b) local ad=(a.DisplayName~="" and a.DisplayName) or a.Name; local bd=(b.DisplayName~="" and b.DisplayName) or b.Name; return string.lower(ad) < string.lower(bd) end); return arr end

    -- Sections
    local function bindUI(parent,label,keys,apply)
        local Row=Instance.new("Frame"); Row.BackgroundTransparency=1; Row.Size=UDim2.new(1,0,0,38); Row.Parent=parent
        local Lb=Instance.new("TextLabel"); Lb.BackgroundTransparency=1; Lb.Font=Enum.Font.Gotham; Lb.TextSize=14; Lb.TextXAlignment=Enum.TextXAlignment.Left; Lb.TextColor3=Color3.fromRGB(235,238,255); Lb.Text=label; Lb.Position=UDim2.fromOffset(0,8); Lb.Size=UDim2.fromOffset(240,18); Lb.Parent=Row
        local Btn=Instance.new("TextButton"); Btn.Size=UDim2.fromOffset(180,28); Btn.Position=UDim2.new(0,250,0,4); Btn.BackgroundColor3=Color3.fromRGB(60,60,70); Btn.AutoButtonColor=false; Btn.TextColor3=Color3.fromRGB(235,238,255); Btn.TextSize=14; Btn.Font=Enum.Font.GothamSemibold; Btn.Parent=Row; Instance.new("UICorner",Btn).CornerRadius=UDim.new(0,8); regA(Btn)
        local function show() Btn.Text="["..(type(keys)=="table" and table.concat(keys," + ") or tostring(keys)).."]" end
        show()
        local waiting=false
        Btn.MouseButton1Click:Connect(function() Btn.Text="... press key ..."; waiting=true end)
        UIS.InputBegan:Connect(function(io,gp)
            if not waiting or gp or io.UserInputType~=Enum.UserInputType.Keyboard then return end
            waiting=false
            if (UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift)) and io.KeyCode==Enum.KeyCode.Four then
                keys={"Shift","4"}
            else
                keys={io.KeyCode.Name}
            end
            apply(keys); show()
        end)
    end

    do
        local Card,Body=section("Appearance and UI","Scale, opacity, HUD, keybinds.")
        local gScale=slider(Body,"UI Scale",80,120,math.floor(S.scale*100),function(v)return v.."%" end)
        local gOp   =slider(Body,"Opacity",70,100,math.floor(S.opacity*100),function(v)return v.."%" end)
        RS.Heartbeat:Connect(function() S.scale=(gScale()/100); sc.Scale=S.scale; S.opacity=(gOp()/100); applyOpacity() end)
        local setHUD,btnHUD=toggle(Body,"Mini HUD",S.hudOn); btnHUD.MouseButton1Click:Connect(function() S.hudOn=not S.hudOn; HUD.Enabled=S.hudOn; setHUD(S.hudOn) end)
        bindUI(Body,"Toggle UI", S.key_UI,   function(k) S.key_UI=k end)
        bindUI(Body,"Panic (all off)", S.key_Panic,function(k) S.key_Panic=k end)
        bindUI(Body,"Toggle ESP", S.key_ESP, function(k) S.key_ESP=k end)
        bindUI(Body,"Toggle Fly", S.key_Fly, function(k) S.key_Fly=k end)
        bindUI(Body,"Toggle NoClip", S.key_Clip, function(k) S.key_Clip=k end)
    end

    do
        local Card,Body=section("Speed","Keep walkspeed, anti reset.")
        local setT,btn=toggle(Body,"Enable Speed",S.speedOn)
        local gV=slider(Body,"Speed value",S.minSpeed,S.maxSpeed,S.speed,function(v) return v end)
        btn.MouseButton1Click:Connect(function() S.speed=gV(); S.speedOn=not S.speedOn; setT(S.speedOn); if S.speedOn then speed_enable() else speed_disable() end; refreshHUD() end)
        RS.Heartbeat:Connect(function() S.speed=gV() end)
    end

    do
        local Card,Body=section("Fly","Smooth fly (WASD/ZQSD + camera tilt). Clean exit.")
        local setT,btn=toggle(Body,"Enable Fly",S.flyOn)
        btn.MouseButton1Click:Connect(function() S.flyOn=not S.flyOn; setT(S.flyOn); if S.flyOn then fly_enable() else fly_disable() end; refreshHUD() end)
    end

    do
        local Card,Body=section("Light","No shadows, no fog, brighter.")
        local setT,btn=toggle(Body,"Enable Light",S.lightOn)
        btn.MouseButton1Click:Connect(function() S.lightOn=not S.lightOn; setT(S.lightOn); if S.lightOn then light_enable() else light_disable() end end)
    end

    do
        local Card,Body=section("ESP Player","Aura + box + name + distance (role/team colors, live update).")
        local setT,btn=toggle(Body,"Enable ESP",S.espOn)
        local setU,ubtn=toggle(Body,"Show @username",S.espShowUsername); ubtn.MouseButton1Click:Connect(function() S.espShowUsername=not S.espShowUsername; setU(S.espShowUsername) end)
        local gHz=slider(Body,"Refresh per second",4,30,S.espHz,function(v)return v end)
        local gR =slider(Body,"Range (studs)",200,6000,S.espMaxDist,function(v)return v end)
        RS.Heartbeat:Connect(function() S.espHz=gHz(); S.espMaxDist=gR() end)
        btn.MouseButton1Click:Connect(function() S.espOn=not S.espOn; setT(S.espOn); if S.espOn then esp_enable() else esp_disable() end; refreshHUD() end)
    end

    do
        local Card,Body=section("Hitbox (HRP)","Grow other players HRP locally.")
        local setT,btn=toggle(Body,"Enable Hitbox",S.hitboxOn)
        local gSize=slider(Body,"Size",2,30,S.hitboxSize,function(v) return v end)
        RS.Heartbeat:Connect(function() S.hitboxSize=gSize() end)
        btn.MouseButton1Click:Connect(function() S.hitboxOn=not S.hitboxOn; setT(S.hitboxOn); if S.hitboxOn then hitbox_enable() else hitbox_disable() end end)
    end

    do
        local Card,Body=section("TP Player","Pick a player then click TP.")
        local row=Instance.new("Frame"); row.BackgroundTransparency=1; row.Size=UDim2.new(1,0,0,36); row.Parent=Body
        local ddBtn=Instance.new("TextButton"); ddBtn.Size=UDim2.new(1,-118,1,0); ddBtn.Text="Choose player  v"; ddBtn.Font=Enum.Font.Gotham; ddBtn.TextSize=14; ddBtn.TextColor3=Color3.fromRGB(235,238,255); ddBtn.BackgroundColor3=Color3.fromRGB(46,50,65); ddBtn.AutoButtonColor=true; ddBtn.Parent=row; Instance.new("UICorner",ddBtn).CornerRadius=UDim.new(0,8); regA(ddBtn)
        local refreshBtn=Instance.new("TextButton"); refreshBtn.Size=UDim2.new(0,110,1,0); refreshBtn.Text="Refresh"; refreshBtn.Font=Enum.Font.GothamSemibold; refreshBtn.TextSize=14; refreshBtn.TextColor3=Color3.fromRGB(235,238,255); refreshBtn.BackgroundColor3=Color3.fromRGB(58,116,255); refreshBtn.Parent=row; Instance.new("UICorner",refreshBtn).CornerRadius=UDim.new(0,8)
        local listHolder=Instance.new("ScrollingFrame"); listHolder.Size=UDim2.new(1,0,0,120); listHolder.BackgroundColor3=Color3.fromRGB(28,30,36); listHolder.BorderSizePixel=0; listHolder.ScrollBarThickness=6; listHolder.CanvasSize=UDim2.new(0,0,0,0); listHolder.Visible=false; listHolder.Parent=Body
        Instance.new("UICorner",listHolder).CornerRadius=UDim.new(0,10); regA(listHolder)
        local listLayout=Instance.new("UIListLayout",listHolder); listLayout.Padding=UDim.new(0,6)
        local pad=Instance.new("UIPadding",listHolder); pad.PaddingLeft=UDim.new(0,6); pad.PaddingRight=UDim.new(0,6); pad.PaddingTop=UDim.new(0,6); pad.PaddingBottom=UDim.new(0,6)
        local empty=Instance.new("TextLabel"); empty.Size=UDim2.new(1,-12,0,28); empty.BackgroundTransparency=1; empty.Text="No other players."; empty.Font=Enum.Font.Gotham; empty.TextSize=14; empty.TextColor3=Color3.fromRGB(170,176,196); empty.Visible=false; empty.Parent=listHolder
        local tpBtn=Instance.new("TextButton"); tpBtn.Size=UDim2.new(1,0,0,36); tpBtn.Text="TP -> (choose a player)"; tpBtn.Font=Enum.Font.GothamSemibold; tpBtn.TextSize=15; tpBtn.TextColor3=Color3.fromRGB(235,238,255); tpBtn.BackgroundColor3=Color3.fromRGB(80,80,95); tpBtn.Parent=Body; Instance.new("UICorner",tpBtn).CornerRadius=UDim.new(0,10)
        local function setTPEnabled(on) tpBtn.Active=on; tpBtn.AutoButtonColor=on; tween(tpBtn,.15,{BackgroundColor3= on and Color3.fromRGB(58,116,255) or Color3.fromRGB(80,80,95)}):Play() end
        setTPEnabled(false)
        local function clearList() for _,ch in ipairs(listHolder:GetChildren()) do if ch:IsA("TextButton") then ch:Destroy() end end; empty.Visible=false end
        local function resizeCanvas() local total=0; for _,ch in ipairs(listHolder:GetChildren()) do if ch:IsA("TextButton") then total += ch.AbsoluteSize.Y + listLayout.Padding.Offset end end; listHolder.CanvasSize=UDim2.new(0,0,0, math.max(total,0)) end
        local function rebuild()
            clearList()
            local others=listOthers()
            if #others==0 then empty.Visible=true else
                for _,p in ipairs(others) do
                    local b=Instance.new("TextButton"); b.Size=UDim2.new(1,-12,0,30); b.TextXAlignment=Enum.TextXAlignment.Left
                    b.Text=string.format("%s  (@%s)", (p.DisplayName~="" and p.DisplayName) or p.Name, p.Name)
                    b.Font=Enum.Font.Gotham; b.TextSize=14; b.TextColor3=Color3.fromRGB(235,238,255); b.BackgroundColor3=Color3.fromRGB(46,50,65); b.AutoButtonColor=true; b.Parent=listHolder
                    Instance.new("UICorner",b).CornerRadius=UDim.new(0,8); regA(b)
                    b.MouseButton1Click:Connect(function() S.tpSelectedUserId=p.UserId; S.tpSelectedLabel=(p.DisplayName~="" and p.DisplayName) or p.Name; ddBtn.Text="Target: "..S.tpSelectedLabel.."  v"; tpBtn.Text="TP -> "..S.tpSelectedLabel; setTPEnabled(true); listHolder.Visible=false end)
                end
            end
            resizeCanvas()
            if S.tpSelectedUserId and not Players:GetPlayerByUserId(S.tpSelectedUserId) then S.tpSelectedUserId=nil; S.tpSelectedLabel=nil; ddBtn.Text="Choose player  v"; tpBtn.Text="TP -> (choose a player)"; setTPEnabled(false) end
        end
        ddBtn.MouseButton1Click:Connect(function() listHolder.Visible=not listHolder.Visible; if listHolder.Visible then rebuild() end end)
        refreshBtn.MouseButton1Click:Connect(function() rebuild() end)
        Players.PlayerAdded:Connect(function() if listHolder.Visible then rebuild() end end); Players.PlayerRemoving:Connect(function() if listHolder.Visible then rebuild() end end)
        tpBtn.MouseButton1Click:Connect(function() if S.tpSelectedUserId then tpToPlayerId(S.tpSelectedUserId) end end)
        UIS.InputBegan:Connect(function(input,gp) if gp then return end; if input.KeyCode==Enum.KeyCode.G and S.tpSelectedUserId then tpToPlayerId(S.tpSelectedUserId) end end)
    end

    do
        local Card,Body=section("NoClip","Walk through parts (reversible).")
        local setT,btn=toggle(Body,"Enable NoClip",S.noclipOn)
        btn.MouseButton1Click:Connect(function() S.noclipOn=not S.noclipOn; setT(S.noclipOn); if S.noclipOn then noclip_enable() else noclip_disable() end; refreshHUD() end)
    end

    do
        local Card,Body=section("Infinite Jump","Jump again in air (boost).")
        local setT,btn=toggle(Body,"Enable Infinite Jump",S.ijOn)
        local g=slider(Body,"Boost Y",20,120,S.ijBoost,function(v) return v end)
        RS.Heartbeat:Connect(function() S.ijBoost=g() end)
        btn.MouseButton1Click:Connect(function() S.ijOn=not S.ijOn; setT(S.ijOn); if S.ijOn then if LP.Character then ij_bind(LP.Character) end else if S.ijConn then S.ijConn:Disconnect(); S.ijConn=nil end end end)
    end

    -- quick actions
    local function saveNow()
        local pos=Main.AbsolutePosition; S.windowPos={x=pos.X,y=pos.Y}
        local dump={} for k,v in pairs(S) do local t=typeof(v); if t=="boolean" or t=="number" or t=="string" or t=="table" then dump[k]=v end end
        saveTable(dump)
        pcall(function() StarterGui:SetCore("SendNotification",{Title="Premium Hub", Text="Saved.", Duration=2}) end)
    end
    local function allOff()
        if S.speedOn then S.speedOn=false; speed_disable() end
        if S.flyOn then S.flyOn=false; fly_disable() end
        if S.lightOn then S.lightOn=false; light_disable() end
        if S.espOn then S.espOn=false; esp_disable() end
        if S.hitboxOn then S.hitboxOn=false; hitbox_disable() end
        if S.noclipOn then S.noclipOn=false; noclip_disable() end
        if S.ijOn then S.ijOn=false; if S.ijConn then S.ijConn:Disconnect(); S.ijConn=nil end end
        refreshHUD()
    end
    quick("Save",82,saveNow)
    quick("All Off",96,allOff)
    quick("Panic",88,function() allOff(); UI.Enabled=false; HUD.Enabled=false end)
    quick("Reset Pos",98,function() local vs=workspace.CurrentCamera.ViewportSize; Main.Position=UDim2.fromOffset(math.floor(vs.X/2-Main.Size.X.Offset/2), math.floor(vs.Y/2-Main.Size.Y.Offset/2)); S.windowPos=nil end)
    quick("HUD",70,function() S.hudOn=not S.hudOn; HUD.Enabled=S.hudOn end)

    -- drag + hotkeys
    local function clampToScreen(x,y) local vs=workspace.CurrentCamera.ViewportSize; local w,h=Main.AbsoluteSize.X,Main.AbsoluteSize.Y; return math.clamp(x,0,math.max(0,vs.X-w)), math.clamp(y,0,math.max(0,vs.Y-h)) end
    local dragging,offset
    local function beginDrag(io) dragging=true; local p=Main.AbsolutePosition; offset=Vector2.new(io.Position.X-p.X, io.Position.Y-p.Y) end
    local function updateDrag(io) if not dragging then return end; local x=io.Position.X-offset.X; local y=io.Position.Y-offset.Y; x,y=clampToScreen(x,y); Main.Position=UDim2.fromOffset(x,y) end
    local function endDrag() dragging=false; saveNow() end
    for _,area in ipairs({Header,Main}) do
        area.InputBegan:Connect(function(io)
            if io.UserInputType==Enum.UserInputType.MouseButton1 then
                beginDrag(io)
                io.Changed:Connect(function() if io.UserInputState==Enum.UserInputState.End then endDrag() end end)
            end
        end)
    end
    UIS.InputChanged:Connect(function(io) if io.UserInputType==Enum.UserInputType.MouseMovement then updateDrag(io) end end)

    local function combo(keys, keycode)
        if type(keys)=="table" then
            if table.find(keys,"Shift") and (keycode==Enum.KeyCode.Four) and (UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift)) then return true end
            for _,k in ipairs(keys) do if Enum.KeyCode[k] and Enum.KeyCode[k]==keycode then return true end end
            return false
        else
            return (Enum.KeyCode[keys] and Enum.KeyCode[keys]==keycode) or false
        end
    end
    local function toggleUI() S.uiVisible=not S.uiVisible; UI.Enabled=S.uiVisible; HUD.Enabled=S.hudOn and S.uiVisible end
    HideBtn.MouseButton1Click:Connect(toggleUI)
    UIS.InputBegan:Connect(function(io,gp)
        if gp then return end
        if io.UserInputType==Enum.UserInputType.Keyboard then
            if combo(S.key_UI, io.KeyCode) or io.KeyCode==Enum.KeyCode.F2 or io.KeyCode==Enum.KeyCode.Insert or io.KeyCode==Enum.KeyCode.RightControl then
                toggleUI()
            elseif combo(S.key_Panic, io.KeyCode) then
                allOff(); UI.Enabled=false; HUD.Enabled=false
            elseif combo(S.key_ESP, io.KeyCode) then
                S.espOn=not S.espOn; if S.espOn then esp_enable() else esp_disable() end; refreshHUD()
            elseif combo(S.key_Fly, io.KeyCode) then
                S.flyOn=not S.flyOn; if S.flyOn then fly_enable() else fly_disable() end; refreshHUD()
            elseif combo(S.key_Clip, io.KeyCode) then
                S.noclipOn=not S.noclipOn; if S.noclipOn then noclip_enable() else noclip_disable() end; refreshHUD()
            end
        end
    end)

    -- autosave
    local t=0; RS.Heartbeat:Connect(function(dt) t+=dt; if t>5 then t=0; saveNow() end end)

    -- show
    UI.Enabled=true; HUD.Enabled=S.hudOn; applyOpacity(); refreshHUD()
    pcall(function() StarterGui:SetCore("SendNotification",{Title="Premium Hub", Text="Loaded.", Duration=2}) end)
end

-- start: splash then hub
showSplash7s(StartHub)
