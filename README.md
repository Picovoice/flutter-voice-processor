# flutter-voice-processor

Made in Vancouver, Canada by [Picovoice](https://picovoice.ai)

A Flutter plugin for real-time voice processing.

## Usage

Create:
```dart
int frameLength = 512;
int sampleRate = 16000;
VoiceProcessor _voiceProcessor = VoiceProcessor.getVoiceProcessor(frameLength, sampleRate);
Function _removeListener = _voiceProcessor.addListener((buffer) {
    print("Listener received buffer of size ${buffer.length}!");
});

```

Start audio:
```dart
try {
    if (await _voiceProcessor.hasRecordAudioPermission()) {
        await _voiceProcessor.start();
    } else {
        print("Recording permission not granted");
    }
} on PlatformException catch (ex) {
    print("Failed to start recorder: " + ex.toString());
}
```

Stop audio:
```dart
await _voiceProcessor.stop();
_removeListener();
```