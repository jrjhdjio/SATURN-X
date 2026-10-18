--[[
NEPTUNE X | 100 Days At Sea | EXPERIMENTAL 0.1 | 2026-10-18
โค้ด Lua ทั้งหมด: คัดลอกทั้งไฟล์ไปรันหลังเข้าแมพและเริ่มรอบแล้ว

วิธีใช้
1. กด START เพื่อให้พยายามเก็บของที่มี ProximityPrompt อยู่ในระยะปกติ
2. เปิด AUTO WALK หากต้องการเดินเข้าหาของที่ตรวจพบ (สูงสุด 40 studs)
3. STOP หยุดทันที / ขีด - ย่อหน้าต่าง / แตะดาวเพื่อเปิดกลับ / X ปิดทั้งหมด
4. ถ้าไม่เก็บ ให้ยืนข้างของ กด INFO แล้วส่งข้อมูลหรือภาพหน้าจอกลับมา

ขอบเขตที่ต้องรู้: ยังไม่ได้ทดสอบในเซิร์ฟเวอร์จริงของแมพนี้
นี่เป็นระบบช่วยเก็บของผ่าน ProximityPrompt ไม่ใช่บอทเล่นครบ 100 วัน
ไม่รองรับการยิงฉมวก ระบบหิว สร้างแพ ต่อสู้ หรือปุ่มโต้ตอบเฉพาะเกมที่ยังไม่รู้
ไม่เดาชื่อ RemoteEvent และไม่มีการโหลดโค้ดจากเว็บภายนอก
จำนวน ATTEMPTS คือจำนวนครั้งที่สั่งโต้ตอบ ไม่ใช่จำนวนของที่เซิร์ฟเวอร์ยืนยัน
ภาพดาวใน UI เป็นไอคอนวาดด้วย GUI ไม่ใช่ไฟล์ภาพโลโก้ที่สร้างไว้ก่อนหน้า
]]

local Config = {
    PlaceId = 70411440483149,
    UniverseId = 9167377564,
    ScanRadius = 40,
    TickInterval = 0.30,
    RetryCooldown = 7,
    FailureCooldown = 16,
    MaxHoldSeconds = 8,
    MinHealthRatio = 0.35,
    -- ว่างไว้ = ใช้ไอคอนดาวที่วาดด้วย GUI; ใส่ asset ของคุณได้ภายหลัง
    LogoAsset = "",
}

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")
local UserInputService = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local player = Players.LocalPlayer
if not player then warn("NEPTUNE X: run on the client") return end

local env = type(getgenv) == "function" and getgenv() or _G
local slot = "NEPTUNE_X_SEA_SESSION"
if type(env[slot]) == "table" and type(env[slot].Destroy) == "function" then
    pcall(env[slot].Destroy)
end

local S = {
    alive = true, running = false, walking = false, ready = false,
    generation = 0, heldPrompt = nil, movedHumanoid = nil,
    prompts = {}, cooldowns = {}, shown = {}, connections = {},
    attempts = 0, eligible = 0, total = 0, status = "กำลังสำรวจปุ่มโต้ตอบ…",
    lastError = "", lastAction = "-",
}
env[slot] = S
local correctGame = game.PlaceId == Config.PlaceId or game.GameId == Config.UniverseId

local function connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(S.connections, connection)
    return connection
end

local function character()
    local c = player.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    local r = c and c:FindFirstChild("HumanoidRootPart")
    if c and h and r and h.Health > 0 then return c, h, r end
end

local function releaseHold()
    local prompt = S.heldPrompt
    S.heldPrompt = nil
    if prompt then pcall(function() prompt:InputHoldEnd() end) end
end

local function releaseMovement()
    local h = S.movedHumanoid
    S.movedHumanoid = nil
    if h and h.Parent then
        pcall(function()
            local r = h.RootPart
            if r then h:MoveTo(r.Position) end
            h:Move(Vector3.zero, false)
        end)
    end
end

local refresh = function() end
local function stop(reason)
    S.running = false
    S.generation = S.generation + 1
    releaseHold()
    releaseMovement()
    if reason then S.status = reason end
    refresh()
end

local gui = Instance.new("ScreenGui")
gui.Name = "NEPTUNE_X_Sea"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 80
gui.IgnoreGuiInset = false
local parent = player:WaitForChild("PlayerGui", 15)
if type(gethui) == "function" then
    local ok, hidden = pcall(gethui)
    if ok and typeof(hidden) == "Instance" then parent = hidden end
end
if not parent then S.alive = false; env[slot] = nil; return end
local parentOK = pcall(function() gui.Parent = parent end)
if not parentOK then gui.Parent = player:WaitForChild("PlayerGui") end

local C = {
    background = Color3.fromRGB(9, 19, 42),
    panel = Color3.fromRGB(17, 37, 67),
    blue = Color3.fromRGB(28, 109, 244),
    sky = Color3.fromRGB(73, 201, 255),
    text = Color3.fromRGB(235, 246, 255),
    muted = Color3.fromRGB(151, 178, 206),
    red = Color3.fromRGB(180, 59, 82),
}

local function make(class, properties, parentObject)
    local object = Instance.new(class)
    for key, value in pairs(properties) do object[key] = value end
    object.Parent = parentObject
    return object
end
local function round(object, pixels)
    make("UICorner", { CornerRadius = UDim.new(0, pixels or 12) }, object)
end
local function label(parentObject, text, x, y, w, h, size, color)
    return make("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(x, y),
        Size = UDim2.fromOffset(w, h), Text = text, TextSize = size or 14,
        TextColor3 = color or C.text, Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
    }, parentObject)
end
local function button(parentObject, text, x, y, w, h, color)
    local b = make("TextButton", {
        Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h),
        BackgroundColor3 = color or C.panel, BorderSizePixel = 0,
        Text = text, TextColor3 = C.text, TextSize = 13,
        Font = Enum.Font.GothamBold, AutoButtonColor = true,
    }, parentObject)
    round(b, 10)
    return b
end

local function planet(parentObject, x, y, size)
    if Config.LogoAsset ~= "" then
        return make("ImageLabel", {
            BackgroundTransparency = 1, Position = UDim2.fromOffset(x,y),
            Size = UDim2.fromOffset(size,size), Image = Config.LogoAsset,
            ScaleType = Enum.ScaleType.Fit,
        }, parentObject)
    end
    local disk = make("Frame", {
        Position = UDim2.fromOffset(x,y), Size = UDim2.fromOffset(size,size),
        BorderSizePixel = 0, BackgroundColor3 = Color3.new(1,1,1),
    }, parentObject)
    round(disk, size)
    make("UIGradient", {
        Rotation = 35,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(125,229,255)),
            ColorSequenceKeypoint.new(0.40, Color3.fromRGB(24,137,255)),
            ColorSequenceKeypoint.new(0.73, Color3.fromRGB(21,77,216)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(7,24,83)),
        }),
    }, disk)
    for _, stripe in ipairs({{.18,.28,.61,.065},{.12,.45,.74,.05},{.23,.67,.56,.04}}) do
        local band = make("Frame", {
            Position = UDim2.fromScale(stripe[1],stripe[2]),
            Size = UDim2.fromScale(stripe[3],stripe[4]),
            BorderSizePixel = 0, BackgroundColor3 = C.sky, BackgroundTransparency = .40,
            Rotation = -12,
        }, disk)
        round(band, size)
    end
    return disk
end

-- An inset-aware screen container also clamps dragging after orientation changes.
local screen = make("Frame", { Size = UDim2.fromScale(1,1), BackgroundTransparency = 1 }, gui)
local panel = make("Frame", {
    Size = UDim2.fromOffset(334,418), Position = UDim2.new(.5,-167,.5,-209),
    BorderSizePixel = 0, BackgroundColor3 = C.background,
    BackgroundTransparency = .04, Active = true,
}, screen)
round(panel, 18)
make("UIStroke", { Color = C.blue, Thickness = 1, Transparency = .25 }, panel)
local scale = make("UIScale", { Scale = 1 }, panel)
local header = make("Frame", {
    Size = UDim2.new(1,-88,0,68), BackgroundTransparency = 1, Active = true,
}, panel)
planet(header, 14, 14, 38)
label(header,"NEPTUNE X",62,11,180,27,20).Font = Enum.Font.GothamBold
label(header,"100 DAYS AT SEA  ·  TEST 0.1",62,37,180,19,9,C.muted)
local minimize = button(panel,"−",250,17,30,31)
local close = button(panel,"×",287,17,30,31)
local tag = label(panel,"AUTO COLLECT ASSIST",16,72,302,22,12,C.sky)
tag.Font = Enum.Font.GothamBold
local statusText = label(panel,S.status,16,102,302,49,14)
statusText.TextWrapped = true
statusText.TextYAlignment = Enum.TextYAlignment.Top
local stats = label(panel,"PROMPTS 0   •   MATCH 0   •   ATTEMPTS 0",16,153,302,22,10,C.muted)
local startButton = button(panel,"START",16,188,146,44,C.blue)
local stopButton = button(panel,"STOP",172,188,146,44,C.red)
local walkButton = button(panel,"AUTO WALK  ·  OFF",16,243,302,39)
local rangeButton = button(panel,"ระยะค้นหา  40 studs",16,292,184,34)
local infoButton = button(panel,"INFO",210,292,108,34)
local note = label(panel,"เก็บเฉพาะของที่มีปุ่มโต้ตอบ\nยังไม่รองรับฉมวก / สร้างแพ / เล่นครบ 100 วัน",16,335,302,43,11,C.muted)
note.TextWrapped = true
label(panel,"ลากแถบชื่อเพื่อย้าย  ·  ย่อแล้วแตะดาวเพื่อเปิด",16,384,302,20,10,C.muted)

local bubble = button(screen,"",18,90,50,50,C.background)
round(bubble,25)
planet(bubble,7,7,36)
bubble.Visible = false

local info = make("Frame", {
    Size = UDim2.fromScale(1,1), BackgroundColor3 = C.background,
    BorderSizePixel = 0, Visible = false, ZIndex = 10,
}, panel)
round(info,18)
label(info,"ข้อมูลตรวจสอบ",16,16,230,28,18).ZIndex = 11
local infoClose = button(info,"กลับ",258,16,60,31)
infoClose.ZIndex = 11
local report = make("TextBox", {
    Position = UDim2.fromOffset(16,61), Size = UDim2.fromOffset(302,293),
    BackgroundColor3 = C.panel, BorderSizePixel = 0,
    TextColor3 = C.text, TextSize = 11, Font = Enum.Font.Code,
    TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
    TextWrapped = true, MultiLine = true, ClearTextOnFocus = false,
    TextEditable = false, Text = "", ZIndex = 11,
}, info)
round(report,10)
local copyButton = button(info,"คัดลอกข้อมูล",16,366,146,35,C.blue)
copyButton.ZIndex = 11
local refreshInfo = button(info,"อ่านใหม่",172,366,146,35)
refreshInfo.ZIndex = 11

refresh = function()
    if not S.alive then return end
    statusText.Text = S.status
    stats.Text = string.format("PROMPTS %d   •   MATCH %d   •   ATTEMPTS %d",S.total,S.eligible,S.attempts)
    startButton.Text = S.running and "RUNNING" or "START"
    startButton.BackgroundColor3 = S.running and Color3.fromRGB(16,112,141) or C.blue
    walkButton.Text = "AUTO WALK  ·  " .. (S.walking and "ON" or "OFF")
    walkButton.BackgroundColor3 = S.walking and Color3.fromRGB(24,82,139) or C.panel
    rangeButton.Text = "ระยะค้นหา  " .. Config.ScanRadius .. " studs"
end

local function clampPosition(object, sizeScale)
    local available = screen.AbsoluteSize
    if available.X < 1 or available.Y < 1 then return end
    local x = object.Position.X.Scale * available.X + object.Position.X.Offset
    local y = object.Position.Y.Scale * available.Y + object.Position.Y.Offset
    local w = object.Size.X.Offset * (sizeScale or 1)
    local h = object.Size.Y.Offset * (sizeScale or 1)
    object.Position = UDim2.fromOffset(
        math.clamp(x,0,math.max(0,available.X-w)),
        math.clamp(y,0,math.max(0,available.Y-h))
    )
end
local function fit()
    local size = screen.AbsoluteSize
    if size.X < 1 or size.Y < 1 then return end
    scale.Scale = math.min(1,math.max(.35,math.min((size.X-16)/334,(size.Y-16)/418)))
    clampPosition(panel,scale.Scale)
    clampPosition(bubble,1)
end
connect(screen:GetPropertyChangedSignal("AbsoluteSize"),fit)
task.defer(fit)

local lastBubbleDrag = 0
local function draggable(handle, object, isBubble)
    local dragging, pointer, startPosition, startPoint, moved = false,nil,nil,nil,false
    connect(handle.InputBegan,function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        dragging, pointer, moved = true,input,false
        startPoint, startPosition = input.Position,object.Position
    end)
    connect(UserInputService.InputChanged,function(input)
        if not dragging then return end
        if pointer.UserInputType == Enum.UserInputType.Touch then
            if input ~= pointer then return end
        elseif input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        local delta = input.Position-startPoint
        if delta.Magnitude > 5 then moved = true end
        if moved then
            object.Position = UDim2.new(startPosition.X.Scale,startPosition.X.Offset+delta.X,
                startPosition.Y.Scale,startPosition.Y.Offset+delta.Y)
            clampPosition(object,isBubble and 1 or scale.Scale)
            if isBubble then lastBubbleDrag = os.clock() end
        end
    end)
    connect(UserInputService.InputEnded,function(input)
        if input == pointer then
            dragging = false
            if isBubble and moved then lastBubbleDrag = os.clock() end
        end
    end)
end
draggable(header,panel,false)
draggable(bubble,bubble,true)
connect(minimize.Activated,function() panel.Visible=false; bubble.Visible=true end)
connect(bubble.Activated,function()
    if os.clock()-lastBubbleDrag < .25 then return end
    panel.Visible=true; bubble.Visible=false; fit()
end)

-- Text matching uses word boundaries: "take" must not match "stake".
local function hasWord(text, words)
    local t = " " .. string.lower(text):gsub("[^%w]"," ") .. " "
    for _, word in ipairs(words) do
        if t:find(" " .. word .. " ",1,true) then return true end
    end
    return false
end
local function hasThai(text, words)
    for _, word in ipairs(words) do if text:find(word,1,true) then return true end end
    return false
end
local denyWords = {"buy","purchase","sell","upgrade","build","craft","revive","trade",
    "donate","teleport","travel","start","join","leave","sail","repair","deposit","fuel","feed","open"}
local collectWords = {"collect","pickup","pick up","grab","take","loot","harvest","gather"}
local resourceWords = {"wood","plank","planks","scrap","metal","rope","stone","sticks","plastic","resources"}

local function eligible(prompt)
    if not prompt.Parent or not prompt.Enabled or not prompt:IsDescendantOf(Workspace) then return false end
    local action = prompt.ActionText or ""
    local text = action .. " " .. (prompt.ObjectText or "") .. " " .. prompt.Parent.Name
    if hasWord(text,denyWords) or hasThai(text,{"ซื้อ","ขาย","อัปเกรด","สร้าง","ซ่อม","เติม","ฝาก","เปิด","ชุบ","แลก"}) then return false end
    local node = prompt.Parent
    while node and node ~= Workspace do
        if node:IsA("Model") and (node:FindFirstChildOfClass("Humanoid") or Players:GetPlayerFromCharacter(node)) then return false end
        if node:IsA("Tool") then return false end
        node = node.Parent
    end
    if hasWord(action,collectWords) or hasThai(action,{"เก็บ","หยิบ","รับของ"}) then return true end
    return hasWord(action,{"interact"}) and hasWord(text,resourceWords)
end

local function promptPosition(prompt)
    local parentObject = prompt.Parent
    if not parentObject then return nil end
    if parentObject:IsA("Attachment") then return parentObject.WorldPosition end
    if parentObject:IsA("BasePart") then return parentObject.Position end
    if parentObject:IsA("Model") and parentObject.PrimaryPart then return parentObject.PrimaryPart.Position end
end

local function cast(origin,direction,extra,solidOnly)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local exclusions = {}
    if player.Character then table.insert(exclusions,player.Character) end
    if extra then table.insert(exclusions,extra) end
    params.FilterDescendantsInstances = exclusions
    params.IgnoreWater = false
    params.RespectCanCollide = solidOnly == true
    return Workspace:Raycast(origin,direction,params)
end

local function lineOfSight(prompt,position)
    if not prompt.RequiresLineOfSight then return true end
    local c,_,r = character()
    if not c then return false end
    local head = c:FindFirstChild("Head")
    local origin = head and head.Position or r.Position
    local hit = cast(origin,position-origin,nil,false)
    if not hit then return true end
    local holder = prompt.Parent
    if holder:IsA("Attachment") then holder = holder.Parent end
    return hit.Instance == holder or hit.Instance:IsDescendantOf(holder)
end

local function interactionReady(prompt)
    local _,_,root = character()
    local position = promptPosition(prompt)
    if not root or not position or not eligible(prompt) then return false end
    local radius = math.max(0,prompt.MaxActivationDistance-.5)
    return (root.Position-position).Magnitude <= radius and lineOfSight(prompt,position)
end

local function active(token)
    if not S.alive or not S.running or token ~= S.generation then return false end
    local _,h = character()
    if not h then stop("หยุด: ตัวละครไม่พร้อมหรือเสียชีวิต"); return false end
    if h.Health / math.max(1,h.MaxHealth) < Config.MinHealthRatio then
        stop("หยุด: เลือดต่ำกว่า 35% — ดูแลตัวละครก่อน"); return false
    end
    if h:GetState() == Enum.HumanoidStateType.Swimming then
        stop("หยุด: ตัวละครกำลังว่ายน้ำ"); return false
    end
    if h.Sit then stop("หยุด: ตัวละครนั่งอยู่"); return false end
    return true
end

local function supportedSegment(from,to,humanoid)
    local distance = (to-from).Magnitude
    if distance > 12 then return false end
    local drop = math.clamp(humanoid.HipHeight+4,5,10)
    local count = math.max(1,math.ceil(distance/1.5))
    for index=0,count do
        local point = from:Lerp(to,index/count)
        local hit = cast(point+Vector3.new(0,1,0),Vector3.new(0,-drop,0),nil,true)
        if not hit or hit.Material == Enum.Material.Water or hit.Normal.Y < .65 then return false end
        if hit.Instance:IsA("BasePart") and (not hit.Instance.CanCollide or hit.Instance.AssemblyLinearVelocity.Magnitude > 3) then return false end
    end
    return true
end

local function moveToward(prompt,token)
    if not S.walking or not active(token) then return false end
    local _,h,r = character()
    local position = promptPosition(prompt)
    if not position then return false end
    local ground = cast(position+Vector3.new(0,3,0),Vector3.new(0,-14,0),prompt.Parent,true)
    if not ground or ground.Material == Enum.Material.Water then return false end
    local path = PathfindingService:CreatePath({
        AgentRadius = 2, AgentHeight = 5, AgentCanJump = false,
        AgentCanClimb = false, WaypointSpacing = 3, Costs = { Water = math.huge },
    })
    local ok,err = pcall(function() path:ComputeAsync(r.Position,ground.Position) end)
    if not active(token) or not S.walking then path:Destroy(); return false end
    if not ok or path.Status ~= Enum.PathStatus.Success then
        if not ok then S.lastError = tostring(err) end
        path:Destroy(); return false
    end
    local waypoints = path:GetWaypoints()
    path:Destroy()
    local pathStart = os.clock()
    for _,waypoint in ipairs(waypoints) do
        if not active(token) or not S.walking then releaseMovement(); return false end
        if interactionReady(prompt) then releaseMovement(); return true end
        local _,currentH,currentR = character()
        if currentH ~= h or not currentR then releaseMovement(); return false end
        if not eligible(prompt) then releaseMovement(); return false end
        local nowPosition = promptPosition(prompt)
        if not nowPosition or (nowPosition-position).Magnitude > 4 then releaseMovement(); return false end
        if waypoint.Action == Enum.PathWaypointAction.Jump then releaseMovement(); return false end
        local target = Vector3.new(waypoint.Position.X,currentR.Position.Y,waypoint.Position.Z)
        local delta = target-currentR.Position
        if delta.Magnitude > 1.4 then
            if not supportedSegment(currentR.Position,target,h) then releaseMovement(); return false end
            if cast(currentR.Position,delta,nil,true) then releaseMovement(); return false end
            S.movedHumanoid = h
            h:MoveTo(waypoint.Position)
            local started = os.clock()
            local lastGuard = 0
            local reached = false
            while active(token) and S.walking do
                local _,liveH,liveR = character()
                if liveH ~= h or not liveR then break end
                local flat = Vector3.new(liveR.Position.X-target.X,0,liveR.Position.Z-target.Z)
                if flat.Magnitude <= 1.6 then reached=true; break end
                if interactionReady(prompt) then releaseMovement(); return true end
                if os.clock()-started > 2.5 or os.clock()-pathStart > 10 then break end
                if os.clock()-lastGuard > .15 then
                    lastGuard = os.clock()
                    local nextTarget = Vector3.new(target.X,liveR.Position.Y,target.Z)
                    if not supportedSegment(liveR.Position,nextTarget,h) then break end
                end
                task.wait(.05)
            end
            if not reached then releaseMovement(); return false end
        end
    end
    releaseMovement()
    return interactionReady(prompt)
end

local function interact(prompt,token)
    if not active(token) or not interactionReady(prompt) then return false end
    if prompt.HoldDuration > Config.MaxHoldSeconds then return false end
    S.lastAction = prompt.ActionText .. " / " .. prompt.ObjectText
    S.status = "กำลังโต้ตอบ: " .. (prompt.ObjectText ~= "" and prompt.ObjectText or prompt.Parent.Name)
    S.heldPrompt = prompt
    S.attempts = S.attempts + 1
    refresh()
    -- Standard prompt input, preserving the game's actual hold duration and range.
    local ok,err = pcall(function() prompt:InputHoldBegin() end)
    if not ok then S.lastError=tostring(err); releaseHold(); return false end
    local endAt = os.clock()+math.max(.12,prompt.HoldDuration+.10)
    while os.clock() < endAt do
        if not active(token) then releaseHold(); return false end
        -- Disappearance can mean the item was consumed, but is not counted as success.
        if not prompt.Parent or not prompt.Enabled then break end
        if not interactionReady(prompt) then releaseHold(); return false end
        task.wait(.04)
    end
    releaseHold()
    return true
end

local function addPrompt(object)
    if object:IsA("ProximityPrompt") then S.prompts[object] = true end
end
connect(Workspace.DescendantAdded,addPrompt)
connect(Workspace.DescendantRemoving,function(object)
    S.prompts[object]=nil; S.cooldowns[object]=nil; S.shown[object]=nil
end)
connect(ProximityPromptService.PromptShown,function(prompt) S.shown[prompt]=true; addPrompt(prompt) end)
connect(ProximityPromptService.PromptHidden,function(prompt) S.shown[prompt]=nil end)

local function candidates()
    local _,_,r = character()
    local choices,total,matched = {},0,0
    for prompt in pairs(S.prompts) do
        if prompt.Parent then
            total = total+1
            local position = promptPosition(prompt)
            if eligible(prompt) and position then
                matched = matched+1
                local d = r and (r.Position-position).Magnitude or math.huge
                if d <= Config.ScanRadius and (S.cooldowns[prompt] or 0) <= os.clock() then
                    table.insert(choices,{prompt=prompt,distance=d})
                end
            end
        else S.prompts[prompt]=nil; S.cooldowns[prompt]=nil; S.shown[prompt]=nil end
    end
    table.sort(choices,function(a,b) return a.distance<b.distance end)
    S.total,S.eligible = total,matched
    return choices
end

local function diagnostics()
    candidates()
    local _,h,r = character()
    local lines = {
        "NEPTUNE X / Sea / experimental 0.1",
        "Place: "..tostring(game.PlaceId), "Universe: "..tostring(game.GameId),
        "Known game: "..tostring(correctGame),
        "Health: "..(h and string.format("%.0f/%.0f",h.Health,h.MaxHealth) or "no character"),
        "Prompts: "..S.total.." | Match: "..S.eligible,
        "Attempts (unconfirmed): "..S.attempts,
        "Last: "..S.lastAction, "Error: "..(S.lastError ~= "" and S.lastError or "none"),
        "Nearest prompts (up to 5):",
    }
    local nearby = {}
    for prompt in pairs(S.prompts) do
        local position = promptPosition(prompt)
        if position and r then table.insert(nearby,{p=prompt,d=(r.Position-position).Magnitude}) end
    end
    table.sort(nearby,function(a,b) return a.d<b.d end)
    for i=1,math.min(5,#nearby) do
        local p=nearby[i].p
        table.insert(lines,string.format("%d. %.1f studs [%s] %s / %s",i,nearby[i].d,
            eligible(p) and "match" or "skip",p.ActionText,p.ObjectText))
        table.insert(lines,"   "..p.Parent.Name.." | range="..p.MaxActivationDistance)
    end
    if #nearby == 0 then table.insert(lines,"No replicated prompts near this character.") end
    return table.concat(lines,"\n")
end

connect(infoButton.Activated,function() report.Text=diagnostics(); info.Visible=true end)
connect(infoClose.Activated,function() info.Visible=false end)
connect(refreshInfo.Activated,function() report.Text=diagnostics() end)
connect(copyButton.Activated,function()
    if type(setclipboard) == "function" then
        local ok = pcall(setclipboard,report.Text)
        copyButton.Text = ok and "คัดลอกแล้ว" or "ถ่ายหน้าจอแทน"
    else copyButton.Text="ถ่ายหน้าจอแทน" end
end)

connect(startButton.Activated,function()
    if S.running then return end
    if not S.ready then S.status="รอสแกนให้เสร็จก่อน"; refresh(); return end
    if not correctGame then S.status="แมพนี้ไม่ตรงกับ 100 Days At Sea"; refresh(); return end
    S.generation=S.generation+1
    S.running=true
    S.status="เริ่มตรวจหาทรัพยากร…"
    active(S.generation)
    refresh()
end)
connect(stopButton.Activated,function() stop("หยุดแล้ว — ควบคุมตัวละครได้ตามปกติ") end)
connect(walkButton.Activated,function()
    stop("เปลี่ยนโหมดเดินแล้ว — กด START เพื่อเริ่ม")
    S.walking=not S.walking
    refresh()
end)
local ranges={20,40,60}
connect(rangeButton.Activated,function()
    for i,value in ipairs(ranges) do
        if value==Config.ScanRadius then Config.ScanRadius=ranges[i % #ranges+1]; break end
    end
    refresh()
end)
connect(player.CharacterRemoving,function() stop("หยุด: ตัวละครออกจากฉาก") end)
connect(player.CharacterAdded,function() stop("เกิดใหม่แล้ว — กด START เมื่อตัวละครพร้อม") end)
connect(UserInputService.InputBegan,function(input,processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.P then stop("หยุดด้วยปุ่ม P") end
end)

S.Destroy = function()
    if not S.alive then return end
    stop("ปิดแล้ว")
    S.alive=false
    for _,connection in ipairs(S.connections) do connection:Disconnect() end
    S.connections={}; S.prompts={}; S.cooldowns={}; S.shown={}
    if gui.Parent then gui:Destroy() end
    if env[slot]==S then env[slot]=nil end
end
connect(close.Activated,S.Destroy)
connect(gui.Destroying,S.Destroy)

-- Scan once, then update incrementally through workspace events.
task.spawn(function()
    local descendants=Workspace:GetDescendants()
    for index,object in ipairs(descendants) do
        if not S.alive then return end
        if object:IsDescendantOf(Workspace) then addPrompt(object) end
        if index % 300==0 then task.wait() end
    end
    descendants=nil
    if not S.alive then return end
    candidates()
    S.ready=true
    S.status=correctGame and "พร้อมทดลอง — เข้าเกมรอบจริงแล้วกด START" or "เปิดแมพ 100 Days At Sea ก่อนใช้งาน"
    refresh()
end)

task.spawn(function()
    while S.alive do
        if S.running then
            local token=S.generation
            local ok,err=pcall(function()
                if not active(token) then return end
                local choices=candidates()
                local selected=nil
                for _,choice in ipairs(choices) do
                    if interactionReady(choice.prompt) then selected=choice; break end
                end
                if not selected and S.walking then selected=choices[1] end
                if not selected then
                    if S.total==0 then S.status="ไม่พบปุ่มโต้ตอบ — เข้ารอบจริงแล้วลอง INFO"
                    elseif S.eligible==0 then S.status="พบปุ่ม แต่ยังไม่รู้จักของที่เก็บได้ — กด INFO"
                    elseif #choices>0 then S.status="เดินเข้าใกล้ของ หรือเปิด AUTO WALK"
                    else S.status="รอของในระยะค้นหา / รอคูลดาวน์" end
                    refresh(); return
                end
                local prompt=selected.prompt
                if not interactionReady(prompt) then
                    S.status="กำลังหาทางเดินที่มีพื้นรองรับ…"; refresh()
                    if not moveToward(prompt,token) then
                        if token==S.generation then
                            S.cooldowns[prompt]=os.clock()+Config.FailureCooldown
                            S.status="ข้ามของนี้: ทางเดินไม่พร้อมหรือเอื้อมไม่ถึง"
                        end
                        return
                    end
                end
                if not active(token) then return end
                local attempted=interact(prompt,token)
                if token==S.generation and prompt.Parent then
                    S.cooldowns[prompt]=os.clock()+(attempted and Config.RetryCooldown or Config.FailureCooldown)
                end
            end)
            if not ok then
                S.lastError=tostring(err)
                stop("หยุดเพราะข้อผิดพลาด — กด INFO เพื่อดูรายละเอียด")
            end
            refresh()
        end
        task.wait(Config.TickInterval)
    end
end)
