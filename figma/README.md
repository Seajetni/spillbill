# ❖ SplitBill — Figma Design System & Simulator Files

ระบบจำลองดีไซน์และ Wireflow สำหรับ **SplitBill Flutter Application** ออกแบบตามมาตรฐาน **iPhone 16 Pro (393 × 852 px)** พร้อมส่งออกเป็นไฟล์แยกตามคำขอเพื่อนำเข้าใช้งานใน **Figma** ได้ทันที 100%

---

## 📁 รายการไฟล์แยกในโฟลเดอร์นี้

### 📱 1. ไฟล์หน้าจอแยกแต่ละหน้า (Individual Figma Screen SVGs)
> *วิธีใช้*: ลากไฟล์ `.svg` แต่ละไฟล์ไปวาง (Drag & Drop) ลงในโปรแกรม Figma ได้โดยตรง จะได้ Frame เวกเตอร์แยกอิสระ สามารถแก้ไขข้อความ สี และเลย์เอาต์ได้ทุกจุด

| ไฟล์ | ชื่อหน้าจอ (Screen Name) | รายละเอียดที่จำลอง |
| :--- | :--- | :--- |
| [01_home_dashboard.svg](file:///D:/code/split_bill/figma/01_home_dashboard.svg) | **Home Dashboard** | หน้าแรก, ยอดสุทธิ Net Balance, รายการ "ต้องจัดการ", Quick Action ปุ่มลัด, แท็บเมนูล่าง |
| [02_manual_bill_entry.svg](file:///D:/code/split_bill/figma/02_manual_bill_entry.svg) | **Manual Bill Entry** | กรอกรายละเอียดบิล, หมวดหมู่อีโมจิ, วันที่, รายการอาหารแยกชิ้น, VAT 7%, Service Charge |
| [03_split_mode_selection.svg](file:///D:/code/split_bill/figma/03_split_mode_selection.svg) | **Split Mode Selector** | เลือกวิธีหาร (เท่ากัน / ตามจริง), ชิปเลือกเพื่อน, ระบบปัดเศษสตางค์ (Penny Rounding) |
| [04_bill_summary_breakdown.svg](file:///D:/code/split_bill/figma/04_bill_summary_breakdown.svg) | **Bill Summary & Invoice** | สรุปยอดใบเสร็จ, หุ้นจ่ายรายบุคคล, ป้ายสถานะชำระเงิน, ปุ่มส่งเสียงทวง AI รวม |
| [05_payment_promptpay_qr.svg](file:///D:/code/split_bill/figma/05_payment_promptpay_qr.svg) | **Payment & PromptPay QR** | หน้าชำระเงิน, บัตร QR พร้อมเพย์ทางการ, ปุ่มลัดเปิดแอป K PLUS/SCB/ttb, แนบสลิป |
| [06_voice_nudge_ai_studio.svg](file:///D:/code/split_bill/figma/06_voice_nudge_ai_studio.svg) | **AI Voice Nudge Studio** | เลือกบุคลิกเสียง (น้องนุ่ม, เพื่อนซี้), ปรับระดับ Escalation, ปุ่ม AI Gemini, พรีวิวเสียง |
| [07_voice_record_effects.svg](file:///D:/code/split_bill/figma/07_voice_record_effects.svg) | **Voice Record & FX** | บันทึกเสียงไมค์จริง, ตัวจับเวลา, Waveform คลื่นเสียงสด, เอฟเฟกต์ชิพมังก์/ทุ้มลึก |
| [08_zero_install_web_receiver.svg](file:///D:/code/split_bill/figma/08_zero_install_web_receiver.svg) | **Zero-Install Web Landing** | หน้าเว็บสำหรับเพื่อน (Web View บนเบราว์เซอร์), เครื่องเล่นเสียง, Quick Reply |
| [09_groups_debt_simplification.svg](file:///D:/code/split_bill/figma/09_groups_debt_simplification.svg) | **Groups & Debt Graph** | กลุ่มเพื่อน, กราฟตัดยอดหนี้ซ้ำซ้อน (ลดจาก 7 ครั้งเหลือ 3 ครั้ง), ประวัติบิล |
| [10_statistics_analytics.svg](file:///D:/code/split_bill/figma/10_statistics_analytics.svg) | **Statistics & Reports** | สถิติค่าใช้จ่าย, โดนัทชาร์ตแยกหมวด, แถบสัดส่วนรายจ่าย, ปุ่ม Export CSV & PDF |
| [11_user_profile_settings.svg](file:///D:/code/split_bill/figma/11_user_profile_settings.svg) | **Profile & Settings** | ข้อมูลผู้ใช้, จัดการบัญชีธนาคาร (กสิกร/ไทยพาณิชย์), กฎสโตร์ Apple (ลบบัญชี/นโยบาย) |
| [12_notifications_modal.svg](file:///D:/code/split_bill/figma/12_notifications_modal.svg) | **Notifications Sheet** | หน้าต่างแจ้งเตือน Modal Sheet, ฟิลเตอร์ประเภท, การแจ้งเตือนรับเงินและเสียงทวง |

---

### 🗺️ 2. มาสเตอร์บอร์ดรวมทุกหน้า (Master System Board)
- [00_all_screens_figma_board.svg](file:///D:/code/split_bill/figma/00_all_screens_figma_board.svg):
  - รวมทั้ง 12 หน้าจอจัดเรียงบน Infinite Canvas พร้อมลูกศรเชื่อมต่อ Prototype Wireflow ลากไฟล์เดียวลง Figma ได้ทั้งระบบทันที

---

### 🧩 3. ชุดคอมโพเนนต์ Master UI Kit
- [figma_ui_kit_components.svg](file:///D:/code/split_bill/figma/figma_ui_kit_components.svg):
  - รวมชิ้นส่วน Buttons, Badges, Status Chips, Participant Avatars, Audio Waveforms, Form Inputs, และ Color Swatches

---

### 🎨 4. Design Tokens JSON (W3C Standard)
- [figma_tokens.json](file:///D:/code/split_bill/figma/figma_tokens.json):
  - กำหนดค่าตัวแปร Color Palette, Typography, Spacing, Border Radius, Elevation สำหรับใช้กับปลั๊กอิน **Tokens Studio for Figma** หรือ Figma Variables

---

### 💻 5. โปรแกรมจำลอง Figma เสมือนจริงบนเบราว์เซอร์ (Interactive Web Simulator)
- [figma_simulator.html](file:///D:/code/split_bill/figma/figma_simulator.html):
  - ดับเบิ้ลคลิกเพื่อเปิดใน Google Chrome / Microsoft Edge
  - มีแถบเมนูเครื่องมือจำลอง Figma Canvas ย่อ/ขยาย ซูมเข้า-ออก
  - มีปุ่ม **"📋 Copy SVG สำหรับวางใน Figma"** สามารถคลิกคัดลอก แล้วไปกด `Ctrl + V` วางลงในโปรเจกต์ Figma ของคุณได้ทันที!
