import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../screens/voice_receiver_screen.dart';
import '../theme/app_theme.dart';

/// Shows a bottom sheet after submitting a Voice Nudge,
/// allowing the user to share the voice file and payment info
/// directly to friends via LINE/Messenger, copy the details,
/// or preview the receiver view.
void showVoiceNudgeShareModal({
  required BuildContext context,
  required String targetName,
  required String billTitle,
  required double amount,
  required String transcript,
  required int durationSeconds,
  required String? audioPath,
  required String persona,
  required String nudgeId,
  String promptPayNumber = '081-234-5678',
  String senderName = 'ป๊อป',
}) {
  final shareUrl = 'https://spillbill.vercel.app/n/$nudgeId';
  final ppLine = promptPayNumber.isNotEmpty
      ? '🏦 พร้อมเพย์ (PromptPay): $promptPayNumber\n'
      : '';
  final shareText = '''🔊 ข้อความเสียงทวงเงินจาก $senderName
📋 รายการ: $billTitle
💰 ยอดที่ต้องชำระ: ฿${amount.toStringAsFixed(2)}
💬 ข้อความ ($persona): "$transcript"
$ppLine👉 ฟังเสียงและชำระเงินได้ทันที (ไม่ต้องติดตั้งแอป):
$shareUrl''';

  final bool hasAudioFile = audioPath != null &&
      !kIsWeb &&
      !audioPath.startsWith('http') &&
      File(audioPath).existsSync() &&
      File(audioPath).lengthSync() > 100;

  Future<void> doShare() async {
    try {
      if (hasAudioFile) {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(audioPath)],
            text: shareText,
            subject: 'แจ้งเตือนค่าใช้จ่าย: $billTitle',
          ),
        );
      } else {
        await SharePlus.instance.share(
          ShareParams(
            text: shareText,
            subject: 'แจ้งเตือนค่าใช้จ่าย: $billTitle',
          ),
        );
      }
    } catch (e) {
      debugPrint('Share error: $e');
      await SharePlus.instance.share(
        ShareParams(
          text: shareText,
          subject: 'แจ้งเตือนค่าใช้จ่าย: $billTitle',
        ),
      );
    }
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetCtx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: 58,
              height: 58,
              decoration: const BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🎉', style: TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'สร้างเสียงทวงเงินสำเร็จแล้ว!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'ส่งให้ $targetName ผ่าน LINE หรือแชท เพื่อให้เพื่อนเปิดฟังเสียงและสแกนจ่ายเงินได้ทันที',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.ink2, height: 1.4),
            ),
            const SizedBox(height: 16),

            // Bill & Audio Summary Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: AppRadius.mdBorder,
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              billTitle,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.ink,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'เสียงสไตล์ $persona · 0:${durationSeconds.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.ink3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '฿${amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (promptPayNumber.isNotEmpty) ...[
                    const Divider(height: 18),
                    Row(
                      children: [
                        const Icon(Icons.account_balance_wallet_outlined, size: 16, color: AppColors.ink3),
                        const SizedBox(width: 6),
                        Text(
                          'PromptPay: $promptPayNumber',
                          style: const TextStyle(fontSize: 12.5, color: AppColors.ink2),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Primary: Share to LINE / Chat (with Audio attachment)
            ElevatedButton.icon(
              icon: Icon(hasAudioFile ? Icons.send_rounded : Icons.share_rounded, size: 18),
              label: Text(
                hasAudioFile
                    ? 'แชร์ให้ $targetName (LINE / แชท + ไฟล์เสียง 🔊)'
                    : 'แชร์ให้ $targetName (LINE / แชท) ↗',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.mdBorder,
                ),
              ),
              onPressed: doShare,
            ),
            const SizedBox(height: 10),

            // Copy Full Text Button
            OutlinedButton.icon(
              icon: const Icon(Icons.copy_rounded, size: 17),
              label: const Text(
                'คัดลอกข้อความทวงเงิน + ยอดบัญชี 📋',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 46),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.mdBorder,
                ),
              ),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: shareText));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('คัดลอกข้อความสรุปยอดแล้ว วางในแชทให้เพื่อนได้ทันที 📋'),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),

            // Preview Receiver View Button
            TextButton.icon(
              icon: const Icon(Icons.visibility_rounded, size: 17, color: AppColors.ink2),
              label: const Text(
                'ดูตัวอย่างหน้าจอที่เพื่อนจะเห็น (Receiver Preview)',
                style: TextStyle(fontSize: 13, color: AppColors.ink2),
              ),
              onPressed: () {
                Navigator.pop(sheetCtx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VoiceReceiverScreen(
                      senderName: senderName,
                      billTitle: billTitle,
                      amount: amount,
                      transcript: transcript,
                      durationSeconds: durationSeconds,
                      audioPath: audioPath,
                      persona: persona,
                      isPreview: true,
                      promptPayNumber: promptPayNumber,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 4),

            // Back to Home
            TextButton(
              onPressed: () {
                Navigator.pop(sheetCtx);
                Navigator.pop(context);
              },
              child: const Text(
                'เสร็จสิ้น (กลับหน้าหลัก)',
                style: TextStyle(color: AppColors.ink3, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
