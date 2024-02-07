#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_voice_processor.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_voice_processor'
  s.version          = '1.1.1'
  s.summary          = 'A Flutter audio recording plugin designed for real-time speech audio processing.'
  s.description      = <<-DESC
  The Flutter Voice Processor is an asynchronous audio capture library designed for real-time audio processing.
  Given some specifications, the library delivers frames of raw audio data to the user via listeners.
                       DESC
  s.homepage         = 'https://picovoice.ai/'
  s.license          = { :type => 'Apache-2.0' }
  s.author           = { 'Picovoice' => 'hello@picovoice.ai' }
  s.source           = { :git => "https://github.com/Picovoice/flutter-voice-processor.git" }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'ios-voice-processor', '~> 1.1.0'
  s.platform = :ios, '11.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
