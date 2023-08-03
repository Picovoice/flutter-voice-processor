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

/// Exception class for errors related to the VoiceProcessor.
class VoiceProcessorException implements Exception {
  /// The error message associated with the exception.
  final String? message;

  /// Creates a VoiceProcessorException with an optional error [message].
  VoiceProcessorException([this.message]);
}

/// Type for callback functions that receive audio frames from the VoiceProcessor.
typedef void VoiceProcessorFrameListener(List<int> frame);

/// Type for callbacks that receive errors from the VoiceProcessor.
typedef void VoiceProcessorErrorListener(VoiceProcessorException error);

/// An audio capture library designed for real-time speech audio processing
/// on mobile devices. Given some specifications, the library delivers
/// frames of raw audio data to the user via listeners.
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

  void _onFrame(List<int> frame) {
    for (VoiceProcessorFrameListener frameListener in _frameListeners) {
      frameListener(frame);
    }
  }

  void _onError(String errorMessage) {
    if (_errorListeners.isNotEmpty) {
      for (VoiceProcessorErrorListener errorListener in _errorListeners) {
        errorListener(VoiceProcessorException(errorMessage));
      }
    } else {
      print("VoiceProcessorException: " + errorMessage);
    }
  }

  /// Private constructor for VoiceProcessor.
  VoiceProcessor._() {
    _frameEventStream = _frameEventsChannel.receiveBroadcastStream("frame");
    _frameEventStream?.listen((event) {
      try {
        List<int> frame = (event as List<dynamic>).cast<int>();
        _onFrame(frame);
      } on Error {
        _onError("VoiceProcessorException: Failed to cast incoming frame data");
      }
    }, cancelOnError: true);

    _errorEventStream = _errorEventsChannel.receiveBroadcastStream("error");
    _errorEventStream?.listen((event) {
      try {
        String error = event as String;
        _onError(error);
      } on Error {
        _onError(
            "VoiceProcessorException: Unable to cast incoming error event.");
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

  /// Gets the number of registered frame listeners.
  int get numFrameListeners => _frameListeners.length;

  /// Gets the number of registered error listeners.
  int get numErrorListeners => _errorListeners.length;

  /// Adds a new listener that receives audio frames.
  void addFrameListener(VoiceProcessorFrameListener listener) {
    _frameListeners.add(listener);
  }

  /// Adds a list of listeners that receive audio frames.
  void addFrameListeners(List<VoiceProcessorFrameListener> listeners) {
    _frameListeners.addAll(listeners);
  }

  /// Removes a previously added frame listener.
  void removeFrameListener(VoiceProcessorFrameListener listener) {
    _frameListeners.remove(listener);
  }

  /// Removes previously added frame listeners.
  void removeFrameListeners(List<VoiceProcessorFrameListener> listeners) {
    for (VoiceProcessorFrameListener listener in listeners) {
      _frameListeners.remove(listener);
    }
  }

  /// Removes all frame listeners.
  void clearFrameListeners() {
    _frameListeners.clear();
  }

  /// Adds a new error listener.
  void addErrorListener(VoiceProcessorErrorListener errorListener) {
    _errorListeners.add(errorListener);
  }

  /// Removes a previously added error listener.
  void removeErrorListener(VoiceProcessorErrorListener errorListener) {
    _errorListeners.remove(errorListener);
  }

  /// Removes all error listeners.
  void clearErrorListeners() {
    _errorListeners.clear();
  }

  /// Starts audio recording with the given [sampleRate] and delivering audio
  /// frames of size [frameLength] to registered frame listeners.
  Future<void> start(int frameLength, int sampleRate) async {
    await _channel.invokeMethod('start', <String, dynamic>{
      'frameLength': frameLength,
      'sampleRate': sampleRate
    });
  }

  /// Stops audio recording.
  Future<void> stop() async {
    await _channel.invokeMethod('stop');
  }

  /// Checks if audio recording is currently in progress.
  Future<bool?> isRecording() async {
    return _channel.invokeMethod('isRecording');
  }

  /// Checks if the app has permission to record audio and prompts user if not.
  Future<bool?> hasRecordAudioPermission() {
    return _channel.invokeMethod('hasRecordAudioPermission');
  }
}
