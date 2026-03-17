import 'dart:async';

import 'package:flutter/services.dart';
import 'package:proxy_setting_platform_interface/proxy_setting_platform_interface.dart';

const MethodChannel _channel = MethodChannel('playon.jp/proxy_setting_windows');

bool _asBool(dynamic value) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  return false;
}

/// An implementation of [ProxySettingPlatform] for Windows.
class ProxySettingWindows extends ProxySettingPlatform {
  /// Registers this class as the default instance of [ProxySettingPlatform].
  static void registerWith() {
    ProxySettingPlatform.instance = ProxySettingWindows();
  }

  @override
  Future<ProxySetting?> proxySetting({String? url}) async {
    return _channel
        .invokeMethod<dynamic>('proxySetting', <String, Object?>{'url': url})
        .then(
          (value) => value == null
              ? null
              : ProxySetting(
                  mode: value["mode"] == "proxy"
                      ? ProxySettingModeEnum.proxy
                      : ProxySettingModeEnum.direct,
                  isAutoDetect: _asBool(value["isAutoDetect"]),
                  proxy: value["proxy"]?.toString() ?? "",
                  proxyBypass: value["proxyBypass"]?.toString() ?? "",
                  configUrl: value["configUrl"]?.toString() ?? "",
                ),
        );
  }
}
