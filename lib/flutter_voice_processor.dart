//
// Copyright 2020-2023 Picovoice Inc.
//
// You may not use this file except in compliance with the license. A copy of the license is located in the "LICENSE"
// file accompanying this source.
//
// Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
// an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//

import 'dart:async';

import 'package:flutter/services.dart';

class VoiceProcessorException implements Exception {
  final String? message;
  VoiceProcessorException([this.message]);
}

typedef void VoiceProcessorFrameListener(List<int> frame);
typedef void VoiceProcessorErrorListener(VoiceProcessorException error);

class VoiceProcessor {
  static VoiceProcessor? _instance;
  Stream? _frameEventStream;
  Stream? _errorEventStream;

  final MethodChannel _channel =
      const MethodChannel('flutter_voice_processor_methods');
  final EventChannel _frameEventsChannel =
      const EventChannel('flutter_voice_processor_frame_events');
  final EventChannel _errorEventsChannel =
      const EventChannel('flutter_voice_processor_error_events');

  List<VoiceProcessorFrameListener> _frameListeners = [];
  List<VoiceProcessorErrorListener> _errorListeners = [];

  void onFrame(List<int> frame) {
    for (VoiceProcessorFrameListener frameListener in _frameListeners) {
      frameListener(frame);
    }
  }

  void onError(String error) {
    if (_errorListeners.isNotEmpty) {
      for (VoiceProcessorErrorListener errorListener in _errorListeners) {
        errorListener(
            VoiceProcessorException("Failed to cast incoming error data."));
      }
    } else {
      print(error);
    }
  }

  VoiceProcessor._() {
    _frameEventStream = _frameEventsChannel.receiveBroadcastStream("frame");
    _frameEventStream?.listen((event) {
      try {
        List<int> frame = (event as List<dynamic>).cast<int>();
        onFrame(frame);
      } on Error {
        onError("Failed to cast incoming frame data.");
      }
    }, cancelOnError: true);

    _errorEventStream = _errorEventsChannel.receiveBroadcastStream("error");
    _errorEventStream?.listen((event) {
      try {
        String error = event as String;
        onError(error);
      } on Error {
        onError("Unable to cast incoming error event.");
      }
    }, cancelOnError: true);
  }

  /// Singleton instance of VoiceProcessor
  static VoiceProcessor? get instance {
    if (_instance == null) {
      _instance = new VoiceProcessor._();
    }
    return _instance;
  }

  int get numFrameListeners => _frameListeners.length;
  int get numErrorListeners => _errorListeners.length;

  void addFrameListener(VoiceProcessorFrameListener listener) {
    _frameListeners.add(listener);
  }

  void addFrameListeners(List<VoiceProcessorFrameListener> listeners) {
    _frameListeners.addAll(listeners);
  }

  void removeFrameListener(VoiceProcessorFrameListener listener) {
    _frameListeners.remove(listener);
  }

  void removeFrameListeners(List<VoiceProcessorFrameListener> listeners) {
    for (VoiceProcessorFrameListener listener in listeners) {
      _frameListeners.remove(listener);
    }
  }

  void clearFrameListeners() {
    _frameListeners.clear();
  }

  void addErrorListener(VoiceProcessorErrorListener errorListener) {
    _errorListeners.add(errorListener);
  }

  void removeErrorListener(VoiceProcessorErrorListener errorListener) {
    _errorListeners.remove(errorListener);
  }

  void clearErrorListeners() {
    _errorListeners.clear();
  }

  /// Starts audio recording
  /// throws [PlatformError] if native audio engine doesn't start
  Future<void> start(int frameLength, int sampleRate) async {
    await _channel.invokeMethod('start', <String, dynamic>{
      'frameLength': frameLength,
      'sampleRate': sampleRate
    });
  }

  /// Stops audio recording
  Future<void> stop() async {
    await _channel.invokeMethod('stop');
  }

  /// Checks if user has granted recording permission and
  /// asks for it if they haven't
  Future<bool?> hasRecordAudioPermission() {
    return _channel.invokeMethod('hasRecordAudioPermission');
  }
}
