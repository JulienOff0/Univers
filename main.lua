--[[ 
Premium Hub v7 (ASCII only)
- Splash 7s -> Hub
- Speed (anti-reset)
- Fly (clean exit, no face-plant)
- Light (no fog/shadows)
- ESP (highlight + selection box + name + distance, role/team colors, live)
- Hitbox HRP (size slider)
- TP Player (dropdown + refresh + G hotkey)
- NoClip (reversible, respawn safe)
- Infinite Jump (boost)
- Mini HUD + keybinds + autosave + panic + drag clamped
- All connections tracked and disconnected on feature stop/respawn
- No UTF-8, no emojis -> avoids parser bugs on some executors
]]]

-- ===== utilities / guards
pcall(function()
  local P = game:GetService("Players").LocalPlayer
  local roots = {}
  local okCore, core = pcall(function() return game:GetService("CoreGui") end)
  if gethui then local ok, h = pcall(gethui); if ok and h then table.insert(roots, h) end end
  if okCore and core then table.insert(roots, core) end
  if P and P:FindFirstChild("PlayerGui") then table.insert(roots, P.PlayerGui) end
  local names = { "PHV7_ASCII","PHV7_SPLASH","PHV7_HUD","PHV7_UI","PremiumHubV7" }
  for _,root in ipairs(roots) do
    for _,n in ipairs(names) do
      pcall(function() if root:FindFirstChild(n) then root[n]:Destroy() end end)
    end
  end
end)

local Players  = game:GetService("Players")
local RS       = game:GetService("RunService")
local UIS      = game:GetService("UserInputService")
local TS       = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Http     = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local MPS      = game:GetService("MarketplaceService")
local LP       = Players.LocalPlayer

local function bestParent()
  if gethui then local ok,h = pcall(gethui); if ok and h then return h end end
  local okCore, core = pcall(function() return game:GetService("CoreGui") end)
  return okCore and core or LP:WaitForChild("PlayerGui")
end

local function safeParent(gui)
  gui.ResetOnSpawn = false
  gui.IgnoreGuiInset = true
  gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
  pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
  gui.Parent = bestParent()
end

local function tween(o,t,props) return TS:Create(o, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props) end
local function disc(c) if c then pcall(function() c:Disconnect() end) end end
local function discAll(tab) for i=#tab,1,-1 do disc(tab[i]); tab[i]=nil end end
local function char() return LP.Character or LP.CharacterAdded:Wait() end
local function hum()  return (char()):WaitForChild("Humanoid") end

-- ===== splash (7 s)
local function splash7(onClose)
  local blur = Instance.new("BlurEffect"); blur.Size=0; blur.Name="PHV7_BLUR"; blur.Parent=Lighting
  tween(blur,.18,{Size=18}):Play()

  local G = Instance.new("ScreenGui"); G.Name="PHV7_SPLASH"; safeParent(G)
  local bg = Instance.new("Frame"); bg.BackgroundColor3=Color3.new(0,0,0); bg.BackgroundTransparency=.35; bg.Size=UDim2.fromScale(1,1); bg.Parent=G
  local box = Instance.new("Frame"); box.Size=UDim2.fromOffset(520,10); box.AnchorPoint=Vector2.new(.5,.5); box.Position=UDim2.fromScale(.5,.5)
  box.BackgroundColor3=Color3.fromRGB(24,26,32); box.Parent=G; Instance.new("UICorner",box).CornerRadius=UDim.new(0,16)

  local title = Instance.new("TextLabel"); title.BackgroundTransparency=1; title.Font=Enum.Font.GothamBlack; title.TextSize=22
  title.TextColor3=Color3.fromRGB(235,238,255); title.TextXAlignment=Enum.TextXAlignment.Left
  title.Text="Welcome, "..(LP.DisplayName or LP.Name); title.Position=UDim2.fromOffset(24,74); title.Size=UDim2.fromOffset(480,28); title.Parent=box

  local gname="this game"; pcall(function() gname=MPS:GetProductInfo(game.PlaceId).Name end)
  local sub = Instance.new("TextLabel"); sub.BackgroundTransparency=1; sub.Font=Enum.Font.Gotham; sub.TextSize=14; sub.TextXAlignment=Enum.TextXAlignment.Left
  sub.TextColor3=Color3.fromRGB(170,176,196); sub.Text="Loading Premium Hub v7 ... Game: "..gname
  sub.Position=UDim2.fromOffset(24,104); sub.Size=UDim2.fromOffset(480,20); sub.Parent=box

  local tip = Instance.new("TextLabel"); tip.BackgroundTransparency=1; tip.Font=Enum.Font.Gotham; tip.TextSize=13; tip.TextXAlignment=Enum.TextXAlignment.Left
  tip.TextColor3=Color3.fromRGB(170,176,196); tip.Text='Hint: toggle UI with "$" (Shift+4) / F2 / Insert / RightCtrl'
  tip.Position=UDim2.fromOffset(24,128); tip.Size=UDim2.fromOffset(480,18); tip.Parent=box

  local spin = Instance.new("ImageLabel"); spin.BackgroundTransparency=1; spin.Image="rbxassetid://1095708"
  spin.ImageColor3=Color3.fromRGB(120,170,255); spin.AnchorPoint=Vector2.new(1,1); spin.Position=UDim2.new(1,-18,1,-14); spin.Size=UDim2.fromOffset(28,28); spin.Parent=box

  tween(box,.22,{Size=UDim2.fromOffset(520,220)}):Play()
  local r=0; local c=RS.RenderStepped:Connect(function(dt) r=(r+dt*360)%360; spin.Rotation=r end)

  task.delay(7,function()
    tween(box,.18,{Size=UDim2.fromOffset(520,10)}):Play()
    tween(bg,.18,{BackgroundTransparency=1}):Play()
    task.delay(.20,function()
      disc(c); tween(blur,.18,{Size=0}):Play()
      task.delay(.20,function() pcall(function() blur:Destroy() end) end)
      pcall(function() G:Destroy() end)
      if onClose then onClose() end
    end)
  end)
end

-- ===== main hub
local function StartHub()
  if _G.__PHV7_RUNNING then return end
  _G.__PHV7_RUNNING = true

  -- storage (per-place)
  local FS = { ok = (writefile and readfile and isfile and makefolder) and true or false }
  FS.dir="PHV7_DATA"; FS.file=("%s/s_%d.json"):format(FS.dir, game.PlaceId)

  local function saveTbl(t)
    local ok,json = pcall(function() return Http:JSONEncode(t) end)
    if not ok then return end
    if FS.ok then
      pcall(function() if not isfolder(FS.dir) then makefolder(FS.dir) end end)
      pcall(function() writefile(FS.file, json) end)
    else
      shared.__PHV7_SAVE = json
    end
  end
  local function loadTbl()
    local raw
    if FS.ok and isfile(FS.file) then raw = pcall(function() return readfile(FS.file) end) and readfile(FS.file) or nil
    else raw = shared.__PHV7_SAVE end
    if raw then local ok,t = pcall(function() return Http:JSONDecode(raw) end); if ok and type(t)=="table" then return t end end
    return {}
  end

  local S = {
    ui=true, hud=true, scale=1.0, opacity=1.0, pos=nil,
    keyUI={"Shift","4"}, keyPanic={"RightAlt"}, keyESP={"F3"}, keyFly={"F4"}, keyClip={"F5"},

    speedOn=false, speed=22, minSpeed=16, maxSpeed=120, speedCon={hb=nil,prop=nil}, humanoid=nil, normal=nil,

    flyOn=false, flyAlive=false, flyCon={}, flyData=nil,

    lightOn=false, lightBackup=nil,

    espOn=false, espConn=nil, espHz=12, espNameUser=true, espRange=6000,

    hitOn=false, hitSize=10, hitConn=nil, hitOrig={},

    tpUser=nil, tpLabel=nil,

    clipOn=false, clipStep=nil, clipDesc=nil, clipOrig={},

    ijOn=false, ijBoost=55, ijConn=nil,
  }
  do local L=loadTbl(); for k,v in pairs(L) do if S[k]~=nil then S[k]=v end end end

  -- UI roots
  local UI = Instance.new("ScreenGui"); UI.Name="PHV7_UI"; safeParent(UI); UI.Enabled=false
  local HUD= Instance.new("ScreenGui"); HUD.Name="PHV7_HUD"; safeParent(HUD); HUD.Enabled=S.hud

  local F={}
  local function regAlpha(x) table.insert(F, x) end
  local function applyAlpha() for _,x in ipairs(F) do pcall(function() x.BackgroundTransparency = 1 - S.opacity end) end end

  -- window
  local Main = Instance.new("Frame"); Main.Size=UDim2.fromOffset(700,780); Main.BackgroundColor3=Color3.fromRGB(18,18,22); Main.BorderSizePixel=0; Main.Active=true; Main.Parent=UI
  do local vs=workspace.CurrentCamera.ViewportSize
    local x = S.pos and S.pos.x or math.floor(vs.X/2 - Main.Size.X.Offset/2)
    local y = S.pos and S.pos.y or math.floor(vs.Y/2 - Main.Size.Y.Offset/2)
    Main.Position=UDim2.fromOffset(x,y)
  end
  Instance.new("UICorner",Main).CornerRadius=UDim.new(0,18); regAlpha(Main)
  local sc=Instance.new("UIScale",Main); sc.Scale=S.scale

  -- header
  local Head=Instance.new("Frame"); Head.Size=UDim2.new(1,0,0,56); Head.BackgroundColor3=Color3.fromRGB(28,30,36); Head.BorderSizePixel=0; Head.Active=true; Head.Parent=Main
  Instance.new("UICorner",Head).CornerRadius=UDim.new(0,18); regAlpha(Head)

  local HTitle=Instance.new("TextLabel"); HTitle.BackgroundTransparency=1; HTitle.Font=Enum.Font.GothamBlack; HTitle.TextSize=22; HTitle.TextColor3=Color3.fromRGB(235,238,255)
  HTitle.TextXAlignment=Enum.TextXAlignment.Left; HTitle.Text="Premium Hub v7 - VIP"; HTitle.Position=UDim2.fromOffset(16,8); HTitle.Size=UDim2.fromOffset(420,40); HTitle.Parent=Head

  local HHint=Instance.new("TextLabel"); HHint.BackgroundTransparency=1; HHint.Font=Enum.Font.Gotham; HHint.TextSize=14; HHint.TextColor3=Color3.fromRGB(170,176,196)
  HHint.TextXAlignment=Enum.TextXAlignment.Right; HHint.Text='Hide: "$"(Shift+4) / F2 / Insert / RightCtrl'
  HHint.AnchorPoint=Vector2.new(1,0); HHint.Position=UDim2.new(1,-56,0,18); HHint.Size=UDim2.fromOffset(360,24); HHint.Parent=Head

  local Hide=Instance.new("TextButton"); Hide.AnchorPoint=Vector2.new(1,0); Hide.Position=UDim2.new(1,-12,0,10); Hide.Size=UDim2.fromOffset(36,36)
  Hide.Text="X"; Hide.TextSize=16; Hide.Font=Enum.Font.GothamBold; Hide.TextColor3=Color3.fromRGB(235,238,255); Hide.AutoButtonColor=false
  Hide.BackgroundColor3=Color3.fromRGB(60,60,70); Hide.Parent=Head; Instance.new("UICorner",Hide).CornerRadius=UDim.new(1,0); regAlpha(Hide)

  -- quick bar
  local Bar=Instance.new("Frame"); Bar.BackgroundColor3=Color3.fromRGB(28,30,36); Bar.BorderSizePixel=0; Bar.Size=UDim2.new(1,-32,0,42); Bar.Position=UDim2.fromOffset(16,62)
  Bar.Parent=Main; Instance.new("UICorner",Bar).CornerRadius=UDim.new(0,12); regAlpha(Bar)
  local ql=Instance.new("UIListLayout",Bar); ql.FillDirection=Enum.FillDirection.Horizontal; ql.Padding=UDim.new(0,8); ql.VerticalAlignment=Enum.VerticalAlignment.Center
  local function quick(txt,w,cb)
    local b=Instance.new("TextButton"); b.Size=UDim2.fromOffset(w,28); b.Text=txt; b.Font=Enum.Font.GothamSemibold; b.TextSize=14; b.TextColor3=Color3.fromRGB(235,238,255)
    b.BackgroundColor3=Color3.fromRGB(60,60,70); b.AutoButtonColor=false; b.Parent=Bar; Instance.new("UICorner",b).CornerRadius=UDim.new(0,8); regAlpha(b)
    b.MouseEnter:Connect(function() tween(b,.12,{BackgroundColor3=Color3.fromRGB(80,110,240)}):Play() end)
    b.MouseLeave:Connect(function() tween(b,.12,{BackgroundColor3=Color3.fromRGB(60,60,70)}):Play() end)
    b.MouseButton1Click:Connect(cb)
  end

  -- content
  local Content=Instance.new("ScrollingFrame"); Content.Position=UDim2.fromOffset(16,110); Content.Size=UDim2.new(1,-32,1,-126)
  Content.CanvasSize=UDim2.new(0,0,0,0); Content.ScrollBarThickness=6; Content.BackgroundTransparency=1; Content.Parent=Main
  local vlist=Instance.new("UIListLayout",Content); vlist.Padding=UDim.new(0,12); vlist.SortOrder=Enum.SortOrder.LayoutOrder
  vlist:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() Content.CanvasSize=UDim2.new(0,0,0,vlist.AbsoluteContentSize.Y+8) end)

  -- HUD
  local H=Instance.new("Frame"); H.Size=UDim2.fromOffset(250,26); H.Position=UDim2.fromOffset(12,12); H.BackgroundColor3=Color3.fromRGB(28,30,36); H.Parent=HUD
  Instance.new("UICorner",H).CornerRadius=UDim.new(0,8)
  local HT=Instance.new("TextLabel"); HT.BackgroundTransparency=1; HT.Font=Enum.Font.GothamSemibold; HT.TextSize=14; HT.TextXAlignment=Enum.TextXAlignment.Left; HT.TextColor3=Color3.fromRGB(235,238,255)
  HT.Text="Speed:off  Fly:off  ESP:off  Clip:off"; HT.Size=UDim2.new(1,-10,1,0); HT.Position=UDim2.fromOffset(8,0); HT.Parent=H
  local function hud() HT.Text=string.format("Speed:%s  Fly:%s  ESP:%s  Clip:%s", S.speedOn and "on" or "off", S.flyOn and "on" or "off", S.espOn and "on" or "off", S.clipOn and "on" or "off") end
  hud()

  -- builders
  local function section(title,sub)
    local Card=Instance.new("Frame"); Card.Size=UDim2.new(1,0,0,0); Card.AutomaticSize=Enum.AutomaticSize.Y; Card.BackgroundColor3=Color3.fromRGB(22,24,29); Card.BorderSizePixel=0; Card.Active=true; Card.Parent=Content
    Instance.new("UICorner",Card).CornerRadius=UDim.new(0,14); regAlpha(Card)
    local Top=Instance.new("Frame"); Top.BackgroundColor3=Color3.fromRGB(28,30,36); Top.BorderSizePixel=0; Top.Size=UDim2.new(1,0,0,46); Top.Parent=Card
    Instance.new("UICorner",Top).CornerRadius=UDim.new(0,14); regAlpha(Top)
    local T=Instance.new("TextLabel"); T.BackgroundTransparency=1; T.Font=Enum.Font.GothamSemibold; T.TextSize=16; T.TextXAlignment=Enum.TextXAlignment.Left; T.TextColor3=Color3.fromRGB(235,238,255); T.Text=title; T.Position=UDim2.fromOffset(12,8); T.Size=UDim2.fromOffset(460,20); T.Parent=Top
    local ST=Instance.new("TextLabel"); ST.BackgroundTransparency=1; ST.Font=Enum.Font.Gotham; ST.TextSize=13; ST.TextXAlignment=Enum.TextXAlignment.Left; ST.TextColor3=Color3.fromRGB(170,176,196); ST.Text=sub or ""; ST.Position=UDim2.fromOffset(12,24); ST.Size=UDim2.fromOffset(580,18); ST.Parent=Top
    local Body=Instance.new("Frame"); Body.BackgroundTransparency=1; Body.Position=UDim2.fromOffset(0,46); Body.Size=UDim2.new(1,0,0,0); Body.AutomaticSize=Enum.AutomaticSize.Y; Body.Parent=Card
    local Pad=Instance.new("UIPadding",Body); Pad.PaddingLeft=UDim.new(0,12); Pad.PaddingRight=UDim.new(0,12); Pad.PaddingTop=UDim.new(0,10); Pad.PaddingBottom=UDim.new(0,12)
    return Card,Body
  end
  local function toggle(parent,label,default)
    local Row=Instance.new("Frame"); Row.BackgroundTransparency=1; Row.Size=UDim2.new(1,0,0,34); Row.Parent=parent
    local L=Instance.new("TextLabel"); L.BackgroundTransparency=1; L.Font=Enum.Font.Gotham; L.TextSize=14; L.TextXAlignment=Enum.TextXAlignment.Left; L.TextColor3=Color3.fromRGB(235,238,255); L.Text=label; L.Position=UDim2.fromOffset(0,8); L.Size=UDim2.fromOffset(380,18); L.Parent=Row
    local Btn=Instance.new("TextButton"); Btn.AutoButtonColor=false; Btn.AnchorPoint=Vector2.new(1,0); Btn.Position=UDim2.new(1,-2,0,4); Btn.Size=UDim2.fromOffset(74,26)
    Btn.BackgroundColor3= default and Color3.fromRGB(58,116,255) or Color3.fromRGB(60,60,70); Btn.Text=""; Btn.Parent=Row; Instance.new("UICorner",Btn).CornerRadius=UDim.new(1,0); regAlpha(Btn)
    local Knob=Instance.new("Frame"); Knob.Size=UDim2.fromOffset(24,24); Knob.Position= default and UDim2.fromOffset(48,1) or UDim2.fromOffset(2,1); Knob.BackgroundColor3=Color3.fromRGB(28,30,36); Knob.Parent=Btn; Instance.new("UICorner",Knob).CornerRadius=UDim.new(1,0); regAlpha(Knob)
    local function set(on) tween(Btn,.16,{BackgroundColor3= on and Color3.fromRGB(58,116,255) or Color3.fromRGB(60,60,70)}):Play(); tween(Knob,.16,{Position= on and UDim2.fromOffset(48,1) or UDim2.fromOffset(2,1)}):Play() end
    return set, Btn
  end
  local function slider(parent,label,minV,maxV,defaultV,fmt)
    local Row=Instance.new("Frame"); Row.BackgroundTransparency=1; Row.Size=UDim2.new(1,0,0,58); Row.Parent=parent
    local T=Instance.new("TextLabel"); T.BackgroundTransparency=1; T.Font=Enum.Font.Gotham; T.TextSize=14; T.TextXAlignment=Enum.TextXAlignment.Left; T.TextColor3=Color3.fromRGB(235,238,255)
    local function format(v) return fmt and fmt(v) or tostring(v) end
    T.Text=string.format("%s: %s",label,format(defaultV)); T.Position=UDim2.fromOffset(0,2); T.Size=UDim2.fromOffset(420,18); T.Parent=Row
    local Track=Instance.new("Frame"); Track.BackgroundColor3=Color3.fromRGB(46,50,65); Track.BorderSizePixel=0; Track.Position=UDim2.fromOffset(0,28); Track.Size=UDim2.new(1,-2,0,10); Track.Parent=Row; Instance.new("UICorner",Track).CornerRadius=UDim.new(0,6); regAlpha(Track)
    local Fill=Instance.new("Frame"); Fill.BackgroundColor3=Color3.fromRGB(58,116,255); Fill.BorderSizePixel=0; Fill.Size=UDim2.fromOffset(0,10); Fill.Parent=Track; Instance.new("UICorner",Fill).CornerRadius=UDim.new(0,6)
    local Knob=Instance.new("Frame"); Knob.Size=UDim2.fromOffset(16,16); Knob.Position=UDim2.fromOffset(-8,-3); Knob.BackgroundColor3=Color3.fromRGB(28,30,36); Knob.Parent=Fill; Instance.new("UICorner",Knob).CornerRadius=UDim.new(1,0); regAlpha(Knob)
    local dragging=false; local current=defaultV
    local function setFrom(px)
      local abs=Track.AbsoluteSize.X; local rel=math.clamp(px/abs,0,1)
      local val=math.floor(minV + (maxV-minV)*rel + .5)
      local w=math.floor(abs*rel + .5)
      Fill.Size=UDim2.fromOffset(w,10); Knob.Position=UDim2.fromOffset(w-8,-3)
      T.Text=string.format("%s: %s",label,format(val)); current=val
    end
    RS.Heartbeat:Wait(); local rel=(defaultV-minV)/(maxV-minV); setFrom(Track.AbsoluteSize.X*rel)
    Track.InputBegan:Connect(function(io) if io.UserInputType==Enum.UserInputType.MouseButton1 or io.UserInputType==Enum.UserInputType.Touch then dragging=true; setFrom(io.Position.X-Track.AbsolutePosition.X) end end)
    UIS.InputChanged:Connect(function(io) if dragging and (io.UserInputType==Enum.UserInputType.MouseMovement or io.UserInputType==Enum.UserInputType.Touch) then setFrom(io.Position.X-Track.AbsolutePosition.X) end end)
    UIS.InputEnded:Connect(function(io) if io.UserInputType==Enum.UserInputType.MouseButton1 or io.UserInputType==Enum.UserInputType.Touch then dragging=false end end)
    return function() return current end
  end

  -- ===== features

  -- Speed
  local function speed_on()
    S.humanoid = hum(); S.normal = S.humanoid.WalkSpeed
    disc(S.speedCon.hb); disc(S.speedCon.prop)
    S.speedCon.hb = RS.Heartbeat:Connect(function()
      if S.speedOn and S.humanoid and S.humanoid.Parent and S.humanoid.WalkSpeed ~= S.speed then
        S.humanoid.WalkSpeed = S.speed
      end
    end)
    S.speedCon.prop = S.humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
      if S.speedOn and S.humanoid.WalkSpeed ~= S.speed then S.humanoid.WalkSpeed = S.speed end
    end)
  end
  local function speed_off()
    disc(S.speedCon.hb); S.speedCon.hb=nil
    disc(S.speedCon.prop); S.speedCon.prop=nil
    local h = S.humanoid or (char():FindFirstChildOfClass("Humanoid"))
    if h then h.WalkSpeed = S.normal or 16 end
  end
  LP.CharacterAdded:Connect(function() if S.speedOn then task.wait(.3); speed_on() end end)

  -- Fly
  local function fly_off()
    S.flyAlive=false; discAll(S.flyCon)
    if not S.flyData then return end
    local d=S.flyData; S.flyData=nil
    pcall(function() if d.lv then d.lv:Destroy() end end)
    pcall(function() if d.att then d.att:Destroy() end end)
    if d.coll then for part,can in pairs(d.coll) do if part and part.Parent then part.CanCollide=can end end end
    if d.hrp then d.hrp.AssemblyAngularVelocity=Vector3.zero; d.hrp.AssemblyLinearVelocity=Vector3.zero; d.hrp.CFrame=d.hrp.CFrame + Vector3.new(0,0.05,0) end
    if d.ctrl then pcall(function() d.ctrl:Enable() end) end
    if d.hum then
      d.hum.AutoRotate=true; d.hum.PlatformStand=false; d.hum.Sit=false
      pcall(function() d.hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
      task.delay(0.05,function() if d.hum and d.hum.Parent then pcall(function() d.hum:ChangeState(Enum.HumanoidStateType.Running) end) end end)
    end
  end
  local function fly_on()
    fly_off()
    local c=char(); local hrp=c:WaitForChild("HumanoidRootPart"); local h= c:WaitForChild("Humanoid")
    S.flyAlive=true
    local ctrl=nil; pcall(function() local ps=LP:WaitForChild("PlayerScripts"); local ok,PM=pcall(function() return require(ps:WaitForChild("PlayerModule")) end); if ok and PM then ctrl=PM:GetControls(); if ctrl then ctrl:Disable() end end end)
    h.AutoRotate=false; h:ChangeState(Enum.HumanoidStateType.Physics); h.PlatformStand=true
    local coll={}; for _,d in ipairs(c:GetDescendants()) do if d:IsA("BasePart") then coll[d]=d.CanCollide; d.CanCollide=false end end
    table.insert(S.flyCon, c.DescendantAdded:Connect(function(d) if d:IsA("BasePart") then coll[d]=d.CanCollide; d.CanCollide=false end end))
    local att=Instance.new("Attachment"); att.Parent=hrp
    local lv=Instance.new("LinearVelocity"); lv.Attachment0=att; lv.MaxForce=math.huge; lv.RelativeTo=Enum.ActuatorRelativeTo.World; lv.Parent=hrp
    S.flyData={hrp=hrp,hum=h,lv=lv,att=att,ctrl=ctrl,coll=coll}
    table.insert(S.flyCon, h:GetPropertyChangedSignal("PlatformStand"):Connect(function() if S.flyAlive and h.PlatformStand~=true then h.PlatformStand=true end end))
    table.insert(S.flyCon, RS.Stepped:Connect(function() if S.flyAlive then hrp.AssemblyAngularVelocity=Vector3.zero end end))
    table.insert(S.flyCon, RS.RenderStepped:Connect(function()
      if not S.flyAlive then return end
      local cam=workspace.CurrentCamera; if not cam then return end
      local look=cam.CFrame.LookVector
      local yaw=Vector3.new(look.X,0,look.Z); if yaw.Magnitude<1e-3 then yaw=Vector3.zAxis else yaw=yaw.Unit end
      hrp.CFrame=CFrame.lookAt(hrp.Position, hrp.Position+yaw, Vector3.yAxis)
      local right=Vector3.new(cam.CFrame.RightVector.X,0,cam.CFrame.RightVector.Z); right=(right.Magnitude>0) and right.Unit or Vector3.new(-yaw.Z,0,yaw.X)
      local f,r=0,0
      if UIS:IsKeyDown(Enum.KeyCode.W) then f+=1 end
      if UIS:IsKeyDown(Enum.KeyCode.S) then f-=1 end
      if UIS:IsKeyDown(Enum.KeyCode.D) then r+=1 end
      if UIS:IsKeyDown(Enum.KeyCode.A) then r-=1 end
      local SPEED,VERT,DEAD=65,45,0.08
      local horiz=yaw*f + right*r; if horiz.Magnitude>0 then horiz=horiz.Unit*SPEED else horiz=Vector3.zero end
      local vert=0; if f~=0 then local pitch=look.Y; if math.abs(pitch)>DEAD then vert=pitch*VERT*f end end
      lv.VectorVelocity=Vector3.new(horiz.X,vert,horiz.Z)
    end))
    table.insert(S.flyCon, h.Died:Connect(fly_off))
  end

  -- Light
  local LPRE={ GlobalShadows=false, FogEnd=100000, Brightness=2, Ambient=Color3.fromRGB(150,150,150) }
  local function light_on() if not S.lightBackup then S.lightBackup={GlobalShadows=Lighting.GlobalShadows, FogEnd=Lighting.FogEnd, Brightness=Lighting.Brightness, Ambient=Lighting.Ambient} end
    Lighting.GlobalShadows=LPRE.GlobalShadows; Lighting.FogEnd=LPRE.FogEnd; Lighting.Brightness=LPRE.Brightness; Lighting.Ambient=LPRE.Ambient end
  local function light_off() if S.lightBackup then Lighting.GlobalShadows=S.lightBackup.GlobalShadows; Lighting.FogEnd=S.lightBackup.FogEnd; Lighting.Brightness=S.lightBackup.Brightness; Lighting.Ambient=S.lightBackup.Ambient end end

  -- ESP (optimized)
  local ROLE = { Murder=Color3.fromRGB(255,60,60), Murderer=Color3.fromRGB(255,60,60), Innocent=Color3.fromRGB(64,128,255), Sheriff=Color3.fromRGB(255,220,0), Detective=Color3.fromRGB(255,220,0) }
  local DEF  = Color3.fromRGB(200,200,200)
  local function roleOf(p,c) local r=p:GetAttribute("Role"); if r==nil and c then r=c:GetAttribute("Role") end; return (typeof(r)=="string") and r or nil end
  local function colFor(p,c) local r=roleOf(p,c); if r and ROLE[r] then return ROLE[r] end; if p.Team and p.Team.TeamColor then return p.Team.TeamColor.Color end; return DEF end
  local function adorn(char) return char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildWhichIsA("BasePart") end
  local function eq(a,b) return a and b and a.r==b.r and a.g==b.g and a.b==b.b end

  local REG = {} -- [Player] => { char, hl, box, bb, name, dist, lastName, lastDist, lastCol, conns={} }
  local function buildESP(p,c)
    if not c or p==LP then return end
    local r=REG[p]; if not r then r={conns={}}; REG[p]=r else discAll(r.conns) end
    r.char=c
    local hl=c:FindFirstChild("PHV7_HL"); if not hl then hl=Instance.new("Highlight"); hl.Name="PHV7_HL"; hl.FillTransparency=1; hl.OutlineTransparency=0; hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; hl.Parent=c end
    r.hl=hl
    local box=c:FindFirstChild("PHV7_BOX"); if not box then box=Instance.new("SelectionBox"); box.Name="PHV7_BOX"; box.LineThickness=0.02; box.SurfaceTransparency=1; pcall(function() box.Adornee=c end); box.Parent=c end
    r.box=box
    for _,d in ipairs(c:GetDescendants()) do if d:IsA("BillboardGui") and d.Name=="PHV7_TAG" then d:Destroy() end end
    local bb=Instance.new("BillboardGui"); bb.Name="PHV7_TAG"; bb.Size=UDim2.new(0,220,0,44); bb.StudsOffset=Vector3.new(0,3,0); bb.AlwaysOnTop=true; bb.MaxDistance=5000
    local head=adorn(c); bb.Parent=(head and head:IsA("BasePart")) and head or (c:FindFirstChild("HumanoidRootPart") or c)
    local nm=Instance.new("TextLabel"); nm.Name="Name"; nm.BackgroundTransparency=1; nm.Size=UDim2.new(1,0,0.5,0); nm.Font=Enum.Font.GothamBold; nm.TextScaled=true; nm.TextStrokeTransparency=.5; nm.Parent=bb
    local di=Instance.new("TextLabel"); di.Name="Dist"; di.BackgroundTransparency=1; di.Position=UDim2.new(0,0,0.5,0); di.Size=UDim2.new(1,0,0.5,0); di.Font=Enum.Font.Gotham; di.TextScaled=true; di.TextStrokeTransparency=.5; di.Parent=bb
    r.bb, r.name, r.dist = bb, nm, di; r.lastName="", r.lastDist=-1; r.lastCol=nil
    table.insert(r.conns, c.DescendantAdded:Connect(function(d) if d.Name=="Head" and d:IsA("BasePart") and r.bb and r.bb.Parent~=d then r.bb.Parent=d end end))
    table.insert(r.conns, c.AncestryChanged:Connect(function(_,par) if par==nil then discAll(r.conns) end end))
  end
  local function ensureESP(p) local c=p.Character; if not c then return end; local r=REG[p]; if not r or r.char~=c or not r.bb or not r.hl or not r.box then buildESP(p,c) end end
  local function esp_tick()
    local mc=LP.Character; if not mc then return end
    local my=mc:FindFirstChild("HumanoidRootPart"); if not my then return end
    for _,p in ipairs(Players:GetPlayers()) do
      if p~=LP then
        ensureESP(p)
        local r=REG[p]; local c=p.Character
        if r and c and r.bb and r.hl and r.box then
          local hrp=c:FindFirstChild("HumanoidRootPart")
          if not hrp then r.bb.Enabled=false; r.hl.Enabled=false; r.box.Visible=false
          else
            local d=(my.Position-hrp.Position).Magnitude
            if d > S.espRange then r.bb.Enabled=false; r.hl.Enabled=false; r.box.Visible=false
            else
              local col=colFor(p,c)
              if not eq(r.lastCol,col) then r.lastCol=col; r.hl.OutlineColor=col; pcall(function() r.box.LineColor3=col end); r.name.TextColor3=col; r.dist.TextColor3=col end
              local disp=(p.DisplayName and p.DisplayName~="") and p.DisplayName or p.Name
              local want = S.espNameUser and (disp.." (@"..p.Name..")") or disp
              if r.lastName~=want then r.name.Text=want; r.lastName=want end
              local di=(d>=0) and math.floor(d+0.5) or 0
              if r.lastDist~=di then r.dist.Text=tostring(di).." studs"; r.lastDist=di end
              r.bb.Enabled=true; r.hl.Enabled=true; r.box.Visible=true
              if r.bb.Parent==r.char or (not r.bb.Parent) or (not r.bb.Parent.Parent) then local h=adorn(c); if h then r.bb.Parent=h end end
            end
          end
        end
      end
    end
  end
  local function esp_on()
    if S.espConn then return end
    for _,pl in ipairs(Players:GetPlayers()) do if pl~=LP and pl.Character then buildESP(pl,pl.Character) end end
    local acc=0; S.espConn=RS.Heartbeat:Connect(function(dt) acc+=dt; if acc>=(1/math.max(1,S.espHz)) then esp_tick(); acc=0 end end)
    Players.PlayerAdded:Connect(function(p) p.CharacterAdded:Connect(function(c) task.wait(.2); buildESP(p,c) end); if p.Character then buildESP(p,p.Character) end end)
  end
  local function esp_off() disc(S.espConn); S.espConn=nil; for _,r in pairs(REG) do if r.bb then r.bb.Enabled=false end; if r.hl then r.hl.Enabled=false end; if r.box then r.box.Visible=false end end end

  -- Hitbox
  local function remember(hrp) if not hrp or S.hitOrig[hrp] then return end S.hitOrig[hrp]={Size=hrp.Size,Transparency=hrp.Transparency,Material=hrp.Material,CanCollide=hrp.CanCollide,BrickColor=hrp.BrickColor} end
  local function applyHB(hrp) if not hrp then return end remember(hrp); hrp.Size=Vector3.new(S.hitSize,S.hitSize,S.hitSize); hrp.Transparency=.7; hrp.BrickColor=BrickColor.new("Really red"); hrp.Material=Enum.Material.Neon; hrp.CanCollide=false end
  local function restoreHB() for hrp,orig in pairs(S.hitOrig) do if hrp and hrp.Parent and orig then pcall(function() hrp.Size=orig.Size; hrp.Transparency=orig.Transparency; hrp.Material=orig.Material; hrp.CanCollide=orig.CanCollide; hrp.BrickColor=orig.BrickColor end) end end S.hitOrig={} end
  local function hb_loop() for _,pl in ipairs(Players:GetPlayers()) do if pl~=LP and pl.Character then local hrp=pl.Character:FindFirstChild("HumanoidRootPart"); if hrp then pcall(applyHB,hrp) end end end end
  local function hb_on() if S.hitConn then return end; hb_loop(); S.hitConn=RS.RenderStepped:Connect(function() if S.hitOn then hb_loop() end end); Players.PlayerAdded:Connect(function(p) p.CharacterAdded:Connect(function(c) task.wait(.1); local hrp=c:FindFirstChild("HumanoidRootPart"); if hrp then remember(hrp) end end) end) end
  local function hb_off() disc(S.hitConn); S.hitConn=nil; restoreHB() end

  -- NoClip
  local function clip_cache(inst) if inst:IsA("BasePart") and S.clipOrig[inst]==nil then S.clipOrig[inst]=inst.CanCollide end end
  local function clip_cacheChar(c) for _,d in ipairs(c:GetDescendants()) do clip_cache(d) end; disc(S.clipDesc); S.clipDesc=c.DescendantAdded:Connect(clip_cache) end
  local function clip_apply(c) for part,_ in pairs(S.clipOrig) do if part.Parent and part:IsDescendantOf(c) then part.CanCollide=false end end end
  local function clip_on() local c=char(); S.clipOrig={}; clip_cacheChar(c); disc(S.clipStep); S.clipStep=RS.Stepped:Connect(function() clip_apply(c) end) end
  local function clip_off() disc(S.clipStep); S.clipStep=nil; disc(S.clipDesc); S.clipDesc=nil; for part,can in pairs(S.clipOrig) do if part and part.Parent then part.CanCollide=can end end; S.clipOrig={} end
  LP.CharacterAdded:Connect(function(c) if S.clipOn then clip_on() end end)

  -- Infinite Jump
  local function ij_bind(c)
    local h=c:WaitForChild("Humanoid"); local r=c:WaitForChild("HumanoidRootPart")
    h.UseJumpPower=true
    disc(S.ijConn)
    S.ijConn=UIS.JumpRequest:Connect(function()
      if not S.ijOn then return end
      if h.Health<=0 or h:GetState()==Enum.HumanoidStateType.Dead then return end
      local v=r.AssemblyLinearVelocity
      r.AssemblyLinearVelocity=Vector3.new(v.X, math.max(S.ijBoost,0), v.Z)
      h:ChangeState(Enum.HumanoidStateType.Jumping)
    end)
  end
  if LP.Character then ij_bind(LP.Character) end
  LP.CharacterAdded:Connect(function(c) if S.ijOn then ij_bind(c) end end)

  -- TP
  local function HRP(c) return c and c:FindFirstChild("HumanoidRootPart") end
  local function tpTo(uid)
    local me, t = LP, Players:GetPlayerByUserId(uid)
    if not (me and me.Character and t and t.Character) then return end
    local mh, th = HRP(me.Character), HRP(t.Character); if not (mh and th) then return end
    me.Character:PivotTo(th.CFrame * CFrame.new(0,0,3))
  end
  local function others() local a={}; for _,p in ipairs(Players:GetPlayers()) do if p~=LP then table.insert(a,p) end end; table.sort(a,function(x,y) local ax=(x.DisplayName~="" and x.DisplayName) or x.Name; local ay=(y.DisplayName~="" and y.DisplayName) or y.Name; return ax:lower()<ay:lower() end); return a end

  -- ===== sections

  -- Appearance + keybinds
  do
    local _,B=section("Appearance and UI","Scale, opacity, HUD, keybinds")
    local gS=slider(B,"UI Scale",80,120,math.floor(S.scale*100),function(v)return v.."%" end)
    local gO=slider(B,"Opacity",70,100,math.floor(S.opacity*100),function(v)return v.."%" end)
    RS.Heartbeat:Connect(function() S.scale=gS()/100; sc.Scale=S.scale; S.opacity=gO()/100; applyAlpha() end)
    local setHUD,bHUD=toggle(B,"Mini HUD",S.hud); bHUD.MouseButton1Click:Connect(function() S.hud=not S.hud; HUD.Enabled=S.hud; setHUD(S.hud) end)

    local function bind(label,keys,apply)
      local Row=Instance.new("Frame"); Row.BackgroundTransparency=1; Row.Size=UDim2.new(1,0,0,38); Row.Parent=B
      local L=Instance.new("TextLabel"); L.BackgroundTransparency=1; L.Font=Enum.Font.Gotham; L.TextSize=14; L.TextXAlignment=Enum.TextXAlignment.Left; L.TextColor3=Color3.fromRGB(235,238,255)
      L.Text=label; L.Position=UDim2.fromOffset(0,8); L.Size=UDim2.fromOffset(240,18); L.Parent=Row
      local Btn=Instance.new("TextButton"); Btn.Size=UDim2.fromOffset(180,28); Btn.Position=UDim2.new(0,250,0,4); Btn.BackgroundColor3=Color3.fromRGB(60,60,70); Btn.AutoButtonColor=false
      Btn.TextColor3=Color3.fromRGB(235,238,255); Btn.TextSize=14; Btn.Font=Enum.Font.GothamSemibold; Btn.Parent=Row; Instance.new("UICorner",Btn).CornerRadius=UDim.new(0,8); regAlpha(Btn)
      local function show() Btn.Text="["..(type(keys)=="table" and table.concat(keys," + ") or tostring(keys)).."]" end
      show()
      local wait=false
      Btn.MouseButton1Click:Connect(function() Btn.Text="... press key ..."; wait=true end)
      UIS.InputBegan:Connect(function(io,gp)
        if not wait or gp or io.UserInputType~=Enum.UserInputType.Keyboard then return end
        wait=false
        if (UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift)) and io.KeyCode==Enum.KeyCode.Four then keys={"Shift","4"}
        else keys={io.KeyCode.Name} end
        apply(keys); show()
      end)
    end
    bind("Toggle UI", S.keyUI, function(k) S.keyUI=k end)
    bind("Panic (all off)", S.keyPanic, function(k) S.keyPanic=k end)
    bind("Toggle ESP", S.keyESP, function(k) S.keyESP=k end)
    bind("Toggle Fly", S.keyFly, function(k) S.keyFly=k end)
    bind("Toggle NoClip", S.keyClip, function(k) S.keyClip=k end)
  end

  -- Speed
  do local _,B=section("Speed","Keep walkspeed, anti reset")
    local set,btn=toggle(B,"Enable Speed",S.speedOn)
    local g=slider(B,"Speed value",S.minSpeed,S.maxSpeed,S.speed,function(v)return v end)
    btn.MouseButton1Click:Connect(function() S.speed=g(); S.speedOn=not S.speedOn; set(S.speedOn); if S.speedOn then speed_on() else speed_off() end; hud() end)
    RS.Heartbeat:Connect(function() S.speed=g() end)
  end

  -- Fly
  do local _,B=section("Fly","Smooth fly (WASD/ZQSD + camera tilt), clean exit")
    local set,btn=toggle(B,"Enable Fly",S.flyOn)
    btn.MouseButton1Click:Connect(function() S.flyOn=not S.flyOn; set(S.flyOn); if S.flyOn then fly_on() else fly_off() end; hud() end)
  end

  -- Light
  do local _,B=section("Light","No shadows, no fog, brighter scene")
    local set,btn=toggle(B,"Enable Light",S.lightOn)
    btn.MouseButton1Click:Connect(function() S.lightOn=not S.lightOn; set(S.lightOn); if S.lightOn then light_on() else light_off() end end)
  end

  -- ESP
  do local _,B=section("ESP Player","Aura + box + name + distance (role/team colors, live)")
    local set,btn=toggle(B,"Enable ESP",S.espOn)
    local setU,ub=toggle(B,"Show @username",S.espNameUser); ub.MouseButton1Click:Connect(function() S.espNameUser=not S.espNameUser; setU(S.espNameUser) end)
    local gHz=slider(B,"Refresh per second",4,30,S.espHz,function(v)return v end)
    local gRg=slider(B,"Range (studs)",200,6000,S.espRange,function(v)return v end)
    RS.Heartbeat:Connect(function() S.espHz=gHz(); S.espRange=gRg() end)
    btn.MouseButton1Click:Connect(function() S.espOn=not S.espOn; set(S.espOn); if S.espOn then esp_on() else esp_off() end; hud() end)
  end

  -- Hitbox
  do local _,B=section("Hitbox (HRP)","Grow HRP of other players (client side)")
    local set,btn=toggle(B,"Enable Hitbox",S.hitOn)
    local g=slider(B,"Size",2,30,S.hitSize,function(v)return v end)
    RS.Heartbeat:Connect(function() S.hitSize=g() end)
    btn.MouseButton1Click:Connect(function() S.hitOn=not S.hitOn; set(S.hitOn); if S.hitOn then hb_on() else hb_off() end end)
  end

  -- TP
  do local _,B=section("TP Player","Choose a player then TP (G hotkey)")
    local row=Instance.new("Frame"); row.BackgroundTransparency=1; row.Size=UDim2.new(1,0,0,36); row.Parent=B
    local dd=Instance.new("TextButton"); dd.Size=UDim2.new(1,-118,1,0); dd.Text="Choose player  v"; dd.Font=Enum.Font.Gotham; dd.TextSize=14; dd.TextColor3=Color3.fromRGB(235,238,255); dd.BackgroundColor3=Color3.fromRGB(46,50,65); dd.AutoButtonColor=true; dd.Parent=row; Instance.new("UICorner",dd).CornerRadius=UDim.new(0,8); regAlpha(dd)
    local rf=Instance.new("TextButton"); rf.Size=UDim2.new(0,110,1,0); rf.Text="Refresh"; rf.Font=Enum.Font.GothamSemibold; rf.TextSize=14; rf.TextColor3=Color3.fromRGB(235,238,255); rf.BackgroundColor3=Color3.fromRGB(58,116,255); rf.Parent=row; Instance.new("UICorner",rf).CornerRadius=UDim.new(0,8)

    local list=Instance.new("ScrollingFrame"); list.Size=UDim2.new(1,0,0,120); list.BackgroundColor3=Color3.fromRGB(28,30,36); list.BorderSizePixel=0; list.ScrollBarThickness=6; list.CanvasSize=UDim2.new(0,0,0,0); list.Visible=false; list.Parent=B
    Instance.new("UICorner",list).CornerRadius=UDim.new(0,10); regAlpha(list)
    local ll=Instance.new("UIListLayout",list); ll.Padding=UDim.new(0,6)
    local pad=Instance.new("UIPadding",list); pad.PaddingLeft=UDim.new(0,6); pad.PaddingRight=UDim.new(0,6); pad.PaddingTop=UDim.new(0,6); pad.PaddingBottom=UDim.new(0,6)
    local empty=Instance.new("TextLabel"); empty.Size=UDim2.new(1,-12,0,28); empty.BackgroundTransparency=1; empty.Text="No other players."; empty.Font=Enum.Font.Gotham; empty.TextSize=14; empty.TextColor3=Color3.fromRGB(170,176,196); empty.Visible=false; empty.Parent=list
    local tp=Instance.new("TextButton"); tp.Size=UDim2.new(1,0,0,36); tp.Text="TP -> (choose a player)"; tp.Font=Enum.Font.GothamSemibold; tp.TextSize=15; tp.TextColor3=Color3.fromRGB(235,238,255); tp.BackgroundColor3=Color3.fromRGB(80,80,95); tp.Parent=B; Instance.new("UICorner",tp).CornerRadius=UDim.new(0,10)

    local function setTP(on) tp.Active=on; tp.AutoButtonColor=on; tween(tp,.15,{BackgroundColor3= on and Color3.fromRGB(58,116,255) or Color3.fromRGB(80,80,95)}):Play() end
    setTP(false)
    local function clear() for _,ch in ipairs(list:GetChildren()) do if ch:IsA("TextButton") then ch:Destroy() end end; empty.Visible=false end
    local function resize() local tot=0; for _,ch in ipairs(list:GetChildren()) do if ch:IsA("TextButton") then tot += ch.AbsoluteSize.Y + ll.Padding.Offset end end; list.CanvasSize=UDim2.new(0,0,0,math.max(tot,0)) end
    local function rebuild()
      clear(); local o=others()
      if #o==0 then empty.Visible=true else
        for _,p in ipairs(o) do
          local b=Instance.new("TextButton"); b.Size=UDim2.new(1,-12,0,30); b.TextXAlignment=Enum.TextXAlignment.Left
          b.Text=string.format("%s  (@%s)", (p.DisplayName~="" and p.DisplayName) or p.Name, p.Name)
          b.Font=Enum.Font.Gotham; b.TextSize=14; b.TextColor3=Color3.fromRGB(235,238,255); b.BackgroundColor3=Color3.fromRGB(46,50,65); b.AutoButtonColor=true; b.Parent=list
          Instance.new("UICorner",b).CornerRadius=UDim.new(0,8); regAlpha(b)
          b.MouseButton1Click:Connect(function() S.tpUser=p.UserId; S.tpLabel=(p.DisplayName~="" and p.DisplayName) or p.Name; dd.Text="Target: "..S.tpLabel.."  v"; tp.Text="TP -> "..S.tpLabel; setTP(true); list.Visible=false end)
        end
      end
      resize()
      if S.tpUser and not Players:GetPlayerByUserId(S.tpUser) then S.tpUser=nil; S.tpLabel=nil; dd.Text="Choose player  v"; tp.Text="TP -> (choose a player)"; setTP(false) end
    end
    dd.MouseButton1Click:Connect(function() list.Visible=not list.Visible; if list.Visible then rebuild() end end)
    rf.MouseButton1Click:Connect(function() rebuild() end)
    Players.PlayerAdded:Connect(function() if list.Visible then rebuild() end end)
    Players.PlayerRemoving:Connect(function() if list.Visible then rebuild() end end)
    tp.MouseButton1Click:Connect(function() if S.tpUser then tpTo(S.tpUser) end end)
    UIS.InputBegan:Connect(function(i,gp) if gp then return end; if i.KeyCode==Enum.KeyCode.G and S.tpUser then tpTo(S.tpUser) end end)
  end

  -- NoClip
  do local _,B=section("NoClip","Walk through parts")
    local set,btn=toggle(B,"Enable NoClip",S.clipOn)
    btn.MouseButton1Click:Connect(function() S.clipOn=not S.clipOn; set(S.clipOn); if S.clipOn then clip_on() else clip_off() end; hud() end)
  end

  -- Infinite Jump
  do local _,B=section("Infinite Jump","Re-jump in air")
    local set,btn=toggle(B,"Enable Infinite Jump",S.ijOn)
    local g=slider(B,"Boost Y",20,120,S.ijBoost,function(v)return v end)
    RS.Heartbeat:Connect(function() S.ijBoost=g() end)
    btn.MouseButton1Click:Connect(function() S.ijOn=not S.ijOn; set(S.ijOn); if S.ijOn then if LP.Character then ij_bind(LP.Character) end else disc(S.ijConn); S.ijConn=nil end end)
  end

  -- quick actions
  local function saveNow()
    local p=Main.AbsolutePosition; S.pos={x=p.X,y=p.Y}
    local dump={}; for k,v in pairs(S) do local t=typeof(v); if t=="boolean" or t=="number" or t=="string" or t=="table" then dump[k]=v end end
    saveTbl(dump)
    pcall(function() StarterGui:SetCore("SendNotification",{Title="Premium Hub", Text="Saved", Duration=2}) end)
  end
  local function allOff()
    if S.speedOn then S.speedOn=false; speed_off() end
    if S.flyOn then S.flyOn=false; fly_off() end
    if S.lightOn then S.lightOn=false; light_off() end
    if S.espOn then S.espOn=false; esp_off() end
    if S.hitOn then S.hitOn=false; hb_off() end
    if S.clipOn then S.clipOn=false; clip_off() end
    if S.ijOn then S.ijOn=false; if S.ijConn then S.ijConn:Disconnect(); S.ijConn=nil end end
    hud()
  end

  quick("Save",80,saveNow)
  quick("All Off",96,allOff)
  quick("Panic",88,function() allOff(); UI.Enabled=false; HUD.Enabled=false end)
  quick("Reset Pos",100,function() local vs=workspace.CurrentCamera.ViewportSize; Main.Position=UDim2.fromOffset(math.floor(vs.X/2-Main.Size.X.Offset/2), math.floor(vs.Y/2-Main.Size.Y.Offset/2)); S.pos=nil end)
  quick("HUD",70,function() S.hud=not S.hud; HUD.Enabled=S.hud end)

  -- drag bounded
  local function clamp(x,y) local vs=workspace.CurrentCamera.ViewportSize; local w,h=Main.AbsoluteSize.X,Main.AbsoluteSize.Y; return math.clamp(x,0,math.max(0,vs.X-w)), math.clamp(y,0,math.max(0,vs.Y-h)) end
  local dragging,off
  local function begin(io) dragging=true; local p=Main.AbsolutePosition; off=Vector2.new(io.Position.X-p.X, io.Position.Y-p.Y) end
  local function update(io) if not dragging then return end; local x=io.Position.X-off.X; local y=io.Position.Y-off.Y; x,y=clamp(x,y); Main.Position=UDim2.fromOffset(x,y) end
  local function finish() dragging=false; saveNow() end
  for _,a in ipairs({Head,Main}) do
    a.InputBegan:Connect(function(io) if io.UserInputType==Enum.UserInputType.MouseButton1 then begin(io); io.Changed:Connect(function() if io.UserInputState==Enum.UserInputState.End then finish() end end) end end)
  end
  UIS.InputChanged:Connect(function(io) if io.UserInputType==Enum.UserInputType.MouseMovement then update(io) end end)

  -- keybinds
  local function combo(keys, key)
    if type(keys)=="table" then
      if table.find(keys,"Shift") and key==Enum.KeyCode.Four and (UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift)) then return true end
      for _,k in ipairs(keys) do if Enum.KeyCode[k] and Enum.KeyCode[k]==key then return true end end
      return false
    else
      return (Enum.KeyCode[keys] and Enum.KeyCode[keys]==key) or false
    end
  end
  local function toggleUI() S.ui=not S.ui; UI.Enabled=S.ui; HUD.Enabled=S.hud and S.ui end
  Hide.MouseButton1Click:Connect(toggleUI)
  UIS.InputBegan:Connect(function(io,gp)
    if gp then return end
    if io.UserInputType==Enum.UserInputType.Keyboard then
      if combo(S.keyUI, io.KeyCode) or io.KeyCode==Enum.KeyCode.F2 or io.KeyCode==Enum.KeyCode.Insert or io.KeyCode==Enum.KeyCode.RightControl then
        toggleUI()
      elseif combo(S.keyPanic, io.KeyCode) then
        allOff(); UI.Enabled=false; HUD.Enabled=false
      elseif combo(S.keyESP, io.KeyCode) then
        S.espOn=not S.espOn; if S.espOn then esp_on() else esp_off() end; hud()
      elseif combo(S.keyFly, io.KeyCode) then
        S.flyOn=not S.flyOn; if S.flyOn then fly_on() else fly_off() end; hud()
      elseif combo(S.keyClip, io.KeyCode) then
        S.clipOn=not S.clipOn; if S.clipOn then clip_on() else clip_off() end; hud()
      end
    end
  end)

  -- autosave every 5s
  local acc=0; RS.Heartbeat:Connect(function(dt) acc+=dt; if acc>5 then acc=0; saveNow() end end)

  -- show
  UI.Enabled=true; HUD.Enabled=S.hud; applyAlpha(); hud()
  pcall(function() StarterGui:SetCore("SendNotification",{Title="Premium Hub", Text="Loaded", Duration=2}) end)
end

-- start
splash7(StartHub)
