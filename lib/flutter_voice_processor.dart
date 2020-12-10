//
// Copyright 2020 Picovoice Inc.
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

typedef void BufferListener(dynamic buffer);
typedef void RemoveListener();

class VoiceProcessor {
  static VoiceProcessor _instance;
  int _frameLength;
  int _sampleRate;
  Stream _bufferEventStream;
  bool _isRecording = false;

  bool get isRecording => this._isRecording;

  final MethodChannel _channel =
      const MethodChannel('flutter_voice_processor_methods');
  final EventChannel _eventChannel =
      const EventChannel('flutter_voice_processor_events');

  VoiceProcessor._(this._frameLength, this._sampleRate) {
    _bufferEventStream = _eventChannel.receiveBroadcastStream();
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
    var subscription = _bufferEventStream.listen(listener, cancelOnError: true);
    return () {
      subscription.cancel();
    };
  }

  Future<void> start() async {
    if (_isRecording) {
      return;
    }
    await _channel.invokeMethod('start', <String, dynamic>{
      'frameLength': _frameLength,
      'sampleRate': _sampleRate
    });
    _isRecording = true;
  }

  Future<void> stop() async {
    if (!_isRecording) {
      return;
    }
    await _channel.invokeMethod('stop');
    _isRecording = false;
  }

  Future<bool> hasRecordAudioPermission() {
    return _channel.invokeMethod('hasRecordAudioPermission');
  }
}
