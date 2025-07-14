import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
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
class VoiceHomePage extends StatefulWidget {
  const VoiceHomePage({super.key});

  @override
  _VoiceHomePageState createState() => _VoiceHomePageState();
}
Future<String> _sendToChatGPT(String prompt) async {
  const apiKey = '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';
  const endpoint = 'https://api.openai.com/v1/chat/completions';

  final response = await http.post(
    Uri.parse(endpoint),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    },
    body: jsonEncode({
      'model': 'gpt-3.5-turbo',
      'messages': [
        {'role': 'user', 'content': prompt}
      ]
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

class _VoiceHomePageState extends State<VoiceHomePage> with WidgetsBindingObserver {
  List<stt.LocaleName> _locales = [];
  String? _selectedLocaleId;
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _recognizedText = 'Pulsa y habla';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Permission.microphone.request().then((status) {
      if (status == PermissionStatus.granted) {
        _speech = stt.SpeechToText();
        _initSpeech();
      } else {
        setState(() {
          _recognizedText = 'Permiso de micrófono denegado. Habilítalo en ajustes.';
        });
      }
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
      // final respuesta = await _sendToChatGPT(result.recognizedWords);
      // setState(() {
      //   _recognizedText += '\n\nRespuesta IA:\n$respuesta';
      // });
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
            Text(
              _recognizedText,
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
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
