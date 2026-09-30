import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/split_bill_provider.dart';
import '../theme/app_theme.dart';
import 'payment_screen.dart';
import 'voice_nudge_record_screen.dart';
import 'notifications_sheet.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SplitBillProvider>();
    final net = provider.netBalance;
    final toReceive = provider.toReceiveAmount;
    final toPay = provider.toPayAmount;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'สวัสดีตอนบ่าย',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.ink3,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${provider.currentUser.name} ${provider.currentUser.avatarEmoji}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: AppColors.ink, size: 26),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const NotificationsSheet(),
                  );
                },
              ),
              if (provider.unreadNotificationsCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${provider.unreadNotificationsCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => await Future.delayed(const Duration(milliseconds: 500)),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Net Balance Card (PDD Section E Screen 1)
              _buildHeroNetBalanceCard(context, provider, net, toReceive, toPay),
              const SizedBox(height: 24),

              // Action List: "ต้องจัดการ"
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ต้องจัดการ',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                    ),
                  ),
                  if (provider.homeFilter != 'all')
                    TextButton(
                      onPressed: () => provider.setHomeFilter('all'),
                      child: const Text(
                        'ดูทั้งหมด',
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                      ),
                    )
                  else
                    const Text(
                      '3 รายการ',
                      style: TextStyle(color: AppColors.ink3, fontSize: 13),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              _buildActionList(context, provider),

              const SizedBox(height: 24),

              // Recent Activities: "กิจกรรมล่าสุด"
              const Text(
                'กิจกรรมล่าสุด',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 12),
              _buildRecentActivities(provider),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroNetBalanceCard(
    BuildContext context,
    SplitBillProvider provider,
    double net,
    double toReceive,
    double toPay,
  ) {
    final isPositive = net >= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2D6BFF), Color(0xFF1447D1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.xlBorder,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D6BFF).withValues(alpha: 0.35),
            offset: const Offset(0, 10),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ยอดสุทธิของคุณ',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${isPositive ? '+' : '-'} ฿${net.abs().toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: AppRadius.mdBorder,
            ),
            child: Row(
              children: [
                // "จะได้รับ" Pill
                Expanded(
                  child: InkWell(
                    onTap: () {
                      provider.setHomeFilter(provider.homeFilter == 'receive' ? 'all' : 'receive');
                    },
                    borderRadius: AppRadius.mdBorder,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      decoration: BoxDecoration(
                        color: provider.homeFilter == 'receive'
                            ? Colors.white.withValues(alpha: 0.25)
                            : Colors.transparent,
                        borderRadius: AppRadius.mdBorder,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF0FBF7F),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'จะได้รับ',
                                style: TextStyle(color: Colors.white70, fontSize: 12.5),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '฿${toReceive.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(width: 1, height: 35, color: Colors.white24),
                // "ต้องจ่าย" Pill
                Expanded(
                  child: InkWell(
                    onTap: () {
                      provider.setHomeFilter(provider.homeFilter == 'pay' ? 'all' : 'pay');
                    },
                    borderRadius: AppRadius.mdBorder,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      decoration: BoxDecoration(
                        color: provider.homeFilter == 'pay'
                            ? Colors.white.withValues(alpha: 0.25)
                            : Colors.transparent,
                        borderRadius: AppRadius.mdBorder,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF8A3D),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'ต้องจ่าย',
                                style: TextStyle(color: Colors.white70, fontSize: 12.5),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '฿${toPay.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionList(BuildContext context, SplitBillProvider provider) {
    final filtered = provider.filteredDebts;

    if (filtered.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.mdBorder,
          border: Border.all(color: AppColors.line),
        ),
        child: const Center(
          child: Column(
            children: [
              Text('🎉', style: TextStyle(fontSize: 32)),
              SizedBox(height: 8),
              Text(
                'ไม่มีรายการค้างชำระ!',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink),
              ),
              Text(
                'เคลียร์หนี้หมดเรียบร้อยแล้ว',
                style: TextStyle(fontSize: 13, color: AppColors.ink3),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: filtered.map((debt) {
        final isOwedToMe = debt.toMember.id == provider.currentUser.id;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppRadius.mdBorder,
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isOwedToMe ? AppColors.successSoft : AppColors.warnSoft,
                  borderRadius: AppRadius.smBorder,
                ),
                child: Center(
                  child: Text(
                    debt.fromMember.avatarEmoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      debt.billTitle,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isOwedToMe
                          ? '${debt.fromMember.name} ติดคุณ · ${debt.daysOverdue > 0 ? "เกิน ${debt.daysOverdue} วัน" : "เร็วๆ นี้"}'
                          : 'คุณติด ${debt.toMember.name} · ครบกำหนดพรุ่งนี้',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: debt.daysOverdue >= 3 ? AppColors.danger : AppColors.ink2,
                        fontWeight: debt.daysOverdue >= 3 ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isOwedToMe ? "+" : "-"}฿${debt.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isOwedToMe ? AppColors.success : AppColors.warn,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (isOwedToMe && debt.daysOverdue >= 3)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primarySoft,
                        foregroundColor: AppColors.primary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        // Open Voice Nudge Screen (Screen 8)
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VoiceNudgeRecordScreen(debt: debt),
                          ),
                        );
                      },
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('สะกิด 👉', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  else if (!isOwedToMe)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        // Open Payment Screen (Screen 5)
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PaymentScreen(
                              recipient: debt.toMember,
                              billTitle: debt.billTitle,
                              amount: debt.amount,
                              debtId: debt.id,
                            ),
                          ),
                        );
                      },
                      child: const Text('จ่ายเงิน', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    )
                  else
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VoiceNudgeRecordScreen(debt: debt),
                          ),
                        );
                      },
                      child: const Text(
                        'ทวงเงิน',
                        style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentActivities(SplitBillProvider provider) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.mdBorder,
        side: const BorderSide(color: AppColors.line),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: provider.activities.length,
        separatorBuilder: (_, index) => const Divider(),
        itemBuilder: (context, index) {
          final act = provider.activities[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: CircleAvatar(
              backgroundColor: AppColors.bg,
              child: Text(act.emoji, style: const TextStyle(fontSize: 18)),
            ),
            title: Text(
              act.title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),
            ),
            subtitle: Text(
              act.subtitle,
              style: const TextStyle(fontSize: 12, color: AppColors.ink3),
            ),
            trailing: act.amount != null
                ? Text(
                    '${act.amount! > 0 ? "+" : ""}฿${act.amount!.abs().toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: act.amount! > 0 ? AppColors.success : AppColors.warn,
                    ),
                  )
                : const Text('—', style: TextStyle(color: AppColors.ink3)),
          );
        },
      ),
    );
  }
}
