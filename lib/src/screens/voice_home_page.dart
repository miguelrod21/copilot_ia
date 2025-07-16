import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../services/chatgpt_service.dart';
import '../utils/permissions.dart';

final FlutterTts flutterTts = FlutterTts();

class VoiceHomePage extends StatefulWidget {
  const VoiceHomePage({super.key});

  @override
  _VoiceHomePageState createState() => _VoiceHomePageState();
}

class _VoiceHomePageState extends State<VoiceHomePage>
    with WidgetsBindingObserver {
  String? _selectedLocaleId;
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _isPassiveListening = false;
  String _recognizedText = 'Pulsa o di "Oye chat" y habla';
  Map<String, String> selectedVoice = {};
  bool loadingVoices = true;

  @override
  void initState()  {
    super.initState();
     initVoices();
    WidgetsBinding.instance.addObserver(this);
    requestMicrophonePermission().then((granted) async {
      if (granted) {
        _speech = stt.SpeechToText();
        await _initSpeech();
        _startPassiveListening(); // Solo inicia cuando la app está en primer plano
      } else {
        setState(() {
          _recognizedText =
              'Permiso de micrófono denegado. Habilítalo en ajustes.';
        });
      }
    });
  }

  Future<void> initVoices() async {
    var allVoices = await flutterTts.getVoices;
    var spanishVoices = allVoices.where((voice) {
      return voice['locale'] == 'es-ES';
    }).toList();

    if (spanishVoices.isNotEmpty) {
      selectedVoice = Map<String, String>.from(spanishVoices.first);
      await flutterTts.setVoice(selectedVoice);
    }

    setState(() {
      loadingVoices = false;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _speech.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Vuelve a escuchar pasivamente solo si no está escuchando activamente
      if (!_isListening && !_isPassiveListening) {
        _startPassiveListening();
      }
    } else {
      // Detén la escucha pasiva si la app no está en primer plano
      _stopPassiveListening();
      if (_isListening) _stopActiveListening();
    }
  }

  Future<void> _initSpeech() async {
    bool available = await _speech.initialize(
      onError: (val) {
        setState(() {
          _recognizedText = 'Error inicializando reconocimiento: $val';
          _isListening = false;
        });
      },
      onStatus: (val) {
        if (val == 'notListening' || val == 'done') {
          setState(() {
            _isListening = false;
          });
        }
      },
    );

    if (available) {
      var locales = await _speech.locales();
      final esEs = locales.firstWhere(
        (locale) => locale.localeId == 'es_ES',
        orElse: () => locales.isNotEmpty
            ? locales.first
            : stt.LocaleName('es_ES', 'Español (España)'),
      );
      _selectedLocaleId = esEs.localeId;
      print('[Conversia] Locale seleccionado: $_selectedLocaleId');
    } else {
      setState(() {
        _recognizedText =
            'Reconocimiento de voz no disponible en este dispositivo.';
      });
    }
  }

  void speakResponse(String responseText) async {
    await flutterTts.setVoice(selectedVoice);
    await flutterTts.setLanguage("es-ES");
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(responseText);
  }

  void _startPassiveListening() async {
    if (_isPassiveListening || _isListening || _selectedLocaleId == null) {
      print(
        '[Conversia] Ya está escuchando pasivamente o activamente, o no hay idioma seleccionado.',
      );
      return;
    }
    print('[Conversia] INICIO escucha pasiva');
    _isPassiveListening = true;
    await _speech.listen(
      onResult: (result) async {
        print(
          '[Conversia] Escucha pasiva resultado: ${result.recognizedWords}',
        );
        if (result.recognizedWords.toLowerCase().contains('hola')) {
          print('[Conversia] Palabra clave detectada: "hola"');
          _isPassiveListening = false;
          print('[Conversia] FIN escucha pasiva');
          await _stopPassiveListening();
          _startActiveListening();
        }
      },
      localeId: _selectedLocaleId,
      listenFor: const Duration(minutes: 10),
      pauseFor: const Duration(seconds: 5),
    );
  }

  Future<void> _stopPassiveListening() async {
    if (_isPassiveListening) {
      print('[Conversia] FIN escucha pasiva');
      await _speech.stop();
      _isPassiveListening = false;
    }
  }

  void _startActiveListening() async {
    if (!_isListening && _selectedLocaleId != null) {
      print('[Conversia] INICIO escucha principal');
      setState(() {
        _isListening = true;
      });

      _speech.listen(
        onResult: (result) async {
          print(
            '[Conversia] Escucha principal resultado: ${result.recognizedWords}',
          );
          setState(() {
            _recognizedText = result.recognizedWords;
          });
          if (result.finalResult && result.recognizedWords.isNotEmpty) {
            final response = await sendToChatGPT(result.recognizedWords);
            speakResponse(response);
            setState(() {
              _recognizedText += '\n\nRespuesta IA:\n$response';
            });
            print('[Conversia] FIN escucha principal (vuelve a pasiva)');
            _stopPassiveListening();
          }
        },
        localeId: _selectedLocaleId,
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 5),
      );
    }else{
      print('[Conversia] No se puede iniciar escucha activa: $_selectedLocaleId');
      setState(() {
        _recognizedText = 'No se puede iniciar escucha activa. Verifica el idioma.';
      });
    }
  }

  void _stopActiveListening() {
    print('[Conversia] FIN escucha principal');
    _speech.stop();
    setState(() {
      _isListening = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Reconocimiento de voz')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(_recognizedText, style: TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            Spacer(),
            ElevatedButton(
              onPressed: _isListening ? _stopActiveListening : _startActiveListening,
              child: Text(_isListening ? 'Escuchando' : 'Escuchar'),
            ),
          ],
        ),
      ),
    );
  }
}
