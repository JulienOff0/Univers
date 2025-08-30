--[[  👑 Premium Hub v6.4 — Solara Safe  ]]
-- Reset ultra-dur: supprime anciennes UIs / splash / états globaux
pcall(function()
    local P = game:GetService("Players").LocalPlayer
    local roots = {}
    local okCore, core = pcall(function() return game:GetService("CoreGui") end)
    local hui = gethui and gethui() or nil
    table.insert(roots, hui)
    if okCore then table.insert(roots, core) end
    if P and P:FindFirstChild("PlayerGui") then table.insert(roots, P.PlayerGui) end
    local names = {"PremiumHubV64","PremiumHubV63","PremiumHubV6","PremiumHubV4","PremiumHubV3","PremiumHUD","PH_Splash"}
    for _,root in ipairs(roots) do
        if root then
            for _,n in ipairs(names) do
                if root:FindFirstChild(n) then root[n]:Destroy() end
            end
        end
    end
end)
_G.__PREMIUM_HUB_RUNNING = nil

-- Services
local Players  = game:GetService("Players")
local UIS      = game:GetService("UserInputService")
local RS       = game:GetService("RunService")
local TS       = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Http     = game:GetService("HttpService")
local MPS      = game:GetService("MarketplaceService")
local StarterGui = game:GetService("StarterGui")
local LP       = Players.LocalPlayer

-- helpers
local function getChar() return LP.Character or LP.CharacterAdded:Wait() end
local function getHum()  return (getChar()):WaitForChild("Humanoid") end
local function tween(o,t,props) return TS:Create(o, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props) end
local function disconnect(c) if c then pcall(function() c:Disconnect() end) end
local function disconnectAll(tab) for i=#tab,1,-1 do disconnect(tab[i]); tab[i]=nil end end

-- parentage le plus compatible (Solara / mobile / PC)
local function best_ui_parent()
    local target = nil
    if gethui then
        target = gethui()
    end
    if not target then
        local ok, core = pcall(function() return game:GetService("CoreGui") end)
        if ok and core then target = core end
    end
    if not target then
        target = LP:WaitForChild("PlayerGui")
    end
    return target
end
local function safeParent(gui)
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
    gui.Parent = best_ui_parent()
end

-- ================== Persistance ==================
local FS = { ok = (writefile and readfile and isfile and makefolder) and true or false }
FS.dir  = "PremiumHub"
FS.file = ("%s/settings_%d.json"):format(FS.dir, game.PlaceId)
local function saveTable(t)
    local ok, data = pcall(function() return Http:JSONEncode(t) end)
    if not ok then return false end
    if FS.ok then
        pcall(function() if not isfolder(FS.dir) then makefolder(FS.dir) end end)
        local wrote = pcall(function() writefile(FS.file, data) end)
        if wrote then return true end
    end
    shared.__PH_SAVE = data
    return true
end
local function loadTable()
    local raw
    if FS.ok and isfile(FS.file) then
        local ok, data = pcall(function() return readfile(FS.file) end)
        if ok then raw = data end
    elseif shared.__PH_SAVE then
        raw = shared.__PH_SAVE
    end
    if raw then
        local ok, tab = pcall(function() return Http:JSONDecode(raw) end)
        if ok and type(tab)=="table" then return tab end
    end
    return {}
end

-- ================== État ==================
local S = {
    __ver="6.4",
    uiVisible=true, hudOn=true, showSplash=true,
    theme="dark", accent="blue", scale=1.0, opacity=1.0, windowPos=nil,

    key_UI   = {"Shift","4"},
    key_Panic= {"RightAlt"},
    key_ESP  = {"F3"},
    key_Fly  = {"F4"},
    key_Clip = {"F5"},

    -- Speed
    speedOn=false, speed=22, minSpeed=16, maxSpeed=120, speedCon={hb=nil,prop=nil}, humanoid=nil, normalSpeed=nil,

    -- Fly
    flyOn=false, flyConns={}, flyAlive=false, flyData=nil,

    -- Light
    lightOn=false, lightBackup=nil,

    -- ESP (aura + box + tags)
    espOn=false, espConn=nil, espHz=10, espShowUsername=true, espMaxDist=6000,

    -- Hitbox
    hitboxOn=false, hitboxSize=10, hitboxConn=nil, hitboxOrig={},

    -- TP
    tpSelectedUserId=nil, tpSelectedLabel=nil,

    -- NoClip
    noclipOn=false, noclipStep=nil, noclipDesc=nil, noclipOriginal={},

    -- Infinite Jump
    ijOn=false, ijBoost=55, ijConn=nil,
}
do
    local loaded = loadTable()
    for k,v in pairs(loaded) do if S[k] ~= nil then S[k]=v end end
end

-- ================== Thème ==================
local THEMES = {
    dark  ={bg=Color3.fromRGB(12,13,16), card=Color3.fromRGB(22,24,29), cardTop=Color3.fromRGB(28,30,36), text=Color3.fromRGB(235,238,255), muted=Color3.fromRGB(170,176,196), neutral=Color3.fromRGB(66,70,88), bar=Color3.fromRGB(46,50,65)},
    light ={bg=Color3.fromRGB(240,242,248), card=Color3.fromRGB(252,253,255), cardTop=Color3.fromRGB(248,250,255), text=Color3.fromRGB(28,30,36),  muted=Color3.fromRGB(110,120,140), neutral=Color3.fromRGB(210,214,230), bar=Color3.fromRGB(220,224,240)},
}
local ACCENTS = {
    blue    ={Color3.fromRGB(58,116,255),  Color3.fromRGB(120,170,255)},
    violet  ={Color3.fromRGB(160,90,255),  Color3.fromRGB(210,120,255)},
    emerald ={Color3.fromRGB(34,197,94),   Color3.fromRGB(74,222,128)},
    gold    ={Color3.fromRGB(245,183,0),   Color3.fromRGB(255,220,80)},
    rose    ={Color3.fromRGB(236,72,153),  Color3.fromRGB(244,114,182)},
}
local function TH() return THEMES[S.theme] end
local function ACCA() return ACCENTS[S.accent][1] end
local function ACCB() return ACCENTS[S.accent][2] end

-- ================== Racines UI ==================
local UI  = Instance.new("ScreenGui"); UI.Name="PremiumHubV64"; safeParent(UI); UI.Enabled=false
local HUD = Instance.new("ScreenGui"); HUD.Name="PremiumHUD";   safeParent(HUD); HUD.Enabled=S.hudOn

-- Opacité
local ALPHA={} local function regAlpha(n) table.insert(ALPHA, n) end
local function applyOpacity() for _,f in ipairs(ALPHA) do pcall(function() f.BackgroundTransparency = 1 - S.opacity end) end end

-- ================== Main Window ==================
local Main = Instance.new("Frame")
Main.Size=UDim2.fromOffset(660,770)
Main.BackgroundColor3=TH().bg
Main.BorderSizePixel=0
Main.Active=true
Main.Parent=UI
do
    local vs=workspace.CurrentCamera.ViewportSize
    local x=math.floor(vs.X/2-Main.Size.X.Offset/2)
    local y=math.floor(vs.Y/2-Main.Size.Y.Offset/2)
    if S.windowPos then x=S.windowPos.x;y=S.windowPos.y end
    Main.Position=UDim2.fromOffset(x,y)
end
local sc=Instance.new("UIScale",Main); sc.Scale=S.scale
Instance.new("UICorner",Main).CornerRadius=UDim.new(0,18)
regAlpha(Main)

local Shadow=Instance.new("ImageLabel")
Shadow.Image="rbxassetid://5028857084"; Shadow.ImageTransparency=.5
Shadow.ScaleType=Enum.ScaleType.Slice; Shadow.SliceCenter=Rect.new(24,24,276,276)
Shadow.AnchorPoint=Vector2.new(.5,.5); Shadow.Position=UDim2.fromScale(.5,.5)
Shadow.Size=UDim2.new(1,50,1,50); Shadow.BackgroundTransparency=1; Shadow.Parent=Main

-- Header
local Header=Instance.new("Frame"); Header.Size=UDim2.new(1,0,0,70); Header.BackgroundColor3=TH().cardTop; Header.BorderSizePixel=0; Header.Active=true; Header.Parent=Main
Instance.new("UICorner",Header).CornerRadius=UDim.new(0,18); regAlpha(Header)
local bar=Instance.new("Frame"); bar.BackgroundTransparency=.15; bar.Size=UDim2.new(1,-32,0,70); bar.Position=UDim2.fromOffset(16,0); bar.Parent=Header
pcall(function() local gbar=Instance.new("UIGradient",bar); gbar.Rotation=20; gbar.Color=ColorSequence.new(ACCA(),ACCB()); gbar.Transparency=NumberSequence.new{NumberSequenceKeypoint.new(0,.9), NumberSequenceKeypoint.new(.5,.82), NumberSequenceKeypoint.new(1,.9)} end)
local Title=Instance.new("TextLabel"); Title.BackgroundTransparency=1; Title.Position=UDim2.fromOffset(18,12); Title.Size=UDim2.fromOffset(460,44)
Title.Font=Enum.Font.GothamBlack; Title.TextSize=24; Title.TextXAlignment=Enum.TextXAlignment.Left; Title.TextColor3=TH().text
Title.Text="👑 Premium Hub v6.4 — VIP"; Title.Parent=Header
local Hint=Instance.new("TextLabel"); Hint.BackgroundTransparency=1; Hint.AnchorPoint=Vector2.new(1,0); Hint.Position=UDim2.new(1,-56,0,24)
Hint.Size=UDim2.fromOffset(360,24); Hint.Font=Enum.Font.Gotham; Hint.TextSize=14; Hint.TextXAlignment=Enum.TextXAlignment.Right; Hint.TextColor3=TH().muted
Hint.Text='Hide: "$"(⇧+4) • F2 • Insert • RightCtrl'; Hint.Parent=Header
local HideBtn=Instance.new("TextButton"); HideBtn.AnchorPoint=Vector2.new(1,0); HideBtn.Position=UDim2.new(1,-12,0,16); HideBtn.Size=UDim2.fromOffset(36,36)
HideBtn.Text="✕"; HideBtn.TextSize=18; HideBtn.Font=Enum.Font.GothamBold; HideBtn.TextColor3=TH().text; HideBtn.AutoButtonColor=false; HideBtn.BackgroundColor3=TH().neutral
HideBtn.Parent=Header; Instance.new("UICorner",HideBtn).CornerRadius=UDim.new(1,0); regAlpha(HideBtn)

-- Quick bar
local Quick=Instance.new("Frame"); Quick.BackgroundColor3=TH().cardTop; Quick.BorderSizePixel=0; Quick.Size=UDim2.new(1,-32,0,44); Quick.Position=UDim2.fromOffset(16,76); Quick.Parent=Main
Instance.new("UICorner",Quick).CornerRadius=UDim.new(0,12); regAlpha(Quick)
local qList=Instance.new("UIListLayout",Quick); qList.FillDirection=Enum.FillDirection.Horizontal; qList.Padding=UDim.new(0,8); qList.VerticalAlignment=Enum.VerticalAlignment.Center
local function glow(btn,on,off) btn.MouseEnter:Connect(function() tween(btn,.15,{BackgroundColor3=on}):Play() end); btn.MouseLeave:Connect(function() tween(btn,.15,{BackgroundColor3=off}):Play() end) end
local function quickButton(txt,w,cb)
    local b=Instance.new("TextButton"); b.Size=UDim2.fromOffset(w,30); b.Text=txt; b.Font=Enum.Font.GothamSemibold; b.TextSize=14; b.TextColor3=TH().text
    b.BackgroundColor3=TH().neutral; b.AutoButtonColor=false; b.Parent=Quick; Instance.new("UICorner",b).CornerRadius=UDim.new(0,8); regAlpha(b)
    glow(b, ACCA(), TH().neutral); b.MouseButton1Click:Connect(cb); return b
end

-- Content
local Content=Instance.new("ScrollingFrame"); Content.Position=UDim2.fromOffset(16,126); Content.Size=UDim2.new(1,-32,1,-142)
Content.CanvasSize=UDim2.new(0,0,0,0); Content.ScrollBarThickness=6; Content.BackgroundTransparency=1; Content.Parent=Main
local VList=Instance.new("UIListLayout",Content); VList.Padding=UDim.new(0,12); VList.SortOrder=Enum.SortOrder.LayoutOrder
local function refreshCanvas() Content.CanvasSize=UDim2.new(0,0,0,VList.AbsoluteContentSize.Y+8) end
VList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(refreshCanvas)

-- HUD
local HudFrame=Instance.new("Frame"); HudFrame.Size=UDim2.fromOffset(230,28); HudFrame.Position=UDim2.fromOffset(12,12); HudFrame.BackgroundColor3=TH().cardTop; HudFrame.Parent=HUD
Instance.new("UICorner",HudFrame).CornerRadius=UDim.new(0,8); regAlpha(HudFrame)
local HudText=Instance.new("TextLabel"); HudText.BackgroundTransparency=1; HudText.Font=Enum.Font.GothamSemibold; HudText.TextSize=14; HudText.TextXAlignment=Enum.TextXAlignment.Left; HudText.TextColor3=TH().text
HudText.Text="Speed:off  Fly:off  ESP:off  Clip:off"; HudText.Size=UDim2.new(1,-10,1,0); HudText.Position=UDim2.fromOffset(8,0); HudText.Parent=HudFrame
local function refreshHUD() HudText.Text=string.format("Speed:%s  Fly:%s  ESP:%s  Clip:%s", S.speedOn and "on" or "off", S.flyOn and "on" or "off", S.espOn and "on" or "off", S.noclipOn and "on" or "off") end
refreshHUD()

-- ========== UI Helpers ==========
local function makeSection(titleText, subtitleText)
    local Card=Instance.new("Frame"); Card.Size=UDim2.new(1,0,0,0); Card.AutomaticSize=Enum.AutomaticSize.Y; Card.BackgroundColor3=TH().card; Card.BorderSizePixel=0; Card.Active=true; Card.Parent=Content
    Instance.new("UICorner",Card).CornerRadius=UDim.new(0,14); regAlpha(Card)
    local Top=Instance.new("Frame"); Top.BackgroundColor3=TH().cardTop; Top.BorderSizePixel=0; Top.Size=UDim2.new(1,0,0,48); Top.Parent=Card
    Instance.new("UICorner",Top).CornerRadius=UDim.new(0,14); regAlpha(Top)
    local T=Instance.new("TextLabel"); T.BackgroundTransparency=1; T.Font=Enum.Font.GothamSemibold; T.TextSize=16; T.TextXAlignment=Enum.TextXAlignment.Left
    T.TextColor3=TH().text; T.Text=titleText; T.Position=UDim2.fromOffset(14,10); T.Size=UDim2.fromOffset(440,20); T.Parent=Top
    local ST=Instance.new("TextLabel"); ST.BackgroundTransparency=1; ST.Font=Enum.Font.Gotham; ST.TextSize=13; ST.TextXAlignment=Enum.TextXAlignment.Left
    ST.TextColor3=TH().muted; ST.Text=subtitleText or ""; ST.Position=UDim2.fromOffset(14,28); ST.Size=UDim2.fromOffset(540,18); ST.Parent=Top
    local Toggle=Instance.new("TextButton"); Toggle.AutoButtonColor=false; Toggle.AnchorPoint=Vector2.new(1,0); Toggle.Position=UDim2.new(1,-10,0,8)
    Toggle.Size=UDim2.fromOffset(30,30); Toggle.Font=Enum.Font.GothamBold; Toggle.TextSize=16; Toggle.Text="–"; Toggle.TextColor3=TH().text; Toggle.BackgroundColor3=TH().neutral; Toggle.Parent=Top
    Instance.new("UICorner",Toggle).CornerRadius=UDim.new(1,0); regAlpha(Toggle)
    local Body=Instance.new("Frame"); Body.BackgroundTransparency=1; Body.Position=UDim2.fromOffset(0,48); Body.Size=UDim2.new(1,0,0,0); Body.AutomaticSize=Enum.AutomaticSize.Y; Body.Parent=Card
    local Pad=Instance.new("UIPadding",Body); Pad.PaddingLeft=UDim.new(0,14); Pad.PaddingRight=UDim.new(0,14); Pad.PaddingTop=UDim.new(0,10); Pad.PaddingBottom=UDim.new(0,12)
    local open=true; Toggle.MouseButton1Click:Connect(function() open=not open; Toggle.Text=open and "–" or "+"; tween(Body,.15,{Transparency=open and 0 or 1}):Play(); Body.Visible=open end)
    return Card,Body
end
local function makeToggle(parent,label,defaultOn)
    local Row=Instance.new("Frame"); Row.BackgroundTransparency=1; Row.Size=UDim2.new(1,0,0,34); Row.Parent=parent
    local L=Instance.new("TextLabel"); L.BackgroundTransparency=1; L.Font=Enum.Font.Gotham; L.TextSize=14; L.TextXAlignment=Enum.TextXAlignment.Left; L.TextColor3=TH().text
    L.Text=label; L.Position=UDim2.fromOffset(0,8); L.Size=UDim2.fromOffset(360,18); L.Parent=Row
    local Btn=Instance.new("TextButton"); Btn.AutoButtonColor=false; Btn.AnchorPoint=Vector2.new(1,0); Btn.Position=UDim2.new(1,-2,0,4)
    Btn.Size=UDim2.fromOffset(74,26); Btn.BackgroundColor3= defaultOn and ACCA() or TH().neutral; Btn.Text=""; Btn.Parent=Row; Instance.new("UICorner",Btn).CornerRadius=UDim.new(1,0); regAlpha(Btn)
    local Knob=Instance.new("Frame"); Knob.Size=UDim2.fromOffset(24,24); Knob.Position= defaultOn and UDim2.fromOffset(48,1) or UDim2.fromOffset(2,1); Knob.BackgroundColor3=TH().cardTop; Knob.Parent=Btn; Instance.new("UICorner",Knob).CornerRadius=UDim.new(1,0); regAlpha(Knob)
    local function setOn(on) tween(Btn,.16,{BackgroundColor3= on and ACCA() or TH().neutral}):Play(); tween(Knob,.16,{Position= on and UDim2.fromOffset(48,1) or UDim2.fromOffset(2,1)}):Play() end
    return Row,setOn,Btn
end
local function makeSlider(parent,label,minV,maxV,defaultV,fmt)
    local Row=Instance.new("Frame"); Row.BackgroundTransparency=1; Row.Size=UDim2.new(1,0,0,58); Row.Parent=parent
    local T=Instance.new("TextLabel"); T.BackgroundTransparency=1; T.Font=Enum.Font.Gotham; T.TextSize=14; T.TextXAlignment=Enum.TextXAlignment.Left; T.TextColor3=TH().text
    local function format(v) return fmt and fmt(v) or tostring(v) end
    T.Text=string.format("%s: %s",label,format(defaultV)); T.Position=UDim2.fromOffset(0,2); T.Size=UDim2.fromOffset(380,18); T.Parent=Row
    local Track=Instance.new("Frame"); Track.BackgroundColor3=TH().bar; Track.BorderSizePixel=0; Track.Position=UDim2.fromOffset(0,28); Track.Size=UDim2.new(1,-2,0,10); Track.Parent=Row; Instance.new("UICorner",Track).CornerRadius=UDim.new(0,6); regAlpha(Track)
    local Fill=Instance.new("Frame"); Fill.BackgroundColor3=ACCA(); Fill.BorderSizePixel=0; Fill.Size=UDim2.fromOffset(0,10); Fill.Parent=Track; Instance.new("UICorner",Fill).CornerRadius=UDim.new(0,6)
    pcall(function() local grad=Instance.new("UIGradient",Fill); grad.Rotation=15; grad.Color=ColorSequence.new(ACCA(), ACCB()) end)
    local Knob=Instance.new("Frame"); Knob.Size=UDim2.fromOffset(16,16); Knob.Position=UDim2.fromOffset(-8,-3); Knob.BackgroundColor3=TH().cardTop; Knob.Parent=Fill; Instance.new("UICorner",Knob).CornerRadius=UDim.new(1,0); regAlpha(Knob)
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
    return function() return current end, function(v) v=math.clamp(v,minV,maxV); local abs=Track.AbsoluteSize.X; local r=(v-minV)/(maxV-minV); local w=math.floor(abs*r + .5); Fill.Size=UDim2.fromOffset(w,10); Knob.Position=UDim2.fromOffset(w-8,-3); T.Text=string.format("%s: %s",label,format(v)); current=v end
end

-- ================== Modules ==================
-- Speed
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

-- Fly (sortie propre anti-plaquage)
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
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.Landed) end)
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
    task.spawn(function() while S.flyAlive and char.Parent do if hum.AutoRotate~=false then hum.AutoRotate=false end if not att.Parent then att.Parent=hrp end if not lv.Parent then lv.Parent=hrp end task.wait(0.05) end end)
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

-- Light
local LIGHT_PRESET={GlobalShadows=false, FogEnd=100000, Brightness=2, Ambient=Color3.fromRGB(150,150,150)}
local function light_enable() if not S.lightBackup then S.lightBackup={GlobalShadows=Lighting.GlobalShadows, FogEnd=Lighting.FogEnd, Brightness=Lighting.Brightness, Ambient=Lighting.Ambient} end
Lighting.GlobalShadows=LIGHT_PRESET.GlobalShadows; Lighting.FogEnd=LIGHT_PRESET.FogEnd; Lighting.Brightness=LIGHT_PRESET.Brightness; Lighting.Ambient=LIGHT_PRESET.Ambient end
local function light_disable() if S.lightBackup then Lighting.GlobalShadows=S.lightBackup.GlobalShadows; Lighting.FogEnd=S.lightBackup.FogEnd; Lighting.Brightness=S.lightBackup.Brightness; Lighting.Ambient=S.lightBackup.Ambient end end

-- ESP (aura + boîte + pseudo + distance)
local ROLE_COLORS={Murder=Color3.fromRGB(255,60,60),Murderer=Color3.fromRGB(255,60,60),Innocent=Color3.fromRGB(64,128,255),Sheriff=Color3.fromRGB(255,220,0),Detective=Color3.fromRGB(255,220,0)}
local DEFAULT_COLOR=Color3.fromRGB(200,200,200)
local function getRole(p,char) local r=p:GetAttribute("Role"); if r==nil and char then r=char:GetAttribute("Role") end; return (typeof(r)=="string") and r or nil end
local function colorFor(p,char) local role=getRole(p,char); if role and ROLE_COLORS[role] then return ROLE_COLORS[role] end; if p.Team and p.Team.TeamColor then return p.Team.TeamColor.Color end; return DEFAULT_COLOR end
local function headOrPart(char) return char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildWhichIsA("BasePart") end
local function sameColor(a,b) return a and b and a.r==b.r and a.g==b.g and a.b==b.b end
local ESP_REG={} -- [Player]={char,hl,box,bb,nameLbl,distLbl,lastName,lastDist,lastColor,conns={}}
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
                        if not sameColor(reg.lastColor,col) then reg.lastColor=col; reg.hl.OutlineColor=col; pcall(function() reg.box.LineColor3=col end); pcall(function() reg.box.Color3=col end); reg.nameLbl.TextColor3=col; reg.distLbl.TextColor3=col end
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

-- Hitbox (HRP)
local function rememberHRP(hrp) if not hrp or S.hitboxOrig[hrp] then return end S.hitboxOrig[hrp]={Size=hrp.Size,Transparency=hrp.Transparency,Material=hrp.Material,CanCollide=hrp.CanCollide,BrickColor=hrp.BrickColor} end
local function applyHitboxTo(hrp) if not hrp then return end rememberHRP(hrp); hrp.Size=Vector3.new(S.hitboxSize,S.hitboxSize,S.hitboxSize); hrp.Transparency=.7; hrp.BrickColor=BrickColor.new("Really red"); hrp.Material=Enum.Material.Neon; hrp.CanCollide=false end
local function restoreAllHitbox() for hrp,orig in pairs(S.hitboxOrig) do if hrp and hrp.Parent and orig then pcall(function() hrp.Size=orig.Size; hrp.Transparency=orig.Transparency; hrp.Material=orig.Material; hrp.CanCollide=orig.CanCollide; hrp.BrickColor=orig.BrickColor end) end end S.hitboxOrig={} end
local function hitbox_loop() for _,pl in ipairs(Players:GetPlayers()) do if pl~=LP and pl.Character then local hrp=pl.Character:FindFirstChild("HumanoidRootPart"); if hrp then pcall(applyHitboxTo, hrp) end end end end
local function hitbox_enable() if S.hitboxConn then return end; hitbox_loop(); S.hitboxConn=RS.RenderStepped:Connect(function() if S.hitboxOn then hitbox_loop() end end); Players.PlayerAdded:Connect(function(p) p.CharacterAdded:Connect(function(c) task.wait(.1); local hrp=c:FindFirstChild("HumanoidRootPart"); if hrp then rememberHRP(hrp) end end) end) end
local function hitbox_disable() disconnect(S.hitboxConn); S.hitboxConn=nil; restoreAllHitbox() end

-- NoClip
local function noclip_cachePart(inst) if inst:IsA("BasePart") and S.noclipOriginal[inst]==nil then S.noclipOriginal[inst]=inst.CanCollide end end
local function noclip_cacheChar(char) for _,d in ipairs(char:GetDescendants()) do noclip_cachePart(d) end; disconnect(S.noclipDesc); S.noclipDesc=char.DescendantAdded:Connect(noclip_cachePart) end
local function noclip_apply(char) for part,_ in pairs(S.noclipOriginal) do if part.Parent and part:IsDescendantOf(char) then part.CanCollide=false end end end
local function noclip_enable() local char=getChar(); S.noclipOriginal={}; noclip_cacheChar(char); disconnect(S.noclipStep); S.noclipStep=RS.Stepped:Connect(function() noclip_apply(char) end) end
local function noclip_disable() disconnect(S.noclipStep); S.noclipStep=nil; disconnect(S.noclipDesc); S.noclipDesc=nil; for part,can in pairs(S.noclipOriginal) do if part and part.Parent then part.CanCollide=can end end; S.noclipOriginal={} end
LP.CharacterAdded:Connect(function(c) if S.noclipOn then noclip_enable() end end)

-- Infinite Jump
local function ij_bind(char)
    local hum=char:WaitForChild("Humanoid"); local root=char:WaitForChild("HumanoidRootPart")
    hum.UseJumpPower=true
    disconnect(S.ijConn)
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

-- ========== Sections ==========
local function makeBindUI(Body,label,keys,apply)
    local Row=Instance.new("Frame"); Row.BackgroundTransparency=1; Row.Size=UDim2.new(1,0,0,38); Row.Parent=Body
    local Lb=Instance.new("TextLabel"); Lb.BackgroundTransparency=1; Lb.Font=Enum.Font.Gotham; Lb.TextSize=14; Lb.TextXAlignment=Enum.TextXAlignment.Left; Lb.TextColor3=TH().text; Lb.Text=label; Lb.Position=UDim2.fromOffset(0,8); Lb.Size=UDim2.fromOffset(240,18); Lb.Parent=Row
    local Btn=Instance.new("TextButton"); Btn.Size=UDim2.fromOffset(180,28); Btn.Position=UDim2.new(0,250,0,4); Btn.BackgroundColor3=TH().neutral; Btn.AutoButtonColor=false; Btn.TextColor3=TH().text; Btn.TextSize=14; Btn.Font=Enum.Font.GothamSemibold; Btn.Parent=Row; Instance.new("UICorner",Btn).CornerRadius=UDim.new(0,8); regAlpha(Btn)
    local function show() Btn.Text="["..(type(keys)=="table" and table.concat(keys," + ") or tostring(keys)).."]" end
    show()
    local waiting=false
    Btn.MouseButton1Click:Connect(function() Btn.Text="... appuie ..."; waiting=true end)
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

-- Apparence & UI
do
    local Card,Body=makeSection("🎨 Apparence & UI","Thème, accent, scale, opacité, HUD, keybinds.")
    local _,setLight,btnLight=makeToggle(Body,"Thème clair",S.theme=="light"); btnLight.MouseButton1Click:Connect(function()
        S.theme=(S.theme=="light") and "dark" or "light"
        Main.BackgroundColor3=TH().bg; Header.BackgroundColor3=TH().cardTop; Title.TextColor3=TH().text; Hint.TextColor3=TH().muted
        Quick.BackgroundColor3=TH().cardTop; HudFrame.BackgroundColor3=TH().cardTop; HudText.TextColor3=TH().text; applyOpacity()
        setLight(S.theme=="light")
    end)
    -- Accent
    local row=Instance.new("Frame"); row.BackgroundTransparency=1; row.Size=UDim2.new(1,0,0,36); row.Parent=Body
    local L=Instance.new("TextLabel"); L.BackgroundTransparency=1; L.Font=Enum.Font.Gotham; L.TextSize=14; L.TextXAlignment=Enum.TextXAlignment.Left; L.TextColor3=TH().text; L.Text="Accent"; L.Position=UDim2.fromOffset(0,8); L.Size=UDim2.fromOffset(120,18); L.Parent=row
    local function dot(c,name,x) local b=Instance.new("TextButton"); b.Size=UDim2.fromOffset(26,26); b.Position=UDim2.fromOffset(130+(x*32),5); b.Text=""; b.BackgroundColor3=c; b.AutoButtonColor=false; b.Parent=row; Instance.new("UICorner",b).CornerRadius=UDim.new(1,0); b.MouseButton1Click:Connect(function() S.accent=name end) end
    dot(ACCENTS.blue[1],"blue",0); dot(ACCENTS.violet[1],"violet",1); dot(ACCENTS.emerald[1],"emerald",2); dot(ACCENTS.gold[1],"gold",3); dot(ACCENTS.rose[1],"rose",4)
    -- sliders
    local sGet,_sSet=makeSlider(Body,"Échelle UI",80,120,math.floor(S.scale*100),function(v)return v.."%";end)
    local oGet,_oSet=makeSlider(Body,"Opacité",70,100,math.floor(S.opacity*100),function(v)return v.."%";end)
    RS.Heartbeat:Connect(function() S.scale=(sGet()/100); sc.Scale=S.scale; S.opacity=(oGet()/100); applyOpacity() end)
    local _,setHUD,btnHUD=makeToggle(Body,"Mini HUD",S.hudOn); btnHUD.MouseButton1Click:Connect(function() S.hudOn=not S.hudOn; HUD.Enabled=S.hudOn; setHUD(S.hudOn) end)
    local _,setSplash,btnSp=makeToggle(Body,"Afficher le Splash au lancement",S.showSplash); btnSp.MouseButton1Click:Connect(function() S.showSplash=not S.showSplash; setSplash(S.showSplash) end)
    makeBindUI(Body,"Afficher/Cacher l’UI", S.key_UI,   function(k) S.key_UI=k end)
    makeBindUI(Body,"Panic (tout couper)", S.key_Panic,function(k) S.key_Panic=k end)
    makeBindUI(Body,"Toggle ESP",          S.key_ESP,  function(k) S.key_ESP=k end)
    makeBindUI(Body,"Toggle Fly",          S.key_Fly,  function(k) S.key_Fly=k end)
    makeBindUI(Body,"Toggle NoClip",       S.key_Clip, function(k) S.key_Clip=k end)
end

-- Speed
do local Card,Body=makeSection("⚡ Speed","Maintient ta vitesse (anti-reset + respawn).")
    local _,setT,btn=makeToggle(Body,"Activer Speed",S.speedOn)
    local getV,_setV=makeSlider(Body,"Vitesse",S.minSpeed,S.maxSpeed,S.speed,function(v) return v end)
    btn.MouseButton1Click:Connect(function() S.speed= getV(); S.speedOn=not S.speedOn; setT(S.speedOn); if S.speedOn then speed_enable() else speed_disable() end; refreshHUD() end)
    RS.Heartbeat:Connect(function() S.speed=getV() end)
end

-- Fly
do local Card,Body=makeSection("🕊️ Fly","Vol fluide (WASD/ZQSD + inclinaison caméra) — sortie propre.")
    local _,setT,btn=makeToggle(Body,"Activer Fly",S.flyOn)
    btn.MouseButton1Click:Connect(function() S.flyOn=not S.flyOn; setT(S.flyOn); if S.flyOn then fly_enable() else fly_disable() end; refreshHUD() end)
end

-- Light
do local Card,Body=makeSection("💡 Light","Désactive ombres, enlève brouillard, boost luminosité.")
    local _,setT,btn=makeToggle(Body,"Activer Light",S.lightOn)
    btn.MouseButton1Click:Connect(function() S.lightOn=not S.lightOn; setT(S.lightOn); if S.lightOn then light_enable() else light_disable() end end)
end

-- ESP
do local Card,Body=makeSection("🧭 ESP Player","Aura + boîte + pseudo + distance (couleurs rôle/équipe, MAJ live).")
    local _,setT,btn=makeToggle(Body,"Activer ESP",S.espOn)
    local _,setU,ubtn=makeToggle(Body,"Afficher @username",S.espShowUsername); ubtn.MouseButton1Click:Connect(function() S.espShowUsername=not S.espShowUsername; setU(S.espShowUsername) end)
    local gHz,_sHz=makeSlider(Body,"Rafraîchissements/s",4,30,S.espHz,function(v)return v end)
    local gR,_sR =makeSlider(Body,"Portée (studs)",200,6000,S.espMaxDist,function(v)return v end)
    RS.Heartbeat:Connect(function() S.espHz=gHz(); S.espMaxDist=gR() end)
    btn.MouseButton1Click:Connect(function() S.espOn=not S.espOn; setT(S.espOn); if S.espOn then esp_enable() else esp_disable() end; refreshHUD() end)
end

-- Hitbox
do local Card,Body=makeSection("🎯 Hitbox (HRP)","Agrandit le HumanoidRootPart des autres joueurs (client-side).")
    local _,setT,btn=makeToggle(Body,"Activer Hitbox",S.hitboxOn)
    local getSize,_set=makeSlider(Body,"Taille",2,30,S.hitboxSize,function(v) return v end)
    RS.Heartbeat:Connect(function() S.hitboxSize=getSize() end)
    btn.MouseButton1Click:Connect(function() S.hitboxOn=not S.hitboxOn; setT(S.hitboxOn); if S.hitboxOn then hitbox_enable() else hitbox_disable() end end)
end

-- TP Player
do
    local Card,Body=makeSection("🧭 TP Player","Choisis un joueur puis clique TP.")
    local row=Instance.new("Frame"); row.BackgroundTransparency=1; row.Size=UDim2.new(1,0,0,36); row.Parent=Body
    local ddBtn=Instance.new("TextButton"); ddBtn.Size=UDim2.new(1,-118,1,0); ddBtn.Text="Choisir un joueur  ▾"; ddBtn.Font=Enum.Font.Gotham; ddBtn.TextSize=14; ddBtn.TextColor3=TH().text; ddBtn.BackgroundColor3=TH().bar; ddBtn.AutoButtonColor=true; ddBtn.Parent=row; Instance.new("UICorner",ddBtn).CornerRadius=UDim.new(0,8); regAlpha(ddBtn)
    local refreshBtn=Instance.new("TextButton"); refreshBtn.Size=UDim2.new(0,110,1,0); refreshBtn.Text="Refresh"; refreshBtn.Font=Enum.Font.GothamSemibold; refreshBtn.TextSize=14; refreshBtn.TextColor3=TH().text; refreshBtn.BackgroundColor3=ACCA(); refreshBtn.Parent=row; Instance.new("UICorner",refreshBtn).CornerRadius=UDim.new(0,8)
    local listHolder=Instance.new("ScrollingFrame"); listHolder.Size=UDim2.new(1,0,0,120); listHolder.BackgroundColor3=TH().cardTop; listHolder.BorderSizePixel=0; listHolder.ScrollBarThickness=6; listHolder.CanvasSize=UDim2.new(0,0,0,0); listHolder.Visible=false; listHolder.Parent=Body
    Instance.new("UICorner",listHolder).CornerRadius=UDim.new(0,10); regAlpha(listHolder)
    local listLayout=Instance.new("UIListLayout",listHolder); listLayout.Padding=UDim.new(0,6)
    local pad=Instance.new("UIPadding",listHolder); pad.PaddingLeft=UDim.new(0,6); pad.PaddingRight=UDim.new(0,6); pad.PaddingTop=UDim.new(0,6); pad.PaddingBottom=UDim.new(0,6)
    local empty=Instance.new("TextLabel"); empty.Size=UDim2.new(1,-12,0,28); empty.BackgroundTransparency=1; empty.Text="Aucun autre joueur."; empty.Font=Enum.Font.Gotham; empty.TextSize=14; empty.TextColor3=TH().muted; empty.Visible=false; empty.Parent=listHolder
    local tpBtn=Instance.new("TextButton"); tpBtn.Size=UDim2.new(1,0,0,36); tpBtn.Text="Se TP → (choisis un joueur)"; tpBtn.Font=Enum.Font.GothamSemibold; tpBtn.TextSize=15; tpBtn.TextColor3=TH().text; tpBtn.BackgroundColor3=Color3.fromRGB(80,80,95); tpBtn.Parent=Body; Instance.new("UICorner",tpBtn).CornerRadius=UDim.new(0,10)
    local function setTPEnabled(on) tpBtn.Active=on; tpBtn.AutoButtonColor=on; tween(tpBtn,.15,{BackgroundColor3= on and ACCA() or Color3.fromRGB(80,80,95)}):Play() end
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
                b.Font=Enum.Font.Gotham; b.TextSize=14; b.TextColor3=TH().text; b.BackgroundColor3=TH().bar; b.AutoButtonColor=true; b.Parent=listHolder
                Instance.new("UICorner",b).CornerRadius=UDim.new(0,8); regAlpha(b)
                b.MouseButton1Click:Connect(function() S.tpSelectedUserId=p.UserId; S.tpSelectedLabel=(p.DisplayName~="" and p.DisplayName) or p.Name; ddBtn.Text="Cible : "..S.tpSelectedLabel.."  ▾"; tpBtn.Text="Se TP → "..S.tpSelectedLabel; setTPEnabled(true); listHolder.Visible=false end)
            end
        end
        resizeCanvas()
        if S.tpSelectedUserId and not Players:GetPlayerByUserId(S.tpSelectedUserId) then S.tpSelectedUserId=nil; S.tpSelectedLabel=nil; ddBtn.Text="Choisir un joueur  ▾"; tpBtn.Text="Se TP → (choisis un joueur)"; setTPEnabled(false) end
    end
    ddBtn.MouseButton1Click:Connect(function() listHolder.Visible=not listHolder.Visible; if listHolder.Visible then rebuild() end end)
    refreshBtn.MouseButton1Click:Connect(function() rebuild() end)
    Players.PlayerAdded:Connect(function() if listHolder.Visible then rebuild() end end); Players.PlayerRemoving:Connect(function() if listHolder.Visible then rebuild() end end)
    tpBtn.MouseButton1Click:Connect(function() if S.tpSelectedUserId then tpToPlayerId(S.tpSelectedUserId) end end)
    UIS.InputBegan:Connect(function(input,gp) if gp then return end; if input.KeyCode==Enum.KeyCode.G and S.tpSelectedUserId then tpToPlayerId(S.tpSelectedUserId) end end)
end

-- NoClip
do local Card,Body=makeSection("🧱 NoClip","Traverse les objets (réversible).")
    local _,setT,btn=makeToggle(Body,"Activer NoClip",S.noclipOn)
    btn.MouseButton1Click:Connect(function() S.noclipOn=not S.noclipOn; setT(S.noclipOn); if S.noclipOn then noclip_enable() else noclip_disable() end; refreshHUD() end)
end

-- Infinite Jump
do local Card,Body=makeSection("🦘 Infinite Jump","Saut infini (boost réglable).")
    local _,setT,btn=makeToggle(Body,"Activer Infinite Jump",S.ijOn)
    local get,set=makeSlider(Body,"Boost Y",20,120,S.ijBoost,function(v) return v end)
    RS.Heartbeat:Connect(function() S.ijBoost=get() end)
    btn.MouseButton1Click:Connect(function() S.ijOn=not S.ijOn; setT(S.ijOn); if S.ijOn then if LP.Character then ij_bind(LP.Character) end else disconnect(S.ijConn); S.ijConn=nil end end)
end

-- ========== Quick bar ==========
local function saveNow()
    local pos=Main.AbsolutePosition; S.windowPos={x=pos.X,y=pos.Y}
    local dump={} for k,v in pairs(S) do local t=typeof(v); if t=="boolean" or t=="number" or t=="string" or t=="table" then dump[k]=v end end
    saveTable(dump)
    pcall(function() StarterGui:SetCore("SendNotification",{Title="Premium Hub", Text="Paramètres sauvegardés.", Duration=2}) end)
end
local function loadNow()
    local t=loadTable()
    for k,v in pairs(t) do if S[k]~=nil then S[k]=v end end
    sc.Scale=S.scale or 1; applyOpacity()
    if S.windowPos then Main.Position=UDim2.fromOffset(S.windowPos.x,S.windowPos.y) end
    pcall(function() StarterGui:SetCore("SendNotification",{Title="Premium Hub", Text="Paramètres chargés.", Duration=2}) end)
end
local function allOff()
    if S.speedOn then S.speedOn=false; speed_disable() end
    if S.flyOn then S.flyOn=false; fly_disable() end
    if S.lightOn then S.lightOn=false; light_disable() end
    if S.espOn then S.espOn=false; esp_disable() end
    if S.hitboxOn then S.hitboxOn=false; hitbox_disable() end
    if S.noclipOn then S.noclipOn=false; noclip_disable() end
    if S.ijOn then S.ijOn=false; disconnect(S.ijConn); S.ijConn=nil end
    refreshHUD()
end
quickButton("💾 Save",82,saveNow)
quickButton("📂 Load",82,loadNow)
quickButton("🧹 All Off",96,allOff)
quickButton("🚨 Panic",88,function() allOff(); UI.Enabled=false; HUD.Enabled=false end)
quickButton("📌 Reset Pos",98,function() local vs=workspace.CurrentCamera.ViewportSize; Main.Position=UDim2.fromOffset(math.floor(vs.X/2-Main.Size.X.Offset/2), math.floor(vs.Y/2-Main.Size.Y.Offset/2)); S.windowPos=nil end)
quickButton("👁 HUD",70,function() S.hudOn=not S.hudOn; HUD.Enabled=S.hudOn end)

-- Drag + hide
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

local function comboHit(keys, keycode)
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
        if comboHit(S.key_UI, io.KeyCode) or io.KeyCode==Enum.KeyCode.F2 or io.KeyCode==Enum.KeyCode.Insert or io.KeyCode==Enum.KeyCode.RightControl then
            toggleUI()
        elseif comboHit(S.key_Panic, io.KeyCode) then
            allOff(); UI.Enabled=false; HUD.Enabled=false
        elseif comboHit(S.key_ESP, io.KeyCode) then
            S.espOn=not S.espOn; if S.espOn then esp_enable() else esp_disable() end; refreshHUD()
        elseif comboHit(S.key_Fly, io.KeyCode) then
            S.flyOn=not S.flyOn; if S.flyOn then fly_enable() else fly_disable() end; refreshHUD()
        elseif comboHit(S.key_Clip, io.KeyCode) then
            S.noclipOn=not S.noclipOn; if S.noclipOn then noclip_enable() else noclip_disable() end; refreshHUD()
        end
    end
end)

-- autosave périodique (et très léger)
local saver=0; RS.Heartbeat:Connect(function(dt) saver+=dt; if saver>5 then saver=0; saveNow() end end)

-- ========== Splash (Solara-safe) ==========
local function showSplash(onClose)
    local okBlur, blur = pcall(function() local b=Instance.new("BlurEffect"); b.Size=0; b.Name="PH_Blur"; b.Parent=Lighting; return b end)
    if okBlur and blur then pcall(function() tween(blur,.25,{Size=18}):Play() end) end

    local Splash = Instance.new("ScreenGui"); Splash.Name="PH_Splash"; splashParent = best_ui_parent(); Splash.DisplayOrder=999999
    safeParent(Splash)

    local dim=Instance.new("Frame"); dim.BackgroundColor3=Color3.new(0,0,0); dim.BackgroundTransparency=.35; dim.Size=UDim2.fromScale(1,1); dim.Parent=Splash
    local panel=Instance.new("Frame"); panel.Size=UDim2.fromOffset(520,240); panel.AnchorPoint=Vector2.new(.5,.5); panel.Position=UDim2.fromScale(.5,.5); panel.BackgroundColor3=TH().card; panel.Parent=Splash
    Instance.new("UICorner",panel).CornerRadius=UDim.new(0,16)
    local banner=Instance.new("Frame"); banner.Size=UDim2.new(1,-24,0,54); banner.Position=UDim2.fromOffset(12,12); banner.BackgroundTransparency=.1; banner.Parent=panel
    pcall(function() local grad=Instance.new("UIGradient",banner); grad.Rotation=18; grad.Color=ColorSequence.new(ACCA(),ACCB()) end)
    banner.BackgroundColor3=TH().cardTop; Instance.new("UICorner",banner).CornerRadius=UDim.new(0,12)
    local hello=Instance.new("TextLabel"); hello.BackgroundTransparency=1; hello.Font=Enum.Font.GothamBlack; hello.TextSize=22; hello.TextColor3=TH().text; hello.TextXAlignment=Enum.TextXAlignment.Left
    hello.Text="👋 Bienvenue, "..(LP.DisplayName or LP.Name).." !"; hello.Position=UDim2.fromOffset(24,78); hello.Size=UDim2.fromOffset(460,28); hello.Parent=panel
    local gameName="le jeu"; pcall(function() gameName=MPS:GetProductInfo(game.PlaceId).Name end)
    local sub=Instance.new("TextLabel"); sub.BackgroundTransparency=1; sub.Font=Enum.Font.Gotham; sub.TextSize=14; sub.TextColor3=TH().muted; sub.TextXAlignment=Enum.TextXAlignment.Left
    sub.Text="Premium Hub prêt • Jeu : "..gameName.." • "..os.date("%H:%M"); sub.Position=UDim2.fromOffset(24,110); sub.Size=UDim2.fromOffset(470,22); sub.Parent=panel
    local tip=Instance.new("TextLabel"); tip.BackgroundTransparency=1; tip.Font=Enum.Font.Gotham; tip.TextSize=13; tip.TextColor3=TH().muted; tip.TextXAlignment=Enum.TextXAlignment.Left
    tip.Text='Astuce : ouvre l’UI avec "$" (⇧+4), F2, Insert ou RightCtrl.'; tip.Position=UDim2.fromOffset(24,138); tip.Size=UDim2.fromOffset(470,22); tip.Parent=panel
    local btn=Instance.new("TextButton"); btn.Size=UDim2.fromOffset(130,34); btn.AnchorPoint=Vector2.new(1,1); btn.Position=UDim2.new(1,-18,1,-16); btn.Text="Continuer →"
    btn.Font=Enum.Font.GothamSemibold; btn.TextSize=14; btn.TextColor3=TH().text; btn.BackgroundColor3=ACCA(); btn.AutoButtonColor=true; btn.Parent=panel; Instance.new("UICorner",btn).CornerRadius=UDim.new(0,10)

    panel.Size = UDim2.fromOffset(520,10); panel.ClipsDescendants=true; pcall(function() tween(panel,.25,{Size=UDim2.fromOffset(520,240)}):Play() end)

    local closed=false
    local function close()
        if closed then return end; closed=true
        pcall(function() tween(panel,.18,{Size=UDim2.fromOffset(520,10)}):Play() end)
        pcall(function() tween(dim,.18,{BackgroundTransparency=1}):Play() end)
        if okBlur and blur then pcall(function() tween(blur,.22,{Size=0}):Play() end) end
        task.delay(.22,function()
            pcall(function() if blur then blur:Destroy() end end)
            pcall(function() Splash:Destroy() end)
            if onClose then onClose() end
        end)
    end
    btn.MouseButton1Click:Connect(close)
    UIS.InputBegan:Connect(function(io,gp) if gp then return end; if io.UserInputType==Enum.UserInputType.Keyboard and (io.KeyCode==Enum.KeyCode.Space or io.KeyCode==Enum.KeyCode.Return or io.KeyCode==Enum.KeyCode.KeypadEnter or io.KeyCode==Enum.KeyCode.Escape) then close() end end)
    task.delay(2.6, close)
end

-- ========= Boot + watchdog =========
local function boot()
    UI.Enabled=true
    HUD.Enabled=S.hudOn
    applyOpacity()
    refreshHUD()
    print("[Premium Hub v6.4] prêt.")
    pcall(function() StarterGui:SetCore("SendNotification",{Title="Premium Hub", Text="v6.4 chargé (Solara-safe).", Duration=2}) end)
end

local function hardFailFallback()
    -- Si quoi que ce soit merde (Solara bloquant un effet), on ouvre direct le Hub
    print("[Premium Hub v6.4] Fallback boot.")
    boot()
end

local function start()
    -- évite les doubles boots
    if _G.__PREMIUM_HUB_RUNNING then return end
    _G.__PREMIUM_HUB_RUNNING = true
    if S.showSplash then
        local ok = pcall(function() showSplash(boot) end)
        if not ok then hardFailFallback() end
        -- watchdog: si le menu n'est pas visible après 3s, on force
        task.delay(3.2, function()
            if not UI.Enabled then hardFailFallback() end
        end)
    else
        boot()
    end
end

start()


if S.showSplash then showSplash(boot) else boot() end
