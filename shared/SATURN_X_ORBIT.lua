-- SATURN X Orbit 1.3.0 / BM
-- UI-only extension. The original eight pages and their handlers stay in place.
local function InstallOrbit(M)
    if M.Orbit and M.Orbit.Alive and M.Orbit.Version=="1.3.0" then return M.Orbit end
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
    local Orbit={Version="1.3.0",Alive=true,Controllers={},Assets=previous and previous.Assets or {},Jobs={},Tracks={},
        AnimationFrames=20,AnimationFPS=60}
    local frameDuration=Orbit.AnimationFrames/Orbit.AnimationFPS
    M.Orbit=Orbit;M.Build="1.5.0-orbit"
    local function moving()
        return M.Settings.motionEnabled~=false and not (M.Motion and M.Motion.Reduced)
    end
    -- One 20-pose clock also serves ordinary buttons, colors and shared panels.
    function Orbit:Animate(o,props,easing,owner,pulse,complete)
        if self.Tracks[o] then self.Tracks[o]:Cancel() end
        if not self.Alive or not M.Alive or not o.Parent or (owner and not owner.Alive) then return end
        local from={};for key in pairs(props) do from[key]=o[key] end
        local target=pulse and from or props
        if not moving() then
            for key,value in pairs(target) do o[key]=value end
            if complete then complete() end
            return
        end
        local t={Elapsed=0,Frame=1,Samples={},Target=target,Complete=complete}
        for frame=1,self.AnimationFrames do
            local progress=(frame-1)/(self.AnimationFrames-1)
            local alpha=pulse and math.sin(math.pi*progress) or
                TweenService:GetValue(progress,easing or Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
            local pose={}
            for key,value in pairs(props) do
                local start=from[key]
                pose[key]=type(start)=="number" and (start+(value-start)*alpha) or start:Lerp(value,alpha)
            end
            t.Samples[frame]=pose
        end
        function t:Cancel()
            if Orbit.Tracks[o]==self then Orbit.Tracks[o]=nil end
            if owner then
                if owner.FrameAnimations[o]==self then owner.FrameAnimations[o]=nil end
                if owner.Tweens[o]==self then owner.Tweens[o]=nil end
            end
        end
        self.Tracks[o]=t
        if owner then owner.FrameAnimations[o]=t;owner.Tweens[o]=t end
        for key,value in pairs(t.Samples[1]) do o[key]=value end
        return t
    end
    Orbit.FrameConnection=RunService.Heartbeat:Connect(function(dt)
        for o,t in pairs(Orbit.Tracks) do
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
                    t:Cancel();if t.Complete then t.Complete() end
                end
            end
        end
    end)
    function M:Animate20(o,props,easing,complete) return Orbit:Animate(o,props,easing,nil,false,complete) end
    function M:Pulse20(o,props) return Orbit:Animate(o,props,nil,nil,true) end
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
            Options=options,Planets={},Rings={},Sprites={},Angle=0,Hover={},Pointers={},FeedbackScales={}}
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
        local function animate20(o,props,easing)
            return Orbit:Animate(o,props,easing,C)
        end
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
        local function feedback(button,visual)
            local scale=own("UIScale",{Name="OrbitButtonScale",Scale=1},visual)
            table.insert(C.FeedbackScales,scale)
            local hover=false;local pointer
            local function release()
                pointer=nil
                animate20(scale,{Scale=moving() and M.Settings.pressMotionEnabled~=false and hover and 1.05 or 1})
            end
            connect(button.MouseEnter,function() hover=true;release() end)
            connect(button.MouseLeave,function() hover=false;release() end)
            connect(button.SelectionGained,function() hover=true;release() end)
            connect(button.SelectionLost,function() hover=false;release() end)
            connect(button.InputBegan,function(input)
                if M.Settings.pressMotionEnabled~=false and (input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1) then
                    pointer=input;animate20(scale,{Scale=.96})
                end
            end)
            connect(UIS.InputEnded,function(input) if pointer==input then release() end end)
            connect(button.Activated,function()
                if M.Settings.pressMotionEnabled~=false then
                    scale.Scale=1;Orbit:Animate(scale,{Scale=.94},nil,C,true)
                end
            end)
            connect(UIS.WindowFocusReleased,function() hover=false;release() end)
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
            connect(b.MouseEnter,function() C.Hover[b]=true;animate20(scale,{Scale=planetScale(i)}) end)
            connect(b.MouseLeave,function() C.Hover[b]=nil;animate20(scale,{Scale=planetScale(i)}) end)
            connect(b.SelectionGained,function() C.Hover[b]=true;animate20(scale,{Scale=planetScale(i)}) end)
            connect(b.SelectionLost,function() C.Hover[b]=nil;animate20(scale,{Scale=planetScale(i)}) end)
            connect(b.InputBegan,function(input)
                if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
                    C.Pointers[input]=true
                    if M.Settings.pressMotionEnabled~=false then animate20(scale,{Scale=.96}) end
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
        connect(returnButton.Activated,function() C:Back() end)
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
            if not self.Alive or self.Closing then return end
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
            if not self.Alive or self.Closing then return end
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
        function C:Back()
            if not self.Alive or self.Closing then return end
            if self.State~="category" then self:Open(true);return end
            local serial=self:Cancel();self.State="returning"
            animate20(options.Window,{GroupTransparency=1})
            if pageScale then animate20(pageScale,{Scale=.965}) end
            later(serial,frameDuration,function() self:Open(true) end)
        end
        function C:Close(callback)
            if not self.Alive or self.Closing then return end
            self:SetOpen(false);self.Closing=true
            local serial=self.Serial
            later(serial,frameDuration,callback)
        end
        connect(core.Activated,function()
            if C.State=="orbit" and C.Selected then C.Selected=nil;C:Refresh();M:Click() end
        end)
        feedback(core,core);feedback(black,black);feedback(returnButton,options.Logo)
        connect(UIS.InputEnded,function(input)
            if C.Pointers[input] then
                C.Pointers[input]=nil
                for i,p in ipairs(C.Planets) do animate20(p.Scale,{Scale=planetScale(i)},Enum.EasingStyle.Back) end
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
            for _,scale in ipairs(self.FeedbackScales) do scale:Destroy() end
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
        for _,track in pairs(self.Tracks) do track:Cancel() end
        self.FrameConnection:Disconnect()
        self.Jobs={};if self.Wave then self.Wave:Destroy() end
    end
    function Orbit:Close(gui,callback)
        local controller=self.Controllers[gui]
        if controller and controller.Alive then controller:Close(callback) else callback() end
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
