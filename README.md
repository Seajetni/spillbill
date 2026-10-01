# 📱 SplitBill - Flutter App

แอปพลิเคชันจัดการหารบิลและติดตามยอดหนี้สำหรับกลุ่มเพื่อน ออกแบบมาเพื่อลดความกระอักกระอ่วนใจในการทวงเงิน พร้อมระบบคำนวณภาษี/ส่วนลด, รองรับ PromptPay QR Code, และฟีเจอร์เสียงทวงหนี้จำลอง (Voice Nudge)

---

## 📋 Production & App Store Readiness Checklist (รายการที่ต้องทำเพื่อปล่อยใช้งานจริง)

จากการวิเคราะห์โค้ดอย่างละเอียด (Forensic Code Audit) ของโปรเจกต์ ปัจจุบันหน้าจอหลักส่วนใหญ่ยังเป็น **UI Prototype/Mockup** ที่ใช้ข้อมูลจำลองใน RAM และมี Hardcoded Logic อยู่หลายจุด หากต้องการ Deploy ขึ้น **Apple App Store** เพื่อใช้งานจริง ต้องพัฒนาและแก้ไข **7 ระบบหลัก** ดังต่อไปนี้:

---

### 1. ระบบสร้างบิลและการคำนวณ (Bill Creation & Splitting Engine)
* [x] **สร้างหน้าฟอร์มสร้างบิลใหม่จากศูนย์ (Blank Bill Creation)**
  * พัฒนาหน้า [ManualBillEntryScreen](file:///D:/code/split_bill/lib/screens/manual_bill_entry_screen.dart) เรียบร้อยแล้ว พร้อมฟังก์ชันตั้งชื่อบิล, เลือกหมวดหมู่/Emoji, วันที่, ผู้สำรองจ่าย, และเพิ่ม/แก้ไข/ลบรายการอาหาร
  * เชื่อมต่อปุ่ม "✍️ กรอกเอง" (`provider.createBlankBill()`) และ "🔁 ทำซ้ำจากบิลเดิม" (`provider.duplicateLatestBill()`) ใน [main_scaffold.dart](file:///D:/code/split_bill/lib/screens/main_scaffold.dart) และ [group_details_screen.dart](file:///D:/code/split_bill/lib/screens/group_details_screen.dart) เรียบร้อย
* [x] **แก้ไข Logic การหารบิลแบบ Dynamic (ไม่จำกัดจำนวนคน)**
  * ปลดล็อก `allMembers.take(4)` ใน [split_bill_provider.dart](file:///D:/code/split_bill/lib/providers/split_bill_provider.dart) และ [split_mode_screen.dart](file:///D:/code/split_bill/lib/screens/split_mode_screen.dart)
  * รองรับการเลือกสมาชิกที่เข้าร่วมในแต่ละบิลได้จริงแบบยืดหยุ่น (ไม่จำกัดจำนวนคน) พร้อมปุ่ม "+ เพิ่มเพื่อน" ใหม่เข้าบิลได้ทันที
* [x] **ดึงวันที่ของบิลตามจริง (Dynamic Date Formatting)**
  * ใน [bill_summary_screen.dart](file:///D:/code/split_bill/lib/screens/bill_summary_screen.dart), [manual_bill_entry_screen.dart](file:///D:/code/split_bill/lib/screens/manual_bill_entry_screen.dart) และ [ocr_review_screen.dart](file:///D:/code/split_bill/lib/screens/ocr_review_screen.dart) เปลี่ยนมาจัดฟอร์แมตวันที่ตาม `bill.date` จริง ผ่าน [DateFormatter](file:///D:/code/split_bill/lib/utils/date_formatter.dart) ด้วย package `intl` (เช่น "9 ก.ย. 69")
* [x] **ระบบปัดเศษสตางค์ (Penny Rounding Strategy)**
  * พัฒนาระบบจัดการเศษสตางค์ครบทั้ง 3 รูปแบบใน [split_bill_provider.dart](file:///D:/code/split_bill/lib/providers/split_bill_provider.dart):
    1. คนสำรองจ่ายรับผิดชอบเศษ (Payer Absorbs)
    2. กระจายเศษ 1 สตางค์ให้คนแรก ๆ (Distribute Evenly)
    3. ปัดเป็นจำนวนเต็มบาท (Round to Baht)
  * มี UI ให้เลือกและแสดงผลทั้งในโหมดหารเท่ากันและหารตามจริง พร้อมชุด Unit Test ตรวจสอบความถูกต้อง 100% (ดู [bill_calculation_test.dart](file:///D:/code/split_bill/test/bill_calculation_test.dart))

---

### 2. ระบบการเงินและธนาคาร (Payment & Bank Integration)
* [x] **เชื่อมต่อเบอร์ PromptPay ของผู้รับเงินจริง**
  * ใน [payment_screen.dart](file:///D:/code/split_bill/lib/screens/payment_screen.dart) ดึงเบอร์ PromptPay ของสมาชิกที่เป็นเจ้าหนี้จริงในแต่ละบิล (ผ่าน `widget.recipient.promptPayNumber`)
* [x] **เชื่อมต่อ Deep Link เปิดแอปธนาคารจริง**
  * ใน [payment_screen.dart](file:///D:/code/split_bill/lib/screens/payment_screen.dart) ติดตั้ง `url_launcher` พร้อมตั้งค่า URL Scheme ใน iOS `Info.plist` และ Android `<queries>` (SCB Easy, K PLUS, ttb, KMA) พร้อมปุ่มคัดลอกเบอร์ PromptPay หากยังไม่ได้ติดตั้งแอป
* [x] **ฟังก์ชันบันทึกรูป QR Code ลง Photo Library จริง**
  * ใน [payment_screen.dart](file:///D:/code/split_bill/lib/screens/payment_screen.dart) ใช้ `RepaintBoundary` แปลง Widget QR Code เป็นภาพ และเซฟลงเครื่องจริงผ่านแพ็กเกจ `gal` พร้อมขอ Permission
* [x] **ระบบแนบสลิปโอนเงิน (Slip Attachment)**
  * ใน [payment_screen.dart](file:///D:/code/split_bill/lib/screens/payment_screen.dart) ติดตั้ง `image_picker` ให้ผู้ใช้เลือกภาพสลิปจากอัลบั้มจริง พร้อมแสดงพรีวิวภาพขนาดย่อและบันทึกสถานะชำระเงินเรียบร้อยแล้ว

---

### 3. ระบบเสียง AI และการทวงหนี้ (Voice Nudge & AI Engine)
* [x] **เชื่อมต่อ LLM สำหรับสร้างบทพูด AI ตามบริบทจริง**
  * พัฒนา [GeminiService](file:///D:/code/split_bill/lib/services/gemini_service.dart) เชื่อมต่อ Gemini API (`gemini-3.6-flash` / `gemini-flash-latest`) พร้อม API Key จริง
  * ใน [VoiceNudgeAiScreen](file:///D:/code/split_bill/lib/screens/voice_nudge_ai_screen.dart) เชื่อมต่อปุ่ม "✨ AI ช่วยเขียน", "😂 ใส่มุก", "🙏 สุภาพขึ้น" สร้างบทพูดทวงเงินตามชื่อเพื่อน, รายการบิล, ยอดเงิน, คาแรกเตอร์ (Persona), และระดับความสนิท (Escalation Ladder) พร้อมระบบ Fallback อัจฉริยะหากออฟไลน์
* [x] **ระบบแปลงข้อความเป็นเสียงพูด (Text-to-Speech Engine)**
  * พัฒนา [TtsService](file:///D:/code/split_bill/lib/services/tts_service.dart) รองรับทั้งการสังเคราะห์ไฟล์เสียงผ่าน ElevenLabs API (Multi-lingual v2) และเครื่องยนต์ `flutter_tts` ภาษาไทย (`th-TH`) ปรับระดับเสียง (Pitch) และความเร็ว (Rate) ตาม Persona แต่ละแบบ
  * มีปุ่ม "▶ ลองฟังเสียง AI" ใน [VoiceNudgeAiScreen](file:///D:/code/split_bill/lib/screens/voice_nudge_ai_screen.dart) ก่อนส่ง
* [x] **ระบบบันทึกเสียงและเล่นไฟล์เสียงจริง**
  * พัฒนา [AudioService](file:///D:/code/split_bill/lib/services/audio_service.dart) เชื่อมต่อแพ็กเกจ `record` (สำหรับอัดเสียงไมโครโฟนจริง) และ `audioplayers` (สำหรับเล่นไฟล์เสียงจริง)
  * ใน [VoiceNudgeRecordScreen](file:///D:/code/split_bill/lib/screens/voice_nudge_record_screen.dart) อัดเสียงไมโครโฟนจริง บันทึกไฟล์ `.m4a` ปรับเอฟเฟกต์ความเร็ว (ชิพมังก์, ทุ้มลึก, วิทยุเก่า, ห้องโถง) และส่งต่อไปยัง [VoiceReceiverScreen](file:///D:/code/split_bill/lib/screens/voice_receiver_screen.dart) เพื่อเล่นเสียงจริงพร้อม Waveform สด

---

### 4. สถาปัตยกรรมคลาวด์และระบบ Multi-User (Backend & Real Sync)
* [ ] **ระบบระบุตัวตนและยืนยันตัวตน (Authentication)**
  * ปัจจุบันผู้ใช้ทุกคนเป็น `m_pop` อัตโนมัติ ขาดระบบ Sign Up / Sign In
  * *ข้อกำหนด Apple*: หากมีระบบบัญชี ต้องรองรับ **Sign in with Apple** (Guideline 4.8) และมี **ปุ่มลบบัญชี (Account Deletion)** ในแอป (Guideline 5.1.1(v))
* [x] **ระบบฐานข้อมูล Cloud Database (Real-time Sync) [เลือกใช้ Vercel + MongoDB Atlas]**
  * จัดเก็บบน **MongoDB Atlas** (คลัสเตอร์ aquasmartguard) เชื่อมโยงผ่าน Serverless API บน **Vercel** (`https://spillbill.vercel.app/api/nudge`) ใช้งานได้จริงแล้ว
* [ ] **ระบบ Push Notification ข้ามเครื่อง (APNs / FCM)**
  * ใน `lib/screens/notifications_sheet.dart` เป็นเพียง `simulateIncomingNotification()` ใส่ในเครื่องตัวเอง
  * ต้องติดตั้ง Apple Push Notification service (APNs) ผ่าน Firebase Cloud Messaging เพื่อส่งแจ้งเตือนเข้ามือถือเพื่อนเมื่อมีบิลใหม่หรือมียอดชำระ

---

### 5. ระบบหน้าเว็บสำหรับเพื่อน (Zero-Install Web Landing) [สถาปัตยกรรม Vercel + MongoDB]
* [x] **พัฒนา Web Application จริงบน Vercel (Express Serverless)**
  * พัฒนาหน้าเว็บ Zero-Install โฮสต์บน **Vercel** (`https://spillbill.vercel.app`) เชื่อมต่อฐานข้อมูล **MongoDB Atlas**
  * รูปแบบ URL: `https://spillbill.vercel.app/n/:nudgeId` เปิดฟังเสียงทวง, สแกน QR PromptPay, เปิด Deep Link K PLUS/SCB/Krungthai และกดส่ง Quick Reply ได้ทันที
* [x] **ระบบแชร์ลิงก์และไฟล์เสียงด้วย Native Share Sheet**
  * เชื่อมต่อ package `share_plus` ใน [voice_nudge_share_modal.dart](file:///D:/code/split_bill/lib/widgets/voice_nudge_share_modal.dart) สามารถแชร์ข้อความสรุปยอด, เลขพร้อมเพย์, ลิงก์ และ**แนบไฟล์เสียงจริง (.m4a / .mp3)** ส่งตรงเข้าแชท LINE หรือโซเชียลมีเดียได้ทันที พร้อมปุ่มเปิดดูตัวอย่างหน้าจอฝั่งเพื่อน (Receiver Preview)

---

### 6. ระบบสถิติและการส่งออกไฟล์ (Analytics & Export Engine)
* [x] **คำนวณสถิติจากประวัติบิลจริง**
  * ใน [statistics_screen.dart](file:///D:/code/split_bill/lib/screens/statistics_screen.dart) คำนวณสัดส่วนค่าใช้จ่าย (อาหาร, ที่พัก, เดินทาง, อื่น ๆ) และยอดรวมสุทธิตามรายการบิลและช่วงเวลาจริงจาก `SplitBillProvider`
* [x] **ระบบ Export ไฟล์ CSV และ PDF**
  * ใน [statistics_screen.dart](file:///D:/code/split_bill/lib/screens/statistics_screen.dart) ติดตั้ง package `csv`, `pdf`, และ `path_provider` สามารถสร้างและส่งออกไฟล์ Excel CSV และเอกสารสรุป PDF จริงพร้อมปุ่มแชร์

---

### 7. การจัดการกลุ่มและสมาชิก (Group & Member Management)
* [ ] **ระบบเพิ่มเพื่อนและค้นหาสมาชิกใหม่**
  * ปัจจุบันมีสมาชิกตายตัว 5 คนใน Provider
  * ต้องพัฒนาระบบค้นหาเพื่อนผ่านเบอร์โทร/Username, สแกน QR Code เชิญเข้ากลุ่ม, หรือดึงจากรายชื่อสมุดโทรศัพท์ (Contacts)
* [ ] **อัลกอริทึมลดยอดหนี้ซ้ำซ้อน (Debt Simplification Graph)**
  * เมื่อมีการออกเงินหลายคนข้ามไปมา (A ติด B, B ติด C, C ติด A) ต้องมี Logic คำนวณรวบยอดหนี้สุทธิ (Net Debt Minimization) เพื่อให้เกิดการโอนเงินจำนวนครั้งน้อยที่สุด
---

## 🗺️ แผนงานและลำดับขั้นตอนการพัฒนาต่อ (Action Plan & Implementation Roadmap)

จัดกลุ่มและจัดลำดับความสำคัญ (Prioritization) ของงานที่ต้องทำต่อ เพื่อให้พัฒนาได้อย่างเป็นระบบและวัดผลได้ชัดเจน:

### 🚀 ระยะที่ 1: Quick Wins & Client-side Integration (ปลดล็อกฟังก์ชันบนเครื่องจริง)
> มุ่งเน้นการเปลี่ยน Mockup ที่ทำงานในระดับเครื่องให้ใช้งานได้จริง โดยยังไม่ต้องพึ่งพา Cloud Backend
* [x] **ระบบการเงินและ PromptPay จริง**:
  * ปรับ [payment_screen.dart](file:///D:/code/split_bill/lib/screens/payment_screen.dart) ให้ดึงเบอร์/เลขบัตรของเจ้าหนี้จริงในบิลแทน `'0812345678'`
  * ติดตั้ง `url_launcher` ทำ Deep Link เปิดแอปธนาคารจริง (K PLUS, SCB Easy, ttb, KMA)
  * ติดตั้ง `gal` เพื่อเซฟภาพ PromptPay QR ลง Photo Library
  * ติดตั้ง `image_picker` ให้แนบสลิปจริงจากอัลบั้มพร้อมพรีวิวภาพขนาดย่อ
* [x] **ระบบแชร์ลิงก์บิล**:
  * ติดตั้ง `share_plus` ทำ Native Share Sheet ส่งลิงก์/ยอดเข้า LINE หรือโซเชียลมีเดีย
* [x] **ระบบสถิติจริงและ Export**:
  * แก้ไข [statistics_screen.dart](file:///D:/code/split_bill/lib/screens/statistics_screen.dart) ให้คำนวณกราฟสัดส่วนจากรายการบิลจริงใน Provider
  * ติดตั้ง `csv`, `pdf`, `path_provider` เพื่อ Export รายงานรายรับ-รายจ่ายจริง (CSV & PDF)

### 🎙️ ระยะที่ 2: ฟีเจอร์ AI Voice Nudge (จุดเด่นของแอป - มี API Key พร้อม)
> ดึงศักยภาพของ Generative AI และ TTS มาใช้สร้างเสียงทวงหนี้จำลองตามบุคลิกและความสนิท
* [x] **เชื่อมต่อ Gemini API**:
  * ต่อ Gemini API ใน [voice_nudge_ai_screen.dart](file:///D:/code/split_bill/lib/screens/voice_nudge_ai_screen.dart) เพื่อสร้างบทพูดทวงเงินตามชื่อเพื่อน, ยอดเงิน, และระดับความสนิท (Escalation Ladder)
* [x] **ระบบ Text-to-Speech (TTS) & เสียงสังเคราะห์**:
  * เชื่อมต่อ ElevenLabs API และ `flutter_tts` แปลงบทสคริปต์เป็นไฟล์เสียงพูดภาษาไทย พร้อมพรีวิวเสียงตาม Persona
* [x] **ระบบบันทึกและเล่นเสียงจริง**:
  * เชื่อมต่อแพ็กเกจ `record` และ `audioplayers` ใน [voice_nudge_record_screen.dart](file:///D:/code/split_bill/lib/screens/voice_nudge_record_screen.dart) และ [voice_receiver_screen.dart](file:///D:/code/split_bill/lib/screens/voice_receiver_screen.dart) แทนการจำลองเวลา

### ☁️ ระยะที่ 3: สถาปัตยกรรมคลาวด์และระบบ Multi-User (Cloud Sync & Backend - Vercel + MongoDB Atlas)
> จำเป็นสำหรับให้เพื่อนใช้จริงข้ามเครื่อง และเป็นเงื่อนไขสำคัญในการส่งขึ้น App Store
* [x] **Cloud Database & Web Landing (Vercel + MongoDB Atlas)**:
  * จัดเก็บข้อมูลบิล, การทวงหนี้ (Voice Nudge) บน MongoDB Atlas (Cluster aquasmartguard) ผ่าน Vercel Serverless Function สำเร็จ
  * พัฒนาหน้าเว็บ Zero-Install Receiver บน Vercel (`https://spillbill.vercel.app/n/:id`) เปิดฟังเสียงและชำระ PromptPay ได้จากเบราว์เซอร์
* [ ] **ระบบ Authentication**:
  * ทำระบบ Sign in with Apple (ตาม Apple Guideline 4.8) และปุ่มลบบัญชี (Account Deletion)
* [ ] **ระบบ Debt Simplification Graph**:
  * พัฒนาอัลกอริทึมลดยอดหนี้ซ้ำซ้อนเพื่อให้โอนเงินน้อยครั้งที่สุด

### 🍎 ระยะที่ 4: ตรวจสอบความพร้อมและเตรียมขึ้น App Store (iOS Readiness)
* [x] เพิ่มคำขอ Permission ใน `Info.plist` (กล้อง `NSCameraUsageDescription`, ไมโครโฟน `NSMicrophoneUsageDescription`, อัลบั้ม `NSPhotoLibraryUsageDescription` / `NSPhotoLibraryAddUsageDescription`)
* [x] เพิ่ม `<key>ITSAppUsesNonExemptEncryption</key><false/>` ใน `ios/Runner/Info.plist`
* [x] จัดทำ `ios/Podfile` กำหนด `platform :ios, '15.0'` และ build settings พร้อมคอมไพล์ CocoaPods
* [x] จัดทำหน้าเว็บ **Privacy Policy** (`https://spillbill.vercel.app/privacy`) และ **Support URL** (`https://spillbill.vercel.app/support`) เปิดใช้งานจริงแล้ว
* [x] ติดตั้ง **GitHub Actions CI/CD** (`.github/workflows/ios_build.yml`) ทดสอบคอมไพล์บน macOS runner และสร้าง Build Artifact สำหรับ iOS สำเร็จ 100%
* [ ] จัดเตรียม Apple Developer Account ($99/ปี)
* [ ] เปลี่ยน Bundle Identifier จาก `com.splitbill.splitBill` ใน Xcode project เป็น Domain ของผู้พัฒนา
* [ ] ออกแบบ App Icon (1024x1024 px ไม่มี Alpha) และรัน `flutter_launcher_icons`

---

## 🍎 ข้อกำหนดสำหรับฝั่ง iOS & App Store

| รายการ | รายละเอียดที่ต้องเตรียม |
| :--- | :--- |
| **Apple Developer Account** | บัญชีรายปี $99 USD/ปี ของ Apple |
| **Bundle Identifier** | เปลี่ยนจาก `com.splitbill.splitBill` ใน `project.pbxproj` เป็น Reverse Domain จริงของผู้พัฒนา |
| **App Icon** | สร้างไฟล์ 1024x1024 px (**ห้ามมี Transparency/Alpha**) และรัน `flutter_launcher_icons` |
| **Permissions (`Info.plist`)** | เพิ่มคำอธิบายการใช้งาน: `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, `NSMicrophoneUsageDescription` |
| **Export Compliance** | เพิ่ม `<key>ITSAppUsesNonExemptEncryption</key><false/>` ใน `ios/Runner/Info.plist` |
| **Legal URLs** | ต้องมีหน้าเว็บสำหรับ **Privacy Policy URL** และ **Support URL** ที่เปิดดูได้จริง |
| **Hardware ในการ Build** | ต้องมีเครื่อง **macOS + Xcode** หรือใช้ **Cloud CI/CD** (เช่น Codemagic หรือ GitHub Actions) เนื่องจาก Windows ไม่สามารถ Build ไฟล์ `.ipa` สำหรับ App Store ได้โดยตรง |

---

## 🚀 คำสั่งเริ่มต้นรันโปรเจกต์ (Development & Build)

### 💻 Windows 1-Click Executable Installer (สร้างไฟล์ติดตั้ง .exe ในคลิกเดียว)

สามารถสร้างไฟล์ตัวติดตั้ง `.exe` แบบ Standalone (ขนาดเพียง ~11.4 MB รวม Flutter Engine และ DLLs ครบถ้วน) ได้ง่ายๆ:

1. **คอมไพล์ใน 1 คลิกผ่าน Batch Script**:
   ```cmd
   build_windows_exe.bat
   ```
2. **ผลลัพธ์ที่ได้**:
   - `D:\code\split_bill\SplitBill_Setup.exe` (และในโฟลเดอร์ `dist/`)
   - ดับเบิ้ลคลิกเพื่อติดตั้งและเปิดใช้งานแอปได้ทันทีใน 1 วินาที พร้อมสร้าง Desktop Shortcut อัตโนมัติ โดยไม่ต้องมีสิทธิ์ Administrator

### 🛠️ Flutter Development Commands

```bash
# ตรวจสอบการตั้งค่าและแพ็กเกจ
flutter doctor

# ดาวน์โหลด dependencies
flutter pub get

# ตรวจสอบความถูกต้องของโค้ด
flutter analyze

# รันแอปพลิเคชันบน Windows
flutter run -d windows
```
