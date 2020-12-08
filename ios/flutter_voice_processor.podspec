#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_voice_processor.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_voice_processor'
  s.version          = '1.0.0'
  s.summary          = 'A Flutter package plugin for real-time voice processing.'
  s.description      = <<-DESC
  A Flutter package plugin for real-time voice processing.
                       DESC
  s.homepage         = 'https://picovoice.ai/'
  s.license          = { :type => 'Apache-2.0' }
  s.author           = { 'Picovoice' => 'hello@picovoice.ai' }
  s.source           = { :git => "https://github.com/Picovoice/flutter-voice-processor.git" }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '8.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
