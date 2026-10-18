-- Mock tests of observation boundaries and forwarding, not a live executor test.
local create=assert(loadfile('shared/SATURN_X_HARPOON_TRACE.lua'))()
local checks=0
local function expect(value,label) assert(value,label);checks=checks+1 end
local function instance(class,name,parent)
 local o={ClassName=class,Name=name,Parent=parent,children={},instance=true}
 if parent then parent.children[#parent.children+1]=o end
 function o:IsA(kind) return self.ClassName==kind end
 function o:GetFullName() return (self.Parent and self.Parent:GetFullName()..'.' or '')..self.Name end
 function o:GetChildren() return self.children end
 function o:GetDescendants()
  local out={};for _,c in ipairs(self.children) do out[#out+1]=c;for _,d in ipairs(c:GetDescendants()) do out[#out+1]=d end end;return out
 end
 return o
end
typeof=function(v) return type(v)=='table' and v.instance and 'Instance' or type(v) end
local char=instance('Model','Character')
local tool=instance('Tool','Harpoon',char)
local script=instance('LocalScript','HarpoonScript',tool)
local other=instance('LocalScript','OtherScript',tool)
local remote=instance('RemoteEvent','Throw')
local game={PlaceId=139802517550914,GameId=9167377564}
local player={Character=char}
local now,timers,completed=0,{},{}
local env={}
local function options()
 return {Environment=env,Player=player,Game=game,Clock=function() return now end,
  Delay=function(seconds,fn) timers[#timers+1]={seconds,fn} end,
  OnFinished=function(report) completed[#completed+1]=report end}
end
local c=create(options())
local ok,reason=c:Start()
expect(not ok and reason:find('Unsupported API',1,true),'missing API fails explicitly')
expect(not env.SATURN_X_HARPOON_OBSERVER,'unsupported runtime installs nothing')
local hook,installs,forwarded,lastArgs,method,caller,isExecutor,originalError=nil,0,0,nil,'FireServer',script,false,false
env.hookmetamethod=function(target,name,fn)
 expect(target==game and name=='__namecall','only game namecall observed')
 installs=installs+1;hook=fn
 return function(self,...)
  forwarded=forwarded+1;lastArgs=table.pack(...)
  expect(self==remote,'original receiver preserved')
  if originalError then error('original remote failure') end
  return 'result',nil,3
 end
end
env.getnamecallmethod=function() return method end
env.getcallingscript=function() return caller end
env.checkcaller=function() return isExecutor end
env.newcclosure=function(fn) return fn end
char.children={}
ok,reason=c:Start();expect(not ok and reason:find('Equip Harpoon',1,true),'requires held HarpoonScript')
char.children={tool};expect(c:Start(),'record starts when equipped and supported')
expect(timers[1][1]==15 and installs==1,'bounded timer and single hook')
local result=table.pack(hook(remote,'shot',nil,remote))
expect(forwarded==1 and lastArgs.n==3 and lastArgs[1]=='shot' and lastArgs[2]==nil and lastArgs[3]==remote,'forwards identical arguments exactly once')
expect(result.n==3 and result[1]=='result' and result[2]==nil and result[3]==3,'preserves return tuple including nil')
local report=c:Report()
expect(report:find('calls=1',1,true) and report:find('arg2: nil',1,true) and report:find('caller=Character.Harpoon.HarpoonScript',1,true),'captures actual script and positional nil')
caller=other;hook(remote,'other');caller=script
isExecutor=true;hook(remote,'executor');isExecutor=false
method='GetAttribute';hook(remote,'read');method='FireServer'
tool.Parent=nil;hook(remote,'unequipped');tool.Parent=char
expect(#c.Record.Rows==1 and forwarded==5,'unrelated scripts, executor, non-requests and unequipped calls ignored but forwarded')
method='InvokeServer';remote.ClassName='RemoteFunction';hook(remote,'invoke');method='FireServer';remote.ClassName='RemoteEvent'
expect(#c.Record.Rows==2,'remote function requests recorded without invoking again')
local value={token='hidden',password='hidden2'};value.loop=value
hook(remote,value)
report=c:Report()
expect(report:find('<redacted>',1,true) and report:find('<cycle>',1,true) and not report:find('hidden',1,true),'bounded serialization handles cycles and redacts sensitive keys')
local oldName=remote.GetFullName;remote.GetFullName=function() error('inspection failure') end
local before=forwarded;hook(remote,'still forwarded');remote.GetFullName=oldName
expect(forwarded==before+1 and c.Record.Errors==1,'inspection error cannot block original request')
originalError=true;ok,reason=pcall(hook,remote,'error');originalError=false
expect(not ok and tostring(reason):find('original remote failure',1,true),'original error propagates')
for i=1,20 do hook(remote,i) end
expect(#c.Record.Rows==12 and c.Record.Capped,'capture capped at twelve requests')
local prev=c.Record
now=16;hook(remote,'expired');expect(#prev.Rows==12,'deadline prevents late capture before timer runs')
timers[1][2]();expect(not prev.Active and env.SATURN_X_HARPOON_OBSERVER.Active==nil and #completed==1,'timer detaches observer and publishes once')
timers[1][2]();expect(#completed==1,'duplicate timer cannot publish twice')
expect(c:Start() and installs==1,'restart reuses installed inert hook')
local timer=timers[#timers][2];c:Finish();timer()
expect(#completed==1 and not c.Record.Active,'manual finish suppresses delayed copy')
expect(c:Start(),'restart before dispose');timer=timers[#timers][2];c:Dispose();timer()
expect(not c.Record and #completed==1 and not env.SATURN_X_HARPOON_OBSERVER.Active,'dispose releases active record and prevents late publication')
expect(not c:Start(),'disposed observer cannot restart')
local replacement=create(options());expect(replacement:Start() and installs==1,'script rerun shares wrapper without adding hooks')
before=forwarded;hook(remote,'new controller')
expect(#replacement.Record.Rows==1 and forwarded==before+1,'reused wrapper captures only current record')
replacement:Cancel();before=forwarded;hook(remote,'inactive')
expect(#replacement.Record.Rows==1 and forwarded==before+1,'cancelled wrapper only forwards')
print('PASS '..checks..' harpoon trace checks (mock executor; live capture not verified)')
