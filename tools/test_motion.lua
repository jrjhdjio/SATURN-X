-- UI behavior model only: no Roblox rendering, hit testing, assets, or gameplay.
local path=arg[1] or 'shared/SATURN_X_MOTION.lua'
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
UDim2={new=function(xs,xo,ys,yo)return {X=UDim.new(xs,xo),Y=UDim.new(ys,yo)}end}
UDim2.fromOffset=function(x,y)return UDim2.new(0,x,0,y)end;UDim2.fromScale=function(x,y)return UDim2.new(x,0,y,0)end
Color3={fromRGB=function(r,g,b)return {R=r,G=g,B=b}end}
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
    for _,e in ipairs({'Destroying','AncestryChanged','DescendantAdded','DescendantRemoving','MouseEnter','MouseLeave','SelectionGained','SelectionLost','InputBegan','Activated'})do o.props[e]=signal()end
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
task={defer=function(f)table.insert(deferred,f)end,delay=function(_,f)table.insert(delayed,f)end}
local function flush()local guard=0;while #deferred>0 do guard=guard+1;assert(guard<100,'recursive rescan');local q=deferred;deferred={};for _,f in ipairs(q)do f()end end end
local function runDelayed()local q=delayed;delayed={};for _,f in ipairs(q)do f()end end
local clock=0;os.clock=function()return clock end
local RunService={Heartbeat=signal()};local UIS={InputEnded=signal(),InputChanged=signal(),WindowFocusReleased=signal()}
local GuiService=obj('GuiService',nil,{ReducedMotionEnabled=false});local saved
local HttpService={JSONEncode=function(_,settings)saved={};for k,v in pairs(settings)do saved[k]=v end;return 'mock-json'end}
writefile=function(p,c)assert(p=='SATURN_X_shared_settings_v1.json'and c=='mock-json')end
local services={RunService=RunService,UserInputService=UIS,GuiService=GuiService,HttpService=HttpService}
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
function M:Click()end;function M:OpenSettings()end
local install=assert(loadfile(path))();local motion=install(M)
local function tick(n)for _=1,n or 35 do clock=clock+1/30;RunService.Heartbeat:Fire(1/30);flush()end end
local function count(t)local n=0;for _ in pairs(t)do n=n+1 end;return n end
local passed=0;local function pass(s)passed=passed+1;print('PASS '..s)end
local initialConnections=connectionCount();assert(install(M)==motion);assert(connectionCount()==initialConnections);pass('one shared controller on repeated installation')
local root=obj('ScreenGui',host);local window=obj('Frame',root,{Size=UDim2.fromOffset(760,510)});local responsive=obj('UIScale',window,{Scale=.7})
local page=obj('ScrollingFrame',window,{AbsolutePosition=Vector2.new(0,0),AbsoluteWindowSize=Vector2.new(300,300)});obj('UIListLayout',page)
local heading=obj('TextLabel',page,{Text='Heading',Size=UDim2.new(1,0,0,32)})
local auto=obj('Frame',page,{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y})
obj('TextLabel',auto,{Text='Auto text',AutomaticSize=Enum.AutomaticSize.Y})
local button=obj('TextButton',page,{Size=UDim2.new(1,0,0,42),Text='เปิด'});local actions=0;button.Activated:Connect(function()actions=actions+1 end)
local stepper=obj('Frame',page,{Size=UDim2.new(1,0,0,62)});local inner=obj('TextButton',stepper,{Size=UDim2.fromOffset(30,30)})
local dynamic=obj('Frame',page,{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y});obj('UIListLayout',dynamic)
local result=obj('TextButton',dynamic,{Size=UDim2.new(1,0,0,42),Text='Result'})
local input=obj('TextBox',page,{Size=UDim2.new(1,0,0,43)})
local original={heading,auto,button,stepper,dynamic,input};local sizes={};for _,o in ipairs(original)do sizes[o]=o.Size end
M:Watch(root,{});flush();local controller=assert(motion.Roots[root]);assert(#controller.Slots==6)
local slots={};for _,o in ipairs(page:GetChildren())do if o:IsA('GuiObject')then table.insert(slots,o)end end
for i,r in ipairs(controller.Slots)do assert(r.object==original[i]and r.slot==slots[i]);assert(r.slot.Size==sizes[r.object])end
assert(window.Size.X.Offset==760 and window.Size.Y.Offset==510 and responsive.Scale==.7)
assert(result.Parent==dynamic and not result:FindFirstChildOfClass('UIScale'));assert(auto.Parent.AutomaticSize==Enum.AutomaticSize.Y)
assert(not input:FindFirstChildOfClass('UIScale'));pass('original sizes, row order, automatic height and dynamic list parents preserved')
assert(M.Bindings[button].Text.source=='เปิด','translation source lost during reparent');M:Set('language','th');assert(button.Text=='เปิด');M:Set('language','en');assert(button.Text=='On');pass('language source survives in-root reparenting')
local r=controller.Records[button];r.slot.AbsolutePosition=Vector2.new(0,-21);r.slot.AbsoluteSize=Vector2.new(300,42)
page.CanvasPosition=Vector2.new(0,80);local canvas=page.CanvasPosition;tick();assert(math.abs(r.scale.Scale-.96)<.001)
assert(r.slot.Size==sizes[button]and page.CanvasPosition==canvas);assert(r.stroke.Transparency<1)
r.slot.AbsolutePosition=Vector2.new(0,130);page.CanvasPosition=Vector2.new(0,90);tick();assert(r.scale.Scale==1);pass('scroll edge scale 96–100% without changing slot or canvas geometry')
local pointer={UserInputType=Enum.UserInputType.Touch,Position=Vector3.new(20,20,0)}
button.InputBegan:Fire(pointer);tick(6);assert(r.scale.Scale<.98);UIS.InputEnded:Fire(pointer);tick();assert(r.scale.Scale==1);assert(actions==0)
button.InputBegan:Fire(pointer);pointer.Position=Vector3.new(20,40,0);UIS.InputChanged:Fire(pointer);tick();assert(not r.pressed and r.scale.Scale==1)
button.Activated:Fire();tick();assert(actions==1);pass('touch press, release outside and drag cancellation leave actions untouched')
button.MouseEnter:Fire();tick();assert(r.stroke.Transparency<1 and r.scale.Scale<=1);button.MouseLeave:Fire();tick();assert(r.stroke.Transparency==1)
button.SelectionGained:Fire();tick();assert(r.stroke.Transparency<1);button.SelectionLost:Fire();tick();assert(r.stroke.Transparency==1);pass('mouse and gamepad feedback never enlarges buttons')
r.slot.AbsolutePosition=Vector2.new(0,-21);page.CanvasPosition=Vector2.new(0,100);tick();assert(r.scale.Scale<1)
assert(M:Set('motionEnabled',false));assert(r.scale.Scale==1 and r.stroke.Transparency==1);assert(not M:Set('motionEnabled','yes'));runDelayed();assert(saved.motionEnabled==false)
M:Set('motionEnabled',true);M:Set('scrollMotionEnabled',false);tick();assert(r.scale.Scale==1);M:Set('pressMotionEnabled',false);button.InputBegan:Fire(pointer);tick();assert(r.scale.Scale==1)
M:Set('scrollMotionEnabled',true);M:Set('pressMotionEnabled',true);tick();assert(r.scale.Scale<1);pass('independent settings apply immediately and persist as booleans')
GuiService.ReducedMotionEnabled=true;tick();assert(motion.Reduced and r.scale.Scale==1)
GuiService.ReducedMotionEnabled=false;tick();assert(not motion.Reduced and r.scale.Scale<1);pass('Roblox reduced-motion preference restores neutral UI')
window.Visible=false;tick();assert(r.scale.Scale==1);window.Visible=true;tick();assert(r.scale.Scale<1)
UIS.WindowFocusReleased:Fire();assert(r.scale.Scale==1);pass('hidden windows and focus loss reset visual state')
local recordCount=count(controller.Records);local watchedCount=count(controller.Watched);local baselineConnections=connectionCount()
for i=1,30 do
    for _,child in ipairs(dynamic:GetChildren())do if child:IsA('TextButton')then child:Destroy()end end
    result=obj('TextButton',dynamic,{Size=UDim2.new(1,0,0,42),Text='Result '..i});flush();tick(1)
    assert(result.Parent==dynamic)
end
assert(count(controller.Records)==recordCount);assert(count(controller.Watched)==watchedCount);assert(connectionCount()==baselineConnections)
pass('30 dynamic result rebuilds keep stable records and live handlers')
local later=obj('TextButton',page,{Size=UDim2.new(1,0,0,44)});flush();assert(controller.Records[later].slot);assert(#controller.Slots==7)
local c=connectionCount();M:Watch(root,{});assert(connectionCount()==c);later:Destroy();flush();assert(not controller.Records[later]);pass('new rows attach once and destroyed rows release effects')
local root2=obj('ScreenGui',host);local b2=obj('TextButton',root2,{Size=UDim2.fromOffset(80,40)});M:Watch(root2,{});flush();assert(motion.Roots[root2]);root2:Destroy();flush();assert(not motion.Roots[root2])
pass('closing one script releases only its own controller')
controller:Destroy(true);flush();assert(not motion.Roots[root]);assert(not button.destroyed)
for _,o in ipairs(original)do assert(o.Parent==page and o.Size==sizes[o]and not o:FindFirstChildOfClass('UIScale'))end
local restored={};for _,o in ipairs(page:GetChildren())do if o:IsA('GuiObject')then table.insert(restored,o)end end
for i,o in ipairs(original)do assert(restored[i]==o)end
button.Activated:Fire();assert(actions==2);pass('unbind restores original parents, row order, dimensions and action handlers')
M:Destroy();M:Destroy();flush();assert(not motion.Alive and not next(motion.Roots)and not next(motion.Pending))
for _,c in ipairs(motion.Connections)do assert(not c.Connected)end
pass('service cleanup is idempotent with no motion connections')
print('Passed '..passed..' motion groups. Roblox rendering and hit testing require live testing.')
