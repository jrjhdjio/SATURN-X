-- UI behavior model only: no Roblox rendering, hit testing, assets, or gameplay.
local path=arg[1] or 'shared/SATURN_X_ORBIT.lua'
math.clamp=function(v,a,b)return math.max(a,math.min(b,v))end
local signals={}
local function signal()
    local s={handlers={}};table.insert(signals,s)
    function s:Connect(fn)local c={Connected=true,fn=fn};function c:Disconnect()self.Connected=false end;table.insert(self.handlers,c);return c end
    function s:Fire(...)local copy={table.unpack(self.handlers)};for _,c in ipairs(copy)do if c.Connected then c.fn(...)end end end
    return s
end
local function connectionCount()local n=0;for _,s in ipairs(signals)do for _,c in ipairs(s.handlers)do if c.Connected then n=n+1 end end end;return n end
local vector={};vector.__index=function(v,k)if k=='Magnitude'then return math.sqrt(v.X*v.X+v.Y*v.Y+(v.Z or 0)^2)end end
vector.__sub=function(a,b)return setmetatable({X=a.X-b.X,Y=a.Y-b.Y,Z=(a.Z or 0)-(b.Z or 0)},vector)end
Vector2={new=function(x,y)return setmetatable({X=x,Y=y,Z=0},vector)end};Vector3={new=function(x,y,z)return setmetatable({X=x,Y=y,Z=z or 0},vector)end}
UDim={new=function(s,o)return {Scale=s or 0,Offset=o or 0}end}
local udim2Methods={}
UDim2={new=function(xs,xo,ys,yo)return setmetatable({X=UDim.new(xs,xo),Y=UDim.new(ys,yo)},{__index=udim2Methods})end}
function udim2Methods:Lerp(b,a)
    return UDim2.new(self.X.Scale+(b.X.Scale-self.X.Scale)*a,self.X.Offset+(b.X.Offset-self.X.Offset)*a,
        self.Y.Scale+(b.Y.Scale-self.Y.Scale)*a,self.Y.Offset+(b.Y.Offset-self.Y.Offset)*a)
end
UDim2.fromOffset=function(x,y)return UDim2.new(0,x,0,y)end;UDim2.fromScale=function(x,y)return UDim2.new(x,0,y,0)end
ColorSequence={new=function(a,b)return {a,b}end}
TweenInfo={new=function(...)return {...}end}
local colorMethods={}
Color3={fromRGB=function(r,g,b)return setmetatable({R=r,G=g,B=b},{__index=colorMethods})end}
function colorMethods:Lerp(b,a)return Color3.fromRGB(self.R+(b.R-self.R)*a,self.G+(b.G-self.G)*a,self.B+(b.B-self.B)*a)end
Enum=setmetatable({},{__index=function(t,k)local v=setmetatable({},{__index=function(a,b)rawset(a,b,k..'.'..b);return rawget(a,b)end});rawset(t,k,v);return v end})
local methods={};local all={};local creation=0
local mt={__index=function(o,k)return methods[k] or o.props[k]end}
local function ancestors(o)local a={};while o do table.insert(a,o);o=o.Parent end;return a end
mt.__newindex=function(o,k,v)
    local old=o.props[k];if old==v then return end
    if k=='Parent' then
        for _,p in ipairs(ancestors(old))do p.DescendantRemoving:Fire(o);for _,d in ipairs(o:GetDescendants())do p.DescendantRemoving:Fire(d)end end
        o.props[k]=v;creation=creation+1;o.order=creation
        o.AncestryChanged:Fire(o,v)
        for _,p in ipairs(ancestors(v))do p.DescendantAdded:Fire(o);for _,d in ipairs(o:GetDescendants())do p.DescendantAdded:Fire(d)end end
    else o.props[k]=v end
    if o.events[k]then o.events[k]:Fire()end
end
Instance={new=function(class)
    local o=setmetatable({class=class,props={Name=class,Size=UDim2.new(),Position=UDim2.new(),AnchorPoint=Vector2.new(0,0),AutomaticSize=Enum.AutomaticSize.None,LayoutOrder=0,Visible=true,Enabled=true,Text='',ZIndex=1,Scale=1,AbsolutePosition=Vector2.new(0,0),AbsoluteSize=Vector2.new(300,50),AbsoluteWindowSize=Vector2.new(300,300),CanvasPosition=Vector2.new(0,0)},events={},attrs={}},mt)
    for _,e in ipairs({'Destroying','AncestryChanged','DescendantAdded','DescendantRemoving','MouseEnter','MouseLeave','SelectionGained','SelectionLost','InputBegan','InputEnded','Activated'})do o.props[e]=signal()end
    table.insert(all,o);return o
end}
local guiClasses={Frame=true,TextLabel=true,TextButton=true,ImageButton=true,ImageLabel=true,TextBox=true,ViewportFrame=true,ScrollingFrame=true,CanvasGroup=true}
function methods:IsA(c)return self.class==c or(c=='GuiObject'and guiClasses[self.class])or(c=='GuiButton'and(self.class=='TextButton'or self.class=='ImageButton'))end
function methods:GetChildren()local t={};for _,o in ipairs(all)do if o.Parent==self then table.insert(t,o)end end;table.sort(t,function(a,b)return a.order<b.order end);return t end
function methods:GetDescendants()local t={};for _,o in ipairs(self:GetChildren())do table.insert(t,o);for _,d in ipairs(o:GetDescendants())do table.insert(t,d)end end;return t end
function methods:IsDescendantOf(p)local o=self.Parent;while o do if o==p then return true end;o=o.Parent end;return false end
function methods:FindFirstChild(name)for _,o in ipairs(self:GetChildren())do if o.Name==name then return o end end end
function methods:FindFirstChildOfClass(c)for _,o in ipairs(self:GetChildren())do if o:IsA(c)then return o end end end
function methods:GetPropertyChangedSignal(k)self.events[k]=self.events[k]or signal();return self.events[k]end
function methods:SetAttribute(k,v)self.attrs[k]=v end;function methods:GetAttribute(k)return self.attrs[k]end
function methods:Destroy()
    if self.destroyed then return end;self.destroyed=true;self.Destroying:Fire()
    for _,o in ipairs(self:GetChildren())do o:Destroy()end
    self.Parent=nil
    for _,s in pairs(self.events)do for _,c in ipairs(s.handlers)do c:Disconnect()end end
    for _,s in pairs(self.props)do if type(s)=='table'and s.handlers then for _,c in ipairs(s.handlers)do c:Disconnect()end end end
end
local function obj(c,p,props)local o=Instance.new(c);for k,v in pairs(props or{})do o[k]=v end;o.Parent=p;return o end
local deferred={};local delayed={}
task={spawn=function(f)table.insert(deferred,f)end,defer=function(f)table.insert(deferred,f)end,delay=function(_,f)table.insert(delayed,f)end}
local function flush()local guard=0;while #deferred>0 do guard=guard+1;assert(guard<100,'recursive rescan');local q=deferred;deferred={};for _,f in ipairs(q)do f()end end end
local function runDelayed()local q=delayed;delayed={};for _,f in ipairs(q)do f()end end
local clock=0;os.clock=function()return clock end
local RunService={Heartbeat=signal(),PreRender=signal()};local UIS={InputEnded=signal(),InputChanged=signal(),WindowFocusReleased=signal(),WindowFocused=signal()}
local GuiService=obj('GuiService',nil,{ReducedMotionEnabled=false});local saved
local HttpService={JSONEncode=function(_,settings)saved={};for k,v in pairs(settings)do saved[k]=v end;return 'mock-json'end}
writefile=function(p,c)assert(p=='SATURN_X_shared_settings_v1.json'and c=='mock-json')end
local services={RunService=RunService,UserInputService=UIS,GuiService=GuiService,HttpService=HttpService}
local TweenService={Create=function(_,o,_,props) local t={};function t:Play()for k,v in pairs(props)do o[k]=v end end;function t:Cancel()self.cancelled=true end;return t end};services.TweenService=TweenService
-- Linear easing isolates timeline tests from Roblox's native easing/rendering.
function TweenService:GetValue(alpha)return alpha end
game={GetService=function(_,name)return assert(services[name],name)end};workspace={CurrentCamera={ViewportSize=Vector2.new(1200,800)}}
local host=obj('Folder');local sharedGui=obj('ScreenGui',host)
local M={Alive=true,Version='1.0.0',Settings={language='en'},Gui=sharedGui,WatchRoots={},Bindings={},Renderers={}}
function M:Refresh()for _,f in ipairs(self.Renderers)do f()end end
function M:T(s)return s=='เปิด'and(self.Settings.language=='en'and'On'or'เปิด')or s end
function M:BindText(o,p)
    self.Bindings[o]=self.Bindings[o]or{};if self.Bindings[o][p]then return end
    local r={source=o[p]};self.Bindings[o][p]=r
    function r.render()r.applied=self:T(r.source);o[p]=r.applied end
    r.c=o:GetPropertyChangedSignal(p):Connect(function()if o[p]~=r.applied then r.source=o[p];r.render()end end);r.render()
end
function M:Watch(root)
    if self.WatchRoots[root]then return end;self.WatchRoots[root]=true
    local function add(o)if o:IsA('TextLabel')or o:IsA('TextButton')then self:BindText(o,'Text')end end
    for _,o in ipairs(root:GetDescendants())do add(o)end
    root.DescendantAdded:Connect(add)
    root.DescendantRemoving:Connect(function(o)local rows=self.Bindings[o];if rows then for _,r in pairs(rows)do r.c:Disconnect()end;self.Bindings[o]=nil end end)
end
function M:Set(k,v)self.Settings[k]=v;for _,props in pairs(self.Bindings)do for _,r in pairs(props)do r.render()end end;self:Refresh();return true end
function M:Destroy()self.Alive=false;sharedGui:Destroy()end
function M:Click()self.clicks=(self.clicks or 0)+1 end;function M:OpenSettings()end
function M:PlayEffect()self.waves=(self.waves or 0)+1;return self.Settings.effectsEnabled~=false end
function M:Asset(_,callback)callback(nil)end
M.Audio=obj('Folder',host);M.EffectsGroup=obj('SoundGroup',M.Audio)
M.Motion={Reduced=false};M.Settings.motionEnabled=true;M.Settings.pressMotionEnabled=true
if arg[2] then
    M.Motion=nil
    assert(loadfile(arg[2]))()(M)
end
writefile=nil
local install=assert(loadfile(path))();local orbit=install(M)
local function tick(n)for _=1,n or 35 do clock=clock+1/30;RunService.PreRender:Fire(1/30);RunService.Heartbeat:Fire(1/30);flush()end end
local flushTimers=runDelayed
runDelayed=function() flushTimers();tick(100) end
local function descendantsNamed(root,name)for _,o in ipairs(root:GetDescendants())do if o.Name==name then return o end end end
local passed=0;local function pass(s)passed=passed+1;print('PASS '..s)end
assert(install(M)==orbit);assert(M.Build=='1.5.1-orbit');pass('idempotent install on a live media service')
local root=obj('ScreenGui',host)
local surface=obj('Frame',root,{AbsoluteSize=Vector2.new(360,740)})
local window=obj('CanvasGroup',surface,{Size=UDim2.fromOffset(760,510)})
local windowScale=obj('UIScale',window,{Scale=.6})
local contentPosition=UDim2.fromOffset(198,78)
local contentSize=UDim2.new(1,-212,1,-120)
local content=obj('Frame',window,{Name='Content',Position=contentPosition,Size=contentSize})
local sidebar=obj('ScrollingFrame',window,{Name='Categories'})
local logo=obj('ImageLabel',window);local minimize=obj('TextButton',window,{Text='−'})
local floating=obj('ImageButton',surface)
local selected,shown,soundCount=nil,nil,0
local options={Gui=root,Root=surface,Window=window,Floating=floating,Logo=logo,Minimize=minimize,
    Names={'อัปเดตแรก','เครดิตผู้สร้าง','โปรไฟล์ผู้เล่น','บิน','เคลื่อนที่','ภาพ / กล้อง','จุดบันทึก','ตั้งค่า'},
    OnSelect=function(i)selected=i end,OnVisible=function(v)shown=v end,PlayWindow=function()soundCount=soundCount+1 end}
local c=orbit:Create(options);assert(orbit:Create(options)==c)
M:Watch(root,{})
flush();assert(c.AtlasFailed and c.Planets[1].Fallback.Visible)
assert(#c.Planets==8 and #c.Rings==8)
assert(descendantsNamed(c.Stage,'AssetStatus').Text=='Using fallback icons')
c:Open(false);assert(c.State=='opening' and not window.Visible and shown and not floating.Visible)
runDelayed();assert(c.State=='orbit');assert(c.Fit.Scale>0.57 and c.Fit.Scale<0.58)
assert(c.Planets[1].Button.Size.X.Offset*c.Fit.Scale>=48)
assert(window.Size.X.Offset==760 and window.Size.Y.Offset==510 and windowScale.Scale==.6)
pass('8 rings and usable phone targets; original window dimensions and scale retained')
local angle=c.Angle;tick();assert(c.Angle>angle)
c.Planets[4].Button.Activated:Fire()
assert(c.Selected==4 and c.State=='orbit' and selected==nil and not window.Visible)
assert(descendantsNamed(c.Stage,'CategoryDetail').Text=='Flight options and controls')
angle=c.Angle;tick();assert(c.Angle==angle)
c.Planets[5].Button.Activated:Fire();assert(c.Selected==5 and selected==nil)
c.Planets[5].Button.Activated:Fire();assert(c.State=='category' and selected==5 and window.Visible and not c.Stage.Visible)
pass('first tap shows details and freezes orbit; same-planet second tap opens only its existing page')
for i=1,8 do
    c:Open(false);runDelayed();selected=nil
    c:Tap(i);assert(selected==nil);c:Tap(i);assert(selected==i and c.State=='category')
end
pass('all eight category callbacks remain reachable')
local pageScale=content:FindFirstChild('OrbitPageScale')
local frameTrack=c.FrameAnimations[window]
assert(orbit.AnimationFrames==20 and orbit.AnimationFPS==60 and #frameTrack.Samples==20)
assert(frameTrack.Frame==1 and window.GroupTransparency==1 and pageScale.Scale<1)
for frame=1,20 do
    RunService.PreRender:Fire(1/60)
    assert(frameTrack.Frame==frame)
    assert(math.abs(window.GroupTransparency-(1-(frame-1)/19))<1e-9)
end
RunService.PreRender:Fire(1/60)
assert(c.FrameAnimations[window]==nil and c.FrameAnimations[content]==nil and c.FrameAnimations[pageScale]==nil)
pass('page reveal advances through exactly 20 sampled poses at 60 Hz and releases finished tracks')
assert(pageScale and windowScale.Scale==.6 and pageScale.Scale==1 and not sidebar.Visible)
c:SetOpen(false)
assert(window.Visible and not descendantsNamed(c.Stage,'OrbitalMenu').Visible)
c:SetOpen(true);runDelayed();assert(c.State=='orbit' and not window.Visible)
c:Tap(4);c:Tap(4);runDelayed();tick(25)
assert(c.State=='category' and window.Visible and window.GroupTransparency==0 and pageScale.Scale==1)
assert(content.Position.Y.Offset==78 and windowScale.Scale==.6)
pass('interrupting page collapse with reopen cannot hide the next page or change responsive scaling')
c:Open(false);runDelayed();c:Tap(4);c:Tap(4)
RunService.Heartbeat:Fire(.5)
assert(window.GroupTransparency==1 and c.FrameAnimations[window].Frame==1)
RunService.PreRender:Fire(.5)
assert(window.GroupTransparency==1 and c.FrameAnimations[window].Frame==1)
RunService.PreRender:Fire(.5)
assert(window.GroupTransparency>0 and window.GroupTransparency<1 and c.FrameAnimations[window].Frame==2)
tick(20)
assert(window.GroupTransparency==0 and pageScale.Scale==1 and c.FrameAnimations[window]==nil)
pass('a half-second stall preserves the first poses and Heartbeat cannot skip render frames')
c.ReturnButton.Activated:Fire();assert(c.State=='returning');runDelayed();runDelayed();assert(c.State=='orbit' and not window.Visible)
c:Tap(2);descendantsNamed(c.Stage,'CenterLogo').Activated:Fire();assert(c.Selected==nil)
descendantsNamed(c.Stage,'BlackHoleCollapse').Activated:Fire()
assert(c.State=='collapsing' and not shown and floating.Visible)
runDelayed();assert(c.State=='closed' and not c.Stage.Visible)
c:SetOpen(true);assert(c.State=='opening' and descendantsNamed(c.Stage,'Portal').Visible)
runDelayed();assert(c.State=='orbit' and shown and not floating.Visible)
pass('header logo return, clear selection, black-hole collapse and white-hole reopening')
c:SetOpen(false);c:SetOpen(true);c:SetOpen(false);c:SetOpen(true);runDelayed()
assert(c.State=='orbit' and c.Stage.Visible and not floating.Visible and not window.Visible)
c:SetOpen(false);c:SetOpen(true);c:SetOpen(false);runDelayed()
assert(c.State=='closed' and floating.Visible and not c.Stage.Visible)
pass('rapid open/close invalidates stale delayed transitions')
c:SetOpen(true);runDelayed();c:Tap(1)
M.Settings.language='zh';M:Refresh()
assert(descendantsNamed(c.Stage,'CategoryDetail').Text=='脚本更新与改动')
assert(descendantsNamed(c.Stage,'Instructions').Text=='再次轻点此行星打开')
M.Settings.language='th';M:Refresh();assert(descendantsNamed(c.Stage,'CategoryDetail').Text=='ข่าวและการเปลี่ยนแปลงของสคริปต์')
pass('new labels and category descriptions update in English, Chinese and Thai')
M.Motion.Reduced=true;c:SetOpen(false);assert(c.State=='closed')
c:SetOpen(true);assert(c.State=='orbit' and not descendantsNamed(c.Stage,'Portal').Visible)
angle=c.Angle;tick();assert(c.Angle==angle)
c:Tap(3);c:Tap(3);assert(c.State=='category' and selected==3)
M.Motion.Reduced=false;M.Settings.motionEnabled=false;c:Open(false);assert(c.State=='orbit')
angle=c.Angle;tick();assert(c.Angle==angle)
pass('reduced motion and disabled effects preserve immediate complete navigation')
M.Settings.motionEnabled=true;c:Open(false);runDelayed()
local touch={UserInputType=Enum.UserInputType.Touch}
c.Planets[1].Button.InputBegan:Fire(touch);angle=c.Angle;tick();assert(c.Angle==angle)
UIS.InputEnded:Fire(touch);tick();assert(c.Angle>angle and c.Planets[1].Scale.Scale==1)
UIS.WindowFocusReleased:Fire();angle=c.Angle;tick();assert(c.Angle==angle)
UIS.WindowFocused:Fire();tick();assert(c.Angle>angle)
pass('touch hold and lost focus pause orbit; release restores feedback')
surface.AbsoluteSize=Vector2.new(844,360);assert(c.Fit.Scale>0.57 and c.Fit.Scale<0.58)
surface.AbsoluteSize=Vector2.new(1200,800);assert(c.Fit.Scale==1)
for _,o in ipairs(c.Stage:GetDescendants())do assert(o:GetAttribute('SATURN_X_NoMotion')) end
pass('rotation resizing and isolation from shared scroll/press transforms')
c:SetOpen(false);local connectionsBefore=connectionCount();c:Destroy();runDelayed();flush()
assert(not c.Alive and orbit.Controllers[root]==nil and c.Stage.Parent==nil)
assert(minimize.Text=='−' and not c.ReturnButton.Parent and #c.Connections==0)
assert(content.Position==contentPosition and content.Size==contentSize and sidebar.Visible)
assert(pageScale.Parent==nil and window.GroupTransparency==0 and windowScale.Scale==.6)
assert(next(c.FrameAnimations)==nil)
assert(connectionCount()<connectionsBefore)
pass('destroy during transition disconnects hooks and removes navigation overlays')
-- Verify a failed download is never registered, then coalesced valid downloads cache once.
local registerCalls,httpCalls=0,0
writefile=function(_,data)assert(type(data)=='string')end
getcustomasset=function(_)registerCalls=registerCalls+1;return 'local://verified-asset'end
game.HttpGet=function()httpCalls=httpCalls+1;return 'not a PNG'end
local invalid='unset';orbit:Asset('atlas',function(id)invalid=id end);flush()
assert(invalid==nil and registerCalls==0 and httpCalls==1)
game.HttpGet=function()httpCalls=httpCalls+1;return '\137PNG\r\n\26\n'..string.rep('\0',2411469-8)end
local a,b;orbit:Asset('atlas',function(id)a=id end);orbit:Asset('atlas',function(id)b=id end);flush()
assert(a=='local://verified-asset' and b==a and registerCalls==1 and httpCalls==2)
local cached;orbit:Asset('atlas',function(id)cached=id end);assert(cached==a and httpCalls==2)
pass('invalid asset rejection, coalesced requests and successful cache reuse')
local c2=orbit:Create(options);flush()
for _,p in ipairs(c2.Planets)do
    p.Image.IsLoaded=false
    assert(not c2.AtlasFailed and not p.Fallback.Visible)
end
assert(not c2.MiniFallback.Visible)
pass('validated local artwork replaces fallback even if IsLoaded stays false')
for _,icon in ipairs(c2.Sprites)do
    local index=tonumber(icon.Name:match('%d+'));local col=(index-1)%4;local row=math.floor((index-1)/4)
    assert(icon.Parent.ClipsDescendants and icon.Size.X.Scale==4 and icon.Size.Y.Scale==3)
    assert(icon.Position.X.Scale==-col and icon.Position.Y.Scale==-row)
    assert(icon.ImageRectOffset.X==0 and icon.ImageRectOffset.Y==0 and icon.ImageRectSize.X==0 and icon.ImageRectSize.Y==0)
    assert(math.abs(icon.Parent.Size.X.Offset/icon.Parent.Size.Y.Offset-9/8)<1e-9)
    for _,resolution in ipairs({{1536,1024},{1024,683},{1024,682},{768,512},{512,341}})do
        local x=-icon.Position.X.Scale/icon.Size.X.Scale*resolution[1]
        local y=-icon.Position.Y.Scale/icon.Size.Y.Scale*resolution[2]
        assert(math.abs(x/resolution[1]-col/4)<1e-9)
        assert(math.abs(y/resolution[2]-row/3)<1e-9)
        assert(x+resolution[1]/4<=resolution[1]+1e-9 and y+resolution[2]/3<=resolution[2]+1e-9)
    end
end
c2:Open(false);runDelayed()
local portalArt=descendantsNamed(c2.Stage,'OrbitSprite10')
assert(portalArt.Position.X.Scale==-1 and portalArt.Position.Y.Scale==-2)
c2:SetOpen(false);assert(portalArt.Position.X.Scale==0 and portalArt.Position.Y.Scale==-2);runDelayed()
pass('all 10 artwork cells and both portal states retain bounds across 5 decoded texture sizes')
local old=c2;local oldService=orbit;local oldStage=c2.Stage
c2:Open(false);runDelayed();c2:Tap(4);c2:Tap(4)
orbit.Version='1.0.0';orbit=install(M);flush()
local upgraded=orbit.Controllers[root]
assert(orbit~=oldService and not oldService.Alive and oldStage.Parent==nil)
assert(upgraded and upgraded.State=='category' and upgraded.Selected==4 and window.Visible)
old:SetOpen(false);runDelayed();assert(upgraded.State=='closed' and floating.Visible)
old:SetOpen(true);runDelayed();assert(upgraded.State=='orbit' and not floating.Visible)
assert(orbit.Assets.atlas==a and upgraded.Planets[1].Image.Image==a)
pass('live service upgrade replaces old visuals and forwards previously captured toggle handles')
local colorButton=obj('TextButton',surface,{BackgroundColor3=Color3.fromRGB(0,0,0)})
local completed=0
local colorTrack=M:Animate20(colorButton,{BackgroundColor3=Color3.fromRGB(200,100,50)},nil,function()completed=completed+1 end)
assert(#colorTrack.Samples==20 and completed==0)
for frame=1,20 do RunService.PreRender:Fire(1/60);assert(colorTrack.Frame==frame) end
RunService.PreRender:Fire(1/60)
assert(completed==1 and colorButton.BackgroundColor3.R==200 and orbit.Tracks[colorButton]==nil)
M:Animate20(colorButton,{BackgroundColor3=Color3.fromRGB(0,0,0)},nil,function()completed=completed+1 end)
M:Animate20(colorButton,{BackgroundColor3=Color3.fromRGB(30,40,50)},nil,function()completed=completed+10 end)
RunService.PreRender:Fire(.5);assert(completed==1);tick(21);assert(completed==11 and colorButton.BackgroundColor3.R==30)
pass('shared button color transitions use 20 poses and cancel stale completion callbacks')
for _,fps in ipairs({10,30,60,144}) do
    colorButton.BackgroundColor3=Color3.fromRGB(0,0,0)
    local done=0
    local track=M:Animate20(colorButton,{BackgroundColor3=Color3.fromRGB(190,0,0)},nil,function() done=done+1 end)
    local seen,last=0,0
    for render=1,400 do
        RunService.PreRender:Fire(render==5 and .8 or 1/fps)
        if done>0 then assert(seen==20 and done==1);break end
        local pose=math.floor(colorButton.BackgroundColor3.R/10+.5)+1
        assert(pose==last or pose==last+1, 'skipped pose at '..fps..' FPS')
        if pose~=last then seen=seen+1;last=pose end
    end
    assert(done==1 and seen==20)
end
pass('all 20 output poses survive 10/30/60/144 FPS and an 800ms stall before completion')
upgraded:Open(false);runDelayed();upgraded:Tap(4);upgraded:Tap(4);tick(25)
upgraded:SetOpen(false)
RunService.Heartbeat:Fire(2);flushTimers()
assert(window.Visible and upgraded.Stage.Visible and upgraded.State=='collapsing')
for render=1,20 do
    RunService.PreRender:Fire(.5);RunService.Heartbeat:Fire(.5)
    assert(window.Visible and upgraded.Stage.Visible and upgraded.State=='collapsing')
end
RunService.PreRender:Fire(.5)
assert(not window.Visible and not upgraded.Stage.Visible and upgraded.State=='closed')
pass('slow close retains the page and portal through every render; wall timers cannot hide them early')

upgraded:Open(false);runDelayed();tick(25)
local planet=upgraded.Planets[1]
planet.Button.MouseEnter:Fire();assert(#upgraded.FrameAnimations[planet.Scale].Samples==20);tick(25)
planet.Button.InputBegan:Fire(touch);assert(#upgraded.FrameAnimations[planet.Scale].Samples==20);tick(25)
assert(planet.Scale.Scale==.96)
UIS.InputEnded:Fire(touch);tick(25);assert(planet.Scale.Scale==1.05)
local center=descendantsNamed(upgraded.Stage,'CenterLogo')
center.Activated:Fire();local centerScale=center:FindFirstChild('OrbitButtonScale')
assert(#upgraded.FrameAnimations[centerScale].Samples==20);tick(25);assert(centerScale.Scale==1)
local hole=descendantsNamed(upgraded.Stage,'BlackHoleCollapse')
hole.MouseEnter:Fire();assert(#upgraded.FrameAnimations[hole:FindFirstChild('OrbitButtonScale')].Samples==20)
pass('planet hover, press, release, center logo and black-hole buttons all use 20-pose feedback')
upgraded:Tap(4);upgraded:Tap(4);tick(25)
local closed=0
orbit:Close(root,function() closed=closed+1 end)
orbit:Close(root,function() closed=closed+1 end)
old:SetOpen(true);assert(upgraded.Closing and closed==0)
tick(25);runDelayed();assert(closed==1 and upgraded.State=='closed')
pass('close waits for its animation, ignores duplicate close/open input, and invokes shutdown once')
orbit:Destroy();assert(not orbit.Alive and not c2.Alive and next(orbit.Controllers)==nil)
assert(next(orbit.Tracks)==nil and not orbit.FrameConnection.Connected)
M:Destroy();flush();runDelayed();pass('shared service cleanup is safe after controller cleanup')
print(string.format('PASS %d orbital UI groups (mock Roblox APIs; no live client/render verification)',passed))
