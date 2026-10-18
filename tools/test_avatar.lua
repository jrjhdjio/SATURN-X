-- Local behavioral harness. This does not simulate Roblox networking or physics.
local path=arg[1] or 'SATURN_X_AVATAR.lua'
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
local cfMethods={}
local cfMT={}
local function makeCF(p,r) return setmetatable({p=p,r=r or {1,0,0,0,1,0,0,0,1}},cfMT) end
local function rotate(r,v)
    return Vector3.new(r[1]*v.X+r[2]*v.Y+r[3]*v.Z,r[4]*v.X+r[5]*v.Y+r[6]*v.Z,r[7]*v.X+r[8]*v.Y+r[9]*v.Z)
end
cfMT.__index=function(o,k)
    if k=='Position' then return o.p end
    if k=='LookVector' then return Vector3.new(-o.r[3],-o.r[6],-o.r[9]) end
    return cfMethods[k]
end
cfMT.__mul=function(a,b)
    local r={}
    for i=0,2 do for j=0,2 do
        r[i*3+j+1]=0
        for k=0,2 do r[i*3+j+1]=r[i*3+j+1]+a.r[i*3+k+1]*b.r[k*3+j+1] end
    end end
    return makeCF(a.p+rotate(a.r,b.p),r)
end
cfMT.__add=function(a,b) return makeCF(a.p+b,a.r) end
function cfMethods:Inverse()
    local r=self.r;local t={r[1],r[4],r[7],r[2],r[5],r[8],r[3],r[6],r[9]}
    return makeCF(rotate(t,self.p)*-1,t)
end
function cfMethods:ToObjectSpace(b) return self:Inverse()*b end
CFrame={new=function(x,y,z) return makeCF(Vector3.new(x or 0,y or 0,z or 0)) end}
CFrame.lookAt=function(pos,target) return makeCF(pos) end
CFrame.Angles=function(x,y,z)
    local cx,sx,cy,sy,cz,sz=math.cos(x),math.sin(x),math.cos(y),math.sin(y),math.cos(z),math.sin(z)
    return makeCF(Vector3.zero,{1,0,0,0,cx,-sx,0,sx,cx})*makeCF(Vector3.zero,{cy,0,sy,0,1,0,-sy,0,cy})*makeCF(Vector3.zero,{cz,-sz,0,sz,cz,0,0,0,1})
end

Enum=setmetatable({}, {__index=function(t,k)
    local v=setmetatable({}, {__index=function(a,b) rawset(a,b,k..'.'..b);return rawget(a,b) end})
    rawset(t,k,v);return v
end})
TweenInfo={new=function() return {} end}
local all={}
local methods={}
local mt={__index=function(o,k)
    if methods[k] then return methods[k] end
    return o.props[k]
end,__newindex=function(o,k,v) o.props[k]=v end}
Instance={new=function(class)
    local o=setmetatable({class=class,props={ClassName=class,Name=class,Visible=true,Text='',Position=UDim2.new(),AbsoluteSize=Vector3.new(1024,768),Size=UDim2.new()},events={},attrs={}},mt)
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
local rootPart=obj('Part',char,{Name='HumanoidRootPart',CanCollide=true,Position=Vector3.new(10,20,30),CFrame=CFrame.new(10,20,30),AssemblyLinearVelocity=Vector3.zero})
local limb=obj('Part',char,{CanCollide=false})
player={Character=char,DisplayName='Tester',Name='tester',UserId=123,AccountAge=50,CharacterRemoving=signal(),CharacterAdded=signal(),FindFirstChild=function() return nil end}
Players={GetPlayers=function() return {player} end}
Workspace={Gravity=196.2,CurrentCamera=obj('Camera',world,{FieldOfView=70,CFrame={LookVector=Vector3.new(0,0,-1)}})}
Lighting=obj('Lighting',world,{Brightness=1,FogEnd=400,FogStart=0,GlobalShadows=true,Ambient=Color3.fromRGB(1,2,3),OutdoorAmbient=Color3.fromRGB(4,5,6)})
local atmosphere=obj('Atmosphere',Lighting,{Density=0.3,Haze=2})
UIS={InputBegan=signal(),InputChanged=signal(),InputEnded=signal(),JumpRequest=signal(),WindowFocusReleased=signal(),WindowFocused=signal(),GetFocusedTextBox=function() return nil end,IsKeyDown=function() return false end}
RunService={RenderStepped=signal(),PreSimulation=signal()}
TweenService={Create=function(_,o,_,props) return {Play=function() for k,v in pairs(props) do o[k]=v end end} end}
task={spawn=function() end,delay=function() end,defer=function() end,wait=function() end}
environment={}
CONFIG={Version='1.0.0-mini-beta'}
game={PlaceId=12345,GameId=67890}
warn=function() end
typeof=function(v) return getmetatable(v)==vectorMT and 'Vector3' or type(v) end
local session={SetVisible=function() end,Close=function(s) s.closed=true end,Bind=function() end,Finish=function() end}
SXMedia={Settings={language='th'},UISounds={},Begin=function() return session end,T=function(_,s) return s end,Refresh=function() end,PlayEffect=function() end,Asset=function() end,OpenSettings=function() end}
-- Extra engine stubs for public profile loading and local visual poses.
local pending,delays={},{}
task.spawn=function(fn) table.insert(pending,fn) end
task.delay=function(seconds,fn) table.insert(delays,{seconds=seconds,fn=fn}) end
RunService.Heartbeat=signal()
RunService.bindings={}
function RunService:BindToRenderStep(name,priority,fn) self.bindings[name]=fn end
function RunService:UnbindFromRenderStep(name) self.bindings[name]=nil end
Workspace.CurrentCamera.CFrame=CFrame.new(0,0,10)
Workspace.CurrentCamera.Focus=CFrame.new()
function methods:IsDescendantOf(parent)
    local o=self.Parent;while o do if o==parent then return true end;o=o.Parent end;return false
end
function methods:FindFirstChildWhichIsA(class,deep)
    for _,o in ipairs(deep and self:GetDescendants() or self:GetChildren()) do if o:IsA(class) then return o end end
end
function methods:Clone()
    local list={self};for _,o in ipairs(self:GetDescendants()) do table.insert(list,o) end
    local map={}
    for _,o in ipairs(list) do map[o]=Instance.new(o.class) end
    for _,o in ipairs(list) do
        local c=map[o]
        for k,v in pairs(o.props) do
            if k~='Parent' and not (type(v)=='table' and v.handlers) then c[k]=map[v] or v end
        end
        c.Parent=map[o.Parent]
    end
    return map[self]
end
function methods:PivotTo(cf)
    local rp=self:FindFirstChild('HumanoidRootPart');local delta=cf*rp.CFrame:Inverse()
    for _,p in ipairs(self:GetDescendants()) do if p:IsA('BasePart') then p.CFrame=delta*p.CFrame;p.Position=p.CFrame.Position end end
end
function methods:GetBoundingBox() return CFrame.new(),Vector3.new(4,6,2) end
local function skeleton(model,h,r,scale)
    r.Size=Vector3.new(2,2,1);r.LocalTransparencyModifier=0.2;r.CFrame=CFrame.new(10,20,30)
    r.Name='HumanoidRootPart';r.Position=r.CFrame.Position
    h.RigType=Enum.HumanoidRigType.R6;h.HipHeight=0;h.RootPart=r
    local torso=obj('Part',model,{Name='Torso',CFrame=r.CFrame,Size=Vector3.new(2,2,1),LocalTransparencyModifier=0.1})
    obj('Motor6D',r,{Part0=r,Part1=torso,C0=CFrame.new(),C1=CFrame.new(),Enabled=true})
    for _,spec in ipairs({{'Head',0,1.5,0},{'Left Arm',-1.5,0,0},{'Right Arm',1.5,0,0},{'Left Leg',-0.5,-2,0},{'Right Leg',0.5,-2,0}}) do
        local rest=CFrame.new(spec[2]*scale,spec[3]*scale,spec[4]*scale)
        local part=obj('Part',model,{Name=spec[1],CFrame=r.CFrame*rest,Size=Vector3.new(1,2,1),LocalTransparencyModifier=0})
        part.Position=part.CFrame.Position
        obj('Motor6D',torso,{Part0=torso,Part1=part,C0=rest,C1=CFrame.new(),Enabled=true})
    end
    model.PrimaryPart=r
end
skeleton(char,hum,rootPart,1)
local face=obj('Decal',char:FindFirstChild('Head'),{Transparency=0.35})
local heldTool=obj('Tool',char)
local heldHandle=obj('Part',heldTool,{LocalTransparencyModifier=0,CFrame=CFrame.new(),Size=Vector3.new(1,1,1)})
local created={}
function Players:GetUserIdFromNameAsync(name)
    if name=='MissingUser' then error('missing user') end
    return name=='AlphaUser' and 100 or 200
end
function Players:GetNameFromUserIdAsync(id) return id==100 and 'AlphaUser' or 'BetaUser' end
function Players:GetHumanoidDescriptionFromUserIdAsync(id)
    return obj('HumanoidDescription',nil,{UserId=id})
end
function Players:CreateHumanoidModelFromDescriptionAsync(desc,rigType)
    local m=obj('Model',nil,{Name='Avatar'})
    local h=obj('Humanoid',m,{Health=100,AutoRotate=true,PlatformStand=false})
    local r=obj('Part',m,{Name='HumanoidRootPart',CFrame=CFrame.new(),Size=Vector3.new(2,2,1),LocalTransparencyModifier=0})
    skeleton(m,h,r,1.2)
    local head=m:FindFirstChild('Head')
    local accessory=obj('Accessory',m,{Name='Hat'})
    local handle=obj('Part',accessory,{Name='Handle',CFrame=head.CFrame*CFrame.new(0,1,0),Size=Vector3.new(1,1,1),LocalTransparencyModifier=0})
    obj('Weld',handle,{Part0=handle,Part1=head,C0=CFrame.new(),C1=CFrame.new(0,1,0),Enabled=true})
    m.PrimaryPart=r;created[#created+1]=m
    return m
end

local f=assert(io.open(path));local source=f:read('*a');f:close()
local coreStart=assert(source:find('local SXSession = SXMedia:Begin("SATURN_X_AVATAR"',1,true));source=source:sub(coreStart)
source=source..'\nreturn {Avatar=Avatar,S=S,toggle=toggleSetters,reset=resetFeatures,stop=stop,window=window,layout=layout,root=root,gui=gui,flight=flyControls,setOpen=setOpen,savepoint=waypointName}'
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
local avatar=api.Avatar
expect(avatar:Normalize('  @AlphaUser  ')=='AlphaUser','username normalization')
expect(not avatar:Normalize('Display Name') and not avatar:Normalize('@@AlphaUser') and not avatar:Normalize('ab'),'invalid usernames')
avatar:Load('MissingUser',false);pending[#pending]()
expect(not avatar.current and not avatar.busy,'lookup failure contained')
avatar:Load('@AlphaUser',false);pending[#pending]()
expect(avatar.current.username=='AlphaUser' and avatar.current.id==100,'profile loaded')
expect(avatar.current.model.Parent==avatar.world and avatar.current.rigType==hum.RigType,'preview uses matching rig')
expect(player.Character==char and rootPart.LocalTransparencyModifier==0.2,'preview does not touch character')
pass('username validation, lookup failure and profile preview')
avatar:Load('AlphaUser',false);local stale=pending[#pending]
avatar:Load('BetaUser',false);pending[#pending]();stale()
expect(avatar.current.username=='BetaUser','newest lookup wins')
avatar:Load('AlphaUser',false);local timedOut=pending[#pending];delays[#delays].fn();timedOut()
expect(not avatar.busy and avatar.current.username=='BetaUser','timeout ignores late result')
avatar:Load('AlphaUser',false);local canceled=pending[#pending];avatar:Restore(true);canceled()
expect(avatar.current.username=='BetaUser','restore cancels queued lookup')
pass('concurrent lookups, timeout and cancellation')
avatar:Wear()
expect(avatar.overlay and avatar.overlay.model.Parent==Workspace,'local overlay created')
expect(player.Character==char and rootPart.LocalTransparencyModifier==1 and face.Transparency==1,'source is only hidden locally')
expect(heldHandle.LocalTransparencyModifier==0,'held tool left visible')
expect(RunService.bindings[avatar.renderName]~=nil,'render bound')
local sourceTorso=char:FindFirstChild('Torso')
local sourceArm=char:FindFirstChild('Right Arm')
sourceArm.CFrame=sourceTorso.CFrame*CFrame.new(1.5,0,0)*CFrame.Angles(0,0,math.pi/2)
RunService.bindings[avatar.renderName]()
local targetTorso=avatar.overlay.model:FindFirstChild('Torso')
local targetArm=avatar.overlay.model:FindFirstChild('Right Arm')
local rel=targetTorso.CFrame:ToObjectSpace(targetArm.CFrame)
expect(closeEnough(rel.Position.X,1.8),'target proportions preserved')
expect(closeEnough(rel.r[1],0) and closeEnough(rel.r[4],1),'source animation rotation copied')
local targetHead=avatar.overlay.model:FindFirstChild('Head')
local targetHat=avatar.overlay.model:FindFirstChild('Hat'):FindFirstChild('Handle')
expect(closeEnough(targetHat.CFrame.Position.Y-targetHead.CFrame.Position.Y,1),'reversed accessory weld follows head')
pass('local overlay, target proportions, animation pose and accessory attachment')
Workspace.CurrentCamera.CFrame=CFrame.new(0,0,0.1);RunService.bindings[avatar.renderName]()
expect(targetHead.LocalTransparencyModifier==1,'overlay hidden in first-person')
Workspace.CurrentCamera.CFrame=CFrame.new(0,0,10);RunService.bindings[avatar.renderName]()
expect(targetHead.LocalTransparencyModifier==0,'overlay returns in third-person')
local added=obj('Part',char,{LocalTransparencyModifier=0.4})
char.DescendantAdded:Fire(added);expect(added.LocalTransparencyModifier==1,'late appearance hidden')
local overlay=avatar.overlay.model;avatar:Restore(true);avatar:Restore(true)
expect(not avatar.overlay and overlay.destroyed and rootPart.LocalTransparencyModifier==0.2 and face.Transparency==0.35 and added.LocalTransparencyModifier==0.4,'exact restoration')
expect(not RunService.bindings[avatar.renderName],'render unbound')
pass('first-person handling, late appearance and exact restoration')
avatar:Wear();player.CharacterRemoving:Fire()
expect(not avatar.overlay and rootPart.LocalTransparencyModifier==0.2,'respawn restoration')
local orphan=obj('Part',avatar.current.model,{Name='OrphanBody',CFrame=CFrame.new(),LocalTransparencyModifier=0,Size=Vector3.new(1,1,1)})
avatar:Wear();expect(not avatar.overlay and rootPart.LocalTransparencyModifier==0.2,'unsupported rig leaves original visible')
orphan:Destroy()
avatar:Wear();expect(avatar.overlay~=nil,'valid preview can be reapplied')
pass('respawn and unsupported-rig fallback')

api.stop(true);api.stop(true)
expect(not api.Avatar.overlay and rootPart.LocalTransparencyModifier==0.2,'closing restores appearance')
expect(not api.S.alive and session.closed and api.gui.destroyed and environment.SATURN_X_AVATAR_STOP==nil,'stop is idempotent')
for _,c in ipairs(api.S.connections) do expect(not c.Connected,'connection leak') end
pass('closing is idempotent and disconnects handlers')
print('Passed '..count..' behavior groups; real Roblox physics not tested.')
