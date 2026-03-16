/// Read the current system HTTP proxy configuration on the active platform.
library;

import 'dart:async';

import 'package:proxy_setting_platform_interface/proxy_setting_platform_interface.dart';

export 'package:proxy_setting_platform_interface/proxy_setting.dart'
    show ProxySetting, ProxySettingModeEnum;

/// Returns the system proxy configuration.
///
/// When [url] is specified, platforms that support PAC files or automatic proxy
/// resolution can resolve the proxy that would be used for that URL.
///
/// Supported platforms are Android, iOS, macOS, and Windows.
Future<ProxySetting?> proxySetting({String? url}) async {
  return await ProxySettingPlatform.instance.proxySetting(url: url);
}
