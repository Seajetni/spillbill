# 🔊 SplitBill - Zero-Install Web Receiver Service

ระบบหน้าเว็บสำหรับผู้รับ (Zero-Install Web Landing) และ API บันทึกข้อมูลเสียงทวงหนี้ (Voice Nudge) พัฒนาด้วย Express.js และเชื่อมต่อกับ **MongoDB Atlas** ออกแบบมาเพื่อให้เพื่อนที่โดนทวงหนี้สามารถเปิดฟังเสียงและกดชำระผ่าน PromptPay ได้ทันทีผ่าน Browser ใน LINE / Safari / Chrome **โดยไม่ต้องติดตั้งแอป**

---

## 🚀 ฟีเจอร์หลัก (Features)

* **🔊 เล่นไฟล์เสียงจริง / Web TTS**: เล่นไฟล์เสียงที่อัดหรือสังเคราะห์จาก AI พร้อม Waveform Visualizer เคลื่อนไหว
* **💳 PromptPay QR Code สด**: สร้าง QR Code PromptPay ตามยอดเงินและเบอร์โทรจริงทันที รองรับการสแกนจ่ายผ่านแอปธนาคารทุกธนาคารในไทย
* **⚡ Deep Link เปิดแอปธนาคาร**: ปุ่มเปิด K PLUS, SCB EASY, Krungthai NEXT ได้ใน 1 คลิก
* **📋 คัดลอกเลขพร้อมเพย์**: ปุ่มคัดลอกเลขบัญชีสำหรับโอนผ่านแอป
* **💬 ตอบกลับเร็ว (Quick Replies)**: กด "💸 โอนแล้ว", "⏰ ขอ 3 วัน", "😅 ลืมสนิท ขอโทษที" เพื่ออัปเดตสถานะกลับไปยังฐานข้อมูล MongoDB
* **🌐 OpenGraph Rich Preview**: แสดงการ์ดตัวอย่างสวยงามเมื่อแชร์ลิงก์เข้าไปใน LINE หรือ Messenger

---

## 🛠️ การตั้งค่า Environment Variables บน Vercel

เมื่อ Import โปรเจกต์ขึ้น **Vercel** ให้ตั้งค่า Environment Variable ดังนี้:

| Variable | ค่า (Value) |
| :--- | :--- |
| `MONGODB_URI` | `mongodb+srv://sea:S2UHiGtAAQiiRyDa@aquasmartguard.njwqyfu.mongodb.net/data?retryWrites=true&w=majority&appName=aquaSmartGuard` |

---

## 📡 API Endpoints

* `GET /`: หน้าตรวจสอบสถานะของ Web Service และการเชื่อมต่อ MongoDB
* `POST /api/nudge`: รับข้อมูลบิลและคลิปเสียงทวงหนี้เพื่อบันทึกลง MongoDB
* `GET /api/nudge/:id`: ดึงข้อมูลบิลเป็น JSON
* `POST /api/nudge/:id/reply`: บันทึกการตอบกลับหรือการแจ้งชำระเงิน
* `GET /n/:id`: หน้าเว็บสำหรับผู้รับ (Zero-Install Web Landing)
