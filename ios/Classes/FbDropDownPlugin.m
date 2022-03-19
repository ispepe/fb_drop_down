#import "FbDropDownPlugin.h"
#if __has_include(<fb_drop_down/fb_drop_down-Swift.h>)
#import <fb_drop_down/fb_drop_down-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "fb_drop_down-Swift.h"
#endif

@implementation FbDropDownPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFbDropDownPlugin registerWithRegistrar:registrar];
}
@end
