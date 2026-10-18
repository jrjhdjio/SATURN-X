-- SATURN X AVATAR / BM / 1.0.0-beta
-- Username-based profile outfit preview and local-only visual try-on.
-- No inventory purchases or server character/identity changes.
-- Same original layout: 760x510 desktop, responsive 430x620 portrait.
-- Client-side behavior depends on the experience. Not tested in a live Roblox session.
local CONFIG = {Creator="BM", Version="1.0.0-avatar-beta"}
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer
if not player then warn("SATURN X: run on a Roblox client, not a server.") return end
local playerGui = player:WaitForChild("PlayerGui", 15)
if not playerGui then warn("SATURN X: PlayerGui unavailable.") return end

local environment = (type(getgenv) == "function" and getgenv()) or _G
if type(environment.SATURN_X_AVATAR_STOP) == "function" then pcall(environment.SATURN_X_AVATAR_STOP, true) end
local stale = playerGui:FindFirstChild("SATURN_X_AVATAR")
if stale then stale:Destroy() end


-- BEGIN SATURN_X_SHARED_MEDIA 1.0.0
local SXMedia = (function()
-- SATURN X media / BM / 1.4.0-orbit
-- This module is bundled into every entry script; only image/audio data is downloaded.
-- Local music needs writefile and getcustomasset/getsynasset. No telemetry.
local env = (type(getgenv) == "function" and getgenv()) or _G
local existing = env.SATURN_X_MEDIA_SERVICE
local InstallMotion = (function()
-- SATURN X Motion 1.0.0 / BM
-- Embedded UI-only extension. Fixed scroll slots prevent layout feedback.
-- No remotes, gameplay changes, executable downloads, or replacement input handlers.
local function InstallMotion(M)
    if M.Motion and M.Motion.Alive then return M.Motion end
    local RunService=game:GetService("RunService")
    local UIS=game:GetService("UserInputService")
    local HttpService=game:GetService("HttpService")
    local GuiService=game:GetService("GuiService")
    local env=(type(getgenv)=="function" and getgenv()) or _G
    local defaults={motionEnabled=true,scrollMotionEnabled=true,pressMotionEnabled=true}
    for key,value in pairs(defaults) do if type(M.Settings[key])~="boolean" then M.Settings[key]=value end end
    local Motion={Version="1.0.0",Alive=true,Roots={},Connections={},Pending={},Dirty={},Reduced=false}
    M.Motion=Motion;M.Build="1.1.0-motion"
    local function connect(signal,fn,list)
        local c=signal:Connect(fn);table.insert(list or Motion.Connections,c);return c
    end
    local function disconnect(list) for _,c in ipairs(list) do c:Disconnect() end end
    local function own(class,props,parent)
        local o=Instance.new(class);o:SetAttribute("SATURN_X_MotionOwned",true)
        for key,value in pairs(props) do o[key]=value end
        o.Parent=parent;return o
    end
    local function visible(o)
        while o do
            if o:IsA("GuiObject") and not o.Visible then return false end
            if o:IsA("ScreenGui") and not o.Enabled then return false end
            o=o.Parent
        end
        return true
    end
    local function enabled() return Motion.Alive and M.Alive and M.Settings.motionEnabled and not Motion.Reduced end
    local function hasLayout(parent)
        return parent and (parent:FindFirstChildOfClass("UIListLayout") or parent:FindFirstChildOfClass("UIGridLayout"))
    end
    local function target(r)
        local scale=1
        if enabled() and visible(r.object) then
            if M.Settings.scrollMotionEnabled then scale=r.scrollScale or 1 end
            if M.Settings.pressMotionEnabled then
                if r.pressed or r.pulse>0 then scale=scale*0.965
                elseif r.hover then scale=math.min(1,scale+0.012) end
            end
        end
        return math.clamp(scale,0.92,1)
    end
    local function wake(r) if not r.dead then Motion.Pending[r]=true end end
    local function reset(r)
        r.pressed=nil;r.hover=false;r.pulse=0;r.scrollScale=1;r.current=1
        if r.scale and r.scale.Parent then r.scale.Scale=1 end
        if r.stroke and r.stroke.Parent then r.stroke.Transparency=1 end
        Motion.Pending[r]=nil
    end
    function Motion:Invalidate(controller)
        if controller and controller.Alive then self.Dirty[controller]=true end
    end
    function Motion:Refresh()
        for _,controller in pairs(self.Roots) do
            self:Invalidate(controller)
            for _,r in pairs(controller.Records) do
                if not enabled() then reset(r) else wake(r) end
            end
        end
    end
    local function readReduced()
        local ok,value=pcall(function() return GuiService.ReducedMotionEnabled end)
        Motion.Reduced=ok and value==true or false
        Motion:Refresh()
        M:Refresh()
    end
    readReduced()
    pcall(function() connect(GuiService:GetPropertyChangedSignal("ReducedMotionEnabled"),readReduced) end)

    function Motion:Bind(root)
        if not self.Alive or self.Roots[root] or not root:IsA("ScreenGui") then return end
        local controller={Alive=true,Root=root,Records={},Slots={},Scrollers={},Connections={},Watched={},Busy=false,Queued=false}
        self.Roots[root]=controller
        local function invalidate() Motion:Invalidate(controller) end
        local function disposeRecord(r,restore)
            if r.dead then return end;r.dead=true;Motion.Pending[r]=nil
            disconnect(r.connections);controller.Records[r.object]=nil
            if r.scale then pcall(function() r.scale:Destroy() end) end
            if r.stroke then pcall(function() r.stroke:Destroy() end) end
            if r.slot then
                for i,slotRecord in ipairs(controller.Slots) do if slotRecord==r then table.remove(controller.Slots,i);break end end
                if restore and r.object.Parent==r.slot and r.parent.Parent then
                    pcall(function()
                        r.object.Parent=r.parent;r.object.Size=r.saved.Size
                        r.object.Position=r.saved.Position;r.object.AnchorPoint=r.saved.AnchorPoint
                        r.object.AutomaticSize=r.saved.AutomaticSize;r.object.LayoutOrder=r.saved.LayoutOrder
                    end)
                end
                pcall(function() r.slot:Destroy() end)
            end
        end
        local function record(o)
            if controller.Records[o] then return controller.Records[o] end
            local r={object=o,connections={},scrollScale=1,current=1,pulse=0,hover=false}
            controller.Records[o]=r
            connect(o.Destroying,function() disposeRecord(r,false) end,r.connections)
            connect(o.AncestryChanged,function()
                task.defer(function()
                    if not r.dead and controller.Alive and not o:IsDescendantOf(root) then disposeRecord(r,false) end
                end)
            end,r.connections)
            return r
        end
        local function scaleFor(r)
            if r.scale or r.object:FindFirstChildOfClass("UIScale") then return end
            r.scale=own("UIScale",{Name="SATURN_X_MotionScale",Scale=1},r.object)
        end
        local function strokeFor(r)
            if r.stroke then return end
            r.stroke=own("UIStroke",{Name="SATURN_X_MotionGlow",ApplyStrokeMode=Enum.ApplyStrokeMode.Border,
                Color=Color3.fromRGB(217,229,244),Thickness=1,Transparency=1},r.object)
        end
        local function buttonFeedback(o)
            if not o:IsA("GuiButton") or o:GetAttribute("SATURN_X_NoMotion") then return end
            local r=record(o);if r.button then return end;r.button=true
            -- List children retain their original parent for game-owned list rebuilds.
            -- Only an isolated slot or a non-layout button gets a UIScale.
            if r.slot or not hasLayout(o.Parent) then scaleFor(r) end
            strokeFor(r)
            connect(o.MouseEnter,function() r.hover=true;wake(r) end,r.connections)
            connect(o.MouseLeave,function() r.hover=false;r.pressed=nil;wake(r) end,r.connections)
            connect(o.SelectionGained,function() r.hover=true;wake(r) end,r.connections)
            connect(o.SelectionLost,function() r.hover=false;r.pressed=nil;wake(r) end,r.connections)
            connect(o.InputBegan,function(input)
                if not enabled() or not M.Settings.pressMotionEnabled then return end
                if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
                    r.pressed=input;r.start=input.Position;r.pressedAt=os.clock();wake(r)
                end
            end,r.connections)
            connect(o.Activated,function() r.pressed=nil;r.pulse=0.075;wake(r) end,r.connections)
        end
        local function wrap(o,scroll)
            if o:GetAttribute("SATURN_X_MotionOwned") or o:GetAttribute("SATURN_X_NoMotion") then return end
            if not o:IsA("GuiObject") or o:IsA("ScrollingFrame") then return end
            local r=record(o);if r.slot then return end
            local textSources={}
            local textObjects={o};for _,descendant in ipairs(o:GetDescendants()) do table.insert(textObjects,descendant) end
            for _,textObject in ipairs(textObjects) do
                for property,binding in pairs(M.Bindings[textObject] or {}) do
                    table.insert(textSources,{object=textObject,property=property,source=binding.source,value=textObject[property]})
                end
            end
            local function restoreTranslationSources()
                if not controller.Alive then return end
                for _,entry in ipairs(textSources) do
                    local binding=M.Bindings[entry.object] and M.Bindings[entry.object][entry.property]
                    if binding and entry.object[entry.property]==entry.value then binding.source=entry.source;binding.render() end
                end
            end
            -- Keep all direct rows in original insertion/LayoutOrder sequence,
            -- including automatic-height text and dynamic list containers.
            r.parent=scroll;r.scroller=scroll
            r.saved={Size=o.Size,Position=o.Position,AnchorPoint=o.AnchorPoint,AutomaticSize=o.AutomaticSize,LayoutOrder=o.LayoutOrder}
            local automatic=o.AutomaticSize
            r.slot=own("Frame",{Name="SATURN_X_MotionSlot",BackgroundTransparency=1,BorderSizePixel=0,
                Size=o.Size,AutomaticSize=automatic,LayoutOrder=o.LayoutOrder,Visible=o.Visible,
                Active=false,ClipsDescendants=false,ZIndex=o.ZIndex},scroll)
            table.insert(controller.Slots,r)
            local fixed=automatic==Enum.AutomaticSize.None and o.Size.Y.Scale==0 and o.Size.Y.Offset>0
            r.scalable=fixed and not o:IsA("TextBox") and not o:IsA("ViewportFrame") and not o:FindFirstChildOfClass("UIScale")
            r.adjusting=true
            o.Parent=r.slot
            if fixed then
                o.Size=UDim2.fromScale(1,1);o.Position=UDim2.fromScale(0.5,0.5);o.AnchorPoint=Vector2.new(0.5,0.5)
            else
                o.Size=UDim2.new(1,0,o.Size.Y.Scale,o.Size.Y.Offset)
                o.Position=UDim2.fromOffset(0,0);o.AnchorPoint=Vector2.new(0,0)
            end
            r.adjusting=false
            restoreTranslationSources();task.defer(restoreTranslationSources)
            if r.scalable then scaleFor(r) end
            if r.scalable and not o:IsA("TextLabel") then strokeFor(r) end
            connect(o:GetPropertyChangedSignal("Visible"),function() if r.slot then r.slot.Visible=o.Visible end;invalidate() end,r.connections)
            connect(o:GetPropertyChangedSignal("LayoutOrder"),function() r.saved.LayoutOrder=o.LayoutOrder;r.slot.LayoutOrder=o.LayoutOrder;invalidate() end,r.connections)
            connect(o:GetPropertyChangedSignal("Size"),function()
                if r.adjusting then return end
                r.saved.Size=o.Size;r.slot.Size=o.Size;r.adjusting=true
                o.Size=fixed and UDim2.fromScale(1,1) or UDim2.new(1,0,o.Size.Y.Scale,o.Size.Y.Offset)
                r.adjusting=false;invalidate()
            end,r.connections)
            connect(o:GetPropertyChangedSignal("AutomaticSize"),function()
                -- A runtime layout-mode change retires effects for this row.
                r.saved.AutomaticSize=o.AutomaticSize;r.slot.AutomaticSize=o.AutomaticSize
                r.scalable=false;reset(r)
                if r.scale then r.scale:Destroy();r.scale=nil end
                r.adjusting=true;o.Size=UDim2.new(1,0,r.saved.Size.Y.Scale,r.saved.Size.Y.Offset)
                o.Position=UDim2.fromOffset(0,0);o.AnchorPoint=Vector2.new(0,0);r.adjusting=false;invalidate()
            end,r.connections)
        end
        local scan
        local function queueScan()
            if not controller.Alive or controller.Busy or controller.Queued then return end
            controller.Queued=true
            task.defer(function()
                controller.Queued=false
                if controller.Alive and root.Parent then scan() end
            end)
        end
        scan=function()
            if not controller.Alive then return end
            controller.Busy=true
            local descendants=root:GetDescendants()
            for _,o in ipairs(descendants) do
                if o:IsA("ScrollingFrame") and not controller.Scrollers[o] then
                    local scrollRecord={last=0,connections={}}
                    controller.Scrollers[o]=scrollRecord
                    for _,property in ipairs({"CanvasPosition","AbsoluteWindowSize","AbsoluteSize","Visible"}) do
                        connect(o:GetPropertyChangedSignal(property),function()
                            if property=="CanvasPosition" then scrollRecord.last=os.clock() end
                            invalidate()
                        end,scrollRecord.connections)
                    end
                    connect(o.Destroying,function() disconnect(scrollRecord.connections);controller.Scrollers[o]=nil end,scrollRecord.connections)
                end
                if o:IsA("GuiObject") and not o:GetAttribute("SATURN_X_MotionOwned") and not controller.Watched[o] then
                    local watch={};controller.Watched[o]=watch
                    connect(o:GetPropertyChangedSignal("Visible"),invalidate,watch)
                    connect(o.Destroying,function() disconnect(watch);controller.Watched[o]=nil end,watch)
                end
            end
            for scroll in pairs(controller.Scrollers) do
                if scroll:FindFirstChildOfClass("UIListLayout") then
                    for _,o in ipairs(scroll:GetChildren()) do wrap(o,scroll) end
                end
            end
            for _,o in ipairs(descendants) do buttonFeedback(o) end
            controller.Busy=false;invalidate()
        end
        function controller:Destroy(restore)
            if not self.Alive then return end;self.Alive=false
            Motion.Dirty[self]=nil;Motion.Roots[root]=nil;disconnect(self.Connections)
            for _,watch in pairs(self.Watched) do disconnect(watch) end
            for _,scrollRecord in pairs(self.Scrollers) do disconnect(scrollRecord.connections) end
            -- Stable iteration restores original row order before removing slots.
            local slots={};for _,r in ipairs(self.Slots) do table.insert(slots,r) end
            for _,r in ipairs(slots) do disposeRecord(r,restore) end
            local rest={};for _,r in pairs(self.Records) do table.insert(rest,r) end
            for _,r in ipairs(rest) do disposeRecord(r,restore) end
            self.Records={};self.Slots={};self.Scrollers={};self.Watched={}
        end
        connect(root.DescendantAdded,queueScan,controller.Connections)
        connect(root:GetPropertyChangedSignal("Enabled"),invalidate,controller.Connections)
        connect(root.Destroying,function() controller:Destroy(false) end,controller.Connections)
        scan()
        return controller
    end

    local function updateScroll(controller)
        for _,r in ipairs(controller.Slots) do
            if not r.dead and r.scalable and r.slot.Parent then
                local scroll=r.scroller
                r.scrollScale=1
                if enabled() and M.Settings.scrollMotionEnabled and visible(r.object) then
                    local window=scroll.AbsoluteWindowSize
                    local top=scroll.AbsolutePosition.Y;local bottom=top+window.Y
                    local y=r.slot.AbsolutePosition.Y;local h=r.slot.AbsoluteSize.Y
                    if window.Y>0 and h>0 then
                        local center=y+h*0.5
                        local edge=math.min(center-top,bottom-center)
                        local band=math.max(24,math.min(70,window.Y*0.22))
                        r.scrollScale=0.96+0.04*math.clamp(edge/band,0,1)
                    end
                end
                wake(r)
            end
        end
    end
    local accumulator=0
    connect(RunService.Heartbeat,function(dt)
        if not Motion.Alive then return end
        accumulator=accumulator+dt;if accumulator<1/30 then return end
        local step=math.min(accumulator,0.1);accumulator=0
        for controller in pairs(Motion.Dirty) do
            Motion.Dirty[controller]=nil
            if controller.Alive then updateScroll(controller) end
        end
        local alpha=1-math.exp(-24*step)
        for r in pairs(Motion.Pending) do
            if r.dead or not r.object.Parent then Motion.Pending[r]=nil
            elseif not enabled() or not visible(r.object) then reset(r)
            else
                if r.pressed and os.clock()-(r.pressedAt or 0)>2 then r.pressed=nil end
                r.pulse=math.max(0,r.pulse-step)
                local desired=target(r)
                r.current=r.current+(desired-r.current)*alpha
                if math.abs(desired-r.current)<0.0005 then r.current=desired end
                if r.scale then r.scale.Scale=r.current end
                local activity=M.Settings.pressMotionEnabled and (r.pressed or r.hover or r.pulse>0)
                local glow=activity and 0.38 or ((M.Settings.scrollMotionEnabled and (r.scrollScale or 1)<0.999) and 0.82 or 1)
                if r.stroke then r.stroke.Transparency=glow end
                if r.current==desired and r.pulse==0 and not r.pressed then Motion.Pending[r]=nil end
            end
        end
    end)
    connect(UIS.InputEnded,function(input)
        for _,controller in pairs(Motion.Roots) do
            for _,r in pairs(controller.Records) do
                if r.pressed==input then r.pressed=nil;wake(r) end
            end
        end
    end)
    connect(UIS.InputChanged,function(input)
        for _,controller in pairs(Motion.Roots) do
            for _,r in pairs(controller.Records) do
                if r.pressed and (r.pressed==input or input.UserInputType==Enum.UserInputType.MouseMovement) and r.start then
                    local delta=input.Position-r.start
                    if delta.Magnitude>8 then r.pressed=nil;wake(r) end
                end
            end
        end
    end)
    connect(UIS.WindowFocusReleased,function()
        for _,controller in pairs(Motion.Roots) do for _,r in pairs(controller.Records) do reset(r) end;Motion:Invalidate(controller) end
    end)

    local baseWatch=M.Watch
    function M:Watch(root,session)
        baseWatch(self,root,session)
        if session then Motion:Bind(root) end
    end
    local baseSet=M.Set
    function M:Set(key,value)
        if defaults[key]==nil then return baseSet(self,key,value) end
        if type(value)~="boolean" then return false end
        self.Settings[key]=value;env.SATURN_X_MEDIA_SETTINGS=self.Settings
        Motion:Refresh();self:Refresh()
        self.SaveSerial=(self.SaveSerial or 0)+1;local serial=self.SaveSerial
        task.delay(0.3,function()
            if not self.Alive or serial~=self.SaveSerial then return end
            if type(writefile)=="function" then
                local ok=pcall(function() writefile("SATURN_X_shared_settings_v1.json",HttpService:JSONEncode(self.Settings)) end)
                self.SaveStatus=ok and "saved" or "session"
            else self.SaveStatus="session" end
            self:Refresh()
        end)
        return true
    end
    local dictionary={
        ["เอฟเฟกต์เมนู"]={en="Menu motion",zh="菜单动效"},
        ["เปิดเอฟเฟกต์เมนู"]={en="Enable menu motion",zh="启用菜单动效"},
        ["ย่อรายการขณะเลื่อน"]={en="Scale down on scroll",zh="滚动缩小效果"},
        ["เอฟเฟกต์แตะ / ชี้ปุ่ม"]={en="Tap / hover feedback",zh="点击 / 悬停反馈"},
        ["ขนาดเมนูเดิม • เอฟเฟกต์ใช้ร่วมกันทุกตัว"]={en="Original menu size • Shared by every script",zh="保持原菜单尺寸 · 所有脚本共用"},
        ["Roblox เปิดลดการเคลื่อนไหวอยู่ • พักเอฟเฟกต์"]={en="Roblox reduced motion is on • Effects paused",zh="Roblox 已启用减少动态 · 动效已暂停"},
        ["ปรับได้ทันที • รองรับเมาส์และการสัมผัส"]={en="Changes apply now • Mouse and touch",zh="设置立即生效 · 支持鼠标与触摸"},
    }
    local baseT=M.T
    function M:T(source)
        local row=dictionary[source];local lang=self.Settings.language
        if row and row[lang] then return row[lang] end
        return baseT(self,source)
    end
    local panel=own("Frame",{Name="SATURN_X_MotionSettings",Size=UDim2.fromOffset(400,310),
        Position=UDim2.fromScale(0.5,0.5),AnchorPoint=Vector2.new(0.5,0.5),Visible=false,
        BackgroundColor3=Color3.fromRGB(13,16,24),BorderSizePixel=0,ZIndex=40},M.Gui)
    own("UICorner",{CornerRadius=UDim.new(0,16)},panel)
    own("UIStroke",{Color=Color3.fromRGB(62,76,97),Thickness=1},panel)
    local panelScale=own("UIScale",{Scale=1},panel)
    local function label(text,x,y,w,h,size)
        local o=own("TextLabel",{Text=text,TextColor3=Color3.fromRGB(226,234,245),TextSize=size or 13,
            Font=Enum.Font.Gotham,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,
            BackgroundTransparency=1,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),ZIndex=41},panel)
        M:BindText(o,"Text");return o
    end
    local function button(parent,text,x,y,w,h,callback)
        local b=own("TextButton",{Text=text,TextColor3=Color3.fromRGB(226,234,245),TextSize=13,Font=Enum.Font.GothamMedium,
            AutoButtonColor=true,BackgroundColor3=Color3.fromRGB(25,31,43),BorderSizePixel=0,
            Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),ZIndex=42},parent)
        own("UICorner",{CornerRadius=UDim.new(0,9)},b);M:BindText(b,"Text")
        connect(b.Activated,function() M:Click();callback() end);return b
    end
    label("เอฟเฟกต์เมนู",22,15,305,28,20)
    label("ขนาดเมนูเดิม • เอฟเฟกต์ใช้ร่วมกันทุกตัว",22,46,356,30,11)
    button(panel,"×",352,14,30,30,function() panel.Visible=false end)
    for i,spec in ipairs({{"เปิดเอฟเฟกต์เมนู","motionEnabled"},{"ย่อรายการขณะเลื่อน","scrollMotionEnabled"},{"เอฟเฟกต์แตะ / ชี้ปุ่ม","pressMotionEnabled"}}) do
        local key=spec[2];local y=90+(i-1)*46;label(spec[1],22,y,255,34,13)
        local b=button(panel,"",292,y,86,34,function() M:Set(key,not M.Settings[key]) end)
        table.insert(M.Renderers,function()
            b.Text=M.Settings[key] and "เปิด" or "ปิด"
            b.BackgroundColor3=M.Settings[key] and Color3.fromRGB(49,73,94) or Color3.fromRGB(25,31,43)
        end)
    end
    local state=label("",22,232,356,50,11)
    table.insert(M.Renderers,function()
        state.Text=Motion.Reduced and "Roblox เปิดลดการเคลื่อนไหวอยู่ • พักเอฟเฟกต์" or "ปรับได้ทันที • รองรับเมาส์และการสัมผัส"
    end)
    local function layoutPanel()
        local camera=workspace.CurrentCamera;local size=camera and camera.ViewportSize or Vector2.new(800,600)
        panelScale.Scale=math.min(1,math.max(0.2,(size.X-22)/400),math.max(0.2,(size.Y-64)/310))
    end
    local launcher=button(M.Gui,"SX • FX",0,0,76,36,function()
        layoutPanel()
        panel.Visible=not panel.Visible
        local other=M.Gui:FindFirstChild("Settings");if panel.Visible and other then other.Visible=false end
        M:Refresh()
    end)
    launcher.Name="SATURN_X_MotionLauncher";launcher.AnchorPoint=Vector2.new(1,0);launcher.Position=UDim2.new(1,-12,0,96)
    local panelTimer=0
    connect(RunService.Heartbeat,function(dt)
        panelTimer=panelTimer+dt;if panelTimer<0.25 then return end;panelTimer=0
        if not panel.Visible then return end
        layoutPanel()
    end)
    local baseOpen=M.OpenSettings
    function M:OpenSettings(show) panel.Visible=false;return baseOpen(self,show) end
    function Motion:Destroy()
        if not self.Alive then return end;self.Alive=false;disconnect(self.Connections)
        local roots={};for _,c in pairs(self.Roots) do table.insert(roots,c) end
        for _,c in ipairs(roots) do c:Destroy(true) end
        self.Pending={};self.Dirty={};panel:Destroy();launcher:Destroy()
    end
    local baseDestroy=M.Destroy
    function M:Destroy() Motion:Destroy();return baseDestroy(self) end
    for root in pairs(M.WatchRoots) do if root:IsA("ScreenGui") and root~=M.Gui then Motion:Bind(root) end end
    M:Refresh()
    return Motion
end
return InstallMotion
end)()
local InstallOrbit = (function()
-- SATURN X Orbit 1.2.0 / BM
-- UI-only extension. The original eight pages and their handlers stay in place.
local function InstallOrbit(M)
    if M.Orbit and M.Orbit.Alive and M.Orbit.Version=="1.2.0" then return M.Orbit end
    local previous=M.Orbit
    local upgrades={}
    if previous and previous.Alive then
        for _,controller in pairs(previous.Controllers or {}) do
            if controller.Alive then
                table.insert(upgrades,{Legacy=controller,Options=controller.Options,State=controller.State,Selected=controller.Selected})
            end
        end
        previous:Destroy()
    end
    local RunService=game:GetService("RunService")
    local TweenService=game:GetService("TweenService")
    local UIS=game:GetService("UserInputService")
    local Orbit={Version="1.2.0",Alive=true,Controllers={},Assets=previous and previous.Assets or {},Jobs={},
        AnimationFrames=20,AnimationFPS=60}
    local frameDuration=Orbit.AnimationFrames/Orbit.AnimationFPS
    M.Orbit=Orbit;M.Build="1.4.0-orbit"
    local function moving()
        return M.Settings.motionEnabled~=false and not (M.Motion and M.Motion.Reduced)
    end
    local strings={
        choose={th="แตะดาวเพื่อเลือกหมวด",en="Tap a planet to explore",zh="轻点行星查看分类"},
        again={th="แตะดาวเดิมอีกครั้งเพื่อเปิด",en="Tap this planet again to open",zh="再次轻点此行星打开"},
        back={th="แตะโลโก้เพื่อล้างการเลือก",en="Tap the logo to clear selection",zh="轻点标志取消选择"},
        collapse={th="ย่อเมนู",en="Collapse",zh="收起"},
        ready={th="8 หมวด • SATURN X",en="8 categories • SATURN X",zh="8 个分类 • SATURN X"},
        fallback={th="ใช้ไอคอนสำรอง • ภาพยังไม่พร้อม",en="Using fallback icons",zh="正在使用备用图标"},
        default={th="ดูตัวเลือกของหมวดนี้",en="Explore this category",zh="查看此分类的选项"},
    }
    local details={
        ["อัปเดตแรก"]={th="ข่าวและการเปลี่ยนแปลงของสคริปต์",en="What's new in this script",zh="脚本更新与改动"},
        ["เครดิตผู้สร้าง"]={th="ผู้สร้างและเครดิต • BM",en="Creator and credits • BM",zh="作者与制作名单 • BM"},
        ["โปรไฟล์ผู้เล่น"]={th="ข้อมูลตัวละครและผู้เล่นของคุณ",en="Your player and character info",zh="你的玩家与角色信息"},
        ["ดึงของ"]={th="ตัวเลือกจัดการไอเท็ม",en="Item interaction options",zh="物品交互选项"},
        ["ค้นหาไอเท็ม"]={th="ค้นหาและเลือกไอเท็ม",en="Find and select items",zh="查找和选择物品"},
        ["บิน"]={th="ตัวเลือกการบินและการควบคุม",en="Flight options and controls",zh="飞行选项与控制"},
        ["เคลื่อนที่"]={th="ปรับตัวเลือกการเคลื่อนที่",en="Adjust movement options",zh="调整移动选项"},
        ["จุดบันทึก"]={th="จัดการตำแหน่งที่บันทึกไว้",en="Manage saved locations",zh="管理已保存的位置"},
        ["ภาพ / ตั้งค่า"]={th="ตัวเลือกการแสดงผลและตั้งค่า",en="Visual options and settings",zh="显示选项与设置"},
        ["ภาพ / กล้อง"]={th="ปรับภาพและตัวเลือกกล้อง",en="Visual and camera options",zh="显示与相机选项"},
        ["ตั้งค่า"]={th="ภาษา เสียง และตัวเลือกของเมนู",en="Language, audio and menu options",zh="语言、声音与菜单选项"},
        ["แต่งตัว"]={th="ค้นหาชื่อและดูตัวเลือกชุด",en="Search usernames and outfits",zh="搜索用户名与装扮"},
        ["รายชื่อล่าสุด"]={th="ดูรายชื่อที่ใช้ล่าสุด",en="Browse recent usernames",zh="查看最近的用户名"},
        ["แมว / จุดกด"]={th="ตัวเลือกแมวและจุดโต้ตอบ",en="Cats and interaction points",zh="猫咪与交互点"},
        ["ผู้เล่น / บทบาท"]={th="ข้อมูลผู้เล่นและบทบาท",en="Players and role information",zh="玩家与角色信息"},
        ["เหรียญ / ปืนตก"]={th="ตัวเลือกเหรียญและปืนที่ตก",en="Coins and dropped weapons",zh="金币与掉落武器"},
        ["จุด / กล้อง"]={th="ตำแหน่งและตัวเลือกกล้อง",en="Locations and camera options",zh="位置与相机选项"},
        ["ช่วยเล็ง"]={th="ตัวเลือกการช่วยเล็ง",en="Aim assistance options",zh="瞄准辅助选项"},
        ["ผู้เล่น / บอท"]={th="ข้อมูลผู้เล่นและบอท",en="Player and bot information",zh="玩家与机器人信息"},
        ["เป้า / กล้อง"]={th="ตัวเลือกเป้าและกล้อง",en="Crosshair and camera options",zh="准星与相机选项"},
        ["ประตู / ไอเท็ม"]={th="ตัวเลือกประตูและไอเท็ม",en="Doors and item options",zh="门与物品选项"},
        ["ศัตรู / แจ้งเตือน"]={th="ข้อมูลศัตรูและการแจ้งเตือน",en="Enemies and alerts",zh="敌人与提示"},
        ["เก็บของ / โต้ตอบ"]={th="ตัวเลือกเก็บของและโต้ตอบ",en="Collection and interaction options",zh="拾取与交互选项"},
        ["ช่วยตกปลา"]={th="ตัวเลือกการช่วยตกปลา",en="Fishing assistance options",zh="钓鱼辅助选项"},
        ["โซน / สำรวจ"]={th="ดูโซนและตัวเลือกสำรวจ",en="Zones and exploration options",zh="区域与探索选项"},
        ["ใส่รหัส / เล่นท่า"]={th="ใส่รหัสและเลือกท่าแอนิเมชัน",en="Enter IDs and choose animations",zh="输入编号并选择动作"},
        ["ท่าโปรด"]={th="จัดการท่าที่บันทึกไว้",en="Manage saved animations",zh="管理收藏的动作"},
        ["ปรับการเล่น"]={th="ปรับตัวเลือกการเล่นแอนิเมชัน",en="Animation playback options",zh="动作播放选项"},
        ["ท่าในตัวละคร"]={th="ดูแอนิเมชันของตัวละคร",en="Browse character animations",zh="查看角色动作"},
        ["เสียง / ตั้งค่า"]={th="ภาษา เสียง และตัวเลือกของเมนู",en="Language, audio and menu options",zh="语言、声音与菜单选项"},
        ["ไอเท็ม / ดึงของ"]={th="ตัวเลือกไอเท็มและการโต้ตอบ",en="Items and interaction options",zh="物品与交互选项"},
        ["ผู้เล่น / NPC"]={th="ข้อมูลผู้เล่นและ NPC",en="Players and NPC information",zh="玩家与 NPC 信息"},
    }
    local function tr(row) return row[M.Settings.language] or row.th end
    local function own(class,props,parent)
        local o=Instance.new(class)
        o:SetAttribute("SATURN_X_NoMotion",true)
        o:SetAttribute("SATURN_X_NoTranslate",true)
        for k,v in pairs(props) do o[k]=v end
        o.Parent=parent;return o
    end
    local function round(o) own("UICorner",{CornerRadius=UDim.new(1,0)},o) end
    local silver=Color3.fromRGB(219,229,244)
    local muted=Color3.fromRGB(156,172,195)
    local colors={Color3.fromRGB(197,211,229),Color3.fromRGB(220,153,105),Color3.fromRGB(130,215,235),
        Color3.fromRGB(106,196,156),Color3.fromRGB(230,183,101),Color3.fromRGB(179,149,227),
        Color3.fromRGB(105,158,222),Color3.fromRGB(224,220,201)}
    local specs={
        atlas={remote="SATURN_X_orbit_atlas_v1.png",size=2411469,kind="png"},
        wave={remote="SATURN_X_orbit_wave_v1.wav",size=70604,kind="wav"},
    }
    local function valid(data,spec)
        if type(data)~="string" or #data~=spec.size then return false end
        if spec.kind=="png" then return data:sub(1,8)=="\137PNG\r\n\26\n" end
        return data:sub(1,4)=="RIFF" and data:sub(9,12)=="WAVE"
    end
    function Orbit:Asset(kind,callback)
        if self.Assets[kind] then callback(self.Assets[kind]);return end
        if self.Jobs[kind] then table.insert(self.Jobs[kind],callback);return end
        self.Jobs[kind]={callback}
        task.spawn(function()
            local ok,id=pcall(function()
                local register=type(getcustomasset)=="function" and getcustomasset or
                    (type(getsynasset)=="function" and getsynasset)
                assert(register and type(writefile)=="function","local assets unavailable")
                local spec=assert(specs[kind]);local path="SATURN_X_media_"..spec.remote
                local data
                if type(readfile)=="function" then
                    local readOK,value=pcall(readfile,path)
                    if readOK and valid(value,spec) then data=value end
                end
                if not data then
                    data=game:HttpGet("https://raw.githubusercontent.com/jrjhdjio/SATURN-X/main/assets/"..spec.remote)
                    assert(valid(data,spec),"invalid orbit asset");writefile(path,data)
                end
                local result=register(path);assert(type(result)=="string" and result~="","invalid local asset")
                return result
            end)
            local jobs=self.Jobs[kind] or {};self.Jobs[kind]=nil
            if not self.Alive or not M.Alive then return end
            if ok then self.Assets[kind]=id end
            for _,fn in ipairs(jobs) do pcall(fn,ok and id or nil) end
        end)
    end
    function Orbit:Create(options)
        assert(self.Alive and #options.Names==8,"Orbit needs eight existing categories")
        if self.Controllers[options.Gui] then return self.Controllers[options.Gui] end
        local C={Alive=true,State="closed",Selected=nil,Serial=0,Connections={},Tweens={},FrameAnimations={},
            Options=options,Planets={},Rings={},Sprites={},Angle=0,Hover={},Pointers={}}
        self.Controllers[options.Gui]=C
        -- The orbit is the category picker. Show only the chosen page inside
        -- the original window, using the space previously occupied by its tabs.
        local sidebar=options.Window:FindFirstChild("Categories")
        local content=options.Window:FindFirstChild("Content")
        local savedSidebar=sidebar and sidebar.Visible
        local savedPosition=content and content.Position
        local savedSize=content and content.Size
        if sidebar then sidebar.Visible=false end
        if content then
            content.Position=UDim2.new(0,14,savedPosition.Y.Scale,savedPosition.Y.Offset)
            content.Size=UDim2.new(1,-28,savedSize.Y.Scale,savedSize.Y.Offset)
        end
        local function connect(signal,fn)
            local c=signal:Connect(fn);table.insert(C.Connections,c);return c
        end
        local function animate(o,props,duration,easing)
            if C.Tweens[o] then C.Tweens[o]:Cancel();C.Tweens[o]=nil end
            if not C.Alive or not o.Parent then return end
            if not moving() or duration==0 then for k,v in pairs(props) do o[k]=v end;return end
            local t=TweenService:Create(o,TweenInfo.new(duration or .2,easing or Enum.EasingStyle.Quad,Enum.EasingDirection.Out),props)
            C.Tweens[o]=t;t:Play()
        end
        -- Twenty sampled poses, advanced by elapsed time on one shared heartbeat.
        -- A slow client skips overdue poses instead of stretching or queueing them.
        local function animate20(o,props,easing)
            if C.Tweens[o] then C.Tweens[o]:Cancel();C.Tweens[o]=nil end
            if not C.Alive or not o.Parent then return end
            if not moving() then for k,v in pairs(props) do o[k]=v end;return end
            local t={Elapsed=0,Frame=1,Samples={},Target=props}
            for frame=1,Orbit.AnimationFrames do
                local alpha=TweenService:GetValue((frame-1)/(Orbit.AnimationFrames-1),easing or Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
                local pose={}
                for key,target in pairs(props) do
                    local start=o[key]
                    pose[key]=type(start)=="number" and (start+(target-start)*alpha) or start:Lerp(target,alpha)
                end
                t.Samples[frame]=pose
            end
            function t:Cancel()
                if C.FrameAnimations[o]==self then C.FrameAnimations[o]=nil end
                if C.Tweens[o]==self then C.Tweens[o]=nil end
            end
            C.FrameAnimations[o]=t;C.Tweens[o]=t
            for key,value in pairs(t.Samples[1]) do o[key]=value end
        end
        connect(RunService.Heartbeat,function(dt)
            for o,t in pairs(C.FrameAnimations) do
                if not o.Parent then t:Cancel()
                else
                    t.Elapsed=t.Elapsed+math.max(0,dt)
                    local frame=not moving() and Orbit.AnimationFrames or
                        math.min(Orbit.AnimationFrames,math.floor(t.Elapsed*Orbit.AnimationFPS+1e-6)+1)
                    if frame~=t.Frame then
                        t.Frame=frame
                        for key,value in pairs(t.Samples[frame]) do o[key]=value end
                    end
                    if not moving() or t.Elapsed+1e-6>=frameDuration then
                        for key,value in pairs(t.Target) do o[key]=value end
                        t:Cancel()
                    end
                end
            end
        end)
        function C:Cancel()
            self.Serial=self.Serial+1
            for o,t in pairs(self.Tweens) do t:Cancel();self.Tweens[o]=nil end
            self.Pointers={};self.Hover={}
            return self.Serial
        end
        local function later(serial,seconds,fn)
            if not moving() then fn();return end
            task.delay(seconds,function() if C.Alive and C.Serial==serial then fn() end end)
        end
        -- Animate page content independently of the window's responsive UIScale.
        local pagePosition=content and content.Position
        local pageScale=content and not content:FindFirstChildOfClass("UIScale") and
            own("UIScale",{Name="OrbitPageScale",Scale=1},content) or nil
        local function resetPage()
            if content and content.Parent then content.Position=pagePosition end
            if pageScale and pageScale.Parent then pageScale.Scale=1 end
            options.Window.GroupTransparency=0
        end
        local function revealPage()
            resetPage()
            if not moving() then return end
            options.Window.GroupTransparency=1
            if content and content.Parent then
                content.Position=UDim2.new(pagePosition.X.Scale,pagePosition.X.Offset,pagePosition.Y.Scale,pagePosition.Y.Offset+12)
                animate20(content,{Position=pagePosition},Enum.EasingStyle.Quint)
            end
            if pageScale then pageScale.Scale=.965;animate20(pageScale,{Scale=1},Enum.EasingStyle.Quint) end
            animate20(options.Window,{GroupTransparency=0})
        end
        local function planetScale(index)
            if not moving() then return 1 end
            if C.Selected==index then return 1.10 end
            local p=C.Planets[index]
            return p and C.Hover[p.Button] and 1.05 or 1
        end
        local stage=own("Frame",{Name="SATURN_X_Orbit",BackgroundTransparency=1,AnchorPoint=Vector2.new(.5,.5),
            Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(600,600),Visible=false,ZIndex=20},options.Root)
        C.Stage=stage
        local fit=own("UIScale",{Scale=1},stage);C.Fit=fit
        local disk=own("CanvasGroup",{Name="OrbitalMenu",BackgroundTransparency=1,AnchorPoint=Vector2.new(.5,.5),
            Position=UDim2.fromScale(.5,.5),Size=UDim2.fromScale(1,1),GroupTransparency=0,ZIndex=20},stage)
        local diskScale=own("UIScale",{Scale=1},disk)
        local backdrop=own("Frame",{BackgroundColor3=Color3.fromRGB(8,12,21),BackgroundTransparency=.08,
            Position=UDim2.fromOffset(10,10),Size=UDim2.fromOffset(580,580),BorderSizePixel=0,ZIndex=1},disk)
        round(backdrop)
        own("UIStroke",{Color=Color3.fromRGB(77,95,121),Transparency=.5,Thickness=1},backdrop)
        own("UIGradient",{Rotation=60,Color=ColorSequence.new(Color3.fromRGB(25,37,57),Color3.fromRGB(4,6,12))},backdrop)
        for i=1,28 do
            local a=i*2.399963;local r=110+(i*37%169)
            local dot=own("Frame",{BackgroundColor3=silver,BackgroundTransparency=.60+(i%3)*.1,BorderSizePixel=0,
                Position=UDim2.fromOffset(300+math.cos(a)*r,300+math.sin(a)*r),Size=UDim2.fromOffset(i%5==0 and 3 or 2,2),ZIndex=2},disk)
            round(dot)
        end
        local function text(parent,name,x,y,w,h,size,color)
            return own("TextLabel",{Name=name,Text="",BackgroundTransparency=1,Position=UDim2.fromOffset(x,y),
                Size=UDim2.fromOffset(w,h),Font=Enum.Font.GothamMedium,TextSize=size,TextColor3=color or silver,
                TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Center,TextYAlignment=Enum.TextYAlignment.Center,ZIndex=6},parent)
        end
        local function sprite(parent,index,size)
            local col=(index-1)%4;local row=math.floor((index-1)/4)
            -- Crop in UI space, not texture pixels. Local textures can be resampled
            -- before rendering; fixed ImageRect coordinates then select adjacent cells.
            -- A 4 x 3 atlas at 1536 x 1024 has cells with aspect ratio 9:8.
            local clip=own("Frame",{Name="OrbitClip"..index,BackgroundTransparency=1,BorderSizePixel=0,
                AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),
                Size=UDim2.fromOffset(size,size*8/9),ClipsDescendants=true,ZIndex=7},parent)
            local icon=own("ImageLabel",{Name="OrbitSprite"..index,Image="",BackgroundTransparency=1,
                AnchorPoint=Vector2.new(0,0),Position=UDim2.fromScale(-col,-row),Size=UDim2.fromScale(4,3),
                ImageRectOffset=Vector2.new(0,0),ImageRectSize=Vector2.new(0,0),
                ScaleType=Enum.ScaleType.Stretch,ZIndex=7},clip)
            table.insert(C.Sprites,icon);return icon,clip
        end
        local core=own("TextButton",{Name="CenterLogo",Text="",AutoButtonColor=false,BackgroundColor3=Color3.fromRGB(13,19,30),
            BackgroundTransparency=.08,BorderSizePixel=0,Position=UDim2.fromOffset(184,184),Size=UDim2.fromOffset(232,232),ZIndex=5},disk)
        round(core);own("UIStroke",{Color=silver,Transparency=.72,Thickness=1},core)
        local centerLogo=own("ImageLabel",{Name="OriginalSaturnLogo",Image="",BackgroundTransparency=1,ScaleType=Enum.ScaleType.Fit,
            AnchorPoint=Vector2.new(.5,0),Position=UDim2.fromOffset(116,4),Size=UDim2.fromOffset(132,74),ZIndex=6},core)
        local logoFallback=text(core,"LogoFallback",44,10,144,65,30);logoFallback.Text="SATURN X"
        local heading=text(core,"CategoryTitle",10,80,212,44,22)
        local description=text(core,"CategoryDetail",12,126,208,48,17,muted)
        local hint=text(core,"Instructions",12,178,208,42,18)
        local status=text(disk,"AssetStatus",117,554,366,24,13,muted)
        local badge=text(disk,"Brand",182,32,236,24,15,muted);badge.Text="SATURN X  /  ORBIT"
        for i=1,8 do
            local radius=160+(i-1)*10
            local ring=own("Frame",{Name="OrbitRing"..i,BackgroundTransparency=1,AnchorPoint=Vector2.new(.5,.5),
                Position=UDim2.fromOffset(300,300),Size=UDim2.fromOffset(radius*2,radius*2),ZIndex=3},disk)
            round(ring)
            local line=own("UIStroke",{Color=colors[i],Transparency=.80,Thickness=1},ring)
            C.Rings[i]={Object=ring,Stroke=line,Scale=own("UIScale",{Scale=1},ring)}
            local b=own("TextButton",{Name="Planet"..i,Text="",AutoButtonColor=false,BackgroundTransparency=1,
                AnchorPoint=Vector2.new(.5,.5),Size=UDim2.fromOffset(84,84),ZIndex=10},disk)
            local scale=own("UIScale",{Scale=1},b)
            local fallback=own("Frame",{Name="FallbackPlanet",BackgroundColor3=colors[i],BackgroundTransparency=.2,
                AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(49,49),BorderSizePixel=0,ZIndex=6},b)
            round(fallback)
            own("UIGradient",{Rotation=45,Color=ColorSequence.new(Color3.fromRGB(255,255,255),Color3.fromRGB(35,43,60))},fallback)
            local art=sprite(b,i,104)
            local number=text(b,"CategoryNumber",24,64,36,20,15);number.Text=string.format("%02d",i)
            local outline=own("Frame",{Name="SelectedRing",BackgroundTransparency=1,AnchorPoint=Vector2.new(.5,.5),
                Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(64,64),ZIndex=8},b)
            round(outline)
            local lineSelected=own("UIStroke",{Color=colors[i],Transparency=1,Thickness=2},outline)
            local ripple=own("Frame",{Name="RingWave",BackgroundTransparency=1,AnchorPoint=Vector2.new(.5,.5),
                Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(50,50),ZIndex=8},b)
            round(ripple)
            local rippleLine=own("UIStroke",{Color=colors[i],Transparency=1,Thickness=2},ripple)
            C.Planets[i]={Button=b,Scale=scale,Fallback=fallback,Image=art,Outline=lineSelected,Ripple=ripple,RippleLine=rippleLine,Radius=radius}
            connect(b.Activated,function() C:Tap(i) end)
            connect(b.MouseEnter,function() C.Hover[b]=true;animate(scale,{Scale=planetScale(i)},.18) end)
            connect(b.MouseLeave,function() C.Hover[b]=nil;animate(scale,{Scale=planetScale(i)},.18) end)
            connect(b.SelectionGained,function() C.Hover[b]=true;animate(scale,{Scale=planetScale(i)},.18) end)
            connect(b.SelectionLost,function() C.Hover[b]=nil;animate(scale,{Scale=planetScale(i)},.18) end)
            connect(b.InputBegan,function(input)
                if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
                    C.Pointers[input]=true
                    if M.Settings.pressMotionEnabled~=false then animate(scale,{Scale=.96},.08) end
                end
            end)
        end
        local black=own("TextButton",{Name="BlackHoleCollapse",Text="",AutoButtonColor=false,BackgroundTransparency=1,
            Position=UDim2.fromOffset(506,10),Size=UDim2.fromOffset(84,84),ZIndex=11},disk)
        local blackFallback=text(black,"Fallback",12,5,60,60,38);blackFallback.Text="◉"
        sprite(black,9,104)
        local collapseLabel=text(black,"CollapseLabel",-10,66,104,22,14)
        connect(black.Activated,function() C:SetOpen(false) end)
        local portal=own("Frame",{Name="Portal",BackgroundTransparency=1,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromOffset(300,300),
            Size=UDim2.fromOffset(220,220),Visible=false,ZIndex=30},stage)
        local portalFallback=own("Frame",{BackgroundColor3=silver,BackgroundTransparency=.35,AnchorPoint=Vector2.new(.5,.5),
            Position=UDim2.fromScale(.5,.5),Size=UDim2.fromScale(.38,.38),BorderSizePixel=0,ZIndex=1},portal)
        round(portalFallback)
        local portalArt=sprite(portal,10,260)
        local portalScale=own("UIScale",{Scale=1},portal)
        -- The existing header logo is a return control; window dimensions stay intact.
        local returnButton=own("TextButton",{Name="ReturnToOrbit",Text="",AutoButtonColor=false,BackgroundTransparency=1,
            Size=UDim2.fromScale(1,1),ZIndex=options.Logo.ZIndex+4},options.Logo)
        local returnBadge=text(returnButton,"OrbitBadge",28,28,18,18,15);returnBadge.Text="↶"
        connect(returnButton.Activated,function() C:Open(true) end)
        local minText=options.Minimize.Text
        options.Minimize.Text=""
        local miniArt,miniClip=sprite(options.Minimize,9,48)
        local miniFallback=text(options.Minimize,"BlackHoleFallback",0,0,36,36,21);miniFallback.Text="◉"
        C.ReturnButton=returnButton;C.MiniArt=miniArt;C.MiniClip=miniClip;C.MiniFallback=miniFallback
        local function layout()
            local available=options.Root.AbsoluteSize
            if available.X>0 and available.Y>0 then fit.Scale=math.min(1,(available.X-16)/600,(available.Y-16)/600) end
        end
        function C:PositionPlanets()
            for i,p in ipairs(self.Planets) do
                local angle=self.Angle+(i-1)*math.pi/4-math.pi/2
                p.Button.Position=UDim2.fromOffset(300+math.cos(angle)*p.Radius,300+math.sin(angle)*p.Radius)
            end
        end
        function C:Refresh()
            if not self.Alive then return end
            local selected=self.Selected
            heading.Text=selected and M:T(options.Names[selected]) or "SATURN X"
            description.Text=selected and tr(details[options.Names[selected]] or strings.default) or tr(strings.ready)
            hint.Text=tr(selected and strings.again or strings.choose)
            core:SetAttribute("ActionHint",tr(strings.back))
            status.Text=self.AtlasFailed and tr(strings.fallback) or ""
            collapseLabel.Text=tr(strings.collapse)
            for i,p in ipairs(self.Planets) do
                p.Button:SetAttribute("CategoryTitle",M:T(options.Names[i]))
                p.Button:SetAttribute("CategoryDetail",tr(details[options.Names[i]] or strings.default))
                p.Outline.Transparency=i==selected and .12 or 1
                C.Rings[i].Stroke.Transparency=i==selected and .42 or .80
                if self.State=="orbit" then animate20(p.Scale,{Scale=planetScale(i)},Enum.EasingStyle.Back) end
                if not moving() then p.Scale.Scale=1;p.RippleLine.Transparency=1 end
            end
            if not moving() and self.State=="category" then
                for _,o in ipairs({options.Window,content,pageScale}) do
                    if C.Tweens[o] then C.Tweens[o]:Cancel();C.Tweens[o]=nil end
                end
                resetPage()
            end
        end
        local function wave(index)
            M:Click()
            if Orbit.Wave then M:PlayEffect(Orbit.Wave) end
            local p=C.Planets[index]
            if not moving() then return end
            if C.Tweens[p.Ripple] then C.Tweens[p.Ripple]:Cancel() end
            if C.Tweens[p.RippleLine] then C.Tweens[p.RippleLine]:Cancel() end
            p.Ripple.Size=UDim2.fromOffset(45,45);p.RippleLine.Transparency=.12
            animate20(p.Ripple,{Size=UDim2.fromOffset(112,112)})
            animate20(p.RippleLine,{Transparency=1})
            if C.Tweens[p.Scale] then C.Tweens[p.Scale]:Cancel() end
            p.Scale.Scale=.94
            animate20(p.Scale,{Scale=planetScale(index)},Enum.EasingStyle.Back)
        end
        function C:Tap(index)
            if not self.Alive or self.State~="orbit" or not self.Planets[index] then return end
            wave(index)
            if self.Selected~=index then self.Selected=index;self:Refresh();return end
            self:Cancel();self.State="category";stage.Visible=false;portal.Visible=false
            options.OnSelect(index)
            options.Window.Visible=true;options.Window.GroupTransparency=0;options.Floating.Visible=false
            revealPage()
            options.OnVisible(true);options.PlayWindow()
        end
        function C:Open(sound)
            if not self.Alive then return end
            local serial=self:Cancel();self.State="opening";self.Selected=nil
            resetPage()
            options.OnVisible(true);options.Window.Visible=false;options.Window.GroupTransparency=0;options.Floating.Visible=false
            stage.Visible=true;disk.Visible=true;disk.GroupTransparency=moving() and 1 or 0;diskScale.Scale=moving() and .82 or 1
            portal.Visible=moving();portalScale.Scale=.3;portalArt.ImageTransparency=0
            portalArt.Position=UDim2.fromScale(-1,-2)
            portalFallback.BackgroundColor3=silver;portalFallback.BackgroundTransparency=.35
            self:Refresh();layout();self:PositionPlanets()
            for i,r in ipairs(self.Rings) do
                r.Scale.Scale=moving() and .3 or 1;r.Stroke.Transparency=moving() and 1 or .80
                later(serial,.12+i*.035,function() animate20(r.Scale,{Scale=1});animate20(r.Stroke,{Transparency=.80}) end)
            end
            for i,p in ipairs(self.Planets) do
                p.Scale.Scale=moving() and .55 or 1
                later(serial,.10+i*.025,function() animate20(p.Scale,{Scale=1},Enum.EasingStyle.Back) end)
            end
            if sound then options.PlayWindow() end
            animate20(portalScale,{Scale=1.45})
            later(serial,.12,function() animate20(disk,{GroupTransparency=0});animate20(diskScale,{Scale=1},Enum.EasingStyle.Quint) end)
            later(serial,.24,function() animate20(portalArt,{ImageTransparency=1});animate20(portalFallback,{BackgroundTransparency=1}) end)
            later(serial,.40+frameDuration,function() portal.Visible=false;self.State="orbit" end)
        end
        function C:SetOpen(value)
            if not self.Alive then return end
            if value then self:Open(true);return end
            if self.State=="closed" or self.State=="collapsing" then return end
            local fromPage=self.State=="category" and options.Window.Visible
            local serial=self:Cancel();self.State="collapsing";self.Selected=nil
            options.OnVisible(false);options.Floating.Visible=true;options.PlayWindow()
            if fromPage and moving() then
                animate20(options.Window,{GroupTransparency=1})
                if pageScale then animate20(pageScale,{Scale=.965},Enum.EasingStyle.Quint) end
                later(serial,frameDuration,function() options.Window.Visible=false;resetPage() end)
            else options.Window.Visible=false;resetPage() end
            stage.Visible=true;disk.Visible=not fromPage;portal.Visible=moving()
            portalArt.Position=UDim2.fromScale(0,-2)
            portalArt.ImageTransparency=0;portalScale.Scale=1.1
            portalFallback.BackgroundColor3=Color3.fromRGB(0,0,0);portalFallback.BackgroundTransparency=0
            animate20(diskScale,{Scale=.08});animate20(disk,{GroupTransparency=1})
            animate20(portalScale,{Scale=.05});animate20(portalArt,{ImageTransparency=1})
            later(serial,frameDuration,function() stage.Visible=false;portal.Visible=false;self.State="closed" end)
        end
        connect(core.Activated,function()
            if C.State=="orbit" and C.Selected then C.Selected=nil;C:Refresh();M:Click() end
        end)
        connect(UIS.InputEnded,function(input)
            if C.Pointers[input] then
                C.Pointers[input]=nil
                for i,p in ipairs(C.Planets) do animate(p.Scale,{Scale=planetScale(i)},.22,Enum.EasingStyle.Back) end
            end
        end)
        connect(UIS.WindowFocusReleased,function()
            C.Pointers={};C.Hover={};C.Focused=false
            for _,p in ipairs(C.Planets) do p.Scale.Scale=1 end
        end)
        connect(UIS.WindowFocused,function() C.Focused=true end)
        local elapsed=0
        connect(RunService.Heartbeat,function(dt)
            if not C.Alive or C.State~="orbit" or C.Selected or C.Focused==false or not moving() or next(C.Hover) or next(C.Pointers) then return end
            elapsed=elapsed+dt;if elapsed<1/30 then return end
            C.Angle=(C.Angle+math.min(elapsed,.1)*.014)%(math.pi*2);elapsed=0;C:PositionPlanets()
        end)
        connect(options.Root:GetPropertyChangedSignal("AbsoluteSize"),layout)
        function C:Destroy()
            if not self.Alive then return end
            self:Cancel();self.Alive=false;Orbit.Controllers[options.Gui]=nil
            for _,c in ipairs(self.Connections) do c:Disconnect() end;self.Connections={}
            stage:Destroy();returnButton:Destroy();miniClip:Destroy();miniFallback:Destroy()
            resetPage();if pageScale then pageScale:Destroy() end
            if options.Minimize.Parent then options.Minimize.Text=minText end
            if sidebar and sidebar.Parent then sidebar.Visible=savedSidebar end
            if content and content.Parent then content.Position=savedPosition;content.Size=savedSize end
        end
        connect(options.Gui.Destroying,function() C:Destroy() end)
        M:Asset("logo",function(id)
            if C.Alive and id then centerLogo.Image=id;logoFallback.Visible=false end
        end)
        self:Asset("atlas",function(id)
            if not C.Alive then return end
            C.AtlasFailed=not id
            if id then
                for _,icon in ipairs(C.Sprites) do icon.Image=id end
                -- Registration follows byte/signature validation. IsLoaded can stay
                -- false for local runtime URIs even while the image is visible.
                -- Never draw placeholders underneath successfully assigned artwork.
                for _,p in ipairs(C.Planets) do p.Fallback.Visible=false end
                blackFallback.Visible=false;miniFallback.Visible=false;portalFallback.Visible=false
            end
            C:Refresh()
        end)
        C:PositionPlanets();C:Refresh();layout()
        return C
    end
    local baseRefresh=M.Refresh
    function M:Refresh()
        baseRefresh(self)
        for _,controller in pairs(Orbit.Controllers) do controller:Refresh() end
    end
    function Orbit:Destroy()
        if not self.Alive then return end;self.Alive=false
        local all={};for _,c in pairs(self.Controllers) do table.insert(all,c) end
        for _,c in ipairs(all) do c:Destroy() end
        self.Jobs={};if self.Wave then self.Wave:Destroy() end
    end
    local baseDestroy=M.Destroy
    function M:Destroy() Orbit:Destroy();return baseDestroy(self) end
    Orbit:Asset("wave",function(id)
        if id and Orbit.Alive then Orbit.Wave=own("Sound",{Name="OrbitRingWave",SoundId=id,Volume=1,SoundGroup=M.EffectsGroup},M.Audio) end
    end)
    for _,entry in ipairs(upgrades) do
        local options=entry.Options
        if options and options.Gui.Parent and options.Window.Parent then
            local replacement=Orbit:Create(options)
            -- Existing entry scripts capture their controller in setOpen closures.
            -- Forward those handles so updating one script also repairs other live menus.
            entry.Legacy.SetOpen=function(_,value) return replacement:SetOpen(value) end
            entry.Legacy.Open=function(_,sound) return replacement:Open(sound) end
            if entry.State=="category" then
                replacement.State="category";replacement.Selected=entry.Selected
                options.Window.Visible=true;options.Floating.Visible=false;options.OnVisible(true)
                replacement:Refresh()
            elseif entry.State=="closed" or entry.State=="collapsing" then
                options.Window.Visible=false;options.Floating.Visible=true;options.OnVisible(false)
            else replacement:Open(false) end
        end
    end
    return Orbit
end
return InstallOrbit
end)()
if type(existing) == "table" and existing.Version == "1.0.0" and existing.Alive then InstallMotion(existing);InstallOrbit(existing);return existing end
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer
local playerGui = player and player:FindFirstChildOfClass("PlayerGui")
assert(playerGui, "SATURN X media requires PlayerGui")

-- BEGIN_LOCALES
local translations = {
    ["โหลดโมเดลจริงก่อน แล้วกดขึ้นไปเดิน"]={en="Load the original model, then go up to explore",zh="先加载原始模型，再上去探索"},
    ["รูปทรงเดิมครบ • Texture ใบไม้ขาด 2 ภาพ"]={en="Original geometry • 2 leaf textures missing",zh="原始模型 • 缺少 2 张树叶贴图"},
    ["LOAD / โหลดโมเดลจริง"]={en="LOAD / Original model",zh="加载原始模型"},
    ["UP / ขึ้นไปเดิน"]={en="UP / Explore",zh="上去探索"},
    ["BACK / กลับจุดเดิม"]={en="BACK / Return",zh="返回原位"},
    ["ป่าเห็นเฉพาะเรา • ตัวละครอาจถูกคนอื่นเห็น"]={en="Forest is local • Others may see your character",zh="森林仅自己可见 • 他人可能看到你的角色"},
    ["กลับไม่ได้: "]={en="Cannot return: ",zh="无法返回： "},
    ["ยังไม่ได้ขึ้นไป หรือเกิดใหม่แล้ว"]={en="You have not gone up, or have respawned",zh="尚未上去，或角色已重生"},
    ["กลับจุดเดิมแล้ว"]={en="Returned to the starting point",zh="已返回原位"},
    ["โหลดรูปทรงจริง "]={en="Loading original geometry ",zh="正在加载原始模型 "},
    ["กำลังโหลดอยู่ครับ"]={en="Already loading",zh="正在加载中"},
    ["โหลดแล้ว กด UP เพื่อขึ้นไปเดิน"]={en="Loaded • Press UP to explore",zh="已加载 • 按“上去”探索"},
    ["รอตัวละครเกิดก่อนครับ"]={en="Wait for your character to spawn",zh="请等待角色生成"},
    ["โหลดโมเดลจริงไม่ได้: "]={en="Cannot load the original model: ",zh="无法加载原始模型： "},
    ["อาจติดสิทธิ์ Mesh API หรือหน่วยความจำ ดู Console"]={en="Mesh API permission or memory limit; check Console",zh="可能受网格权限或内存限制，请查看控制台"},
    ["รูปทรงเดิมครบ 36,702 สามเหลี่ยม • กด UP"]={en="All 36,702 original triangles • Press UP",zh="原始模型共 36,702 个三角面 • 按“上去”"},
    ["Texture โหลด "]={en="Textures loaded ",zh="已加载贴图 "},
    ["/5 • ไฟล์ใบไม้ขาด 2 ภาพ"]={en="/5 • 2 leaf texture files missing",zh="/5 • 缺少 2 张树叶贴图"},
    [" • บางภาพโหลดไม่ได้"]={en=" • Some textures failed",zh=" • 部分贴图加载失败"},
    ["ต้องโหลดโมเดลจริงให้สำเร็จก่อนขึ้นไป"]={en="Load the original model successfully before going up",zh="请先成功加载原始模型"},
    ["ออกจากที่นั่งก่อนขึ้นไปครับ"]={en="Leave your seat before going up",zh="请先离开座位"},
    ["ย้ายตัวละครไม่ได้: "]={en="Cannot move character: ",zh="无法移动角色： "},
    ["ขึ้นไปแล้ว ใช้ปุ่มเดินตามปกติ • BACK เพื่อกลับ"]={en="You are up • Move normally • BACK to return",zh="已到达 • 正常移动 • 按“返回”回原位"},
    ["เกมย้ายตัวกลับหรือออกจากป่าแล้ว ไม่มีการย้ายซ้ำ"]={en="The game moved you back or you left; no retry",zh="游戏将你移回或你已离开森林，不会重复移动"},
    ["ออกจากพื้นที่ป่าแล้ว เกมอาจย้ายตัวกลับ"]={en="Outside the forest; the game may have moved you back",zh="已离开森林范围，游戏可能将你移回"},
    ["กลับจุดเดิมแล้ว เพราะหลุดจากพื้นป่า"]={en="Returned after falling through the forest floor",zh="跌出森林地面，已返回原位"},
    ["ยังไม่ได้ใช้"]={en="Not used yet",zh="尚未使用"},
    ["รอถือเบ็ด"]={en="Waiting for a fishing rod",zh="等待装备鱼竿"},
    ["กำลังโหลด"]={en="Loading",zh="加载中"},
    ["BETA  •  ยังไม่ทดสอบในเกมจริง"]={en="BETA • Not tested in a live game",zh="测试版 • 尚未在实际游戏中测试"},
    ["อัปเดตแรก"]={en="First update",zh="首次更新"},
    ["เครดิตผู้สร้าง"]={en="Creator credits",zh="作者信息"},
    ["โปรไฟล์ผู้เล่น"]={en="Player profile",zh="玩家资料"},
    ["ช่วยตกปลา"]={en="Fishing helpers",zh="钓鱼辅助"},
    ["โซน / สำรวจ"]={en="Zones / Explore",zh="区域 / 探索"},
    ["เคลื่อนที่"]={en="Movement",zh="移动"},
    ["จุดบันทึก"]={en="Waypoints",zh="保存地点"},
    ["ภาพ / ตั้งค่า"]={en="Visuals / Settings",zh="画面 / 设置"},
    ["ทำรายการไม่ได้: "]={en="Action failed: ",zh="操作失败： "},
    ["เปิดฟีเจอร์ไม่ได้: "]={en="Cannot enable feature: ",zh="无法开启功能： "},
    ["แมพนี้ไม่ใช่ Fisch • เปิดได้เฉพาะเมนู"]={en="This is not Fisch • Menu only",zh="当前不是 Fisch • 仅能打开菜单"},
    ["รอให้ตัวละครเกิดก่อนครับ"]={en="Wait for your character to spawn",zh="请等待角色生成"},
    ["ลงจากที่นั่งก่อนเปิดบินครับ"]={en="Leave your seat before flying",zh="飞行前请先离开座位"},
    ["ดึงปลา"]={en="Reeling",zh="收线"},
    ["เขย่าเบ็ด"]={en="Shaking the rod",zh="摇动鱼竿"},
    ["รอปลากินเหยื่อ"]={en="Waiting for a bite",zh="等待鱼上钩"},
    ["พร้อมเหวี่ยงเบ็ด"]={en="Ready to cast",zh="可以抛竿"},
    ["ถือเบ็ดและยืนใกล้น้ำก่อนครับ"]={en="Equip a rod and stand near water",zh="请装备鱼竿并站在水边"},
    ["เบ็ดกำลังใช้งานอยู่ครับ"]={en="The rod is already in use",zh="鱼竿正在使用中"},
    ["ส่งคำขอเหวี่ยงแล้ว • ตรวจตำแหน่งทุ่นในเกม"]={en="Cast requested • Check the float in game",zh="已发送抛竿请求 • 请在游戏中查看浮漂"},
    ["ส่งคำขอเหวี่ยงไม่ได้"]={en="Cast request failed",zh="抛竿请求失败"},
    ["ปุ่ม Shake รุ่นนี้ไม่มีคำสั่งที่รองรับ"]={en="This Shake button has no supported action",zh="此摇竿按钮不支持当前操作"},
    ["ไม่รองรับการกดเมาส์จำลอง"]={en="Simulated mouse input unavailable",zh="不支持模拟鼠标输入"},
    ["ส่งการกด/ปล่อยได้"]={en="Press/release supported",zh="支持按下 / 松开"},
    ["runtime ไม่รองรับการกด/ปล่อย"]={en="This runtime cannot send press/release input",zh="当前运行环境不支持按下 / 松开输入"},
    ["รูปแบบหลอดไม่ตรง • หยุดช่วยดึง"]={en="Unrecognized reel bar • Helper stopped",zh="收线条格式不匹配 • 已停止辅助"},
    ["เครื่องนี้ส่งการกดช่วยดึงปลาไม่ได้ • ใช้มินิเกมของเกมได้ตามปกติ"]={en="Reel input unavailable • Use the normal game minigame",zh="无法发送收线输入 • 请使用游戏原有小游戏"},
    ["พบ %d โซนในรัศมี • ตรวจ %d วัตถุ%s\nระยะวัดถึงจุดกึ่งกลางโซน"]={en="Found %d zones • Checked %d objects%s\nDistance is measured to each zone center",zh="发现 %d 个区域 • 检查 %d 个对象%s\n距离按区域中心计算"},
    [" (บางส่วน)"]={en=" (partial)",zh=" （部分）"},
    ["ตกปลา"]={en="Fishing",zh="钓鱼"},
    ["พื้นที่"]={en="Area",zh="区域"},
    ["ไฟล์ไม่ตรงกับแมพนี้"]={en="This file belongs to a different map",zh="文件与当前地图不符"},
    ["รายการจุดไม่ถูกต้อง"]={en="Invalid waypoint list",zh="地点列表无效"},
    ["รายการจุดไม่ต่อเนื่อง"]={en="Waypoint list is not contiguous",zh="地点列表不连续"},
    ["ไฟล์มีจุดเกิน 8 จุด"]={en="File contains more than 8 waypoints",zh="文件中的地点超过 8 个"},
    ["ชื่อจุดไม่ถูกต้อง"]={en="Invalid waypoint name",zh="地点名称无效"},
    ["พิกัดไม่ถูกต้อง"]={en="Invalid coordinates",zh="坐标无效"},
    ["มุมไม่ถูกต้อง"]={en="Invalid angle",zh="角度无效"},
    ["8 หมวด • ดาวเสาร์สีเงิน • เสียงเปิด/ปิดและคลิก\nเมนูลากได้ รองรับจอมือถือ"]={en="8 tabs • Silver Saturn • Open/close and click sounds\nDraggable menu with mobile support",zh="8 个分类 • 银色土星 • 开关及点击音效\n可拖动菜单，支持手机"},
    ["• ช่วยเหวี่ยงเบ็ด / เขย่า / คุมหลอดดึงปลา\n• ป้ายโซนตกปลา พื้นที่ และผู้เล่น\n• ความเร็ว บิน และจุดบันทึก 8 จุด\n• โปรไฟล์จริง สถิติการใช้งาน และปรับภาพ"]={en="• Cast / shake / reel helpers\n• Fishing zones, areas and player labels\n• Speed, flight and 8 waypoints\n• Profile, session stats and visuals",zh="• 抛竿 / 摇竿 / 收线辅助\n• 钓鱼区、区域和玩家标记\n• 速度、飞行和 8 个保存地点\n• 玩家资料、使用统计和画面设置"},
    ["ถือเบ็ดและยืนใกล้น้ำ → เปิดตัวช่วยในหมวด 4 → ย่อเมนู\nระบบตกปลาพักเมื่อเปิดเมนูหรือสลับออกจากหน้าต่าง\nทุกสวิตช์เริ่มเป็นปิด หลังย้ายเซิร์ฟเวอร์ให้รันใหม่"]={en="Equip a rod near water → Enable helpers in tab 4 → Minimize\nFishing pauses while the menu is open or the window loses focus\nFeature switches start off; rerun after changing servers",zh="在水边装备鱼竿 → 分类 4 开启辅助 → 最小化\n菜单打开或切换窗口时暂停钓鱼\n功能默认关闭；更换服务器后重新运行"},
    ["รุ่นทดลอง ยังไม่ทดสอบในเกมจริง\nตัวช่วยดึงปลาใช้การกด/ปล่อยเมาส์ อาจไม่รองรับทุกเครื่อง\nจำนวนคำขอและรอบมินิเกมไม่ใช่จำนวนปลาที่จับสำเร็จ"]={en="Beta; not tested live\nReel assistance simulates mouse input and may not work everywhere\nRequests and completed minigames are not confirmed catches",zh="测试版，尚未实测\n收线辅助模拟鼠标输入，可能不兼容所有环境\n请求数和小游戏次数不代表成功捕鱼数"},
    ["ไปหมวดช่วยตกปลา →"]={en="Go to fishing helpers →",zh="前往钓鱼辅助 →"},
    ["BM\nผู้สร้างแบรนด์และผู้ออกแบบแนวคิด SATURN X"]={en="BM\nSATURN X brand creator and concept designer",zh="BM\nSATURN X 品牌创建者与概念设计者"},
    ["โลโก้ดาวเสาร์สีเงินที่ BM เลือก\nเปิด / ปิด: window-opening-100430\nเลือก / คลิก: mouse-click-290204"]={en="Silver Saturn logo chosen by BM\nOpen / close: window-opening-100430\nSelect / click: mouse-click-290204",zh="BM 选择的银色土星标志\n开关：window-opening-100430\n点击：mouse-click-290204"},
    ["Fisch เป็นผลงานของ Fisching\nSATURN X เป็นเมนูแยกที่สร้างตามแนวคิดของ BM"]={en="Fisch is created by Fisching\nSATURN X is a separate menu based on BM's concept",zh="Fisch 由 Fisching 制作\nSATURN X 是根据 BM 构思制作的独立菜单"},
    ["ชื่อและรูปของคนที่เปิดเมนูนี้"]={en="The name and avatar of the menu's user",zh="当前使用者的名字和头像"},
    ["\nอายุบัญชี: "]={en="\nAccount age: ",zh="\n账号年龄： "},
    [" วัน"]={en=" days",zh=" 天"},
    ["กำลังอ่านข้อมูลผู้เล่น…"]={en="Reading player information…",zh="正在读取玩家信息…"},
    ["กำลังอ่านสถิติครั้งนี้…"]={en="Reading session statistics…",zh="正在读取本次使用统计…"},
    ["ถือเบ็ดก่อนเปิดตัวช่วยครับ"]={en="Equip a rod before enabling helpers",zh="开启辅助前请先装备鱼竿"},
    ["ปิดบินก่อนเปิดตัวช่วยตกปลาครับ"]={en="Stop flying before enabling fishing helpers",zh="开启钓鱼辅助前请先停止飞行"},
    ["เครื่องนี้ไม่รองรับการกดเมาส์จำลอง"]={en="This runtime cannot simulate mouse input",zh="当前环境不支持模拟鼠标输入"},
    ["เปิดตัวช่วยแล้ว • ย่อเมนูเพื่อเริ่ม"]={en="Helpers enabled • Minimize to start",zh="辅助已开启 • 最小化以开始"},
    ["รอถือเบ็ด…"]={en="Waiting for a rod…",zh="等待装备鱼竿…"},
    ["ยืนใกล้น้ำและถือเบ็ด เปิดตัวช่วยที่ต้องการ แล้วกดย่อเมนู\nตัวช่วยคุมหลอดเป็นรุ่นทดลอง ผลขึ้นกับเบ็ดและการตอบสนองของเกม"]={en="Stand near water with a rod, enable helpers, then minimize\nReel assistance is experimental; results depend on the rod and game response",zh="在水边装备鱼竿，开启辅助后最小化\n收线辅助为实验功能，效果取决于鱼竿及游戏响应"},
    ["ถือเบ็ดจากกระเป๋า"]={en="Equip a rod from your backpack",zh="装备背包中的鱼竿"},
    ["ถือเบ็ดอยู่แล้วครับ"]={en="A rod is already equipped",zh="已经装备鱼竿"},
    ["ถือ "]={en="Equipped ",zh="已装备 "},
    [" แล้ว"]={en=" now",zh=" 了"},
    ["ยังไม่พบเบ็ดที่รองรับในกระเป๋า"]={en="No supported rod found in the backpack",zh="背包中未找到支持的鱼竿"},
    ["เหวี่ยงเบ็ด 1 ครั้ง"]={en="Cast once",zh="抛竿一次"},
    ["เหวี่ยงเบ็ดอัตโนมัติ"]={en="Automatic casting",zh="自动抛竿"},
    ["เขย่าเบ็ดอัตโนมัติ"]={en="Automatic shaking",zh="自动摇竿"},
    ["ช่วยคุมหลอดดึงปลา (ทดลอง)"]={en="Reel bar helper (experimental)",zh="收线条辅助（实验）"},
    ["แรงเหวี่ยง (%)"]={en="Cast strength (%)",zh="抛竿力度（%）"},
    ["เว้นคำขอเหวี่ยงอย่างน้อย (วินาที)"]={en="Minimum cast interval (seconds)",zh="最短抛竿间隔（秒）"},
    ["เว้นคำขอเขย่าอย่างน้อย (วินาที)"]={en="Minimum shake interval (seconds)",zh="最短摇竿间隔（秒）"},
    ["ย่อเมนู / เริ่มตัวช่วยที่เปิดไว้"]={en="Minimize / Start enabled helpers",zh="最小化 / 启动已开启的辅助"},
    ["หยุดตัวช่วยตกปลาทั้งหมด"]={en="Stop all fishing helpers",zh="停止所有钓鱼辅助"},
    ["หยุดตัวช่วยตกปลาแล้ว"]={en="Fishing helpers stopped",zh="钓鱼辅助已停止"},
    ["อ่านโซนที่เกมโหลดให้เครื่องนี้ ระยะวัดถึงกึ่งกลางโซน\nบางพื้นที่อาจยังไม่โหลดเมื่ออยู่ไกล\nเลือกชื่อเพื่อทำเครื่องหมายในรายการ"]={en="Reads zones loaded on this client; distance is to the center\nDistant areas may not be loaded\nSelect a name to mark it in the list",zh="读取本机已加载区域，距离按中心计算\n远处区域可能尚未加载\n点击名称可在列表中选中"},
    ["ป้ายโซนตกปลา"]={en="Fishing zone labels",zh="钓鱼区域标记"},
    ["ป้ายพื้นที่ / เกาะ"]={en="Area / Island labels",zh="区域 / 岛屿标记"},
    ["ป้ายผู้เล่นพร้อม HP"]={en="Player labels with HP",zh="玩家标记及生命值"},
    ["รัศมีรายการและป้าย (studs)"]={en="List and label radius (studs)",zh="列表及标记范围（studs）"},
    ["ค้นหาชื่อโซน เช่น Moosewood"]={en="Search zones, e.g. Moosewood",zh="搜索区域，例如 Moosewood"},
    ["อ่านโซนที่โหลดอยู่ใหม่"]={en="Rescan loaded zones",zh="重新扫描已加载区域"},
    ["เปิดหมวดนี้เพื่ออ่านโซน…"]={en="Open this tab to read zones…",zh="打开此分类以读取区域…"},
    ["เกมอาจปรับความเร็วกลับหรือย้อนตำแหน่ง\nบิน: จอยมือถือหรือ WASD • ↑↓ หรือ Space / Ctrl\nเปิดบินจะหยุดตัวช่วยตกปลา"]={en="The server may reset speed or position\nFlight: joystick or WASD • ↑↓ or Space / Ctrl\nFlying stops fishing helpers",zh="服务器可能重置速度或位置\n飞行：摇杆或 WASD • ↑↓ 或空格 / Ctrl\n开启飞行会停止钓鱼辅助"},
    ["ปรับความเร็วเดิน"]={en="Adjust walk speed",zh="调整步行速度"},
    ["ความเร็วเดิน"]={en="Walk speed",zh="步行速度"},
    ["ปรับความสูงกระโดด"]={en="Adjust jump height",zh="调整跳跃高度"},
    ["ความสูงกระโดด"]={en="Jump height",zh="跳跃高度"},
    ["บิน (ทดลอง)"]={en="Flight (experimental)",zh="飞行（实验）"},
    ["ความเร็วบิน"]={en="Flight speed",zh="飞行速度"},
    ["หยุดทุกฟีเจอร์ / คืนค่า"]={en="Stop all features / Restore",zh="停止全部功能 / 还原"},
    ["หยุดฟีเจอร์และคืนค่าที่เปลี่ยนแล้ว"]={en="Features stopped and modified values restored",zh="功能已停止，修改的数值已还原"},
    ["บันทึกจุดที่ยืนอยู่จริง แล้วเลือกจุดเพื่อกลับไป\nลงจากเรือก่อนย้าย • เซิร์ฟเวอร์อาจย้อนตำแหน่ง\nจุดคงอยู่หลังเกิดใหม่ และบันทึกลงไฟล์ได้เมื่อเครื่องรองรับ"]={en="Save where you stand, then select a point to return\nLeave your boat first; the server may reset your position\nPoints survive respawns and can be saved if file access is supported",zh="保存当前位置，选择地点即可返回\n移动前先下船；服务器可能将你移回\n重生后保留地点，支持文件访问时可保存到本机"},
    ["ชื่อจุด เช่น ท่าเรือ"]={en="Point name, e.g. Pier",zh="地点名称，例如码头"},
    ["ยังไม่มีจุดที่เลือก"]={en="No waypoint selected",zh="尚未选择地点"},
    ["บันทึกตำแหน่งที่ยืนอยู่"]={en="Save current location",zh="保存当前位置"},
    ["บันทึกครบ 8 จุดแล้ว • ลบจุดเดิมก่อนครับ"]={en="8 points saved • Delete an old point first",zh="已保存 8 个地点 • 请先删除旧地点"},
    ["ลงจากที่นั่งก่อนบันทึกจุดครับ"]={en="Leave your seat before saving a point",zh="保存地点前请先离开座位"},
    ["ชื่อจุดยาวเกินไปครับ"]={en="Waypoint name is too long",zh="地点名称过长"},
    ["จุด "]={en="Point ",zh="地点 "},
    ["บันทึก "]={en="Saved ",zh="已保存 "},
    ["กลับไปจุดที่เลือก"]={en="Return to selected point",zh="返回所选地点"},
    ["เลือกจุดในแมพนี้ก่อนครับ"]={en="Select a point on this map first",zh="请先选择当前地图中的地点"},
    ["ลงจากที่นั่งก่อนย้ายครับ"]={en="Leave your seat before moving",zh="移动前请先离开座位"},
    ["ลองย้ายไป "]={en="Trying to move to ",zh="正在尝试移动到 "},
    ["ลบจุดที่เลือก"]={en="Delete selected point",zh="删除所选地点"},
    ["เลือกจุดก่อนครับ"]={en="Select a point first",zh="请先选择地点"},
    ["บันทึกรายการจุดลงเครื่อง"]={en="Save waypoints to this device",zh="保存地点列表到本机"},
    ["เครื่องนี้ไม่รองรับการบันทึกไฟล์"]={en="This runtime cannot save files",zh="当前环境不支持保存文件"},
    ["บันทึกรายการ "]={en="Saved list with ",zh="已保存列表，共 "},
    [" จุดแล้ว"]={en=" points",zh=" 个地点"},
    ["โหลดรายการจุดที่บันทึกไว้"]={en="Load saved waypoint list",zh="加载保存的地点列表"},
    ["เครื่องนี้ไม่รองรับการอ่านไฟล์"]={en="This runtime cannot read files",zh="当前环境不支持读取文件"},
    ["ยังไม่มีไฟล์จุดของแมพนี้"]={en="No waypoint file for this map yet",zh="当前地图尚无地点文件"},
    ["ไฟล์จุดไม่ถูกต้องหรือใหญ่เกินไป"]={en="Invalid or oversized waypoint file",zh="地点文件无效或过大"},
    ["โหลด "]={en="Loaded ",zh="已加载 "},
    ["เพิ่มความสว่าง"]={en="Increase brightness",zh="提高亮度"},
    ["ลดหมอก"]={en="Reduce fog",zh="减少雾效"},
    ["ปิดเงา"]={en="Disable shadows",zh="关闭阴影"},
    ["มุมมองกล้อง FOV"]={en="Camera field of view",zh="相机视野 FOV"},
    ["ปิดเสียงเมนู"]={en="Mute menu sounds",zh="静音菜单音效"},
    ["ระดับเสียงเมนู"]={en="Menu sound volume",zh="菜单音效音量"},
    ["ทดสอบเสียงเปิด / ปิด"]={en="Test open / close sound",zh="测试开关音效"},
    ["กำลังเตรียมโลโก้และเสียง…"]={en="Preparing logo and sounds…",zh="正在准备标志及音效…"},
    ["สร้างรายงานตรวจข้อมูล"]={en="Create diagnostic report",zh="生成诊断报告"},
    ["ถ้าฟีเจอร์ไม่ทำงาน ส่งภาพรายงานนี้มาได้ครับ"]={en="If a feature fails, send a screenshot of this report",zh="如果功能失效，可发送此报告的截图"},
    ["รายงานจะแสดงที่นี่"]={en="The report will appear here",zh="报告将在此显示"},
    ["คัดลอกรายงาน"]={en="Copy report",zh="复制报告"},
    ["คัดลอกแล้ว"]={en="Copied",zh="已复制"},
    ["เครื่องนี้ไม่มีคำสั่งคัดลอก ใช้ภาพหน้าจอแทนครับ"]={en="Clipboard unavailable; take a screenshot instead",zh="无法复制到剪贴板，请使用截图"},
    ["หยุดทุกฟีเจอร์แล้ว"]={en="All features stopped",zh="所有功能已停止"},
    ["ปิด SATURN X FISCH"]={en="Close SATURN X FISCH",zh="关闭 SATURN X FISCH"},
    ["หยุดฟีเจอร์ทั้งหมดแล้ว"]={en="All features stopped",zh="所有功能已停止"},
    ["ระบบตกปลาหยุดแล้ว • ดูรายงานหมวด 8 ได้ครับ"]={en="Fishing stopped • See the report in tab 8",zh="钓鱼已停止 • 请查看分类 8 的报告"},
    ["พัก: เมนูเปิดอยู่"]={en="Paused: menu open",zh="已暂停：菜单打开"},
    ["พัก: สลับหน้าต่าง"]={en="Paused: window unfocused",zh="已暂停：窗口失去焦点"},
    ["พัก: เมนู Roblox เปิดอยู่"]={en="Paused: Roblox menu open",zh="已暂停：Roblox 菜单打开"},
    ["เมนูย่อแล้ว"]={en="Menu minimized",zh="菜单已最小化"},
    ["เบ็ด: %s\nช่วง: %s • %s\nการกดช่วยดึง: %s"]={en="Rod: %s\nPhase: %s • %s\nReel input: %s",zh="鱼竿：%s\n阶段：%s • %s\n收线输入：%s"},
    ["ยังไม่ได้ถือ"]={en="Not equipped",zh="尚未装备"},
    ["ใช้งานครั้งนี้ %02d:%02d:%02d\nคำขอเหวี่ยง %d • คำขอเขย่า %d\nรอบหลอดดึงที่จบ %d (รวมล้มเหลว/ยกเลิก ไม่ใช่จำนวนปลา)"]={en="Session %02d:%02d:%02d\nCast requests %d • Shake requests %d\nReel minigames ended %d (includes failed/cancelled; not catches)",zh="本次使用 %02d:%02d:%02d\n抛竿请求 %d • 摇竿请求 %d\n收线小游戏结束 %d 次（含失败及取消，不代表捕鱼数）"},
    ["พลังชีวิต %.0f / %.0f\nตำแหน่ง %.0f, %.0f, %.0f\nผู้เล่น %d • FPS %.0f"]={en="Health %.0f / %.0f\nPosition %.0f, %.0f, %.0f\nPlayers %d • FPS %.0f",zh="生命值 %.0f / %.0f\n位置 %.0f, %.0f, %.0f\n玩家 %d • FPS %.0f"},
    ["%s • ห่าง %.0f studs"]={en="%s • %.0f studs away",zh="%s • 距离 %.0f studs"},
    ["เลือกจุดเพื่อดูระยะ"]={en="Select a point to see the distance",zh="选择地点以查看距离"},
    ["กำลังรอตัวละครเกิด…"]={en="Waiting for your character…",zh="等待角色生成…"},
    ["รอตัวละครเกิดเพื่อดูระยะ"]={en="Waiting for your character to measure distance",zh="等待角色生成后计算距离"},
    ["แมพไม่ตรง"]={en="Map mismatch",zh="地图不匹配"},
    ["ไม่รองรับไฟล์แนบ — ต้องตั้ง Roblox asset ID"]={en="Attached files unsupported — set a Roblox asset ID",zh="不支持本地附件，请设置 Roblox 资源 ID"},
    ["โหลดไม่ได้: "]={en="Load failed: ",zh="加载失败： "},
    ["โลโก้: "]={en="Logo: ",zh="标志： "},
    ["\nเปิด/ปิด: "]={en="\nOpen/close: ",zh="\n开关音效： "},
    ["\nคลิก: "]={en="\nClick: ",zh="\n点击音效： "},
    ["กำลังตรวจการโหลด"]={en="Checking asset loading",zh="正在检查资源加载"},
    ["พร้อม"]={en="Ready",zh="就绪"},
    ["ไม่สำเร็จ / runtime หรือ asset permission ไม่รองรับ"]={en="Failed / Runtime or asset permission unsupported",zh="失败 / 运行环境或资源权限不支持"},
    ["โหลดช้า / ยังไม่ยืนยัน"]={en="Slow loading / Not yet confirmed",zh="加载较慢 / 尚未确认"},
    ["เปิด UI ได้ แต่แมพนี้ไม่ใช่ Fisch"]={en="Menu available, but this map is not Fisch",zh="菜单可用，但当前地图不是 Fisch"},
    ["[BM XY] ต้องรันฝั่ง client; ไม่ใช่ Server Script หรือช่องแชต"]={en="[BM XY] Run on the client, not as a server script or in chat",zh="[BM XY] 请在客户端运行，不要放入服务器脚本或聊天框"},
    ["[BM XY] ไม่พบ PlayerGui"]={en="[BM XY] PlayerGui not found",zh="[BM XY] 找不到 PlayerGui"},
    ["[BM XY audio] ตัวรันไม่มี writefile/getcustomasset สำหรับเสียงแนบ; ระบบเล็งยังใช้งานได้"]={en="[BM XY audio] Local audio files unsupported; aiming can still work",zh="[BM XY audio] 不支持本地音频文件，瞄准功能仍可运行"},
    ["[BM XY audio] โหลดเสียงไม่สำเร็จ: "]={en="[BM XY audio] Sound loading failed: ",zh="[BM XY audio] 音效加载失败： "},
    ["ดึงของ"]={en="Item pull",zh="拉取物品"},
    ["ค้นหาไอเท็ม"]={en="Find items",zh="搜索物品"},
    ["Place/Universe นี้ไม่ตรงกับ 100 Days At Sea — เปิดได้เฉพาะเมนู"]={en="This Place/Universe is not 100 Days At Sea — Menu only",zh="当前地点或世界不是 100 Days At Sea，仅能打开菜单"},
    ["เก็บ"]={en="Collect",zh="拾取"},
    ["พบ %d ชิ้น • ตรวจ %d parts%s\nรายการคือของที่เข้าเกณฑ์ ยังไม่ยืนยันว่าเซิร์ฟเวอร์ให้ดึง"]={en="Found %d items • Checked %d parts%s\nEligible items; server permission to move them is not confirmed",zh="发现 %d 件物品 • 检查 %d 个部件%s\n列表仅表示符合条件，未确认服务器允许移动"},
    [" (ถึงขีดจำกัด)"]={en=" (limit reached)",zh=" （已达上限）"},
    ["เลือก "]={en="Selected ",zh="已选择 "},
    ["ครั้งล่าสุด: ส่งคำสั่งฟิสิกส์ %d ชิ้น • ข้ามสิทธิ์ %d\nตัวเลขนี้ไม่ใช่จำนวนที่เก็บเข้ากระเป๋าสำเร็จ"]={en="Last attempt: physics requests %d • Permission skipped %d\nThese are not confirmed inventory pickups",zh="最近尝试：物理请求 %d 件 • 跳过权限 %d 件\n这些数字不代表成功放入背包的数量"},
    ["ยังดึงไม่ได้: ลองเข้าใกล้ของแล้วสแกน หรือดูรายงานตรวจของ"]={en="Cannot pull yet: move closer and rescan, or check diagnostics",zh="暂时无法拉取：靠近后重新扫描，或查看诊断报告"},
    ["ลองดึง "]={en="Attempted to pull ",zh="已尝试拉取 "},
    [" ชิ้นแล้ว — ต้องดูผลในเกม ไม่ยืนยันการเก็บเข้ากระเป๋า"]={en=" items — Check in game; inventory pickup not confirmed",zh=" 件物品，请在游戏中确认；不保证已放入背包"},
    ["SILVER ORBIT\nเมนู 8 หมวด • ลากแถบด้านบนเพื่อย้าย\nย่อเป็นปุ่มดาวเสาร์ • รองรับเมาส์และสัมผัส"]={en="SILVER ORBIT\n8 tabs • Drag the top bar to move\nMinimizes to a Saturn button • Mouse and touch support",zh="SILVER ORBIT\n8 个分类 • 拖动顶部栏移动\n最小化为土星按钮 • 支持鼠标及触控"},
    ["ในเวอร์ชันนี้\n• โลโก้และเสียงที่ BM ส่งมา\n• รูปอวตาร ชื่อ และข้อมูลผู้เล่นจริง\n• ค้นหาทรัพยากร / ป้ายระยะ / เลือกของ\n• ดึงของแบบทดลอง / บิน / จุดบันทึก"]={en="This version\n• BM's logo and sounds\n• Actual avatar, name and player data\n• Resource search / Distance labels / Item selection\n• Experimental pulling / Flight / Waypoints",zh="本版本\n• BM 提供的标志及音效\n• 真实头像、名字和玩家资料\n• 资源搜索 / 距离标记 / 物品选择\n• 实验性拉取 / 飞行 / 地点保存"},
    ["สถานะ: ยังไม่ได้ทดสอบในเซิร์ฟเวอร์จริง\nดึงของใช้ฟิสิกส์ฝั่งเครื่อง ชื่อและโฟลเดอร์ของเป็นเกณฑ์ค้นหาเบื้องต้น จึงอาจตรวจไม่พบหรือขยับไม่ได้"]={en="Not tested on a live server\nPulling uses client physics. Names and folders are initial search criteria; items may not be found or may not move",zh="尚未在实际服务器测试\n拉取使用客户端物理，名称和文件夹仅用于初步搜索，物品可能无法找到或移动"},
    ["เริ่มค้นหาของ →"]={en="Start finding items →",zh="开始搜索物品 →"},
    ["โลโก้: ดาวเสาร์สีเงินที่ BM เลือก\nเสียงเปิด / ปิด: window-opening-100430\nเสียงเลือก / คลิก: mouse-click-290204"]={en="Logo: Silver Saturn chosen by BM\nOpen / close: window-opening-100430\nSelect / click: mouse-click-290204",zh="标志：BM 选择的银色土星\n开关音效：window-opening-100430\n点击音效：mouse-click-290204"},
    ["เกม 100 Days At Sea เป็นผลงานของ Stranded Devs\nSATURN X เป็นงานแยก ไม่ใช่เมนูทางการของเกม"]={en="100 Days At Sea is created by Stranded Devs\nSATURN X is separate and is not the game's official menu",zh="100 Days At Sea 由 Stranded Devs 制作\nSATURN X 是独立作品，并非游戏官方菜单"},
    ["ข้อมูลของคนที่เปิดใช้เมนูนี้"]={en="Information about the person using this menu",zh="当前菜单使用者的资料"},
    ["กำลังอ่านตัวละคร…"]={en="Reading character…",zh="正在读取角色…"},
    ["ดึงเฉพาะทรัพยากรที่ตรวจพบใกล้ตัว ไม่ใช่การเก็บเข้ากระเป๋าอัตโนมัติ ของที่เซิร์ฟเวอร์ควบคุมอาจไม่ขยับ"]={en="Pulls detected nearby resources, not automatic inventory pickup. Server-controlled objects may not move",zh="拉取附近检测到的资源，不会自动放入背包。服务器控制的物体可能无法移动"},
    ["ดึงของใกล้ตัวต่อเนื่อง"]={en="Continuously pull nearby items",zh="持续拉取附近物品"},
    ["เปิดดึงของทดลอง • ปิดสวิตช์หรือกดหยุดทั้งหมดเพื่อหยุด"]={en="Experimental pull enabled • Toggle off or stop all to end",zh="实验性拉取已开启 • 关闭开关或停止全部即可结束"},
    ["ระยะดึง (studs)"]={en="Pull range (studs)",zh="拉取距离（studs）"},
    ["จำนวนสูงสุดต่อรอบ"]={en="Maximum per round",zh="每轮最大数量"},
    ["ลองดึงของใกล้ตัว 1 ครั้ง"]={en="Try pulling nearby items once",zh="尝试拉取附近物品一次"},
    ["ลองดึงเฉพาะชิ้นที่เลือก"]={en="Try pulling only the selected item",zh="仅尝试拉取所选物品"},
    ["เลือกของจากหมวดค้นหาไอเท็มก่อน"]={en="Select an item in the search tab first",zh="请先在搜索分类中选择物品"},
    ["ยังไม่มีคำสั่งดึงของ"]={en="No pull requests yet",zh="尚未发送拉取请求"},
    ["กรองชื่อที่พบ เช่น wood"]={en="Filter names, e.g. wood",zh="按名称筛选，例如 wood"},
    ["รัศมีค้นหา (studs)"]={en="Search radius (studs)",zh="搜索范围（studs）"},
    ["แสดงชื่อและระยะของไอเท็ม"]={en="Show item names and distances",zh="显示物品名称及距离"},
    ["สแกน / อัปเดตรายการ"]={en="Scan / Refresh list",zh="扫描 / 刷新列表"},
    ["กดสแกนเพื่อค้นหาทรัพยากรที่อยู่ใกล้ตัว"]={en="Scan to find nearby resources",zh="点击扫描以查找附近资源"},
    ["แตะรายการเพื่อเลือกชิ้นที่จะดึง • ค้นหาได้เฉพาะของที่โหลดอยู่ในเครื่อง และชื่อ/โฟลเดอร์ที่เข้าเกณฑ์"]={en="Tap an item to select it • Only loaded items matching name/folder criteria can be found",zh="点击物品以选择 • 仅能查找本机已加载且名称或文件夹符合条件的物品"},
    ["การเคลื่อนที่ขึ้นกับกติกาของเซิร์ฟเวอร์\nบิน: จอยมือถือหรือ WASD • ปุ่ม ↑↓ หรือ Space / Ctrl"]={en="Movement depends on server rules\nFlight: joystick or WASD • ↑↓ or Space / Ctrl",zh="移动效果取决于服务器规则\n飞行：摇杆或 WASD • ↑↓ 或空格 / Ctrl"},
    ["บิน"]={en="Flight",zh="飞行"},
    ["หยุดฟีเจอร์ทั้งหมด"]={en="Stop all features",zh="停止所有功能"},
    ["ปิดฟีเจอร์และคืนค่าที่เปลี่ยนแล้ว"]={en="Features disabled and modified values restored",zh="功能已关闭，修改的数值已还原"},
    ["บันทึกพิกัดปัจจุบันได้ 8 จุด เช่น เกาะหรือฐาน\nพิกัดอยู่กับที่ หากแพเคลื่อนจะไม่ตามแพ และจะหายเมื่อออกเกม"]={en="Save up to 8 locations such as islands or bases\nPoints are fixed, do not follow moving rafts, and clear on exit",zh="最多保存 8 个位置，例如岛屿或基地\n坐标固定，不跟随移动的木筏，退出后清除"},
    ["ชื่อจุด เช่น ฐาน / เกาะแรก"]={en="Point name, e.g. Base / First island",zh="地点名称，例如基地 / 第一座岛"},
    ["บันทึกจุดที่ยืนอยู่"]={en="Save standing location",zh="保存当前站立位置"},
    ["ครบ 8 จุดแล้ว ลบจุดเดิมก่อน"]={en="8 points already saved; delete an old one first",zh="已保存 8 个地点，请先删除旧地点"},
    ["บันทึกพิกัดแล้ว"]={en="Coordinates saved",zh="坐标已保存"},
    ["กลับไปจุดที่เลือก (ทดลอง)"]={en="Return to selected point (experimental)",zh="返回所选地点（实验）"},
    ["ส่งคำสั่งย้ายแล้ว • เซิร์ฟเวอร์อาจดึงกลับ"]={en="Move requested • The server may move you back",zh="已请求移动 • 服务器可能将你移回"},
    ["ชื่อทรัพยากร คั่นด้วย ,"]={en="Resource names, separated by commas",zh="资源名称，以逗号分隔"},
    ["ใส่ชื่อทรัพยากรอย่างน้อย 1 ชื่อ"]={en="Enter at least one resource name",zh="请至少输入一个资源名称"},
    ["สร้างรายงานตรวจของ"]={en="Create item diagnostic report",zh="生成物品诊断报告"},
    ["รายงานอยู่ในช่องด้านล่าง คัดลอกหรือถ่ายภาพส่งมาได้"]={en="Report below; copy it or take a screenshot",zh="报告在下方，可复制或截图"},
    ["คัดลอกรายงานแล้ว"]={en="Report copied",zh="报告已复制"},
    ["หยุดทั้งหมด / คืนค่า"]={en="Stop everything / Restore",zh="停止全部 / 还原"},
    ["ปิดทุกฟีเจอร์แล้ว"]={en="All features disabled",zh="所有功能已关闭"},
    ["ปิด SATURN X"]={en="Close SATURN X",zh="关闭 SATURN X"},
    ["พลังชีวิต %.0f / %.0f\nตำแหน่ง %.0f, %.0f, %.0f\nผู้เล่นในเซิร์ฟเวอร์ %d • FPS %.0f"]={en="Health %.0f / %.0f\nPosition %.0f, %.0f, %.0f\nServer players %d • FPS %.0f",zh="生命值 %.0f / %.0f\n位置 %.0f, %.0f, %.0f\n服务器玩家 %d • FPS %.0f"},
    ["เปิด UI ได้ แต่ Place/Universe ไม่ตรงกับแมพที่ตั้งไว้"]={en="Menu available, but Place/Universe differs from the configured map",zh="菜单可用，但当前地点或世界与设置的地图不符"},
    ["เปิดหมวด 4 เพื่ออ่านบทบาทจากเกม"]={en="Open tab 4 to read roles from the game",zh="打开分类 4 读取游戏身份"},
    ["ยังไม่ได้เริ่มเดิน"]={en="Walking has not started",zh="尚未开始行走"},
    ["ผู้เล่น / บทบาท"]={en="Players / Roles",zh="玩家 / 身份"},
    ["เหรียญ / ปืนตก"]={en="Coins / Dropped gun",zh="金币 / 掉落的枪"},
    ["จุด / กล้อง"]={en="Waypoints / Camera",zh="地点 / 相机"},
    ["Place/Universe นี้ไม่ตรงกับ Murder Mystery 2 — เปิดได้เฉพาะเมนู"]={en="This Place/Universe is not Murder Mystery 2 — Menu only",zh="当前地点或世界不是 Murder Mystery 2，仅能打开菜单"},
    ["ถืออยู่"]={en="Equipped",zh="已装备"},
    ["ในกระเป๋า"]={en="In backpack",zh="在背包中"},
    ["มีด: "]={en="Knife: ",zh="刀： "},
    [" • ปืน: "]={en=" • Gun: ",zh=" • 枪： "},
    ["พบมีด • "]={en="Knife detected • ",zh="发现刀 • "},
    ["พบปืน • "]={en="Gun detected • ",zh="发现枪 • "},
    ["ยังไม่ทราบอาวุธ"]={en="Weapon unknown",zh="武器未知"},
    ["ฆาตกร"]={en="Murderer",zh="凶手"},
    ["นายอำเภอ"]={en="Sheriff",zh="警长"},
    ["ฮีโร่"]={en="Hero",zh="英雄"},
    ["ผู้บริสุทธิ์"]={en="Innocent",zh="平民"},
    ["ข้อมูลบทบาทมีรูปแบบที่ยังไม่รองรับ"]={en="Unsupported role data format",zh="不支持的身份数据格式"},
    ["รับบทบาทจากเกมแล้ว "]={en="Game roles received for ",zh="已收到游戏身份，共 "},
    [" คน • "]={en=" players • ",zh=" 位玩家 • "},
    ["เกมยังไม่ส่งบทบาทที่อ่านได้"]={en="No readable role data from the game yet",zh="游戏尚未发送可读取的身份数据"},
    ["เริ่มรอบ • รอข้อมูลบทบาท"]={en="Round started • Waiting for role data",zh="回合开始 • 等待身份数据"},
    ["กำลังรับบทบาทรอบใหม่"]={en="Receiving roles for the new round",zh="正在接收新回合身份"},
    ["จบรอบ • รอรอบใหม่"]={en="Round ended • Waiting for the next round",zh="回合结束 • 等待下一回合"},
    ["เกมยังไม่ตอบข้อมูลบทบาท • รอโดยไม่ส่งคำขอซ้ำ"]={en="Waiting for game roles without repeating requests",zh="等待游戏身份响应，不重复发送请求"},
    ["ไม่พบ GetPlayerData • รอข้อมูลที่เกมส่งมา"]={en="GetPlayerData not found • Waiting for game data",zh="未找到 GetPlayerData • 等待游戏发送数据"},
    ["ข้อมูลตอบกลับช้า • รอข้อมูลใหม่"]={en="Slow response • Waiting for new data",zh="响应较慢 • 等待新数据"},
    ["อ่านบทบาทไม่สำเร็จ"]={en="Could not read roles",zh="无法读取身份"},
    ["ตาย / ไม่อยู่ในรอบ • ข้อมูลเกม"]={en="Dead / Not in round • Game data",zh="死亡 / 不在回合中 • 游戏数据"},
    [" • ข้อมูลเกม"]={en=" • Game data",zh=" • 游戏数据"},
    ["\nผู้เล่นที่มีตัวละครและ HP > 0: "]={en="\nPlayers with a character and HP > 0: ",zh="\n有角色且生命值大于 0 的玩家： "},
    [" คน • อาจรวมล็อบบี้\nป้ายระบุว่าเป็นข้อมูลบทบาทจากเกม หรืออาวุธที่มองเห็น"]={en=" players • May include the lobby\nLabels distinguish game role data from visible weapons",zh=" 人 • 可能包含大厅玩家\n标记会区分游戏身份数据和可见武器"},
    [" แล้ว • ดูกล้องได้ในหมวด 7"]={en=" • Spectate in tab 7",zh=" • 可在分类 7 观看"},
    ["เลือกผู้เล่นที่ยังมีตัวละครในหมวด 4 ก่อนครับ"]={en="Select a player with a character in tab 4 first",zh="请先在分类 4 选择仍有角色的玩家"},
    ["พบ %d รายการ • ตรวจ %d parts%s\nชื่อที่เข้าเกณฑ์ยังต้องตรวจสอบกับแมพจริง"]={en="Found %d items • Checked %d parts%s\nMatching names still need verification in the current map",zh="发现 %d 项 • 检查 %d 个部件%s\n名称匹配结果仍需在当前地图中核实"},
    ["เหรียญ"]={en="Coin",zh="金币"},
    ["ปืนตก"]={en="Dropped gun",zh="掉落的枪"},
    ["พบวัตถุชื่อปืนตกใกล้ตัว • เปิดหมวด 5 เพื่อดูตำแหน่ง"]={en="Nearby dropped-gun name detected • See tab 5 for its position",zh="附近发现名称类似掉落枪的物体 • 分类 5 可查看位置"},
    ["หยุดเดินอัตโนมัติแล้ว"]={en="Automatic walking stopped",zh="自动行走已停止"},
    ["หาเส้นทางไม่ได้ • ลองเข้าใกล้ของ"]={en="No path found • Try moving closer",zh="找不到路径 • 请尝试靠近物品"},
    ["เส้นทางยาวเกินไป • เข้าใกล้เป้าหมายก่อน"]={en="Path too long • Move closer to the target first",zh="路径过长 • 请先靠近目标"},
    ["เดินติดสิ่งกีดขวาง • หยุดเป้าหมายนี้"]={en="Path blocked • This target was stopped",zh="路径受阻 • 已停止前往此目标"},
    ["เดินถึงเป้าหมายแล้ว • ยังไม่ยืนยันการเก็บของ"]={en="Reached target • Pickup is not confirmed",zh="已到达目标 • 未确认成功拾取"},
    ["กำลังเดินหาเหรียญ: "]={en="Walking to coin: ",zh="正在前往金币： "},
    ["รอเหรียญที่เข้าเกณฑ์ในรัศมีค้นหา"]={en="Waiting for eligible coins within search range",zh="等待搜索范围内符合条件的金币"},
    ["เดินต่อไม่ได้ • หยุดแล้ว"]={en="Unable to continue walking • Stopped",zh="无法继续行走 • 已停止"},
    ["ระบบเดินหยุดแล้ว ดูรายละเอียดในรายงานหมวด 8 ได้ครับ"]={en="Walking stopped; see diagnostics in tab 8",zh="行走已停止，请查看分类 8 的报告"},
    ["MURDER MYSTERY 2\nเมนู 8 หมวด • โลโก้เงิน • เสียงที่ BM เลือก\nลากแถบบนเพื่อย้าย • ย่อเป็นปุ่มดาวเสาร์"]={en="MURDER MYSTERY 2\n8 tabs • Silver logo • BM's sounds\nDrag the top bar • Minimize to Saturn",zh="MURDER MYSTERY 2\n8 个分类 • 银色标志 • BM 选择的音效\n拖动顶部栏 • 最小化为土星按钮"},
    ["ฟีเจอร์ MM2\n• ป้ายผู้เล่นและอาวุธที่ตรวจพบ\n• ค้นหาเหรียญ / ปืนตก / เดินตามเส้นทาง\n• บิน เดินเร็ว กระโดด และจุดบันทึก\n• กล้องดูผู้เล่นและการปรับภาพ"]={en="MM2 features\n• Player and detected weapon labels\n• Coins / Dropped gun / Path walking\n• Flight, speed, jump and waypoints\n• Spectating and visual settings",zh="MM2 功能\n• 玩家及检测到的武器标记\n• 金币 / 掉落枪 / 路径行走\n• 飞行、速度、跳跃及保存地点\n• 玩家观战与画面设置"},
    ["อัปเดต 1.0.2\nอ่านบทบาทจากข้อมูลเกมได้โดยไม่ต้องรอถืออาวุธ เมื่อเกมรองรับ\nมีสถานะการรับข้อมูลในหมวด 4 และล้างบทบาทเมื่อจบรอบ"]={en="Update 1.0.2\nReads game role data without waiting for equipped weapons, when supported\nTab 4 shows data status; roles clear when the round ends",zh="更新 1.0.2\n游戏支持时，无需等待装备武器即可读取身份\n分类 4 显示接收状态，回合结束时清除身份"},
    ["สถานะ: ยังไม่ทดสอบในเกมจริง\nหากเกมไม่ส่งบทบาท จะใช้ป้ายอาวุธที่มองเห็นแทน\nชื่อไอเท็มเป็นเกณฑ์ค้นหาเบื้องต้น ต้องทดสอบกับแมพปัจจุบัน"]={en="Not tested live\nFalls back to visible weapon labels if no role data arrives\nItem names are initial criteria and need testing on the current map",zh="尚未实测\n未收到身份数据时，仅显示可见武器标记\n物品名称用于初步搜索，需在当前地图中测试"},
    ["ดูรายชื่อผู้เล่น →"]={en="View player list →",zh="查看玩家列表 →"},
    ["Murder Mystery 2 เป็นผลงานของ Nikilis\nSATURN X เป็นงานแยก ไม่ใช่เมนูทางการของเกม"]={en="Murder Mystery 2 is created by Nikilis\nSATURN X is separate and is not the game's official menu",zh="Murder Mystery 2 由 Nikilis 制作\nSATURN X 为独立作品，并非官方菜单"},
    ["ผู้เล่นที่เปิด SATURN X"]={en="The player using SATURN X",zh="当前使用 SATURN X 的玩家"},
    ["ป้าย ‘ข้อมูลเกม’ อ่านบทบาทได้โดยไม่ต้องถืออาวุธ\nแดง = ฆาตกร • ฟ้า = นายอำเภอ • ส้ม = ฮีโร่ • เขียว = ผู้บริสุทธิ์\nหากเกมไม่ส่งบทบาท จะแสดงเฉพาะอาวุธที่พบหรือ ‘ยังไม่ทราบ’"]={en="'Game data' roles do not require an equipped weapon\nRed = Murderer • Blue = Sheriff • Orange = Hero • Green = Innocent\nWithout role data, labels show detected weapons or 'unknown'",zh="“游戏数据”身份无需装备武器\n红＝凶手 • 蓝＝警长 • 橙＝英雄 • 绿＝平民\n没有身份数据时，仅显示检测到的武器或“未知”"},
    ["อ่านบทบาทจากข้อมูลเกม"]={en="Read roles from game data",zh="读取游戏身份数据"},
    ["รอข้อมูลบทบาทจากเกม"]={en="Waiting for game role data",zh="等待游戏身份数据"},
    ["ปิดการอ่านบทบาทแล้ว"]={en="Role reading disabled",zh="已关闭身份读取"},
    ["ไฮไลต์ผู้เล่นผ่านวัตถุ"]={en="Highlight players through objects",zh="透过物体高亮玩家"},
    ["แสดงชื่อและระยะผู้เล่น"]={en="Show player names and distances",zh="显示玩家名字及距离"},
    ["ใช้สีตามบทบาท / อาวุธ"]={en="Color by role / weapon",zh="按身份 / 武器着色"},
    ["อัปเดตบทบาท / รายชื่อผู้เล่น"]={en="Refresh roles / player list",zh="刷新身份 / 玩家列表"},
    ["กำลังอ่านผู้เล่น…"]={en="Reading players…",zh="正在读取玩家…"},
    ["ตรวจวัตถุตามชื่อและโครงสร้างที่โหลดอยู่ในเครื่อง\nระบบเดินอัตโนมัติพาไปตำแหน่งของ การเก็บสำเร็จขึ้นกับเกม"]={en="Checks names and structures loaded on this client\nAuto-walking goes to the item; successful pickup depends on the game",zh="检查本机已加载的名称及结构\n自动行走前往物品位置，是否拾取成功取决于游戏"},
    ["แสดงป้ายชื่อ / ระยะไอเท็ม"]={en="Show item name / distance labels",zh="显示物品名称 / 距离"},
    ["แจ้งเตือนเมื่อพบปืนตก"]={en="Notify when a dropped gun is detected",zh="发现掉落的枪时提醒"},
    ["เดินหาเหรียญใกล้ตัวอัตโนมัติ"]={en="Automatically walk to nearby coins",zh="自动前往附近金币"},
    ["เดินอัตโนมัติเริ่มต้นเป็นปิด"]={en="Automatic walking is off by default",zh="自动行走默认关闭"},
    ["กรองชื่อไอเท็มที่พบ"]={en="Filter detected item names",zh="筛选检测到的物品名称"},
    ["สลับชนิด: ทั้งหมด → เหรียญ → ปืนตก"]={en="Cycle: All → Coins → Dropped gun",zh="切换类型：全部 → 金币 → 掉落枪"},
    ["ตัวกรอง: "]={en="Filter: ",zh="筛选： "},
    ["กดสแกนเพื่อค้นหาไอเท็มใกล้ตัว"]={en="Scan to find nearby items",zh="点击扫描以查找附近物品"},
    ["เดินไปไอเท็มที่เลือก"]={en="Walk to selected item",zh="前往所选物品"},
    ["เลือกรายการที่ยังอยู่ใกล้ตัวก่อนครับ"]={en="Select an item that is still nearby",zh="请选择仍在附近的物品"},
    ["หยุดเดินอัตโนมัติ"]={en="Stop automatic walking",zh="停止自动行走"},
    ["การเคลื่อนที่ขึ้นกับกติกาของเซิร์ฟเวอร์\nบิน: จอยมือถือหรือ WASD • ↑↓ หรือ Space / Ctrl"]={en="Movement depends on server rules\nFlight: joystick or WASD • ↑↓ or Space / Ctrl",zh="移动效果取决于服务器规则\n飞行：摇杆或 WASD • ↑↓ 或空格 / Ctrl"},
    ["หยุดทุกฟีเจอร์"]={en="Stop every feature",zh="停止所有功能"},
    ["กล้องดูผู้เล่นที่เลือก"]={en="Spectate selected player",zh="观看所选玩家"},
    ["เลือกผู้เล่นในหมวด 4 ก่อนเปิดกล้อง\nจุดบันทึกเก็บได้ 8 จุด และจะล้างเมื่อตัวละครเกิดใหม่"]={en="Select a player in tab 4 before spectating\nSave up to 8 points; cleared on respawn",zh="观战前请在分类 4 选择玩家\n最多保存 8 个地点，角色重生时清除"},
    ["ชื่อจุด เช่น ล็อบบี้ / ห้องโถง"]={en="Point name, e.g. Lobby / Hall",zh="地点名称，例如大厅 / 走廊"},
    ["ชื่อเหรียญ คั่นด้วย ,"]={en="Coin names, separated by commas",zh="金币名称，以逗号分隔"},
    ["ใส่ชื่อวัตถุอย่างน้อย 1 ชื่อ"]={en="Enter at least one object name",zh="请至少输入一个物体名称"},
    ["ชื่อปืนตก คั่นด้วย ,"]={en="Dropped-gun names, separated by commas",zh="掉落枪的名称，以逗号分隔"},
    ["รายงานอยู่ด้านล่าง ส่งภาพหรือคัดลอกมาได้"]={en="Report below; send a screenshot or copy it",zh="报告在下方，可截图发送或复制"},
    ["ปิด SATURN X MM2"]={en="Close SATURN X MM2",zh="关闭 SATURN X MM2"},
    ["ตัวละครเกิดใหม่ • รอข้อมูลบทบาท"]={en="Character respawned • Waiting for role data",zh="角色已重生 • 等待身份数据"},
    ["พลังชีวิต %.0f / %.0f\n%s\nตำแหน่ง %.0f, %.0f, %.0f\nผู้เล่น %d • FPS %.0f"]={en="Health %.0f / %.0f\n%s\nPosition %.0f, %.0f, %.0f\nPlayers %d • FPS %.0f",zh="生命值 %.0f / %.0f\n%s\n位置 %.0f, %.0f, %.0f\n玩家 %d • FPS %.0f"},
    ["ประตู / ไอเท็ม"]={en="Doors / Items",zh="门 / 物品"},
    ["ศัตรู / แจ้งเตือน"]={en="Enemies / Alerts",zh="敌人 / 提醒"},
    ["เก็บของ / โต้ตอบ"]={en="Loot / Interact",zh="拾取 / 交互"},
    ["แมพนี้ไม่ใช่ DOORS ของ LSPLASH • เปิดได้เฉพาะเมนู"]={en="This is not DOORS by LSPLASH • Menu only",zh="当前不是 LSPLASH 的 DOORS • 仅能打开菜单"},
    ["กุญแจ"]={en="Key",zh="钥匙"},
    ["หนังสือ"]={en="Book",zh="书"},
    ["เบรกเกอร์"]={en="Breaker",zh="断路器"},
    ["ฟิวส์"]={en="Fuse",zh="保险丝"},
    ["คันโยก"]={en="Lever",zh="拉杆"},
    ["เครื่องกำเนิดไฟ"]={en="Generator",zh="发电机"},
    ["ปุ่มประตู"]={en="Door button",zh="门按钮"},
    ["ปั๊มน้ำ"]={en="Water pump",zh="水泵"},
    ["ประตู • ห้อง "]={en="Door • Room ",zh="门 • 房间 "},
    ["ที่ซ่อน • "]={en="Hiding spot • ",zh="藏身处 • "},
    ["ซื้อ"]={en="Buy",zh="购买"},
    ["บริจาค"]={en="Donate",zh="捐赠"},
    ["ชุบชีวิต"]={en="Revive",zh="复活"},
    ["ซ่อน"]={en="Hide",zh="躲藏"},
    ["ยังไม่มีข้อมูล"]={en="No information yet",zh="暂无信息"},
    ["แมพนี้ไม่ใช่ DOORS ของ LSPLASH"]={en="This is not DOORS by LSPLASH",zh="当前不是 LSPLASH 的 DOORS"},
    ["เข้าเล่นชั้นที่ต้องการก่อน แล้วรันโหลดเดอร์อีกครั้งครับ"]={en="Enter the desired floor, then run the loader again",zh="先进入想玩的楼层，再重新运行加载器"},
    ["กำลังรอห้องในด่านโหลดครับ"]={en="Waiting for rooms to load",zh="等待房间加载"},
    ["ตรวจพบ %s • ห่าง %.0f studs"]={en="Detected %s • %.0f studs away",zh="检测到 %s • 距离 %.0f studs"},
    ["พบ %d จุดในรัศมี • %s\nเลือกจุดเพื่อดูชื่อ ระยะ และห้อง"]={en="Found %d points in range • %s\nSelect to view name, distance and room",zh="范围内发现 %d 个地点 • %s\n选择以查看名称、距离及房间"},
    ["กำลังอ่านห้อง"]={en="Reading rooms",zh="正在读取房间"},
    ["อ่านบางส่วน"]={en="Partial scan",zh="部分扫描"},
    ["%s • %.0f studs • ห้อง %s%s"]={en="%s • %.0f studs • Room %s%s",zh="%s • %.0f studs • 房间 %s%s"},
    ["ปุ่มนี้ต้องกดค้างนาน • ใช้ปุ่มของเกมครับ"]={en="This button requires a long hold • Use the game button",zh="此按钮需要长按 • 请使用游戏按钮"},
    ["สิ้นสุดการกด • ตรวจผลในเกม"]={en="Press finished • Check the result in game",zh="按键操作结束 • 请在游戏中确认结果"},
    ["กดปุ่มนี้ไม่ได้"]={en="Cannot press this button",zh="无法按下此按钮"},
    ["DOORS โดย LSPLASH\nเมนู 8 หมวด • โลโก้เงิน • เสียงเปิด/ปิดและคลิก"]={en="DOORS by LSPLASH\n8 tabs • Silver logo • Open/close and click sounds",zh="DOORS 由 LSPLASH 制作\n8 个分类 • 银色标志 • 开关及点击音效"},
    ["• ป้ายประตู กุญแจ หนังสือ ฟิวส์ และจุดสำคัญ\n• ป้ายที่ซ่อน ไอเท็ม ผู้เล่น และศัตรูที่ตรวจพบ\n• แจ้งเตือนศัตรูพร้อมระยะ\n• เก็บของและโต้ตอบเมื่ออยู่ใกล้\n• เคลื่อนที่ แสง หมอก และมุมมอง"]={en="• Doors, keys, books, fuses and objective labels\n• Detected hiding spots, items, players and enemies\n• Enemy alerts with distance\n• Nearby loot and interaction\n• Movement, lighting, fog and field of view",zh="• 门、钥匙、书、保险丝及目标标记\n• 检测藏身处、物品、玩家及敌人\n• 敌人距离提醒\n• 附近拾取及交互\n• 移动、光照、雾效及视野"},
    ["เข้าเล่นชั้นที่ต้องการก่อน แล้วรันโหลดเดอร์\nหลังเปลี่ยนเซิร์ฟเวอร์หรือกลับล็อบบี้ ให้รันใหม่\nทุกฟีเจอร์เริ่มเป็นปิด เลือกเปิดได้ตามต้องการ"]={en="Enter the desired floor before running the loader\nRerun after changing servers or returning to the lobby\nFeatures start disabled; enable what you need",zh="先进入目标楼层，再运行加载器\n更换服务器或返回大厅后重新运行\n功能默认关闭，请按需开启"},
    ["ยังไม่ได้ทดสอบในเซิร์ฟเวอร์จริง\nตรวจได้เฉพาะสิ่งที่เกมโหลดให้เครื่องนี้\nการแจ้งเตือนอาจไม่ครอบคลุมทุกศัตรูหรือทุกเหตุการณ์"]={en="Not tested on a live server\nOnly sees objects loaded on this client\nAlerts may not cover every enemy or event",zh="尚未在实际服务器测试\n仅检测本机已加载的内容\n提醒可能无法覆盖所有敌人或事件"},
    ["ดูประตูและไอเท็ม →"]={en="View doors and items →",zh="查看门及物品 →"},
    ["DOORS เป็นผลงานของ LSPLASH\nSATURN X เป็นเมนูแยกที่สร้างตามแนวคิดของ BM"]={en="DOORS is created by LSPLASH\nSATURN X is a separate menu based on BM's concept",zh="DOORS 由 LSPLASH 制作\nSATURN X 是根据 BM 构思制作的独立菜单"},
    ["กำลังอ่านข้อมูลห้อง…"]={en="Reading room information…",zh="正在读取房间信息…"},
    ["ป้ายประตูใช้หมายเลขห้องของโมเดลในเกม\nรายการแสดงเฉพาะจุดที่โหลดอยู่ในรัศมี\nป้ายที่ซ่อนไม่ได้ยืนยันว่ามีที่ว่างหรือใช้ได้ในตอนนี้"]={en="Door labels use room numbers from game models\nLists only loaded points within range\nHiding spot labels do not guarantee availability or usability",zh="门标记使用游戏模型中的房间编号\n仅显示范围内已加载的地点\n藏身处标记不保证目前有空位或可以使用"},
    ["ป้ายและไฮไลต์ประตู"]={en="Door labels and highlights",zh="门的标记及高亮"},
    ["กุญแจ / หนังสือ / ฟิวส์ / จุดสำคัญ"]={en="Keys / Books / Fuses / Objectives",zh="钥匙 / 书 / 保险丝 / 目标"},
    ["ป้ายไอเท็มและกองทองที่ตรวจพบ"]={en="Detected item and gold labels",zh="检测到的物品及金币标记"},
    ["ป้ายตู้และจุดซ่อนที่ตรวจพบ"]={en="Detected closets and hiding spots",zh="检测到的柜子及藏身处"},
    ["ระยะป้าย (studs)"]={en="Label range (studs)",zh="标记范围（studs）"},
    ["กรองชื่อ เช่น Key / กุญแจ / Book"]={en="Filter names, e.g. Key / Book",zh="筛选名称，例如 Key / Book"},
    ["อ่านรายการห้องใหม่"]={en="Rescan rooms",zh="重新扫描房间"},
    ["กำลังอัปเดตสิ่งที่โหลดอยู่ในด่าน"]={en="Refreshing loaded level objects",zh="正在刷新关卡中已加载的物体"},
    ["กำลังรอข้อมูล…"]={en="Waiting for data…",zh="等待数据…"},
    ["ตรวจชื่อโมเดล เช่น Rush, Ambush, Eyes และ Figure\nการตรวจพบไม่ได้แปลว่าศัตรูกำลังโจมตีทันที\nเสียงเตือนใช้เสียงคลิกของ SATURN X"]={en="Detects model names such as Rush, Ambush, Eyes and Figure\nDetection does not mean an immediate attack\nAlerts use SATURN X's click sound",zh="检测 Rush、Ambush、Eyes、Figure 等模型名称\n发现敌人不表示马上受到攻击\n提醒使用 SATURN X 的点击音效"},
    ["ไฮไลต์ศัตรูที่ตรวจพบ"]={en="Highlight detected enemies",zh="高亮检测到的敌人"},
    ["แจ้งเตือนเมื่อศัตรูเข้ารัศมี"]={en="Alert when enemies enter range",zh="敌人进入范围时提醒"},
    ["เสียงคลิกพร้อมการแจ้งเตือน"]={en="Click sound with alerts",zh="提醒时播放点击音效"},
    ["รัศมีแจ้งเตือน (studs)"]={en="Alert radius (studs)",zh="提醒范围（studs）"},
    ["ยังไม่มีการแจ้งเตือน"]={en="No alerts yet",zh="暂无提醒"},
    ["ล้างประวัติแจ้งเตือน"]={en="Clear alert history",zh="清除提醒记录"},
    ["ล้างประวัติแล้ว"]={en="History cleared",zh="记录已清除"},
    ["กดปุ่มที่เกมเปิดให้ใช้ โดยคงระยะและเวลากดค้าง\nระบบอัตโนมัติลองแต่ละปุ่มครั้งเดียวจนกว่าจะเปิดใหม่\nจำนวนครั้งที่กดไม่ใช่จำนวนเก็บสำเร็จ"]={en="Uses available game prompts, respecting range and hold time\nAutomatic mode tries each prompt once until restarted\nPress counts are not confirmed pickups",zh="使用游戏提供的按钮，保留距离及长按时间要求\n自动模式每个按钮尝试一次，重新开启后重试\n按键次数不代表成功拾取数"},
    ["เก็บของใกล้ตัวอัตโนมัติ (ทดลอง)"]={en="Auto-collect nearby items (experimental)",zh="自动拾取附近物品（实验）"},
    ["รวมปุ่มเปิดลิ้นชัก / กล่อง"]={en="Include drawers / boxes",zh="包括抽屉 / 箱子"},
    ["รวมคันโยก / ฟิวส์ / ปลดล็อก"]={en="Include levers / fuses / locks",zh="包括拉杆 / 保险丝 / 解锁"},
    ["การปลดล็อกใช้ระบบของเกม และอาจใช้กุญแจหรืออุปกรณ์ที่ถืออยู่"]={en="Unlocking uses the game's system and may consume equipped keys or tools",zh="解锁使用游戏机制，可能消耗已装备的钥匙或工具"},
    ["ระยะโต้ตอบสูงสุด (studs)"]={en="Maximum interaction range (studs)",zh="最大交互距离（studs）"},
    ["กดปุ่มเก็บ / โต้ตอบที่ใกล้ที่สุด"]={en="Use nearest collect / interaction prompt",zh="使用最近的拾取 / 交互按钮"},
    ["ยังไม่มีปุ่มที่ใช้ได้ในระยะ • ลองเข้าใกล้และมองไปที่ของ"]={en="No usable prompt in range • Move closer and look at the item",zh="范围内没有可用按钮 • 请靠近并看向物品"},
    ["ล้างรายการที่ลองแล้ว"]={en="Clear attempted prompt list",zh="清除已尝试按钮列表"},
    ["พร้อมลองเก็บใหม่แล้ว"]={en="Ready to try collecting again",zh="可以重新尝试拾取"},
    ["หยุดกด / หยุดเก็บ"]={en="Stop pressing / collecting",zh="停止按键 / 拾取"},
    ["ระบบโต้ตอบเริ่มเป็นปิด"]={en="Interaction is off by default",zh="交互功能默认关闭"},
    ["เกมอาจปรับความเร็วกลับหรือย้อนตำแหน่ง\nบิน: จอยมือถือหรือ WASD • ↑↓ หรือ Space / Ctrl"]={en="The server may reset speed or position\nFlight: joystick or WASD • ↑↓ or Space / Ctrl",zh="服务器可能重置速度或位置\n飞行：摇杆或 WASD • ↑↓ 或空格 / Ctrl"},
    ["ปิด SATURN X DOORS"]={en="Close SATURN X DOORS",zh="关闭 SATURN X DOORS"},
    ["ล็อบบี้"]={en="Lobby",zh="大厅"},
    ["ชั้น "]={en="Floor ",zh="楼层 "},
    ["%s\nห้องล่าสุดของรอบ: %s\nห้องล่าสุดอาจอยู่ไกลกว่าตำแหน่งของคุณ"]={en="%s\nLatest room this round: %s\nThe latest room may be ahead of your position",zh="%s\n本回合最新房间：%s\n最新房间可能在你前方较远的位置"},
    ["HP %.0f / %.0f\n%s • ผู้เล่น %d\nFPS %.0f"]={en="HP %.0f / %.0f\n%s • Players %d\nFPS %.0f",zh="生命值 %.0f / %.0f\n%s • 玩家 %d\nFPS %.0f"},
    ["ตรวจพบโมเดลศัตรูที่โหลดอยู่ "]={en="Loaded enemy models detected: ",zh="已检测到的敌人模型： "},
    [" รายการ"]={en=" entries",zh=" 项"},
    ["แจ้งเตือนล่าสุด: "]={en="Latest alert: ",zh="最新提醒： "},
    ["%s • ส่งการกด %d ครั้ง\nดูผลการเก็บจากเกม"]={en="%s • %d presses sent\nCheck the game for pickup results",zh="%s • 已发送 %d 次按键\n拾取结果请在游戏中确认"},
    ["กำลังกดค้าง"]={en="Holding the button",zh="正在长按"},
    ["รอปุ่มที่ใช้ได้ใกล้ตัว"]={en="Waiting for a nearby usable prompt",zh="等待附近可用的按钮"},
    ["หยุดอยู่"]={en="Stopped",zh="已停止"},
    ["เปิด UI ได้ แต่แมพนี้ไม่ใช่ DOORS ของ LSPLASH"]={en="Menu available, but this is not DOORS by LSPLASH",zh="菜单可用，但当前不是 LSPLASH 的 DOORS"},
    ["ปิดอยู่"]={en="Off",zh="已关闭"},
    ["ช่วยเล็ง"]={en="Aim helper",zh="瞄准辅助"},
    ["ผู้เล่น / บอท"]={en="Players / Bots",zh="玩家 / 机器人"},
    ["เป้า / กล้อง"]={en="Crosshair / Camera",zh="准星 / 相机"},
    ["แมพนี้ไม่ใช่ Hypershot • เปิดได้เฉพาะเมนู"]={en="This is not Hypershot • Menu only",zh="当前不是 Hypershot • 仅能打开菜单"},
    ["ไม่พบกล้อง"]={en="Camera not found",zh="未找到相机"},
    ["พัก: เมนู / สลับหน้าต่าง"]={en="Paused: menu / window unfocused",zh="已暂停：菜单打开 / 窗口失去焦点"},
    ["พัก: ย่อเมนูเพื่อเริ่ม"]={en="Paused: minimize the menu to start",zh="已暂停：最小化菜单以开始"},
    ["พัก: กำลังบิน"]={en="Paused: flying",zh="已暂停：飞行中"},
    ["รอเกิดใหม่"]={en="Waiting to respawn",zh="等待重生"},
    ["กำลังหาเป้าในวง"]={en="Searching within the aim circle",zh="正在瞄准圈内搜索"},
    ["กำลังเล็ง"]={en="Aiming",zh="瞄准中"},
    ["ผู้เล่น"]={en="Player",zh="玩家"},
    ["บอท / NPC"]={en="Bot / NPC",zh="机器人 / NPC"},
    ["พบ %d ตัวในรัศมี • ตรวจ %d วัตถุ%s\nสีเขียว = ตรวจพบทีมเดียวกัน • ไม่ทราบ HP แสดง ?"]={en="Found %d characters in range • Checked %d objects%s\nGreen = detected teammate • Unknown HP shows ?",zh="范围内发现 %d 个角色 • 检查 %d 个对象%s\n绿色＝检测到的队友 • 未知生命值显示 ?"},
    ["• ช่วยเล็งผู้เล่นและบอท เปลี่ยนเป้าอัตโนมัติ\n• กรองทีม สิ่งกีดขวาง และเกราะเกิด\n• ป้ายชื่อ HP ระยะ และไฮไลต์\n• เป้ากากบาท วงเล็ง ปุ่มมือถือ และปรับการเคลื่อนที่"]={en="• Player and bot aiming with automatic target changes\n• Team, obstacle and spawn-shield filters\n• Names, HP, distances and highlights\n• Crosshair, aim circle, mobile button and movement settings",zh="• 玩家及机器人瞄准，自动切换目标\n• 队伍、障碍及出生保护筛选\n• 名称、生命值、距离及高亮\n• 准星、瞄准圈、手机按钮及移动设置"},
    ["เปิดช่วยเล็งในหมวด 4 แล้วกดย่อเมนู\nแตะปุ่ม ○ / ● เพื่อเปิด–ปิด • ลากปุ่มเพื่อย้าย\nRight Shift เปิดเมนู • Q สลับเล็ง • End หยุดฟีเจอร์\nหลังเปลี่ยนเซิร์ฟเวอร์ให้รันใหม่"]={en="Enable aiming in tab 4, then minimize\nTap ○ / ● to toggle • Drag to move\nRight Shift: menu • Q: aim toggle • End: stop features\nRerun after changing servers",zh="分类 4 开启瞄准后最小化\n点击 ○ / ● 切换 • 拖动按钮移动\n右 Shift：菜单 • Q：切换瞄准 • End：停止功能\n更换服务器后重新运行"},
    ["รุ่นทดลอง ยังไม่ได้ทดสอบในเกมจริง\nระบบเล็งหมุนกล้องตามเป้า ผลขึ้นกับระบบกล้องและอาวุธของเกม"]={en="Beta; not tested live\nAiming rotates the camera toward a target; results depend on the game's camera and weapon systems",zh="测试版，尚未实测\n辅助通过旋转相机瞄准目标，效果取决于游戏的相机及武器系统"},
    ["ไปหมวดช่วยเล็ง →"]={en="Go to aim helper →",zh="前往瞄准辅助 →"},
    ["Hypershot เป็นผลงานของ Frosted Studio\nSATURN X เป็นเมนูแยกที่สร้างตามแนวคิดของ BM"]={en="Hypershot is created by Frosted Studio\nSATURN X is a separate menu based on BM's concept",zh="Hypershot 由 Frosted Studio 制作\nSATURN X 是根据 BM 构思制作的独立菜单"},
    ["ช่วยเล็งเริ่มเป็นปิด"]={en="Aim helper is off by default",zh="瞄准辅助默认关闭"},
    ["เปิดช่วยเล็งแล้วกดย่อเมนู • ปุ่ม ○ / ● หรือ Q ใช้สลับเปิด/ปิด\nเลือกเป้าที่อยู่ในวง แล้วเปลี่ยนเมื่อเป้าตาย หาย หรือถูกบัง\nใช้ปุ่มยิงของเกมตามปกติ"]={en="Enable aiming, then minimize • ○ / ● or Q toggles it\nSelects targets inside the circle; changes when dead, missing or blocked\nUse the game's normal fire button",zh="开启瞄准后最小化 • ○ / ● 或 Q 切换开关\n选择圈内目标，死亡、消失或被遮挡时切换\n请正常使用游戏的射击按钮"},
    ["ถ้าเล่น Free for All แล้วไม่พบเป้า ลองปิดกรองทีม\nบอทต้องมีโครงตัวละครที่อ่านได้\nการเล็งกล้องไม่ได้ยืนยันว่ากระสุนถูกเป้า"]={en="In Free for All, try disabling team filtering if no targets appear\nBots need a readable character rig\nCamera aiming does not confirm bullet hits",zh="自由混战模式找不到目标时，可尝试关闭队伍筛选\n机器人需要可读取的角色骨架\n相机瞄准并不保证子弹命中"},
    ["เปิดช่วยเล็ง"]={en="Enable aim helper",zh="开启瞄准辅助"},
    ["แมพนี้ไม่ใช่ Hypershot ครับ"]={en="This map is not Hypershot",zh="当前地图不是 Hypershot"},
    ["ปิดตัวช่วย BM XY เดิมก่อน เพื่อไม่ให้กล้องแย่งกันครับ"]={en="Close the old BM XY helper to avoid camera conflicts",zh="请先关闭旧 BM XY 辅助，避免相机控制冲突"},
    ["ย่อเมนูเพื่อเริ่ม"]={en="Minimize to start",zh="最小化以开始"},
    ["รวมผู้เล่น"]={en="Include players",zh="包括玩家"},
    ["รวมบอท / NPC"]={en="Include bots / NPCs",zh="包括机器人 / NPC"},
    ["ข้ามเพื่อนร่วมทีม"]={en="Skip teammates",zh="跳过队友"},
    ["ตรวจสิ่งกีดขวาง"]={en="Check obstacles",zh="检查障碍物"},
    ["ข้ามตัวที่มีเกราะเกิด"]={en="Skip spawn-shielded characters",zh="跳过出生保护中的角色"},
    ["ค้างเป้าเดิมจนใช้ไม่ได้"]={en="Keep target until unavailable",zh="保持当前目标直到失效"},
    ["เล็งลำตัวแทนหัว"]={en="Aim at torso instead of head",zh="瞄准躯干而非头部"},
    ["รัศมีวงช่วยเล็ง (พิกเซล)"]={en="Aim-circle radius (pixels)",zh="瞄准圈半径（像素）"},
    ["ระยะเล็งสูงสุด (studs)"]={en="Maximum aim range (studs)",zh="最大瞄准距离（studs）"},
    ["ความนุ่ม (0 = ล็อกทันที)"]={en="Smoothing (0 = instant)",zh="平滑程度（0＝立即锁定）"},
    ["ปิดตัวช่วย BM XY เดิม"]={en="Close old BM XY helper",zh="关闭旧 BM XY 辅助"},
    ["ปิด BM XY เดิมแล้ว"]={en="Old BM XY closed",zh="旧 BM XY 已关闭"},
    ["ไม่พบตัวช่วย BM XY เดิมที่รองรับ"]={en="No supported old BM XY helper found",zh="未找到支持关闭的旧 BM XY"},
    ["ป้ายแสดงเฉพาะตัวที่เกมโหลดให้เครื่องนี้\nชื่อและพลังชีวิตอ่านจากตัวละครที่ตรวจพบ\nสีเขียวใช้ข้อมูลทีมที่อ่านได้ อาจต้องปิดกรองทีมในโหมด FFA"]={en="Labels show characters loaded on this client\nNames and HP come from detected characters\nGreen uses available team data; FFA may need team filtering off",zh="仅标记本机已加载的角色\n名字及生命值读取自检测到的角色\n绿色依据可读取的队伍数据，混战模式可能需要关闭队伍筛选"},
    ["ป้ายและไฮไลต์ผู้เล่น"]={en="Player labels and highlights",zh="玩家标记及高亮"},
    ["ป้ายและไฮไลต์บอท / NPC"]={en="Bot / NPC labels and highlights",zh="机器人 / NPC 标记及高亮"},
    ["แมพนี้ไม่ใช่ Hypershot"]={en="This map is not Hypershot",zh="当前地图不是 Hypershot"},
    ["แสดงป้ายและไฮไลต์ผ่านสิ่งกีดขวาง"]={en="Show labels and highlights through obstacles",zh="透过障碍显示标记及高亮"},
    ["กรองชื่อผู้เล่นหรือบอท"]={en="Filter player or bot names",zh="筛选玩家或机器人名称"},
    ["อ่านตัวละครที่โหลดอยู่ใหม่"]={en="Rescan loaded characters",zh="重新扫描已加载角色"},
    ["เปิดหมวดนี้เพื่ออ่านตัวละคร…"]={en="Open this tab to read characters…",zh="打开此分类以读取角色…"},
    ["ใช้ได้เมื่ออ่านระบบเดินของตัวละครได้\nเกมอาจปรับความเร็วกลับหรือย้อนตำแหน่ง\nบิน: จอยมือถือหรือ WASD • ↑↓ หรือ Space / Ctrl\nช่วยเล็งพักระหว่างบิน"]={en="Requires a readable character movement system\nThe game may reset speed or position\nFlight: joystick or WASD • ↑↓ or Space / Ctrl\nAiming pauses during flight",zh="需要可读取的角色移动系统\n游戏可能重置速度或位置\n飞行：摇杆或 WASD • ↑↓ 或空格 / Ctrl\n飞行期间暂停瞄准"},
    ["วงช่วยเล็งและเป้ากากบาทอยู่กลางภาพเกม\nวงจะเล็กลงอัตโนมัติเมื่อจอไม่พอ\nปุ่มเล็งลอยลากย้ายได้ และแสดงเมื่อย่อเมนู"]={en="Aim circle and crosshair stay at screen center\nThe circle shrinks to fit small screens\nThe draggable aim button appears when the menu is minimized",zh="瞄准圈和准星位于画面中心\n屏幕不足时自动缩小瞄准圈\n菜单最小化时显示可拖动瞄准按钮"},
    ["แสดงวงช่วยเล็ง"]={en="Show aim circle",zh="显示瞄准圈"},
    ["แสดงเป้ากากบาท"]={en="Show crosshair",zh="显示准星"},
    ["ปุ่มเล็งลอย ○ / ●"]={en="Floating aim button ○ / ●",zh="悬浮瞄准按钮 ○ / ●"},
    ["แสดงชื่อเป้าที่กำลังเล็ง"]={en="Show current target name",zh="显示当前目标名称"},
    ["ขนาดเส้นเป้า"]={en="Crosshair line size",zh="准星线条大小"},
    ["ช่องว่างกลางเป้า"]={en="Crosshair center gap",zh="准星中心间距"},
    ["คืนมุมมองกล้องเดิม"]={en="Restore original field of view",zh="还原原始相机视野"},
    ["คืนมุมมองที่บันทึกไว้แล้ว"]={en="Saved field of view restored",zh="已还原保存的相机视野"},
    ["ถ้าหาเป้าหรือเล็งไม่ได้ ส่งภาพรายงานนี้มาได้ครับ"]={en="If target search or aiming fails, send a screenshot of this report",zh="若搜索或瞄准失效，可发送此报告截图"},
    ["ปิด SATURN X HYPERSHOT"]={en="Close SATURN X HYPERSHOT",zh="关闭 SATURN X HYPERSHOT"},
    ["พัก: เมนู Roblox"]={en="Paused: Roblox menu",zh="已暂停：Roblox 菜单"},
    ["หาเป้าใหม่"]={en="Find a new target",zh="寻找新目标"},
    ["หยุด: เกิดข้อผิดพลาด"]={en="Stopped: error occurred",zh="已停止：发生错误"},
    ["ช่วยเล็งหยุดแล้ว • ดูรายงานหมวด 8"]={en="Aim helper stopped • See tab 8 report",zh="瞄准辅助已停止 • 查看分类 8 报告"},
    ["พลังชีวิต %s\nทีม %s • ผู้เล่น %d\nFPS %.0f • อ่านตัวละคร: %s"]={en="Health %s\nTeam %s • Players %d\nFPS %.0f • Character readable: %s",zh="生命值 %s\n队伍 %s • 玩家 %d\nFPS %.0f • 可读取角色：%s"},
    ["ยังอ่านไม่ได้"]={en="Not readable yet",zh="暂时无法读取"},
    ["ไม่ระบุ"]={en="Unspecified",zh="未指定"},
    ["ไม่มีกล้อง"]={en="No camera",zh="无相机"},
    ["ใช้งานครั้งนี้ %02d:%02d:%02d\nได้เป้า %d ครั้ง (ไม่ใช่จำนวนยิงโดนหรือกำจัด)"]={en="Session %02d:%02d:%02d\nTargets acquired %d (not hits or eliminations)",zh="本次使用 %02d:%02d:%02d\n获取目标 %d 次（不代表命中或淘汰数）"},
    ["สถานะ: %s\nเป้า: %s\nการค้นหาล่าสุด: ผู้เล่น %d • บอท %d"]={en="Status: %s\nTarget: %s\nLast search: players %d • Bots %d",zh="状态：%s\n目标：%s\n最近搜索：玩家 %d • 机器人 %d"},
    ["เปิด UI ได้ แต่แมพนี้ไม่ใช่ Hypershot"]={en="Menu available, but this map is not Hypershot",zh="菜单可用，但当前地图不是 Hypershot"},
    ["ใส่รหัสท่าแล้วกดเล่น"]={en="Enter an animation ID, then press Play",zh="输入动作 ID，然后点击播放"},
    ["ใส่รหัส / เล่นท่า"]={en="Enter ID / Play",zh="输入 ID / 播放"},
    ["ท่าโปรด"]={en="Favorites",zh="收藏动作"},
    ["ปรับการเล่น"]={en="Playback",zh="播放设置"},
    ["ท่าในตัวละคร"]={en="Character animations",zh="角色中的动作"},
    ["เสียง / ตั้งค่า"]={en="Audio / Settings",zh="音频 / 设置"},
    ["รหัสหรือลิงก์ยาวเกินไป"]={en="ID or link is too long",zh="ID 或链接过长"},
    ["Animation ID ไม่ถูกต้อง"]={en="Invalid Animation ID",zh="动作 ID 无效"},
    ["ลิงก์ Catalog เป็นรหัสสินค้า • ต้องใช้ Animation ID ของท่านั้น"]={en="Catalog links are product IDs • Use the animation's Animation ID",zh="商品链接是商品 ID • 请使用动作的 Animation ID"},
    ["ใส่เลข Animation ID หรือ rbxassetid://ตามด้วยเลขครับ"]={en="Enter a numeric Animation ID or rbxassetid:// followed by digits",zh="请输入数字动作 ID，或 rbxassetid:// 后接数字"},
    ["ไม่พบ"]={en="Not found",zh="未找到"},
    ["ยังไม่พบตัวละครที่พร้อมเล่นท่า"]={en="No character ready to play an animation",zh="没有可播放动作的角色"},
    ["ตัวละครนี้ยังไม่มีระบบ Animator ที่รองรับ"]={en="This character has no supported Animator",zh="当前角色没有支持的 Animator"},
    ["หยุดแล้ว"]={en="Stopped",zh="已停止"},
    [" • ยังเล่นท่าเดิม"]={en=" • Previous animation continues",zh=" • 仍播放原动作"},
    ["ท่าระบุ "]={en="Animation rig is ",zh="动作骨架为 "},
    [" แต่ตัวละครเป็น "]={en=" but the character is ",zh=" ，但角色为 "},
    ["หยุดเดินก่อนเล่นท่า หรือปิดหยุดเมื่อเดินในหมวด 6"]={en="Stop walking first, or disable Stop on movement in tab 6",zh="请先停止移动，或在分类 6 关闭“移动时停止”"},
    ["ท่า "]={en="Animation ",zh="动作 "},
    ["กำลังโหลด "]={en="Loading ",zh="正在加载 "},
    ["โหลดท่าไม่สำเร็จ • ตรวจรหัส สิทธิ์ และชนิดตัวละคร"]={en="Animation failed to load • Check ID, permissions and rig",zh="动作加载失败 • 请检查 ID、权限及骨架类型"},
    ["ยกเลิก: ตัวละครเปลี่ยนแล้ว"]={en="Cancelled: character changed",zh="已取消：角色已更换"},
    ["กำลังโหลดท่าใหม่"]={en="Loading a new animation",zh="正在加载新动作"},
    ["เล่นจบแล้ว"]={en="Playback finished",zh="播放结束"},
    ["หยุด: ตัวละครตาย"]={en="Stopped: character died",zh="已停止：角色死亡"},
    ["กำลังเล่น "]={en="Playing ",zh="正在播放 "},
    ["หยุด: เล่นท่านี้ไม่ได้"]={en="Stopped: this animation cannot play",zh="已停止：无法播放此动作"},
    ["โหลดท่านี้ไม่ได้ • ตรวจ Animation ID และสิทธิ์"]={en="Cannot load animation • Check Animation ID and permissions",zh="无法加载动作 • 请检查动作 ID 及权限"},
    ["ยังไม่มีท่าที่กำลังเล่น"]={en="No animation is playing",zh="当前没有播放中的动作"},
    ["พักหรือเล่นต่อไม่ได้ครับ"]={en="Cannot pause or resume",zh="无法暂停或继续"},
    ["พักไว้: "]={en="Paused: ",zh="已暂停： "},
    ["เล่นท่าก่อนเลื่อนตำแหน่งครับ"]={en="Play an animation before seeking",zh="请先播放动作再跳转"},
    ["ใส่ตำแหน่งตั้งแต่ 0 ถึง 100"]={en="Enter a position from 0 to 100",zh="请输入 0 至 100 的位置"},
    ["รูปแบบไฟล์ไม่ถูกต้อง"]={en="Invalid file format",zh="文件格式无效"},
    ["รายการท่าไม่ถูกต้อง"]={en="Invalid animation list",zh="动作列表无效"},
    ["รายการท่าไม่ต่อเนื่อง"]={en="Animation list is not contiguous",zh="动作列表不连续"},
    ["รหัสหรือชื่อท่าไม่ถูกต้อง"]={en="Invalid animation ID or name",zh="动作 ID 或名称无效"},
    ["ชนิดตัวละครไม่ถูกต้อง"]={en="Invalid character rig type",zh="角色骨架类型无效"},
    ["มีท่าซ้ำในไฟล์"]={en="Duplicate animations in file",zh="文件中有重复动作"},
    ["ชนิดท่าไม่ถูกต้อง"]={en="Invalid animation type",zh="动作类型无效"},
    ["ชื่อท่ายาวเกินไปครับ"]={en="Animation name is too long",zh="动作名称过长"},
    ["อัปเดตชื่อท่าโปรดแล้ว"]={en="Favorite name updated",zh="收藏动作名称已更新"},
    ["ท่าโปรดครบ "]={en="Favorite limit reached: ",zh="收藏已达上限： "},
    [" ท่าแล้ว"]={en=" animations",zh=" 个动作"},
    ["เพิ่มท่าโปรดแล้ว"]={en="Added to favorites",zh="已加入收藏"},
    ["เกมนี้ไม่แสดงรายการท่าในตัวละคร"]={en="This game does not expose character animations",zh="此游戏未提供角色动作列表"},
    ["อ่านรายการบางส่วน"]={en="Partial list read",zh="已读取部分列表"},
    ["อ่านจากตัวละครปัจจุบัน"]={en="Read from the current character",zh="读取自当前角色"},
    ["ใส่รหัสท่า → กดเล่น → เต้นบนตัวละครของเรา\nดาวเสาร์สีเงิน เสียง และเมนู 8 หมวดของ BM"]={en="Enter ID → Press Play → Animate your character\nSilver Saturn, sounds and BM's 8-tab menu",zh="输入 ID → 点击播放 → 让角色播放动作\n银色土星、音效及 BM 的 8 分类菜单"},
    ["• เล่น หยุด พัก และเล่นต่อ\n• ปรับความเร็ว เล่นวน และเลื่อนตำแหน่งท่า\n• บันทึกท่าโปรดได้ 24 ท่า\n• อ่านท่าที่มีในตัวละครและใช้ปุ่มลอยบนมือถือ"]={en="• Play, stop, pause and resume\n• Speed, looping and seeking\n• Up to 24 favorites\n• Read character animations and use mobile quick controls",zh="• 播放、停止、暂停及继续\n• 速度、循环及进度跳转\n• 最多收藏 24 个动作\n• 读取角色动作，支持手机快捷按钮"},
    ["ใช้ Animation ID ของท่า ไม่ใช่รหัสสินค้า Catalog\nท่าต้องเข้ากับตัวละครและเกมต้องมีสิทธิ์โหลด\nคนอื่นจะเห็นหรือไม่ขึ้นกับระบบของเกม\nรุ่นนี้ยังไม่ได้ทดสอบในเกมจริง"]={en="Use Animation IDs, not Catalog product IDs\nAnimations must match the rig and be permitted in the game\nVisibility to others depends on the game's system\nThis version has not been tested live",zh="请使用动作 ID，而非商城商品 ID\n动作必须匹配角色骨架，且游戏有权加载\n其他人能否看到取决于游戏系统\n此版本尚未在实际游戏中测试"},
    ["ไปใส่รหัสท่า →"]={en="Enter an animation ID →",zh="前往输入动作 ID →"},
    ["ท่าที่นำมาเล่นเป็นผลงานของเจ้าของแอนิเมชันแต่ละท่า"]={en="Animations belong to their respective creators",zh="动作版权归各自创作者所有"},
    ["ชื่อ รูป และชนิดตัวละครปัจจุบัน"]={en="Current name, avatar and character rig",zh="当前名字、头像及角色骨架"},
    ["ชนิดท่า: "]={en="Rig: ",zh="骨架： "},
    ["บันทึก %d / %d ท่า • แตะชื่อเพื่อเลือก"]={en="Saved %d / %d animations • Tap a name to select",zh="已保存 %d / %d 个动作 • 点击名称选择"},
    ["พบ %d ท่า • %s\nแตะชื่อเพื่อใส่รหัส แล้วกดเล่นในหมวด 4"]={en="Found %d animations • %s\nTap a name to fill the ID, then play in tab 4",zh="发现 %d 个动作 • %s\n点击名称填入 ID，然后在分类 4 播放"},
    ["ใส่รหัสแล้ว • กดเล่นท่าได้เลยครับ"]={en="ID entered • You can press Play now",zh="ID 已填入 • 可以点击播放"},
    ["Animation ID หรือ rbxassetid://…"]={en="Animation ID or rbxassetid://…",zh="动作 ID 或 rbxassetid://…"},
    ["ชื่อท่า (ตั้งเองได้)"]={en="Animation name (optional)",zh="动作名称（可自定义）"},
    ["ชนิดท่า: ไม่ระบุ  ›"]={en="Rig: Unspecified  ›",zh="骨架：未指定  ›"},
    ["ถ้ารู้ว่าท่าใช้กับ R6 หรือ R15 ให้เลือกชนิดให้ตรง\nไม่ระบุ = ลองโหลดกับตัวละครปัจจุบัน\nหากยังไม่มีรหัส ลองเลือกท่าในหมวด 7"]={en="Choose R6 or R15 if you know the animation's rig\nUnspecified = try the current character\nNo ID? Try the animations in tab 7",zh="已知动作骨架时，请选择 R6 或 R15\n未指定＝尝试当前角色\n没有 ID 时，可尝试分类 7 中的动作"},
    ["▶  เล่นท่า"]={en="▶  Play animation",zh="▶  播放动作"},
    ["Ⅱ  พัก / เล่นต่อ"]={en="Ⅱ  Pause / Resume",zh="Ⅱ  暂停 / 继续"},
    ["เล่นท่าก่อนครับ"]={en="Play an animation first",zh="请先播放动作"},
    ["■  หยุด / ยกเลิกโหลด"]={en="■  Stop / Cancel loading",zh="■  停止 / 取消加载"},
    ["♡  เพิ่มท่านี้ในรายการโปรด"]={en="♡  Add this animation to favorites",zh="♡  收藏此动作"},
    ["ย่อเมนูเพื่อดูตัวละคร"]={en="Minimize to view your character",zh="最小化以查看角色"},
    ["แตะชื่อแล้วกดเล่นได้ทันที\nกดบันทึกลงเครื่องเพื่อเก็บไว้ใช้ครั้งหน้าเมื่อเครื่องรองรับ"]={en="Tap a name, then play\nSave to this device to reuse next time, when file access is supported",zh="点击名称后即可播放\n支持文件访问时，可保存到本机供下次使用"},
    ["ยังไม่มีท่าโปรด"]={en="No favorite animations yet",zh="尚无收藏动作"},
    ["เล่นท่าโปรดที่เลือก"]={en="Play selected favorite",zh="播放所选收藏动作"},
    ["เลือกท่าโปรดก่อนครับ"]={en="Select a favorite first",zh="请先选择收藏动作"},
    ["ลบท่าโปรดที่เลือก"]={en="Delete selected favorite",zh="删除所选收藏动作"},
    ["บันทึกรายการลงเครื่อง"]={en="Save list to this device",zh="将列表保存到本机"},
    ["บันทึกท่าโปรดแล้ว"]={en="Favorites saved",zh="收藏已保存"},
    ["โหลดรายการที่บันทึกไว้"]={en="Load saved list",zh="加载保存的列表"},
    ["ยังไม่มีไฟล์ท่าโปรดที่บันทึกไว้"]={en="No saved favorites file yet",zh="尚无已保存的收藏文件"},
    ["ไฟล์ไม่ถูกต้องหรือใหญ่เกินไป"]={en="Invalid or oversized file",zh="文件无效或过大"},
    ["ความเร็วท่า (เท่า)"]={en="Playback speed (×)",zh="播放速度（倍）"},
    ["เวลาเฟดเข้า / ออก (วินาที)"]={en="Fade in / out time (seconds)",zh="淡入 / 淡出时间（秒）"},
    ["เล่นวนซ้ำ"]={en="Loop playback",zh="循环播放"},
    ["หยุดท่าเมื่อเดิน"]={en="Stop animation on movement",zh="移动时停止动作"},
    ["ตำแหน่งในท่า 0–100%"]={en="Animation position 0–100%",zh="动作进度 0–100%"},
    ["เลื่อนไปตำแหน่งที่ใส่"]={en="Seek to entered position",zh="跳转到输入的位置"},
    ["ย้อน 5%"]={en="Back 5%",zh="后退 5%"},
    ["เดินหน้า 5%"]={en="Forward 5%",zh="前进 5%"},
    ["กลับไปเริ่มท่า"]={en="Restart animation",zh="从头播放动作"},
    ["พักท่าเพื่อค้างท่าทาง แล้วเลื่อนตำแหน่งได้\nหยุดท่าจะคืนการควบคุมให้แอนิเมชันของเกม"]={en="Pause to hold a pose, then adjust the position\nStopping returns control to the game's animations",zh="暂停可保持姿势，再调整进度\n停止后由游戏原本的动画恢复控制"},
    ["อ่านรหัสที่อยู่ในตัวละครปัจจุบัน เช่น dance / emote\nบางเกมไม่ได้เปิดรายการนี้ให้เห็น หรือเก็บไว้รูปแบบอื่น"]={en="Reads animation IDs from the current character, such as dance / emote\nSome games hide this list or store it differently",zh="读取当前角色中的动作 ID，例如舞蹈或表情\n部分游戏隐藏列表或以其他方式存储"},
    ["รวมท่าเดิน วิ่ง และท่าอื่นด้วย"]={en="Include walk, run and other animations",zh="包括走路、跑步等动作"},
    ["อ่านรายการท่าใหม่"]={en="Rescan animations",zh="重新扫描动作"},
    ["กดอ่านรายการท่าเพื่อเริ่ม"]={en="Press Rescan animations to start",zh="点击重新扫描以开始"},
    ["แสดงปุ่มเล่น / หยุดเมื่อย่อเมนู"]={en="Show play / stop buttons when minimized",zh="最小化时显示播放 / 停止按钮"},
    ["เปิดปุ่มลัด P พัก/เล่นต่อ • X หยุด"]={en="Hotkeys: P pause/resume • X stop",zh="快捷键：P 暂停 / 继续 • X 停止"},
    ["โลโก้ขยับเบา ๆ"]={en="Gentle logo animation",zh="标志轻微动画"},
    ["สร้างรายงานตรวจท่า"]={en="Create animation diagnostic report",zh="生成动作诊断报告"},
    ["ถ้าท่าไม่เล่น ให้สร้างรายงานแล้วส่งภาพมาได้ครับ"]={en="If an animation fails, create a report and send a screenshot",zh="动作无法播放时，可生成报告并发送截图"},
    ["ปิด SATURN X DANCE"]={en="Close SATURN X DANCE",zh="关闭 SATURN X DANCE"},
    ["ยกเลิกโหลดแล้ว"]={en="Loading cancelled",zh="加载已取消"},
    ["ปิดแล้ว"]={en="Closed",zh="已关闭"},
    ["หยุด: ตัวละครเปลี่ยนแล้ว"]={en="Stopped: character changed",zh="已停止：角色已更换"},
    ["ตัวละครใหม่พร้อมแล้ว • เลือกท่าเพื่อเล่น"]={en="New character ready • Select an animation",zh="新角色已就绪 • 请选择动作"},
    ["หยุด: ตัวละครไม่พร้อม"]={en="Stopped: character not ready",zh="已停止：角色尚未就绪"},
    ["หยุดเมื่อเดิน"]={en="Stopped on movement",zh="因移动而停止"},
    ["\n%s • %.1f / %.1f วินาที • %.2fx"]={en="\n%s • %.1f / %.1f seconds • %.2fx",zh="\n%s • %.1f / %.1f 秒 • %.2f 倍"},
    ["พักไว้"]={en="Paused",zh="已暂停"},
    ["เล่นอยู่"]={en="Playing",zh="播放中"},
    ["ตัวละคร %s • HP %.0f\nโหลดท่าแล้ว %d ครั้ง\nผู้เล่นในเซิร์ฟเวอร์ %d"]={en="Rig %s • HP %.0f\nAnimations loaded %d times\nServer players %d",zh="骨架 %s • 生命值 %.0f\n动作加载 %d 次\n服务器玩家 %d"},
    ["ไอเท็ม / ดึงของ"]={en="Items / Pull",zh="物品 / 拉取"},
    ["ผู้เล่น / NPC"]={en="Players / NPCs",zh="玩家 / NPC"},
    ["แมพนี้ไม่ใช่ Dead Rails ของ RCM Games • เปิดได้เฉพาะเมนู"]={en="This is not Dead Rails by RCM Games • Menu only",zh="当前不是 RCM Games 的 Dead Rails • 仅能打开菜单"},
    ["ขาย"]={en="Sell",zh="出售"},
    ["สร้าง"]={en="Build",zh="建造"},
    ["อัปเกรด"]={en="Upgrade",zh="升级"},
    ["หยิบ"]={en="Pick up",zh="拾取"},
    ["แมพนี้ไม่ใช่ Dead Rails ของ RCM Games"]={en="This is not Dead Rails by RCM Games",zh="当前不是 RCM Games 的 Dead Rails"},
    ["อยู่ในล็อบบี้ • เข้าเล่นรอบ แล้วรันโหลดเดอร์อีกครั้งครับ"]={en="You are in the lobby • Enter a round, then rerun the loader",zh="当前在大厅 • 进入回合后重新运行加载器"},
    ["กำลังรอไอเท็มในด่านโหลด • ลองสแกนใหม่อีกครั้งครับ"]={en="Waiting for level items to load • Try scanning again",zh="等待关卡物品加载 • 请尝试重新扫描"},
    ["พบ %d ชิ้น • ตรวจของ %d / %d%s\nเลือกของเพื่อเดินไป กดเก็บ หรือทดลองดึง"]={en="Found %d items • Checked %d / %d%s\nSelect an item to walk to, collect or try pulling",zh="发现 %d 件物品 • 已检查 %d / %d%s\n选择物品后可前往、拾取或尝试拉取"},
    [" (ตรวจบางส่วน)"]={en=" (partial scan)",zh=" （部分扫描）"},
    ["มีระบบเก็บ"]={en="Pickup available",zh="有拾取功能"},
    ["ลาก/ยก"]={en="Drag / Lift",zh="拖动 / 搬起"},
    ["ชิ้นนี้เป็นของลาก/ยก • ใช้การลากหรือถุงของเกมครับ"]={en="This item requires dragging/lifting • Use the game's bag or controls",zh="此物品需要拖动或搬起 • 请使用游戏操作或袋子"},
    ["เข้าใกล้ของภายใน "]={en="Move within ",zh="请靠近至 "},
    [" studs ก่อนครับ"]={en=" studs first",zh=" studs 内"},
    ["ไม่พบระบบเก็บชนิดนี้ในเกมรุ่นปัจจุบัน • ใช้ปุ่มในเกมครับ"]={en="This pickup type is unsupported in the current game • Use its normal controls",zh="当前游戏不支持此拾取方式 • 请使用游戏原有操作"},
    ["ส่งคำขอเก็บแล้ว • ตรวจผลในเกม"]={en="Pickup requested • Check the result in game",zh="已请求拾取 • 请在游戏中确认结果"},
    ["ส่งคำขอเก็บไม่ได้"]={en="Pickup request failed",zh="拾取请求失败"},
    ["ต้องอยู่ในระยะปุ่มเก็บของที่เกมเปิดให้ใช้ก่อนครับ"]={en="Move within the range allowed by the game's pickup prompt first",zh="请先进入游戏拾取按钮允许的距离"},
    ["ปุ่มนี้ต้องกดค้างนาน ใช้ปุ่มในเกมโดยตรงครับ"]={en="This prompt requires a long hold; use the game button directly",zh="此按钮需要长按，请直接使用游戏按钮"},
    ["สิ้นสุดการกดปุ่มเก็บ • ตรวจผลในกระเป๋าของเกม"]={en="Pickup press finished • Check the game's inventory",zh="拾取按键结束 • 请查看游戏背包"},
    ["ส่งการกดเก็บไม่ได้"]={en="Could not send pickup input",zh="无法发送拾取输入"},
    ["ส่งคำสั่งดึง %d ชิ้น • ข้าม %d ชิ้น\nจำนวนนี้ไม่ใช่จำนวนเก็บสำเร็จ"]={en="Pull requests %d items • Skipped %d\nThese are not confirmed pickups",zh="拉取请求 %d 件 • 跳过 %d 件\n这些数字不代表成功拾取数"},
    ["ทดลองดึงแล้ว • ของที่เกมควบคุมอาจไม่ขยับ"]={en="Pull attempted • Game-controlled objects may not move",zh="已尝试拉取 • 游戏控制的物体可能无法移动"},
    ["ยังไม่มีของที่เข้าเกณฑ์ดึง ลองเข้าใกล้แล้วสแกน"]={en="No eligible pull targets yet; move closer and rescan",zh="暂无符合条件的拉取目标，请靠近后重新扫描"},
    ["พบผู้เล่น / NPC ที่มีชีวิต "]={en="Living players / NPCs found: ",zh="发现存活玩家 / NPC： "},
    [" รายการ\nป้าย NPC ไม่ได้ยืนยันว่าเป็นศัตรู"]={en=" entries\nNPC labels do not confirm hostility",zh=" 项\nNPC 标记不代表一定是敌人"},
    ["กำลังเดินหาไอเท็ม: "]={en="Walking to item: ",zh="正在前往物品： "},
    ["รอไอเท็มที่เข้าเกณฑ์ในรัศมีค้นหา"]={en="Waiting for eligible items within search range",zh="等待搜索范围内符合条件的物品"},
    ["Dead Rails โดย RCM Games\nแก้แมพตามลิงก์ใหม่ของ BM แล้ว\nรองรับการตรวจล็อบบี้และด่านเล่น"]={en="Dead Rails by RCM Games\nUpdated to BM's corrected map link\nDetects the lobby and active level",zh="Dead Rails 由 RCM Games 制作\n已采用 BM 更正后的地图链接\n支持识别大厅与游玩关卡"},
    ["เมนู 8 หมวด • โลโก้เงิน • เสียงเดิม\n• ค้นหา ดึง และเดินหาไอเท็ม\n• กดปุ่มเก็บของเมื่ออยู่ในระยะ\n• ป้ายผู้เล่น / NPC พร้อม HP\n• บิน เดินเร็ว กระโดด และจุดตามพื้น/รถ"]={en="8 tabs • Silver logo • Original sounds\n• Find, pull and walk to items\n• Use pickup prompts within range\n• Player / NPC labels with HP\n• Flight, speed, jump and ground/vehicle waypoints",zh="8 个分类 • 银色标志 • 原有音效\n• 搜索、拉取及前往物品\n• 在距离内使用拾取按钮\n• 玩家 / NPC 标记及生命值\n• 飞行、速度、跳跃、地面或车辆保存点"},
    ["เข้าเล่นรอบก่อน แล้วรันโหลดเดอร์ในด่านนั้น\nถ้าเปลี่ยนเซิร์ฟเวอร์หรือกลับล็อบบี้ ให้รันใหม่\nระบบเก็บรองรับปุ่มเก็บ และไอเท็มที่เกมระบุประเภท"]={en="Enter a round, then run the loader in that level\nRerun after changing servers or returning to the lobby\nPickup supports prompts and game-typed items",zh="先进入回合，再在关卡中运行加载器\n更换服务器或返回大厅后重新运行\n拾取支持游戏按钮及有类型信息的物品"},
    ["ยังไม่ได้ทดสอบในเซิร์ฟเวอร์จริง\nการดึง การเก็บ และการเคลื่อนที่ขึ้นกับเซิร์ฟเวอร์\nของที่ต้องยกหรือใส่ถุงยังต้องใช้ระบบของเกม"]={en="Not tested on a live server\nPulling, pickup and movement depend on the server\nCarry/bag items still require the game's own system",zh="尚未在实际服务器测试\n拉取、拾取及移动取决于服务器\n需要搬运或装袋的物品仍需使用游戏系统"},
    ["เริ่มค้นหาไอเท็ม →"]={en="Start finding items →",zh="开始搜索物品 →"},
    ["Dead Rails เป็นผลงานของ RCM Games\nSATURN X เป็นงานแยก ไม่ใช่เมนูทางการของเกม"]={en="Dead Rails is created by RCM Games\nSATURN X is separate and is not the game's official menu",zh="Dead Rails 由 RCM Games 制作\nSATURN X 是独立作品，并非官方菜单"},
    ["เลือกไอเท็มในด่านที่โหลดอยู่ใกล้ตัว\nอาวุธ ยา กระสุน และ Bond จะใช้ประเภทที่เกมระบุ\nการเก็บแบบคำขอต้องอยู่ใน 12 studs\nการดึงเป็นฟิสิกส์ทดลอง ของอาจไม่ขยับ"]={en="Select nearby loaded level items\nWeapons, medicine, ammo and Bonds use game item types\nPickup requests require being within 12 studs\nPulling is experimental physics; objects may not move",zh="选择附近已加载的关卡物品\n武器、药品、弹药及 Bond 使用游戏类型信息\n拾取请求需在 12 studs 内\n拉取是实验性物理操作，物品可能无法移动"},
    ["ป้ายชื่อและระยะไอเท็ม"]={en="Item names and distance labels",zh="物品名称及距离标记"},
    ["จำนวนดึงสูงสุดต่อรอบ"]={en="Maximum pulls per round",zh="每轮最大拉取数量"},
    ["ยังไม่ได้ส่งคำสั่งดึงของ"]={en="No item pull requests sent yet",zh="尚未发送物品拉取请求"},
    ["เดินหาไอเท็มที่กรองไว้"]={en="Walk to filtered items",zh="前往筛选后的物品"},
    ["เก็บเมื่อเดินถึงของ (ทดลอง)"]={en="Collect on arrival (experimental)",zh="到达后拾取（实验）"},
    ["ระบบเดินอัตโนมัติเริ่มต้นเป็นปิด"]={en="Auto-walking starts disabled",zh="自动行走默认关闭"},
    ["กรองชื่อของ เช่น Coal / Bond"]={en="Filter items, e.g. Coal / Bond",zh="筛选物品，例如 Coal / Bond"},
    ["กดสแกนเพื่อค้นหาของ"]={en="Scan to search for items",zh="点击扫描以查找物品"},
    ["เดินไปของที่เลือก"]={en="Walk to the selected item",zh="前往所选物品"},
    ["เก็บของที่เลือก (ทดลอง)"]={en="Collect selected item (experimental)",zh="拾取所选物品（实验）"},
    ["เลือกของก่อนครับ"]={en="Select an item first",zh="请先选择物品"},
    ["ทดลองดึงของที่เลือก"]={en="Try pulling the selected item",zh="尝试拉取所选物品"},
    ["หยุดเดิน / หยุดดึง"]={en="Stop walking / pulling",zh="停止行走 / 拉取"},
    ["ฟ้า = ผู้เล่น • ส้ม = NPC\nNPC คือโมเดลที่มี Humanoid ไม่ได้ยืนยันว่าเป็นศัตรู\nตรวจได้เฉพาะตัวที่เกมโหลดมาให้เครื่องนี้"]={en="Blue = player • Orange = NPC\nNPC means a model with Humanoid, not necessarily an enemy\nOnly sees characters loaded on this client",zh="蓝色＝玩家 • 橙色＝NPC\nNPC 指带有 Humanoid 的模型，不一定是敌人\n仅检测本机已加载的角色"},
    ["ไฮไลต์ NPC ผ่านวัตถุ"]={en="Highlight NPCs through objects",zh="透过物体高亮 NPC"},
    ["แสดงชื่อ / HP / ระยะ"]={en="Show name / HP / distance",zh="显示名称 / 生命值 / 距离"},
    ["สแกน NPC และอัปเดตรายชื่อ"]={en="Scan NPCs and refresh list",zh="扫描 NPC 并刷新列表"},
    ["กำลังอ่านรายชื่อ…"]={en="Reading names…",zh="正在读取名称…"},
    ["บิน: จอยมือถือหรือ WASD • ↑↓ หรือ Space / Ctrl\nเซิร์ฟเวอร์อาจจำกัดหรือย้อนตำแหน่ง"]={en="Flight: joystick or WASD • ↑↓ or Space / Ctrl\nThe server may limit or reset your position",zh="飞行：摇杆或 WASD • ↑↓ 或空格 / Ctrl\n服务器可能限制移动或重置位置"},
    [" • ตามวัตถุ"]={en=" • Follow object",zh=" • 跟随物体"},
    [" • พิกัดคงที่"]={en=" • Fixed position",zh=" • 固定坐标"},
    ["ยืนบนพื้นหรือรถก่อนบันทึกจุดตามวัตถุครับ"]={en="Stand on ground or a vehicle before saving an attached point",zh="保存跟随地点前，请站在地面或车辆上"},
    ["บันทึกจุดแล้ว"]={en="Waypoint saved",zh="地点已保存"},
    ["เก็บได้ 8 จุด และล้างเมื่อตัวละครเกิดใหม่\nจุดตามพื้น/รถจะเคลื่อนตามชิ้นส่วนที่ยืนอยู่\nถ้าวัตถุนั้นหายหรือถูกถอดจากการโหลด ต้องบันทึกใหม่"]={en="Up to 8 points; cleared on respawn\nAttached points follow the ground/vehicle part you stood on\nSave again if that object disappears or unloads",zh="最多 8 个地点，重生时清除\n跟随地点会随你所站的地面或车辆部件移动\n物体消失或未加载时需要重新保存"},
    ["ชื่อจุด เช่น ฐาน / รถ / จุดเริ่มต้น"]={en="Point name, e.g. Base / Train / Start",zh="地点名称，例如基地 / 火车 / 起点"},
    ["บันทึกพิกัดคงที่"]={en="Save fixed coordinates",zh="保存固定坐标"},
    ["บันทึกจุดตามพื้น / รถที่ยืนอยู่"]={en="Save a point on this ground / vehicle",zh="保存当前地面 / 车辆上的地点"},
    ["จุดนี้ไม่มีแล้วหรือยังไม่ได้เลือกครับ"]={en="This point is gone or has not been selected",zh="地点已不存在或尚未选择"},
    ["ลงจากที่นั่งก่อนย้ายจุดครับ"]={en="Leave your seat before moving to a point",zh="移动到地点前请先离开座位"},
    ["ค้นหาของจากรายการไอเท็มของเกม\nปิดการค้นหาตามประเภท เพื่อใช้เฉพาะรายชื่อด้านล่าง\nถ้าของหายจากรายการ ให้สร้างรายงานขณะยืนใกล้ของ"]={en="Searches the game's item list\nDisable type-based search to use only the names below\nIf items are missing, create a report while standing nearby",zh="搜索游戏物品列表\n关闭类型搜索时，仅使用下方名称\n如果物品未显示，请站在附近生成报告"},
    ["ค้นหาไอเท็มตามข้อมูลประเภทของเกม"]={en="Find items using the game's type data",zh="按游戏类型数据搜索物品"},
    ["รายชื่อไอเท็ม คั่นด้วย ,"]={en="Item names, separated by commas",zh="物品名称，以逗号分隔"},
    ["ใส่ชื่อไอเท็มอย่างน้อย 1 ชื่อ"]={en="Enter at least one item name",zh="请至少输入一个物品名称"},
    ["รายงานอยู่ด้านล่าง ถ่ายภาพหรือคัดลอกส่งมาได้"]={en="Report below; screenshot or copy it to share",zh="报告在下方，可截图或复制发送"},
    ["ปิด SATURN X DEAD RAILS"]={en="Close SATURN X DEAD RAILS",zh="关闭 SATURN X DEAD RAILS"},
    ["เลือกจุดที่ยังอยู่ในแมพเพื่อดูระยะ"]={en="Select an existing point on this map to see distance",zh="选择地图中仍存在的地点以查看距离"},
    ["ด่านเล่น"]={en="Active level",zh="游玩关卡"},
    ["เปิด UI ได้ แต่แมพนี้ไม่ใช่ Dead Rails ของ RCM Games"]={en="Menu available, but this is not Dead Rails by RCM Games",zh="菜单可用，但当前不是 RCM Games 的 Dead Rails"},
    ["เพลง / ภาษา / หน้าโหลด"]={en="Music / Language / Loading",zh="音乐 / 语言 / 加载"},
    ["ภาษา"]={en="Language",zh="语言"},
    ["เปิด"]={en="On",zh="开启"},
    ["ปิด"]={en="Off",zh="关闭"},
    ["เพลงประกอบ"]={en="Background music",zh="背景音乐"},
    ["ระดับเสียงเพลง"]={en="Music volume",zh="音乐音量"},
    ["เสียงเปิด / ปิดและคลิก"]={en="Open / close and click sounds",zh="开关及点击音效"},
    ["แสดงหน้าโหลด"]={en="Show loading screen",zh="显示加载画面"},
    ["เล่นเพลงต่อเมื่อย่อเมนู"]={en="Keep music when minimized",zh="最小化后继续播放音乐"},
    ["ลองโหลดเพลงอีกครั้ง"]={en="Retry music download",zh="重新加载音乐"},
    ["เริ่มเพลงใหม่"]={en="Restart track",zh="从头播放音乐"},
    ["รอเพลง"]={en="Waiting for music",zh="等待音乐"},
    ["กำลังโหลดเพลง…"]={en="Loading music…",zh="正在加载音乐…"},
    ["เพลงพร้อม • Gaming Music • 3:12"]={en="Music ready • Gaming Music • 3:12",zh="音乐就绪 • Gaming Music • 3:12"},
    ["เพลงโหลดช้า • ใช้เมนูต่อได้"]={en="Music is loading slowly • Menu is usable",zh="音乐加载较慢 • 可继续使用菜单"},
    ["โหลดเพลงไม่สำเร็จ • กดลองอีกครั้ง"]={en="Music failed to load • Press Retry",zh="音乐加载失败 • 请点击重试"},
    ["เครื่องนี้ไม่รองรับไฟล์เสียงแนบ"]={en="Local audio files are not supported here",zh="当前环境不支持本地音频文件"},
    ["บันทึกตั้งค่าร่วมกันแล้ว"]={en="Shared settings saved",zh="共用设置已保存"},
    ["ตั้งค่าใช้ร่วมกัน • จำในครั้งนี้หากบันทึกไฟล์ไม่ได้"]={en="Shared settings • Session only if file saving is unavailable",zh="共用设置 • 无法保存文件时仅在本次保留"},
    ["เมนูพร้อม • กำลังเตรียมเพลง"]={en="Menu ready • Preparing music",zh="菜单就绪 • 正在准备音乐"},
    ["พร้อมใช้งาน"]={en="Ready to use",zh="准备就绪"},
    ["กำลังเตรียมเมนู…"]={en="Preparing menu…",zh="正在准备菜单…"},
    ["ข้ามหน้าโหลด"]={en="Skip loading screen",zh="跳过加载画面"},
    ["ON"]={en="ON",zh="开启"},
    ["OFF"]={en="OFF",zh="关闭"},
    ["ALL"]={en="ALL",zh="全部"},
    ["COINS"]={en="COINS",zh="金币"},
    ["GUN"]={en="GUN",zh="枪"},
    ["UPDATE 01"]={en="UPDATE 01",zh="更新 01"},
    ["CREATED BY"]={en="CREATED BY",zh="创作者"},
    ["PLAYER PROFILE"]={en="PLAYER PROFILE",zh="玩家资料"},
    ["MAKE IT YOUR ORBIT"]={en="MAKE IT YOUR ORBIT",zh="打造你的轨道"},
    ["CONTROLS"]={en="CONTROLS",zh="操作"},
    ["SETTINGS"]={en="SETTINGS",zh="设置"},
}
-- END_LOCALES

local defaults = {language="th", musicEnabled=true, musicVolume=0.20,
    effectsEnabled=true, effectsVolume=0.45, loadingScreen=true, backgroundWhenHidden=true,
    motionEnabled=true,scrollMotionEnabled=true,pressMotionEnabled=true}
local languages = {th=true, en=true, zh=true}
local function cleanSettings(value)
    local out = {}
    for key, default in pairs(defaults) do
        local candidate
        if type(value)=="table" then candidate=value[key] end
        if key=="language" then out[key] = languages[candidate] and candidate or default
        elseif type(default)=="boolean" then
            if type(candidate)=="boolean" then out[key]=candidate else out[key]=default end
        elseif type(candidate)=="number" and candidate==candidate and candidate~=math.huge and candidate~=-math.huge then
            out[key] = math.clamp(candidate, 0, 1)
        else out[key] = default end
    end
    return out
end
local settingsPath = "SATURN_X_shared_settings_v1.json"
local saved = env.SATURN_X_MEDIA_SETTINGS
if not saved and type(readfile)=="function" then
    local ok, result = pcall(function()
        local raw = readfile(settingsPath)
        assert(type(raw)=="string" and #raw<8192)
        return HttpService:JSONDecode(raw)
    end)
    if ok then saved=result end
end
local M = {Version="1.0.0", Alive=true, Settings=cleanSettings(saved), Clients={}, Connections={},
    Bindings=setmetatable({}, {__mode="k"}), Assets={}, AssetJobs={}, MusicStatus="waiting", SaveStatus="session",
    Logo="", Serial=0, Loading=nil, Renderers={}, Cache={}, CacheCount=0, WatchRoots={}}
env.SATURN_X_MEDIA_SERVICE = M
env.SATURN_X_MEDIA_SETTINGS = M.Settings
local sourceTrie, formatRows = {}, {}
local function escapePattern(text) return (text:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")) end
for source, row in pairs(translations) do
    if source:find("%%[%d%.%-]*[sdf]") then
        local cursor, parts = 1, {}
        while true do
            local a,b = source:find("%%[%d%.%-]*[sdf]", cursor)
            if not a then parts[#parts+1]=escapePattern(source:sub(cursor)); break end
            parts[#parts+1]=escapePattern(source:sub(cursor,a-1))
            parts[#parts+1]="(.-)"; cursor=b+1
        end
        formatRows[#formatRows+1]={pattern="^"..table.concat(parts).."$",row=row,source=source}
    elseif source:find("[\224-\239]") then
        local node=sourceTrie
        for i=1,#source do local byte=source:byte(i); node[byte]=node[byte] or {}; node=node[byte] end
        node.row=row
    end
end
table.sort(formatRows,function(a,b) return #a.source>#b.source end)
local function interpolate(template, values)
    local index=0
    return (template:gsub("%%[%d%.%-]*[sdf]", function() index=index+1; return tostring(values[index] or "") end))
end
function M:T(source)
    if type(source)~="string" or self.Settings.language=="th" then return source end
    local cached=self.Cache[source]; if cached then return cached end
    local lang=self.Settings.language; local row=translations[source]; local result
    if row then result=row[lang] or source
    else
        for _,entry in ipairs(formatRows) do
            local values={source:match(entry.pattern)}
            if #values>0 then
                -- Translate known status values; preserve unknown names, IDs and numbers.
                for i,v in ipairs(values) do
                    if translations[v] then values[i]=translations[v][lang] or v
                    elseif #v<#source and v:find("\224[\184\185]") then values[i]=self:T(v) end
                end
                result=interpolate(entry.row[lang] or entry.source,values); break
            end
        end
    end
    if not result then
        local pieces,i={},1
        while i<=#source do
            local node=sourceTrie; local lastRow,lastEnd; local j=i
            while node and j<=#source do
                node=node[source:byte(j)]
                if node and node.row then lastRow,lastEnd=node.row,j end
                j=j+1
            end
            if lastRow then pieces[#pieces+1]=lastRow[lang]; i=lastEnd+1
            else pieces[#pieces+1]=source:sub(i,i); i=i+1 end
        end
        result=table.concat(pieces)
    end
    if self.CacheCount>=512 then self.Cache={};self.CacheCount=0 end
    self.Cache[source]=result;self.CacheCount=self.CacheCount+1
    return result
end
local function connect(signal, callback, list)
    local c=signal:Connect(callback); table.insert(list or M.Connections,c); return c
end
local function make(class, props, parent)
    local obj=Instance.new(class)
    for key,value in pairs(props or {}) do obj[key]=value end
    obj.Parent=parent
    return obj
end
local C={bg=Color3.fromRGB(13,16,24),card=Color3.fromRGB(25,31,43),line=Color3.fromRGB(62,76,97),
    text=Color3.fromRGB(238,243,251),muted=Color3.fromRGB(164,179,200),blue=Color3.fromRGB(153,204,255)}
local function round(obj,r) make("UICorner",{CornerRadius=UDim.new(0,r or 12)},obj) end
local function line(obj) make("UIStroke",{Color=C.line,Thickness=1,Transparency=0.2},obj) end
local function animate(obj,props,seconds)
    if not M.Alive or not obj.Parent then return end
    local t=TweenService:Create(obj,TweenInfo.new(seconds or 0.2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),props)
    t:Play();return t
end
function M:BindText(obj, property)
    if obj:GetAttribute("SATURN_X_NoTranslate") then return end
    if self.Bindings[obj] and self.Bindings[obj][property] then return end
    local record={source=obj[property], applied=nil}
    self.Bindings[obj]=self.Bindings[obj] or {};self.Bindings[obj][property]=record
    local function render()
        local value=obj:GetAttribute("SATURN_X_NoTranslate") and record.source or self:T(record.source); record.applied=value
        if obj[property]~=value then obj[property]=value end
    end
    record.render=render
    record.connection=obj:GetPropertyChangedSignal(property):Connect(function()
        if not self.Alive or obj[property]==record.applied then return end
        record.source=obj[property];render()
    end)
    render()
end
function M:SourceText(obj)
    local record=self.Bindings[obj] and self.Bindings[obj].Text
    return record and record.source or obj.Text
end
function M:Watch(root, session)
    if self.WatchRoots[root] then return end
    local records={};self.WatchRoots[root]=records
    local function attach(obj)
        if obj:GetAttribute("SATURN_X_NoTranslate") then return end
        if obj:IsA("TextLabel") or obj:IsA("TextButton") then self:BindText(obj,"Text")
        elseif obj:IsA("TextBox") then
            self:BindText(obj,"PlaceholderText")
            if not obj.TextEditable then self:BindText(obj,"Text") end
        end
        records[obj]=true
    end
    for _,obj in ipairs(root:GetDescendants()) do attach(obj) end
    local added=root.DescendantAdded:Connect(attach)
    local removing=root.DescendantRemoving:Connect(function(obj)
        local props=self.Bindings[obj]
        if props then for _,r in pairs(props) do r.connection:Disconnect() end;self.Bindings[obj]=nil end
        records[obj]=nil
    end)
    local destroying
    destroying=root.Destroying:Connect(function()
        added:Disconnect();removing:Disconnect();destroying:Disconnect()
        for obj in pairs(records) do
            local props=self.Bindings[obj]
            if props then for _,r in pairs(props) do r.connection:Disconnect() end;self.Bindings[obj]=nil end
        end
        self.WatchRoots[root]=nil
        if session then session:Close() end
    end)
    records._connections={added,removing,destroying}
end
local function textLabel(parent,text,x,y,w,h,size)
    local o=make("TextLabel",{BackgroundTransparency=1,Text=text,TextColor3=C.text,TextSize=size or 14,
        Font=Enum.Font.Gotham,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,
        Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h)},parent)
    M:BindText(o,"Text");return o
end
local function button(parent,text,x,y,w,h,callback)
    local b=make("TextButton",{BackgroundColor3=C.card,TextColor3=C.text,Text=text,TextSize=13,
        TextWrapped=true,Font=Enum.Font.GothamMedium,AutoButtonColor=false,BorderSizePixel=0,
        Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h)},parent)
    round(b,9);line(b);M:BindText(b,"Text")
    connect(b.Activated,function() M:Click();callback() end)
    return b
end
local oldGui=playerGui:FindFirstChild("SATURN_X_SHARED_MEDIA")
if oldGui then oldGui:Destroy() end
local gui=make("ScreenGui",{Name="SATURN_X_SHARED_MEDIA",ResetOnSpawn=false,IgnoreGuiInset=false,
    DisplayOrder=2000,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},playerGui)
M.Gui=gui
M.Audio=make("Folder",{Name="SATURN_X_SHARED_AUDIO"},SoundService)
M.EffectsGroup=make("SoundGroup",{Name="SATURN_X_EFFECTS",Volume=M.Settings.effectsVolume},M.Audio)
M.Music=make("Sound",{Name="SATURN_X_Background",Volume=M.Settings.musicVolume,Looped=true,PlayOnRemove=false},M.Audio)
M.UISounds={window=make("Sound",{Name="Window",Volume=1,SoundGroup=M.EffectsGroup},M.Audio),
    click=make("Sound",{Name="Click",Volume=1,SoundGroup=M.EffectsGroup},M.Audio)}
local function clientCount()
    local n=0;for _ in pairs(M.Clients) do n=n+1 end;return n
end
function M:Refresh()
    if not self.Alive then return end
    for _,fn in ipairs(self.Renderers) do fn() end
end
function M:SyncAudio()
    if not self.Alive then return end
    self.EffectsGroup.Volume=self.Settings.effectsEnabled and self.Settings.effectsVolume or 0
    self.Music.Volume=self.Settings.musicVolume
    local visible=false
    for _,client in pairs(self.Clients) do if client.Visible then visible=true;break end end
    local play=clientCount()>0 and self.Settings.musicEnabled and
        (self.Settings.backgroundWhenHidden or visible) and self.MusicStatus=="ready"
    if play and not self.Music.IsPlaying then
        if self.MusicStarted then self.Music:Resume() else self.Music:Play();self.MusicStarted=true end
    elseif not play and self.Music.IsPlaying then self.Music:Pause() end
end
function M:Set(key,value)
    if defaults[key]==nil then return false end
    if key=="language" and not languages[value] then return false end
    if type(value)~=type(defaults[key]) then return false end
    if type(value)=="number" and (value~=value or math.abs(value)==math.huge) then return false end
    if type(value)=="number" then value=math.clamp(value,0,1) end
    if self.Settings[key]==value then return true end
    self.Settings[key]=value;env.SATURN_X_MEDIA_SETTINGS=self.Settings
    if key=="language" then
        self.Cache={};self.CacheCount=0
        for _,props in pairs(self.Bindings) do for _,r in pairs(props) do r.render() end end
    end
    if key=="loadingScreen" and not value then self:DismissLoading() end
    self:SyncAudio();self:Refresh()
    self.SaveSerial=(self.SaveSerial or 0)+1;local serial=self.SaveSerial
    task.delay(0.3,function()
        if serial~=self.SaveSerial then return end
        if type(writefile)=="function" then
            local ok=pcall(function() writefile(settingsPath,HttpService:JSONEncode(self.Settings)) end)
            self.SaveStatus=ok and "saved" or "session"
        else self.SaveStatus="session" end
        self:Refresh()
    end)
    return true
end
function M:PlayEffect(sound)
    if not self.Alive or not sound or not sound.Parent or sound.SoundId=="" or not self.Settings.effectsEnabled then return false end
    local ok=pcall(function()
        sound.SoundGroup=self.EffectsGroup;sound.Volume=1;sound:Stop();sound.TimePosition=0;sound:Play()
    end)
    return ok
end
function M:Click() return self:PlayEffect(self.UISounds.click) end

local assetSpecs={
    music={name="background.mp3",remote="SATURN_X_background.mp3",size=6145671,kind="mp3"},
    logo={name="logo.png",remote="SATURN_X_logo.png",size=912102,kind="png"},
    window={name="window.mp3",remote="SATURN_X_window.mp3",size=52320,kind="mp3"},
    click={name="click.mp3",remote="SATURN_X_click.mp3",size=11702,kind="mp3"},
}
local assetBase="https://raw.githubusercontent.com/jrjhdjio/SATURN-X/main/assets/"
local function validAsset(data,spec)
    if type(data)~="string" or #data~=spec.size then return false end
    if spec.kind=="png" then return data:sub(1,8)=="\137PNG\r\n\26\n" end
    return data:sub(1,3)=="ID3" or (data:byte(1)==255 and (data:byte(2) or 0)>=224)
end
function M:Asset(kind,callback)
    if self.Assets[kind] then callback(self.Assets[kind]);return end
    if self.AssetJobs[kind] then table.insert(self.AssetJobs[kind],callback);return end
    self.AssetJobs[kind]={callback}
    task.spawn(function()
        local register=type(getcustomasset)=="function" and getcustomasset or
            (type(getsynasset)=="function" and getsynasset)
        local ok,id=pcall(function()
            assert(register and type(writefile)=="function","unsupported")
            local spec=assert(assetSpecs[kind]);local path="SATURN_X_media_v1_"..spec.name
            local data
            if type(readfile)=="function" then local readOK,value=pcall(readfile,path);if readOK and validAsset(value,spec) then data=value end end
            if not data then
                data=game:HttpGet(assetBase..spec.remote)
                assert(validAsset(data,spec),"invalid audio/image download")
                writefile(path,data)
            end
            local result=register(path);assert(type(result)=="string" and result~="","invalid local asset")
            return result
        end)
        local callbacks=self.AssetJobs[kind] or {};self.AssetJobs[kind]=nil
        if not self.Alive then return end
        if ok then self.Assets[kind]=id end
        for _,fn in ipairs(callbacks) do pcall(fn,ok and id or nil,not ok and tostring(id) or nil) end
    end)
end
function M:LoadMusic(force)
    if self.MusicStatus=="loading" or (self.MusicStatus=="ready" and not force) then return end
    self.MusicGeneration=(self.MusicGeneration or 0)+1;local generation=self.MusicGeneration
    self.MusicStatus="loading";self:Refresh()
    self:Asset("music",function(id,err)
        if not self.Alive or generation~=self.MusicGeneration then return end
        if not id then
            self.MusicStatus=(err and err:find("unsupported",1,true)) and "unsupported" or "failed"
            self:Refresh();self:MaybeFinishLoading();return
        end
        self.Music.SoundId=id
        local function ready()
            if self.Alive and generation==self.MusicGeneration and self.Music.IsLoaded then
                self.MusicStatus="ready";self:SyncAudio();self:Refresh();self:MaybeFinishLoading()
            end
        end
        ready()
        task.spawn(function() pcall(function() ContentProvider:PreloadAsync({self.Music}) end);ready() end)
    end)
    task.delay(18,function()
        if self.Alive and generation==self.MusicGeneration and self.MusicStatus=="loading" then
            self.MusicStatus="slow";self:Refresh();self:MaybeFinishLoading()
        end
    end)
end
connect(M.Music.Loaded,function()
    if M.Alive and M.Music.SoundId~="" then M.MusicStatus="ready";M:SyncAudio();M:Refresh();M:MaybeFinishLoading() end
end)

local settings=make("CanvasGroup",{Name="Settings",Size=UDim2.fromOffset(400,530),
    Position=UDim2.fromScale(0.5,0.5),AnchorPoint=Vector2.new(0.5,0.5),BackgroundColor3=C.bg,
    BorderSizePixel=0,Visible=false,GroupTransparency=1},gui)
round(settings,18);line(settings)
local settingsScale=make("UIScale",{Scale=1},settings)
local launcher=button(gui,"SX • ♪",0,0,76,36,function() M:OpenSettings(not settings.Visible) end)
launcher.AnchorPoint=Vector2.new(1,0);launcher.Position=UDim2.new(1,-12,0,54)
textLabel(settings,"SATURN X",22,14,300,28,21)
textLabel(settings,"เพลง / ภาษา / หน้าโหลด",22,43,320,24,12).TextColor3=C.muted
button(settings,"×",352,14,30,30,function() M:OpenSettings(false) end)
textLabel(settings,"ภาษา",22,79,356,22,14)
local langButtons={}
for i,entry in ipairs({{"th","ไทย"},{"en","English"},{"zh","中文"}}) do
    local key,name=entry[1],entry[2]
    langButtons[key]=button(settings,name,22+(i-1)*121,108,113,34,function() M:Set("language",key) end)
end
local function toggleRow(label,key,y)
    textLabel(settings,label,22,y,258,34,14)
    local b=button(settings,"",292,y,86,34,function() M:Set(key,not M.Settings[key]) end)
    M.Renderers[#M.Renderers+1]=function()
        b.Text=M.Settings[key] and "เปิด" or "ปิด"
        b.BackgroundColor3=M.Settings[key] and Color3.fromRGB(49,73,94) or C.card
    end
end
local function volumeRow(label,key,y)
    textLabel(settings,label,22,y,204,32,13)
    local value=textLabel(settings,"",258,y,58,32,13);value.TextXAlignment=Enum.TextXAlignment.Center
    button(settings,"−",220,y,32,32,function() M:Set(key,math.floor(M.Settings[key]*100-5+0.5)/100) end)
    button(settings,"+",322,y,56,32,function() M:Set(key,math.floor(M.Settings[key]*100+5+0.5)/100) end)
    M.Renderers[#M.Renderers+1]=function() value.Text=tostring(math.floor(M.Settings[key]*100+0.5)).."%" end
end
toggleRow("เพลงประกอบ", "musicEnabled",156)
volumeRow("ระดับเสียงเพลง", "musicVolume",198)
toggleRow("เสียงเปิด / ปิดและคลิก", "effectsEnabled",240)
volumeRow("ระดับเสียงเมนู", "effectsVolume",282)
toggleRow("แสดงหน้าโหลด", "loadingScreen",324)
toggleRow("เล่นเพลงต่อเมื่อย่อเมนู", "backgroundWhenHidden",366)
local musicState=textLabel(settings,"",22,408,356,36,11);musicState.TextColor3=C.muted
button(settings,"ลองโหลดเพลงอีกครั้ง",22,450,216,32,function() M:LoadMusic(true) end)
button(settings,"เริ่มเพลงใหม่",246,450,132,32,function()
    M.Music.TimePosition=0;M:Set("musicEnabled",true);M:SyncAudio()
end)
local saveState=textLabel(settings,"",22,490,356,24,10);saveState.TextColor3=C.muted
M.Renderers[#M.Renderers+1]=function()
    for key,b in pairs(langButtons) do b.BackgroundColor3=key==M.Settings.language and Color3.fromRGB(49,73,94) or C.card end
    local statuses={waiting="รอเพลง",loading="กำลังโหลดเพลง…",ready="เพลงพร้อม • Gaming Music • 3:12",slow="เพลงโหลดช้า • ใช้เมนูต่อได้",failed="โหลดเพลงไม่สำเร็จ • กดลองอีกครั้ง",unsupported="เครื่องนี้ไม่รองรับไฟล์เสียงแนบ"}
    musicState.Text=statuses[M.MusicStatus] or statuses.waiting
    saveState.Text=M.SaveStatus=="saved" and "บันทึกตั้งค่าร่วมกันแล้ว" or "ตั้งค่าใช้ร่วมกัน • จำในครั้งนี้หากบันทึกไฟล์ไม่ได้"
end
function M:OpenSettings(show)
    if not self.Alive then return end
    if show==nil then show=true end
    if show then settings.Visible=true;settings.GroupTransparency=1;animate(settings,{GroupTransparency=0})
    else settings.Visible=false end
    self:PlayEffect(self.UISounds.window);self:Refresh()
end
local function scalePanels()
    local camera=workspace.CurrentCamera;local size=camera and camera.ViewportSize or Vector2.new(800,600)
    settingsScale.Scale=math.min(1,math.max(0.2,(size.X-22)/400),math.max(0.2,(size.Y-64)/530))
    if M.Loading then M.Loading.scale.Scale=math.min(1,math.max(0.2,(size.X-24)/420),math.max(0.2,(size.Y-64)/370)) end
end
function M:SetLogo(id)
    if type(id)~="string" or id=="" then return end
    self.Logo=id
    if self.Loading then
        self.Loading.logo.Image=id;self.Loading.logo.Visible=true;self.Loading.fallback.Visible=false
    end
end
function M:DismissLoading()
    local current=self.Loading;if not current then return end
    self.Loading=nil
    animate(current.root,{GroupTransparency=1},0.2)
    task.delay(0.22,function() current.root:Destroy() end)
end
function M:MaybeFinishLoading()
    local current=self.Loading
    if not current or not current.session.Ready then return end
    current.status.Text=self.MusicStatus=="loading" and "เมนูพร้อม • กำลังเตรียมเพลง" or "พร้อมใช้งาน"
    animate(current.fill,{Size=UDim2.fromScale(self.MusicStatus=="loading" and 0.75 or 1,1)})
    if self.MusicStatus~="loading" then
        task.delay(math.max(0.4,1.5-(os.clock()-current.started)),function() if self.Loading==current then self:DismissLoading() end end)
    end
end
function M:ShowLoading(session)
    self:DismissLoading()
    if not self.Settings.loadingScreen then return end
    local root=make("CanvasGroup",{Name="Loading",Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.new(0,0,0),
        BackgroundTransparency=0.24,BorderSizePixel=0,GroupTransparency=1,Active=true},gui)
    local card=make("Frame",{Size=UDim2.fromOffset(420,370),Position=UDim2.fromScale(0.5,0.5),
        AnchorPoint=Vector2.new(0.5,0.5),BackgroundColor3=C.bg,BorderSizePixel=0},root);round(card,20);line(card)
    local scale=make("UIScale",{Scale=1},card)
    local logo=make("ImageLabel",{BackgroundTransparency=1,Size=UDim2.fromOffset(146,146),Position=UDim2.fromOffset(137,12),
        ScaleType=Enum.ScaleType.Fit,Image=self.Logo,Visible=self.Logo~=""},card)
    local fallback=textLabel(card,"SX",146,37,128,90,42);fallback.TextXAlignment=Enum.TextXAlignment.Center;fallback.Visible=self.Logo==""
    local title=textLabel(card,"SATURN X",24,155,372,32,25);title.TextXAlignment=Enum.TextXAlignment.Center
    local name=textLabel(card,session.Name,24,191,372,24,12);name.TextColor3=C.muted;name.TextXAlignment=Enum.TextXAlignment.Center
    local status=textLabel(card,"กำลังเตรียมเมนู…",24,223,372,28,12);status.TextXAlignment=Enum.TextXAlignment.Center
    local track=make("Frame",{Position=UDim2.fromOffset(30,259),Size=UDim2.fromOffset(360,5),BackgroundColor3=C.card,BorderSizePixel=0},card);round(track,3)
    local fill=make("Frame",{Size=UDim2.fromScale(0.15,1),BackgroundColor3=C.blue,BorderSizePixel=0},track);round(fill,3)
    for i,entry in ipairs({{"th","ไทย"},{"en","English"},{"zh","中文"}}) do
        local key=entry[1];button(card,entry[2],30+(i-1)*122,280,116,30,function() self:Set("language",key) end)
    end
    button(card,"ข้ามหน้าโหลด",110,321,200,30,function() self:DismissLoading() end)
    self.Loading={root=root,logo=logo,fallback=fallback,fill=fill,status=status,scale=scale,session=session,started=os.clock()}
    self:Watch(root)
    scalePanels();animate(root,{GroupTransparency=0},0.2)
    local current=self.Loading
    task.delay(12,function() if self.Loading==current then self:DismissLoading() end end)
end
function M:Begin(id,name)
    local previous=self.Clients[id];if previous then previous:Close() end
    self.Serial=self.Serial+1
    local session={Id=id,Name=name,Alive=true,Visible=true,Ready=false,Service=self}
    self.Clients[id]=session
    function session:Bind(root) if self.Alive then self.Bound=true;self.Service:Watch(root,self) end end
    function session:SetVisible(value) self.Visible=value==true;self.Service:SyncAudio() end
    function session:Finish()
        if not self.Alive or self.Ready then return end
        self.Ready=true;self.Service:MaybeFinishLoading()
        if self.OpenSound then
            self.Service:Asset("window",function(id)
                if self.Alive and id then
                    self.Service.UISounds.window.SoundId=id;self.Service:PlayEffect(self.Service.UISounds.window)
                end
            end)
        end
    end
    function session:Close()
        if not self.Alive then return end;self.Alive=false
        local service=self.Service
        if service.Clients[self.Id]==self then service.Clients[self.Id]=nil end
        if service.Loading and service.Loading.session==self then service:DismissLoading() end
        service:SyncAudio();local serial=service.Serial
        if clientCount()==0 then service.Gui.Enabled=false end
        task.delay(3,function() if service.Alive and clientCount()==0 and serial==service.Serial then service:Destroy() end end)
    end
    self.Gui.Enabled=true;self:ShowLoading(session);self:SyncAudio()
    self:LoadMusic()
    task.delay(15,function() if session.Alive and not session.Bound then session:Close() end end)
    return session
end
function M:Destroy()
    if not self.Alive then return end;self.Alive=false
    for _,c in ipairs(self.Connections) do c:Disconnect() end
    for _,props in pairs(self.Bindings) do for _,r in pairs(props) do r.connection:Disconnect() end end
    for _,records in pairs(self.WatchRoots) do for _,c in ipairs(records._connections or {}) do c:Disconnect() end end
    self.Bindings={};self.WatchRoots={}
    self.Music:Stop();self.Audio:Destroy();self.Gui:Destroy()
    if env.SATURN_X_MEDIA_SERVICE==self then env.SATURN_X_MEDIA_SERVICE=nil end
end
connect(gui.Destroying,function() if M.Alive then M:Destroy() end end)
local elapsed=0
connect(RunService.Heartbeat,function(dt)
    elapsed=elapsed+dt
    if elapsed>=0.25 then elapsed=0;scalePanels() end
    local current=M.Loading
    if current then
        local t=os.clock()-current.started
        current.logo.Rotation=math.sin(t*1.8)*7
        current.logo.Position=UDim2.fromOffset(137,12+math.sin(t*2.2)*4)
    end
end)
for _,kind in ipairs({"logo","window","click"}) do
    local assetKind=kind
    M:Asset(assetKind,function(id)
        if not id then return end
        if assetKind=="logo" then M:SetLogo(id) else M.UISounds[assetKind].SoundId=id end
    end)
end
M:SyncAudio();M:Refresh();scalePanels()
InstallMotion(M)
InstallOrbit(M)
return M

end)()
-- END SATURN_X_SHARED_MEDIA

local SXSession = SXMedia:Begin("SATURN_X_AVATAR", "SATURN X AVATAR")
local S = {
    alive=true, open=true, tab=1, connections={},
    fly=false, flight=nil, flySpeed=45, up=false, down=false,
    speed=false, walkSpeed=24, jump=false, jumpHeight=10,
    airJump=false, noclip=false, collisionSnapshot={},
    bright=false, noFog=false, noShadows=false, volume=0.45,
    waypoints={}, selectedWaypoint=nil, humSnapshot=nil,
    lightSnapshot={}, atmosphereSnapshot={}, cameraSnapshot=nil,
    fov=nil, fps=0, lastError="none", focused=true,
}
local miniTranslations = {
    ["แต่งตัว"]={en="Dress up",zh="换装"},
    ["รายชื่อล่าสุด"]={en="Recent usernames",zh="最近用户名"},
    ["แต่งตัวตาม Username"]={en="Dress by username",zh="按用户名换装"},
    ["แต่งตัวตาม Username • เมนู SATURN X ขนาดเดิม"]={en="Dress by username • Original SATURN X menu size",zh="按用户名换装 • 原版 SATURN X 菜单尺寸"},
    ["ค้นหา Username • ดูตัวอย่างสามมิติ • ลองชุดเฉพาะเครื่อง • คืนชุดเดิม • รายชื่อล่าสุด"]={en="Username lookup • 3D preview • Local try-on • Restore • Recent usernames",zh="用户名搜索 • 3D 预览 • 本地试穿 • 恢复 • 最近用户名"},
    ["เปิดเมนูแต่งตัว"]={en="Open dress-up menu",zh="打开换装菜单"},
    ["ใช้ Username จริง ไม่ใช่ Display Name • ดึงชุดที่ใส่บนโปรไฟล์"]={en="Use the actual username, not display name • Loads the profile outfit",zh="请使用真实用户名而非显示名 • 加载个人资料上的穿搭"},
    ["ใส่ Username เช่น @ชื่อบัญชี"]={en="Enter username, for example @username",zh="输入用户名，例如 @username"},
    ["ค้นหาและลองชุด"]={en="Find and try on",zh="查找并试穿"},
    ["ดูตัวอย่างอย่างเดียว"]={en="Preview only",zh="仅预览"},
    ["หมุนตัวอย่างซ้าย"]={en="Rotate preview left",zh="向左旋转预览"},
    ["หมุนตัวอย่างขวา"]={en="Rotate preview right",zh="向右旋转预览"},
    ["ลองชุดจากตัวอย่าง"]={en="Wear preview outfit",zh="试穿预览穿搭"},
    ["คืนชุดเดิม / ยกเลิกโหลด"]={en="Restore / Cancel loading",zh="恢复 / 取消加载"},
    ["ชุดที่ลองเห็นเฉพาะเครื่องเรา • บัญชีและชุดที่ผู้อื่นเห็นยังเป็นของเดิม"]={en="Try-on is visible only here • Your account and others' view stay unchanged",zh="试穿仅在本机可见 • 账号及其他玩家所见保持原样"},
    ["ตัวละครพิเศษและ R6 อาจแสดงบางชิ้นไม่ครบ • เกิดใหม่แล้วกดลองชุดอีกครั้ง"]={en="Custom characters and R6 may omit some items • Try on again after respawn",zh="特殊角色和 R6 可能无法显示部分物品 • 重生后请再次试穿"},
    ["กรอก Username จริง 3–20 ตัว เช่น @ชื่อบัญชี"]={en="Enter a real 3–20 character username, such as @username",zh="请输入真实的 3–20 位用户名，例如 @username"},
    ["กำลังโหลดชุดจากโปรไฟล์…"]={en="Loading profile outfit…",zh="正在加载资料穿搭…"},
    ["โหลดนานเกินไป กดลองอีกครั้ง"]={en="Loading timed out; please retry",zh="加载超时，请重试"},
    ["โหลดไม่ได้ ตรวจ Username หรือกดลองใหม่"]={en="Could not load; check the username or retry",zh="无法加载，请检查用户名或重试"},
    ["ตัวอย่างพร้อมแล้ว • ลองชุดได้"]={en="Preview ready • Try-on available",zh="预览已就绪 • 可试穿"},
    ["คืนตัวละครเดิมแล้ว"]={en="Original character restored",zh="已恢复原角色"},
    ["ใส่ Username แล้วโหลดตัวอย่างก่อน"]={en="Enter a username and load a preview first",zh="请先输入用户名并加载预览"},
    ["รอตัวละครเกิดก่อนลองชุด"]={en="Wait for your character before trying on",zh="请等待角色生成后再试穿"},
    ["ชนิดตัวละครเปลี่ยน กรุณาโหลดตัวอย่างใหม่"]={en="Character rig changed; reload the preview",zh="角色骨架已改变，请重新加载预览"},
    ["ตัวละครแมพนี้ไม่รองรับการลองชุด • ดูตัวอย่างได้"]={en="This character cannot support try-on • Preview is available",zh="当前角色不支持试穿 • 可查看预览"},
    ["หยุดลองชุดแล้ว เพราะโครงตัวละครเปลี่ยน"]={en="Try-on stopped because the character skeleton changed",zh="角色骨架改变，已停止试穿"},
    ["เครื่องนี้ไม่รองรับการลองชุด • ดูตัวอย่างได้"]={en="Try-on is unavailable here • Preview is available",zh="当前环境不支持试穿 • 可查看预览"},
    ["กำลังลองชุด • เห็นเฉพาะเครื่องเรา"]={en="Trying on • Visible only on this client",zh="试穿中 • 仅本机可见"},
    ["จำ 8 รายชื่อในครั้งนี้ • แตะชื่อเพื่อโหลดชุดโปรไฟล์ล่าสุด"]={en="Remembers 8 usernames this session • Tap to load their latest profile outfit",zh="本次记住 8 个用户名 • 点击加载最新资料穿搭"},
    ["ล้างรายชื่อล่าสุด"]={en="Clear recent usernames",zh="清除最近用户名"},
    ["MINI คือชื่อรุ่น • เมนูขนาดเดิม"]={en="MINI is the edition name • Original menu size",zh="MINI 是版本名称 • 保持原菜单尺寸"},
    ["บิน • ความเร็วเดิน • กระโดดสูง • กระโดดกลางอากาศ • เดินทะลุ • จุดบันทึก • ตั้งค่าภาพ"]={en="Flight • Walk speed • High jump • Air jump • Noclip • Waypoints • Visuals",zh="飞行 • 行走速度 • 高跳 • 空中跳跃 • 穿墙 • 路点 • 画面"},
    ["ลากแถบด้านบนเพื่อย้าย • ย่อเป็นปุ่มดาวเสาร์ • รองรับมือถือและคอมพิวเตอร์"]={en="Drag the header to move • Minimize to Saturn • Touch and mouse support",zh="拖动顶栏移动 • 最小化为土星按钮 • 支持触屏与鼠标"},
    ["ยังไม่ได้ทดสอบในเกมจริง • เซิร์ฟเวอร์อาจจำกัดการเคลื่อนที่"]={en="Not tested in a live game • The server may limit movement",zh="尚未在实际游戏中测试 • 服务器可能限制移动"},
    ["เปิดเมนูบิน"]={en="Open flight controls",zh="打开飞行控制"},
    ["มือถือ: จอยเดินและปุ่ม ↑ ↓ • คอม: WASD และ Space / Ctrl"]={en="Mobile: joystick and ↑ ↓ • PC: WASD and Space / Ctrl",zh="手机：摇杆及 ↑ ↓ • 电脑：WASD 及 Space / Ctrl"},
    ["หยุดบิน"]={en="Stop flying",zh="停止飞行"},
    ["กระโดดกลางอากาศ"]={en="Air jump",zh="空中跳跃"},
    ["เดินทะลุ"]={en="Noclip",zh="穿墙"},
    ["เกิดใหม่แล้วระบบจะปิดการเคลื่อนที่พิเศษ • เปิดอีกครั้งเมื่อพร้อม"]={en="Movement features turn off on respawn • Enable again when ready",zh="重生时关闭特殊移动 • 准备好后重新开启"},
    ["ภาพ / กล้อง"]={en="Visuals / Camera",zh="画面 / 镜头"},
    ["คืนค่าภาพและกล้อง"]={en="Restore visuals and camera",zh="恢复画面和镜头"},
    ["บันทึกพิกัดได้ 8 จุด • อยู่กับที่ • หายเมื่อปิด MINI"]={en="Save 8 fixed waypoints • Cleared when MINI closes",zh="可保存 8 个固定路点 • 关闭 MINI 后清除"},
    ["ตั้งค่า"]={en="Settings",zh="设置"},
    ["ไทย / English / 中文 • ใช้เสียงและตั้งค่าร่วมกับ SATURN X"]={en="Thai / English / 中文 • Shared audio and settings with SATURN X",zh="ไทย / English / 简体中文 • 与 SATURN X 共用音频及设置"},
    ["Right Shift: เปิดหรือย่อเมนู • End: หยุดฟีเจอร์ทั้งหมด"]={en="Right Shift: toggle menu • End: stop all features",zh="Right Shift：显示或最小化菜单 • End：停止全部功能"},
    ["ปิด SATURN X AVATAR"]={en="Close SATURN X AVATAR",zh="关闭 SATURN X AVATAR"},
}
-- Extend only the MINI strings, including when the shared service is already running.
SXMedia.AvatarTranslations=miniTranslations
if not SXMedia.AvatarBaseTranslate then
    SXMedia.AvatarBaseTranslate=SXMedia.T
    function SXMedia:T(source)
        if type(source)=="string" and self.Settings.language~="th" then
            local prefix,body=source:match("^(%d%d  )(.+)$")
            local row=self.AvatarTranslations[source] or (body and self.AvatarTranslations[body])
            if row then return (prefix or "")..(row[self.Settings.language] or source) end
        end
        return self.AvatarBaseTranslate(self,source)
    end
end
SXMedia:Refresh()
local C = {
    bg = Color3.fromRGB(17, 20, 27), panel = Color3.fromRGB(23, 27, 35),
    card = Color3.fromRGB(31, 36, 46), stroke = Color3.fromRGB(62, 71, 87),
    text = Color3.fromRGB(236, 240, 249), muted = Color3.fromRGB(155, 167, 185),
    accent = Color3.fromRGB(157, 204, 255), green = Color3.fromRGB(141, 228, 184),
    orange = Color3.fromRGB(245, 191, 119),
}
local function connect(signal, callback)
    local c = signal:Connect(callback)
    table.insert(S.connections, c)
    return c
end
local function make(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do obj[k] = v end
    obj.Parent = parent
    return obj
end
local function corner(parent, radius) make("UICorner", {CornerRadius = UDim.new(0, radius or 12)}, parent) end
local function stroke(parent, transparency)
    make("UIStroke", {Color = C.stroke, Thickness = 1, Transparency = transparency or 0.35}, parent)
end
local function tween(obj, props, duration)
    if not S.alive or not obj.Parent then return end
    TweenService:Create(obj, TweenInfo.new(duration or 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end
local function label(parent, text, size, color)
    return make("TextLabel", {
        BackgroundTransparency = 1, BorderSizePixel = 0, Text = text, TextSize = size or 14,
        Font = Enum.Font.Gotham, TextColor3 = color or C.text,
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
        TextWrapped = true, Size = UDim2.new(1, 0, 0, 24),
    }, parent)
end
local gui = make("ScreenGui", {Name = "SATURN_X_AVATAR", ResetOnSpawn = false,
    IgnoreGuiInset = false, DisplayOrder = 40, ZIndexBehavior = Enum.ZIndexBehavior.Sibling}, playerGui)
local root = make("Frame", {BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1)}, gui)
local window = make("CanvasGroup", {Name = "Window", BackgroundColor3 = C.bg,
    BorderSizePixel = 0, Size = UDim2.fromOffset(760, 510), Position = UDim2.fromOffset(80, 50), ClipsDescendants = true}, root)
corner(window, 18) stroke(window, 0.05)
local uiScale = make("UIScale", {Scale = 1}, window)
local header = make("Frame", {Size = UDim2.new(1, 0, 0, 66), BackgroundColor3 = C.panel, BorderSizePixel = 0}, window)
make("Frame", {Position = UDim2.new(0, 0, 1, -1), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = C.stroke, BorderSizePixel = 0}, header)
local logo = make("ImageLabel", {BackgroundTransparency = 1, Size = UDim2.fromOffset(46, 46), Position = UDim2.fromOffset(12, 10), ScaleType = Enum.ScaleType.Fit}, header)
local logoFallback = label(logo, "🪐", 30) logoFallback.Size = UDim2.fromScale(1, 1) logoFallback.TextXAlignment = Enum.TextXAlignment.Center
local brand = label(header, "SATURN X AVATAR", 21) brand.Position = UDim2.fromOffset(68, 9) brand.Size = UDim2.new(1, -190, 0, 28) brand.Font = Enum.Font.GothamBold
local subtitle = label(header, "AVATAR DRESS-UP  /  BY BM", 10, C.muted) subtitle.Position = UDim2.fromOffset(69, 37) subtitle.Size = UDim2.new(1, -180, 0, 18)
local dragArea = make("Frame", {BackgroundTransparency = 1, Active = true, Position = UDim2.fromOffset(60, 0), Size = UDim2.new(1, -168, 1, 0)}, header)
local function iconButton(parent, text, x)
    local b = make("TextButton", {Text = text, Font = Enum.Font.GothamBold, TextSize = 19,
        TextColor3 = C.text, BackgroundColor3 = C.card, BorderSizePixel = 0,
        Size = UDim2.fromOffset(36, 34), Position = UDim2.new(1, x, 0, 16), AutoButtonColor = false}, parent)
    corner(b, 9)
    return b
end
local minimize = iconButton(header, "−", -90)
local close = iconButton(header, "×", -48)
local sidebar = make("ScrollingFrame", {Name = "Categories", BackgroundColor3 = C.panel, BorderSizePixel = 0,
    Position = UDim2.fromOffset(10, 77), Size = UDim2.new(0, 174, 1, -119),
    ScrollBarThickness = 2, ScrollBarImageColor3 = C.stroke, AutomaticCanvasSize = Enum.AutomaticSize.Y,
    CanvasSize = UDim2.new(), ScrollingDirection = Enum.ScrollingDirection.Y}, window)
corner(sidebar, 12)
make("UIPadding", {PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6)}, sidebar)
make("UIListLayout", {Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder}, sidebar)
local content = make("Frame", {Name = "Content", BackgroundTransparency = 1, Position = UDim2.fromOffset(198, 78), Size = UDim2.new(1, -212, 1, -120)}, window)
local footer = label(window, "BETA  •  ยังไม่ทดสอบในเกมจริง", 11, C.muted)
footer.Position = UDim2.new(0, 18, 1, -31) footer.Size = UDim2.new(1, -36, 0, 20)
local pages, tabs, toggleSetters = {}, {}, {}
local tabNames = {"อัปเดตแรก", "เครดิตผู้สร้าง", "โปรไฟล์ผู้เล่น", "แต่งตัว", "เคลื่อนที่", "ภาพ / กล้อง", "รายชื่อล่าสุด", "ตั้งค่า"}
for i, name in ipairs(tabNames) do
    local b = make("TextButton", {Name = "Tab" .. i, LayoutOrder = i, Size = UDim2.new(1, 0, 0, 37),
        BackgroundColor3 = C.panel, Text = string.format("%02d  %s", i, name), TextColor3 = C.muted,
        TextSize = 13, Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0, AutoButtonColor = false}, sidebar)
    corner(b, 8)
    make("UIPadding", {PaddingLeft = UDim.new(0, 10)}, b)
    tabs[i] = b
    local page = make("ScrollingFrame", {Name = "Page" .. i, BackgroundTransparency = 1, BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1), ScrollBarThickness = 3, ScrollBarImageColor3 = C.accent,
        AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Visible = i == 1}, content)
    make("UIPadding", {PaddingRight = UDim.new(0, 7), PaddingBottom = UDim.new(0, 12)}, page)
    make("UIListLayout", {Padding = UDim.new(0, 9), SortOrder = Enum.SortOrder.LayoutOrder}, page)
    pages[i] = page
end

local function playSound(kind)
    return SXMedia:PlayEffect(SXMedia.UISounds[kind])
end
local toastSerial = 0
local toast = make("TextLabel", {BackgroundColor3 = C.card, BorderSizePixel = 0, TextColor3 = C.text,
    TextSize = 13, Font = Enum.Font.Gotham, TextWrapped = true, Visible = false,
    AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -16), Size = UDim2.new(0.9, 0, 0, 62), ZIndex = 80}, root)
corner(toast, 12) stroke(toast)
make("UISizeConstraint", {MaxSize = Vector2.new(520, 100)}, toast)
local function notify(text)
    if not S.alive then return end
    toastSerial = toastSerial + 1
    local serial = toastSerial
    toast.Text = text toast.Visible = true
    task.delay(4, function() if S.alive and serial == toastSerial then toast.Visible = false end end)
end
local function guarded(fn)
    local ok, err = pcall(fn)
    if not ok then S.lastError = tostring(err) warn("SATURN X: " .. S.lastError) notify("ทำรายการไม่ได้: " .. string.sub(S.lastError, 1, 140)) end
end
local function title(page, text, sub)
    local t = label(page, text, 22) t.Font = Enum.Font.GothamBold t.Size = UDim2.new(1, 0, 0, 32)
    if sub then local s = label(page, sub, 12, C.muted) s.AutomaticSize = Enum.AutomaticSize.Y s.Size = UDim2.new(1, 0, 0, 28) end
end
local function info(page, text, color)
    local box = make("Frame", {BackgroundColor3 = C.card, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y}, page)
    corner(box, 10)
    make("UIPadding", {PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12)}, box)
    local t = label(box, text, 13, color or C.muted) t.Size = UDim2.new(1, 0, 0, 0) t.AutomaticSize = Enum.AutomaticSize.Y
    return t
end
local function action(page, text, callback, secondary)
    local b = make("TextButton", {Text = text, TextSize = 13, Font = Enum.Font.GothamMedium,
        TextColor3 = secondary and C.text or C.bg, BackgroundColor3 = secondary and C.card or C.accent,
        BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 42), AutoButtonColor = true, TextWrapped = true}, page)
    corner(b, 10)
    connect(b.Activated, function() playSound("click") guarded(callback) end)
    return b
end
local function toggle(page, text, key, callback)
    local b = make("TextButton", {Text = "", BackgroundColor3 = C.card, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 52), AutoButtonColor = false}, page)
    corner(b, 10)
    local t = label(b, text, 13) t.Position = UDim2.fromOffset(12, 5) t.Size = UDim2.new(1, -80, 1, -10)
    local track = make("Frame", {Position = UDim2.new(1, -59, 0.5, -12), Size = UDim2.fromOffset(46, 24), BackgroundColor3 = C.stroke, BorderSizePixel = 0}, b)
    corner(track, 20)
    local dot = make("Frame", {Size = UDim2.fromOffset(18, 18), Position = UDim2.fromOffset(3, 3), BackgroundColor3 = C.text, BorderSizePixel = 0}, track) corner(dot, 20)
    local function render()
        tween(track, {BackgroundColor3 = S[key] and C.accent or C.stroke})
        tween(dot, {Position = UDim2.fromOffset(S[key] and 25 or 3, 3), BackgroundColor3 = S[key] and C.bg or C.text})
    end
    local function set(value, quiet)
        if S[key] == value then render() return end
        local ok, result = pcall(callback, value)
        if not ok then S.lastError = tostring(result) if not quiet then notify("เปิดฟีเจอร์ไม่ได้: " .. string.sub(S.lastError, 1, 100)) end return end
        if result ~= false then S[key] = value end
        render()
    end
    toggleSetters[key] = set
    connect(b.Activated, function() playSound("click") set(not S[key]) end)
    render()
    return set
end
local function stepper(page, text, key, minimum, maximum, step, onChange)
    local box = make("Frame", {Size = UDim2.new(1, 0, 0, 62), BackgroundColor3 = C.card, BorderSizePixel = 0}, page) corner(box, 10)
    local t = label(box, text, 12, C.muted) t.Position = UDim2.fromOffset(12, 5) t.Size = UDim2.new(1, -24, 0, 20)
    local value = label(box, tostring(S[key]), 16) value.Position = UDim2.fromOffset(12, 28) value.Size = UDim2.new(1, -110, 0, 25)
    for _, spec in ipairs({{"−", -82, -1}, {"+", -43, 1}}) do
        local b = make("TextButton", {Text = spec[1], TextColor3 = C.text, TextSize = 20, Font = Enum.Font.Gotham,
            Size = UDim2.fromOffset(30, 30), Position = UDim2.new(1, spec[2], 0, 24), BackgroundColor3 = C.stroke, BorderSizePixel = 0}, box) corner(b, 8)
        connect(b.Activated, function()
            playSound("click")
            S[key] = math.clamp(math.floor((S[key] + step * spec[3]) * 100 + 0.5) / 100, minimum, maximum)
            value.Text = tostring(S[key])
            if onChange then guarded(onChange) end
        end)
    end
    return value
end
local function input(page, placeholder, initial, callback)
    local b = make("TextBox", {PlaceholderText = placeholder, Text = initial or "", TextColor3 = C.text,
        PlaceholderColor3 = C.muted, TextSize = 12, Font = Enum.Font.Gotham, ClearTextOnFocus = false,
        BackgroundColor3 = C.card, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 43), TextXAlignment = Enum.TextXAlignment.Left}, page)
    corner(b, 10) make("UIPadding", {PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12)}, b)
    connect(b.FocusLost, function() guarded(function() callback(b.Text) end) end)
    return b
end
local function selectTab(index)
    S.tab = index
    for i, page in ipairs(pages) do
        page.Visible = i == index
        tween(tabs[i], {BackgroundColor3 = i == index and C.card or C.panel, TextColor3 = i == index and C.accent or C.muted})
    end
end
for i, tab in ipairs(tabs) do connect(tab.Activated, function() playSound("click") selectTab(i) end) end

local floating = make("ImageButton", {Name = "SaturnButton", Image = "", BackgroundColor3 = C.panel,
    BackgroundTransparency = 0.12, Size = UDim2.fromOffset(54, 54), Position = UDim2.fromOffset(20, 100), BorderSizePixel = 0, AutoButtonColor = false, Visible = false}, root)
corner(floating, 30) stroke(floating, 0.05)
local floatingFallback = label(floating, "🪐", 31) floatingFallback.Size = UDim2.fromScale(1, 1) floatingFallback.TextXAlignment = Enum.TextXAlignment.Center
local movedAt = 0
local function clampPosition(obj, x, y)
    return UDim2.fromOffset(math.clamp(x, 6, math.max(6, root.AbsoluteSize.X - obj.AbsoluteSize.X - 6)), math.clamp(y, 6, math.max(6, root.AbsoluteSize.Y - obj.AbsoluteSize.Y - 6)))
end
local function draggable(handle, object)
    local pointer, origin, start, moved
    connect(handle.InputBegan, function(e)
        if not pointer and (e.UserInputType == Enum.UserInputType.MouseButton1 or e.UserInputType == Enum.UserInputType.Touch) then
            pointer, origin, start, moved = e, Vector2.new(e.Position.X, e.Position.Y), object.Position, false
        end
    end)
    connect(UIS.InputChanged, function(e)
        if pointer and (e == pointer or (pointer.UserInputType == Enum.UserInputType.MouseButton1 and e.UserInputType == Enum.UserInputType.MouseMovement)) then
            local delta = Vector2.new(e.Position.X, e.Position.Y) - origin
            if delta.Magnitude > 6 then moved = true end
            if moved then object.Position = clampPosition(object, start.X.Offset + delta.X, start.Y.Offset + delta.Y) end
        end
    end)
    connect(UIS.InputEnded, function(e)
        if e == pointer then
            if moved then movedAt = os.clock() end
            pointer = nil
        end
    end)
end
draggable(dragArea, window) draggable(floating, floating)
local function setOpen(value)
    S.open = value
    SXSession:SetVisible(value)
    playSound("window")
    floating.Visible = not value
    if value then
        window.Visible = true
        tween(window, {GroupTransparency = 0}, 0.16)
    else
        tween(window, {GroupTransparency = 1}, 0.16)
        task.delay(0.17, function() if S.alive and not S.open then window.Visible = false end end)
    end
end
connect(minimize.Activated, function() setOpen(false) end)
connect(floating.Activated, function() if os.clock() - movedAt > 0.25 then setOpen(true) end end)
local positioned = false
local function layout()
    local available = root.AbsoluteSize
    if available.X < 1 or available.Y < 1 then return end
    local narrow = available.X < 600
    local w, h, side = narrow and 430 or 760, narrow and 620 or 510, narrow and 52 or 174
    window.Size = UDim2.fromOffset(w, h)
    uiScale.Scale = math.min(1, (available.X - 16) / w, (available.Y - 16) / h)
    sidebar.Size = UDim2.new(0, side, 1, -119)
    content.Position = UDim2.fromOffset(side + 24, 78)
    content.Size = UDim2.new(1, -side - 38, 1, -120)
    subtitle.Text = narrow and "AVATAR DRESS-UP" or "AVATAR DRESS-UP  /  BY BM"
    for i, b in ipairs(tabs) do b.Text = narrow and string.format("%02d", i) or string.format("%02d  %s", i, tabNames[i]) end
    if not positioned then
        window.Position = UDim2.fromOffset(math.max(6, (available.X - w * uiScale.Scale) / 2), math.max(6, (available.Y - h * uiScale.Scale) / 2))
        positioned = true
    else window.Position = clampPosition(window, window.Position.X.Offset, window.Position.Y.Offset) end
    floating.Position = clampPosition(floating, floating.Position.X.Offset, floating.Position.Y.Offset)
end
connect(root:GetPropertyChangedSignal("AbsoluteSize"), layout)
task.defer(layout)

local function character()
    local c = player.Character
    if not c then return nil, nil end
    return c:FindFirstChildOfClass("Humanoid"), c:FindFirstChild("HumanoidRootPart")
end
local function gameReady()
    local h, r = character()
    if not h or not r or h.Health <= 0 then notify("รอให้ตัวละครเกิดก่อนครับ") return false end
    return true
end
local function snapshotHumanoid(h)
    if S.humSnapshot and S.humSnapshot.h == h then return end
    S.humSnapshot = {h = h, speed = h.WalkSpeed, jumpPower = h.JumpPower, jumpHeight = h.JumpHeight, autoRotate = h.AutoRotate, platformStand = h.PlatformStand}
end
local function applyMovement()
    local h = character()
    if not h then return end
    snapshotHumanoid(h)
    h.WalkSpeed = S.speed and S.walkSpeed or S.humSnapshot.speed
    if S.jump then
        if h.UseJumpPower then h.JumpPower = math.sqrt(2 * Workspace.Gravity * S.jumpHeight) else h.JumpHeight = S.jumpHeight end
    else h.JumpPower = S.humSnapshot.jumpPower h.JumpHeight = S.humSnapshot.jumpHeight end
end
local function stopFlight()
    local f = S.flight
    if not f then return end
    S.flight = nil S.up = false S.down = false
    if f.r and f.r.Parent then f.r.AssemblyLinearVelocity = Vector3.zero end
    for _, obj in pairs({velocity = f.velocity, orientation = f.orientation, attachment = f.attachment}) do obj:Destroy() end
    if f.h and f.h.Parent then
        f.h.AutoRotate = f.autoRotate f.h.PlatformStand = f.platformStand
        if f.h.Health > 0 then f.h:ChangeState(Enum.HumanoidStateType.GettingUp) end
    end
end
local flyControls = make("Frame", {BackgroundTransparency = 1, Position = UDim2.new(1, -70, 0.5, -50), Size = UDim2.fromOffset(56, 110), Visible = false}, root)
local flightTouches = {}
for i, spec in ipairs({{"↑", "up"}, {"↓", "down"}}) do
    local b = make("TextButton", {Text = spec[1], Font = Enum.Font.GothamBold, TextSize = 24, TextColor3 = C.text,
        BackgroundColor3 = C.panel, BackgroundTransparency = 0.08, BorderSizePixel = 0,
        Size = UDim2.fromOffset(52, 48), Position = UDim2.fromOffset(0, (i - 1) * 56)}, flyControls) corner(b, 14) stroke(b)
    connect(b.InputBegan, function(e) if e.UserInputType == Enum.UserInputType.Touch or e.UserInputType == Enum.UserInputType.MouseButton1 then S[spec[2]] = true flightTouches[e] = spec[2] end end)
    connect(b.InputEnded, function(e) if e.UserInputType == Enum.UserInputType.Touch or e.UserInputType == Enum.UserInputType.MouseButton1 then S[spec[2]] = false end end)
end
connect(UIS.InputEnded, function(e) if flightTouches[e] then S[flightTouches[e]] = false flightTouches[e] = nil end end)
local function startFlight()
    if not gameReady() then return false end
    stopFlight()
    local h, r = character() snapshotHumanoid(h)
    if h.SeatPart then notify("ลงจากที่นั่งก่อนเปิดบินครับ") return false end
    local f = {h = h, r = r, autoRotate = h.AutoRotate, platformStand = h.PlatformStand}
    S.flight = f -- Register first so a partially failed setup can always be cleaned up.
    local ok, err = pcall(function()
        f.attachment = make("Attachment", {Name = "SaturnMiniFlightAttachment"}, r)
        f.velocity = make("LinearVelocity", {Attachment0 = f.attachment, RelativeTo = Enum.ActuatorRelativeTo.World,
            VelocityConstraintMode = Enum.VelocityConstraintMode.Vector, ForceLimitsEnabled = false, VectorVelocity = Vector3.zero}, r)
        f.orientation = make("AlignOrientation", {Attachment0 = f.attachment, Mode = Enum.OrientationAlignmentMode.OneAttachment,
            MaxTorque = 1000000, Responsiveness = 20}, r)
        h.AutoRotate = false h.PlatformStand = true
    end)
    if not ok then stopFlight() error(err) end
    flyControls.Visible = true
    return true
end


-- Appearance preview and local visual overlay. Never changes Player.Character,
-- account inventory, purchase state, identity, or the server's avatar description.
local Avatar = (function()
    local A={serial=0,busy=false,dead=false,hidden={},recent={},recentConnections={},yaw=math.pi,
        current=nil,overlay=nil,renderName="SATURN_X_AVATAR_OVERLAY"}
    function A:Status(text)
        self.statusText=text
        if self.statusLabel then self.statusLabel.Text=SXMedia:T(text) end
    end
    function A:Normalize(text)
        text=tostring(text or ""):match("^%s*(.-)%s*$"):gsub("^@","")
        if #text<3 or #text>20 or not text:match("^[A-Za-z0-9_]+$") then return nil end
        return text
    end
    local function dispose(o) if o then pcall(function() o:Destroy() end) end end
    local function sanitize(model)
        for _,o in ipairs(model:GetDescendants()) do
            if o:IsA("Script") or o:IsA("LocalScript") or o:IsA("ModuleScript") or o:IsA("Sound") then
                o:Destroy()
            elseif o:IsA("BasePart") then
                o.Anchored=true;o.CanCollide=false;o.CanTouch=false;o.CanQuery=false;o.Massless=true
                o.LocalTransparencyModifier=0
            elseif o:IsA("Humanoid") then
                o.AutoRotate=false;o.BreakJointsOnDeath=false
                o.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
                pcall(function() o.EvaluateStateMachine=false end)
            end
        end
        local rootPart=model:FindFirstChild("HumanoidRootPart")
        if rootPart then rootPart.Transparency=1 end
        return model
    end
    function A:FramePreview()
        if not self.current or not self.camera then return end
        local cf,size=self.current.model:GetBoundingBox()
        local distance=math.max(size.Y,size.X,size.Z)*1.9+1
        local target=cf.Position
        self.camera.CFrame=CFrame.lookAt(target+Vector3.new(math.sin(self.yaw)*distance,size.Y*0.06,math.cos(self.yaw)*distance),target)
    end
    function A:RenderRecent()
        if not self.recentFrame then return end
        for _,c in ipairs(self.recentConnections) do c:Disconnect() end
        self.recentConnections={}
        for _,o in ipairs(self.recentFrame:GetChildren()) do if o:IsA("TextButton") then o:Destroy() end end
        for _,name in ipairs(self.recent) do
            local username=name
            local b=make("TextButton",{Text="@"..username,TextSize=14,Font=Enum.Font.Gotham,
                TextColor3=C.text,BackgroundColor3=C.card,BorderSizePixel=0,Size=UDim2.new(1,0,0,42)},self.recentFrame)
            b:SetAttribute("SATURN_X_NoTranslate",true);corner(b,10)
            table.insert(self.recentConnections,b.Activated:Connect(function()
                playSound("click");self.nameInput.Text=username;selectTab(4);self:Load(username,false)
            end))
        end
    end
    function A:Load(text,wearAfter)
        if self.dead then return end
        local username=self:Normalize(text)
        if not username then self:Status("กรอก Username จริง 3–20 ตัว เช่น @ชื่อบัญชี");return end
        self.serial=self.serial+1;local serial=self.serial
        self.busy=true;self:Status("กำลังโหลดชุดจากโปรไฟล์…")
        task.delay(30,function()
            if not self.dead and self.busy and self.serial==serial then
                self.serial=self.serial+1;self.busy=false;self:Status("โหลดนานเกินไป กดลองอีกครั้ง")
            end
        end)
        task.spawn(function()
            local desc,model
            local ok,result=pcall(function()
                local id=Players:GetUserIdFromNameAsync(username)
                if A.dead or serial~=A.serial then return end
                local name=Players:GetNameFromUserIdAsync(id)
                if A.dead or serial~=A.serial then return end
                desc=Players:GetHumanoidDescriptionFromUserIdAsync(id)
                if A.dead or serial~=A.serial then return end
                local h=character()
                local rigType=h and h.RigType or Enum.HumanoidRigType.R15
                model=Players:CreateHumanoidModelFromDescriptionAsync(desc,rigType)
                if A.dead or serial~=A.serial then return end
                sanitize(model)
                model.Name="SATURN_X_AvatarPreview"
                model:PivotTo(CFrame.new())
                return {id=id,username=name,description=desc,model=model,rigType=rigType}
            end)
            if A.dead or serial~=A.serial then dispose(model);dispose(desc);return end
            A.busy=false
            if not ok or not result then
                dispose(model);dispose(desc)
                S.lastError=tostring(result);A:Status("โหลดไม่ได้ ตรวจ Username หรือกดลองใหม่")
                return
            end
            if A.current then dispose(A.current.model);dispose(A.current.description) end
            A.current=result;result.model.Parent=A.world
            A.userLabel.Text="@"..result.username.."  •  "..tostring(result.id)
            A.yaw=math.pi;A:FramePreview()
            for i=#A.recent,1,-1 do if A.recent[i]:lower()==result.username:lower() then table.remove(A.recent,i) end end
            table.insert(A.recent,1,result.username);while #A.recent>8 do table.remove(A.recent) end
            A:RenderRecent();A:Status("ตัวอย่างพร้อมแล้ว • ลองชุดได้")
            if wearAfter then A:Wear() end
        end)
    end
    local function jointRecord(o)
        if o:IsA("Motor6D") or o:IsA("Weld") then
            if o.Part0 and o.Part1 then return {object=o,p0=o.Part0,p1=o.Part1,c0=o.C0,c1=o.C1,animated=o:IsA("Motor6D")} end
        elseif o.ClassName=="AnimationConstraint" then
            local a,b=o.Attachment0,o.Attachment1
            if a and b and a.Parent:IsA("BasePart") and b.Parent:IsA("BasePart") then
                return {object=o,p0=a.Parent,p1=b.Parent,c0=a.CFrame,c1=b.CFrame,animated=true}
            end
        elseif o:IsA("WeldConstraint") and o.Part0 and o.Part1 then
            return {object=o,p0=o.Part0,p1=o.Part1,c0=o.Part0.CFrame:ToObjectSpace(o.Part1.CFrame),c1=CFrame.new(),animated=false}
        end
    end
    local function key(a,b) return a.Name.."\0"..b.Name end
    function A:BuildPose(model,source)
        local targetRoot=model:FindFirstChild("HumanoidRootPart")
        local sourceRoot=source:FindFirstChild("HumanoidRootPart")
        assert(targetRoot and sourceRoot,"Missing root")
        local sourceJoints={}
        for _,o in ipairs(source:GetDescendants()) do
            local j=jointRecord(o)
            if j and j.animated and j.p0.Parent==source and j.p1.Parent==source then sourceJoints[key(j.p0,j.p1)]=j end
        end
        local joints,adjacency={},{}
        for _,o in ipairs(model:GetDescendants()) do
            local j=jointRecord(o)
            if j and j.p0:IsDescendantOf(model) and j.p1:IsDescendantOf(model) then
                if j.animated and j.p0.Parent==model and j.p1.Parent==model then
                    j.source=assert(sourceJoints[key(j.p0,j.p1)],"Unsupported body joints")
                end
                joints[#joints+1]=j
                adjacency[j.p0]=adjacency[j.p0] or {};table.insert(adjacency[j.p0],j)
                adjacency[j.p1]=adjacency[j.p1] or {};table.insert(adjacency[j.p1],j)
            end
        end
        local visited={[targetRoot]=true};local queue={targetRoot};local index=1;local ordered={};local matched=0
        while index<=#queue do
            local p=queue[index];index=index+1
            for _,j in ipairs(adjacency[p] or {}) do
                local other=j.p0==p and j.p1 or j.p0
                if not visited[other] then
                    visited[other]=true;queue[#queue+1]=other
                    j.forward=j.p0==p;ordered[#ordered+1]=j
                    if j.source then matched=matched+1 end
                end
            end
        end
        assert(matched>=5,"Unsupported character skeleton")
        local fallback={};local parts={}
        for _,o in ipairs(model:GetDescendants()) do
            if o:IsA("BasePart") then
                parts[#parts+1]=o
                if not visited[o] then
                    assert(o.Parent~=model,"Disconnected body part")
                    fallback[#fallback+1]={part=o,offset=targetRoot.CFrame:ToObjectSpace(o.CFrame)}
                end
            elseif o:IsA("Animator") then o:Destroy() end
        end
        for _,j in ipairs(joints) do pcall(function() j.object.Enabled=false end) end
        return {root=targetRoot,sourceRoot=sourceRoot,edges=ordered,fallback=fallback,parts=parts}
    end
    local function inTool(o,source)
        local p=o.Parent
        while p and p~=source do if p:IsA("Tool") then return true end;p=p.Parent end
        return false
    end
    function A:HidePart(o,source)
        if inTool(o,source) then return end
        local property=o:IsA("BasePart") and "LocalTransparencyModifier" or (o:IsA("Decal") and "Transparency")
        if property and not self.hidden[o] then self.hidden[o]={property=property,value=o[property]};o[property]=1 end
    end
    function A:Restore(cancelPending)
        if cancelPending~=false then self.serial=self.serial+1;self.busy=false end
        pcall(function() RunService:UnbindFromRenderStep(self.renderName) end)
        if self.appearanceConnection then self.appearanceConnection:Disconnect();self.appearanceConnection=nil end
        for o,entry in pairs(self.hidden) do if o.Parent then pcall(function() o[entry.property]=entry.value end) end end
        self.hidden={}
        local overlay=self.overlay;self.overlay=nil
        if overlay then dispose(overlay.model) end
        if not self.dead then self:Status("คืนตัวละครเดิมแล้ว") end
    end
    function A:Wear()
        if self.dead then return end
        if self.busy then self:Status("กำลังโหลดชุดจากโปรไฟล์…");return end
        if not self.current then self:Status("ใส่ Username แล้วโหลดตัวอย่างก่อน");return end
        local h,r=character();local source=player.Character
        if not h or not r or h.Health<=0 then self:Status("รอตัวละครเกิดก่อนลองชุด");return end
        if self.current.rigType~=h.RigType then self:Status("ชนิดตัวละครเปลี่ยน กรุณาโหลดตัวอย่างใหม่");return end
        local model,pose
        local ok,err=pcall(function()
            model=sanitize(self.current.model:Clone())
            pose=self:BuildPose(model,source)
        end)
        if not ok then dispose(model);S.lastError=tostring(err);self:Status("ตัวละครแมพนี้ไม่รองรับการลองชุด • ดูตัวอย่างได้");return end
        self:Restore(false)
        model.Name="SATURN_X_LocalOutfit"
        local targetHum=model:FindFirstChildOfClass("Humanoid")
        local offset=0
        if h.RigType==Enum.HumanoidRigType.R15 and targetHum then
            offset=math.clamp(targetHum.HipHeight+pose.root.Size.Y/2-h.HipHeight-r.Size.Y/2,-5,5)
        end
        self.overlay={model=model,pose=pose,source=source,humanoid=h,offset=offset}
        local function render()
            local current=A.overlay
            if not current then return end
            if player.Character~=source or not r.Parent or h.Health<=0 then A:Restore(true);return end
            local good,problem=pcall(function()
                pose.root.CFrame=r.CFrame+Vector3.new(0,offset,0)
                for _,edge in ipairs(pose.edges) do
                    local transform=CFrame.new()
                    local sj=edge.source
                    if sj then
                        assert(sj.p0.Parent and sj.p1.Parent,"Body changed")
                        transform=sj.c0:Inverse()*sj.p0.CFrame:ToObjectSpace(sj.p1.CFrame)*sj.c1
                    end
                    if edge.forward then edge.p1.CFrame=edge.p0.CFrame*edge.c0*transform*edge.c1:Inverse()
                    else edge.p0.CFrame=edge.p1.CFrame*edge.c1*transform:Inverse()*edge.c0:Inverse() end
                end
                for _,item in ipairs(pose.fallback) do item.part.CFrame=pose.root.CFrame*item.offset end
                local cam=Workspace.CurrentCamera
                local firstPerson=cam and (cam.CFrame.Position-cam.Focus.Position).Magnitude<1
                for _,part in ipairs(pose.parts) do part.LocalTransparencyModifier=firstPerson and 1 or 0 end
                for part,entry in pairs(A.hidden) do if part.Parent then part[entry.property]=1 end end
            end)
            if not good then S.lastError=tostring(problem);A:Restore(true);A:Status("หยุดลองชุดแล้ว เพราะโครงตัวละครเปลี่ยน") end
        end
        -- Pose once before showing or hiding either model.
        render()
        if not self.overlay then return end
        local bound=pcall(function()
            model.Parent=Workspace
            for _,o in ipairs(source:GetDescendants()) do self:HidePart(o,source) end
            self.appearanceConnection=source.DescendantAdded:Connect(function(o)
                local hiddenOK=pcall(function() self:HidePart(o,source) end)
                if not hiddenOK then self:Restore(true) end
            end)
            RunService:BindToRenderStep(self.renderName,Enum.RenderPriority.Last.Value,render)
        end)
        if not bound then self:Restore(true);self:Status("เครื่องนี้ไม่รองรับการลองชุด • ดูตัวอย่างได้");return end
        self:Status("กำลังลองชุด • เห็นเฉพาะเครื่องเรา")
    end
    function A:Destroy()
        self:Restore(true);self.dead=true
        for _,c in ipairs(self.recentConnections) do c:Disconnect() end
        if self.current then dispose(self.current.model);dispose(self.current.description);self.current=nil end
    end
    local language=SXMedia.Settings.language
    connect(RunService.Heartbeat,function()
        if language~=SXMedia.Settings.language then
            language=SXMedia.Settings.language
            if A.statusText then A:Status(A.statusText) end
        end
    end)
    return A
end)()

local function restoreCollisions()
    for part, value in pairs(S.collisionSnapshot) do
        if part.Parent then pcall(function() part.CanCollide = value end) end
    end
    S.collisionSnapshot = {}
end
local function applyNoclip()
    if not S.noclip or not player.Character then return end
    for _, part in ipairs(player.Character:GetDescendants()) do
        if part:IsA("BasePart") then
            if S.collisionSnapshot[part] == nil then S.collisionSnapshot[part] = part.CanCollide end
            part.CanCollide = false
        end
    end
end
local function stopMovement()
    for _, key in ipairs({"fly", "speed", "jump", "airJump", "noclip"}) do
        if toggleSetters[key] then toggleSetters[key](false, true) end
        S[key] = false
    end
    stopFlight(); restoreCollisions(); flyControls.Visible = false
    S.up = false; S.down = false; flightTouches = {}
end
local function lightingMode(key, enabled)
    local mappings = {bright = {Brightness = 3, Ambient = Color3.fromRGB(170, 170, 185), OutdoorAmbient = Color3.fromRGB(170, 170, 185)}, noFog = {FogEnd = 100000, FogStart = 100000}, noShadows = {GlobalShadows = false}}
    for property, value in pairs(mappings[key]) do
        if enabled then
            if S.lightSnapshot[property] == nil then S.lightSnapshot[property] = Lighting[property] end
            Lighting[property] = value
        elseif S.lightSnapshot[property] ~= nil then Lighting[property] = S.lightSnapshot[property] S.lightSnapshot[property] = nil end
    end
    if key == "noFog" then
        if enabled then
            for _, a in ipairs(Lighting:GetChildren()) do
                if a:IsA("Atmosphere") then S.atmosphereSnapshot[a] = {Density = a.Density, Haze = a.Haze} a.Density = 0 a.Haze = 0 end
            end
        else
            for a, values in pairs(S.atmosphereSnapshot) do if a.Parent then a.Density = values.Density a.Haze = values.Haze end end
            S.atmosphereSnapshot = {}
        end
    end
end
local function resetFeatures()
    Avatar:Restore(true)
    stopMovement()
    for _, key in ipairs({"bright", "noFog", "noShadows"}) do
        if toggleSetters[key] then toggleSetters[key](false, true) end
    end
    if S.cameraSnapshot and S.cameraSnapshot.camera.Parent then
        pcall(function() S.cameraSnapshot.camera.FieldOfView = S.cameraSnapshot.fov end)
    end
    S.cameraSnapshot = nil
end
local stop

-- 01 / Overview
do
    local p = pages[1]
    title(p, "SATURN X AVATAR", "V1.0.0 BETA / BY BM")
    info(p, "แต่งตัวตาม Username • เมนู SATURN X ขนาดเดิม", C.text)
    info(p, "ค้นหา Username • ดูตัวอย่างสามมิติ • ลองชุดเฉพาะเครื่อง • คืนชุดเดิม • รายชื่อล่าสุด", C.text)
    info(p, "ลากแถบด้านบนเพื่อย้าย • ย่อเป็นปุ่มดาวเสาร์ • รองรับมือถือและคอมพิวเตอร์")
    info(p, "ยังไม่ได้ทดสอบในเกมจริง • เซิร์ฟเวอร์อาจจำกัดการเคลื่อนที่", C.orange)
    action(p, "เปิดเมนูแต่งตัว", function() selectTab(4) end)
    action(p, "หยุดฟีเจอร์ทั้งหมด", function() resetFeatures() notify("ปิดทุกฟีเจอร์แล้ว") end, true)
end
-- 02 / Credits
do
    local p = pages[2]
    title(p, "เครดิตผู้สร้าง", "SATURN X AVATAR / BM")
    info(p, "BM\nผู้สร้างแบรนด์และผู้ออกแบบแนวคิด SATURN X", C.text)
    info(p, "โลโก้: ดาวเสาร์สีเงินที่ BM เลือก\nเสียงเปิด / ปิด: window-opening-100430\nเสียงเลือก / คลิก: mouse-click-290204", C.text)
end
-- 03 / Profile
local profileLive
do
    local p = pages[3]
    title(p, "โปรไฟล์ผู้เล่น", "ข้อมูลของคนที่เปิดใช้เมนูนี้")
    local card = make("Frame", {Size = UDim2.new(1, 0, 0, 112), BackgroundColor3 = C.card, BorderSizePixel = 0}, p) corner(card, 12)
    local avatar = make("ImageLabel", {Name = "Avatar", Size = UDim2.fromOffset(82, 82), Position = UDim2.fromOffset(13, 15), BackgroundColor3 = C.panel}, card) corner(avatar, 41)
    local name = label(card, player.DisplayName, 18) name:SetAttribute("SATURN_X_NoTranslate",true) name.Font = Enum.Font.GothamBold name.Position = UDim2.fromOffset(108, 22) name.Size = UDim2.new(1, -118, 0, 36)
    local username = label(card, "@" .. player.Name, 12, C.accent) username:SetAttribute("SATURN_X_NoTranslate",true) username.Position = UDim2.fromOffset(108, 61) username.Size = UDim2.new(1, -118, 0, 28)
    task.spawn(function()
        for _ = 1, 3 do
            if not S.alive then return end
            local ok, url, ready = pcall(Players.GetUserThumbnailAsync, Players, player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size180x180)
            if ok and ready and S.alive then avatar.Image = url return end
            task.wait(1)
        end
    end)
    info(p, "User ID: " .. tostring(player.UserId) .. "\nอายุบัญชี: " .. tostring(player.AccountAge) .. " วัน", C.text)
    profileLive = info(p, "กำลังอ่านตัวละคร…")
end

-- 04 / Username avatar
do
    local p=pages[4]
    title(p,"แต่งตัวตาม Username","SATURN X AVATAR")
    info(p,"ใช้ Username จริง ไม่ใช่ Display Name • ดึงชุดที่ใส่บนโปรไฟล์",C.text)
    Avatar.nameInput=input(p,"ใส่ Username เช่น @ชื่อบัญชี","",function() end)
    Avatar.nameInput:SetAttribute("SATURN_X_NoTranslate",false)
    action(p,"ค้นหาและลองชุด",function() Avatar:Load(Avatar.nameInput.Text,true) end)
    action(p,"ดูตัวอย่างอย่างเดียว",function() Avatar:Load(Avatar.nameInput.Text,false) end,true)
    Avatar.userLabel=info(p,"—",C.accent);Avatar.userLabel:SetAttribute("SATURN_X_NoTranslate",true)
    Avatar.viewport=make("ViewportFrame",{Size=UDim2.new(1,0,0,260),BackgroundColor3=C.panel,BorderSizePixel=0,
        Ambient=Color3.fromRGB(210,210,210),LightColor=Color3.fromRGB(255,255,255),LightDirection=Vector3.new(-1,-1,-1)},p)
    corner(Avatar.viewport,12)
    Avatar.world=make("WorldModel",{},Avatar.viewport)
    Avatar.camera=make("Camera",{FieldOfView=35},Avatar.viewport);Avatar.viewport.CurrentCamera=Avatar.camera
    action(p,"หมุนตัวอย่างซ้าย",function() Avatar.yaw=Avatar.yaw-0.5;Avatar:FramePreview() end,true)
    action(p,"หมุนตัวอย่างขวา",function() Avatar.yaw=Avatar.yaw+0.5;Avatar:FramePreview() end,true)
    action(p,"ลองชุดจากตัวอย่าง",function() Avatar:Wear() end)
    action(p,"คืนชุดเดิม / ยกเลิกโหลด",function() Avatar:Restore(true) end,true)
    Avatar.statusLabel=info(p,"",C.orange);Avatar.statusLabel:SetAttribute("SATURN_X_NoTranslate",true)
    Avatar:Status("ใส่ Username แล้วโหลดตัวอย่างก่อน")
    info(p,"ชุดที่ลองเห็นเฉพาะเครื่องเรา • บัญชีและชุดที่ผู้อื่นเห็นยังเป็นของเดิม")
    info(p,"ตัวละครพิเศษและ R6 อาจแสดงบางชิ้นไม่ครบ • เกิดใหม่แล้วกดลองชุดอีกครั้ง")
end

-- 05 / Movement
do
    local p = pages[5]
    title(p, "เคลื่อนที่", "MOVEMENT")
    info(p, "มือถือ: จอยเดินและปุ่ม ↑ ↓ • คอม: WASD และ Space / Ctrl", C.text)
    toggle(p, "บิน", "fly", function(value)
        if value then return startFlight() end
        stopFlight(); flyControls.Visible = false; return true
    end)
    stepper(p, "ความเร็วบิน", "flySpeed", 10, 150, 5)
    action(p, "หยุดบิน", function() toggleSetters.fly(false) end, true)
    toggle(p, "ปรับความเร็วเดิน", "speed", function(v)
        if v and not gameReady() then return false end
        S.speed=v; applyMovement(); return true
    end)
    stepper(p, "ความเร็วเดิน", "walkSpeed", 8, 100, 2, function() if S.speed then applyMovement() end end)
    toggle(p, "ปรับความสูงกระโดด", "jump", function(v)
        if v and not gameReady() then return false end
        S.jump=v; applyMovement(); return true
    end)
    stepper(p, "ความสูงกระโดด", "jumpHeight", 5, 50, 1, function() if S.jump then applyMovement() end end)
    toggle(p, "กระโดดกลางอากาศ", "airJump", function(v) return not v or gameReady() end)
    toggle(p, "เดินทะลุ", "noclip", function(v)
        if v and not gameReady() then return false end
        if not v then restoreCollisions() end
        return true
    end)
    info(p, "เกิดใหม่แล้วระบบจะปิดการเคลื่อนที่พิเศษ • เปิดอีกครั้งเมื่อพร้อม")
    action(p, "หยุดฟีเจอร์ทั้งหมด", function() resetFeatures() notify("ปิดทุกฟีเจอร์แล้ว") end, true)
end
-- 06 / Visuals
do
    local p = pages[6]
    title(p, "ภาพ / กล้อง", "VISUALS")
    toggle(p, "เพิ่มความสว่าง", "bright", function(v) lightingMode("bright", v); return true end)
    toggle(p, "ลดหมอก", "noFog", function(v) lightingMode("noFog", v); return true end)
    toggle(p, "ปิดเงา", "noShadows", function(v) lightingMode("noShadows", v); return true end)
    S.fov = Workspace.CurrentCamera and math.floor(Workspace.CurrentCamera.FieldOfView) or 70
    stepper(p, "มุมมองกล้อง FOV", "fov", 50, 110, 5, function()
        local cam = Workspace.CurrentCamera
        if cam then
            if not S.cameraSnapshot or S.cameraSnapshot.camera ~= cam then
                S.cameraSnapshot = {camera=cam, fov=cam.FieldOfView}
            end
            cam.FieldOfView=S.fov
        end
    end)
    action(p, "คืนค่าภาพและกล้อง", function()
        for _, k in ipairs({"bright", "noFog", "noShadows"}) do toggleSetters[k](false) end
        if S.cameraSnapshot and S.cameraSnapshot.camera.Parent then
            S.cameraSnapshot.camera.FieldOfView=S.cameraSnapshot.fov
        end
        S.cameraSnapshot=nil
    end, true)
end
-- 07 / Recent usernames (session only; not saved outfit snapshots)
do
    local p=pages[7]
    title(p,"รายชื่อล่าสุด","RECENT USERNAMES")
    info(p,"จำ 8 รายชื่อในครั้งนี้ • แตะชื่อเพื่อโหลดชุดโปรไฟล์ล่าสุด")
    Avatar.recentFrame=make("Frame",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y},p)
    make("UIListLayout",{Padding=UDim.new(0,8)},Avatar.recentFrame)
    action(p,"ล้างรายชื่อล่าสุด",function() Avatar.recent={};Avatar:RenderRecent() end,true)
end

-- 08 / Shared settings
do
    local p=pages[8]
    title(p, "ตั้งค่า", "SATURN X AVATAR")
    action(p, "เพลง / ภาษา / หน้าโหลด", function() SXMedia:OpenSettings(true) end)
    action(p, "ทดสอบเสียงเปิด / ปิด", function() playSound("window") end, true)
    info(p, "ไทย / English / 中文 • ใช้เสียงและตั้งค่าร่วมกับ SATURN X")
    info(p, "Right Shift: เปิดหรือย่อเมนู • End: หยุดฟีเจอร์ทั้งหมด")
    action(p, "หยุดทั้งหมด / คืนค่า", function() resetFeatures(); notify("ปิดทุกฟีเจอร์แล้ว") end, true)
    action(p, "ปิด SATURN X AVATAR", function() stop() end, true)
end

stop = function(silent)
    if not S.alive then return end
    if not silent then playSound("window") end
    resetFeatures(); Avatar:Destroy(); S.alive=false; SXSession:Close()
    for _, c in ipairs(S.connections) do c:Disconnect() end
    gui:Destroy()
    if environment.SATURN_X_AVATAR_STOP == stop then environment.SATURN_X_AVATAR_STOP=nil end
end
environment.SATURN_X_AVATAR_STOP=stop
connect(close.Activated, function() stop(false) end)
connect(gui.Destroying, function() if S.alive then stop(true) end end)
connect(UIS.InputBegan, function(e, processed)
    if processed or UIS:GetFocusedTextBox() then return end
    if e.KeyCode == Enum.KeyCode.RightShift then setOpen(not S.open) end
    if e.KeyCode == Enum.KeyCode.End then resetFeatures(); notify("หยุดฟีเจอร์ทั้งหมดแล้ว") end
end)
connect(UIS.WindowFocusReleased, function()
    S.focused=false; S.up=false; S.down=false; flightTouches={}
    if S.flight and S.flight.velocity then S.flight.velocity.VectorVelocity=Vector3.zero end
end)
connect(UIS.WindowFocused, function() S.focused=true end)
connect(player.CharacterRemoving, function() Avatar:Restore(true);stopMovement(); S.humSnapshot=nil end)
connect(player.CharacterAdded, function() S.humSnapshot=nil end)
local jumpAt=0
connect(UIS.JumpRequest, function()
    if not S.airJump or S.fly or not S.focused or UIS:GetFocusedTextBox() then return end
    if os.clock()-jumpAt < 0.18 then return end
    local h,r=character()
    if not h or not r or h.Health<=0 or h.SeatPart then return end
    jumpAt=os.clock()
    local power=h.UseJumpPower and h.JumpPower or math.sqrt(2*Workspace.Gravity*h.JumpHeight)
    if S.jump then power=math.sqrt(2*Workspace.Gravity*S.jumpHeight) end
    local v=r.AssemblyLinearVelocity
    r.AssemblyLinearVelocity=Vector3.new(v.X, power, v.Z)
    h:ChangeState(Enum.HumanoidStateType.Jumping)
end)
local controls
task.spawn(function()
    local ps=player:FindFirstChild("PlayerScripts")
    local pm=ps and ps:FindFirstChild("PlayerModule")
    if pm then
        local ok,value=pcall(function() return require(pm):GetControls() end)
        if ok and S.alive then controls=value end
    end
end)
connect(RunService.PreSimulation, function()
    if S.noclip then applyNoclip() end
end)
connect(RunService.RenderStepped, function(dt)
    if dt>0 then S.fps=S.fps*0.9+math.min(999,1/dt)*0.1 end
    local f,cam=S.flight,Workspace.CurrentCamera
    if not S.fly or not f then return end
    if not f.r.Parent or not f.h.Parent or f.h.Health<=0 or f.h.SeatPart then
        toggleSetters.fly(false, true); return
    end
    if not cam or not S.focused or UIS:GetFocusedTextBox() then
        f.velocity.VectorVelocity=Vector3.zero; return
    end
    local vertical=(S.up and 1 or 0)-(S.down and 1 or 0)
    if UIS:IsKeyDown(Enum.KeyCode.Space) then vertical=vertical+1 end
    if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then vertical=vertical-1 end
    local flat=Vector3.new(cam.CFrame.LookVector.X,0,cam.CFrame.LookVector.Z)
    local direction=f.h.MoveDirection
    if controls and flat.Magnitude>0.01 then
        local ok,mv=pcall(function() return controls:GetMoveVector() end)
        if ok and typeof(mv)=="Vector3" then
            local forward=flat.Unit
            local right=Vector3.new(-forward.Z,0,forward.X)
            direction=right*mv.X-forward*mv.Z
        end
    end
    direction=direction+Vector3.new(0,math.clamp(vertical,-1,1),0)
    if direction.Magnitude>1 then direction=direction.Unit end
    f.velocity.VectorVelocity=direction*S.flySpeed
    if flat.Magnitude>0.01 then f.orientation.CFrame=CFrame.lookAt(Vector3.zero,flat.Unit) end
end)
task.spawn(function()
    while S.alive do
        guarded(function()
            local h,r=character()
            if h and r then
                profileLive.Text=string.format("พลังชีวิต %.0f / %.0f\nตำแหน่ง %.0f, %.0f, %.0f\nผู้เล่นในเซิร์ฟเวอร์ %d • FPS %.0f",h.Health,h.MaxHealth,r.Position.X,r.Position.Y,r.Position.Z,#Players:GetPlayers(),S.fps)
            else profileLive.Text="กำลังรอตัวละครเกิด…" end
            footer.Text=string.format("SATURN X AVATAR • %s • FPS %.0f",CONFIG.Version,S.fps)
        end)
        task.wait(1)
    end
end)
-- SATURN X orbital navigation: existing page callbacks and dimensions are retained.
local orbitMenu = SXMedia.Orbit:Create({
    Gui=gui, Root=root, Window=window, Floating=floating, Logo=logo, Minimize=minimize,
    Names=tabNames, OnSelect=selectTab,
    OnVisible=function(value) S.open=value; SXSession:SetVisible(value) end,
    PlayWindow=function() playSound("window") end,
})
setOpen=function(value) orbitMenu:SetOpen(value) end
orbitMenu:Open(false)
SXSession:Bind(gui)
SXSession:Finish()
SXMedia:Asset("logo",function(id)
    if id and S.alive then
        logo.Image=id; floating.Image=id
        logoFallback.Visible=false; floatingFallback.Visible=false
    end
end)
selectTab(1)

