import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class StorageService {
  static const String _fileName = 'split_bill_data.json';

  static Future<File?> _getLocalFile() async {
    if (kIsWeb) return null;
    try {
      final dir = await getApplicationDocumentsDirectory();
      return File('${dir.path}/$_fileName');
    } catch (e) {
      debugPrint('StorageService: Error getting documents directory: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> loadState() async {
    try {
      final file = await _getLocalFile();
      if (file != null && await file.exists()) {
        final content = await file.readAsString();
        if (content.trim().isNotEmpty) {
          final decoded = jsonDecode(content);
          if (decoded is Map<String, dynamic>) {
            return decoded;
          }
        }
      }
    } catch (e) {
      debugPrint('StorageService: Error loading saved state: $e');
    }
    return null;
  }

  static Future<void> saveState(Map<String, dynamic> state) async {
    try {
      final file = await _getLocalFile();
      if (file != null) {
        final jsonString = jsonEncode(state);
        final tempFile = File('${file.path}.tmp');
        await tempFile.writeAsString(jsonString, flush: true);
        if (await file.exists()) {
          await file.delete();
        }
        await tempFile.rename(file.path);
      }
    } catch (e) {
      debugPrint('StorageService: Error saving state: $e');
    }
  }

  static Future<void> clearState() async {
    try {
      final file = await _getLocalFile();
      if (file != null && await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('StorageService: Error clearing state: $e');
    }
  }
}
