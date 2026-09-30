import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/split_bill_provider.dart';
import '../theme/app_theme.dart';
import '../utils/date_formatter.dart';
import 'split_mode_screen.dart';

class OcrReviewScreen extends StatefulWidget {
  final bool startInCameraMode;

  const OcrReviewScreen({super.key, this.startInCameraMode = false});

  @override
  State<OcrReviewScreen> createState() => _OcrReviewScreenState();
}

class _OcrReviewScreenState extends State<OcrReviewScreen> {
  int _currentStep = 3; // 1: Camera, 2: Processing, 3: Review
  int _simulatedProgress = 4;
  final int _totalItems = 7;
  bool _showOriginalReceipt = false;

  @override
  void initState() {
    super.initState();
    if (widget.startInCameraMode) {
      _currentStep = 1;
    }
  }

  void _startOcrSimulation() async {
    setState(() {
      _currentStep = 2;
      _simulatedProgress = 1;
    });

    for (int i = 2; i <= _totalItems; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      setState(() {
        _simulatedProgress = i;
      });
    }

    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    setState(() {
      _currentStep = 3;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentStep == 1) {
      return _buildCameraView();
    } else if (_currentStep == 2) {
      return _buildProcessingView();
    }
    return _buildReviewView(context);
  }

  // Step 1: Camera Simulation
  Widget _buildCameraView() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Camera viewfinder overlay
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary, width: 2),
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white.withValues(alpha: 0.05),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_rounded, color: Colors.white.withValues(alpha: 0.7), size: 64),
                      const SizedBox(height: 16),
                      const Text(
                        'วางใบเสร็จให้เต็มกรอบ',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ระบบจะตรวจจับขอบอัตโนมัติ',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Top Controls
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.flash_on, color: Colors.white),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.photo_library_outlined, color: Colors.white),
                        onPressed: _startOcrSimulation,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Bottom Capture Button
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _startOcrSimulation,
                    child: Container(
                      width: 80,
                      height: 80,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 36),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('แตะเพื่อถ่าย', style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Step 2: Processing state with explicit progress
  Widget _buildProcessingView() {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3.5),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'AI กำลังประมวลผลใบเสร็จ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.ink),
              ),
              const SizedBox(height: 8),
              Text(
                'กำลังอ่านรายการ… $_simulatedProgress/$_totalItems',
                style: const TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _simulatedProgress / _totalItems,
                  backgroundColor: AppColors.line,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Step 3: Review & Edit Items
  Widget _buildReviewView(BuildContext context) {
    final provider = context.watch<SplitBillProvider>();
    final bill = provider.currentDraftBill;

    if (bill == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('ตรวจสอบรายการ')),
        body: const Center(child: Text('ไม่พบบิล')),
      );
    }

    final warningItemsCount = bill.items.where((i) => i.hasWarning).length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('ตรวจสอบรายการ'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showOriginalReceipt ? Icons.receipt_rounded : Icons.image_outlined,
              color: AppColors.primary,
            ),
            tooltip: 'ดูภาพใบเสร็จจริง',
            onPressed: () {
              setState(() {
                _showOriginalReceipt = !_showOriginalReceipt;
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          if (_showOriginalReceipt)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: AppRadius.mdBorder,
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.image, color: Colors.amber, size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ภาพใบเสร็จต้นฉบับ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('ร้าน ${bill.title} · ${DateFormatter.formatThaiDate(bill.date)} · ${bill.items.length} รายการ', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _showOriginalReceipt = false),
                    child: const Text('ซ่อน'),
                  ),
                ],
              ),
            ),

          // Warning Banner
          if (warningItemsCount > 0)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.warnSoft,
                borderRadius: AppRadius.mdBorder,
                border: Border.all(color: AppColors.warn.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Text('⚠️', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'พบ $warningItemsCount รายการที่ควรตรวจสอบ',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.ink),
                        ),
                        const Text(
                          'แตะที่ตัวเลขหรือชื่อเพื่อแก้ไข inline ได้ทันที',
                          style: TextStyle(fontSize: 12, color: AppColors.ink2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Items List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'รายการ · ${bill.items.length} อย่าง',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.ink),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.add_circle_outline, size: 16, color: AppColors.primary),
                      label: const Text('เพิ่มรายการเอง', style: TextStyle(color: AppColors.primary, fontSize: 13)),
                      onPressed: () => _showAddItemDialog(context, provider),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Item Cards
                ...bill.items.map((item) => _buildItemCard(context, provider, item)),

                const SizedBox(height: 16),

                // Financial Summary Card (Subtotal, VAT, Service, Discount, Grand Total)
                _buildSummaryCard(bill),
                const SizedBox(height: 24),
              ],
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.line)),
            ),
            child: SafeArea(
              top: false,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SplitModeScreen()),
                  );
                },
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
        ],
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, SplitBillProvider provider, BillItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: item.hasWarning ? const Color(0xFFFFFBEB) : Colors.white,
        borderRadius: AppRadius.mdBorder,
        border: Border.all(
          color: item.hasWarning ? const Color(0xFFFDE68A) : AppColors.line,
          width: item.hasWarning ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          if (item.hasWarning)
            const Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: Text('⚠️', style: TextStyle(fontSize: 14)),
            ),
          Expanded(
            child: InkWell(
              onTap: () => _showEditItemDialog(context, provider, item),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.quantity > 1 ? '${item.name} × ${item.quantity}' : item.name,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink),
                  ),
                  if (item.hasWarning && item.warningMessage != null)
                    Text(
                      item.warningMessage!,
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFFD97706)),
                    ),
                ],
              ),
            ),
          ),
          InkWell(
            onTap: () => _showEditItemDialog(context, provider, item),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: item.hasWarning ? const Color(0xFFFEF3C7) : AppColors.primarySoft,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '฿${item.totalPrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: item.hasWarning ? const Color(0xFFB45309) : AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.edit,
                    size: 14,
                    color: item.hasWarning ? const Color(0xFFB45309) : AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.ink3),
            onPressed: () => provider.removeBillItem(item.id),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(Bill bill) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.mdBorder,
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          _summaryRow('ยอดรวม', '฿${bill.subtotal.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          _summaryRow('VAT 7%', '฿${bill.vatAmount.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          _summaryRow('Service charge 10%', '฿${bill.serviceChargeAmount.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          _summaryRow('ส่วนลดโปรฯ', '−฿${bill.discountAmount.toStringAsFixed(2)}', isNegative: true),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'รวมสุทธิ',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.ink),
              ),
              Text(
                '฿${bill.grandTotal.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isNegative = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: AppColors.ink2)),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isNegative ? AppColors.success : AppColors.ink,
          ),
        ),
      ],
    );
  }

  void _showEditItemDialog(BuildContext context, SplitBillProvider provider, BillItem item) {
    final nameCtrl = TextEditingController(text: item.name);
    final priceCtrl = TextEditingController(text: item.price.toStringAsFixed(2));
    final qtyCtrl = TextEditingController(text: item.quantity.toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) {
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
              const Text('แก้ไขรายการ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'ชื่อรายการ', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: priceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'ราคาต่อหน่วย (฿)', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: qtyCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'จำนวน', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
                onPressed: () {
                  final newPrice = double.tryParse(priceCtrl.text) ?? item.price;
                  final newQty = int.tryParse(qtyCtrl.text) ?? item.quantity;
                  provider.updateBillItem(item.id, name: nameCtrl.text, price: newPrice, quantity: newQty);
                  Navigator.pop(ctx);
                },
                child: const Text('บันทึกการแก้ไข'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddItemDialog(BuildContext context, SplitBillProvider provider) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) {
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
              const Text('เพิ่มรายการเอง', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'ชื่อรายการ เช่น ยำวุ้นเส้น', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'ราคา (฿)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
                onPressed: () {
                  final price = double.tryParse(priceCtrl.text) ?? 0.0;
                  if (nameCtrl.text.isNotEmpty && price > 0) {
                    provider.addBillItem(nameCtrl.text, price, 1);
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('เพิ่มรายการ'),
              ),
            ],
          ),
        );
      },
    );
  }
}
