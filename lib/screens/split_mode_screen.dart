import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/split_bill_provider.dart';
import '../theme/app_theme.dart';
import 'bill_summary_screen.dart';

class SplitModeScreen extends StatelessWidget {
  const SplitModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SplitBillProvider>();
    final bill = provider.currentDraftBill;

    if (bill == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('วิธีหารบิล')),
        body: const Center(child: Text('ไม่พบบิล')),
      );
    }

    final totalItemsCount = bill.items.length;
    final assignedItemsCount = bill.items.where((i) => i.assignedMemberIds.isNotEmpty).length;
    final unassignedItemsCount = totalItemsCount - assignedItemsCount;
    final isFullyAssigned = bill.splitMode == SplitMode.equal || unassignedItemsCount == 0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('วิธีหารบิล'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Segmented Control: [ หารเท่ากัน | หารตามจริง ]
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.lgBorder,
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _modeSegment(
                      label: 'หารเท่ากัน',
                      icon: Icons.pie_chart_outline_rounded,
                      isSelected: bill.splitMode == SplitMode.equal,
                      onTap: () => provider.setSplitMode(SplitMode.equal),
                    ),
                  ),
                  Expanded(
                    child: _modeSegment(
                      label: 'หารตามจริง ✓',
                      icon: Icons.receipt_long_outlined,
                      isSelected: bill.splitMode == SplitMode.itemized,
                      onTap: () => provider.setSplitMode(SplitMode.itemized),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (bill.splitMode == SplitMode.equal)
            Expanded(child: _buildEqualModeView(context, provider, bill))
          else
            Expanded(child: _buildItemizedModeView(context, provider, bill, unassignedItemsCount)),

          // Bottom Bar: Progress & Next Button
          _buildBottomAction(context, provider, bill, assignedItemsCount, totalItemsCount, isFullyAssigned),
        ],
      ),
    );
  }

  Widget _modeSegment({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: AppRadius.mdBorder,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.ink2),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.ink2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Equal Split View
  Widget _buildEqualModeView(BuildContext context, SplitBillProvider provider, Bill bill) {
    final participants = provider.getDraftBillParticipants();
    final shares = provider.calculateMemberShares();
    final perPerson = participants.isNotEmpty ? bill.grandTotal / participants.length : 0.0;
    final payer = provider.allMembers.firstWhere((m) => m.id == bill.paidByMemberId, orElse: () => provider.currentUser);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        _buildRoundingStrategySelector(provider, bill),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppRadius.mdBorder,
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            children: [
              const Text('หารเฉลี่ยเท่ากันทุกคน', style: TextStyle(fontSize: 14, color: AppColors.ink3)),
              const SizedBox(height: 6),
              Text(
                '฿${perPerson.toStringAsFixed(2)} / คน',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('👥 ${participants.length} คนร่วมบิล', style: const TextStyle(fontSize: 12.5, color: AppColors.ink3)),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact, padding: EdgeInsets.zero),
                    icon: const Icon(Icons.group_add_rounded, size: 14),
                    label: const Text('จัดการคนร่วมบิล', style: TextStyle(fontSize: 12)),
                    onPressed: () => _showManageParticipantsSheet(context, provider),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(),
              const SizedBox(height: 8),
              ...participants.map((m) {
                final memberShare = shares[m.id] ?? perPerson;
                final isPayer = m.id == payer.id;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: m.avatarColor.withValues(alpha: 0.15),
                        child: Text(m.avatarEmoji, style: const TextStyle(fontSize: 18)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isPayer ? '${m.name} (${m.isCurrentUser ? "คุณจ่าย" : "คนจ่าย"})' : m.name,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                      ),
                      Text(
                        '฿${memberShare.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.ink),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  // Itemized Mode View
  Widget _buildItemizedModeView(
    BuildContext context,
    SplitBillProvider provider,
    Bill bill,
    int unassignedItemsCount,
  ) {
    final activeMembers = provider.getDraftBillParticipants();

    return Column(
      children: [
        // Rounding Strategy & Member Selector Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildRoundingStrategySelector(provider, bill),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'แตะที่รายการเพื่อเลือกคนที่กินด้วยกัน',
                    style: TextStyle(fontSize: 12.5, color: AppColors.ink3),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact, padding: EdgeInsets.zero),
                    icon: const Icon(Icons.group_add_rounded, size: 14),
                    label: Text('คนร่วมบิล (${activeMembers.length})', style: const TextStyle(fontSize: 12)),
                    onPressed: () => _showManageParticipantsSheet(context, provider),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ...activeMembers.map((m) {
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: AppRadius.smBorder,
                          border: Border.all(color: AppColors.line),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(m.avatarEmoji, style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 4),
                            Text(m.name, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Items List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            itemCount: bill.items.length,
            itemBuilder: (context, index) {
              final item = bill.items[index];
              final isUnassigned = item.assignedMemberIds.isEmpty;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isUnassigned ? const Color(0xFFFFF1F2) : Colors.white,
                  borderRadius: AppRadius.mdBorder,
                  border: Border.all(
                    color: isUnassigned ? const Color(0xFFFECDD3) : AppColors.line,
                    width: isUnassigned ? 1.5 : 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.ink),
                        ),
                        Text(
                          '฿${item.totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.ink),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Assigned Avatars / Member chips
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (isUnassigned)
                          const Text(
                            '⚠️ ยังไม่มีคนรับผิดชอบ',
                            style: TextStyle(fontSize: 12, color: AppColors.danger, fontWeight: FontWeight.w600),
                          )
                        else
                          ...item.assignedMemberIds.map((mId) {
                            final m = provider.allMembers.firstWhere((mem) => mem.id == mId);
                            return InkWell(
                              onTap: () => provider.toggleMemberAssignment(item.id, mId),
                              child: Chip(
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                avatar: Text(m.avatarEmoji, style: const TextStyle(fontSize: 14)),
                                label: Text(m.name, style: const TextStyle(fontSize: 12)),
                                deleteIcon: const Icon(Icons.close, size: 14),
                                onDeleted: () => provider.toggleMemberAssignment(item.id, mId),
                              ),
                            );
                          }),

                        // Add member button for this item
                        ActionChip(
                          visualDensity: VisualDensity.compact,
                          avatar: const Icon(Icons.add, size: 14, color: AppColors.primary),
                          label: const Text('เพิ่มคน', style: TextStyle(fontSize: 12, color: AppColors.primary)),
                          onPressed: () => _showMemberPickerSheet(context, provider, item),
                        ),

                        // Shortcut: "ทุกคนกินร่วม"
                        ActionChip(
                          visualDensity: VisualDensity.compact,
                          avatar: const Text('🍚', style: TextStyle(fontSize: 13)),
                          label: const Text('ทุกคนกินร่วม', style: TextStyle(fontSize: 12, color: AppColors.ink2)),
                          onPressed: () => provider.assignAllMembersToItem(item.id),
                        ),
                      ],
                    ),

                    if (item.assignedMemberIds.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '฿${(item.totalPrice / item.assignedMemberIds.length).toStringAsFixed(2)} / คน',
                          style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),

        // Quick Global Action Bar: [ 🍚 ทุกคนกินร่วม ] [ ↺ ล้างทั้งหมด ]
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                icon: const Text('🍚', style: TextStyle(fontSize: 16)),
                label: const Text('แบ่งให้ทุกคนทุกรายการ', style: TextStyle(color: AppColors.ink2, fontSize: 13)),
                onPressed: () {
                  for (var it in bill.items) {
                    provider.assignAllMembersToItem(it.id);
                  }
                },
              ),
              TextButton.icon(
                icon: const Icon(Icons.refresh_rounded, size: 16, color: AppColors.danger),
                label: const Text('↺ ล้างทั้งหมด', style: TextStyle(color: AppColors.danger, fontSize: 13)),
                onPressed: () => provider.clearAllAssignments(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomAction(
    BuildContext context,
    SplitBillProvider provider,
    Bill bill,
    int assignedCount,
    int totalCount,
    bool isFullyAssigned,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            if (bill.splitMode == SplitMode.itemized)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'จัดสรรแล้ว $assignedCount/$totalCount รายการ',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isFullyAssigned ? AppColors.success : AppColors.warn,
                      ),
                    ),
                    if (!isFullyAssigned)
                      const Text(
                        'ต้องกำหนดให้ครบทุกรายการ',
                        style: TextStyle(fontSize: 12, color: AppColors.danger),
                      )
                    else
                      const Text('พร้อมสรุปยอด 🎉', style: TextStyle(fontSize: 12, color: AppColors.success)),
                  ],
                ),
              ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isFullyAssigned ? AppColors.primary : AppColors.ink3,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
              ),
              onPressed: isFullyAssigned
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BillSummaryScreen()),
                      );
                    }
                  : null,
              child: const Text('ถัดไป · สรุปบิล', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showMemberPickerSheet(BuildContext context, SplitBillProvider provider, BillItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final members = provider.getDraftBillParticipants();
            final allAssigned = members.isNotEmpty && members.every((m) => item.assignedMemberIds.contains(m.id));

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'เลือกคนสำหรับ: ${item.name}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'เลือกแล้ว ${item.assignedMemberIds.length}/${members.length} คน (฿${(item.assignedMemberIds.isNotEmpty ? (item.totalPrice / item.assignedMemberIds.length) : 0.0).toStringAsFixed(2)}/คน)',
                          style: const TextStyle(fontSize: 12, color: AppColors.ink2, fontWeight: FontWeight.w500),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                          onPressed: () {
                            setSheetState(() {
                              if (allAssigned) {
                                provider.setItemAssignedMembers(item.id, []);
                              } else {
                                provider.setItemAssignedMembers(item.id, members.map((m) => m.id).toList());
                              }
                            });
                          },
                          child: Text(allAssigned ? 'ล้างทั้งหมด' : 'เลือกทุกคน'),
                        ),
                      ],
                    ),
                    const Divider(),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.45),
                      child: ListView(
                        shrinkWrap: true,
                        children: members.map((m) {
                          final isSelected = item.assignedMemberIds.contains(m.id);
                          return CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Row(
                              children: [
                                Text(m.avatarEmoji, style: const TextStyle(fontSize: 18)),
                                const SizedBox(width: 8),
                                Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                if (m.isCurrentUser)
                                  const Text(' (คุณ)', style: TextStyle(fontSize: 12, color: AppColors.ink3)),
                              ],
                            ),
                            value: isSelected,
                            onChanged: (bool? val) {
                              setSheetState(() {
                                provider.toggleMemberAssignment(item.id, m.id);
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('ตกลง', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showManageParticipantsSheet(BuildContext context, SplitBillProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final allMembers = provider.allMembers;
            final bill = provider.currentDraftBill;
            if (bill == null) return const SizedBox();

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('จัดการคนร่วมบิลนี้', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'เลือกคนที่เข้าร่วมในบิลนี้ (${bill.participantMemberIds.length}/${allMembers.length} คน)',
                      style: const TextStyle(fontSize: 12.5, color: AppColors.ink3),
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.45),
                      child: ListView(
                        shrinkWrap: true,
                        children: allMembers.map((m) {
                          final isSelected = bill.participantMemberIds.contains(m.id);
                          return CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Row(
                              children: [
                                Text(m.avatarEmoji, style: const TextStyle(fontSize: 18)),
                                const SizedBox(width: 8),
                                Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                if (m.isCurrentUser) const Text(' (คุณ)', style: TextStyle(fontSize: 12, color: AppColors.ink3)),
                              ],
                            ),
                            value: isSelected,
                            onChanged: (_) {
                              setSheetState(() {
                                provider.toggleDraftBillParticipant(m.id);
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('เสร็จสิ้น', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRoundingStrategySelector(SplitBillProvider provider, Bill bill) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.mdBorder,
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Text('🪙', style: TextStyle(fontSize: 15)),
                  SizedBox(width: 6),
                  Text('การปัดเศษสตางค์:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                ],
              ),
              Text(
                bill.roundingStrategy == RoundingStrategy.payerAbsorbs
                    ? 'คนสำรองจ่ายรับเศษ'
                    : bill.roundingStrategy == RoundingStrategy.distributeEvenly
                        ? 'กระจายเศษ 1 สตางค์'
                        : 'ปัดเป็นบาทถ้วน',
                style: const TextStyle(fontSize: 11.5, color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _strategyChip(
                  label: '🪙 คนจ่ายรับเศษ',
                  isSelected: bill.roundingStrategy == RoundingStrategy.payerAbsorbs,
                  onTap: () => provider.setRoundingStrategy(RoundingStrategy.payerAbsorbs),
                ),
                const SizedBox(width: 6),
                _strategyChip(
                  label: '🔄 กระจายเศษ 1 สต.',
                  isSelected: bill.roundingStrategy == RoundingStrategy.distributeEvenly,
                  onTap: () => provider.setRoundingStrategy(RoundingStrategy.distributeEvenly),
                ),
                const SizedBox(width: 6),
                _strategyChip(
                  label: '🎯 ปัดเป็นบาทถ้วน',
                  isSelected: bill.roundingStrategy == RoundingStrategy.roundToBaht,
                  onTap: () => provider.setRoundingStrategy(RoundingStrategy.roundToBaht),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _strategyChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySoft : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.line,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppColors.primary : AppColors.ink2,
          ),
        ),
      ),
    );
  }
}
