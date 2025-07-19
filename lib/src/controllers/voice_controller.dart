import 'package:copilot_ia/resources/es.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/chatgpt_service.dart';

class VoiceController {
  final SpeechToText speech;
  final FlutterTts tts;
  final ChatGPTService chatService;

  bool isPassiveListening = false;
  bool isActiveListening = false;
  String recognizedText = '';
  String? selectedLocaleId;

  VoiceController({
    required this.speech,
    required this.tts,
    required this.chatService,
  });

  Future<bool> initializeSpeech({
    required Function(String error) onError,
    required Function(String status) onStatus,
  }) async {
    final available = await speech.initialize(
      onError: (e) => onError(e.errorMsg),
      onStatus: onStatus,
    );

    if (available) {
      final locales = await speech.locales();
      final esLocale = locales.firstWhere(
        (l) => l.localeId == 'es_ES',
        orElse: () => locales.isNotEmpty
            ? locales.first
            : LocaleName('es_ES', 'Español'),
      );
      selectedLocaleId = esLocale.localeId;
    }

    return available;
  }

  Future<void> speak(String text) async {
    await tts.setVoice({'name': 'es-es-x-sfb-local', 'locale': 'es-ES'});
    await tts.setLanguage('es-ES');
    await tts.setPitch(1.0);
    await tts.speak(text);
  }

  Future<void> startPassiveListening({
    required Function onWakeWordDetected,
    required Function(String transcript) onTranscript,
  }) async {
    if (isPassiveListening || isActiveListening || selectedLocaleId == null) return;

    isPassiveListening = true;

    await speech.listen(
      localeId: selectedLocaleId!,
      listenFor: const Duration(minutes: 10),
      onResult: (result) async {
        final text = result.recognizedWords.toLowerCase();
        onTranscript(text);

        if (text.contains(AppPhrases.KeyWordPassiveListening.toLowerCase())) {
          isPassiveListening = false;
          await speech.stop();
          onWakeWordDetected();
        }
      },
    );
  }

  Future<void> startActiveListening({
    required Function(String text) onTranscript,
    required Function(String response) onResponse,
    required Function(String error) onError,
  }) async {
    if (isActiveListening || selectedLocaleId == null) {
      onError('No se puede iniciar escucha activa.');
      return;
    }

    isActiveListening = true;

    await speech.listen(
      localeId: selectedLocaleId!,
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 5),
      onResult: (result) async {
        final text = result.recognizedWords;
        onTranscript(text);

        if (result.finalResult && text.isNotEmpty) {
          final response = await chatService.sendToChatGPT(text);
          await speak(response);
          onResponse(response);
          await stopListening();
        }
      },
    );
  }

  Future<void> stopListening() async {
    await speech.stop();
    isPassiveListening = false;
    isActiveListening = false;
  }
}
