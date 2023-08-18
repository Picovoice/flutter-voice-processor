import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_voice_processor/flutter_voice_processor.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Test tests', () {
    // late dynamic testData;

    setUp(() async {
      // String testDataJson =
      //     await rootBundle.loadString('assets/test_resources/test_data.json');
      // testData = json.decode(testDataJson);
    });

    testWidgets('Test', (tester) async {});
  });
}
