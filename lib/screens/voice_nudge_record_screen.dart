import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/split_bill_provider.dart';
import '../services/audio_service.dart';
import '../services/nudge_sync_service.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';
import '../widgets/waveform_visualizer.dart';
import '../widgets/voice_nudge_share_modal.dart';
import 'voice_nudge_ai_screen.dart';

class VoiceNudgeRecordScreen extends StatefulWidget {
  final DebtRecord debt;

  const VoiceNudgeRecordScreen({super.key, required this.debt});

  @override
  State<VoiceNudgeRecordScreen> createState() => _VoiceNudgeRecordScreenState();
}

class _VoiceNudgeRecordScreenState extends State<VoiceNudgeRecordScreen>
    with SingleTickerProviderStateMixin {
  final AudioService _audioService = AudioService();
  final TtsService _ttsService = TtsService();

  bool _isRecording = false;
  bool _hasRecorded = false;
  bool _isPlaying = false;
  int _recordSeconds = 0;
  final int _maxSeconds = 15;
  Timer? _timer;
  String _selectedEffect = 'ปกติ';
  String? _recordedFilePath;

  final List<String> _effects = [
    'ปกติ',
    '🐿ชิพมังก์',
    '🎩ทุ้มลึก',
    '📻วิทยุเก่า',
    '🎪ห้องโถง',
  ];

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
      lowerBound: 1.0,
      upperBound: 1.2,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _audioService.stopPlayback();
    _ttsService.stop();
    if (_isRecording) {
      _audioService.stopRecording();
    }
    super.dispose();
  }

  String get _defaultTranscript =>
      'สวัสดีจ้า ${widget.debt.fromMember.name} อย่าลืมโอนค่า${widget.debt.billTitle.replaceAll(RegExp(r'[^a-zA-Zก-๙0-9 ]'), '')} ${widget.debt.amount.toStringAsFixed(0)} บาท ให้ด้วยนะ ขอบคุณจ้า';

  void _toggleRecording() {
    if (_isRecording) {
      _stopRecording();
    } else {
      _startRecording();
    }
  }

  Future<void> _startRecording() async {
    final started = await _audioService.startRecording();
    if (!started && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'ไม่พบไมโครโฟนหรือยังไม่ได้อนุญาตสิทธิ์ (ระบบเปิดโหมดจำลองเสียงพูดภาษาไทยให้อัตโนมัติ)',
          ),
        ),
      );
    }

    setState(() {
      _isRecording = true;
      _recordSeconds = 0;
      _hasRecorded = false;
      _isPlaying = false;
    });
    _pulseController.repeat(reverse: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        _recordSeconds++;
        if (_recordSeconds >= _maxSeconds) {
          _stopRecording();
        }
      });
    });
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    _pulseController.stop();
    _pulseController.value = 1.0;

    final path = await _audioService.stopRecording();
    String? validPath = path;

    // Verify if the recorded file has actual audio content
    bool hasValidAudio = false;
    if (validPath != null) {
      if (kIsWeb ||
          validPath.startsWith('blob:') ||
          validPath.startsWith('http')) {
        hasValidAudio = validPath.isNotEmpty;
      } else {
        final file = File(validPath);
        if (await file.exists() && await file.length() > 300) {
          hasValidAudio = true;
        }
      }
    }

    // If recording produced empty/no file (e.g. no mic hardware on PC or simulator),
    // synthesize a high quality Thai voice MP3 file immediately so preview ALWAYS has sound!
    if (!hasValidAudio) {
      try {
        validPath = await _ttsService.synthesizeToAudioFile(
          _defaultTranscript,
          persona: 'เพื่อนซี้',
        );
      } catch (e) {
        debugPrint('Fallback TTS synthesis error: $e');
      }
    }

    if (mounted) {
      setState(() {
        _isRecording = false;
        _hasRecorded = true;
        _recordedFilePath = validPath;
      });
    }
  }

  Future<void> _togglePlayback() async {
    if (!_hasRecorded) return;

    if (_isPlaying) {
      await _audioService.stopPlayback();
      await _ttsService.stop();
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    } else {
      setState(() {
        _isPlaying = true;
      });

      final hasValidRecordedAudio = _recordedFilePath != null &&
          (kIsWeb ||
              _recordedFilePath!.startsWith('blob:') ||
              _recordedFilePath!.startsWith('http') ||
              (File(_recordedFilePath!).existsSync() &&
                  File(_recordedFilePath!).lengthSync() > 100));

      if (hasValidRecordedAudio) {
        await _audioService.playFile(
          _recordedFilePath!,
          effect: _selectedEffect,
          onComplete: () {
            if (mounted) setState(() => _isPlaying = false);
          },
        );
      } else {
        // Direct spoken fallback with Thai voice
        await _ttsService.speak(
          _defaultTranscript,
          persona: 'เพื่อนซี้',
          onComplete: () {
            if (mounted) setState(() => _isPlaying = false);
          },
        );
      }
    }
  }

  void _submitVoiceNudge() {
    final nudge = VoiceNudgeData(
      id: 'vn_${DateTime.now().millisecondsSinceEpoch}',
      targetMember: widget.debt.fromMember,
      amount: widget.debt.amount,
      billTitle: widget.debt.billTitle,
      daysOverdue: widget.debt.daysOverdue,
      mode: 'self',
      persona: 'อัดเอง',
      soundEffect: _selectedEffect,
      transcript: _defaultTranscript,
      durationSeconds: _recordSeconds > 0 ? _recordSeconds : 7,
      ladder: EscalationLadder.normal,
      audioPath: _recordedFilePath,
      isSent: true,
    );

    final provider = context.read<SplitBillProvider>();
    provider.addVoiceNudge(nudge);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('อัดเสียงทวงเรียบร้อยแล้ว 🔊 พร้อมแชร์ให้เพื่อน'),
      ),
    );

    // Background sync to Vercel + MongoDB Atlas
    NudgeSyncService.syncNudgeToCloud(
      nudgeId: nudge.id,
      targetName: widget.debt.fromMember.name,
      senderName: 'ป๊อป',
      billTitle: widget.debt.billTitle,
      amount: widget.debt.amount,
      transcript: _defaultTranscript,
      persona: 'อัดเสียงเอง',
      promptPayNumber: provider.userPromptPay,
      durationSeconds: nudge.durationSeconds,
      audioPath: _recordedFilePath,
    );

    showVoiceNudgeShareModal(
      context: context,
      targetName: widget.debt.fromMember.name,
      billTitle: widget.debt.billTitle,
      amount: widget.debt.amount,
      transcript: _defaultTranscript,
      durationSeconds: nudge.durationSeconds,
      audioPath: _recordedFilePath,
      persona: 'อัดเสียงเอง',
      nudgeId: nudge.id,
      promptPayNumber: provider.userPromptPay,
      senderName: 'ป๊อป',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('อัดเสียงทวง (Voice Nudge)'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: AppColors.ink3),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'ระบบส่งเสียงทวงแบบจำกัด 1 ครั้ง/วัน ไม่ส่งช่วง 22:00-08:00',
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            // Mode Selector: [ 🎙 อัดเอง ✓ ] [ 🤖 เสียง AI ] [ 🎵 คลัง ]
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.lgBorder,
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _modePill('🎙 อัดเอง', isSelected: true, onTap: () {}),
                  ),
                  Expanded(
                    child: _modePill('🤖 เสียง AI', isSelected: false, onTap: () {
                      _ttsService.stop();
                      _audioService.stopPlayback();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              VoiceNudgeAiScreen(debt: widget.debt),
                        ),
                      );
                    }),
                  ),
                  Expanded(
                    child: _modePill('🎵 คลังเสียง', isSelected: false, onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('กำลังเปิดคลังเสียงสำเร็จรูป')),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Target Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.mdBorder,
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: widget.debt.fromMember.avatarColor
                        .withValues(alpha: 0.15),
                    child: Text(
                      widget.debt.fromMember.avatarEmoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ทวง ${widget.debt.fromMember.name}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.debt.billTitle} · ค้าง ${widget.debt.daysOverdue} วัน',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.danger,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '฿${widget.debt.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Instruction Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: AppRadius.mdBorder,
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: const Row(
                children: [
                  Text('🎙️', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'อัดเสียงพูดทวงเงินด้วยตัวคุณเอง',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          'กดปุ่มไมโครโฟนเพื่อเริ่มอัดเสียง (ความยาวสูงสุด 15 วินาที)',
                          style: TextStyle(fontSize: 11.5, color: AppColors.ink2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Record Button & Timer Section
            ScaleTransition(
              scale: _pulseController,
              child: GestureDetector(
                onTap: _toggleRecording,
                child: Container(
                  width: 118,
                  height: 118,
                  decoration: BoxDecoration(
                    color: _isRecording
                        ? AppColors.danger
                        : AppColors.danger.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.danger
                            .withValues(alpha: _isRecording ? 0.4 : 0.2),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                      color: Colors.white,
                      size: 54,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Timer & Status Text
            Text(
              '0:${_recordSeconds.toString().padLeft(2, '0')} / 0:15',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _isRecording
                  ? 'กำลังอัดเสียง… แตะอีกครั้งเพื่อหยุด'
                  : (_hasRecorded
                      ? 'อัดเสียงเสร็จแล้ว แตะเพื่อลองฟัง'
                      : 'แตะปุ่มเพื่อเริ่มอัดเสียง (สูงสุด 15 วินาที)'),
              style: TextStyle(
                fontSize: 13,
                color: _isRecording ? AppColors.danger : AppColors.ink2,
                fontWeight: _isRecording ? FontWeight.w600 : FontWeight.normal,
              ),
            ),

            const SizedBox(height: 24),

            // Waveform Visualizer
            WaveformVisualizer(
              isPlayingOrRecording: _isRecording || _isPlaying,
              activeColor: _isRecording ? AppColors.danger : AppColors.primary,
              height: 44,
            ),

            const SizedBox(height: 28),

            // Voice Effects Bar
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
                    'เพิ่มเอฟเฟกต์เสียง (Voice Effects)',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _effects.map((fx) {
                      final isSelected = _selectedEffect == fx;
                      return ChoiceChip(
                        label: Text(fx),
                        selected: isSelected,
                        selectedColor: AppColors.primarySoft,
                        labelStyle: TextStyle(
                          fontSize: 12.5,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppColors.primary : AppColors.ink,
                        ),
                        onSelected: (_) {
                          setState(() => _selectedEffect = fx);
                          if (_isPlaying) {
                            _togglePlayback();
                          }
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.line)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: Icon(
                    _isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                  ),
                  label: Text(_isPlaying ? 'หยุด' : 'ฟังตัวอย่าง'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.mdBorder,
                    ),
                  ),
                  onPressed: _togglePlayback,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.volume_up_rounded, size: 18),
                  label: const Text(
                    'ส่งเสียงทวง 🔊',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.mdBorder,
                    ),
                  ),
                  onPressed: _submitVoiceNudge,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modePill(
    String label, {
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: AppRadius.mdBorder,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.ink2,
            ),
          ),
        ),
      ),
    );
  }
}
