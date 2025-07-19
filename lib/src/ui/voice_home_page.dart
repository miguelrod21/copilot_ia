import 'package:copilot_ia/resources/es.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

import '../services/chatgpt_service.dart';
import '../utils/permissions.dart';
import '../controllers/voice_controller.dart';

class VoiceHomePage extends StatefulWidget {
  const VoiceHomePage({super.key});

  @override
  _VoiceHomePageState createState() => _VoiceHomePageState();
}

class _VoiceHomePageState extends State<VoiceHomePage>
    with WidgetsBindingObserver {
  late VoiceController controller;
  String _recognizedText = AppPhrases.defaultPrompt;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    //API KEY VALIDATION
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null) {
      setState(() => _recognizedText = AppPhrases.missingApiKey);
      return;
    }
    //MICROPHONE PERMISSION
    final granted = await requestMicrophonePermission();
    if (!granted) {
      setState(() => _recognizedText = AppPhrases.deniedPermission);
      return;
    }

    controller = VoiceController(
      speech: stt.SpeechToText(),
      tts: FlutterTts(),
      chatService: ChatGPTService(apiKey: apiKey),
    );

    final available = await controller.initializeSpeech(
      onError: (msg) => setState(() => _recognizedText = AppPhrases.errorInitializingVoice + msg),
      onStatus: (status) {
        if (status == 'notListening' || status == 'done') {
          setState(() => _isListening = false);
        }
      },
    );

    if (available) {
      controller.startPassiveListening(
        onWakeWordDetected: _startActiveListening,
        onTranscript: (text) => setState(() => _recognizedText = text),
      );
    } else {
      setState(() => _recognizedText = AppPhrases.noListeningAvailable);
    }
  }

  void _startActiveListening() {
    print(AppPhrases.activeStart);
    setState(() => _isListening = true);

    controller.startActiveListening(
      onTranscript: (text) => setState(() => _recognizedText = text),
      onResponse: (response) => setState(() {
        _recognizedText += AppPhrases.defaultChatResponse + response;
        _isListening = false;
      }),
      onError: (err) => setState(() {
        _recognizedText = err;
        _isListening = false;
      }),
    );
  }

  void _stopActiveListening() async {
    print(AppPhrases.activeEnd);
    await controller.stopListening();
    setState(() => _isListening = false);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.stopListening();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_isListening && !controller.isPassiveListening) {
        controller.startPassiveListening(
          onWakeWordDetected: _startActiveListening,
          onTranscript: (text) => setState(() => _recognizedText = text),
        );
      }
    } else {
      controller.stopListening();
      if (_isListening) _stopActiveListening();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppPhrases.appTitle)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(_recognizedText, style: TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            const Spacer(),
            ElevatedButton(
              onPressed: _isListening ? _stopActiveListening : _startActiveListening,
              child: Text(_isListening
                  ? AppPhrases.buttonListening
                  : AppPhrases.buttonListen),
            ),
          ],
        ),
      ),
    );
  }
}
