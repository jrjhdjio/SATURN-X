# SATURN X MINI — BM

MINI คือชื่อรุ่นเครื่องมือทั่วไป **ใช้ขนาดเมนูเดิม**: 760 × 510 บนจอกว้าง และผัง 430 × 620 บนจอแนวตั้ง พร้อมปรับให้พอดีหน้าจอแบบรุ่นเดิม

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/jrjhdjio/SATURN-X/main/SATURN_X_MINI.lua"))()
```

## ฟังก์ชัน

- บิน: จอยมือถือหรือ WASD และปุ่ม ↑ ↓ หรือ Space / Ctrl; ปรับความเร็ว 10–150
- ความเร็วเดิน 8–100, ความสูงกระโดด 5–50, กระโดดกลางอากาศ และเดินทะลุ
- เพิ่มความสว่าง ลดหมอก ปิดเงา และปรับ FOV
- บันทึกพิกัดได้ 8 จุดในครั้งที่เปิดใช้งาน
- โปรไฟล์ผู้เล่น เครดิต BM และเมนู 8 หมวด
- โลโก้ดาวเสาร์ เสียงเปิด/ปิดและคลิก เพลง หน้าโหลด และภาษาไทย / English / 中文 ใช้ระบบร่วมกับ SATURN X

ลากแถบด้านบนเพื่อย้าย ย่อเป็นปุ่มดาวเสาร์ได้ กด Right Shift เพื่อเปิด/ย่อ และ End เพื่อหยุดฟังก์ชันทั้งหมด ปิดเมนูด้วย × จะคืนค่าที่แก้และลบตัวควบคุมบิน เกิดใหม่แล้วฟังก์ชันการเคลื่อนที่จะปิด ต้องเปิดใหม่เอง

ไฟล์ MINI แยกจากรุ่นเฉพาะเกม ไม่มีระบบดึงไอเท็มหรือฟังก์ชันเฉพาะแมพ เสียงและภาพโหลดจาก `assets/` ของคลังนี้ ระบบ MP3 ต้องรองรับ `writefile` และ `getcustomasset`/`getsynasset` หากไม่รองรับยังเปิดเมนูได้

ตรวจไวยากรณ์และพฤติกรรมด้วยแบบจำลอง 8 กลุ่ม: ขนาดเดิม, 3 ภาษา, ความเร็ว/กระโดด, บิน/ย่อ/เสียโฟกัส, คืนค่า collision, กระโดดกลางอากาศ, เกิดใหม่/คืนค่า, และปิดซ้ำ/ตัด event handlers **ยังไม่ได้ทดสอบใน Roblox หรือ Delta จริง** เซิร์ฟเวอร์อาจจำกัดหรือคืนค่าการเคลื่อนที่

API references: [LinearVelocity](https://create.roblox.com/docs/reference/engine/classes/LinearVelocity), [Humanoid](https://create.roblox.com/docs/reference/engine/classes/Humanoid), [UserInputService](https://create.roblox.com/docs/reference/engine/classes/UserInputService).
