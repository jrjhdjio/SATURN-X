-- BM XY AIM V6.1 / 2026-10-18 / เพิ่มตัวกรองศพและจำร่างที่เคยตาย
-- ข้ามสถานะ Dead, เหตุการณ์ Died, ร่างผู้เล่นเก่าที่เคยตรวจพบ และป้ายกำกับศพ
-- ไม่ตัดสินจากการนอน/ล้ม/Ragdoll อย่างเดียว; เกิดใหม่เป็นร่างใหม่ยังเลือกได้
-- ศพที่สร้างใหม่ เลือดเต็ม และไม่มีชื่อ/ป้าย/สถานะบอกว่าเป็นศพ ยังอาจแยกไม่ได้
-- เปิดปุ่ม: หาเป้าที่มีแนวเล็งโล่งทั้งหน้า/ข้าง/หลัง; ยังไม่พบจะหมุนหาอัตโนมัติ
-- เป้าเดิมตาย/ถูกบัง/ออกระยะ: เลือกเป้าใหม่ในเฟรมถัดไปโดยไม่รอรอบค้นหา
-- ฝัง MP3 ต้นฉบับไว้ในไฟล์นี้ (ข้อมูลเสียง ไม่ใช่โค้ดที่ดาวน์โหลดจากภายนอก)
-- เสียงแนบใช้ writefile + getcustomasset ของตัวรัน ถ้าไม่มี ระบบเล็งยังทำงานต่อ
-- ใน Studio ให้ใส่ ToggleSoundAssetId ของเสียงที่อัปโหลดและมีสิทธิ์ใช้แทน
-- V5 ค้นหาเป้าต่อได้แม้ Player.Character เป็น nil หรืออยู่นอก Workspace
-- ถ้ามี CameraSubject ที่เป็นตัวละคร ใช้ระบุตัวเราเพื่อไม่เลือก/ตรวจชนตัวเอง
-- ถ้าระบุตัวเราไม่ได้ จะเล็งจากกล้องและข้ามเป้าที่ใกล้กล้องมากกว่าเกณฑ์ด้านล่าง
-- ปุ่ม ○ / ●; ซ่อนข้อความสถานะแล้ว เสียงเล่นเฉพาะการแตะเปิด/ปิด ไม่เล่นตอนลาก
-- รองรับ Humanoid ที่อยู่ซ้อนใน Model และ Player.Character ที่ไม่มี Humanoid
-- บอทยังต้องมี Humanoid; ไม่เดาว่าโมเดลตกแต่งเป็นบอท
-- เป็นสคริปต์ฝั่ง client: ถ้าทดสอบใน Studio ใช้ LocalScript ใน StarterPlayerScripts
-- ปิดสคริปต์ล็อกเป้าเก่าก่อนใช้ เพื่อลดการแย่งควบคุมกล้อง
-- แตะ = เปิด/ปิด, ลาก = ย้ายตำแหน่ง (ลากแล้วไม่สลับสถานะ)
-- ล็อกเป้าเดิมจนตาย/ถูกบัง/ออกระยะ แล้วหาเป้าใหม่อัตโนมัติ
-- ไม่มีการยิงอัตโนมัติ: ใช้ปุ่มยิงของเกมตามปกติ
-- ยังไม่ได้ทดสอบใน Hypershot จริง; กล้อง/ตัวละคร/ปืนที่เกมเขียนเองอาจไม่รองรับ
-- ไฟล์นี้หมุนกล้องเท่านั้น ไม่แก้ระบบกระสุนหรือรับประกันว่าเซิร์ฟเวอร์จะนับว่าถูกเป้า
-- API references:
-- https://create.roblox.com/docs/reference/engine/classes/RunService
-- https://create.roblox.com/docs/reference/engine/classes/Camera
-- https://create.roblox.com/docs/reference/engine/classes/WorldRoot
-- https://create.roblox.com/docs/reference/engine/classes/Player
-- https://create.roblox.com/docs/reference/engine/classes/Sound
-- https://create.roblox.com/docs/reference/engine/classes/ContentProvider
-- https://create.roblox.com/docs/reference/engine/classes/Humanoid
-- https://create.roblox.com/docs/reference/engine/classes/CollectionService
-- https://github.com/unified-naming-convention/NamingStandard/blob/main/api/filesystem.md

local CONFIG = {
    TargetPlayers = true,
    TargetBots = true,
    ShowDiagnostics = false,  -- ซ่อนข้อความใต้ปุ่ม
    ToggleSoundEnabled = true,
    ToggleSoundVolume = 0.75,
    ToggleSoundAssetId = "",  -- เว้นว่างเพื่อใช้ MP3 ที่ฝังมา; ใส่ Asset ID ได้ถ้าจำเป็น
    CameraOnlyMinDistance = 3, -- studs: เมื่อไม่รู้ตัวเรา ข้ามโมเดลชิดกล้องเพื่อลดการเลือกตัวเอง
    TeamCheck = true,          -- false ถ้าต้องการรวมผู้เล่นทีมเดียวกันด้วย
    WallCheck = true,
    IgnoreForceFields = true,
    IgnoreCorpses = true,
    MaxDistance = 1500,
    AutoSearch360 = true,     -- รวมเป้านอกจอและด้านหลัง; ยังตรวจผนัง/ทีม/ระยะ
    AutoRotateWhenNoTarget = true,
    SearchTurnSpeed = 90,     -- องศาต่อวินาทีขณะไม่มีเป้า; 90 = ครบรอบใน 4 วินาที
    AcquireAngle = 85,        -- ใช้เฉพาะเมื่อ AutoSearch360 = false
    SearchInterval = 0.05,    -- ตรวจเป้าใหม่ 20 ครั้ง/วินาทีเมื่อยังไม่พบ
    SwitchEverySeconds = 0,   -- 0 = ค้างเป้า; เปลี่ยนเมื่อตาย/ถูกบัง/ออกระยะ
                             -- ตั้งเป็น 2 เพื่อสลับทุก 2 วินาทีถ้ามีเป้าอื่น
    LeadSeconds = 0,          -- 0 = กลางหัวปัจจุบัน ไม่เดาทิศทางกระสุน
    ReferenceWidth = 1536,
    ReferenceHeight = 709,
    ButtonDiameter = 74,      -- เท่าปุ่มคนเต้นโดยประมาณในภาพอ้างอิง
    ButtonCenterX = 390,      -- ด้านขวาของปุ่มคนเต้น
    ButtonCenterY = 153,      -- ต่ำกว่ากึ่งกลางปุ่มคนเต้นเล็กน้อย
    ButtonColor = Color3.fromRGB(10, 10, 12),
    ButtonTransparency = 0.45,
    SymbolColor = Color3.fromRGB(242, 242, 242),
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local localPlayer = Players.LocalPlayer
if not localPlayer then
    warn("[BM XY] ต้องรันฝั่ง client; ไม่ใช่ Server Script หรือช่องแชต")
    return
end
local playerGui = localPlayer:WaitForChild("PlayerGui", 15)
if not playerGui then
    warn("[BM XY] ไม่พบ PlayerGui")
    return
end

-- ใช้ชื่อเดิมเพื่อหยุดและแทนที่เวอร์ชันก่อนหน้าที่รันอยู่
local GUI_NAME = "BM_XY_Aim_V3"
local RENDER_NAME = "BM_XY_Aim_V3_Render"
local previous = playerGui:FindFirstChild(GUI_NAME)
if previous then
    local shutdown = previous:FindFirstChild("Shutdown")
    if shutdown and shutdown:IsA("BindableEvent") then
        shutdown:Fire()
    end
    previous:Destroy()
end
RunService:UnbindFromRenderStep(RENDER_NAME)

local gui = Instance.new("ScreenGui")
gui.Name = GUI_NAME
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 1000
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function()
    gui.ScreenInsets = Enum.ScreenInsets.None
    gui.ClipToDeviceSafeArea = false
end)

local shutdown = Instance.new("BindableEvent")
shutdown.Name = "Shutdown"
shutdown.Parent = gui

local canvas = Instance.new("Frame")
canvas.Name = "Canvas"
canvas.Size = UDim2.fromScale(1, 1)
canvas.BackgroundTransparency = 1
canvas.BorderSizePixel = 0
canvas.Active = false
canvas.Parent = gui

local button = Instance.new("TextButton")
button.Name = "AimToggle"
button.AnchorPoint = Vector2.new(0.5, 0.5)
button.BackgroundColor3 = CONFIG.ButtonColor
button.BackgroundTransparency = CONFIG.ButtonTransparency
button.BorderSizePixel = 0
button.AutoButtonColor = false
button.Active = true
button.Selectable = false
button.Font = Enum.Font.Arial
button.Text = "○"
button.TextColor3 = CONFIG.SymbolColor
button.TextStrokeTransparency = 1
button.TextXAlignment = Enum.TextXAlignment.Center
button.TextYAlignment = Enum.TextYAlignment.Center
button.ZIndex = 2
button.Parent = canvas

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0)
corner.Parent = button

local diagnostic = Instance.new("TextLabel")
diagnostic.Name = "Diagnostic"
diagnostic.AnchorPoint = Vector2.new(0.5, 0)
diagnostic.Position = UDim2.new(0.5, 0, 1, 6)
diagnostic.Size = UDim2.fromOffset(310, 62)
diagnostic.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
diagnostic.BackgroundTransparency = 0.30
diagnostic.BorderSizePixel = 0
diagnostic.TextColor3 = Color3.fromRGB(255, 255, 255)
diagnostic.Font = Enum.Font.Arial
diagnostic.TextSize = 14
diagnostic.TextWrapped = true
diagnostic.Active = false
diagnostic.Visible = false
diagnostic.ZIndex = 3
diagnostic.Parent = button
gui.Parent = playerGui

local running = true
local enabled = false
local connections = {}
local humanoids = {}
local deadHumanoids = setmetatable({}, {__mode = "k"})
local deadModels = setmetatable({}, {__mode = "k"})
local characterOwners = setmetatable({}, {__mode = "k"})
local current = nil
local searchDirection = nil
local lastCamera = nil
local selfModel = nil
local selfMode = "CameraOnly"
local nextSearch = 0
local acquiredAt = 0
local clock = 0
local nextDiagnostic = 0
local lastDiagnosticState = ""
local scan = {P = 0, B = 0, valid = 0, reasons = {}, blocker = ""}
local pointer = nil
local pointerStart = nil
local centerStart = nil
local dragged = false
local lastCanvasSize = Vector2.new(0, 0)
local normalizedPosition = Vector2.new(
    CONFIG.ButtonCenterX / CONFIG.ReferenceWidth,
    CONFIG.ButtonCenterY / CONFIG.ReferenceHeight
)

local function connect(signal, callback)
    local connection = signal:Connect(callback)
    connections[#connections + 1] = connection
    return connection
end

local function canvasSize()
    local size = canvas.AbsoluteSize
    if size.X > 0 and size.Y > 0 then return size end
    local camera = Workspace.CurrentCamera
    return camera and camera.ViewportSize or Vector2.new(1536, 709)
end

local function putButton(center)
    local size = canvasSize()
    local half = button.Size.X.Offset / 2
    local x = math.clamp(center.X, half + 2, math.max(half + 2, size.X - half - 2))
    local y = math.clamp(center.Y, half + 2, math.max(half + 2, size.Y - half - 2))
    button.Position = UDim2.fromOffset(x, y)
    normalizedPosition = Vector2.new(x / math.max(size.X, 1), y / math.max(size.Y, 1))
end

local function layout()
    local size = canvasSize()
    if size.X < 1 or size.Y < 1 then return end
    local scale = math.min(size.X / CONFIG.ReferenceWidth, size.Y / CONFIG.ReferenceHeight)
    local diameter = math.clamp(math.floor(CONFIG.ButtonDiameter * scale + 0.5), 36, 120)
    button.Size = UDim2.fromOffset(diameter, diameter)
    button.TextSize = math.floor(diameter * 0.58 + 0.5)
    diagnostic.Size = UDim2.fromOffset(math.min(310, math.max(230, size.X - 12)), 62)
    putButton(Vector2.new(normalizedPosition.X * size.X, normalizedPosition.Y * size.Y))
    lastCanvasSize = size
end
layout()
connect(canvas:GetPropertyChangedSignal("AbsoluteSize"), function()
    pointer = nil
    layout()
end)

local function status(state, name, detail)
    if gui:GetAttribute("State") ~= state then gui:SetAttribute("State", state) end
    name = name or ""
    if gui:GetAttribute("Target") ~= name then gui:SetAttribute("Target", name) end
    diagnostic.Visible = CONFIG.ShowDiagnostics and (enabled or state == "Error")
    if clock < nextDiagnostic and lastDiagnosticState == state then return end
    nextDiagnostic = clock + 0.25
    lastDiagnosticState = state
    local line1 = "V6.1 | " .. state
    if name ~= "" then line1 = line1 .. ": " .. name end
    local line2 = "SCAN P=" .. scan.P .. " B=" .. scan.B .. " OK=" .. scan.valid .. " | " .. selfMode
    local reasonList = {}
    for _, key in ipairs({"DEAD", "CORPSE", "TEAM", "SHIELD", "NO_HEAD", "NEAR", "RANGE", "OFFSCREEN", "WALL", "DISABLED"}) do
        if (scan.reasons[key] or 0) > 0 then
            reasonList[#reasonList + 1] = key .. "=" .. scan.reasons[key]
        end
    end
    local line3 = detail or table.concat(reasonList, " ")
    if not detail and scan.blocker ~= "" then line3 = line3 .. " hit=" .. scan.blocker end
    diagnostic.Text = line1 .. "\n" .. line2 .. "\n" .. line3
end

local function setEnabled(value)
    enabled = value
    current = nil
    searchDirection = nil
    nextSearch = 0
    nextDiagnostic = 0
    button.Text = enabled and "●" or "○"
    gui:SetAttribute("Enabled", enabled)
    status(enabled and "Searching" or "Off")
end
setEnabled(false)

-- เสียงต้นฉบับ: matthewvakaliuk73627-mouse-click-290204.mp3
-- BEGIN_EMBEDDED_CLICK_MP3
local CLICK_MP3_BASE64 = [=[
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
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVf/70mQAD/AAAGkA
AAAIAAANIAAAAQAAAaQAAAAgAAA0gAAABExBTUUzLjEwMFVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVMQU1FMy4xMDBVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVV//vSZAAP8AAAaQAAAAgAAA0gAAABAAABpAAAACAAADSAAAAETEFNRTMuMTAwVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVUxBTUUzLjEwMFVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVX/+9JkAA/wAABpAAAACAAADSAAAAEAAAGkAAAAIAAANIAAAARMQU1FMy4xMDBVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVTEFNRTMuMTAwVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVf/70GQAD/AAAGkAAAAIAAANIAAAAQAA
AaQAAAAgAAA0gAAABExBTUUzLjEwMFVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVUxBTUUzLjEwMFVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVU=
]=]
-- END_EMBEDDED_CLICK_MP3
local CLICK_MP3_BYTES = 11702
local CLICK_MP3_FILENAME = "BM_XY_Click_075e17bdac5c1366.mp3"
local toggleSound = nil

local function decodeAudioBase64(encoded)
    local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    local values = {}
    for index = 1, #alphabet do values[string.byte(alphabet, index)] = index - 1 end
    encoded = encoded:gsub("%s", "")
    assert(#encoded % 4 == 0, "Invalid embedded audio length")
    local output = {}
    for index = 1, #encoded, 4 do
        local a = values[string.byte(encoded, index)]
        local b = values[string.byte(encoded, index + 1)]
        local c = values[string.byte(encoded, index + 2)] or 0
        local d = values[string.byte(encoded, index + 3)] or 0
        assert(a and b, "Invalid embedded audio data")
        local packed = ((a * 64 + b) * 64 + c) * 64 + d
        output[#output + 1] = string.char(math.floor(packed / 65536) % 256)
        if string.byte(encoded, index + 2) ~= 61 then
            output[#output + 1] = string.char(math.floor(packed / 256) % 256)
        end
        if string.byte(encoded, index + 3) ~= 61 then output[#output + 1] = string.char(packed % 256) end
    end
    local decoded = table.concat(output)
    assert(#decoded == CLICK_MP3_BYTES, "Embedded audio is incomplete")
    return decoded
end

local function initialiseToggleSound()
    if not CONFIG.ToggleSoundEnabled then
        gui:SetAttribute("AudioState", "Disabled")
        return
    end
    local source = tostring(CONFIG.ToggleSoundAssetId or "")
    if source == "" then
        if type(writefile) ~= "function" or type(getcustomasset) ~= "function" then
            gui:SetAttribute("AudioState", "UnsupportedLocalAudio")
            warn("[BM XY audio] ตัวรันไม่มี writefile/getcustomasset สำหรับเสียงแนบ; ระบบเล็งยังใช้งานได้")
            return
        end
        -- เขียนเฉพาะไฟล์เสียงชื่อนี้ในโฟลเดอร์ของตัวรัน ไม่อ่านไฟล์ส่วนตัวอื่น
        writefile(CLICK_MP3_FILENAME, decodeAudioBase64(CLICK_MP3_BASE64))
        source = getcustomasset(CLICK_MP3_FILENAME)
        assert(type(source) == "string" and source ~= "", "Local audio asset registration failed")
    elseif source:match("^%d+$") then
        source = "rbxassetid://" .. source
    end
    local sound = Instance.new("Sound")
    sound.Name = "BM_XY_ToggleClick"
    sound.SoundId = source
    sound.Volume = math.clamp(CONFIG.ToggleSoundVolume, 0, 1)
    sound.PlaybackSpeed = 1
    sound.Looped = false
    sound.PlayOnRemove = false
    sound.Parent = gui
    toggleSound = sound
    gui:SetAttribute("AudioState", "Prepared")
    gui:SetAttribute("AudioPlayRequests", 0)
    connect(sound.Loaded, function()
        if running then gui:SetAttribute("AudioState", "Loaded") end
    end)
    -- เตรียมเสียงเบื้องหลัง: การรอโหลดเสียงต้องไม่ขวางปุ่มหรือระบบเล็ง
    task.spawn(function()
        if not running then return end
        local ok, message = pcall(function()
            game:GetService("ContentProvider"):PreloadAsync({sound}, function(_, result)
                if not running then return end
                if result == Enum.AssetFetchStatus.Success then
                    gui:SetAttribute("AudioState", "Loaded")
                else
                    gui:SetAttribute("AudioState", "LoadFailed")
                    warn("[BM XY audio] โหลดเสียงไม่สำเร็จ: " .. tostring(result))
                end
            end)
        end)
        if not ok and running then
            gui:SetAttribute("AudioState", "LoadFailed")
            gui:SetAttribute("AudioError", tostring(message))
            warn("[BM XY audio] " .. tostring(message))
        end
    end)
end

do
    local ok, message = pcall(initialiseToggleSound)
    if not ok then
        gui:SetAttribute("AudioState", "Error")
        gui:SetAttribute("AudioError", tostring(message))
        warn("[BM XY audio] " .. tostring(message))
    end
end

local function playToggleSound()
    if not running or not toggleSound or not toggleSound.Parent then return end
    local ok, message = pcall(function()
        toggleSound:Stop()
        toggleSound.TimePosition = 0
        toggleSound:Play()
        gui:SetAttribute("AudioPlayRequests", (gui:GetAttribute("AudioPlayRequests") or 0) + 1)
    end)
    if not ok then
        gui:SetAttribute("AudioError", tostring(message))
        warn("[BM XY audio] " .. tostring(message))
    end
end

-- จับเฉพาะนิ้ว/เมาส์ที่เริ่มบนปุ่ม; นิ้วที่ใช้เดินหรือหมุนกล้องไม่ลากปุ่มตาม
local function inputPoint(input)
    return Vector2.new(input.Position.X, input.Position.Y)
end
connect(button.InputBegan, function(input)
    local kind = input.UserInputType
    if pointer or (kind ~= Enum.UserInputType.Touch and kind ~= Enum.UserInputType.MouseButton1) then
        return
    end
    pointer = input
    pointerStart = inputPoint(input)
    centerStart = Vector2.new(button.Position.X.Offset, button.Position.Y.Offset)
    dragged = false
end)
connect(UserInputService.InputChanged, function(input)
    if not pointer then return end
    local isTouch = pointer.UserInputType == Enum.UserInputType.Touch
    if (isTouch and input ~= pointer) or
       (not isTouch and input.UserInputType ~= Enum.UserInputType.MouseMovement) then return end
    local delta = inputPoint(input) - pointerStart
    local threshold = math.max(5, button.Size.X.Offset * 0.08)
    if delta.Magnitude >= threshold then dragged = true end
    if dragged then putButton(centerStart + delta) end
end)
connect(UserInputService.InputEnded, function(input)
    if not pointer then return end
    local isMouse = pointer.UserInputType == Enum.UserInputType.MouseButton1
    if input ~= pointer and not (isMouse and input.UserInputType == Enum.UserInputType.MouseButton1) then
        return
    end
    -- ตรวจระยะซ้ำ: ป้องกันการปล่อยนิ้วไกลจากจุดเดิมโดยไม่มี InputChanged
    local delta = inputPoint(input) - pointerStart
    local wasDrag = dragged or delta.Magnitude >= math.max(5, button.Size.X.Offset * 0.08)
    local cancelled = input.UserInputState == Enum.UserInputState.Cancel
    pointer = nil
    if not wasDrag and not cancelled then
        setEnabled(not enabled)
        playToggleSound()
    end
end)
connect(UserInputService.WindowFocusReleased, function() pointer = nil end)

local function register(instance)
    if instance:IsA("Humanoid") and not humanoids[instance] then
        -- จับการตายแม้ปุ่มปิดอยู่ หรือเกมเปลี่ยนค่าเลือดก่อนรอบค้นหาครั้งต่อไป
        humanoids[instance] = instance.Died:Connect(function()
            deadHumanoids[instance] = true
            if current == instance then current = nil; nextSearch = 0 end
        end)
    end
end
-- เก็บรายชื่อครั้งแรก แล้วติดตามการเพิ่ม/ลบ; ไม่สแกน Workspace ทั้งหมดทุกเฟรม
connect(Workspace.DescendantAdded, register)
connect(Workspace.DescendantRemoving, function(instance)
    if humanoids[instance] then
        humanoids[instance]:Disconnect()
        humanoids[instance] = nil
        if current == instance then current = nil; nextSearch = 0 end
    end
    if current == instance then current = nil; nextSearch = 0 end
end)
for _, instance in ipairs(Workspace:GetDescendants()) do register(instance) end

local function teamKey(object)
    if not object then return nil end
    for _, name in ipairs({"TeamId", "Team", "Faction"}) do
        local value = object:GetAttribute(name)
        if value ~= nil and value ~= "" and value ~= 0 and value ~= "Neutral" then
            return tostring(value)
        end
    end
    return nil
end

local function friendly(model, owner)
    if not CONFIG.TeamCheck then return false end
    if owner and localPlayer.Team and owner.Team and
       not localPlayer.Neutral and not owner.Neutral and owner.Team == localPlayer.Team then
        return true
    end
    if not owner and model:GetAttribute("Friendly") == true then return true end
    local theirs = teamKey(owner) or teamKey(model)
    local ours = teamKey(localPlayer) or teamKey(selfModel) or teamKey(localPlayer.Character)
    if not ours and localPlayer.Team and not localPlayer.Neutral then
        ours = localPlayer.Team.Name
    end
    return ours ~= nil and theirs ~= nil and ours == theirs
end

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
raycastParams.IgnoreWater = true

local function updateRayFilter(camera)
    local excluded = {camera}
    if selfModel then excluded[#excluded + 1] = selfModel end
    if localPlayer.Character and localPlayer.Character ~= selfModel then
        excluded[#excluded + 1] = localPlayer.Character
    end
    raycastParams.FilterDescendantsInstances = excluded
    return excluded
end

local function ancestorModel(instance)
    local parent = instance.Parent
    while parent and parent ~= Workspace do
        if parent:IsA("Model") then return parent end
        parent = parent.Parent
    end
    return nil
end

local function resolveSelf(camera)
    local character = localPlayer.Character
    if character and character:IsDescendantOf(Workspace) then return character, "Character" end
    local subject = camera.CameraSubject
    if subject and subject:IsDescendantOf(Workspace) then
        local model = subject:IsA("Model") and subject or ancestorModel(subject)
        if model and model:IsDescendantOf(Workspace) and not model:IsDescendantOf(camera) then
            local owner = Players:GetPlayerFromCharacter(model)
            local humanoid = model:FindFirstChildWhichIsA("Humanoid", true)
            local head = model:FindFirstChild("Head", true)
            -- ไม่ถือว่า CameraSubject ที่เป็นผู้เล่นอื่นเป็นตัวเรา
            if (not owner or owner == localPlayer) and (humanoid or (head and head:IsA("BasePart"))) then
                return model, "CameraSubject"
            end
        end
    end
    return nil, "CameraOnly"
end

local function healthValue(model)
    for _, key in ipairs({"Health", "HP"}) do
        local value = model:GetAttribute(key)
        if type(value) == "number" then return value end
        local child = model:FindFirstChild(key)
        if child and (child:IsA("NumberValue") or child:IsA("IntValue")) then return child.Value end
    end
    return nil
end

local function deadModel(model, humanoid)
    if humanoid and (humanoid.Health <= 0 or humanoid:GetState() == Enum.HumanoidStateType.Dead) then
        return true
    end
    if model:GetAttribute("Dead") == true or model:GetAttribute("Alive") == false then return true end
    local health = healthValue(model)
    return health ~= nil and health <= 0
end

local corpseFlags = {"Corpse", "IsCorpse", "DeadBody", "IsDeadBody", "Dead", "IsDead"}
local corpseTags = {corpse = true, corpses = true, iscorpse = true,
    deadbody = true, deadbodies = true, isdeadbody = true, dead = true, isdead = true}

local function corpseName(name)
    local normalized = string.lower(name):gsub("[_%-]+", " ")
    if normalized == "deadbody" or normalized == "deadbodies" or
       normalized == "dead body" or normalized == "dead bodies" then return true end
    for word in normalized:gmatch("%S+") do
        if word == "corpse" or word == "corpses" or word == "deadbody" or word == "deadbodies" then
            return true
        end
    end
    return false
end

local function corpseMarker(object, checkName)
    for _, key in ipairs(corpseFlags) do
        if object:GetAttribute(key) == true then return true end
        local flag = object:FindFirstChild(key)
        if flag and flag:IsA("BoolValue") and flag.Value == true then return true end
    end
    if object:GetAttribute("Alive") == false then return true end
    local alive = object:FindFirstChild("Alive")
    if alive and alive:IsA("BoolValue") and alive.Value == false then return true end
    for _, tag in ipairs(CollectionService:GetTags(object)) do
        local normalized = string.lower(tag):gsub("[%s_%-]", "")
        if corpseTags[normalized] then return true end
    end
    return checkName and corpseName(object.Name)
end

local function isCorpse(model, humanoid, owner)
    if not CONFIG.IgnoreCorpses then return false end
    if humanoid and deadHumanoids[humanoid] then return true end
    local remembered = deadModels[model]
    if remembered and (remembered == humanoid or (remembered == true and not humanoid)) then return true end
    local formerOwner = characterOwners[model]
    if not owner and formerOwner and formerOwner.Character ~= model then return true end
    if humanoid and corpseMarker(humanoid, false) then return true end
    local object = model
    while object and object ~= Workspace do
        -- ชื่อผู้เล่นจริงอาจเป็น Corpse; อย่าใช้ชื่อนั้นเป็นเหตุข้ามตัวที่ยังเล่นอยู่
        if (object:IsA("Model") or object:IsA("Folder")) and
           corpseMarker(object, object ~= model or owner == nil) then return true end
        object = object.Parent
    end
    return false
end

local function evaluate(subject, camera, acquiring)
    if not subject or not subject.Parent or not subject:IsDescendantOf(Workspace) then
        return nil, "STALE"
    end
    local humanoid = subject:IsA("Humanoid") and subject or nil
    local model = humanoid and ancestorModel(humanoid) or subject
    if not model or not model:IsA("Model") then return nil, "STALE" end
    local owner = Players:GetPlayerFromCharacter(model)
    -- Humanoid อาจอยู่ในโมเดลย่อย; ตรวจถึง Character ชั้นนอกของผู้เล่น
    local ancestor = model.Parent
    while not owner and ancestor and ancestor ~= Workspace do
        if ancestor:IsA("Model") then
            owner = Players:GetPlayerFromCharacter(ancestor)
            if owner then model = ancestor; break end
        end
        ancestor = ancestor.Parent
    end
    if not humanoid then humanoid = model:FindFirstChildWhichIsA("Humanoid", true) end
    local character = selfModel
    if model == character or (character and model:IsDescendantOf(character)) or
       model:IsDescendantOf(camera) or owner == localPlayer then return nil, "SELF" end
    local kind = owner and "P" or "B"
    local function reject(reason, detail) return nil, reason, detail, kind end
    if not humanoid and not owner then return reject("NO_HEAD") end
    if owner then characterOwners[model] = owner end
    if deadModel(model, humanoid) then
        deadModels[model] = humanoid or true
        return reject("DEAD")
    end
    if isCorpse(model, humanoid, owner) then return reject("CORPSE") end
    if owner and not CONFIG.TargetPlayers then return reject("DISABLED") end
    if not owner and not CONFIG.TargetBots then return reject("DISABLED") end
    if friendly(model, owner) then return reject("TEAM") end
    if CONFIG.IgnoreForceFields and model:FindFirstChildWhichIsA("ForceField", true) then
        return reject("SHIELD")
    end

    local part = model:FindFirstChild("Head", true)
    local offset = Vector3.new(0, 0, 0)
    if not part or not part:IsA("BasePart") then
        part = (humanoid and humanoid.RootPart) or model:FindFirstChild("HumanoidRootPart", true)
        if not part or not part:IsA("BasePart") then return reject("NO_HEAD") end
        offset = Vector3.new(0, 1.5, 0)
    end
    local point = part.Position + offset
    if CONFIG.LeadSeconds > 0 then
        point = point + part.AssemblyLinearVelocity * CONFIG.LeadSeconds
    end
    local delta = point - camera.CFrame.Position
    local distance = delta.Magnitude
    if not character and distance < CONFIG.CameraOnlyMinDistance then return reject("NEAR") end
    if distance < 0.1 or distance > CONFIG.MaxDistance then return reject("RANGE") end
    local alignment = math.clamp(camera.CFrame.LookVector:Dot(delta.Unit), -1, 1)
    -- คะแนนเชิงมุมใช้ได้ทั้งหน้าและหลัง ไม่ใช้ภาพฉายด้านหลังที่กลับด้าน
    local score = 1 - alignment
    if not CONFIG.AutoSearch360 then
        local projected, onScreen = camera:WorldToViewportPoint(point)
        if acquiring then
            if not onScreen or projected.Z <= 0 then return reject("OFFSCREEN") end
            if alignment < math.cos(math.rad(CONFIG.AcquireAngle)) then return reject("OFFSCREEN") end
        end
        local viewport = camera.ViewportSize
        score = Vector2.new(projected.X - viewport.X / 2, projected.Y - viewport.Y / 2).Magnitude
    end
    if CONFIG.WallCheck then
        -- ข้ามเฉพาะชิ้นส่วนแทบโปร่งใสที่ไม่มีการชน; ยังตรวจผนัง/พื้นตามปกติ
        local filter = updateRayFilter(camera)
        for attempt = 1, 6 do
            raycastParams.FilterDescendantsInstances = filter
            local hit = Workspace:Raycast(camera.CFrame.Position, delta, raycastParams)
            if not hit or hit.Instance:IsDescendantOf(model) then break end
            local object = hit.Instance
            if attempt < 6 and object:IsA("BasePart") and object.Transparency >= 0.95 and not object.CanCollide then
                filter[#filter + 1] = object
            else
                return reject("WALL", object.Parent and (object.Parent.Name .. "." .. object.Name) or object.Name)
            end
        end
    end
    return {
        subject = subject,
        model = model,
        point = point,
        score = score,
        distance = distance,
        name = owner and owner.Name or model.Name,
    }, nil, nil, kind
end

local function choose(camera, exclude)
    local best = nil
    local result = {P = 0, B = 0, valid = 0, reasons = {}, blocker = ""}
    local function consider(subject)
        if subject == exclude then return end
        local info, reason, detail, kind = evaluate(subject, camera, true)
        if kind then result[kind] = result[kind] + 1 end
        if reason and reason ~= "SELF" and reason ~= "STALE" then
            result.reasons[reason] = (result.reasons[reason] or 0) + 1
            if reason == "WALL" and result.blocker == "" then result.blocker = detail or "" end
        end
        if info then
            result.valid = result.valid + 1
            if not best or info.score < best.score or
               (info.score == best.score and info.distance < best.distance) then best = info end
        end
    end
    for humanoid in pairs(humanoids) do
        if not humanoid.Parent then
            humanoids[humanoid]:Disconnect()
            humanoids[humanoid] = nil
        else consider(humanoid) end
    end
    -- Player.Character เป็นหลักฐานว่าเป็นผู้เล่นจริง แม้เกมไม่ใช้ Humanoid
    for _, player in ipairs(Players:GetPlayers()) do
        local model = player.Character
        if player ~= localPlayer and model and not model:FindFirstChildWhichIsA("Humanoid", true) then
            consider(model)
        end
    end
    scan = result
    gui:SetAttribute("ScanPlayers", result.P)
    gui:SetAttribute("ScanBots", result.B)
    gui:SetAttribute("ScanValid", result.valid)
    return best
end

connect(localPlayer.CharacterAdded, function()
    current = nil
    searchDirection = nil
    nextSearch = 0
end)

local function cleanup()
    if not running then return end
    running = false
    enabled = false
    current = nil
    searchDirection = nil
    pointer = nil
    RunService:UnbindFromRenderStep(RENDER_NAME)
    for _, connection in ipairs(connections) do connection:Disconnect() end
    for _, connection in pairs(humanoids) do connection:Disconnect() end
    connections = {}
    humanoids = {}
    deadHumanoids = {}
    deadModels = {}
    characterOwners = {}
    gui:Destroy()
end
connect(shutdown.Event, cleanup)
connect(gui.Destroying, cleanup)

local function rotateSearch(camera, dt)
    if not CONFIG.AutoRotateWhenNoTarget or CONFIG.SearchTurnSpeed <= 0 then
        searchDirection = nil
        return
    end
    if not searchDirection then
        local forward = camera.CFrame.LookVector
        local horizontal = Vector3.new(forward.X, 0, forward.Z)
        if horizontal.Magnitude < 0.001 then horizontal = Vector3.new(0, 0, -1) end
        -- ลดมุมก้ม/เงยระหว่างหมุนหา เพื่อไม่ให้ค้างมองพื้นหรือฟ้า
        local pitch = math.clamp(forward.Y, -0.5, 0.5)
        searchDirection = horizontal.Unit * math.sqrt(1 - pitch * pitch) + Vector3.new(0, pitch, 0)
    end
    -- สะสมทิศค้นหาเอง แม้กล้องเกมจะตั้งมุมเดิมซ้ำก่อนเฟรมนี้
    local angle = math.rad(CONFIG.SearchTurnSpeed) * math.clamp(dt, 0, 0.25)
    local cosine, sine = math.cos(angle), math.sin(angle)
    searchDirection = Vector3.new(
        searchDirection.X * cosine - searchDirection.Z * sine,
        searchDirection.Y,
        searchDirection.X * sine + searchDirection.Z * cosine
    ).Unit
    local origin = camera.CFrame.Position
    camera.CFrame = CFrame.lookAt(origin, origin + searchDirection)
end

local function render(dt)
    if not running then return end
    clock = clock + dt
    local camera = Workspace.CurrentCamera
    if not camera then
        searchDirection = nil
        lastCamera = nil
        if enabled then status("NoCamera", nil, "CurrentCamera is nil") end
        return
    end
    if camera ~= lastCamera then
        searchDirection = nil
        nextSearch = 0
        lastCamera = camera
    end
    local size = canvasSize()
    if size ~= lastCanvasSize then layout() end
    if not enabled then return end
    local character, mode = resolveSelf(camera)
    if selfModel ~= character then
        current = nil
        searchDirection = nil
        nextSearch = 0
    end
    selfModel = character
    selfMode = mode
    if gui:GetAttribute("SelfMode") ~= mode then gui:SetAttribute("SelfMode", mode) end
    local ourHumanoid = character and character:FindFirstChildWhichIsA("Humanoid", true)
    -- ไม่มี Character ไม่ใช่เหตุให้หยุด: กล้องยังหา/เล็งเป้าที่อยู่ใน Workspace ได้
    if character and deadModel(character, ourHumanoid) then
        current = nil
        searchDirection = nil
        nextSearch = 0
        status("WaitingForRespawn", nil, "Local character is dead")
        return
    end
    updateRayFilter(camera)
    local info = current and evaluate(current, camera, false) or nil
    if current and not info then
        current = nil
        nextSearch = 0
    end
    if not current and clock >= nextSearch then
        info = choose(camera, nil)
        nextSearch = clock + CONFIG.SearchInterval
        if info then
            current = info.subject
            acquiredAt = clock
        end
    elseif info and CONFIG.SwitchEverySeconds > 0 and
           clock - acquiredAt >= CONFIG.SwitchEverySeconds then
        local alternative = choose(camera, current)
        acquiredAt = clock
        if alternative then
            info = alternative
            current = alternative.subject
        end
    end
    if not info then
        rotateSearch(camera, dt)
        local reason = scan.P + scan.B == 0 and "NoTargets" or "Filtered"
        status(reason, nil, reason == "NoTargets" and "No supported player/NPC rigs found" or nil)
        return
    end
    searchDirection = nil
    -- เขียนทิศกล้องทุกเฟรมหลังลำดับกล้องปกติ; ไม่แช่ CameraType เป็น Scriptable
    -- ไม่เปลี่ยนตำแหน่งกล้อง: จึงยังเดิน/กระโดด/เกิดใหม่ได้ตามระบบกล้องของเกม
    local origin = camera.CFrame.Position
    local direction = (info.point - origin).Unit
    local up = Vector3.new(0, 1, 0)
    if math.abs(direction:Dot(up)) > 0.999 then up = Vector3.new(0, 0, 1) end
    camera.CFrame = CFrame.lookAt(origin, info.point, up)
    local dot = math.clamp(camera.CFrame.LookVector:Dot(direction), -1, 1)
    local errorDegrees = math.deg(math.acos(dot))
    gui:SetAttribute("WriteAngleError", errorDegrees)
    -- WriteOK ยืนยันการอ่านกลับทันทีเท่านั้น ไม่ยืนยันว่าเกมไม่เขียนทับภายหลัง
    status(errorDegrees < 0.5 and "WriteOK" or "WriteMismatch", info.name,
        string.format("Immediate angle error %.2f deg | self H=%s", errorDegrees, ourHumanoid and "yes" or "no"))
end

-- ถ้าเกิด error จริง ให้ปิดและบันทึก error แทนการกลืนปัญหาแล้วแสดงว่าเปิดอยู่
RunService:BindToRenderStep(RENDER_NAME, Enum.RenderPriority.Last.Value + 1, function(dt)
    local ok, message = pcall(render, dt)
    if not ok then
        setEnabled(false)
        status("Error")
        gui:SetAttribute("LastError", tostring(message))
        nextDiagnostic = 0
        status("Error", nil, tostring(message))
        warn("[BM XY] " .. tostring(message))
    end
end)
print("[BM XY V6.1] Ready: corpse filter, 360 target search, idle rotation, instant head lock, attached toggle audio. AudioState=" .. tostring(gui:GetAttribute("AudioState")))
