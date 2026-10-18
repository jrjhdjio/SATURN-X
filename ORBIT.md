# SATURN X Orbit / BM

เมนูวงโคจรสำหรับ SATURN X ทั้ง 10 ตัว ใช้ตัวโหลด URL เดิมได้
เวอร์ชันส่วนติดต่อ: `1.2.2-orbit` • โมดูล Orbit: `1.0.2`

## แพตช์ 1.2.2

เมื่อเปิดหมวด จะแสดงเฉพาะหน้าที่เลือก โดยซ่อนแถบรายชื่อ 8 หมวดด้านซ้าย
เนื้อหาใช้พื้นที่เต็มความกว้างของกรอบเดิม พร้อมระยะขอบซ้ายและขวา 14 พิกเซล
ขนาดหน้าต่างและการปรับตามจอเดิมยังคงอยู่ แตะโลโก้มุมซ้ายบนเพื่อกลับวงโคจรและเลือกหน้าใหม่
เลือกหน้าก่อนแสดงหน้าต่าง เพื่อไม่ให้หน้าเก่าปรากฏระหว่างเปลี่ยนหมวด
รองรับการอัปเกรดเมนูที่เปิดอยู่ และคืนรูปแบบเดิมเมื่อถอนโมดูล
ตรวจไวยากรณ์และชุดทดสอบพฤติกรรมเดิมผ่านแล้ว ยังไม่ได้ลองแสดงผลใน Roblox/Delta จริง

## แพตช์ 1.2.1

แก้ภาพดาวที่แสดงติดหลายช่อง ภาพถูกตัด และวงกลมสำรองซ้อนภาพ ตามภาพที่พบใน Delta
เปลี่ยนจากพิกัด ImageRect แบบพิกเซลเป็นกรอบตัดภาพตามสัดส่วน จึงไม่ผูกกับความละเอียด texture หลังโหลด
ใช้สัดส่วนช่อง 9:8 เพื่อให้ดาวกลมตามภาพต้นฉบับ รวมหลุมดำและหลุมขาว
หลังตรวจไฟล์และลงทะเบียน local asset สำเร็จ จะซ่อนไอคอนสำรองโดยไม่รอสถานะ IsLoaded
หากดาวน์โหลดหรือลงทะเบียนไฟล์ไม่สำเร็จ จะยังใช้ไอคอนสำรองต่อได้
เมื่อรันตัวโหลดใหม่ ระบบเปลี่ยน Orbit รุ่นเก่าที่เปิดอยู่ พร้อมส่งต่อปุ่มเปิด/ย่อเดิมไปยังตัวใหม่
ตรวจขอบเขตทุกช่องที่ความละเอียด 1536×1024, 1024×683, 1024×682, 768×512 และ 512×341 ด้วยแบบจำลอง
ยังไม่ได้ยืนยันการ render หลังแก้ใน Roblox/Delta จริง; เครื่องตรวจสอบไม่มีเบราว์เซอร์สำหรับตรวจภาพเพิ่มเติม

## วิธีใช้

- เมื่อเปิดสคริปต์ จะเห็นโลโก้ SATURN X เดิมอยู่ตรงกลาง วงโคจร 8 วง และดาว 8 ดวง
- แตะดาวครั้งแรกเพื่ออ่านชื่อหมวดและรายละเอียด การโคจรจะพักระหว่างเลือก
- แตะดาวดวงเดิมอีกครั้งเพื่อเปิดหน้าหมวดเดิม
- แตะโลโก้ตรงกลางเพื่อล้างการเลือก
- ภายในหน้าหมวด แตะโลโก้ที่มุมซ้ายบนเพื่อกลับสู่วงโคจร
- แตะหลุมดำเพื่อย่อเมนู แล้วแตะโลโก้ลอยเพื่อเปิดกลับพร้อมหลุมขาวและวงโคจร
- ปุ่ม × ในหน้าหมวดยังคงปิดสคริปต์ทั้งหมด ส่วน Right Shift ยังคงเปิดหรือย่อเมนู
- ภาษาของชื่อหมวด รายละเอียด และคำแนะนำเปลี่ยนตาม ไทย / English / 中文 ในการตั้งค่าเดิม
- เสียงคลิก เสียงเปิด/ปิด เพลง และหน้าโหลดเดิมยังอยู่ พร้อมเสียงคลื่นวงแหวนใหม่เมื่อแตะดาว
- การตั้งค่า SX • FX และการลดการเคลื่อนไหวของ Roblox ใช้กับเอฟเฟกต์วงโคจรด้วย
- Scale-down และ Micro-interactions ในหน้าเลื่อนเดิมยังทำงานผ่าน Motion

## ขอบเขต

ใช้กับ SATURN_X, MINI, AVATAR, CAT_SITTING, DANCE, DEAD_RAILS, DOORS, FISCH, HYPERSHOT และ MM2

หมวดทั้ง 8 เรียก `selectTab` เดิมของแต่ละตัว โดยไม่แทนที่หน้าหรือโค้ดฟังก์ชันเกม
หน้าหมวดเก็บขนาดเดิมและกฎการปรับตามหน้าจอเดิม ส่วนวงโคจรปรับขนาดให้พอดีด้านสั้นของหน้าจอ
ที่พื้นที่ 360 × 740 ปุ่มดาวมีพื้นที่แตะประมาณ 48 × 48 พิกเซล วงโคจรพักขณะสัมผัส ชี้เมาส์ เลือกหมวด หรือหน้าต่างเสียโฟกัส

สคริปต์แต่ละไฟล์มี Orbit ฝังอยู่แล้ว ไม่ดาวน์โหลดโค้ดเพิ่มเติม
โมดูลติดตั้งบน media service เดิมได้ และการรันหลายตัวใช้แคชภาพกับเสียงร่วมกัน
เมื่อปิดสคริปต์ จะตัดการเชื่อมต่อ หยุด tween และยกเลิกผลของ callback ที่ค้างอยู่

## ภาพและเสียง

- `assets/SATURN_X_orbit_atlas_v1.png`: ภาพ AI ที่สร้างด้วย built-in imagegen; RGBA 1536 × 1024, 2,411,469 bytes
- Atlas 4 คอลัมน์ × 3 แถว: ดาว 8 ดวงในสองแถวแรก; หลุมดำกับหลุมขาวในสองช่องแรกของแถวสุดท้าย
- ใช้กรอบ ClipsDescendants และตำแหน่งตามสัดส่วน 4 × 3 แสดงแต่ละช่องจากภาพเดียว ภาพต้นฉบับไม่ได้ตัดหรือปรับแต่งหลังสร้าง
- เก็บโลโก้เดิม `assets/SATURN_X_logo.png` ไว้เป็นภาพศูนย์กลาง
- `assets/SATURN_X_orbit_wave_v1.wav`: เสียง chime สังเคราะห์ใหม่ 0.8 วินาที, PCM mono 44.1 kHz, 16-bit; 70,604 bytes
- ต้องใช้ runtime ที่รองรับ writefile และ getcustomasset หรือ getsynasset สำหรับภาพและเสียงในเครื่อง
- ตรวจขนาดและ signature ของไฟล์ก่อนลงทะเบียน หากยังโหลดภาพไม่ได้ จะใช้ดาวสีพร้อมหมายเลขให้เลือกหมวดต่อได้
- ไม่ได้ยืนยันการเล่นเสียงหรือการแสดงภาพใน Delta จริง

### Imagegen prompt

```text
Use case: stylized-concept. Asset type: ONE production sprite-atlas texture for a premium circular space-themed game menu called SATURN X. Create a single transparent RGBA image, landscape, ideally 1536 by 1024, precisely arranged as 4 equal columns and 3 equal rows. Absolutely NO grid lines, NO labels, NO text, NO background, NO checkerboard. Every icon is isolated with generous fully transparent padding, centered within its own cell, occupying at most 65% of cell width and height, with no touching between cells. Row 1 from left to right: a textured silver cratered moon planet; a warm copper rocky planet; a pale icy cyan planet; a deep emerald planet with subtle cloud bands. Row 2 from left to right: an amber gas giant with bands; a violet crystalline-looking planet; a deep blue ocean planet; a small pearl-silver Saturn-like planet with elegant diagonal rings. Row 3: first cell a beautiful BLACK HOLE icon, round black event horizon surrounded by a slim warm silver-white accretion ring and subtle light bending; second cell a WHITE HOLE icon, brilliant pearl-white luminous round core with cool pale-blue concentric accretion rings; third and fourth cells entirely empty and transparent. Consistent luxurious semi-realistic 3D space illustration, same soft upper-left key light, fine material detail, crisp silhouette. Restrained clean glows confined to each cell. Planets must remain legible as small mobile UI buttons. The circles and portals are seen mostly front-on. This is a functional texture atlas, not a composed space scene. Keep every icon in the specified separate grid cell. True alpha transparency everywhere outside the icons.
```

## การตรวจสอบ

```sh
texlua tools/test_orbit.lua shared/SATURN_X_ORBIT.lua shared/SATURN_X_MOTION.lua
texluac -p SATURN_X_MINI.lua
```

ตรวจไวยากรณ์ครบ 10 entrypoints และโมดูลที่เปลี่ยนแล้ว
ตรวจพฤติกรรม 16 กลุ่มด้วย Roblox API จำลอง รวม Motion จริง: การเลือกสองครั้งครบ 8 หมวด,
การย่อ/เปิดกลับ, การสลับเร็ว, สามภาษา, reduced motion, touch/focus,
การปรับหน้าจอ, การโหลดภาพล้มเหลว, แคช และ cleanup
ตรวจย้อนการแทนที่โมดูลและเพิ่ม bridge แล้วได้ core เดิมครบทั้ง 10 ตัว
ชุดทดสอบไม่ได้ตรวจการ render, hit testing, asset decode หรือฟังก์ชันเกมใน Roblox / Delta จริง

