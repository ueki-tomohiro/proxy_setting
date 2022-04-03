#import "ProxySettingPlugin.h"
#if __has_include(<proxy_setting_ios/proxy_setting_ios-Swift.h>)
#import <proxy_setting_ios/proxy_setting_ios-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "proxy_setting_ios-Swift.h"
#endif

@implementation ProxySettingPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftProxySettingPlugin registerWithRegistrar:registrar];
}
@end
