-- Launch models come from explicit metadata, observed flight, or an explicit manual model.
-- A solved arc is a model result, not proof that UF's throw controller uses the same inputs.
return function(ctx,Math)
 local M={Status="Waiting for a launch model",Requests=0,Source="None"}
 local cfg=ctx.Config
 local sample,clock,profile,stable,attempted= nil,0,nil,0,nil
 local function attribute(nodes,names)
  for _,node in ipairs(nodes) do
   if node then for _,name in ipairs(names) do
    local value=tonumber(node:GetAttribute(name))
    if value and value>0 and value<1500 then return value end
   end end
  end
 end
 local function ownedTool(char)
  for _,node in ipairs(char:GetChildren()) do
   if node:IsA("Tool") then
    local name=node.Name:lower():gsub('[%s_%-]','')
    if name=="football" or name=="ball" or node:GetAttribute("IsFootball")==true then return node end
   end
  end
 end
 function M.Observe(ball,dt)
  clock+=dt
  if not ball or not ball.Parent or ball.Anchored then sample=nil;return end
  if ball:FindFirstAncestorOfClass("Tool") then sample=nil;return end
  local model=ball:FindFirstAncestorOfClass("Model")
  if model and game:GetService("Players"):GetPlayerFromCharacter(model) then sample=nil;return end
  local velocity=ball.AssemblyLinearVelocity
  if velocity.Magnitude<20 then sample=nil;return end
  if sample and sample.Ball==ball then
   local duration=clock-sample.Clock
   if duration>=.08 then
    local acceleration=(velocity-sample.Velocity)*(1/duration)
    local horizontal=Vector3.new(acceleration.X,0,acceleration.Z).Magnitude
    local gravity=-acceleration.Y
    if gravity>=1 and gravity<=350 and horizontal<25 then
     -- Use only consecutive descending acceleration samples; never infer from a collision.
     local n=(sample.Valid or 0)+1
     local estimate=sample.Gravity and sample.Gravity*.65+gravity*.35 or gravity
     if n>=3 then
      profile={Speed=sample.LaunchSpeed,Gravity=estimate,Ball=ball,At=clock}
     end
     sample.Valid=n;sample.Gravity=estimate
    else sample.Valid=0 end
    sample.Clock=clock;sample.Velocity=velocity
   end
  else sample={Ball=ball,Clock=clock,Velocity=velocity,LaunchSpeed=velocity.Magnitude,Valid=0} end
 end
 function M.Model(char,ball)
  local tool=ownedTool(char)
  local nodes={tool or false,ball or false,char}
  local speed=attribute(nodes,{"LaunchSpeed","ThrowSpeed","ProjectileSpeed","BallSpeed"})
  local gravity=attribute(nodes,{"ProjectileGravity","BallGravity"})
  if speed and gravity then M.Source="Replicated launch metadata";return speed,gravity end
  if cfg.ManualPassModel then M.Source="Manual model · must match game's actual power";return cfg.PassSpeed,cfg.PassGravity end
  if profile and clock-profile.At<90 then
   M.Source="Observed pass estimate · power equivalence unverified"
   return profile.Speed,profile.Gravity
  end
  M.Source="None";return nil,nil
 end
 function M.Plan(char,root,ball,targetRoot)
  local speed,gravity=M.Model(char,ball)
  if not speed then M.Status="Waiting to observe a pass or find launch metadata";return end
  local owned=ball and ball:IsDescendantOf(char)
  local origin=owned and ball.Position or root.Position+Vector3.new(0,2,0)
  local plan,reason=Math.Solve(origin,targetRoot.Position+Vector3.new(0,1,0),targetRoot.AssemblyLinearVelocity,speed,gravity,5)
  if not plan then M.Status=reason;return end
  -- Validate the modeled arc against solid geometry before requesting a throw.
  local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.IgnoreWater=true
  params.FilterDescendantsInstances={char,ball or char}
  local previous=origin
  for i=1,12 do
   local point=Math.Position(plan,plan.Time*i/12)
   local hit=workspace:Raycast(previous,point-previous,params)
   if hit and not hit.Instance:IsDescendantOf(targetRoot.Parent) then M.Status="Modeled pass arc blocked";return end
   previous=point
  end
  M.Status=string.format("Modeled intercept %.2fs · %s",plan.Time,M.Source)
  M.LastPlan=plan;return plan
 end
 function M.HasPossession(char,ball)
  local key=ownedTool(char) or ball and ball:IsDescendantOf(char) and ball
  if not key then attempted=nil;stable=0 end
  return key
 end
 function M.AutoThrow(char,ball,cam,plan,dt,button,signal)
  if not cfg.AutoThrow then stable=0;return end
  local tool=ownedTool(char)
  local possessed=M.HasPossession(char,ball)
  if not possessed then attempted=nil;stable=0;M.Status="Auto throw waiting for possession";return end
  if attempted==possessed then M.Status="Throw already requested for this possession";return end
  if not plan then stable=0;return end
  if char:GetAttribute("busy")==true or char:GetAttribute("canThrow")==false or possessed:GetAttribute("OnCooldown")==true then stable=0;return end
  if cam.CFrame.LookVector:Dot(plan.Velocity.Unit)<math.cos(math.rad(1)) then stable=0;return end
  stable+=dt;if stable<.12 then return end
  if button and button.Parent then
   local node=button
   while node do
    if node:IsA("GuiObject") and not node.Visible or node:IsA("ScreenGui") and not node.Enabled then M.Status="Throw control hidden";return end
    node=node.Parent
   end
   if button:GetAttribute("OnCooldown")==true or (tonumber(button:GetAttribute("CooldownRemaining")) or 0)>0 then M.Status="Throw cooldown active";return end
  end
  local ok,err
  if button and button.Parent and signal and type(firesignal)=="function" then
   ok,err=pcall(firesignal,signal)
  elseif tool and tool.Enabled~=false then ok,err=pcall(function() tool:Activate() end)
  else M.Status="No native throw button or equipped football tool";return end
  attempted=possessed;stable=0
  if ok then M.Requests+=1;M.Status="Native throw requested · launch unverified"
  else M.Status="Throw request failed: "..tostring(err) end
 end
 function M.Pause() stable=0 end
 function M.Reset() stable=0;attempted=nil;M.LastPlan=nil end
 function M.Diagnostics() return "Pass planner: "..M.Status.." | requests="..M.Requests.." | model="..M.Source end
 return M
end
