import 'dart:async';

import 'package:flutter/services.dart';

typedef void BufferListener(dynamic buffer);
typedef void RemoveListener();

class VoiceProcessor {
  static VoiceProcessor _instance;
  int _frameLength;
  int _sampleRate;
  int _nextListenerId = 1;

  final MethodChannel _channel =
      const MethodChannel('flutter_voice_processor_methods');
  final EventChannel _eventChannel =
      const EventChannel('flutter_voice_processor_events');

  VoiceProcessor._(frameLength, sampleRate) {
    _frameLength = frameLength;
    _sampleRate = sampleRate;
  }

  static getVoiceProcessor(int frameLength, int sampleRate) {
    if (_instance == null) {
      _instance = new VoiceProcessor._(frameLength, sampleRate);
    } else {
      _instance._frameLength = frameLength;
      _instance._sampleRate = sampleRate;
    }
    return _instance;
  }

  RemoveListener addListener(BufferListener listener) {
    var subscription = _eventChannel
        .receiveBroadcastStream(_nextListenerId++)
        .listen(listener, cancelOnError: true);
    return () {
      subscription.cancel();
    };
  }

  Future<bool> start() {
    return _channel.invokeMethod('start', <String, dynamic>{
      'frameLength': _frameLength,
      'sampleRate': _sampleRate
    });
  }

  Future<bool> stop() {
    return _channel.invokeMethod('stop');
  }

  Future<bool> hasRecordAudioPermission() {
    return _channel.invokeMethod('hasRecordAudioPermission');
  }
}
