import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/waveform_visualizer.dart';
import 'payment_screen.dart';

class ZeroInstallLandingScreen extends StatefulWidget {
  final String payerName;
  final String billTitle;
  final double amount;
  final String token;

  const ZeroInstallLandingScreen({
    super.key,
    this.payerName = 'ป๊อป',
    this.billTitle = 'หมูกระทะ ศุกร์',
    this.amount = 241.30,
    this.token = 'a7Kf9x',
  });

  @override
  State<ZeroInstallLandingScreen> createState() => _ZeroInstallLandingScreenState();
}

class _ZeroInstallLandingScreenState extends State<ZeroInstallLandingScreen> {
  bool _isPlaying = false;
  bool _showTranscript = false;

  void _togglePlay() {
    setState(() => _isPlaying = !_isPlaying);
    if (_isPlaying) {
      Future.delayed(const Duration(seconds: 9), () {
        if (mounted) setState(() => _isPlaying = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_rounded, size: 14, color: AppColors.success),
              const SizedBox(width: 6),
              Text(
                'splitbill.app/n/${widget.token}',
                style: const TextStyle(fontSize: 13, color: AppColors.ink2, fontFamily: 'monospace'),
              ),
            ],
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          children: [
            // Zero-Install Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '🌐 หน้าเว็บสำหรับเพื่อน (ไม่ต้องติดตั้งแอป)',
                style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),

            // Card Container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.xlBorder,
                border: Border.all(color: AppColors.line),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.primarySoft,
                    child: Text('🔵', style: TextStyle(fontSize: 26)),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${widget.payerName} ฝากข้อความเสียงถึงคุณ',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.ink),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '🍜 ${widget.billTitle}',
                    style: const TextStyle(fontSize: 13, color: AppColors.ink3),
                  ),
                  const SizedBox(height: 24),

                  // Big 92px Blue Play Button (PDD Section G.6)
                  GestureDetector(
                    onTap: _togglePlay,
                    child: Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Waveform
                  WaveformVisualizer(
                    isPlayingOrRecording: _isPlaying,
                    activeColor: AppColors.primary,
                    height: 36,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isPlaying ? 'กำลังเล่นข้อความเสียง…' : 'แตะเพื่อฟัง · 0:09',
                    style: const TextStyle(fontSize: 12.5, color: AppColors.ink3),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Divider(),
                  ),

                  // Target Amount
                  const Text('ยอดที่คุณต้องจ่าย', style: TextStyle(fontSize: 13, color: AppColors.ink3)),
                  const SizedBox(height: 4),
                  Text(
                    '฿${widget.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Action Buttons
                  ElevatedButton.icon(
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    label: const Text('เปิด QR พร้อมเพย์ สำหรับจ่ายเงิน', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PaymentScreen(
                            recipient: Member(
                              id: 'm_pop',
                              name: widget.payerName,
                              avatarEmoji: '🔵',
                              avatarColor: AppColors.primary,
                            ),
                            billTitle: widget.billTitle,
                            amount: widget.amount,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.line),
                            foregroundColor: AppColors.ink2,
                          ),
                          onPressed: () => setState(() => _showTranscript = !_showTranscript),
                          child: Text(_showTranscript ? 'ซ่อนข้อความ' : '📝 อ่านข้อความ'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.line),
                            foregroundColor: AppColors.ink2,
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('ส่งข้อความขอเลื่อนการจ่ายเงินไปยังเพื่อนแล้ว')),
                            );
                          },
                          child: const Text('⏰ ขอเลื่อน'),
                        ),
                      ),
                    ],
                  ),

                  if (_showTranscript) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.bg,
                        borderRadius: AppRadius.mdBorder,
                      ),
                      child: const Text(
                        '"สวัสดีเพื่อน อย่าลืมโอนค่าหมูกระทะ 241.30 บาทให้ด้วยนะ ขอบคุณมากจ้า"',
                        style: TextStyle(fontSize: 13, color: AppColors.ink2, height: 1.4),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Soft Install Prompt Card (PDD Section G.7 - Viral loop)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF5FF),
                borderRadius: AppRadius.mdBorder,
                border: Border.all(color: const Color(0xFFE9D5FF)),
              ),
              child: Row(
                children: [
                  const Text('✨', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ไม่ต้องโหลดแอปก็จ่ายได้',
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF6B21A8)),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'แต่ถ้าติดตั้ง SplitBill คุณจะเห็นยอดค้างทุกกลุ่มและประวัติทั้งหมดในที่เดียว',
                          style: TextStyle(fontSize: 12, color: Color(0xFF7E22CE)),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('เปิดหน้าดาวน์โหลดแอป SplitBill บน App Store / Play Store')),
                      );
                    },
                    child: const Text('ลองดู →', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6B21A8))),
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
}
