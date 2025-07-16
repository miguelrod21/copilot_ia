import 'package:permission_handler/permission_handler.dart';

Future<bool> requestMicrophonePermission() async {
  final status = await Permission.microphone.request();
  return status == PermissionStatus.granted;
}