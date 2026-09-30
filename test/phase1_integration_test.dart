import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:split_bill/models/models.dart';
import 'package:split_bill/providers/split_bill_provider.dart';
import 'package:split_bill/screens/payment_screen.dart';
import 'package:split_bill/screens/statistics_screen.dart';

void main() {
  group('Phase 1 Integration Tests', () {
    testWidgets('PaymentScreen displays creditor promptpay, QR, and actions', (tester) async {
      final provider = SplitBillProvider();
      const testRecipient = Member(
        id: 'm_beer',
        name: 'เบียร์',
        avatarEmoji: '🟢',
        avatarColor: Color(0xFF0FBF7F),
        promptPayNumber: '0891112233',
        bankName: 'ธนาคารกสิกรไทย',
      );

      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(
            home: PaymentScreen(
              recipient: testRecipient,
              billTitle: 'หมูกระทะ ศุกร์',
              amount: 245.50,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check recipient and bill information
      expect(find.text('เบียร์ ขอเก็บค่า'), findsOneWidget);
      expect(find.text('หมูกระทะ ศุกร์'), findsOneWidget);
      expect(find.text('฿245.50'), findsWidgets);
      expect(find.textContaining('0891112233 (เบียร์)'), findsOneWidget);

      // Check action buttons
      expect(find.text('บันทึก QR'), findsOneWidget);
      expect(find.text('เปิดแอปธนาคาร'), findsOneWidget);
      expect(find.text('📎 แนบสลิปยืนยันการโอนเงิน'), findsOneWidget);
    });

    testWidgets('StatisticsScreen renders dynamic categories and export sheet', (tester) async {
      final provider = SplitBillProvider();

      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(
            home: StatisticsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify title and categories
      expect(find.text('สถิติการใช้จ่าย'), findsOneWidget);
      expect(find.text('อาหาร & เครื่องดื่ม'), findsOneWidget);
      expect(find.text('ที่พัก & ค่าเช่า'), findsOneWidget);
      expect(find.text('เดินทาง'), findsOneWidget);

      // Tap export button to open export sheet
      final exportBtn = find.byIcon(Icons.download_rounded);
      expect(exportBtn, findsOneWidget);
      await tester.tap(exportBtn);
      await tester.pumpAndSettle();

      // Verify export options in bottom sheet
      expect(find.text('ส่งออกรายงานค่าใช้จ่าย (Export)'), findsOneWidget);
      expect(find.text('Export CSV (Excel)'), findsOneWidget);
      expect(find.text('Export PDF Report'), findsOneWidget);
    });
  });
}
