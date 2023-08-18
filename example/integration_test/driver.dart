import 'dart:io';

import 'package:path/path.dart';
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() async {
  integrationDriver();

  if (Platform.isAndroid) {
    final Map<String, String> envVars = Platform.environment;
    String? adbPath = join(
      envVars['ANDROID_SDK_ROOT'] ?? envVars['ANDROID_HOME']!,
      'platform-tools',
      Platform.isWindows ? 'adb.exe' : 'adb',
    );

    await Process.run(
      adbPath,
      [
        'shell',
        'pm',
        'grant',
        'ai.picovoice.flutter.voiceprocessorexample',
        'android.permission.RECORD_AUDIO'
      ],
    );
  } else if (Platform.isIOS) {
    await Process.run('xcrun', [
      'simctl',
      'privacy',
      'booted',
      'grant',
      'all',
      'ai.picovoice.flutter.voiceprocessor.flutterVoiceProcessorExample'
    ]);
  }
}
