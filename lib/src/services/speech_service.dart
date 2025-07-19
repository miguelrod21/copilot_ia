import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  final SpeechToText speech;

  SpeechService(this.speech);

Future<bool> initialize({
  required Function(SpeechRecognitionError error) onError,
  required Function(String status) onStatus,
}) async {
  return await speech.initialize(
    onError: onError,
    onStatus: onStatus,
  );
}


  Future<List<LocaleName>> getLocales() async {
    return await speech.locales();
  }

  Future<void> listen({
    required String localeId,
    required Function(String resultText, bool isFinal) onResult,
    Duration listenFor = const Duration(seconds: 60),
    Duration pauseFor = const Duration(seconds: 5),
  }) async {
    await speech.listen(
      localeId: localeId,
      listenFor: listenFor,
      pauseFor: pauseFor,
      onResult: (result) =>
          onResult(result.recognizedWords, result.finalResult),
    );
  }

  Future<void> stop() async {
    await speech.stop();
  }
}
