import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  print('OPENAI_API_KEY: ${dotenv.env['OPENAI_API_KEY']}');
}