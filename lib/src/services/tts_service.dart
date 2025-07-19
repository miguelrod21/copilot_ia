import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts flutterTts;
  Map<String, String> selectedVoice = {};
  bool loading = true;

  TtsService(this.flutterTts);

  Future<void> initSpanishVoice() async {
    var allVoices = await flutterTts.getVoices;
    var spanishVoices = allVoices.where((voice) => voice['locale'] == 'es-ES').toList();
    if (spanishVoices.isNotEmpty) {
      selectedVoice = Map<String, String>.from(spanishVoices.first);
      await flutterTts.setVoice(selectedVoice);
    }
    loading = false;
  }

  Future<void> speak(String text) async {
    await flutterTts.setVoice(selectedVoice);
    await flutterTts.setLanguage("es-ES");
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(text);
  }
}
