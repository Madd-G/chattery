import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

abstract class TtsService {
  Future<void> initialize();
  Future<void> speak(String text);
  Future<void> stop();
}

class FlutterTtsServiceImpl implements TtsService {
  final FlutterTts _flutterTts;

  FlutterTtsServiceImpl(this._flutterTts);

  @override
  Future<void> initialize() async {
    try {
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(0.5);
    } catch (e) {
      debugPrint("TTS initialization error: $e");
    }
  }

  @override
  Future<void> speak(String text) async {
    if (text.isNotEmpty) {
      await _flutterTts.speak(text);
    }
  }

  @override
  Future<void> stop() async {
    await _flutterTts.stop();
  }
}