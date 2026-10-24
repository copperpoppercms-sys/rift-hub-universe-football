-- RiftHub-Entry: universe-football
-- Rift Hub / Universe Football / 1.3
local env=type(getgenv)=="function" and getgenv() or _G
local prior=env.RiftUniverseFootball
if type(prior)=="table" and type(prior.Unload)=="function" then pcall(prior.Unload) end
local Kit={}
function Kit.create(class,props,parent)
 local obj=Instance.new(class)
 for k,v in pairs(props) do obj[k]=v end
 if parent then obj.Parent=parent end
 return obj
end
local Brand=(function()
-- Exact user-supplied Rift logo. Normalized clipping stays centered after texture resizing.
-- One asynchronous download per script; failed image loading leaves the text fallback usable.
return function(url)
	local M={}
	local asset,started=nil,false
	local targets=setmetatable({},{__mode="k"})
	local function paint(image,fallback)
		if not image.Parent or not image.Parent.Parent or not asset then return end
		image.Image=asset; image.Visible=true
		if fallback and fallback.Parent then fallback.Text="" end
	end
	function M.Apply(image,fallback)
		local viewport=Instance.new("Frame")
		viewport.Name="RiftLogoViewport"; viewport.BackgroundTransparency=1; viewport.BorderSizePixel=0; viewport.ClipsDescendants=true
		viewport.Position=image.Position; viewport.Size=image.Size; viewport.AnchorPoint=image.AnchorPoint
		viewport.LayoutOrder=image.LayoutOrder; viewport.ZIndex=image.ZIndex; viewport.Parent=image.Parent
		image.Parent=viewport; image.AnchorPoint=Vector2.new()
		image.Position=UDim2.fromScale(-374/520,-298/520); image.Size=UDim2.fromScale(1254/520,1254/520)
		image.Name="RiftLogo"; image.ImageRectOffset=Vector2.new(); image.ImageRectSize=Vector2.new()
		image.ImageColor3=Color3.new(1,1,1); image.ScaleType=Enum.ScaleType.Stretch; image.Visible=false
		targets[image]=fallback or false
		if asset then paint(image,fallback); return end
		if started then return end; started=true
		task.spawn(function()
			local ok,result=pcall(function()
				local customAsset=type(getcustomasset)=="function" and getcustomasset or type(getsynasset)=="function" and getsynasset
				assert(customAsset and type(writefile)=="function" and type(isfile)=="function","Custom images unavailable")
				local path="RiftHub/rift-logo-92145dc6000c.jpg"
				if type(isfolder)=="function" and type(makefolder)=="function" and not isfolder("RiftHub") then makefolder("RiftHub") end
				if not isfile(path) then
					local bytes=game:HttpGet(url)
					assert(type(bytes)=="string" and bytes:sub(1,3)==string.char(255,216,255),"Invalid Rift logo")
					writefile(path,bytes)
				end
				local content=customAsset(path)
				assert(type(content)=="string" and content~="","Image registration failed")
				return content
			end)
			if not ok then return end
			asset=result
			for image,fallback in pairs(targets) do paint(image,fallback) end
			table.clear(targets)
		end)
	end
	return M
end

end)()
local Interface=(function()
-- Native animated interface; no downloaded UI library or flashing effects.
return function(ctx)
    local API,cfg,gui=ctx.API,ctx.Config,ctx.Gui
    local Input=game:GetService("UserInputService")
    local Tween=game:GetService("TweenService")
    local C={Base=Color3.fromRGB(16,18,25),Panel=Color3.fromRGB(24,27,37),Raised=Color3.fromRGB(33,37,50),
        Line=Color3.fromRGB(55,61,80),Accent=Color3.fromRGB(178,161,255),Text=Color3.fromRGB(239,240,249),Sub=Color3.fromRGB(151,159,181)}
    local M={};local connections={};local dead=false
    function M.Destroy()
        if dead then return end;dead=true
        for _,c in ipairs(connections) do c:Disconnect() end;table.clear(connections)
    end
    if ctx.RegisterCleanup then ctx.RegisterCleanup(function() M.Destroy() end) end
    local orders=setmetatable({},{__mode="k"})
    local function connect(event,fn) local c=event:Connect(fn);table.insert(connections,c);return c end
    local function make(class,props,parent)
        local node=Instance.new(class);for key,value in pairs(props) do node[key]=value end
        if parent and node:IsA("GuiObject") and props.LayoutOrder==nil then orders[parent]=(orders[parent] or 0)+1;node.LayoutOrder=orders[parent] end
        node.Parent=parent;return node
    end
    local function round(node,r) make("UICorner",{CornerRadius=UDim.new(0,r or 10)},node) end
    local function animate(node,props,t)
        if cfg.ReduceMotion then for key,value in pairs(props) do node[key]=value end;return end
        Tween:Create(node,TweenInfo.new(t or 0.17,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),props):Play()
    end
    local function text(parent,value,size,color,position,dimensions,bold)
        return make("TextLabel",{Text=value,TextSize=size,TextColor3=color or C.Text,Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham,
            Position=position or UDim2.new(),Size=dimensions or UDim2.new(1,0,0,20),BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left},parent)
    end
    local function hover(button)
        local scale=make("UIScale",{Scale=1},button)
        connect(button.MouseEnter,function() animate(scale,{Scale=1.025},0.14) end)
        connect(button.MouseLeave,function() animate(scale,{Scale=1},0.16) end)
        connect(button.InputBegan,function(input)
            if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
                animate(scale,{Scale=0.975},0.08);task.delay(0.1,function() if not dead and button.Parent then animate(scale,{Scale=1},0.16) end end)
            end
        end)
    end
    local window=make("Frame",{Name="Panel",AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(680,470),BackgroundTransparency=1},gui)
    local fit=make("UIScale",{Scale=1},window)
    local surface=make("CanvasGroup",{Size=UDim2.fromScale(1,1),BackgroundColor3=C.Base,BorderSizePixel=0,GroupTransparency=1},window);round(surface,15)
    make("UIStroke",{Color=C.Line,Thickness=1},surface)
    make("UIGradient",{Rotation=75,Color=ColorSequence.new(C.Base,Color3.fromRGB(23,24,40))},surface)
    local opening=make("UIScale",{Scale=0.96},surface)
    local top=make("Frame",{Name="Handle",Active=true,Size=UDim2.new(1,0,0,64),BackgroundTransparency=1},surface)
    local logoFallback=text(top,"R",25,C.Text,UDim2.fromOffset(18,17),UDim2.fromOffset(30,30),true)
    local logo=make("ImageLabel",{Position=UDim2.fromOffset(18,17),Size=UDim2.fromOffset(30,30),BackgroundTransparency=1},top);ctx.Brand.Apply(logo,logoFallback)
    text(top,"RIFT HUB",15,C.Text,UDim2.fromOffset(61,12),UDim2.new(1,-155,0,23),true)
    text(top,"UNIVERSE FOOTBALL",9,C.Accent,UDim2.fromOffset(62,36),UDim2.new(1,-150,0,16),true)
    local seam=make("Frame",{Position=UDim2.new(0,16,0,63),Size=UDim2.new(1,-32,0,1),BackgroundColor3=C.Accent,BackgroundTransparency=0.45,BorderSizePixel=0},surface)
    make("UIGradient",{Color=ColorSequence.new(C.Accent,C.Line)},seam)
    local function headerButton(name,glyph,x)
        local b=make("TextButton",{Name=name,Position=UDim2.new(1,x,0,18),Size=UDim2.fromOffset(28,28),Text=glyph,TextSize=20,
            Font=Enum.Font.Gotham,TextColor3=C.Sub,BackgroundColor3=C.Panel,BorderSizePixel=0,AutoButtonColor=false},top);round(b,8);hover(b);return b
    end
    local close=headerButton("Close","×",-43);local minimize=headerButton("Minimize","−",-78)
    local side=make("Frame",{Name="Sidebar",Position=UDim2.fromOffset(0,64),Size=UDim2.new(0,136,1,-64),BackgroundColor3=C.Panel,BorderSizePixel=0},surface)
    local content=make("Frame",{Position=UDim2.fromOffset(136,64),Size=UDim2.new(1,-136,1,-91),BackgroundTransparency=1,ClipsDescendants=true},surface)
    local footer=text(surface,"N0VA_0100  /  RIFT UF 1.3",9,C.Sub,UDim2.new(0,151,1,-23),UDim2.new(1,-166,0,18))
    local marker=make("Frame",{Position=UDim2.fromOffset(0,24),Size=UDim2.fromOffset(3,22),BackgroundColor3=C.Accent,BorderSizePixel=0},side);round(marker,2)
    local pages,tabs,selected={},{},"football"
    local function select(id)
        selected=id
        local index=({football=1,movement=2,visuals=3,settings=4})[id] or 1
        animate(marker,{Position=UDim2.fromOffset(0,24+(index-1)*45)},0.22)
        for key,page in pairs(pages) do
            page.Visible=key==id
            if key==id then page.GroupTransparency=cfg.ReduceMotion and 0 or 1;animate(page,{GroupTransparency=0},0.22) end
        end
        for key,b in pairs(tabs) do animate(b,{BackgroundTransparency=key==id and 0 or 1,TextColor3=key==id and C.Accent or C.Sub}) end
    end
    for i,entry in ipairs({{"football","Football"},{"movement","Movement"},{"visuals","Visuals"},{"settings","Settings"}}) do
        local id,title=entry[1],entry[2]
        local tab=make("TextButton",{Name="Tab_"..id,Position=UDim2.fromOffset(10,17+(i-1)*45),Size=UDim2.new(1,-20,0,36),Text="  "..title,
            Font=Enum.Font.GothamBold,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,BackgroundColor3=C.Raised,TextColor3=C.Sub,BorderSizePixel=0,AutoButtonColor=false},side);round(tab,8);hover(tab);tabs[id]=tab
        connect(tab.Activated,function() select(id) end)
        local page=make("CanvasGroup",{Name="Page_"..id,Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Visible=false},content)
        local scroll=make("ScrollingFrame",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,
            ScrollBarImageColor3=C.Line,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y},page)
        make("UIPadding",{PaddingLeft=UDim.new(0,16),PaddingRight=UDim.new(0,16),PaddingTop=UDim.new(0,16),PaddingBottom=UDim.new(0,16)},scroll)
        make("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,12)},scroll)
        text(scroll,title,23,C.Text,nil,UDim2.new(1,0,0,34),true);pages[id]=page;page:SetAttribute("TabId",id)
        M[id]=scroll
    end
    local function section(parent,title,description)
        local box=make("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundColor3=C.Panel,BorderSizePixel=0},parent);round(box,11)
        make("UIStroke",{Color=C.Line,Transparency=0.4},box)
        make("UIPadding",{PaddingLeft=UDim.new(0,14),PaddingRight=UDim.new(0,14),PaddingTop=UDim.new(0,12),PaddingBottom=UDim.new(0,12)},box)
        make("UIListLayout",{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder},box)
        text(box,title,13,C.Text,nil,UDim2.new(1,0,0,22),true)
        if description then local note=text(box,description,11,C.Sub,nil,UDim2.new(1,0,0,0));note.TextWrapped=true;note.AutomaticSize=Enum.AutomaticSize.Y end
        return box
    end
    local paints={};local sliderDrag
    local function toggle(parent,key,title)
        local b=make("TextButton",{Name=key,Size=UDim2.new(1,0,0,40),BackgroundTransparency=1,Text="",AutoButtonColor=false,BorderSizePixel=0},parent);hover(b)
        local caption=text(b,title,12,C.Text,UDim2.fromOffset(0,7),UDim2.new(1,-52,0,28),true);caption.TextWrapped=true
        local track=make("Frame",{AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,0,0.5,0),Size=UDim2.fromOffset(36,20),BackgroundColor3=C.Line,BorderSizePixel=0},b);round(track,12)
        local knob=make("Frame",{Size=UDim2.fromOffset(14,14),Position=UDim2.fromOffset(3,3),BackgroundColor3=C.Sub,BorderSizePixel=0},track);round(knob,8)
        local previous
        local function paint()
            if previous==cfg[key] then return end;previous=cfg[key]
            animate(track,{BackgroundColor3=previous and C.Accent or C.Line})
            animate(knob,{Position=UDim2.fromOffset(previous and 19 or 3,3),BackgroundColor3=previous and C.Base or C.Sub})
        end
        table.insert(paints,paint);paint();connect(b.Activated,function() API.SetOption(key,not cfg[key]) end)
        return b
    end
    local function slider(parent,key,title,minimum,maximum,percent)
        local row=make("Frame",{Name=key,Size=UDim2.new(1,0,0,51),BackgroundTransparency=1},parent)
        text(row,title,12,C.Text,nil,UDim2.new(1,-50,0,20),true)
        local value=text(row,"",11,C.Accent,UDim2.new(1,-50,0,0),UDim2.fromOffset(50,20),true);value.TextXAlignment=Enum.TextXAlignment.Right
        local hit=make("TextButton",{Position=UDim2.fromOffset(0,22),Size=UDim2.new(1,0,0,26),Text="",BackgroundTransparency=1,AutoButtonColor=false},row)
        local track=make("Frame",{Position=UDim2.fromOffset(0,10),Size=UDim2.new(1,0,0,4),BackgroundColor3=C.Line,BorderSizePixel=0},hit);round(track,3)
        local fill=make("Frame",{Size=UDim2.fromScale(0,1),BackgroundColor3=C.Accent,BorderSizePixel=0},track);round(fill,3)
        local knob=make("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Size=UDim2.fromOffset(11,11),BackgroundColor3=C.Text,BorderSizePixel=0},track);round(knob,7)
        local function paint()
            local a=(cfg[key]-minimum)/(maximum-minimum);fill.Size=UDim2.fromScale(a,1);knob.Position=UDim2.fromScale(a,0.5)
            value.Text=percent and tostring(math.floor(cfg[key]*100)).."%" or maximum<1 and string.format("%.2fs",cfg[key]) or tostring(math.floor(cfg[key]))
        end
        local function update(x)
            if track.AbsoluteSize.X<=0 then return end
            local a=math.clamp((x-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1);local v=minimum+(maximum-minimum)*a
            API.SetOption(key,(percent or maximum<1) and v or math.floor(v+0.5))
        end
        table.insert(paints,paint);paint()
        connect(hit.InputBegan,function(input)
            if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then sliderDrag={Input=input,Update=update};update(input.Position.X) end
        end)
        return row
    end
    local function button(parent,name,title,fn)
        local b=make("TextButton",{Name=name,Text=title,Size=UDim2.new(1,0,0,37),Font=Enum.Font.GothamBold,TextSize=12,
            TextColor3=C.Text,BackgroundColor3=C.Raised,AutoButtonColor=false,BorderSizePixel=0},parent);round(b,8);hover(b);connect(b.Activated,fn);return b
    end
    local qb=section(M.football,"QB ASSIST","Gentle camera lead toward a confirmed teammate near your aim. Hold the button or right mouse; throwing stays manual. Does not calculate the game's throw power or guarantee completions.")
    toggle(qb,"QBAim","Enable QB aim assistance")
    local hold=button(qb,"HoldQB","HOLD QB ASSIST",function() end)
    connect(hold.InputBegan,function(input)
        if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then API.HoldQB(true,input) end
    end)
    slider(qb,"AimCone","Aim cone (degrees)",3,12)
    slider(qb,"AimStrength","Aim response",2,8)
    slider(qb,"LeadTime","Receiver lead (seconds)",0,.4)
    slider(qb,"AimRange","Receiver range",25,220)
    toggle(qb,"ReceiverMarker","Show selected receiver")
    local qbStatus=text(qb,"Off",10,C.Sub,nil,UDim2.new(1,0,0,32));qbStatus.TextWrapped=true
    local catching=section(M.football,"CATCH ASSIST","Requests the visible native catch button for a nearby incoming football. Requires a detected catch button and executor signal support; no hitbox or remote changes.")
    toggle(catching,"AutoCatch","Auto catch input")
    toggle(catching,"TouchCatch","Hand-contact fallback (executor support required)")
    toggle(catching,"AutoJump","Auto jump for nearby overhead passes")
    slider(catching,"CatchDistance","Request distance (studs)",2,6)
    toggle(catching,"IncomingAlert","Incoming football alert")
    local catchStatus=text(catching,"Off",10,C.Sub,nil,UDim2.new(1,0,0,38));catchStatus.TextWrapped=true
    local ball=section(M.football,"LIVE FOOTBALL","Automatically scans the live world in batches, skips menu/locker-room scenery and watches for new footballs.")
    toggle(ball,"BallHighlight","Highlight football")
    toggle(ball,"BallName","Football label")
    local ballStatus=text(ball,"Looking for football",11,C.Sub,nil,UDim2.new(1,0,0,42));ballStatus.TextWrapped=true
    button(ball,"RescanBall","Rescan football",API.Rescan)
    local camera=section(M.football,"CAMERA","Follow the detected football, or keep your normal camera. Scripted game cameras take priority.")
    toggle(camera,"FollowBall","Follow football camera")
    slider(camera,"FieldOfView","Field of view",50,110)
    toggle(camera,"CustomFOV","Enable custom field of view")
    local movement=section(M.movement,"MOVEMENT","Requests your selected WalkSpeed once. The game can replace it; Rift preserves that change. Turn off to restore the original value.")
    toggle(movement,"SpeedEnabled","Custom walking speed")
    slider(movement,"WalkSpeed","WalkSpeed",16,60)
    local jumps=section(M.movement,"JUMPING","Uses the active Humanoid jump mode. Original values restore on disable. Games can replace jump settings.")
    toggle(jumps,"JumpBoost","Custom jump setting")
    slider(jumps,"JumpPower","Jump power",35,85)
    slider(jumps,"JumpHeight","Jump height",4,16)
    toggle(jumps,"InfiniteJump","Repeat jump on jump input")
    local collision=section(M.movement,"COLLISION","Noclip changes your character's local collisions while enabled. Turn off or unload to restore them; the server may restrict movement.")
    toggle(collision,"Noclip","Noclip")
    local esp=section(M.visuals,"PLAYERS","Team-colored highlights and usernames. Player visuals start off; teammates can be filtered independently.")
    toggle(esp,"PlayerESP","Player highlights")
    toggle(esp,"PlayerNames","Player usernames")
    toggle(esp,"ShowTeammates","Include teammates")
    slider(esp,"FillTransparency","Highlight transparency",0,1,true)
    local settings=section(M.settings,"INTERFACE","Drag the header to move. Minimize to the Rift emblem; tap it to reopen. RightShift also toggles the window.")
    toggle(settings,"ReduceMotion","Reduce motion")
    button(settings,"ResetFeatures","Reset all features",API.Reset)
    local tools=section(M.settings,"SESSION")
    button(tools,"CopyReport","Copy diagnostics",function() local _,copied=API.CopyDiagnostics();footer.Text=copied and "Diagnostics copied" or "Diagnostics printed in console" end)
    button(tools,"Rejoin","Rejoin server",function()
        local p=game:GetService("Players").LocalPlayer;local t=game:GetService("TeleportService")
        if game.JobId~="" then t:TeleportToPlaceInstance(game.PlaceId,game.JobId,p) else t:Teleport(game.PlaceId,p) end
    end)
    button(tools,"Unload","Unload Rift Hub",API.Unload)
    text(M.settings,"Rift Hub · N0VA_0100",11,C.Sub,nil,UDim2.new(1,0,0,24))
    local bubble=make("TextButton",{Name="Restore",Text="R",AnchorPoint=Vector2.new(),Position=UDim2.fromOffset(18,150),Size=UDim2.fromOffset(48,48),TextSize=24,
        Font=Enum.Font.GothamBold,TextColor3=C.Text,BackgroundColor3=C.Base,BorderSizePixel=0,AutoButtonColor=false,Visible=false},gui);round(bubble,13);hover(bubble)
    make("UIStroke",{Color=C.Accent,Transparency=0.3},bubble)
    local miniLogo=make("ImageLabel",{Position=UDim2.fromOffset(8,8),Size=UDim2.fromOffset(32,32),BackgroundTransparency=1},bubble);ctx.Brand.Apply(miniLogo,bubble)
    local minimized=false
    local function minimizeTo(on) minimized=on;window.Visible=not on;bubble.Visible=on end
    connect(minimize.Activated,function() minimizeTo(true) end)
    connect(close.Activated,API.Unload)
    local drag,lastDragAt=nil,-10
    local function draggable(handle,target)
        connect(handle.InputBegan,function(input)
            if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
                drag={Input=input,Start=input.Position,Origin=target.Position,Target=target,Moved=false};ctx.Drag(true)
            end
        end)
    end
    draggable(top,window);draggable(bubble,bubble)
    connect(bubble.Activated,function() if os.clock()-lastDragAt>0.2 then minimizeTo(false) end end)
    connect(Input.InputChanged,function(input)
        local function matches(press) return input==press or input.UserInputType==Enum.UserInputType.MouseMovement and press.UserInputType==Enum.UserInputType.MouseButton1 end
        if sliderDrag and matches(sliderDrag.Input) then sliderDrag.Update(input.Position.X) end
        if drag and matches(drag.Input) then
            local delta=input.Position-drag.Start;if delta.Magnitude>7 then drag.Moved=true end
            local view=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize
            if view then
                local size=drag.Target==window and Vector2.new(window.Size.X.Offset*fit.Scale,window.Size.Y.Offset*fit.Scale) or Vector2.new(48,48)
                local anchor=drag.Target.AnchorPoint;local x=drag.Origin.X.Scale*view.X+drag.Origin.X.Offset+delta.X;local y=drag.Origin.Y.Scale*view.Y+drag.Origin.Y.Offset+delta.Y
                drag.Target.Position=UDim2.fromOffset(math.clamp(x,8+size.X*anchor.X,math.max(8+size.X*anchor.X,view.X-8-size.X*(1-anchor.X))),math.clamp(y,8+size.Y*anchor.Y,math.max(8+size.Y*anchor.Y,view.Y-8-size.Y*(1-anchor.Y))))
            end
        end
    end)
    connect(Input.InputEnded,function(input)
        if sliderDrag and input==sliderDrag.Input then sliderDrag=nil end
        if drag and input==drag.Input then if drag.Moved then lastDragAt=os.clock() end;drag=nil;ctx.Drag(false) end
    end)
    connect(Input.WindowFocusReleased,function() sliderDrag=nil;drag=nil;ctx.Drag(false);ctx.Focus(false) end)
    connect(Input.WindowFocused,function() ctx.Focus(true) end)
    connect(Input.InputBegan,function(input,processed) if not processed and not Input:GetFocusedTextBox() and input.KeyCode==Enum.KeyCode.RightShift then minimizeTo(not minimized) end end)
    local lastView
    function M.Step()
        if dead then return end
        local view=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize
        if view and view~=lastView then
            lastView=view;local w,h=math.clamp(view.X-20,320,680),math.clamp(view.Y-32,280,470)
            window.Size=UDim2.fromOffset(w,h);fit.Scale=math.max(0.1,math.min(1,(view.X-20)/w,(view.Y-32)/h))
            local sideWidth=w<500 and 100 or 136
            side.Size=UDim2.new(0,sideWidth,1,-64);content.Position=UDim2.fromOffset(sideWidth,64);content.Size=UDim2.new(1,-sideWidth,1,-91)
            footer.Position=UDim2.new(0,sideWidth+15,1,-23);footer.Size=UDim2.new(1,-sideWidth-30,0,18);window.Position=UDim2.fromScale(0.5,0.5)
        end
        for _,paint in ipairs(paints) do paint() end
        ballStatus.Text=API.Status
        if API.Assists then
            qbStatus.Text=API.Assists.AimStatus
            catchStatus.Text=API.Assists.CatchStatus..(API.Assists.Alert~="" and " · "..API.Assists.Alert or "")
        end

    end
    function M.Destroy()
        if dead then return end;dead=true;sliderDrag=nil;drag=nil
        for _,c in ipairs(connections) do c:Disconnect() end;table.clear(connections)
    end
    M.SelectTab=select;M.Window=window;M.Step();select("football")
    animate(surface,{GroupTransparency=0},0.25);animate(opening,{Scale=1},0.28)
    return M
end

end)()
local Assists=(function()
-- Opt-in camera lead and bounded native catch input. Never modifies a throw packet or catch hitbox.
return function(ctx)
 local Players=game:GetService("Players")
 local Input=game:GetService("UserInputService")
 local player=Players.LocalPlayer
 local cfg=ctx.Config
 local M={Held=false,Target=nil,AimStatus="Off",CatchStatus="Off",CatchRequests=0,JumpRequests=0,CatchMethod="None",Alert="",LastError=nil}
 local dead=false
 local press,age,scanAt,nextCatch,nextJump= nil,0,0,0,0
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
       if activeHandlers(event)>0 then catchButton,catchSignal=node,event;return end
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
  local ownTeam=teamKey(player)
  for _,plr in ipairs(Players:GetPlayers()) do
   if plr~=player and ownTeam~=nil and teamKey(plr)==ownTeam then
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
  local char,hum,root=eligible()
  if not char then M.Hold(false);M.CatchStatus="Paused for character/input";M.Alert="";return end
  local ball=ctx.Ball()
  M.Alert=cfg.IncomingAlert and incoming(ball,root,45) and "INCOMING FOOTBALL" or ""
  if cfg.AutoJump and age>=nextJump and hum.FloorMaterial~=Enum.Material.Air and incoming(ball,root,12)
   and ball.Position.Y-root.Position.Y>3 and char:GetAttribute("canRun")~=false then
   hum.Jump=true;M.JumpRequests+=1;nextJump=age+.8
  end
  local cam=workspace.CurrentCamera
  if cfg.QBAim and M.Held and cam and cam.CameraType~=Enum.CameraType.Scriptable and not cfg.FollowBall then aim(cam,char,root,dt)
  else M.Target=nil;clearMarker();M.AimStatus=cfg.QBAim and "Hold QB ASSIST or right mouse · aim near teammate" or "Off" end
  if not cfg.AutoCatch then M.CatchStatus="Off";return end
  if age>=scanAt then M.Scan();scanAt=age+1 end
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
  nextCatch=age+.4
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
 function M.Diagnostics()
  return table.concat({"QB assist: "..M.AimStatus,"Catch: "..M.CatchStatus.." | requests="..M.CatchRequests,
   "Catch control: "..(catchButton and catchButton.Parent and catchButton:GetFullName() or "none"),
   "Catch path: "..M.CatchMethod.." | jump requests="..M.JumpRequests,
   "Input support: firetouchinterest="..tostring(type(firetouchinterest)=="function")..", firesignal="..tostring(type(firesignal)=="function")..", getconnections="..tostring(type(getconnections)=="function"),
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

end)()
local Movement=(function()
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

end)()
local Runtime=(function()
-- Universe Football first release: replicated ball/player utilities and owned settings.
return function(Kit,Brand,Interface,Assists,Movement)
 local Players=game:GetService("Players")
 local Run=game:GetService("RunService")
 local Input=game:GetService("UserInputService")
 local player=Players.LocalPlayer
 local defaults={TouchCatch=false,AutoJump=false,JumpBoost=false,JumpPower=60,JumpHeight=9,InfiniteJump=false,Noclip=false,QBAim=false,AutoCatch=false,IncomingAlert=false,ReceiverMarker=false,AimCone=6,AimRange=160,AimStrength=4,LeadTime=.18,CatchDistance=5,
  BallHighlight=false,BallName=false,FollowBall=false,FieldOfView=80,CustomFOV=false,
  SpeedEnabled=false,WalkSpeed=24,PlayerESP=false,PlayerNames=false,ShowTeammates=true,FillTransparency=.65,ReduceMotion=false}
 local cfg=table.clone(defaults)
 local API={Game="Universe Football",Version="1.3",Config=cfg,Status="Starting",Alive=true,Candidates=0,Inspected=0,ScanCapped=false}
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
   local bounds={JumpPower={35,85},JumpHeight={4,16},AimCone={3,12},AimRange={25,220},AimStrength={2,8},LeadTime={0,.4},CatchDistance={2,6},WalkSpeed={16,60},FieldOfView={50,110},FillTransparency={0,1}}
   value=math.clamp(value,bounds[key][1],bounds[key][2])
  end
  cfg[key]=value
  if API.Movement and (key=="JumpBoost" or key=="Noclip") then API.Movement.Reset() end
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
  if API.Movement then API.Movement.Reset() end
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
   "No direct remote calls or rewritten throw packets. Ball discovery uses names/IsFootball; throw integration remains unverified."},"\n")
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
  if API.Movement then API.Movement.Destroy() end
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
  API.Movement=Movement({Config=cfg,Focused=function() return focused end})
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

end)()
local brand=Brand("https://raw.githubusercontent.com/copperpoppercms-sys/rift-hub-universe-football/main/assets/rift_logo.jpg")
local app=Runtime(Kit,brand,Interface,Assists,Movement)
app.OnUnload=function() if env.RiftUniverseFootball==app then env.RiftUniverseFootball=nil end end
env.RiftUniverseFootball=app
return app
