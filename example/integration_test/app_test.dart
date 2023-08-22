import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_voice_processor/flutter_voice_processor.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Voice Processor tests', () {
    final VoiceProcessor? _vp = VoiceProcessor.instance;

    final int _frameLength = 512;
    final int _sampleRate = 16000;

    final List<List<int>> _receivedFrames = [];
    int _errorCount = 0;

    void _frameListener(List<int> frame) {
      _receivedFrames.add(frame);
    }

    void _frameListener2(List<int> frame) {}

    void _errorListener(VoiceProcessorException e) {
      print(e.message);
      _errorCount++;
    }

    void _errorListener2(VoiceProcessorException e) {}

    setUpAll(() async {});

    tearDown(() {
      _vp?.clearErrorListeners();
      _vp?.clearFrameListeners();
      _receivedFrames.clear();
      _errorCount = 0;
    });

    testWidgets('Test basic', (tester) async {
      expect(await _vp?.isRecording(), false);
      _vp?.addFrameListener(_frameListener);
      _vp?.addErrorListener(_errorListener);

      expect(await _vp?.hasRecordAudioPermission(), true);
      await _vp?.start(_frameLength, _sampleRate);
      expect(await _vp?.isRecording(), true);

      sleep(Duration(seconds: 3));

      await _vp?.stop();
      expect(_receivedFrames.length, greaterThan(0));
      for (List<int> frame in _receivedFrames) {
        expect(frame.length, _frameLength);
      }
      expect(_errorCount, equals(0));

      expect(await _vp?.isRecording(), false);
    });

    testWidgets('Test invalid start', (tester) async {
      expect(await _vp?.hasRecordAudioPermission(), true);
      await _vp?.start(_frameLength, _sampleRate);
      expect(() async => await _vp?.start(1024, 44100),
          throwsA(isA<PlatformException>()));
      await _vp?.stop();
    });

    testWidgets('Test add and remove listeners', (tester) async {
      VoiceProcessorFrameListener frameListener1 = _frameListener;
      VoiceProcessorFrameListener frameListener2 = _frameListener2;

      VoiceProcessorErrorListener errorListener1 = _errorListener;
      VoiceProcessorErrorListener errorListener2 = _errorListener2;

      _vp?.addFrameListener(frameListener1);
      expect(_vp?.numFrameListeners, equals(1));
      _vp?.addFrameListener(frameListener2);
      expect(_vp?.numFrameListeners, equals(2));
      _vp?.removeFrameListener(frameListener1);
      expect(_vp?.numFrameListeners, equals(1));
      _vp?.removeFrameListener(frameListener1);
      expect(_vp?.numFrameListeners, equals(1));
      _vp?.removeFrameListener(frameListener2);
      expect(_vp?.numFrameListeners, equals(0));

      List<VoiceProcessorFrameListener> frameListeners = [
        frameListener1,
        frameListener2
      ];
      _vp?.addFrameListeners(frameListeners);
      expect(_vp?.numFrameListeners, equals(2));
      _vp?.removeFrameListeners(frameListeners);
      expect(_vp?.numFrameListeners, equals(0));
      _vp?.addFrameListeners(frameListeners);
      expect(_vp?.numFrameListeners, equals(2));
      _vp?.clearFrameListeners();
      expect(_vp?.numFrameListeners, equals(0));

      _vp?.addErrorListener(errorListener1);
      expect(_vp?.numErrorListeners, equals(1));
      _vp?.addErrorListener(errorListener2);
      expect(_vp?.numErrorListeners, equals(2));
      _vp?.removeErrorListener(errorListener1);
      expect(_vp?.numErrorListeners, equals(1));
      _vp?.removeErrorListener(errorListener1);
      expect(_vp?.numErrorListeners, equals(1));
      _vp?.removeErrorListener(errorListener2);
      expect(_vp?.numErrorListeners, equals(0));
      _vp?.addErrorListener(errorListener1);
      expect(_vp?.numErrorListeners, equals(1));
      _vp?.clearErrorListeners();
      expect(_vp?.numErrorListeners, equals(0));
    });
  });
}
