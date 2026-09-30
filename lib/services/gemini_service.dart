import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class GeminiService {
  static const String _defaultApiKey =
      String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  // Primary modern model that supports generateContent
  static const String _primaryModel = 'gemini-3.6-flash';
  static const String _fallbackModel = 'gemini-flash-latest';

  final String apiKey;
  final http.Client _client;

  GeminiService({String? apiKey, http.Client? client})
      : apiKey = apiKey ?? _defaultApiKey,
        _client = client ?? http.Client();

  /// Generates a voice nudge script tailored to the friend's name, bill details,
  /// selected persona, and escalation ladder.
  Future<String> generateVoiceScript({
    required String recipientName,
    required String billTitle,
    required double amount,
    required String persona,
    required EscalationLadder ladder,
    String style = 'ai',
  }) async {
    final cleanTitle = billTitle.replaceAll(RegExp(r'[^a-zA-Zก-๙0-9 ]'), '').trim();
    final cleanAmount = amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2);

    final prompt = _buildPrompt(
      recipientName: recipientName,
      billTitle: cleanTitle.isEmpty ? 'ค่าอาหาร/บิล' : cleanTitle,
      amountText: cleanAmount,
      persona: persona,
      ladder: ladder,
      style: style,
    );

    // Try primary model first, fallback to secondary if needed
    for (final model in [_primaryModel, _fallbackModel]) {
      try {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
        );

        final response = await _client.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': prompt}
                ]
              }
            ],
            'generationConfig': {
              'temperature': 0.7,
              'maxOutputTokens': 150,
            }
          }),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          final candidates = data['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final parts = candidates[0]['content']?['parts'] as List?;
            if (parts != null && parts.isNotEmpty) {
              String text = (parts[0]['text'] as String? ?? '').trim();
              text = _cleanResponseText(text);
              if (text.isNotEmpty) {
                return text;
              }
            }
          }
        } else {
          debugPrint('Gemini API ($model) HTTP ${response.statusCode}: ${response.body}');
        }
      } catch (e) {
        debugPrint('Gemini API ($model) request error: $e');
      }
    }

    // High quality offline contextual fallback
    return _getFallbackScript(
      recipientName: recipientName,
      billTitle: cleanTitle.isEmpty ? 'ค่าบิล' : cleanTitle,
      amountText: cleanAmount,
      persona: persona,
      ladder: ladder,
      style: style,
    );
  }

  String _buildPrompt({
    required String recipientName,
    required String billTitle,
    required String amountText,
    required String persona,
    required EscalationLadder ladder,
    required String style,
  }) {
    String ladderDesc;
    switch (ladder) {
      case EscalationLadder.gentle:
        ladderDesc = 'ระดับสะกิดเบาๆ สุภาพ เกรงใจมาก นุ่มนวล';
        break;
      case EscalationLadder.normal:
        ladderDesc = 'ระดับเตือนปกติ เป็นกันเอง สบายๆ';
        break;
      case EscalationLadder.serious:
        ladderDesc = 'ระดับจริงจัง เตือนกำหนดชำระตรงประเด็น';
        break;
      case EscalationLadder.sarcastic:
        ladderDesc = 'ระดับประชดประชันขำขัน แซวแสบๆ น่ารัก';
        break;
    }

    String styleInstruction;
    switch (style) {
      case 'joke':
        styleInstruction = 'เน้นใส่มุกตลก มุกฮา ชวนหัวเราะ';
        break;
      case 'polite':
        styleInstruction = 'เน้นความสุภาพ อ่อนน้อม ให้เกียรติสูงสุด';
        break;
      default:
        styleInstruction = 'บทพูดธรรมชาติ น่ารัก ฟังเพลิน';
        break;
    }

    return '''
คุณคือนักแต่งสคริปต์เสียงพูดทวงเงินสำหรับเพื่อนในแอป SplitBill
จงเขียนข้อความบทพูดภาษาไทยสั้นๆ 1-2 ประโยค สำหรับอ่านเป็นข้อความเสียง (Voice Nudge)
กฎสำคัญ:
- ความยาวไม่เกิน 110 ตัวอักษร
- ห้ามใส่เครื่องหมายคำพูด ดอกจัน หรือข้อความอธิบายใดๆ ตอบเฉพาะบทพูดเพียวๆ เท่านั้น
- สามารถมี Emoji ประกอบได้ 1-2 ตัว
- สคริปต์ต้องเข้ากับคาแรกเตอร์และระดับความจริงจัง

ข้อมูลบริบท:
- ชื่อเพื่อนผู้รับ: $recipientName
- รายการบิล: $billTitle
- ยอดเงิน: $amountText บาท
- คาแรกเตอร์เสียง: $persona (เช่น น้องนุ่ม, เพื่อนซี้, หุ่นยนต์, คุณยาย, ผู้ประกาศ)
- ระดับการเตือน: $ladderDesc
- สไตล์พิเศษ: $styleInstruction
''';
  }

  String _cleanResponseText(String text) {
    var cleaned = text
        .replaceAll(RegExp(r'^["“”\s]+|["“”\s]+$'), '')
        .replaceAll(RegExp(r'^\*+|\*+$'), '')
        .replaceAll(RegExp(r'\n+'), ' ')
        .trim();
    if (cleaned.length > 120) {
      cleaned = cleaned.substring(0, 120);
    }
    return cleaned;
  }

  String _getFallbackScript({
    required String recipientName,
    required String billTitle,
    required String amountText,
    required String persona,
    required EscalationLadder ladder,
    required String style,
  }) {
    if (style == 'joke') {
      return 'เฮ้ย $recipientName โอนค่า$billTitle $amountText บาทด้วย เดี๋ยววิญญาณหมูตามไปหลอกหลอนนะเว้ยยย 🐷';
    }
    if (style == 'polite') {
      return 'เรียนคุณ $recipientName ที่เคารพ ขอรบกวนเวลาสักนิดชำระยอด$billTitle $amountText บาทนะคะ ขอบคุณค่ะ 🙏';
    }

    switch (persona) {
      case 'เพื่อนซี้':
        return 'เฮ้ย $recipientName! ว่างแล้วเคลียร์ค่า$billTitle $amountText บาทให้ด้วยนะเพื่อน ซี๊ดเลย 😎';
      case 'หุ่นยนต์':
        return 'แจ้งเตือนอัตโนมัติ: บัญชี $recipientName มียอดค้าง $billTitle จำนวน $amountText บาท กรุณาชำระด้วยครับ 🤖';
      case 'คุณยาย':
        return 'หลาน $recipientName จ๋า ยายมาเตือนค่า$billTitle $amountText บาท ว่างแล้วโอนให้เพื่อนนะลูก 👵';
      case 'ผู้ประกาศ':
        return 'ด่วนที่สุด! รายงานข่าวด่วน แจ้งยอด$billTitle จากคุณ $recipientName $amountText บาท ยังไม่มียอดเข้าครับ 📣';
      case 'น้องนุ่ม':
      default:
        if (ladder == EscalationLadder.serious) {
          return 'สวัสดีค่ะคุณ$recipientName ขออนุญาตเตือนยอดค้าง$billTitle $amountText บาท รบกวนโอนวันนี้ด้วยนะคะ ขอบคุณค่ะ';
        }
        return 'สวัสดีค่ะคุณ$recipientName รบกวนโอนค่า$billTitle $amountText บาทให้ด้วยนะคะ ขอบคุณมากๆ ค่ะ 😊';
    }
  }
}
