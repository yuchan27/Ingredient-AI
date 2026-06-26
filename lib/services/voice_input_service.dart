import 'dart:async';

import 'package:speech_to_text/speech_to_text.dart';

class VoiceInputService {
  final SpeechToText _speech;

  VoiceInputService({SpeechToText? speech}) : _speech = speech ?? SpeechToText();

  bool get isListening => _speech.isListening;

  Future<bool> initialize() {
    return _speech.initialize();
  }

  Future<String?> listenOnce({
    Duration listenFor = const Duration(seconds: 10),
    String localeId = 'zh_TW',
  }) async {
    final available = await initialize();
    if (!available) return null;

    final completer = Completer<String?>();
    String latestWords = '';

    await _speech.listen(
      onResult: (result) {
        latestWords = result.recognizedWords.trim();
        if (result.finalResult && !completer.isCompleted) {
          completer.complete(latestWords.isEmpty ? null : latestWords);
        }
      },
      listenOptions: SpeechListenOptions(
        localeId: localeId,
        listenFor: listenFor,
        partialResults: true,
      ),
    );

    return completer.future.timeout(
      listenFor + const Duration(seconds: 2),
      onTimeout: () async {
        await stop();
        return latestWords.isEmpty ? null : latestWords;
      },
    );
  }

  Future<void> stop() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
  }
}
