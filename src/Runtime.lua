-- Universe Football first release: replicated ball/player utilities and owned settings.
return function(Kit,Brand,Interface,Assists)
 local Players=game:GetService("Players")
 local Run=game:GetService("RunService")
 local Input=game:GetService("UserInputService")
 local player=Players.LocalPlayer
 local defaults={QBAim=false,AutoCatch=false,IncomingAlert=false,ReceiverMarker=false,AimCone=6,AimRange=160,AimStrength=4,LeadTime=.18,CatchDistance=5,
  BallHighlight=false,BallName=false,FollowBall=false,FieldOfView=80,CustomFOV=false,
  SpeedEnabled=false,WalkSpeed=24,PlayerESP=false,PlayerNames=false,ShowTeammates=true,FillTransparency=.65,ReduceMotion=false}
 local cfg=table.clone(defaults)
 local API={Game="Universe Football",Version="1.2",Config=cfg,Status="Starting",Alive=true,Candidates=0,Inspected=0,ScanCapped=false}
 local connections,cleaners,candidates,rows={}, {}, {}, {}
 local focused=true
 local scanQueue,scanIndex,missingAge={},1,0
 local ignored={mainmenu=true,mainmenuscreen=true,lockerroom=true,graphics=true,loading=true,viewportframe=true}
 local function excluded(node)
  local current=node
  while current and current~=workspace do
   if ignored[current.Name:lower():gsub("[%s_%-]","")] then return true end
   current=current.Parent
  end
  return false
 end
 local speedHum,speedBase,speedApplied,speedRequest,speedBlocked
 local fovCam,fovBase,fovApplied,fovRequest,fovBlocked
 local followCam,followBase,followApplied,followBlocked
 local ballHighlight,ballLabel,ballVisual
 local gui=Kit.create("ScreenGui",{Name="RiftUniverseFootball",ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=905})
 local parent=type(gethui)=="function" and gethui() or game:GetService("CoreGui")
 local ok=pcall(function() gui.Parent=parent end)
 if not ok or not gui.Parent then gui.Parent=player:WaitForChild("PlayerGui") end
 API.Gui=gui
 local function connect(signal,fn)
  local c=signal:Connect(function(...) if API.Alive then fn(...) end end);table.insert(connections,c);return c
 end
 local function hum()
  local c=player.Character;return c and c:FindFirstChildOfClass("Humanoid")
 end
 local function restoreSpeed()
  if speedHum and speedHum.WalkSpeed==speedApplied then speedHum.WalkSpeed=speedBase end
  speedHum,speedBase,speedApplied,speedRequest=nil,nil,nil,nil
 end
 local function restoreFOV()
  if fovCam and fovCam.FieldOfView==fovApplied then fovCam.FieldOfView=fovBase end
  fovCam,fovBase,fovApplied,fovRequest=nil,nil,nil,nil
 end
 local function restoreFollow()
  if followCam and followCam.CameraSubject==followApplied then
   local subject=followBase and followBase.Parent and followBase or hum()
   if subject then followCam.CameraSubject=subject end
  end
  followCam,followBase,followApplied=nil,nil,nil
 end
 local function clearBallVisual()
  if ballHighlight then ballHighlight:Destroy();ballHighlight=nil end
  if ballLabel then ballLabel:Destroy();ballLabel=nil end
  ballVisual=nil
 end
 local function clearRow(plr)
  local row=rows[plr];if not row then return end
  row.Highlight:Destroy();row.Tag:Destroy();rows[plr]=nil
 end
 local function clearRows() for plr in pairs(rows) do clearRow(plr) end end
 local function named(node)
  local name=node.Name:lower():gsub('[%s_%-]','')
  return name=="football" or name=="matchball" or node:GetAttribute("IsFootball")==true
 end
 local function ballPart(node)
  if not node:IsA("BasePart") or excluded(node) then return false end
  if node.Anchored and node:GetAttribute("IsFootball")~=true then return false end
  if named(node) then return true end
  if node.Name~="Handle" and node.Name~="Ball" and node.Name~="MeshPart" then return false end
  local p=node.Parent
  for _=1,3 do
   if not p or p==workspace then break end
   if (p:IsA("Model") or p:IsA("Tool")) and named(p) then return true end
   p=p.Parent
  end
  return false
 end
 local function addCandidate(node)
  if API.Candidates>=128 or not ballPart(node) or candidates[node] then return end
  candidates[node]=true;API.Candidates+=1
 end
 function API.Rescan()
  table.clear(candidates);API.Candidates=0;API.Inspected=0;API.ScanCapped=false
  scanQueue=workspace:GetChildren();scanIndex=1;API.Scanning=true
 end
 local function scanBatch()
  local budget=1200
  while budget>0 and scanIndex<=#scanQueue do
   local node=scanQueue[scanIndex];scanIndex+=1;budget-=1;API.Inspected+=1
   if node.Parent and not excluded(node) then
    addCandidate(node)
    for _,child in ipairs(node:GetChildren()) do table.insert(scanQueue,child) end
   end
  end
  if scanIndex>#scanQueue then scanQueue={};scanIndex=1;API.Scanning=false end
 end
 local function chooseBall()
  local own=player.Character;local root=own and own:FindFirstChild("HumanoidRootPart")
  local best,distance,bestScore=nil,math.huge,math.huge
  for part in pairs(candidates) do
   if not part.Parent or not part:IsDescendantOf(workspace) then candidates[part]=nil;API.Candidates-=1
   else
    local d=root and (part.Position-root.Position).Magnitude or 0
    local score=d-(part.AssemblyLinearVelocity.Magnitude>3 and 35 or 0)
    if not best or score<bestScore then best,distance,bestScore=part,d,score end
   end
  end
  return best,distance
 end
 local function updateBall(ball,distance)
  if ball~=ballVisual then clearBallVisual();ballVisual=ball end
  if not ball then API.Status=API.Scanning and "Scanning live world · menu scenery excluded" or "No football found · watching for the next play";return end
  local held=ball:FindFirstAncestorOfClass("Model")
  local carrier=held and Players:GetPlayerFromCharacter(held)
  API.Status=(carrier and "Carrier: @"..carrier.Name or "Football: "..ball.Name)..string.format(" · %.0f studs · %.0f studs/s",distance,ball.AssemblyLinearVelocity.Magnitude)
  if API.Candidates>1 then API.Status..=" · live priority / "..API.Candidates.." candidates" end
  if cfg.BallHighlight and not ballHighlight then
   ballHighlight=Kit.create("Highlight",{Name="RiftFootballHighlight",Adornee=ball,DepthMode=Enum.HighlightDepthMode.AlwaysOnTop,
    FillColor=Color3.fromRGB(255,178,72),OutlineColor=Color3.fromRGB(255,225,168),FillTransparency=.55},ball)
  elseif not cfg.BallHighlight and ballHighlight then ballHighlight:Destroy();ballHighlight=nil end
  if cfg.BallName and not ballLabel then
   ballLabel=Kit.create("BillboardGui",{Name="RiftFootballLabel",Adornee=ball,AlwaysOnTop=true,Size=UDim2.fromOffset(150,22),StudsOffset=Vector3.new(0,2,0)},gui)
   Kit.create("TextLabel",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text="FOOTBALL",TextColor3=Color3.fromRGB(255,216,145),
    Font=Enum.Font.GothamBold,TextSize=12,TextStrokeTransparency=.35},ballLabel)
  elseif not cfg.BallName and ballLabel then ballLabel:Destroy();ballLabel=nil end
 end
 local function updatePlayers()
  for _,plr in ipairs(Players:GetPlayers()) do
   if plr~=player then
    local c=plr.Character;local h=c and c:FindFirstChildOfClass("Humanoid");local head=c and (c:FindFirstChild("Head") or c:FindFirstChild("HumanoidRootPart"))
    local same=not plr.Neutral and not player.Neutral and plr.Team~=nil and plr.Team==player.Team
    if not (cfg.PlayerESP or cfg.PlayerNames) or not c or not c.Parent or not h or h.Health<=0 or not head or (same and not cfg.ShowTeammates) then clearRow(plr)
    else
     local row=rows[plr]
     if row and row.Character~=c then clearRow(plr);row=nil end
     if not row then
      local highlight=Kit.create("Highlight",{Name="RiftUFPlayer",Adornee=c,DepthMode=Enum.HighlightDepthMode.AlwaysOnTop},c)
      local tag=Kit.create("BillboardGui",{Name="RiftUFUsername",Adornee=head,Size=UDim2.fromOffset(180,24),StudsOffset=Vector3.new(0,2.2,0),AlwaysOnTop=true},gui)
      local label=Kit.create("TextLabel",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text="@"..plr.Name,Font=Enum.Font.GothamBold,TextSize=12,TextStrokeTransparency=.35},tag)
      row={Character=c,Highlight=highlight,Tag=tag,Label=label};rows[plr]=row
     end
     local color=plr.Team and plr.TeamColor.Color or Color3.fromRGB(198,204,218)
     row.Highlight.Enabled=cfg.PlayerESP;row.Highlight.FillColor=color;row.Highlight.OutlineColor=color;row.Highlight.FillTransparency=cfg.FillTransparency
     row.Tag.Enabled=cfg.PlayerNames;row.Tag.Adornee=head;row.Label.TextColor3=color
    end
   end
  end
 end
 local function settings(ball)
  local h=hum()
  if speedHum and (speedHum~=h or speedHum.WalkSpeed~=speedApplied) then
   speedBlocked={Hum=speedHum,Request=speedRequest};restoreSpeed()
  end
  local c=player.Character
  local locked=c and (c:GetAttribute("LOCKED_INPUTS")==true or c:GetAttribute("canRun")==false or c:GetAttribute("cutsceneLock")==true)
  if not cfg.SpeedEnabled or not focused or not h or h.Health<=0 or locked then restoreSpeed()
  elseif not(speedBlocked and speedBlocked.Hum==h and speedBlocked.Request==cfg.WalkSpeed) and (speedHum~=h or speedRequest~=cfg.WalkSpeed) then
   if speedHum~=h then restoreSpeed();speedHum=h;speedBase=h.WalkSpeed end
   speedRequest=cfg.WalkSpeed;speedApplied=cfg.WalkSpeed;h.WalkSpeed=speedApplied
  end
  local cam=workspace.CurrentCamera
  if fovCam and (fovCam~=cam or fovCam.FieldOfView~=fovApplied) then fovBlocked={Camera=fovCam,Request=fovRequest};restoreFOV() end
  local scripted=cam and cam.CameraType==Enum.CameraType.Scriptable
  if not cfg.CustomFOV or not cam or scripted or not focused then restoreFOV()
  elseif not(fovBlocked and fovBlocked.Camera==cam and fovBlocked.Request==cfg.FieldOfView) and (fovCam~=cam or fovRequest~=cfg.FieldOfView) then
   if fovCam~=cam then restoreFOV();fovCam=cam;fovBase=cam.FieldOfView end
   fovRequest=cfg.FieldOfView;fovApplied=cfg.FieldOfView;cam.FieldOfView=fovApplied
  end
  if followCam and (followCam~=cam or followCam.CameraSubject~=followApplied) then followBlocked=followCam;restoreFollow() end
  if not cfg.FollowBall or not cam or scripted or not focused or not ball then restoreFollow()
  elseif followBlocked~=cam then
   if not followCam then followCam=cam;followBase=cam.CameraSubject end
   followApplied=ball;cam.CameraSubject=ball
  end
 end
 function API.SetOption(key,value)
  if not API.Alive or cfg[key]==nil or type(value)~=type(cfg[key]) then return false end
  if type(value)=="number" then
   if value~=value or math.abs(value)==math.huge then return false end
   local bounds={AimCone={3,12},AimRange={25,220},AimStrength={2,8},LeadTime={0,.4},CatchDistance={2,6},WalkSpeed={16,60},FieldOfView={50,110},FillTransparency={0,1}}
   value=math.clamp(value,bounds[key][1],bounds[key][2])
  end
  cfg[key]=value
  if key=="QBAim" and not value and API.Assists then API.Assists.Hold(false) end
  if key=="FollowBall" and value and API.Assists then API.Assists.Hold(false) end
  if key=="SpeedEnabled" then restoreSpeed();speedBlocked=nil end
  if key=="CustomFOV" then restoreFOV();fovBlocked=nil end
  if key=="FollowBall" then restoreFollow();followBlocked=nil end
  if API.UI then API.UI.Step() end
  return true
 end
 function API.Reset()
  if API.Assists then API.Assists.Reset() end
  restoreSpeed();restoreFOV();restoreFollow();clearRows();clearBallVisual()
  speedBlocked,fovBlocked,followBlocked=nil,nil,nil
  for k,v in pairs(defaults) do cfg[k]=v end
  if API.UI then API.UI.Step() end
 end
 function API.Diagnostics()
  local ball=API.Ball
  return table.concat({"Rift Hub / Universe Football / "..API.Version,"PlaceId: "..game.PlaceId.." | GameId: "..game.GameId,
   "Status: "..API.Status,"Ball: "..(ball and ball.Parent and ball:GetFullName() or "none"),
   "Candidates: "..API.Candidates.." | inspected: "..API.Inspected.." | scanning: "..tostring(API.Scanning),
   "Speed: "..tostring(hum() and hum().WalkSpeed).." | game override preserved: "..tostring(speedBlocked~=nil),
   API.Assists and API.Assists.Diagnostics() or "Assists not initialized",
   "Last error: "..tostring(API.LastError),
   "No remotes invoked. Ball discovery uses exact names/IsFootball; game-specific throw/catch wiring is not assumed."},"\n")
 end
 function API.CopyDiagnostics()
  local report=API.Diagnostics();local copy=setclipboard or toclipboard
  local ok=type(copy)=="function" and pcall(copy,report)
  if not ok then print(report) end
  return report,ok==true
 end
 function API.Unload()
  if not API.Alive then return end
  API.Reset();API.Alive=false
  if API.Assists then API.Assists.Destroy() end
  if API.UI then API.UI.Destroy() end
  for _,clean in ipairs(cleaners) do pcall(clean) end
  for _,connection in ipairs(connections) do connection:Disconnect() end
  table.clear(connections);gui:Destroy();API.Gui=nil
  if API.OnUnload then API.OnUnload() end
 end
 local age=0
 function API.Step(dt)
  if not API.Alive then return end
  age+=math.clamp(tonumber(dt) or 0,0,.2)
  if age<.15 then return end;age=0
  local ok,err=pcall(function()
   if not API.Scanning and API.Candidates==0 then
    missingAge+=.15
    if missingAge>=3 then API.Rescan();missingAge=0 end
   else missingAge=0 end
   if API.Scanning then scanBatch() end
   local ball,distance=chooseBall();API.Ball=ball
   updateBall(ball,distance);updatePlayers();settings(ball)
   if API.UI then API.UI.Step() end
  end)
  if not ok then API.LastError=tostring(err);API.Reset();API.Status="Paused after error · copy diagnostics" end
 end
 local started,err=pcall(function()
  API.Assists=Assists({Config=cfg,Gui=gui,Create=Kit.create,Ball=function() return API.Ball end,Focused=function() return focused end})
  API.HoldQB=API.Assists.Hold
  API.UI=Interface({API=API,Config=cfg,Gui=gui,Brand=Brand,
   RegisterCleanup=function(fn) table.insert(cleaners,fn) end,
   Drag=function() end,Focus=function(on) focused=on end})
  API.Rescan()
  connect(workspace.DescendantAdded,addCandidate)
  connect(Players.PlayerRemoving,clearRow)
  connect(player.CharacterRemoving,function() restoreSpeed();speedBlocked=nil end)
  connect(gui.Destroying,API.Unload)
  connect(Run.Heartbeat,API.Step)
  connect(Run.RenderStepped,function(dt)
   local ok,err=pcall(API.Assists.Step,dt)
   if not ok then API.Assists.LastError=tostring(err);API.Reset() end
  end)
  API.Step(.15)
 end)
 if not started then API.Unload();error("Rift Universe Football startup: "..tostring(err)) end
 return API
end
