import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/models.dart';
import '../providers/split_bill_provider.dart';
import '../theme/app_theme.dart';
import 'ocr_review_screen.dart';
import 'manual_bill_entry_screen.dart';

class GroupDetailsScreen extends StatelessWidget {
  final GroupModel group;

  const GroupDetailsScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SplitBillProvider>();
    // Check if group still exists in provider
    final currentGroup = provider.groups.firstWhere(
      (g) => g.id == group.id,
      orElse: () => group,
    );
    final groupBills = provider.getGroupBills(currentGroup.id);
    final isCleared = currentGroup.userBalance == 0;
    final isPositive = currentGroup.userBalance > 0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(currentGroup.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.primary),
            tooltip: 'เชิญเพื่อนเข้ากลุ่ม',
            onPressed: () => _showInviteSheet(context, currentGroup),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
            tooltip: 'ลบกลุ่ม',
            onPressed: () => _showDeleteGroupDialog(context, provider, currentGroup),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // Group Hero Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.xlBorder,
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(currentGroup.emoji, style: const TextStyle(fontSize: 40)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentGroup.name,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.ink),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.bg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'หมวดหมู่: ${currentGroup.category}',
                              style: const TextStyle(fontSize: 12, color: AppColors.ink2),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('ยอดสุทธิของคุณ', style: TextStyle(fontSize: 11, color: AppColors.ink3)),
                        const SizedBox(height: 2),
                        if (isCleared)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.successSoft,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              '✓ เคลียร์แล้ว',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.success),
                            ),
                          )
                        else
                          Text(
                            '${isPositive ? "+" : ""}฿${currentGroup.userBalance.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isPositive ? AppColors.success : AppColors.warn,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Members Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'สมาชิกในกลุ่ม (${currentGroup.members.length} คน)',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.ink),
              ),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 16, color: AppColors.primary),
                label: const Text('เชิญเพื่อน', style: TextStyle(fontSize: 13, color: AppColors.primary)),
                onPressed: () => _showInviteSheet(context, currentGroup),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.mdBorder,
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              children: currentGroup.members.map((m) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: m.avatarColor.withValues(alpha: 0.15),
                        child: Text(m.avatarEmoji, style: const TextStyle(fontSize: 18)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          m.isCurrentUser ? '${m.name} (คุณ · ผู้จัดการกลุ่ม)' : m.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: m.isCurrentUser ? FontWeight.bold : FontWeight.w500,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      if (m.isCurrentUser)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Admin', style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 24),

          // Bills in Group Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'บิลทั้งหมดในกลุ่ม (${groupBills.length} บิล)',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.ink),
              ),
              TextButton.icon(
                icon: const Icon(Icons.receipt_long_rounded, size: 16, color: AppColors.primary),
                label: const Text('เพิ่มบิล', style: TextStyle(fontSize: 13, color: AppColors.primary)),
                onPressed: () => _showAddBillActionSheet(context, provider, currentGroup),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (groupBills.isEmpty)
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.mdBorder,
                border: Border.all(color: AppColors.line),
              ),
              child: Center(
                child: Column(
                  children: [
                    const Text('🧾', style: TextStyle(fontSize: 32)),
                    const SizedBox(height: 8),
                    const Text('ยังไม่มีรายการบิลในกลุ่มนี้', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('กดปุ่มเพิ่มบิลด้านล่างเพื่อเริ่มหารค่าใช้จ่าย', style: TextStyle(fontSize: 12, color: AppColors.ink3)),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                      ),
                      onPressed: () => _showAddBillActionSheet(context, provider, currentGroup),
                      child: const Text('เพิ่มบิลแรก'),
                    ),
                  ],
                ),
              ),
            )
          else
            ...groupBills.map((b) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppRadius.mdBorder,
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.bg,
                        borderRadius: AppRadius.smBorder,
                      ),
                      child: const Icon(Icons.receipt_outlined, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            b.title,
                            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppColors.ink),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${b.paidByName} จ่ายไปก่อน · แชร์ ${b.memberCount} คน',
                            style: const TextStyle(fontSize: 12, color: AppColors.ink3),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '฿${b.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.ink),
                    ),
                  ],
                ),
              );
            }),

          const SizedBox(height: 30),

          // Delete Group Option
          OutlinedButton.icon(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
            label: const Text('ลบกลุ่มนี้', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              side: const BorderSide(color: AppColors.danger),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
            ),
            onPressed: () => _showDeleteGroupDialog(context, provider, currentGroup),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  void _showInviteSheet(BuildContext context, GroupModel group) {
    const inviteUrl = 'https://splitbill.app/g/join_c8m9X1';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('เชิญเพื่อนเข้าร่วมกลุ่ม "${group.name}"', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text('เพื่อนสามารถกดเข้าร่วมได้ทันทีโดยไม่ต้องโหลดแอปก่อน', style: TextStyle(fontSize: 12.5, color: AppColors.ink3)),
              const SizedBox(height: 18),
              SizedBox(
                width: 140,
                height: 140,
                child: QrImageView(
                  data: inviteUrl,
                  version: QrVersions.auto,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: AppRadius.smBorder,
                ),
                child: const Row(
                  children: [
                    Icon(Icons.link_rounded, size: 18, color: AppColors.ink3),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        inviteUrl,
                        style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppColors.ink2),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('คัดลอกลิงก์'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('คัดลอกลิงก์เชิญเพื่อนเรียบร้อยแล้ว')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.share_rounded, size: 16),
                      label: const Text('แชร์ไปที่ LINE'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('เปิด Share Sheet สำหรับส่งลิงก์เข้า LINE')),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Destructive Delete Confirmation Dialog (PDD Section E Screen 6 & Section I)
  void _showDeleteGroupDialog(BuildContext context, SplitBillProvider provider, GroupModel group) {
    final hasBalance = group.userBalance != 0;
    final confirmCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isMatch = confirmCtrl.text.trim() == group.name.trim();

            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
              title: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 28),
                  const SizedBox(width: 8),
                  const Text('ยืนยันการลบกลุ่ม', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('คุณแน่ใจหรือไม่ว่าต้องการลบกลุ่ม "${group.name}"?'),
                  if (hasBalance) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.warnSoft,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.warn.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        '⚠️ กลุ่มนี้ยังมียอดค้างชำระอยู่ (${group.userBalance > 0 ? "+" : ""}฿${group.userBalance.toStringAsFixed(2)}) หากลบ บิลและรายการหนี้ในกลุ่มนี้จะไม่ถูกติดตาม',
                        style: const TextStyle(fontSize: 12, color: Color(0xFFC2410C), fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'เพื่อยืนยันการลบ กรุณาพิมพ์ชื่อกลุ่ม "${group.name}":',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: confirmCtrl,
                      decoration: InputDecoration(
                        hintText: group.name,
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('ยกเลิก', style: TextStyle(color: AppColors.ink2)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: (!hasBalance || isMatch)
                      ? () {
                          provider.deleteGroup(group.id);
                          Navigator.pop(ctx); // close dialog
                          Navigator.pop(context); // return from details to groups list
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('ลบกลุ่ม "${group.name}" เรียบร้อยแล้ว')),
                          );
                        }
                      : null,
                  child: const Text('ลบกลุ่มถาวร'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddBillActionSheet(BuildContext context, SplitBillProvider provider, GroupModel currentGroup) {
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
              Text(
                'เพิ่มบิลในกลุ่ม ${currentGroup.name}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.ink),
              ),
              const SizedBox(height: 6),
              const Text(
                'เลือกวิธีสร้างบิลสำหรับกลุ่มนี้',
                style: TextStyle(fontSize: 13, color: AppColors.ink3),
              ),
              const SizedBox(height: 18),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primarySoft,
                  child: Icon(Icons.document_scanner_rounded, color: AppColors.primary),
                ),
                title: const Text('📷 สแกนใบเสร็จ (AI OCR)', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('ถ่ายรูปใบเสร็จเพื่ออ่านรายการอัตโนมัติ'),
                onTap: () {
                  Navigator.pop(ctx);
                  provider.initDraftBillFromOcr();
                  provider.updateDraftBillInfo(groupName: currentGroup.name);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OcrReviewScreen(startInCameraMode: true)),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.successSoft,
                  child: Icon(Icons.edit_note_rounded, color: AppColors.success),
                ),
                title: const Text('✍️ กรอกเอง (Manual Entry)', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('สร้างบิลใหม่จากศูนย์ กำหนดรายการและคนร่วมหาร'),
                onTap: () {
                  Navigator.pop(ctx);
                  provider.createBlankBill(groupName: currentGroup.name);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ManualBillEntryScreen()),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.warnSoft,
                  child: Icon(Icons.repeat_rounded, color: AppColors.warn),
                ),
                title: const Text('🔁 ทำซ้ำจากบิลเดิม', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('คัดลอกจากบิลล่าสุดเพื่อความรวดเร็ว'),
                onTap: () {
                  Navigator.pop(ctx);
                  provider.duplicateLatestBill();
                  provider.updateDraftBillInfo(groupName: currentGroup.name);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ManualBillEntryScreen()),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
