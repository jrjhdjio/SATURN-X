-- BM XY AIM V6.2 / 2026-10-20 / ไม่หมุนหาเมื่อไม่มีเป้า + กรองศพ
-- ข้ามสถานะ Dead, เหตุการณ์ Died, ร่างผู้เล่นเก่าที่เคยตรวจพบ และป้ายกำกับศพ
-- ไม่ตัดสินจากการนอน/ล้ม/Ragdoll อย่างเดียว; เกิดใหม่เป็นร่างใหม่ยังเลือกได้
-- ศพที่สร้างใหม่ เลือดเต็ม และไม่มีชื่อ/ป้าย/สถานะบอกว่าเป็นศพ ยังอาจแยกไม่ได้
-- เปิดปุ่ม: หาเป้าที่มีแนวเล็งโล่งทั้งหน้า/ข้าง/หลัง; ไม่มีเป้าจะปล่อยให้ควบคุมกล้องเอง
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
    AutoRotateWhenNoTarget = false, -- ไม่มีเป้า: ไม่หมุนกล้องหาเอง
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

-- BEGIN SATURN_X_SHARED_MEDIA 1.0.0
local SXMedia = (function()
-- SATURN X media / BM / 1.0.0
-- This module is bundled into every entry script; only image/audio data is downloaded.
-- Local music needs writefile and getcustomasset/getsynasset. No telemetry.
local env = (type(getgenv) == "function" and getgenv()) or _G
local existing = env.SATURN_X_MEDIA_SERVICE
if type(existing) == "table" and existing.Version == "1.0.0" and existing.Alive then return existing end
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
    effectsEnabled=true, effectsVolume=0.45, loadingScreen=true, backgroundWhenHidden=true}
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
return M

end)()
-- END SATURN_X_SHARED_MEDIA
local SXSession = SXMedia:Begin("BM_XY_Aim_Players_Bots","BM XY")
SXSession.OpenSound=true

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
    local line1 = "V6.2 | " .. state
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
        if not SXMedia:PlayEffect(toggleSound) then return end
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
    SXMedia:PlayEffect(SXMedia.UISounds.window)
    SXSession:Close()
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
print("[BM XY V6.2] Ready: corpse filter, 360 target search, idle rotation off, instant head lock, attached toggle audio. AudioState=" .. tostring(gui:GetAttribute("AudioState")))

SXSession:Bind(gui)
SXSession:Finish()
