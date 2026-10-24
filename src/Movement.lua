-- Owned movement settings. No speed loop, player teleport, or network interception.
return function(ctx)
 local Input=game:GetService("UserInputService")
 local Run=game:GetService("RunService")
 local player=game:GetService("Players").LocalPlayer
 local cfg=ctx.Config
 local M={JumpRequests=0}
 local collisions,connections={},{}
 local owner,property,base,applied,requested,blocked
 local dead=false
 local function restoreJump()
  if owner and owner[property]==applied then owner[property]=base end
  owner,property,base,applied,requested=nil,nil,nil,nil,nil
 end
 local function restoreCollisions()
  for part,value in pairs(collisions) do pcall(function() if part.Parent and part.CanCollide==false then part.CanCollide=value end end) end
  table.clear(collisions)
 end
 local function body()
  local c=player.Character;local h=c and c:FindFirstChildOfClass("Humanoid")
  if not c or not h or h.Health<=0 or h.PlatformStand or h.Sit or not ctx.Focused() or Input:GetFocusedTextBox()
   or c:GetAttribute("LOCKED_INPUTS")==true or c:GetAttribute("cutsceneLock")==true or c:GetAttribute("canRun")==false then return end
  return c,h
 end
 function M.Step()
  if dead then return end
  local c,h=body()
  local prop=h and (h.UseJumpPower and "JumpPower" or "JumpHeight")
  if owner and (owner~=h or property~=prop or owner[property]~=applied) then
   blocked={Hum=owner,Property=property,Value=requested};restoreJump()
  end
  if not cfg.JumpBoost or not h then restoreJump()
  else
   local value=prop=="JumpPower" and cfg.JumpPower or cfg.JumpHeight
   if not(blocked and blocked.Hum==h and blocked.Property==prop and blocked.Value==value) and (owner~=h or property~=prop or requested~=value) then
    if owner~=h or property~=prop then restoreJump();owner=h;property=prop;base=h[prop] end
    requested=value;applied=value;h[prop]=value
   end
  end
  if not cfg.Noclip or not c then restoreCollisions()
  else
   for _,part in ipairs(c:GetDescendants()) do
    if part:IsA("BasePart") and part.CanCollide then
     if collisions[part]==nil then collisions[part]=part.CanCollide end
     part.CanCollide=false
    end
   end
  end
 end
 function M.Reset() restoreJump();restoreCollisions();blocked=nil end
 local function connect(signal,fn) table.insert(connections,signal:Connect(fn)) end
 connect(Input.JumpRequest,function()
  if dead or not cfg.InfiniteJump then return end
  local _,h=body()
  if h then h:ChangeState(Enum.HumanoidStateType.Jumping);M.JumpRequests+=1 end
 end)
 connect(Run.Stepped,function() local ok,err=pcall(M.Step);if not ok then M.LastError=tostring(err);M.Reset() end end)
 connect(player.CharacterRemoving,M.Reset)
 function M.Destroy()
  if dead then return end
  M.Reset();dead=true
  for _,c in ipairs(connections) do c:Disconnect() end;table.clear(connections)
 end
 return M
end
