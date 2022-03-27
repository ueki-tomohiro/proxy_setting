import 'dart:async';

import 'package:flutter/services.dart';

import 'proxy_setting_platform_interface.dart';

const MethodChannel _channel = MethodChannel('playon.jp/proxy_setting');

/// An implementation of [ProxySettingPlatform] that uses method channels.
class MethodChannelProxySetting extends ProxySettingPlatform {
  @override
  Future<ProxySetting?> proxySetting({String? url}) {
    return _channel.invokeMethod<ProxySetting>(
      'proxySetting',
      <String, Object?>{'url': url},
    );
  }
}
