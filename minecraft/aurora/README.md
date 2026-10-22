# SATURN X · AURORA

แพ็กภาพสำหรับ Minecraft Bedrock บนมือถือที่เปิด **Vibrant Visuals** ได้
รุ่น 1.0.0 · สร้างให้ BM · 22 ตุลาคม 2569

## ดาวน์โหลดและติดตั้ง

1. ดาวน์โหลด [SATURN_X_AURORA_1.0.0.mcpack](https://github.com/jrjhdjio/SATURN-X/raw/refs/heads/main/minecraft/aurora/dist/SATURN_X_AURORA_1.0.0.mcpack) แล้วเปิดด้วย Minecraft รอข้อความนำเข้าสำเร็จ
2. เข้าเมนูแก้ไขโลก → Resource Packs → My Packs → SATURN X | AURORA → Activate แล้วเลื่อนแพ็กไว้ด้านบน
3. จากหน้าหลักเข้า Settings → Video → Graphics Mode → **Vibrant Visuals**
4. ในการตั้งค่าแพ็ก (รูปเฟือง) เลือก **CINEMATIC** สำหรับเอฟเฟกต์คลื่นเต็ม หรือ **CALM** เพื่อปิดคลื่นโดยเก็บโทนแสงและสีไว้ จากนั้นออกแล้วเข้าโลกใหม่

ถ้าต้องการใช้ทุกโลก เปิดผ่าน Settings → Global Resources ได้ แต่แพ็กที่โลกเลือกไว้เองอาจทับการตั้งค่าได้

ถ้าดาวน์โหลดมาเป็น `.mcpack.zip` ให้เปลี่ยนชื่อท้ายกลับเป็น `.mcpack` โดยไม่ต้องแตกไฟล์ หากตัวจัดการไฟล์ไม่แสดง Minecraft ให้ใช้เมนูแชร์/เปิดด้วย Minecraft ของตัวจัดการไฟล์ที่รองรับการเปิดไฟล์ชนิดนี้

## ภาพที่ออกแบบไว้

- แสงกลางวันอุ่น พร้อมไล่สีทองและพีชช่วงพระอาทิตย์ขึ้นและตก
- กลางคืนสีน้ำเงิน พร้อมแสงจันทร์และเงานุ่ม
- ท้องฟ้าและสีภาพ 6 กลุ่ม: ทุ่ง/ป่า, เขตร้อน, ทะเลทราย, หิมะ, ซากุระ, ป่าลึกลับ
- น้ำ 7 แบบ: ใส, ทะเล, เขตร้อน, ทะเลลึก, แม่น้ำ, น้ำเย็น, บึง
- คลื่นผิวน้ำแบบภาพและลายแสงใต้น้ำ; คลื่นไม่เปลี่ยนรูปร่างบล็อกหรือฟิสิกส์
- ตั้งค่าสีคบเพลิง/ตะเกียงให้อุ่น ไฟวิญญาณสีฟ้า และแท่ง End โทนม่วงอ่อน ในเกมและอุปกรณ์ที่รองรับแสงสีแบบ point light; บน Android รุ่นเก่าเอฟเฟกต์ส่วนนี้อาจไม่แสดง แม้ส่วนแสงหลักและน้ำจะทำงาน
- รักษารูปแบบบล็อกเดิม เสียง หมอกและบรรยากาศเฉพาะของถ้ำ Nether และ End; ปรับสีภาพในมิติเหล่านี้อย่างอ่อน

ชื่อ AURORA เป็นชื่อแพ็ก ไม่ได้เพิ่มแสงเหนือบนท้องฟ้า

## ตั้งค่าสำหรับมือถือ

เริ่มจากโหมด Favor Visuals/เน้นภาพ หากมีให้เลือก และระยะมองเห็น 6–8 chunks แล้วค่อยเพิ่มตามความลื่นของเครื่อง ถ้าเฟรมตกให้ลด render distance, เลือก Favor Performance หรือเปลี่ยนเป็น CALM ตัวเลือกและระดับสูงสุดขึ้นกับรุ่นเกมและอุปกรณ์

CALM ลดงานเอฟเฟกต์คลื่นที่แพ็กเพิ่ม แต่ไม่ได้ปลดล็อกกราฟิก ไม่ได้ปิดทุกเอฟเฟกต์ของเกม และไม่รับประกัน FPS

## การรองรับและข้อจำกัด

- ต้องเป็น **Minecraft Bedrock 1.21.120 หรือใหม่กว่า** และเปิด Vibrant Visuals ได้ แนะนำอัปเดตเกมก่อนติดตั้ง
- ถ้าเมนู Vibrant Visuals เป็นสีเทาหรือไม่มี แพ็กนี้ไม่สามารถบังคับปลดล็อกอุปกรณ์ได้ ส่งภาพหน้า Video Settings และเลขเวอร์ชันเกมมาเพื่อตรวจต่อ
- เป็น resource pack ที่ปรับระบบแสงของเกม ไม่ใช่ shader `.zip` ของ Java/OptiFine/Iris, ไม่ใช่ RTX และไม่ต้องใช้ APK ดัดแปลง
- เงา การสะท้อน หมอก และลายแสงใต้น้ำยังขึ้นกับตัวเรนเดอร์ของเกม ระดับกราฟิก อุปกรณ์และไดรเวอร์
- การสะท้อนของ Vibrant Visuals ใช้เทคนิคของเกม จึงไม่รับประกันการสะท้อนวัตถุนอกจอหรือกระจกที่สมบูรณ์
- ไม่เปลี่ยนระบบเกิดมอนสเตอร์ ค่าความสว่างสำหรับเกมเพลย์ หรือพฤติกรรมโลก
- แพ็กที่แก้ client biomes/แสง/น้ำซ้อนกันอาจทับกัน ให้ทดสอบ AURORA เพียงแพ็กเดียวก่อน
- ไบโอมจากแอดออนที่กำหนด visuals ของตัวเองอาจไม่ใช้ AURORA
- ปรับการเชื่อมต่อภาพในไบโอม 87 แบบ; sulfur_caves และ dappled_forest ของเกมรุ่นใหม่เก็บภาพเดิมไว้ เพื่อไม่บังคับให้ทุกเครื่องใช้เวอร์ชัน 26.50

## สถานะการตรวจ

ตรวจ JSON, manifest/UUID, เวอร์ชันของข้อมูล, การอ้างอิงไบโอม, ช่วงค่าตามเอกสาร, ความต่อเนื่องรอบวัน, ตัวเลือกคลื่น และโครงสร้าง ZIP ด้วยสคริปต์แล้ว
**ยังไม่ได้เปิดทดสอบใน Minecraft จริงหรือบนโทรศัพท์ จึงยังยืนยันภาพจริง ความลื่น และความเข้ากันได้ของเครื่องไม่ได้** ไม่มีภาพจำลองที่อ้างว่าเป็นภาพจากเกม

## ซอร์สและการสร้างใหม่

ซอร์สอยู่ที่ [GitHub](https://github.com/jrjhdjio/SATURN-X/tree/main/minecraft/aurora)
`pack/` คือเนื้อหาแพ็กพร้อมใช้งาน สามารถ ZIP เนื้อหาภายในโฟลเดอร์นี้แล้วตั้งนามสกุล `.mcpack` ได้
`build.py` สร้างค่าภาพและแพ็กใหม่โดยใช้ไบโอม Mojang ใน `../vanilla-reference/` ตาม commit ที่บันทึกใน `UPSTREAM.json`
รัน `python fetch_reference.py` ครั้งแรกเพื่อดึงไฟล์อ้างอิงที่ตรวจ SHA-256 แล้ว จากนั้น `python build.py` เพื่อสร้างแพ็กใหม่; ไอคอนสำเร็จรูปมีอยู่แล้ว ไม่ต้องติดตั้งไลบรารีเพิ่มในการสร้างแพ็ก
ใช้ `python validate.py` เพื่อตรวจแพ็กและ ZIP อีกครั้ง

อ้างอิงทางเทคนิค:
- https://learn.microsoft.com/en-us/minecraft/creator/documents/vibrantvisuals/vvresourcepacks
- https://learn.microsoft.com/en-us/minecraft/creator/documents/vibrantvisuals/biomecustomization
- https://learn.microsoft.com/en-us/minecraft/creator/documents/vibrantvisuals/lightingcustomization
- https://learn.microsoft.com/en-us/minecraft/creator/documents/vibrantvisuals/atmosphericscustomization
- https://learn.microsoft.com/en-us/minecraft/creator/documents/vibrantvisuals/colorgradingtonemappingcustomization
- https://github.com/Mojang/bedrock-samples/blob/main/documentation/Water.html

Not an official Minecraft product. Not approved by or associated with Mojang or Microsoft.
