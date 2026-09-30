import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class NudgeSyncService {
  static const String defaultVercelBaseUrl = 'https://spillbill.vercel.app';
  static String vercelBaseUrl = defaultVercelBaseUrl;

  /// Syncs a voice nudge to Vercel + MongoDB Atlas.
  /// If offline or Vercel is not yet deployed, gracefully returns the expected share URL.
  static Future<String> syncNudgeToCloud({
    required String nudgeId,
    required String targetName,
    required String senderName,
    required String billTitle,
    required double amount,
    required String transcript,
    required String persona,
    required String promptPayNumber,
    required int durationSeconds,
    String? audioPath,
  }) async {
    String? audioBase64;
    try {
      if (audioPath != null && !kIsWeb && File(audioPath).existsSync()) {
        final bytes = await File(audioPath).readAsBytes();
        if (bytes.length < 5 * 1024 * 1024) {
          audioBase64 = base64Encode(bytes);
        }
      }
    } catch (e) {
      debugPrint('Error reading audio for cloud sync: $e');
    }

    final payload = {
      'id': nudgeId,
      'targetName': targetName,
      'senderName': senderName,
      'billTitle': billTitle,
      'amount': amount,
      'transcript': transcript,
      'persona': persona,
      'promptPayNumber': promptPayNumber,
      'durationSeconds': durationSeconds,
      'audioBase64': ?audioBase64,
    };

    final defaultUrl = '$vercelBaseUrl/n/$nudgeId';

    try {
      final res = await http.post(
        Uri.parse('$vercelBaseUrl/api/nudge'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['shareUrl'] != null) {
          return data['shareUrl'] as String;
        }
      }
    } catch (e) {
      debugPrint('Cloud sync notice (offline/initial setup): $e');
    }

    return defaultUrl;
  }
}
