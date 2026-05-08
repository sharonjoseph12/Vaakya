import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// 4-state voice engine for STT and TTS.
enum VoiceState { idle, listening, processing, speaking }

class VoiceProvider extends ChangeNotifier {
  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  VoiceState _state = VoiceState.idle;
  String _currentWords = '';
  bool _sttAvailable = false;
  Timer? _silenceTimer;

  VoiceState get state => _state;
  String get currentWords => _currentWords;
  bool get sttAvailable => _sttAvailable;

  /// Called when the user finishes speaking (silence timeout or manual stop).
  /// The [String] parameter contains the recognized text.
  ValueChanged<String>? onSpeechResult;

  /// Initialize both STT and TTS engines.
  Future<void> init() async {
    _sttAvailable = await _stt.initialize(
      onError: (error) {
        debugPrint('STT error: ${error.errorMsg}');
        _setState(VoiceState.idle);
      },
      onStatus: (status) {
        debugPrint('STT status: $status');
      },
    );

    // Configure TTS
    await _tts.setLanguage('en-IN');
    await _tts.setSpeechRate(0.48);
    await _tts.setPitch(1.05);

    _tts.setStartHandler(() {
      _setState(VoiceState.speaking);
    });

    _tts.setCompletionHandler(() {
      _setState(VoiceState.idle);
    });

    _tts.setErrorHandler((message) {
      debugPrint('TTS error: $message');
      _setState(VoiceState.idle);
    });
  }

  /// Start listening for speech input.
  Future<void> startListening() async {
    if (!_sttAvailable) return;

    _currentWords = '';
    HapticFeedback.lightImpact();
    _setState(VoiceState.listening);

    await _stt.listen(
      onResult: (result) {
        _currentWords = result.recognizedWords;
        notifyListeners();

        // Reset the silence timer on each partial result
        _resetSilenceTimer();
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 2),
      localeId: 'en_IN',
      listenOptions: SpeechListenOptions(
        cancelOnError: true,
        partialResults: true,
      ),
    );

    // Start initial silence timer
    _resetSilenceTimer();
  }

  /// Stop listening manually.
  Future<void> stopListening() async {
    _silenceTimer?.cancel();
    await _stt.stop();

    if (_currentWords.isNotEmpty) {
      _setState(VoiceState.processing);
      onSpeechResult?.call(_currentWords);
    } else {
      _setState(VoiceState.idle);
    }
  }

  /// Speak text aloud via TTS.
  Future<void> speak(String text, {String language = 'en-IN'}) async {
    await _tts.setLanguage(language);
    _setState(VoiceState.speaking);
    await _tts.speak(text);
  }

  /// Stop TTS playback.
  Future<void> stopSpeaking() async {
    await _tts.stop();
    _setState(VoiceState.idle);
  }

  /// Set state to processing (called externally when API call starts).
  void setProcessing() {
    _setState(VoiceState.processing);
  }

  /// Set state back to idle.
  void setIdle() {
    _setState(VoiceState.idle);
  }

  /// 1.5-second silence timeout — auto-stop and trigger API call.
  void _resetSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(const Duration(milliseconds: 1500), () {
      if (_state == VoiceState.listening) {
        stopListening();
      }
    });
  }

  void _setState(VoiceState newState) {
    if (_state != newState) {
      _state = newState;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _silenceTimer?.cancel();
    _stt.cancel();
    _tts.stop();
    super.dispose();
  }
}
