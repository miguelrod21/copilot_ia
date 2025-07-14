import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Copilot-AI',
      home: VoiceHomePage(),
      debugShowCheckedModeBanner: true,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
    );
  }
}

final FlutterTts flutterTts = FlutterTts();

class VoiceHomePage extends StatefulWidget {
  const VoiceHomePage({super.key});

  @override
  _VoiceHomePageState createState() => _VoiceHomePageState();
}

Future<String> _sendToChatGPT(String prompt) async {
  final openAiKey =
      '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';
  const endpoint = 'https://api.openai.com/v1/chat/completions';

  final response = await http.post(
    Uri.parse(endpoint),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $openAiKey',
    },
    body: jsonEncode({
      'model': 'gpt-3.5-turbo',
      'messages': [
        {'role': 'user', 'content': prompt},
      ],
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['choices'][0]['message']['content'];
  } else {
    print('Error: ${response.body}');
    return 'Error al conectar con ChatGPT.';
  }
}

Future<void> requestMicrophonePermission() async {
  final status = await Permission.microphone.request();
  if (status != PermissionStatus.granted) {
    print("Permiso de micrófono denegado");
  }
}

class _VoiceHomePageState extends State<VoiceHomePage>
    with WidgetsBindingObserver {
  List<stt.LocaleName> _locales = [];
  String? _selectedLocaleId;
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _recognizedText = 'Pulsa y habla';
  List<dynamic> allVoices = [];
  List<dynamic> spanishVoices = [];
  Map<String, String> selectedVoice = {};
  bool loadingVoices = true;

  @override
  void initState() {
    super.initState();
    initVoices();
    WidgetsBinding.instance.addObserver(this);
    Permission.microphone.request().then((status) {
      if (status == PermissionStatus.granted) {
        _speech = stt.SpeechToText();
        _initSpeech();
      } else {
        setState(() {
          _recognizedText =
              'Permiso de micrófono denegado. Habilítalo en ajustes.';
        });
      }
    });
  }

  Future<void> initVoices() async {
    allVoices = await flutterTts.getVoices;
    spanishVoices = allVoices.where((voice) {
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
    if (state != AppLifecycleState.resumed && _isListening) {
      _stopListening(); // Detener si la app se va al fondo
    }
  }

  void _initSpeech() async {
    bool available = await _speech.initialize(
      onError: (val) {
        print('Speech initialize error: $val');
        setState(() {
          _recognizedText = 'Error inicializando reconocimiento: $val';
          _isListening = false;
        });
      },
      onStatus: (val) {
        print('Speech status: $val');
        if (val == 'notListening' || val == 'done') {
          setState(() {
            _isListening = false;
          });
        }
      },
    );

    print('Speech available: $available');
    if (available) {
      _locales = await _speech.locales();
      final esEs = _locales.firstWhere(
        (locale) => locale.localeId == 'es_ES',
        orElse: () => _locales.isNotEmpty
            ? _locales.first
            : stt.LocaleName('es_ES', 'Español (España)'),
      );
      _selectedLocaleId = esEs.localeId;
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

  void _startListening() async {
    if (!_isListening && _selectedLocaleId != null) {
      setState(() {
        _isListening = true;
      });

      _speech.listen(
        onResult: (result) async {
          setState(() {
            _recognizedText = result.recognizedWords;
          });
          if (result.finalResult && result.recognizedWords.isNotEmpty) {
            final response = await _sendToChatGPT(result.recognizedWords);
            speakResponse(response);
            setState(() {
              _recognizedText += '\n\nRespuesta IA:\n$response';
            });
          }
        },
        localeId: _selectedLocaleId,
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 5),
      );
    }
  }

  void _stopListening() {
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
            if (!loadingVoices && spanishVoices.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selecciona una voz española:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  DropdownButton<String>(
                    isExpanded: true,
                    value:
                        selectedVoice['name'], // usamos solo el nombre como valor
                    hint: Text('Selecciona una voz'),
                    items: spanishVoices.map<DropdownMenuItem<String>>((voice) {
                      return DropdownMenuItem<String>(
                        value: voice['name'], // solo el nombre como clave única
                        child: Text(voice['name']),
                      );
                    }).toList(),
                    onChanged: (selectedName) async {
                      final voice = spanishVoices.firstWhere(
                        (v) => v['name'] == selectedName,
                      );
                      setState(() {
                        selectedVoice = Map<String, String>.from(voice);
                      });
                      await flutterTts.setVoice(selectedVoice);
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),

            Spacer(),
            ElevatedButton(
              onPressed: _isListening ? _stopListening : _startListening,
              child: Text(_isListening ? 'Parar' : 'Escuchar'),
            ),
          ],
        ),
      ),
    );
  }
}
