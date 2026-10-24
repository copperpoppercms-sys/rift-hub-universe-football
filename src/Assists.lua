-- Opt-in camera lead and bounded native catch input. Never modifies a throw packet or catch hitbox.
return function(ctx,Planner,PassMath)
 local Players=game:GetService("Players")
 local Input=game:GetService("UserInputService")
 local player=Players.LocalPlayer
 local cfg=ctx.Config
 local planner=Planner(ctx,PassMath)
 local M={Held=false,Target=nil,AimStatus="Off",CatchStatus="Off",CatchRequests=0,JumpRequests=0,CatchMethod="None",Alert="",LastError=nil}
 local dead=false
 local press,age,scanAt,nextCatch,nextJump= nil,0,0,0,0
 local catchButton,catchSignal,throwButton,throwSignal,marker
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
  catchButton,catchSignal,throwButton,throwSignal=nil,nil,nil,nil
  local pg=player:FindFirstChild("PlayerGui");if not pg then return end
  local queue=pg:GetChildren();local index,inspected=1,0
  local skip={mainmenu=true,mainmenuscreen=true,graphics=true,loading=true,viewportframe=true}
  while index<=#queue and inspected<6000 do
   local node=queue[index];index+=1;inspected+=1
   local name=node.Name:lower():gsub('[%s_%-]','')
   if not skip[name] and not node:IsDescendantOf(ctx.Gui) and visible(node) then
    if node:IsA("GuiButton") then
     local action=tostring(node:GetAttribute("Action") or ""):lower():gsub('[%s_%-]','')
     local text=node:IsA("TextButton") and node.Text:lower():gsub('<[^>]+>',''):gsub('[%s_%-]','') or ""
     local match=name=="catch" or name=="catchbutton" or name=="catchball" or action=="catch" or text=="catch" or text=="catchball"
     if not match then
      local labels=node:GetDescendants()
      for i,child in ipairs(labels) do
       if i>64 then break end
       if child:IsA("TextLabel") and visible(child) and child.Text:lower():gsub('[%s_%-]','')=="catch" then match=true;break end
      end
     end
     if match then
      for _,event in ipairs({node.Activated,node.MouseButton1Click}) do
       if activeHandlers(event)>0 then catchButton,catchSignal=node,event;break end
      end
     end
     local throwMatch=name=="throw" or name=="throwbutton" or name=="passbutton" or action=="throw" or text=="throw"
     if throwMatch then
      for _,event in ipairs({node.Activated,node.MouseButton1Click}) do
       if activeHandlers(event)>0 then throwButton,throwSignal=node,event;break end
      end
     end
    end
    for _,child in ipairs(node:GetChildren()) do table.insert(queue,child) end
   end
  end
 end
 local function teamKey(plr)
  if plr.Team and not plr.Neutral then return plr.Team end
  for _,node in ipairs({plr,plr.Character or false}) do
   if node then
    for _,key in ipairs({"TeamId","TeamName","Team","Side"}) do
     local value=node:GetAttribute(key)
     if (type(value)=="string" and value~="" and value:lower()~="neutral") or type(value)=="number" then return key..":"..tostring(value) end
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
  planner.Reset()
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
 local function aim(cam,char,root,dt,ball)
  local best,bestRoot,bestChar,bestAngle
  local cone=math.cos(math.rad(cfg.AimCone))
  local ownTeam=teamKey(player)
  for _,plr in ipairs(Players:GetPlayers()) do
   if plr~=player and ownTeam~=nil and teamKey(plr)==ownTeam then
    local c,_,r=character(plr)
    if r and (r.Position-root.Position).Magnitude<=cfg.AimRange then
     local delta=r.Position-cam.CFrame.Position
     local score=delta.Magnitude>.1 and cam.CFrame.LookVector:Dot(delta.Unit) or -1
     local tracking=cfg.BallisticAim and M.Target==plr
     if tracking then
      local horizontal=Vector3.new(delta.X,0,delta.Z)
      local look=Vector3.new(cam.CFrame.LookVector.X,0,cam.CFrame.LookVector.Z)
      tracking=horizontal.Magnitude>.1 and look.Magnitude>.1 and horizontal.Unit:Dot(look.Unit)>.7
     end
     local screen,onScreen=cam:WorldToViewportPoint(r.Position)
     if ((score>=cone and onScreen and screen.Z>0) or tracking) and (not bestAngle or score>bestAngle) then
      local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={char};params.IgnoreWater=true
      local hit=workspace:Raycast(cam.CFrame.Position,delta,params)
      if not hit or hit.Instance:IsDescendantOf(c) then best,bestRoot,bestChar,bestAngle=plr,r,c,score end
     end
    end
   end
  end
  if best~=M.Target then clearMarker() end
  M.Target=best
  if not best then planner.Pause();M.AimStatus="No confirmed teammate in aim cone";return end
  local lead=bestRoot.AssemblyLinearVelocity*cfg.LeadTime
  if lead.Magnitude>12 then lead=lead.Unit*12 end
  local point=bestRoot.Position+Vector3.new(0,1,0)+lead
  local plan
  if cfg.BallisticAim then
   plan=planner.Plan(char,root,ball,bestRoot)
   if not plan then planner.Pause();M.AimStatus=planner.Status;return end
   point=cam.CFrame.Position+plan.Velocity.Unit*1000
  end
  if (point-cam.CFrame.Position).Magnitude>.1 then
   cam.CFrame=cam.CFrame:Lerp(CFrame.lookAt(cam.CFrame.Position,point),1-math.exp(-cfg.AimStrength*dt))
  end
  if cfg.ReceiverMarker and not marker then
   marker=ctx.Create("BillboardGui",{Name="RiftUFReceiver",Adornee=bestChar:FindFirstChild("Head") or bestRoot,Size=UDim2.fromOffset(190,22),
    StudsOffset=Vector3.new(0,3,0),AlwaysOnTop=true},ctx.Gui)
   ctx.Create("TextLabel",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text="RECEIVER · @"..best.Name,
    Font=Enum.Font.GothamBold,TextSize=11,TextColor3=Color3.fromRGB(255,215,131),TextStrokeTransparency=.4},marker)
  elseif not cfg.ReceiverMarker then clearMarker() end
  if cfg.AutoThrow then planner.AutoThrow(char,ball,cam,plan,dt,throwButton,throwSignal) end
  M.AimStatus=cfg.BallisticAim and ("@"..best.Name.." · "..planner.Status) or "Leading @"..best.Name.." · throw manually"
 end
 function M.Step(dt)
  if dead then return end
  local observedDt=math.clamp(tonumber(dt) or 0,0,.2)
  dt=math.min(observedDt,.05);age+=observedDt
  local char,hum,root=eligible()
  if not char then planner.Pause();M.Hold(false);M.CatchStatus="Paused for character/input";M.Alert="";return end
  local ball=ctx.Ball()
  planner.Observe(ball,observedDt)
  if (cfg.AutoCatch or cfg.AutoThrow) and age>=scanAt then M.Scan();scanAt=age+1 end
  M.Alert=cfg.IncomingAlert and incoming(ball,root,45) and "INCOMING FOOTBALL" or ""
  if cfg.AutoJump and age>=nextJump and hum.FloorMaterial~=Enum.Material.Air and incoming(ball,root,12)
   and ball.Position.Y-root.Position.Y>3 and char:GetAttribute("canRun")~=false then
   hum.Jump=true;M.JumpRequests+=1;nextJump=age+.8
  end
  local cam=workspace.CurrentCamera
  local autoPossession=cfg.AutoThrow and planner.HasPossession(char,ball)
  if ((cfg.QBAim and M.Held) or autoPossession) and cam and cam.CameraType~=Enum.CameraType.Scriptable and not cfg.FollowBall then aim(cam,char,root,dt,ball)
  else M.Target=nil;clearMarker();M.AimStatus=cfg.AutoThrow and "Auto throw waiting for possession" or cfg.QBAim and "Hold QB ASSIST or right mouse · aim near teammate" or "Off" end
  if not cfg.AutoCatch then M.CatchStatus="Off";return end
  local native=type(firesignal)=="function" and catchButton~=nil
  local contact=cfg.TouchCatch and type(firetouchinterest)=="function"
  if not native and not contact then M.CatchStatus="Waiting for a supported live catch button";return end
  M.CatchStatus="Watching incoming football"
  if age<nextCatch or not incoming(ball,root,cfg.CatchDistance) then return end
  if char:GetAttribute("busy")==true or char:GetAttribute("canCatch")==false or char:GetAttribute("CanCatch")==false then return end
  if native and (not visible(catchButton) or catchButton:GetAttribute("OnCooldown")==true or (tonumber(catchButton:GetAttribute("CooldownRemaining")) or 0)>0) then return end
  local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={char};params.IgnoreWater=true
  local hit=workspace:Raycast(root.Position,ball.Position-root.Position,params)
  if hit and hit.Instance~=ball then M.CatchStatus="Football obstructed";return end
  nextCatch=age+(cfg.AutoMag and .15 or .4)
  local ok,err
  if native then
   ok,err=pcall(firesignal,catchSignal);M.CatchMethod="Native catch control"
  else
   local attempts=0
   for _,name in ipairs({"LeftHand","RightHand","Left Arm","Right Arm"}) do
    local hand=char:FindFirstChild(name)
    if hand and hand:IsA("BasePart") and (hand.Position-ball.Position).Magnitude<=cfg.CatchDistance then
     local beginOK,reason=pcall(firetouchinterest,hand,ball,0)
     local endOK,endReason=pcall(firetouchinterest,hand,ball,1)
     if beginOK and endOK then attempts+=1 else err=reason or endReason end
    end
   end
   ok=attempts>0;M.CatchMethod="Close-range hand contact"
   if not ok and not err then M.CatchStatus="Football outside hand-contact distance";return end
  end
  if ok then M.CatchRequests+=1;M.CatchStatus=(native and "Catch input requested" or "Hand contact requested").." · server result unverified"
  else M.LastError=tostring(err);M.CatchStatus="Catch input failed" end
 end
 M.Planner=planner
 function M.Diagnostics()
  return table.concat({planner.Diagnostics(),"QB assist: "..M.AimStatus,"Catch: "..M.CatchStatus.." | requests="..M.CatchRequests,
   "Catch control: "..(catchButton and catchButton.Parent and catchButton:GetFullName() or "none"),
   "Catch path: "..M.CatchMethod.." | jump requests="..M.JumpRequests,
   "Input support: firetouchinterest="..tostring(type(firetouchinterest)=="function")..", firesignal="..tostring(type(firesignal)=="function")..", getconnections="..tostring(type(getconnections)=="function"),
   "Assist error: "..tostring(M.LastError),"Solved arcs assume the selected launch model. Native throw requests and hand contacts do not confirm server completion."},"\n")
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
