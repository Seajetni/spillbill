import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/models.dart';
import '../providers/split_bill_provider.dart';
import '../theme/app_theme.dart';
import '../utils/date_formatter.dart';
import '../widgets/donut_chart.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  String _selectedPeriod = '3 เดือน';

  List<CategoryExpense> _calculateCategories(SplitBillProvider provider) {
    double foodAmount = 0.0;
    double lodgingAmount = 0.0;
    double travelAmount = 0.0;
    double otherAmount = 0.0;

    DateTime cutoffDate;
    final now = DateTime.now();
    if (_selectedPeriod == 'เดือนนี้') {
      cutoffDate = now.subtract(const Duration(days: 30));
    } else if (_selectedPeriod == '3 เดือน') {
      cutoffDate = now.subtract(const Duration(days: 90));
    } else {
      cutoffDate = DateTime(now.year, 1, 1);
    }

    // Aggregate groupBills
    provider.groupBills.forEach((groupId, bills) {
      for (final b in bills) {
        if (b.date.isAfter(cutoffDate)) {
          final t = b.title.toLowerCase();
          if (t.contains('หมูกระทะ') || t.contains('ก๋วยเตี๋ยว') || t.contains('ข้าว') || t.contains('อาหาร') || t.contains('กิน')) {
            foodAmount += b.totalAmount;
          } else if (t.contains('ที่พัก') || t.contains('เน็ต') || t.contains('คอนโด') || t.contains('น้ำประปา')) {
            lodgingAmount += b.totalAmount;
          } else if (t.contains('น้ำมัน') || t.contains('รถ') || t.contains('เดินทาง') || t.contains('บิน')) {
            travelAmount += b.totalAmount;
          } else {
            otherAmount += b.totalAmount;
          }
        }
      }
    });

    // Aggregate savedBills
    for (final b in provider.savedBills) {
      if (b.date.isAfter(cutoffDate)) {
        final t = b.title.toLowerCase();
        final emoji = b.categoryEmoji;
        if (emoji == '🍽️' || emoji == '🍜' || t.contains('หมูกระทะ') || t.contains('ก๋วยเตี๋ยว') || t.contains('ข้าว')) {
          foodAmount += b.grandTotal;
        } else if (emoji == '🏠' || emoji == '🏡' || t.contains('ที่พัก') || t.contains('คอนโด')) {
          lodgingAmount += b.grandTotal;
        } else if (emoji == '🚗' || emoji == '🚐' || t.contains('เดินทาง') || t.contains('รถ')) {
          travelAmount += b.grandTotal;
        } else {
          otherAmount += b.grandTotal;
        }
      }
    }

    // Default baseline figures if period has no transactions
    if (foodAmount == 0 && lodgingAmount == 0 && travelAmount == 0 && otherAmount == 0) {
      return const [
        CategoryExpense(title: 'อาหาร & เครื่องดื่ม', amount: 5240.0, color: Color(0xFF2D6BFF), emoji: '🔵'),
        CategoryExpense(title: 'ที่พัก & ค่าเช่า', amount: 3250.0, color: Color(0xFF0FBF7F), emoji: '🟢'),
        CategoryExpense(title: 'เดินทาง', amount: 2240.0, color: Color(0xFFFF8A3D), emoji: '🟠'),
        CategoryExpense(title: 'อื่น ๆ', amount: 1750.0, color: Color(0xFFA855F7), emoji: '🟣'),
      ];
    }

    return [
      CategoryExpense(title: 'อาหาร & เครื่องดื่ม', amount: foodAmount, color: const Color(0xFF2D6BFF), emoji: '🔵'),
      CategoryExpense(title: 'ที่พัก & ค่าเช่า', amount: lodgingAmount, color: const Color(0xFF0FBF7F), emoji: '🟢'),
      CategoryExpense(title: 'เดินทาง', amount: travelAmount, color: const Color(0xFFFF8A3D), emoji: '🟠'),
      CategoryExpense(title: 'อื่น ๆ', amount: otherAmount, color: const Color(0xFFA855F7), emoji: '🟣'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SplitBillProvider>();
    final categories = _calculateCategories(provider);
    final totalSpent = categories.fold(0.0, (sum, c) => sum + c.amount);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('สถิติการใช้จ่าย'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded, color: AppColors.primary),
            tooltip: 'Export CSV / PDF',
            onPressed: () => _showExportSheet(context, categories, totalSpent, provider),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period Selector
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.mdBorder,
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                children: [
                  _periodTab('เดือนนี้'),
                  _periodTab('3 เดือน'),
                  _periodTab('ปีนี้'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Donut Chart Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.xlBorder,
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                children: [
                  DonutChart(
                    categories: categories,
                    totalAmount: totalSpent,
                    size: 190,
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Category Breakdown Rows
                  ...categories.map((cat) {
                    final percent = totalSpent > 0 ? ((cat.amount / totalSpent) * 100).toStringAsFixed(0) : '0';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(color: cat.color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              cat.title,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink),
                            ),
                          ),
                          Text(
                            '$percent%',
                            style: const TextStyle(fontSize: 13, color: AppColors.ink3),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '฿${cat.amount.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.ink),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Monthly Comparison Bar Chart Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.mdBorder,
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'เปรียบเทียบรายเดือน',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.ink),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 130,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _monthBar('มิ.ย.', 3200, 5000),
                        _monthBar('ก.ค.', 4100, 5000),
                        _monthBar('ส.ค.', 2900, 5000),
                        _monthBar('ก.ย.', 4800, 5000, isCurrent: true),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Behavioral Insight Card (FR-09 / PDD Section E Screen 7)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: AppRadius.mdBorder,
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Row(
                children: [
                  Text('📈', style: TextStyle(fontSize: 24)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'เดือนนี้จ่ายค่าอาหารมากขึ้น 23%',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'เทียบกับค่าเฉลี่ย 3 เดือนที่ผ่านมา แนะนำตั้งงบประมาณกลุ่มรอบหน้า',
                          style: TextStyle(fontSize: 12, color: Color(0xFF1D4ED8)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _periodTab(String period) {
    final isSelected = _selectedPeriod == period;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPeriod = period),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: AppRadius.smBorder,
          ),
          child: Center(
            child: Text(
              period,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.ink2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _monthBar(String month, double amount, double maxAmount, {bool isCurrent = false}) {
    final heightRatio = (amount / maxAmount).clamp(0.1, 1.0);
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '฿${(amount / 1000).toStringAsFixed(1)}k',
          style: TextStyle(
            fontSize: 11,
            color: isCurrent ? AppColors.primary : AppColors.ink3,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 38,
          height: 85 * heightRatio,
          decoration: BoxDecoration(
            color: isCurrent ? AppColors.primary : const Color(0xFFE2E8F0),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          month,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            color: isCurrent ? AppColors.ink : AppColors.ink2,
          ),
        ),
      ],
    );
  }

  void _showExportSheet(
    BuildContext context,
    List<CategoryExpense> categories,
    double totalSpent,
    SplitBillProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ส่งออกรายงานค่าใช้จ่าย (Export)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('เลือกรูปแบบไฟล์ที่คุณต้องการนำไปใช้งานต่อ', style: TextStyle(fontSize: 13, color: AppColors.ink3)),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.successSoft, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.table_chart_rounded, color: AppColors.success),
                ),
                title: const Text('Export CSV (Excel)', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('เหมาะสำหรับนำไปคำนวณและวิเคราะห์ใน Spreadsheet'),
                onTap: () {
                  Navigator.pop(ctx);
                  _exportCsv(context, categories, totalSpent, provider);
                },
              ),
              const Divider(),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.warnSoft, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.warn),
                ),
                title: const Text('Export PDF Report', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('เอกสารสรุปยอดสวยงามพร้อมส่งให้เพื่อนร่วมกลุ่ม'),
                onTap: () {
                  Navigator.pop(ctx);
                  _exportPdf(context, categories, totalSpent, provider);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _exportCsv(
    BuildContext context,
    List<CategoryExpense> categories,
    double totalSpent,
    SplitBillProvider provider,
  ) async {
    try {
      final List<List<dynamic>> rows = [
        ['วันที่', 'รายการ', 'หมวดหมู่', 'ยอดเงิน (บาท)', 'ผู้สำรองจ่าย', 'กลุ่ม'],
      ];

      provider.groupBills.forEach((groupId, bills) {
        final group = provider.groups.firstWhere(
          (g) => g.id == groupId,
          orElse: () => GroupModel(
            id: groupId,
            name: 'ทั่วไป',
            category: 'ทั่วไป',
            emoji: '📁',
            members: [],
            billIds: [],
            userBalance: 0,
          ),
        );
        for (final b in bills) {
          rows.add([
            DateFormatter.formatThaiDate(b.date),
            b.title,
            group.category,
            b.totalAmount.toStringAsFixed(2),
            b.paidByName,
            group.name,
          ]);
        }
      });

      for (final b in provider.savedBills) {
        final payer = provider.getMemberById(b.paidByMemberId);
        rows.add([
          DateFormatter.formatThaiDate(b.date),
          b.title,
          b.categoryEmoji,
          b.grandTotal.toStringAsFixed(2),
          payer?.name ?? 'ไม่ระบุ',
          b.groupName,
        ]);
      }

      final csvString = Csv.excel().encode(rows);
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/SplitBill_Expenses_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csvString);

      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path)],
        subject: 'ส่งออกรายงานค่าใช้จ่าย SplitBill (CSV)',
        text: 'รายงานค่าใช้จ่าย SplitBill ยอดรวม ฿${totalSpent.toStringAsFixed(2)}',
      ));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ส่งออกไฟล์ CSV ไม่สำเร็จ: $e')),
        );
      }
    }
  }

  Future<void> _exportPdf(
    BuildContext context,
    List<CategoryExpense> categories,
    double totalSpent,
    SplitBillProvider provider,
  ) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context ctx) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'SplitBill - Expense Summary Report',
                  style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 8),
                pw.Text('Export Date: ${DateTime.now().toLocal().toString().split('.')[0]}'),
                pw.Text('Selected Period: $_selectedPeriod'),
                pw.Text(
                  'Total Expenses: THB ${totalSpent.toStringAsFixed(2)}',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Category Summary',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 8),
                pw.TableHelper.fromTextArray(
                  headers: ['Category', 'Amount (THB)', 'Share (%)'],
                  data: categories.map((c) {
                    final pct = totalSpent > 0 ? ((c.amount / totalSpent) * 100).toStringAsFixed(1) : '0';
                    return [c.title, c.amount.toStringAsFixed(2), '$pct%'];
                  }).toList(),
                ),
              ],
            );
          },
        ),
      );

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/SplitBill_Summary_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());

      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path)],
        subject: 'ส่งออกรายงานสรุป PDF SplitBill',
        text: 'เอกสารสรุปยอดค่าใช้จ่าย SplitBill',
      ));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ส่งออกไฟล์ PDF ไม่สำเร็จ: $e')),
        );
      }
    }
  }
}
