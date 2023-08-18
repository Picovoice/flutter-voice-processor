import 'dart:io';
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() async {
  integrationDriver();
  await Process.run(
    'adb',
    [
      'shell',
      'pm',
      'grant',
      'ai.picovoice.flutter.voiceprocessorexample',
      'android.permission.RECORD_AUDIO'
    ],
  );
}
