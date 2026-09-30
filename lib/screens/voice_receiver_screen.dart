import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/models.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';
import '../widgets/waveform_visualizer.dart';
import 'payment_screen.dart';

class VoiceReceiverScreen extends StatefulWidget {
  final String senderName;
  final String billTitle;
  final double amount;
  final String transcript;
  final int durationSeconds;
  final String? audioPath;
  final String persona;
  final bool isPreview;
  final String? promptPayNumber;

  const VoiceReceiverScreen({
    super.key,
    required this.senderName,
    required this.billTitle,
    required this.amount,
    required this.transcript,
    this.durationSeconds = 9,
    this.audioPath,
    this.persona = 'น้องนุ่ม',
    this.isPreview = false,
    this.promptPayNumber,
  });

  @override
  State<VoiceReceiverScreen> createState() => _VoiceReceiverScreenState();
}

class _VoiceReceiverScreenState extends State<VoiceReceiverScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TtsService _ttsService = TtsService();
  StreamSubscription? _playerCompleteSub;

  bool _isPlaying = false;
  bool _receiveAudio = true;
  bool _quietHours = true;
  bool _autoPlay = false;

  @override
  void initState() {
    super.initState();
    _playerCompleteSub = _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlaying = false);
    });

    if (_autoPlay) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _togglePlay();
      });
    }
  }

  @override
  void dispose() {
    _playerCompleteSub?.cancel();
    _audioPlayer.dispose();
    _ttsService.stop();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (!_receiveAudio) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'คุณปิดการรับข้อความเสียงอยู่ สามารถอ่านข้อความถอดเสียงด้านล่างได้',
          ),
        ),
      );
      return;
    }

    if (_isPlaying) {
      await _audioPlayer.stop();
      await _ttsService.stop();
      setState(() => _isPlaying = false);
    } else {
      setState(() => _isPlaying = true);

      final path = widget.audioPath;
      final isWebOrUrl = path != null &&
          (kIsWeb || path.startsWith('blob:') || path.startsWith('http'));
      final hasLocalFile = path != null &&
          !kIsWeb &&
          !path.startsWith('blob:') &&
          !path.startsWith('http') &&
          File(path).existsSync() &&
          File(path).lengthSync() > 100;

      if (isWebOrUrl) {
        try {
          await _audioPlayer.setVolume(1.0);
          await _audioPlayer.play(UrlSource(path));
        } catch (e) {
          debugPrint('Error playing web audioPath in receiver: $e');
          await _ttsService.speak(
            widget.transcript,
            onComplete: () {
              if (mounted) setState(() => _isPlaying = false);
            },
          );
        }
      } else if (hasLocalFile) {
        try {
          await _audioPlayer.setVolume(1.0);
          final file = File(path);
          try {
            await _audioPlayer.play(DeviceFileSource(path));
          } catch (e) {
            final bytes = await file.readAsBytes();
            await _audioPlayer.play(BytesSource(bytes));
          }
        } catch (e) {
          debugPrint('Error playing audioPath in receiver: $e');
          await _ttsService.speak(
            widget.transcript,
            onComplete: () {
              if (mounted) setState(() => _isPlaying = false);
            },
          );
        }
      } else if (widget.transcript.isNotEmpty) {
        await _ttsService.speak(
          widget.transcript,
          onComplete: () {
            if (mounted) setState(() => _isPlaying = false);
          },
        );
      } else {
        Future.delayed(Duration(seconds: widget.durationSeconds), () {
          if (mounted) setState(() => _isPlaying = false);
        });
      }
    }
  }

  Future<void> _shareNudge() async {
    final shareUrl =
        'https://spillbill.vercel.app/n/vn_${DateTime.now().millisecondsSinceEpoch}';
    final pp = widget.promptPayNumber ?? '081-234-5678';
    final shareText = '''🔊 ข้อความเสียงทวงเงินจาก ${widget.senderName}
📋 รายการ: ${widget.billTitle}
💰 ยอดที่ต้องชำระ: ฿${widget.amount.toStringAsFixed(2)}
💬 ข้อความ (${widget.persona}): "${widget.transcript}"
🏦 PromptPay: $pp

👉 ฟังเสียงและชำระเงินได้ทันที (ไม่ต้องติดตั้งแอป):
$shareUrl''';

    final path = widget.audioPath;
    final hasAudioFile = path != null &&
        !kIsWeb &&
        !path.startsWith('http') &&
        File(path).existsSync() &&
        File(path).lengthSync() > 100;

    try {
      if (hasAudioFile) {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(path)],
            text: shareText,
            subject: 'แจ้งเตือนค่าใช้จ่าย: ${widget.billTitle}',
          ),
        );
      } else {
        await SharePlus.instance.share(
          ShareParams(
            text: shareText,
            subject: 'แจ้งเตือนค่าใช้จ่าย: ${widget.billTitle}',
          ),
        );
      }
    } catch (e) {
      debugPrint('Share error in receiver screen: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(widget.isPreview
            ? 'ตัวอย่างหน้าจอฝั่งเพื่อน'
            : 'ข้อความเสียง (Voice Nudge)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            _audioPlayer.stop();
            _ttsService.stop();
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'แชร์ให้เพื่อน (LINE / แชท)',
            onPressed: _shareNudge,
          ),
          IconButton(
            icon: Icon(
              _receiveAudio
                  ? Icons.volume_up_rounded
                  : Icons.volume_off_rounded,
            ),
            onPressed: () {
              setState(() => _receiveAudio = !_receiveAudio);
              if (!_receiveAudio && _isPlaying) {
                _audioPlayer.stop();
                _ttsService.stop();
                setState(() => _isPlaying = false);
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            if (widget.isPreview)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: AppRadius.mdBorder,
                  border: Border.all(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.visibility_rounded,
                        color: Color(0xFFD97706), size: 20),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'คุณกำลังดูตัวอย่างหน้าจอที่เพื่อนจะเห็น (Receiver View)',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: _shareNudge,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.share_rounded,
                                size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'แชร์เลย',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Voice Message Hero Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.xlBorder,
                border:
                    Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: AppColors.primarySoft,
                        child: Text('🔵', style: TextStyle(fontSize: 16)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${widget.senderName} ส่งเสียงทวง',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.ink,
                              ),
                            ),
                            Text(
                              '${widget.billTitle} · 5 นาทีที่แล้ว',
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.ink3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _isPlaying
                              ? Icons.pause_circle_filled_rounded
                              : Icons.play_circle_filled_rounded,
                          color: AppColors.primary,
                          size: 40,
                        ),
                        onPressed: _togglePlay,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Waveform
                  WaveformVisualizer(
                    isPlayingOrRecording: _isPlaying,
                    activeColor: AppColors.primary,
                    height: 38,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '0:${widget.durationSeconds.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.ink3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Divider(height: 24),

                  // Amount & Pay Now Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ยอดที่ต้องจ่าย',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.ink3,
                            ),
                          ),
                          Text(
                            '฿${widget.amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.mdBorder,
                          ),
                        ),
                        onPressed: () {
                          _audioPlayer.stop();
                          _ttsService.stop();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PaymentScreen(
                                recipient: Member(
                                  id: 'm_pop',
                                  name: widget.senderName,
                                  avatarEmoji: '🔵',
                                  avatarColor: AppColors.primary,
                                ),
                                billTitle: widget.billTitle,
                                amount: widget.amount,
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          'จ่ายเลย',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Transcript Section (Accessibility requirement)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.mdBorder,
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text('📝', style: TextStyle(fontSize: 16)),
                      SizedBox(width: 8),
                      Text(
                        'ถอดข้อความอัตโนมัติ (Transcript)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '"${widget.transcript}"',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.ink2,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '💡 ฟังไม่สะดวก? สามารถอ่านข้อความแทนได้เสมอ',
                    style: TextStyle(fontSize: 12, color: AppColors.ink3),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Quick Replies (PDD Section F.6 Screen 10)
            Container(
              width: double.infinity,
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
                    'ตอบกลับเร็ว (Quick Reply)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _quickReplyBtn('💸 โอนแล้ว', () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'ส่งข้อความ "โอนแล้ว" ไปยังเพื่อนเรียบร้อย',
                            ),
                          ),
                        );
                      }),
                      _quickReplyBtn('⏰ ขอ 3 วัน', () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('ส่งคำขอเลื่อน 3 วัน ไปยังเพื่อนเรียบร้อย'),
                          ),
                        );
                      }),
                      _quickReplyBtn('😅 ลืมสนิท ขอโทษที', () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('ส่งข้อความขอโทษไปยังเพื่อน')),
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Voice Settings
            Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.mdBorder,
                side: const BorderSide(color: AppColors.line),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'การตั้งค่าเสียงของฉัน',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'รับข้อความเสียง',
                        style: TextStyle(fontSize: 14),
                      ),
                      value: _receiveAudio,
                      onChanged: (v) {
                        setState(() => _receiveAudio = v);
                        if (!v && _isPlaying) {
                          _audioPlayer.stop();
                          _ttsService.stop();
                          setState(() => _isPlaying = false);
                        }
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'ห้ามรบกวน 22:00–08:00',
                        style: TextStyle(fontSize: 14),
                      ),
                      subtitle: const Text(
                        'ปิดเสียงแจ้งเตือนช่วงเวลานี้',
                        style: TextStyle(fontSize: 12, color: AppColors.ink3),
                      ),
                      value: _quietHours,
                      onChanged: (v) => setState(() => _quietHours = v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'เล่นเสียงอัตโนมัติ',
                        style: TextStyle(fontSize: 14),
                      ),
                      value: _autoPlay,
                      onChanged: (v) => setState(() => _autoPlay = v),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _quickReplyBtn(String text, VoidCallback onTap) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        side: const BorderSide(color: AppColors.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onTap,
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
    );
  }
}
