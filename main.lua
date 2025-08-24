--[[
  ⚡ Premium Hub v3 — Speed • Fly • Light • ESP (box+name+distance) • TP • NoClip • Infinite Jump • Hitbox
  Ouvrir/Fermer l'UI : "$" (Shift+4) • F2 • Insert • RightCtrl

  Nouveauté:
   - Hitbox (client): agrandit le HumanoidRootPart des autres joueurs, réglable, propre & réversible.

  ESP:
   - Pseudo + carré (SelectionBox) + distance
   - Couleurs: rôle > équipe > défaut
   - MAJ live si rôle/équipe changent
]]

if _G.__PREMIUM_MENU_V3 then return end
_G.__PREMIUM_MENU_V3 = true

-- ========= Services =========
local Players  = game:GetService("Players")
local UIS      = game:GetService("UserInputService")
local RS       = game:GetService("RunService")
local TS       = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local LP = Players.LocalPlayer
local function getChar() return LP.Character or LP.CharacterAdded:Wait() end
local function getHum()  return (getChar()):WaitForChild("Humanoid") end

local function safeParent(gui)
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
	pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
	local ok, core = pcall(function() return game:GetService("CoreGui") end)
	gui.Parent = ok and core or LP:WaitForChild("PlayerGui")
end
local function tween(o,t,props) return TS:Create(o, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props) end
local function disconnect(c) if c then c:Disconnect() end end
local function disconnectAll(tab) for i=#tab,1,-1 do pcall(function() tab[i]:Disconnect() end); tab[i]=nil end end

-- ========= État =========
local S = {
	uiVisible = true,

	-- Speed
	speedOn=false, speed=22, minSpeed=16, maxSpeed=120,
	speedCon={hb=nil,prop=nil}, humanoid=nil, normalSpeed=nil,

	-- Fly
	flyOn=false, flyConns={}, flyAlive=false, flyData=nil,

	-- Light
	lightOn=false, lightBackup=nil,

	-- ESP (complet)
	espOn=false, espConn=nil, espAcc=0, espHz=10,
	espShowUsername=true, -- unique option d’ESP

	-- Hitbox
	hitboxOn=false, hitboxSize=10,
	hitboxConn=nil, hitboxOrig={}, -- [HRP] = {Size=..., Transparency=..., Material=..., CanCollide=...}

	-- TP
	tpSelectedUserId=nil, tpSelectedLabel=nil,

	-- NoClip
	noclipOn=false, noclipStep=nil, noclipDesc=nil, noclipOriginal={},

	-- Infinite Jump
	ijOn=false, ijBoost=55, ijConn=nil,
}

-- ========= UI =========
local UI = Instance.new("ScreenGui"); UI.Name="PremiumHubV3"; safeParent(UI)

local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(510, 640) -- un peu plus haut pour la Hitbox card
Main.BackgroundColor3 = Color3.fromRGB(18,18,20)
Main.BorderSizePixel = 0
Main.Active = true
Main.Parent = UI
do local vs=workspace.CurrentCamera.ViewportSize
	Main.Position = UDim2.fromOffset(math.floor(vs.X/2 - Main.Size.X.Offset/2), math.floor(vs.Y/2 - Main.Size.Y.Offset/2))
end
Instance.new("UICorner", Main).CornerRadius = UDim.new(0,16)
local stroke=Instance.new("UIStroke",Main) stroke.Thickness=1.5; stroke.Transparency=.15; stroke.Color=Color3.fromRGB(255,255,255)
local Shadow=Instance.new("ImageLabel")
Shadow.Image="rbxassetid://5028857084"; Shadow.ImageTransparency=.4; Shadow.ScaleType=Enum.ScaleType.Slice; Shadow.SliceCenter=Rect.new(24,24,276,276)
Shadow.AnchorPoint=Vector2.new(.5,.5); Shadow.Position=UDim2.fromScale(.5,.5); Shadow.Size=UDim2.new(1,32,1,32); Shadow.BackgroundTransparency=1; Shadow.Parent=Main

-- Header
local Header=Instance.new("Frame"); Header.Size=UDim2.new(1,0,0,46); Header.BackgroundTransparency=1; Header.Active=true; Header.Parent=Main
local Title=Instance.new("TextLabel"); Title.BackgroundTransparency=1; Title.Position=UDim2.fromOffset(14,8); Title.Size=UDim2.fromOffset(360,30)
Title.Font=Enum.Font.GothamBold; Title.TextSize=18; Title.TextXAlignment=Enum.TextXAlignment.Left; Title.TextColor3=Color3.fromRGB(255,255,255)
Title.Text="⚡ Premium Hub v3 — Speed • Fly • Light • ESP • TP • NoClip • IJ • Hitbox"; Title.Parent=Header
local Hint=Instance.new("TextLabel"); Hint.BackgroundTransparency=1; Hint.AnchorPoint=Vector2.new(1,0); Hint.Position=UDim2.new(1,-42,0,10)
Hint.Size=UDim2.fromOffset(300,24); Hint.Font=Enum.Font.Gotham; Hint.TextSize=14; Hint.TextXAlignment=Enum.TextXAlignment.Right; Hint.TextColor3=Color3.fromRGB(180,180,190)
Hint.Text='Hide: "$"(⇧+4) • F2 • Insert • RightCtrl'; Hint.Parent=Header
local HideBtn=Instance.new("TextButton"); HideBtn.AnchorPoint=Vector2.new(1,0); HideBtn.Position=UDim2.new(1,-10,0,8); HideBtn.Size=UDim2.fromOffset(28,28)
HideBtn.Text="✕"; HideBtn.TextSize=18; HideBtn.Font=Enum.Font.GothamBold; HideBtn.TextColor3=Color3.fromRGB(230,230,235); HideBtn.AutoButtonColor=false
HideBtn.BackgroundColor3=Color3.fromRGB(60,60,68); HideBtn.Parent=Header; Instance.new("UICorner",HideBtn).CornerRadius=UDim.new(1,0); Instance.new("UIStroke",HideBtn).Transparency=.35
local Sep=Instance.new("Frame"); Sep.BackgroundColor3=Color3.fromRGB(45,45,52); Sep.Size=UDim2.new(1,-24,0,1); Sep.Position=UDim2.fromOffset(12,46); Sep.BorderSizePixel=0; Sep.Parent=Main

-- Scroll content
local Content=Instance.new("ScrollingFrame"); Content.Position=UDim2.fromOffset(12,58); Content.Size=UDim2.new(1,-24,1,-70)
Content.CanvasSize=UDim2.new(0,0,0,0); Content.ScrollBarThickness=6; Content.BackgroundTransparency=1; Content.ScrollingDirection=Enum.ScrollingDirection.Y; Content.Parent=Main
local VList=Instance.new("UIListLayout",Content); VList.Padding=UDim.new(0,12); VList.SortOrder=Enum.SortOrder.LayoutOrder
local function refreshCanvas() Content.CanvasSize=UDim2.new(0,0,0,VList.AbsoluteContentSize.Y+8) end
VList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(refreshCanvas)

-- Helpers
local function makeCard(titleText, subtitleText, height)
	local Card=Instance.new("Frame"); Card.Size=UDim2.new(1,0,0,height); Card.BackgroundColor3=Color3.fromRGB(24,24,28); Card.BorderSizePixel=0; Card.Active=true; Card.Parent=Content
	Instance.new("UICorner",Card).CornerRadius=UDim.new(0,12)
	local s=Instance.new("UIStroke",Card); s.Thickness=1; s.Transparency=0.25; s.Color=Color3.fromRGB(255,255,255)
	local T=Instance.new("TextLabel"); T.BackgroundTransparency=1; T.Font=Enum.Font.GothamSemibold; T.TextSize=16; T.TextXAlignment=Enum.TextXAlignment.Left; T.TextColor3=Color3.fromRGB(235,235,240); T.Text=titleText; T.Position=UDim2.fromOffset(12,8); T.Size=UDim2.fromOffset(360,20); T.Parent=Card
	local ST=Instance.new("TextLabel"); ST.BackgroundTransparency=1; ST.Font=Enum.Font.Gotham; ST.TextSize=13; ST.TextXAlignment=Enum.TextXAlignment.Left; ST.TextColor3=Color3.fromRGB(170,170,182); ST.Text=subtitleText or ""; ST.Position=UDim2.fromOffset(12,30); ST.Size=UDim2.fromOffset(470,18); ST.Parent=Card
	return Card
end
local function makeToggle(parent, defaultOn, xOff)
	local Btn=Instance.new("TextButton"); Btn.AutoButtonColor=false; Btn.AnchorPoint=Vector2.new(1,0); Btn.Position=UDim2.new(1,-(xOff or 10),0,8)
	Btn.Size=UDim2.fromOffset(64,28); Btn.BackgroundColor3= defaultOn and Color3.fromRGB(60,200,110) or Color3.fromRGB(60,60,68); Btn.Text=""; Btn.Parent=parent
	Instance.new("UICorner",Btn).CornerRadius=UDim.new(1,0); local s=Instance.new("UIStroke",Btn); s.Thickness=1; s.Transparency=.2; s.Color=Color3.fromRGB(255,255,255)
	local Knob=Instance.new("Frame"); Knob.Size=UDim2.fromOffset(26,26); Knob.Position= defaultOn and UDim2.fromOffset(36,1) or UDim2.fromOffset(1,1); Knob.BackgroundColor3=Color3.fromRGB(240,240,245); Knob.Parent=Btn
	Instance.new("UICorner",Knob).CornerRadius=UDim.new(1,0)
	local function setOn(on) tween(Btn,.15,{BackgroundColor3= on and Color3.fromRGB(60,200,110) or Color3.fromRGB(60,60,68)}):Play(); tween(Knob,.15,{Position= on and UDim2.fromOffset(36,1) or UDim2.fromOffset(1,1)}):Play() end
	return Btn,setOn
end
local function makeSlider(parent, title, minV, maxV, defaultV, yOff, onChanged, valueFmt)
	local Wrap=Instance.new("Frame"); Wrap.BackgroundTransparency=1; Wrap.Position=UDim2.fromOffset(12,yOff or 56); Wrap.Size=UDim2.new(1,-24,0,60); Wrap.Parent=parent
	local function fmt(v) return valueFmt and valueFmt(v) or tostring(v) end
	local T=Instance.new("TextLabel"); T.BackgroundTransparency=1; T.Font=Enum.Font.Gotham; T.TextSize=14; T.TextXAlignment=Enum.TextXAlignment.Left; T.TextColor3=Color3.fromRGB(200,200,210)
	T.Text=string.format("%s: %s",title,fmt(defaultV)); T.Position=UDim2.fromOffset(0,0); T.Size=UDim2.fromOffset(280,18); T.Parent=Wrap
	local Bar=Instance.new("Frame"); Bar.BackgroundColor3=Color3.fromRGB(45,45,55); Bar.BorderSizePixel=0; Bar.Position=UDim2.fromOffset(0,26); Bar.Size=UDim2.new(1,0,0,8); Bar.Parent=Wrap
	Instance.new("UICorner",Bar).CornerRadius=UDim.new(0,6)
	local Fill=Instance.new("Frame"); Fill.BackgroundColor3=Color3.fromRGB(110,170,255); Fill.BorderSizePixel=0; Fill.Size=UDim2.fromOffset(0,8); Fill.Parent=Bar
	Instance.new("UICorner",Fill).CornerRadius=UDim.new(0,6)
	local Knob=Instance.new("Frame"); Knob.Size=UDim2.fromOffset(14,14); Knob.Position=UDim2.fromOffset(-7,-3); Knob.BackgroundColor3=Color3.fromRGB(240,240,245); Knob.Parent=Fill
	Instance.new("UICorner",Knob).CornerRadius=UDim.new(1,0)
	local dragging=false
	local function setFromX(px)
		local abs=Bar.AbsoluteSize.X; local rel=math.clamp(px/abs,0,1)
		local val=math.floor(minV + (maxV-minV)*rel + .5)
		local w=math.floor(abs*rel + .5)
		Fill.Size=UDim2.fromOffset(w,8); Knob.Position=UDim2.fromOffset(w-7,-3)
		T.Text=string.format("%s: %s",title,fmt(val))
		if onChanged then onChanged(val) end
	end
	RS.Heartbeat:Wait(); local rel=(defaultV-minV)/(maxV-minV); setFromX(Bar.AbsoluteSize.X*rel)
	Bar.InputBegan:Connect(function(io) if io.UserInputType==Enum.UserInputType.MouseButton1 or io.UserInputType==Enum.UserInputType.Touch then dragging=true; setFromX(io.Position.X-Bar.AbsolutePosition.X) end end)
	UIS.InputChanged:Connect(function(io) if dragging and (io.UserInputType==Enum.UserInputType.MouseMovement or io.UserInputType==Enum.UserInputType.Touch) then setFromX(io.Position.X-Bar.AbsolutePosition.X) end end)
	UIS.InputEnded:Connect(function(io) if io.UserInputType==Enum.UserInputType.MouseButton1 or io.UserInputType==Enum.UserInputType.Touch then dragging=false end end)
	return { set=function(v) v=math.clamp(v,minV,maxV); local r=(v-minV)/(maxV-minV); setFromX(Bar.AbsoluteSize.X*r) end }
end

-- ========= Speed =========
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

-- ========= Fly (sortie propre) =========
local function fly_disable()
	S.flyAlive=false; disconnectAll(S.flyConns)
	if not S.flyData then return end

	local hrp = S.flyData.hrp
	local hum = S.flyData.humanoid
	local Controls = S.flyData.Controls
	local collMap = S.flyData.collMap

	pcall(function() if S.flyData.lv then S.flyData.lv.Enabled=false; S.flyData.lv:Destroy() end end)
	pcall(function() if S.flyData.att then S.flyData.att:Destroy() end end)

	if collMap then for part,can in pairs(collMap) do if part and part.Parent then part.CanCollide=can end end end

	if hrp then
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
		hrp.CFrame = hrp.CFrame + Vector3.new(0,0.05,0)
	end

	if Controls then pcall(function() Controls:Enable() end) end
	if hum then
		hum.AutoRotate=true
		hum.PlatformStand=false
		hum.Sit=false
		pcall(function() hum:ChangeState(Enum.HumanoidStateType.Landed) end)
		pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
		task.delay(0.05,function()
			if hum and hum.Parent then pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end) end
		end)
	end
	S.flyData=nil
end

local function fly_enable()
	fly_disable()
	local char=getChar(); local hrp=char:WaitForChild("HumanoidRootPart"); local hum=char:WaitForChild("Humanoid")
	S.flyAlive=true

	local Controls=nil
	pcall(function()
		local ps=LP:WaitForChild("PlayerScripts")
		local ok,PlayerModule=pcall(function() return require(ps:WaitForChild("PlayerModule")) end)
		if ok and PlayerModule then
			Controls = PlayerModule:GetControls()
			if Controls then Controls:Disable() end
		end
	end)

	hum.AutoRotate=false
	hum:ChangeState(Enum.HumanoidStateType.Physics)
	hum.PlatformStand=true

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

		local rightDir=Vector3.new(cam.CFrame.RightVector.X,0,cam.CFrame.RightVector.Z)
		rightDir=(rightDir.Magnitude>0) and rightDir.Unit or Vector3.new(-yawDir.Z,0,yawDir.X)

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

-- ========= Light =========
local LIGHT_PRESET={GlobalShadows=false, FogEnd=100000, Brightness=2, Ambient=Color3.fromRGB(150,150,150)}
local function light_enable()
	if not S.lightBackup then S.lightBackup={GlobalShadows=Lighting.GlobalShadows, FogEnd=Lighting.FogEnd, Brightness=Lighting.Brightness, Ambient=Lighting.Ambient} end
	Lighting.GlobalShadows=LIGHT_PRESET.GlobalShadows; Lighting.FogEnd=LIGHT_PRESET.FogEnd; Lighting.Brightness=LIGHT_PRESET.Brightness; Lighting.Ambient=LIGHT_PRESET.Ambient
end
local function light_disable()
	if S.lightBackup then Lighting.GlobalShadows=S.lightBackup.GlobalShadows; Lighting.FogEnd=S.lightBackup.FogEnd; Lighting.Brightness=S.lightBackup.Brightness; Lighting.Ambient=S.lightBackup.Ambient end
end

-- ========= ESP (BOX + NAME + DISTANCE) =========
local ROLE_COLORS = {
	Murder=Color3.fromRGB(255,60,60), Murderer=Color3.fromRGB(255,60,60),
	Innocent=Color3.fromRGB(64,128,255),
	Sheriff=Color3.fromRGB(255,220,0), Detective=Color3.fromRGB(255,220,0),
}
local DEFAULT_COLOR = Color3.fromRGB(200,200,200)
local ESP_MAX_DIST = math.huge

local function getRole(p,char) local r=p:GetAttribute("Role"); if r==nil and char then r=char:GetAttribute("Role") end; return (typeof(r)=="string") and r or nil end
local function colorFor(p,char)
	local role=getRole(p,char); if role and ROLE_COLORS[role] then return ROLE_COLORS[role] end
	if p.Team and p.Team.TeamColor then return p.Team.TeamColor.Color end
	return DEFAULT_COLOR
end
local function bestAdornee(char) return char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildWhichIsA("BasePart") end

local ESP_REG = {} -- [Player] = {char, box, bb, name, dist, lastName="", lastDist=-1, lastColor=nil, conns={...}}

local function cleanupLegacy(char)
	local keepBB=nil
	for _,d in ipairs(char:GetChildren()) do
		if d:IsA("BillboardGui") and d.Name=="ESP_BBG" then
			if keepBB then d:Destroy() else keepBB=d end
		end
	end
	for _,d in ipairs(char:GetChildren()) do
		if d:IsA("SelectionBox") and d.Name=="ESP_Box" then
			d:Destroy()
		end
	end
	return keepBB
end

local function makeOrGet(p,char)
	if not char or p==LP then return end
	local reg=ESP_REG[p]
	if not reg then reg={conns={}}; ESP_REG[p]=reg else disconnectAll(reg.conns) end
	reg.char=char

	local box=Instance.new("SelectionBox")
	box.Name="ESP_Box"
	box.Adornee=char
	box.LineThickness=0.02
	box.SurfaceTransparency=1
	box.Parent=char
	reg.box=box

	local bb=cleanupLegacy(char)
	if not bb then
		bb=Instance.new("BillboardGui"); bb.Name="ESP_BBG"
		bb.Size=UDim2.new(0, 210, 0, 42)
		bb.StudsOffset=Vector3.new(0,3,0)
		bb.AlwaysOnTop=true
		bb.MaxDistance=5000
		bb.Parent=char
		local nameLbl=Instance.new("TextLabel"); nameLbl.Name="Name"
		nameLbl.BackgroundTransparency=1; nameLbl.Size=UDim2.new(1,0,0.5,0)
		nameLbl.Font=Enum.Font.GothamBold; nameLbl.TextScaled=true; nameLbl.TextStrokeTransparency=.5; nameLbl.Parent=bb
		local distLbl=Instance.new("TextLabel"); distLbl.Name="Dist"
		distLbl.BackgroundTransparency=1; distLbl.Position=UDim2.new(0,0,0.5,0); distLbl.Size=UDim2.new(1,0,0.5,0)
		distLbl.Font=Enum.Font.Gotham; distLbl.TextScaled=true; distLbl.TextStrokeTransparency=.5; distLbl.Parent=bb
	end
	reg.bb=bb; reg.name=bb:FindChild("Name") or bb:FindFirstChild("Name"); reg.dist=bb:FindChild("Dist") or bb:FindFirstChild("Dist"); reg.lastName=""; reg.lastDist=-1
	bb.Adornee = bestAdornee(char)

	table.insert(reg.conns, char.DescendantAdded:Connect(function(d)
		if d.Name=="Head" and d:IsA("BasePart") then if reg.bb and reg.bb.Adornee~=d then reg.bb.Adornee=d end end
	end))
	table.insert(reg.conns, char.AncestryChanged:Connect(function(_,parent) if parent==nil then disconnectAll(reg.conns) end end))

	return reg
end

local function ensureBuilt(p)
	local char=p.Character
	if not char then return end
	local reg=ESP_REG[p]
	if not reg or reg.char~=char or not reg.bb or not reg.box then
		makeOrGet(p,char)
	end
end

local function colorsEqual(a,b) if not a or not b then return false end; return a.r==b.r and a.g==b.g and a.b==b.b end

local function esp_tick(dt)
	for _,p in ipairs(Players:GetPlayers()) do
		if p~=LP then
			ensureBuilt(p)
			local reg=ESP_REG[p]
			local char=p.Character
			if not (reg and char and reg.box and reg.bb and reg.name and reg.dist) then continue end

			local myC=LP.Character; if not myC then continue end
			local myHRP=myC:FindFirstChild("HumanoidRootPart"); local tHRP=char:FindFirstChild("HumanoidRootPart")
			local head = char:FindFirstChild("Head") or char:FindFirstChildWhichIsA("BasePart")
			if not (myHRP and tHRP and head) then reg.box.Visible=false; reg.bb.Enabled=false; continue end

			local dist=(myHRP.Position - tHRP.Position).Magnitude
			if dist > ESP_MAX_DIST then reg.box.Visible=false; reg.bb.Enabled=false; continue end

			local col = colorFor(p,char)
			if not colorsEqual(reg.lastColor, col) then
				reg.lastColor = col
				pcall(function() reg.box.LineColor3 = col end)
				pcall(function() reg.box.Color3 = col end)
				reg.name.TextColor3 = col
				reg.dist.TextColor3 = col
			end

			local display = (p.DisplayName and p.DisplayName ~= "") and p.DisplayName or p.Name
			local wantName = S.espShowUsername and (display.." (@"..p.Name..")") or display
			if reg.lastName ~= wantName then reg.name.Text = wantName; reg.lastName = wantName end

			local di = (dist >= 0) and math.floor(dist + 0.5) or 0
			if reg.lastDist ~= di then reg.dist.Text = tostring(di).." studs"; reg.lastDist = di end

			reg.box.Visible = true
			reg.bb.Enabled = true
			if (not reg.bb.Adornee) or (not reg.bb.Adornee.Parent) then reg.bb.Adornee = bestAdornee(char) end
		end
	end
end

local function esp_enable()
	if S.espConn then return end
	for _,pl in ipairs(Players:GetPlayers()) do if pl~=LP and pl.Character then makeOrGet(pl, pl.Character) end end
	S.espConn = RS.Heartbeat:Connect(esp_tick) -- 60 Hz; léger et sûr pour rafraîchir couleurs/roles
	Players.PlayerAdded:Connect(function(p)
		p.CharacterAdded:Connect(function(c) task.wait(0.2); makeOrGet(p,c) end)
		if p.Character then makeOrGet(p,p.Character) end
	end)
end
local function esp_disable()
	disconnect(S.espConn); S.espConn=nil
	for _,reg in pairs(ESP_REG) do
		if reg.box then reg.box.Visible=false end
		if reg.bb then reg.bb.Enabled=false end
	end
end

-- ========= Hitbox =========
local function rememberHRP(hrp)
	if not hrp or S.hitboxOrig[hrp] then return end
	S.hitboxOrig[hrp] = {
		Size = hrp.Size,
		Transparency = hrp.Transparency,
		Material = hrp.Material,
		CanCollide = hrp.CanCollide,
	}
end

local function applyHitboxTo(hrp)
	if not hrp then return end
	rememberHRP(hrp)
	-- Valeurs "style original": Neon rouge, semi-transparent, pas de collisions
	hrp.Size = Vector3.new(S.hitboxSize, S.hitboxSize, S.hitboxSize)
	hrp.Transparency = 0.7
	hrp.BrickColor = BrickColor.new("Really red")
	hrp.Material = Enum.Material.Neon
	hrp.CanCollide = false
end

local function restoreAllHitbox()
	for hrp,orig in pairs(S.hitboxOrig) do
		if hrp and hrp.Parent and orig then
			pcall(function()
				hrp.Size = orig.Size
				hrp.Transparency = orig.Transparency
				hrp.Material = orig.Material
				hrp.CanCollide = orig.CanCollide
			end)
		end
	end
	S.hitboxOrig = {}
end

local function hitbox_loop()
	-- Boucle côté client pour contrer les resets serveurs
	for _,pl in ipairs(Players:GetPlayers()) do
		if pl ~= LP and pl.Character then
			local hrp = pl.Character:FindFirstChild("HumanoidRootPart")
			if hrp then pcall(applyHitboxTo, hrp) end
		end
	end
end

local function hitbox_enable()
	if S.hitboxConn then return end
	-- Applique immédiatement
	hitbox_loop()
	-- Et maintient à chaque RenderStepped (fluide)
	S.hitboxConn = RS.RenderStepped:Connect(function()
		if S.hitboxOn then hitbox_loop() end
	end)
	-- Sur nouveaux joueurs / respawn, on mémorise les originaux dès que possible
	Players.PlayerAdded:Connect(function(p)
		p.CharacterAdded:Connect(function(c)
			task.wait(0.1)
			local hrp = c:FindFirstChild("HumanoidRootPart")
			if hrp then rememberHRP(hrp) end
		end)
	end)
end

local function hitbox_disable()
	disconnect(S.hitboxConn); S.hitboxConn=nil
	restoreAllHitbox()
end

-- ========= NoClip =========
local function noclip_cachePart(inst) if inst:IsA("BasePart") and S.noclipOriginal[inst]==nil then S.noclipOriginal[inst]=inst.CanCollide end end
local function noclip_cacheChar(char) for _,d in ipairs(char:GetDescendants()) do noclip_cachePart(d) end; disconnect(S.noclipDesc); S.noclipDesc=char.DescendantAdded:Connect(noclip_cachePart) end
local function noclip_apply(char) for part,_ in pairs(S.noclipOriginal) do if part.Parent and part:IsDescendantOf(char) then part.CanCollide=false end end end
local function noclip_enable() local char=getChar(); S.noclipOriginal={}; noclip_cacheChar(char); disconnect(S.noclipStep); S.noclipStep=RS.Stepped:Connect(function() noclip_apply(char) end) end
local function noclip_disable() disconnect(S.noclipStep); S.noclipStep=nil; disconnect(S.noclipDesc); S.noclipDesc=nil; for part,can in pairs(S.noclipOriginal) do if part and part.Parent then part.CanCollide=can end end; S.noclipOriginal={} end
LP.CharacterAdded:Connect(function(c) if S.noclipOn then noclip_enable() end end)

-- ========= Infinite Jump =========
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

-- ========= TP helpers =========
local function getHRPFromChar(char) return char and char:FindFirstChild("HumanoidRootPart") end
local function tpToPlayerId(userId)
	local me=LP; local target=Players:GetPlayerByUserId(userId)
	if not (me and me.Character and target and target.Character) then return end
	local myHRP=getHRPFromChar(me.Character); local targetHRP=getHRPFromChar(target.Character); if not (myHRP and targetHRP) then return end
	me.Character:PivotTo(targetHRP.CFrame * CFrame.new(0,0,3))
end
local function listOthers() local arr={}; for _,p in ipairs(Players:GetPlayers()) do if p~=LP then table.insert(arr,p) end end; table.sort(arr,function(a,b) local ad=(a.DisplayName~="" and a.DisplayName) or a.Name; local bd=(b.DisplayName~="" and b.DisplayName) or b.Name; return string.lower(ad) < string.lower(bd) end); return arr end

-- ========= Cartes =========
-- Speed
do
	local Card=makeCard("Speed","Maintient ta vitesse (anti-reset + respawn)",150)
	local Toggle,setT=makeToggle(Card,false)
	makeSlider(Card,"Vitesse",S.minSpeed,S.maxSpeed,S.speed,56,function(v) S.speed=v end)
	Toggle.MouseButton1Click:Connect(function() S.speedOn=not S.speedOn; setT(S.speedOn); if S.speedOn then speed_enable() else speed_disable() end end)
end

-- Fly
do local Card=makeCard("Fly","Vol fluide (WASD/ZQSD + inclinaison caméra) — sortie propre",100); local Toggle,setT=makeToggle(Card,false)
	Toggle.MouseButton1Click:Connect(function() S.flyOn=not S.flyOn; setT(S.flyOn); if S.flyOn then fly_enable() else fly_disable() end end)
end

-- Light
do local Card=makeCard("Light","Désactive ombres, enlève brouillard, boost luminosité",100); local Toggle,setT=makeToggle(Card,false)
	Toggle.MouseButton1Click:Connect(function() S.lightOn=not S.lightOn; setT(S.lightOn); if S.lightOn then light_enable() else light_disable() end end)
end

-- ESP (Complet, mini-toggle username)
do
	local Card=makeCard("ESP Player","Pseudo + carré + distance (couleurs dynamiques).",150)
	local Toggle,setT=makeToggle(Card,false)

	local Row=Instance.new("Frame"); Row.BackgroundTransparency=1; Row.Position=UDim2.fromOffset(12,56); Row.Size=UDim2.new(1,-24,0,28); Row.Parent=Card
	local L=Instance.new("TextLabel"); L.BackgroundTransparency=1; L.Font=Enum.Font.Gotham; L.TextSize=14; L.TextXAlignment=Enum.TextXAlignment.Left; L.TextColor3=Color3.fromRGB(200,200,210)
	L.Text="Afficher @username"; L.Position=UDim2.fromOffset(0,6); L.Size=UDim2.fromOffset(160,18); L.Parent=Row
	local Small,setSmall=makeToggle(Row,S.espShowUsername); Small.Position=UDim2.new(1,-56,0,2); Small.Size=UDim2.fromOffset(56,24)
	Small.MouseButton1Click:Connect(function() S.espShowUsername=not S.espShowUsername; setSmall(S.espShowUsername) end)

	Toggle.MouseButton1Click:Connect(function()
		S.espOn=not S.espOn; setT(S.espOn)
		if S.espOn then esp_enable() else esp_disable() end
	end)
end

-- Hitbox (nouvelle carte)
do
	local Card=makeCard("Hitbox (HRP)","Agrandit le HumanoidRootPart des AUTRES joueurs (client-side).",150)
	local Toggle,setT=makeToggle(Card,false)
	makeSlider(Card,"Taille",2,30,S.hitboxSize,56,function(v) S.hitboxSize=v end)

	Toggle.MouseButton1Click:Connect(function()
		S.hitboxOn = not S.hitboxOn
		setT(S.hitboxOn)
		if S.hitboxOn then hitbox_enable() else hitbox_disable() end
	end)
end

-- TP Player
do
	local Card=makeCard("TP Player","Choisis un joueur puis clique TP.",220)
	local row=Instance.new("Frame"); row.BackgroundTransparency=1; row.Position=UDim2.fromOffset(12,56); row.Size=UDim2.new(1,-24,0,36); row.Parent=Card
	local uiList=Instance.new("UIListLayout",row); uiList.FillDirection=Enum.FillDirection.Horizontal; uiList.Padding=UDim.new(0,8)

	local refreshBtn=Instance.new("TextButton"); refreshBtn.Size=UDim2.new(0,100,1,0); refreshBtn.Text="Refresh"; refreshBtn.Font=Enum.Font.GothamSemibold; refreshBtn.TextSize=14; refreshBtn.TextColor3=Color3.fromRGB(255,255,255)
	refreshBtn.BackgroundColor3=Color3.fromRGB(50,130,255); refreshBtn.AutoButtonColor=true; refreshBtn.Parent=row; do local c=Instance.new("UICorner",refreshBtn) c.CornerRadius=UDim.new(0,8) end

	local dropdownBtn=Instance.new("TextButton"); dropdownBtn.Size=UDim2.new(1,-108,1,0); dropdownBtn.Text="Choisir un joueur  ▾"; dropdownBtn.Font=Enum.Font.Gotham; dropdownBtn.TextSize=14
	dropdownBtn.TextColor3=Color3.fromRGB(235,235,240); dropdownBtn.BackgroundColor3=Color3.fromRGB(45,45,55); dropdownBtn.AutoButtonColor=true; dropdownBtn.Parent=row; do local c=Instance.new("UICorner",dropdownBtn) c.CornerRadius=UDim.new(0,8) end

	local listHolder=Instance.new("ScrollingFrame"); listHolder.Size=UDim2.new(1,-24,0,112); listHolder.Position=UDim2.fromOffset(12,100); listHolder.BackgroundColor3=Color3.fromRGB(40,40,48)
	listHolder.BorderSizePixel=0; listHolder.ScrollBarThickness=6; listHolder.CanvasSize=UDim2.new(0,0,0,0); listHolder.Visible=false; listHolder.Parent=Card; do local c=Instance.new("UICorner",listHolder) c.CornerRadius=UDim.new(0,10) end
	local listLayout=Instance.new("UIListLayout",listHolder); listLayout.Padding=UDim.new(0,6)
	local listPad=Instance.new("UIPadding",listHolder); listPad.PaddingLeft=UDim.new(0,6); listPad.PaddingRight=UDim.new(0,6); listPad.PaddingTop=UDim.new(0,6); listPad.PaddingBottom=UDim.new(0,6)

	local emptyLabel=Instance.new("TextLabel"); emptyLabel.Size=UDim2.new(1,-12,0,28); emptyLabel.BackgroundTransparency=1; emptyLabel.Text="Aucun autre joueur."
	emptyLabel.Font=Enum.Font.Gotham; emptyLabel.TextSize=14; emptyLabel.TextColor3=Color3.fromRGB(200,200,205); emptyLabel.Visible=false; emptyLabel.Parent=listHolder

	local tpBtn=Instance.new("TextButton"); tpBtn.Size=UDim2.new(1,-24,0,34); tpBtn.Position=UDim2.fromOffset(12,216-34); tpBtn.Text="Se TP → (choisis un joueur)"
	tpBtn.Font=Enum.Font.GothamSemibold; tpBtn.TextSize=15; tpBtn.TextColor3=Color3.fromRGB(255,255,255); tpBtn.BackgroundColor3=Color3.fromRGB(80,80,90); tpBtn.AutoButtonColor=true; tpBtn.Parent=Card
	do local c=Instance.new("UICorner",tpBtn) c.CornerRadius=UDim.new(0,10) end
	local function setTPEnabled(on) tpBtn.Active=on; tpBtn.AutoButtonColor=on; tpBtn.BackgroundColor3= on and Color3.fromRGB(60,120,255) or Color3.fromRGB(80,80,90) end
	setTPEnabled(false)

	local function clearList() for _,ch in ipairs(listHolder:GetChildren()) do if ch:IsA("TextButton") then ch:Destroy() end end; emptyLabel.Visible=false end
	local function resizeCanvas() local total=0; for _,ch in ipairs(listHolder:GetChildren()) do if ch:IsA("TextButton") then total += ch.AbsoluteSize.Y + listLayout.Padding.Offset end end; listHolder.CanvasSize=UDim2.new(0,0,0, math.max(total,0)) end
	local function rebuild()
		clearList()
		local others=listOthers()
		if #others==0 then emptyLabel.Visible=true else
			for _,p in ipairs(others) do
				local b=Instance.new("TextButton"); b.Size=UDim2.new(1,-12,0,30); b.TextXAlignment=Enum.TextXAlignment.Left
				b.Text=string.format("%s  (@%s)", (p.DisplayName~="" and p.DisplayName) or p.Name, p.Name)
				b.Font=Enum.Font.Gotham; b.TextSize=14; b.TextColor3=Color3.fromRGB(235,235,240); b.BackgroundColor3=Color3.fromRGB(56,56,66); b.AutoButtonColor=true; b.Parent=listHolder
				Instance.new("UICorner",b).CornerRadius=UDim.new(0,8)
				b.MouseButton1Click:Connect(function()
					S.tpSelectedUserId=p.UserId; S.tpSelectedLabel=(p.DisplayName~="" and p.DisplayName) or p.Name
					dropdownBtn.Text="Cible : "..S.tpSelectedLabel.."  ▾"; tpBtn.Text="Se TP → "..S.tpSelectedLabel; setTPEnabled(true); listHolder.Visible=false
				end)
			end
		end
		resizeCanvas()
		if S.tpSelectedUserId and not Players:GetPlayerByUserId(S.tpSelectedUserId) then
			S.tpSelectedUserId=nil; S.tpSelectedLabel=nil; dropdownBtn.Text="Choisir un joueur  ▾"; tpBtn.Text="Se TP → (choisis un joueur)"; setTPEnabled(false)
		end
	end
	dropdownBtn.MouseButton1Click:Connect(function() listHolder.Visible=not listHolder.Visible; if listHolder.Visible then rebuild() end end)
	refreshBtn.MouseButton1Click:Connect(function() rebuild() end)
	Players.PlayerAdded:Connect(function() if listHolder.Visible then rebuild() end end)
	Players.PlayerRemoving:Connect(function() if listHolder.Visible then rebuild() end end)
	tpBtn.MouseButton1Click:Connect(function() if S.tpSelectedUserId then tpToPlayerId(S.tpSelectedUserId) end end)
	UIS.InputBegan:Connect(function(input,gp) if gp then return end; if input.KeyCode==Enum.KeyCode.G and S.tpSelectedUserId then tpToPlayerId(S.tpSelectedUserId) end end)
end

-- NoClip
do local Card=makeCard("NoClip","Traverse les objets (réversible).",100); local Toggle,setT=makeToggle(Card,false)
	Toggle.MouseButton1Click:Connect(function() S.noclipOn=not S.noclipOn; setT(S.noclipOn); if S.noclipOn then
		local char=getChar(); S.noclipOriginal={}; for _,d in ipairs(char:GetDescendants()) do if d:IsA("BasePart") then S.noclipOriginal[d]=d.CanCollide end end
		disconnect(S.noclipDesc); S.noclipDesc=char.DescendantAdded:Connect(function(inst) if inst:IsA("BasePart") then S.noclipOriginal[inst]=inst.CanCollide end end)
		disconnect(S.noclipStep); S.noclipStep=RS.Stepped:Connect(function() for part,_ in pairs(S.noclipOriginal) do if part.Parent and part:IsDescendantOf(char) then part.CanCollide=false end end end)
	else
		disconnect(S.noclipStep); S.noclipStep=nil; disconnect(S.noclipDesc); S.noclipDesc=nil
		for part,can in pairs(S.noclipOriginal) do if part and part.Parent then part.CanCollide=can end end
		S.noclipOriginal={}
	end end)
end
LP.CharacterAdded:Connect(function() if S.noclipOn then noclip_enable() end end)

-- Infinite Jump
do local Card=makeCard("Infinite Jump","Saut infini (boost réglable).",150); local Toggle,setT=makeToggle(Card,false)
	makeSlider(Card,"Boost Y",20,120,S.ijBoost,56,function(v) S.ijBoost=v end)
	local function ij_bind(char)
		local hum=char:WaitForChild("Humanoid"); local root=char:WaitForChild("HumanoidRootPart")
		hum.UseJumpPower=true; disconnect(S.ijConn)
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
	Toggle.MouseButton1Click:Connect(function() S.ijOn=not S.ijOn; setT(S.ijOn); if S.ijOn then if LP.Character then ij_bind(LP.Character) end else disconnect(S.ijConn); S.ijConn=nil end end)
end

-- Drag (borné) + Hide
local function clampToScreen(x,y) local vs=workspace.CurrentCamera.ViewportSize; local w,h=Main.AbsoluteSize.X,Main.AbsoluteSize.Y; return math.clamp(x,0,math.max(0,vs.X-w)), math.clamp(y,0,math.max(0,vs.Y-h)) end
local dragging,offset
local function beginDrag(io) dragging=true; local p=Main.AbsolutePosition; offset=Vector2.new(io.Position.X-p.X, io.Position.Y-p.Y) end
local function updateDrag(io) if not dragging then return end; local x=io.Position.X-offset.X; local y=io.Position.Y-offset.Y; x,y=clampToScreen(x,y); Main.Position=UDim2.fromOffset(x,y) end
local function endDrag() dragging=false end
for _,area in ipairs({Header,Main}) do
	area.InputBegan:Connect(function(io)
		if io.UserInputType==Enum.UserInputType.MouseButton1 then
			beginDrag(io)
			io.Changed:Connect(function() if io.UserInputState==Enum.UserInputState.End then endDrag() end end)
		end
	end)
end
UIS.InputChanged:Connect(function(io) if io.UserInputType==Enum.UserInputType.MouseMovement then updateDrag(io) end end)

local function toggleUI() S.uiVisible=not S.uiVisible; UI.Enabled=S.uiVisible end
HideBtn.MouseButton1Click:Connect(toggleUI)
UIS.InputBegan:Connect(function(io)
	if UIS:GetFocusedTextBox() then return end
	if io.UserInputType==Enum.UserInputType.Keyboard then
		local shift = UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift)
		if (shift and io.KeyCode==Enum.KeyCode.Four) or io.KeyCode==Enum.KeyCode.F2 or io.KeyCode==Enum.KeyCode.Insert or io.KeyCode==Enum.KeyCode.RightControl then
			toggleUI()
		end
	end
end)

print("[Premium Hub v3] prêt. Hitbox + ESP complet + Fly clean. Ouvre/ferme: \"$\" (⇧+4) • F2 • Insert • RightCtrl.")
