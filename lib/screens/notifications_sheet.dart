import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/split_bill_provider.dart';
import '../theme/app_theme.dart';
import 'payment_screen.dart';
import 'voice_nudge_record_screen.dart';

class NotificationsSheet extends StatelessWidget {
  const NotificationsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SplitBillProvider>();
    final notifications = provider.notifications;
    final unreadCount = provider.unreadNotificationsCount;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        'การแจ้งเตือน',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.ink),
                      ),
                      if (unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$unreadCount ใหม่',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (notifications.isNotEmpty)
                    TextButton(
                      onPressed: () => provider.markAllNotificationsAsRead(),
                      child: const Text('อ่านทั้งหมด', style: TextStyle(fontSize: 13, color: AppColors.primary)),
                    ),
                ],
              ),
            ),
            const Divider(),

            // Notifications List
            if (notifications.isEmpty)
              Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    const Icon(Icons.notifications_off_outlined, size: 48, color: AppColors.ink3),
                    const SizedBox(height: 12),
                    const Text('ไม่มีการแจ้งเตือนในขณะนี้', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add_alert_rounded, size: 16),
                      label: const Text('จำลองแจ้งเตือนใหม่'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primarySoft,
                        foregroundColor: AppColors.primary,
                        elevation: 0,
                      ),
                      onPressed: () => provider.simulateIncomingNotification(),
                    ),
                  ],
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: notifications.length,
                  separatorBuilder: (_, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final notif = notifications[index];
                    return _buildNotificationItem(context, provider, notif);
                  },
                ),
              ),

            // Bottom Simulator Action
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.line)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.add_alert_rounded, size: 16),
                      label: const Text('จำลอง Push Notification เข้ามา'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.ink2,
                        side: const BorderSide(color: AppColors.line),
                      ),
                      onPressed: () {
                        provider.simulateIncomingNotification();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('จำลองข้อความแจ้งเตือนใหม่เข้ามาแล้ว 🔔')),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    SplitBillProvider provider,
    AppNotification notif,
  ) {
    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.danger,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => provider.clearNotification(notif.id),
      child: Material(
        color: notif.isRead ? Colors.white : AppColors.primarySoft.withValues(alpha: 0.35),
        child: InkWell(
          onTap: () {
            provider.markNotificationAsRead(notif.id);
            _handleNotificationAction(context, provider, notif);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _getBgColor(notif.type),
                  child: Text(notif.emoji, style: const TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              notif.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.bold,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                          if (!notif.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notif.message,
                        style: const TextStyle(fontSize: 12.5, color: AppColors.ink2, height: 1.35),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatTime(notif.timestamp),
                        style: const TextStyle(fontSize: 11, color: AppColors.ink3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getBgColor(NotificationType type) {
    switch (type) {
      case NotificationType.payment:
        return AppColors.successSoft;
      case NotificationType.overdue:
        return AppColors.warnSoft;
      case NotificationType.newBill:
        return AppColors.primarySoft;
      case NotificationType.system:
        return AppColors.bg;
    }
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} นาทีที่แล้ว';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} ชั่วโมงที่แล้ว';
    }
    return '${diff.inDays} วันที่แล้ว';
  }

  void _handleNotificationAction(
    BuildContext context,
    SplitBillProvider provider,
    AppNotification notif,
  ) {
    Navigator.pop(context); // Close sheet

    if (notif.relatedAction == 'nudge') {
      final nutDebt = provider.debts.firstWhere(
        (d) => d.fromMember.name == 'นัท',
        orElse: () => provider.debts.first,
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => VoiceNudgeRecordScreen(debt: nutDebt)),
      );
    } else if (notif.relatedAction == 'pay' || notif.relatedAction == 'view_payment') {
      final mint = provider.allMembers.firstWhere((m) => m.name == 'มิ้นท์');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentScreen(
            recipient: mint,
            billTitle: '🏠 ค่าเน็ตคอนโด',
            amount: 310.0,
          ),
        ),
      );
    }
  }
}
