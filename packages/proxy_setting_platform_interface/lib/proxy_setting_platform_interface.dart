import 'dart:async';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'method_channel_proxy_setting.dart';
import 'proxy_setting.dart';

export 'proxy_setting.dart';

abstract class ProxySettingPlatform extends PlatformInterface {
  ProxySettingPlatform() : super(token: _token);

  static final Object _token = Object();

  static ProxySettingPlatform _instance = MethodChannelProxySetting();

  static ProxySettingPlatform get instance => _instance;

  static set instance(ProxySettingPlatform instance) {
    PlatformInterface.verify(instance, _token);
    _instance = instance;
  }

  Future<ProxySetting?> proxySetting({String? url}) {
    throw UnimplementedError('proxySetting() has not been implemented.');
  }
}
