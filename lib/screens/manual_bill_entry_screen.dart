import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/split_bill_provider.dart';
import '../theme/app_theme.dart';
import '../utils/date_formatter.dart';
import 'split_mode_screen.dart';

class ManualBillEntryScreen extends StatefulWidget {
  const ManualBillEntryScreen({super.key});

  @override
  State<ManualBillEntryScreen> createState() => _ManualBillEntryScreenState();
}

class _ManualBillEntryScreenState extends State<ManualBillEntryScreen> {
  late TextEditingController _titleCtrl;
  late TextEditingController _discountCtrl;
  late TextEditingController _vatCtrl;
  late TextEditingController _serviceCtrl;

  final List<String> _emojis = ['🍜', '☕', '🍻', '🏠', '🚗', '🛒', '💼', '🍿', '✈️', '🎉'];

  @override
  void initState() {
    super.initState();
    final provider = context.read<SplitBillProvider>();
    final bill = provider.currentDraftBill;

    _titleCtrl = TextEditingController(text: bill?.title ?? '');
    _discountCtrl = TextEditingController(
      text: (bill != null && bill.discountAmount > 0) ? bill.discountAmount.toStringAsFixed(0) : '',
    );
    _vatCtrl = TextEditingController(
      text: (bill != null && bill.vatPercent > 0) ? bill.vatPercent.toStringAsFixed(0) : '7',
    );
    _serviceCtrl = TextEditingController(
      text: (bill != null && bill.serviceChargePercent > 0) ? bill.serviceChargePercent.toStringAsFixed(0) : '0',
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _discountCtrl.dispose();
    _vatCtrl.dispose();
    _serviceCtrl.dispose();
    super.dispose();
  }

  String _formatThaiDate(DateTime date) {
    return DateFormatter.formatThaiDate(date);
  }

  Future<void> _pickDate(BuildContext context, SplitBillProvider provider, DateTime currentDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      provider.updateDraftBillInfo(date: picked);
    }
  }

  void _showAddItemSheet(BuildContext context, SplitBillProvider provider) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    int quantity = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('เพิ่มรายการอาหาร / ค่าใช้จ่าย', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'ชื่อรายการ (เช่น ก๋วยเตี๋ยว, น้ำดื่ม)',
                      border: OutlineInputBorder(borderRadius: AppRadius.smBorder),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: priceCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'ราคาต่อชิ้น (฿)',
                            border: OutlineInputBorder(borderRadius: AppRadius.smBorder),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Container(
                          height: 58,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.line),
                            borderRadius: AppRadius.smBorder,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, size: 18),
                                onPressed: quantity > 1 ? () => setSheetState(() => quantity--) : null,
                              ),
                              Text('$quantity', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              IconButton(
                                icon: const Icon(Icons.add, size: 18),
                                onPressed: () => setSheetState(() => quantity++),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
                    ),
                    onPressed: () {
                      final name = nameCtrl.text.trim();
                      final price = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
                      if (name.isNotEmpty && price > 0) {
                        provider.addBillItem(name, price, quantity);
                        Navigator.pop(ctx);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('กรุณาระบุชื่อและราคาที่ถูกต้อง')),
                        );
                      }
                    },
                    child: const Text('บันทึกรายการ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showEditItemSheet(BuildContext context, SplitBillProvider provider, BillItem item) {
    final nameCtrl = TextEditingController(text: item.name);
    final priceCtrl = TextEditingController(text: item.price.toStringAsFixed(2));
    int quantity = item.quantity;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('แก้ไขรายการ', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                        onPressed: () {
                          provider.removeBillItem(item.id);
                          Navigator.pop(ctx);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'ชื่อรายการ',
                      border: OutlineInputBorder(borderRadius: AppRadius.smBorder),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: priceCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'ราคาต่อชิ้น (฿)',
                            border: OutlineInputBorder(borderRadius: AppRadius.smBorder),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Container(
                          height: 58,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.line),
                            borderRadius: AppRadius.smBorder,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, size: 18),
                                onPressed: quantity > 1 ? () => setSheetState(() => quantity--) : null,
                              ),
                              Text('$quantity', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              IconButton(
                                icon: const Icon(Icons.add, size: 18),
                                onPressed: () => setSheetState(() => quantity++),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
                    ),
                    onPressed: () {
                      final name = nameCtrl.text.trim();
                      final price = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
                      if (name.isNotEmpty && price > 0) {
                        provider.updateBillItem(item.id, name: name, price: price, quantity: quantity);
                        Navigator.pop(ctx);
                      }
                    },
                    child: const Text('บันทึกการแก้ไข', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddMemberDialog(BuildContext context, SplitBillProvider provider) {
    final nameCtrl = TextEditingController();
    String selectedEmoji = '👤';
    const friendEmojis = ['👤', '😎', '🥳', '🐱', '🐶', '🦊', '🐼', '🦄', '⭐', '🔥'];
    final colors = [
      const Color(0xFF6366F1),
      const Color(0xFFEC4899),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFF3B82F6),
      const Color(0xFF8B5CF6),
    ];
    Color selectedColor = colors[0];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('เพิ่มเพื่อนร่วมหารใหม่', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'ชื่อเพื่อน (เช่น แนน, บอม, พี่ตู่)',
                      border: OutlineInputBorder(borderRadius: AppRadius.smBorder),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('เลือกอิโมจิ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink2)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: friendEmojis.map((e) {
                      final isSel = selectedEmoji == e;
                      return GestureDetector(
                        onTap: () => setDialogState(() => selectedEmoji = e),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSel ? AppColors.primarySoft : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isSel ? AppColors.primary : Colors.transparent, width: 1.5),
                          ),
                          child: Text(e, style: const TextStyle(fontSize: 20)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
                    ),
                    onPressed: () {
                      final name = nameCtrl.text.trim();
                      if (name.isNotEmpty) {
                        provider.addNewMember(
                          name: name,
                          avatarEmoji: selectedEmoji,
                          avatarColor: selectedColor,
                        );
                        Navigator.pop(ctx);
                      }
                    },
                    child: const Text('เพิ่มเพื่อนและร่วมบิลนี้', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SplitBillProvider>();
    final bill = provider.currentDraftBill;

    if (bill == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('กรอกบิล')),
        body: const Center(child: Text('ไม่พบบิล')),
      );
    }

    final participants = provider.getDraftBillParticipants();
    final allMembers = provider.allMembers;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('สร้างและกรอกบิลใหม่'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // 1. Bill Title & Emoji
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.lgBorder,
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ข้อมูลบิล', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Emoji Selector
                    PopupMenuButton<String>(
                      initialValue: bill.categoryEmoji,
                      onSelected: (emoji) => provider.updateDraftBillInfo(categoryEmoji: emoji),
                      itemBuilder: (ctx) => _emojis
                          .map(
                            (e) => PopupMenuItem(
                              value: e,
                              child: Text(e, style: const TextStyle(fontSize: 24)),
                            ),
                          )
                          .toList(),
                      child: Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Center(
                          child: Text(bill.categoryEmoji, style: const TextStyle(fontSize: 26)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Title input
                    Expanded(
                      child: TextField(
                        controller: _titleCtrl,
                        decoration: InputDecoration(
                          hintText: 'ชื่อบิล เช่น หมูกระทะ ศุกร์',
                          labelText: 'ชื่อบิล *',
                          border: OutlineInputBorder(borderRadius: AppRadius.smBorder),
                        ),
                        onChanged: (val) => provider.updateDraftBillInfo(title: val),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Date & Group
                Row(
                  children: [
                    // Date
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickDate(context, provider, bill.date),
                        borderRadius: AppRadius.smBorder,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: AppRadius.smBorder,
                            border: Border.all(color: AppColors.line),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _formatThaiDate(bill.date),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Group selector
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: AppRadius.smBorder,
                          border: Border.all(color: AppColors.line),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: provider.groups.any((g) => g.name == bill.groupName)
                                ? bill.groupName
                                : (provider.groups.isNotEmpty ? provider.groups.first.name : null),
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                            items: provider.groups
                                .map(
                                  (g) => DropdownMenuItem(
                                    value: g.name,
                                    child: Text(
                                      '${g.emoji} ${g.name}',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (grp) {
                              if (grp != null) {
                                provider.updateDraftBillInfo(groupName: grp);
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 2. Who Paid? & Who Participates?
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.lgBorder,
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('ใครเป็นคนจ่าย? (สำรองจ่าย)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: allMembers.any((m) => m.id == bill.paidByMemberId)
                            ? bill.paidByMemberId
                            : provider.currentUser.id,
                        items: allMembers
                            .map(
                              (m) => DropdownMenuItem(
                                value: m.id,
                                child: Text('${m.avatarEmoji} ${m.name} ${m.isCurrentUser ? "(คุณ)" : ""}'),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            provider.updateDraftBillInfo(paidByMemberId: val);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('ใครร่วมหารบ้างในบิลนี้?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Row(
                      children: [
                        TextButton(
                          style: TextButton.styleFrom(visualDensity: VisualDensity.compact, padding: EdgeInsets.zero),
                          onPressed: () {
                            provider.setDraftBillParticipants(allMembers.map((m) => m.id).toList());
                          },
                          child: const Text('เลือกทุกคน', style: TextStyle(fontSize: 12, color: AppColors.primary)),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${participants.length} คน',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ...allMembers.map((m) {
                      final isSelected = bill.participantMemberIds.contains(m.id);
                      return FilterChip(
                        selected: isSelected,
                        avatar: Text(m.avatarEmoji, style: const TextStyle(fontSize: 14)),
                        label: Text(m.name),
                        selectedColor: AppColors.primarySoft,
                        checkmarkColor: AppColors.primary,
                        onSelected: (_) => provider.toggleDraftBillParticipant(m.id),
                      );
                    }),
                    ActionChip(
                      avatar: const Icon(Icons.person_add_alt_1_rounded, size: 16, color: AppColors.primary),
                      label: const Text('+ เพิ่มเพื่อน', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: AppColors.primary, style: BorderStyle.solid),
                      onPressed: () => _showAddMemberDialog(context, provider),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 3. Items List
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.lgBorder,
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'รายการค่าใช้จ่าย (${bill.items.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.add_circle_outline, size: 18),
                      label: const Text('เพิ่มรายการ', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () => _showAddItemSheet(context, provider),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (bill.items.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        const Icon(Icons.receipt_long_outlined, size: 44, color: AppColors.ink3),
                        const SizedBox(height: 8),
                        const Text('ยังไม่มีรายการในบิลนี้', style: TextStyle(color: AppColors.ink2, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        const Text('แตะปุ่ม "เพิ่มรายการ" ด้านบนเพื่อเริ่มกรอก', style: TextStyle(fontSize: 12, color: AppColors.ink3)),
                      ],
                    ),
                  )
                else
                  ...bill.items.map((item) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: AppRadius.smBorder,
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _showEditItemSheet(context, provider, item),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.quantity > 1 ? '${item.name} × ${item.quantity}' : item.name,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                  ),
                                  Text(
                                    '฿${item.price.toStringAsFixed(2)} / หน่วย',
                                    style: const TextStyle(fontSize: 11.5, color: AppColors.ink3),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Text(
                            '฿${item.totalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: AppColors.ink),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                            onPressed: () => provider.removeBillItem(item.id),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 4. Taxes & Discounts
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.lgBorder,
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ภาษี, เซอร์วิสชาร์จ และส่วนลด', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // VAT
                    Expanded(
                      child: TextField(
                        controller: _vatCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'VAT (%)',
                          border: OutlineInputBorder(borderRadius: AppRadius.smBorder),
                        ),
                        onChanged: (val) {
                          provider.updateDraftBillInfo(vatPercent: double.tryParse(val) ?? 0.0);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Service Charge
                    Expanded(
                      child: TextField(
                        controller: _serviceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Service (%)',
                          border: OutlineInputBorder(borderRadius: AppRadius.smBorder),
                        ),
                        onChanged: (val) {
                          provider.updateDraftBillInfo(serviceChargePercent: double.tryParse(val) ?? 0.0);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Discount
                    Expanded(
                      child: TextField(
                        controller: _discountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'ส่วนลด (฿)',
                          border: OutlineInputBorder(borderRadius: AppRadius.smBorder),
                        ),
                        onChanged: (val) {
                          provider.updateDraftBillInfo(discountAmount: double.tryParse(val) ?? 0.0);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 5. Penny Rounding Strategy
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.lgBorder,
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text('🪙', style: TextStyle(fontSize: 18)),
                    SizedBox(width: 8),
                    Text('ระบบปัดเศษสตางค์ (Penny Rounding)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'เลือกวิธีจัดการเศษสตางค์กรณีหารไม่ลงตัว (เช่น 100 บาท หาร 3 คน)',
                  style: TextStyle(fontSize: 12, color: AppColors.ink3),
                ),
                const SizedBox(height: 12),
                _roundingOptionTile(
                  title: 'คนสำรองจ่ายรับผิดชอบเศษ (แนะนำ)',
                  subtitle: 'ยอดทุกคนรวมกันตรงกับยอดบิล 100.00% พอดีเป๊ะ',
                  strategy: RoundingStrategy.payerAbsorbs,
                  current: bill.roundingStrategy,
                  onTap: () => provider.setRoundingStrategy(RoundingStrategy.payerAbsorbs),
                ),
                const SizedBox(height: 8),
                _roundingOptionTile(
                  title: 'กระจายเศษ 1 สตางค์ให้คนแรก ๆ',
                  subtitle: 'เฉลี่ยให้เพื่อนคนแรก ๆ จ่ายเพิ่ม 1 สตางค์จนครบ',
                  strategy: RoundingStrategy.distributeEvenly,
                  current: bill.roundingStrategy,
                  onTap: () => provider.setRoundingStrategy(RoundingStrategy.distributeEvenly),
                ),
                const SizedBox(height: 8),
                _roundingOptionTile(
                  title: 'ปัดเป็นจำนวนเต็มบาท (ไม่มีเศษสตางค์)',
                  subtitle: 'ทุกคนจ่ายยอดเลขกลม โอนสะดวก ไม่ต้องโอนเศษสตางค์',
                  strategy: RoundingStrategy.roundToBaht,
                  current: bill.roundingStrategy,
                  onTap: () => provider.setRoundingStrategy(RoundingStrategy.roundToBaht),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 6. Total calculation overview
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.lgBorder,
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              children: [
                _calcRow('ยอดรวมรายการ', '฿${bill.subtotal.toStringAsFixed(2)}'),
                if (bill.vatPercent > 0) ...[
                  const SizedBox(height: 6),
                  _calcRow('VAT ${bill.vatPercent.toStringAsFixed(0)}%', '฿${bill.vatAmount.toStringAsFixed(2)}'),
                ],
                if (bill.serviceChargePercent > 0) ...[
                  const SizedBox(height: 6),
                  _calcRow('Service Charge ${bill.serviceChargePercent.toStringAsFixed(0)}%', '฿${bill.serviceChargeAmount.toStringAsFixed(2)}'),
                ],
                if (bill.discountAmount > 0) ...[
                  const SizedBox(height: 6),
                  _calcRow('ส่วนลด', '−฿${bill.discountAmount.toStringAsFixed(2)}', isNegative: true),
                ],
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('ยอดสุทธิทั้งบิล', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(
                      '฿${bill.grandTotal.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.primary),
                    ),
                  ],
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
          top: false,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: bill.items.isNotEmpty ? AppColors.primary : AppColors.ink3,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
            ),
            onPressed: bill.items.isNotEmpty
                ? () {
                    final finalTitle = _titleCtrl.text.trim().isNotEmpty
                        ? _titleCtrl.text.trim()
                        : 'บิลวันที่ ${_formatThaiDate(bill.date)}';
                    provider.updateDraftBillInfo(title: finalTitle);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SplitModeScreen()),
                    );
                  }
                : null,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('ถัดไป · เลือกวิธีหาร', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _roundingOptionTile({
    required String title,
    required String subtitle,
    required RoundingStrategy strategy,
    required RoundingStrategy current,
    required VoidCallback onTap,
  }) {
    final isSelected = strategy == current;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.smBorder,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySoft : const Color(0xFFF8FAFC),
          borderRadius: AppRadius.smBorder,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.line,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.primary : AppColors.ink3,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? AppColors.primary : AppColors.ink,
                    ),
                  ),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.ink3)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _calcRow(String label, String amount, {bool isNegative = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13.5, color: AppColors.ink2)),
        Text(
          amount,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: isNegative ? AppColors.success : AppColors.ink,
          ),
        ),
      ],
    );
  }
}
