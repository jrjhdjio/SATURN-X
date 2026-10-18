-- Behavioral regression tests; mock instances do not simulate live Roblox physics.
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
function methods:IsA(class) return self.class==class or (class=='BasePart' and (self.class=='Part' or self.class=='MeshPart' or self.class=='Seat' or self.class=='VehicleSeat')) end
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
function methods:GetFullName() return (self.Parent and self.Parent:GetFullName()..'.' or '')..self.Name end
function methods:GetExtentsSize() return self.extents or Vector3.new(3,3,3) end
function methods:FindFirstAncestorOfClass(class) local p=self.Parent;while p do if p:IsA(class) then return p end;p=p.Parent end end
Workspace=obj('Workspace',nil,{Name='Workspace'})
local char=obj('Model',Workspace,{Name='Player'})
local hum=obj('Humanoid',char,{Health=100})
local rootPart=obj('Part',char,{Name='HumanoidRootPart',Position=Vector3.zero,CFrame={LookVector=Vector3.new(0,0,1)}})
player={Character=char,UserId=123}
function character() return hum,rootPart end
function connect(signal,fn) return signal:Connect(fn) end
local notices={}
function notify(t) notices[#notices+1]=t end
function gameReady() return S.gameMatch and hum.Health>0 end
local waitHook
local now=10
os.clock=function() return now end
task={wait=function() if waitHook then waitHook() end end}
CONFIG={ScanInterval=3,PullBurstSeconds=4}
S={alive=true,items={},scanGeneration=0,resourceWords={'wood','log','plank','scrap','metal','stone','rock','coal','barrel','crate','rope','plastic'},
scanRadius=180,pullRadius=60,pullLimit=8,search='',gameMatch=true,attempts=0,pullUntil=0,pull=false}
local f=assert(io.open('SATURN_X.lua'));local source=f:read('*a');f:close()
local block=assert(source:match('%-%- BEGIN SEA ITEM LOGIC(.-)%-%- END SEA ITEM LOGIC'))
local api=assert(load(block..'\nreturn {candidate=candidate,scan=scan,list=filteredItems,pull=pullOnce,begin=beginPull,tick=updatePull,block=pullBlock,report=interactionReport}', '@sea-item-logic'))()
local checks=0
local function expect(ok,message) assert(ok,message);checks=checks+1 end
local function part(parent,name,anchored,position)
 local p=obj('Part',parent,{Name=name,Anchored=anchored or false,CanQuery=true,AssemblyMass=3,Position=position or Vector3.new(10,0,0),AssemblyLinearVelocity=Vector3.zero})
 p.AssemblyRootPart=p;Workspace.DescendantAdded:Fire(p);return p
end
local function model(name,parent) return obj('Model',parent or Workspace,{Name=name}) end
local function has(object) for _,item in ipairs(api.list()) do if item.object==object then return item end end end
local generic=obj('Folder',Workspace,{Name='OceanThings'})
local wood=model('Wood_Plank_03',generic);local woodPart=part(wood,'Mesh')
expect(api.candidate(woodPart).object==wood,'compound name in unknown folder is discoverable')
woodPart.CanQuery=false
local fixed=model('Small_Scrap_1',generic);local fixedPart=part(fixed,'Mesh',true)
expect(api.candidate(fixedPart)~=nil,'anchored item must be discoverable')
local prompted=model('Drop_82',generic);local promptedPart=part(prompted,'Handle')
obj('ProximityPrompt',promptedPart,{ActionText='Take',ObjectText='Useful item'})
expect(api.candidate(promptedPart).name=='Useful item','pickup prompt identifies unfamiliar item')
local drops=obj('Folder',Workspace,{Name='FloatingItems'})
local mystery=model('Salvage_99',drops);local mysteryPart=part(mystery,'Handle')
expect(api.candidate(mysteryPart).object==mystery,'loot container identifies unknown name')
local tool=obj('Tool',drops,{Name='SalvageTool'});local toolPart=part(tool,'Handle')
expect(api.candidate(toolPart).object==tool,'dropped tools discoverable')
local equipped=obj('Tool',char,{Name='Wood'});local eqPart=part(equipped,'Handle')
expect(api.candidate(eqPart)==nil,'equipped tools excluded')
local boat=model('Boat');local boatWood=model('Wood',boat);local boatPart=part(boatWood,'Mesh')
expect(api.candidate(boatPart)==nil,'boat structure excluded')
local npc=model('Pirate');obj('Humanoid',npc);local npcPart=part(npc,'Wood')
expect(api.candidate(npcPart)==nil,'characters excluded')
local owned=model('Wood');owned:SetAttribute('OwnerUserId',999);local ownedPart=part(owned,'Mesh')
expect(api.candidate(ownedPart)==nil,'foreign owned objects excluded')
owned:SetAttribute('OwnerUserId',0);expect(api.candidate(ownedPart)~=nil,'unowned ID zero accepted')
owned:SetAttribute('OwnerUserId',999)
local catalog=part(generic,'Catalog');expect(api.candidate(catalog)==nil,'log does not match catalog')
local sub=model('SalvagePiece');local subRoot=part(sub,'Handle');local namedChild=part(sub,'Wood')
namedChild.AssemblyRootPart=subRoot
expect(api.candidate(namedChild).object==sub,'named child resolves whole assembly object')
-- A prompt on a different object must never turn an entire map into loot.
local big=model('Map');big.extents=Vector3.new(500,500,500)
local tile=part(big,'Tile');local chest=model('UnknownChest',big);local chestPart=part(chest,'Handle')
obj('ProximityPrompt',chestPart,{ActionText='Pick up',ObjectText='Chest'})
expect(api.candidate(tile)==nil,'large map excluded')
local looseWood=part(big,'Wood')
expect(api.candidate(looseWood).object==looseWood,'standalone resource inside a large map stays discoverable')
-- Match was formerly lost after the first 1200 query results / CanQuery=false.
for i=1,1300 do part(generic,'Decor'..i) end
local late=model('FloatingMetal99',generic);local latePart=part(late,'Mesh');latePart.CanQuery=false
expect(api.scan(),'dense scene scans successfully')
expect(S.scanCount>1200 and has(late) and has(wood),'dense scene and non-queryable loot included')
expect(has(fixed),'anchored item survives list filtering')
local duplicate=part(wood,'Extra');duplicate.AssemblyRootPart=woodPart
api.scan();local count=0;for _,item in ipairs(S.items) do if item.object==wood then count=count+1 end end
expect(count==1,'multi-part model deduplicates')
-- Generic root still needs to resolve the named child on subsequent physics ticks.
local subItem=has(sub);expect(subItem~=nil,'named child assembly scanned')
isnetworkowner=function() return true end
S.search='no matches';api.pull(wood,true)
expect(S.lastAttempt==1 and woodPart.AssemblyLinearVelocity.Magnitude>0,'explicit selection ignores filter')
api.pull(fixed,true);expect(S.lastAttempt==0 and S.pullSkipped.anchored==1,'anchored item reports reason')
isnetworkowner=function() return false end
api.pull(wood,true);expect(S.lastAttempt==0 and S.pullSkipped.ownership==1,'ownership block reports reason')
isnetworkowner=function() error('unsupported') end
api.pull(wood,true);expect(S.lastAttempt==0 and S.pullSkipped.ownership==1,'ownership API failure is not success')
isnetworkowner=function() return true end
woodPart.Position=Vector3.new(100,0,0);api.pull(wood,true)
expect(S.pullSkipped.range==1 and S.lastAttempt==0,'range is evaluated at each pull tick')
woodPart.Position=Vector3.new(10,0,0)
api.pull(sub,true);expect(S.lastAttempt==1,'named child with generic assembly root can be pulled')
local external=part(boat,'Assembly');local weld=model('Wood');local weldPart=part(weld,'Piece');weldPart.AssemblyRootPart=external
api.scan();api.pull(weld,true);expect(S.pullSkipped.attached==1 and S.lastAttempt==0,'welded external structure not moved')
S.search='';S.selected=wood;api.begin(true)
expect(S.pullUntil==14 and S.lastAttempt==1,'manual button starts four-second burst')
local attempts=S.attempts;now=11;api.tick();expect(S.attempts==attempts+1,'burst repeats physics step')
now=15;attempts=S.attempts;api.tick();expect(S.attempts==attempts,'burst expires')
S.pull=true;api.tick();expect(S.attempts>attempts,'continuous pull works after burst')
S.pull=false;S.pullUntil=0;attempts=S.attempts;api.tick();expect(S.attempts==attempts,'cancel prevents more writes')
Workspace.DescendantRemoving:Fire(woodPart);woodPart.Parent=nil
Workspace.DescendantRemoving:Fire(duplicate);duplicate.Parent=nil
api.scan();expect(not has(wood) and S.selected==nil,'stream removal clears stale selection')
local sentinel=S.items;waitHook=function() S.scanGeneration=S.scanGeneration+1;waitHook=nil end
api.scan();expect(S.items==sentinel and not S.scanBusy,'respawn cancels pending scan without publishing stale items')
-- A single malformed object does not abort all results.
local bad=model('Wood');local badPart=part(bad,'Mesh');bad.extents={}
api.scan();expect(S.scanErrors>0 and has(late) and not S.scanBusy,'per-object failure isolated')
S.alive=false;attempts=S.attempts;S.pull=true;api.tick();expect(S.attempts==attempts,'closed UI cannot pull')
-- Read-only diagnostic output must include actual nearby objects and the equipped tool.
function methods:GetAttributes() return self.attrs end
S.alive=true;S.selected=nil;S.search='unrelated filter'
S.items={api.candidate(fixedPart),api.candidate(promptedPart)}
local harpoon=obj('Tool',char,{Name='Harpoon',Enabled=true,RequiresHandle=true,ManualActivationOnly=false})
obj('LocalScript',harpoon,{Name='Controller',ClassName='LocalScript'})
local control=obj('RemoteEvent',harpoon,{Name='Throw',ClassName='RemoteEvent'})
control.FireServer=function() error('diagnostics must not send requests') end
fixed:SetAttribute('ItemType','Wood');fixed:SetAttribute('UnrelatedSecret','do-not-log')
local report=api.report()
expect(report:find('anchored=true',1,true) and report:find('promptCount=0',1,true),'report includes anchored objects without interactions')
expect(report:find('action=Take',1,true) and report:find('promptCount=1',1,true),'report includes exact pickup prompt details')
expect(report:find('HELD TOOL:',1,true) and report:find('Harpoon',1,true) and report:find('Controller',1,true),'report identifies equipped tool and controller names')
expect(report:find('ItemType=Wood',1,true) and not report:find('do-not-log',1,true),'only item-related attributes reported')
expect(fixedPart.Anchored and not api.candidate(promptedPart).prompt.begins,'report does not change anchoring or activate prompts')
harpoon.Parent=nil;equipped.Parent=nil;S.items={}
report=api.report()
expect(report:find('No candidate within 60',1,true) and report:find('No equipped Tool found',1,true),'empty report explains how to obtain useful evidence')
print('PASS '..checks..' sea item regressions (mock instances; live game not tested)')
