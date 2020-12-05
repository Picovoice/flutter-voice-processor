#import "FlutterVoiceProcessorPlugin.h"
#if __has_include(<flutter_voice_processor/flutter_voice_processor-Swift.h>)
#import <flutter_voice_processor/flutter_voice_processor-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "flutter_voice_processor-Swift.h"
#endif

@implementation FlutterVoiceProcessorPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterVoiceProcessorPlugin registerWithRegistrar:registrar];
}
@end
