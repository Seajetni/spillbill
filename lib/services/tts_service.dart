import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;

  TtsService._internal();

  static const Map<String, String> elevenLabsVoices = {
    'น้องนุ่ม': 'EXAVITQu4vr4xnSDxMaL',
    'เพื่อนซี้': 'FGY2WhTYpPnrIDTdsKH5',
    'หุ่นยนต์': 'IKne3meq5aSn9XLyUdCD',
    'คุณยาย': 'JBFqnCBsd6RMkjVDRZzb',
    'ผู้ประกาศ': 'CwhRBWXzGAHq8TQ4Fs17',
  };

  AudioPlayer? _player;
  FlutterTts? _flutterTts;
  bool _isPlaying = false;
  StreamSubscription? _playerCompleteSub;
  VoidCallback? _currentOnComplete;

  bool get isPlaying => _isPlaying;

  AudioPlayer get player {
    if (_player == null) {
      _player = AudioPlayer();
      _initPlayerListeners();
    }
    return _player!;
  }

  FlutterTts get flutterTts {
    if (_flutterTts == null) {
      _flutterTts = FlutterTts();
      _initFlutterTtsListeners();
    }
    return _flutterTts!;
  }

  void _initPlayerListeners() {
    _playerCompleteSub = _player?.onPlayerComplete.listen((_) {
      _finishPlayback();
    });
  }

  void _initFlutterTtsListeners() {
    _flutterTts?.setCompletionHandler(() {
      _finishPlayback();
    });
    _flutterTts?.setErrorHandler((msg) {
      debugPrint('FlutterTts error: $msg');
      _finishPlayback();
    });
    _flutterTts?.setCancelHandler(() {
      _finishPlayback();
    });
  }

  void _finishPlayback() {
    _isPlaying = false;
    final cb = _currentOnComplete;
    _currentOnComplete = null;
    cb?.call();
  }

  /// Speaks using FlutterTts (Web Speech API / Native platform TTS)
  Future<bool> _speakWithFlutterTts(String text, String persona) async {
    try {
      final tts = flutterTts;
      await tts.stop();
      await tts.setLanguage('th-TH');

      // Configure persona voice characteristics
      switch (persona) {
        case 'น้องนุ่ม':
          await tts.setPitch(1.3);
          await tts.setSpeechRate(0.5);
          break;
        case 'เพื่อนซี้':
          await tts.setPitch(1.05);
          await tts.setSpeechRate(0.55);
          break;
        case 'หุ่นยนต์':
          await tts.setPitch(0.65);
          await tts.setSpeechRate(0.48);
          break;
        case 'คุณยาย':
          await tts.setPitch(0.85);
          await tts.setSpeechRate(0.38);
          break;
        case 'ผู้ประกาศ':
          await tts.setPitch(1.05);
          await tts.setSpeechRate(0.52);
          break;
        default:
          await tts.setPitch(1.0);
          await tts.setSpeechRate(0.5);
          break;
      }

      await tts.awaitSpeakCompletion(false);
      _isPlaying = true;
      final result = await tts.speak(text);
      if (result == 1 || result == '1' || result == true) {
        return true;
      }
    } catch (e) {
      debugPrint('FlutterTts error: $e');
    }
    return false;
  }

  /// Synthesizes Thai speech to an MP3 file using Google Thai TTS.
  /// Returns the absolute file path, or null if network is unavailable or running on web.
  Future<String?> synthesizeToAudioFile(
    String text, {
    String persona = 'ปกติ',
  }) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return null;

    if (kIsWeb) {
      // Audio file creation via local filesystem is not supported on web
      return null;
    }

    try {
      final url = Uri.https('translate.google.com', '/translate_tts', {
        'ie': 'UTF-8',
        'client': 'tw-ob',
        'tl': 'th',
        'q': cleanText,
      });

      final res = await http.get(
        url,
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        },
      ).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200 && res.bodyBytes.length > 500) {
        final tempDir = await getTemporaryDirectory();
        final filename =
            'tts_th_${DateTime.now().millisecondsSinceEpoch}.mp3';
        final file = File('${tempDir.path}/$filename');
        await file.writeAsBytes(res.bodyBytes);
        debugPrint(
          'Google Thai TTS successfully downloaded: ${file.path} (${res.bodyBytes.length} bytes)',
        );
        return file.path;
      }
    } catch (e) {
      debugPrint('Google Thai TTS download error: $e');
    }

    return null;
  }

  /// Speaks the given Thai text.
  /// On Web: Uses Web Speech API (FlutterTts) or direct audio URL to prevent CORS fetch errors.
  /// On Mobile/Desktop: Uses Google Thai TTS stream with FlutterTts fallback.
  Future<void> speak(
    String text, {
    String persona = 'ปกติ',
    VoidCallback? onComplete,
  }) async {
    await stop();
    _currentOnComplete = onComplete;

    final cleanText = text.trim();
    if (cleanText.isEmpty) {
      _finishPlayback();
      return;
    }

    // 1. On Web: Avoid http.get which is blocked by browser CORS (ClientException: Failed to fetch)
    if (kIsWeb) {
      final ttsSuccess = await _speakWithFlutterTts(cleanText, persona);
      if (ttsSuccess) return;

      // Web Fallback: Try playing directly via AudioPlayer UrlSource (HTML5 <audio> bypasses fetch CORS)
      try {
        final url = Uri.https('translate.google.com', '/translate_tts', {
          'ie': 'UTF-8',
          'client': 'tw-ob',
          'tl': 'th',
          'q': cleanText,
        });
        await player.setVolume(1.0);
        _isPlaying = true;
        await player.play(UrlSource(url.toString()));
        return;
      } catch (e) {
        debugPrint('Web AudioPlayer UrlSource fallback error: $e');
        _finishPlayback();
        return;
      }
    }

    // 2. On Mobile / Desktop: Try Google Thai TTS audio stream via HTTP download
    try {
      final url = Uri.https('translate.google.com', '/translate_tts', {
        'ie': 'UTF-8',
        'client': 'tw-ob',
        'tl': 'th',
        'q': cleanText,
      });

      final res = await http.get(
        url,
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        },
      ).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200 && res.bodyBytes.length > 500) {
        await player.setVolume(1.0);
        _isPlaying = true;
        await player.play(BytesSource(res.bodyBytes));

        // Cache file for future playback if on native platform
        try {
          final tempDir = await getTemporaryDirectory();
          final file = File('${tempDir.path}/tts_preview.mp3');
          await file.writeAsBytes(res.bodyBytes);
        } catch (_) {}
        return;
      }
    } catch (e) {
      debugPrint('Google Thai TTS stream error: $e');
    }

    // 3. Fallback on native platforms: Use device TTS
    final fallbackSuccess = await _speakWithFlutterTts(cleanText, persona);
    if (!fallbackSuccess) {
      _finishPlayback();
    }
  }

  /// Stops current audio output
  Future<void> stop() async {
    try {
      if (_flutterTts != null) {
        await _flutterTts!.stop();
      }
      if (_player != null) {
        await _player!.stop();
      }
    } catch (e) {
      debugPrint('Error stopping TTS player: $e');
    } finally {
      _finishPlayback();
    }
  }

  void dispose() {
    _playerCompleteSub?.cancel();
    _player?.dispose();
    _player = null;
    _flutterTts?.stop();
    _flutterTts = null;
  }
}
