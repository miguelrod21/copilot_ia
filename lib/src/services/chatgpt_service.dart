import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<String> sendToChatGPT(String prompt) async {
  final openAiKey = dotenv.env['OPENAI_API_KEY'];
  if (openAiKey == null) {
    return 'Error: OPENAI_API_KEY no encontrada en .env';
  }
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