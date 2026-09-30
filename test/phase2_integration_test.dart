import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:split_bill/models/models.dart';
import 'package:split_bill/providers/split_bill_provider.dart';
import 'package:split_bill/screens/voice_nudge_ai_screen.dart';
import 'package:split_bill/screens/voice_nudge_record_screen.dart';
import 'package:split_bill/screens/voice_receiver_screen.dart';
import 'package:split_bill/services/gemini_service.dart';
import 'package:split_bill/services/tts_service.dart';
import 'package:split_bill/widgets/voice_nudge_share_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testDebt = DebtRecord(
    id: 'debt_test',
    fromMember: const Member(
      id: 'm_nut',
      name: 'นัท',
      avatarEmoji: '🟡',
      avatarColor: Color(0xFFF59E0B),
      promptPayNumber: '0812345678',
    ),
    toMember: const Member(
      id: 'm_pop',
      name: 'ป๊อป',
      avatarEmoji: '🔵',
      avatarColor: Color(0xFF3B82F6),
      promptPayNumber: '0898765432',
    ),
    amount: 250.0,
    billTitle: 'ค่าหมูกระทะ',
    daysOverdue: 3,
    isSettled: false,
  );

  group('GeminiService Tests', () {
    test('Fallback script generation returns valid Thai script according to persona', () async {
      final gemini = GeminiService(apiKey: 'dummy_key');
      final script = await gemini.generateVoiceScript(
        recipientName: 'นัท',
        billTitle: 'ค่าหมูกระทะ',
        amount: 250.0,
        persona: 'เพื่อนซี้',
        ladder: EscalationLadder.normal,
        style: 'joke',
      );

      expect(script, isNotEmpty);
      expect(script.contains('นัท'), isTrue);
      expect(script.length, lessThanOrEqualTo(120));
    });

    test('GeminiService handles all personas and ladders in fallback mode', () async {
      final gemini = GeminiService(apiKey: 'dummy_key');
      for (final persona in ['น้องนุ่ม', 'เพื่อนซี้', 'หุ่นยนต์', 'คุณยาย', 'ผู้ประกาศ']) {
        final script = await gemini.generateVoiceScript(
          recipientName: 'นัท',
          billTitle: 'หมูกระทะ',
          amount: 250,
          persona: persona,
          ladder: EscalationLadder.gentle,
          style: 'ai',
        );
        expect(script, isNotEmpty);
        expect(script.contains('นัท'), isTrue);
      }
    });
  });

  group('TtsService Tests', () {
    test('Voice mapping has correct ElevenLabs voices for personas', () {
      expect(TtsService.elevenLabsVoices['น้องนุ่ม'], 'EXAVITQu4vr4xnSDxMaL');
      expect(TtsService.elevenLabsVoices['เพื่อนซี้'], 'FGY2WhTYpPnrIDTdsKH5');
      expect(TtsService.elevenLabsVoices['หุ่นยนต์'], 'IKne3meq5aSn9XLyUdCD');
      expect(TtsService.elevenLabsVoices['คุณยาย'], 'JBFqnCBsd6RMkjVDRZzb');
      expect(TtsService.elevenLabsVoices['ผู้ประกาศ'], 'CwhRBWXzGAHq8TQ4Fs17');
    });

    test('TtsService instance and state', () {
      final tts = TtsService();
      expect(tts.isPlaying, isFalse);
    });
  });

  group('Phase 2 UI Integration Tests', () {
    testWidgets('VoiceNudgeAiScreen renders personas, ladder, chips and preview button', (tester) async {
      final provider = SplitBillProvider();

      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: MaterialApp(
            home: VoiceNudgeAiScreen(debt: testDebt),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check personas
      expect(find.text('น้องนุ่ม'), findsWidgets);
      expect(find.text('เพื่อนซี้'), findsOneWidget);
      expect(find.text('หุ่นยนต์'), findsOneWidget);
      expect(find.text('คุณยาย'), findsOneWidget);
      expect(find.text('ผู้ประกาศ'), findsOneWidget);

      // Check AI chips
      expect(find.text('AI ช่วยเขียน'), findsOneWidget);
      expect(find.text('ใส่มุก'), findsOneWidget);
      expect(find.text('สุภาพขึ้น'), findsOneWidget);

      // Check ladder options
      expect(find.text('🟢 สะกิดเบา ๆ'), findsOneWidget);
      expect(find.text('🟡 เตือนปกติ'), findsOneWidget);
      expect(find.text('🟠 จริงจัง'), findsOneWidget);
      expect(find.text('🔴 โหมดประชด 🔥 (ล็อก)'), findsOneWidget);

      // Check preview voice button
      expect(find.textContaining('ลองฟังเสียง AI'), findsOneWidget);

      // Tap an AI chip (ใส่มุก)
      await tester.tap(find.text('ใส่มุก'));
      await tester.pumpAndSettle();

      // Tap persona (เพื่อนซี้)
      await tester.tap(find.text('เพื่อนซี้'));
      await tester.pumpAndSettle();

      // Tap ladder (เตือนปกติ)
      await tester.tap(find.text('🟡 เตือนปกติ'));
      await tester.pumpAndSettle();

      // Verify submit button
      final submitBtn = find.textContaining('สร้างและส่งเสียงทวง AI');
      expect(submitBtn, findsOneWidget);
    });

    testWidgets('VoiceNudgeRecordScreen renders mic, timer, waveform, effects', (tester) async {
      final provider = SplitBillProvider();

      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: MaterialApp(
            home: VoiceNudgeRecordScreen(debt: testDebt),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check target info
      expect(find.text('ทวง นัท'), findsOneWidget);
      expect(find.text('฿250.00'), findsOneWidget);

      // Check effects
      expect(find.text('ปกติ'), findsOneWidget);
      expect(find.text('🐿ชิพมังก์'), findsOneWidget);
      expect(find.text('🎩ทุ้มลึก'), findsOneWidget);
      expect(find.text('📻วิทยุเก่า'), findsOneWidget);
      expect(find.text('🎪ห้องโถง'), findsOneWidget);

      // Check Action Buttons
      expect(find.text('ฟังตัวอย่าง'), findsOneWidget);
      expect(find.text('ส่งเสียงทวง 🔊'), findsOneWidget);
    });

    testWidgets('VoiceReceiverScreen renders transcript, waveform, quick replies', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: VoiceReceiverScreen(
            senderName: 'ป๊อป',
            billTitle: 'ค่าหมูกระทะ',
            amount: 250.0,
            transcript: 'สวัสดีนัทจ๋า โอนค่าหมูกระทะ 250 บาทให้เค้าด้วยน้า',
            durationSeconds: 8,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check sender and amount
      expect(find.text('ป๊อป ส่งเสียงทวง'), findsOneWidget);
      expect(find.text('฿250.00'), findsOneWidget);
      expect(find.text('จ่ายเลย'), findsOneWidget);

      // Check transcript
      expect(find.text('ถอดข้อความอัตโนมัติ (Transcript)'), findsOneWidget);
      expect(find.text('"สวัสดีนัทจ๋า โอนค่าหมูกระทะ 250 บาทให้เค้าด้วยน้า"'), findsOneWidget);

      // Check quick replies
      expect(find.text('💸 โอนแล้ว'), findsOneWidget);
      expect(find.text('⏰ ขอ 3 วัน'), findsOneWidget);
      expect(find.text('😅 ลืมสนิท ขอโทษที'), findsOneWidget);

      // Check settings switches
      expect(find.text('รับข้อความเสียง'), findsOneWidget);
      expect(find.text('ห้ามรบกวน 22:00–08:00'), findsOneWidget);
      expect(find.text('เล่นเสียงอัตโนมัติ'), findsOneWidget);

      // Tap quick reply
      await tester.tap(find.text('💸 โอนแล้ว'));
      await tester.pump();
      expect(find.text('ส่งข้อความ "โอนแล้ว" ไปยังเพื่อนเรียบร้อย'), findsOneWidget);
    });

    testWidgets('VoiceReceiverScreen preview mode shows banner and share action', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: VoiceReceiverScreen(
            senderName: 'ป๊อป',
            billTitle: 'ค่าหมูกระทะ',
            amount: 250.0,
            transcript: 'สวัสดีนัทจ๋า โอนค่าหมูกระทะ 250 บาทให้เค้าด้วยน้า',
            durationSeconds: 8,
            isPreview: true,
            promptPayNumber: '081-234-5678',
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('ตัวอย่างหน้าจอฝั่งเพื่อน'), findsOneWidget);
      expect(find.text('คุณกำลังดูตัวอย่างหน้าจอที่เพื่อนจะเห็น (Receiver View)'), findsOneWidget);
      expect(find.text('แชร์เลย'), findsOneWidget);
      expect(find.byIcon(Icons.share_rounded), findsWidgets);
    });

    testWidgets('VoiceNudgeShareModal displays target, bill details, and share options', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  showVoiceNudgeShareModal(
                    context: ctx,
                    targetName: 'นัท',
                    billTitle: 'ค่าหมูกระทะ',
                    amount: 250.0,
                    transcript: 'อย่าลืมโอนน้า',
                    durationSeconds: 6,
                    audioPath: null,
                    persona: 'น้องนุ่ม',
                    nudgeId: 'test_nudge_123',
                    promptPayNumber: '081-234-5678',
                    senderName: 'ป๊อป',
                  );
                },
                child: const Text('Open Modal'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.text('สร้างเสียงทวงเงินสำเร็จแล้ว!'), findsOneWidget);
      expect(find.text('ค่าหมูกระทะ'), findsOneWidget);
      expect(find.text('฿250.00'), findsOneWidget);
      expect(find.text('PromptPay: 081-234-5678'), findsOneWidget);
      expect(find.text('แชร์ให้ นัท (LINE / แชท) ↗'), findsOneWidget);
      expect(find.text('คัดลอกข้อความทวงเงิน + ยอดบัญชี 📋'), findsOneWidget);
      expect(find.text('ดูตัวอย่างหน้าจอที่เพื่อนจะเห็น (Receiver Preview)'), findsOneWidget);
    });
  });
}
