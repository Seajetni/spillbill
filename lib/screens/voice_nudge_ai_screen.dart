import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/split_bill_provider.dart';
import '../services/gemini_service.dart';
import '../services/nudge_sync_service.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';
import '../widgets/voice_nudge_share_modal.dart';
import 'voice_nudge_record_screen.dart';

class VoiceNudgeAiScreen extends StatefulWidget {
  final DebtRecord debt;

  const VoiceNudgeAiScreen({super.key, required this.debt});

  @override
  State<VoiceNudgeAiScreen> createState() => _VoiceNudgeAiScreenState();
}

class _VoiceNudgeAiScreenState extends State<VoiceNudgeAiScreen> {
  String _selectedPersona = 'น้องนุ่ม';
  late TextEditingController _scriptCtrl;
  EscalationLadder _selectedLadder = EscalationLadder.gentle;

  final GeminiService _geminiService = GeminiService();
  final TtsService _ttsService = TtsService();

  bool _isGeneratingAi = false;
  bool _isPlayingPreview = false;
  bool _isSynthesizing = false;

  final List<Map<String, String>> _personas = [
    {'name': 'น้องนุ่ม', 'emoji': '😊', 'desc': 'สุภาพ นุ่มนวล'},
    {'name': 'เพื่อนซี้', 'emoji': '😎', 'desc': 'กันเอง ตรงไปตรงมา'},
    {'name': 'หุ่นยนต์', 'emoji': '🤖', 'desc': 'ตลกแห้ง เป็นทางการ'},
    {'name': 'คุณยาย', 'emoji': '👵', 'desc': 'น่ารัก อบอุ่น'},
    {'name': 'ผู้ประกาศ', 'emoji': '📣', 'desc': 'ดราม่าเกินเหตุ'},
  ];

  @override
  void initState() {
    super.initState();
    _scriptCtrl = TextEditingController(
      text:
          'สวัสดีค่ะคุณ${widget.debt.fromMember.name} รบกวนโอนค่า${widget.debt.billTitle.replaceAll(RegExp(r'[^a-zA-Zก-๙0-9 ]'), '')} ${widget.debt.amount.toStringAsFixed(0)} บาท ให้ป๊อปด้วยนะคะ ขอบคุณค่ะ',
    );
  }

  @override
  void dispose() {
    _ttsService.stop();
    _scriptCtrl.dispose();
    super.dispose();
  }

  Future<void> _applyAiSuggestion(String type) async {
    if (_isGeneratingAi) return;

    setState(() {
      _isGeneratingAi = true;
    });

    try {
      final generatedScript = await _geminiService.generateVoiceScript(
        recipientName: widget.debt.fromMember.name,
        billTitle: widget.debt.billTitle,
        amount: widget.debt.amount,
        persona: _selectedPersona,
        ladder: _selectedLadder,
        style: type,
      );

      if (mounted) {
        setState(() {
          _scriptCtrl.text = generatedScript;
          _isGeneratingAi = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGeneratingAi = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการสร้างบทพูด: $e')),
        );
      }
    }
  }

  Future<void> _toggleVoicePreview() async {
    if (_isPlayingPreview) {
      await _ttsService.stop();
      if (mounted) setState(() => _isPlayingPreview = false);
    } else {
      final textToSpeak = _scriptCtrl.text.trim();
      if (textToSpeak.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณากรอกข้อความสคริปต์ก่อนลองฟัง')),
        );
        return;
      }

      setState(() => _isPlayingPreview = true);
      await _ttsService.speak(
        textToSpeak,
        persona: _selectedPersona,
        onComplete: () {
          if (mounted) setState(() => _isPlayingPreview = false);
        },
      );
    }
  }

  Future<void> _submitVoiceNudge() async {
    final scriptText = _scriptCtrl.text.trim();
    if (scriptText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาระบุข้อความบทพูดก่อนส่ง')),
      );
      return;
    }

    setState(() {
      _isSynthesizing = true;
    });

    await _ttsService.stop();

    // Synthesize audio to file if possible (via ElevenLabs or local TTS)
    String? audioPath;
    try {
      audioPath = await _ttsService.synthesizeToAudioFile(
        scriptText,
        persona: _selectedPersona,
      );
    } catch (e) {
      debugPrint('TTS synthesis error: $e');
    }

    if (!mounted) return;

    // Save to SplitBillProvider
    final nudge = VoiceNudgeData(
      id: 'vn_${DateTime.now().millisecondsSinceEpoch}',
      targetMember: widget.debt.fromMember,
      amount: widget.debt.amount,
      billTitle: widget.debt.billTitle,
      daysOverdue: widget.debt.daysOverdue,
      mode: 'ai',
      persona: _selectedPersona,
      transcript: scriptText,
      durationSeconds: (scriptText.length / 10).clamp(5, 12).toInt(),
      ladder: _selectedLadder,
      audioPath: audioPath,
      isSent: true,
    );

    final provider = context.read<SplitBillProvider>();
    provider.addVoiceNudge(nudge);

    setState(() {
      _isSynthesizing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'สังเคราะห์เสียง AI สำเร็จ พร้อมแชร์ให้ ${widget.debt.fromMember.name} 🔊',
        ),
      ),
    );

    // Background sync to Vercel + MongoDB Atlas
    NudgeSyncService.syncNudgeToCloud(
      nudgeId: nudge.id,
      targetName: widget.debt.fromMember.name,
      senderName: 'ป๊อป',
      billTitle: widget.debt.billTitle,
      amount: widget.debt.amount,
      transcript: scriptText,
      persona: _selectedPersona,
      promptPayNumber: provider.userPromptPay,
      durationSeconds: nudge.durationSeconds,
      audioPath: audioPath,
    );

    showVoiceNudgeShareModal(
      context: context,
      targetName: widget.debt.fromMember.name,
      billTitle: widget.debt.billTitle,
      amount: widget.debt.amount,
      transcript: scriptText,
      durationSeconds: nudge.durationSeconds,
      audioPath: audioPath,
      persona: _selectedPersona,
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
        title: const Text('เสียง AI (TTS Nudge)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mode Selector: [ 🎙 อัดเอง ] [ 🤖 AI ✓ ] [ 🎵 คลัง ]
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
                    child: _modePill('🎙 อัดเอง', isSelected: false, onTap: () {
                      _ttsService.stop();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              VoiceNudgeRecordScreen(debt: widget.debt),
                        ),
                      );
                    }),
                  ),
                  Expanded(
                    child: _modePill('🤖 เสียง AI', isSelected: true, onTap: () {}),
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
            const SizedBox(height: 20),

            // Personas Selector
            const Text(
              'เลือกคาแรกเตอร์เสียง (Voice Persona)',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 106,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _personas.length,
                itemBuilder: (context, index) {
                  final p = _personas[index];
                  final isSelected = _selectedPersona == p['name'];
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedPersona = p['name']!);
                      if (_isPlayingPreview) _ttsService.stop();
                    },
                    child: Container(
                      width: 88,
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primarySoft : Colors.white,
                        borderRadius: AppRadius.mdBorder,
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.line,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(p['emoji']!, style: const TextStyle(fontSize: 26)),
                          const SizedBox(height: 4),
                          Text(
                            p['name']!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.ink,
                            ),
                          ),
                          Text(
                            p['desc']!,
                            style: const TextStyle(
                              fontSize: 9.5,
                              color: AppColors.ink3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // Script Editor Section
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ข้อความที่จะอ่าน (Script)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        '${_scriptCtrl.text.length}/120',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.ink3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _scriptCtrl,
                    maxLines: 3,
                    maxLength: 120,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      counterText: '',
                      hintText: 'พิมพ์ข้อความที่ต้องการให้ AI อ่าน...',
                      suffixIcon: _isGeneratingAi
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : null,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 10),

                  // AI Suggestion Chips powered by Gemini API
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      ActionChip(
                        avatar: _isGeneratingAi
                            ? const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(strokeWidth: 1.5),
                              )
                            : const Text('✨', style: TextStyle(fontSize: 12)),
                        label: const Text(
                          'AI ช่วยเขียน',
                          style: TextStyle(fontSize: 12),
                        ),
                        onPressed:
                            _isGeneratingAi ? null : () => _applyAiSuggestion('ai'),
                      ),
                      ActionChip(
                        avatar: const Text('😂', style: TextStyle(fontSize: 12)),
                        label: const Text('ใส่มุก', style: TextStyle(fontSize: 12)),
                        onPressed:
                            _isGeneratingAi ? null : () => _applyAiSuggestion('joke'),
                      ),
                      ActionChip(
                        avatar: const Text('🙏', style: TextStyle(fontSize: 12)),
                        label: const Text(
                          'สุภาพขึ้น',
                          style: TextStyle(fontSize: 12),
                        ),
                        onPressed: _isGeneratingAi
                            ? null
                            : () => _applyAiSuggestion('polite'),
                      ),
                    ],
                  ),

                  if (_isGeneratingAi)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Gemini กำลังร่างบทพูดตามบริบท...',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 8),

                  // Preview Voice Button
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      icon: Icon(
                        _isPlayingPreview
                            ? Icons.stop_circle_rounded
                            : Icons.play_circle_fill_rounded,
                        size: 20,
                        color: _isPlayingPreview
                            ? AppColors.danger
                            : AppColors.primary,
                      ),
                      label: Text(
                        _isPlayingPreview
                            ? 'หยุดฟัง'
                            : '▶ ลองฟังเสียง AI ($_selectedPersona)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _isPlayingPreview
                              ? AppColors.danger
                              : AppColors.primary,
                        ),
                      ),
                      onPressed: _toggleVoicePreview,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Escalation Ladder Section (PDD Section F.4)
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
                    'ระดับความแรง (Escalation Ladder)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _ladderOption(
                    ladder: EscalationLadder.gentle,
                    title: '🟢 สะกิดเบา ๆ',
                    desc: 'แจ้งเตือนเงียบ · โทนสุภาพนุ่มนวล',
                  ),
                  _ladderOption(
                    ladder: EscalationLadder.normal,
                    title: '🟡 เตือนปกติ',
                    desc: 'มีเสียงแจ้งเตือน · โทนกันเองแบบเพื่อน',
                  ),
                  _ladderOption(
                    ladder: EscalationLadder.serious,
                    title: '🟠 จริงจัง',
                    desc: 'ส่งซ้ำทุกวัน · แจ้งเตือนในกลุ่มเพื่อน',
                  ),
                  _ladderOption(
                    ladder: EscalationLadder.sarcastic,
                    title: '🔴 โหมดประชด 🔥 (ล็อก)',
                    desc: 'ปลดล็อกเมื่อค้างเกิน 14 วัน · ยืนยัน 2 ชั้น',
                    isLocked: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Guardrail Info Banner (PDD Section F.5)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: AppRadius.mdBorder,
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                children: [
                  Text('🛡', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ระบบป้องกันการรบกวน (Guardrails)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          'จำกัด 1 ครั้ง/วัน/คน · งดส่ง 22:00–08:00 อัตโนมัติ',
                          style: TextStyle(fontSize: 12, color: AppColors.ink2),
                        ),
                      ],
                    ),
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
          child: ElevatedButton.icon(
            icon: _isSynthesizing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.volume_up_rounded),
            label: Text(
              _isSynthesizing
                  ? 'กำลังประมวลผลเสียง AI...'
                  : 'สร้างและส่งเสียงทวง AI ($_selectedPersona) 🔊',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
            ),
            onPressed: _isSynthesizing ? null : _submitVoiceNudge,
          ),
        ),
      ),
    );
  }

  Widget _ladderOption({
    required EscalationLadder ladder,
    required String title,
    required String desc,
    bool isLocked = false,
  }) {
    final isSelected = _selectedLadder == ladder;
    return InkWell(
      onTap: isLocked
          ? () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'โหมดประชดจะปลดล็อกเฉพาะเมื่อค้างชำระเกิน 14 วันเท่านั้น เพื่อป้องกันความขัดแย้ง',
                  ),
                ),
              );
            }
          : () => setState(() => _selectedLadder = ladder),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              isLocked
                  ? Icons.lock_outline_rounded
                  : (isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked),
              color: isLocked
                  ? AppColors.ink3
                  : (isSelected ? AppColors.primary : AppColors.ink3),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isLocked ? AppColors.ink3 : AppColors.ink,
                    ),
                  ),
                  Text(
                    desc,
                    style: const TextStyle(fontSize: 12, color: AppColors.ink3),
                  ),
                ],
              ),
            ),
          ],
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
