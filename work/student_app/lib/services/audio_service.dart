import 'package:flutter_tts/flutter_tts.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final FlutterTts _tts = FlutterTts();
  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  Future<void> init() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.48); // Optimal speech pace for medical terms
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _tts.setStartHandler(() {
      _isPlaying = true;
    });

    _tts.setCompletionHandler(() {
      _isPlaying = false;
    });

    _tts.setErrorHandler((msg) {
      _isPlaying = false;
    });
  }

  Future<void> speakText(String text) async {
    if (_isPlaying) {
      await stop();
    }
    _isPlaying = true;
    await _tts.speak(text);
  }

  Future<void> speakLesson({
    required String title,
    required List<String> objectives,
    required List<Map<String, String>> sections,
    required List<String> cautions,
  }) async {
    final buffer = StringBuffer();
    buffer.writeln('Lesson Title: $title.');
    if (objectives.isNotEmpty) {
      buffer.writeln('Learning Objectives:');
      for (final obj in objectives) {
        buffer.writeln('$obj.');
      }
    }
    for (final sec in sections) {
      buffer.writeln('${sec['heading'] ?? ''}.');
      buffer.writeln('${sec['text'] ?? ''}.');
    }
    if (cautions.isNotEmpty) {
      buffer.writeln('Clinical Patient Safety Cautions:');
      for (final caution in cautions) {
        buffer.writeln('Caution: $caution.');
      }
    }
    await speakText(buffer.toString());
  }

  Future<void> stop() async {
    await _tts.stop();
    _isPlaying = false;
  }
}

final audioService = AudioService();
