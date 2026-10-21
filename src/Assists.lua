-- Opt-in camera lead and bounded native catch input. Never modifies a throw packet or catch hitbox.
return function(ctx)
 local Players=game:GetService("Players")
 local Input=game:GetService("UserInputService")
 local player=Players.LocalPlayer
 local cfg=ctx.Config
 local M={Held=false,Target=nil,AimStatus="Off",CatchStatus="Off",CatchRequests=0,Alert="",LastError=nil}
 local dead=false
 local press,age,scanAt,nextCatch= nil,0,0,0
 local catchButton,catchSignal,marker
 local connections={}
 local function connect(event,fn) table.insert(connections,event:Connect(fn)) end
 local function clearMarker() if marker then marker:Destroy();marker=nil end end
 local function character(plr)
  local char=plr.Character
  local hum=char and char:FindFirstChildOfClass("Humanoid")
  local root=char and char:FindFirstChild("HumanoidRootPart")
  if char and char.Parent and hum and hum.Health>0 and root then return char,hum,root end
 end
 local function visible(button)
  if not button or not button.Parent then return false end
  local node=button
  while node do
   if node:IsA("GuiObject") and not node.Visible or node:IsA("ScreenGui") and not node.Enabled then return false end
   node=node.Parent
  end
  return true
 end
 local function activeHandlers(event)
  if type(getconnections)~="function" then return 0 end
  local ok,handlers=pcall(getconnections,event)
  if not ok then return 0 end
  local count=0
  for _,handler in ipairs(handlers) do if handler.Connected~=false and handler.Enabled~=false then count+=1 end end
  return count
 end
 function M.Scan()
  catchButton,catchSignal=nil,nil
  local pg=player:FindFirstChild("PlayerGui");if not pg then return end
  local inspected=0
  for _,node in ipairs(pg:GetDescendants()) do
   inspected+=1;if inspected>4000 then break end
   if node:IsA("GuiButton") and not node:IsDescendantOf(ctx.Gui) then
    local name=node.Name:lower():gsub('[%s_%-]','')
    local action=node:GetAttribute("Action")
    if name=="catch" or name=="catchbutton" or name=="catchball" or action=="Catch" then
     if visible(node) then
      for _,event in ipairs({node.Activated,node.MouseButton1Click}) do
       if activeHandlers(event)>0 then catchButton,catchSignal=node,event;return end
      end
     end
    end
   end
  end
 end
 function M.Hold(on,input)
  if dead then return end
  if on then
   if not cfg.QBAim or M.Held then return end
   press=input;M.Held=true
  else
   if input and press and input~=press and not(input.UserInputType==Enum.UserInputType.MouseButton2 and press.UserInputType==Enum.UserInputType.MouseButton2) then return end
   press=nil;M.Held=false;M.Target=nil;clearMarker()
  end
 end
 function M.Reset()
  M.Hold(false);M.Target=nil;M.Alert="";M.AimStatus="Off";M.CatchStatus="Off";clearMarker()
 end
 local function eligible()
  local char,hum,root=character(player)
  local camera=workspace.CurrentCamera
  if camera and camera.CameraType==Enum.CameraType.Scriptable then return end
  if not char or root.Anchored or hum.PlatformStand or hum.Sit or char:GetAttribute("LOCKED_INPUTS")==true
   or char:GetAttribute("cutsceneLock")==true or Input:GetFocusedTextBox() or not ctx.Focused() then return end
  return char,hum,root
 end
 local function incoming(ball,root,limit)
  if not ball or not ball.Parent then return false end
  if ball:FindFirstAncestorOfClass("Tool") then return false end
  local owner=ball:FindFirstAncestorOfClass("Model")
  if owner and Players:GetPlayerFromCharacter(owner) then return false end
  local delta=root.Position-ball.Position
  if delta.Magnitude>limit or delta.Magnitude<.05 then return false end
  local velocity=ball.AssemblyLinearVelocity-root.AssemblyLinearVelocity
  return velocity.Magnitude>2 and velocity.Unit:Dot(delta.Unit)>.45
 end
 local function aim(cam,char,root,dt)
  local best,bestRoot,bestChar,bestAngle
  local cone=math.cos(math.rad(cfg.AimCone))
  for _,plr in ipairs(Players:GetPlayers()) do
   if plr~=player and not player.Neutral and not plr.Neutral and player.Team and plr.Team==player.Team then
    local c,_,r=character(plr)
    if r and (r.Position-root.Position).Magnitude<=cfg.AimRange then
     local delta=r.Position-cam.CFrame.Position
     local score=delta.Magnitude>.1 and cam.CFrame.LookVector:Dot(delta.Unit) or -1
     local screen,onScreen=cam:WorldToViewportPoint(r.Position)
     if score>=cone and onScreen and screen.Z>0 and (not bestAngle or score>bestAngle) then
      local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={char};params.IgnoreWater=true
      local hit=workspace:Raycast(cam.CFrame.Position,delta,params)
      if not hit or hit.Instance:IsDescendantOf(c) then best,bestRoot,bestChar,bestAngle=plr,r,c,score end
     end
    end
   end
  end
  if best~=M.Target then clearMarker() end
  M.Target=best
  if not best then M.AimStatus="No confirmed teammate in aim cone";return end
  local lead=bestRoot.AssemblyLinearVelocity*cfg.LeadTime
  if lead.Magnitude>12 then lead=lead.Unit*12 end
  local point=bestRoot.Position+Vector3.new(0,1,0)+lead
  if (point-cam.CFrame.Position).Magnitude>.1 then
   cam.CFrame=cam.CFrame:Lerp(CFrame.lookAt(cam.CFrame.Position,point),1-math.exp(-cfg.AimStrength*dt))
  end
  if cfg.ReceiverMarker and not marker then
   marker=ctx.Create("BillboardGui",{Name="RiftUFReceiver",Adornee=bestChar:FindFirstChild("Head") or bestRoot,Size=UDim2.fromOffset(190,22),
    StudsOffset=Vector3.new(0,3,0),AlwaysOnTop=true},ctx.Gui)
   ctx.Create("TextLabel",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text="RECEIVER · @"..best.Name,
    Font=Enum.Font.GothamBold,TextSize=11,TextColor3=Color3.fromRGB(255,215,131),TextStrokeTransparency=.4},marker)
  elseif not cfg.ReceiverMarker then clearMarker() end
  M.AimStatus="Leading @"..best.Name.." · throw manually"
 end
 function M.Step(dt)
  if dead then return end
  dt=math.clamp(tonumber(dt) or 0,0,.05);age+=dt
  local char,_,root=eligible()
  if not char then M.Hold(false);M.CatchStatus="Paused for character/input";M.Alert="";return end
  local ball=ctx.Ball()
  M.Alert=cfg.IncomingAlert and incoming(ball,root,45) and "INCOMING FOOTBALL" or ""
  local cam=workspace.CurrentCamera
  if cfg.QBAim and M.Held and cam and cam.CameraType~=Enum.CameraType.Scriptable and not cfg.FollowBall then aim(cam,char,root,dt)
  else M.Target=nil;clearMarker();M.AimStatus=cfg.QBAim and "Hold QB ASSIST or right mouse · aim near teammate" or "Off" end
  if not cfg.AutoCatch then M.CatchStatus="Off";return end
  if age>=scanAt then M.Scan();scanAt=age+1 end
  if type(firesignal)~="function" or not catchButton then M.CatchStatus="No supported catch control · copy diagnostics";return end
  M.CatchStatus="Watching incoming football"
  if age<nextCatch or not incoming(ball,root,cfg.CatchDistance) then return end
  if char:GetAttribute("busy")==true or char:GetAttribute("canCatch")==false or char:GetAttribute("CanCatch")==false then return end
  if not visible(catchButton) or catchButton:GetAttribute("OnCooldown")==true or (tonumber(catchButton:GetAttribute("CooldownRemaining")) or 0)>0 then return end
  local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={char};params.IgnoreWater=true
  local hit=workspace:Raycast(root.Position,ball.Position-root.Position,params)
  if hit and hit.Instance~=ball then M.CatchStatus="Football obstructed";return end
  nextCatch=age+.4
  local ok,err=pcall(firesignal,catchSignal)
  if ok then M.CatchRequests+=1;M.CatchStatus="Catch input requested · server result unverified"
  else M.LastError=tostring(err);M.CatchStatus="Catch input failed" end
 end
 function M.Diagnostics()
  return table.concat({"QB assist: "..M.AimStatus,"Catch: "..M.CatchStatus.." | requests="..M.CatchRequests,
   "Catch control: "..(catchButton and catchButton.Parent and catchButton:GetFullName() or "none"),
   "Input support: firesignal="..tostring(type(firesignal)=="function")..", getconnections="..tostring(type(getconnections)=="function"),
   "Assist error: "..tostring(M.LastError),"QB assist changes camera aim only; throw power/arc and catch acceptance remain game-controlled."},"\n")
 end
 connect(Input.InputBegan,function(input,processed)
  if not processed and input.UserInputType==Enum.UserInputType.MouseButton2 then M.Hold(true,input) end
 end)
 connect(Input.InputEnded,function(input) M.Hold(false,input) end)
 connect(Input.WindowFocusReleased,function() M.Hold(false) end)
 function M.Destroy()
  if dead then return end
  M.Reset();dead=true
  for _,c in ipairs(connections) do c:Disconnect() end
  table.clear(connections)
 end
 return M
end
