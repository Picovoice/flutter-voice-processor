# Flutter Voice Processor

[![GitHub release](https://img.shields.io/github/release/Picovoice/flutter-voice-processor.svg)](https://github.com/Picovoice/flutter-voice-processor/releases)
[![GitHub](https://img.shields.io/github/license/Picovoice/flutter-voice-processor)](https://github.com/Picovoice/flutter-voice-processor/)

[![Pub Version](https://img.shields.io/pub/v/flutter_voice_processor)](https://pub.dev/packages/flutter_voice_processor)

Made in Vancouver, Canada by [Picovoice](https://picovoice.ai)

<!-- markdown-link-check-disable -->
[![Twitter URL](https://img.shields.io/twitter/url?label=%40AiPicovoice&style=social&url=https%3A%2F%2Ftwitter.com%2FAiPicovoice)](https://twitter.com/AiPicovoice)
<!-- markdown-link-check-enable -->
[![YouTube Channel Views](https://img.shields.io/youtube/channel/views/UCAdi9sTCXLosG1XeqDwLx7w?label=YouTube&style=social)](https://www.youtube.com/channel/UCAdi9sTCXLosG1XeqDwLx7w)

The Flutter Voice Processor is an asynchronous audio capture library designed for real-time audio
processing on mobile devices. Given some specifications, the library delivers frames of raw audio
data to the user via listeners.

## Table of Contents

- [Flutter Voice Processor](#flutter-voice-processor)
    - [Table of Contents](#table-of-contents)
    - [Requirements](#requirements)
    - [Compatibility](#compatibility)
    - [Installation](#installation)
    - [Permissions](#permissions)
    - [Usage](#usage)
        - [Capturing with Multiple Listeners](#capturing-with-multiple-listeners)
    - [Example](#example)

## Requirements

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Android SDK](https://developer.android.com/about/versions/12/setup-sdk) (21+)
- [JDK](https://www.oracle.com/java/technologies/downloads/) (8+)
- [Xcode](https://developer.apple.com/xcode/) (11+)
- [CocoaPods](https://cocoapods.org/)

## Compatibility

- Flutter 1.20.0+
- Android 5.0+ (API 21+)
- iOS 11.0+

## Installation

Flutter Voice Processor is available via [pub.dev](https://pub.dev/packages/flutter_voice_processor).
To import it into your Flutter project, add the following line to your `pubspec.yaml`:
```yaml
dependencies:
  flutter_voice_processor: ^<version>
```

## Permissions

To enable recording with the hardware's microphone, you must first ensure that you have enabled the proper permission on both iOS and Android.

On iOS, open the `Info.plist` file and add the following line:
```xml
<key>NSMicrophoneUsageDescription</key>
<string>[Permission explanation]</string>
```

On Android, open the `AndroidManifest.xml` and add the following line:
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

See our [example app](./example) for how to properly request this permission from your users.

## Usage

Access the singleton instance of `VoiceProcessor`:

```dart
import 'package:flutter_voice_processor/flutter_voice_processor.dart';

VoiceProcessor _voiceProcessor = VoiceProcessor.instance;
```

Add listeners for audio frames and errors:

```dart
VoiceProcessorFrameListener frameListener = (List<int> frame) {
    // use audio
}

VoiceProcessorErrorListener errorListener = (VoiceProcessorException error) {
    // handle error
}

_voiceProcessor.addFrameListener(frameListener);
_voiceProcessor.addErrorListener(errorListener);
```

Start audio capture with the desired frame length and audio sample rate:

```dart
final int frameLength = 512;
final int sampleRate = 16000;
try {
    await _voiceProcessor.start(frameLength, sampleRate);
} on PlatformException catch (ex) {
    // handle start error
}
```

Stop audio capture:
```dart
try {
    await _voiceProcessor.stop();
} on PlatformException catch (ex) {
    // handle stop error
}
```

Once audio capture has started successfully, any frame listeners assigned to the `VoiceProcessor` will start receiving audio frames with the given `frameLength` and `sampleRate`.

### Capturing with Multiple Listeners

Any number of listeners can be added to and removed from the `VoiceProcessor` instance. However,
the instance can only record audio with a single audio configuration (`frameLength` and `sampleRate`),
which all listeners will receive once a call to `start()` has been made. To add multiple listeners:
```dart
VoiceProcessorFrameListener listener1 = (frame) { }
VoiceProcessorFrameListener listener2 = (frame) { }
List<VoiceProcessorFrameListener> listeners = [listener1, listener2];
voiceProcessor.addFrameListeners(listeners);

voiceProcessor.removeFrameListeners(listeners);
// or
voiceProcessor.clearFrameListeners();
```

## Example

The [Flutter Voice Processor app](./example) demonstrates how to ask for user permissions and capture output from the `VoiceProcessor`.

## Releases

### v1.1.0 - August 4, 2023
- Numerous API improvements
- Error handling improvements
- Allow for multiple listeners instead of a single callback function
- Upgrades to testing infrastructure and example app

### v1.0.0 - December 8, 2020

- Initial public release.
