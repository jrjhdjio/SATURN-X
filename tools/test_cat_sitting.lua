-- Local behavioral harness. This does not simulate Roblox networking or physics.
local path=arg[1] or 'SATURN_X_CAT_SITTING.lua'
math.clamp=function(v,a,b) return math.max(a,math.min(b,v)) end
local function signal()
    local s={handlers={}}
    function s:Connect(fn)
        local c={Connected=true, fn=fn}
        function c:Disconnect() self.Connected=false end
        table.insert(self.handlers,c); return c
    end
    function s:Fire(...)
        for _,c in ipairs(self.handlers) do if c.Connected then c.fn(...) end end
    end
    return s
end
local vectorMT={}
Vector3={}
function Vector3.new(x,y,z) return setmetatable({X=x,Y=y,Z=z or 0},vectorMT) end
vectorMT.__add=function(a,b) return Vector3.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
vectorMT.__sub=function(a,b) return Vector3.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
vectorMT.__mul=function(a,b) return Vector3.new(a.X*b,a.Y*b,a.Z*b) end
vectorMT.__index=function(v,k)
    local m=math.sqrt(v.X*v.X+v.Y*v.Y+v.Z*v.Z)
    if k=='Magnitude' then return m end
    if k=='Unit' then return Vector3.new(v.X/m,v.Y/m,v.Z/m) end
end
Vector3.zero=Vector3.new(0,0,0)
Vector2={new=Vector3.new}
UDim={new=function(s,o) return {Scale=s,Offset=o} end}
UDim2={new=function(xs,xo,ys,yo) return {X=UDim.new(xs or 0,xo or 0),Y=UDim.new(ys or 0,yo or 0)} end}
UDim2.fromOffset=function(x,y) return UDim2.new(0,x,0,y) end
UDim2.fromScale=function(x,y) return UDim2.new(x,0,y,0) end
Color3={fromRGB=function(r,g,b) return {R=r,G=g,B=b} end}
local cframeMT={__add=function(a,b) return setmetatable({Position=a.Position+b},getmetatable(a)) end}
CFrame={lookAt=function(_,v) return {LookVector=v} end}
Enum=setmetatable({}, {__index=function(t,k)
    local v=setmetatable({}, {__index=function(a,b) rawset(a,b,k..'.'..b);return rawget(a,b) end})
    rawset(t,k,v);return v
end})
TweenInfo={new=function() return {} end}
local all={}
local methods={}
function methods:IsDescendantOf(parent) local o=self.Parent;while o do if o==parent then return true end;o=o.Parent end;return false end
function methods:FindFirstChildWhichIsA(class,deep) for _,o in ipairs(deep and self:GetDescendants() or self:GetChildren()) do if o:IsA(class) then return o end end end
function methods:MoveTo(pos) self.RootPart.Position=pos;self.MoveToFinished:Fire(true) end
function methods:Move(v) self.MoveDirection=v end
function methods:InputHoldBegin() self.begins=(self.begins or 0)+1 end
function methods:InputHoldEnd() self.ends=(self.ends or 0)+1 end
local mt={__index=function(o,k)
    if methods[k] then return methods[k] end
    return o.props[k]
end,__newindex=function(o,k,v) o.props[k]=v end}
Instance={new=function(class)
    local o=setmetatable({class=class,props={Name=class,Visible=true,Text='',Position=UDim2.new(),AbsoluteSize=Vector3.new(1024,768),Size=UDim2.new()},events={},attrs={}},mt)
    for _,e in ipairs({'Activated','InputBegan','InputEnded','FocusLost','Destroying','DescendantAdded','DescendantRemoving'}) do o.props[e]=signal() end
    table.insert(all,o);return o
end}
function methods:IsA(class) return self.class==class or (class=='BasePart' and self.class=='Part') end
function methods:GetChildren()
    local a={};for _,o in ipairs(all) do if o.Parent==self then table.insert(a,o) end end;return a
end
function methods:GetDescendants()
    local a={};for _,o in ipairs(self:GetChildren()) do table.insert(a,o);for _,d in ipairs(o:GetDescendants()) do table.insert(a,d) end end;return a
end
function methods:FindFirstChild(name) for _,o in ipairs(self:GetChildren()) do if o.Name==name then return o end end end
function methods:FindFirstChildOfClass(class) for _,o in ipairs(self:GetChildren()) do if o:IsA(class) then return o end end end
function methods:GetPropertyChangedSignal(k) self.events[k]=self.events[k] or signal();return self.events[k] end
function methods:SetAttribute(k,v) self.attrs[k]=v end
function methods:GetAttribute(k) return self.attrs[k] end
function methods:Destroy()
    if self.destroyed then return end
    self.destroyed=true;self.Destroying:Fire()
    for _,o in ipairs(self:GetChildren()) do o:Destroy() end
    self.Parent=nil
end
function methods:ChangeState(v) self.state=v end
local function obj(class,parent,props)
    local o=Instance.new(class);o.Parent=parent;for k,v in pairs(props or {}) do o[k]=v end;return o
end
local world=obj('Folder',nil)
playerGui=obj('Folder',world)
local char=obj('Model',world)
local hum=obj('Humanoid',char,{Health=100,MaxHealth=100,WalkSpeed=19,JumpPower=50,JumpHeight=7.2,UseJumpPower=true,AutoRotate=true,PlatformStand=false,MoveDirection=Vector3.zero})
local rootPart=obj('Part',char,{Name='HumanoidRootPart',CanCollide=true,Position=Vector3.new(10,20,30),CFrame=setmetatable({Position=Vector3.new(10,20,30)},cframeMT),AssemblyLinearVelocity=Vector3.zero})
local limb=obj('Part',char,{CanCollide=false})
player={Character=char,DisplayName='Tester',Name='tester',UserId=123,AccountAge=50,CharacterRemoving=signal(),CharacterAdded=signal(),FindFirstChild=function() return nil end}
Players={GetPlayers=function() return {player} end}
Workspace=obj('Workspace',world,{Gravity=196.2,CurrentCamera=obj('Camera',world,{FieldOfView=70,CFrame={LookVector=Vector3.new(0,0,-1)}})})
char.Parent=Workspace;hum.RootPart=rootPart;hum.MoveToFinished=signal()
Lighting=obj('Lighting',world,{Brightness=1,FogEnd=400,FogStart=0,GlobalShadows=true,Ambient=Color3.fromRGB(1,2,3),OutdoorAmbient=Color3.fromRGB(4,5,6)})
local atmosphere=obj('Atmosphere',Lighting,{Density=0.3,Haze=2})
UIS={InputBegan=signal(),InputChanged=signal(),InputEnded=signal(),JumpRequest=signal(),WindowFocusReleased=signal(),WindowFocused=signal(),GetFocusedTextBox=function() return nil end,IsKeyDown=function() return false end}
RunService={RenderStepped=signal(),PreSimulation=signal(),Heartbeat=signal()}
ProximityPromptService={PromptShown=signal(),PromptHidden=signal()}
PathfindingService={CreatePath=function() return {Status=Enum.PathStatus.Success,ComputeAsync=function(self,from,to) self.goal=to end,GetWaypoints=function(self) return {{Position=self.goal,Action='Walk'}} end} end}
TweenService={Create=function(_,o,_,props) return {Play=function() for k,v in pairs(props) do o[k]=v end end} end}
local pending={}
task={spawn=function(fn) table.insert(pending,fn) end,delay=function() end,defer=function() end,wait=function() end}
environment={}
CONFIG={Version='1.0.0-cat-beta',PlaceId=116802325837172}
game={PlaceId=116802325837172,GameId=67890}
warn=function() end
typeof=function(v) return getmetatable(v)==vectorMT and 'Vector3' or type(v) end
local session={SetVisible=function() end,Close=function(s) s.closed=true end,Bind=function() end,Finish=function() end}
SXMedia={Settings={language='th'},UISounds={},Begin=function() return session end,T=function(_,s) return s end,Refresh=function() end,PlayEffect=function() end,Asset=function() end,OpenSettings=function() end}
local f=assert(io.open(path));local source=f:read('*a');f:close()
local coreStart=assert(source:find('local SXSession = SXMedia:Begin("SATURN_X_CAT_SITTING"',1,true), 'Missing Cat Sitting core')
source=source:sub(coreStart)
source=source..'\nreturn {Finder=Finder,S=S,toggle=toggleSetters,reset=resetFeatures,stop=stop,window=window,layout=layout,root=root,gui=gui,flight=flyControls,setOpen=setOpen,savepoint=waypointName}'
local api=assert(load(source,'mini_core'))()
local function expect(v,msg) assert(v,msg) end
local function closeEnough(a,b) return math.abs(a-b)<0.001 end
local count=0
local function pass(s) count=count+1;print('PASS '..s) end
expect(api.window.Size.X.Offset==760 and api.window.Size.Y.Offset==510,'original desktop size')
api.root.AbsoluteSize=Vector3.new(400,800);api.layout()
expect(api.window.Size.X.Offset==430 and api.window.Size.Y.Offset==620,'original portrait size')
pass('desktop and portrait dimensions preserved')
for _,lang in ipairs({'en','zh','th'}) do
    SXMedia.Settings.language=lang
    local t=SXMedia:T('กระโดดกลางอากาศ')
    expect(t==({en='Air jump',zh='空中跳跃',th='กระโดดกลางอากาศ'})[lang],'translation '..lang)
end
pass('translation extension works in all three languages')
api.toggle.speed(true);expect(hum.WalkSpeed==24,'walk speed set')
api.toggle.jump(true);expect(closeEnough(hum.JumpPower,math.sqrt(2*196.2*10)),'jump power set')
api.toggle.speed(false);expect(hum.WalkSpeed==19,'original speed restored')
api.toggle.jump(false);expect(hum.JumpPower==50 and hum.JumpHeight==7.2,'jump restored')
hum.UseJumpPower=false;api.toggle.jump(true);expect(hum.JumpHeight==10,'height mode');api.toggle.jump(false)
pass('speed and both jump modes restore original values')
api.toggle.fly(true);expect(api.S.fly and api.S.flight and hum.PlatformStand and not hum.AutoRotate,'flight setup')
local flight=api.S.flight
api.S.up=true;RunService.RenderStepped:Fire(1/60)
expect(flight.velocity.VectorVelocity.Y==45,'vertical flight command')
api.setOpen(false);expect(api.S.fly and api.flight.Visible,'minimize keeps flight available')
UIS.WindowFocusReleased:Fire();expect(flight.velocity.VectorVelocity.Magnitude==0 and not api.S.up,'focus loss stop')
UIS.WindowFocused:Fire();api.toggle.fly(false)
expect(not api.S.flight and not hum.PlatformStand and hum.AutoRotate,'flight cleanup')
expect(flight.attachment.destroyed and flight.orientation.destroyed and flight.velocity.destroyed,'constraints deleted')
pass('flight, minimize, lost focus and cleanup')
api.toggle.noclip(true);RunService.PreSimulation:Fire()
expect(not rootPart.CanCollide and not limb.CanCollide,'noclip')
local extra=obj('Part',char,{CanCollide=true});RunService.PreSimulation:Fire();expect(not extra.CanCollide,'new part noclip')
api.toggle.noclip(false);expect(rootPart.CanCollide and not limb.CanCollide and extra.CanCollide,'exact collision values restored')
pass('noclip tracks new parts and restores original collisions')
local realClock=os.clock
os.clock=function() return 10 end
api.toggle.airJump(true);rootPart.AssemblyLinearVelocity=Vector3.new(3,-8,4)
UIS.JumpRequest:Fire()
expect(closeEnough(rootPart.AssemblyLinearVelocity.Y,math.sqrt(2*196.2*7.2)) and rootPart.AssemblyLinearVelocity.X==3,'air jump preserves horizontal velocity')
rootPart.AssemblyLinearVelocity=Vector3.zero;UIS.JumpRequest:Fire()
expect(rootPart.AssemblyLinearVelocity.Magnitude==0,'jump debounced')
api.toggle.airJump(false);os.clock=realClock
pass('air jump works and debounces repeated requests')
api.toggle.bright(true);api.toggle.noFog(true);api.toggle.noShadows(true)
expect(Lighting.Brightness==3 and atmosphere.Density==0 and not Lighting.GlobalShadows,'visual enabled')
api.toggle.speed(true);api.toggle.jump(true);api.toggle.fly(true);api.toggle.noclip(true);RunService.PreSimulation:Fire()
player.CharacterRemoving:Fire()
expect(not api.S.fly and not api.S.speed and not api.S.noclip and hum.WalkSpeed==19 and rootPart.CanCollide,'respawn reset')
api.reset();expect(Lighting.Brightness==1 and Lighting.GlobalShadows and atmosphere.Density==0.3 and atmosphere.Haze==2,'visual restored')
pass('respawn and full reset restore changed state')
local finder=api.Finder
game.PlaceId=42;api.toggle.fly(true)
expect(not api.S.fly,'wrong map rejected');game.PlaceId=CONFIG.PlaceId
local cat=obj('Model',Workspace,{Name='Whiskers'})
local catPart=obj('Part',cat,{Name='CatBody',Position=Vector3.new(14,20,30),CanCollide=true})
cat.PrimaryPart=catPart
local bowl=obj('Part',Workspace,{Name='FoodBowl',Position=Vector3.new(15,20,30)})
local prompt=obj('ProximityPrompt',bowl,{ObjectText='Bowl',ActionText='Feed',Enabled=true,MaxActivationDistance=10,HoldDuration=0})
local ownPrompt=obj('ProximityPrompt',rootPart,{ObjectText='Player',ActionText='Pet',Enabled=true,MaxActivationDistance=10,HoldDuration=0})
local click=obj('ClickDetector',bowl)
expect(finder:Candidate(cat).kind=='cat','cat detected')
expect(finder:Candidate(catPart)==nil,'cat children deduplicated')
expect(finder:Candidate(ownPrompt)==nil,'player objects excluded')
expect(finder:Candidate(obj('Part',Workspace,{Name='Education',Position=Vector3.zero}))==nil,'cat substring false positive')
finder:Scan();pending[#pending]()
expect(not finder.scanBusy and #finder.entries==3,'world scan finds actual instances')
expect(#finder:List()==3,'visible result list')
prompt.Enabled=false;expect(#finder:List()==2,'disabled prompt omitted');prompt.Enabled=true
finder.query='feed';expect(#finder:List()==1,'literal label search');finder.query=''
finder.catsOnly=true;expect(#finder:List()==1,'cat filter');finder.catsOnly=false
pass('map guard, scanner, filters and player exclusion')
local e=finder:Candidate(prompt);finder:Select(e)
finder:Interact();expect(not prompt.begins,'interaction cannot start before game shows prompt')
ProximityPromptService.PromptShown:Fire(prompt)
finder:Interact();expect(prompt.begins==1 and finder.holding==prompt,'eligible interaction starts')
ProximityPromptService.PromptHidden:Fire(prompt)
expect(not finder.holding and prompt.ends>=1,'hidden prompt releases hold')
ProximityPromptService.PromptShown:Fire(prompt)
rootPart.Position=Vector3.new(200,20,30)
finder:Interact();expect(prompt.begins==1,'out-of-range input rejected')
rootPart.Position=Vector3.new(10,20,30)
pass('interaction requires visible prompt and normal distance; cancellation releases input')
for i=1,40 do
    local p=obj('Part',Workspace,{Name='Door'..i,Position=Vector3.new(20+i,20,30)})
    obj('ClickDetector',p)
end
finder:Scan();pending[#pending]()
local rows=0;for _ in pairs(finder.rows) do rows=rows+1 end
expect(rows==32,'visible list capped at 32')
api.toggle.showTargets(true);finder:UpdateMarkers()
local marks=0;for _ in pairs(finder.markers) do marks=marks+1 end
expect(marks==12,'marker cap at 12')
api.toggle.showTargets(false);expect(next(finder.markers)==nil,'markers cleaned')
pass('32-result and 12-marker bounds with cleanup')
finder:Select(e);finder:Walk();local walk=pending[#pending]
finder:CancelWalk();local pos=rootPart.Position;walk()
expect(rootPart.Position==pos and not finder.walkingHum,'cancel before path work prevents movement')
finder:Walk();pending[#pending]()
expect(not finder.walkingHum and not finder.walkConnection,'completed walk cleans handles')
expect((rootPart.Position-bowl.Position).Magnitude<=10,'walk reaches selected area in mock')
bowl:Destroy();expect(finder:Position(e)==nil,'removed target invalid')
finder:Select(e);finder:Walk();expect(not finder.walkingHum,'cannot walk to removed target')
pass('walking completion, cancellation and removed targets')

api.stop(true);api.stop(true)
expect(not api.S.alive and session.closed and api.gui.destroyed and environment.SATURN_X_CAT_SITTING_STOP==nil,'stop is idempotent')
for _,c in ipairs(api.S.connections) do expect(not c.Connected,'connection leak') end
pass('closing is idempotent and disconnects handlers')
print('Passed '..count..' behavior groups; real Roblox physics not tested.')
