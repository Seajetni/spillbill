import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../providers/split_bill_provider.dart';
import '../theme/app_theme.dart';
import '../utils/promptpay_qr.dart';

class PaymentScreen extends StatefulWidget {
  final Member recipient;
  final String billTitle;
  final double amount;
  final String? debtId;

  const PaymentScreen({
    super.key,
    required this.recipient,
    required this.billTitle,
    required this.amount,
    this.debtId,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final GlobalKey _qrBoundaryKey = GlobalKey();
  bool _isSlipAttached = false;
  XFile? _slipImage;
  bool _isSavingQr = false;

  Future<void> _saveQrCodeImage() async {
    setState(() => _isSavingQr = true);
    try {
      final boundary = _qrBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('ไม่พบคอนเทนต์สำหรับบันทึกภาพ');
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('ไม่สามารถสร้างไฟล์รูปภาพได้');
      }

      final pngBytes = byteData.buffer.asUint8List();

      final hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) {
        final granted = await Gal.requestAccess(toAlbum: true);
        if (!granted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('กรุณาให้สิทธิ์เข้าถึงคลังรูปภาพเพื่อบันทึก QR Code')),
            );
          }
          return;
        }
      }

      await Gal.putImageBytes(
        pngBytes,
        name: 'SplitBill_QR_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('บันทึกรูป QR Code ลงในคลังภาพเรียบร้อยแล้ว 📸'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('บันทึกรูปไม่สำเร็จ: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingQr = false);
      }
    }
  }

  Future<void> _pickSlipImage(SplitBillProvider provider) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (picked != null) {
        setState(() {
          _slipImage = picked;
          _isSlipAttached = true;
        });

        if (widget.debtId != null) {
          provider.markDebtSettled(widget.debtId!);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('แนบสลิปและยืนยันการชำระเงินเรียบร้อยแล้ว 🎉'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เลือกรูปภาพไม่สำเร็จ: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<SplitBillProvider>();
    final promptPayTarget = widget.recipient.promptPayNumber ?? provider.userPromptPay;
    final qrPayload = PromptPayQR.generatePayload(promptPayTarget, amount: widget.amount);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('ชำระเงิน'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'แชร์ข้อมูลการชำระเงิน',
            onPressed: () async {
              final shareText = '🧾 ข้อมูลชำระเงินบิล: ${widget.billTitle}\n'
                  '💰 ยอดเงิน: ฿${widget.amount.toStringAsFixed(2)}\n'
                  '👤 ผู้รับ: ${widget.recipient.name}\n'
                  '📱 พร้อมเพย์: $promptPayTarget\n\n'
                  'จัดการบิลร่วมกันง่าย ๆ ผ่านแอป SplitBill';
              await SharePlus.instance.share(ShareParams(text: shareText, subject: 'ชำระเงินบิล ${widget.billTitle}'));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            // QR & Amount Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.xlBorder,
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: widget.recipient.avatarColor.withValues(alpha: 0.15),
                    child: Text(widget.recipient.avatarEmoji, style: const TextStyle(fontSize: 24)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.recipient.name} ขอเก็บค่า',
                    style: const TextStyle(fontSize: 14, color: AppColors.ink2),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.billTitle,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.ink),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '฿${widget.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // PromptPay QR Code with RepaintBoundary
                  RepaintBoundary(
                    key: _qrBoundaryKey,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: AppRadius.mdBorder,
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF003D79),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'พร้อมเพย์ PromptPay',
                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: 170,
                            height: 170,
                            child: QrImageView(
                              data: qrPayload,
                              version: QrVersions.auto,
                              eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: AppColors.ink,
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'พร้อมเพย์: $promptPayTarget (${widget.recipient.name})',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.ink),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ฝังยอดเงินมาแล้ว ฿${widget.amount.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 11, color: AppColors.ink3, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'สแกนด้วยแอปธนาคารใดก็ได้',
                    style: TextStyle(fontSize: 13, color: AppColors.ink3),
                  ),
                  const SizedBox(height: 16),

                  // Quick Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: _isSavingQr
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.download_rounded, size: 16),
                          label: Text(_isSavingQr ? 'กำลังบันทึก...' : 'บันทึก QR', style: const TextStyle(fontSize: 13)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.line),
                            foregroundColor: AppColors.ink,
                          ),
                          onPressed: _isSavingQr ? null : _saveQrCodeImage,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.account_balance_rounded, size: 16),
                          label: const Text('เปิดแอปธนาคาร', style: TextStyle(fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                          ),
                          onPressed: () => _showBankPickerSheet(context, promptPayTarget),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Itemized Breakdown Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.mdBorder,
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'รายการที่คุณต้องจ่าย',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.ink),
                  ),
                  const SizedBox(height: 12),
                  _itemRow('ต้มยำกุ้ง (แชร์ 2 คน)', '฿140.00'),
                  const SizedBox(height: 8),
                  _itemRow('ส้มตำไทย (แชร์ 2 คน)', '฿60.00'),
                  const SizedBox(height: 8),
                  _itemRow('น้ำเปล่า (แชร์ 4 คน)', '฿15.00'),
                  const SizedBox(height: 8),
                  _itemRow('VAT + Service (ตามสัดส่วน)', '฿26.30'),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('รวมสุทธิ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      Text(
                        '฿${widget.amount.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Attach Slip Action
            if (!_isSlipAttached)
              OutlinedButton.icon(
                icon: const Icon(Icons.attach_file_rounded, color: AppColors.primary),
                label: const Text('📎 แนบสลิปยืนยันการโอนเงิน', style: TextStyle(fontSize: 15, color: AppColors.primary)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
                ),
                onPressed: () => _pickSlipImage(provider),
              )
            else
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.successSoft,
                  borderRadius: AppRadius.mdBorder,
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    if (_slipImage != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: kIsWeb
                            ? Image.network(_slipImage!.path, width: 44, height: 44, fit: BoxFit.cover)
                            : Image.file(File(_slipImage!.path), width: 44, height: 44, fit: BoxFit.cover),
                      )
                    else
                      const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 36),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('แนบสลิปเรียบร้อยแล้ว 🎉', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.success)),
                          Text('บันทึกยอดชำระแล้ว รอยืนยันจากผู้รับเงิน', style: TextStyle(fontSize: 12, color: AppColors.ink2)),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => _pickSlipImage(provider),
                      child: const Text('เปลี่ยนรูป', style: TextStyle(color: AppColors.primary)),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _itemRow(String title, String price) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 13.5, color: AppColors.ink2)),
        Text(price, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.ink)),
      ],
    );
  }

  void _showBankPickerSheet(BuildContext context, String promptPayTarget) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('เลือกแอปธนาคารสำหรับจ่ายเงิน', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text('ระบบจะพยายามเปิดแอปธนาคารของคุณผ่าน Deep Link', style: TextStyle(fontSize: 13, color: AppColors.ink3)),
              const SizedBox(height: 16),
              _bankTile(ctx, 'SCB Easy', 'ธนาคารไทยพาณิชย์', const Color(0xFF4E2E80), 'scbeasy://', promptPayTarget),
              _bankTile(ctx, 'K PLUS', 'ธนาคารกสิกรไทย', const Color(0xFF138F2D), 'kplus://', promptPayTarget),
              _bankTile(ctx, 'KMA krungsri', 'ธนาคารกรุงศรีอยุธยา', const Color(0xFFFEC300), 'kma://', promptPayTarget),
              _bankTile(ctx, 'ttb touch', 'ธนาคารทหารไทยธนชาต', const Color(0xFF0056B3), 'ttbtouch://', promptPayTarget),
            ],
          ),
        );
      },
    );
  }

  Widget _bankTile(
    BuildContext sheetContext,
    String bankName,
    String fullName,
    Color color,
    String scheme,
    String promptPayTarget,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
        child: Center(
          child: Text(
            bankName.substring(0, 1),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
      ),
      title: Text(bankName, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(fullName, style: const TextStyle(fontSize: 12, color: AppColors.ink3)),
      trailing: const Icon(Icons.open_in_new_rounded, size: 18, color: AppColors.ink3),
      onTap: () async {
        Navigator.pop(sheetContext);
        final uri = Uri.parse(scheme);
        try {
          final canLaunch = await canLaunchUrl(uri);
          if (canLaunch) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('ไม่พบแอป $bankName ในเครื่อง กรุณาเปิดแอปเพื่อโอนเงินด้วยตนเอง'),
                  action: SnackBarAction(
                    label: 'คัดลอกเบอร์',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: promptPayTarget));
                    },
                  ),
                ),
              );
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('ไม่สามารถเปิดแอป $bankName ได้ ($e)')),
            );
          }
        }
      },
    );
  }
}
