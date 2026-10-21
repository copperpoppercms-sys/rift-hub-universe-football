-- A minimal simulated Roblox client; exercises the complete standalone file.
local allSignals, allInstances, checks = {}, {}, 0
math.randomseed(145)
local function check(value, message)
	checks += 1
	assert(value, message)
end
local function signal()
	local s = { handlers = {} }; table.insert(allSignals, s)
	function s:Connect(fn)
		local c = { Connected = true, fn = fn, Function = fn }
		function c:Disconnect() self.Connected = false end
		table.insert(self.handlers, c)
		return c
	end
	function s:Fire(...)
		for _, c in ipairs(table.clone(self.handlers)) do if c.Connected then c.fn(...) end end
	end
	return s
end
local function enum()
	return setmetatable({}, { __index = function(t, key) local v = enum(); rawset(t, key, v); return v end })
end
local Enum = enum()
Enum.RenderPriority.Camera.Value = 200
local V2 = {}
V2.__index = function(t, k) if k == "Magnitude" then return math.sqrt(t.X*t.X+t.Y*t.Y) end; return V2[k] end
V2.__add = function(a,b) return setmetatable({ X=a.X+b.X, Y=a.Y+b.Y }, V2) end
V2.__sub = function(a,b) return setmetatable({ X=a.X-b.X, Y=a.Y-b.Y }, V2) end
V2.__eq = function(a,b) return a.X == b.X and a.Y == b.Y end
V2.__mul = function(a,b) return setmetatable({X=a.X*b,Y=a.Y*b},V2) end
local Vector2 = { new = function(x,y) return setmetatable({ X=x or 0, Y=y or 0 }, V2) end }
local V3 = {}
V3.__index = function(t,k)
	if k == "Magnitude" then return math.sqrt(t.X*t.X+t.Y*t.Y+t.Z*t.Z) end
	if k == "Unit" then local m=math.sqrt(t.X*t.X+t.Y*t.Y+t.Z*t.Z); return setmetatable({X=t.X/m,Y=t.Y/m,Z=t.Z/m},V3) end
	return V3[k]
end
V3.__sub = function(a,b) return setmetatable({ X=a.X-b.X,Y=a.Y-b.Y,Z=a.Z-b.Z }, V3) end
V3.__add = function(a,b) return setmetatable({ X=a.X+b.X,Y=a.Y+b.Y,Z=a.Z+b.Z }, V3) end
V3.__mul = function(a,b) if type(a)=="number" then a,b=b,a end; return setmetatable({ X=a.X*b,Y=a.Y*b,Z=a.Z*b }, V3) end
function V3:Dot(b) return self.X*b.X+self.Y*b.Y+self.Z*b.Z end
local Vector3 = { new = function(x,y,z) return setmetatable({ X=x or 0,Y=y or 0,Z=z or 0 }, V3) end }
local RaycastParams={new=function() return {} end}
local OverlapParams={new=function() return {} end}
local UDim = { new = function(scale, offset) return { Scale=scale or 0, Offset=offset or 0 } end }
local UDim2 = {
	new = function(xs,xo,ys,yo) return { X=UDim.new(xs,xo), Y=UDim.new(ys,yo) } end,
	fromOffset = function(x,y) return { X=UDim.new(0,x), Y=UDim.new(0,y) } end,
	fromScale = function(x,y) return { X=UDim.new(x,0), Y=UDim.new(y,0) } end,
}
local Color3 = { new=function(...) return {...} end, fromRGB=function(...) return {...} end, fromHSV=function(...) return {...} end }
local ColorSequence = { new=function(...) return {...} end }
local TweenInfo = { new=function(...) return {...} end }
local pending = {}
local spawned={}
local task = { delay = function(_,fn) table.insert(pending,fn) end,spawn=function(fn) table.insert(spawned,fn) end }
local function flushSpawn() local jobs=spawned; spawned={}; for _,fn in ipairs(jobs) do fn() end end
local function flush() local calls=pending; pending={}; for _,fn in ipairs(calls) do fn() end end
local lookCalls, lastLook, lastAlpha = 0,nil,nil
local CFrame = {}
function CFrame.lookAt(position, point)
	local frame={Position=position,Point=point,LookVector=(point-position).Unit}
	function frame:Lerp(goal) return CFrame.lookAt(goal.Position,goal.Point) end
	return setmetatable(frame,{__add=function(a,offset) return CFrame.lookAt(a.Position+offset,a.Point+offset) end})
end
local cameraFrame = {Position=Vector3.new(),LookVector=Vector3.new(0,0,-1)}
function cameraFrame:Lerp(goal, alpha)
	self.LookVector=(goal.Point-goal.Position).Unit
	lookCalls+=1; lastLook=goal.Point; lastAlpha=alpha
	return self
end
local camera = { FieldOfView=70, ViewportSize=Vector2.new(1280,720), CFrame=cameraFrame }

function camera:WorldToViewportPoint(p) return Vector3.new(640+p.X*10,360-p.Y*10,20),true end
local instanceMethods = {}
local guiClasses = { Frame=true, CanvasGroup=true, TextLabel=true, TextButton=true, TextBox=true, ScrollingFrame=true, ImageLabel=true, ImageButton=true }
local function isA(node, class)
	return node.ClassName == class or class == "Instance" or (class == "GuiObject" and guiClasses[node.ClassName])
		or (class == "GuiButton" and (node.ClassName == "TextButton" or node.ClassName == "ImageButton"))
		or (class == "BasePart" and (node.ClassName == "Part" or node.ClassName == "MeshPart"))
end
local mt = {}
mt.__index = function(t, key)
	if instanceMethods[key] then return instanceMethods[key] end
	local props=rawget(t,"_props")
	if key == "AbsoluteSize" then
		if props.ClassName == "ScreenGui" or props.ClassName == "Workspace" or not props.Parent then return camera.ViewportSize end
		local parentSize = props.Parent.AbsoluteSize
		local size=props.Size or UDim2.fromOffset(100,40)
		local scale=1
		for _, child in ipairs(rawget(t,"_children")) do if child.ClassName == "UIScale" then scale=child.Scale end end
		return Vector2.new((parentSize.X*size.X.Scale+size.X.Offset)*scale,(parentSize.Y*size.Y.Scale+size.Y.Offset)*scale)
	end
	if key == "AbsolutePosition" then
		local pos=props.Position or UDim2.new()
		local ps=props.Parent and props.Parent.AbsoluteSize or camera.ViewportSize
		return Vector2.new(ps.X*pos.X.Scale+pos.X.Offset,ps.Y*pos.Y.Scale+pos.Y.Offset)
	end
	return props[key]
end
mt.__newindex = function(t, key, value)
	local props = rawget(t,"_props")
	if key == "Parent" then
		if props.Parent then
			local children=rawget(props.Parent,"_children")
			local index=table.find(children,t); if index then table.remove(children,index) end
		end
		if value then table.insert(rawget(value,"_children"),t) end
	end
	props[key]=value
	local event = rawget(t,"_changes")[key]; if event then event:Fire() end
end
local Instance = {}
function Instance.new(class)
	local obj=setmetatable({ _props={ClassName=class,Name=class,Visible=true,Enabled=true,Text="",Health=100,MaxHealth=100,AssemblyLinearVelocity=Vector3.new(),
		IgnoreGuiInset=false,DisplayOrder=0,GroupTransparency=0,AbsoluteRotation=0,CanCollide=true},
		_children={},_attributes={},_changes={},_destroyed=false },mt)
	for _,name in ipairs({"Destroying","MouseEnter","MouseLeave","Activated","MouseButton1Click","MouseButton1Down","MouseButton1Up","InputBegan","AnimationPlayed"}) do obj[name]=signal() end
	table.insert(allInstances,obj); return obj
end
function instanceMethods:IsA(class) return isA(self,class) end
function instanceMethods:GetChildren() return table.clone(rawget(self,"_children")) end
function instanceMethods:GetDescendants()
	local result={}
	local function visit(parent)
		for _,child in ipairs(parent:GetChildren()) do table.insert(result,child); visit(child) end
	end
	visit(self); return result
end
function instanceMethods:GetAttributes() return table.clone(rawget(self,"_attributes")) end
function instanceMethods:SetAttribute(key,value)
    local values=rawget(self,"_attributes");local old=values[key];values[key]=value
    local event=rawget(self,"_changes")["Attribute:"..key]
    if old~=value and event then event:Fire() end
end
function instanceMethods:GetAttributeChangedSignal(key) return self:GetPropertyChangedSignal("Attribute:"..key) end
function instanceMethods:GetAttribute(key) return rawget(self,"_attributes")[key] end
function instanceMethods:FindFirstChild(name)
	for _,child in ipairs(self:GetChildren()) do if child.Name==name then return child end end
end
function instanceMethods:FindFirstChildOfClass(class)
	for _,child in ipairs(self:GetChildren()) do if child:IsA(class) then return child end end
end
function instanceMethods:FindFirstAncestorWhichIsA(class)
	local parent=self.Parent
	while parent do if parent:IsA(class) then return parent end; parent=parent.Parent end
end
function instanceMethods:GetFullName() return self.Parent and self.Parent:GetFullName().."."..self.Name or self.Name end
function instanceMethods:GetPropertyChangedSignal(name)
	local changes=rawget(self,"_changes"); if not changes[name] then changes[name]=signal() end; return changes[name]
end
function instanceMethods:WaitForChild(name) return assert(self:FindFirstChild(name)) end
function instanceMethods:IsDescendantOf(parent)
	local ancestor=self.Parent
	while ancestor do if ancestor==parent then return true end; ancestor=ancestor.Parent end
	return false
end
local guiHits={}
function instanceMethods:GetGuiObjectsAtPosition() return guiHits[self] or {} end
function instanceMethods:ReleaseFocus() end
function instanceMethods:Move(direction) self.LastMove=direction end
function instanceMethods:MoveTo(position) self.LastMoveTo=position; self.Moves=(self.Moves or 0)+1 end
function instanceMethods:ChangeState(state) self.LastState=state end
function instanceMethods:Activate() self.Activations=(self.Activations or 0)+1 end
function instanceMethods:GetBoundingBox()
	return { PointToWorldSpace=function(_,p) return p end },Vector3.new(4,6,2)
end
local loadedTracks={}
function instanceMethods:LoadAnimation(animation)
	local track=Instance.new("AnimationTrack"); track.Animation=animation; track.Name=animation.Name
	track.Length=0.24; track.IsPlaying=false; track.Animator=self
	table.insert(loadedTracks,track); return track
end
function instanceMethods:Play() self.IsPlaying=true; if self.Animator then self.Animator.AnimationPlayed:Fire(self) end end
function instanceMethods:Stop() self.IsPlaying=false end
function instanceMethods:Destroy()
	if rawget(self,"_destroyed") then return end
	rawset(self,"_destroyed",true); self.Destroying:Fire()
	for _,child in ipairs(self:GetChildren()) do child:Destroy() end
	for _,v in pairs(rawget(self,"_props")) do if type(v)=="table" and v.handlers then for _,c in ipairs(v.handlers) do c:Disconnect() end end end
	for _,v in pairs(rawget(self,"_changes")) do for _,c in ipairs(v.handlers) do c:Disconnect() end end
	self.Parent=nil
end
local function node(class,name,parent,value)
	local obj=Instance.new(class); obj.Name=name; obj.Parent=parent
	if value~=nil then obj.Value=value end
	return obj
end
local workspace = node("Workspace","Workspace"); workspace.Gravity=196.2; workspace.CurrentCamera=camera
local wall=false
local forcedHit
local ground=true
function workspace:Raycast(origin,direction) if direction and direction.Y < -2 then return ground and {Instance=workspace} or nil end; return forcedHit and {Instance=forcedHit} or wall and {Instance=workspace} or nil end
local blockcasts=0
function workspace:Blockcast() blockcasts+=1; return wall and {Instance=workspace} or nil end
local replicated=node("Folder","ReplicatedStorage")
local players = node("Players","Players"); players.PlayerRemoving=signal()
local people={}
function players:GetPlayers() return table.clone(people) end
local function player(name,id)
	local p=node("Player",name,players); p.UserId=id; p.DisplayName=name.." Display"
	table.insert(people,p); return p
end
local localPlayer=player("Owner",1); players.LocalPlayer=localPlayer
local other=player("Other",2)
local function character(plr)
	local model=node("Model",plr.Name,workspace)
	local head=node("Part","Head",model); head.Position=Vector3.new(0,4,0)
	local root=node("Part","HumanoidRootPart",model); root.Position=Vector3.new()
	root.AssemblyLinearVelocity=Vector3.new(); root.Anchored=false
	root.Size=Vector3.new(2,2,1)
	root.CFrame=CFrame.lookAt(root.Position,root.Position+Vector3.new(0,0,-1))
	model.PrimaryPart=root
	local h=node("Humanoid","Humanoid",model); h.JumpPower=50; h.JumpHeight=7.2; h.UseJumpPower=true; h.MoveDirection=Vector3.new(); h.WalkSpeed=16; h.AutoRotate=true
	node("Animator","Animator",h); plr.Character=model
	return model
end
character(localPlayer); character(other)
node("PlayerGui","PlayerGui",localPlayer)
local coreGui=node("CoreGui","CoreGui")
local run={ Heartbeat=signal(), RenderStepped=signal(),PreSimulation=signal() }
local renderBindings={}
function run:BindToRenderStep(name, priority, fn) renderBindings[name]={priority=priority,fn=fn} end
function run:UnbindFromRenderStep(name) renderBindings[name]=nil end
local function renderAim(dt) for _,binding in pairs(renderBindings) do binding.fn(dt or 1/60) end end
local focusedBox
local input={ InputBegan=signal(),InputChanged=signal(),InputEnded=signal(),WindowFocusReleased=signal(),WindowFocused=signal(),JumpRequest=signal(),GetFocusedTextBox=function() return focusedBox end }
local tweens={ Create=function(_,item,_,props)
	return { Cancel=function() end, Play=function() for k,v in pairs(props) do item[k]=v end end }
end }
local sentKeys, sentMouse, sentTouches, rejectKeys = {},{},{},false
local vim={SendKeyEvent=function(_,down,key)
	if rejectKeys then error("virtual input unavailable") end
	table.insert(sentKeys,{down=down,key=key})
end,SendMouseButtonEvent=function(_,x,y,button,down) table.insert(sentMouse,{down=down,x=x,y=y}) end,
SendTouchEvent=function(_,id,state,x,y) table.insert(sentTouches,{id=id,state=state,x=x,y=y}) end}
local lighting=node("Lighting","Lighting")
lighting.Brightness=1; lighting.Ambient="Ambient"; lighting.OutdoorAmbient="Outdoor"; lighting.GlobalShadows=true; lighting.FogStart=15; lighting.FogEnd=400
local atmosphere=node("Atmosphere","Atmosphere",lighting); atmosphere.Density=0.4; atmosphere.Haze=2
local teleports,lastTeleport=0,nil
local teleportService={TeleportToPlaceInstance=function(_,place,job,plr) teleports+=1; lastTeleport=job end,Teleport=function() teleports+=1 end}
local pathSuccess=true
local pathPoints={}
local pathfinder={CreatePath=function()
	return {ComputeAsync=function(self,origin,goal) self.Origin=origin; self.Goal=goal; self.Status=pathSuccess and Enum.PathStatus.Success or Enum.PathStatus.NoPath end,GetWaypoints=function(self) if #pathPoints>0 then return pathPoints end; return {{Position=self.Origin},{Position=self.Goal}} end}
end}
local nativeActions={}
local services={ContextActionService={GetAllBoundActionInfo=function() return nativeActions end},GuiService={GetGuiInset=function() return Vector2.new(0,36) end},PathfindingService=pathfinder,TeleportService=teleportService,Lighting=lighting,Players=players,RunService=run,UserInputService=input,TweenService=tweens,CoreGui=coreGui,VirtualInputManager=vim,ReplicatedStorage=replicated}
local game={PlaceId=123456,JobId="current-server",GetService=function(_,name) return assert(services[name],name) end}
local env={}
local warnings={}
local warn=function(value) table.insert(warnings,value) end
local getgenv=function() return env end
local clipboard
local setclipboard=function(value) clipboard=value end
local firesignal=function(s,...) s:Fire(...) end
local getconnections=function(s)
	local connected={}; for _,c in ipairs(s.handlers) do if c.Connected then table.insert(connected,c) end end
	return connected
end
local queryParts={}
local destinationBlocked=false
workspace.DescendantAdded=signal()
function workspace:GetPartBoundsInRadius() return table.clone(queryParts) end
function workspace:GetPartBoundsInBox() return destinationBlocked and {{CanCollide=true,GetFullName=function() return "Workspace.TestWall" end}} or {} end
local originalRequire=require
local require=function(module)
    if type(module)=="table" and module.MockModule then return module.MockModule end
    return originalRequire(module)
end

instanceMethods.FindFirstAncestorOfClass=instanceMethods.FindFirstAncestorWhichIsA
function players:GetPlayerFromCharacter(c) for _,p in ipairs(people) do if p.Character==c then return p end end end
localPlayer.CharacterRemoving=signal();game.GameId=123
local function boot()
-- STANDALONE
end
local function findName(root,name)
 if root.Name==name then return root end
 for _,child in ipairs(root:GetChildren()) do local got=findName(child,name);if got then return got end end
end
local api=boot()
check(api.Game=='Universe Football' and api.Version=='1.1' and api.Gui.Parent,'standalone did not open')
check(not api.Config.PlayerESP and not api.Config.BallHighlight and not api.Config.SpeedEnabled and not api.Config.FollowBall,'features start enabled')
check(api.Status:find('No football',1,true),'missing football falsely reported')
check(findName(api.Gui,'Tab_football') and findName(api.Gui,'Tab_movement'),'football/movement pages missing')
local ball=node('Part','Football',workspace);ball.Position=Vector3.new(10,5,0);ball.AssemblyLinearVelocity=Vector3.new(30,0,0)
api.Rescan();api.Step(.2)
check(api.Ball==ball and api.Candidates==1 and api.Status:find('30 studs/s',1,true),'ball discovery/live speed missing')
findName(api.Gui,'BallHighlight').Activated:Fire();api.Step(.2)
check(ball:FindFirstChild('RiftFootballHighlight'),'football toggle did not create highlight')
api.SetOption('BallName',true);api.Step(.2);check(findName(api.Gui,'RiftFootballLabel'),'ball label missing')
local h=localPlayer.Character:FindFirstChildOfClass('Humanoid')
api.SetOption('WalkSpeed',40);api.SetOption('SpeedEnabled',true);api.Step(.2);check(h.WalkSpeed==40,'speed setting failed')
h.WalkSpeed=19;api.Step(.2);api.Step(.2);check(h.WalkSpeed==19,'speed fought game override')
api.SetOption('WalkSpeed',45);api.Step(.2);check(h.WalkSpeed==45,'new speed request ignored')
api.SetOption('SpeedEnabled',false);check(h.WalkSpeed==19,'speed toggle did not restore')
check(not api.SetOption('WalkSpeed',0/0),'NaN option accepted')
api.SetOption('WalkSpeed',500);check(api.Config.WalkSpeed==60,'speed clamp missing')
local originalFov=camera.FieldOfView or 70;camera.FieldOfView=originalFov
api.SetOption('FieldOfView',90);api.SetOption('CustomFOV',true);api.Step(.2);check(camera.FieldOfView==90,'FOV not applied')
camera.FieldOfView=75;api.Step(.2);api.Step(.2);check(camera.FieldOfView==75,'camera FOV override lost')
api.SetOption('CustomFOV',false);api.SetOption('CustomFOV',true);api.Step(.2);check(camera.FieldOfView==90,'FOV toggle retry ignored')
api.SetOption('CustomFOV',false);check(camera.FieldOfView==75,'FOV snapshot not restored')
camera.CameraSubject=h;api.SetOption('FollowBall',true);api.Step(.2);check(camera.CameraSubject==ball,'ball camera did not follow')
api.SetOption('FollowBall',false);check(camera.CameraSubject==h,'camera subject not restored')
api.SetOption('FollowBall',true);api.Step(.2)
local external=node('Part','GameCameraTarget',workspace);camera.CameraSubject=external;api.Step(.2);api.Step(.2)
check(camera.CameraSubject==external,'external camera override overwritten')
api.SetOption('FollowBall',false);camera.CameraSubject=h
local ownTeam=node('Team','OwnTeam');local enemyTeam=node('Team','EnemyTeam')
localPlayer.Team=ownTeam;localPlayer.Neutral=false;localPlayer.TeamColor={Color='blue'}
other.Team=enemyTeam;other.Neutral=false;other.TeamColor={Color='red'}
api.SetOption('PlayerESP',true);api.SetOption('PlayerNames',true);api.Step(.2)
local hl=other.Character:FindFirstChild('RiftUFPlayer');check(hl and hl.FillColor=='red','player highlight did not use team color')
local tag=findName(api.Gui,'RiftUFUsername');check(tag and tag.Enabled,'username missing')
other.Team=ownTeam;api.SetOption('ShowTeammates',false);api.Step(.2);check(not other.Character:FindFirstChild('RiftUFPlayer'),'teammate filter ignored')
api.SetOption('ShowTeammates',true);api.Step(.2);check(other.Character:FindFirstChild('RiftUFPlayer'),'teammate filter did not recover')
ball.Parent=localPlayer.Character;api.Step(.2);check(api.Status:find('@Owner',1,true),'carrier not identified from character')
local nearer=node('Part','MatchBall',workspace);nearer.Position=Vector3.new(1,0,0);workspace.DescendantAdded:Fire(nearer);api.Step(.2)
check(api.Ball==nearer and api.Candidates==2,'new/multiple balls not tracked')
nearer:Destroy();ball:Destroy();api.Step(.2);check(not api.Ball and api.Candidates==0,'removed football remained selected')
local generic=node('Part','Ball',workspace);generic.Position=Vector3.new();api.Rescan();api.Step(.2);check(not api.Ball,'unidentified generic Ball was guessed as football')
generic:SetAttribute('IsFootball',true);api.Rescan();api.Step(.2);check(api.Ball==generic,'explicit IsFootball field ignored')
api.SetOption('SpeedEnabled',true);api.Step(.2);input.WindowFocusReleased:Fire();api.Step(.2);check(h.WalkSpeed==19,'focus loss did not restore speed')
input.WindowFocused:Fire();api.Step(.2)
local report,copied=api.CopyDiagnostics();check(copied and clipboard==report and report:find('Universe Football',1,true),'diagnostics copy failed')
api.Reset();check(not api.Config.SpeedEnabled and not api.Config.PlayerESP and h.WalkSpeed==19,'reset did not restore/disable features')

-- QB assist: held input, team/angle/visibility gates and bounded camera response.
check(not api.Config.QBAim and not api.Config.AutoCatch,'assists must start off')
local mateRoot=other.Character.PrimaryPart;mateRoot.Position=Vector3.new(0,0,-35);mateRoot.AssemblyLinearVelocity=Vector3.new(5,0,0)
other.Team=ownTeam;other.Neutral=false;camera.CFrame=cameraFrame;cameraFrame.LookVector=Vector3.new(0,0,-1)
local touch={UserInputType=Enum.UserInputType.Touch}
findName(api.Gui,'HoldQB').InputBegan:Fire(touch);api.Assists.Step(.05)
check(not api.Assists.Held and not api.Assists.Target,'disabled QB assist reacted')
api.SetOption('QBAim',true);findName(api.Gui,'HoldQB').InputBegan:Fire(touch)
api.Assists.Step(.05)
check(api.Assists.Target==other and lookCalls>0 and lastAlpha<.25,'held teammate assist did not apply gentle camera response')
check(lastLook.X>mateRoot.Position.X,'receiver velocity lead missing')
local unrelated={UserInputType=Enum.UserInputType.Touch};input.InputEnded:Fire(unrelated)
check(api.Assists.Held,'another touch released QB assist')
input.InputEnded:Fire(touch);check(not api.Assists.Held and not api.Assists.Target,'held aim failed to release')
api.HoldQB(true,touch);other.Team=enemyTeam;api.Assists.Step(.05);check(not api.Assists.Target,'QB assist targeted opponent')
other.Team=ownTeam;mateRoot.Position=Vector3.new(25,0,-10);api.Assists.Step(.05);check(not api.Assists.Target,'QB assist snapped outside cone')
mateRoot.Position=Vector3.new(0,0,-35);wall=true;api.Assists.Step(.05);check(not api.Assists.Target,'QB assist ignored wall');wall=false
api.Assists.Step(.05);check(api.Assists.Target==other,'visible teammate did not recover')
api.SetOption('FollowBall',true);check(not api.Assists.Held,'ball follow and held aiming conflicted');api.SetOption('FollowBall',false)
-- Native catch: one eligible event, cooldowns, incoming direction, walls and game gates.
local hud=node('ScreenGui','MobileFootballHUD',localPlayer:FindFirstChild('PlayerGui'))
local catch=node('TextButton','CatchButton',hud);local caught=0
catch.Activated:Connect(function() caught+=1 end)
generic.Position=Vector3.new(0,0,-4);generic.AssemblyLinearVelocity=Vector3.new(0,0,15)
localPlayer.Character.PrimaryPart.AssemblyLinearVelocity=Vector3.new()
api.SetOption('AutoCatch',true);api.SetOption('IncomingAlert',true);api.SetOption('CatchDistance',5)
api.Assists.Scan();api.Assists.Step(.05)
check(caught==1 and api.Assists.CatchRequests==1,'incoming ball did not request actual catch signal')
check(api.Assists.Alert=='INCOMING FOOTBALL','incoming alert missing')
api.Assists.Step(.05);check(caught==1,'catch request cooldown ignored')
for i=1,9 do api.Assists.Step(.05) end
check(caught==2,'catch cooldown did not recover')
catch:SetAttribute('OnCooldown',true);for i=1,12 do api.Assists.Step(.05) end;check(caught==2,'native catch cooldown bypassed')
catch:SetAttribute('OnCooldown',false);localPlayer.Character:SetAttribute('canCatch',false)
for i=1,12 do api.Assists.Step(.05) end;check(caught==2,'game canCatch lock ignored')
localPlayer.Character:SetAttribute('canCatch',nil);generic.AssemblyLinearVelocity=Vector3.new(0,0,-15)
for i=1,12 do api.Assists.Step(.05) end;check(caught==2,'outgoing ball triggered catch')
generic.AssemblyLinearVelocity=Vector3.new(0,0,15);generic.Position=Vector3.new(0,0,-30)
for i=1,12 do api.Assists.Step(.05) end;check(caught==2,'out-of-range ball triggered catch')
generic.Position=Vector3.new(0,0,-4);wall=true
for i=1,12 do api.Assists.Step(.05) end;check(caught==2,'catch requested through wall');wall=false
local tool=node('Tool','Football',other.Character);generic.Parent=tool
for i=1,12 do api.Assists.Step(.05) end;check(caught==2,'held ball triggered auto catch')
generic.Parent=workspace;catch.Visible=false
for i=1,12 do api.Assists.Step(.05) end;check(caught==2,'hidden catch button used')
catch.Visible=true;api.Assists.Scan();local originalSignal=firesignal;firesignal=nil
api.Assists.Step(.05);check(api.Assists.CatchStatus:find('No supported',1,true),'missing executor support was hidden');firesignal=originalSignal
api.SetOption('CatchDistance',100);check(api.Config.CatchDistance==6,'catch request distance exceeded bound')
api.SetOption('AutoCatch',false);hud:Destroy()
local old=api;api=boot();flushSpawn();flush();check(not old.Alive and old.Gui==nil,'reexecution left old UI running')
api.Unload();api.Unload();flushSpawn();flush();check(not env.RiftUniverseFootball and not api.Gui,'unload left global/window')
local leaks=0
for _,sig in ipairs(allSignals) do for _,c in ipairs(sig.handlers) do if c.Connected then leaks+=1 end end end
check(leaks==0,'unload leaked '..leaks..' listeners')
print('PASS: '..checks..' football discovery, team visuals, owned settings, camera, UI, reset and lifecycle checks.')
