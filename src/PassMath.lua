-- Constant-velocity receiver intercept under constant downward projectile gravity.
local M={}
function M.Solve(origin,target,receiverVelocity,speed,gravity,maxTime)
 if speed<=0 or gravity<0 or speed~=speed or gravity~=gravity then return nil,"Invalid launch model" end
 local delta=target-origin
 local g=Vector3.new(0,-gravity,0)
 local function velocity(t) return (delta+receiverVelocity*t-g*(.5*t*t))*(1/t) end
 local function errorAt(t) return velocity(t).Magnitude-speed end
 local previousTime,previousError=.06,errorAt(.06)
 local limit=maxTime or 5
 -- The first root is the lower/shorter arc. Bracket before refining.
 for i=1,160 do
  local t=.06+(limit-.06)*i/160
  local e=errorAt(t)
  if previousError>0 and e<=0 then
   local lo,hi=previousTime,t
   for _=1,28 do
    local mid=(lo+hi)*.5
    if errorAt(mid)>0 then lo=mid else hi=mid end
   end
   local flight=(lo+hi)*.5
   return {Velocity=velocity(flight),Time=flight,Point=target+receiverVelocity*flight,Origin=origin,Gravity=gravity}
  end
  previousTime,previousError=t,e
 end
 return nil,"Receiver outside modeled pass range"
end
function M.Position(plan,time)
 return plan.Origin+plan.Velocity*time+Vector3.new(0,-plan.Gravity*.5*time*time,0)
end
return M
