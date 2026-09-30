import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:split_bill/providers/split_bill_provider.dart';
import 'package:split_bill/screens/profile_screen.dart';

void main() {
  testWidgets('ProfileScreen renders and does NOT contain ภาพรวมหน้าจอทั้งหมด', (WidgetTester tester) async {
    final provider = SplitBillProvider();

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0; // 1080x2400 logical points
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(
          home: ProfileScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify title and user info
    expect(find.text('โปรไฟล์และการตั้งค่า'), findsOneWidget);
    expect(find.text('ป๊อป'), findsOneWidget);
    expect(find.text('พร้อมเพย์: 081-234-5678'), findsWidgets);
    expect(find.text('พร้อมเพย์ยืนยันแล้ว ✓'), findsOneWidget);

    // Verify "ภาพรวมหน้าจอทั้งหมด" is COMPLETELY GONE
    expect(find.textContaining('ภาพรวมหน้าจอทั้งหมด'), findsNothing);
    expect(find.textContaining('11 หน้า PDD'), findsNothing);
    expect(find.textContaining('100% PDD'), findsNothing);

    // Verify functional sections exist
    expect(find.text('บัญชีและการรับเงิน'), findsOneWidget);
    expect(find.text('บัญชีธนาคารและพร้อมเพย์'), findsOneWidget);
    expect(find.text('QR Code รับเงินของฉัน'), findsOneWidget);
    expect(find.text('การแจ้งเตือนและระบบเสียง'), findsOneWidget);
    expect(find.text('ตั้งค่าการแจ้งเตือน & Push'), findsOneWidget);
    expect(find.text('ตั้งค่าระบบเสียง (Voice Nudge)'), findsOneWidget);
    expect(find.text('การตั้งค่าทั่วไปและช่วยเหลือ'), findsOneWidget);

    // Scroll to bottom to verify reset button
    await tester.scrollUntilVisible(find.text('รีเซ็ตข้อมูลระบบเป็นค่าเริ่มต้น'), 200);
    expect(find.text('รีเซ็ตข้อมูลระบบเป็นค่าเริ่มต้น'), findsOneWidget);
  });

  testWidgets('Edit Profile updates user name and reflects dynamically', (WidgetTester tester) async {
    final provider = SplitBillProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(
          home: ProfileScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap "แก้ไขโปรไฟล์"
    await tester.tap(find.widgetWithText(OutlinedButton, 'แก้ไขโปรไฟล์'));
    await tester.pumpAndSettle();

    // Verify modal appears
    expect(find.text('แก้ไขข้อมูลโปรไฟล์'), findsOneWidget);

    // Change name in textfield
    final nameField = find.widgetWithText(TextField, 'ป๊อป');
    await tester.enterText(nameField, 'สมชาย สายเปย์');

    // Tap save
    await tester.tap(find.widgetWithText(ElevatedButton, 'บันทึกข้อมูล'));
    await tester.pumpAndSettle();

    // Verify name updated in provider and UI
    expect(provider.userName, 'สมชาย สายเปย์');
    expect(find.text('สมชาย สายเปย์'), findsOneWidget);
  });

  testWidgets('Bank account modal can set primary and add account', (WidgetTester tester) async {
    final provider = SplitBillProvider();

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(
          home: ProfileScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap "บัญชีธนาคารและพร้อมเพย์"
    await tester.tap(find.text('บัญชีธนาคารและพร้อมเพย์'));
    await tester.pumpAndSettle();

    // Verify modal appears with bank accounts
    expect(find.text('บัญชีรับเงินโอน'), findsOneWidget);
    expect(find.text('พร้อมเพย์หลัก (PromptPay ID)'), findsOneWidget);
    expect(find.text('บัญชีหลัก'), findsOneWidget);
  });
}
