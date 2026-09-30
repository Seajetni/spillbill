import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/split_bill_provider.dart';
import '../theme/app_theme.dart';
import '../utils/date_formatter.dart';
import 'zero_install_landing_screen.dart';

class BillSummaryScreen extends StatelessWidget {
  const BillSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SplitBillProvider>();
    final bill = provider.currentDraftBill;

    if (bill == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('สรุปบิล')),
        body: const Center(child: Text('ไม่พบบิล')),
      );
    }

    final shares = provider.calculateMemberShares();
    final participants = provider.getDraftBillParticipants();
    final payer = provider.allMembers.firstWhere(
      (m) => m.id == bill.paidByMemberId,
      orElse: () => provider.currentUser,
    );

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('สรุปบิล'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // Hero Summary Card
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.xlBorder,
              border: Border.all(color: AppColors.line),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(bill.categoryEmoji, style: const TextStyle(fontSize: 40)),
                const SizedBox(height: 8),
                Text(
                  '${bill.title} · ${DateFormatter.formatThaiDate(bill.date)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink),
                ),
                const SizedBox(height: 8),
                Text(
                  '฿${bill.grandTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '👥 ${participants.length} คน · ${bill.groupName}',
                    style: const TextStyle(fontSize: 12.5, color: AppColors.ink2),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // "ใครจ่ายเท่าไหร่" Header
          const Text(
            'ใครจ่ายเท่าไหร่',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.ink),
          ),
          const SizedBox(height: 12),

          // Payer card
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: AppRadius.mdBorder,
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: payer.avatarColor.withValues(alpha: 0.2),
                  child: Text(payer.avatarEmoji, style: const TextStyle(fontSize: 16)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${payer.name} · ${payer.isCurrentUser ? "คุณจ่ายไปก่อน" : "คนสำรองจ่าย"}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary),
                      ),
                      Text(
                        payer.isCurrentUser ? 'สำรองจ่ายทั้งบิล' : 'สำรองจ่ายให้ทุกคนในบิลนี้',
                        style: const TextStyle(fontSize: 12.5, color: AppColors.ink2),
                      ),
                    ],
                  ),
                ),
                Text(
                  '฿${bill.grandTotal.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
          ),

          // Other Participating Members
          ...participants.where((m) => m.id != payer.id).map((m) {
            final share = shares[m.id] ?? 0.0;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.mdBorder,
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: m.avatarColor.withValues(alpha: 0.15),
                    child: Text(m.avatarEmoji, style: const TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.isCurrentUser ? '${m.name} (คุณ)' : m.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.ink),
                        ),
                        Text(
                          bill.splitMode == SplitMode.equal
                              ? 'หารเท่า (${participants.length} คน)'
                              : _getMemberItemsDescription(bill, m.id),
                          style: const TextStyle(fontSize: 12, color: AppColors.ink3),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '฿${share.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: m.isCurrentUser ? AppColors.danger : AppColors.ink,
                        ),
                      ),
                      Text(
                        m.isCurrentUser ? 'ต้องโอนให้ ${payer.name}' : 'ต้องโอนคืน',
                        style: const TextStyle(fontSize: 11, color: AppColors.ink3),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 8),

          // Penny Rounding Strategy & Summary Note
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: AppRadius.mdBorder,
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🎯', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bill.roundingStrategy == RoundingStrategy.roundToBaht
                            ? 'ระบบปัดเศษสตางค์: ปัดเป็นจำนวนเต็มบาท'
                            : bill.roundingStrategy == RoundingStrategy.distributeEvenly
                                ? 'ระบบปัดเศษสตางค์: กระจายเศษ 1 สตางค์'
                                : 'ระบบปัดเศษสตางค์: คนสำรองจ่ายรับเศษ (${payer.name})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF166534)),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        bill.roundingStrategy == RoundingStrategy.roundToBaht
                            ? 'ยอดทุกคนรวมกันเท่ากับ ฿${shares.values.fold(0.0, (a, b) => a + b).toStringAsFixed(0)} บาทถ้วน โอนเงินสะดวก ไม่มีเศษสตางค์'
                            : 'คำนวณยอดเงินแม่นยำระดับสตางค์ ยอดรวมของทุกคนเท่ากับ ฿${shares.values.fold(0.0, (a, b) => a + b).toStringAsFixed(2)} ตรงกับยอดบิล ฿${bill.grandTotal.toStringAsFixed(2)} พอดีเป๊ะ 100% ไม่มีเศษสตางค์ตกหล่น',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF15803D)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 52),
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
                    side: const BorderSide(color: AppColors.line),
                  ),
                  onPressed: () {
                    provider.saveCurrentBill();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('บันทึกบิลเรียบร้อยแล้ว 🎉')),
                    );
                    Navigator.popUntil(context, (r) => r.isFirst);
                  },
                  child: const Text('บันทึก', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 52),
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
                  ),
                  onPressed: () {
                    provider.saveCurrentBill();
                    final firstOwerShare = shares.entries
                        .where((e) => e.key != payer.id && e.value > 0)
                        .map((e) => e.value)
                        .firstOrNull ?? (bill.grandTotal / (participants.isNotEmpty ? participants.length : 1));
                    final billToken = bill.id.replaceAll('b_', '').length >= 6
                        ? bill.id.replaceAll('b_', '').substring(0, 6)
                        : 'a7Kf9x';

                    // Open Zero-Install Landing page simulator (Screen 11)
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ZeroInstallLandingScreen(
                          payerName: payer.name,
                          billTitle: bill.title,
                          amount: firstOwerShare,
                          token: billToken,
                        ),
                      ),
                    );
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send_rounded, size: 16),
                      SizedBox(width: 6),
                      Text('ส่งลิงก์เก็บเงิน', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMemberItemsDescription(Bill bill, String memberId) {
    final names = <String>[];
    for (var it in bill.items) {
      if (it.assignedMemberIds.contains(memberId)) {
        names.add(it.name);
      }
    }
    if (names.isEmpty) return 'ไม่มีรายการ';
    return names.join(', ');
  }
}
