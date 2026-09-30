import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:split_bill/models/models.dart';
import 'package:split_bill/providers/split_bill_provider.dart';
import 'package:split_bill/utils/date_formatter.dart';

void main() {
  group('DateFormatter Tests', () {
    test('formats Thai Buddhist era date correctly', () {
      final date = DateTime(2026, 9, 9, 14, 30);
      expect(DateFormatter.formatThaiDate(date), '9 ก.ย. 69');
      expect(DateFormatter.formatThaiDate(date, includeTime: true), '9 ก.ย. 69 (14:30 น.)');
      expect(DateFormatter.formatThaiDateFull(date), '9 กันยายน 2569');
    });

    test('formats currency with commas and 2 decimals', () {
      expect(DateFormatter.formatCurrency(1250.5), '1,250.50');
      expect(DateFormatter.formatCurrency(0), '0.00');
    });
  });

  group('Bill Creation & Calculation Tests', () {
    late SplitBillProvider provider;

    setUp(() {
      provider = SplitBillProvider();
    });

    test('Blank Bill Creation creates an empty bill from scratch', () {
      provider.createBlankBill(title: 'มื้อเที่ยงสยาม', categoryEmoji: '🍜');
      final bill = provider.currentDraftBill;

      expect(bill, isNotNull);
      expect(bill!.title, 'มื้อเที่ยงสยาม');
      expect(bill.categoryEmoji, '🍜');
      expect(bill.items, isEmpty);
      expect(bill.subtotal, 0.0);
      expect(bill.grandTotal, 0.0);

      // Add items
      provider.addBillItem('ก๋วยเตี๋ยวเรือ', 60.0, 2); // 120.0
      provider.addBillItem('เกี๊ยวทอด', 40.0, 1); // 40.0
      expect(bill.items.length, 2);
      expect(bill.subtotal, 160.0);

      // Update VAT, service charge, discount
      provider.updateDraftBillInfo(vatPercent: 7.0, serviceChargePercent: 10.0, discountAmount: 10.0);
      // Subtotal: 160.0
      // Discount: 10.0
      // VAT (7% of 150): 10.50
      // Service (10% of 160): 16.0
      // Grand total: 150 + 10.50 + 16.0 = 176.50
      expect(bill.subtotal, 160.0);
      expect(bill.discountAmount, 10.0);
      expect(bill.vatAmount, closeTo(10.50, 0.001));
      expect(bill.serviceChargeAmount, closeTo(16.0, 0.001));
      expect(bill.grandTotal, closeTo(176.50, 0.001));
    });

    test('Dynamic Participants allows arbitrary number of members and adding new friends', () {
      provider.createBlankBill(title: 'ปาร์ตี้หมูกระทะ');
      expect(provider.allMembers.length, 5);

      // Add 6th member dynamically
      final newFriend = provider.addNewMember(
        name: 'จูน',
        avatarEmoji: '🌸',
        avatarColor: const Color(0xFFF43F5E),
      );
      expect(provider.allMembers.length, 6);
      expect(provider.allMembers.last.name, 'จูน');

      // Select 3 specific participants out of 6
      provider.setDraftBillParticipants([
        provider.currentUser.id,
        'm_beer',
        newFriend.id,
      ]);

      final participants = provider.getDraftBillParticipants();
      expect(participants.length, 3);
      expect(participants.any((m) => m.id == newFriend.id), isTrue);
    });

    test('Penny Rounding Strategy - Equal Mode with 100 THB / 3 people', () {
      provider.createBlankBill(title: 'ทดสอบปัดเศษ 100 บาท 3 คน');
      provider.addBillItem('อาหารรวม', 100.0, 1);
      provider.updateDraftBillInfo(vatPercent: 0, serviceChargePercent: 0, discountAmount: 0);

      // Set exactly 3 participants: Payer (m_pop), Beer (m_beer), Nut (m_nut)
      provider.setDraftBillParticipants(['m_pop', 'm_beer', 'm_nut']);
      final bill = provider.currentDraftBill!;
      expect(bill.grandTotal, 100.0);

      // Strategy 1: Payer absorbs remaining 1 satang
      provider.setRoundingStrategy(RoundingStrategy.payerAbsorbs);
      var shares = provider.calculateMemberShares();
      expect(shares['m_beer'], 33.33);
      expect(shares['m_nut'], 33.33);
      expect(shares['m_pop'], 33.34); // Payer absorbed +0.01
      var totalShares = shares.values.fold(0.0, (a, b) => a + b);
      expect(totalShares, closeTo(100.0, 0.001));

      // Strategy 2: Distribute evenly (first person pays +0.01)
      provider.setRoundingStrategy(RoundingStrategy.distributeEvenly);
      shares = provider.calculateMemberShares();
      totalShares = shares.values.fold(0.0, (a, b) => a + b);
      expect(totalShares, closeTo(100.0, 0.001));
      expect(shares.values.where((v) => v == 33.34).length, 1);
      expect(shares.values.where((v) => v == 33.33).length, 2);

      // Strategy 3: Round to whole Baht
      provider.setRoundingStrategy(RoundingStrategy.roundToBaht);
      shares = provider.calculateMemberShares();
      totalShares = shares.values.fold(0.0, (a, b) => a + b);
      expect(totalShares, 100.0);
      expect(shares['m_beer'], 33.0);
      expect(shares['m_nut'], 33.0);
      expect(shares['m_pop'], 34.0); // Payer absorbed +1 Baht
    });

    test('Penny Rounding Strategy - Itemized Mode calculates shares accurately matching grandTotal', () {
      provider.createBlankBill(title: 'หารตามจริง');
      provider.setDraftBillParticipants(['m_pop', 'm_beer', 'm_nut']);

      // Item 1: 150 THB shared by pop & beer (75 each)
      provider.addBillItem('ส้มตำ', 150.0, 1);
      final item1 = provider.currentDraftBill!.items[0];
      provider.setItemAssignedMembers(item1.id, ['m_pop', 'm_beer']);

      // Item 2: 200 THB shared by nut only (200)
      provider.addBillItem('ลาบเป็ด', 200.0, 1);
      final item2 = provider.currentDraftBill!.items[1];
      provider.setItemAssignedMembers(item2.id, ['m_nut']);

      provider.setSplitMode(SplitMode.itemized);
      provider.updateDraftBillInfo(vatPercent: 7.0, serviceChargePercent: 10.0);

      final bill = provider.currentDraftBill!;
      final shares = provider.calculateMemberShares();
      final totalShares = shares.values.fold(0.0, (a, b) => a + b);

      expect(totalShares, closeTo(bill.grandTotal, 0.001));
      expect(shares['m_pop']! > 0, isTrue);
      expect(shares['m_beer']! > 0, isTrue);
      expect(shares['m_nut']! > 0, isTrue);
    });

    test('Bill save and duplication work smoothly with savedBills history', () {
      provider.createBlankBill(title: 'มื้อพิเศษกับครอบครัว');
      provider.addBillItem('สเต๊กเนื้อ', 450.0, 1);
      provider.saveCurrentBill();

      expect(provider.savedBills.isNotEmpty, isTrue);
      expect(provider.savedBills.first.title, 'มื้อพิเศษกับครอบครัว');

      // Duplicate latest bill
      provider.duplicateLatestBill();
      expect(provider.currentDraftBill!.title, 'มื้อพิเศษกับครอบครัว (ทำซ้ำ)');
      expect(provider.currentDraftBill!.items.length, 1);
      expect(provider.currentDraftBill!.items.first.price, 450.0);
    });
  });
}
