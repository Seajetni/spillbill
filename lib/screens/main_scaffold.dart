import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/split_bill_provider.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'groups_screen.dart';
import 'statistics_screen.dart';
import 'profile_screen.dart';
import 'ocr_review_screen.dart';
import 'manual_bill_entry_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    HomeScreen(),
    GroupsScreen(),
    StatisticsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        elevation: 4,
        backgroundColor: AppColors.primary,
        shape: const CircleBorder(),
        onPressed: () => _showAddBillActionSheet(context),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: Colors.white,
        elevation: 8,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                _navItem(icon: Icons.home_filled, label: 'หน้าแรก', index: 0),
                const SizedBox(width: 8),
                _navItem(icon: Icons.group_rounded, label: 'กลุ่ม', index: 1),
              ],
            ),
            const SizedBox(width: 48), // Gap for docked center FAB
            Row(
              children: [
                _navItem(icon: Icons.bar_chart_rounded, label: 'สถิติ', index: 2),
                const SizedBox(width: 8),
                _navItem(icon: Icons.person_rounded, label: 'โปรไฟล์', index: 3),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem({required IconData icon, required String label, required int index}) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? AppColors.primary : AppColors.ink3,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.ink3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddBillActionSheet(BuildContext context) {
    final provider = context.read<SplitBillProvider>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'เพิ่มบิลใหม่ (Add Bill)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.ink),
              ),
              const SizedBox(height: 6),
              const Text(
                'เลือกวิธีนำเข้าข้อมูลบิลและรายการอาหาร',
                style: TextStyle(fontSize: 13, color: AppColors.ink3),
              ),
              const SizedBox(height: 20),

              // Option 1: 📷 OCR Scan
              _actionTile(
                icon: Icons.document_scanner_rounded,
                iconBg: AppColors.primarySoft,
                iconColor: AppColors.primary,
                title: '📷 สแกนใบเสร็จ (AI OCR)',
                subtitle: 'ตรวจจับขอบ ถ่ายรูป อ่านรายการและยอดเงินอัตโนมัติ',
                badge: 'แนะนำ ⭐',
                badgeColor: AppColors.primary,
                onTap: () {
                  Navigator.pop(ctx);
                  provider.initDraftBillFromOcr();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const OcrReviewScreen(startInCameraMode: true),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              // Option 2: ✍️ Manual Input
              _actionTile(
                icon: Icons.edit_note_rounded,
                iconBg: AppColors.successSoft,
                iconColor: AppColors.success,
                title: '✍️ กรอกเอง (Manual Entry)',
                subtitle: 'พิมพ์ชื่อบิล เพิ่มรายการอาหาร และคำนวณภาษีเอง',
                onTap: () {
                  Navigator.pop(ctx);
                  provider.createBlankBill();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ManualBillEntryScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              // Option 3: 🔁 Duplicate Bill
              _actionTile(
                icon: Icons.repeat_rounded,
                iconBg: AppColors.warnSoft,
                iconColor: AppColors.warn,
                title: '🔁 ทำซ้ำจากบิลเดิม',
                subtitle: 'คัดลอกรายการจากมื้อก่อนหน้าเพื่อประหยัดเวลา',
                onTap: () {
                  Navigator.pop(ctx);
                  provider.duplicateLatestBill();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ManualBillEntryScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _actionTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? badge,
    Color? badgeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.mdBorder,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.mdBorder,
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.ink)),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeColor!.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.ink3)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.ink3),
          ],
        ),
      ),
    );
  }
}
