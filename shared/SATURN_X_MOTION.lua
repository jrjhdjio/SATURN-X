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
