import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/split_bill_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_stack.dart';
import 'group_details_screen.dart';

class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SplitBillProvider>();
    final groups = provider.filteredGroups;
    final categories = ['ทั้งหมด', 'บ้าน', 'ทริป', 'กิน', 'งาน'];

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('กลุ่มของฉัน'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.primary, size: 28),
            onPressed: () => _showCreateGroupModal(context, provider),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Category Filter Chips
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = provider.groupCategoryFilter == cat;
                final count = cat == 'ทั้งหมด'
                    ? provider.groups.length
                    : provider.groups.where((g) => g.category == cat).length;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    showCheckmark: false,
                    label: Text(
                      cat == 'ทั้งหมด' ? 'ทั้งหมด · $count' : '$cat ($count)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.ink2,
                      ),
                    ),
                    backgroundColor: Colors.white,
                    selectedColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.smBorder,
                      side: BorderSide(color: isSelected ? AppColors.primary : AppColors.line),
                    ),
                    onSelected: (_) => provider.setGroupCategoryFilter(cat),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Groups List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              itemCount: groups.length + 1,
              itemBuilder: (context, index) {
                if (index == groups.length) {
                  // "＋ สร้างกลุ่มใหม่" Card
                  return _buildCreateGroupDashedCard(context, provider);
                }

                final group = groups[index];
                return _buildGroupCard(context, group);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(BuildContext context, GroupModel group) {
    final isCleared = group.userBalance == 0;
    final isPositive = group.userBalance > 0;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GroupDetailsScreen(group: group)),
        );
      },
      borderRadius: AppRadius.mdBorder,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.mdBorder,
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Text(group.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.ink),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${group.billIds.length} บิล · ${group.members.length} สมาชิก',
                        style: const TextStyle(fontSize: 12, color: AppColors.ink3),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (isCleared)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.successSoft,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '✓ เคลียร์แล้ว',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.success),
                        ),
                      )
                    else
                      Text(
                        '${isPositive ? "+" : ""}฿${group.userBalance.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isPositive ? AppColors.success : AppColors.warn,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AvatarStack(members: group.members, size: 26),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: AppColors.ink3),
                  label: const Text('ดูรายละเอียด', style: TextStyle(fontSize: 12.5, color: AppColors.primary)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => GroupDetailsScreen(group: group)),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateGroupDashedCard(BuildContext context, SplitBillProvider provider) {
    return InkWell(
      onTap: () => _showCreateGroupModal(context, provider),
      borderRadius: AppRadius.mdBorder,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.mdBorder,
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.5), style: BorderStyle.solid),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text(
              'สร้างกลุ่มใหม่',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateGroupModal(BuildContext context, SplitBillProvider provider) {
    final nameCtrl = TextEditingController();
    String selectedCat = 'กิน';
    String selectedEmoji = '🍽';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('สร้างกลุ่มใหม่', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'ชื่อกลุ่ม เช่น แก๊งชาบูกินแหลก', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  const Text('หมวดหมู่', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _catChoice('🍽 กิน', 'กิน', '🍽', selectedCat, (cat, emoji) {
                        setModalState(() {
                          selectedCat = cat;
                          selectedEmoji = emoji;
                        });
                      }),
                      _catChoice('✈️ ทริป', 'ทริป', '✈️', selectedCat, (cat, emoji) {
                        setModalState(() {
                          selectedCat = cat;
                          selectedEmoji = emoji;
                        });
                      }),
                      _catChoice('🏠 บ้าน', 'บ้าน', '🏠', selectedCat, (cat, emoji) {
                        setModalState(() {
                          selectedCat = cat;
                          selectedEmoji = emoji;
                        });
                      }),
                      _catChoice('💼 งาน', 'งาน', '💼', selectedCat, (cat, emoji) {
                        setModalState(() {
                          selectedCat = cat;
                          selectedEmoji = emoji;
                        });
                      }),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
                    ),
                    onPressed: () {
                      if (nameCtrl.text.isNotEmpty) {
                        provider.addNewGroup(nameCtrl.text, selectedCat, selectedEmoji);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('สร้างกลุ่ม ${nameCtrl.text} สำเร็จแล้ว 🎉')),
                        );
                      }
                    },
                    child: const Text('บันทึกกลุ่ม'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _catChoice(String label, String cat, String emoji, String selected, Function(String, String) onSelect) {
    final isSelected = selected == cat;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelect(cat, emoji),
      selectedColor: AppColors.primarySoft,
      labelStyle: TextStyle(color: isSelected ? AppColors.primary : AppColors.ink2, fontWeight: FontWeight.w600),
    );
  }
}
