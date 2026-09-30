import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;

  AudioService._internal();

  AudioRecorder? _recorder;
  AudioPlayer? _player;

  bool _isRecording = false;
  bool _isPlaying = false;
  String? _lastRecordedFilePath;
  StreamSubscription? _playerCompleteSub;
  StreamSubscription? _playerStateSub;
  VoidCallback? _currentOnComplete;

  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  String? get lastRecordedFilePath => _lastRecordedFilePath;

  AudioPlayer get player {
    if (_player == null) {
      _player = AudioPlayer();
      _initPlayerListeners();
    }
    return _player!;
  }

  AudioRecorder get recorder => _recorder ??= AudioRecorder();

  void _initPlayerListeners() {
    _playerCompleteSub = _player?.onPlayerComplete.listen((_) {
      _isPlaying = false;
      _currentOnComplete?.call();
      _currentOnComplete = null;
    });

    _playerStateSub = _player?.onPlayerStateChanged.listen((state) {
      _isPlaying = (state == PlayerState.playing);
    });
  }

  /// Checks microphone permissions and starts recording to a temporary file (or in-memory Blob on web)
  Future<bool> startRecording() async {
    try {
      final hasPermission = await recorder.hasPermission();
      if (!hasPermission) {
        debugPrint('Microphone permission not granted');
        return false;
      }

      // Stop any current playback
      await stopPlayback();

      AudioEncoder encoder = AudioEncoder.aacLc;
      String path = '';

      if (kIsWeb) {
        // On web, record_web doesn't use path_provider filesystem.
        // It records to an in-memory Blob and produces an Object URL.
        encoder = (await recorder.isEncoderSupported(AudioEncoder.opus))
            ? AudioEncoder.opus
            : AudioEncoder.wav;
        path = '';
      } else {
        final tempDir = await getTemporaryDirectory();
        String ext = 'm4a';

        if (Platform.isWindows) {
          encoder = AudioEncoder.wav;
          ext = 'wav';
        }

        path =
            '${tempDir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.$ext';
      }

      final config = RecordConfig(
        encoder: encoder,
        bitRate: 128000,
        sampleRate: 44100,
      );

      await recorder.start(config, path: path);
      _isRecording = true;
      _lastRecordedFilePath = path;
      return true;
    } catch (e) {
      debugPrint('Error starting recording: $e');
      _isRecording = false;
      return false;
    }
  }

  /// Stops recording and returns the file path of the recorded audio
  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) return _lastRecordedFilePath;

      final path = await _recorder?.stop();
      _isRecording = false;
      _lastRecordedFilePath = path ?? _lastRecordedFilePath;

      if (_lastRecordedFilePath != null) {
        if (kIsWeb ||
            _lastRecordedFilePath!.startsWith('blob:') ||
            _lastRecordedFilePath!.startsWith('http')) {
          debugPrint(
            'Recording successfully saved on web: $_lastRecordedFilePath',
          );
          return _lastRecordedFilePath;
        }

        final file = File(_lastRecordedFilePath!);
        if (await file.exists() && await file.length() > 200) {
          debugPrint(
            'Recording successfully saved: ${_lastRecordedFilePath!} (${await file.length()} bytes)',
          );
          return _lastRecordedFilePath;
        }
      }
      return _lastRecordedFilePath;
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      _isRecording = false;
      return _lastRecordedFilePath;
    }
  }

  /// Plays a local audio file with optional sound effects (playback rate adjustment)
  Future<void> playFile(
    String filePath, {
    String effect = 'ปกติ',
    VoidCallback? onComplete,
  }) async {
    try {
      await stopPlayback();
      _currentOnComplete = onComplete;

      double rate = 1.0;
      if (effect.contains('ชิพมังก์')) {
        rate = 1.35;
      } else if (effect.contains('ทุ้มลึก')) {
        rate = 0.82;
      } else if (effect.contains('วิทยุเก่า')) {
        rate = 1.08;
      } else if (effect.contains('ห้องโถง')) {
        rate = 0.92;
      }

      await player.setVolume(1.0);
      _isPlaying = true;
      if (kIsWeb ||
          filePath.startsWith('blob:') ||
          filePath.startsWith('http')) {
        await player.play(UrlSource(filePath));
      } else {
        await player.play(DeviceFileSource(filePath));
      }
      try {
        await player.setPlaybackRate(rate);
      } catch (_) {}
    } catch (e) {
      debugPrint('Error playing audio file: $e');
      _isPlaying = false;
      onComplete?.call();
    }
  }

  /// Stops current playback
  Future<void> stopPlayback() async {
    try {
      await _player?.stop();
      _isPlaying = false;
      _currentOnComplete = null;
    } catch (e) {
      debugPrint('Error stopping playback: $e');
    }
  }

  void dispose() {
    _playerCompleteSub?.cancel();
    _playerStateSub?.cancel();
    _player?.dispose();
    _recorder?.dispose();
  }
}
